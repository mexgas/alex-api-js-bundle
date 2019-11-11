CREATE PROCEDURE [dbo].[ccsp_RIAChatPredefinedMsg]
@Type smallint,
@Type2 smallint,
@IDArea smallint=0,
@CamEspID smallint,
@User_id smallint,
@InsertMessage_id varchar(1000),
@DeleteMessage_id varchar(1000),
@serviceId smallint = 1 --Default Chat
AS
set nocount on

If @Type=1--get ACDGroups
 begin
	if @serviceId = 2 --1 chat, 2 Email
		begin
			set @serviceId = 3
		end
	SELECT a1.Inbound_id, descripcion, a2.graphic_id, a3.frame, a1.chat from ccInbound a1
	inner join ccRIAInboundGraph a2 on(a1.Inbound_id=a2.Inbound_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where a1.chat = @serviceId and isnull(a1.IDArea, -1) = case when @IDArea=0 then -1
	when (select login from ccusers where user_id = @User_id) = 'root' then isnull(a1.IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

IF @Type=2--query
 begin
	select i.Inbound_id, descripcion , c.message_id, description, [message]
	from ccInbound i inner join ccRIAChatInboundPredefinedMsg c on i.Inbound_id=c.Inbound_id
	inner join ccRIAChatPredefinedMsg m on m.message_id=c.message_id and m.serviceId=c.serviceId
	where m.message_status=1 and c.serviceId=@serviceId and i.Inbound_id=@CamEspID
	order by 4
	return(0)
 end

If @Type=3--get Areas
 begin
	if exists(select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id)
	and (select login from ccUsers where user_id=@User_id)<>'root'
		select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	else
		select * from ccRIACAT_Areas where StatusArea=1 order by AreaName
	return(0)
 end

declare @sql nvarchar(1000), @nIDArea nvarchar(10)

if @Type=4--Insert Message
 begin
	If @Type2=2
	 begin
		If exists(select inbound_id from ccRIAChatInboundPredefinedMsg where inbound_id=@CamEspID and message_id=@InsertMessage_id and serviceId=@serviceId)
			select 2
		else
			if exists(select inbound_id from ccInbound where Inbound_id=@CamEspID)
			and exists(select message_id from ccRIAChatPredefinedMsg where message_status=1 and message_id=@InsertMessage_id and serviceId=@serviceId)
					insert ccRIAChatInboundPredefinedMsg(inbound_id, message_id, serviceId) select @CamEspID, @InsertMessage_id, @serviceId
		return(0)
	 end

	If @Type2=1
	begin
		set @nIDArea = 0
		select @nIDArea=IDArea from ccUsers where USER_ID=@User_id
		if @nIDArea>0
		begin
			set @sql='insert ccRIAChatInboundPredefinedMsg (inbound_id,message_id,serviceId)
			select distinct a.inbound_id, b.message_id, b.serviceId from ccInbound a, ccRIAChatPredefinedMsg b where
			b.message_id in('+@InsertMessage_id+') and b.message_status=1 and b.serviceId='+cast(@serviceId as nvarchar)+'
			and not exists(select c.inbound_id, e.message_id, e.serviceId from ccRIAChatInboundPredefinedMsg c
			join ccRIAChatPredefinedMsg e on e.message_id=c.message_id and e.serviceId=c.serviceId
			join ccInbound d on d.inbound_id=c.inbound_id and IDArea='+@nIDArea+
			' where c.inbound_id=a.inbound_id and b.message_id=e.message_id and b.serviceId=e.serviceId)
			and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea='+@nIDArea+' and ((chat>0 and '+cast(@serviceId as nvarchar)+'=1) || ('+cast(@serviceId as nvarchar)+'<>1)))'
			declare @serviceType int
			if(@serviceId = 1)
				begin
					set @serviceType = 1
				end
			if(@serviceId = 2)
				begin
					set @serviceType = 3
				end
			set @sql='insert ccRIAChatInboundPredefinedMsg (inbound_id,message_id,serviceId)
			select distinct a.inbound_id, b.message_id, ' + cast(@serviceId as nvarchar) + ' from ccInbound a, ccRIAChatPredefinedMsg b where
			b.message_id in('+@InsertMessage_id+') and b.message_status=1 
			and not exists(select c.inbound_id, e.message_id, e.serviceId from ccRIAChatInboundPredefinedMsg c
			join ccRIAChatPredefinedMsg e on e.message_id=c.message_id and e.serviceId=c.serviceId
			join ccInbound d on d.inbound_id=c.inbound_id and IDArea='+@nIDArea+
			' where c.inbound_id=a.inbound_id and b.message_id=e.message_id and b.serviceId=e.serviceId)
			and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea='+@nIDArea+' and chat = '+ cast(@serviceType as nvarchar) +')'
			execute sp_executesql @sql
		end
	end
		return(0)
 end

If @Type=5--Delete Messages
 begin
	If @Type2=2
	 begin
		delete ccRIAChatInboundPredefinedMsg where inbound_id=@CamEspID	and message_id=@DeleteMessage_id and serviceId=@serviceId
		return(0)
	 end

	If @Type2=1
	begin
		set @nIDArea = 0
		select @nIDArea=IDArea from ccUsers where USER_ID=@User_id
		if @nIDArea>0
		begin
			set @sql='delete ccRIAChatInboundPredefinedMsg where inbound_id in(select inbound_id from
			ccInbound where IDArea='+@nIDArea+') and message_id in('+@DeleteMessage_id+') and serviceId =' + cast(@serviceId as nvarchar)
			execute sp_executesql @sql
		end
		return(0)
	end
 end

 If @Type=6 --get Areas
 begin
	select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	return(0)
 end

return(0)
set nocount off