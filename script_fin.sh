#!/bin/bash

# Pesquisa apenas dígitos:
# grep -Eo '\<[[:digit:]]{1,2}(\,\<[[:digit:]]{1,2}\>)'

# Cores
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

NC="\e[m"               # Color Reset

BANCEN="http://conteudo.bcb.gov.br/api/feed/pt-br/PAINEL_INDICADORES"
CETIP="https://www.cetip.com.br"

# TAXA DI
TXDI=`wget $CETIP -q -O - | grep "TaxDI" | cut -d '>' -f 3 | cut -d '%' -f 1 | head -1`
DTDI=`wget $CETIP -q -O - | grep -Eo '\<[[:digit:]]{1,2}(\/\<[[:digit:]]{1,2}\>\/[[:digit:]]{4})' | head -1`

# TAXA SELIC
DTSELIC=`wget $BANCEN/juros -q -O - | grep -Eo '\<[[:digit:]]{1,2}\/\<[[:digit:]]{1,2}\>\/[[:digit:]]{4}' | tail -1`
SELIC=`wget $BANCEN/juros -q -O - | grep "Diária" | awk '{ print $8 }' | cut -d ';' -f2 | cut -d '&' -f 1`

# Poupança
POUP=`wget $BANCEN/poupanca -q -O - | grep "value" | awk '{ print $4 }' | cut -d ';' -f 2 | cut -d '&' -f 1`

# Inflação
IPCA=`wget $BANCEN/inflacao -q -O - | grep IPCA | awk '{ print $11 }' | cut -d ';' -f 2 | cut -d '&' -f 1`

echo -e "$BWhite Taxa DI:	$Green $TXDI%		$Cyan[Cotação de $DTDI]$NC"
echo -e "$BWhite SELIC:		$Green $SELIC%		$Cyan[Cotação de $DTSELIC]$NC"
echo -e "$BWhite Poupança:	$Green $POUP%$NC"
echo -e "$BWhite Inflação:	$Green $IPCA%		$Cyan[Período de 12 meses]$NC"
