/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 128

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
SET @version = 129 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	---------------------------------------BEGIN Jesus Gallardo hotfix/125.20231211.0.6---------------------------------------------------------
    set @process = 'DEV1-459 ALTER TABLE Add Column PublicationLowLoad.active'
    set @sql='if not exists (select * from sys.columns where name = N''active'' and Object_ID = Object_ID(N''PublicationLowLoad''))
begin
    ALTER TABLE PublicationLowLoad ADD active bit NULL;
end
'
    EXEC(@sql)


	set @process = 'Add PublicationLowLoad no se modifica a menudo'
    set @sql='if not exists( select * from PublicationLowLoad where namePublication=''ConversationWhatsApp'' ) begin
    insert into PublicationLowLoad values(''ConversationWhatsApp'',1)
end
if not exists( select * from PublicationLowLoad where namePublication=''ConversationWhatsAppOut'' ) begin
    insert into PublicationLowLoad values(''ConversationWhatsAppOut'',1)
end
if not exists( select * from PublicationLowLoad where namePublication=''MenuReportsRia'' ) begin
    insert into PublicationLowLoad values(''MenuReportsRia'',1)
end
if not exists( select * from PublicationLowLoad where namePublication=''CallsPreviewData'' ) begin
    insert into PublicationLowLoad values(''CallsPreviewData'',1)
end
if not exists( select * from PublicationLowLoad where namePublication=''RecordingEvaluation'' ) begin
    insert into PublicationLowLoad values(''RecordingEvaluation'',1)
end
if not exists( select * from PublicationLowLoad where namePublication=''AVRSTemplates'' ) begin
    insert into PublicationLowLoad values(''AVRSTemplates'',1)
end
if not exists( select * from PublicationLowLoad where namePublication=''AVRSTemplatesRate'' ) begin
    insert into PublicationLowLoad values(''AVRSTemplatesRate'',1)
end
'
    EXEC(@sql)


    set @process = 'DEV1-459 alter table RepOutManagementBase.calKey varchar(40)'
    set @sql='alter table RepOutManagementBase Alter Column calKey varchar(40)'
    EXEC(@sql)


    set @process = 'DEV1-459 DROP PROCEDURE ccsprepLogAgentriaseparate ya no se utiliza'
    set @sql='if exists (select * from sys.procedures where name = N''ccsprepLogAgentriaseparate'')
    begin
        DROP PROCEDURE ccsprepLogAgentriaseparate;
    end'
    EXEC(@sql)



    set @process = 'DEV1-459 Drop TABLE tmpTimesInboundData'
    set @sql='IF EXISTS (
        SELECT *
        FROM sys.tables
        WHERE name = ''tmpTimesInboundData''
        )
    Drop TABLE tmpTimesInboundData'
    EXEC(@sql)

    set @process = 'DEV1-459 Drop TABLE tmpccLogAgentesDia'
    set @sql='IF EXISTS (
        SELECT *
        FROM sys.tables
        WHERE name = ''tmpccLogAgentesDia''
        )
    Drop TABLE tmpccLogAgentesDia'
    EXEC(@sql)

    set @process = 'DEV1-459 Drop TABLE tmpTimesOutboundData'
    set @sql='IF EXISTS (
        SELECT *
        FROM sys.tables
        WHERE name = ''tmpTimesOutboundData''
        )
    Drop TABLE tmpTimesOutboundData'
    EXEC(@sql)

    
	 set @process = 'DEV1-459 CREATE TABLE [dbo].[replicationMergeClean]'
    set @sql='if not exists (select * from sys.tables where name = N''replicationMergeClean'') begin
CREATE TABLE [dbo].[replicationMergeClean](
    [dateStart] [datetime] not null,
	[dateEnd] [datetime] not null,
	[num_genhistory_rows] [int] not null,
	[num_contents_rows] [int] not null,
	[num_tombstone_rows] [int] not null,
	[MSmerge_genhistory] [int] not null,
	[MSmerge_tombstone] [int] not null,
	
) 
end'
    EXEC(@sql)

    set @process = 'DEV1-459 CREATE TABLE [dbo].[ReportHighUse]'
    set @sql='if not exists (select * from sys.tables where name = N''ReportHighUse'') begin
CREATE TABLE [dbo].[ReportHighUse](
    [nameSp] [varchar](256) not NULl primary key
) 
end'
    EXEC(@sql)

    set @process = 'DEV1-459 insert ReportHighUse'
    set @sql='
    if not exists(select * from ReportHighUse) begin
    insert into ReportHighUse values(''ccspRepAgentSessionByInterval'')


insert into ReportHighUse values(''ccspRepAgentKPI'')
insert into ReportHighUse values(''ccspRepAgentSummary'')
insert into ReportHighUse values(''ccspRepAnsweredCallsByDialingRetries'')


insert into ReportHighUse values(''ccspRepInAbnd'')
insert into ReportHighUse values(''ccspRepInAnsw'')
insert into ReportHighUse values(''ccspRepInBill01900'')
insert into ReportHighUse values(''ccspRepInboundKPI'')
insert into ReportHighUse values(''ccspRepInCalls'')
insert into ReportHighUse values(''ccspRepInCallsDetail'')
insert into ReportHighUse values(''ccspRepInChangeFlow'')
insert into ReportHighUse values(''ccspRepInDIDResume'')
insert into ReportHighUse values(''ccspRepInDispositions'')
insert into ReportHighUse values(''ccspRepInEffectiveness'')
insert into ReportHighUse values(''ccspRepInNotTransferred'')
insert into ReportHighUse values(''ccspRepInRejectedCalls'')
insert into ReportHighUse values(''ccspRepInSubDispositions'')

insert into ReportHighUse values(''ccspRepOutAnswAndXferCalls'')
insert into ReportHighUse values(''ccspRepOutAnswCalls'')
insert into ReportHighUse values(''ccspRepOutboundKPI'')
insert into ReportHighUse values(''ccspRepOutCallBacks'')
insert into ReportHighUse values(''ccspRepOutCallBilling'')
insert into ReportHighUse values(''ccspRepOutCalls'')
insert into ReportHighUse values(''ccspRepOutCallsByTelephone'')
insert into ReportHighUse values(''ccspRepOutCallsDetail'')
insert into ReportHighUse values(''ccspRepOutCallsOnChatDetail'')
insert into ReportHighUse values(''ccspRepOutDialDetail'')
insert into ReportHighUse values(''ccspRepOutDials'')
insert into ReportHighUse values(''ccspRepOutDispositions'')
insert into ReportHighUse values(''ccspRepOutDispositionsContacOwner'')
insert into ReportHighUse values(''ccspRepOutKPI'')

insert into ReportHighUse values(''ccspRepOutSubDispositions'')
end'
    EXEC(@sql)

    set @process = 'DEV1-459 CREATE TABLE tmpTimesOutboundData'
    set @sql='IF NOT EXISTS (
        SELECT *
        FROM sys.tables
        WHERE name = ''tmpTimesOutboundData''
        )
BEGIN
    CREATE TABLE tmpTimesOutboundData (
        row INT identity, dateStartDetail DATETIME, dateEndDetail DATETIME, timegroup DATETIME, timegroup_next DATETIME, cam_id INT, 
        User_id INT, ntotal INT, nno_agent INT, nxfer INT, nabnd_xfer INT, nabnd_ring INT, nno_answer INT, nabnd_dialog INT, nanswer INT, 
        nlost INT, tque INT, txfer INT, tring INT, tdialog INT, tnotes INT, tresp INT, nhangup INT, nMoh INT, nWHag INT, nWHcl INT, 
        time_endque DATETIME,dateXferAgtStart datetime, time_ring DATETIME, time_dialog DATETIME, time_notes DATETIME, time_end_call DATETIME, phone_out 
        VARCHAR(30), cal_id INT, cal_puerto INT, idwg INT, statuscall_id INT, calif_id INT, cal_manual INT, cal_tMoh INT
        )
END'
    EXEC(@sql)


    set @process = 'DEV1-459 CREATE TABLE tmpSessionTimeGroup'
    set @sql='if not exists( select * from sys.tables where name=''tmpSessionTimeGroup'') begin
    CREATE TABLE tmpSessionTimeGroup([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
end'
    EXEC(@sql)


    set @process = 'DEV1-459 CREATE TABLE tmpccLogAgentesDia'
    set @sql='IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''tmpccLogAgentesDia'')
BEGIN
    CREATE TABLE tmpccLogAgentesDia (
        id INT NOT NULL 
        ,userId INT NOT NULL
        ,TipoStatusAge_id TINYINT NOT NULL
        ,tStatus FLOAT NOT NULL
        ,dateIni DATETIME NOT NULL
        ,dateEnd DATETIME NOT NULL
        ,currentStatus INT NOT NULL
        ,timeGroup DATETIME NOT NULL
        ,timeGroupNext DATETIME NOT NULL
        ,camId SMALLINT
        ,camType SMALLINT
        ,callId INT,
        primary key (id,userId)
        );

END'
    EXEC(@sql)

     set @process = 'DEV1-459 CREATE TABLE tmpTimesInboundData'
    set @sql='IF NOT EXISTS (
        SELECT *
        FROM sys.tables
        WHERE name = ''tmpTimesInboundData''
        )
BEGIN
    CREATE TABLE tmpTimesInboundData (
        [row] INT, dateStartDetail DATETIME, dateEndDetail DATETIME, timegroup DATETIME, timegroup_next DATETIME, time_endque 
        DATETIME, dateXferAgtStart datetime, time_ring DATETIME, time_dialog DATETIME, time_notes DATETIME, time_end_call DATETIME, phone_in VARCHAR(40), 
        cal_id INT, dni_id INT, Inbound_id INT, [User_id] INT, ntotal INT, ninitial INT, nout_hour INT, nout_service INT, nabnd INT, 
        nno_agent INT, nque INT, ntimeout INT, noverflow INT, nxfer INT, nxfer_que INT, nabnd_xfer INT, nabnd_ring INT, nno_answer INT, 
        nabnd_dialog INT, nanswer INT, nlost INT, nmsg INT, nabnd_tres INT, nansw_tres INT, tque_max INT, tque INT, txfer INT, tdialog INT, 
        tnotes INT, tring INT, tresp INT, nMoh INT, nWHag INT, nWHcl INT, statusCall_id INT, [dateTResp] DATETIME, [dateTACD] DATETIME, 
        calif_id INT, cal_tMoh INT, cal_puerto INT
        );
END'
    EXEC(@sql)

    SET @process = 'Replication DROP PROCEDURE ccSpCreateIndexReport'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccSpCreateIndexReport'')
    begin
        DROP PROCEDURE ccSpCreateIndexReport;
    end'
        EXEC (@sql)

    set @process = 'DEV1-459 alter SP ccSpCreateIndexReport'
    set @sql='Create PROCEDURE [dbo].[ccSpCreateIndexReport]  
AS
BEGIN
    SET NOCOUNT ON;


declare @tIndexMerge table(id int identity,tableName varchar(255),status bit)
declare @sql nvarchar(max),@tableName varchar(255),@id int
declare @column varchar(255),@indexName varchar(255)

insert into @tIndexMerge(tableName,status)
SELECT Art.name tableName,0 [status] FROM dbo.sysmergepublications P
inner join dbo.sysmergearticles Art on Art.pubid=P.pubid

set @column=''rowguid''

