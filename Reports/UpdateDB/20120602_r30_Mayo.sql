/*
Autor: Armando Rodriguez
Fecha: 2012/06/02
Descripcion: 
	se arregla el problema del reporte de KPI outbound por el que marcaba overflow
	se arrglan diferencias en los reprotes de IVR
	se arregla problema con reporte de rechazos
	se arregla problema con reporte de calificaciones outbound
	 

Version requerida: 29
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '30'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInSpecWG]
@from AS smalldatetime,
@to AS smalldatetime
AS
--set nocount on
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
--return(0)
--set nocount off'
	EXEC(@Sql)

 	set @Sql='ALTER proc [dbo].[A_cwRep2Calif_WG]
@DateG as varchar(20),	-- Por Hora, Hour, Por Día, Day, Por Periodo, Period
@CamAgt as varchar(20), -- Especialidad, ACD group, Agente, Agent, Grupo de Trabajo, WorkGroup, Area
@fini as varchar(20),	-- Fecha Inicio
@ffin as varchar(20),	-- Fecha Fin
@cbjUno as varchar(500),-- Agrega filtro por inbound_id
@CblDos as varchar(300),-- Agrega filtro por calif_id
@SupID as int=0,		-- Id de supervisor, solo filtra en workgroup y en area
@InOutCalls as bit=0	-- 0:Campa?as,Salida / 1:Especialidad,Entrada
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

 	set @Sql='alter FUNCTION [dbo].[fn_RIASplitDelimited]
(	
	@List nvarchar(2000),
	@SplitOn nvarchar(1)
)
RETURNS @RtnValue table (
	Id int identity(1,1),
	Value nvarchar(100)
)
AS
BEGIN
	While (Charindex(@SplitOn,@List)>0)
	Begin 
		Insert Into @RtnValue (value)
		Select 
			Value = ltrim(rtrim(Substring(@List,1,Charindex(@SplitOn,@List)-1))) 
		Set @List = Substring(@List,Charindex(@SplitOn,@List)+len(@SplitOn),len(@List))
	End 
	
	Insert Into @RtnValue (Value)
    Select Value = ltrim(rtrim(@List))

    Return
END
'
	EXEC(@Sql)

 	set @Sql='ALTER procedure [dbo].[ccsp_reportInRejectCall]
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
	select @dni_numeroS_MAX=@dni_numeroS_MAX+coalesce('',''+nchar(39)+value+nchar(39), '','')
	from dbo.fn_RIASplitDelimited(replace(@dni_numeroS, nchar(39), ''''), '','')

	set @dni_numeroS_MAX=right(@dni_numeroS_MAX,len(@dni_numeroS_MAX)-1)
	set @Where = @Where + nchar(13) + '' and CR.dnis in ('' + @dni_numeroS_MAX + '')'' 
 end

set @SQL = @SQL + @Where + '' order by cal_inicio desc''

exec(@SQL)
set nocount off
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspIVRInfo]
@from as varchar(20),
@to as varchar(20),
@option as tinyint

AS
declare @id AS INTEGER,@opcion as varchar(200), @ivr as varchar (200)
declare @ids as varchar(10), @pivot as varchar(2000),@isnullpivot as varchar(5000), @sql as varchar(max)

if (@option = 1)
begin
	delete from IVRLlamadas where date >= @from and date < @to 
	insert into IVRLlamadas (ivr_id,cal_ani,user_id,calif_id,cal_id, date)
	select ivr_id, cal_ani,user_id,calif_id,cal_id, date from ivr.dbo.CallsInIVR where date >= @from and date < @to
end

if (@option = 2)
begin
	select @opcion = '''',@ivr = ''''
	CREATE TABLE [dbo].[#myoptions] (
		[ivr_id] [int] NULL,
		[options] varchar(500) NULL
	) ON [PRIMARY]

	DECLARE CCivr CURSOR FOR 
		select distinct ivr_id from IVRLlamadas where date >= @from and date < @to
	Open CCivr
	Fetch Next From CCivr
	Into @id
	if @@FETCH_STATUS = 0
		Begin 
			While @@FETCH_STATUS = 0
			Begin
				select @opcion = '''',@ivr = ''''
				select @ivr= ivl.ivr_id, @opcion = @opcion +  case @opcion when '''' then '''' else '','' end + convert(varchar(50),selectedoption) from IVRLlamadas ivl left join ivroptions ivo on (ivl.ivr_id = ivo.ivr_id) where ivl.ivr_id = @id order by ivl.date
				--select @ivr= ivr_id, @opcion = @opcion +  case @opcion when '''' then '''' else '','' end + convert(varchar(50),selectedoption) from ivroptions where ivr_id = @id order by date

				INSERT #myoptions
					select @ivr,@opcion
				Fetch Next From CCivr
				Into  @id
			End
		End
	CLOSE CCivr
	DEALLOCATE CCivr

	select date as fecha,telefono, isnull(nombre,'''') Nombre, isnull(calificacion,'''') calificacion, isnull(cal_id,'''') cal_id, options as opciones, dbo.fGetHHmmSS(tiempo) tiempo from (
		select ivrs.date, ivrs.cal_ani as telefono, u.nombres + '' '' + u.apellidopaterno + '' '' + u.apellidomaterno as nombre, isnull(cal.description,ivrs.calif_id) as calificacion, cal_id, options, tiempo from
		(select ivr.ivr_id,cal_ani,user_id,calif_id,date,options,cal_id from IVRLlamadas ivr, #myoptions opt where opt.ivr_id = ivr.ivr_id) as ivrs
		left join ccusers u on (u.user_id = ivrs.user_id)
		left join cctipocalif cal on (ivrs.calif_id = cal.calif_id)
		left join (select ivr_id, datediff(ss,fec_ini,fec_fin) tiempo from(select distinct iop.ivr_id, min(ivr.date) fec_ini, max(iop.date) fec_fin from dbo.IVROptions iop, dbo.IVRLlamadas ivr where iop.ivr_id = ivr.ivr_id and iop.date >= @from and iop.date < @to group by iop.ivr_id) as a
		) as iv_ti on (iv_ti.ivr_id = ivrs.ivr_id)
		where ivrs.date >= @from and ivrs.date < @to
	) as b

	drop table #myoptions
end

if (@option = 3)
begin
	select convert(smalldatetime,convert(varchar(10),date,121),121) as fecha, sum(case when cal_id = 0 then 1 else 0 end) as [No transferidas], sum(case when cal_id > 0 then 1 else 0 end) as [Transferidas], count(*) Total
	from dbo.IVRLlamadas  where date >= @from and date < @to
	group by convert(smalldatetime,convert(varchar(10),date,121),121)
end

if (@option = 4)
begin
set @pivot = ''''
set @isnullpivot = ''''
		DECLARE CCamp CURSOR FOR 
			select distinct selectedoption from IVROptions order by 1
		Open CCamp
		Fetch Next From CCamp
		Into @ids
		if @@FETCH_STATUS = 0
			Begin 
				While @@FETCH_STATUS = 0
				Begin
					if (@pivot = '''')
					begin 
						set @pivot = ''['' + @ids + '']''
						set @isnullpivot =  ''isnull(['' + @ids + ''],0) ['' + @ids + '']''
					end
					else
					begin
						set @pivot = @pivot + '','' + ''['' + @ids + '']''
						set @isnullpivot = @isnullpivot + '','' + ''isnull(['' + @ids + ''],0) ['' + @ids + '']''
					end
					Fetch Next From CCamp
					Into  @ids
				End
			End
		CLOSE CCamp
		DEALLOCATE CCamp

		set @sql = ''select date as fecha, '' + @isnullpivot + '' from (select date,'' + @pivot + '' from (
select selectedoption, convert(smalldatetime,convert(varchar(10),opivr.date,121),121) date, count(*) cantidad from 
(select ivr_id, min(date) date from dbo.IVROptions group by ivr_id) as opivr, IVROptions ivr 
where opivr.ivr_id = ivr.ivr_id and opivr.date = ivr.date and opivr.date >= ''''''+ @from + '''''' and opivr.date < '''''' + @to + '''''' group by selectedoption,convert(smalldatetime,convert(varchar(10),opivr.date,121),121)
 ) as pba
pivot (
avg(cantidad) for selectedoption in ('' + @pivot + '')
) as pvt) as mcs''

--print (@sql)
exec (@sql)
end

if (@option = 5)
begin
	delete from IVROptions where date >= @from and date < @to 
	insert into IVROptions (IVR_id,selectedOption,date)
	select IVR_id,selectedOption,date from ivr.dbo.IVROptions where date >= @from and date < @to /*and ivr_id in (select ivr_id from IVRLlamadas where date >= convert(smalldatetime,convert(varchar(10),getdate(),121),121))*/
