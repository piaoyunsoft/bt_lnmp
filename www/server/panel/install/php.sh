#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://download.bt.cn/install/public.sh -T 5;
fi
. $public_file
download_Url=$NODE_URL

run_path="/root"
Is_64bit=`getconf LONG_BIT`
Root_Path=`cat /var/bt_setupPath.conf`
apacheVersion=`cat /var/bt_apacheVersion.pl`
mysql_dir=$Root_Path/server/mysql
mysql_config="${mysql_dir}/bin/mysql_config"
php_path=$Root_Path/server/php
alibabaVer=`cat /etc/redhat-release |grep Alibaba`
isFedora=`cat /etc/redhat-release |grep Fedora`
Centos8Check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')

if [ "${isFedora}" != "" ] || [ "${alibabaVer}" != "" ] || [ "${apacheVersion}" = "2.2" ] || [ "${Centos8Check}" != "" ];then
	wget -O php.sh $download_Url/install/0/php.sh -T 5
	bash php.sh $1 $2
	exit;
fi

centos_version=`cat /etc/redhat-release | grep ' 7.' | grep -i centos`
LibCurlVer=$(/usr/local/curl/bin/curl -V|grep curl|awk '{print $2}'|cut -d. -f2)

if [[ "${LibCurlVer}" -lt "64" ]] || [ "${centos_version}" = "" ] ; then
	wget -O php.sh $download_Url/install/1/old/php.sh -T 5
	bash php.sh $1 $2
	exit;
fi

if [ "${centos_version}" != '' ]; then
	rpm_path="centos7"
else
	rpm_path="centos6"
fi
Set_Php_INI(){
	sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,putenv,chroot,chgrp,chown,shell_exec,popen,proc_open,pcntl_exec,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,imap_open,apache_setenv/g' /www/server/php/${php_version}/etc/php.ini
	sed -i 's/expose_php = On/expose_php = Off/g' /www/server/php/${php_version}/etc/php.ini
	/etc/init.d/php-fpm-${php_version} reload
}
Install_PHP(){
	if [ "${php_version}" = "73" ]; then
		yum install libsodium libsodium-devel -y
	fi
	wget ${download_Url}/rpm/${rpm_path}/${Is_64bit}/bt-php${php_version}.rpm
	rpm -ivh bt-php${php_version}.rpm --force --nodeps
	rm -f bt-php${php_version}.rpm
}

Uninstall_PHP(){
	php_version=${1/./}
	if [ -f "/www/server/php/${php_version}/rpm.pl" ];then
		yum remove -y bt-php${php_version}
		[ ! -f "/www/server/php/${php_version}/bin/php" ] && exit 0;
	fi
	service php-fpm-$php_version stop

	chkconfig --del php-fpm-${php_version}
	chkconfig --level 2345 php-fpm-${php_version} off

	rm -rf $php_path/$php_version
	rm -f /etc/init.d/php-fpm-$php_version

}

actionType=$1
version=$2

if [ "$actionType" == 'install' ];then
	php_version=`echo $version|sed "s/\.//"`
	pkill -9 php-fpm-${php_version}
	rm -f /etc/php-cgi-${php_version}.sock
	Install_PHP
	Set_Php_INI
else 
	if [ "$actionType" == 'uninstall' ];then
	Uninstall_PHP $version
	fi
fi
