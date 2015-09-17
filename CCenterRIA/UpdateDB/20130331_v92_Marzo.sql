/*
Autor: Raymundo Gonzalez
Fecha: 2013/03/31
Descripcion:
	Se crean las tablas ScriptingAgentConfiguration, ScriptingAnswerTemplate, ScriptingCampaignRelation, ScriptingTemplate, ScriptingTemplateStruct para Scripting de Reminder
	Se crea el SP ccsp_ScriptingADM para Scripting de Rimender
	Se modifica el SP ccsp_RIA_ABCCamps para eliminar la funcionalidad de paso de informacion de CCenterRIA a ccReports y borrado de información cuando una campaña es eliminada
	Se modifica el SP ccsp_RIAADMCampMsgs para relacionar los system prompt de campañas
	Se modifica el SP ccsp_RIACATMessages para dar de alta los system prompt
	Se modifica el SP ccsp_RIAADMCampsMsgs_Del para eliminar los sytem prompt
	Se modifica el SP ccsp_ExtAppsCallHistory para agregar columna de cal_key en los casos necesarios
	Se agregan las columnas IdCampEsp y Tipo en las tablas ccLogAgentesDia y ccLogAgentesNotReady para guardar tiempos de reporte de tiempos especiales (Boan)
	Se modifica el SP ccsp_SaveStatusAgent para guardar tiempos de reporte de tiempos especiales (Boan)
	Se modifica el SP ccsp_AgentUpdateCallCALIF para guardar el usuario cuando se hace reprogramación automática por calificación
	Se modifica el SP ccsp_OUTInsertaCallBack para arreglar los callbacks cuando tienen listas configuradas
	
Version requerida: 91
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '92'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ScriptingAgentConfiguration - Create Table'
		set @Sql='CREATE TABLE [dbo].[ScriptingAgentConfiguration](
	[agentId] [int] NOT NULL,
	[windowPosition] [varchar](20) NOT NULL,
	[windowSize] [varchar](20) NOT NULL
) ON [PRIMARY]'

	EXEC(@Sql)

		set @process = 'ScriptingAnswerTemplate - Create Table'
		set @Sql='CREATE TABLE [dbo].[ScriptingAnswerTemplate](
	[scriptingId] [int] NOT NULL,
	[answerId] [int] NOT NULL,
	[answerPlot] [varchar](max) NOT NULL,
	[answerStatus] [varchar](max) NOT NULL,
	[nextPlot] [varchar](max) NOT NULL
) ON [PRIMARY]'

	EXEC(@Sql)

		set @process = 'ScriptingCampaignRelation - Create Table'
		set @Sql='CREATE TABLE [dbo].[ScriptingCampaignRelation](
	[scriptingId] [smallint] NOT NULL,
	[callId] [smallint] NOT NULL,
	[callType] [tinyint] NOT NULL
) ON [PRIMARY]'

	EXEC(@Sql)

		set @process = 'ScriptingTemplate - Create Table'
		set @Sql='CREATE TABLE [dbo].[ScriptingTemplate](
	[scriptingId] [smallint] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NOT NULL
) ON [PRIMARY]'
				
	EXEC(@Sql)

		set @process = 'ScriptingTemplateStruct - Create Table'
		set @Sql='CREATE TABLE [dbo].[ScriptingTemplateStruct](
	[scriptingId] [smallint] NOT NULL,
	[scriptId] [int] NOT NULL,
	[scriptLabel] [varchar](40) NOT NULL,
	[scriptPlot] [varchar](max) NOT NULL,
	[scriptAnswers] [varchar](max) NULL,
	[scriptVariables] [varchar](max) NULL,
	[scriptStatus] [varchar](max) NOT NULL
) ON [PRIMARY]'

	EXEC(@Sql)

		set @process = 'ccsp_ScriptingADM - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_ScriptingADM] 
	-- Add the parameters for the stored procedure here
	@option smallint, 
	@scriptingId smallint = NULL,
	@scriptingName varchar(40) = NULL,
	@scriptId int = NULL,
	@scriptLabel varchar(40) = NULL,
	@scriptPlot varchar(MAX) = NULL,
	@scriptAnswers varchar(MAX) = NULL,
	@scriptVariables varchar(MAX) = NULL,
	@scriptStatus varchar(MAX) = NULL,
	@answerId int = NULL,   
	@answerPlot varchar(MAX) = NULL,   
	@answerStatus  varchar(MAX) = NULL,  
	@answerNextPlot  varchar(MAX) = NULL,
	@agentId int = NULL,
	@agentWindowPosition varchar(20) = NULL,
	@agentWindowSize varchar(20) = NULL,
	@callId smallint = NULL,
	@callType tinyint = NULL
 
AS
	-- INTERNAL VARS
DECLARE @newIdTemplate smallint
SET @newIdTemplate = 0


----------------------
---- CASE OPTIONS


-- DO NOTHING
IF @option = 1
	BEGIN	
		SELECT 1
	END


-- INSERT A NEW SCRIPTING TEMPLATE
IF @option = 2 
	BEGIN
		IF ( SELECT COUNT(*) FROM ScriptingTemplate WHERE name = @scriptingName ) > 0
			BEGIN
				SELECT -1 --''The Scripting template name is already in use.''
			END
		ELSE
			BEGIN
				INSERT INTO ScriptingTemplate(name) VALUES (@scriptingName)
				
				SELECT @newIdTemplate = scope_identity()
							
				SELECT @newIdTemplate
			END
	END


-- UPDATE A SCRIPTING TEMPLATE
IF @option = 3 
BEGIN
	IF ( SELECT COUNT(*) FROM ScriptingTemplate WHERE scriptingId  = @scriptingId ) = 0
		BEGIN
			SELECT -1 --''The scripting does not exists''
		END
	ELSE
		BEGIN
			UPDATE ScriptingTemplate SET name = @scriptingName WHERE scriptingId =@scriptingId
		END
	SELECT @scriptingId
END


-- DELETE
IF @option = 4
BEGIN

IF( SELECT COUNT(*) FROM ScriptingTemplate WHERE scriptingId  = @scriptingId ) > 0
	BEGIN
		DELETE FROM ScriptingTemplateStruct WHERE scriptingId=@scriptingId
		DELETE FROM ScriptingAnswerTemplate WHERE scriptingId=@scriptingId
		DELETE FROM ScriptingTemplate  WHERE scriptingId  = @scriptingId
		SELECT @scriptingId
	END
ELSE
	BEGIN
		SELECT -1
	END
END


-- SELECT ALL SCRIPTING TEMPLATES
IF @option = 5
BEGIN
	IF @scriptingId = 0
		BEGIN
			SELECT scriptingId , name FROM ScriptingTemplate 
		END
	ELSE
		BEGIN
			SELECT scriptingId , name FROM ScriptingTemplate WHERE scriptingId  = @scriptingId
		END
END


-- INSERT A NEW SCRIPT
IF @option = 6 
BEGIN
	INSERT INTO ScriptingTemplateStruct (scriptingId, scriptId, scriptLabel, scriptPlot, scriptAnswers, scriptVariables,scriptStatus)
	VALUES (@scriptingId, @scriptId, @scriptLabel, @scriptPlot, @scriptAnswers, ISNULL(@scriptVariables, ''''),ISNULL(@scriptStatus, ''''))
END

-- SELECT ALL SCRIPTS
IF @option = 7
BEGIN
	SELECT scriptId, scriptLabel, scriptPlot, scriptAnswers, scriptVariables, scriptStatus
	FROM ScriptingTemplateStruct
	WHERE scriptingId = @scriptingId
END

-- DELETE ALL SCRIPTS (SCRIPTING TEMPALTE STRUCT) OF SCRIPTING ID PROVIDED
IF @option = 8
BEGIN
	DELETE ScriptingTemplateStruct WHERE scriptingId = @scriptingId
	DELETE ScriptingAnswerTemplate WHERE scriptingId = @scriptingId
END

-- INSERT A NEW ANSWER SCRIPT
IF @option = 9
BEGIN
	INSERT INTO ScriptingAnswerTemplate (scriptingId, answerId, answerPlot, answerStatus, nextPlot)
	VALUES (@scriptingId, @answerId, @answerPlot, @answerStatus, @answerNextPlot)
END

-- SELECT ANSWER PLOT
IF @option = 10
BEGIN
	SELECT answerId,answerPlot,answerStatus , nextPlot
	FROM ScriptingAnswerTemplate
	WHERE scriptingId = @scriptingId
END

-- RESET SCRIPTING TABLES (TRUNCATE)
IF @option = 11
BEGIN
	TRUNCATE TABLE ScriptingTemplate
	TRUNCATE TABLE ScriptingTemplateStruct
	TRUNCATE TABLE ScriptingAnswerTemplate
	SELECT 1
END

-- RESET SCRIPTING AGENT CONFIGURATION (TRUNCATE)
IF @option = 12
BEGIN
	TRUNCATE TABLE ScriptingAgentConfiguration
	SELECT 1
END

-- SAVE CURRENT AGENT SCRIPTING WINDOW POSITION & SIZE
IF @option = 13
BEGIN
	IF ( SELECT COUNT(*) FROM ScriptingAgentConfiguration WHERE agentId = @agentId ) = 0
		BEGIN
			-- INSERT
			INSERT INTO ScriptingAgentConfiguration (agentId, windowPosition, windowSize)
			VALUES (@agentId, @agentWindowPosition, @agentWindowSize)
		END
	ELSE
		BEGIN
			UPDATE ScriptingAgentConfiguration
			SET windowPosition = @agentWindowPosition, windowSize = @agentWindowSize
			WHERE agentId=@agentId
		END
	SELECT @agentId
END


-- GET AGENT SCRIPTING CONFIGURATION DATA
IF @option = 14
BEGIN
	IF(@agentId = NULL)
		BEGIN
			SELECT * FROM ScriptingAgentConfiguration
		END
	ELSE
		BEGIN
			SELECT * FROM ScriptingAgentConfiguration WHERE agentId = @agentId
		END
END

-- ADD SCRIPTING-CAMPAIGN RELATIONSHIP
IF @option = 15
BEGIN
	DECLARE @campRelationFlag smallint
	SET @campRelationFlag = (SELECT COUNT(*) FROM ScriptingCampaignRelation WHERE callId = @callId AND callType = @callType)

	IF @campRelationFlag > 0
		BEGIN
			DELETE ScriptingCampaignRelation WHERE callId = @callId AND callType = @callType
		END

	BEGIN
		INSERT INTO ScriptingCampaignRelation (scriptingId, callId, callType)
		VALUES (@scriptingId, @callId, @callType)
	END
	SELECT 1
END


-- DELETE SCRIPTING-CAMPAIGN RELATIONSHIP
IF @option = 16
BEGIN
	DELETE ScriptingCampaignRelation WHERE scriptingId = @scriptingId
	SELECT 1
END


-- UPDATES AN EXISTING SCRIPTING-CAMPAIGN REALTIONSHIP
IF @option = 17
BEGIN
	UPDATE ScriptingCampaignRelation
	SET scriptingId = @scriptingId
	WHERE callId=@callId AND callType = @callType
	SELECT 1
END

-- SELECT ANSWER PLOT
IF @option = 18
BEGIN
	SELECT callType, callId
	FROM ScriptingCampaignRelation
	WHERE scriptingId = @scriptingId
END

-- Check relation ACd|Camp with Scripting
IF @option = 19
BEGIN
	IF EXISTS (SELECT * FROM ScriptingCampaignRelation WHERE callId=@callId and callType=@callType  ) 	
		begin
			SELECT scriptingId as result FROM ScriptingCampaignRelation WHERE callId=@callId and callType=@callType 
		end
	else
		begin
			select -1 as result
		end
END'

	EXEC(@Sql)
	
		set @process = 'ccsp_RIA_ABCCamps - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
@option smallint,
@UserId int,
@Descripcion varchar(40),
@Cam_id varchar(1000),
@Activa tinyint,
@IDArea smallint = null,
@frame tinyint, 
@MirrorInbound_Id smallint = null
as
set nocount on

if @option = 0
 begin
	 select cam_id,ISNULL(cam_descripcion,'''') as cam_descripcion
	  ,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
	 from ccCamps as CAMP with(nolock)
	 left join ccRIACat_Areas as AREas with(nolock)
	 on CAMP.IDArea = AREas.IDArea
	 return(0)
 end

if @option = 1 -- select Camp
 begin
	 select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,
	  cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0)
	 from ccCamps a1
	  inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
	  inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
	 where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
	 return(0)
 end

if @option = 4 --Delete
 begin
 	 if exists (select inbound_id from ccInbound where cam_id = @Cam_id)
	  begin
		declare @error varchar(70)
		Select @error=case valor when 0 then ''No es posible eliminar la campaña, esta asociada a una especialidad'' 
		 else ''Campaign can not be deleted, it has an association with an ACD'' end
		from ccsettings where setting_id = 27
		raiserror (@error,18,1)		
		return(0)
	  end

	 delete ccCampsHorarios where cam_id = @Cam_id
	 insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id)
	  Values(@Cam_id, 5, 0, 0, @UserId)
	 Delete ccCalifCamp where cam_id = @Cam_id and tipo = 1
	 Delete ccRIACampsGraph where cam_id = @Cam_id
	 delete ccHistorialListaNegra where cam_id = @Cam_id
	 delete ccRIARegistryLists where cam_id = @Cam_id

	/*** Se elimina la funcionalidad de paso de informacion de CCenterRIA a ccReports y borrado de información cuando una campaña es eliminada ***/
	/*
	-- Se inicia proceso de scheduler service para pasar informacion de ccocallsout antes de eliminarla
	 declare @server varchar(200), @sql varchar(8000), @from datetime, @to datetime
	select @server=valor from ccsettings where setting_id=22

	set @from=convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '':00'',121)
	set @to=convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '':00'',121)

	set @sql=''declare @calIni as varchar(15), @calfin as varchar(15), @Cam_id as smallint
	select @calIni=isnull(max(cal_id),1) from '' + @server + ''.dbo.ccocallsout WITH(NOLOCK) where cam_id = @Cam_id
	select @calfin=max(cal_id) from ccocallsout with(index (IX_ccoCallsOut_2),NOLOCK) where cam_id = @Cam_id 
	SET IDENTITY_INSERT '' + @server + ''.dbo.ccocallsout ON ''

	set @sql = @sql + ''
	insert into '' + @server + ''.dbo.ccocallsout (cal_id,callout_id, cal_telefono,cal_puerto,cam_id,user_id,cal_extension,cal_colgada,cal_key,
	statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,
	cal_tlinebusy,costo,provedor_id,tipollamada_id,cal_tMoh)
	select cal_id,callout_id, cal_telefono,cal_puerto,cam_id,user_id,cal_extension,cal_colgada,cal_key,
	statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,
	cal_tlinebusy,costo,provedor_id,tipollamada_id,cal_tMoh from ccocallsout WITH(NOLOCK) WHERE cal_id>@calIni and cal_id<=@calfin 
	and cam_id=''+cast(@Cam_id as varchar(10))+'' 
	SET IDENTITY_INSERT '' + @server + ''.dbo.ccocallsout OFF ''
	exec(@sql)

	delete ccoCallsOut where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @Cam_id)
	delete ccoCallsOutSource where cam_id = @Cam_id
	Delete ccCamps where cam_id = @Cam_id
	 */
	 return(0)
 end