end
'
	EXEC(@Sql)

 	set @Sql='ALTER procedure [dbo].[ccsp_GenKPIOutbound]
@tipoGroup char(1),
@sCam_Id varchar(255), 
@fechaIni datetime, 
@fechaFin datetime
as
set nocount on
Declare @langU tinyint
select @langU = valor from ccSettings where setting_id = 23

CREATE TABLE #ccoCallsOut_Rep(
	cal_id int, cam_id smallint,
	statusCall_id tinyint, cal_tDialog smallint,
	tConnTime datetime, tBridgeTime datetime, cal_Inicio datetime,
 CONSTRAINT PK_ccoCallsOut_Temp PRIMARY KEY CLUSTERED (cal_id ASC))

insert into #ccoCallsOut_Rep
select cal_id, cam_id, statusCall_id, cal_tDialog, tConnTime, tBridgeTime, 
case @tipoGroup when ''H'' then convert(varchar(13), cal_Inicio, 121)+'':00''
when ''P'' then convert(varchar(6), cal_Inicio, 112)+''01 00:00''
else convert(varchar(8), cal_Inicio, 112)+'' 00:00'' end
from ccocallsout with(index(IX_ccoCallsOut_3))
where cal_Inicio between @fechaIni and @fechaFin and cam_id in (select value from dbo.fn_RIASplitDelimited(@sCam_Id, '',''))

