#!/usr/bin/env python

import smtplib

def sendEmailmess(message_content):
                        sender = 'EngineeringInfrastructure@splunk.com'
			receivers = ['vitikyalapati@splunk.com']

			message = """From: From Person <engineeringInfrastructure@splunk.com>
			To: To Person <vitikyalapati@splunk.com>
			Subject: SMTP e-mail test
			"""
                        post_message="""

                                      <HTML>
                                      <style>
                                      table#t02 {
                                          background-color: lightyellow;
                                      }
                                      </style><TABLE border=1>
                                      <TD bgcolor=peachpuff>Groupname</TD><TD bgcolor=peachpuff>Hostname</TD><TD bgcolor=peachpuff>Docker Daemon</TD><TD bgcolor=peachpuff>Wget Status</TD><TD bgcolor=peachpuff>Node Status</TD><TD bgcolor=peachpuff>Port Status</TD><TD bgcolor=peachpuff>SSH Status</TD><TD bgcolor=peachpuff>Overlay Status</TD><TD bgcolor=peachpuff>Controller PING</TD>
                                      <TR>
                                  </TABLE>

                                  <TABLE border=1 id=\"t02\">

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
                                      <td>\"docker service restart\" / \"systemctl start docker \"</td>
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
                        total_message=message+post_message
			try:
			   smtpObj = smtplib.SMTP('mail.splunk.com')
			   smtpObj.sendmail(sender, receivers, total_message)
			   print "Successfully sent email"
			except SMTPException:
			   print "Error: unable to send email"



sendEmailmess("this is the test testing ")