if @option = 2 --Insert
 begin
	declare @new_cam_id smallint

	if exists(select cam_descripcion from ccCamps where cam_descripcion = @Descripcion)
	 begin
		select -1 --, ''Nombre en Uso''
		return(0)  
	 end

	-- ODC: la campaña siempre esta activa
	set @Activa = 1

	Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd)
	select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
	case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end

	if @@rowcount = 1
	select @new_cam_id = scope_identity()

	else
	 begin
		select -2 --, ''Error al crear campaña''
		return(0)
	 end

	if isnull(@MirrorInbound_Id, 0)<>0
	 begin
		if not exists(select inbound_id from ccInbound where inbound_id=@MirrorInbound_Id)
		 begin
			select -3 -- Error al asignar campaña a ACD, el ACD no existe o no pertenece a la misma area
			return(0)
		 end

		update ccinbound set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
		update cccamps set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
	 end

	insert into ccoDialerCamp (dialer_id, cam_id)
	select dialer_id, @new_cam_id from ccoDialers where status = 1

	insert into ccCalifCamp (calif_id, cam_id, tipo) select calif_id, @new_cam_id, 1 from ccTipoCalifOUT where CalifOut_Status = 1

	If not exists (select frame from ccRIAGraphics where frame = @frame and type_id = 1)
	 begin
		insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
	 end

	insert into ccRIACampsGraph (cam_id, graphic_id)
	select @new_cam_id, graphic_id from ccRIAGraphics where frame = @frame and type_id = 1

	select @new_cam_id
	return(0)
 end

