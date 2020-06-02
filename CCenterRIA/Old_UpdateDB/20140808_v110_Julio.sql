/*
Autor: Jesus Gallardo
Fecha: 2014/08/08
Descripcion:
	Se crea tabla ccInboundAgentesBackup
	Se crea tabla ccCampsAgenteBackup
	Se crea tabla ccSupervisorCamBackup
	
	Se agrega indice IX_cccallsreject en cccallsreject 
	Se agrega indice IX_ccriachats en ccriachats
	Se agrega indice IX_ivrcallsin en ivrcallsin 
	Se agrega indice IX_ivroptions en ivroptions
	Se agrega indice IX_ccLogAgentesDia_Dialog en ccLogAgentesDia_Dialog
	Se agrega indice IX_ccoCallBacks6 en ccoCallBacks

	Se inserta ccTipoMsgs nuevo tipo musica en hold personalizado
	Se actuliza la detalle de la configuracion asterisk integration setting 160
	
	Se agrega a Stored procedure ccsp_ADMCamp cambio para guardar relacion de supervisores con Campañas en version Integrada
	Se agrega a Stored procedure ccsp_ADMdelAgent cambio para guardar relacion de supervisores con Campañas en version Integrada
	Se agrega a Stored procedure ccsp_ADMEspec cambio para guardar relacion de supervisores con Campañas en version Integrada
	Se agrega a Stored procedure ccsp_RIA_ABCAreas cambio para guardar relacion de supervisores con Campañas en version Integrada
	Se agrega a Stored procedure ccsp_RIA_ABCWorkGroups cambio para guardar relacion de supervisores con Campañas en version Integrada
	Se agrega a Stored procedure ccsp_RIAManageWG cambio para guardar relacion de supervisores con Campañas en version Integrada	
	Se agrega a Stored procedure ccsp_RIAManageAreas cambio para guardar relacion de supervisores con Campañas en version Integrada		
	
	Se modifica SP ccsp_RIAConfEspec para agregar parametro si es valida la cuenta correo
	Se modifica SP ccsp_DLRgetDialPrefix mensajes moh para campañas del hold
	Se modifica SP ccsp_IVRChecaInboundHorario mensajes moh para ACD del hold
	Se modifica SP ccsp_OUTUpdateDialJob nuevo tipo resultado desconocido
	Se modifica SP ccsp_RIA_mnuReciclar

	Se crea Job DatabaseCentinella para perfomance de indices
	Se modifica Job CW Delete old records
	Se modifica Job NuxibaMaintenancePlan para deshabilitarlo

Version requerida: 109
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '110'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

	set @process = 'CREATE table  - ccInboundAgentesBackup'
		set @Sql='
		if  not exists(SELECT * FROM sysobjects WHERE name=''ccInboundAgentesBackup'') 
	
		begin 

			CREATE TABLE [dbo].[ccInboundAgentesBackup](
			[User_id] [smallint] NOT NULL,
			[Inbound_id] [smallint] NOT NULL,
			[cli_id] [int] NULL,
			[prioridad] [int] NOT NULL,
			[skill] [tinyint] NOT NULL,
			[rel_id] [int] NOT NULL,
			[IDWG] [int] NOT NULL
			) ON [PRIMARY]
		end
		'	
		EXEC(@Sql)

	set @process = 'CREATE table  - ccCampsAgenteBackup'
		set @Sql='
		if  not exists(SELECT * FROM sysobjects WHERE name=''ccCampsAgenteBackup'') 
	
		begin 
			CREATE TABLE [dbo].[ccCampsAgenteBackup](
			[user_id] [smallint] NULL,
			[cam_id] [smallint] NOT NULL,
			[prioridad] [tinyint] NOT NULL,
			[skill] [tinyint] NOT NULL,
			[rel_id] [int] NOT NULL,
			[IDWG] [int] NOT NULL
			) ON [PRIMARY]
			
		end
		'	
		EXEC(@Sql)

	set @process = 'CREATE table  - ccSupervisorCamBackup'
		set @Sql='
		if  not exists(SELECT * FROM sysobjects WHERE name=''ccSupervisorCamBackup'') 
	
		begin 
			CREATE TABLE [dbo].[ccSupervisorCamBackup](
			[user_id] [int] NOT NULL,
			[cam_id] [int] NOT NULL,
			[tipo] [int] NOT NULL,
			[IDWG] [int] NOT NULL,
			[monitored] [int] NULL,
			[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL		 
		) ON [PRIMARY]
			
		end
		'	
		EXEC(@Sql)

	set @process = 'Create - index  IX_cccallsreject in cccallsreject '
	set @Sql='CREATE NONCLUSTERED INDEX [IX_cccallsreject] ON [dbo].[cccallsreject]
(
	[cal_inicio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'Create - index  IX_ccriachats in ccriachats '
	set @Sql='CREATE NONCLUSTERED INDEX [IX_ccriachats] ON [dbo].[ccriachats]
(
	[chatDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'Create - index  IX_ivrcallsin in ivrcallsin '
	set @Sql='CREATE NONCLUSTERED INDEX [IX_ivrcallsin] ON [dbo].[ivrcallsin]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'Create - index  IX_ivroptions in ivroptions '
	set @Sql='CREATE NONCLUSTERED INDEX [IX_ivroptions] ON [dbo].[ivroptions]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'Create - index  IX_ccLogAgentesDia_Dialog in ccLogAgentesDia_Dialog '
	set @Sql='CREATE NONCLUSTERED INDEX [IX_ccLogAgentesDia_Dialog] ON [dbo].[ccLogAgentesDia_Dialog]
(
	[fecha_Dialog] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)
	
	set @process = 'Create - index  IX_ccoCallBacks6 in ccoCallBacks '
	set @Sql='CREATE NONCLUSTERED INDEX [IX_ccoCallBacks6] ON [dbo].[ccoCallBacks]
(
	[callout_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'Insert -  ccTipoMsgs'
	set @Sql='insert ccTipoMsgs values (15, ''Music On Hold'',''CustomMOH'')'

	EXEC(@Sql)

	set @process = 'Update -  ccSettings'
	set @Sql='update ccSettings set detalle=''num_channels|offset|ip|user|pwd|tcp_port|extensions (5|0|192.168.1.137|administrator|Nuxiba2013|5038|*.gsm;*.wav;)'' where setting_id=160'

	EXEC(@Sql)

	set @process = 'Alter PROCEDURE - ccsp_ADMCamp'
	set @Sql='ALTER PROCEDURE [dbo].[ccsp_ADMCamp]
		@Descripcion varchar(40),
		@cam_id smallint,
		@cli_id smallint=1,
		@Tipo tinyint, -- 1=ALTA, 2=Modificacion, 2=Eliminar
		@ventana tinyint = 2, -- 0 Falso, 1 Verdadero, 2 Sin Cambio
		@timer int = 2,
		@Activa tinyint = 2,
		@user_id int=0
		AS
		set nocount on
		--ccsp_ADMCamp ''ABCD'', 1, 0, 2, 1 , 1 , 1
		declare @new_cam_id smallint
		declare @idioma as bit

		Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

		--HLAS no crear campa±as sin cliente asignado 20050104
		if not exists(select cli_id from ccClientes where cli_id = @cli_id)
			return(0)

		select @cli_id = max(cli_id) from ccClientes
		if isnull(@cli_id,0)=0 
		 begin
			select 0, case @idioma when 1 then ''Please check Clients Catalogue and make sure there is at least one client''
			else ''Favor de revisar el Catálogo de Clientes y verificar que exista alguno'' end
			return(0)
		 end 

		if @Tipo in(1,4)
		begin
			if exists (select cam_descripcion from ccCamps where cam_descripcion = @Descripcion)
			 begin
				select 0, case @idioma when 1 then ''Name in Use'' else ''Nombre en Uso'' end
				return(0)
			 end

			Insert ccCamps (cam_descripcion, cli_id, cam_ShowCalifWnd, cam_StartTimerOnHangUp)
			 Values(@Descripcion, @cli_id, @ventana, @timer)
			select @new_cam_id = SCOPE_IDENTITY()
			
			if @new_cam_id is null and @Tipo=4
			 begin
				select 0, case @idioma when 1 then ''Error creating campaign'' else ''Error al crear campaña'' end
				return(0)
			 end

			insert into ccoDialerCamp (dialer_id, cam_id)
			 select dialer_id, @new_cam_id as cam_id from ccoDialers where status=1

			insert into ccCalifCamp (calif_id, cam_id, tipo)
			 select calif_id, @new_cam_id as cam_id, 1 as tipo from ccTipoCalifOUT

			if @user_id > 1 and exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
			 begin
				Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select @user_id, @new_cam_id, 1, IDWG from ccRIAWorkGroupUsers where User_id=@user_id
			 end

			else if @user_id > 1 and not exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
			 begin
				Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select @user_id, @new_cam_id, 1, 0
			 end

			select -1, case @idioma when 1 then ''Campaign: '' + upper(@Descripcion) + '' Added Succesfully''
			else ''Campaña: '' + upper(@Descripcion) + '' Dada de Alta'' end
			return(0)
		 end

		if @Tipo=2
		 begin
			Update ccCamps set cam_descripcion= @Descripcion where cam_id = @cam_id
			if @ventana <> 2 Update ccCamps set cam_ShowCalifWnd=@ventana where cam_id = @cam_id
			if @timer <> 2 	Update ccCamps set cam_StartTimerOnHangUp=@timer where cam_id = @cam_id
			if @Activa <> 2 Update ccCamps set cam_activo=@Activa where cam_id = @cam_id

			select -1, case @idioma when 1 then ''Campaign: '' + upper(@Descripcion) + '' Modified''
			else ''Campaña: '' + upper(@Descripcion) + '' Modificada'' end
			return(0)
		 end

		if @Tipo=3
		 begin
		 	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @cam_id

			delete from ccCampsAgente where cam_id = @cam_id
			delete from ccoDialerCamp where cam_id = @cam_id
			delete from ccoWorkingTable where cam_id = @cam_id
			delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @cam_id)
			delete from ccoLogDials where cam_id = @cam_id
			delete from ccoCallsOut where cam_id = @cam_id
			delete ccoCallsOut where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @cam_id)
			delete from ccoCallsOutSource where cam_id = @cam_id

			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCamBackup B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @cam_id and A.tipo = 1
			
			Delete ccSupervisorCam where cam_id  = @cam_id and tipo = 1
			
			if exists(select cam_id from ccCampsAgente where cam_id = @cam_id)
			 begin
				select 0, case @idioma when 1 then ''There are Agents Related to this Campaign''
				else ''Existen Agentes Relacionados con esta Campaña'' end
				return(0)
			 end
			
			if exists(select cam_id from ccoCallsOut where cam_id = @cam_id)
			 begin
				select 0, case @idioma when 1 then ''There are Call Registries Related with this Campaign''
				else ''Existen Registros de Llamadas Relacionados con esta Campaña'' end
				return(0)
			 end

			insert ccCampsMovs (cam_id, TipoMov, NewRecords,  CBRecords, user_id) 
			 Values(@cam_id, 5, 0,0,@user_id)
			Delete ccCamps Where cam_id = @cam_id

			select -1, case @idioma when 1 then ''Campaign: '' + upper(@Descripcion) + '' Deleted''
			else ''Campaa: '' + upper(@Descripcion) + '' Eliminada'' end
			return(0)
		 end

		set nocount off'
	
		EXEC(@Sql)
		

		set @process = 'Alter PROCEDURE - ccsp_ADMdelAgent'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_ADMdelAgent]
		@user_id int
		AS
		insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and  A.user_id = @user_id

		delete from ccSupervisorCam where user_id = @user_id
		delete from ccMenuUser where id_User = @user_id
		delete from ccCampsAgente where user_id = @user_id
		delete from ccInboundAgentes where user_id = @user_id

		insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user_id 
		insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentesBackup A left join ccInboundAgentes B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@user_id

		update ccPosicion set user_id = 0 where user_id = @user_id

		update ccUsers set status = 0 where user_id = @user_id'	

		EXEC(@Sql)

		set @process = 'Alter PROCEDURE - ccsp_ADMEspec'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_ADMEspec]
		@Descripcion varchar(40),
		@Inbound_id smallint,
		@cli_id smallint,
		@Tipo tinyint, -- 1=ALTA, 2=Modificacion
		@Show tinyint = 2,
		@Timer tinyint = 2,
		@user_id int = 0
		AS
		set nocount on
		declare @new_Inbound_id smallint
		declare @idioma as bit
		Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

		if @Tipo=1
		 begin
			if exists(select Descripcion from ccInbound where Descripcion = @Descripcion)
			 begin
				select 0, case @idioma when 1 then ''The ACD group already exists''
				else ''La especialidad ya existe'' end
				return(0)
			 end

			Insert ccInbound (Descripcion, cli_id, ShowCalifWnd, StartTimerOnHangUp)
			 Values(@Descripcion, @cli_id, @Show, @Timer)
			select @new_Inbound_id = SCOPE_IDENTITY()
			
			insert into ccCalifCamp (calif_id, cam_id, tipo)
			 select calif_id, @new_Inbound_id as cam_id, 0 as tipo from ccTipoCalif

			if @user_id > 1 and exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
			 begin
				Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select @user_id, @new_Inbound_id, 0, IDWG from ccRIAWorkGroupUsers where User_id=@user_id
			 end

			else if @user_id > 1 and not exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
			 begin
				Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select @user_id, @new_Inbound_id, 0, 0
			 end
			 
			select -1, case @idioma when 1 then ''ACD group : '' + upper(@Descripcion) + '' added succesfully''
			else ''Especialidad: '' + upper(@Descripcion) + '' dada de alta'' end
			return(0)
		 end

		if @Tipo=2
		 begin
			--Update ccInbound set Descripcion= @Descripcion, ShowCalifWnd=@Show,  StartTimerOnHangUp=@Timer where Inbound_id = @Inbound_id
			Update ccInbound set Descripcion= @Descripcion where Inbound_id = @Inbound_id
			if @Show <> 2 Update ccInbound set ShowCalifWnd=@Show where Inbound_id = @Inbound_id
			if @Timer <> 2 Update ccInbound set StartTimerOnHangUp = @Timer  where Inbound_id = @Inbound_id

			select -1, case @idioma when 1 then ''ACD group : '' + upper(@Descripcion) + '' updated''
			else ''Especialidad: '' + upper(@Descripcion) + '' modificada'' end
			return(0)
		 end

		if @Tipo=3
		 begin
			if exists(select Inbound_id from ccInboundAgentes where Inbound_id = @Inbound_id)
			 begin
				select 0, case @idioma when 1 then ''There are Agents Related to this ACD group ''
				else ''Existen Agentes Relacionados con esta Especialidad'' end
				return(0)
			 end

			if exists( select Inbound_id from ccCallsIN where Inbound_id = @Inbound_id)
			 begin
				select 0, case @idioma when 1 then ''There are Call Registries Related to this ACD group ''
				else ''Existen Registros de Llamadas Relacionados con esta Especialidad'' end
				return(0)
			 end

			Delete ccInbound Where Inbound_id = @Inbound_id
			Delete ccInboundHorarios Where Inbound_id = @Inbound_id
			Delete ccInboundMsgs Where Inbound_id = @Inbound_id
			
			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) 
			select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A 
				left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and  A.cam_id  = @Inbound_id
				

			Delete ccSupervisorCam where cam_id  = @Inbound_id and tipo = 0

			select -1, case @idioma when 1 then ''ACD group : '' + upper(@Descripcion) + '' deleted''
			else ''Especialidad: '' + upper(@Descripcion) + '' Eliminada'' end
			return(0)
		 end

		set nocount off'	
		
		EXEC(@Sql)

		set @process = 'Alter PROCEDURE - ccsp_RIA_ABCAreas'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
		@option smallint,
		@IDArea smallint,
		@Descripcion varchar(40)
		AS
		set nocount on
		if @option=1 --Selected Area
		begin
		declare @maxchats as smallint

		Select a.IDArea, AreaName, maxChats as maxChats  from ccRIACat_Areas a 
		left join (select IDArea , MAX(isnull(maxChats,0)) as maxChats from ccInbound GROUP BY IDArea) b
		on a.IDArea = b.IDArea
		where StatusArea=1 and isnull(a.IDArea,0)=case isnull(@IDArea,0) 
		when 0 then isnull(a.IDArea,0) else @IDArea end
		order by AreaName
		return(0)
		end

		if @option=2 --Insert Area
		begin
		if exists(select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
		 begin
			select -1--, Nombre en Uso
			return(0)
		 end

		Insert into ccRIACat_Areas (AreaName) values (@Descripcion)			
		select 1, scope_identity()--, Area Insertada
		return(0)
		end

		if @option=3 --Update Area
		begin
		if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
			Update ccRIACat_Areas set AreaName=@Descripcion where IDArea=@IDArea

		return(0)
		end

		if @option=4 --Delete Area
		begin	
		if (exists(select IDArea from ccUsers where IDArea=@IDArea) 
		 or exists(select IDArea from ccCamps where IDArea = @IDArea)
		 or exists(select IDArea from ccInbound where IDArea=@IDArea)) 
		 and (select valor from ccSettings where setting_id=95)<>1
		 begin
			select -1
			return(0)
		 end

		declare @DWorkGroups as varchar(500)

		insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select user_id,cam_id,prioridad,skill,rel_id,IDWG from ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea) 
		insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

		Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
		Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

		insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select user_id,cam_id,tipo,IDWG,monitored from ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

		Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

		delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
		delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
		delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
		where cam_id in (select cam_id from ccCamps where IDArea=@IDArea))

		Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)
		Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)

		Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
		Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
		Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)

		select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea=@IDArea
		Delete from ccRIAAreaWorkGroup where IDArea=@IDArea

		if (select valor from ccSettings where setting_id=95)=1
		 begin
			Update ccInbound set IDArea=NULL, status=0 where IDArea=@IDArea	
			Update ccCamps set IDArea=NULL where IDArea=@IDArea
			Update ccUsers set IDArea=NULL where IDArea=@IDArea
		 end

		Update ccRIACat_Areas set StatusArea=0 where IDArea=@IDArea
		select @DWorkGroups
		return(0)
		end
		return(0)
		set nocount off'	

		EXEC(@Sql)

		set @process = 'Alter PROCEDURE - ccsp_RIA_ABCWorkGroups'
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

		 	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.IDWG = @IDWG
			insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.IDWG = @IDWG
		 	
			Delete from ccCampsAgente where IDWG = @IDWG
			Delete from ccInboundAgentes where IDWG = @IDWG

			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.IDWG = @IDWG

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
				begin
					insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.IDWG=@IDWG and A.cam_id=@IDCampEsp
					Delete from ccCampsAgente where IDWG=@IDWG and cam_id=@IDCampEsp
				end
			else if @Type = 0 
				begin
					insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.IDWG=@IDWG and A.inbound_id=@IDCampEsp
					Delete from ccInboundAgentes where IDWG=@IDWG and inbound_id=@IDCampEsp
				end

			Delete from ccRIACampEspWG where IDWG=@IDWG and IdCampEsp=@IDCampEsp and Tipo=@Type

			return(0)
		 end
		 
		return(0)
		set nocount off'	

		EXEC(@Sql)

		set @process = 'Alter PROCEDURE - ccsp_RIAManageWG'
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

				if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@UserId) begin	
					insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@UserId)
				end
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
			 	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@UserId and A.IDWG=@IDWG
				insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@UserId and A.IDWG=@IDWG

			 	delete from cccampsagente where user_id=@UserId and IDWG=@IDWG
				delete from ccInboundagentes where user_id=@UserId and IDWG=@IDWG
				select @Type
				return(0)
			 end
			 
			--else if @Type in(2, 6) -- Supervisor
			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@UserId and A.IDWG=@IDWG
			delete ccSupervisorCam where user_id=@UserId and IDWG=@IDWG
			select @Type
			return(0)
		end
		return(0)
		set nocount off'	

		EXEC(@Sql)

		set @process = 'Alter PROCEDURE - ccsp_RIAManageAreas'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAManageAreas]
		@option tinyint,
		@IDArea smallint = 0,
		@InsertUserId smallint =null,
		@DeleteUserId varchar(255)=null,
		@InsertCamId smallint=null,
		@DeleteCamId smallint=null,
		@InsertACDGroupId smallint=null,
		@DeleteACDGroupId smallint=null
		as
		set nocount on

		if @option = 1 -- Insert User Area
		 begin
			if not exists(select IDArea from ccUsers where IDArea = @IDArea AND User_id = @InsertUserId)
			 begin
				Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @InsertUserId
				return(0)
			 end	
			 
			select 1
			return(0)
		 end

		if @option = 3 -- Insert camp area
		 begin
			if not exists(select IDArea from ccCamps where IDArea = @IDArea and cam_id = @InsertCamId)
			 begin
				Update ccCamps set IDArea = case @IDArea when 0 then null else @IDArea end
				where cam_id = @InsertCamId
				return(0)
			 end

			select 1
			return(0)
		 end

		if @option = 4 -- Delete camp area
		 begin
		 	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId
		 
		 	delete from ccCampsAgente where cam_id = @DeleteCamId
			delete from ccoDialerCamp where cam_id = @DeleteCamId
			delete from ccoWorkingTable where cam_id = @DeleteCamId

			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1	

			delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
			delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	
			delete from ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @DeleteCamId)

			if exists(select cam_id from ccInbound where cam_id=@DeleteCamId)
			 begin
				select -4
				return(0)	 
			 end

			Update ccCamps set IDArea= null where cam_id=@DeleteCamId--, cam_activo = 0 
			return(0)
		 end

		if @option = 5 -- Insert ACDGroup area
		 begin
			if not exists(select IDArea from ccInbound where IDArea = @IDArea and Inbound_Id = @InsertACDGroupId)
			 begin
				Update ccInbound set IDArea = @IDArea, status = 1 where Inbound_id = @InsertACDGroupId
				return(0)
			 end

			select 1
			return(0)
		 end

		if @option = 6 -- Delete ACDGroup area
		 begin
		 	insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

			delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
			delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId

			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId and A.tipo = 0

			delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
			delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
			delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

			Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId
			select 1
			return(0)
		 end

		if @option in (2, 9, 10, 11)
		 begin
		 	declare @Type tinyint
			select @Type = TipoUser_id from ccUsers where User_id = @DeleteUserId
			
			if @option in (2, 10, 11) -- Delete User area
			 begin
				if @Type = 1 -- Agente
				 begin

					insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
					insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

					delete from ccCampsAgente where user_id = @DeleteUserId
					delete from ccInboundAgentes where user_id = @DeleteUserId
				 end

				else if @Type in (2, 6) -- Supervisor
				begin
					insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
					delete from ccSupervisorCam where user_id = @DeleteUserId
				end

				delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
				
				if @option=2
				 begin
					update ccPosicion set user_id = 0 where user_id = @DeleteUserId
					update ccUsers set IDArea = null where user_id = @DeleteUserId	
				 end
				return(0)
			end

			declare @UserWG varchar(100)
			-- @option = 9 -- Delete User area and get his workgroups

			select @UserWG = IDWG from ccRIAWorkGroupUsers where user_id = @DeleteUserId

			if @Type = 1 -- Agente
			 begin
			 	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
				insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

				delete from ccCampsAgente where user_id = @DeleteUserId
				delete from ccInboundAgentes where user_id = @DeleteUserId
			 end

			if @Type in (2, 6) -- Supervisor
			 begin
			 	insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId

			 	delete from ccSupervisorCam where user_id = @DeleteUserId
				delete from ccMenuUser where id_User = @DeleteUserId
			 end

			delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
			update ccPosicion set user_id = 0 where user_id = @DeleteUserId
			
			if @option <> 11
				update ccUsers set IDArea = null where user_id = @DeleteUserId
			
			select @UserWG, @Type
			return(0)
		 end

		declare @AllWG varchar(400), @CurrentWG varchar(400), @AreaDescripcion varchar(40)

		if @option = 7 -- Delete camp area
		 begin
		 	if exists(select cam_id from ccInbound where cam_id=@DeleteCamId)
			begin
				update ccInbound set cam_id = null where cam_id=@DeleteCamId		 
			end

			select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
			from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId

			delete from ccCampsAgente where cam_id = @DeleteCamId
			delete from ccoWorkingTable where cam_id = @DeleteCamId or callout_id 
			 in (select callout_id from ccoCallsOutSource where cam_id = @DeleteCamId)

			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1

			delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
			delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	

			select @CurrentWG = coalesce(@CurrentWG + '','', '''') + CAST(IDWG as varchar(400)) 
			from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

			select @AreaDescripcion = area.AreaName
			from ccCamps as camp with(nolock)inner join ccRIACat_Areas as area 
			 with(nolock) on camp.IDArea = area.IDArea
			where camp.cam_id = @DeleteCamId
			Update ccCamps set IDArea = null where cam_id = @DeleteCamId

			If @CurrentWG is null
				set @CurrentWG = 0

			If @AllWG is null
				set @AllWG = 0

			select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
			return(0)
		 end

		if @option = 8 --Delete ACDGroup area
		 begin
			if (select cam_id from ccInbound where Inbound_id = @DeleteACDGroupId) is not null
			begin
				update ccInbound set cam_id = null where Inbound_id = @DeleteACDGroupId
			end

			select @AllWG = coalesce(@AllWG + '','', '') + CAST(IDWG as varchar(400)) 
			from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

			insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

			delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
			delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId

			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId and A.tipo = 0

			delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
			delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
			delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

			select @CurrentWG = coalesce(@CurrentWG + '','', '') + CAST(IDWG as varchar(400)) 
			from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

			select @AreaDescripcion = area.AreaName
			from ccInbound as ACD with(nolock) inner join ccRIACat_Areas as area 
			 with(nolock) on ACD.IDArea = area.IDArea
			where ACD.Inbound_id = @DeleteACDGroupId
			Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId

			If @CurrentWG is null
				set @CurrentWG = 0

			If @AllWG is null
				set @AllWG = 0

			select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
			return(0)
		 end

		return(0)
		set nocount off'	

		EXEC(@Sql)


		set @process = 'ALTER - SP ccsp_RIAConfEspec'
		set @Sql='ALTER procEDURE [dbo].[ccsp_RIAConfEspec] 
@User_id int 
AS 
set nocount on

declare @sql nvarchar(max)

if not exists (SELECT * FROM sysobjects WHERE type = ''U'' AND name = ''ContactMeanIn'') begin
	set @sql=''select A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd, 
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat, A.inactiveChatTime, A.maxChats, A.chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
A.startStopRecording,'''''''' as nameMail,'''''''' as conexionInfo,'''''''' as connUser,'''''''' as connPass,3 as numMessages,10 as timeAlertMessage, 0 as Active
from ccInbound A where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (''+convert(nvarchar(max),@User_id)+'', 2))''	

end
else begin
	set @sql=''select A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd, 
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat, A.inactiveChatTime, A.maxChats, A.chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
A.startStopRecording,isnull(B.name,'''''''') as nameMail,isnull(B.conexionInfo,'''''''') as conexionInfo,isnull(B.connUser,'''''''') as connUser,
isnull(B.ConnPass,'''''''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage, isnull(B.IsActive,0) as Active
from ccInbound A 
left join ContactMeanIn B on A.inbound_id=B.inboundId
where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (''+convert(nvarchar(max),@User_id)+'', 2))''
	end

exec (@sql)

return(0)
set nocount off'
	
	EXEC(@Sql)

	set @process = 'ALTER - SP ccsp_DLRgetDialPrefix'
	set @Sql='ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
@cam_id smallint=0,
@iPortNumber smallint = 0,
@phone varchar(30) = ''''
as
declare @prefix as varchar(15)
declare @ani as varchar(32)

declare @call_record_cam as tinyint
declare @pais as tinyint 

select @pais = valor from ccsettings where setting_id = 104
select @call_record_cam = call_record from ccCamps where cam_id = @cam_id

set @prefix =''''
-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

-- Prefijo por campaña,
if @prefix =''''
	select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

-- Prefijo general
if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
	select @prefix = valor from ccsettings where setting_id =101

-- Ani
set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

--AnswerMachine Message Files
DECLARE @MsgFiles VARCHAR(8000) 
SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000) 
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

select @prefix as sDialPrefix, cam_tNoContesta as tNoContesta,
case when @ani = '''' then ani else @ani end as ani, detectAnswerMachine, detectVoiceMail,
dbo.EnableCallRecord(@call_record_cam,@pais,@phone) as call_record, @MsgFiles as messageFiles, @MohFiles as mohFiles
from ccCamps where cam_id = @cam_id'
	
	EXEC(@Sql)

	set @process = 'ALTER - SP ccsp_IVRChecaInboundHorario'
	set @Sql='ALTER PROCEDURE [dbo].[ccsp_IVRChecaInboundHorario]
@inbound_id int
AS
set nocount on
declare @fecha datetime
declare @dia smallint
declare @hora smallint
declare @minuto smallint
declare @Cuantos smallint
declare @bnocturno smallint
declare @tel_noct varchar(14)
declare @tel_maxqueue varchar(14)
declare @tel_maxwait varchar(14)
declare @tel_outservice varchar(14)
declare @tHoldCall int
declare @OutOFService tinyint
declare @Active tinyint
declare @stopRecording bit
declare @MohFiles varchar(8000)

	SET DATEFIRST 1

	select @fecha =  getdate()
	select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)
	if ( @dia=1 )	--LUNES
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND LUNES = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	if @dia=2	--MARTES
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND MARTES = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	if @dia=3	--MIERCOLES
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND MIERCOLES = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	if @dia=4	--JUEVES
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND JUEVES = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	if @dia=5	--VIERNES
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND VIERNES = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	if @dia=6	--SABADO
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND SABADO = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	if @dia=7	--DOMINGO
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND DOMINGO = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	--- Para ver si esta Activa la Especialidad
	select @Active = count(*)
	from ccInbound
	where Inbound_id = @inbound_id
	and Status =1
	--- Para ver si esta en Operacion o No esta Campaña
	select @OutOFService = count(*)
	from ccInbound
	where Inbound_id = @inbound_id
	and standby = 0
	IF ( @OutOFService =1 AND @Active=1 and (select valor from ccsettings where setting_id = 4) = 1)
	BEGIN
--			SI ESTA EN SERVICO
		select  @tHoldCall = tMaxWaitCall, @bnocturno =bnocturno, @stopRecording=stopRecording,
			@tel_noct=tel_noct, @tel_maxqueue=tel_maxqueue, @tel_maxwait=tel_maxwait, @tel_outservice=tel_outservice
			from ccInbound I
			Where I.Inbound_id = @inbound_id

		--Custom MOH Files
		SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
		FROM ccInboundMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE Inbound_id = @Inbound_ID and TYPE = 15 ORDER BY orden
	END
	ELSE
	BEGIN
		IF ( @OutOFService = 0 and (select valor from ccsettings where setting_id = 4) = 1)
		BEGIN -- ESPECIALIDAD NO ACTIVA
			select @Cuantos= -1, @tHoldCall =0, @bnocturno ='''', @tel_noct ='''', @tel_maxqueue='''', @tel_maxwait='''', @tel_outservice='''', @MohFiles=''''
			--from ccInbound
			--Where Inbound_id = @inbound_id
		END
		IF ( @Active = 0 )
		BEGIN -- ESPECIALIDAD FUERA DE SERVICIO TEMPORAL
			select @Cuantos= -2, @tHoldCall =0, @bnocturno ='''', @tel_noct ='''', @tel_maxqueue='''', @tel_maxwait='''', @tel_outservice=tel_outservice, @MohFiles=''''
			from ccInbound
			Where Inbound_id = @inbound_id
		END 
	END
	SET DATEFIRST 7

	select ''Cuantos''=@Cuantos, ''tHoldCall''=@tHoldCall, ''bNocturno''=1, ''tel_MaxWait''=@tel_maxwait, ''tel_MaxQueue''=@tel_maxqueue, ''tel_Noct''=@tel_noct, ''tel_outservice''=@tel_outservice, ''stopRecording''=@stopRecording, ''mohFiles''=@MohFiles
set nocount off'
	
	EXEC(@Sql)

	set @process = 'ALTER - SP ccsp_OUTUpdateDialJob'
	set @Sql='ALTER PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
@callout_id int,
@CallResultDial tinyint
as
set nocount on
/*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine	*/
declare @nOcupado tinyint, @nNoContesta tinyint, @nFax tinyint, @nContestadora tinyint
declare @nShortCall tinyint, @nOtro tinyint, @cam_NoInt_ocupado tinyint, @cam_NoInt_graba tinyint
declare @cam_ocupado smallint, @cam_inter_ocupado smallint, @cam_nocontesto smallint
declare @cam_graba smallint, @cam_inter_graba smallint, @cam_inter_nocontesto smallint
declare @cam_fax smallint, @cam_inter_fax smallint
declare @DateNextDial smalldatetime, @DateNewDial smalldatetime, @cam_id smallint
declare @ExisteWT tinyint, @cam_NoInt_fax tinyint, @cam_NoInt_nocontesto tinyint
declare @sSQL nvarchar(max), @Telefono varchar(15)

