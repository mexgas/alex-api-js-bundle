/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.33

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 34
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'IA_States'
	SET @sql = 'if not exists (select * from sys.columns where name = N''ia_state'' and Object_ID = Object_ID(N''ccRIALoading''))
    begin
        ALTER TABLE ccRIALoading ADD ia_state int;
end';
	EXEC(@sql);

	SET @process = 'IA_States'
	SET @sql = 'if not exists(select * from sys.tables where name=''IA_States'') begin
	CREATE TABLE IA_States (
		id int,
		description varchar(255),
	);
	
end';
	EXEC(@sql);

	SET @process = 'IA_States'
	SET @sql = 'if not exists(select id from IA_States where id=1) begin
	INSERT INTO IA_States VALUES(1,''En espera de copiado a IA'');
end';
	EXEC(@sql);

	SET @process = 'K038008-Servicio IA Service setting replicación de tablas'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccAIReplicaConfiguration'') begin
CREATE TABLE [dbo].[ccAIReplicaConfiguration](
	[idConfig] [smallint] IDENTITY(1,1) NOT NULL,
	[tableName] [varchar](255) NOT NULL,
	[columnPrimaryKey] [varchar](255) NOT NULL,
	[triggerName] [varchar](255) NOT NULL,
	[active] [bit] NOT NULL,
	[timeCheck] [int] NOT NULL,
	[dateLastCheck] [datetime] NULL,
	[columnWhereDays] [varchar](255) NULL,
	[copyContent] [bit] NULL
)
end
';
	EXEC(@sql);

	SET @process = 'K038016-Servicio IA-Actualiza ccoCallsOutSource al cargar BD'
	SET @sql = 'if not exists(select * from sys.tables where name=''cc_CalloutDateIA'') begin
CREATE TABLE [dbo].[cc_CalloutDateIA](
	[CalloutId] [int] NOT NULL primary Key,
	[DateDial] [datetime] NULL,
	)
end
';
	EXEC(@sql);

	SET @process = 'K038008-Servicio IA Service table ccoLogDialsTmpIA'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccoLogDialsTmpIA'') begin
CREATE TABLE ccoLogDialsTmpIA (
    logDial_id int not null primary key,
dateUpdate datetime not null
);

end';
	EXEC(@sql);

	SET @process = 'K038008-Servicio IA Service table ccCampsTmpIA'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccCampsTmpIA'') begin
CREATE TABLE ccCampsTmpIA (
    cam_id int not null primary key,
    dateUpdate datetime not null
);

end';
	EXEC(@sql);

	SET @process = 'K038008-Servicio IA Service table ccoCallsOutSourceTmpIA'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccoCallsOutSourceTmpIA'') begin
CREATE TABLE ccoCallsOutSourceTmpIA (
    callout_id int not null primary key,
    dateUpdate datetime not null
);
end';
	EXEC(@sql);

	SET @process = 'K038008-Servicio IA Service table ccoCallsOutTmpIA'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccoCallsOutTmpIA'') begin
CREATE TABLE ccoCallsOutTmpIA (
    cal_id int not null primary key,
    dateUpdate datetime not null
);
end';
	EXEC(@sql);

	SET @process = 'K038008-Servicio IA Service table ccRIALoadingTmpIA'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccRIALoadingTmpIA'') begin
CREATE TABLE ccRIALoadingTmpIA (
    load_id int not null primary key,
    dateUpdate datetime not null
);
end';
	EXEC(@sql);

	SET @process = 'K038008-Servicio IA Service table ccoLogDialsTmpIA'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccUsersTmpIA'') begin
CREATE TABLE ccUsersTmpIA (
    User_id smallint not null primary key,
    dateUpdate datetime not null
);

end';
	EXEC(@sql);


	SET @process = 'K038008-Servicio IA Service setting replicación de tablas '
	SET @sql = 'if not exists(select tableName from ccAIReplicaConfiguration where tableName=''ccoLogDials'') begin
	insert into ccAIReplicaConfiguration (tableName,columnPrimaryKey,triggerName,active,timeCheck,columnWhereDays) 
	values(''ccoLogDials'',''logDial_id'',''tg_ccoLogDials_IA'',0,10,''fecha'')
