#!/bin/bash

#############################################################################################
# Author :  Gino Ruperez
# 
# Date   : December 6, 2021
#
# This script is a utility for making a user backup based on the list entered in .backup file
# If the .backup file is not existed in home user folder it will create a blank one. 
# User must populate it with filenames to be backup one filename per line. 
# Actual file should be placed relative to home user folder e.g. /home/[username]/[file]
# It requires that the user who runs the script to have a sudo access priveleges. 
# Files are backup in /var/backup folder for each user and finally a compressed backup.tar.gz file 
# is created once the backup is completed successfully. 
# 
# The script also creates log entries in /var/log/syslog when it runs in Debian OS otherwise log entry can
# be seen in /var/log/messages for other distro such as FEDORA e.g centos. 
#
# Please see below the usage syntax. 
#
# Usage : ./cabackup.sh [argument]
# 
# The argument is a text file containing list of existing users of the system
#############################################################################################


# logger variable 
LOGGER=/usr/bin/logger

# this variable is switch to true once .tar.gz is extracted in /tmp/backup
ISTARFILE_EXTRACTED=false

# Initial file to be checked or created if .backup file is not yet existed
BACKUPFILE=.backup

# Folder to zip and copy the files to be backup
VAR_DIR=/var  

# Folder to extract existing backup.tar.gz
TMP_BACKUP=/tmp/backup

# Source folder to be zip into backup.tar.gz
DIRECTORY_TO_BACKUP=${VAR_DIR}/backup

# Output log file 
OUTPUTLOG=/dev/null

# Backup status to determine if backup is completed successfully
BACKUPOK=true

# Display usage instruction 
display_usage() { 
	echo -e "\nThis script must be run with a sudo access privilege." 
	echo "Make sure argument passed is a file containing existing users list of this system e.g userlist.txt"
	echo -e "\nUsage: $0 [argument] \n" 
	} 


# Create logs in /var/log/syslog if runs in ubuntu or /var/log/messages if it runs in other distro e.g. centos
info()
{
    ${LOGGER} -s -t CABACKUP-SCRIPT -p user.notice "INFO: $@"
}

error()
{
    ${LOGGER} -s -t CABACKUP-SCRIPT -p user.err "ERROR: $@"
}



# Check whether user had supplied -h or --help as argument. If yes call the display_usage function
if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
	display_usage
	exit 0
fi 

# Check if parameter is passed or valid, otherwise terminate the program
if [ ! -f $1 ]; then
	error "File $1 argument does not exist!"
	echo ""
	display_usage
	exit 1
fi