SELECT @cam_id=cam_id, @nOcupado=IsNull(nOcupado, 0), @nNoContesta=IsNull(nNoContesta,0),
	@nFax=IsNull(nFax, 0), @nContestadora=IsNull(nContestadora, 0),@nShortCall=IsNull(nShortCall,0),
	@nOtro=IsNull(nOtro,0),@DateNextDial=cal_fechaDial
FROM ccoWorkingTable WHERE callout_id = @callout_id

select @ExisteWT=case when @cam_id is not null then 1 else 0 end


IF @CallResultDial=20 -- CONTACTADO
 BEGIN
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial=1 -- CONTESTO
 BEGIN
	if (select abandonCallback from ccCamps where cam_id = @cam_id) = 1 begin
		EXEC ccsp_OUTCancelDialJOB @callout_id, 1, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	end
	else begin
		EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	end
	return(0)
 END

IF @CallResultDial in (2,12) -- OCUPADO
 BEGIN
	SELECT @cam_ocupado =cam_ocupado, @cam_inter_ocupado=cam_inter_ocupado, @cam_NoInt_ocupado=cam_NoInt_ocupado, @nOcupado= @nOcupado+1
	FROM ccCamps WHERE cam_id=@cam_id
	
	IF @cam_ocupado=1 -- Opcion Ocupado HABILITADA
	 BEGIN
		IF @nOcupado>@cam_NoInt_ocupado or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		-- Change priority and obtain the next telephone
		update ccoCallsOutSource set nNoContesta=case when nNoContesta < 255 then isnull(nNoContesta,0)+1 else nNoContesta end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT
		
		SELECT @DateNewDial=dateadd(mi, @cam_inter_ocupado, getdate())

		-- Programacion de CALLBACK
		IF @DateNewDial>@DateNextDial
		 BEGIN	-- Nueva fecha de Call BACk
			UPDATE  ccoWorkingTable SET nOcupado=@nOcupado, cal_fechaDial=@DateNewDial, cal_status=1 WHERE callout_id = @callout_id
			return(0)
		 END

		-- Mantiene la fecha de Call BACK
		UPDATE  ccoWorkingTable SET nOcupado=@nOcupado, cal_status=1, cal_telefono=@Telefono  WHERE callout_id = @callout_id

		return(0)
	 END

