/********************************
BORRA LAS RELACIONES DE LA TABLA DE DISTRIBUCION
********************************/

declare @num int,@count int
declare @name nvarchar(max),@tableName nvarchar(max),@sql nvarchar(max)

/***********************************************Elimina los trigger***********************************************/
SELECT 
	ROW_NUMBER() OVER(ORDER BY sysobjects.name  DESC) AS row,
     sysobjects.name AS trigger_name 
    ,USER_NAME(sysobjects.uid) AS trigger_owner 
    ,s.name AS table_schema 
    ,OBJECT_NAME(parent_obj) AS table_name 
    ,OBJECTPROPERTY( id, 'ExecIsUpdateTrigger') AS isupdate 
    ,OBJECTPROPERTY( id, 'ExecIsDeleteTrigger') AS isdelete 
    ,OBJECTPROPERTY( id, 'ExecIsInsertTrigger') AS isinsert 
    ,OBJECTPROPERTY( id, 'ExecIsAfterTrigger') AS isafter 
    ,OBJECTPROPERTY( id, 'ExecIsInsteadOfTrigger') AS isinsteadof 
    ,OBJECTPROPERTY(id, 'ExecIsTriggerDisabled') AS [disabled] 
    into #triggerTempDistributtion
FROM sysobjects 
	INNER JOIN sysusers ON sysobjects.uid = sysusers.uid 
	INNER JOIN sys.tables t ON sysobjects.parent_obj = t.object_id 
	INNER JOIN sys.schemas s  ON t.schema_id = s.schema_id 
WHERE sysobjects.type = 'TR' and sysobjects.name like '%merge%'


select @count= COUNT(*),@num=1 from #triggerTempDistributtion

while  @num<=@count begin
	select @name = trigger_name from #triggerTempDistributtion where row = @num;
	set @sql='drop trigger '+@name
	exec(@sql)
	set @num= @num+1
end





/***********************************************Elimina los CONSTRAINT***********************************************/
SELECT
	ROW_NUMBER() OVER(ORDER BY default_constraints.name  DESC) AS row,
    default_constraints.name as name_constraints,tables.name as table_name
	into #tempConstraint
FROM 
    sys.all_columns
        INNER JOIN sys.tables ON all_columns.object_id = tables.object_id
        INNER JOIN sys.schemas ON tables.schema_id = schemas.schema_id
        INNER JOIN sys.default_constraints ON all_columns.default_object_id = default_constraints.object_id       
        WHERE schemas.name = 'dbo' AND all_columns.name = 'rowguid'

select @count= COUNT(*),@num=1 from #tempConstraint

while  @num<=@count begin
	select @tableName = table_name,@name= name_constraints from #tempConstraint where row = @num;
	set @sql='ALTER TABLE '+@tableName+' DROP CONSTRAINT '+@name	
	exec(@sql)
	set @num= @num+1
end



/***********************************************Elimina los INDEX***********************************************/
SELECT 
	ROW_NUMBER() OVER(ORDER BY A.name  DESC) AS row,
	A.name as name_index,object_name(A.id) as table_name
	into #tempIndex
	FROM sysindexes A where name like '%merge%'

select @count= COUNT(*),@num=1 from #tempIndex

while  @num<=@count begin
	select @tableName = table_name,@name = name_index from #tempIndex where row = @num;
	set @sql='DROP INDEX '+@name+' ON '+@tableName	
	exec(@sql)
	set @num= @num+1
end



/***********************************************Elimina los rowguid***********************************************/
SELECT  
	ROW_NUMBER() OVER(ORDER BY sysobjects.name  DESC) AS row,
	sysobjects.name AS table_name, syscolumns.name AS column_name, 
	systypes.name AS datatype, syscolumns.LENGTH AS LENGTH
	into #tempTableRowguid
FROM       sysobjects INNER JOIN syscolumns ON sysobjects.id = syscolumns.id INNER JOIN systypes ON syscolumns.xtype = systypes.xtype
WHERE     (sysobjects.xtype = 'U') and (UPPER(syscolumns.name) like upper('rowguid')) 
ORDER BY sysobjects.name, syscolumns.colid	

select @count= COUNT(*),@num=1 from #tempTableRowguid

while  @num<=@count begin
	select @name = table_name from #tempTableRowguid where row = @num;
	set @sql='ALTER TABLE '+@name+' DROP COLUMN rowguid'	
	print(@sql)
	exec(@sql)
	set @num= @num+1
end

drop table #triggerTempDistributtion
drop table #tempConstraint
drop table #tempIndex
drop table #tempTableRowguid