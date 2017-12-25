#! /usr/bin/python

import smtplib

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# me == my email address
# you == recipient's email address
me = "EngineeringInfrastructure@email.com"
you = "vitikyalapati@splunk.com"

# Create message container - the correct MIME type is multipart/alternative.
msg = MIMEMultipart('alternative')
msg['Subject'] = "UCP Service Status"
msg['From'] = me
msg['To'] = you

# Create the body of the message (a plain-text and an HTML version).
text = "Hi!\nHow are you?\nHere is the link you wanted:\nhttp://www.python.org"
html = """\

<HTML>
<style>
table#t02 {
    background-color: lightyellow;
}
</style><TABLE border=1>
<TD bgcolor=peachpuff>Groupname</TD><TD bgcolor=peachpuff>Hostname</TD><TD bgcolor=peachpuff>Docker Daemon</TD><TD bgcolor=peachpuff>Wget Status</TD><TD bgcolor=peachpuff>Node Status</TD><TD bgcolor=peachpuff>Port Status</TD><TD bgcolor=peachpuff>SSH Status</TD><TD bgcolor=peachpuff>Overlay Status</TD><TD bgcolor=peachpuff>Controller PING</TD>
<TR>
<TH bgcolor=lightyellow>UCPProd</TH><TH bgcolor=lightyellow>sv3-orca-0308e5b4</TH><TH bgcolor=salmon>DOWN</TH><TH bgcolor=salmon>DOWN</TH><TH bgcolor=salmon>DOWN</TH><TH bgcolor=salmon>DOWN</TH><TH bgcolor=salmon>DOWN</TH><TH bgcolor=salmon>DOWN</TH><TH bgcolor=salmon>DOWN</TH>
<TR>
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

# Record the MIME types of both parts - text/plain and text/html.
part1 = MIMEText(text, 'plain')
part2 = MIMEText(html, 'html')

# Attach parts into message container.
# According to RFC 2046, the last part of a multipart message, in this case
# the HTML message, is best and preferred.
msg.attach(part1)
msg.attach(part2)

# Send the message via local SMTP server.
s = smtplib.SMTP('mail.splunk.com')
# sendmail function takes 3 arguments: sender's address, recipient's address
# and message to send - here it is sent as one string.
s.sendmail(me, you, msg.as_string())
s.quit()
