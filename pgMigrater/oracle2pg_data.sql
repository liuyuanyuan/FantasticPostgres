---ORACLE vs PG Datatype---

--Oracle XMLTYPE - PG XML --
CREATE TABBLE test_xml(id int, x XMLTYPE);
INSERT INTO test_xml VALUES(1, 'abc');//failed
INSERT INTO test_xml VALUES(1, '<as>abc</as>');//successed

CREATE TABBLE test_xml(id int, x XML);
INSERT INTO test_xml VALUES(1, 'abc');//failed
INSERT INTO test_xml VALUES(1, '<as>abc</as>');//successed

结论： 在SQL中执行INSERT时XML数值都有格式要求，普通字符串都无法插入。


--ORACLE[float, BINARY_FLOAT, BINARY_DOUBLE]--

create table float_double(c int, f float, bf BINARY_FLOAT,bd BINARY_DOUBLE);
alter table float_double add constraint float_double_pk primary key(c);
desc float_double;
select * from float_double;

insert into float_double values(1, 99999999999999999999999999999999999999, 0.999999,   0.9999999999999); 
--原数（38个9，6个9,13个9）；插入后的是【都为原数】

insert into float_double values(2, 999999999999999999999999999999999999999,0.9999999 , 0.99999999999999);
--原数（39个9，7个9,14个9）；插入后的是【进1， 原数， 原数】

insert into float_double values(3, 9999999999999999999999999999999999999.9,0.99999999 , 0.999999999999999);
--原数（38个9，8个9,15个9）；插入后的是【原数， 1.0 进1，原数】

insert into float_double values(4, 9999999999999999999999999999999999999.99, 99999999 , 0.9999999999999999);
--原数（39个9，8个9,16个9）；插入后的是【进1， 进1，原数】

select * from float_double;
--query result--
1	| 99999999999999999999999999999999999999	| 0.999999	| 0.9999999999999
2	| 1000000000000000000000000000000000000000	| 0.9999999	| 0.99999999999999
3	| 9999999999999999999999999999999999999.9	| 1.0	    | 0.999999999999999
4	| 10000000000000000000000000000000000000	| 100000000	| 0.9999999999999999
5	| 0	                                        | 0.0	    | 1.0
-----------------

--以上测试结论：在oracle11g中， float能保持38个有效数字， binary_float能保持7个有效数字，binary_double能保持15个有效数字。

select sum(c) + sum(f) + sum(bf) + sum(bd) from float_double;
--query result--
Infinity
----------------
--java执行时以上sum，得到字段类型：BINARY_DOUBLE， 字段值：Infinity（无限大）

select sum(f), sum(bf), sum(bd) from float_double;
--query result---
1119999999999999999999999999999999999999 |	100000000 |	4.999999999999889
-----------------
--java执行时以上sum，得到: 1.12E39, 1.0E8, 4.999999999999889

---ORACLE---



---HGDB[DOUBLE PRECISION]---
--以下测试结论：在HGDB中，DOUBLE PRECISION能保持15个有效数字，
create table float_double(c int, f DOUBLE PRECISION, bf DOUBLE PRECISION,bd DOUBLE PRECISION);
alter table float_double add constraint float_double_pk primary key(c);


insert into float_double values(1, 99999999999999999999999999999999999999, 0.999999,   0.9999999999999); 
--原数（38个9，6个9,13个9）；插入后的是【进1科学计数,原数, 原数】

insert into float_double values(2, 999999999999999999999999999999999999999,0.9999999 , 0.99999999999999);
--原数（39个9，7个9,14个9）；插入后的是【进1科学计数， 原数， 原数】

insert into float_double values(3, 9999999999999999999999999999999999999.9,0.99999999 , 0.999999999999999);
--原数（38个9，8个9,15个9）；插入后的是【进1科学计数， 1.0 进1，原数】

insert into float_double values(4, 9999999999999999999999999999999999999.99, 99999999 , 0.9999999999999999);
--原数（39个9，8个9,16个9）；插入后的是【进1科学计数， 进1，原数】

--以下测试结论：在hgdb4中， DOUBLE PRECISION能保持15个有效数字。
insert into float_double values(5, 999999999999999, 0.999999999999999, 0.999999999999999); 
--原数（15个9，15个9,15个9）；插入后的是【都为原数】

