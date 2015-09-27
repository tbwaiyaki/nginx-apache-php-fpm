FROM ubuntu
MAINTAINER Tbw

# Surpress Upstart errors/warning
# RUN dpkg-divert --local --rename --add /sbin/initctl
# RUN ln -sf /bin/true /sbin/initctl

# Let the conatiner know that there is no tty
# ENV DEBIAN_FRONTEND noninteractive

# Update base image
# Install software requirements
ADD ./sources.list /etc/apt/sources.list
RUN apt-get update
# tweak sources.list file to enable install of the PHP FastCGI Apache module
RUN sed -i -r 's|^# deb(.*multiverse)|deb\1|' /etc/apt/sources.list && \
        apt-get -y update && \
        apt-get -y upgrade && \
        apt-get -y install apache2 libapache2-mod-fastcgi php5-fpm

# change Apache's port number to 8080 and configure it to work with
# PHP5-FPM using the mod_fastcgi module and change the
# default virtual host Apache directive from port 80 to port 8080
RUN sed -i -r 's|Listen 80$|Listen 8080|' /etc/apache2/ports.conf && \
        sed -i -r 's|<VirtualHost \*:80>|<VirtualHost \*:8080>|' /etc/apache2/sites-available/000-default.conf && \
        sed -i -r 's|;listen.mode = 0660|listen.mode = 0666|' /etc/php5/fpm/pool.d/www.conf && \
        # remove error: "Could not reliably determine the server's
        # fully qualified domain name ..."
        echo 'ServerName localhost' > /etc/apache2/conf-available/fqdn.conf && \
        a2enconf fqdn && \

# Configure Apache to use mod_fastcgi
# Enable mod-action
        a2enmod actions && \
        #a2enconf php5-fpm && \
        update-rc.d apache2 enable && \
        service apache2 start && \
        apache2 -v  | grep 'Server version' | sed -r 's|.*([0-9]\.[0-9])(\.[0-9]).*|\1|' && \
		
# Change the permissions of the sites location
		chown www-data:www-data -R /var/www/

ADD ./fastcgi.conf /etc/apache2/mods-enabled/fastcgi.conf
RUN apachectl -t && \
	service apache2 restart && \
	/etc/init.d/php5-fpm restart && \

	rm -rf /var/www/sasa.mug && \
	mkdir -v /var/www/sasa.mug && \
	echo "<h1 style='color: green;'>Sasa!</h1>" | sudo tee /var/www/sasa.mug/index.html && \
	echo "<?php phpinfo(); ?>" | sudo tee /var/www/sasa.mug/info.php && \

	rm -rf /var/www/tuanze.mug && \
	mkdir -v /var/www/tuanze.mug && \
	echo "<h1 style='color: red;'>Tuanze Test Maze!</h1>" | sudo tee /var/www/tuanze.mug/index.html && \
	echo "<?php phpinfo(); ?>" | sudo tee /var/www/tuanze.mug/info.php && \

	rm -rf /etc/apache2/sites-available/sasa.mug.conf && \
	rm -rf /etc/apache2/sites-available/tuanze.mug.conf

ADD ./sasa.mug.conf /etc/apache2/sites-available/sasa.mug.conf
ADD ./tuanze.mug.conf /etc/apache2/sites-available/tuanze.mug.conf

RUN a2ensite sasa.mug && \
	a2ensite tuanze.mug && \
	apachectl -t && \
	service apache2 restart

#NOTES
## REMEMBER to check that ports.conf, the sites-available ports and
# the docker run -p settings are synchronised - VERY IMPORTANT!

## ALSO to avoid 500 Internal Server Error check that the file
# /etc/php5/fpm/pool.d/www.conf has the following settings:
#	listen.owner = www-data
#	listen.group = www-data
# Restart after these changes with /etc/init.d/php5-fpm restart

## NGINX install

# Install Nginx
RUN apt-get install -y nginx && \
	# remove the default virtual host's symlink
	rm /etc/nginx/sites-enabled/default && \

	# create virtual host mambo.mug
	mkdir -v /usr/share/nginx/mambo.mug && \
	echo "<h1 style='color: blue;'>Mambo Bado!</h1>" | sudo tee /usr/share/nginx/mambo.mug/index.html && \
	echo "<?php phpinfo(); ?>" | sudo tee /usr/share/nginx/mambo.mug/info.php && \

	# create virtual host endelea.mug
	mkdir -v /usr/share/nginx/endelea.mug && \
	echo "<h1 style='color: red;'>Endelea Tujenge!</h1>" | sudo tee /usr/share/nginx/endelea.mug/index.html && \
	echo "<?php phpinfo(); ?>" | sudo tee /usr/share/nginx/endelea.mug/info.php 

# Add the virtual hosts files mambo.mug and endelea.mug
ADD ./mambo.mug /etc/nginx/sites-available/mambo.mug
ADD ./endelea.mug /etc/nginx/sites-available/endelea.mug

# Add the proxy file
ADD ./nginx-apache /etc/nginx/sites-available/apache

# Enable both sites - create symbolic links to the sites-enabled directory
RUN ln -s /etc/nginx/sites-available/mambo.mug /etc/nginx/sites-enabled/mambo.mug && \
	ln -s /etc/nginx/sites-available/endelea.mug /etc/nginx/sites-enabled/endelea.mug && \
	ln -s /etc/nginx/sites-available/apache /etc/nginx/sites-enabled/apache && \

	# do nginx configuration test
	service nginx configtest && \
	service nginx reload
	
##NOTES
# IMPORTANT: In the proxy file, for the nginx server to listen on IPV4, the 'listen' parameter 
# should be as follows:
#	listen 0.0.0.0:80;

# To start up, use a script:
	# service apache2 start
	# /etc/init.d/php5-fpm restart
	# service nginx start

# To check for errors
	# tail -f /var/log/nginx/error.log

# To check access logs
	# tail -f /var/log/nginx/access.log
