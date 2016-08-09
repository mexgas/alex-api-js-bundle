/*
Autor: Raymundo González
Fecha: 2012/08/01
Descripcion: 
	Se agrega columna cal_id a la tabla ccologdials y a la tabla exportReports
	Se crea el Stored Procedure ccspGenOutPortStats y la tabla ccGenOutPortStats para determinar la ocupación de puertos
	Se crea el Stored Procedure ccRepOutPortStats para generar el reporte de ocupación de puertos
	Se libera fix en el Stored Procedure ccspIVRInfo

Version requerida: 31
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '32'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='alter table ccologdials add cal_id int NULL'
	EXEC(@Sql)
	
	SET @Sql = 'update dbo.exportReports set cols = ''logDial_id,callout_id,cam_id,tipoResDial_id,Telefono,Puerto,fecha,tDialing,tBusy,answerbit,canceledNoAgents,cal_id'' where jobid = 3'
	EXEC(@Sql)
	
	SET @Sql = 'CREATE PROCEDURE [dbo].[ccspGenOutPortStats]
@from AS smalldatetime,
@to AS smalldatetime
AS

declare @RtnValue table (cal_id int,
						[user_id] int,
						fecha datetime,
						puerto int,
						cam_id int,
						tbusy int,
						contador int,
						tipo int)
declare @sql varchar(max)
 
DECLARE @cal_id int,
		@user_id int,
		@fecha	datetime,
		@puerto	int,
		@cam_id	int,
		@duracion	int,
		@fechafin	datetime,
		@timetot	int,
		@base_hour	datetime,
		@duracion_rest	int,
		@full_hours	int,
		@cur_hour	int,
		@tipo tinyint

insert into @RtnValue
	select dials.cal_id, calls.user_id, dials.fecha, dials.Puerto, dials.cam_id,
	sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)) as tBusy,1 as contador, 1 as tipo
	from ccologdials as dials left join ccocallsout as calls 
	on (dials.Puerto = calls.cal_puerto and dials.cal_id = calls.cal_id ) where dials.fecha >= @from and dials.fecha < @to
	group by dials.cal_id, calls.user_id, dials.fecha, dials.Puerto, dials.cam_id 
union all
	select incall.cal_id,incall.user_id,incall.cal_inicio as fecha,incall.cal_puerto as puerto, incall.inbound_id as cam_id, 
	sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)) as tBusy,1 as contador, 0 as tipo
	from cccallsin as incall 
	where cal_inicio >= @from and cal_inicio < @to
	group by incall.cal_id, incall.user_id, incall.cal_inicio, incall.cal_puerto, incall.inbound_id 

DECLARE Log_Cursor CURSOR FOR
		select * from ( select cal_id,user_id, fecha, puerto, cam_id, tbusy, dateadd(ss,tbusy,fecha) fechafin, tipo from @RtnValue ) as temp where case when datepart(mi, fecha) >= 30 then 
		dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121))  else 
		convert(varchar(13), fecha,121) + '':30:00'' end < fechafin

	OPEN Log_Cursor
	FETCH NEXT FROM Log_Cursor INTO @cal_id, @user_id, @fecha, @puerto, @cam_id, @duracion, @fechafin, @tipo

	WHILE @@fetch_status = 0 
	BEGIN
		SELECT @base_hour = case when datepart(mi, @fecha) > 30 then dateadd(mi,30,convert(varchar(13), @fecha,121) + '':30:00'')  else convert(varchar(13), @fecha,121) + '':30:00'' end
		SELECT @duracion_rest = DATEDIFF(s, @base_hour, @fechafin)
		SELECT @full_hours = @duracion_rest / 1800
		select @timetot = @duracion

		INSERT INTO @RtnValue (cal_id,[user_id], fecha, puerto, cam_id, tbusy, contador,tipo) VALUES (@cal_id,@user_id,@base_hour,@puerto,@cam_id,convert(int,DATEDIFF(s, @fecha, @base_hour)),0,@tipo)

		select @timetot = @timetot - DATEDIFF(s, @fecha, @base_hour)
		SELECT @cur_hour = 1
		
		WHILE @cur_hour <= @full_hours
		BEGIN
			INSERT INTO @RtnValue (cal_id,[user_id], fecha, puerto, cam_id, tbusy,contador,tipo) VALUES (@cal_id,@user_id,@base_hour,@puerto,@cam_id, 1800,0, @tipo)

			select @timetot = @timetot - 1800
			SELECT @cur_hour = @cur_hour + 1
		END
--tbusy
		UPDATE @RtnValue SET tbusy = @timetot % 1800 WHERE [user_id]= @user_id AND cam_id = @cam_id AND fecha= @fecha AND puerto =@puerto 

		FETCH NEXT FROM Log_Cursor INTO @cal_id, @user_id, @fecha, @puerto, @cam_id, @duracion, @fechafin, @tipo
	END
	CLOSE Log_Cursor
	DEALLOCATE Log_Cursor

	delete from ccGenOutPortStats where timegroup >= @from and timegroup < @to

	insert into ccGenOutPortStats
	select case when datepart(mi,  dials.fecha) >= 30 then convert(varchar(13),dials.fecha,121) + '':30:00'' else convert(varchar(13),dials.fecha,121) + '':00:00'' end as timegroup,
	dials.Puerto as Port, dials.cam_id,
	sum(tBusy) as tBusy,
	0 as porcentaje, sum(dials.contador) llamadas, tipo
	from @RtnValue dials where dials.fecha >= @from and dials.fecha < @to
	group by  dials.Puerto, dials.cam_id, case when datepart(mi,  dials.fecha) >= 30 then 
	convert(varchar(13),dials.fecha,121) + '':30:00''  else 
	convert(varchar(13),dials.fecha,121) + '':00:00'' end,tipo order by timegroup,port

	update ccGenOutPortStats set pctgBusy = dbo.fPorcentaje(tBusy,3600) where timegroup >= @from and timegroup < @to
'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[ccGenOutPortStats](
	[timegroup] [datetime] NOT NULL,
	[port] [smallint] NOT NULL,
	[cam_id] [int] NOT NULL,
	[tBusy] [int] NOT NULL,
	[pctgBusy] [varchar](6) NOT NULL CONSTRAINT [DF_ccGenOutPortStats_pctgBusy]  DEFAULT ((0)),
	[Calls] [int] NOT NULL,
	[tipo] [tinyint] NOT NULL CONSTRAINT [DF_ccGenOutPortStats_tipo]  DEFAULT ((0)),
 CONSTRAINT [PK_ccGenOutPortStats] PRIMARY KEY CLUSTERED 
(
	[timegroup] ASC,
	[port] ASC,
	[cam_id] ASC,
	[tipo] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='CREATE PROCEDURE [dbo].[ccRepOutPortStats]
@fini as varchar(20),
@ffin as varchar(20),
@DateG as varchar(20),
@CamGral as varchar(20),
@cbjUno as varchar(500),
@tipo as tinyint --0 inbound, 1 outbound
as
set nocount on

DECLARE @sGroupDetail as varchar(105), @Sql varchar(max), @ddif as smallint, @idioma as smallint

select @ddif = datediff(dd,@fini,@ffin)
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23
select @DateG = case when @DateG =''Por Medias Hrs'' or @DateG =''Half Hour'' then ''H'' 
					 when @DateG =''Por Día'' or @DateG =''Day'' then ''D'' 
					 when @DateG =''Por Periodo'' or @DateG =''Period'' then ''P'' end

select @CamGral = case when @CamGral =''Campaña'' or @CamGral =''Campaign'' or @CamGral =''Especialidad'' or @CamGral =''ACD group'' then ''C'' 
					   when @CamGral =''General'' or @CamGral =''All Information'' then ''G'' end

set @Sql=''select '' + case @DateG when ''H'' then '' timegroup '' when ''D'' then '' CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) '' when ''P'' then '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +''''-01 '''', 121) '' end + '' [Fecha] '' + 
case @tipo when 1 then
case @CamGral when ''C'' then '',cam_descripcion as [Campana], port as [Puerto]'' when ''G'' then '',port as [Puerto]'' end
else
case @CamGral when ''C'' then '',descripcion as [Grupo ACD], port as [Puerto]'' when ''G'' then '',port as [Puerto]'' end end+
'', dbo.fGetHHmmSS(sum(tBusy)) as [Tiempo Ocupado], sum(Calls) as [Llamadas], dbo.fPorcentaje(sum(tBusy),'' +
case @DateG when ''H'' then ''1800'' when ''D'' then ''86400'' when ''P'' then convert(varchar(3),@ddif) end + '') as [% Ocupacion] from ccGenOutPortStats ps'' +
case @tipo when 1 then
case @CamGral when ''C'' then '' left join cccamps c on (ps.cam_id = c.cam_id)'' when ''G'' then '''' end
else 
case @CamGral when ''C'' then '' left join ccinbound c on (ps.cam_id = c.inbound_id)'' when ''G'' then '''' end end + '' where'' +
case when @cbjUno <> '''' then '' ps.cam_id in ('' + @cbjUno + '') and'' else '''' end + case when @tipo < 2 then '' tipo = '' + convert(varchar(3),@tipo) + '' and'' else '''' end  + '' timegroup >= '''''' + @fini + '''''' AND timegroup < '''''' + @ffin + '''''' group by '' +
case @DateG when ''H'' then '' timegroup '' when ''D'' then '' CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) '' when ''P'' then '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +''''-01 '''', 121) '' end +
case @tipo when 1 then
case @CamGral when ''C'' then '',cam_descripcion, port'' when ''G'' then '',port'' end 
else
case @CamGral when ''C'' then '',descripcion, port'' when ''G'' then '',port'' end end

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
set nocount off

'
	EXEC(@Sql)
	
	SET @Sql = 'ALTER PROCEDURE [dbo].[ccspIVRInfo]
	@from as varchar(20),
	@to as varchar(20),
	@option as tinyint
	AS
	declare @id AS INTEGER,@opcion as varchar(200), @ivr as varchar (200)
	declare @ids as varchar(10), @pivot as varchar(2000),@isnullpivot as varchar(5000), @sql as varchar(max)

	if (@option = 1)
	begin
		delete from IVROptions where date >= @from and date < @to
		delete from IVRLlamadas where date >= @from and date < @to

		insert into IVRLlamadas (ivr_id,cal_ani,user_id,calif_id,cal_id,date)
		select A.Ivr_id,A.cal_ani,isnull(B.user_id,0),isnull(B.calif_id,0),isnull(B.cal_id,0),A.date from CCenterRia.dbo.IVRCallsIn as A 
		left join CCenterRia.dbo.ccCallsIn As B on  A.IVR_id = B.IVR_id 
		where date >= @from and date < @to		

		insert into IVROptions (IVR_id,selectedOption,date,saveType)
		select IVR_id,selectedOption,date,saveType from CCenterRia.dbo.IVROptions where date >= @from and date < @to
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

	print (@sql)
	exec (@sql)
	end
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
