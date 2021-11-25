#!/bin/bash

#logger variable 
LOGGER=/usr/bin/logger

#this variable is switch to true once .tar.gz is extracted in /tmp/backup
ISTARFILE_EXTRACTED=false

#Initial file to be checked or created if .backup file is not yet existed
BACKUPFILE=.backup

#Folder to zip and copy the files to be backup
VAR_DIR=/var  

#Folder to extract existing backup.tar.gz
TMP_BACKUP=/tmp/backup

#Source folder to be zip into backup.tar.gz
DIRECTORY_TO_BACKUP=${VAR_DIR}/backup

#Display usage instruction 
display_usage() { 
	echo -e "\nThis script must be run with a sudo access privilege." 
	echo "Make sure argument passed is a file containing existing users list of this system e.g userlist.txt"
	echo -e "\nUsage: $0 [argument] \n" 
	} 

#Create logs in /var/log/syslog if runs in ubuntu or /var/log/messages if it runs in other distro e.g. centos
info()
{
    ${LOGGER} -s -t CABACKUP-SCRIPT -p user.notice "INFO: $@"
}

error()
{
    ${LOGGER} -s -t CABACKUP-SCRIPT -p user.err "ERROR: $@"
}

#Check filename contains / symbol listed in .backup file
chk_filename() {

	error "FILE $1"
	STRFILE=$1
	if [[ $STRFILE == *[\/]* ]]
	then
		info "WARNING: File $STRFILE contains / symbol, file will not be backup correctly "
	fi

}



# Check whether user had supplied -h or --help as argument. If yes the display_usage 
if [[ ( $# == "--help") ||  $# == "-h" ]] 
then 
	display_usage
	exit 0
fi 

#Check if parameter is passed or valid, otherwise terminate the program
if [ ! -f $1 ]; then
	display_usage
	exit 1
fi

#if no parameter passed, call display_usage and terminate the program
if [ $# -eq 0 ]; then
    display_usage
    exit 1
fi

#Check if user has sudo access privelege
printf "skippass\n" | sudo -S /bin/chmod --help >/dev/null 2>&1
info "Checking user's privileges..."
if [ $? -eq 0 ];then
   info  "User " $(whoami) "has sudo access."
else
   error "User " $(whoami) "has no sudo access!"
   display_usage
   exit 0
fi

#Iterate base on the number lines entered in userlist text file
while read line; do

	USER=$line

	USER_DIRECTORY=/home/$USER  	

	if [ ! -d $USER_DIRECTORY ]; then
		error "Entry in file $1 user $line, folder " $USER_DIRECTORY " does not exist!"
		continue
	fi

	echo ""
	info "*** Preparing backup for user  $line ***"


	if [ ! -f ${USER_DIRECTORY}/$BACKUPFILE ]; then
		info "File .backup does not exist in " $USER_DIRECTORY
		info "Creating .backup file...."
		sudo touch ${USER_DIRECTORY}/$BACKUPFILE
		if [ -f ${USER_DIRECTORY}/$BACKUPFILE ]; then
			info "File .backup created successfully"
		fi
	fi

 	#check if /var/backup.tar.gz exist
 	if [ -f ${VAR_DIR}/backup.tar.gz ]; then


		if [ "$ISTARFILE_EXTRACTED" = false ]; then

			info "File /var/backup.tar.gz existed"
			#check if /tmp/backup dir exist before extracting remove and create
			if [ -d /tmp/backup ]; then 
				#remove the existing files from /tmp/backup if any
				sudo rm -rf /tmp/backup
			fi
			sudo mkdir /tmp/backup

			info "Extracting /var/backup.tar.gz to /tmp/backup once only"
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

				#Check filename if contains / symbol 
				echo "WARNING ${USERFILELINE}"
				chk_filename ${USERFILELINE}

				if cmp --silent -- "$FILE1" "$FILE2"; then
					info $FILE1 " is identical to " $FILE2
				else
					info $FILE1 " is differ to " $FILE2 " previous file will be renamed"
					
					counter=1
					until [ ! -f ${FILE2}.$counter ]; do
						#Increment the counter for file renaming
						let counter+=1
						
					done

					#replace the previous with e.g. filename.1 , filename.2 ... 
					info "Renaming ${FILE2} to " ${FILE2}.$counter 
					sudo mv ${FILE2} ${FILE2}.$counter			

				fi
			

			fi

			#Check if entry in .backup file is existed if not,  log the error
			if [ ! -f $FILE1 ]; then
				error "Entry filename $USERFILELINE in .backup file is not existed!"
			else
				#Then copy the original  file from /home/user to /tmp/backup/user/
				info "Copying  $FILE1 to ${TMP_BACKUP}/$USER"
				sudo cp $FILE1 ${TMP_BACKUP}/$USER
			
			fi
			

		done < $USER_BACKUP_FILE


		#Check if /var/backup exist, if not create first
		if [ ! -d ${VAR_DIR}/backup ]; then 
			info "Folder /var/backup  is created"
			sudo mkdir ${VAR_DIR}/backup
		fi

		#remove and create /var/backup/user 
		VAR_BAK_USER=${VAR_DIR}/backup/$USER
		if [ -d ${VAR_BAK_USER} ]; then 
			sudo rm -rf $VAR_BAK_USER  
		fi
		sudo mkdir $VAR_BAK_USER
		
		#Copying the content of /tmp/backup/user/*.* /var/backup/user"
		info "Copying the content of " ${TMP_BACKUP}/${USER}/ " to " $VAR_BAK_USER 
		sudo cp ${TMP_BACKUP}/${USER}/*.* $VAR_BAK_USER 

 	else

		#Check if /var/backup exist, if not create first
		if [ ! -d ${VAR_DIR}/backup ]; then 
				info "Folder /var/backup folder is created"
				sudo mkdir ${VAR_DIR}/backup
		fi

		#Read each user e.g /home/gino/.backup file and copy to /var/backup/$user/
		VAR_BAK_USER=${VAR_DIR}/backup/$USER
		USER_BACKUP_FILE=${USER_DIRECTORY}/$BACKUPFILE

		info "Creating $VAR_BAK_USER folder"
		if [ ! -d $VAR_BAK_USER ]; then 
				sudo mkdir $VAR_BAK_USER
		fi

		#Read the user .backup file and copy the file listed to /var/backup/$user 
		while read USERFILELINE1; do

			
			#copying /home/gino/file to /var/backup/gino
			info "Copying file ${USER_DIRECTORY}/$USERFILELINE1 to $VAR_BAK_USER"
			sudo cp ${USER_DIRECTORY}/$USERFILELINE1 $VAR_BAK_USER

		done < $USER_BACKUP_FILE

 	fi


done < $1


# tar -czvf /var/backup.tar.gz $USER_DIRECTORY
echo ""
info "Creating a backup.tar.gz file in /var from /var/backup content"
sudo tar -C $DIRECTORY_TO_BACKUP -cvf ${VAR_DIR}/backup.tar.gz . 

#display the list of /var/backup.tar.gz
echo ""
info "Listing the content of /var/backup.tar.gz"
tar --list --file=/var/backup.tar.gz
echo ""
info "Backup is successfully completed!"




