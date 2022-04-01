# Copyright 2018 The soda Authors.
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

BASE_DIR := $(shell pwd)
DIST_DIR := $(BASE_DIR)/build/dist
VERSION ?= $(shell git describe --exact-match 2> /dev/null || \
                 git describe --match=$(git rev-parse --short=8 HEAD) \
		 --always --dirty --abbrev=8)
BUILD_TGT := installer-$(VERSION)

all: help

help:
	@echo This is used for packaging automation. This repo\'s contents
	@echo may be used without the need for compilation.
	@echo
	@echo Refer to the README file in each subdirectory for specific
	@echo details for that installer type.

version:
	@echo ${VERSION}

.PHONY: dist
dist:
	( \
	    rm -fr $(DIST_DIR) && mkdir -p $(DIST_DIR)/$(BUILD_TGT) && \
	    cd $(DIST_DIR) && \
	    cp -r $(BASE_DIR)/ansible $(BUILD_TGT)/ && \
	    cp -r $(BASE_DIR)/charts $(BUILD_TGT)/ && \
	    cp -r $(BASE_DIR)/salt $(BUILD_TGT)/ && \
	    cp -r $(BASE_DIR)/conf $(BUILD_TGT)/ && \
	    cp -r $(BASE_DIR)/contrib $(BUILD_TGT)/ && \
	    cp $(BASE_DIR)/LICENSE $(BUILD_TGT)/ && \
	    zip -r $(DIST_DIR)/$(BUILD_TGT).zip $(BUILD_TGT) && \
	    tar zcvf $(DIST_DIR)/$(BUILD_TGT).tar.gz $(BUILD_TGT) && \
	    tree \
	)
