/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.25

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
SET @versionfix = 31
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

	SET @process = 'K038008-Servicio IA Service setting replicación de tablas'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccAIReplicaConfiguration'') begin

CREATE TABLE [dbo].[ccAIReplicaConfiguration] (
	idConfig SMALLINT IDENTITY(1,1) NOT NULL,
	tableName varchar(255) NOT NULL,
	columnPrimaryKey varchar(255) not null,
	triggerName varchar(255) not null,
	active BIT NOT NULL,
	timeCheck int not null,
	dateLastCheck datetime null,
	columnWhereDays  varchar(255) null,
)
end
';
	EXEC(@sql);


	SET @process = 'K038008-Servicio IA Service setting replicación de tablas'
	SET @sql = 'if not exists(select tableName from ccAIReplicaConfiguration where tableName=''ccoLogDials'') begin
	insert into ccAIReplicaConfiguration (tableName,columnPrimaryKey,triggerName,active,timeCheck,columnWhereDays) 
	values(''ccoLogDials'',''logDial_id'',''tg_ccoLogDials_IA'',0,10,''fecha'')
end
if not exists(select tableName from ccAIReplicaConfiguration where tableName=''ccoLogDials'') begin
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
';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de ccCamps'
	SET @sql = '
if not exists (select * from sys.triggers where name = N''tg_ccCamps_IA'' and parent_id = OBJECT_ID(N''ccCamps''))
    begin      
    
CREATE TRIGGER [dbo].[tg_ccCamps_IA]
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

END

end';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de ccoCallsOutSource'
	SET @sql = '
if not exists (select * from sys.triggers where name = N''tg_ccoCallsOutSource_IA'' and parent_id = OBJECT_ID(N''ccoCallsOutSource''))
    begin      
CREATE TRIGGER dbo.tg_ccoCallsOutSource_IA
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

END

End';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de ccoCallsOut'
	SET @sql = '
if not exists (select * from sys.triggers where name = N''tg_ccoCallsOut_IA'' and parent_id = OBJECT_ID(N''ccoCallsOut''))
    begin  
CREATE TRIGGER dbo.tg_ccoCallsOut_IA
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

END

END';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de ccoLogDials'
	SET @sql = 'if not exists (select * from sys.triggers where name = N''tg_ccoLogDials_IA'' and parent_id = OBJECT_ID(N''ccoLogDials''))
    begin  

CREATE TRIGGER dbo.tg_ccoLogDials_IA
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

END

END
';
	EXEC(@sql);

	SET @process = 'K038009-Servicio IA Service replicación de ccUsers'
	SET @sql = 'if not exists (select * from sys.triggers where name = N''tg_ccUsersTmp_IA'' and parent_id = OBJECT_ID(N''ccUsers''))
    begin 
CREATE TRIGGER dbo.tg_ccUsersTmp_IA
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

END

END';
	EXEC(@sql);

	SET @process = 'K038008-Servicio IA Service setting replicación de tablas'
	SET @sql = '';
	EXEC(@sql);

	SET @process = 'K038008-Servicio IA Service setting replicación de tablas'
	SET @sql = '';
	EXEC(@sql);

	SET @process = 'K038008-Servicio IA Service setting replicación de tablas'
	SET @sql = '';
	EXEC(@sql);
		----------------------------------------------------------------------------------------------------------------------

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
