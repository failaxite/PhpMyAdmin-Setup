apt install -y lsb-release ca-certificates apt-transport-https software-properties-common
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
wget -g0 - https://packages.sury.org/php/apt.gpg | apt-key add -
apt update
apt install php8.0 php8.0-common php8.0-mysql php8.0-gmp php8.0-curl php8.0-intl php8.0-mbstring php8.0-xmlrpc php8.0-gd php8.0-xml php8.0-cli php8.0-zip

latest=$(curl --silent https://www.phpmyadmin.net/ | grep href | grep files | head -n 1 | sed 's/.*href=//g; s/"//g' |  awk '{ print $1 }');
wget $latest;
unzip phpMyAdmin*;
rm -rf phpMyAdmin*.zip;
mv phpMyAdmin* /usr/share/phpmyadmin;
chown -R www-data:www-data /usr/share/phpmyadmin;

# Create the dababase.
mysql -u root -p"root" -e "DROP DATABASE IF EXISTS phpmyadmin;";
mysql -u root -p"root" -e "CREATE DATABASE phpmyadmin DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;";
mysql -u root -p"root" -e "GRANT ALL ON phpmyadmin.* TO 'root'@'localhost' IDENTIFIED BY 'root'; FLUSH PRIVILEGES;";

a2disconf phpmyadmin.conf && systemctl reload apache2;
echo "# phpMyAdmin default Apache configuration
Alias /phpmyadmin /usr/share/phpmyadmin
<Directory /usr/share/phpmyadmin>
    Options SymLinksIfOwnerMatch
    DirectoryIndex index.php
    <IfModule mod_php5.c>
        <IfModule mod_mime.c>
            AddType application/x-httpd-php .php
        </IfModule>
        <FilesMatch ".+\.php$">
            SetHandler application/x-httpd-php
        </FilesMatch>
        php_value include_path .
        php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
        php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/php/php-php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/
        php_admin_value mbstring.func_overload 0
    </IfModule>
    <IfModule mod_php.c>
        <IfModule mod_mime.c>
            AddType application/x-httpd-php .php
        </IfModule>
        <FilesMatch ".+\.php$">
            SetHandler application/x-httpd-php
        </FilesMatch>
        php_value include_path .
        php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
        php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/php/php-php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/
        php_admin_value mbstring.func_overload 0
    </IfModule>
</Directory>
# Disallow web access to directories that don't need it
<Directory /usr/share/phpmyadmin/templates>
    Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/libraries>
    Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/setup/lib>
    Require all denied
</Directory>" | tee /etc/apache2/conf-available/phpmyadmin.conf;

# Create temp folder.
mkdir -p /var/lib/phpmyadmin/tmp;
chown www-data:www-data /var/lib/phpmyadmin/tmp;

a2enconf phpmyadmin.conf && systemctl reload apache2;