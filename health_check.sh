#!/usr/bin/ksh

#-------------------------------------------------------------
# Setting the variables that  will be used in the script
# Script is being refactored in python - @author:vitikyalapati
# Revision: 1.0
#-------------------------------------------------------------
dirpath=`pwd`
FILE=${dirpath}/urls.txt
HEALTHCHECK=${dirpath}/temp.html
MAIL_FROM=SERVICES-STATUS@serverName.com
MAIL_TO=vitikyalapati@splunk.com
MAIL_SUB="Servers and Services status"
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


getResponse(){
        groupname=$1
        nodename=$2
        url=$3
        portno=$4
        response=$(wget --secure-protocol=TLSv1  --timeout=20 --tries=1 --no-check-certificate $url 2>&1  | grep HTTP | tail -1 | cut -f6 -d" ")
        if [ "$response" == "200" ]; then 
                color="green"
                status="UP"
        elif [ "$response" == "302" ]; then 
                color="lightBlue"
                status="REDIRECT"
        elif [ "$response" == "403" ]; then
                color="lightBlue"
                status="FILTER?"
        elif [ "$response" == "404" ]; then 
                color="salmon"
                status="NOT_FOUND"
        elif [ "$response" == "500" ]; then 
                color="salmon"
                status="500"
        elif [ "$response" == "EMPTY" ]; then 
                color="grey"
                status=""
        else 
                color="salmon"
                status="DOWN"
        fi

}
#-----------------------------------------
# Empty the files
#-----------------------------------------

> $TEMP_FILE
> $HTML_FILE

#----------------------------------------------------------------------------------------------------
#     We first set the title in the html snippet and then do a loop on the respective group urls
#     Here File is the urls file
#     The case of 301 redirect is also handled, in case we have a redirect on the url
#     and capture only the final HTTP response
#----------------------------------------------------------------------------------------------------
for i in `cat $FILE | egrep -v '^#|^$' | cut -f1 -d';' | sort | uniq`
do
	rm ${i}.html
	touch ${i}.html
	echo "   <tr> " > $i.html
	echo "      <th id=\"grey\" title=\"$i\">$i</th> " >> $i.html
	for j in `cat $FILE | egrep -v '^#|^$' | grep $i `
	do
		groupname=`echo $j | cut -f1 -d';' `
		nodename=`echo $j | cut -f2 -d';' `
		url=`echo $j | cut -f3 -d';' `
		portno=`echo $j | cut -f4 -d';' `
        getResponse $groupname $nodename $url $portno

        echo "      <th id=\"$color\" title=\"$url\">${status}${LIMIT}${nodename}</th> " >> $i.html

    done
    echo "   </tr>" >> $i.html
done

rm index.html*
rm ${HEALTHCHECK}_*
rm ${HEALTHCHECK}_${time}
touch ${HEALTHCHECK}_${time}

#---------------------------------------
# Echo the output into the final file
#---------------------------------------
cat $PREHTML >> ${HEALTHCHECK}_${time}

for i in `cat $FILE | egrep -v '^#|^$' | cut -f1 -d';' | sort | uniq`
do
	cat ${i}.html >> ${HEALTHCHECK}_${time}
done

cat $POSTHTML >> ${HEALTHCHECK}_${time}
mv  ${HEALTHCHECK}_${time} ${HEALTHCHECK}_${time}.html












