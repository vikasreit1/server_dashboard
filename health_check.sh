#!/usr/bin/ksh

#-------------------------------------------------------------
# Setting the variables that  will be used in the script
# Script is being refactored in python - @author:vitikyalapati
# Revision: 1.0
#-------------------------------------------------------------
# loop continuously 
while true
do

dirpath=`pwd`
FILE=${dirpath}/test_urls.txt
HC_File=health_chk_status
HEALTHCHECK=${dirpath}/health_chk_status
MAIL_FROM=SERVICES-STATUS@serverName.com

MAIL_TO="vitikyalapati@splunk.com,scentoni@splunk.com"
MAIL_SUB="Servers and Services status"
MAILFILE=maildata.txt

WGET=/usr/local/bin/wget
TIMEOUT=6 #Seconds
cur_time=`date +"%m%d%y-%H%M%S"`
footer_time=`date`
LIMIT=" - "
PREHTML=${dirpath}/prehtml_file
POSTHTML=${dirpath}/posthtml_file

OUTPUTDIR="/var/tmp/OUTPUT$$"
TEMPDIR="/var/tmp/TEMP$$"

OUTPUTDIR=${dirpath}/OUTPUT
TEMPDIR=${dirpath}/TEMP

TEMP_FILE=$OUTPUTDIR/all_env_${cur_time}.csv
HTML_FILE=$OUTPUTDIR/final_output.html

#---------------------------------------
# Empty the mail file
# total_maildata has the html included
#---------------------------------------
> maildata.txt  
> total_maildata.txt
#--------------------------------
# Can send a custom text alert
#--------------------------------
> alert_data.txt

#--------------------------------------------------Future Support for CURL and Verbose output---------------------------------------------------------------------------
# Curl Command
# curl -i --ssl --connect-timeout 20 --retry 1 --retry-delay 2 --insecure https://repo.splunk.com/artifactory/api/system/ping 2>&1 | grep HTTP | tail -1 | cut -f2 -d" "
# response=$(curl -i --ssl --connect-timeout 20 --retry 1 --retry-delay 2 --insecure $url 2>&1 | grep HTTP | tail -1 | cut -f2 -d" ")
# echo "      <th id=\"$color\" title=\"$url\"><a href=\"$url\" target="_top">${status}</a></th> " >> $i.html
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#  We do a telnet on the DB Nodes to check the port is up
#---------------------------------------------------------- 

usage(){

echo " This is the usage "

}


#------------------------------
# Alerts - Email, TXT, HipChat
#------------------------------

sendEmail(){
outputFile="total_maildata.txt"
toaddr=$1
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

sendAlert(){
outputFile="total_maildata.txt"
txtaddress="vitikyalapati@splunk.com"
(
echo "From: Engineering_Infrastructure@splunk.com"
echo "To: $txtaddress"
echo "MIME-Version: 1.0"
echo "Subject: Servers Status - Txt alert"
echo "Content-Type: text/html"
cat premail_data >> total_maildata.txt
cat maildata.txt >> total_maildata.txt
cat postmail_data >> total_maildata.txt
) | /usr/sbin/sendmail -t
}


sendHipChatAlert(){
  echo " this is hipchat alert "
}


if [ "$1" == "-h" ]; then
  echo "| ---------------------------------------------------------| "
  echo "|   Usage: `basename $0` --email=username@splunk.com     | "
  echo "| ---------------------------------------------------------| "
  exit 0
fi

# if [ $# -ne 1 ]; then
#   echo "| ---------------------------------------------------------| "
#   echo "|     Usage: `basename $0` --email=username@splunk.com     |  "
#   echo "| ---------------------------------------------------------| "
#   exit 0
# fi

for i in "$@"
do
case $i in
    -e=*|--email=*)
    EMAIL="${i#*=}"
    ;;
    *)
            # unknown option
    ;;
esac
done
  
if [[ "$EMAIL" -ne "" ]]
then
  email_address=${EMAIL}
else
  email_address=${MAIL_TO}
fi

#------------------------
# echo $email_address

#------Exit for Test------
# exit 1


#------------------------------
#  Depends on the mail data
# if maildata changes, this code 
#  needs to be revisited
#------------------------------
# cat maildata.txt | grep -v TR | cut -f 2 -d "<" | cut -f2 -d">" | sort -nr | uniq
checkAlertPriority(){
   # groupname=$1
   # nodename=$2
   # url=$3
   for i in `cat maildata.txt | grep -v TR | cut -f 2 -d "<" | cut -f2 -d">" | sort -nr | uniq`
   do
       if  [[ $i =~ .*Prod.* ]] 
       then
            alertpriority="1"
            # sendAlert
            sendEmail $email_address
            break
       else
            alertpriority="0"
       fi
   done
   # alertpriority=$4
   # if [ "$alertpriority" == "1" ]
   # then

   #  fi
}

