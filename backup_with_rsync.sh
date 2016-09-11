#!/bin/bash
#clear

_hostname=$(hostname) #_hostname=$(hostname -s)
_hostname=${_hostname%%.*}

_date=$(date +"%Y-%m-%d")
_time=$(date +"%T")

#will be overriden
#evenorodddate=$(date +%d)
#if [ $((10#${evenorodddate}%2)) -eq 0 ];
#then
#    _backup_root_folder="/media/backup2/"
#else
#    _backup_root_folder="/media/backup1/"
#fi

#will override backup root folder
declare -a target_folders=("/media/backup1/" "/media/backup2/" "/media/backup3/")
target_folders_count=${#target_folders[@]}
target_folder_index=$(($target_folders_count-1))
daynumber=$(($(date --utc --date "$1" +%s)/86400))

COUNTER=$target_folders_count
until [ $COUNTER -lt 1 ]; do
    if [[ $(($daynumber % $COUNTER)) == 0 ]];
    then
      target_folder_index=$(($COUNTER-1))
      break
    fi
    let COUNTER-=1
done

_backup_root_folder=${target_folders[$target_folder_index]};

_source_folder="/srv/samba/"
_admin_folder="/root/"
_script_folder=$_admin_folder"scripts/"
_this_host_backup_folder=$_backup_root_folder$_hostname"/rsync/"
_oldest_folder=$(ls -1t $_this_host_backup_folder | tail -1)
_folder_count=$(find $_this_host_backup_folder -maxdepth 1 -type d | wc -l)
_target_folder=$_this_host_backup_folder$_date
_log_folder=$_script_folder"logs/"
_log_filename=$_hostname"-rsync-"$_date"-"$_time".log"
_log_filepath=$_log_folder$_log_filename
_exclude_list_folder=$_script_folder"exclude/"
_exclude_list_filepath=$_exclude_list_folder$_hostname".lst"

if [ -d "$_target_folder" ]
then
	_method="sync"
else
	if [ $_folder_count -gt 1 ]
	then
		_method="sync"
		mkdir $_target_folder -p
		mv $_this_host_backup_folder$_oldest_folder/* $_target_folder
		rmdir $_this_host_backup_folder$_oldest_folder
	else
		_method="copy"
		mkdir $_target_folder -p
	fi
fi

echo -e "\n"
echo +----------------------------------------------------------------------------------------------------------+
echo " "backup: rsync \| version: 1.5 \| author: András Szabácsik
echo " "method: $_method
echo "   "date: $_date $_time
echo "   "host: $_hostname
echo " "source: $_source_folder
echo " "target: $_target_folder
echo exclude: $_exclude_list_filepath
echo "    "log: $_log_filepath
echo +----------------------------------------------------------------------------------------------------------+
echo -e "\n"

if [[ $_hostname == localhost* ]]; then
    echo "ERROR: Invalid Hostname ($_hostname)"
	#todo: use ip address
    echo -e "\n"
    exit
fi

#mkdir $_log_folder -p
#mkdir $_exclude_list_folder -p

touch $_log_filepath

if [ ! -f $_log_filepath ]
then
    echo "ERROR: file does not exist ( $_log_filepath )"
    exit
fi

if [ ! -f $_exclude_list_filepath ]
then
    echo "ERROR: file does not exist ( $_exclude_list_filepath )"
    echo -e "\n"
    exit
fi

touch $_target_folder


_start_time=$(date +"%Y-%m-%d %T")
echo "   Begin at: "$_start_time

if which ionice >/dev/null 2>&1;
then
ionice -c 3 nice -n +19 rsync -avvl --stats --progress --exclude-from $_exclude_list_filepath $_source_folder $_target_folder >> $_log_filepath 2>&1
else
nice -n +19 rsync -avvl --stats --progress --exclude-from $_exclude_list_filepath $_source_folder $_target_folder >> $_log_filepath 2>&1
fi

_end_time=$(date +"%Y-%m-%d %T")
touch $_target_folder
echo "Finished at: "$_end_time
echo -e "\n"