while exists(select 1 from @tIndexMerge where status=0) begin
    select top 1 @tableName=tableName,@id=id from @tIndexMerge where status=0 
    set @indexName=N''MSmerge_index_'' + @tableName
    set @sql=''if not exists(SELECT 1 FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.is_hypothetical = 0 -- Excluir índices hipotéticos
    and i.name = @tableName
    and c.name=@column
)
and not exists (select * from sys.indexes where name = @indexName and object_id = OBJECT_ID(@tableName)) 
and exists (select * from sys.columns where name = @column and Object_ID = Object_ID(@tableName))
begin
CREATE UNIQUE NONCLUSTERED INDEX [''+@indexName+''] on [dbo].[''+@tableName+''](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
    ''
    EXEC sp_executesql @sql, 
    N''@tableName varchar(255),@column varchar(255),@indexName varchar(255)'', 
    @tableName = @tableName, 
    @indexName = @indexName,
    @column = @column;
    --print @sql
    update @tIndexMerge set status=1 where @id=id
end


/****************************INDICES PARA REPORTES *******************************/

if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesDia_4'' and object_id = OBJECT_ID(N''ccLogAgentesDia''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_4
ON [dbo].[ccLogAgentesDia] ([User_id],[fecha])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesDia_6'' and object_id = OBJECT_ID(N''ccLogAgentesDia''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_6
ON [dbo].[ccLogAgentesDia] ([fecha])
INCLUDE ([User_id],[TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesNotReady_5'' and object_id = OBJECT_ID(N''cclogagentesnotready''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesNotReady_5
ON [dbo].[cclogagentesnotready] ([fecha])
INCLUDE ([User_id],[TipoNotReady_id],[tStatus])
end

    
if not exists (select * from sys.indexes where name = N''IX_ccLogLogin_6'' and object_id = OBJECT_ID(N''ccloglogin''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogLogin_6
ON [dbo].[ccloglogin] ([fecha])
INCLUDE ([User_id],[Extension],[TipoMov])
end

    
if not exists (select * from sys.indexes where name = N''IX_ccLogTransfers_3'' and object_id = OBJECT_ID(N''ccLogtransfers''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogTransfers_3
ON [dbo].[ccLogtransfers] ([fechaFin])
INCLUDE ([cal_id],[tipo],[modo],[destino],[tAntesXfer],[tDespuesXfer])
end

if not exists (select * from sys.indexes where name = N''IX_ccoCallsOut13'' and object_id = OBJECT_ID(N''ccoCallsOut''))
begin
   CREATE NONCLUSTERED INDEX IX_ccoCallsOut13
ON [dbo].[ccoCallsOut] ([cal_Inicio])
INCLUDE ([cal_id],[cal_telefono],[cal_puerto],[cam_id],[User_id],[statusCall_id],[calif_id],[cal_tDialog],[cal_tNotas],[cal_tXfer],[cal_tRing],[cal_manual],[cal_tMoh],[cal_whoHung],[cal_twait])
end


if not exists (select * from sys.indexes where name = N''IX_ccoCallsOut_14'' and object_id = OBJECT_ID(N''ccoCallsOut''))
begin
   CREATE NONCLUSTERED INDEX IX_ccoCallsOut_14
ON [dbo].[ccoCallsOut] ([cal_Inicio],[cal_manual])
INCLUDE ([cal_id],[callout_id],[cal_telefono],[cam_id],[User_id],[calif_id],[cal_tDialog],[cal_tNotas],[cal_tXfer],[cal_tRing],[califSub_id])
end 


    
if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACION_11'' and object_id = OBJECT_ID(N''RIA_GRABACION''))
begin
CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_11
ON [dbo].[RIA_GRABACION] ([tipo_llamada],[cal_id])
INCLUDE ([grab_id])
end

if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACION_10'' and object_id = OBJECT_ID(N''RIA_GRABACION''))
begin
CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_10
ON [dbo].[RIA_GRABACION] ([tipo_llamada])
INCLUDE ([cal_id])
end

    
if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesDia_Dialog'' and object_id = OBJECT_ID(N''ccLogAgentesDia_Dialog''))
begin
CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_Dialog
ON [dbo].[ccLogAgentesDia_Dialog] ([fecha_Dialog])
INCLUDE ([User_id],[fecha_Calc_ms])
end


if not exists (select * from sys.indexes where name = N''IX_ccoCallsOutSource_1'' and object_id = OBJECT_ID(N''ccoCallsOutSource''))
begin
CREATE NONCLUSTERED INDEX IX_ccoCallsOutSource_1
ON [dbo].[ccoCallsOutSource] ([cal_fechaDial],[Region])
end

if not exists (select * from sys.indexes where name = N''IX_ccoLogDials_6'' and object_id = OBJECT_ID(N''ccoLogDials''))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_6
ON [dbo].[ccoLogDials] ([fecha])
INCLUDE ([cam_id],[tipoResDial_id],[Telefono],[cal_id],[disconnectCause],[answerbit],[tipoLlamada_id])
end

    
if not exists (select * from sys.indexes where name = N''IX_ccoLogDials_7'' and object_id = OBJECT_ID(N''ccoLogDials''))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_7
ON [dbo].[ccoLogDials] ([cal_id])
INCLUDE ([tipoResDial_id])
end


if not exists (select * from sys.indexes where name = N''IX_ccoLogDials_8'' and object_id = OBJECT_ID(N''ccoLogDials''))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_8
ON [dbo].[ccoLogDials] ([fecha],[cal_id])
INCLUDE ([tipoResDial_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_7'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
   CREATE NONCLUSTERED INDEX IX_ccCallsIn_7
ON [dbo].[ccCallsIn] ([Inbound_id],[cal_Inicio])
INCLUDE ([cal_id],[dni_id],[cal_ANI],[User_id],[statusCall_id],[calif_id],[cal_que],[cal_tDialog],[cal_tNotas],[cal_tWait],[cal_tXfer],[cal_tRing],[cal_Xfer],[cal_tMoh],[cal_whoHung],[califSub_id])

end

if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_8'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_8
ON [dbo].[ccCallsIn] ([IVR_id])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_9'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_9
ON [dbo].[ccCallsIn] ([cal_Inicio])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_tmpSessionTimeGroup_1'' and object_id = OBJECT_ID(N''tmpSessionTimeGroup''))
begin
CREATE NONCLUSTERED INDEX IX_tmpSessionTimeGroup_1
ON [dbo].[tmpSessionTimeGroup] ([user_id])
INCLUDE ([timegroup],[tlog])
end

   
if not exists (select * from sys.indexes where name = N''IX_tmpccLogAgentesDia_2'' and object_id = OBJECT_ID(N''tmpccLogAgentesDia''))
begin
CREATE NONCLUSTERED INDEX IX_tmpccLogAgentesDia_2
ON [dbo].[tmpccLogAgentesDia] ([userId],[timeGroup])
INCLUDE ([TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N''IX_tmpTimesInboundData_1'' and object_id = OBJECT_ID(N''tmpTimesInboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_1
ON [dbo].[tmpTimesInboundData] ([statusCall_id])
INCLUDE ([timegroup],[Inbound_id],[nabnd],[tque],[txfer],[tring])
end

    
if not exists (select * from sys.indexes where name = N''IX_tmpTimesInboundData_2'' and object_id = OBJECT_ID(N''tmpTimesInboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_2
ON [dbo].[tmpTimesInboundData] ([cal_id])
INCLUDE ([Inbound_id],[User_id])
end


if not exists (select * from sys.indexes where name = N''IX_tmpTimesOutboundData_1'' and object_id = OBJECT_ID(N''tmpTimesOutboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_1
ON [dbo].[tmpTimesOutboundData] ([timegroup],[cal_id])
INCLUDE ([User_id])
end
    
if not exists (select * from sys.indexes where name = N''IX_tmpTimesOutboundData_2'' and object_id = OBJECT_ID(N''tmpTimesOutboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_2
ON [dbo].[tmpTimesOutboundData] ([cal_manual])
INCLUDE ([timegroup],[User_id],[nabnd_xfer],[nabnd_ring],[tdialog],[tnotes],[cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_RiaMarkHold_1'' and object_id = OBJECT_ID(N''RiaMarkHold''))
begin
create index IX_RiaMarkHold_1 on RiaMarkHold (
    call_id,tipo_llamada
)
end
/**************************** INDICES Reportes *******************************/



set @column=''date''
delete from @tIndexMerge

insert into @tIndexMerge(tableName,status)
SELECT     
    t.TABLE_NAME,0
FROM 
    INFORMATION_SCHEMA.COLUMNS c
INNER JOIN 
    INFORMATION_SCHEMA.TABLES t 
    ON c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
WHERE 
    t.TABLE_NAME LIKE ''Rep%''   -- Las tablas que comienzan con ''Rep''
    AND c.COLUMN_NAME = ''date'' -- Que contienen una columna llamada ''date''
    AND t.TABLE_TYPE = ''BASE TABLE'' -- Solo tablas (no vistas)
ORDER BY 
    t.TABLE_SCHEMA, t.TABLE_NAME;


while exists(select 1 from @tIndexMerge where status=0) begin
    select top 1 @tableName=tableName,@id=id from @tIndexMerge where status=0 
    set @indexName=N''IX_''+ @tableName+''_date'' 
    set @sql=''if not exists(SELECT 1 FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.is_hypothetical = 0 -- Excluir índices hipotéticos
    and i.name = @tableName
    and c.name=@column
)
and not exists (select * from sys.indexes where name = @indexName and object_id = OBJECT_ID(@tableName)) 
and exists (select * from sys.columns where name = @column and Object_ID = Object_ID(@tableName))
begin
CREATE NONCLUSTERED INDEX ''+@indexName+''
ON [dbo].[''+@tableName+''] ([date])
end
    ''
    EXEC sp_executesql @sql, 
    N''@tableName varchar(255),@column varchar(255),@indexName varchar(255)'', 
    @tableName = @tableName, 
    @indexName = @indexName,
    @column = @column;
    print @sql
    update @tIndexMerge set status=1 where @id=id
end
    
if not exists (select * from sys.indexes where name = N''IX_RepAgentNotReadyDet_2'' and object_id = OBJECT_ID(N''RepAgentNotReadyDet''))
begin
CREATE NONCLUSTERED INDEX IX_RepAgentNotReadyDet_2
ON [dbo].[RepAgentNotReadyDet] ([tiponotreadyId],[startDate])
INCLUDE ([userId],[status],[statusTime])
end 

end'
    EXEC(@sql)

   
    set @process = 'DEV1-459 Alter SP ccspTimesInboundData se quita la creacion de la tabla tmpTimesInboundData'
    set @sql='ALTER PROCEDURE [dbo].[ccspTimesInboundData]
@from AS SMALLDATETIME, @to AS SMALLDATETIME
AS

SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#inboundData2'', N''U'') IS NOT NULL
    DROP TABLE #inboundData2


TRUNCATE TABLE tmpTimesInboundData  


DECLARE @relastionCampWg TABLE (idwg INT, camId INT)

INSERT INTO @relastionCampWg
SELECT MAX(IDWG) AS IDWG, IdCampEsp AS Id
FROM ccRIACampEspWG
WHERE Tipo = 0
GROUP BY IdCampEsp

DECLARE @HourExtend AS SMALLINT

SELECT @HourExtend = 2

DECLARE @fromExtended AS SMALLDATETIME

SELECT @fromExtended = DATEADD(hh, - @HourExtend, @from)

DECLARE @tresRing AS SMALLINT
DECLARE @tresDialog AS SMALLINT
DECLARE @tresDelayIn AS SMALLINT

EXEC @tresRing = ccspConfigTresRing

EXEC @tresDialog = ccspConfigTresDialog

EXEC @tresDelayIn = ccspConfigtresDelayIn


DECLARE @dateNow DATETIME

SET @dateNow = GETDATE();

WITH inboundData
AS (
    SELECT ROW_NUMBER() OVER (ORDER BY cal_id ASC) AS rowId
    , CASE WHEN cal_Xfer IS NULL OR cal_Xfer = ''1900-01-01 00:00:00'' THEN cal_inicio ELSE cal_Xfer END AS dateStartDetail 
    ,cal_id,Inbound_id,cal_tWait,cal_tXfer,cal_tRing,cal_tDialog,cal_tNotas 
    ,cal_Ani, dni_id, User_id, statuscall_id, cal_que, cal_Xfer
    ,cal_tMoh, cal_whoHung, calif_id, cal_puerto
    FROM ccCallsIn
    WHERE cal_inicio between @fromExtended AND @to AND INBOUND_ID > 0   
    )
    ,callInStart as(
    select distinct userId,min(dateIni) dateIni,callId,camType
    from tmpccLogAgentesDia 
    where callId>0 and  camType=0 and TipoStatusAge_id in(5,9,4,6)
    group by userId,callId,camType
    ) 
    ,callDataStartXfer as(
    select A.userId,B.callId,B.camType,B.camId,min(B.dateIni) dateIni from callInStart A
    inner join tmpccLogAgentesDia B on A.userId=B.userId and A.dateIni=B.dateIni
    where B.tStatus>0
    group by A.userId,B.callId,B.camType,B.camId
    ),inboundDataWithXferAgent  as(
    select rowId
    ,cal_id,Inbound_id,cal_tWait,cal_tXfer,cal_tRing,cal_tDialog,cal_tNotas 
    ,dateStartDetail    
    ,DATEADD(ss, cal_tWait, A.dateStartDetail) as time_endque
    ,ISNULL(B.dateIni,A.dateStartDetail) as dateXferAgtStart
    ,DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, ISNULL(B.dateIni,A.dateStartDetail)) as dateEndDetail
    ,cal_Ani, dni_id, User_id, statuscall_id, cal_que, cal_Xfer
    ,cal_tMoh, cal_whoHung, calif_id, cal_puerto
    from inboundData A
    left join callDataStartXfer B on A.cal_id= B.callId and A.Inbound_id=B.camId and A.User_id=B.userId
    )      

    INSERT INTO tmpTimesInboundData
    select rowId, dateStartDetail,dateEndDetail
    , dbo.GetTimeGroup(dateStartDetail, 0) AS timegroup
    , dbo.GetTimeGroup(dateEndDetail, 1 ) AS timegroup_next
    , time_endque, dateXferAgtStart
    , DATEADD(ss, cal_txfer, dateXferAgtStart) AS time_ring
    , DATEADD(ss, cal_txfer + cal_tring, dateXferAgtStart) AS time_dialog
    , DATEADD(ss, cal_txfer + cal_tring + cal_tdialog, dateXferAgtStart) AS time_notes  
    , dateEndDetail AS time_end_call
    , cal_Ani AS phone_in, cal_id, dni_id, Inbound_id, [User_id], 1 AS ntotal
    , CASE WHEN statuscall_id = 1 THEN 1 ELSE 0 END AS ninitial
    , CASE WHEN statuscall_id = 2 THEN 1 ELSE 0 END AS nout_hour
    , CASE WHEN statuscall_id = 3 THEN 1 ELSE 0 END AS nout_service
    , CASE WHEN statuscall_id IN (5, 6) AND cal_que > 0 AND (cal_xfer IS NULL OR cal_xfer = ''1900-01-01 00:00:00'') THEN 1 ELSE 0 END AS nabnd
    , CASE WHEN statuscall_id = 4 THEN 1 ELSE 0 END AS nno_agent
    , CASE WHEN cal_que > 0 THEN 1 ELSE 0 END AS  nque
    , CASE WHEN statuscall_id = 7 THEN 1 ELSE 0 END AS ntimeout
    , CASE WHEN statuscall_id = 8 THEN 1 ELSE 0 END AS noverflow
    , CASE WHEN statuscall_id IN (11, 15, 13, 16)OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'' ) THEN 1 ELSE 0 END AS nxfer
    , CASE WHEN cal_que > 0 AND ( statuscall_id IN (11, 15, 13, 16) OR ( statuscall_id = 6  AND cal_xfer <> ''1900-01-01 00:00:00'') ) THEN 1 ELSE 0 END AS nxfer_que
    , CASE WHEN statuscall_id = 11 OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'') THEN 1 ELSE 0 END AS nabnd_xfer
    , CASE WHEN statuscall_id = 15 AND cal_tring <= @tresRing    THEN 1 ELSE 0 END AS nabnd_ring
    , CASE WHEN statuscall_id = 15 AND cal_tring > @tresRing  THEN 1 ELSE 0 END AS nno_answer
    , CASE WHEN statuscall_id = 13 AND cal_tdialog <= @tresDialog  THEN 1 ELSE 0 END AS nabnd_dialog
    , CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog   THEN 1 ELSE 0 END AS nanswer
    , CASE WHEN statuscall_id = 16 THEN 1 ELSE 0 END AS nlost
    , CASE WHEN statuscall_id IN (9, 10, 12, 14)  THEN 1 ELSE 0 END AS nmsg
    , CASE WHEN ( ( statuscall_id IN (5, 6) AND cal_que > 0 AND (cal_xfer IS NULL OR cal_xfer = ''1900-01-01 00:00:00'')    )
                    AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE 0 END AS nabnd_tres
    , CASE WHEN ((statuscall_id = 13 AND cal_tdialog > @tresDialog) AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn) ) THEN 1 ELSE 0 END AS nansw_tres    
    , cal_twait AS tque_max, cal_twait AS tque, cal_txfer AS txfer, cal_tdialog AS tdialog
    , cal_tnotas AS tnotes, cal_tring AS tring
    , CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog THEN cal_twait + cal_txfer + cal_tring ELSE 0 END AS tresp
    , CASE WHEN cal_tMoh > 0 THEN 1 ELSE 0 END AS nMoh
    , CASE WHEN cal_whoHung > 0 THEN 1 ELSE 0 END AS nWHag
    , CASE WHEN cal_whoHung = 0 THEN 1 ELSE 0 END AS nWHcl
    , statusCall_id
    , dateadd(ss, cal_txfer + cal_tring, dateXferAgtStart) AS [dateTResp]
    , dateadd(ss, cal_txfer + cal_tring + cal_tdialog, dateXferAgtStart) AS [dateTACD]
    , calif_id, cal_tMoh, cal_puerto
    from inboundDataWithXferAgent

/******************* Revisa si los datos son del dia ******************************/

declare @today date
set @today =convert(date,@dateNow,121)

IF @today = CONVERT(DATE, @to, 121)
BEGIN
        ;

    WITH lastAgentStatus
    AS (
        SELECT userId, max(dateIni) dateIn
        FROM tmpccLogAgentesDia
        WHERE dateIni BETWEEN @today AND @to
        GROUP BY userId
        ), timeAcumlate
    AS (
        SELECT A.userId, A.camId, A.callId, sum(CASE WHEN A.currentStatus IN (4, 5, 9) THEN A.tStatus 
                    ELSE 0 END) AS tdialog, sum(CASE WHEN A.currentStatus = 6 THEN A.tStatus ELSE 0 END) AS tnotes, max(A.dateEnd) AS 
            dateEnd, max(A.timeGroupNext) AS timeGroupNext
        FROM tmpccLogAgentesDia A
        INNER JOIN lastAgentStatus B ON A.userId = B.userId
            AND A.dateIni = B.dateIn
        WHERE A.dateIni BETWEEN @today AND @to
            AND currentStatus IN (4, 5, 6, 9)
            AND A.camType = 0
        GROUP BY A.userId, A.camId, A.callId
        )
    UPDATE A
    SET A.dateEndDetail = B.dateEnd, A.timegroup_next = B.timeGroupNext, A.tdialog = CASE WHEN B.tdialog > 0 THEN B.tdialog ELSE A.
                tdialog END, A.tnotes = CASE WHEN B.tnotes > 0 THEN B.tnotes ELSE A.tnotes END, A.time_notes = CASE WHEN B.tdialog > 0 THEN B.
                    dateEnd ELSE A.time_dialog END, A.time_end_call = CASE WHEN B.tnotes > 0 THEN B.dateEnd ELSE A.time_notes END, A.
        User_id = CASE WHEN A.User_id > 0 THEN B.userId ELSE A.User_id END
    FROM tmpTimesInboundData A
    INNER JOIN timeAcumlate B ON A.Inbound_id = B.camId
        AND A.cal_id = B.callId
END

SELECT *
INTO #inboundData2
FROM tmpTimesInboundData
WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

DELETE tmpTimesInboundData
WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

INSERT INTO tmpTimesInboundData
SELECT [row], dateStartDetail, dateEndDetail, th.start AS timegroup, th.stop AS timegroup_next, time_endque
,dateXferAgtStart, time_ring, time_dialog, time_notes, time_end_call, phone_in, cal_id, dni_id, Inbound_id, [User_id] 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN ntotal ELSE 0 END AS ntotal 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN ninitial ELSE 0 END AS ninitial 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nout_hour ELSE 0 END AS nout_hour 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nout_service ELSE 0 END AS nout_service 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd ELSE 0 END AS nabnd 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nno_agent ELSE 0 END AS nno_agent 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nque ELSE 0 END AS nque 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN ntimeout ELSE 0 END AS ntimeout 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN noverflow ELSE 0 END AS noverflow 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nxfer ELSE 0 END AS nxfer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nxfer_que ELSE 0 END AS nxfer_que 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_xfer ELSE 0 END AS nabnd_xfer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_ring ELSE 0 END AS nabnd_ring 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nno_answer ELSE 0 END AS nno_answer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_dialog ELSE 0 END AS nabnd_dialog 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nanswer ELSE 0 END AS nanswer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nlost ELSE 0 END AS nlost 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nmsg ELSE 0 END AS nmsg 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_tres ELSE 0 END AS nabnd_tres 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nansw_tres ELSE 0 END AS nansw_tres 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN tque_max ELSE 0 END AS tque_max
, dbo.TimeInterval(th.start, th.stop, dateStartDetail,  time_endque) AS tque
, dbo.TimeInterval(th.start, th.stop, dateXferAgtStart, time_ring) AS txfer
, dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog
, dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes
, dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring
, dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tresp, dateStartDetail)) AS tresp 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nMoh ELSE 0 END AS nMoh 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nWHag ELSE 0 END AS nWHag 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nWHcl ELSE 0 END AS nWHcl, statusCall_id, [dateTResp], [dateTACD] 
, CASE WHEN th.start >  dateStartDetail AND th.stop > dateEndDetail THEN calif_id ELSE - 2 END AS calif_id, dbo.AccountInterval(th.start, th.stop, dateStartDetail
        , dateEndDetail, cal_tMoh) AS cal_tMoh, cal_puerto
FROM #inboundData2 t
INNER JOIN TmpTimesInterval th ON (
        t.timegroup > th.Start
        AND t.timegroup < th.stop
        )
    OR th.Start BETWEEN t.timegroup AND t.timegroup_next
WHERE DATEDIFF(ss, th.start, timegroup_next) > 0
    AND th.Start BETWEEN @from AND @to
ORDER BY [row], th.start


IF OBJECT_ID(N''tempdb..#inboundData2'', N''U'') IS NOT NULL
    DROP TABLE #inboundData2
'
    EXEC(@sql)

     set @process = 'DEV1-459 Alter SP ccspTimesccLogAgentesDia se quita la creacion tabla tmpccLogAgentesDia'
    set @sql='ALTER PROCEDURE [dbo].[ccspTimesccLogAgentesDia] @from AS SMALLDATETIME, @to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL Begin
    DROP TABLE #tempccLogAgentesDia2
End

TRUNCATE TABLE tmpccLogAgentesDia

IF not EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_tmpccLogAgentesDia_TipoStatusAge_id'')   Begin
    CREATE NONCLUSTERED INDEX [IX_tmpccLogAgentesDia_TipoStatusAge_id]
    ON [dbo].[tmpccLogAgentesDia] ([TipoStatusAge_id])
    INCLUDE ([tStatus],[timeGroupNext])
end

CREATE TABLE #tempccLogAgentesDia2 (
    rowId INT NOT NULL
    ,userId INT NOT NULL
    ,TipoStatusAge_id TINYINT NOT NULL
    ,tStatus FLOAT NOT NULL
    ,dateIni DATETIME NOT NULL
    ,dateEnd DATETIME NOT NULL
    ,currentStatus INT
    ,timeGroup DATETIME NOT NULL
    ,timeGroupNext DATETIME NOT NULL
    ,camId SMALLINT
    ,camType SMALLINT
    ,callId INT
    );

WITH tmpLog
AS (
    SELECT User_id AS userId
        ,TipoStatusAge_id
        ,tStatus
        ,DATEADD(ms, - tStatus*1000, fecha) dateIni
        ,fecha dateEnd
        ,ISNULL(currentStatus, 0) AS currentStatus
        ,dbo.GetTimeGroup(DATEADD(ms, - tStatus*1000, fecha), 0) AS timegroup
        ,dbo.GetTimeGroup(fecha, 1) AS timegroup_next
        ,IdCampEsp AS camId
        ,Tipo AS camType
        ,callId
    FROM ccLogAgentesDia with(nolock,index(IX_ccLogAgentesDia_6))
    WHERE DATEADD(ss, - tStatus, fecha) BETWEEN @from AND @to   
    )
, cteLogAgentesDia as (

SELECT ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId
    ,userId
    ,TipoStatusAge_id
    ,tStatus
    ,dateIni
    ,dateEnd
    ,currentStatus
    ,timegroup
    ,timegroup_next
    ,camId
    ,camType
    ,callId
FROM tmpLog
)
insert into tmpccLogAgentesDia
select * from cteLogAgentesDia

/***** Elimina los repetidos ******/
; with regDeleteRepLogout as(
SELECT 
    case when A.dateIni<S.dateIni or A.currentStatus<0 then S.id else A.Id end [rowId]  
    , A.userId      
    FROM tmpccLogAgentesDia A
    LEFT JOIN tmpccLogAgentesDia S ON A.Id = S.Id - 1
        AND A.userId = S.userId
    WHERE A.tStatus >0 and S.tStatus >0
        AND A.TipoStatusAge_id = S.TipoStatusAge_id
        AND A.TipoStatusAge_id>0    
        and (A.dateEnd between S.dateIni and S.dateEnd
        or S.dateEnd between A.dateIni and A.dateEnd
        )
        and ABS( A.tStatus-S.tStatus)<=2
),
rowReconnectLogout as(
select ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId,* 
from tmpccLogAgentesDia where currentStatus in(30,-2) and tStatus>0
)
,
regDeleteReconnect as( 
 select 
case when A.currentStatus=-2 then S.Id else A.Id end [rowId], A.userId
--,A.userId,S.userId,A.RowId,S.RowId,A.timeGroup,S.timeGroupNext,A.id,S.id,A.TipoStatusAge_id,S.TipoStatusAge_id,A.tStatus,S.tStatus
--,A.dateIni,A.dateEnd,S.dateIni,S.dateEnd
--,ABS(A.tStatus-S.tStatus)
from rowReconnectLogout A
inner join rowReconnectLogout S on A.userId=S.userId and A.RowId=S.RowId-1 
and A.TipoStatusAge_id=S.TipoStatusAge_id 
where ( A.dateIni between S.dateIni and S.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
 )
 , rowDelete as(
 select * from regDeleteRepLogout
 union 
 select * from regDeleteReconnect
 )

            
--SELECT A.*
Delete A
from tmpccLogAgentesDia A
inner join rowDelete X  ON A.id = x.rowId AND A.userId = x.userId;

/***** Revisa si es el dia actual para calcular el tiempo del estado ******/
declare @today date,@dateNow datetime
SET @today = convert(DATE, GETDATE(), 121)
SET @dateNow=GETDATE()


IF @today = CONVERT(DATE, @to, 121)
BEGIN
    ;   
    WITH tmpAgentLastStatus
    AS (
        SELECT userId ,MAX(dateEnd) AS dateStart
        FROM tmpccLogAgentesDia
        WHERE dateEnd BETWEEN @today AND @to
        GROUP BY userId
        )           

    INSERT INTO tmpccLogAgentesDia
    SELECT 0
        ,A.userId
        ,A.currentStatus
        ,DATEDIFF(ss, A.dateEnd, @dateNow) AS tStatus
        ,B.dateStart
        ,@dateNow
        ,A.currentStatus
        ,dbo.GetTimeGroup(B.dateStart, 0) AS timegroup
        ,dbo.GetTimeGroup(@dateNow, 1) AS timegroup_next
        ,A.camId
        ,A.camType
        ,A.callId
    FROM tmpccLogAgentesDia A
    INNER JOIN tmpAgentLastStatus B ON A.dateEnd = B.dateStart AND A.userId = B.userId
    WHERE A.dateIni BETWEEN @today AND @to
        AND A.currentStatus NOT IN (- 2, - 1, 0);
END


/***** Separa los estados para tenerlos en intervalos 15 minutos para algunos reportes ******/
INSERT INTO #tempccLogAgentesDia2
SELECT * FROM tmpccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15


DELETE tmpccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15;



INSERT INTO tmpccLogAgentesDia
SELECT-1* ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId
    ,t.userId
    ,TipoStatusAge_id
    ,dbo.TimeInterval(th.start, th.stop, dateIni, dateEnd) AS tStatus
    ,dateIni
    ,dateEnd
    ,currentStatus
    ,th.start AS timegroup
    ,th.stop AS timegroup_next
    ,t.camId
    ,t.camType
    ,t.callId
FROM #tempccLogAgentesDia2 t
INNER JOIN TmpTimesInterval th ON (
        t.timegroup > th.Start
        AND t.timegroup < th.stop
        )
    OR th.Start BETWEEN t.timegroup
        AND t.timeGroupNext
WHERE DATEDIFF(ss, th.start, timeGroupNext) > 0
    AND th.Start BETWEEN @from
        AND @to
order by dateIni,timegroup


IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL
    DROP TABLE #tempccLogAgentesDia2'
    EXEC(@sql)


    set @process = 'DEV1-459 Alter Sp ccspTmpSessionTimeGroup ajustes de los timepos con logout o login faltantes'
    set @sql='ALTER PROCEDURE [dbo].[ccspTmpSessionTimeGroup]
@from as smalldatetime,
@to as smalldatetime 
AS
set nocount on

if @from is null begin
    select @from = convert(datetime,convert(varchar(11),getdate()))
end

if @to is null begin
    select @to = dateadd(mi,1, convert(varchar(15),getdate(),121)+'':00'')
end

IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup
IF OBJECT_ID(''tempdb..#sessionTimeMayores'') IS NOT NULL drop table #sessionTimeMayores;

CREATE TABLE #sessionTimeGroup( [user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
CREATE TABLE #sessionTimeMayores([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)

truncate table tmpSessionTimeGroup  


INSERT INTO #sessionTimeGroup
select * from tmpSessionGeneral

INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
delete #sessionTimeGroup where  datediff(mi,timegroup,timegroup_next)>15

insert into #sessionTimeGroup
    select [User_id],login,logout,extension, convert(varchar,th.start,121) as timegroup, convert(varchar, th.stop,121) as timegroup_next,
    dbo.TimeInterval(th.start,th.stop,login,logout) as [tlog seg]    

from #sessionTimeMayores t
inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0;

delete from #sessionTimeGroup where tlog=0 and DATEPART(MS,logout)<=700
    
update  #sessionTimeGroup set tlog=1 where tlog=0 and DATEPART(MS,logout)>700


insert into tmpSessionTimeGroup
select user_id,min([login]) as [login],max([logout]) as [logout],min(extension) as extension,timegroup,timegroup_next,sum(tlog) as tlog from #sessionTimeGroup  
group by user_id,timegroup,timegroup_next   
    

IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup
IF OBJECT_ID(''tempdb..#sessionTimeMayores'') IS NOT NULL drop table #sessionTimeMayores;

set nocount off'
    EXEC(@sql)


    set @process = 'DEV1-459 Alter Sp ccspTimesOutboundData se quita la creacion tabla tmpTimesOutboundData'
    set @sql='ALTER PROCEDURE [dbo].[ccspTimesOutboundData] 
@from AS SMALLDATETIME, @to AS SMALLDATETIME
AS
SET NOCOUNT ON


IF OBJECT_ID(N''tempdb..#outboundData2'', N''U'') IS NOT NULL
    DROP TABLE #outboundData2


TRUNCATE TABLE tmpTimesOutboundData

DECLARE @relastionCampWg TABLE (idwg INT, camId INT)

INSERT INTO @relastionCampWg
SELECT max(IDWG) AS IDWG, IdCampEsp AS Id
FROM ccRIACampEspWG
WHERE Tipo = 1
GROUP BY IdCampEsp

DECLARE @HourExtend AS SMALLINT
DECLARE @fromExtended AS SMALLDATETIME
DECLARE @tresRing AS SMALLINT
DECLARE @tresDialog AS SMALLINT
DECLARE @tresDelayIn AS SMALLINT

SELECT @HourExtend = 2

SELECT @fromExtended = DATEADD(hh, - @HourExtend, @from)

EXEC @tresRing = ccspConfigTresRing

EXEC @tresDialog = ccspConfigTresDialog

EXEC @tresDelayIn = ccspConfigtresDelayIn

DECLARE @dateNow DATETIME

SET @dateNow = GETDATE();

WITH outboundData AS (
SELECT ROW_NUMBER() OVER (ORDER BY cal_id ASC) AS rowId
, cal_inicio AS dateStartDetail 
,cal_id,cam_id,cal_tWait,cal_tXfer,cal_tRing,cal_tDialog,cal_tNotas 
,cal_telefono, User_id, statuscall_id, cal_que
,cal_tMoh, cal_whoHung, calif_id, cal_puerto
FROM ccoCallsOut
WHERE cal_inicio between @fromExtended AND @to AND cam_id > 0   
)
,callOutStart as(
select userId,MIN(dateIni) dateIni,callId,camType,camId
from tmpccLogAgentesDia 
where callId>0 and camType=1 and TipoStatusAge_id in(5,9,4,6)
group by userId,callId,camType,camId
)
, callDataStartXfer as(
select A.userId,B.callId,B.camType,B.camId,min(B.dateIni) as dateIni from callOutStart A
inner join tmpccLogAgentesDia B on A.userId=B.userId and A.dateIni=B.dateIni 
where B.tStatus>0
group by A.userId,B.callId,B.camType,B.camId
)
,outData  as(
    select 
    
    cal_Inicio AS dateStartDetail   
    , DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, ISNULL(B.dateIni,A.cal_Inicio)) AS dateEndDetail
    ,cam_id,[User_id], 1 AS ntotal
    ,CASE WHEN statuscall_id = 4 THEN 1 ELSE 0 END AS nno_agent
    ,CASE WHEN statuscall_id >= 10 THEN 1 ELSE 0 END AS nxfer
    ,CASE WHEN statuscall_id = 11 THEN 1 ELSE 0 END AS nabnd_xfer
    , CASE WHEN statuscall_id = 15 AND cal_tring <= @tresRing THEN 1 ELSE 0 END AS nabnd_ring
    , CASE WHEN statuscall_id = 15 AND cal_tring > @tresRing THEN 1 ELSE 0 END AS nno_answer
    , CASE WHEN statuscall_id = 13 AND cal_tdialog <= @tresDialog THEN 1 ELSE 0 END AS nabnd_dialog
    , CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog THEN 1 ELSE 0 END AS nanswer
    , CASE WHEN statuscall_id = 16 THEN 1 ELSE 0 END AS nlost
    , cal_twait AS tque, cal_txfer AS txfer, cal_tring AS tring, cal_tdialog AS tdialog, cal_tnotas AS tnotes
    , CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog THEN cal_txfer + cal_tring ELSE 0 END AS tresp
    , CASE WHEN statuscall_id = 6 THEN 1 ELSE 0 END AS nhangup
    , CASE WHEN cal_tMoh > 0 THEN 1 ELSE 0 END AS nMoh
    , CASE WHEN cal_whoHung > 0 THEN 1 ELSE 0 END AS nWHag
    , CASE WHEN cal_whoHung = 0 THEN 1 ELSE 0 END AS nWHcl
    , DATEADD(ss, cal_twait, cal_inicio) AS time_endque
    , ISNULL(B.dateIni,A.cal_Inicio) as dateXferAgtStart
    , DATEADD(ss, cal_txfer, ISNULL(B.dateIni,A.cal_Inicio)) AS time_ring
    , DATEADD(ss, cal_txfer + cal_tring, ISNULL(B.dateIni,A.cal_Inicio)) AS time_dialog
    , DATEADD(ss, cal_txfer + cal_tring + cal_tdialog, ISNULL(B.dateIni,A.cal_Inicio)) AS time_notes
    , DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, ISNULL(B.dateIni,A.cal_Inicio)) AS time_end_call
    , cal_telefono AS phone_out, cal_id, cal_puerto, C.idwg AS idwg
    , A.statuscall_id, A.calif_id, A.cal_manual, A.cal_tMoh
    from ccoCallsOut A
    left join callDataStartXfer B on A.cal_id= B.callId and A.cam_id=B.camId
    LEFT JOIN @relastionCampWg C ON A.cam_id = C.camId
    WHERE A.cal_Inicio between @fromExtended AND @to
)   

INSERT INTO tmpTimesOutboundData (
    dateStartDetail, dateEndDetail, cam_id, User_id, ntotal, nno_agent, nxfer, nabnd_xfer, nabnd_ring, nno_answer, nabnd_dialog, 
    nanswer, nlost, tque, txfer, tring, tdialog, tnotes, tresp, nhangup, nMoh, nWHag, nWHcl, time_endque,dateXferAgtStart, time_ring, time_dialog, 
    time_notes, time_end_call, phone_out, cal_id, cal_puerto, idwg, statuscall_id, calif_id, cal_manual, cal_tMoh, timegroup, 
    timegroup_next
    )
SELECT A.*, dbo.GetTimeGroup(dateStartDetail, 0) AS timegroup, dbo.GetTimeGroup(dateEndDetail, 1) AS timegroup_next
FROM outData A

declare @today date
set @today =convert(date,@dateNow,121)


/******************* Revisa si los datos son del dia ******************************/

IF @today = CONVERT(DATE, @to, 121)
BEGIN
        ;

    WITH lastAgentStatus
    AS (
        SELECT userId, max(dateIni) dateIn
        FROM tmpccLogAgentesDia
        WHERE dateIni BETWEEN @today AND @to
        GROUP BY userId
        ), timeAcumlate
    AS (
        SELECT A.userId, A.camId, A.callId, sum(CASE WHEN A.currentStatus IN (4, 5, 9) THEN A.tStatus 
                    ELSE 0 END) AS tdialog, sum(CASE WHEN A.currentStatus = 6 THEN A.tStatus ELSE 0 END) AS tnotes, max(A.dateEnd) AS 
            dateEnd, max(A.timeGroupNext) AS timeGroupNext
        FROM tmpccLogAgentesDia A
        INNER JOIN lastAgentStatus B ON A.userId = B.userId
            AND A.dateIni = B.dateIn
        WHERE A.dateIni BETWEEN @today   AND @to
            AND currentStatus IN (4, 5, 6, 9)
            AND A.camType = 1
        GROUP BY A.userId, A.camId, A.callId
        )
    UPDATE A
    SET A.dateEndDetail = B.dateEnd, A.timegroup_next = B.timeGroupNext, A.tdialog = CASE WHEN B.tdialog > 0 THEN B.tdialog ELSE A.
                tdialog END, A.tnotes = CASE WHEN B.tnotes > 0 THEN B.tnotes ELSE A.tnotes END, A.time_notes = CASE WHEN B.tdialog > 0 THEN B.
                    dateEnd ELSE A.time_dialog END, A.time_end_call = CASE WHEN B.tnotes > 0 THEN B.dateEnd ELSE A.time_notes END
    FROM tmpTimesOutboundData A
    INNER JOIN timeAcumlate B ON A.User_id = B.userId
        AND A.cam_id = B.camId
        AND A.cal_id = B.callId
END

SELECT *
INTO #outboundData2
FROM tmpTimesOutboundData
WHERE datediff(mi, timegroup, timegroup_next) > 15

DELETE tmpTimesOutboundData
WHERE datediff(mi, timegroup, timegroup_next) > 15

INSERT INTO tmpTimesOutboundData (
    dateStartDetail, dateEndDetail, timegroup, timegroup_next, cam_id, User_id, ntotal, nno_agent, nxfer, nabnd_xfer, nabnd_ring, 
    nno_answer, nabnd_dialog, nanswer, nlost, tque, txfer, tring, tdialog, tnotes, tresp, nhangup, nMoh, nWHag, nWHcl, time_endque, 
    dateXferAgtStart, time_ring, time_dialog, time_notes, time_end_call, phone_out, cal_id, cal_puerto, idwg, statuscall_id, calif_id,  
    cal_manual, cal_tMoh
    )
SELECT dateStartDetail, dateEndDetail, th.start AS timegroup, th.stop AS timegroup_next, cam_id, [User_id]
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN ntotal ELSE 0 END AS ntotal
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nno_agent ELSE 0 END AS nno_agent
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nxfer ELSE 0 END AS nxfer
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nabnd_xfer ELSE 0 END AS nabnd_xfer
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nabnd_ring ELSE 0 END AS nabnd_ring
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nno_answer ELSE 0 END AS nno_answer
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nabnd_dialog ELSE 0 END AS nabnd_dialog
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nanswer ELSE 0 END AS nanswer
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nlost ELSE 0 END AS nlost
    , dbo.TimeInterval(th.start, th.stop, dateStartDetail, time_endque) AS tque
    , dbo.TimeInterval(th.start, th.stop, dateXferAgtStart, time_ring) AS txfer
    , dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring
    , dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog
    , dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes
    , dbo.TimeInterval(th.start, th.stop, dateStartDetail
    , dateadd(ss, tresp, dateStartDetail)) AS tresp
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nhangup ELSE 0 END AS nhangup
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nMoh ELSE 0 END AS nMoh
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nWHag ELSE 0 END AS nWHag
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nWHcl ELSE 0 END AS nWHcl
    , time_endque, dateXferAgtStart, time_ring, time_dialog, time_notes, time_end_call 
    , phone_out, cal_id, cal_puerto, idwg, statuscall_id
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  calif_id ELSE - 2 END AS calif_id
    , cal_manual
    , dbo.AccountInterval(th.start, th.stop, dateStartDetail, dateEndDetail, cal_tMoh) AS cal_tMoh
    FROM #outboundData2 t
    INNER JOIN TmpTimesInterval th ON  ( t.timegroup > th.Start AND t.timegroup < th.stop)  OR th.Start BETWEEN t.timegroup AND t.timegroup_next
    WHERE datediff(ss, th.start, timegroup_next) > 0
    

IF OBJECT_ID(N''tempdb..#outboundData2'', N''U'') IS NOT NULL
    DROP TABLE #outboundData2
'
    EXEC(@sql)

   
    set @process = 'DEV1-459 alter SP ccspRepOutAnswCalls se quita with index '
    set @sql='ALTER PROCEDURE [dbo].[ccspRepOutAnswCalls]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()
                            
    delete RepOutAnswCalls with(rowlock)
    where [date] between @from and @to

    ;with   
    co as(
    select
    convert(date,cal_inicio,121) [date],
    co.cam_id campaignId, count(*) total, 
    COUNT(CASE WHEN(statusCall_id = 16)THEN co.cal_id ELSE NULL END) nasig_tl,
    COUNT(CASE WHEN(statuscall_id = 15)THEN co.cal_id ELSE NULL END) nasig_nc,
    COUNT(CASE WHEN(statuscall_id = 13)THEN co.cal_id ELSE NULL END) nAnswered,
    COUNT(CASE WHEN(statuscall_id = 11)THEN co.cal_id ELSE NULL END) nassigned,
    COUNT(CASE WHEN(statuscall_id in (6,4))THEN co.cal_id ELSE NULL END) nabdn_sis
    from ccocallsout co with(nolock,index(IX_ccoCallsOut13))    
    where cal_inicio between @from and @to 
    group by convert(date,cal_inicio,121),co.cam_id
    ) 
    ,wgCalId as(
    
        select campaignId,isnull(min(wg.IDWG),1) IDWG
        from co o 
        left join ccRIACampEspWG wg on o.campaignId =wg.IdCampEsp and wg.Tipo=1
        group by campaignId
    )
    

    insert RepOutAnswCalls
    select 
    [date], abnd.campaignId, ca.cam_descripcion campaign, 
    wg.IDWG workgroupId, e.WGName workgroup, isnull(f.IDArea,0) areaId, g.AreaName area, total,
    cast(((nasig_tl*100.0)/total) as decimal(5,2)) asig_tl,
    cast(((nasig_nc*100.0)/total) as decimal(5,2)) asig_nc,
    cast(((nAnswered*100.0)/total) as decimal(5,2)) Answered,
    cast(((nassigned*100.0)/total) as decimal(5,2)) assigned,
    cast(((nabdn_sis*100.0)/total) as decimal(5,2)) abdn_sis
    from co abnd    
    left join cccamps ca on ca.cam_id=abnd.campaignId 
    left join wgCalId wg on abnd.campaignId=wg.campaignId
    left join ccRIACat_WorkGroup as e on e.idwg = wg.idwg
    left join ccRIAAreaWorkGroup as f on f.idwg = e.idwg
    left join ccRIACat_Areas as g on g.idarea = f.idarea
                            
end'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepOutCallBilling se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepOutCallBilling]
    @action AS TINYINT,
    @from AS DATETIME= null,
    @to AS DATETIME= null

AS


    DECLARE @country AS TINYINT
    DECLARE @iva AS DECIMAL(3,2)
    DECLARE @aux AS VARCHAR(3)

    SELECT @country = CONVERT(TINYINT,isnull(valor,1)) FROM ccsettings WHERE setting_id = 104
    SELECT @aux = isnull(valor,0) FROM ccsettings WHERE setting_id = 25
    
    SET @iva=CONVERT(DECIMAL(3,2),''1.''+@aux)

    IF @country is null
        SET @country = 1
    IF @from is null
        SELECT @from = convert(DATETIME,convert(VARCHAR(11),getdate()))
    IF @to is null
        SELECT @to = getdate()

IF @action = 1
BEGIN

    IF OBJECT_ID(''tempdb..#TempOutCallBilling'') IS NOT NULL DROP TABLE #TempOutCallBilling
    IF OBJECT_ID(''tempdb..#TempTransCallBilling'') IS NOT NULL DROP TABLE #TempTransCallBilling

    DELETE FROM RepOutCallBilling WITH(rowlock) WHERE [date] >= @FROM AND [date] < @to

    CREATE TABLE #TempTransCallBilling(
        [date] datetime NOT NULL,
        camId INT NOT NULL,
        inboundId INT NOT NULL,
        userId INT NOT NULL,
        [proveedorId] INT NOT NULL,
        provedor VARCHAR(30) collate SQL_Latin1_General_CP1_CI_AS NOT NULL,
        [tipollamadaId] INT NOT NULL,   
        [tipoLlamada] VARCHAR(50) collate SQL_Latin1_General_CP1_CI_AS NOT NULL,
        [amount] INT NOT NULL,
        mins INT NOT NULL,
        costo DECIMAL(10,2) NOT NULL,
        costoIva DECIMAL(10,2) NOT NULL
    )


    create table #TempOutCallBilling(
        [date] datetime NOT NULL,
        camId INT NOT NULL,
        inboundId INT NOT NULL,
        userId INT NOT NULL,
        [proveedorId] INT NOT NULL,
        provedor VARCHAR(30) collate SQL_Latin1_General_CP1_CI_AS NOT NULL,
        [tipollamadaId] INT NOT NULL,   
        [tipoLlamada] VARCHAR(50) collate SQL_Latin1_General_CP1_CI_AS NOT NULL,
        [amount] INT NOT NULL,
        mins INT NOT NULL,
        costo DECIMAL(10,2) NOT NULL,
        costoIva DECIMAL(10,2) NOT NULL
        )


        CREATE NONCLUSTERED INDEX IX_#TempOutCallBilling_I ON [dbo].[#TempOutCallBilling] ([camId])
        INCLUDE ([date],[inboundId],userId,[proveedorId],[tipollamadaId],[tipoLlamada],[amount],mins,[costo],[costoIva])

    INSERT INTO #TempTransCallBilling
    
    SELECT 
        [date],
        [camp_id],
        [inbund_id],
        [user_id],
        CASE WHEN [proveedorId] IS NULL THEN -1 ELSE [proveedorId] END AS proveedorId,
        CASE WHEN provedor IS NULL THEN ''systemTranslated_NoCarrier'' ELSE provedor END AS provedor,
        [tipollamadaId],
        [tipoLlamada],
        COUNT(*) AS amount,
        SUM(mins) AS mins,  
        SUM([costo]) AS [costo],
        SUM( costo ) * @iva AS costoIva
    FROM (
        SELECT DATEADD(ss, -(tAntesXfer + tDespuesXfer),fechaFin) AS [date],
            cco.cam_id AS [camp_id],
            0 AS [inbund_id],
            cco.[User_id] AS [user_id],
            channel.proveedorId AS [proveedorId],
            prov.descrip AS provedor,
            tipoLlam.tipoLlamada_id AS [tipollamadaId],
            tipoLlam.descrip AS [tipoLlamada],
            CEILING((tAntesXfer+tDespuesXfer +1 ) / 60.0 )AS [mins],
            dbo.fnGetCstoTarifa(trans.tipoLlamada_id,channel.proveedorId,tAntesXfer+tDespuesXfer+1,@country) AS [costo]
        FROM 
            ccLogTransfers  trans 
            INNER JOIN ccoCallsOut cco ON cco.cal_id=trans.cal_id 
                    AND tipo = 2
            INNER JOIN cstoTipoLlamada tipoLlam ON  tipoLlam.country_id = @country 
                    AND tipoLlam.tipoLlamada_id = trans.tipoLlamada_id
            LEFT JOIN ccCallCost_RIA CCost on CCost.country_id = tipoLlam.country_id 
                    AND CCost.tipoLlamada_id = tipoLlam.tipoLlamada_id
            LEFT JOIN ccChannelTransfer channel ON channel.pbxId=trans.pbxId 
                    AND trans.channel BETWEEN channel.startChannel AND channel.endChannel
            LEFT JOIN cstoProvedor prov ON prov.provedor_id=channel.proveedorId
        WHERE trans.fechaFin BETWEEN @from AND @to

        UNION ALL

        SELECT DATEADD(ss, -(tAntesXfer + tDespuesXfer),fechaFin) AS [date],
            0 AS [camp_id],
            cci.Inbound_id AS [inbund_id],
            cci.[User_id] AS [user_id],
            channel.proveedorId AS [proveedorId],
            prov.descrip AS provedor,
            tipoLlam.tipoLlamada_id AS [tipollamadaId],
            tipoLlam.descrip AS [tipoLlamada],
            CEILING((tAntesXfer+tDespuesXfer +1 ) / 60.0 )AS [mins],
            dbo.fnGetCstoTarifa(trans.tipoLlamada_id,channel.proveedorId,tAntesXfer+tDespuesXfer+1,@country) AS [costo]
        FROM    
            ccLogTransfers  trans 
            INNER JOIN ccCallsIn cci ON cci.cal_id=trans.cal_id 
                    AND tipo = 1
            INNER JOIN cstoTipoLlamada tipoLlam ON  tipoLlam.country_id = @country 
                    AND tipoLlam.tipoLlamada_id = trans.tipoLlamada_id
            LEFT JOIN ccCallCost_RIA CCost on CCost.country_id = tipoLlam.country_id 
                            AND CCost.tipoLlamada_id = tipoLlam.tipoLlamada_id
            LEFT JOIN ccChannelTransfer channel ON channel.pbxId=trans.pbxId 
                    AND trans.channel BETWEEN channel.startChannel AND channel.endChannel
            LEFT JOIN cstoProvedor prov ON prov.provedor_id=channel.proveedorId
        WHERE trans.fechaFin BETWEEN @from AND @to 
            AND modo NOT IN (1,2)
    )x
    WHERE [costo] > 0
    GROUP BY [DATE],[camp_id],[inbund_id],[user_id],[proveedorId],provedor,[tipollamadaId],[tipoLlamada]
        
    insert into #TempOutCallBilling
    SELECT cal_inicio AS [date],
        cam_id,
        inboundId,
        [user_id],
        CASE WHEN provedor_id IS NULL THEN -1 ELSE provedor_id END AS provedor_id,
        '''' as provedor,
        tipoLlamada_id,
        MIN(tipoLlamada) AS tipoLlamada,
        COUNT(*) AS amount,
        isnull(SUM( mins),1) AS mins,
        isnull(SUM( costo ),0) AS costo,
        isnull(SUM( costo ),0)  * @iva AS costoIva  
    FROM
    (
        SELECT cal_inicio,
            cco.cam_id AS cam_id,
            0 AS inboundId,
            cco.user_id AS user_id,
            cco.provedor_id,
            cco.tipoLlamada_id,
            t.descrip AS tipoLlamada,
            CEILING((cal_tXfer + cal_tRing + totalCall_Time +1 ) / 60.0 ) AS mins,
            dbo.fnGetCstoTarifa(cco.tipoLlamada_id, cco.provedor_id, cco.totalCall_Time,@country) AS costo
        FROM ccoCallsOut cco
            INNER JOIN cstoTipoLlamada t with(nolock) ON cco.tipoLlamada_id = t.tipoLlamada_id 
                    AND country_id = @country
            LEFT JOIN ccCallCost_RIA CCost WITH(NOLOCK) ON CCost.country_id = t.country_id 
                    AND CCost.tipoLlamada_id = t.tipoLlamada_id 
        WHERE cal_inicio >= @FROM 
            AND  cal_inicio < @to
            AND [User_id] <> 0

        UNION ALL

        -- Tambien las llamdas que fueron fax
        SELECT cco.fecha AS fecha,
            cco.cam_id,0 AS inboundId,
            0 AS userId,
            p.provedor_id,
            l.tipoLlamada_id,
            l.descrip AS tipoLlamada,
            1 AS mins,
            CASE 
                WHEN p.provedor_id IS NOT NULL THEN t.MinutoUno
                ELSE CONVERT(DECIMAL(10,2),CCost.cost_per_min)
            END AS costo
        FROM ccoLogDials  cco with(nolock)
            INNER JOIN ccoDialers cd with(nolock)  ON cco.puerto = cd.puerto
            LEFT JOIN cstoProvedor p ON cd.provedor_id = p.provedor_id
            LEFT JOIN cstoTarifa t ON  p.provedor_id = t.provedor_id 
                    AND cco.tipoLlamada_id = t.tipoLlamada_id
            INNER JOIN cstotipollamada l on cco.tipoLlamada_id = l.tipoLlamada_id 
                    AND country_id = @country
            LEFT JOIN ccCallCost_RIA CCost WITH(NOLOCK) ON CCost.country_id = l.country_id 
            AND CCost.tipoLlamada_id = l.tipoLlamada_id     
        WHERE cco.fecha >=  @FROM 
            AND cco.fecha < @to  
            AND cco.answerbit = 1 
            AND cco.tiporesdial_id <> 1
    ) costo
    GROUP BY cal_inicio, cam_id,inboundId, [user_id], provedor_id, tipoLlamada_id
        

    INSERT RepOutCallBilling
    SELECT CONVERT(smalldatetime, CONVERT(VARCHAR(13), [date], 121) + '':00'', 121) AS [date],
        [cam_id],
        [campACDDescription],
        [user_id],[agentName],
        [username],
        [provedor_id],
        [provedor],
        [tipollamadaId],
        (CASE 
            WHEN tipo = ''amount'' THEN ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''Calls_Count''
            WHEN tipo = ''mins'' THEN + ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''MinBilled_Count''
            WHEN tipo = ''costo'' THEN + ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''Cost_Count''
            WHEN tipo = ''costoIva'' THEN + ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''Tax_Count''
            ELSE tipo
        END ) AS tipoLLamada_Count,
        CONVERT(VARCHAR,[tipollamada_Count])  AS [count],
        [tipoLLamada] AS tipoLlamadaDesp,
        CASE 
            WHEN tipo = ''costo'' THEN CONVERT(int,CONVERT(DECIMAL(10,2),[tipollamada_Count]) ) 
            ELSE 0 
        END,
        DATEPART(yyyy,[date]) AS [year],
        DATEPART(mm,[date]) AS [month],
        DATEPART(dd,[date]) AS [day],
        DATEPART(hh,[date]) AS [hour],
        DATEPART(mi,[date]) AS [min],
        inboundId AS [inboundId],
        [dialId],
        [dialType]
    FROM(
        SELECT [date],
            temp.camId AS cam_id,inboundId,
            ''Camp - '' + camps.cam_descripcion AS campACDDescription,
            ISNULL(ccuse.[user_id] ,0) AS [user_id],
            CASE 
                WHEN ccuse.[user_id] IS NULL THEN ''systemTranslated_NoName'' 
                ELSE  ccuse.Nombres+'' ''+ ccuse.ApellidoPaterno+'' ''+ccuse.ApellidoMaterno 
            END AS agentName,
            CASE
                WHEN ccuse.[Login] IS NULL THEN ''systemTranslated_NoUserName'' 
                ELSE ccuse.[Login] 
            END AS username,
            temp.proveedorId AS provedor_id,
            CASE WHEN prov.descrip IS NULL THEN ''systemTranslated_NoCarrier'' ELSE prov.descrip END AS provedor,
            [tipoLlamadaId],
            [tipoLLamada],
            [tipoLLamada] AS tipoLlamadaDesp,
            CONVERT(VARCHAR,[amount]) AS [amount],
            CONVERT(VARCHAR,[mins]) AS [mins],
            CONVERT(VARCHAR,[costo]) AS [costo],
            CONVERT(VARCHAR,[costoIva]) AS [costoIva],
            di.id AS [dialId],
            di.[description] AS [dialType]
        FROM #TempOutCallBilling temp
            INNER JOIN ccCamps camps ON camps.cam_id = temp.camId
            LEFT JOIN ccUserView ccuse ON ccuse.[User_id] = temp.[userId]
            LEFT JOIN cstoprovedor prov ON prov.provedor_id = temp.proveedorId
            INNER JOIN Dials di ON di.Id = 2
        UNION ALL
        SELECT [date],
            camId,
            inboundId,
            CASE
                WHEN camps.cam_descripcion IS NULL THEN ''ACD - '' + cci.descripcion 
                ELSE ''Camp - ''+ camps.cam_descripcion 
            END AS campACDDescription,
            ISNULL(ccuse.[user_id] ,0) AS [user_id],
            CASE 
                WHEN ccuse.[user_id] IS NULL THEN ''systemTranslated_NoName''  
                ELSE  ccuse.Nombres+'' ''+ ccuse.ApellidoPaterno+'' ''+ccuse.ApellidoMaterno 
            END AS agentName,
            CASE
                WHEN ccuse.[Login] IS NULL THEN ''systemTranslated_NoUserName''
                ELSE ccuse.[Login]
            END AS username,
            [proveedorId],
            CASE WHEN provedor IS NULL THEN ''systemTranslated_NoCarrier'' ELSE provedor END,
            [tipollamadaId],
            [tipoLlamada],
            [tipoLlamada] [tipoLlamadaDesp],
            CONVERT(VARCHAR,[amount]) AS [amount],
            CONVERT(VARCHAR,[mins]) AS [mins],
            CONVERT(VARCHAR,[costo]) AS [costo],
            CONVERT(VARCHAR,[costoIva]) AS [costoIva],
            di.Id AS [dialId],
            di.[description] AS [dialType]
        FROM #TempTransCallBilling temp
            LEFT JOIN ccCamps camps ON camps.cam_id = temp.camId
            LEFT JOIN ccinbound cci ON cci.Inbound_id=temp.inboundId 
            LEFT JOIN ccUserView ccuse ON ccuse.[User_id] = temp.userId
            INNER JOIN Dials di ON di.Id = 1
    ) p
    UNPIVOT
        ([tipollamada_Count] for tipo IN
        ([amount], [mins], [costo], [costoIva])
    )AS unpvt
    

    IF OBJECT_ID(''tempdb..#TempOutCallBilling'') IS NOT NULL DROP TABLE #TempOutCallBilling
    IF OBJECT_ID(''tempdb..#TempTransCallBilling'') IS NOT NULL DROP TABLE #TempTransCallBilling


END'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepOutCallsDetail se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] 
@action as tinyint,
@from as datetime = NULL,
@to as datetime = NULL
AS

IF @from IS NULL
    SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
    SELECT @to = getdate()

DECLARE @IVA INT
DECLARE @country AS TINYINT

SELECT @IVA = convert(INT, isnull(valor, 0))
FROM ccsettings
WHERE setting_id = 25

SELECT @country = convert(TINYINT, isnull(valor, 1))
FROM ccsettings
WHERE setting_id = 104

IF @country IS NULL
    SET @country = 1

IF @action = 1
BEGIN
    --Borrar lo que esta para no repetir
    DELETE
    FROM RepOutCallsDetail WITH (ROWLOCK)
    WHERE DATE >= @from AND DATE < @to

    INSERT INTO RepOutCallsDetail
    SELECT Call.cal_inicio AS [date],
        Call.cal_key AS [callKey],
        Call.cal_telefono AS [telephone],
        Call.cal_txfer + call.cal_tring AS [transfer],
        Call.cal_tdialog AS [dialog],
        ISNULL(Call.cal_tMoh, 0) AS [nque],
        Call.cal_tnotas AS [wrapup],
        ISNULL(Tipo.[description], '''') AS [CallDisposition],
        Call.cal_extension AS [extension],
        isnull(Usr.user_id, 0) AS [userId],
        ISNULL(convert(VARCHAR(255), Usr.LOGIN), ''systemTranslated_NoUserName'') [login],
        ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username],
        camps.cam_id AS [campaignId],
        ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
        (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration],
        CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country)) AS [ncost],

        @IVA AS iva,
        CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country) * (1 + (@IVA / 100.00))) AS total,
        CASE 
            WHEN prov.descrip IS NOT NULL THEN prov.descrip
            ELSE ''systemTranslated_NoCarrier'' 
        END AS [ByCarrier],
        ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [Calltypes],
        CASE 
            WHEN LEFT(ld.TipoDialingMode, 1) = ''1'' THEN ''systemTranslated_Assisted'' ELSE
            CASE WHEN Call.cal_manual = 0 THEN ''systemTranslated_Auto'' 
            ELSE ''systemTranslated_Manual'' END
        END AS [dialType], 
        CASE 
            WHEN Call.cal_whoHung = 0 THEN ''systemTranslated_Client'' 
            WHEN Call.cal_whoHung = 1 THEN ''systemTranslated_Agent'' 
            ELSE ''systemTranslated_AgentSurvey'' 
        END [whoHangUp], 
        CASE 
            WHEN call.califsub_id = 0 THEN ''systemTranslated_NoSubDisposition'' 
            ELSE isnull(sub.califSubDesc, '''') 
        END AS [subDisposition],
        sta.descripcion AS [dialResult], 
        Call.cal_id as [calId],
        datepart(yyyy, Call.cal_inicio) AS [year],
        datepart(mm, Call.cal_inicio) AS [month],
        datepart(dd, Call.cal_inicio) AS [day],
        datepart(hh, Call.cal_inicio) AS [hour],
        datepart(mi, Call.cal_inicio) AS [minutes],
        Call.cal_puerto,
        ISNULL(cs.Dato1, '''') AS [data1],
        ISNULL(cs.Dato2, '''') AS [data2],
        ISNULL(cs.Dato3, '''') AS [data3],
        ISNULL(cs.Dato4, '''') AS [data4],
        ISNULL(cs.Dato5, '''') AS [data5],
        ISNULL(Call.cal_tMsg, 0) AS [MessageTime],
        ISNULL(rc.grab_id, 0) as grabId
    FROM ccoCallsOut Call (nolock)
        LEFT JOiN ccoLogDials ld (nolock) ON Call.cal_id=ld.cal_id
        LEFT JOIN ccTipoCalifOUT Tipo (nolock) ON Call.calif_id = Tipo.calif_id
        LEFT JOIN ccUserView Usr (nolock) ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
        LEFT JOIN ccCamps camps (nolock) ON camps.[cam_id] = Call.[cam_id]
        LEFT JOIN ccStatusLlamada sta (nolock) ON call.statuscall_id = sta.statuscall_id
        LEFT JOIN cstoProvedor prov (nolock) ON prov.[provedor_id] = Call.[provedor_id]
        LEFT JOIN cstoTipoLlamada tl (nolock) ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] AND tl.Country_id = @country)
        LEFT JOIN ccTipoCalifSubOut sub (nolock) ON call.califsub_id = sub.califsub_id
        LEFT JOIN ccoDialers di (nolock) ON di.dialer_id = Call.cal_puerto AND call.provedor_id = di.provedor_id
        LEFT JOIN ccoCallsOutSource cs (nolock) ON Call.callout_id = cs.callout_id
        LEFT JOIN ccCallCost_RIA cc (nolock) ON cc.country_id = tl.country_id AND cc.tipoLlamada_id = tl.tipoLlamada_id
        LEFT JOIN Ria_grabacion rc (nolock) on (rc.cal_id = Call.cal_id and rc.tipo_llamada = 2)
    WHERE Call.cal_inicio >= @from AND Call.cal_inicio < @to AND Call.cal_manual IN (0, 2)
    ORDER BY DATE
END'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepOutKPI se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepOutKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET NOCOUNT ON

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
    delete RepOutKPI with(rowlock)
    where date >= @from AND date < @to

    insert into RepOutKPI
    select dateHour, cam_id, campaign, sum(totalCalls) as totalCalls,
    sum(txfer)/sum(totalCalls) as avgXfer, sum(tDialog)/sum(totalCalls) as avgCallTime,
    sum(C10) as c10sec, sum(C20) as c20sec, sum(C30) as c30sec, sum(CMax) as cMax,
    sum(AnsweredCalls) as AnsweredCalls, (sum(AnsweredCalls) * 100.00)/sum(totalCalls) as AnsweredPctg,
    sum(RemainingCalls) as RemainingCalls, (sum(RemainingCalls) * 100.00)/sum(totalCalls) as RemainingPct,
    sum(AbandonedCalls) as AbandonedCalls, (sum(AbandonedCalls) * 100.00)/sum(totalCalls) as AbandonedPctg,
    (3600*1.00)/sum(totalCalls) as AvgTimeBtwCalls,
    datepart(yyyy,max(dateHour)) as [year], datepart(mm,max(dateHour)) as [month], datepart(dd,max(dateHour)) as [day],
    datepart(hh,max(dateHour)) as [hour], datepart(mi,max(dateHour)) as [minutes]
    from
    (
        select CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour, cam_id, '''' as campaign,
        count(*) as totalCalls,
        cal_tXfer as tXfer,
        cal_tDialog as tDialog,
        case when statusCall_id = 13 and cal_tDialog<=10 then 1 else 0 end C10,
        case when statusCall_id = 13 and cal_tDialog<=20 and cal_tDialog > 10 then 1 else 0 end C20,
        case when statusCall_id = 13 and cal_tDialog<=30 and cal_tDialog > 20 then 1 else 0 end C30,
        case when statusCall_id = 13 and cal_tDialog>30 then 1 else 0 end CMax,
        case when statusCall_id = 13 then 1 else 0 end as AnsweredCalls,
        0.00 as AnsweredPctg,
        case when statusCall_id not in (13,5) then 1 else 0 end  as RemainingCalls,
        0.00 as RemainingPct,
        case when statusCall_id in(5,6,7,8,9,10,11,15,16) then 1 else 0 end  as AbandonedCalls,
        0.00 as AbandonedPctg,
        0.00 as AvgTimeBtwCalls
        from ccocallsout with(nolock)
        where cal_inicio >= @from and cal_inicio < @to
        group by statusCall_id, cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121), cal_tXfer, cal_tDialog
    ) as final
    group by dateHour, cam_id, campaign
    order by dateHour, cam_id

    update RepOutKPI with(rowlock)
    set campaign = isnull(b.cam_descripcion,'''')
    from RepOutKPI a
    left join ccCamps b
    on a.campaignId = b.cam_id
    where date >= @from AND date < @to

end'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepSpececialAbnd se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepSpececialAbnd]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

declare @setting smallint
select @setting= valor from ccSettings where setting_id=43
if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()

    delete RepSpececialAbnd with(rowlock)
    where [date] between @from and @to
    
    insert RepSpececialAbnd select [date], campaignId, inboundId, [Espec/Camp], total, abandonedCalls, 
    cast(((abandonedCalls*100.0)/total) as decimal(5,2)) abandonedCallsPctg from (
        select convert(varchar(10),cal_inicio,121) [date], 0 campaignId, ci.inbound_id inboundId, 
        ''ACD - '' + descripcion [Espec/Camp], count(*) total, 
        COUNT(
        CASE WHEN @setting = 0 and (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00''))  THEN 1
             WHEN @setting = 1 and (statuscall_id IN (6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00'')) THEN 1
         ELSE NULL END) abandonedCalls
        from cccallsin ci with(nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id 
        where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, ''ACD - '' + descripcion
        union all
        select convert(varchar(10),cal_inicio,121) [date], co.cam_id campaignId, 0 inboundId, 
        ''Camp - '' + cam_descripcion [Espec/Camp], count(*) total, 
        COUNT(
            CASE WHEN @setting = 0 and (statuscall_id in(11,15,16))THEN cal_id 
                 WHEN @setting = 1 and (statuscall_id in(6))THEN cal_id ELSE NULL END) abandonedCalls
        from ccocallsout co with(nolock) left join cccamps ca on ca.cam_id=co.cam_id 
        where cal_inicio between @from and @to and cal_manual in (0,2) group by convert(varchar(10),cal_inicio,121), co.cam_id, ''Camp - '' + cam_descripcion
    ) abnd
end
    '
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepSpececialAbndPercentage se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepSpececialAbndPercentage]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS
declare @setting smallint
set @setting=1
select @setting= valor from ccSettings where setting_id=43 

begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null
        select @to = getdate()

    delete RepSpececialAbndPercentage with(rowlock)
    where [date] between @from and @to

    insert RepSpececialAbndPercentage select [date], inboundId, [inbound]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [5]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [10]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [15]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [20]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [25]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [30]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [40]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [50]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [60]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [>60]
            from (
                select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
                ,cal_id
                ,SUM(CASE WHEN  @setting = 0 and (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) 
                          WHEN  @setting = 1 and (statuscall_id = 6) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
                ,COUNT(
                    CASE WHEN @setting = 0 and (statuscall_id <> 13) THEN 1 
                         WHEN @setting = 1 and (statuscall_id = 6) THEN 1 ELSE NULL END) AS nAbnd
                from cccallsin ci with(nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id
                where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
            ) xCalls
        GROUP BY [date], inboundId, [inbound]
end
'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepSpececialAbndProfiles se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepSpececialAbndProfiles]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS
declare @setting smallint
select @setting= valor from ccSettings where setting_id=43
if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null
        select @to = getdate()

    delete RepSpececialAbndProfiles with(rowlock)
    where [date] between @from and @to

    insert RepSpececialAbndProfiles select [date], inboundId, [inbound]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))) AS [5]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))) AS [10]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))) AS [15]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))) AS [20]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))) AS [25]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))) AS [30]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))) AS [40]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))) AS [50]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))) AS [60]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 THEN 1 ELSE NULL END),0))) AS [>60]
        , COUNT(*) total
            from (
                select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
                ,cal_id
                ,SUM(CASE WHEN  @setting = 0 and (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) 
                          WHEN  @setting = 1 and (statuscall_id = 6) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
                ,COUNT(
                    CASE WHEN @setting = 0 and (statuscall_id <> 13) THEN 1 
                         WHEN @setting = 1 and (statuscall_id = 6) THEN 1 ELSE NULL END) AS nAbnd
                from cccallsin ci with(nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id
                where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
            ) xCalls
        GROUP BY [date], inboundId, [inbound]
end
'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepSpececialAbndTimes se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepSpececialAbndTimes]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

declare @setting smallint
select @setting= valor from ccSettings where setting_id=43

if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null
        select @to = getdate()

    delete RepSpececialAbndTimes with(rowlock)
    where [date] between @from and @to

    insert RepSpececialAbndTimes select [date], inboundId, [inbound]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [5]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [10]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [15]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [20]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [25]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [30]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [40]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [50]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [60]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [>60]
            from (
                select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
                ,cal_id
                ,SUM(CASE WHEN  @setting = 0 and (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) 
                          WHEN  @setting = 1 and (statuscall_id = 6) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
                ,COUNT(
                    CASE WHEN @setting = 0 and (statuscall_id <> 13) THEN 1 
                         WHEN @setting = 1 and (statuscall_id = 6) THEN 1 ELSE NULL END) AS nAbnd
                from cccallsin ci with(nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id
                where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
            ) xCalls
        GROUP BY [date], inboundId, [inbound]
end
'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepSpececialAgtPerformance se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepSpececialAgtPerformance]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()
                            
    DECLARE @data varchar(10), @promesa INT, @promesainb INT, @tresDialog AS smallint
    EXEC @tresDialog=ccspConfigTresDialog
    select @data = isnull(valor,''1|1'') from ccSettings where setting_id = 30
    SELECT @promesainb = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 1
    SELECT @promesa = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 2
                        
    delete RepSpececialAgtPerformance with(rowlock)
    where [date] between @from and @to

    insert RepSpececialAgtPerformance select [date],rcalls.USER_ID [userId]
    ,us.apellidopaterno + '' '' + us.apellidomaterno + '' '' + nombres [user],login [Agent]
    ,answer Answered, promises, promisesPctg, dialog avgCallTime, wrapup avgWrapupTime
    from (
    select [date], user_id, SUM(answer) answer, SUM(promises) promises
    ,isnull(cast(SUM(promises)*100.0/nullif(SUM(answer),0) as decimal(5,2)),0) promisesPctg
    ,isnull(sum(dialog)/nullif(SUM(answer),0),0) dialog, isnull(sum(wrapup)/nullif(SUM(answer),0),0) wrapup
    from (
    select 
    CONVERT(varchar(10),cal_inicio,121) [date], user_id
    ,isnull(sum(cal_tdialog),0) dialog, isnull(sum(cal_tnotas),0) wrapup
    ,isnull(count(case calif_id when @promesa then 1 else null end),0) promises
    ,isnull(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) answer
    from ccoCallsOut with(nolock) where cal_inicio between @from and @to and cal_manual in(0,2) and USER_ID>0
    group by CONVERT(varchar(10),cal_inicio,121),user_id
    union all
    select
    CONVERT(varchar(10),cal_inicio,121) [date], user_id
    ,isnull(sum(cal_tdialog),0) dialog, isnull(sum(cal_tnotas),0) wrapup
    ,isnull(count(case calif_id when @promesainb then 1 else null end),0) promises
    ,isnull(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) answer
    from ccCallsIn with(nolock) where cal_inicio between @from and @to  and USER_ID>0
    group by CONVERT(varchar(10),cal_inicio,121),user_id) calls group by [date],user_id) rcalls 
    left join ccUserView us on us.user_id=rcalls.user_id
end'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepSpecialAbndCamp se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepSpecialAbndCamp]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null
        select @to = getdate()

    delete RepSpecialAbndCamp with(rowlock) where [date] between @from and @to

    insert RepSpecialAbndCamp
    select [date], campaignId, cam_descripcion, total, abandonedCalls,
    cast(isnull(((abandonedCalls*100.0)/nullif(total,0)),0) as decimal(5,2)) abandonedCallsPctg,
    [year],[month],[day],[hour],[minutes]
    from(
        select convert(datetime,convert(varchar(13),cal_inicio,121)+'':00'') as [date], co.cam_id campaignId,
        cam_descripcion , count(*) total,
        COUNT(CASE WHEN(statuscall_id in(5,6,7,8,9,10,11,15,16))THEN cal_id ELSE NULL END) abandonedCalls,
        datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS [year],
        datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) as [month],
        datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) as [day],
        datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) as [hour],
        datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) as [minutes]
        from ccocallsout co with(nolock) left join cccamps ca on ca.cam_id=co.cam_id
        where cal_inicio between @from and @to and
        cal_manual in (0,2)
        group by convert(varchar(13),cal_inicio,121), co.cam_id,  cam_descripcion)X

