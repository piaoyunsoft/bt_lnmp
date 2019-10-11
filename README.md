# bt_lnmp 基于宝塔面板的LNMP环境

## 下载必要文件

<https://github.com/piaoyunsoft/bt_lnmp.git> 里面的www目录就是宝塔初始化需要的目录，将其挂载到容器里面使数据持久化，下面将进行映射。

## 启动容器

* 方法1：

```
docker run -i -t -d --name bt_lnmp_test -p 20:20 -p 21:21 -p 80:80 -p 443:443 -p 888:888 -p 8888:8888 --privileged=true -v $PWD/www:/www piaoyun/bt_lnmp:1.0 bash /start.sh
```

* 方法2：

```
docker-compose up -d
```

##  面板入口：http://IP:8888/admin

```
用户名：piao
密码：baota1234
数据库root密码：baota1234
```

切记：每次启动面板，需要进入后台手动启动Nginx、PHP和MySQL服务