if @option = 3 -- Update
 begin
	 if not exists(select frame from ccRIAGraphics where frame = @frame and type_id = 1)
	  insert into ccRIAGraphics (frame,type_id) values (@frame,1)

	 Update ccCamps set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

	 update ccRIACampsGraph
	  set graphic_id = (select graphic_id from ccRIAGraphics where frame = @frame and type_id = 1)
	  where cam_id = @Cam_id

	 return(0)
 end

 if @option = 5 --Obtener relaciones de campañas - campañas
   begin
      if not exists (select cam_id from ccCamps where cam_id = @Cam_id) or
	 (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
		not exists (select cam_id from ccCamps where cam_id=@descripcion))
	 begin
		select -3 -- Campaña invalida
		return(0)
	 end
	
	if @descripcion=0
		set @descripcion = null

	update ccCamps set surveyCamId = @descripcion where cam_id = @Cam_id
	if @@rowcount=0
		select -4 -- Error al actualizar
		
	else
	 begin
		delete cccalifcamp where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	 end

	return(0)
   end

if @option = 6
	begin
		select cam_id, isnull(surveycamid,0)
		from cccamps with(nolock)
		where cam_id = @Cam_id
		return(0)
	end

return(0)
set nocount off'
		
	EXEC(@Sql)

		set @process = 'ccsp_RIAADMCampMsgs - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAADMCampMsgs]
