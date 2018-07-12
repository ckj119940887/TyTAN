#! /bin/bash

FIND_SYM="zeroriscy_config.sv";
FILE_NAME="";

if test -e name_list; then
	echo ;
else 
	touch name_list;
	ls -1 |grep .sv > name_list;
fi

FILE_NUM=`wc -l name_list | cut -d' ' -f1`

i=1;
while [ ${i} -le ${FILE_NUM} ];do
	FILE_NAME=`sed "${i}p" -n name_list`;
	echo ${FILE_NAME};
	cat ${FILE_NAME} |grep -n ${FIND_SYM};
	echo "";
	let i=i+1;
done;



