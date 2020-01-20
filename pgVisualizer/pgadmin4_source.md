## pgAdmin4 - 搞定源码架构

## 简介

[pgAdmin4](https://link.zhihu.com/?target=https%3A//www.pgadmin.org/) 是开源数据库 [PostgreSQL](https://link.zhihu.com/?target=http%3A//www.postgresql.org/) 的图形管理工具，是桌面版图形管理工具pgAdmin3 的重写，遵循 [PostgreSQL协议](https://link.zhihu.com/?target=https%3A//www.pgadmin.org/licence/) 是开源、免费、可商用可发行的。pgAdmin4 是python开发的web应用程序，既可以部署为web模式通过浏览器访问，也可以部署为桌面模式独立运行。

**以下基于： pgadmin 4.15**

## 功能图谱

![](/Users/liuyuanyuan/github/PostgresAdmin/images/pgadmin4.15-features.png)

## 系统架构

pgAdmin4 is a web application in python:

- Front End/client GUI:

- - HTML5+CSS3
  - Bootstrap: for UI look and feel
  - Backbone: for data manipulation of a node
  - jQuery/Backform: for generating properties/create dialog for selected node

- Backend/server:

- - python v2.7+/v3.4+
  - Flask (python framework)

- SQLite3 db: store registered servers and Preference settings

- - SQLITE_PATH = os.path.join(DATA_DIR, 'pgadmin4.db')

- configuration file:

- - LOG_FILE = os.path.join(DATA_DIR, 'pgadmin4.log')
  - SESSION_DB_PATH = os.path.join(DATA_DIR, 'sessions')
  - STORAGE_DIR = os.path.join(DATA_DIR, 'storage')

## 源码概览

参考： [pgAdmin4 github](https://link.zhihu.com/?target=https%3A//github.com/postgres/pgadmin4.git)   [pgAdmin4 overview doc](https://link.zhihu.com/?target=https%3A//www.pgadmin.org/docs/pgadmin4/4.11/code_overview.html%23configuration)

下载源码：

```git
git clone https://github.com/postgres/pgadmin4.git
```

源码文件树（部分）：

```shell
Yolandas-MacBook-Pro:pgadmin4 liuyuanyuan$ tree -L 1
pgadmin4
├── Dockerfile
├── LICENSE 
├── Make.bat
├── Makefile
├── README
├── docs    
├── libraries.txt            
├── pkg
├── requirements.txt  # dependencies to be installed by pip
├── runtime           # modified using the QT Creator application
├── tools
└── web
    ├── __pycache__
    ├── babel.cfg
    ├── config.py  # core configuration(config.py>config_distro.py>config_local.py)    
    ├── karma.conf.js
    ├── migrations
    ├── node_modules
    ├── package.json
    ├── pgAdmin4.py   
    ├── pgAdmin4.wsgi 
    ├── pgadmin    # heart of pgadmin4 contains globally HTML template and static files
    │   ├── __init__.py # constructor to handle the work of the package
    │   ├── __pycache__
    │   ├── about
    │   ├── browser    # tree browser of all db object node
    │   ├── dashboard  # dashboard for welcome/server/database
    │   ├── feature_tests
    │   ├── help
    │   ├── messages.pot 
    │   ├── misc
    │   ├── model
    │   ├── preferences
    │   ├── redirects
    │   ├── settings
    │   ├── setup
    │   ├── static     # core bundle/css/fonts/img/js/scss
    │   ├── templates
    │   ├── tools
    │   ├── translations # i18n 
    │   └── utils
    ├── pgadmin.themes.json
    ├── regression
    ├── servers.json # dependencies to be installed by yarn 
    ├── setup.py    # create the database file and schema within it
    ├── webpack.config.js
    ├── webpack.shim.js
    ├── webpack.test.config.js
    └── yarn.lock
```

## 核心与模块

**pgAdmin 的核心部分在pgadmin包中。**

pgadmin包中包含Jinja引擎使用的全局可用HTML模板，以及在多个模块中使用的所有全局静态文件，例如图像、Javascript和CSS文件。

程序包的工作是在其构造函器__init__.py中进行的。它负责设置日志记录和身份验证，动态加载其他模块以及其他一些任务。

**pgAdmin 通过模块添加功能单元。**

通过添加模块将功能单元添加到pgAdmin中。这些是Python的类的对象实例，继承Web/pgadmin/utils.py中的PgAdminModule类（一个Flask Blueprint实现）。它为其他模块（主要是默认模块-**browser**）提供了各种挂钩点。

要被识别为模块，必须创建一个Python包，必须遵守以下要求：

- 放置在web/pgadmin /目录下；
- 并且实现pgadmin.utils.PgAdminModule类；
- 一个实例变量（通常称为blueprint）表示该包中的特定类。

每个模块可以为其实现的Blueprint定义**template**和**static**目录。为避免名称冲突，模板应存储在指定模板目录下的目录下，该目录以模块本身命名。例如，**browser**模块将其模板存储在web/pgadmin/browser/templates/browser /中。这不适用于可能忽略第二个模块名称的静态文件。