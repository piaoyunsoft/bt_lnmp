#!/bin/bash
# chkconfig: 2345 55 25
# description: bt Cloud Service

### BEGIN INIT INFO
# Provides:          bt
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts bt
# Description:       starts the bt
### END INIT INFO
panel_path=/www/server/panel
pidfile=$panel_path/logs/panel.pid
cd $panel_path
py26=$(python -V 2>&1|grep '2.6.')
if [ "$py26" != "" ];then
	pythonV=python3
fi
panel_start()
{
        isStart=`ps aux|grep 'runserver:app'|grep -v grep|awk '{print $2}'`
        if [ "$isStart" == '' ];then
                echo -e "Starting Bt-Panel.\c"
				rm -f $pidfile
                gunicorn -c runconfig.py runserver:app
                port=$(cat /www/server/panel/data/port.pl)
				isStart=""
				n=0
				while [[ "$isStart" == "" ]];
				do
					echo -e ".\c"
					sleep 0.5
					isStart=$(lsof -n -P -i:$port|grep LISTEN|grep -v grep|awk '{print $2}'|xargs)
					let n+=1
					if [ $n -gt 8 ];then
						break;
					fi
				done
                if [ "$isStart" == '' ];then
                        echo -e "\033[31mfailed\033[0m"
                        echo '------------------------------------------------------'
                        tail -n 20 $panel_path/logs/error.log
                        echo '------------------------------------------------------'
                        echo -e "\033[31mError: BT-Panel service startup failed.\033[0m"
                fi
                echo -e "	\033[32mdone\033[0m"
        else
                echo "Starting Bt-Panel... Bt-Panel (pid $(echo $isStart)) already running"
        fi
        
        isStart=$(ps aux |grep 'task.py'|grep -v grep|awk '{print $2}')
        if [ "$isStart" == '' ];then
                echo -e "Starting Bt-Tasks... \c"
                nohup python task.py >> /www/server/panel/logs/task.log 2>&1 &
                sleep 0.2
                isStart=$(ps aux |grep 'task.py'|grep -v grep|awk '{print $2}')
                if [ "$isStart" == '' ];then
                        echo -e "\033[31mfailed\033[0m"
                        echo '------------------------------------------------------'
                        tail -n 20 /www/server/panel/logs/task.log
                        echo '------------------------------------------------------'
                        echo -e "\033[31mError: BT-Task service startup failed.\033[0m"
                        return;
                fi
                echo -e "	\033[32mdone\033[0m"
        else
                echo "Starting Bt-Tasks... Bt-Tasks (pid $isStart) already running"
        fi
}

panel_stop()
{
	echo -e "Stopping Bt-Tasks...\c";
    pids=$(ps aux | grep 'task.py'|grep -v grep|awk '{print $2}')
    arr=($pids)

    for p in ${arr[@]}
    do
            kill -9 $p
    done
    echo -e "	\033[32mdone\033[0m"

    echo -e "Stopping Bt-Panel...\c";
    arr=`ps aux|grep 'runserver:app'|grep -v grep|awk '{print $2}'`
	for p in ${arr[@]}
    do
            kill -9 $p &>/dev/null
    done
    
    if [ -f $pidfile ];then
    	rm -f $pidfile
    fi
    echo -e "	\033[32mdone\033[0m"
}

panel_status()
{
        port=$(cat /www/server/panel/data/port.pl)
        isStart=$(lsof -i:$port|grep LISTEN|grep -v grep|awk '{print $2}'|xargs)
        if [ "$isStart" != '' ];then
                echo -e "\033[32mBt-Panel (pid $(echo $isStart)) already running\033[0m"
        else
                echo -e "\033[31mBt-Panel not running\033[0m"
        fi
        
        isStart=$(ps aux |grep 'task.py'|grep -v grep|awk '{print $2}')
        if [ "$isStart" != '' ];then
                echo -e "\033[32mBt-Task (pid $isStart) already running\033[0m"
        else
                echo -e "\033[31mBt-Task not running\033[0m"
        fi
}

panel_reload()
{
	isStart=$(ps aux|grep 'runserver:app'|grep -v grep|awk '{print $2}')
    
    if [ "$isStart" != '' ];then
    	echo -e "Reload Bt-Panel.\c";
	    arr=`ps aux|grep 'runserver:app'|grep -v grep|awk '{print $2}'`
		for p in ${arr[@]}
        do
                kill -9 $p
        done
		rm -f $pidfile
        gunicorn -c runconfig.py runserver:app
		port=$(cat /www/server/panel/data/port.pl)
		isStart=""
		n=0
		while [[ "$isStart" == "" ]];
		do
			echo -e ".\c"
			sleep 0.5
			isStart=$(lsof -n -P -i:$port|grep LISTEN|grep -v grep|awk '{print $2}'|xargs)
			let n+=1
			if [ $n -gt 8 ];then
				break;
			fi
		done
        if [ "$isStart" == '' ];then
                echo -e "\033[31mfailed\033[0m"
                echo '------------------------------------------------------'
                tail -n 20 $panel_path/logs/error.log
                echo '------------------------------------------------------'
                echo -e "\033[31mError: BT-Panel service startup failed.\033[0m"
                return;
        fi
        echo -e "	\033[32mdone\033[0m"
    else
        echo -e "\033[31mBt-Panel not running\033[0m"
        panel_start
    fi
}

install_used()
{
        if [ ! -f $panel_path/aliyun.pl ];then
                return;
        fi
        password=$(cat /dev/urandom | head -n 16 | md5sum | head -c 12)
        username=$($pythonV $panel_path/tools.py panel $password)
        echo "$password" > $panel_path/default.pl
        rm -f $panel_path/aliyun.pl
}

error_logs()
{
	tail -n 100 $panel_path/logs/error.log
}


case "$1" in
        'start')
                install_used
                panel_start
                ;;
        'stop')
                panel_stop
                ;;
        'restart')
                panel_stop
                panel_start
                ;;
        'reload')
                panel_reload
                ;;
        'status')
                panel_status
                ;;
        'logs')
        		error_logs
        		;;
        'panel')
        		python $panel_path/tools.py cli $2
        		;;
        'default')
                port=$(cat $panel_path/data/port.pl)
                password=$(cat $panel_path/default.pl)
                if [ -f $panel_path/data/domain.conf ];then
                	address=$(cat $panel_path/data/domain.conf)
                fi
                if [ -f $panel_path/data/admin_path.pl ];then
                	auth_path=$(cat $panel_path/data/admin_path.pl)
                fi
                if [ "$address" = "" ];then
                	address=$(curl -sS --connect-timeout 10 -m 60 https://www.bt.cn/Api/getIpAddress)
                fi
				pool=http
				if [ -f $panel_path/data/ssl.pl ];then
					pool=https
				fi
                echo -e "=================================================================="
                echo -e "\033[32mBT-Panel default info!\033[0m"
                echo -e "=================================================================="
                echo  "Bt-Panel-URL: $pool://$address:$port$auth_path"
                echo -e `python $panel_path/tools.py username`
                echo -e "password: $password"
                echo -e "\033[33mWarning:\033[0m"
                echo -e "\033[33mIf you cannot access the panel, \033[0m"
                echo -e "\033[33mrelease the following port (8888|888|80|443|20|21) in the security group\033[0m"
                echo -e "=================================================================="
                ;;
        *)
                python $panel_path/tools.py cli $1
        ;;
esac