@Command tinyint, -- 1=Query, 2=Insert
@msg_id int = null,
@cam_id smallint = null,
@order tinyint = null,
@Type tinyint = null,
@queue bit = null,
@msgFile varchar(40) = '''',
@description varchar(40) = ''''
as
set nocount on
if @Command=1
 begin
	select A.type, A.orden, msgFile, A.Msg_id, D.msg_mostrar
	from ccCampsMsgs A 
	join ccCamps B on A.cam_id = B.cam_id
	join ccMsgFiles C on A.Msg_id = C.Msg_id 
	left join ccTipoMsgs D on A.type = D.tipomsg_id
	where A.cam_id = @cam_id
	order by A.type, A.orden
	return(0) 
 end

If @Command=2
 begin
	if not exists (select msg_id from ccCampsMsgs where msg_id=@msg_id and cam_id=@cam_id and type=@type)
		insert into ccCampsMsgs (msg_id, cam_id, orden, type) values (@msg_id, @cam_id, @order, @Type)
	return(0)
 end
 
If @Command=3
	begin
		exec @msg_id = ccsp_RIACATMessages 5, 0, @msgFile, @description
		if @msg_id <> 0
			insert into ccCampsMsgs (msg_id, cam_id, orden, type) values (@msg_id, @cam_id, @order, @Type)
		return(0)
	end

