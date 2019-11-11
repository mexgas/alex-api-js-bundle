CREATE procedure [dbo].[ccsp_RiaMenuByRole]
@Type tinyint,
@role_id smallint = null,
@Menu_id smallint = null,
@CM tinyint = 0,
@AE tinyint = 0
as
set nocount on

select @AE = valor from ccsettings where setting_id = 71
Declare @NRS tinyint
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

If @Type = 1 -- Get language
begin
	select valor from ccSettings where setting_id = 27
	return(0)
end

If @Type = 2 -- Carga todos los roles
begin
	select Role_id, Description from ccRIACat_AdminRole where type = 1 and Role_id<>1 order by priority
	return(0)
end

If @Type = 3 -- Carga roles
begin
select rm.role_id, m.menu_descrip, rm.id_menu,rm.type,m.release from dbo.ccRIARoleMenu rm, ccmenus m where rm.id_menu = m.menu_id and rm.role_id = @role_id and rm.type = 1 and
	((rm.id_Menu not in (41,42,53)) or (rm.id_Menu = 41 and @CM = 1) or (rm.id_Menu = 42 and @ae > 0) or (rm.id_Menu = 53 and @NRS = 1))
	return(0)
end

declare @language tinyint
select @language=valor from ccSettings where setting_id = 27

If @Type = 4 -- Inserta rol
begin
if not exists(select role_id from ccRIARoleMenu where role_id = @role_id and id_Menu = @Menu_id and type = 1)
begin
	Insert into ccRIARoleMenu (role_id, id_Menu, type) values(@role_id, @Menu_id, 1)
	select
		(select case @language when 0 then substring(Description, 1, charindex('|',Description)-1)
		else substring(Description, charindex('|',Description)+1, len(Description)) end
		from ccRIACat_AdminRole where role_id=@role_id) as sRole,

		(select case @language when 0 then substring(menu_descrip, 1, charindex('|',menu_descrip)-1)
		else substring(menu_descrip, charindex('|',menu_descrip)+1, len(menu_descrip)) end
		from ccMenus where menu_id=@Menu_id) as sMenu
	return(0)
end
end

If @Type = 5 -- Elimina rol
begin
delete from ccRIARoleMenu where role_id =@role_id  and id_Menu=@Menu_id and type= 1
select
	(select case @language when 0 then substring(Description, 1, charindex('|',Description)-1)
	else substring(Description, charindex('|',Description)+1, len(Description)) end
	from ccRIACat_AdminRole where role_id=@role_id) as sRole,

	(select case @language when 0 then substring(menu_descrip, 1, charindex('|',menu_descrip)-1)
	else substring(menu_descrip, charindex('|',menu_descrip)+1, len(menu_descrip)) end
	from ccMenus where menu_id=@Menu_id) as sMenu
return(0)
end