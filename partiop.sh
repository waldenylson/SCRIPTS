#!/bin/bash
#
# partiop.sh - Particiona e instala a estação de trabalho Archlinux
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
# Este programa cria uma tabela de partições GPT nova, cria duas partições,
# uma EFI System e outra Linux LVM, particiona o disco com LVM, formata em
# XFS, monta as partições e descompacta o sistema Archlinux pré-instalado
# na estação de trabalho.
#
# Dependências:
#	* util-linux
#	* lvm2
#	* gptfdisk
#
# Utilização:
#	$ sudo ./partiop.sh gpt
#	$ sudo ./partiop.sh instalar
#
# Os arquivos de configuração alterados serão os seguintes:
#	* /etc/fstab
#	* /boot/loader/entries/sistema.conf
#
# Layout do particionamento GPT:
#	Partição	S. Arquivos		Label	P. montagem		T. Partição		Tamanho
#		1			vfat		BOOT	   /boot		EFI System		150MB
#		2		LVM2_Member		  -			 -			Linux LVM		Restante
#
# Layout do particionamento LVM:
#	Grupo		Partição	S. Arquivos		P. montagem		Tamanho
#	SISTEMA		  SWAP			swap		   [SWAP]		6GB
#	SISTEMA		  ROOT			xfs			    /			12GB
#	SISTEMA		  VARS			xfs				/var		3GB
#	SISTEMA		  TIOP			xfs				/tiop		1GB
#	SISTEMA		  HOME			xfs				/home		Restante
#
# Definição das funções:
#	* Discos()
#		Esta função lista os discos encontrados no sistema utilizando o
# 		comando "lsblk -r --output=NAME,SIZE", obtendo, através de filtros,
#		o nome disco e sua capacidade. Esta função ignora o disco "sr0".
#	* CriarGPT()
#		Esta função irá exibir uma tela gráfica que lista o nome e a
#		capacidade dos discos encontrados no sistema. O usuário deverá
#		escolher qual disco será utilizado no particionamento. Após a
#		escolha do disco a função irá zerar as assinaturas de partições
#		antigas com o comando "wipefs -a -f" para que seja possível
#		trabalhar nelas. Em seguida é criada uma nova tabela de partições
#		do tipo GPT com o comando "fdisk" e a máquina é reinicializada
#		para aplicar as configurações feitas anteriormente.
#	* Particionar()
#		Esta função irá particionar o disco com o comando "fdisk", criando
#		2 partições, uma do tipo EFI System e outra do tipo Linux LVM.
#		Logo em seguida é exibido o layout do disco com o comando "lsblk".
#	* CriarLVM()
#		Esta função irá criar um volume físico LVM, um grupo de volumes LVM
#		chamado "SISTEMA", e os volumes lógicos LVM (SWAP, ROOT, TIOP, VARS
#		e HOME) utilizando os comandos do utilitário LVM2 "pvcreate", "vgcreate"
#		e "lvcreate".
#	* Formatar()
#		Esta função irá formatar a partição EFI System como FAT32 (vfat)
#		e os demais volumes lógicos LVM como xfs.
#	* Montar()
#		Esta função irá montar a partição EFI System e os demais volumes
#		lógicos em seus respectivos diretórios, no layout especificado
#		neste cabeçalho, para que o sistema possa ser descompactado.
#	* Instalar()
#		Esta função irá chamar as funções Particionar(), CriarLVM(), 
#		Formatar() e Montar(). Em seguida ela irá descompactar o sistema
#		no diretório /mnt, o qual já deverá estar montado com o volume
#		lógico LVM "ROOT" e todos os outros volumes lógicos com o layout
#		especificado neste cabeçalho, será gerado um novo arquivo /etc/fstab
#		com o comando "genfstab -U /mnt" com as UUIDS das novas partições
#		e volumes lógicos e, por fim, irá instalar o carregador de boot
#		syslinux para que seja possível inicializar o sistema em computadores
#		que suportem BIOS Legacy e também gerado o arquivo de configuração
#		de boot em "/boot/loader/entries/sistema.conf" para computadores
#		que suportem inicialização via UEFI. Após esses procedimentos
#		a função irá reinicializar a máquina.
#-----------------------------------------------------------------------
#
# Histórico
#
# v102017-0.1 16-10-2017, Diego Varejão
#	- Versão inicial
# v102017-0.2 17-10-2017, Diego Varejão
#	- Retirado a parte de configuração de rede da aplicação e colocada
#	  em uma aplicação à parte;
#	- Retirado a parte de configuração adicional e colocada em uma
#	  aplicação à parte;
#	- Retiradas variáveis inúteis e alterada a forma como a aplicação
#	  se comporta;
#	- Retiradas as diversas opções de chamada da aplicação e mantido
#	  apenas "gpt" e "instalar" como parâmetros.

