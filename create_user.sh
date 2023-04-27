#!/bin/bash

# Verifica se o script esta sendo executado como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script deve ser executado como root" 1>&2
   exit 1
fi

# Verifica se os argumentos corretos foram fornecidos
if [[ $# -ne 2 ]]; then
    echo "Uso: $0 <nome_do_usuario> <caminho_para_chave_publica>" 1>&2
    exit 1
fi

# Define o nome de usuario e o caminho para o arquivo da chave publica a partir dos argumentos fornecidos
new_username="$1"
public_key_file="$2"

# Cria o novo usuario
useradd -m -s /bin/bash "$new_username"

# Cria o diretorio .ssh no diretorio home do novo usuario
mkdir -p "/home/$new_username/.ssh"

# Adiciona a chave publica ao arquivo authorized_keys do novo usuario
cat "$public_key_file" >> "/home/$new_username/.ssh/authorized_keys"

# Ajusta as permissoes do diretorio .ssh e do arquivo authorized_keys
chown -R "$new_username:$new_username" "/home/$new_username/.ssh"
chmod 700 "/home/$new_username/.ssh"
chmod 600 "/home/$new_username/.ssh/authorized_keys"

# Adiciona o novo usuario ao grupo sudo
usermod -aG sudo "$new_username"

# Adiciona a entrada no arquivo /etc/sudoers para permitir que o novo usuario use sudo sem senha
echo "$new_username   ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

echo "Usuario $new_username criado, chave publica adicionada e permissoes sudo concedidas sem senha com sucesso."
