FROM node:lts-bookworm

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && npm install -g firebase-tools@latest \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
