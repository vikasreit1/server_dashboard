!/bin/bash

for i in `cat test_urls.txt | egrep -v '^#|^$'  `
do
groupname=`echo $i | cut -f1 -d';' `
nodename=`echo $i | cut -f2 -d';' `
url=`echo $i | cut -f3 -d';' `
rm ${url}_inputerrors.txt  2> /dev/null
time_stamp=$(ssh -i /Users/vitikyalapati/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@${url} systemctl show -p ActiveEnterTimestamp docker.service | awk '{print $2 $3}')
ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@${url} journalctl -u docker.service -S "$time_stamp" | grep "input/output error" | wc -l > ${url}_inputerrors.txt &
done

