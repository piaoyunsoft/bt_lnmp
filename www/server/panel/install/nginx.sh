#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8
public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://download.bt.cn/install/public.sh -T 5;
fi
. $public_file
download_Url=$NODE_URL

Is_64bit=`getconf LONG_BIT`
centos_version=`cat /etc/redhat-release | grep ' 7.' | grep -i centos`
if [ "${centos_version}" = '' ] || [ "${Is_64bit}" = "32" ]; then
	wget -O nginx.sh ${download_Url}/install/0/nginx.sh && sh nginx.sh $1 $2
	exit;
fi
if [ "${centos_version}" != '' ]; then
	rpm_path="centos7"
else
	rpm_path="centos6"
fi
Setup_Path="/www/server/nginx"
Install_Jemalloc(){
	if [ ! -f '/usr/local/lib/libjemalloc.so' ]; then
		wget -O jemalloc-5.0.1.tar.bz2 ${download_Url}/src/jemalloc-5.0.1.tar.bz2
		tar -xvf jemalloc-5.0.1.tar.bz2
		cd jemalloc-5.0.1
		./configure
		make && make install
		ldconfig
		cd ..
		rm -rf jemalloc*
	fi
}
Install_cjson()
{
	if [ ! -f /usr/local/lib/lua/5.1/cjson.so ];then
		wget -O lua-cjson-2.1.0.tar.gz $download_Url/install/src/lua-cjson-2.1.0.tar.gz -T 20
		tar xvf lua-cjson-2.1.0.tar.gz
		rm -f lua-cjson-2.1.0.tar.gz
		cd lua-cjson-2.1.0
		make
		make install
		cd ..
		rm -rf lua-cjson-2.1.0
	fi
}
Install_LuaJIT()
{
	if [ ! -d '/usr/local/include/luajit-2.0' ];then
		yum install libtermcap-devel ncurses-devel libevent-devel readline-devel -y
		wget -c -O LuaJIT-2.0.4.tar.gz ${download_Url}/install/src/LuaJIT-2.0.4.tar.gz -T 5
		tar xvf LuaJIT-2.0.4.tar.gz
		cd LuaJIT-2.0.4
		make linux
		make install
		cd ..
		rm -rf LuaJIT-*
		export LUAJIT_LIB=/usr/local/lib
		export LUAJIT_INC=/usr/local/include/luajit-2.0/
		ln -sf /usr/local/lib/libluajit-5.1.so.2 /usr/local/lib64/libluajit-5.1.so.2
		echo "/usr/local/lib" >> /etc/ld.so.conf
		ldconfig
	fi
}
Install_Nginx(){
	Uninstall_Nginx
	if [ -f "/www/server/panel/vhost/nginx/btwaf.conf" ]; then
		if [ ! -f "/www/server/btwaf/waf.lua" ]; then
			rm -f /www/server/panel/vhost/nginx/btwaf.conf
		fi
	fi
	wget ${download_Url}/rpm/${rpm_path}/${Is_64bit}/bt-${nginxVersion}.rpm 
	rpm -ivh bt-${nginxVersion}.rpm --force --nodeps
	rm -f bt-${nginxVersion}.rpm
	echo ${nginxVersion} > ${Setup_Path}/rpm.pl
	if [ "${version}" == "tengine" ]; then
		echo "-Tengine2.2.3" > ${Setup_Path}/version.pl
	elif [ "${version}" == "openresty" ]; then
		echo "openresty" > ${Setup_Path}/version.pl
	else
		echo "${ngxVer}" > ${Setup_Path}/version.pl
	fi
}

Uninstall_Nginx(){
	/etc/init.d/nginx stop
	chkconfig --del nginx
	chkconfig --level 2345 nginx off
	if [ -f "${Setup_Path}/rpm.pl" ]; then
		yum remove bt-$(cat ${Setup_Path}/rpm.pl) -y
	fi
	rm -f /etc/init.d/nginx
	rm -rf /www/server/nginx
	
}

actionType=$1
version=$2

if [ "$actionType" == 'install' ];then
	nginxVersion="tengine"
	if [ "${version}" == "1.10" ] || [ "${version}" == "1.12" ]; then
		nginxVersion="nginx112"
		ngxVer="1.12.2"
	elif [ "${version}" == "1.14" ]; then
		nginxVersion="nginx114"
		ngxVer="1.14.2"
	elif [ "${version}" == "1.15" ]; then
		nginxVersion="nginx115"
		ngxVer="1.15.10"
	elif [ "${version}" == "1.16" ]; then
		nginxVersion="nginx116"
		ngxVer="1.16.0"
	elif [ "${version}" == "1.17" ]; then
		nginxVersion="nginx117"
		ngxVer="1.17.0"
	elif [ "${version}" == "1.8" ]; then
		nginxVersion="nginx108"
		ngxVer="1.8.1"
	elif [ "${version}" == "openresty" ]; then
		nginxVersion="openresty"
	else
		version="tengine"
	fi
	Install_Jemalloc
	Install_cjson
	Install_LuaJIT
	Install_Nginx
else 
	if [ "$actionType" == 'uninstall' ];then
	Uninstall_Nginx
	fi
fi
