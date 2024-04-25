#!/bin/bash

NUM_SYMBOLS=$1

for((i=0; $i < $NUM_SYMBOLS; i= $i+1))
do
	echo -n "A"
done

echo '!'
echo "-:fin:-"

exit 0

