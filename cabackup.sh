#!/bin/bash

while read line; do

	echo "Preparing backup for user " $line

	USER=$line

	USER_DIRECTORY=/home/$USER  

	#Initial file to be checked or created if .backup is not exist
	BACKUPFILE=.backup

	#Folder to zip the backup 
	VAR_DIR=/var  

	#Folder to extract existing backup.tar.gz
	TMP_BACKUP=/tmp/backup

	#Source folder to be backup
	DIRECTORY_TO_BACKUP=${VAR_DIR}/backup


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

 	else

		#Check if /var/backup exist, if not create first
		if [ ! -d ${VAR_DIR}/backup ]; then 
				echo "/var/backup folder is created"
				sudo mkdir ${VAR_DIR}/backup
		fi

		#Read each user e.g /home/gino/.backup file and copy to /var/backup/$user/
		VAR_BAK_USER=${VAR_DIR}/backup/$USER
		USER_BACKUP_FILE=${USER_DIRECTORY}/$BACKUPFILE
		while read line; do

			if [ ! -d $VAR_BAK_USER ]; then 
				sudo mkdir $VAR_BAK_USER
			fi
			#Read the user .backup file and copy the file listed to /var/backup/$user 
			#Example cp /home/gino/myscript.txt /var/backup/gino 
			sudo cp ${USER_DIRECTORY}/$line $VAR_BAK_USER

		done < $USER_BACKUP_FILE



 	fi
 


	# tar -czvf /var/backup.tar.gz $USER_DIRECTORY  this is final 
	echo "Creating a backup.tar.gz file in /var from /var/backup content"
	sudo tar -C /var/backup -cvf /var/backup.tar.gz . 

	#display the list of /var/backup.tar.gz
	tar --list --file=/var/backup.tar.gz


done < $1



