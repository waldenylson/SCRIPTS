#!/bin/bash
#
# confrede.sh - Configura a rede da estação de trabalho
# baseada em Archlinux.
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
# Este programa exibe uma janela de configuração interativa que solicita
# informações sobre a rede para acrescentar aos arquivos de configuração
# da estação de trabalho.
#
# Dependências:
#	* privilégios avançados
#	* ipcalc
#
# Utilização:
#   $ sudo ./confirede.sh
#	$ sudo ./confirede.sh proxy
#
# Arquivos de configurações:
#	* /etc/hostname
#	* /etc/systemd/network/20-wired.network
#	* /etc/resolv.conf
#	* /etc/environment
#
# Definição das funções:
#	* Dispositivos()
#		Esta função lista os dispositivos de rede encontrados utilizando
#		o comando "ip addr show", obtendo, através de filtros, o nome do 
#		dispositivo e seu endereço MAC. Esta função ignora o dispositivo
#		de loopback (lo) referenciado como dispositivo 1.
#	* ConfiguracaoManual()
#		Esta função exibe uma janela gráfica (dialog) solicitando 
#		informações de rede ao usuário, armazena em variáveis específicas
#		e as exibe em uma tela, solicitando confirmação. Após confirmação
#		positiva a função insere as informações nos arquivos de configuração
#		e caso a confirmação seja negativa a função irá chamar a si própria
#		e recomeçar todo o processo.
#	* _DHCP()
#		Esta função insere a configuração padrão para que a estação
#		receba as informações de rede através de um servidor DHCP.
#	* Proxy()
#		Esta função exibe uma janela gráfica (dialog) solicitando informações 
#		sobre o proxy. Esta função deve ser chamada como parâmetro no script.
#--------------------------------------------------------------------
#
# Histórico:
#
# v092017-0.1 28-09-2017, Diego Varejão
#	- Versão inicial
# v092017-0.2 29-09-2017, Diego Varejão
#	- Removida a função "IPEstatico"
#	- Criada a função ConfiguracaoManual()
#	- Movido os comandos da função IPEstatico() para dentro da função 
#	  ConfiguracaoManual()
#	- Adicionada a tela de confirmação das informações inseridas pelo
#	  usuário
#	- Adicionada a função Proxy() para configuração de proxy
#	- Adicionada validação de IP nas funções
# v092017-0.3 30-09-2017, Diego Varejão
#	- Adicionado verificação de privilégios avançados
#	- Adicionado verificação do ipcalc
#	- Adicionada listagem de dependências ao cabeçalho da aplicação
#	- Adicionado verificação de espaços na porta do proxy
#	- Adicionado verificação de caracteres no hostname

#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
################## INÍCIO DE TESTES DE DEPENDÊNCIAS ####################
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#

# Verifica se o ipcalc está instalado
if (! ipcalc > /dev/null 2>&1)
then
	echo "	>> ERRO: \"ipcalc\" não detectado! Abortando."
	exit 1
fi

# Verifica se o usuário tem privilégios para executar a aplicação
if test "$UID" -ne 0
then
	echo "	>> ERRO: É preciso permissão de root para executar esta aplicação."
	exit 1
fi

#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
################### FIM DE TESTES DE DEPENDÊNCIAS ######################
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#


DTITULOS="CINDACTA III - Seção de informática operacional"
DIRCONFG="$PWD/conf"


#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#
################# INÍCIO DA DECLARAÇÃO DAS FUNÇÕES #####################
#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#

# Obtém o nome e o MAC do dispositivo de rede
function Dispositivos() 
{
	for i in $(ip a s | grep "^[2-9]" -A 1 | awk '{ print $2 $16 }') 
		do echo "$i" 
	done;
}

