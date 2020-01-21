Q1. ORACLE XMLTYPE-PG XML

/* 
 Oracle XMLType needs xdb6.jar, xmlparserv2.jar, orai18n.jar.
 ojdbc6.jar; xdb6.jar download here: http://www.oracle.com/technetwork/database/enterprise-edition/jdbc-112010-090769.html
 xmlparserv2-11.1.1.jar available here: (SQL Developer) (in sqldeveloper\modules\oracle.xdk_12.1.2)
*/
// 1 convert rs to OracleResultSet 
OracleResultSet ors = (OracleResultSet)rawrs;
// 2 get oracle XMLTYPE data 
XMLType xmltype = (XMLType) ors.getObject(index);	
// 3 make SQLXML from oracle XMLTYPE data		
SQLXML xml = baseConn.createSQLXML();
xml.setString(xmltype.getString());

// 4 setSQLXML for pg ppstmt
pgPpst.setSQLXML(index, xml);
// ppstmt.setSQLXML(index, rawrs.getSQLXML(index));//this failed cause oracle not support getSQLXML()


Q2. ORACLE BLOB/RAW/LONG RAW/BFILE - PG bytea/oid
doc: https://jdbc.postgresql.org/documentation/head/binary-data.html