set -e

# Cor do texto
txtund=$(tput sgr 0 1)    # Underline
txtbld=$(tput bold)       # Negrito
txtred=$(tput setaf 1)    # Vermelho
txtgrn=$(tput setaf 2)    # Verde
txtylw=$(tput setaf 3)    # Amarelo
txtblu=$(tput setaf 4)    # Azul
txtpur=$(tput setaf 5)    # Púrpura
txtcyn=$(tput setaf 6)    # Ciano
txtwht=$(tput setaf 7)    # Branco
txtrst=$(tput sgr0)       # Cor padrão

#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
################## INÍCIO DE TESTES DE DEPENDÊNCIAS ####################
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#

# Verifica se o usuário tem privilégios para executar a aplicação
if test "$UID" -ne 0
then
	printf "	>> ERRO: É preciso permissão de ${txtbld}${txtred}root${txtrst} para executar esta aplicação."
	exit 1
fi

DEP=("lvm2" "util-linux" "gptfdisk")

# Verifica se as dependências foram satisfeitas
for i in ${!DEP[*]}
do
	if (! pacman -Qen | grep "${DEP[$i]}" > /dev/null 2>&1)
	then
		printf "	>> ERRO: Dependência ${txtbld}${txtwht}\"${DEP[$i]}\"${txtrst} não detectado! Abortando."
	exit 1
	fi
done;

#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
################### FIM DE TESTES DE DEPENDÊNCIAS ######################
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#

########################################################################
################# INÍCIO DA DECLARAÇÃO DE VARIÁVEIS ####################
########################################################################

DTITULOS="CINDACTA III - Seção de informática operacional (TIOp)"

########################################################################
################# FIM DA DECLARAÇÃO DE VARIÁVEIS #######################
########################################################################

#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#
################# INÍCIO DA DECLARAÇÃO DAS FUNÇÕES #####################
#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#

function Discos()
{
	# Obtém o nome e a capacidade dos discos
	for i in $(lsblk -r --output=NAME,SIZE | grep -v "^...[0-9A-Z]" | grep -v "sr0")
		do echo "$i"
	done;
}

