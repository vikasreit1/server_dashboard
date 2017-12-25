#!/usr/bin/ksh

#-------------------------------------------------------------
# Setting the variables that  will be used in the script
# Script is being refactored in python - @author:vitikyalapati
# Revision: 1.0
#-------------------------------------------------------------
# Copy the logo into HISTORY directory

#----------------------------------------------
# loop continuously
# Status_values : good, bad, up, down
# Colors        : lime, salmon
#----------------------------------------------
while true
do

dirpath=`pwd`
FILE=${dirpath}/test_urls.txt
HC_File=health_chk_status
HEALTHCHECK=${dirpath}/health_chk_status
MAIL_FROM=SERVICES-STATUS@serverName.com

MAIL_TO="vitikyalapati@splunk.com"
MAIL_TO="vitikyalapati@splunk.com"
MAIL_SUB="Servers and Services status"
MAILFILE=maildata.txt

WGET=/usr/local/bin/wget
TIMEOUT=6 #Seconds
cur_time=`date +"%m%d%y-%H%M%S"`
file_time=`date +"%m%d%y"`
footer_time=`date`
error_date=`date | cut -f2,3 -d" "`
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
# total_maildata has the html
#---------------------------------------
> maildata.txt
> total_maildata.txt
#--------------------------------
# Can send a custom text alert
#--------------------------------
> alert_data.txt

#------------------
# SET Default Vars
#------------------
cpu_used="N/A"
free_memory="N/A"
memory_used="N/A"
swap_memory="N/A"
disk_used="N/A"
io_error_status="N/A"
mpt2sas_status="N/A"
cpu_status="N/A"
var_lib_status="N/A"
swap_status="N/A"
cpu_status="N/A"
load_avg_status="N/A"
input_output_status="N/A"
out_of_memory_status="N/A"

#----------------------------------
# The Default agent status is good
#----------------------------------
ucpagent_status="good"

url="N/A"
Port="N/A"
Ping="N/A"
in_rotation="N/A"
OS="N/A"
status="N/A"

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
echo " Supply a json/text file with the information "
echo " about the hosts and their properties"

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
  # Need to add this ??
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

#---------------------------------
#  Depends on the mail data
#  if maildata changes, this code
#  needs to be revisited
#---------------------------------
# cat maildata.txt | grep -v TR | cut -f 2 -d "<" | cut -f2 -d">" | sort -nr | uniq
checkAlertPriority(){
   # groupname=$1
   # nodename=$2
   # url=$3
   sed -ie '$d' maildata.txt
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
   telnet_color=${10}
   dockerps_status=${11}
   dockerps_color=${12}
   overlay_status=${13}
   overlay_color=${14}
   free_memory=${15}
   free_memory_color=${16}
   io_error_status=${17}
   io_error_color=${18}
   mpt2sas_status=${19}
   mpt2sas_color=${20}
   cpu_satus=${21}
   cpu_color=${22}
   var_lib_status=${23}
   var_lib_color=${24}
   out_of_memory_status=${25}
   out_of_memory_color=${26}
   input_output_status=${27}
   input_output_color=${28}
   load_avg_status=${29}
   load_avg_color=${30}
   swap_status=${31}
   swap_color=${32}
   controller_status="N/A"
   controller_color="white"
   # if [ "$#" -ne 12 ]; then
   #     overlay_status=${13}
   #     overlay_color=${14}
   # fi
   if [ "$#" -eq 34 ]; then
       controller_status=${33}
       controller_color=${34}
   fi
   mail_file=maildata.txt
   if [ "$priority" == "1" ]
   then
        echo "<TH bgcolor=lightyellow>$groupname</TH><TH bgcolor=lightyellow>$nodename</TH><TH bgcolor=$dockerps_color>$dockerps_status</TH><TH bgcolor=salmon>DOWN</TH><TH bgcolor=$node_color>$node_status</TH><TH bgcolor=$port_color>$port_status</TH><TH bgcolor=$ssh_color>$ssh_status</TH><TH bgcolor=$overlay_color>$overlay_status</TH><TH bgcolor=$controller_color>$controller_status</TH><TH bgcolor=$free_memory_color>$free_memory</TH><TH bgcolor=$io_error_color>$io_error_status</TH><TH bgcolor=$mpt2sas_color>$mpt2sas_status</TH><TH bgcolor=$cpu_color>$cpu_status</TH><TH bgcolor=$var_lib_color>$var_lib_status</TH><TH bgcolor=$out_of_memory_color>$out_of_memory_status</TH><TH bgcolor=$input_output_color>$input_output_status</TH><TH bgcolor=$load_avg_color>$load_avg_status</TH><TH bgcolor=$swap_color>$swap_status</TH>" >> maildata.txt
        echo "<TR>" >> maildata.txt
   fi
}

