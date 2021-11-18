Create procedure [dbo].[ccsp_AdminNotready]
@Type tinyint,	-- 1:ND x Supervisor/2:actualiza x supervisor/3:Actualiza todo/4:trae ND/5:Trae supervisores
@User_id smallint = null,
@id_ND smallint = null,
@valor bit=1,
@id_NDs varchar(max) = ''
as
set nocount on

declare @sql as nvarchar(2000)
declare @dato1 as varchar (100)

if @Type not in (1,2,3,4,5)
	raiserror('ERROR. No se ingreso parametro de entrada', 18, 1)

if @Type = 1
 begin

 	if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@User_id)
	 begin
		raiserror('ERROR. invalid user id', 18, 1)
		return(0)
	 end

select @dato1 = valor from (select case when valor= 3 then 'nd.issup =1' when valor = 2 then 'nd.issup = nd.issup and nd.tiponotready_id > 0' when valor = 4 
	then 'nd.issup = nd.issup and nd.tiponotready_id > 0' else (select 'nd.tiponotready_id = ' + valor from ccsettings where setting_id = 28) end valor 
	from ccsettings where setting_id =87) as a



	set @sql = 'select nd.tiponotready_id, nd.descripcion , snd.user_id, Nombres + replace('' ''+isnull(ApellidoPaterno, '''') + '' ''+
	isnull(ApellidoMaterno, ''''), ''  '', '' '') Nombre, a3.frame, u.login 
	from cctiponotready nd 
	join ccSupervisor_NotReady snd on (nd.tiponotready_id = snd.tiponotready_id)
	join ccUsers u on (u.user_id = snd.user_id)
	inner join ccRIAnotreadyGraph a2 on (nd.tiponotready_id=a2.tiponotready_id) 
	inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
	where nd.tiponotready_id > 0 and nd.statustiponotready = 1 and snd.user_id = case when ' + convert(varchar(10),@User_id) + ' <> 0 then ''' 
	+ convert(varchar(10),@User_id) + ''' else convert(varchar(10),snd.user_id) end
	and ' + @dato1 + ' order by snd.user_id ,nd.tiponotready_id'

exec sp_executesql @sql
--print (@sql)

	return(0)
 end

if @Type = 2
 begin

 	if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@User_id)
	 begin
		raiserror('ERROR. invalid user id', 18, 1)
		return(0)
	 end


 	if not exists(select tiponotready_id from cctiponotready where tiponotready_id =@id_ND)
	 begin
		raiserror('ERROR. invalid notReady id', 18, 1)
		return(0)
	 end

	if @valor=0
		delete from ccSupervisor_NotReady where user_id = @User_id and tiponotready_id = @id_ND

	else if not exists (select user_id from ccSupervisor_NotReady where user_id = @User_id and tiponotready_id = @id_ND)
		insert ccSupervisor_NotReady select @user_id, @id_ND

	return(0)
 end

if @Type = 3
 begin
	declare @NDs_Ids table (id int primary key not null)

	if @id_ND is null
	 begin
		insert into @NDs_Ids
		select value from dbo.fn_RIASplitDelimited (@id_NDs, ',')
	 end
	else
	 begin
		insert into @NDs_Ids
		select @id_ND
	 end

 	if not exists(select tiponotready_id from cctiponotready where tiponotready_id in (select id from @NDs_Ids))
	 begin
		raiserror('ERROR. invalid notReady id', 18, 1)
		return(0)
	 end

	if @valor=0
		delete from ccSupervisor_NotReady where tiponotready_id in (select id from @NDs_Ids)

	else
		insert ccSupervisor_NotReady select u.User_id , nd.tiponotready_id
		from ccUsers u cross join cctipoNotReady nd
		where u.tipouser_id in (2,6) and nd.tiponotready_id in (select id from @NDs_Ids)
		and cast(u.User_id as varchar(10)) + '|' + cast(nd.tiponotready_id as varchar(10))
		not in (select cast(User_id as varchar(10)) + '|' + cast(tiponotready_id as varchar(10)) 
		from ccSupervisor_NotReady)

	return(0)
 end

if @Type = 4
 begin
	
	select @dato1 = valor from (select case when valor= 3 then 'nd.issup =1' when valor = 2 then 'nd.issup = nd.issup and nd.tiponotready_id > 0' when valor = 4 then 'nd.issup = nd.issup and nd.tiponotready_id > 0' else (select 'nd.tiponotready_id = ' + valor from ccsettings where setting_id = 28) end valor from ccsettings where setting_id =87) as a

	set @sql = 'select nd.tiponotready_id, nd.descripcion, a3.frame from cctiponotready nd 
			inner join ccRIAnotreadyGraph a2 on (nd.tiponotready_id=a2.tiponotready_id) 
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
	where nd.statustiponotready = 1 and ' + @dato1

	exec sp_executesql @sql
	--print (@sql)
	return(0)
 end

if @Type = 5
 begin

	select User_id, Login, Nombres + 
	replace(' '+isnull(ApellidoPaterno, '') + ' '+isnull(ApellidoMaterno, ''), '  ', ' ') Nombre
	from ccUsers where tipouser_id in (2,6)
	order by Login
	return(0)

 end

set nocount off