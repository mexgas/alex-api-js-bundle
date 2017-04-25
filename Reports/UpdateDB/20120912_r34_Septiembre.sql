/*
Autor: Raymundo González
Fecha: 2012/09/12
Descripcion: 
	Se crea tabla ccoDialerCamp
	Se inserta registro de tabla ccoDialerCamp en exportreports para uso por parte del scheduler
	Modificacion del sp ccRepOutPortStats

Version requerida: 33
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '34'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @Sql='CREATE TABLE [dbo].[ccoDialerCamp](
	[dialer_id] [int] NOT NULL,
	[cam_id] [smallint] NOT NULL,
 CONSTRAINT [PK_ccodialercamp] PRIMARY KEY NONCLUSTERED 
(
	[dialer_id] ASC,
	[cam_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[ccoDialerCamp]  WITH CHECK ADD  CONSTRAINT [FK_ccoDialerCamp_ccoDialers] FOREIGN KEY([dialer_id])
REFERENCES [dbo].[ccoDialers] ([dialer_id])

ALTER TABLE [dbo].[ccoDialerCamp] CHECK CONSTRAINT [FK_ccoDialerCamp_ccoDialers]'
	
	EXEC(@Sql)

		set @Sql='insert into exportreports (jobid,jobtype,intervalminutes,tableN,idn,daten,cols,skipminutes) 
values(227,4,180,''ccoDialerCamp'','''','''',''dialer_id, cam_id'',0)'
	
	EXEC(@Sql)

		set @Sql='ALTER PROCEDURE [dbo].[ccRepOutPortStats]
@fini as varchar(20),
@ffin as varchar(20),
@DateG as varchar(20),
@CamGral as varchar(20),
@cbjUno as varchar(500),
@tipo as tinyint,
@cbjDos as varchar(500) --0 inbound, 1 outbound
as
set nocount on

DECLARE @sGroupDetail as varchar(105), @Sql varchar(max), @ddif as smallint, @idioma as smallint

select @ddif = datediff(dd,@fini,@ffin)
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23
select @DateG = case when @DateG =''Por Medias Hrs'' or @DateG =''Half Hour'' then ''H'' 
					 when @DateG =''Por Día'' or @DateG =''Day'' then ''D'' 
					 when @DateG =''Por Hora'' or @DateG =''Hour'' then ''O'' end

select @CamGral = case when @CamGral =''Campaña'' or @CamGral =''Campaign'' or @CamGral =''Especialidad'' or @CamGral =''ACD group'' then ''C'' 
					   when @CamGral =''General'' or @CamGral =''All Information'' then ''G'' end

set @Sql=''select '' + case @DateG when ''H'' then '' convert(varchar(21),timegroup,121) '' when ''D'' then '' CONVERT(varchar(10), timegroup, 121) + '''' 00:00:00'''' '' when ''O'' then '' CONVERT(varchar(13), timegroup, 121) + '''':00:00'''' '' end + '' [Fecha] '' + 
case @tipo when 1 then
case @CamGral when ''C'' then '',c.cam_descripcion as [Campana], dia.descripcion as [Puerto]'' when ''G'' then '',dia.descripcion as [Puerto]'' end
else
case @CamGral when ''C'' then '',c.descripcion as [Grupo ACD], dia.descripcion as [Puerto]'' when ''G'' then '',dia.descripcion as [Puerto]'' end end+
'', dbo.fGetHHmmSS(sum(tBusy)) as [Tiempo Ocupado], sum(Calls) as [Llamadas], dbo.fPorcentaje(sum(tBusy),'' +
case @DateG when ''H'' then ''1800'' when ''D'' then ''86400'' when ''O'' then ''3600'' end + '') as [% Ocupacion] from ccGenOutPortStats ps'' +
case @tipo when 1 then
case @CamGral when ''C'' then '' left join cccamps c on (ps.cam_id = c.cam_id)'' when ''G'' then '''' end
else 
case @CamGral when ''C'' then '' left join ccinbound c on (ps.cam_id = c.inbound_id)'' when ''G'' then '''' end end + '' left join ccoDialers dia on (dia.puerto = ps.port) where'' +
case when @cbjUno <> '''' then '' ps.cam_id in ('' + @cbjUno + '') and'' else '''' end + case when @cbjDos <> '''' then '' ps.port in ('' + @cbjDos + '') and'' else '''' end + case when @tipo < 2 then '' tipo = '' + convert(varchar(3),@tipo) + '' and'' else '''' end  + '' timegroup >= '''''' + @fini + '''''' AND timegroup < '''''' + @ffin + '''''' group by '' +
case @DateG when ''H'' then '' timegroup '' when ''D'' then '' CONVERT(varchar(10), timegroup, 121) + '''' 00:00:00'''' ''  when ''O'' then '' CONVERT(varchar(13), timegroup, 121) + '''':00:00'''' '' end +
case @tipo when 1 then
case @CamGral when ''C'' then '',c.cam_descripcion,dia.descripcion'' when ''G'' then '',dia.descripcion'' end 
else
case @CamGral when ''C'' then '',c.descripcion,dia.descripcion'' when ''G'' then '',dia.descripcion'' end end

set @Sql = @Sql + ''
Union all
 select '''''''' as [Fecha]'' +
case @tipo when 1 then
case @CamGral when ''C'' then '','''''''' as [Campana], ''''Total'''' as [Puerto]'' when ''G'' then '',''''Total'''' as [Puerto]'' end
else
case @CamGral when ''C'' then '','''''''' as [Grupo ACD], ''''Total'''' as [Puerto]'' when ''G'' then '',''''Total'''' as [Puerto]'' end end +
'', dbo.fGetHHmmSS(sum(tBusy)) as [Tiempo Ocupado], sum(Calls) as [Llamadas], dbo.fPorcentaje(sum(tBusy),datediff(ss,'''''' + @fini + '''''','''''' + @ffin + '''''')) as [% Ocupacion] from ccGenOutPortStats ps'' +
case @tipo when 1 then
case @CamGral when ''C'' then '' left join cccamps c on (ps.cam_id = c.cam_id)'' when ''G'' then '''' end
else 
case @CamGral when ''C'' then '' left join ccinbound c on (ps.cam_id = c.inbound_id)'' when ''G'' then '''' end end + '' left join ccoDialers dia on (dia.puerto = ps.port) where'' +
case when @cbjUno <> '''' then '' ps.cam_id in ('' + @cbjUno + '') and'' else '''' end + case when @cbjDos <> '''' then '' ps.port in ('' + @cbjDos + '') and'' else '''' end + case when @tipo < 2 then '' tipo = '' + convert(varchar(3),@tipo) + '' and'' else '''' end  + '' timegroup >= '''''' + @fini + '''''' AND timegroup < '''''' + @ffin + '''''' ''

if @idioma = 1
begin
	set @Sql = replace(@Sql, ''Fecha'', ''Date'') 
	set @Sql = replace(@Sql, ''Campana'', ''Campaign'')
	set @Sql = replace(@Sql, ''Puerto'', ''Port'') 
	set @Sql = replace(@Sql, ''Llamadas'', ''Call'') 
	set @Sql = replace(@Sql, ''Ocupacion'', ''Ocupation'')
	set @Sql = replace(@Sql, ''Grupo ACD'', ''ACD Group'') 
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
