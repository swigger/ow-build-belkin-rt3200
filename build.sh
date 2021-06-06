#!/bin/bash


CFILES=$(cd ../e8450/custom-files/ && pwd)
PACKAGES="kmod-usb-storage kmod-usb-storage-uas luci diffutils tcpdump psmisc netcat gdbserver vim curl"
IBFILE="https://downloads.openwrt.org/snapshots/targets/mediatek/mt7622/openwrt-imagebuilder-mediatek-mt7622.Linux-x86_64.tar.xz"

check_local_hash(){
	sha256sum "$1" | grep "$2" >/dev/null 2>&1
}

download_ib_package(){
	PAGEPART=${IBFILE%/*}
	FILEPART=${IBFILE##*/}
	ODIR=${FILEPART%.tar.*}
	# echo $PAGEPART $FILEPART
	HASHCODE=`curl -s ${PAGEPART}/sha256sums | grep ${FILEPART} | grep -Eo '[0-9a-fA-F]{64}'`
	if check_local_hash "$FILEPART" $HASHCODE ; then
		return 0;
	else
		curl -o $FILEPART "$IBFILE"
		if check_local_hash "$FILEPART" $HASHCODE ; then
			echo "unpacking..." >&2
			rm -fr $ODIR
			tar -xJf "$FILEPART"
		else
			return 1
		fi
	fi
}

if download_ib_package; then
	echo "removing old files..." >&2
	find . -name '*e8450*.itb' | xargs rm -f  
	echo "doing...." >&2
	make -C $ODIR image PROFILE=linksys_e8450-ubi PACKAGES="$PACKAGES" FILES="$CFILES"
	if [ $? -ne 0 ] ; then
		exit 1
	fi
	echo "DONE"
	find $ODIR/bin -name '*e8450*.itb' | xargs -I {} cp {} . 
else
	false
fi
