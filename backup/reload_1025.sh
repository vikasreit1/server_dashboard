#!/usr/bin/bash


#----------------------------------
Stop the processes
#----------------------------------
ps -ef | grep -i 102 |grep -v grep | awk '{print $2}' | xargs kill -9


#--------------------------------------------
COPY the latest health_check_Script
#--------------------------------------------
for i in `cat urls.txt | egrep -v '^#|^$' | cut -f7 -d ";" | sort | uniq`
do
cp /home/vitikyalapati/ucp_check_load1025/health_check1025.sh  /home/vitikyalapati/ragnarok/${i}/health_check1025_${i}.sh
done


#-----------------------------------------------
#  Start the tests
#-----------------------------------------------
for i in `cat urls.txt | egrep -v '^#|^$' | cut -f7 -d ";" | sort | uniq`
do
cd /home/vitikyalapati/ragnarok/${i}/
nohup sh health_check1025_${i}.sh &
done

#------------------------------------------------
#Copy the Active URLS
#------------------------------------------------
for i in `cat urls.txt | egrep -v '^#|^$' | cut -f7 -d ";" | sort | uniq`
do 
cat /home/vitikyalapati/ucp_check_load1025/urls.txt| grep ${i} > /home/vitikyalapati/ragnarok/${i}/urls.txt
done

