#!/usr/bin/env python

import smtplib

sender = 'EngineeringInfrastructure@splunk.com'
receivers = ['vitikyalapati@splunk.com']

message = """From: From Person <engineeringInfrastructure@splunk.com>
To: To Person <vitikyalapati@splunk.com>
Subject: SMTP e-mail test

This is a test e-mail message from aws-artifactory.
"""

try:
   smtpObj = smtplib.SMTP('mail.splunk.com')
   smtpObj.sendmail(sender, receivers, message)
   print "Successfully sent email"
except SMTPException:
   print "Error: unable to send email"


