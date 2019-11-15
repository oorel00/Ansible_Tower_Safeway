#!/bin/bash
#
# Resets a user password on a target server by setting it to a random 12 character string,
# setting the password aging to 0 and send the new password to the user via email.
#
# Argument required : {userid}
# original Author: shans05
# modified by....: oorel00
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin
USERARG=$1

HOSTNAME=`uname -n`
fqdn=`nslookup $HOSTNAME | grep Name: | awk '{print $2}'`
ipaddr=`nslookup $HOSTNAME | grep Address: | awk '{print $2}'`
sn=`basename "$0"`

echo "executing Script $sn on: $fqdn - $ipaddr to reset pwd for user: $USERARG"

if [[ $(id -u) -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# Functions
reset_pw ()
{
  CURUSER=$1
  timestamp=`date`
  NEWPASS=$(dd if=/dev/urandom bs=64 count=1 2>/dev/null | tr -cd '[:alnum:]'|cut -c 1-12)
  if [[ $(grep -c "^${CURUSER}:" /etc/passwd) -lt 1 ]]; then
    echo "User does not exist."
    return 1
  fi
  echo ${NEWPASS} | passwd --stdin ${CURUSER} > /dev/null 2>&1
  chage -d 0 ${CURUSER} > /dev/null 2>&1

  cat << EOF | mailx -s "Password reset : $(hostname)" "${CURUSER}@safeway.com"
${CURUSER},
Your password has been reset on server $(hostname). Please log in and change your password immediately.
Your current password is: ${NEWPASS}
Password Change TimeStamp: ${timestamp}
EOF

  return 0
}

# Main
if [[ ${#USERARG} -ne 7 ]]; then
  echo "Invalid user ID specified."
  exit 1
fi
reset_pw ${USERARG} || exit 1

exit 0
