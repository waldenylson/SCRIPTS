#!/bin/bash
###############################################################################
###############################################################################
###############################################################################
#####                                                                     #####
#####     Data: 29/08/2019         Versao 1.0                             #####
#####                                                                     #####
#####     Autor: Waldenylson Silva (TIOp - CINDACTA III)                  #####
#####            <waldenylsonwpss@fab.mil.br>                             #####
#####            <waldenylson.silva@yahoo.com.br>                         #####
#####     Descricao : script de firewall para aplicar os mesmo tipos de   #####
#####                 regras de acesso utilizadas no SAGITARIO ACC-RE.    #####
#####                                                                     #####
#####     Tipo de execucao: Manualmente e durante o processo de boot.     #####
#####                                                                     #####
###############################################################################
###############################################################################
###############################################################################

IPTABLES="/sbin/iptables"

# Interfaces de rede
    IFACE_LOOPBACK="lo"
    IFACE_INTRAER="em1"
    IFACE_X4000="ens4f0"

# Porta SSH
    PORTA_SSH="22"

# Outras Porta
    PORTA_HTTP="80"
    PORTAS_ALTAS="1024:"
    PORTA_ZABBIX="10050"

# REDE INTRAER
    IP_ADDR_INTRAER="10.80.8.83/22"
    IP_ADDR_SERVER="172.16.33.2/30"
    REDE_INTERNA_TIOP="10.80.33.32/27"


# REDE DACOM
    IP_ADDR_DACOM="172.16.4.210/24"
    REDE_INTERNA_DACOM="172.16.4.0/24"
    REDE_INTERNA_SERVERS="172.16.33.0/30"

# Servidor SISTIOP
    IP_ADDR_SISTIOP="10.80.33.37/27"
    IP_ADDR_SISTIOP_DB="10.80.33.58/27"


case "$1" in
  start)
        echo -e -n "Aplicando Regras de Firewall..."

    # Políticas Padrão
        $IPTABLES -P INPUT    DROP
        $IPTABLES -P OUTPUT   DROP
        $IPTABLES -P FORWARD  DROP

    # Libera acesso SSH a partir da VLAN3 
        $IPTABLES -A INPUT  -p tcp -s $REDE_INTERNA_TIOP --dport $PORTA_SSH -j ACCEPT
        $IPTABLES -A OUTPUT -p tcp -d $REDE_INTERNA_TIOP --sport $PORTA_SSH -j ACCEPT        
       
    # # Libera Agente Zabbix
        $IPTABLES -A INPUT  -p tcp -i $IFACE_INTRAER -s $REDE_INTERNA_TIOP --dport $PORTA_ZABBIX -j ACCEPT
        $IPTABLES -A OUTPUT -p tcp -o $IFACE_INTRAER -d $REDE_INTERNA_TIOP --sport $PORTA_ZABBIX -j ACCEPT
    
    # Libera ping da/para VLAN3
        $IPTABLES -A INPUT  -p icmp -s $REDE_INTERNA_TIOP -j ACCEPT
        $IPTABLES -A OUTPUT -p icmp -d $REDE_INTERNA_TIOP -j ACCEPT

    # Libera HTTP para Servidores SISTIOP
        $IPTABLES -A INPUT  -p tcp -i $IFACE_INTRAER -s $IP_ADDR_SISTIOP,$IP_ADDR_SISTIOP_DB -j ACCEPT
        $IPTABLES -A OUTPUT -p tcp -o $IFACE_INTRAER -d $IP_ADDR_SISTIOP,$IP_ADDR_SISTIOP_DB -j ACCEPT

    # Libera Rede DACOM
        $IPTABLES -A INPUT  -i $IFACE_DACOM -s $REDE_INTERNA_DACOM -j ACCEPT
        $IPTABLES -A OUTPUT -o $IFACE_DACOM -d $REDE_INTERNA_DACOM -j ACCEPT
    
    # Libera Rede Interna Servidores
        $IPTABLES -A INPUT  -i $IFACE_LAN_VRRP -s $REDE_INTERNA_SERVERS -j ACCEPT
        $IPTABLES -A OUTPUT -o $IFACE_LAN_VRRP -d $REDE_INTERNA_SERVERS -j ACCEPT

    # Libera Loopback
        $IPTABLES -A INPUT  -i $IFACE_LOOPBACK -j ACCEPT
        $IPTABLES -A OUTPUT -o $IFACE_LOOPBACK -j ACCEPT

    # Liberar trafego VRRP
        $IPTABLES -A INPUT -p vrrp -j ACCEPT
        $IPTABLES -A OUTPUT -p vrrp -j ACCEPT

	echo "[ OK ]"
 ;;

  stop)
        echo -e -n "Parando Regras de Firewall... "

        
        $IPTABLES -P INPUT    ACCEPT
        $IPTABLES -P OUTPUT   ACCEPT
        $IPTABLES -P FORWARD  ACCEPT
        $IPTABLES --flush
        $IPTABLES --flush -t nat 

        echo "[ OK ]"
    ;;

  restart)

    $0 stop
    sleep 1
    $0 start
    ;;
esac
