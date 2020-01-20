# file_fdw -从PG外部表读取文件/系统信息

**简介**

PostgreSQL从v9.4开始添加了file_fdw模块，用以支持外部数据包装器**[file_fdw](https://link.zhihu.com/?target=http%3A//www.postgresql.org/docs/9.4/static/file-fdw.html)**，可用于访问服务器文件系统中的数据文件。数据文件必须采用可由COPY FROM读取的格式（text,csv(以逗号分隔值), binary）；有关详细信息，请参见[COPY](https://link.zhihu.com/?target=https%3A//www.postgresql.org/docs/current/sql-copy.html)。当前对此类数据文件的访问是只读的。

file_fdw显著用途之一是通过PG数据库表读取PostgreSQL日志信息。

**创建file_fdw**

安装pg数据库后，需要再安装file_fdw功能模块

```text
Yolandas-MBP:file_fdw liuyuanyuan$ pwd
  /Users/liuyuanyuan/pgadmin/pg13source/contrib/file_fdw
Yolandas-MBP:file_fdw liuyuanyuan$make;make install
  #安装成功会在/Users/liuyuanyuan/pgadmin/pgdb/share/postgresql/extension/目录下生成文件：file_fdw.control, file_fdw--1.0.sql ,  file_fdw.so 
```

创建扩展：

```text
postgres=# CREATE EXTENSION file_fdw;
```

创建外部服务：

```text
postgres=# CREATE SERVER fdwserver FOREIGN DATA WRAPPER file_fdw;
```

**应用1 - 通过外部表读取PG系统日志**

###### 1 配置postgresql.conf中日志参数，使PG记录CSV格式日志文件

配置PG记录日志：[https://www.postgresql.org/docs/current/runtime-config-logging.html](https://link.zhihu.com/?target=https%3A//www.postgresql.org/docs/current/runtime-config-logging.html)

```text
log_destination = 'csvlog'         #生成日csv格式的日志文件
logging_collector = on
log_directory = 'pg_log'            #日志文件存储在./data/pg_log目录
log_filename = 'postgresql-%Y-%m-%d'  #定义日志文件名字为postgresql-2013-12-17.csv
log_truncate_on_rotation = off
log_rotation_age = 1d               #设置日志文件生成的频率为1天
log_rotation_size = 0   
log_error_verbosity = verbose  #设置日志文件中的错误信息为详细
log_statement = all                   #设置所有语句均计入日志
```

###### 2 创建外部表：

```text
postgres=# CREATE FOREIGN TABLE pglog (
  log_time timestamp(3) with time zone,
  user_name text,
  database_name text,
  process_id integer,
  connection_from text,
  session_id text,
  session_line_num bigint,
  command_tag text,
  session_start_time timestamp with time zone,
  virtual_transaction_id text,
  transaction_id bigint,
  error_severity text,
  sql_state_code text,
  message text,
  detail text,
  hint text,
  internal_query text,
  internal_query_pos integer,
  context text,
  query text,
  query_pos integer,
  location text,
  application_name text
) SERVER fdwserver
OPTIONS (filename '/user/data/pg_log/postgresql-2013-12-17.csv',format 'csv');
```

注意：以上filename中的文件路径要求是绝对路径。

###### 3 通过外部表读取日志信息

```text
postgres=# select log_time,connection_from,user_name,database_name,query,application_name from pglog where query is not null;
```

实际应用中可以根据需要为SQL语句添加过滤条件。

**应用2 -** [通过PG外部表读取操作系统信息](https://link.zhihu.com/?target=https%3A//yq.aliyun.com/articles/624113)

```text
#读取操作系统中实时进程信息
CREATE FOREIGN TABLE process_status (
  username TEXT,
  pid      INTEGER,
  cpu      NUMERIC,
  mem      NUMERIC,
  vsz      BIGINT,
  rss      BIGINT,
  tty      TEXT,
  stat     TEXT,
  start    TEXT,
  time     TEXT,
  command  TEXT
) SERVER fdwserver OPTIONS (
PROGRAM 
$$
ps aux | awk '{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,substr($0,index($0,$11))}' OFS='\037'
$$
,
FORMAT 'csv', DELIMITER E'\037', HEADER 'TRUE');

#用于读取操作系统用户列表
CREATE FOREIGN TABLE etc_password (
  username  TEXT,
  password  TEXT,
  user_id   INTEGER,
  group_id  INTEGER,
  user_info TEXT,
  home_dir  TEXT,
  shell     TEXT
) SERVER fs OPTIONS (
  PROGRAM 
$$
awk -F: 'NF && !/^[:space:]*#/ {print $1,$2,$3,$4,$5,$6,$7}' OFS='\037' /etc/passwd
$$
, 
  FORMAT 'csv', DELIMITER E'\037'
);

#读取操作系统磁盘用量
CREATE FOREIGN TABLE disk_free (
  file_system TEXT,
  blocks_1m   BIGINT,
  used_1m     BIGINT,
  avail_1m    BIGINT,
  capacity    TEXT,
  iused       BIGINT,
  ifree       BIGINT,
  iused_pct   TEXT,
  mounted_on  TEXT
) SERVER fs OPTIONS (PROGRAM 
$$
df -ml| awk '{print $1,$2,$3,$4,$5,$6,$7,$8,$9}' OFS='\037'
$$
, FORMAT 'csv', HEADER 'TRUE', DELIMITER E'\037'
);
```

