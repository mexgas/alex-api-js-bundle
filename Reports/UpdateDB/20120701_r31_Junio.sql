/*
Autor: Christian Castellanos
Fecha: 2012/07/01
Descripcion: 

Version requerida: 30
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '31'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='create index IX_ccRIAWorkGroup_Calid_2 on ccRIAWorkGroup_Calid ( timestamp )'
	EXEC(@Sql)

 	set @Sql='alter table ccoLogDials add canceledNoAgents bit null

update exportReports set cols = ''logDial_id,callout_id,cam_id,tipoResDial_id,Telefono,Puerto,fecha,tDialing,tBusy,answerbit,canceledNoAgents'' where jobid =3

ALTER TABLE dbo.IVROptions ADD
		saveType tinyint NULL

	ALTER TABLE cccallsIn ADD IVR_id int NULL ;

	update exportReports set cols = ''cal_id,dni_id, cal_ANI, cal_puerto,Inbound_id, User_id, cal_extension,cal_colgada,cal_Key,statusCall_id,calif_id,cal_que,cal_tDialog,cal_tNotas,cal_tWait,cal_tXfer,cal_tCall,cal_tRing,isNull(cal_Xfer,'''''''') as cal_Xfer,cal_Inicio,cal_Opciones,cal_origin_id, cal_tMoh, cal_whoHung, isNull(califSub_id,0) as califSub_id, IVR_id'' where jobId = 2'
	EXEC(@Sql)
	
	SET @Sql = '
		ALTER TABLE dbo.IVRLlamadas
			DROP CONSTRAINT DF_IVRLlamadas_user_id
		
		ALTER TABLE dbo.IVRLlamadas
			DROP CONSTRAINT DF_IVRLlamadas_calif_id
		
		ALTER TABLE dbo.IVRLlamadas
			DROP CONSTRAINT DF_IVRLlamadas_cal_id
		
		CREATE TABLE dbo.Tmp_IVRLlamadas
			(
			IVR_id int NOT NULL,
			cal_ani varchar(30) NULL,
			user_id smallint NOT NULL,
			calif_id smallint NOT NULL,
			cal_id int NOT NULL,
			date datetime NOT NULL
			)  ON [PRIMARY]
		
		ALTER TABLE dbo.Tmp_IVRLlamadas ADD CONSTRAINT
			DF_IVRLlamadas_user_id DEFAULT ((0)) FOR user_id
		
		ALTER TABLE dbo.Tmp_IVRLlamadas ADD CONSTRAINT
			DF_IVRLlamadas_calif_id DEFAULT ((0)) FOR calif_id
		
		ALTER TABLE dbo.Tmp_IVRLlamadas ADD CONSTRAINT
			DF_IVRLlamadas_cal_id DEFAULT ((0)) FOR cal_id
		
		IF EXISTS(SELECT * FROM dbo.IVRLlamadas)
			 EXEC(''INSERT INTO dbo.Tmp_IVRLlamadas (IVR_id, cal_ani, user_id, calif_id, cal_id, date)
				SELECT IVR_id, cal_ani, user_id, calif_id, cal_id, date FROM dbo.IVRLlamadas WITH (HOLDLOCK TABLOCKX)'')
		
		ALTER TABLE dbo.IVROptions
			DROP CONSTRAINT FK_IVROptions_IVRLlamadas
		
		DROP TABLE dbo.IVRLlamadas
		
		EXECUTE sp_rename N''dbo.Tmp_IVRLlamadas'', N''IVRLlamadas'', ''OBJECT'''

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
	where opivr.ivr_id = ivr.ivr_id and opivr.date = ivr.date and opivr.date >= ''+ @from + '' and opivr.date < '' + @to + '' group by selectedoption,convert(smalldatetime,convert(varchar(10),opivr.date,121),121)
	 ) as pba
	pivot (
	avg(cantidad) for selectedoption in ('' + @pivot + '')
	) as pvt) as mcs''

	--print (@sql)
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
