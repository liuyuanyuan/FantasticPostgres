# 数据库迁移篇（oracle2pg）

## 迁移过程概述

迁移涉及源端数据库（oracle）和目标端数据库（pg）；从源端库提取数据库对象定义和数据，转换成目标端支持的语法，然后在目标端创建对象和插入数据。

## 差异列表

* [TangCheng oracle2pg Migrate Blog](http://osdbablog.sinaapp.com/528.html)
* [Oracle vs PG Diff](https://my.oschina.net/liyuj/blog/539303)
* [Oracle与PG System Function Diff](https://yq.aliyun.com/users/1994466589078092?spm=a2c4e.11153940.blogcont59422.2.2130505bZglu5d)

## 迁移解决方案

#### 1 在目标PG库添加【Oracle 兼容】

[Orafce](https://github.com/orafce/orafce) Functions and operators that emulate a subset of functions and packages from the Oracle RDBMS.

- [PG中创建和使用Orafce](orafce.md)

#### 2 进行基础的【oracle2pg迁移转换】

* [ora2pg](http://ora2pg.darold.net) - [Open source and free] Perl module to export an Oracle database schema to a PostgreSQL compatible schema.
* [SQLine - Oracle to PostgreSQL Migration](http://www.sqlines.com/oracle-to-postgresql) - C++， Include migrator and PLSQL Converter
* [pgloader](https://github.com/liuyuanyuan/fantastic-postgres/blob/master/pgMigrater/pgloader/pgloader_intro.md)
* [Ispirer Migration](http://wiki.ispirer.com/sqlways)
* [Comparison of database tools](https://en.wikipedia.org/wiki/Comparison_of_database_tools)

* [PG WIKI - Oracle_to_Postgres_Conversion](https://wiki.postgresql.org/wiki/Oracle_to_Postgres_Conversion)
* [plsql2pgsql converter](plsql2pgsql.md)
* [mysql-postgresql-converter](https://github.com/lanyrd/mysql-postgresql-converter) - Lanyrd's MySQL to PostgreSQL conversion script.

#### 3 【oracle2pg对比】以校验一致性

##### 目标/用途

用于异构数据库迁移后的准确性校验。对迁移目标数据库（PostgreSQL）和原数据库（oracle）进行的比对。

##### 对比原理

由于比较的两种数据库是异构的，所以难以进行物理对比，一般通过逻辑对比，数据库中对象和数据库进行对比：

- 数据库（同类型）对象对比：通过类型+名称来比对

- 数据库（同类型）对象结构对比：

  普通对象：通过类型+定义来比对；

  函数/存储过程：plsql与plpgsql迁移过程中进行了转换，很难直接比对定义，所以通过执行结果校验；

- 数据比对：

   整表数据库比较：通过数据压缩算法，压缩后比较娇艳值；

   行数据比较：按相同字段顺序获取行数据后比较；

- 数据库对象迁移映射校验（针对异构库中类型不同的库）

##### 市面已有对比工具

普通对象和数据对比校验：

- [EMS Comparer for PostgreSQL](http://download2.sqlmanager.net/download/datasheets/products/datacomparer/en/datacomparer.pdf) （[SQLManager](https://www.sqlmanager.net)）- Compare and synchronize the contents of your database with ease.
- [DBForge Data Compara](https://www.devart.com/dbforge/postgresql/datacompare/) - Visual data diffs comparison and deployment tool

函数/存储过程的验证和结果对比校验：

- [plpgsqlCheck](https://pgxn.org/dist/plpgsql_check/) （[DSD 3 License](https://opensource.org/licenses/BSD-3-Clause)）- Additional tools for plpgsql functions validation。

  

#### 4 进行【增量数据同步】

在主量基础数据迁移完毕后，以此为基准点，对此后执行的SQL语句进行记录，转换后放到目标端执行，这是常用的增量数据同步的方法。

[HVR](https://www.hvr-software.com)(商业) - 异构数据同步工具



#### 5 其他辅助工具

ETL工具：[Data Integration (or Kettle)](https://community.hitachivantara.com/docs/DOC-1009855)