#!/usr/bin/env bash

# MIT License

# Copyright (c) 2019 Byzan Team

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -o errexit
set -o nounset
set -o pipefail

CONFIGS=("adapter-gateway/config.yml" "adapter-gateway/adapter-all-in-one.yaml" "postgres/pg-all-in-one.yaml" "redis/redis-all-in-one.yaml" "secrets/redis-config.yaml" "secrets/postgres-dsn.yaml")

source hack/envs.conf

url="host=postgres.openfaas.svc.cluster.local port=5432 user=${DB_USER} dbname=${DB_NAME} password=${DB_PASSWORD}"

dsn=$(echo -n "$url" | base64)

export POSTGRES_DSN=$dsn

url="redis-0.redis.openfaas.svc.cluster.local:6379;${REDIS_PASSWORD};0"

dsn=$(echo -n "$url" | base64)

export REDIS_CONFIG=$dsn

passwd=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)

export OPENFAAS_PASSWORD=$passwd


rpConfig(){
    i=0
    for (( i=0; i<=$(( ${#CONFIGS[@]} -1 )); i++ ))
    do
        if [ ! -z ${CONFIGS[$i]} ];then 
            envsubst < ${CONFIGS[$i]} > tmp && mv tmp ${CONFIGS[$i]}
        fi
    done
}

rpConfig
