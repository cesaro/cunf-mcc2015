launch_a_vm_with_qemu_or_vbox () {
	set -x
	# Change "-smp 1" to "-smp N" for allocating N cores
	KVM=$(which qemu-kvm)
	if [ "$KVM" ] ; then
		$KVM -vnc :$VNC \
			-enable-kvm\
			-smp 1\
			-cpu host \
		    -daemonize \
		    -k $KEYBOARD \
		    -m $MAXMEM \
		    -drive file=$HDD \
		    -net nic,vlan=1 -net user,vlan=1 -name MCC \
		    -redir tcp:$SSHP::22
	else
		echo "=========================================="
		echo " qemu not installed, checking VirtualBox"
		VBOX=$(which vboxmanage 2>/dev/null)
		if [ -z "$VBOX" ] ; then
			VBOX=$(which VBoxManage 2>/dev/null)
		fi
		if [ -z "$VBOX" ] ; then
			exit -1
		fi

		# I do not know how to allocae N cores with VirtualBox

		if [ -z "$($VBOX list vms | grep mcc2015)" ] ; then
			$VBOX createvm --name mcc2015 --ostype Debian_64 --register
			$VBOX modifyvm mcc2015 --memory $MAXMEM --boot1 disk
			$VBOX storagectl mcc2015 --name sata_controller --add sata
			$VBOX storageattach mcc2015 --storagectl sata_controller  --port 0 --device 0 --type hdd --medium $HDD
			$VBOX modifyvm mcc2015 --natpf1 "SSH,tcp,127.0.0.1,$SSHP,,22"
		fi
		$VBOX startvm mcc2015
	fi
}

KEYBOARD=fr
HDD=$1

# definition, si ce n'est pas une variable d'environnement, du port VNC
if [ -z "$VNC" ] ; then
	VNC="42" 
fi
# definition, si ce n'est pas une variable d'environnement, du port redirige
if [ -z "$SSHP" ] ; then
	SSHP="2222" 
fi
# definition, si ce n'est pas une variable d'environnement, du port redirige
if [ -z "$CTRLP" ] ; then
	CTRLP="1234" 
fi
# definition, si ce n'est pas une variable d'environnement, du max memoire
if [ -z "$MAXMEM" ] ; then
	MAXMEM="4096" 
fi

launch_a_vm_with_qemu_or_vbox 2> /tmp/launcher

if [ "$?" = "-1" ] ; then
	echo "=========================================="
	echo " neither qemu or Visturlabox is installed ==> VM NOT LAUNCHED"
	echo "=========================================="
	echo "errors found, see below"
	cat /tmp/launcher
	rm -f /tmp/launcher
fi

echo "Probing ssh"
while true ; do
  echo "Waiting ssh to respond"
  state=$(nmap localhost -p $SSHP -P0 -sV | grep "^$SSHP" | awk '{print $2}')
  if [ "${state}" != "closed"  ] ;then
    echo "Ssh up and responding"
    break
  fi
  sleep 1
done
