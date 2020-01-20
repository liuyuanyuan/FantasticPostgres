# pgAdmin4 - 搞定安装部署

## 简介

[pgAdmin4](https://link.zhihu.com/?target=https%3A//www.pgadmin.org/) 是开源数据库 [PostgreSQL](https://link.zhihu.com/?target=http%3A//www.postgresql.org/) 的图形管理工具，是桌面版图形管理工具pgAdmin3 的重写，遵循 [PostgreSQL协议](https://link.zhihu.com/?target=https%3A//www.pgadmin.org/licence/) 是开源、免费、可商用可发行的。pgAdmin4 是python开发的web应用程序，既可以部署为web模式通过浏览器访问，也可以部署为桌面模式独立运行。

**以下基于： pgadmin 4.15 + python2.7 + httpd2.4**

## 1 在Centos7 源码安装pgAdmin4(pgadmin4.whl)

**参考：** [http://yallalabs.com/linux/how-to-install-pgadmin-4-in-server-mode-as-web-application-on-centos-7-rhel-7/](https://link.zhihu.com/?target=http%3A//yallalabs.com/linux/how-to-install-pgadmin-4-in-server-mode-as-web-application-on-centos-7-rhel-7/)

##### **1.1安装系统依赖包**

```text
sudo yum install gcc python-devel -y
```

##### **1.2安装python应用开发依赖（python/pip/virtualenv）**

```text
#使用centos7系统自带的python2.7.5，因此不用安装

#安装python2-pip（安装到了系统python中）
sudo yum -y install epel-release
sudo yum install python2-pip
pip —version
##注意：python3配套的是python3-pip

#安装虚拟环境（安装到了系统python中）
pip install virtualenv

#创建虚拟环境（--no-site-packages 已被弃用）
cd /home/centos7/
virtualenv  py2env
#进入虚拟环境
source py2env/bin/activate

#安装依赖模块包
##将pgadmin4/requirements.txt中的psycopg2修改为psycopg2-binary
(py2env) vim ./pgadmin4/requirements.txt
    #psycopg2>=2.8
    psycopg2-binary>=2.8
(py2env) pip install ./pgadmin4/requirements.txt
```

**注意**：

1 pip 安装超时报错：aise ReadTimeoutError(self._pool, None, 'Read timed out.')

可通过更换安装源来解决：pip install -i [https://pypi.douban.com/simple](https://link.zhihu.com/?target=https%3A//pypi.douban.com/simple) <需要安装的包>

2 virtualenvwrapper是virtualenv的扩展包，用于更方便管理虚拟环境，不是必须安装的。

参考[https://www.jianshu.com/p/3abe52adfa2b](https://link.zhihu.com/?target=https%3A//www.jianshu.com/p/3abe52adfa2b)

##### **1.3python编译运行程序**

```text
#创建配置文件和日志文件
(py2env) python ./pgadmin4/web/setup.py
#启动
(py2env) python ./pgadmin4/web/pgAdmin4.py
```

##### **1.4 httpd+mod_wsgi部署pgAdmin4服务**

```text
#安装apache httpd
sudo yum install -y httpd httpd-devel

#在虚拟机环境中安装mod_wsgi
(py2env) ./bin/pip install mod_wsgi

#查看安装路径
(py2env) ./bin/mod_wsgi-express install-module
LoadModule wsgi_module "/usr/lib64/httpd/modules/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so"
WSGIPythonHome "/home/centos8/py3env/“

#配置httpd.conf
vim /etc/httpd/conf/httpd.conf
#末尾添加
LoadModule wsgi_module "/usr/lib64/httpd/modules/mod_wsgi-py36.cpython-27m-x86_64-linux-gnu.so"
WSGIPythonHome "/home/centos7/py2env/"
Listen 5050
<VirtualHost *:5050>
     #ServerName pgadmin.example.com
     #LogLevel debug
     #ErrorLog ${APACHE_LOG_DIR}/pgadmin-error.log
     #CustomLog ${APACHE_LOG_DIR}/pgadmin-access.log combined
     #WSGIDaemonProcess pgadmin processes=1 threads=25 python-home=/home/centos7/py2env/
     WSGIScriptAlias / /home/centos7/py2env/hgadmin4/web/pgAdmin4.wsgi
     <Directory "/home/centos7/py2env/hgadmin4/web/">
         WSGIProcessGroup pgadmin
         WSGIApplicationGroup %{GLOBAL}
         Require all granted
     </Directory>
</VirtualHost>

#检查httpd配置文件修改语法正确性
apachectl configtest
```

##### **1.5 修改pgadmin配置文件的用户访问控制权限**

[https://www.pgadmin.org/docs/pgadmin4/development/config_py.html](https://link.zhihu.com/?target=https%3A//www.pgadmin.org/docs/pgadmin4/development/config_py.html)

```text
注意：默认在非server_mode时以下配置库根目录变为：~/.pgadmin/
#修改配置路径
vim web/config_distro.py
LOG_FILE = '/var/log/pgadmin/pgadmin4.log'
SQLITE_PATH = '/var/lib/pgadmin/pgadmin4.db'
SESSION_DB_PATH = '/var/lib/pgadmin/sessions'
STORAGE_DIR = '/var/lib/pgadmin/storage’

#修改配置文件和库的所属关系（按照httpd.conf中的用户和组）
chown -R apache:apache /var/lib/pgadmin
chown -R apache:apache /var/log/pgadmin

#如果SeLinux开启了，使用以下命令修改SELinux policy（未开启则不需要）:
chcon -R -t httpd_sys_content_rw_t "/var/log/pgadmin/"
chcon -R -t httpd_sys_content_rw_t "/var/lib/pgadmin/"

#查看安装标签设置情况
ls -Z /var/log/pgadmin/ 
##补充：修改selinux安全访问配置的方法
su - root
#永久生效（重启后）
vim /etc/selinux/config 
    SELINUX = disabeld #重启生效
#临时生效
setenforce 0 #即时生效
service iptables stop

#重启apache httpd服务（一般在root下启动）
apachectl restart
apachectl status
```

浏览器浏览: [http://127.0.0.1:5050]()

## 2. 在 win10 源码安装pgAdmin4()

此处使用 [ python2.7.17_32bit + apache2.4.6_32bit + VCForPython27.msi ]

注意：python、httpd必须位数一致（此处皆为32bit），版本协调。

##### **2.1 安装并配置python和pip**

下载python-2.7.17.32.msi，并手动安装到 C:\Python27。（python和pip执行文件位于C:\Python27\Scripts）

```text
 #在系统环境变量path中添加：c:\Python27; C:\Python27\Scripts

 C:\Users\liuyu>python —version
 Python 2.7.17
 C:\Users\liuyu>pip -version
 pip 19.2.3 from  C:\Python27\lib\site-package\pip (python 27)
```

注意：有时C:\Windows\System32路径需要python27.dll文件，如缺失复制进去即可。

##### **2.2 安装并创建虚拟环境**

```text
#安装虚拟环境
C:\>pip install virtualenv
#创建虚拟环境
C:\>virtualenv py2env
#进入虚拟环境
C:\>cd c:\py2env
C:\py2env>Scripts\activate
```

##### **2.3 安装pgAdmin4依赖**

```text
#将pgadmin4源码包拷贝到py2env
git clone https://github.com/postgres/pgadmin4.git pgadmin4

#将pgadmin4依赖模块包安装到虚拟环境
(py2env)C:\py2env>Scripts\pip install -r pgadmin4\requirement.txt

#试运行python程序
(py2env)C:\py2env>Scripts\python.exe pgadmin4\web\setup.py
(py2env)C:\py2env>Scripts\python.exe pgadmin4\web\pgAdmin4.py
Starting pgAdmin 4. Please navigate to http://127.0.0.1:5050 in your browser.
 * Serving Flask app "pgadmin" (lazy loading)
 * Environment: production
   WARNING: Do not use the development server in a production environment.
   Use a production WSGI server instead.
 * Debug mode: off
```

注意：如配置完启动httpd时报错在c:/Windows/System32/找不到python27.dll，可以通过以下方式解决：上网下载python27.dll并放到C:/Windows/System32/；

##### **2.4 安装apache httpd**

手动安装或者解压apache2.4到C:\apache2.4

##### **2.5 安装mod_wsgi**

###### 1 安装mod_wsgi依赖的编译器VCForPython27.mis

下载VCForPython27.mis（mod_wsgi的gcc编译器）到本地系统，使用手动安装或者命令行[静模安装](https://link.zhihu.com/?target=https%3A//baike.baidu.com/item/%E9%9D%99%E9%BB%98%E5%AE%89%E8%A3%85/8559321%3Ffr%3Daladdin)到默认路径即可。其中，命令行如下：

```text
msiexec /i VCForPython27.msi /qb REBOOT=SUPPRESS
```

###### 2 安装mod_wsgi

可以安装到虚拟环境或系统python，也可以安装到apachehttpd的modules目录中，安装到不同位置的引用位置不同。

```text
#设置临时环境变量
(py2env) c:\py2env>set “MOD_WSGI_APACHE_ROOTDIR=C:\apache2.4”

#在虚拟环境中安装mod_wsgi
(py2env) c:\py2env>Scripts\pip.exe install mod_wsgi
Collecting mod_wsgi
  Using cached https://files.pythonhosted.org/packages/25/d8/1df4ba9c051cd88e02971814f0867274a8ac821baf983b6778dacd6e31f7/mod_wsgi-4.6.8.tar.gz
Building wheels for collected packages: mod-wsgi
  Building wheel for mod-wsgi (setup.py) ... done
  Created wheel for mod-wsgi: filename=mod_wsgi-4.6.8-cp27-cp27m-win_amd64.whl size=365468 sha256=74afcaa578aa17be65bc3b19b63419b76f3617992a22ee8c49edaafb7470053b
  Stored in directory: C:\Users\liuyu\AppData\Local\pip\Cache\wheels\14\20\6d\6302d26b9f3a8d84eb8a06e2c418cf807700e3550ded230f8a
Successfully built mod-wsgi
Installing collected packages: mod-wsgi
Successfully installed mod-wsgi-4.6.8

#查看mod_wsgi安装配置情况
(py2env) c:\py2env>Scripts\mod_wsgi-express.exe --help
Usage: mod_wsgi-express command [params]
Commands:
    module-config
    module-location
(py2env) c:\py2env>Scripts\mod_wsgi-express.exe module-config
LoadModule wsgi_module "c:/py2env/lib/site-packages/mod_wsgi/server/mod_wsgi.pyd"
WSGIPythonHome "c:/py2env”
```

##### **2.6 将pgAdmin4.wsgi配置到httpd.conf**

在C:\apache2.4\conf\httpd.conf 末尾加入(或者配置在单独的pgamin4.conf文件)以下内容：

```text
#config pgadmin4
LoadModule wsgi_module “C:/py2env/lib/site-packages/mod_wsgi/server/mod_wsgi.pyd"
WSGIPythonHome “C:/py2env"

<VirtualHost *:80>
    ServerName pgadmin4.highgo.com
    WSGIScriptAlias / C:\py2env\pgadmin4\web\pgAdmin4.wsgi
    <Directory  C:\py2env\pgadmin4\web\>
            # Order deny,allow
            # Allow from all
            Require all granted
    </Directory>
</VirtualHost>
```

##### **2.7 启动httpd服务**

```text
#双击或者命令行启动httpd.exe
C:\apache2.4\bin>httpd.exe
(如正确则不返回任何信息，报错则返回甚至退出）
```

##### **2.8 访问pgAdmin4网页**

浏览器访问 [http://localhost:80/]()

![pgadmin4_welcome](images/pgadmin4_welcome.png)