/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/03/06
Description:

Database: CCenterRia
Required version: 122.14

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 122 --**********actualizar a 122 sin fix
SET @versionfix = 15
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 14
BEGIN
	BEGIN TRAN

	BEGIN TRY


		set @process = 'CW-3908 Alter SP ccsp_RIAManageAreas'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAManageAreas]
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

if @option = 4 begin-- Delete camp area
	

	--Si existe una campaña relacionada con el grupo
	if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
		select -4
		return(0)	 
	end

	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId
				 
	delete from ccCampsAgente where cam_id = @DeleteCamId	

	insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1	

	delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
	delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	
	delete from ccoWorkingTable where cam_id = @DeleteCamId
	
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

			if @option = 11
				begin
					select IDWG, User_id into #WorkGroupUsers from ccRIAWorkGroupUsers where user_id = @DeleteUserId

					delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
									
					select * from #WorkGroupUsers
					drop table #WorkGroupUsers
									
					return(0)
				end
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

if @option = 7 begin-- Delete camp area
	
	if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
	
		---Borra las calificacion con reprogramacion
		delete ccCalifCamp from ccInbound A 
		inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
		inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
		where A.cam_id=@DeleteCamId
		---Borra las subcalificacion con reprogramacion
		delete rel from ccInbound A 
		inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
		inner join ccTipoCalif C on B.calif_id=C.calif_id 
		inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
		inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where A.cam_id=@DeleteCamId and sb.canReprogram=1
	
		update ccInbound set cam_id = null where cam_id=@DeleteCamId				
		 
	end

	select @AllWG = coalesce(@AllWG + '','', '') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId

	delete from ccCampsAgente where cam_id = @DeleteCamId
	insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1

	delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
	delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1
	
	delete from ccoWorkingTable where cam_id = @DeleteCamId  

	select @CurrentWG = coalesce(@CurrentWG + '','', '') + CAST(IDWG as varchar(400)) 
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

	select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'') as areaName
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

	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId 

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

	select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'') as areaName
	
	if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId=@DeleteACDGroupId)--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
	begin
		DECLARE @TwitterResult table(--Se declaro por que el SP ccsp_MailAdminAccount regresa una consulta.  
		result int,  
		operation varchar(30));
		insert @TwitterResult
		EXEC [dbo].[ccsp_MailAdminAccount] @action = 22,@meanContactTypeId = 2, @inboundId = @DeleteACDGroupId--se ejecutara el SP para desasociar la cuenta de mail
	end
	if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId=@DeleteACDGroupId)--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
	begin
		update ContactMeanIn set name = '', conexionInfo = '', connUser = '', connpass='', isActive = 0 where inboundId = @DeleteACDGroupId and meanContactTypeId=1
	end
	update ccinbound set chatDomain = '' where inbound_id = @DeleteACDGroupId--para desasociar el dominio del chat
	return(0)
	end

return(0)
set nocount off'
		EXEC(@sql)		

		
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		-- exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
