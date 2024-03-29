#!/bin/bash
# A script to set up the EVPN of the top router (spine) in P3

# Start FRR
/usr/lib/frr/docker-start &

# Wait for services
sleep 5

# Write conf file
cat << EOF > /vtysh.conf
hostname router_cclaude-1
no ipv6 forwarding
!
interface eth0
 ip address 10.1.1.1/30
!
interface eth1
 ip address 10.1.1.5/30
!
interface eth2
 ip address 10.1.1.9/30
!
interface lo
 ip address 1.1.1.1/32
!
router bgp 1
 neighbor ibgp peer-group
 neighbor ibgp remote-as 1
 neighbor ibgp update-source lo
 bgp listen range 1.1.1.0/29 peer-group ibgp
 !
 address-family l2vpn evpn
  neighbor ibgp activate
  neighbor ibgp route-reflector-client
 exit-address-family
!
router ospf
 network 0.0.0.0/0 area 0
!
line vty
!
EOF

# Configure vtysh
vtysh -f /vtysh.conf

# Keep running
tail -f /dev/null
