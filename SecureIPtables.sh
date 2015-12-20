#!/bin/sh

####################################################################
# Copyright 2014 Samuel Christison, May be adapted freely.         #
# Please don't remove this notice                                  #
# This script will stop most; port scanning attempts, UDP Floods,  #
# SYN Floods, TCP Floods, Handshake Exploits, XMAS Packets,        #
# Smurf Attacks, ICMP Bombs, LAND attacks and RST Floods.          #
# You need to give this script Root privileges Before you run it.  #
# sudo chmod 777 SecureWS.sh                                       #
# sudo chmod +x SecureWS.sh                                       #
#################################################################################################
# This script by default will leave open ports 80, 25, 53, 443, 22.                             #
#################################################################################################
#Ports for your services, You can change these before running the script.

WEB=80
MAIL=25
DNS=53
SSL=443
SSH=22
LB=8888
TCPBurstNew=200
TCPBurstEst=50

###############################################################################
#TCPBurstNew is how many packets a new connection can send in 1 request       #
#TCPBurstEst is how many packets an existing connection can send in 1 request.#
###############################################################################

#########################################################
#You don't need to change anything below this line               #
#########################################################

echo "The setup is planning on configuring IPTables on your behalf"
echo "The following ports are being set up"
echo "Your SSH Port will be: $SSH"
echo "Your DNS Port will be: $DNS"
echo "Your SSL Port will be: $SSL"
echo "Your MAIL Services SMTP Port will be: $MAIL"
echo "Your WEB SERVER port will be: $WEB"
echo "If these are not correct, Please press Ctrl + C NOW"
echo "The installer will continue in 5"
sleep 1
echo "The installer will continue in 4"
sleep 1
echo "The installer will continue in 3"
sleep 1
echo "The installer will continue in 2"
sleep 1
echo "The installer will continue in 1"
sleep 1
echo "The installer will now RUN to completion"
sleep 1
echo "Lets start by Flushing your old Rules."
sleep 0.1

sudo iptables -F

echo "Done"
sleep 0.1
echo "We need to create the Default rule and Accept LoopBack Input."
sleep 0.1

sudo iptables -A INPUT -i lo -p all -j ACCEPT

echo "Enabling the 3 Way Hand Shake and limiting TCP Requests."
echo "Note if you have cloud flare the limit needs to be rather high or you need to make a set of separate rules for their IP range."
sleep 2

sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport $WEB -m state --state NEW -m limit --limit 50/minute --limit-burst $TCPBurstNew -j ACCEPT
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -m limit --limit 50/second --limit-burst $TCPBurstEst -j ACCEPT

echo "Adding Protection from LAND Attacks, If these IPs look required, please stop the script and alter it."

echo "10.0.0.0/8 DROP"
sleep 1
sudo iptables -A INPUT -s 10.0.0.0/8 -j DROP
echo "169.254.0.0/16 DROP"
sleep 1
sudo iptables -A INPUT -s 169.254.0.0/16 -j DROP
echo "172.16.0.0/12 DROP"
sleep 1
sudo iptables -A INPUT -s 172.16.0.0/12 -j DROP
echo "127.0.0.0/8 DROP"
sleep 1
sudo iptables -A INPUT -s 127.0.0.0/8 -j DROP
echo "192.168.0.0/24 DROP"
sleep 1
sudo iptables -A INPUT -s 192.168.0.0/24 -j DROP
echo "224.0.0.0/4 SOURCE DROP"
sleep 1
sudo iptables -A INPUT -s 224.0.0.0/4 -j DROP
echo "224.0.0.0/4 DEST DROP"
sleep 1
sudo iptables -A INPUT -d 224.0.0.0/4 -j DROP
echo "224.0.0.0/5 SOURCE DROP"
sleep 1
sudo iptables -A INPUT -s 240.0.0.0/5 -j DROP
echo "224.0.0.0/5 DEST DROP"
sleep 1
sudo iptables -A INPUT -d 240.0.0.0/5 -j DROP
echo "0.0.0.0/8 SOURCE DROP"
sleep 1
sudo iptables -A INPUT -s 0.0.0.0/8 -j DROP
echo "0.0.0.0/8 DEST DROP"
sleep 1
sudo iptables -A INPUT -d 0.0.0.0/8 -j DROP
echo "239.255.255.0/24 DROP SUBNETS"
sleep 1
sudo iptables -A INPUT -d 239.255.255.0/24 -j DROP
echo "255.255.255.255 DROP SUBNETS"
sleep 1
sudo iptables -A INPUT -d 255.255.255.255 -j DROP

echo "Lets stop ICMP SMURF Attacks at the Door."

sudo iptables -A INPUT -p icmp -m icmp --icmp-type address-mask-request -j DROP
sudo iptables -A INPUT -p icmp -m icmp --icmp-type timestamp-request -j DROP
sudo iptables -A INPUT -p icmp -m icmp --icmp-type 0 -m limit --limit 1/second -j ACCEPT

