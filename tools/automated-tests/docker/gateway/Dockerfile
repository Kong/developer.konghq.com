FROM ubuntu:latest
RUN apt-get update -y && apt-get install -y curl && apt-get install -y docker.io && apt-get install -y uuid-runtime
RUN curl -L -o deck_v1.deb https://github.com/Kong/deck/releases/download/v1.49.1/deck_v1.49.1_amd64.deb && \
    dpkg -i deck_v1.deb
