#!/bin/bash

while read line; do

 echo "Preparing backup for user " $line

 user=$line

 user_directory=/home/$user  

 #Initial file to be checked or created if .backup is not exist
 backupfile=.backup

 vardir=/var  

 tmpbackup=/tmp/backup

 #folder to tar 
 #directory_to_backup=${tmpbackup}/${user_directory}
 directory_to_backup=$user_directory



 if [ ! -f ${user_directory}/$backupfile ]; then
	echo "Document .backup does not exist"
	echo "Creating .backup file...."
	touch ${user_directory}/$backupfile
	if [ -f ${user_directory}/$backupfile ]; then
		echo ".backup created successfully"
	fi
 fi

 #check if /var/backup.tar.gz exist
 if [ -f ${vardir}/backup.tar.gz ]; then
	echo "/var/backup.tar.gz exist"

	#check if /tmp/backup dir exist before extracting 
	if [ ! -d /tmp/backup ]; then 
	 	mkdir /tmp/backup
	fi

	echo "extracting /var/backup.tar.gz to /tmp/backup"
	tar xf ${vardir}/backup.tar.gz -C $tmpbackup

	

	#do the comparison here 
	FILE1=${user_directory}/$backupfile 
	FILE2=${tmpbackup}/${user_directory}/$backupfile

	if cmp --silent -- "$FILE1" "$FILE2"; then
  		echo "Both files  are identical" 
	else
  		echo "Both files differ"
          	#replace the previous with e.g. filename.1 , filename.2 ... 
		counter=1
		until [ ! -f ${FILE2}.$counter ]; do
			let counter+=1
			echo "Counter :" $counter
		done

  		mv $FILE2 ${FILE2}.$counter

 		#Copy the renamed  file to /home/user
                cp $FILE2.$counter $user_directory

	fi

 fi


 # tar -czvf /var/backup.tar.gz $user_directory  this is final 
 echo "Creating a backup.tar.gz file in " $vardir from $directory_to_backup
 sudo tar -czvf ${vardir}/backup.tar.gz  ${directory_to_backup}/*.backup*

 #display the list of /var/backup.tar.gz
 tar --list --file=/var/backup.tar.gz


done < $1



