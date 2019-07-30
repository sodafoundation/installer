#!/usr/bin/env python
##############################################################
# Copyright (c) 2019 Saltstack formulas, The OpenSDS Authors
##############################################################
# encoding: utf-8
# This script displays a formula menu for default profile.
# http://npyscreen.readthedocs.org/introduction.html
# todo: dynamic menu generation based on argv

try:
    import sys, os, platform, subprocess
except ImportError("Cannot import sys, os, platform, subprocess, modules"):
    exit(100)
try:
    import npyscreen
except ImportError("Cannot import npyscreen"):
    exit(102)

class TestApp(npyscreen.NPSApp, outdir='/srv/salt'):
    def __init__(self):
        self.dir = outdir
        # Set option users will see in the multi select widget
        self.infra = 'infra'
        self.telemetry = 'telemetry'
        self.keystone = 'keystone'
        self.config = 'config'
        self.database = 'database'
        self.auth = 'auth'
        self.hotpot = 'hotpot'
        self.sushi = 'sushi'
        self.backend = 'backend'
        self.dock = 'dock'
        self.dashboard = 'dashboard'
        self.gelato = 'gelato'
        self.freespace = 'freespace'
        
    def main(self):
        # Create form
        F  = npyscreen.Form(name = "Profiles:",)
        # Create multi select widget on form
        multi_select = F.add(npyscreen.TitleMultiSelect, max_height =-2, value = [], name="Select Components",
                values = [
                          self.infra,
                          self.telemetry,
                          self.keystone,
                          self.config,
                          self.database,
                          self.auth,
                          self.hotpot,
                          self.sushi,
                          self.backend,
                          self.dock,
                          self.dashboard,
                          self.gelato,
                          self.freespace], scroll_exit=True)
        # Allow users to interact with form
        F.edit()
        self.selection = multi_select.get_selected_objects()
        self.write_top()

    def write_top(self):
        # Map selected options to salt states
        select_list = []
        for item in self.selection:

            if item == self.infra:
                select_list.append('infra')
            if item == self.telemetry:
                select_list.append('telemetry')
            if item == self.keystone:
                select_list.append('keystone')
            if item == self.config:
                select_list.append('config')
            if item == self.database:
                select_list.append('database')
            if item == self.hotpot:
                select_list.append('hotpot')
            if item == self.auth:
                select_list.append('auth')
            if item == self.sushi:
                select_list.append('sushi')
            if item == self.backend:
                select_list.append('backend')
            if item == self.dock:
                select_list.append('dock')
            if item == self.dashboard:
                select_list.append('dashboard')
            if item == self.gelato:
                select_list.append('gelato')
            if item == self.freespace:
                select_list.append('freespace')

        if select_list:
           try:
               f = open(self.dir + '/top.sls', 'w')
               f.write("base:\n")
               f.write("  '*':\n")
               for ele in select_list:
                   f.write("    - %s\n" % ele)
           finally:
               f.close()
        else:
          print("No selection made.")


#### Run the select screen & handle interrupts
if __name__ == "__main__":
    try:
        outdir = '/srv/salt'
        if len(sys.argv) > 1:
            outdir = str(sys.argv[1])
        App = TestApp(outdir)
        App.run()
    except KeyboardInterrupt:
        print('Interrupted')
        try:
            sys.exit(12)
        except SystemExit:
            os._exit(12)
