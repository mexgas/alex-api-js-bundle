CREATE PROCEDURE [dbo].[ccsp_RIAChatCATMessages]
@command tinyint,
@msg_id int=0,
@Description varchar(40)='',
@msg varchar(255) = ''

AS
set nocount on
If @command=0
begin
SELECT Descripcion FROM ccRIAChatMsg WHERE msg_id=@msg_id
return(0)
end 

If @command=1
begin
SELECT msg_id, msg,Descripcion from ccRIAChatMsg order by msg_id
return(0)
end 

if @command=2
begin
if EXISTS(select Descripcion from ccRIAChatMsg where Descripcion=@Description)
 begin
	select 1, 'Description en Uso'
	return(0)
 end

Insert ccRIAChatMsg (msg, descripcion) select @msg, @Description
return(0)
end 

if @command=3
begin
if exists(select msg_id from ccRIAChatInboundMsgs where msg_id=@msg_id)
 begin 
	select 1 --'Este Mensaje tiene alguna Especialidad asignada'
	return(0)
 end

Delete ccRIAChatMsg Where msg_id=@msg_id
return(0)
end 

if @command=4 
begin
Update ccRIAChatMsg set msg=@msg, descripcion=@Description Where msg_id=@msg_id
return(0)
end

if @command=5
begin
if EXISTS(select Descripcion from ccRIAChatMsg where descripcion= @Description)
 begin
	select 1, 'Descripcion en Uso'
	return(0)
 end

Insert ccRIAChatMsg (msg, descripcion) select @msg, @Description
return scope_identity()
end

set nocount off