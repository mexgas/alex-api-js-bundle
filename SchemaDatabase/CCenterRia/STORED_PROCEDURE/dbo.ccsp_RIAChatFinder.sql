CREATE PROCEDURE [dbo].[ccsp_RIAChatFinder]
@action int,
@userId smallint = 0,
@params varchar(500) = '',
@status bit = 0,
@id int = 0,
@template varchar(100) = ''
AS

if @action = 1 begin  --Guarda nueva busqueda
insert into ccRIAChatFinder values(@userId,@params,1,@template)	
end

if @action = 3 begin --Actualiza busquedas
update ccRIAChatFinder set [status]=@status where id = @id
end

if @action = 4 begin --Actualiza busquedas
update ccRIAChatFinder set params=@params where id = @id

end

select ID,params,template from ccRIAChatFinder where userId = @userId and [status] = 1