function ConfiguracaoManual()
{
	local MNAL=$(dialog \
					--stdout \
					--backtitle "$DTITULOS" \
					--title "Configuração manual de rede" \
					--no-cancel \
					--form " " 0 0 0 \
						"Hostname:"				1 1		""		1 25 25 30 \
						"Domínio:"				2 1		""		2 25 25 30 \
						"Endereço IP:"			3 1		""		3 25 25 30 \
						"Máscara de subrede:" 	4 1 	"" 		4 25 25 30 \
						"Gateway:" 				5 1 	"" 		5 25 25 30 \
						"DNS Primário:" 		6 1 	"" 		6 25 25 30 \
						"DNS Secundário:" 		7 1 	"" 		7 25 25 30 )

	# TODO Inserir validação de caracteres numéricos nos IPs
	local HOSTNAME=$(echo $MNAL | cut -d ' ' -f 1)
	local DOMINIOL=$(echo $MNAL | cut -d ' ' -f 2)	# Domínio local
	local ENDERECO=$(echo $MNAL | cut -d ' ' -f 3)	# Endereço IP
	local MASCREDE=$(echo $MNAL | cut -d ' ' -f 4)	# Máscara de subrede
	local EGATEWAY=$(echo $MNAL | cut -d ' ' -f 5)	# Endereço de gateway
	local DNSPRIMA=$(echo $MNAL | cut -d ' ' -f 6)	# DNS Primário
	local DNSSECUN=$(echo $MNAL | cut -d ' ' -f 7)	# DNS Secundário

#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
#################### INÍCIO DE TESTES DE VARIÁVEIS #####################
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#

	# Verifica se o hostname está em branco
	if test "$HOSTNAME" == ""
		then
			dialog \
				--backtitle "$DTITULOS" \
				--colors \
				--title "Configurações inválidas detectadas" \
				--sleep 5 \
				--infobox "O \Z1hostname não pode ficar em branco\Zn! Abortando." \
				3 70
			exit 1
	fi

	# Verifica se o hostname é válido (Se contém algum caracter que não 
	# seja letras, números, hífen ou underscore)
	if (echo "$HOSTNAME" | egrep [^[:alnum:]\\_\\-])
		then
			dialog \
				--backtitle "$DTITULOS" \
				--colors \
				--title "Configurações inválidas detectadas" \
				--sleep 5 \
				--infobox "O \Z5hostname\Zn \"\Z1$HOSTNAME\Zn\" não é válido! Abortando." \
				3 70
			exit 1
	fi

	# Verifica se o IP informado é um IP válido
	if (ipcalc "$ENDERECO" | grep "INVALID")
		then
		
			dialog \
				--backtitle "$DTITULOS" \
				--colors \
				--title "Configurações inválidas detectadas" \
				--sleep 5 \
				--infobox "O \Z5endereço IP\Zn \"\Z1$ENDERECO\Zn\" não é válido! Abortando." \
				3 70
			exit 1

		# Verifica se a máscara de subrede é válida
		elif (ipcalc "$ENDERECO/$MASCREDE" | grep "INVALID MASK")
			then
				dialog \
					--backtitle "$DTITULOS" \
					--colors \
					--title "Configurações inválidas detectadas" \
					--sleep 5 \
					--infobox "A \Z5máscara de subrede\Zn \"\Z1$MASCREDE\Zn\" não é válida! Abortando." \
					3 70
				exit 1

			# Verifica se o endereço de gateway é válido
			elif (ipcalc "$EGATEWAY" | grep "INVALID")
				then
					dialog \
						--backtitle "$DTITULOS" \
						--colors \
						--title "Configurações inválidas detectadas" \
						--sleep 5 \
						--infobox "O endereço \Z5gateway\Zn \"\Z1$EGATEWAY\Zn\" não é válido! Abortando." \
						3 70
					exit 1
				
				# Verifica se o endereço do DNS primário é válido
				elif (ipcalc "$DNSPRIMA" | grep "INVALID")
					then
						dialog \
							--backtitle "$DTITULOS" \
							--colors \
							--title "Configurações inválidas detectadas" \
							--sleep 5 \
							--infobox "O endereço de \Z5DNS primário\Zn \"\Z1$DNSPRIMA\Zn\" não é válido! Abortando." \
							3 70
						exit 1
				
					# Verifica se o endereço do DNS secundário é válido
					elif (ipcalc "$DNSSECUN" | grep "INVALID")
						then
							dialog \
								--backtitle "$DTITULOS" \
								--colors \
								--title "Configurações inválidas detectadas" \
								--sleep 5 \
								--infobox "O endereço de \Z5DNS secundário\Zn \"\Z1$DNSSECUN\Zn\" não é válido! Abortando." \
								3 70
							exit 1
	fi
	
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
##################### FIM DE TESTES DE VARIÁVEIS #######################
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
	
	# Máscara de subrede (CIDR)
	local MSBRCIDR=$(ipcalc $ENDERECO $MASCREDE | grep "Netmask" | awk '{ print $4 }')

	# Exibe a configuração feita pelo usuário e solicita confirmação 			 
	dialog \
		--backtitle "$DTITULOS" \
		--title 'Verifique sua configuração de rede' \
		--colors \
		--yesno "\n
Hostname													: \Z4$HOSTNAME\Zn\n
Domínio														:	\Z4$DOMINIOL\Zn\n\n
Dispositivo de rede		:	\Z4$DISPOSITIVO\Zn\n
Endereço IP										:	\Z4$ENDERECO/$MSBRCIDR\Zn\n
Gateway														:	\Z4$EGATEWAY\Zn\n\n
DNS Primário									: \Z4$DNSPRIMA\Zn\n\
DNS Secundário							: \Z4$DNSSECUN\Zn\n\n

					\Z4Estas informações estão corretas?\n\n" 0 0

	case $? in
		1) 
			ConfiguracaoManual 
		;;
		*) 	
			# Altera o arquivo de configuração "/etc/systemd/network/20-wired.network"
			# com a configuração de rede manual informada pelo usuário.
			echo "[Match]"						>  $DIRCONFG/20-wired.network
			echo "Name=$DISPOSITIVO" 			>> $DIRCONFG/20-wired.network
			echo " "							>> $DIRCONFG/20-wired.network
			echo "[Network]" 					>> $DIRCONFG/20-wired.network
			echo "Address=$ENDERECO/$MSBRCIDR"	>> $DIRCONFG/20-wired.network
			echo "Gateway=$EGATEWAY"			>> $DIRCONFG/20-wired.network
		
			# Altera o arquivo de configuração "/etc/resolv.conf" com as configurações
			# de rede manual informada pelo usuário.
			echo "domain $DOMINIOL"				>  $DIRCONFG/resolv.conf
			echo "search $DOMINIOL"				>> $DIRCONFG/resolv.conf
			echo "nameserver $DNSPRIMA"			>> $DIRCONFG/resolv.conf
			echo "nameserver $DNSSECUN"			>> $DIRCONFG/resolv.conf
			
			# Insere o nome da máquina
			echo "$HOSTNAME"					> $DIRCONFG/hostname
		;;
	esac
}

