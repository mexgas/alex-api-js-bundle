/*
Autor: Jesus Antonio Gallardo
Fecha: 2014/03/31
Descripcion:
	Se agrega setting 158 para AgentWS para integracion envio de eventos por socket o por http
	Se agrega setting 159 para Finder el numero de dias de la migracion
	Se agrega setting 160 para integracion de asterisk
	Se agrega catalogo cstotipollamada las opciones de Local y LD Nacional para USA y Argentina
	Se agrega menu para reporte de llamadas con chat
	Se actuliza menu Estado del call center de ccMenus se cambia type 0 
	Se actuliza el setting 154 la descripcion en ingles 
	Se modifica el sp ccsp_RIAGetAllInfoEspecNew para modificar el apartado short call en ACD
	Se modifica el sp ccsp_RIACATMenu para menus mail y fix de menus avrs
	Se pone rol dbwoner al sa si este es diferente

Version requerida: 107
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '108'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'insert -- ccsettings '
		set @Sql='if not exists(select * from ccsettings where setting_id=158) begin insert into ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings)
values(158,''0'',''Envia de eventos AgentWS por URL(0) Ã³ Socket(1)'',1,''X'',''0 envio eventos por URL y 1 por socket'',''Send event AgentWS by URL (0) or Socket (1)'',1) end
insert into ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings)
values(159,''90'',''Dias de migracion del finder para BaseX'',1,''X'',''Numero de dias que se procesara la informacion la BaseX'',''Days migration finder for BaseX'',1)
if not exists(select * from ccsettings where setting_id=160) begin insert into ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings)
values (160,'''',''asterisk integration'',1,''GRL'',''num_channels|offset|ip|user|pwd|tcp_port'','''',0) end'
	
	EXEC(@Sql)

	set @process = 'insert -- cstotipollamada'
	set @Sql='insert into cstotipollamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (4,1,''Local'',7,''%'')
insert into cstotipollamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (4,2,''LD Nacional'',11,''1%'')
insert into cstotipollamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (5,1,''Local'',9,''%'')
insert into cstotipollamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (5,2,''LD Nacional'',10,''0%'')
'

	EXEC(@Sql)

	set @process = 'insert -- ccMenus'
	set @Sql='insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF)
values (4140,''Detalle de llamadas en chat contestadas|Answered Calls On Chat Detail'',4000,''B'',4,3,'''')'

	EXEC(@Sql)


	set @process = 'update -- ccMenus'
	set @Sql='update ccMenus set type=0 where menu_id=31 '

	EXEC(@Sql)

	set @process = 'update -- ccsettings'
	set @Sql='update ccsettings set description = ''Include ANI numbers in VOICEMAL option'' where setting_id = 154'

	EXEC(@Sql)	

	set @process = 'ccsp_RIAGetAllInfoEspecNew -- alter SP'
	set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAGetAllInfoEspecNew]
@User_id as smallint
AS
set nocount on
-- declare @tresDialog int
-- exec @tresDialog = ccspConfigTresDialog

select a.inbound_id, calls = ISNULL(count(*), 0), -- calls
abandon = isnull(COUNT(CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0), -- Abandoned
callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0),
OverFlowQueue = ISNULL(count (case when statusCall_id =8 then 1 else null end), 0),
OverFlowTimeOut = ISNULL(count (case when statusCall_id =7 then 1 else null end), 0), -- OverFlowQueue+OverFlowTimeOut = not answered
Dialogs = ISNULL(count (case when statusCall_id = 13 then 1 else null end), 0), -- Answered
DlgsAveTime= ISNULL(sum (case when statusCall_id = 13 then cal_tDialog + cal_tNotas else 0 end), 0),
QueueAveTime=ISNULL( avg( case when cal_que > 0 then cal_tWait else null end), 0) ,
another=0, --ISNULL(count (case when statusCall_id in(2, 3, 4, 11, 15, 16) then 1 else null end), 0), -- others
outOfSchedule=ISNULL(count (case when statusCall_id =2 then 1 else null end), 0), -- fuera de horario
outOfService=ISNULL(count (case when statusCall_id =3 then 1 else null end), 0), -- fuera de servicio
noAgentsLoggedIn=ISNULL(count (case when statusCall_id =4 then 1 else null end), 0), -- sin agentes firmados
assigned=ISNULL(count (case when statusCall_id =11 then 1 else null end), 0), -- asignada
assignedAndNotAnswered=ISNULL(count (case when statusCall_id =15 then 1 else null end), 0), -- asignada y no contestada
assignedAndTookLine=ISNULL(count (case when statusCall_id =16 then 1 else null end), 0), -- asignada y toma linea
shortCalls=0, --ISNULL(sum(case when cal_tDialog < @tresDialog then 1 else 0 end), 0)
onQueue = isnull(count(case when statusCall_id = 5 then 1 else null end), 0),
initCalls = cast(isnull(count(case when statusCall_id = 1 then 1 else null end), 0) as varchar(7))+''|''+
ISNULL((SELECT STUFF((SELECT ''|'' + cast(ci.cal_id as varchar(7))
            FROM ccCallsin ci (nolock) where cal_inicio > dateadd(mi,-5,getdate()) and ci.inbound_id=a.inbound_id
            FOR XML PATH('''')) ,1,1,'''')),''0'')
from ccCallsIn a (nolock)
where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
and a.inbound_id in (select cam_id from ccSupervisorCam where user_id = @User_id and tipo = 0)
group by a.inbound_id
set nocount off
return(0)'

	EXEC(@Sql)


	set @process='ccsp_RIACATMenu -- ALter SP'
	set @Sql='ALTER procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
Declare @AVRS tinyint
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenusChat tinyint
Declare @MenuMail tinyint

set @MenuMail=0

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155

---Mail MenuId (81)
if @Type=1
begin
	if @ReportRol = 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
		and (
		(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81)) 
		or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
		or (menu_id in (71,72) and @IVRScripting = 1)
		or (menu_id in (73,74,75,76) and @AVRS = 1)
		or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
		or (menu_id = 79 and @MenusChat > 0)
		or (menu_id in (81) and @MenuMail = 1)--Mail
		)
		order by ordengral asc
		return(0)
		
	end
	else if @ReportRol = 3 begin
		select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) and menu_id not in (select distinct Parent from ccMenus where menu_id >= 2000 and type = 3)
		and (menu_id not in (3131,3132,3133,3134,3135,3136,8061,8062,8063,8071,8072,8080))
		or  (menu_id     in (3131,3132,3133,3134,3135,3136) and @MenusChat > 0 )
		or  (menu_id     in (8061,8062,8063,8071,8072,8080) and @AVRS > 0)
		order by ordengral asc
		return(0)
	end
	else begin	
		select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)
	end
	
end

if @Type=2
begin
  delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu and type = @ReportRol
  return(0)
end

if @Type=3
begin
  insert into ccMenuUser(id_User,id_Menu,type) values (@id_User, @id_Menu,@ReportRol)
  return(0)
end

if @Type=4
begin
  declare @lan varchar(3), @page varchar(200)
  select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
  select @lan = case valor when 0 then ''ES'' else ''EN'' end from ccSettings where setting_id = 27
  
  select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
  return(0)
end

set nocount off'

	EXEC(@Sql)

	set @process='ccsp_RIAMenuRoles -- Alter SP'
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

select @reportRol = case @reportRol when 0 then 1 else @reportRol end, @role_id = case @role_id when 0 then 1 else @role_id end



Declare @NRS tinyint
declare @MenusChat tinyint
declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenuMail tinyint

set @MenuMail=0


select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

---Checar si esta se aplica
select @AVRS = valor from ccSettings where setting_id = 124
select @IVRScripting = valor from ccsettings where setting_id = 125

select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
--Activa menus relacionados con campañas
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155

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
		select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
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
		
		select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
      
	  from ccRIAUserRole a 
		inner join ccMenuUser b on a.user_id = b.id_user
		inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
      where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol 
		and (	
			(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81)) 
			or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)
			or (menu_id in (71,72) and @IVRScripting = 1)		
			or (menu_id in (73,74,75,76) and @AVRS = 1)
			or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
			or (menu_id = 79 and @MenusChat > 0)
			or (menu_id in (81) and @MenuMail = 1)--Mail
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
      update ccUsers set tipoUser_id = @AVRS where user_id = @User_id 
      return(0)
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
set nocount off'

	EXEC(@Sql)


	set @process = 'update -- dbowner DATABASE'
	set @Sql='if not exists (select * from sys.databases where suser_sname(owner_sid)=''sa'' and name=''CCenterRia'') ALTER AUTHORIZATION ON DATABASE::CCenterRia TO sa'

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
