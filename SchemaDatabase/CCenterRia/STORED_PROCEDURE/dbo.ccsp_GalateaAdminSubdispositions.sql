CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSubdispositions]
@command int,
@califSub_id smallint = null,
@califSubIdLst varchar(max) = null,
@califSubDesc varchar(60) = null,
@order varchar(3) = null,
@canReprogram bit = null,
@endConversation bit=null,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null
AS
set nocount on
declare @inserted table (ID smallint)

if @command=1 -- Load Inbound Subdispositions
begin
  select califSub_id, IsNull(califSubDesc,'') [califSubDesc], orden, canReprogram,
  IsNull(EndConversation,0) EndConversation
  from ccTipoCalifSub
  where califSub_Status = 1
  order by 2
  return(0)
end

If @command=2 -- Load Outbound Subdispositions
begin
  select califSub_id, IsNull(califSubDesc,'') [califSubDesc],
  IsNull(canReprogram, 0) [canReprogram],
  IsNull(orden, 0) [orden],
  IsNull(keepDial, 0) [keepDial],
  IsNull(autoCallback, 0) [autoCallback],
  IsNull(contactOwner, 0) [contactOwner]
  from ccTipoCalifSubOut
  where califSubOut_Status = 1
  order by 2
  return(0)
end

if @command=3	-- New Inbound Subdisposition
begin
	if(exists(select califSub_id from ccTipoCalifSub where califSub_Status = 1 and califSubDesc=@califSubDesc))
	begin
		select cast(-1 as smallint) [result]	-- Subdisposition already exists
		return(0)
	end

	if(exists(select califSub_id from ccTipoCalifSub where califSub_Status=0 and califSubDesc=@califSubDesc))
	begin
		select top 1 @califSub_id = califSub_id from ccTipoCalifSub where califSub_Status=0 and califSubDesc=@califSubDesc order by califSub_id desc
		update ccTipoCalifSub set orden=isnull(@order,0), canReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0),
		califSub_Status=1
		output inserted.califSub_id into @inserted
		where califSub_id=@califSub_id
		select ID [result] from @inserted
		return(0)
	end

	insert into ccTipoCalifSub (califSubDesc, orden, canReprogram, califSub_Status, EndConversation)
	select @califSubDesc, isnull(@order,0), isnull(@canReprogram,0), 1, isnull(@endConversation,0)
	select cast(SCOPE_IDENTITY() as smallint) [result]
	return(0)
end

if @command=4	-- New Outbound Subdisposition
begin
	if(exists(select califSub_id from ccTipoCalifSubOUT where califSubOut_Status = 1 and califSubDesc=@califSubDesc))
	begin
		select cast(-1 as smallint) [result]	-- Subdisposition already exists
		return(0)
	end

	if(exists(select califSub_id from ccTipoCalifSubOUT where califSubOut_Status=0 and califSubDesc=@califSubDesc))
	begin
		select top 1 @califSub_id = califSub_id from ccTipoCalifSubOUT where califSubOut_Status=0 and califSubDesc=@califSubDesc order by califSub_id desc
		update ccTipoCalifSubOUT set orden=isnull(@order,0), canReprogram=isnull(@canReprogram,0),idTipoLista=0,
		califSubOut_Status=1, keepDial=isnull(@keepDial,0), autoCallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0)
		output inserted.califSub_id into @inserted
		where califSubDesc=@califSubDesc
		select ID [result] from @inserted
		return(0)
	end

	insert into ccTipoCalifSubOUT (califSubDesc, orden, canReprogram, califSubOut_Status, keepDial, autoCallback, contactOwner)
	select @califSubDesc, isnull(@order,0), isnull(@canReprogram,0), 1, isnull(@keepDial,0), isnull(@autoCB,0), isnull(@contactOwner,0)
	select cast(SCOPE_IDENTITY() as smallint) [result]
	return(0)
end

if @command=5	-- Delete Inbound Subdisposition
begin
	delete cctipoSubCalifRel where tipoSubRel=1 and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, ','))
	update cctipocalifSub set califSub_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, ','))
	return(0)
end

if @command=6	-- Delete Outbound Subdisposition
begin
	delete cctipoSubCalifRel where tipoSubRel=0 and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, ','))
	update cctipocalifSubOUT set califSubOut_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, ','))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
end

if @command=7	-- Update Inbound Subdisposition
begin
	if(exists(select califSub_id from ccTipoCalifSub where califSub_Status=1 and califSubDesc=@califSubDesc and califSub_id<>@califSub_id))
	begin
		select cast(-1 as smallint) [result]	-- Subdisposition already exists
		return(0)
	end

	if @canReprogram=1
	begin
		declare @asignada bit, @can bit
		select @asignada=IB.inbound_id, @can=IB.cam_id
		from cctipoSubCalifRel CR join cctipoCalif TC on CR.calif_id = TC.calif_id and CR.tipoSubRel=1
		join ccCalifCamp CM on TC.calif_id = CM.calif_id and CM.tipo = 0 join ccInbound IB on CM.cam_id = IB.inbound_id
		where califSub_id = cast(@califSub_id as smallint)
		if @asignada is not null and @can is null
		begin
			select cast(-2 as smallint) [result]	-- Cant reprogram, there are not assigned campaign
			return(0)
		end
	end

	update ccTipoCalifSub set califSubDesc=isnull(@califSubDesc, califSubDesc), orden=isnull(@order, orden), canReprogram=isnull(@canReprogram, canReprogram),
	EndConversation=isnull(@endConversation, EndConversation)
	output inserted.califSub_id into @inserted
	where califSub_id=@califSub_id

	delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	select ID [result] from @inserted
	return(0)
end

if @command=8	-- Update Outbound Subdisposition
begin

	if(exists(select califSub_id from ccTipoCalifSubOUT where califSubOut_Status=1 and califSubDesc=@califSubDesc and califSub_id<>@califSub_id))
	begin
		select cast(-1 as smallint) [result]	-- Subdisposition already exists
		return(0)
	end

	update ccTipoCalifSubOUT set califSubDesc=isnull(@califSubDesc, califSubDesc), canReprogram=isnull(@canReprogram, canReprogram),
	orden=isnull(@order, orden), keepDial=isnull(@keepDial, keepDial), autoCallback=isnull(@autoCB, autoCallback), contactOwner=isnull(@contactOwner,contactOwner)
	output inserted.califSub_id into @inserted
	where califSub_id=@califSub_id
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)

	select ID [result] from @inserted
	return(0)
end


set nocount off