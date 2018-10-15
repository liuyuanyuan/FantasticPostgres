======================================================
I Compiling plpgsql_check extension with PostgreSQL10
======================================================
ref:
github: https://github.com/okbob/plpgsql_check
website: https://pgxn.org/dist/plpgsql_check/0.9.3/
Compile and use: https://www.raghavt.com/blog/2018/04/10/compiling-plpgsql_check-extension-with-edb-postgres-9.6/

0 Introducation
plpgsql_check extension helps developers to validate all embeded SQL and SQL statements inside plpgsql function. Its one of the useful extensions particularly when working with plpgsql development. For more details refer to plpgsql_check documentation.
By default, plpgsql_check extension not enabled in community PostgreSQL or commercial EDB Postgres. You need compile the extension with your flavor database. Community PostgreSQL compilation is easy and documented in the above reference link, however below steps help you to compile with commercial EDB Postgres database.

1 Download and Install PostgreSQL 10

2 Download plpgsql_check
As a root user clone the plpgsql_check repository from the Github
git clone https://github.com/okbob/plpgsql_check.git

Change to plpgsql_check directory

3 Before compiling, we need to make sure we have installed libicu-devel packages. 
Latest version PostgreSQL/EDB Postgres binaries are linked to a particular libicu 
to support International Componenets for Unicode(ICU). In case, if libicu-devel 
package not installed on your machine then you may encounter below error:

In file included from /opt/edb/as9.6/include/server/tsearch/ts_locale.h:18:0,
                 from plpgsql_check.c:71:
/opt/edb/as9.6/include/server/utils/pg_locale.h:54:26: fatal error: unicode/ucol.h: No such file or directory
 #include <unicode/ucol.h>
Use YUM to install libicu-devel package.

yum install libicu*

4 Set PostgreSQL 10, pg_config in PATH before compiling.
export PATH=/opt/PostgreSQL/10/bin:$PATH

5 Follow the source compilation steps

 make USE_PGXS=1 clean
 make USE_PGXS=1 all
 make USE_PGXS=1 install

6 Switch as “postgres” user, connect to database and create extension

su - postgres
psql -U postgres -d postgres -p 5432
psql.bin (9.6.5.10)
Type "help" for help.

postgres=# load 'plpgsql';
LOAD
postgres=# create extension plpgsql_check;
CREATE EXTENSION

postgres=# create table t1(a int, b int);
CREATE TABLE
postgres=# CREATE OR REPLACE FUNCTION public.f1()
postgres-# RETURNS void
postgres-# LANGUAGE plpgsql
postgres-# AS $function$
postgres$# DECLARE r record;
postgres$# BEGIN
postgres$#   FOR r IN SELECT * FROM t1
postgres$#   LOOP
postgres$#     RAISE NOTICE '%', r.c; -- there is bug - table t1 missing "c" column
postgres$#   END LOOP;
postgres$# END;
postgres$# $function$;
CREATE FUNCTION
postgres=#  select f1(); -- execution doesn't find a bug due to empty table t1
 f1 
----
 
(1 row)

postgres=# \x
Expanded display is on.
postgres=# select * from plpgsql_check_function_tb('f1()');
-[ RECORD 1 ]---------------------------
functionid | f1
lineno     | 6
statement  | RAISE
sqlstate   | 42703
message    | record "r" has no field "c"
detail     | 
hint       | 
level      | error
position   | 
query      | 
context    | SQL statement "SELECT r.c"

postgres=# \sf+ f1
        CREATE OR REPLACE FUNCTION public.f1()
         RETURNS void
         LANGUAGE plpgsql
1       AS $function$
2       DECLARE r record;
3       BEGIN
4         FOR r IN SELECT * FROM t1
5         LOOP
6           RAISE NOTICE '%', r.c; -- there is bug - table t1 missing "c" column
7         END LOOP;
8       END;
9       $function$
postgres=# 


