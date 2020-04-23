#!/bin/bash
#
# tiop_backup.sh - Cria um backup do banco de dados e arquivos importantes do AMHS
#
# Autor		: Diego Varejão <varejaodfav@fab.mil.br>
# Manutenção	: Diego Varejão	<varejaodfav@fab.mil.br>
#
# CINDACTA III / Divisão Técnica
# Subdivisão de tecnologia da informação
# Seção de informática operacional
# (81) 2129-8293
#
# ----------------------------------------------------------------------
# Este programa cria um backup do banco de dados e arquivos importantes
# do aplicativo AMHS e exclui os backups e arquivos anteriores com mais 
# de 6 meses.
# 
#
# Dependências:
#	* tar
#	* findutils
#
# Utilização:
#	$ sudo ./tiop_backup.sh
#
# Definição das funções:
#	* renArq()
#		Esta função renomeia os arquivos de backup que possuem espaços
# 		em sua nomenclatura e acrescente um "0" em seu lugar.
#	* backup()
#		Esta função irá gerar um backup do banco de dados e dos arquivos
#		importantes do sistema AMHS, compactando-os em um arquivo .tar,
#		com a data e hora a qual o script foi executado.
#-----------------------------------------------------------------------
#
# Histórico
#
# v042018-0.1 05-04-2018, Diego Varejão
#	- Versão inicial
# v042018-0.2 09-04-2018, Diego Varejão
#	- Acrescentado o backup do arquivo morto do AMHS
#	- Acrescentado a funcionalidade de excluir arquivos
#	  de backup com mais de 6 meses

#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
################## INÍCIO DE TESTES DE DEPENDÊNCIAS ####################
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#

# Verifica se o usuário tem privilégios para executar a aplicação
if test "$UID" -ne 0
then
	printf "	>> ERRO: É preciso permissão de root para executar esta aplicação."
	exit 1
fi
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
################### FIM DE TESTES DE DEPENDÊNCIAS ######################
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#

########################################################################
################# INÍCIO DA DECLARAÇÃO DE VARIÁVEIS ####################
########################################################################
DIA=`date +%d`
MES=`date +%B | tr [:lower:] [:upper:]`
ANO=`date +%Y`
DATA=`date +%d_%m_%Y`

BKPBD="backup_plnbd-$DATA.tar"
BKPAM="backup_plnam-$DATA.tar"

BDDIR='/tiop/ArquivosMV/AMHS/Backup/BancoDados/'
AMDIR='/tiop/ArquivosMV/AMHS/Backup/ArquivoMorto'
TBDDIR='/tiop/Backups/BancodDados'
TAMDIR='/tiop/Backups/ArquivoMorto'
TBKPSD='/tiop/Backups'
########################################################################
################## FIM DA DECLARAÇÃO DE VARIÁVEIS ######################
########################################################################

# Verifica se existe o diretório do ano e mês corrente e, caso negativo, os cria.
(cd $TBDDIR
if [ ! -d "$ANO" ]; then
	mkdir -p $ANO/$MES
else
	(cd $ANO

	if [ ! -d "$MES" ]; then
		mkdir $MES
	fi)
fi)

# Verifica se existe o diretório do ano e mês corrente e, caso negativo, os cria.
(cd $TAMDIR
if [ ! -d "$ANO" ]; then
	mkdir -p $ANO/$MES
else
	(cd $ANO

	if [ ! -d "$MES" ]; then
		mkdir $MES
	fi)
fi)

#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#
################# INÍCIO DA DECLARAÇÃO DAS FUNÇÕES #####################
#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#

function renArq() {
	(cd $BDDIR
	find . -name "* *" | while read i
	do 
		novo=`echo $i | tr ' ' '0'`
		mv "$i" $novo
	done)
}

renArq

function backup() {
	(cd $BDDIR; tar -cvf $TBDDIR/$ANO/$MES/$BKPBD $(ls $BDDIR | grep "$DATA-"))
	(cd $AMDIR; tar -cvf $TAMDIR/$ANO/$MES/$BKPAM $(ls $AMDIR | grep $(date +%Y%m%d)))

	echo "#####$DIA de $MES de $ANO#####" >> $TBKPSD/historico.txt
	echo "===> $BKPBD com $(ls $BDDIR | grep "$DATA-" | wc -l) arquivo(s):" >> $TBKPSD/historico.txt

	ls -lh $BDDIR | grep "$DATA-" | while read i
		do
			echo $i | awk '{ print $9" de "'$DIA'" de "$6" às "$8" com "$5 }' >> $TBKPSD/historico.txt
		done
	
	echo " " >> $TBKPSD/historico.txt
	echo "===> $BKPAM com $(ls $AMDIR | grep $(date +%Y%m%d) | wc -l) arquivo(s):" >> $TBKPSD/historico.txt

	ls -lh $AMDIR | grep $(date +%Y%m%d) | while read i
		do
			echo $i | awk '{ print $9" de "'$DIA'" de "$6" às "$8" com "$5 }' >> $TBKPSD/historico.txt
		done
	echo "---" >> $TBKPSD/historico.txt
}

backup

#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#
################## FIM DA DECLARAÇÃO DAS FUNÇÕES #######################
#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#

# Excluir todos os arquivos de backup superiores a 1 ano
EXCBKP=("$BDDIR" "$AMDIR" "$TBDDIR" "$TAMDIR")

for i in "${EXCBKP[@]}"
	do
		find $i -mtime +365 -exec rm -rf "{}" \;
	done