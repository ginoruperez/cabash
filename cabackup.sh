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
		sudo touch ${USER_DIRECTORY}/$BACKUPFILE
		if [ -f ${USER_DIRECTORY}/$BACKUPFILE ]; then
			echo ".backup created successfully"
		fi
	fi

 	#check if /var/backup.tar.gz exist
 	if [ -f ${VAR_DIR}/backup.tar.gz ]; then
		echo "/var/backup.tar.gz exist"

		#check if /tmp/backup dir exist before extracting remove and create
		if [ -d /tmp/backup ]; then 
			#remove the existing files from /tmp/backup if any
		 	sudo rm -rf /tmp/backup
		fi
		sudo mkdir /tmp/backup

		echo "extracting /var/backup.tar.gz to /tmp/backup"
		sudo tar xf ${VAR_DIR}/backup.tar.gz -C $TMP_BACKUP


		USER_BACKUP_FILE=${USER_DIRECTORY}/$BACKUPFILE
		while read USERFILELINE; do

			FILE1=${USER_DIRECTORY}/$USERFILELINE
			FILE2=${TMP_BACKUP}/$USER/$USERFILELINE

			#IF  the same file exist in /tmp/backup/user then start compare
			if [ -f $FILE2 ]; then

				if cmp --silent -- "$FILE1" "$FILE2"; then
					echo  $FILE1 "in /tmp is identical to " $FILE2
				else
					echo "Both files differ"
					#replace the previous with e.g. filename.1 , filename.2 ... 
					counter=1
					until [ ! -f ${FILE2}.$counter ]; do
						let counter+=1
						echo "Counter :" $counter
					done

					#rename the temp file with different content but same name from /home/user  e.g. myscript.txt is same file with /home/user/myscript.txt but diff in content
					sudo mv ${FILE2} ${FILE2}.$counter

			

				fi
			

			fi

			#Then copy the original  file from /home/user to /tmp/backup/user/
			sudo cp $FILE1 ${TMP_BACKUP}/$USER
			

		done < $USER_BACKUP_FILE


		#Check if /var/backup exist, if not create first
		if [ ! -d ${VAR_DIR}/backup ]; then 
			echo "/var/backup folder is created"
			sudo mkdir ${VAR_DIR}/backup
		fi

		#remove and create /var/backup/user 
		VAR_BAK_USER=${VAR_DIR}/backup/$USER
		if [ -d ${VAR_BAK_USER} ]; then 
			sudo -rf $VAR_BAK_USER  #is this need??
		fi
		sudo mkdir $VAR_BAK_USER

		#copy now to /var/backup/user/
		echo "Copy the content of /tmp/backup/user/*.* /var/backup/user"
		sudo cp ${TMP_BACKUP}/${USER}/*.* $VAR_BAK_USER 2> /dev/null








		#Compare each file from /tmp/backup/user/ vs /home/user/
		#TMP_BAK_USER=${TMP_BACKUP}/$USER/*.*
		
		#for FILENAME in ${TMP_BAK_USER}; do

			# remove the path using ##*/ coz FILENAME contains the path and filename
			# USER_FILE=${USER_DIRECTORY}/${FILENAME##*/}

		#	echo  "TEMP FILE" $FILENAME "in /tmp VS" $USER_FILE

		#	if cmp --silent -- "$FILENAME" "$USER_FILE"; then
		#		echo  $FILENAME "in /tmp is identical to " $USER_FILE
		#	else
		#		echo "Both files differ"
		#		#replace the previous with e.g. filename.1 , filename.2 ... 
		#		counter=1
		#		until [ ! -f ${FILENAME}.$counter ]; do
		#			let counter+=1
		#			echo "Counter :" $counter
		#		done

		#		#rename the temp file with different content but same name from /home/user  e.g. myscript.txt is same file with /home/user/myscript.txt but diff in content
		#		sudo mv ${FILENAME} ${FILENAME}.$counter

				#Then copy the original  file from /home/user to /tmp/backup/user/
		#		sudo cp $USER_FILE ${TMP_BACKUP}/$USER

		#	fi

		#done
		

 	else

		#Check if /var/backup exist, if not create first
		if [ ! -d ${VAR_DIR}/backup ]; then 
				echo "/var/backup folder is created"
				sudo mkdir ${VAR_DIR}/backup
		fi

		#Read each user e.g /home/gino/.backup file and copy to /var/backup/$user/
		VAR_BAK_USER=${VAR_DIR}/backup/$USER
		USER_BACKUP_FILE=${USER_DIRECTORY}/$BACKUPFILE

		#create /var/backup/$user folder for each user
		if [ ! -d $VAR_BAK_USER ]; then 
				sudo mkdir $VAR_BAK_USER
		fi

		while read USERFILELINE1; do

			#Read the user .backup file and copy the file listed to /var/backup/$user 
			echo "Example cp /home/gino/myscript.txt /var/backup/gino "
			sudo cp ${USER_DIRECTORY}/$USERFILELINE1 $VAR_BAK_USER

		done < $USER_BACKUP_FILE



 	fi
 



done < $1


# tar -czvf /var/backup.tar.gz $USER_DIRECTORY  this is final 
echo "Creating a backup.tar.gz file in /var from /var/backup content"
#sudo tar -C /var/backup -cvf /var/backup.tar.gz . 
sudo tar -C $DIRECTORY_TO_BACKUP -cvf ${VAR_DIR}/backup.tar.gz . 

#display the list of /var/backup.tar.gz
echo "Displaying the content of /var/backup.tar.gz"
tar --list --file=/var/backup.tar.gz