end



if not exists(select tableName from ccAIReplicaConfiguration where tableName=''ccoCallsOutSource'') begin
	insert into ccAIReplicaConfiguration (tableName,columnPrimaryKey,triggerName,active,timeCheck,columnWhereDays) 
	values(''ccoCallsOutSource'',''callout_id'',''tg_ccoCallsOutSource_IA'',0,10,''cal_fechaDial'')
end

if not exists(select tableName from ccAIReplicaConfiguration where tableName=''ccoCallsOut'') begin
	insert into ccAIReplicaConfiguration (tableName,columnPrimaryKey,triggerName,active,timeCheck,columnWhereDays) 
	values(''ccoCallsOut'',''cal_id'',''tg_ccoCallsOut_IA'',0,10,''cal_Inicio'')
end

if not exists(select tableName from ccAIReplicaConfiguration where tableName=''ccCamps'') begin
	insert into ccAIReplicaConfiguration (tableName,columnPrimaryKey,triggerName,active,timeCheck) 
	values(''ccCamps'',''cam_id'',''tg_ccCamps_IA'',0,30)
end

if not exists(select tableName from ccAIReplicaConfiguration where tableName=''ccUsers'') begin
	insert into ccAIReplicaConfiguration (tableName,columnPrimaryKey,triggerName,active,timeCheck) 
	values(''ccUsers'',''User_id'',''tg_ccUsersTmp_IA'',0,30)
end
if not exists(select tableName from ccAIReplicaConfiguration where tableName=''ccRIALoading'') begin
	insert into ccAIReplicaConfiguration (tableName,columnPrimaryKey,triggerName,active,timeCheck,copyContent, columnWhereDays) 
	values(''ccRIALoading'',''load_id'',''tg_ccRIALoading_IA'',0,60,0, ''loadDate'')
end
';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccCamps_IA'
	SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccCamps_IA'' and parent_id = OBJECT_ID(N''ccCamps''))
begin      
	drop trigger [tg_ccCamps_IA]    
end';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccoCallsOutSource_IA'
	SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccoCallsOutSource_IA'' and parent_id = OBJECT_ID(N''ccoCallsOutSource''))
begin 
	drop trigger [tg_ccoCallsOutSource_IA]    
end';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccoCallsOut_IA'
	SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccoCallsOut_IA'' and parent_id = OBJECT_ID(N''ccoCallsOut''))
begin      
	drop trigger [tg_ccoCallsOut_IA]    
end';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccoLogDials_IA'
	SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccoLogDials_IA'' and parent_id = OBJECT_ID(N''ccoLogDials''))
begin 
	drop trigger [tg_ccoLogDials_IA]    
end';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccUsersTmp_IA'
	SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccUsersTmp_IA'' and parent_id = OBJECT_ID(N''ccUsers''))
begin 
	drop trigger [tg_ccUsersTmp_IA]    
end
';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccRIALoading_IA'
	SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccRIALoading_IA'' and parent_id = OBJECT_ID(N''ccRIALoading''))
begin 
	drop trigger [tg_ccRIALoading_IA]    
end
';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de ccRIALoading'
	SET @sql = 'CREATE TRIGGER dbo.tg_ccRIALoading_IA
ON dbo.ccRIALoading	
AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	declare @datenow datetime=getdate()
	update B set B.dateUpdate=@datenow FROM INSERTED A
	inner join ccRIALoadingTmpIA B on A.[load_id]=b.[load_id]
	inner join ccCamps c on c.cam_id=A.cam_id and c.CampType=4


	insert into ccRIALoadingTmpIA
	select A.[load_id],@datenow from INSERTED A
	inner join ccCamps c on c.cam_id=A.cam_id and c.CampType=4
	left join  ccRIALoadingTmpIA B on A.[load_id]=b.[load_id]
	where B.dateUpdate is null

END
';
	EXEC(@sql)

	SET @process = 'K038009-Servicio IA Service replicación de ccCamps'
	SET @sql = 'CREATE TRIGGER [dbo].[tg_ccCamps_IA]
