CREATE Procedure [dbo].[ccsp_RIAADMGetCalifDayForced]
		@type smallint,
		@cam_id smallint,
		@calif_id smallint = null
		AS 
		set nocount on
		create table #CalifTemp (id int identity,
		tipo integer, 
		Cam_id varchar(50), 
		Calificacion varchar(50), 
		subCalificacion varchar(50) null,
		calif_id smallint null,
		Total int ) 

		declare @today datetime
		set @today = convert(datetime, convert (varchar(11), getdate(), 101))
		--set @today =convert(datetime, convert (varchar(11), '2015-10-01 17:50:20.470', 101))

		-- Seleccion de idioma -- 
		declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
		select @nIdioma = case valor when 0 then 'Sin calificación Otros' else 'No disposition Others' end
		from ccsettings where setting_id = 27 -- 0esp

		select @nIdiomaSub = case valor when 0 then 'Sin Subcalificación' else 'No Subdisposition' end
		from ccsettings where setting_id = 27 -- 0 esp

		if @type=0 
		insert into #CalifTemp 
		select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13
				then case when description is not null 
							then description 
							else @nIdioma--substring(@nIdioma, 1, charindex('@', @nIdioma)-1) 
							end
		else case when sll.descripcion is not null then 'cw:' + sll.descripcion else 'cw:' + @nIdioma--substring(@nIdioma, 1, charindex('@', @nIdioma)-1) 
		end end as Calificacion,
		case when count(co.califSub_id) > 0 then 1 else 0 end as Subcalificacion,co.calif_id as calif_id,count(*) cantidad
		from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
		left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
		left join ccTipoCalifSubOUT tcsout on co.califSub_id = tcsout.califSub_id
		left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
		left join ccCamps ci on ci.cam_id = co.cam_id 
		where co.cal_inicio > @today
		and co.cam_id = @cam_id
		group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id



		if @type=1 
		insert into #CalifTemp 
		select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
		else @nIdioma-- substring(@nIdioma, 1, charindex('@', @nIdioma)-1) 
		end as Calificacion,count(ci.califSub_id) as subCalificacion,ci.calif_id,count(*)  as total
		from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) 
		left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
		left join ccInbound cci on cci.inbound_id = ci.inbound_id 
		where ci.cal_inicio > @today
		and ci.inbound_id = @cam_id
		and statuscall_id = 13 
		group by description, cci.inbound_id,ci.califSub_id,ci.calif_id



		-- Se corrigio suma de totales -- 
		Alter table #CalifTemp add iTotal4Campaign int null

		if (select valor from ccSettings where setting_id = 78) = 0
		update #CalifTemp set iTotal4Campaign = 0

		else	
		update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
		from (select cam_id, sum(A.Total) iTotal4Campaign 
		from #CalifTemp A group by cam_id) t join #CalifTemp c
		on t.cam_id = c.cam_id

		if @type=1 
		select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total from (
			select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
			 else @nIdioma --substring(@nIdioma, 1, charindex('@', @nIdioma)-1) 
			 end as Calificacion,0 as subCalificacion ,0 as calif_id,count(disposition) as Total--,0 as iTotal4Campaign
			from ccriachats a left join ccTipoCalif b 
			on a.disposition=b.calif_id 
			where a.chatDate > @today
			and a.inboundId = @cam_id
			group by inboundId, Description
			
			union all
			
			
			select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex('@', @nIdioma)-1) 
			then calificacion 
			else @nIdioma --substring(@nIdioma, charindex('@', @nIdioma)+1, len(@nIdioma)) 
			end as Calificacion,
			case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total  --iTotal4Campaign -- para ver total por campaña
			from #CalifTemp 
			group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex('@', @nIdioma)-1) 
			then calificacion 
			else @nIdioma--substring(@nIdioma, charindex('@', @nIdioma)+1, len(@nIdioma)) 
			end, Cam_id,calif_id, iTotal4Campaign
		)  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id order by tipo,cam_id 
		if @type=0 

		select tipo as Type,Cam_id as CampId,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex('@', @nIdioma)-1) 
		then calificacion 
		else @nIdioma--substring(@nIdioma, charindex('@', @nIdioma)+1, len(@nIdioma)) 
		end as Calification,subCalificacion as SubCalificationQuantity, calif_id as CalificationId,sum(Total) as Total -- , iTotal4Campaign -- para ver total por campaña
		from #CalifTemp 
		group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex('@', @nIdioma)-1) 
		then calificacion 
		else @nIdioma--substring(@nIdioma, charindex('@', @nIdioma)+1, len(@nIdioma)) 
		end, Cam_id,subCalificacion, calif_id, iTotal4Campaign



		if @type = 3 begin -----entrada acd's
			select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
			else @nIdioma--substring(@nIdioma, 1, charindex('@', @nIdioma)-1) 
			end as Calificacion,isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(*) as totales 
			from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
			left join ccInbound cci on cci.inbound_id = ci.inbound_id 
			left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
			where ci.cal_inicio > @today
			and ci.inbound_id = @cam_id
			and statuscall_id = 13 
			and ci.calif_id = @calif_id
			group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id 
		end

		if @type = 4 begin --salida campañas
				select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
					then case when description is not null 
								then description 
								else @nIdioma--substring(@nIdioma, 1, charindex('@', @nIdioma)-1) 
								end
			else case when sll.descripcion is not null 
			then 'cw:' + sll.descripcion else 'cw:' + @nIdioma--substring(@nIdioma, 1, charindex('@', @nIdioma)-1) 
			end end as Calificacion,isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad 
			from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
			left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
			left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
			left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
			left join ccCamps ci on ci.cam_id = co.cam_id 
			where co.cal_inicio > @today
			and co.cam_id = @cam_id
			group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
		end 
		 

		drop table #CalifTemp 
		set nocount off