declare @GenKPIOutbound as Table (a smalldatetime, b varchar(40), c int, d int, e int, f decimal(18,2), g int, h int, i int, j int, k int)

insert into @GenKPIOutbound select convert(varchar(16), Scnd.cal_Inicio, 121) cal_Inicio, Camp.cam_descripcion, Scnd.marcados, Scnd.Contactadas, 
Scnd.Abandonadas, Scnd.tAvgTrans, Scnd.ten, Scnd.twe, Scnd.tir,	isnull(Trd.avg_fCalc, 0) avg_fCalc, isnull(Dialog.avg_tDialog, 0) avg_tDialog from 
	(select cam_id, cal_Inicio, COUNT(marcados) marcados, SUM(Contactadas)*100/COUNT(marcados) Contactadas, SUM(Abandonadas)*100/COUNT(marcados) Abandonadas, 
	cast(CAST(SUM(tAvgTrans)/COUNT(marcados) as decimal(18,2)) as varchar(5)) tAvgTrans, SUM(ten) ten, SUM(twe) twe, SUM(tir) tir from 
		(select cal_Inicio, cam_id, cal_id Marcados, case statusCall_id when 13 then 1 else 0 end Contactadas,
		case statusCall_id when 6 then 1 else 0 end Abandonadas, isnull(cast(datediff(ms, 
		tConnTime, tBridgeTime) as decimal(18,3))/1000, ''0'') tAvgTrans,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<10 then 1 else 0 end ten,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<20 then 1 else 0 end twe,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<30 then 1 else 0 end tir
		from #ccoCallsOut_Rep
		) as Frst group by cam_id, cal_Inicio
	) as Scnd
join ccCamps Camp on Scnd.cam_id = Camp.cam_id
left join 
	(select Cam_id, cast(AVG((fecha_Calc_ms/1000.0)) as decimal(10,0)) avg_fCalc 
	from ccLogAgentesDia_Dialog where fecha_Dialog between @fechaIni and @fechaFin 
		and Cam_id in (select value from dbo.fn_RIASplitDelimited(@sCam_Id, '','')) group by Cam_id
	) as Trd
on Scnd.cam_id=Trd.Cam_id
left join
	(select Dl.Cam_id, cast(AVG(Dl.tStatus_Dialog) as decimal(10,0)) avg_tDialog
	from ccLogAgentesDia Lg left join ccLogAgentesDia_Dialog Dl on 
	CAST(Lg.user_id as varchar(10))+''|''+CONVERT(varchar(25), Lg.fecha, 121) = 
	CAST(Dl.user_id as varchar(10))+''|''+CONVERT(varchar(25), Dl.fecha_Dialog, 121)
	where Lg.fecha between @fechaIni and @fechaFin and Dl.Cam_id in (select value from dbo.fn_RIASplitDelimited(@sCam_Id, '',''))
	group by Dl.cam_id
	) as Dialog
on Trd.cam_id=Dialog.Cam_id
order by Scnd.cal_inicio, Camp.cam_descripcion
drop table #ccoCallsOut_Rep

if @langU=0
 begin
 	select a Fecha, b [Campaña], c Marcados, d [Contactadas (%)], e [Abandonadas (%)], f [Tiempo Promedio Transferida (seg)], 
	g [Llamadas Cortadas (10s)], h [Llamadas Cortadas (20s)], i [Llamadas Cortadas (30s)], 
	j [Tiempo Promedio entre Llamadas (seg)], k [Tiempo Promedio en Dialogo (seg)] from @GenKPIOutbound	
 end

else
 begin
 	select a [Date], b Campaign, c Dialed, d [Contacted (%)], e [Abandoned (%)], f [Average time During Transference (seg)], 
	g [Finished Calls (10s)], h [Finished Calls (20s)], i [Finished Calls (30s)], 
	j [Average time Between Calls (seg)], k [Average time While Talking (seg)] from @GenKPIOutbound
 end	

return(0)
set nocount off
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


