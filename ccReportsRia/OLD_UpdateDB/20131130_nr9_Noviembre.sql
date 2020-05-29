/*
Autor: Raymundo Gonzalez
Fecha: 2013/11/30
Descripcion:
	Se crean las tabla RIA_FORMACALIF para reportesAVRS
	Se crean las tabla RIA_RESULTADOSFORMA para reportesAVRS
	Se crean las tabla RIA_FORMATOS para reportesAVRS
	Se crean las tabla RIA_CONCEPTOS para reportesAVRS
	Se crean las tabla RIA_PREGUNTAS para reportesAVRS
	Se crean las tabla RIA_RESPUESTAS para reportesAVRS
	Se crean las tabla RIA_GRABACION para reportesAVRS
	Se crean las tabla RIA_GRABACIONCONSULTA  para reportesAVRS
	Se crea setting para obtener el servername de CCenteria		
	Se crean las tablas para nuevos reportes
	Se crean los indices para las nuevas tablas de reportes
	Se agrega la columna dnis a la tabla RepIVRDetail para reporte
	Se agrega la columna dnis a la tabla IVRCallsIn para reporte
	Se agrega la columna avgAbandon a la tabla RepInEffectiveness
	Se inserta registro en la tabla ccSettings para nuevos reportes y cambio replicas
	Se insertan registros en la tabla reportsfilters para nuevos reportes
	Se insertan registros en la tabla reportsfiltersmenus para nuevos reportes
	Se insertan registros en la tabla Reportscharts para nuevos reportes
	Se insertan registros en la tabla ReportsTotals para nuevos reportes
	Se insertan registros en la tabla TranslatedReports para nuevos reportes
	Se actualiza la tabla ReportsTotals para agregar nueva columna de porcentaje de abandono
	Se actualiza la tabla ccsettings para modificar valor y descripcion de proceso maestro de replicas y reportes
	Se crean los SPs para nuevos reportes
	Se modifica el SP ccspRepIVRDetail para mostrar nueva columna de dnis
	Se modifica el SP ccspRepInEffectiveness para mostrar nueva columna de porcentaje de abandono
	Se modifica el SP ReportsMasterProcess para control de replicas y reportes
	Se crean los jobs para nuevos reportes
	
Version requerida: 8
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '9'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'RIA_FORMACALIF - Create Table'
	set @Sql='
		IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''RIA_FORMACALIF'') BEGIN
			CREATE TABLE [dbo].[RIA_FORMACALIF](
	[id_forma] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[fecha_calif] [smalldatetime] NOT NULL,
	[id_calificador] [int] NOT NULL,
	[id_supervisor] [int] NOT NULL,
	[id_grabacion] [bigint] NOT NULL,
	[id_formato] [int] NOT NULL,
	[total_forma] [tinyint] NOT NULL,
	[age_id] [int] NOT NULL,
	[version] [int] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
 CONSTRAINT [PK_TREC_FORMACALIF] PRIMARY KEY CLUSTERED 
(
	[id_forma] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
	END'
	EXEC(@Sql)

	set @process = 'RIA_RESULTADOSFORMA - Create Table'
	set @Sql='
		IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''RIA_RESULTADOSFORMA'') BEGIN
			CREATE TABLE [dbo].[RIA_RESULTADOSFORMA](
	[id_forma] [int] NOT NULL,
	[id_pregunta] [int] NOT NULL,
	[id_respuesta] [int] NOT NULL,
	[peso] [int] NOT NULL,
	[etiquetas] [varchar](max) NOT NULL
) ON [PRIMARY]
	END'
	EXEC(@Sql)	
	
	set @process = 'RIA_FORMATOS - Create Table'
	set @Sql='IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''RIA_FORMATOS'') BEGIN		
CREATE TABLE [dbo].[RIA_FORMATOS](
	[id_formato] [int] NOT NULL,
	[nombre] [varchar](50) NOT NULL,
	[id_creador] [smallint] NOT NULL,
	[fecha_creado] [smalldatetime] NOT NULL,
	[activo] [bit] NOT NULL,
	[peso] [int] NOT NULL,
	[version] [int] NOT NULL,
 CONSTRAINT [PK_RIA_FORMATOS] PRIMARY KEY CLUSTERED 
(
	[id_formato] ASC,
	[version] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_PADDING OFF
ALTER TABLE [dbo].[RIA_FORMATOS] ADD  CONSTRAINT [fecha_formato]  DEFAULT (getdate()) FOR [fecha_creado]
ALTER TABLE [dbo].[RIA_FORMATOS] ADD  CONSTRAINT [activo_formato]  DEFAULT ((1)) FOR [activo]
ALTER TABLE [dbo].[RIA_FORMATOS] ADD  CONSTRAINT [DF_RIA_FORMATOS_version]  DEFAULT ((1)) FOR [version]
END'
	EXEC(@Sql)
	
	set @process = 'RIA_CONCEPTOS - Create Table'
	set @Sql='
		IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''RIA_CONCEPTOS'') BEGIN
	CREATE TABLE [dbo].[RIA_CONCEPTOS](
	[id_concepto] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[id_formato] [int] NOT NULL,
	[num_concepto] [int] NOT NULL,
	[con_descripcion] [varchar](80) NOT NULL,
	[version] [int] NOT NULL,
 CONSTRAINT [PK_RIA_CONCEPTOS] PRIMARY KEY CLUSTERED 
(
	[id_concepto] ASC,
	[version] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_PADDING OFF

ALTER TABLE [dbo].[RIA_CONCEPTOS] ADD  CONSTRAINT [DF_RIA_CONCEPTOS_version]  DEFAULT ((1)) FOR [version]
END'
	EXEC(@Sql)
	
	set @process = 'RIA_PREGUNTAS - Create Table'
	set @Sql='IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''RIA_PREGUNTAS'') BEGIN
	CREATE TABLE [dbo].[RIA_PREGUNTAS](
	[id_pregunta] [int] IDENTITY(1,1) NOT NULL,
	[id_concepto] [int] NOT NULL,
	[num_pregunta] [int] NOT NULL,
	[id_TipoPregunta] [int] NOT NULL,
	[enunciado_pregunta] [varchar](256) NOT NULL,
	[peso] [int] NOT NULL,
	[valor_inicial] [int] NULL,
	[incremento] [int] NULL,
 CONSTRAINT [PK_RIA_PREGUNTAS] PRIMARY KEY CLUSTERED 
(
	[id_pregunta] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END'
	EXEC(@Sql)

	set @process = 'RIA_RESPUESTAS - Create Table'
	set @Sql='IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''RIA_RESPUESTAS'') BEGIN
	CREATE TABLE [dbo].[RIA_RESPUESTAS](
	[id_respuesta] [int] IDENTITY(1,1) NOT NULL,
	[id_pregunta] [int] NOT NULL,
	[etiqueta] [varchar](120) NOT NULL,
	[peso] [int] NOT NULL
) ON [PRIMARY]
	END'
	EXEC(@Sql)

	set @process = 'RIA_GRABACION - Create Table'
	set @Sql='IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''RIA_GRABACION'') BEGIN
	
CREATE TABLE [dbo].[RIA_GRABACION](
	[grab_id] [bigint] IDENTITY(1,1) NOT NULL,
	[cli_id] [int] NULL,
	[age_id] [int] NULL,
	[puerto_id] [int] NULL,
	[tipo_grab_id] [tinyint] NULL,
	[age_id_rec] [int] NULL,
	[ffin] [datetime] NOT NULL,
	[finicio] [datetime] NOT NULL,
	[ani] [varchar](15) NOT NULL,
	[dni] [varchar](15) NULL,
	[tamano] [int] NULL,
	[duracion] [int] NULL,
	[pos_pc] [varchar](25) NULL,
	[extension] [varchar](25) NULL,
	[razon_id] [tinyint] NULL,
	[nombre_archivo] [varchar](20) NULL,
	[info1] [varchar](50) NULL,
	[info2] [varchar](50) NULL,
	[info3] [varchar](50) NULL,
	[info4] [varchar](50) NULL,
	[info5] [varchar](50) NULL,
	[id_repositorio] [tinyint] NULL,
	[id_nivel_grito] [int] NULL,
	[tipo_llamada] [smallint] NULL,
	[cam_id] [smallint] NULL,
	[calif_id] [smallint] NULL,
	[cal_id] [int] NULL,
	[cal_key] [varchar](20) NULL,
	[cal_manual] [tinyint] NULL,
	[cal_extension] [int] NULL,
	[cal_whoHung] [smallint] NULL,
	[cal_whoRec] [int] NULL,
	[id_plantilla] [smallint] NULL,
	[fvalida] [datetime] NULL,
	[fvalida2] [datetime] NULL,
	[borra_id] [bit] NULL,
	[cal_fcallback] [smalldatetime] NULL,
	[dni_id] [smallint] NULL,
	[extra_info] [varchar](50) NULL,
	[extra_info2] [varchar](50) NULL,
	[id_rep_video] [tinyint] NULL,
 CONSTRAINT [PK_RIA_GRABACION] PRIMARY KEY CLUSTERED 
(
	[grab_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_PADDING OFF
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [DF__TREC_GRAB__age_i__0425A276]  DEFAULT (NULL) FOR [age_id]
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [DF__TREC_GRAB__puert__0519C6AF]  DEFAULT ((0)) FOR [puerto_id]
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [DF_TREC_GRABACION_ffin]  DEFAULT (getdate()) FOR [ffin]
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [DF_TREC_GRABACION_finicio]  DEFAULT (getdate()) FOR [finicio]
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [DF_TREC_GRABACION_ani]  DEFAULT ('') FOR [ani]
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [DF_TREC_GRABACION_dni]  DEFAULT ('') FOR [dni]
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [DF__TREC_GRAB__taman__09DE7BCC]  DEFAULT ((0)) FOR [tamano]
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [DF__TREC_GRAB__durac__0AD2A005]  DEFAULT ((0)) FOR [duracion]
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [DF_RIA_GRABACION_pos_pc]  DEFAULT ('') FOR [pos_pc]
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [DF_TREC_GRABACION_nombre_archivo]  DEFAULT ('') FOR [nombre_archivo]
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [ceroCamp]  DEFAULT ((0)) FOR [calif_id]
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [DF_RIA_GRABACION_cal_manual]  DEFAULT ((0)) FOR [cal_manual]
ALTER TABLE [dbo].[RIA_GRABACION] ADD  CONSTRAINT [DF_RIA_GRABACION_cal_whoRec]  DEFAULT ((0)) FOR [cal_whoRec]
END'
	EXEC(@Sql)

	set @process = 'RIA_GRABACIONCONSULTA - Create Table'
	set @Sql='
		IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''RIA_GRABACIONCONSULTA'') BEGIN
 CREATE TABLE [dbo].[RIA_GRABACIONCONSULTA](
	[grab_id] [bigint] IDENTITY(1,1) NOT NULL,
	[cli_id] [int] NULL,
	[age_id] [int] NULL CONSTRAINT [DF__RIA_GRABA__age_i__7CD98669]  DEFAULT (NULL),
	[puerto_id] [int] NULL CONSTRAINT [DF__RIA_GRABA__puert__7DCDAAA2]  DEFAULT ((0)),
	[tipo_grab_id] [tinyint] NULL,
	[age_id_rec] [int] NULL,
	[ffin] [datetime] NOT NULL CONSTRAINT [DF__RIA_GRABAC__ffin__7EC1CEDB]  DEFAULT (getdate()),
	[finicio] [datetime] NOT NULL CONSTRAINT [DF__RIA_GRABA__finic__7FB5F314]  DEFAULT (getdate()),
	[ani] [varchar](15) NOT NULL CONSTRAINT [DF__RIA_GRABACI__ani__00AA174D]  DEFAULT (''''),
	[dni] [varchar](15) NULL CONSTRAINT [DF__RIA_GRABACI__dni__019E3B86]  DEFAULT (''''),
	[tamano] [int] NULL CONSTRAINT [DF__RIA_GRABA__taman__02925FBF]  DEFAULT ((0)),
	[duracion] [int] NULL CONSTRAINT [DF__RIA_GRABA__durac__038683F8]  DEFAULT ((0)),
	[pos_pc] [varchar](25) NULL,
	[extension] [varchar](25) NULL,
	[razon_id] [tinyint] NULL,
	[nombre_archivo] [varchar](20) NULL CONSTRAINT [DF__RIA_GRABA__nombr__047AA831]  DEFAULT (''''),
	[info1] [varchar](50) NULL,
	[info2] [varchar](50) NULL,
	[info3] [varchar](50) NULL,
	[info4] [varchar](50) NULL,
	[info5] [varchar](50) NULL,
	[id_repositorio] [tinyint] NULL,
	[id_nivel_grito] [int] NULL,
	[tipo_llamada] [smallint] NULL,
	[cam_id] [smallint] NULL,
	[calif_id] [smallint] NULL CONSTRAINT [DF__RIA_GRABA__calif__056ECC6A]  DEFAULT ((0)),
	[cal_id] [int] NULL,
	[cal_key] [varchar](20) NULL,
	[cal_manual] [tinyint] NULL,
	[cal_extension] [int] NULL,
	[cal_whoHung] [smallint] NULL,
	[cal_whoRec] [int] NULL CONSTRAINT [DF_RIA_GRABACIONCONSULTA_cal_whoRec]  DEFAULT ((0)),
	[id_plantilla] [smallint] NULL,
	[fvalida] [datetime] NULL,
	[fvalida2] [datetime] NULL,
	[borra_id] [bit] NULL,
	[cal_fcallback] [smalldatetime] NULL,
	[dni_id] [smallint] NULL,
	[extra_info] [varchar](50) NULL,
	[extra_info2] [varchar](50) NULL,
	[id_rep_video] [tinyint] NULL,
 CONSTRAINT [PK_TREC_GRABACIONCONSULTA] PRIMARY KEY CLUSTERED 
(
	[grab_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
	END'
	EXEC(@Sql)	

	set @process = 'Reports New Tables - Create Table'
	set @Sql='CREATE TABLE [dbo].[RepCallXfer](
	[date] datetime not null,
	callid int not null,
	CallTypes varchar(7) not null,
	Agent varchar(250) not null,
	xfertype varchar(25) not null,
	destination varchar(50) not null,
	timebeforexfer int not null,
	timeafterxfer int not null,
	startDate datetime not null,
	endDate datetime not null
) ON [PRIMARY]

CREATE TABLE [dbo].[RepInAbnd](
	[date] [datetime] NOT NULL,
	[areaId] [int] NOT NULL,
	[area] [varchar](255) NOT NULL,
	[workgroupId] [int] NOT NULL,
	[workgroup] [varchar](255) NOT NULL,
	[inboundId] [int] NOT NULL,
	[inbound] [varchar](255) NOT NULL,
	[amount] [smallint] NOT NULL,
	[time_max] [smallint] NOT NULL,
	[time_tot] [bigint] NOT NULL,
	[LT10] [smallint] NOT NULL,
	[LT20] [smallint] NOT NULL,
	[LT30] [smallint] NOT NULL,
	[LT40] [smallint] NOT NULL,
	[LT50] [smallint] NOT NULL,
	[LT60] [smallint] NOT NULL,
	[LT120] [smallint] NOT NULL,
	[LT180] [smallint] NOT NULL,
	[LT240] [smallint] NOT NULL,
	[LT300] [smallint] NOT NULL,
	[GT300] [smallint] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[RepInAnsw](
	[date] [datetime] NOT NULL,
	[areaId] [int] NOT NULL,
	[area] [varchar](255) NOT NULL,
	[workgroupId] [int] NOT NULL,
	[workgroup] [varchar](255) NOT NULL,
	[inboundId] [int] NOT NULL,
	[inbound] [varchar](255) NOT NULL,
	[amount] [smallint] NOT NULL,
	[time_max] [smallint] NOT NULL,
	[time_tot] [bigint] NOT NULL,
	[LT10] [smallint] NOT NULL,
	[LT20] [smallint] NOT NULL,
	[LT30] [smallint] NOT NULL,
	[LT40] [smallint] NOT NULL,
	[LT50] [smallint] NOT NULL,
	[LT60] [smallint] NOT NULL,
	[LT120] [smallint] NOT NULL,
	[LT180] [smallint] NOT NULL,
	[LT240] [smallint] NOT NULL,
	[LT300] [smallint] NOT NULL,
	[GT300] [smallint] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[RepOutAnswCalls](
	[date] datetime not null,
	campaignId int not null,
	campaign varchar(255) not null,
	[workgroupId] [int] NOT NULL,
	[workgroup] [varchar](255) NOT NULL,
	[areaId] [int] NOT NULL,
	[area] [varchar](255) NOT NULL,
	total int not null,
	asig_tl decimal(5,2) not null,
	asig_nc decimal(5,2) not null,
	Answered decimal(5,2) not null,
	assigned decimal(5,2) not null,
	abdn_sis decimal(5,2) not null
) ON [PRIMARY]

CREATE TABLE [dbo].[RepSpececialAbnd](
	[date] [datetime] NOT NULL,
	[campaignId] [int] NOT NULL,
	[inboundId] [int] NOT NULL,
	[campACDDescription] [varchar](255) NOT NULL,
	[total] smallint not null,
	[abandonedCalls] smallint not null,
	[abandonedCallsPctg] decimal(5,2) not null
) ON [PRIMARY]

CREATE TABLE [dbo].[RepSpececialAgent](
	[date] [datetime] NOT NULL,
	[userId] [int] NOT NULL,
	[user] [varchar](255) NOT NULL,
	[login] [varchar](20) NOT NULL,
	sessionTime int not null,
	loginTime datetime not null,
	logoutTime datetime not null,
	dialogTime int not null,
	ndTime int not null,
	callsOut smallint not null,
	callsIn smallint not null,
	abandonedCalls smallint not null,
	nanswer2 smallint not null,
	unrated smallint not null
) ON [PRIMARY]

CREATE TABLE [dbo].[RepSpececialAgtPerformance](
	[date] [datetime] NOT NULL,
	[userId] [int] NOT NULL,
	[user] [varchar](255) NOT NULL,
	[login] [varchar](20) NOT NULL,
	Answered smallint not null,
	promises smallint not null,
	promisesPctg decimal (5,2) not null,
	avgCallTime smallint not null,
	avgWrapupTime smallint not null
) ON [PRIMARY]

CREATE TABLE [dbo].[RepSpececialCamMovs](
	[date] [datetime] NOT NULL,
	campaignId int not null,
	campaign varchar(255) not null,
	[action] varchar(50) not null,
	[type] varchar(50) not null,
	[nnew] smallint not null,
	[ncallback] smallint not null,
	[Agents] smallint not null,	
	[user] [varchar](255) NOT NULL,
) ON [PRIMARY]

CREATE TABLE [dbo].[RepSpececialPromises](
	[date] [datetime] NOT NULL,
	[type] varchar(10) not null,
	[campaignId] [int] NOT NULL,
	[inboundId] [int] NOT NULL,
	[campACDDescription] [varchar](255) NOT NULL,
	promises smallint not null,
	total smallint not null,
	percentage smallint not null
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'Reports New Tables - Create Index'
		set @Sql = 'CREATE NONCLUSTERED INDEX [IX_RepCallXfer] ON [dbo].[RepCallXfer] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInAbnd] ON [dbo].[RepInAbnd] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInAnsw] ON [dbo].[RepInAnsw] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepOutAnswCalls] ON [dbo].[RepOutAnswCalls] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepSpececialAbnd] ON [dbo].[RepSpececialAbnd] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepSpececialAgent] ON [dbo].[RepSpececialAgent] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepSpececialAgtPerformance] ON [dbo].[RepSpececialAgtPerformance] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepSpececialCamMovs] ON [dbo].[RepSpececialCamMovs] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepSpececialPromises] ON [dbo].[RepSpececialPromises] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]'
		
	EXEC(@Sql)

		set @process = 'RepIVRDetail - Alter Table'
		set @Sql='ALTER TABLE dbo.RepIVRDetail 
ADD dnis varchar(50) DEFAULT '''' NOT NULL'
	
	EXEC(@Sql)
	
		set @process = 'IVRCallsIn - Alter Table'
		set @Sql='IF NOT EXISTS( SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = ''IVRCallsIn'' AND  COLUMN_NAME = ''dnis'') begin 
			ALTER TABLE dbo.IVRCallsIn ADD dnis varchar(50) DEFAULT '''' NOT NULL   
           end'
	
	EXEC(@Sql)
	
		set @process = 'RepInEffectiveness - Alter Table'
		set @Sql='ALTER TABLE RepInEffectiveness ADD avgAbandon decimal(5,2)'
		
	EXEC(@Sql)
	
		set @process = 'ccSettings - Insert'
		set @Sql = 'insert into ccSettings (setting_id,valor,descripcion,Status,Tipo) values (30, ''1|1'', ''CalifId destinada a promesa Inbound|Outbound'',1,''RPT'')
			insert into ccsettings(setting_id,valor,descripcion,Status,Tipo) values(31,'''',''HOSTNAME|IP CW'',1,''X'')
			insert into ccsettings(setting_id,valor,descripcion,Status,Tipo) values(32,'''',''HOSTNAME|IP AVRS'',1,''X'')'
	EXEC(@Sql)					
	
		set @process = 'reportsfilters - Insert'
		set @Sql = 'insert reportsfilters values (''Abandoned'',''areas'',3141)
insert reportsfilters values (''Abandoned'',''workgroups'',3141)
insert reportsfilters values (''Abandoned'',''acds'',3141)
insert reportsfilters values (''Answered'',''areas'',3142)
insert reportsfilters values (''Answered'',''workgroups'',3142)
insert reportsfilters values (''Answered'',''acds'',3142)
insert reportsfilters values (''Answered Calls by Status'',''areas'',4130)
insert reportsfilters values (''Answered Calls by Status'',''workgroups'',4130)
insert reportsfilters values (''Answered Calls by Status'',''campaigns'',4130)
insert reportsfilters values (''Abandon reports'',''acds'',7010)
insert reportsfilters values (''Abandon reports'',''campaigns'',7010)
insert reportsfilters values (''Agent summary'',''users'',7020)
insert reportsfilters values (''Performance per agent'',''users'',7050)
insert reportsfilters values (''Movements per campaign'',''campaigns'',7030)
insert reportsfilters values (''Promises per campaign'',''acds'',7040)
insert reportsfilters values (''Promises per campaign'',''campaigns'',7040)'
		
	EXEC(@Sql)
	
		set @process = 'reportsfiltersmenus - Insert'
		set @Sql='insert reportsfiltersmenus values (4120,''date'')
insert reportsfiltersmenus values (3141,''date'')
insert reportsfiltersmenus values (3141,''filterby'')
insert reportsfiltersmenus values (3141,''groupby'')
insert reportsfiltersmenus values (3142,''date'')
insert reportsfiltersmenus values (3142,''filterby'')
insert reportsfiltersmenus values (3142,''groupby'')
insert reportsfiltersmenus values (4130,''date'')
insert reportsfiltersmenus values (4130,''filterby'')
insert reportsfiltersmenus values (7010,''date'')
insert reportsfiltersmenus values (7010,''filterby'')
insert reportsfiltersmenus values (7020,''date'')
insert reportsfiltersmenus values (7020,''filterby'')
insert reportsfiltersmenus values (7050,''date'')
insert reportsfiltersmenus values (7050,''filterby'')
insert reportsfiltersmenus values (7030,''date'')
insert reportsfiltersmenus values (7030,''filterby'')
insert reportsfiltersmenus values (7040,''date'')
insert reportsfiltersmenus values (7040,''filterby'')'
		
	EXEC(@Sql)
	
		set @process = 'Reportscharts - Insert'
		set @Sql = 'insert Reportscharts ([id],[reportName],[chartType],[x1],[subX1],[x2],[subX2],[countColumn],[chartDescription],[isTime]) VALUES(3141,''Abandoned'',1,''ACDGroup'','''','''','''','''',''Abandoned per ACD Group'',0)
insert Reportscharts ([id],[reportName],[chartType],[x1],[subX1],[x2],[subX2],[countColumn],[chartDescription],[isTime]) VALUES(3141,''Abandoned'',2,''year|month|day'',''ACDGroup'','''','''','''',''Abandoned per ACD Group by day'',0)
insert Reportscharts ([id],[reportName],[chartType],[x1],[subX1],[x2],[subX2],[countColumn],[chartDescription],[isTime]) VALUES(3142,''Answered'',1,''ACDGroup'','''','''','''','''',''Answered per ACD Group'',0)
insert Reportscharts ([id],[reportName],[chartType],[x1],[subX1],[x2],[subX2],[countColumn],[chartDescription],[isTime]) VALUES(3142,''Answered'',2,''year|month|day'',''ACDGroup'','''','''','''',''Answered per ACD Group by day'',0)'
		
	EXEC(@Sql)
	
		set @process = 'ReportsTotals - Insert'
		set @Sql = 'insert ReportsTotals values (3141,''sum:amount|avg:time_max|avg:time_tot|sum:LT10|sum:LT20|sum:LT30|sum:LT40|sum:LT50|sum:LT60|sum:LT120|sum:LT180|sum:LT240|sum:LT300|sum:GT300'')
insert ReportsTotals values (3142,''sum:amount|avg:time_max|avg:time_tot|sum:LT10|sum:LT20|sum:LT30|sum:LT40|sum:LT50|sum:LT60|sum:LT120|sum:LT180|sum:LT240|sum:LT300|sum:GT300'')
insert ReportsTotals values (4130,''sum:total|avg:asig_tl|avg:asig_nc|avg:Answered|avg:assigned|avg:abdn_sis'')
insert ReportsTotals values (7010,''sum:total|sum:abandoned|avg:percent_abandoned'')
insert ReportsTotals values (7040,''sum:promises|sum:total|avg:percentage'')
insert ReportsTotals values (7030,'''')
insert ReportsTotals values (7050,'''')
insert ReportsTotals values (7020,'''')
insert into ReportsTotals values (4120,'''')'
		
	EXEC(@Sql)
	
		set @process = 'TranslatedReports -Insert'
		set @Sql = 'insert into [TranslatedReports] values (7040, ''type'')
insert into [TranslatedReports] values (7030, ''action|type|user'')
insert into [TranslatedReports] values (4120, ''CallTypes|Agent|xfertype|destination'')'

	EXEC(@Sql)

		set @process = 'ReportsTotals - Update'
		set @Sql='update ReportsTotals 
set TotalColumns = ''sum:ntotalin|sum:nanswer2|sum:nabnd|special:tatencion:isnull(sum(tatencion*nanswer2)/nullif(sum(nanswer2),0),0)|sum:tqueavg|sum:tQuetot|sum:nQuetot|sum:avgAbandonTime|sum:tresp|avg:poscount|special:Porcentaje:ISNULL(SUM(SLP1) * 100/ NULLIF(SUM(SLP2)_ 0)_ 0)|special:avgAbandon:convert(decimal(5,2),(sum(nabnd)/nullif(convert(decimal(5,2),sum(ntotalin)),0))*100)'' 
WHERE Id=3060'
		
	EXEC(@Sql)
	
		set @process = 'ccsettings - Update'
		set @Sql = 'update ccsettings
set valor = ''5|5'', descripcion = ''Min. replicas | Min. reportes (Total 10 Minutos)''
where setting_id = 28'
		
	EXEC(@Sql)
	
		set @process = 'New Reports - Create Procedure 1'
		set @Sql='CREATE PROCEDURE ccspRepCallXfer
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()

	delete RepCallXfer with(rowlock)
	where [date] between @from and @to
	
	insert RepCallXfer select convert(varchar(10),fechafin,121) [date],
	clt.cal_id callid, case when tipo = 1 then ''systemTranslated_inbound'' else ''systemTranslated_outbound'' end CallTypes, 
	isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccusers nolock where user_id = 
	(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') Agent,
	case when modo = 0 then ''systemTranslated_blindXfer'' 
	when modo = 1 then ''systemTranslated_Agent'' 
	when modo = 2 then ''systemTranslated_acd'' 
	when modo = 3 then ''systemTranslated_conference'' 
	when modo = 4 then ''systemTranslated_supXfer'' 
	when modo = 5 then ''systemTranslated_overflow'' end as xfertype,
	case when modo = 0 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
	when modo = 1 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),''systemTranslated_Indefinite'') 
	when modo = 2 then isnull((select descripcion from ccinbound where inbound_id = clt.destino),''systemTranslated_Indefinite'') 
	when modo = 3 then isnull((select nombre from telefonosConferencia where tel = clt.destino),clt.destino) 
	when modo = 4 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
	when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end destination,
	tantesxfer timebeforexfer,
	tdespuesxfer timeafterxfer,
	dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate,
	fechafin as endDate
	from cclogtransfers clt left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=1 left join 
	cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=0
	WHERE fechafin >= @from and fechafin < @to
end'

	EXEC(@Sql)

		set @process = 'New Reports - Create Procedure 2'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccspRepInAbnd]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()
		
	declare @number int	
	
	CREATE TABLE #times(
      [ID] INT primary key,
      [Start] DATETIME,
      [Stop] DATETIME
      )
 
      create nonclustered index ix_times on #times(
      [Start] DESC,
      [Stop] DESC
      )
      create nonclustered index ix_times2 on #times([Start] DESC)
 
	select @number = 0
    while @number <= (datediff(mi,@from,@to)/15)
    begin
		insert into #times
		SELECT [Hour] = @number,
		StartTime = DATEADD(mi, @number*15, @from),
		EndTime = DATEADD(mi, (@number+1)*15, @from)
		set @number = @number +1
    end

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
	 FROM	(
			SELECT start timegroup
				, cal_inicio
				, inbound_id				
				, statuscall_id
				, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
				, (cal_twait + cal_txfer + cal_tring) AS tAbnd
			 FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock)
				JOIN #times th on cal_inicio between Start and [Stop]
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

	EXEC(@Sql)

		set @process = 'New Reports - Create Procedure 3'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccspRepInAnsw]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
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
	
	CREATE TABLE #times(
      [ID] INT primary key,
      [Start] DATETIME,
      [Stop] DATETIME
      )
 
      create nonclustered index ix_times on #times(
      [Start] DESC,
      [Stop] DESC
      )
      create nonclustered index ix_times2 on #times([Start] DESC)
 
	select @number = 0
    while @number <= (datediff(mi,@from,@to)/15)
    begin
		insert into #times
		SELECT [Hour] = @number,
		StartTime = DATEADD(mi, @number*15, @from),
		EndTime = DATEADD(mi, (@number+1)*15, @from)
		set @number = @number +1
    end

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
	 FROM	(
			SELECT start timegroup
				, cal_inicio
				, inbound_id				
				, statuscall_id
				, (CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
				, (cal_twait + cal_txfer + cal_tring) AS tAnsw
			 FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock)
				JOIN #times th on cal_inicio between Start and [Stop]
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

	EXEC(@Sql)

		set @process = 'New Reports - Create Procedure 4'
		set @Sql = 'CREATE PROCEDURE ccspRepOutAnswCalls
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()
		
	delete RepOutAnswCalls with(rowlock)
	where [date] between @from and @to
	
	insert RepOutAnswCalls select [date], campaignId, ca.cam_descripcion campaign, 
	abnd.IDWG workgroupId, e.WGName workgroup, f.IDArea areaId, g.AreaName area, total,
	cast(((nasig_tl*100.0)/total) as decimal(5,2)) asig_tl,
	cast(((nasig_nc*100.0)/total) as decimal(5,2)) asig_nc,
	cast(((nAnswered*100.0)/total) as decimal(5,2)) Answered,
	cast(((nassigned*100.0)/total) as decimal(5,2)) assigned,
	cast(((nabdn_sis*100.0)/total) as decimal(5,2)) abdn_sis
	from (
		select convert(varchar(10),cal_inicio,121) [date], co.cam_id campaignId, min(d.IDWG) idwg, count(*) total, 
		COUNT(CASE WHEN(statusCall_id = 16)THEN co.cal_id ELSE NULL END) nasig_tl,
		COUNT(CASE WHEN(statuscall_id = 15)THEN co.cal_id ELSE NULL END) nasig_nc,
		COUNT(CASE WHEN(statuscall_id = 13)THEN co.cal_id ELSE NULL END) nAnswered,
		COUNT(CASE WHEN(statuscall_id = 11)THEN co.cal_id ELSE NULL END) nassigned,
		COUNT(CASE WHEN(statuscall_id in (6,4))THEN co.cal_id ELSE NULL END) nabdn_sis
		from ccocallsout co with(index(IX_ccoCallsOut_2),nolock) 
		left join ccRIAWorkGroup_Calid d on (d.cal_id = co.cal_id)
		where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121),co.cam_id
    ) abnd left join cccamps ca on ca.cam_id=abnd.campaignId 
    left join ccRIACat_WorkGroup as e on (e.idwg = abnd.idwg)
	left join ccRIAAreaWorkGroup as f on (f.idwg = e.idwg)
	left join ccRIACat_Areas as g on (g.idarea = f.idarea)
end'

	EXEC(@Sql)

		set @process = 'New Reports - Create Procedure 5'
		set @Sql = 'CREATE PROCEDURE ccspRepSpececialAbnd
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

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
		COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) abandonedCalls
		from cccallsin ci with(index(IX_ccCallsIn),nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id 
		where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, ''ACD - '' + descripcion
		union all
		select convert(varchar(10),cal_inicio,121) [date], co.cam_id campaignId, 0 inboundId, 
		''Camp - '' + cam_descripcion [Espec/Camp], count(*) total, 
		COUNT(CASE WHEN(statuscall_id in(11,15,16))THEN cal_id ELSE NULL END) abandonedCalls
		from ccocallsout co with(index(IX_ccoCallsOut_2),nolock) left join cccamps ca on ca.cam_id=co.cam_id 
		where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), co.cam_id, ''Camp - '' + cam_descripcion
    ) abnd
end'

	EXEC(@Sql)

		set @process = 'New Reports - Create Procedure 6'
		set @Sql = 'CREATE PROCEDURE ccspRepSpececialAgent
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()
		
	DECLARE @tresRing AS smallint
	DECLARE @tresDialog AS smallint
	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog

	delete RepSpececialAgent with(rowlock) 
	where [date] between @from and @to
	
	insert RepSpececialAgent select ses.date,ses.userId,[user],login
	,[session] sessionTime,loginTime,logoutTime
	,isnull(cout.dialog,0)+isnull(cin.dialog,0)+isnull(cin.wrapup,0)+isnull(cout.wrapup,0) dialogTime 
	,nd.total ndTime
	,ISNULL(cout.ncalls,0) callsOut
	,ISNULL(cin.ncalls,0) callsIn
	,ISNULL(cout.abnd_xfer,0)+ISNULL(cout.abnd_ring,0)+ISNULL(cout.abnd_dialog,0)+ISNULL(cin.abnd_xfer,0)+ISNULL(cin.abnd_ring,0)+ISNULL(cin.abnd_dialog,0) abandonedCalls
	,ISNULL(cout.answer,0)+ISNULL(cin.answer,0) nanswer2
	,ISNULL(cout.nocalif,0)+ISNULL(cin.nocalif,0) unrated
	from 
	(select convert(varchar(10),[date],121) [date], login, userid, [user], 
	sum(sessionTimeSeconds) [session], 
	min(logintime) loginTime, max(logouttime) logoutTime
	from RepAgentsession where [date] between @from and @to group by convert(varchar(10),[date],121), login, userId, [user]) ses left join 
	(select convert(varchar(10),[date],121) [date], userId,SUM(timeseconds) total from RepAgentNotReady
	where [date] between @from and @to group by convert(varchar(10),[date],121), userId) nd on nd.date=ses.date and nd.userId=ses.userId left join 
	(select 
	CONVERT(varchar(10),cal_inicio,121) [date], USER_ID
	,SUM(cal_tdialog) dialog, SUM(cal_tnotas) wrapup
	,COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END)AS ncalls
	,COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer
	,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END)AS answer
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog)AND ISNULL(calif_id,0)=0) THEN cal_id ELSE NULL END)AS nocalif
	from ccoCallsOut with(index(IX_ccoCallsOut_2),nolock) where cal_inicio between @from and @to and cal_manual in(0,2)
	group by CONVERT(varchar(10),cal_inicio,121),USER_ID) cout on cout.date=ses.date and cout.User_id = ses.userId left join 
	(select
	CONVERT(varchar(10),cal_inicio,121) [date], USER_ID
	,SUM(cal_tdialog) dialog, SUM(cal_tnotas) wrapup
	,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND (isnull(cal_xfer,''1900-01-01 00:00:00'') <> ''1900-01-01 00:00:00'')))THEN 1 ELSE NULL END)AS ncalls
	,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
	,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog)AND ISNULL(calif_id,0)=0) THEN cal_id ELSE NULL END)AS nocalif
	from ccCallsIn with(index(IX_ccCallsIn),nolock) where cal_inicio between @from and @to
	group by CONVERT(varchar(10),cal_inicio,121),USER_ID) cin on cin.date = ses.date and cin.User_id=ses.userId
end'

	EXEC(@Sql)

		set @process = 'New Reports - Create Procedure 7'
		set @Sql = 'CREATE PROCEDURE ccspRepSpececialAgtPerformance
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
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
	
	delete RepSpececialAgent with(rowlock)
	where [date] between @from and @to

	insert RepSpececialAgtPerformance select [date],rcalls.USER_ID [userId]
	,us.apellidopaterno + '' '' + us.apellidomaterno + '' '' + nombres [user],login [Agent]
	,answer Answered, promises, promisesPctg, dialog avgCallTime, wrapup avgWrapupTime
	from (
	select [date], user_id, SUM(answer) answer, SUM(promises) promises
	,cast(SUM(promises)*100.0/SUM(answer) as decimal(5,2)) promisesPctg
	,sum(dialog)/SUM(answer) dialog, sum(wrapup)/SUM(answer) wrapup
	from (
	select 
	CONVERT(varchar(10),cal_inicio,121) [date], user_id
	,sum(cal_tdialog) dialog, sum(cal_tnotas) wrapup
	,count(case calif_id when @promesa then 1 else null end) promises
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END) answer
	from ccoCallsOut with(index(IX_ccoCallsOut_2),nolock) where cal_inicio between @from and @to and cal_manual in(0,2) and USER_ID>0
	group by CONVERT(varchar(10),cal_inicio,121),user_id
	union all
	select
	CONVERT(varchar(10),cal_inicio,121) [date], user_id
	,sum(cal_tdialog) dialog, sum(cal_tnotas) wrapup
	,count(case calif_id when @promesainb then 1 else null end) promises
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END) answer
	from ccCallsIn with(index(IX_ccCallsIn),nolock) where cal_inicio between @from and @to  and USER_ID>0
	group by CONVERT(varchar(10),cal_inicio,121),user_id) calls group by [date],user_id) rcalls 
	left join ccusers us on us.user_id=rcalls.user_id
end'

	EXEC(@Sql)

		set @process = 'New Reports - Create Procedure 8'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccspRepSpececialCamMovs]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()

	delete RepSpececialCamMovs with(rowlock)
	where [date] between @from and @to

	insert RepSpececialCamMovs
	SELECT movs.fecha as [date], movs.cam_id campaignId, camp.cam_descripcion campaign, 
	CASE movs.TipoMov
	WHEN 0 THEN ''systemTranslated_Stop''
	WHEN 1 THEN ''systemTranslated_Start''
	WHEN 2 THEN ''systemTranslated_newRecords''
	WHEN 3 THEN ''systemTranslated_jobNew''
	WHEN 4 THEN ''systemTranslated_jobCB''
	WHEN 5 THEN ''systemTranslated_Delete''
	WHEN 6 THEN ''systemTranslated_jobBoth''
	END AS [action],
	CASE WHEN movs.prevMovs = 0 THEN ''systemTranslated_jobNew''
	WHEN movs.prevMovs = 1 THEN ''systemTranslated_jobCB''
	WHEN movs.prevMovs = 2 THEN ''systemTranslated_jobBoth''
	WHEN movs.prevMovs IS NULL THEN ''systemTranslated_noType''
	END AS [type],
	movs.NewRecords AS nnew, movs.CBRecords AS ncallback,
	CASE WHEN movs.cant_agent IS NULL THEN 0 ELSE movs.cant_agent END AS Agents,
	CASE WHEN movs.user_id IS NULL THEN ''systemTranslated_NoName''
	WHEN movs.user_id = 0 THEN ''systemTranslated_NoName''
	ELSE usr.Nombres+'' ''+ISNULL(usr.ApellidoPaterno,'''')+'' ''+ISNULL(usr.ApellidoMaterno,'''')
	END AS [user]
	FROM ccCampsMovs as movs JOIN ccCamps as camp ON movs.cam_id = camp.cam_id 
	LEFT OUTER JOIN ccUsers AS usr ON movs.user_id = usr.user_id
	WHERE movs.fecha BETWEEN @from AND @to
end'

	EXEC(@Sql)

		set @process = 'New Reports - Create Procedure 9'
		set @Sql = 'CREATE PROCEDURE ccspRepSpececialPromises
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()

	DECLARE @data varchar(10), @promesa INT, @promesainb INT
	select @data = isnull(valor,''1|1'') from ccSettings where setting_id = 30
	SELECT @promesainb = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 1
	SELECT @promesa = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 2

	delete RepSpececialPromises with(rowlock)
	where [date] between @from and @to
	
	insert RepSpececialPromises SELECT convert(varchar(10),[date],121) [date], ''systemTranslated_outbound'' [type],
	cout.campaignId campaignId, 0 inboundId,
	camp.cam_descripcion [campACDDescription],
	ISNULL(SUM(CASE cout.dispositionId WHEN @promesa THEN cout.count ELSE 0 END),0) AS promises,
	ISNULL(SUM(cout.count),0) AS total,
	CASE ISNULL(SUM(cout.count),0) WHEN 0 THEN 0 ELSE  
	CONVERT(decimal,ISNULL(SUM(CASE cout.dispositionId WHEN @promesa THEN cout.count ELSE 0 END),0))/ 
	CONVERT(decimal,ISNULL(SUM(cout.count),0)) END AS percentage 
	FROM RepOutDispositions as cout JOIN ccCamps as camp ON camp.cam_id = cout.campaignId 
	WHERE cout.date BETWEEN @from AND @to GROUP BY convert(varchar(10),[date],121), cout.campaignId, camp.cam_descripcion
	union all
	SELECT convert(varchar(10),[date],121) [date], ''systemTranslated_inbound'' [type],
	0 campaignId, cin.inboundId inboundId,
	espe.descripcion [campACDDescription],
	ISNULL(SUM(CASE cin.dispositionId WHEN @promesainb THEN cin.count ELSE 0 END),0) AS promises,
	ISNULL(SUM(cin.count),0) AS TOTAL,
	CASE ISNULL(SUM(cin.count),0) WHEN 0 THEN 0 ELSE
	CONVERT(decimal,ISNULL(SUM(CASE cin.dispositionId WHEN @promesainb THEN cin.count ELSE 0 END),0))/ 
	CONVERT(decimal,ISNULL(SUM(cin.count),0)) END AS percentage
	FROM RepInDispositions as cin JOIN ccInbound as espe ON espe.inbound_id = cin.inboundId
	WHERE cin.date BETWEEN @from AND @to GROUP BY convert(varchar(10),[date],121), cin.inboundId, espe.descripcion
end'
		
	EXEC(@Sql)

		set @process = 'ccspRepIVRDetail - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepIVRDetail]
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
	,isnull(B.cal_id,0) as [cal_id],A.date,A.dnis
	into #IVRLlamadas
	from IVRCallsIn as A 
	left join ccCallsIn As B on  A.IVR_id = B.IVR_id 
	where date >= @from and date < @to
		
	delete from RepIVRDetail with(rowlock)
	where date >= @from AND date < @to
		
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
			datepart(mi,[date]),
			dnis as DNIS
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
		
		set @process = 'ccspRepInEffectiveness - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspRepInEffectiveness]
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
,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(isnull(cal_xfer,'''') = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd 
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
	, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,'''') = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
	, (cal_twait + cal_txfer + cal_tring) AS tAbnd
 FROM ccCallsIn
	WHERE cal_inicio >= @from AND  cal_inicio < @to
	AND INBOUND_ID > 0
) xCalls
WHERE (abnd IS NOT NULL) 
GROUP BY timegroup, inbound_id

--Borrar lo que esta para no repetir
delete from RepInEffectiveness with(rowlock)
where date >= @from AND date < @to

insert into RepInEffectiveness
SELECT timegroup as date, xDetail.inbound_id, isnull(descripcion, ''systemTranslated_NoACDGroup'') descripcion , ntotal, nanswer, nabnd , isnull(tatention / nullif(nanswer,0),0), 
tque_avg as tqueavg, tQue_tot as tQuetot, nQue_tot as nQuetot, isnull(tabnd_tot / NULLIF(nabnd,0),0) as tabndtot, SL_P_1 as SLP1, SL_P_2 as SLP2, tresp, 
/*pos_tot as postot,*/ pos_count as poscount, ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0)  as Porcentaje
, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes] 
, convert(decimal(5,2),(nabnd/nullif(convert(decimal(5,2),ntotal),0))*100) as [avgAbandon]
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
	
		set @process = 'ReportsMasterProcess - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ReportsMasterProcess] as

