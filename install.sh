#!/bin/bash

# Full Stack server set up for Adult Script Pro 3.4.6. Configured for 5900X, 128GB RAM, RTX 3080

# Initialize variables for large file upload
MAX_UPLOAD_SIZE="20480M"  # 20GB
MAX_EXECUTION_TIME="6000"  # 100 minutes

# System Optimization
sysctl -w net.core.somaxconn=65535
sysctl -w net.core.netdev_max_backlog=100000
sysctl -w net.ipv4.tcp_max_syn_backlog=8096
echo "* soft nofile 1048576" >> /etc/security/limits.conf
echo "* hard nofile 1048576" >> /etc/security/limits.conf
ulimit -n 1048576

# Update package index
dnf update -y

# Install EPEL and Remi repositories
dnf install -y epel-release
dnf install -y dnf-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm

# Enable Remi repository for PHP
dnf config-manager --set-enabled remi-php74

# Install Nginx
dnf install -y nginx

# Nginx Optimization and Large File Support
sed -i "s/worker_connections 1024;/worker_connections 1048576;/" /etc/nginx/nginx.conf
sed -i "s/# multi_accept on;/multi_accept on;/" /etc/nginx/nginx.conf
echo "worker_rlimit_nofile 1048576;" >> /etc/nginx/nginx.conf
echo "client_max_body_size ${MAX_UPLOAD_SIZE};" >> /etc/nginx/nginx.conf

# Start and Enable Nginx
systemctl start nginx
systemctl enable nginx

# Install MariaDB
dnf install -y mariadb-server mariadb

# MariaDB Optimization
cat <<EOL >> /etc/my.cnf.d/server.cnf
[mysqld]
max_connections = 5000
innodb_buffer_pool_size = 80G
innodb_io_capacity = 2000
innodb_read_io_threads = 64
innodb_write_io_threads = 64
EOL

# Start and Enable MariaDB
systemctl start mariadb
systemctl enable mariadb

# Install PHP and additional modules
dnf install -y php php-mysqlnd php-fpm php-gd php-curl php-ftp php-simplexml php-xml php-mbstring php-json php-zip php-opcache php-openssl

# PHP-FPM and Large File Support
sed -i "s/pm.max_children = 50/pm.max_children = 512/" /etc/php-fpm.d/www.conf
sed -i "s/pm.start_servers = 5/pm.start_servers = 20/" /etc/php-fpm.d/www.conf
sed -i "s/pm.min_spare_servers = 5/pm.min_spare_servers = 20/" /etc/php-fpm.d/www.conf
sed -i "s/pm.max_spare_servers = 35/pm.max_spare_servers = 50/" /etc/php-fpm.d/www.conf
echo "upload_max_filesize = ${MAX_UPLOAD_SIZE}" >> /etc/php.ini
echo "post_max_size = ${MAX_UPLOAD_SIZE}" >> /etc/php.ini
echo "max_execution_time = ${MAX_EXECUTION_TIME}" >> /etc/php.ini

# Install ImageMagick and PHP extension
dnf install -y ImageMagick ImageMagick-devel
dnf install -y php-pecl-imagick

# Install MP4Box
dnf install -y gpac

# Install ionCube Loader
cd /tmp
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar xzf ioncube_loaders_lin_x86-64.tar.gz
cp ioncube/ioncube_loader_lin_7.4.so /usr/lib64/php/modules/
echo "zend_extension = /usr/lib64/php/modules/ioncube_loader_lin_7.4.so" > /etc/php.d/00-ioncube.ini

# Start and Enable PHP-FPM
systemctl start php-fpm
systemctl enable php-fpm

# Install Sphinx
dnf install -y sphinx

# Start and Enable Sphinx
systemctl start searchd
systemctl enable searchd

# Display installed versions
nginx -v
mariadb --version
php -v
searchd --status

echo "All requested packages and optimizations have been applied."