check_dockerPS(){
    host_name=$1
    group_name=$2
    # ssh -q root@$host_name docker ps -a --quiet 2>/dev/null
    #ssh -i ~/.ssh/id_rsa  root@sv3-orca-0409e2b2.sv.splunk.com docker ps
    # ssh -i ~/.ssh/id_rsa  root@sv3-orca-0409e2b2.sv.splunk.com docker info | grep -i running  | cut -f2 -d":"
    ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@$host_name docker ps -a --quiet 2>/dev/null
    if [ $? -eq 0 ]
    then
        container_count=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@$host_name docker info | grep Running | cut -f2 -d":")
        ucpagent_container_count=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@$host_name docker ps | grep ucp-agent | wc -l)
        if [ $ucpagent_container_count -lt 2 ]
        then
            ucpagent_status="bad"
        elif [ $ucpagent_container_count -eq 3  ]
        then
            ucp_reconcile_count=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@$host_name docker ps | grep ucp-rec | wc -l)
            if [ $ucp_reconcile_count -eq 1 ]
            then
                   ucpagent_status="good"
            else
                   ucpagent_status="bad"
            fi
        elif [ $ucpagent_container_count -gt 3 ]
        then
            if [[ $group_name == "UCPMasterProd" ]]
            then
               ucpagent_status="good"
            else
               ucpagent_status="bad"
            fi
        else
            ucpagent_status="good"
        fi
        dockerps_color="lime"
        dockerps_status="UP"
    else
        dockerps_color="salmon"
        dockerps_status="DOWN"
        container_count="0"
        ucpagent_container_count="0"
        ucpagent_status="bad"
    fi
}

check_ping (){
    host_name=$1
    portno=$2

    ping -q -c 3 -W 2 $host_name 2>/dev/null

    if [ $? -eq 0 ]
    then
        node_color="lime"
        node_status="UP"
        check_ssh $host_name
        check_telnet $host_name $portno
        # - Not doing a cpu,memory and disk check as it will be part of ssh check
        # If the arguments are not equal to 2, then its not a db node and we check the status of overlay port
        if [ "$#" -ne 2 ]; then
          overlayport=${3}
          check_overlay_network_port $host_name $overlayport
        fi
        # check_dockerPS $host_name
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
        io_error_color="salmon"
        io_error_status="NONE"
        mpt2sas_status="NONE"
        mpt2sas_color="salmon"
        cpu_satus="NONE"
        cpu_color="salmon"
        var_lib_status="NONE"
        var_lib_color="salmon"
        out_of_memory_status="NONE"
        out_of_memory_color="salmon"
        input_output_status="NONE"
        input_output_color="salmon"
        load_avg_status="NONE"
        load_avg_color="salmon"
        swap_status="NONE"
        swap_color="salmon"
        tooltiptext_color="tooltiptextred"
        # Overlay chek will determine this status
        # overlay_color="salmon"
        # overlay_status="DOWN"
        # Controller check will determine this
        # controller_color="salmon"
        # controller_status="DOWN"
        # Docker ps check will determine this
        # dockerps_status="DOWN"
        # dockerps_color="salmon"
    fi
}

check_ssh(){
    host_name=$1
    ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name exit
    if [ $? -eq 0 ]
    then
        ssh_color="lime"
        ssh_status="UP"
        check_memory $host_name
        check_swap $host_name
        check_cpu $host_name
        check_load_average $host_name
        check_input_output_errors $host_name
        check_outof_memory $host_name
        check_mpt2sas $host_name
        check_var_lib $host_name
        check_io_errors $host_name
        # check_kernel_issue $host_name
    else
        ssh_color="salmon"
        ssh_status="DOWN"
        free_memory="N\A"
        free_memory_color="salmon"
        io_error_status="N/A"
        io_error_color="salmon"
    fi
}

