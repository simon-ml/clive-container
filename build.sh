#!/bin/bash
set -e

docker build \
  -f container/Dockerfile \
  -t clive \
  .
