#!/usr/bin/env python

# Copyright 2020 The SODA Authors.
# Copyright 2010 United States Government as represented by the
# Administrator of the National Aeronautics and Space Administration.
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

"""db create  script for delfin """

import os
import sys
from oslo_config import cfg
from delfin import db
from delfin import version
from oslo_db import options as db_options
CONF = cfg.CONF
db_options.set_defaults(cfg.CONF,
                        connection='sqlite:////var/lib/delfin/delfin.sqlite')
def remove_prefix(text, prefix):
    if text.startswith(prefix):
        return text[len(prefix):]
    return text
def main():
    CONF(sys.argv[1:], project='delfin',
         version=version.version_string())
    connection = CONF.database.connection
    head_tail = os.path.split(connection)
    path = remove_prefix(head_tail[0], 'sqlite:///')
    if not os.path.exists(path):
        os.makedirs(path)
    db.register_db()
if __name__ == '__main__':
    main()