function _DHCP()
{
	echo "[Match]"				>  $DIRCONFG/20-wired.network
	echo "Name=$DISPOSITIVO" 	>> $DIRCONFG/20-wired.network
	echo " "					>> $DIRCONFG/20-wired.network
	echo "[Network]" 			>> $DIRCONFG/20-wired.network
	echo "DHCP=ipv4"			>> $DIRCONFG/20-wired.network
}

function Proxy()
{
	
	local INFOPROXY=$(dialog \
						--stdout \
						--backtitle "$DTITULOS" \
						--title "Configuração de proxy" \
						--no-cancel \
						--form " " 0 0 0 \
							"Endereço:"				1 1		""		1 25 25 30 \
							"Porta:"				2 1		""		2 25 25 30 )

	# Verifica se foram passadas informações
	if test "$INFOPROXY" != ""
	then
		local PROXY="$(echo $INFOPROXY | cut -d ' ' -f 1)"
		local PORTA="$(echo $INFOPROXY | cut -d ' ' -f 2)"
		
		# Verifica se o IP informado é um IP válido
		if (ipcalc "$PROXY" | grep "INVALID")
		then
			dialog \
				--backtitle "$DTITULOS" \
				--colors \
				--title "Configurações inválidas detectadas" \
				--sleep 5 \
				--infobox "O \Z5endereço IP\Zn \"\Z1$PROXY\Zn\" não é válido! Abortando" \
				3 70
			exit 1
		
		# Verifica se a porta informada é uma porta válida
		elif (echo "$PORTA" | grep [[:punct:][:alpha:][:space:]])
		then
			dialog \
				--backtitle "$DTITULOS" \
				--colors \
				--title "Configurações inválidas detectadas" \
				--sleep 5 \
				--infobox "A \Z5porta\Zn \"\Z1$PORTA\Zn\" não é válida! Abortando" \
				3 70
			exit 1

		else
			local PROXY="$(echo $INFOPROXY | cut -d ' ' -f 1):$(echo $INFOPROXY | cut -d ' ' -f 2)"
		fi
	else
		local PROXY="10.80.11.13:8080"
	fi

	# Adiciona as entradas no arquivo "/etc/environment"
	echo "export ftp_proxy=http://$PROXY" 								>  $DIRCONFG/environment
	echo "export http_proxy=http://$PROXY" 								>> $DIRCONFG/environment
	echo "export https_proxy=http://$PROXY" 							>> $DIRCONFG/environment
	echo "export rsync_proxy=$PROXY"									>> $DIRCONFG/environment
	echo "export no_proxy=\"localhost,127.0.0.1,.intraer,10.0.0.0/8\"" 	>> $DIRCONFG/environment
	
	cat $DIRCONFG/environment		> /mnt/etc/environment
}

