# cabash
PREREQUISITE : userlist.txt   
				 - gino
				 - ginoruperez

TEST CASES #1 :  run the ./rmbk to make no .backup file in /home/gino and /home/ginoruperez  and no /var/backup.tar.gz existed

     OUTPUT   :  /var/backup/gino, /var/backup/ginoruperez are created 
	 			 /var/backup.tar.gz is created and with empty two folders (/gino and /ginoruperez)
	 			 no /tmp/backup created
	 			 /home/gino/.backup and /home/ginoruperez/.backup created

	 COMMANDS : ll -Rt /var/backup
	 			ll -Rt /tmp/backup
	 			tar --list --file=/var/backup.tar.gz
				ll /home/gino/.backup /home/ginoruperez/.backup 


TEST CASES #2 : with .backup in /home/gino  contains two files mybash.txt and myscript.txt    commands: sudo vim /home/gino/.backup
                with .backup in /home/ginoruperez  but empty
                backup.tar.gz existed containing empty folders /gino and /ginoruperez

     OUTPUT   : backup.tar.gz created containing /gino/{withtwofiles}  and empty /ginoruperez 
                /tmp/backup/gino created and contains two files mybash.txt and myscript.txt
                /tmp/backup/ginoruperez created but empty
                /var/backup/gino created and contains mybash.txt and myscript.txt
                /var/backup/ginoruperez created but empty
    

TEST CASE #3   : with .backup in home/gino contains two files mybash.txt and myscript.txt
                 with .backup in home/ginoruperez contains one file  mydata.scp           command : sudo vim /home/ginoruperez/.backup
                 backup.tar.gz existed containing /gino/{withtwofiles}  and empty /ginoruperez 

     OUTPUT  	: backup.tar.gz created contains /gino with two files and /ginoruperez with one file
                /tmp/backup/gino/{create with two files  mybash.txt and myscript.txt}
                /tmp/backup/ginoruperez/{ created with mydata.scp }
                /var/backup/gino created and contains mybash.txt and myscript.txt
                /var/backup/ginoruperez created and contains mydata.scp

TEST CASE #4	: Having the output from test case 3, modify /home/gino/mybash.txt    (run this for 3 times)

	OUTPUT 		: backup.tar.gz created contains /gino with two files and /ginoruperez with one file
                /tmp/backup/gino/{create with 3 files  mybash.txt, mybash.txt.1 and myscript.txt} NOTE: mybash should have 4 entries .1 .2 .3 and original mybash.txt
                /tmp/backup/ginoruperez/{ created with mydata.scp }
                /var/backup/gino created and contains mybash.txt and myscript.txt
                /var/backup/ginoruperez created and contains mydata.scp
				  
                 
TEST CASE #5	: reset them all by running ./rmbk  to remove all test samples
				  create .backup in /home/gino with  content mybash.txt
				  create .backup in /home/ginoruperez with content mydata.scp, notfound.file  and /home/ginoruperez/mydata/personal.txt
				  modify userlist.txt add Tess
				  

	OUTPUT		: /var/backup/gino is create with one file mybash.txt
				  /var/backup/ginoruperez is created  with tw files mydata.scp and personal.txt
				  display WARNING for personal.txt, it will be backup relative to user folder instead, will not be compared 
				  display ERROR for notfound.file:
				  display ERROR for Tess 
	 			  /var/backup.tar.gz is created and with  two folders (/gino/withonefile and /ginoruperez/withtwofiles  )
	 			  no /tmp/backup created
	 			  /home/gino/.backup and /home/ginoruperez/.backup created


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