insert into float_double values(6, 9999999999999999, 0.9999999999999999, 0.9999999999999999); 
--原数（16个9，16个9,16个9）；插入后的是【进1科学技术,进1,进1】

insert into float_double values(7, 99999999999999.99, 9999999999999999, 9999999999999999); 
--原数（16个9，16个9,16个9）；插入后的是【进1,进1,进1】

select * from float_double;
--query result---
1;1e+038;0.999999;0.9999999999999
2;1e+039;0.9999999;0.99999999999999
3;1e+037;0.99999999;0.999999999999999
4;1e+037;99999999;1
5;999999999999999;0.999999999999999;0.999999999999999
6;1e+016;1;1
7;100000000000000;1e+016;1e+016
------------------

select sum(c) + sum(f) + sum(bf) + sum(bd) from float_double;
--query result--
1.12e+039
----------------
--java执行时以上sum，得到字段类型：float8(在hgdb中得到的是DOUBLE PRECISION)， 字段值：1.1199999999999999E39

select sum(f), sum(bf), sum(bd) from float_double;
--query result---
1.12e+039;1.00000001e+016;1e+016
-----------------
--java执行时以上sum，得到: 1.1199999999999999E39, 1.000000029999989E8, 4.999999999999888

---HGDB---





---Oracle[interval, data, timestamp, timestamptz]---
Oracle Interval数据类型
Interval year(precision) to month  
       precision是这个时限的年部分所要求的最大位数。 默认为2，范围为0~9
Interval day(d_precision) to second(s_precision)  
       d_precision是这个时限的天部分所要求的最大位数,默认为2，范围也是0~9
       s_precision是这个时限的秒部分所要求的小数点右边的位数，默认为6，范围是0~9
例子：
create table intev3(id int primary key, 
intv1 INTERVAL YEAR(3) TO MONTH,
intv2 INTERVAL DAY(3) TO SECOND (7)
);
select interval '1-5' year to month, INTERVAL '123 2:25:45.123456789' DAY(3) TO SECOND(7) from  dual;
insert into intev3 values(1, interval '1-5' year to month, INTERVAL '123 2:25:45.123456789' DAY(3) TO SECOND(7));
insert into intev3 values(2,INTERVAL '10-11' year TO month, INTERVAL '10:22.123' MINUTE TO SECOND )
select * from intev3;
--------------------
1	+01-05	+123 02:25:45.123456800
2	+10-11	+00 00:10:22.123000
--------------------

HGDB interval数据类型
Interva[(s)]  s范围1-6，缺省为6.

间隔类型的输出格式可以被设置为四种风格之：
sql_standard、postgres、postgres_verbose或iso_8601，
设置方法使用SET intervalstyle命令。默认值为postgres格式。
间隔输出风格例子：
风格声明 | 年-月间隔  | 日-时间间隔混合间隔
sql_standard | 1-2 3 4:05:06 | -1-2 +3 -4:05:06
postgres | 1 year 2 mons 3 days 04:05:06 | -1 year -2 mons +3 days -04:05:06
postgres_verbose | @ 1 year 2 mons @ 3 days 4 hours 5 mins 6 secs  |  @ 1 year 2 mons -3 days 4 hours 5 mins 6 secs ago
iso_8601 | P1Y2M P3DT4H5M6S |  P-1Y-2M3DT-4H-5M-6S


create table interv3(
id int primary key,
interv1 interval(6)
);
insert into interv3 values(1, interval '3 4:05:06.12345678');
insert into interv3 values(2, INTERVAL '10:22.123' MINUTE TO SECOND);
insert into interv3 values(3, INTERVAL '10-11' year TO month);
select * from interv3;
-------------------------
1;"3 days 04:05:06.123457"
2;"00:10:22.123457"
3;"10 years 11 mons"
-------------------------
SET intervalstyle=sql_standard;
select * from  interv3;
----------------------
1;"3 4:05:06.123457"
2;"0:10:22.123457"
3;"10-11"


--oracle
select INTERVAL '10:22.12345678' MINUTE TO SECOND  from dual;
+00 00:10:22.123457
select INTERVAL '10:22.123' MINUTE TO SECOND  from dual;
+00 00:10:22.123000

