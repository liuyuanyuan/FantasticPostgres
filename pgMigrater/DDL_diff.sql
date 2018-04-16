
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


--PG的序列可直接用于表的自增(oracle不能)
--PG--
create table test_seq3(id int default nextval('lyy.seqtest3'), name varchar );

--ORACLE 12C--
CREATE TABLE TEST_SEQ
(  ID NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 
   		CACHE 20 NOORDER  NOCYCLE  NOT NULL ENABLE,
   NAME VARCHAR2(100)
); 




