# Zabbix

[Press Releases](https://www.zabbix.com/pr)



##### Doc

[官方Zabbix 3.0 从入门到精通](https://www.cnblogs.com/clsn/p/7885990.html)

[Zabbix实现原理及架构详解](https://www.cnblogs.com/mysql-dba/p/5010902.html)



##### Deployment

DB Server: agent(db, os, device,application)
Proxy(optional): help to gather data 
Zabbix Server:
       front process
       http API
       backend process(gather data from DB server to config db) 
       config DB(store config info and collected data)