# Do we "Need ?" to variabilize the Service_Status and service_color ?- Down , which is hardcoded below
generateMaildata(){
   groupname=$1
   nodename=$2
   url=$3
   priority=$4
#----------------------------------------------------------------
#  Service status and service color are always RED and DOWN
#  as the maildata will be generated only if wget is a non 200
#  service_status="DOWN"
#  service_color="salmon"
#-----------------------------------------------------------------
   node_status=$5
   node_color=$6
   ssh_status=$7
   ssh_color=$8
   telnet_status=$9
   telnet_color=$10
   mail_file=maildata.txt
   if [ "$priority" == "1" ]
   then
        echo "<TH bgcolor=lightyellow>$groupname</TH><TH bgcolor=lightyellow>$nodename</TH><TH bgcolor=salmon>DOWN</TH><TH bgcolor=$node_color>$node_status</TH><TH bgcolor=$port_color>$port_status</TH><TH bgcolor=$ssh_color>$ssh_status</TH>" >> maildata.txt
        echo "<TR>" >> maildata.txt
   fi
}

check_ping (){
    host_name=$1
    portno=$2
    ping -q -c 3 -W 2 $host_name > /dev/null

    if [ $? -eq 0 ]
    then
        node_color="green"
        node_status="UP"
        check_ssh $host_name
        check_telnet $host_name $portno
    else
        node_color="salmon"
        node_status="DOWN"
        ssh_color="salmon"
        ssh_status="DOWN"
        telnet_color="salmon"
        telnet_status="DOWN"
        port_color="salmon"
        port_status="DOWN"
        service_color="salmon"
        service_status="DOWN"
    fi
}

check_ssh(){
  host_name=$1
  ssh -i ~/.ssh/id_rsa -o ConnectTimeout=5 root@$host_name exit
  if [ $? -eq 0 ]
  then
      ssh_color="green"
      ssh_status="UP"
  else
      ssh_color="salmon"
      ssh_status="DOWN"
  fi

}

check_telnet(){
  url=$1
  portno=$2
  nc -z $url $portno  2>/dev/null
  if [ $? -eq 0 ];
  then
      telnet_color="green"
      node_status="UP"
      service_status="UP"
      service_status="green"
      port_status="UP"
      port_color="lime"
      telnet_status="UP"
      telnet_color="lime"
  else
      telnet_color="salmon"
      port_color="salmon"
      service_status="DOWN"
      port_status="DOWN"
      telnet_status="DOWN"
  fi
}

#------------------------------------
#  Actions to be taken in case
#  the service or the host is down
#------------------------------------

service_restart(){
  echo " Restarting the service"
}

host_restart() {
  echo "Restarting the host using ilo"
}

# check_port(){
# echo " checking port"
# }

#
# Change the status
#


