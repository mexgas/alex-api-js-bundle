CREATE DATABASE CCenterRIA
ON (FILENAME = '/var/opt/mssql/data/CCenterRIA.mdf'),
(FILENAME = '/var/opt/mssql/data/CCenterRIA_log.ldf')
FOR ATTACH;


CREATE DATABASE CCReportsRIA
ON (FILENAME = '/var/opt/mssql/data/ccReportsRia.mdf'),
(FILENAME = '/var/opt/mssql/data/ccReportsRia_1.ldf')
FOR ATTACH;


CREATE DATABASE CCRecorderRIA
ON (FILENAME = '/var/opt/mssql/data/CCRecorderRIA.mdf'),
(FILENAME = '/var/opt/mssql/data/CCRecorderRIA_log.ldf')
FOR ATTACH;
