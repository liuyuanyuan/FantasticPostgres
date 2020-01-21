# Grafana

#### Postgres Monitor 

Monitor system table: https://www.postgresql.org/docs/10/static/monitoring-stats.html



#### Universal Monitor CO

##### grafana+influxdb+telegraf compatible with PostgreSQL

##### I in windows 

reference:

http://www.cnblogs.com/Bug-Hunter/p/7428774.html
http://blog.51cto.com/11512826/2056183?cid=698642

1. download three zip files;

2. unzip file and config;

3. make StartAll.bat(with following content) and run it:

   @echo off
   start cmd /k "cd/d %~dp0\influxdb-1.5.2_windows_amd64\influxdb-1.5.2-1&&influxd -config influxdb.conf"
   echo started influxdb
   start cmd /k "cd/d %~dp0\telegraf-1.6.1_windows_amd64\telegraf&&telegraf -config telegraf.conf"
   start cmd /k "cd/d %~dp0\grafana-5.1.0.windows-x64\grafana-5.1.0\bin&&grafana-server.exe"
   ping -n 5 127.0>null

browse http://127.0.0.1:3000

##### II in linux 

reference:

http://www.cnblogs.com/Scissors/p/5977670.html
https://www.cnblogs.com/renqiqiang/p/8659772.html
 (Grafana) http://www.ywnds.com/?p=5903 

1 [DB]influxdb doc: https://portal.influxdata.com/downloads
wget https://dl.influxdata.com/influxdb/releases/influxdb-1.5.2.x86_64.rpm
sudo yum localinstall influxdb-1.5.2.x86_64.rpm

2 [Monitor]Grafana doc: https://grafana.com/grafana/download
sudo yum install  https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.1.0-1.x86_64.rpm 

3 [Proxy]Telegraf doc: https://portal.influxdata.com/downloads
wget https://dl.influxdata.com/telegraf/releases/telegraf-1.6.1-1.x86_64.rpm
sudo yum localinstall telegraf-1.6.1-1.x86_64.rpm

4 start service in the following order
sudo systemctl start influxd

sudo systemctl start grafana-server

5 create db in Influxdb
liuyuanyuan@yfslcentos71 ~]$ influx
Connected to http://localhost:8086 version 1.5.2
InfluxDB shell version: 1.5.2
> create database telegraf
> show databases
name: databases
name
----
_internal
telegraf

> quit

6 conifg Telegraf 
sudo vim /etc/telegraf/telegraf.conf

#config following content

[[outputs.influxdb]]
  urls = ["http://localhost:8086"]  #infulxdb host address
  database = "telegraf" #db name
  precision = "s"
  timeout = "5s"
  username = "admin" #user
  password = "admin" #pwd
  retention_policy = ""

sudo systemctl restart telegraf

7 start grafana
sudo systemctl status grafana-server

8 browse grafana monitor web
8.1 browse: http://192.168.102.41:3000/dashboard/new
Using PostgreSQL in Grafana: http://docs.grafana.org/features/datasources/postgres/

8.2 config datasource:
---input---
Name:telegraf
Type:InfluxDB
url:http://influxdb-host:8086
Database:telegraf
user:admin
password:admin
---save and test---

8.3 customize dashboard:
new - title - new graph ...


