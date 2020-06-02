/*
Autor: Jesus Gallardo
Fecha: 2014/05/12
Descripcion:
	Se crea la tabla ccRIACampEspWGConsulta para fix en finder AVRS
	Se crea la tabla ccRIAWorkGroupUsersConsulta para fix en finder AVRS
	Se crea indece en la tabla ccRIACampEspWGConsulta(IX_ccRIACampEspWGConsulta) la columna IdCampEsp
	Se crea indece en la tabla ccRIACampEspWGConsulta(IX_ccRIACampEspWGConsulta_1) la columna IDWG
	Se crea indece en la tabla ccRIACampEspWGConsulta(IX_ccRIACampEspWGConsulta_2) la columna Tipo
	Se crea indece en la tabla ccRIAWorkGroupUsersConsulta(IX_ccRIAWorkGroupUsersConsulta) la columna IDWG
	Se inserta setting 153 para servicio de BaseX
	Se inserta setting 154 para la configuracion de agregar ani por la opcion VOICEMAIL
	Se inserta setting 155,156 y 157 para el servicio de Mail
	Se copia los registros de ccRIACampEspWG a ccRIACampEspWGConsulta
	Se copia los registros de ccRIAWorkGroupUsers a ccRIAWorkGroupUsersConsulta
	Se actuliza la descripcion del menu 3060 de efectividad ACD
	Se actuliza el parent del menu AVRS -- Disposition por 8000 al 8050 que es el padre correcto
	Se modifica el SP ccsp_RIA_ABCWorkGroups para relacion workGroup con campañas o ACD en ccRIACampEspWGConsulta
	Se modifica el SP ccsp_RIAManageWG para relacion workGroup y administradores en ccRIAWorkGroupUsersConsulta
	Se modifica el SP ccsp_AgentSetCallStatus para llamadas con chat
	Se modifica el SP ccsp_AgentUpdateCallTimes para llamadas con chat
	Se modifica el Job NuxibaMaintenancePlan para actualizacion
	
Version requerida: 106
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '107'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccRIACampEspWGConsulta - Create Table'
		set @Sql='CREATE TABLE [dbo].[ccRIACampEspWGConsulta](
	[IDWG] [smallint] NOT NULL,
	[Tipo] [smallint] NOT NULL,
	[IdCampEsp] [smallint] NOT NULL		
) ON [PRIMARY]'
	
	EXEC(@Sql)

		set @process = 'ccRIAWorkGroupUsersConsulta - Create Table'
		set @Sql='CREATE TABLE [dbo].[ccRIAWorkGroupUsersConsulta](
	[IDWG] [smallint] NOT NULL,
	[User_id] [smallint] NOT NULL
) ON [PRIMARY]'
	
	EXEC(@Sql)
	
		set @process = 'IX_ccRIACampEspWG - Create index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccRIACampEspWGConsulta] ON [dbo].[ccRIACampEspWGConsulta] ([IdCampEsp] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]'
	
	EXEC(@Sql)

		set @process = 'IX_ccRIACampEspWG_1 - Create index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccRIACampEspWGConsulta_1] ON [dbo].[ccRIACampEspWGConsulta]([IDWG] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]'
	
	EXEC(@Sql)
	
		set @process = 'IX_ccRIACampEspWG_2 - Create index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccRIACampEspWGConsulta_2] ON [dbo].[ccRIACampEspWGConsulta] ([Tipo] ASC, [IdCampEsp] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

		set @process = 'IX_ccRIAWorkGroupUsers - Create index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccRIAWorkGroupUsersConsulta] ON [dbo].[ccRIAWorkGroupUsersConsulta]([IDWG] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'ccsettings - insert ccsettings'
	set @Sql='insert into ccsettings (setting_id, valor, descripcion, [Status], [Tipo], detalle, [description], bLoadSettings) values
(153, ''C:\Program Files\BaseX|192.168.1.143|1984|admin|nuxiba|120|10'', ''Configuración del servicio BaseX path|host|port|user|pass|seg|amount'', 1, ''X'', ''Parametros para el servicio de Base X path|host|port|user|pass|seg|amount, seg = el tiempo que debera transcurrir para pasar los datos'', ''BaseX service configuration'',1)
insert into  ccsettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings) values 
(154,''0'',''Agrega el ani en la opcion VOICEMAIL'',1,''GRL'',''Formato archivo (ANI_HHMMSS_Port.wav), ejemplo 17224487_172015_1.wav '',''Add ANI in option VOICEMAIL'',1)
insert into ccsettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings) 
values(155,''0'',''Muestra si esta activa la funcionalidad de Email'',1,''X'',''0 no esta habilitada y 1 esta habilitada'',''0 not enabled and 1 is enabled'',1)
insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings) 
values(156,''.\emails'',''Ruta para guardar los correos electronicos'',1,''GRL'',''Se guarda los archivos mail en carpetas por el conversationId'',''Path to save the mail'',1)
insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings) 
values(157,'''',''Ubicacion del email service'',1,''GRL'',''IP del servidor donde se encuentra el Email Service, se actualiza automaticamente cuando se abre el email service'',''Email Service location (automatically updated when the email service starts)'',1)'
	
	EXEC(@Sql)	

	set @process = 'Copy registry ccRIACampEspWG to ccRIACampEspWGConsulta - insert ccRIACampEspWGConsulta'
	set @Sql='insert into ccRIACampEspWGConsulta(IDWG,Tipo,IdCampEsp) select IDWG,Tipo,IdCampEsp from ccRIACampEspWG'
	
	EXEC(@Sql)

	set @process = 'Copy registry ccRIAWorkGroupUsers to ccRIAWorkGroupUsersConsulta - insert ccRIAWorkGroupUsersConsulta'
	set @Sql='insert into ccRIAWorkGroupUsersConsulta(IDWG,User_id) select IDWG,User_id from ccRIAWorkGroupUsers'
	
	EXEC(@Sql)
	
	set @process = 'update - Table ccmenus'
	set @Sql = 'update ccmenus set menu_descrip =''Efectividad|Effectiveness'' where menu_id=3060 and type=3
	update ccmenus set parent=8050 where type = 3 and menu_id= 8080'
		
		EXEC(@Sql)

	set @process = 'ccsp_RIA_ABCWorkGroups - Alter Procedure'
	set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCWorkGroups]
@option smallint,
@IDWG smallint,
@user_Id smallint = 0,
@Descripcion varchar(45) = null,
@IDArea smallint = null,
@IDCampEsp varchar(2000),
@Type smallint
as
set nocount on
if @option = 0 -- All WokGroup
 begin
	if(@IDArea = 0 or @IDArea is null)
		select IDWG, WGName from ccRIACat_WorkGroup with(readpast) where StatusWorkGroup=1
	else
		select IDWG, WGName from ccRIACat_WorkGroup with(readpast) where StatusWorkGroup=1 and IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea=@IDArea)
	
	return(0)
 end

if @option = 1 -- Selected WokGroup
 begin
	if @type = 0
	begin
		select IDWG, WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and IDWG=@IDWG
	end
	else if @type = 1
	begin
		select w.IDWG, w.WGName, a.IDArea
		from ccRIACat_WorkGroup w
		join ccRIAAreaWorkGroup aw on aw.idwg = w.idwg
		join ccRIACat_Areas a on a.IDArea = aw.IDArea
		where w.StatusWorkGroup=1
	end
	else if @type = 2
	begin
		select w.WGName, a.IDArea, a.AreaName
		from ccRIACat_WorkGroup w
		join ccRIAAreaWorkGroup aw on aw.idwg = w.idwg
		join ccRIACat_Areas a on a.IDArea = aw.IDArea
		where w.StatusWorkGroup=1 and w.IDWG=@IDWG
	end
	else if @type = 3
	begin
		select count(*)
		from ccRIAWorkGroupUsers
		where idwg=@IDWG
		and user_id=@user_Id
	end

	return(0)
 end

if @option = 2 -- insert WorkGroup
 begin
	if exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
	 begin
		select -1 --, Nombre en Uso
		return(0)
	 end
	
	insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
	if @@rowcount = 1
		select @IDWG = scope_identity()

	else 
	 begin
		select -2 --, No se inserto correctamente
		return(0)
	 end

	insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@IDWG, @IDArea)
	select 1 --, WG insertado
	return(0)
 end

if @option = 3 -- UpdateWokGroup
 begin
	Update ccRIACat_WorkGroup set WGName=@Descripcion where StatusWorkGroup=1 and IDWG=@IDWG
	return(0)
 end

if @option in (4,8) -- Delete WorkGroup (4:all / 8:only from acd/camps)
 begin
	Delete from ccCampsAgente where IDWG = @IDWG
	Delete from ccInboundAgentes where IDWG = @IDWG
	Delete from ccSupervisorCam where IDWG = @IDWG
	Delete from ccRIACampEspWG where IDWG = @IDWG
	
	if @option=4
	 begin
		Delete from ccRIAAreaWorkGroup where IDWG = @IDWG 
		Delete from ccRIAWorkGroupUsers where IDWG = @IDWG
		Update ccRIACat_WorkGroup set StatusWorkGroup=0 where IDWG=@IDWG
	 end
	return(0)
 end

if @option = 5 -- Insert WorkGroup in Camp or ACDGroup	
 begin
	if (select count(IDWG) from ccRIACampEspWG where IDWG=@IDWG) >= (select valor from ccSettings where setting_id=64) -- limit
	 begin
		select 2
		return(0)
	 end
	
	if exists (select IDWG from ccRIACampEspWG where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) -- Ya existe el grupo en el ACD o Especialidad
	 begin
		select 1
		return(0)
	 end

	insert into ccRIACampEspWG (IDWG, Tipo, IdCampEsp, priority) values (@IDWG, @Type, @IDCampEsp, 1)
	if not exists(select * from ccRIACampEspWGConsulta where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) begin
		insert into ccRIACampEspWGConsulta (IDWG, Tipo, IdCampEsp) values (@IDWG, @Type, @IDCampEsp)
	end
		

	exec ccsp_RIACalcula_WGPriority @IDWG, @IDCampEsp, @Type
	if @Type not in (0, 1) -- ACDGroup
		return(0)
		
	if @Type=0 --ACDGroup
	begin

		if @IDWG is null or @IDWG = 0
		 begin
			select 48
			return(0)
		 end
		 
		insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
		SELECT distinct u.user_id, @IDCampEsp, 0 cli_id, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG 
		FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
		 join ccusers s on u.user_id = s.user_id
		WHERE c.tipo=0 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and c.IDWG=@IDWG 
		and u.User_id not in (select User_id from ccInboundAgentes where Inbound_id=@IDCampEsp and IDWG=@IDWG)

		insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
		select b.user_id, @IDCampEsp, 0, @IDWG
		from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
		 join ccusers s on b.user_id = s.user_id
		where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=0
		 and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=0 and IDWG=@IDWG)
	 
		return(0)
	end
	
	if @IDWG is null or @IDWG = 0
	 begin
		select 18
		return(0)
	 end

	-- if @Type = 1 -- Camp
	insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
	SELECT distinct u.user_id, @IDCampEsp, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG
	FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
	join ccusers s on u.user_id = s.user_id
	WHERE c.tipo=1 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and u.IDWG=@IDWG 
	 and u.User_id not in (select User_id from ccCampsAgente where cam_id=@IDCampEsp and IDWG=@IDWG)
	
	insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
	select b.user_id, @IDCampEsp, 1, @IDWG
	from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
	 join ccusers s on b.user_id = s.user_id
	where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=1
	 and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=1 and IDWG=@IDWG)

	return(0)
 end

if @option = 6 -- Verifica si existe el grupo
 begin
  	select @IDWG = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
	 then 1 else 0 end
 
 	if isnull(@IDArea,0)=0
	 begin
		select @IDWG
		return(0)
	 end

 	if @IDWG=1
	 begin
		select ''-1''
		return(0)
	 end

	insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
	if @@rowcount = 1
		select @IDWG = scope_identity()

	insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@IDWG, @IDArea)
	select @IDWG
	return(0)
 end

if @option = 7 -- Delete WokGroup from ACD or Camp
 begin
	if @Type = 1
		Delete from ccCampsAgente where IDWG=@IDWG and cam_id=@IDCampEsp

	else if @Type = 0 
		Delete from ccInboundAgentes where IDWG=@IDWG and inbound_id=@IDCampEsp

	Delete from ccRIACampEspWG where IDWG=@IDWG and IdCampEsp=@IDCampEsp and Tipo=@Type

	return(0)
 end
 
return(0)
set nocount off'
	
	EXEC(@Sql)

set @process = 'ccsp_RIA_ABCWorkGroups - Alter Procedure'
		set @Sql='ALTER PROCedure [dbo].[ccsp_RIAManageWG]
@option smallint,
@IDWG smallint,
@Type smallint,
@UserId smallint,
@Descripcion varchar(25),
@IDArea as int
as
set nocount on

if @option = 3 -- Insert WokGroup
 begin
	Insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
	select @IDWG = scope_identity()
			
	Insert into ccRIAAreaWorkGroup(IDWG, IDArea) values(@IDWG, @IDArea)
	select @IDWG
	return(0)
 end

select @Type = TipoUser_id from ccUsers where User_id = @UserId

if @option = 1 -- Insert Agente-Supervisor in WorkGroup
 begin
	if @Type not in(1, 2, 6)
		return(0)

	if exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @UserId)
	 begin
		 select 1
		 return(0)
	 end

	If @Type = 1
	 begin
		
		If (select count(User_id) from ccRIAWorkGroupUsers where User_id = @UserId) > = (select valor from ccSettings where setting_id = 63)
		 begin
			select 3
			return(0)
		 end

		insert into ccRIAWorkGroupUsers(IDWG, User_id) values(@IDWG,@UserId)		

		if @IDWG is null or @IDWG = 0
		 begin
			select 38
			return(0)
		 end
		 
		insert into cccampsAgente (user_id, cam_id, prioridad, skill, IDWG)
		select @UserId, idCampEsp, dbo.fn_Calcula_UsrPriority(@UserId,0), 1, @IDWG
		from ccRIACampEspWG where tipo = 1 and IDWG = @IDWG and 
		 idCampEsp not in (select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

		insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, IDWG)
		select @UserId, idCampEsp, 0, dbo.fn_Calcula_UsrPriority(@UserId,0), 1, @IDWG
		from ccRIACampEspWG where tipo = 0 and IDWG = @IDWG and 
		 idCampEsp not in (select inbound_id from ccInboundAgentes where user_id=@UserId and IDWG=@IDWG)
		return(0)
	 end	

	-- -Supervisor	@Type in (2,6)
	insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @UserId)
	if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@UserId) begin	
		insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@UserId)
	end

	insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
	select @UserId, idCampEsp, 0, @IDWG 
	from ccRIACampEspWG where tipo=0 and IDWG=@IDWG 
	 and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

	update ccSupervisorCam
	set monitored = 1
	where user_id = @UserId
	and cam_id in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)
	and tipo = 0
	and IDWG <> @IDWG
	and monitored = 0

	insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
	select @UserId, idCampEsp, 1, @IDWG
	from ccRIACampEspWG where tipo=1 and IDWG=@IDWG 
	 and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)

	update ccSupervisorCam
	set monitored = 1
	where user_id = @UserId
	and cam_id in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
	and tipo = 1
	and IDWG <> @IDWG
	and monitored = 0

	return(0)
 end

if @option = 2 -- Delete Agent-Supervisor from WorkGroup
 begin
	Delete ccRIAWorkGroupUsers where IDWG = @IDWG and User_id = @UserId

	if @Type = 1 -- Agente
	 begin
		delete from cccampsagente where user_id=@UserId and IDWG=@IDWG
		delete from ccInboundagentes where user_id=@UserId and IDWG=@IDWG
		select @Type
		return(0)
	 end
	 
	--else if @Type in(2, 6) -- Supervisor
 	delete ccSupervisorCam where user_id=@UserId and IDWG=@IDWG
	select @Type
	return(0)
end
return(0)
set nocount off'
	
	EXEC(@Sql)

	set @process = 'ccsp_AgentSetCallStatus - Alter Procedure'
	set @Sql='ALTER procedure [dbo].[ccsp_AgentSetCallStatus]
@callout_id int,
@cal_id int,
@TipoCall tinyint,	-- 1= IN,  2=Out
@TipoMov tinyint,	-- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
@cal_tXfer tinyint=0,
@cal_tring  smallint=0,
@user_id smallint=0,
@extension varchar(5)='''',
@isChatCall bit = 0
AS
set nocount on

declare @RecicleSIC tinyint
SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id=60
Declare @ANI_x varchar(19)
declare @cal_inicio datetime
declare @callout_id_IN int
declare @cal_key varchar(20)
declare @cam_id int
declare @cal_telefono varchar(30)
declare @surveycamid int
declare @inbound_id int

if @TipoMov=4 or @TipoMov=14 -- DIALOG OnDialog
 begin
	if @TipoCall=2
	 begin
		if @TipoMov = 4
			Update ccoCallsOUT with(rowlock) Set statusCall_id=13, cal_manual=case when @isChatCall=1 then 3 else cal_manual end Where cal_id=@cal_id
		else if @TipoMov = 14
			Update ccoCallsOUT with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

		if @RecicleSIC=0
			DELETE ccoWorkingTable with(rowlock) WHERE callout_id=@callout_id

		update ccoCallBacks
		set [status] = 1, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 13

		-- calcula el costo de la llamada
		exec ccsp_CstoCalculaCosto @cal_id

		select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono
		from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
		where callout_id = @callout_id
		and statusCall_id = 13
		and cal_id = @cal_id

		select @surveycamid = isnull(surveycamid,0) from cccamps where cam_id = @cam_id

		if @surveycamid > 0
			begin
				if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100 
				begin
					insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial) 
					values(right((cast(@cal_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,1, dateadd(mi, 6, getdate()))
				end
			end

		return(0)
	end

	if @TipoMov = 4
		Update ccCallsIN with(rowlock) Set statusCall_id=13 Where cal_id=@cal_id
	else if @TipoMov = 14
		Update ccCallsIN with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

	-- Elimina callback generado por abandono
	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x
	
	update ccoCallBacks with(rowlock)
	set [status] = 1, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	DELETE ccoWorkingTable with(rowlock) WHERE callout_id in (select distinct(callout_id) from ccRIAUpdateCallBack_Abandon with(rowlock) where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x

	select @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani
	from ccCallsIN with(index(IX_ccCallsIn_6),nolock)
	where cal_id = @cal_id
	and statusCall_id = 13

	select @surveycamid = isnull(cam_id,0) from ccinbound where inbound_id = @inbound_id

	if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
		begin
			if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100 
			begin
				insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial) 
				values(right((cast(@cal_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,1, dateadd(mi, 6, getdate()) )
			end
		end

	return(0)
 end

if @TipoMov=7 --OTHER OFFHook_OnXfer
 begin
	if @cal_id<=0
		return(0)

	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 16

		exec ccsp_CstoCalculaCosto @cal_id
		return(0)
	 end

	Update ccCallsIN with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock) 
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

if  @TipoMov=9 --RING CallNoAnswered
 begin
	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 15

		exec ccsp_CstoCalculaCosto @cal_id
	 end
	
	Update ccCallsIN with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock) 
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

set nocount off'

	EXEC(@Sql)

	set @process = 'ccsp_AgentUpdateCallTimes - Alter Procedure'
	set @Sql='ALTER procedure [dbo].[ccsp_AgentUpdateCallTimes]
@IDCall int,
@cal_tXfer smallint,
@cal_tDialog smallint,
@cal_tNotas smallint,
@TipoCall tinyint,
@cal_tRing smallint=0,
@mtmoh smallint = 0,
@isChatCall bit = 0
AS
set nocount on
if @IDCall<=0 
	return(0)

declare @tMinAVRS smallint

if @TipoCall=1 --INBOUND
 begin
    If @mtmoh > 0
		Update ccCallsIN Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
		 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, cal_tMoh=@mtmoh Where cal_id= @IDCall
    Else
       Update ccCallsIN Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
		 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13 Where cal_id= @IDCall

 
	-- Elimina callback generado por abandono
	Declare @ANI_x varchar(19)
	select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn)) where cal_id=@IDCall

	DELETE ccoWorkingTable WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon WHERE cal_ANI=@ANI_x
 end

if @TipoCall=2 --OUTBOUND
 begin
   If @mtmoh > 0
	Update ccoCallsOUT Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
	 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13,  cal_tMoh=@mtmoh, cal_manual=case when @isChatCall=1 then 3 else cal_manual end 
	 Where cal_id=@IDCall
   Else 
    Update ccoCallsOUT Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
	 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, cal_manual=case when @isChatCall=1 then 3 else cal_manual end 
	 Where cal_id=@IDCall

	-- calcula el costo de la llamada
	exec ccsp_CstoCalculaCosto @IDCall
 end

select @tMinAVRS=valor from ccSettings where setting_id=65
select @tMinAVRS=isnull(@tMinAVRS, 5)	

if @cal_tDialog >= @tMinAVRS
 begin
	insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
	return(0)
 end

set nocount off'

	EXEC(@Sql)	

	set @process = 'NuxibaMaintenancePlan - Delete and Create Job'
	set @Sql='USE [msdb]

/****** Object:  Job [NuxibaMaintenancePlan]    Script Date: 04/09/2014 16:19:11 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''NuxibaMaintenancePlan'')
EXEC msdb.dbo.sp_delete_job @job_name=N''NuxibaMaintenancePlan'', @delete_unused_schedule=1

/****** Object:  Job [NuxibaMaintenancePlan]    Script Date: 04/07/2014 16:43:25 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/07/2014 16:43:25 ******/
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
/****** Object:  Step [Check Call Center Activity Task]    Script Date: 04/07/2014 16:43:25 ******/
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
/****** Object:  Step [Check Database Integrity Task]    Script Date: 04/07/2014 16:43:25 ******/
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
/****** Object:  Step [Shrink Database Task]    Script Date: 04/07/2014 16:43:25 ******/
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
/****** Object:  Step [Shrink Log Task]    Script Date: 04/07/2014 16:43:25 ******/
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
/****** Object:  Step [Reorganize Index Task]    Script Date: 04/07/2014 16:43:26 ******/
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
ALTER INDEX [IX_ccLogReciclaje_3] ON [dbo].[ccLogReciclaje] REORGANIZE WITH ( LOB_COMPACTION = ON )
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
ALTER INDEX [IX_ccoCallBacks3] ON [dbo].[ccoCallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks4] ON [dbo].[ccoCallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks5] ON [dbo].[ccoCallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_1] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_10] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_11] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_13] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
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
ALTER INDEX [IX_ccoCallsOutSource_12] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_13] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_14] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
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
ALTER INDEX [IX_ccoLogDials_5] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
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
ALTER INDEX [IX_ccRIACampEspWGConsulta] ON [dbo].[ccRIACampEspWGConsulta] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACampEspWGConsulta_1] ON [dbo].[ccRIACampEspWGConsulta] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACampEspWGConsulta_2] ON [dbo].[ccRIACampEspWGConsulta] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACampsGraph] ON [dbo].[ccRIACampsGraph] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACat_Restrictions] ON [dbo].[ccRIACat_AdminRole] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACat_DialMode] ON [dbo].[ccRIACat_DialMode] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACatFunExt] ON [dbo].[ccRIACatFunExt] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAChat_Log_1] ON [dbo].[ccRIAChat_Log] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChat_TipoMsg] ON [dbo].[ccRIAChat_TipoMsg] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChatFinder] ON [dbo].[ccRIAChatFinder] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccInboundMsgs] ON [dbo].[ccRIAChatInboundMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChatPredefinedMsg] ON [dbo].[ccRIAChatPredefinedMsg] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChats_1] ON [dbo].[ccRIAChats] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChatStatus] ON [dbo].[ccRIAChatStatus] REORGANIZE WITH ( LOB_COMPACTION = ON )
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
ALTER INDEX [IX_ccRIARegistryLists_1] ON [dbo].[ccRIARegistryLists] REORGANIZE WITH ( LOB_COMPACTION = ON )
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
ALTER INDEX [IX_ccRIAWorkGroupUsersConsulta] ON [dbo].[ccRIAWorkGroupUsersConsulta] REORGANIZE WITH ( LOB_COMPACTION = ON )
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
ALTER INDEX [PK_telefonosTransferencia] ON [dbo].[telefonosTransferencia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_clienteCarga] ON [dbo].[xxClienteCarga] REORGANIZE WITH ( LOB_COMPACTION = ON )'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Rebuild Index Task]    Script Date: 04/07/2014 16:43:26 ******/
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
ALTER INDEX [IX_ccLogReciclaje_3] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
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
ALTER INDEX [IX_ccoCallBacks3] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks4] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks5] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_1] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_10] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_11] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_13] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
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
ALTER INDEX [IX_ccoCallsOutSource_12] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_13] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_14] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
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
ALTER INDEX [IX_ccoLogDials_5] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
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
ALTER INDEX [IX_ccRIACampEspWGConsulta] ON [dbo].[ccRIACampEspWGConsulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACampEspWGConsulta_1] ON [dbo].[ccRIACampEspWGConsulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACampEspWGConsulta_2] ON [dbo].[ccRIACampEspWGConsulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACampsGraph] ON [dbo].[ccRIACampsGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACat_Restrictions] ON [dbo].[ccRIACat_AdminRole] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACat_DialMode] ON [dbo].[ccRIACat_DialMode] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACatFunExt] ON [dbo].[ccRIACatFunExt] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAChat_Log_1] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChat_TipoMsg] ON [dbo].[ccRIAChat_TipoMsg] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChatFinder] ON [dbo].[ccRIAChatFinder] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccInboundMsgs] ON [dbo].[ccRIAChatInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY  = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChatPredefinedMsg] ON [dbo].[ccRIAChatPredefinedMsg] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChats_1] ON [dbo].[ccRIAChats] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChatStatus] ON [dbo].[ccRIAChatStatus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
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
ALTER INDEX [IX_ccRIARegistryLists_1] ON [dbo].[ccRIARegistryLists] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
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
ALTER INDEX [IX_ccRIAWorkGroupUsersConsulta] ON [dbo].[ccRIAWorkGroupUsersConsulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
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
ALTER INDEX [PK_telefonosTransferencia] ON [dbo].[telefonosTransferencia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_clienteCarga] ON [dbo].[xxClienteCarga] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Statistics Task]    Script Date: 04/07/2014 16:43:26 ******/
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
UPDATE STATISTICS [dbo].[ccNPALocalPrefixes] 
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
UPDATE STATISTICS [dbo].[ccRateByCarrier] 
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
UPDATE STATISTICS [dbo].[ccRIACampEspWGConsulta] 
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
UPDATE STATISTICS [dbo].[ccRIAChatFinder] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatInboundMsgs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatInboundPredefinedMsg] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatMailbox] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatMsg] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatPredefinedMsg] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChats] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatStatus] 
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
UPDATE STATISTICS [dbo].[ccRIAWorkGroupUsersConsulta] 
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
If exists (select name from sysobjects where name = ''''migration'''')
	begin
		UPDATE STATISTICS [dbo].[migration] 
		WITH FULLSCAN
	end
If exists (select name from sysobjects where name = ''''migrationAVRS'''')
	begin
		UPDATE STATISTICS [dbo].[migrationAVRS] 
		WITH FULLSCAN
	end
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
WITH FULLSCAN'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clean Up History Task]    Script Date: 04/07/2014 16:43:26 ******/
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
/****** Object:  Step [Back Up Database Task]    Script Date: 04/07/2014 16:43:26 ******/
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
/****** Object:  Step [Maintenance Clean Up Task]    Script Date: 04/07/2014 16:43:26 ******/
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
