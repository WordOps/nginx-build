#!/usr/bin/env bash

if [ -z "$(command -v curl)" ]; then
    apt-get update && apt-get install curl -y
fi

# Define NGINX version
PACKAGE_NAME="nginx"
NGINX_VERSION="$(curl -sL https://nginx.org/en/download.html 2>&1 | grep -E -o 'nginx\-[0-9.]+\.tar[.a-z]*' | awk -F "nginx-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 2 | grep 1.20 2>&1)"
EMAIL_ADDRESS="$1"

# Capture errors
function ppa_error()
{
    echo "[ $(date) ] $(tput setaf 1)${*}$(tput sgr0)"
    exit $2
}

# Echo function
function ppa_lib_echo()
{
    echo "$(tput setaf 4)${*}$(tput sgr0)"
}

# Update/Install Packages
ppa_lib_echo "Execute: apt-get update, please wait"
sudo apt-get update || ppa_error "Unable to update packages, exit status = " $?
ppa_lib_echo "Installing required packages, please wait"
sudo apt-get -y install git dh-make devscripts debhelper dput gnupg-agent dh-systemd vim || ppa_error "Unable to install packages, exit status = " $?

# Lets Clone Launchpad repository
ppa_lib_echo "Copy Launchpad Debian files, please wait"
rm -rf /tmp/launchpad ~/PPA && rsync -az nginx /tmp/launchpad/ \
|| ppa_error "Unable to clone launchpad repo, exit status = " $?

# Configure NGINX PPA
mkdir -p ~/PPA/$PACKAGE_NAME && cd ~/PPA/$PACKAGE_NAME \
|| ppa_error "Unable to create ~/PPA/$PACKAGE_NAME, exit status = " $?

# Download NGINX
ppa_lib_echo "Download nginx, please wait"
wget -c http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
|| ppa_error "Unable to download nginx-${NGINX_VERSION}.tar.gz, exit status = " $?
tar -zxvf nginx-${NGINX_VERSION}.tar.gz \
|| ppa_error "Unable to extract nginx, exit status = " $?
cd nginx-${NGINX_VERSION} \
|| ppa_error "Unable to change directory, exit status = " $?

# Lets start building
ppa_lib_echo "Execute: dh_make --single --copyright gpl --email $EMAIL_ADDRESS --createorig, please wait"
dh_make --single --copyright gpl --email "$EMAIL_ADDRESS" --createorig \
|| ppa_error "Unable to run dh_make command, exit status = " $?
rm debian/*.ex debian/*.EX \
|| ppa_error "Unable to remove unwanted files, exit status = " $?

# Let's copy files
cp -av /tmp/launchpad/nginx/debian/* ~/PPA/nginx/nginx-${NGINX_VERSION}/debian/ \
|| ppa_error "Unable to copy launchpad debian files, exit status = " $?

# NGINX modules
ppa_lib_echo "Downloading NGINX modules, please wait"
mkdir ~/PPA/nginx/modules && cd ~/PPA/nginx/modules \
|| ppa_error "Unable to create ~/PPA/nginx/modules, exit status = " $?

ppa_lib_echo "1/16 headers-more-nginx-module"
git clone https://github.com/openresty/headers-more-nginx-module.git \
|| ppa_error "Unable to clone headers-more-nginx-module repo, exit status = " $?

ppa_lib_echo "2/16 nginx-auth-pam"
git clone https://github.com/sto/ngx_http_auth_pam_module nginx-auth-pam  \
|| ppa_error "Unable to clone ngx_http_auth_pam_module repo, exit status = " $?

ppa_lib_echo "3/16 nginx-cache-purge"
git clone https://github.com/FRiCKLE/ngx_cache_purge.git nginx-cache-purge \
|| ppa_error "Unable to clone nginx-cache-purge repo, exit status = " $?

cd nginx-cache-purge || exit 1
patch -p1 < ~/data/nginx-build/patches/ngx_cache_purge.patch || ppa_error "Unable to patch nginx-cache-purge , exit status = " $?

cd ~/PPA/nginx/modules || exit 1

ppa_lib_echo "4/16 nginx-dav-ext-module"
git clone https://github.com/arut/nginx-dav-ext-module.git \
|| ppa_error "Unable to clone nginx-dav-ext-module repo, exit status = " $?

ppa_lib_echo "5/16 nginx-development-kit"
git clone https://github.com/simpl/ngx_devel_kit.git nginx-development-kit \
|| ppa_error "Unable to clone nginx-development-kit repo, exit status = " $?

ppa_lib_echo "6/16  nginx-echo"
git clone https://github.com/agentzh/echo-nginx-module.git nginx-echo \
|| ppa_error "Unable to clone nginx-echo repo, exit status = " $?

ppa_lib_echo "7/16 nginx-upstream-fair"
git clone https://github.com/itoffshore/nginx-upstream-fair.git \
|| ppa_error "Unable to clone nginx-upstream-fair repo, exit status = " $?

ppa_lib_echo "8/16 ngx_http_substitutions_filter_module"
git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git \
|| ppa_error "Unable to clone ngx_http_substitutions_filter_module repo, exit status = " $?

ppa_lib_echo "9/16 memc-nginx-module"
git clone https://github.com/openresty/memc-nginx-module.git \
|| ppa_error "Unable to clone memc-nginx-module repo, exit status = " $?

ppa_lib_echo "10/16 srcache-nginx-module"
git clone https://github.com/openresty/srcache-nginx-module.git \
|| ppa_error "Unable to clone srcache-nginx-module repo, exit status = " $?

ppa_lib_echo "11/16 HttpRedisModule"
git clone https://github.com/EasyEngine/ngx_http_redis.git HttpRedisModule \
|| ppa_error "Unable to clone nginx_http_redis_module repo, exit status = " $?

ppa_lib_echo "12/16 redis2-nginx-module"
git clone https://github.com/openresty/redis2-nginx-module.git \
|| ppa_error "Unable to clone redis2-nginx-module repo, exit status = " $?

ppa_lib_echo "13/16 ngx_devel_kit-module"
git clone https://github.com/simpl/ngx_devel_kit.git \
|| ppa_error "Unable to clone ngx_devel_kit-module repo, exit status = " $?

ppa_lib_echo "14/16 set-misc-nginx-module"
git clone https://github.com/openresty/set-misc-nginx-module.git \
|| ppa_error "Unable to clone set-misc-nginx-module repo, exit status = " $?

ppa_lib_echo "15/16 nginx-module-vts "
git clone https://github.com/vozlt/nginx-module-vts.git || ppa_error "Unable to download nginx-module-vts, exit status = " $?

ppa_lib_echo "16/16 ngx_brotli"
git clone --recursive https://github.com/eustas/ngx_brotli || ppa_error "Unable to download ngx_brotli, exit status = " $?

cp -av ~/PPA/nginx/modules ~/PPA/nginx/nginx-${NGINX_VERSION}/debian/ \
|| ppa_error "Unable to copy modules files, exit status = " $?

# Edit changelog
nano ~/PPA/nginx/nginx-${NGINX_VERSION}/debian/changelog
