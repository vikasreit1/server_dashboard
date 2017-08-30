#!/usr/bin/env python

import os,sys
import json
import urllib2
import subprocess

#from pprint import pprint

with open('urls.json') as data_file:    
    data = json.load(data_file)


for i in data['UCPProdWorkers']['components'] :
    host_name=i['hostname']
    try:
         ssh_return_code=subprocess.call(["ssh","-i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=10", "root@"+host_name, "exit"], stdout= subprocess.PIPE, stderr= subprocess.PIPE );
         # print ssh_return_code
         if ssh_return_code==0:
              sshStatus="UP"
              try:
                   dockerps_return_code=subprocess.call(["ssh","-i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=10", "root@"+host_name, "docker ps"], stdout= subprocess.PIPE, stderr= subprocess.PIPE );
                   # print dockerps_return_code
                   if dockerps_return_code==0:
                       container_count=subprocess.call(["ssh","-i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=10", "root@"+host_name, "docker info | grep Running | cut -f2 -d':' "], stdout= subprocess.PIPE, stderr= subprocess.PIPE );
                       dockerPS="UP"
                   else:
                       container_count=0
                       dockerPS="DOWN"
                   # print dockerPS
              except:
                   dockerPS="DOWN"
                   container_count=0
                   # print dockerPS 
              try:
                   wgetCheck=subprocess.call(["wget","--timeout=1 --tries=1 --no-check-certificate", httpsurl, "2>&1",  "| grep HTTP |", "awk '{print $6}' " ], stdout= subprocess.PIPE, stderr= subprocess.PIPE );
                   # print dockerps_return_code
                   if wgetCheck==0:
                       wgetStatus="UP"
                   else:
                       wgetStatus="DOWN"
                   # print dockerPS
              except:
                   wgetStatus="DOWN"
                   # print dockerPS 
         else:
             sshStatus="DOWN"
             dockerPS="DOWN"
             wgetStatus="DOWN"
         print "ssh:",sshStatus
         print "dockerPS:",dockerPS
         print "wgetStatus:",wgetStatus
    except:
         sshStatus="DOWN"
         dockerPS="DOWN"
         wgetStatus="DOWN"
         print "ssh:",sshStatus
         print "dockerPS:",dockerPS
         print "wgetStatus:",wgetStatus


 