set nocount off'
				
	EXEC(@Sql)
	
		set @process = 'ccsp_RIACATMessages - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIACATMessages]
@command tinyint,
@msg_id int=0,
@msgFile varchar(40)='''',
@Description varchar(40)=''''
AS
set nocount on
If @command=0
 begin
	SELECT Descripcion FROM ccMsgFiles WHERE msg_id=@msg_id
	return(0)
end 
 
If @command=1
 begin
	SELECT msg_id, msgFile, Descripcion, 1 as FileExists from ccMsgFiles where msgFile not like ''%TTS|%'' order by msg_id
	return(0)
 end 

if @command=2
 begin
	if EXISTS(select msgFile from ccMsgFiles where msgFile=@msgFile)
	 begin
		select 1, ''Nombre en Uso''
		return(0)
	 end

	Insert ccMsgFiles (msgFile, descripcion) select @msgFile, @Description
    return(0)
 end 

if @command=3
 begin
	if exists(select msg_id from ccInboundMsgs where msg_id=@msg_id)
	 begin 
		select 1 --''Este Mensaje tiene alguna Especialidad asignada''
		return(0)
	 end

	if exists(select msg_id from ccCampsMsgs where msg_id=@msg_id)
	 begin 
		select 1 --''Este Mensaje tiene alguna campaña asignada''
		return(0)
	 end

	Delete ccMsgFiles Where msg_id=@msg_id
	return(0)
 end 