check_memory(){
    host_name=$1
    free_memory=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name free -m | grep Mem | awk '{print ($2-$3)/1024}')
    #freeMem_percentage
    memory_used_percent=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name  free -m | awk 'NR==2{printf "%.2f%%\t\t", $3*100/$2 }')
    memory_used=$(echo $free_memory| cut -f1 -d"." )
    # Condition to alert based on the memory usage
    if [ "$memory_used" -le 4 ]
    then
        free_memory_color="salmon"
        free_memory_status="bad"
    else
        free_memory_color="lime"
        free_memory_status="good"
    fi
}

#-----------------------------------------------------------------------------------------------------
# eval $(ls -la | awk '{usr = $3 " " usr;fil = $9 " " fil} END{print "usr=\""usr"\";fil=\""fil"\""}')
# eval $(ssh  -q root@sv3-orca-0308e1b1 "free " | grep Swap | awk '{swap_total = $2 " " swap_total; swap_used= $3 " " swap_used } END{print "used=\""swap_used"; tot=\""swap_total"\""}')
# -----------------------------------------------------------------------------------------------------
# eval $(ssh  -q root@sv3-orca-0308e1b1 "free " | grep Swap | awk '{swap_total = $2 " " swap_total; swap_used= $3 " " swap_used } END{print "used='swap_used'; tot='swap_total' "}')
#------------------------------------------------------------------------------------------------------
check_swap(){
    host_name=$1
    swap_used=$(ssh -q root@s$host_name "free " | grep Swap | awk '{print $3}') 
    swap_used_percent=$(ssh -q root@$host_name "free " | grep Swap | awk '{print $3/$2*100}')
    swap_used_percent_int=${swap_used_percent%.*}
    if [ "$swap_used_percent_int" -gt 70 ]
    then
        ucpagent_status="bad"
        swap_color="salmon"
        swap_status="bad"
    else
        swap_color="lime"
        swap_status="good"
    fi
}

# MEMORY=$(free -m | awk 'NR==2{printf "%.2f%%\t\t", $3*100/$2 }')
# DISK=$(df -h | awk '$NF=="/"{printf "%s\t\t", $5}')
# CPU=$(top -bn1 | grep load | awk '{printf "%.2f%%\t\t\n", $(NF-2)}')
# CPU_usage=sar -P ALL 1 2 |grep 'Average.*all' |awk -F" " '{print 100.0 -$NF}'
# check_cpu(){
#     host_name=$1
#     cpu_used_percent=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name top -bn1 | grep load | awk '{printf "%.2f%%\t\t\n", $(NF-2)}')
#     cpu_used=$( echo $cpu_used | cut -f1 -d"." )
#     # Condition to alert based on the cpu usage
#     if [ "$int_cpu" -gt 45 ]
#     then
#         ucpagent_status="bad"
#         cpu_status="bad"
#         cpu_color="salmon"
#     else
#         cpu_color="lime"
#         cpu_status="good"
#     fi
# }

check_cpu(){
    host_name=$1
    cpu_used_percent=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name sar -P ALL 1 2 |grep 'Average.*all' |awk -F" " '{print 100.0 -$NF}')
    cpu_used_int=$( echo $cpu_used_percent | cut -f1 -d"." )
    # Condition to alert based on the cpu usage
    if [ "$cpu_used_int" -gt 45 ]
    then
        ucpagent_status="bad"
        cpu_status="bad"
        cpu_color="salmon"
    else
        cpu_color="lime"
        cpu_status="good"
    fi
}

