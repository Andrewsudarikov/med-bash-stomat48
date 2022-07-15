#!/bin/bash
rm -f /файл/логов.txt #чистим файл логов если он был
rm -f /файл/отключенных/компьютеров.txt #расстрельный список если он был
rm -f /список/для/команд.txt #список для команд expect если он был
hosts="/список/хостов.txt" #файл вида "ip-адрес mac-адрес" подготовленный заранее
LOG="/файл/логов.txt" #запись логов 
TOP="/список/для/команд.txt" #список адресов для выполнения expect
M=0 #переменная в которую будет записываться mac адрес
PASS="парольрута"
for IP in $(cut -d ' ' -f1 $hosts) #идем по списку хостов
do
    ping -c 1 $IP &> /dev/null 
    if [[ $? -ne 0 ]] #если результат выполнения предыдущей команды не успех
	then 
	    M=$(grep $IP $hosts | cut -d ' ' -f2) #находим мак адрес
	    wakeonlan -p 8 $M &> /dev/null #кастуем пробуждение
	    echo "$IP" >> /файл/спящих/компьютеров.txt
	else echo "$IP" >> $TOP
    fi
done
for I in $(cat /файл/спящих/компьютеров.txt) #смотрим кто проснулся
do 
    ping -c 1 $I &> /dev/null
    if [[ $? -ne 0 ]]
	then echo "$I" >> /файл/отключенных/компьютеров.txt
	else echo "$I" >> $TOP
    fi
done

#подключение и выполнение команд
for H in $(cat $TOP)
do
echo START >> $LOG
COMM="
set timeout 5
spawn ssh пользователь@$H
#логинимся
expect \"*(yes/no)?*\" {send \"yes\r\"}
expect \"password:\" {send \"парольпользователя\r\"}
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
#выключение компов что мы разбудили
for S in $(cat /файл/спящих/компьютеров.txt)
do
    grep $S /файл/отключенных/компьютеров.txt &> /dev/null
	if [[ $? -ne 0 ]]
	then COMM="
	set timeout 5
	spawn ssh пользователь@$S
	#логинимся
	expect \"*(yes/no)?*\" {send \"yes\r\"}
	expect \"password:\" {send \"1\r\"}
	expect \"*>\"
	send \"su-\r\"
	expect \"Password:\" {send \"$PASS\r\"}

	#здесь могли быть ваши команды
	expect \"*#\"
	send \"poweroff\r\"
	expect eof
	"
	expect -c "$COMM" >> $LOG
    fi
done
rm -f /home/admin/1.txt #чистим файл для wol, т.к. он больше не нужен
