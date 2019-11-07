create procedure [dbo].[ccsp_RIAMultimediaSignature]
@action smallint,
@Description as varchar(40) = null,
@htmlText as varchar(max) = null,
@signature_id as smallint = null,
@campAcd_id as smallint = null
as
set nocount on

if @action = 1 --Load initial info
begin
	select ci.inbound_id, descripcion, graphic_id from ccinbound ci (nolock) join ccRIAInboundGraph cg (nolock) on cg.Inbound_id = ci.Inbound_id where status=1 and chat=3
	select signature_id,description from ccRIAMultimediaSignatures nolock where status=1

	return(0)
end

if @action = 2 --Load Signatures
begin
	select signature_id,description,htmltext from ccRIAMultimediaSignatures nolock where status=1
	return(0)
end

if @action = 3 --Load relations
begin
	select sg.signature_id,description,htmltext from ccRIAMultimediaSignatureRel re (nolock)
	join ccRIAMultimediaSignatures sg (nolock) on sg.signature_id = re.signature_id where campAcd_id = @campAcd_id or @campAcd_id = 0
	return(0)
end

if @action = 4 --Add signature
begin
	If exists(select description from ccRIAMultimediaSignatures where Status=1 and description=@Description)
	 begin
		select 2
		return(0)
	 end

	If exists(select description from ccRIAMultimediaSignatures where Status=0 and description=@Description)
	begin
		update ccRIAMultimediaSignatures set Status=1,htmlText=@htmlText where description=@Description
		return(0)
	end

	insert into ccRIAMultimediaSignatures (signature_id, description, htmlText)
	select isnull(max(signature_id), 0) + 1,@Description,@htmlText from ccRIAMultimediaSignatures
	return(0)
end

if @action = 5 --Update signature
begin
	If exists(select description from ccRIAMultimediaSignatures where Status=1 and description=@Description)
		set @Description=null

	UPDATE ccRIAMultimediaSignatures set Description=isnull(@Description, Description), htmlText=isnull(@htmlText, htmlText)
	where signature_id = @signature_id
	return(0)
end

if @action = 6 --Delete signature
begin
	delete ccRIAMultimediaSignatureRel where signature_id = @signature_id
	update ccRIAMultimediaSignatures set Status=0 where signature_id = @signature_id
	return(0)
end

if @action = 7 --Delete relation
begin
	delete ccRIAMultimediaSignatureRel where signature_id = @signature_id and (campAcd_id = @campAcd_id /*or @campAcd_id = 0*/)
	return(0)
end

if @action = 8 --Add relation
begin
	if not exists(select * from ccRIAMultimediaSignatureRel where signature_id = @signature_id and campAcd_id = @campAcd_id)
	begin
		delete ccRIAMultimediaSignatureRel where campAcd_id = @campAcd_id --only one
		insert ccRIAMultimediaSignatureRel (signature_id, campAcd_id) values (@signature_id, @campAcd_id)
	end
	return(0)
end

set nocount off