if @command=4 
 begin
	Update ccMsgFiles set msgFile=@msgFile, descripcion=@Description Where msg_id=@msg_id
	return(0)
 end
 
 if @command=5
 begin
	if EXISTS(select msgFile from ccMsgFiles where descripcion= @Description)
	 begin
		select 1, ''Nombre en Uso''
		return(0)
	 end

	Insert ccMsgFiles (msgFile, descripcion) select @msgFile, @Description
    return scope_identity()
 end

set nocount off'
					
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAADMCampsMsgs_Del - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAADMCampsMsgs_Del]
@msg_id varchar(255) = null,
@cam_id smallint = null,
@order varchar(255) = null,
@Type varchar(255) = null
as
set nocount on
declare @i int, @x int
declare @T_msg_id as table (id int, msg_id varchar(255))
declare @T_order as table (id int, [order] varchar(255))
declare @T_Type as table (id int, [type] varchar(255))
declare @T_all as table (id int, cam_id int, msg_id int, [order] int, [type] int)
declare @temp_ccCampsMsgs as table(id int identity, Msg_id int, cam_id smallint, orden tinyint, Type tinyint)

insert @T_msg_id select * from dbo.fn_RIASplitDelimited(@msg_id, '','')
insert @T_order select * from dbo.fn_RIASplitDelimited(@order, '','')
insert @T_Type select * from dbo.fn_RIASplitDelimited(@Type, '','')

insert @T_all select m.id, @cam_id, msg_id, [order], [type] 
	from @T_msg_id m join @T_order o on m.id = o.id join @T_Type t on o.id = t.id
	order by o.[order]

select @i = 1, @x = count(id) from @T_all

while @i <= @x
 begin
	delete ccCampsMsgs 
	where cam_id = @cam_id 
	and msg_id in (select msg_id from @T_all where id = @i) 
	and orden in (select [order] from @T_all where id = @i)
	and Type in (select Type from @T_all where id = @i)
	
	delete ccMsgFiles
	where msg_id in (select msg_id from @T_all where id = @i)
	and msgFile like ''%TTS%''
	set @i = @i+1
 end

	insert @temp_ccCampsMsgs select distinct r.*
	from ccCampsMsgs r join @T_all a on
	r.cam_id = a.cam_id and r.Type = a.Type
	order by orden

select @i = 1, @x = count(id) from @temp_ccCampsMsgs

while @i <= @x
begin
	delete ccCampsMsgs 
	where cam_id = @cam_id
	and msg_id in (select msg_id from @temp_ccCampsMsgs where id = @i) 
	and orden in (select orden from @temp_ccCampsMsgs where id = @i)
	and Type in (select Type from @temp_ccCampsMsgs where id = @i)
	
	delete ccMsgFiles
	where msg_id in (select msg_id from @T_all where id = @i)
	and msgFile like ''%TTS%''
	set @i = @i+1
end

	update @temp_ccCampsMsgs set orden = id
	insert into ccCampsMsgs (Msg_id, cam_id, orden, Type)
	select Msg_id, cam_id, orden, Type from @temp_ccCampsMsgs
return(0)
set nocount off'
					
	EXEC(@Sql)
	
		set @process = 'ccsp_ExtAppsCallHistory - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory]
@action smallint,
@call_id int = 0,
@startDate varchar(20) = null,
@endDate varchar(20) = null,
@state int = 0,
@multipleCall_id as varchar(500) = null,
@agentId int = 0
AS 

