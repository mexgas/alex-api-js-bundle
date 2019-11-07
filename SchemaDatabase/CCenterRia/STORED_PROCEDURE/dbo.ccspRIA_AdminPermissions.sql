CREATE procedure [dbo].[ccspRIA_AdminPermissions]
@Type tinyint,	-- 1:Catalogo/2:Supervisores/3:permisos_X_supervisor/4:actualiza_supervisor/5:actualiza_todo
@user_id smallint = null,
@per_id tinyint = null,
@value bit=1
as
set nocount on
if @Type = 1
	begin
	declare @Idioma bit
	select @Idioma = valor from ccsettings where setting_id = 27
	select per_id, case @Idioma when 0 then substring(per_desc, 1, charindex('|',per_desc)-1)
	else substring(per_desc, charindex('|',per_desc)+1, len(per_desc))
	end per_desc,release
	from ccRIACat_AdminPermissions where bStatus = 1
	return(0)
	end

if @Type = 2
	begin
	select User_id, Login, Nombres +
	replace(''+isnull(ApellidoPaterno, '') + ''+isnull(ApellidoMaterno, ''), '', '') Nombre
	from ccUsers where tipouser_id in (2,6)
	order by Login
	return(0)
	end

if @Type = 3
	begin
	if not exists(select user_id from ccUsers where TipoUser_id in(2,6) and user_id = @user_id)
		return(0)

	select c.per_id, cast(cast(isnull(u.user_id, 0) as bit) as tinyint) value
	from ccRIACat_AdminPermissions c
		left join ccRIAUsr_AdminPermissions u
		on c.per_id = u.per_id and u.user_id = @user_id
	where c.bStatus = 1
		order by c.per_id
	return(0)
	end

if @Type = 4
	begin
	if cast(@User_id as bit) <> 1 or cast(@per_id as bit) <> 1
	return(0)

	if @value=0
		delete ccRIAUsr_AdminPermissions where user_id = @user_id and per_id = @per_id

	else if not exists (select user_id from ccRIAUsr_AdminPermissions where user_id = @user_id and per_id = @per_id)
		insert ccRIAUsr_AdminPermissions select @user_id, @per_id
	return(0)
	end

if @Type = 5
	begin
	if not exists(select per_id from ccRIACat_AdminPermissions)
		return(0)

	if @value=0
		delete ccRIAUsr_AdminPermissions where per_id = @per_id

	else
		insert into ccRIAUsr_AdminPermissions select User_id , per_id
		from ccUsers cross join ccRIACat_AdminPermissions
		where tipouser_id in (2,6) and per_id in (@per_id)
		and cast(User_id as varchar(10)) + '|' + cast(per_id as varchar(10))
		not in (select cast(User_id as varchar(10)) + '|' + cast(per_id as varchar(10))
		from ccRIAUsr_AdminPermissions)
		order by 1,2
	return(0)
	end
set nocount off