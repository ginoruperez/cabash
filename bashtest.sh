!/bin/bash
current=`pwd`
rm -rf ./sh
listing=$( ls )
mkdir sh
for i in $listing; do
 if [ -d $i ] ; then
cd $i
for j in $( ls *.sh 2>/dev/null ); do
if [ -f $current/sh/$j ]; then
echo $j exists in target directory;
count=1
while [ -f $current/sh/$j.$count ]; do
echo $j.$count exists in target directory;
let count++
done
cp $j $current/sh/$j.$count;
else
cp $j $current/sh;
fi
done;
cd $current
fi;
done;