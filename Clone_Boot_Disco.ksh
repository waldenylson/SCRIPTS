#!/bin/ksh
######################################################################################
######################################################################################
####                                                                               ###
####  Empresa   : CTCEA - Orgnizacao Brasileira para o Desenvolvimento Cientifico  ###
####                      e Tecnologico para o Controle do Espaco Aereo.           ###
####  Setor    : Coord. Tecnologia (Resp. Cel Antonio Marcos)                      ###
####                                                                               ###
####  Nome      : Clone_Boot_Disco.ksh                                             ###
####  Autor     : Sergio G / Haryson M  / Melo R                                   ###
####  Versao    : 1.1                                                              ###
####  Data      : 06/01/2011                                                       ###
####  Descricao : Este script tem por objetivo automatizar o processo de clone de  ###
####              disco do SUN SOLARIS Versao 10 (pode ser utilizados para outras  ###
####              versoes)                                                         ###
####                                                                               ###
######################################################################################
######################################################################################
# script assume:
# c1t0d0 - origem
# c1t1d0 - destino
# chamada do comando: ./Clone_Disco.ksh 0 1
prtvtoc /dev/rdsk/c1t$1d0s2 |fmthard -s - /dev/rdsk/c1t$2d0s2
prtvtoc /dev/rdsk/c1t$1d0s2 | awk '!/\*/{print $1}' > arq.txt
grep -v "^2" arq.txt > arq1.txt
mv arq1.txt arq.txt
for clt in `cat arq.txt`
do
echo "Esse file System ja esta pronto"
newfs /dev/rdsk/c1t$2d0s$clt < /dev/null
mount /dev/dsk/c1t$2d0s$clt /mnt
cd /mnt
pwd
ufsdump 0uf - /dev/dsk/c1t$1d0s$clt | ufsrestore rf -
cd /
umount /mnt
done
installboot /usr/platform/`uname -i`/lib/fs/ufs/bootblk /dev/rdsk/c1t$2d0s0
echo "Clone realizado e Boot do sistema instalado - Favor desligar o sistema"