function CriarGPT()
{
	# Seleciona o disco que será particionado
	local DISCO=$(dialog 	--stdout \
							--backtitle "$DTITULOS [Particionamento]"  \
							--title "Selecionar disco"  \
							--menu " 	"  0 0 0 \
							$(Discos))

	# Removendo qualquer assinatura de partições passadas				
	for i in $(lsblk -r --output=NAME | grep "^$DISCO")
	do
		printf "Removendo assinaturas de partições antigas em $i\t..."
		wipefs -a -f /dev/$i > /dev/null 2>&1 && printf "%44s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%43s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	done;
	
	# Cria a tabela de partições 
	echo "Criando uma nova tabela GPT..."
	sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$DISCO 
g		#Cria uma nova tabela de partições GPT
y		#Aceita sobrescrever a tabela de partições atual
		#Confirma a ação anterior
w		#Salva e sai
y		#Aceita modificações
		#Confirma ação anterior
EOF
	# Reiniciar o computador para que o sistema possa ler a nova tabela de partições corretamente
	echo "O sistema será reiniciado em 3 segundos para a releitura da tabela de partições..."
	
	sleep 3
	
	systemctl reboot
}
function Particionar()
{
	printf "${txtbld}${txtwht}Iniciando etapa 1 (${txtblu}Criando partições \"EFI System\" e \"Linux LVM\"${txtwht})${txtrst}\n"
	
	sleep 2
	
	# Seleciona o disco que será particionado
	local DISCO=$(dialog 	--stdout \
							--backtitle "$DTITULOS [Particionamento]"  \
							--title "Selecionar disco"  \
							--menu " 	"  0 0 0 \
							$(Discos))
	
	# Cria a tabela de partições 
	echo "Criando partições \"EFI System\" e \"Linux LVM\"..."
	sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$DISCO
n		#Cria uma nova partição
		#Confirma a ação anterior
		#Aceita configuração padrão
+150M	#Define o tamanho da partição para 150M (Partição /boot)
n		#Cria uma nova partição
		#Aceita o número de partição padrão
		#Aceita a opção padrão 
		#Aceita o tamanho padrão (todo o restante do disco)
t		#Muda o tipo da partição
1		#Seleciona partição 1
1		#Seleciona o tipo de partição como "EFI System"
t		#Muda o tipo da partição
2		#Seleciona a partição 2
31		#Seleciona o tipo de partição como "Linux LVM"
w		#Salva e sai do particionador
		#Confirma a ação anterior
EOF

	lsblk
}
function CriarLVM()
{
	printf "${txtbld}${txtwht}Iniciando etapa 2 (${txtblu}Criando volumes LVM${txtwht})${txtrst}\n"
	
	# Seleciona o disco que será particionado
	local DISCO=$(dialog 	--stdout \
							--backtitle "$DTITULOS [Particionamento]"  \
							--title "Selecionar disco"  \
							--menu " 	"  0 0 0 \
							$(Discos))
							
	# Cria um volume físico LVM
	printf "Criando volume físico em /dev/${DISCO}2..."
	pvcreate /dev/${DISCO}2 > /dev/null 2>&1 && printf "%65s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%65s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	# Cria um grupo de volumes LVM
	printf "Criando grupo de volume \"SISTEMA\" em /dev/${DISCO}2..."
	vgcreate SISTEMA /dev/${DISCO}2 > /dev/null 2>&1 && printf "%52s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%52s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	# Cria o volume lógico SWAP
	printf "Criando volume lógico SWAP..."
	lvcreate -L 6144M SISTEMA -n SWAP -W y -y > /dev/null 2>&1 && printf "%73s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%73s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	# Cria o volume lógico ROOT
	printf "Criando volume lógico ROOT..."
	lvcreate -L 12288M SISTEMA -n ROOT -W y -y > /dev/null 2>&1 && printf "%73s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%73s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	# Cria o volume lógico VAR
	printf "Criando volume lógico VARS..."
	lvcreate -L 3072M SISTEMA -n VARS -W y -y > /dev/null 2>&1 && printf "%73s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%73s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	# Cria o volume lógico TIOP
	printf "Criando volume lógico TIOP..."
	lvcreate -L 10240M SISTEMA -n TIOP -W y -y > /dev/null 2>&1 && printf "%73s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%73s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	# Cria o volume lógico HOME
	printf "Criando volume lógico HOME..."
	lvcreate -l 100%FREE SISTEMA -n HOME -W y -y > /dev/null 2>&1 && printf "%73s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%73s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
}
function Formatar()
{
	local BOOT=$(lsblk -r | grep "150M" | awk '{ print $1 }')

	printf "${txtbld}${txtwht}Iniciando etapa 3 (${txtblu}Formatando partições${txtwht})${txtrst}\n"
	
	# Formata as partições do sistema
	printf "Formatando partição /dev/$BOOT..."
	mkfs.vfat -F 32 /dev/$BOOT -n BOOT > /dev/null 2>&1 && printf "%70s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%70s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	printf "Formatando partição /dev/SISTEMA/ROOT..."
	mkfs.xfs -f /dev/SISTEMA/ROOT > /dev/null 2>&1 && printf "%62s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%62s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	printf "Formatando partição /dev/SISTEMA/HOME..."
	mkfs.xfs -f /dev/SISTEMA/HOME > /dev/null 2>&1 && printf "%62s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%62s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	printf "Formatando partição /dev/SISTEMA/VARS..."
	mkfs.xfs -f /dev/SISTEMA/VARS > /dev/null 2>&1 && printf "%62s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%62s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	printf "Formatando partição /dev/SISTEMA/TIOP..."
	mkfs.xfs -f /dev/SISTEMA/TIOP > /dev/null 2>&1 && printf "%62s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%62s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	printf "Formatando partição /dev/SISTEMA/SWAP..."
	mkswap /dev/SISTEMA/SWAP 2> /dev/null 2>&1 && printf "%62s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%62s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
}
function Montar()
{
	printf "${txtbld}${txtwht}Iniciando etapa 4 (${txtblu}Montando partições${txtwht})${txtrst}\n"
	# Diretórios onde serão montadas as partições
	local DIRS=("home" "boot" "var" "tiop")
	
	# Partição destinada ao diretório /boot
	local BOOT=$(lsblk -r | grep "150M" | awk '{ print $1 }')
	
	# Monta a partição raiz
	printf "Montando partição /dev/SISTEMA/ROOT em /mnt..."
	mount /dev/SISTEMA/ROOT /mnt 2> /dev/null && printf "%56s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%56s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	
	# Entra na nova raiz
	cd /mnt
	
	# Verifica se os diretórios existem, caso contrário os cria
	for i in ${!DIRS[*]}
	do
		[ -d "${DIRS[$i]}" ] && printf "Criando diretório /${DIRS[$i]}\t... %74s[${txtylw}  IGNOR  ${txtrst}]\t- ${txtred}Já existe!${txtrst}\n" || (mkdir ${DIRS[$i]} && printf "Criando diretório /${DIRS[$i]}\t... %74s[${txtgrn}  FEITO  ${txtrst}]\n")
	done;	

	# Monta as partições restantes
	printf "Montando partição /dev/$BOOT em /mnt/boot..."
	mount /dev/$BOOT /mnt/boot 2> /dev/null && printf "%59s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%59s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	printf "Montando partição /dev/SISTEMA/VARS em /mnt/var..."
	mount /dev/SISTEMA/VARS /mnt/var 2> /dev/null && printf "%52s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%52s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	printf "Montando partição /dev/SISTEMA/HOME em /mnt/home..."
	mount /dev/SISTEMA/HOME /mnt/home 2> /dev/null && printf "%51s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%51s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	printf "Montando partição /dev/SISTEMA/TIOP em /mnt/tiop..."
	mount /dev/SISTEMA/TIOP /mnt/tiop 2> /dev/null && printf "%51s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%51s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	printf "Ativando partição swap..."
	swapon /dev/SISTEMA/SWAP 2> /dev/null && printf "%77s[${txtgrn}  FEITO  ${txtrst}]\n" || (printf "%77s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
}
function Instalar()
{
	Particionar
	
	clear
	
	CriarLVM
	Formatar
	Montar
	
	printf "${txtbld}${txtwht}Iniciando etapa 5 (${txtblu}Descompactando sistema operacional${txtwht})${txtrst}\n"
	
	printf "Descompactando sistema em /mnt..."
	
	sleep 3
	
	# Descompacta o sistema na nova raiz
	tar -vxjpf /root/TIOP-SISARCH.tar.bz2 -C /mnt --xattrs --numeric-owner || (printf "%69s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	
	clear
	
	printf "${txtbld}${txtwht}Iniciando etapa 6 (${txtblu}Configurando${txtwht})${txtrst}\n"
	
	printf "Gerando um novo fstab..."
	# Gera um novo arquivo "/etc/fstab" no novo sistema
	(genfstab -U /mnt > /mnt/etc/fstab) 2> /dev/null && printf "%78s[${txtgrn}  FEITO ${txtrst}]\n" || (printf "%78s[${txtred}  FALHA  ${txtrst}]\n" && exit 1)
	
	echo "Criando arquivo de configuração de boot..."
	local UUID=$(blkid | grep SISTEMA-ROOT | cut -d '"' -f 2)
	
	# Adiciona as estradas do arquivo de configuração de boot UEFI
	echo "title	Inicializar Archlinux (TIOp)" 		> /mnt/boot/loader/entries/sistema.conf
	echo "linux	vmlinuz-linux" 						>> /mnt/boot/loader/entries/sistema.conf
	echo "initrd	initramfs-linux.img" 			>> /mnt/boot/loader/entries/sistema.conf
	echo "options	root=UUID=$UUID	rw" 			>> /mnt/boot/loader/entries/sistema.conf

	# Instala o syslinux para boot via Legacy BIOS
	syslinux-install_update -i -m -c /mnt/
	
	# Reinicia o sistema
	echo "O computador será reiniciado em 3 segundos..."
	
	sleep 3
	
	systemctl reboot
}

#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#
################## FIM DA DECLARAÇÃO DAS FUNÇÕES #######################
#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#

case $1 in
	gpt) CriarGPT
	;;
	instalar) Instalar
	;;
	*) echo -e "Utilização:\n $ sudo ./partiop.sh gpt	# Cria uma nova tabela de partições do tipo GPT\n $ sudo ./partiop.sh instalar	# Instala o sistema operacional (deve ser executado após o \"partiop.sh gpt\")"
	;;
esac
