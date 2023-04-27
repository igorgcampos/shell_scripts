#!/bin/bash

# Este script coleta informações importantes do servidor e salva em um arquivo markdown chamado server_info.md.
# As informações coletadas incluem: jobs no cron, portas abertas, conexões estabelecidas, compartilhamentos NFS,
# processos de aplicação em execução e os últimos logs que foram escritos em /var/log.

hostname=$(hostname)
output_file="${hostname}_info.md"
echo "# Informacoes do Servidor" > $output_file

echo "## Maquina Fisica ou Virtual ##" >> $output_file
echo '```' >> $output_file
product_name=$(cat /sys/devices/virtual/dmi/id/product_name)
if [[ $product_name == "KVM" || $product_name == "VMware Virtual Platform" || $product_name == "VirtualBox" || $product_name == "Xen" ]]; then
    echo "Virtual: $product_name" >> $output_file
else
    echo "Fisica: $product_name" >> $output_file
fi
echo '```' >> $output_file
echo "" >> $output_file

echo "## Jobs no Cron ##" >> $output_file
echo '```' >> $output_file
crontab -l >> $output_file
echo '```' >> $output_file
echo "" >> $output_file

echo "## Portas abertas no servidor (LSOF) ##" >> $output_file
echo '```' >> $output_file
sudo lsof -i -P -n | grep LISTEN >> $output_file
echo '```' >> $output_file
echo "" >> $output_file

echo "## Conexoes estabelecidas (netstat) ##" >> $output_file
echo '```' >> $output_file
sudo netstat -ntupe | grep ESTABLISHED >> $output_file
echo '```' >> $output_file
echo "" >> $output_file

# Lista os parâmetros "ServerName" e "ServerAlias" dos arquivos .conf do Apache no diretório /etc/httpd/sites.d
echo "## Configuracoes do Apache (ServerName e ServerAlias) ##" >> $output_file
echo '```' >> $output_file
sudo grep -E 'ServerName|ServerAlias' /etc/httpd/sites.d/*.conf >> $output_file
echo '```' >> $output_file
echo "" >> $output_file

echo "## Compartilhamentos NFS ##" >> $output_file
echo '```' >> $output_file
sudo df -hT >> $output_file
echo '```' >> $output_file
echo "" >> $output_file

## lista os processos de aplicações em execução no sistema, excluindo os processos do kernel.
## Usa o awk para processar e filtrar a saída do comando ps. Neste caso, ele verifica a oitava coluna da saída do comando ps (o campo 'STAT', que indica o estado do processo)
# e filtra os processos cujo estado não corresponde ao padrão \[*\] (ou seja, processos do kernel, que têm estados entre colchetes). Em seguida, ele imprime as informações dos processos filtrados.
echo "## Processos de aplicacoes em execucao ##" >> $output_file
echo '```' >> $output_file
ps aux --no-headers | awk '!($8 ~ /\[.*\]/) {print}' >> $output_file
echo '```' >> $output_file
echo "" >> $output_file

# O comando "ls -lt" Lista todos os arquivos em /var/log ordenado por data de modificacao, do mais recente para o mais antigo.
# "head -n 5" Filtra os primeiros ( Os 5 arquivos mais recentes).
# "awk '{print $9}'" Usa o comando awk para extrair apenas a nona coluna do resultado (o nome do arquivo) e armazenar os nomes dos 5 arquivos mais recentes na variável recent_logs.
echo "## Ultimos logs escritos em /var/log. ## " >> $output_file
recent_logs=$(ls -lt /var/log | head -n 5 | awk '{print $9}')
echo "Últimos logs encontrados:" >> $output_file
echo "$recent_logs" >> $output_file
echo "" >> $output_file

for log in $recent_logs; do
  echo "### Conteudo do arquivo $log" >> $output_file
  echo '```' >> $output_file
  sudo cat /var/log/$log >> $output_file
  echo '```' >> $output_file
  echo "" >> $output_file
done

exit 0
