import smtplib

sender = 'from@fromdomain.com'
receivers = ['vitikyalapati@splunk.com']

message = """From: From Person <from@fromdomain.com>
To: To Person <to@todomain.com>
Subject: SMTP e-mail test

This is a test e-mail message from vitikyalapati.
"""

try:
   smtpObj = smtplib.SMTP('mail.splunk.com')
   smtpObj.sendmail(sender, receivers, message)
   print "Successfully sent email"
except SMTPException:
   print "Error: unable to send email"
