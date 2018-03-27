#cloud-config
bootcmd:
  - rm -f /etc/network/interfaces.d/50-cloud-init.cfg
  - echo "auto lo\niface lo inet loopback\n\nauto ${iface}\niface ${iface} inet static\n    address ${address}/${netmask}\n    gateway ${gateway}\n    dns-nameservers ${nameservers}" > /etc/network/interfaces.d/60-${iface}.cfg
  - ifdown ${iface}
  - ifup ${iface}
