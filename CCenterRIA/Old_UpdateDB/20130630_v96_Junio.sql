/*
Autor: Raymundo Gonzalez
Fecha: 2013/06/30
Descripcion:
	Se actualiza la tabla ccsettings en su setting 131 para configuracion default de Mizuphone
	Se insertan los settings 132, 133 y 134 en la tabla ccsettings para cifrado a traves de Mizuphone
	Se inserta el setting 135 en la tabla ccsettings para configuracion de no disponibles por campaña y Grupo ACD
	Se insertan los settings 136 y 137 para migracion de nueva version de reportes
	Se insertan los menus 77 y 78 en la tabla ccMenus para configuracion de no disponibles por campaña y Grupo ACD
	Se inserta registro en la tabla ccRIACat_AdminPermissions para migracion de nueva version de reportes
	Se inserta registro en la tabla ccTipoResultadoDial para migracion de nueva version de reportes
	Se crea la tabla ccUnavailableRelation para configuracion de no disponibles por campaña y Grupo ACD
	Se modifica el SP ccsp_RIAGetNotReadyTypes_xUser para devolver la lista de no disponibles de acuerdo a configuracion de setting
	Se modifica el SP ccsp_RIACATNotReadyTypes para devolver la lista de no disponibles de acuerdo a configuracion de setting
	Se modifica el SP ccsp_RIAMenuRoles para mostrar menus de configuracion de no disponibles por campaña y Grupo ACD con base en setting
	Se crea el SP ccsp_RIANotReadyAssignment para administrar la asignacion de no disponibles por campaña y Grupo ACD
	Se actualiza el plan de mantenmiento NuxibaMaintenancePlan para mejora de performance
	Se modifican los SP ccsp_SaveStatusAgent, ccsp_RIAsubCalif, ccsp_RIAOUTInsertNewJOBS_WT_Camp, ccsp_OUTInsertaCallBack y ccsp_INInsertaCallBack por migracion de Reportes

Version requerida: 95
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '96'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccsettings - Update'
		set @Sql='update ccsettings 
set valor=''2|2|0|0'', detalle = ''Configuración para Mizuphone: CODEC|STUN|RPORT|LOG CODEC(1:G711U,2:G711A,3:G729) STUN(-1:Forzar IP privada,0:No,1:NAT simetrica,2:siempre,3:usar aun en ip publica) RPORT(0:No,1:NAT simetrica,2:siempre,3:aun en ip publica,9:peticion con señalizacion) LOG(0:Sin Log, 5:Log activado)'' 
where setting_id = 131'
		
	EXEC(@Sql)
	
		set @process = 'ccsettings - Insert'
		set @Sql='insert into ccsettings values(132,0,''Utilizar cifrado de voz Mizutech'',1,''GRL'',''0: No usar cifrado 1: Utilizar el servidor primario 2: Utilizar el servidor secundario 3: Random entre los servidores'',''Use Mizutech encryption'',1)
insert into ccsettings values(133,''208.110.149.81:16200'',''Servidor primario de cifrado de voz Mizutech'',1,''GRL'',''IP del servidor primario de cifrado de voz Mizutech'',''Primary Mizutech Encryption Server'',1)
insert into ccsettings values(134,''208.110.149.82:16200'',''Servidor secundario de cifrado de voz Mizutech'',1,''GRL'',''IP del servidor secundario de cifrado de voz Mizutech'',''Secondary Mizutech Encryption Server'',1)
insert into ccSettings values(135, ''0'', ''Configurar No Disponibles por Campaña y Grupo ACD'', 1, ''ADM'', ''Permitir cambiar al agente a los No Disponibles de acuerdo a las campañas o grupos ACD a los que pertenece'', ''Configure Not Available by Campaign and ACD Group'', 1)
insert into ccsettings values(136,'''',''Ruta de la aplicación de reportes nueva versión'', 1, ''REP'', ''Direccion web/url donde se encuentra la pagina web de reportes nueva version RIA: IP/REPORTSV2'', ''Path of reports new version app'', 1)
insert into ccsettings values(137,'''',''Nombre del servidor para la suscripcion de las replicas'', 1, ''X'', ''Alias del servidor de suscripcion de replicas'', ''Subscription Server Name Alias for replication'', 1)'
		
	EXEC(@Sql)
	
		set @process = 'ccmenus - Insert'
		set @Sql='insert into ccmenus values(77,''Configurar No Disponibles por Campaña|Configure Not Available by  Campaigns'',20,''B'', 31,1,'''')
insert into ccmenus values(78,''Configurar No Disponibles por Grupo ACD|Configure Not Available by  ACD Group'',30,''B'', 38,1,'''')	'
		
	EXEC(@Sql)
	
		set @process = 'ccRIACat_AdminPermissions - Insert'
		set @Sql='insert into ccRIACat_AdminPermissions values(''Reportes|Reports'',1)'

	EXEC(@Sql)
	
		set @process = 'ccTipoResultadoDial - Insert'
		set @Sql='insert into ccTipoResultadoDial values (80, ''Unknown'')'

	EXEC(@Sql)
	
		set @process = 'ccUnavailableRelation - Create Table'
		set @Sql='CREATE TABLE [dbo].ccUnavailableRelation(
[idUnavailable] [int] NOT NULL,
[idCampACD] [int] NOT NULL,
[type] [bit] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAGetNotReadyTypes_xUser - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAGetNotReadyTypes_xUser]
@user_id int
as
set nocount on

declare @NotReadybyCampACD int
select @NotReadybyCampACD = valor from ccsettings where setting_id = 135

declare @NotReadyRestricted tinyint
select @NotReadyRestricted = NotReadyRestricted from ccUsers where User_id = @user_id

if (@NotReadybyCampACD = 0)
	begin
		select a1.TipoNotReady_id, Descripcion, frame, 
		dbo.NeventsNRdisp(@user_id, a1.tiponotready_id, getdate()), @NotReadyRestricted NotReadyRestricted
		from ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on a1.tiponotready_id = a2.tiponotready_id
		inner join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
		where a1.TipoNotReady_id > 0 and a1.IsSup = 0
	end
else if (@NotReadybyCampACD = 1)
	begin
		select a1.TipoNotReady_id, Descripcion, frame, dbo.NeventsNRdisp(@user_id, a1.tiponotready_id, getdate()), @NotReadyRestricted NotReadyRestricted
		from ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id = a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
		where a1.TipoNotReady_id > 0 
		and a1.IsSup = 0
		and a4.idCampACD in (select distinct(inbound_id) from ccInboundAgentes where user_id = @user_id)
		AND a4.type = 0
		union
		select a1.TipoNotReady_id, Descripcion, frame, dbo.NeventsNRdisp(@user_id, a1.tiponotready_id, getdate()), @NotReadyRestricted NotReadyRestricted
		from ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id = a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
		where a1.TipoNotReady_id > 0 
		and a1.IsSup = 0
		and a4.idCampACD in (select distinct(cam_id) from ccCampsAgente where user_id = @user_id)
		AND a4.type = 1
	end

return(0)

set nocount off'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIACATNotReadyTypes - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIACATNotReadyTypes]
@TipoNotReady_id varchar(5)='''',
@Descripcion varchar(30)='''',
@Time_Acum varchar(10)='''',
@Time_xEv varchar(5)='''',
@Pas_Sup varchar(2)='''',
@NextStatus varchar(5)='''',
@graphic_id varchar(5)='''',
@Type varchar(1)='''',
@IsSup int = null,
@super_id as int = null
AS
set nocount on
DECLARE @sql nvarchar(4000), @graph nvarchar(1000), @id smallint, @newGraph smallint

if @Type=0
 begin
	SELECT TipoNotReady_id, Descripcion FROM ccTipoNotReady WITH(NOLOCK) WHERE StatusTipoNotReady=1
	return(0)
 end

if @Type=6 -- LOAD by setting
 begin
	select @Type = valor from ccSettings where setting_id = 87

    if @Type = 4 begin
		SELECT a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
		FROM ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
		inner join ccsupervisor_notready snd on (a1.tiponotready_id = snd.tiponotready_id and snd.user_id = @super_id)
		where a1.TipoNotReady_id > 0 
		and a1.IsSup = case @Type when 1 then (select valor from ccSettings where setting_id = 28)
		when 2 then a1.IsSup when 4 then a1.issup else 1 end and a1.StatusTipoNotReady=1
	end
	else begin
		SELECT a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
		FROM ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
		where a1.TipoNotReady_id > 0 
		and a1.IsSup = case @Type when 1 then (select valor from ccSettings where setting_id = 28)
		when 2 then a1.IsSup when 4 then a1.issup else 1 end and a1.StatusTipoNotReady=1
	end
	return(0)
 end

if @Type=1 -- LOAD
 begin
	declare @NotReadybyCampACD int
	select @NotReadybyCampACD = valor from ccsettings where setting_id = 135
	
	if (@NotReadybyCampACD = 0)
	begin
		SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
		FROM ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
		where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
	end
	else if (@NotReadybyCampACD = 1)
		begin
			SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
			FROM ccTipoNotReady a1 
			inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
			inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
			where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
			and a4.idCampACD in (select distinct(cam_id) from ccSupervisorCam where user_id = @super_id)
			AND a4.type = 0
			union
			SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
			FROM ccTipoNotReady a1 
			inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
			inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
			where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
			and a4.idCampACD in (select distinct(cam_id) from ccSupervisorCam where user_id = @super_id)
			AND a4.type = 1
		end
	return(0)
 end

If @Type=2 -- INSERT
 begin
	if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Descripcion)
	 begin		
		select 1
		return(0)
	 end
	if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=0 and Descripcion=@Descripcion)
		begin		
			select @id=TipoNotReady_id from ccTipoNotReady where Descripcion=@Descripcion
			update ccTipoNotReady set 
			Time_acum=@Time_Acum,
			Time_xEv=@Time_xEv,
			Pas_Sup=@Pas_Sup,
			NextStatus=@NextStatus,
			IsSup=@IsSup,
			StatusTipoNotReady=1
			where Descripcion=@Descripcion
			If not exists(select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
				Begin
					insert into ccRIAGraphics select @graphic_id,4
				End
			
			insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
			return(0)		
		end
	If not exists(select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
	 Begin
		insert into ccRIAGraphics select @graphic_id,4
	 End

	insert ccTipoNotReady (Descripcion, Time_Acum, Time_xEv, Pas_Sup, NextStatus, IsSup,StatusTipoNotReady) 
	select @Descripcion, @Time_Acum, @Time_xEv, @Pas_Sup, @NextStatus, @IsSup,1
	select @id=SCOPE_IDENTITY()
	insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
	return(0)
 end

If @Type=3 -- DELETE
 begin
	exec ccsp_AdminNotready 3,0,@TipoNotReady_id,0
	delete ccRIANotReadyGraph where tipoNotReady_id = @TipoNotReady_id
	update ccTipoNotReady set StatusTipoNotReady=0 where tipoNotReady_id = @TipoNotReady_id
 end

if(@Type=4) --UPDATE
 begin

	if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Descripcion)
	 begin		
		select @Descripcion=''''
	 end

	update ccTipoNotReady set 
	 Descripcion=case @Descripcion when '''' then Descripcion else @Descripcion end,
	 Time_Acum=case @Time_Acum when '''' then Time_Acum else @Time_Acum end,
	 Time_xEv=case @Time_xEv when '''' then Time_xEv else @Time_xEv end,
	 Pas_Sup=case @Pas_Sup when '''' then Pas_Sup else @Pas_Sup end,
	 NextStatus=case @NextStatus when '''' then NextStatus else @NextStatus end,
	 IsSup=ISNULL(@IsSup,IsSup)
	where TipoNotReady_id=@TipoNotReady_id

	IF ISNULL(@graphic_id,'''') not in('''')
	 BEGIN
		If not exists (select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
		 begin
			insert into ccRIAGraphics select @graphic_id,4
		 end

		select @graph = graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
		update ccRIANotReadyGraph set graphic_id=cast(@graph as smallint) where TipoNotReady_id=cast(@TipoNotReady_id as tinyint)
	 END
	return(0)
 end

set nocount off'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAMenuRoles - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAMenuRoles]
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
select @reportRol = case @reportRol when 0 then 1 else @reportRol end, 
 @role_id = case @role_id when 0 then 1 else @role_id end

select @AE = valor from ccsettings where setting_id = 71

Declare @NRS tinyint
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
declare @RelationCampInbNotReady tinyint
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135


If @Type = 1 -- Carga todos los roles
 begin
      select Role_id, Description from ccRIACat_AdminRole where type = @reportRol order by priority
      return(0)
 end

If @Type = 2 -- Carga los menus de un supervisor
 begin
  Select a.id_User, a.id_Menu, b.menu_descrip, Nivel, ordengral 
  from ccMenuUser a inner join ccMenus b with(index(IX_ccMenus)) on a.id_Menu = b.menu_id 
  where id_User = @User_id and a.Type = @reportRol and ((a.id_Menu not in (41,42, 53)) or 
  (a.id_Menu = 41 and @CM = 1) or (a.id_Menu = 42 and @AE > 0) or (a.id_Menu = 53 and @NRS = 1))
  order by ordengral asc
  return(0)
 end

If @Type = 3 -- Return the menus of a rol
 begin
  select a.Role_id, b.menu_id, b.menu_descrip, b.Nivel, b.ordengral 
  from ccRIARoleMenu a inner join ccMenus b with(index(IX_ccMenus)) on b.menu_id = a.id_Menu
  where a.Role_id = @Role_id and 
  a.type = @reportRol and 
  ((b.menu_id not in (41,42,53)) or (b.menu_id = 41 and @CM = 1) or (b.menu_id = 42 and @ae > 0) or (b.menu_id = 53 and @NRS = 1))
  order by a.Role_id, b.ordengral asc
  return(0)
 end

If @Type = 4 -- Insert 
 begin
	if @Role_id in (1, 10) and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
	 begin
		Insert into ccMenuUser (id_User, id_Menu, type) values(@User_id, @InsertMenu_id, @reportRol)
		if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40)
					Insert into ccMenuUser values(@User_id,40,1)
		else If not exists(select id_User from ccMenuUser where id_User = @User_id and (id_Menu between 1000 and 1999))
					Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, menu_id, 2 from ccMenus with(index(IX_ccMenus)) where menu_id between 1000 and 1999
		
	 end

	else if ((@InsertMenu_id = 53 and @NRS = 1) or (@InsertMenu_id <> 53) )
	 begin
		if @InsertMenu_id <> 40
			  delete ccMenuUser where id_User = @User_id and type = @reportRol

		Insert into ccMenuUser (id_User, id_Menu, type)
		select @User_id, id_Menu, @reportRol from ccRIARoleMenu where Role_id = @Role_id and type = @reportRol
		If @reportRol = 1
			  Insert into ccMenuUser (id_User, id_Menu, type) values(@User_id,40,1)
	 end

	If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol

	else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)

	--    inserta parent en caso de no haberlo hecho en rol personalizado        
	Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, 2 from               
	(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id
	where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
	where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

	return(0)
 end

If @Type = 5 -- delete
 begin
      delete ccMenuUser where id_User = @User_id and id_Menu = @DeleteMenu_id and type = @reportRol
      If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
  Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol

      else
            insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)

      return(0)
 end

If @Type = 6 -- Get userMenus
 begin
      select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
      from ccRIAUserRole a inner join ccMenuUser b on a.user_id = b.id_user
       inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id
      where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol and 
      ((b.id_Menu not in (41,42,53)) or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)) 
		and ( b.id_Menu not in(77,78) or (@RelationCampInbNotReady = 1 and b.id_Menu in(77,78)))      
	  order by ordengral asc
      return(0)
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

If @Type = 10 -- Delete all supervisor menus 
 begin
      update ccUsers set tipoUser_id = @AVRS where user_id = @User_id 
      return(0)
 end

If @Type = 11 -- Verify level A menus
 begin
 --   inserta parent en caso de no haberlo hecho en rol personalizado        
      Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, 2 from               
      (select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id
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

return(0)
set nocount off'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIANotReadyAssignment - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIANotReadyAssignment]
@action smallint, --1 Consulta relacion, 2 Inserta y 3 Borrar
@CampEspId smallint = 0,
@type smallint = 0, --0 ACD y 1 Campaña
@notReadyId varchar(max) = null

AS

set nocount on

if @action = 1
	begin
		if (@type = 0)
			begin
				select TipoNotReady_id, ccTipoNotReady.[Descripcion] from ccUnavailableRelation
				left outer join ccTipoNotReady on (idUnavailable = TipoNotReady_id)
				left outer join ccInbound on (idCampACD = inbound_id)
				where type = @type
				and idCampACD = @CampEspId
			end
		else
			begin
				select TipoNotReady_id, ccTipoNotReady.[Descripcion] from ccUnavailableRelation
				left outer join ccTipoNotReady on (idUnavailable = TipoNotReady_id)
				left outer join ccCamps on (idCampACD = cam_id)
				where type = @type
				and idCampACD = @CampEspId
			end
	end
	
if @action = 2
	begin
		delete ccUnavailableRelation where [idCampACD] = @CampEspId and [type] = @type 

		insert into ccUnavailableRelation
			select value, @CampEspId, @type from fn_RIASplitDelimited (@notReadyId, ''|'')
	end
	
if @action = 3
	begin
		delete ccUnavailableRelation where [idCampACD] = @CampEspId and [type] = @type and
			[idUnavailable] in (select value from fn_RIASplitDelimited (@notReadyId, ''|''))
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIA_ABCACDGroups - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIA_ABCACDGroups]
@option smallint,
@userid int,
@descripcion varchar(40),
@inbound_id varchar(1000),
@idarea smallint = null,
@frame tinyint
as
set nocount on
declare @new_inbound_id smallint, @graph_id smallint

if @option = 0 -- all acd
 begin
	 select acd.inbound_id, acd.descripcion, isnull(acd.idarea,0) as idarea,
	isnull(areas.areaname,'''') as areaname
	 from ccinbound as acd with(nolock)
	 left join dbo.ccriacat_areas as areas with(nolock) on acd.idarea = areas.idarea
	 return(0)
 end

if @option = 1 -- select acd
 begin
	 select a1.inbound_id, a1.descripcion, a3.frame, a1.showcalifwnd, a1.starttimeronhangup, isnull(a1.idarea,0), isnull(a1.cam_id,0) cam_id
	 from ccinbound a1 
	  inner join ccriainboundgraph a2 on (a1.inbound_id=a2.inbound_id)
	  inner join ccriagraphics a3 on (a2.graphic_id=a3.graphic_id)
	 where a3.type_id = 1 and a1.inbound_id = (cast(@inbound_id as int))
	 order by descripcion
	 return(0)
 end

if @option = 2 -- insert
 begin
	if exists (select descripcion from ccinbound where descripcion = @descripcion and status = 1)
	 begin
			select -1--, ''nombre en uso''
			return(0)
	 end
	
	if @idarea = 0
	set @idarea = null
	
	insert into ccinbound (descripcion, starttimeronhangup, idarea, showcalifwnd)
	select @descripcion, 1, @idarea, case when exists(select calif_id from cctipocalif) then 1 else 0 end
	
	if @@rowcount = 1
		select @new_inbound_id = inbound_id from ccinbound where descripcion = @descripcion and status = 1

	else
	 begin
		select -2 -- Error al insertar
		return(0)
	 end

	insert into cccalifcamp (calif_id, cam_id, tipo) select calif_id, @new_inbound_id, 0 from cctipocalif where CanReprogram=0 and Calif_Status = 1

	if not exists (select msg_id from ccInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccMsgFiles where msgFile like ''%\Default%''))
	 begin
		insert into ccInboundMsgs (msg_id, inbound_id, orden, type, queue)
		select msg_id, @new_inbound_id, 0, cast(substring(msgFile, 19,3) as integer),0 from ccMsgFiles where msgFile like ''%\Default%''
	 end

	if not exists(select frame from ccriagraphics where frame = @frame and type_id = 1)
	 insert into ccriagraphics (frame,type_id) values (@frame,1)
	
	 select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
	 
	 insert into ccriainboundgraph values(@new_inbound_id,@graph_id)
	 select @new_inbound_id
	 return(0) 
 end

if @option = 3 -- update
 begin
	 if not exists (select frame from ccriagraphics where frame=@frame and type_id=1)
		insert into ccriagraphics (frame, type_id) values (@frame, 1)

	 select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
	 update ccinbound set descripcion = @descripcion where inbound_id = (cast(@inbound_id as int))
	 update ccriainboundgraph set graphic_id = @graph_id where inbound_id = (cast(@inbound_id as int))
	 return(0)
 end

if @option = 4 -- delete
 begin
	 delete cccalifcamp where cam_id = @inbound_id and tipo = 0
	 delete ccinboundhorarios where inbound_id = @inbound_id
	 delete ccriainboundgraph where inbound_id = @inbound_id
	 delete ccinbound where inbound_id = @inbound_id
	 return(0)
 end

if @option = 5 -- asignar campaña a ACD
 begin
	if not exists (select inbound_id from ccInbound where inbound_id=@inbound_id) or
	 (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
		not exists (select cam_id from ccCamps where cam_id=@descripcion))
	 begin
		select -3 -- Campaña o ACD invalido
		return(0)
	 end
	
	if @descripcion=0
		set @descripcion = null

	update ccInbound set cam_id = @descripcion where Inbound_id = @inbound_id
	if @@rowcount=0
		select -4 -- Error al actualizar
		
	else
	 begin
		delete cccalifcamp where tipo=0 and cam_id=@inbound_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	 end

	return(0)
 end
set nocount off'

	EXEC(@Sql)
	
		set @process = 'NuxibaMaintenancePlan - Drop and Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [NuxibaMaintenancePlan]    Script Date: 07/22/2013 08:40:12 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''NuxibaMaintenancePlan'')
EXEC msdb.dbo.sp_delete_job @job_name=N''NuxibaMaintenancePlan'', @delete_unused_schedule=1

/****** Object:  Job [NuxibaMaintenancePlan]    Script Date: 07/16/2013 15:25:04 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 07/16/2013 15:25:04 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''NuxibaMaintenancePlan'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''NuxibaMaintenancePlan'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Call Center Activity Task]    Script Date: 07/16/2013 15:25:04 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Call Center Activity Task'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''declare @fecha_ini datetime
declare @fecha_fin datetime

select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))
select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))

IF EXISTS (SELECT uid, max(ext) ext, login, isnull(max(logout),getdate()) logout, 
datediff(s,login,isnull(max(logout),getdate())) loginTime
FROM (SELECT uid, ext, login, ISNULL(logout, 
(SELECT MIN(fecha) FROM ccLogLogin with (nolock, index(IX_ccLogLogin_2))  
WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout   
FROM (SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout   
FROM (SELECT uid, ext, MAX(login) as login, logout
FROM(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha)
FROM ccLogLogin subLogin with (nolock, index(IX_ccLogLogin_2)) WHERE subLogin.tipomov = 0      
AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout]      
FROM ccLogLogin Login with (nolock, index(IX_ccLogLogin_2))     
WHERE login.fecha >= dateadd(dd, -5, @fecha_ini) and tipomov = 1     
GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail     
WHERE logout IS not NULL GROUP BY uid, ext, logout) Login    
RIGHT OUTER JOIN ccLogLogin  with (nolock, index(IX_ccLogLogin_2))   
ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login 
AND ccLogLogin.extension = Login.ext)   WHERE tipomov = 1   and ccLogLogin.fecha 
>= dateadd( dd, -5, @fecha_ini)) Det   ) LoginDetail WHERE logout IS NULL 
and login >= @fecha_ini and login < @fecha_fin 
GROUP BY uid, login)
BEGIN
  RAISERROR(''''Agents online.'''', 11, 1);
END
ELSE
BEGIN
	RETURN
END'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Database Integrity Task]    Script Date: 07/16/2013 15:25:04 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Database Integrity Task'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC CHECKDB WITH NO_INFOMSGS'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Database Task]    Script Date: 07/16/2013 15:25:04 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Database Task'', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKDATABASE(N''''CCenterRia'''', 10, TRUNCATEONLY)'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Log Task]    Script Date: 07/16/2013 15:25:05 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Log Task'', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKFILE(''''ccenter_Log'''',1)'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Reorganize Index Task]    Script Date: 07/16/2013 15:25:05 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Reorganize Index Task'', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''ALTER INDEX [IX_axLicG729_Data] ON [dbo].[axLicG729_Data] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_Camplistanegra] ON [dbo].[Camplistanegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAbandonoSalida_Chart] ON [dbo].[ccAbandonoSalida_Chart] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAgenda_TipolistaNegra] ON [dbo].[ccAgenda_TipolistaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAgendaListaNegra] ON [dbo].[ccAgendaListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAgendaListaNegra_1] ON [dbo].[ccAgendaListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAgendaListaNegra_2] ON [dbo].[ccAgendaListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAgendaListaNegra_3] ON [dbo].[ccAgendaListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_INFOESPEC_FECHA] ON [dbo].[ccAllInfoEspec] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_INFOESPEC_INBOUND_ID] ON [dbo].[ccAllInfoEspec] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAVRSTransfer] ON [dbo].[ccAVRSTransfer] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccAVRSTransfer] ON [dbo].[ccAVRSTransfer] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_cccalifblacklist] ON [dbo].[cccalifblacklist] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCalifCamp] ON [dbo].[ccCalifCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCalifCamp_1] ON [dbo].[ccCalifCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [uc_ccCalifCamp] ON [dbo].[ccCalifCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_1] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_2] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_3] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_4] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_5] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_6] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCallsIn] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_cccallsin_tmpChart] ON [dbo].[cccallsin_tmpChart] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCallsReject] ON [dbo].[ccCallsReject] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCamEspAgentStatus] ON [dbo].[ccCamEspAgentStatus] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCamps] ON [dbo].[ccCamps] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCamps_Consulta] ON [dbo].[ccCamps_Consulta] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [iii] ON [dbo].[ccCampsAgente] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCampsAgente] ON [dbo].[ccCampsAgente] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCampsHorarios] ON [dbo].[ccCampsHorarios] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCampsMsgs] ON [dbo].[ccCampsMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCampsNvosCB] ON [dbo].[ccCampsNvosCB] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCampsPrioridadTel] ON [dbo].[ccCampsPrioridadTel] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccClientes] ON [dbo].[ccClientes] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccDNIS] ON [dbo].[ccDNIS] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccDNIS] ON [dbo].[ccDNIS] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccEdoAniList] ON [dbo].[ccEdoAniList] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenAgent] ON [dbo].[ccGenAgent] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenAgentNotReady] ON [dbo].[ccGenAgentNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenChart] ON [dbo].[ccGenChart] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInAbnd] ON [dbo].[ccGenInAbnd] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInAnsw] ON [dbo].[ccGenInAnsw] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCalif] ON [dbo].[ccGenInCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCall] ON [dbo].[ccGenInCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCallDNI] ON [dbo].[ccGenInCallDNI] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSpec] ON [dbo].[ccGenInSpec] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCall] ON [dbo].[ccGenOutCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallCalif] ON [dbo].[ccGenOutCallCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallDials] ON [dbo].[ccGenOutCallDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSpecOut] ON [dbo].[ccGenOutCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCstoResumen] ON [dbo].[ccGenOutCstoResumen] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenLogin] ON [dbo].[ccGenSession] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionAgent] ON [dbo].[ccGenSessionAgent] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionInCall] ON [dbo].[ccGenSessionInCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionInSpec] ON [dbo].[ccGenSessionInSpec] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionNotReady] ON [dbo].[ccGenSessionNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionOutCall] ON [dbo].[ccGenSessionOutCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionOutCamp] ON [dbo].[ccGenSessionOutCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccHistorialListaNegra] ON [dbo].[ccHistorialListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccHistorialListaNegra_1] ON [dbo].[ccHistorialListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccHistorialListaNegra_2] ON [dbo].[ccHistorialListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccHistorialListaNegra_3] ON [dbo].[ccHistorialListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccHistorialListaNegra] ON [dbo].[ccHistorialListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccHorarios] ON [dbo].[ccHorarios] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccHorarioVerano] ON [dbo].[ccHorarioVerano] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccHorarioVeranoUsa] ON [dbo].[ccHorarioVeranoUsa] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccInbound] ON [dbo].[ccInbound] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccInbound_Consulta] ON [dbo].[ccInbound_Consulta] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccInboundAgentes] ON [dbo].[ccInboundAgentes] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccInboundDNIS] ON [dbo].[ccInboundDnis] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccInboundHorarios] ON [dbo].[ccInboundHorarios] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccInboundMsgs] ON [dbo].[ccInboundMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccInboundMsgs_1] ON [dbo].[ccInboundMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccInboundMsgs_2] ON [dbo].[ccInboundMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccInboundMsgs_3] ON [dbo].[ccInboundMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccListaNegra] ON [dbo].[ccListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_1] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_2] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_3] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_4] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_5] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccLogAgentesDia_Dialog] ON [dbo].[ccLogAgentesDia_Dialog] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNotReady] ON [dbo].[ccLogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNotReady_2] ON [dbo].[ccLogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNotReady_3] ON [dbo].[ccLogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNotReady_4] ON [dbo].[ccLogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogLogin] ON [dbo].[ccLogLogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogLogin_1] ON [dbo].[ccLogLogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogLogin_2] ON [dbo].[ccLogLogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogLogin_3] ON [dbo].[ccLogLogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogReciclaje] ON [dbo].[ccLogReciclaje] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogReciclaje_1] ON [dbo].[ccLogReciclaje] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogReciclaje_2] ON [dbo].[ccLogReciclaje] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogTransfers_2] ON [dbo].[ccLogTransfers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccMenu_Views] ON [dbo].[ccMenu_Views] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccMenu_ViewsUser] ON [dbo].[ccMenu_ViewsUser] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccMenus] ON [dbo].[ccMenus] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccMenus] ON [dbo].[ccMenus] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccMenusReportes] ON [dbo].[ccMenusReportes] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccMonitorExt] ON [dbo].[ccMonitorExt] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccMsgFiles] ON [dbo].[ccMsgFiles] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks] ON [dbo].[ccoCallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks2] ON [dbo].[ccoCallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_1] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_10] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_11] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_2] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_3] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_4] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_5] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_6] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_7] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_8] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_9] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut12] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoCallsOut] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_1] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_10] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_11] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_2] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_3] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_4] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_5] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_6] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_7] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_8] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_9] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoDatos] ON [dbo].[ccoDatos] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccodialercamp] ON [dbo].[ccoDialerCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoDialers] ON [dbo].[ccoDialers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccodialers] ON [dbo].[ccoDialers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_1] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_2] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_3] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_4] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoLogDials] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_1] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_10] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_11] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_12] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_13] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_14] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_2] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_3] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_4] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_5] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_6] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_7] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_8] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_9] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoWorkingTable] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicion] ON [dbo].[ccPosicion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicion_1] ON [dbo].[ccPosicion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicion_2] ON [dbo].[ccPosicion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccPosicion] ON [dbo].[ccPosicion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccPuertosPBX] ON [dbo].[ccPuertosPBX] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallBacks] ON [dbo].[ccRIACallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACallBacks] ON [dbo].[ccRIACallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACallBacks_1] ON [dbo].[ccRIACallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACallBacks_2] ON [dbo].[ccRIACallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACallBacks_3] ON [dbo].[ccRIACallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACampEspWG] ON [dbo].[ccRIACampEspWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACampEspWG_1] ON [dbo].[ccRIACampEspWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACampEspWG_2] ON [dbo].[ccRIACampEspWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACampsGraph] ON [dbo].[ccRIACampsGraph] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACat_Restrictions] ON [dbo].[ccRIACat_AdminRole] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACat_DialMode] ON [dbo].[ccRIACat_DialMode] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACatFunExt] ON [dbo].[ccRIACatFunExt] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAChat_Log_1] ON [dbo].[ccRIAChat_Log] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChat_TipoMsg] ON [dbo].[ccRIAChat_TipoMsg] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAClienteCarga] ON [dbo].[ccRIAClienteCarga] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAClienteCarga_1] ON [dbo].[ccRIAClienteCarga] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIADispMonitorRel] ON [dbo].[ccRIADispMonitorRel] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAExternalApplications] ON [dbo].[ccRIAExternalApplications] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAGraphics] ON [dbo].[ccRIAGraphics] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAGraphicType] ON [dbo].[ccRIAGraphicType] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAInboundGraph] ON [dbo].[ccRIAInboundGraph] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIALoading] ON [dbo].[ccRIALoading] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIALoading_1] ON [dbo].[ccRIALoading] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIALoading] ON [dbo].[ccRIALoading] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIALog] ON [dbo].[ccRIALog] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIALog_Module] ON [dbo].[ccRIALog_Module] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIALog_Operation] ON [dbo].[ccRIALog_Operation] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIALogAgentesNotReady] ON [dbo].[ccRIALogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIALogAgentesNotReady_1] ON [dbo].[ccRIALogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIANotReadyGraph] ON [dbo].[ccRIANotReadyGraph] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIARegistryLists] ON [dbo].[ccRIARegistryLists] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_Table_1] ON [dbo].[ccRIARegistryLists] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRiaRemoteLog] ON [dbo].[ccRiaRemoteLog] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAUpdateCallBack_Abandon_1] ON [dbo].[ccRIAUpdateCallBack_Abandon] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAUpdateCallBack_Abandon] ON [dbo].[ccRIAUpdateCallBack_Abandon] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_2] ON [dbo].[ccRIAWorkGroup_Calid] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_3] ON [dbo].[ccRIAWorkGroup_Calid] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_WGCal_id] ON [dbo].[ccRIAWorkGroup_Calid] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_cccRIAWorkGroup_logdial_id_2] ON [dbo].[ccRIAWorkGroup_logDial_id] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_WGlogDial_id] ON [dbo].[ccRIAWorkGroup_logDial_id] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAWorkGroupUsers] ON [dbo].[ccRIAWorkGroupUsers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccSettings] ON [dbo].[ccSettings] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccStatusLLamada] ON [dbo].[ccStatusLLamada] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccSupervisorND] ON [dbo].[ccSupervisor_NotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [ix_tipo_1] ON [dbo].[ccSupervisorCam] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccSupervisorCam] ON [dbo].[ccSupervisorCam] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_TideWater_Templates] ON [dbo].[ccTideWater_Templates] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTideWater_Templates_Cols] ON [dbo].[ccTideWater_Templates_Cols] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTideWater_TipoConexion] ON [dbo].[ccTideWater_TipoConexion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_Timetable] ON [dbo].[ccTimetable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTimetablechange] ON [dbo].[ccTimetablechange] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTimetabledetail] ON [dbo].[ccTimetabledetail] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTimeZoneArea_1] ON [dbo].[ccTimeZoneArea] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [pk_areaprefix] ON [dbo].[ccTimeZoneAreaUsaDetail] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTimeZones] ON [dbo].[ccTimeZones] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoCalif] ON [dbo].[ccTipoCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoCalifOUT] ON [dbo].[ccTipoCalifOUT] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoCalifSub] ON [dbo].[ccTipoCalifSub] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoSubCalifOUT] ON [dbo].[ccTipoCalifSubOUT] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoFiltro] ON [dbo].[ccTipoFiltro] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoMovsListaNegra] ON [dbo].[ccTipoMovsListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoMsgs] ON [dbo].[ccTipoMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoNotReady] ON [dbo].[ccTipoNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoPBX] ON [dbo].[ccTipoPBX] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoResultadoDial] ON [dbo].[ccTipoResultadoDial] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTiposListaNegra] ON [dbo].[ccTiposListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoStatusAgente] ON [dbo].[ccTipoStatusAgente] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cctipoSubCalifRel] ON [dbo].[cctipoSubCalifRel] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccUploadTemporal] ON [dbo].[ccUploadTemporal] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccUploadTemporal_1] ON [dbo].[ccUploadTemporal] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccusers] ON [dbo].[ccUsers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccusers_1] ON [dbo].[ccUsers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccUsers] ON [dbo].[ccUsers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccUsers_Consulta] ON [dbo].[ccUsers_Consulta] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cstoProvedor] ON [dbo].[cstoProvedor] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cstoTarifa] ON [dbo].[cstoTarifa] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_cstoTipoLlamada] ON [dbo].[cstoTipoLlamada] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_IVR_ID_1] ON [dbo].[IVRCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_Series] ON [dbo].[Series] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_Series_1] ON [dbo].[Series] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_telefonosConferencia] ON [dbo].[telefonosConferencia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_telefonosTransferencia] ON [dbo].[telefonosTransferencia] REORGANIZE WITH ( LOB_COMPACTION = ON )'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Rebuild Index Task]    Script Date: 07/16/2013 15:25:05 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Rebuild Index Task'', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''ALTER INDEX [IX_axLicG729_Data] ON [dbo].[axLicG729_Data] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_Camplistanegra] ON [dbo].[Camplistanegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAbandonoSalida_Chart] ON [dbo].[ccAbandonoSalida_Chart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAgenda_TipolistaNegra] ON [dbo].[ccAgenda_TipolistaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAgendaListaNegra] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAgendaListaNegra_1] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAgendaListaNegra_2] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAgendaListaNegra_3] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_INFOESPEC_FECHA] ON [dbo].[ccAllInfoEspec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_INFOESPEC_INBOUND_ID] ON [dbo].[ccAllInfoEspec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAVRSTransfer] ON [dbo].[ccAVRSTransfer] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccAVRSTransfer] ON [dbo].[ccAVRSTransfer] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_cccalifblacklist] ON [dbo].[cccalifblacklist] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCalifCamp] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCalifCamp_1] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [uc_ccCalifCamp] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_1] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_2] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_3] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_4] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_5] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_6] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCallsIn] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_cccallsin_tmpChart] ON [dbo].[cccallsin_tmpChart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCallsReject] ON [dbo].[ccCallsReject] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCamEspAgentStatus] ON [dbo].[ccCamEspAgentStatus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCamps] ON [dbo].[ccCamps] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCamps_Consulta] ON [dbo].[ccCamps_Consulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [iii] ON [dbo].[ccCampsAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCampsAgente] ON [dbo].[ccCampsAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCampsHorarios] ON [dbo].[ccCampsHorarios] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCampsMsgs] ON [dbo].[ccCampsMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCampsNvosCB] ON [dbo].[ccCampsNvosCB] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCampsPrioridadTel] ON [dbo].[ccCampsPrioridadTel] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccClientes] ON [dbo].[ccClientes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccDNIS] ON [dbo].[ccDNIS] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccDNIS] ON [dbo].[ccDNIS] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccEdoAniList] ON [dbo].[ccEdoAniList] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenAgent] ON [dbo].[ccGenAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenAgentNotReady] ON [dbo].[ccGenAgentNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenChart] ON [dbo].[ccGenChart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInAbnd] ON [dbo].[ccGenInAbnd] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInAnsw] ON [dbo].[ccGenInAnsw] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCalif] ON [dbo].[ccGenInCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCall] ON [dbo].[ccGenInCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCallDNI] ON [dbo].[ccGenInCallDNI] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSpec] ON [dbo].[ccGenInSpec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCall] ON [dbo].[ccGenOutCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallCalif] ON [dbo].[ccGenOutCallCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallDials] ON [dbo].[ccGenOutCallDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSpecOut] ON [dbo].[ccGenOutCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCstoResumen] ON [dbo].[ccGenOutCstoResumen] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenLogin] ON [dbo].[ccGenSession] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionAgent] ON [dbo].[ccGenSessionAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionInCall] ON [dbo].[ccGenSessionInCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionInSpec] ON [dbo].[ccGenSessionInSpec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionNotReady] ON [dbo].[ccGenSessionNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionOutCall] ON [dbo].[ccGenSessionOutCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionOutCamp] ON [dbo].[ccGenSessionOutCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccHistorialListaNegra] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccHistorialListaNegra_1] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccHistorialListaNegra_2] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccHistorialListaNegra_3] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccHistorialListaNegra] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccHorarios] ON [dbo].[ccHorarios] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccHorarioVerano] ON [dbo].[ccHorarioVerano] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccHorarioVeranoUsa] ON [dbo].[ccHorarioVeranoUsa] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccInbound] ON [dbo].[ccInbound] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccInbound_Consulta] ON [dbo].[ccInbound_Consulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccInboundAgentes] ON [dbo].[ccInboundAgentes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccInboundDNIS] ON [dbo].[ccInboundDnis] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccInboundHorarios] ON [dbo].[ccInboundHorarios] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccInboundMsgs] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccInboundMsgs_1] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccInboundMsgs_2] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccInboundMsgs_3] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccListaNegra] ON [dbo].[ccListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_1] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_2] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_3] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_4] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_5] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccLogAgentesDia_Dialog] ON [dbo].[ccLogAgentesDia_Dialog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNotReady] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNotReady_2] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNotReady_3] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNotReady_4] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogLogin] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogLogin_1] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogLogin_2] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogLogin_3] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogReciclaje] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogReciclaje_1] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogReciclaje_2] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogTransfers_2] ON [dbo].[ccLogTransfers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccMenu_Views] ON [dbo].[ccMenu_Views] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccMenu_ViewsUser] ON [dbo].[ccMenu_ViewsUser] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccMenus] ON [dbo].[ccMenus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccMenus] ON [dbo].[ccMenus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccMenusReportes] ON [dbo].[ccMenusReportes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccMonitorExt] ON [dbo].[ccMonitorExt] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccMsgFiles] ON [dbo].[ccMsgFiles] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks2] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_1] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_10] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_11] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_2] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_3] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_4] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_5] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_6] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_7] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_8] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_9] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut12] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoCallsOut] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_1] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_10] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_11] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_2] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_3] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_4] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_5] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_6] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_7] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_8] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_9] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoDatos] ON [dbo].[ccoDatos] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccodialercamp] ON [dbo].[ccoDialerCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoDialers] ON [dbo].[ccoDialers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccodialers] ON [dbo].[ccoDialers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_1] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_2] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_3] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_4] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoLogDials] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_1] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_10] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_11] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_12] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_13] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_14] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_2] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_3] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_4] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_5] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_6] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_7] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_8] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_9] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoWorkingTable] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicion] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicion_1] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicion_2] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccPosicion] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccPuertosPBX] ON [dbo].[ccPuertosPBX] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallBacks] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACallBacks] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACallBacks_1] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACallBacks_2] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACallBacks_3] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACampEspWG] ON [dbo].[ccRIACampEspWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACampEspWG_1] ON [dbo].[ccRIACampEspWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACampEspWG_2] ON [dbo].[ccRIACampEspWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACampsGraph] ON [dbo].[ccRIACampsGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACat_Restrictions] ON [dbo].[ccRIACat_AdminRole] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACat_DialMode] ON [dbo].[ccRIACat_DialMode] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACatFunExt] ON [dbo].[ccRIACatFunExt] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAChat_Log_1] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChat_TipoMsg] ON [dbo].[ccRIAChat_TipoMsg] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAClienteCarga] ON [dbo].[ccRIAClienteCarga] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAClienteCarga_1] ON [dbo].[ccRIAClienteCarga] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIADispMonitorRel] ON [dbo].[ccRIADispMonitorRel] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAExternalApplications] ON [dbo].[ccRIAExternalApplications] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAGraphics] ON [dbo].[ccRIAGraphics] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAGraphicType] ON [dbo].[ccRIAGraphicType] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAInboundGraph] ON [dbo].[ccRIAInboundGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIALoading] ON [dbo].[ccRIALoading] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIALoading_1] ON [dbo].[ccRIALoading] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIALoading] ON [dbo].[ccRIALoading] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIALog] ON [dbo].[ccRIALog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIALog_Module] ON [dbo].[ccRIALog_Module] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIALog_Operation] ON [dbo].[ccRIALog_Operation] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIALogAgentesNotReady] ON [dbo].[ccRIALogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIALogAgentesNotReady_1] ON [dbo].[ccRIALogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIANotReadyGraph] ON [dbo].[ccRIANotReadyGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIARegistryLists] ON [dbo].[ccRIARegistryLists] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_Table_1] ON [dbo].[ccRIARegistryLists] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRiaRemoteLog] ON [dbo].[ccRiaRemoteLog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAUpdateCallBack_Abandon_1] ON [dbo].[ccRIAUpdateCallBack_Abandon] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAUpdateCallBack_Abandon] ON [dbo].[ccRIAUpdateCallBack_Abandon] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_2] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_3] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_WGCal_id] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_cccRIAWorkGroup_logdial_id_2] ON [dbo].[ccRIAWorkGroup_logDial_id] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_WGlogDial_id] ON [dbo].[ccRIAWorkGroup_logDial_id] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAWorkGroupUsers] ON [dbo].[ccRIAWorkGroupUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccSettings] ON [dbo].[ccSettings] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccStatusLLamada] ON [dbo].[ccStatusLLamada] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccSupervisorND] ON [dbo].[ccSupervisor_NotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [ix_tipo_1] ON [dbo].[ccSupervisorCam] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccSupervisorCam] ON [dbo].[ccSupervisorCam] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_TideWater_Templates] ON [dbo].[ccTideWater_Templates] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTideWater_Templates_Cols] ON [dbo].[ccTideWater_Templates_Cols] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTideWater_TipoConexion] ON [dbo].[ccTideWater_TipoConexion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_Timetable] ON [dbo].[ccTimetable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTimetablechange] ON [dbo].[ccTimetablechange] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTimetabledetail] ON [dbo].[ccTimetabledetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTimeZoneArea_1] ON [dbo].[ccTimeZoneArea] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [pk_areaprefix] ON [dbo].[ccTimeZoneAreaUsaDetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTimeZones] ON [dbo].[ccTimeZones] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoCalif] ON [dbo].[ccTipoCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoCalifOUT] ON [dbo].[ccTipoCalifOUT] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoCalifSub] ON [dbo].[ccTipoCalifSub] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoSubCalifOUT] ON [dbo].[ccTipoCalifSubOUT] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoFiltro] ON [dbo].[ccTipoFiltro] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoMovsListaNegra] ON [dbo].[ccTipoMovsListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoMsgs] ON [dbo].[ccTipoMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoNotReady] ON [dbo].[ccTipoNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoPBX] ON [dbo].[ccTipoPBX] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoResultadoDial] ON [dbo].[ccTipoResultadoDial] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTiposListaNegra] ON [dbo].[ccTiposListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoStatusAgente] ON [dbo].[ccTipoStatusAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cctipoSubCalifRel] ON [dbo].[cctipoSubCalifRel] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccUploadTemporal] ON [dbo].[ccUploadTemporal] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccUploadTemporal_1] ON [dbo].[ccUploadTemporal] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccusers] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccusers_1] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccUsers] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccUsers_Consulta] ON [dbo].[ccUsers_Consulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cstoProvedor] ON [dbo].[cstoProvedor] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cstoTarifa] ON [dbo].[cstoTarifa] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_cstoTipoLlamada] ON [dbo].[cstoTipoLlamada] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY  = OFF, ONLINE = OFF )
ALTER INDEX [PK_IVR_ID_1] ON [dbo].[IVRCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_Series] ON [dbo].[Series] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_Series_1] ON [dbo].[Series] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_telefonosConferencia] ON [dbo].[telefonosConferencia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_telefonosTransferencia] ON [dbo].[telefonosTransferencia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Statistics Task]    Script Date: 07/16/2013 15:25:05 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Update Statistics Task'', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''UPDATE STATISTICS [dbo].[ACDlistanegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[axLicG729_Data] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[Camplistanegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccAbandonoSalida] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccAbandonoSalida_Chart] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccAgenda_TipolistaNegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccAgendaListaNegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccAllInfoEspec] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccAVRSTransfer] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccBorrardasReciclaje] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cccalifblacklist] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCalifCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCallsIn] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cccallsin_tmpChart] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCallsReject] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCamEspAgentStatus] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCamps] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCamps_Consulta] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsAgente] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsAutoInicio] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsDialInfo] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsHorarios] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsMovs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsMovsAgts] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsMsgs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsNvosCB] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsPrioridadTel] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccClientes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccDataAgents] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccDataCamps] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccDataGridByUser] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccDias] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccDNIS] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccEdoAniList] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccEstadosAni] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenAgent] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenAgentNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenChart] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInAbnd] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInAnsw] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCallDNI] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInSpec] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallDials] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCstoResumen] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSession] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionAgent] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionInCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionInSpec] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionOutCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionOutCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccgenTelMarcados] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHistorialListaNegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarios] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarioVerano] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarioVeranoArg] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarioVeranoChi] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarioVeranoCol] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarioVeranoUsa] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarioVeranoVen] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInbound] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInbound_Consulta] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInboundAgentes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInboundDnis] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInboundHorarios] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInboundInfo] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInboundMsgs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccListaNegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgente] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgentesDia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgentesDia_Dialog] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgentesNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogCamps] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogCampsAgentesDia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogInfo] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogLogin] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogReciclaje] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogTransfers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenu_Views] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenu_ViewsUser] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenuReportesUser] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenus] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenusReportes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenuUser] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMonitorExt] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMsgFiles] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoCallBacks] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoCallsOut] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoCallsOutSource] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoDatos] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoDialerCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoDialers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoLogDials] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoWorkingTable] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoXferType] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPosicion] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPosicionCamps] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPosicionEspecialidad] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPuertosPBX] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIA_vmACDMailBoxes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIA_vmMailBoxes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIA_vmMessages] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAAreaWorkGroup] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACallBack_Queue] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACallBacks] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACampEspWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACampsGraph] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_AdminPermissions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_AdminRole] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_Areas] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_Country] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_DataGrid] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_DialMode] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_WorkGroup] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACatConnStrings] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACatFunExt] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACATLogPhones] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChat_Log] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChat_TipoMsg] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAClassPath] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAClienteCarga] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIADispMonitorRel] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAExternalApplications] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAGraphics] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAGraphicType] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAInboundGraph] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALoading] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALog] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALog_Cat_Relation] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALog_Module] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALog_Operation] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALogAgentesNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALogPhones] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIANotReadyGraph] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIARegistryLists] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRiaRemoteLog] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIARoleMenu] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAUpdateCallBack_Abandon] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAUserRole] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAUsr_AdminPermissions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAWorkGroup_Calid] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAWorkGroup_logDial_id] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAWorkGroupUsers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccSettings] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccStatusLLamada] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccSupervisor_NotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccSupervisorCam] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTeclaExtensionPuerto] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTideWater_Templates] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTideWater_Templates_Cols] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTideWater_TipoConexion] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimetable] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimetablechange] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimetabledetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimeZoneArea] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimeZoneAreaArgDetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimeZoneAreaUsaDetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimeZones] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalifOUT] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalifSub] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalifSubOUT] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoDias] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoDnis] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoFiltro] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoMovsListaNegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoMsgs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoPBX] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoResultadoDial] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTiposListaNegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoStatusAgente] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cctipoSubCalifRel] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoUsers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUnavailableRelation] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUploadBlocked] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUploadTemporal] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUploadWrong] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUsers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUsers_Consulta] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cli_TipoOrigenLlamada] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cstoProvedor] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cstoTarifa] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cstoTipoLlamada] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ivrActividadPto] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRCallsIn] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVROptions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRStructure] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRTemplate] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRTemplateAudio] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRTemplateStruct] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ScriptingAgentConfiguration] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ScriptingAnswerTemplate] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ScriptingCampaignRelation] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ScriptingTemplate] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ScriptingTemplateStruct] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[Series] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[SeriesArg] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[seriesAU] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[seriesBR] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[seriesChi] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[SeriesCol] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[seriesSA] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[seriesUK] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[SeriesVen] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[telefonosConferencia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[telefonosIvr] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[telefonosTransferencia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[xxClienteCarga] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[xxClienteConexiones] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[xxClienteHistorial] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[xxLog] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenViewAgent] 
WITH FULLSCAN, NORECOMPUTE 
UPDATE STATISTICS [dbo].[ccGenViewAgentMaxSession] 
WITH FULLSCAN, NORECOMPUTE
UPDATE STATISTICS [dbo].[ccGenViewInCall] 
WITH FULLSCAN, NORECOMPUTE
UPDATE STATISTICS [dbo].[ccGenViewOutCall] 
WITH FULLSCAN, NORECOMPUTE
UPDATE STATISTICS [dbo].[ccGenViewRelsSupsAgent] 
WITH FULLSCAN, NORECOMPUTE
UPDATE STATISTICS [dbo].[VIEW_LOG_AGENTES] 
WITH FULLSCAN, NORECOMPUTE
UPDATE STATISTICS [dbo].[VIEW_LOG_CALLSOUT] 
WITH FULLSCAN, NORECOMPUTE'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clean Up History Task]    Script Date: 07/16/2013 15:25:05 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Clean Up History Task'', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''declare @dt datetime 
select @dt = getdate()

exec msdb.dbo.sp_delete_backuphistory @dt

EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date=@dt

EXECUTE msdb..sp_maintplan_delete_log null,null,@dt'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Back Up Database Task]    Script Date: 07/16/2013 15:25:05 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Back Up Database Task'', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @currentdate datetime
declare @date varchar(200)
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = ''''CCenterRia_backup_MP'''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''.bak''''

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''HKEY_LOCAL_MACHINE'''', N''''Software\Microsoft\MSSQLServer\MSSQLServer'''',N''''BackupDirectory''''

select @rutaBak = Data
from #RutaBak

select @rutaBak= @rutaBak + ''''\'''' + @date

drop table #RutaBak

BACKUP DATABASE [CCenterRia] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10
'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Maintenance Clean Up Task]    Script Date: 07/16/2013 15:25:05 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Maintenance Clean Up Task'', 
		@step_id=10, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @currentdate datetime
declare @date datetime
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = dateadd(ww,-3,getdate())

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''HKEY_LOCAL_MACHINE'''', N''''Software\Microsoft\MSSQLServer\MSSQLServer'''',N''''BackupDirectory''''

select @rutaBak = Data
from #RutaBak

EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''bak'''',@date

drop table #RutaBak'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Monthly'', 
		@enabled=1, 
		@freq_type=32, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=1, 
		@freq_recurrence_factor=1, 
		@active_start_date=20130716, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_SaveStatusAgent - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus smallint,
@TipoCall  tinyint,
@Camp smallint
AS
declare @Fecha4 datetime
set @Fecha4 = getdate()

if @TipoCall > 0
	set @TipoCall = @TipoCall - 1

if (@User_id > 0 )
begin
	if (@TipoStatusAge_id=4) -- 4 = Dialogo
	 begin
		declare @tStatus3 int, @Fecha3 datetime
		select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
		insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
		select @User_id, cam_id, datediff(ms, dateadd(ss, -@tStatus3, @Fecha3), dateadd(ss, -@tStatus, @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
		from cccampsagente where user_id = @User_id
	 end

	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo )
	VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall )

	if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
	begin
		INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )

		---Para Agente RIA: OAYC
		INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )			
	end

	-- Actualiza para reporte de tiempos especiales (Boan)
	if @Camp > 0
		begin
			if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesDia with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
			
			if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesNotReady with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
		end
end'

	EXEC(@Sql)
	
		set @process = 'ccsp_RIAsubCalif - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAsubCalif]
@action tinyint = 0,
@tipo tinyint = null, --	0:Outbound / 1:Inbound
@calif_id varchar(max) = nulesol,
@califSub_id varchar(max) = null,
@califSubDesc varchar(40) = null,
@canReprogramSub tinyint = null,
@orden varchar(3) = null,
@idTipoLista int = null,
@keepDial tinyint = null,
@autoCallback tinyint = null
as
set nocount on
begin try
	declare @sxML as varchar(max), @xml as xml, @succesValue varchar(2), @succesType varchar(2)
	set @xml = cast(''<?xml version="1.0"?> <MainSubQualificationLoad/>'' as xml)
	set @xml.modify(''insert element action {""} as last into (/MainSubQualificationLoad)[1]'')
	set @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/MainSubQualificationLoad/action)[1]'')

	if @action = 0
	 begin
		select @succesValue=0, @succesType=1 -- No se ingreso el action
		goto Success
	 end

	if @action=1	--	Muestra info de Inbound
	 begin
		set @xml.modify(''insert element qualifications {""} as last into (/MainSubQualificationLoad)[1]'')
		set @xml.modify(''insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]'')
		set @xml.modify(''insert element subQualifications {""} as last into (/MainSubQualificationLoad)[1]'')
		
		select @sxML = cast((select * from (select 1 as tag, null as parent, 
		calif_id as "qualification!1!qualif_id", Description as "qualification!1!qualification",
		CanReprogram as "qualification!1!canReprogram", orden as "qualification!1!sort"
		from cctipocalif where Calif_Status=1) as x order by tag, "qualification!1!sort", 
		"qualification!1!qualification" for xml explicit, type) as varchar(max))
		select @xml=dbo.xmlAppend(@xml, @sxML, ''<qualifications/>'')
		
		select @sxML = cast((select * from (select 1 as tag, null as parent, 
		R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification", isnull(O.canReprogram,0) "qualifRelation!1!canReprogram"
		from cctipoSubCalifRel R join cctipocalifSub O on R.califSub_id = O.califSub_id
		where R.tipoSubRel=1 and R.calif_id in (select top 1 calif_id from cctipocalif where Calif_Status=1 order by orden, Description)) as x 
		order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
		select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')
		
		select @sxML = cast((select * from (select 1 as tag, null as parent, 
		califSub_id as "subQualification!1!qualif_id", califSubDesc as "subQualification!1!qualification",
		isnull(CanReprogram, 0) as "subQualification!1!canReprogram", isnull(orden, 0) as "subQualification!1!sort"
		from cctipocalifSub where CalifSub_Status=1 ) as x order by tag, "subQualification!1!sort", 
		"subQualification!1!qualification" for xml explicit, type) as varchar(max))
		select @xml=dbo.xmlAppend(@xml, @sxML, ''<subQualifications/>'')
		
		select @xml
		return(0)
	 end

	if @action=2	--	Muestra Info de Outbound
	 begin
		set @xml.modify(''insert element qualifications {""} as last into (/MainSubQualificationLoad)[1]'')
		set @xml.modify(''insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]'')
		set @xml.modify(''insert element subQualifications {""} as last into (/MainSubQualificationLoad)[1]'')

		select @sxML = cast((select * from (select 1 as tag, null as parent, 
		calif_id as "qualification!1!qualif_id", Description as "qualification!1!qualification",
		CanReprogram as "qualification!1!canReprogram", orden as "qualification!1!sort",
		autoCallback as "qualification!1!AutoCB", keepDial as "qualification!1!keepDial"
		from cctipocalifOUT where CalifOut_Status=1) as x order by tag, "qualification!1!sort", 
		"qualification!1!qualification" for xml explicit, type) as varchar(max))
		select @xml=dbo.xmlAppend(@xml, @sxML, ''<qualifications/>'')

		select @sxML = cast((select * from (select 1 as tag, null as parent, 
		R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification", isnull(O.canReprogram,0) "qualifRelation!1!canReprogram"
		from cctipoSubCalifRel R join cctipocalifSubOUT O on R.califSub_id = O.califSub_id
		where R.tipoSubRel=0 and R.calif_id in (select top 1 calif_id from cctipocalifOUT where CalifOUT_Status=1 order by orden, Description)) as x 
		order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
		select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')

		select @sxML = cast((select * from (select 1 as tag, null as parent, 
		califSub_id as "subQualification!1!qualif_id", califSubDesc as "subQualification!1!qualification",
		isnull(CanReprogram,0) as "subQualification!1!canReprogram", isnull(orden,0) as "subQualification!1!sort",
		isnull(autoCallback,0) as "subQualification!1!AutoCB", isnull(keepDial,0) as "subQualification!1!keepDial"
		from cctipocalifSubOUT where CalifSubOut_Status=1 ) as x order by tag, "subQualification!1!sort", 
		"subQualification!1!qualification" for xml explicit, type) as varchar(max))
		select @xml=dbo.xmlAppend(@xml, @sxML, ''<subQualifications/>'')

		select @xml
		return(0)
	 end

 	if @tipo is null
	 begin
		select @succesValue=0, @succesType=2 -- No se ingreso el tipo
		goto Success
	 end
	 
	if @action=3	--	Muestra relacion de Calificaciones con subCalificaciones
	 begin
		set @xml.modify(''insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]'')
		
		if @tipo=0
		 begin
			select @sxML = cast((select * from (select 1 as tag, null as parent, 
			R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification", 
			isnull(O.canReprogram,0) "qualifRelation!1!canReprogram", autoCallback "qualifRelation!1!autoCallback"
			from cctipoSubCalifRel R join cctipocalifSubOUT O on R.califSub_id = O.califSub_id
			where R.tipoSubRel=0 and R.calif_id in (select value from dbo.fn_RIASplitDelimited(@calif_id,'',''))) as x 
			order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
			select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')
			select @xml
			return(0)
		 end

		select @sxML = cast((select * from (select 1 as tag, null as parent, 
		R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification", 
		isnull(O.canReprogram,0) "qualifRelation!1!canReprogram"
		from cctipoSubCalifRel R join cctipocalifSub O on R.califSub_id = O.califSub_id
		where R.tipoSubRel=1 and R.calif_id in (select value from dbo.fn_RIASplitDelimited(@calif_id,'',''))) as x 
		order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
		select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')
		select @xml
		return(0)
	 end

	if @action=4	--	Alta de subcalificaciones
	 begin
		if isnull(@califSubDesc, '''')=''''
		 begin
			select @succesValue=0, @succesType=6 -- No se ingreso el nombre de la subcalificacion
			goto Success
		 end
	 
		if @tipo=0
		 begin
			if exists(select califSub_id from cctipocalifSubOUT where califSubOut_Status=1 and califSubDesc=@califSubDesc)
			 begin
				select @succesValue=0, @succesType=3 -- La subCalificacion ya existe
				goto Success
			 end
		
			insert cctipocalifSubOUT (califSubDesc, canReprogram, orden, idTipoLista, califSubOut_Status, keepDial, autoCallback)
			select @califSubDesc, @canReprogramSub, @orden, @idTipoLista, 1, @keepDial, @autoCallback
			select @succesType=scope_identity(), @succesValue=1
			goto Success
		 end

		if exists(select califSub_id from cctipocalifSub where califSub_Status=1 and califSubDesc=@califSubDesc)
		 begin
			select @succesValue=0, @succesType=3 -- La subCalificacion ya existe
			goto Success
		 end
		insert cctipocalifSub (califSubDesc,orden,canReprogram,califSub_Status) 
					   select @califSubDesc, @orden, @canReprogramSub, 1
		select @succesType=scope_identity(), @succesValue=1
		goto Success
	 end

	if @action=5	--	baja de subcalificaciones
	 begin
 		delete cctipoSubCalifRel where tipoSubRel=@tipo and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, '',''))
		
		if @tipo=0
		 begin
			update cctipocalifSubOUT set califSubOut_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, '',''))
			update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
			select @succesValue=1
			goto Success
		 end

		update cctipocalifSub set califSub_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, '',''))
		select @succesValue=1
		goto Success
	 end

	if @action=6	--	Actualizacion de subcalificaciones
	 begin
 		if @tipo=0
		 begin
			if not exists(select califSub_id from cctipocalifSubOUT where califSub_id = cast(@califSub_id as smallint))
			 begin
				select @succesValue=0, @succesType=4 -- La subCalificacion no existe
				goto Success
			 end
		 
			update cctipocalifSubOUT set califSubDesc=isnull(@califSubDesc, califSubDesc), canReprogram=isnull(@canReprogramSub, canReprogram), 
				orden=isnull(@orden, orden), idTipoLista=isnull(@idTipoLista, idTipoLista), keepDial=isnull(@keepDial, keepDial), 
				autoCallback=isnull(@autoCallback, autoCallback) where califSub_id = cast(@califSub_id as smallint)
			update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
			select @succesValue=1
			goto Success
		 end

		if not exists(select califSub_id from cctipocalifSub where califSub_id = cast(@califSub_id as smallint))
		 begin
			select @succesValue=0, @succesType=4 -- La subCalificacion no existe
			goto Success
		 end

		if @canReprogramSub=1 
         begin
			declare @asignada bit, @can bit
			select @asignada=IB.inbound_id, @can=IB.cam_id from cctipoSubCalifRel CR join cctipoCalif TC on CR.calif_id = TC.calif_id and CR.tipoSubRel=1
		    join ccCalifCamp CM on TC.calif_id = CM.calif_id and CM.tipo = 0 join ccInbound IB on CM.cam_id = IB.inbound_id where califSub_id = cast(@califSub_id as smallint)
            if @asignada is not null and @can is null
		     begin
			    select @succesValue=0, @succesType=5 -- No se puede reprogramar ya que no hay campaña asignada
			    goto Success
		     end
         end

		update cctipocalifSub set califSubDesc=isnull(@califSubDesc, califSubDesc), orden=isnull(@orden, orden), 
			canReprogram=isnull(@canReprogramSub, canReprogram) where califSub_id = cast(@califSub_id as smallint)

		exec ccsp_RIACATQualifications @Type = 4, @CamEspId = 0, @canReprogram = @canReprogramSub, @qualif_id = @califSub_id
		select @succesValue=1
		goto Success
	 end

	if @action=7	--	Asignacion de Calfs / SubCalfs
	 begin
		if @tipo=1 and (select cast(sum(isnull(cast(canReprogram as tinyint),0)) as bit) FROM cctipocalifSub where califSub_id in 
		(select value from dbo.fn_RIASplitDelimited (@califSub_id, '','')))>0 and not exists (select IB.cam_id from cctipocalif CO 
		join ccCalifCamp CF on  CF.calif_id = CO.calif_id and CF.tipo = 0 join ccInbound IB on IB.Inbound_id = CF.cam_id
		where IB.cam_id is not null and CO.calif_id in (select value from dbo.fn_RIASplitDelimited (@calif_id, '','')))
		 begin
			select @succesValue=0, @succesType=5 -- No se puede reprogramar ya que no hay campaña asignada
			goto Success
		 end
	 
		insert cctipoSubCalifRel (calif_id, califSub_id, tipoSubRel)
		select C.value calif_id, S.value califSub_id, @tipo Tipo 
		from dbo.fn_RIASplitDelimited (@califSub_id, '','') S
		 cross join dbo.fn_RIASplitDelimited (@calif_id, '','') C
		where cast(C.value as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@tipo as varchar(10)) not in
		 (select cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) from cctipoSubCalifRel)
		and C.value is not null and S.value is not null

		if @tipo=0
			update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)

		select @succesValue=1
		goto Success
	 end

	if @action=8	--	Desasignacion de Calfs / SubCalfs
	 begin
		delete cctipoSubCalifRel
		where cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) in 
		(select cast(C.value as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@tipo as varchar(10))
		 from dbo.fn_RIASplitDelimited (@califSub_id, '','') S cross join dbo.fn_RIASplitDelimited (@calif_id, '','') C)

		if @tipo=0
			update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)

		select @succesValue=1
		goto Success
	 end

	return(0)
 end try

begin catch
	select @succesValue=0, @succesType=0 -- error no controlado
	goto Success
end catch

Success: -- <success value=''n'' type=''n''/>
set @xml.modify(''insert element success {""} as last into (/MainSubQualificationLoad)[1]'')
set @xml.modify(''insert attribute value {sql:variable("@succesValue")} as last into (/MainSubQualificationLoad/success)[1]'')
if isnull(@succesType, 0) <> 0
 begin
	set @xml.modify(''insert attribute type {sql:variable("@succesType")} as last into (/MainSubQualificationLoad/success)[1]'')
 end
select @xml
return(0)
set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAOUTInsertNewJOBS_WT_Camp - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp]
@camp_id as int,
@reciclar as int = 1
as
set nocount on

declare @prioridad varchar(8)

Delete ccUploadTemporal with(rowlock)
where cam_id = @camp_id

update ccoCallBacks with(rowlock)
set [status] = 6, schedulerStatus = 1
where callout_id in (select cs.callout_id
from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_11),nolock) 
inner join ccoWorkingTable wt with(index(IX_ccoWorkingTable),nolock)
on cs.cal_key = wt.cal_keyw and cs.cam_id = wt.cam_id 
where cs.cam_id = @camp_id
and wt.cal_status <= 2
and cs.cal_status in(0,7))

update ccoCallsOutSource
set cal_Status = 4 
from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_11),nolock)
inner join ccoWorkingTable wt with(index(IX_ccoWorkingTable),nolock)
on cs.cal_key = wt.cal_keyw and cs.cam_id = wt.cam_id 
where cs.cam_id = @camp_id
and wt.cal_status <= 2
and cs.cal_status in(0,7)

update ccoCallBacks with(rowlock)
set [status] = 6, schedulerStatus = 1
where callout_id in (select Cout.callout_id
from ccoCallsOutSource Cout with(index(IX_ccoCallsOutSource_11),nolock)
JOIN ccoworkingtable Wtab
ON Cout.callout_id = Wtab.callout_id 
WHERE Cout.cam_id = @camp_id 
and (COUT.cal_status < 2 or COUT.cal_status = 7))

update ccoCallsOutSource
set cal_Status = 4 
from ccoCallsOutSource Cout with(index(IX_ccoCallsOutSource_11),nolock)
JOIN ccoworkingtable Wtab
ON Cout.callout_id = Wtab.callout_id 
WHERE Cout.cam_id = @camp_id 
and (COUT.cal_status < 2 or COUT.cal_status = 7)

Insert ccoWorkingTable (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2,
	iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
SELECT callout_id, cam_id, 
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono,
case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key, 
case when len( cal_telefono ) > 0 then iZonaHoraria else null end, case when len( cal_telefono ) > 0 then iZonaHoraria_verano else null end, 
case when len( cal_telefono2 ) > 0 then iZonaHoraria2 else null end, case when len( cal_telefono2 ) > 0 then iZonaHoraria_verano2 else null end, 
case when len( cal_telefono3 ) > 0 then iZonaHoraria3 else null end, case when len( cal_telefono3 ) > 0 then iZonaHoraria_verano3 else null end, 
case when len( cal_telefono4 ) > 0 then iZonaHoraria4 else null end, case when len( cal_telefono4 ) > 0 then iZonaHoraria_verano4 else null end, 
case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end,
list_id
FROM ccoCallsOutSource with(index(IX_ccoCallsOutSource_11),nolock)
WHERE cam_id = @camp_id 
and (cal_status < 2 or cal_status = 7) -- Nuevos Jobs

Insert into ccoCallBacks
(callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus) 
SELECT callout_id, user_id, cam_id, cal_key,
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono1,
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono2,cal_fechaDial,cal_fechaDial,NULL,0,1
FROM ccoCallsOutSource with(index(IX_ccoCallsOutSource_11),nolock)
WHERE cam_id = @camp_id 
and (cal_status < 2 or cal_status = 7) -- Nuevos Jobs

select @prioridad = isnull(Prioridad,''12345NNN'') from ccCampsPrioridadTel where cam_id = @camp_id

UPDATE ccoCallsOutSource with(rowlock)
SET cal_status = 2, dial_tels = @prioridad, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) 
and cam_id = @camp_id

set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_OUTInsertaCallBack - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_OUTInsertaCallBack]
@cal_id int,
@Telefono varchar(15),
@Camp smallint,
@FechaDial smalldatetime,
@callout_id int=0,
@TelReprograma smallint=-1,
@user_id int=0,
@cal_Key varchar(33)=''''
as
set nocount on
IF @TelReprograma<0
      return(0)
 
declare @Fecha smalldatetime, @sSQL nvarchar(max)
declare @iZonaHoraria int,@iZonaHoraria_verano int,@iZonaHoraria2 int, @iZonaHoraria_verano2 int,@iZonaHoraria3 int,@iZonaHoraria_verano3 int,@iZonaHoraria4 int,@iZonaHoraria_verano4 int,@iZonaHoraria5 int,@iZonaHoraria_verano5 int
declare @idZone int, @idZoneDaylight int, @list_id int
declare @bIsDaylight bit, @difference int
declare @TelOriginal varchar(15)
declare @FechaOriginal datetime
 
select @callout_id = callout_id, @TelOriginal = cal_telefono, @FechaOriginal = cal_Inicio
from ccocallsout
where Cal_id=@cal_id
 
IF @TelReprograma=0 --Otro telefono
BEGIN
      declare @tel2 varchar(20), @tel3 varchar(20), @tel4 varchar(20), @tel5 varchar(20)
      declare @phoneCompleted varchar(20)
      declare @emptyPhoneMsg varchar(50)
 
      select @idZone = dbo.fnGetTimeZone(@Telefono,0)
      select @idZoneDaylight = dbo.fnGetTimeZone(@Telefono,1)
      select @phoneCompleted = dbo.Completa(@Telefono)
      select @emptyPhoneMsg = case valor when 0 then ''El teléfono no puede ser nulo o vacío'' else ''Phone number can not be null or empty'' end from ccsettings where setting_id = 27
 
      if charIndex(''E_NV'',@phoneCompleted) > 0
            set @phoneCompleted = @Telefono
            if @phoneCompleted = ''''
            begin
                  raiserror(@emptyPhoneMsg, 18, 1)
            end
 
     select @tel2=cal_telefono2,@tel3=cal_telefono3,@tel4=cal_telefono4,@tel5=cal_Telefono5,@cal_Key=cal_key
     from ccoCallsoutSource where callout_id=@callout_id
     
      select @TelReprograma=case when isnull(@tel4,'''')='''' then 4 when isnull(@tel3,'''')='''' then 3     when isnull(@tel2,'''')='''' then 2 else 5 end
 
      select @sSQL=''update ccoCallsOutSource set cal_telefono''+cast(@TelReprograma as varchar(1))+''=''''''+@phoneCompleted+''''''''
      +'',cal_status=2,dial_Tels=''''''+cast(@TelReprograma as char(1))+replace(''2345NNN'',cast(@TelReprograma as char(1)),''1'')+''''''''
      +'', iZonaHoraria''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZone as varchar(10))+'', iZonaHoraria_Verano''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZoneDaylight as varchar(10))+'' where callout_id=''+cast(@callout_id as varchar(10))
      exec(@sSQL)
END
 
ELSE--@>0 telefono ya existente
BEGIN
      update ccoCallsOutSource set cal_status=2,
      dial_Tels=cast(@TelReprograma as char(1))+ replace(''2345NNN'',cast(@TelReprograma as char(1)),''1'')
      where callout_id=@callout_id
 
      select @sSQL= N''select @outA=cal_key, @outB=izonahoraria'' +replace( cast( @TelReprograma as varchar(1)), ''1'', '''' )+'', @outC=izonahoraria_verano''+replace( cast( @TelReprograma as varchar(1)), ''1'', '''' )+'', @outD= rtrim(left(ltrim(cal_telefono + ''''        ''''
            + cal_telefono2 + ''''         ''''
            + cal_telefono3 + ''''         ''''
            + cal_telefono4 + ''''         ''''
            + cal_telefono5 + ''''         ''''),13)) from ccoCallsOutSource where callout_id = '' +cast(@callout_id as varchar)
      exec sp_executesql @sSQL, N''@outA varchar(33) OUTPUT, @outB int OUTPUT, @outC int OUTPUT, @outD varchar(19) OUTPUT'', @outA=@cal_Key OUTPUT, @outB=@idZone OUTPUT, @outC=@idZoneDaylight OUTPUT, @outD=@Telefono OUTPUT
END
 
-- PARA LA FECHA
declare @country_id as int
select @country_id = valor from ccsettings where setting_id = 104
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
 
select @difference = dbo.fnGetTimeDifference(case when @bIsDaylight = 0 then @idZone else @idZoneDaylight end)
select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))    
update ccoCallsOut set cal_fcallback=@FechaDial where cal_id=@cal_id
 
--PARA LAS ESTADISTICAS
if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha) and mes=month(@Fecha) and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@Camp)
      update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@Camp
else
      insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@Camp
 
select @iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end, @iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end,
 @iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end, @iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end,
@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end, @iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end,
@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end, @iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end,
@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end, @iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end,
@list_id=list_id
from ccocallsoutsource where callout_id=@callout_id
 
if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
      UPDATE ccoWorkingTable SET cal_telefono=@Telefono, cam_id=@Camp,cal_fechaDial=@Fecha,
      cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_Key,
      iZonaHoraria = @iZonaHoraria, iZonaHoraria_Verano = @iZonaHoraria_Verano,
      iZonaHoraria2 = @iZonaHoraria2, iZonaHoraria_Verano2 = @iZonaHoraria_Verano2,
      iZonaHoraria3 = @iZonaHoraria3, iZonaHoraria_Verano3 = @iZonaHoraria_Verano3,
      iZonaHoraria4 = @iZonaHoraria4, iZonaHoraria_Verano4 = @iZonaHoraria_Verano4,
      iZonaHoraria5 = @iZonaHoraria5, iZonaHoraria_Verano5 = @iZonaHoraria_Verano5
      WHERE callout_id=@callout_id
 
else
      INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,
      [user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano,iZonaHoraria2,iZonaHoraria_verano2,iZonaHoraria3,
      iZonaHoraria_verano3,iZonaHoraria4,iZonaHoraria_verano4,iZonaHoraria5,iZonaHoraria_verano5,list_id)
      select @callout_id,@Telefono,@Camp,@Fecha,1,3,1,
      @user_id,@cal_Key,@iZonaHoraria,@iZonaHoraria_Verano,@iZonaHoraria2,@iZonaHoraria_Verano2,@iZonaHoraria3,
      @iZonaHoraria_Verano3,@iZonaHoraria4,@iZonaHoraria_Verano4,@iZonaHoraria5,@iZonaHoraria_Verano5,@list_id
 
      insert into ccoCallBacks 
	  (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus) 
	  values
	  (@callout_id,@user_id,@Camp,@cal_Key,@TelOriginal,@Telefono,@FechaOriginal,@Fecha,NULL,0,1)
 
set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_INInsertaCallBack - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_INInsertaCallBack]
@cal_key varchar(20) =''b'',
@cam_id smallint,
@cal_telefono varchar(19),
@fechadial varchar(17),
@dato1 varchar(255),
@dato2 varchar(255),
@dato3 varchar(255),
@dato4 varchar(255),
@dato5 varchar(255),
@TelReprograma smallint = -1,
@user_id int=0
AS
set nocount on
declare @TelOriginal as varchar(15)
declare @FechaOriginal as datetime

if len(@cal_telefono)<=3
	return(0)

if isnull(@cal_key,'''') = ''''
 begin
      -- Generamos cal_key aleatorio para casos de reprogramacion inbound --
      Genera_cal_key:
      select @cal_key = right(newID(), 10)
      if exists (select cal_key from ccoCallsOutSource where cal_key=@cal_key)
            goto Genera_cal_key
 end

declare @bIsDaylight as bit
declare @idioma as int
declare @country_id as varchar(3)

select @country_id = valor from ccsettings where setting_id = 104

select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

declare @difference as int
select @difference = isNull(dbo.fnGetTimeDifference(dbo.fnGetTimeZone(@cal_telefono,@bIsDaylight)),0)
declare @Fecha smalldatetime, @callout_id int, @iZonaHoraria int,@iZonaHoraria_verano int, @cal_statusTemp tinyint
select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))

if exists(select cal_Key, cam_id from ccoCallsOutSource where cal_Key = @cal_key and cam_id =@cam_id)
 begin
	select @callout_id=callout_id,@cal_statusTemp =cal_status,@iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano, @TelOriginal = cal_telefono, @FechaOriginal = cal_fechadial from ccoCallsOutSource where cal_Key = @cal_key and cam_id = @cam_id
	update ccoCallsOutSource set cal_status = ''2'',cal_telefono=@cal_telefono where cal_key = @cal_key and cam_id = @cam_id

	if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
	else
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano)
		select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key,@iZonaHoraria,@iZonaHoraria_verano  

		insert into ccoCallBacks
		(callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus) 
		values
		(@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
  end

else
 begin
	select @FechaOriginal = getdate()

	insert into ccoCallsOutSource (cal_key,cam_id,cal_telefono,cal_fechadial,Dato1,Dato2,Dato3,Dato4,Dato5,dial_tels,cal_status)
	values (@cal_key,@cam_id,@cal_telefono,@FechaOriginal,@dato1,@dato2,@dato3,@dato4,@dato5,cast(@TelReprograma as char(1))+ replace(''2345NNN'',cast(@TelReprograma as char(1)),''1''),''2'')

	select @TelOriginal = @cal_telefono

	select @callout_id = scope_identity()
	select @iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano from ccocallsoutsource where callout_id=@callout_id

	 if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
	 else
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano)
		select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key,@iZonaHoraria,@iZonaHoraria_verano

		insert into ccoCallBacks
		(callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus) 
		values
		(@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
end

if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id)
	update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id
else
	insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@cam_id

return(0)
set nocount off'
		
	EXEC(@Sql)
	
	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