end'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepSpecialTelephoneNumbersByRegistry se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepSpecialTelephoneNumbersByRegistry]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET NOCOUNT ON

create table #tempPhone(
[date] datetime,camId int,
tel1 int,tel2 int,tel3 int,tel4 int,tel5 int,
listid int
)
create table #sumTempPhone (
[date] datetime,
totalPhone int
)

create index IX_TEMPPHONE  on #tempPhone(listid)

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
    select @to = getdate()

if @action = 1
begin
    delete from RepSpecialTelephoneNumbersByRegistry where date >= @from and date < @to

    insert into #tempPhone
        select
        convert(datetime,convert(varchar(11),min(cal_fechaDial))) as [date],
        cam_id as camId,
        sum(case when cal_telefono <> '''' then 1 else 0 end),
        sum(case when cal_telefono2 <> '''' then 1 else 0 end),
        sum(case when cal_telefono3 <> '''' then 1 else 0 end),
        sum(case when cal_telefono4 <> '''' then 1 else 0 end),
        sum(case when cal_telefono5 <> '''' then 1 else 0 end),
        list_id
    from ccoCallsOutSource 
    where cal_fechaDial >= @from and cal_fechaDial < @to
    group by cam_id,list_id

    insert into #sumTempPhone
    select  [date],SUM(tel1+tel2+tel3+tel4+tel5) from #tempPhone
    group by [date] 

    insert into RepSpecialTelephoneNumbersByRegistry
    select date,campaignId,campaign,listId,listName
    ,cPhoneNumber_count as cPhoneNumbers,''systemTranslated_'' + cPhoneNumber_count+''_Count'' as cPhoneNumber_Count,[count]
    ,percentage_avg as percentage,''systemTranslated_'' + percentage_avg + ''_Avg'' as percentage_avg,[avg],
    [year],[month],[day],[hour],[minutes]
    from (
    select tem.[date],
    camId as ''campaignId'', camp.cam_descripcion as ''campaign'',
        isnull(rl.list_id,0) as ''listId'', isnull(rl.name, '''') as ''listName'',
        tem.tel1 as cPhoneNumbers1,tem.tel2 as cPhoneNumbers2,tem.tel3 as cPhoneNumbers3,tem.tel4 as cPhoneNumbers4,tem.tel5 as cPhoneNumbers5,
        dbo.fPercentage(tem.tel1,sumTemp.totalPhone ) as percentage1,
        dbo.fPercentage(tem.tel2,sumTemp.totalPhone) as percentage2,
        dbo.fPercentage(tem.tel3,sumTemp.totalPhone) as percentage3,
        dbo.fPercentage(tem.tel4,sumTemp.totalPhone) as percentage4,
        dbo.fPercentage(tem.tel5, sumTemp.totalPhone) as percentage5,
        datepart(yy,convert(datetime, convert(varchar(11),tem.[date]))) as [year],
        datepart(mm,convert(datetime, convert(varchar(11),tem.[date]))) as [month],
        datepart(dd,convert(datetime, convert(varchar(11),tem.[date]))) as [day],
        datepart(hh,convert(datetime, convert(varchar(11),tem.[date]))) as [hour],
        datepart(mi,convert(datetime, convert(varchar(11),tem.[date]))) as [minutes]
     from #tempPhone tem
     inner join ccRIARegistryLists rl on tem.listid =  rl.list_id
     inner join cccamps camp on camp.cam_id=tem.camId
     inner join #sumTempPhone sumTemp on tem.date=sumTemp.date)p
     UNPIVOT(
     [count] FOR cPhoneNumber_count IN  (cPhoneNumbers1, cPhoneNumbers2, cPhoneNumbers3, cPhoneNumbers4, cPhoneNumbers5)
        )AS unpvt
     UNPIVOT(
     [avg] FOR percentage_avg IN  (percentage1, percentage2, percentage3, percentage4, percentage5)
        )AS unpvt2
    where RIGHT(cPhoneNumber_count,1) = RIGHT(percentage_avg,1)

    drop table #tempPhone
    drop table #sumTempPhone

end'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepSpecialTelephoneNumbersByState se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepSpecialTelephoneNumbersByState]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

declare @totales int

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
    select @to = getdate()

if @action = 1
begin
    delete from RepSpecialTelephoneNumbersByState with(rowlock) where date >= @from and date < @to

    select @totales = isnull( COUNT(callout_id), 0)
    from ccoCallsOutSource with(nolock)
    where cal_fechaDial >= @from
    and cal_fechaDial < @to
    and Region is not null

    insert into RepSpecialTelephoneNumbersByState
    select convert(datetime,convert(varchar(11),cal_fechaDial)) as [date],
       isnull([cos].list_id,0) as ''listId'', isnull(rl.name, '''') as ''listName'',
       Region as [state],
       Region + ''_Count'' as [state_Count],
       isnull( COUNT(callout_id), 0) as ''Count'',
       Region + ''_Avg'' as ''state_avg'',
       dbo.fPercentage(isnull( COUNT(callout_id), 0), @totales) as ''avg'',
       datepart(yy,convert(datetime, convert(varchar(11),cal_fechaDial))) as [year],
       datepart(mm,convert(datetime, convert(varchar(11),cal_fechaDial))) as [month],
       datepart(dd,convert(datetime, convert(varchar(11),cal_fechaDial))) as [day],
       datepart(hh,convert(datetime, convert(varchar(11),cal_fechaDial))) as [hour],
       datepart(mi,convert(datetime, convert(varchar(11),cal_fechaDial))) as [minutes]
       from ccoCallsOutSource [cos] with(nolock)
       left join ccRIARegistryLists rl on [cos].list_id =  rl.list_id
    where cal_fechaDial >= @from
    and cal_fechaDial < @to
    and Region is not null
    group by convert(datetime,convert(varchar(11),cal_fechaDial)) , [cos].list_id, rl.name, Region
end
'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepInChangeFlow se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepInChangeFlow]
    @action as tinyint,
    @from AS datetime = NULL,
    @to AS datetime = NULL
AS

SET NOCOUNT ON
SET DATEFIRST 1

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

    DELETE FROM RepInChangeFlow with(rowlock)
    WHERE [date]>=@from AND [date]<@to

    INSERT INTO RepInChangeFlow
    ([date],inboundId,inbound,weekday_count,[count],[time],[year],[month],[day],[hour],[minutes])
    
    SELECT
        [date],
        inbound_id,
        '''',
        ''day'' + cast (datepart(weekday,[date]) AS VARCHAR(1)) + ''_Count'',
        ISNULL(xfer,0) AS [count],
        left(CONVERT(varchar(20), [date], 114), 8),
        datepart(yyyy,[date]),
        datepart(mm,[date]),
        datepart(dd,[date]),
        datepart(hh,[date]),
        datepart(mi,[date])
    FROM(
        
        SELECT
            CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) AS [date],
            inbound_id,
            COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END) AS xfer
        FROM ccCallsIn
            with (nolock)
            WHERE cal_inicio>=@from AND cal_inicio<@to AND INBOUND_ID > 0 AND [user_id] > 0
            GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id
    ) xFers
    WHERE [date]>=@from AND [date]<@to
    AND ISNULL(xfer,0) > 0
    ORDER BY [date],inbound_id
    
    update r set
    r.Inbound = isnull(i.Descripcion,'''')
    from RepInChangeFlow r, ccInbound i
    where [date] >= @from and [date] < @to
    and i.Inbound_id = r.InboundId 
    and i.inbound_id is not null
    
end'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepInDIDResume se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepInDIDResume]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off 
set ANSI_WARNINGS off

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

--Sets amount of hours of last day to include in calculations of agent times
DECLARE @HourExtend AS smallint
SELECT @HourExtend = 2

--@fromExtended used to include the times of calls that extend FROM previous day
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended = DATEADD(hh, -@HourExtend, @from)

DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint
DECLARE @tresDelayIn AS smallint

EXEC @tresRing = ccspConfigTresRing
EXEC @tresDialog = ccspConfigTresDialog
EXEC @tresDelayIn = ccspConfigtresDelayIn

if @action = 1
begin

    CREATE TABLE [dbo].[#ccGenInCallDNI](
        [timegroup] [smalldatetime] NOT NULL,
        [dni_id] [smallint] NOT NULL,
        [user_id] [smallint] NOT NULL,
        [ntotal] [smallint] NOT NULL,
        [ninitial] [smallint] NOT NULL,
        [nout_hour] [smallint] NOT NULL,
        [nout_service] [smallint] NOT NULL,
        [nabnd] [smallint] NOT NULL,
        [nno_agent] [smallint] NOT NULL,
        [nque] [smallint] NOT NULL,
        [ntimeout] [smallint] NOT NULL,
        [noverflow] [smallint] NOT NULL,
        [nxfer] [smallint] NOT NULL,
        [nxfer_que] [smallint] NOT NULL,
        [nabnd_xfer] [smallint] NOT NULL,
        [nabnd_ring] [smallint] NOT NULL,
        [nno_answer] [smallint] NOT NULL,
        [nabnd_dialog] [smallint] NOT NULL,
        [nanswer] [smallint] NOT NULL,
        [nlost] [smallint] NOT NULL,
        [nmsg] [smallint] NOT NULL,
        [nabnd_tres] [smallint] NOT NULL,
        [nansw_tres] [smallint] NOT NULL,
        [tque_max] [smallint] NOT NULL,
        [tque] [int] NOT NULL,
        [txfer] [int] NOT NULL,
        [tdialog] [int] NOT NULL,
        [tnotes] [int] NOT NULL,
        [tring] [int] NOT NULL,
        [tresp] [int] NOT NULL,
    
    ) ON [PRIMARY]

    INSERT INTO #ccGenInCallDNI (timegroup, dni_id, [user_id]
        , ntotal, nout_hour, nout_service
        , nabnd, nno_agent, nque, ntimeout
        , noverflow, nxfer, nxfer_que
        , nabnd_xfer, nabnd_ring ,nno_answer
        , nabnd_dialog, nanswer, nlost, nmsg
        , nabnd_tres, nansw_tres, tque_max
        , tque, txfer, tring
        , tdialog, tnotes, tresp, ninitial)
    SELECT timegroup, dni_id, [user_id], ntotal, nout_hour, nout_service
        , nabnd, nno_agent, nque, ntimeout, noverflow, nxfer, nxfer_que
        , nabnd_xfer, nabnd_ring ,nno_answer, nabnd_dialog, nanswer, nlost, nmsg
        , nabnd_tres, nansw_tres, tque_max, tque, txfer, tring, tdialog, tnotes, tresp, ninitial
    FROM (      
        SELECT xDetailTime.timegroup, xDetailTime.dni_id, xDetailTime.[user_id]
            , ISNULL(ntotal, 0) AS ntotal, ISNULL(initial, 0) AS ninitial, ISNULL(out_hour, 0) AS nout_hour, ISNULL(out_service, 0) AS nout_service
            , ISNULL(abnd, 0) AS nabnd, ISNULL(no_agent, 0) AS nno_agent, ISNULL(que, 0) AS nque, ISNULL(timeout, 0) AS ntimeout
            , ISNULL(overflow, 0) AS noverflow, ISNULL(xfer, 0) AS nxfer, ISNULL(xfer_que, 0) AS nxfer_que
            , ISNULL(abnd_xfer, 0) AS nabnd_xfer, ISNULL(abnd_ring, 0) AS nabnd_ring, ISNULL(no_answer, 0) AS nno_answer
            , ISNULL(abnd_dialog, 0) AS nabnd_dialog, ISNULL(answer, 0) AS nanswer, ISNULL(lost, 0) AS nlost, ISNULL(msg, 0) AS nmsg
            , ISNULL(abnd_tres, 0) AS nabnd_tres, ISNULL(answ_tres, 0) AS nansw_tres, ISNULL(tque_max, 0) AS tque_max
            , xDetailTime.tque, xDetailTime.txfer, xDetailTime.tring
            , xDetailTime.tdialog, xDetailTime.tnotes, ISNULL(tresp, 0) AS tresp
        FROM (  
            SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
                , dni_id
                , [user_id]
                , COUNT(cal_id) AS ntotal
                , COUNT(CASE WHEN statuscall_id = 1 THEN 1 ELSE NULL END) AS initial
                , COUNT(CASE WHEN statuscall_id = 2 THEN 1 ELSE NULL END) AS out_hour 
                , COUNT(CASE WHEN statuscall_id = 3 THEN 1 ELSE NULL END) AS out_service
                , COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
                , COUNT(CASE WHEN (statuscall_id = 4) THEN 1 ELSE NULL END) AS no_agent
                , COUNT(CASE WHEN (cal_que > 0) THEN 1 ELSE NULL END) AS que 
                , COUNT(CASE WHEN (statuscall_id = 7) THEN 1 ELSE NULL END) AS timeout
                , COUNT(CASE WHEN (statuscall_id = 8) THEN 1 ELSE NULL END) AS overflow
                , COUNT(CASE WHEN( (statuscall_id in (11,15,13,16)) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'') ) THEN 1 ELSE NULL END) AS xfer
                , COUNT(CASE WHEN ( (cal_que > 0) and (statuscall_id in (11,15,13,16)  OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00''))  ) THEN cal_xfer ELSE NULL END) AS xfer_que
                , COUNT(CASE WHEN ((statuscall_id = 11) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'')) THEN 1 ELSE NULL END) AS abnd_xfer
                , COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring <= @tresRing)) THEN 1 ELSE NULL END) AS abnd_ring
                , COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring > @tresRing)) THEN 1 ELSE NULL END) AS no_answer
                , COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  <= @tresDialog)) THEN 1 ELSE NULL END) AS abnd_dialog
                , COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
                , COUNT(CASE WHEN (statuscall_id = 16) THEN 1 ELSE NULL END) AS lost
                , COUNT(CASE WHEN (statuscall_id IN (9, 10, 12, 14)) THEN 1 ELSE NULL END) AS msg
                , COUNT(CASE WHEN ( (statuscall_id IN (5,6) AND cal_que > 0 AND cal_xfer = ''1900-01-01 00:00:00'') AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS abnd_tres
                , COUNT(CASE WHEN ( (statuscall_id = 13 AND cal_tdialog > @tresDialog) AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS answ_tres
                , ISNULL(MAX(cal_twait), 0) AS tque_max
                , ISNULL(SUM(cal_twait), 0) AS tque
                , ISNULL(SUM(cal_txfer), 0) AS txfer
                , ISNULL(SUM(cal_tdialog), 0) AS tdialog
                , ISNULL(SUM(cal_tnotas), 0) AS tnotes
                , ISNULL(SUM(cal_tring), 0) AS tring
                , ISNULL(SUM(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN (cal_twait + cal_txfer + cal_tring) ELSE NULL END), 0) AS tresp
            FROM ccCallsIn
            WHERE cal_inicio >= @fromExtended AND  cal_inicio < @to AND dni_id > 0
            GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), dni_id, [user_id]
        ) xDetailCount
        LEFT JOIN
        (
            SELECT timegroup
                , dni_id
                , [user_id]
                , ISNULL(SUM(cal_twait), 0) AS tque
                , ISNULL(SUM(cal_txfer), 0) AS txfer
                , ISNULL(SUM(cal_tring), 0) AS tring
                , ISNULL(SUM(cal_tdialog), 0) AS tdialog
                , ISNULL(SUM(cal_tnotas), 0) AS tnotes
            FROM ( SELECT timegroup, dni_id, [user_id]
                    , CASE WHEN time_endque < timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss, timegroup_next, time_endque) END AS cal_twait
                    , CASE WHEN (time_ring < timegroup_next) THEN cal_txfer WHEN ((time_ring >= timegroup_next) AND (time_endque < timegroup_next)) THEN cal_txfer - DATEDIFF(ss, timegroup_next, time_ring) ELSE 0 END  AS cal_txfer
                    , CASE WHEN (time_dialog < timegroup_next) THEN cal_tring WHEN ((time_dialog >= timegroup_next) AND (time_ring < timegroup_next)) THEN cal_tring - DATEDIFF(ss, timegroup_next, time_dialog) ELSE 0 END  AS cal_tring
                    , CASE WHEN (time_notes < timegroup_next) THEN cal_tdialog WHEN ((time_notes >= timegroup_next) AND (time_dialog < timegroup_next)) THEN cal_tdialog - DATEDIFF(ss, timegroup_next, time_notes) ELSE 0 END  AS cal_tdialog
                    , CASE WHEN (time_end_call < timegroup_next) THEN cal_tnotas WHEN ((time_end_call >= timegroup_next) AND (time_notes < timegroup_next)) THEN cal_tnotas - DATEDIFF(ss, timegroup_next, time_end_call) ELSE 0 END  AS cal_tnotas
                FROM (
                    SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
                        , DATEADD(hh, 1, CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121))  AS timegroup_next
                        , DATEADD(ss, cal_twait, cal_inicio)  AS time_endque
                        , DATEADD(ss, cal_twait + cal_txfer, cal_inicio)  AS time_ring
                        , DATEADD(ss, cal_twait + cal_txfer + cal_tring, cal_inicio)  AS time_dialog
                        , DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_inicio)  AS time_notes
                        , DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas, cal_inicio)  AS time_end_call
                        , *
                    FROM ccCallsIn
                    WHERE cal_inicio >= @fromExtended AND  cal_inicio < @to  AND dni_id > 0
                ) xDetail
                UNION
                SELECT timegroup_next, dni_id, [user_id]
                    , CASE WHEN time_endque >= timegroup_next THEN DATEDIFF(ss, timegroup_next, time_endque) ELSE 0 END AS cal_twait
                    , CASE WHEN (time_ring < timegroup_next) THEN 0 WHEN ((time_ring >= timegroup_next) AND (time_endque < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_ring) ELSE cal_txfer END AS cal_txfer
                    , CASE WHEN (time_dialog < timegroup_next) THEN 0 WHEN ((time_dialog >= timegroup_next) AND (time_ring < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_dialog) ELSE cal_tring END AS cal_tring
                    , CASE WHEN (time_notes < timegroup_next) THEN 0 WHEN ((time_notes >= timegroup_next) AND (time_dialog < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_notes) ELSE cal_tdialog END AS cal_tdialog
                    , CASE WHEN (time_end_call < timegroup_next) THEN 0 WHEN ((time_end_call >= timegroup_next) AND (time_notes < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_end_call) ELSE cal_tnotas END AS cal_tnotas
                FROM    (
                    SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
                        , DATEADD(hh, 1, CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121))  AS timegroup_next
                        , DATEADD(ss, cal_twait, cal_inicio)  AS time_endque
                        , DATEADD(ss, cal_twait + cal_txfer, cal_inicio)  AS time_ring
                        , DATEADD(ss, cal_twait + cal_txfer + cal_tring, cal_inicio)  AS time_dialog
                        , DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_inicio)  AS time_notes
                        , DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas, cal_inicio)  AS time_end_call
                        , *
                    FROM ccCallsIn
                    WHERE cal_inicio >= @fromExtended AND  cal_inicio < @to  AND dni_id > 0
                ) xDetail
            ) xTimeDetail
            GROUP BY timegroup, dni_id, [user_id]
        ) xDetailTime
        ON (xDetailTime.timegroup = xDetailCount.timegroup AND xDetailTime.dni_id = xDetailCount.dni_id AND xDetailTime.[user_id] = xDetailCount.[user_id])
    ) xComplete
    WHERE timegroup >= @from AND  timegroup < @to
    AND NOT (ntotal = 0 AND nout_hour = 0 AND nout_service = 0 AND nabnd = 0 AND nno_agent = 0 AND nque = 0
        AND ntimeout = 0 AND noverflow = 0 AND nxfer = 0 AND nxfer_que = 0 AND nabnd_xfer = 0 AND nabnd_ring = 0
        AND nno_answer = 0 AND nabnd_dialog = 0 AND nanswer = 0 AND nlost = 0 AND nmsg = 0 AND nabnd_tres = 0
        AND nansw_tres = 0 AND tque_max = 0 AND tque = 0 AND txfer = 0 AND tring = 0 AND tdialog = 0 AND tnotes = 0 AND tresp = 0)
    ORDER BY timegroup, dni_id, [user_id]
    
    delete [RepInDIDResume] with(rowlock)
    where date >= @from AND date < @to 

    insert into [RepInDIDResume]
    select timegroup as date, a.dni_id as dnisId,  CASE WHEN ccd.dni_descripcion = '''' then  convert(varchar,min(ccd.dni_numero)) else ccd.dni_descripcion end as dnis, 
           (CASE WHEN ccd.dni_descripcion = '''' then  convert(varchar,min(ccd.dni_numero)) else ccd.dni_descripcion end) + ''_Count'' as dnis_count, sum(nanswer) as [count]
    , datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
    , datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
    , datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
    , datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
    , datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes] 
    from dbo.#ccGenInCallDNI a
    left join ccdnis ccd on (a.dni_id = ccd.dni_id)
    where timegroup >= @from
    and timegroup < @to     
    group by timegroup,a.dni_id,dni_descripcion
    having sum(nanswer) > 0

    drop table #ccGenInCallDNI

end'
    EXEC(@sql)


    set @process = 'DEV1-459 alter SP ccspRepMKTAgentes se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepMKTAgentes]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
 set nocount on
if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
        select @to = getdate()

if @action = 1 begin

select
    cal_inicio dateStartDetail,
    dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
    [dbo].[GetTimeGroup](case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end,0) as timegroup,
    [dbo].[GetTimeGroup](
    dateadd(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) 
    ,1) as timegroup_next,
         c.user_id,

         isnull(count(case when c.statusCall_id=13 then 1 else null end),0) nacd,
         isnull(count(case when c.statusCall_id=13 and c.cal_tnotas>0 then 1 else null end),0) nacw,
         isnull(count(case when l.modo in (3,4) and l.tipo=1 then 1 else NULL end),0) cayuda,
         isnull(count(case when l.modo in (0,3,4) and l.tipo=1 then 1 else NULL end),0) nxfersal,
         isnull(sum(case when c.statuscall_id = 13 then (c.cal_twait + c.cal_txfer + c.cal_tring) else 0 end),0) tresp,
         isnull(sum(case when c.statusCall_id=13 and c.cal_tdialog>=0 then c.cal_tdialog else 0 end),0) tacd,
         isnull(sum(case when c.statusCall_id=13 then c.cal_tnotas else 0 end),0) tacw

        ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
        ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
        ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
       into #timeAgenteTransfer
       from cccallsin c
       LEFT OUTER JOIN ccLogTransfers l (nolock) on (l.cal_id = c.cal_id and l.fechaFin between @from and @to)
       where c.cal_inicio between @from and @to and 
       c.user_id>0
       and c.inbound_id>0     
       group by c.user_id,cal_inicio
       ,[dbo].[GetTimeGroup](case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end,0)
       ,[dbo].[GetTimeGroup](
        dateadd(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) 
        ,1)

    select * into #timeAgenteTransfer2 from #timeAgenteTransfer where datediff(mi,timegroup,timegroup_next)>15
    delete #timeAgenteTransfer where datediff(mi,timegroup,timegroup_next) > 15
    insert into #timeAgenteTransfer
    select dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,
        [User_id]
        ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nacd else 0 end as nacd
        ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nacw else 0 end as nacw
        ,case when th.start > dateStartDetail and th.stop > dateEndDetail then cayuda else 0 end as cayuda
        ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfersal else 0 end as nxfersal
        ,[dbo].TimeInterval(th.Start,th.Stop,dateStartDetail,time_dialog) as tresp
        ,[dbo].TimeInterval(th.Start,th.Stop,time_dialog,time_notes) as tacd
        ,[dbo].TimeInterval(th.Start,th.Stop,time_notes,dateEndDetail) as tacw
        ,time_dialog,time_notes,time_end_call

    from #timeAgenteTransfer2 t
    join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
    where  datediff(ss,th.start,timegroup_next)>0  

select dateadd(ss,-tstatus,fecha) dateStartDetail,
           fecha dateEndDetail,
    dbo.GetTimeGroup(dateadd(ss,isnull(-tstatus,0),fecha),0)  as timegroup,
    dbo.GetTimeGroup(fecha,1 ) as timegroup_next,
    user_id,
             (case when TipoStatusAge_id = 7 then tstatus else 0 end) t_otra,
             (case when TipoStatusAge_id = 2 then tstatus else 0 end) t_aux,
             (case when TipoStatusAge_id = 3 then tstatus else 0 end) t_disp,
             (case when TipoStatusAge_id = 4 then tstatus else 0 end) t_dialog,
             (case when TipoStatusAge_id = 6 then tstatus else 0 end) t_notas,
             tstatus t_pers
        , case when TipoStatusAge_id = 7 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_otra
, case when TipoStatusAge_id = 2 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_aux
, case when TipoStatusAge_id = 3 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_disp
, case when TipoStatusAge_id = 4 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_dialog
, case when TipoStatusAge_id = 6 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_notas
,fecha time_total
        into #timeAgenteStatus
       from cclogagentesdia
       where fecha between @from and @to 
    order by user_id,fecha

    select * into #timeAgenteStatus2 from #timeAgenteStatus where datediff(mi,timegroup,timegroup_next)>15
    delete #timeAgenteStatus where datediff(mi,timegroup,timegroup_next) > 15

    insert into #timeAgenteStatus
    select dateStartDetail,dateEndDetail,th.start,th.stop,user_id
    ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_otra and  th.stop > time_otra and t_otra>0 then datediff(ss,dateStartDetail,time_otra)
      when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_otra and t_otra>0 then datediff(ss,dateStartDetail,th.stop)
      when th.start > dateStartDetail and th.start <= time_otra and  th.stop > time_otra and t_otra>0 then datediff(ss,th.start,time_otra)
      when th.start > dateStartDetail and th.stop < time_otra and t_otra>0 then datediff(ss,th.start,th.stop) else  0 end as t_otra
    ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_aux and  th.stop > time_aux and t_aux>0  then datediff(ss,dateStartDetail,time_aux)
      when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_aux and t_aux>0 then datediff(ss,dateStartDetail,th.stop)
      when th.start > dateStartDetail and th.start <= time_aux and  th.stop > time_aux and t_aux>0 then datediff(ss,th.start,time_aux)
      when th.start > dateStartDetail and th.stop < time_aux and t_aux>0 then datediff(ss,th.start,th.stop)  else  0 end as t_aux

    ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_disp and  th.stop > time_disp and t_disp>0 then datediff(ss,dateStartDetail,time_disp)
      when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_disp and t_disp>0 then datediff(ss,dateStartDetail,th.stop)
      when th.start > dateStartDetail and th.start <= time_disp and  th.stop > time_disp and t_disp>0 then datediff(ss,th.start,time_disp)
      when th.start > dateStartDetail and th.stop < time_disp and t_disp>0 then datediff(ss,th.start,th.stop) else  0 end as t_disp

    ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_dialog and  th.stop > time_dialog and t_dialog>0 then datediff(ss,dateStartDetail,time_dialog)
      when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_dialog and t_dialog>0 then datediff(ss,dateStartDetail,th.stop)
      when th.start > dateStartDetail and th.start <= time_dialog and  th.stop > time_dialog and t_dialog>0 then datediff(ss,th.start,time_dialog)
      when th.start > dateStartDetail and th.stop < time_dialog and t_dialog>0 then datediff(ss,th.start,th.stop) else  0 end as t_dialog
    ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_notas and  th.stop > time_notas and t_notas>0 then datediff(ss,dateStartDetail,time_notas)
      when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_notas and t_notas>0 then datediff(ss,dateStartDetail,th.stop)
      when th.start > dateStartDetail and th.start <= time_notas and  th.stop > time_notas and t_notas>0 then datediff(ss,th.start,time_notas)
      when th.start > dateStartDetail and th.stop < time_notas and t_notas>0 then datediff(ss,th.start,th.stop) else  0 end as t_notas
    ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_total and  th.stop > time_total and t_pers>0 then datediff(ss,dateStartDetail,time_total)
      when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_total and t_pers>0 then datediff(ss,dateStartDetail,th.stop)
      when th.start > dateStartDetail and th.start <= time_total and  th.stop > time_total and t_pers>0 then datediff(ss,th.start,time_total)
      when th.start > dateStartDetail and th.stop < time_total and t_pers>0 then datediff(ss,th.start,th.stop) else  0 end as t_pers
    ,time_otra,time_aux,time_disp,time_dialog,time_notas,time_total
    from #timeAgenteStatus2 t
    inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
    where  datediff(ss,th.start,timegroup_next)>0


delete from dbo.RepMKTAgentes with(rowlock)
        where date >= @from AND date < @to

;WITH cte (date,user_id,CallsperACDGroupD,tACD,[tAgent],oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW, year, month,day,hour,minutes)
AS
(
select isnull(convert(varchar(24),acd.timegroup,121),convert(varchar(24),tready.timegroup,121)) date,
        isnull(acd.user_Id,tready.User_id),
        isnull(acd.nacd,0) [CallsperACDGroupD],
        isnull(acd.tacd,0) [tACD],
        isnull(acd.tresp,0) [tAgent],
        isnull(tready.t_otra,0) [oHour],
       isnull(tready.t_aux,0) [tAux],
       isnull(tready.t_disp,0) [readyTime],
       isnull(tready.t_pers,0) [tPer],
       isnull(acd.cayuda,0) [Ayuda],
       isnull(acd.nxfersal,0) [nxfer],
       isnull(acd.nacw,0) [nacw],
       isnull(acd.tACW,0) [tACW],
    isnull(datepart(yyyy,convert(varchar(24),acd.timegroup,121)),0) year,
    isnull(datepart(mm, acd.timegroup),0) month,
    isnull(datepart(dd, convert(varchar(24),acd.timegroup,121)),0) day,
    isnull(datepart(hh, convert(varchar(24),acd.timegroup,121)),0) hour,
    isnull(datepart(mi,convert(varchar(24),acd.timegroup,121)),0) minutes
from (
select 
acd.timegroup,
acd.user_id,
sum(nacd) nacd,
sum(nacw) nacw,
sum(cayuda) cayuda ,
sum(nxfersal) nxfersal,
sum(tresp) tresp,
sum(tacd) tacd,
sum(tacw) tacw
    from #timeAgenteTransfer acd group by acd.timegroup,acd.user_id 
    ) acd
full join
(select 
timegroup,
user_id,
sum(t_otra) t_otra,
sum(t_aux) t_aux,
sum(t_disp) t_disp,
sum(t_pers) t_pers
    from #timeAgenteStatus group by timegroup,user_id)tready on tready.user_id=acd.user_id and tready.timegroup=acd.timegroup) 

insert into RepMKTAgentes(date,userId,login,agentName,CallsperACDGroupD,tACD,tAgent,oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW,year,month,day,hour,minutes)
select date,a.user_id,u.Login,
(isnull(u.apellidopaterno,u.apellidopaterno)+'' ''+isnull(u.apellidomaterno,'''')+'' ''+isnull(u.nombres,'''')) agt_name,
CallsperACDGroupD,tACD,[tAgent],oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW, year, month,day,hour,minutes from cte a
inner join ccUserView as u on a.user_id=u.user_id
order by date,Login

drop table #timeAgenteTransfer
drop table #timeAgenteTransfer2
drop table #timeAgenteStatus
drop table #timeAgenteStatus2

end
'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepChatsAndCallsGeneral se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepChatsAndCallsGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
begin
    select @from = convert(datetime,convert(varchar(11),getdate()))
end
if @from is null
begin
    select @to = convert(datetime,convert(varchar(11),getdate()))
end

DECLARE @HourExtend AS smallint, @fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

declare @DTChat as int
select @DTChat = valor from ccsettings where setting_id = 33

if @action = 1
begin
    CREATE TABLE [dbo].[#callsin](
        [timegroup] [smalldatetime] NOT NULL,
        [inbound_id] [smallint] NOT NULL,
        [dni_id] [smallint] NOT NULL,
        [user_id] [smallint] NOT NULL,
        [ntotal] [smallint] NOT NULL,
        [ninitial] [smallint] NOT NULL,
        [nout_hour] [smallint] NOT NULL,
        [nout_service] [smallint] NOT NULL,
        [nabnd] [smallint] NOT NULL,
        [nno_agent] [smallint] NOT NULL,
        [nque] [smallint] NOT NULL,
        [ntimeout] [smallint] NOT NULL,
        [noverflow] [smallint] NOT NULL,
        [nxfer] [smallint] NOT NULL,
        [nxfer_que] [smallint] NOT NULL,
        [nabnd_xfer] [smallint] NOT NULL,
        [nabnd_ring] [smallint] NOT NULL,
        [nno_answer] [smallint] NOT NULL,
        [nabnd_dialog] [smallint] NOT NULL,
        [nanswer] [smallint] NOT NULL,
        [nlost] [smallint] NOT NULL,
        [nmsg] [smallint] NOT NULL,
        [nabnd_tres] [smallint] NOT NULL,
        [nansw_tres] [smallint] NOT NULL,
        [tque_max] [smallint] NOT NULL,
        [tque] [int] NOT NULL,
        [txfer] [int] NOT NULL,
        [tdialog] [int] NOT NULL,
        [tnotes] [int] NOT NULL,
        [tring] [int] NOT NULL,
        [tresp] [int] NOT NULL,
        [nMoh] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCall_nMoh]  DEFAULT ((0)),
        [nWHag] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCall_nWHag]  DEFAULT ((0)),
        [nWHcl] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCall_nWHcl]  DEFAULT ((0)),
    ) ON [PRIMARY]

    INSERT INTO #callsin(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
    ,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
    ,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
    SELECT timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
    ,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
    ,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
    FROM
    (
        SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
        ,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
        ,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
        ,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
        ,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
        ,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
        ,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
        ,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
        FROM
        (
            SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id,[user_id]
            ,COUNT(cal_id)AS ntotal
            ,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
            ,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
            ,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
            ,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer is null))THEN 1 ELSE NULL END)AS abnd
            ,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
            ,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
            ,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
            ,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
            ,COUNT(CASE WHEN((statuscall_id in(11,13,15,16))OR(statuscall_id=6 AND cal_xfer is not null))THEN 1 ELSE NULL END)AS xfer
            ,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,13,15,16)OR(statuscall_id=6 AND cal_xfer is not null)))THEN cal_xfer ELSE NULL END)AS xfer_que
            ,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer is not null))THEN 1 ELSE NULL END)AS abnd_xfer
            ,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
            ,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
            ,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
            ,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
            ,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
            ,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
            ,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer is null) AND (cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
            ,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
            ,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
            ,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
            ,ISNULL(SUM(CASE WHEN((statuscall_id=13) AND (cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE 0 END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
            ,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
            FROM ccCallsIn with (nolock)
            WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
            GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id,[user_id]
        )xDetailCount
        right JOIN
        (
            SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
            ,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
            FROM
            (
                SELECT timegroup,inbound_id,dni_id,[user_id]
                ,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
                ,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
                ,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
                ,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
                ,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
                FROM
                (
                    SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
                    ,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
                    ,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
                    ,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
                    ,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
                    ,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
                    ,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
                    ,*
                    FROM ccCallsIn with (nolock)
                    WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
                )xDetail
                UNION
                SELECT timegroup_next,inbound_id,dni_id,[user_id]
                ,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
                ,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
                ,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
                ,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
                ,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
                FROM
                (
                    SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
                    ,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
                    ,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
                    ,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
                    ,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
                    ,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
                    ,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
                    ,* FROM ccCallsIn with (nolock) 
                    WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
                )xDetail
            )xTimeDetail
            GROUP BY timegroup,inbound_id,dni_id,[user_id]
        )xDetailTime
        ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id = xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id])
    )xComplete
    WHERE timegroup>=@from AND timegroup<@to
    AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
    AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
    AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
    AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)


    SELECT CONVERT(varchar(20), timegroup, 120) as [date], ccInbound.inbound_id as inboundId, descripcion as inbound, 
    ntotal, nabnd_que, tque_max, nnoanswer, nanswer, SL, avgTQueue
    into #partialCalls
    FROM 
    (   
        SELECT xDetCall.tg as timegroup , xDetCall.inbound_id  as inbound_id,
        ISNULL(ntotal, 0) ntotal, ISNULL(nabnd_que, 0) nabnd_que , ISNULL(tque_max, 0) tque_max , 
        ISNULL(tque, 0) tque, ISNULL(nanswer, 0) nanswer , ISNULL(tque/ NULLIF(nque, 0), 0) avgTQueue, 
        convert(decimal(10,2),ISNULL(SL_P_1 * 100 / NULLIF(ntotal,0), 0)) SL, ninitial + [nout_hour] + nabnd_xfer + nabnd_ring + nabnd_dialog + nno_agent + ntimeout + noverflow + nno_answer + nlost as nnoanswer,
        SL_P_1, SL_P_2
        FROM 
        (
            SELECT timegroup as tg, inbound_id, SUM(ntotal) ntotal , SUM(nabnd) nabnd_que , 
            MAX(tque_max) tque_max, NULLIF(SUM(nque), 0) nque,
            SUM(tque) tque, SUM(nanswer) nanswer, SUM(nanswer) AS SL_P_1 , 
            SUM(ninitial + [nout_hour] +  nabnd_xfer + nabnd_ring + nabnd_dialog + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, 
            SUM(nabnd) nabnd, SUM(nno_agent) nno_agent, SUM(ntimeout) ntimeout, SUM(noverflow) noverflow, 
            SUM(nno_answer) nno_answer, SUM(nlost) nlost, sum([nout_hour]) [nout_hour], sum(nabnd_xfer) nabnd_xfer,
            SUM(nabnd_ring) nabnd_ring, SUM(nabnd_dialog) nabnd_dialog, SUM(ninitial) ninitial
            FROM #callsin  
            WHERE timegroup >= @from 
            AND timegroup < @to
            GROUP BY  timegroup, inbound_id
        ) xDetCall
    ) xDetail  
    INNER JOIN ccInbound ON (xDetail.inbound_id = ccInbound.inbound_id) 
    where ccInbound.inbound_id is not null

    
    select [date], inboundId, descripcion, [totalChats], [waitingAbandoned], maxTQueue, notConnected, Connected, 
    convert(decimal(10,2),ISNULL(convert(float,[Connected_AbandonValid]) * 100 / NULLIF(convert(float,Total),0), 0)) as SL,
    avgTQueue
    into #partialChats
    from
    (
        select fecha as [date],
        inboundId, b.descripcion,
        max([totalChats]) as [totalChats],
        sum([waitingAbandoned]) as [waitingAbandoned],
        max(maxTQueue) as maxTQueue,
        sum([UnavailableAgents] + [OutOfService] + [OutOfSchedule] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow] + [Assigned] + [Connected<DT]) as [notConnected],
        sum([Connected]) as [Connected],
        max(avgTQueue) as avgTQueue,
        sum([Connected] + [AbandonValid]) as [Connected_AbandonValid], 
        sum([Connected] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow] + [UnavailableAgents] + [OutOfService] + [OutOfSchedule]) as Total
        from(
            select inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as fecha,
            count(*) as [totalChats],
            ISNULL(count(CASE WHEN(chatstatus = 4 and tChatting >= @DTChat) THEN 1 ELSE NULL END),0)AS [Connected],
            ISNULL(count(CASE WHEN(chatstatus = 4 and tChatting < @DTChat) THEN 1 ELSE NULL END),0)AS [Connected<DT],
            ISNULL(count(CASE WHEN(chatstatus = 2)THEN 1 ELSE NULL END),0)AS [UnavailableAgents],
            ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
            ISNULL(count(CASE WHEN(chatstatus = 5)THEN 1 ELSE NULL END),0)AS [OutOfService],
            ISNULL(count(CASE WHEN(chatstatus = 6)THEN 1 ELSE NULL END),0)AS [OutOfSchedule],
            ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
            ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
            ISNULL(count(CASE WHEN(chatstatus = 9 and tQueue>=@tresDialog) THEN 1 ELSE NULL END),0)AS [waitingAbandoned],
            ISNULL(count(CASE WHEN(chatstatus = 9 and tQueue<@tresDialog)THEN 1 ELSE NULL END),0)AS [AbandonValid],
            ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
            ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow],
            max(tqueue) as maxTQueue,
            avg(tqueue) as avgTQueue
            from ccRIAChats a
            where requestDate >= @from and requestDate < @to and
            chatStatus in (2,3,4,5,6,7,9,10,11)
            group by inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121)
        ) as ChatDetail
        left join ccInbound b on (b.inbound_id = ChatDetail.inboundId)
        where fecha >= @from and fecha < @to
        group by inboundId, fecha, b.descripcion
    ) as ChatSummary 
    

    delete RepChatsAndCallsGeneral with(rowlock)
    where date >= @from and date <= @to

    insert into RepChatsAndCallsGeneral
    select 
    convert(datetime,isnull(a.date, b.date)) as date,
    isnull(a.inboundId,b.inboundId) as inboundId, 
    isnull(a.inbound,b.descripcion) as descripcion,
    isnull(ntotal,0) as ntotal, 
    isnull(totalChats,0) as totalChats, 
    isnull(nabnd_que,0) as nabnd_que, 
    isnull(waitingAbandoned,0) as waitingAbandoned, --CHAT en espera abandonas
    isnull(tque_max,0) as tque_max, 
    isnull(maxTQueue,0) as maxTQueue, -- Tiempo en espera
    isnull(nnoanswer,0) as nnoanswer, 
    isnull(notConnected,0) as notConnected,
    isnull(nanswer,0) as nanswer, 
    isnull(Connected,0) as Connected, 
    isnull(a.SL,0) as SL1,
    isnull(b.SL,0) as SL2, 
    isnull(a.avgTQueue,0) as avgTQueue1, 
    isnull(b.avgTQueue,0) as avgTQueue2,
    YEAR(convert(datetime,isnull(a.date, b.date))) as [year],
    MONTH(convert(datetime,isnull(a.date, b.date))) as [month],
    DAY(convert(datetime,isnull(a.date, b.date))) as [day],
    datepart(HOUR, convert(datetime,isnull(a.date, b.date))) as [hour],
    datepart(MINUTE,convert(datetime,isnull(a.date, b.date))) as [minutes]
    from #partialCalls a
    full join #partialChats b on (a.date = b.date and a.inboundId = b.inboundId)

        
    drop table #partialChats
    drop table #partialCalls
    drop table #callsin
end'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepInAnsw se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepInAnsw]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()
        
    declare @number int 
    DECLARE @tresDialog AS smallint
    EXEC @tresDialog = ccspConfigTresDialog
  
    SELECT [date], areaId, CAST('''' as varchar(50)) area, 0 workgroupId, CAST('''' as varchar(50)) workgroup, inbound_id, isnull(inbound,'''') inbound, amount, time_max,
        time_tot, LT10, LT20, LT30, LT40, LT50, LT60, LT120, LT180, LT240, LT300, GT300, [year], [month], [day], [hour], [minutes]
    INTO #AnswData
    FROM
    (SELECT timegroup [date]
        , IDArea areaId
        , xCalls.inbound_id, descripcion inbound
        , COUNT(cal_inicio) AS amount
        , MAX(tAnsw) AS time_max
        , SUM(tAnsw) AS time_tot
        , COUNT(CASE WHEN tAnsw < 10  THEN 1 ELSE NULL END) as [LT10]
        , COUNT(CASE WHEN tAnsw BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [LT20]
        , COUNT(CASE WHEN tAnsw BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [LT30]
        , COUNT(CASE WHEN tAnsw BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [LT40]
        , COUNT(CASE WHEN tAnsw BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [LT50]
        , COUNT(CASE WHEN tAnsw BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [LT60]
        , COUNT(CASE WHEN tAnsw BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [LT120]
        , COUNT(CASE WHEN tAnsw BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [LT180]
        , COUNT(CASE WHEN tAnsw BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [LT240]
        , COUNT(CASE WHEN tAnsw BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [LT300]
        , COUNT(CASE WHEN tAnsw >= 300  THEN 1 ELSE NULL END) as [GT300]
        , datepart(yyyy,timegroup) [year], datepart(mm,timegroup) [month], datepart(dd,timegroup) [day]
        , datepart(hh,timegroup) [hour], datepart(mi,timegroup) [minutes]
     FROM   (
            SELECT start timegroup
                , cal_inicio
                , inbound_id                
                , statuscall_id
                , (CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
                , (cal_twait + cal_txfer + cal_tring) AS tAnsw
             FROM ccCallsIn ci with(nolock)
                JOIN TmpTimesInterval th on cal_inicio between Start and [Stop]
                WHERE cal_inicio >= @from AND  cal_inicio < @to
                AND INBOUND_ID > 0
        ) xCalls left join ccInbound Ib ON Ib.inbound_id=xCalls.inbound_id 
    WHERE (answer IS NOT NULL) 
    GROUP BY timegroup, IDArea, xCalls.inbound_id, descripcion) Rep
    
    update #AnswData set
    [workgroupId] = b.idwg
    from #AnswData a, ccInboundAgentes b
    where a.inbound_id = b.inbound_id

    update #AnswData
    set workgroup = wgname, area = areaname
    from #AnswData a, ccriacat_workgroup b, ccriacat_areas c
    where a.[workgroupId] = b.idwg
    and a.areaId = c.idarea

    delete [RepInAnsw] with(rowlock)
    where [date] between @from and @to
    
    insert [RepInAnsw] select * from #AnswData
end'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepInBill01900 se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepInBill01900]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off 
set ANSI_WARNINGS off

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
begin

    --Borrar lo que esta para no repetir
    delete from RepInBill01900 with(rowlock)
    where date >= @from AND date < @to

    INSERT INTO RepInBill01900(date,inboundId,inbound,ntotalin,nxfer,tque2,txfer,tdialog,tring,[nminutes],[ncost],[year],[month],[day],[hour],[minutes])
    SELECT timegroup,xComplete.inbound_id,ccInbound.descripcion,ntotal,nxfer,tque,txfer,tdialog,tring, ceiling((tque+txfer+tdialog+tring) / 60.00),
    convert(int,ceiling((tque+txfer+tdialog+tring) / 60.00) * 25)
    , datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
    , datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
    , datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
    , datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
    , datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes] 
    FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
        ,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
        ,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
        ,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
        ,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
        ,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
        ,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
        ,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
    FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id
        ,COUNT(cal_id)AS ntotal
        ,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
        ,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
        ,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
        ,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd 
        ,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
        ,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
        ,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
        ,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
        ,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS xfer
        ,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END)AS xfer_que
        ,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
        ,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
        ,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
        ,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
        ,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
        ,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
        ,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
        ,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
        ,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
        ,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
        ,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
        ,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
        ,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
    FROM ccCallsIn with (nolock)
    WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
    GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id)xDetailCount
    right JOIN(SELECT timegroup,inbound_id,dni_id,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
        ,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
    FROM(SELECT timegroup,inbound_id,dni_id
        ,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
        ,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
        ,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
        ,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
        ,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
    FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
        ,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
        ,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
        ,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
        ,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
        ,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
        ,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
        ,*
    FROM ccCallsIn with (nolock)
    WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
    UNION
    SELECT timegroup_next,inbound_id,dni_id
        ,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
        ,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
        ,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
        ,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
        ,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
    FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
        ,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
        ,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
        ,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
        ,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
        ,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
        ,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
        ,* FROM ccCallsIn with (nolock) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
    GROUP BY timegroup,inbound_id,dni_id)xDetailTime
    ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id = xDetailCount.dni_id))xComplete
    LEFT OUTER JOIN ccDnis on (xComplete.dni_id = ccdnis.dni_id)
    LEFT OUTER JOIN ccInbound ON (xComplete.inbound_id = ccInbound.inbound_id)
    WHERE timegroup>=@from AND timegroup<@to
    AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
    AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
    AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
    AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
    and ccdnis.dni_numero = ''01900''
    ORDER BY timegroup,inbound_id

end'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepInCalls se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepInCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off
set ANSI_WARNINGS off

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
    select @to = getdate()



if @action = 1
begin

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

IF OBJECT_ID(''tempdb..#callsin'') IS NOT NULL drop table #callsin
IF OBJECT_ID(''tempdb..#callsin2'') IS NOT NULL drop table #callsin2
IF OBJECT_ID(''tempdb..#agentInformation'') IS NOT NULL drop table #agentInformation
IF OBJECT_ID(''tempdb..#ccGenInSpec'') IS NOT NULL drop table #ccGenInSpec
IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL drop table #timeDetailAgent
IF OBJECT_ID(''tempdb..#timeDetailAgent2'') IS NOT NULL drop table #timeDetailAgent2

create table [#callsin](
row int identity,
dateStartDetail datetime,
dateEndDetail datetime,
timegroup datetime,
timegroup_next datetime,
time_endque datetime,
time_ring datetime,
time_dialog datetime,
time_notes datetime,
time_end_call datetime,
phone_in varchar(30),
cal_id int,
dni_id int,
Inbound_id int,
User_id int,
ntotal int,
ninitial int,
nout_hour int,
nout_service int,
nabnd int,
nno_agent int,
nque int,
ntimeout int,
noverflow int,
nxfer int,
nxfer_que int,
nabnd_xfer int,
nabnd_ring int,
nno_answer int,
nabnd_dialog int,
nanswer int,
nlost int,
nmsg int,
nabnd_tres int,
nansw_tres int,
tque_max int,
tque int,
txfer int,
tdialog int,
tnotes int,
tring int,
tresp int,
nMoh int,
nWHag int,
nWHcl int)

CREATE TABLE [dbo].[#ccGenInSpec](
[timegroup] [datetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[pos_tot] [smallint] NOT NULL,
[pos_time] [int] NOT NULL,
[pos_efect] [smallint] NOT NULL
) ON [PRIMARY]

------ Time Agent In ----------
insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
SELECT cal_inicio as dateStartDetail
    ,dateadd(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),cal_inicio) as dateEndDetail
    ,dbo.GetTimeGroup(cal_inicio,0)  as timegroup
    ,dbo.GetTimeGroup(dateadd(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),cal_inicio),1)   as timegroup_next  
    ,DATEADD(ss,isnull(cal_twait,0),cal_inicio) as time_endque
    ,DATEADD(ss,isnull(cal_twait + cal_txfer,0),cal_inicio) as time_ring
    ,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring,0),cal_inicio) as time_dialog
    ,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog,0),cal_inicio) as time_notes
    ,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),cal_inicio) as time_end_call
    ,isnull(cal_Ani,0) as phone_in,cal_id,cin.dni_id,Inbound_id,[User_id]
    ,1 AS ntotal
    ,ISNULL(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END,0) AS ninitial
    ,ISNULL(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END,0) AS nout_hour
    ,ISNULL(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END,0) AS nout_service
    ,ISNULL(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END,0) AS nabnd
    ,ISNULL(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END,0) AS nno_agent
    ,ISNULL(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END,0) AS nque
    ,ISNULL(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END,0) AS ntimeout
    ,ISNULL(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END,0) AS noverflow
    ,ISNULL(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END,0) AS nxfer
    ,ISNULL(CASE WHEN(cal_que>0 and statuscall_id in(11,15,13,16) ) OR (statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')    THEN 1 ELSE NULL END,0) AS nxfer_que
    ,ISNULL(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END,0) AS nabnd_xfer
    ,ISNULL(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END,0) AS nabnd_ring
    ,ISNULL(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END,0) AS nno_answer
    ,ISNULL(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END,0) AS nabnd_dialog
    ,ISNULL(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END,0) AS nanswer
    ,ISNULL(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END,0) AS nlost
    ,ISNULL(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END,0) AS nmsg
    ,ISNULL(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END,0) AS nabnd_tres
    ,ISNULL(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END,0) AS nansw_tres
    ,ISNULL(cal_twait,0)AS tque_max,ISNULL(cal_twait,0)AS tque,ISNULL(cal_txfer,0)AS txfer
    ,ISNULL(cal_tdialog,0)AS tdialog,ISNULL(cal_tnotas,0)AS tnotes,ISNULL(cal_tring,0)AS tring
    ,ISNULL(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END,0)AS tresp
    ,ISNULL(case when cal_tMoh>0 then 1 else 0 end,0)as nMoh
    ,ISNULL(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END,0)as nWHag,ISNULL(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END,0)as nWHcl
    FROM ccCallsIn cin with (nolock)
    left join ccdnis dnis on dnis.dni_id = cin.dni_id
    WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0 

delete #callsin WHERE timegroup>=@from AND timegroup<@to AND INBOUND_ID>0
AND ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0

select * into #callsin2 from #callsin where datediff(mi,timegroup,timegroup_next)>15

delete #callsin where datediff(mi,timegroup,timegroup_next) > 15

insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
select
    dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next
    ,time_endque,time_ring,time_dialog,time_notes,time_end_call
    ,phone_in,cal_id,t.dni_id,Inbound_id,[User_id]
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ninitial else 0 end as ninitial
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_hour else 0 end as nout_hour
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_service else 0 end as nout_service
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd else 0 end as nabnd
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nque else 0 end as nque
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntimeout else 0 end as ntimeout
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then noverflow else 0 end as noverflow
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer_que else 0 end as nxfer_que
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nmsg else 0 end as nmsg
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_tres else 0 end as nabnd_tres
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nansw_tres else 0 end as nansw_tres
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then tque_max else 0 end as tque_max
    ,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,time_endque) as tque
    ,dbo.TimeInterval(th.start ,th.stop, time_endque,time_ring) as txfer
    ,dbo.TimeInterval(th.start ,th.stop, time_dialog,time_notes) as tdialog
    ,dbo.TimeInterval(th.start ,th.stop, time_notes,time_end_call) as tnotes
    ,dbo.TimeInterval(th.start ,th.stop, time_ring,time_dialog) as tring
    ,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tresp,dateStartDetail)) as tresp    
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
    ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
    from #callsin2 t
    join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
    left join ccdnis dnis on dnis.dni_id = t.dni_id
    where  datediff(ss,th.start,timegroup_next)>0
    and th.start between @from and @to
    order by cal_id

------------ Session Time Start ----------------


------ Time Agent Common ----------

select DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0) AS timegroup,
dbo.GetTimeGroup(fecha,1) as timegroup_next
        ,[User_id]
        ,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE 0 END),0) AS tunknown
        ,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE 0 END),0) AS tnot_av
        ,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE 0 END),0) AS tav
        ,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE 0 END),0) AS tprob
        ,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE 0 END),0) AS tother
        ,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
        into #timeDetailAgent
    from ccLogAgentesDia
    WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
    GROUP BY
    dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0), 
    dbo.GetTimeGroup(fecha,1), [User_id]    
        
