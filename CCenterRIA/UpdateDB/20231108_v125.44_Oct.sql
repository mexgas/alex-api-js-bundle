/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K089000

Database: CCenterRia
Required version: 125.37

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 44
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	-----------------------------------------------------BEGIN JCL ----------------------------------------------------------------
	SET @process = ' CW-8153 alter sp ccsp_RIACampsManualCall'
	SET @sql = '
			ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]
			@option int,
			@UserID int = 0,
			@onChat int = 0,
			@campId int = 0
			AS
			set nocount on
			if(@option = 1)
			begin
				if (@onChat = 0)
				begin
					declare @mod smallint
					declare @IdArea smallint
					declare @DialingMode tinyint
					select @IdArea = IDArea, @DialingMode = DialingMode from ccUsers where User_id = @UserID
					select @mod = defCampaing from ccRIACat_Areas A
					where A.IDArea = @IdArea 
					select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [isDefault],  g.graphic_id, c.cam_ModoManual, 
					isnull(c.selectRotativeANI, 0) selectRotativeANI
					, isnull(c.CampType,0) as CampType,
					CASE WHEN @DialingMode = 1 THEN (select count(1) from ccoWorkingTable nolock where cam_id = c.cam_id) ELSE 0 END AS countJobs,
					isnull(c.timesPreview, 0) timesPreview
					from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id and c.IDArea = @IdArea
					join ccRIACampsGraph g ON g.cam_id = c.cam_id
					where ca.user_id = @UserID  
						and cam_ModoManual = case when @DialingMode = 1 OR (@DialingMode = 0 AND cam_ModoManual in (1,3)) then cam_ModoManual else -1 end AND CampType = CASE WHEN @DialingMode = 1 THEN 6 ELSE CampType END
					order by cam_descripcion
				end
				else 
				begin 
					select distinct c.cam_id, c.cam_descripcion,  g.graphic_id,  c.cam_ModoManual
					, isnull(c.CampType,0) as CampType
					from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
					join ccRIACampsGraph g ON g.cam_id = c.cam_id
					where ca.user_id = @UserID and manualCallOnChat = 1
					order by cam_descripcion
					SET NOCOUNT OFF;
				end
			end
			if(@option = 2)
			begin
				declare @aniList int 
				declare @rotativeAniListId int
				select @aniList = id_anilist, @rotativeAniListId  = rotativeAlgo from ccCamps where cam_id = @campId
				if @rotativeAniListId >0 begin
					select telAni from ccRotativeANIListDetail where id_RAniList = @aniList
				end
				else begin
					select top 0 '''' telAni 
				end					
			end'
	EXEC(@sql);
	-----------------------------------------------------END JCL ----------------------------------------------------------------


	-----------------------------------------------------BEGIN Gaby -----------------------------------------------------------------
	SET @process = 'CW-8148 drop sp ccsp_GalateaGetPreviewData'
	SET @sql = '
		if exists(select * from sys.procedures where name = ''ccsp_GalateaGetPreviewData'')
		begin
			DROP PROCEDURE ccsp_GalateaGetPreviewData
		end'
	EXEC(@sql);

	SET @process = 'CW-8148 create procedure ccsp_GalateaGetPreviewData'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaGetPreviewData]
        @option int = null,
		@callout_id int = null,
        @user_id smallint = null

        AS
        set nocount on

		if(@option = 1 or @option is null)
		begin
			declare @typePreview varchar = null

			select @typePreview= valor from ccSettings (nolock)
			where setting_id=248 and Status=1

			select ''previewData''=
			 case when U.AllowDeleteRecord=1 then ''true'' else ''false'' end +''~''+
			 ISNULL(P.Headers,'''')+''~''+
			 ISNULL(O.Dato1,'''')+''~''+
			 ISNULL(O.Dato2,'''')+''~''+
			 ISNULL(O.Dato3,'''')+''~''+
			 ISNULL(O.Dato4,'''')+''~''+
			 ISNULL(O.Dato5,'''')+''~''+
			 ISNULL(P.Dato6,'''')+''~''+
			 ISNULL(P.Dato7,'''')+''~''+
			 ISNULL(P.Dato8,'''')+''~''+
			 ISNULL(P.Dato9,'''')+''~''+
			 ISNULL(P.Dato10,'''')+''~''+
			 ISNULL(P.Dato11,'''')+''~''+
			 ISNULL(P.Dato12,'''')+''~''+
			 ISNULL(P.Dato13,'''')+''~''+
			 ISNULL(P.Dato14,'''')+''~''+
			 ISNULL(P.Dato15,'''')+''~''+
			 ISNULL(O.cal_telefono2,'''')+''~''+
			 ISNULL(O.cal_telefono3,'''')+''~''+
			 ISNULL(O.cal_telefono4,'''')+''~''+
			 ISNULL(O.cal_telefono5,'''')+''~''+
			 ISNULL(cast(O.cal_Key as varchar),'''')+''~''+
			 ISNULL(cast(O.cal_telefono as varchar),'''')+''~''+
			 @typePreview+''~'',
			 C.previewDiscard,
			 CE.EditableContactData as previewUpdate
				   from ccoCallsOutSource O (nolock)
			INNER JOIN ccoCallsPreviewData P (nolock) on O.cal_Key=P.Cal_key and O.cam_id=P.cam_id
			INNER JOIN ccCamps C (nolock) on P.cam_id = C.cam_id
			INNER JOIN ccCampsExtend CE (nolock) on C.cam_id= CE.cam_id
			JOIN ccUsers U (nolock) on U.TipoUser_id=1
			Where callout_id=@callout_id and U.User_id=@user_id
		end

		if(@option = 2)
		begin
			select COUNT(*) from ccoCallsOutSource nolock where callout_id = @callout_id
		end
        set nocount off'
	EXEC(@sql);

	-----------------------------------------------------END Gaby -----------------------------------------------------------------
	-----------------------------------------------------Begin Fri ----------------------------------------------------------------
	SET @process = 'Drop sp ccsp_GalateaPermissionsActivityLog'
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GalateaPermissionsActivityLog'')
    begin
        DROP PROCEDURE ccsp_GalateaPermissionsActivityLog;
    end
	'
	EXEC(@sql);

	SET @process = 'create sp ccsp_GalateaPermissionsActivityLog'
	SET @sql = '
	CREATE procedure ccsp_GalateaPermissionsActivityLog
	@UserId           SMALLINT,
	@Operations       VARCHAR(MAX)= '''',
	@Identifiers	  VARCHAR(MAX) = '''',
	@Values			  VARCHAR(MAX) = '''',
	@Module			  SMALLINT = 0,
	@Target			  VARCHAR(40) = ''''
	AS
	BEGIN

	DECLARE @AgentIdsTemp TABLE (i int, AgentId int)
	insert @AgentIdsTemp select * from dbo.fn_RIASplitDelimited (@Target, '','') agentsId

	declare @i int, @n int, @id int, @login varchar(40)
	select @i = 1 , @n = COUNT(AgentId) from @AgentIdsTemp


	while (@i <= @n)
	begin
		select @id =  AgentId from @AgentIdsTemp where i = @i
		select @login = Login from ccUsers where User_id= @id
		exec ccsp_GalateaActivityLog @UserId,@Operations,@Identifiers,@Values,@Module,@login
		set @i = @i + 1
	end

	END
	'
	EXEC(@sql);

	SET @process = ''
	SET @sql = '
	if not exists(select OperationId from ccGalateaOperations where OperationId = 90)
	begin
		insert into ccGalateaOperations (OperationId,OpTagEs,OpTagEn,OpTagPt) values (90,''Habilitar permiso'',''Enable permission'',''Ativar permissão'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert OperationId = 91'
	SET @sql = '
	if not exists(select OperationId from ccGalateaOperations where OperationId = 91)
	begin
		insert into ccGalateaOperations (OperationId,OpTagEs,OpTagEn,OpTagPt) values (91,''Deshabilitar permiso'',''Disable permission'',''Desativar permissão'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert ModuleId = 11'
	SET @sql = '
	if not exists(select ModuleId from ccGalateaModules where ModuleId = 11)
	begin
		insert into ccGalateaModules (ModuleId,MTagEs,MTagEn,MTagPt) values (11,''Permisos de agente'',''Agent permissions'',''Permissões de agente'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert ModuleId=11 and OperationId=90'
	SET @sql = '
	if not exists(select * from ccGalateaModOpRelation where ModuleId=11 and OperationId=90)
	begin
		insert into ccGalateaModOpRelation (ModuleId,OperationId) values (11,90)
	end
	'
	EXEC(@sql);

	SET @process = 'Insert ModuleId=11 and OperationId=91'
	SET @sql = '
	if not exists(select * from ccGalateaModOpRelation where ModuleId=11 and OperationId=91)
	begin
		insert into ccGalateaModOpRelation (ModuleId,OperationId) values (11,91)
	end
	'
	EXEC(@sql);

	SET @process = 'Insert AllowSelectCamp in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''AllowSelectCamp'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''AllowSelectCamp'',''Gestionar marcación de vista previa (seleccionar campaña)'',''Manage preview dialing (select campaign)'',''Gerenciar discagem de visualização (Selecionar campanha)'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert AllowCellPhoneCalls in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''AllowCellPhoneCalls'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''AllowCellPhoneCalls'',''Llamar manualmente (a teléfonos celulares)'',''Dial numbers manually (mobile numbers)'',''Discar manualmente (para telefones celulares)'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert AllowLongDistanceCalls in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''AllowLongDistanceCalls'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''AllowLongDistanceCalls'',''Llamar manualmente (a teléfonos de LD)'',''Dial numbers manually (LD numbers)'',''Discar manualmente (para telefones de LD)'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert AllowLocalCalls in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''AllowLocalCalls'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''AllowLocalCalls'',''Llamar manualmente (a teléfonos locales)'',''Dial numbers manually (local numbers)'',''Discar manualmente (para telefones locais)'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert AllowTransferCalls in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''AllowTransferCalls'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''AllowTransferCalls'',''Recibir transferencias'',''Accept transfers'',''Receber transferências
	'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert XferAgents in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''XferAgents'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''XferAgents'',''Transferir llamadas (a agentes)'',''Transfer calls (to agents)'',''Transferir chamadas (para agentes)'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert XferCamps in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''XferCamps'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''XferCamps'',''Transferir llamadas (a campañas)'',''Transfer calls (to campaigns)'',''Transferir chamadas (para campanhas)'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert XferExt in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''XferExt'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''XferExt'',''Transferir llamadas (a teléfonos externos)'',''Transfer calls (to external lines)'',''Transferir chamadas (para telefones externos)'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert XferManual in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''XferManual'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''XferManual'',''Transferir llamadas (a teléfonos manuales)'',''Transfer calls (to manual dials)'',''Transferir chamadas (para telefones digitados)'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert startStopRecording in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''startStopRecording'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''startStopRecording'',''Pausar y reanudar grabación'',''Pause and resume recording'',''Pausar e continuar gravação'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert AllowPlayRecordsOnCallHistory in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''AllowPlayRecordsOnCallHistory'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''AllowPlayRecordsOnCallHistory'',''Reproducir grabaciones en historial'',''Play back recordings in log'',''Reproduzir gravações no histórico'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert AllowMarks in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''AllowMarks'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''AllowMarks'',''Añadir marcas a grabaciones'',''Add marks to recordings'',''Adicionar marcas às gravações'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert LayoutModeDefault in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''LayoutModeDefault'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''LayoutModeDefault'',''Visualizar interfaz (predeterminada)'',''Use layout mode (default)'',''Usar layout de campanha (padrão)'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert LayoutModePreview in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''LayoutModePreview'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''LayoutModePreview'',''Visualizar interfaz (vista previa)'',''Use layout mode (preview)'',''Usar layout de campanha (visualização)'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert AgentPermissionDailing in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''AgentPermissionDailing'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''AgentPermissionDailing'',''Cambiar tipo de campaña'',''Change campaign type'',''Alterar tipo de campanha'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert AgentPermissionDelete in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''AgentPermissionDelete'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''AgentPermissionDelete'',''Gestionar marcación de vista previa (eliminar registros)'',''Manage preview dialing (delete records)'',''Gerenciar discagem de visualização (excluir registros)'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert AllowSpam in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''AllowSpam'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''AllowSpam'',''Gestionar conversaciones (marcar como spam)'',''Manage conversations (mark as spam)'',''Gerenciar conversas (marcar como spam)'')
	end
	'
	EXEC(@sql);

	SET @process = 'Insert AllowUnassign in ccGalateaIdentifiers'
	SET @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description = ''AllowUnassign'')
	begin
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''AllowUnassign'',''Gestionar conversaciones (desasignar)'',''Manage conversations (unassign)'',''Gerenciar conversas (cancelar atribuição)'')
	end
	'
	EXEC(@sql);

	-----------------------------------------------------END Fri ------------------------------------------------------------------

	/* End script release */
	/* Upgrade database version (first and the last number of setting 77) */
	EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
	EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

	COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
