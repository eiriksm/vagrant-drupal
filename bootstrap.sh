#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive

# Date
# https://help.ubuntu.com/community/UbuntuTime
TIMEZONE=$(head -n 1 "/etc/timezone")
if [ $TIMEZONE != "Europe/Oslo" ]; then
    echo "Europe/Oslo" | sudo tee /etc/timezone
    sudo dpkg-reconfigure --frontend noninteractive tzdata
fi

if [ ! -d "/opt/provisioned" ]; then
  mkdir /opt/provisioned
  apt-get update

  # Install all kinds of useful stuff
  echo 'mysql-server-5.1 mysql-server/root_password password vagrant' | debconf-set-selections
  echo 'mysql-server-5.1 mysql-server/root_password_again password vagrant' | debconf-set-selections
  apt-get -qq -y install build-essential git curl vim apache2 php5 libapache2-mod-php5 mysql-server php-pear php5-gd php5-mysql php5-curl
  a2enmod rewrite
  cp /vagrant/apache/drupal.conf /etc/apache2/sites-available/
  cp /vagrant/apache/php.ini /etc/php5/apache2/php.ini
  a2ensite drupal
  a2dissite default
  usermod -a -G vagrant www-data
  /etc/init.d/apache2 restart
  pear channel-discover pear.drush.org
  pear install drush/drush
  # Have to run status once, to get drush to download something.
  drush st
  # Install Drupal
  if [ ! -d "/drupal" ]; then
    drush dl
    mv drupal* /drupal
  fi
  drush --root=/drupal si --db-su=root --db-su-pw=vagrant --db-url=mysql://drupal:drupal@localhost/drupal -y
fi
