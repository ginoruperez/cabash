# cabash
TEST CASES #1 :  no .backup file in /home/gino and /home/ginoruperez  and no /var/backup.tar.gz existed
     OUTPUT   :  /var/backup/gino, /var/backup/ginoruperez, /var/backup.tar.gz are created and empty two folders (/gino and /ginoruperez)

TEST CASES #2 : with .backup in /home/gino  contains two files mybash.txt and myscript.txt
                without .backup in /home/ginoruperez  
                backup.tar.gz existed containing empty folders /gino and /ginoruperez

     OUTPUT   : backup.tar.gz created containing /gino/{withtwofiles}  and empty /ginoruperez 
                /tmp/backup/gino created but empty
                /tmp/backup/ginoruperez created but empty
                /var/backup/gino created and contains mybash.txt and myscript.txt
                /var/backup/ginoruperez created but empty
    

TEST CASE #3   : with .backup in home/gino contains two files mybash.txt and myscript.txt
                 with .backup in home/ginoruperez contains one file  mydata.scp
                 backup.tar.gz existed containing /gino/{withtwofiles}  and empty /ginoruperez 

     OUTPUT    : backup.tar.gz created contains /gino with two files and /ginoruperez with one file
                /tmp/backup/gino/{withtwofile}
                /tmp/backup/ginoruperez created but empty
                /var/backup/gino created and contains mybash.txt and myscript.txt
                /var/backup/ginoruperez created and contains mydata.scp
    
                 

LEARNING 


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