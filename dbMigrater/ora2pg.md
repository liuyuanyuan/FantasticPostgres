# Ora2Pg

Ora2Pg - Free and open source migrator from Oracle to PostgreSQL, writed by Perl.

Github: https://github.com/darold/ora2pg
Install Ref: https://www.cnblogs.com/alighie/p/7834136.html

---------------------------------
### Preparation

Centos7
Oracle12c -12.2.0
Ora2Pg19.1

----------------------------------
### Installation

1 Install Oracle client（At least client）
Install Oracle client（At least）
ref: https://blog.csdn.net/tracy1talent/article/details/82861495

download
https://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html

install
rpm -ivh oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
rpm -ivh oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm

query installed dir
rpm -qpl oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm

config EVN
vi ~/.bash_profile

#add following

ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/12.2.0/dbhome_1; export ORACLE_HOME
ORACLE_SID=orcl; export ORACLE_SID
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib:/usr/lib64; export LD_LIBRARY_PATH

copy tnanames.ora from oracle server to client side, dir is:
/usr/lib/oracle/12.1/client64/network/admin


Or Install Oracle server and client
ref: https://wiki.centos.org/zh/HowTos/Oracle12onCentos7
(Must: su - oracle then run runInstaller TO start GUI installer)

vi ~/.bash_profile

#add following:

TMPDIR=$TMP; export TMPDIR
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/12.2.0/dbhome_1; export ORACLE_HOME
ORACLE_SID=orcl; export ORACLE_SID
PATH=$ORACLE_HOME/bin:$PATH; export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib:/usr/lib64; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH

------------------------------
2 Install ora2pg dependecncy
su - root

yum install perl-DBI perl-DBD-Pg perl-ExtUtils-MakeMaker gcc

wget http://search.cpan.org/CPAN/authors/id/P/PY/PYTHIAN/DBD-Oracle-1.74.tar.gz
tar -zxvf DBD-Oracle-1.74.tar.gz
cd DBD-Oracle-1.74
export ORACLE_HOME=/u01/app/oracle/product/12.2.0/dbhome_1
export LD_LIBRARY_PATH=/u01/app/oracle/product/12.2.0/dbhome_1/lib
perl Makefile.PL
make
make install

------------------------------
3 Install ora2pg
download: https://sourceforge.net/projects/ora2pg/
tar -jxvf ora2pg-19.1.tar.bz2
cd ora2pg-19.1
perl Makefile.PL
make
make install
/usr/local/bin/ora2pg

------------------------------
4 Config ora2pg.conf
vi /etc/ora2pg/ora2pg.conf
#Oracle
ORACLE_DSN dbi:Oracle:host=192.168.100.170;sid=orcl
ORACLE_USER lyy
ORACLE_PWD  lyy
SCHEMA LYY
TYPE TABLE
OUTPUT output.sql 
allow emp
#PostgreSQL
PG_DSN dbi:Pg:dbname=lyy;host=192.168.100.172;port=5433
PG_USER lyy
PG_PWD lyy

------------------------------
5 Execute ora2pg
/usr/local/bin/ora2pg -c /etc/ora2pg/ora2pg.conf  --debug
[2018-10-15 23:33:45] Ora2Pg version: 19.1
[2018-10-15 23:33:45] Trying to connect to database: dbi:Oracle:host=127.0.0.1;sid=orcl;port=1521
[2018-10-15 23:33:46] Isolation level: SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
[2018-10-15 23:33:46] Looking forward functions declaration in schema LYY.
[2018-10-15 23:33:46] Retrieving table information...
[2018-10-15 23:34:54] [1] Scanning table TAB (1 rows)...
[2018-10-15 23:34:58] Dumping table TAB...

login to PostgreSQL and execute output.sql
[postgres@serveroracle ~]$ psql
psql (9.6.2 dbi services build)
Type "help" for help.
postgres=# CREATE DATABASE lyy;
postgres=# \c lyy
You are now connected to database "orclpg" as user "postgres".
lyy=# create user lyy WITH PASSWORD 'lyy';
lyy=# \i output.sql

