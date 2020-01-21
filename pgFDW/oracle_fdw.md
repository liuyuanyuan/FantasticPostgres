# oracle_fdw - 从PG操作Oracle

## 简介

[oracle_fdw](https://pgxn.org/dist/oracle_fdw/)是PostgreSQL的一个外部数据接口，可以使PostgreSQL轻松跨库操作Oracle。

要求PostgreSQL是 9.1 及更高版本。从 9.2开始支持ANALYZE；从9.3开始支持INSERT、UODATE 和 DELETE。

要求Oracle客户端是10.1及更高版本。基于Oracle Instant Client ，或者 带有Universal Installer的Oracle Client和Server的安装，Oracle_fdw可以进行创建和使用。通过Oracle Client 10 编译的二进制文件，可以被更高版本的客户端使用，而不需要recompilation 或者 relink。

## **环境**

一个windows xp(32bit)虚拟机，装有oracle11g。本文假设该oracle服务器安装完毕，可远程访问，ip为192.168.100.234。

一个centos（32bit）linux虚拟机，用来安装postgresql，oracle客户端，oracle_fdw。(本文所有操作在此进行)

## 一、源码编译安装PostgreSQL

下载PostgreSQL源码安装包并解压，本文使用的： postgresql-9.4.4.tar.gz

编译安装（注意：编译时使用--without-ldap）

```text
/configure --prefix=/opt/pgsql --with-pgport=5432--with-segsize=8 --with-wal-segsize=64 --with-wal-blocksize=64 --with-perl  --without-openssl --without-pam --without-ldap  --enable-thread-safety
gmake world
gmake install -world

cd /opt/pgsql
mkdir data

useradd -m postgres
passwd postgres
chown postgres data

su - postgres
cd ..
cd bin
./initdb  -D ../data  --locale=C  -U postgres
./pg_ctl start -D ../data
./psql
```

添加环境变量：

```text
vi /etc/profile
```

在文件末尾添加

```text
export PG_HOME=/opt/pgsql
Esc
:w
:q
source /etc/profile
```

## 二、安装oracle database instant client客户端

官方介绍和安装指导：[http://www.oracle.com/technetwork/database/features/instant-client/index-100365.html](https://link.zhihu.com/?target=http%3A//www.oracle.com/technetwork/database/features/instant-client/index-100365.html)

官方下载地址：[http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html](https://link.zhihu.com/?target=http%3A//www.oracle.com/technetwork/database/features/instant-client/index-097480.html)

安装过程：

1. 下载：basic/sdk/sqlplus三个安装包， 一定要与操作系统和位数(32bit或64bit)符合,本文使用的是：

instantclient-basic-linux-12.1.0.2.0 .zip

instantclient-sdk-linux-12.1.0.2.0.zip

instantclient-sqlplus-linux-12.1.0.2.0.zip

2. 创建一个oracle客户端的目录/opt/oracle，

3. 将三个压缩包解压后，将所有文件直接拷贝到/opt/oracle/下面.

4. 在/opt/oracle/下面创建配置文件tnsname.ora

```text
    cd /opt/oracle
    vi tnsname.ora
```

添加内容：

```text
    MYDB =
     (DESCRIPTION =
        (ADDRESS_LIST =
            (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.100.234)(PORT=1521))
          )
       (CONNECT_DATA=(SID=orcl)(SERVER = DEDICATED))
      ）
```

5. 配置关于oracle客户端的环境变量

```text
vi /etc/profile
```

添加以下内容

```text
    export ORACLE_HOME=/opt/oracle;
    export SQLPATH=/opt/oracle;
    export TNS_ADMIN=/opt/oracle;
    export LD_LIBRARY_PATH=$ORACLE_HOME:$LD_LIBRARY_PATH;
    export PATH=$PATH:$ORACLE_HOME;
    source /opt/profile
```

6. 创建oracle用户，并对客户端目录授权

```text
    groupadd oinstall
    useradd － g oinstall oracle
    passwd oracle
    chown -R oracle:oinstall /opt/oracle
    chmod -R 775 /usr/oracle
```

7. 使用客户端进行连接测试

```text
su - oracle
cd /opt/oracle
[oracle@localhost oracle]$ sqlplus lyy/lyy@//192.168.100.234:1521/orcl
SQL*Plus: Release 12.1.0.2.0 Production on Sun Sep 6 19:32:12 2015
Copyright (c) 1982, 2014, Oracle.  All rights reserved.
Connected to:
Oracle Database 11g Enterprise Edition Release 11.2.0.1.0 - Production
With the Partitioning, OLAP, Data Mining and Real Application Testing options
SQL>
```

此时oracle客户端配置完毕并连接成功。

注意：错误[sqlplus: error while loading shared ](https://link.zhihu.com/?target=https%3A//my.oschina.net/liuyuanyuangogo/blog/502090)来解决。

## 三、源码编译安装oracle_fdw

官方源码地址：[http://pgfoundry.org/frs/?group_id=1000600](https://link.zhihu.com/?target=http%3A//pgfoundry.org/frs/%3Fgroup_id%3D1000600)

官方安装包下载、安装指导、使用说明、常见问题地址：[http://pgxn.org/dist/oracle_fdw/](https://link.zhihu.com/?target=http%3A//pgxn.org/dist/oracle_fdw/)

1. 下载源码并阅读安装说明.

官方下载和使用说明地址：[http://pgxn.org/dist/oracle_fdw/](https://link.zhihu.com/?target=http%3A//pgxn.org/dist/oracle_fdw/)

本文下载的是：oracle_fdw-1.2.0.zip

要确保与postgresql安装的操作系统及其位数(32bit或64bit)匹配。

2. 解压压缩包并配置Makefile

查找pg_config位置

```text
[root@oracle_fdw-1.2.0]# find / -name pg_config/opt/PostgresPlus/9.3AS/bin/pg_config
```

更改oracle_fdw-0.9.9文件夹里的Makefile文件，指定pg_config位置

```text
[root@oracle_fdw-1.2.0]# cat Makefile | grep PG_CONFIG
```

改为PG_CONFIG=$PG_HOME/bin/pg_config（更改文件的路径）

3. 编译并安装(必须是root用户下)

直接在oracle_fdw-1.2.0目录下执行：

[root@localhost oracle_fdw-1.2.0]# **make**

```text
gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -O2 -fpic -shared -o oracle_fdw.so oracle_fdw.o oracle_utils.o oracle_gis.o -L/opt/pgsql/lib  -Wl,-rpath,'/opt/pgsql/lib',--enable-new-dtags  -L/opt/oracle -L/opt/oracle/bin -L/opt/oracle/lib -lclntsh -L/usr/lib/oracle/12.1/client/lib -L/usr/lib/oracle/12.1/client64/lib -L/usr/lib/oracle/11.2/client/lib -L/usr/lib/oracle/11.2/client64/lib -L/usr/lib/oracle/11.1/client/lib -L/usr/lib/oracle/11.1/client64/lib -L/usr/lib/oracle/10.2.0.5/client/lib -L/usr/lib/oracle/10.2.0.5/client64/lib -L/usr/lib/oracle/10.2.0.4/client/lib -L/usr/lib/oracle/10.2.0.4/client64/lib -L/usr/lib/oracle/10.2.0.3/client/lib -L/usr/lib/oracle/10.2.0.3/client64/lib
```

[root@localhost oracle_fdw-1.2.0]# **ldd oracle_fdw.so**

```text
        linux-gate.so.1 =>  (0x007e6000)
        libclntsh.so.12.1 => /opt/oracle/libclntsh.so.12.1 (0x007e7000)
        libc.so.6 => /lib/libc.so.6 (0x00248000)
        libnnz12.so => /opt/oracle/libnnz12.so (0x04873000)
        libons.so => /opt/oracle/libons.so (0x00110000)
        libdl.so.2 => /lib/libdl.so.2 (0x00144000)
        libm.so.6 => /lib/libm.so.6 (0x005e4000)
        libpthread.so.0 => /lib/libpthread.so.0 (0x00671000)
        libnsl.so.1 => /lib/libnsl.so.1 (0x00149000)
        librt.so.1 => /lib/librt.so.1 (0x00162000)
        /lib/ld-linux.so.2 (0x0022b000)
        libaio.so.1 => /usr/lib/libaio.so.1 (0x0016b000)
        libclntshcore.so.12.1 => /opt/oracle/libclntshcore.so.12.1 (0x02b7c000)
```

[root@localhost oracle_fdw-1.2.0]# **make install**

```text
/bin/mkdir -p '/opt/pgsql/lib'
/bin/mkdir -p '/opt/pgsql/share/extension'
/bin/mkdir -p '/opt/pgsql/share/extension'
/bin/mkdir -p '/opt/pgsql/share/doc/extension'
/usr/bin/install -c -m 755  oracle_fdw.so '/opt/pgsql/lib/oracle_fdw.so'
/usr/bin/install -c -m 644 oracle_fdw.control '/opt/pgsql/share/extension/'
/usr/bin/install -c -m 644 oracle_fdw--1.1.sql oracle_fdw--1.0--1.1.sql '/opt/pgsql/share/extension/'
/usr/bin/install -c -m 644 README.oracle_fdw '/opt/pgsql/share/doc/extension/'
```

出现以上信息说明orale_fdw编译安装完成。

**常见错误：**在make时遇到错误cannot find -lclntsh：

```text
/usr/bin/ld: cannot find -lclntsh
collect2: ld returned 1 exit status
make: *** [oracle_fdw.so] Error 1
```

**解决办法**：到oracle客户端的目录下，为libclntsh.so创建指向libclntsh.so.12.1的软链接。

```text
[postgres@localhost bin]$ su - root
Password: 
[root@localhost ~]# cd /opt/oracle/
--创建软连接
[root@localhost oracle]# ln -s libclntsh.so.12.1 libclntsh.so
--查看指向情况
[root@localhost oracle]# ll
total 175420
-rwxrwxr-x 1 oracle oinstall     24706 Jul  8  2014 adrci
-rwxrwxr-x 1 oracle oinstall       438 Jul  8  2014 BASIC_README
-rwxrwxr-x 1 oracle oinstall     33309 Jul  8  2014 genezi
-rwxrwxr-x 1 oracle oinstall       342 Jul  8  2014 glogin.sql
-rwxrwxr-x 1 oracle oinstall   5520733 Jul  8  2014 libclntshcore.so.12.1
lrwxrwxrwx 1 root   root            17 Sep  6 23:02 libclntsh.so -> libclntsh.so.12.1
-rwxrwxr-x 1 oracle oinstall  45817130 Jul  8  2014 libclntsh.so.12.1
-rwxrwxr-x 1 oracle oinstall   5323903 Jul  8  2014 libnnz12.so
-rwxrwxr-x 1 oracle oinstall   1958194 Jul  8  2014 libocci.so.12.1
-rwxrwxr-x 1 oracle oinstall 109543276 Jul  8  2014 libociei.so
-rwxrwxr-x 1 oracle oinstall    183705 Jul  8  2014 libocijdbc12.so
-rwxrwxr-x 1 oracle oinstall    268133 Jul  8  2014 libons.so
-rwxrwxr-x 1 oracle oinstall     81153 Jul  8  2014 liboramysql12.so
-rwxrwxr-x 1 oracle oinstall   1561437 Jul  8  2014 libsqlplusic.so
-rwxrwxr-x 1 oracle oinstall   1299573 Jul  8  2014 libsqlplus.so
drwxrwxr-x 3 oracle oinstall      4096 Sep  6 20:16 oci
-rwxrwxr-x 1 oracle oinstall   3692096 Jul  8  2014 ojdbc6.jar
-rwxrwxr-x 1 oracle oinstall   3698857 Jul  8  2014 ojdbc7.jar
drwxrwxr-x 5 oracle oinstall      4096 Jul  8  2014 sdk
-rwxrwxr-x 1 oracle oinstall      7353 Jul  8  2014 sqlplus
-rwxrwxr-x 1 oracle oinstall       442 Jul  8  2014 SQLPLUS_README
-rwxrwxr-x 1 oracle oinstall    172720 Jul  8  2014 uidrvci
-rwxrwxr-x 1 oracle oinstall     71202 Jul  8  2014 xstreams.jar
--查看libclntsh.so.12.1所调用的库
[root@localhost oracle_fdw-1.2.0]# ldd /opt/oracle/libclntsh.so.12.1 
        linux-gate.so.1 =>  (0x00a30000)
        libnnz12.so => /opt/oracle/libnnz12.so (0x00248000)
        libons.so => /opt/oracle/libons.so (0x00110000)
        libdl.so.2 => /lib/libdl.so.2 (0x00144000)
        libm.so.6 => /lib/libm.so.6 (0x00149000)
        libpthread.so.0 => /lib/libpthread.so.0 (0x00172000)
        libnsl.so.1 => /lib/libnsl.so.1 (0x0018c000)
        librt.so.1 => /lib/librt.so.1 (0x00937000)
        libc.so.6 => /lib/libc.so.6 (0x0069f000)
        /lib/ld-linux.so.2 (0x0022b000)
        libaio.so.1 => /usr/lib/libaio.so.1 (0x001a5000)
        libclntshcore.so.12.1 => /opt/oracle/libclntshcore.so.12.1 (0x083b1000)
--操作完毕即可重新执行make和make install
```

## 四、PostgreSQL配置oracle_fdw

```text
[root@localhost oracle_fdw-1.2.0]# cd /opt/oracle/
[root@localhost oracle]# cp libclntsh.so.12.1 /opt/pgsql/lib/
[root@localhost oracle]# cp libnnz12.so /opt/pgsql/lib/
[root@localhost oracle]# chown .daemon /opt/pgsql/lib/libclntsh.so.12.1 
[root@localhost oracle]# chown .daemon /opt/pgsql/lib/libnnz12.so
```

## 五、在PostgreSQL中使用oracle_fdw

```text
[postgres@localhost bin]$ ./psql
psql (9.4.4)
Type "help" for help.
postgres=# create extension oracle_fdw;
CREATE EXTENSION
postgres=# create server oracledb foreign data wrapper oracle_fdw options(dbserver '//192.168.100.234:1521/orcl');
CREATE SERVER
postgres=# create user oracle_fdw superuser password 'oracle';
CREATE ROLE
postgres=# create user mapping for oracle_fdw server oracledb options (user 'lyy',password 'lyy');
CREATE USER MAPPING
postgres=# create foreign table oracle_lyy(id int, name varchar) server oracledb options(schema 'lyy', table 'LYY');--注意oracle中表名一般为大写
CREATE FOREIGN TABLE
postgres=# \q

[postgres@localhost bin]$ ./psql -U oracle_fdw -d postgres
psql (9.4.4)
Type "help" for help.
postgres=# select * from oracle_lyy;
 id |         name         
----+----------------------
  1 | ddd                 
(1 row)
```

此后，在oracle中对lyy表的操作提交后，PostgreSQL中oracle_lyy也会更新。在PostgreSQL中对oracle_lyy表的操作提交后，Oracle中lyy也会更新。

## 六、oracle_fdw在PostgreSQL中使用的常见错误

详细请参阅官方问题列表: problem [http://pgxn.org/dist/oracle_fdw/](https://link.zhihu.com/?target=http%3A//pgxn.org/dist/oracle_fdw/)

**错误举例：**

```text
Encoding
--------

Characters stored in an Oracle database that cannot be converted to the PostgreSQL database encoding will silently be replaced by "replacement characters", typically a normal or inverted question mark, by Oracle.You will get no warning or error messages.

If you use a PostgreSQL database encoding that Oracle does not know
(currently, these are EUC_CN, EUC_KR, LATIN10, MULE_INTERNAL, WIN874
and SQL_ASCII), non-ASCII characters cannot be translated correctly.
You will get a warning in this case, and the characters will be replaced
by replacement characters as described above.

You can set the "nls_lang" option of the foreign data wrapper to force a
certain Oracle encoding, but the resulting characters will most likely be
incorrect and lead to PostgreSQL error messages.  This is probably only
useful for SQL_ASCII encoding if you know what you are doing.
See "Options" above.
```

PotgreSQL初始化时指定--locale-C（该编码oracle不识别），之后使用oracle_fdw会出现，如下错误：

```text
postgres=# select * from oracle_lyy;
WARNING:  no Oracle character set for database encoding "SQL_ASCII"
DETAIL:  All but ASCII characters will be lost.
HINT:  You can set the option "nls_lang" on the foreign data wrapper to force an Oracle character set.
WARNING:  no Oracle character set for database encoding "SQL_ASCII"
```

只能重新初始化一个可以支持的编码的库，比如--locale=en_US.utf8.