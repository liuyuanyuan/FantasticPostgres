# PostgreSQL JDBC Series

### 要点

- ##### [PGJDBC](pg_jdbc.md)- PostgreSQL JDBC Driver

- ##### [HA-JDBC](ha_jdbc.md) - High-Availability JDBC

- ##### [Sharding-JDBC](sharding_jdbc.md) - 开源的分布式数据库中间件ShardingSphere系列之一



附注：PostgreSQL系列方案

​	PostgreSQL:  OLTP

​	Greenplum:  MPPDB（shared-nothing） for OLAP

​	pgxc, pgxl:   PG的集群

​	pgpool II:     PG的读写分离实现

​	PG 流复制:  PG的高可用实现

​    PG备份： pg_dump/pg_dumpall (pg_restore)

​    PG数据同步：全量备份后，进行wal日志的SQL分析，然后通过重演SQL进行增量同步。


