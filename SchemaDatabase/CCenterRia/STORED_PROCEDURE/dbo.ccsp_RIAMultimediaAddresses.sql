CREATE procedure [dbo].[ccsp_RIAMultimediaAddresses]
@action smallint,
@Description as varchar(40) = null,
@address as varchar(254) = null,
@address_id as smallint = null,
@campAcd_id as smallint = null
as
set nocount on

if @action = 1 --Load initial info
begin
	select ci.inbound_id, descripcion, graphic_id from ccinbound ci (nolock) join ccRIAInboundGraph cg (nolock) on cg.Inbound_id = ci.Inbound_id where status=1 and chat=3
	select address_id,description,address from ccRIAMultimediaAddress nolock where status=1

	return(0)
end

if @action = 2 --Load addresses
begin
	select address_id,description,address from ccRIAMultimediaAddress nolock where status=1
	return(0)
end

if @action = 3 --Load relations
begin
	select sg.address_id,description,address from ccRIAMultimediaAddressRel re (nolock)
	join ccRIAMultimediaAddress sg (nolock) on sg.address_id = re.address_id where campAcd_id = @campAcd_id or @campAcd_id = 0
	return(0)
end

if @action = 4 --Add Address
begin
	If exists(select description from ccRIAMultimediaAddress where Status=1 and address=@address)
	 begin
		select 2
		return(0)
	 end

	If exists(select description from ccRIAMultimediaAddress where Status=0 and address=@address)
	begin
		update ccRIAMultimediaAddress set Status=1,address=@address where description=@Description
		return(0)
	end

	insert into ccRIAMultimediaAddress (address_id, description, address)
	select isnull(max(address_id), 0) + 1,@Description,@address from ccRIAMultimediaAddress
	return(0)
end

if @action = 5 --Update Address
begin
	If exists(select description from ccRIAMultimediaAddress where Status=1 and address=@address)
		set @Description=null

	UPDATE ccRIAMultimediaAddress set Description=isnull(@Description, Description), address=isnull(@address, address)
	where address_id = @address_id
	return(0)
end

if @action = 6 --Delete Address
begin
	delete ccRIAMultimediaAddressRel where address_id = @address_id
	update ccRIAMultimediaAddress set Status=0 where address_id = @address_id
	return(0)
end

if @action = 7 --Delete relation
begin
	delete ccRIAMultimediaAddressRel where address_id = @address_id and (campAcd_id = @campAcd_id /*or @campAcd_id = 0*/)
	return(0)
end

if @action = 8 --Add relation
begin
	if not exists(select * from ccRIAMultimediaAddressRel where address_id = @address_id and campAcd_id = @campAcd_id)
	begin
		insert ccRIAMultimediaAddressRel (address_id, campAcd_id) values (@address_id, @campAcd_id)
	end
	return(0)
end
set nocount off