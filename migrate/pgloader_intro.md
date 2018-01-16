

2018年1月10日，本PostgreSQL迁移白皮书由 pgloader 负责人 Dimitri Fontaine 发布，介绍了将数据从其他数据库迁移到PostgreSQL的工具和方法论。

迁移白皮书主要内容

1 前言

2 迁移项目

2.1 迁移到 PostgreSQL 的原因

2.2 典型的迁移成本预计

2.3 Port vs Migration

2.4 更多关于 PostgreSQL

3 连续迁移

3.1 PostgreSQL 体系结构

3.2 生产数据的页面迁移

3.3 迁移 Code 和 SQL 查询

4 使用工具：pgloader

4.1常规迁移行为

4.2 pgloader 特性 

5 Closing Thoughts

查看或下载迁移白皮书：


关于pgloader

    pgloader 是一个 PostgreSQL 的数据加载工具，并且可以实现从当前数据库到PostgreSQL的连续迁移，使用了COPY命令 。

    与仅使用 COPY 或 \copy 以及使用 Foreign Data Wrapper 相比，它的主要优势在于它的事务行为，其中 pgloader 将保留单独的被拒绝数据文件，但继续尝试将好的数据复制到数据库中。

   默认的PostgreSQL行为是事务性的，这意味着输入数据（文件或远程数据库）中的任何错误行将停止表的整个批量加载。

    pgloader也实现了数据重新格式化，一个典型的例子就是将MySQL datestamps 0000-00-00 和 0000-00-00 00:00:00 转换为 PostgreSQL 的 NULL值（因为我们的日历从来没有零年）。

website： https://pgloader.io/

doc: http://pgloader.readthedocs.io/en/latest/

github: https://github.com/dimitri/pgloader