check_load_average(){
    host_name=$1
    load_avg=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@sv3-orca-0308e1b1 'uptime | grep load' | awk '{print $(NF-2)}')
    load_avg_int=${load_avg%.*}
    if [ "$load_avg_int" -gt 21 ]
    then
        cpu_used=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name sar -P ALL 1 2 |grep 'Average.*all' |awk -F" " '{print 100.0 -$NF}' | cut -f -d".")
        if [ "$cpu_used" -gt 25 ]
        then
            ucpagent_status="bad"
            cpu_status="bad"
            cpu_color="salmon"
            ucpagent_status="bad"
            load_avg_status="bad"
            load_avg_color="salmon"
        else
            ucpagent_status="bad"
            kernel_status="bad"
            reboot_required="TRUE"
        fi
    else
        load_avg_color="lime"
        load_avg_status="good"
    fi
}

check_input_output_errors(){
    host_name=$1
    input_output_error_cnt=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name 'grep "input/output error" /var/log/messages | grep -v grep | grep $error_date'  | wc -l )
    # Condition to alert based on the count
    if [ "$input_output_error_cnt" -gt 500 ]
    then
        ucpagent_status="bad"
        input_output_status="bad"
        input_output_color="salmon"
    else
        input_output_color="lime"
        input_output_status="good"
    fi
}

check_outof_memory(){
    host_name=$1
    out_memory_cnt=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name 'grep "Out of memory:" /var/log/messages | grep -v grep | grep $error_date' | wc -l )
    # Condition to alert based on the cpu usage
    if [ "$out_memory_cnt" -gt 45 ]
    then
        ucpagent_status="bad"
        out_of_memory_status="bad"
        out_of_memory_color="salmon"
    else
        out_of_memory_color="lime"
        out_of_memory_status="good"
    fi
}

check_mpt2sas(){
    host_name=$1
    mpt2sas_errors=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name dmesg | grep 'mpt2sas_cm0: log_info(0x32010081)' | wc -l)
    if [ $? -eq 0 ] || [ $mpt2sas_errors -eq 0 ]
    then
        mpt2sas_error_status="good"
        mpt2sas_error_color="lime"
    else
        ucpagent_status="bad"
        mpt2sas_error_status="bad"
        mpt2sas_error_color="salmon"
    fi
}

check_io_errors(){
    host_name=$1
    io_error_count=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name journalctl -u docker.service -S "$(/usr/bin/systemctl show -p ActiveEnterTimestamp docker.service | awk '{print $2 $3}')" | grep "input/output error" | wc -l)
    if [ $io_error_count -gt 0 ]
    then
        ucpagent_status="bad"
        io_error_status="bad"
        io_error_color="salmon"
    else
        io_error_status="0"
        io_error_color="lime"
    fi
}

check_var_lib(){
    host_name=$1
    disk_used_percent=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name df -h | awk '$NF=="/var/lib/docker"{printf "%s\t\t", $5}')
    disk_used=$( echo $disk_used_percent | cut -f1 -d"%" )
    if [ "$disk_used" -gt 30 ]
    then
        ucpagent_status="bad"
        var_lib_color="salmon"
        var_lib_status="bad"
    else
        var_lib_color="lime"
        var_lib_status="good"
    fi
}

check_telnet(){
  url=$1
  portno=$2
  nc  -w 10 -z $url $portno  2>/dev/null
  if [ $? -eq 0 ];
  then
      telnet_color="lime"
      telnet_status="UP"
      node_status="UP"
      service_status="UP"
      service_color="green"
      port_status="UP"
      port_color="lime"
      tooltiptext_color="tooltiptextgreen"
  else
      telnet_status="DOWN"
      telnet_color="salmon"
      port_status="DOWN"
      port_color="salmon"
      service_color="salmon"
      service_status="DOWN"
      tooltiptext_color="tooltiptextred"
  fi
}

check_controller_https_ping(){
    httpsurl=$1
    sleep 1
    try1=$(wget --timeout=1 --tries=1 --no-check-certificate ${httpsurl}  2>&1  | grep HTTP | awk '{print $6}')
    sleep 1
    try2=$(wget --timeout=1 --tries=1 --no-check-certificate ${httpsurl}  2>&1  | grep HTTP | awk '{print $6}')
    sleep 1
    try3=$(wget --timeout=1 --tries=1 --no-check-certificate ${httpsurl}  2>&1  | grep HTTP | awk '{print $6}')
    if [ "$try1" == "200" ] ||  [ "$try2" == "200" ] ||  [ "$try3" == "200" ]
    then
        controller_status="UP"
        controller_color="lime"
    else
        controller_status="DOWN"
        controller_color="salmon"
    fi
}

