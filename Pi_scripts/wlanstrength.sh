#!/bin/bash
dummy=0
sum1=0
movingAverage1=0
count=0
skipCount=0
declare -a window1

window1[0]=0
window1[1]=0
window1[2]=0
window1[3]=0
window1[4]=0
window1[5]=0
window1[6]=0
window1[7]=0

avgMovingAvg=0
avgSkipCount=0
#python3 picam.py &

while true
do
dev1=`iw wlan0 scan | egrep 'SSID|signal' | egrep -B1 "Redmi" | grep "signal" | grep -Eo '[0-9]+([.][0-9]+)?'`

dev1Num=$(awk '{print $1+$2}' <<<"${dev1} ${dummy}")

sum1=$(expr $sum1 - ${window1[count]})

window1[count]=$dev1Num;

sum1=$(expr $sum1 + ${window1[count]})

skipCount=$(expr $skipCount + 1)
count=$(expr $count + 1)
count=$(expr $count % 3)

movingAverage1=$(expr $sum1 / 3)

if [[ $skipCount -gt 10 ]]
then

        avgMovingAvg=$(expr $movingAverage1 + $avgMovingAvg)
        avgSkipCount=$(expr $avgSkipCount + 1)
        if [ $(( $avgSkipCount % 3 )) -eq 0 ]
        then
                avgMovingAvg=$(expr $avgMovingAvg / 3)
                echo "$avgMovingAvg" >> /dev/ttyACM0
				# Store in Log file for debugging 
                echo "$avgMovingAvg" >> /home/pi/data.txt
                avgMovingAvg=0
        fi
fi

#sleep 0.1
done
