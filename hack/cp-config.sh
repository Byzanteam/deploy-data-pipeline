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
CONFIG_EXAMPLES=("adapter-gateway/config.example" "adapter-gateway/adapter-all-in-one.example" "postgres/pg-all-in-one.example" "redis/redis-all-in-one.example" "secrets/redis-config.example" "secrets/postgres-dsn.example")

cpConfig(){
    i=0
    for (( i=0; i<=$(( ${#CONFIGS[@]} -1 )); i++ ))
    do
        if [ ! -z ${CONFIGS[$i]} ];then
            cp ${CONFIG_EXAMPLES[$i]} ${CONFIGS[$i]}
        fi
    done
}

cpConfig