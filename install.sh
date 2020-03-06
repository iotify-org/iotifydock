#!/bin/bash

## ------------------------------------------------------------------
## [Author] Title
##          Description
## ------------------------------------------------------------------
clear
msg="
  _____     _____ _  __       
  \_   \___/__   (_)/ _|_   _ 
   / /\/ _ \ / /\/ | |_| | | |
/\/ /_| (_) / /  | |  _| |_| |
\____/ \___/\/   |_|_|  \__, |
                        |___/ 

"
tput setaf 4;
echo "$msg"
tput setaf 7;

random_string()
{
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}
sleep 2

tput setaf 2;
echo "We will need some information to configure the system installation"
tput setaf 7;
echo ""

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
  read -p "Enter a new root mysql password : " mysql_root_password
done


while [[ -z "$mysql_admin_user" ]]
do
  read -p "Enter a new admin mysql user : " mysql_admin_user
done


while [[ -z "$mysql_admin_password" ]]
do
  read -p "Enter a new admin mysql password : " mysql_admin_password
done

while [[ -z "$mysql_database_name" ]]
do
  read -p "Enter a name for mysql database : " mysql_database_name
done



echo ""
echo ""
echo ""
tput setaf 2;
echo "*************************"
echo "**** S U M A R Y ********"
echo "*************************"
tput setaf 7;
echo ""
echo "TIMEZONE: $timezone"
echo "DOMAIN: $domain"
echo "EMAIL SSL: $email"
echo ""
tput setaf 4;
echo "if you see any error press ctrl + c"
tput setaf 7;

for i in {10..1..1};do echo -n "$i." && sleep 1; done


emqx_dash_user=admin
emqx_dash_password=$(random_string)
emqx_api_id=admin
emqx_api_secret=$(random_string)



cd /

tput setaf 2;
echo ""
echo "**************************"
echo "**** UPDATING SYSTEM *****"
echo "**************************"
echo ""
tput setaf 7;
sleep 3


apt-get update
apt dist-upgrade -y

tput setaf 2;
echo ""
echo "******************************"
echo "**** INSTALLING FAIL2BAN *****"
echo "******************************"
echo ""
tput setaf 7;
sleep 3

apt install fail2ban -y

tput setaf 2;
echo ""
echo "******************************"
echo "**** INSTALLING DOCKER *****"
echo "******************************"
echo ""
tput setaf 7;
sleep 3

#DOCKER
apt-get install -y \
    apt-transport-https \ 
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
apt-get update.
apt-get install docker-ce docker-ce-cli containerd.io -y
docker run hello-world

tput setaf 2;
echo ""
echo "************************************"
echo "**** INSTALLING DOCKER-COMPOSE *****"
echo "************************************"
echo ""
tput setaf 7;
sleep 3

#DOCKER COMPOSE
curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-$
chmod +x /usr/local/bin/docker-compose
docker-compose --version

tput setaf 2;
echo ""
echo "******************************"
echo "**** CLONING REPOSITORY ******"
echo "******************************"
echo ""
tput setaf 7;
sleep 3

#IOTIFY
git clone https://github.com/iotify-org/iotifydock.git
cd iotifydock


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
echo "EMQX_API_ID=$emqx_api_id" >> ./.env
echo "EMQX_API_SECRET=$emqx_api_secret" >> ./.env

tput setaf 2;
echo ""
echo "*******************************"
echo "**** GENERATING SSL CERTS *****"
echo "*******************************"
echo ""
tput setaf 7;
sleep 3

#GENERATING SSL CERTS
docker-compose -f certbot.yml up
docker rm $(docker ps -a -q) -f

tput setaf 2;
echo ""
echo "*************************************"
echo "****   INSTALLING MQTT BROKER   *****"
echo "*************************************"
echo ""
tput setaf 7;
sleep 3

unzip emqx.zip

#SETTING UP EMQX DASHBOARD CREDENTIALS
sed -i "8s/.*/dashboard.default_user.login = $emqx_dash_user/" ./emqx/etc/plugins/emqx_dashboard.conf
sed -i "13s/.*/dashboard.default_user.password = $emqx_dash_password/" ./emqx/etc/plugins/emqx_dashboard.conf

