##
## Build nginx from scratch and install it
##

# get the environment variables from the nginx_build_env.sh
# to config for this environment
#

if [ -f "./nginx/nginx_build_env.sh" ]; then
    echo "Found environmental config file for nginx exists."
    . ./nginx/nginx_build_env.sh 
else
    echo "Config file ./nginx/nginx_build_env.sh not found, must invoke from repo root. Exiting."
    exit 1
fi

#
# Make sure these exist before running the configure
# to install configs for various sites. Remove any existing
# files in these directories, they will be populated by the
# subsequent steps.
#
sudo mkdir -vp /etc/nginx/sites-available /etc/nginx/modules-available
sudo mkdir -vp /etc/nginx/sites-enabled   /etc/nginx/modules-available
rm -f /etc/nginx/sites-enabled/* /etc/nginx/modules-enabled/*
rm -f /etc/nginx/sites-available/* /etc/nginx/modules-available/*

echo "******** Install pre-req modules **************************"
cd ${ngx_dir}
service nginx stop
sudo apt-mark hold nginx ## prevent any upgrades that wipe out our config
sudo apt --yes   update && sudo apt --yes upgrade
sudo apt-get install --yes   gcc
sudo apt-get install --yes   make
sudo apt-get install --yes   make-guile
#sudo apt-get install --yes   libnginx-mod-rtmp # installs in /usr/lib/nginx/modules and conf in /etc/nginx
sudo apt-get install --yes   zlib1g-dev zlib1g
sudo apt-get install --yes   libpcre3 libpcre3-dev
sudo apt-get install --yes   libssl-dev
sudo apt-get install --yes   libperl-dev
sudo apt-get install --yes   libgd-dev
sudo apt-get install --yes   net-tools

echo "******** Install nginx nonce modules **************************"
cd ${ngx_dir}/ ; mkdir -pv ${ngx_tar_dir} ${ngx_dev_kit_tar_dir} ${setnginx_tar_dir}
wget -O  ${ngx_tar_dir}.tar.gz          http://nginx.org/download/${ngx_tar_dir}.tar.gz
tar --strip-components 1 -C ${ngx_tar_dir}         -xzvf ${ngx_tar_dir}.tar.gz
wget -O  ${ngx_dev_kit_tar_dir}.tar.gz  https://github.com/simpl/ngx_devel_kit/archive/${ngx_dev_kit_ver}.tar.gz
tar --strip-components 1 -C ${ngx_dev_kit_tar_dir} -xzvf ${ngx_dev_kit_tar_dir}.tar.gz
wget -O  ${setnginx_tar_dir}.tar.gz     https://github.com/openresty/set-misc-nginx-module/archive/${setnginx_ver}.tar.gz
tar --strip-components 1 -C ${setnginx_tar_dir}    -xzvf ${setnginx_tar_dir}.tar.gz

echo "******** configure nginx with nonces **************************"
cd ${ngx_dir}/${ngx_tar_dir}
# https://www.photographerstechsupport.com/tutorials/hosting-wordpress-on-aws-tutorial-part-2-setting-up-aws-for-wordpress-with-rds-nginx-hhvm-php-ssmtp/#nginx-source
 ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --modules-path=/usr/lib/nginx/modules \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=www-data \
    --group=www-data \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-threads \
    --with-file-aio \
    --with-http_v2_module \
    --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=native' \
    --with-http_ssl_module \
    --with-http_sub_module \
    --add-module=${ngx_dir}/${ngx_dev_kit_tar_dir}/ \
    --add-module=${ngx_dir}/${setnginx_tar_dir}/


echo "******** Build nginx **************************"
sudo  make -j2
sudo  make install

### set file permissions
echo "******** Set file permissions **************************"
sudo mkdir -pv \
    /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp 
sudo chown www-data:www-data /etc/nginx /usr/lib/nginx/modules /var/log/nginx /var/log/nginx/error.log /var/log/nginx/access.log  /var/cache/nginx/scgi_temp /var/cache/nginx/uwsgi_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/proxy_temp /var/cache/nginx/client_temp /var/cache/nginx
sudo chmod 750  /usr/lib/nginx/modules /var/log/nginx /var/log/nginx/error.log /var/log/nginx/access.log /var/cache/nginx/scgi_temp /var/cache/nginx/uwsgi_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/proxy_temp /var/cache/nginx/client_temp /var/cache/nginx
sudo chown root:www-data /var/run/nginx.lock /var/run/nginx.pid
sudo chmod 664          /var/run/nginx.lock /var/run/nginx.pid 
sudo chown -R www-data:www-data /etc/nginx
sudo chmod -R 770 /etc/nginx


## use this to build docker image
# https://stackoverflow.com/questions/28863126/creating-a-docker-image-with-nginx-compile-options-for-optional-http-modules