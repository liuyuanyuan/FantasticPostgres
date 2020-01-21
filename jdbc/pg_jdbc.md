# [PGJDBC](https://jdbc.postgresql.org/) - PostgreSQL JDBC Driver

#### References

###### Use References

- [Download Jar (also have Source)](https://jdbc.postgresql.org/download.html)

- [Private API](https://jdbc.postgresql.org/development/privateapi/index.html)

- [Official Document (head)](https://jdbc.postgresql.org/documentation/head/index.html)

- [Changelog List](https://jdbc.postgresql.org/index.html)

###### Develop References

- [Official GIT ](https://jdbc.postgresql.org/development/git.html)

- [Github](https://github.com/pgjdbc/pgjdbc)

- [Development (About the Driver, Tools, Build Process, Test Suite)](https://jdbc.postgresql.org/development/development.html)

- [Todo List](https://jdbc.postgresql.org/development/todo.html)

- [Community (PG Weekly News, Mailing List) ](https://jdbc.postgresql.org/community/community.html)

  

#### About

>**PostgreSQL JDBC Driver** (*PgJDBC* for short) allows Java programs to connect to a PostgreSQL database using standard, database independent Java code. Is an open source JDBC driver written in Pure Java (Type 4), and communicates in the [PostgreSQL native network protocol](https://www.postgresql.org/docs/current/protocol.html).
>
>The current version of the driver should be compatible with **PostgreSQL 8.2 and higher**, and **Java 6** (JDBC 4.0), **Java 7** (JDBC 4.1), **Java 8** (JDBC 4.2) and **Java 9**.



#### Use PGJDBC to Connect to PostgreSQL

###### Get pgjdbc driver

for general project: download jar from [official download](https://jdbc.postgresql.org/download.html) .

for maven project: add following setting into POX.xml

```
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <version>42.2.9</version>
</dependency>
```

###### Connect to PostgreSQL in Java:

 via a URL referencing [official connection url propertis](https://jdbc.postgresql.org/documentation/head/connect.html) .



#### Use feature of  load balance and connection failover 

>###### Load Balance
>
>- **loadBalanceHosts** = boolean
>
>In default mode (disabled) hosts are connected in the given order. If enabled hosts are chosen randomly from the set of suitable candidates.
>
>###### Connection Fail-over
>
>To support simple connection fail-over it is possible to define multiple endpoints (host and port pairs) in the connection url separated by commas. The driver will try to once connect to each of them in order until the connection succeeds. If none succeed, a normal connection exception is thrown.
>
>The syntax for the connection url is:
>
>```
>jdbc:postgresql://host1:port1,host2:port2/database
>```
>
>The simple connection fail-over is useful when running against a high availability postgres installation that has identical data on each node. For example streaming replication postgres or postgres-xc cluster.
>
>For example an application can create two connection pools. One data source is for writes, another for reads. The write pool limits connections only to master node:
>
>`jdbc:postgresql://node1,node2,node3/accounting?targetServerType=master`.
>
>And read pool balances connections between slaves nodes, but allows connections also to master if no slaves are available:
>
>```
>jdbc:postgresql://node1,node2,node3/accounting?targetServerType=preferSlave&loadBalanceHosts=true
>```
>
>If a slave fails, all slaves in the list will be tried first. If the case that there are no available slaves the master will be tried. If all of the servers are marked as "can't connect" in the cache then an attempt will be made to connect to all of the hosts in the URL in order.



#### Develop PGJDBC Source

>###### Git Clone Code
>
>```git
>git clone git://github.com/pgjdbc/pgjdbc.git
>```
>
>###### Tools to Develop 
>
>The following tools are required to build and test the driver:
>
>- [Java 6 Standard Edition Development Kit](https://java.oracle.com/) At least JDK 1.6
>- [Apache Maven](https://maven.apache.org/) At least 3.1.1
>- [Git SCM](https://git-scm.com/)
>- [A PostgreSQL instance](https://www.postgresql.org/) to run the tests.
>
>###### Build Process
>
>After retrieving the source from the [git repository](https://jdbc.postgresql.org/development/git.html). Move into the **top level pgjdbc directory** and simply type `mvn package -DskipTests`. This will build the appropriate driver for your current Java version and place it into **target/postgresql-${version}.jar**.
>
>###### Test Suite
>
>To make sure the driver is working as expected there are a set of JUnit tests that should be run. These require a database to run against that has the plpgsql procedural language installed. The default parameters for username and database are "test", and for password it's "test". so a sample interaction to set this up would look the following, if you enter "password" when asked for it:
>
>```plsql
>postgres@host:~$ createuser -d -A test -P
>Enter password for user "test": 
>Enter it again: 
>CREATE USER
>
>postgres@host:~$ createdb -U test test
>CREATE DATABASE
>
>postgres@host:~$ createlang plpgsql test
>```
>
>Now we're ready to run the tests, we simply type mvn clean package, and it should be off and running. To use non default values to run the regression tests, you can create a build.local.properties in the top level directory. This properties file allows you to set values for host, database, user, password, and port with the standard properties "key = value" usage. The ability to set the port value makes it easy to run the tests against a number of different server versions on the same machine.

