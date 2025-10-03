
#!/bin/bash

# Konnect Personal Access Token for Konnect mode
KONNECT_PAT=""

DEFAULT_KONG_IMAGE_REPO="kong"
DEFAULT_KONG_IMAGE_NAME="kong-gateway"
DEFAULT_KONG_IMAGE_TAG="3.11.0.0"

DEFAULT_KONNECT_CONTROL_PLANE_NAME="quickstart"

DEFAULT_POSTGRES_IMAGE_TAG="13"
DEFAULT_POSTGRES_IMAGE_NAME="postgres"

DEFAULT_KONG_PASSWORD=kongFTW

DEFAULT_APP_NAME="kong-quickstart"

DEFAULT_PROXY_PORT=8000
DEFAULT_HTTPS_PROXY_PORT=8443
DEFAULT_ADMIN_PORT=8001
DEFAULT_MANAGER_PORT=8002
DEFAULT_DEVPORTAL_PORT=8003
DEFAULT_FILES_PORT=8004

APP_NAME="${APP_NAME:-$DEFAULT_APP_NAME}"

OUTPUT_DIR="${OUTPUT_DIR:-/tmp/kong/quickstart}"
# This is a file a user can use to source in env vars for interacting w/ Kong
USER_ENV_FILE="${OUTPUT_DIR}/kong.env"
# This is a file that is used to pass env vars to the docker run command
KONG_ENV_FILE="${OUTPUT_DIR}/${APP_NAME}.env"

KONG_IMAGE_REPO="${KONG_IMAGE_REPO:-$DEFAULT_KONG_IMAGE_REPO}"
KONG_IMAGE_NAME="${KONG_IMAGE_NAME:-$DEFAULT_KONG_IMAGE_NAME}"
KONG_IMAGE_TAG="${KONG_IMAGE_TAG:-$DEFAULT_KONG_IMAGE_TAG}"

KONG_DATABASE="postgres"
KONG_ROLE="traditional"

POSTGRES_IMAGE_NAME="${POSTGRES_IMAGE_NAME:-$DEFAULT_POSTGRES_IMAGE_NAME}"
POSTGRES_IMAGE_TAG="${POSTGRES_IMAGE_TAG:-$DEFAULT_POSTGRES_IMAGE_TAG}"
POSTGRES_IMAGE="${POSTGRES_IMAGE_NAME}:${POSTGRES_IMAGE_TAG}"

POSTGRES_DB="${POSTGRES_DB:-kong}"
POSTGRES_USER="${POSTGRES_USER:-kong}" 
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-kong}"

USE_DEFAULT_PORTS="true"

INSTALL_MOCK_SERVICE="${INSTALL_MOCK_SERVICE:-false}"

PROXY_PORT="${PROXY_PORT:-$DEFAULT_PROXY_PORT}"
HTTPS_PROXY_PORT="${HTTPS_PROXY_PORT:-$DEFAULT_HTTPS_PROXY_PORT}"

ADMIN_PORT="${ADMIN_PORT:-$DEFAULT_ADMIN_PORT}"
MANAGER_PORT="${MANAGER_PORT:-$DEFAULT_MANAGER_PORT}"
DEVPORTAL_PORT="${DEVPORTAL_PORT:-$DEFAULT_DEVPORTAL_PORT}"
FILES_PORT="${FILE_PORT:-$DEFAULT_FILES_PORT}"

DISPLAY_SUMMARY="${DISPLAY_SUMMARY:-true}"
DISPLAY_LOGGING_INFO="${DISPLAY_LOGGING_INFO:-true}"

DECK_IMAGE="kong/deck:latest"
JQ_IMAGE="ghcr.io/jqlang/jq:latest"

UNKNOWN_PORT_BIND_LIST=()

ENVIRONMENT=()
VOLUMES=()

ADMIN_API_HEADERS=()

KONNECT_REGION="${KONNECT_REGION:-us}"

DB_LESS_MODE="false"

echo_fail() {
  printf "\e[31m✘ \033\e[0m$@\n"
}
echo_pass() {
  printf "\e[32m✔ \033\e[0m$@\n"
}
echo_warn() {
  printf "\e[33m• \033\e[0m$@\n"
}
echo_pause() {
  printf "\e[34m⏸︎ \033\e[0m$1\n"
}
echo_question() {
  if [ "$2" = "" ]; then
    printf "\e[33m? \033\e[0m$@\n"
  else
    printf "\e[33m? \033\e[0m$@"
  fi
}
echo_info() {
  printf "\e[34mℹ \033\e[0m$1\n"
}
echo_point() {
  if [ "$2" = "" ]; then
    printf "\e[34m→ \033\e[0m$1\n"
  else
    printf "\e[34m→ \033\e[0m$1"
  fi
}
echo_bullet() {
  printf "\e[34m• \033\e[0m$1\n"
}
echo_wait() {
  if [ "$2" = "" ]; then
    printf "\e[33m⏲︎ \033\e[0m$1\n"
  else
    printf "\e[33m⏲︎ \033\e[0m$1"
  fi
}

retry() {
    local -r -i max_wait="$1"; shift
    local -r cmd="$@"

    local -i sleep_interval=2
    local -i curr_wait=0

    until $cmd
    do
        if (( curr_wait >= max_wait ))
        then
            echo "ERROR: Command '${cmd}' failed after $curr_wait seconds."
            return 1
        else
            curr_wait=$((curr_wait+sleep_interval))
            sleep $sleep_interval
        fi
    done
}

slugify() {
    echo "$1" | tr 'A-Z' 'a-z' | sed -e 's/[^a-zA-Z0-9]/-/g' | awk 'BEGIN{OFS="-"}{$1=$1;print $0}' | sed -e 's/--*/-/g' -e 's/^-//' -e 's/-$//'
}