-- INBOUND x cal_id
if @action = 1
 begin
	select top 500 cal_id as call_id,c.inbound_id,isnull(a.descripcion,'''') as acdGroup,cal_ani as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,'''') as login,
	isnull(e.description,'''') as disposition,d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing,  cal_key as callKey
	from cccallsin c with(nolock)
	left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
	left join ccusers b on (c.user_id = b.user_id) 
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalif e on ( c.calif_id = e.calif_id )
	where cal_id >= @call_id
 end

-- OUTBOUND x cal_id
if @action = 2 
 begin
	select top 500 cal_id as call_id,c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
	d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_manual as CallManual,  cal_key as callKey
	from ccocallsout c with(nolock)
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

		select user_id, login, logout, datediff(ss,login,logout) as logintime 
		from(select a.user_id, a.fecha as ''login'',
				(select isnull(max(Fecha),getdate())
					from ccLogLogin b with(nolock)
					where b.user_id = a.user_id and
					b.tipomov = 0 and
					b.fecha >= a.fecha and
					b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
								from ccLogLogin with(nolock)
								where user_id = b.user_id and
								tipomov = 1 and
								fecha > a.fecha)) as ''logout''
				from ccLogLogin a
				where a.tipomov=1
				and fecha >= @fecha_ini
				and fecha <= @fecha_fin) as sessiontime
		order by user_id, login
	end

	if @action = 4 -- Estados de los agentes
	begin	
		select User_id, tStatus, fecha from cclogagentesdia with(nolock) where TipoStatusAge_id = @state and fecha >= @startDate and fecha < @endDate order by User_id,fecha
	end

	if @action = 5 -- Sinlge Call id Inbound
	 begin
		select top 500 cal_id as call_id,c.inbound_id,isnull(a.descripcion,'''') as acdGroup,cal_ani as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,'''') as login,
		isnull(e.description,'''') as disposition,d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_key as callKey
		from cccallsin c with(nolock)
		left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
		left join ccusers b on (c.user_id = b.user_id) 
		left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
		left join ccTipoCalif e on ( c.calif_id = e.calif_id )
		where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') ) 
	 end


	-- Single call_id Outbound
	if @action = 6
	 begin
		select top 500 cal_id as call_id,c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
		d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_manual as CallManual, cal_key as callKey
		from ccocallsout c with(nolock)
		left join ccusers b on (c.user_id = b.user_id) 
		left join cccamps a on (c.cam_id = a.cam_id)
		left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
		left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
		where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') ) 
	 end

if @action = 7 begin --Status Agente
	select tipostatusAge_id, tstatus, dateadd(ss,(-1*tstatus),fecha) from cclogagentesdia with(nolock) where user_id = @agentId and fecha >= @startDate and fecha < @endDate order by fecha
end'
					
	EXEC(@Sql)
	
		set @process = 'ccLogAgentesDia - Alter Table(1)'
		set @Sql='alter table ccLogAgentesDia
add IdCampEsp smallint null'
					
	EXEC(@Sql)
	
		set @process = 'ccLogAgentesDia - Alter Table(2)'
		set @Sql='alter table ccLogAgentesDia
add Tipo smallint null'
					
	EXEC(@Sql)
	
		set @process = 'ccLogAgentesNotReady - Alter Table(1)'
		set @Sql='alter table ccLogAgentesNotReady
add IdCampEsp smallint null'
						
	EXEC(@Sql)
	
		set @process = 'ccLogAgentesNotReady - Alter Table(2)'
		set @Sql='alter table ccLogAgentesNotReady
add Tipo smallint null'
						
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
set @TipoCall = @TipoCall - 1

if (@User_id > 0 )
begin
	if (@TipoStatusAge_id=4) -- 4 = Dialogo
	 begin
		declare @tStatus3 int, @Fecha3 datetime
		select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
		insert into ccLogAgentesDia_Dialog
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
			if exists (select * from ccLogAgentesDia where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesDia
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
			
			if exists (select * from ccLogAgentesNotReady where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesNotReady
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
		end
end'
						
	EXEC(@Sql)
	
		set @process = 'ccsp_AgentUpdateCallCALIF - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_AgentUpdateCallCALIF]
@IDCall int,
@calif_id smallint,
@TipoCall smallint,
@Origin int=0,
@cal_key varchar(20)=null,
@callOutId int=0,
@subId smallint=0
as
set nocount on
declare @RecicleSIC tinyint, @Reprogram tinyint, @DateNewDial smalldatetime, @idTipoLista int, @autoCB tinyint, @tel varchar(30), @camp int, @iddncList as int
declare @userid int
select @RecicleSIC=valor FROM ccSettings WHERE setting_id=60
select @RecicleSIC=IsNull(@RecicleSIC, 0)

if @TipoCall=1
 begin
	Update ccCallsIN Set calif_id=@calif_id, cal_origin_id=@Origin, cal_key=isnull(@cal_key, cal_key), 
	califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall
	return(0)
 end

if @TipoCall=2
 begin
 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @autoCB=autocallback from ccTipoCalifSubout where califSub_Id = @subId
	
	-- Si no tiene subcalificacion toma la de la calificacion
	if @autoCB is null
	 begin
		select @autoCB = autocallback from cctipocalifout where calif_id = @calif_id
	 end

	if @autoCB = 1
	begin
		select @callOutId=callout_id, @camp=cam_id,@userid=user_id from ccocallsout where Cal_id=@IDCall
		select @DateNewDial=dateadd(mi,t_autoCB,getdate()) from cccamps cam where cam.cam_id = @camp

		exec ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid
	end

	Update ccoCallsOUT Set calif_id=@calif_id, califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall

	if exists(select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id)
	and not exists (select co.cal_telefono from ccoCallsOut co with (index (PK_ccoCallsOut))
	join ccListaNegra bl on dbo.Completa_ListaNegra(co.cal_telefono)=bl.telefono or co.cal_telefono=bl.telefono where co.cal_id=@idCall
	and bl.idtipolista in (select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id))
	 begin		
		select @tel=dbo.Completa_ListaNegra(co.cal_telefono), @iddncList = cbl.idTipoLista 
		from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
		where co.cal_id=@idCall and dbo.Completa_ListaNegra(co.cal_telefono)<>''E_NV_Longitud'' and cbl.tipo=1

		exec ccsp_InsertDNCList @tel, @iddncList

		insert ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
		select dbo.Completa_ListaNegra(co.cal_telefono), cbl.idTipoLista, co.cam_id, getdate(), co.callout_id, 6
		from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
		where co.cal_id=@idCall and dbo.Completa_ListaNegra(co.cal_telefono)<>''E_NV_Longitud'' and cbl.tipo=1
	 end

	if @RecicleSIC=1
	 begin
	 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
		select @Reprogram=CanReprogram from ccTipoCalifSubout where califSub_Id = @subId
		
		-- Si no tiene subcalificacion toma la de la calificacion
		if @Reprogram is null
		 begin
			select @Reprogram=CanReprogram from ccTipoCalifOUT where calif_id=@calif_id
		 end

		if @callOutId=0
			select @callOutId=callout_id from ccocallsout where Cal_id=@IDCall

		Update ccoWorkingTable Set calif_id=@calif_id, 
		 cal_status=case @Reprogram when 0 then 3 else cal_status end
		Where callout_id=@callOutId

	 end
	declare @keepDial bit
	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @keepDial=keepDial from ccTipoCalifSubout where califSub_Id = @subId
	
	-- Si no tiene subcalificacion toma la de la calificacion
	if @keepDial is null
	 begin
		select @keepDial=keepDial from ccTipoCalifout where calif_id = @calif_id
	 end

	if @keepDial=1
	 begin
		update ccologdials set TipoDialingMode=dbo.fn_getDialingMode(@IDCall, 3, 0, @camp) 
		where logDial_id in (select top 1 L.logDial_id from 
			ccoLogDials L with(index(IX_ccoLogDials_2), nolock) 
			 join ccoCallsOut O with(index(PK_ccoCallsOut), nolock) 
			 on L.callout_id = O.callout_id where O.cal_id=@IDCall
			order by L.logDial_id desc)
	 end
	 
	select @keepDial
	return(0)
 end

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
 
      insert ccoCallBacks values(@callout_id,@user_id,@Camp,@cal_Key,@TelOriginal,@Telefono,@FechaOriginal,@Fecha,NULL,0,1)
 
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