-- ELSE: Opcion Ocupado DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
  END

IF @CallResultDial in (3,5,8) -- NO CONTESTA
 BEGIN
	--select NO Contesta
	SELECT @cam_nocontesto =cam_nocontesto, @cam_inter_nocontesto=cam_inter_nocontesto, @cam_NoInt_nocontesto=cam_NoInt_nocontesto, @nNoContesta=@nNoContesta+1
	FROM ccCamps WHERE cam_id=@cam_id

	--SELECT @cam_nocontesto, @cam_inter_nocontesto, @cam_NoInt_nocontesto, @nNoContesta
	IF @cam_nocontesto=1 -- Opcion NoContesta HABILITADA
	 BEGIN
		--select No Contesta Habilitada
		IF @nNoContesta>@cam_NoInt_nocontesto or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		-- Change priority and obtain the next telephone
		update ccoCallsOutSource set nNoContesta=case when nNoContesta < 255 then isnull(nNoContesta,0)+1 else nNoContesta end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT

		SELECT @DateNewDial=dateadd(mi, @cam_inter_nocontesto, getdate())
		-- Programacion de CALLBACK
		UPDATE ccoWorkingTable SET nNoContesta =@nNoContesta, cal_status=1, cal_telefono=@Telefono, 
		cal_fechaDial=case when @DateNewDial>@DateNextDial then @DateNewDial else cal_fechaDial end
		WHERE callout_id = @callout_id

		return(0)
	 END

	-- Opcion NoContesta DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial=4 -- Fax/Modem
 BEGIN
	SELECT @cam_fax =cam_fax, @cam_inter_fax=cam_inter_fax, @cam_NoInt_fax=cam_NoInt_fax, @nFax=@nFax +1
	FROM ccCamps WHERE cam_id=@cam_id

	IF @cam_fax=1 -- Opcion Fax/Modem HABILITADA
	 BEGIN
		IF @nFax>@cam_NoInt_fax or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		-- Change priority and obtain the next telephone
		update ccoCallsOutSource set nFax=case when nFax < 255 then isnull(nFax,0)+1 else nFax end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT

		SELECT @DateNewDial=dateadd(mi, @cam_inter_fax, getdate())

		-- Programacion de CALLBACK
		UPDATE ccoWorkingTable SET nFax =@nFax, cal_status=1, cal_telefono=@Telefono,
		cal_fechaDial=case when @DateNewDial>@DateNextDial then @DateNewDial else cal_fechaDial end
		WHERE callout_id = @callout_id

		return(0)
	 END

	-- Opcion Fax/Modem DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial=11 -- Maquina Contestadora
 BEGIN
	SELECT @cam_graba =cam_graba, @cam_inter_graba=cam_inter_graba, @cam_NoInt_graba=cam_NoInt_graba, @nContestadora=@nContestadora+1
	FROM ccCamps WHERE cam_id=@cam_id

	IF @cam_graba=1 -- Opcion Maquina Contestadora HABILITADA
	 BEGIN
		IF @nContestadora>@cam_NoInt_graba or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		 -- Change priority and obtain the next telephone
		 update ccoCallsOutSource set nContestadora=case when nContestadora < 255 then isnull(nContestadora,0)+1 else nContestadora end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT

		SELECT @DateNewDial=dateadd(mi, @cam_inter_graba, getdate())

		-- Programacion de CALLBACK
		UPDATE ccoWorkingTable SET nContestadora =@nContestadora, cal_status=1, cal_telefono=@Telefono,
		cal_fechaDial= case when @DateNewDial>@DateNextDial then @DateNewDial else cal_fechaDial end
		WHERE callout_id = @callout_id
		
		return(0)
	 END

	-- Opcion Maquina Contestadora DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial in (10,90) --No Dial Tone, otros, NoService
 BEGIN
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

