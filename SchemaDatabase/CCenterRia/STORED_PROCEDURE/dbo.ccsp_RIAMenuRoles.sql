CREATE procedure [dbo].[ccsp_RIAMenuRoles]
@Type tinyint,
@User_id smallint = null,
@Role_id smallint = null,
@InsertMenu_id smallint = null,
@DeleteMenu_id smallint = null,

@firstSup smallint = null,
@reportRol tinyint = 1,
@AVRS tinyint = null,
@CM tinyint = 0,
@AE tinyint = 0
as
set nocount on

select @reportRol = case @reportRol when 0 then 1 else @reportRol end, @role_id = case @role_id when 0 then 1 else @role_id end

Declare @NRS tinyint
declare @MenusChat tinyint
declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenuMail tinyint
Declare @MenuCRM tinyint
Declare @monitorPortMenu tinyint

set @MenuMail = 0
set @MenuCRM = 0

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

---Checar si esta se aplica
select @AVRS = valor from ccSettings where setting_id = 124
select @IVRScripting = valor from ccsettings where setting_id = 125

select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
--Activa menus relacionados con campañas
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155
select @MenuCRM = valor from ccsettings where setting_id = 168
select @monitorPortMenu = case when valor='1' then 1 else 0 end from ccsettings where setting_id = 186

If @Type = 1 -- Carga todos los roles
	begin
		select Role_id, Description from ccRIACat_AdminRole where type = @reportRol order by priority
		return(0)
	end

If @Type = 2 -- Carga los menus de un supervisor
	begin
	Select a.id_User, a.id_Menu, b.menu_descrip, Nivel, ordengral
	from ccMenuUser a inner join ccMenus b with(index(IX_ccMenus)) on a.id_Menu = b.menu_id and a.type = b.type
	where id_User = @User_id and a.Type = @reportRol and ((a.id_Menu not in (41,42, 53)) or
	(a.id_Menu = 41 and @CM = 1) or (a.id_Menu = 42 and @AE > 0) or (a.id_Menu = 53 and @NRS = 1))
	order by ordengral asc
	return(0)
	end

If @Type = 3 -- Return the menus of a rol
	begin
	select a.Role_id, b.menu_id, b.menu_descrip, b.Nivel, b.ordengral
	from ccRIARoleMenu a inner join ccMenus b with(index(IX_ccMenus)) on b.menu_id = a.id_Menu and a.type = b.type
	where a.Role_id = @Role_id and
	a.type = @reportRol and
	((b.menu_id not in (41,42,53)) or (b.menu_id = 41 and @CM = 1) or (b.menu_id = 42 and @ae > 0) or (b.menu_id = 53 and @NRS = 1))
	order by a.Role_id, b.ordengral asc
	return(0)
	end

If @Type = 4 -- Insert
	begin
	if (@InsertMenu_id <> 0) or not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
	begin
		if @Role_id in (1, 10, 14) begin
			if @InsertMenu_id <> 0 and not exists(select * from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
				insert into ccMenuUser (id_User, id_Menu, type) values(@User_id, @InsertMenu_id, @reportRol)
			if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40)begin
				Insert into ccMenuUser (id_User, id_Menu, type)values(@User_id,40,@reportRol)
			end
			else If @reportRol = 2 and not exists(select id_User from ccMenuUser where id_User = @User_id and (id_Menu between 1000 and 1999)) begin
					Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, menu_id, @reportRol from ccMenus with(index(IX_ccMenus)) where menu_id between 1000 and 1999
				end
			else if @reportRol = 3 begin
				insert into ccMenuUser (id_User, id_Menu, type) select @User_id, id_Menu, @reportRol from ccRIARoleMenu  where Role_id = @Role_id
			end
		end
		else if ((@InsertMenu_id = 53 and @NRS = 1) or (@InsertMenu_id <> 53) )
		begin
			if @InsertMenu_id <> 40	delete ccMenuUser where id_User = @User_id and type = @reportRol
				insert into ccMenuUser (id_User, id_Menu, type)	select @User_id, id_Menu, @reportRol from ccRIARoleMenu where Role_id = @Role_id and type = @reportRol
			if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40 and type = @reportRol)
				insert into ccMenuUser (id_User, id_Menu, type) values(@User_id,40,@reportRol)
		end
	end
	--Asigna un rol por default o lo actuliza
	if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
	else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)

	--Solo es necesario en caso admin y reports
	if @reportRol in(1,2) begin
		--    inserta parent en caso de no haberlo hecho en rol personalizado
		insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent
		where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0

		select @User_id, parent, @reportRol from
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent
		where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0

	end
	return (0)
	end