# if no parameter passed, call display_usage and terminate the program
if [ $# -eq 0 ]; then
	error "No argument passed!"
	echo ""
    display_usage
    exit 1
fi


# Check if user has sudo access privelege
info "Checking user's privileges..."
printf "skippass\n" | sudo -S /bin/chmod --help >/dev/null 2>&1
if [ $? -eq 0 ];then
   info  "User " $(whoami) "has sudo access."
else
   error "User " $(whoami) "has no sudo access!"
   display_usage
   exit 1
fi


# Check filename contains / symbol listed in .backup file
chk_filename() {

	STRFILE=$1
	if [[ $STRFILE == *[\/]* ]] && [ -f ${USER_DIRECTORY}/$STRFILE ]
	then
		error "Entry file $STRFILE contains / symbol, file must be placed relative to user folder ${USER_DIRECTORY}"
		BACKUPOK=false
	fi

}


# Iterate base on the number lines entered in userlist text file
while read line; do

	USER=$line

	USER_DIRECTORY=/home/$USER  	

	if [ ! -d $USER_DIRECTORY ]; then
		error "Entry in file $1 user $line, folder " $USER_DIRECTORY " does not exist!"
		BACKUPOK=false
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

 	# Check if /var/backup.tar.gz exist, if existed extract to /tmp/backup once only
	# otherwise copy the users file from /home/[user] to /var/backup
 	if [ -f ${VAR_DIR}/backup.tar.gz ]; then


		if [ "$ISTARFILE_EXTRACTED" = false ]; then

			info "File /var/backup.tar.gz existed"
			# check if /tmp/backup dir exist before extracting,  remove and create
			if [ -d /tmp/backup ]; then 
				# remove the existing files from /tmp/backup if any
				sudo rm -rf /tmp/backup &>$OUTPUTLOG
			fi
			sudo mkdir /tmp/backup

			info "Extracting /var/backup.tar.gz to /tmp/backup once only"
			sudo tar xf ${VAR_DIR}/backup.tar.gz -C $TMP_BACKUP &>$OUTPUTLOG

			# set the switch to true
			ISTARFILE_EXTRACTED=true

		fi

		# Put /home/username/.backup to USER_BACKUP_FILE
		USER_BACKUP_FILE=${USER_DIRECTORY}/$BACKUPFILE

		while read USERFILELINE; do

			# This will contain a value /home/username/filename
			FILE1=${USER_DIRECTORY}/$USERFILELINE

			# This will contain a value /tmp/backup/username/filename
			FILE2=${TMP_BACKUP}/$USER/$USERFILELINE

			# Check filename if contains / special symbol or the file is placed in a subdirectory relative to user directory
			chk_filename ${USERFILELINE}

			# if the same file exist in /tmp/backup/user then start the comparison and renaming of old files
			if [ -f $FILE2 ]; then

				

				if cmp --silent -- "$FILE1" "$FILE2"; then
					info $FILE1 " is identical to " $FILE2
				else
					info $FILE1 " is differ to " $FILE2 ", previous file will be renamed"
					
					counter=1
					until [ ! -f ${FILE2}.$counter ]; do
						# Increment the counter for file renaming
						let counter+=1
						
					done

					# replace the previous with e.g. filename.1 , filename.2 ... 
					info "Renaming ${FILE2} to " ${FILE2}.$counter 
					sudo mv ${FILE2} ${FILE2}.$counter	&>$OUTPUTLOG		

				fi
			

			fi

			# Check if entry in .backup file is existed if not,  log the error
			if [ ! -f $FILE1 ]; then
				error "Entry filename $USERFILELINE in .backup file is not existed!"
				BACKUPOK=false
			else
				# Then copy the original  file from /home/user to /tmp/backup/user/
				info "Copying  $FILE1 to ${TMP_BACKUP}/$USER"
				sudo cp $FILE1 ${TMP_BACKUP}/$USER &>$OUTPUTLOG
			
			fi
			

		done < $USER_BACKUP_FILE


		# Check if /var/backup exist, if not create first
		if [ ! -d ${VAR_DIR}/backup ]; then 
			info "Folder /var/backup  is created"
			sudo mkdir ${VAR_DIR}/backup &>$OUTPUTLOG
		fi

		# remove and create /var/backup/[user]
		VAR_BAK_USER=${VAR_DIR}/backup/$USER
		if [ -d ${VAR_BAK_USER} ]; then 
			sudo rm -rf $VAR_BAK_USER &>$OUTPUTLOG 
		fi
		sudo mkdir $VAR_BAK_USER
		
		# Copying the content of /tmp/backup/[user]/*.* /var/backup/[user]"
		info "Copying the content of " ${TMP_BACKUP}/${USER}/ " to " $VAR_BAK_USER 
		sudo cp ${TMP_BACKUP}/${USER}/*.* $VAR_BAK_USER &>$OUTPUTLOG

 	else

		# Check if /var/backup exist, if not create first
		if [ ! -d ${VAR_DIR}/backup ]; then 
				info "Folder /var/backup folder is created"
				sudo mkdir ${VAR_DIR}/backup &>$OUTPUTLOG
		fi

		# Read each user e.g /home/gino/.backup file and copy to /var/backup/gino/
		VAR_BAK_USER=${VAR_DIR}/backup/$USER
		USER_BACKUP_FILE=${USER_DIRECTORY}/$BACKUPFILE

		info "Creating $VAR_BAK_USER folder"
		if [ ! -d $VAR_BAK_USER ]; then 
				sudo mkdir $VAR_BAK_USER &>$OUTPUTLOG
		fi

		# Read the user .backup file and copy the file listed to /var/backup/$user 
		while read USERFILELINE1; do

			# Check filename if contains / special symbol or the file is placed in a subdirectory relative to user directory
			chk_filename ${USERFILELINE1}

			# FILE1 value is /home/[user]/[filename]
            FILE1=${USER_DIRECTORY}/$USERFILELINE1

			# Check if entry in .backup file is existed if not,  log the error
			if [ ! -f $FILE1 ]; then
				error "Entry filename $USERFILELINE1 in .backup file is not existed!"
				BACKUPOK=false
			else
				# e.g copying /home/gino/file to /var/backup/gino
				info "Copying file ${USER_DIRECTORY}/$USERFILELINE1 to $VAR_BAK_USER"
				sudo cp ${USER_DIRECTORY}/$USERFILELINE1 $VAR_BAK_USER &>$OUTPUTLOG

			
			fi

			
		done < $USER_BACKUP_FILE

 	fi


done < $1


# Creating /var/backup.tar.gz 
echo ""
info "Creating a backup.tar.gz file in /var from /var/backup content"
sudo tar -C $DIRECTORY_TO_BACKUP -cvf ${VAR_DIR}/backup.tar.gz . &>$OUTPUTLOG

# display the list of /var/backup.tar.gz
echo ""
info "Listing the content of /var/backup.tar.gz"
tar --list --file=/var/backup.tar.gz
echo ""

if [ "$ISTARFILE_EXTRACTED" = true ]; then
	info "Backup is successfully completed!"
	info "Details about the output backup file"
	ls -l /var/backup.tar.gz
else
	info "Backup completed with ERROR(S)!"
fi