ON [dbo].[ccCamps]
After INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
	
	declare @datenow datetime=getdate()


	update B set B.dateUpdate=@datenow FROM INSERTED A
	inner join ccCampsTmpIA B on A.cam_id=b.cam_id and A.CampType=4

	insert into ccCampsTmpIA
	select A.cam_id,@datenow from INSERTED A
	left join ccCampsTmpIA B on A.cam_id=B.cam_id  
	where B.cam_id is null and A.CampType=4

END';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de ccoCallsOutSource'
	SET @sql = 'CREATE TRIGGER dbo.tg_ccoCallsOutSource_IA
ON dbo.ccoCallsOutSource
AFTER INSERT, UPDATE
AS 
BEGIN
    SET NOCOUNT ON;

	declare @datenow datetime=getdate()
	update B set B.dateUpdate=@datenow FROM INSERTED A
	inner join ccoCallsOutSourceTmpIA B on A.callout_id=b.callout_id
	inner join ccCamps c on c.cam_id=A.cam_id and c.CampType=4

	insert into ccoCallsOutSourceTmpIA
	select A.callout_id,@datenow from INSERTED A
	inner join ccCamps c on c.cam_id=A.cam_id and c.CampType=4
	left join ccoCallsOutSourceTmpIA B on A.callout_id=b.callout_id
	where B.dateUpdate is null

END';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de ccoCallsOut'
	SET @sql = 'CREATE TRIGGER dbo.tg_ccoCallsOut_IA
ON dbo.ccoCallsOut
AFTER INSERT, UPDATE
AS 
BEGIN
    SET NOCOUNT ON;

	declare @datenow datetime=getdate()
	update B set B.dateUpdate=@datenow FROM INSERTED A
	inner join ccoCallsOutTmpIA B on A.cal_id=b.cal_id
	inner join ccCamps c on c.cam_id=A.cam_id and c.CampType=4

	insert into ccoCallsOutTmpIA
	select A.cal_id,@datenow from INSERTED A
	inner join ccCamps c on c.cam_id=A.cam_id and c.CampType=4
	left join ccoCallsOutTmpIA B on A.cal_id=b.cal_id
	where B.dateUpdate is null

END';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de ccoLogDials'
	SET @sql = 'CREATE TRIGGER dbo.tg_ccoLogDials_IA
ON dbo.ccoLogDials
AFTER INSERT, UPDATE
AS 
BEGIN
    SET NOCOUNT ON;

	declare @datenow datetime=getdate()
	update B set B.dateUpdate=@datenow FROM INSERTED A
	inner join ccoLogDialsTmpIA B on A.logDial_id=b.logDial_id
	inner join ccCamps c on c.cam_id=A.cam_id and c.CampType=4

	insert into ccoLogDialsTmpIA
	select A.logDial_id,@datenow from INSERTED A
	inner join ccCamps c on c.cam_id=A.cam_id and c.CampType=4
	left join ccoLogDialsTmpIA B on A.logDial_id=B.logDial_id
	where B.logDial_id is null

END';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de ccUsers'
	SET @sql = 'CREATE TRIGGER dbo.tg_ccUsersTmp_IA
ON dbo.ccUsers	
AFTER INSERT, UPDATE
AS 
BEGIN
    SET NOCOUNT ON;

	declare @datenow datetime=getdate()
	update B set B.dateUpdate=@datenow FROM INSERTED A
	inner join ccUsersTmpIA B on A.[User_id]=b.[User_id]

	insert into ccUsersTmpIA
	select A.[User_id],@datenow from INSERTED A
	left join  ccUsersTmpIA B on A.[User_id]=b.[User_id]
	where B.dateUpdate is null

END';
	EXEC(@sql);

	SET @process = 'K038009-Servicio Drop ccsp_GalateaArtificialIntelligence'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaArtificialIntelligence'')
    begin
        DROP PROCEDURE ccsp_GalateaArtificialIntelligence;
    end';
	EXEC(@sql);

	SET @process = 'K038009-Servicio Create ccsp_GalateaArtificialIntelligence'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaArtificialIntelligence] 

@option AS SMALLINT, 
@tableName varchar(255) = null,
@tableNameTmpIA varchar(255) = null,
@columnNameId varchar(255) = null,
@dateLastCheck datetime = null,
@columnWhereDays varchar(255)=null,
@EnableOrDisableTrigger bit =0,
@listLoadings varchar(8000) =null,
@IAState int =null

