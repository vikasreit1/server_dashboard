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
         dockerps_return_code=subprocess.call(["ssh","-i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=10", "root@"+host_name, "service docker start"], stdout= subprocess.PIPE,
                                  stderr= subprocess.PIPE );
         print dockerps_return_code
         if dockerps_return_code==0:
           dockerPS="UP"
         else:
           dockerPS="DOWN"
         print dockerPS
         print "#======================= "+host_name
    except:
         dockerPS="DOWN"
         print dockerPS 
         print "#======================= "+host_name

if dockerps_return_code==1:
   dockerPS="UP"
else:
   dockerPS="DOWN"
 


