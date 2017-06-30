#!/usr/bin/ksh

#-------------------------------------------------------------
# Setting the variables that  will be used in the script
# Script is being refactored in python - @author:vitikyalapati
# Revision: 1.0
#-------------------------------------------------------------
dirpath=`pwd`
FILE=${dirpath}/urls.txt
HC_File=health_chk_status
HEALTHCHECK=${dirpath}/health_chk_status
MAIL_FROM=SERVICES-STATUS@serverName.com
MAIL_TO=vitikyalapati@splunk.com
MAIL_SUB="Servers and Services status"
MAILFILE=maildata.txt

WGET=/usr/local/bin/wget
TIMEOUT=6 #Seconds
time=`date +"%m%d%y-%H%M%S"`
LIMIT=" - "
PREHTML=${dirpath}/prehtml_file
POSTHTML=${dirpath}/posthtml_file

OUTPUTDIR="/var/tmp/OUTPUT$$"
TEMPDIR="/var/tmp/TEMP$$"

OUTPUTDIR=${dirpath}/OUTPUT
TEMPDIR=${dirpath}/TEMP

TEMP_FILE=$OUTPUTDIR/all_env_${time}.csv
HTML_FILE=$OUTPUTDIR/final_output.html

#--------------------
# Empty the mail file
#--------------------
> maildata.txt  
> total_maildata.txt

#--------------------------------------------------Future Support for CURL and Verbose output---------------------------------------------------------------------------
# Curl Command
# curl -i --ssl --connect-timeout 20 --retry 1 --retry-delay 2 --insecure https://repo.splunk.com/artifactory/api/system/ping 2>&1 | grep HTTP | tail -1 | cut -f2 -d" "
# response=$(curl -i --ssl --connect-timeout 20 --retry 1 --retry-delay 2 --insecure $url 2>&1 | grep HTTP | tail -1 | cut -f2 -d" ")
# echo "      <th id=\"$color\" title=\"$url\"><a href=\"$url\" target="_top">${status}</a></th> " >> $i.html
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#  We do a telnet on the DB Nodes to check the port is up
#---------------------------------------------------------- 


sendEmail(){
outputFile="total_maildata.txt"
toaddr="vitikyalapati@splunk.com"
(
echo "From: Engineering_Infrastructure@splunk.com"
echo "To: $toaddr"
#echo "To: vitikyalapati@splunk.com,rbraun@splunk.com,rwen@splunk.com"
echo "MIME-Version: 1.0"
echo "Subject: Servers Status"
echo "Content-Type: text/html"
cat premail_data >> total_maildata.txt
cat maildata.txt >> total_maildata.txt
cat postmail_data >> total_maildata.txt
cat $outputFile
) | /usr/sbin/sendmail -t
}

sendTxt(){
txtaddress= vitikyalapati@splunk.com
outputFile="total_maildata.txt"
(
echo "From: Engineering_Infrastructure@splunk.com"
echo "To: vitikyalapati@splunk.com"
#echo "To: vitikyalapati@splunk.com,rbraun@splunk.com,rwen@splunk.com"
echo "MIME-Version: 1.0"
echo "Subject: Servers Status"
echo "Content-Type: text/html"
cat $outputFile
) | /usr/sbin/sendmail -t
}

checkAlertPriority(){
   groupname=$1
   nodename=$2
   url=$3
   alertpriority=$4
   if [ $alertpriority == 1 ]
   then
        sendTxt 
        sendEmail
    else
        sendEmail
    fi
}

generateMaildata(){
   groupname=$1
   nodename=$2
   url=$3
   mail_file=maildata.txt
   echo "<TH bgcolor=lightblue>$nodename</TH><TH bgcolor=red>Down</TH>" >> maildata.txt
   echo "<TR>" >> maildata.txt
}

