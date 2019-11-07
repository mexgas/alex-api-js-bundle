CREATE PROCEDURE [dbo].[ccspRepSpecialTimes]
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
		delete from RepSpecialTimes with(rowlock)
		where date >= @from AND date < @to

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
			select cam_id, 0 as inbound_id, 'Camp - ' + b.cam_descripcion as [Espec/Camp], 
				case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + ':30:00',121)) 
					 else convert(varchar(13), fecha,121) + ':30:00' end as Periodo,
				case when tipostatusage_id = 3 then 'Tiempo Disponible' when tipostatusage_id = 4 then 'Tiempo Dialogo' 
					when tipostatusage_id = 2 then 'Tiempo No Disponible' else 'Otro' end as tDescripcion,
				sum(tstatus) as tstatus
			from ccLogAgentesDia a
			left outer join cccamps b on (cam_id = idcampesp and tipo = 1)
			where (idCampEsp is not null)
			and (tipo is not null)
			and tipo = 1
			and fecha between @from and @to
			group by cam_id, cam_descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + ':30:00',121)) else convert(varchar(13), fecha,121) + ':30:00' end,
				case when tipostatusage_id = 3 then 'Tiempo Disponible' when tipostatusage_id = 4 then 'Tiempo Dialogo' when tipostatusage_id = 2 then 'Tiempo No Disponible' else 'Otro' end 
			union
			select 0 as cam_id, inbound_id, 'ACD - ' + b.descripcion as [Espec/Camp], 
				case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + ':30:00',121)) 
					else convert(varchar(13), fecha,121) + ':30:00' end as Periodo, 
				case when tipostatusage_id = 3 then 'Tiempo Disponible' when tipostatusage_id = 4 then 'Tiempo Dialogo' 
					when tipostatusage_id = 2 then 'Tiempo No Disponible' else 'Otro' end as tDescripcion,
				sum(tstatus) as tstatus
			from ccLogAgentesDia a
			left outer join ccinbound b on (inbound_id = idcampesp and tipo = 0)
			where (idCampEsp is not null)
			and (tipo is not null)
			and tipo = 0
			and fecha between @from and @to
			group by inbound_id, descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + ':30:00',121)) else convert(varchar(13), fecha,121) + ':30:00' end,
				case when tipostatusage_id = 3 then 'Tiempo Disponible' when tipostatusage_id = 4 then 'Tiempo Dialogo' when tipostatusage_id = 2 then 'Tiempo No Disponible' else 'Otro' end 
		) times
		pivot (max(tstatus) for [tdescripcion] in ([Tiempo Disponible], [Tiempo Dialogo], [Tiempo No Disponible], [Otro])) as pvtTimes
		where [Espec/Camp] is not null
		order by [Espec/Camp], Periodo

		select * into #notready from(
		select 'Camp - ' + cam_descripcion as [Espec/Camp],  
			case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + ':30:00',121)) 
					else convert(varchar(13), fecha,121) + ':30:00' end as Periodo,
			c.descripcion as [descriptionT], sum(tstatus) as T, c.descripcion as [descriptionN], count(*) as N
		from ccLogAgentesNotReady a
		left outer join cccamps b on (idcampesp = cam_id and tipo = 1)
		left outer join ccTipoNotReady c on (a.tiponotready_id = c.tiponotready_id)
		where (idCampEsp is not null)
		and (tipo is not null)
		and tipo = 1
		and fecha between @from and @to
		group by cam_descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + ':30:00',121)) else convert(varchar(13), fecha,121) + ':30:00' end, c.descripcion
		union
		select 'ACD - ' + b.descripcion as [Espec/Camp], 
			case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + ':30:00',121)) 
					else convert(varchar(13), fecha,121) + ':30:00' end as Periodo,
			c.descripcion as [descriptionT], sum(tstatus) as T, c.descripcion as [descriptionN], count(*) as N
		from ccLogAgentesNotReady a
		left outer join ccinbound b on (idcampesp = inbound_id and tipo = 0)
		left outer join ccTipoNotReady c on (a.tiponotready_id = c.tiponotready_id)
		where (idCampEsp is not null)
		and (tipo is not null)
		and tipo = 0
		and fecha between @from and @to
		group by b.descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + ':30:00',121)) else convert(varchar(13), fecha,121) + ':30:00' end, c.descripcion
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
		descriptionN + '_Count' as [descripcion_count], 
		[N] as [count],
		b.descriptionT + '_Time' as [descripcion_time], 
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
		@NotReady + '_Count', 0,
		@NotReady + '_Time', '0', 0
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
	end