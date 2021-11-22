#!/bin/bash

while read line; do

 echo "Preparing backup for user " $line

 USER=$line

 USER_DIRECTORY=/home/$USER  

 #Initial file to be checked or created if .backup is not exist
 BACKUPFILE=.backup

 VAR_DIR=/var  

 TMP_BACKUP=/tmp/backup

 #folder to tar 
 #DIRECTORY_TO_BACKUP=${TMP_BACKUP}/${USER_DIRECTORY}
 DIRECTORY_TO_BACKUP=$USER_DIRECTORY


 if [ ! -f ${USER_DIRECTORY}/$BACKUPFILE ]; then
	echo "Document .backup does not exist"
	echo "Creating .backup file...."
	touch ${USER_DIRECTORY}/$BACKUPFILE
	if [ -f ${USER_DIRECTORY}/$BACKUPFILE ]; then
		echo ".backup created successfully"
	fi
 fi

 #check if /var/backup.tar.gz exist
 if [ -f ${VAR_DIR}/backup.tar.gz ]; then
	echo "/var/backup.tar.gz exist"

	#check if /tmp/backup dir exist before extracting 
	if [ ! -d /tmp/backup ]; then 
	 	mkdir /tmp/backup
	fi

	echo "extracting /var/backup.tar.gz to /tmp/backup"
	tar xf ${VAR_DIR}/backup.tar.gz -C $TMP_BACKUP

	

	#do the comparison here 
	FILE1=${USER_DIRECTORY}/$BACKUPFILE 
	FILE2=${TMP_BACKUP}/${USER_DIRECTORY}/$BACKUPFILE

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
                cp $FILE2.$counter $USER_DIRECTORY

	fi

 fi


 # tar -czvf /var/backup.tar.gz $USER_DIRECTORY  this is final 
 echo "Creating a backup.tar.gz file in " $VAR_DIR from $DIRECTORY_TO_BACKUP
 sudo tar -czvf ${VAR_DIR}/backup.tar.gz  ${DIRECTORY_TO_BACKUP}/*.backup*

 #display the list of /var/backup.tar.gz
 tar --list --file=/var/backup.tar.gz


done < $1



