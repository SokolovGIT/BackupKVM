#!/bin/bash

# Date (year, months, day)
data=`date +%Y-%m-%d`
# Directory for backup
backup_dir=/backup
# List of running VM
vm_list=`virsh list | grep running | awk '{print $2}'`
# 
#vm_list=(vm-1 vm-2)
# Log File
logfile="/var/log/kvmbackup.log"

# Use this condition for choosing VM directly.
#for activevm in "${vm_list[@]}";

# Use this construction for all working VM
for activevm in $vm_list

    do
        mkdir -p $backup_dir/$activevm
        # Writing infrormation into the log file with seconds
        echo "`date +"%Y-%m-%d_%H-%M-%S"` Start backup $activevm" >> $logfile
        # Configuration backup
        virsh dumpxml $activevm > $backup_dir/$activevm/$activevm-$data.xml
        echo "`date +"%Y-%m-%d_%H-%M-%S"` Create snapshots $activevm" >> $logfile
        # List of VM disks
        disk_list=`virsh domblklist $activevm | grep vd | awk '{print $1}'`
        # List of VM disks path
        disk_path=`virsh domblklist $activevm | grep vd | awk '{print $2}'`
        # Making snapshots
        virsh snapshot-create-as --domain $activevm snapshot --disk-only --atomic --quiesce --no-metadata
        sleep 2
	for path in $disk_path
	    do
		echo "`date +"%Y-%m-%d_%H-%M-%S"` Create backup $activevm $path" >> $logfile
		# Filename of the path
		filename=`basename $path`
		# Backuping disk
		pigz -c $path > $backup_dir/$activevm/$filename.gz
		sleep 2
	    done
	for disk in $disk_list
	            do
	                # Finding the path to snapshot
	                snap_path=`virsh domblklist $activevm | grep $disk | awk '{print $2}'`
	                echo "`date +"%Y-%m-%d_%H-%M-%S"` Commit snapshot $activevm $snap_path" >> $logfile
	                # Combine snapshots
	                virsh blockcommit $activevm $disk --active --verbose --pivot
	                sleep 2
	            done
	        echo "`date +"%Y-%m-%d_%H-%M-%S"` End backup $activevm" >> $logfile
	    done                                                                                                                                                 

#Deleting backups older than 90 days. USE IT only if NEEDED
#/usr/bin/find /backup/*/ -type f -mtime +90 -exec rm -rf {} \;
