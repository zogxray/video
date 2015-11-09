#!/bin/bash

# ——————————-
# on a MAC, make a softlink so you don’t have to deal with spaces.
# cd /Users/yourname/Pictures/
# ln -s /Users/yourname/Pictures/Photo\ Booth/ photobooth
# CHANGE THIS DIRECTORY

SEARCH_DIR=/home/$USER/studio
#SEARCH_DIR=smb://chenbro/студия/VECHER

# ——————————-

COPY_DIR=/home/$USER/copy
# make sure photo booth directory is there
if [ -d $SEARCH_DIR ]; then
echo “Got Videos directory”
else
echo “You do not have Videos directory of ‘$SEARCH_DIR’”
exit 1
fi
cd $SEARCH_DIR

# make sure a copy directory is there otherwise make it
if [ -d $COPY_DIR ]; then
echo “You have a save2 directory”
else
mkdir $COPY_DIR
fi

# ————————————————————
# Setup Environment
# ————————————————————
PDIR=${0%`basename $0`}
LCK_FILE=`basename $0`.lck

# ————————————————————
# Am I Running
# ————————————————————
if [ -f ${LCK_FILE} ]; then

# The file exists so read the PID
# to see if it is still running
MYPID=`head -n 1 ${LCK_FILE}`

TEST_RUNNING=`ps -p ${MYPID} | grep ${MYPID}`

if [ -z ${TEST_RUNNING} ]; then
# The process is not running
# Echo current PID into lock file
echo “Not running ${MYPID}”
echo $$ > ${LCK_FILE}
else
echo “`basename $0` is already running [${MYPID}]“
exit 0
fi

else
echo “Not running”
echo $$ > ${LCK_FILE}
fi

# ————————————————————
# Do Something
# ————————————————————

# check for the last time this program was run so we only upload newer files
if [ -f last_run.txt ]; then
LAST_RUN=`cat last_run.txt`
else
LAST_RUN=0
fi
THIS_RUN=`date +%s`
DATETIME=`date +%Y%m%d%H%M%S`
# DATETIME=`date +%Y%m%d%H%M%S`

# look for any .mov
# sometimes using mp4s now, can i search for multiple file types?
for f in ./*.ogv ./*.mov ./*.mp4 ./*.mpg; do
if [[ '*' != ${f:2:1} ]]; then

# for f in *.m*;do # this will get .mov, .m4v, and .mp4
# check to make sure the file hasn’t been touched in the last 120 seconds
# and that the file is newer than the last time we ran minus 120 seconds
# this stat line works for mac but not linux.
#if [ $FILE_TIME -lt $(($THIS_RUN - 120)) ] && [ `stat -f "%Sm" -t "%s" "$f"` -ge $(($LAST_RUN - 120)) ]; then

#MAC VERSION
#FILE_TIME=`stat -f “%Sm” -t “%s” “$f”`
#LINUX VERSION
#FILE_TIME=`stat -c ‘%X’ $f`  ### sometime you need the ' ' around the %X, sometimes not. ;)
FILE_TIME=`stat -c %X $f`

if [ $FILE_TIME -lt $(($THIS_RUN - 120)) ]; then
echo “Uploading $f”
python youtube-upload --title="$f" $f
# sometimes this behaves strange with the " marks, if so, try this one->
# python uploader2.py $DATETIME $f
# if it didn’t work, then touch the file so we can try again on future runs
# touch is only for mac running photobooth.
# move it on linux. cheese can handle files moving. photobooth barfs.
if [ $? -ne 0 ]; then
sleep 1
#touch $f
else
mv $f $COPY_DIR
fi
fi
fi
done

echo $THIS_RUN > last_run.txt
# ————————————————————
# Cleanup
# ————————————————————
rm -f ${LCK_FILE}

# ————————————————————
# Done
# ————————————————————
exit 0
