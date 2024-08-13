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
SET @version = 126 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
	------------------------------Begin Frida
	set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
		begin
		DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
		end'
	EXEC(@sql)

	set @process = 'DEV2-620 CREATE TABLE ccRecordingsDownload  '
	set @sql = '
	if not exists (select * from sys.tables where name = N'ccRecordingsDownload')
    begin
        CREATE TABLE ccRecordingsDownload (
		date DATETIME NOT NULL,
		adminId int,
		grab_Id BIGINT,
		cam_id int,
		CampType smallint
		)
    end
	'
	EXEC(@sql)

	set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
			begin
			ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
			end'
	EXEC(@sql)

	set @process = 'DEV2-620 create table RepSpecialRecordingsDownload'
	set @sql = '
	if not exists (select * from sys.tables where name = N''RepSpecialRecordingsDownload'')
    begin
	CREATE TABLE RepSpecialRecordingsDownload (
		date DATETIME NOT NULL,
		adminId SMALLINT NOT NULL,
		admin_name  VARCHAR(80),
		grab_id BIGINT,
		generalId SMALLINT,
		inboundId SMALLINT,
		inboundCampaign VARCHAR(40),
		campaignId SMALLINT,
		outboundCampaign VARCHAR(40),
		disposition VARCHAR(150),
		subDisposition	VARCHAR(150)
	)
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 create index on RepSpecialRecordingsDownload'
	set @sql = '
	if not exists (select * from sys.indexes where name = N''IX_RepSpecialRecordingsDownload'' and object_id = OBJECT_ID(N''yourTableName''))
    begin
		CREATE CLUSTERED INDEX IX_RepSpecialRecordingsDownload
		ON RepSpecialRecordingsDownload (date, adminId,inboundId,campaignId);
    end
	'
	EXEC(@sql)
	
	set @process = 'DEV2-620 delete sp ccSpCreateIndexReport'
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccSpCreateIndexReport'')
    begin
        DROP PROCEDURE ccSpCreateIndexReport;
    end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 create sp ccSpCreateIndexReport'
	set @sql = '
	CREATE PROCEDURE ccSpCreateIndexReport
