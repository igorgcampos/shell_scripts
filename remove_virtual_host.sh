#!/bin/bash

# Verifica se o usuário é root
if [ "$(id -u)" != "0" ]; then
    echo "Este script deve ser executado como root" 1>&2
    exit 1
fi

# Obtem o nome do domínio
read -p "Informe o nome do domínio (ex: exemplo.com): " domain

# Desativa e remove o arquivo de configuração do VirtualHost
config_file="/etc/apache2/sites-available/${domain}.conf"

if [ -f "$config_file" ]; then
    a2dissite "${domain}.conf"
    rm "$config_file"
else
    echo "Arquivo de configuração do VirtualHost não encontrado. Saindo."
    exit 1
fi

# Remove o arquivo de configuração SSL
ssl_config_file="/etc/apache2/sites-available/${domain}-le-ssl.conf"

if [ -f "$ssl_config_file" ]; then
    a2dissite "${domain}-le-ssl.conf"
    rm "$ssl_config_file"
else
    echo "Arquivo de configuração SSL não encontrado."
fi

# Remove os arquivos de certificado SSL e configurações relacionadas ao domínio
letsencrypt_dir="/etc/letsencrypt"
live_dir="${letsencrypt_dir}/live/${domain}"
archive_dir="${letsencrypt_dir}/archive/${domain}"
config_dir="${letsencrypt_dir}/renewal"

if [ -d "$live_dir" ]; then
    rm -r "$live_dir"
else
    echo "Diretório 'live' do Let's Encrypt não encontrado."
fi

if [ -d "$archive_dir" ]; then
    rm -r "$archive_dir"
else
    echo "Diretório 'archive' do Let's Encrypt não encontrado."
fi

config_file="${config_dir}/${domain}.conf"
if [ -f "$config_file" ]; then
    rm "$config_file"
else
    echo "Arquivo de configuração de renovação do Let's Encrypt não encontrado."
fi

# Reinicie o Apache para aplicar as alterações
systemctl restart apache2

echo "Concluído! O VirtualHost e suas dependências de SSL foram removidos com sucesso."

