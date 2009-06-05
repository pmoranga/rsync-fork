#!/bin/bash
# pmoranga - around 2008 - initial script
#
# TODO: read configuration from conf file
#
#

LOG=~/log/`date +"%Y%m%d%H%M"`
mkdir -p $LOG

OLDDIR=$1
NEWDIR=$2

[ -z "$1" ] && echo usage: `basename $0` /source/ /dest/

FL=$LOG/rsync-fork.`date +"%Y%m%d"`.$$.log

# read configuration file, where it contains just one number (ex: echo 6 > ~/maxsync.cfg
CONF=~/maxsync.cfg
echo Config file: $CONF with value `cat $CONF`

RSYNC_ARGS="-auv --delete"

START=`date +%s`

for i in `ls $OLDDIR ` ; do
if [ -d $OLDDIR/$i -a ! -L $i ]; then
  EXCLUDE="${EXCLUDE} --exclude=/${i}"
  SUBSYNC="${SUBSYNC} ${i}"
  export EXCLUDE
fi
done

CMD="rsync ${RSYNC_ARGS} ${EXCLUDE} ${OLDDIR}/ ${NEWDIR}/"
echo $CMD
$CMD > $LOG/root.log

MPROC=`cat $CONF`

for d in ${SUBSYNC}; do
 CMD="rsync ${RSYNC_ARGS} ${OLDDIR}/${d}/ ${NEWDIR}/${d}/"
 $CMD > $LOG/${d}.log &
 echo `date +"%d/%m/%Y %H:%M"` $CMD : $!
 sleep 1
 PROC=`ps -ef | grep rsync | grep -wc $$ `
 [ $PROC -ge 30 ] && echo "Too much process, aborting, verify conf file" && exit 1
 while [ $PROC -ge $MPROC ]; do
  PROC=`ps -ef | grep rsync | grep -wc $$ `
  MPROC=`cat $CONF`
  sleep 5
 done
done

PROC=`ps -ef | grep rsync | grep -wc $$ `
while ! [ $PROC -eq 0 ]; do
PROC=`ps -ef | grep rsync | grep -wc $$ `
done

END=`date +%s`

echo start: $START end: $END elapsed: $(($END-$START)) s or $(( $(($END-$START)) / 60 )) min, `cat $LOG/*.log  | grep /  | grep -vc 'bytes  received'` arquivos copiados\ | tee $LOG/time.log