select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15

delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother)
select
    dateStartDetail, dateEndDetail,th.start as timegroup,th.stop as timegroup_next, [User_id]
    ,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tunknown,dateStartDetail)) as tunknown
    ,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tnot_av,dateStartDetail)) as tnot_av
    ,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tav,dateStartDetail)) as tav2   
    ,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tprob,dateStartDetail)) as tprob
    ,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tother,dateStartDetail)) as tother2 
    ,isnull(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end,0) as nother
from #timeDetailAgent2 t
inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0
and th.start between @from and @to

;
with sessionTimeGroup as (

select session.timegroup, session.user_id
,isnull(sum(session.tlog),0) as tlog
from TmpSessionTimeGroup as session 
where login between @from and @to
group by session.timegroup,session.user_id
),
callin as (
select 
callin.timegroup,callin.user_id
,isnull(sum(callin.txfer),0) txfer,isnull(sum(callin.tdialog),0) tdialog,isnull(sum(callin.tnotes),0) tnotes
,isnull(sum(callin.tring),0) tring,isnull(sum(callin.nMoh),0) nMoh,isnull(sum(callin.nWHag),0) nWHag,isnull(sum(callin.nWHcl),0) nWHcl
from #callsin callin
group by callin.timegroup,callin.user_id
), timeAgent as(
select timeAgent.timegroup,timeAgent.user_id,isnull(sum(timeAgent.tnot_av),0) as tnot_av,isnull(sum(timeAgent.tav),0) tav
,isnull(sum(timeAgent.tprob),0) tprob, isnull(sum(timeAgent.tother),0) tother,isnull(sum(timeAgent.tunknown),0) tunknown
,isnull(sum(timeAgent.nother),0) nother
from #timeDetailAgent timeAgent
group by timeAgent.timegroup,timeAgent.user_id
)

select ROW_NUMBER() OVER(ORDER BY session.timegroup,session.[user_id] ) AS Row,
session.timegroup, session.user_id
,isnull(timeAgent.tnot_av,0) as tnot_av,isnull(timeAgent.tav,0) tav,isnull(timeAgent.tprob,0) tprob
,isnull(timeAgent.tother,0) tother,isnull(timeAgent.tunknown,0) tunknown,isnull(timeAgent.nother,0) nother
,isnull(callin.txfer,0) txfer,isnull(callin.tdialog,0) tdialog,isnull(callin.tnotes,0) tnotes
,isnull(callin.tring,0) tring,isnull(callin.nMoh,0) nMoh,isnull(callin.nWHag,0) nWHag,isnull(callin.nWHcl,0) nWHcl
,isnull(session.tlog,0) as tlog
into #agentInformation
from sessionTimeGroup as session 
left join timeAgent on timeAgent.User_id=session.user_id and timeAgent.timegroup=session.timegroup
left join callin on callin.User_id=session.user_id and session.timegroup=callin.timegroup
order by session.timegroup

INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
select timegroup, B.inbound_id
, COUNT(DISTINCT B.[user_id]) AS pos_max -- pos_tot
    ,SUM (tlog - (tnot_av + tprob + tother)) AS pos_time
    , COUNT(CASE WHEN (tlog- (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
from #agentInformation X
INNER JOIN ccInboundAgentes B ON X.[user_id] = B.[user_id]
WHERE timegroup >= @from AND timegroup < @to  
group by timegroup, B.inbound_id

--Borrar lo que esta para no repetir
delete from [RepInCalls] where date >= @from AND date < @to

;
with callsin as(
select timegroup as tg
    ,inbound_id as inboundId,   dni_id  
    ,ntotal, nxfer, nabnd as nabnd_que, nxfer_que,
    (ninitial + nout_service + nout_hour + nno_agent + ntimeout + noverflow ) nno_xfer , tque_max,
    tque, NULLIF(nque, 0) nque , nanswer, nno_answer , nlost,
        (nabnd_xfer) nabnd_xfer , nabnd_ring, nabnd_dialog
        --,0 as pos_tot, 0 as pos_time --completar      
        , (nansw_tres + nabnd_tres) AS SL_P_1 ,
        (nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2
        ,ISNULL(tque/ NULLIF(nque, 0), 0) as [avg]
        --,ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0) SL
        ,nMoh,  nWHag   ,nWHcl
        ,DATEPART(yyyy,timegroup) as [year]
        ,DATEPART(mm,timegroup) as [mounth]
        ,DATEPART(dd,timegroup) as [day]
        ,DATEPART(hh,timegroup) as [hour]
        ,DATEPART(mi,timegroup) as [minute]
        ,cal_id,phone_in    ,dateStartDetail
        FROM #callsin       
),
wgByAcd as(
    select max(IDWG) as IDWG,Inbound_id,descripcion from ccWgByAcdView
    group by Inbound_id,descripcion
)

insert into [RepInCalls]
select tg as date,inboundId,ccInbound.descripcion as  inbound
,xDetail.dni_id,isnull(ccDnis.dni_Descripcion,''S/DNIS'') as dnis
,wgByAcd.IDWG workgroupId,isnull(wgByAcd.descripcion,'''') workgroup,ccInbound.IDArea areaID,D.AreaName area
,ntotal,nxfer,nabnd_que,nxfer_que,nno_xfer,tque_max,tque,isnull(nque,0) as nque,nanswer
,nno_answer,nlost,nabnd_xfer,nabnd_ring,nabnd_dialog
,spec.pos_tot pos_tot,spec.pos_tot pos_time
,SL_P_1,SL_P_2,avg,ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0) SL
,nMoh,nWHag,nWHcl
,year,mounth,day,hour,minute,cal_id,phone_in,dateStartDetail,isnull(dni_numero,'''') as DniNumber
 from callsin xDetail
 INNER JOIN ccInbound ON xDetail.inboundId = ccInbound.inbound_id
 LEFT JOIN ccDnis ON xDetail.dni_id = ccDnis.dni_id
 INNER join wgByAcd on wgByAcd.Inbound_id=ccinbound.Inbound_id
 INNER JOIN ccriacat_areas D ON D.IDArea = ccInbound.IDArea
 inner join #ccGenInSpec spec on spec.timegroup=xDetail.tg and spec.inbound_id=xDetail.inboundId
 --order by tg


IF OBJECT_ID(''tempdb..#callsin'') IS NOT NULL drop table #callsin
IF OBJECT_ID(''tempdb..#callsin2'') IS NOT NULL drop table #callsin2
IF OBJECT_ID(''tempdb..#agentInformation'') IS NOT NULL drop table #agentInformation
IF OBJECT_ID(''tempdb..#ccGenInSpec'') IS NOT NULL drop table #ccGenInSpec
IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL drop table #timeDetailAgent
IF OBJECT_ID(''tempdb..#timeDetailAgent2'') IS NOT NULL drop table #timeDetailAgent2
end
'
    EXEC(@sql)


    
    set @process = 'DEV1-459 Alter SP ccspRepSpecialTimes se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepSpecialTimes] @action AS TINYINT
    ,@from AS DATETIME = NULL
    ,@to AS DATETIME = NULL
AS
IF @from IS NULL
    SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

SELECT @to = getdate()

IF @action = 1
BEGIN
    --Borrar lo que esta para no repetir
    DELETE
    FROM RepSpecialTimes
    WHERE DATE >= @from
        AND DATE < @to

    DECLARE @NotReady VARCHAR(max)

    SELECT TOP 1 @NotReady = descripcion
    FROM ccTipoNotReady
    ORDER BY tiponotready_id;

    WITH timeAgent
    AS (
        SELECT dateadd(mi, CASE WHEN datePart(mi, timeGroup) IN (15, 45) THEN - 15 ELSE 0 END, timeGroup) AS timeGroup
            ,camId
            ,camType
            ,CASE WHEN tipostatusage_id = 3 THEN ''Tiempo Disponible'' WHEN tipostatusage_id = 4 THEN ''Tiempo Dialogo'' WHEN tipostatusage_id = 2 THEN ''Tiempo No Disponible'' ELSE ''Otro'' END AS tDescripcion
            ,tStatus
            ,TipoStatusAge_id
            ,dateIni
            ,dateEnd
            ,dbo.AccountInterval(dateIni, dateEnd, timeGroup, timeGroupNext, 1) ntotal
        FROM tmpccLogAgentesDia
        WHERE tStatus > 0
        )
        ,times
    AS (
        SELECT C.cam_id
            ,0 AS inbound_id
            ,''Camp - '' + C.cam_descripcion AS [Espec/Camp]
            ,A.timegroup
            ,A.tDescripcion
            ,sum(tStatus) AS tStatus
        FROM timeAgent A
        INNER JOIN cccamps C ON A.camId = C.cam_id
            AND A.camType = 1
        GROUP BY C.cam_id
            ,C.cam_descripcion
            ,A.timeGroup
            ,A.tDescripcion
        
        UNION ALL
        
        SELECT 0 AS cam_id
            ,inbound_id
            ,''ACD - '' + C.descripcion AS [Espec/Camp]
            ,A.timegroup
            ,A.tDescripcion
            ,sum(tStatus) AS tStatus
        FROM timeAgent A
        INNER JOIN ccinbound C ON A.camId = C.inbound_id
            AND A.camType = 0
        GROUP BY C.inbound_id
            ,C.descripcion
            ,A.timeGroup
            ,A.tDescripcion
        )
        ,Report1
    AS (
        SELECT cam_id
            ,inbound_id
            ,[Espec/Camp]
            ,timegroup
            ,isnull([Tiempo Disponible], 0) + isnull([Tiempo Dialogo], 0) + isnull([Tiempo No Disponible], 0) + isnull([Otro], 0) AS [Tiempo Sesion]
            ,isnull([Tiempo Disponible], 0) AS [Tiempo Disponible]
            ,isnull([Tiempo Dialogo], 0) AS [Tiempo Dialogo]
            ,isnull([Tiempo No Disponible], 0) AS [Tiempo No Disponible]
            ,isnull([Otro], 0) AS [Otro]
        FROM times
        pivot(max(tstatus) FOR [tdescripcion] IN ([Tiempo Disponible], [Tiempo Dialogo], [Tiempo No Disponible], [Otro])) AS pvtTimes
        WHERE [Espec/Camp] IS NOT NULL
        )
        ,NotReadyTime
    AS (
        SELECT A.timeGroup
            ,B.TipoNotReady_id
            ,C.Descripcion
            ,A.tStatus
            ,A.camId
            ,A.camType
            ,A.ntotal
        FROM timeAgent A
        LEFT JOIN ccLogAgentesNotReady B ON A.dateEnd = B.fecha
        LEFT JOIN ccTipoNotReady c ON B.TipoNotReady_id = c.tiponotready_id
        WHERE TipoStatusAge_id = 2
        )
        ,notready
    AS (
        SELECT ''Camp - '' + cam_descripcion AS [Espec/Camp]
            ,A.timeGroup
            ,A.Descripcion AS [descriptionT]
            ,sum(A.tstatus) AS T
            ,A.Descripcion AS [descriptionN]
            ,sum(ntotal) AS N
        FROM NotReadyTime A
        LEFT JOIN cccamps b ON A.camId = b.cam_id
            AND A.camType = 1
        GROUP BY cam_descripcion
            ,timeGroup
            ,A.Descripcion
        
        UNION
        
        SELECT ''ACD - '' + b.descripcion AS [Espec/Camp]
            ,A.timeGroup
            ,A.Descripcion AS [descriptionT]
            ,sum(A.tstatus) AS T
            ,A.Descripcion AS [descriptionN]
            ,sum(ntotal) AS N
        FROM NotReadyTime A
        LEFT JOIN ccinbound b ON A.camId = b.Inbound_id
            AND A.camType = 0
        GROUP BY b.descripcion
            ,timeGroup
            ,A.Descripcion
        )

    INSERT INTO RepSpecialTimes
    SELECT a.timeGroup AS [date]
        ,a.cam_id AS [campaignId]
        ,a.inbound_id AS [inboundId]
        ,a.[Espec/Camp] AS [campACDDescription]
        ,[Tiempo Sesion] AS [sessionTime]
        ,[Tiempo Disponible] AS [readyTime]
        ,[Tiempo Dialogo] AS [dialogTime]
        ,[Tiempo No Disponible] AS [notReadyTime]
        ,[Otro] AS [other]
        ,descriptionN AS [descripcion]
        ,descriptionN + ''_Count'' AS [descripcion_count]
        ,[N] AS [count]
        ,b.descriptionT + ''_Time'' AS [descripcion_time]
        ,[T] AS [time]
        ,[T] AS [timeSeconds]
        ,datepart(yyyy, a.timeGroup) AS [year]
        ,datepart(mm, a.timeGroup) AS [month]
        ,datepart(dd, a.timeGroup) AS [day]
        ,datepart(hh, a.timeGroup) AS [hour]
        ,datepart(mi, a.timeGroup) AS [minutes]
    FROM Report1 a
    LEFT JOIN notready b ON (
            a.[Espec/Camp] = b.[Espec/Camp]
            AND a.timeGroup = b.timeGroup
            )
    WHERE b.timeGroup IS NOT NULL
    AND descriptionN IS NOT NULL
    
    UNION
    
    SELECT a.timeGroup
        ,a.cam_id
        ,a.inbound_id
        ,a.[Espec/Camp]
        ,[Tiempo Sesion] AS [Tiempo Sesion]
        ,[Tiempo Disponible] AS [Tiempo Disponible]
        ,[Tiempo Dialogo] AS [Tiempo Dialogo]
        ,[Tiempo No Disponible] AS [Tiempo No Disponible]
        ,[Otro] AS [Otro]
        ,@NotReady
        ,@NotReady + ''_Count''
        ,0
        ,@NotReady + ''_Time''
        ,''0''
        ,0
        ,datepart(yyyy, a.timeGroup) AS [year]
        ,datepart(mm, a.timeGroup) AS [month]
        ,datepart(dd, a.timeGroup) AS [day]
        ,datepart(hh, a.timeGroup) AS [hour]
        ,datepart(mi, a.timeGroup) AS [minutes]
    FROM Report1 a
    LEFT JOIN notready b ON (
            a.[Espec/Camp] = b.[Espec/Camp]
            AND a.timeGroup = b.timeGroup
            )
    WHERE b.timeGroup IS NULL
    ORDER BY a.[Espec/Camp]
        ,a.timeGroup
END
'
    EXEC(@sql)


 set @process = 'DEV1-459 Alter SP ReportsMasterProcessWIthOnlyGenerate se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ReportsMasterProcessWIthOnlyGenerate] @from AS DATETIME = NULL
,@to AS DATETIME = NULL
,@scheduleTime INT = 10
,@dateStart DATETIME = NULL
,@isAllReport tinyint =0 --0 Only table ReportHighUse,1  not in table ReportHighUse, 2 all 
AS
SET ANSI_WARNINGS OFF
SET NOCOUNT ON

DECLARE @i INT,@count INT
DECLARE @SQL nVARCHAR(4000)
DECLARE @name SYSNAME
DECLARE @descError NVARCHAR(max)
DECLARE @dateSP DATETIME

IF @from IS NULL
BEGIN
    SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))
END

IF @to IS NULL
BEGIN
    SET @to = getdate()
END

IF @dateStart IS NULL
BEGIN
    SET @dateStart = getdate()
END

exec ccSpCreateIndexReport

EXEC ccspTmpTimesInterval @from = @from ,@to = @to  ,@interval = 15 --Tabla TmpTimesInterval Temporal para tener Intervalos de 15 Minutos
EXEC ccspTmpSessionGeneral @from = @from    ,@to = @to              --Tabla tmpSessionGeneral para tener la sesiones de agentes
EXEC ccspTmpSessionTimeGroup @from = @from  ,@to = @to              --Tabla tmpSessionTimeGroup para dividir la sesion en intervalos de 15 Minutos
EXEC ccspTimesccLogAgentesDia @from = @from ,@to = @to              --Tabla tmpccLogAgentesDia tener los movimientos de los agentes
EXEC ccspTimesOutboundData @from = @from    ,@to = @to              --Tabla tmpTimesOutboundData para los tiempos de las llamadas de salida
EXEC ccspTimesInboundData @from = @from ,@to = @to                  --Tabla tmpTimesInboundData para los tiempos de las llamadas de entrada
exec ccspTmpTimesccLogtransfers @from = @from, @to = @to            --Tabla TmpTimesccLogtransfers para los tiempos de las llamadas que son trasferidas
exec ccsptmpTimesHoldIn @from = @from, @to = @to                    --Tabla tmpTimesHoldIn para los tiempos cuando se pone en hold en llamadas de entrada

CREATE TABLE #tmpProcedureReports (
    id INT
    ,name SYSNAME
    )

declare @tableSpDontProcess table(nameSp varchar(300) primary key not null)

insert into @tableSpDontProcess values(''ccspRepCatalogos'') -- ccspRepCatalogos es para catalogos por eso no se debe correr
insert into @tableSpDontProcess values(''ccspRepAgentSession'') -- ccspRepAgentSession Genera el reporte de sesiones para alimentar  
insert into @tableSpDontProcess values(''ccspRepAgentNotReadyDet'') -- ccspRepAgentNotReadyDet sabemos cuando inicia y cuando termina los no disponibles 
insert into @tableSpDontProcess values(''ccspRepAgentNotReady'') -- ccspRepAgentNotReady Agrupa por hora
insert into @tableSpDontProcess values(''ccspRepAgentGI'')      -- ccspRepAgentGI Agrupa por hora


if @isAllReport =0 begin

    INSERT INTO #tmpProcedureReports
    SELECT ROW_NUMBER() OVER (
            ORDER BY [name]
            ) AS id
        ,[name]
    FROM sys.procedures
    WHERE [name] LIKE ''ccspRep%''  
        AND [name] NOT IN (select nameSp from @tableSpDontProcess)
        AND [name] IN (select nameSp from ReportHighUse)        
end
else if @isAllReport =1 begin
    INSERT INTO #tmpProcedureReports
    SELECT ROW_NUMBER() OVER (
            ORDER BY [name]
            ) AS id
        ,[name]
    FROM sys.procedures
    WHERE [name] LIKE ''ccspRep%''
        AND [name] NOT IN (select nameSp from @tableSpDontProcess)
        AND [name] Not IN (select nameSp from ReportHighUse)        
end
else begin
    INSERT INTO #tmpProcedureReports
    SELECT ROW_NUMBER() OVER (
            ORDER BY [name]
            ) AS id
        ,[name]
    FROM sys.procedures
    WHERE [name] LIKE ''ccspRep%''
        AND [name] NOT IN (select nameSp from @tableSpDontProcess)        
end


exec ccspRepAgentSession @action=1,@from=@from,@to=@to --Saca el detalle de las sesiones
exec ccspRepAgentNotReadyDet @action=1,@from=@from,@to=@to --Saca el detalle de los no disponibles
exec ccspRepAgentNotReady @action=1,@from=@from,@to=@to --Agrupa a los no disponibles por hora
exec ccspRepAgentGI @action=1,@from=@from,@to=@to   --Agrupa por 15 minutos

INSERT INTO [logsReportsMaster] (name,STATUS,dateStart,dateEnd,error,maxTime)
SELECT name,0 [status]  ,''19000101'' as dateStart,''19000101'' dateEnd,'''' error,@scheduleTime
FROM #tmpProcedureReports

SELECT @i = 1, @count = count(*) FROM #tmpProcedureReports

WHILE @i <= @count  
BEGIN
    SELECT @name = name
    FROM #tmpProcedureReports
    WHERE id = @i

    SET @sql = ''EXEC '' + @name + '' @action=1, @from=@from, @to=@to''
    
    SET @dateSP = getdate()

    BEGIN TRY
        --print @sql
        
        exec sp_executesql @sql, N''@from DATETIME, @to DATETIME'',@from, @to

        UPDATE [logsReportsMaster]
        SET STATUS = 1
            ,dateStart = @dateSP
            ,dateEnd = getdate()
        WHERE name = @name
            AND STATUS = 0
            AND dateStart = ''19000101''
            AND dateEnd = ''19000101''
            
    END TRY

    BEGIN CATCH
        SELECT @descError = ''Line: '' + cast(error_line() AS NVARCHAR) + '' Number: '' + cast(@@error AS NVARCHAR) + '' Message: '' + error_message()

        SELECT @descError,@name

        UPDATE [logsReportsMaster]
        SET STATUS = 3
            ,dateStart = @dateSP
            ,dateEnd = getdate()
            ,error = @descError
        WHERE name = @name
            AND STATUS = 0
            AND dateStart = ''19000101''
            AND dateEnd = ''19000101''
    END CATCH

    SET @i = @i + 1
END

DROP TABLE #tmpProcedureReports'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ReportsMasterProcessPublicationLowLoad se quita with index'
    set @sql='ALTER procedure [dbo].[ReportsMasterProcessPublicationLowLoad]
as

set nocount on

declare @replicationName varchar(max)
declare @i int,@count int


declare @jobName varchar(255),@duration int
set @duration=0
 
SELECT @jobName= j.name, @duration= DATEDIFF(ms,ja.start_execution_date,GETDATE()) 
    FROM msdb.dbo.sysjobactivity ja 
    LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
    JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
    WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
    AND start_execution_date is not null
    AND stop_execution_date is null
    AND j.name in (''ReportsMasterProcessPublicationLowLoad'')


IF @jobName is not null and @duration>2000
BEGIN
    print ''Process Active Job''
    SELECT @jobName AS job_name, @duration AS [Duration] 
    return(0)
END

print ''--------------- Get Jobs Replication ------------------------------''
create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
    select distinct A.[name], 0 as flag from msdb.dbo.sysjobs A 
    inner join PublicationLowLoad B on A.[name] like ''%''+B.namePublication+''%''  and (B.active is null or B.active=1)
    where A.[name] like ''%ccReportsRia- 0%'' and A.[name] like ''%CCenterRia%''    

select @count=count(*) from #replications

while exists(select * from #replications with(nolock) where flag = 0)
begin
    set rowcount 1
        select @replicationName = [name]
        from #replications with(nolock)
        where flag = 0
    set rowcount 0
    
    if (
        SELECT top 1 sjh.run_status
      FROM msdb.dbo.sysjobhistory                sjh  
      inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
      inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
      WHERE
      j.name = @replicationName
      order by sjh.instance_id desc     
    ) <>4 
    or not exists(SELECT top 1 sjh.run_status
      FROM msdb.dbo.sysjobhistory                sjh  
      inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
      inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
      WHERE
      j.name = @replicationName
      order by sjh.instance_id desc )
    
    begin
        exec msdb.dbo.sp_start_job @job_name = @replicationName
        print ''sp_start_job ''+@replicationName
    end
    else begin
        print ''Job is Init ''+@replicationName
    end

    update #replications with(rowlock)  set flag = 1    where [name] = @replicationName

    WAITFOR DELAY ''00:00:03''      

    while (
        SELECT top 1 sjh.run_status
      FROM msdb.dbo.sysjobhistory                sjh  
      inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
      inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
      WHERE
      j.name = @replicationName
      order by sjh.instance_id desc     
    ) = 4
    begin   
        WAITFOR DELAY ''00:00:01''
        print ''In Progress Job in ReplicationName: ''+@replicationName
        
    end
    print ''Progress End Job in ReplicationName: ''+@replicationName
end

drop table #replications
'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ReportsMasterSubProcess se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ReportsMasterSubProcess]               
AS

BEGIN   
SET NOCOUNT ON;

DECLARE @from DATETIME = NULL
DECLARE @to DATETIME = NULL
DECLARE @dateStart DATETIME = NULL
DECLARE @scheduleTime int = 10


-- Insert statements for procedure here
PRINT ''--------------------------- Creacion tablas cada domingo ---------------------------''

DECLARE @isSunday TINYINT,  @hourSunday TINYINT,@minSunday TINYINT

SELECT @isSunday = DATEPART(dw, GETDATE()),@hourSunday = DATEPART(hh, getdate()), @minSunday = DATEPART(mi, GETDATE())

IF @isSunday=1 AND @hourSunday = 3 AND @minSunday>=30 

BEGIN

    IF EXISTS (SELECT * FROM sys.tables WHERE name = ''logsReportsMaster'') 
    BEGIN
        DROP TABLE logsReportsMaster
    END

    CREATE TABLE [logsReportsMaster](
        [id] INT IDENTITY not null PRIMARY KEY,
        [name] VARCHAR(100) not null,
        [status] TINYINT not null,
        [dateStart] DATETIME not null,
        [dateEnd] DATETIME not null,
        [error] VARCHAR(max) not null,
        [maxTime] INT not null)

    CREATE NONCLUSTERED INDEX [IX_logsReportsMaster1] ON [dbo].[logsReportsMaster]
    (
        [name] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

    CREATE NONCLUSTERED INDEX [IX_logsReportsMaster2] ON [dbo].[logsReportsMaster]
    (
    [status] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

    CREATE NONCLUSTERED INDEX [IX_logsReportsMaster3] ON [dbo].[logsReportsMaster]
    (
    [maxTime] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

END

PRINT ''--------------------------- Termina Creacion tablas cada domingo ---------------------------''

PRINT ''EXEC ReportsMasterProcessWIthOnlyGenerate @from=''+CAST(@from as varchar)+'',@to=''+CAST(@to as varchar)+'',@scheduleTime=''+CAST(@scheduleTime as varchar)+'',@dateStart=''+CAST(@dateStart as varchar)

EXEC ReportsMasterProcessWIthOnlyGenerate @from=@from,@to=@to,@scheduleTime=@scheduleTime,@dateStart=@dateStart 

END'
    EXEC(@sql)   

    set @process = 'DEV1-459 alter SP ccspRepDetailAgent se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepDetailAgent]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET NOCOUNT ON

declare @califout int , @califin int
declare @var varchar(100)

BEGIN
SET ANSI_WARNINGS off
SET NOCOUNT ON

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
    select @to =getdate()

if @action=1 begin

    
set @califout =1
set @califin =1

select @var= valor from ccsettings where setting_id = 39
select @califout = Value from dbo.fn_RIASplitDelimited(@var,''|'') where Id=1
select @califin =  Value from dbo.fn_RIASplitDelimited(@var,''|'') where Id=2

delete from RepDetailAgent where date>=@from and date<@to

 ;with notReady as(
 select A.date,A.userId,SUM(A.timeSeconds) as tnot_av
 from RepAgentNotReady A 
 where A.date between @from and @to
 group by A.date,A.userId
 ) , AgentSession as (
 select A.userId,A.login as [user],A.[user] as [userName]
 ,convert(datetime,convert(varchar(14),A.date,121)+''00:00'',121) as [date]
 ,sum(A.sessionTime) as sessionTime
 from RepAgentSessionByInterval A
 where A.date between @from and @to
 group by A.userId,A.login ,A.[user],convert(datetime,convert(varchar(14),A.date,121)+''00:00'',121)
 ), callDataOut as(
 select convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121) as [date]
 ,A.User_id as UserId,sum(A.txfer) as txfer,sum(A.tring) as tring  ,sum(A.tdialog) as tdialog
 ,sum(A.tnotes) as tnotes, SUM(ntotal) as ntotal
 ,count(case when A.calif_id = @califout then 1 else null end) as completeOut --Revisar el calificacionId
 from tmpTimesOutboundData A
 where A.cal_manual in(0,2)
 group by convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121),A.User_id
 ), callDataIn as(
 select convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121) as [date]
 ,A.User_id as UserId,sum(A.txfer) as txfer,sum(A.tring) as tring  ,sum(A.tdialog) as tdialog
 ,sum(A.tnotes) as tnotes, SUM(ntotal) as ntotal
 ,count(case when A.calif_id = @califin then 1 else null end) as completeIn --Revisar el calificacionId
 from tmpTimesInboundData A
 group by convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121),A.User_id
 ),timeAgent as(  
 select convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121) as [date]
 ,userId,
 sum(case when TipoStatusAge_id =3 then tStatus else 0 end) tav 
 from tmpccLogAgentesDia A
where TipoStatusAge_id>0
group by convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121),userId
 )
 , callData as(   
 select isnull(callOut.date,callIn.date) as [date],isnull(callOut.userId,callIn.UserId) as UserId
 ,isnull(callOut.txfer,0) +isnull(callIn.txfer,0) as txfer
 ,isnull(callOut.tring,0) +isnull(callIn.tring,0) as tring
 ,isnull(callOut.tdialog,0) +isnull(callIn.tdialog,0) as tdialog
 ,isnull(callOut.tnotes,0) +isnull(callIn.tnotes,0) as tnotes
 ,isnull(callOut.ntotal,0)+isnull(callIn.ntotal,0) as ntotal 
 ,isnull(callOut.completeOut,0)+isnull(callIn.completeIn,0) as  [complete]
 from callDataOut callOut
 full outer join callDataIn callIn on callOut.[date]=callIn.[date] and callOut.UserId=callIn.userId
 )

 insert into RepDetailAgent
 select A.userId,A.[user],A.userName,A.[date],A.sessionTime
 ,A.sessionTime - isnull(B.tnot_av,0) as [activeTime]
 ,isnull(C.txfer+C.tring+C.tdialog+C.tnotes,0) as [talkingtTime]
 ,isnull(C.txfer+C.tring,0) as [holdTime]
 ,isnull(B.tnot_av,0) as [unavaibleTime]
 ,convert ( decimal(18,3),  isnull(C.tdialog*1.0 ,0)/36.0 ) as [talkingPercent]
 ,convert ( decimal(18,3),  isnull((C.txfer+C.tring)*1.0 ,0)/36.0 ) as [waitpercent]
 ,convert ( decimal(18,3), isnull(t.tav *1.0,0) /36.0 ) as [readyPercent]
 ,convert ( decimal(10,3), ( (1.0*A.sessionTime)-( isnull(B.tnot_av,0) ))/A.sessionTime  ) as [adherencia]
 ,isnull(C.ntotal,0) as [totalCalls]
 ,isnull(C.ntotal,0)  as [callsByHour]
 ,isnull(C.[complete],0) as  [complete]
 ,convert(decimal(10,4),  (isnull(C.[complete]*1.0,0) )/7.0) as  [completeByHour] --se va ocultar en la interfaz
 ,case when C.ntotal=0 or C.ntotal is null then 0.0000
    else convert(decimal(10,4), isnull( ( C.[complete]*1.0)/ C.ntotal,0) )  end as [percentComplete]
 ,datepart(YYYY,A.[date]) [year]
,datepart(MM,A.[date]) [month]
,datepart(DD,A.[date]) [day]
,datepart(HH,A.[date]) [hour]
,0 [minutes]
 from AgentSession A 
 left join notReady B on A.date=B.date and A.userId=B.userId
 left join callData C on A.date=C.date and A.userId=C.userId 
 left join timeAgent t on A.date=t.date and A.userId=t.userId
 order by A.[date]
        
    
end
END'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepInAbnd se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepInAbnd]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()
    

    SELECT [date], areaId, CAST('''' as varchar(50)) area, 0 workgroupId, CAST('''' as varchar(50)) workgroup, inbound_id, isnull(inbound,'''') inbound, amount, time_max,
        time_tot, LT10, LT20, LT30, LT40, LT50, LT60, LT120, LT180, LT240, LT300, GT300, [year], [month], [day], [hour], [minutes]
    INTO #AbndData
    FROM
    (SELECT timegroup [date]
        , IDArea areaId
        , xCalls.inbound_id, descripcion inbound
        , COUNT(cal_inicio) AS amount
        , MAX(tAbnd) AS time_max
        , SUM(tAbnd) AS time_tot
        , COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [LT10]
        , COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [LT20]
        , COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [LT30]
        , COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [LT40]
        , COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [LT50]
        , COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [LT60]
        , COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [LT120]
        , COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [LT180]
        , COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [LT240]
        , COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [LT300]
        , COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [GT300]
        , datepart(yyyy,timegroup) [year], datepart(mm,timegroup) [month], datepart(dd,timegroup) [day]
        , datepart(hh,timegroup) [hour], datepart(mi,timegroup) [minutes]
     FROM   (
            SELECT start timegroup
                , cal_inicio
                , inbound_id                
                , statuscall_id
                , (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
                , (cal_twait + cal_txfer + cal_tring) AS tAbnd
             FROM ccCallsIn ci with(nolock)
                JOIN TmpTimesInterval th on cal_inicio between Start and [Stop]
                WHERE cal_inicio >= @from AND  cal_inicio < @to
                AND INBOUND_ID > 0
        ) xCalls left join ccInbound Ib ON Ib.inbound_id=xCalls.inbound_id 
    WHERE (abnd IS NOT NULL) 
    GROUP BY timegroup, IDArea, xCalls.inbound_id, descripcion) Rep
    
    update #AbndData set
    [workgroupId] = b.idwg
    from #AbndData a, ccInboundAgentes b
    where a.inbound_id = b.inbound_id

    update #AbndData
    set workgroup = wgname, area = areaname
    from #AbndData a, ccriacat_workgroup b, ccriacat_areas c
    where a.[workgroupId] = b.idwg
    and a.areaId = c.idarea

    delete [RepInAbnd] with(rowlock)
    where [date] between @from and @to
    
    insert [RepInAbnd] select * from #AbndData
end'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ReportsMasterProcess'
    set @sql='ALTER procedure [dbo].[ReportsMasterProcess]
as

set nocount on

declare @replicationName varchar(max)
declare @SubProcessNameReports varchar(max)
declare @dateStart datetime, @dateSP datetime
declare @schedule_id int,@scheduleTime int
declare @isSunday tinyint,  @hourSunday tinyint,@minSunday tinyint

declare @sessionKIll table(id int, sessionId int)
declare @i int,@count int
declare @sessionId int
declare @SQL varchar(max)
declare @name sysname
declare @descError nvarchar(max)

set @dateStart = getdate()
set @scheduleTime = 15


declare @tableArticle table(nameArticle [sysname],objectId int)
declare @tableTrigger table(id int identity, nameArticle [sysname])

insert into @tableArticle(nameArticle,objectId)
SELECT Art.name nameArticle,t.object_id FROM dbo.sysmergepublications P
inner join dbo.sysmergearticles Art on Art.pubid=P.pubid
inner join sys.tables t on t.name=Art.name

insert into @tableTrigger
select t.name as nameTrigger from @tableArticle Art
inner join sys.triggers  t on Art.objectId=t.parent_id
where name not like ''MSmerge_%''

select @i=1,@count =count(*) from @tableTrigger
while @i<=@count
begin
    select @name = nameArticle  from @tableTrigger where id=@i
    set @sql =''DROP TRIGGER ''+ @name
    exec (@sql)
    set @i = @i+1
end

print ''--------------------------- DROP TRIGGER Tables ---------------------------''

print ''--------------- Get Jobs Replication ------------------------------''
create table #replications ([name] nvarchar(100), flag bit)

;

with jobNotStart as(
select distinct A.[name] from msdb.dbo.sysjobs A
    inner join PublicationLowLoad B on A.[name] like ''%''+B.namePublication+''%''
    where A.[name] like ''%CCReportsRIA- 0%'' and A.[name] like ''%CCenterRIA%''
-- union all
-- select distinct A.[name] from msdb.dbo.sysjobs A
--     inner join PublicationHighLoad B on A.[name] like ''%''+B.namePublication+''%''
--     where A.[name] like ''%CCReportsRIA- 0%'' and A.[name] like ''%CCenterRIA%''
)

insert into #replications
select distinct A.[name],0 from msdb.dbo.sysjobs A
    where A.[name] like ''%CCReportsRIA- 0%'' and A.[name] like ''%CCenterRIA%''
    and A.name not in(select name from jobNotStart)

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%CCReportsRIA- 0%'' and [name] like ''%CCRecorderRIA%'' order by [name]

select @count=count(*) from #replications

while(
select count(*) from #replications with(nolock) where flag = 0) > 0

begin
    set rowcount 1
        select @replicationName = [name]
        from #replications with(nolock)
        where flag = 0
    set rowcount 0

    if (
        SELECT top 1 sjh.run_status
        FROM msdb.dbo.sysjobhistory                sjh
        inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
        inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)
        WHERE
        j.name = @replicationName
        order by sjh.instance_id desc
    ) <>4
    or not exists(SELECT top 1 sjh.run_status
        FROM msdb.dbo.sysjobhistory                sjh
        inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
        inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)
        WHERE
        j.name = @replicationName
        order by sjh.instance_id desc   )

    begin
        exec msdb.dbo.sp_start_job @job_name = @replicationName
        print ''sp_start_job ''+@replicationName
    end
    else begin
        print ''Job is Init ''+@replicationName
    end

    update #replications with(rowlock)  set flag = 1    where [name] = @replicationName

    WAITFOR DELAY ''00:00:03''

    while (
        SELECT top 1 sjh.run_status
        FROM msdb.dbo.sysjobhistory                sjh
        inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
        inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)
        WHERE
        j.name = @replicationName
        order by sjh.instance_id desc
    ) = 4
    begin
        WAITFOR DELAY ''00:00:01''
        print ''In Progress Job in ReplicationName: ''+@replicationName
        if datediff(ss,@dateStart,getdate())>((@scheduleTime*60)/@count) begin
            print ''Stop Job in ReplicationName: ''+@replicationName
            break
        end
    end
    print ''Progress End Job in ReplicationName: ''+@replicationName
end

drop table #replications



insert into RIA_FORMATOCONCEPTO
SELECT
t.id_formato AS ''ID Formato'', c.id_concepto as ''id concepto''
FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato, nombre, MAX(version) as version
                        FROM RIA_FORMATOS
                        WHERE activo = 1
                        group by id_formato, nombre) as t
ON f.id_formato = t.id_formato AND f.version = t.version inner join RIA_CONCEPTOS c
on t.id_formato = c.id_formato and t.version = c.version

left join RIA_FORMATOCONCEPTO as a on a.templateId = t.id_formato  and a.sectionId = c.id_concepto
where a.id is null

print ''---#reinitmergepullsubscription----''
declare @lastTenMinuteFirst datetime
declare @id int
declare @publisher_reinit nvarchar(max)
declare @publisher_db_reinit nvarchar(max)
declare @publication_reinit nvarchar(max)
declare @upload_first_reinit nvarchar(max)

set @lastTenMinuteFirst = dateadd(minute,-@scheduleTime*2,getdate())

create table #reinitmergepullsubscription(
id int not null identity,
publisher nvarchar(max) not null,
publisher_db nvarchar(max)not null,
publication nvarchar(max) not null,
upload_first nvarchar(max) not null,
[status] bit not null
)

insert into #reinitmergepullsubscription
select distinct s.name, ma.publisher_db, ma.publication, ''false'', 0
from distribution.dbo.MSmerge_history mh
left outer join distribution.dbo.MSrepl_errors me
on (mh.error_id = me.id)
left outer join distribution.dbo.MSmerge_agents ma
on (mh.agent_id = ma.id)
left outer join master.sys.servers s
on (ma.publisher_id = s.server_id)
where
(mh.comments like ''%You must reinitialize the subscription (without upload)%'' or
mh.comments like  ''%The Merge Agent failed because the schema of the article at the Publisher does not match the schema of the article at the Subscriber%'')
and mh.time >= @lastTenMinuteFirst
and ma.subscriber_db = ''CCReportsRIA''

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
    begin
        set rowcount 1
        select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first
        from #reinitmergepullsubscription
        where [status] = 0
        set rowcount 0

        exec sp_reinitmergepullsubscription  @publisher = @publisher_reinit,    @puSblisher_db = @publisher_db_reinit,    @publication = @publication_reinit,    @upload_first = @upload_first_reinit

        update #reinitmergepullsubscription
        set [status] = 1
        where id = @id
    end

drop table #reinitmergepullsubscription

        

print ''--------------------------- Comienzo de subprocesos de reportes ---------------------------''


PRINT ''EXEC ReportsMasterSubProcess''
EXEC ReportsMasterSubProcess
'
    EXEC(@sql)

   
	---------------------------------------End Jesus Gallardo hotfix/125.20231211.0.6---------------------------------------------------------

    ---------------------------------------Begin Jesus Gallardo hotfix/125.20231211.0.7---------------------------------------------------------

set @process = 'CW-8302 Alter SP ccspRepAnsweredCallsByDialingRetries Se agrega with(nolock)'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepAnsweredCallsByDialingRetries]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
    select @to = getdate()

if @action = 1
begin   
    --Borrar lo que esta para no repetir
    delete from RepAnsweredCallsByDialingRetries where date >= @from and date < @to

    ;
    with logExtension as(
        select user_id,max(Extension) ext from ccLogLogin where fecha between @from and @to
        group by user_id
    )

    INSERT INTO RepAnsweredCallsByDialingRetries
    select
    A.cal_Inicio as [date],
    A.cal_id as [calId],
    A.cal_telefono as [telephone],
    isnull(B.tipoResDial_id,0) as [dialResultId],
    isnull(resDial.descripcion,''N/A'') as [dialResult],
    isnull(C.cal_intentos,0) as [tries],
    A.cam_id as [campaignId],
    E.cam_descripcion as [campaign],
    A.User_id as [userId],
    ISnull(D.Nombres + '' '' + D.ApellidoPaterno + '' '' + D.ApellidoMaterno,''systemTranslated_NoName'') as [agentName],
    isnull(logExtension.ext ,'''') as [extension],
    convert(varchar(12),A.cal_Inicio,108) as [startHour],
    convert(varchar(12),dateadd(ss,A.cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,A.cal_Inicio),108) as [endHour],
    cal_tDialog as [dialogTime],
    isnull(A.calif_id,0) as [dispositionId],
    isnull(A.califSub_id,0) as [subDispositionId],
    isnull(disp.Description,''systemTranslated_Dispositionless'') as [disposition],
    isnull(subDisp.califSubDesc,''systemTranslated_NoSubDisposition'') as [subDisposition],
    A.cal_tNotas as [wrapup],
    datepart(yyyy,cal_Inicio) AS [year],
    datepart(mm,cal_Inicio) as [month],
    datepart(dd,cal_Inicio) as [day],
    datepart(hh,cal_Inicio) as [hour],
    datepart(mi,cal_Inicio) as [minutes]
    from ccoCallsOut A with(nolock)
    left join ccoLogDials B with(nolock) on A.cal_id=B.cal_id
    left join ccoCallsOutSource C with(nolock) on C.callout_id=A.callout_id
    left join ccUserView D on A.User_id=D.User_id
    left join ccCamps E on A.cam_id=E.cam_id
    left join ccTipoCalifOUT disp On disp.calif_id=A.calif_id
    left join ccTipoCalifSubOUT subDisp On subDisp.califSub_id=A.califSub_id
    left join ccTipoResultadoDial resDial on resDial.tipoResDial_id=B.tipoResDial_id
    left join logExtension on logExtension.user_id=A.User_id

    where A.cal_Inicio >= @from
    and A.cal_Inicio < @to
    and A.cal_manual in(0,2)
    order by date
END'
    EXEC(@sql)

    set @process = 'CW-8302 update ReportsTotals empty id=4010'
    set @sql='update  ReportsTotals set totalColumns='''' where id=4010'
    EXEC(@sql)



    ---------------------------------------End Jesus Gallardo hotfix/125.20231211.0.7---------------------------------------------------------


    ---------------------------------------BEGIN Jesus Gallardo hotfix/125.20231211.0.9---------------------------------------------------------
    set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
    begin
    DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
    end'
EXEC(@sql)

    set @process = 'alter Table smsccoLogDial add Message'
    set @sql='if not exists(select * from sys.tables where name = N''smsccoLogDial'') begin
    CREATE TABLE [dbo].[smsccoLogDial](
    [logId] [bigint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
    [smsout_id] [int] NOT NULL,
    [cam_id] [int] NOT NULL,
    [phone] [varchar](32) NOT NULL,
    [smsDate] [datetime] NOT NULL,
    [registryClient] [varchar](60) NOT NULL,
    [SystemApiId] [varchar](100) NOT NULL,
    [statusSystemsId] [int] NOT NULL,
    [Bill] [float] NOT NULL,
    [ProviderId] [int] NOT NULL,
    [Message] [varchar](200) NULL
) 
end'
    EXEC(@sql)
 
    set @process = 'alter Table smsccoLogDial add Message'
    set @sql='if not exists (select * from sys.columns where name = N''Message'' and Object_ID = Object_ID(N''smsccoLogDial''))
begin
    alter Table smsccoLogDial add Message varchar(200) null
end
'
    EXEC(@sql)
 
set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
        begin
        ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
        end'
    EXEC(@sql)
    

    set @process = 'Dineria -- Add Column RepAgentKPI.callsAvgTimeCustom'
    set @sql='if not exists (select * from sys.columns where name = N''callsAvgTimeCustom'' and Object_ID = Object_ID(N''RepAgentKPI''))
begin
    ALTER TABLE RepAgentKPI ADD callsAvgTimeCustom [decimal](10, 0) NULL;
end'
    EXEC(@sql)

     set @process = 'DEV1-459 alter SP ccspRepAgentKPI se quita with index Add Column callsAvgTimeCustom'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepAgentKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS


SET NOCOUNT ON

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
    select @to = getdate()

if(@to = convert(datetime,convert(varchar(11),getdate(),121)+''03:00:00'',121)) AND @from = DATEADD(dd,-1,@to)
BEGIN   
    select @from = convert(datetime,convert(varchar(11),@from))
END

if @action = 1
begin
   delete RepAgentKPI with(rowlock) where date >= @from AND date < @to
    
    ;with callTemp as(  
    select  User_id, statusCall_id, cal_tDialog, convert(date, cal_Inicio, 121) as cal_Inicio, cal_whoHung, 0  as callType
    from ccoCallsOut with(nolock)
    where cal_inicio between @from and @to and cal_manual < 3
    union all
    select  User_id, statusCall_id, cal_tDialog, convert(date, cal_Inicio, 121) as cal_Inicio, cal_whoHung, 1 as callType
    from ccCallsIn with(nolock)
    where cal_inicio between @from and @to 
    ) 
    , Conteos as(
    select user_id, cal_Inicio, 1 Total, case callType when 1 then 1 else 0 end Cin, case callType when 0 then 1 else 0 end Cout,
    case when statusCall_id in (11,13,15,16,17) and cal_tDialog<10 then 1 else 0 end C10,
    case when statusCall_id in (11,13,15,16,17) and cal_tDialog<20 then 1 else 0 end C20,
    case when statusCall_id in (11,13,15,16,17) and cal_tDialog<30 then 1 else 0 end C30,
    cal_whoHung from callTemp
    ), logAgentDialogDistinct as(
    
    select distinct User_id,fecha_Calc_ms/1000.0 as fecha_Calc_ms,fecha_Dispo,fecha_Dialog
    from ccLogAgentesDia_Dialog 
    where fecha_Dialog between @from and @to     
    )
    , Trd as(   
    select  User_id, cast(AVG(fecha_Calc_ms) as decimal(10,0)) avg_fCalc
    , CONVERT(date,fecha_Dialog,121) as fecha_Dispo
    ,sum(fecha_Calc_ms) sum_fCalc
    from logAgentDialogDistinct with(nolock)
    where fecha_Dialog between @from and @to 
    group by User_id,CONVERT(date,fecha_Dialog,121)
    )
    , Snd as(
    select user_id, cal_Inicio, sum(Total) Total, sum(Cin) Cin, sum(Cout) Cout,
    sum(C10) C10, sum(C20) C20, sum(C30) C30, sum(cal_whoHung) cal_whoHung
    from Conteos group by user_id, cal_Inicio
    ), timeAgtDontDialog as(
    select A.User_id,convert(date,fecha) date
    ,sum(case when A.TipoStatusAge_id not in(0,4,5,6,9,37) then tStatus else 0 end) tDontDialog 
    ,sum(case when A.TipoStatusAge_id in(3,31) then tStatus else 0 end) tready
    from ccLogAgentesDia A with(nolock)
    where fecha between @from and @to
    group by A.User_id,convert(date,fecha)
    
    )


    insert into RepAgentKPI
    select Snd.cal_Inicio,Fst.Login as login , Fst.user_id as [userId]
    ,Nombres + isnull('' ''+ApellidoPaterno, '''') + isnull('' ''+ApellidoMaterno, '''') as [user]
    ,Total as totalCalls, Cin as callsIn
    ,Cout as callsOut, C10 as [finishedCalls10], C20 as [finishedCalls20], C30 as [finishedCalls30], cal_whoHung as whoHung
    ,isnull(avg_fCalc, 0) as callsAvgTime
    ,datepart(yyyy,Snd.cal_Inicio) [year]
    ,datepart(mm,Snd.cal_Inicio) [mounth]
    ,datepart(dd,Snd.cal_Inicio) [day]
    ,0 as [hour]
    ,0 as [minute]
    ,convert(decimal(10,0),agtTime.tDontDialog/Total) as [callsAvgTimeCustom]   
    from Snd
    inner join ccUserView Fst on Fst.User_id = Snd.User_id
    left join Trd on Trd.User_id=Snd.User_id and Trd.fecha_Dispo=Snd.cal_Inicio
    left join timeAgtDontDialog agtTime on agtTime.User_id=Snd.User_id and agtTime.date=Snd.cal_Inicio
    order by cal_Inicio

    

end'
    EXEC(@sql)

  
    ---------------------------------------BEGIN Jesus Gallardo hotfix/125.20231211.0.11---------------------------------------------------------

    
  set @process = 'DEV1-459 Alter SP ccspRepOutDialDetail se quita with index'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepOutDialDetail] 

@action AS TINYINT, 
@from AS   DATETIME = NULL, 
@to AS     DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
    SELECT @from =CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE())) - 15
if @to is null
    SELECT @to = GETDATE()

IF @action = 1
BEGIN  

DECLARE @country SMALLINT
SELECT @country = valor
FROM ccSettings
WHERE setting_id = 104

--Borrar lo que esta para no repetir          
DELETE FROM RepOutDialDetail WHERE date >= @from AND date < @to
        
    IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
    IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
    IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;

    create table #dials (
    logDial_id  int not null,
    callout_id  int not null,
    cam_id  smallint not null,
    tipoResDial_id  int not null,
    resultDialDesc  varchar(60) not null,
    Telefono    varchar(32) not null,
    Puerto  smallint not null,
    fecha   datetime not null,
    tDialing    smallint not null,
    dialType    varchar(50) not null,
    tBusy   smallint  not null,
    answerbit   bit not null,
    canceledNoAgents    bit not null,
    cal_id  int null,
    disconnectCause varchar(250) not null,
    cal_key varchar(40) not null,
    file_moved  varchar(100)  null,
    tipoLlamada_id  smallint null,
    CallDisposition varchar(150) null,
    califSubDesc    varchar(150) null,
    codeSip varchar(10) not null,
    TipoTel varchar(30)  not null,
    tpreview    smallint not null,
    UserID  smallint null,
    )

    if exists(select *  from DC_Extra) begin
    CREATE NONCLUSTERED INDEX IX_dials_Tmp1 ON #dials ([codeSip])INCLUDE ([disconnectCause])
    end
    
    create table #relationCodeSip(
    codeSip int not null,
    disconnectCause varchar(250),
    description varchar(250)
    )

    insert into #dials
    SELECT  dial.logDial_id
        ,dial.callout_id
        ,dial.cam_id
        ,CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id
        ,ISNULL(tr.descripcion ,'''') as resultDialDesc
        ,dial.Telefono
        ,dial.Puerto
        ,dial.fecha
        ,dial.tDialing
        ,CASE WHEN dial.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview'' 
              WHEN LEFT(dial.TipoDialingMode, 1) = ''1'' THEN ''systemTranslated_Assisted'' 
              WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto'' 
              WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' END AS dialType            
        ,dial.tBusy
        ,dial.answerbit
        ,dial.canceledNoAgents
        ,dial.cal_id
        ,dial.disconnectCause
        ,isnull(co.cal_key,dial.cal_key) cal_key 
        ,case when co.file_moved=2 then ''systemTranslated_Remoto'' else ''Local'' end file_moved-- isnull(co.file_moved,0) as file_moved
        ,dial.tipoLlamada_id
        ,tco.[Description] AS CallDisposition
        ,tsco.califSubDesc
        ,CASE WHEN dial.disconnectCause <> '''' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '''' END codeSip
        ,case when @country<>1 then '''' WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
            WHEN dial.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' ELSE ''systemTranslated_Indefinite'' END TipoTel
        ,ISNULL(regp.tPreview,'''') as tpreview
        ,co.User_id as UserID   
    FROM ccoLogDials dial(NOLOCK)
    LEFT JOIN ccocallsout co(NOLOCK) ON dial.cal_id = co.cal_id
    LEFT JOIN cctipocalifout tco WITH (NOLOCK) ON tco.calif_id = co.calif_id
    LEFT JOIN cctipocalifsubout tsco WITH (NOLOCK) ON tsco.califSub_id = co.califSub_id
    LEFT JOIN RegProcessPreviewRecord regp WITH (NOLOCK) ON regp.callout_id = co.callout_id and regp.callId = co.cal_id
    LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dial.tipoResDial_id = tr.tiporesdial_id
    WHERE fecha >= @from AND fecha < @to

    if exists(select * from RegProcessPreviewRecord) begin

    insert into #dials
    select 
            0 as logDial_id 
            ,reg.callout_id
            ,ccoa.cam_id
            ,reg.process
            ,ISNULL(cctyp.translatedDesc,'''')
            ,ccoa.cal_telefono
            ,0 as Puerto
            ,reg.reg_date
            ,0 as tDialing
            ,''systemTranslated_Preview'' as dialType     
            ,0 as tBusy
            ,0 as answerbit
            ,0 as canceledNoAgents
            ,0 as cal_id
            ,'''' as disconnectCause
            ,ccoa.cal_Key
            ,''Local'' as file_moved 
            ,0 as tipoLlamada_id
            ,'''' as CallDisposition
            ,'''' as califSubDesc
            ,'''' as codeSip
            ,''systemTranslated_Indefinite'' as TipoTel
            ,reg.tPreview
            ,reg.userId 
    FROM RegProcessPreviewRecord reg(NOLOCK)
    left join ccoCallsOutSource ccoa (NOLOCK) ON reg.callout_id = ccoa.callout_id
    left join ccTypeProcessPreview cctyp (NOLOCK) ON  cctyp.typeProcess_id = reg.process
    WHERE reg.reg_date >= @from AND reg.reg_date < @to AND reg.process !=7
    
    end
    
    if exists(select *  from DC_Extra) begin
        ;with codeSips as (
            select distinct codeSip as codeSip,disconnectCause          
            from #dials where codeSip<>''''
        )   

        select cast(codeSip as int) as codeSip,disconnectCause 
        into #codeSip 
        from codeSips where IsNumeric(codeSip)=1
    
        insert into #relationCodeSip
        select A.codeSip,A.disconnectCause,B.description        
        from #codeSip A
        inner join DC_Extra B on A.codeSip=B.id

    end

--Inserta informacon de reporte  
    INSERT INTO RepOutDialDetail
        SELECT fecha as [date]
        ,case when dials.cal_key is null or  cs.cal_key is null then '''' when dials.cal_key is not null then dials.cal_key else cs.cal_key end cal_key
        ,telefono telephone
        ,dials.tiporesdial_id as tiporesdialId
        ,CASE WHEN dials.tipoResDial_id = 14 THEN ''systemTranslated_CancelledBySystem'' ELSE ISNULL(dials.resultDialDesc, '''') END AS dialResult
        ,dials.[cam_id] campaignId
        ,ISNULL(RTRIM(LTRIM(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') AS campaign
        ,dials.tbusy AS timeMessage
        ,DATEPART(yyyy, fecha) year 
        ,DATEPART(mm, fecha) month  
        ,DATEPART(dd, fecha) day    
        ,DATEPART(hh, fecha) hour   
        ,DATEPART(mi, fecha) minutes
        ,ISNULL(rl.name, '''') listName
        ,CASE WHEN answerbit = 1 THEN ''systemTranslated_Charged'' ELSE ''systemTranslated_NotCharged'' END AS billed
        ,ISNULL(cs.Dato1, '''') AS data1
        ,ISNULL(cs.Dato2, '''') AS data2
        ,ISNULL(cs.Dato3, '''') AS data3
        ,ISNULL(cs.Dato4, '''') AS data4
        ,ISNULL(cs.Dato5, '''') AS data5
        --,CASE WHEN dials.[file_moved] = 1 THEN ''systemTranslated_Remoto'' ELSE ''Local'' END AS fileMoved
        ,dials.[file_moved] AS fileMoved
        ,dials.disconnectCause
        ,COALESCE(dat.description, descripcion, ''N/A'') DCCustomer
        ,dials.dialType
        ,TipoTel
        ,ISNULL(CallDisposition, ''N/A'') AS CallDisposition
        ,ISNULL(califSubDesc, ''N/A'') AS CallSubDisposition
        ,ISNULL(csP.Dato6, '''') AS data6
        ,ISNULL(csP.Dato7, '''') AS data7
        ,ISNULL(csP.Dato8, '''') AS data8
        ,ISNULL(csP.Dato9, '''') AS data9
        ,ISNULL(csP.Dato10, '''') AS data10
        ,ISNULL(csP.Dato11, '''') AS data11
        ,ISNULL(csP.Dato12, '''') AS data12
        ,ISNULL(csP.Dato13, '''') AS data13
        ,ISNULL(csP.Dato14, '''') AS data14
        ,ISNULL(csP.Dato15, '''') AS data15
        ,dials.tpreview AS preview_Time
        ,ISNULL(us.Login,'''') as [login]
    FROM #dials as dials
    LEFT JOIN ccoCallsOutSource cs(NOLOCK) ON dials.callout_id = cs.callout_id
    LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dials.tiporesdial_id = tr.tiporesdial_id
    LEFT JOIN ccCamps camps(NOLOCK) ON camps.[cam_id] = dials.[cam_id]
    LEFT JOIN ccRIARegistryLists rl(NOLOCK) ON cs.list_id = rl.list_id
    LEFT JOIN #relationCodeSip dat ON dat.disconnectCause = dials.disconnectCause
    LEFT JOIN ccoCallsPreviewData csP ON (dials.cal_Key = csP.cal_Key AND dials.cam_id = csP.cam_id)
    LEFT JOIN ccUsers us (NOLOCK) ON  us.User_id = dials.UserID

    IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
    IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
    IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;
END'
    EXEC(@sql)


	set @process = 'Create View RepViewAgentGIUnion'
    set @sql='if exists (select * FROM sys.views where name = N''RepViewAgentGIUnion'')
    begin
	DROP VIEW [RepViewAgentGIUnion];
	end'
	EXEC(@sql)

	set @process = 'Create View RepViewAgentGIUnion'
    set @sql='if exists (select * FROM sys.views where name = N''RepViewSummary'')
    begin
	DROP VIEW [RepViewSummary];
	end'
	EXEC(@sql)


    set @process = 'Create View RepViewAgentGIUnion'
    set @sql='CREATE VIEW [dbo].[RepViewAgentGIUnion] AS
select [date],userId,[user],[login]
,sum(tlog) tlog
,sum(tunknown) tunknown
,sum(tav) tav
,sum(tnotav) tnotav
,sum(tother) tother
,sum(tprob) tprob
,sum(tChatting) tChatting
,sum(tundefined) tundefined
,sum(nxferin) nxferin
,sum(nanswerin) nanswerin
,sum(nabndxferin) nabndxferin
,sum(nabndringin) nabndringin
,sum(nabnddlgin) nabnddlgin
,sum(abndaxferin) abndaxferin
,sum(nnoanswerin) nnoanswerin
,sum(nlostin) nlostin
,sum(tdialogin) tdialogin
,sum(tnotesin) tnotesin
,sum(tringin) tringin
,sum(txferin) txferin
,sum(nxferout) nxferout
,sum(nanswerout) nanswerout
,sum(nabndxferout) nabndxferout
,sum(nabndringout) nabndringout
,sum(nabnddlgout) nabnddlgout
,sum(abndaxferout) abndaxferout
,sum(nnoanswerout) nnoanswerout
,sum(nlostout) nlostout
,sum(tdialogout) tdialogout
,sum(tnotesout) tnotesout
,sum(tringout) tringout
,sum(txferout) txferout
,sum(nother) nother
,sum(nmohin) nmohin
,sum(nmohout) nmohout
,sum(nwhagin) nwhagin
,sum(nwhagout) nwhagout
,sum(nwhcliin) nwhcliin
,sum(nwhcliout) nwhcliout
,[year],[month],[day],[hour],[minutes]
,0 tManual,0 tauxiliarready
from RepAgentGI_VersionOld
group by [date],userId,[user],[login],[year],[month],[day],[hour],[minutes]
union
select [date],userId,[user],[login]
,tlog
,tunknown
,tav
,tnotav
,tother
,tprob
,tChatting
,tundefined
,nxferin
,nanswerin
,nabndxferin
,nabndringin
,nabnddlgin
,abndaxferin
,nnoanswerin
,nlostin
,tdialogin
,tnotesin
,tringin
,txferin
,nxferout
,nanswerout
,nabndxferout
,nabndringout
,nabnddlgout
,abndaxferout
,nnoanswerout
,nlostout
,tdialogout
,tnotesout
,tringout
,txferout
,nother
,nmohin
,nmohout
,nwhagin
,nwhagout
,nwhcliin
,nwhcliout
,[year],[month],[day],[hour],[minutes]
,tManual
,0 tauxiliarready
from RepAgentGI
'
    EXEC(@sql)


    set @process = 'Create View RepViewSummary'
    set @sql='CREATE VIEW [dbo].[RepViewSummary] AS
select 
[date]
,[login]
,[user]
,sessionTime
,loginMktTime
,logoutMktTime
,0 callTengaged
,ndTime
,NCallsOut
,NCallsIn
,NCallsCorta
,NAtend
,NNoCalif
,Available
,0 avgCallTengaged
,twrapup
,userId
,0 TypeNotReady
,'''' descripcion
,''_Time'' descripcion_time
,0 [time]
,0 transferStatus
,0 ringingTime
,0 unknownStatus
,0 otherStatus
,0 failureStatus
,0 chatTengaged
,0 undefinedTime
,0 dialingStatus
--,null TipoReadyAuxiliarId
--,'' auxiliarRedy_descripcion
--,'' descripcion_auxiliarRedyTime_time
--,0 auxiliarRedyTime
from RepAgentSummary_VersionAmatech
union
select date
,login
,user
,sessionTime
,loginMktTime
,logoutMktTime
,callTengaged
,ndTime
,NCallsOut
,NCallsIn
,NCallsCorta
,NAtend
,NNoCalif
,Available
,avgCallTengaged
,twrapup
,userId
,TypeNotReady
,descripcion
,descripcion_time
,time
,transferStatus
,ringingTime
,unknownStatus
,otherStatus
,failureStatus
,chatTengaged
,undefinedTime
,dialingStatus
--,TipoReadyAuxiliarId
--,auxiliarRedy_descripcion
--,descripcion_auxiliarRedyTime_time
--,auxiliarRedyTime
from RepAgentSummary'
    EXEC(@sql)

    set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
    begin
    DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
    end'
EXEC(@sql)

    set @process = 'add ani to ccologdials'
    set @sql = 'IF COL_LENGTH(''dbo.ccologdials'', ''ani'') IS NULL
    BEGIN
        alter table ccologdials add ani varchar(32) null
    END'
    EXEC(@sql)
    
	set @process = 'alter SP ccspRepOutAnswAndXferCalls se corrige para que tome el ani de ccoLogDials'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = NULL

AS

SET NOCOUNT ON

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME,CONVERT(VARCHAR(11),GETDATE()))
IF @to IS NULL
    SELECT @to = GETDATE()

DECLARE @IVA INT
DECLARE @country AS TINYINT
SELECT @IVA = CONVERT(INT,ISNULL(valor,0)) FROM ccsettings WHERE setting_id = 25
SELECT @country = CONVERT(TINYINT,ISNULL(valor,1)) FROM ccsettings WHERE setting_id = 104

IF @country IS NULL SET @country = 1

IF @action = 1
BEGIN
--Borrar lo que esta para no repetir
DELETE FROM RepOutAnswAndXferCalls WHERE DATE >= @from AND DATE < @TO

declare @descriptionXfer varchar(100)

SELECT @descriptionXfer=[description] FROM dialType WHERE dialId = 3

;with ccld as(
    SELECT *, [dbo].[GetProveedor](Telefono, Puerto,tipoLlamada_id) AS proBIDs,tipoLlamada_id as CallType  FROM ccologdials
    WHERE fecha between @from and @to and answerbit = 1
)

INSERT INTO RepOutAnswAndXferCalls
SELECT COALESCE([Call].cal_inicio,ccld.fecha) AS [date],
    ISNULL(ccld.cal_id,0) AS [callid],
    ISNULL(ccld.cam_id,0) AS [campaignId],
    ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
    ISNULL([Call].user_id,0) AS [userId],
    ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') AS [Agent],
    dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg) AS [dialog],
    ccld.telefono AS [telephone],
    ISNULL(Call.cal_manual,0) AS [dialId],
    ISNULL(dialType.[description],''systemTranslated_Auto'') AS [dialType],
    ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
    CASE 
        WHEN provedor_id IS NOT NULL THEN dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),COALESCE(Call.provedor_id,ccld.proBIDs),
            dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg), @country)
        ELSE  CONVERT(DECIMAL(10,2),(CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) / 60) * ccost.additional_min)))
    END AS [ncost],
    @IVA AS iva,
    CASE
        WHEN provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),
                COALESCE(Call.provedor_id,ccld.proBIDs), dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg), @country),0.00) * (1 + (@IVA / 100.00)))
        ELSE  CONVERT(DECIMAL(10,2),((CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) / 60) * ccost.additional_min)) * (1 + (@IVA / 100.00))))
    END AS total,
    COALESCE(ccld.Puerto, Call.cal_puerto, 0) as [trunk],
    case when ccld.ani<>'''' then ccld.ani when dbo.TelAni(ccld.Telefono, camps.id_anilist) <> '''' then dbo.TelAni(ccld.Telefono, camps.id_anilist) else camps.ani end [ANI],
    COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) as dialTimeSec
