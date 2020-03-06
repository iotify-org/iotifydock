##!/bin/bash
## ------------------------------------------------------------------
## [Author] Title
##          Description
## ------------------------------------------------------------------
# 
#cd /
#
#apt-get update
#apt dist-upgrade -y
#apt install fail2ban -y
#
##DOCKER
#apt-get install -y \
#    apt-transport-https \ 
#    ca-certificates \
#    curl \
#    gnupg-agent \
#    software-properties-common
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#apt-key fingerprint 0EBFCD88
#apt-get update.
#apt-get install docker-ce docker-ce-cli containerd.io -y
#docker run hello-world
#
#
##DOCKER COMPOSE
#curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-$
#chmod +x /usr/local/bin/docker-compose
#docker-compose --version
#
##IOTIFY
#git clone https://github.com/iotify-org/iotifydock.git
#cd iotifydock

while [[ -z "$timezone" ]]
do
  read -p "Enter your Timezone : "  timezone
done

while [[ -z "$domain" ]]
do
  read -p "Enter your domain : " domain
done


while [[ -z "$email" ]]
do
  read -p "Enter our email for ssl notifications: " email
done

while [[ -z "$mysql_root_password" ]]
do
  read -p "Enter a new root mysql user password : " mysql_root_password
done


while [[ -z "$mysql_admin_user" ]]
do
  read -p "Enter a new admin mysql user : " mysql_admin_user
done


while [[ -z "$mysql_admin_password" ]]
do
  read -p "Enter a new admin  mysql user password : " mysql_admin_password
done

while [[ -z "$mysql_database_name" ]]
do
  read -p "Enter a name for mysql database : " mysql_database_name
done

while [[ -z "$emqx_dash_user" ]]
do
  read -p "Enter a username for EMQX dashboard : " emqx_dash_user
done

while [[ -z "$emqx_dash_password" ]]
do
  read -p "Enter a password for EMQX dashboard : " emqx_dash_password
done





echo "TIMEZONE=$timezone" > ./.env

echo "" >> ./.env
echo "#DOMAIN DATA" >> ./.env
echo "DOMAINS=$domain" >> ./.env
echo "EMAIL=$email" >> ./.env
echo "SECURE_CA=/etc/letsencrypt/live/certificate/chain.pem" >> ./.env
echo "SECURE_KEY=/etc/letsencrypt/live/certificate/privkey.pem" >> ./.env
echo "SECURE_CERT=/etc/letsencrypt/live/certificate/fullchain.pem" >> ./.env

echo "" >> ./.env

echo "#MYSQL" >> ./.env
echo "MYSQL_HOST=db" >> ./.env
echo "MYSQL_PORT=3306" >> ./.env
echo "MYSQL_USER=$mysql_admin_user" >> ./.env
echo "MYSQL_PASSWORD=$mysql_admin_password" >> ./.env
echo "MYSQL_ROOT_PASSWORD=$mysql_root_password" >> ./.env
echo "MYSQL_DATABASE=$mysql_database_name" >> ./.env


echo "EMQX_DASH_USER=$emqx_dash_user" >> ./.env
echo "EMQX_DASH_PASS=$emqx_dash_password" >> ./.env

#GENERATING SSL CERTS
docker-compose -f certbot.yml up
docker rm $(docker ps -a -q) -f

unzip emqx.zip

#SETTING UP EMQX DASHBOARD CREDENTIALS
sed -i "8s/.*/dashboard.default_user.login = $emqx_dash_user/" ./emqx/etc/plugins/emqx_dashboard.conf
sed -i "13s/.*/dashboard.default_user.password = $emqx_dash_password/" ./emqx/etc/plugins/emqx_dashboard.conf

#SETTING UP ACL CONF
sed -i "460s/.*/allow_anonymous = false/" ./emqx/etc/emqx.conf
sed -i "465s/.*/acl_nomatch = deny/" ./emqx/etc/emqx.conf

#SETTING UP MQTT LISTENERS
sed -i "1116s/.*/listener.ssl.external.max_connections = 100/" ./emqx/etc/emqx.conf
sed -i "1121s/.*/listener.ssl.external.max_conn_rate = 25/" ./emqx/etc/emqx.conf
sed -i "1367s/.*/listener.ws.external.max_connections = 100/" ./emqx/etc/emqx.conf
sed -i "1372s/.*/listener.ws.external.max_conn_rate = 25/" ./emqx/etc/emqx.conf
sed -i "1578s/.*/listener.wss.external.max_connections = 100/" ./emqx/etc/emqx.conf
sed -i "1585s/.*/listener.wss.external.max_conn_rate = 25/" ./emqx/etc/emqx.conf

#SETTING UP MAIN EMQX API CREDENTIALS
sed -i "16s/.*/management.default_application.id = $emqx_dash_user/" ./emqx/etc/plugins/emqx_management.conf
sed -i "21s/.*/management.default_application.secret = $emqx_dash_password/" ./emqx/etc/plugins/emqx_management.conf

#SETTING UP EMQX AUTH MYSQL
sed -i "20s/.*/auth.mysql.username = $mysql_admin_user/" ./emqx/etc/plugins/emqx_auth_mysql.conf
sed -i "25s/.*/auth.mysql.password = $mysql_admin_password/" ./emqx/etc/plugins/emqx_auth_mysql.conf
sed -i "35s/.*/auth.mysql.query_timeout = 15s/" ./emqx/etc/plugins/emqx_auth_mysql.conf
sed -i "96s/.*/auth.mysql.acl_query = select allow, ipaddr, username, clientid, access, topic from mqtt_user_acl where ipaddr = '%a' or username = '%u' or username = '$all' or clientid = '%c' ORDER BY id ASC/" ./emqx/etc/plugins/emqx_auth_mysql.conf

rm ./emqx/etc/certs/cert.pem
rm ./emqx/etc/certs/key.pem

ln -s ./user-data/etc/letsencrypt/live/$domain/cert.pem ./emqx/etc/certs/cert.pem
ln -s ./user-data/etc/letsencrypt/live/$privkey/key.pem ./emqx/etc/certs/key.pem

