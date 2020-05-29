/*
Autor: Raymundo Gonzalez
Fecha: 2013/06/30
Descripcion: 
	Nueva version de reportes ccReportsRia
	
Version requerida: 0
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '1'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------
		
/*********************************/
/*** TABLAS DE NUEVOS REPORTES ***/
/*********************************/
		
		set @process = 'Tables - Drop Table'
		set @Sql='DROP TABLE [dbo].[ccCamps]
drop TABLE [dbo].[ccoCallsOutSource]
DROP TABLE [dbo].[ccTipoCalifOUT]
DROP TABLE [dbo].[CCODIALERS]
DROP TABLE [dbo].[ccDNIS]
DROP TABLE [dbo].[ccInbound]'
		
	EXEC(@Sql)
	
		set @process = 'ccCamps - Create Table'
		set @Sql='CREATE TABLE [dbo].[ccCamps](
[cam_id] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
[cli_id] [int] NOT NULL CONSTRAINT [DF_ccCamps_cli_id]  DEFAULT ((0)),
[cam_descripcion] [varchar](40) NOT NULL,
[cam_activo] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_cam_activo]  DEFAULT ((1)),
[cam_ModoManual] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_inicio]  DEFAULT ((0)),
[cam_modpredictivo] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_modpredictivo]  DEFAULT ((1)),
[cam_TipoJobs] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_TipoJobs]  DEFAULT ((2)),
[cam_tNoContesta] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_tNoContesta]  DEFAULT ((30)),
[cam_SortColumns] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_SortColumns]  DEFAULT ((1)),
[cam_ocupado] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_ocupado]  DEFAULT ((1)),
[cam_nocontesto] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_nocontesto]  DEFAULT ((1)),
[cam_graba] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_graba]  DEFAULT ((0)),
[cam_fax] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_fax]  DEFAULT ((1)),
[cam_callratio] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_callratio]  DEFAULT ((0)),
[cam_inter_ocupado] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_cam_inter_ocupado]  DEFAULT ((20)),
[cam_inter_nocontesto] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_cam_inter_nocontesto]  DEFAULT ((180)),
[cam_inter_graba] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_cam_inter_graba]  DEFAULT ((180)),
[cam_inter_fax] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_cam_inter_fax]  DEFAULT ((180)),
[cam_NoInt_ocupado] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_NoInt_ocupado]  DEFAULT ((4)),
[cam_NoInt_nocontesto] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_NoInt_nocontesto]  DEFAULT ((4)),
[cam_NoInt_graba] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_NoInt_graba]  DEFAULT ((1)),
[cam_NoInt_fax] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_NoInt_fax]  DEFAULT ((1)),
[cam_procesando] [bit] NOT NULL CONSTRAINT [DF_ccCamps_cam_procesando]  DEFAULT ((0)),
[cam_dsn] [varchar](10) NOT NULL CONSTRAINT [DF_ccCamps_cam_dsn]  DEFAULT (''''),
[cam_sql] [varchar](10) NOT NULL CONSTRAINT [DF_ccCamps_cam_sql]  DEFAULT (''''),
[cam_tnotas] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_cam_tnotas]  DEFAULT ((15)),
[cam_tDialAfterWU] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_cam_tDialAfterWU]  DEFAULT ((5)),
[cam_tDialAfterDLG] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_cam_tDialAfterDLG]  DEFAULT ((120)),
[cam_fDialOnWU] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_fDialOnWU]  DEFAULT ((0)),
[cam_fDialOnDLG] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_fDialOnDLG]  DEFAULT ((0)),
[cam_tDialBeforeWU] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_cam_tDialBeforeWU]  DEFAULT ((5)),
[cam_tDialBeforeReady] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_cam_tDialBeforeReady]  DEFAULT ((5)),
[cam_bValidaTel] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_cam_bValidaTel]  DEFAULT ((1)),
[cam_bNew] [tinyint] NULL CONSTRAINT [DF__cccamps__cam_bNe__3296789C]  DEFAULT ((1)),
[cam_ShowCalifWnd] [bit] NOT NULL CONSTRAINT [DF__ccCamps__cam_Sho__7C3A67EB]  DEFAULT ((1)),
[cam_StartTimerOnHangUp] [bit] NOT NULL CONSTRAINT [DF__ccCamps__cam_Sta__7D2E8C24]  DEFAULT ((1)),
[cam_fCreate] [smalldatetime] NOT NULL CONSTRAINT [DF_ccCamps_cam_fCreate]  DEFAULT (getdate()),
[cam_MaxDlrXage] [decimal](3, 1) NULL CONSTRAINT [DF__ccCamps__cam_Max__22951AFD]  DEFAULT ((3)),
[ani] [varchar](15) NOT NULL CONSTRAINT [DF__ccCamps__ani__1431ED0D]  DEFAULT (''''),
[IDArea] [smallint] NULL,
[EditableCallKey] [bit] NOT NULL CONSTRAINT [DF__ccCamps__editabl__43B6E2FD]  DEFAULT ((0)),
[iTipoDial] [tinyint] NOT NULL CONSTRAINT [DF_ccCamps_iTipoDial]  DEFAULT ((0)),
[detectAnswerMachine] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_detectAnswerMachine]  DEFAULT ((0)),
[detectVoiceMail] [tinyint] NOT NULL CONSTRAINT [DF_cccamps_detectVoiceMail]  DEFAULT ((1)),
[compliance] [tinyint] NOT NULL CONSTRAINT [DF_cccamps_compliance]  DEFAULT ((0)),
[progDial] [bit] NOT NULL CONSTRAINT [DF_ccCamps_progDial]  DEFAULT ((0)),
[excCallBack] [bit] NOT NULL CONSTRAINT [DF_ccCamps_excCallBack]  DEFAULT ((0)),
[keepDial] [bit] NOT NULL CONSTRAINT [DF_ccCamps_keepDial]  DEFAULT ((0)),
[aggressionFactor] [float] NOT NULL CONSTRAINT [DF_ccCamps_aggressionFactor]  DEFAULT ((0)),
[dialOrder] [bit] NOT NULL CONSTRAINT [DF_ccCamps_dialOrder]  DEFAULT ((0)),
[dialPrefix] [varchar](10) NULL CONSTRAINT [DF_ccCamps_dialPrefix]  DEFAULT (''''),
[listenManualCall] [bit] NOT NULL CONSTRAINT [DF_ccCamps_listenManualCall]  DEFAULT (''false''),
[stopRecording] [bit] NOT NULL CONSTRAINT [DF_ccCamps_stopRecording]  DEFAULT (''false''),
[abandonCallback] [bit] NOT NULL CONSTRAINT [DF_ccCamps_abandonCallback]  DEFAULT ((1)),
[t_autoCB] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_t_autoCB]  DEFAULT ((400)),
[id_anilist] [smallint] NULL CONSTRAINT [DF_ccCamps_id_anilist]  DEFAULT ((0)),
[dialPrefixMan] [varchar](10) NOT NULL CONSTRAINT [DF_ccCamps_dialPrefixMan]  DEFAULT (''''),
[dialPrefixXfe] [varchar](10) NOT NULL CONSTRAINT [DF_ccCamps_dialPrefixXfe]  DEFAULT (''''),
[tDialonWrapUp] [smallint] NOT NULL CONSTRAINT [DF_ccCamps_tDialonWrapUp]  DEFAULT ((0)),
[cam_maxqueue] [smallint] NOT NULL DEFAULT ((10)),
[DNCScrub] [int] NOT NULL DEFAULT ((0)),
[callerIdDesc] [varchar](15) NULL DEFAULT (''''),
CONSTRAINT [PK_ccCamps] PRIMARY KEY CLUSTERED 
(
[cam_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]'
		
	EXEC(@Sql)

		set @process = 'ccoCallsOutSource - Create Table'
		set @Sql='CREATE TABLE [dbo].[ccoCallsOutSource](
[callout_id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
[cal_Key] [varchar](20) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_Key]  DEFAULT (''''),
[cam_id] [smallint] NOT NULL,
[cal_telefono] [varchar](19) NOT NULL,
[cal_telefono2] [varchar](19) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_telefono2]  DEFAULT (''''),
[cal_telefono3] [varchar](19) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_telefono3]  DEFAULT (''''),
[cal_telefono4] [varchar](19) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_telefono4]  DEFAULT (''''),
[cal_telefono5] [varchar](19) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_telefono5]  DEFAULT (''''),
[cal_callback] [varchar](19) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_callback]  DEFAULT (''''),
[cal_status] [tinyint] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_status]  DEFAULT ((0)),
[cal_intentos] [tinyint] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_intentos]  DEFAULT ((0)),
[user_id] [smallint] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_user_id]  DEFAULT ((0)),
[cal_fechaDial] [datetime] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_fechaDial]  DEFAULT (getdate()),
[nOcupado] [tinyint] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_nOcupado]  DEFAULT ((0)),
[nNoContesta] [tinyint] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_nNoContesta]  DEFAULT ((0)),
[nFax] [tinyint] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_nFax]  DEFAULT ((0)),
[nContestadora] [tinyint] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_nContestadora]  DEFAULT ((0)),
[nShortCall] [tinyint] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_nShortCall]  DEFAULT ((0)),
[nOtro] [tinyint] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_nOtro]  DEFAULT ((0)),
[Dato2] [varchar](255) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_Dato2]  DEFAULT (''''),
[Dato3] [varchar](255) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_Dato3]  DEFAULT (''''),
[Dato4] [varchar](255) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_Dato4]  DEFAULT (''''),
[Dato5] [varchar](255) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_Dato5]  DEFAULT (''''),
[last_dialed] [int] NULL,
[dial_tels] [char](8) NULL CONSTRAINT [DF_ccoCallsOutSource_dial_tels]  DEFAULT (''12345NNN''),
[Dato1] [varchar](255) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_Dato1_1]  DEFAULT (''''),
[iZonaHoraria] [int] NOT NULL CONSTRAINT [DF__ccoCallsO__iZona__538D5813]  DEFAULT ((0)),
[iZonaHoraria_verano] [int] NOT NULL CONSTRAINT [DF__ccoCallsO__iZona__526F16A8]  DEFAULT ((0)),
[iZonaHoraria2] [int] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_iZonaHoraria2]  DEFAULT ((0)),
[iZonaHoraria_verano2] [int] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_iZonaHoraria_verano2]  DEFAULT ((0)),
[iZonaHoraria3] [int] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_iZonaHoraria3]  DEFAULT ((0)),
[iZonaHoraria_verano3] [int] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_iZonaHoraria_verano3]  DEFAULT ((0)),
[iZonaHoraria4] [int] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_iZonaHoraria4]  DEFAULT ((0)),
[iZonaHoraria_verano4] [int] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_iZonaHoraria_verano4]  DEFAULT ((0)),
[iZonaHoraria5] [int] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_iZonaHoraria5]  DEFAULT ((0)),
[iZonaHoraria_verano5] [int] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_iZonaHoraria_verano5]  DEFAULT ((0)),
[list_id] [int] NOT NULL CONSTRAINT [DF_ccoCallsOutSource_list_id]  DEFAULT ((0)),
CONSTRAINT [PK_ccoCallsOutSource] PRIMARY KEY CLUSTERED 
(
[callout_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'ccTipoCalifOUT - Create Table'
		set @Sql='CREATE TABLE [dbo].[ccTipoCalifOUT](
	[calif_id] [smallint] NOT NULL,
	[Description] [varchar](40) NOT NULL,
	[autoTime] [int] NOT NULL CONSTRAINT [DF__cctipocal__autoT__01342732]  DEFAULT (0),
	[CanReprogram] [bit] NOT NULL CONSTRAINT [DF__cctipocal__CanRe__09C96D33]  DEFAULT (0),
	[orden] [tinyint] NOT NULL CONSTRAINT [DF_ccTipoCalifOUT_orden]  DEFAULT (255),
	[idTipoLista] [int] NOT NULL CONSTRAINT [DF__ccTipoCal__idTip__0A93743A]  DEFAULT (0),
	[CalifOut_Status] [bit] NOT NULL CONSTRAINT [DF_ccTipoCalifOut_Status]  DEFAULT ((1)),
	[keepDial] [bit] NOT NULL CONSTRAINT [DF_ccTipoCalifOUT_keepDial]  DEFAULT ((0)),
	[autoCallback] [bit] NOT NULL CONSTRAINT [DF_ccTipoCalifOUT_autoCAllback]  DEFAULT ((0)),
 CONSTRAINT [PK_ccTipoCalifOUT] PRIMARY KEY CLUSTERED 
(
	[calif_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'ccoDialers - Create Table'
		set @Sql='CREATE TABLE [dbo].[ccoDialers](
	[dialer_id] [int] IDENTITY(1,1) NOT NULL,
	[Descripcion] [varchar](15) NOT NULL,
	[Puerto] [smallint] NOT NULL,
	[Extension] [smallint] NOT NULL CONSTRAINT [DF_ccoDialers_Extension]  DEFAULT (0),
	[Status] [tinyint] NOT NULL CONSTRAINT [DF_ccoDialers_Status]  DEFAULT (0),
	[provedor_id] [smallint] NULL DEFAULT (1),
	[XferType] [tinyint] NOT NULL CONSTRAINT [DF_ccoDialers_XferType]  DEFAULT ((3)),
 CONSTRAINT [PK_ccodialers] PRIMARY KEY NONCLUSTERED 
(
	[dialer_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'ccInbound - Create Table'
		set @Sql='CREATE TABLE [dbo].[ccInbound](
[cli_id] [smallint] NULL,
[Inbound_id] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
[descripcion] [varchar](50) NOT NULL,
[Status] [smallint] NOT NULL CONSTRAINT [DF_ccInbound_Status]  DEFAULT ((1)),
[dnis] [varchar](4) NOT NULL CONSTRAINT [DF_ccInbound_dnis]  DEFAULT (''''),
[standby] [smallint] NOT NULL CONSTRAINT [DF_ccInbound_standby]  DEFAULT ((0)),
[tNotas] [int] NOT NULL CONSTRAINT [DF_ccInbound_tNotas]  DEFAULT ((10)),
[tMaxWaitCall] [smallint] NOT NULL CONSTRAINT [DF_ccInbound_tMaxWaitCall]  DEFAULT ((120)),
[nMaxQue] [smallint] NOT NULL CONSTRAINT [DF_ccInbound_nMaxQue]  DEFAULT ((6)),
[Msg_id] [int] NULL,
[tel_maxwait] [varchar](15) NOT NULL CONSTRAINT [DF_ccInbound_tel_maxwait]  DEFAULT (''''),
[tel_maxqueue] [varchar](15) NOT NULL CONSTRAINT [DF_ccInbound_tel_maxqueue]  DEFAULT (''''),
[tel_outservice] [varchar](15) NOT NULL CONSTRAINT [DF_ccInbound_tel_outservice]  DEFAULT (''''),
[tel_noct] [varchar](15) NOT NULL CONSTRAINT [DF_ccInbound_tel_noct]  DEFAULT (''''),
[bnocturno] [tinyint] NOT NULL CONSTRAINT [DF_ccInbound_bnocturno]  DEFAULT ((0)),
[ShowCalifWnd] [bit] NOT NULL CONSTRAINT [DF__ccInbound__ShowC__6FD49106]  DEFAULT ((1)),
[StartTimerOnHangUp] [bit] NOT NULL CONSTRAINT [DF__ccInbound__Start__70C8B53F]  DEFAULT ((1)),
[voicePath] [varchar](30) NULL CONSTRAINT [DF_ccInbound_voicePath]  DEFAULT (''''),
[IDArea] [smallint] NULL,
[editableCallKey] [bit] NOT NULL CONSTRAINT [DF__ccInbound__edita__44AB0736]  DEFAULT ((0)),
[cam_id] [smallint] NULL,
[queuePosition] [bit] NOT NULL CONSTRAINT [DF_ccInbound_queuePosition]  DEFAULT ((0)),
[minCallBackAbandon] [smallint] NOT NULL CONSTRAINT [DF_ccInbound_minCallBackAbandon]  DEFAULT ((30)),
[minCallBackAbandonXpire] [smallint] NOT NULL CONSTRAINT [DF_ccInbound_minCallBackAbandonXpire]  DEFAULT ((240)),
[statuscall_id_Array] [varchar](1000) NOT NULL CONSTRAINT [DF_ccInbound_statuscall_id_Array]  DEFAULT ((0)),
[tMaxQueueCallBack] [smallint] NOT NULL CONSTRAINT [DF_ccInbound_tMaxQueueCallBack]  DEFAULT ((0)),
[stopRecording] [bit] NOT NULL CONSTRAINT [DF_ccInbound_stopRecording]  DEFAULT (''false''),
[dialPrefixOverflow] [varchar](10) NOT NULL CONSTRAINT [DF_ccInbound_dialPrefixOverflow]  DEFAULT (''''),
[OpriorityT] [smallint] NOT NULL CONSTRAINT [DF_ccInbound_OpriorityT]  DEFAULT ((0)),
[callerIdDesc] [varchar](15) NULL DEFAULT (''''),
CONSTRAINT [PK_ccInbound] PRIMARY KEY CLUSTERED 
(
[Inbound_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'ccDNIS - Create Table'
		set @Sql='CREATE TABLE [dbo].[ccDNIS](
	[dni_id] [smallint] NOT NULL,
	[dni_numero] [varchar](50) NULL,
	[dni_tipo] [tinyint] NULL,
	[tipodni_id] [int] NOT NULL,
	[dni_tpoMaxEspera] [smallint] NOT NULL,
	[dni_Descripcion] [varchar](40) NOT NULL,
	[dni_Status] [bit] NOT NULL CONSTRAINT [DF_ccDNIS_dni_Status]  DEFAULT ((1)),
	[dni_isBlock] [bit] NOT NULL CONSTRAINT [DF_ccDnis_isBlock]  DEFAULT ((0)),
 CONSTRAINT [PK_ccDNIS] PRIMARY KEY CLUSTERED 
(
	[dni_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]'
		
	EXEC(@Sql)

		set @process = 'ccMenus - Create Table'
		set @Sql='CREATE TABLE [dbo].[ccMenus](
	[menu_id] [smallint] NOT NULL,
	[menu_descrip] [varchar](250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[parent] [smallint] NULL,
	[Nivel] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ordengral] [smallint] NOT NULL,
	[type] [tinyint] NOT NULL,
	[HelpSWF] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ccMenus] PRIMARY KEY CLUSTERED 
(
	[menu_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]'
		
	EXEC(@Sql)

		set @process = 'Charts - Create Table'
		set @Sql='CREATE TABLE [dbo].[Charts](
[id] [int] NOT NULL,
[name] [nvarchar](100) NOT NULL,
[type] [nvarchar](1) NOT NULL,
CONSTRAINT [PK_Charts] PRIMARY KEY CLUSTERED 
(
[name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]'
					
	EXEC(@Sql)
	
		set @process = 'RepOutDialDetail - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepOutDialDetail](
[date] [datetime] NOT NULL,
[callKey] [varchar](20) NOT NULL,
[telephone] [varchar](30) NOT NULL,
[dialResultId] [int] NOT NULL,
[dialResult] [varchar](20) NOT NULL,
[campaignId] [int] NOT NULL,
[campaign] [varchar](40) NOT NULL,
[timeMessage] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
							
	EXEC(@Sql)
	
		set @process = 'ReportsCharts - Create Table'
		set @Sql='CREATE TABLE [dbo].[ReportsCharts](
[id] int NOT NULL,
[reportName] [nvarchar](100) NOT NULL,
[chartType] [nvarchar](1) NOT NULL,
[x1] [nvarchar] (100) NOT NULL,
[subX1] [nvarchar] (100) NOT NULL,
[x2] [nvarchar] (100) NOT NULL,
[subX2] [nvarchar] (100) NOT NULL,
[countColumn] [nvarchar] (200) NOT NULL,
[chartDescription] [nvarchar](255) NOT NULL
CONSTRAINT [PK_ReportsCharts] PRIMARY KEY CLUSTERED 
(
[id] ASC,
[reportName] ASC,
[chartType] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]'
					
	EXEC(@Sql)
	
		set @process = 'Filters - Create Table'
		set @Sql='CREATE TABLE [dbo].[Filters](
[id] [int] NOT NULL,
[name] [nvarchar](50) NOT NULL,
[type] [int] NOT NULL,
[xmlParentNode] [nvarchar](50) NOT NULL,
[xmlChildNode] [nvarchar](50) NOT NULL,
CONSTRAINT [PK_Filters] PRIMARY KEY CLUSTERED 
(
[name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]'
					
	EXEC(@Sql)
	
		set @process = 'ccTemplates - Create Table'
		set @Sql='CREATE TABLE dbo.ccTemplates(
[id] [int] NOT NULL,
[User_id] [int] NOT NULL,
[parameters] [varchar](max) NOT NULL,
[reportName] [varchar](255) NOT NULL,
[date] [datetime] NOT NULL
)'
					
	EXEC(@Sql)
	
		set @process = 'ReportsFilters - Create Table'
		set @Sql='CREATE TABLE [dbo].[ReportsFilters](
[reportName] [nvarchar](100) NOT NULL,
[filterName] [nvarchar](50) NOT NULL,
[id] [int] NOT NULL,
CONSTRAINT [PK_ReportsFilters] PRIMARY KEY CLUSTERED 
(
[reportName] ASC,
[filterName] ASC,
[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[ReportsFilters]  WITH CHECK ADD  CONSTRAINT [FK_ReportsFilters_FilterName] FOREIGN KEY([filterName])
REFERENCES [dbo].[Filters] ([name])
ON UPDATE CASCADE
ON DELETE CASCADE

ALTER TABLE [dbo].[ReportsFilters] CHECK CONSTRAINT [FK_ReportsFilters_FilterName]'
					
	EXEC(@Sql)
	
		set @process = 'RepOutCalls - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepOutCalls](
[date] [datetime] NOT NULL,
[areaId] [int] NOT NULL,
[area] [varchar](255) NOT NULL,
[workgroupId] [int] NOT NULL,
[workgroup] [varchar](255) NOT NULL,
[campaignId] [int] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[userId] [int] NOT NULL,
[user] [varchar](255) NOT NULL,
[ntotal] [int] NOT NULL,
[nxfer] [int] NOT NULL,
[nnoagent] [int] NOT NULL,
[nanswer] [int] NOT NULL,
[nnoanswer] [int] NOT NULL,
[nlost] [int] NOT NULL,
[nabndxfer] [int] NOT NULL,
[nabndring] [int] NOT NULL,
[nabnddialog] [int] NOT NULL,
[postot] [int] NOT NULL,
[postime] [int] NOT NULL,
[nhangup] [int] NOT NULL,
[tatencion] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
					
	EXEC(@Sql)
	
		set @process = 'FiltersMenus - Create Table'
		set @Sql='CREATE TABLE [dbo].[FiltersMenus](
[id] [int] IDENTITY(1,1) NOT NULL,
[name] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
CONSTRAINT [PK_FiltersMenus] PRIMARY KEY CLUSTERED 
(
[name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)'
					
	EXEC(@Sql)
	
		set @process = 'FavoriteTemplates - Create Table'
		set @Sql='CREATE TABLE [dbo].[FavoriteTemplates](
[id] [int] NOT NULL,
[userId] [int] NOT NULL,
[parameters] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reportName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date] [datetime] NOT NULL,
CONSTRAINT [PK_FavoriteTemplates] PRIMARY KEY CLUSTERED 
(
[userId] ASC,
[reportName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)'
					
	EXEC(@Sql)
	
		set @process = 'ReportsFiltersMenus - Create Table'
		set @Sql='CREATE TABLE [dbo].[ReportsFiltersMenus](
[idReport] [int] NOT NULL,
[filterMenuName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)

ALTER TABLE [dbo].[ReportsFiltersMenus]  WITH CHECK ADD  CONSTRAINT [FK_ReportsFiltersMenus_FiltersMenus] FOREIGN KEY([filterMenuName])
REFERENCES [dbo].[FiltersMenus] ([name])
ON UPDATE CASCADE
ON DELETE CASCADE

ALTER TABLE [dbo].[ReportsFiltersMenus] CHECK CONSTRAINT [FK_ReportsFiltersMenus_FiltersMenus]'
					
	EXEC(@Sql)
	
		set @process = 'RepAgentGI - Create Table'
		set @Sql='CREATE TABLE RepAgentGI(
[date] [datetime] not null,
[userId] [int] NOT NULL,
[user] [varchar](255) NOT NULL,
[login] [varchar](20) NOT NULL,
[nxferin] [int] NOT NULL,
[nanswerin] [int] NOT NULL,
[nabndxferin] [int] NOT NULL,
[nabndringin] [int] NOT NULL,
[nabnddlgin] [int] NOT NULL,
[abndaxferin] [int] NOT NULL,
[nnoanswerin] [int] NOT NULL,
[nlostin] [int] NOT NULL,
[tdialogin] [int] NOT NULL,
[tnotesin] [int] NOT NULL,
[tringin] [int] NOT NULL,
[txferin] [int] NOT NULL,
[nxferout] [int] NOT NULL,
[nanswerout] [int] NOT NULL,
[nabndxferout] [int] NOT NULL,
[nabndringout] [int] NOT NULL,
[nabnddlgout] [int] NOT NULL,
[abndaxferout] [int] NOT NULL,
[nnoanswerout] [int] NOT NULL,
[nlostout] [int] NOT NULL,
[tdialogout] [int] NOT NULL,
[tnotesout] [int] NOT NULL,
[tringout] [int] NOT NULL,
[txferout] [int] NOT NULL,
[nother] [int] NOT NULL,
[tunknown] [int] NOT NULL,
[tnotav] [int] NOT NULL,
[tlog] [int] NOT NULL,
[treq] [int] NOT NULL,
[tav] [int] NOT NULL,
[tother] [int] NOT NULL,
[tprob] [int] NOT NULL,
[nmohin] [int] NOT NULL,
[nmohout] [int] NOT NULL,
[nwhagin] [int] NOT NULL,
[nwhagout] [int] NOT NULL,
[nwhcliin] [int] NOT NULL,
[nwhcliout] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
)'
					
	EXEC(@Sql)

		set @process = 'RepAgentKPI - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepAgentKPI](
[date] [datetime] NULL,
[login] [varchar](20) NOT NULL,
[userId] [int] NOT NULL,
[user] [varchar](255) NOT NULL,
[totalCalls] [int] NULL,
[callsIn] [int] NULL,
[callsOut] [int] NULL,
[finishedCalls10] [int] NULL,
[finishedCalls20] [int] NULL,
[finishedCalls30] [int] NULL,
[whoHung] [int] NULL,
[callsAvgTime] [decimal](10, 0) NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'

	EXEC(@Sql)
	
		set @process = 'RepAgentNotReady - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepAgentNotReady](
[date] [datetime] NOT NULL,
[login] [varchar](20) NOT NULL,
[userId] [int] NOT NULL,
[user] [varchar](255) NOT NULL,
[sessionTime] [int] NOT NULL,
[tiponotreadyId] [int] NOT NULL,
[descripcion] [varchar](255) NOT NULL,
[descripcion_count] [varchar](255) NOT NULL,
[count] [int] NOT NULL,
[descripcion_time] [varchar](255) NOT NULL,
[time] [int] NOT NULL,
[timeSeconds] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
	
	EXEC(@Sql)
	
		set @process = 'RepAgentNotReadyDet - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepAgentNotReadyDet](
[date] [datetime] NOT NULL,
[login] [varchar](20) NOT NULL,
[userId] [int] NOT NULL,
[user] [varchar](255) NOT NULL,
[tiponotreadyId] [int] NOT NULL,
[status] [varchar](255) NOT NULL,
[startDate] [datetime] NOT NULL,
[endDate] [datetime] NOT NULL,
[statusTime] [int] NOT NULL,
[statusTimeSeconds] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepAgentSession - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepAgentSession](
[date] [datetime] NOT NULL,
[login] [varchar](20) NOT NULL,
[userId] [int] NOT NULL,
[user] [varchar](255) NOT NULL,
[extension] [varchar](15) NOT NULL,
[loginTime] [datetime] NOT NULL,
[logoutTime] [datetime] NOT NULL,
[sessionTime] [int] NOT NULL,
[sessionTimeSeconds] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepInBill01900 - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepInBill01900](
[date] [smalldatetime] NOT NULL,
[inboundId] [smallint] NOT NULL,
[inbound] [varchar](255) NOT NULL,
[ntotalin] [smallint] NOT NULL,
[nxfer] [smallint] NOT NULL,
[tque2] [int] NOT NULL,
[txfer] [int] NOT NULL,
[tdialog] [int] NOT NULL,
[tring] [int] NOT NULL,
[nminutes] [int] NOT NULL,
[ncost] [int] not null,
[year] [int] NULL,
[month] [int] NULL,
[day] [int] NULL,
[hour] [int] NULL,
[minutes] [int] NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepInCalls - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepInCalls](
[date] [datetime] NOT NULL,
[inboundId] [int] NOT NULL,
[inbound] [varchar](255) NOT NULL,
[dnisId] [int] NULL,
[dnis] [varchar](255) NULL,
[workgroupId] [int] NOT NULL,
[workgroup] [varchar](255) NOT NULL,
[areaId] [int] NOT NULL,
[area] [varchar](255) NOT NULL,
[ntotalin] [int] NOT NULL,
[nxfer] [int] NOT NULL,
[nabndque] [int] NOT NULL,
[nxferque] [int] NOT NULL,
[nnoxfer] [int] NOT NULL,
[tquemax] [int] NOT NULL,
[tque] [int] NOT NULL,
[nque] [int] NOT NULL,
[nanswer] [int] NOT NULL,
[nnoanswer] [int] NOT NULL,
[nlost] [int] NOT NULL,
[nabndxferincall] [int] NOT NULL,
[nabndringincall] [int] NOT NULL,
[nabnddialogincall] [int] NOT NULL,
[postot] [int] NOT NULL,
[postime] [int] NOT NULL,
[SLP1] [int] NOT NULL,
[SLP2] [int] NOT NULL,
[avg] [int] NOT NULL,
[SL] [int] NOT NULL,
[nMoh] [int] NOT NULL,
[nWHag] [int] NOT NULL,
[nWHcl] [int] NOT NULL,
[year] [int] NULL,
[month] [int] NULL,
[day] [int] NULL,
[hour] [int] NULL,
[minutes] [int] NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepInDIDResume - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepInDIDResume](
[date] [datetime] NOT NULL,
[dnisId] [int] NOT NULL,
[dnis] [varchar](255) NOT NULL,
[dnis_count] [varchar](255) NOT NULL,
[count] [int] NOT NULL,
[year] [int] NULL,
[month] [int] NULL,
[day] [int] NULL,
[hour] [int] NULL,
[minutes] [int] NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepInEffectiveness - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepInEffectiveness](
[date] [datetime] NOT NULL,
[inboundId] [int] NOT NULL,
[inbound] [varchar](255) NOT NULL,
[ntotalin] [int] NOT NULL,
[nanswer] [int] NOT NULL,
[nabnd] [int] NOT NULL,
[tatention] [int] NOT NULL,
[tqueavg] [int] NOT NULL,
[tQuetot] [int] NOT NULL,
[nQuetot] [int] NOT NULL,
[tabndtot] [int] NOT NULL,
[SLP1] [int] NOT NULL,
[SLP2] [int] NOT NULL,
[tresp] [int] NOT NULL,
[poscount] [int] NOT NULL,
[Porcentaje] [int] NOT NULL,
[year] [int] NULL,
[month] [int] NULL,
[day] [int] NULL,
[hour] [int] NULL,
[minutes] [int] NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'PivotReports - Create Table'
		set @Sql='CREATE TABLE PivotReports(
[id] [int] not null,
[columns] [nvarchar](max) not null,
[complementColumns] [nvarchar](max) not null,
[pivotFunction] [varchar](6) not null
)'
		
	EXEC(@Sql)
	
		set @process = 'RepInCallsDetail - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepInCallsDetail](
[date] [datetime] NOT NULL,
[inboundId] [smallint] NOT NULL,
[ACDGroup] [varchar](255) NOT NULL,
[callStatusId] [tinyint] NOT NULL,
[callStatus] [varchar](255) NOT NULL,
[dispositionId] [smallint] NOT NULL,
[disposition] [varchar](255) NOT NULL,
[subDispositionId] [smallint] NOT NULL,
[subDisposition] [varchar](255) NOT NULL,
[dnisId] [smallint] NOT NULL,
[dnis] [varchar](255) NOT NULL,
[userId] [smallint] NOT NULL,
[username] [varchar] (100) NOT NULL,
[callKey] [varchar](255) NOT NULL,
[ANI] [varchar](255) NOT NULL,
[queueTime] [smallint] NOT NULL,
[xferTime] [smallint] NOT NULL,
[ringingTime] [smallint] NOT NULL,
[dialogTime] [smallint] NOT NULL,
[extension] [varchar](10) NOT NULL,
[agentName] [varchar] (500) NOT NULL,
[whoHangup] [smallint] NOT NULL,
[mohTime] [smallint] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepInNotTransferred - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepInNotTransferred](
[date] [datetime] NOT NULL,
[inboundId] [smallint] NOT NULL,
[ACDGroup] [varchar](255) NOT NULL,
[callStatusId] [smallint] NOT NULL,
[callStatus] [varchar](255) NOT NULL,
[callStatus_Count] [varchar](255) NOT NULL,
[count] [smallint] NOT NULL,
[areaId] [smallint] NOT NULL,
[area] [varchar](200) NOT NULL,
[workgroupId] [smallint] NOT NULL,
[wg] [varchar](20) NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepInDispositions - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepInDispositions](
[date] [datetime] NOT NULL,
[inboundId] [smallint] NOT NULL,
[ACDGroup] [varchar](255) NOT NULL,
[dispositionId] [smallint] NOT NULL,
[disposition] [varchar](255) NOT NULL,
[disposition_count] [varchar](255) NOT NULL,
[count] [smallint] NOT NULL,
[userId] [smallint] NOT NULL,
[agentName] [varchar] (500) NOT NULL,
[username] [varchar] (100) NOT NULL,
[areaId] [smallint] NOT NULL,
[area] [varchar](200) NOT NULL,
[workgroupId] [smallint] NOT NULL,
[wg] [varchar](20) NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepInSubDispositions - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepInSubDispositions](
[date] [datetime] NOT NULL,
[inboundId] [smallint] NOT NULL,
[ACDGroup] [varchar](255) NOT NULL,
[subDispositionId] [smallint] NOT NULL,
[subDisposition] [varchar](255) NOT NULL,
[subDisposition_count] [varchar](255) NOT NULL,
[count] [smallint] NOT NULL,
[userId] [smallint] NOT NULL,
[agentName] [varchar] (500) NOT NULL,
[username] [varchar] (100) NOT NULL,
[areaId] [smallint] NOT NULL,
[area] [varchar](200) NOT NULL,
[workgroupId] [smallint] NOT NULL,
[wg] [varchar](20) NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepInRejectedCalls - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepInRejectedCalls](
[dnisId] [int] NULL,            
[dnisNumber] [varchar](255) NULL,
[dnisDescription] [varchar](255) NULL,								
[inboundId] [int] NOT NULL,
[inbound] [varchar](255) NOT NULL,
[date] [datetime] NOT NULL,
[ANI] [varchar](255) NULL,
[port] [varchar](255) NULL,
[year] [int] NULL,
[month] [int] NULL,
[day] [int] NULL,
[hour] [int] NULL,
[minutes] [int] NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepIVRGeneral - Create Table'
		set @Sql='CREATE TABLE RepIVRGeneral(
[date] [datetime] NOT NULL,
[noTransferred] [int] NOT NULL,
[transferred] [int] NOT NULL,
[total] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
)'
		
	EXEC(@Sql)
	
		set @process = 'RepIVRByOptions - Create Table'
		set @Sql='CREATE TABLE RepIVRByOptions(
[date] [datetime] NOT NULL,
[levelOption] [varchar](255) NOT NULL,
[descriptionOption] [varchar](255) NOT NULL,
[quantityOption] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
)'
		
	EXEC(@Sql)
	
		set @process = 'RepOutCallsDetail - Create Table'
		set @Sql='CREATE TABLE RepOutCallsDetail(
[date] [datetime] NOT NULL,
[callKey] [varchar](255) NOT NULL,
[telephone] [varchar](255) NOT NULL,
[transfer] [int] NOT NULL,
[dialog] [int] NOT NULL, 
[nque] [int] NOT NULL,
[wrapup] [int] NOT NULL,
[CallDisposition] [varchar](255) NOT NULL,
[extension] [varchar](255) NOT NULL,
[userId] [int] NOT NULL,
[login] [varchar](255) NOT NULL,
[username] [varchar](255) NOT NULL,
[campaignId] [int] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[duration] [int] NOT NULL,
[ncost] [decimal](10,2) NOT NULL,
[iva] [int] NOT NULL,
[total] [decimal](10,2) NOT NULL,
[ByCarrier] [varchar](255) NOT NULL,
[Calltypes] [varchar](255) NOT NULL,
[dialType] [varchar](255) NOT NULL,
[whoHangUp] [varchar](255) NOT NULL,
[subDisposition] [varchar](255) NOT NULL,
[dialResult] [varchar](255) NOT NULL,
[calId] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
)'
		
	EXEC(@Sql)
	
		set @process = 'RepOutCallsByTelephone - Create Table'
		set @Sql='CREATE TABLE RepOutCallsByTelephone(
[date] [datetime] NOT NULL,
[telephone] [varchar](255) NOT NULL,
[callKey] [varchar](255) NOT NULL,
[campaignId] [int] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[quantity] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
)'
		
	EXEC(@Sql)
	
		set @process = 'RepOutCallBacks - Create Table'
		set @Sql='CREATE TABLE RepOutCallBacks(
[date] [datetime] NOT NULL,
[userId] [int] NOT NULL,
[user] [varchar](255) NOT NULL,
[campaignId] [int] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[callKey] [varchar](255) NOT NULL,
[originalTel] [varchar](255) NOT NULL,
[scheduledTel] [varchar](255) NOT NULL,
[originalDate] [datetime] NOT NULL,
[scheduledDate] [datetime] NOT NULL,
[status] [varchar](255) NOT NULL,
[dialDate] [varchar](255) NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
)'
		
	EXEC(@Sql)
	
		set @process = 'RepIVRDetail - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepIVRDetail](
[date] [datetime] NOT NULL,
[telephone] [varchar](255) NOT NULL,
[user] [varchar](255) NOT NULL,
[disposition] [varchar](255) NOT NULL,
[callid] [int] NOT NULL,
[options] [varchar](255) NOT NULL,
[statusTime] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
	) ON [PRIMARY]'

	EXEC(@Sql)
	
		set @process = 'RepOutDials - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepOutDials](
[date] [datetime] NOT NULL,
[campaignId] [int] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[workgroupId] [int] NOT NULL,
[workgroup] [varchar](255) NOT NULL,
[areaId] [int] NOT NULL,
[area] [varchar](255) NOT NULL,
[dialResultId] [int] NOT NULL,
[dialResult] [varchar](255) NOT NULL,
[descripcion_count] [varchar](255) NOT NULL,
[count] [int] NOT NULL,
[descripcion_avg] [varchar](255) NOT NULL,
[avg] [decimal](10,2) NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
)ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepIVRFirstOption - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepIVRFirstOption](
[date] [smalldatetime] NOT NULL,
[descriptionOption] [varchar](5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[option_Count] [varchar](11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Count] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
)'
		
	EXEC(@Sql)
	
		set @process = 'RepInChangeFlow - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepInChangeFlow](
[date] [smalldatetime] NOT NULL,
[time] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inboundId] [smallint] NOT NULL,
[inbound] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[weekday_count] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[count] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL,
CONSTRAINT [PK_RepInChangeFlow] PRIMARY KEY CLUSTERED 
(
[date] ASC,
[inboundId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]'
		
	EXEC(@Sql)
		
		set @process = 'RepOutCallBilling - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepOutCallBilling](
[date] [datetime] NOT NULL,
[campaignId] [smallint] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[userId] [smallint] NOT NULL,
[agentName] [varchar](500) NOT NULL,
[username] [varchar](100) NOT NULL,
[providerId] [smallint] NOT NULL,
[provider] [varchar](30) NOT NULL,
[tipoLlamadaId] [smallint] NOT NULL,
[tipoLlamada_count] [varchar](500) NOT NULL,
[count] decimal(20,2) NOT NULL,
[tipoLlamada] [varchar](500) NOT NULL,
[costo] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'GroupByReports - Create Table'
		set @Sql='CREATE TABLE [dbo].[GroupByReports](
	[id] [int] NOT NULL,
	[columns] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[groupByColumns] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)

		set @process = 'RepOutDispositions - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepOutDispositions](
[date] [datetime] NOT NULL,
[campaignId] [smallint] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[dispositionId] [smallint] NOT NULL,
[disposition] [varchar](255) NOT NULL,
[disposition_count] [varchar](255) NOT NULL,
[count] [smallint] NOT NULL,
[userId] [smallint] NOT NULL,
[agentName] [varchar] (500) NOT NULL,
[username] [varchar] (100) NOT NULL,
[areaId] [smallint] NOT NULL,
[area] [varchar](200) NOT NULL,
[wgId] [smallint] NOT NULL,
[wg] [varchar](20) NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepOutSubDispositions - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepOutSubDispositions](
[date] [datetime] NOT NULL,
[campaignId] [smallint] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[subDispositionId] [smallint] NOT NULL,
[subDisposition] [varchar](255) NOT NULL,
[subDisposition_count] [varchar](255) NOT NULL,
[count] [smallint] NOT NULL,
[userId] [smallint] NOT NULL,
[agentName] [varchar] (500) NOT NULL,
[username] [varchar] (100) NOT NULL,
[areaId] [smallint] NOT NULL,
[area] [varchar](200) NOT NULL,
[wgId] [smallint] NOT NULL,
[wg] [varchar](20) NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepOutKPI - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepOutKPI](
[date] [datetime] NOT NULL,
[campaignId] [smallint] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[totalCalls] [smallint] NOT NULL,
[avgXfer] [smallint] NOT NULL,
[avgCallTime] [smallint] NOT NULL,
[c10Secs] [smallint] NOT NULL,
[c20Secs] [smallint] NOT NULL,
[c30Secs] [smallint] NOT NULL,
[cMaxSecs] [smallint] NOT NULL,
[AnsweredCalls] [smallint] NOT NULL,
[answeredCallsPctg] [smallint] NOT NULL,
[remainingCalls] [smallint] NOT NULL,
[remainingCallsPctg] [smallint] NOT NULL,
[abandonedCalls] [smallint] NOT NULL,
[abandonedCallsPctg] [smallint] NOT NULL,
[avgTimeBetweenCalls] [smallint] NOT NULL,
[year] [int] NULL,
[month] [int] NULL,
[day] [int] NULL,
[hour] [int] NULL,
[minutes] [int] NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)

		set @process = 'RepSpecialTimes - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepSpecialTimes](
[date] [datetime] NOT NULL,
[campaignId] [int] NOT NULL,
[inboundId] [int] NOT NULL,
[campACDDescription] [varchar](255) NOT NULL,
[sessionTime] [int] NOT NULL,
[readyTime] [int] NOT NULL,
[dialogTime] [int] NOT NULL,
[notReadyTime] [int] NOT NULL,
[other] [int] NOT NULL,
[descripcion] [varchar](255) NOT NULL,
[descripcion_count] [varchar](255) NOT NULL,
[count] [int] NOT NULL,
[descripcion_time] [varchar](255) NOT NULL,
[time] [int] NOT NULL,
[timeSeconds] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
				
	EXEC(@Sql)
	
		set @process = 'ReportsFiltersRange - Create Table'
		set @Sql='CREATE TABLE ReportsFiltersRange(
	reportName	[nvarchar](100) NOT NULL,
	filterName	[nvarchar](50) NOT NULL, 
	id	[int] NOT NULL
)ON [PRIMARY]

ALTER TABLE ReportsFiltersRange ADD PRIMARY KEY (reportName, filterName, id)
ALTER TABLE ReportsFiltersRange ADD FOREIGN KEY (filterName) REFERENCES Filters([name])'
					
	EXEC(@Sql)
	
		set @process = 'RepOutTrunkBusy - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepOutTrunkBusy](
[date] [datetime] NOT NULL,
[campaignId] [smallint] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[trunk] [int] NOT NULL,
[tBusy] [int] NOT NULL,	
[Calls] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
	
	EXEC(@Sql)
	
		set @process = 'RepInTrunkBusy - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepInTrunkBusy](
[date] [datetime] NOT NULL,
[inboundId] [smallint] NOT NULL,
[inbound] [varchar](255) NOT NULL,
[trunk] [int] NOT NULL,
[tBusy] [int] NOT NULL,	
[Calls] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'

	EXEC(@Sql)
	
		set @process = 'RepTrunkBusy - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepTrunkBusy](
[date] [datetime] NOT NULL,
[trunk] [int] NOT NULL,
[tBusy] [int] NOT NULL,
[Calls] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'

	EXEC(@Sql)
	
		set @process = 'ReportsTotals - Create Table'
		set @Sql='CREATE TABLE [dbo].[ReportsTotals](
	[id] [int] NOT NULL,
	[totalColumns] [nvarchar](MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ReportsTotals] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]'

	EXEC(@Sql)
	
		set @process = 'IX_ccCallsIn_7 - Create Index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccCallsIn_7] ON [dbo].[ccCallsIn] 
(
	[IVR_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'

	EXEC(@Sql)
	
/***********************************************/	
/*** INSERCIONES A TABLAS DE NUEVOS REPORTES ***/
/***********************************************/	

		set @process = 'ccMenus - Insert'
		set @Sql='INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (1000, N''File'', 1000, N''A         '', 1, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (1010, N''Supervisor Groups'', 1000, N''B         '', 1, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (2000, N''Agents'', 2000, N''A         '', 2, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (2010, N''General Information'', 2000, N''B         '', 2, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (2020, N''Sessions'', 2000, N''B         '', 2, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (2030, N''Unavailable'', 2000, N''B         '', 2, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (2040, N''Unavailable Detail'', 2000, N''B         '', 2, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (2050, N''KPI Agents Report'', 2000, N''B         '', 2, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3000, N''ACD Groups'', 3000, N''A         '', 3, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3010, N''Call Detail'', 3000, N''B         '', 3, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3020, N''Calls by ACD Group DID general WG Area'', 3000, N''B         '', 3, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3030, N''Not Transferred by ACD Group general WG Area'', 3000, N''B         '', 3, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3040, N''Call Disposition by ACD Group general WG Area'', 3000, N''B         '', 3, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3060, N''Effectiveness'', 3000, N''B         '', 3, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3070, N''Change flow'', 3000, N''B         '', 3, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3080, N''Billing 01 900'', 3000, N''B         '', 3, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3100, N''Resume per DID'', 3000, N''B         '', 3, 2, N''Error'')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3110, N''Rejected Calls'', 3000, N''B         '', 3, 2, N''Error'')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3120, N''Call SubDisposition'', 3000, N''B         '', 3, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (4000, N''CampaignM'', 4000, N''A         '', 4, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (4010, N''Dialing Detail'', 4000, N''B         '', 4, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (4020, N''Answered Calls Detail'', 4000, N''B         '', 4, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (4030, N''Answered Calls by Campaign general wg area'', 4000, N''B         '', 4, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (4040, N''Call Disposition campaign wg area'', 4000, N''B         '', 4, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (4050, N''Dialing by Campaign wg area'', 4000, N''B         '', 4, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (4060, N''Call Billing'', 4000, N''B         '', 4, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (4070, N''Answered Calls per telephone number'', 4000, N''B         '', 4, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (4090, N''KPI Outbound Report'', 4000, N''B         '', 4, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (4100, N''Call SubDisposition'', 4000, N''B         '', 4, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (4110, N''CallBacks'', 4000, N''B         '', 4, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (6000, N''IVR'', 6000, N''A         '', 6, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (6010, N''IVR Detail'', 6000, N''B         '', 6, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (6020, N''IVR General'', 6000, N''B         '', 6, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (6030, N''First optionselected'', 6000, N''B         '', 6, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (6040, N''By Options'', 6000, N''B         '', 6, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (8000, N''General'', 8000, N''A         '', 8, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (8010, N''Trunks busy'', 8000, N''B         '', 8, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (8020, N''Outbound Trunks busy'', 8000, N''B         '', 8, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (8030, N''Inbound Trunks busy'', 8000, N''B         '', 8, 2, N'''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (8040, ''Special Times'', 8000, ''B'', 8, 2, '''')'
		
	EXEC(@Sql)
	
		set @process = 'charts - Insert'
		set @Sql='insert into charts
values(1,''Pie'',1)
insert into charts
values(2,''Area'',2)
insert into charts
values(3,''Bar'',2)
insert into charts
values(4,''Column'',2)
insert into charts
values(5,''Line'',2)
insert into charts
values(6,''Multiple Axes'',3)'
		
	EXEC(@Sql)
	
		set @process = 'ReportsCharts - Insert'
		set @Sql='insert into ReportsCharts values (2010, ''General Information'', 1, ''user'', '''', '''', '''',''sum([tav])'',''Ready time per user'')
insert into ReportsCharts values (2010, ''General Information'', 2, ''year|month|day|hour'', ''user'', '''', '''',''sum([tav])'',''Ready time per user by hour'')
insert into ReportsCharts values (2020, ''Sessions'', 1, ''user'', '''', '''', '''', ''sum([sessionTimeSeconds])'', ''Session time per user'')
insert into ReportsCharts values (2020, ''Sessions'', 2, ''year|month|day'', ''user'', '''', '''', ''sum([sessionTimeSeconds])'', ''Session time per user by day'')
insert into ReportsCharts values (2030, ''Unavailable'', 1, ''user'', '''', '''', '''', ''sum([count])'', ''Not ready use amount per user'')
insert into ReportsCharts values (2030, ''Unavailable'', 2, ''year|month|day'', ''user'', '''', '''', ''sum([count])'', ''Not ready use amount per user by day'')
insert into ReportsCharts values (2040, ''Unavailable Detail'', 1, ''status'', '''', '''', '''', '''', ''Not ready use detail per user'')
insert into ReportsCharts values (2040, ''Unavailable Detail'', 2, ''year|month|day'', ''status'', '''', '''', '''', ''Not ready use detail per user by day'')
insert into ReportsCharts values (2050, ''KPI Agents Report'', 1, ''user'', '''', '''', '''', ''sum([totalCalls])'', ''Total calls per user'')
insert into ReportsCharts values (2050, ''KPI Agents Report'', 2, ''year|month|day'', ''user'', '''', '''', ''sum([totalCalls])'', ''Total calls per user by day'')

insert into ReportsCharts values (3010, ''Call Detail Inbound'', 1, ''ACDGroup'', '''', '''', '''','''',''Calls detail per ACD Group'')
insert into ReportsCharts values (3010, ''Call Detail Inbound'', 2, ''year|month|day'', ''ACDGroup'', '''', '''','''',''Calls detail per ACD Group by day'')
insert into ReportsCharts values (3020, ''Calls by ACD Group DID general WG Area'', 1, ''inbound'', '''', '''', '''', ''sum([ntotalin])'',''Calls per ACD Group'')
insert into ReportsCharts values (3020, ''Calls by ACD Group DID general WG Area'', 2, ''year|month|day'', ''inbound'', '''', '''', ''sum([ntotalin])'',''Calls per ACD Group by day'')
insert into ReportsCharts values (3030, ''Not Transferred by ACD Group general WG Area'', 1, ''callStatus'', '''', '''', '''',''sum([count])'',''Not Transferred call status'')
insert into ReportsCharts values (3030, ''Not Transferred by ACD Group general WG Area'', 2, ''year|month|day'', ''callStatus'', '''', '''',''sum([count])'',''Not Transferred call status by day'')
insert into ReportsCharts values (3040, ''Call Disposition by ACD Group general WG Area'', 1, ''disposition'', '''', '''', '''',''sum([count])'',''Call Disposition per ACD Group'')
insert into ReportsCharts values (3040, ''Call Disposition by ACD Group general WG Area'', 2, ''year|month|day'', ''disposition'', '''', '''',''sum([count])'',''Call Disposition per ACD Group by day'')
insert into ReportsCharts values (3060, ''Effectiveness'', 1, ''inbound'', '''', '''', '''', ''sum([ntotalin])'',''Calls per ACD Group'')
insert into ReportsCharts values (3060, ''Effectiveness'', 2, ''year|month|day|hour'', ''inbound'', '''', '''', ''sum([ntotalin])'',''Calls per ACD Group by hour'')
INSERT INTO ReportsCharts VALUES (3070, ''Change flow'', ''1'', ''time'', '''', '''', '''', ''sum([count])'',''ACD Group activity per hour'')
INSERT INTO ReportsCharts VALUES (3070, ''Change flow'', ''2'', ''time'', ''weekday_Count'', '''', '''', ''sum([count])'',''ACD Group activity per hour by weekday'')
insert into ReportsCharts values (3080, ''Billing 01 900'', 1, ''inbound'', '''', '''', '''',''sum([ncost])'',''Billing 01 900 per ACD Group'')
insert into ReportsCharts values (3080, ''Billing 01 900'', 2, ''year|month|day'', ''inbound'', '''', '''',''sum([ncost])'',''Billing 01 900 per ACD Group by day'')
insert into ReportsCharts values (3100, ''Resume per DID'', 1, ''dnis'', '''', '''', '''', ''sum([count])'',''DID use'')
insert into ReportsCharts values (3100, ''Resume per DID'', 2, ''year|month|day|hour'', ''dnis'', '''', '''', ''sum([count])'',''DID use by hour'')
insert into ReportsCharts values (3110, ''Rejected Call'', 1, ''dnisNumber'', '''', '''', '''','''',''Rejected calls per dnis number'')
insert into ReportsCharts values (3110, ''Rejected Call'', 2, ''year|month|day'', ''dnisNumber'', '''', '''','''',''Rejected calls per dnis number by day'')
insert into ReportsCharts values (3120, ''Call Subdisposition by ACD Group general WG Area'', 1, ''subDisposition'', '''', '''', '''',''sum([count])'',''Call Subdisposition per ACD Group'')
insert into ReportsCharts values (3120, ''Call Subdisposition by ACD Group general WG Area'', 2, ''year|month|day'', ''subDisposition'', '''', '''',''sum([count])'',''Call Subdisposition per ACD Group by day'')

insert into ReportsCharts values (4010,''Dialing Detail'',1,''dialResult'','''','''','''', '''',''Dial Results per Campaign'')
insert into ReportsCharts values (4010,''Dialing Detail'',2,''campaign'',''dialResult'','''','''', '''',''Dial Results per Campaign'')
insert into ReportsCharts values (4020, ''Answered Calls Detail'', 1, ''campaign'', '''', '''', '''', '''',''Answered calls detail per Campaign'')
insert into ReportsCharts values (4020, ''Answered Calls Detail'', 2, ''year|month|day'', ''campaign'', '''', '''', '''',''Answered calls detail per Campaign by day'')
insert into ReportsCharts values (4030, ''Answered Calls by Campaign general wg area'', 1, ''campaign'', '''', '''', '''', '''',''Answer calls per Campaign'')
insert into ReportsCharts values (4030, ''Answered Calls by Campaign general wg area'', 2, ''year|month|day'', ''campaign'', '''', '''', '''',''Answer calls per Campaign by day'')
insert into ReportsCharts values (4040, ''Call Disposition by campaign wg area'', 1, ''disposition'', '''', '''', '''',''sum([count])'', ''Call dispositions per Campaign'')
insert into ReportsCharts values (4040, ''Call Disposition by campaign wg area'', 2, ''year|month|day'', ''disposition'', '''', '''',''sum([count])'',''Call dispositions per Campaign by day'')
insert into ReportsCharts values (4050, ''Dialing by Campaign wg area'', 1, ''dialResult'', '''', '''', '''', ''sum([count])'',''Dial Results per Campaign'')
insert into ReportsCharts values (4050, ''Dialing by Campaign wg area'', 2, ''year|month|day'', ''dialResult'', '''', '''', ''sum([count])'',''Dial Results per Campaign by day'')
insert into ReportsCharts values (4060, ''Call Billing'', 1, ''campaign'', '''', '''', '''', ''sum([costo])'',''Call billing per Campaign'')
insert into ReportsCharts values (4060, ''Call Billing'', 2, ''year|month|day|hour'', ''campaign'', '''', '''', ''sum([costo])'',''Call billing per Campaign by hour'')
insert into ReportsCharts values (4070, ''Answered Calls per telephone number'', 1, ''campaign'', '''', '''', '''', ''sum([quantity])'',''Answered calls per Campaign'')
insert into ReportsCharts values (4070, ''Answered Calls per telephone number'', 2, ''year|month|day'', ''campaign'', '''', '''', ''sum([quantity])'',''Answered calls per Campaign by day'')
insert into ReportsCharts values (4090, ''KPI Outbound'', 1, ''campaign'', '''', '''', '''','''',''Calls per Campaign'')
insert into ReportsCharts values (4090, ''KPI Outbound'', 2, ''year|month|day'', ''campaign'', '''', '''','''',''Calls per Campaign by day'')
insert into ReportsCharts values (4100, ''Call Subdisposition by Campaign general WG Area'', 1, ''subDisposition'', '''', '''', '''',''sum([count])'',''Call subdispositions per Campaign'')
insert into ReportsCharts values (4100, ''Call Subdisposition by Campaign general WG Area'', 2, ''year|month|day'', ''subDisposition'', '''', '''',''sum([count])'',''Call subdispositions per Campaign by day'')
insert into ReportsCharts values (4110, ''CallBacks'', 1, ''campaign'', '''', '''', '''', '''',''Callbacks per Campaign'')
insert into ReportsCharts values (4110, ''CallBacks'', 2, ''year|month|day'', ''campaign'', '''', '''', '''',''Callbacks per Campaign by day'')

insert into ReportsCharts values (6010, ''IVR Detail'', 1, ''options'', '''', '''', '''', '''',''Options use detail'')
insert into ReportsCharts values (6010, ''IVR Detail'', 2, ''year|month|day'', ''options'', '''', '''', '''',''Options use detail by day'')
insert into ReportsCharts values (6020, ''IVR General'', 1, ''date'', '''', '''', '''', ''sum([total])'',''Options selected'')
insert into ReportsCharts values (6020, ''IVR General'', 2, ''year|month|day'', ''date'', '''', '''', ''sum([total])'',''Options selected by day'')
INSERT INTO ReportsCharts VALUES (6030, ''First Option Selected'', ''1'', ''descriptionOption'', '''', '''', '''', ''sum([count])'',''First option selected'')
INSERT INTO ReportsCharts VALUES (6030, ''First Option Selected'', ''2'', ''year|month|day'', ''descriptionOption'', '''', '''', ''sum([count])'',''First option selected by day'')
insert into ReportsCharts values (6040, ''By Options'', 1, ''descriptionOption'', '''', '''', '''', ''sum([quantityOption])'',''Option use'')
insert into ReportsCharts values (6040, ''By Options'', 2, ''year|month|day'', ''descriptionOption'', '''', '''', ''sum([quantityOption])'',''Option use by day'')

insert into ReportsCharts values (8010, ''Trunks busy'', 1, ''trunk'', '''', '''', '''', ''sum([tBusy])'',''Busy time per trunk'')
insert into ReportsCharts values (8010, ''Trunks busy'', 2, ''year|month|day'', ''trunk'', '''', '''', ''sum([tBusy])'',''Busy time per trunk by day'')
insert into ReportsCharts values (8020, ''Outbound Trunks busy'', 1, ''trunk'', '''', '''', '''', ''sum([tBusy])'',''Busy time per trunk'')
insert into ReportsCharts values (8020, ''Outbound Trunks busy'', 2, ''year|month|day'', ''trunk'', '''', '''', ''sum([tBusy])'',''Busy time per trunk by day'')
insert into ReportsCharts values (8030, ''Inbound Trunks busy'', 1, ''trunk'', '''', '''', '''', ''sum([tBusy])'',''Busy time per trunk'')
insert into ReportsCharts values (8030, ''Inbound Trunks busy'', 2, ''year|month|day'', ''trunk'', '''', '''', ''sum([tBusy])'',''Busy time per trunk by day'')
insert into ReportsCharts values (8040, ''Special Times'', 1, ''campACDDescription'', '''', '''', '''', '''',''Campaign and ACD activity'')
insert into ReportsCharts values (8040, ''Special Times'', 2, ''year|month|day'', ''campACDDescription'', '''', '''', '''',''Campaign and ACD Group activity by day'')'
		
	EXEC(@Sql)
	
		set @process = 'filters - Insert'
		set @Sql='insert into filters
values(1,	''acds'',	7,	''Acds'',	''Acd'')
insert into filters
values(2,	''areas'',	4,	''Areas'',	''Area'')
insert into filters
values(3,	''calltypes'',	14,	''CallTypes'',	''CallType'')
insert into filters
values(4,	''campaigns'',	1,	''Campaigns'',	''Campaign'')
insert into filters
values(6,	''carriers'',	0,	''Carriers'',	''Carrier'')
insert into filters
values(7,	''dialresults'',	2,	''DialResults'',	''DialResult'')
insert into filters
values(8,	''dids'',	8,	''Dids'',	''Did'')
insert into filters
values(9,	''dispositions'',	9,	''Dispositions'',	''Disposition'')
insert into filters
values(10,	''subdispositions'',	10,	''Subdispositions'',	''Subdisposition'')
insert into filters
values(11,	''trunks'',	13,	''Trunks'',	''Trunk'')
insert into filters
values(12,	''unavailables'',	12,	''Unavailables'',	''Unavailable'')
insert into filters
values(13,	''users'',	6,	''Users'',	''User'')
insert into filters
values(14,	''workgroups'',	3,	''WorkGroups'',	''WorkGroup'')
insert into filters 
values(5,''providers'',11,''Providers'',''Provider'')'
		
	EXEC(@Sql)
	
		set @process = 'ReportsFilters - Insert'
		set @Sql='insert into ReportsFilters
values(''Dialing Detail'', ''campaigns'', 4010)
insert into ReportsFilters
values(''Dialing Detail'', ''dialresults'', 4010)
insert into ReportsFilters
values(''General Information'', ''users'', 2010)
insert into ReportsFilters
values(''Sessions'', ''users'', 2020)
insert into ReportsFilters
values(''Unavailable'', ''users'', 2030)
insert into ReportsFilters
values(''Unavailable'', ''unavailables'', 2030)
insert into ReportsFilters
values(''Unavailable Detail'', ''users'', 2040)
insert into ReportsFilters
values(''Unavailable Detail'', ''unavailables'', 2040)
insert into ReportsFilters
values(''KPI Agents Report'', ''users'', 2050)
insert into ReportsFilters
values(''Call Detail'', ''acds'', 3010)
insert into ReportsFilters
values(''Calls by ACD Group DID general WG Area'', ''acds'', 3020)
insert into ReportsFilters
values(''Calls by ACD Group DID general WG Area'', ''areas'', 3020)
insert into ReportsFilters
values(''Calls by ACD Group DID general WG Area'', ''workgroups'', 3020)
insert into ReportsFilters
values(''Not Transferred by ACD Group general WG Area'', ''acds'', 3030)
insert into ReportsFilters
values(''Not Transferred by ACD Group general WG Area'', ''areas'', 3030)
insert into ReportsFilters
values(''Not Transferred by ACD Group general WG Area'', ''workgroups'', 3030)
insert into ReportsFilters 
values(''Not Transferred by ACD Group general WG Area'',''calltypes'',3030)
insert into ReportsFilters
values(''Call Disposition by ACD Group general WG Area'', ''acds'', 3040)
insert into ReportsFilters
values(''Call Disposition by ACD Group general WG Area'', ''areas'', 3040)
insert into ReportsFilters
values(''Call Disposition by ACD Group general WG Area'', ''dispositions'', 3040)
insert into ReportsFilters
values(''Call Disposition by ACD Group general WG Area'', ''workgroups'', 3040)
insert into ReportsFilters
values(''Effectiveness'', ''acds'', 3060)
insert into ReportsFilters
values(''Change flow'', ''acds'', 3070)
insert into ReportsFilters
values(''Billing 01 900'', ''acds'', 3080)
insert into ReportsFilters
values(''Symposium'', ''acds'', 3090)
insert into ReportsFilters
values(''Resume per DID'', ''dids'', 3100)
insert into ReportsFilters
values(''Rejected Calls'', ''dids'', 3110)
insert into ReportsFilters
values(''Call SubDisposition'', ''acds'', 3120)
insert into ReportsFilters
values(''Call SubDisposition'', ''subdispositions'', 3120)
insert into ReportsFilters
values(''Answered Calls Detail'', ''campaigns'', 4020)
insert into ReportsFilters
values(''Answered Calls Detail'', ''users'', 4020)
insert into ReportsFilters
values(''Answered Calls by Campaign general wg area'', ''campaigns'', 4030)
insert into ReportsFilters
values(''Answered Calls by Campaign general wg area'', ''users'', 4030)
insert into ReportsFilters
values(''Answered Calls by Campaign general wg area'', ''areas'', 4030)
insert into ReportsFilters
values(''Answered Calls by Campaign general wg area'', ''workgroups'', 4030)
insert into ReportsFilters
values(''Call Disposition campaign wg area'', ''campaigns'', 4040)
insert into ReportsFilters
values(''Call Disposition campaign wg area'', ''areas'', 4040)
insert into ReportsFilters
values(''Call Disposition campaign wg area'', ''dispositions'', 4040)
insert into ReportsFilters
values(''Call Disposition campaign wg area'', ''workgroups'', 4040)
insert into ReportsFilters
values(''Dialing by Campaign wg area'', ''areas'', 4050)
insert into ReportsFilters
values(''Dialing by Campaign wg area'', ''campaigns'', 4050)
insert into ReportsFilters
values(''Dialing by Campaign wg area'', ''dialresults'', 4050)
insert into ReportsFilters
values(''Dialing by Campaign wg area'', ''workgroups'', 4050)
insert into ReportsFilters
values(''Answered Calls per telephone number'', ''campaigns'', 4070)
insert into ReportsFilters
values(''KPI Outbound Report'', ''campaigns'', 4090)
insert into ReportsFilters
values(''Call SubDisposition'', ''campaigns'', 4100)
insert into ReportsFilters
values(''Call SubDisposition'', ''subdispositions'', 4100)
insert into ReportsFilters
values(''CallBacks'', ''users'', 4110)
insert into ReportsFilters
values(''CallBacks'', ''campaigns'', 4110)
insert into ReportsFilters
values(''Outbound Trunks busy'', ''campaigns'', 8020)
insert into ReportsFilters
values(''Inbound Trunks busy'', ''acds'', 8030)
insert into ReportsFilters
values (''Calls by ACD Group DID general WG Area'', ''dids'', 3020)
insert into ReportsFilters
values(''Special Times'', ''campaigns'', 8040)
insert into ReportsFilters
values(''Special Times'', ''acds'', 8040)
insert into ReportsFilters values(''Call Billing'', ''campaigns'', 4060)
insert into ReportsFilters values(''Call Billing'', ''users'', 4060)
insert into ReportsFilters values(''Call Billing'', ''providers'', 4060)'
		
	EXEC(@Sql)
	
		set @process = 'FiltersMenus - Insert'
		set @Sql='INSERT [dbo].[FiltersMenus] ([name]) VALUES (N''date'')
INSERT [dbo].[FiltersMenus] ([name]) VALUES (N''groupby'')
INSERT [dbo].[FiltersMenus] ([name]) VALUES (N''select'')
INSERT [dbo].[FiltersMenus] ([name]) VALUES (N''filterby'')
INSERT [dbo].[FiltersMenus] ([name]) VALUES (N''range'')'
		
	EXEC(@Sql)
	
		set @process = 'ReportsFiltersMenus - Insert'
		set @Sql='INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4010, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4010, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4030, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4030, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (2010, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (2010, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (2050, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (2050, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (2040, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (2040, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (2030, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (2030, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (2020, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (2020, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3020, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3020, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3020, N''groupBy'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3060, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3060, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3080, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3080, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3100, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3100, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3010, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3010, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3030, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3030, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3040, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3040, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3120, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3120, N''filterby'')
INSERT ReportsFiltersMenus ([idReport], [filterMenuName]) VALUES (3110, N''date'')
INSERT ReportsFiltersMenus ([idReport], [filterMenuName]) VALUES (3110, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (6020, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (6020, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (6040, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (6040, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4020, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4020, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4070, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4070, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4110, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4110, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (6010, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (6010, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4050, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4050, N''filterby'')
INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) VALUES (6030, ''date'')
INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) VALUES (6030, ''filterby'')
INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) VALUES (3070, ''date'')
INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) VALUES (3070, ''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4040, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4040, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4100, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4100, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4090, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4090, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8040, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8040, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8010, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8010, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8010, N''groupBy'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8010, N''range'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8020, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8020, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8020, N''groupBy'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8020, N''range'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8030, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8030, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8030, N''groupBy'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (8030, N''range'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4060, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4060, N''filterby'')'
		
	EXEC(@Sql)
	
		set @process = 'PivotReports - Insert'
		set @Sql='insert into PivotReports
values (2030, ''descripcion_count|descripcion_time'', ''login|date|user|sessionTime|userId|tipoNotReadyId'', ''max'')
insert into pivotReports
values (3100, ''dnis_count'', ''date|dnisId'', ''max'')
insert into PivotReports values (3030,''callStatus_count'',''date|ACDGroup|area|wg|workgroupId|inboundId|areaId'', ''max'')
insert into PivotReports values (3040,''disposition_count'',''date|ACDGroup|agentName|username|area|wg|workgroupId|inboundId|areaId|dispositionId'', ''max'')
insert into PivotReports values(3120,''SubDisposition_count'',''date|ACDGroup|agentName|username|area|wg|workgroupId|inboundId|areaId'', ''max'')
insert into pivotReports
values (4050, ''descripcion_count|descripcion_avg'', ''date|campaignId|campaign|workgroupId|workgroup|areaId|area|dialResultId'', ''max'')
INSERT INTO PivotReports (id, columns, complementColumns, pivotFunction) VALUES (6030, ''option_Count'', ''date'', ''sum'')
INSERT INTO PivotReports (id, columns, complementColumns, pivotFunction) VALUES (3070, ''weekday_Count'', ''time|inbound'', ''sum'')
insert into pivotReports values(4040,''disposition_count'',''date|campaignId|campaign|agentName|username|areaId|area|wgId|wg|dispositionId'',''max'')
insert into PivotReports values(4100,''SubDisposition_count'',''date|campaign|agentName|username|area|wg'', ''max'')
insert into pivotReports
values (8040, ''descripcion_count|descripcion_time'', ''date|campACDDescription|sessionTime|readyTime|dialogTime|notReadyTime|other'', ''max'')
insert into pivotReports values(4060,''tipoLlamada_count'',''date|campaignId|campaign|userId|agentName|username|providerId|provider|tipoLlamadaId'',''max'')'
		
	EXEC(@Sql)
	
		set @process = 'GroupByReports - Insert'
		set @Sql='insert into GroupByReports values(8010, ''trunk|sum([tBusy]):tBusy|dbo.fPorcentaje(sum([tBusy])_TIMEGROUP):avgBusy|sum([Calls]):Calls'', ''trunk'')
insert into GroupByReports values(8020, ''campaignId|campaign|trunk|sum([tBusy]):tBusy|dbo.fPorcentaje(sum([tBusy])_TIMEGROUP):avgBusy|sum([Calls]):Calls'', ''campaignId|campaign|trunk'')
insert into GroupByReports values(8030, ''inboundId|inbound|trunk|sum([tBusy]):tBusy|dbo.fPorcentaje(sum([tBusy])_TIMEGROUP):avgBusy|sum([Calls]):Calls'', ''inboundId|inbound|trunk'')
insert into GroupByReports values(3020, ''inboundId|inbound|dnisId|dnis|workgroupId|workgroup|areaId|area|sum([ntotalin]):ntotalin|sum([nxfer]):nxfer|sum([nabndque]):nabndque|sum([nxferque]):nxferque|sum([nnoxfer]):nnoxfer|MAX([tquemax]):tquemax|sum([tque]):tque|sum([nque]):nque|sum([nanswer]):nanswer|sum([nnoanswer]):nnoanswer|sum([nlost]):nlost|sum([nabndxferincall]):nabndxferincall|sum([nabndringincall]):nabndringincall|sum([nabnddialogincall]):nabnddialogincall|AVG([postot]):postot|AVG([postime]):postime|min([SLP1]):SLP1|min([SLP2]):SLP2|ISNULL(sum(tque)/ NULLIF(sum(nque)_ 0)_ 0):avg|ISNULL(SUM(SLP1) * 100/ NULLIF(SUM(SLP2)_ 0)_ 0):SL|sum([nMoh]):nMoh|sum([nWHag]):nWHag|sum([nWHcl]):nWHcl'',''inboundId|inbound|dnisId|dnis|workgroupId|workgroup|areaId|area'')'
		
	EXEC(@Sql)
	
		set @process = 'ReportsFiltersRange - Insert'
		set @Sql='INSERT INTO ReportsFiltersRange VALUES(''Trunks busy'',''Trunks'',8010)
INSERT INTO ReportsFiltersRange VALUES(''Outbound Trunks busy'',''Trunks'',8020)
INSERT INTO ReportsFiltersRange VALUES(''Inbound Trunks busy'',''Trunks'',8030)'
					
	EXEC(@Sql)
	
		set @process = 'ReportsTotals - Insert'
		set @Sql='insert into ReportsTotals values (2010, ''sum:nxferin|sum:nanswerin|sum:nabndxferin|sum:nabndringin|sum:nabnddlgin|sum:abndaxferin|sum:nnoanswerin|sum:nlostin|sum:tdialogin|sum:tnotesin|sum:tringin|sum:txferin|sum:nxferout|sum:nanswerout|sum:nabndxferout|sum:nabndringout|sum:nabnddlgout|sum:abndaxferout|sum:nnoanswerout|sum:nlostout|sum:tdialogout|sum:tnotesout|sum:tringout|sum:txferout|sum:nother|sum:tunknown|sum:tnotav|sum:tlog|sum:treq|sum:tav|sum:tother|sum:tprob|sum:nmohin|sum:nmohout|sum:nwhagin|sum:nwhagout|sum:nwhcliin|sum:nwhcliout'')
insert into ReportsTotals values (2020, ''sum:sessionTime'')
insert into ReportsTotals values (2030, ''sum:count|sum:time|sum:sessionTime'')
insert into ReportsTotals values (2040, ''sum:count|sum:statusTime'')
insert into ReportsTotals values (2050, ''sum:totalCalls|sum:callsIn|sum:callsOut|sum:finishedCalls10|sum:finishedCalls20|sum:finishedCalls30|sum:whoHung|avg:callsAvgTime'')
insert into ReportsTotals values (3010, ''sum:queueTime|sum:xferTime|sum:ringingTime|sum:dialogTime|sum:whoHangup|sum:mohTime'')
insert into ReportsTotals values (3020, ''special:SL:ISNULL(SUM(SLP1) * 100/ NULLIF(SUM(SLP2)_ 0)_ 0)|special:avg:ISNULL(sum(tque)/ NULLIF(sum(nque)_ 0)_ 0)|sum:ntotalin|sum:nxfer|sum:nabndque|sum:nxferque|sum:nnoxfer|MAX:tquemax|sum:tque|sum:nque|sum:nanswer|sum:nnoanswer|sum:nlost|sum:nabndxferincall|sum:nabndringincall|sum:nabnddialogincall|avg:postot|avg:postime|sum:nMoh|sum:nWHag|sum:nWHcl'')
insert into ReportsTotals values (3030, ''sum:count'')
insert into ReportsTotals values (3040, ''sum:count'')
insert into ReportsTotals values (3060, ''sum:ntotalin|sum:nanswer|sum:nabnd|sum:tatention|avg:tqueavg|sum:tQuetot|sum:nQuetot|sum:tabndtot|sum:tresp|sum:poscount|special:Porcentaje:ISNULL(SUM(SLP1) * 100/ NULLIF(SUM(SLP2)_ 0)_ 0)'')
insert into ReportsTotals values (3070, ''sum:count'')
insert into ReportsTotals values (3080, ''sum:ntotalin|sum:nxfer|sum:tque2|sum:txfer|sum:tdialog|sum:tring|sum:nminutes|sum:ncost'')
insert into ReportsTotals values (3100, ''sum:count'')
insert into ReportsTotals values (3110, '''')
insert into ReportsTotals values (3120, ''sum:count'')
insert into ReportsTotals values (4010, ''sum:timeMessage'')
insert into ReportsTotals values (4020, ''sum:transfer|sum:dialog|sum:nque|sum:wrapup|sum:duration|sum:ncost|sum:total'')
insert into ReportsTotals values (4030, ''sum:ntotal|sum:nxfer|sum:nnoagent|sum:nanswer|sum:nnoanswer|sum:nlost|sum:nabndxfer|sum:nabndring|sum:nabnddialog|sum:postot|sum:postime|sum:nhangup|sum:tatencion'')
insert into ReportsTotals values (4040, ''sum:count'')
insert into ReportsTotals values (4050, ''sum:count|avg:avg'')
insert into ReportsTotals values (4060, ''sum:costo'')
insert into ReportsTotals values (4070, ''sum:quantity'')
insert into ReportsTotals values (4090, ''special:abandonedCallsPctg:convert(decimal(10_2)_ISNULL((sum(AbandonedCalls) * 100.00)/NULLIF(sum(totalCalls)_0)_0))|special:remainingCallsPctg:convert(decimal(10_2)_ISNULL((sum(AnsweredCalls) * 100.00)/NULLIF(sum(totalCalls)_0)_0))|sum:totalCalls|avg:avgXfer|avg:avgCallTime|sum:c10Secs|sum:c20Secs|sum:c30Secs|sum:cMaxSecs|sum:AnsweredCalls|sum:answeredCallsPctg|sum:remainingCalls|sum:abandonedCalls|avg:avgTimeBetweenCalls'')
insert into ReportsTotals values (4100, ''sum:count'')
insert into ReportsTotals values (4110, '''')
insert into ReportsTotals values (6010, ''sum:statusTime'')
insert into ReportsTotals values (6020, ''sum:noTransferred|sum:transferred|sum:total'')
insert into ReportsTotals values (6030, ''sum:Count'')
insert into ReportsTotals values (6040, ''sum:quantityOption'')
insert into ReportsTotals values (8010, ''special:avgBusy:dbo.fPorcentaje(sum([tBusy])_TIMEGROUP*(select count(DISTINCT [trunk])))|sum:Calls|sum:tBusy'')
insert into ReportsTotals values (8020, ''special:avgBusy:dbo.fPorcentaje(sum([tBusy])_TIMEGROUP*(select count(DISTINCT [trunk])))|sum:Calls|sum:tBusy'')
insert into ReportsTotals values (8030, ''special:avgBusy:dbo.fPorcentaje(sum([tBusy])_TIMEGROUP*(select count(DISTINCT [trunk])))|sum:Calls|sum:tBusy'')
insert into ReportsTotals values (8040, ''sum:count|sum:time'')'

	EXEC(@Sql)
	
/*************************************/
/*** TRIGGERS PARA NUEVOS REPORTES ***/
/*************************************/

		set @process = 'trigZonaHoraria - Create Trigger'
		set @Sql='CREATE TRIGGER [dbo].[trigZonaHoraria] ON [dbo].[ccoCallsOutSource]
FOR INSERT,UPDATE
AS
SET NOCOUNT ON
begin
if update(cal_telefono) begin
	update ccoCallsOutSource 
	set iZonaHoraria = dbo.fnGetTimeZone(cs.cal_telefono,0),
	iZonaHoraria_verano = dbo.fnGetTimeZone(cs.cal_telefono,1)
	from ccoCallsOutSource cs 
	inner join inserted i
	on cs.callout_id = i.callout_id
end

if update(cal_telefono2) begin
	update ccoCallsOutSource 
	set iZonaHoraria2 = dbo.fnGetTimeZone(cs.cal_telefono2,0),
	iZonaHoraria_verano2 = dbo.fnGetTimeZone(cs.cal_telefono2,1)
	from ccoCallsOutSource cs 
	inner join inserted i
	on cs.callout_id = i.callout_id
end

if update(cal_telefono3) begin
	update ccoCallsOutSource 
	set iZonaHoraria3 = dbo.fnGetTimeZone(cs.cal_telefono3,0),
	iZonaHoraria_verano3 = dbo.fnGetTimeZone(cs.cal_telefono3,1)
	from ccoCallsOutSource cs 
	inner join inserted i
	on cs.callout_id = i.callout_id
end

if update(cal_telefono4) begin
	update ccoCallsOutSource 
	set iZonaHoraria4 = dbo.fnGetTimeZone(cs.cal_telefono4,0),
	iZonaHoraria_verano4 = dbo.fnGetTimeZone(cs.cal_telefono4,1)
	from ccoCallsOutSource cs 
	inner join inserted i
	on cs.callout_id = i.callout_id
end

if update(cal_telefono5) begin
	update ccoCallsOutSource 
	set iZonaHoraria5 = dbo.fnGetTimeZone(cs.cal_telefono5,0),
	iZonaHoraria_verano5 = dbo.fnGetTimeZone(cs.cal_telefono5,1)
	from ccoCallsOutSource cs 
	inner join inserted i
	on cs.callout_id = i.callout_id	
end
end'
		
	EXEC(@Sql)
	
/**************************************/
/*** FUNCIONES PARA NUEVOS REPORTES ***/
/**************************************/

		set @process = 'Limpia - Create Function'
		set @Sql='CREATE FUNCTION [dbo].[Limpia](@Cadena varchar(32))
RETURNS varchar(32) AS  
BEGIN
if datalength(@Cadena) > 1 begin
	return dbo.Limpia(left(@Cadena, 1)) + dbo.Limpia(substring(@Cadena, 2, 255))
end else begin
	return case when CHARINDEX(@Cadena, ''1234567890'') > 0 then @Cadena else '''' end
end
return ''''
end'
		
	EXEC(@Sql)

		set @process = 'Completa - Create Function'
		set @Sql='CREATE function [dbo].[Completa](@Cadena varchar(32))
RETURNS varchar(32) 
AS  
BEGIN
declare @resultado varchar(32)
declare @ld varchar(5)
declare @pais varchar(2)

select @pais = valor from ccSettings where setting_id = 104
select @ld = valor from ccSettings where setting_id = 17
select @resultado = dbo.limpia(@Cadena)

--Completa 1:México 2:Argentina 3:Colombia 4:USA 5:Chile 6: venezuela 7: UK 8: arabia saudita 9: Australia
if @pais = 1 
 begin
	--Empieza Mexico
	select @resultado = case 
	 when (len(@resultado)=8 and len(@ld)=2) or (len(@resultado)=7 and len(@ld)=3) then @resultado
	 when len(@resultado)=10 then 
	   case when left(@resultado, len(@ld)) = @ld 
		then right(@resultado, 10 - len(@ld)) else ''01'' + @resultado end
	 when len(@resultado)=12 then 
	   case when left(@resultado, 2) = ''01'' then
		 case when substring(@resultado, 3, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	 when len(@resultado)=13 then
	   case when left(@resultado, 3) in (''044'', ''045'') then
		 case when substring(@resultado, 4, len(@ld)) = @ld then
		   ''044'' + right(@resultado, 10) else ''045'' + right(@resultado, 10) 
		 end
	   else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	--Termina Mexico
	return @resultado
 end

if @pais = 2 
 begin
	-- Empieza Argentina
	select @resultado = case 
	 when (len(@resultado)=7 and len(@ld)=3) or (len(@resultado)=6 and len(@ld)=4) then 
		@resultado
	-- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
	-- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
	 when len(@resultado) = 8 then
		case when len(@ld) = 4 then
			case when left(@resultado,2) = ''15'' then @resultado end
		else 
			case when len(@ld) = 2 then @resultado end
		end
	-- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
	 when len(@resultado)=9 then
		case when left(@resultado, 2) = ''15'' then @resultado else ''E_NV_Cel'' end
	-- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
	 -- Si es diferente se le agrega un 0 para llamadas de larga distancia
	 when len(@resultado)=10 then 
	   case when left(@resultado, len(@ld)) = @ld 
		then right(@resultado, 10 - len(@ld)) else 
			case when left(@resultado,2) = ''15'' then @resultado else ''0'' + @resultado end 
	   end
	-- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
	-- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
	 when len(@resultado)=11 then 
	   case when left(@resultado, 1) = ''0'' then
		 case when substring(@resultado, 2, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	-- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
	-- si no es local se le agrega el 0 y se marca el numero
	 when len(@resultado)=12 then
		case when left(@resultado, len(@ld)) = @ld then 
			case when substring(@resultado, len(@ld) + 1, 2) = ''15'' then 
				right(@resultado,12 - len(@ld)) else ''E_NV_Cel'' end else ''0'' + @resultado end
	-- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
	 when len(@resultado)=13 then
		case when left(@resultado, 1) = ''0'' then
			case when substring(@resultado, 2, len(@ld)) = @ld then substring(@resultado, len(@ld) + 2, 12 - len(@ld)) else @resultado end
		else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	--Termina Argentina	
	return @resultado	
 end

if @pais = 3 
 begin
	--Empieza colombia
	select @resultado = case 
	--Si son 7 digitos, se regresa igual
	 when len(@resultado)=7 then 
		@resultado
	--Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
	 when len(@resultado) = 8  then
		case when left(@resultado,1) = @ld then right(@resultado,7) else @resultado end		
	-- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
	 when len(@resultado)=10 then
		case when left(@resultado,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then ''0'' + @resultado 
		else
			''E_NV_Cel'' 
		end
	--Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
	--prefijo de celular
	 when len(@resultado)=11 then 
		case when left(@resultado,1)=''0'' then
			case when substring(@resultado,2,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then @resultado else ''E_NV_Cel'' end
		else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end	

	-- Termina Colombia
	return @resultado	
 end

if @pais = 4 
 begin
	--Empieza USA
	select @resultado = case len(@resultado)
	 when 3 then
		case @resultado when ''911'' then @resultado else ''E_NV_Longitud'' end
	 when 7 then @resultado
	 when 10 then 
	   case when left(@resultado, len(@ld)) = @ld 
		then right(@resultado, 10 - len(@ld)) else ''1'' + @resultado end
	 when 11 then 
	   case when left(@resultado, 1) = ''1'' then
		 case when substring(@resultado, 2, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	else ''E_NV_Longitud'' end

	--Termina USA
	return @resultado
 end

if @pais = 5 
 begin
	select @resultado = case len(@resultado) 
	 when 6 then @resultado 
	 when 7 then @resultado
	-- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
	 when 8 then

		case when @ld = left(@resultado,len(@ld)) then right(@resultado,8-len(@ld)) else				
			case when left(@resultado,1) in (8,9) then ''09'' + @resultado else
				case when left(@resultado,1) = ''6'' then case when left(@resultado,2) in (61,63,64,65,67) then  @resultado else ''09'' + @resultado end
				 else case when left(@resultado,1) = ''7'' then case when left(@resultado,2) in (71,72,73,75) then @resultado else ''09'' + @resultado end else @resultado end end	
			 end
		end
	-- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
	-- de telefonia voIp se le agrega el 0 al inicio
	 when 9 then
		case when @ld = left(@resultado,2) then right(@resultado,7) else
			case when left(@resultado,2) in (41,32,65) then @resultado else 
				case when left(@resultado,2) = ''44'' then ''0'' + @resultado else 
					case when left(@resultado,1) = ''9'' and substring(@resultado,2,1) in (6,7,8,9) then ''0'' + @resultado else ''E_NV_Longitud'' end
				 end
			end
		end
	 when 10 then
		case when left(@resultado,2) = ''09'' then @resultado else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	-- Termina Chile
	return @resultado
 end

-- Venezuela
if @pais = 6 begin
	select @resultado = case len(@resultado)
		when 7 then @resultado
		when 10 then ''0'' + @resultado
		when 11 then 
			case when left(@resultado,1) = ''0'' then @resultado else ''E_NV_Longitud'' end
		else 
	    ''E_NV_Longitud'' end
end
--Termina Venezuela

-- UK
if @pais = 7 begin
	select @resultado = case len(@resultado)
		when 11 then
			case left(@resultado,1)
				when ''0'' then @resultado else ''E_NV_Longitud''
			end
		when 10 then
			case left(@resultado,1)
				when ''0'' then @resultado else ''0'' + @resultado
			end
		when 9 then
			case when left(@resultado,1) <> ''0'' then ''0'' + @resultado else ''E_NV_Longitud'' end
		when 8 then
			case when substring(@resultado, 1, 2) = ''08'' then @resultado else ''E_NV_Longitud'' end
		when 7 then
			case when left(@resultado,1) = ''8'' then ''0'' + @resultado else ''E_NV_Longitud'' end
		else
		''E_NV_Longitud''
	end
end
-- Termina UK

if @pais = 8 begin -- arabia saudita
	select @resultado = case len(@resultado)
	when 7 then @resultado
	when 8 then case substring(@resultado, 1, 1) when @ld then right(@resultado, 7) else ''0'' + @resultado end
	when 9 then case substring(@resultado, 1, 1) when ''5'' then ''0'' + @resultado 
				when ''0'' then case substring(@resultado, 2, 1) 
						when @ld then right(@resultado, 7) else @resultado end 
				else ''E_NV_Longitud''
				end
	when 10 then case substring(@resultado, 2, 1) when ''5'' then @resultado else ''E_NV_Longitud'' end
	when 11 then case substring(@resultado, 2, 1) 
					when ''8'' then case substring(@resultado, 3, 3) 
									when ''111'' then @resultado else ''E_NV_Longitud'' end 
					else case when substring(@resultado, 3, 3) = ''510'' or substring(@resultado, 3, 3) = ''511'' then @resultado else ''E_NV_Longitud'' end
					end
	when 13 then @resultado
	else ''E_NV_Longitud'' end
end -- arabia saudita

if @pais = 9 --Australia
begin
	select @resultado = case len(@resultado)
	when 8 then 
		/*case when exists (select AreaCode 
						  from SeriesAU 
						  where convert(int,LD) = convert(int,@ld) 
						  and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then*/
			case substring(@resultado, 1, 4) when ''5550'' then ''E_NV_LD'' else @ld +  @resultado end
		/*else case when exists (select AreaCode 
						  from SeriesAU 
						  where convert(int,LD) = convert(int,''04'') 
						  and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then
		''04'' +  @resultado 
		else ''E_NV_Cel'' end end*/
	when 9 then 
		case when left(@resultado,1) <> ''0'' then 
			case substring(@resultado, 2, 4) when ''5550'' then ''E_NV_LD'' else ''0'' + @resultado end
		else ''E_NV_LD'' end
	when 10 then 
		case substring(@resultado, 3, 4) when ''5550'' then ''E_NV_LD'' else @resultado end 
	else ''E_NV_Longitud'' end
end


if @pais = 10 --Brasil
begin
				
	select @resultado = case len(@resultado)
--llamada local fijo o celular	
	when 8 then @resultado 
    when 9 then @resultado 	
	when 10 then  -- Numero nacional
		case when left(@resultado, 2) = @ld 
			then right(@resultado,8) else @resultado end
	when 11 then	-- Este caso solomente es para numero celular
			case when left(@resultado, 2) = @ld
				 then right(@resultado,9) else @resultado end		
	when 12 then	-- llamadas por cobrar local
		case when (left(@resultado,4) = ''9090'') then right(@resultado,8) else ''E_NV_PC'' end
	when 13 then 
		case when left(@resultado,4) = ''9090'' then right(@resultado,9) -- llamadas por cobrar local celular	
			 when left(@resultado,1) = ''0'' then 				
			case when substring(@resultado,4,2)=@ld then right(@resultado,8) else right(@resultado,10) end -- llamadas de LDN
		else ''E_NV_Longitud'' end
	when 14 then
			case when left(@resultado,2) = ''90'' then -- llamadas por cobrar larga distancia
					case when substring(@resultado,5,2) = @ld then right(@resultado,8) else right(@resultado,11) end			     
				 when left(@resultado,1) = ''0''  then --llamada larga distancia a celular					
						case when substring(@resultado,4,2)= @ld then right(@resultado,9) else right(@resultado,11) end				
			else ''E_NV_Longitud'' end
	when 15 then 
		case when left(@resultado,2) = ''90'' then -- Llamadas por cobrar a celular LD
				case when substring(@resultado,5,2)=@ld then right(@resultado,9) else right(@resultado,11) end			
			else ''E_NV_Longitud'' end	

	else ''E_NV_Longitud'' end

end


-- Termina
return @resultado

end'
		
	EXEC(@Sql)
	
		set @process = 'fnGetTimeZone - Create Function'
		set @Sql='CREATE FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN
	declare @lada as varchar(5)
	declare @timeZone as int

	select @lada = valor from ccsettings where setting_id = 17

	declare @country as tinyInt
	select @country = valor from ccSettings where setting_id = 104

		if @country = 1 begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
			where id_country = @country and (
			( len(@phone) = 8 and @lada = area and len(area) = 2 )
			or
			( len(@phone) = 7 and @lada = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 2) = area and len(area) = 2 ))
		end

		if @country = 2 begin
			declare @telTemp varchar(15)
			set @telTemp = @phone
			select @phone = dbo.Completa(@phone)
			if left(@phone,1) = ''E'' begin set @phone = @telTemp end
			select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaArgDetail where
						( len(@phone) = 6 and @lada = area and len(area) = 4 )
						or
						( len(@phone) = 7 and @lada = area and len(area) = 3 )
						or
						( len(@phone) = 8 and @lada = area and len(area) = 2 )
						or
						( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
						or
						( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
						or
						( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
						or
						( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
						or
						( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
						or
						( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 )
						if @timeZone is null
							begin
								select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
								where id_country = @country and (
									( len(@phone) = 6 and @lada = area and len(area) = 4 )
									or
									( len(@phone) = 7 and @lada = area and len(area) = 3 )
									or
									( len(@phone) = 8 and @lada = area and len(area) = 2 )
									or
									( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
									or
									( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
									or
									( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
									or
									( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
									or
									( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
									or
									( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 ))
							end
		end

	if @country = 3 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 7 and @lada = area )
		or
		( len(@phone) = 8 and left(@phone,1) = area )
		or
		( len(@phone) in(10,11) and (left(@phone,1) = ''3'' or substring(@phone,2,1) = ''3'')))
	end

	if @country = 4

		begin
			select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaUsaDetail where
			( len(@phone) = 7 and @lada = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 and left(right(@phone, 7), 3) = prefix)
			if @timeZone is null
				begin
					select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
					where id_country = @country and (
					( len(@phone) = 7 and @lada = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
				end
		end

	if @country = 5 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 6 and @lada = area )
		or
		( len(@phone) = 7 and @lada = area )
		or
		( len(@phone) = 8 and left(@phone,1) = area )
		or
		( len(@phone) = 8 and left(@phone,2) = area )
		or
		( len(@phone) = 9 and left(@phone,2) = area )
		or
		( len(@phone) = 10 and substring(@phone,3,1) = area and left(@phone,2) = ''09'' ))
	end

	if @country = 6 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 7 and @lada = area and len(area) = 3 )
		or
		( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
	end

	if @country = 7 begin
		declare @phoneTemp as varchar(10)
		select @phoneTemp = right ( @phone, 10 )
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
		where id_country = @country and (
		(len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,4) = area ) or
		(len(@phoneTemp) = 9 and left(@phoneTemp,4) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,3) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,2) = area )
		)
	end

	if @country = 8 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
		where id_country = @country and (
		(len(@phone) = 7 and @lada = area) or
		(len(@phone) = 9 and substring(@phone, 2, 1) = area) or
		(len(@phone) = 10 and substring(@phone, 2, 1) = area) or
		(len(@phone) = 11 and substring(@phone, 2, 1) = area))
	end
	
	if @country = 9 begin
		select @phone = dbo.Completa(@phone)
		-- len(@phone) = 10
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
			where id_country = @country and (
			(convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
			(convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
		end
	end
	
	if @country = 10 begin
		select @phone = dbo.Completa(@phone)
		-- 8 <= len(@phone) <= 19
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
			where id_country = @country and (
			((len(@phone) between  8 and  9)                                      and                   @lada = area) or
			((len(@phone) between 10 and 11)                                      and substring(@phone, 1, 2) = area) or
			((len(@phone) between 12 and 13) and substring(@phone, 1, 4) = ''9090'' and                   @lada = area) or
			((len(@phone)       = 13       )                                      and substring(@phone, 4, 2) = area) or
			((len(@phone) between 14 and 15) and substring(@phone, 1, 2) = ''90''   and substring(@phone, 5, 2) = area) or
			((len(@phone)       = 14       ) and substring(@phone, 1, 1) = ''0''    and substring(@phone, 4, 2) = area))
		end
	end

	return isNull(@timeZone,0)
 END'
		
	EXEC(@Sql)
	
/********************************************/
/*** STORED PROCEDURES DE NUEVOS REPORTES ***/
/********************************************/

		set @process = 'GetReportMenus - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[GetReportMenus] @userId int
AS
BEGIN	
	Select distinct Nivel, menu_descrip, menu_id,ordengral, 5 as filtersType
	from ccmenus
	where type = 2 
	and (menu_id >= 2000) 
	order by ordengral asc
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutDialDetail - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepOutDialDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
		--Borrar lo que esta para no repetir
		delete from RepOutDialDetail where date >= @from AND date < @to

		--Inserta información de reporte
		insert into RepOutDialDetail
		SELECT fecha,isnull(isnull(dials.cal_key,cs.cal_key),'''') cal_key, telefono, dials.tiporesdial_id, isnull(descripcion,'''') as resultado,
		dials.[cam_id],ISNULL(rtrim(ltrim(camps.cam_descripcion)), ''Sin campaña'') as campa, dials.tbusy as Msgtime, datepart(yyyy,fecha),
		datepart(mm,fecha), datepart(dd,fecha), datepart(hh,fecha), datepart(mi,fecha)
		FROM
			(select dial.*, co.cal_key 
			FROM ccoLogDials dial
			left join ccocallsout co on (dial.callout_id = co.callout_id and dial.Telefono=co.cal_telefono and 
			tiporesdial_id = 1 and convert(datetime,convert(varchar(19),co.cal_inicio,121),121) >= 
			convert(datetime,convert(varchar(19),dateadd(mi,-1,dial.fecha),121),121) and 
			convert(datetime,convert(varchar(19),co.cal_inicio,121),121) <= convert(datetime,convert(varchar(19),dateadd(mi,1,dial.fecha),121),121))
			WHERE fecha >= @from AND fecha < @to) dials     
		LEFT JOIN ccoCallsOutSource cs ON dials.callout_id = cs.callout_id LEFT JOIN cctipoResultadoDial tr
		ON dials.tiporesdial_id=tr.tiporesdial_id LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]    
		WHERE fecha >= @from AND fecha < @to
		order by fecha
	end'
		
	EXEC(@Sql)
	
		set @process = 'GetReportFilters - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[GetReportFilters] @id nvarchar(100), @action tinyint = 0 -- 0 Filter select; 1 Filters Range 
AS
BEGIN
	if @action = 0 begin
		SELECT Filters.[type],Filters.xmlParentNode,Filters.xmlChildNode
		FROM Filters, ReportsFilters 
		WHERE Filters.name = ReportsFilters.filterName 
		AND ReportsFilters.id = @id
	end
	if @action = 1 begin
		SELECT Filters.[type], Filters.xmlParentNode, Filters.xmlChildNode
		FROM Filters, ReportsFiltersRange 
		WHERE Filters.name = ReportsFiltersRange.filterName 
		AND ReportsFiltersRange.id = @id
	end
END'
							
	EXEC(@Sql)
	
		set @process = 'GetDefaultChart - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[GetDefaultChart] @id int 
AS
BEGIN
	select reportName, chartType, case chartType when 1 then x1 ELSE x1 + ''|'' + subX1 end as columns, countColumn, chartDescription
	from ReportsCharts
	WHERE id = @id
	order by id
END'
		
	EXEC(@Sql)
	
		set @process = 'SaveReportTemplates - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[SaveReportTemplates] @userId int, @process int, @parameters varchar(max)
AS
BEGIN
	DECLARE @reportName varchar(255)
	DECLARE @id int
	DECLARE @max int
	DECLARE @idReport int

	select @max = 10

	if exists(select *
			  from ccTemplates
		      where user_Id = @userId)
		begin
			select @id = max(id) + 1
			from ccTemplates
		    where user_Id = @userId
		end
	else
		begin
			select @id = 1
		end

	select @reportName = menu_descrip
	from ccMenus
	where menu_id = @process
	
	if not exists (select * from ccTemplates where user_Id = @userId and reportName = @reportName)
		begin
			if (@id <= @max)
				begin
					update ccTemplates
					set id = id + 1
					where user_Id = @userId

					insert into ccTemplates
					values (1, @userId, replace(@parameters,'','',''|''), @reportName, getdate())
				end
			else
				begin
					delete ccTemplates
					where user_Id = @userId
					and id = @max

					update ccTemplates
					set id = id + 1
					where user_Id = @userId

					insert into ccTemplates
					values (1, @userId, replace(@parameters,'','',''|''), @reportName, getdate())
				end
		end
	else
		begin
			select @idReport = id
			from cctemplates
			where user_Id = @userId
			and reportName = @reportName

			update cctemplates
			set id = id + 1
			where id < @idReport

			update cctemplates
			set id = 1, parameters = replace(@parameters,'','',''|''), date = GETDATE()
			where user_Id = @userId
			and reportName = @reportName
		end

	select 0
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCalls - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepOutCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint
SELECT @HourExtend=2
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint

if @action = 1
begin

	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog

	--Borrar lo que esta para no repetir
	delete from RepOutCalls where date >= @from AND date < @to

	insert into RepOutCalls
	select finalReport.tg, 0 as [areaId], '''' as [area], idwg, '''' as [workgroup],
	cam_id, '''' as campaign, [user_id], '''' as [user]
	, ISNULL(ntotal, 0) ntotal
	, ISNULL(nxfer, 0) nxfer
	, ISNULL(nno_agent, 0) nno_agent
	, ISNULL(nanswer, 0) nanswer
	, ISNULL(nno_answer, 0) nno_answer
	, ISNULL(nlost, 0) nlost
	, ISNULL(nabnd_xfer, 0) nabnd_xfer
	, ISNULL(nabnd_ring, 0) nabnd_ring
	, ISNULL(nabnd_dialog, 0) nabnd_dialog
	, ISNULL(pos_tot, 0) pos_tot
	, ISNULL(pos_time, 0) pos_time
	, ISNULL(nhangup, 0) nhangup
	, ISNULL(tatencion, 0) tatencion
	, datepart(yyyy,finalReport.tg)
	, datepart(mm,finalReport.tg)
	, datepart(dd,finalReport.tg)
	, datepart(hh,finalReport.tg)
	, datepart(mi,finalReport.tg)
	FROM(
		SELECT tg, cam_id,[user_id],idwg
		, SUM(ntotal) ntotal
		, SUM(nxfer) nxfer
		, SUM(nno_agent) nno_agent
		, SUM(nanswer) nanswer
		, SUM(nno_answer) nno_answer
		, SUM(nlost) nlost
		, SUM(nabnd_xfer) nabnd_xfer
		, SUM(nabnd_ring) nabnd_ring
		, SUM(nabnd_dialog) nabnd_dialog
		, SUM(nhangup) nhangup
		, SUM(tdialog + tnotes) tatencion
		FROM(
			SELECT timegroup as tg,cam_id,[user_id],ntotal,idwg
			,nno_agent,nxfer
			,nabnd_xfer,nabnd_ring,nno_answer
			,nabnd_dialog,nanswer,nlost
			,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
			FROM(
				SELECT xDetailTime.timegroup,xDetailTime.cam_id,xDetailTime.[user_id],xDetailTime.idwg
				,ISNULL(ntotal,0)AS ntotal
				,ISNULL(no_agent,0)AS nno_agent
				,ISNULL(xfer,0)AS nxfer
				,ISNULL(abnd_xfer,0)AS nabnd_xfer
				,ISNULL(abnd_ring,0)AS nabnd_ring
				,ISNULL(no_answer,0)AS nno_answer
				,ISNULL(abnd_dialog,0)AS nabnd_dialog
				,ISNULL(answer,0)AS nanswer
				,ISNULL(lost,0)AS nlost
				,xDetailTime.txfer
				,xDetailTime.tring
				,xDetailTime.tdialog
				,xDetailTime.tnotes
				,ISNULL(tresp,0)AS tresp
				,ISNULL(hung_up,0)AS nhangup
				,ISNULL(nMoh,0) as nMoh
				,isnull(nWHag,0)as nWHag
				,isnull(nWHcl,0)as nWHcl
				FROM(
					SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,cam_id
					,ccoCallsOut.[user_id]
					,idwg
					,COUNT(ccoCallsOut.cal_id)AS ntotal
					,COUNT(CASE WHEN(statuscall_id=6)THEN ccoCallsOut.cal_id ELSE NULL END)AS hung_up --Ne se usa,asi que es igual a total para las llamadas sin agente asignada(->agente 0)
					,COUNT(CASE WHEN(statuscall_id=4)THEN ccoCallsOut.cal_id ELSE NULL END)AS no_agent
					,COUNT(CASE WHEN(statuscall_id>=10)THEN ccoCallsOut.cal_id ELSE NULL END)AS xfer
					,COUNT(CASE WHEN(statuscall_id=11)THEN ccoCallsOut.cal_id ELSE NULL END)AS abnd_xfer
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN ccoCallsOut.cal_id ELSE NULL END)AS abnd_ring
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN ccoCallsOut.cal_id ELSE NULL END)AS no_answer
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN ccoCallsOut.cal_id ELSE NULL END)AS abnd_dialog
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN ccoCallsOut.cal_id ELSE NULL END)AS answer
					,COUNT(CASE WHEN(statuscall_id=16)THEN ccoCallsOut.cal_id ELSE NULL END)AS lost
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
					,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
					FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
					LEFT JOIN ccriaworkgroup_calid
					ON ccoCallsOut.cal_id = ccriaworkgroup_calid.cal_id
					WHERE cal_inicio >= @fromExtended AND cal_inicio < @to
					-- para contar bien las llamadas manuales
					and cal_manual in(0,2)
					GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),cam_id,ccoCallsOut.[user_id],idwg
				)xDetailCount

				LEFT JOIN (

				SELECT timegroup
				,cam_id
				,[user_id]
				,idwg
				,ISNULL(SUM(cal_txfer),0)AS txfer
				,ISNULL(SUM(cal_tring),0)AS tring
				,ISNULL(SUM(cal_tdialog),0)AS tdialog
				,ISNULL(SUM(cal_tnotas),0)AS tnotes
				FROM(
					SELECT timegroup,cam_id,[user_id],idwg
					,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
					,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
					,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
					,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
					FROM(
						SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
						,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
						,0 time_endque
						,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
						,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
						,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
						,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
						,idwg
						,ccoCallsOut.*
						FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
						LEFT JOIN ccriaworkgroup_calid
						ON ccoCallsOut.cal_id = ccriaworkgroup_calid.cal_id
						WHERE cal_inicio >= @fromExtended AND cal_inicio < @to
						-- para contar bien las llamadas manuales
						and cal_manual in(0,2)
					)xDetail
					
					UNION
					
					SELECT timegroup_next,cam_id,[user_id],idwg
					,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
					,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
					,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
					,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
					FROM(
						SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
						,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
						,0 AS time_endque
						,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
						,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
						,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
						,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
						,idwg
						,ccoCallsOut.*
						FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
						LEFT JOIN ccriaworkgroup_calid
						ON ccoCallsOut.cal_id = ccriaworkgroup_calid.cal_id
						WHERE cal_inicio >= @fromExtended AND cal_inicio < @to
						-- para contar bien las llamadas manuales
						and cal_manual in(0,2)
					)xDetail
				)xTimeDetail
				GROUP BY timegroup,cam_id,[user_id],idwg
			)xDetailTime
			ON(
				xDetailTime.timegroup=xDetailCount.timegroup AND
				xDetailTime.cam_id=xDetailCount.cam_id AND
				xDetailTime.[user_id]=xDetailCount.[user_id] AND
				xDetailTime.idwg=xDetailCount.idwg
			)
		)xComplete
		WHERE timegroup >= @from AND timegroup < @to
		AND NOT(ntotal=0 AND nno_agent=0
		AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
		)reportDetail
	WHERE tg >= @from AND tg < @to
	group by tg, cam_id,[user_id],idwg
	) finalReport

	LEFT OUTER JOIN (

		SELECT timegroup as tg, AVG(pos_tot) pos_tot, avg(pos_time) pos_time
		FROM ccGenOutCamp
		WHERE timegroup >= @from AND timegroup < @to
		group by timegroup
		) xDetSpec
	ON (finalReport.tg = xDetSpec.tg)

	ORDER BY finalReport.tg,cam_id,[user_id]

	delete repoutcalls
	where userId = 0
	and [date] >= @from and [date] < @to

	update repoutcalls
	set areaId = idArea
	from repoutcalls 
	left outer join ccriaareaworkgroup on (workgroupid = idwg)
	where idarea is not null
	and [date] >= @from and [date] < @to

	delete repoutcalls
	where areaId = 0
	and [date] >= @from and [date] < @to

	update repoutcalls set
	area = (select areaname from ccriacat_areas where idarea = areaid),
	workgroup = (select wgname from ccriacat_workgroup where idwg = workgroupid),
	campaign = (select cam_descripcion from cccamps where cam_id = campaignid),
	[user] = (select login from ccusers where user_id = userid)
	where [date] >= @from and [date] < @to
end'
		
	EXEC(@Sql)
	
		set @process = 'SaveUserTemplate - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[SaveUserTemplate] @userId int, @reportName nvarchar(50), @parameters nvarchar(MAX)
AS
BEGIN
	DECLARE @id int  

	if exists (select * from FavoriteTemplates where userid = @userId)
		begin
			select @id = max(id) + 1 
			from FavoriteTemplates 
			where userid = @userId
		end
	else
		begin
			select @id = 1
		end
	
    INSERT INTO dbo.FavoriteTemplates
    VALUES(@id,@userId,replace(@parameters,'','',''|''),@reportName,getdate()) 
    
END'
		
	EXEC(@Sql)
	
		set @process = 'GetUserTemplates - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[GetUserTemplates] @userId int 	
AS
BEGIN   
	SELECT id,parameters,reportName,date
	FROM dbo.FavoriteTemplates 
	WHERE userId = @userId 
	order by date desc
END'
		
	EXEC(@Sql)
	
		set @process = 'GetReportFiltersMenus - Create Procedure'
		set @Sql='CREATE PROCEDURE GetReportFiltersMenus	
	@id int	
AS
BEGIN   
	SELECT id,name 
	FROM dbo.FiltersMenus as f, dbo.ReportsFiltersMenus fm
	WHERE f.name = fm.filterMenuName
	AND fm.idReport = @id
END'
		
	EXEC(@Sql)
	
		set @process = 'DeleteUserTemplate - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[DeleteUserTemplate] @reportName nvarchar(50), @userId int
AS
BEGIN
	DECLARE @id int

	select @id = id 
	from FavoriteTemplates
	WHERE userId = @userId 
	AND reportName = @reportName

	DELETE FROM dbo.FavoriteTemplates
	WHERE userId = @userId 
	AND reportName = @reportName

	update FavoriteTemplates
	set id = id - 1
	where userId = @userId
	and id > @id
END'
		
	EXEC(@Sql)
	
		set @process = 'UpdateUserTemplate - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[UpdateUserTemplate] @userId int, @reportName nvarchar(50), @newReportName nvarchar(50), @parameters nvarchar(MAX)
AS
BEGIN
    UPDATE dbo.FavoriteTemplates
    SET reportName = @newReportName,
    parameters = replace(@parameters,'','',''|''),
    date = getdate()
    WHERE userId = @userId 
    AND reportName = @reportName
END'
		
	EXEC(@Sql)
	
		set @process = 'GetReportTemplates - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[GetReportTemplates] @userId int 
AS
BEGIN
	select id, parameters, reportName, CONVERT(VARCHAR(8),date,108) AS date
	from ccTemplates
	where user_id = @userId
	order by date desc
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAgentGI - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepAgentGI] 
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS off
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
	delete from RepAgentGI where date >= @from AND date < @to

	-- Session Time
	select [user_id], [login], logout, extension
	into #sessionTime
	from(select a.extension, a.user_id, a.fecha as ''login'',
	(select isnull(max(Fecha),getdate())
	 from ccLogLogin b with(nolock)
	 where b.user_id = a.user_id and
	 b.tipomov = 0 and
	 b.fecha >= a.fecha and
	 b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
		from ccLogLogin with(nolock)
		where user_id = b.user_id and
		tipomov = 1 and
		fecha > a.fecha)) as ''logout''
	from ccLogLogin a
	where a.tipomov=1
	and fecha >= @from
	and fecha <= @to) as sessiontime
	order by user_id, login

	-- Inbound Data
	SELECT timegroup,inbound_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
	,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
	,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
	into #inboundData
	FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
		,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
		,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
		,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
		,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
		,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
		,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
		,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
	FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,[user_id]
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
	FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
	WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
	GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,[user_id])xDetailCount
	right JOIN(SELECT timegroup,inbound_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
	FROM(SELECT timegroup,inbound_id,[user_id]
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
	FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
	WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
	UNION
	SELECT timegroup_next,inbound_id,[user_id]
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
		,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
	GROUP BY timegroup,inbound_id,[user_id])xDetailTime
	ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
	ORDER BY timegroup,inbound_id,[user_id]

	--Outbound Data
	SELECT timegroup,cam_id,[user_id],ntotal
	,nno_agent,nxfer
	,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost
	,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
	into #outboundData
	FROM(		
		SELECT xDetailTime.timegroup,xDetailTime.cam_id,xDetailTime.[user_id]
			,ISNULL(ntotal,0)AS ntotal
			,ISNULL(no_agent,0)AS nno_agent,ISNULL(xfer,0)AS nxfer
			,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost
			,xDetailTime.txfer,xDetailTime.tring
			,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp
			,ISNULL(hung_up,0)AS nhangup,ISNULL(nMoh,0) as nMoh,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM(	 
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,cam_id
					,[user_id]
					,COUNT(cal_id)AS ntotal
					,COUNT(CASE WHEN(statuscall_id=6)THEN cal_id ELSE NULL END)AS hung_up --Ne se usa,as que es igual a total para las llamadas sin agente asignada(->agente 0)
					,COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END)AS no_agent
					,COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END)AS xfer
					--,COUNT(CASE WHEN(statuscall_id in(11,15,13,16))THEN 1 ELSE NULL END)AS xfer
					,COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END)AS no_answer
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END)AS answer
					,COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END)AS lost
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
					,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
					-- para contar bien las llamadas manuales
					and cal_manual in(0,2)
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),cam_id,[user_id]
			)xDetailCount
			--RIGHT OUTER JOIN 
			LEFT JOIN
			(
				SELECT timegroup
					,cam_id
					,[user_id]
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(cal_tring),0)AS tring
					,ISNULL(SUM(cal_tdialog),0)AS tdialog
					,ISNULL(SUM(cal_tnotas),0)AS tnotes
				 FROM(	SELECT timegroup,cam_id,[user_id]
						,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					UNION
					SELECT timegroup_next,cam_id,[user_id]
						,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 AS time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					)xTimeDetail
				 GROUP BY timegroup,cam_id,[user_id]
			)xDetailTime
			ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.cam_id=xDetailCount.cam_id AND xDetailTime.[user_id]=xDetailCount.[user_id])
	)xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nno_agent=0
		 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		 AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
	ORDER BY timegroup,cam_id,[user_id]

		-- Agent Information
	SELECT timegroup,[user_id],tlog, 0 as treq, tnot_av
	--,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
	--,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
	--,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
	--,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
	,tav
	,tprob
	,tunknown
	,tother
	,nother,nMoh,nWHag,nWHcl
	into #agentInformation
 FROM(
		SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
			,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
		 FROM(
			SELECT 
				xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
				,ISNULL(SUM(#inboundData.txfer),0)+ ISNULL(SUM(#outboundData.txfer),0)as txfer
				,ISNULL(SUM(#inboundData.tdialog),0)+ ISNULL(SUM(#outboundData.tdialog),0)as tdialog
				,ISNULL(SUM(#inboundData.tnotes),0)+ ISNULL(SUM(#outboundData.tnotes),0)as tnotes
				,ISNULL(SUM(#inboundData.tring),0)+ ISNULL(SUM(#outboundData.tring),0)as tring
				,ISNULL(SUM(#inboundData.nMoh),0)+ ISNULL(SUM(#outboundData.nMoh),0)as nMoh
				,ISNULL(SUM(#inboundData.nWHag),0)+ ISNULL(SUM(#outboundData.nWHag),0)as nWHag
				,ISNULL(SUM(#inboundData.nWHcl),0)+ ISNULL(SUM(#outboundData.nWHcl),0)as nWHcl
		
				,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t1
				,ISNULL((SELECT top 1 3600
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t2
				,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t3
				,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t4
			
			 FROM(
					SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
						,ccLogAgentesDia.[user_id]
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
						,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
					 FROM ccLogAgentesDia
					 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
					 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
				)xTimeDetail
					LEFT OUTER JOIN #inboundData ON(xTimeDetail.timegroup=#inboundData.timegroup AND xTimeDetail.[user_id]=#inboundData.[user_id])
					LEFT OUTER JOIN #outboundData ON(xTimeDetail.timegroup=#outboundData.timegroup AND xTimeDetail.[user_id]=#outboundData.[user_id])
				GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		 	)xDetail
	)xAllTimes
 WHERE tlog>0
 ORDER BY timegroup,[user_id]

SELECT CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121) AS timegroup
		, [user_id],SUM(tStatus) as [timeNotReady]
	 into #notReady
		 FROM ccLogAgentesNotReady
		 WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
		 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121), [user_id]

INSERT INTO RepAgentGI
	SELECT     
	CASE WHEN #agentInformation.timegroup IS NOT NULL THEN #agentInformation.timegroup WHEN #inboundData.timegroup IS NOT NULL 
	  THEN #inboundData.timegroup WHEN #outboundData.timegroup IS NOT NULL THEN #outboundData.timegroup ELSE 0 END AS date, 
	  CASE WHEN #agentInformation.user_id IS NOT NULL THEN #agentInformation.user_id WHEN #inboundData.user_id IS NOT NULL 
	  THEN #inboundData.user_id WHEN #outboundData.user_id IS NOT NULL THEN #outboundData.user_id ELSE - 1 END AS user_id,
	  u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + nombres as [user] , u.login as [login],
	  ISNULL(dbo.#inboundData.nxfer, 0) AS nxfer_in, ISNULL(dbo.#inboundData.nanswer, 0) AS nanswer_in, ISNULL(dbo.#inboundData.nabnd_xfer, 0) 
	  AS nabnd_xfer_in, ISNULL(dbo.#inboundData.nabnd_ring, 0) AS nabnd_ring_in, ISNULL(dbo.#inboundData.nabnd_dialog, 0) AS nabnd_dlg_in, 
	  ISNULL(dbo.#inboundData.nabnd_xfer, 0) + ISNULL(dbo.#inboundData.nabnd_ring, 0) + ISNULL(dbo.#inboundData.nabnd_dialog, 0) AS abnd_a_xfer_in, 
	  ISNULL(dbo.#inboundData.nno_answer, 0) AS nno_answer_in, ISNULL(dbo.#inboundData.nlost, 0) AS nlost_in, ISNULL(dbo.#inboundData.tdialog, 0) 
	  AS tdialog_in, ISNULL(dbo.#inboundData.tnotes, 0) AS tnotes_in, ISNULL(dbo.#inboundData.tring, 0) AS tring_in, ISNULL(dbo.#inboundData.txfer, 0) AS txfer_in, 
	  ISNULL(dbo.#outboundData.nxfer, 0) AS nxfer_out, ISNULL(dbo.#outboundData.nanswer, 0) AS nanswer_out, ISNULL(dbo.#outboundData.nabnd_xfer, 0) 
	  AS nabnd_xfer_out, ISNULL(dbo.#outboundData.nabnd_ring, 0) AS nabnd_ring_out, ISNULL(dbo.#outboundData.nabnd_dialog, 0) AS nabnd_dlg_out, 
	  ISNULL(dbo.#outboundData.nabnd_xfer, 0) + ISNULL(dbo.#outboundData.nabnd_ring, 0) + ISNULL(dbo.#outboundData.nabnd_dialog, 0) AS abnd_a_xfer_out, 
	  ISNULL(dbo.#outboundData.nno_answer, 0) AS nno_answer_out, ISNULL(dbo.#outboundData.nlost, 0) AS nlost_out, ISNULL(dbo.#outboundData.tdialog, 0) 
	  AS tdialog_out, ISNULL(dbo.#outboundData.tnotes, 0) AS tnotes_out, ISNULL(dbo.#outboundData.tring, 0) AS tring_out, ISNULL(dbo.#outboundData.txfer, 0) 
	  AS txfer_out, ISNULL(dbo.#agentInformation.nother, 0) AS nother, ISNULL(dbo.#agentInformation.tunknown, 0) AS tunknown, ISNULL(dbo.#agentInformation.tnot_av, 0) AS tnot_av, 
	  ISNULL(dbo.#agentInformation.tlog, 0) AS tlog
	  ,ISNULL(dbo.#notReady.timeNotReady, 0) AS treq --  ,0 as treq	
	, ISNULL(dbo.#agentInformation.tav, 0) AS tav, ISNULL(dbo.#agentInformation.tother, 0) AS tother, 
	  ISNULL(dbo.#agentInformation.tprob, 0) AS tprob, ISNULL(dbo.#inboundData.nMoh, 0) AS nMoh_in, ISNULL(dbo.#outboundData.nMoh, 0) AS nMoh_out, 
	  ISNULL(dbo.#inboundData.nWHag, 0) AS nWHag_in, ISNULL(dbo.#outboundData.nWHag, 0) AS nWHag_out, ISNULL(dbo.#inboundData.nWHcl, 0) 
	  AS nWHcl_in, ISNULL(dbo.#outboundData.nWHcl, 0) AS nWHcl_out
	  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(yy,#agentInformation.timegroup) WHEN #inboundData.timegroup IS NOT NULL 
	  THEN datepart(yy,#inboundData.timegroup) WHEN #outboundData.timegroup IS NOT NULL THEN datepart(yy,#outboundData.timegroup) ELSE 0 END AS [year]
	  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(mm,#agentInformation.timegroup) WHEN #inboundData.timegroup IS NOT NULL 
	  THEN datepart(mm,#inboundData.timegroup) WHEN #outboundData.timegroup IS NOT NULL THEN datepart(mm,#outboundData.timegroup) ELSE 0 END AS [month]
	  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(dd,#agentInformation.timegroup) WHEN #inboundData.timegroup IS NOT NULL 
	  THEN datepart(dd,#inboundData.timegroup) WHEN #outboundData.timegroup IS NOT NULL THEN datepart(dd,#outboundData.timegroup) ELSE 0 END AS [day]
	  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(hh,#agentInformation.timegroup) WHEN #inboundData.timegroup IS NOT NULL 
	  THEN datepart(hh,#inboundData.timegroup) WHEN #outboundData.timegroup IS NOT NULL THEN datepart(hh,#outboundData.timegroup) ELSE 0 END AS [hour]
	  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(mi,#agentInformation.timegroup) WHEN #inboundData.timegroup IS NOT NULL 
	  THEN datepart(mi,#inboundData.timegroup) WHEN #outboundData.timegroup IS NOT NULL THEN datepart(mi,#outboundData.timegroup) ELSE 0 END AS [minutes]
FROM  dbo.#agentInformation FULL OUTER JOIN
      dbo.#inboundData ON dbo.#inboundData.timegroup = dbo.#agentInformation.timegroup AND dbo.#inboundData.user_id = dbo.#agentInformation.user_id 
	  FULL OUTER JOIN
      dbo.#outboundData ON dbo.#outboundData.timegroup = dbo.#agentInformation.timegroup AND dbo.#outboundData.user_id = dbo.#agentInformation.user_id 
	  LEFT OUTER JOIN
	  dbo.ccusers u ON (#agentInformation.[user_id] = u.[user_id])
	  LEFT OUTER JOIN dbo.#notReady ON #agentInformation.[user_id] = dbo.#notReady.[user_id] AND dbo.#notReady.timegroup = dbo.#agentInformation.timegroup 
WHERE #agentInformation.[user_id] IS NOT NULL


drop table #sessionTime
drop table #inboundData
drop table #outboundData
drop table #agentInformation
drop table #notReady

end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAgentKPI - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepAgentKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete RepAgentKPI where date >= @from AND date < @to

	create table #ccCalls_Temp(
	cal_id int, 
	User_id smallint, 
	statusCall_id tinyint, 
	cal_tDialog smallint, 
	cal_Inicio datetime, 
	cal_whoHung smallint, 
	tipoTabla tinyint)

	CREATE NONCLUSTERED INDEX IX_ccCalls_Temp ON #ccCalls_Temp (cal_id ASC)

	insert into #ccCalls_Temp 
	select cal_id, User_id, statusCall_id, cal_tDialog, convert(varchar(8), cal_Inicio, 112)+'' 00:00'', cal_whoHung, 0 
	from ccoCallsOut
	where cal_inicio between @from and @to

	insert into #ccCalls_Temp 
	select cal_id, User_id, statusCall_id, cal_tDialog, convert(varchar(8), cal_Inicio, 112)+'' 00:00'', cal_whoHung, 1 
	from ccCallsIn
	where cal_inicio between @from and @to 

	insert into RepAgentKPI
	select convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121)) date, Fst.Login as login, Fst.user_id as [userId],
	Nombres + isnull('' ''+ApellidoPaterno, '''') + isnull('' ''+ApellidoMaterno, '''') as [user], Total as totalCalls, Cin as callsIn, 
	Cout as callsOut, C10 as [finishedCalls10], C20 as [finishedCalls20], C30 as [finishedCalls30], cal_whoHung as whoHung, 
	isnull(avg_fCalc, 0) as callsAvgTime,
	datepart(yyyy,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(mm,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(dd,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(hh,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(mi,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121)))
	from 
	(
	select User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno 
	from ccUsers
	) as Fst
	join
	(
	select user_id, cal_Inicio, sum(Total) Total, sum(Cin) Cin, sum(Cout) Cout, sum(C10) C10, sum(C20) C20, sum(C30) C30, sum(cal_whoHung) cal_whoHung
	from (select user_id, cal_Inicio, 1 Total, tipoTabla Cin, case tipoTabla when 0 then 1 else 0 end Cout,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<10 then 1 else 0 end C10,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<20 then 1 else 0 end C20,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<30 then 1 else 0 end C30,
		cal_whoHung from #ccCalls_Temp
	) as Conteos group by user_id, cal_Inicio
	) as Snd
	on Fst.User_id = Snd.User_id
	left join 
	(
	select User_id, cast((AVG(convert(bigint,fecha_Calc_ms)))/1000.0 as decimal(10,0)) avg_fCalc 
	from ccLogAgentesDia_Dialog where fecha_Dialog between @from and @to 
	group by User_id
	) as Trd
	on Snd.User_id = Trd.User_id

	drop table #ccCalls_Temp
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAgentNotReady - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepAgentNotReady]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS OFF

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
	delete from RepAgentNotReady where date >= @from AND date < @to
	
	-- Session Time
	select [user_id], [login], logout, extension
	into #sessionTime
	from(select a.extension, a.user_id, a.fecha as ''login'',
	(select isnull(max(Fecha),getdate())
	 from ccLogLogin b with(nolock)
	 where b.user_id = a.user_id and
	 b.tipomov = 0 and
	 b.fecha >= a.fecha and
	 b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
		from ccLogLogin with(nolock)
		where user_id = b.user_id and
		tipomov = 1 and
		fecha > a.fecha)) as ''logout''
	from ccLogLogin a
	where a.tipomov=1
	and fecha >= @from
	and fecha <= @to) as sessiontime
	order by user_id, login

		-- Inbound Data
	SELECT timegroup,inbound_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
	,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
	,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
	into #inboundData
	FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
		,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
		,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
		,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
		,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
		,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
		,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
		,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
	FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,[user_id]
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
	FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
	WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
	GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,[user_id])xDetailCount
	right JOIN(SELECT timegroup,inbound_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
	FROM(SELECT timegroup,inbound_id,[user_id]
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
	FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
	WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
	UNION
	SELECT timegroup_next,inbound_id,[user_id]
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
		,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
	GROUP BY timegroup,inbound_id,[user_id])xDetailTime
	ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
	ORDER BY timegroup,inbound_id,[user_id]

	--Outbound Data
	SELECT timegroup,cam_id,[user_id],ntotal
	,nno_agent,nxfer
	,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost
	,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
	into #outboundData
	FROM(		
		SELECT xDetailTime.timegroup,xDetailTime.cam_id,xDetailTime.[user_id]
			,ISNULL(ntotal,0)AS ntotal
			,ISNULL(no_agent,0)AS nno_agent,ISNULL(xfer,0)AS nxfer
			,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost
			,xDetailTime.txfer,xDetailTime.tring
			,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp
			,ISNULL(hung_up,0)AS nhangup,ISNULL(nMoh,0) as nMoh,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM(	 
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,cam_id
					,[user_id]
					,COUNT(cal_id)AS ntotal
					,COUNT(CASE WHEN(statuscall_id=6)THEN cal_id ELSE NULL END)AS hung_up --Ne se usa,as que es igual a total para las llamadas sin agente asignada(->agente 0)
					,COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END)AS no_agent
					,COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END)AS xfer
					--,COUNT(CASE WHEN(statuscall_id in(11,15,13,16))THEN 1 ELSE NULL END)AS xfer
					,COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END)AS no_answer
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END)AS answer
					,COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END)AS lost
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
					,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
					-- para contar bien las llamadas manuales
					and cal_manual in(0,2)
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),cam_id,[user_id]
			)xDetailCount
			--RIGHT OUTER JOIN 
			LEFT JOIN
			(
				SELECT timegroup
					,cam_id
					,[user_id]
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(cal_tring),0)AS tring
					,ISNULL(SUM(cal_tdialog),0)AS tdialog
					,ISNULL(SUM(cal_tnotas),0)AS tnotes
				 FROM(	SELECT timegroup,cam_id,[user_id]
						,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					UNION
					SELECT timegroup_next,cam_id,[user_id]
						,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 AS time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					)xTimeDetail
				 GROUP BY timegroup,cam_id,[user_id]
			)xDetailTime
			ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.cam_id=xDetailCount.cam_id AND xDetailTime.[user_id]=xDetailCount.[user_id])
	)xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nno_agent=0
		 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		 AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
	ORDER BY timegroup,cam_id,[user_id]

	-- Agent Information
	SELECT timegroup,[user_id],tlog, 0 as treq, tnot_av
	,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
	,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
	,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
	,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
	,nother,nMoh,nWHag,nWHcl
	into #agentInformation
 FROM(
		SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
			,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
		 FROM(
			SELECT 
				xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
				,ISNULL(SUM(#inboundData.txfer),0)+ ISNULL(SUM(#outboundData.txfer),0)as txfer
				,ISNULL(SUM(#inboundData.tdialog),0)+ ISNULL(SUM(#outboundData.tdialog),0)as tdialog
				,ISNULL(SUM(#inboundData.tnotes),0)+ ISNULL(SUM(#outboundData.tnotes),0)as tnotes
				,ISNULL(SUM(#inboundData.tring),0)+ ISNULL(SUM(#outboundData.tring),0)as tring
				,ISNULL(SUM(#inboundData.nMoh),0)+ ISNULL(SUM(#outboundData.nMoh),0)as nMoh
				,ISNULL(SUM(#inboundData.nWHag),0)+ ISNULL(SUM(#outboundData.nWHag),0)as nWHag
				,ISNULL(SUM(#inboundData.nWHcl),0)+ ISNULL(SUM(#outboundData.nWHcl),0)as nWHcl
		
				,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t1
				,ISNULL((SELECT top 1 3600
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t2
				,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t3
				,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t4
			
			 FROM(
					SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
						,ccLogAgentesDia.[user_id]
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
						,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
					 FROM ccLogAgentesDia
					 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
					 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
				)xTimeDetail
					LEFT OUTER JOIN #inboundData ON(xTimeDetail.timegroup=#inboundData.timegroup AND xTimeDetail.[user_id]=#inboundData.[user_id])
					LEFT OUTER JOIN #outboundData ON(xTimeDetail.timegroup=#outboundData.timegroup AND xTimeDetail.[user_id]=#outboundData.[user_id])
				GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		 	)xDetail
	)xAllTimes
 WHERE tlog>0
 ORDER BY timegroup,[user_id]

	SELECT CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121) AS timegroup
		, [user_id], tiponotready_id
		, COUNT(tStatus) as [count], SUM(tStatus) as [time]
		--, sum( case when separado in (0,3) then 1 else null end ) as amountReal --amount Real
	 into #notReady
	 FROM ccLogAgentesNotReady
	 WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
	 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121), [user_id], tiponotready_id

	insert into RepAgentNotReady
	select a.timegroup as date, c.login, a.user_id as [userId], c.apellidopaterno + '' '' + c.apellidomaterno + '' '' + c.nombres as [user],
	a.tlog as sessionTime, d.tiponotready_id, d.descripcion,
	d.descripcion + ''_Count'' as descripcion_count, [count], d.descripcion + ''_Time'' as descripcion_time,
	[time],
	[time] as timeSeconds--, amountReal
	, datepart(yyyy,a.timegroup), datepart(mm,a.timegroup), datepart(dd,a.timegroup), datepart(hh,a.timegroup), datepart(mi,a.timegroup)
	from #agentInformation a, #notReady b, ccusers c, ccTipoNotReady d
	where a.timegroup = b.timegroup
	and a.user_id = b.user_id
	and b.user_id = c.user_id
	and b.tiponotready_id = d.tiponotready_id

	drop table #sessionTime
	drop table #inboundData
	drop table #outboundData
	drop table #agentInformation
	drop table #notReady

end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAgentNotReadyDet - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepAgentNotReadyDet]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()


if @action = 1
begin
	delete from RepAgentNotReadyDet where date >= @from AND date < @to
	
	INSERT INTO RepAgentNotReadyDet
	SELECT convert(datetime,convert(varchar(11),fechaInicio)) as [date], isNull(usr.Login,''No agent'') as login, usr.user_id as userId, 
	isNull(usr.ApellidoPaterno,'''') + '' '' + isNull(usr.ApellidoMaterno, '''') + '' '' + IsNull(usr.Nombres, ''No name'') as [user],
	isnull(tn.tiponotready_id,0) as tiponotreadyId,  
	isNull(tn.Descripcion, ''No status'')as [status], 
	fechaInicio as startDate, 
	case when fechaFin is null then fecha when separado = 0 then fecha when separado = 3  or separado = 1 then fechaFin end as endDate,
	case when fechafin is null then
			tStatus
		 when separado = 0 then 
			tStatus
		 when separado = 3  or separado = 1 then
			datediff( s, fechaInicio, fechaFin) end as statusTime,
	case when fechafin is null then tStatus when separado = 0 then tStatus when separado = 3  or separado = 1 then datediff( s, fechaInicio, fechaFin) end as statusTimeSeconds,
	datepart(yyyy,fechaInicio), datepart(mm,fechaInicio), datepart(dd,fechaInicio), datepart(hh,fechaInicio), datepart(mi,fechaInicio)
	From (select distinct user_id, 
		tiponotready_id, 
		DATEADD(s, -tstatus, fecha) AS fechaInicio, 
		separado, 
		tStatus, 
		fecha, 
		( select min( sub.fecha) 
			from ccLogAgentesNotReady sub 
			where sub.separado = 1 
			and sub.fecha = nr.fecha 
			and nr.user_id = sub.user_id 
			and nr.tiponotready_id = sub.tiponotready_id ) as fechaFin 
		from ccLogAgentesNotReady nr 
		WHERE fecha >= @from 
		AND fecha < @to )xdet 
	left join ccUsers usr on usr.user_id = xdet.user_id  
	left join ccTipoNotReady tn on tn.tipoNotready_id = xdet.tiponotready_id 
	order by [user], [status], fechaInicio

end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAgentSession - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepAgentSession]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()


if @action = 1
begin
   delete from RepAgentSession where date >= @from and date < @to

   insert into RepAgentSession
   select sessiontime.login as date, u.login as login, sessiontime.user_id, 
   u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension, sessiontime.login as loginTime, 
   logout as logoutTime,
   datediff(ss,sessiontime.login,logout) as sessionTime, 
   datediff(ss,sessiontime.login,logout) as sessionTimeSeconds,
   datepart(yyyy,sessiontime.login), datepart(mm,sessiontime.login), datepart(dd,sessiontime.login), 
   datepart(hh,sessiontime.login), datepart(mi,sessiontime.login) 
   from(select a.extension, a.user_id, a.fecha as ''login'',
    (select isnull(max(Fecha),getdate())
     from ccLogLogin b with(nolock)
     where b.user_id = a.user_id and
     b.tipomov = 0 and
     b.fecha >= a.fecha and
     b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
        from ccLogLogin with(nolock)
        where user_id = b.user_id and
        tipomov = 1 and
        fecha > a.fecha)) as ''logout''
    from ccLogLogin a
    where a.tipomov=1
    and fecha >= @from
    and fecha <= @to) as sessiontime
   left join ccusers u on (sessiontime.user_id = u.user_id)
  order by user_id, login
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInBill01900 - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepInBill01900]
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
		delete from RepInBill01900 where date >= @from AND date < @to

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
		FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
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
		FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
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
			,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
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
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInCalls - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepInCalls]
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
			[nMoh] [smallint] NOT NULL DEFAULT ((0)),
			[nWHag] [smallint] NOT NULL  DEFAULT ((0)),
			[nWHcl] [smallint] NOT NULL DEFAULT ((0))
		) ON [PRIMARY]

		CREATE TABLE [dbo].[#agents](
			[timegroup] [smalldatetime] NOT NULL,
			[user_id] [smallint] NOT NULL,
			[tlog] [smallint] NOT NULL DEFAULT (0),
			[treq] [smallint] NOT NULL DEFAULT (0),
			[tnot_av] [int] NOT NULL,
			[tav] [smallint] NOT NULL DEFAULT (0),
			[tprob] [smallint] NOT NULL DEFAULT (0),
			[tunknown] [smallint] NOT NULL DEFAULT (0),
			[tother] [smallint] NOT NULL DEFAULT (0),
			[nother] [smallint] NOT NULL DEFAULT (0),
			[nMoh] [smallint] NOT NULL DEFAULT ((0)),
			[nWHag] [smallint] NOT NULL DEFAULT ((0)),
			[nWHcl] [smallint] NOT NULL DEFAULT ((0))
		) ON [PRIMARY]

		CREATE TABLE [dbo].[#ccGenInSpec](
			[timegroup] [smalldatetime] NOT NULL,
			[inbound_id] [smallint] NOT NULL,
			[pos_tot] [smallint] NOT NULL,
			[pos_time] [int] NOT NULL,
			[pos_efect] [smallint] NOT NULL
		) ON [PRIMARY]

		CREATE TABLE [dbo].[#ccGenSession](
			[user_id] [smallint] NOT NULL,
			[login] [datetime] NOT NULL,
			[logout] [datetime] NOT NULL,
			[extension] [varchar](7) NOT NULL
		) ON [PRIMARY]

		CREATE TABLE [dbo].[#ccGenInCall](
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
			[nMoh] [smallint] NOT NULL DEFAULT ((0)),
			[nWHag] [smallint] NOT NULL DEFAULT ((0)),
			[nWHcl] [smallint] NOT NULL DEFAULT ((0))
		) ON [PRIMARY]

		CREATE TABLE [dbo].[#ccGenOutCall](
			[timegroup] [smalldatetime] NOT NULL,
			[cam_id] [smallint] NOT NULL,
			[user_id] [smallint] NOT NULL,
			[ntotal] [smallint] NOT NULL,
			[nno_agent] [smallint] NOT NULL,
			[nxfer] [smallint] NOT NULL,
			[nabnd_xfer] [smallint] NOT NULL,
			[nabnd_ring] [smallint] NOT NULL,
			[nno_answer] [smallint] NOT NULL,
			[nabnd_dialog] [smallint] NOT NULL,
			[nanswer] [smallint] NOT NULL,
			[nlost] [smallint] NOT NULL,
			[nhangup] [smallint] NULL,
			[txfer] [int] NOT NULL,
			[tdialog] [int] NOT NULL,
			[tnotes] [int] NOT NULL,
			[tring] [int] NOT NULL,
			[tresp] [int] NOT NULL,
			[nMoh] [smallint] NOT NULL DEFAULT ((0)),
			[nWHag] [smallint] NOT NULL DEFAULT ((0)),
			[nWHcl] [smallint] NOT NULL DEFAULT ((0))
		) ON [PRIMARY]

		INSERT INTO #callsin(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
		,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
		,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
		SELECT timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
		,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
		,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
		FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
			,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
			,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
			,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
			,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
			,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
			,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		FROM(SELECT cal_inicio AS timegroup,inbound_id,dni_id,[user_id]
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
		FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
		GROUP BY cal_inicio,inbound_id,dni_id,[user_id])xDetailCount
		right JOIN(SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
			,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
		FROM(SELECT timegroup,inbound_id,dni_id,[user_id]
			,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
			,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
			,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
			,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
			,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
		FROM(SELECT cal_inicio AS timegroup
			,DATEADD(hh,1,cal_inicio) AS timegroup_next
			,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
			,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
			,*
		FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
		UNION
		SELECT timegroup_next,inbound_id,dni_id,[user_id]
			,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
			,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
			,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
			,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
			,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
		FROM(SELECT cal_inicio AS timegroup
			,DATEADD(hh,1,cal_inicio) AS timegroup_next
			,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
			,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
			,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
		GROUP BY timegroup,inbound_id,dni_id,[user_id])xDetailTime
		ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id = xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
		WHERE timegroup>=@from AND timegroup<@to
		AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
		AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
		AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
		AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
		ORDER BY timegroup,inbound_id,dni_id,[user_id]

		INSERT INTO #ccGenSession ([user_id], extension, login, logout)
		SELECT uid, max(ext) ext, login, max(logout) logout
		FROM 
			(SELECT uid, ext, login, ISNULL(logout, (SELECT MIN(fecha) FROM ccLogLogin /*with (nolock, index(ccLogLogin_fecha))*/
			WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout 
			FROM
				(SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout
				FROM 
					(SELECT uid, ext, MAX(login) as login, logout
					FROM
						(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha) 
						FROM ccLogLogin subLogin /*with (nolock, index(ccLogLogin_fecha))*/ WHERE subLogin.tipomov = 0 
						AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout] 
						FROM ccLogLogin Login /*with (nolock, index(ccLogLogin_fecha))*/
						WHERE login.fecha >= dateadd(dd, -5, @from) and tipomov = 1
						GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail 
					WHERE logout IS NOT NULL GROUP BY uid, ext, logout) Login 
				RIGHT OUTER JOIN ccLogLogin  /*with (nolock, index(ccLogLogin_fecha))*/
				ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login AND ccLogLogin.extension = Login.ext)
				WHERE tipomov = 1
				and ccLogLogin.fecha >= dateadd( dd, -5, @from)) Det 
			) LoginDetail 
		WHERE logout IS NOT NULL
		AND login >= @from and login < @to
		GROUP BY uid, login

		INSERT INTO #ccGenInCall(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
		,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
		,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
		SELECT timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
		,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
		,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
		FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
			,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
			,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
			,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
			,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
			,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
			,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		FROM(SELECT cal_inicio AS timegroup,inbound_id,dni_id,[user_id]
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
		FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
		GROUP BY cal_inicio,inbound_id,dni_id,[user_id])xDetailCount
		right JOIN(SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
			,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
		FROM(SELECT timegroup,inbound_id,dni_id,[user_id]
			,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
			,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
			,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
			,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
			,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
		FROM(SELECT cal_inicio AS timegroup
			,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
			,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
			,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
			,*
		FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
		UNION
		SELECT timegroup_next,inbound_id,dni_id,[user_id]
			,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
			,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
			,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
			,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
			,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
		FROM(SELECT cal_inicio AS timegroup
			,DATEADD(hh,1,cal_inicio) AS timegroup_next
			,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
			,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
			,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
		GROUP BY timegroup,inbound_id,dni_id,[user_id])xDetailTime
		ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id=xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
		WHERE timegroup>=@from AND timegroup<@to
		AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
		AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
		AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
		AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
		ORDER BY timegroup,inbound_id,dni_id,[user_id]

		INSERT INTO #agents(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl)
		SELECT timegroup,[user_id],tlog,tnot_av
			,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
			,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
			,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
			,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
			,nother,nMoh,nWHag,nWHcl
		 FROM(
				SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
					,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
				 FROM(
					SELECT 
						xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
						,ISNULL(SUM(#ccGenInCall.txfer),0) as txfer
						,ISNULL(SUM(#ccGenInCall.tdialog),0) as tdialog
						,ISNULL(SUM(#ccGenInCall.tnotes),0) as tnotes
						,ISNULL(SUM(#ccGenInCall.tring),0) as tring
						,ISNULL(SUM(#ccGenInCall.nMoh),0) as nMoh
						,ISNULL(SUM(#ccGenInCall.nWHag),0) as nWHag
						,ISNULL(SUM(#ccGenInCall.nWHcl),0) as nWHcl
				
						,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
									 FROM #ccGenSession
									 WHERE [user_id]=xTimeDetail.[user_id]
										AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
							),0)AS t1
						,ISNULL((SELECT top 1 3600
									 FROM #ccGenSession
									 WHERE [user_id]=xTimeDetail.[user_id]
										AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
							),0)AS t2
						,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
									 FROM #ccGenSession
									 WHERE [user_id]=xTimeDetail.[user_id]
										AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
							),0)AS t3
						,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
									 FROM #ccGenSession
									 WHERE [user_id]=xTimeDetail.[user_id]
										AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
							),0)AS t4
					
					 FROM(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
								,ccLogAgentesDia.[user_id]
								,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
								,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
								,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
								,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
								,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
								,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
							 FROM ccLogAgentesDia
							 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
							 GROUP BY DATEADD(ss,-tStatus,fecha),ccLogAgentesDia.[user_id]
						)xTimeDetail
							LEFT OUTER JOIN #ccGenInCall ON(xTimeDetail.timegroup=#ccGenInCall.timegroup AND xTimeDetail.[user_id]=#ccGenInCall.[user_id])
						GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		 			)xDetail
			)xAllTimes
		 WHERE tlog>0
		 ORDER BY timegroup,[user_id]

		INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
			SELECT timegroup, ccInboundAgentes.inbound_id
				, COUNT(DISTINCT #agents.[user_id]) AS pos_max -- pos_tot
				, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
				, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
			 FROM #agents
				INNER JOIN ccInboundAgentes ON (#agents.[user_id] = ccInboundAgentes.[user_id])
			 WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0
			 GROUP BY timegroup, ccInboundAgentes.inbound_id

		--Borrar lo que esta para no repetir
		delete from [RepInCalls] where date >= @from AND date < @to

		insert into [RepInCalls]
		SELECT CONVERT(varchar(20), timegroup, 120) as [date], ccInbound.inbound_id as inboundId, descripcion as inbound, 
		ccDnis.dni_id as dnisId, ccDnis.dni_descripcion as dnis, 0 as [workgroupId], '''' as [workgroup], 0 as [areaId], 
		'''' as [area], 
		ntotal, nxfer, 
		nabnd_que, nxfer_que, nno_xfer, tque_max , 
		tque, nque, nanswer, nno_answer, nlost, nabnd_xfer, nabnd_ring, nabnd_dialog, pos_tot, pos_time, SL_P_1, SL_P_2 , avg, SL,nMoh, 
		nWHag, nWHcl, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
		, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
		, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
		, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
		, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes] 
		FROM (SELECT ISNULL(xDetCall.tg, xDetSpec.tg ) as timegroup , ISNULL(xDetCall.inbound_id, xDetSpec.inbound_id) inbound_id, xDetCall.dni_id as dni_id, 
			ISNULL(ntotal, 0) ntotal, ISNULL(nxfer, 0) nxfer, ISNULL(nabnd_que, 0) nabnd_que , ISNULL(nxfer_que, 0) nxfer_que, 
			ISNULL(nno_xfer, 0) nno_xfer, ISNULL(tque_max, 0) tque_max , ISNULL(tque, 0) tque, ISNULL(nque, 0) nque, 
			ISNULL(nanswer, 0) nanswer , ISNULL(nno_answer, 0) nno_answer, ISNULL(nlost, 0) nlost, ISNULL(nabnd_xfer, 0) nabnd_xfer , 
			ISNULL(nabnd_ring, 0) nabnd_ring, ISNULL(nabnd_dialog, 0) nabnd_dialog, ISNULL(pos_tot, 0) pos_tot , ISNULL(pos_time, 0) pos_time, 
			ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2 , ISNULL(tque/ NULLIF(nque, 0), 0) avg, 
			ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0) SL, ISNULL(nMoh, 0) nMoh, ISNULL(nWHag,0) nWHag, ISNULL(nWHcl,0) nWHcl 
			FROM (SELECT timegroup as tg, inbound_id, dni_id, SUM(ntotal) ntotal , SUM(nxfer) nxfer, SUM(nabnd) nabnd_que , SUM(nxfer_que) nxfer_que,
				SUM(ninitial + nout_service + nout_hour + nno_agent + ntimeout + noverflow ) nno_xfer , MAX(tque_max) tque_max, 
				SUM(tque) tque, NULLIF(SUM(nque), 0) nque , SUM(nanswer) nanswer, SUM(nno_answer) nno_answer , SUM(nlost) nlost, 
				SUM(nabnd_xfer) nabnd_xfer , SUM(nabnd_ring) nabnd_ring, SUM(nabnd_dialog) nabnd_dialog, SUM(nMoh) nMoh, SUM(nWHag) 
				nWHag, SUM(nWHcl) nWHcl , SUM(nansw_tres + nabnd_tres) AS SL_P_1 , 
				SUM(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2 
				FROM #callsin  
				WHERE timegroup >= @from 
				AND timegroup < @to
				GROUP BY  timegroup, inbound_id, dni_id) xDetCall 
		FULL OUTER JOIN ( SELECT  timegroup as tg, inbound_id, AVG(pos_tot) pos_tot, AVG(pos_time) pos_time  
					FROM #ccGenInSpec  
					WHERE timegroup >= @from
					AND timegroup < @to
					GROUP BY  timegroup, inbound_id ) xDetSpec 
			ON (xDetCall.tg = xDetSpec.tg  AND xDetCall.inbound_id = xDetSpec.inbound_id)) xDetail  
		INNER JOIN ccInbound ON (xDetail.inbound_id = ccInbound.inbound_id) 
		LEFT OUTER JOIN ccDnis ON (xDetail.dni_id = ccDnis.dni_id)
		where ccInbound.inbound_id is not null
		and ccDnis.dni_id is not null
		order by descripcion, CONVERT(varchar(20), timegroup, 120)

		update [RepInCalls] set
		[workgroupId] = b.idwg
		from [RepInCalls] a, ccInboundAgentes b
		where a.inboundId = b.inbound_id

		update [RepInCalls] set
		areaId = b.idarea
		from [RepInCalls] a, ccRIAAreaWorkGroup b
		where a.[workgroupId] = b.idwg

		update [RepInCalls]
		set workgroup = wgname, area = areaname
		from [RepInCalls] a, ccriacat_workgroup b, ccriacat_areas c
		where a.[workgroupId] = b.idwg
		and a.areaId = c.idarea

		drop table #callsin
		drop table #agents
		drop table #ccGenInSpec
		drop table #ccGenSession
		drop table #ccGenInCall
		drop table #ccGenOutCall
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInDIDResume - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepInDIDResume]
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
		-- CONSTRAINT [PK_ccGenInCallDNI] PRIMARY KEY CLUSTERED 
		--(
		--	[timegroup] ASC,
		--	[dni_id] ASC,
		--	[user_id] ASC
		--)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
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
					FROM	(
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
		
		
		delete [RepInDIDResume] where date >= @from AND date < @to 

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
		
	EXEC(@Sql)

		set @process = 'ccspRepInEffectiveness - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepInEffectiveness]
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
			CREATE TABLE [dbo].[#ccGenInCall](
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
						[nMoh] [smallint] NOT NULL DEFAULT ((0)),
						[nWHag] [smallint] NOT NULL DEFAULT ((0)),
						[nWHcl] [smallint] NOT NULL DEFAULT ((0))
					) ON [PRIMARY]

					CREATE TABLE [dbo].[#ccGenSession](
						[user_id] [smallint] NOT NULL,
						[login] [datetime] NOT NULL,
						[logout] [datetime] NOT NULL,
						[extension] [varchar](7) NOT NULL
					) ON [PRIMARY]

					CREATE TABLE [dbo].[#agents](
						[timegroup] [smalldatetime] NOT NULL,
						[user_id] [smallint] NOT NULL,
						[tlog] [smallint] NOT NULL DEFAULT (0),
						[treq] [smallint] NOT NULL DEFAULT (0),
						[tnot_av] [int] NOT NULL,
						[tav] [smallint] NOT NULL DEFAULT (0),
						[tprob] [smallint] NOT NULL DEFAULT (0),
						[tunknown] [smallint] NOT NULL DEFAULT (0),
						[tother] [smallint] NOT NULL DEFAULT (0),
						[nother] [smallint] NOT NULL DEFAULT (0),
						[nMoh] [smallint] NOT NULL DEFAULT ((0)),
						[nWHag] [smallint] NOT NULL DEFAULT ((0)),
						[nWHcl] [smallint] NOT NULL DEFAULT ((0))
					) ON [PRIMARY]		

					CREATE TABLE [dbo].[#ccGenInSpec](
						[timegroup] [smalldatetime] NOT NULL,
						[inbound_id] [smallint] NOT NULL,
						[pos_tot] [smallint] NOT NULL,
						[pos_time] [int] NOT NULL,
						[pos_efect] [smallint] NOT NULL
					) ON [PRIMARY]

			CREATE TABLE [dbo].[#ccGenInAbnd](
				[timegroup] [smalldatetime] NOT NULL,
				[inbound_id] [smallint] NOT NULL,
				[amount] [smallint] NOT NULL,
				[time_max] [smallint] NOT NULL,
				[time_tot] [bigint] NOT NULL,
				[<10] [smallint] NOT NULL,
				[<20] [smallint] NOT NULL,
				[<30] [smallint] NOT NULL,
				[<40] [smallint] NOT NULL,
				[<50] [smallint] NOT NULL,
				[<60] [smallint] NOT NULL,
				[<120] [smallint] NOT NULL,
				[<180] [smallint] NOT NULL,
				[<240] [smallint] NOT NULL,
				[<300] [smallint] NOT NULL,
				[+300] [smallint] NOT NULL
			) ON [PRIMARY]

			INSERT INTO #ccGenInCall(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
					,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
					,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
					SELECT timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
					,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
					,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
					FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
						,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
						,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
						,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
						,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
						,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
						,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
						,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
					FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id,[user_id]
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
					FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
					GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id,[user_id])xDetailCount
					right JOIN(SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
						,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
					FROM(SELECT timegroup,inbound_id,dni_id,[user_id]
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
					FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
					UNION
					SELECT timegroup_next,inbound_id,dni_id,[user_id]
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
						,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
					GROUP BY timegroup,inbound_id,dni_id,[user_id])xDetailTime
					ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id=xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
					WHERE timegroup>=@from AND timegroup<@to
					AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
					AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
					AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
					AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
					ORDER BY timegroup,inbound_id,dni_id,[user_id]

					INSERT INTO #ccGenSession ([user_id], extension, login, logout)
					SELECT uid, max(ext) ext, login, max(logout) logout
					FROM 
						(SELECT uid, ext, login, ISNULL(logout, (SELECT MIN(fecha) FROM ccLogLogin /*with (nolock, index(ccLogLogin_fecha))*/
						WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout 
						FROM
							(SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout
							FROM 
								(SELECT uid, ext, MAX(login) as login, logout
								FROM
									(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha) 
									FROM ccLogLogin subLogin /*with (nolock, index(ccLogLogin_fecha))*/ WHERE subLogin.tipomov = 0 
									AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout] 
									FROM ccLogLogin Login /*with (nolock, index(ccLogLogin_fecha))*/
									WHERE login.fecha >= dateadd(dd, -5, @from) and tipomov = 1
									GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail 
								WHERE logout IS NOT NULL GROUP BY uid, ext, logout) Login 
							RIGHT OUTER JOIN ccLogLogin  /*with (nolock, index(ccLogLogin_fecha))*/
							ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login AND ccLogLogin.extension = Login.ext)
							WHERE tipomov = 1
							and ccLogLogin.fecha >= dateadd( dd, -5, @from)) Det 
						) LoginDetail 
					WHERE logout IS NOT NULL
					AND login >= @from and login < @to
					GROUP BY uid, login

					INSERT INTO #agents(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl)
					SELECT timegroup,[user_id],tlog,tnot_av
						,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
						,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
						,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
						,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
						,nother,nMoh,nWHag,nWHcl
					 FROM(
							SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
								,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
							 FROM(
								SELECT 
									xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
									,ISNULL(SUM(#ccGenInCall.txfer),0) as txfer
									,ISNULL(SUM(#ccGenInCall.tdialog),0) as tdialog
									,ISNULL(SUM(#ccGenInCall.tnotes),0) as tnotes
									,ISNULL(SUM(#ccGenInCall.tring),0) as tring
									,ISNULL(SUM(#ccGenInCall.nMoh),0) as nMoh
									,ISNULL(SUM(#ccGenInCall.nWHag),0) as nWHag
									,ISNULL(SUM(#ccGenInCall.nWHcl),0) as nWHcl
							
									,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
												 FROM #ccGenSession
												 WHERE [user_id]=xTimeDetail.[user_id]
													AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
										),0)AS t1
									,ISNULL((SELECT top 1 3600
												 FROM #ccGenSession
												 WHERE [user_id]=xTimeDetail.[user_id]
													AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
										),0)AS t2
									,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
												 FROM #ccGenSession
												 WHERE [user_id]=xTimeDetail.[user_id]
													AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
										),0)AS t3
									,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
												 FROM #ccGenSession
												 WHERE [user_id]=xTimeDetail.[user_id]
													AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
										),0)AS t4
								
								 FROM(
										SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
											,ccLogAgentesDia.[user_id]
											,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
											,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
											,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
											,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
											,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
											,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
										 FROM ccLogAgentesDia
										 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
										 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
									)xTimeDetail
										LEFT OUTER JOIN #ccGenInCall ON(xTimeDetail.timegroup=#ccGenInCall.timegroup AND xTimeDetail.[user_id]=#ccGenInCall.[user_id])
									GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
	 							)xDetail
						)xAllTimes
					 WHERE tlog>0
					 ORDER BY timegroup,[user_id]

			INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
						SELECT timegroup, ccInboundAgentes.inbound_id
							, COUNT(DISTINCT #agents.[user_id]) AS pos_max -- pos_tot
							, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
							, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
						 FROM #agents
							INNER JOIN ccInboundAgentes ON (#agents.[user_id] = ccInboundAgentes.[user_id])
						 WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0
						 GROUP BY timegroup, ccInboundAgentes.inbound_id

			insert into #ccGenInAbnd (timegroup, inbound_id, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
			SELECT timegroup
					, inbound_id
					, COUNT(cal_inicio) AS amount
					, MAX(tAbnd) AS time_max
					, SUM(tAbnd) AS time_tot
					, COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [<10]
					, COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [<20]
					, COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [<30]
					, COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [<40]
					, COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [<50]
					, COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [<60]
					, COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [<120]
					, COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [<180]
					, COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [<240]
					, COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [<300]
					, COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [+300]
				 FROM	(
						SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
							, cal_inicio
							, inbound_id
							, statuscall_id
							, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
							, (cal_twait + cal_txfer + cal_tring) AS tAbnd
						 FROM ccCallsIn
							WHERE cal_inicio >= @from AND  cal_inicio < @to
							AND INBOUND_ID > 0
					) xCalls
				WHERE (abnd IS NOT NULL) 
				GROUP BY timegroup, inbound_id

			--Borrar lo que esta para no repetir
			delete from RepInEffectiveness where date >= @from AND date < @to

			insert into RepInEffectiveness
			SELECT timegroup as date, xDetail.inbound_id, isnull(descripcion, ''No ACD group'') descripcion , ntotal, nanswer, nabnd , tatention, 
			tque_avg as tqueavg, tQue_tot as tQuetot, nQue_tot as nQuetot, tabnd_tot as tabndtot, SL_P_1 as SLP1, SL_P_2 as SLP2, tresp, 
			/*pos_tot as postot,*/ pos_count as poscount, ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0)  as Porcentaje
			, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
			, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
			, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
			, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
			, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes] 
			FROM ( 

			SELECT ISNULL(xDetCall.timegroup, ISNULL(xDetSpec.timegroup, xDetAbnd.timegroup)) timegroup, ISNULL(xDetCall.inbound_id, 
			ISNULL(xDetSpec.inbound_id, xDetAbnd.inbound_id)) inbound_id, ISNULL(ntotal, 0) ntotal, ISNULL(nanswer, 0) nanswer, ISNULL(nabnd, 0) nabnd, 
			ISNULL(tatention, 0) tatention, ISNULL(tque_avg, 0) tque_avg, isnull(tQue_tot, 0) tQue_tot, isnull(nQue_tot, 0) nQue_tot, ISNULL(tabnd_tot, 0) tabnd_tot, 
			ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2, ISNULL(tresp, 0) tresp, ISNULL(pos_tot, 0) pos_tot, ISNULL(pos_count, 0) pos_count 

			FROM (

			SELECT timegroup, inbound_id, SUM(ntotal) AS ntotal, SUM(nanswer) AS nanswer, SUM(nabnd) AS nabnd, SUM(tdialog + tnotes) tatention, 
			ISNULL(sum(tque)/ NULLIF(sum(nque), 0), 0) AS tque_avg, sum(tque) as tQue_tot, sum(nQue) as nQue_tot, SUM(nansw_tres + nabnd_tres) AS SL_P_1, 
			SUM(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, SUM(tresp) AS tresp  
			FROM #ccGenInCall  
			WHERE timegroup >= @from
			AND timegroup < @to 
			GROUP BY timegroup , inbound_id) xDetCall  
			LEFT JOIN (
				SELECT timegroup, inbound_id, SUM(pos_tot) AS pos_tot, SUM(pos_tot) AS pos_avg, SUM(pos_efect) AS pos_efect, COUNT(pos_tot) AS pos_count  
				FROM #ccGenInSpec 
				WHERE timegroup >= @from
				AND timegroup < @to 
				GROUP BY timegroup , inbound_id) xDetSpec 
			ON (xDetCall.timegroup = xDetSpec.timegroup AND xDetCall.inbound_id = xDetSpec.inbound_id)  
			LEFT JOIN (
				SELECT timegroup, inbound_id, SUM(time_tot) AS tabnd_tot   
				FROM #ccGenInAbnd  
				WHERE timegroup >= @from 
				AND timegroup < @to 
				GROUP BY timegroup , inbound_id) xDetAbnd 
			ON (xDetCall.timegroup = xDetAbnd.timegroup AND xDetCall.inbound_id = xDetAbnd.inbound_id) 
			) xDetail  
			LEFT JOIN ccInbound ON (xDetail.inbound_id=ccInbound.inbound_id)  
			ORDER BY date

			drop table #ccGenInCall
			drop table #ccGenInSpec
			drop table #ccGenSession
			drop table #agents
			drop table #ccGenInAbnd
	end'
			
	EXEC(@Sql)
	
		set @process = 'GetPivotColumns - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[GetPivotColumns]	
	@id int	
AS
BEGIN
	SELECT [columns],complementColumns,pivotFunction 
	FROM dbo.PivotReports 
	WHERE id = @id
END'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepInCallsDetail - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepInCallsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInCallsDetail where date >= @from AND date < @to
	--select * from RepInCallsDetail
	--select top 10 * from cccallsin

	insert into RepInCallsDetail
	select cal_inicio, Inbound_id, '''', statusCall_id, '''', calif_id, '''', isnull(califSub_id,0), '''', dni_id, '''', user_id, '''',
	isnull(cal_key,''''), cal_ANI, cal_tWait, cal_tXfer, cal_tRing, cal_tDialog, cal_extension, '''',
	cal_whoHung, cal_tMoh, datepart(yyyy,cal_inicio), datepart(mm,cal_inicio), datepart(dd,cal_inicio)
	, datepart(hh,cal_inicio), datepart(mi,cal_inicio) 
	from cccallsin a 			
	where cal_inicio >= @from AND cal_inicio < @to

	update a set acdGroup = isnull(descripcion,'''')
	from RepInCallsDetail a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set callStatus = isnull(descripcion,'''')
	from RepInCallsDetail a
	left join ccstatusllamada b 
	on a.callStatusId = b.statusCall_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,'''')
	from RepInCallsDetail a
	left join cctipocalif b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,'''')
	from RepInCallsDetail a
	left join cctipocalifsub b 
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInCallsDetail a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set dnis = isnull(dni_numero,'''')
	from RepInCallsDetail a
	left join ccdnis b 
	on a.dnisId = b.dni_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInCallsDetail a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to
end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepInNotTransferred - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepInNotTransferred]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInNotTransferred where date >= @from AND date < @to
	--select * from RepInCallsDetail
	--select top 10 * from cccallsin


	insert into RepInNotTransferred
	select CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121) as dateHour, a.Inbound_id, 
	'''' as acd, statusCall_id, '''' as statusCall,'''' as statusCallCount,count(statusCall_id) as count,  b.IDArea, 
	'''' as area, 1 as wgId, ''Workgroup1'' as wg,
	datepart(yyyy,max(cal_inicio)), datepart(mm,max(cal_inicio)), datepart(dd,max(cal_inicio)), 
	datepart(hh,max(cal_inicio)), datepart(mi,max(cal_inicio)) 
	from cccallsin a 		
	left join ccInbound b
	on	b.Inbound_id = a.Inbound_id
	where cal_inicio >= @from AND cal_inicio < @to and statuscall_id in (2,3,4,6,7,8)
	group by CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121),a.Inbound_id, a.statusCall_id, user_id,b.IDArea

	update a set acdGroup = isnull(descripcion,'''')
	from RepInNotTransferred a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set callStatus = isnull(descripcion,''''), callStatus_Count = isnull(descripcion,'''') + ''_Count''
	from RepInNotTransferred a
	left join ccstatusllamada b 
	on a.callStatusId = b.statusCall_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInNotTransferred a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepInRejectedCalls - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepInRejectedCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInRejectedCalls where date >= @from AND date < @to
	
	insert into RepInRejectedCalls
		select 			
		D.dni_id,		
		reject.dnis,
		D.dni_Descripcion,
		reject.InBound_id,
		inBound.descripcion,
		reject.cal_inicio,
		reject.ani,
		reject.puerto,
		datepart(yyyy,reject.cal_inicio), datepart(mm,reject.cal_inicio), datepart(dd,reject.cal_inicio), 
		datepart(hh,reject.cal_inicio), datepart(mi,reject.cal_inicio) 		
	from ccCallsReject reject
	INNER JOIN ccDNIS D ON D.dni_numero = reject.dnis and D.dni_Status=1
	INNER JOIN ccInbound inBound ON reject.Inbound_id = inBound.Inbound_id
	where cal_inicio >= @from AND cal_inicio < @to

end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallBacks - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepOutCallBacks]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete RepOutCallBacks where date >= @from and date < @to

		insert into RepOutCallBacks
		select cal_fecha as [date], b.user_id as [userId], b.login as [user], c.cam_id as [campaignId], c.cam_descripcion as [campaign],
		cal_key as [callKey], cal_telefono as [originalTel], cal_telCB as [scheduledTel], cal_fecha as [originalDate], 
		cal_fusercallback as [scheduledDate],
		case a.status when 0 then ''Pending / Pendiente''
		when 1 then ''Answer / Contestado''
		when 2 then ''No Answer / No Contestado''
		when 3 then ''Recicled / Reciclado''
		when 4 then ''Expired / Expirado''
		when 5 then ''Old Record / Registro Viejo''
		when 6 then ''Load Record / Carga de Registro'' end as [status], 
		case when cal_fcallback is null then ''''
			when convert(varchar(13),cal_fcallback) = ''jan 1 1900'' then ''''
			else convert(varchar(255),cal_fcallback) end as [dialDate]
		, datepart(yyyy,cal_fecha) as [year]
		, datepart(mm,cal_fecha) as [month]
		, datepart(dd,cal_fecha) as [day]
		, datepart(hh,cal_fecha) as [hour]
		, datepart(mi,cal_fecha) as [minutes]
		from ccocallbacks a, ccusers b, cccamps c
		where cal_fecha between @from and @to
		and a.user_id = b.user_id
		and a.cam_id = c.cam_id
	end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepIVRGeneral - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepIVRGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete RepIVRGeneral where date >= @from and date < @to

		insert into RepIVRGeneral
		select convert(varchar(10),date,121) as [date], 
		sum(case when calId = 0 then 1 else 0 end) as [noTransferred], 
		sum(case when calId > 0 then 1 else 0 end) as [transferred], 
		count(*) as [total]
		, datepart(yyyy,convert(varchar(10),date,121))
		, datepart(mm,convert(varchar(10),date,121))
		, datepart(dd,convert(varchar(10),date,121))
		, datepart(hh,convert(varchar(10),date,121))
		, datepart(mi,convert(varchar(10),date,121))
		from (select A.Ivr_id, A.cal_ani, isnull(B.cal_id,0) as calId ,A.date 
				from IVRCallsIn as a 
				left join ccCallsIn as b on  A.IVR_id = B.IVR_id 
				where date >= @from and date < @to) as c
		where date >= @from and date < @to
		group by convert(varchar(10),date,121)
		order by convert(varchar(10),date,121)
	end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepIVRByOptions - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepIVRByOptions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete from RepIVRByOptions where date >= @from AND date < @to
		
		insert into RepIVRByOptions
		select date, [level] as [levelOption], min([Description]) as [descriptionOption], count(*) as [quantityOption]
		, datepart(yyyy,date)
		, datepart(mm,date)
		, datepart(dd,date)
		, datepart(hh,date)
		, datepart(mi,date)
		from ivrstructure,
		( 
			select ivrLLamadas.date, ivr_id, isnull
			((
				select selectedOption + '','' 
				from IVROptions	
				where IVROptions.ivr_id = ivrLLamadas.ivr_id 
				order by IVROptions.date 
				for xml path('''')
			),''#'') as opciones 
			from (
				select A.Ivr_id, A.cal_ani, isnull(B.cal_id,0) as calId , convert(datetime,convert(varchar(11),A.date)) as [date]
				from IVRCallsIn as a 
				left join ccCallsIn as b on  A.IVR_id = B.IVR_id 
				where date >= @from and date < @to
			)ivrLLamadas
			where ivrLLamadas.date >= @from and ivrLLamadas.date < @to
		)x 
		where opciones like [level]+''%''
		group by date, [level]
		order by date, [level]

	end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallsDetail - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepOutCallsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @IVA INT
SELECT @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25

if @action = 1
	begin		
		--Borrar lo que esta para no repetir
		delete from RepOutCallsDetail where date >= @from AND date < @to

		INSERT INTO RepOutCallsDetail
		SELECT Call.cal_inicio as [date],
		cal_key as [callKey],
		Call.cal_telefono AS [telephone], 
		Call.cal_txfer + call.cal_tring AS [transfer], 
		Call.cal_tdialog AS [dialog], 
		ISNULL(Call.cal_tMoh,0) as [nque],
		Call.cal_tnotas AS [wrapup], 
		ISNULL( Tipo.[description], '''') AS [CallDisposition], 
		Call.cal_extension AS [extension],
		Usr.user_id as [userId],
		ISNULL(Usr.login,''Sin nombre de usuario'') [login], 
		ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username], 
		camps.cam_id as [campaignId],
		ISNULL(camps.cam_descripcion, ''Sin campaña'') as [campaign], 
		(CEILING((cal_tXfer + cal_tRing + cal_tDialog +1) / 60.0 )* 60) AS [duration], 
		ISNULL(Call.costo,0.00) as [ncost], 
		@IVA as iva, 
		convert(decimal(10,2),ISNULL(Call.costo,0.00) * (1 + (@IVA / 100.00))) as total,
		ISNULL(prov.descrip, ''Sin proveedor'') as [ByCarrier], 
		ISNULL(tl.descrip, ''Indefinido'') as [Calltypes], 
		case when Call.cal_manual = 0 then ''Auto'' else ''Manual'' end as [dialType], 
		case when cal_whoHung = 0 then ''Cliente'' else ''Agente'' end [whoHangUp], 
		case when call.califsub_id = 0 then ''Sin Calificar'' else isnull(sub.califSubDesc, '''') end as [subDisposition],
		sta.descripcion as [dialResult],
		Call.cal_id as [calId]
		, datepart(yyyy,Call.cal_inicio) AS [year]
		, datepart(mm,Call.cal_inicio) as [month]
		, datepart(dd,Call.cal_inicio) as [day]
		, datepart(hh,Call.cal_inicio) as [hour]
		, datepart(mi,Call.cal_inicio) as [minutes]
		FROM ccoCallsOut Call  
		LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id=Tipo.calif_id  
		INNER JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
		LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]  
		LEFT JOIN ccStatusLlamada sta on call.statuscall_id = sta.statuscall_id  
		LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]  
		LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = 1)  
		LEFT JOIN ccTipoCalifSubOut sub on call.califsub_id = sub.califsub_id 
		WHERE Call.cal_inicio >= @from
		AND Call.cal_inicio < @to
		and cal_manual in (0, 2) 
		order by date
	end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallsByTelephone - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepOutCallsByTelephone]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete RepOutCallsByTelephone where date >= @from and date < @to

		insert into RepOutCallsByTelephone
		select timegroup as [date], cal_telefono as [telephone], cal_key as [callKey], cam_id as [campaignId], cam_descripcion as [campaign], 
		count(cal_telefono) as quantity
		, datepart(yyyy,timegroup) as [year]
		, datepart(mm,timegroup) as [month]
		, datepart(dd,timegroup) as [day]
		, datepart(hh,timegroup) as [hour]
		, datepart(mi,timegroup) as [minutes]
		from(select cal_telefono, convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) as timegroup, cal_key, a.cam_id, b.cam_descripcion
			 from ccocallsout a
			 left join cccamps b on (a.cam_id = b.cam_id) 
			 where cal_inicio >= @from 
			 and cal_inicio < @to) c
		group by cal_telefono, timegroup, cal_key, cam_id, cam_descripcion
		order by cal_telefono, count(cal_telefono)
	end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepIVRDetail - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepIVRDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin

		select A.Ivr_id,A.cal_ani,isnull(B.user_id,0) as [user_id],isnull(B.calif_id,0) as [calif_id]
		,isnull(B.cal_id,0) as [cal_id],A.date 
		into #IVRLlamadas
		from IVRCallsIn as A 
		left join ccCallsIn As B on  A.IVR_id = B.IVR_id 
		where date >= @from and date < @to
		
	delete from RepIVRDetail where date >= @from AND date < @to
		
	insert into RepIVRDetail
		select #IVRLlamadas.date as fecha, cal_ani as telefono
			, isNull(u.nombres + '' '' + u.apellidopaterno + '' '' + u.apellidomaterno,'''') as nombre
			, isnull(calif.description, #IVRLlamadas.calif_id) as calificacion, cal_id as cal_id
			, isnull(
			(
				select selectedOption + '',''	from IVROptions
				where IVROptions.ivr_id = #IVRLlamadas.ivr_id
				order by IVROptions.date for xml path('''')
			),'''') as opciones
			, isnull(datediff( ss, date, maxdate),0) as tiempo,
			datepart(yyyy,[date]),
			datepart(mm,[date]),
			datepart(dd,[date]),
			datepart(hh,[date]),
			datepart(mi,[date])
			from #IVRLlamadas
			left join
			(
				select ivr_id, max(date) as maxDate from IVROptions
				group by ivr_id
			) optTime on #IVRLlamadas.ivr_id = optTime.ivr_id
			left join ccusers u on (u.user_id = #IVRLlamadas.user_id)
			left join cctipocalif calif on (calif.calif_id = #IVRLlamadas.calif_id)
			where #IVRLlamadas.date >= @from and #IVRLlamadas.date < @to
			order by date
	
	drop table #IVRLlamadas
	end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepOutDials - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepOutDials]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
		declare @total decimal(10,2)
		
		select @total = count(*) from ccologdials as a 
		left join ccTipoResultadoDial as b on (a.tipoResDial_id = b.tipoResDial_id)
		where fecha >= @from and fecha < @to
		and descripcion is not null
		and cal_id is not null
		
		delete from RepOutDials where date >= @from AND date < @to
		
		insert into RepOutDials
		select CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121) as [date],
		a.cam_id as campaignId, c.cam_descripcion as campaign, min(d.idwg) as workgroupId, min(wgname) as workgroup, min(f.idarea) as areaId, min(areaname) as area,
		a.tipoResDial_id, descripcion,
		descripcion + ''_Count'' as descripcion_count,
		count(*) as count,
		descripcion + ''_Avg'' as descripcion_avg,
		convert(decimal(10,2), (count(*)/@total)*100.00) as avg,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) AS [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [month],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [minutes]
		from ccologdials as a 
		left join ccTipoResultadoDial as b on (a.tipoResDial_id = b.tipoResDial_id)
		left join ccCamps as c on (a.cam_id = c.cam_id)
		left join ccRIAWorkGroup_Calid as d on (a.cal_id = d.cal_id)
		left join ccRIACat_WorkGroup as e on (d.idwg = e.idwg)
		left join ccRIAAreaWorkGroup as f on (e.idwg = f.idwg)
		left join ccRIACat_Areas as g on (f.idarea = g.idarea)
		where fecha >= @from and fecha < @to
		and descripcion is not null
		and a.cal_id is not null
		and d.tipo = 1
		and f.idarea is not null
		group by CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121), 
		a.cam_id, c.cam_descripcion, a.tipoResDial_id, descripcion  
	end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepIVRFirstOption - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepIVRFirstOption]
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

	DELETE FROM RepIVRFirstOption WHERE [date]>=@from AND [date]<@to

	INSERT INTO RepIVRFirstOption
	([date],[descriptionOption],[option_Count],[count],[year],[month],[day],[hour],[minutes])
	
	SELECT
		[date],
		selectedoption,
		'''' + selectedoption + ''_Count'',
		COUNT(selectedOption),
		datepart(yyyy,[date]),
		datepart(mm,[date]),
		datepart(dd,[date]),
		datepart(hh,[date]),
		datepart(mi,[date])
	from
	(
		select convert(varchar(10), [date], 121) as [date], selectedOption from IVROptions
		join
		(
			select ivr_id, min([date]) as minDate from IVROptions
			where [date] >= @from and [date] < @to
			group by ivr_id
		) A
		on A.ivr_id = IVROptions.ivr_id and A.minDate=IVROptions.[date]
	) B
	GROUP BY [date], selectedOption
	ORDER BY [date], selectedOption
	
end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepInChangeFlow - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepInChangeFlow]
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

	DELETE FROM RepInChangeFlow WHERE [date]>=@from AND [date]<@to

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
			with (nolock, index(IX_ccCallsIn))
			WHERE cal_inicio>=@from AND cal_inicio<@to AND INBOUND_ID > 0 AND [user_id] > 0
			GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id
	) xFers
	WHERE [date]>=@from AND [date]<@to
	AND ISNULL(xfer,0) > 0
	ORDER BY [date],inbound_id
	
	update r set
	r.Inbound = (select i.Descripcion from ccInbound i where i.Inbound_id = r.InboundId)
	from RepInChangeFlow r
	where [date] >= @from and [date] < @to
	
end'
			
	EXEC(@Sql)
	
		set @process = 'ccspGetGroupByColumns - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspGetGroupByColumns]   
 @id int   
AS  
BEGIN  
 SELECT [columns],[groupByColumns]
    FROM dbo.GroupByReports   
    WHERE id = @id  
END'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallBilling - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepOutCallBilling]
	@action as tinyint,
	@from as datetime = null,
	@to as datetime = null
AS

declare @country as tinyint
declare @iva as decimal(3,2)
declare @aux as varchar(3)

select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104
select @aux = isnull(valor,0) from ccsettings where setting_id = 25
set @iva=convert(decimal(3,2),''1.''+@aux)

if @country is null set @country = 1

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	
	delete from RepOutCallBilling where date >= @from AND date < @to
	
		SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS date
			, cam_id, [user_id],
			provedor_id, tipoLlamada_id , min(tipoLlamada) as tipoLlamada
			, COUNT(*) as amount
			, SUM( mins) as mins
			, SUM( costo ) as costo
			, SUM( costo ) * @iva as costoIva
			into #TempOutCallBilling 
		FROM
		(
			SELECT cal_inicio, cco.cam_id as cam_id,
					cco.user_id as user_id,
					cco.provedor_id,
					cco.tipoLlamada_id, t.descrip as tipoLlamada, CEILING((cal_tXfer + cal_tRing + cal_tDialog +1 ) / 60.0 ) as mins, costo
				FROM ccoCallsOut cco 
					inner join cstoTipoLlamada t on cco.tipoLlamada_id = t.tipoLlamada_id			
				WHERE cal_inicio >= @from AND  cal_inicio < @to and cco.provedor_id is not null and cal_manual in (0,2) and country_id = @country
			
			-- Tambien las llamdas que fueron fax
			UNION ALL

			SELECT cco.fecha as fecha, cco.cam_id, 0, p.provedor_id, l.tipoLlamada_id, l.descrip as tipoLlamada,1, t.MinutoUno as costo
				FROM ccoLogDials cco, ccoDialers cd, cstoProvedor p, cstoTarifa t, cstoTipoLlamada l
				WHERE 
				l.country_id = @country
				and cco.answerbit = 1 and cco.tiporesdial_id <> 1
				and cco.fecha >=  @from AND cco.fecha < @to
				and cco.puerto = cd.puerto
				and cd.provedor_id = p.provedor_id	
				and p.provedor_id = t.provedor_id
				and l.longitud = len(cco.telefono)
				and cco.telefono like l.prefijo
				and t.tipoLlamada_id = l.tipoLlamada_id
		
		) costo
		GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), cam_id, [user_id], provedor_id, tipoLlamada_id	

	insert RepOutCallBilling
		select [date], [cam_id], [campaign], [user_id], [agentName], [username], [provedor_id],[provedor], [tipoLlamada_id], 
			(case when tipo = ''amount'' then [tipoLLamada] + ''Llamadas_''  + '' / '' + [tipoLLamada] + ''Calls_''  + ''_Count''
				  when tipo = ''mins'' then + [tipoLLamada] + ''_Min_Facturados'' + '' / '' + [tipoLLamada] + ''_Min_Facturados'' + ''_Count''
				  when tipo = ''costo'' then + [tipoLLamada] + ''_costo'' + '' / '' + [tipoLLamada] + ''_Cost'' + ''_Count''
				  when tipo = ''costoIva'' then + [tipoLLamada] + ''_IVA'' + '' / '' + [tipoLLamada] + ''_Tax''+ ''_Count''
				  else tipo end ) as tipoLLamada_Count
			,convert(varchar,[tipollamada_Count])  as [count]
			, [tipoLLamada] as tipoLlamadaDesp, case when tipo = ''costo'' then convert(int,convert(decimal(10,2),[tipollamada_Count]) ) else 0 end 			
			, datepart(yyyy,[date]) as [year]
			, datepart(mm,[date]) as [month]
			, datepart(dd,[date]) as [day]
			, datepart(hh,[date]) as [hour]
			, datepart(mi,[date]) as [min]
		from 
		   (
				select [date], temp.cam_id as cam_id, camps.cam_descripcion as campaign, 
					temp.user_id as user_id, ccuse.Nombres+'' ''+ ccuse.ApellidoPaterno+'' ''+ccuse.ApellidoMaterno as agentName, ccuse.Login as username,
					temp.provedor_id as provedor_id, prov.descrip as provedor,
					[tipoLlamada_id], [tipoLLamada],[tipoLLamada] as tipoLlamadaDesp,convert(varchar,[amount]) as [amount], convert(varchar,[mins]) as [mins], convert(varchar,[costo]) as [costo], convert(varchar,[costoIva]) as [costoIva]
			   from #TempOutCallBilling temp
				inner join ccCamps camps on camps.cam_id = temp.cam_id
				inner join ccUsers ccuse on ccuse.User_id = temp.user_id
				inner join cstoprovedor prov on prov.provedor_id = temp.provedor_id
			) p
		UNPIVOT
		   ([tipollamada_Count] for tipo IN 
			  ([amount], [mins], [costo], [costoIva])
		)AS unpvt

	drop table #TempOutCallBilling
	
end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepOutDispositions - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepOutDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepOutDispositions where date >= @from AND date < @to
	--select * from RepOutDispositions
	--select top 10 * from ccocallsout
	--select * from cccamps

	insert into RepOutDispositions 
	select CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121) as dateHour, a.cam_id, '''' as Campaign, a.calif_id, '''' as DispName, '''', count(calif_id) DispAmount, user_id, '''' as login
	, '''' as username, b.IDArea, '''' as areaName, 1 as wgId, ''Workgroup1'' as wg,
	datepart(yyyy,max(cal_inicio)) as year, datepart(mm,max(cal_inicio)), datepart(dd,max(cal_inicio)),
	datepart(hh,max(cal_inicio)), datepart(mi,max(cal_inicio))
	from ccocallsout a 		
	left join cccamps b
	on	b.cam_id = a.cam_id		
	where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13
	and b.idArea is not null
	group by CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121),a.cam_id, a.calif_id, user_id,b.IDArea

	update a set campaign = isnull(cam_descripcion,'''')
	from RepOutDispositions a
	left join cccamps b 
	on a.campaignId = b.cam_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,''Dispositionless''), disposition_count = isnull(description,''Dispositionless'') + ''_Count''
	from RepOutDispositions a
	left join cctipocalifout b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepOutDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepOutDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepOutDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to


end'
			
	EXEC(@Sql)
	
		set @process = 'ccspRepOutKPI - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepOutKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete RepOutKPI where date >= @from AND date < @to

	insert into RepOutKPI
	select dateHour, cam_id, '''' as campaign, totalCalls, avgXfer, avgCallTime, c10sec, c20sec, c30sec, cMax, AnsweredCalls, ISNULL((AnsweredCalls * 100.00)/NULLIF(totalCalls,0),0) as AnsweredPctg,
		ComplementCalls as RemainingCalls,  ISNULL((ComplementCalls * 100.00)/NULLIF(totalCalls,0),0) as RemainingPct, AbandonedCalls, ISNULL((AbandonedCalls * 100.00)/NULLIF(totalCalls,0),0) as AbandonedPctg, ISNULL((3600*1.00/NULLIF(totalCalls,0)),0) as AvgTimeBtwCalls, 
			[year], [month], [day],  [hour], [minutes] from (
			select CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) as dateHour,
			calls.cam_id, sum(isnull(total,0)) + sum(isnull(total2,0)) + sum(isnull(total3,0)) as totalCalls,avg(calls.cal_tXfer) as avgXfer, avg(calls.cal_tDialog) as avgCallTime,
			sum(isnull(c10,0)) as c10sec ,sum(isnull(c20,0)) as c20sec ,sum(isnull(c30,0)) as c30sec, sum(isnull(cMax,0)) as cMax,
			sum(isnull(total,0)) as AnsweredCalls, sum(isnull(total2,0)) as ComplementCalls, sum(isnull(total3,0)) as AbandonedCalls,
			datepart(yyyy,max(cal_inicio)) as [year], datepart(mm,max(cal_inicio)) as [month], datepart(dd,max(cal_inicio)) as [day],
			datepart(hh,max(cal_inicio)) as [hour], datepart(mi,max(cal_inicio)) as [minutes]
			from ccocallsout as calls with(nolock)
			left join (
					select count(cal_id) as total,cal_id,cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour,
					case when statusCall_id = 13 and cal_tDialog<=10 then 1 else 0 end C10,
					case when statusCall_id = 13 and cal_tDialog<=20 and cal_tDialog > 10 then 1 else 0 end C20,
					case when statusCall_id = 13 and cal_tDialog<=30 and cal_tDialog > 20 then 1 else 0 end C30,
					case when statusCall_id = 13 and cal_tDialog>30 then 1 else 0 end CMax
					 from ccocallsout with(nolock) where statusCall_id = 13 and cal_inicio >= @from and cal_inicio < @to group by statusCall_id,cal_tDialog,cal_id,cam_id,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 
			) as times 
			on (CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) = times.dateHour and calls.cal_id = times.cal_id ) 
			left join (
					select count(cal_id) as total2, cal_id,cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour
					 from ccocallsout with(nolock) where statusCall_id not in(13,5) and cal_inicio >= @from and cal_inicio < @to group by statusCall_id,cal_tDialog,cal_id,cam_id,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 
			) as times2 
			on (CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) = times2.dateHour and calls.cal_id = times2.cal_id )
			left join (
					select count(cal_id) as total3, cal_id,cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour
					 from ccocallsout with(nolock) where statusCall_id in(5) and cal_inicio >= @from and cal_inicio < @to group by statusCall_id,cal_tDialog,cal_id,cam_id,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 
			) as times3
			on (CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) = times2.dateHour and calls.cal_id = times2.cal_id )
			group by calls.cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 	
			) as tablon

			update a set campaign = isnull(b.cam_descripcion,'''')
			from RepOutKPI a
			left join ccCamps b
			on a.campaignId = b.cam_id
			where date >= @from AND date < @to
	
end'
				
	EXEC(@Sql)
	
		set @process = 'ccspRepOutSubDispositions - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepOutSubDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepOutDispositions where date >= @from AND date < @to
	--select * from RepOutSubDispositions
	--select top 10 * from ccocallsout
	--select * from ccsettings

	insert into RepOutSubDispositions 
	select CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121) as dateHour, a.cam_id, '''' as Campaign, isnull(a.califSub_id,0), '''' as DispName, '''', count(calif_id) DispAmount, user_id, '''' as login
	, '''' as username, b.IDArea, '''' as areaName, 1 as wgId, ''Workgroup1'' as wg,
	datepart(yyyy,max(cal_inicio)) as year, datepart(mm,max(cal_inicio)), datepart(dd,max(cal_inicio)),
	datepart(hh,max(cal_inicio)), datepart(mi,max(cal_inicio))
	from ccocallsout a 		
	left join ccCamps b
	on	b.cam_Id = a.cam_id		
	where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13
	group by CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121),a.cam_id, a.califSub_id, user_id,b.IDArea

	update a set campaign = isnull(cam_descripcion,'''')
	from RepOutSubDispositions a
	left join ccCamps b 
	on a.campaignId = b.cam_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,''Dispositionless''), subDisposition_count = isnull(califSubDesc,''Dispositionless'') + ''_Count''
	from RepOutSubDispositions a
	left join cctipocalifsubout b 
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepOutSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepOutSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepOutSubDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
				
	EXEC(@Sql)
	
		set @process = 'ccspRepSpecialTimes - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepSpecialTimes]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		--Borrar lo que esta para no repetir
		delete from RepSpecialTimes where date >= @from AND date < @to

		declare @NotReady varchar(max)
		select top 1 @NotReady = descripcion
		from ccTipoNotReady
		order by tiponotready_id

		select cam_id, inbound_id, [Espec/Camp], Periodo, 
		isnull([Tiempo Disponible],0) + isnull([Tiempo Dialogo],0) + isnull([Tiempo No Disponible],0) + isnull([Otro],0) as [Tiempo Sesion],
		isnull([Tiempo Disponible],0) as [Tiempo Disponible], 
		isnull([Tiempo Dialogo],0) as [Tiempo Dialogo], 
		isnull([Tiempo No Disponible],0) as [Tiempo No Disponible], 
		isnull([Otro],0) as [Otro]
		into #Report1
		from(
			select cam_id, 0 as inbound_id, ''Camp - '' + b.cam_descripcion as [Espec/Camp], 
				case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) 
					 else convert(varchar(13), fecha,121) + '':30:00'' end as Periodo,
				case when tipostatusage_id = 3 then ''Tiempo Disponible'' when tipostatusage_id = 4 then ''Tiempo Dialogo'' 
					when tipostatusage_id = 2 then ''Tiempo No Disponible'' else ''Otro'' end as tDescripcion,
				sum(tstatus) as tstatus
			from ccLogAgentesDia a
			left outer join cccamps b on (cam_id = idcampesp and tipo = 1)
			where (idCampEsp is not null)
			and (tipo is not null)
			and tipo = 1
			and fecha between @from and @to
			group by cam_id, cam_descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end,
				case when tipostatusage_id = 3 then ''Tiempo Disponible'' when tipostatusage_id = 4 then ''Tiempo Dialogo'' when tipostatusage_id = 2 then ''Tiempo No Disponible'' else ''Otro'' end 
			union
			select 0 as cam_id, inbound_id, ''ACD - '' + b.descripcion as [Espec/Camp], 
				case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) 
					else convert(varchar(13), fecha,121) + '':30:00'' end as Periodo, 
				case when tipostatusage_id = 3 then ''Tiempo Disponible'' when tipostatusage_id = 4 then ''Tiempo Dialogo'' 
					when tipostatusage_id = 2 then ''Tiempo No Disponible'' else ''Otro'' end as tDescripcion,
				sum(tstatus) as tstatus
			from ccLogAgentesDia a
			left outer join ccinbound b on (inbound_id = idcampesp and tipo = 0)
			where (idCampEsp is not null)
			and (tipo is not null)
			and tipo = 0
			and fecha between @from and @to
			group by inbound_id, descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end,
				case when tipostatusage_id = 3 then ''Tiempo Disponible'' when tipostatusage_id = 4 then ''Tiempo Dialogo'' when tipostatusage_id = 2 then ''Tiempo No Disponible'' else ''Otro'' end 
		) times
		pivot (max(tstatus) for [tdescripcion] in ([Tiempo Disponible], [Tiempo Dialogo], [Tiempo No Disponible], [Otro])) as pvtTimes
		where [Espec/Camp] is not null
		order by [Espec/Camp], Periodo

		select * into #notready from(
		select ''Camp - '' + cam_descripcion as [Espec/Camp],  
			case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) 
					else convert(varchar(13), fecha,121) + '':30:00'' end as Periodo,
			c.descripcion as [descriptionT], sum(tstatus) as T, c.descripcion as [descriptionN], count(*) as N
		from ccLogAgentesNotReady a
		left outer join cccamps b on (idcampesp = cam_id and tipo = 1)
		left outer join ccTipoNotReady c on (a.tiponotready_id = c.tiponotready_id)
		where (idCampEsp is not null)
		and (tipo is not null)
		and tipo = 1
		and fecha between @from and @to
		group by cam_descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end, c.descripcion
		union
		select ''ACD - '' + b.descripcion as [Espec/Camp], 
			case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) 
					else convert(varchar(13), fecha,121) + '':30:00'' end as Periodo,
			c.descripcion as [descriptionT], sum(tstatus) as T, c.descripcion as [descriptionN], count(*) as N
		from ccLogAgentesNotReady a
		left outer join ccinbound b on (idcampesp = inbound_id and tipo = 0)
		left outer join ccTipoNotReady c on (a.tiponotready_id = c.tiponotready_id)
		where (idCampEsp is not null)
		and (tipo is not null)
		and tipo = 0
		and fecha between @from and @to
		group by b.descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end, c.descripcion
		) as tmp
		where [Espec/Camp] is not null

		insert into RepSpecialTimes
		select a.Periodo as [date], a.cam_id as [campaignId], a.inbound_id as [inboundId], a.[Espec/Camp] as [campACDDescription], 
		[Tiempo Sesion] as [sessionTime], 
		[Tiempo Disponible]  as [readyTime], 
		[Tiempo Dialogo] as [dialogTime], 
		[Tiempo No Disponible] as [notReadyTime], 
		[Otro] as [other], 
		descriptionN as [descripcion],
		descriptionN + ''_Count'' as [descripcion_count], 
		[N] as [count],
		b.descriptionT + ''_Time'' as [descripcion_time], 
		[T] as [time],
		[T] as [timeSeconds]
		, datepart(yyyy,a.Periodo) as [year]
		, datepart(mm,a.Periodo) as [month]
		, datepart(dd,a.Periodo) as [day]
		, datepart(hh,a.Periodo) as [hour]
		, datepart(mi,a.Periodo) as [minutes]
		from #Report1 a
		left outer join #notready b on (a.[Espec/Camp] = b.[Espec/Camp] and a.Periodo = b.Periodo)
		where b.Periodo is not null
		union
		select a.Periodo, a.cam_id, a.inbound_id, a.[Espec/Camp], 
		[Tiempo Sesion] as [Tiempo Sesion], 
		[Tiempo Disponible] as [Tiempo Disponible], 
		[Tiempo Dialogo] as [Tiempo Dialogo], 
		[Tiempo No Disponible] as [Tiempo No Disponible], 
		[Otro] as [Otro], 
		@NotReady,
		@NotReady + ''_Count'', 0,
		@NotReady + ''_Time'', ''0'', 0
		, datepart(yyyy,a.Periodo) as [year]
		, datepart(mm,a.Periodo) as [month]
		, datepart(dd,a.Periodo) as [day]
		, datepart(hh,a.Periodo) as [hour]
		, datepart(mi,a.Periodo) as [minutes]
		from #Report1 a
		left outer join #notready b on (a.[Espec/Camp] = b.[Espec/Camp] and a.Periodo = b.Periodo)
		where b.Periodo is null
		order by a.[Espec/Camp], a.Periodo

		drop table #Report1
		drop table #notready
	end'
				
	EXEC(@Sql)
	
		set @process = 'ccspRepTrunkBusy - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepTrunkBusy]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
	
		create table #RtnValue(cal_id int,
		[user_id] int,
		fecha datetime,
		puerto int,
		cam_id int,
		tbusy int,
		contador int,
		tipo int,
		fechafin datetime,
		fechaInicio datetime,
		fechaFinal datetime)

		create nonclustered index ix_RtnValue on #RtnValue(
		[fecha] DESC,
		[fechafin] DESC
		)

		create nonclustered index ix_RtnValue2 on #RtnValue(
		[fechaInicio] DESC,
		[fechafinal] DESC
		)

		create table #RtnValue2(cal_id int,
		[user_id] int,
		fecha datetime,
		puerto int,
		cam_id int,
		tbusy int,
		contador int,
		tipo int,
		fechafin datetime,
		fechaInicio datetime,
		fechaFinal datetime)

		create nonclustered index ix_RtnValue on #RtnValue2(
		[fecha] DESC,
		[fechafin] DESC
		)

		insert into #RtnValue
			select dials.cal_id, calls.user_id, dials.fecha, dials.Puerto, dials.cam_id,
			sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)) as tBusy,1 as contador, 1 as tipo,
			dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha) as fechafin,
			case when datepart(mi,dials.fecha) between 0 and 14 then convert(varchar(13),dials.fecha,121) + '':00:00.000''
			when datepart(mi,dials.fecha) between 15 and 29 then convert(varchar(13),dials.fecha,121) + '':15:00.000''
			when datepart(mi,dials.fecha) between 30 and 44 then convert(varchar(13),dials.fecha,121) + '':30:00.000''
			when datepart(mi,dials.fecha) between 45 and 59 then convert(varchar(13),dials.fecha,121) + '':45:00.000'' end as fechaInicio,
			case when datepart(mi,dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha)) 
				between 0 and 14 then convert(varchar(13),dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha),121) + '':15:00.000''
			when datepart(mi,dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha)) 
				between 15 and 29 then convert(varchar(13),dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha),121) + '':30:00.000''
			when datepart(mi,dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha)) 
				between 30 and 44 then convert(varchar(13),dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha),121) + '':45:00.000''
			when datepart(mi,dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha)) 
				between 45 and 59 then convert(varchar(13),dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha),121) + '':00:00.000'' end as fechaFinal
			from ccologdials as dials left join ccocallsout as calls 
			on (dials.Puerto = calls.cal_puerto and dials.cal_id = calls.cal_id ) 
			where dials.fecha >= @from and dials.fecha < getdate()
			group by dials.cal_id, calls.user_id, dials.fecha, dials.Puerto, dials.cam_id 
		union all
			select incall.cal_id,incall.user_id,incall.cal_inicio as fecha,incall.cal_puerto as puerto, incall.inbound_id as cam_id, 
			sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)) as tBusy,1 as contador, 0 as tipo,
			dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio) as fechafin,
			case when datepart(mi,incall.cal_inicio) between 0 and 14 then convert(varchar(13),incall.cal_inicio,121) + '':00:00.000''
			when datepart(mi,incall.cal_inicio) between 15 and 29 then convert(varchar(13),incall.cal_inicio,121) + '':15:00.000''
			when datepart(mi,incall.cal_inicio) between 30 and 44 then convert(varchar(13),incall.cal_inicio,121) + '':30:00.000''
			when datepart(mi,incall.cal_inicio) between 45 and 59 then convert(varchar(13),incall.cal_inicio,121) + '':45:00.000'' end as fechaInicio,
			case when datepart(mi,dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio)) 
				between 0 and 14 then convert(varchar(13),dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio),121) + '':15:00.000''
			when datepart(mi,dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio)) 
				between 15 and 29 then convert(varchar(13),dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio),121) + '':30:00.000''
			when datepart(mi,dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio)) 
				between 30 and 44 then convert(varchar(13),dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio),121) + '':45:00.000''
			when datepart(mi,dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio)) 
				between 45 and 59 then dateadd(hh,1,(convert(varchar(13),dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio),121) + '':00:00.000'')) end
			from cccallsin as incall 
			where cal_inicio >= @from and cal_inicio < getdate()
			group by incall.cal_id, incall.user_id, incall.cal_inicio, incall.cal_puerto, incall.inbound_id  

		delete #RtnValue
		where tbusy = 0

		declare @starttime datetime
		declare @number int
		set @starttime = @from
		select @number = 0

		CREATE TABLE #times(
		[ID] INT primary key,
		[Start] DATETIME,
		[Stop] DATETIME
		)

		create nonclustered index ix_times on #times(
		[Start] DESC,
		[Stop] DESC
		)
		create nonclustered index ix_times2 on #times(
		[Start] DESC
		)

		while @number <= (datediff(mi,@starttime,getdate())/15)
		begin
			insert into #times
			SELECT [Hour] = @number,
			StartTime = DATEADD(mi, @number*15, @starttime),
			EndTime = DATEADD(mi, (@number+1)*15, @StartTime)

			set @number = @number +1
		end

		insert into #RtnValue2
		select *
		from #RtnValue
		where datediff(mi,fechainicio,fechafinal) > 15

		delete #RtnValue
		where datediff(mi,fechainicio,fechafinal) > 15

		insert into #RtnValue
		select cal_id, [user_id], th.start as fecha, t.Puerto, t.cam_id, 
			case when th.start < t.fecha then datediff(ss,fecha,th.stop) 
			when th.start > t.fecha and th.stop < t.fechafin then datediff(ss,th.start, th.stop) 
			else datediff(ss,th.start,fechafin) end as tBusy, 
		t.contador as llamadas, tipo, th.stop, th.start, th.stop
		from #RtnValue2 t
		join #times th on (t.fecha > th.Start and t.fecha < th.stop) OR th.Start between t.fecha and t.fechafin

		drop table #times
		drop table #RtnValue2

		select fecha as timegroup, puerto as port,cam_id,sum(tBusy) as tbusy,sum(contador) as llamadas,tipo
		into #ccGenOutPortStats
		from #RtnValue
		group by fecha, puerto, cam_id, tipo

		drop table #RtnValue
		
		delete from RepInTrunkBusy where date >= @from AND date < @to

		insert into RepInTrunkBusy
			select timegroup, #ccGenOutPortStats.cam_id, [in].descripcion, port, tbusy, llamadas,
			datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year],
			datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month],
			datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day],
			datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour],
			datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
			from #ccGenOutPortStats
			inner join ccInbound [in] on ([in].inbound_id = #ccGenOutPortStats.cam_id and #ccGenOutPortStats.tipo = 0)
			where timegroup >= @from and timegroup < @to
			
		delete from RepOutTrunkBusy where date >= @from AND date < @to

		insert into RepOutTrunkBusy
			select timegroup, #ccGenOutPortStats.cam_id, [out].cam_descripcion, port, tbusy, llamadas,
			datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year],
			datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month],
			datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day],
			datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour],
			datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
			from #ccGenOutPortStats
			inner join cccamps [out] on ([out].cam_id = #ccGenOutPortStats.cam_id and #ccGenOutPortStats.tipo = 1)
			where timegroup >= @from and timegroup < @to
		
		delete from RepTrunkBusy where date >= @from AND date < @to

		insert into RepTrunkBusy
			select timegroup, port, tbusy, llamadas,
			datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year],
			datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month],
			datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day],
			datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour],
			datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
			from #ccGenOutPortStats
			where timegroup >= @from and timegroup < @to
				
		drop table #ccGenOutPortStats 
	end'
					
	EXEC(@Sql)
	
		set @process = 'ccspRepCatalogos - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepCatalogos]
@type as tinyint,
@action tinyint = 0 -- 0 Filter select; 1 Filters Range 

AS
if @action = 0 
begin
	-- CAMPAIGNS
	if @type = 1 
	begin
		SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn 
		FROM ccCamps 
		GROUP BY cam_id, cam_descripcion
		ORDER BY cam_descripcion
	end

	-- DIAL RESULTS
	if @type = 2
	begin
		Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn 
		from ccTipoResultadoDial 
		order by descripcion
	end

	-- WORKGROUPS
	if @type = 3
	begin
		select idwg as id, wgname as description, ''workgroupId'' as dbColumn 
		from ccRIACat_WorkGroup 
		group by idwg, wgname
		order by wgname
	end

	-- AREAS
	if @type = 4
	begin
		select idArea as id, AreaName as description, ''areaId'' as dbColumn 
		from ccRIACat_Areas
		group by idArea, AreaName
		order by AreaName
	end

	-- DISPOSITIONS OUT
	if @type = 5
	begin
		SELECT calif_id as id, [description] as description, ''califId'' as dbColumn 
		FROM ccTipoCalifOut 
		order by [description]
	end

	-- USERS
	if @type = 6
	begin
		SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn 
		FROM ccUsers 
		WHERE [status] = 1 
		and TipoUser_id = 1		
		ORDER BY [login]
	end

	-- ACDS
	if @type = 7
	begin
		select inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
		from ccinbound 
		GROUP BY inbound_id, descripcion
		ORDER BY descripcion
	end

	-- DIDS
	if @type = 8
	begin
		select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
		from ccdnis	
		
	end

	--DISPOSITIONS
	if @type = 9
	begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn 
		FROM ccTipoCalif 
		order by [description]
	end

	--SUBDISPOSITIONS
	if @type = 10
	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn 
		FROM ccTipoCalifSub 
		order by [description]
	end

	--PROVIDER
	if @type = 11
	begin
		SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
		FROM cstoProvedor
		order by [description]
	end

	-- UNAVAILABLES
	if @type = 12
	begin
		SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn 
		FROM cctiponotready 
		order by descripcion
	end

	-- DIALERS
	if @type = 13
	begin
		SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn 
		FROM ccoDialers 
		order by descripcion
	end

	-- CallTYpes
	if @type = 14
	begin
			SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn 
			FROM ccStatusLlamada
		order by descripcion
	end
end

if @action = 1 
begin
	-- TRUNKS
	if @type = 13
	begin
		SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
	end
end'

	EXEC(@Sql)
	
		set @process = 'ccsp_RIAADMLoadSettings - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAADMLoadSettings]
@setting_id as tinyint = 0,
@type as tinyint = null,
@ip_admin as varchar(15)=''''
AS

declare @bremlog as tinyint
set nocount on
if @type is null
 begin
	IF @setting_id=0
 		select setting_id, valor, isnull(@bremlog,0) ip_host from ccsettings where Status=''1'' order by setting_id
	ELSE
		select setting_id, valor, isnull(@bremlog,0) ip_host from ccsettings where Status=''1'' and setting_id  = @setting_id
	return(0)
 end'

	EXEC(@Sql)

		set @process = 'ccspRepInDispositions - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepInDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInDispositions where date >= @from AND date < @to
	--select * from RepInCallsDetail
	--select top 10 * from cccallsin
	
	insert into RepInDispositions 
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),
		Inbound_id,'''' as ACDGroup, dispositionId, '''' as DispName,'''',
		count(dispositionId) DispAmount,user_id, '''' as login,'''' as username,IDArea, '''' as areaName,1 as wgId ,''Workgroup1'' as wg ,
		datepart(yyyy,max(dateHour)) as year, datepart(mm,max(dateHour)), datepart(dd,max(dateHour)),
		datepart(hh,max(dateHour)), 0
		FROM (
			SELECT 
				a.cal_inicio as dateHour, a.Inbound_id, a.calif_id as dispositionId, user_id, b.IDArea
				from cccallsin a 		
				left join ccInbound b
				on	b.Inbound_id = a.Inbound_id		
				where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13	--Constestada
--			UNION 
--			SELECT 		
--				requestDate,a.inboundId, a.disposition, a.userId, b.IDArea
--				FROM ccRIAChats a
--				left join ccInbound b
--				on	b.Inbound_id = a.inboundId
--				where requestDate >= @from AND requestDate < @to and a.chatStatus = 3 --Assigned		
	) as x group by CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),Inbound_id, dispositionId, user_id, IDArea
	
	update a set acdGroup = isnull(descripcion,'''')
	from RepInDispositions a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,''Dispositionless''), disposition_count = isnull(description,''Dispositionless'') + ''_Count''
	from RepInDispositions a
	left join cctipocalif b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
			
	EXEC(@Sql)

		set @process = 'ccspRepInSubDispositions - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepInSubDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInDispositions where date >= @from AND date < @to
	--select * from RepInCallsDetail
	--select top 10 * from cccallsin
	--select * from ccsettings

	insert into RepInSubDispositions 
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),
		Inbound_id,'''' as ACDGroup, subDispositionId, '''' as DispName, '''',
		count(dispositionId) DispAmount,user_id, '''' as login,'''' as username,IDArea, '''' as areaName,1 as wgId ,''Workgroup1'' as wg ,
		datepart(yyyy,max(dateHour)) as year, datepart(mm,max(dateHour)), datepart(dd,max(dateHour)),
		datepart(hh,max(dateHour)), 0
	 FROM 
	(
		select 
		cal_inicio as dateHour, a.Inbound_id,isnull(a.califSub_id,0) as subDispositionId, calif_id as dispositionId, user_id, b.IDArea
		from cccallsin a 		
		left join ccInbound b
		on	b.Inbound_id = a.Inbound_id		
		where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13
--		UNION 
--		SELECT 		
--			requestDate,a.inboundId, a.subDisposition, a.disposition, a.userId, b.IDArea
--			FROM ccRIAChats a
--			left join ccInbound b
--			on	b.Inbound_id = a.inboundId
--			where requestDate >= @from AND requestDate < @to and a.chatStatus = 3 --Assigned		
	) as x group by CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),Inbound_id, subDispositionId, user_id, IDArea

	update a set acdGroup = isnull(descripcion,'''')
	from RepInSubDispositions a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,''Dispositionless''), subDisposition_count = isnull(califSubDesc,''Dispositionless'') + ''_Count''
	from RepInSubDispositions a
	left join cctipocalifsub b 
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInSubDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
			
	EXEC(@Sql)

/**********************************************/
/*** JOBS PARA LA NUEVA VERSION DE REPORTES ***/
/**********************************************/

		set @process = 'ccspRepOutDialDetail - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepOutDialDetail]    Script Date: 09/10/2012 10:39:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/10/2012 10:39:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepOutDialDetail'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 09/10/2012 10:39:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [ccspRepOutDialDetail] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120910, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepOutCalls - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepOutCalls]    Script Date: 09/10/2012 10:39:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/10/2012 10:39:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepOutCalls'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 09/10/2012 10:39:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [ccspRepOutCalls] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120910, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)

		set @process = 'ccspAgentNotReady - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspAgentNotReady]    Script Date: 02/19/2013 10:45:21 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 02/19/2013 10:45:22 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspAgentNotReady'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 02/19/2013 10:45:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepAgentNotReady] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130219, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepAgentGI - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepAgentGI]    Script Date: 02/19/2013 10:41:11 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 02/19/2013 10:41:12 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepAgentGI'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 02/19/2013 10:41:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepAgentGI] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130215, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepAgentKPI - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepAgentKPI]    Script Date: 02/20/2013 12:48:59 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 02/20/2013 12:48:59 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepAgentKPI'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 02/20/2013 12:48:59 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepAgentKPI] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130220, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepAgentNotReadyDet - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepAgentNotReadyDet]    Script Date: 02/20/2013 08:28:42 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 02/20/2013 08:28:42 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepAgentNotReadyDet'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 02/20/2013 08:28:43 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepAgentNotReadyDet] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130220, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepAgentSession - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepAgentSession]    Script Date: 02/14/2013 14:19:53 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 02/14/2013 14:19:53 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepAgentSession'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 02/14/2013 14:19:53 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepAgentSession] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130213, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepInBill01900 - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepInBill01900]    Script Date: 03/26/2013 13:30:18 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 03/26/2013 13:30:18 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepInBill01900'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepInBill01900'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 03/26/2013 13:30:19 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepInBill01900] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130326, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepInCalls - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepInCalls]    Script Date: 03/22/2013 14:44:11 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 03/22/2013 14:44:11 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepInCalls'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepInCalls'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [[LoadInformationReport]    Script Date: 03/22/2013 14:44:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''[LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepInCalls] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130322, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepInDIDResume - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepInDIDResume]    Script Date: 04/01/2013 14:04:12 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/01/2013 14:04:12 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepInDIDResume'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepInDIDResume'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 04/01/2013 14:04:13 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepInDIDResume] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130401, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepInEffectiveness - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepInEffectiveness]    Script Date: 03/25/2013 17:30:17 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 03/25/2013 17:30:17 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepInEffectiveness'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepInEffectiveness'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 03/25/2013 17:30:18 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepInEffectiveness] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130325, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)	
	
		set @process = 'ccspRepInRejectedCalls - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepInRejectedCalls]    Script Date: 04/01/2013 15:25:44 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/01/2013 15:25:44 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepInRejectedCalls'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 04/01/2013 15:25:44 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [ccspRepInRejectedCalls] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120910, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
	IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepOutCalls - Create Job'
		set @Sql='USE [msdb]

/****** Object: Job [ccspRepOutCalls] Script Date: 09/10/2012 10:39:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object: JobCategory [[Uncategorized (Local)]]] Script Date: 09/10/2012 10:39:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N''ccspRepInCallsDetail'',
@enabled=1,
@notify_level_eventlog=0,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N''No description available.'',
@category_name=N''[Uncategorized (Local)]'',
@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object: Step [LoadInformationReport] Script Date: 09/10/2012 10:39:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N''TSQL'',
@command=N''EXEC ccspRepInCallsDetail 1'',
@database_name=N''ccReportsRia'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=10,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20120910,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepInDispositions - Create Job'
		set @Sql='USE [msdb]

/****** Object: Job ccspRepInDispositions Script Date: 09/10/2012 10:39:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object: JobCategory [[Uncategorized (Local)]]] Script Date: 09/10/2012 10:39:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N''ccspRepInDispositions'',
@enabled=1,
@notify_level_eventlog=0,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N''No description available.'',
@category_name=N''[Uncategorized (Local)]'',
@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object: Step [LoadInformationReport] Script Date: 09/10/2012 10:39:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N''TSQL'',
@command=N''EXEC ccspRepInDispositions 1'',
@database_name=N''ccReportsRia'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=10,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20120910,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepInNotTransferred - Create Job'
		set @Sql='USE [msdb]

/****** Object: Job ccspRepInNotTransferred Script Date: 09/10/2012 10:39:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object: JobCategory [[Uncategorized (Local)]]] Script Date: 09/10/2012 10:39:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N''ccspRepInNotTransferred'',
@enabled=1,
@notify_level_eventlog=0,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N''No description available.'',
@category_name=N''[Uncategorized (Local)]'',
@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object: Step [LoadInformationReport] Script Date: 09/10/2012 10:39:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N''TSQL'',
@command=N''EXEC ccspRepInNotTransferred 1'',
@database_name=N''ccReportsRia'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=10,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20120910,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepInSubDispositions - Create Job'
		set @Sql='USE [msdb]

/****** Object: Job ccspRepInSubDispositions Script Date: 09/10/2012 10:39:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object: JobCategory [[Uncategorized (Local)]]] Script Date: 09/10/2012 10:39:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N''ccspRepInSubDispositions'',
@enabled=1,
@notify_level_eventlog=0,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N''No description available.'',
@category_name=N''[Uncategorized (Local)]'',
@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object: Step [LoadInformationReport] Script Date: 09/10/2012 10:39:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N''TSQL'',
@command=N''EXEC ccspRepInSubDispositions 1'',
@database_name=N''ccReportsRia'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=10,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20120910,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepIVRGeneral - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepIVRGeneral]    Script Date: 04/24/2013 17:14:52 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/24/2013 17:14:52 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepIVRGeneral'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepIVRGeneral'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 04/24/2013 17:14:52 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepIVRGeneral] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130424, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepIVRByOptions - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepIVRByOptions]    Script Date: 04/25/2013 12:00:05 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/25/2013 12:00:05 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepIVRByOptions'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepIVRByOptions'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 04/25/2013 12:00:06 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepIVRByOptions] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130425, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallsDetail - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepOutCallsDetail]    Script Date: 04/22/2013 15:55:14 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/22/2013 15:55:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepOutCallsDetail'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepOutCallsDetail'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 04/22/2013 15:55:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [ccspRepOutCallsDetail] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130422, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallsByTelephone - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepOutCallsByTelephone]    Script Date: 04/23/2013 13:03:04 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/23/2013 13:03:04 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepOutCallsByTelephone'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepOutCallsByTelephone'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 04/23/2013 13:03:04 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [ccspRepOutCallsByTelephone] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130423, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallBacks - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepOutCallBacks]    Script Date: 04/24/2013 11:01:30 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/24/2013 11:01:30 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepOutCallBacks'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepOutCallBacks'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 04/24/2013 11:01:31 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepOutCallBacks] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130424, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepIVRDetail - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepIVRDetail]    Script Date: 04/24/2013 16:52:54 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/24/2013 16:52:54 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepIVRDetail'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepIVRDetail'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 04/24/2013 16:52:55 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec ccspRepIVRDetail 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130424, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepOutDials - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepOutDials]    Script Date: 04/23/2013 11:10:20 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/23/2013 11:10:20 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepOutDials'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepOutDials'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 04/23/2013 11:10:20 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec ccspRepOutDials 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130423, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepIVRFirstOption - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepIVRFirstOption]    Script Date: 03/26/2013 17:26:21 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 03/26/2013 17:26:21 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepIVRFirstOption'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepIVRFirstOption'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 03/26/2013 17:26:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepIVRFirstOption] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130326, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepInChangeFlow - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepInChangeFlow]    Script Date: 03/26/2013 17:26:21 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 03/26/2013 17:26:21 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepInChangeFlow'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepInChangeFlow'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 03/26/2013 17:26:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepInChangeFlow] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130326, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCalls - Create Job'
		set @Sql='USE [msdb]

/****** Object: Job [ccspRepOutCalls] Script Date: 09/10/2012 10:39:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object: JobCategory [[Uncategorized (Local)]]] Script Date: 09/10/2012 10:39:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N''ccspRepOutCallBilling'',
	@enabled=1,
	@notify_level_eventlog=0,
	@notify_level_email=0,
	@notify_level_netsend=0,
	@notify_level_page=0,
	@delete_level=0,
	@description=N''No description available.'',
	@category_name=N''[Uncategorized (Local)]'',
	@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object: Step [LoadInformationReport] Script Date: 09/10/2012 10:39:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'',
	@step_id=1,
	@cmdexec_success_code=0,
	@on_success_action=1,
	@on_success_step_id=0,
	@on_fail_action=2,
	@on_fail_step_id=0,
	@retry_attempts=0,
	@retry_interval=0,
	@os_run_priority=0, @subsystem=N''TSQL'',
	@command=N''EXEC [ccspRepOutCallBilling] 1'',
	@database_name=N''ccReportsRia'',
	@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'',
	@enabled=1,
	@freq_type=4,
	@freq_interval=1,
	@freq_subday_type=4,
	@freq_subday_interval=10,
	@freq_relative_interval=0,
	@freq_recurrence_factor=0,
	@active_start_date=20120910,
	@active_end_date=99991231,
	@active_start_time=0,
	@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
	IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepOutDispositions - Create Job'
		set @Sql='USE [msdb]

/****** Object: Job [ccspRepOutDispositions] Script Date: 09/10/2012 10:39:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object: JobCategory [[Uncategorized (Local)]]] Script Date: 09/10/2012 10:39:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N''ccspRepOutDispositions'',
@enabled=1,
@notify_level_eventlog=0,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N''No description available.'',
@category_name=N''[Uncategorized (Local)]'',
@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object: Step [LoadInformationReport] Script Date: 09/10/2012 10:39:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N''TSQL'',
@command=N''EXEC ccspRepOutDispositions 1'',
@database_name=N''ccReportsRia'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=10,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20120910,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepOutKPI - Create Job'
		set @Sql='USE [msdb]

/****** Object: Job [ccspRepOutKPI] Script Date: 09/10/2012 10:39:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object: JobCategory [[Uncategorized (Local)]]] Script Date: 09/10/2012 10:39:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N''ccspRepOutKPI'',
@enabled=1,
@notify_level_eventlog=0,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N''No description available.'',
@category_name=N''[Uncategorized (Local)]'',
@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object: Step [LoadInformationReport] Script Date: 09/10/2012 10:39:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N''TSQL'',
@command=N''EXEC ccspRepOutKPI 1'',
@database_name=N''ccReportsRia'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=10,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20120910,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepOutSubDispositions - Create Job'
		set @Sql='USE [msdb]

/****** Object: Job [ccspRepOutSubDispositions] Script Date: 09/10/2012 10:39:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object: JobCategory [[Uncategorized (Local)]]] Script Date: 09/10/2012 10:39:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N''ccspRepOutSubDispositions'',
@enabled=1,
@notify_level_eventlog=0,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N''No description available.'',
@category_name=N''[Uncategorized (Local)]'',
@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object: Step [LoadInformationReport] Script Date: 09/10/2012 10:39:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N''TSQL'',
@command=N''EXEC ccspRepOutSubDispositions 1'',
@database_name=N''ccReportsRia'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=10,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20120910,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)

		set @process = 'ccspRepTrunkBusy - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepTrunkBusy]    Script Date: 05/20/2013 16:17:56 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/20/2013 16:17:56 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepTrunkBusy'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 05/20/2013 16:17:56 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec ccspRepTrunkBusy 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130520, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

	EXEC(@Sql)

		set @process = 'ccspRepSpecialTimes - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepSpecialTimes]    Script Date: 05/21/2013 13:48:23 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/21/2013 13:48:23 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepSpecialTimes'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepSpecialTimes'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 05/21/2013 13:48:24 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [ccspRepSpecialTimes] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130521, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)

		set @process = 'migration - Create Table'
		set @sql = 'use [ccReportsRia]
CREATE TABLE [dbo].[migration](
[id] [int] NOT NULL,
[description] [varchar](255) NOT NULL,
[status] [bit] NOT NULL,
[error] [nvarchar](max) NOT NULL,
[dateStart] datetime NOT NULL,
[dateEnd] datetime NOT NULL
) ON [PRIMARY]
'
	
	EXEC(@Sql)

		set @process = 'migration - Insert'
		set @sql = 'use [ccReportsRia]
insert into migration values (1 , ''SnapShots Completed'', 0, '''', '''', '''')
insert into migration values (2 , ''ccspRepOutDialDetail'', 0, '''', '''', '''')
insert into migration values (3 , ''ccspRepOutCalls'', 0, '''', '''', '''')
insert into migration values (4 , ''ccspRepAgentGI'', 0, '''', '''', '''')
insert into migration values (5 , ''ccspRepAgentKPI'', 0, '''', '''', '''')
insert into migration values (6 , ''ccspRepAgentNotReady'', 0, '''', '''', '''')
insert into migration values (7 , ''ccspRepAgentNotReadyDet'', 0, '''', '''', '''')
insert into migration values (8 , ''ccspRepAgentSession'', 0, '''', '''', '''')
insert into migration values (9 , ''ccspRepInBill01900'', 0, '''', '''', '''')
insert into migration values (10 , ''ccspRepInCalls'', 0, '''', '''', '''')
insert into migration values (11 , ''ccspRepInDIDResume'', 0, '''', '''', '''')
insert into migration values (12 , ''ccspRepInEffectiveness'', 0, '''', '''', '''')
insert into migration values (13 , ''ccspRepInCallsDetail'', 0, '''', '''', '''')
insert into migration values (14 , ''ccspRepInNotTransferred'', 0, '''', '''', '''')
insert into migration values (15 , ''ccspRepInRejectedCalls'', 0, '''', '''', '''')
insert into migration values (16 , ''ccspRepOutCallBacks'', 0, '''', '''', '''')
insert into migration values (17 , ''ccspRepIVRGeneral'', 0, '''', '''', '''')
insert into migration values (18 , ''ccspRepIVRByOptions'', 0, '''', '''', '''')
insert into migration values (19 , ''ccspRepOutCallsDetail'', 0, '''', '''', '''')
insert into migration values (20 , ''ccspRepOutCallsByTelephone'', 0, '''', '''', '''')
insert into migration values (21 , ''ccspRepIVRDetail'', 0, '''', '''', '''')
insert into migration values (22 , ''ccspRepOutDials'', 0, '''', '''', '''')
insert into migration values (23 , ''ccspRepIVRFirstOption'', 0, '''', '''', '''')
insert into migration values (24 , ''ccspRepInChangeFlow'', 0, '''', '''', '''')
insert into migration values (25 , ''ccspRepOutCallBilling'', 0, '''', '''', '''')
insert into migration values (26 , ''ccspRepOutDispositions'', 0, '''', '''', '''')
insert into migration values (27 , ''ccspRepOutKPI'', 0, '''', '''', '''')
insert into migration values (28 , ''ccspRepOutSubDispositions'', 0, '''', '''', '''')
insert into migration values (29 , ''ccspRepSpecialTimes'', 0, '''', '''', '''')
insert into migration values (30 , ''ccspRepTrunkBusy'', 0, '''', '''', '''')
insert into migration values (31 , ''ccspRepInDispositions'', 0, '''', '''', '''')
insert into migration values (32 , ''ccspRepInSubDispositions'', 0, '''', '''', '''')
insert into migration values (33 , ''Migration Completed'', 0, '''', '''', '''')'
		
	EXEC(@Sql)

		set @process = 'ccSettings - Insert'
		set @sql ='insert into ccSettings values(27,''90'',''Dias Generacion Reportes'',1,''X'')'
	
	EXEC(@Sql)

		set @process = 'CW Reports Migration - Create Job'
		set @sql = 'USE [msdb]
/****** Object:  Job [CW Reports Migration]    Script Date: 06/20/2013 10:28:48 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 06/20/2013 10:28:48 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Reports Migration'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [migration]    Script Date: 06/20/2013 10:28:49 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Reports Migration'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''
if (select [status] from migration where id = 1) = 0
begin
	if (select count(distinct publication)	
	from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b 	
	where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%'''') = 17
	begin
		update migration with (rowlock) set [status] = 1, [dateStart] = getdate(), [dateEnd] = getdate() where id = 1
		update migration with (rowlock) set [status] = 1, [dateStart] = getdate() where id = 33
		
		declare @from as datetime
		declare @day as int 

		select @day = valor from ccReportsRia.dbo.ccSettings where setting_id = 27
		select @from = convert(datetime,convert(varchar(11),getdate() - @day))		
		
		BEGIN TRANSACTION ccspRepOutDialDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 2
			exec ccspRepOutDialDetail 1, @from  
			COMMIT TRANSACTION ccspRepOutDialDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutDialDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 2
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 2 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCalls;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 3
			exec ccspRepOutCalls 1,  @from
			COMMIT TRANSACTION ccspRepOutCalls;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCalls;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 3
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 3 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentGI;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 4
			exec ccspRepAgentGI 1,  @from
			COMMIT TRANSACTION ccspRepAgentGI;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentGI;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 4
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 4 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentKPI;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 5
			exec ccspRepAgentKPI 1,  @from
			COMMIT TRANSACTION ccspRepAgentKPI;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentKPI;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 5
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 5 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentNotReady;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 6
			exec ccspRepAgentNotReady 1,  @from
			COMMIT TRANSACTION ccspRepAgentNotReady;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentNotReady;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 6
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 6 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentNotReadyDet;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 7
			exec ccspRepAgentNotReadyDet 1,  @from
			COMMIT TRANSACTION ccspRepAgentNotReadyDet;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentNotReadyDet;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 7
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 7 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentSession;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 8
			exec ccspRepAgentSession 1,  @from
			COMMIT TRANSACTION ccspRepAgentSession;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentSession;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 8
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 8 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInBill01900;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 9
			exec ccspRepInBill01900 1,  @from
			COMMIT TRANSACTION ccspRepInBill01900;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInBill01900;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 9
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 9 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInCalls;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 10
			exec ccspRepInCalls 1,  @from
			COMMIT TRANSACTION ccspRepInCalls;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInCalls;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 10
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 10 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInDIDResume;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 11
			exec ccspRepInDIDResume 1,  @from
			COMMIT TRANSACTION ccspRepInDIDResume;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInDIDResume;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 11
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 11 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInEffectiveness;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 12
			exec ccspRepInEffectiveness 1,  @from
			COMMIT TRANSACTION ccspRepInEffectiveness;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInEffectiveness;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 12
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 12 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInCallsDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 13
			exec ccspRepInCallsDetail 1,  @from
			COMMIT TRANSACTION ccspRepInCallsDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInCallsDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 13
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 13 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInNotTransferred;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 14
			exec ccspRepInNotTransferred 1,  @from
			COMMIT TRANSACTION ccspRepInNotTransferred;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInNotTransferred;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 14
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 14 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInRejectedCalls;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 15
			exec ccspRepInRejectedCalls 1,  @from
			COMMIT TRANSACTION ccspRepInRejectedCalls;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInRejectedCalls;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 15
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 15 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCallBacks;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 16
			exec ccspRepOutCallBacks 1,  @from
			COMMIT TRANSACTION ccspRepOutCallBacks;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCallBacks;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 16
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 16 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepIVRGeneral;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 17
			exec ccspRepIVRGeneral 1,  @from
			COMMIT TRANSACTION ccspRepIVRGeneral;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepIVRGeneral;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 17
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 17 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepIVRByOptions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 18
			exec ccspRepIVRByOptions 1,  @from
			COMMIT TRANSACTION ccspRepIVRByOptions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepIVRByOptions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 18
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 18 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCallsDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 19
			exec ccspRepOutCallsDetail 1,  @from
			COMMIT TRANSACTION ccspRepOutCallsDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCallsDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 19
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 19 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCallsByTelephone;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 20
			exec ccspRepOutCallsByTelephone 1,  @from
			COMMIT TRANSACTION ccspRepOutCallsByTelephone;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCallsByTelephone;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 20
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 20 and [error] = ''''''''
	
		BEGIN TRANSACTION ccspRepIVRDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 21
			exec ccspRepIVRDetail 1,  @from
			COMMIT TRANSACTION ccspRepIVRDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepIVRDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 21
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 21 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutDials;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 22
			exec ccspRepOutDials 1,  @from
			COMMIT TRANSACTION ccspRepOutDials;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutDials;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 22
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 22 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepIVRFirstOption;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 23
			exec ccspRepIVRFirstOption 1,  @from
			COMMIT TRANSACTION ccspRepIVRFirstOption;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepIVRFirstOption;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 23
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 23 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInChangeFlow;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 24
			exec ccspRepInChangeFlow 1,  @from
			COMMIT TRANSACTION ccspRepInChangeFlow;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInChangeFlow;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 24
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 24 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCallBilling;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 25
			exec ccspRepOutCallBilling 1,  @from
			COMMIT TRANSACTION ccspRepOutCallBilling;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCallBilling;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 25
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 25 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutDispositions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 26
			exec ccspRepOutDispositions 1,  @from
			COMMIT TRANSACTION ccspRepOutDispositions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutDispositions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 26
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 26 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutKPI;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 27
			exec ccspRepOutKPI 1,  @from
			COMMIT TRANSACTION ccspRepOutKPI;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutKPI;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 27
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 27 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutSubDispositions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 28
			exec ccspRepOutSubDispositions 1,  @from
			COMMIT TRANSACTION ccspRepOutSubDispositions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutSubDispositions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 28
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 28 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepSpecialTimes;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 29
			exec ccspRepSpecialTimes 1,  @from
			COMMIT TRANSACTION ccspRepSpecialTimes;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepSpecialTimes;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 29
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 29 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepTrunkBusy;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 30
			exec ccspRepTrunkBusy 1,  @from
			COMMIT TRANSACTION ccspRepTrunkBusy;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepTrunkBusy;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 30
		END CATCH
						
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 30 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInDispositions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 31
			exec ccspRepInDispositions 1,  @from
			COMMIT TRANSACTION ccspRepInDispositions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInDispositions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 31
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 31 and [error] = ''''''''		

		BEGIN TRANSACTION ccspRepInSubDispositions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 32
			exec ccspRepInSubDispositions 1,  @from
			COMMIT TRANSACTION ccspRepInSubDispositions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInSubDispositions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 32
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 32 and [error] = ''''''''

		update migration with (rowlock) set [status] = 2, [dateEnd] = getdate() where id = 33 
	end
end'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''migration'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130620, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959 
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
	IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)

------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