#--------------------------------------
# If the host is a DB host,we check if
# the port is up and listening
#---------------------------------------
getResponse(){
        groupname=$1
        nodename=$2
        url=$3
        portno=$4
        priority=$5
        if [[ $nodename =~ .*DB.* ]]
        then
             nc -z $url $portno  2>/dev/null
             if [ $? -eq 0 ];
             then
                response="200"
                service_color="green"
                service_status="UP"
                node_status="UP"
                node_color="green"
                ssh_status="UP"
                ssh_color="green"
                telnet_status="UP"
                telnet_color="green"
             else
                response="500"
                service_color="salmon"
                check_ping $host_name
                check_ssh $host_name
                check_telnet $host_name $portno
                generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color
             fi
        else
             response=$(wget --secure-protocol=TLSv1  --timeout=20 --tries=1 --no-check-certificate $url:$portno 2>&1  | grep HTTP | tail -1 | cut -f6 -d" ")
        fi
        if [ "$response" == "200" ]; then 
                service_color="green"
                service_status="UP"
                node_status="UP"
                node_color="green"
                ssh_status="UP"
                ssh_color="green"
                telnet_status="UP"
                telnet_color="green"
        elif [ "$response" == "302" ]; then
                service_color="lightBlue"
                service_status="REDIRECT"
                node_status="UP"
                node_color="green"
                ssh_status="UP"
                ssh_color="green"
                telnet_status="UP"
                telnet_color="green"
        elif [ "$response" == "403" ]; then
                service_color="lightBlue"
                service_status="FILTER?"
                node_status="UP"
                service_status="UP"
                ssh_status="UP"
                port_status="UP"
                check_ping $host_name $portno # returns node_status ping_color
                # check_ssh $host_name # returns ssh_status ssh_color
                # check_telnet $host_name $portno # returns telnet_status telnet_color
                generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color 
        elif [ "$response" == "404" ]; then
                # check_ping $url
                service_color="salmon"
                status="NOT_FOUND"
                node_status="UP"
                service_status="NOT_FOUND"
                check_ping $host_name $portno
                # check_ssh $host_name
                # check_telnet $host_name $portno
                generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color
        elif [ "$response" == "500" ]; then
                # check_ping $url 
                service_color="salmon"
                status="500"
                node_status="UP"
                service_status="UP"
                ssh_status="UP"
                telnet_status="UP"
                check_ping $host_name $portno
                # check_ssh $host_name
                # check_telnet $host_name $portno
                generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color
        elif [ "$response" == "EMPTY" ]; then 
                service_color="grey"
                node_status="N/A"
                service_status="N/A"
                ssh_status="N/A"
                telnet_status="N/A"
                check_ping $host_name $portno
                # check_ssh $host_name
                # check_telnet $host_name $portno
        else 
                service_color="salmon"
                status="DOWN"
                node_status="DOWN"
                service_status="DOWN"
                ssh_status="DOWN"
                telnet_status="DOWN"
                check_ping $host_name $portno
                # check_ssh $host_name
                # check_telnet $host_name $portno
                generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color
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
        host_name=$url
		    portno=`echo $j | cut -f4 -d';' `
        priority=`echo $j | cut -f5 -d';' `
        getResponse $groupname $nodename $url $portno $priority
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
        echo "      <th id=\"$service_color\" title=\"$url\"><a href=\"$url\" target="_top">${nodename}</a></th> " >> $i.html
       
    done
    echo "   </tr>" >> $i.html
done

#----------------------------------------
# Clean up the directory of the output
#----------------------------------------
rm index.html*  2> /dev/null
rm ping* 2> /dev/null
rm artifactory* 2> /dev/null
rm ${HC_File}_latest.html 2> /dev/null

#-------------------------------------------------
# Move the old health check reports into archive
#-------------------------------------------------
mkdir -p HISTORY
for i in `ls ${HEALTHCHECK}_* 2>/dev/null`
do
    mv $i HISTORY/ 2>/dev/null
done

# if [ -f ${HEALTHCHECK}_* ]; then
#    mv ${HEALTHCHECK}_* HISTORY/
# fi
touch ${HEALTHCHECK}_${cur_time}

#---------------------------------------
# Echo the output into the final file
#---------------------------------------
cat $PREHTML >> ${HEALTHCHECK}_${cur_time}

#----------------------------------------
# Get the output from all the group files
#----------------------------------------
for i in `cat $FILE | egrep -v '^#|^$' | cut -f1 -d';' | sort | uniq`
do
	cat ${i}.html >> ${HEALTHCHECK}_${cur_time}
done


#---------------------------------------------------------------------------
# Closing the HTML Tags and printing the time time this file was generated
# cat $POSTHTML >> ${HEALTHCHECK}_${cur_time}
#---------------------------------------------------------------------------
echo "</table>" >> ${HEALTHCHECK}_${cur_time}
echo "<br>" >> ${HEALTHCHECK}_${cur_time}
echo "<br>" >> ${HEALTHCHECK}_${cur_time}
echo "<b><p><font size="4px">Report Generated on :  ${footer_time}</font></p></b>" >> ${HEALTHCHECK}_${cur_time}
echo "</body>" >> ${HEALTHCHECK}_${cur_time}
echo "</html>" >> ${HEALTHCHECK}_${cur_time}

cat $POSTHTML >> ${HEALTHCHECK}_${cur_time}
mv  ${HEALTHCHECK}_${cur_time} ${HEALTHCHECK}_${cur_time}.html
ln -s ${HEALTHCHECK}_${cur_time}.html ${HC_File}_latest.html

#-------------------------
# Clean up of the files
#-------------------------
for i in `cat $FILE | egrep -v '^#|^$' | cut -f1 -d';' | sort | uniq`
do
        rm ${i}.html
done

checkAlertPriority
# sendEmail

sleep 600
done

echo " ----------------------------------------------------------------- " 
echo " |    Access the health check status using the below url after   | "
echo " |    Start the webserver ---> python -m SimpleHTTPServer 2223 & | "
echo " ----------------------- Access  URL ----------------------------- " 
echo " |        localhost:2223/health_chk_status_latest.html           | "
echo " ------------------------------------------------------------------ " 