=========================================
II Get all function defination of PostgreSQL 
=========================================
SELECT p.oid funcoid, n.nspname funcschema, p.proname funcname, pg_get_functiondef(p.oid) funcdefine
FROM pg_proc p
LEFT OUTER JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname NOT IN('information_schema', 'pg_catalog')
AND p.proname NOT IN('__plpgsql_check_function', '__plpgsql_check_function_tb','plpgsql_check_function', 'plpgsql_check_function_tb')


============================================
III Get check result for all functions
============================================
You can use the plpgsql_check_function for mass check functions and mass check triggers. Please, test following queries:

-- check all nontrigger plpgsql functions
SELECT p.oid, p.proname, plpgsql_check_function(p.oid)
   FROM pg_catalog.pg_namespace n
   JOIN pg_catalog.pg_proc p ON pronamespace = n.oid
   JOIN pg_catalog.pg_language l ON p.prolang = l.oid
  WHERE l.lanname = 'plpgsql' AND p.prorettype <> 2279;
or

SELECT p.proname, tgrelid::regclass, cf.*
   FROM pg_proc p
        JOIN pg_trigger t ON t.tgfoid = p.oid 
        JOIN pg_language l ON p.prolang = l.oid
        JOIN pg_namespace n ON p.pronamespace = n.oid,
        LATERAL plpgsql_check_function(p.oid, t.tgrelid) cf
  WHERE n.nspname = 'public' and l.lanname = 'plpgsql'
or

-- check all plpgsql functions (functions or trigger functions with defined triggers)
SELECT
    (pcf).functionid::regprocedure, (pcf).lineno, (pcf).statement,
    (pcf).sqlstate, (pcf).message, (pcf).detail, (pcf).hint, (pcf).level,
    (pcf)."position", (pcf).query, (pcf).context
FROM
(
    SELECT
        plpgsql_check_function_tb(pg_proc.oid, COALESCE(pg_trigger.tgrelid, 0)) AS pcf
    FROM pg_proc
    LEFT JOIN pg_trigger
        ON (pg_trigger.tgfoid = pg_proc.oid)
    WHERE
        prolang = (SELECT lang.oid FROM pg_language lang WHERE lang.lanname = 'plpgsql') AND
        pronamespace <> (SELECT nsp.oid FROM pg_namespace nsp WHERE nsp.nspname = 'pg_catalog') AND
        -- ignore unused triggers
        (pg_proc.prorettype <> (SELECT typ.oid FROM pg_type typ WHERE typ.typname = 'trigger') OR
         pg_trigger.tgfoid IS NOT NULL)
    OFFSET 0
) ss
ORDER BY (pcf).functionid::regprocedure::text, (pcf).lineno
 
=equal to ===============================================================
SELECT (pcf).functionid::regprocedure, (pcf).lineno, (pcf).statement,   
(pcf).sqlstate, (pcf).message, (pcf).detail, (pcf).hint, (pcf).level,    
(pcf)."position", (pcf).query, (pcf).context
 ,funcoid::varchar, funcschema::varchar, funcname::varchar, typname::varchar
FROM (  
    SELECT plpgsql_check_function_tb(p.oid, COALESCE(trig.tgrelid, 0), fatal_errors:= false) pcf
       , p.oid as funcoid ,nsp.nspname funcschema , p.proname as funcname, typ.typname
    FROM pg_proc p        
    JOIN pg_namespace nsp ON(nsp.oid = P.pronamespace )
    JOIN pg_language lang ON(lang.oid = p.prolang )
    JOIN pg_type typ ON(typ.oid = p.prorettype)
    LEFT JOIN pg_trigger trig ON (trig.tgfoid = p.oid) 
    WHERE lang.lanname IN('plpgsql')
    AND nsp.nspname NOT IN('pg_catalog')
    AND (typ.typname NOT IN('trigger') OR trig.tgfoid IS NOT NULL) 
    OFFSET 0) cont
ORDER BY (pcf).functionid::regprocedure::text, (pcf).lineno;
=======================================================================







