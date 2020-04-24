#!/bin/bash
#
# TARIS.sh - Inicia a máquina virtual Ubuntu do TARIS
#
# Autor			: Diego Varejão <varejaodfav@fab.mil.br>
# Manutenção	: Diego Varejão	<varejaodfav@fab.mil.br>
# Atualização	: 11/03/2020
#
# CINDACTA III / Divisão Técnica
# Subdivisão de tecnologia da informação
# Seção de informática operacional
# (81) 2129-8293
#
# ----------------------------------------------------------------------
# Este programa inicia a máquina virtual Windows onde a aplicação AMHS
# é executada, e exibe uma mensagem ao usuário informando o status da 
# inicialização.
# 
#
# Dependências:
#	* virtualbox
#	* libnotify
#
# Utilização:
#	$ ./TARIS.sh
#
#-----------------------------------------------------------------------
#
# Histórico
#
# v042018-0.1 05-04-2018, Diego Varejão
#	- Versão inicial
# v032020-0.2 11-03-2020, Diego Varejão
#	- Corrigido a verificação de inicialização da máquina virtual
#	- Acrescentado o log de inicialização da máquina virtual

NOMEVM='TARIS2020'
DATA=`date "+%m-%d-%Y %T"`

sleep 15 

notify-send -i /home/operador/.config/tiop/icones/info.svg -t 23000 \
"Inicializando TARIS..." "Aguardando inicialização da máquina virtual"

printf "\n$DATA Inicialização da máquina virtual\n" >> \
/tiop/Logs/vmlog.txt

VBoxManage startvm "$NOMEVM" >> \
/tiop/Logs/vmlog.txt 2>&1

if [ "$?" -ne 0 ]; then 

	notify-send -i /home/operador/.config/tiop/icones/cancel.svg -t \
	100000 \
	"Falha ao inicializar TARIS" "Ocorreu uma falha ao inicializar o \
	sistema virtual. Favor entrar em contato com a TIOp pelo ramal \
	8293 e reportar o ocorrido"

	exit 1
fi

sleep 23

notify-send -i /home/operador/.config/tiop/icones/checked.svg \
	-t 100000 "Inicialização concluída!" \
	"Acesse o TARIS pressionando Ctrl + Alt + 3 e retorne ao linux \
	pressionando Ctrl + Alt + 1"
