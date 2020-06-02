/*
Autor: Raymundo González
Fecha: 2012/08/01
Descripcion: 
	Se inserta menu para monitoreo de puertos de marcación en la tabla ccmenus y se configura como opcion default en ccriarolemenu
	Se inserta permiso para asignación de grupos ACD y Campañas y se otorgan los permisos correspondientes
	Se modifica Stored Procedure ccsp_RIALoadWorkGroup para revisar permisos de administrador en cuanto a asignacion de ACDs y Campañas
	Se modifica Stored Procedure ccsp_GetAgentNotReadyDetail para devolver agentes notReady de 1 supervisor
	Se modifica Stored Procedure ccsp_ExtAppsCallHistory para sacar tiempo de sesión junto con su historial
	se modifica Stored Procedure ccsp_InsertDNCList para aplicar lista negra (fix)
	Se crea Stored Procedure ccsp_ADMCalifInformation para devolver numero de llamadas por calificacion de cada agente
	Se modifica Stored Procedure ccsp_RIAcalifblacklist para validar existencia de 1 Lista Negra a insertar o borrar
	Se agregan las relaciones necesarias para mostrarse en pantalla dentro de la tabla ccRIALog_Cat_Relation
	Se eliminan de la tabla ccRIALog_Module los id de Monitoreo de Llamadas y de Grupos ACD
	Se agregan los id faltantes a la tabla ccRIALog_Operation para registro de Logs
	Se modifica Stored Procedure ccsp_GetAgentIndividualCounters para agrupar por tipo de llamada
	Se crea Stored Procedure ccsp_GetConversionFactor para devolver el factor de conversión desde WebService
	Se modifico Stored Procedure ccsp_RIA_ABCLog para devolver ordenado alfabeticamente el menu de logs
	Se agregan indices a las tablas identificadas en los Stored Procedures con mayor tiempo de ejecución en operación
	Se modifica Stored Procedure ccsp_CstoCalculaCosto para uso de nuevos indices
	Se modifica Stored Procedure ccsp_RIAABCChat para eliminar indice no requerido en consulta
	
Version requerida: 79
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '80'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

			set @Sql = 'insert into ccmenus(menu_id, menu_descrip, parent, Nivel, ordengral, type, helpSWF)
values(69, ''Monitor de puertos de marcación|Dialers Monitor'', 60, ''B'', 70, 1, '''')

insert into ccriarolemenu(role_id, id_menu, type)
values(2, 69, 1)

insert into ccriarolemenu(role_id, id_menu, type)
values(3, 69, 1)

insert into ccriarolemenu(role_id, id_menu, type)
values(6, 69, 1)

insert into ccRIACat_AdminPermissions(per_desc, bStatus) 
values(''Eliminar grupos ACD y Campañas|Delete ACD Groups and Campaign'', 1)

declare @lastID as tinyint
select @lastID = @@identity

insert into ccRIAUsr_AdminPermissions(user_id, per_id)
select ccusers.User_id, per_id
from ccusers cross join ccRIACat_AdminPermissions
where Status = 1 and TipoUser_id = 2 and per_id = @lastID'

		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_RIALoadWorkGroup]
@option smallint,
@AreaId smallint,
@Sup smallint,
@CamEspId smallint,
@InOut tinyint
as
set nocount on

if @option = 1 -- Todos los WG
 begin
	-- Agentes y Supervisores
	select a2.IDArea,a1.IDWG, a1.WGName, a4.User_id as ID, 
	 Case TipoUser_id when 1 then ''A'' when 2 then ''S'' when 6 then ''S'' end as TypeLoad 
	from ccRIACat_WorkGroup a1 join ccRIAAreaWorkGroup a2 on a1.IDWG = a2.IDWG
	 join ccRIAWorkGroupUsers a3 on a1.IDWG = a3.IDWG
	 join ccUsers a4 on a3.User_id = a4.User_id
	UNION
	-- Campañas/acds
	select a2.IDArea,a1.IDWG, a1.WGName, a3.IdCampEsp as ID, 
	 Case Tipo when 0 then ''I'' when 1 then ''C'' end as TypeLoad 
	from ccRIACat_WorkGroup a1
	 join ccRIAAreaWorkGroup a2 on a1.IDWG = a2.IDWG
	 join ccRIACampEspWG a3 on a1.IDWG = a3.IDWG
	Order By 1,2,5,4
	return(0)
 end

if @option = 2 -- WG de un Area
 begin
	-- Agentes y Supervisores
	select a2.IDArea,a1.IDWG, a1.WGName, a4.User_id as ID, 
	 Case TipoUser_id when 1 then ''A'' when 2 then ''S'' when 6 then ''S'' end as TypeLoad 
	from ccRIACat_WorkGroup a1 join ccRIAAreaWorkGroup a2 on a1.IDWG = a2.IDWG
	 join ccRIAWorkGroupUsers a3 on a1.IDWG = a3.IDWG
	 join ccUsers a4 on (a3.User_id = a4.User_id)
	where a2.IDArea = @AreaId
	UNION
	-- Campañas
	select a2.IDArea,a1.IDWG, a1.WGName, a3.IdCampEsp as ID, 
	 Case Tipo when 0 then ''I'' when 1 then ''C'' end as TypeLoad 
	from ccRIACat_WorkGroup a1 join ccRIAAreaWorkGroup a2 on a1.IDWG = a2.IDWG
	  join ccRIACampEspWG a3 on a1.IDWG = a3.IDWG
	where a2.IDArea = @AreaId
	Order By 1,2,5,4
	return(0)
 end

if @option = 3 -- WG por Supervisor
 begin
	-- Agentes y Supervisores
	select distinct a2.IDArea,a1.IDWG, a1.WGName, a4.User_id as ID, 
	 Case TipoUser_id when 1 then ''A'' when 2 then ''S'' when 6 then ''S'' end as TypeLoad 
	from ccRIACat_WorkGroup a1 join ccRIAAreaWorkGroup a2 on a1.IDWG = a2.IDWG
	 join ccRIAWorkGroupUsers a3 on a1.IDWG = a3.IDWG 
	 join ccUsers a4 on a3.User_id = a4.User_id
	 join ccRIAWorkGroupUsers a5 on a1.IDWG = a5.IDWG
	where a5.User_id = @sup
	UNION

-- Campañas y Especialidades
	select a2.IDArea,a1.IDWG, a1.WGName, a3.IdCampEsp as ID, 
	 Case Tipo when 0 then ''I'' when 1 then ''C'' end as TypeLoad 
	from ccRIACat_WorkGroup a1 join ccRIAAreaWorkGroup a2 on a1.IDWG = a2.IDWG
	 join ccRIACampEspWG a3 on a1.IDWG = a3.IDWG
	 join ccRIAWorkGroupUsers a4 on a1.IDWG = a4.IDWG
	where a4.User_id = @sup
	Order By 1,2,5,4
	return(0)
 end

If @option = 4 -- Datos Agents y Sups por WG de un area 
 begin
	select a.IDWG,a.WGName, isnull(d.TipoUser_id,'''') TipoUser_id, isnull(d.user_id,'''') user_id,
	 isnull(d.login,'''') login, isnull(d.TipoLlamadas,'''') TipoLlamadas, isnull(d.Nombres,'''') + '' '' + 
	 isnull(d.ApellidoPaterno,'''') + '' '' + isnull(d.ApellidoMaterno,'''') as nombre,
	 isnull(d.sexo,'''') sexo, dbo.fn_CampEspWG(a.IDWG,0) nAcd, dbo.fn_CampEspWG(a.IDWG,1) nCamp
	from ccRIACat_WorkGroup a 
	join ccRIAAreaWorkGroup b on b.IDWG = a.IDWG
	left join ccRIAWorkGroupUsers c on c.IDWG = a.IDWG
	left join ccUsers d on d.User_id = c.User_id 
	where b.IDArea = @AreaID
	order by a.WGName, a.IDWG,d.TipoUser_id, d.user_id
	return(0)
 end

If @option in (5, 7)
 begin
	Create table #WGPriority (IDWG smallint, WGName varchar(50), TipoUser_id int, 
	User_id smallint, login varchar(20), TipoLlamadas tinyint, nombre varchar(70), 
	sexo bit, prioridad tinyint, WGPriority tinyint, rel_id int null)
 
	if @InOut = 1
	 begin
		insert into #WGPriority (IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id)
		select distinct a.IDWG,d.WGName,c.TipoUser_id, b.User_id, c.login, c.TipoLlamadas, 
		 c.Nombres + '' '' + c.ApellidoPaterno + '' '' + c.ApellidoMaterno as nombre,
		 c.sexo, e.prioridad, a.priority as WGPriority, e.rel_id relation_id
		from ccRIACampEspWg a join ccRIAWorkGroupUsers b on a.IDWG = b.IDWG
		 join ccUsers c on b.User_id = c.User_id
		 join cccampsagente e on c.User_id = e.User_id and e.cam_id = @CamEspId and a.IDWG = e.IDWG
		 join ccRIACat_WorkGroup d on d.IDWG = a.IDWG 
		where a.IdCampEsp = @CamEspId and a.tipo = 1 and c.tipouser_id=1
		order by 1,2,3

		insert into #WGPriority (IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id)
		select distinct a.IDWG,d.WGName, 2, b.User_id, c.login, c.TipoLlamadas, 
		 c.Nombres + '' '' + c.ApellidoPaterno + '' '' + c.ApellidoMaterno as nombre,
		 c.sexo, 0, a.priority as WGPriority, 0
		from ccRIACampEspWg a join ccRIAWorkGroupUsers b on a.IDWG = b.IDWG
		 join ccUsers c on b.User_id = c.User_id
		 join ccsupervisorcam e on c.User_id = e.User_id and e.cam_id = @CamEspId and a.IDWG = e.IDWG 
		 join ccRIACat_WorkGroup d on d.IDWG = a.IDWG 
		where a.IdCampEsp = @CamEspId and a.tipo = 1 and c.tipouser_id in (2,6) and e.tipo=@InOut
		order by 1,2,3		
	 end

	else
	 begin
		insert into #WGPriority (IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority)
		select distinct a.IDWG,d.WGName,c.TipoUser_id, b.User_id, c.login, c.TipoLlamadas, 
		 c.Nombres + '' '' + c.ApellidoPaterno + '' '' + c.ApellidoMaterno as nombre,
		 c.sexo, e.prioridad, a.priority as WGPriority
		from ccRIACampEspWg a join ccRIAWorkGroupUsers b on a.IDWG = b.IDWG
		 join ccUsers c on b.User_id = c.User_id
		 join ccInboundAgentes e on c.User_id = e.User_id and e.Inbound_id = @CamEspId and a.IDWG = e.IDWG
		 join ccRIACat_WorkGroup d on d.IDWG = a.IDWG
		where a.IdCampEsp = @CamEspId and tipo = 0
		order by 1,2,3
		
		insert into #WGPriority (IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id)
		select distinct a.IDWG,d.WGName, 2, b.User_id, c.login, c.TipoLlamadas, 
		 c.Nombres + '' '' + c.ApellidoPaterno + '' '' + c.ApellidoMaterno as nombre,
		 c.sexo, 0, a.priority as WGPriority, 0
		from ccRIACampEspWg a join ccRIAWorkGroupUsers b on a.IDWG = b.IDWG
		 join ccUsers c on b.User_id = c.User_id
		 join ccsupervisorcam e on c.User_id = e.User_id and e.cam_id = @CamEspId and a.IDWG = e.IDWG 
		 join ccRIACat_WorkGroup d on d.IDWG = a.IDWG 
		where a.IdCampEsp = @CamEspId and a.tipo = 0 and c.tipouser_id in (2,6) and e.tipo=@InOut
		order by 1,2,3	
	 end

	update #WGPriority set WGPriority = 0 where IDWG in (select IDWG from (
	select IDWG, count(distinct prioridad) prioridad
	from #WGPriority group by IDWG, prioridad) as x group by IDWG, prioridad
	having count(prioridad) > 1)

	if @option = 5
	 begin
		select IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, 
		nombre, sexo, prioridad, WGPriority, min(rel_id) relational_id
		from 
			(select IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, 

			nombre, sexo, prioridad, WGPriority, rel_id
			from #WGPriority) as WGPriority
		group by IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, 
		nombre, sexo, prioridad, WGPriority
	end

	if @option = 7
	 begin
		select 1 as tag, null parent, 0 "WorkGroup!1!TipoUser_id", IDWG "WorkGroup!1!id", WGName "WorkGroup!1!description", WGPriority "WorkGroup!1!priority",
		null "Agent!3!id", null "Agent!3!login", null "Agent!3!callType", null "Agent!3!name", null "Agent!3!gender", null "Agent!3!priority", null "Agent!3!relational_id",
		null "Supervisor!2!id", null "Supervisor!2!login", null "Supervisor!2!callType", null "Supervisor!2!name", null "Supervisor!2!gender", null "Supervisor!2!priority", null "Supervisor!2!relational_id"
		from (select IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id
		from #WGPriority) as WGPriority group by IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority
			union	
		select 2 as tag, 1 parent,TipoUser_id, IDWG, null, null, null, null, null, null, null, null, null, User_id, login, TipoLlamadas, nombre, sexo, prioridad, min(rel_id) relational_id
		from (select IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id
		from #WGPriority where TipoUser_id = 2) as WGPriority group by IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority
			union
		select 3 as tag, 1 parent, TipoUser_id, IDWG, null, null, User_id, login, TipoLlamadas, nombre, sexo, prioridad, min(rel_id) relational_id, null, null, null, null, null, null, null
		from (select IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id
		from #WGPriority where TipoUser_id = 1) as WGPriority group by IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority
			order by "WorkGroup!1!id", tag, "WorkGroup!1!TipoUser_id" desc, "Supervisor!2!name", "Agent!3!name"
			
		for xml explicit, type
	end

	return(0)
 end
  
If @option = 6
 begin
	--if @AreaId = 0
	--set @AreaId = null
	select W.Tipo, I.Inbound_id IdCampEsp, I.descripcion
	from ccInbound I join ccRIACampEspWG W on I.Inbound_id = W.IdCampEsp
	and W.IDWG = isnull(@AreaId, W.IDWG) and W.Tipo = 0
	union
	select W.Tipo, C.cam_id, C.cam_descripcion
	from ccCamps C join ccRIACampEspWG W on C.cam_id = W.IdCampEsp
	and W.IDWG = isnull(@AreaId, W.IDWG) and W.Tipo = 1
	order by W.Tipo desc, 2
	return(0)
 end

if @option=8
 begin
	SELECT isnull(viewMode.typeView,0) typeView FROM ccMenu_Views as viewMode
	join ccMenu_Views as [view] on viewMode.mView_id = [view].mView_id
	where viewMode.status=1 and [view].menu_id = 4
	and (case when viewMode.typeView = dbo.fn_viewMode (@Sup, [view].menu_id) then 1 else 0 end) = 1
	return(0)
 end

if @option=9
begin
declare @assignACDCamp as tinyint
select @assignACDCamp = isnull(per_id,0) FROM ccRIAUsr_AdminPermissions WHERE per_id = 3 and user_id = @Sup

SELECT case when @assignACDCamp > 0 then 1 else 0 end as granted
return(0)
end

return(0)
set nocount off'

		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentNotReadyDetail] @user_id as int = 0, @sup_id as int = 0, @action as int = 0 as

set nocount on

declare @fecha_ini datetime
declare @fecha_fin datetime

select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))
select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))

create table #cctiponotready(
user_id int not null,
tiponotready_id int not null,
tstatus int not null,
Descripcion varchar(255) not null,
time_acum int not null,
Time_xEv int not null
)

create table #ccsp_RIAGetRelsSupsAgent(
agt int not null,
sup int not null,
login varchar(50)
)

if @action = 1
   begin

		insert #ccsp_RIAGetRelsSupsAgent
		exec ccsp_RIAGetRelsSupsAgent

		delete #ccsp_RIAGetRelsSupsAgent
		where sup <> @sup_id

        SELECT a.user_id,a.TipoNotReady_id,isnull(sum(tStatus),0) as ''time'',a.descripcion,a.Time_Acum,a.Time_xEV
		FROM
		(SELECT user_id,login,TipoNotReady_id,descripcion,Time_Acum,Time_xEV
		FROM cctiponotready,ccusers
        WHERE  user_id IN (SELECT agt FROM #ccsp_RIAGetRelsSupsAgent)) a
		LEFT JOIN 
		(SELECT user_id,TipoNotReady_id,tStatus FROM ccLogAgentesNotReady
        WHERE CONVERT(datetime,CONVERT(varchar(11),fecha)) between @fecha_ini and @fecha_fin)  b 
		ON a.user_id = b.user_id AND a.TipoNotReady_id = b.TipoNotReady_id        
		GROUP BY a.user_id,a.TipoNotReady_id,a.descripcion,a.Time_Acum,a.Time_xEV		
   end

else if @user_id = 0 and @sup_id > 0
	begin
		insert #ccsp_RIAGetRelsSupsAgent
		exec ccsp_RIAGetRelsSupsAgent

		delete #ccsp_RIAGetRelsSupsAgent
		where sup <> @sup_id
		        
        SELECT DISTINCT a.user_id, 1 AS ''type'', c.login
        from ccLogAgentesNotReady a,cctiponotready b, ccusers c
        WHERE  a.user_id IN (SELECT agt FROM #ccsp_RIAGetRelsSupsAgent) 
		AND a.TipoNotReady_id = b.TipoNotReady_id 
		AND b.Time_xEv <> 0 AND a.tStatus > b.Time_xEv
		and a.fecha between @fecha_ini and @fecha_fin
		and a.user_id = c.user_id

        UNION
       
        SELECT DISTINCT a.user_id, 2 AS ''type'', c.login
        from ccLogAgentesNotReady a,cctiponotready b, ccusers c
        WHERE a.user_id IN (SELECT agt FROM #ccsp_RIAGetRelsSupsAgent) 
		AND a.TipoNotReady_id = b.TipoNotReady_id 
		AND b.Time_Acum <> 0 
		and a.fecha between @fecha_ini and @fecha_fin
		and a.user_id = c.user_id
        GROUP BY a.user_id, a.TipoNotReady_id,b.Time_Acum, c.login
        HAVING sum(a.tStatus) > b.Time_Acum

		UNION
		
		SELECT a.agt, 0 AS ''type'', b.login
		FROM #ccsp_RIAGetRelsSupsAgent a, ccusers b
		where a.agt = b.user_id

	end

else if @user_id > 0 and @sup_id = 0
	begin
		insert into #cctiponotready
		select a.user_id, a.tiponotready_id, a.tstatus, b.descripcion, b.time_acum, b.time_xev
		from ccLogAgentesNotReady a, cctiponotready b
		where user_id = @user_id
		and fecha between @fecha_ini and @fecha_fin
		and a.tiponotready_id = b.tiponotready_id

		insert into #cctiponotready
		select @user_id, tiponotready_id, 0, descripcion, time_acum, time_xev
		from ccTipoNotReady
		where tiponotready_id not in (select tiponotready_id from #cctiponotready)
		and issup = 0

		select *
		from #cctiponotready
end

set nocount on'

		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory]
@action smallint,
@call_id int = 0,
@startDate varchar(20) = null,
@endDate varchar(20) = null
AS 

-- INBOUND x cal_id
if @action = 1
 begin
	select top 500 cal_id as call_id,a.inbound_id,a.descripcion as acdGroup,cal_ani as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,'''') as login,
	isnull(e.description,'''') as disposition,d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date from cccallsin c with(nolock)
	left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
	left join ccusers b on (c.user_id = b.user_id) 
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalif e on ( c.calif_id = e.calif_id )
	where cal_id >= @call_id
 end

-- OUTBOUND x cal_id
if @action = 2 
 begin
	select top 500 cal_id as call_id,a.cam_id,a.cam_descripcion as Campaign,cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
	d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date from ccocallsout c with(nolock)
	left join ccusers b on (c.user_id = b.user_id) 
	left join cccamps a on (c.cam_id = a.cam_id)
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
	where cal_id >= @call_id
 end

if @action = 3 --Session time
	begin
		declare @fecha_ini datetime
		declare @fecha_fin datetime	

		if (@startDate is null or @endDate is null) or (@startDate = '''' or @endDate = '''') begin
			select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))
			select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))	
		end
		else begin
			select @fecha_ini = convert(datetime,convert(varchar(11),@startDate))
			select @fecha_fin = convert(datetime,convert(varchar(11),@endDate))
		end

		select uid, min(login) as login,max(logout) as logout,logintime as logintime from(
		SELECT uid, max(ext) ext, login, isnull(max(logout),getdate()) logout, 
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
		>= dateadd( dd, -5, @fecha_ini)) Det   ) LoginDetail -- WHERE logout IS NULL 
		where login >= @fecha_ini and login < @fecha_fin 
		GROUP BY uid, login) as a group by uid, logintime order by 1,2
		
	end'

		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer
AS

--declare @telephone as varchar(30), @ln_id as integer
--select @telephone=''5511078530'', @ln_id = 1
--set nocount
declare @ld varchar(4), @tel as varchar(30)

insert into cclistanegra values(@telephone, @ln_id)

CREATE TABLE [dbo].[#mycamps] (
	[campsid] [int] NULL )

insert #mycamps
select cam_id from Camplistanegra where idtipolista = @ln_id

CREATE TABLE [dbo].[#mytemp] (
	[callout_id] [int] NULL, 
        [telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
        [idtipolista] [int] NULL)

CREATE  UNIQUE  INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) 

select @ld = valor from ccSettings where setting_id = 17
select @tel = dbo.completa(@telephone)

-----------------------------------------------------------------------------  telefono1
insert #mytemp
select callout_id,cal_telefono,cam_id,''3'',@ln_id as idtipolista from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono = @tel and cal_fechadial >  getdate()-30

-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
delete ccoWOrkingTable from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30 and cs.cal_telefono= wt.cal_telefono and  rtrim(left(ltrim(            cs.cal_telefono2 + ''         ''
							 + cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono = 
rtrim(left(ltrim(            cs.cal_telefono2 + ''         ''
							 + cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs 
inner join ccoWorkingTable wt
on cs.callout_id = wt.callout_id
inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30 and cs.cal_telefono= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono1 de CS
update ccoCallsOutSource set cal_telefono = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 2

insert #mytemp
select callout_id,cal_telefono2,cam_id,''3'',@ln_id as idtipolista from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono2 = @tel and cal_fechadial >  getdate()-30

-- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
delete ccoWOrkingTable from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30 and cs.cal_telefono2= wt.cal_telefono and rtrim(left(ltrim(            cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono = 
rtrim(left(ltrim(            cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs 
inner join ccoWorkingTable wt
on cs.callout_id = wt.callout_id
inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30 and cs.cal_telefono2= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp


-- Eliminamos el telefono2 de CS
update ccoCallsOutSource set cal_telefono2 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 3

insert #mytemp
select callout_id,cal_telefono3,cam_id,''3'',@ln_id as idtipolista from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono3 = @tel and cal_fechadial >  getdate()-30

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30 and cs.cal_telefono3= wt.cal_telefono  and  rtrim(left(ltrim(            cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono = 
rtrim(left(ltrim(             cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs 
inner join ccoWorkingTable wt
on cs.callout_id = wt.callout_id
inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30 and cs.cal_telefono3= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono3 de CS
update ccoCallsOutSource set cal_telefono3 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 4

insert #mytemp
select callout_id,cal_telefono4,cam_id,''3'',@ln_id as idtipolista from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono4 = @tel and cal_fechadial >  getdate()-30

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30 and cs.cal_telefono4= wt.cal_telefono and  rtrim(left(ltrim(            cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono = 
rtrim(left(ltrim(            cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs 
inner join ccoWorkingTable wt
on cs.callout_id = wt.callout_id
inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30 and cs.cal_telefono4= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp


-- Eliminamos el telefono4 de CS
update ccoCallsOutSource set cal_telefono4 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 5

insert #mytemp
select callout_id,cal_telefono5,cam_id,''3'',@ln_id as idtipolista from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono5 = @tel and cal_fechadial >  getdate()-30

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30 and cs.cal_telefono5= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono5 de CS
update ccoCallsOutSource set cal_telefono5 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > getdate()-30

truncate table #mytemp
truncate table #mycamps

drop table #mytemp
drop table [dbo].[#mycamps]'

		EXEC(@Sql)
		
			set @Sql = 'Create Procedure [dbo].[ccsp_ADMCalifInformation]
@user_id as int,
@type as int
as
if @type = 1
begin
	declare @fecha_ini datetime, @fecha_fin datetime
    declare @hours as BIGINT
    SET @hours = 0 
	--0 in, 1 out
	select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))
	select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))

	(select calif.calif_id, description, 
	case when timegroup is null then convert(smalldatetime,convert(varchar(10),getdate(),121),121) else timegroup end timegroup,
	case when user_id is null then @user_id else user_id end [user_id],
	case when llamadas is null then 0 else llamadas end [llamadas], @hours as hours, 1 as type
	  from (select calif_id, description from cctipocalifout where califout_status = 1) calif
	left join (SELECT convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) AS timegroup, [user_id], calif_id, COUNT(*) llamadas
	FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2)) WHERE cal_inicio >= convert(smalldatetime,convert(varchar(10),getdate(),121),121) AND statuscall_id = 13 and user_id = @user_id and calif_id > 0
	 GROUP BY convert(smalldatetime,convert(varchar(10),cal_inicio,121),121), [user_id], calif_id 
	) data
	on (calif.calif_id = data.calif_id))
	union all
	(select calif.calif_id, description, 
	case when timegroup is null then convert(smalldatetime,convert(varchar(10),getdate(),121),121) else timegroup end timegroup,
	case when user_id is null then @user_id else user_id end [user_id],
	case when llamadas is null then 0 else llamadas end [llamadas], @hours as hours, 0 as type
	  from (select calif_id, description from cctipocalif where calif_status = 1) calif
	left join (SELECT convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) AS timegroup, [user_id], calif_id, COUNT(*) llamadas
	FROM cccallsin with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio >= convert(smalldatetime,convert(varchar(10),getdate(),121),121) AND statuscall_id = 13 and user_id = @user_id and calif_id > 0
	 GROUP BY convert(smalldatetime,convert(varchar(10),cal_inicio,121),121), [user_id], calif_id 
	) data
	on (calif.calif_id = data.calif_id))
end

if @type = 2
begin
	select calif_id, description, 0 type from cctipocalif where calif_status = 1
	union all
	select calif_id, description,1 type from cctipocalifout where califout_status = 1
end'
		
		EXEC(@Sql)
		
			set @Sql = 'ALTER procedure [dbo].[ccsp_RIAcalifblacklist]
@Qualif_id int = null,
@BlackListIds_Insert varchar(1500) = ''0'',
@BlackListIds_Delete varchar(1500) = ''0'',
@Type tinyint = 0,
@tipoCampACD bit = 1
as
set nocount on

if @Type = 0 -- Catalogo de Calificaciones
 begin
	if @tipoCampACD=1
	 begin
		select calif_id, Description from cctipocalifout where CalifOut_Status = 1
		return(0)
	 end
	
	select calif_id, Description from cctipocalif where Calif_Status = 1
	return(0)
 end

if @Type = 1 -- Muestra listas negras asignadas por calificacion
 begin
	select b.idtipolista, b.Tipolista 
	from cccalifblacklist a with(index(IX_cccalifblacklist)) join ccTiposListaNegra b on a.idtipolista = b.idtipolista
	where a.tipo = @tipoCampACD and a.calif_id = @Qualif_id
	group by b.idtipolista, b.Tipolista
	return(0)
 end

if @Type = 2 -- Inserta BlackList por calificacion / Elimina BlackList por calificacion
 begin
	if LEN(@BlackListIds_Insert)>0
		insert into cccalifblacklist
		select @Qualif_id calif_id, Value Tipolista, 1 from dbo.fn_RIASplitDelimited (@BlackListIds_Insert, '','') 
		where cast(@Qualif_id as varchar(10)) + ''/'' + cast(Value as varchar(10)) not in
		(select cast(calif_id as varchar(10)) + ''/'' + cast(idTipoLista as varchar(10)) from cccalifblacklist with(index(IX_cccalifblacklist)))

	if LEN(@BlackListIds_Delete)>0
		delete cccalifblacklist where tipo = 1 and cast(calif_id as varchar(10)) + ''/'' + cast(idTipoLista as varchar(10)) in 
		(select cast(@Qualif_id as varchar(10)) + ''/'' + cast(Value as varchar(10)) from dbo.fn_RIASplitDelimited (@BlackListIds_Delete, '',''))

	return(0)
 end

set nocount off'
		
		EXEC(@Sql)
		
			set @Sql = 'delete from ccRIALog_Cat_Relation where module_id <> 3

insert into  ccRIALog_Cat_Relation values(1,5)--5
insert into  ccRIALog_Cat_Relation values(2,1)--1,2,16,17,22,25,26,70
insert into  ccRIALog_Cat_Relation values(2,2)
insert into  ccRIALog_Cat_Relation values(2,16)
insert into  ccRIALog_Cat_Relation values(2,17)
insert into  ccRIALog_Cat_Relation values(2,22)
insert into  ccRIALog_Cat_Relation values(2,25)
insert into  ccRIALog_Cat_Relation values(2,26)
insert into  ccRIALog_Cat_Relation values(2,70)
insert into  ccRIALog_Cat_Relation values(4,24)--24
insert into  ccRIALog_Cat_Relation values(5,1)--1,2,3
insert into  ccRIALog_Cat_Relation values(5,2)
insert into  ccRIALog_Cat_Relation values(5,3)
insert into  ccRIALog_Cat_Relation values(6,89)--89,90,99
insert into  ccRIALog_Cat_Relation values(6,90)
insert into  ccRIALog_Cat_Relation values(6,99)
insert into  ccRIALog_Cat_Relation values(7,30)--30,31,3
insert into  ccRIALog_Cat_Relation values(7,31)
insert into  ccRIALog_Cat_Relation values(7,3)
insert into  ccRIALog_Cat_Relation values(8,44)--44,45,46
insert into  ccRIALog_Cat_Relation values(8,45)
insert into  ccRIALog_Cat_Relation values(8,46)
insert into  ccRIALog_Cat_Relation values(9,109)--109
insert into  ccRIALog_Cat_Relation values(10,1)--1,2,3,37,38,
insert into  ccRIALog_Cat_Relation values(10,2)
insert into  ccRIALog_Cat_Relation values(10,3)
insert into  ccRIALog_Cat_Relation values(10,37)
insert into  ccRIALog_Cat_Relation values(10,38)
insert into  ccRIALog_Cat_Relation values(11,47)--47,48,68,69,145,146,147
insert into  ccRIALog_Cat_Relation values(11,48)
insert into  ccRIALog_Cat_Relation values(11,68)
insert into  ccRIALog_Cat_Relation values(11,69)
insert into  ccRIALog_Cat_Relation values(11,145)
insert into  ccRIALog_Cat_Relation values(11,146)
insert into  ccRIALog_Cat_Relation values(11,147)
insert into  ccRIALog_Cat_Relation values(12,49)--49,50,101,112,115,116,120
insert into  ccRIALog_Cat_Relation values(12,50)
insert into  ccRIALog_Cat_Relation values(12,101)
insert into  ccRIALog_Cat_Relation values(12,112)
insert into  ccRIALog_Cat_Relation values(12,115)
insert into  ccRIALog_Cat_Relation values(12,116)
insert into  ccRIALog_Cat_Relation values(12,120)
insert into  ccRIALog_Cat_Relation values(13,30)--30,31,3
insert into  ccRIALog_Cat_Relation values(13,31)
insert into  ccRIALog_Cat_Relation values(13,3)
insert into  ccRIALog_Cat_Relation values(14,43)--3,42,43
insert into  ccRIALog_Cat_Relation values(14,42)
insert into  ccRIALog_Cat_Relation values(14,3)
insert into  ccRIALog_Cat_Relation values(15,39)--39,40,124,125,126
insert into  ccRIALog_Cat_Relation values(15,40)
insert into  ccRIALog_Cat_Relation values(15,124)
insert into  ccRIALog_Cat_Relation values(15,125)
insert into  ccRIALog_Cat_Relation values(15,126)
insert into  ccRIALog_Cat_Relation values(16,47)--47,48,68,69,145,146
insert into  ccRIALog_Cat_Relation values(16,48)
insert into  ccRIALog_Cat_Relation values(16,68)
insert into  ccRIALog_Cat_Relation values(16,69)
insert into  ccRIALog_Cat_Relation values(16,145)
insert into  ccRIALog_Cat_Relation values(16,146)
insert into  ccRIALog_Cat_Relation values(17,1)--1,2,3
insert into  ccRIALog_Cat_Relation values(17,2)
insert into  ccRIALog_Cat_Relation values(17,3)
insert into  ccRIALog_Cat_Relation values(18,1)--1,2,3
insert into  ccRIALog_Cat_Relation values(18,2)
insert into  ccRIALog_Cat_Relation values(18,3)
insert into  ccRIALog_Cat_Relation values(19,149)--149
insert into  ccRIALog_Cat_Relation values(20,32)--32,33
insert into  ccRIALog_Cat_Relation values(20,33)
insert into  ccRIALog_Cat_Relation values(21,29)--29,41
insert into  ccRIALog_Cat_Relation values(21,41)
insert into  ccRIALog_Cat_Relation values(22,29) --29
insert into  ccRIALog_Cat_Relation values(23,1)--1,2,3
insert into  ccRIALog_Cat_Relation values(23,2)
insert into  ccRIALog_Cat_Relation values(23,3)
insert into  ccRIALog_Cat_Relation values(24,37) --3,37,38
insert into  ccRIALog_Cat_Relation values(24,38)
insert into  ccRIALog_Cat_Relation values(24,3)
insert into  ccRIALog_Cat_Relation values(25,1)--1,2,3
insert into  ccRIALog_Cat_Relation values(25,2)
insert into  ccRIALog_Cat_Relation values(25,3)
insert into  ccRIALog_Cat_Relation values(27,1) --1,2,3
insert into  ccRIALog_Cat_Relation values(27,2)
insert into  ccRIALog_Cat_Relation values(27,3)
insert into  ccRIALog_Cat_Relation values(28,133) --133,134
insert into  ccRIALog_Cat_Relation values(28,134)
insert into  ccRIALog_Cat_Relation values(29,1)--1,2,3
insert into  ccRIALog_Cat_Relation values(29,2)
insert into  ccRIALog_Cat_Relation values(29,3)
insert into  ccRIALog_Cat_Relation values(30,33) --33,35
insert into  ccRIALog_Cat_Relation values(30,35)
insert into  ccRIALog_Cat_Relation values(31,18)--18,19
insert into  ccRIALog_Cat_Relation values(31,19)
insert into  ccRIALog_Cat_Relation values(32,128)--128,129
insert into  ccRIALog_Cat_Relation values(32,129)
insert into  ccRIALog_Cat_Relation values(33,1) --1,2
insert into  ccRIALog_Cat_Relation values(33,2)
insert into  ccRIALog_Cat_Relation values(34,42)--42,43
insert into  ccRIALog_Cat_Relation values(34,43)
insert into  ccRIALog_Cat_Relation values(35,63)--63,64,65
insert into  ccRIALog_Cat_Relation values(35,64)
insert into  ccRIALog_Cat_Relation values(35,65)
insert into  ccRIALog_Cat_Relation values(36,137)--137,138,139,140,141,142
insert into  ccRIALog_Cat_Relation values(36,138)
insert into  ccRIALog_Cat_Relation values(36,139)
insert into  ccRIALog_Cat_Relation values(36,140)
insert into  ccRIALog_Cat_Relation values(36,141)
insert into  ccRIALog_Cat_Relation values(36,142)
insert into  ccRIALog_Cat_Relation values(37,130) --130
insert into  ccRIALog_Cat_Relation values(38,105) --105
insert into  ccRIALog_Cat_Relation values(39,3) --3
insert into  ccRIALog_Cat_Relation values(40,135) --135,136
insert into  ccRIALog_Cat_Relation values(40,136)
insert into  ccRIALog_Cat_Relation values(41,108) --133,134
insert into  ccRIALog_Cat_Relation values(41,109)
insert into  ccRIALog_Cat_Relation values(41,110)
insert into  ccRIALog_Cat_Relation values(41,111)
insert into  ccRIALog_Cat_Relation values(42,6) --6
insert into  ccRIALog_Cat_Relation values(43,71)--71,72
insert into  ccRIALog_Cat_Relation values(43,72)
insert into  ccRIALog_Cat_Relation values(44,150) --150
insert into  ccRIALog_Cat_Relation values(46,22)--1,22,3,20
insert into  ccRIALog_Cat_Relation values(46,3)
insert into  ccRIALog_Cat_Relation values(46,20)
insert into  ccRIALog_Cat_Relation values(47,7)--7,8,9,10,11,12,13,14,15
insert into  ccRIALog_Cat_Relation values(47,8)
insert into  ccRIALog_Cat_Relation values(47,9)
insert into  ccRIALog_Cat_Relation values(47,10)
insert into  ccRIALog_Cat_Relation values(47,11)
insert into  ccRIALog_Cat_Relation values(47,12)
insert into  ccRIALog_Cat_Relation values(47,13)
insert into  ccRIALog_Cat_Relation values(47,14)
insert into  ccRIALog_Cat_Relation values(47,15)
insert into  ccRIALog_Cat_Relation values(48,21) --21,23
insert into  ccRIALog_Cat_Relation values(48,23) 
insert into  ccRIALog_Cat_Relation values(49,1) --1,20,21,22,23,25,26,27,28
insert into  ccRIALog_Cat_Relation values(49,20)
insert into  ccRIALog_Cat_Relation values(49,21)
insert into  ccRIALog_Cat_Relation values(49,22)
insert into  ccRIALog_Cat_Relation values(49,23)
insert into  ccRIALog_Cat_Relation values(49,25)
insert into  ccRIALog_Cat_Relation values(49,26)
insert into  ccRIALog_Cat_Relation values(49,27)
insert into  ccRIALog_Cat_Relation values(49,28)
insert into  ccRIALog_Cat_Relation values(50,145)--145,146,147,69,68
insert into  ccRIALog_Cat_Relation values(50,146)
insert into  ccRIALog_Cat_Relation values(50,147)
insert into  ccRIALog_Cat_Relation values(50,69)
insert into  ccRIALog_Cat_Relation values(50,68)
insert into  ccRIALog_Cat_Relation values(51,145)--145,146,147,69,68
insert into  ccRIALog_Cat_Relation values(51,146)
insert into  ccRIALog_Cat_Relation values(51,147)
insert into  ccRIALog_Cat_Relation values(51,69)
insert into  ccRIALog_Cat_Relation values(51,68)
insert into  ccRIALog_Cat_Relation values(52,30)--30,31,104
insert into  ccRIALog_Cat_Relation values(52,31)
insert into  ccRIALog_Cat_Relation values(52,104)'
		
		EXEC(@Sql)
		
			set @Sql = 'delete from ccRIALog_Module where module_id = 45 --Grupos ACD
delete from ccRIALog_Module where module_id = 26 --Monitoreo de llamada'
		
		EXEC(@Sql)
		
			set @Sql = 'insert into ccRIALog_Operation values(148,''Lista Negra SCRUB|DNC SCRUB'')
insert into ccRIALog_Operation values(149,''Ver Historial de listas negras|View DNC'')
insert into ccRIALog_Operation values(150,''Actualiza Prioridad de camapañas|Update Campaign priority'')
insert into ccRIALog_Operation values(150,''Actualiza prioridad|UpdateAgentPrioriry'')'
		
		EXEC(@Sql)
		
			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters] @type as int, @sup_id as int = 0 as

set nocount on

declare @fecha_ini datetime
declare @fecha_fin datetime

select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))
select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))

create table #ccsp_RIAGetRelsSupsAgent(
agt int not null,
sup int not null,
login varchar(50)
)

insert #ccsp_RIAGetRelsSupsAgent
exec ccsp_RIAGetRelsSupsAgent

delete #ccsp_RIAGetRelsSupsAgent
where sup <> @sup_id

if @type = 1 --Session time
	begin

		SELECT uid, max(ext) ext, login, isnull(max(logout),getdate()) logout, 
		datediff(s,login,isnull(max(logout),getdate())) loginTime
		into #LoginTime
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
		>= dateadd( dd, -5, @fecha_ini)) Det   ) LoginDetail -- WHERE logout IS NULL 
		where login >= @fecha_ini and login < @fecha_fin 
		GROUP BY uid, login

		select uid as User_id, sum(loginTime) as loginTime
		from #LoginTime 
		where uid IN (SELECT AGT FROM #ccsp_RIAGetRelsSupsAgent)
		group by uid

		drop table #LoginTime
	end

if @type = 2 --Status agent
	begin
		SELECT User_id, TipoStatusAge_id, sum(tStatus) As segundos 
		FROM ccLogAgentesDia
		WHERE CONVERT(datetime,CONVERT(varchar(11),fecha)) = CONVERT(datetime,CONVERT(varchar(11),GETDATE())) 
		AND User_id IN (SELECT AGT FROM #ccsp_RIAGetRelsSupsAgent)
		GROUP BY User_id, TipoStatusAge_id 
		ORDER BY User_id
	end

if @type = 3
	begin
		create table #totalCalls(
		user_id int not null,
		total_calls int not null,
		type_calls int not null)

		create table #NACalls(
		user_id int not null,
		total_calls int not null,
		type_calls int not null)

		insert into #totalCalls
		SELECT User_id , count(*), 1
		FROM ccCallsIn
        WHERE User_id IN (SELECT AGT FROM #ccsp_RIAGetRelsSupsAgent)
		and cal_inicio BETWEEN CONVERT(datetime,CONVERT(varchar(11),GETDATE())+'' 00:00'') AND CONVERT(datetime,CONVERT(varchar(11),GETDATE())+'' 23:59'') 
		and statuscall_id not in (11,15)
		GROUP BY User_id

		insert into #totalCalls
		SELECT User_id , count(*), 2
		FROM ccoCallsOut
		WHERE User_id IN (SELECT AGT FROM #ccsp_RIAGetRelsSupsAgent)
		AND cal_inicio BETWEEN CONVERT(datetime,CONVERT(varchar(11),GETDATE())+'' 00:00'') AND CONVERT(datetime,CONVERT(varchar(11),GETDATE())+'' 23:59'') 
		and statuscall_id not in (11,15)
		GROUP BY User_id


        --Add manual calls 
        insert into #totalCalls
		SELECT User_id , count(*), 3
		FROM ccoCallsOut
		WHERE User_id IN (SELECT AGT FROM #ccsp_RIAGetRelsSupsAgent)
		AND cal_inicio BETWEEN CONVERT(datetime,CONVERT(varchar(11),GETDATE())+'' 00:00'') AND CONVERT(datetime,CONVERT(varchar(11),GETDATE())+'' 23:59'') 
		and cal_manual = 2
		GROUP BY User_id        

        --Outbound no answer
		insert into #totalCalls
		SELECT User_id , count(*), 4
		FROM ccCallsIn
        WHERE User_id IN (SELECT AGT FROM #ccsp_RIAGetRelsSupsAgent)
		and cal_inicio BETWEEN CONVERT(datetime,CONVERT(varchar(11),GETDATE())+'' 00:00'') AND CONVERT(datetime,CONVERT(varchar(11),GETDATE())+'' 23:59'') 
		and statuscall_id in (11,15)
		GROUP BY User_id

        --Inbound no answer
		insert into #totalCalls
		SELECT User_id , count(*), 5
		FROM ccoCallsOut
		WHERE User_id IN (SELECT AGT FROM #ccsp_RIAGetRelsSupsAgent)
		AND cal_inicio BETWEEN CONVERT(datetime,CONVERT(varchar(11),GETDATE())+'' 00:00'') AND CONVERT(datetime,CONVERT(varchar(11),GETDATE())+'' 23:59'') 
		and statuscall_id in (11,15)
		GROUP BY User_id
	
		select a.*, b.login
		from #totalCalls a, ccusers b
		where a.user_id = b.user_id	
	end

if @type = 4
	begin
        select user_id, login 
        from ccusers
		where user_id in (SELECT AGT FROM #ccsp_RIAGetRelsSupsAgent)
    end

set nocount on'
		
		EXEC(@Sql)

			set @Sql = 'CREATE PROCEDURE [dbo].[ccsp_GetConversionFactor]
	@userId int = 0 ,
    @califId int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --Clean temp tables--

	IF OBJECT_ID(''tempdb..#LoginTime'') IS NOT NULL 
	BEGIN
	  DROP TABLE #LoginTime
	END

	IF OBJECT_ID(''tempdb..#LoginTimeAgent'') IS NOT NULL 
	BEGIN
	  DROP TABLE #LoginTimeAgent
	END

	IF OBJECT_ID(''tempdb..#totalCalls'') IS NOT NULL 
	BEGIN
	  DROP TABLE #totalCalls
	END

	--Clean temp tables--

	--Create time ranges--

	declare @fecha_ini datetime
	declare @fecha_fin datetime
	select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))
	select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))

	--Create time ranges--

	--Create flags for searches--

	declare @agentFlag bit 
	IF @userId < 1
	  BEGIN
		--Select all agents
		SET @agentFlag = 1
	  END
	ELSE
	  BEGIN
		--Find agent specified in param @userId
		SET @agentFlag = 0
	  END

	declare @califFlag bit
	IF @califId < 1
	  BEGIN
		--Select all califications
		SET @califFlag = 1
	  END
	ELSE
	  BEGIN
		--Find specified calification in param @califId
		SET @califFlag = 0
	  END

	--Create flags for searches--

	--Get login times of the current day for all agents--

	SELECT uid, max(ext) ext, login, isnull(max(logout),getdate()) logout, 
	datediff(s,login,isnull(max(logout),getdate())) loginTime
	into #LoginTime
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
	>= dateadd( dd, -5, @fecha_ini)) Det   ) LoginDetail 
	where login >= @fecha_ini and login < @fecha_fin 
	GROUP BY uid, login

	SELECT uid,sum(loginTime) AS ''time_secs''
	INTO #LoginTimeAgent 
	FROM #LoginTime    
	group by uid    

	--Get login times for the day of all agents--

	--Get total calls for the day of all agents--

	create table #totalCalls(
	user_id int not null,
	total_calls int not null		
	)

	insert into #totalCalls
	SELECT User_id , count(*)
	FROM ccCallsIn
	WHERE  (@agentFlag=1 OR user_id = @userId) 
	and cal_inicio BETWEEN @fecha_ini AND @fecha_fin		
	GROUP BY User_id

	insert into #totalCalls
	SELECT User_id , count(*)
	FROM ccoCallsOut
	WHERE  (@agentFlag=1 OR user_id = @userId) 
	AND cal_inicio BETWEEN @fecha_ini AND @fecha_fin		
	GROUP BY User_id

	--Get total calls for the day of all agents--
	        	    
	SELECT R.user_id As ''userId'',U.login,R.calif_id As ''califId'',R.description,R.llamadas AS ''calls'',CASE WHEN T.time_secs <1 THEN 1 ELSE T.time_secs END As ''time_secs'', TC.total_calls As ''totalCalls'' FROM
		((select calif.calif_id, description, 
		case when timegroup is null then convert(smalldatetime,convert(varchar(10),getdate(),121),121) else timegroup end timegroup,
		case when user_id is null then 0 else user_id end [user_id],
		case when llamadas is null then 0 else llamadas end [llamadas], 1 as type
		  from (select calif_id, description from cctipocalifout where califout_status = 1 AND (@califFlag=1 OR calif_id = @califId)) calif
		  left join (SELECT convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) AS timegroup, [user_id], calif_id, COUNT(*) llamadas
		FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2)) WHERE cal_inicio >= convert(smalldatetime,convert(varchar(10),getdate(),121),121) AND statuscall_id = 13  and calif_id > 0 
		 AND (@agentFlag=1 OR user_id = @userId) 
		 GROUP BY convert(smalldatetime,convert(varchar(10),cal_inicio,121),121), [user_id], calif_id 
		) data
		on (calif.calif_id = data.calif_id))
		union all
		(select calif.calif_id, description, 
		case when timegroup is null then convert(smalldatetime,convert(varchar(10),getdate(),121),121) else timegroup end timegroup,
		case when user_id is null then 0 else user_id end [user_id],
		case when llamadas is null then 0 else llamadas end [llamadas], 0 as type
		  from (select calif_id, description from cctipocalif where calif_status = 1 AND (@califFlag=1 OR calif_id = @califId)) calif
		  left join (SELECT convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) AS timegroup, [user_id], calif_id, COUNT(*) llamadas
		FROM cccallsin with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio >= convert(smalldatetime,convert(varchar(10),getdate(),121),121) AND statuscall_id = 13  and calif_id > 0 
		 AND (@agentFlag=1 OR user_id = @userId) 
		 GROUP BY convert(smalldatetime,convert(varchar(10),cal_inicio,121),121), [user_id], calif_id 
		) data
		on (calif.calif_id = data.calif_id))) AS R   
	, #LoginTimeAgent As T
	, ccUsers As U
	, #totalCalls As TC
	WHERE R.user_id = T.uid 
	AND R.user_id = U.user_id
	AND R.user_id = TC.user_id 
	ORDER BY R.user_id

	--Get total calls for the day of all agents--

	--Clean temp tables--

	IF OBJECT_ID(''tempdb..#LoginTime'') IS NOT NULL 
	BEGIN
	  DROP TABLE #LoginTime
	END

	IF OBJECT_ID(''tempdb..#LoginTimeAgent'') IS NOT NULL 
	BEGIN
	  DROP TABLE #LoginTimeAgent
	END

	IF OBJECT_ID(''tempdb..#totalCalls'') IS NOT NULL 
	BEGIN
	  DROP TABLE #totalCalls
	END

	--Clean temp tables--

END'
		
		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_RIA_ABCLog]
@option tinyint,
@areaName varchar(50)=null,
@operationType tinyint = null,
@login varchar(20) = null,
@moduleId int=null,
@value varchar(50)=null,
@target varchar(50)=null,
@operationDateIni smalldatetime = null,
@operationDateFin smalldatetime = null,
@top int = 0
as
set nocount on

if @option=1 -- muestra todo
 begin
	select log_id, areaName, operationDate, operationType, login, module_id, value, target
	from ccRIALog with(nolock)
	return(0)
 end

if @option=2 -- insert
 begin
	declare @areaNameValue as varchar(50)
	set @areaNameValue = @areaName

	if (left(@areaName,1) = ''!'')
	 begin
		select @areaNameValue = areaName
		from dbo.ccRIACat_Areas AS AREAS WITH(NOLOCK)
		where AREAS.IDArea = right(@areaName,len(@areaName)-1)
	 end

	INSERT INTO ccRIALog VALUES(@areaNameValue, GETDATE(), @operationType, @login, @moduleId, @value, @target)
	return(0)
 end

declare @lang tinyint
select @lang = valor from ccsettings where setting_id=27

if @option=3 -- muestra información por filtros (System>Log) // Fechas
 begin
	set rowcount @top
	select L.log_id, L.areaName, L.operationDate, 
	case @lang when 0 then SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion)-1)
	 else SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion)+1, len(o.descripcion)) END operationType, L.login, 
	case @lang when 0 then SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion)-1)
	 else SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion)+1, len(m.descripcion)) END module_id, L.value, L.target
	from CCRIALOG L join ccRIALog_Module M with(index(IX_ccRIALog_Module)) on L.module_id = M.module_id join ccRIALog_Operation O with(index(IX_ccRIALog_Operation)) on L.operationType = O.operationType
	where L.operationType = case isnull(@operationType, 0) when 0 then L.operationType else @operationType end
	 and L.login = case isnull(@login, '''') when '''' then L.login else @login end
	 and L.module_id = case isnull(@moduleId, 0) when 0 then L.module_id else @moduleId end
	 and L.target = case isnull(@target, '''') when '''' then L.target else @target end
	 and L.operationDate >= case when isnull(@operationDateIni, ''19000101'') <> ''19000101'' and 
		isnull(@operationDateFin, ''19000101'') <> ''19000101'' then dateadd(minute, -1, @operationDateIni) else L.operationDate end
	 and L.operationDate <= case when isnull(@operationDateIni, ''19000101'') <> ''19000101'' and 
		isnull(@operationDateFin, ''19000101'') <> ''19000101'' then dateadd(minute, 1, @operationDateFin) else L.operationDate end
	order by L.operationDate desc
	return(0)
 end

if @option=4 -- Catalogo de modulos
 begin
	select m.module_id, o.operationType, 
	case @lang when 0 then SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion)-1)
	 else SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion)+1, len(m.descripcion)) END as mDescripcion, 
	 case @lang when 0 then SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion)-1)
	 else SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion)+1, len(o.descripcion)) END as oDescripcion
	from ccRIALog_Operation o with(index(IX_ccRIALog_Operation)) join ccRIALog_Cat_Relation r on o.operationType = r.operationType
	 join ccRIALog_Module m with(index(IX_ccRIALog_Module)) on r.module_id = m.module_id
	UNION
	select 0, -1, case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END, ''-''
	UNION
	select 0, 0, case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END, case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END
	UNION
	select module_id, 0, case @lang when 0 then SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion)-1)
	 else SUBSTRING(descripcion, CHARINDEX(''|'', descripcion)+1, len(descripcion)) END as descripcion, 
	 case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END from ccRIALog_Module with(index(IX_ccRIALog_Module)) 
	UNION
	select module_id, -1, case @lang when 0 then SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion)-1)
	 else SUBSTRING(descripcion, CHARINDEX(''|'', descripcion)+1, len(descripcion)) END as descripcion, ''-'' 
	 from ccRIALog_Module with(index(IX_ccRIALog_Module)) 	
    order by mDescripcion, oDescripcion
	return(0)
 end

if @option=5 -- Catalogo de operaciones
 begin
	select operationType, case @lang when 0 then SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion)-1)
	 else SUBSTRING(descripcion, CHARINDEX(''|'', descripcion)+1, len(descripcion)) END as descripcion
	from ccRIALog_Operation with(index(IX_ccRIALog_Operation))
	union
	select 0, case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END 
	order by 2
	return(0)
 end

set nocount off'
		
		EXEC(@Sql)

			set @Sql = 'CREATE NONCLUSTERED INDEX IX_ccLogLogin_3
      ON ccLogLogin (user_id,tipomov,fecha)

CREATE NONCLUSTERED INDEX IX_ccPosicion_2
      ON ccPosicion (user_id,computer)

CREATE NONCLUSTERED INDEX IX_ccusers
      ON ccusers (tipostatusage_id)

CREATE NONCLUSTERED INDEX IX_ccoCallsOut_7
      ON ccoCallsOut (cal_puerto,cal_manual)

CREATE NONCLUSTERED INDEX IX_ccoCallsOut_8
      ON ccoCallsOut (cal_puerto,cal_manual,cal_inicio,provedor_id)

CREATE NONCLUSTERED INDEX IX_ccoDialers
      ON ccoDialers (puerto)

CREATE NONCLUSTERED INDEX IX_ccRIACampEspWG_2
      ON ccRIACampEspWG (tipo,idcampesp)

CREATE NONCLUSTERED INDEX IX_ccRIAChat_Log
      ON ccRIAChat_Log (TipoMsgChat,user_id_adm,user_id_agt,fecha_chat)

CREATE NONCLUSTERED INDEX IX_ccRIAChat_Log_1
      ON ccRIAChat_Log (user_id_adm,user_id_agt,fecha_chat)

CREATE NONCLUSTERED INDEX IX_ccusers_1
      ON ccusers (tipouser_id,idarea)

CREATE NONCLUSTERED INDEX IX_ccCallsIn_3
      ON ccCallsIn (cal_inicio,inbound_id)

CREATE NONCLUSTERED INDEX IX_ccHorarioVeranoUsa
      ON ccHorarioVeranoUsa (inicio)

CREATE NONCLUSTERED INDEX IX_ccHorarioVerano
      ON ccHorarioVerano (inicio)

CREATE NONCLUSTERED INDEX IX_ccCampsPrioridadTel
      ON ccCampsPrioridadTel (cam_id)

CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_3
      ON ccLogAgentesDia (tipostatusage_id,user_id)

CREATE NONCLUSTERED INDEX IX_ccDNIS
      ON ccDNIS (dni_numero,dni_status)

CREATE NONCLUSTERED INDEX IX_ccInboundDNIS
      ON ccInboundDNIS (dni_id)'
		
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_CstoCalculaCosto]
@IDCall int = 0,
@from AS smalldatetime = NULL,
@to AS smalldatetime = NULL
AS
set nocount on
declare @minutouno decimal(10,3), @minutoadicional decimal(10,3)
declare @puerto smallint, @provedor_id smallint
declare @longitud tinyint, @tipoLlamada_id tinyint
declare @telefono varchar(20)

if @IDCall = 0 -- Para calcular todo
 begin
	if @from is null and @to is null
	 begin
		update ccoCallsOut
		set costo =  t.MinutoUno + case when cco.cal_txfer + cco.cal_tring + cco.cal_tDialog > 0 then((ceiling(( cco.cal_txfer + cco.cal_tring + cco.cal_tDialog ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
		 ,provedor_id = cd.provedor_id
		 ,tipoLlamada_id = t.tipoLlamada_id
		from ccoCallsOut cco with(index(IX_ccoCallsOut_7)), ccoDialers cd, cstoTarifa t
		where cco.cal_puerto = cd.puerto
		 and cd.provedor_id = t.provedor_id	
		 and t.tipoLlamada_id = dbo.fnGetTipoLlamada(ltrim(rtrim(cal_telefono)))--dbo.fnGetTipoLlamada(cco.cal_telefono)
		 and cco.cal_manual <> 1
		 return(0)
	 end

	-- calcula en el rango de fechas, solo los que no tienen costo
	update ccoCallsOut
	set costo =  t.MinutoUno + case when cco.cal_txfer + cco.cal_tring + cco.cal_tDialog > 0 then((ceiling(( cco.cal_txfer + cco.cal_tring + cco.cal_tDialog ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
	,provedor_id = cd.provedor_id
	,tipoLlamada_id = t.tipoLlamada_id
	from ccoCallsOut cco with(index(IX_ccoCallsOut_8)), ccoDialers cd, cstoTarifa t
	where cco.cal_puerto = cd.puerto
	 and cd.provedor_id = t.provedor_id	
	 and t.tipoLlamada_id = dbo.fnGetTipoLlamada(cco.cal_telefono)
	 and cco.cal_manual <> 1
	 and cco.cal_inicio between @from and @to
	 and cco.provedor_id is null
	 return(0)
 end

select @puerto = cal_puerto, @longitud = len(cal_telefono) , @telefono = cal_telefono from ccoCallsOut where cal_id = @idCall

if @puerto = 0
	return(0)

select @minutouno = minutouno, @minutoadicional = minutoadicional, @provedor_id = d.provedor_id, @tipoLlamada_id = t.tipollamada_id from cstoTarifa t
inner join ccoDialers d on d.provedor_id = t.provedor_id
where t.tipollamada_id = dbo.fnGetTipoLlamada( @telefono )
and d.puerto = @puerto

update ccoCallsOut set costo = @MinutoUno + 
case when cal_txfer + cal_tring + cal_tDialog > 0 then((ceiling(( cal_txfer + cal_tring + cal_tDialog ) / 60.0 )- 1) * @MinutoAdicional ) else 0 end
,provedor_id = case @provedor_id when 0 then provedor_id else @provedor_id end
,tipoLlamada_id = case @tipoLlamada_id when 0 then tipoLlamada_id else @tipoLlamada_id end
where cal_id = @idCall
set nocount off'
		
		EXEC(@Sql)

			set @Sql = 'ALTER Procedure [dbo].[ccsp_RIAABCChat]
@OperationType tinyint = 0, -- 0:Select | 1:Insert | 2:Select Excel | 3:DateRange | 4:Admins | 5:Agents
@TipoMsgChat tinyint = null,
@User_id_Adm varchar(8000) = null,
@User_id_Agt varchar(8000) = null,
@ChatMsg varchar(1500) = null,
@Fecha_Chat_ini datetime = null,
@Fecha_Chat_fin datetime = null,
@IDArea int = null
AS
set nocount on

if @OperationType not in (0,1,2,3,4,5)
	raiserror(''Invalid Operation Type'', 18, 1)

if @OperationType=0
 begin
	Declare @User_id_Adm2 smallint, @User_id_Agt2 smallint, @Fecha2 varchar(10), @Fecha3 varchar(10), @Fecha4 varchar(10)
	CREATE TABLE #CHAT (id int identity, xmlType tinyint, User_id_Adm smallint, User_id_Agt smallint, date varchar(10), 
	 iniTime varchar(10), endTime varchar(10), TipoMsgChat tinyint, text varchar(1500), time varchar(10))
	
	Declare CursorChat Cursor For
	-- Realizamos la Select para extraer las tablas
	select distinct User_id_Adm, User_id_Agt, convert(varchar(25), Fecha_Chat, 103) date
	 , min(convert(varchar(8), Fecha_Chat, 108)) iniTime
	 , max(convert(varchar(8), Fecha_Chat, 108)) endTime
	from ccRIAChat_Log --with (nolock, index(PK_ccRIAChat_Log))
	where TipoMsgChat = case when isnull(@TipoMsgChat,0)=0 then TipoMsgChat else @TipoMsgChat end
	 and User_id_Adm in (select case when isnull(@User_id_Adm,''0'') in (''0'','''') then User_id_Adm else value end from dbo.fn_RIASplitDelimited (@User_id_Adm, '',''))
	 and User_id_Agt in (select case when isnull(@User_id_Agt,''0'') in (''0'','''') then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
	 and Fecha_Chat between isnull(@Fecha_Chat_ini, ''19000101 00:00'') 
	 and isnull(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))
	group by User_id_Adm, User_id_Agt, convert(varchar(25), Fecha_Chat, 103)
	Order by date desc, iniTime desc

	Open CursorChat
	Fetch Next From CursorChat
	Into @User_id_Adm2, @User_id_Agt2, @Fecha2, @Fecha3, @Fecha4

	if @@FETCH_STATUS = 0
	 Begin

	-- Mientras hay resultados para procesar
		While @@FETCH_STATUS = 0
		 Begin
			insert into #CHAT select ''1'' xmlType, @User_id_Adm2 User_id_Adm, @User_id_Agt2 User_id_Agt, 
			 @Fecha2 date, @Fecha3 iniTime, @Fecha4 endTime, 0 TipoMsgChat, '''' text, '''' time
			 
			-- Iniciamos el proceso
			insert into #CHAT select ''0'' xmlType, @User_id_Adm2 User_id_Adm, @User_id_Agt2 User_id_Agt, @Fecha2 date, '''' iniTime, 
			'''' endTime, TipoMsgChat, ChatMsg text, convert(varchar(25), Fecha_Chat, 108) time
			from ccRIAChat_Log where User_id_Adm = @User_id_Adm2 and User_id_Agt = @User_id_Agt2 and convert(varchar(25), Fecha_Chat, 103) = @Fecha2
			order by time desc

			-- Recuperamos la siguiente fila
			Fetch Next From CursorChat
				Into @User_id_Adm2, @User_id_Agt2, @Fecha2, @Fecha3, @Fecha4
		 End
	 End 


	Close CursorChat
	Deallocate CursorChat
	select C.xmlType, U2.Nombres + isnull('' '' + U2.ApellidoPaterno, '''') + isnull('' '' + U2.ApellidoMaterno, '''') Nombre_Adm,
	 U1.Nombres + isnull('' '' + U1.ApellidoPaterno, '''') + isnull('' '' + U1.ApellidoMaterno, '''') Nombre_Agt, 
	C.date, C.iniTime, C.endTime, C.TipoMsgChat, C.text, C.time
	from #CHAT C join ccUsers U1 on U1.user_id = C.User_id_Agt
	 join ccUsers U2 on U2.user_id = C.User_id_Adm
	order by C.id
	return(0)
 end

if @OperationType=1
 begin
	if  @TipoMsgChat is NULL or @User_id_Adm is NULL or @User_id_Agt is NULL or @ChatMsg is NULL
		raiserror(''Invalid Data 3'', 18, 3)

	insert ccRIAChat_Log (TipoMsgChat, User_id_Adm, User_id_Agt, ChatMsg)
	select @TipoMsgChat, @User_id_Adm, @User_id_Agt, @ChatMsg
	select SCOPE_IDENTITY() ChatID
	return(0)
 end

if @OperationType=2
 begin
	-- Realizamos la Select para extraer las tablas
	if isnull(@User_id_Adm,''0'')=''0'' and isnull(@User_id_Agt,''0'')=''0'' and isnull(@TipoMsgChat,0)=0 and (@Fecha_Chat_ini is null and @Fecha_Chat_fin is null)
		raiserror(''Invalid Data 2'', 18, 2)

	create table #ExcelChat (Fecha_Chat datetime, TipoMsgChat varchar(30), Nombre_Adm varchar(100), Nombre_Agt varchar(100), ChatMsg varchar(2000))
	
	insert into #ExcelChat
	select Fecha_Chat, 
	case C.TipoMsgChat when 1 then ''Admin -> Agent'' when 2 then ''Admin <- Agent'' else ''Admin -> Global'' end TipoMsgChat, 
	U2.Nombres + isnull('' '' + U2.ApellidoPaterno, '''') + isnull('' '' + U2.ApellidoMaterno, '''') Nombre_Adm, 
	U1.Nombres + isnull('' '' + U1.ApellidoPaterno, '''') + isnull('' '' + U1.ApellidoMaterno, '''') Nombre_Agt, C.ChatMsg
	from ccRIAChat_Log C join ccUsers U1 on U1.user_id = C.User_id_Agt
	 join ccUsers U2 on U2.user_id = C.User_id_Adm
	where TipoMsgChat = case when isnull(@TipoMsgChat,0)=0 then TipoMsgChat else @TipoMsgChat end
	 and User_id_Adm in (select case when isnull(@User_id_Adm,''0'')=''0'' then User_id_Adm else value end from dbo.fn_RIASplitDelimited (@User_id_Adm, '',''))
	 and User_id_Agt in (select case when isnull(@User_id_Agt,''0'')=''0'' then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
	 and Fecha_Chat between isnull(@Fecha_Chat_ini, ''19000101 00:00'') 
	 and isnull(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))

	if (select valor from ccsettings where setting_id=27) = 0
	 begin
		select convert(varchar(10), Fecha_Chat, 103)+'' ''+convert(varchar(8), Fecha_Chat, 108) Fecha_Chat, TipoMsgChat, Nombre_Adm, Nombre_Agt, ChatMsg from #ExcelChat Order by 1 desc
	 end

	else
	 begin
		select convert(varchar(10), Fecha_Chat, 101)+'' ''+convert(varchar(8), Fecha_Chat, 108) timestamp, TipoMsgChat MsgChatType, Nombre_Adm Adm_Name, Nombre_Agt Agt_Name, ChatMsg ChatMsg from #ExcelChat Order by 1 desc
	 end

	return(0)
 end

if @OperationType=3
 begin
	select @Fecha_Chat_ini=min(Fecha_Chat), @Fecha_Chat_fin=max(Fecha_Chat) from ccRIAChat_Log
	select @Fecha_Chat_ini Fecha_Chat_MIN, @Fecha_Chat_fin Fecha_Chat_MAX
	return(0)
 end

if @OperationType=4
 begin
	if not exists(select IDArea from ccRIACat_Areas where IDArea = @IDArea) or not exists(select user_id from ccusers where TipoUser_id in(2,6) and IDArea=@IDArea)
		raiserror(''Invalid Area'', 18, 4)

	select User_id, Login, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') Nombre
	from ccusers where TipoUser_id in(2,6) and IDArea=@IDArea
	order by login, Nombre
	return(0)
 end

if @OperationType=5
 begin
	if not exists(select IDArea from ccRIACat_Areas where IDArea = @IDArea) or not exists(select user_id from ccusers where TipoUser_id in(1) and IDArea=@IDArea)
		raiserror(''Invalid Area'', 18, 4)

	select User_id, Login, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') Nombre, Sexo gender
	from ccusers where TipoUser_id in(1) and IDArea=@IDArea
	order by login, Nombre
	return(0)
 end

select 0
set nocount off'
		
		EXEC(@Sql)

set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0,
@Tipo tinyint = 0,
@user_id int = 0
as
set nocount on
declare @regval as int
-- Actualiza todas las camps
if @Tipo=2
begin
	declare @ultimo as datetime,@id AS INTEGER
	select @ultimo = isnull( convert(datetime, valor, 121), dateadd(hh, -1, getdate() ) ) from ccSettings where setting_id = 21
	if datediff(ss, @ultimo, getdate()) > 120
	begin
		
		CREATE TABLE #Tcamps
		(cam_id int,
		 cantidad int)
		
		DECLARE CCamp CURSOR FOR 
			select cam_id from ccCamps
		Open CCamp
		Fetch Next From CCamp
		Into @id
		if @@FETCH_STATUS = 0
			Begin 
				While @@FETCH_STATUS = 0
				Begin 
					EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
					INSERT #Tcamps
						select @id, @regval
					Fetch Next From CCamp
					Into  @id
				End
			End
		CLOSE CCamp
		DEALLOCATE CCamp

		UPDATE ccSettings set valor = convert( varchar(23), getdate(),121) where setting_id = 21
		TRUNCATE TABLE ccCampsNvosCB
		INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial)
		SELECT cams.cam_id, cams.cam_descripcion, 
		isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb, 
		isNull(cs.Pend,0) as pend,
		isNull(wt.Pro,0) as pro,
		cams.cam_procesando, cams.cam_tipojobs, isNull(wt.Fin,0) Fin,
		tc.cantidad
		FROM ccCamps cams
		LEFT JOIN
		(
				SELECT cam_id,
				count(case cal_status when 0 then 1 else null end) as New,
				count(case cal_status when 1 then 1 else null end) as Cb,
				count(case cal_status when 2 then 1 else null end) as Pro,
				count(case cal_status when 3 then 1 else null end) as Fin
				FROM ccoworkingtable
				GROUP BY cam_id
		) wt on cams.cam_id = wt.cam_id
		LEFT JOIN
		(
				SELECT cam_id, count(cam_id) as Pend
				FROM ccocallsoutsource 
				WHERE cal_status in(0, 7)
				GROUP BY cam_id
		) cs on cams.cam_id = cs.cam_id
		left join #Tcamps tc on (tc.cam_id = cams.cam_id)

		drop table #Tcamps
	end

	-- devuelve resultado de la taba, solo las camps del usuario
	SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, res.st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial
	FROM ccCampsNvosCB res
	LEFT JOIN ccCampsPrioridadTel prio on res.id=prio.cam_id
	WHERE res.id in(select cam_id from ccSupervisorCam where tipo=1 and user_id=@user_id)
	return(0)
end

-- Actualiza una camp
if @Tipo=1
begin
	exec @regval = ccsp_OUTGetNewJobs @cam_id,2,0

	delete ccCampsNvosCB where id = @cam_id
	INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial)
	SELECT cams.cam_id, cams.cam_descripcion, 
	isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb, 
	isNull(cs.Pend,0) as pend,
	isNull(wt.Pro,0) as pro,
	cams.cam_procesando, cams.cam_tipojobs, isNull(wt.Fin,0) Fin,
	isnull(@regval,0) NextDial
	FROM ccCamps cams
	LEFT JOIN
	(
			SELECT @cam_id as cam_id,
			count(case cal_status when 0 then 1 else null end) as New,
			count(case cal_status when 1 then 1 else null end) as Cb,
			count(case cal_status when 2 then 1 else null end) as Pro,
			count(case cal_status when 3 then 1 else null end) as Fin
			FROM ccoworkingtable
			WHERE cam_id = @cam_id
	) wt on cams.cam_id = wt.cam_id
	LEFT JOIN
	(
			SELECT @cam_id as cam_id, count(cam_id) as Pend
			FROM ccocallsoutsource
			WHERE cal_status in (0,7) AND cam_id = @cam_id
	) cs on cams.cam_id = cs.cam_id
	WHERE cams.cam_id= @cam_id

	-- devuelve resultado de la taba
	SELECT id, campaña, new, cb, pro, pen,st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial
	FROM ccCampsNvosCB res
	LEFT JOIN ccCampsPrioridadTel prio on res.id=prio.cam_id
	WHERE res.id =@cam_id

	return(0)
 end
set nocount off'
exec(@Sql)

set @Sql = 'ALTER proc [dbo].[ccsp_RIAADMgetAbandonoSalida_Fix]
as
set nocount on
declare @fecha smalldatetime, @fecha2 smalldatetime
declare @i int

truncate table ccAbandonoSalida_Chart

set @fecha = convert(varchar(10), getdate(), 112)+'' ''+convert(varchar(4), getdate(), 108)+''0''
set @i =0
while @i < 30
begin
	set @fecha2 = dateadd( mi, -10, @fecha)

	insert into ccAbandonoSalida_Chart
	select ccCamps.cam_id, x.AbndPctg, @fecha2 from ccCamps
	left join
	(
		select cam_id,round(count(case statuscall_id when 6 then 1 else null end ) *100.0 / (count(*)+.000001) , 2 ) as AbndPctg 
		from ccoCallsOut
		with( index(IX_ccoCallsOut_2) )
		where cal_manual in (0,2 ) and cal_inicio >= @fecha2 and cal_inicio < @fecha
		group by cam_id
	)x on x.cam_id = ccCamps.cam_id
	where ccCamps.idArea is not null

	set @fecha = @fecha2
	set @i = @i +1
end

set nocount off'
exec(@Sql)

set @Sql = 'ALTER procedure [dbo].[ccsp_RIAADMgetAbandonoSalida]
@User_id smallint = null,
@cam_id smallint = null
AS 
set nocount on
declare @fecha datetime, @ultimo datetime
declare @lastAband float

select @ultimo = valor from ccSettings where setting_id = 25
if datediff(ss, @ultimo, getdate()) > 300 
begin
	set @fecha = getdate()
	update ccsettings set valor = convert(varchar(19), @fecha, 121) where setting_id = 25

	-- calcula abandono para la grafica
	exec ccsp_RIAADMgetAbandonoSalida_Fix

	-- llena tabla ccAbandonoSalida
	truncate table ccAbandonoSalida

	insert into ccAbandonoSalida
	select cam_id, round(avg(abndpctg),2) from ccAbandonoSalida_chart -- where abndpctg is not null
	group by cam_id	
end

if @User_id is not null
begin
	select distinct h.cam_id, isnull(h.AbndPctg,0)
	from ccAbandonoSalida h inner join ccSupervisorCam i on h.cam_id = i.cam_id
	where i.user_id = @User_id

	return(0)
end

if @cam_id is not null
begin
	select top 1 @lastAband = AbndPctg from ccAbandonoSalida_Chart
	where cam_id = @cam_id order by timestamp desc

	select @cam_id as cam_id, x.cam_descripcion, isNull(@lastAband,0) as LastAbndPctg, x.ts as timestamp, x.AbndPctg from 
	(
		select top 20 C.cam_descripcion,
		convert(varchar(4), A.Timestamp, 108)+''0'' as ts, isnull(A.AbndPctg,0) as AbndPctg
		from ccAbandonoSalida_Chart A 
		join ccCamps C on A.cam_id = C.cam_id
		Where A.cam_id=@cam_id
		order by timestamp desc
	)x order by x.ts

	return(0)
end

set nocount off'
exec(@Sql)

set @sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID as int,
@test as int=0,
@nAgentsLogin as int=1
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @idioma int, @TipoJobs int
declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @Sql varchar(4000), @Order_Asc_Desc char(4)
 
-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @idioma=valor FROM ccSettings WHERE setting_id=27
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')
 
SET DATEFIRST 1
--Checamos si es horario de verano
if @idioma=1
       select @bIsDaylight=case when getdate()between inicio and fin then 1 else 0 end
       from ccHorarioVeranoUsa where year(getdate())=year(inicio)
 
else
       select @bIsDaylight=case when getdate()between inicio and fin then 1 else 0 end
       from ccHorarioVerano where year(getdate())=year(inicio)
 
select @bIsDaylight=isnull(@bIsDaylight,1)
 
--Checamos si la campaña tiene horarios configurados
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
begin
       declare @horaUniversal as datetime
       set @horaUniversal=getutcdate()
 
       select @iZonas=sum(distinct tz_id)from
       (select tz_id,
             datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora,
             datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
             datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
             from ccTimeZones
       )zonas inner join cchorarios on
       ((hora>HoraInicio OR(hora=HoraInicio AND minuto>= MinInicio))
             AND (hora<HoraFin OR(hora=HoraFin AND minuto<= MinFin))
             AND (
                    Lunes=dia or
                    Martes*2=dia or
                    Miercoles*3=dia or
                    Jueves*4=dia or
                    Viernes*5=dia or
                    Sabado*6=dia or
                    domingo*7=dia
              )
       ) inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id=ccCampsHorarios.horario_id and ccCampsHorarios.cam_id=@campid
 
       if @iZonas is null begin
             SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
             return
       end
end
 
else
begin
       if @revHorario=0
             select @iZonas=sum(distinct tz_id)from ccTimeZones -- No hay horarios, ponemos todas las zonas
       else
             select @iZonas=Null
 
end
 
set @Sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
cal_status tinyint,
cal_fechaDial datetime,
user_id int,
 tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint
)''
 
-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94
 
if isnull(@topCount,0)=0
select @topCount=case when @nAgentsLogin<3 then 30
  when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
  when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
  when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
  when @nAgentsLogin>=16 then 240 else 0 end
 
select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
       select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast(isnull(@topCount/2,''0'') as CHAR(5))
 
       select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
       SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
       W.list_id, isNull(R.sequence,0) as sequence
       FROM ccoWorkingTable W left join ccRIARegistryLists R on W.list_id = R.list_id
       WHERE cal_status=1 -- CallBacks
       and cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
       and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
       and (
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
       )
       and isnull(R.status,2) = 2
       order by prioridad_cb desc, cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
 
end -- TOMA EN CUENTA LOS CALLBACKS
 
if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin 
       select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
       SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
       W.list_id, isNull(R.sequence,0) as sequence
       FROM ccoWorkingTable W left join ccRIARegistryLists R on W.list_id = R.list_id
       WHERE cal_status=0 -- Nuevas sin Tiempo
       and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
       and (
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
       )
       and isnull(R.status,2) = 2
       order by R.sequence, cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''
      
end -- TOMA EN CUENTA LAS NUEVAS
 
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @Sql=@Sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
begin
	select @Sql=@Sql+nchar(13)+ ''UPDATE ccoWorkingTable SET cal_status=2 --CALLBACK IN PROGRESS
		WHERE callout_id in(select callout_id from #NEW_JOBS)''
end
 
if @Test = 2
begin
	select @Sql=@Sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
	declare @nSQL nvarchar(4000)
	set @nSQL=cast(@Sql as nvarchar(4000))
	exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
	return(@total)
end
else
begin
 
select @Sql=@Sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0''
end
 
select @Sql=@Sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print @Sql
exec(@Sql)
return(0)'
exec(@sql)

set @sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewProviderJobs]
@CAMPID as int, 
@test as int=0,
@nAgentsLogin as int=1
as
set nocount on
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @idioma int, @TipoJobs int
declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @Sql varchar(MAX), @Order_Asc_Desc char(4)

-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @idioma=valor FROM ccSettings WHERE setting_id=27
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano 
if @idioma=1 
	select @bIsDaylight=case when getdate()between inicio and fin then 1 else 0 end
	from ccHorarioVeranoUsa where year(getdate())=year(inicio)

else 
	select @bIsDaylight=case when getdate()between inicio and fin then 1 else 0 end
	from ccHorarioVerano where year(getdate())=year(inicio)

select @bIsDaylight=isnull(@bIsDaylight,1)

--Checamos si la campaña tiene horarios configurados
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
 begin
	declare @horaUniversal as datetime 
	set @horaUniversal=getutcdate()

	select @iZonas=sum(distinct tz_id)from 
	(select tz_id,
		datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora, 
		datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
		datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
		from ccTimeZones 
	)zonas inner join cchorarios on
	((hora>HoraInicio OR(hora=HoraInicio AND minuto>= MinInicio))
		AND (hora<HoraFin OR(hora=HoraFin AND minuto<= MinFin))
		AND (
			Lunes=dia or
			Martes*2=dia or
			Miercoles*3=dia or
			Jueves*4=dia or
			Viernes*5=dia or
			Sabado*6=dia or
			domingo*7=dia
		)
	) inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id=ccCampsHorarios.horario_id and ccCampsHorarios.cam_id=@campid

	if @iZonas is null begin
		SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
		return
	end
 end 

else
begin
	if @revHorario=0
	begin
		select @iZonas=sum(distinct tz_id)from ccTimeZones -- No hay horarios, ponemos todas las zonas
	end
	else
	begin
		select @iZonas=Null
	end
end

set @Sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
 cam_id int,
 cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
 cal_status tinyint,
 cal_fechaDial datetime,
 user_id int, 
 tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
tel varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel2 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel3 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel4 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel5 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
dialOrder varchar(10),
list_id int,
sequence smallint
)''

-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
 select @topCount=case when @nAgentsLogin<3 then 30
  when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
  when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
  when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
  when @nAgentsLogin>=16 then 240 else 0 end

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
 begin
	select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast(isnull(@topCount/2,''0'') as CHAR(5))

	select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isnull(R.sequence,0) as sequence
	FROM ccoWorkingTable W left join ccRIARegistryLists R 
	on W.list_id = R.list_id 
	left join ccocallsoutsource couts    
	on W.callout_id = couts.callout_id 
	WHERE W.cal_status=1 -- CallBacks
	and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
	and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + '' 
	and (
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by W.prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
 end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
 begin
	select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id, 
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isNull(R.sequence,0) as sequence
	FROM ccoWorkingTable W left join ccRIARegistryLists R 
	on W.list_id = R.list_id 
	left join ccocallsoutsource couts    
	on W.callout_id = couts.callout_id 
	WHERE W.cal_status=0 -- Nuevas sin Tiempo
	and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + '' 
	and (
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', W.callout_id''
	
 end -- TOMA EN CUENTA LAS NUEVAS

----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT 0''
if @Test=0 
begin
	select @Sql=@Sql+nchar(13)+ ''UPDATE ccoWorkingTable SET cal_status=2 --CALLBACK IN PROGRESS
	WHERE callout_id in(select callout_id from #NEW_JOBS)''
end

select @Sql=@Sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, 
user_id, tz, tz2, tz3, tz4, tz5, tel, tel2, tel3, tel4, tel5, dialOrder, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0''

select @Sql=@Sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print @Sql
exec(@Sql)
return(0)'
exec(@sql)

	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC], ERROR_PROCEDURE()
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