return(0)
set nocount off'
	
	EXEC(@Sql)

	set @process = 'ALTER - SP ccsp_RIA_mnuReciclar'
	set @Sql='ALTER proc [dbo].[ccsp_RIA_mnuReciclar]
@cam_id int,
@type tinyint, -- 0:recicla todo / 1:recicla no efectivos / 2:recicla los efectivos calificados / 
--				  3:recicla no efectivos y efectivos calificados (1 y 2) / 4:Recicla status "Finalizado"
@calif_id varchar(1500) = null,
@user_id as integer = null,
@list_id as integer = 0
as
set nocount on
declare @Valor int, @SQL varchar(4000)
select @Valor = valor from ccSettings where setting_id = 60

If @Valor = 1
 begin
	declare @ultimoReciclaje datetime, @siguienteReciclaje datetime, @difDateAdd datetime
	select @Valor = valor from ccSettings where setting_id = 59
	
	If @Valor = 0 
	 begin
		select -2, ''No hay un limite para volver a reciclar''
		return(0)
	 end

	select top 1 @ultimoReciclaje = max(fecha) from ccLogReciclaje where cam_id = @cam_id

	-- Se crea log, ccsp_ADMlogReciclaje para que esta informacion la traiga, por que no se esta metiendo
	select @user_id = isnull(@user_id, ''0''), @calif_id = isnull(@calif_id, ''0'')
	
	exec dbo.ccsp_ADMlogReciclaje @cam_id, @user_id, @type, @calif_id

	If @ultimoReciclaje is not null and getdate() < DateAdd(n, @Valor, @ultimoReciclaje)
	begin
		select -3, ''No se puede realizar un reciclaje hasta que pase el tiempo limite''
 		return(0)
	end

 end

