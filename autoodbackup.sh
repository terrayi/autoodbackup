#!/bin/bash

WORK_PATH=$PWD #${1:-$PWD}
SOURCE_DEVICE="/dev/sr0"
MOUNT_PATH="ISOMOUNT"
MOUNT_TYPE="${MTYPE:-iso9660}"
DDRESCUE="/usr/bin/ddrescue -dJ -b 2Ki"
ISOINFO="/usr/bin/isoinfo -debug -d -J -j UTF-8 -R -i"
CONTENT_JSON="tree -JsN -o"
CONTENT_TREE="tree -sN -o"
CONTENT_XML="tree -XsN -o"

# waiting for optical disc
echo "waiting for disc.."
while ! dd if=$SOURCE_DEVICE bs=2048 count=1 of=/dev/null 2>/dev/null; do sleep 1; done

#dev=$SOUICE_DEVICE
#while :; do
#    err=$(dd if=$dev of=/dev/null bs=2048 status=none count=1 2>&1)
#    case $err in
#    "dd: failed to open '$dev': No medium found")
#        sleep 1 ;;
#    '')
#        # successfully opened
#        break ;;
#    *)
#        # unexpected error
#        # play some SOUND in the speakers
#        # and wait for user input to continue
#        read wtf ;;
#    esac
#done

# copy ISO image
echo "readng optical disc.."
TMPNAME=${TNAME:-`mktemp XXXX.iso`}

if [ -z "${LOOPDDRESCUE}" ]
then
	$DDRESCUE $SOURCE_DEVICE $TMPNAME $TMPNAME.map
else
	until $DDRESCUE $SOURCE_DEVICE $TMPNAME $TMPNAME.map
	do
		sleep 1
	done
fi

# do not attempt running if it fails
if  [ $? -gt 0 ]
then
    echo "error reading disc to ${TMPNAME}"
    exit $?
fi
# remove .map and .map.bak files
rm -f $TMPNAME.map*

# retrieve volume label and creation date
echo "retrieve volume label and creation date from image.."
ISOINFO_OUTPUT=`$ISOINFO $WORK_PATH/$TMPNAME 2> /dev/null`

if [ -z "${VOLUME}" ]
then
	VOLUME=`echo "${ISOINFO_OUTPUT}" \
		| grep 'Volume id' \
		| cut -d':' -f 2- \
		| xargs \
		| awk '{print tolower(\$0)}' \
		| sed -r 's/[ ]+/-/g'`
fi

DATE=`echo "${ISOINFO_OUTPUT}" \
	| grep 'Creation Date' \
	| cut -d':' -f 2- \
	| xargs \
	| cut -d' ' -f -3 \
	| sed -r 's/[ ]//g'`
echo "  Volume: ${VOLUME}"
echo "  Created: ${DATE}"

# mount
echo "try to mount iso.."
mkdir $WORK_PATH/$MOUNT_PATH &> /dev/null \
	; mount -t $MOUNT_TYPE -o ro $WORK_PATH/$TMPNAME $WORK_PATH/$MOUNT_PATH/ \
	&& cd $WORK_PATH/$MOUNT_PATH

if [ $? -eq 0 ]
then
	LOG_CONTENT=1
else
	echo "failed to mount"
	LOG_CONTENT=0
fi

if [ $LOG_CONTENT -eq 1 ]
then
	# retrieve latest date of files
	LAST_DATE=`ls -lgGt --time-style iso . \
		| awk '{print $4, $5}' \
		| awk '!/^[[:blank:]]*$/' \
		| head -n 1 \
		| cut -d' ' -f 1`
fi

if [ -z "${VOLUME}" ]
then
	VOLUME="backup"
fi

if [ -z "${DATE}" ]
then
	DATE="${LAST_DATE}"
fi

#FINAL_NAME="$VOLUME-$DATE"
#FINAL_NAME="$VOLUME-$LAST_DATE"
FINAL_NAME=${1:-"$VOLUME-$DATE"}

# auto numbering
FNAME=$FINAL_NAME
NUMBER=0
while [ -e "$WORK_PATH/$FNAME" ]; do
    printf -v FNAME '%s-%02d' "$FINAL_NAME" "$(( ++NUMBER ))"
done
FINAL_NAME=$FNAME
FINAL_PATH=$WORK_PATH/$FINAL_NAME
echo "The path name of generated image will be ${FINAL_PATH}/${FINAL_NAME}.iso"
mkdir -p $FINAL_PATH

if [ $LOG_CONTENT -eq 1 ]
then
	# create file listings
	echo "creating file listings.."
	$CONTENT_JSON $FINAL_PATH/$FINAL_NAME.json ./
	$CONTENT_TREE $FINAL_PATH/$FINAL_NAME.txt ./
	$CONTENT_XML $FINAL_PATH/$FINAL_NAME.xml ./

	# unmount
	echo "unmounting image.."
	cd $WORK_PATH ; umount $WORK_PATH/$MOUNT_PATH
fi

# rename
mv $WORK_PATH/$TMPNAME $WORK_PATH/$FINAL_NAME.iso

# create checksum files
echo "calculating checksums.."
/usr/bin/md5sum -b $FINAL_NAME.iso > $FINAL_PATH/$FINAL_NAME.md5sum
/usr/bin/sha256sum -b $FINAL_NAME.iso > $FINAL_PATH/$FINAL_NAME.sha256sum
/usr/bin/cksum -a blake2b $FINAL_NAME.iso > $FINAL_PATH/$FINAL_NAME.blake2sum
mv $WORK_PATH/$FINAL_NAME.iso $FINAL_PATH/$FINAL_NAME.iso

# update global checksum files
echo "updating global checksum files.."
touch $WORK_PATH/files.md5sum
touch $WORK_PATH/files.sha256sum
touch $WORK_PATH/files.blake2sum
REPLACE="$FINAL_NAME/$FINAL_NAME"
`sed 's+'$FINAL_NAME'+'$REPLACE'+g' $FINAL_PATH/$FINAL_NAME.md5sum >> $WORK_PATH/files.md5sum`
`sed 's+'$FINAL_NAME'+'$REPLACE'+g' $FINAL_PATH/$FINAL_NAME.sha256sum >> $WORK_PATH/files.sha256sum`
`sed 's+'$FINAL_NAME'+'$REPLACE'+g' $FINAL_PATH/$FINAL_NAME.blake2sum >> $WORK_PATH/files.blake2sum`

#mkdir $WORK_PATH/$FINAL_NAME && mv $WORK_PATH/$FINAL_NAME.* $WORK_PATH/$FINAL_NAME/
echo "Created $FINAL_NAME.{iso, json, xml, md5sum, sha256sum, blake2sum}"

echo "ejecting disc.."
eject /dev/sr0
echo "done."

