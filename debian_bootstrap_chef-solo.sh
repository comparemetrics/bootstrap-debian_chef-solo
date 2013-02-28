#!/bin/bash
# Bootstrap debian and chef-solo
#

echo -e "\nInstalling development dependencies and essential tools..." \
        "\n===============================================================================\n"

export DEBIAN_FRONTEND=noninteractive

# Update OS
apt-get update --yes --fix-missing -qq
apt-get upgrade --yes --fix-missing -qq
apt-get dist-upgrade --yes --fix-missing -qq

# Install apt-utils
apt-get -y install apt-utils --yes --fix-missing --force-yes -qq

# Install build tools
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install git build-essential screen curl git-core sudo --yes --fix-missing --force-yes -qq

# Make sure we are running a Bash shell
ln -sf /bin/bash /bin/sh

echo -e "\nInstalling Ruby and Rubygems..." \
        "\n===============================================================================\n"

# Install Ruby dependencies
apt-get -y install bison zlib1g-dev libopenssl-ruby1.9.1 libssl-dev libreadline5-dev libncurses5-dev libyaml-0-2 libxslt-dev libxml2-dev file --yes --fix-missing -qq

# Install Ruby
apt-get -y install ruby1.9.1 ruby1.9.1-dev --yes --fix-missing -qq

# Fix Debian
ln -nfs /usr/bin/ruby1.9.1 /usr/local/bin/ruby
ln -nfs /usr/bin/gem1.9.1 /usr/local/bin/gem
echo "PATH=$PATH:/var/lib/gems/1.9.1/bin/" > /etc/profile.d/rubygems.sh
source /etc/profile.d/rubygems.sh

# Install the JSON gem
gem install json --no-ri --no-rdoc

echo -e "\nInstalling and bootstrapping Chef..." \
        "\n===============================================================================\n"
test -d "/opt/chef" || curl -# -L http://www.opscode.com/chef/install.sh | sudo bash -s --

mkdir -p /etc/chef/
mkdir -p /var/chef-solo/site-cookbooks
mkdir -p /var/chef-solo/cookbooks

if test -f /tmp/solo.rb;   then mv /tmp/solo.rb /etc/chef/solo.rb;     fi
if test -d /tmp/data_bags; then mv /tmp/data_bags /etc/chef/data_bags; fi

echo -e "\n*******************************************************************************\n" \
        "Bootstrap finished" \
        "\n*******************************************************************************\n"
