---table---
--PG timestamp参数长度越界测试，超过6时转为6，创建成功给出警告
create table test_time3(t timestamp(8));
1.在PLSQL中:
postgres-# highgo=# create table test_time3(t timestamp(8));
ERROR:  42601: syntax error at or near "PSQL"
第1行PSQL: Release 4.1.1
     ^
postgres=# WARNING:  22023: TIMESTAMP(8) precision reduced to maximum allowed, 6
postgres-# 第1行create table test_time3(t timestamp(8));
ERROR:  42601: syntax error at or near "WARNING"
第1行WARNING:  22023: TIMESTAMP(8) precision reduced to maximum a...
     ^
2.在JDBC中:
执行成功,查看表定义timestamp的长度变成6，可以得到警告。

--view--
Oracle CREATE VIEW: 
https://docs.oracle.com/en/database/oracle/oracle-database/18/sqlrf/CREATE-VIEW.html#GUID-61D2D2B4-DACC-4C7C-89EB-7E50D9594D30

PG CREATE VIEW:
https://www.postgresql.org/docs/10/static/sql-createview.html



--sequence--
--oracle--
CREATE SEQUENCE seqTest
INCREMENT BY 1 -- 每次加几个
START WITH 1 -- 从1开始计数
NOMAXVALUE -- 不设置最大值
NOCYCLE -- 一直累加，不循环
CACHE 10; --设置缓存cache个序列，如果系统down掉了或者其它情况将会导致序列不连续；也可设置为NOCACHE即为1

SELECT SEQTEST.NEXTVAL FROM DUAL; --增加并返回
SELECT SEQTEST.CURRVAL FROM DUAL; --返回当前值

--pg--
CREATE SEQUENCE seqtest
  INCREMENT [BY] 1
  START [WITH]  6  
  MINVALUE 1 --缺省为1，NO MINVALUE即采用缺省值1.
  MAXVALUE 9223372036854775807 --缺省为该类型最大值，NO MAXVALUE即采用缺省值（9223372036854775807） 
  NO CYCLE --一直达到最大值时报错，不循环， 设置为CYCLE则在最小和最大值之间循环
  CACHE 1; --最小为1

SELECT nextval('lyy.seqtest3'); --将当前值递增并返回
SELECT currval('lyy.seqtest3'); --返回当前值

--设置当前值；b 默认设置true；设置true后，调用 nextval() 时直接返回 n+increment; 设置 false，则调用 nextval() 时返回 n:
SELECT setval('lyy.seqtest3', 11, true);  


--在表的自增列中的使用
--PG中直接可用--
CREATE TABLE test_seq3(id int default nextval('lyy.seqtest3'), name varchar );
--ORACLE不能直接用--
http://www.xifenfei.com/2015/03/oracle-12c-新特性identity-columns-实现oracle自增长列功能.html
ORACLE 12C新特性：
CREATE TABLE TEST_SEQ
(  ID NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 
   		CACHE 20 NOORDER  NOCYCLE  NOT NULL ENABLE,
   NAME VARCHAR2(100)
); 


--comment-

PG:https://www.postgresql.org/docs/10/static/sql-comment.html
Syntax：COMMENT ON <type> <name> IS '<comment>';

Oracle:https://docs.oracle.com/en/database/oracle/oracle-database/18/sqlrf/COMMENT.html#GUID-65F447C4-6914-4823-9691-F15D52DB74D7
Syntax: same to PG.







