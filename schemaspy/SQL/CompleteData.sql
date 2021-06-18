Use CCReportsRIA;

With  TableCol AS(
SELECT 
	ta.name tableName,
    c.name columnName,
    t.Name 'Data type'

FROM    
    sys.columns c
inner join sys.tables ta on c.object_id=ta.object_id
INNER JOIN 
    sys.types t ON c.user_type_id = t.user_type_id
where ta.name like 'Rep%'
)

insert into DataInformation
select A.tableName,A.columnName,B.Nombre  from TableCol A
inner join DataColumn B on A.columnName=B.[column]
left join DataInformation C on A.tableName=C.tableName and A.columnName=C.columnName
where C.tableName is null
--truncate table DataInformation