declare @dateStart datetime
declare @delay int
declare @strDelay nvarchar(8)
declare @reportName nvarchar(100)
declare @replicationName nvarchar(100)
declare @numOfReports int
declare @numOfReplications int
declare @repDelay int
declare @repStrDelay nvarchar(8)
declare @minReplication int
declare @minReports int

set nocount on

set @dateStart = getdate()
set @delay = 0
set @strDelay = ''''
set @reportName = ''''
set @replicationName = ''''
set @numOfReports = 0
set @numOfReplications = 0
set @repDelay = 0
set @repStrDelay = ''''
set @minReplication = 0
set @minReports = 0

select @minReplication = cast(substring(valor, 0, charindex(''|'',valor)) as int)
from ccsettings
where setting_id = 28

select @minReports = cast(substring(valor, charindex(''|'',valor) + 1, len(valor)) as int)
from ccsettings
where setting_id = 28

if (@minReplication + @minReports) <> 10
begin
	set @minReplication = 300
	set @minReports = 300
end
else
begin
	set @minReplication = @minReplication * 60
	set @minReports = @minReports * 60
end

create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select [name], 0 as flag
from msdb.dbo.sysjobs
where [name] like ''%ccReportsRia- 0%''
and [name] like ''%CCenterRia%''
order by [name]

