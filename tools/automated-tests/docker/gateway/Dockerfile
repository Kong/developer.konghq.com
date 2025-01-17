FROM ubuntu:latest
RUN apt-get update -y && apt-get install -y curl && apt-get install -y docker.io
RUN curl -L https://github.com/mheap/setup-deck-apply-preview/raw/refs/heads/main/deck-ubuntu > /usr/local/bin/deck
RUN chmod +x /usr/local/bin/deck
