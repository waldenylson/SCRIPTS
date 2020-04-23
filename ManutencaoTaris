#!/bin/bash
#
# ManutencaoTaris.sh - Gerencia opções de energia do Archlinux
#
# Autor		: Diego Varejão <varejaodfav@fab.mil.br>
#
# Manutenção	: Diego Varejão	<varejaodfav@fab.mil.br>
# Atualização	: 11/03/2020
#
# Manutenção	: Waldenylson Silva <waldenylsonwpss@fab.mil.br>
# Atualização	: 17/04/2020
#
# Manutenção	: João dos Santos <dossantosjbssj@fab.mil.br>
# Atualização	: 17/04/2020
#
# CINDACTA III / Divisão Técnica
# Subdivisão de tecnologia da informação
# Seção de informática operacional
# (81) 2129-8293
#
# ----------------------------------------------------------------------
# Este programa verifica o estado da máquina virtual Windows do TARIS e
# gerencia as opções de energia do Archlinux como: reinicialização e 
# desligamento. Também reinicia apenas a máquina virtual do TARIS.
# 
#
# Dependências:
#	* virtualbox
#	* libnotify
#	* systemd
#	* openbox
#
# Utilização:
#	$ ./ManutencaoTaris.sh
#
#-----------------------------------------------------------------------
#
# Histórico
#
# v032020-0.1 11-03-2020, Diego Varejão
#	- Versão inicial

NOMEVM='TARIS2020'
DATA=`date "+%m-%d-%Y %T"`
ESTADOMV=`vboxmanage showvminfo "$NOMEVM" | grep -c "running (since"`

if [ $ESTADOMV -eq 1 ]; then

	notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
	30000 \
	"Desligando TARIS" "O sistema virtual do TARIS está sendo desligado, \
	por favor aguarde até todo o sistema ser desativado."
	
	printf "\n$DATA Desligamento da máquina virtual pelo script de \
	manutenção do TARIS\n" >> /tiop/Logs/vmlog.txt
	
	# Desliga a máquina virtual do TARIS antes de executar qualquer ação
	VBoxManage controlvm $NOMEVM acpipowerbutton >> \
	/tiop/Logs/vmlog.txt 2>&1
	
	
	sleep 30

	if [ $GATILHO -eq 0 ]; then
	
		notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
		10000 \
		"Desligando computador" "Seu computador será desligado agora"
		
		printf "$DATA Desligamento do computador pelo script de \
		manutenção do TARIS\n" >> /tiop/Logs/hostlog.txt
		
		sleep 3
		
		systemctl poweroff
		
	elif [ $GATILHO -eq 2 ]; then
	
		printf "$DATA Reinicialização da máquina virtual pelo script de \
		manutenção do TARIS\n" >> /tiop/Logs/vmlog.txt
	
		#openbox --exit
		VBoxManage startvm $NOMEVM 
		
	else
	
		notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
		10000 \
		"Reiniciando computador" "Seu computador será reiniciado agora"
		
		printf "$DATA Reinicialização do computador pelo script de \
		manutenção do TARIS\n" >> /tiop/Logs/hostlog.txt
		
		sleep 3
		
		systemctl reboot
	fi

else
	if [ $GATILHO -eq 0 ]; then
	
		notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
		10000 \
		"Desligando computador" "Seu computador será desligado agora"
		
		sleep 3
		
		printf "$DATA Desligamento do computador pelo script de \
		manutenção do TARIS\n" >> /tiop/Logs/hostlog.txt
		
		systemctl poweroff
		
	elif [ $GATILHO -eq 2 ]; then
	
		printf "$DATA Inicialização da máquina virtual pelo script de \
		manutenção do TARIS\n" >> /tiop/Logs/vmlog.txt
	
		openbox --exit
		
	else
	
		notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
		10000 \
		"Reiniciando computador" "Seu computador será reiniciado agora"
		
		printf "$DATA Reinicialização do computador pelo script de \
		manutenção do TARIS\n" >> /tiop/Logs/hostlog.txt
		
		sleep 3
		
		systemctl reboot
	fi
fi