AS
BEGIN
SET NOCOUNT ON;
	  if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRecordingsDownload'' and object_id = OBJECT_ID(N''ccRecordingsDownload'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRecordingsDownload''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRecordingsDownload] on [dbo].[ccRecordingsDownload](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end

  if not exists (select * from sys.indexes where name = N''IX_ccRecordingsDownload_I'' and object_id = OBJECT_ID(N''ccRecordingsDownload'')) 
begin
CREATE UNIQUE NONCLUSTERED INDEX IX_ccRecordingsDownload_I on [dbo].[ccRecordingsDownload](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccChannelTransfer'' and object_id = OBJECT_ID(N''ccChannelTransfer'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccChannelTransfer''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccChannelTransfer] on [dbo].[ccChannelTransfer](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccLogtransfers'' and object_id = OBJECT_ID(N''ccLogtransfers'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccLogtransfers''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccLogtransfers] on [dbo].[ccLogtransfers](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIACampEspWG'' and object_id = OBJECT_ID(N''ccRIACampEspWG'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIACampEspWG''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACampEspWG] on [dbo].[ccRIACampEspWG](
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

if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIAWorkGroupUsersConsulta'' and object_id = OBJECT_ID(N''ccRIAWorkGroupUsersConsulta'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIAWorkGroupUsersConsulta''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAWorkGroupUsersConsulta] on [dbo].[ccRIAWorkGroupUsersConsulta](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_RIA_GRABACIONCONSULTA'' and object_id = OBJECT_ID(N''RIA_GRABACIONCONSULTA'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RIA_GRABACIONCONSULTA''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RIA_GRABACIONCONSULTA] on [dbo].[RIA_GRABACIONCONSULTA](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_RIA_CONCEPTOS'' and object_id = OBJECT_ID(N''RIA_CONCEPTOS'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RIA_CONCEPTOS''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RIA_CONCEPTOS] on [dbo].[RIA_CONCEPTOS](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end

if not exists (select * from sys.indexes where name = N''MSmerge_index_RIA_FORMACALIF'' and object_id = OBJECT_ID(N''RIA_FORMACALIF'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RIA_FORMACALIF''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RIA_FORMACALIF] on [dbo].[RIA_FORMACALIF](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_RIA_FORMACALIF_CHAT'' and object_id = OBJECT_ID(N''RIA_FORMACALIF_CHAT'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RIA_FORMACALIF_CHAT''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RIA_FORMACALIF_CHAT] on [dbo].[RIA_FORMACALIF_CHAT](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end

if not exists (select * from sys.indexes where name = N''MSmerge_index_RIA_RESULTADOSFORMA_CHAT'' and object_id = OBJECT_ID(N''RIA_RESULTADOSFORMA_CHAT'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RIA_RESULTADOSFORMA_CHAT''))
begin
CREATE UNIQUE NONCLUSTERED INDEX MSmerge_index_RIA_RESULTADOSFORMA_CHAT on [dbo].[RIA_RESULTADOSFORMA_CHAT](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccoCallsOut'' and object_id = OBJECT_ID(N''ccoCallsOut'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccoCallsOut''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallsOut] on [dbo].[ccoCallsOut](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccCallCost_RIA'' and object_id = OBJECT_ID(N''ccCallCost_RIA'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccCallCost_RIA''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCallCost_RIA] on [dbo].[ccCallCost_RIA](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccEstadosAni'' and object_id = OBJECT_ID(N''ccEstadosAni'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccEstadosAni''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccEstadosAni] on [dbo].[ccEstadosAni](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIARegistryLists'' and object_id = OBJECT_ID(N''ccRIARegistryLists'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIARegistryLists''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIARegistryLists] on [dbo].[ccRIARegistryLists](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_cctiponotready'' and object_id = OBJECT_ID(N''cctiponotready'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cctiponotready''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctiponotready] on [dbo].[cctiponotready](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccTypeProcessPreview'' and object_id = OBJECT_ID(N''ccTypeProcessPreview'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccTypeProcessPreview''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccTypeProcessPreview] on [dbo].[ccTypeProcessPreview](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_cstotarifa'' and object_id = OBJECT_ID(N''cstotarifa'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cstotarifa''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cstotarifa] on [dbo].[cstotarifa](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccRIAWorkGroup_Calid'' and object_id = OBJECT_ID(N''ccRIAWorkGroup_Calid'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccRIAWorkGroup_Calid''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAWorkGroup_Calid] on [dbo].[ccRIAWorkGroup_Calid](
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





if not exists (select * from sys.indexes where name = N''MSmerge_index_ccWAMessagesConversations'' and object_id = OBJECT_ID(N''ccWAMessagesConversations'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccWAMessagesConversations''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWAMessagesConversations] on [dbo].[ccWAMessagesConversations](
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



if not exists (select * from sys.indexes where name = N''MSmerge_index_ccWhatsAppConversationsRelationship'' and object_id = OBJECT_ID(N''ccWhatsAppConversationsRelationship'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccWhatsAppConversationsRelationship''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWhatsAppConversationsRelationship] on [dbo].[ccWhatsAppConversationsRelationship](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_contactMeanIn'' and object_id = OBJECT_ID(N''contactMeanIn'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''contactMeanIn''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_contactMeanIn] on [dbo].[contactMeanIn](
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

if not exists (select * from sys.indexes where name = N''MSmerge_index_ivrstructure'' and object_id = OBJECT_ID(N''ivrstructure'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ivrstructure''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ivrstructure] on [dbo].[ivrstructure](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccLogAgentesDia_Dialog'' and object_id = OBJECT_ID(N''ccLogAgentesDia_Dialog'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccLogAgentesDia_Dialog''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccLogAgentesDia_Dialog] on [dbo].[ccLogAgentesDia_Dialog](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccoLogDials'' and object_id = OBJECT_ID(N''ccoLogDials'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccoLogDials''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoLogDials] on [dbo].[ccoLogDials](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccCampsMovs'' and object_id = OBJECT_ID(N''ccCampsMovs'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccCampsMovs''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCampsMovs] on [dbo].[ccCampsMovs](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_cctipocalifsubout'' and object_id = OBJECT_ID(N''cctipocalifsubout'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cctipocalifsubout''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalifsubout] on [dbo].[cctipocalifsubout](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_RegProcessPreviewRecord'' and object_id = OBJECT_ID(N''RegProcessPreviewRecord'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RegProcessPreviewRecord''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RegProcessPreviewRecord] on [dbo].[RegProcessPreviewRecord](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_cccamps'' and object_id = OBJECT_ID(N''cccamps'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cccamps''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cccamps] on [dbo].[cccamps](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_cctipocalif'' and object_id = OBJECT_ID(N''cctipocalif'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''cctipocalif''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalif] on [dbo].[cctipocalif](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccCampsAgente'' and object_id = OBJECT_ID(N''ccCampsAgente'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccCampsAgente''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCampsAgente] on [dbo].[ccCampsAgente](
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
if not exists (select * from sys.indexes where name = N''MSmerge_index_ccriacat_areas'' and object_id = OBJECT_ID(N''ccriacat_areas'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''ccriacat_areas''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriacat_areas] on [dbo].[ccriacat_areas](
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



if not exists (select * from sys.indexes where name = N''MSmerge_index_RIA_FORMATOS'' and object_id = OBJECT_ID(N''RIA_FORMATOS'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RIA_FORMATOS''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RIA_FORMATOS] on [dbo].[RIA_FORMATOS](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end

if not exists (select * from sys.indexes where name = N''MSmerge_index_RIA_PREGUNTAS'' and object_id = OBJECT_ID(N''RIA_PREGUNTAS'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RIA_PREGUNTAS''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RIA_PREGUNTAS] on [dbo].[RIA_PREGUNTAS](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end

if not exists (select * from sys.indexes where name = N''MSmerge_index_RIA_RESPUESTAS'' and object_id = OBJECT_ID(N''RIA_RESPUESTAS'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RIA_RESPUESTAS''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RIA_RESPUESTAS] on [dbo].[RIA_RESPUESTAS](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end

if not exists (select * from sys.indexes where name = N''MSmerge_index_RIA_RESULTADOSFORMA'' and object_id = OBJECT_ID(N''RIA_RESULTADOSFORMA'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RIA_RESULTADOSFORMA''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RIA_RESULTADOSFORMA] on [dbo].[RIA_RESULTADOSFORMA](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end



if not exists (select * from sys.indexes where name = N''MSmerge_index_RiaMarkHold'' and object_id = OBJECT_ID(N''RiaMarkHold'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RiaMarkHold''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RiaMarkHold ] on [dbo].[RiaMarkHold](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_relationQuestionAnswer'' and object_id = OBJECT_ID(N''relationQuestionAnswer'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''relationQuestionAnswer''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationQuestionAnswer ] on [dbo].[relationQuestionAnswer](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_relationSurveyQuestion'' and object_id = OBJECT_ID(N''relationSurveyQuestion'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''relationSurveyQuestion''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationSurveyQuestion ] on [dbo].[relationSurveyQuestion](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_Survey'' and object_id = OBJECT_ID(N''Survey'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''Survey''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_Survey ] on [dbo].[Survey](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_SurveyAnswer'' and object_id = OBJECT_ID(N''SurveyAnswer'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''SurveyAnswer''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_SurveyAnswer ] on [dbo].[SurveyAnswer](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_SurveyQuestion'' and object_id = OBJECT_ID(N''SurveyQuestion'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''SurveyQuestion''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_SurveyQuestion ] on [dbo].[SurveyQuestion](
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


if not exists (select * from sys.indexes where name = N''MSmerge_index_RiaMarkHold'' and object_id = OBJECT_ID(N''RiaMarkHold'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''RiaMarkHold''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RiaMarkHold ] on [dbo].[RiaMarkHold](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_relationQuestionAnswer'' and object_id = OBJECT_ID(N''relationQuestionAnswer'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''relationQuestionAnswer''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationQuestionAnswer ] on [dbo].[relationQuestionAnswer](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_relationSurveyQuestion'' and object_id = OBJECT_ID(N''relationSurveyQuestion'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''relationSurveyQuestion''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationSurveyQuestion ] on [dbo].[relationSurveyQuestion](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_Survey'' and object_id = OBJECT_ID(N''Survey'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''Survey''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_Survey ] on [dbo].[Survey](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_SurveyAnswer'' and object_id = OBJECT_ID(N''SurveyAnswer'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''SurveyAnswer''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_SurveyAnswer ] on [dbo].[SurveyAnswer](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''MSmerge_index_SurveyQuestion'' and object_id = OBJECT_ID(N''SurveyQuestion'')) 
and exists (select * from sys.columns where name = N''rowguid'' and Object_ID = Object_ID(N''SurveyQuestion''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_SurveyQuestion ] on [dbo].[SurveyQuestion](
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


if not exists (select * from sys.indexes where name = N''IX_RepOutAnswAndXferCalls_1'' and object_id = OBJECT_ID(N''RepOutAnswAndXferCalls''))
begin
   CREATE NONCLUSTERED INDEX IX_RepOutAnswAndXferCalls_1
ON [dbo].[RepOutAnswAndXferCalls] ([date])
end

if not exists (select * from sys.indexes where name = N''IX_RepMKTTiemposTotales_1'' and object_id = OBJECT_ID(N''RepMKTTiemposTotales''))
begin
CREATE NONCLUSTERED INDEX IX_RepMKTTiemposTotales_1
ON [dbo].[RepMKTTiemposTotales] ([date])
end

if not exists (select * from sys.indexes where name = N''IX_RepOutDialDetail_3'' and object_id = OBJECT_ID(N''RepOutDialDetail''))
begin
CREATE NONCLUSTERED INDEX IX_RepOutDialDetail_3
ON [dbo].[RepOutDialDetail] ([date])
INCLUDE ([callKey],[telephone],[dialResultId])
end

if not exists (select * from sys.indexes where name = N''IX_RepInSubDispositions_1'' and object_id = OBJECT_ID(N''RepInSubDispositions''))
begin
CREATE NONCLUSTERED INDEX IX_RepInSubDispositions_1
ON [dbo].[RepInSubDispositions] ([date])
INCLUDE ([userId],[inboundId],[subDispositionId],[areaId])
end

if not exists (select * from sys.indexes where name = N''IX_RepInCallsDetail_2'' and object_id = OBJECT_ID(N''RepInCallsDetail''))
begin
CREATE NONCLUSTERED INDEX IX_RepInCallsDetail_2
ON [dbo].[RepInCallsDetail] ([date])
INCLUDE ([callStatusId],[dispositionId],[userId],[queueTime])
end
    
if not exists (select * from sys.indexes where name = N''IX_RepAgentNotReadyDet_2'' and object_id = OBJECT_ID(N''RepAgentNotReadyDet''))
begin
CREATE NONCLUSTERED INDEX IX_RepAgentNotReadyDet_2
ON [dbo].[RepAgentNotReadyDet] ([tiponotreadyId],[startDate])
INCLUDE ([userId],[status],[statusTime])
end

if not exists (select * from sys.indexes where name = N''IX_RepOutManagementBase_1'' and object_id = OBJECT_ID(N''RepOutManagementBase''))
begin
CREATE NONCLUSTERED INDEX IX_RepOutManagementBase_1
ON [dbo].[RepOutManagementBase] ([date])
end
    
if not exists (select * from sys.indexes where name = N''IX_RepOutSubDispositions_1'' and object_id = OBJECT_ID(N''RepOutSubDispositions''))
begin
CREATE NONCLUSTERED INDEX IX_RepOutSubDispositions_1
ON [dbo].[RepOutSubDispositions] ([date])
INCLUDE ([campaignId],[subDispositionId],[userId],[areaId])
end

    
if not exists (select * from sys.indexes where name = N''IX_RepAgentGI_1'' and object_id = OBJECT_ID(N''RepAgentGI''))
begin
CREATE NONCLUSTERED INDEX IX_RepAgentGI_1
ON [dbo].[RepAgentGI] ([date])
INCLUDE ([userId],[user],[login],[tdialogin],[tnotesin],[tdialogout],[tnotesout],[tnotav],[tlog])
end

end
	'
	EXEC(@sql)
	

	set @process = 'DEV2-620 insert into ReportHighUse ccspRepSpecialRecordingsDownload '
	set @sql = '
	if not exists(select * from ReportHighUse where nameSp=''ccspRepSpecialRecordingsDownload'')
	begin 
	insert into ReportHighUse (nameSp) values (''ccspRepSpecialRecordingsDownload'')
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 insert into Filters Filters adminIds'
	set @sql = '
	if not exists(select id from Filters where id = 15 and type = 36)
	begin
		insert into Filters (id,name,type,xmlParentNode,xmlChildNode) values (15,''adminIds'',36,''AdminIds'',''AdminId'')
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 insert into FiltersMenus adminids'
	set @sql = '
	if not exists (select * from FiltersMenus where name=''adminids'' )
	begin
		insert into FiltersMenus (name) values (''adminids'')
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 insert into FiltersMenus campaigns'
	set @sql = '
	if not exists (select * from FiltersMenus where name=''campaigns'' )
	begin
		insert into FiltersMenus (name) values (''campaigns'')
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 insert into FiltersMenus acds'
	set @sql = '
	if not exists (select * from FiltersMenus where name=''acds'' )
	begin
		insert into FiltersMenus (name) values (''acds'')
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 insert into FiltersMenus groupby'
	set @sql = '
	if not exists (select * from FiltersMenus where name=''groupby'' )
	begin
		insert into FiltersMenus (name) values (''groupby'')
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 insert into FiltersMenus text'
	set @sql = '
	if not exists (select * from FiltersMenus where name=''text'' )
	begin
		insert into FiltersMenus (name) values (''text'')
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 INSERT INTO ReportsFiltersMenus date '
	set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=7230 and filterMenuName=''date'')
	begin
		INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(7230,N''date'') 
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 INSERT INTO ReportsFilters campaigns'
	set @sql = '
	if not exists (select * from ReportsFilters where id=7230 and filterName=''campaigns'')
	begin
		INSERT INTO ReportsFilters(reportName,filterName,id) VALUES(''Recordings Download'',''campaigns'',7230) 
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 INSERT INTO ReportsFilters acds'
	set @sql = '
	if not exists (select * from ReportsFilters where id=7230 and filterName=''acds'')
	begin
		INSERT INTO ReportsFilters(reportName,filterName,id) VALUES(''Recordings Download'',''acds'',7230) 
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 INSERT INTO ReportsFilters adminids'
	set @sql = '
	if not exists (select * from ReportsFilters where id=7230 and filterName=''adminids'')
	begin
		INSERT INTO ReportsFilters(reportName,filterName,id) VALUES(''Recordings Download'',''adminids'',7230) 
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620  insert into ReportsFiltersMenus adminids'
	set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=7230 and filterMenuName=''adminids'')
	begin
		insert into ReportsFiltersMenus (idReport,filterMenuName,showFilter) values (7230,''adminids'',1)
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 DEV2-620 insert into ReportsFiltersMenus campaigns '
	set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=7230 and filterMenuName=''campaigns'')
	begin
		insert into ReportsFiltersMenus (idReport,filterMenuName,showFilter) values (7230,''campaigns'',1)
	end
	'
	EXEC(@sql)


	set @process = 'DEV2-620 insert into ReportsFiltersMenus acds'
	set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=7230 and filterMenuName=''acds'')
	begin
		insert into ReportsFiltersMenus (idReport,filterMenuName,showFilter) values (7230,''acds'',1)
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 create table orColumnsByReport '
	set @sql = '
	if not exists (select * from sys.tables where name = N''orColumnsByReport'')
    begin
        create table orColumnsByReport(idReport int, columns varchar(255))
    end
	'
	EXEC(@sql)

	set @process = 'DEV2-620  insert into orColumnsByReport report 7230'
	set @sql = '
	if not exists (select * from orColumnsByReport where idReport=7230 and columns=''campaignId|inboundId'')
	begin
		insert into orColumnsByReport (idReport,columns) values (7230,''campaignId|inboundId'')
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-620  DROP PROCEDURE ccspRepSpecialRecordingsDownload '
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccspRepSpecialRecordingsDownload'')
    begin
        DROP PROCEDURE ccspRepSpecialRecordingsDownload;
    end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 CREATE PROC ccspRepSpecialRecordingsDownload '
	set @sql = '
	
CREATE PROC ccspRepSpecialRecordingsDownload
@action AS TINYINT, 
@from AS DATETIME = NULL, 
@to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))
IF @to IS NULL
	SELECT @to = getdate()
IF @action = 1
BEGIN
  DELETE FROM RepSpecialRecordingsDownload  WHERE date >= @from AND date < @to


;with grab as(
	select  ccrd.date ,ccrd.adminId,
		A.grab_id, ccrd.CampType as tipo_llamada, A.calif_id, A.califSub_id,A.cam_id
	from ccRecordingsDownload ccrd
	inner join RIA_GRABACION A with(nolock) on ccrd.grab_Id=A.grab_id
	where ccrd.date between @from and @to
	union
	select ccrd.date ,ccrd.adminId,
		A.grab_id, ccrd.CampType as tipo_llamad, A.calif_id, A.califSub_id,A.cam_id
	from ccRecordingsDownload ccrd
	inner join  RIA_GRABACIONCONSULTA  A with(nolock) on ccrd.grab_Id=A.grab_id
	where ccrd.date between @from and @to
), 
	califTotal as (
	select grab_id
	,isnull(calif.Description,''N/A'') as calificacion
	,isnull(sub.califSubDesc,''N/A'') as subCalif
	from grab
	left join cctipocalifout calif on calif.calif_id = grab.calif_id
	left join cctipocalifsubout sub on sub.califSub_id = grab.califSub_id
	where grab.tipo_llamada=2
	union
	select grab_id
	,isnull(calif.Description,''N/A'') as calificacion
	,isnull(sub.califSubDesc,''N/A'') as subCalif
	from grab
	left join cctipocalif calif on calif.calif_id = grab.calif_id
	left join cctipocalifsub sub on sub.califSub_id = grab.califSub_id
	where grab.tipo_llamada=1
),
total as(
	select
	ccr.date,
	ccr.grab_id,
	c.cam_id,c.cam_descripcion,2 as CampType,
	ccr.adminId
	,ccr.tipo_llamada
	from cccamps c
	inner join grab ccr on ccr.cam_id= c.cam_id
	where ccr.tipo_llamada = 2 and ccr.date between @from and @to
	union
	select 
	ccr.date,
	ccr.grab_id,
	Inbound_id,descripcion,1 as CampType
	,ccr.adminId
	,ccr.tipo_llamada
	from 
	ccinbound i
	inner join grab ccr on ccr.cam_id = i.Inbound_id
	where ccr.tipo_llamada = 1 and ccr.date between @from and @to
)

insert into RepSpecialRecordingsDownload
select 
t.date
,t.adminId
,case when CHARINDEX('' '',u.Nombres) > 0 then left(u.Nombres,CHARINDEX('' '',u.Nombres)-1)  + '' '' + u.ApellidoPaterno else  u.Nombres  + '' '' + u.ApellidoPaterno end admin_Name
,t.grab_id
,t.cam_id as generalId
,case when t.tipo_llamada = 1 then t.cam_id else 0 end as inboundId
,case when t.tipo_llamada = 1 then t.cam_descripcion else '''' end as inboundCampaign
,case when t.tipo_llamada = 2 then t.cam_id else 0 end as campaingId
,case when t.tipo_llamada = 2 then t.cam_descripcion else '''' end as outboundCampaign
,ct.calificacion
,ct.subCalif
from total t
inner join ccUsers u on u.User_id = t.adminId
inner join califTotal ct on ct.grab_id=t.grab_id


END
	'
	EXEC(@sql)

	set @process = 'DEV2-620 DROP PROCEDURE ccspRepCatalogos '
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccspRepCatalogos'')
    begin
        DROP PROCEDURE ccspRepCatalogos;
    end
	'
	EXEC(@sql)

	set @process = 'DEV2-620 CREATE PROCEDURE  ccspRepCatalogos'
	set @sql = 'CREATE  PROCEDURE ccspRepCatalogos
	@type as tinyint,
	@action tinyint = 0 -- 0 Filter select; 1 Filters Range
	,@userId int =0 ---- se agrega parametro para filtros
	,@menuId INT = 0

	AS
	declare @tablatemp table (id int, description varchar(100) null)
	declare @tempwork table (idwg int)
	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @condition NVARCHAR(300) = '''';
	DECLARE @columnName NVARCHAR(100) = '''';
	DECLARE @consult NVARCHAR (2000) = '''';

	if @action = 0
	BEGIN
	IF OBJECT_ID(''TEMPDB..#filters'') IS NULL
	BEGIN
		CREATE TABLE #filters ([Type] VARCHAR(200))
	END

		-- CAMPAIGNS
	IF @type = 1 BEGIN

		INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId
		IF EXISTS (SELECT * FROM #filters)
		BEGIN
			SET @condition = '' WHERE camp.campType IN (SELECT * FROM #filters)''
			SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId;
		END
		ELSE BEGIN
			SET @columnName =	''campaignId'';
		END

		SET @consult = N'' SELECT cam_id as id, cam_descripcion as description, @columnName as dbColumn FROM ccCamps camp''

		IF @userId <> 0 BEGIN

			SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null)	
				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''' '''' as description  from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
				inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1
				where us.[User_id] = @userId ''
				+ @consult + '' inner join @tablatemp A on camp.cam_id = A.id'' + @condition;
		END
		ELSE BEGIN
			SET @SQL = @consult + @condition;
		END
		EXEC sp_executesql @SQL, N''@userId AS int = 0, @columnName AS NVARCHAR(100)'', @userId=@userId, @columnName=@columnName;
	END


		-- DIAL RESULTS
	if @type = 2 begin
		Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
		from ccTipoResultadoDial
		order by descripcion
	end

		-- WORKGROUPS
	if @type = 3 begin
		if @userId <> 0 begin
			select v.IDWG as id, c.WGName as description, ''workgroupId'' as dbColumn
			from ccWgByAcdView v
			inner join ccriacat_workgroup c on c.IDWG=v.IDWG
			where USER_ID= @userId
			return
		end
		else  begin
			select idwg as id, wgname as description, ''workgroupId'' as dbColumn
			from ccRIACat_WorkGroup
			group by idwg, wgname	select * from ccRIACat_WorkGroup
			order by wgname
		end
	end


	-- AREAS
	if @type = 4 begin
	if @userId <> 0 begin

		insert into @tablatemp
		select distinct isnull(us.IDArea,0) as IDArea, wgu.User_id from ccUserView us
		inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
		where us.[User_id] = @userId

		select distinct idArea as id, isnull(AreaName,''S/AREA'') as description, ''areaId'' as dbColumn
		from ccRIACat_Areas area inner join @tablatemp tem on area.IDArea = tem.id
		return
	end
		else begin

			select idArea as id, AreaName as description, ''areaId'' as dbColumn
			from ccRIACat_Areas
			group by idArea, AreaName
			order by AreaName
		end
	end

	-- DISPOSITIONS OUT
	if @type = 5 begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalifOut
		order by [description]
	end

		-- USER
	if @type = 6 	begin
		if @userId <> 0 begin

				insert into @tempwork
						select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

				select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

				inner join @tempwork awg on wgu.IDWG = awg.idwg
				where us.TipoUser_id = 1 and [status] = 1

				return
			end

			else begin

				SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
				FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 1
				ORDER BY description
			end
	end

		-- ACDS**************
	IF @type = 7 BEGIN

		INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId
		IF EXISTS (SELECT * FROM #filters)
		BEGIN
			SET @condition = '' WHERE B.chat IN (SELECT * FROM #filters)''
			SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId;
		END
		ELSE BEGIN
			SET @columnName = ''inboundId'';
		END

		SET @consult = N'' SELECT inbound_id AS id, descripcion AS description, @columnName AS dbColumn
			FROM ccinbound B''

		IF @userId <> 0 BEGIN

			SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null)
				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''''''' as description  from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
				inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
				where us.[User_id] = @userId;''
				+ @consult + '' inner join @tablatemp A on B.inbound_id = A.id'' + @condition + '' return;'';		
		END
		ELSE BEGIN
			SET @SQL = @consult + @condition;
		END
		EXEC sp_executesql @SQL, N''@userId INT = 0, @columnName AS NVARCHAR(100)'',@userId=@userId, @columnName=@columnName;
	end

		-- DIDS
	if @type = 8 	begin
		select 0 as id, ''S/DNIS''  as description, ''dnisId'' as dbColumn
		union
		select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
		from ccdnis
	end

		--DISPOSITIONS IN
	if @type = 9 begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalif
		order by [description]
	end

		--SUBDISPOSITIONS IN
	if @type = 10	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM ccTipoCalifSub
		order by [description]
	end

		--PROVIDER
	if @type = 11 begin
		SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
		FROM cstoProvedor
		order by [description]
	end

		-- UNAVAILABLES
	if @type = 12 begin
		SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
		FROM cctiponotready
		order by descripcion
	end

		-- DIALERS
	if @type = 13 begin
		SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
		FROM ccoDialers
		order by descripcion
	end

		-- CallTYpes
	if @type = 14	begin
			SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
			FROM ccStatusLlamada
		order by descripcion
	end

		-- SUBDISPOSITIONS OUT
	if @type = 21	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM cctipocalifsubout
		order by [description]
	end

		--AVRS TEMPLATE-SECTION
	if @type = 15 	begin
		SELECT fc.id as id, (rf.nombre +'' ''+ rc.con_descripcion)+'' ''+convert(varchar(10),fc.id) as description, ''templateSectionId'' as dbColumn
		FROM RIA_FORMATOCONCEPTO fc
		INNER JOIN  (SELECT id_formato, nombre, MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato, nombre) as rf
		ON rf.id_formato = fc.templateId
		inner join RIA_CONCEPTOS rc ON rc.id_concepto = fc.sectionId
		order by fc.id
	END

	--exec dbo.ccspRepCatalogos @type=15,@action=0

		--AVRS TEMPLATES
	if @type = 16 	begin
		SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
		FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato) as t
		ON f.id_formato = t.id_formato AND f.version = t.version
		order by f.nombre
	end

		--AVRS TEMPLATES
	if @type = 31 	begin
		SELECT c.id_concepto as id, c.con_descripcion as description, ''sectionId'' as dbColumn
		FROM RIA_CONCEPTOS c INNER JOIN (SELECT id_concepto,MAX(version) as version
										FROM RIA_CONCEPTOS
										group by id_concepto) as t
		ON c.id_concepto = t.id_concepto AND c.version = t.version
		order by c.con_descripcion
	END

		--AVRS QUESTIONS
	if @type = 23 	begin
		SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
		FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
										FROM RIA_PREGUNTAS
										group by id_pregunta) as t
		ON p.id_pregunta = t.id_pregunta
		order by p.enunciado_pregunta
	END


	--AVRS QUESTIONS CHAT
	if @type = 24 	begin
		SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
		FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
										FROM RIA_PREGUNTAS
										group by id_pregunta) as t
		ON p.id_pregunta = t.id_pregunta
		order by p.enunciado_pregunta
	END

		-- AVRS SUPERVISOR
	if @type = 17 	begin
		SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
		FROM ccUserView
		WHERE [status] = 1
		and TipoUser_id = 2
		ORDER BY [login]
	end

		--Status Call
	if @type = 25 	begin
		select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
		from ccstatusllamada
		order by [descripcion]
	end

		--Survey
	if @type = 26 	begin
		select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
		from Survey
		order by [description]
	end

	--dialType
	if @type = 29 begin
		select dialId as id, [description] as description, ''dialId'' as dbcolumn
		from dialType
		order by [description]
	end

		--dial
	if @type = 30 	begin
		select id as id, [description] as description, ''dialId'' as dbcolumn
		from Dials
		order by [description]
	end

	if @type = 33 begin
		if @userId <> 0 begin
 			insert into @tablatemp
			select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
			inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
			inner join ccinbound i on caesp.IdCampEsp = i.Inbound_id and i.chat = 0
			where us.[User_id] = @userId

			SELECT inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
			from ccinbound B
			inner join @tablatemp A on B.inbound_id = A.id
			return
		end
		else begin
			select inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
			from ccinbound where chat = 0
		end
	end
	IF @type = 34 	
	BEGIN
		SELECT DISTINCT TipoReadyAuxiliar_Id AS id, [Description] AS description, ''auxiliarId'' AS dbcolumn
		FROM TipoReadyAuxiliar
		ORDER BY [description]
	END
	IF @type = 35 	
	BEGIN
		select SegmentId as Id,Name as description, ''SegmentId'' as dbColumn from ccSmsSegments
	END
	if @type = 36 begin
		if @userId <> 0 begin

				insert into @tempwork
						select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

				select distinct us.User_id as id, us.Login as description,  ''adminId'' as dbcolumn from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

				inner join @tempwork awg on wgu.IDWG = awg.idwg
				where us.TipoUser_id = 2 and [status] = 1

				return
			end

			else begin

				SELECT [user_id] as id, [login] AS description, ''adminId'' as dbColumn
				FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 2
				ORDER BY description
			end
	end
	end --Action 0

	IF OBJECT_ID(''TEMPDB..#filters'') IS NOT NULL
	BEGIN
		DROP TABLE #filters;
	END

	-----------------------------------------------------------
	if @action = 1 begin
		-- TRUNKS
		if @type = 13
		begin
			SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
		end

		-- AVRS DISPOSITION
		if @type = 18
		begin
			SELECT 0 as [min], 100 as [max],''Disposition'' as dbColumn
		end

		-- AVG DISPOSITION
		if @type = 19
		begin
			SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
		end

		-- SCORE
		if @type = 20
		begin
			SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
		end
	end'
	EXEC(@sql)
	
	------------------------------END Frida
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
