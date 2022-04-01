#!/usr/bin/env python

# Copyright 2019 The soda Authors.
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


import requests
import json
import sys
import time


def get_soda_token(ip):
    url = "http://" + ip + "/identity/v3/auth/tokens"
    headers = {
        'content-type': 'application/json'
    }
    data = {
        "auth": {
            "identity": {
                "methods": ["password"],
                "password": {
                    "user": {
                        "name": "admin",
                        "domain": {"id": "default"},
                        "password": "soda@123"
                    }
                }
            },
            "scope": {
                "project": {
                    "domain": {
                        "id": "default"
                    },
                    "name": "admin"
                }
            }
        }
    }
    resp = requests.post(
        url=url, data=json.dumps(data), headers=headers, verify=False)
    if resp.status_code != 201:
        print("Request for soda Token failed ", resp.status_code)
        raise Exception('Request for soda Token failed')

    return resp.headers['X-Subject-Token']


def get_project_id(ip, token):
    url = "http://" + ip + "/identity/v3/projects"
    headers = {
        'x-auth-token': token
    }
    resp = requests.get(url=url, headers=headers)
    if resp.status_code != 200:
        print("Request for Project ID failed", resp.status_code)
        raise Exception('Request for Project ID failed')


    json_resp = json.loads(resp.text)

    for proj in json_resp['projects']:
        if proj['name'] == 'admin':
            return proj['id']

    raise Exception('Invalid response for Project ID')


def get_user_id(ip, token):
    url = "http://" + ip + "/identity/v3/users"
    headers = {
        'x-auth-token': token
    }
    resp = requests.get(url=url, headers=headers)
    if resp.status_code != 200:
        print("Request for User ID failed", resp.status_code)
        raise Exception('Request for User ID failed')

    json_resp = json.loads(resp.text)

    for usr in json_resp['users']:
        if usr['name'] == 'admin':
            return usr['id']

    raise Exception('Invalid response for User ID')


def add_services(ip, port, pid, uid):
    url = "http://" + ip  + ":" + port + "/v1beta/" + pid + "/orchestration/services"
    headers = {
        'content-type': 'application/json'
    }
    prov_vol_data = {
        "name": "volume provision",
        "description": "Volume Service",
        "tenant_id": pid,
        "user_id": uid,
        "input": "",
        "constraint": "",
        "group": "provisioning",
        "workflows": [
            {
                "definition_source": "soda.provision-volume",
                "wfe_type": "st2"
            },
            {
                "definition_source": "soda.snapshot-volume",
                "wfe_type": "st2"
            }

        ]

    }
    migrate_vol_data = {
        "name": "migration bucket",
        "description": "Migration bucket Service",
        "tenant_id": pid,
        "user_id": uid,
        "input": "",
        "constraint": "",
        "group": "migration",
        "workflows": [
            {
                "definition_source": "soda.migration-bucket",
                "wfe_type": "st2"
            }
        ]

    }

    resp = requests.post(url=url, data=json.dumps(prov_vol_data), headers=headers)
    if resp.status_code != 200:
        print("Request for Register Provision volume Services failed", resp.status_code)
        raise Exception('Request for Register Provision volume Services failed')

    print(resp.text)
    # Wait for session to expire, until fixed in orchestration code
    time.sleep(60)

    resp = requests.post(url=url, data=json.dumps(migrate_vol_data), headers=headers)
    if resp.status_code != 200:
        print("Request for Register Migrate bucket Services failed", resp.status_code)
        raise Exception('Request for Register Migrate bucket Services failed')

    print(resp.text)


if __name__ == '__main__':
    # Start
    # Args : ip, orc_ip, orc_port
    if len(sys.argv) != 4:
        print("Usage: CMD <soda_ip> <orchestration_ip> <orchestration_port>")
        raise Exception("Invalid argument")
        
    ip = sys.argv[1]
    orc_ip = sys.argv[2]
    orc_port = sys.argv[3]

    token = get_soda_token(ip)
    pid = get_project_id(ip, token)
    uid = get_user_id(ip, token)

    add_services(orc_ip, orc_port, pid, uid)
