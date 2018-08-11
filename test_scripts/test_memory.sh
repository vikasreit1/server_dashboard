#!/usr/bin/ksh


check_memory(){
    host_name=$1
    freeMem_status=$(ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host_name free -m | grep Mem | awk '{print ($2-$3)/1024}')
    int_memory=$(echo $freeMem_status| cut -f1 -d"." )
    echo $int_memory
    if [ "$int_memory" -le 4 ]
    then
        freeMem_color="salmon"
    else
        freeMem_color="lime"
    fi
}




check_memory sv3-orca-ucp-004.sv.splunk.com
#check_memory sv3-orca-0313e1b3.sv.splunk.com
check_memory sv3-orca-0308e5b4.sv.splunk.com

echo "$freeMem_color"