#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#
################## FIM DA DECLARAÇÃO DAS FUNÇÕES #######################
#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#

# Verifica se foi passado o parâmetro "proxy" para o script e decide qual
# tela chamar

case $1 in
	proxy)
		Proxy
	;;
	*)
	
		# Exibe uma janela de seleção com duas opções de configuração de rede
		# e armazena um valor numérico (0 manual, 1 DHCP) na variável "DHCP".
		#
		# A opção "Configuração manual" (0) é a escolha padrão.
		DHCP=$(dialog \
				--stdout \
				--backtitle "$DTITULOS" \
				--title "Ativar/Desativar DHCP" \
				--radiolist "Como deseja configurar a rede desta estação?" 0 0 0 \
					"1" "Configuração automática" OFF \
					"0" "Configuração manual" ON )
	
		# Exibe os dispositivos de rede encontrados pela função "Dispositivos"
		# e solicita ao usuário que selecione o qual deseja configurar
		DISPOSITIVO=$(dialog \
						--stdout \
						--backtitle "$DTITULOS"  \
						--title "Selecione um dispositivo de rede"  \
						--menu " 	"  0 0 0 \
							$(Dispositivos) | cut -d ':' -f 1)

		if test $DHCP -eq 1
		then
			_DHCP
			
			cat $DIRCONFG/20-wired.network	> /mnt/etc/systemd/network/20-wired.network
			cat $DIRCONFG/resolv.conf		> /mnt/etc/resolv.conf
		else
			ConfiguracaoManual
			
			cat $DIRCONFG/20-wired.network	> /mnt/etc/systemd/network/20-wired.network
			cat $DIRCONFG/resolv.conf		> /mnt/etc/resolv.conf
			cat $DIRCONFG/hostname			> /mnt/etc/hostname
			
		fi
	;;
esac 