check_overlay_network_port(){
  url=$1
  overlayportno=$2
  if [[ $url != *"sv3-orca-ucp-00"* ]]; then
      nc -z -w 10 $url $overlayportno  2>/dev/null
      if [ $? -eq 0 ];
      then
          overlay_color="lime"
          overlay_status="UP"
      else
          overlay_status="DOWN"
          overlay_color="salmon"
      fi
  else
      overlay_color="white"
      overlay_status="N/A"
  fi
}

check_system_io(){

   avg_service_time=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name iostat -xn 5)
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
generate_html(){
  service_color=$1
  url=$2
  nodename=$3
  shortname=$4
  container_count=$5
  tooltiptext_color=$6
  ucpagent_status=$7
  ucpagent_container_count=$8
  io_error_status=$9
  io_error_color=$10
  mpt2sas_status=$11
  mpt2sas_color=$12
  cpu_satus=$13
  cpu_color=$14
  var_lib_status=$15
  var_lib_color=$16
  out_of_memory_status=$17
  out_of_memory_color=$18
  input_output_status=$19
  input_output_color=$20
  load_avg_status=$21
  load_avg_color=$22
  swap_status=$23
  swap_color=$24
  if [[ $url == "ucp.splunk.com" ]]
  then
      echo "  <th id=\"$service_color\"> <a class=\"tooltip\" href=\"$url\">${nodename}<span class=\"$tooltiptext_color\">CPU: \"$cpu_used\" <br>Memory: \" $memory_used_percent \"<br>Disk used: \" $disk_used\"</span> </a></th> "  >> $i.html
  else
     if [[ $ucpagent_status == "bad" ]] || [[ $io_error_status == "bad" ]]
     then
         echo " <th id=\"$service_color\"> <a class=\"tooltip\" href=\"$url\">${shortname}-( ${container_count} )-<span id="yellowred"> ${ucpagent_container_count}</span><span class=\"$tooltiptext_color\">CPU: \"$cpu_used\"  <br>Memory: \" $memory_used_percent \" <br>Disk used: \" $disk_used\"<br>Port: \"$Port\" <br> Ping: \"$Ping\" <br> In Rotation: \"$in_rotation\" <br> OS: \"$OS\" <br>Status: \"$status\" <br> URL: \"$url\" </span> </a></th> " >> $i.html
     else
         echo " <th id=\"$service_color\"> <a class=\"tooltip\" href=\"$url\">${shortname}-( ${container_count} )<span class=\"$tooltiptext_color\">CPU: \"$cpu_used\"  <br>Memory: \" $memory_used_percent \" <br>Disk used: \" $disk_used\" <br>Port: \"$Port\" <br> Ping: \"$Ping\" <br> In Rotation: \"$in_rotation\" <br> OS: \"$OS\" <br>Status: \"$status\" <br> URL: \"$url\" </span> </a></th> " >> $i.html
     fi
  fi
}

# Sample Hover example
#<div class="tooltip">Hover over me
#  <span class="tooltiptext">Diskspace: 12332<br> cpu: test 2<br>memory: test3<br></span>
#</div>

#  <th id="green"> <a class="tooltip" href="#">Master01-( 0 )<span class="tooltiptext">TEST1<br>Test2<br>Test3</span> </a></th>
#  <th id="green" title="sv3-orca-ucp-002.sv.splunk.com"><a href="sv3-orca-ucp-002.sv.splunk.com" target=_top>Master02-( 11 )</a></th>

