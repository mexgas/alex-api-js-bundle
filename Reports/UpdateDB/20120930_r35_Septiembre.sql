/*
Autor: Raymundo González y Armando Rodríguez
Fecha: 2012/09/30
Descripcion: 
	Se inserta registro en la tabla exportReports para exportar los datos de IVRStructure
	Se modifica el SP ccRepOutPortStats para tomar configuración de idioma
	Se crea la tabla IVRStructure para almacenar la estructura del IVR
	Se crea el SP ccspGenInfo para regenerar la información de reportes
	Se modifica el SP ccsp_reportInRejectCall para fix

Version requerida: 34
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '35'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @Sql = 'insert into exportReports values(227,4,180,''IVRStructure'','''','''',''IdScript,Level,Description'',0)'

	EXEC(@Sql)

		set @Sql = 'ALTER PROCEDURE [dbo].[ccRepOutPortStats]
@fini as varchar(20),
@ffin as varchar(20),
@DateG as varchar(20),
@CamGral as varchar(20),
@cbjUno as varchar(500),
@tipo as tinyint,
@cbjDos as varchar(500) --0 inbound, 1 outbound
as
set nocount on

DECLARE @sGroupDetail as varchar(105), @Sql varchar(max), @ddif as smallint, @idioma as smallint, @desde as varchar(4), @hasta as varchar(4)

select @desde = ltrim(rtrim(Substring(@cbjDos,1,Charindex(''-'',@cbjDos)-1)))
select @hasta = ltrim(rtrim(Substring(@cbjDos,Charindex(''-'',@cbjDos)+len(''-''),len(@cbjDos))))

select @ddif = datediff(dd,@fini,@ffin)
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23
select @DateG = case when @DateG =''Por Medias Hrs'' or @DateG =''Half Hour'' then ''H'' 
					 when @DateG =''Por Día'' or @DateG =''Day'' then ''D'' 
					 when @DateG =''Por Hora'' or @DateG =''Hour'' then ''O'' end

select @CamGral = case when @CamGral =''Campaña'' or @CamGral =''Campaign'' or @CamGral =''Especialidad'' or @CamGral =''ACD group'' then ''C'' 
					   when @CamGral =''General'' or @CamGral =''All Information'' then ''G'' end

set @Sql=''select '' + case @DateG when ''H'' then '' convert(varchar(21),timegroup,121) '' when ''D'' then '' CONVERT(varchar(10), timegroup, 121) + '''' 00:00:00'''' '' when ''O'' then '' CONVERT(varchar(13), timegroup, 121) + '''':00:00'''' '' end + '' [Fecha] '' + 
case @tipo when 1 then
case @CamGral when ''C'' then '',c.cam_descripcion as [Campana], dia.descripcion as [Pto]'' when ''G'' then '',dia.descripcion as [Pto]'' end
else
case @CamGral when ''C'' then '',c.descripcion as [Grupo ACD], dia.descripcion as [Pto]'' when ''G'' then '',dia.descripcion as [Pto]'' end end+
'', dbo.fGetHHmmSS(sum(tBusy)) as [Tiempo Ocupado], sum(Calls) as [Llamadas], dbo.fPorcentaje(sum(tBusy),'' +
case @DateG when ''H'' then ''1800'' when ''D'' then ''86400'' when ''O'' then ''3600'' end + '') as [% Ocupacion] from ccGenOutPortStats ps'' +
case @tipo when 1 then
case @CamGral when ''C'' then '' left join cccamps c on (ps.cam_id = c.cam_id)'' when ''G'' then '''' end
else 
case @CamGral when ''C'' then '' left join ccinbound c on (ps.cam_id = c.inbound_id)'' when ''G'' then '''' end end + '' left join ccoDialers dia on (dia.puerto = ps.port) where'' +
case when @cbjUno <> '''' then '' ps.cam_id in ('' + @cbjUno + '') and'' else '''' end + case when replace(@cbjDos,''-'','''') <> '''' then '' ps.port between '' + @desde + '' and ''+ @hasta +'' and'' else '''' end + case when @tipo < 2 then '' tipo = '' + convert(varchar(3),@tipo) + '' and'' else '''' end  + '' timegroup >= '''''' + @fini + '''''' AND timegroup < '''''' + @ffin + '''''' group by '' +
case @DateG when ''H'' then '' timegroup '' when ''D'' then '' CONVERT(varchar(10), timegroup, 121) + '''' 00:00:00'''' ''  when ''O'' then '' CONVERT(varchar(13), timegroup, 121) + '''':00:00'''' '' end +
case @tipo when 1 then
case @CamGral when ''C'' then '',c.cam_descripcion,dia.descripcion'' when ''G'' then '',dia.descripcion'' end 
else
case @CamGral when ''C'' then '',c.descripcion,dia.descripcion'' when ''G'' then '',dia.descripcion'' end end

set @Sql = @Sql + ''
Union all
 select '''''''' as [Fecha]'' +
case @tipo when 1 then
case @CamGral when ''C'' then '','''''''' as [Campana], ''''Total'''' as [Puerto]'' when ''G'' then '',''''Total'''' as [Pto]'' end
else
case @CamGral when ''C'' then '','''''''' as [Grupo ACD], ''''Total'''' as [Puerto]'' when ''G'' then '',''''Total'''' as [Pto]'' end end +
'', dbo.fGetHHmmSS(sum(tBusy)) as [Tiempo Ocupado], sum(Calls) as [Llamadas], dbo.fPorcentaje(sum(tBusy),datediff(ss,'''''' + @fini + '''''','''''' + @ffin + '''''')) as [% Ocupacion] from ccGenOutPortStats ps'' +
case @tipo when 1 then
case @CamGral when ''C'' then '' left join cccamps c on (ps.cam_id = c.cam_id)'' when ''G'' then '''' end
else 
case @CamGral when ''C'' then '' left join ccinbound c on (ps.cam_id = c.inbound_id)'' when ''G'' then '''' end end + '' left join ccoDialers dia on (dia.puerto = ps.port) where'' +
case when @cbjUno <> '''' then '' ps.cam_id in ('' + @cbjUno + '') and'' else '''' end + case when replace(@cbjDos,''-'','''') <> '''' then '' ps.port between '' + @desde + '' and ''+ @hasta +'' and'' else '''' end + case when @tipo < 2 then '' tipo = '' + convert(varchar(3),@tipo) + '' and'' else '''' end  + '' timegroup >= '''''' + @fini + '''''' AND timegroup < '''''' + @ffin + '''''' ''

if @idioma = 1
begin
	set @Sql = replace(@Sql, ''Fecha'', ''Date'') 
	set @Sql = replace(@Sql, ''Campana'', ''Campaign'')
	set @Sql = replace(@Sql, ''Pto'', ''Port'') 
	set @Sql = replace(@Sql, ''Llamadas'', ''Call'') 
	set @Sql = replace(@Sql, ''Ocupacion'', ''Ocupation'')
	set @Sql = replace(@Sql, ''Grupo ACD'', ''ACD Group'') 
	set @Sql = replace(@Sql, ''Tiempo Ocupado'',''Busy Time'')
end
if @idioma = 0
begin
	set @Sql = replace(@Sql, ''Pto'', ''Puerto'') 
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
set nocount off'
	
	EXEC(@Sql)

 		set @Sql = 'CREATE TABLE [dbo].[IVRStructure](
	[IdScript] [tinyint] NOT NULL,
	[Level] [varchar](50) NOT NULL,
	[Description] [varchar](100) NULL
) ON [PRIMARY]'

	EXEC(@Sql)

		set @Sql = 'create PROCEDURE dbo.ccspGenInfo
AS
set nocount on
declare @start datetime, @end datetime 

declare @dbname varchar(50)
declare @server varchar(50)
select @dbname = db_name(dbid) from master..sysprocesses where spid=@@SPID 
BACKUP LOG @dbName TO DISK=''NUL:''

select @server = valor from ccsettings where setting_id = 22

-- Poner fechas aqui
SELECT @start = convert(smalldatetime,convert(varchar(11),dateadd(d,-1,getdate()),121)+ ''00:00:00'',121)
SELECT @end = convert(smalldatetime,convert(varchar(11),dateadd(dd,-1,getdate()),121)+ ''23:59:00'',121)

EXEC ccspGenSession @start, @end
EXEC ccspGenInCall @start, @end
EXEC ccspGenInCallDNI @start, @end
EXEC ccspGenOutCall @start, @end

EXEC ccspGenAgentStatusSepHour @start, @end
EXEC ccspGenAgent @start, @end
EXEC ccspGenAgentStatusSepHourNotReady @start, @end
EXEC ccspGenAgentStatusNotReady  @start, @end

EXEC ccspGenInSpec @start, @end
EXEC ccspGenInAbnd @start, @end
EXEC ccspGenInAnsw @start, @end
EXEC ccspGenInCalif @start, @end
EXEC ccspGenoutsubcalif @start, @end
EXEC ccspGenInSubCalif @start, @end

EXEC ccspGenOutCamp @start, @end
EXEC ccspGenOutCallCalif @start, @end
EXEC ccspGenOutCallDials @start, @end

EXEC ccspGenInCallWG @start, @end
EXEC ccspGenOutCallwg @start, @end
EXEC ccspGenInSpecwg @start, @end
EXEC ccspGenInAbndwg @start, @end
EXEC ccspGenInAnswwg @start, @end
EXEC ccspGenInCalifwg @start, @end
EXEC ccspGenOutCampwg @start, @end
EXEC ccspGenOutCallCalifwg @start, @end
EXEC ccspGenOutCallDialswg @start, @end
EXEC ccspGenTelMArcados @start, @end

EXEC ccspGenOutCstoResumen @start, @end
set nocount off
'
	
	EXEC(@Sql)

		set @Sql = 'ALTER procedure [dbo].[ccsp_reportInRejectCall]
@fFin smalldatetime = null,
@fIni smalldatetime = null,
@dni_numeroS varchar(max) = null
as
set nocount on
declare @SQL varchar(max), @Where varchar(max), @dni_numeroS_MAX varchar(max), @idioma tinyint
declare @campo1 varchar(50), @campo2 varchar(50), @campo3 varchar(50), @campo4 varchar(50), @campo5 varchar(50), @campo6 varchar(50)

select @idioma = valor from ccSettings where setting_id = 23

if @idioma=0
 begin
	select @campo1=''[Numero DNIS]'', @campo2=''[Descripcion DNIS]'', @campo3=''[Descripcion Especialidad]'', @campo4=''[Fecha]'', @campo5=''[Ani]'', @campo6=''[Puerto]''
 end

else
 begin
	select @campo1=''[DNIS Number]'', @campo2=''[DNIS Description]'', @campo3=''[ACD Description]'', @campo4=''[Date]'', @campo5=''[Ani]'', @campo6=''[Port]''
 end

set @dni_numeroS_MAX=''''

set @SQL= ''select CR.dnis '' + @campo1 + '', isnull(DN.dni_descripcion, '''''''') '' + @campo2 + '', isnull(NI.descripcion, '''''''') '' + @campo3 
+ '', convert(varchar(19), cal_inicio, 121) '' + @campo4 + '', CR.ani '' + @campo5 + '', CR.puerto '' + @campo6 
+ nchar(13) + ''from ccCallsReject CR join ccDNIS DN on CR.dnis = DN.dni_numero	left join ccInbound NI on CR.Inbound_id = NI.Inbound_id''

set @Where = nchar(13) + ''Where 1=1''

if @fIni is not null
	set @Where = @Where + '' and convert(varchar(25), cal_inicio, 121) >= '''''' + convert(varchar(25), @fIni, 121) + nchar(39)

if @fFin is not null
	set @Where = @Where + '' and convert(varchar(25), cal_inicio, 121) <= '''''' + convert(varchar(25), @fFin, 121) + nchar(39)

if len(isnull(@dni_numeroS, '''')) > 1
 begin
	select @dni_numeroS = replace(@dni_numeroS,nchar(39),'''')
	select @dni_numeroS_MAX=@dni_numeroS_MAX+coalesce('',''+nchar(39)+value+nchar(39), '','')
	from dbo.fn_RIASplitDelimited(@dni_numeroS, '','')

	set @dni_numeroS_MAX=right(@dni_numeroS_MAX,len(@dni_numeroS_MAX)-1)
	set @Where = @Where + nchar(13) + '' and CR.dnis in ('' + @dni_numeroS_MAX + '')'' 
 end

set @SQL = @SQL + @Where + '' order by cal_inicio desc''

exec(@SQL)
set nocount off'
	
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
