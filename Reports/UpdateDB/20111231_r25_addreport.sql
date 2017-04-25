/*
Autor: Armando Rodriguez, Mauricio perez
Fecha: 2011/12/30
Descripcion: reportes de sub calificaciones, reportes de mca y correcciones a fallas encontradas en leon
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '25'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='CREATE TABLE [dbo].[ccTipoCalifSub](
	[califSub_id] [smallint] NOT NULL,
	[califSubDesc] [varchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[orden] [tinyint] NOT NULL CONSTRAINT [DF_ccTipoCalifSub_orden]  DEFAULT ((255)),
	[canReprogram] [bit] NOT NULL CONSTRAINT [DF_ccTipoCalifSub_CanReprogram]  DEFAULT ((0)),
	[califSub_Status] [bit] NOT NULL CONSTRAINT [DF_ccTipoCalifSub_califSub_Status]  DEFAULT ((1)),
 CONSTRAINT [PK_ccTipoCalifSub] PRIMARY KEY CLUSTERED 
(
	[califSub_id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[ccTipoCalifSubOUT](
	[califSub_id] [smallint] NOT NULL,
	[califSubDesc] [varchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[canReprogram] [bit] NOT NULL CONSTRAINT [DF_ccTipoSubCalifOut_CanReprogram]  DEFAULT ((0)),
	[orden] [tinyint] NOT NULL CONSTRAINT [DF_ccTipoSubCalifOUT_orden]  DEFAULT ((255)),
	[idTipoLista] [int] NOT NULL CONSTRAINT [DF_ccTipoSubCalifOut_idTipoLista]  DEFAULT ((0)),
	[califSubOut_Status] [bit] NOT NULL CONSTRAINT [DF_ccTipoSubCalifOut_califSubOut_Status]  DEFAULT ((1)),
	[keepDial] [bit] NOT NULL CONSTRAINT [DF_ccTipoSubCalifOUT_keepDial]  DEFAULT ((0)),
	[autoCallback] [bit] NOT NULL CONSTRAINT [DF_ccTipoSubCalifOUT_autoCAllback]  DEFAULT ((0)),
 CONSTRAINT [PK_ccTipoSubCalifOUT] PRIMARY KEY CLUSTERED 
(
	[califSub_id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE [dbo].[ccoCallsOut]
	ADD [califSub_id] [smallint] CONSTRAINT [DF_ccoCallsOut_califSub_id] DEFAULT ((0)) NOT NULL'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE [dbo].[ccCallsIn]
	ADD [califSub_id] [smallint] CONSTRAINT [DF_ccCallsIn_califSub_id] DEFAULT ((0)) NOT NULL'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[ccGenOutSubCalif](
	[timegroup] [smalldatetime] NOT NULL,
	[cam_id] [smallint] NOT NULL,
	[user_id] [smallint] NOT NULL,
	[califSub_id] [int] NOT NULL,
	[amount] [smallint] NOT NULL,
 CONSTRAINT [PK_ccGenOutsubCalif] PRIMARY KEY CLUSTERED 
(
	[timegroup] ASC,
	[cam_id] ASC,
	[user_id] ASC,
	[califSub_id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[ccGenInSubCalif](
	[timegroup] [smalldatetime] NOT NULL,
	[inbound_id] [smallint] NOT NULL,
	[user_id] [smallint] NOT NULL,
	[califSub_id] [tinyint] NOT NULL,
	[amount] [smallint] NOT NULL,
 CONSTRAINT [PK_ccGenInsubCalif] PRIMARY KEY CLUSTERED 
(
	[timegroup] ASC,
	[inbound_id] ASC,
	[user_id] ASC,
	[califsub_id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]'
	EXEC(@Sql)

 	set @Sql='CREATE PROCEDURE [dbo].[ccspGenOutSubCalif]
@from AS smalldatetime,
@to AS smalldatetime
AS
-- Delete previous data in case of reprocess HLAS

DELETE ccGenOutSUbCalif WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutSubCalif (timegroup, cam_id, [user_id], califSub_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, cam_id, [user_id], califsub_id
	, COUNT(*)
 FROM ccoCallsOut
 WHERE cal_inicio >= @from AND  cal_inicio < @to AND statuscall_id = 13 
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), cam_id, [user_id], califsub_id
'
	EXEC(@Sql)

 	set @Sql='CREATE PROCEDURE [dbo].[ccspGenInSubCalif]
@from AS smalldatetime,
@to AS smalldatetime
AS
-- Delete previous data in case of reprocess HLAS
DELETE ccGenInSubCalif WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInsubCalif (timegroup, inbound_id, [user_id], califsub_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, inbound_id, [user_id], califsub_id
	, COUNT(cal_inicio)
 FROM ccCallsIN
 WHERE cal_inicio >= @from AND  cal_inicio < @to
 AND statuscall_id = 13 AND INBOUND_ID > 0
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), inbound_id, [user_id], califsub_id
'
	EXEC(@Sql)

 	set @Sql='
CREATE PROCEDURE [dbo].[A_cwRepSubCalif]
@DateG as varchar(20),	-- Por Hora, Hour, Por Día, Day, Por Periodo, Period
@CamAgt as varchar(20), -- Especialidad, Campaña, Agente, Agent
@fini as varchar(20),	-- Fecha Inicio
@ffin as varchar(20),	-- Fecha Fin
@cbjUno as varchar(500),-- Agrega filtro 1
@CblDos as varchar(300),-- Agrega filtro por califsub_id
@InOutCalls as bit=0,	-- 0:Campañas,Salida / 1:Especialidad,Entrada
@SupID as int
as
set nocount on
declare @RtnValue table (Id int identity(1,1), Value nvarchar(100))
declare @CamAgt_M varchar(max), @CamAgt_C varchar(max), @Sql varchar(max), @Serv varchar(50), @idioma as bit,@CblDosTmp as varchar(300)
select @CamAgt_M='''', @CamAgt_C='''', @Serv=valor from ccsettings where setting_id = 22
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

if @CblDos <> '''' 
 begin
	set @CblDosTmp = @CblDos
	While (Charindex('','',@CblDos)>0)
	 Begin 
		Insert Into @RtnValue (value)
		Select Value = ltrim(rtrim(Substring(@CblDos,1,Charindex('','',@CblDos)-1))) 
		Set @CblDos = Substring(@CblDos,Charindex('','',@CblDos)+len('',''),len(@CblDos))
	 End 

	Insert Into @RtnValue (Value)
	Select Value = ltrim(rtrim(@CblDos))
 end

else
 begin
	if @InOutCalls = 0
 		insert into @RtnValue select califsub_id from ccTipoCalifsubOUT
 	else
 		insert into @RtnValue select califsub_id from ccTipoCalifsub
 end

if @InOutCalls = 0
 begin
	select @CamAgt_M=coalesce(@CamAgt_M + '', xDetail.[''+replace([califsubdesc], '' '', ''_'')+'']'', '''') 
	from ccTipoCalifsubOUT where califsub_id in (select value from @RtnValue) order by califsub_id

	select @CamAgt_C=coalesce(@CamAgt_C + '', sum(case when califsub_id = '' + CAST(califsub_id as varchar(10)) 
		+ '' then isnull(amount,0) else 0 end)'' + ''[''+replace([califsubdesc], '' '', ''_'')+'']'', '''') 
	from ccTipoCalifsubOUT where califsub_id in (select value from @RtnValue) order by califsub_id
 end

else
 begin
	select @CamAgt_M=coalesce(@CamAgt_M + '', xDetail.[''+replace([califsubdesc], '' '', ''_'')+'']'', '''') 
	from ccTipoCalifsub where califsub_id in (select value from @RtnValue) order by califsub_id

	select @CamAgt_C=coalesce(@CamAgt_C + '', sum(case when califsub_id = '' + CAST(califsub_id as varchar(10)) 
		+ '' then isnull(amount,0) else 0 end)'' + ''[''+replace([califsubdesc], '' '', ''_'')+'']'', '''') 
	from ccTipoCalifsub where califsub_id in (select value from @RtnValue) order by califsub_id
 end

select @DateG = case @DateG when ''Por Hora'' then ''H'' when ''Hour'' then ''H'' when ''Por Día'' then ''D'' 
	when ''Day'' then ''D'' when ''Por Periodo'' then ''p'' when ''Period'' then ''p'' end

select @CamAgt = case @CamAgt when ''Campaña'' then ''C'' when ''Campaign'' then ''C'' 
	when ''Especialidad'' then ''E'' when ''ACD group'' then ''E'' when ''Agente'' then ''G'' 
	when ''Agent'' then ''G'' when ''Grupo de Trabajo'' then ''W'' when ''WorkGroup'' then ''W'' when ''Area'' then ''A'' end

if @InOutCalls=0 and @CamAgt=''E''
	set @CamAgt=''C''

if @InOutCalls=1 and @CamAgt=''C''
	set @CamAgt=''E''

IF @CamAgt=''A'' and @SupID=0 or @CamAgt=''W'' and @SupID=0
	raiserror(''En el caso filtro por Area y Workgroup es necesario el id del supervisor que consulta'', 18, 1)
 
set @Sql=''SELECT timegroup as Fecha '' + case @CamAgt 
	when ''G'' then '', apellidoPaterno + '''' ''''+ isNull( apellidoMaterno, '''' '''')+ '''' ''''+  nombres as Agente ''
	when ''C'' then '', ccCamps.cam_descripcion AS Campana '' when ''E'' then '', ccInbound.descripcion AS Especialidad '' 
	when ''W'' then '', WGName as WorkGroup '' 
	when ''A'' then '', AreaName as Area '' else ''''	end + @CamAgt_M + '' from (SELECT '' + 
	case @DateG when ''H'' then '' timegroup '' when ''D'' then '' CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) '' 
	when ''P'' then '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +''''-01 '''', 121) '' end + '' timegroup '' + 
	case @CamAgt when ''G'' then '', [user_id]'' when ''C'' then '', cam_id'' when ''E'' then '', inbound_id'' 
	when ''W'' then '', IDWG'' when ''A'' then '', IDArea'' 
	else '''' end + @CamAgt_C + '' FROM '' + 

	case when @CamAgt in (''G'',''C'') and @InOutCalls = 0 then ''ccGenOutsubCalif''
		 when @CamAgt in (''W'') and @InOutCalls = 0 then ''ccGenOutsubCalifWG''
		 when @CamAgt in (''G'',''E'') and @InOutCalls = 1 then ''ccGenInsubCalif''
		 when @CamAgt in (''W'') and @InOutCalls = 1 then ''ccGenInsubCalifWG''
		 when @CamAgt in (''A'') and @InOutCalls = 0 then ''ccGenOutsubCalifWG owg, ccRIAAreaWorkGroup awg''
		 when @CamAgt in (''A'') and @InOutCalls = 1 then ''ccGenInsubCalifWG iwg, ccRIAAreaWorkGroup awg'' else '''' end + '' WHERE '' +

	case @InOutCalls 
	when 0 then 
		case @CamAgt
		when ''W'' then + case 
			when @cbjUno <> '''' and @CblDos <> '''' then '' idwg in ('' + @cbjUno  + '') '' + '' and califsub_id IN ('' + @CblDosTmp + '') and ''
			when @cbjUno <> '''' and @CblDos = '''' then '' idwg in ( '' + @cbjUno  + '') and ''
			else '''' end 
		when ''A'' then ''owg.idwg = awg.idwg and'' + case 
			when @cbjUno <> '''' and @CblDos <> '''' then '' idarea in ('' + @cbjUno  + '') '' + '' and califsub_id IN ('' + @CblDosTmp + '') and ''
			when @cbjUno <> '''' and @CblDos = '''' then '' idarea in ( '' + @cbjUno  + '') and ''
			else '''' end 
		else '''' + case 
			when @cbjUno <> '''' and @CblDos <> '''' then '' cam_id in ('' + @cbjUno  + '') '' + '' and califsub_id IN ('' + @CblDosTmp + '') and ''
			when @cbjUno <> '''' and @CblDos = '''' then '' cam_id in ( '' + @cbjUno  + '') and ''
			else '''' end 
		end + ''''
	else
		case @CamAgt
		when ''W'' then + case 
			when @cbjUno <> '''' and @CblDos <> '''' then '' idwg in ('' + @cbjUno  + '') '' + '' and califsub_id IN ('' + @CblDosTmp + '') and ''
			when @cbjUno <> '''' and @CblDos = '''' then '' idwg in ( '' + @cbjUno  + '') and ''
			else '''' end 
		when ''A'' then ''iwg.idwg = awg.idwg and'' + case 
			when @cbjUno <> '''' and @CblDos <> '''' then '' idarea in ('' + @cbjUno  + '') '' + '' and califsub_id IN ('' + @CblDosTmp + '') and ''
			when @cbjUno <> '''' and @CblDos = '''' then '' idarea in ( '' + @cbjUno  + '') and ''
			else '''' end 
		else '''' + case 
			when @cbjUno <> '''' and @CblDos <> '''' then '' inbound_id in ('' + @cbjUno  + '') '' + '' and califsub_id IN ('' + @CblDosTmp + '') and ''
			when @cbjUno <> '''' and @CblDos = '''' then '' inbound_id in ( '' + @cbjUno  + '') and ''
			else '''' end 
		end + ''''
	end + '' timegroup >= '''''' + @fini + '''''' AND timegroup < '''''' + @ffin + '''''' GROUP BY '' + 

	case @DateG when ''H'' then '' timegroup '' when ''D'' then '' CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) '' when ''P'' 
	then '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +''''-01 '''', 121)'' end + case @CamAgt 
	when ''G'' then '', [user_id]'' when ''C'' then '', cam_id'' when ''E'' then '', inbound_id'' 
	when ''W'' then '', IDWG'' when ''A'' then '', IDArea'' 
	else '''' end + '') xDetail  LEFT JOIN '' + case @CamAgt when ''G'' then ''ccUsers ON xDetail.[user_id]=ccUsers.[user_id]'' 
	when ''C'' then ''ccCamps ON xDetail.cam_id=ccCamps.cam_id'' 
	when ''E'' then ''ccInbound ON xDetail.inbound_id=ccInbound.inbound_id'' 
	when ''W'' then ''ccRIACat_WorkGroup wg ON xDetail.IDWG=wg.IDWG''
	when ''A'' then ''ccRIACat_Areas ON xDetail.IDArea=ccRIACat_Areas.IDArea'' 
	else '''' end + '' order by Fecha, '' + case @CamAgt when ''G'' then ''Agente'' 
	when ''C'' then ''Campana'' when ''E'' then ''Especialidad'' 
	when ''W'' then ''WorkGroup'' when ''A'' then ''Area'' else ''''end

	-- Adaptar segun formato de @Serv
if @idioma = 1
begin
set @Sql = replace(@Sql, ''Fecha'', ''Date'') 
set @Sql = replace(@Sql, ''Agente'', ''Agent'')
set @Sql = replace(@Sql, ''Especialidad'', ''Specialty'') 
set @Sql = replace(@Sql, ''Campana'', ''Campaign'') 
end

begin try
	exec(@Sql)
	--print(@Sql)
end try

begin catch
	declare @error varchar(255)
	set @error=''Se presento un problema al generar el reporte, causa del mismo: "''+ERROR_MESSAGE()+''"''
	select @error
end catch
set nocount off
'
	EXEC(@Sql)

 	set @Sql='
ALTER PROCEDURE [dbo].[ccspGenOutCstoResumen]
@from AS smalldatetime,
@to AS smalldatetime
AS

-- Delete previous data in case of reprocess HLAS
DELETE ccGenOutCstoResumen WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCstoResumen (timegroup, cam_id, [user_id], provedor_id, tipoLlamada_id, amount, mins, costo)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, cam_id, [user_id], provedor_id, tipoLlamada_id 
	, COUNT(*)
	, SUM( mins)
	, SUM( costo )
FROM
(
	SELECT cal_inicio, cam_id, [user_id], provedor_id, tipoLlamada_id, CEILING((cal_tXfer + cal_tRing + cal_tDialog +1 ) / 60.0 ) as mins, costo
	FROM ccoCallsOut
	WHERE cal_inicio >= @from AND  cal_inicio < @to and provedor_id is not null and cal_manual in (0,2)

	-- Tambien las llamdas que fueron fax
	UNION ALL

	SELECT cco.fecha as fecha, cco.cam_id, 0, p.provedor_id, l.tipoLlamada_id, 1, t.MinutoUno as costo
	FROM ccoLogDials cco, ccoDialers cd, cstoProvedor p, cstoTarifa t, cstoTipoLlamada l
	WHERE 
	cco.answerbit = 1 and cco.tiporesdial_id <> 1
	and cco.fecha >=  @from AND cco.fecha < @to
	and cco.puerto = cd.puerto
	and cd.provedor_id = p.provedor_id	
	and p.provedor_id = t.provedor_id
	and l.longitud = len(cco.telefono)
	and cco.telefono like l.prefijo
	and t.tipoLlamada_id = l.tipoLlamada_id
)x
GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), cam_id, [user_id], provedor_id, tipoLlamada_id
'
	EXEC(@Sql)

-- optimizaciones
 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInSpecWG]
@from AS smalldatetime,
@to AS smalldatetime
AS
set nocount on
-- Delete previous data in case of reprocess HLAS
DELETE ccGenInSpecWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInSpecWG (timegroup, idwg, pos_tot, pos_time, pos_efect)
SELECT timegroup, wgs.idwg
	, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max -- pos_tot
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
FROM ccGenAgent INNER JOIN 
	(select distinct wg.user_id, wg.idwg, ci.inbound_id from ccRIAWorkGroup_Calid wg, cccallsin ci where wg.cal_id = ci.cal_id and wg.tipo = 0 and wg.timestamp >= @from AND wg.timestamp < @to)as wgs 
	ON (ccGenAgent.[user_id] = wgs.[user_id])
WHERE timegroup >= @from AND timegroup < @to  AND wgs.idwg > 0
GROUP BY timegroup, wgs.idwg
return(0)
set nocount off'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCampWG]
@from AS smalldatetime,
@to AS smalldatetime
AS
set nocount on

declare @to2 as smalldatetime
declare @from2 as smalldatetime

SELECT @to2 = @to 
SELECT @from2 = @from

DELETE ccGenOutCampWG WHERE timegroup >= @from2 AND timegroup < @to2

INSERT INTO ccGenOutCampWG (timegroup, idwg, pos_tot, pos_time, pos_efect)
SELECT timegroup, idwg
	, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
FROM ccGenAgent INNER JOIN 
	(select distinct wg.user_id, wg.idwg, co.cam_id from ccRIAWorkGroup_Calid wg, ccocallsout co where wg.cal_id = co.cal_id and wg.tipo = 1 and co.cal_inicio >= @from2 AND co.cal_inicio < @to2)as wgs 
	ON (ccGenAgent.[user_id] = wgs.[user_id])
WHERE timegroup >= @from2 AND timegroup < @to2
GROUP BY timegroup, idwg

return(0)
set nocount off'


	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCallDialsWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenOutCallDialsWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCallDialsWG (timegroup, idwg, [puerto], tiporesdial_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + '':00'', 121) AS timegroup
	, idwg, puerto, tiporesdial_id
	, COUNT(*)
 FROM ccologdials ld with(index(IX_ccoLogDials),nolock), ccRIAWorkGroup_logDial_id wg
 WHERE fecha >= @from AND  fecha < @to and ld.logdial_id = wg.logdial_id
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + '':00'', 121), idwg, [puerto], tiporesdial_id'
	EXEC(@Sql)

 	set @Sql='create index IX_cccRIAWorkGroup_logdial_id_2 on ccRIAWorkGroup_logdial_id(logdial_id)'
	EXEC(@Sql)

-- nueva tabla para scheduler
 	set @Sql='
create table exportReports
(
	jobId int not null,
	jobType int not null,
	intervalMinutes int not null,
	tableN varchar(128) not null,
	idN varchar(128) not null,
	dateN varchar(128) not null,
	cols varchar(max) not null,
	skipMinutes int not null
)

insert into exportReports values ( 1, 1, 10, ''ccoCallsOut'', ''cal_id'', ''cal_inicio'', ''cal_id, callout_id, cal_telefono, cal_puerto, cam_id, User_id, cal_extension, cal_colgada, cal_Key, statusCall_id, calif_id, cal_que, cal_tDialog, cal_tNotas, cal_tXfer, cal_tRing, cal_Inicio, cal_fcallback, cal_manual, cal_tDialogDialer, cal_tLineBusy, costo, provedor_id, tipoLlamada_id, cal_tMoh, cal_whoHung, isNull(califSub_id,0) as califSub_id'', 60)
insert into exportReports values ( 2, 1, 10, ''ccCallsIn'', ''cal_id'', ''cal_inicio'', ''cal_id,dni_id, cal_ANI, cal_puerto,Inbound_id, User_id, cal_extension,cal_colgada,cal_Key,statusCall_id,calif_id,cal_que,cal_tDialog,cal_tNotas,cal_tWait,cal_tXfer,cal_tCall,cal_tRing,cal_Xfer,cal_Inicio,cal_Opciones,cal_origin_id, cal_tMoh, cal_whoHung, isNull(califSub_id,0) as califSub_id'', 60)
insert into exportReports values ( 3, 1, 10, ''ccologdials'', ''logDial_id'', ''fecha'', ''logDial_id,callout_id,cam_id,tipoResDial_id,Telefono,Puerto,fecha,tDialing,tBusy,answerbit'', 60)
insert into exportReports values ( 4, 1, 10, ''ccoCallsOutSource'', ''callout_id'', ''cal_fechaDial'', ''callout_id,cal_Key,cam_id,cal_fechaDial, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, Dato1, Dato2, Dato3, Dato4, Dato5'', 60)
insert into exportReports values ( 5, 2, 10, ''ccLogTransfers'', '''', ''fechaFin'', ''cal_id, tipo, modo, destino, tAntesXfer, tDespuesXfer, fechaFin'', 30)
insert into exportReports values ( 6, 1, 10, ''ccCallsReject'', ''cal_id'', ''cal_inicio'', ''cal_id, ani, dnis, puerto, cal_inicio, Inbound_id'', 30)
insert into exportReports values ( 7, 2, 10, ''ccLogLogin'', '''', ''fecha'', ''User_id, Extension, TipoMov, fecha'', 30)
insert into exportReports values ( 8, 2, 10, ''ccLogAgentesDia'', '''', ''fecha'', ''User_id, TipoStatusAge_id, tStatus, fecha'', 30)
insert into exportReports values ( 9, 2, 10, ''ccLogAgentesNotReady'', '''', ''fecha'', ''User_id, TipoNotReady_id,tStatus,fecha,separado'', 30)
insert into exportReports values ( 10, 2, 10, ''ccRIAWorkGroup_Calid'', '''', ''timestamp'', ''IDWG, cal_id, User_id, timestamp, tipo'', 60)
insert into exportReports values ( 11, 1, 10, ''ccRIAWorkGroup_logdial_id'', ''logdial_id'', ''timestamp'', ''IDWG, logdial_id, CAM_ID, timestamp'', 60)
insert into exportReports values ( 12, 1, 10, ''ccLogAgentesDia_Dialog'', ''Log_DialId'', ''fecha_Dialog'', ''Log_DialId, User_id, Cam_id, fecha_Calc_ms, tStatus_Dispo, fecha_Dispo, tStatus_Dialog, fecha_Dialog'', 60)

insert into exportReports values ( 101, 3, 60,''ccspGenSession'',''0'',''1'','''',0)
insert into exportReports values ( 102, 3, 60,''ccspGenInCall'',''4'',''1'','''',0)
insert into exportReports values ( 103, 3, 60,''ccspGenOutCall'',''4'',''1'','''',0)
insert into exportReports values ( 104, 3, 60,''ccspGenAgentStatusSepHour'',''0'',''1'','''',0)
insert into exportReports values ( 105, 3, 60,''ccspGenAgent'',''0'',''1'','''',0)
insert into exportReports values ( 106, 3, 60,''ccspGenAgentStatusSepHourNotReady'',''0'',''1'','''',0)
insert into exportReports values ( 107, 3, 60,''ccspGenAgentStatusNotReady'',''4'',''1'','''',0)
insert into exportReports values ( 108, 3, 60,''ccspGenInSpec'',''0'',''1'',''checa'',0)
insert into exportReports values ( 109, 3, 60,''ccspGenInCalif'',''4'',''1'','''',0)
insert into exportReports values ( 110, 3, 60,''ccspGenInAbnd'',''4'',''1'','''',0)
insert into exportReports values ( 111, 3, 60,''ccspGenInAnsw'',''4'',''1'','''',0)
insert into exportReports values ( 112, 3, 60,''ccspGenInCallDNI'',''4'',''1'','''',0)
insert into exportReports values ( 113, 3, 60,''ccspGenOutCamp'',''0'',''1'',''checa'',0)
insert into exportReports values ( 114, 3, 60,''ccspGenOutCallCalif'',''4'',''1'','''',0)
insert into exportReports values ( 115, 3, 60,''ccspGenOutCallDials'',''4'',''1'','''',0)
insert into exportReports values ( 116, 3, 60,''ccspGenOutCstoResumen'',''4'',''1'','''',0)
insert into exportReports values ( 117, 3, 60,''ccspGenInCallWG'',''4'',''1'','''',0)
insert into exportReports values ( 118, 3, 60,''ccspGenInSpecWG'',''0'',''1'',''checa'',0)
insert into exportReports values ( 119, 3, 60,''ccspGenInCalifWG'',''4'',''1'','''',0)
insert into exportReports values ( 120, 3, 60,''ccspGenInAbndWG'',''4'',''1'','''',0)
insert into exportReports values ( 121, 3, 60,''ccspGenInAnswWG'',''4'',''1'','''',0)
insert into exportReports values ( 122, 3, 60,''ccspGenOutCallWG'',''4'',''1'','''',0)
insert into exportReports values ( 123, 3, 60,''ccspGenOutCampWG'',''0'',''1'',''checa'',0)
insert into exportReports values ( 124, 3, 60,''ccspGenOutCallCalifWG'',''4'',''1'','''',0)
insert into exportReports values ( 125, 3, 60,''ccspGenOutCallDialsWG'',''4'',''1'','''',0)
insert into exportReports values ( 126, 3, 60,''ccspGenTelMarcados'',''1'',''1'','''',0)
insert into exportReports values ( 127, 3, 60,''ccspGenOutSubCalif'',''4'',''1'','''',0)
insert into exportReports values ( 128, 3, 60,''ccspGenInSubCalif'',''4'',''1'','''',0)

insert into exportReports values ( 201, 4, 180,''ccUsers'','''','''',''User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,Password,TipoUser_id,Status,TipoLLamadas,Sexo,filter,CanChangeStatus,fCreate,DialMask,XferMask,LastPasswordChange'',0)
insert into exportReports values ( 202, 4, 180,''ccUsers'',''ccUsers_Consulta'','''',''User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,Password,TipoUser_id,Status,TipoLLamadas,Sexo,filter,CanChangeStatus,fCreate,DialMask,XferMask,LastPasswordChange'',0)
insert into exportReports values ( 203, 4, 180,''ccCamps'','''','''',''cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, cam_inter_ocupado, cam_inter_nocontesto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql, cam_tnotas, cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_tDialBeforeWU, cam_tDialBeforeReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, cam_fCreate, cam_MaxDlrXage, ani'',0)
insert into exportReports values ( 204, 4, 180,''ccCamps'',''ccCamps_Consulta'','''',''cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, cam_inter_ocupado, cam_inter_nocontesto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql, cam_tnotas, cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_tDialBeforeWU, cam_tDialBeforeReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, cam_fCreate, cam_MaxDlrXage, ani'',0)
insert into exportReports values ( 205, 4, 180,''ccInbound'','''','''',''isnull(cli_id,0) cli_id,Inbound_id,descripcion,Status,dnis,standby,tNotas,tMaxWaitCall,nMaxQue,Msg_id,tel_maxwait,tel_maxqueue,tel_outservice,tel_noct,bnocturno,ShowCalifWnd,StartTimerOnHangUp,voicePath'',0)
insert into exportReports values ( 206, 4, 180,''ccInbound'',''ccInbound_Consulta'','''',''isnull(cli_id,0) cli_id,Inbound_id,descripcion,Status,dnis,standby,tNotas,tMaxWaitCall,nMaxQue,Msg_id,tel_maxwait,tel_maxqueue,tel_outservice,tel_noct,bnocturno,ShowCalifWnd,StartTimerOnHangUp,voicePath'',0)
insert into exportReports values ( 207, 4, 180,''ccTipoCalif'','''','''',''calif_id,Description,orden'',0)
insert into exportReports values ( 208, 4, 180,''ccTipoCalifOUT'','''','''',''calif_id,Description,autoTime,CanReprogram,orden'',0)
insert into exportReports values ( 209, 4, 180,''ccTipoNotReady'','''','''',''TipoNotReady_id,Descripcion'',0)
insert into exportReports values ( 210, 4, 180,''ccPosicion'','''','''',''pos_id,Computer,ext_id,user_id,Status,tipoConexion,IP'',0)
insert into exportReports values ( 211, 4, 180,''ccDNIS'','''','''',''dni_id,dni_numero,dni_tipo,tipodni_id,dni_tpoMaxEspera,dni_Descripcion'',0)
insert into exportReports values ( 212, 4, 180,''telefonosConferencia'','''','''',''nombre,tel'',0)
insert into exportReports values ( 213, 4, 180,''cstoTipoLlamada'','''','''',''tipoLlamada_id,descrip,longitud,prefijo'',0)
insert into exportReports values ( 214, 4, 180,''cstoProvedor'','''','''',''provedor_id,descrip'',0)
insert into exportReports values ( 215, 4, 180,''cstoTarifa'','''','''',''provedor_id, tipoLlamada_id, minutoUno, minutoAdicional'',0)
insert into exportReports values ( 216, 4, 180,''ccoDialers'','''','''',''dialer_id, Descripcion, Puerto, Extension, Status, provedor_id'',0)
insert into exportReports values ( 217, 4, 180,''ccRIACat_Areas'','''','''',''IDArea, AreaName'',0)
insert into exportReports values ( 218, 4, 180,''ccriacat_workgroup'','''','''',''IDWG, WGName'',0)
insert into exportReports values ( 219, 4, 180,''ccSupervisorCam'','''','''',''distinct user_id,cam_id,tipo'',0)
insert into exportReports values ( 220, 4, 180,''ccCampsAgente'','''','''',''distinct user_id, cam_id, prioridad, skill'',0)
insert into exportReports values ( 221, 4, 180,''ccInboundAgentes'','''','''',''distinct User_id,Inbound_id,cli_id,prioridad,skill'',0)
insert into exportReports values ( 222, 4, 180,''ccCalifCamp'','''','''',''calif_id, cam_id, tipo'',0)
insert into exportReports values ( 223, 4, 180,''ccRIAAreaWorkGroup'','''','''',''IDWG, IDArea'',0)
insert into exportReports values ( 224, 4, 180,''ccRIAWorkGroupUsers'','''','''',''IDWG,User_id'',0)
insert into exportReports values ( 225, 4, 180,''ccTipoCalifSub'','''','''',''califSub_id, califSubDesc, isnull(orden,0) as orden, isnull(canreprogram,0) as canReprogram, califSub_Status'',0)
insert into exportReports values ( 226, 4, 180,''ccTipoCalifSubOut'','''','''',''califSub_id, califSubDesc, isnull(canReprogram,0) as canReprogram, isnull(orden,0) as orden, isnull(idTipoLista,0) as idTipoLista, califSubOut_Status, isnull(keepDial,0) as keepDial, isnull(autoCallback,0) as autoCallback'',0)

insert into exportReports values ( 301, 4, 1440,''ccStatusLlamada'','''','''',''statusCall_id,descripcion'',0)
insert into exportReports values ( 302, 4, 1440,''ccTipoStatusAgente'','''','''',''TipoStatusAge_id,descripcion'',0)
insert into exportReports values ( 303, 4, 1440,''ccTipoResultadoDial'','''','''',''tipoResDial_id,descripcion'',0)
'
	EXEC(@Sql)

------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC]
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