#--------------------------------------
# If the host is a DB host,we check if
# the port is up and listening
#---------------------------------------
getResponse(){
        groupname=$1
        nodename=$2
        url=$3
        host_name=$url
        portno=$4
        overlayport=$5
        priority=$6
        shortname=$7
        firstrow=$8
        count=$9
        if [[ $url == "ucp.splunk.com" ]]
        then
              url="https://ucp.splunk.com"
        fi

        if [[ $nodename =~ .*DB.* ]]
        then
             nc -z -w 10 $url $portno  2>/dev/null
             if [ $? -eq 0 ];
             then
                response="200"
                service_color="green"
                service_status="UP"
                node_status="UP"
                node_color="lime"
                ssh_status="UP"
                ssh_color="lime"
                telnet_status="UP"
                telnet_color="lime"
                tooltiptext_color="tooltiptextgreen"
             else
                response="500"
                service_color="salmon"
                tooltiptext_color="tooltiptextred"
                check_ping $host_name $portno
                check_ssh $host_name
                check_telnet $host_name $portno
                generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color $dockerps_status $dockerps_color $overlay_status $overlay_color $free_memory $free_memory_color $io_error_status $io_error_color $mpt2sas_status $mpt2sas_color $cpu_satus $cpu_color $var_lib_status $var_lib_color $out_of_memory_status $out_of_memory_color $input_output_status $input_output_color $load_avg_status $load_avg_color $swap_status $swap_color
             fi
        elif [[ $nodename =~ .*orca-ucp-00.* ]] ||  [[ $groupname == "UCPMasterProd" ]]
        then
             httpsurl="https://${url}/_ping"
             check_controller_https_ping $httpsurl
             check_dockerPS $host_name $groupname
             check_ping $host_name $portno $overlayport
             response=$(wget --secure-protocol=TLSv1  --timeout=20 --tries=1 --no-check-certificate $url:$portno 2>&1  | grep HTTP | tail -1 | cut -f6 -d" ")
             if [ "$response" != "200" ] || [[ "service_status" == "DOWN" ]] || [[ "node_status" == "DOWN" ]] || [[ "ssh_status" == "DOWN" ]] || [[ "telnet_status" == "DOWN" ]] || [[ "controller_status" == "DOWN" ]] || [[ "io_error_status" == "bad" ]] || [[ "mpt2sas_status" == "bad" ]] || [[ "cpu_status" == "bad" ]] || [[ "var_lib_status" == "bad" ]]
             then
                 generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color $dockerps_status $dockerps_color $overlay_status $overlay_color  $free_memory $free_memory_color $io_error_status $io_error_color $mpt2sas_status $mpt2sas_color $cpu_satus $cpu_color $var_lib_status $var_lib_color $out_of_memory_status $out_of_memory_color $input_output_status $input_output_color $load_avg_status $load_avg_color $swap_status $swap_color $controller_status $controller_color 
             fi
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
                 generate_html $service_color $url $nodename $shortname $container_count $tooltiptext_color $ucpagent_status $ucpagent_container_count $io_error_status $io_error_color $mpt2sas_status $mpt2sas_color $cpu_satus $cpu_color $var_lib_status $var_lib_colo $out_of_memory_status $out_of_memory_color $input_output_status $input_output_color $load_avg_status $load_avg_color $swap_status $swap_color
             continue
        else
             check_dockerPS $host_name $groupname
             if [[ $dockerps_status == "DOWN" ]]; then
                 check_ping $host_name $portno $overlayport
                 response=$(wget --secure-protocol=TLSv1  --timeout=20 --tries=1 --no-check-certificate $url:$portno 2>&1  | grep HTTP | tail -1 | cut -f6 -d" ")
                 generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color $dockerps_status $dockerps_color $overlay_status $overlay_color $free_memory $free_memory_color $io_error_status $io_error_color $mpt2sas_status $mpt2sas_color $cpu_satus $cpu_color $var_lib_status $var_lib_color $out_of_memory_status $out_of_memory_color $input_output_status $input_output_color $load_avg_status $load_avg_color $swap_status $swap_color
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
                 generate_html $service_color $url $nodename $shortname $container_count $tooltiptext_color $ucpagent_status $ucpagent_container_count $io_error_status $io_error_color $mpt2sas_status $mpt2sas_color $cpu_satus $cpu_color $var_lib_status $var_lib_colo $out_of_memory_status $out_of_memory_color $input_output_status $input_output_color $load_avg_status $load_avg_color $swap_status $swap_color
                 continue
             else
                 response=$(wget --secure-protocol=TLSv1  --timeout=20 --tries=1 --no-check-certificate $url:$portno 2>&1  | grep HTTP | tail -1 | cut -f6 -d" ")
             fi
             # generate_html $service_color $url $nodename $container_count
             #
        fi
        if [ "$response" == "200" ]; then
                service_color="green"
                service_status="UP"
                node_status="UP"
                node_color="lime"
                # check_ping $host_name $portno
                # if [ "$dockerps_status" == "DOWN" ] | [ "$ssh_status" = "DOWN" ] |  [ "$telnet_status" = "DOWN" ]
                # then
                # generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color $dockerps_status $dockerps_color
                # fi
                ssh_status="UP"
                ssh_color="lime"
                telnet_status="UP"
                telnet_color="lime"
                port_status="UP"
                port_color="lime"
                tooltiptext_color="tooltiptextgreen"
        elif [ "$response" == "302" ]; then
                service_color="lightBlue"
                service_status="REDIRECT"
                node_status="UP"
                node_color="lime"
                check_ping $host_name $portno $overlayport
                ssh_status="UP"
                ssh_color="lime"
                telnet_status="UP"
                telnet_color="lime"
                tooltiptext_color="tooltiptextgreen"
        elif [ "$response" == "403" ]; then
                service_color="lightBlue"
                service_status="FILTER?"
                # node_status="UP"
                # node_color="lime"
                # ssh_status="UP"
                # ssh_color="lime"
                # port_status="UP"
                # port_color="lime"
                # telnet_status="UP"
                # telnet_color="lime"
                check_ping $host_name $portno $overlayport # returns node_status ping_color
                # check_ssh $host_name # returns ssh_status ssh_color
                # check_telnet $host_name $portno # returns telnet_status telnet_color
                generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color $dockerps_status $dockerps_color $overlay_status $overlay_color $free_memory $free_memory_color $io_error_status $io_error_color $mpt2sas_status $mpt2sas_color $cpu_satus $cpu_color $var_lib_status $var_lib_color $out_of_memory_status $out_of_memory_color $input_output_status $input_output_color $load_avg_status $load_avg_color $swap_status $swap_color
        elif [ "$response" == "404" ]; then
                # check_ping $url
                service_color="salmon"
                status="NOT_FOUND"
                node_status="UP"
                service_status="NOT_FOUND"
                tooltiptext_color="tooltiptextred"
                check_ping $host_name $portno $overlayport
                # check_ssh $host_name
                # check_telnet $host_name $portno
                generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color $dockerps_status $dockerps_color $overlay_status $overlay_color $free_memory $free_memory_color $io_error_status $io_error_color $mpt2sas_status $mpt2sas_color $cpu_satus $cpu_color $var_lib_status $var_lib_color $out_of_memory_status $out_of_memory_color $input_output_status $input_output_color $load_avg_status $load_avg_color $swap_status $swap_color
        elif [ "$response" == "500" ]; then
                # check_ping $url
                service_color="salmon"
                status="500"
                node_status="UP"
                service_status="DOWN"
                tooltiptext_color="tooltiptextred"
                # ssh_status="UP"
                # telnet_status="UP"
                check_ping $host_name $portno $overlayport
                # check_ssh $host_name
                # check_telnet $host_name $portno
                generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color $dockerps_status $dockerps_color $overlay_status $overlay_color $free_memory $free_memory_color $io_error_status $io_error_color $mpt2sas_status $mpt2sas_color $cpu_satus $cpu_color $var_lib_status $var_lib_color $out_of_memory_status $out_of_memory_color $input_output_status $input_output_color $load_avg_status $load_avg_color $swap_status $swap_color
        elif [ "$response" == "EMPTY" ]; then
                service_color="grey"
                node_status="N/A"
                service_status="N/A"
                ssh_status="N/A"
                telnet_status="N/A"
                tooltiptext_color="tooltiptextred"
                check_ping $host_name $portno $overlayport
                # check_ssh $host_name
                # check_telnet $host_name $portno
        else
                service_color="salmon"
                status="DOWN"
                node_status="DOWN"
                service_status="DOWN"
                ssh_status="DOWN"
                telnet_status="DOWN"
                tooltiptext_color="tooltiptextred"
                check_ping $host_name $portno $overlayport
                # check_ssh $host_name
                # check_telnet $host_name $portno
                generateMaildata $groupname $nodename $url $priority $node_status $node_color $ssh_status $ssh_color $telnet_status $telnet_color $dockerps_status $dockerps_color $overlay_status $overlay_color $free_memory $free_memory_color $io_error_status $io_error_color $mpt2sas_status $mpt2sas_color $cpu_satus $cpu_color $var_lib_status $var_lib_color $out_of_memory_status $out_of_memory_color $input_output_status $input_output_color $load_avg_status $load_avg_color $swap_status $swap_color
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
        overlayport=`echo $j | cut -f5 -d';' `
        priority=`echo $j | cut -f6 -d';' `
        if  [[ $groupname == "UCPMasterProd" ]]
        then
             shortname=`echo $nodename | cut -f2 -d'-' `
        else
             shortname=`echo $nodename | cut -f3 -d'-' `
        fi
        count=$(( $count + 1 ))
        firstrow=$(( $firstrow + 1 ))
        getResponse $groupname $nodename $url $portno $overlayport $priority $shortname $firstrow $count
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
        generate_html $service_color $url $nodename $shortname $container_count $tooltiptext_color $ucpagent_status $ucpagent_container_count $io_error_status $io_error_color $mpt2sas_status $mpt2sas_color $cpu_satus $cpu_color $var_lib_status $var_lib_colo $out_of_memory_status $out_of_memory_color $input_output_status $input_output_color $load_avg_status $load_avg_color $swap_status $swap_color
        # echo "      <th id=\"$service_color\" title=\"$url\"><a href=\"$url\" target="_top">${shortname}-${container_count}</a></th> " >> $i.html

    done
    echo "   </tr>" >> $i.html
done

#----------------------------------------
# Clean up the directory of the output
#----------------------------------------
rm index.html*  2> /dev/null
rm ping* 2> /dev/null
rm _ping* 2> /dev/null
rm artifactory* 2> /dev/null
rm ${HC_File}_latest.html 2> /dev/null

#-------------------------------------------------
# Move the old health check reports into archive
#-------------------------------------------------
mkdir -p HISTORY/${file_time}
cp Infra_engg.png HISTORY/${file_time}

for i in `ls ${HEALTHCHECK}_* 2>/dev/null`
do
    mv $i HISTORY/${file_time}/ 2>/dev/null
done

# if [ -f ${HEALTHCHECK}_* ]; then
#    mv ${HEALTHCHECK}_* HISTORY/
# fi
#---------------------------------------------------
# Creating the Html File for the dashboard
#---------------------------------------------------
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


#----------------------------------------------------------------------
# Closing the HTML Tags and printing the time this file was generated
# cat $POSTHTML >> ${HEALTHCHECK}_${cur_time}
#----------------------------------------------------------------------
echo "</table>" >> ${HEALTHCHECK}_${cur_time}
echo "<br>" >> ${HEALTHCHECK}_${cur_time}
echo "<br>" >> ${HEALTHCHECK}_${cur_time}
echo "<b><p><font size="4px">Report Generated on :  ${footer_time}</font></p></b>" >> ${HEALTHCHECK}_${cur_time}
echo "</body>" >> ${HEALTHCHECK}_${cur_time}
echo "</html>" >> ${HEALTHCHECK}_${cur_time}

# cat $POSTHTML >> ${HEALTHCHECK}_${cur_time}
mv  ${HEALTHCHECK}_${cur_time} ${HEALTHCHECK}_${cur_time}.html
ln -s ${HEALTHCHECK}_${cur_time}.html ${HC_File}_latest.html

#-------------------------
# Clean up of the files
#-------------------------
for i in `cat $FILE | egrep -v '^#|^$' | cut -f1 -d';' | sort | uniq`
do
        rm ${i}.html
done

echo " =================   End of HC    ==================== "
checkAlertPriority
# sendEmail

sleep 400
done

echo " ----------------------------------------------------------------- "
echo " |    Access the health check status using the below url after   | "
echo " |    Start the webserver ---> python -m SimpleHTTPServer 2223 & | "
echo " ----------------------- Access  URL ----------------------------- "
echo " |        localhost:2223/health_chk_status_latest.html           | "
echo " ------------------------------------------------------------------ "


