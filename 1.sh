#!/bin/bash
rm -f /home/admin/per.txt #чистим файл логов
rm -f /home/admin/1.txt #чистим файл для wol
rm -f /home/admin/2.txt #расстрельный список
rm -f /home/admin/good.txt #список для команд expect
hosts="/home/admin/mac.txt" #файл вида ip_mac
LOG="/home/admin/per.txt"
TOP="/home/admin/good.txt"
M=0
PASS="____"
for IP in $(cut -d ' ' -f1 $hosts)
do
    ping -c 1 $IP &> /dev/null
    if [[ $? -ne 0 ]] #если результат выполнения предыдущей команды не успех
	then 
	    M=$(grep $IP $hosts | cut -d ' ' -f2)
	    wakeonlan -p 8 $M &> /dev/null
	    echo "$IP" >> /home/admin/1.txt
	else echo "$IP" >> $TOP
    fi
done
for I in $(cat /home/admin/1.txt) #смотрим кто проснулся
do 
    ping -c 1 $I &> /dev/null
    if [[ $? -ne 0 ]]
	then echo "$I" >> /home/admin/2.txt
	else echo "$I" >> $TOP
    fi
done

#подключение и выполнение команд
for H in $(cat $TOP)
do
echo START >> $LOG
COMM="
set timeout 5
spawn ssh user1@$H
#логинимся
expect \"*(yes/no)?*\" {send \"yes\r\"}
expect \"password:\" {send \"1\r\"}
expect \"*>\"
send \"su-\r\"
expect \"Password:\" {send \"$PASS\r\"}

#здесь могли быть ваши команды
expect \"*#\"
send \"uname -a\r\"
expect \"*#\"
send \"exit\r\"
send \"exit\r\"
expect eof
"
expect -c "$COMM" >> $LOG
echo ======================================= >> $LOG
done
