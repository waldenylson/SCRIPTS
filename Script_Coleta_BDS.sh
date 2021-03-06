#!/bin/bash

#Criado em 09/11/2017 por Marcio Nascimento mrnascimento@atech.com.br


#***************************************************************************************************
clear
Menu(){
echo -e "*****************************************************************************************"
echo -e "*****************************************************************************************"
echo -e "*****************************************************************************************"
echo -e "**************************SCRIPT DE COLETA DE BDS ***************************************"
echo -e "*****************************************************************************************"
echo -e "*****************************************************************************************"
echo -e "*****************************************************************************************"
   echo
   echo "[ 1 ] SELECIONAR A BDS QUE DEVERA SER COPIADA"
   echo "[ 2 ] COPIAR ARQUIVO DE BDS DA PLJ PARA O PENDRIVE"
   echo "[ 3 ] COPIAR ARQUIVO DE BDS DA PLJ PARA O PENDRIVE CASO A OPCAO 03 NAO FUNCIONE"
   echo "[ 4 ] DESMONTAR O PENDRIVE PARA REMOÇÃO COM SEGURANCA"
   echo "[ 5 ] SAIR"
   echo
   echo -n "QUAL A OPCAO DESEJADA? "
   read opcao
   case $opcao in
      1) Bds01 ;;
      2) Flashdrive1 ;;
      3) Flashdrive2 ;;
      4) Desmontar1 ;;
      5) exit ;;
      *) "Opcao desconhecida." ; echo ; Principal ;;
   esac
}
Bds01() {
echo -e ""
echo -e "*****************************************************************************************"
echo -e "**************************COLETA DE BDS SAGITARIO****************************************"
echo -e "*****************************************************************************************"
echo -e ""
read -p "INSIRA O NOME DA BDS COMPLETA EM LETRAS MAIUSCULAS, Exemplo: ACCAO02: " GBDS1

DIR="/home/gbds/IMP_EXP/"

cd $DIR
ls -lrth ${GBDS1}_* 

echo -e ""
echo -e "**********************************************************"
read -p "***********PRESSIONE ENTER PARA CONTINUAR ****************"
echo -e "**********************************************************"
echo -e ""
clear
echo -e "**********************************************************"
echo -e "**********COLETANDO E COMPACTANDO OS ARQUIVOS*************"
echo -e "**********************************************************"
echo -e ""

#**************************************************************************************************
#******COPIAR ARQUIVOS SELECIONADOS RENOMEANDO E MOVENDO PARA O /TMP/ DA PLJ******

cd $DIR
tar cvf bds_${GBDS1}.tar ${GBDS1}_*

mv bds_${GBDS1}.tar /tmp/ 
cd /tmp/
gzip bds_${GBDS1}.tar



echo -e ""
echo -e "******************************************************************************"
echo -e "******************************************************************************"
echo -e "******** O ARQUIVO DE BDS FOI COPIADO PARA A PASTA /tmp/ DA PLJ00101**********" 
echo -e "******************************************************************************"
echo -e "******************************************************************************"
echo -e ""
echo -e "**********************************************************"
echo -e "*******NOME DO ARQUIVO: bds_${GBDS1}.tar.gz *******" 
echo -e "**********************************************************"
echo -e ""

echo -e "**********************************************************"
echo -e "***********PRESSIONE ENTER PARA VOLTAR AO MENU************"
read -p "**********************************************************"
echo -e ""
clear

   Menu
}


Flashdrive1() {

echo -e "********************************************************"
echo -e "********COPIA DA BDS PARA o PENDRIVE********************"
echo -e "********************************************************"
echo -e ""
echo -e "******************************************************************************************"
echo -e "******INSIRA O PENDRIVE NA PLJ E TECLE ENTER QUANDO ESTIVER PRONTO************************"
read -p "******************************************************************************************"

mount /dev/sdb1 /mnt/

echo -e "******AGUARDE ENQUANTO O ARQUIVO DE BDS E COPIADO PARA O PENDRIVE*************************"

cp /tmp/bds_${GBDS1}.tar.gz /mnt/


echo -e "******************************************************************************************"
echo -e "******FAVOR CONFIRMAR SE O ARQUIVO bds_${GBDS1}.tar.gz APARECE NA LISTAGEM ABAIXO:********"
echo -e "******************************************************************************************"

ls -lrth /mnt/bds_${GBDS1}*



echo -e "**********************************************************"
echo -e "******O ARQUIVO DE BDS FOI COPIADO PARA O PENDRIVE********"
echo -e "**********************************************************"
echo -e ""
echo -e "***************************************************************************"
echo -e "***********PRESSIONE ENTER PARA VOLTAR AO MENU*****************************"
read -p "***************************************************************************"
clear
echo -e ""
echo -e ""


Menu
}

Desmontar1() {

echo -e "********************************************************"
echo -e "********REMOVENDO O PENDRVE COM SEGURANCA***************"
echo -e "********************************************************"
echo -e "******************************************************************************************"

umount /mnt/

echo -e "**********************************************************"
echo -e "******O PENDRIVE FOI DESMONTADO COM SUCESSO********"
echo -e "**********************************************************"
echo -e ""
echo -e "***************************************************************************"
echo -e "******PRESSIONE ENTER PARA RETIRAR O PENDRIVE E VOLTAR AO MENU************"
read -p "***************************************************************************"
echo -e ""
echo -e ""
clear


Menu
}


Flashdrive2() {
echo -e "********************************************************"
echo -e "********COPIA DA BDS PARA o PENDRIVE********************"
echo -e "********************************************************"
echo -e ""
echo -e "******************************************************************************************"
echo -e "******INSIRA O PENDRIVE NA PLJ E TECLE ENTER QUANDO ESTIVER PRONTO************************"
read -p "******************************************************************************************"

mount /dev/sdc1 /mnt/

echo -e "******AGUARDE ENQUANTO O ARQUIVO DE BDS E COPIADO PARA O PENDRIVE*************************"

cp /tmp/bds_${GBDS1}.tar.gz /mnt/


echo -e "******************************************************************************************"
echo -e "******FAVOR CONFIRMAR SE O ARQUIVO bds_${GBDS1}.tar.gz APARECE NA LISTAGEM ABAIXO:********"
echo -e "******************************************************************************************"

ls -lrth /mnt/bds_${GBDS1}*



echo -e "**********************************************************"
echo -e "******O ARQUIVO DE BDS FOI COPIADO PARA O PENDRIVE********"
echo -e "**********************************************************"
echo -e ""
echo -e "***************************************************************************"
echo -e "***********PRESSIONE ENTER PARA VOLTAR AO MENU*****************************"
read -p "***************************************************************************"
clear
echo -e ""
echo -e ""

Menu
}
Menu

