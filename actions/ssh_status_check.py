#!/usr/bin/env python

import os,sys
import json
import urllib2
import subprocess

#from pprint import pprint

def check_wget_dockerps_ssh(host, port="12376",httpurl="n/a"):
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
                       # print container_count
                   else:
                       container_count=0
                       dockerPS="DOWN"
                   # print dockerPS
              except:
                   dockerPS="DOWN"
                   container_count=0
                   # print dockerPS 
         else:
             sshStatus="DOWN"
             dockerPS="DOWN"
         print "ssh:",sshStatus
         print "dockerPS:",dockerPS
    except:
         sshStatus="DOWN"
         dockerPS="DOWN"
         print "ssh:",sshStatus
         print "dockerPS:",dockerPS


#-----------
# Testing 
#-----------
with open('urls.json') as data_file:
    data = json.load(data_file)
    ucpport=data['UCPProdWorkers']['portnumber']
    for i in data['UCPProdWorkers']['components'] :
        host_name=i['hostname']
        httpurl="http://"+host_name
        urlname=i['url']
        # try:
        check_wget_dockerps_ssh(urlname ,12376,httpurl)
        # except:
            # print "error"


