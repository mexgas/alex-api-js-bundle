/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 121

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
SET @version = 121 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
select @actualVersion [@actualVersion], @version

IF @version >= @actualVersion 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	---------------------------------------BEGIN Jesus Gallardo hotfix/125.20230719.0.9---------------------------------------------------------
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

    set @process = 'DEV1-459 ALTER TABLE PublicationLowLoad.active'
    set @sql='if not exists (select * from sys.columns where name = N''active'' and Object_ID = Object_ID(N''PublicationLowLoad''))
begin
    ALTER TABLE PublicationLowLoad ADD active bit NULL;
end
'
    EXEC(@sql)

	 set @process = 'DEV1-459 CREATE TABLE [dbo].[ReportHighUse]'
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

    SET @process = 'Replication DROP PROCEDURE ccSpCreateIndexReport'
    SET @sql = 'CREATE PROCEDURE ccSpCreateIndexReport  
AS
BEGIN   
    SET NOCOUNT ON;
    if not exists (select * from sys.indexes where name = N''MSmerge_index_ccoLogDials'' and object_id = OBJECT_ID(N''ccoLogDials'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccoLogDials''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoLogDials] on [dbo].[ccoLogDials](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccLogAgentesDia'' and object_id = OBJECT_ID(N''ccLogAgentesDia'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccLogAgentesDia''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccLogAgentesDia] on [dbo].[ccLogAgentesDia](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_RiaMarkHold'' and object_id = OBJECT_ID(N''RiaMarkHold'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RiaMarkHold''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RiaMarkHold] on [dbo].[RiaMarkHold](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccoCallsOutSource'' and object_id = OBJECT_ID(N''ccoCallsOutSource'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccoCallsOutSource''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallsOutSource] on [dbo].[ccoCallsOutSource](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccoCallsPreviewData'' and object_id = OBJECT_ID(N''ccoCallsPreviewData'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccoCallsPreviewData''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallsPreviewData] on [dbo].[ccoCallsPreviewData](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_RegProcessPreviewRecord'' and object_id = OBJECT_ID(N''RegProcessPreviewRecord'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RegProcessPreviewRecord''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RegProcessPreviewRecord] on [dbo].[RegProcessPreviewRecord](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccoCallsOut'' and object_id = OBJECT_ID(N''ccoCallsOut'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccoCallsOut''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallsOut] on [dbo].[ccoCallsOut](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccCallsIn'' and object_id = OBJECT_ID(N''ccCallsIn'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccCallsIn''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCallsIn] on [dbo].[ccCallsIn](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_DataCallIn'' and object_id = OBJECT_ID(N''DataCallIn'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''DataCallIn''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_DataCallIn] on [dbo].[DataCallIn](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cctipocalifsubout'' and object_id = OBJECT_ID(N''cctipocalifsubout'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cctipocalifsubout''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalifsubout] on [dbo].[cctipocalifsubout](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cctipocalifsub'' and object_id = OBJECT_ID(N''cctipocalifsub'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cctipocalifsub''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalifsub] on [dbo].[cctipocalifsub](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cctiposubcalifrel'' and object_id = OBJECT_ID(N''cctiposubcalifrel'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cctiposubcalifrel''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctiposubcalifrel] on [dbo].[cctiposubcalifrel](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccCampsMovs'' and object_id = OBJECT_ID(N''ccCampsMovs'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccCampsMovs''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCampsMovs] on [dbo].[ccCampsMovs](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_telefonosConferencia'' and object_id = OBJECT_ID(N''telefonosConferencia'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''telefonosConferencia''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_telefonosConferencia] on [dbo].[telefonosConferencia](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_telefonosTransferencia'' and object_id = OBJECT_ID(N''telefonosTransferencia'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''telefonosTransferencia''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_telefonosTransferencia] on [dbo].[telefonosTransferencia](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_messageStatus'' and object_id = OBJECT_ID(N''messageStatus'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''messageStatus''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageStatus] on [dbo].[messageStatus](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccriacat_areas'' and object_id = OBJECT_ID(N''ccriacat_areas'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccriacat_areas''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriacat_areas] on [dbo].[ccriacat_areas](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccinboundagentes'' and object_id = OBJECT_ID(N''ccinboundagentes'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccinboundagentes''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccinboundagentes] on [dbo].[ccinboundagentes](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccriaareaworkgroup'' and object_id = OBJECT_ID(N''ccriaareaworkgroup'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccriaareaworkgroup''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriaareaworkgroup] on [dbo].[ccriaareaworkgroup](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccsupervisorcam'' and object_id = OBJECT_ID(N''ccsupervisorcam'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccsupervisorcam''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccsupervisorcam] on [dbo].[ccsupervisorcam](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccCampsAgente'' and object_id = OBJECT_ID(N''ccCampsAgente'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccCampsAgente''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCampsAgente] on [dbo].[ccCampsAgente](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cclogagentesnotready'' and object_id = OBJECT_ID(N''cclogagentesnotready'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cclogagentesnotready''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cclogagentesnotready] on [dbo].[cclogagentesnotready](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccloglogin'' and object_id = OBJECT_ID(N''ccloglogin'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccloglogin''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccloglogin] on [dbo].[ccloglogin](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cccallsreject'' and object_id = OBJECT_ID(N''cccallsreject'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cccallsreject''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cccallsreject] on [dbo].[cccallsreject](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccLogtransfers'' and object_id = OBJECT_ID(N''ccLogtransfers'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccLogtransfers''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccLogtransfers] on [dbo].[ccLogtransfers](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccChannelTransfer'' and object_id = OBJECT_ID(N''ccChannelTransfer'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccChannelTransfer''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccChannelTransfer] on [dbo].[ccChannelTransfer](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ivrstructure'' and object_id = OBJECT_ID(N''ivrstructure'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ivrstructure''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ivrstructure] on [dbo].[ivrstructure](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ivrcallsin'' and object_id = OBJECT_ID(N''ivrcallsin'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ivrcallsin''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ivrcallsin] on [dbo].[ivrcallsin](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ivroptions'' and object_id = OBJECT_ID(N''ivroptions'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ivroptions''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ivroptions] on [dbo].[ivroptions](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_Survey'' and object_id = OBJECT_ID(N''Survey'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''Survey''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_Survey] on [dbo].[Survey](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_SurveyQuestion'' and object_id = OBJECT_ID(N''SurveyQuestion'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''SurveyQuestion''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_SurveyQuestion] on [dbo].[SurveyQuestion](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_SurveyAnswer'' and object_id = OBJECT_ID(N''SurveyAnswer'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''SurveyAnswer''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_SurveyAnswer] on [dbo].[SurveyAnswer](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_relationSurveyQuestion'' and object_id = OBJECT_ID(N''relationSurveyQuestion'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''relationSurveyQuestion''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationSurveyQuestion] on [dbo].[relationSurveyQuestion](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_relationQuestionAnswer'' and object_id = OBJECT_ID(N''relationQuestionAnswer'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''relationQuestionAnswer''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationQuestionAnswer] on [dbo].[relationQuestionAnswer](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cctipoResultadodial'' and object_id = OBJECT_ID(N''cctipoResultadodial'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cctipoResultadodial''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipoResultadodial] on [dbo].[cctipoResultadodial](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cctiponotready'' and object_id = OBJECT_ID(N''cctiponotready'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cctiponotready''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctiponotready] on [dbo].[cctiponotready](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccodialers'' and object_id = OBJECT_ID(N''ccodialers'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccodialers''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccodialers] on [dbo].[ccodialers](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccdnis'' and object_id = OBJECT_ID(N''ccdnis'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccdnis''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccdnis] on [dbo].[ccdnis](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccstatusllamada'' and object_id = OBJECT_ID(N''ccstatusllamada'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccstatusllamada''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccstatusllamada] on [dbo].[ccstatusllamada](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cstoprovedor'' and object_id = OBJECT_ID(N''cstoprovedor'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cstoprovedor''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cstoprovedor] on [dbo].[cstoprovedor](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cstotipollamada'' and object_id = OBJECT_ID(N''cstotipollamada'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cstotipollamada''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cstotipollamada] on [dbo].[cstotipollamada](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cstotarifa'' and object_id = OBJECT_ID(N''cstotarifa'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cstotarifa''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cstotarifa] on [dbo].[cstotarifa](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIARegistryLists'' and object_id = OBJECT_ID(N''ccRIARegistryLists'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIARegistryLists''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIARegistryLists] on [dbo].[ccRIARegistryLists](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccCallCost_RIA'' and object_id = OBJECT_ID(N''ccCallCost_RIA'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccCallCost_RIA''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCallCost_RIA] on [dbo].[ccCallCost_RIA](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccEstadosAni'' and object_id = OBJECT_ID(N''ccEstadosAni'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccEstadosAni''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccEstadosAni] on [dbo].[ccEstadosAni](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccTypeProcessPreview'' and object_id = OBJECT_ID(N''ccTypeProcessPreview'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccTypeProcessPreview''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccTypeProcessPreview] on [dbo].[ccTypeProcessPreview](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccLogAgentesDia_Dialog'' and object_id = OBJECT_ID(N''ccLogAgentesDia_Dialog'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccLogAgentesDia_Dialog''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccLogAgentesDia_Dialog] on [dbo].[ccLogAgentesDia_Dialog](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccoCallbacks'' and object_id = OBJECT_ID(N''ccoCallbacks'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccoCallbacks''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallbacks] on [dbo].[ccoCallbacks](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIACallBack_Queue'' and object_id = OBJECT_ID(N''ccRIACallBack_Queue'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIACallBack_Queue''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACallBack_Queue] on [dbo].[ccRIACallBack_Queue](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccriachats'' and object_id = OBJECT_ID(N''ccriachats'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccriachats''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriachats] on [dbo].[ccriachats](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccriachatstatus'' and object_id = OBJECT_ID(N''ccriachatstatus'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccriachatstatus''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriachatstatus] on [dbo].[ccriachatstatus](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccinbound'' and object_id = OBJECT_ID(N''ccinbound'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccinbound''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccinbound] on [dbo].[ccinbound](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cctipocalif'' and object_id = OBJECT_ID(N''cctipocalif'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cctipocalif''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalif] on [dbo].[cctipocalif](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccUsers'' and object_id = OBJECT_ID(N''ccUsers'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccUsers''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccUsers] on [dbo].[ccUsers](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccUsers_Consulta'' and object_id = OBJECT_ID(N''ccUsers_Consulta'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccUsers_Consulta''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccUsers_Consulta] on [dbo].[ccUsers_Consulta](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cccamps'' and object_id = OBJECT_ID(N''cccamps'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cccamps''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cccamps] on [dbo].[cccamps](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccriacat_workgroup'' and object_id = OBJECT_ID(N''ccriacat_workgroup'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccriacat_workgroup''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriacat_workgroup] on [dbo].[ccriacat_workgroup](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccriaworkgroupusers'' and object_id = OBJECT_ID(N''ccriaworkgroupusers'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccriaworkgroupusers''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriaworkgroupusers] on [dbo].[ccriaworkgroupusers](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_cctipocalifout'' and object_id = OBJECT_ID(N''cctipocalifout'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cctipocalifout''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalifout] on [dbo].[cctipocalifout](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccBaseXDB'' and object_id = OBJECT_ID(N''ccBaseXDB'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccBaseXDB''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccBaseXDB] on [dbo].[ccBaseXDB](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIAWorkGroup_Calid'' and object_id = OBJECT_ID(N''ccRIAWorkGroup_Calid'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIAWorkGroup_Calid''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAWorkGroup_Calid] on [dbo].[ccRIAWorkGroup_Calid](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIACampEspWG'' and object_id = OBJECT_ID(N''ccRIACampEspWG'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIACampEspWG''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACampEspWG] on [dbo].[ccRIACampEspWG](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccCalifCamp'' and object_id = OBJECT_ID(N''ccCalifCamp'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccCalifCamp''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCalifCamp] on [dbo].[ccCalifCamp](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccPosicion'' and object_id = OBJECT_ID(N''ccPosicion'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccPosicion''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccPosicion] on [dbo].[ccPosicion](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIACampsGraph'' and object_id = OBJECT_ID(N''ccRIACampsGraph'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIACampsGraph''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACampsGraph] on [dbo].[ccRIACampsGraph](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIAGraphics'' and object_id = OBJECT_ID(N''ccRIAGraphics'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIAGraphics''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAGraphics] on [dbo].[ccRIAGraphics](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIAInboundGraph'' and object_id = OBJECT_ID(N''ccRIAInboundGraph'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIAInboundGraph''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAInboundGraph] on [dbo].[ccRIAInboundGraph](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIACampEspWGConsulta'' and object_id = OBJECT_ID(N''ccRIACampEspWGConsulta'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIACampEspWGConsulta''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACampEspWGConsulta] on [dbo].[ccRIACampEspWGConsulta](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIAWorkGroupUsersConsulta'' and object_id = OBJECT_ID(N''ccRIAWorkGroupUsersConsulta'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIAWorkGroupUsersConsulta''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAWorkGroupUsersConsulta] on [dbo].[ccRIAWorkGroupUsersConsulta](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccSettings'' and object_id = OBJECT_ID(N''ccSettings'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccSettings''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccSettings] on [dbo].[ccSettings](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccMenus'' and object_id = OBJECT_ID(N''ccMenus'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccMenus''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccMenus] on [dbo].[ccMenus](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccMenuUser'' and object_id = OBJECT_ID(N''ccMenuUser'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccMenuUser''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccMenuUser] on [dbo].[ccMenuUser](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_conversation'' and object_id = OBJECT_ID(N''conversation'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''conversation''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_conversation] on [dbo].[conversation](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_message'' and object_id = OBJECT_ID(N''message'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''message''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_message] on [dbo].[message](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_messageUnAssigned'' and object_id = OBJECT_ID(N''messageUnAssigned'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''messageUnAssigned''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageUnAssigned] on [dbo].[messageUnAssigned](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_relationMessageDispositionTwit'' and object_id = OBJECT_ID(N''relationMessageDispositionTwit'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''relationMessageDispositionTwit''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationMessageDispositionTwit] on [dbo].[relationMessageDispositionTwit](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_messageUnAssingedTwit'' and object_id = OBJECT_ID(N''messageUnAssingedTwit'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''messageUnAssingedTwit''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageUnAssingedTwit] on [dbo].[messageUnAssingedTwit](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_messageOutTwitter'' and object_id = OBJECT_ID(N''messageOutTwitter'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''messageOutTwitter''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageOutTwitter] on [dbo].[messageOutTwitter](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_conversationTwitter'' and object_id = OBJECT_ID(N''conversationTwitter'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''conversationTwitter''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_conversationTwitter] on [dbo].[conversationTwitter](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_searchConversationTwitter'' and object_id = OBJECT_ID(N''searchConversationTwitter'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''searchConversationTwitter''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_searchConversationTwitter] on [dbo].[searchConversationTwitter](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_messageInTwitter'' and object_id = OBJECT_ID(N''messageInTwitter'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''messageInTwitter''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageInTwitter] on [dbo].[messageInTwitter](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccWhatsAppConversations'' and object_id = OBJECT_ID(N''ccWhatsAppConversations'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccWhatsAppConversations''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWhatsAppConversations] on [dbo].[ccWhatsAppConversations](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccWhatsAppSpam'' and object_id = OBJECT_ID(N''ccWhatsAppSpam'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccWhatsAppSpam''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWhatsAppSpam] on [dbo].[ccWhatsAppSpam](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccWAMessagesConversations'' and object_id = OBJECT_ID(N''ccWAMessagesConversations'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccWAMessagesConversations''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWAMessagesConversations] on [dbo].[ccWAMessagesConversations](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccWhatsAppConversationsRelationship'' and object_id = OBJECT_ID(N''ccWhatsAppConversationsRelationship'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccWhatsAppConversationsRelationship''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWhatsAppConversationsRelationship] on [dbo].[ccWhatsAppConversationsRelationship](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_contactMeanIn'' and object_id = OBJECT_ID(N''contactMeanIn'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''contactMeanIn''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_contactMeanIn] on [dbo].[contactMeanIn](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_smsccoLogDial'' and object_id = OBJECT_ID(N''smsccoLogDial'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''smsccoLogDial''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_smsccoLogDial] on [dbo].[smsccoLogDial](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_smsOutSource'' and object_id = OBJECT_ID(N''smsOutSource'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''smsOutSource''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_smsOutSource] on [dbo].[smsOutSource](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_smsoutSourceMessage'' and object_id = OBJECT_ID(N''smsoutSourceMessage'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''smsoutSourceMessage''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_smsoutSourceMessage] on [dbo].[smsoutSourceMessage](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end


if not exists (select * from sys.indexes where name = N''MSmerge_index_RIA_GRABACION'' and object_id = OBJECT_ID(N''RIA_GRABACION'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RIA_GRABACION''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RIA_GRABACION] on [dbo].[RIA_GRABACION](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
    
END

'
        EXEC (@sql)
   
    set @process = 'DEV1-459 Alter SP ccspTimesInboundData'
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

     set @process = 'DEV1-459 Alter SP ccspTimesccLogAgentesDia'
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
    FROM ccLogAgentesDia
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


    set @process = 'DEV1-459 Alter Sp ccspTmpSessionTimeGroup'
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


    set @process = 'DEV1-459 Alter Sp ccspTimesOutboundData'
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

   
    set @process = 'DEV1-459 alter SP ccspRepOutAnswCalls'
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

    ;with  wgCalId as(
        select min(IDWG) as IDWG,cal_id
        from ccRIAWorkGroup_Calid where [timestamp] between @from and @to
        group by cal_id 
    ),
    co as(
    select
    convert(date,cal_inicio,121) [date],
    co.cam_id campaignId, isnull(min(d.IDWG),1) idwg, count(*) total, 
    COUNT(CASE WHEN(statusCall_id = 16)THEN co.cal_id ELSE NULL END) nasig_tl,
    COUNT(CASE WHEN(statuscall_id = 15)THEN co.cal_id ELSE NULL END) nasig_nc,
    COUNT(CASE WHEN(statuscall_id = 13)THEN co.cal_id ELSE NULL END) nAnswered,
    COUNT(CASE WHEN(statuscall_id = 11)THEN co.cal_id ELSE NULL END) nassigned,
    COUNT(CASE WHEN(statuscall_id in (6,4))THEN co.cal_id ELSE NULL END) nabdn_sis
    from ccocallsout co 
    left join wgCalId d on (d.cal_id = co.cal_id)
    where cal_inicio between @from and @to 
    group by convert(date,cal_inicio,121),co.cam_id
    )
    insert RepOutAnswCalls
    select 
    [date], campaignId, ca.cam_descripcion campaign, 
    abnd.IDWG workgroupId, e.WGName workgroup, isnull(f.IDArea,0) areaId, g.AreaName area, total,
    cast(((nasig_tl*100.0)/total) as decimal(5,2)) asig_tl,
    cast(((nasig_nc*100.0)/total) as decimal(5,2)) asig_nc,
    cast(((nAnswered*100.0)/total) as decimal(5,2)) Answered,
    cast(((nassigned*100.0)/total) as decimal(5,2)) assigned,
    cast(((nabdn_sis*100.0)/total) as decimal(5,2)) abdn_sis
    from co abnd
    left join cccamps ca on ca.cam_id=abnd.campaignId 
    left join ccRIACat_WorkGroup as e on e.idwg = abnd.idwg
    left join ccRIAAreaWorkGroup as f on f.idwg = e.idwg
    left join ccRIACat_Areas as g on g.idarea = f.idarea
                            
end'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepOutCallBilling'
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

    set @process = 'DEV1-459 alter SP ccspRepOutCallsDetail'
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

    set @process = 'DEV1-459 alter SP ccspRepOutKPI'
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

    set @process = 'DEV1-459 alter SP ccspRepSpececialAbnd'
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

    set @process = 'DEV1-459 alter SP ccspRepSpececialAbndPercentage'
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

    set @process = 'DEV1-459 alter SP ccspRepSpececialAbndProfiles'
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

    set @process = 'DEV1-459 alter SP ccspRepSpececialAbndTimes'
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

    set @process = 'DEV1-459 alter SP ccspRepSpececialAgtPerformance'
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

    set @process = 'DEV1-459 alter SP ccspRepSpecialAbndCamp'
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

    set @process = 'DEV1-459 alter SP ccspRepSpecialTelephoneNumbersByRegistry'
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

    set @process = 'DEV1-459 alter SP ccspRepSpecialTelephoneNumbersByState'
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

    set @process = 'DEV1-459 alter SP ccspRepInChangeFlow'
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

    set @process = 'DEV1-459 alter SP ccspRepInDIDResume'
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


    set @process = 'DEV1-459 alter SP ccspRepMKTAgentes'
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

    set @process = 'DEV1-459 alter SP ccspRepChatsAndCallsGeneral'
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

    set @process = 'DEV1-459 alter SP ccspRepInAnsw'
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

    set @process = 'DEV1-459 alter SP ccspRepInBill01900'
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

    set @process = 'DEV1-459 alter SP ccspRepInCalls'
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


    set @process = 'DEV1-459 Alter SP ccspRepOutDialDetail'
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
    cal_id  int not null,
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

    set @process = 'DEV1-459 Alter SP ccspRepSpecialTimes'
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


 set @process = 'DEV1-459 Alter SP ReportsMasterProcessWIthOnlyGenerate'
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

    set @process = 'DEV1-459 alter SP ReportsMasterProcessPublicationLowLoad'
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

    set @process = 'DEV1-459 alter SP ReportsMasterSubProcess'
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

    set @process = 'DEV1-459 alter SP ccspRepAgentKPI'
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
    )
    , Trd as(   
    select  User_id, cast((AVG(convert(bigint,fecha_Calc_ms)))/1000.0 as decimal(10,0)) avg_fCalc
    , CONVERT(date,fecha_Dispo,121) as fecha_Dispo
    from ccLogAgentesDia_Dialog with(nolock)
    where fecha_Dialog between @from and @to 
    group by User_id,CONVERT(date,fecha_Dispo,121)
    )
    , Snd as(
    select user_id, cal_Inicio, sum(Total) Total, sum(Cin) Cin, sum(Cout) Cout,
    sum(C10) C10, sum(C20) C20, sum(C30) C30, sum(cal_whoHung) cal_whoHung
    from Conteos group by user_id, cal_Inicio
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
    from Snd
    inner join ccUserView Fst on Fst.User_id = Snd.User_id
    left join Trd on Trd.User_id=Snd.User_id and Trd.fecha_Dispo=Snd.cal_Inicio

end'
    EXEC(@sql)

    set @process = 'DEV1-459 alter SP ccspRepDetailAgent'
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

    set @process = 'DEV1-459 alter SP ccspRepInAbnd'
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

    set @process = 'DEV1-459 alter SP'
    set @sql=''
    EXEC(@sql)
   
	---------------------------------------BEGIN Jesus Gallardo hotfix/125.20230719.0.9---------------------------------------------------------



		/* End script release */		/* Upgrade database version (first and the last number of setting 77) */
		--EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)	

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
