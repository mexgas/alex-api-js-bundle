
--select * from DataInformation A where tableName='ccCamps' order by columnName
--select * from DataInformation where tableName='ccCamps_Consulta' order by columnName

;with dataCamp as(
select * from DataInformation A where tableName='ccCamps')
, dataCampConsulta as(
select * from DataInformation where tableName='ccCamps_Consulta') 

--update B set B.comments=A.comments
--from dataCamp A
--inner join DataInformation B on B.tableName='ccCamps_Consulta' and A.columnName=B.columnName
--where A.comments is not null


select A.*,B.comments 
from dataCamp A
inner join DataInformation B on B.tableName='ccCamps_Consulta' and A.columnName=B.columnName
where A.comments is not null
