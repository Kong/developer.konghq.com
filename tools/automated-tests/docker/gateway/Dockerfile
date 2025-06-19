FROM ubuntu:latest
RUN apt-get update -y && apt-get install -y curl && apt-get install -y docker.io && apt-get install -y uuid-runtime
RUN curl -L -o deck_v1.48.deb https://github.com/Kong/deck/releases/download/v1.48.0/deck_v1.48.0_amd64.deb && \
    dpkg -i deck_v1.48.deb