If @Type = 5 -- delete
	begin
		delete ccMenuUser where id_User = @User_id and id_Menu = @DeleteMenu_id and type = @reportRol
		if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
		else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
		return(0)
	end

If @Type = 6 -- Get userMenus
	begin
	if @reportRol = 2 begin --Reports version vieja
		select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode,
		c.release
		from ccRIAUserRole a inner join ccMenuUser b on a.user_id = b.id_user
		inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
		where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol and
		((b.id_Menu not in (41,42,53)) or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1))
		and ( b.id_Menu not in(77,78) or (@RelationCampInbNotReady = 1 and b.id_Menu in(77,78)))
		and ( b.id_Menu not in(79) or (@MenusChat > 0 and b.id_Menu in(79)))
		order by ordengral asc
		return(0)
	end
	else begin ---Sitio del administrador
		if not exists( select * from ccRIAUsr_AdminPermissions where User_id=@user_id and per_id=6)
		set @AVRS =0

		select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode,
		c.release
		from ccRIAUserRole a
		inner join ccMenuUser b on a.user_id = b.id_user
		inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
		where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol
		and (
			(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82,83,84,85,69))
			or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)
			or (menu_id in (71,72) and @IVRScripting = 1)
			or (menu_id in (73,74,75,76) and @AVRS = 1)
			or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
			or (menu_id = 79 and @MenusChat > 0)
			or (menu_id in (81,82,84,85) and @MenuMail = 1)--Mail
			or (menu_id = 83 and @MenuCRM > 0)
			or (@monitorPortMenu > 0 and b.id_Menu in(69))
			)
		order by ordengral asc
		return(0)
	end
	end

If @Type = 7 -- Get language
	begin
		select valor from ccSettings where setting_id = 27
		return(0)
	end

If @Type = 8 -- Insert the personalized menus of a supervisor
	begin
		insert into ccMenuUser (id_User, id_Menu, type)
		select @User_id, id_Menu, @reportRol from ccMenuUser where id_User = @firstSup and type = @reportRol

		If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		begin
			Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
			return(0)
		end

		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
		return(0)
	end

If @Type = 9 -- Delete all supervisor menus
	begin
		delete ccMenuUser where id_User = @User_id and type = @reportRol
		return(0)
	end

If @Type = 10 -- update all supervisor menus
	begin

		if @AVRS = 1
		begin
			update ccUsers set tipoUser_id = 6 where user_id = @User_id
			return(0)
		end
	end

If @Type = 11 -- Verify level A menus
	begin
	--   inserta parent en caso de no haberlo hecho en rol personalizado
		Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where m.menu_id in (1000,2000,3000,4000) and u.id_User = @User_id and u.type = @reportRol
		group by m.parent) parent where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

		return(0)
	end

If @Type = 12
	begin
		declare @lan as tinyint
		select @lan = valor from ccSettings where setting_id = 27
		select menu_descrip from ccMenus with(index(IX_ccMenus)) where menu_id = @Role_id
		return(0)
	end

	if @Type = 13 --Agrega Menus por default a Admin en ReportsRia Agentes,ACD y Campañas
	begin
	insert into ccMenuUser([id_user],[id_Menu],[type])
	select a.User_id, b.menu_id, b.type
		from ccUsers a cross join ccMenus b
		left join ccMenuUser d on d.id_User = a.User_id and d.id_Menu = b.menu_id
		where a.TipoUser_id = 2 and b.type = 3 and d.id_User IS null and
		b.menu_id >= 2000 and b.menu_id < 5000 and a.User_id = @User_id

	insert into ccRIAUserRole([User_id],[Role_id],[type])
		select a.[User_id], 14 as role_id, 3 as type from ccUsers a
			left join ccRIAUserRole d on d.User_id = a.User_id and d.type = 3
			where d.User_id IS null and a.TipoUser_id = 2 and a.User_id = @User_id

	return (0)

	end

return(0)
set nocount off