select @numOfReplications = count(*)
from #replications with(nolock)

set @repDelay = floor(cast(@minReplication as decimal) / cast(@numOfReplications as decimal))

set @repStrDelay = STUFF(STUFF(REPLICATE(''0'',6-LEN(@repDelay)) + convert(VARCHAR(6),@repDelay),3,0,'':''),6,0,'':'')

while(select count(*) from #replications with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @replicationName

	update #replications with(rowlock)
	set flag = 1
	where [name] = @replicationName

	waitfor delay @repStrDelay
end

drop table #replications

declare @avrsIntegration int
set @avrsIntegration = (select valor from ccSettings where setting_id = 29) 

create table #reports ([name] nvarchar(100), flag bit)

insert into #reports
select [name], 0 as flag
from msdb.dbo.sysjobs
where ([name] like ''ccsp%'' and [name] not like ''ccspRepAVRS%'')
or ([name] like ''ccspRepAVRS%'' and @avrsIntegration = 1)
order by [name]

select @numOfReports = count(*)
from #reports with(nolock)

set @delay = floor(cast(@minReports as decimal) / cast(@numOfReports as decimal))

set @strDelay = STUFF(STUFF(REPLICATE(''0'',6-LEN(@delay)) + convert(VARCHAR(6),@delay),3,0,'':''),6,0,'':'')

while(select count(*) from #reports with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @reportName = [name]
		from #reports with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @reportName

	update #reports with(rowlock)
	set flag = 1
	where [name] = @reportName

	waitfor delay @strDelay
end

drop table #reports'
		
	EXEC(@Sql)
	
		set @process = 'New Reports - Create Job 1'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspAgentNotReady]    Script Date: 11/28/2013 22:07:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 11/28/2013 22:07:01 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepCallXfer'', 
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
/****** Object:  Step [LoadInformationReport]    Script Date: 11/28/2013 22:07:03 ******/
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
		@command=N''exec [ccspRepCallXfer] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'New Reports - Create Job 2'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspAgentNotReady]    Script Date: 11/28/2013 22:07:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 11/28/2013 22:07:01 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepInAbnd'', 
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
/****** Object:  Step [LoadInformationReport]    Script Date: 11/28/2013 22:07:03 ******/
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
		@command=N''exec [ccspRepInAbnd] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'New Reports - Create Job 3'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspAgentNotReady]    Script Date: 11/28/2013 22:07:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 11/28/2013 22:07:01 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepInAnsw'', 
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
/****** Object:  Step [LoadInformationReport]    Script Date: 11/28/2013 22:07:03 ******/
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
		@command=N''exec [ccspRepInAnsw] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'New Reports - Create Job 4'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspAgentNotReady]    Script Date: 11/28/2013 22:07:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 11/28/2013 22:07:01 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepOutAnswCalls'', 
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
/****** Object:  Step [LoadInformationReport]    Script Date: 11/28/2013 22:07:03 ******/
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
		@command=N''exec [ccspRepOutAnswCalls] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'New Reports - Create Job 5'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspAgentNotReady]    Script Date: 11/28/2013 22:07:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 11/28/2013 22:07:01 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepSpececialAbnd'', 
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
/****** Object:  Step [LoadInformationReport]    Script Date: 11/28/2013 22:07:03 ******/
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
		@command=N''exec [ccspRepSpececialAbnd] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'New Reports - Create Job 6'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspAgentNotReady]    Script Date: 11/28/2013 22:07:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 11/28/2013 22:07:01 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepSpececialAgent'', 
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
/****** Object:  Step [LoadInformationReport]    Script Date: 11/28/2013 22:07:03 ******/
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
		@command=N''exec [ccspRepSpececialAgent] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'New Reports - Create Job 7'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspAgentNotReady]    Script Date: 11/28/2013 22:07:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 11/28/2013 22:07:01 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepSpececialAgtPerformance'', 
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
/****** Object:  Step [LoadInformationReport]    Script Date: 11/28/2013 22:07:03 ******/
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
		@command=N''exec [ccspRepSpececialAgtPerformance] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'New Reports - Create Job 8'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspAgentNotReady]    Script Date: 11/28/2013 22:07:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 11/28/2013 22:07:01 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepSpececialCamMovs'', 
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
/****** Object:  Step [LoadInformationReport]    Script Date: 11/28/2013 22:07:03 ******/
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
		@command=N''exec [ccspRepSpececialCamMovs] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'New Reports - Create Job 9'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspAgentNotReady]    Script Date: 11/28/2013 22:07:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 11/28/2013 22:07:01 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepSpececialPromises'', 
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
/****** Object:  Step [LoadInformationReport]    Script Date: 11/28/2013 22:07:03 ******/
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
		@command=N''exec [ccspRepSpececialPromises] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
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