------------------------------
6 ora2pg help
/usr/local/bin/ora2pg --help
Usage: ora2pg [-dhpqv --estimate_cost --dump_as_html] [--option value]

    -a | --allow str  : Comma separated list of objects to allow from export.
    		Can be used with SHOW_COLUMN too.
    -b | --basedir dir: Set the default output directory, where files
    		resulting from exports will be stored.
    -c | --conf file  : Set an alternate configuration file other than the
    		default /etc/ora2pg/ora2pg.conf.
    -d | --debug      : Enable verbose output.
    -D | --data_type STR : Allow custom type replacement at command line.
    -e | --exclude str: Comma separated list of objects to exclude from export.
    		Can be used with SHOW_COLUMN too.
    -h | --help       : Print this short help.
    -g | --grant_object type : Extract privilege from the given object type.
    		See possible values with GRANT_OBJECT configuration.
    -i | --input file : File containing Oracle PL/SQL code to convert with
    		no Oracle database connection initiated.
    -j | --jobs num   : Number of parallel process to send data to PostgreSQL.
    -J | --copies num : number of parallel connection to extract data from Oracle.
    -l | --log file   : Set a log file. Default is stdout.
    -L | --limit num  : Number of tuples extracted from Oracle and stored in
    		memory before writing, default: 10000.
    -m | --mysql      : Export a MySQL database instead of an Oracle schema.
    -n | --namespace schema : Set the Oracle schema to extract from.
    -N | --pg_schema schema : Set PostgreSQL's search_path.
    -o | --out file   : Set the path to the output file where SQL will
    		be written. Default: output.sql in running directory.
    -p | --plsql      : Enable PLSQL to PLPGSQL code conversion.
    -P | --parallel num: Number of parallel tables to extract at the same time.
    -q | --quiet      : Disable progress bar.
    -s | --source DSN : Allow to set the Oracle DBI datasource.
    -t | --type export: Set the export type. It will override the one
    		given in the configuration file (TYPE).
    -T | --temp_dir DIR: Set a distinct temporary directory when two
                         or more ora2pg are run in parallel.
    -u | --user name  : Set the Oracle database connection user.
    	        ORA2PG_USER environment variable can be used instead.
    -v | --version    : Show Ora2Pg Version and exit.
    -w | --password pwd : Set the password of the Oracle database user.
    	        ORA2PG_PASSWD environment variable can be used instead.
    --forceowner      : Force ora2pg to set tables and sequences owner like in
    	  Oracle database. If the value is set to a username this one
    	  will be used as the objects owner. By default it's the user
    	  used to connect to the Pg database that will be the owner.
    --nls_lang code: Set the Oracle NLS_LANG client encoding.
    --client_encoding code: Set the PostgreSQL client encoding.
    --view_as_table str: Comma separated list of view to export as table.
    --estimate_cost   : Activate the migration cost evalution with SHOW_REPORT
    --cost_unit_value minutes: Number of minutes for a cost evalution unit.
    	  default: 5 minutes, correspond to a migration conducted by a
    	  PostgreSQL expert. Set it to 10 if this is your first migration.
      --dump_as_html     : Force ora2pg to dump report in HTML, used only with
                            SHOW_REPORT. Default is to dump report as simple text.
       --dump_as_csv      : As above but force ora2pg to dump report in CSV.
       --dump_as_sheet    : Report migration assessment one CSV line per database.
       --init_project NAME: Initialise a typical ora2pg project tree. Top directory
                            will be created under project base dir.
       --project_base DIR : Define the base dir for ora2pg project trees. Default
                            is current directory.
       --print_header     : Used with --dump_as_sheet to print the CSV header
                            especially for the first run of ora2pg.
       --human_days_limit num : Set the number human-days limit where the migration
                            assessment level switch from B to C. Default is set to
                            5 human-days.
       --audit_user LIST  : Comma separated list of username to filter queries in
                            the DBA_AUDIT_TRAIL table. Used only with SHOW_REPORT
                            and QUERY export type.
       --pg_dsn DSN       : Set the datasource to PostgreSQL for direct import.
       --pg_user name     : Set the PostgreSQL user to use.
       --pg_pwd password  : Set the PostgreSQL password to use.
       --count_rows       : Force ora2pg to perform a real row count in TEST action.
       --no_header        : Do not append Ora2Pg header to output file
       --oracle_speed     : use to know at which speed Oracle is able to send
                            data. No data will be processed or written written.
       --ora2pg_speed     : use to know at which speed Ora2Pg is able to send
                            transformed data. Nothing will be written.
See full documentation at http://ora2pg.darold.net/ for more help or see manpage with 'man ora2pg'.

ora2pg will return 0 on success, 1 on error. It will return 2 when a child
process has been interrupted and you've gotten the warning message:
    "WARNING: an error occurs during data export. Please check what's happen."
Most of the time this is an OOM issue, first try reducing DATA_LIMIT value.













