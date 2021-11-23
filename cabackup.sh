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
			sudo mkdir /tmp/backup
		else
			#remove the existing files from /tmp/backup if any
			sudo rm -rf /tmp/backup/*.*
		fi

		echo "extracting /var/backup.tar.gz to /tmp/backup"
		tar xf ${VAR_DIR}/backup.tar.gz -C $TMP_BACKUP

		#Compare each file from /tmp/backup/user/ vs /home/user/
		TMP_BAK_USER=${TMP_BACKUP}/$USER
		
		for FILENAME in ${TMP_BAK_USER}/*.*; do

			# remove the path using ##*/ coz FILENAME contains the path and filename
			USER_FILE=${USER_DIRECTORY}/${FILENAME##*/}

			echo  "TEMP FILE" $FILENAME "in /tmp VS" $USER_FILE

			if cmp --silent -- "$FILENAME" "$USER_FILE"; then
				echo  $FILENAME "in /tmp is identical to " $USER_FILE
			else
				echo "Both files differ"
				#replace the previous with e.g. filename.1 , filename.2 ... 
				counter=1
				until [ ! -f ${FILENAME}.$counter ]; do
					let counter+=1
					echo "Counter :" $counter
				done

				#rename the temp file with different content but same name from /home/user  e.g. myscript.txt is same file with /home/user/myscript.txt but diff in content
				sudo mv ${FILENAME} ${FILENAME}.$counter

				#Then copy the original  file from /home/user to /tmp/backup/user/
				sudo cp $USER_FILE $TMP_BAK_USER

			fi

		done
		

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
	#sudo tar -C /var/backup -cvf /var/backup.tar.gz . 
	sudo tar -C $DIRECTORY_TO_BACKUP -cvf ${VAR_DIR}/backup.tar.gz . 

	#display the list of /var/backup.tar.gz
	tar --list --file=/var/backup.tar.gz


done < $1



