# 数据库对比校验



## 异构数据库比对校验（Oracle2PG ）

#### 目标/用途

用于异构数据库迁移后的准确性校验。对迁移目标数据库（PostgreSQL）和原数据库（oracle）进行的比对。

#### 对比原理

由于比较的两种数据库是异构的，所以难以进行物理对比，一般通过逻辑对比，数据库中对象和数据库进行对比：

- 数据库（同类型）对象对比：通过类型+名称来比对

- 数据库（同类型）对象结构对比：

  普通对象：通过类型+定义来比对；

  函数/存储过程：plsql与plpgsql迁移过程中进行了转换，很难直接比对定义，所以通过执行结果校验；

- 表数据比对：

   整表数据库比较：通过数据压缩算法，压缩后比较娇艳值；

   行数据比较：按相同字段顺序获取行数据后比较；

- 数据库对象迁移映射校验（针对异构库中类型不同的库）

#### 市面已有对比工具

- [EMS Comparer for PostgreSQL](http://download2.sqlmanager.net/download/datasheets/products/datacomparer/en/datacomparer.pdf) （[SQLManager](https://www.sqlmanager.net)）- Compare and synchronize the contents of your database with ease.
- [plpgsqlCheck](https://pgxn.org/dist/plpgsql_check/) （[DSD 3 License](https://opensource.org/licenses/BSD-3-Clause)）- Additional tools for plpgsql functions validation。
- [DBForge Data Compara](https://www.devart.com/dbforge/postgresql/datacompare/) - Visual data diffs comparison and deployment tool

## 同构数据库对比

#### 目标/用途

用于备份恢复目标库和原库的对比。

#### 对比方式

同构数据库理论上可以进行物理对比和逻辑对比。

#### 市面已有对比工具

- [apgdiff](https://www.apgdiff.com/) （Java, [MIT License](https://www.apgdiff.com/license.php)）- Compares two database dump files and creates output with DDL statements that can be used to update old database schema to new one.