sleep 1
echo "Done!"
echo "Next were going to drop all INVALID packets\."

sudo iptables -A INPUT -m state --state INVALID -j DROP
sudo iptables -A FORWARD -m state --state INVALID -j DROP
sudo iptables -A OUTPUT -m state --state INVALID -j DROP

sleep 1
echo "Done!"
echo "Next we drop Valid but incomplete packets."

sudo iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP 
sudo iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN FIN,SYN -j DROP 
sudo iptables -A INPUT -p tcp -m tcp --tcp-flags SYN,RST SYN,RST -j DROP 
sudo iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,RST FIN,RST -j DROP 
sudo iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,ACK FIN -j DROP 
sudo iptables -A INPUT -p tcp -m tcp --tcp-flags ACK,URG URG -j DROP

sleep 1
echo "Done!"
echo "Now we enable RST Flood Protection MORE SMURF PROTECTION"

sudo iptables -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT

sleep 1
echo "Done!"
echo "Protection from Port Scans."
echo "Attacking IP will be locked for 24 hours (3600 x 24 = 86400 Seconds)"
sleep 1

sudo iptables -A INPUT -m recent --name portscan --rcheck --seconds 86400 -j DROP
sudo iptables -A FORWARD -m recent --name portscan --rcheck --seconds 86400 -j DROP

echo "Adjusting..."
echo "Banned IP addresses are removed from the list every 24 Hours."

sudo iptables -A INPUT -m recent --name portscan --remove
sudo iptables -A FORWARD -m recent --name portscan --remove

sleep 1
echo "Done!"
echo "Creating rules to add scanners to the PortScanner list and log the attempt. Remember to set up QUOTA"

sudo iptables -A INPUT -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "portscan:"
sudo iptables -A INPUT -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP

sudo iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "portscan:"
sudo iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP

sleep 1
echo "Done!"
echo "Lets block all incoming PINGS, Although they should be blocked already"

sudo iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j REJECT

sleep 1
echo "Done!"
echo "Allow the following ports through from outside"

echo "SMTP Port $MAIL"
sudo iptables -A INPUT -p tcp -m tcp --dport $MAIL -j ACCEPT

sleep 0.1
echo "Done!"

echo "Web Port $WEB"
sudo iptables -A INPUT -p tcp -m tcp --dport $WEB -j ACCEPT

sleep 0.1
echo "Done!"

echo "DNS Port $DNS"
sudo iptables -A INPUT -p udp -m udp --dport $DNS -j ACCEPT

sleep 1
echo "Done\!"

echo "SSL Port $SSL"
sudo iptables -A INPUT -p tcp -m tcp --dport $SSL -j ACCEPT

sleep 1
echo "Done!"

echo "SSH Port $SSH"
sudo iptables -A INPUT -p tcp -m tcp --dport $SSH -j ACCEPT

sleep 1
echo "Done!"

echo "LB Port $LB"
sudo iptables -A INPUT -p tcp -m tcp --dport $LB -j ACCEPT

sleep 1
echo "Done Opening Ports For Web Access!"

echo "Lastly we block ALL OTHER INPUT TRAFFIC."
sudo iptables -A INPUT -j REJECT

sleep 1
echo "Done\!"

################# Below are for OUTPUT iptables rules #############################################
echo "NOW LETS SET UP OUTPUTS"

echo "Default Rule for OUTPUT and our LoopBack Again. We wont be limiting outgoing traffic."
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

sleep 1
echo "Done!"

echo "Allow the following ports Access OUT from the INSIDE"

echo "SMTP Port $MAIL"
iptables -A OUTPUT -p tcp -m tcp --dport $MAIL -j ACCEPT

sleep 1
echo "Done!"

echo "DNS Port $DNS"
iptables -A OUTPUT -p udp -m udp --dport $DNS -j ACCEPT

sleep 1
echo "Done!"

echo "Web Port $WEB"
iptables -A OUTPUT -p tcp -m tcp --dport $WEB -j ACCEPT

sleep 1
echo "Done!"

echo "HTTPS Port $SSL"
iptables -A OUTPUT -p tcp -m tcp --dport $SSL -j ACCEPT

sleep 1
echo "Done!"

echo "SSH Port $SSH"
iptables -A OUTPUT -p tcp -m tcp --dport $SSH -j ACCEPT

sleep 1
echo "Done!"

echo "Allow Outgoing PING Type ICMP Requests"

iptables -A OUTPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT

sleep 1
echo "Done!"

echo "Lastly Reject all Output traffic"

iptables -A OUTPUT -j REJECT

sleep 1
echo "Done!"

echo "Reject Forwarding  traffic"

iptables -A FORWARD -j REJECT

sleep 1
echo "Done!"
echo "Your Webserver is now more secure then it was 5 minutes ago"
sleep 5
exit