if @type=0
 begin
	if @list_id = 0 begin
		create table #allReciycled(callout_id int not null primary key)

		insert into #allReciycled
		select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) where cam_id = @cam_id and cal_status = 1

		update ccoCallsOutSource with(rowlock) 
		set dato5 = isnull(dato5, '''') 
		from ccoCallsOutSource a join #allReciycled b on (a.callout_id = b.callout_id)

		update ccoCallBacks with(rowlock)
		set [status] = 3, schedulerStatus = 1
		from ccoCallBacks a with(index([IX_ccoCallBacks6])) join #allReciycled b on (a.callout_id = b.callout_id)
		where [status] = 0

		update ccoWorkingTable with(rowlock) 
		set cal_status = 0 
		from ccoWorkingTable a join #allReciycled b on (a.callout_id = b.callout_id)

		drop table #allReciycled
	end
	else begin
		create table #allListReciycled(callout_id int not null primary key)

		insert into #allListReciycled
		select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_10),nolock) where cam_id = @cam_id and cal_status = 1 and list_id = @list_id

		update ccoCallsOutSource with(rowlock) 
		set dato5 = isnull(dato5, '''') 
		from ccoCallsOutSource a join #allListReciycled b on (a.callout_id = b.callout_id)

		update ccoCallBacks with(rowlock)
		set [status] = 3, schedulerStatus = 1
		from ccoCallBacks a with(index([IX_ccoCallBacks6])) join #allListReciycled b on (a.callout_id = b.callout_id)
		where [status] = 0

		update ccoWorkingTable with(rowlock) 
		set cal_status = 0 
		from ccoWorkingTable a join #allListReciycled b on (a.callout_id = b.callout_id)

		drop table #allListReciycled
	end

	return(0)
 end

if @type in(1,3)
 begin
	update ccoCallsOutSource with(rowlock)
	set dato5 = isnull(dato5, '''') where callout_id in (
	 select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_11),nolock)
	 where cam_id = @cam_id and cal_status = 1 and tiporesdial_id <> 1)

	update ccoCallBacks with(rowlock)
	set [status] = 3, schedulerStatus = 1
	where callout_id in (select distinct(callout_id)
						 from ccoWorkingTable with(index(IX_ccoWorkingTable_12),nolock)
						 where cam_id = @cam_id 
						 and cal_status = 1 
						 and tiporesdial_id <> 1
						 and callout_id in (select distinct(b.callout_id)
												from ccologdials a with (index (IX_ccoLogDials_4),nolock) 
												left join ccocallsout b with(index(IX_ccoCallsOut12),nolock)
												on a.callout_id = b.callout_id
												and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
												where calif_id = 0
												and calif_id is not null))
	and [status] = 0

	update ccoWorkingTable with(rowlock)
	set cal_status = 0, tiporesdial_id = 0 
	where cam_id = @cam_id 
	and cal_status = 1 
	and tiporesdial_id <> 1
	and callout_id in (select distinct(b.callout_id)
						   from ccologdials a with (index (IX_ccoLogDials_4),nolock) 
						   left join ccocallsout b with(index(IX_ccoCallsOut12),nolock)
						   on a.callout_id = b.callout_id
						   and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
						   where calif_id = 0
						   and calif_id is not null)
 end

if @type in(2,3)
 begin
	Set @SQL = ''update ccoCallsOutSource with(rowlock) set dato5 = isnull(dato5, '''''''') where callout_id in ('' +
	 ''select distinct(callout_id) from ccoWorkingTable with(index(IX_ccoWorkingTable_13),nolock) '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 and tiporesdial_id = 1 '' +
	 ''and calif_id in ('' + @calif_id + '')''+'')'' + nchar(13)
	exec(@SQL)

	Set @SQL = ''update ccoCallBacks with(rowlock) set [status] = 3, schedulerStatus = 1'' +
	 ''where callout_id in ('' +
	 ''select distinct(callout_id) from ccoWorkingTable with(index(IX_ccoWorkingTable_14),nolock) '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 '' +
	 ''and calif_id in ('' + @calif_id + ''))'' +
	 ''and [status] = 0''

	exec(@SQL)

	Set @SQL = ''update ccoWorkingTable with(rowlock) set cal_status = 0, tiporesdial_id = 0, calif_id = 0 '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 ''
	 + -- and tiporesdial_id = 1 '' +
	 ''and calif_id in ('' + @calif_id + '')''

	exec(@SQL)
 end

if @type = 4
 begin
	update ccoCallsOutSource with(rowlock) 
	set dato5 = isnull(dato5, '''') 
	where callout_id in (select distinct(callout_id)
					     from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) 
						 where cam_id = @cam_id and cal_status = 3)

	update ccoCallBacks with(rowlock) 
	set [status] = 3, schedulerStatus = 1
	where callout_id in (select distinct(callout_id)
						 from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) 
						 where cam_id = @cam_id and cal_status = 3)
	and [status] = 0

	update ccoWorkingTable with(rowlock) set cal_status = 0, tiporesdial_id = 0 
	where cam_id = @cam_id and cal_status = 3
 end

