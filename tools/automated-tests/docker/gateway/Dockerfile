FROM ubuntu:latest
RUN apt-get update -y && apt-get install -y curl && apt-get install -y docker.io
COPY ./binaries/deck /usr/local/bin/
RUN chmod +x /usr/local/bin/deck
