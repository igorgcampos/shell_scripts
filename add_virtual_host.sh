#!/bin/bash

# Verifique se o usuário é root
if [ "$(id -u)" != "0" ]; then
    echo "Este script deve ser executado como root" 1>&2
    exit 1
fi

# Obtenha o nome do domínio e o endereço do servidor de destino
read -p "Informe o nome do domínio (ex: *telespazio.com.br): " domain
read -p "Informe o endereço do servidor de destino (ex: http://192.168.0.2:8080): " target

# Crie o arquivo de configuração do VirtualHost
config_file="/etc/apache2/sites-available/${domain}.conf"

cat > "$config_file" <<EOL
<VirtualHost *:80>
    ServerName $domain

    ProxyPreserveHost On
    ProxyPass / $target/
    ProxyPassReverse / $target/

    ErrorLog \${APACHE_LOG_DIR}/${domain}_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain}_access.log combined
</VirtualHost>
EOL

# Habilite os módulos necessários e o novo site
a2enmod proxy proxy_http
a2ensite "${domain}.conf"

# Reinicie o Apache
systemctl restart apache2

# Instale o certbot se ainda não estiver instalado
#if ! command -v certbot &> /dev/null; then
    #apt-get update
    #apt-get install -y certbot python3-certbot-apache
#fi

# Obtenha o certificado SSL através do Let's Encrypt e configure o VirtualHost
certbot --apache -d "$domain"

echo "Concluído! O novo VirtualHost, como proxy reverso e o certificado SSL, foram configurados com sucesso."
