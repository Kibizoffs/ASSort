#!/bin/bash

for((i=0; $i<10000; i=$i+100))
do
	if ./buffer_overflow.sh $i | make run > /dev/null
	then
		echo "Size $i: OK"
	else
		echo "Size $i: ERR"
		exit 1
	fi
done

exit 0
