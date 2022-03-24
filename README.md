# README #

Este documento al orden que se deben poner los objetos para la liberacion del release y validaciones necesarias para cuando se coloque algun script

https://nuxiba.atlassian.net/wiki/spaces/CW/pages/101843033/Database+pasos+para+validar+archivo

## Orden de creacion de objetos ##

* DDL (Data Definition Language)
    * Create
    * Drop
    * Alter

* DML (Data Manipulation Language)
    * Select
    * Update
    * Delete
    * Insert

* Contraint Object Types
    * C = CHECK constraint
    * D = DEFAULT (constraint or stand-alone)
    * F = FOREIGN KEY constraint
    * PK = PRIMARY KEY constraint
    * R = Rule (old-style, stand-alone)
    * UQ = UNIQUE constraint

* Function Object Types
    * FN Scalar function
	* IF Inline table-valued function
	* TF Table-valued-function
	* FS Assembly (CLR) scalar-function
	* FT Assembly (CLR) table-valued function


#### TABLES ####


``` 
-- When table exists
if exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

-- When table does not exists
if not exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

```

#### COLUMNS ####

``` 
-- When column exists
if exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When column does not exists
if not exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

```

#### CONSTRAINTS ####

``` 
-- When constraint exists
if exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not exists
if not exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

-- When constraint primariy key
if exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = 'PK' and OBJECT_NAME(o.parent_object_id) = 'yourTableName')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not primariy key
if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = 'PK' and OBJECT_NAME(o.parent_object_id) = 'yourTableName')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not foreign key
if exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)='yourTableName' and  c1.[name]='yourColumnName')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not foreign key
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)='yourTableName' and  c1.[name]='yourColumnName')
	begin
		Use DDL or DML as you need
	end
-- When constraint drop foreing key
declare @name nvarchar(max),@sql2 nvarchar(max)
if exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)='ReportsFiltersRange' and  c1.[name]='filtername') begin
	SELECT @name =OBJECT_NAME(f.constraint_object_id) FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)='ReportsFiltersRange' and  c1.[name]='filtername'
	set @sql2='ALTER TABLE ReportsFiltersRange DROP CONSTRAINT '+@name
	exec (@sql2)
end

```

#### INDEXES ####

``` 
--NO saber el nombre Index
declare @name nvarchar(max),@sql2 nvarchar(max)
if exists(SELECT  OBJECT_NAME(ind.object_id) AS ObjectName
      , ind.name AS IndexName
      , col.name AS ColumnName
FROM    sys.indexes ind
        INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id AND ind.index_id = ic.index_id
        INNER JOIN sys.columns col ON ic.object_id = col.object_id AND ic.column_id = col.column_id
        INNER JOIN sys.tables t ON ind.object_id = t.object_id
WHERE   t.is_ms_shipped = 0 and OBJECT_NAME(ind.object_id)='ContactMeanIn' and col.name='connUser')
begin
	SELECT  @name= ind.name FROM    sys.indexes ind
			INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id AND ind.index_id = ic.index_id
			INNER JOIN sys.columns col ON ic.object_id = col.object_id AND ic.column_id = col.column_id
			INNER JOIN sys.tables t ON ind.object_id = t.object_id
	WHERE   t.is_ms_shipped = 0 and OBJECT_NAME(ind.object_id)='ContactMeanIn' and col.name='connUser'
	set @sql2='ALTER TABLE ContactMeanIn DROP CONSTRAINT '+@name
	exec (@sql2)
end


-- When index exists
if exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When index does not exists
if not exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

```

#### TRIGGERS ####

``` 
-- When trigger exists
if exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When trigger does not exists
if not exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

```

#### FUNCTIONS ####

``` 
-- When function exists
if exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

-- When function does not exists
if not exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

```

#### STORED PROCEDURES ####

``` 
-- When stored procedure exists
if exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

-- When stored procedure does not exists
if not exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

```

#### VIEWS ####

``` 
-- When view exists
if exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

-- When view does not exists
if not exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

JOBS (In this case be careful about what to do)
-- if you want to create, modify or delete use the script below
if exists (select * from msdb.dbo.sysjobs_view where name = N'yourJobName')
	begin
		exec msdb.dbo.sp_delete_job @job_name = N'yourJobName', @delete_unused_schedule=1
	end
```

#### DATABASES ####

``` 
-- When database exists
if exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

-- When database does not exists
if not exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

```

#### LOGINS ####

``` 
-- When login exists
if exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

-- When login does not exists
if not exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end
```

#### SERVER ROLES ####

``` 
-- When server role exists
if exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

-- When server role does not exists
if not exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

```

#### SCHEMAS ####

``` 
-- When schema exists
if exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

-- When schema does not exists
if not exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end
```

#### Replication ####

``` 

-- Replication scripts are generated apart so you have to check them and consider the validations implemented on those scripts
	* Publications
	* Subscriptions on publisher
	* Subscriptions
	* Snapshots

```