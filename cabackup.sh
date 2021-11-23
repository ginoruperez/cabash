#!/bin/bash


#globally output the error to /dev/null
exec 2> /dev/null

#this variable is switch to true once .tar.gz is extracted in /tmp/backup
ISTARFILE_EXTRACTED=false


while read line; do

	
	USER=$line

	USER_DIRECTORY=/home/$USER  

	#Initial file to be checked or created if .backup file is not yet existed
	BACKUPFILE=.backup

	#Folder to zip and copy the files to be backup
	VAR_DIR=/var  

	#Folder to extract existing backup.tar.gz
	TMP_BACKUP=/tmp/backup

	#Source folder to be zip into backup.tar.gz
	DIRECTORY_TO_BACKUP=${VAR_DIR}/backup

	if [ ! d $USER_DIRECTORY ]; then
		echo "ERROR: Entry in file $1 home user folder "$USER_DIRECTORY " does not exist!"
		continue
	fi

	echo ""
	echo "*** Preparing backup for user " $line "***"




	if [ ! -f ${USER_DIRECTORY}/$BACKUPFILE ]; then
		echo "INFO: File .backup does not exist in " $USER_DIRECTORY
		echo "INFO: Creating .backup file...."
		sudo touch ${USER_DIRECTORY}/$BACKUPFILE
		if [ -f ${USER_DIRECTORY}/$BACKUPFILE ]; then
			echo "INFO: File .backup created successfully"
		fi
	fi

 	#check if /var/backup.tar.gz exist
 	if [ -f ${VAR_DIR}/backup.tar.gz ]; then


		if [ "$ISTARFILE_EXTRACTED" = false ]; then

			echo "INFO: File /var/backup.tar.gz existed"
			#check if /tmp/backup dir exist before extracting remove and create
			if [ -d /tmp/backup ]; then 
				#remove the existing files from /tmp/backup if any
				sudo rm -rf /tmp/backup
			fi
			sudo mkdir /tmp/backup

			echo "INFO: Extracting /var/backup.tar.gz to /tmp/backup once only"
			sudo tar xf ${VAR_DIR}/backup.tar.gz -C $TMP_BACKUP

			#set the switch to true
			ISTARFILE_EXTRACTED=true

		fi


		USER_BACKUP_FILE=${USER_DIRECTORY}/$BACKUPFILE
		while read USERFILELINE; do

			FILE1=${USER_DIRECTORY}/$USERFILELINE
			FILE2=${TMP_BACKUP}/$USER/$USERFILELINE

			#if the same file exist in /tmp/backup/user then start the comparison and renaming of old files
			if [ -f $FILE2 ]; then

				if cmp --silent -- "$FILE1" "$FILE2"; then
					echo "INFO: "$FILE1 " is identical to " $FILE2
				else
					echo "INFO: "$FILE1 " is differ to " $FILE2 " previous file will be renamed"
					
					counter=1
					until [ ! -f ${FILE2}.$counter ]; do
						#Increment the counter for file renaming
						let counter+=1
						
					done

					#replace the previous with e.g. filename.1 , filename.2 ... 
					echo "INFO: Renaming ${FILE2} to " ${FILE2}.$counter 
					sudo mv ${FILE2} ${FILE2}.$counter			

				fi
			

			fi

			#Check if entry in .backup file is existed if not,  log the error
			if [ ! -f $FILE1 ]; then
				echo "ERROR: Entry filename $USERFILELINE in .backup file is not existed!"
			else
				#Then copy the original  file from /home/user to /tmp/backup/user/
				echo "INFO: Copying  $FILE1 to ${TMP_BACKUP}/$USER"
				sudo cp $FILE1 ${TMP_BACKUP}/$USER
			
			fi
			

		done < $USER_BACKUP_FILE


		#Check if /var/backup exist, if not create first
		if [ ! -d ${VAR_DIR}/backup ]; then 
			echo "INFO: Folder /var/backup  is created"
			sudo mkdir ${VAR_DIR}/backup
		fi

		#remove and create /var/backup/user 
		VAR_BAK_USER=${VAR_DIR}/backup/$USER
		if [ -d ${VAR_BAK_USER} ]; then 
			sudo -rf $VAR_BAK_USER  
		fi
		sudo mkdir $VAR_BAK_USER
		
		#Copying the content of /tmp/backup/user/*.* /var/backup/user"
		echo "INFO: Copying the content of " ${TMP_BACKUP}/${USER}/ " to " $VAR_BAK_USER 
		sudo cp ${TMP_BACKUP}/${USER}/*.* $VAR_BAK_USER 

 	else

		#Check if /var/backup exist, if not create first
		if [ ! -d ${VAR_DIR}/backup ]; then 
				echo "INFO: Folder /var/backup folder is created"
				sudo mkdir ${VAR_DIR}/backup
		fi

		#Read each user e.g /home/gino/.backup file and copy to /var/backup/$user/
		VAR_BAK_USER=${VAR_DIR}/backup/$USER
		USER_BACKUP_FILE=${USER_DIRECTORY}/$BACKUPFILE

		echo "INFO: Creating $VAR_BAK_USER folder"
		if [ ! -d $VAR_BAK_USER ]; then 
				sudo mkdir $VAR_BAK_USER
		fi

		#Read the user .backup file and copy the file listed to /var/backup/$user 
		while read USERFILELINE1; do

			
			#copying /home/gino/file to /var/backup/gino
			echo "INFO: Copying file ${USER_DIRECTORY}/$USERFILELINE1 to $VAR_BAK_USER"
			sudo cp ${USER_DIRECTORY}/$USERFILELINE1 $VAR_BAK_USER

		done < $USER_BACKUP_FILE

 	fi


done < $1


# tar -czvf /var/backup.tar.gz $USER_DIRECTORY
echo ""
echo "INFO: Creating a backup.tar.gz file in /var from /var/backup content"
sudo tar -C $DIRECTORY_TO_BACKUP -cvf ${VAR_DIR}/backup.tar.gz . 

#display the list of /var/backup.tar.gz
echo ""
echo "INFO: Listing the content of /var/backup.tar.gz"
tar --list --file=/var/backup.tar.gz
echo ""
echo "INFO: Backup is successfully completed!"