fetch_konnect_cp() {
    echo ">fetch_konnect_cp" >> $LOG_FILE
    local cp_name="${1}"
    local url="https://${KONNECT_REGION}"'.api.konghq.com/v2/control-planes/?filter\[name\]\[eq\]'"=${cp_name}"
    local response=$(curl -s --fail-with-body --request GET \
        --header "Authorization: Bearer ${KONNECT_PAT}" \
        --url "${url}" \
        --header 'accept: application/json')
    local rv=$?
    echo "${response}" >> $LOG_FILE
    if [[ $rv -ne 0 ]]; then
        CONTROL_PLANE_INFO=""
    else
        CONTROL_PLANE_INFO=$(echo "${response}" | docker run -i --rm ${JQ_IMAGE} -r '.data[0]')
        [[ "${CONTROL_PLANE_INFO}" = "null" ]] && {
            CONTROL_PLANE_INFO=""
            rv=1
        }
    fi
    echo "<fetch_konnect_cp" >> $LOG_FILE
    return $rv
}

create_konnect_cp() {
    echo ">create_konnect_cp" >> $LOG_FILE
    local cp_name="${1}"
    local cp_description="${2}"
    local cp_cluster_type="${3}"
    local body="{\"name\":\"$cp_name\",\"description\":\"$cp_description\",\"cluster_type\":\"$cp_cluster_type\"}"
    local response=$(curl -s --fail-with-body \
        --header "Authorization: Bearer ${KONNECT_PAT}" \
        --url "https://${KONNECT_REGION}.api.konghq.com/v2/control-planes" \
        --header 'Content-Type: application/json' \
        --header 'Accept: application/json' \
        --data "${body}")
    local rv=$?
    if [[ $rv -ne 0 ]]; then
        echo_fail "Unable to create control plane"
        exit 1
    else
        CONTROL_PLANE_INFO="${response}"
    fi
    echo "<create_konnect_cp" >> $LOG_FILE
    return $rv
}

