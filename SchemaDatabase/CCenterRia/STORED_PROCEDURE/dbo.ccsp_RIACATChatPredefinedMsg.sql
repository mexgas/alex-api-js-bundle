CREATE PROCEDURE [dbo].[ccsp_RIACATChatPredefinedMsg]
@message_id varchar(max)=null,
@Description varchar(40)=null,
@message varchar(max)=null,
@Type smallint,
@CamEspId smallint=null,
@serviceId smallint=1
AS
set nocount on
declare @sql nvarchar(1000)

if @Type=1 -- Load
 begin
	Select message_id, description, [message] from ccRIAChatPredefinedMsg where message_status=1 and serviceId = @serviceId order by 2
	return(0)
 end

If @Type=2 -- New
 begin
	If exists(select description from ccRIAChatPredefinedMsg where message_status=1 and description=@Description and serviceId = @serviceId)
	 begin
		select -1
		return(0)
	 end

	declare @msg_id smallint
	set @msg_id = 0
	select top 1 @msg_id=message_id from ccRIAChatPredefinedMsg where message_status=0 and description=@Description
	If @msg_id>0
	begin
		update ccRIAChatPredefinedMsg set message_status=1, [message]=@message where description=@Description
		select @msg_id
		return(0)
	end

	insert into ccRIAChatPredefinedMsg (description, [message],serviceId) values (@Description,@message,@serviceId )
	select SCOPE_IDENTITY()
	return(0)
 end

If @Type=3 -- Update
 begin
	If exists(select description from ccRIAChatPredefinedMsg where message_status=1 and message_id=@message_id and serviceId = @serviceId)
	begin
		UPDATE ccRIAChatPredefinedMsg set Description=@Description ,[message]=isnull(@message, [message])
		where message_id in (select value from dbo.fn_RIASplitDelimited(@message_id, ','))
	end
	
	return(0)
 end

If @Type=4 -- Delete
 begin
	delete from ccRIAChatInboundPredefinedMsg where message_id in (select value from dbo.fn_RIASplitDelimited(@message_id, ',')) and serviceId = @serviceId
	update ccRIAChatPredefinedMsg set message_status=0 where message_id in (select value from dbo.fn_RIASplitDelimited(@message_id, ',')) and serviceId = @serviceId
	return(0)
 end

If @Type=5 --Relation
 begin
	select description from ccRIAChatPredefinedMsg where message_id=@message_id
	return(0)
 end

set nocount off