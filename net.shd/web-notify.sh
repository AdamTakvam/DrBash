#!/bin/bash

# Send an email if the specified text is present on the specified URL.
# Text can be any grep-compliant regular expression.

email=${1:-"nataliepeaceofmind@gmail.com cc:adam@adamtakvam.com"}
searchterm=$2
url=$3

if [ "$(grepweb $2 $3)" == "Found" ]; then
  sudo sendmail -f'adam.takvam@gmail.com' -s "I've got news about $2" $1 <<EOF
  Hello Natalie,
  
  This is Adam's automated web scaping utility. I've detected that there has been news about your friend, $2. 
  You can read about it at the following link: $3
  
  Even though I'm just a robot, please allow me to offer my sincere
  condolences on your loss.
  
  ~Web Notifer Robot
  EOF
fi
