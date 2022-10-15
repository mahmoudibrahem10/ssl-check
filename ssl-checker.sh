#!/bin/bash  
#reading the file which contains the domains to make ssl expiry check  
file='file.txt'  
  
i=1  
while read line; do 
#skipping lines that starts with # 
[[ $line = \#* ]] && continue  
#Reading each line  
i=$((i+1))
# customizing slack channel and your visualization preferences
notify() {
#your channel webhook here 
  WEBHOOK=""
#your channel name 
  SLACK_CHANNEL="#test-channel-for-devops"
#adding a botname 
  SLACK_BOTNAME="SSL Checker"
#reading  line by line  from the file in a variable called domain  and customizing the color 
  DOMAIN="$line"
  EXPIRY_DAYS="$2"
  EXPIRY_DATE="$3"
  ISSUER="$4"
  COLOR="$5"
#setting the payload configuration to start communicating with slack 
  SLACK_PAYLOAD="payload={\"channel\":\"${SLACK_CHANNEL}\",\"icon_emoji\":\":skull:\",\"username\":\"${SLACK_BOTNAME}\",\"attachments\":[{\"color\":\"${COLOR}\",\"fields\":[{\"title\":\"Domain:\",\"value\":\"${DOMAIN}\",\"short\":true},{\"title\":\"Expiry day(s):\",\"value\":\"${EXPIRY_DAYS}\",\"short\":true},{\"title\":\"Expiry date:\",\"value\":\"$EXPIRY_DATE\",\"short\":true},{\"title\":\"Issued by:\",\"value\":\"$ISSUER\",\"short\":true}]}]}"
  curl -X POST --data-urlencode "$SLACK_PAYLOAD" $WEBHOOK
}
#making a function to take each domain and check it`d expiration date

check_certs() {
#checking if the file is exmpty and if it is empty the output will be Domain name missing
  if [ -z "$line" ]
  then
    echo "Domain name missing"
    exit 1
  fi
  name="$line"
  shift
#getting the ip of every domain
  now_epoch=$( date +%s )
  ip_server=$(dig +short a $name)
  dig +noall +answer +short $name | while read -r ip;
  do
#comparing to check if the  domain ip = server ip 
    if [ "$ip" == "$ip_server" ]
    then
#starting our process to check the not after option that the ssl will expire after that date
      data=`echo | openssl s_client -showcerts -servername $name -connect $ip:443 2>/dev/null | openssl x509 -noout -enddate -issuer`
#getting the expiray date using cut on the not after - then we will have a the expiration date
      expiry_date=$(echo $data | grep -Eo "notAfter=(.*)GMT" | cut -d "=" -f 2)
      issuer=$(echo $data | grep -Eo "CN=(.*)"| cut -d "=" -f 2)
      expiry_epoch=$(date -d "$expiry_date" +%s)
#getting how many days that will the ssl expire in using the expiration data
      expiry_days="$(( ($expiry_epoch - $now_epoch) / (3600 * 24) ))"
# if expiration date is before 100 day - make the slack notification in red color 
      if [ $expiry_days -lt 100 ]
      then
          color="#ff0000"
          notify "$name" "$expiry_days" "$expiry_date" "$issuer" "$color"
# if expiration date is before 100 day - make the slack notification in green color 

      else
          color="#2eb886"
          notify "$name" "$expiry_days" "$expiry_date" "$issuer" "$color"
      fi
    fi
  done
}
#call the function
check_certs $line
  
done < $file
