#!/bin/bash
#
# confess.sh - Configuração essencial da estação de trabalho Archlinux
#
# Autor			: Diego Varejão <varejaodfav@fab.mil.br>
# Manutenção	: Diego Varejão	<varejaodfav@fab.mil.br>
#
# CINDACTA III / Divisão Técnica
# Subdivisão de tecnologia da informação
# Seção de informática operacional
# (81) 2129-8293
#
# ----------------------------------------------------------------------
# Esta aplicação recebe as informações passadas anteriormente pelo usuário
# e insere aos arquivos essenciais de configuração da estação de trabalho.
# 
# Dependências:
#	* Não há
#
# Utilização:
#	$ sudo ./confess.sh
#
# Os arquivos de configuração alterados são os seguintes:
#	* /etc/clamav/freshclam.conf
#	* /etc/zabbix/zabbix_agentd.conf
# ----------------------------------------------------------------------
#
# Histórico
#
# v102017-0.1 18-10-2017, Diego Varejão
#	- Versão inicial

#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
################## INÍCIO DE TESTES DE DEPENDÊNCIAS ####################
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#

# Verifica se o usuário tem privilégios para executar a aplicação
if test "$UID" -ne 0
then
	printf "	>> ERRO: É preciso permissão de ${txtbld}${txtred}root${txtrst} para executar esta aplicação."
	exit 1
fi

#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
################### FIM DE TESTES DE DEPENDÊNCIAS ######################
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#

########################################################################
################# INÍCIO DA DECLARAÇÃO DE VARIÁVEIS ####################
########################################################################

DIRCONFIG="$PWD/conf"
HOSTNAME=`cat $DIRCONFIG/hostname`

########################################################################
################# FIM DA DECLARAÇÃO DE VARIÁVEIS #######################
########################################################################

# Configura o agente do Zabbix
cat << EOF > $DIRCONFIG/zabbix_agentd.conf
# HOST TIOp - CONFIGURAÇÃO DE AGENTE

# Servidor de monitoramento
Server=10.80.11.59
ServerActive=10.80.11.59

# Nome do computador
Hostname=$HOSTNAME

# Habilitar metadados do host
HostMetadata=Linux    21df83bf21bf0be663090bb8d4128558ab9b95fba66a6dbf834f8b91ae5e08ae    AMHS

# Monitorar updates do sistema
Include=/etc/zabbix/zabbix_agentd.conf.d/*.conf

# Habilitar comandos remotos pelo zabbix
EnableRemoteCommands=1

# Informações de logs
DebugLevel=3

# Tipo de armazenagem de logs (system = syslog, file = arquivo de log externo)
LogType=system
#LogFile=/tioplog/zabbix-agente
EOF

# Configura o antivírus ClamAV
cat << EOF > $DIRCONFIG/freshclam.conf
# Arquivo de log
UpdateLogFile /var/log/clamav/freshclam.log

# Servidor
#DatabaseMirror http://clamav.cindacta3.intraer
PrivateMirror http://clamav.cindacta3.intraer

# Arquivos essenciais
DatabaseCustomURL http://clamav.cindacta3.intraer/daily.cvd
DatabaseCustomURL http://clamav.cindacta3.intraer/main.cvd
DatabaseCustomURL http://clamav.cindacta3.intraer/bytecode.cvd

# Arquivo de configuração
NotifyClamd /etc/clamav/clamd.conf
ScriptedUpdates no

# Proxy
HTTPProxyServer 10.80.11.59 
HTTPProxyPort 80
EOF

# Configura o repositório da TIOp
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.original
echo "Server = http://archlinux.cindacta3.intraer/repoarch/$repo/os/$arch" > /etc/pacman.d/mirrorlist

cat $DIRCONFIG/freshclam.conf 		> /mnt/etc/clamav/freshclam.conf
cat $DIRCONFIG/zabbix_agentd.conf 	> /mnt/etc/zabbix/zabbix_agentd.conf
