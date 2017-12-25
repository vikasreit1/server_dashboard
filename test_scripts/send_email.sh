#!/bin/bash


sendEmail(){
outputFile="total_maildata.txt"
#toaddr=$1
(
echo "From: Engineering_Infrastructure@splunk.com"
#echo "To: $toaddr"
echo "To: vitikyalapati@splunk.com"
echo "MIME-Version: 1.0"
echo "Subject: Servers Status"
echo "Content-Type: text/html"
cat premail_data >> total_maildata.txt
cat maildata.txt >> total_maildata.txt
cat postmail_data >> total_maildata.txt
cat $outputFile
) | /usr/sbin/sendmail -t
}


