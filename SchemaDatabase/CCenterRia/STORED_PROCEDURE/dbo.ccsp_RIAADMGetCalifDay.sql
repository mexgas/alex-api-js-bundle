CREATE Procedure [dbo].[ccsp_RIAADMGetCalifDay]
		@type smallint = null,
		@inbound_id smallint = null,
		@calif_id smallint = null,
		@cam_id smallint = null
		AS
		set nocount on
		create table #CalifTemp (
		id int identity,
		tipo integer,
		Cam_id varchar(60),
		Calificacion varchar(60),
		subCalificacion varchar(60) null,
		calif_id smallint null,
		Total int,
		iTotal4Campaign int null)

		declare @typeACD smallint --= 0
		declare @today datetime
		declare @nIdioma varchar(22),@nIdiomaSub varchar(22)

		set @today = convert(datetime, convert (varchar(11), getdate(), 101))
		select @typeACD = chat from ccInbound  where Inbound_id = @inbound_id


		select @nIdioma = case valor when 0 then 'Sin calificación Otros' else 'No disposition Others' end,
		@nIdiomaSub = case valor when 0 then 'Sin Subcalificación' else 'No Subdisposition' end
		from ccsettings where setting_id = 27 -- 0 esp

		---------------OUT ----------------------------
		if @type=0 begin
		    insert into #CalifTemp
		    select 0 as tipo,co.cam_id as cam_id,
		    case when co.statuscall_id = 13
			   then case when description is not null
			   then description else @nIdioma end
		    else case when sll.descripcion is not null then 'cw:' + sll.descripcion
		    else 'cw:' + @nIdioma
		    end end as Calificacion
		    ,0 as subCalificaion,
		    co.calif_id,count(*) cantidad,0 as iTotal4Campaign
		    from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
		    left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
		    left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
		    left join ccCamps ci on ci.cam_id = co.cam_id
		    where co.cal_inicio > @today
		    group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id

		    select tipo,Cam_id, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end as Calificacion,
		    case when count(subCalificacion)>0 then 1 else 0 end subCalificacion, calif_id,sum(Total) as Total
		    from #CalifTemp
		    group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end, Cam_id, iTotal4Campaign,calif_id

		end
		---------------IN ----------------------------
		else if @type = 1 begin

		    if @typeACD = 0 begin  --Calls
		    insert into #CalifTemp
		    select @typeACD as tipo,cci.inbound_id as cam_id, description as Calificacion
				  ,case when count(ci.califSub_id) >0 then 1 else 0 end as subCalificacion,ci.calif_id
				  ,count(*) as total,0 as iTotal4Campaign
				  from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
				  left join ccTipoCalif ca on ci.calif_id = ca.calif_id
				  left join ccInbound cci on cci.inbound_id = ci.inbound_id
				  left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
				  where ci.cal_inicio > @today and statuscall_id = 13	and cci.Inbound_id=@inbound_id
				  group by description, cci.inbound_id,ci.calif_id

		    if (select valor from ccSettings where setting_id = 78) = 0 begin
			   update #CalifTemp set iTotal4Campaign = 0
		    end
		    else begin
		    update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign
			   from (
				  select cam_id, sum(A.Total) iTotal4Campaign from #CalifTemp A group by cam_id) t
			   inner join #CalifTemp c on t.cam_id = c.cam_id
		    end
		    end
		    else if @typeACD = 1 begin--Chats
		    insert into #CalifTemp(tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
		    select @typeACD as tipo, inboundId as Cam_id, [description] as Calificacion,
				  case when sum(case when a.subDisposition = 0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
				  a.disposition as calif_id, count(disposition) as Total
				  from ccriachats a
				  left join ccTipoCalif b on a.disposition=b.calif_id
			   where a.chatDate > @today and
			   a.chatStatus=4 and a.inboundId=@inbound_id
		    group by inboundId, [description],disposition
		    end
		    else if @typeACD = 3 begin ---Mail
		    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
		    select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
		    case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
		    relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
		    from conversation conver
		    inner join message mess on mess.conversationId = conver.conversationId
		    left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
		    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
		    where mess.date > @today and
		    conver.inboundId=@inbound_id and mess.messageStatusId >= 5
		    group by conver.inboundId,relmesdis.dispositionId,disp.Description

		    end
		    else if @typeACD = 4 begin --calif twetter
		    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
		    select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
		    case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
		    relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
		    from conversationTwitter conver
		    inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
		    left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
		    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
		    where mess.date > @today and
		    conver.inboundId=@inbound_id and mess.messageStatusId >= 5
		    group by conver.inboundId,relmesdis.dispositionId,disp.Description

		    end
		    select camtemp.tipo,camtemp.cam_id,
		    case when tipcal.Description is not null then tipcal.Description else @nIdioma end as Calificacion,
		    camtemp.subcalificacion,camtemp.calif_id,camtemp.total
		    from #CalifTemp camtemp
		    left join ccTipoCalif tipcal on camtemp.calif_id =  tipcal.calif_id
		end
		-------------------SUBCALIFICACIONES IN-------------------
		else if @type = 2 begin
		    if @typeACD = 0 begin --Calls
		    select @typeACD as Type,cci.inbound_id as CampId,  [description] as Calification,
		    isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName, count(ctcs.califSubDesc) as Quantity
		    from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
		    left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		    left join ccInbound cci on cci.inbound_id = ci.inbound_id
		    left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
		    where ci.cal_inicio > @today
		    and ci.inbound_id = @inbound_id  and statuscall_id = 13  and ci.calif_id = @calif_id
		    group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id
		    end
		    else if @typeACD = 1 begin --Chat
		    select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
				  isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
				  from ccriachats a
				  left join ccTipoCalif b on a.disposition=b.calif_id
				  left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
				  where a.chatDate > @today and
				  a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id
				  group by inboundId, [description],ctcs.califSubDesc
		    end
		    else if @typeACD = 3 begin --Mail
		    select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
		    isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
		    from conversation conver
		    inner join message mess on mess.conversationId = conver.conversationId
		    left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
		    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
		    left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
		    where mess.date > @today and
		    mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
		    group by conver.inboundId,disp.Description,subDisp.califSubDesc


		    end
		    else if @typeACD = 4 begin --Twitter
		    select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
		    isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
		    from conversationTwitter conver
		    inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
		    left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
		    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
		    left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
		    where mess.date > @today and
		    mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
		    group by conver.inboundId,disp.Description,subDisp.califSubDesc
		    end

		end
		-------------------SUBCALIFICACIONES OUT-------------------
		else if @type = 4 begin
		    select 0 as Type,co.cam_id as CampId,
		    case when co.statuscall_id = 13
		    then case when description is not null
		    then description else @nIdioma end
		    else
		    case when sll.descripcion is not null
		    then 'cw:' + sll.descripcion else 'cw:' + @nIdioma
		    end
		    end as Calification,
		    isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(cso.califSub_id) Quantity
		    from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
		    left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
		    left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id 
		    left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
		    left join ccCamps ci on ci.cam_id = co.cam_id
		    where co.cal_inicio > @today
		    and co.cam_id = @inbound_id
		    and co.calif_id = @calif_id
		    group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
		end


		drop table #CalifTemp
		set nocount off