getResponse(){
        groupname=$1
        nodename=$2
        url=$3
        portno=$4
        if [[ $nodename =~ .*DB.* ]]
        then
             nc -z $url $portno  2>/dev/null
             if [ $? -eq 0 ];
             then
                  response="200"
             else
                  response="500"
                  generateMaildata $groupname $nodename $url
             fi
        else
             response=$(wget --secure-protocol=TLSv1  --timeout=20 --tries=1 --no-check-certificate $url 2>&1  | grep HTTP | tail -1 | cut -f6 -d" ")
        fi
        if [ "$response" == "200" ]; then 
                color="green"
                status="UP"
        elif [ "$response" == "302" ]; then 
                color="lightBlue"
                status="REDIRECT"
        elif [ "$response" == "403" ]; then
                color="lightBlue"
                status="FILTER?"
                generateMaildata $groupname $nodename $url
        elif [ "$response" == "404" ]; then 
                color="salmon"
                status="NOT_FOUND"
                generateMaildata $groupname $nodename $url
        elif [ "$response" == "500" ]; then 
                color="salmon"
                status="500"
                generateMaildata $groupname $nodename $url
        elif [ "$response" == "EMPTY" ]; then 
                color="grey"
                status=""
        else 
                color="salmon"
                status="DOWN"
                generateMaildata $groupname $nodename $url
        fi

}

#----------------------------------------------------------------------------------------------------
#     We first set the title in the html snippet and then do a loop on the respective group urls
#     Here File is the urls file
#     The case of 301 redirect is also handled, in case we have a redirect on the url
#     and capture only the final HTTP response
#----------------------------------------------------------------------------------------------------
for i in `cat $FILE | egrep -v '^#|^$' | cut -f1 -d';' | sort | uniq`
do
	rm ${i}.html  2> /dev/null
	touch ${i}.html
	echo "   <tr> " > $i.html
	echo "      <th id=\"grey\" title=\"$i\">$i</th> " >> $i.html
        firstrow=0
        count=0
	for j in `cat $FILE | egrep -v '^#|^$' | grep $i `
	do
		groupname=`echo $j | cut -f1 -d';' `
		nodename=`echo $j | cut -f2 -d';' `
		url=`echo $j | cut -f3 -d';' `
		portno=`echo $j | cut -f4 -d';' `
        priority=`echo $j | cut -f5 -d';' `
                getResponse $groupname $nodename $url $portno
                count=$(( $count + 1 ))
                firstrow=$(( $firstrow + 1 ))
        if [ $firstrow -eq 21 ] && [ $count -gt 21 ]
        then
             echo "   </tr>" >> $i.html
             echo "   <tr>" >> $i.html 
	     echo "      <th id=\"white\" ></th> " >> $i.html
             count=0    ## Count is reset to 0
        elif [ $count -gt 20 ] && [ $firstrow -gt 21 ]
        then
             echo "   </tr>" >> $i.html
             echo "   <tr>" >> $i.html
             echo "      <th id=\"white\" ></th> " >> $i.html
             count=0    ## Count is reset to 0 
        fi
        echo "      <th id=\"$color\" title=\"$url\"><a href=\"$url\" target="_top">${status}${LIMIT}${nodename}</a></th> " >> $i.html
       
    done
    echo "   </tr>" >> $i.html
done

#----------------------------------------
# Clean up the directory of the output
#----------------------------------------
rm index.html*  2> /dev/null
rm ping* 2> /dev/null
rm artifactory* 2> /dev/null
#rm ${HEALTHCHECK}_*  2> /dev/null
#rm ${HEALTHCHECK}_${time} 2> /dev/null

#-------------------------------------------------
# Move the old health check reports into archive
#-------------------------------------------------
mkdir -p HISTORY
if [ -f ${HEALTHCHECK}_* ]; then
   mv ${HEALTHCHECK}_* HISTORY/
fi
touch ${HEALTHCHECK}_${time}

#---------------------------------------
# Echo the output into the final file
#---------------------------------------
cat $PREHTML >> ${HEALTHCHECK}_${time}

#----------------------------------------
# Get the output from all the group files
#----------------------------------------
for i in `cat $FILE | egrep -v '^#|^$' | cut -f1 -d';' | sort | uniq`
do
	cat ${i}.html >> ${HEALTHCHECK}_${time}
done

cat $POSTHTML >> ${HEALTHCHECK}_${time}
mv  ${HEALTHCHECK}_${time} ${HEALTHCHECK}_${time}.html

for i in `cat $FILE | egrep -v '^#|^$' | cut -f1 -d';' | sort | uniq`
do
        rm ${i}.html
done

sendEmail

echo " ----------------------------------------------------------------- " 
echo " |    Access the health check status using the below url after   | "
echo " |    Start the webserver ---> python -m SimpleHTTPServer 2223 & | "
echo " ----------------------- Access  URL ----------------------------- " 
echo " |    localhost:2223/${HC_File}_${time}.html        | "
echo " ------------------------------------------------------------------ " 



