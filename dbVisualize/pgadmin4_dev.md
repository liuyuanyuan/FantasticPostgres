# pgAdmin4 - 搞定开发环境

## 简介

[pgAdmin4](https://link.zhihu.com/?target=https%3A//www.pgadmin.org/) 是开源数据库 [PostgreSQL](https://link.zhihu.com/?target=http%3A//www.postgresql.org/) 的图形管理工具，是桌面版图形管理工具pgAdmin3 的重写，遵循 [PostgreSQL协议](https://link.zhihu.com/?target=https%3A//www.pgadmin.org/licence/) 是开源、免费、可商用的。pgAdmin4 是python开发的web应用程序，既可以部署为web模式通过浏览器访问，也可以部署为桌面模式独立运行。

**以下基于： centos7 + python2.7 + pgadmin 4.15  。**

## 在centos7上搭建开发环境

#### **1 配置python开发环境**

注意：

```shell
#系统依赖（安装到系统环境）
sudo yum install gcc python-devel -y 

#安装python应用开发依赖（python/pip/virtualenv）
##使用centos7系统自带的python2.7即可 

#安装python2-pip（安装到系统python中） 
sudo yum -y install epel-release 
sudo yum install python2-pip 
pip —version 
##注意：python3配套的是python3-pip 

#安装虚拟环境（安装到系统python中） 
pip install virtualenv 

#创建虚拟环境（ 注意--no-site-packages已被弃用） 
cd /home/centos7/ 
virtualenv  py2env 
#激活并进入虚拟环境 
source py2env/bin/activate 

#下载pgadmin4源码（此处下载到虚拟环境文件夹下）
git clone https://github.com/postgres/pgadmin4.git pgadmin4

#安装pgdmin4依赖模块包（安装到虚拟环境中） 
##将pgadmin4/requirements.txt中的psycopg2修改为psycopg2-binary 
(py2env) vim ./pgadmin4/requirements.txt 
    psycopg2-binary>=2.8 #psycopg2>=2.8 
(py2env) pip install ./pgadmin4/requirements.txt 
```

**注意**：

1 pip 安装超时 

如报错： aise ReadTimeoutError(self._pool, None, 'Read timed out.')

可通过更换安装源来解决： pip install -i [https://pypi.douban.com/simple](https://link.zhihu.com/?target=https%3A//pypi.douban.com/simple) <需安装的包> 

2 virtualenvwrapper是virtualenv的扩展包，用于方便管理虚拟环境，此处不是必须安装的，仅virtualenv即可满足。参考 [https://www.jianshu.com/p/3abe52adfa2b](https://link.zhihu.com/?target=https%3A//www.jianshu.com/p/3abe52adfa2b)

**关于虚拟环境：**

虚拟环境是为python应用方便搭建独立依赖环境，避免多个应用间依赖包及其版本冲突。

虚拟环境中pip安装的依赖包在lib/site-packsages/底下；

虚拟环境中的python和pip，安装到 ./bin/或者./Scripts/中，pip执行文件中存储了python绝对路径位置，每次使用该python启动pip；activate脚本将该路径临时添加到环境变量path里，并且临时声明了其他环境变量，供虚拟环境方便使用；deactivate脚本中抹去了这些临时环境变量；如需离线移植虚拟环境文件后复用，需要修该activate脚本中配置VIRTUAL_ENV路径，以及修改pip配置的python路径：linux下可通过修改./bin/python-config，win下可以用[hex eidtor](https://link.zhihu.com/?target=https%3A//blog.csdn.net/testcs_dn/article/details/54176504)（如[wxMEdit](https://link.zhihu.com/?target=https%3A//wxmedit.github.io/downloads.html)）[修改./Scripts/pip.exe](https://link.zhihu.com/?target=https%3A//stackoverflow.com/questions/24627525/fatal-error-in-launcher-unable-to-create-process-using-c-program-files-x86/24627797%2324627797)。

虚拟环境2个特殊命令：

```text
#创建虚拟环境时,可以通过-p指定创建虚拟环境所使用的python（在有多个系统python并存🔟可用）
virtualenv -p C:\Python2.7\python.exe py2env

#将pip依赖包安装文件(*.whl)下载到指定路径：
#c:\py2download\whls\为保存安装包的路径，不存在会被创建；requirement.txt为前一步生成的包列表文件
pip download -d  [c:\py2download\whls\]  -r [requirement.txt]
```

#### **2 python运行pgAdmin4**

```text
#安装配置库和配置文件 
(py2env) python ./pgadmin4/web/setup.py 
#启动应用pgadmin4
(py2env) python ./pgadmin4/web/pgAdmin4.py 
#browse: http://localhost:5050/
```

#### **3 系统前端开发**

安装前端开发开发工具

```text
#安装nodejs相关工具（setup_12.x表示v12版本的） 
curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash - 
#如果下载过慢，则安装淘宝镜像cnpm，然后再执行 
npm install -g cnpm --registry=https://registry.npm.taobao.org 
 
yum install -y nodes 
yum install gcc-c++ make 
curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo 
yum install -y yarn 
#安装git，因为yarn install常用到git 
yum install -y git 
```

下载和管理前端资源

```text
#以下在源码包根目录下执行
cd ./pgadmin4/  

#下载package.json中的依赖包（初次下载完成后，仅依赖修改后才需执行）
make install-node 

#整合前端资源（每次前端修改后要执行该命令才能生效）
make bundle 
```

**注意**

错误：前端依赖资源下载缓慢/失败/报错fetchmetadata:sill pacote range manifest for buf

解决：

1 清理缓存npm cache clean 或 npm cache clean —force，或者删掉web/node-module，然后再执行安装。

2 更换新的安装源来下载依赖

```text
#查看当前安装源
npm config get registry 
#临时（安装时）换源：
npm install --registry=https://registry.npm.taobao.org 
#永久换源
npm config set registry http://registry.npm.taobao.org
```

常用安装源：

- https://registry.npm.taobao.org

- http://registry.npm.alibaba-inc.com

#### **4 系统国际化和本地化开发**

4.1 系统语言选择

通过preference的语言模块进行设置；

4.2 源码中字符串的国际化

源码中使用gettext('msgid')来通过msgid（即英文字符串）调用本地化字符串（如中文）；

4.3 国际化和本地化更新

更新i18n和l10n的命令：

```text
#step1: extract msgid from all file（gettext()） to messages.pot
make msg-extract

#step2: update .po file from messages.pot to translation
make msg-update

#step3: compile .po to .mo file
make msg-compile
```

4.4 本地化资源文件位置

```text
./pgadmin4/web/pgadmin/messages.pot
./pgadmin4/web/pgadmin/translations/zh/messages.po/messages.mo
```

#### **5 安装包打包工具QT安装（gpl协议，非必须）**

```text
#下载
wget http://download.qt.io/official_releases/qt/5.9/5.9.5/qt-opensource-linux-x64-5.9.5.run
#给下载的文件赋予可执行的权限
chmod +x qt-opensource-linux-x64-5.9.5.run
#执行文件，进行安装
./qt-opensource-linux-x64-5.9.5.run
#安装依赖
yum -y install mesa-libGL-devel mesa-libGLU-devel freeglut-devel
#将./qt4/bin/加入系统环境变量PATH中并生效
#终端中输入qtcreator可以打开图形界面
./qtcreator
```

