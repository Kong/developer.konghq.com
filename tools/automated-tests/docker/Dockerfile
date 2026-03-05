FROM ubuntu:latest
RUN apt-get update -y && apt-get install -y apt-utils curl docker.io uuid-runtime ca-certificates curl python3 python3-pip python3-venv jq

# set python env
RUN python3 -m venv /opt/myenv
ENV PATH="/opt/myenv/bin:$PATH"

RUN ARCH=$(dpkg --print-architecture) && \
    curl -L -o deck_v1.deb https://github.com/Kong/deck/releases/download/v1.49.1/deck_v1.49.1_${ARCH}.deb && \
    dpkg -i deck_v1.deb
RUN apt-get update
RUN apt-get install ca-certificates curl
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
RUN chmod a+r /etc/apt/keyrings/docker.asc

RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-compose-plugin
RUN ARCH=$(dpkg --print-architecture) && \
    curl -L https://go.dev/dl/go1.25.3.linux-${ARCH}.tar.gz -o go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV PATH="${GOPATH}/bin:${PATH}"

RUN go install github.com/deviceinsight/kafkactl/v5@latest

# Install kubectl v1.35.2 (pinned + checksum verified)
RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64) CHECKSUM="924eb50779153f20cb668117d141440b95df2f325a64452d78dff9469145e277" ;; \
      arm64) CHECKSUM="cd859449f54ad2cb05b491c490c13bb836cdd0886ae013c0aed3dd67ff747467" ;; \
      *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL -o kubectl "https://dl.k8s.io/release/v1.35.2/bin/linux/${ARCH}/kubectl" && \
    echo "$CHECKSUM  kubectl" | sha256sum -c - && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Install helm v4.1.1 (pinned + checksum verified)
RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64) CHECKSUM="5d4c7623283e6dfb1971957f4b755468ab64917066a8567dd50464af298f4031" ;; \
      arm64) CHECKSUM="02a5fb7742469d2d132e24cb7c3f52885894043576588c6788b6813297629edd" ;; \
      *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL -o helm.tar.gz "https://get.helm.sh/helm-v4.1.1-linux-${ARCH}.tar.gz" && \
    echo "$CHECKSUM  helm.tar.gz" | sha256sum -c - && \
    tar -xzf helm.tar.gz linux-${ARCH}/helm && \
    install -o root -g root -m 0755 linux-${ARCH}/helm /usr/local/bin/helm && \
    rm -rf helm.tar.gz linux-${ARCH}

# Install k3d v5.8.3 (pinned + checksum verified)
RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64) CHECKSUM="dbaa79a76ace7f4ca230a1ff41dc7d8a5036a8ad0309e9c54f9bf3836dbe853e" ;; \
      arm64) CHECKSUM="0b8110f2229631af7402fb828259330985918b08fefd38b7f1b788a1c8687216" ;; \
      *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL -o k3d "https://github.com/k3d-io/k3d/releases/download/v5.8.3/k3d-linux-${ARCH}" && \
    echo "$CHECKSUM  k3d" | sha256sum -c - && \
    install -o root -g root -m 0755 k3d /usr/local/bin/k3d && \
    rm k3d

# Install yq v4.52.4 (pinned + checksum verified, for kubernetes-resource-property validation)
RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64) CHECKSUM="0c4d965ea944b64b8fddaf7f27779ee3034e5693263786506ccd1c120f184e8c" ;; \
      arm64) CHECKSUM="4c2cc022a129be5cc1187959bb4b09bebc7fb543c5837b93001c68f97ce39a5d" ;; \
      *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL -o yq "https://github.com/mikefarah/yq/releases/download/v4.52.4/yq_linux_${ARCH}" && \
    echo "$CHECKSUM  yq" | sha256sum -c - && \
    install -o root -g root -m 0755 yq /usr/local/bin/yq && \
    rm yq
