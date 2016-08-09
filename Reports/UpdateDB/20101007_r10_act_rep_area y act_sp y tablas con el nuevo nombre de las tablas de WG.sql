/*
Autor: Armando Rodriguez
Fecha: 2010/00/00
Descripcion: Actualizacion de querys para correr todo desde los registros
Version requerida: 9
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '10'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenSession]
@from as smalldatetime,
@to as smalldatetime
AS
set nocount on
declare @to2 as smalldatetime
declare @from2 as smalldatetime

SELECT @to2 = @to --CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''00:00'', 121)
SELECT @from2 = @from -- DATEADD(d, -1, @to2)

delete  from ccGenSession where login >= @from2 and login<@to2
INSERT INTO ccGenSession ([user_id], extension, login, logout)
SELECT uid, max(ext) ext, login, max(logout) logout
FROM 
	(SELECT uid, ext, login, ISNULL(logout, (SELECT MIN(fecha) FROM ccLogLogin with (nolock, index(ccLogLogin_fecha))
	WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout 
	FROM
		(SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout
		FROM 
			(SELECT uid, ext, MAX(login) as login, logout
			FROM
				(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha) 
				FROM ccLogLogin subLogin with (nolock, index(ccLogLogin_fecha)) WHERE subLogin.tipomov = 0 
				AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout] 
				FROM ccLogLogin Login with (nolock, index(ccLogLogin_fecha))
				WHERE login.fecha >= dateadd(dd, -5, @from2) and tipomov = 1
				GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail 
			WHERE logout IS NOT NULL GROUP BY uid, ext, logout) Login 
		RIGHT OUTER JOIN ccLogLogin  with (nolock, index(ccLogLogin_fecha))
		ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login AND ccLogLogin.extension = Login.ext)
		WHERE tipomov = 1
		and ccLogLogin.fecha >= dateadd( dd, -5, @from2)) Det 
	) LoginDetail 
WHERE logout IS NOT NULL
AND login >= @from2 and login < @to2
GROUP BY uid, login

return(0)
set nocount off'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[ccRIACat_Areas](
	[IDArea] [int] NOT NULL,
	[AreaName] [varchar](50) NOT NULL,
 CONSTRAINT [PK_ccRIACat_Areas] PRIMARY KEY CLUSTERED 
(
	[IDArea] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[ccRIAAreaWorkGroup](
	[IDWG] [smallint] NOT NULL,
	[IDArea] [int] NOT NULL,
 CONSTRAINT [PK_ccRIAAreaWorkGroup] PRIMARY KEY CLUSTERED 
(
	[IDArea] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE [dbo].[ccRIAAreaWorkGroup]  WITH CHECK ADD  CONSTRAINT [FK_ccRIAAreas_IDArea] FOREIGN KEY([IDArea])
REFERENCES [dbo].[ccRIACat_Areas] ([IDArea])'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE [dbo].[ccRIAAreaWorkGroup] CHECK CONSTRAINT [FK_ccRIAAreas_IDArea]'
	EXEC(@Sql)

 	set @Sql='ALTER proc [dbo].[A_cwRep2Calif_WG]
@DateG as varchar(20),	-- Por Hora, Hour, Por Día, Day, Por Periodo, Period
@CamAgt as varchar(20), -- Especialidad, ACD group, Agente, Agent, Grupo de Trabajo, WorkGroup, Area
@fini as varchar(20),	-- Fecha Inicio
@ffin as varchar(20),	-- Fecha Fin
@cbjUno as varchar(500),-- Agrega filtro por inbound_id
@CblDos as varchar(300),-- Agrega filtro por calif_id
@SupID as int=0,		-- Id de supervisor, solo filtra en workgroup y en area
@InOutCalls as bit=0	-- 0:Campañas,Salida / 1:Especialidad,Entrada
as
set nocount on
declare @RtnValue table (Id int identity(1,1), Value nvarchar(100))
declare @CamAgt_M varchar(max), @CamAgt_C varchar(max), @Sql varchar(max), @Serv varchar(50), @idioma as bit,@CblDosTmp as varchar(300)
select @CamAgt_M='''', @CamAgt_C='''', @Serv=valor from ccsettings where setting_id = 22
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

if @CblDos <> '''' --and @cbjUno = ''''
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
 		insert into @RtnValue select calif_id from ccTipoCalifOUT
 	else
 		insert into @RtnValue select calif_id from ccTipoCalif
 end

if @InOutCalls = 0
 begin
	select @CamAgt_M=coalesce(@CamAgt_M + '', xDetail.[''+replace([Description], '' '', ''_'')+'']'', '''') 
	from ccTipoCalifOUT where calif_id in (select value from @RtnValue) order by calif_id

	select @CamAgt_C=coalesce(@CamAgt_C + '', sum(case when calif_id = '' + CAST(calif_id as varchar(10)) 
		+ '' then isnull(amount,0) else 0 end)'' + ''[''+replace([Description], '' '', ''_'')+'']'', '''') 
	from ccTipoCalifOUT where calif_id in (select value from @RtnValue) order by calif_id
 end

else
 begin
	select @CamAgt_M=coalesce(@CamAgt_M + '', xDetail.[''+replace([Description], '' '', ''_'')+'']'', '''') 
	from ccTipoCalif where calif_id in (select value from @RtnValue) order by calif_id

	select @CamAgt_C=coalesce(@CamAgt_C + '', sum(case when calif_id = '' + CAST(calif_id as varchar(10)) 
		+ '' then isnull(amount,0) else 0 end)'' + ''[''+replace([Description], '' '', ''_'')+'']'', '''') 
	from ccTipoCalif where calif_id in (select value from @RtnValue) order by calif_id
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

	case when @CamAgt in (''G'',''C'') and @InOutCalls = 0 then ''ccGenOutCallCalif''
		 when @CamAgt in (''W'') and @InOutCalls = 0 then ''ccGenOutCallCalifWG''
		 when @CamAgt in (''G'',''E'') and @InOutCalls = 1 then ''ccGenInCalif''
		 when @CamAgt in (''W'') and @InOutCalls = 1 then ''ccGenInCalifWG''
		 when @CamAgt in (''A'') and @InOutCalls = 0 then ''ccGenOutCallCalifWG owg, ccRIAAreaWorkGroup awg''
		 when @CamAgt in (''A'') and @InOutCalls = 1 then ''ccGenInCalifWG iwg, ccRIAAreaWorkGroup awg'' else '''' end + '' WHERE '' +

	case @InOutCalls 
	when 0 then 
		case @CamAgt
		when ''W'' then + case 
			when @cbjUno <> '''' and @CblDos <> '''' then '' idwg in ('' + @cbjUno  + '') '' + '' and calif_id IN ('' + @CblDosTmp + '') and ''
			when @cbjUno <> '''' and @CblDos = '''' then '' idwg in ( '' + @cbjUno  + '') and ''
			else '''' end 
		when ''A'' then ''owg.idwg = awg.idwg and'' + case 
			when @cbjUno <> '''' and @CblDos <> '''' then '' idarea in ('' + @cbjUno  + '') '' + '' and calif_id IN ('' + @CblDosTmp + '') and ''
			when @cbjUno <> '''' and @CblDos = '''' then '' idarea in ( '' + @cbjUno  + '') and ''
			else '''' end 
		else '''' + case 
			when @cbjUno <> '''' and @CblDos <> '''' then '' cam_id in ('' + @cbjUno  + '') '' + '' and calif_id IN ('' + @CblDosTmp + '') and ''
			when @cbjUno <> '''' and @CblDos = '''' then '' cam_id in ( '' + @cbjUno  + '') and ''
			else '''' end 
		end + ''''
	else
		case @CamAgt
		when ''W'' then + case 
			when @cbjUno <> '''' and @CblDos <> '''' then '' idwg in ('' + @cbjUno  + '') '' + '' and calif_id IN ('' + @CblDosTmp + '') and ''
			when @cbjUno <> '''' and @CblDos = '''' then '' idwg in ( '' + @cbjUno  + '') and ''
			else '''' end 
		when ''A'' then ''iwg.idwg = awg.idwg and'' + case 
			when @cbjUno <> '''' and @CblDos <> '''' then '' idarea in ('' + @cbjUno  + '') '' + '' and calif_id IN ('' + @CblDosTmp + '') and ''
			when @cbjUno <> '''' and @CblDos = '''' then '' idarea in ( '' + @cbjUno  + '') and ''
			else '''' end 
		else '''' + case 
			when @cbjUno <> '''' and @CblDos <> '''' then '' inbound_id in ('' + @cbjUno  + '') '' + '' and calif_id IN ('' + @CblDosTmp + '') and ''
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

 	set @Sql='ALTER PROCEDURE [dbo].[A_cwReportDialWG]
@DateG as varchar(20),
@fini as varchar(20),
@ffin as varchar(20),
@cbjUno as varchar(600)='''',
@CblDos as varchar(300) = '''',
@CamAgt as varchar(20)
AS

set nocount on
declare @RtnValue table (Id int identity(1,1), Value nvarchar(100))
declare @CamAgt_M varchar(max), @CamAgt_C varchar(max), @Sql varchar(max), @Serv varchar(50), @idioma as bit,@CblDosTmp as varchar(300)
select @CamAgt_M='''', @CamAgt_C='''', @CblDosTmp='''', @Serv=valor from ccsettings where setting_id = 22
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

if @CblDos <> '''' --and @cbjUno = ''''
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
 		insert into @RtnValue select tipoResDial_id from ccTipoResultadoDial
 end

	select @CamAgt_M=coalesce(@CamAgt_M + '', xDetail.[''+replace([Descripcion], '' '', ''_'')+'']''+ '', dbo.fPorcentaje([''+replace([Descripcion], '' '', ''_'')+''],Total) '' + ''[% ''+replace([Descripcion], '' '', ''_'')+'']'', '''') 
	from ccTipoResultadoDial where tipoResDial_id in (select value from @RtnValue) order by tipoResDial_id

	select @CamAgt_C=coalesce(@CamAgt_C + '', sum(case when tipoResDial_id = '' + CAST(tipoResDial_id as varchar(10)) 
		+ '' then isnull(amount,0) else 0 end)'' + ''[''+replace([Descripcion], '' '', ''_'')+'']'', '''') 
	from ccTipoResultadoDial where tipoResDial_id in (select value from @RtnValue) order by tipoResDial_id

select @CamAgt_C = @CamAgt_C + '', SUM(amount) Total ''

select @DateG = case @DateG when ''Por Hora'' then ''H'' when ''Hour'' then ''H'' when ''Por Día'' then ''D'' 
	when ''Day'' then ''D'' when ''Por Periodo'' then ''p'' when ''Period'' then ''p'' end

select @CamAgt = case @CamAgt when ''Grupo de Trabajo'' then ''W'' when ''workgroup'' then ''W'' when ''Area'' then ''A'' end

set @Sql=''Select timegroup as Fecha'' + case @CamAgt when ''W'' then '', WGName AS WorkGroup'' when ''A'' then '', areaName AS Area'' end  + @CamAgt_M + '', total from (SELECT distinct'' + 
	case @DateG 
		when ''H'' then '' timegroup '' 
		when ''D'' then '' CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) '' 
		when ''P'' then '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +''''-01 '''', 121) '' 
	end + '' timegroup'' + case @CamAgt when ''W'' then  '', IDWG '' when ''A'' then '', idarea '' end + @CamAgt_C + '' FROM '' + case @CamAgt when ''W'' then ''ccGenOutCallDialsWG '' when ''A'' then ''ccGenOutCallDialsWG nr, ccRIAAreaWorkGroup awg '' end + '' WHERE'' + 

	case @CamAgt 
	when ''W'' then  + case 
		when @cbjUno <> '''' and @CblDos <> '''' then '' idwg in ('' + @cbjUno  + '') '' + '' and tipoResDial_id IN ('' + @CblDosTmp + '') and ''
		when @cbjUno <> '''' and @CblDos = '''' then '' idwg in ( '' + @cbjUno  + '') and ''
		else '''' end
	when ''A'' then + case 
		when @cbjUno <> '''' and @CblDos <> '''' then '' idarea in ('' + @cbjUno  + '') '' + '' and tipoResDial_id IN ('' + @CblDosTmp + '') and ''
		when @cbjUno <> '''' and @CblDos = '''' then '' idarea in ( '' + @cbjUno  + '') and ''
		else '''' end 
	end +
case @CamAgt when ''W'' then '''' when ''A'' then'' nr.idwg = awg.idwg and '' end

+ '' timegroup >= '''''' + @fini + '''''' AND timegroup < '''''' + @ffin + '''''' GROUP BY '' +

	case @DateG 
		when ''H'' then '' timegroup '' 
		when ''D'' then '' CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) '' 
		when ''P'' then '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +''''-01 '''', 121)'' 
	end + case @CamAgt when ''W'' then  '', IDWG '' when ''A'' then '', idarea '' end +

case @CamAgt when ''W'' then  '') xDetail inner JOIN ccRIACat_WorkGroup wg ON xDetail.IDWG=wg.IDWG order by WGName, timegroup '' 
			 when ''A'' then '') xDetail inner JOIN ccRIACat_Areas ON (xDetail.idarea = ccRIACat_Areas.idarea) order by areaName, timegroup '' end 

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

 	set @Sql='update exp_jobs set active = 0 where description = ''Borra destino'''
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenAgentStatusSepHour]
@start_date	datetime,
@end_date	datetime
AS
BEGIN
SET NOCOUNT ON
	DECLARE @user_id smallint,
		@status_id	tinyint,
		@duracion	int,
		@timetot	int,
		@end_time	datetime,
		@start_time	datetime,
		@base_hour	datetime,
		@duracion_rest	int,
		@sql as varchar (8000),
		@full_hours	int,
		@cur_hour	int

	DECLARE Log_Cursor CURSOR FOR
	SELECT [user_id], tipostatusage_id, tstatus, fecha
		, DATEADD(s, -tstatus, fecha) AS start
		FROM ccLogAgentesDia 
		WHERE  fecha > DATEADD(hh, 1, CONVERT(datetime, CONVERT(varchar(13), DATEADD(ss, -tstatus, fecha), 121) + '':00'', 121))
			AND fecha between @start_date and @end_date
		ORDER BY fecha
	
	OPEN Log_Cursor
	FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time

	WHILE @@fetch_status = 0 
	BEGIN
		SELECT @base_hour = DATEADD(hh, 1, CONVERT(datetime, CONVERT(varchar(13), @start_time, 121) + '':00'', 121))
		SELECT @duracion_rest = DATEDIFF(s, @base_hour, @end_time)
		SELECT @full_hours = @duracion_rest / 3600
		select @timetot = @duracion
	
		set @sql = ''INSERT INTO ccLogAgentesDia ([user_id], tipostatusage_id, tstatus, fecha) VALUES ('' + convert(varchar(5),@user_id) +  '','' + convert(varchar(5),@status_id) + '','' + convert(varchar(5),convert(int,DATEDIFF(s, @start_time, @base_hour)))+ '','' + char(0x27) + convert(varchar(24),@base_hour,121) + char(0x27) + '')''
		exec sp_sqlexec @sql

		select @timetot = @timetot - DATEDIFF(s, @start_time, @base_hour)
		SELECT @cur_hour = 1

		WHILE @cur_hour <= @full_hours
		BEGIN
			set @sql = ''INSERT INTO ccLogAgentesDia ([user_id], tipostatusage_id, tstatus, fecha) VALUES ('' + convert(varchar(5),@user_id) +  '','' + convert(varchar(5),@status_id) + '', 3600,'' + char(0x27) + convert(varchar(24),DATEADD(hh, @cur_hour, @base_hour),121) + char(0x27) + '')''
			exec sp_sqlexec @sql

			select @timetot = @timetot - 3600
			SELECT @cur_hour = @cur_hour + 1
		END

		set @sql = ''UPDATE ccLogAgentesDia SET tstatus = ('' + convert(varchar(10),@timetot) + '' % 3600) WHERE [user_id]='' + convert(varchar(5),@user_id) + '' AND tipostatusage_id='' + convert(varchar(5),@status_id) + '' AND fecha= '' + char(0x27) + convert(varchar(24),@end_time,121) + char(0x27) + ''''

		exec sp_sqlexec @sql
		FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time
	END
	CLOSE Log_Cursor
	DEALLOCATE Log_Cursor
SET NOCOUNT OFF
END
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenAgentStatusSepHourNotReady]
@start_date	datetime,
@end_date	datetime
AS
BEGIN
	DECLARE @user_id smallint,
		@status_id	tinyint,
		@duracion	int,
		@timetot	int,
		@end_time	datetime,
		@start_time	datetime,
		@base_hour	datetime,
		@sql as varchar (8000),
		@duracion_rest	int,
		@full_hours	int,
		@cur_hour	int

	DECLARE Log_Cursor CURSOR FOR
	SELECT [user_id], tiponotready_id, tstatus, fecha
		, DATEADD(s, -tstatus, fecha) AS start
		FROM ccLogAgentesNotReady 
		WHERE  fecha > DATEADD(hh, 1, CONVERT(datetime, CONVERT(varchar(13), DATEADD(ss, -tstatus, fecha), 121) + '':00'', 121))
			AND fecha between @start_date and @end_date
		ORDER BY fecha
	
	OPEN Log_Cursor
	FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time

	WHILE @@fetch_status = 0 
	BEGIN
		SELECT @base_hour = DATEADD(hh, 1, CONVERT(datetime, CONVERT(varchar(13), @start_time, 121) + '':00'', 121))
		SELECT @duracion_rest = DATEDIFF(s, @base_hour, @end_time)
		SELECT @full_hours = @duracion_rest / 3600
		select @timetot = @duracion
	
		set @sql = ''INSERT INTO ccLogAgentesNotReady ([user_id], tiponotready_id, tstatus, fecha, separado) VALUES ('' + convert(varchar(5),@user_id) +  '','' + convert(varchar(5),@status_id) + '','' + convert(varchar(5),convert(int,DATEDIFF(s, @start_time, @base_hour)))+ '','' + char(0x27) + convert(varchar(24),@base_hour,121) + char(0x27) + '', 3)''
		exec sp_sqlexec @sql

		select @timetot = @timetot - DATEDIFF(s, @start_time, @base_hour)
		SELECT @cur_hour = 1
		
		WHILE @cur_hour <= @full_hours
		BEGIN
			set @sql = ''INSERT INTO ccLogAgentesNotReady ([user_id], tiponotready_id, tstatus, fecha, separado) VALUES ('' + convert(varchar(5),@user_id) + '','' + convert(varchar(5),@status_id) + '', 3600,'' + char(0x27) + convert(varchar(24),DATEADD(hh, @cur_hour, @base_hour),121) + char(0x27) + '', 2)''
			exec sp_sqlexec @sql

			select @timetot = @timetot - 3600
			SELECT @cur_hour = @cur_hour + 1
		END

		set @sql = ''UPDATE ccLogAgentesNotReady SET tstatus = ('' + convert(varchar(10),@timetot) + '' % 3600), separado = 1 WHERE [user_id]= '' + convert(varchar(5),@user_id) + '' AND tiponotready_id= '' + convert(varchar(5),@status_id) + '' AND fecha= '' + char(0x27) + convert(varchar(24),@end_time,121) + char(0x27) + '' AND separado =0''
		exec sp_sqlexec @sql

		FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time
	END
	CLOSE Log_Cursor
	DEALLOCATE Log_Cursor
END'
	EXEC(@Sql)

-------------estaba como version 11 -------------------

	set @Sql='CREATE TABLE [dbo].[ccRIAWorkGroup_Calid](
	[IDWG] [smallint] NOT NULL,
	[cal_id] [int] NULL,
	[User_id] [int] NOT NULL,
	[timestamp] [datetime] NOT NULL,
	[tipo] [int] NOT NULL
) ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX IX_WGCal_id ON dbo.ccRIAWorkGroup_Calid (IDWG)'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[ccRIAWorkGroup_logdial_id](
	[IDWG] [smallint] NOT NULL,
	[logdial_id] [int] NULL,
	[CAM_ID] [smallint] NOT NULL,
	[timestamp] [datetime] NOT NULL
) ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX IX_WGlogDial_id ON dbo.ccRIAWorkGroup_logDial_id (IDWG)'
	EXEC(@Sql)

	set @Sql='drop table ccGenWorkGroup_Calid'
	EXEC(@Sql)

	set @Sql='drop table ccGenWorkGroup_logdial_id'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInCallWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

DELETE FROM ccGenInCallWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInCallWG (timegroup,idwg,ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer
	, nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
SELECT timegroup,idwg,ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
 FROM (SELECT xDetailTime.timegroup, xDetailTime.idwg
			, ISNULL(ntotal, 0) AS ntotal, ISNULL(initial, 0) AS ninitial, ISNULL(out_hour, 0) AS nout_hour, ISNULL(out_service, 0) AS nout_service
			, ISNULL(abnd, 0) AS nabnd, ISNULL(no_agent, 0) AS nno_agent, ISNULL(que, 0) AS nque, ISNULL(timeout, 0) AS ntimeout
			, ISNULL(overflow, 0) AS noverflow, ISNULL(xfer, 0) AS nxfer, ISNULL(xfer_que, 0) AS nxfer_que
			, ISNULL(abnd_xfer, 0) AS nabnd_xfer, ISNULL(abnd_ring, 0) AS nabnd_ring, ISNULL(no_answer, 0) AS nno_answer
			, ISNULL(abnd_dialog, 0) AS nabnd_dialog, ISNULL(answer, 0) AS nanswer, ISNULL(lost, 0) AS nlost, ISNULL(msg, 0) AS nmsg
			, ISNULL(abnd_tres, 0) AS nabnd_tres, ISNULL(answ_tres, 0) AS nansw_tres, ISNULL(tque_max, 0) AS tque_max
			, xDetailTime.tque, xDetailTime.txfer, xDetailTime.tring, xDetailTime.tdialog, xDetailTime.tnotes, ISNULL(tresp, 0) AS tresp,ISNULL(nMoh,0)AS nMoh
			,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM (SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup,wg.idwg
					, COUNT(ci.cal_id) AS ntotal
					, COUNT(CASE WHEN statuscall_id = 1 THEN 1 ELSE NULL END) AS initial
					, COUNT(CASE WHEN statuscall_id = 2 THEN 1 ELSE NULL END) AS out_hour 
					, COUNT(CASE WHEN statuscall_id = 3 THEN 1 ELSE NULL END) AS out_service
					, COUNT(CASE WHEN(statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = ''1900-01-01 00:00:00'')) THEN 1 ELSE NULL END) AS abnd 
					, COUNT(CASE WHEN(statuscall_id = 4) THEN 1 ELSE NULL END) AS no_agent
					, COUNT(CASE WHEN(cal_que > 0) THEN 1 ELSE NULL END) AS que 
					, COUNT(CASE WHEN(statuscall_id = 7) THEN 1 ELSE NULL END) AS timeout
					, COUNT(CASE WHEN(statuscall_id = 8) THEN 1 ELSE NULL END) AS overflow
					, COUNT(CASE WHEN((statuscall_id in (11,15,13,16)) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'')) THEN 1 ELSE NULL END) AS xfer
					, COUNT(CASE WHEN((cal_que > 0) and (statuscall_id in (11,15,13,16) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00''))) THEN cal_xfer ELSE NULL END) AS xfer_que
					, COUNT(CASE WHEN((statuscall_id = 11) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'')) THEN 1 ELSE NULL END) AS abnd_xfer
					, COUNT(CASE WHEN((statuscall_id = 15) AND (cal_tring <= @tresRing)) THEN 1 ELSE NULL END) AS abnd_ring
					, COUNT(CASE WHEN((statuscall_id = 15) AND (cal_tring > @tresRing)) THEN 1 ELSE NULL END) AS no_answer
					, COUNT(CASE WHEN((statuscall_id = 13) AND (cal_tdialog  <= @tresDialog)) THEN 1 ELSE NULL END) AS abnd_dialog
					, COUNT(CASE WHEN((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
					, COUNT(CASE WHEN(statuscall_id = 16) THEN 1 ELSE NULL END) AS lost
					, COUNT(CASE WHEN(statuscall_id IN (9, 10, 12, 14)) THEN 1 ELSE NULL END) AS msg
					, COUNT(CASE WHEN((statuscall_id IN (5,6) AND cal_que > 0 AND cal_xfer = ''1900-01-01 00:00:00'') AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS abnd_tres
					, COUNT(CASE WHEN((statuscall_id = 13 AND cal_tdialog > @tresDialog) AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS answ_tres
					, ISNULL(MAX(cal_twait), 0) AS tque_max,ISNULL(SUM(cal_twait), 0) AS tque
					, ISNULL(SUM(cal_txfer), 0) AS txfer,ISNULL(SUM(cal_tdialog), 0) AS tdialog
					, ISNULL(SUM(cal_tnotas), 0) AS tnotes,ISNULL(SUM(cal_tring), 0) AS tring
					, ISNULL(SUM(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN (cal_twait + cal_txfer + cal_tring) ELSE NULL END), 0) AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
					,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccCallsIn ci, ccRIAWorkGroup_Calid wg
					WHERE wg. cal_id = ci.cal_id and wg.tipo = 0 and cal_inicio >= @fromExtended AND  cal_inicio < @to AND wg.idwg > 0
				 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), wg.idwg
			) xDetailCount
			LEFT JOIN
			(
				SELECT timegroup
					, idwg
					, ISNULL(SUM(cal_twait), 0) AS tque
					, ISNULL(SUM(cal_txfer), 0) AS txfer
					, ISNULL(SUM(cal_tring), 0) AS tring
					, ISNULL(SUM(cal_tdialog), 0) AS tdialog
					, ISNULL(SUM(cal_tnotas), 0) AS tnotes
				 FROM (	SELECT timegroup, idwg
						, CASE WHEN time_endque < timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss, timegroup_next, time_endque) END AS cal_twait
						, CASE WHEN (time_ring < timegroup_next) THEN cal_txfer WHEN ((time_ring >= timegroup_next) AND (time_endque < timegroup_next)) THEN cal_txfer - DATEDIFF(ss, timegroup_next, time_ring) ELSE 0 END  AS cal_txfer
						, CASE WHEN (time_dialog < timegroup_next) THEN cal_tring WHEN ((time_dialog >= timegroup_next) AND (time_ring < timegroup_next)) THEN cal_tring - DATEDIFF(ss, timegroup_next, time_dialog) ELSE 0 END  AS cal_tring
						, CASE WHEN (time_notes < timegroup_next) THEN cal_tdialog WHEN ((time_notes >= timegroup_next) AND (time_dialog < timegroup_next)) THEN cal_tdialog - DATEDIFF(ss, timegroup_next, time_notes) ELSE 0 END  AS cal_tdialog
						, CASE WHEN (time_end_call < timegroup_next) THEN cal_tnotas WHEN ((time_end_call >= timegroup_next) AND (time_notes < timegroup_next)) THEN cal_tnotas - DATEDIFF(ss, timegroup_next, time_end_call) ELSE 0 END  AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
								, DATEADD(hh, 1, CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121))  AS timegroup_next
								, DATEADD(ss, cal_twait, cal_inicio)  AS time_endque
								, DATEADD(ss, cal_twait + cal_txfer, cal_inicio)  AS time_ring
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring, cal_inicio)  AS time_dialog
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_inicio)  AS time_notes
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas, cal_inicio)  AS time_end_call
								, ci.*, wg.idwg
							FROM ccCallsIn ci, ccRIAWorkGroup_Calid wg
							WHERE wg.cal_id = ci.cal_id and wg.tipo = 0 and cal_inicio >= @fromExtended AND  cal_inicio < @to  AND wg.idwg > 0
						) xDetail
					UNION
					SELECT timegroup_next, idwg
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
								, ci.*, wg.idwg
							FROM ccCallsIn ci, ccRIAWorkGroup_Calid wg
							WHERE wg.cal_id = ci.cal_id and wg.tipo = 0 and cal_inicio >= @fromExtended AND  cal_inicio < @to  AND wg.idwg > 0
						) xDetail
					) xTimeDetail
				 GROUP BY timegroup, idwg
			) xDetailTime
			ON (xDetailTime.timegroup = xDetailCount.timegroup AND xDetailTime.idwg = xDetailCount.idwg)
	) xComplete
 WHERE timegroup >= @from AND  timegroup < @to
	AND NOT (ntotal = 0 AND nout_hour = 0 AND nout_service = 0 AND nabnd = 0 AND nno_agent = 0 AND nque = 0
		 AND ntimeout = 0 AND noverflow = 0 AND nxfer = 0 AND nxfer_que = 0 AND nabnd_xfer = 0 AND nabnd_ring = 0
		 AND nno_answer = 0 AND nabnd_dialog = 0 AND nanswer = 0 AND nlost = 0 AND nmsg = 0 AND nabnd_tres = 0
		 AND nansw_tres = 0 AND tque_max = 0 AND tque = 0 AND txfer = 0 AND tring = 0 AND tdialog = 0 AND tnotes = 0 AND tresp = 0)
 ORDER BY timegroup, idwg
'
	EXEC(@Sql)

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

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInAbndWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenInAbndWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInAbndWG (timegroup, idwg, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
	SELECT timegroup
		, idwg
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
				, wg.idwg
				, statuscall_id
				, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
				, (cal_twait + cal_txfer + cal_tring) AS tAbnd
			 FROM ccCallsIn ci, ccRIAWorkGroup_Calid wg
				WHERE cal_inicio >= @from AND  cal_inicio < @to and wg.cal_id = ci.cal_id and wg.tipo = 0
				AND wg.idwg > 0
		) xCalls
	WHERE (abnd IS NOT NULL) 
	 GROUP BY timegroup, idwg'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInAnswWG]
@from AS smalldatetime,
@to AS smalldatetime
AS
DECLARE @tresDialog AS smallint

EXEC @tresDialog = ccspConfigTresDialog

DELETE ccGenInAnswWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInAnswWG (timegroup, idwg, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
	SELECT timegroup
		, idwg
		, COUNT(cal_inicio) AS amount
		, MAX(tAnsw) AS time_max
		, SUM(tAnsw) AS time_tot
		, COUNT(CASE WHEN tAnsw < 10  THEN 1 ELSE NULL END) as [<10]
		, COUNT(CASE WHEN tAnsw BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [<20]
		, COUNT(CASE WHEN tAnsw BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [<30]
		, COUNT(CASE WHEN tAnsw BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [<40]
		, COUNT(CASE WHEN tAnsw BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [<50]
		, COUNT(CASE WHEN tAnsw BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [<60]
		, COUNT(CASE WHEN tAnsw BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [<120]
		, COUNT(CASE WHEN tAnsw BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [<180]
		, COUNT(CASE WHEN tAnsw BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [<240]
		, COUNT(CASE WHEN tAnsw BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [<300]
		, COUNT(CASE WHEN tAnsw >= 300  THEN 1 ELSE NULL END) as [+300]
	 FROM	(
			SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
				, cal_inicio
				, wg.idwg
				, statuscall_id
				, (CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
				, (cal_twait + cal_txfer + cal_tring) AS tAnsw
			 FROM ccCallsIn ci, ccRIAWorkGroup_Calid wg
				WHERE cal_inicio >= @from AND  cal_inicio < @to and wg.cal_id = ci.cal_id and wg.tipo = 0
				AND wg.idwg > 0
		) xCalls
	 WHERE (answer IS NOT NULL)
	 GROUP BY timegroup, idwg
'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInCalifWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenInCalifWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInCalifWG (timegroup, idwg, calif_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, wg.idwg, calif_id, COUNT(cal_inicio)
 FROM ccCallsIN ci, ccRIAworkgroup_calid wg
 WHERE cal_inicio >= @from AND  cal_inicio < @to
 AND statuscall_id = 13 and ci.cal_id = wg.cal_id and wg.tipo = 0
AND wg.idwg > 0
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), wg.idwg, calif_id
'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCallWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DECLARE @HourExtend AS smallint
SELECT @HourExtend=2
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog

DELETE FROM ccGenOutCallWG WHERE timegroup>=@from AND timegroup<@to

INSERT INTO ccGenOutCallWG (timegroup,idwg,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl)
SELECT timegroup,idwg,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
 FROM(		
		SELECT xDetailTime.timegroup,xDetailTime.idwg
			,ISNULL(ntotal,0)AS ntotal
			,ISNULL(no_agent,0)AS nno_agent,ISNULL(xfer,0)AS nxfer
			,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost
			,xDetailTime.txfer,xDetailTime.tring
			,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp
			,ISNULL(hung_up,0)AS nhangup,ISNULL(nMoh,0) as nMoh,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM(	 
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,wg.idwg
					,COUNT(co.cal_id)AS ntotal
					,COUNT(CASE WHEN(statuscall_id=6)THEN co.cal_id ELSE NULL END)AS hung_up --NO se usa,así que es igual a total para las llamadas sin agente asignada(->agente 0)
					,COUNT(CASE WHEN(statuscall_id=4)THEN co.cal_id ELSE NULL END)AS no_agent
					,COUNT(CASE WHEN(statuscall_id>=10)THEN co.cal_id ELSE NULL END)AS xfer
					,COUNT(CASE WHEN(statuscall_id=11)THEN co.cal_id ELSE NULL END)AS abnd_xfer
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN co.cal_id ELSE NULL END)AS abnd_ring
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN co.cal_id ELSE NULL END)AS no_answer
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN co.cal_id ELSE NULL END)AS abnd_dialog
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN co.cal_id ELSE NULL END)AS answer
					,COUNT(CASE WHEN(statuscall_id=16)THEN co.cal_id ELSE NULL END)AS lost
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
					,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccoCallsOut co, ccRIAworkgroup_calid wg
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to and co.cal_id = wg.cal_id and wg.tipo = 1
					-- para contar bien las llamadas manuales
					and cal_manual in(0,2)
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),wg.idwg
			)xDetailCount
			LEFT JOIN
			(SELECT timegroup
					, idwg
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(cal_tring),0)AS tring
					,ISNULL(SUM(cal_tdialog),0)AS tdialog
					,ISNULL(SUM(cal_tnotas),0)AS tnotes
				 FROM(	SELECT timegroup,0 as idwg
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
							FROM ccoCallsOut co
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							and cal_manual in(0,2)
						)xDetail
					UNION
					SELECT timegroup_next, idwg
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
								,co.* , wg.idwg
							FROM ccoCallsOut co, ccRIAworkgroup_calid wg
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to and co.cal_id = wg.cal_id and wg.tipo = 1
							and cal_manual in(0,2)
						)xDetail
					)xTimeDetail
				 GROUP BY timegroup, idwg
			)xDetailTime
			ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.idwg=xDetailCount.idwg)
	)xComplete
 WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nno_agent=0
		 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		 AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
 ORDER BY timegroup,idwg
'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCampWG]
@from AS smalldatetime,
@to AS smalldatetime
AS
set nocount on

DELETE ccGenOutCampWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCampWG (timegroup, idwg, pos_tot, pos_time, pos_efect)
SELECT timegroup, idwg
	, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
FROM ccGenAgent INNER JOIN 
	(select distinct wg.user_id, wg.idwg, co.cam_id from ccRIAWorkGroup_Calid wg, ccocallsout co where wg.cal_id = co.cal_id and wg.tipo = 1 and co.cal_inicio >= @from AND co.cal_inicio < @to)as wgs 
	ON (ccGenAgent.[user_id] = wgs.[user_id])
WHERE timegroup >= @from AND timegroup < @to
GROUP BY timegroup, idwg

return(0)
set nocount off'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCallCalifWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenOutCallCalifWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCallCalifWG (timegroup, idwg, calif_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup, wg.idwg, calif_id, COUNT(*)
 FROM ccoCallsOut co, ccRIAworkgroup_calid wg
 WHERE cal_inicio >= @from AND  cal_inicio < @to and co.cal_id = wg.cal_id and wg.tipo = 1
 AND statuscall_id = 13
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), wg.idwg, calif_id
'
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
 FROM ccologdials ld, ccRIAWorkGroup_logDial_id wg
 WHERE fecha >= @from AND  fecha < @to
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + '':00'', 121), idwg, [puerto], tiporesdial_id'
	EXEC(@Sql)

 	set @Sql='update Exp_Jobs set readquery= ''declare @server varchar(200)
declare @sql  varchar(8000)
declare @from datetime
declare @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @calIniOut as varchar(15)
declare @calFinOut as varchar(15)
declare @calIniIn as varchar(15)
declare @calFinIn as varchar(15)

select @calIniIn = isnull(max(cal_id),1)  from '''' + @server +''''.dbo.ccRIAWorkGroup_Calid  WITH(NOLOCK) WHERE tipo = 0
select @calFinIn = min(cal_id) from (select isnull(min(cal_id),0) cal_id from ccRIAWorkGroup_Calid WITH(NOLOCK) where [timestamp] > '''' + char(0x27) + convert(varchar(20),@to,120) + char(0x27) + ''''and tipo = 0 union all select max(cal_id) cal_id from ccRIAWorkGroup_Calid WITH(NOLOCK) WHERE tipo = 0) as a where cal_id <> 0
select @calIniOut = isnull(max(cal_id),1) from '''' + @server +''''.dbo.ccRIAWorkGroup_Calid WITH(NOLOCK) WHERE tipo = 1
select @calfinOut = min(cal_id) from (select isnull(min(cal_id),0) cal_id from ccRIAWorkGroup_Calid WITH(NOLOCK) where [timestamp] > '''' + char(0x27) + convert(varchar(20),@to,120) + char(0x27) + '''' and tipo = 1 union all select max(cal_id) cal_id from ccRIAWorkGroup_Calid WITH(NOLOCK) WHERE tipo = 1) as a where cal_id <> 0
''''

set @sql = @sql + ''''select IDWG, cal_id, [user_id], [timestamp], tipo from ccRIAWorkGroup_Calid WITH(NOLOCK) WHERE cal_id > @calIniOut and cal_id<= @calfinOut and tipo = 1''''
set @sql = @sql + '''' union all select IDWG, cal_id, [user_id], [timestamp], tipo from ccRIAWorkGroup_Calid WITH(NOLOCK) WHERE cal_id > @calIniIn and cal_id<= @calfinIn and tipo = 0''''

--print @sql
exec(@sql)

exec ccsp_LogInfo @sql, -19'' ,writequery = ''ccRIAWorkGroup_Calid'' where description = ''ccGenWorkGroup_Calid''
'
	EXEC(@Sql)

 	set @Sql='update Exp_Jobs set readquery = ''declare @server varchar(200)
declare @sql  varchar(8000)
declare @from datetime
declare @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @logIni as varchar(15)
declare @logFin as varchar(15)
select @logIni = isnull(max(logDial_ID),0) from '''' + @server +''''.dbo.ccRIAWorkGroup_logdial_id WITH(NOLOCK)
select @logFin = min(logdial_id) from (select isnull(min(logDial_ID),0) logdial_id from ccRIAWorkGroup_logdial_id with(NOLOCK) where [timestamp] > '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '''' union all select max(logDial_id) logdial_id from ccRIAWorkGroup_logdial_id WITH(NOLOCK)) as a where logdial_id <> 0
''''
set @sql = @sql + ''''select IDWG, logdial_id,cam_id, [timestamp] from ccRIAWorkGroup_logdial_id WITH(NOLOCK) where logDial_ID > @logIni AND logDial_ID <= @logFin''''
--print @sql
exec(@sql)

exec ccsp_LogInfo @sql, -19'' ,writequery = ''ccRIAWorkGroup_logdial_id''
where description = ''ccGenWorkGroup_logdial_id''
'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccRIAAreaWorkGroup
	DROP CONSTRAINT PK_ccRIAAreaWorkGroup'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccRIAAreaWorkGroup ADD CONSTRAINT
	PK_ccRIAAreaWorkGroup PRIMARY KEY CLUSTERED 
	(
	IDWG,
	IDArea
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
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


