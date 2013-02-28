#!/bin/bash
#
# Debian Bootstrap for Chef Solo
# Copyright (C) 2013  Benjamin H. Graham (bhgraham1@gmail.com)
#
# GNU General Public License 2, see COPYING
#
# Source: https://github.com/comparemetrics/

# Check for command line argument.

die () {
	echo >&2 "$@"
	exit 1
}

PROGNAME=${0##*/}
PROGVERSION=0.3.0

usage() {
  cat << EO
Usage: $PROGNAME [options]
       $PROGNAME -d <version> -c

Bootstrap debian server with chef-solo

        Options:
EO
  cat <<EO | column -s\& -t

        -s|--server & server ip or host to connect to
        -p|--port & server ssh port to connect to
        -u|--user & username used for ssh connection
        -k|--key & ssh key used to connect to server
        -n|--name & short name or nickname for server
        -d|--domain & fully qualified domain name for hostname
        -h|--help & show this output
        -v|--version & show version information
EO
}

SHORTOPTS="hvtspuknd:"
LONGOPTS="help,version,test,server,port,user,key,name,domain:"

ARGS=$(getopt -s bash --options $SHORTOPTS  \
  --longoptions $LONGOPTS --name $PROGNAME -- "$@" )

eval set -- "$ARGS"

while true; do
   case $1 in
      -h|--help)
         usage
         exit 0
         ;;
      -v|--version)
         echo "$PROGVERSION"
         exit 0
         ;;
      -s|--server)
         shift
		 HOST=$1;
         echo $HOST
         ;;
      -p|--port)
         shift
		 PORT=$1;
         echo "$PORT"
         ;;
      -u|--user)
         shift
		 USER=$1;
         echo "$USER"
         ;;
      -k|--key)
         shift
		 KEY=$1;
         echo "$KEY"
         ;;
      -n|--name)
         shift
		 NAME=$1;
         echo "$NAME"
         ;;
      -d|--domain)
         shift
		 FQDN=$1;
         echo "$FQDN"
         ;;
      --)
         shift
         break
         ;;
      *)
         shift
         break
         ;;
   esac
   shift
done

[ "$#" -eq 12 ] || die "12 arguments required, $# provided";

exit
# Set the name of the server:
HOST=$1;
PORT=$2;
USER=$3;
KEY=$4;
NAME=$5;
FQDN=$6;

SSH_OPTIONS="-o BatchMode=yes -o User=$USER -o IdentityFile=$KEY -o Port=$PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";

# Add to the known hosts
ssh-keyscan -H ${HOST} >> ~/.ssh/known_hosts

# Test SSH
ssh $SSH_OPTIONS $HOST "date"
if [ $? -ne 0 ]; then
    echo "SSH Failed";
	exit 255;
fi

if [ deploydata.sh does not exist ]; then
	echo "node.json missing, have you edited the example and renamed the file?"
	exit 1;
fi;

if [ deploydata.sh does not exist ]; then
	echo "deploydata.sh missing, have you edited the example and renamed file?"
	exit 1;
fi;

# Now, copy the files to the machine and execute the bootstrap script:
scp $SSH_OPTIONS debian_bootstrap_chef-solo.sh deploydata.sh node.json solo.rb $HOST:/tmp

ssh -t $SSH_OPTIONS $HOST "hostname $FQDN; echo hostname $FQDN>>/etc/rc.local;"

time ssh -t $SSH_OPTIONS $HOST "bash /tmp/debian_bootstrap_chef-solo.sh"
time ssh -t $SSH_OPTIONS $HOST "bash /tmp/deploydata.sh"

# Execute the _Chef Solo_ run:
time ssh -t $SSH_OPTIONS $HOST "chef-solo --node-name ".$NAME." -j /tmp/node.json"

