#!/usr/bin/env bash

podman run --name "homer" \
  -p 8080:8080 \
  --mount type=bind,source="./assets/config.yml",target=/www/assets \
  --restart=unless-stopped \
  b4bz/homer:latest