FROM ccld
    LEFT JOIN ccoCallsOut Call WITH(NOLOCK) ON ccld.cal_id = Call.cal_id
            AND ccld.answerbit = 1
    LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
    LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
    LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
    LEFT JOIN ccCallCost_RIA ccost (NOLOCK) ON ccost.tipoLlamada_id = tl.tipoLlamada_id     AND ccost.country_id = tl.country_id
    left join dialType on dialType.dialId = Call.cal_manual


;with clt as (

SELECT *
, DATEADD(ss,-(tAntesXfer + tDespuesXfer),fechaFin) AS [date]
, tipoLlamada_id AS  CallType 
,case WHEN modo in(5,6) then abs(destino) else null end posicion
    FROM cclogtransfers WITH(NOLOCK) 
    WHERE modo not in (1,2) 
        AND (tAntesXfer > 0 or tDespuesXfer > 0) 
        AND fechaFin between @from and @to
)


INSERT INTO RepOutAnswAndXferCalls  
SELECT clt.[date],
    clt.cal_id AS [callid],
    COALESCE(co.cam_id,ci.inbound_id,''0'')  AS [campaignId],
    COALESCE(camps.cam_descripcion, ACD.descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
    ISNULL((CASE tipo 
                WHEN 1 THEN ci.User_id 
                ELSE co.User_id 
            END),0) AS [userId],
    ISNULL((SELECT nombres + '' '' + apellidopaterno + '' '' + apellidomaterno FROM ccusers NOLOCK WHERE user_id = 
                (CASE tipo 
                    WHEN 1 THEN ci.User_id 
                    ELSE co.User_id 
                END)),''systemTranslated_NoName'') as [Agent],
    dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) AS [dialog],
    CASE 
        WHEN modo = 0 THEN clt.destino
        WHEN modo = 3 THEN clt.destino 
        WHEN modo = 4 THEN clt.destino 
        WHEN modo in(5,6) THEN isnull((SELECT top 1 Computer FROM ccposicion WHERE pos_id = posicion),clt.destino) 
    END AS [telephone],
    3 AS [dialId],
    @descriptionXfer AS [dialType],
    ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
    CASE 
        WHEN tarifa.provedor_id IS NOT NULL THEN ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
            dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) ,@country), 0) 
        ELSE cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)
    END AS [ncost],
    @IVA AS iva,
    CASE 
        WHEN tarifa.provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
            dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0)
            ,@country),0.00) * (1 + (@IVA / 100.00))) 
        ELSE (cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)) * (1 + (@IVA / 100.00))
    END AS [total],
    IsNull(clt.channel, 0) as [trunk],
    case when (@country = 1 and modo = 4) then case when dbo.TelAni(clt.destino, camps.id_anilist) <> '''' then dbo.TelAni(clt.destino,camps.id_anilist) else camps.ani end else '''' end [ANI],
    ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) as dialTimeSec
FROM clt
    LEFT JOIN cccallsin ci WITH(NOLOCK) ON ci.cal_id=clt.cal_id AND tipo=1
    LEFT JOIN ccocallsout co WITH(NOLOCK) ON co.cal_id=clt.cal_id AND tipo=2 
    LEFT JOIN ccChannelTransfer channel ON clt.pbxId=channel.pbxId AND clt.channel BETWEEN channel.startChannel AND channel.endChannel
    LEFT JOIN cstoTarifa tarifa ON tarifa.provedor_id=channel.proveedorId AND tarifa.tipoLlamada_id = clt.CallType
    LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType AND tl.Country_id = @country)
    LEFT JOIN ccCallCost_RIA cCall ON cCall.country_id = tl.country_id AND cCall.tipoLlamada_id = tl.tipoLlamada_id
    LEFT JOIN ccCamps camps ON camps.[cam_id] = co.cam_id
    LEFT JOIN ccInbound ACD ON ACD.[Inbound_id] = ci.Inbound_id

end'
    EXEC(@sql)

    
    set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
    set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
        begin
        ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
        end'
