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