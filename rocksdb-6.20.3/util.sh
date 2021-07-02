#!/bin/bash

LOGDIR="/home/heejin/project/rocksdb_log/fillrandom_test_nylon_tail"
if [ ! -d $LOGDIR ]; then
  mkdir -p $LOGDIR
  mkdir $LOGDIR/dstat
fi

SZ=$((10*1024*1024*1024/100))
echo "Total DB size is" $SZ
storages=( "nvme" )
for storage in "${storages[@]}"
do
  if [ ! -d /mnt/${storage}/rocksdb-test ]; then
    sudo mkdir /mnt/${storage}/rocksdb-test
    
  fi
  LOG=$LOGDIR/result_${storage}.txt
  touch $LOG
  #sudo bash ~/cpu_disable.sh $cpu && # hj: restrict CPU 
  sudo echo "storage is " $storage >> $LOG
  touch ${LOGDIR}/dstat/${storage}
  if [ $storage == "nvme" ]; then
	echo "NVME START"
  	#dstat -tcdm -D /dev/nvme0n1 --output=$LOGDIR/dstat/${storage} &
  else
	echo "SATA START"
  	dstat -tcdm -D /dev/sdd --output=$LOGDIR/dstat/${storage} &
  fi
  #sudo ./db_bench --key_size=8 --value_size=100 --db=/mnt/${storage}/rocksdb-test --benchmarks="fillrandom" --num=$SZ >> $LOG 
  sudo ./db_bench --key_size=8 --value_size=100 --db=/mnt/${storage}/rocksdb-test \
	  --benchmarks="fillrandom" --num=$SZ \
	  --max_write_buffer_number=10 \
	  --client_tail_log=/mnt/ssd_1/nylon-tail-log.txt
  kill -9 `ps -ef | grep 'dstat' | awk '{print $2}'`

  sudo cp /mnt/${storage}/rocksdb-test/LOG $LOGDIR/LOG_${storage}
done
