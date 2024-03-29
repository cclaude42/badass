#!/bin/bash
# A script to set up the EVPN of the middle routers (top-rack) in P3

if [ $# -eq 0 ]; then
    echo "No arguments supplied"
    exit
fi

if [ $1 = "2" ]; then
    N=2
    SUB=2
elif [ $1 = "3" ]; then
    N=3
    SUB=6
elif [ $1 = "4" ]; then
    N=4
    SUB=10
else
    exit
fi

# Start FRR
/usr/lib/frr/docker-start &

# Create bridge
ip link add br0 type bridge
ip link set dev br0 up

# Create VXLAN
ip link add vxlan10 type vxlan id 10 dstport 4789
ip addr add 20.1.1.$LOCAL/24 dev vxlan10

# Add to bridge
brctl addif br0 eth1
brctl addif br0 vxlan10

# Up bridge
ip link set dev vxlan10 up

# Wait for services
sleep 5

# Write conf file
cat << EOF > /vtysh.conf
hostname router_cclaude-$N
no ipv6 forwarding
!
interface eth0
 ip address 10.1.1.$SUB/30
 ip ospf area 0
!
interface lo
 ip address 1.1.1.$N/32
 ip ospf area 0
!
router bgp 1
 neighbor 1.1.1.1 remote-as 1
 neighbor 1.1.1.1 update-source lo
 !
 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
  advertise-all-vni
 exit-address-family
!
router ospf
!
EOF

# Configure vtysh
vtysh -f /vtysh.conf

# Keep running
tail -f /dev/null