#!/bin/bash

UPPERSZ=$((1*1024*1024*1024))
LOWERSZ=$((30*1024*1024*1024))
versions=( "nylon_hetero_write_only_small_nvme" )
for version in "${versions[@]}"
do
  make -j db_bench
  CURPATH=`pwd`
  LOGDIR="/home/heejin/project/rocksdb_log/fillrandom_test"_${version}
  if [ ! -d $LOGDIR ]; then
    mkdir -p $LOGDIR
    mkdir $LOGDIR/dstat
  fi

  SZ=$((20*1024*1024*1024/100))
  echo "Total DB size is" $SZ
  storages=( "hetero" )
  for storage in "${storages[@]}"
  do
    if [ ! -d /mnt/nvme/rocksdb-test ]; then
      sudo mkdir /mnt/nvme/rocksdb-test
      
    fi
    LOG=$LOGDIR/result_${storage}.txt
    touch $LOG
    #sudo bash ~/cpu_disable.sh $cpu && # hj: restrict CPU 
    sudo echo "storage is " $storage >> $LOG
    touch ${LOGDIR}/dstat/${storage}
      dstat -tcdm -D /dev/nvme0n1,/dev/sdb --output=$LOGDIR/dstat/${storage} &

      echo "AUTO TUNE OFF" >> ${LOG}
      sudo ./db_bench --key_size=8 --value_size=100 --db=/mnt/nvme/rocksdb-test --benchmarks="fillrandom" --num=$SZ \
        --max_write_buffer_number=10 --rate_limiter_auto_tuned=false --lower_db=/mnt/ssd_1/hetero-rocksdb --upper_db=/mnt/nvme/hetero-rocksdb --upper_db_sz=${UPPERSZ} --lower_db_sz=${LOWERSZ} >> ${LOG}

    kill -9 `ps -ef | grep 'dstat' | awk '{print $2}'`

    sudo cp /mnt/${storage}/rocksdb-test/LOG $LOGDIR/LOG_${storage}
  done
done