EXEC(@sql)

    ---------------------------------------BEGIN Jesus Gallardo hotfix/125.20231211.0.11---------------------------------------------------------

	--------------------------------------- BEGIN Marco Garcia hotfix/125.20231211.0.15 ------------------------------------------------------------------------------
	set @process = 'TT10897 Se añade un Setting'
	set @sql = 'if not exists(select * from ccsettings where setting_id=46) begin
			insert into ccsettings values(46,''0'',''Incluye los registros de las llamadas de entrada IVR al reporte RepInCallsDetail si el valor es 1 '',1,''X'')
		end'

	EXEC(@sql)

	set @process = 'alter SP ccspRepInCallsDetail se modificó sp, para que tome el valor del setting 46, y así saber si poner los registros del IVR en el reporte, o no ponerlos,
	y se modificaron las columnas timeTotalInCallSec y timeTotalInCallMin, para que cuando cal_final sea null en lugar de poner 0, poner el calculo de ciertas columnas '
    set @sql='ALTER PROCEDURE [dbo].[ccspRepInCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
		AS

		SET NOCOUNT ON

		IF @from IS NULL
			SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

		IF @to IS NULL
			SELECT @to = getdate()

		IF @action = 1
		BEGIN

			DECLARE @tab TABLE (callId INT PRIMARY KEY, [Dato1] VARCHAR(255), [Dato2] VARCHAR(255), [Dato3] VARCHAR(255), [Dato4] VARCHAR(255), [Dato5] VARCHAR(255))
			DECLARE @showIVRCallsinSetting  TINYINT;

			INSERT INTO @tab
			SELECT callId, [Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5]
			FROM (
				SELECT A.CallId, [Data], [Description]
				FROM DataCallIn A
				INNER JOIN ccCallsIn B ON A.CallId = B.cal_id
				WHERE b.cal_Inicio >= @from AND b.cal_Inicio < @to
				) AS SourceTable
			pivot(max([Data]) FOR [Description] IN ([Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5])) AS pvt

			--Borrar lo que esta para no repetir
			DELETE
			FROM RepInCallsDetail
			WHERE [date] >= @from AND [date] < @to

			SELECT @showIVRCallsinSetting = cs.valor FROM dbo.ccSettings AS cs WHERE cs.setting_id = 46

			IF(@showIVRCallsinSetting > 0)
			BEGIN
				INSERT INTO RepInCallsDetail (DATE,
				 callid,
				 inboundId,
				 ACDGroup,
				 callStatusId,
				 callStatus,
				 dispositionId,
				 disposition,
				 subDispositionId,
				 subDisposition,
				 dnisId,
				 dnis,
				 userId,
				 [user],
				 callKey,
				 ANI,
				 queueTime,
				 xferTime,
				 ringingTime,
				 dialogTime,
				 extension,
				 agentName,
				 whoHangUp,
				 mohTime,
				 year,
				 month,
				 day,
				 hour,
				 minutes,
				 provedorId,
				 provider,
				 trunk,
				 fileMoved,
				 twrapup,
				 AverageHandleTime,
				 Dato1,
				 Dato2,
				 Dato3,
				 Dato4,
				 Dato5,
				 grabId,
				 nameDNI,
				 numDNI,
				 collectCall,
				 timeTotalInCallSec,
				 timeTotalInCallMin,
				 statusCallByIVR,
				 IVR_ID,
				 callHung,
				 recibeCallBy,
				 cal_final)
					SELECT 
						a.cal_inicio AS cal_ini, 
						a.cal_id,
						a.Inbound_id,
						ISNULL(ccIn.descripcion, '''') AS Inbound, 
						a.statusCall_id, 
						ISNULL(statusLlamada.descripcion, '''') AS statusCall, 
						a.calif_id, 
						ISNULL(disposition.description, '''') AS calif, 
						ISNULL(a.califSub_id, 0), 
						ISNULL(subDisposition.califSubDesc, '''') AS califSub, 
						a.dni_id, 
						ISNULL(dnis.dni_numero, '''') AS dni, 
						a.user_id, 
						ISNULL(LOGIN, '''') AS [user], 
						ISNULL(a.cal_key, '''') as cal_key, 
						a.cal_ANI, 
						cal_tWait, 
						cal_tXfer, 
						cal_tRing, 
						cal_tDialog, 
						a.cal_extension, 
						ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''') AS agentName,
						CASE
							WHEN a.cal_whoHung = 0
							THEN ''systemTranslated_Client''
							WHEN a.cal_whoHung = 1
							THEN ''systemTranslated_Agent''
							ELSE ''systemTranslated_AgentSurvey''
						END [whoHangUp], 
						a.cal_tMoh, 
						DATEPART(yyyy, cal_inicio) [year], 
						DATEPART(mm, cal_inicio) [month], 
						DATEPART(dd, cal_inicio) [day], 
						DATEPART(hh, cal_inicio) [hour], 
						DATEPART(mi, cal_inicio) [minute], 
						di.provedor_id, 
						prov.descrip [Proveedor], 
						a.cal_puerto,
						CASE
					WHEN a.file_moved = 1 THEN ''systemTranslated_Remoto''
					WHEN a.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
							ELSE ''Local''
						END AS file_Moved, 
						cal_tNotas, 
						AverageHandleTime = cal_tNotas + cal_tDialog, 
						ISNULL(tab.Dato1, '''') AS Dato1, 
						ISNULL(tab.Dato2, '''') AS Dato2, 
						ISNULL(tab.Dato3, '''') AS Dato3, 
						ISNULL(tab.Dato4, '''') AS Dato4, 
						ISNULL(tab.Dato5, '''') AS Dato5, 
						ISNULL(rc.grab_id, 0) AS grabId,
						ISNULL(dni_Descripcion, '''') AS nameDNI,
						ISNULL(dnis.dni_numero, '''') AS dni,
						CASE
								WHEN statusLlamada.descripcion IS NOT NULL THEN ''Si''
								ELSE ''No''
						END AS collectCall,
						CASE
							WHEN A.cal_final IS NULL THEN CAST( (cal_tDialog + cal_tXfer + cal_tWait + cal_tRing) AS INT)
							ELSE CAST( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) AS INT)
						END AS timeTotalInCallSec,
						CASE
							WHEN A.cal_final IS NULL THEN CAST(FLOOR( ( cal_tDialog + cal_tXfer + cal_tWait  + cal_tRing  ) / 60) AS INT)
							ELSE CAST( FLOOR( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) / 60 ) AS INT) 
						END + 
						CASE
							WHEN A.cal_final IS NULL THEN 
								CASE 
									WHEN CEILING(CAST( (cal_tDialog + cal_tXfer  + cal_tWait  + cal_tRing) AS INT  ) % 60) != 0 THEN 1 
									ELSE 0
								END
							ELSE
								CASE
									WHEN CAST(CEILING( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) ) AS INT) % 60 != 0 THEN 1
									ELSE 0
								END
						END AS timeTotalInCallMin,
						CASE 
							WHEN a.IVR_id != 0 and ivrCIN.callStatus = ''systemTranslated_AbandonedInIVR'' THEN ''systemTranslated_AbandonedInIVR''
							WHEN a.statusCall_id = 13 THEN ''systemTranslated_Answered''
							WHEN a.statusCall_id != 13 THEN ''''
							ELSE ''''
						END AS statusCallByIVR,
						ISNULL(ivrCIN.IVR_ID, 0) AS IVR,
						CASE
							WHEN ivrCIN.callStatus = ''systemTranslated_AbandonedInIVR'' THEN ''systemTranslated_ClientSystem''
							ELSE ''''
						END AS statusCallByIVR,
						CASE
							WHEN ivrCIN.callid = a.cal_id THEN ''systemTranslated_SystemIVR''
							WHEN a.IVR_id = 0 THEN ''systemTranslated_CallInbound'' 
							ELSE ''''
						END AS [recibeCallBy], 
						ISNULL(a.cal_final, NULL) AS cal_final
				FROM cccallsin A   
						LEFT JOIN ccoDialers di ON di.dialer_id = a.cal_puerto
						LEFT JOIN cstoProvedor prov ON di.provedor_id = prov.provedor_id
						LEFT JOIN @tab tab ON tab.callId = a.cal_id
						LEFT JOIN Ria_grabacion rc ON rc.cal_id = a.cal_id and rc.tipo_llamada=1
						LEFT JOIN ccInbound ccIn ON a.Inbound_id = ccIn.Inbound_id
						LEFT JOIN ccstatusllamada statusLlamada ON a.statusCall_id = statusLlamada.statusCall_id
						LEFT JOIN cctipocalif disposition ON a.calif_id = disposition.calif_id
						LEFT JOIN cctipocalifsub subDisposition ON a.califSub_id = subDisposition.califSub_id
						LEFT JOIN ccdnis dnis ON a.dni_id = dnis.dni_id
						LEFT JOIN ccUserView ccuser ON a.User_id = ccuser.user_id
						LEFT JOIN repIVRDetail ivrCIN ON a.IVR_id = ivrCIN.IVR_ID 
				WHERE a.cal_inicio >= @from
						AND a.cal_inicio < @to


				EXEC SupportReportCallInIVR 1, @from, @to

			END
			ELSE
			BEGIN

				INSERT INTO RepInCallsDetail (DATE,
				 callid,
				 inboundId,
				 ACDGroup,
				 callStatusId,
				 callStatus,
				 dispositionId,
				 disposition,
				 subDispositionId,
				 subDisposition,
				 dnisId,
				 dnis,
				 userId,
				 [user],
				 callKey,
				 ANI,
				 queueTime,
				 xferTime,
				 ringingTime,
				 dialogTime,
				 extension,
				 agentName,
				 whoHangUp,
				 mohTime,
				 year,
				 month,
				 day,
				 hour,
				 minutes,
				 provedorId,
				 provider,
				 trunk,
				 fileMoved,
				 twrapup,
				 AverageHandleTime,
				 Dato1,
				 Dato2,
				 Dato3,
				 Dato4,
				 Dato5,
				 grabId,
				 nameDNI,
				 numDNI,
				 collectCall,
				 timeTotalInCallSec,
				 timeTotalInCallMin,
				 statusCallByIVR,
				 IVR_ID,
				 callHung,
				 recibeCallBy,
				 cal_final)
			SELECT 
			   a.cal_inicio AS cal_ini, 
			   a.cal_id,
			   a.Inbound_id,
			   ISNULL(ccIn.descripcion, '''') AS Inbound, 
			   a.statusCall_id, 
			   ISNULL(statusLlamada.descripcion, '''') AS statusCall, 
			   a.calif_id, 
			   ISNULL(disposition.description, '''') AS calif, 
			   ISNULL(a.califSub_id, 0), 
			   ISNULL(subDisposition.califSubDesc, '''') AS califSub, 
			   a.dni_id, 
			   ISNULL(dnis.dni_numero, '''') AS dni, 
			   a.user_id, 
			   ISNULL(LOGIN, '''') AS [user], 
			   ISNULL(a.cal_key, '''') as cal_key, 
			   a.cal_ANI, 
			   cal_tWait, 
			   cal_tXfer, 
			   cal_tRing, 
			   cal_tDialog, 
			   a.cal_extension, 
			   ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''') AS agentName,
			   CASE
				   WHEN a.cal_whoHung = 0
				   THEN ''systemTranslated_Client''
				   WHEN a.cal_whoHung = 1
				   THEN ''systemTranslated_Agent''
				   ELSE ''systemTranslated_AgentSurvey''
			   END [whoHangUp], 
			   a.cal_tMoh, 
			   DATEPART(yyyy, cal_inicio) [year], 
			   DATEPART(mm, cal_inicio) [month], 
			   DATEPART(dd, cal_inicio) [day], 
			   DATEPART(hh, cal_inicio) [hour], 
			   DATEPART(mi, cal_inicio) [minute], 
			   di.provedor_id, 
			   prov.descrip [Proveedor], 
			   a.cal_puerto,
			   CASE
			WHEN a.file_moved = 1 THEN ''systemTranslated_Remoto''
			WHEN a.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
				   ELSE ''Local''
			   END AS file_Moved, 
			   cal_tNotas, 
			   AverageHandleTime = cal_tNotas + cal_tDialog, 
			   ISNULL(tab.Dato1, '''') AS Dato1, 
			   ISNULL(tab.Dato2, '''') AS Dato2, 
			   ISNULL(tab.Dato3, '''') AS Dato3, 
			   ISNULL(tab.Dato4, '''') AS Dato4, 
			   ISNULL(tab.Dato5, '''') AS Dato5, 
			   ISNULL(rc.grab_id, 0) AS grabId,
			   ISNULL(dni_Descripcion, '''') AS nameDNI,
			   ISNULL(dnis.dni_numero, '''') AS dni,
			   CASE
					 WHEN statusLlamada.descripcion IS NOT NULL THEN ''Si''
					 ELSE ''No''
			   END AS collectCall,
			   CASE
					WHEN A.cal_final IS NULL THEN CAST( (cal_tDialog + cal_tXfer + cal_tWait + cal_tRing) AS INT)
					ELSE CAST( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) AS INT)
				END AS timeTotalInCallSec,
				CASE
					WHEN A.cal_final IS NULL THEN CAST(FLOOR( ( cal_tDialog + cal_tXfer + cal_tWait  + cal_tRing  ) / 60) AS INT)
					ELSE CAST( FLOOR( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) / 60 ) AS INT) 
				END + 
				CASE
					WHEN A.cal_final IS NULL THEN 
						CASE 
							WHEN CEILING(CAST( (cal_tDialog + cal_tXfer  + cal_tWait  + cal_tRing) AS INT  ) % 60) != 0 THEN 1 
							ELSE 0
						END
					ELSE
						CASE
							WHEN CAST(CEILING( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) ) AS INT) % 60 != 0 THEN 1
							ELSE 0
						END
				END AS timeTotalInCallMin,
			   CASE 
					WHEN a.IVR_id != 0 THEN ''systemTranslated_AbandonedInIVR''
					WHEN a.statusCall_id = 13 THEN ''systemTranslated_Answered''
					WHEN a.statusCall_id != 13 THEN ''''
					ELSE ''''
				END AS statusCallByIVR,
				0 AS IVR,
				'''' AS statusCallByIVR,
				CASE
					WHEN a.IVR_id = 0 THEN ''systemTranslated_CallInbound'' 
					ELSE ''''
				END AS [recibeCallBy], 
				ISNULL(a.cal_final, NULL) AS cal_final
		FROM cccallsin A   
			 LEFT JOIN ccoDialers di ON di.dialer_id = a.cal_puerto
			 LEFT JOIN cstoProvedor prov ON di.provedor_id = prov.provedor_id
			 LEFT JOIN @tab tab ON tab.callId = a.cal_id
			 LEFT JOIN Ria_grabacion rc ON rc.cal_id = a.cal_id and rc.tipo_llamada=1
			 LEFT JOIN ccInbound ccIn ON a.Inbound_id = ccIn.Inbound_id
			 LEFT JOIN ccstatusllamada statusLlamada ON a.statusCall_id = statusLlamada.statusCall_id
			 LEFT JOIN cctipocalif disposition ON a.calif_id = disposition.calif_id
			 LEFT JOIN cctipocalifsub subDisposition ON a.califSub_id = subDisposition.califSub_id
			 LEFT JOIN ccdnis dnis ON a.dni_id = dnis.dni_id
			 LEFT JOIN ccUserView ccuser ON a.User_id = ccuser.user_id
		WHERE a.cal_inicio >= @from
			  AND a.cal_inicio < @to

			END

		END'
    EXEC(@sql)
	-------------------------- ------------ END Marco García hotfix/125.20231211.0.15
	-------------------------- ------------ BEGIN Frida García hotfix/125.20231211.0.15
	    set @process = 'CW-8604 Drop sp ccspRepAVRSQuestion'
		set @sql='
		if exists (select * from sys.procedures where name = N''ccspRepAVRSQuestion'')
		begin
			DROP PROCEDURE ccspRepAVRSQuestion;
		end'
		EXEC(@sql)

		set @process = 'CW-8604 create procedure ccspRepAVRSQuestion refactorización '
		set @sql='
		CREATE PROCEDURE  ccspRepAVRSQuestion
		@action as tinyint,
		@from as datetime = null,
		@to as datetime = null
		AS
		if @from is null
		  select @from = convert(datetime,convert(varchar(11),getdate()))
		if @to is null
		  select @to = getdate()

		if(DATEPART(hour, @from) = 3 and DATEPART(minute, @from) = 0)
		  SELECT @from = convert(DATETIME, convert(VARCHAR(11), @from))

		if @action = 1 BEGIN


		DELETE FROM dbo.RepAVRSQuestion with(rowlock)
		where date >= @from AND date < @to

		;with template as (
		select 
		rfc.nameFormatConcept
		,rcq.idQuestion
		,rcq.idConcept
		,rcq.idFormat
		,rcq.title
		,ref.nameFormat

		from  RECORDERRIA_CONCEPTQUESTIONS rcq
		right join RECORDERRIA_FORMATCONCEPTS rfc on rfc.idConcept = rcq.idConcept
		right join RECORDERRIA_EVALUATIONFORMATS ref on ref.idFormat = rcq.idFormat
		),
		riagrab as(
			select r.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada 
			from RIA_GRABACION r 
			union
			select rgc.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from ria_grabacionconsulta rgc 
		),
		answer as (
			select 
			 rre.nameAdmin--
			,convert(date, rre.createAt) as [date]
			,raq.idRecordingEvaluation
			,raq.IdQuestion
			,raq.points
			,rre.grab_id
			,rre.userAdmin
			,rre.createAt
			,rre.idFormat
			from  RECORDERRIA_ANSWERSOFQUESTIONSEVALUATION raq
			right join  RECORDERRIA_RECORDINGEVALUATION rre on rre.idRecordingEvaluation = raq.idRecordingEvaluation
		),
		total as(
		select 
		an.date as [date]
		,ra.age_id  as UserId
		,cu.Login AS [user]
		,(cu.apellidopaterno+'' ''+cu.apellidomaterno+'' ''+cu.nombres)  AS agentName
		,ccu.User_id as supervisorId
		,an.userAdmin as supervisorUser
		,an.nameAdmin as Supervisor
		,t.idFormat  AS templateId
		,t.nameFormat AS Template
		,t.idConcept as sectionId
		,t.nameFormatConcept as Section
		,t.idQuestion as questionId
		,t.title as question
		,an.points as score
		,an.grab_id as mediaId
		,case ra.tipo_grab_id
			  when 1 then case ra.tipo_llamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end    
			  when 2 then ''systemTranslated_Chat''
			  when 3 then ''systemTranslated_Email''
			  when 3 then ''systemTranslated_Twitter''
			end as media
		,ra.cam_id AS cam_id
		,(CASE WHEN ra.tipo_llamada = 2 THEN cc.cam_descripcion ELSE ci.descripcion END) AS campaignAcd
		from answer an
		left join template t on t.idFormat = an.idFormat
		inner join riagrab ra on ra.grab_id = an.grab_id
		inner join ccUsers cu ON cu.User_id = ra.age_id
		inner join ccUsers ccu on ccu.Login = an.userAdmin
		left join cccamps cc ON ra.cam_id = cc.cam_id
		left join ccinbound ci ON ra.cam_id = ci.Inbound_id
		WHERE an.createAt >= @from AND an.createAt <= @to
		),
		dataResume as(
		(select
		convert(date, f.fecha_calif) as [date]
			,f.age_id as userId
			,a.Login as [user]
			,(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agentName
			,f.id_calificador as supervisorId
			,s.Login as supervisorUser
			,(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor
			,f.id_formato as templateId
			,q.nombre as Template
			,c.id_concepto as sectionId
			,c.con_descripcion as Section
			,p.id_pregunta AS questionId
			,p.enunciado_pregunta AS Question
			,r.peso AS score
			,f.id_grabacion as mediaId
			,case f.tipo
				when 1 then case f.tipo_llamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end
				when 2 then ''systemTranslated_Chat''
				when 3 then ''systemTranslated_Email''
				when 3 then ''systemTranslated_Twitter''
			end as media
			,f.cam_id as cam_id
			,(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END) AS campaignAcd

		from RIA_RESULTADOSFORMA r
		  INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
		  INNER JOIN RIA_FORMATOS q ON q.id_formato = f.id_formato
		  INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
		  INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
		  INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
		  INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
		  left JOIN cccamps AS e ON f.cam_id = e.cam_id and  f.tipo_llamada=2
		  left JOIN ccinbound AS u ON f.cam_id = u.Inbound_id and  f.tipo_llamada=1
		  WHERE f.fecha_calif >= @from AND f.fecha_calif <= @to
		  )
		  UNION
		  (
			 select 
				date
				,UserId
				,user
				,agentName AS agentName
				,supervisorId
				,supervisorUser
				,Supervisor
				,templateId
				,Template
				,sectionId
				,Section
				,questionId
				,question
				,score
				,mediaId
				,media
				,cam_id
				,campaignAcd
			 from total 
		  )
		)
		  INSERT INTO dbo.RepAVRSQuestion ([date],userId,[user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section, questionId, Question, avgDisposition,mediaId,media,cam_id,campaignAcd,Dispositions)
		  select [date],userId, [user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section, questionId, Question, avg(score) score, mediaId, media,cam_id,campaignAcd, avg(score) score
		  from dataResume
		  group by  [date], userId,[user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section, questionId, Question,
		  mediaId,media,cam_id,campaignAcd
 
		END'
			EXEC(@sql)

		set @process = 'CW-8604 se agrega agrupación por mediaId, sectionId,questionId'
		set @sql='
		update GroupByReports set columns=''Template|mediaId|sectionId|questionId|Section|question|count(avgDisposition):Dispositions|avg(avgDisposition):avgDisposition''
		,groupByColumns=''Template|mediaId|sectionId|questionId|Section|question''
		where id=8064'
		EXEC(@sql)
	-------------------------- ------------ END Frida García hotfix/125.20231211.0.15
----------------------------------------------------------- BEGIN Isaac Cortes  hotfix/125.20231211.0.17  -------------------------------------------------------------------------
    set @process = 'Actualizar settting 40'
    set @sql='
    IF (SELECT valor FROM ccsettings WHERE setting_id=44) <> ''200000|200000|2500000|10000|250000|2500000|44''
    BEGIN
        UPDATE ccSettings 
        SET valor=''200000|200000|2500000|10000|250000|2500000|44''
        WHERE setting_id=44
    END
    '
    EXEC(@sql)

    set @process = 'Eliminar SP ccspRepCallXfer'
    set @sql='
    IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepCallXfer'')
    BEGIN
        DROP PROCEDURE ccspRepCallXfer;
    END
    '
    EXEC(@sql)

    set @process = 'Crear SP ccspRepCallXfer y añadir modo 7 para press 8'
    set @sql='
    CREATE PROCEDURE [dbo].[ccspRepCallXfer]
    @action as tinyint,
    @from AS datetime = null,
    @to AS datetime = null
    AS

    SET NOCOUNT ON

    if @action = 1
    begin
        if @from is null
            select @from = convert(datetime,convert(varchar(11),getdate()))
        if @to is null	
            select @to = getdate()

        delete RepCallXfer where [date] between @from and @to

        insert RepCallXfer 
        select convert(varchar(10),fechafin,121) [date], 
        clt.cal_id callid, 
        case when tipo = 1 then ''systemTranslated_inbound'' else ''systemTranslated_outbound'' end CallTypes, 
        isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno 
                from ccUserView nolock 
                where user_id = (case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') Agent, 
        case when modo = 0 then ''systemTranslated_blindXfer'' 
            when modo = 1 then ''systemTranslated_Agent'' 
            when modo = 2 then 
                case when cast(dbo.Limpia(clt.destino) as int) >= 0 then ''systemTranslated_acd'' 
                    else ''systemTranslated_Survey'' end 
            when modo = 3 then ''systemTranslated_conference'' 
            when modo = 4 then ''systemTranslated_supXfer'' 
            when modo in(5,6) then ''systemTranslated_overflow'' 
            when modo in(7) then ''systemTranslated_press8'' 
            else ''systemTranslated_Default'' 
        end as xfertype, 
        ISNULL((case when modo = 0 then isnull((select top 1 nombre 
                                        from telefonosTransferencia 
                                        where tel = clt.destino),clt.destino) 
            when modo = 1 then isnull((select Computer 
                                        from ccposicion 
                                        where pos_id = abs(clt.destino)),''systemTranslated_Indefinite'') 
            when modo = 2 then 
                case when cast(dbo.Limpia(clt.destino) as bigint) >= 0 then
                        isnull((select descripcion from ccinbound 
                                where inbound_id = clt.destino),''systemTranslated_Indefinite'') 
                    else
                        isnull((select top 1 description 
                                from survey 
                                where active=1 
                                and scriptId = abs(cast(clt.destino as int))),''systemTranslated_Indefinite'') 
                end 
            when modo = 3 then isnull((select nombre 
                                        from telefonosConferencia 
                                        where tel = clt.destino),clt.destino) 
            when modo = 4 then isnull((select top 1 nombre 
                                        from telefonosTransferencia 
                                        where tel = clt.destino),clt.destino) 
            when modo in(5,6) then isnull((select Computer 
                                            from ccposicion 
                                            where pos_id = abs(clt.destino)),clt.destino) 
        end), ''systemTranslated_Indefinite'') destination, 
        tantesxfer timebeforexfer, 
        tdespuesxfer timeafterxfer, 
        dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate, 
        fechafin as endDate, 
        case when camp.cam_descripcion is not null then camp.cam_descripcion 
            when inbound.descripcion is not null then inbound.descripcion 
            else ''systemTranslated_Indefinite'' 
        end as Origin, 
        tantesxfer+tdespuesxfer as TotalTimeDuration, 
        isnull((select case clt.tipoLlamada_id 
                    when 1 then ''systemTranslated_fijo'' 
                    when 3 then ''systemTranslated_cellPhone'' 
                    else ''systemTranslated_interno'' 
                end),''systemTranslated_Indefinite'') as TipoTel, 
        (case tipo when 1 then ci.User_id else co.User_id end) User_ID, 
        isnull(callerAni, '''')  as callerni
        from cclogtransfers clt with(nolock,index(IX_ccLogTransfers_3)) 
        left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
        left join cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1 
        left join cccamps camp on camp.cam_id =co.cam_id 
        left join ccinbound inbound on inbound.Inbound_id =ci.Inbound_id 
        WHERE fechafin >= @from and fechafin < @to
    end
    '
    EXEC(@sql)




----------------------------------------------------------- End Isaac Cortes hotfix/125.20231211.0.17 -------------------------------------------------------------------------


    -------------------------------------- Begin Jesus Gallardo hotfix/125.20231211.0.17 --------------------------------------
    set @process = 'alter SP ccspRepOutAnswAndXferCalls se modifica ani de ccoLogDials para reportes'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = NULL

AS

SET NOCOUNT ON

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME,CONVERT(VARCHAR(11),GETDATE()))
IF @to IS NULL
    SELECT @to = GETDATE()

DECLARE @IVA INT
DECLARE @country AS TINYINT
SELECT @IVA = CONVERT(INT,ISNULL(valor,0)) FROM ccsettings WHERE setting_id = 25
SELECT @country = CONVERT(TINYINT,ISNULL(valor,1)) FROM ccsettings WHERE setting_id = 104

IF @country IS NULL SET @country = 1

IF @action = 1
BEGIN
--Borrar lo que esta para no repetir
DELETE FROM RepOutAnswAndXferCalls WHERE DATE >= @from AND DATE < @TO

declare @descriptionXfer varchar(100)

SELECT @descriptionXfer=[description] FROM dialType WHERE dialId = 3

;with ccld as(
    SELECT *, [dbo].[GetProveedor](Telefono, Puerto,tipoLlamada_id) AS proBIDs,tipoLlamada_id as CallType  FROM ccologdials
    WHERE fecha between @from and @to and answerbit = 1
)

INSERT INTO RepOutAnswAndXferCalls
SELECT COALESCE([Call].cal_inicio,ccld.fecha) AS [date],
    ISNULL(ccld.cal_id,0) AS [callid],
    ISNULL(ccld.cam_id,0) AS [campaignId],
    ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
    ISNULL([Call].user_id,0) AS [userId],
    ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') AS [Agent],
    dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg) AS [dialog],
    ccld.telefono AS [telephone],
    ISNULL(Call.cal_manual,0) AS [dialId],
    ISNULL(dialType.[description],''systemTranslated_Auto'') AS [dialType],
    ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
    CASE 
        WHEN provedor_id IS NOT NULL THEN dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),COALESCE(Call.provedor_id,ccld.proBIDs),
            dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg), @country)
        ELSE  CONVERT(DECIMAL(10,2),(CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) / 60) * ccost.additional_min)))
    END AS [ncost],
    @IVA AS iva,
    CASE
        WHEN provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),
                COALESCE(Call.provedor_id,ccld.proBIDs), dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg), @country),0.00) * (1 + (@IVA / 100.00)))
        ELSE  CONVERT(DECIMAL(10,2),((CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) / 60) * ccost.additional_min)) * (1 + (@IVA / 100.00))))
    END AS total,
    COALESCE(ccld.Puerto, Call.cal_puerto, 0) as [trunk],
    case when (ccld.ani is not null and ccld.ani<>'''') then ccld.ani when dbo.TelAni(ccld.Telefono, camps.id_anilist) <> '''' then dbo.TelAni(ccld.Telefono, camps.id_anilist) else camps.ani end [ANI],
    COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) as dialTimeSec
FROM ccld
    LEFT JOIN ccoCallsOut Call WITH(NOLOCK) ON ccld.cal_id = Call.cal_id
            AND ccld.answerbit = 1
    LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
    LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
    LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
    LEFT JOIN ccCallCost_RIA ccost (NOLOCK) ON ccost.tipoLlamada_id = tl.tipoLlamada_id     AND ccost.country_id = tl.country_id
    left join dialType on dialType.dialId = Call.cal_manual


;with clt as (

SELECT *
, DATEADD(ss,-(tAntesXfer + tDespuesXfer),fechaFin) AS [date]
, tipoLlamada_id AS  CallType 
,case WHEN modo in(5,6) then abs(destino) else null end posicion
    FROM cclogtransfers WITH(NOLOCK) 
    WHERE modo not in (1,2) 
        AND (tAntesXfer > 0 or tDespuesXfer > 0) 
        AND fechaFin between @from and @to
)


INSERT INTO RepOutAnswAndXferCalls  
SELECT clt.[date],
    clt.cal_id AS [callid],
    COALESCE(co.cam_id,ci.inbound_id,''0'')  AS [campaignId],
    COALESCE(camps.cam_descripcion, ACD.descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
    ISNULL((CASE tipo 
                WHEN 1 THEN ci.User_id 
                ELSE co.User_id 
            END),0) AS [userId],
    ISNULL((SELECT nombres + '' '' + apellidopaterno + '' '' + apellidomaterno FROM ccusers NOLOCK WHERE user_id = 
                (CASE tipo 
                    WHEN 1 THEN ci.User_id 
                    ELSE co.User_id 
                END)),''systemTranslated_NoName'') as [Agent],
    dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) AS [dialog],
    CASE 
        WHEN modo = 0 THEN clt.destino
        WHEN modo = 3 THEN clt.destino 
        WHEN modo = 4 THEN clt.destino 
        WHEN modo in(5,6) THEN isnull((SELECT top 1 Computer FROM ccposicion WHERE pos_id = posicion),clt.destino) 
    END AS [telephone],
    3 AS [dialId],
    @descriptionXfer AS [dialType],
    ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
    CASE 
        WHEN tarifa.provedor_id IS NOT NULL THEN ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
            dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) ,@country), 0) 
        ELSE cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)
    END AS [ncost],
    @IVA AS iva,
    CASE 
        WHEN tarifa.provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
            dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0)
            ,@country),0.00) * (1 + (@IVA / 100.00))) 
        ELSE (cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)) * (1 + (@IVA / 100.00))
    END AS [total],
    IsNull(clt.channel, 0) as [trunk],
    case when (@country = 1 and modo = 4) then case when dbo.TelAni(clt.destino, camps.id_anilist) <> '''' then dbo.TelAni(clt.destino,camps.id_anilist) else camps.ani end else '''' end [ANI],
    ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) as dialTimeSec
FROM clt
    LEFT JOIN cccallsin ci WITH(NOLOCK) ON ci.cal_id=clt.cal_id AND tipo=1
    LEFT JOIN ccocallsout co WITH(NOLOCK) ON co.cal_id=clt.cal_id AND tipo=2 
    LEFT JOIN ccChannelTransfer channel ON clt.pbxId=channel.pbxId AND clt.channel BETWEEN channel.startChannel AND channel.endChannel
    LEFT JOIN cstoTarifa tarifa ON tarifa.provedor_id=channel.proveedorId AND tarifa.tipoLlamada_id = clt.CallType
    LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType AND tl.Country_id = @country)
    LEFT JOIN ccCallCost_RIA cCall ON cCall.country_id = tl.country_id AND cCall.tipoLlamada_id = tl.tipoLlamada_id
    LEFT JOIN ccCamps camps ON camps.[cam_id] = co.cam_id
    LEFT JOIN ccInbound ACD ON ACD.[Inbound_id] = ci.Inbound_id

end'
    EXEC(@sql)

    set @process = 'Update datos por hoja'
    set @sql='update ccSettings 
set valor=''200000|200000|2500000|10000|250000|2500000|44''
where setting_id=44'
    EXEC(@sql)
    -------------------------------------- End hotfix/125.20231211.0.17 --------------------------------------
    -------------------------------------- Begin hotfix/125.20231211.0.19 --------------------------------------
    set @process = 'Alter SP ccspRepAgentGI se agrega eliminar ambos DELETE  FROM RepAgentGI_VersionOld  WHERE DATE >= @from AND DATE < @to'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepAgentGI] 
@action AS TINYINT ,@from AS DATETIME ,@to AS DATETIME
AS
SET ANSI_WARNINGS OFF;
SET NOCOUNT ON;

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

IF @to IS NULL
    SELECT @to = GETDATE();

IF @action = 1
BEGIN
    
    DELETE  FROM RepAgentGI WHERE DATE >= @from AND DATE < @to
    DELETE  FROM RepAgentGI_VersionOld  WHERE DATE >= @from AND DATE < @to

    ;with timeDetailAgent as(   
    SELECT userId, timegroup        
        ,sum(CASE WHEN tipostatusage_id = 1 THEN tStatus ELSE 0 END) tunknown
        ,sum(CASE WHEN tipostatusage_id = 2 THEN tStatus ELSE 0 END) tNotReady
        ,sum(CASE WHEN tipostatusage_id IN (3, 31) THEN tStatus ELSE 0 END) tReady  --3 Ready y 31  Ready PreviewPro    
        ,sum(CASE WHEN tipostatusage_id IN (11, 25, 26, 27) THEN tStatus ELSE 0 END) tprob --11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida      
        ,sum(CASE WHEN tipostatusage_id = 7 THEN tStatus ELSE 0 END) tother
        ,sum(CASE WHEN tipostatusage_id = 7 THEN 1 ELSE 0 END) nother
        ,sum(CASE WHEN tipostatusage_id = 21 THEN tStatus ELSE 0 END) tmanualcall       
        ,sum(CASE WHEN tipostatusage_id IN (23, 24) THEN tStatus ELSE 0 END) AS tchatting
        ,sum(CASE WHEN tipostatusage_id = 30 THEN tStatus ELSE 0 END) AS tReconnectKolob
        ,sum(CASE WHEN tipostatusage_id = 32 THEN tStatus ELSE 0 END) AS tPreview
        ,sum(CASE WHEN tipostatusage_id = 33 THEN tStatus ELSE 0 END) AS tAssisted
        ,sum(CASE WHEN tipostatusage_id = 34 THEN tStatus ELSE 0 END) AS tDialogoWhatsApp
        FROM tmpccLogAgentesDia A
        group by A.userId,A.timegroup
    )   
    ,inboundCount
    AS (
        SELECT timegroup
            ,user_id AS userId
            ,sum(nxfer) AS nxferin
            ,sum(nanswer) AS nanswerin
            ,sum(nabnd_xfer) AS nabndxferin
            ,sum(nabnd_ring) AS nabndringin
            ,sum(nabnd_dialog) AS nabnddlgin
            ,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferin
            ,sum(nno_answer) AS nnoanswerin
            ,sum(nlost) AS nlostin
            ,sum(nMoh) AS nMohIn
            ,sum(nWHag) AS nWHagIn
            ,sum(nWHcl) AS nWHclIn
            ,sum(tdialog) AS tdialogIn
            ,sum(tnotes) AS tnotesIn
            ,sum(tring) AS tringIn
            ,sum(txfer) AS txferIn          
        FROM tmpTimesInboundData
        WHERE user_id > 0
        group by timegroup,user_id
        )
        ,outboundCount
    AS (
        SELECT timegroup
            ,user_id AS userId
            ,sum(nxfer) AS nxferOut
            ,sum(nanswer) AS nanswerOut
            ,sum(nabnd_xfer) AS nabndxferOut
            ,sum(nabnd_ring) AS nabndringOut
            ,sum(nabnd_dialog) AS nabnddlgOut
            ,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferOut
            ,sum(nno_answer) AS nnoanswerOut
            ,sum(nlost) AS nlostOut
            ,sum(nMoh) AS nMohOut
            ,sum(nWHag) AS nWHagOut
            ,sum(nWHcl) AS nWHclOut
            ,sum(tdialog) AS tdialogOut
            ,sum(tnotes) AS tnotesOut
            ,sum(tring) AS tringOut
            ,sum(txfer) AS txferOut         
        FROM tmpTimesOutboundData
        WHERE user_id > 0
            AND cal_manual IN (0, 2, 3)
            group by timegroup,user_id
        )
    
    
    
    INSERT INTO RepAgentGI
    SELECT A.timegroup AS [date]
        ,A.user_id AS userId
        ,u.Nombres + '' '' + u.ApellidoPaterno + '' '' + u.ApellidoMaterno AS [user]
        ,u.LOGIN
        ,A.tlog
        ,isnull(atgStatus.tunknown,0) as tunknown
        ,isnull(atgStatus.tReady,0) as tReady
        ,isnull(atgStatus.tNotReady,0) as tNotReady
        ,isnull(atgStatus.tother,0) as tother
        ,isnull(atgStatus.tprob,0) as tprob
        ,isnull(atgStatus.tchatting,0) as tchatting
        ,isnull(A.tlog-( 
        isnull(atgStatus.tunknown+atgStatus.tReady+atgStatus.tNotReady+atgStatus.tother+atgStatus.tprob+atgStatus.tchatting+atgStatus.tmanualcall,0)
        +isnull( txferin+tringin+tdialogin+tnotesIn,0)
        +isnull(txferout+tringout+tdialogout+tnotesout,0)
        
        ),0) as tundefined
        
        ------------------ Count IN Call -----------------------
        ,ISNULL(inCount.nxferin, 0) nXferIn
        ,ISNULL(inCount.nanswerin, 0) nAnswerIn
        ,ISNULL(inCount.nabndxferin, 0) nAbndXferIn
        ,ISNULL(inCount.nabndringin, 0) nAbndRingIn
        ,ISNULL(inCOunt.nabnddlgin, 0) AS nAbnddlgIn
        ,ISNULL(inCount.abndaxferin, 0) abndaXferIn
        ,ISNULL(inCount.nnoanswerin, 0) AS nnoAnswerIn
        ,ISNULL(inCount.nlostIn, 0) AS nlostIn
        ,isnull(inCount.tdialogIn, 0) AS tdialogIn
        ,isnull(inCount.tnotesIn, 0) tnotesIn
        ,isnull(inCount.tringIn, 0) tringIn
        ,isnull(inCount.txferIn, 0) txferIn

        ------------------ Count Out Call -----------------------      
        ,isnull(outTime.nXferOut, 0) nXferOut
        ,isnull(outTime.nAnswerOut, 0) nAnswerOut
        ,isnull(outTime.nAbndXferOut, 0) nAbndXferOut
        ,isnull(outTime.nAbndRingOut, 0) nAbndRingOut
        ,isnull(outTime.nAbnddlgOut, 0) AS nAbnddlgOut
        ,isnull(outTime.abndaXferOut, 0) abndaXferOut
        ,isnull(outTime.nnoAnswerOut, 0) AS nnoAnswerOut
        ,isnull(outTime.nlostOut, 0) AS nlostOut
        ,ISNULL(outTime.tdialogOut, 0) tdialogOut
        ,ISNULL(outTime.tnotesOut, 0) tnotesOut
        ,ISNULL(outTime.tringOut, 0) tringOut
        ,ISNULL(outTime.txferOut, 0) txferOut
        
        ------------------ Time Agent Common -----------------------      
        ,ISNULL(atgStatus.nother,0) nOther
        
        ------------------ Count In/Out Call-----------------------      
        ,isnull(inCount.nMohIn, 0) AS nMohIn
        ,isnull(outTime.nMohOut, 0) AS nMohOut
        ,isnull(inCount.nWHagIn, 0) AS nWHagIn
        ,isnull(outTime.nWHagOut, 0) AS nWHagOut 
        ,isnull(inCount.nWHclIn, 0) AS nWHclIn
        ,isnull(outTime.nWHclOut, 0) AS nWHclOut                

        ,datepart(yyyy, A.timegroup) AS [year]
        ,datepart(mm, A.timegroup) AS [mount]
        ,datepart(dd, A.timegroup) AS [day]
        ,datepart(HH, A.timegroup) AS [hour]
        ,datepart(mi, A.timegroup) AS [minutes]
        ,isnull(atgStatus.tmanualcall,0) as tmanualcall
        
    FROM TmpSessionTimeGroup A
    LEFT JOIN ccUserView u ON A.[user_id] = u.[user_id]
    left join timeDetailAgent as atgStatus on atgStatus.userId=A.user_id and atgStatus.timegroup=A.timegroup
    LEFT JOIN inboundCount inCount ON A.timegroup = inCount.timegroup AND A.User_Id = inCount.userId
    left join outboundCount outTime ON outTime.timegroup = A.timegroup AND outTime.userId = A.User_id
        
END;
'
    EXEC(@sql)

    set @process = 'alter SP ccspRepAgentSummary DELETE RepAgentSummary WHERE DATE BETWEEN @from AND @to;'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepAgentSummary] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()))

IF @to IS NULL
    SELECT @to = GETDATE()

if(@to = convert(datetime,convert(varchar(11),getdate(),121)+''03:00:00'',121)) AND @from = DATEADD(dd,-1,@to)
BEGIN   
    select @from = convert(datetime,convert(varchar(11),@from))
END

IF @action = 1
BEGIN
        
    DELETE RepAgentSummary WHERE DATE BETWEEN @from AND @to;
    DELETE RepAgentSummary_VersionAmatech WHERE DATE BETWEEN @from  AND @to;
    
    ;
    WITH AgentSession
    AS (
        SELECT dbo.getdaygroup(loginTime) AS [date], userId, min([login]) AS [login], [user] AS [user], MIN(loginTime) AS dateLogin, MAX(logoutTime) AS logout, SUM(sessionTimeSeconds) AS sessionTime
        FROM RepAgentSession
        WHERE dbo.getdaygroup(loginTime) BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(logintime), userId, [user]
        ),
        -------------OUT -------------------
    dataCallsOut
    AS (
        SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
        FROM tmpTimesOutboundData
        where cal_manual in (0,2,3)
        GROUP BY cal_id, statusCall_id
        ), dataCallsOutByDay
    AS (
        SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogOut, SUM(tnotes) tNotesOut, sum(nabnd_xfer) nabnd_xfer
        , sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
        , SUM(txfer)  txferOut, SUM(tring)  tringOut
        FROM tmpTimesOutboundData
        where cal_manual in (0,2,3)
        GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
        ), tmpCallout
    AS (
        SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifOut
        , isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallOut
        , isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallOut
        , sum(tDialogOut) AS tDialogOut, sum(tNotesOut) AS tNotesOut, sum(nabnd_xfer) abnd_xfer, sum(nabnd_ring) abnd_ring
        , sum(nabnd_dialog) abnd_dialog, [date]
        , SUM(txferOut)  txferOut, SUM(tringOut)  tringOut
        FROM dataCallsOutByDay A
        INNER JOIN dataCallsOut B
            ON A.cal_id = B.cal_id
        GROUP BY [date], User_id
        ),
        ------------- IN -------------------
    dataCallsIn
    AS (
        SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
        FROM tmpTimesInboundData
        GROUP BY cal_id, statusCall_id
        ), dataCallsInByDay
    AS (
        SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogIn, SUM(tnotes) tNotesIn
        , sum(nabnd_xfer) nabnd_xfer, sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
        , SUM(txfer)  txferIn, SUM(tring)  tringIn
        FROM tmpTimesInboundData
        GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
        ), tmpCallIn
    AS (
        SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifIn
        , isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallIn
        , isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallIn
        , sum(tDialogIn) AS tDialogIn, sum(tNotesIn) AS tNotesIn, sum(nabnd_xfer) abnd_xfer
        , sum(nabnd_ring) abnd_ring, sum(nabnd_dialog) abnd_dialog, [date]
        , SUM(txferIn)  txferIn, SUM(tringIn)  tringIn
        FROM dataCallsInByDay A
        INNER JOIN dataCallsIn B
            ON A.cal_id = B.cal_id
        GROUP BY [date], User_id
        ), RepDetail
    AS (
        SELECT r.userId, SUM(r.timeSeconds) AS notReady, dbo.getdaygroup(r.DATE) AS daygroup
        FROM RepAgentNotReady r with(nolock)
        WHERE r.DATE BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(r.DATE), r.userId
        )
    ,notReadyDay as(
    SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(r.DATE) AS daygroup
        ,descripcion_time,descripcion,tiponotreadyId
        FROM RepAgentNotReady r with(nolock)
        WHERE r.DATE BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(r.DATE), r.userId,descripcion,descripcion_time,tiponotreadyId
    ), RepAgentGIGroup as(
        SELECT dbo.getdaygroup([date]) AS [date], userId, SUM(tav) AS tav
        , SUM(tunknown) AS tunknown
        , SUM(tother) AS tother
        , SUM(tprob) AS tprob
        , SUM(tChatting) AS tChatting       
        , SUM(tundefined) AS tundefined
        , SUM([tManual]) AS [tManual]
        FROM RepAgentGI
        WHERE [date] BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup([date]), userId
    )

    INSERT INTO RepAgentSummary (date,login,[user],sessionTime,loginMktTime,logoutMktTime,callTengaged,ndTime,NCallsOut,NCallsIn,NCallsCorta,NAtend,NNoCalif
    ,Available,avgCallTengaged,twrapup,userId,TypeNotReady,descripcion,descripcion_time,time,transferStatus,ringingTime,unknownStatus,otherStatus,failureStatus
    ,chatTengaged,undefinedTime,dialingStatus)
    SELECT A.[date], A.[login], A.[user], A.sessionTime, A.dateLogin AS loginMktTime
    , A.logout AS logoutMktTime
    , isnull(co.tDialogOut, 0) + isnull(ci.tDialogIn, 0) callTengaged
    , ISNULL(r.notready, 0) AS ndTime, isnull(co.AttendedCallOut, 0) AS NCallsOut, isnull(ci.AttendedCallIn, 0) AS NCallsIn
    , ISNULL(co.abnd_xfer, 0) + isnull(co.abnd_ring, 0) + isnull(co.abnd_ring, 0) + isnull(ci.abnd_xfer, 0) + isnull(ci.abnd_ring, 0) + isnull(ci.abnd_ring, 0) AS NCallsCorta
    , ISNULL(co.NotAttendedCallOut, 0) + ISNULL(ci.NotAttendedCallIn, 0) AS NAtend
    , ISNULL(ci.NoCalifIn, 0) + ISNULL(co.NoCalifOut, 0) AS NNoCalif    
    , ISNULL(AgtGI.tav, 0) AS Available
        ,ISNULL(    
        (   ISNULL(co.tDialogOut, 0) + ISNULL(co.tNotesOut, 0) + ISNULL(ci.tDialogIn, 0) + ISNULL(ci.tNotesIn, 0) )
            /
         nullif(isnull(co.AttendedCallOut,0) + isnull(ci.AttendedCallIn,0),0)
        , 0) AS avgCallTengaged
        
        ,ISNULL(co.tNotesOut, 0) + ISNULL(ci.tNotesIn, 0) AS twrapup, A.userId AS userId
        , notReady.TipoNotReadyId
        , notReady.descripcion
        , notReady.descripcion_time
        , notReady.timeSeconds
        , ISNULL(co.txferOut, 0) + ISNULL(ci.txferIn, 0) AS transferStatus
        , ISNULL(co.tringOut, 0) + ISNULL(ci.tringIn, 0) AS ringingTime
        , ISNULL(AgtGI.tunknown, 0) unknownStatus
        , ISNULL(AgtGI.tother, 0) otherStatus
        , ISNULL(AgtGI.tprob, 0) failureStatus
        , ISNULL(AgtGI.tChatting, 0) chatTengaged
        , ISNULL(AgtGI.tundefined, 0) undefinedTime
        , ISNULL(AgtGI.tManual, 0) dialingStatus
    FROM AgentSession A
    LEFT JOIN tmpCallout co ON A.DATE = co.DATE AND A.userId = co.userId
    LEFT JOIN tmpCallIn ci  ON A.DATE = ci.DATE AND A.userId = ci.userId
    LEFT JOIN RepDetail r   ON r.daygroup = A.DATE AND A.userId = r.userId
    inner join notReadyDay notReady on notReady.userId=A.userId and notReady.daygroup=A.date
    left join RepAgentGIGroup AgtGI on AgtGI.date=A.date and AgtGI.userId=A.userId
    
    order by A.[date],A.userId

END'
    EXEC(@sql)
   
    -------------------------------------- End hotfix/125.20231211.0.17 --------------------------------------

    -------------------------------------- Begin hotfix/125.20231211.0.20 --------------------------------------
    set @process = 'alter SP ccSpCreateIndexReport'
    set @sql='ALTER PROCEDURE [dbo].[ccSpCreateIndexReport]  
AS
BEGIN
    SET NOCOUNT ON;

declare @tIndexMerge table(id int identity,tableName varchar(255),status bit)
declare @sql nvarchar(max),@tableName varchar(255),@id int
declare @column varchar(255),@indexName varchar(255)

insert into @tIndexMerge(tableName,status)
SELECT Art.name tableName,0 [status] FROM dbo.sysmergepublications P
inner join dbo.sysmergearticles Art on Art.pubid=P.pubid

set @column=''rowguid''

while exists(select 1 from @tIndexMerge where status=0) begin
    select top 1 @tableName=tableName,@id=id from @tIndexMerge where status=0 
    set @indexName=N''MSmerge_index_'' + @tableName
    set @sql=''if not exists(SELECT 1 FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.is_hypothetical = 0 -- Excluir índices hipotéticos
    and i.name = @tableName
    and c.name=@column
)
and not exists (select * from sys.indexes where name = @indexName and object_id = OBJECT_ID(@tableName)) 
and exists (select * from sys.columns where name = @column and Object_ID = Object_ID(@tableName))
begin
CREATE UNIQUE NONCLUSTERED INDEX [''+@indexName+''] on [dbo].[''+@tableName+''](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
    ''
    EXEC sp_executesql @sql, 
    N''@tableName varchar(255),@column varchar(255),@indexName varchar(255)'', 
    @tableName = @tableName, 
    @indexName = @indexName,
    @column = @column;
    --print @sql
    update @tIndexMerge set status=1 where @id=id
end


/****************************INDICES PARA REPORTES *******************************/

if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesDia_4'' and object_id = OBJECT_ID(N''ccLogAgentesDia''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_4
ON [dbo].[ccLogAgentesDia] ([User_id],[fecha])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesDia_6'' and object_id = OBJECT_ID(N''ccLogAgentesDia''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_6
ON [dbo].[ccLogAgentesDia] ([fecha])
INCLUDE ([User_id],[TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesNotReady_5'' and object_id = OBJECT_ID(N''cclogagentesnotready''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesNotReady_5
ON [dbo].[cclogagentesnotready] ([fecha])
INCLUDE ([User_id],[TipoNotReady_id],[tStatus])
end

    
if not exists (select * from sys.indexes where name = N''IX_ccLogLogin_6'' and object_id = OBJECT_ID(N''ccloglogin''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogLogin_6
ON [dbo].[ccloglogin] ([fecha])
INCLUDE ([User_id],[Extension],[TipoMov])
end

    
if not exists (select * from sys.indexes where name = N''IX_ccLogTransfers_3'' and object_id = OBJECT_ID(N''ccLogtransfers''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogTransfers_3
ON [dbo].[ccLogtransfers] ([fechaFin])
INCLUDE ([cal_id],[tipo],[modo],[destino],[tAntesXfer],[tDespuesXfer])
end

if not exists (select * from sys.indexes where name = N''IX_ccoCallsOut13'' and object_id = OBJECT_ID(N''ccoCallsOut''))
begin
   CREATE NONCLUSTERED INDEX IX_ccoCallsOut13
ON [dbo].[ccoCallsOut] ([cal_Inicio])
INCLUDE ([cal_id],[cal_telefono],[cal_puerto],[cam_id],[User_id],[statusCall_id],[calif_id],[cal_tDialog],[cal_tNotas],[cal_tXfer],[cal_tRing],[cal_manual],[cal_tMoh],[cal_whoHung],[cal_twait])
end


if not exists (select * from sys.indexes where name = N''IX_ccoCallsOut_14'' and object_id = OBJECT_ID(N''ccoCallsOut''))
begin
   CREATE NONCLUSTERED INDEX IX_ccoCallsOut_14
ON [dbo].[ccoCallsOut] ([cal_Inicio],[cal_manual])
INCLUDE ([cal_id],[callout_id],[cal_telefono],[cam_id],[User_id],[calif_id],[cal_tDialog],[cal_tNotas],[cal_tXfer],[cal_tRing],[califSub_id])
end 


    
if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACION_11'' and object_id = OBJECT_ID(N''RIA_GRABACION''))
begin
CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_11
ON [dbo].[RIA_GRABACION] ([tipo_llamada],[cal_id])
INCLUDE ([grab_id])
end

if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACION_10'' and object_id = OBJECT_ID(N''RIA_GRABACION''))
begin
CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_10
ON [dbo].[RIA_GRABACION] ([tipo_llamada])
INCLUDE ([cal_id])
end

    
if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesDia_Dialog'' and object_id = OBJECT_ID(N''ccLogAgentesDia_Dialog''))
begin
CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_Dialog
ON [dbo].[ccLogAgentesDia_Dialog] ([fecha_Dialog])
INCLUDE ([User_id],[fecha_Calc_ms])
end


if not exists (select * from sys.indexes where name = N''IX_ccoCallsOutSource_1'' and object_id = OBJECT_ID(N''ccoCallsOutSource''))
begin
CREATE NONCLUSTERED INDEX IX_ccoCallsOutSource_1
ON [dbo].[ccoCallsOutSource] ([cal_fechaDial],[Region])
end

if not exists (select * from sys.indexes where name = N''IX_ccoLogDials_6'' and object_id = OBJECT_ID(N''ccoLogDials''))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_6
ON [dbo].[ccoLogDials] ([fecha])
INCLUDE ([cam_id],[tipoResDial_id],[Telefono],[cal_id],[disconnectCause],[answerbit],[tipoLlamada_id])
end

    
if not exists (select * from sys.indexes where name = N''IX_ccoLogDials_7'' and object_id = OBJECT_ID(N''ccoLogDials''))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_7
ON [dbo].[ccoLogDials] ([cal_id])
INCLUDE ([tipoResDial_id])
end


if not exists (select * from sys.indexes where name = N''IX_ccoLogDials_8'' and object_id = OBJECT_ID(N''ccoLogDials''))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_8
ON [dbo].[ccoLogDials] ([fecha],[cal_id])
INCLUDE ([tipoResDial_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_7'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
   CREATE NONCLUSTERED INDEX IX_ccCallsIn_7
ON [dbo].[ccCallsIn] ([Inbound_id],[cal_Inicio])
INCLUDE ([cal_id],[dni_id],[cal_ANI],[User_id],[statusCall_id],[calif_id],[cal_que],[cal_tDialog],[cal_tNotas],[cal_tWait],[cal_tXfer],[cal_tRing],[cal_Xfer],[cal_tMoh],[cal_whoHung],[califSub_id])

end

if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_8'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_8
ON [dbo].[ccCallsIn] ([IVR_id])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_9'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_9
ON [dbo].[ccCallsIn] ([cal_Inicio])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_tmpSessionTimeGroup_1'' and object_id = OBJECT_ID(N''tmpSessionTimeGroup''))
begin
CREATE NONCLUSTERED INDEX IX_tmpSessionTimeGroup_1
ON [dbo].[tmpSessionTimeGroup] ([user_id])
INCLUDE ([timegroup],[tlog])
end

   
if not exists (select * from sys.indexes where name = N''IX_tmpccLogAgentesDia_2'' and object_id = OBJECT_ID(N''tmpccLogAgentesDia''))
begin
CREATE NONCLUSTERED INDEX IX_tmpccLogAgentesDia_2
ON [dbo].[tmpccLogAgentesDia] ([userId],[timeGroup])
INCLUDE ([TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N''IX_tmpTimesInboundData_1'' and object_id = OBJECT_ID(N''tmpTimesInboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_1
ON [dbo].[tmpTimesInboundData] ([statusCall_id])
INCLUDE ([timegroup],[Inbound_id],[nabnd],[tque],[txfer],[tring])
end

    
if not exists (select * from sys.indexes where name = N''IX_tmpTimesInboundData_2'' and object_id = OBJECT_ID(N''tmpTimesInboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_2
ON [dbo].[tmpTimesInboundData] ([cal_id])
INCLUDE ([Inbound_id],[User_id])
end


if not exists (select * from sys.indexes where name = N''IX_tmpTimesOutboundData_1'' and object_id = OBJECT_ID(N''tmpTimesOutboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_1
ON [dbo].[tmpTimesOutboundData] ([timegroup],[cal_id])
INCLUDE ([User_id])
end
    
if not exists (select * from sys.indexes where name = N''IX_tmpTimesOutboundData_2'' and object_id = OBJECT_ID(N''tmpTimesOutboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_2
ON [dbo].[tmpTimesOutboundData] ([cal_manual])
INCLUDE ([timegroup],[User_id],[nabnd_xfer],[nabnd_ring],[tdialog],[tnotes],[cal_id])
end
/**************************** INDICES Reportes *******************************/



set @column=''date''
delete from @tIndexMerge

insert into @tIndexMerge(tableName,status)
SELECT     
    t.TABLE_NAME,0
FROM 
    INFORMATION_SCHEMA.COLUMNS c
INNER JOIN 
    INFORMATION_SCHEMA.TABLES t 
    ON c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
WHERE 
    t.TABLE_NAME LIKE ''Rep%''   -- Las tablas que comienzan con ''Rep''
    AND c.COLUMN_NAME = ''date'' -- Que contienen una columna llamada ''date''
    AND t.TABLE_TYPE = ''BASE TABLE'' -- Solo tablas (no vistas)
ORDER BY 
    t.TABLE_SCHEMA, t.TABLE_NAME;


while exists(select 1 from @tIndexMerge where status=0) begin
    select top 1 @tableName=tableName,@id=id from @tIndexMerge where status=0 
    set @indexName=N''IX_''+ @tableName+''_date'' 
    set @sql=''if not exists(SELECT 1 FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.is_hypothetical = 0 -- Excluir índices hipotéticos
    and i.name = @tableName
    and c.name=@column
)
and not exists (select * from sys.indexes where name = @indexName and object_id = OBJECT_ID(@tableName)) 
and exists (select * from sys.columns where name = @column and Object_ID = Object_ID(@tableName))
begin
CREATE NONCLUSTERED INDEX ''+@indexName+''
ON [dbo].[''+@tableName+''] ([date])
end
    ''
    EXEC sp_executesql @sql, 
    N''@tableName varchar(255),@column varchar(255),@indexName varchar(255)'', 
    @tableName = @tableName, 
    @indexName = @indexName,
    @column = @column;
    print @sql
    update @tIndexMerge set status=1 where @id=id
end
    
if not exists (select * from sys.indexes where name = N''IX_RepAgentNotReadyDet_2'' and object_id = OBJECT_ID(N''RepAgentNotReadyDet''))
begin
CREATE NONCLUSTERED INDEX IX_RepAgentNotReadyDet_2
ON [dbo].[RepAgentNotReadyDet] ([tiponotreadyId],[startDate])
INCLUDE ([userId],[status],[statusTime])
end

 

end'
    EXEC(@sql)

    set @process = 'drop index IX_RepOutDialDetail_3,IX_RepInSubDispositions_1,IX_RepInCallsDetail_2,IX_RepOutSubDispositions_1,IX_RepAgentGI_1'
    set @sql='if exists (select * from sys.indexes where name = N''IX_RepOutDialDetail_3'' and object_id = OBJECT_ID(N''RepOutDialDetail''))
begin
    drop index IX_RepOutDialDetail_3 on RepOutDialDetail
end

if exists (select * from sys.indexes where name = N''IX_RepInSubDispositions_1'' and object_id = OBJECT_ID(N''RepInSubDispositions''))
begin
    drop index IX_RepInSubDispositions_1 on RepInSubDispositions
end
if exists (select * from sys.indexes where name = N''IX_RepInCallsDetail_2'' and object_id = OBJECT_ID(N''RepInCallsDetail''))
begin
    drop index IX_RepInCallsDetail_2 on RepInCallsDetail
end
if exists (select * from sys.indexes where name = N''IX_RepOutSubDispositions_1'' and object_id = OBJECT_ID(N''RepOutSubDispositions''))
begin
    drop index IX_RepOutSubDispositions_1 on RepOutSubDispositions
end

if exists (select * from sys.indexes where name = N''IX_RepAgentGI_1'' and object_id = OBJECT_ID(N''RepAgentGI''))
begin
    drop index IX_RepAgentGI_1 on RepAgentGI
end'
    EXEC(@sql)

    set @process = 'alter FUNCTION fn_RIASplitDelimited'
    set @sql='ALTER FUNCTION [dbo].[fn_RIASplitDelimited]
(   
    @List NVARCHAR(max),
    @SplitOn NVARCHAR(1)
)
RETURNS @RtnValue TABLE (
    Id INT IDENTITY(1,1),
    Value NVARCHAR(255)
)
AS
BEGIN
    DECLARE @Pos INT = 1
    DECLARE @NextPos INT
    DECLARE @Fragment NVARCHAR(255)

    IF LEN(@List) = 0  -- Verificar si la lista está vacía y salir
        RETURN

    WHILE @Pos > 0
    BEGIN
        SET @NextPos = CHARINDEX(@SplitOn, @List, @Pos)
        
        IF @NextPos > 0
        BEGIN
            SET @Fragment = SUBSTRING(@List, @Pos, @NextPos - @Pos)
            IF LEN(@Fragment) > 0  -- Solo insertar si el fragmento tiene longitud
            BEGIN
                INSERT INTO @RtnValue (Value)
                VALUES (LTRIM(RTRIM(@Fragment)))
            END
            SET @Pos = @NextPos + 1
        END
        ELSE
        BEGIN
            SET @Fragment = SUBSTRING(@List, @Pos, LEN(@List) - @Pos + 1)
            IF LEN(@Fragment) > 0
            BEGIN
                INSERT INTO @RtnValue (Value)
                VALUES (LTRIM(RTRIM(@Fragment)))
            END
            SET @Pos = 0
        END
    END

    RETURN
END'
    EXEC(@sql)

    set @process = ' drop index IX_RepOutDialDetail_3,IX_RepInSubDispositions_1,IX_RepInCallsDetail_2,IX_RepOutSubDispositions_1,IX_RepAgentGI_1'
    set @sql='if exists (select * from sys.indexes where name = N''IX_RepOutDialDetail_3'' and object_id = OBJECT_ID(N''RepOutDialDetail''))
begin
    drop index IX_RepOutDialDetail_3 on RepOutDialDetail
end

if exists (select * from sys.indexes where name = N''IX_RepInSubDispositions_1'' and object_id = OBJECT_ID(N''RepInSubDispositions''))
begin
    drop index IX_RepInSubDispositions_1 on RepInSubDispositions
end
if exists (select * from sys.indexes where name = N''IX_RepInCallsDetail_2'' and object_id = OBJECT_ID(N''RepInCallsDetail''))
begin
    drop index IX_RepInCallsDetail_2 on RepInCallsDetail
end
if exists (select * from sys.indexes where name = N''IX_RepOutSubDispositions_1'' and object_id = OBJECT_ID(N''RepOutSubDispositions''))
begin
    drop index IX_RepOutSubDispositions_1 on RepOutSubDispositions
end

if exists (select * from sys.indexes where name = N''IX_RepAgentGI_1'' and object_id = OBJECT_ID(N''RepAgentGI''))
begin
    drop index IX_RepAgentGI_1 on RepAgentGI
end
'
    EXEC(@sql)

    set @process = 'alter SP ccspTmpTimesccLogtransfers with(nolock,index(IX_ccLogTransfers_3)) '
    set @sql='ALTER PROCEDURE [dbo].[ccspTmpTimesccLogtransfers] @from AS SMALLDATETIME, @to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#tempccLogtransfers'', N''U'') IS NOT NULL
    DROP TABLE #tempccLogtransfers
IF OBJECT_ID(N''tempdb..#tempccLogtransfers2'', N''U'') IS NOT NULL
    DROP TABLE #tempccLogtransfers2

IF NOT EXISTS (
        SELECT *
        FROM sys.tables
        WHERE name = ''TmpTimesccLogtransfers''
        )
BEGIN
    CREATE TABLE TmpTimesccLogtransfers (
    dateIni DATETIME NOT NULL, dateEnd DATETIME NOT NULL, callId INT NOT NULL, tipo TINYINT NULL, modo TINYINT NULL
    , destino VARCHAR(100) NOT NULL, tAntesXfer INT, tDespuesXfer INT   
    , timegroup DATETIME NOT NULL
    ,timegroup_next DATETIME NOT NULL
    )
END
ELSE
BEGIN
    TRUNCATE TABLE TmpTimesccLogtransfers
        --drop table TmpTimesccLogtransfers
END

CREATE TABLE #tempccLogtransfers (
    dateIni DATETIME NOT NULL, dateEnd DATETIME NOT NULL, callId INT NOT NULL, tipo TINYINT NULL, modo TINYINT NULL
    , destino VARCHAR(100) NOT NULL, tAntesXfer INT, tDespuesXfer INT
    ,dateStarBeforetTransf DATETIME NOT NULL    
    , timegroup DATETIME NOT NULL
    ,timegroup_next DATETIME NOT NULL
    )
    ;

with logtransfer as(

SELECT DATEADD(ss, - tAntesXfer - tDespuesXfer, fechaFin)as  dateIni, fechaFin  as dateEnd
    , cal_id callId, tipo, modo, destino, tAntesXfer, tDespuesXfer
    , dbo.GetTimeGroup(DATEADD(ss, - tAntesXfer - tDespuesXfer, fechaFin), 0) AS timegroup
    , dbo.GetTimeGroup(fechaFin, 1) AS timegroup_next
FROM ccLogtransfers with(nolock,index(IX_ccLogTransfers_3))
WHERE fechaFin BETWEEN @from        AND @to

)

INSERT INTO #tempccLogtransfers
select dateIni,dateEnd,callId, tipo, modo, destino, tAntesXfer, tDespuesXfer
,dateadd(ss,tAntesXfer,dateIni) as dateStarBeforetTransf
,timegroup,timegroup_next
from logtransfer

select * into #tempccLogtransfers2 from #tempccLogtransfers where datediff(mi,timegroup,timegroup_next)>15
delete #tempccLogtransfers where datediff(mi,timegroup,timegroup_next) > 15

insert into TmpTimesccLogtransfers
select dateIni,dateEnd,callId
    ,tipo, modo, destino
    ,dbo.TimeInterval(th.start, th.stop, dateIni, dateStarBeforetTransf) AS tAntesXfer
    ,dbo.TimeInterval(th.start, th.stop, dateStarBeforetTransf, dateEnd) AS tDespuesXfer    
,th.start as timegroup,th.stop as timegroup_next
    from #tempccLogtransfers2 t
    inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
    where  datediff(ss,th.start,timegroup_next)>0
union all
select dateIni,dateEnd,callId   ,tipo, modo, destino,
tAntesXfer,tDespuesXfer,timegroup,timegroup_next
from #tempccLogtransfers

IF OBJECT_ID(N''tempdb..#tempccLogtransfers'', N''U'') IS NOT NULL
    DROP TABLE #tempccLogtransfers
IF OBJECT_ID(N''tempdb..#tempccLogtransfers2'', N''U'') IS NOT NULL
    DROP TABLE #tempccLogtransfers2
'
    EXEC(@sql)

    set @process = 'alter sp ccsptmpTimesHoldIn with(NOLOCK,index(IX_ccCallsIn_9))'
    set @sql='ALTER PROCEDURE [dbo].[ccsptmpTimesHoldIn] @from AS SMALLDATETIME
    ,@to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#hold'', N''U'') IS NOT NULL
    DROP TABLE #hold

IF OBJECT_ID(N''tempdb..tempccHoldSession'', N''U'') IS NOT NULL
    DROP TABLE #tempccHoldSession

IF OBJECT_ID(N''tempdb..#holdMayores2'', N''U'') IS NOT NULL
    DROP TABLE #holdMayores2

IF NOT EXISTS (
        SELECT *
        FROM sys.tables
        WHERE name = ''tmpTimesHoldIn''
        )
BEGIN
    CREATE TABLE tmpTimesHoldIn (
        inbound_id INT NOT NULL
        ,userId INT NOT NULL
        ,tiempohold INT NOT NULL
        ,timegroup DATETIME
        ,timegroup_next DATETIME
        )
END
ELSE
BEGIN
    TRUNCATE TABLE tmpTimesHoldIn
        --drop table tmpTimesHoldIn
END

CREATE TABLE #hold (
    Fila INT
    ,[userId] INT NOT NULL
    ,[dateStart] [datetime] NOT NULL
    ,[dateEnd] [datetime] NOT NULL
    ,call_id INT NOT NULL
    ,inbound_id INT NOT NULL
    ,marca INT NOT NULL
    ,Tipo_marca INT NOT NULL
    ,Tipo_llamada INT NOT NULL
    ,[timegroup] [datetime] NOT NULL
    ,[timegroup_next] [datetime] NOT NULL
    ,[time_dialog] [datetime] NOT NULL
    ,[time_notes] [datetime] NOT NULL
    ,[time_hold] [datetime] NOT NULL
    )

CREATE TABLE #tempccHoldSession (
    [fila] INT NOT NULL
    ,[call_id] [int] NOT NULL
    ,[userId] INT NOT NULL
    ,[inbound_id] [int] NOT NULL
    ,[hold] [datetime] NOT NULL
    ,[unhold] [datetime] NULL
    ,[Tipo_marca] [int] NOT NULL
    ,[timegroup] [datetime] NOT NULL
    ,[timegroup_next] [datetime] NOT NULL PRIMARY KEY (
        fila
        ,call_id
        )
    )

CREATE TABLE #holdMayores2 (
    call_id INT NOT NULL
    ,[userId] INT NOT NULL
    ,inbound_id INT NOT NULL
    ,hold [datetime] NOT NULL
    ,[unhold] [datetime] NOT NULL
    ,Tipo_marca INT NOT NULL
    ,tiempoHold INT NOT NULL
    ,[timegroup] [datetime] NOT NULL
    ,[timegroup_next] [datetime] NOT NULL
    );

WITH timeHold
AS (
    SELECT User_id AS userId
        ,cal_Inicio AS [dateStart]
        ,dateadd(ss, cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas, cal_Inicio) AS [dateEnd]
        ,cal_id AS cal_id
        ,inbound_id AS inbound_id
        ,isnull(h.marca, 0) AS Marca
        ,CASE WHEN (h.tipo_marca > 0) THEN h.tipo_marca ELSE 0 END AS Tipo_marca
        ,isnull(tipo_llamada, 0) AS Tipo_llamada
        ,dbo.GetTimeGroup(cal_Inicio, 0) AS timegroup
        ,dbo.GetTimeGroup(dateadd(ss, cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas, cal_Inicio), 1) AS timegroup_next
        ,DATEADD(ss, isnull(cal_twait + cal_txfer + cal_tring, 0), cal_inicio) AS time_dialog
        ,DATEADD(ss, isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog, 0), cal_inicio) AS time_notes
        ,DATEADD(ss, isnull(cal_twait + cal_txfer + cal_tring + marca, 0), cal_Inicio) AS time_hold
    FROM cccallsin i with(NOLOCK,index(IX_ccCallsIn_9))
    LEFT JOIN RiaMarkHold h(NOLOCK) ON i.cal_id = h.call_id AND h.tipo_llamada = 1
    WHERE cal_Inicio BETWEEN @from
            AND @to
    )
INSERT INTO #hold
SELECT ROW_NUMBER() OVER (
        PARTITION BY cal_id ORDER BY time_hold
            ,tipo_marca
        ) Fila
    ,*
FROM timeHold a
WHERE time_hold >= @from
    AND time_hold <= @to

INSERT INTO #tempccHoldSession
SELECT A.Fila
    ,A.call_id
    ,a.userId
    ,a.inbound_id
    ,A.time_hold hold
    ,isnull(S.time_hold, a.time_notes) unhold
    ,a.Tipo_marca Tipo_marca
    ,a.timegroup timegroup
    ,a.timegroup_next timegroup_next
FROM #hold A
LEFT JOIN #hold S
    ON A.Fila = S.Fila - 1
        AND A.call_id = S.call_id
        AND A.tipo_marca = 1
        AND S.tipo_marca = 0
WHERE A.tipo_llamada = 1
ORDER BY hold

SELECT ths.call_id
    ,ths.userId
    ,ths.inbound_id
    ,ths.hold
    ,ths.unhold
    ,ths.Tipo_marca
    ,[dbo].TimeInterval(th.[start], th.[stop], ths.hold, ths.unhold) AS tiempohold
    ,ths.timegroup
    ,ths.timegroup_next
INTO #tiempoHold
FROM #tempccHoldSession ths
INNER JOIN TmpTimesInterval th
    ON (
            ths.timegroup > th.Start
            AND ths.timegroup < th.stop
            )
        OR th.Start BETWEEN ths.timegroup
            AND ths.timegroup_next
WHERE [dbo].TimeInterval(th.[start], th.[stop], ths.hold, ths.unhold) > 0
    AND Tipo_marca = 1
    AND th.Start BETWEEN @from
        AND @to

INSERT INTO #holdMayores2
SELECT *
FROM #tiempoHold
WHERE datediff(mi, timegroup, timegroup_next) > 15

DELETE #tiempoHold
WHERE datediff(mi, timegroup, timegroup_next) > 15

INSERT INTO #tiempoHold
SELECT call_id
    ,userId AS userId
    ,inbound_id AS inbound_id
    ,hold
    ,unhold
    ,Tipo_marca
    ,[dbo].TimeInterval(th.[start], th.[stop], hold, unhold) AS tiempohold
    ,th.[start] AS timegroup
    ,th.[stop] AS timegroup_next
FROM #holdMayores2 t
INNER JOIN TmpTimesInterval th
    ON (
            t.timegroup > th.Start
            AND t.timegroup < th.stop
            )
        OR th.Start BETWEEN t.timegroup
            AND t.timegroup_next
WHERE [dbo].TimeInterval(th.[start], th.[stop], hold, unhold) > 0
    AND th.Start BETWEEN @from
        AND @to

INSERT INTO tmpTimesHoldIn
SELECT inbound_id
    ,userId
    ,sum(tiempohold) AS tiempohold
    ,timegroup
    ,timegroup_next
FROM #tiempoHold
WHERE tiempoHold > 0
    AND Tipo_marca = 1
GROUP BY userId
    ,inbound_id
    ,timegroup
    ,timegroup_next

IF OBJECT_ID(N''tempdb..#hold'', N''U'') IS NOT NULL
    DROP TABLE #hold

IF OBJECT_ID(N''tempdb..tempccHoldSession'', N''U'') IS NOT NULL
    DROP TABLE #tempccHoldSession

IF OBJECT_ID(N''tempdb..#holdMayores2'', N''U'') IS NOT NULL
    DROP TABLE #holdMayores2
'
    EXEC(@sql)

    set @process = ''
    set @sql=''
    EXEC(@sql)

    -------------------------------------- End hotfix/125.20231211.0.20 --------------------------------------
-------------------------------------- BEGIN ISAAC hotfix/125.20231211.0.20 --------------------------------------
SET @process = 'Delete view RepViewSummary'
SET @sql = '
IF EXISTS (SELECT * FROM sys.views WHERE name = N''RepViewSummary'')
BEGIN
    DROP VIEW RepViewSummary;
END'
EXEC(@sql)

SET @process = 'Create view RepViewSummary'
SET @sql = '
CREATE VIEW RepViewSummary AS
select 
[date]
,[login]
,[user]
,sessionTime
,loginMktTime
,logoutMktTime
,0 callTengaged
,ndTime
,NCallsOut
,NCallsIn
,NCallsCorta
,NAtend
,NNoCalif
,Available
,0 avgCallTengaged
,twrapup
,userId
,0 TypeNotReady
,'''' descripcion
,''_Time'' descripcion_time
,0 [time]
,0 transferStatus
,0 ringingTime
,0 unknownStatus
,0 otherStatus
,0 failureStatus
,0 chatTengaged
,0 undefinedTime
,0 dialingStatus
--,null TipoReadyAuxiliarId
--,'' auxiliarRedy_descripcion
--,'' descripcion_auxiliarRedyTime_time
--,0 auxiliarRedyTime
from RepAgentSummary_VersionAmatech
union
select date
,login
,[user]
,sessionTime
,loginMktTime
,logoutMktTime
,callTengaged
,ndTime
,NCallsOut
,NCallsIn
,NCallsCorta
,NAtend
,NNoCalif
,Available
,avgCallTengaged
,twrapup
,userId
,TypeNotReady
,descripcion
,descripcion_time
,time
,transferStatus
,ringingTime
,unknownStatus
,otherStatus
,failureStatus
,chatTengaged
,undefinedTime
,dialingStatus
--,TipoReadyAuxiliarId
--,auxiliarRedy_descripcion
--,descripcion_auxiliarRedyTime_time
--,auxiliarRedyTime
from RepAgentSummary
'
EXEC(@sql)
-------------------------------------- END ISAAC hotfix/125.20231211.0.20 --------------------------------------

---------------------------------------BEGIN Jesus Gallardo hotfix/125.20231211.0.22---------------------------------------------------------
    set @process = 'CW-9070 Rename Column RepEmailDetail.inboundId'
    set @sql='IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(''RepEmailDetail'')
      AND name = ''inbounid''
)
BEGIN
    EXEC sp_rename ''RepEmailDetail.inbounid'', ''inboundId'', ''COLUMN'';
END
'
    EXEC(@sql)

    set @process = 'ALTER SP ccspRepOutDials Correcion obtener WG'
    set @Sql='ALTER PROCEDURE [dbo].[ccspRepOutDials]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null 
    select @to = getdate()

if @action = 1 
begin
    declare @total decimal(10,2)
        
        

    select @total = count(*) from ccologdials as a WITH(NOLOCK, INDEX(IX_ccoLogDials_8))
    inner join ccTipoResultadoDial as b (NOLOCK) on (a.tipoResDial_id = b.tipoResDial_id)
    where fecha >= @from and fecha < @to        
    and cal_id is not null
        
    delete from RepOutDials where date >= @from AND date < @to
        
        
    ;with tmpRepOutDials as(
    select  DATEADD(HOUR, DATEDIFF(HOUR, 0, fecha), 0) as fecha ,cal_id
    ,a.tipoResDial_id, descripcion,cam_id
    from ccologdials as a WITH(NOLOCK, INDEX(IX_ccoLogDials_8))
    inner join ccTipoResultadoDial as b (NOLOCK) on (a.tipoResDial_id = b.tipoResDial_id)
    where fecha >= @from and fecha < @to        
    and a.cal_id is not null
    )

    
    insert into RepOutDials

    select fecha as [date]      
    ,a.cam_id as campaignId, c.cam_descripcion as campaign
    , isnull(min(d.idwg),1) as workgroupId, isnull(min(wgname),'''') as workgroup, isnull(min(c.idarea),1) as areaId, isnull(min(areaname),'''') as area
        
    ,a.tipoResDial_id, descripcion,
    descripcion + ''_Count'' as descripcion_count,
    count(*) as count,
    descripcion + ''_Avg'' as descripcion_avg,
    convert(decimal(10,2), (count(*)/@total)*100.00) as avg,
    datepart(yyyy,fecha) AS [year],
    datepart(mm,fecha) as [month],
    datepart(dd,fecha) as [day],
    datepart(hh,fecha) as [hour],
    0 as [minutes]
    from  tmpRepOutDials as a
    left join ccCamps as c (NOLOCK) on (a.cam_id = c.cam_id)
    left join ccRIACampEspWG as d (NOLOCK) on a.cam_id = d.IdCampEsp and d.tipo = 1 
    left join ccRIACat_WorkGroup as e (NOLOCK) on (d.idwg = e.idwg)
    left join ccRIAAreaWorkGroup as f (NOLOCK) on (e.idwg = f.idwg)
    left join ccRIACat_Areas as g (NOLOCK) on (c.idarea = g.idarea)     
    group by fecha ,        
    a.cam_id, c.cam_descripcion, a.tipoResDial_id, descripcion  
    
end'
    
    EXEC(@Sql)

    set @process = ''
    set @sql=''
    EXEC(@sql)

---------------------------------------END Jesus Gallardo hotfix/125.20231211.0.22---------------------------------------------------------

	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