AS
BEGIN
SET NOCOUNT ON;

DECLARE @object_name SYSNAME, @object_id INT;
DECLARE @SQL NVARCHAR(MAX) = '''', @primaryKey NVARCHAR(max), @CONSTRAINT NVARCHAR(max) = ''''
DECLARE @columns XML,@index nvarchar(max)=''''

IF @option in(0,1) begin
	SELECT @object_name = ''['' + s.name + ''].['' + o.name + '']'', @object_id = o.object_id
	FROM sys.objects AS o WITH (NOWAIT)
	INNER JOIN sys.schemas AS s WITH (NOWAIT) ON o.schema_id = s.schema_id
	WHERE o.name = @tableName AND o.type = ''U'' AND o.is_ms_shipped = 0;
end

IF @option = 0   --Create Table
BEGIN  
	SET @columns = (
	SELECT CHAR(9) + '', ['' + c.name + ''] '' 
	+ CASE 
	WHEN c.is_computed = 1
		THEN ''AS '' + cc.DEFINITION
	ELSE UPPER(tp.name) + CASE 
			WHEN tp.name IN (''varchar'', ''char'', ''varbinary'', ''binary'', ''text'')
				THEN ''('' + CASE 
						WHEN c.max_length = - 1
							THEN ''MAX''
						ELSE CAST(c.max_length AS VARCHAR(5))
						END + '')''
			WHEN tp.name IN (''nvarchar'', ''nchar'', ''ntext'')
				THEN ''('' + CASE 
						WHEN c.max_length = - 1
							THEN ''MAX''
						ELSE CAST(c.max_length / 2 AS VARCHAR(5))
						END + '')''
			WHEN tp.name IN (''datetime2'', ''time2'', ''datetimeoffset'')
				THEN ''('' + CAST(c.scale AS VARCHAR(5)) + '')''
			WHEN tp.name = ''decimal''
				THEN ''('' + CAST(c.precision AS VARCHAR(5)) + '','' + CAST(c.scale AS VARCHAR(5)) + '')''
			ELSE ''''
			END + CASE 
			WHEN c.collation_name IS NOT NULL
				THEN '' COLLATE '' + c.collation_name
			ELSE ''''
			END + CASE 
			WHEN c.is_nullable = 1
				THEN '' NULL''
			ELSE '' NOT NULL''
			END  
				
	END + CHAR(13) 
	FROM sys.columns AS c WITH (NOWAIT)
	INNER JOIN sys.types AS tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id	
	LEFT JOIN sys.computed_columns AS cc WITH (NOWAIT) ON c.object_id = cc.object_id
		AND c.column_id = cc.column_id
	LEFT JOIN sys.default_constraints AS dc WITH (NOWAIT) ON c.default_object_id != 0
		AND c.object_id = dc.parent_object_id
		AND c.column_id = dc.parent_column_id
	LEFT JOIN sys.identity_columns AS ic WITH (NOWAIT) ON c.is_identity = 1
		AND c.object_id = ic.object_id
		AND c.column_id = ic.column_id
	WHERE c.object_id = @object_id
		AND c.name <> ''rowguid''
	ORDER BY c.column_id
	FOR XML PATH(''''), TYPE
	)

	SELECT @primaryKey = isnull(CHAR(9) + '', CONSTRAINT ['' + k.name + ''] PRIMARY KEY ('' + (
				SELECT STUFF((
							SELECT '', ['' + c.name + ''] '' + CASE WHEN ic.is_descending_key = 1 THEN ''DESC'' ELSE ''ASC'' END
							FROM sys.index_columns AS ic WITH (NOWAIT)
							INNER JOIN sys.columns AS c WITH (NOWAIT) ON c.object_id = ic.object_id AND c.column_id = ic.column_id
							WHERE ic.is_included_column = 0 AND ic.object_id = k.parent_object_id AND ic.index_id = k.unique_index_id
							FOR XML PATH(N''''), TYPE
							).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''')
				) + '')'' + CHAR(13), '''') + '')'' + CHAR(13)
	FROM sys.key_constraints AS k WITH (NOWAIT)
	WHERE k.parent_object_id = @object_id AND k.type = ''PK'';


	SELECT @SQL = ''CREATE TABLE '' + @object_name + CHAR(13) + ''('' + CHAR(13)  + CHAR(9)+'' ''
	+ STUFF((@columns).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''')
	+ isnull(@primaryKey,'')'')
	+ @CONSTRAINT
	+ @index

	select @SQL as [query];

END;

ELSE IF @option = 1  -- Alter Table Add Column
BEGIN
	SELECT 	
	''if not exists (select * from sys.columns where name = N'''''' + c.name + '''''' and Object_ID = Object_ID(N'''''' + @tableName + 
		'''''')) begin '' + ''ALTER TABLE '' + @tableName + '' ADD ['' + c.name + ''] '' + CASE 
	WHEN c.is_computed = 1
		THEN ''AS '' + cc.DEFINITION
	ELSE UPPER(tp.name) + CASE 
			WHEN tp.name IN (''varchar'', ''char'', ''varbinary'', ''binary'', ''text'')
				THEN ''('' + CASE 
						WHEN c.max_length = - 1
							THEN ''MAX''
						ELSE CAST(c.max_length AS VARCHAR(5))
						END + '')''
			WHEN tp.name IN (''nvarchar'', ''nchar'', ''ntext'')
				THEN ''('' + CASE 
						WHEN c.max_length = - 1
							THEN ''MAX''
						ELSE CAST(c.max_length / 2 AS VARCHAR(5))
						END + '')''
			WHEN tp.name IN (''datetime2'', ''time2'', ''datetimeoffset'')
				THEN ''('' + CAST(c.scale AS VARCHAR(5)) + '')''
			WHEN tp.name = ''decimal''
				THEN ''('' + CAST(c.precision AS VARCHAR(5)) + '','' + CAST(c.scale AS VARCHAR(5)) + '')''
			ELSE ''''
			END + CASE 
			WHEN c.collation_name IS NOT NULL
				THEN '' COLLATE '' + c.collation_name
			ELSE ''''
			END + CASE 
			WHEN c.is_nullable = 1
				THEN '' NULL''
			ELSE '' NOT NULL''
			END  
				
	END + CHAR(13) + '' end'' as [query]
	FROM sys.columns AS c WITH (NOWAIT)
	INNER JOIN sys.types AS tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
	--inner join @tableColumn T on c.name=T.columnName
	LEFT JOIN sys.computed_columns AS cc WITH (NOWAIT) ON c.object_id = cc.object_id
	AND c.column_id = cc.column_id
	LEFT JOIN sys.default_constraints AS dc WITH (NOWAIT) ON c.default_object_id != 0
	AND c.object_id = dc.parent_object_id
	AND c.column_id = dc.parent_column_id
	LEFT JOIN sys.identity_columns AS ic WITH (NOWAIT) ON c.is_identity = 1
	AND c.object_id = ic.object_id
	AND c.column_id = ic.column_id
	WHERE c.object_id = @object_id
	AND c.name <> ''rowguid''
	ORDER BY c.column_id

END;

ELSE IF @option = 2  -- Get Tables Configuration
BEGIN
	SELECT idConfig,
	tableName,
	columnPrimaryKey,
	triggerName,
	active,
	timeCheck,
	dateLastCheck,
	columnWhereDays,
	isnull(copyContent,1)  as copyContent FROM [ccAIReplicaConfiguration] WHERE active = 1
End;

ELSE IF @option = 3  -- Get DataTable
BEGIN	
	DECLARE @params NVARCHAR(4000) = ''@dateLastCheck datetime''
	
	if @dateLastCheck is not null begin
		set @SQL=''select B.* from ''+@tableNameTmpIA+ '' A with(nolock) 
		inner join '' +@tableName+'' B with(nolock) on A.''+@columnNameId+''=B.''+@columnNameId+''
		where A.dateUpdate>@dateLastCheck''
	end
	else begin
		declare @where NVARCHAR(MAX) = ''''
		declare @datenow datetime= dateadd(dd,-30,convert(date,getdate()))
		set @dateLastCheck=@datenow
		if @columnWhereDays is not null or @columnWhereDays<>'''' begin
			set @where='' where ''+@columnWhereDays+''>@dateLastCheck''
		end

		set @SQL=''select A.* from ''+@tableName +'' A with(nolock) ''
		+ case when @tableName in(''ccUsers'') then '' '' else
		 ''inner join ccCamps c with(nolock) on c.cam_id=A.cam_id and c.CampType=4 '' end
		 + @where
	end
	
	print @SQL
	
	EXEC sp_executesql @SQL, @params, @dateLastCheck=@dateLastCheck;
End;

ELSE IF @option = 4   -- Enable and Disable trigger
BEGIN
	declare @command varchar(10) = case when @EnableOrDisableTrigger=0 then ''DISABLE'' else ''ENABLE'' end
	declare @i int
	declare @tmpTable table(idConfig SMALLINT primary key,
	tableName varchar(255) not null,
	triggerName varchar(255) not null,status bit
	)
	insert into @tmpTable
	select idConfig,tableName,triggerName,0 from ccAIReplicaConfiguration
	while exists(select * from @tmpTable where status=0) begin
		select top 1 @columnNameId=triggerName,@tableName=tableName,@i=idConfig from @tmpTable where status=0

		set @SQL=@command+'' TRIGGER ''+@columnNameId+'' ON ''+@tableName
		update @tmpTable set status=1 where idConfig=@i
		--print(@sql)
		exec (@SQL)
		
	end
End;

ELSE IF @option = 5   -- Update Last Check Date
BEGIN
	IF EXISTS (SELECT * FROM ccAIReplicaConfiguration WHERE tableName = @tableName)
	BEGIN
		UPDATE ccAIReplicaConfiguration SET dateLastCheck = @dateLastCheck WHERE tableName = @tableName
	END;
End;

ELSE IF @option = 6   -- Erase Temporary Tables Data
BEGIN
declare @id int

declare @tableTruncate table(
	id int identity primary key,
	tableName varchar(255) not null,
	status bit not null
)
	insert into @tableTruncate(tableName,status)
	select tableName+''TmpIA'',0 from [ccAIReplicaConfiguration]
	while exists(select * from @tableTruncate where status=0) begin
		select top 1 @id=id,@tableNameTmpIA=tableName from @tableTruncate where status=0
			set @sql=''IF EXISTS (SELECT * FROM sys.tables WHERE name = N''''''+@tableNameTmpIA+'''''')
		BEGIN
			TRUNCATE TABLE ''+@tableNameTmpIA+''
		END;''
		exec (@sql)
		update  @tableTruncate set status=1 where @id=id
	end


	SELECT CAST(1 AS BIT) AS Result
End;
ELSE IF @option = 7   -- List Loading
BEGIN
	declare @tableRegistry table(
	LoadId int not null,	
	ListId int not null,
	CamId int not null
	)
	insert into @tableRegistry
	select load_id,list_id,cam_id from ccRIALoading where (@dateLastCheck is null or loadDate>=@dateLastCheck) and ia_state=1 and pctg=100
	order by loadDate 
	if exists(select * from @tableRegistry) begin
		select A.LoadId,A.ListId,A.CamId,B.callout_id as CalloutId from @tableRegistry A
		inner join ccoCallsOutSource B on A.listId=B.list_id
		order by CalloutId
	end
End;

ELSE IF @option = 8 and @listLoadings is not null  -- update State Loading
BEGIN
	
	update B set B.ia_state=@IAState from  dbo.fn_RIASplitDelimited(@listLoadings,'','') A
	inner join ccRIALoading B on A.value=B.load_id

	if @IAState =2 begin
		select @dateLastCheck= max(B.loadDate) from  dbo.fn_RIASplitDelimited(@listLoadings,'','') A
		inner join ccRIALoading B on A.value=B.load_id

		update [ccAIReplicaConfiguration] set dateLastCheck=@dateLastCheck where tableName=''ccRIALoading''
	end
	
End;
ELSE IF @option = 9  -- update State Loading
BEGIN
	update B set B.cal_fechaDial=A.DateDial from cc_CalloutDateIA A
	inner join ccoCallsOutSource B on A.CalloutId=B.callout_id
	

End;
End;
';
	EXEC(@sql);




	
		-------------------------------------- Jesus --------------------------------------------------------------------------------

		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
		EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
