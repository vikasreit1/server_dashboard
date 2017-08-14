#!/usr/bin/env python
"""
   This is the wget module and provides the get_http_response function 
   which prints the HTTP response of the given url
"""
import httplib
import socket
import json

#--------------------
# Set the timeout
#--------------------
response_timeout = 10


def get_http_response(host, port="12376", path="/"):
    """ This function retreives the status code of a website by requesting
        HEAD data from the host. This means that it only requests the headers.
        If the host cannot be reached or something else goes wrong, it returns
        None instead.

    :Example:

    get_http_response("www.google.com", port="80", path="/")
    """
    socket.setdefaulttimeout(response_timeout)
    try:
        conn = httplib.HTTPConnection(host+":"+port)
        conn.request("HEAD", path)
        return conn.getresponse().status
    except httplib.BadStatusLine as err:
        print "bad statusline %s" % err
        # pass
    except StandardError:
        return None
    else:
        return None


#-----------
# Testing 
#-----------
with open('urls.json') as data_file:    
    data = json.load(data_file)
    ucpport=data['UCPProdWorkers']['portnumber']
    for i in data['UCPProdWorkers']['components'] :
      host_name=i['hostname']
      urlname=i['url']
      try:
        print get_http_response(urlname,port=ucpport)
      except:
        print "error"

#print get_http_response("www.google.com", port="80")
# print get_http_response("sv5-prd-artifapp001.sv.splunk.com", port="8081")
# print get_http_response("sv3-orca-0408e7b4.sv.splunk.com", port="12376", path="/")
# print get_http_response("sv3-orca-0408e7b4.sv.splunk.com", port="7946")
# print get_http_response("sv3-orca-0307e1b1.sv.splunk.com", port="12376", path="/")
# print get_http_response("ucp.splunk.com", port="443")
# print get_http_response("sv3-orca-0308e5b4.sv.splunk.com", port="12376", path="/")
# print get_http_response("sv3-orca-0308e8b1.sv.splunk.com", port="12376", path="/")
# print get_http_response("sv3-orca-0313e1b3.sv.splunk.com", port="12376", path="/")
# print get_http_response("sv3-orca-0313e1b3123.sv.splunk.com", port="12376", path="/")




