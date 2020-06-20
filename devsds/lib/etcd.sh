#!/bin/bash

# Copyright 2020 The SODA Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A set of helpers for starting/running etcd for tests
_XTRACE_ETCD=$(set +o | grep xtrace)
set +o xtrace

soda::etcd::stop() {
    kill "$(cat $ETCD_DIR/etcd.pid)" >/dev/null 2>&1 || :
    wait "$(cat $ETCD_DIR/etcd.pid)" >/dev/null 2>&1 || :
}

soda::etcd::clean_etcd_dir() {
      rm -rf "${ETCD_DIR-}"
}

soda::etcd::download() {
  (
    cd "${OPT_DIR}"
    url="https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz"
    download_file="etcd-v${ETCD_VERSION}-linux-amd64.tar.gz"
    soda::util::download_file "${url}" "${download_file}"
    tar xzf "${download_file}"
    cp etcd-v${ETCD_VERSION}-linux-amd64/etcd bin
    cp etcd-v${ETCD_VERSION}-linux-amd64/etcdctl bin
  )
}

soda::etcd::install() {
    # validate before running
    if [ ! -f "${OPT_DIR}/bin/etcd" ]; then
        soda::etcd::download
    fi

    # Start etcd
    mkdir -p $ETCD_DIR
    nohup ${OPT_DIR}/bin/etcd --advertise-client-urls http://${ETCD_HOST}:${ETCD_PORT} --listen-client-urls http://${ETCD_HOST}:${ETCD_PORT}\
    --listen-peer-urls http://${ETCD_HOST}:${ETCD_PEER_PORT} --data-dir ${ETCD_DATADIR} --debug 2> "${ETCD_LOGFILE}" >/dev/null &
    echo $! > $ETCD_DIR/etcd.pid

    soda::echo_summary "Waiting for etcd to come up."
    soda::util::wait_for_url "http://${ETCD_HOST}:${ETCD_PORT}/v2/machines" "etcd: " 0.25 80
    curl -fs -X PUT "http://${ETCD_HOST}:${ETCD_PORT}/v2/keys/_test"
}

soda::etcd::cleanup() {
    soda::etcd::stop
    soda::etcd::clean_etcd_dir
}

soda::etcd::uninstall(){
    : # do nothing
}

soda::etcd::uninstall_purge(){
    : # do nothing
}

# Restore xtrace
$_XTRACE_ETCD
