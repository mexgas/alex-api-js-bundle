USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccspSaveDispositionResult]    Script Date: 20/12/2023 12:58:29 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccspSaveDispositionResult]
@action int,
@callType TINYINT=null,
@camId int =null,
@callid BIGINT=0,
@statusCallId int=0,
@dispotitionId int=null,
@subDispotitionId int=null
AS

declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
declare @callTypeInOut tinyint
if @action in(3,4) begin
	select @nIdioma = case valor when 0 then 'Sin calificación Otros' else 'No disposition Others' end
	from ccsettings where setting_id = 27 -- 0 esp
	
end
if @action in(5,6) begin	
	select @nIdiomaSub = case valor when 0 then 'Sin Subcalificación' else 'No Subdisposition' end
	from ccsettings where setting_id = 27 -- 0 esp	
end

set @callTypeInOut= case when @callType=1 then 0 else 1 end


if @action=0 begin
	declare @today date
	set @today =CONVERT(date,getdate())

	truncate table ccDispositionDashboardResultOut
	truncate table ccDispositionDashboardResultIn

	insert into ccDispositionDashboardResultOut
	select cam_id as CamId,statusCall_id as statusCallId,cal_id as callId
	,calif_id as Disposition
	,case  when califSub_id<=0 or califSub_id is null then 0 else califSub_id end as SubDispotitionId 
	from ccoCallsOut 
	where cal_Inicio>=@today

	insert into ccDispositionDashboardResultIn
	select Inbound_id as CamId,statusCall_id as statusCallId,cal_id as callId
	,calif_id as Disposition
	,case  when califSub_id<=0 or califSub_id is null then 0 else califSub_id end as SubDispotitionId 
	from ccCallsIn 
	where cal_Inicio>=@today
end
else if @action=1 begin
	set @dispotitionId=0
	set @subDispotitionId=0
	if @callType=1 begin
		insert into ccDispositionDashboardResultOut values(@camId,@statusCallId,@callid,@dispotitionId,@subDispotitionId)
	end
	else begin
		insert into ccDispositionDashboardResultIn values(@camId,@statusCallId,@callid,@dispotitionId,@subDispotitionId)
	end
end
else if @action=2 begin
	set @subDispotitionId=case when @subDispotitionId is null then null when @subDispotitionId>0 then @subDispotitionId else 0 end
	if @callType=1 begin
		update ccDispositionDashboardResultOut set statusCallId=@statusCallId,DispotitionId=isnull(@dispotitionId,DispotitionId)
		,SubDispotitionId=isnull(@subDispotitionId,SubDispotitionId)
		where callId=@callid 
	end
	else begin
		update ccDispositionDashboardResultIn set statusCallId=@statusCallId,DispotitionId=isnull(@dispotitionId,DispotitionId)
		,SubDispotitionId=isnull(@subDispotitionId,SubDispotitionId)
		where callId=@callid 
	end
end
else if @action=3 begin	
	select @callTypeInOut as tipo,dash.CamId as CamId
	,case when dash.statusCallId = 13 then
		case when ca.[description] is not null then ca.[description] else @nIdioma end
		else case when sll.descripcion is not null then 'cw:' + sll.descripcion else 'cw:' + @nIdioma end
	end as Calificacion
	,case when count( case when dash.SubDispotitionId>0 then 1 end ) > 0 then 1 else 0 end as WithSubDisposition
	,dash.DispotitionId as DispotitionId
	,count(*) Amount
	,ISNULL(GraphColor,'1DB4E2') GraphColor
	from ccDispositionDashboardResultOut dash with(nolock)
	left join ccTipoCalifOut ca on dash.DispotitionId = ca.calif_id 
	left join ccTipoCalifSubOUT tcsout on dash.SubDispotitionId = tcsout.califSub_id
	left join ccstatusllamada sll on sll.statuscall_id = dash.statusCallId
	left join ccCamps ci on ci.cam_id = dash.CamId
	where CamId=@camId
	group by  dash.CamId, dash.statusCallId,ca.[description],sll.descripcion,dash.DispotitionId,GraphColor

end
else if @action=4 begin	
	select @callTypeInOut as tipo
	,dash.CamId
	,case when ca.[Description] is not null then ca.[Description] else @nIdioma end as Calificacion
	,case when count( case when dash.SubDispotitionId>0 then 1 end ) > 0 then 1 else 0 end as WithSubDisposition
	,dash.DispotitionId
	,count(*)  as Amount
	,ISNULL(GraphColor,'1DB4E2') GraphColor
	from ccDispositionDashboardResultIn dash with(nolock)
	left join ccTipoCalif ca on dash.DispotitionId = ca.calif_id 
	left join ccInbound cci on cci.inbound_id = dash.CamId 
	where dash.CamId = @camId and dash.statusCallId = 13 
	group by ca.[Description], dash.CamId,dash.SubDispotitionId,dash.DispotitionId,GraphColor

end

else if @action=5 begin	
	select 0 as Type,co.CamId as CampId,
	case when co.statusCallId = 13
	then case when description is not null
	then description else @nIdioma end
	else
	case when sll.descripcion is not null
	then 'cw:' + sll.descripcion else 'cw:' + @nIdioma
	end
	end as Calification,
	isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(cso.califSub_id) Quantity
	from ccDispositionDashboardResultOut co with(nolock)
	left join ccTipoCalifOut ca on co.DispotitionId = ca.calif_id
	left join ccTipoCalifSubOUT cso on co.SubDispotitionId = cso.califSub_id 
	left join ccstatusllamada sll on sll.statuscall_id = co.statusCallId
	left join ccCamps ci on ci.cam_id = co.CamId
	where co.CamId = @camId
	and co.DispotitionId = @dispotitionId
	group by  co.CamId, co.statusCallId,description,descripcion,cso.califSubDesc
end
else if @action=6 begin	
	select 0 as [type],CamId as CampId
	, ca.[description] as Calification
	, isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName
	, count(ctcs.califSubDesc) as Quantity
	--,dash.DispotitionId
	from ccDispositionDashboardResultIn dash with(nolock)
	left join ccTipoCalif ca on dash.DispotitionId = ca.calif_id
	left join ccInbound cci on cci.inbound_id = dash.CamId
	left join ccTipoCalifSub ctcs on dash.SubDispotitionId = ctcs.califSub_id
	where dash.CamId=@camId and dash.statusCallId=13 and dash.DispotitionId=@dispotitionId
	group by ca.description, dash.CamId,ctcs.califSubDesc,dash.DispotitionId
end
