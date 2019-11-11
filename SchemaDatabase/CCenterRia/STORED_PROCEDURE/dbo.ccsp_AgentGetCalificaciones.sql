CREATE procedure [dbo].[ccsp_AgentGetCalificaciones]
@InOut tinyint, --0 in, 1 out
@cam_id int, --ADC or CAMP Id
@isXml bit=1

AS
set nocount on
declare @sql varchar(max)

IF @InOut = 0 BEGIN
if exists(
	select calif.calif_id from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
	left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
	left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
	where cam_id = @cam_id and tipo = @InOut)
  begin
	 declare @relationCamId int
	select @relationCamId =cam_id from ccInbound where Inbound_id=@cam_id
	if @relationCamId is null set @relationCamId=0

	set @sql ='
	select distinct 1 as tag, null as parent, calif.calif_id "selection!1!id", calif.Description "selection!1!string", calif.orden "selection!1!califorden",
		isnull(calif.EndConversation,0) "selection!1!endConversation",
		null "subSelection!2!id", null "subSelection!2!string", null "subSelection!2!orden",  null "subSelection!2!endConversation",
		isnull(calif.CanReprogram,0) "selection!1!canReprogram", null "subSelection!2!canReprogram"
		from ccTipoCalif calif
	 inner join ccCalifCamp camp on camp.calif_id=calif.calif_id 
	 and camp.cam_id='+convert(varchar(max), @cam_id)+' and  camp.tipo = '+convert(varchar(max), @InOut)+'
	 left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
	 left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
	 where calif.CanReprogram=0 or (
		calif.CanReprogram=1 and '+convert(varchar(max), @relationCamId)+'>0
	 )
	 union
	 select distinct 2 as tag, 1 as parent, calif.calif_id "selection!1!id", null "selection!1!string", calif.orden "selection!1!califorden", isnull(calif.EndConversation,0) "selection!1!endConversation",
		sb.califsub_id "subSelection!2!id", sb.califSubDesc "subSelection!2!string", cast(sb.orden as int) "subSelection!2!orden" ,isnull(sb.EndConversation,0) "subSelection!2!endConversation",
		null "selection!1!canReprogram", isnull(sb.CanReprogram,0) "subSelection!2!canReprogram"
		from ccTipoCalif calif
		inner join ccCalifCamp camp on camp.calif_id=calif.calif_id and camp.cam_id='+convert(varchar(max), @cam_id)+' and  camp.tipo = '+convert(varchar(max), @InOut)+'
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where sb.califsub_id is not null
		and (
			sb.CanReprogram=0 or
			(sb.CanReprogram=1 and '+convert(varchar(max), @relationCamId)+'>0)
		)'
	  
	  if @isXml=1 begin
		set @sql= @sql+' order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type'
	  end
	  else begin 
	  set @sql='select 
				tag as Tag, isnull(parent,0) as Parent, "selection!1!id" as Id,isnull("selection!1!string",'''') as Description,
				"selection!1!califorden" as Orden, "selection!1!endConversation" EndConversation, isnull("subSelection!2!id",0) as SubId,
				isnull("subSelection!2!string",'''') as SubDescription, isnull("subSelection!2!orden",0) as SubOrden,	
				isnull("subSelection!2!endConversation",0) as SubEndConversation, 
				isnull("selection!1!canReprogram",0) as CanReprogram,isnull("subSelection!2!canReprogram",0) as SubCanReprogram
			from (  ' + @sql+' )X'
	  end
	  print (@sql)
	  exec (@sql)
  end
 return(0)
 END

IF @InOut = 1 BEGIN
 if exists(
	select calif.calif_id from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
	left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
	left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
	where cam_id = @cam_id and tipo = @InOut)
  begin
	set @sql ='
		select distinct 1 as tag, null as parent, calif.calif_id "selection!1!id", calif.Description "selection!1!string", calif.keepDial "selection!1!keepOnDial",
		calif.orden "selection!1!califorden", isnull(calif.finishPreview,0) "selection!1!finishPreview", null "subSelection!2!id", null "subSelection!2!string", null "subSelection!2!keepOnDial",
		null "subSelection!2!orden",   isnull(calif.CanReprogram,0) "selection!1!canReprogram", null "subSelection!2!canReprogram"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = '+convert(varchar(max), @cam_id)+' and tipo = '+convert(varchar(max),@InOut)+'
		union
		select distinct 2 as tag, 1 as parent, calif.calif_id "selection!1!id", null "selection!1!string", null "selection!1!keepOnDial",
		calif.orden "selection!1!califorden", isnull(calif.finishPreview,0) "selection!1!finishPreview", sb.califsub_id "subSelection!2!id", sb.califSubDesc "subSelection!2!string",
		sb.keepDial "subSelection!2!keepOnDial",
		cast(sb.orden as int) "subSelection!2!orden",
		null "selection!1!canReprogram", isnull(sb.CanReprogram,0) "subSelection!2!canReprogram"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = '+convert(varchar(max), @cam_id)+' and tipo ='+convert(varchar(max),@InOut)+' and sb.califsub_id is not null	'
		if @isXml=1 begin
			set @sql= @sql+' order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type'
		end
		else begin 
		  set @sql='select 	tag as Tag, isnull(parent,0) Parent, "selection!1!id" as Id,isnull("selection!1!string",'''') as Description,
					isnull("selection!1!keepOnDial",'''') as KeepOnDial,
					"selection!1!califorden" as Orden, "selection!1!finishPreview" FinishPreview, isnull("subSelection!2!id",0) as SubId,
					isnull("subSelection!2!string",'''') as SubDescription,isnull("subSelection!2!keepOnDial",0) as SubKeepOnDial,
					isnull("subSelection!2!orden",0) as SubOrden,
					isnull("selection!1!canReprogram", 0) CanReprogram,  isnull("subSelection!2!canReprogram",0) SubCanReprogram
					
				from (  ' + @sql+' )X'
		  end
		  print @sql
		exec (@sql)
  end
 return(0)
 END

IF @InOut = 10
 BEGIN
  select distinct S.califSub_id, S.califSubDesc, orden
  from cctipoSubCalifRel R join cctipoCalifSub S on R.califSub_id = S.califSub_id
 where R.tipoSubRel=1 and S.califSub_Status=1 and R.calif_id=@cam_id
 order by S.orden, S.califSubDesc
 return(0)
 END

IF @InOut = 11
 BEGIN
  select distinct S.califSub_id, S.califSubDesc, orden
  from cctipoSubCalifRel R join cctipoCalifSubOut S on R.califSub_id = S.califSub_id
 where R.tipoSubRel=0 and S.califSubOut_Status=1 and R.calif_id=@cam_id
 order by S.orden, S.califSubDesc
 return(0)
 END

set nocount off