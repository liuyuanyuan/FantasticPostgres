# Netdata 

### 简介

**Netdata** is **distributed, real-time, performance and health monitoring for systems and applications**. It is a highly optimized monitoring agent you install on all your systems and containers.

- OS: 仅支持Linux

- [Github 源码](https://github.com/netdata/netdata)
- [Github wiki](https://github.com/netdata/netdata/wiki)

- [安装 Netdata](https://docs.netdata.cloud/zh/packaging/installer/)



1 collect data via plugin

src(C) use /proc、/sys and other Linux kernal file system to collect data；
python.d(python) work with bash and conf file to collect data, include collecting postgres data;
fping.plugin use bash to fping any hosts and get lagency, packet loss and uptime information.
node.d(nodejs) use to collect data;
alarm send email or slack  by alarm-notify.sh。
and so on.

Hint:
=plugins.d [bash]=
type: #!/usr/bin/env bash

Linux下#!/usr/bin/env bash和#!/usr/bin/bash、#!/bin/bash的比较
#!/usr/bin/env bash #在不同的系统上提供了一些灵活性。
#!/usr/bin/bash #将对给定的可执行文件系统进行显式控制。

通过/usr/bin/env运行程序，用户不需要去寻找程序在系统中的位置（因为在不同的系统，命令或程序存放的位置可能不同），只要程序在你的$PATH中；
通过/usr/bin/env运行程序另一个好处是，它会根据你的环境寻找并运行默认的版本，提供灵活性。
不好的地方是，有可能在一个多用户的系统中，别人在你的$PATH中放置了一个bash，可能出现错误。

大部分情况下，/usr/bin/env 是优先选择的，因为它提供了灵活性，特别是你想在不同的版本下运行这个脚本；
而指定具体位置的方式#!/usr/bin/bash，在某些情况下更安全，因为它限制了代码注入的可能。
可能在一些系统上/usr/bin/bash没有，而/bin/bash则一定存在的。所以/bin/bash是显示指定的优先选择。

2 internal API to manange data collection

3 metric database：

缺省是将一小时数据保存在内存中，这种情况下监控的内存和cpu消耗都很低；
如果想保留几小时的历史数据可以启用KSM，因为netdata的写频率很低，所以KSM能够节省60%以上内存；
如果想要保留更长时间的历史数据，最好将数据存储到时间序列数据库中， 可以使用graphite, opentsdb, prometheus, influxdb, kairosdb等。

4 use REST Http API to provide json data to front(via Swagger)

5 hashboard.js

6 dashboard.css

7 dashboard.html
TV Client: tv.html

===Front Postgres Metrics===
Performance metrics for PostgresSQL, the object-relational database (ORDBMS).

==DB(all db, a set of charts per db)
Current connection to db (postgres_local.postgres_db_stat_connections)

Transaction on db (postgres_local.postgres_db_stat_transactions)
    Number of rows inserted/updated/deleted.
    conflicts: number of queries canceled due to conflicts with recovery in this database. (Conflicts occur only on standby servers; see pg_stat_database_conflicts for details.)

Tuples written to dbL postgres(postgres_local.postgres_db_stat_tuple_write)

Tuples returned from db: postgres (postgres_local.postgres_db_stat_tuple_returned)
    Blocks reads from disk or cache.
	blks_read: number of disk blocks read in this database.
	blks_hit: number of times disk blocks were found already in the buffer cache, so that a read was not necessary (this only includes hits in the PostgreSQL buffer cache, not the operating system's file system cache)

Disk blocks reads from db: postgres (postgres_local.postgres_db_stat_blks)
    Temporary files can be created on disk for sorts, hashes, and temporary query results.

Temp files written to disk: postgres (postgres_local.postgres_db_stat_temp_bytes)
   files: number of temporary files created by queries. All temporary files are counted, regardless of why the temporary file was created (e.g., sorting or hashing).

Temp files written to disk: postgres (postgres_local.postgres_db_stat_temp_files)

Locks on db: postgres (postgres_local.postgres_locks)

=DB SIZE(all db in one chart)
=backend processes
=wal
=wal writes
=archive wal
=checkpointer
=bgwriter
=autovacuum


install steps
--------------------------------------------------------------
step1: update centos7
yum -y update
step2:
 bash <(curl -Ss https://my-netdata.io/kickstart.sh) all

*[error and resolve]If cannot download and Failed connect to raw.githubusercontent.com:443
download kickstart.sh
download install-required-packages.sh
edit kickstart.sh to change url="file:///root/Desktop/install-required-packages.sh"
and run again: bash kickstart.sh all
*[error and resolve] yum install nodejs and no package nodejs available
wget nodejs 
unzip
add nodejs/bin to root's /etc/profile PATH, source /etc/profile

step3:install pg10 by binary installer
config pg_hba.conf and change local to trust(if not provid password to netdata).
postgres remote access config:
host  all  all  0.0.0.0/0  md5

step4:config netdata postgresql.conf
vi /etc/netdata/python.d/postgres.conf  
socket:  
    name     : 'local'  
    user     ：'postgres'  
    password : 'postgres'  
    database : 'highgo' 

tcp: 
    name     : 'local'  
    database : 'postgres'  
    user     : 'postgres'  
    password : 'postgres'  # if not provide password then must config postgres trust
    host     : 'locahost'  
    port     : 5432  

tcpipv4:  
    name     : 'local'  
    database : 'postgres'  
    user     : 'postgres'  
    host     : '127.0.0.1'  
    port     : 5432  

tcpipv6:  
    name     : 'local'  
    database : 'postgres'  
    user     : 'postgres'  
    host     : '::1'  
    port     : 5432  

step5：
systemctl enable netdata.service
systemctl restart netdata.service

step6: 
browse: http://localhost:19999/index
[after config postgres.conf then you can see [Postgres local] on the right navigation bar.]

You can get the running config file at any time, by accessing:
http://127.0.0.1:19999/netdata.conf.

remote visit need config firewall:
centos7 close fire wall:
systemctl stop firewalld
systemctl disable firewalld

step7:debug
/usr/libexec/netdata/plugins.d/python.d.plugin
after running this file, debug logs will output to your terminal.

step8: see logs
cd /var/log/netdata/

step9：memory mode and data directory
You can select the memory mode by editing netdata.conf and setting:
[global]
    # ram, save (the default, save on exit, load on start), map (swap like)
    memory mode = save
    # the directory where data are saved
    cache directory = /var/cache/netdata
    
step10: Custom Dashboards

https://github.com/firehol/netdata/wiki/Custom-Dashboards



## API details

http://192.168.100.170:19999/api/v1/allmetrics
http://192.168.100.170:19999/api/v1/data?chart=system.io&format=array&points=300&group=average&gtime=0&options=absolute|jsonwrap|nonzero&after=-300&dimensions=in&_=1528694866751
{
   "api": 1,
   "id": "system.io",
   "name": "system.io",
   "view_update_every": 1,
   "update_every": 1,
   "first_entry": 1528692202,
   "last_entry": 1528696198,
   "before": 1528696198,
   "after": 1528695899,
   "dimension_names": ["in"],
   "dimension_ids": ["in"],
   "latest_values": [0],
   "view_latest_values": [0],
   "dimensions": 1,
   "points": 300,
   "format": "array",
   "result": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
 "min": 0,
 "max": 0
}



## Install  details

root@localhost Desktop]# bash <(curl -Ss https://my-netdata.io/kickstart.sh) all
System            : Linux
Operating System  : GNU/Linux
Machine           : x86_64
BASH major version: 4
 --- Downloading script to detect required packages... --- 
[/root/Desktop]# /usr/bin/curl https://raw.githubusercontent.com/firehol/netdata-demo-site/master/install-required-packages.sh 
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 41916  100 41916    0     0  74976      0 --:--:-- --:--:-- --:--:-- 75118
 OK   


 --- Running downloaded script to detect required packages... --- 
[/root/Desktop]# /usr/bin/bash /tmp/netdata-kickstart-j85D17 netdata-all 
Loading /etc/os-release ...
You should have EPEL enabled to install all the prerequisites.
Check: http://www.tecmint.com/how-to-enable-epel-repository-for-rhel-centos-6-5/

/etc/os-release information:
NAME            : CentOS Linux
VERSION         : 7 (Core)
ID              : centos
ID_LIKE         : rhel fedora
VERSION_ID      : 7

We detected these:
Distribution    : centos
Version         : 7
Codename        : 7 (Core)
Package Manager : install_yum
Packages Tree   : centos
Detection Method: /etc/os-release
Default Python v: 2 

WARNING
package autoconf-archive is not available in this system.
You may try to install without it.

 > Checking if package 'zlib-devel' is installed...
 > Checking if package 'libuuid-devel' is installed...
 > Checking if package 'libmnl-devel' is installed...
 > Checking if package 'nodejs' is installed...
 > Checking if package 'PyYAML' is installed...
WARNING
package python-pymongo is not available in this system.
You may try to install without it.

 > Checking if package 'MySQL-python' is installed...
 > Checking if package 'python-psycopg2' is installed...

The following command will be run:

 >> IMPORTANT << 
    Please make sure your system is up to date
    by running:   yum update  

yum install nodejs 
[/usr/src/netdata.git]# /usr/bin/git fetch --all 
Fetching origin
 OK   

[/usr/src/netdata.git]# /usr/bin/git reset --hard origin/master 
HEAD is now at 7da8ccf Merge pull request #3776 from l2isbad/py2_monotonic_time
 OK   

 --- Re-installing netdata... --- 
[/usr/src/netdata.git]# ./netdata-updater.sh -f 
Thu Jun  7 19:09:56 PDT 2018 : INFO:  Running on a terminal - (this script also supports running headless from crontab)

Thu Jun  7 19:09:56 PDT 2018 : INFO:  Updating netdata source from github...
Already up-to-date.

Thu Jun  7 19:09:59 PDT 2018 : INFO:  Re-installing netdata...

  ^
  |.-.   .-.   .-.   .-.   .  netdata                                        
  |   '-'   '-'   '-'   '-'   real-time performance monitoring, done right!  
  +----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+--->


  You are about to build and install netdata to your system.

  It will be installed at these locations:

   - the daemon     at /usr/sbin/netdata
   - config files   in /etc/netdata
   - web files      in /usr/share/netdata
   - plugins        in /usr/libexec/netdata
   - cache files    in /var/cache/netdata
   - db files       in /var/lib/netdata
   - log files      in /var/log/netdata
   - pid file       at /var/run/netdata.pid
   - logrotate file at /etc/logrotate.d/netdata

  This installer allows you to change the installation path.
  Press Control-C and run the same command with --help for help.


 --- Run autotools to configure the build environment --- 
[/usr/src/netdata.git]# ./autogen.sh 
autoreconf: Entering directory `.'
autoreconf: configure.ac: not using Gettext
autoreconf: running: aclocal --force -I m4
autoreconf: configure.ac: tracing
autoreconf: configure.ac: not using Libtool
autoreconf: running: /usr/bin/autoconf --force
autoreconf: running: /usr/bin/autoheader --force
autoreconf: running: automake --add-missing --copy --force-missing
autoreconf: Leaving directory `.'
 OK   

[/usr/src/netdata.git]# ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --with-zlib --with-math --with-user=netdata CFLAGS=-O2 
.
.
.
.
.
 --- Restore user edited netdata configuration files --- 
[/usr/src/netdata.git]# cp -a /etc/netdata/netdata.conf.installer_backup..30032 /etc/netdata/netdata.conf 
 OK   

[/usr/src/netdata.git]# rm -f /etc/netdata/netdata.conf.installer_backup..30032 
 OK   

[/usr/src/netdata.git]# cp -a /etc/netdata/python.d.conf.installer_backup..30032 /etc/netdata/python.d.conf 
 OK   

[/usr/src/netdata.git]# rm -f /etc/netdata/python.d.conf.installer_backup..30032 
 OK   

[/usr/src/netdata.git]# cp -a /etc/netdata/health_alarm_notify.conf.installer_backup..30032 /etc/netdata/health_alarm_notify.conf 
 OK   

[/usr/src/netdata.git]# rm -f /etc/netdata/health_alarm_notify.conf.installer_backup..30032 
 OK   

 --- Fix generated files permissions --- 
[/usr/src/netdata.git]# find ./system/ -type f -a \! -name \*.in -a \! -name Makefile\* -a \! -name \*.conf -a \! -name \*.service -a \! -name \*.logrotate -exec chmod 755 \{\} \; 
 OK   

 --- Add user netdata to required user groups --- 
Group 'netdata' already exists.
User 'netdata' already exists.
Group 'docker' does not exist.
Group 'nginx' does not exist.
Group 'varnish' does not exist.
Group 'haproxy' does not exist.
User 'netdata' is already in group 'adm'.
Group 'nsd' does not exist.
Group 'proxy' does not exist.
Group 'squid' does not exist.
Group 'ceph' does not exist.
 --- Install logrotate configuration for netdata --- 
[/usr/src/netdata.git]# chmod 644 /etc/logrotate.d/netdata 
 OK   

 --- Read installation options from netdata.conf --- 

    Permissions
    - netdata user     : netdata
    - netdata group    : netdata
    - web files user   : netdata
    - web files group  : netdata
    - root user        : root
    
    Directories
    - netdata conf dir : /etc/netdata
    - netdata log dir  : /var/log/netdata
    - netdata run dir  : /var/run
    - netdata lib dir  : /var/lib/netdata
    - netdata web dir  : /usr/share/netdata/web
    - netdata cache dir: /var/cache/netdata
    
    Other
    - netdata port     : 19999

 --- Fix permissions of netdata directories (using user 'netdata') --- 
[/usr/src/netdata.git]# chown -R root:netdata /etc/netdata 
 OK   

[/usr/src/netdata.git]# find /etc/netdata -type f -exec chmod 0640 \{\} \; 
 OK   

[/usr/src/netdata.git]# find /etc/netdata -type d -exec chmod 0755 \{\} \; 
 OK   

[/usr/src/netdata.git]# chown -R netdata:netdata /usr/share/netdata/web 
 OK   

[/usr/src/netdata.git]# find /usr/share/netdata/web -type f -exec chmod 0664 \{\} \; 
 OK   

[/usr/src/netdata.git]# find /usr/share/netdata/web -type d -exec chmod 0775 \{\} \; 
 OK   

[/usr/src/netdata.git]# chown -R netdata:netdata /var/lib/netdata 
 OK   

[/usr/src/netdata.git]# chown -R netdata:netdata /var/cache/netdata 
 OK   

[/usr/src/netdata.git]# chown -R netdata:netdata /var/log/netdata 
 OK   

[/usr/src/netdata.git]# chmod 755 /var/log/netdata 
 OK   

[/usr/src/netdata.git]# chown netdata:root /var/log/netdata 
 OK   

[/usr/src/netdata.git]# chown -R root /usr/libexec/netdata 
 OK   

[/usr/src/netdata.git]# find /usr/libexec/netdata -type d -exec chmod 0755 \{\} \; 
 OK   

[/usr/src/netdata.git]# find /usr/libexec/netdata -type f -exec chmod 0644 \{\} \; 
 OK   

[/usr/src/netdata.git]# find /usr/libexec/netdata -type f -a -name \*.plugin -exec chmod 0755 \{\} \; 
 OK   

[/usr/src/netdata.git]# find /usr/libexec/netdata -type f -a -name \*.sh -exec chmod 0755 \{\} \; 
 OK   

[/usr/src/netdata.git]# chown root:netdata /usr/libexec/netdata/plugins.d/apps.plugin 
 OK   

[/usr/src/netdata.git]# chmod 0750 /usr/libexec/netdata/plugins.d/apps.plugin 
 OK   

[/usr/src/netdata.git]# setcap cap_dac_read_search\,cap_sys_ptrace+ep /usr/libexec/netdata/plugins.d/apps.plugin 
 OK   

[/usr/src/netdata.git]# chown root:netdata /usr/libexec/netdata/plugins.d/cgroup-network 
 OK   

[/usr/src/netdata.git]# chmod 4750 /usr/libexec/netdata/plugins.d/cgroup-network 
 OK   

[/usr/src/netdata.git]# chown root /usr/libexec/netdata/plugins.d/cgroup-network-helper.sh 
 OK   

[/usr/src/netdata.git]# chmod 0550 /usr/libexec/netdata/plugins.d/cgroup-network-helper.sh 
 OK   

[/usr/src/netdata.git]# chmod a+rX /usr/libexec 
 OK   

[/usr/src/netdata.git]# chmod a+rX /usr/share/netdata 
 OK   

 --- Install netdata at system init --- 
file '/etc/systemd/system/netdata.service' already exists.
 --- Start netdata --- 
[/usr/src/netdata.git]# /usr/bin/systemctl stop netdata 
 OK   

[/usr/src/netdata.git]# /usr/bin/systemctl restart netdata 
 OK   

OK. NetData Started!

 --- Check KSM (kernel memory deduper) --- 

Memory de-duplication instructions

You have kernel memory de-duper (called Kernel Same-page Merging,
or KSM) available, but it is not currently enabled.

To enable it run:

    echo 1 >/sys/kernel/mm/ksm/run
    echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

If you enable it, you will save 40-60% of netdata memory.

 --- Check version.txt --- 
 --- Check apps.plugin --- 
 --- Generate netdata-uninstaller.sh --- 
 --- Basic netdata instructions --- 

netdata by default listens on all IPs on port 19999,
so you can access it with:

  http://this.machine.ip:19999/

To stop netdata run:

  systemctl stop netdata

To start netdata run:

  systemctl start netdata


Uninstall script generated: ./netdata-uninstaller.sh
Update script generated   : ./netdata-updater.sh

netdata-updater.sh can work from cron. It will trigger an email from cron
only if it fails (it does not print anything when it can update netdata).
 --- Refreshing netdata-updater at cron --- 
[/usr/src/netdata.git]# rm /etc/cron.daily/netdata-updater 
 OK   

[/usr/src/netdata.git]# ln -s /usr/src/netdata.git/netdata-updater.sh /etc/cron.daily/netdata-updater 
 OK   


 --- We are done! --- 

  ^
  |.-.   .-.   .-.   .-.   .-.   .  netdata                          .-.   .-
  |   '-'   '-'   '-'   '-'   '-'   is installed and running now!  -'   '-'  
  +----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+--->

  enjoy real-time performance and health monitoring...

 OK   

You have new mail in /var/spool/mail/root





