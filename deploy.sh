#!/usr/bin/env bash
#
# Debian Bootstrap for Chef Solo
# Copyright (C) 2013  Benjamin H. Graham (bhgraham1@gmail.com)
#
# GNU General Public License 2, see COPYING
#
# Source: https://github.com/comparemetrics/

# Check for command line argument.

# 0.4.1 - removing getopt for getopts as getopt is broken
die () {
	echo >&2 "$@"
	exit 1
}

PROGNAME=${0##*/}
PROGVERSION=0.4.1

usage() {
  cat << EO
Usage: $PROGNAME [options]
       $PROGNAME -d <version> -c

Bootstrap debian server with chef-solo

        Options:
EO
  cat <<EO | column -s\& -t

        -s & server ip or host to connect to
        -p & server ssh port to connect to
        -u & username used for ssh connection
        -k & ssh key used to connect to server
        -n & short name or nickname for server
        -d & fully qualified domain name for hostname
        -h & show this output
        -v & show version information
EO
}

while getopts "v:h:s:p:u:k:n:d:" opt; do
  case $opt in
    h)
		usage
		exit 0
		;;
	v)
		echo "$PROGVERSION"
		exit 0
		;;
	s)
		HOST=$OPTARG;
#		echo "$HOST"
		;;
	p)
		PORT=${OPTARG};
#		echo "$PORT"
		;;
	u)
		USER=${OPTARG};
#		echo "$USER"
		;;
	k)
		KEY=${OPTARG};
#		echo "$KEY"
		;;
	n)
		NAME=${OPTARG};
#		echo "$NAME"
		;;
	d)
		FQDN=${OPTARG};
#		echo "$FQDN"
		;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

[ "$#" -eq 12 ] || die "12 arguments required, $# provided";

# Set the name of the server:
#HOST=$1;
#PORT=$2;
#USER=$3;
#KEY=$4;
#NAME=$5;
#FQDN=$6;

SSH_OPTIONS="-o BatchMode=yes -o User=$USER -o IdentityFile=$KEY -o Port=$PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";

# Add to the known hosts
ssh-keyscan -H ${HOST} >> ~/.ssh/known_hosts

# Test SSH
ssh $SSH_OPTIONS $HOST "date"
if [ $? -ne 0 ]; then
    echo "SSH Failed";
	exit 255;
fi

#if [ -f node.json ]; then
#	echo "node.json missing, have you edited the example and renamed the file?"
#	exit 1;
#fi;

#if [ -f deploydata.sh ]; then
#	echo "deploydata.sh missing, have you edited the example and renamed file?"
#	exit 1;
#fi;

# Now, copy the files to the machine and execute the bootstrap script:
scp $SSH_OPTIONS debian_bootstrap_chef-solo.sh deploydata.sh node.json solo.rb $HOST:/tmp

ssh -t $SSH_OPTIONS $HOST "hostname $FQDN; echo hostname $FQDN>>/etc/rc.local;"

time ssh -t $SSH_OPTIONS $HOST "bash /tmp/debian_bootstrap_chef-solo.sh"
time ssh -t $SSH_OPTIONS $HOST "bash /tmp/deploydata.sh"

# Execute the _Chef Solo_ run:
time ssh -t $SSH_OPTIONS $HOST "chef-solo --node-name ".$NAME." -j /tmp/node.json"

