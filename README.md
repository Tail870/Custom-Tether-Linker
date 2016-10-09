# Custom-Tether-Linker
Read the README!

This program are used to share ethernet-inteface (RJ-45) to wi-fi via a terminal command:

su proc/sys/net/ipv4/ip_forward iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

where eth0 - interface to be shared.
