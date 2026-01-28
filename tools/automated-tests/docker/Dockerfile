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