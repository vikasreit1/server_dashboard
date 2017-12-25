#!/usr/bin/env python

import smtplib
import wget
import os 
import sys
import urllib2

def sendEmail(message_content):
    sender = 'EngineeringInfrastructure@splunk.com'
    receivers = ['vitikyalapati@splunk.com']
    # receivers = ['vitikyalapati@splunk.com','scentoni@splunk.com','mdickey@splunk.com']
    pre_message = """From: UCP Health <engineeringInfrastructure@splunk.com>
    To: To Person <vitikyalapati@splunk.com>
    Subject: UCP Health Check Status"""

    message_body=message_content
    post_message="""
                  </TABLE>

                  <TABLE border=1 id="t02">

                      <tr>
                      <th>Status</th>
                      <th>Action</th>
                      <th>Helper Commands</th>
                    </tr>
                    <tr>
                      <td>Service down</td>
                      <td>start it up</td>
                      <td>docker service restart / systemctl start docker</td>
                    </tr>
                    <tr>
                      <td>Node down</td>
                      <td>Bring up the node using ilo</td>
                      <td> Use the ilo console to reboot -->  Sample Login URL:https://sv3-orca-0313e0b2.ilo.sv.splunk.com/login.html</td>
                    </tr>
                    <tr>
                      <td>Port is down</td>
                      <td>Start the service</td>
                      <td>"docker service restart" / "systemctl start docker "</td>
                    </tr>
                    <tr>
                      <td>SSH down</td>
                      <td>The system needs to be rebooted using ilo</td>
                      <td>Use the ilo console to reboot --> Sample Login URL:  https://sv3-orca-0313e0b2.ilo.sv.splunk.com/login.html</td>
                    </tr>
                  </TABLE>
                  <br>
                  <br>
                  <TABLE border=1>
                  <TR>
                      <TD>Latest - Status</TD>
                      <TD bgcolor=peachpuff>http://ttam10.sv.splunk.com:2223/health_chk_status_latest.html</TD>
                  </TR>
                  <TR>
                      <TD>HISTORY</TD>
                      <TD bgcolor=peachpuff>http://ttam10.sv.splunk.com:2223/HISTORY</TD>
                    </TR>
                  </TABLE>
                  </BODY></HTML>
    """
    total_maildata=pre_message+message_body+post_message
    try:
       smtpObj = smtplib.SMTP('mail.splunk.com')
       smtpObj.sendmail(sender, receivers, message)
       print "Successfully sent email"
    except SMTPException:
       print "Error: unable to send email"


sendEmail(" This this is being tested ")
