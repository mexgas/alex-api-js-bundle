/*
Autor: Armando Rodriguez, daniel fernandez
Fecha: 2011/03/02
Descripcion: se agrega reporte de ivr, se cambia sp de cvdirecto y job No.2 para evitar errores, se cambia tabla de subcalificaciones de entrada y salida
se realiza cambios de los sp para que aparezca la palabra periodo. 
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '29'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='update exportReports set cols = ''cal_id,dni_id, cal_ANI, cal_puerto,Inbound_id, User_id, cal_extension,cal_colgada,cal_Key,statusCall_id,calif_id,cal_que,cal_tDialog,cal_tNotas,cal_tWait,cal_tXfer,cal_tCall,cal_tRing,isNull(cal_Xfer,'''''''') as cal_Xfer,cal_Inicio,cal_Opciones,cal_origin_id, cal_tMoh, cal_whoHung, isNull(califSub_id,0) as califSub_id'' where jobid = 2'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInCDNdelay]
@from varchar(20)='''',
@to varchar(20)=''''
AS
DECLARE @from2 AS smalldatetime, @to2 AS smalldatetime, @server as varchar(200), @sql as varchar(8000)
DECLARE @tresRing AS smallint, @tresDialog AS smallint, @tresDelayIn AS smallint

set @from2 = dateadd(mi,-15,convert(smalldatetime,convert(varchar(14),getdate(),121)+ case when substring(convert(varchar(20),getdate(),121),15,2) >= 0 and substring(convert(varchar(20),getdate(),121),15,2) < 15 then ''00'' when substring(convert(varchar(20),getdate(),121),15,2) >= 15 and substring(convert(varchar(20),getdate(),121),15,2) < 30 then ''15'' when substring(convert(varchar(20),getdate(),121),15,2) >= 30 and substring(convert(varchar(20),getdate(),121),15,2) < 45 then ''30'' when substring(convert(varchar(20),getdate(),121),15,2) >= 45 and substring(convert(varchar(20),getdate(),121),15,2) <= 59 then ''45'' end + '':00'',121))
set @to2 = dateadd(mi,-0,convert(smalldatetime,convert(varchar(14),getdate(),121)+ case when substring(convert(varchar(20),getdate(),121),15,2) >= 0 and substring(convert(varchar(20),getdate(),121),15,2) < 15 then ''00'' when substring(convert(varchar(20),getdate(),121),15,2) >= 15 and substring(convert(varchar(20),getdate(),121),15,2) < 30 then ''15'' when substring(convert(varchar(20),getdate(),121),15,2) >= 30 and substring(convert(varchar(20),getdate(),121),15,2) < 45 then ''30'' when substring(convert(varchar(20),getdate(),121),15,2) >= 45 and substring(convert(varchar(20),getdate(),121),15,2) <= 59 then ''45'' end + '':00'',121))

EXEC @tresRing = ccspConfigTresRing
EXEC @tresDialog = ccspConfigTresDialog
EXEC @tresDelayIn = ccspConfigtresDelayIn
select @server = valor from ccsettings where setting_id = 22

DELETE FROM ccGenInCDN WHERE timegroup >= @from2 AND timegroup < @to2

set @sql= ''INSERT INTO ccGenInCDN (timegroup, inbound_id, ntotal, nout_hour, nout_service, nabnd, nno_agent, ntimeout, noverflow, nabnd_xfer, nabnd_ring ,nno_answer, nabnd_dialog, nanswer, nlost)
select fechaCV as timegroup,inbound_id, count(cal_id) ntotal, COUNT(CASE WHEN statuscall_id = 2 THEN 1 ELSE NULL END) AS nout_hour
					, COUNT(CASE WHEN statuscall_id = 3 THEN 1 ELSE NULL END) AS nout_service
					, COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END) AS nabnd, COUNT(CASE WHEN (statuscall_id = 4) THEN 1 ELSE NULL END) AS nno_agent, COUNT(CASE WHEN (statuscall_id = 7) THEN 1 ELSE NULL END) AS ntimeout
					, COUNT(CASE WHEN (statuscall_id = 8) THEN 1 ELSE NULL END) AS noverflow 
					, COUNT(CASE WHEN ((statuscall_id = 11) OR (statuscall_id = 6 AND cal_xfer IS NOT NULL)) THEN 1 ELSE NULL END) AS abnd_xfer
					, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring <= ''+convert(varchar(5),@tresRing)+'')) THEN 1 ELSE NULL END) AS nabnd_ring
					, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring > ''+convert(varchar(5),@tresRing)+'')) THEN 1 ELSE NULL END) AS nno_answer
					, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  <= ''+convert(varchar(5),@tresDialog)+'')) THEN 1 ELSE NULL END) AS nabnd_dialog
					, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > ''+convert(varchar(5),@tresDialog)+'')) THEN 1 ELSE NULL END) AS nanswer
					, COUNT(CASE WHEN (statuscall_id = 16) THEN 1 ELSE NULL END) AS nlost from (
select convert(smalldatetime,convert(varchar(14),cal_inicio,121)+ case when substring(convert(varchar(20),cal_inicio,121),15,2) >= 0 and substring(convert(varchar(20),cal_inicio,121),15,2) < 15 then ''''00'''' when substring(convert(varchar(20),cal_inicio,121),15,2) >= 15 and substring(convert(varchar(20),cal_inicio,121),15,2) < 30 then ''''15'''' when substring(convert(varchar(20),cal_inicio,121),15,2) >= 30 and substring(convert(varchar(20),cal_inicio,121),15,2) < 45 then ''''30'''' when substring(convert(varchar(20),cal_inicio,121),15,2) >= 45 and substring(convert(varchar(20),cal_inicio,121),15,2) <= 59 then ''''45'''' end + '''':00'''',121) fechaCV,cal_id,dni_id,cal_puerto,inbound_id,statuscall_id,calif_id,cal_tdialog,cal_tring, cal_que, cal_xfer from ''+@server+''cccallsin where cal_inicio > ''''''+convert(varchar(20),@from2,121)+'''''' and cal_inicio < ''''''+convert(varchar(20),@to2,121)+'''''' ) a
group by fechaCV,inbound_id''

exec (@sql)
'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccTipoCalifSub
	DROP CONSTRAINT DF_ccTipoCalifSub_orden

alter table dbo.ccTipoCalifSub
	alter column orden [varchar](3) NOT NULL

ALTER TABLE dbo.ccTipoCalifSub ADD CONSTRAINT
	DF_ccTipoCalifSub_orden DEFAULT (''255'') FOR orden
'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccTipoCalifSubOUT
	DROP CONSTRAINT DF_ccTipoSubCalifOUT_orden

alter table dbo.ccTipoCalifSubOUT
	alter column orden [varchar](3) NOT NULL

ALTER TABLE dbo.ccTipoCalifSubOUT ADD CONSTRAINT
	DF_ccTipoSubCalifOUT_orden DEFAULT (''255'') FOR orden
'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[IVRLlamadas](
	[IVR_id] [int] IDENTITY(1,1) NOT NULL,
	[cal_ani] [varchar](30) NULL,
	[user_id] [smallint] NOT NULL CONSTRAINT [DF_IVRLlamadas_user_id]  DEFAULT ((0)),
	[calif_id] [smallint] NOT NULL CONSTRAINT [DF_IVRLlamadas_calif_id]  DEFAULT ((0)),
	[cal_id] [int] NOT NULL CONSTRAINT [DF_IVRLlamadas_cal_id]  DEFAULT ((0)),
	[date] [datetime] NOT NULL,
 CONSTRAINT [PK_IVR_ID] PRIMARY KEY CLUSTERED 
(
	[IVR_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[IVROptions](
	[IVR_id] [int] NOT NULL,
	[selectedOption] [varchar](5) NULL,
	[date] [datetime] NOT NULL
) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE [dbo].[IVROptions]  WITH CHECK ADD  CONSTRAINT [FK_IVROptions_IVRLlamadas] FOREIGN KEY([IVR_id])
REFERENCES [dbo].[IVRLlamadas] ([IVR_id])'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE [dbo].[IVROptions] CHECK CONSTRAINT [FK_IVROptions_IVRLlamadas]'
	EXEC(@Sql)

 	set @Sql='Create PROCEDURE [dbo].[ccspIVRInfo]

@from as varchar(20),

@to as varchar(20),

@option as tinyint

AS
declare @id AS INTEGER,@opcion as varchar(200), @ivr as varchar (200)
declare @ids as varchar(10), @pivot as varchar(2000),@isnullpivot as varchar(5000), @sql as varchar(max)

if (@option = 1)
begin
	insert into IVRLlamadas (cal_ani,user_id,calif_id,cal_id, date)
	select cal_ani,user_id,calif_id,cal_id, date from ivr.dbo.CallsInIVR where date >= @from and date < @to


	insert into IVROptions (IVR_id,selectedOption,date)
	select IVR_id,selectedOption,date from ivr.dbo.IVROptions where date >= @from and date < @to
end

if (@option = 2)
begin
	select @opcion = '''',@ivr = ''''
	CREATE TABLE [dbo].[#myoptions] (
		[ivr_id] [int] NULL,
		[options] varchar(500) NULL
	) ON [PRIMARY]

	DECLARE CCivr CURSOR FOR 
		select distinct ivr_id from ivroptions where date >= @from and date < @to
	Open CCivr
	Fetch Next From CCivr
	Into @id
	if @@FETCH_STATUS = 0
		Begin 
			While @@FETCH_STATUS = 0
			Begin
				select @opcion = '''',@ivr = ''''
				select @ivr= ivr_id, @opcion = @opcion +  case @opcion when '''' then '''' else '','' end + convert(varchar(50),selectedoption) from ivroptions where ivr_id = @id and date >= @from and date < @to order by date

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
'
	EXEC(@Sql)

--daniel
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
declare @CamAgt_M varchar(max), @CamAgt_C varchar(max), @Sql varchar(max), @Serv varchar(50), @idioma as bit,@CblDosTmp as varchar(300), @periodo as varchar(20)
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
set @periodo=@DateG
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
 
set @Sql=''SELECT''+case @periodo when''Por Periodo'' then '' ''''Periodo'''''' when ''Period'' then '' ''''Period'''''' else '' timegroup'' end+'' as Fecha '' + case @CamAgt 
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
	print(@Sql)
end try

begin catch
	declare @error varchar(255)
	set @error=''Se presento un problema al generar el reporte, causa del mismo: "''+ERROR_MESSAGE()+''"''
	select @error
end catch
set nocount off
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[A_cwRepNotReady]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4000)='''',
@CblDos as varchar(1500) = ''''

AS
declare @cursor as varchar (Max)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(max)
DECLARE @idioma as bit

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(max)
DECLARE @sql2 as varchar(max)
DECLARE @nodiponibles as varchar(max)
DECLARE @sumNoDip as varchar(max)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)
DECLARE @totalC as varchar(250)
DECLARE @totalT as varchar(250)

DECLARE @sSQL as varchar(max)
DECLARE @sSQL2 as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select TipoNotReady_id, Descripcion from ccTipoNotReady
''
    end
    else
    begin
	set @cursor = @cursor +''select TipoNotReady_id, Descripcion from ccTipoNotReady where TipoNotReady_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select distinct nr.user_id, nr.timegroup,'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + '' dbo.fGetHHmmSS (Sesion) Sesion''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + '' sum(Sesion) Sesion ''+char(0x27) + ''
set @totalC = ''+char(0x27) + '', sum (0''+char(0x27) + ''
set @totalT = ''+char(0x27) + '', sum (0''+char(0x27) + ''
set @sql = @sql+ ''+char(0x27) + '' (select isnull(SUM(tlog),'' +char(0x27)+''+ char(0x27) + char(0x27) +'' +char(0x27)+'') from ccGenAgent where user_id = nr.user_id and timegroup =  nr.timegroup ) Sesion ''+char(0x27) + ''
set @sql2 =  ''+char(0x27) +char(0x27) + ''

Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
                set @totalC = @totalC + ''+char(0x27)+''+ sum([''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto])'' +char(0x27) + ''
                set @totalT = @totalT + ''+char(0x27)+''+ sum([''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo])'' +char(0x27) + ''
                set @nodiponibles = @nodiponibles+ ''+char(0x27)+'', ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto], dbo.fGetHHmmSS ([''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]) [''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
                set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
				if @id  < 35
				begin
					set @sql = @sql+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amountReal,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto]''+char(0x27)+''
					set @sql = @sql+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(time,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
			    end
			    else
			    begin
			    	set @sql2 = @sql2+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amountReal,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto]''+char(0x27)+''
					set @sql2 = @sql2+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(time,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
			    end
			
			Fetch Next From CCampos
			Into  @id, @desc
		End
	End

--print @sql
--print @nodiponibles
--print @sumNoDip


CLOSE CCampos 
DEALLOCATE CCampos 
''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''  timegroup,''
   set @sGroup = ''timegroup ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
--   set @sGroupDetail = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121), ''
 --  set @sGroup = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121) ''
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121), ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''

end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
   set @sGroupDetail = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121), ''
   set @sGroup = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121) ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' [user_id] in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and tiponotready_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' tiponotready_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + ''set @sSQL = ''+char(0x27)+''SELECT Login, ''+case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else '' timegroup'' end +  '' as Fecha, apellidoPaterno + ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'' ''+char(0x27)+''+ char(0x27)+''+char(0x27)+''+ isNull( apellidoMaterno, ''+char(0x27)+''+ char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'')+ ''+char(0x27)+'' + char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' +char(0x27)+''+char(0x27)+''+  nombres as Agente, ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT ''+ @sGroup +'' as timegroup , [user_id], ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL2 = @sql2+  ''+char(0x27)+'' FROM ccGenAgentNotReady as nr WHERE timegroup >= ''+char(0x27)+'' + char(0x27) + '' +char(0x27)+ @fini +char(0x27)+ '' + char(0x27) + ''+char(0x27)+'' AND timegroup < ''+char(0x27)+'' + char(0x27) + '' +char(0x27)+ @ffin +char(0x27)+ '' + char(0x27) 
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL2 = @sSQL2 + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY  nr.timegroup, [user_id] ) as a WHERE timegroup >= ''+char(0x27)+'' + char(0x27)+ '' +char(0x27)+ @fini +char(0x27)+ ''+ char(0x27)+ ''+char(0x27)+'' AND timegroup < ''+char(0x27)+'' + char(0x27)+ '' +char(0x27)+ @ffin +char(0x27)+ '' + char(0x27) + ''+char(0x27)+''''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '' [user_id]  ) xDetail ''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' INNER JOIN ccUsers ON (xDetail.[user_id]=ccUsers.[user_id]) AND ccUsers.filter = 1 ORDER BY Fecha, Agente ''+char(0x27)+''

exec ( @sSQL + @sSQL2)
--print (@sSQL)
--print (@sSQL2)
''
if @idioma = 1
begin
set @cursor = replace(@cursor, ''Sesion'', ''Session'')
set @cursor = replace(@cursor, ''_Monto'', ''_Count'')
set @cursor = replace(@cursor, ''_Tiempo'', ''_Time'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Agente'', ''Agent'')
end

--print (@cursor)
exec (@cursor)
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[A_cwReportDialCamp]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(600)='''',
@CblDos as varchar(300) = ''''

AS
declare @cursor as varchar (8000)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(1200)
DECLARE @idioma as bit

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(4500)
DECLARE @nodiponibles as varchar(1200)
DECLARE @sumNoDip as varchar(1200)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(8000)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoResDial_id, descripcion from ccTipoResultadoDial
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoResDial_id, descripcion from ccTipoResultadoDial where tipoResDial_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select distinct nr.timegroup, nr.cam_id'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
                       		set @nodiponibles = @nodiponibles+ ''+char(0x27)+'', '' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')
                                set @nodiponibles = @nodiponibles+ ''+char(0x27)+'',dbo.fPorcentaje('' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'') + ''+char(0x27)+'', total )  [% ''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'') +''+char(0x27)+''] ''+char(0x27)+''
                         	set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum( '' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'') ''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')
				set @sql = @sql+''+char(0x27)+'', SUM(Case when tiporesdial_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then amount else 0 end) ''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')

			Fetch Next From CCampos
			Into  @id, @desc
		End
	End

--print @sql
--print @nodiponibles
--print @sumNoDip


CLOSE CCampos 
DEALLOCATE CCampos 

                set @nodiponibles = @nodiponibles+ ''+char(0x27)+'', total '' +char(0x27)+''
		set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum( total) total '' +char(0x27)+''
		set @sql = @sql+''+char(0x27)+'', SUM(amount) Total ''+char(0x27)+'' 


''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.cam_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.tiporesdial_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.tiporesdial_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''SELECT ''+case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else '' timegroup'' end + '' as Fecha, ccCamps.cam_descripcion AS Campana ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT '' + @sGroupDetail + '' as timegroup, cam_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL = @sSQL + ''+char(0x27)+'' FROM ccGenOutCallDials as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL = @sSQL + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL = @sSQL + ''+char(0x27)+'' group by nr.timegroup, nr.cam_id) as a WHERE timegroup >= '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ @fini +char(0x27)+ '' + char(0x27)+ '' + char(0x27) + '' AND timegroup < '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ @ffin +char(0x27)+ '' + char(0x27) + ''+ char(0x27) +'''' + char(0x27) +'' 
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', cam_id  ) xDetail ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' LEFT JOIN ccCamps ON (xDetail.cam_id=ccCamps.cam_id) order by Fecha, Campana ''+char(0x27)+''

--print (@sSQL)
exec sp_sqlexec @sSQL

''
if @idioma = 1
begin
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Campana'', ''Campaign'') 
end
--print (@cursor)
exec (@cursor)
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
declare @periodo as varchar(max)
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

set @periodo=@DateG
select @DateG = case @DateG when ''Por Hora'' then ''H'' when ''Hour'' then ''H'' when ''Por Día'' then ''D'' 
	when ''Day'' then ''D'' when ''Por Periodo'' then ''p'' when ''Period'' then ''p'' end

select @CamAgt = case @CamAgt when ''Grupo de Trabajo'' then ''W'' when ''workgroup'' then ''W'' when ''Area'' then ''A'' end

set @Sql=''Select ''+case @periodo when ''Por Periodo'' then ''''''Periodo'''''' when ''Period'' then ''''''Period'''''' else '' timegroup'' end +'' as Fecha'' + case @CamAgt when ''W'' then '', WGName AS WorkGroup'' when ''A'' then '', areaName AS Area'' end  + @CamAgt_M + '', total from (SELECT distinct'' + 
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

 	set @Sql='ALTER PROCEDURE [dbo].[A_cwReportOutCtoCamp]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4000)='''',
@CblDos as varchar(500) = ''''

AS

declare @cursor as varchar (max)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(4500)
DECLARE @idioma as bit
declare @iva varchar(5)
select @iva=valor from ccsettings where setting_id = 25
select @iva=convert(varchar(5),''1.'' + substring(@iva,(len(@iva)-2),3))

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(max)
DECLARE @nodiponibles as varchar(4000)
DECLARE @sumNoDip as varchar(5000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(max)
DECLARE @sSQLTot as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where tipoLlamada_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select  distinct nr.timegroup, nr.cam_id'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
            set @nodiponibles = @nodiponibles+ ''+char(0x27)+'',['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call] as [Llamadas_''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min] as [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min_Facturados], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            --set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
              set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.mins,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.costo,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]''+char(0x27)+''
		Fetch Next From CCampos
		Into  @id, @desc
		End
	End

--print @sql
--print @nodiponibles
--print @sumNoDip


CLOSE CCampos 
DEALLOCATE CCampos 
''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.cam_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.tipoLlamada_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.tipoLlamada_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT '' +case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else '' timegroup'' end +  '' as Fecha, ccCamps.cam_descripcion AS Campana ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT '' + @sGroupDetail + '' as timegroup, cam_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL = @sSQL + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL = @sSQL + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY timegroup, cam_id ) a''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', cam_id ) xDetail ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' LEFT JOIN ccCamps ON (xDetail.cam_id=ccCamps.cam_id) ) ''+char(0x27)+''''

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT '' +case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else ''getdate()'' end +'' as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as  cam_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQLTot = @sSQLTot + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' GROUP BY timegroup, cam_id ) a) order by Fecha, Campana''+char(0x27)+''


exec ( @sSQL + @sSQLTot)
--print (@sSQL)
--print (@sSQLTot)
''

if @idioma = 1
begin
set @cursor = replace(@cursor, ''Llamadas'', ''Calls'')
set @cursor = replace(@cursor, ''Min_Facturados'', ''Rated_Min'')
set @cursor = replace(@cursor, ''_CostoIVA'', ''_Tax'')
set @cursor = replace(@cursor, ''_Costo'', ''_Cost'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Campana'', ''Campaign'')
end

exec (@cursor)
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[A_cwReportOutCtoProv]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4500)='''',
@CblDos as varchar(500) = ''''
as

declare @cursor as varchar (max)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(4500)
DECLARE @idioma as bit
declare @iva varchar(5)
select @iva=valor from ccsettings where setting_id = 25
select @iva=convert(varchar(5),''1.'' + substring(@iva,(len(@iva)-2),3))

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(max)
DECLARE @nodiponibles as varchar(4000)
DECLARE @sumNoDip as varchar(5000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(max)
DECLARE @sSQLTot as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where tipoLlamada_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select  distinct nr.timegroup, nr.provedor_id'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
            set @nodiponibles = @nodiponibles+ ''+char(0x27)+'',['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call] as [Llamadas_''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min] as [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min_Facturados], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            --set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
	    set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.mins,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.costo,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]''+char(0x27)+''
		Fetch Next From CCampos
		Into  @id, @desc
		End
	End

--print @sql
--print @nodiponibles
--print @sumNoDip


CLOSE CCampos 
DEALLOCATE CCampos 
''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.provedor_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.tipoLlamada_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.tipoLlamada_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT '' +case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else '' timegroup'' end +  '' as Fecha, cstoProvedor.descrip AS Proveedor ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT '' + @sGroupDetail + '' as timegroup, provedor_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL = @sSQL + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL = @sSQL + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY timegroup, provedor_id ) a''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', provedor_id ) xDetail ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' LEFT JOIN cstoProvedor ON (xDetail.provedor_id=cstoProvedor.provedor_id) ) ''+char(0x27)+''''

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT '' +case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else ''getdate()'' end +'' as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as provedor_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQLTot = @sSQLTot + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' GROUP BY timegroup, provedor_id ) a) order by Fecha, Proveedor''+char(0x27)+''


exec ( @sSQL + @sSQLTot)
--print (@sSQL)
--print (@sSQLTot)
''

if @idioma = 1
begin
set @cursor = replace(@cursor, ''Llamadas'', ''Calls'')
set @cursor = replace(@cursor, ''Min_Facturados'', ''Rated_Min'')
set @cursor = replace(@cursor, ''_CostoIVA'', ''_Tax'')
set @cursor = replace(@cursor, ''_Costo'', ''_Cost'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Proveedor'', ''Supplier'')
end

exec (@cursor)
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[A_cwReportOutCtoUser]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4500)='''',
@CblDos as varchar(500) = ''''

AS

declare @cursor as varchar (max)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(4500)
DECLARE @idioma as bit
declare @iva varchar(5)
select @iva=valor from ccsettings where setting_id = 25
select @iva=convert(varchar(5),''1.'' + substring(@iva,(len(@iva)-2),3))

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(max)
DECLARE @nodiponibles as varchar(4000)
DECLARE @sumNoDip as varchar(5000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(max)
DECLARE @sSQLTot as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where tipoLlamada_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select  distinct nr.timegroup, nr.user_id'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
            set @nodiponibles = @nodiponibles+ ''+char(0x27)+'',['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call] as [Llamadas_''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min] as [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min_Facturados], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            --set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.mins,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.costo,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]''+char(0x27)+''

		Fetch Next From CCampos
		Into  @id, @desc
		End
	End

--print @sql
--print @nodiponibles
--print @sumNoDip


CLOSE CCampos 
DEALLOCATE CCampos 
''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.user_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.tipoLlamada_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.tipoLlamada_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT '' +case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else '' timegroup'' end + '' as Fecha, apellidoPaterno + ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'' ''+char(0x27)+''+ char(0x27)+''+char(0x27)+''+ isNull( apellidoMaterno, ''+char(0x27)+''+ char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'')+ ''+char(0x27)+'' + char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' +char(0x27)+''+char(0x27)+''+  nombres as Agente ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT '' + @sGroupDetail + '' as timegroup, user_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL = @sSQL + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL = @sSQL + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY timegroup, user_id ) a''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', user_id ) xDetail ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+''LEFT JOIN ccUsers ON (xDetail.[user_id]=ccUsers.[user_id]) ) ''+char(0x27)+''''

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT '' +case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else ''getdate()'' end +'' as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as user_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQLTot = @sSQLTot + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' GROUP BY timegroup, user_id ) a) order by Fecha, Agente''+char(0x27)+''


exec ( @sSQL + @sSQLTot)
print (@sSQL)
--print (@sSQLTot)
''
if @idioma = 1
begin
--set @cursor = replace(@cursor, ''Sesion'', ''Session'')
set @cursor = replace(@cursor, ''Llamadas'', ''Calls'')
set @cursor = replace(@cursor, ''Min_Facturados'', ''Rated_Min'')
set @cursor = replace(@cursor, ''_CostoIVA'', ''_Tax'')
set @cursor = replace(@cursor, ''_Costo'', ''_Cost'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Agente'', ''Agent'')
end

--print(@cursor)
exec (@cursor)
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccsp_repDIDRes]
@DateG as varchar(20),
@end as varchar(20),
@start as varchar(20),
@cbjUno as varchar(500)=''''
AS

set nocount on
declare @RtnValue table (Id int identity(1,1), Value nvarchar(100))
declare @end_provccgen as smalldatetime
declare @end_prov as smalldatetime
declare @hoy as smalldatetime
declare @hora as smalldatetime
declare @sql as varchar(max)
declare @sGroupDetail as varchar(200)
declare @sGroupDetailCIn as varchar(200)
declare @server as varchar(200)
declare @cols as varchar(8000)
declare @colsUp as varchar(max)
declare @columna as varchar(20)
DECLARE @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23
select @hoy = convert(smalldatetime,convert(varchar(10),getdate(),120),120)
select @hora = dateadd(hh,-1,convert(smalldatetime,convert(varchar(14),getdate(),120)+''00:00'',120))
select @server = valor from ccSettings where setting_id = 22

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''timegroup''
   set @sGroupDetailCIn = ''convert(smalldatetime,convert(varchar(14),cal_inicio,120)+ ''''00:00'''',120)''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121)''
   set @sGroupDetailCIn = ''convert(smalldatetime,convert(varchar(10),cal_inicio,120),120)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''''-01'''', 121)''
    set @sGroupDetailCIn = ''convert(smalldatetime,convert(varchar(7),cal_inicio,120)+ ''''-01'''',120)''
end

if @end > @hoy
begin
	set @end_provccgen = @hoy
	if @start >= @hoy
	begin
		set @sql = ''''
	end
	else
	begin
		set @sql = '' (select '' + @sGroupDetail + '' as timegroup, dni_id, sum(nanswer) cantidad from dbo.ccGenInCallDNI where timegroup >= '' + char(0x27) + convert(varchar(20),@start,120) + char(0x27) + '' and timegroup < '' + char(0x27) + convert(varchar(20),@end_provccgen,120) + char(0x27) + '' group by '' + @sGroupDetail + '',dni_id)''
	end
	if @end > @hora
	begin
		set @end_prov = @hora
		if @start >= @hora
		begin
			set @sql = '' select '' + @sGroupDetailCIn + '' as timegroup, dni_id, count(dni_id) cantidad from '' + @server + ''cccallsin where cal_inicio >= '' + char(0x27) + convert(varchar(20),@start,120) + char(0x27) + '' and cal_inicio < '' + char(0x27) + convert(varchar(20),@end,120) + char(0x27) + '' and statuscall_id = 13 group by '' + @sGroupDetailCIn + '', dni_id''
		end
		else
		begin
			if @sql <> ''''
			begin
				set @sql = @sql + '' union all''
			end
			set @sql = @sql + '' (select '' + @sGroupDetailCIn + '' as timegroup, dni_id, count(dni_id) cantidad from  '' + @server + ''cccallsin where cal_inicio >= '' + char(0x27) + convert(varchar(20),dateadd(ss,1,@end_prov),120) + char(0x27) + '' and cal_inicio < '' + char(0x27) + convert(varchar(20),@end,120) + char(0x27) + '' and statuscall_id = 13 group by '' + @sGroupDetailCIn + '', dni_id)''
			set @sql = @sql + '' union all (select '' + @sGroupDetailCIn + '' as timegroup, dni_id, count(dni_id) cantidad from cccallsin where cal_inicio >= '' + char(0x27) + convert(varchar(20),dateadd(ss,1,@end_provccgen),120) + char(0x27) + '' and cal_inicio < '' + char(0x27) + convert(varchar(20),@end_prov,120) + char(0x27) + '' and statuscall_id = 13 group by '' + @sGroupDetailCIn + '', dni_id)''
		end
	end
	else
	begin
		set @end_prov = @end
		if @start >= @hoy and @start < @hora
		begin
			set @sql = '' select '' + @sGroupDetailCIn + '' as timegroup, dni_id, count(dni_id) cantidad from cccallsin where cal_inicio >= '' + char(0x27) + convert(varchar(20),@start,120) + char(0x27) + '' and cal_inicio < '' + char(0x27) + convert(varchar(20),@end_prov,120) + char(0x27) + '' and statuscall_id = 13 group by '' + @sGroupDetailCIn + '', dni_id''
		end
		else
		begin
			set @sql = @sql + '' union all (select '' + @sGroupDetailCIn + '' as timegroup, dni_id, count(dni_id) cantidad from cccallsin where cal_inicio >= '' + char(0x27) + convert(varchar(20),dateadd(ss,1,@end_provccgen),120) + char(0x27) + '' and cal_inicio < '' + char(0x27) + convert(varchar(20),@end_prov,120) + char(0x27) + '' and statuscall_id = 13 group by '' + @sGroupDetailCIn + '', dni_id)''
		end
	end
end
else
begin
	set @end_provccgen = @end
	set @sql = '' select '' + @sGroupDetail + '' as timegroup, dni_id, sum(nanswer) cantidad from dbo.ccGenInCallDNI where timegroup >= '' + char(0x27) + convert(varchar(20),@start,120) + char(0x27) + '' and timegroup < '' + char(0x27) + convert(varchar(20),@end_provccgen,120) + char(0x27) + '' group by '' + @sGroupDetail + '',dni_id''
end

if @cbjUno <> ''''
 begin
	While (Charindex('','',@cbjUno)>0)
	 Begin 
		Insert Into @RtnValue (value)
		Select Value = ltrim(rtrim(Substring(@cbjUno,1,Charindex('','',@cbjUno)-1))) 
		Set @cbjUno = Substring(@cbjUno,Charindex('','',@cbjUno)+len('',''),len(@cbjUno))
	 End 

	Insert Into @RtnValue (Value)
	Select Value = ltrim(rtrim(@cbjUno))
 end
else
 begin
	insert into @RtnValue select distinct dni_id from ccdnis
 end

--genera las columans de los dnis
DECLARE CCampos CURSOR FOR
     SELECT dni_numero from ccdnis where dni_id in (select value from @RtnValue) order by dni_numero
set @cols = ''''
set @colsUp = ''''
Open CCampos
Fetch Next From CCampos
Into @columna
if @@FETCH_STATUS = 0
	Begin
		While @@FETCH_STATUS = 0
		Begin   
			if @cols = ''''
			begin
				if @columna <> ''cont''
				begin
					set @cols = ''['' + @columna + '']''
					set @colsUp = ''isnull(['' + @columna + ''],0) '' + ''['' + @columna + '']''
				end
			end
			else
			begin
				if @columna <> ''cont''
				begin
					set @cols = @cols +'', ['' + @columna + '']''
					set @colsUp = @colsUp + '', isnull(['' + @columna + ''],0) '' + ''['' + @columna + '']''
				end
			end
			Fetch Next From CCampos
			Into   @columna
		End
	End
CLOSE CCampos 
DEALLOCATE CCampos 
--print @colsUp
--print @cols

set @sql = ''select''+case @DateG when ''Por Periodo'' then '' ''''Periodo'''''' when ''Period'' then '' ''''Period'''''' else '' timegroup'' end +'' as Fecha,'' + @colsUp + '' from(select timegroup,isnull(dni_numero,0) dni_numero, sum(cantidad) as cantidad from ('' + @sql + '') as a left join ccdnis ccd on (a.dni_id = ccd.dni_id) group by timegroup, dni_numero) dnis PIVOT(SUM(cantidad) FOR [dni_numero] IN ('' + @cols + '')) AS pvt''

if @idioma = 1
begin
	set @sql = replace(@sql, ''Fecha'', ''Date'') 
end

--print(@sql)
exec(@sql)
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


