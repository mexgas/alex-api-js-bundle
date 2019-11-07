create procedure dbo.ccsp_RIACATvoiceMail
@type tinyint,
@user_id smallint,
@ACDvm_id varchar(1000)=null,
@vmID varchar(1000)=null,
@mailbox varchar(50)=null,
@inbound_id smallint=null	
as
set nocount on
declare @IDarea smallint
select @IDarea=IDarea from ccUsers where user_id=@user_id

if isnull(@IDarea,'')=''
 begin
	select -1, 'invalid user area'
	return(0)
 end

if @type=1 -- Get acd catalog
 begin
	select Inbound_id, descripcion from ccInbound where IDArea=@IDArea order by descripcion
	return(0)
 end

if @type=2 -- Get mail vs inbound_id relationship by inbound_id
 begin
	if not exists(select inbound_id from ccInbound where inbound_id=@inbound_id and IDArea=@IDArea)
	 begin
		select -3, 'invalid inbound_id'
		return(0)
	 end

	select r.ACDvm_id, m.mailbox
	from ccRIA_vmMailBoxes m join ccRIA_vmACDMailBoxes r on m.vmID=r.vmID
	where r.inbound_id=@inbound_id and m.IDArea=@IDarea order by m.mailbox
	return(0)
 end

if @type=3 -- Get email catalog by user area
 begin
	select vmID, mailbox from ccRIA_vmMailBoxes where IDArea=@IDarea
	return(0)
 end

if @type=4 -- add mail vs inbound_id relationship
 begin
	if not exists(select vmID from ccRIA_vmMailBoxes where IDArea=@IDArea and vmID in (select value from dbo.fn_RIASplitDelimited(@vmID, ','))) 
	 begin
		select -5, 'invalid mailbox id'
		return(0)
	 end

	if not exists(select inbound_id from ccInbound where inbound_id=@inbound_id and IDArea=@IDArea)
	 begin
		select -3, 'invalid inbound_id'
		return(0)
	 end

	if not exists(select ACDvm_id from ccRIA_vmACDMailBoxes where inbound_id=@inbound_id and vmID in (select value from dbo.fn_RIASplitDelimited(@vmID, ',')))
		insert ccRIA_vmACDMailBoxes (vmID, inbound_id) 
		select vmID, @inbound_id from ccRIA_vmMailBoxes where IDArea=@IDArea and vmID in (select value from dbo.fn_RIASplitDelimited(@vmID, ',')) and
		cast(vmID as char(5))+'-'+cast(@inbound_id as char(5)) not in (select cast(vmID as char(5))+'-'+cast(inbound_id as char(5)) from ccRIA_vmACDMailBoxes)
		select 1 -- isnull(SCOPE_IDENTITY(), -7), 'relation exists'
	return(0)
 end

if @type=5 -- del mail vs inbound_id relationship
 begin
 	if not exists(select ACDvm_id from ccRIA_vmACDMailBoxes where ACDvm_id in (select value from dbo.fn_RIASplitDelimited(@ACDvm_id, ',')))
	 begin
		select -4, 'invalid relationship'
		return(0)
	 end

	select top 1 @inbound_id = inbound_id from ccRIA_vmACDMailBoxes where ACDvm_id in (select value from dbo.fn_RIASplitDelimited(@ACDvm_id, ','))
	delete ccRIA_vmACDMailBoxes where ACDvm_id in (select value from dbo.fn_RIASplitDelimited(@ACDvm_id, ','))
	select @inbound_id
	return(0)
 end

if @type=6 -- Insert email into catalog
 begin
	if len(replace(isnull(@mailbox,''),' ',''))<10
	 begin
		select -2, 'invalid mailbox adress'
		return(0)
	 end

	if not exists (select mailbox from ccRIA_vmMailBoxes where mailbox=@mailbox and @IDArea=IDArea)
		insert ccRIA_vmMailBoxes (mailbox, IDarea) select @mailbox, @IDarea

	select isnull(SCOPE_IDENTITY(),-6), 'mailbox exists'
	return(0)
 end

if @type=7 -- update mail
 begin
	if not exists(select mailbox from ccRIA_vmMailBoxes where vmID=@vmID and IDArea=@IDArea) 
	 begin
		select -5, 'invalid mailbox id'
		return(0)
	 end

	if len(replace(isnull(@mailbox,''),' ',''))<10 
	 begin
		select -2, 'invalid mailbox adress'
		return(0)
	 end

	if exists(select mailbox from ccRIA_vmMailBoxes where mailbox=@mailbox and IDArea=@IDArea and vmID<>@vmID) 
	 begin
		select -6, 'mailbox exists'
		return(0)
	 end

	update ccRIA_vmMailBoxes set mailbox=@mailbox where vmID=@vmID
	return(0)
 end

if @type=8 -- check mail references
 begin
	if exists(select ACDvm_id from ccRIA_vmACDMailBoxes where vmID in (select vmID from ccRIA_vmMailBoxes where vmID=@vmID and IDArea=@IDArea))
		select -8, 'mail with active relationships'	
	return(0)
 end

if @type=9 -- del mail
 begin
	if not exists(select mailbox from ccRIA_vmMailBoxes where vmID=@vmID and IDArea=@IDArea) 
	 begin
		select -5, 'invalid mailbox id'
		return(0)
	 end

	delete ccRIA_vmMailBoxes where vmID=@vmID
	return(0)
 end

set nocount off