#SETTING UP ACL CONF
sed -i "460s/.*/allow_anonymous = false/" ./emqx/etc/emqx.conf
sed -i "465s/.*/acl_nomatch = deny/" ./emqx/etc/emqx.conf

#SETTING UP MQTT LISTENERS
sed -i "880s/.*/listener.tcp.external.max_connections = 100/" ./emqx/etc/emqx.conf
sed -i "885s/.*/listener.tcp.external.max_conn_rate = 25/" ./emqx/etc/emqx.conf
sed -i "1011s/.*/listener.tcp.internal.max_connections = 100/" ./emqx/etc/emqx.conf
sed -i "1121s/.*/listener.ssl.external.max_conn_rate = 25/" ./emqx/etc/emqx.conf
sed -i "1116s/.*/listener.ssl.external.max_connections = 100/" ./emqx/etc/emqx.conf
sed -i "1121s/.*/listener.ssl.external.max_conn_rate = 25/" ./emqx/etc/emqx.conf
sed -i "1367s/.*/listener.ws.external.max_connections = 100/" ./emqx/etc/emqx.conf
sed -i "1372s/.*/listener.ws.external.max_conn_rate = 25/" ./emqx/etc/emqx.conf
sed -i "1578s/.*/listener.wss.external.max_connections = 100/" ./emqx/etc/emqx.conf
sed -i "1585s/.*/listener.wss.external.max_conn_rate = 25/" ./emqx/etc/emqx.conf

#SETTING UP MAIN EMQX API CREDENTIALS
sed -i "16s/.*/management.default_application.id = $emqx_api_id/" ./emqx/etc/plugins/emqx_management.conf
sed -i "21s/.*/management.default_application.secret = $emqx_api_secret/" ./emqx/etc/plugins/emqx_management.conf


#SETTING UP EMQX AUTH MYSQL
sed -i "10s/.*/auth.mysql.server = db:3306/" ./emqx/etc/plugins/emqx_auth_mysql.conf
sed -i "20s/.*/auth.mysql.username = $mysql_admin_user/" ./emqx/etc/plugins/emqx_auth_mysql.conf
sed -i "25s/.*/auth.mysql.password = $mysql_admin_password/" ./emqx/etc/plugins/emqx_auth_mysql.conf
sed -i "30s/.*/auth.mysql.database = $mysql_database_name/" ./emqx/etc/plugins/emqx_auth_mysql.conf
sed -i "35s/.*/auth.mysql.query_timeout = 15s/" ./emqx/etc/plugins/emqx_auth_mysql.conf
sed -i "96s/.*/auth.mysql.acl_query = select allow, ipaddr, username, clientid, access, topic from mqtt_user_acl where ipaddr = '%a' or username = '%u' or username = '$all' or clientid = '%c' ORDER BY id ASC/" ./emqx/etc/plugins/emqx_auth_mysql.conf

#SETTING UP DEFAULT EMQX PLUGINS 
echo '{emqx_auth_mysql,true}.' >> ./emqx/data/loaded_plugins

tput setaf 2;
echo ""
echo "**********************************"
echo "****   INSTALLING MQTT SSL   *****"
echo "**********************************"
echo ""
tput setaf 7;
sleep 3

rm ./emqx/etc/certs/cert.pem
rm ./emqx/etc/certs/key.pem

ln -s ./user-data/etc/letsencrypt/live/$domain/cert.pem ./emqx/etc/certs/cert.pem
ln -s ./user-data/etc/letsencrypt/live/$privkey/key.pem ./emqx/etc/certs/key.pem

tput setaf 2;
echo ""
echo "**********************************"
echo "****    STARTING SERVICES    *****"
echo "**********************************"
echo ""
tput setaf 7;
sleep 3

docker-compose up -d

tput setaf 2;
echo ""
echo "**********************************"
echo "****         READY!!!        *****"
echo "**********************************"
echo ""
tput setaf 7;

echo "Go to https://$domains that's all over here..."