return(0)
set nocount off'
	
	EXEC(@Sql)

	set @process = 'CREATE - JOB DatabaseCentinella '
	set @sql='USE [msdb]
/****** Object:  Job [DatabaseCentinella]    Script Date: 07/09/2014 19:44:44 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''DatabaseCentinella'')
EXEC msdb.dbo.sp_delete_job @job_name=N''DatabaseCentinella'', @delete_unused_schedule=1

/****** Object:  Job [DatabaseCentinella]    Script Date: 07/02/2014 00:05:42 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''DatabaseCentinella'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Autor: Raymundo Gonzalez
Fecha: 2014/07/24
Descripcion:
	Centinela para monitoreo de performance y mantenimiento de las BD de SQL
'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseCentinellaTasks]    Script Date: 24/07/2014 09:07:56 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''DatabaseCentinellaTasks'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''use [master]

set nocount on

declare @idDb int
declare @dbName nvarchar(100)
declare @dbLog nvarchar(100)
declare @sql nvarchar(max)
declare @idIndex int
declare @tableName nvarchar(100)
declare @indexName nvarchar(100)
declare @process int
declare @firstSunday datetime
declare @idCmdSql int
declare @cmdSql nvarchar(max)

set @idDb = 0
set @dbName = ''''''''
set @dbLog = ''''''''
set @sql = ''''''''
set @idIndex = 0
set @tableName = ''''''''
set @indexName = ''''''''
set @process = 1
set @firstSunday = DATEADD(WEEKDAY,(8-(DATEPART(WEEKDAY,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))))%7,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))
set @idCmdSql = 0
set @cmdSql = ''''''''

if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
	begin
		if exists (select * from sys.tables where name = ''''userDatabases'''')
			drop table userDatabases

		if exists (select * from sys.tables where name = ''''indexMaintenance'''')
			drop table indexMaintenance

		if exists (select * from sys.tables where name = ''''logCentinella'''')
			drop table logCentinella
	end

if not exists (select * from sys.tables where name = ''''userDatabases'''')
	begin
		create table dbo.userDatabases(
			[idDb] int not null identity primary key,
			[dbName] nvarchar(100) not null,
			[dbLog] nvarchar(100) not null,
			[status] bit not null
		)

		CREATE NONCLUSTERED INDEX [IX_userDatabases1] ON [dbo].[userDatabases]
		(
			[dbName] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_userDatabases2] ON [dbo].[userDatabases]
		(
			[status] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	end

if not exists (select * from sys.tables where name = ''''indexMaintenance'''')
	begin
		create table dbo.indexMaintenance(
			[idIndex] int not null identity primary key,
			[dbName] nvarchar(100) not null,
			[tableName] nvarchar(100) not null,
			[indexName] nvarchar(100) not null,
			[indexType] nvarchar(100) not null,
			[indexFragmentation] nvarchar(100) not null,
			[status] bit not null
		)

		CREATE NONCLUSTERED INDEX [IX_indexMaintenance1] ON [dbo].[indexMaintenance]
		(
			[dbName] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_indexMaintenance2] ON [dbo].[indexMaintenance]
		(
			[tableName] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_indexMaintenance3] ON [dbo].[indexMaintenance]
		(
			[status] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	end

if not exists (select * from sys.tables where name = ''''logCentinella'''')
	begin
		create table dbo.logCentinella(
			[idCmdSql] int not null identity primary key,
			[date] datetime not null,
			[cmdSql] nvarchar(max) not null,
			[status] int not null
		)

		CREATE NONCLUSTERED INDEX [IX_logCentinella1] ON [dbo].[logCentinella]
		(
			[date] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_logCentinella2] ON [dbo].[logCentinella]
		(
			[status] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	end

insert into userDatabases
select db_name(database_id), '''''''', 0
from sys.master_files
where state = 0 
and has_dbaccess(db_name(database_id)) = 1
and db_name(database_id) NOT IN (''''master'''', ''''tempdb'''', ''''model'''', ''''msdb'''', ''''resource'''', ''''distribution'''', ''''reportservice'''', ''''reportservicetempdb'''')
and type = 0

update userDatabases
set [dbLog] = name
from sys.master_files
inner join userDatabases on (db_name(database_id) = [dbName] and type = 1)

while (select count(*) from userDatabases where status = 0) > 0
	begin
		set rowcount 1
			select @idDb = idDb, @dbName = dbName from userDatabases where status = 0 order by idDb
		set rowcount 0

		select @sql = ''''use ['''' + @dbName + ''''] 

insert into master.dbo.indexMaintenance
SELECT '''''''''''' + @dbName + '''''''''''', OBJECT_NAME(ind.OBJECT_ID), ind.name, indexstats.index_type_desc, indexstats.avg_fragmentation_in_percent, 0
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats 
INNER JOIN sys.indexes ind ON (ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id and ind.type > 0)
inner join sysobjects obj on (obj.id = indexstats.object_id and xtype=''''''''U'''''''' and category = 0)
WHERE indexstats.avg_fragmentation_in_percent > 30 
ORDER BY OBJECT_NAME(ind.OBJECT_ID), ind.name''''

		exec(@sql)

		update userDatabases
		set status = 1
		where idDb = @idDb
	end

while (select count(*) from indexMaintenance where status = 0) > 0
	begin
		set rowcount 1
			select @idIndex = idIndex, @dbName = dbName, @tableName = tableName, @indexName = indexName from indexMaintenance where status = 0 order by idIndex
		set rowcount 0

		select @sql = ''''use ['''' + @dbName + ''''] ''''

		if @process = 1
				select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REORGANIZE WITH ( LOB_COMPACTION = ON )'''' 
		else if @process = 2
				select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )'''' 
		else if @process = 3
				select @sql = @sql + ''''UPDATE STATISTICS [dbo].['''' + @tableName + ''''] WITH FULLSCAN'''' 

		insert into logCentinella
		select getdate(), @sql, 0

		if @process < 3
			update indexMaintenance set status = 1 where idIndex = @idIndex
		else
			update indexMaintenance set status = 1 where dbName = @dbName and tableName = @tableName

		if @process < 3
			begin
				if (select count(*) from indexMaintenance where status = 0) = 0
					begin
						update indexMaintenance 
						set status = 0

						set @process = @process + 1
					end
			end
	end

if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
	begin
		update userDatabases
		set status = 0

		while (select count(*) from userDatabases where status = 0) > 0
			begin
				set rowcount 1
					select @idDb = idDb, @dbName = dbName, @dbLog = dbLog from userDatabases where status = 0 order by idDb
				set rowcount 0

				select @sql = ''''use ['''' + @dbName + ''''] DBCC CHECKDB WITH NO_INFOMSGS''''
				
				insert into logCentinella
				select getdate(), @sql, 0
				
				select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKDATABASE(N'''''''''''' + @dbName + '''''''''''', 10, TRUNCATEONLY)''''
				
				insert into logCentinella
				select getdate(), @sql, 0

				select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKFILE('''''''''''' + @dbLog + '''''''''''',1)''''

				insert into logCentinella
				select getdate(), @sql, 0

				select @sql = ''''use [master] 

DECLARE @currentdate datetime
declare @date varchar(200)
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = '''''''''''' + @dbName + ''''_Backup_Centinella_'''''''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''''''.bak''''''''

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

select @rutaBak = Data
from #RutaBak

select @rutaBak= @rutaBak + ''''''''\'''''''' + @date

drop table #RutaBak

BACKUP DATABASE ['''' + @dbName + ''''] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10''''

				insert into logCentinella
				select getdate(), @sql, 0

				update userDatabases
				set status = 1
				where idDb = @idDb
			end

		select @sql = ''''use [master] 

DECLARE @currentdate datetime
declare @date datetime
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = dateadd(ww,-3,getdate())

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

select @rutaBak = Data
from #RutaBak

EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''''''bak'''''''',@date

drop table #RutaBak''''

		insert into logCentinella
		select getdate(), @sql, 0

	end

while (select count(*) from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate()))) > 0
	begin
		set rowcount 1
			select @idCmdSql = idCmdSql, @cmdSql = cmdSql from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate())) order by idCmdSql
		set rowcount 0
	
		exec(@cmdSql)

		update logCentinella
		set status = 1
		where idCmdSql = @idCmdSql
	end

delete userDatabases
delete indexMaintenance'', 
		@database_name=N''master'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''DatabaseCentinellaSchedule'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140724, 
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

	set @process = 'ALTER - Job CW Delete old records'
	set @Sql='USE [msdb]
/****** Object:  Job [ShrinkLogCCenterRia]    Script Date: 07/09/2014 19:44:44 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''CW Delete old records'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW Delete old records'', @delete_unused_schedule=1

/****** Object:  Job [ShrinkLogCCenterRia]    Script Date: 07/02/2014 00:05:42 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 15/07/2014 11:22:44 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Delete old records'', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp]    Script Date: 15/07/2014 11:22:44 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @meses int
set @meses = 8

truncate table cclogInfo
truncate table ccBorrardasReciclaje
truncate table ccUploadTemporal
truncate table ccLogCampsAgentesDia 

delete from cchistoriallistanegra where fecha < dateadd(mm, -@meses, getdate())
delete from ccRIAlog where operationDate < dateadd(mm, -@meses, getdate())
delete from ccRiaChat_log where fecha_chat < dateadd(mm, -@meses, getdate())

delete xxclientehistorial where fechaAct < dateadd(mm, -@meses, getdate())
delete ccRIAWorkGroup_logDial_id where timestamp < dateadd(dd, -15, getdate())
delete ccRIAWorkGroup_Calid where timestamp < dateadd(dd, -15, getdate())
delete ccRIALogAgentesNotReady where fecha < dateadd(dd, -15, getdate())
delete ccRIAcallbacks where año < datepart(yy,getdate())
delete ccRIAcallbacks where mes < datepart(mm,getdate())

delete from ccLogAgentesDia where fecha < dateadd(mm, -@meses, getdate())
delete from ccLogAgentesNotReady where fecha < dateadd(mm, -@meses, getdate())
delete from ccLogLogin where fecha < dateadd(mm, -@meses, getdate())
delete from ccoLogDials where fecha < dateadd(mm, -@meses, getdate())
delete from ccoCallsOut where cal_inicio < dateadd(mm, -@meses, getdate())
delete from ccoWorkingTable where cal_fechadial < dateadd(mm, -@meses, getdate())
delete from ccoCallsOutSource where cal_fechadial < dateadd(mm, -@meses-1, getdate())

delete from ccPosicionEspecialidad where Fecha < dateadd(dd, -15, getdate())
delete from ccPosicionCamps where Fecha < dateadd(dd, -15, getdate())

delete from ccocallbacks where cal_fecha < dateadd(dd, -15, getdate())
delete from ccLogReciclaje where fecha < dateadd(dd, -15, getdate())

delete from cccallsreject where cal_inicio < dateadd(mm, -@meses-1, getdate())
delete from ccLogtransfers where fechaFin < dateadd(mm, -@meses-1, getdate())
delete from ccCallsIn where cal_Inicio < dateadd(mm, -@meses-1, getdate())
delete from ccriachats where chatDate < dateadd(mm, -@meses-1, getdate())
delete from ivrcallsin where date < dateadd(mm, -@meses-1, getdate())
delete from ivroptions where date < dateadd(mm, -@meses-1, getdate())
delete from ccLogAgentesDia_Dialog where fecha_Dialog < dateadd(mm, -@meses-1, getdate())'', 
		@database_name=N''CCenterRia'', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every Sunday at 1:30'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20041022, 
		@active_end_date=99991231, 
		@active_start_time=13000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
'
	
	EXEC(@Sql)

	set @process = 'DISABLE - JOB NuxibaMaintenancePlan'
	set @sql='use [msdb]

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs_view WHERE name = N''NuxibaMaintenancePlan'')
	EXEC dbo.sp_update_job @job_name = N''NuxibaMaintenancePlan'', @enabled = 0'

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
