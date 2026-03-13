#!/bin/bash
set -e

[ -f .env ] && source .env

GITHUB_TOKEN=${GITHUB_TOKEN:?GITHUB_TOKEN must be set}
export GITHUB_TOKEN

docker build \
  --secret id=github_token,env=GITHUB_TOKEN \
  -t clive \
  container/
