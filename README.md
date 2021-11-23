# cabash
TEST CASES #1 :  no .backup file in /home/gino and /home/ginoruperez  and no /var/backup.tar.gz existed
     OUTPUT   :  /var/backup/gino, /var/backup/ginoruperez, backup.tar.gz are created

TEST CASES #2 : with .backup in /home/gino  contains two files mybash.txt and myscript.txt
                without .backup in /home/ginoruperez  
                backup.tar.gz existed containing empty folders /gino and /ginoruperez

     OUTPUT   : backup.tar.gz created
                /tmp/backup/gino created but empty
                /tmp/backup/ginoruperez created but empty
                /var/backup/gino created and contains mybash.txt and myscript.txt
                /var/backup/ginoruperez created but empty
    

TEST CASE #3   : with .backup in home/gino contains two files mybash.txt and myscript.txt
                 with .backup in home/ginoruperez contains one file  mydata.scp
                 backup.tar.gz existed containing /gino/{withtwofiles}  and empty /ginoruperez 

     OUTPUT    : backup.tar.gz created
                /tmp/backup/gino/{withtwofile}
                /tmp/backup/ginoruperez created but empty
                /var/backup/gino created and contains mybash.txt and myscript.txt
                /var/backup/ginoruperez created and contains mydata.scp
    
                 