--hgdb
select INTERVAL '10:22.12345678' MINUTE TO SECOND
"00:10:22.123457"
select INTERVAL '10:22.123' MINUTE TO SECOND
"00:10:22.123"


--lei test--
Date数据类型 ,使用to_char()函数，见下面的例子：
SQL> select to_char(sysdate,'yyyy-MM-dd HH24:mi:ss') from dual;
TO_CHAR(SYSDATE,'YY
-------------------
2018-02-05 20:56:04


Timestamp数据类型,使用to_char()函数，见下面的例子：
SQL> select to_char(to_timestamp('2018-12-28 13:25:56.123456789','YYYY-MM-DD HH24:MI:SS:FF9'),'YYYY-MM-DD HH24:MI:SS:FF9') from dual;
TO_CHAR(TO_TIMESTAMP('2018-12
-----------------------------
2018-12-28 13:25:56:123456789


TIMESTAMP[(fractional_seconds_precision)] WITH TIME ZONE 
打开第一个sqlplus
sqlplus / as sysdba
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT ='YYYY-MM-DD HH24:MI:SS TZR';
create table tztab1(x number primary key, y timestamp with time zone);
insert into tztab1 values(1, TIMESTAMP '2008-05-22 14:00:00 Australia/Sydney');
insert into tztab1 values(2, TIMESTAMP '2007-12-01 14:00:00 America/Argentina/Buenos_Aires');
insert into tztab1 values(3, TIMESTAMP '2008-02-22 14:00:00 America/Caracas');
insert into tztab1 values(4, TIMESTAMP '2008-02-22 14:00:00 Brazil/East');
insert into tztab1 values(5, TIMESTAMP '2008-02-22 14:00:00 Africa/Cairo');
commit;
exit

打开第二个sqlplus
select to_char(Y,'YYYY-MM-DD HH24:MI:SS TZR') from  tztab1;
TO_CHAR(Y,'YYYY-MM-DDHH24:MI:SSTZR')
----------------------------------------------------
2008-05-22 14:00:00 AUSTRALIA/SYDNEY
2007-12-01 14:00:00 AMERICA/ARGENTINA/BUENOS_AIRES
2008-02-22 14:00:00 AMERICA/CARACAS
2008-02-22 14:00:00 BRAZIL/EAST
2008-02-22 14:00:00 AFRICA/CAIRO


--lyy test--
create table timestamp(id int primary key,
time1 timestamp(8),
date1 date,
inter1 interval year(5) to month);

SELECT systimestamp, sysdate,  NUMTOYMINTERVAL( 2, 'YEAR'), NUMTOdsINTERVAL( 2, 'DAY')  FROM DUAL;
--query result--
06-2月 -18 05.41.19.135131000 下午 +08:00 |	06-2月 -18 | +02-00	| +02 00:00:00.000000
----------------

insert into timestamp values(1, systimestamp, sysdate,   NUMTOYMINTERVAL( 2, 'YEAR') )
insert into timestamp values(3, TIMESTAMP '2018-12-28 13:25:56.123456789' , sysdate,   NUMTOYMINTERVAL( 2, 'YEAR') )
select ID, DATE1, TIME1, INTER1  from timestamp;
---query result--
1| 06-2月 -18 | 06-2月 -18 05.33.03.992795000 下午	| +02-00
2| 28-12月-18 | 01.25.56.123456790 下午	07-2月 -18	| +02-00
3| 28-12月-18 | 01.25.56.123456790 下午	07-2月 -18	| +02-00
-----------------

alter session set nls_timestamp_format ='YYYY-MM-DD HH24:MI:SS:FF6';
SELECT * FROM TIMESTAMP;
---QUERY RESULT---
1	2018-02-06 17:33:03:992795	06-2月 -18	+02-00
2	2018-12-28 13:25:56:123456	07-2月 -18	+02-00
3	2018-12-28 13:25:56:123456	07-2月 -18	+02-00
------------------


SELECT ID, TO_CHAR(DATE1 , 'yyyy-MM-dd HH24:mi:ss'), 
TO_CHAR(TIME1,'YYYY-MM-DD HH24:MI:SS:FF6'), 
TO_CHAR(INTER1, 'YYYY-MM-DD HH24:MI:SS:FF6')--?
FROM  timestamp;
--query result--
1 | 2018-02-06 17:33:03	| 2018-02-06 17:33:03:99279500 | +00002-00
2 |	2018-02-07 09:43:53	| 2018-12-28 13:25:56:123456   | +00002-00
3 |	2018-02-07 09:44:49	| 2018-12-28 13:25:56:123456   | +00002-00
----------------
--通过迁移工具将timestamp迁移到hgdb后(超出6位的进行了四舍五入)
SELECT ID, TO_CHAR(DATE1 , 'yyyy-MM-dd HH24:mi:ss'), 
TO_CHAR(TIME1,'YYYY-MM-DD HH24:MI:SS.US'), 
TO_CHAR(INTER1, 'YYYY-MM-DD HH24:MI:SS.US')--?
FROM  timestamp;
--query result--
1;"2018-02-06 17:33:03";"2018-02-06 17:33:03.992795";"0002-00-00 00:00:00.000000"
2;"2018-02-07 09:43:53";"2018-12-28 13:25:56.123457";"0002-00-00 00:00:00.000000"
3;"2018-02-07 09:44:49";"2018-12-28 13:25:56.123457";"0002-00-00 00:00:00.000000"
---------------

--alter session设置本会话下的timestamp的格式(语句在oracle的jdbc不起效)
alter session set nls_timestamp_format ='YYYY-MM-DD HH24:MI:SS:FF6';
--update对NLS_SESSION_PARAMETERS无法执行（jdbc同样无法执行）
update  NLS_SESSION_PARAMETERS set  VALUE = 'YYYY-MM-DD HH24:MI:SS:FF7' where  PARAMETER = 'NLS_TIMESTAMP_FORMAT';
update错误位于命令行: 1 列: 9
错误报告 -
SQL 错误: ORA-02030: 只能从固定的表/视图查询
02030. 00000 -  "can only select from fixed tables/views"
*Cause:    An attempt is being made to perform an operation other than
           a retrieval from a fixed table/view.
*Action:   You may only select rows from fixed tables/views.	
--oracle 官方给出的jdbc修改NLS_TIMESTAMP_FORMAT的方式：通过创建登录时即触发的alter session操作的触发器。(可能对客户造成洽谈影响)
https://my.oschina.net/liuyuanyuangogo/blog/1619513


--ORACLE - Timestamp With local Time Zone--
create table timestamptz(id int primary key, tz1 Timestamp With local Time Zone);
insert into timestamptz values(1, systimestamp);
insert into timestamptz values(2, sysdate);
select id, to_char(tz1,'YYYY-MM-DD HH24:MI:SS:FF6 TZR')  from timestamptz;
-----------------------
1	2018-02-07 11:28:36:882591 ASIA/SHANGHAI
2	2018-02-07 11:29:48:000000 ASIA/SHANGHAI

--迁移工具把表timestamptz迁移到HGDB后
表结构:
CREATE TABLE lyy.timestamptz
(
  id numeric NOT NULL,
  tz1 timestamp(6) with time zone,
  CONSTRAINT sys_c0011173 PRIMARY KEY (id)
);
select id, to_char(tz1,'YYYY-MM-DD HH24:MI:SS.US TZ')  from lyy.timestamptz;
-----------------------
1;"2018-02-07 11:28:36.882591 HKT"
2;"2018-02-07 11:29:48.000000 HKT"

--ORACLE - Timestamp With Time Zone--
create table tztab1(x number primary key, y timestamp with time zone);
insert into tztab1 values(1, TIMESTAMP '2008-05-22 14:00:00 Australia/Sydney');
insert into tztab1 values(2, TIMESTAMP '2007-12-01 14:00:00 America/Argentina/Buenos_Aires');
insert into tztab1 values(3, TIMESTAMP '2008-02-22 14:00:00 America/Caracas');
insert into tztab1 values(4, TIMESTAMP '2008-02-22 14:00:00 Brazil/East');
insert into tztab1 values(5, TIMESTAMP '2008-02-22 14:00:00 Africa/Cairo');
insert into tztab1 values(6, TIMESTAMP '2008-02-23 14:00:00 Asia/Shanghai');
insert into tztab1 values(7, TIMESTAMP '2008-02-23 14:00:00 Asia/Hong_Kong');
select * from tztab1;
-------------------------------------
1	2008-05-22 14:00:00 AUSTRALIA/SYDNEY
2	2007-12-01 14:00:00 AMERICA/ARGENTINA/BUENOS_AIRES
3	2008-02-22 14:00:00 AMERICA/CARACAS
4	2008-02-22 14:00:00 BRAZIL/EAST
5	2008-02-22 14:00:00 AFRICA/CAIRO
6	2008-02-23 14:00:00 ASIA/SHANGHAI
7	2008-02-23 14:00:00 ASIA/HONG_KONG
--------------------------------------
--迁移工具把表tztab1迁移到HGDB后--
表结构：
CREATE TABLE lyy.tztab1
(
  x numeric NOT NULL,
  y timestamp(6) with time zone,
  CONSTRAINT sys_c0011178 PRIMARY KEY (x)
);
select x, to_char(y,'YYYY-MM-DD HH24:MI:SS.US TZ')  from lyy.tztab1;
----------------------------------
1;"2008-05-22 12:00:00.000000 HKT"
2;"2007-12-02 01:00:00.000000 HKT"
3;"2008-02-23 02:30:00.000000 HKT"
4;"2008-02-23 01:00:00.000000 HKT"
5;"2008-02-22 20:00:00.000000 HKT"
6;"2008-02-23 14:00:00.000000 HKT"
7;"2008-02-23 14:00:00.000000 HKT"
----------------------------------
以上timestamptz的结论：ORACLE迁移到HGDB这边统一成了一个时区的时间(这里是HKT香港时区，HKT可能跟我的数据设置或者OS时区有关)




数据库系统函数
--hgdb---
select sysdate;
"2018-03-09 14:51:10.450423+08"
select systimestamp();
"2018-03-09 14:53:07.691636+08"

---oracle---
select sysdate from dual;
09-3月 -18
select systimestamp from dual;
09-3月 -18 02.54.06.812000000 下午 +08:00




---ORACLE---




---HGDB --
--PG time type ref:
https://www.postgresql.org/docs/10/static/functions-formatting.html
https://www.cnblogs.com/alianbog/p/5654846.html
---------时间格式表示---------
模式	描述
YYYY	年(4和更多位)
HH		一天的小时数(01-12)
HH12	一天的小时数(01-12)
HH24	一天的小时数(00-23)
MI		分钟(00-59)
SS		秒(00-59)
MS		毫秒(000-999)
US		微秒(000000-999999)
-----------------------------

---------pg日期相关函数------
current_date	date	当前日期	select current_date;	2016-07-08
current_time	time with time zone	当前时间	select current_time;	15:15:56.394651-07
current_timestamp	timestamp with time zone	当前时间戳	select current_timestamp;	2016-07-08 15:16:50.485864-07
justify_days(interval)	interval	按照每月30天调整时间间隔	select justify_days(interval'1year 45days 23:00:00');	1 year 1 mon 15 days 23:00:00
justify_hours(interval)	interval	按照每天24小时调整时间间隔	select justify_hours(interval'1year 45days 343hour');	1 year 59 days 07:00:00
justify_interval(interval)	interval	同时使用justify_days(interval)和justify_hours(interval)	select justify_interval(interval'1year 45days 343hour');	1 year 1 mon 29 days 07:00:00
-----------------------------

--------几个特殊日期和时间----------
输入字符串   适用类型         描述
epoch        date,timestamp    1970-01-01 00:00:00+00(unix系统零时)
infinity     date,timestamp   比任何其他时间戳都晚
-infinity    date,timestamp   比任何其他时间戳都晚
allballs     time             00:00:00.00 UTC 
now          date,timestamp   当前事务的开始时间
today        date,timestamp   今日午时
tomorrow     date,timestamp   明日午时
yesterday    date,timestamp   昨日午时
-------------------------------------

create table timestamp0(id int primary key,
date1 timestamp(0), 
timestamp timestamp(5),
inter1 interval(5));

select CURRENT_DATE, CURRENT_TIMESTAMP, JUSTIFY_DAYS('2'), JUSTIFY_HOURS('2'), JUSTIFY_INTERVAL('2')
"2018-02-06";"2018-02-06 18:11:13.300581+08";"00:00:02";"00:00:02";"00:00:02"

insert into timestamp0 values(1, CURRENT_DATE, CURRENT_TIMESTAMP, JUSTIFY_DAYS('2') );

select * from timestamp0;
1;"2018-02-06 00:00:00";"2018-02-06 18:10:45.80435";"00:00:02"

SELECT ID, TO_CHAR(DATE1 , 'yyyy-MM-dd HH24:mi:ss'), 
TO_CHAR(timestamp,'YYYY-MM-DD HH24:MI:SS:FF5'), 
TO_CHAR(INTER1, 'YYYY-MM-DD HH24:MI:SS')--?
FROM  timestamp0;
1;"2018-02-06 00:00:00";"2018-02-06 18:10:45:FF5";"0000-00-00 00:00:02"




--------ORACLE NUMBER vs HDGB NUMERIC-------------------------------
NUMBER类型的参数s和p：
Oracle中，s∈[-84,127]，p∈[1,38](p最大值是38可能是oracle出于安全考虑)，p缺省为最大限度内的任意值s缺省为0；
 一般p>=s,在oracle中还支持p<s。
表示有效位最大为p，小数位最多为s。

HGDB中，s>=0，p>0，p缺省为最大限度内的任意值,s缺省为0,HGDB中仅支持p>=s,不支持p<s。
p精度（precision）是所有数字位的个数(最大P位数)
s标度（scale）是到小数点右边所有小数位的个数(小数点后最大占S位) 

迁移过程中：
当从oracle取到number（*）或number ,即缺少参数p和s的声明时（此时可以存储一个直到实现精度上限的任意精度和标度的数值）, 故转为 numeric；
当从oracle取到number（*, s）,即仅缺少参数p的声明时(此时可以存储一个直到实现精度上限的任意精度(跟p小于等于38的限制没直接关系)，故转为 numeric（126，s）；
当从oracle取到number（p, s），即参数p和s的声明都有时，若s<0时，取s=0;若p<s时，取p=s；否则p和s不变，然后转为numeric(p,s)。


ORACLE-NUMBER(P,S) , NUMBER(P) , NUMBER
number(p,s),s大于0，表示有效位最大为p，小数位最多为s，小数点右边s位置开始四舍五入，若s>p，小数点右侧至少有s-p个0填充（必须从小数点处开始并连续）。
举例：
number(2,1),有效位最大为2，小数点后最多保留1位;
存1.115 得1.2
存1.11 得1.1
存1 得1
存0.01 得0
存11.1 得出错 有效位为3，大于2
存11 得出错 因为11等于11.0 有效位为3，大于2
number(3,6),用来存储小于0.001并且小数点后位数最多6位的小数，当小数位数超出时，四舍五入舍去超出位数。
如插入0.0002时，存取0.0002,
插入0.000222时，存取0.000222,
插入0.0002225时，存取0.000223;
number(2,4) 有效位最大为2，小数点后最多保留4位：
最大存值：0.0099，至少从小数点处开始并连续填充4-2=2个0，
如存1出错，因为1等于1.0000，有效位为5，大于2


number(p,s),s小于0，表示有效位最大为p+|s|，没有小数位，小数点左边s位置开始四舍五入，小数点左侧s位，每一位均为0。
举例：
number(2,-3) 有效位最大为2+3=5，没有小数位：
存11111 得11000，因为11111等于11111.0，从小数点左侧3位处开始四舍五入。
存11545 得12000
存11545.5 得12000，因为不存小数位，所以舍去小数位
存99999 得出错，因为四舍五入后变为，100000，有效位为6，大于5
存9999 得10000


HGDB-NUMERIC(P,S), NUMERIC(P),  NUMERIC
p精度（precision）是所有数字位的个数(最大P位数)
s标度（scale）是到小数点右边所有小数位的个数(小数点后最大占S位) 

CREATE TABLE num1(id int primary key,
num1 numeric,
num2 numeric(3),
num3 numeric(4,2)
);

insert into num1  values(1, 12345678, 1234.567, 123.45678);
ERROR: 22003: numeric field overflow
SQL 状态: 22003
详细:A field with precision 4, scale 2 must round to an absolute value less than 10^2.

insert into num1  values(1, 12345678, 1234.567, 12.345678);
select * from num1;
-----------------------
1;12345678;1235;12.35
-----------------------
