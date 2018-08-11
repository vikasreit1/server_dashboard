#!/bin/bash


#----------------------------
# Calculate the load average
#----------------------------

load_avg=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@sv3-orca-0308e1b1 'uptime | grep load' | awk '{print $(NF-2)}')
load_avg_int=${load_avg%.*}
    if [ "$load_avg_int" -gt 21 ]
    then
        load_avg_status="bad"
        load_avg_color="salmon"
    else
        load_avg_color="lime"
        load_avg_status="good"
    fi



echo "$load_avg_status"
echo  "$load_avg_color"
echo "$load_avg_int"


check_load_average(){
    host_name=$1
    load_avg=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@$host_name 'uptime | grep load' | awk '{print $(NF-2)}'  | cut -f1 -d"." )
##    load_avg_int=${load_avg%.*}
    if [ "$load_avg" -gt 21 ]
    then
        cpu_used=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@$host_name sar -P ALL 1 2 |grep 'Average.*all' |awk -F" " '{print 100.0 -$NF}' | cut -f1 -d".")
        if [ "$cpu_used" -gt 26 ]
        then
            ucpagent_status="bad"
            cpu_status="${cpu_used}%"
            cpu_color="salmon"
            ucpagent_status="bad"
            load_avg_status="${load_avg}"
            load_avg_color="salmon"
        else
            # If the cpu used is not greater than 26, then there is a problem
            ucpagent_status="bad"
            kernel_status="bad"
            reboot_required="TRUE"
            ucpagent_status="bad"
            cpu_status="${cpu_used}%"
            cpu_color="salmon"
            ucpagent_status="bad"
            load_avg_status="${load_avg}"
            load_avg_color="salmon"
        fi
    else
        load_avg_color="lime"
        load_avg_status="good"
    fi
}

check_load_average sv3-orca-0308e1b1
echo "${load_avg_color}"
echo "${load_avg_status}"
check_load_average sv3-orca-0308e1b2
echo "${load_avg_color}"
echo "${load_avg_status}"
