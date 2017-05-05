#!/bin/bash

#####
# OSX Machine auth for 802.1x profile with Active Directory
# get AD machine user/pass and put into 802.1x profile template
# install the profile
#
# sed has it's own uses for '&' and '\' in replacements
# and the randomly generated password sometimes has them
# So, trap and escape them before feeding into sed
#
# put the host name in 'host/computername.domain.com' format
##
# Originally by DP ~2012
# added traps and host name modification
# thp 7/16/14
#####
DOMAIN="mydomain.com"
FOREST="MYFOREST"
PASS=`sudo /usr/bin/security find-generic-password -s "/Active Directory/${FOREST}" -w /Library/Keychains/System.keychain`
USER=`/usr/sbin/dsconfigad -show | awk '/Computer *Account/ { print $4 }'`

# trap '\' and escape them
if [[ ${PASS} =~ '\' ]]; then
PASS=$(echo "$PASS" | sed 's/\\/\\\\/g') 
fi

# trap '&' and escape them
if [[ ${PASS} =~ '&' ]]; then
PASS=$(echo "$PASS" | sed 's/&/\\&/g') 
fi

# format username as hostname
USER=`echo $USER | tr -d '$'`
USER="host\/${USER}.${DOMAIN}"

# change template file
PROPATH='/path/to/profile/directory'
PROFILE='PROFILENAME.mobileconfig'

sed -i .bak 's/TESTPASS/'${PASS}'/' ${PROPATH}/${PROFILE}
sed -i .bak 's/TESTUSER/'${USER}'/' ${PROPATH}/${PROFILE}

/usr/bin/profiles -I -F ${PROPATH}/${PROFILE}
RESULT=`echo $?`

rm -f ${PROPATH}/${PROFILE}.bak

# If profile successfully installed, delete it
if [ "$RESULT" = 0 ]; then
  rm -rf ${PROPATH}/${PROFILE}
fi

exit
