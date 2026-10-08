FROM ubuntu:latest
RUN apt-get update -y && apt-get install -y apt-utils curl docker.io uuid-runtime ca-certificates curl python3 python3-pip python3-venv jq unzip bubblewrap git telnet openssl default-jre-headless

# set python env
RUN python3 -m venv /opt/myenv
ENV PATH="/opt/myenv/bin:$PATH"

RUN ARCH=$(dpkg --print-architecture) && \
    curl -L -o deck_v1.deb https://github.com/Kong/deck/releases/download/v1.69.0/deck_v1.69.0_${ARCH}.deb && \
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

# Install kongctl
RUN curl -fsSL https://get.konghq.com/kongctl | sh
#RUN ARCH=$(dpkg --print-architecture) && \
#    curl -sL "https://github.com/Kong/kongctl/releases/download/v1.10.0/kongctl_linux_${ARCH}.zip" -o kongctl.zip && \
#    unzip kongctl.zip && \
#    mv kongctl /usr/local/bin/ && \
#    rm kongctl.zip && \
#    kongctl version --full
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV PATH="${GOPATH}/bin:${PATH}"


RUN curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash

RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/root/.local/bin:${PATH}"

# Install Node.js 22.x (LTS) via NodeSource, then codex CLI
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs
RUN npm install -g @openai/codex
RUN npm install -g @qwen-code/qwen-code
RUN npm install -g @google/gemini-cli
RUN go install github.com/deviceinsight/kafkactl/v5@latest

# Install kubectl v1.35.2 (pinned)
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL -o kubectl "https://dl.k8s.io/release/v1.35.2/bin/linux/${ARCH}/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Install helm v4.1.1 (pinned)
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL -o helm.tar.gz "https://get.helm.sh/helm-v4.1.1-linux-${ARCH}.tar.gz" && \
    tar -xzf helm.tar.gz linux-${ARCH}/helm && \
    install -o root -g root -m 0755 linux-${ARCH}/helm /usr/local/bin/helm && \
    rm -rf helm.tar.gz linux-${ARCH}

# Install k3d v5.8.3 (pinned)
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL -o k3d "https://github.com/k3d-io/k3d/releases/download/v5.8.3/k3d-linux-${ARCH}" && \
    install -o root -g root -m 0755 k3d /usr/local/bin/k3d && \
    rm k3d

# Install yq v4.52.4 (pinned, for kubernetes-resource-property validation)
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL -o yq "https://github.com/mikefarah/yq/releases/download/v4.52.4/yq_linux_${ARCH}" && \
    install -o root -g root -m 0755 yq /usr/local/bin/yq && \
    rm yq

# Install cosign v2.6.5 (pinned, for verify-image-signatures-and-attestations tests)
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL -o cosign "https://github.com/sigstore/cosign/releases/download/v2.6.5/cosign-linux-${ARCH}" && \
    install -o root -g root -m 0755 cosign /usr/local/bin/cosign && \
    rm cosign

# Install regctl v0.11.7 (pinned, for verify-image-signatures-and-attestations tests)
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL -o regctl "https://github.com/regclient/regclient/releases/download/v0.11.7/regctl-linux-${ARCH}" && \
    install -o root -g root -m 0755 regctl /usr/local/bin/regctl && \
    rm regctl

# Install kustomize v5.8.2 (pinned, for the operator upgrade how-to's CRD step)
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL -o kustomize.tar.gz "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.8.2/kustomize_v5.8.2_linux_${ARCH}.tar.gz" && \
    tar -xzf kustomize.tar.gz kustomize && \
    install -o root -g root -m 0755 kustomize /usr/local/bin/kustomize && \
    rm -rf kustomize kustomize.tar.gz

# Install grpcurl v1.9.4 (pinned, for the GRPCRoute how-to)
RUN ARCH=$(dpkg --print-architecture) && \
    [ "$ARCH" = "amd64" ] || [ "$ARCH" = "arm64" ] || { echo "Unsupported architecture: $ARCH" && exit 1; } && \
    curl -fsSL -o grpcurl.tar.gz "https://github.com/fullstorydev/grpcurl/releases/download/v1.9.4/grpcurl_1.9.4_linux_${ARCH}.tar.gz" && \
    tar -xzf grpcurl.tar.gz grpcurl && \
    install -o root -g root -m 0755 grpcurl /usr/local/bin/grpcurl && \
    rm -rf grpcurl grpcurl.tar.gz