clear_output_dir() {
    # Clear the output directory of all files except the log file
    echo ">clear_output_dir" >> $LOG_FILE

    # create a temporary directory
    temp_dir=$(mktemp -d)

    # move each file/directory except for the log file into the temporary directory
    for file in "${OUTPUT_DIR}"/*; do
        if [ "${file}" != "${LOG_FILE}" ]; then
            mv "${file}" "${temp_dir}"
        fi
    done

    # remove the temporary directory and its content
    rm -rf "${temp_dir}"

    echo "<clear_output_dir" >> $LOG_FILE
}

parse_konnect_cp() {
    echo ">parse_konnect_cp" >> $LOG_FILE
    CONTROL_PLANE_ID=$(echo "${CONTROL_PLANE_INFO}" | docker run -i --rm ghcr.io/jqlang/jq -r '.id')
    CONTROL_PLANE_NAME=$(echo "${CONTROL_PLANE_INFO}" | docker run -i --rm ghcr.io/jqlang/jq -r '.name')
    CONTROL_PLANE_ENDPOINT=$(echo "${CONTROL_PLANE_INFO}" | docker run -i --rm ghcr.io/jqlang/jq -r '.config.control_plane_endpoint')
    CONTROL_PLANE_TELEMETRY_ENDPOINT=$(echo "${CONTROL_PLANE_INFO}" | docker run -i --rm ghcr.io/jqlang/jq -r '.config.telemetry_endpoint')
    CONTROL_PLANE_DESCRIPTION=$(echo "${CONTROL_PLANE_INFO}" | docker run -i --rm ghcr.io/jqlang/jq -r '.description')
    echo "Control Plane ID: ${CONTROL_PLANE_ID}" >> $LOG_FILE
    echo "Control Plane Name: ${CONTROL_PLANE_NAME}" >> $LOG_FILE
    echo "Control Plane Endpoint: ${CONTROL_PLANE_ENDPOINT}" >> $LOG_FILE
    echo "Control Plane Telemetry Endpoint: ${CONTROL_PLANE_TELEMETRY_ENDPOINT}" >> $LOG_FILE
    echo "Control Plane Description: ${CONTROL_PLANE_DESCRIPTION}" >> $LOG_FILE
    echo "<parse_konnect_cp" >> $LOG_FILE
}


deck_gateway_sync_konnect() {
    echo ">deck_gateway_sync_konnect" >> $LOG_FILE
    local rv=0
    local deck_file_path="${1}"
    local cp_name="${2}"
    local konnect_pat="${3}"

    docker run --rm -v "${deck_file_path}:/kong.yaml" ${DECK_IMAGE} \
        gateway sync \
        --konnect-control-plane-name "${cp_name}" \
        --konnect-token "${konnect_pat}" /kong.yaml >> $LOG_FILE 2>&1

    rv=$?
    echo "<deck_gateway_sync_konnect" >> $LOG_FILE
    return $rv
}

generate_konnect_certs() {
    echo ">generate_konnect_certs" >> $LOG_FILE
    openssl req -new -x509 -nodes -newkey rsa:2048 \
        -subj "/CN=${APP_NAME}/C=US" -keyout "${OUTPUT_DIR}/key.crt" -out "${OUTPUT_DIR}/tls.crt" >> $LOG_FILE 2>&1

    # Add this line to fix permissions
    chmod o+r "${OUTPUT_DIR}/key.crt"

    local rv=$?
    echo "<generate_konnect_certs" >> $LOG_FILE
    return $rv
}

deploy_konnect_certs() {
    local cp_id="${1}"
    echo ">deploy_konnect_certs" >> $LOG_FILE
    echo "Generating escaped certificate to ${OUTPUT_DIR}/tls.crt.escaped" >> $LOG_FILE
    awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' "${OUTPUT_DIR}/tls.crt" > "${OUTPUT_DIR}/tls.crt.escaped"
    echo "Deploying certificate to Konnect Control Plane ${cp_id}" >> $LOG_FILE
    curl --fail-with-body -s --request POST \
        --header "Authorization: Bearer ${KONNECT_PAT}" \
        --url "https://${KONNECT_REGION}.api.konghq.com/v2/control-planes/${cp_id}/dp-client-certificates" \
        --header 'Content-Type: application/json' \
        --header 'accept: application/json' \
        --data "{\"cert\":\"$(cat ${OUTPUT_DIR}/tls.crt.escaped)\"}" >> $LOG_FILE 2>&1
    local rv=$?
    echo >> $LOG_FILE
    echo "<deploy_konnect_certs" >> $LOG_FILE
    return $rv
}

clear_konnect_certs() {
    echo ">ai_clear_konnect_certs" >> $LOG_FILE
    rm "${OUTPUT_DIR}/tls.crt" 2>/dev/null
    rm "${OUTPUT_DIR}/key.crt" 2>/dev/null
    rm "${OUTPUT_DIR}/tls.crt.escaped" 2>/dev/null
    echo "<ai_clear_konnect_certs" >> $LOG_FILE
}

deck_gateway_sync() {
    echo ">deck_gateway_sync" >> $LOG_FILE
    local rv=0
    local deck_file_path="${1}"

    docker run --network "${NETWORK_NAME}" --rm -v "${deck_file_path}:/kong.yaml" ${DECK_IMAGE} \
        gateway sync '/kong.yaml' --kong-addr "http://${APP_NAME}-gateway:8001" >> $LOG_FILE 2>&1

    rv=$?
    echo "<deck_gateway_sync" >> $LOG_FILE
    return $rv
}

deck_file_openapi2kong() {
    echo ">deck_file_openapi2kong" >> $LOG_FILE
    local oas_file="${1}"
    local deck_file_path="${2}"
    local response=$(cat "${oas_file}" | docker run -i --rm ${DECK_IMAGE} file openapi2kong)
    local rv=$?
    if [[ $rv -ne 0 ]]; then
        echo "Failed to convert OpenAPI specification file to decK format" >> $LOG_FILE
        return $rv
    else
        echo "${response}" > "${deck_file_path}"
    fi
    echo "<deck_file_openapi2kong" >> $LOG_FILE
}

# first argument is a working directory, the input files must be there
# and the output file will be written there
deck_file_merge() {
    echo ">deck_file_merge" >> $LOG_FILE
    local dir="${1}"
    local input_file_pattern="${2}"
    local output_file="${3}"

    echo "Merging decK files in ${dir} with pattern ${input_file_pattern} to ${output_file}" >> $LOG_FILE

    local response=$(docker run --rm -v "${dir}:/tmp" --entrypoint /bin/sh ${DECK_IMAGE} \
        -c "deck file merge --output-file /tmp/${output_file} /tmp/${input_file_pattern}")
    local rv=$?
    if [[ $rv -ne 0 ]]; then
        echo "Failed to merge decK files: ${response}" >> $LOG_FILE
        return $rv
    fi

    echo "<deck_file_merge" >> $LOG_FILE
    return $rv
}

deck_file_patch() {
    echo ">deck_file_patch" >> $LOG_FILE
    local input_file="${1}"
    local patch_file="${2}"
    local output_file="${3}"
    echo "Patching decK file ${input_file} with ${patch_file} to ${output_file}" >> $LOG_FILE
    local response=$(cat "${input_file}" | docker run -i --rm -v "${patch_file}:/tmp/patch.yaml" ${DECK_IMAGE} file patch /tmp/patch.yaml)
    local rv=$?
    if [[ $rv -ne 0 ]]; then
        echo "Failed to patch decK file: ${response}" >> $LOG_FILE
        return $rv
    else
        echo "${response}" > "${output_file}"
    fi
    echo "<deck_file_patch" >> $LOG_FILE
    return $rv
}

curl_with_fail() {
  declare -i rv=0
  local OUTPUT_FILE=$(mktemp)
  declare -a cmd=( curl -L --silent --output "$OUTPUT_FILE" --write-out "%{http_code}" "$@" )
  local HTTP_CODE=$("${cmd[@]}")
  if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
    rv=22
  fi
  cat $OUTPUT_FILE >> $LOG_FILE
  rm $OUTPUT_FILE
  echo "rv=$rv"
  return $rv
}

ensure_docker() {
  {
    docker ps -q > /dev/null 2>> $LOG_FILE
  } || {
    return 1
  }
}

# #####################################################################################
# Using the filesystem like a hashtable here.  Files are keys, values are the contents
# This prooved easier then trying to force bash 4 with associative arrays or another 
# solution. 
write_env_var() {
    local environment_dir="${OUTPUT_DIR}/environment"
    mkdir -p ${environment_dir}
    local name="${1}"
    local value="${2}"
    echo "${value}" > "${environment_dir}/${name}"
}
read_env_var() {
    local environment_dir="${OUTPUT_DIR}/environment"
    local name="${1}"
    cat "${environment_dir}/${name}"
}
write_env_file() {
    local file_path="${1}"
    mkdir -p $(dirname "${file_path}")
    local environment_dir="${OUTPUT_DIR}/environment"
    > "${file_path}"
    # loop through the environment directory and write the contents to the file
    for file in ${environment_dir}/*
    do
        if [ -f "${file}" ]; then # Ensure it is a file and not a directory
            file_name=$(basename "${file}")
            echo "${file_name}=$(< "${file}")" >> "${file_path}"
        fi
    done
}

clear_env() {
    echo ">clear_env" >> $LOG_FILE
    rm -f "${OUTPUT_DIR}/environment/*" 2>> $LOG_FILE
    rm -f "${KONG_ENV_FILE}" 2>> $LOG_FILE
    echo "<clear_env" >> $LOG_FILE
}

# #####################################################################################

docker_pull_images() {
  echo ">docker_pull_images" >> $LOG_FILE
  echo_wait "Downloading Docker images... " noline
  docker pull ${POSTGRES_IMAGE} >> $LOG_FILE 2>&1 && docker pull ${KONG_IMAGE} >> $LOG_FILE 2>&1 \
    && docker pull ${JQ_IMAGE} >> $LOG_FILE 2>&1 && docker pull ${DECK_IMAGE} >> $LOG_FILE 2>&1
  local rv=$?
  echo "<docker_pull_images" >> $LOG_FILE
  return $rv
}

destroy_kong() {
  echo ">destroy_kong" >> $LOG_FILE
  echo_wait "Destroying previous $APP_NAME containers... " noline
  docker rm -f $GW_NAME >> $LOG_FILE 2>&1
  docker rm -f $DB_NAME >> $LOG_FILE 2>&1
  docker network rm "${NETWORK_NAME}" >> $LOG_FILE 2>&1
  echo "<destroy_kong" >> $LOG_FILE
}

delete_konnect_cp() {
  local cp_name="${KONNECT_CONTROL_PLANE_NAME:-${DEFAULT_KONNECT_CONTROL_PLANE_NAME}}"
  echo_wait "Deleting Konnect Control Plane '$cp_name': " noline
  fetch_konnect_cp "${cp_name}"
  CP_ID_TO_DELETE=$(echo "${CONTROL_PLANE_INFO}" | docker run -i --rm ${JQ_IMAGE} -r '.id')
  if [[ "$CP_ID_TO_DELETE" != "null" && -n "$CP_ID_TO_DELETE" ]]; then
    curl -s -X DELETE \
      --header "Authorization: Bearer ${KONNECT_PAT}" \
      --url "https://${KONNECT_REGION}.api.konghq.com/v2/control-planes/${CP_ID_TO_DELETE}" \
      --header 'accept: application/json' >> $LOG_FILE 2>&1
  fi
  echo_pass ""
}

prepare_for_new_run() {
  DB_NAME="${APP_NAME}-database"
  GW_NAME="${APP_NAME}-gateway"
  NETWORK_NAME="${APP_NAME}-net"
  KONG_ENV_FILE="${OUTPUT_DIR}/${APP_NAME}.env"
  LOG_FILE="${LOG_FILE:-${OUTPUT_DIR}/$APP_NAME.log}"
  mkdir -p $(dirname "${LOG_FILE}")
  clear_output_dir
}

init_network() {
  echo ">init_network" >> $LOG_FILE
  docker network create "${NETWORK_NAME}" >> "$LOG_FILE" 2>&1 || true
  local rv=$?
  echo "<init_network" >> $LOG_FILE
  return $rv
}

wait_for_kong() {
  echo ">wait_for_kong" >> $LOG_FILE
  local rv=0
  retry 30 docker exec "${GW_NAME}" kong health --v >> "$LOG_FILE" 2>&1
  rv=$? 
  echo "<wait_for_kong" >> $LOG_FILE
  return $rv
}

init_db() {
  echo ">init_db" >> $LOG_FILE
  local rv=0
  docker run --rm --network="${NETWORK_NAME}" -e "KONG_DATABASE=postgres" \
      --env-file "${KONG_ENV_FILE}" "${VOLUMES[@]}" ${KONG_IMAGE} \
      kong migrations bootstrap >> $LOG_FILE 2>&1
  rv=$?
  echo "<init_db" >> $LOG_FILE
  return $rv
}

wait_for_db() {
  echo ">wait_for_db" >> $LOG_FILE 
  local rv=0
  retry 30 docker exec "$DB_NAME" pg_isready >> $LOG_FILE 2>&1 || rv=$? 
  echo "<wait_for_db" >> $LOG_FILE 
  return $rv
}

db() {
  echo ">db" >> $LOG_FILE
  echo_wait "Starting database... " noline
  local db_port=0
  # not certain why, but the 1 second sleep seems required to allow the socket to fully open and db to be ready
  docker run -d --name "${DB_NAME}" --network="${NETWORK_NAME}" -e "POSTGRES_DB=${POSTGRES_DB}" -e "POSTGRES_USER=${POSTGRES_USER}" -e "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" ${POSTGRES_IMAGE} >> $LOG_FILE 2>&1 && \
      wait_for_db && \
      sleep 1 && \
      init_db
  local rv=$?
  echo "<db" >> $LOG_FILE
  return $rv
}

kong() {
  echo ">kong" >> $LOG_FILE
  echo_wait "Starting Kong Gateway... " noline
 
  if [ "$USE_DEFAULT_PORTS" = true ]; then
    local proxy_port_bind="-p ${PROXY_PORT}:${DEFAULT_PROXY_PORT}"
    local proxy_https_port_bind="-p ${HTTPS_PROXY_PORT}:${DEFAULT_HTTPS_PROXY_PORT}"
    local admin_port_bind="-p ${ADMIN_PORT}:${DEFAULT_ADMIN_PORT}"
    local manager_port_bind="-p ${MANAGER_PORT}:${DEFAULT_MANAGER_PORT}"
    local devportal_port_bind="-p ${DEVPORTAL_PORT}:${DEFAULT_DEVPORTAL_PORT}"
    local files_port_bind="-p ${FILES_PORT}:${DEFAULT_FILES_PORT}"  
    docker run -d --name "${GW_NAME}" --network="${NETWORK_NAME}" \
        --env-file "${KONG_ENV_FILE}" ${proxy_port_bind} ${proxy_https_port_bind} ${admin_port_bind} \
        ${manager_port_bind} ${devportal_port_bind} ${files_port_bind} \
        "${UNKNOWN_PORT_BIND_LIST[@]}" "${VOLUMES[@]}" "${KONG_IMAGE}" \
        >> "$LOG_FILE" 2>&1 && \
        wait_for_kong && \
        sleep 2
  else
    docker run -d --name "$GW_NAME" --network="${NETWORK_NAME}" \
        --env-file "${KONG_ENV_FILE}" "${VOLUMES[@]}" -P ${KONG_IMAGE} \
        >> $LOG_FILE 2>&1 && \
        wait_for_kong && \
        sleep 2
  fi

  local rv=$?
  echo "<kong" >> $LOG_FILE
  return $rv
}

get_dataplane_port() {
  local endpoint=$(docker port $GW_NAME 8000/tcp 2>/dev/null)
  if [ $? -eq 0 ];
  then
    local arrIN=(${endpoint//:/ })
    echo ${arrIN[1]}
  else
    echo ""
  fi
}
get_https_dataplane_port() {
  local endpoint=$(docker port $GW_NAME 8443/tcp 2>/dev/null)
  if [ $? -eq 0 ];
  then
    local arrIN=(${endpoint//:/ })
    echo ${arrIN[1]}
  else
    echo ""
  fi
}
get_admin_port() {
  local endpoint=$(docker port $GW_NAME 8001/tcp 2>/dev/null)
  if [ $? -eq 0 ];
  then
    local arrIN=(${endpoint//:/ })
    echo ${arrIN[1]}
  else
    echo ""
  fi
}
get_manager_port() {
  local endpoint=$(docker port $GW_NAME 8002/tcp 2>/dev/null)
  if [ $? -eq 0 ];
  then
    local arrIN=(${endpoint//:/ })
    echo ${arrIN[1]}
  else
    echo ""
  fi
}
get_devportal_port() {
  local endpoint=$(docker port $GW_NAME 8003/tcp 2>/dev/null)
  if [ $? -eq 0 ];
  then
    local arrIN=(${endpoint//:/ })
    echo ${arrIN[1]}
  else
    echo ""
  fi
}
get_filesapi_port() {
  local endpoint=$(docker port $GW_NAME 8004/tcp 2>/dev/null)
  if [ $? -eq 0 ];
  then
    local arrIN=(${endpoint//:/ })
    echo ${arrIN[1]}
  else
    echo ""
  fi
}

# This function will process a -p argument request
# It's expected that the argument will look like
# hostport:containerport
# This will set the appropriate script level variable
# based on the argument
process_port_bind_request() {
  local request="${1}"
  IFS=':' read -ra KVP <<< "$request"
  if [[ ${#KVP[@]} -eq 2 ]]; 
  then
    local container_port_request="${KVP[1]}"
    if [[ $container_port_request -eq $DEFAULT_PROXY_PORT ]]; then
      PROXY_PORT="${KVP[0]}"
    elif [[ $container_port_request -eq $DEFAULT_HTTPS_PROXY_PORT ]]; then
      HTTPS_PROXY_PORT="${KVP[0]}"
    elif [[ $container_port_request -eq $DEFAULT_ADMIN_PORT ]]; then
      ADMIN_PORT="${KVP[0]}"
    elif [[ $container_port_request -eq $DEFAULT_MANAGER_PORT ]]; then
      MANAGER_PORT="${KVP[0]}"
    elif [[ $container_port_request -eq $DEFAULT_DEVPORTAL_PORT ]]; then
      DEVPORTAL_PORT="${KVP[0]}"
    elif [[ $container_port_request -eq $DEFAULT_FILES_PORT ]]; then
      FILES_PORT="${KVP[0]}"
    else
      UNKNOWN_PORT_BIND_LIST+=(-p ${request})
    fi
  else
    echo_fail "Port bind request '${request}' is invalid"
    exit 1
  fi
}
process_volume_bind_request() {
  echo ">process_volume_bind_request $@" >> $LOG_FILE
  local request="${1}"
  VOLUMES+=(-v ${request})
  echo "<process_volume_bind_request $@" >> $LOG_FILE
}

# This function will process any user set env vars, and maybe 
# set some local state for the script.
#
# The initial use case here is the user has provided KONG_PASSWORD 
# and secured the admin API, preventing the installation of the
# mock service. So this will write a header w/ that password for curl
# to use.
#
# This function expects two arguments:
#   First the variable name, second the variable value
process_environment_variable() {
  local name="${1}" 
  local value="${2}" 

  if [ "${name}" = "KONG_PASSWORD" ]; then
    ADMIN_API_HEADERS+=('Kong-Admin-Token: '"${value}")
  fi
}

write_standard_env_vars() {
    write_env_var KONG_DATABASE "${KONG_DATABASE}"
    write_env_var KONG_PG_HOST "${DB_NAME}"
    write_env_var KONG_PG_USER "${POSTGRES_USER}"
    write_env_var KONG_PG_PASSWORD "${POSTGRES_PASSWORD}"
    write_env_var KONG_ADMIN_LISTEN "0.0.0.0:8001, 0.0.0.0:8444 ssl"
    write_env_var KONG_PROXY_ACCESS_LOG "/dev/stdout"
    write_env_var KONG_ADMIN_ACCESS_LOG "/dev/stdout" 
    write_env_var KONG_PROXY_ERROR_LOG "/dev/stderr"
    write_env_var KONG_ADMIN_ERROR_LOG "/dev/stderr" 
    write_env_var KONG_ROLE "${KONG_ROLE}"
    write_env_var KONG_KONNECT_MODE "${KONG_KONNECT_MODE}"
}

# Variables provided to the script via the -e VAR=VALUE or -e VAR syntax
write_user_provided_env_vars() {
  if [ ${#ENVIRONMENT[@]} -gt 0 ]; then
    for item in "${ENVIRONMENT[@]}"
    do
      IFS='=' read -ra KVP <<< "$item"
      if [ "${#KVP[@]}" -gt "1" ]; 
      then
        write_env_var "${KVP[0]}" "${KVP[1]}"
        process_environment_variable "${KVP[0]}" "${KVP[1]}"
      else 
        local value="$(eval echo \$"${KVP[0]}")"
        write_env_var "${KVP[0]}" "${value}"
        process_environment_variable "${KVP[0]}" "${value}"
      fi
    done
  fi
}

# This file could be useful to clients that want to interact with Kong Gateway
write_user_env_file() {
  echo "##############################################################################" > ${USER_ENV_FILE}
  echo "# The following env file can be sourced and the variables used to " >> ${USER_ENV_FILE}
  echo "# connect to Kong Gateway" >> ${USER_ENV_FILE}
  echo "##############################################################################" >> ${USER_ENV_FILE}
  echo >> ${USER_ENV_FILE} 
  echo "export KONG_PROXY=localhost:$(get_dataplane_port)" >> ${USER_ENV_FILE}
  echo "export KONG_ADMIN_API=localhost:$(get_admin_port)" >> ${USER_ENV_FILE}

  local manager_port=$(get_manager_port)
  [[ -z "$manager_port" ]] || echo "export KONG_MANAGER=localhost:$manager_port" >> ${USER_ENV_FILE}

  local devportal_port=$(get_devportal_port)
  [[ -z "$devportal_port" ]] || echo "export KONG_DEV_PORTAL=localhost:$devportal_port" >> ${USER_ENV_FILE}

  local files_port=$(get_filesapi_port)
  [[ -z "$files_port" ]] || echo "export KONG_FILES_API=localhost:$files_port" >> ${USER_ENV_FILE}
}

install_mock_service() {
  echo ">install_mock_service" >> $LOG_FILE
  echo_info "Adding mock service at path /mock"

  if [ "${KONG_ROLE}" = "data_plane" ]; then
    echo_warn "Mock service installation is not supported in Konnect mode. Skipping..."
    return 1
  fi

  ## First install the mock service under the admin api services route
  declare -a params=( --data name=mock --data url=http://httpbin.org/anything )
  for h in "${ADMIN_API_HEADERS[@]}"
  do
    params+=( -H )
    params+=("${h}")
  done

  local ctrl_plane_ep="http://localhost:$(get_admin_port)"

  params+=("${ctrl_plane_ep}/services")
  declare -i rv=$(curl_with_fail "${params[@]}")

  if [ $rv -eq 0 ]; then
    # then install the /mock route to point to the service on Kong Gateway
    params=( --data 'paths[]=/mock' --data name=mock )
    for h in "${ADMIN_API_HEADERS[@]}"
    do
      params+=( -H )
      params+=("${h}")
    done
    params+=("${ctrl_plane_ep}/services/mock/routes")
    declare -i rv=$(curl_with_fail "${params[@]}")
  fi  

  echo >> $LOG_FILE 
  echo "<install_mock_service" >> $LOG_FILE
  return $rv
}

validate_kong() {
    echo ">validate_kong" >> $LOG_FILE
    docker run --rm --network="${NETWORK_NAME}" \
        subfuzion/netcat@sha256:7e808e84a631d9c2cd5a04f6a084f925ea388e3127553461536c1248c3333c8a \
        -zv "${GW_NAME}" $(get_dataplane_port) >> $LOG_FILE 2>&1 
    local rv=$?
    echo "<validate_kong" >> $LOG_FILE
    return $rv
}

usage() {
  echo "Runs a Docker based Kong Gateway. The following documents the arguments and variables supported by the script."
  echo
  echo "Supported arguments:"
  echo "  -k Provide the Konnect personal access token"
  echo "  -n Provide the Konnect Control Plane name"
  echo "  -r Specify a different docker image registry (Default: $KONG_IMAGE_REPO)"
  echo "  -i Specify a different docker image name (Default: $KONG_IMAGE_NAME)"
  echo "  -t Specify a different docker image tag (Default: $DEFAULT_KONG_IMAGE_TAG)"
  echo "  -a Specify a different name for the quickstart application (Default: $APP_NAME)"
  echo "  -s Specify running Kong Gateway in secure mode."
  echo "      Admin API operations will need to use header 'Kong-Admin-Token: ${DEFAULT_KONG_PASSWORD}'. (Default: false)"
  echo "  -P Requests the usage of the available ports on the host machine instead of the default Kong Gateway ports (Default: false)"
  echo "      Docker will assign ports available on the host to each service"
  echo "  -p Explicitly bind a given host port to a Kong Gateway exposed port (multiple are allowed)."
  echo "      For example, to expose the Admin API port on host port 55202"
  echo "      -p 55202:8001"
  echo "  -e Pass environment variables to the Kong Gateway container"
  echo "      0-n number of -e arguments are permitted"
  echo "      To pass in a variable with a value in the current environment:"
  echo "        -e KONG_LICENSE_DATA"
  echo "      Or to pass an explicit value for a variable:"
  echo "        -e KONG_ENFORCE_RBAC=on"
  echo "  -v Bind mount a volume to the Kong Gateway container"
  echo "      0-n number of -v arguments are permitted"
  echo "  -m Installs a test service pointing to httpbin.org. A /mock route is added to utilize it. (Default: false)"
  echo "  -D Runs the quickstart in DB-Less mode and the database container is not started. (Default: false)"
  echo "  -h Shows this help" 
  echo "  -d Destroys the current running instance. If you've changed the applicaiton name,"
  echo "    include the argument -a <appname>"
  echo 
  echo "Examples:"
  echo 
  echo "  * To Run Kong Gateway with a license, pass the license in via the KONG_LICENSE_DATA variable."
  echo "    Assuming you have the license data stored in KONG_LICENSE_DATA, pass the value in directly."
  echo "    If you're running the script directly on the command line, it would look like this:"
  echo "      ./quickstart -e KONG_LICENSE_DATA"
  echo "    If you're running the script by downloading via curl, it would look like this:"
  echo "      curl -Ls get.konghq.com/quickstart | bash -s -- -e KONG_LICENSE_DATA"
  echo
  echo "  * To run in licensed mode and enable RBAC, set KONG_LICENSE_DATA and KONG_ENFORCE_RBAC:"
  echo "      ./quickstart -e KONG_LICENSE_DATA -e KONG_ENFORCE_RBAC=on"
  echo
  echo "See the source repository for more information or to contact the developers:"
  echo "  https://github.com/Kong/get.konghq.com"
  exit 0
}

secure() {
  echo_warn "Secure mode enabled (requires Kong Gateway Enterprise to take effect)."
  ENVIRONMENT+=( KONG_PASSWORD=$DEFAULT_KONG_PASSWORD )
  ENVIRONMENT+=( KONG_AUDIT_LOG=on )
  ENVIRONMENT+=( KONG_LOG_LEVEL=debug )
  ENVIRONMENT+=( KONG_ENFORCE_RBAC=on )
  ENVIRONMENT+=( KONG_ADMIN_GUI_AUTH=basic-auth )
  ENVIRONMENT+=( KONG_ADMIN_GUI_SESSION_CONF='{"storage": "kong", "secret": "kongFTW", "cookie_name": "admin_session", "cookie_samesite":"off", "cookie_secure":false}' )
}

maybe_port_issue() {
  local re1='^.*listen tcp4 [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:([0-9]{1,5}): bind: address already in use'
  local re2='^.*Bind for 0\.0\.0\.0:([0-9]{1,5}) failed: port is already allocated'
  local er=$(tail -n 2 $LOG_FILE)
  if [[ $er =~ $re1 ]] || [[ $er =~ $re2 ]]; then
    echo_fail "Could not bind to port: ${BASH_REMATCH[1]}"
    echo
    echo_warn "Verify that the Kong Gateway default ports (8000-8004) are available on your host machine before trying again"
    echo_warn "You can also use the -p flag which will use available ports on the host machine"
  fi
}

destroy() {
  echo_wait "Stopping and removing containers and networks: " noline
  docker rm -f "${GW_NAME}" >/dev/null 2>&1
  docker rm -f "${DB_NAME}" >/dev/null 2>&1
  docker network rm "${NETWORK_NAME}" >/dev/null  2>&1
  echo_pass ""

  if [ -n "$KONNECT_PAT" ]; then
    delete_konnect_cp "${DEFAULT_KONNECT_CONTROL_PLANE_NAME}"
  fi

  echo
  echo_bullet "Thanks for trying the Kong Gateway quickstart!"
  echo_bullet "The quickest way to get started in production is with Kong Konnect"
  echo
  echo_point "https://get.konghq.com/konnect-free"
  echo
  exit 0
}

display_logging_info() {
  echo_info "Debugging info logged to:"
  echo "    $LOG_FILE"
}

display_summary() {
    echo
    echo "🐵 Kong Gateway Ready 🐵"
    
    echo
    echo "======================================================="
    echo " 🛑                               Stopping Kong Gateway"
    echo "======================================================="
    echo
    echo_bullet "To stop the gateway run:"
    echo
    echo_point "curl -s https://get.konghq.com/quickstart |" noline
    printf ' \ \n'
    echo "    bash -s -- -d -a $APP_NAME"
    echo
    echo "Or remove the Docker container directly."

    echo
    echo "======================================================="
    echo " ⚒️                                   Using Kong Gateway"
    echo "======================================================="
    
    echo
    local dp_http_port="$(get_dataplane_port)"
    local dp_https_port="$(get_https_dataplane_port)"
    local ctrl_plane_port="$(get_admin_port)"

    echo_bullet "Kong Gateway Data Plane endpoints:"
    if [ ! -z "${dp_http_port}" ]; then
      echo "    HTTP  = http://localhost:${dp_http_port}"
    fi
    if [ ! -z "${dp_https_port}" ]; then
      echo "    HTTPS = https://localhost:${dp_https_port}"
    fi

    echo
    echo_bullet "This script has written an environment file you can"
    echo "  source to make connecting to Kong Gateway easier. "
    echo "  Run this command to source these variables into your"
    echo "  environment:"
    echo
    echo_point "source ${USER_ENV_FILE}"
    echo 
    echo_bullet "Now you can make requests to your Kong Gateway using "
    echo "  variables from the file, for example:"
    echo
    echo_point 'curl -s $KONG_PROXY/mock'
    
    echo
    echo "======================================================="
    echo " ⚒️                              Administer Kong Gateway"
    echo "======================================================="

    if [ "${KONG_ROLE}" = "data_plane" ]; then
        echo
        echo "Kong Gateway is running in data plane mode."
        echo

        if [ "${KONG_KONNECT_MODE}" == "on" ]; then
            echo "To administer the gateway, use the Konnect"
            echo "Control Plane named '$CONTROL_PLANE_NAME'."

            if [ $IS_WITH_DECK == true ]; then
              echo
              echo "======================================================="
              echo " 👉                                      Configure decK"
              echo "======================================================="
              echo
              echo "Run the following commands in your terminal to"
              echo "configure the required environment variables:"
              echo
              echo "export DECK_KONNECT_TOKEN=\$KONNECT_TOKEN"
              echo "export DECK_KONNECT_CONTROL_PLANE_NAME=$CONTROL_PLANE_NAME"
              echo "export KONNECT_CONTROL_PLANE_URL=https://$KONNECT_REGION.api.konghq.com"
              echo "export KONNECT_PROXY_URL='http://localhost:${dp_http_port}'"
            fi
        else
            echo "To administer the gateway, use the Control Plane"
            echo "  configured when deployed."
        fi
    else
        local ctrl_plane_ep="https://localhost:${ctrl_plane_port}"
        echo

        echo_bullet "Kong Gateway Admin API endpoint:"
        echo "   HTTP = http://localhost:${ctrl_plane_port}"
        echo
        echo_bullet "To administer the gateway with curl:"
        echo
       
        echo_point "curl" noline
        for h in "${ADMIN_API_HEADERS[@]}"
        do
          printf " -H "
          printf "'%s'" "$h"
        done
        printf " -s ${ctrl_plane_ep}\n"
    fi

}

main() {
  local do_usage=false
  local do_destroy=false
  local securely=false
  IS_WITH_DECK=false

  while getopts "a:r:i:t:e:p:v:hdPsmDk:n:-:" o; do
    case "${o}" in
      r)
        KONG_IMAGE_REPO=${OPTARG}
        ;;
      i)
        KONG_IMAGE_NAME=${OPTARG}
        ;;
      t)
        KONG_IMAGE_TAG=${OPTARG}
        ;;
      e)
        ENVIRONMENT+=("${OPTARG}")
        ;;
      v)
        process_volume_bind_request ${OPTARG}
        ;;
      a)
        APP_NAME=${OPTARG}
        ;;
      h)
        do_usage=true
        ;;
      d)
        do_destroy=true
        ;;
      s)
        securely=true
        ;;
      p)
        process_port_bind_request ${OPTARG}
        ;;
      P)
        USE_DEFAULT_PORTS=false
        ;;
      D)
        DB_LESS_MODE=true
        KONG_DATABASE=off
        ;;
      m)
        INSTALL_MOCK_SERVICE=true
        ;;
      k)
        KONNECT_PAT=${OPTARG}
        ;;
      n)
        KONNECT_CONTROL_PLANE_NAME=${OPTARG}
        ;;
      -)
        case "${OPTARG}" in
          deck-output)
            IS_WITH_DECK=true
            ;;
        esac
        ;;
    esac
  done

  # This is a helper for when a user has specified the well known
  # OSS image name 'kong', but hasn't overriden the image registry. 
  # Then the script will help the user out by not specifying an image registry
  # because Kong OSS is pulled like: docker pull kong:2.8.1-ubuntu
  if [ "$KONG_IMAGE_REPO" = "$DEFAULT_KONG_IMAGE_REPO" ] && [ "$KONG_IMAGE_NAME" = "kong" ];
  then
    KONG_IMAGE_REPO=""
  fi

  if [ -z "$KONG_IMAGE_REPO" ]
  then
    KONG_IMAGE="${KONG_IMAGE_NAME}:${KONG_IMAGE_TAG}"
  else
    KONG_IMAGE="${KONG_IMAGE_REPO}/${KONG_IMAGE_NAME}:${KONG_IMAGE_TAG}"
  fi

  prepare_for_new_run

  echo ">main $@" >> $LOG_FILE

  if [ "$do_usage" = true ] ; then
    usage
  fi
    
  if [ "$do_destroy" = true ] ; then
    echo "Destroying local Kong Gateway Deployment..."
    echo
    destroy
  else
    echo_bullet "Deploying Kong Gateway to Docker..."
    if [ ${DISPLAY_LOGGING_INFO} = "true" ] ; then
      display_logging_info
    fi
  fi

  ensure_docker || { 
    echo_fail "Docker is not available, check $LOG_FILE"; exit 1 
  }

  if [ -n "$KONNECT_PAT" ]; then
    echo_bullet "Konnect mode enabled via provided token"
    KONG_ROLE="data_plane"
    KONG_DATABASE="off"
    KONG_KONNECT_MODE="on"

    # Auto-configure Konnect
    KONNECT_CONTROL_PLANE_NAME="${KONNECT_CONTROL_PLANE_NAME:-${DEFAULT_KONNECT_CONTROL_PLANE_NAME}}"

    # Delete existing CP if it exists
    # Fetch the CP info to get its ID
    delete_konnect_cp

    # Create the CP
    create_konnect_cp "${KONNECT_CONTROL_PLANE_NAME}" \
        "Created by the quickstart script" \
        "CLUSTER_TYPE_CONTROL_PLANE"
    if [[ $? -ne 0 ]]; then
        echo_fail ""
        echo "Failed to create Konnect Control Plane"
        exit 1
    fi

    parse_konnect_cp || {
      echo_fail ""
      echo_fail "Failed to parse Konnect Control Plane info, check $LOG_FILE"
      exit 1
    }

    generate_konnect_certs || {
      echo_fail ""
      echo_fail "Failed to generate TLS certificate, check $LOG_FILE"
      exit 1
    }

    deploy_konnect_certs "${CONTROL_PLANE_ID}" || {
      echo_fail ""
      echo_fail "Failed to deploy TLS certificate to Konnect Control Plane, check $LOG_FILE"
      exit 1
    }

    export KONG_CLUSTER_MTLS="pki"
    export KONG_CLUSTER_CONTROL_PLANE="${CONTROL_PLANE_ENDPOINT#https://}:443"
    export KONG_CLUSTER_SERVER_NAME="${CONTROL_PLANE_ENDPOINT#https://}"
    export KONG_CLUSTER_TELEMETRY_ENDPOINT="${CONTROL_PLANE_TELEMETRY_ENDPOINT#https://}:443"
    export KONG_CLUSTER_TELEMETRY_SERVER_NAME="${CONTROL_PLANE_TELEMETRY_ENDPOINT#https://}"
    export KONG_LUA_SSL_TRUSTED_CERTIFICATE="system"

    ENVIRONMENT+=(KONG_CLUSTER_MTLS=${KONG_CLUSTER_MTLS})
    ENVIRONMENT+=(KONG_CLUSTER_CONTROL_PLANE=${KONG_CLUSTER_CONTROL_PLANE})
    ENVIRONMENT+=(KONG_CLUSTER_SERVER_NAME=${KONG_CLUSTER_SERVER_NAME})
    ENVIRONMENT+=(KONG_CLUSTER_TELEMETRY_ENDPOINT=${KONG_CLUSTER_TELEMETRY_ENDPOINT})
    ENVIRONMENT+=(KONG_CLUSTER_TELEMETRY_SERVER_NAME=${KONG_CLUSTER_TELEMETRY_SERVER_NAME})
    ENVIRONMENT+=(KONG_LUA_SSL_TRUSTED_CERTIFICATE=${KONG_LUA_SSL_TRUSTED_CERTIFICATE})
    ENVIRONMENT+=(KONG_CLUSTER_CERT=/etc/kong/certs/tls.crt)
    ENVIRONMENT+=(KONG_CLUSTER_CERT_KEY=/etc/kong/certs/key.crt)

    VOLUMES+=("-v${OUTPUT_DIR}:/etc/kong/certs")
  fi

  if [ "$SKIP_KONG_START" != "true" ];
  then
    docker_pull_images && echo_pass "" || { 
      echo_warn "Docker image download failed, check $LOG_FILE. Continuing...";
    }
  fi
 
  if [ "$SKIP_KONG_START" != "true" ];
  then
    destroy_kong && echo_pass ""
  fi
 
  if [ "$securely" = true ] ; then
    secure
  fi

  write_standard_env_vars
  write_user_provided_env_vars
  write_env_file "${KONG_ENV_FILE}"

  init_network || {
    echo_fail "Initalization steps failed, check $LOG_FILE"; exit 1
  }

  if [ "$DB_LESS_MODE" != "true" ] && [ "$KONG_KONNECT_MODE" != "on" ];
  then
    db && echo_pass "" || {
      echo_fail "DB initialization failed, check $LOG_FILE"; exit 1
    }
  fi 

  if [ "$SKIP_KONG_START" != "true" ]; 
  then
    kong && echo_pass "" || {
      echo_fail ""
      echo
      echo "Kong Gateway initialization failed, check $LOG_FILE"; 
      maybe_port_issue
      exit 1
    }
  fi

  echo_wait "Validating kong state... " noline
  validate_kong && echo_pass "" || {
    echo_fail ""
    echo
    echo "Validation failed, could not connect to Kong Gateway. Check $LOG_FILE"
    maybe_port_issue
    exit 1
  }

  if [ "$INSTALL_MOCK_SERVICE" = true ] ; then
    install_mock_service && {
      echo_pass "mock service installed. /mock -> httpbin.org"
    } || {
      echo_fail "Installing mock service failed, check $LOG_FILE"; exit 1
    }
  fi

  write_user_env_file

  if [ "$DISPLAY_SUMMARY" = true ] ; then
    display_summary
  fi

  echo "<main" >> $LOG_FILE
}

# If a user wants to source this script they need to provide this argument
#   otherwise it's a challenge to detect execution vs sourcing in all contexts
#   (like piping from a curl or cat command)
if [ "${1}" != "--source" ]; then
    echo
    main "$@"
fi

