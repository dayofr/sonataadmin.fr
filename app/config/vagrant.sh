#!/bin/sh

php="5.4.23"
apache="2.2.26"
phpmyadmin="4.1.2"
httpdconf="/opt/app/httpd/$apache/conf/httpd.conf"
phpini="/opt/app/httpd/$apache/php/$php/lib/php.ini"

wget http://mirrors.ircam.fr/pub/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uv epel-release-6-8.noarch.rpm

yum -y update
yum -y install apr-devel apr-util-devel autoconf bison curl-devel gd-devel libicu libicu-devel libjpeg-devel libmcrypt-devel libxml2-devel mysql-server mysql-devel openssl-devel pcre-devel rubygems unzip zip zlib-devel

gem install capifony

mkdir /opt/app
mkdir /opt/app/httpd
wget http://archive.apache.org/dist/httpd/httpd-$apache.tar.gz
tar -xzf httpd-$apache.tar.gz
cd httpd-$apache
./configure --prefix=/opt/app/httpd/$apache --enable-proxy --enable-ssl --enable-headers --enable-expires --enable-deflate --enable-rewrite --enable-unique-id --with-pcre=/usr/bin/pcre-config --disable-autoindex --disable-cgi --disable-status --disable-userdir --disable-version --enable-vhost-alias
make
make install
cd

mkdir /opt/app/httpd/$apache/php
mkdir /opt/app/httpd/$apache/php/$php
wget http://www.php.net/get/php-$php.tar.gz/from/fr2.php.net/mirror
tar -xzf php-$php.tar.gz
cd php-$php
./configure --prefix=/opt/app/httpd/$apache/php/$php --with-apxs2=/opt/app/httpd/$apache/bin/apxs --with-pdo-mysql --with-libdir=lib64 --with-mysqli --with-curl --with-openssl --with-gd --enable-gd-native-ttf --with-freetype-dir --with-jpeg-dir --enable-soap --with-zlib --with-mcrypt --enable-sysvmsg --enable-sysvsem --enable-sysvshm --enable-mbstring --enable-intl 
make
make install
cp php.ini-development $phpini

sed -i 's/^;\(date\.timezone\) =\s*$/\1 = "Europe\/Paris"/g' $phpini
sed -i 's/^\(memory_limit\) = .*$/\1 = 256M/g' $phpini
sed -i 's/^\(post_max_size\) = .*$/\1 = 32M/g' $phpini
sed -i 's/^\(upload_max_filesize\) = .*$/\1 = 32M/g' $phpini
sed -i 's/soap.wsdl_cache_enabled=1/soap.wsdl_cache_enabled=0/g' $phpini
sed -i 's/mysqli.default_socket =/ mysqli.default_socket = \/var\/lib\/mysql\/mysql.sock/g' $phpini
sed -i 's/error_reporting = .*/error_reporting = E_ALL | E_STRICT/g' $phpini
sed -i 's/display_errors = Off/display_errors = On/g' $phpini
sed -i 's/html_errors = Off/html_errors = On/g' $phpini

sed -i 's/DirectoryIndex index.html/DirectoryIndex index.html index.php /g' $httpdconf
echo "AddType application/x-httpd-php .php" >> $httpdconf
echo "AddType application/x-httpd-php .phtml" >> $httpdconf
echo "AddType application/x-httpd-php-source .phps" >> $httpdconf
echo "NameVirtualHost *:80" >> $httpdconf
echo "UseCanonicalName Off" >> $httpdconf
echo "<VirtualHost *:80>" >> $httpdconf
echo "" >> $httpdconf
echo "        DocumentRoot /vagrant/web" >> $httpdconf
echo "        <Directory /vagrant/web/>" >> $httpdconf
echo "                Options Indexes FollowSymLinks MultiViews" >> $httpdconf
echo "                AllowOverride All" >> $httpdconf
echo "                Order allow,deny" >> $httpdconf
echo "                Allow from all" >> $httpdconf
echo "        </Directory>" >> $httpdconf
echo "" >> $httpdconf
echo "        ErrorLog /opt/app/httpd/$apache/logs/error-site.log" >> $httpdconf
echo "</VirtualHost>" >> $httpdconf

cd

echo "export PATH=$PATH:/opt/app/httpd/${apache}/php/${php}/bin" >> /home/vagrant/.bashrc
echo "export PATH=$PATH:/opt/app/httpd/${apache}/php/${php}/bin" >> /root/.bashrc

export PATH=$PATH:/opt/app/httpd/$apache/php/$php/bin

printf "\n" | pecl install APC-3.1.12
echo "extension=\"/opt/app/httpd/$apache/php/$php/lib/php/extensions/no-debug-non-zts-20100525/apc.so\"" >> $phpini

printf "\n" | pecl install xdebug
echo "zend_extension=\"/opt/app/httpd/$apache/php/$php/lib/php/extensions/no-debug-non-zts-20100525/xdebug.so\"" >> $phpini

echo "[xdebug]" >> $phpini
echo "xdebug.remote_enable=On" >> $phpini
echo "xdebug.remote_handler=dbgp" >> $phpini
echo "xdebug.remote_mode=req" >> $phpini
echo "xdebug.remote_host=10.0.2.2" >> $phpini
echo "xdebug.remote_port=9000" >> $phpini


pear channel-discover pear.phpunit.de
pear channel-discover pear.symfony.com
pear install --alldeps phpunit/PHPUnit

curl -sS https://getcomposer.org/installer | php
mv composer.phar /bin/composer

wget http://downloads.sourceforge.net/project/phpmyadmin/phpMyAdmin/$phpmyadmin/phpMyAdmin-$phpmyadmin-all-languages.zip?use_mirror=surfnet
unzip phpMyAdmin-$phpmyadmin-all-languages.zip -d /opt
cd /opt/phpMyAdmin-$phpmyadmin-all-languages

cp config.sample.inc.php config.inc.php

echo "<VirtualHost *:80>" >> $httpdconf
echo "        ServerName www.pma.local" >> $httpdconf
echo "        ServerAlias *.pma.local *.local" >> $httpdconf
echo "" >> $httpdconf
echo "        DocumentRoot /opt/phpMyAdmin-$phpmyadmin-all-languages" >> $httpdconf
echo "        <Directory /opt/phpMyAdmin-$phpmyadmin-all-languages/>" >> $httpdconf
echo "                Options Indexes FollowSymLinks MultiViews" >> $httpdconf
echo "                AllowOverride All" >> $httpdconf
echo "                Order allow,deny" >> $httpdconf
echo "                Allow from all" >> $httpdconf
echo "        </Directory>" >> $httpdconf
echo "" >> $httpdconf
echo "        ErrorLog /opt/app/httpd/$apache/logs/error-pma.log" >> $httpdconf
echo "</VirtualHost>" >> $httpdconf


service iptables stop
chkconfig iptables off

service mysqld start
chkconfig --levels 235 mysqld on

/usr/bin/mysqladmin -u root password 'vagrant'
/usr/bin/mysqladmin -u root -h localhost.localdomain password 'vagrant'

cd /etc/init.d/
ln -s /opt/app/httpd/$apache/bin/apachectl httpd
cd /etc/rc3.d
ln -s ../init.d/httpd S99httpd
service httpd start


cd /vagrant
composer install
app/console doctrine:database:create
app/console doctrine:schema:create
app/console assets:install --symlink web
app/console fos:user:create admintest admin@test.com pass --super-admin
