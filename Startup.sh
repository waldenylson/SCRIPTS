#!/bin/bash
#
# Statup.sh - Gerencia VMs do AMHS e TARIS e opções de energia do Archlinux 
#
# Autor			: Waldenylson Silva <waldenylsonwpss@fab.mil.br>
# Manutenção	: Waldenylson Silva <waldenylsonwpss@fab.mil.br>
# Agradecimento	: Diego Varejão	<varejaodfav@fab.mil.br>
# Atualização	: 23/04/2020
#
# CINDACTA III / Divisão Técnica
# Subdivisão de tecnologia da informação
# Seção de informática operacional
# (81) 2129-8293
#
# ----------------------------------------------------------------------
# Este programa verifica o estado da máquina virtual Windows do AMHS,
# Ubuntu do TARIS/VISIR e gerencia as opções de energia do Archlinux 
# como: inicialização, reinicialização e desligamento. 
# Também reinicia apenas a máquina virtual do AMHS ou TARIS/VISIR.
# 
#
# Dependências:
#	* virtualbox
#	* libnotify
#	* systemd
#	* openbox
#
# Utilização:
#	$ ./Startup.sh
#
#-----------------------------------------------------------------------
#
# Histórico
#
# v032020-0.1 11-03-2020, Diego Varejão
#	- Versão inicial
# v042020-0.2 23-04-2020, Waldenylson Silva
#   - Segunda Versão

#AMHSVM='AMHS2020'
#TARISVM='TARIS2020'
TESTEVM='MikroTik-6.36'
DATA=`date "+%m-%d-%Y %T"`

# ESTADOS VM ----------->
#						#
# RUNNING => 1			#
# STOPED  => 0			#
#						#
# ======================>

#ESTADOAMHS=`vboxmanage showvminfo "$AMHSVM" | grep -c "running (since"`
#ESTADOTARIS=`vboxmanage showvminfo "$TARISVM" | grep -c "running (since"`

ESTADOTESTE=`vboxmanage showvminfo "$TESTEVM" | grep -c "running (since"`

# Manipula as VMs =============================================================#
# $1 - Operação a ser executada na VM                                          #
# $2 - Nome da VM para execução da tarefa                                      #
#==============================================================================#
function ManipularVM()
{
	case "$1" in
		start)
			notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
			30000 \
			"Iniciando $2" "O sistema virtual do $2 está sendo iniciado, \
			por favor aguarde..."

			printf "$DATA Inicialização da máquina virtual $2 pelo script de \
			manutenção\n" >> /tmp/testeLogScript.log #/tiop/Logs/vmlog.txt

			VBoxManage startvm $2  >> /tmp/testeLogScript.log 2>&1 #/tiop/Logs/vmlog.txt 2>&1
		;;
		stop)
			notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
			30000 \
			"Desligando $2" "O sistema virtual do $2 está sendo desligado, \
			por favor aguarde..."

			printf "\n$DATA Desligamento da máquina virtual $2 pelo script de \
			manutenção\n" >> /tmp/testeLogScript.log #/tiop/Logs/vmlog.txt
				
			VBoxManage controlvm $2 acpipowerbutton >> /tmp/testeLogScript.log 2>&1 #/tiop/Logs/vmlog.txt 
		;;
		restart)
			notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
			30000 \
			"Reiniciando $2" "O sistema virtual do $2 está sendo reiniciado, \
			por favor aguarde..."

			printf "\n$DATA Reinicialização da máquina virtual $2 pelo script de \
			manutenção\n" >> /tmp/testeLogScript.log #/tiop/Logs/vmlog.tx

			ManipularVM stop $2
			sleep 10
			ManipularVM start $2
		;;
	esac	
}

echo $ESTADOTESTE



if [ $ESTADOMV -eq 1 ]; then # VM RUNNING

	
	
	printf "\n$DATA Desligamento da máquina virtual pelo script de \
	manutenção\n" >> /tiop/Logs/vmlog.txt
	
	# Desliga a máquina virtual do AMHS antes de executar qualquer ação
	ManipularVM stop $AMHSVM 
	
	
	sleep 30

	if [ $GATILHO -eq 0 ]; then
	
		notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
		30000 \
		"Desligando TARIS" "O sistema virtual do TARIS está sendo desligado, \
		por favor aguarde até todo o sistema ser desativado."
		
		printf "\n$DATA Desligamento da máquina virtual pelo script de \
		manutenção\n" >> /tiop/Logs/vmlog.txt
	
		# Desliga a máquina virtual do TARIS antes de Desligar o Computador
		VBoxManage controlvm $NOMEVM2 acpipowerbutton >> \
		/tiop/Logs/vmlog.txt 2>&1

		notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
		10000 \
		"Desligando computador" "Seu computador será desligado agora"
		
		printf "$DATA Desligamento do computador pelo script de \
		manutenção\n" >> /tiop/Logs/hostlog.txt
		
		sleep 3
		
		systemctl poweroff
		
	elif [ $GATILHO -eq 2 ]; then
	
		printf "$DATA Reinicialização da máquina virtual pelo script de \
		manutenção\n" >> /tiop/Logs/vmlog.txt
	
		#openbox --exit
		VBoxManage startvm $NOMEVM
		
	else

		notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
		30000 \
		"Desligando TARIS" "O sistema virtual do TARIS está sendo desligado, \
		por favor aguarde até todo o sistema ser desativado."
		
			printf "\n$DATA Desligamento da máquina virtual pelo script de \
		manutenção\n" >> /tiop/Logs/vmlog.txt
	
		# Desliga a máquina virtual do TARIS antes de Reiniciar o Computador
		VBoxManage controlvm $NOMEVM2 acpipowerbutton >> \
		/tiop/Logs/vmlog.txt 2>&1
	
		notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
		10000 \
		"Reiniciando computador" "Seu computador será reiniciado agora"
		
		printf "$DATA Reinicialização do computador pelo script de \
		manutenção\n" >> /tiop/Logs/hostlog.txt
		
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
		manutenção\n" >> /tiop/Logs/hostlog.txt
		
		systemctl poweroff
		
	elif [ $GATILHO -eq 2 ]; then
	
		printf "$DATA Inicialização da máquina virtual pelo script de \
	manutenção\n" >> /tiop/Logs/vmlog.txt
	
		#openbox --exit
		vboxmanage startvm $NOMEVM
		
	else
	
		notify-send -i /home/operador/.config/tiop/icones/exit.png -t \
		10000 \
		"Reiniciando computador" "Seu computador será reiniciado agora"
		
		printf "$DATA Reinicialização do computador pelo script de \
	manutenção\n" >> /tiop/Logs/hostlog.txt
		
		sleep 3
		
		systemctl reboot
	fi
fi
