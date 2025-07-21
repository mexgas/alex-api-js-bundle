/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio García
Date: 2025/06/23
Description: Demo/Sprint2
Database: CCenterRia
Required version: 127.2
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
SET @version = 127 --**********actualizar a 124 sin fix
SET @versionfix = 1
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
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
	---------------------- BEGIN MAGV  ----------------------
	SET @process = 'K070082 add values in GalateaIdentifiersTable and GalateaModules'
	SET @sql = 'IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers AS cgm WHERE cgm.Description = ''DNI_EDIT_NAME'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt)
			VALUES(''DNI_EDIT_NAME'', ''Nombre'', ''Name'', ''Nome'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers AS cgm WHERE cgm.Description = ''DNIS_EDIT_NUMBER'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt)
			VALUES(''DNIS_EDIT_NUMBER'', ''Número'', ''Number'', ''Número'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaModules AS cgm WHERE cgm.ModuleId = 25)
		BEGIN
		INSERT INTO dbo.ccGalateaModules
		(
			ModuleId,
			MTagEs,
			MTagEn,
			MTagPt
		)
		VALUES
		(   25,  -- ModuleId - int
			''Números DNIS'', -- MTagEs - varchar(250)
			''DNIS numbers'', -- MTagEn - varchar(250)
			''Números DNIS''  -- MTagPt - varchar(250)
			);
		END


		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 140)
		BEGIN   
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (140, N''Configurar número DNIS'', N''Configure DNIS number'', N''Configurar número DNIS'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 141)
		BEGIN   
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (141, N''Editar número DNIS'', N''Edit DNIS number'', N''Editar número DNIS'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 142)
		BEGIN   
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (142, N''Eliminar número DNIS'', N''Delete DNIS number'', N''Excluir número DNIS'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 143)
		BEGIN   
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (143, N''Asignar número DNIS'', N''Assign DNIS number'', N''Atribuir número DNIS'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 144)
		BEGIN   
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (144, N''Desasignar número DNIS'', N''Unassign DNIS number'', N''Cancelar atribuição de número DNIS'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 145)
		BEGIN   
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (145, N''Bloquear número DNIS'', N''Block DNIS number'', N''Bloquear número DNIS'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 146)
		BEGIN   
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (146, N''Desbloquear número DNIS'', N''Unblock DNIS number'', N''Desbloquear número DNIS'');
		END
	'
    EXEC(@sql)

	SET @process = 'K070082 drop SP ccsp_GalateaDnis'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaDnis'')
    BEGIN
        DROP PROCEDURE dbo.ccsp_GalateaDnis;
    END'
    EXEC(@sql);

	SET @process = 'K070082 CREATE SP ccsp_GalateaDnis'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaDnis]
		@User varchar(10),
		@Tipo tinyint,
		@Dnis varchar(40) = null,
		@Inbound_id smallint = null,
		@dni_id as smallint = null,
		@dnis_ids as varchar(MAX) = null,
		@dni_description as varchar(40) = null,
		@dni_isBlock as bit = null
		as
		set nocount on


		if @Tipo = 1 -- carga dnis
		 begin
			select dni_id, dni_numero as dni_number, dni_descripcion as dni_description, case when dni_id in(select dni_id from ccInboundDnis) then 1 else 0 end dni_isRelated
			from ccDnis where dni_Status=1 order by 2
			return(0)
		 end

		if @Tipo = 2 -- carga relaciones de dnis
		 begin
			declare @UserId int=cast(@user as smallint)
			declare @isSuperUser bit=0

			if @UserId > 0 and exists (
				select * from ccUsers_Roles A
				inner join ccRoles R on A.Rol_id=R.Rol_id and R.Level=7
					where User_id = @UserId
				) begin
					set @isSuperUser =1
				end

			;with relationDnis as(
				select a1.Inbound_id, cast(0 as smallint) dni_id, a1.descripcion as description,'''' as dni_number,'''' as dni_description, cast(0 as tinyint) dni_isBlock
				from ccInbound a1
				inner join ccRIAInboundGraph a2 on (a1.Inbound_id = a2.Inbound_id)
				inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
				where a3.type_id = 1 and IDArea is not null 
				and a1.Inbound_id not in (select Inbound_id from ccInboundDnis)
				union
				select ci.inbound_id, cid.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
				from ccInboundDnis cid 
				inner join ccInbound ci on ci.inbound_id = cid.inbound_id 
				join ccDnis cd on cd.dni_id = cid.dni_id 
				where cd.dni_Status=1
			)

			select * from relationDnis a1
			where @isSuperUser=1 or a1.Inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@UserId, 2))
			order by 3,4

			return(0)
		 end

		if @Tipo = 3 -- Agrega Dnis
		 begin
			if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis)
			 begin
				insert into ccDnis (dni_id, dni_numero, dni_tpoMaxEspera, tipodni_id, dni_Descripcion, dni_tipo)
				select isNull(max(dni_id), 0) + 1, @Dnis , 0, 1, @dni_description, 2 from ccDnis
				select top(1) dni_id from ccDNIS order by dni_id desc
				return(0)
			 end
     
			select cast(-1 as smallint)
		 end

		if @Tipo = 4 -- Elimina Dnis
		 begin
			delete from ccInboundDnis where inbound_id = @Inbound_Id and dni_id = @dni_id
    
			select ci.inbound_id, cd.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
			from ccInbound ci , ccDNIS cd
			where ci.Inbound_id=@Inbound_id and dni_id=@dni_id
		 end

		if @Tipo = 5 -- Agrega Relacion
		 begin
			insert into ccInboundDnis (Inbound_id, dni_id)
			select @Inbound_Id,B.Value from  dbo.fn_RIASplitDelimited (@dnis_Ids, '','') B
			left join ccInboundDnis A on A.dni_id=B.Value 
			where  A.dni_id is null

			select cast(@Inbound_Id as smallint) inbound_id,cast(B.Value as smallint) dni_id, 
			ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock        
			,case when cid.Inbound_id is null then 0 else 1 end isAssigned
			from  dbo.fn_RIASplitDelimited (@dnis_Ids, '','') B
			left join ccInboundDnis cid on cid.dni_id=B.Value and cid.Inbound_id=@Inbound_Id
			left join ccInbound ci on ci.inbound_id = @Inbound_Id
			inner join ccDnis cd on cd.dni_id = B.Value
			order by 3,4
		 end

		if @Tipo = 6 -- Elimina Dnis sin pedir inbound_id
		 begin
			if exists(select dni_id from ccInboundDnis where dni_id in (select value from dbo.fn_RIASplitDelimited (@dnis_Ids, '','')) and isnull(inbound_id, 0) <> 0)
				select -1

			else begin
				update ccDNIS set dni_Status=0 where dni_id in (select value from dbo.fn_RIASplitDelimited (@dnis_Ids, '',''))--= @dni_id -- delete from ccdnis where dni_id = @dni_id
				select 1
			end
		 end

		if @tipo = 7
		 BEGIN
			   DECLARE  @CurrentNumero NVARCHAR(50), 
						@CurrentDescripcion NVARCHAR(MAX),
						@CurrentIsBlock  BIT,
						@UserIds SMALLINT=cast(@user as smallint),
						@camp_description VARCHAR(MAX);

				-- Obtener valores actuales antes de hacer cualquier cambio
				SELECT 
					@CurrentNumero = dni_numero,
					@CurrentDescripcion = dni_Descripcion,
					@CurrentIsBlock = dni_isBlock
				FROM ccDNIS
				WHERE dni_id = @dni_id


				if @Dnis = @CurrentNumero BEGIN
					update ccDnis set 
					dni_Descripcion=isnull(@dni_description,dni_Descripcion)
					where dni_id = @dni_id 

					--Activity log
					IF @@ROWCOUNT > 0 AND @dni_description IS NOT NULL AND @dni_description <> @CurrentDescripcion
					BEGIN
						EXEC [dbo].[ccsp_GalateaActivityLog] @UserId =  @UserIds,       -- smallint
															 @Operations = ''141'',  -- varchar(max)
															 @Identifiers = ''DNI_EDIT_NAME'', -- varchar(max)
															 @Values = @dni_description,      -- varchar(max)
															 @Module = 25,       -- smallint
															 @Target = @Dnis       -- varchar(40)
					END
        
					select 1
					return(0)
				end
				if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis) BEGIN
					update ccDnis set 
					dni_numero=case when @Dnis <> ''0'' then @Dnis else dni_numero end,
					dni_Descripcion=isnull(@dni_description,dni_Descripcion),
					dni_isBlock = isnull(@dni_isBlock,dni_isBlock)
					where dni_id = @dni_id 

					--Activity log
					IF @@ROWCOUNT > 0
					BEGIN
						IF @Dnis IS NOT NULL AND @Dnis <> ''0'' AND @Dnis <> @CurrentNumero
						BEGIN
							EXEC [dbo].[ccsp_GalateaActivityLog] @UserId =  @UserIds,       -- smallint
															 @Operations = ''141'',  -- varchar(max)
															 @Identifiers = ''DNIS_EDIT_NUMBER'', -- varchar(max)
															 @Values = @Dnis,      -- varchar(max)
															 @Module = 25,       -- smallint
															 @Target = @Dnis       -- varchar(40)
						END

						IF @dni_description IS NOT NULL AND @dni_description <> @CurrentDescripcion
						BEGIN
							EXEC [dbo].[ccsp_GalateaActivityLog] @UserId =  @UserIds,       -- smallint
															 @Operations = ''141'',  -- varchar(max)
															 @Identifiers = ''DNI_EDIT_NAME'', -- varchar(max)
															 @Values = @dni_description,      -- varchar(max)
															 @Module = 25,       -- smallint
															 @Target = @Dnis       -- varchar(40)
						END

						IF @dni_isBlock IS NOT NULL AND @dni_isBlock <> @CurrentIsBlock
						BEGIN

							SELECT @camp_description = ci.descripcion FROM dbo.ccInbound AS ci WHERE ci.Inbound_id = @Inbound_id

							DECLARE @operation NVARCHAR(20) = 
								CASE 
									WHEN @dni_isBlock = 1 THEN ''145''
									ELSE ''146''
								END

							EXEC [dbo].[ccsp_GalateaActivityLog]
								@UserId     = @UserIds,
								@Operations = @operation,
								@Identifiers = '''',
								@Values     = @CurrentNumero,
								@Module     = 25,
								@Target     = @camp_description
						END
					END

					select 1
					--select dni_id,dni_numero as dni_number, dni_Descripcion as dni_Descriptiondni_id, dni_isBlock from ccDNIS where dni_id=@
					return(0)
				end
    
				select -1
		 END
		 IF @tipo = 8 -- Obtener el listado de dnis por un conjunto de dnisIds
		 BEGIN
			 DECLARE @DnisTable TABLE (
				Value NVARCHAR(max)
			)

			-- Llenar la variable con los valores separados
			INSERT INTO @DnisTable (Value)
			SELECT Value 
			FROM dbo.fn_RIASplitDelimited(@dnis_Ids, '','')

			SELECT cd.dni_id,
				   cd.dni_numero AS dni_number,
				   cd.dni_Descripcion
				   FROM dbo.ccDNIS AS cd INNER JOIN @DnisTable AS dt
				   ON cd.dni_id = dt.Value
		 END

		set nocount off'
    EXEC(@sql);

	SET @process = 'K070029 drop SP ccsp_VirtualAgents'
	 SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_VirtualAgents'')
    BEGIN
        DROP PROCEDURE dbo.ccsp_VirtualAgents;
    END'
    EXEC(@sql);

	SET @process = 'K070029 CREATE SP ccsp_GalateaDnis'
    SET @sql = '
    CREATE PROCEDURE [dbo].[ccsp_VirtualAgents]
    @action INT,
	@idVirtualAgent INT = 0,
    @nameAgent NVARCHAR(255) = NULL,
    @statusAgent BIT = NULL,
	@campaignId INT = NULL,
	@mediaType INT = NULL, -- CALLS, WHATSAPP, SMS
	@campType INT = NULL, -- 0 IN - 1 OUT
	@voiceID INT= 0,
	-- Masivo
	@virtualAgentIds VARCHAR(600) = NULL
    AS
    BEGIN
        IF @action = 1
        BEGIN
            SELECT
                va.idAgent AS idAgent,
                va.NameAgent AS nombre,
                ISNULL(CAST(va.idCampaign AS INT),0) AS idCampaign,
                ISNULL(va.concurrentSessionsLimit, 0) AS concurrentSessionsLimit,
                CAST(va.StatusAgent AS BIT) AS status,
                CAST(va.mediaType AS INT) as SubType,
                ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN ci.descripcion 
                        ELSE co.cam_descripcion
                    END, ''N/A''
                ) AS campName,
                ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN ci.IDArea -- Campaña de entrada
                        ELSE co.IDArea -- Campaña de salida
                    END,
                0) AS IDArea,
                CAST(ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN ig.graphic_id -- Icono para entrada
                        ELSE og.graphic_id -- Icono para salida
                    END, 0
                ) AS int) AS campaignGraph,
                CAST(va.CampType AS int) CampType,
                ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN CAST(ci.Status AS BIT) -- Estado de la campaña de entrada
                        ELSE CAST(co.cam_procesando AS BIT) -- Estado de la campaña de salida
                    END, 0
                ) AS IsActiveCampaign, -- Devuelve 1 o 0
                ISNULL(
                    CASE 
                        WHEN (va.CampType = 0 AND ci.chat = 5) THEN wn.Number
                        WHEN (va.CampType = 1 AND co.CampType = 5) THEN wno.Number
                        ELSE ''N/A''
                    END, ''N/A''
                ) AS NumeroAsociado,
                CONVERT(VARCHAR(10), va.createDateAgent, 120) AS FechaCreacion, -- Devuelve como ''YYYY-MM-DD''
                ISNULL(
                    CASE 
                        WHEN va.latestUpdateDateAgent IS NULL OR va.latestUpdateDateAgent = '''' THEN ''N/A''
                        ELSE CONVERT(VARCHAR(10), va.latestUpdateDateAgent, 120) -- Devuelve como ''YYYY-MM-DD''
                    END, ''N/A''
                ) AS FechaUltimaModificacion, -- Devuelve ''YYYY-MM-DD'' o ''N/A''
				ISNULL(va.voice,1) as Voice
            FROM dbo.ccVirtualAgent va
            LEFT JOIN dbo.ccInbound ci ON ci.Inbound_id = va.idCampaign AND va.campType = 0
            LEFT JOIN dbo.ccCamps co ON co.cam_id = va.idCampaign AND va.campType = 1
            LEFT JOIN dbo.ccMetaWhatsAppNumbers wn ON wn.Inbound_Id = va.idCampaign AND va.campType = 0 AND mediaType != 0
            LEFT JOIN dbo.ccMetaWhatsAppNumbers wno ON wno.Cam_Id = va.idCampaign AND va.campType = 1 AND mediaType != 0
            LEFT JOIN dbo.ccRIAInboundGraph ig ON ig.Inbound_id = va.idCampaign AND va.campType = 0
            LEFT JOIN dbo.ccRIACampsGraph og ON og.cam_id = va.idCampaign AND va.campType = 1
        END

        ELSE IF @action = 2
        BEGIN
            -- Creación de un nuevo agente virtual
            INSERT INTO dbo.ccVirtualAgent (
                nameAgent, 
                statusAgent, 
                createDateAgent, 
                latestUpdateDateAgent
            )
            VALUES (
                @nameAgent, 
                @statusAgent, 
                GETDATE(), -- Fecha de creación actual
                NULL -- latestUpdateDateAgent
            );

            -- Retornar mensaje de éxito
            SELECT ''Agente creado exitosamente'' AS Resultado, SCOPE_IDENTITY() AS IdAgenteCreado;
        END

        ELSE IF @action = 3 -- Elimination of virtual Agent
        BEGIN
            CREATE TABLE #deletedVirtualAgents(idAgent int, agentName varchar(255))

            DELETE FROM dbo.ccVirtualAgent
            OUTPUT deleted.idAgent, deleted.nameAgent INTO #deletedVirtualAgents
            WHERE idAgent IN(SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) AND statusAgent = 0;

            SELECT * FROM #deletedVirtualAgents
        END

        ELSE IF @action = 4 -- Change of campaign
        BEGIN
			DECLARE @PreviousAgentData AS TABLE(
				idAgent INT,
				nameAgent VARCHAR(255),
				idCampaign SMALLINT,
				camptype TINYINT
			);

            IF NOT EXISTS (SELECT 1 FROM ccVirtualAgent WHERE idAgent != @idVirtualAgent AND idCampaign = @campaignId AND mediaType = @mediaType AND campType = @campType) OR
            (@campaignId = 0)
            BEGIN
                UPDATE ccVirtualAgent SET idCampaign = @campaignId, 
                                        mediaType = @mediaType, 
                                        campType = @campType,
                                        latestUpdateDateAgent = GETDATE()
									  OUTPUT deleted.idAgent, deleted.nameAgent, deleted.idCampaign, deleted.campType INTO @PreviousAgentData
                WHERE idAgent = @idVirtualAgent

				IF @campaignId != 0
					BEGIN
						SELECT 
							va.idAgent,
							va.nameAgent,
							CAST(va.idCampaign as int) idCampaign,
							CASE 
								WHEN @campType = 0 THEN i.descripcion
								ELSE cout.cam_descripcion 
							END AS campaignName
						FROM ccVirtualAgent va
						LEFT JOIN ccInbound i ON va.idCampaign = i.Inbound_id AND @campType = 0
						LEFT JOIN ccCamps cout ON va.idCampaign = cout.cam_id AND @campType = 1
						WHERE va.idAgent = @idVirtualAgent;
					END

				ELSE
					BEGIN
						SELECT 
							pvd.idAgent,
							pvd.nameAgent,
							CAST(0 as int) idCampaign,
							CASE 
								WHEN pvd.camptype = 0 THEN i.descripcion
								ELSE cout.cam_descripcion 
							END AS campaignName
						FROM @PreviousAgentData pvd
						LEFT JOIN ccInbound i ON pvd.idCampaign = i.Inbound_id AND pvd.camptype = 0
						LEFT JOIN ccCamps cout ON pvd.idCampaign = cout.cam_id AND pvd.camptype = 1
					END
            END

            ELSE
				SELECT -1 as idAgent,-1 as idCampaign, '''' AS descripcion
        END

        ELSE IF @action = 5 -- Status change
        BEGIN
            CREATE TABLE #updatedVirtualAgents(idAgent int, nameAgent varchar(255), newStatus BIT)

            UPDATE ccVirtualAgent SET statusAgent = @statusAgent,
                                    latestUpdateDateAgent = GETDATE()
            OUTPUT inserted.idAgent, inserted.nameAgent, inserted.statusAgent as newStatus INTO #updatedVirtualAgents
            WHERE idAgent IN (SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) and statusAgent != @statusAgent

            SELECT * FROM #updatedVirtualAgents
        END

		ELSE IF @action = 6 --Check if there''s enabled related agent to camp 
		BEGIN
			DECLARE @result bit = 0;

			IF EXISTS (SELECT 1 FROM ccVirtualAgent WHERE idCampaign = @campaignId)
			BEGIN
				SELECT @result = statusAgent from ccVirtualAgent where idCampaign = @campaignId
			END

			select @result
			
		END
		ELSE IF (@action = 7) --- Get virtual agents by campaign id and camptype
        BEGIN
                SELECT 
                cva.idAgent
                , ISNULL(cva.quantumAgentId,'''') AS QuantumAgentId
                , ISNULL(cva.location,'''') AS Location
                , ISNULL('''','''')  AS ProjectId
				, ISNULL(cva.voice,'''')  AS Voice
                FROM dbo.ccVirtualAgent AS cva
                WHERE cva.idCampaign = @campaignId AND cva.campType = @campType;
        END
        ELSE IF (@action = 8) --- Reload virtual agent association
		BEGIN
			IF (@campType = 0)
				BEGIN 
					SELECT 
					cva.idAgent AS IdAgentVirtual
					,cva.nameAgent AS NameAgentVirtual
					,ISNULL(cva.concurrentSessionsLimit, 0) AS NumberSessions
					,CONVERT(INT, cva.idCampaign) AS IdCampaign
					, cva.campType AS CampType
				FROM ccVirtualAgent cva
				LEFT JOIN ccInbound ci ON cva.idCampaign = ci.Inbound_id AND cva.campType = @campType
				WHERE cva.idAgent = (CASE WHEN @idVirtualAgent = 0 THEN cva.idAgent ELSE @idVirtualAgent END) 
				END
			ELSE 
			BEGIN 
					SELECT 
					cva.idAgent AS IdAgentVirtual
					,cva.nameAgent AS NameAgentVirtual
					,ISNULL(cva.concurrentSessionsLimit, 0) AS NumberSessions
					,CONVERT(INT, cva.idCampaign) AS IdCampaign
					, cva.campType AS CampType
				FROM ccVirtualAgent cva
				LEFT JOIN ccCamps cc ON cva.idCampaign = cc.cam_id AND cva.campType = @campType
				WHERE cva.idAgent = (CASE WHEN @idVirtualAgent = 0 THEN cva.idAgent ELSE @idVirtualAgent END) 
				END
			END
		ELSE IF (@action = 9) --Get FileLocation from ccVirtualAgentVoices
		BEGIN
			select Name, FileName from ccVirtualAgentVoices where ID = @voiceID
		END
		ELSE IF (@action = 10) --Update voice
		BEGIN
			if exists(select * from ccVirtualAgent where idAgent=@idVirtualAgent)
			BEGIN
				update ccVirtualAgent set voice=@voiceID where idAgent=@idVirtualAgent
				select 1
			END
			ELSE BEGIN
				select 0
			END
		END
		ELSE IF(@action = 11) --get voice library
		BEGIN 
			select ID,Name,Gender, FileName from ccVirtualAgentVoices
		END
  
    END'
    EXEC(@sql);

	--------------------------------- END MAGV ---------------------------------------------------------
	--------------------------------- BEGIN DMM --------------------------------------------------------
	SET @process = 'K070064 - Se agrega operacion para elminación de campañas IA entrada para historial de actividad'
	SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 156)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (156, ''Eliminar campaña (llamada de entrada IA)'', ''Delete campaign (AI inbound call)'', ''Excluir campanha (chamada de entrada IA)'')
	END';
	EXEC(@sql);


	SET @process = 'K070239 - Creación de tabla ccoCallsInDispositionIA para guardar resultados de llamada IA entrada'
	SET @sql= 'IF NOT EXISTS (SELECT * 
					 FROM INFORMATION_SCHEMA.TABLES 
					 WHERE TABLE_SCHEMA = ''dbo'' 
					 AND  TABLE_NAME = ''ccCallsInDispositionIA'')
	BEGIN
		CREATE TABLE ccCallsInDispositionIA (
		call_id int Primary key ,
		Qualification VARCHAR(MAX),
		result VARCHAR(MAX),
		Observations VARCHAR(MAX),
		CONSTRAINT FK_ccCallsInDispositionIA_cal_id FOREIGN KEY (call_id)
		REFERENCES ccCallsIn(cal_id)
		ON DELETE CASCADE
		);
	END'
	EXEC(@sql);


	SET @process = 'K070255 - Creación de tabla ccCallsInTranscriptionIA para guardar transcripción llamada IA entrada'
	SET @sql= 'IF NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = ''dbo'' 
                 AND  TABLE_NAME = ''ccCallsInTranscriptionIA'')
			  BEGIN
			  	 CREATE TABLE ccCallsInTranscriptionIA (
			  		call_id int Primary key ,
			  		Transcription VARCHAR(MAX)
			  		CONSTRAINT FK_ccCallsInTranscriptionIA_cal_id FOREIGN KEY (call_id)
			  		REFERENCES ccCallsIn(cal_id)
			  		ON DELETE CASCADE
			  	 );
			  END'
	EXEC(@sql);

	
	SET @process = 'K070064 - drop SP ccsp_GalateaDeleteCampaignAndACD'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaDeleteCampaignAndACD'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_GalateaDeleteCampaignAndACD;
	END'
	EXEC(@sql);

	SET @process = 'K070064 - Se agrega linea WHEN chat = 11 THEN 156 para guardado en historial de actividad 
					de llamadas IA entrada'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_GalateaDeleteCampaignAndACD] 
		@userId           SMALLINT,
		@DeleteCamId      VARCHAR(MAX),
		@DeleteACDGroupId VARCHAR(MAX),
		@moduleId         SMALLINT = 49
		AS
		BEGIN

		IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
			SELECT value As DeleteCamId, c.IDArea AS IDAreaCamp, 1 AS CampTypeCamp, ISNULL(wg.IDWG,0) as IDWG, ISNULL(c.CampType, 0) AS MediaType
			INTO #CampsDelete
			FROM fn_RIASplitDelimited(@DeleteCamId, '','') a
			inner join ccCamps c on  a.value = c.cam_id and c.IDArea IS NOT NULL
			left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=1
		IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
			SELECT value As DeleteACDId, c.IDArea AS IDAreaACD, 0 AS CampTypeACD, ISNULL(wg.IDWG,0) as IDWG, cast(ISNULL(chat, 0) as int) AS MediaType
			INTO #ACDDelete
			FROM fn_RIASplitDelimited(@DeleteACDGroupId, '','') a
			inner join ccInbound c on  a.value = c.Inbound_id and c.IDArea IS NOT NULL
			left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=0

		IF  not Exists (select * from #CampsDelete union select * from #ACDDelete )
		begin
			select ''-1'' AS Result
			return
		end

		IF datalength(@DeleteCamId) > 0
			BEGIN

			if exists(select cam_id from ccInbound where cam_id in (select DeleteCamId from #CampsDelete)) begin
				--Borra las calificacion con reprogramacion
				delete ccCalifCamp from ccInbound A
				inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
				inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
				where A.cam_id in (select DeleteCamId from #CampsDelete)
				--Borra las subcalificacion con reprogramacion
				delete rel from ccInbound A
				inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
				inner join ccTipoCalif C on B.calif_id=C.calif_id
				inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
				inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
				where A.cam_id in (select DeleteCamId from #CampsDelete) and sb.canReprogram=1

				update ccInbound set cam_id = null where cam_id in (select DeleteCamId from #CampsDelete)

			end

			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
			select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete)

			delete from ccCampsAgente where cam_id in (select DeleteCamId from #CampsDelete)
			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
			select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete) and A.tipo = 1

			delete from ccSupervisorCam where cam_id in (select DeleteCamId from #CampsDelete) and tipo = 1
			delete from ccRIACampEspWG where IdCampEsp in (select DeleteCamId from #CampsDelete) and tipo = 1

			IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
			SELECT ca.AreaName,
					GETDATE() operationDate,
					27 operationType,
					(SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
					@moduleId module_id,
					c.cam_descripcion value,
					ca.AreaName AS target
			INTO #CampLog
			FROM ccRIACat_Areas ca
			Inner join ccCamps c with(nolock) on ca.IDArea = c.IDArea
			WHERE c.cam_id in (select DeleteCamId from #CampsDelete)

			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT A.AreaName, GETDATE(), (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
			CASE 
				WHEN CampType = 6 THEN 45
				WHEN CampType = 5 THEN 47
				WHEN CampType = 9 THEN 49
				WHEN CampType = 7 THEN 51
			ELSE 43 END, 
			3, 
			'''',
			'''', 
			c.cam_descripcion
			FROM ccRIACat_Areas A INNER JOIN ccCamps c on A.IDArea = c.IDArea
			where c.cam_id in (select DeleteCamId from #CampsDelete)

			Update ccCamps set IDArea = null where cam_id in (select DeleteCamId from #CampsDelete)
        
			update contactMeanOut set name = '''', conexionInfo = '''', connUser = '''', isActive = 0
			where camp_id in (SELECT DeleteCamId FROM #CampsDelete) and meanContactTypeId=5
        
			update ccWhatsAppNumbers set camp_id = 0 where camp_id in (select DeleteCamId from #CampsDelete)

			update ccMetaWhatsAppNumbers set Cam_Id = 0 where Cam_Id in (select DeleteCamId from #CampsDelete)
        

		END
		IF datalength(@DeleteACDGroupId) > 0
			BEGIN

			if exists(select top 1 cam_id from ccInbound where Inbound_id in (select DeleteACDId from #ACDDelete))
			begin
					update ccInbound set cam_id = null where Inbound_id in (select DeleteACDId from #ACDDelete)
			end

			IF OBJECT_ID(''tempdb..#AllWGACD'') IS NOT NULL DROP TABLE #AllWGACD
			SELECT DISTINCT(IDWG)
			INTO #AllWGACD
			FROM ccRIACampEspWG ce
			WHERE IDCampEsp in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

			insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
			select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG
			from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id
			where B.User_id is null and A.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

			delete ccInboundHorarios Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
			delete ccInboundMsgs Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
			delete ccInboundDnis where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
			select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG
			from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id
			where B.User_id is null and A.cam_id in (SELECT DeleteACDId FROM #ACDDelete)

			delete ccSupervisorCam where cam_id in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0
			delete ccInboundAgentes where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
			delete ccRIACampEspWG where IdCampEsp  in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0


			IF OBJECT_ID(''tempdb..#ACDLog'') IS NOT NULL DROP TABLE #ACDLog
			SELECT ca.AreaName,
					GETDATE() operationDate,
					28 operationType,
					(SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
					@moduleId module_id,
					i.descripcion value,
					ca.AreaName AS target
			INTO #ACDLog
			FROM ccRIACat_Areas ca
			inner join ccInbound i with(nolock) on ca.IDArea = i.IDArea
			WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT a.AreaName, GETDATE(), (SELECT [Login] FROM ccUsers WHERE User_id = @userId),
			CASE 
				WHEN chat = 5 THEN 41
				WHEN chat = 1 THEN 65
				WHEN chat = 11 THEN 156
				ELSE 61 END, 
			3, 
			'''', 
			'''', 
			i.descripcion
			FROM ccRIACat_Areas a inner join ccInbound i on a.IDArea = i.IDArea
			WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

			Update ccInbound set IDArea = null, status = 0 where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

			if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
				begin
					update ContactMeanIn set name = '''', conexionInfo = ''usuarioID|token|tokenSecret|1|0'', connUser = '''', isActive = 0
					where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=2
			end
			if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo email asociado al ACD
				begin
					update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=1
			end
			update ccinbound set chatDomain = '''' where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)--para desasociar el dominio del chat

			if exists (SELECT inboundId FROM contactMeanIn WHERE inboundId in (select DeleteACDId from #ACDDelete))
				begin
					update contactMeanIn set isActive = 0 where inboundId in (select DeleteACDId from #ACDDelete)
			end            
			update ccWhatsAppNumbers set inboundId = 0 where inboundId in (select DeleteACDId from #ACDDelete)
                
			update ccMetaWhatsAppNumbers set Inbound_Id = 0 where Inbound_Id in (select DeleteACDId from #ACDDelete)
        
		END

		IF datalength(@DeleteCamId) > 0
			Insert into ccRIALog Select * from #CampLog
		IF datalength(@DeleteACDGroupId) > 0
			Insert into ccRIALog Select * from #ACDLog

		SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #CampsDelete
		UNION
		SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #ACDDelete
		IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
		IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
		IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
				END'
	EXEC(@sql);


	SET @process = 'K070121 - drop SP ccsp_InboundCallQuantumInfo'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_InboundCallQuantumInfo'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_InboundCallQuantumInfo;
	END'
	EXEC(@sql);

	SET @process = 'K070121 - Creación de SP para obtener datos de para Quantum en llamada IA entrada'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_InboundCallQuantumInfo]
		@InboundId INT
	AS
	BEGIN
		IF EXISTS (SELECT 1 FROM ccInbound WHERE Inbound_id = @InboundId AND chat = 11)
		BEGIN
			SELECT 
				s.valor AS key_api_quantum,
				''{"type":0,"agent_id":"'' + ISNULL(v.quantumAgentId, '''') + ''"}'' AS data_api_quantum
			FROM 
				(SELECT valor FROM ccSettings2 WHERE setting_id = 284) AS s
			OUTER APPLY 
				(SELECT quantumAgentId FROM ccVirtualAgent 
				 WHERE idCampaign = @InboundId AND campType = 0) AS v
		END
	END'
	EXEC(@sql);


	SET @process = 'K0702939 - K0702010 - K070255 drop SP SaveDispositionsAI'
	SET @sql = 'if exists (select * from sys.procedures where name = N''SaveDispositionsAI'')
	BEGIN
		DROP PROCEDURE dbo.SaveDispositionsAI;
	END'
	EXEC(@sql);

	SET @process = 'K0702939 - K0702010 - K070255 Creación de SP para guardado de resultado de llamadas y transcricpiones IA entrada y salida netrada salida '
	SET @sql = '
	CREATE PROCEDURE [dbo].[SaveDispositionsAI]
		@action smallint = null,
		@call_Id int = null,
		@Qualification varchar(max) = null,
		@result VARCHAR(MAX) = null,
		@Observations VARCHAR(MAX) = null,
		@Transcription VARCHAR(MAX) = null,
		@CamType bit = 0

		AS
		IF @action = 1  --Outbound
		BEGIN
			insert into ccoCallsOutDispositionIA (call_id, Qualification, result, Observations) values (@call_Id, @Qualification, @result, @Observations)
		END
		
		IF @action = 2 --Outbound
		BEGIN
			insert into ccoCallsOutTranscriptionIA (call_id, Transcription) values (@call_Id, @Transcription)
		END

		IF @action = 3 --Inbound
		BEGIN
			insert into ccCallsInDispositionIA (call_id, Qualification, result, Observations) values (@call_Id, @Qualification, @result, @Observations)
		END

		IF @action = 4 --Inbound
		BEGIN
			insert into ccCallsInTranscriptionIA (call_id, Transcription) values (@call_Id, @Transcription)
		END'
	EXEC(@sql);


	SET @process = ' Drop SP ccsp_RIAGetAveTimeEspec'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAGetAveTimeEspec'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_RIAGetAveTimeEspec;
	END'
	EXEC(@sql);
	
	SET @process = 'K070064 - Se agrega cambio para que regrese datos de llamada IA entrada tipo 11 en: if @acdType in (0,11) begin --call'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_RIAGetAveTimeEspec] --exec [ccsp_RIAGetAveTimeEspec] @CveCamp = 35, @IsKolob = 1
		@CveCamp INT,
		@IsKolob BIT = 0
		AS

		declare @fechaI as datetime, @fechaF as datetime
		declare @Dlgs as int
		declare @DlgsAveTime as int
		declare @Que as int
		declare @QueueAveTime as INT
		declare @QueueMaxTime as int
		declare @CallsLost as int
		declare @SL1 as int
		declare @SL2 as int
		declare @answ_tres as smallint
		declare @abnd_tres as smallint

		declare @nanswer as smallint
		declare @nno_answer as smallint
		declare @nlost as smallint
		declare @nabnd as smallint
		declare @ntimeout as smallint
		declare @noverflow as smallint
		declare @nno_agent as smallint
		declare @total as int
		declare @setting as tinyint

		declare @dia as varchar(11)

		declare @tresRing as smallint
		declare @tresDialog as smallint
		declare @tresDelayIn as smallint

		exec @tresRing = ccspConfigTresRing
		exec @tresDialog = ccspConfigTresDialog
		exec @tresDelayIn = ccspConfigtresDelayIn

		--select @dia = ''2003/01/22'' --, @CveCamp=5
		select @dia=CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))

		select @fechaI = convert(datetime, @dia, 101)
		select @fechaF = dateadd( d, 1, @fechaI )
		select @setting = valor from ccsettings where setting_id = 127


		declare @acdType tinyint 

		select @acdType= chat from ccInbound where Inbound_id = @CveCamp

		if @acdType in (0,11) begin --call
		SELECT 
		@Dlgs = count(case when statuscall_id = 13 then 1 else null end), 
		@DlgsAveTime = ISNULL(sum( case when statuscall_id = 13 then cal_tDialog + cal_tNotas else null end), 0),

		@Que = count(case when cal_que> 0 then 1 else null end), 
		@QueueAveTime = ISNULL(sum( case when cal_que > 0 then cal_tWait else null end), 0),

		@CallsLost= isnull(COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END), 0), -- ODC

		@abnd_tres = COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer IS NULL)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),
		@answ_tres =  case when @setting = 0 then COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END) else Count(case when (statuscall_id = 13 and (cal_twait + cal_txfer + cal_tring<@tresDelayIn)) then 1 else null end) end,

		@SL1 = case when @setting = 0 then @abnd_tres + @answ_tres else @answ_tres end,

		@nanswer = COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),
		@nno_answer = COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),
		@nlost = COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),
		@nabnd = COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer IS NULL))THEN 1 ELSE NULL END),
		@ntimeout = COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),
		@noverflow = COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),
		@nno_agent = COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),
		@total = count(*),

		@SL2 = case when @setting = 0 then @nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent else @total end
		FROM ccCallsIN
		WHERE cal_Inicio between @fechaI AND @fechaF
		AND Inbound_id = @CveCamp

		select 
			''Id''=@CveCamp, 
			''AverageServiceTime''=@DlgsAveTime/ (@Dlgs+1), 
			''AverageWaitingTime''=@QueueAveTime / (@Que +1),
			''ServiceLevel'' = case 
				when @SL2 > 0 
				then 100 * @SL1 / @SL2 
				else 0 end, 
			''ServiceLevel2'' = case 
				when @setting = 0 
				then 
					case 
						when (@nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent) > 0 
						then 100 * (@abnd_tres + @answ_tres) / (@nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent)
						else 0 end 
				else case 
					when @total > 0 
					then 100 * @answ_tres/@total 
					else 0 end end
				,@acdType as Type
		end

		else if @acdType= 1 begin

		declare @CC int,@CCAb int,@ccme int,@ccma int,@cAs int,@cs int,@cAb int,@cDt int,@cDe int
		select @CC=0,@ccme=0,@ccma=0,@cAs=0,@cs=0,@cAb=1,@cDt=0,@cDe=0,@DlgsAveTime=0

		select
		@CC = count(case when chatStatus=4 and tChatting>=@tresDialog then 1 else null end) ,
		@DlgsAveTime = isnull(sum(case when chatStatus=4 then tChatting+tWrapUp else null end),0) ,
		@ccme = count(case when chatStatus=4 and tChatting<=@tresDialog and tChatting <> 0 then 1 else null end),
		@ccma = count(case when chatStatus=4 and tChatting>@tresDialog and tChatting <> 0 then 1 else null end) ,
		@cAs= count(case when chatStatus=3 then 1 else null end) ,
		@cs = count(case when chatStatus=7 then 1 else null end) ,
		@cAb = count(case when chatStatus=9 and tQueue>=@tresDialog then 1 else null end) ,
		@cDt = count(case when chatStatus=11 then 1 else null end) ,
		@cDe = count(case when chatStatus=10 then 1 else null end),
		@Que = count(case when onQueue > 0 then 1 else null end), 
		@QueueAveTime = ISNULL(sum( case when onQueue > 0 then tQueue else null end), 0),
		@QueueMaxTime = ISNULL (MAX (CASE WHEN onQueue    = 1 THEN  tQueue ELSE NULL END), 0),
		@SL2 = @ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe
		from ccRIAChats 
		where requestDate between @fechaI AND @fechaF
		and inboundId=@CveCamp 
		group by inboundId 

		DECLARE @RESULT DECIMAL(18,2);

			IF(@IsKolob = 1)
			BEGIN
				select 
					@CveCamp as ID, 
					isnull(@DlgsAveTime/(@CC + 1),0) as AverageServiceTime, 
					isnull(@QueueAveTime / (@Que + 1),0) as AverageWaitingTime,
					ISNULL(CONVERT(BIGINT,@QueueMaxTime),0) AS MaximumWaitingTime,
					case when @SL2>0 then (@CC)*100/(@SL2) else 0 end as ServiceLevel,
					isnull((@CC)*100/nullif(@ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe,0),0) as ServiceLevel2,
					@acdType as acdType,
					ISNULL(@CC,0) as CC,
					ISNULL(@SL2,0) as SumSL
			END
			ELSE 
			BEGIN
				select 
				@CveCamp as ID, 
				isnull(@DlgsAveTime/(@CC + 1),0) as DlgsAveTime, 
				isnull(@QueueAveTime / (@Que + 1),0) as QueueAveTime,
				case when @SL2>0 then (@CC)*100/(@SL2) else 0 end as SL,
				isnull((@CC)*100/nullif(@ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe,0),0) as Sl2,
				@acdType as acdType,
				ISNULL(@CC,0) as CC,
				ISNULL(@SL2,0) as SumSL
			END
		END'
	EXEC(@sql);

	
	SET @process = 'K070064 - Drop SP ccsp_VerifyCampaignRelationships'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_VerifyCampaignRelationships'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_VerifyCampaignRelationships;
	END'
	EXEC(@sql);


	SET @process = 'K070064 - Se crea SP ccsp_VerifyCampaignRelationships para verificar relaciones de campañas con otras camapñas, WG 
					y eliminar relaciones con agentes virtuales al momento de ser eliminadas'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_VerifyCampaignRelationships]
		@Option SMALLINT = 0,
		@CamIds VARCHAR(MAX)
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @CurrentId INT;

		IF @Option = 0 --ACDs
		BEGIN
			IF OBJECT_ID(''tempdb..#TmpACDs'') IS NOT NULL DROP TABLE #TmpACDs;
			IF OBJECT_ID(''tempdb..#FinalACDs'') IS NOT NULL DROP TABLE #FinalACDs;
			IF OBJECT_ID(''tempdb..#ClassifiedACDs'') IS NOT NULL DROP TABLE #ClassifiedACDs;

			CREATE TABLE #TmpACDs (Id INT);
			CREATE TABLE #FinalACDs (Id INT);
			CREATE TABLE #ClassifiedACDs (
				Id INT,
				HasWGRelation BIT,
				HasCampaignRelation BIT,
				UnassignVirtualAgent BIT
			);

			INSERT INTO #TmpACDs (Id)
			SELECT CAST(Value AS INT)
			FROM dbo.fn_RIASplitDelimited(@CamIds, '','');

			INSERT INTO #ClassifiedACDs (Id, HasWGRelation, HasCampaignRelation, UnassignVirtualAgent) 
			SELECT
				t.Id,
				CASE WHEN r.IdCampEsp IS NOT NULL THEN 1 ELSE 0 END AS HasWGRelation,
			    CASE WHEN i.inbound_id IS NOT NULL 
					AND (i.cam_id IS NULL OR i.cam_id = 0) 
					AND (i.idForNonComprehension IS NULL OR i.idForNonComprehension = 0)
					AND (i.idForSuccessfulTransaction IS NULL OR i.idForSuccessfulTransaction = 0)
						THEN 1 
						ELSE 0 
					END AS HasCampaignRelation,
				CASE WHEN v.idCampaign IS NOT NULL THEN 1 ELSE 0 END AS UnassignVirtualAgent
			FROM #TmpACDs t
			LEFT JOIN ccRIACampESPWG r
				ON r.IdCampEsp = t.Id AND r.Tipo = 0
			LEFT JOIN ccinbound i
				ON i.inbound_id = t.Id
			LEFT JOIN ccVirtualAgent v
				ON v.idCampaign = t.Id AND v.campType = 0 AND v.mediaType = 11;

			INSERT INTO #FinalACDs (Id)
			SELECT Id
			FROM #ClassifiedACDs
			WHERE HasWGRelation = 0 AND HasCampaignRelation = 1 AND UnassignVirtualAgent = 0;

			DECLARE cur CURSOR LOCAL FOR
			SELECT Id
			FROM #ClassifiedACDs
			WHERE HasWGRelation = 0 AND HasCampaignRelation = 1 AND UnassignVirtualAgent = 1;

			OPEN cur;
			FETCH NEXT FROM cur INTO @CurrentId;

			WHILE @@FETCH_STATUS = 0
			BEGIN
				UPDATE ccVirtualAgent
				SET idCampaign = 0,
					mediaType = NULL
				WHERE idCampaign = @CurrentId AND campType = 0 AND mediaType = 11;

				INSERT INTO #FinalACDs (Id) VALUES (@CurrentId);

				FETCH NEXT FROM cur INTO @CurrentId;
			END

			CLOSE cur;
			DEALLOCATE cur;

			DECLARE @CleanACDIds VARCHAR(MAX);
			SELECT @CleanACDIds = STRING_AGG(CAST(Id AS VARCHAR), '','') FROM #FinalACDs;

			DECLARE @HasRelations BIT = CASE 
											WHEN (SELECT COUNT(*) FROM #FinalACDs) < (SELECT COUNT(*) FROM #TmpACDs)
											THEN 1 ELSE 0 
										END;


			SELECT 
				@HasRelations AS HasRelations,
				ISNULL(@CleanACDIds, '''') AS ACDIds;

			IF OBJECT_ID(''tempdb..#TmpACDs'') IS NOT NULL DROP TABLE #TmpACDs;
			IF OBJECT_ID(''tempdb..#FinalACDs'') IS NOT NULL DROP TABLE #FinalACDs;
			IF OBJECT_ID(''tempdb..#ClassifiedACDs'') IS NOT NULL DROP TABLE #ClassifiedACDs;
		END


		ELSE IF @Option = 1 -- Camps
		BEGIN
			IF OBJECT_ID(''tempdb..#TmpOutIDs'') IS NOT NULL DROP TABLE #TmpOutIDs;

			CREATE TABLE #TmpOutIDs (Id INT);

			INSERT INTO #TmpOutIDs (Id)
			SELECT CAST(Value AS INT)
			FROM dbo.fn_RIASplitDelimited(@CamIds, '','');

			DECLARE cur CURSOR LOCAL FOR
			SELECT Id
			FROM #TmpOutIDs
			WHERE EXISTS (
				SELECT 1
				FROM ccVirtualAgent v
				WHERE v.idCampaign = Id AND v.campType = 1 AND v.mediaType = 10
			);

			OPEN cur;
			FETCH NEXT FROM cur INTO @CurrentId;

			WHILE @@FETCH_STATUS = 0
			BEGIN
				UPDATE ccVirtualAgent
				SET idCampaign = 0,
					mediaType = NULL
				WHERE idCampaign = @CurrentId AND campType = 1 AND mediaType = 10;

				FETCH NEXT FROM cur INTO @CurrentId;
			END

			CLOSE cur;
			DEALLOCATE cur;

			DROP TABLE #TmpOutIDs;
		END
	END'
	EXEC(@sql);
	--------------------------------- END DMM --------------------------------------------------------

	---------------------------------- BEGIN MACL -------------------------------------------------
	SET @process = 'K070190 se agregan filtros al sp ccspGalatea_Finder'
	SET @sql = '
ALTER PROCEDURE [dbo].[ccspGalatea_Finder] 
				@action INT, 
				@userId INT = 0, 
				@conversationId BIGINT = 0,
				@isSuperUser bit=0
				AS
				IF @action = 1
				    BEGIN--trae el nombre de la base de datos en BX
				    if @isSuperUser =0 begin

				            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, c.cam_descripcion AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
				                INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
				                                        AND WGCam.Tipo = 1
				            WHERE Wguser.User_id = @userId
				            UNION
				            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, inb.descripcion AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
				                INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
				                                            AND WGCam.Tipo = 0
				            WHERE Wguser.User_id = @userId;
				        end
				        else begin
				        SELECT CAST(c.cam_id AS INT) AS [Value], CAST(2 AS INT) AS callType, c.cam_descripcion AS label FROM ccCamps c
				        UNION
				        SELECT CAST(inb.Inbound_id AS INT) AS [Value], CAST(1 AS INT) AS callType, inb.descripcion AS label FROM ccInbound inb;
				        end
				        RETURN 0;
				END;
				IF @action = 2
				    BEGIN
				    if @isSuperUser =0 begin
				        WITH WgId
				            AS (SELECT IDWG
				                FROM ccRIAWorkGroupUsers Wguser
				                WHERE Wguser.User_id = @userId)
				            SELECT DISTINCT 
				                    CAST(Wguser.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN WgId ON Wguser.IDWG = WgId.IDWG
				                INNER JOIN ccUsers ON ccUsers.User_id = Wguser.User_id
				                                        AND TipoUser_id = 1;
				end
				else begin
				        select CAST(ccUsers.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
				        from ccUsers where TipoUser_id = 1;
				end
				        RETURN 0;
				END;
				IF @action = 3
				         BEGIN--Informacion de la conversacion de whatsApp
				               SELECT A.ConversationID, A.inboundId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneACD AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID, C.Login AS UserName
				                        ,(cast(sum(A.tConversation) / 3600 as varchar(10)) + '':'' + 
				                        right(''0'' + cast((sum(A.tConversation) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                        right(''0'' + cast(sum(A.tConversation) % 60 as varchar(10)), 2)) as Duration
				             FROM ccWhatsAppConversations A
				                  LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccRIAInboundGraph graph ON graph.Inbound_id = A.inboundId
				                  LEFT JOIN ccUsers C ON A.agentId = C.User_id
				             WHERE A.conversationId = @conversationId
				             group by A.conversationId, A.inboundId, graph.graphic_id, A.phoneACD, A.clientId, B.descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc, conversationDate, requestDate, A.agentId, C.Login;

				             RETURN 0;
				     END;
				IF @action = 4
				         BEGIN--Informacion de la conversacion de whatsApp out
				               SELECT A.ConversationID, A.camId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneCamp AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.cam_descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID, C.Login AS UserName
				                        ,(cast(sum(A.tConversation) / 3600 as varchar(10)) + '':'' + 
				                        right(''0'' + cast((sum(A.tConversation) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                        right(''0'' + cast(sum(A.tConversation) % 60 as varchar(10)), 2)) as Duration
				             FROM ccWhatsAppConversationsOut A
				                  LEFT JOIN ccCamps B ON A.camId = B.cam_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = A.camId
				                  LEFT JOIN ccUsers C ON A.agentId = C.User_id
				             WHERE A.conversationId = @conversationId
				             group by A.conversationId, A.camid, graph.graphic_id, A.phoneCamp, A.clientId, B.cam_descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc, conversationDate, requestDate, A.agentId, C.Login;

				             RETURN 0;
				     END;
				IF @action = 5
				         BEGIN--Informacion de la conversacion de Chat
				                SELECT A.ChatId AS ConversationID, A.inboundId AS CampaignId, A.userId AS AgentID, ISNULL(B.descripcion, ''N/A'') AS CampaignName,
							   ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, 
							   C.Login AS UserName, A.clientName as Client, ISNULL(A.chatDate, A.requestDate) as DateStart,
							   (cast(sum(A.tChatting) / 3600 as varchar(10)) + '':'' + 
				                right(''0'' + cast((sum(A.tChatting) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                right(''0'' + cast(sum(A.tChatting) % 60 as varchar(10)), 2)) as Duration
				             FROM ccRIAChats A
				                  LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccUsers C ON A.userId = C.User_id
				             WHERE A.chatId = @conversationId
				             group by A.chatId, A.inboundId, A.userId, A.userId, B.descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc,
							 chatDate, requestDate, A.userId, C.Login, tChatting, clientName;

				             RETURN 0;
				     END;
				IF @action = 6
				BEGIN
					SELECT cfwadm.FinderWhatsAppMessageId,
                           cfwadm.Description,
                           cfwadm.OpTagEs,
                           cfwadm.OpTagEn,
                           cfwadm.OpTagPt FROM dbo.ccFinderWhatsAppDownloadedMessage AS cfwadm
					RETURN 0
				END
				IF @action = 7
				BEGIN
					SELECT [Description] AS [Label],  CAST(calif_id as VARCHAR) + ''|2'' AS [Value] FROM cctipocalifout
					UNION
					SELECT [Description] AS [Label],  CAST(calif_id as VARCHAR) + ''|1'' AS [Value] FROM cctipocalif
					RETURN 0
				END'
	EXEC(@sql)

	SET @process = 'K070098 se modifica ccsp_AvrsSyncronization para tomar en cuenta las campañas de AI'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization]
@action SMALLINT,
@maxRecordsToTransfer INT = 10,
@ids varchar(max)= 0
AS
BEGIN
SET NOCOUNT ON;

IF @action = 1
BEGIN
    DECLARE @countrId INT;
    SET @countrId = 1;

    SELECT @countrId = valor
    FROM ccSettings
    WHERE setting_id = 104;

          -- Declarar la variable tipo tabla
        declare @tempCalls table(
        cal_id INT,
        user_id INT,
        Inbound_id INT,
        calif_id int,
        cal_extension INT,
        cal_inicio DATETIME,
        phone VARCHAR(50),
        duration INT,
        cal_key VARCHAR(50),
        cal_manual int,
        cal_puerto INT,
        dni_id INT,
        fvalida datetime,
        cal_whohung int,
        califSub_id int,
        cal_tMoh INT,
        dateEnd DATETIME,
        callType INT,
        avrsId INT,
        prefijo VARCHAR(20),
        isCallRecord BIT,
        DNIS VARCHAR(50),
        IDWG VARCHAR(1000),
        IsVoicemail BIT,
		VirtualAgentId int
    );

        declare @deleteRow table(id int primary key);
        declare @relationCallIdUser table(cal_id int, user_id int);

    WITH callsIn AS (
        SELECT TOP (@maxRecordsToTransfer) 
            calls.cal_id as CallId,
            CASE WHEN ccInbound.chat = 11 THEN 0 ELSE calls.[User_id] END AS [user_id],
            calls.Inbound_id,
            calls.calif_id,
            CAST(cal_extension AS INT) AS cal_extension,
            cal_inicio,
            cal_ANI AS phone,
            ISNULL(cal_tDialog - CASE WHEN ccInbound.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0) 
            + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
            cal_key,
            0 AS cal_manual,
            cal_puerto,
            calls.dni_id,
            fvalida,
            cal_whohung,
            ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
            CASE 
                WHEN trans.tAntesXfer IS NULL THEN cal_tMoh 
                WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 
                ELSE cal_tMoh - trans.tAntesXfer 
            END AS cal_tMoh,
            DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
            avrs.tipo + 1 AS callType,
            avrs.id AS avrsId,
            ccInbound.prefijo,
            CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
            ISNULL(dni.dni_numero, '''') AS DNIS,
            dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
            0 AS IsVoicemail,
			CASE WHEN ccInbound.chat = 11 THEN calls.[User_id] ELSE 0 END AS VirtualAgentId
        FROM ccCallsIn AS calls WITH (NOLOCK)
        INNER JOIN ccInbound ON ccInbound.Inbound_id = calls.Inbound_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 0
        LEFT JOIN ccDNIS dni ON dni.dni_id = calls.dni_id
        LEFT JOIN ccInboundExtend inbExt ON inbExt.Inbound_id = calls.Inbound_id
        LEFT JOIN (
            SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers  with(nolock)
            WHERE tipo = 1 AND modo != 7
            GROUP BY cal_id, tipo
        ) trans ON calls.cal_id = trans.cal_id    
    ),
    callsOut AS (
        SELECT TOP (@maxRecordsToTransfer) 
            calls.cal_id AS CallId,
            user_id AS UserId,
            calls.cam_id AS camAcdId,
            CAST(calls.calif_id AS SMALLINT) AS califId,
            CAST(cal_extension AS INT) AS extension,
            cal_inicio,
            cal_telefono,
            ISNULL(cal_tDialog - CASE WHEN camps.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0) 
            + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
            cal_key,
            cal_manual,
            cal_puerto,
            0 AS dni_id,
            fvalida,
            cal_whohung,
            ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
            CASE 
                WHEN trans.tAntesXfer IS NULL THEN cal_tMoh 
                WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 
                ELSE cal_tMoh - trans.tAntesXfer 
            END AS cal_tMoh,
            DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
            avrs.tipo + 1 AS callType,
            avrs.id AS avrsId,
            camps.prefijo,
            CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
            '''' AS DNIS,
            dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
            CASE WHEN calls.statusCall_id = 19 THEN 1 ELSE 0 END AS IsVoicemail,
			calls.virtualAgentId as VirtualAgentId
        FROM ccoCallsOut AS calls WITH (NOLOCK)
        INNER JOIN ccCamps camps ON camps.cam_id = calls.cam_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 1
        LEFT JOIN (
            SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers with(nolock)
            WHERE tipo = 2
            GROUP BY cal_id, tipo
        ) trans ON calls.cal_id = trans.cal_id      
    )

    INSERT INTO @tempCalls                
    SELECT * FROM callsIn
    UNION 
    SELECT * FROM callsOut;


    insert into @deleteRow
    select min(avrsId) id
    from @tempCalls
    group by cal_id,callType 
    having count(*)>1
    
    delete from @tempCalls where avrsId in( select id from @deleteRow )
        delete from ccAVRSTransfer where id in( select id from @deleteRow )

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and callType=0)
    BEGIN   
                insert into @relationCallIdUser
                select A.cal_id,aglog.User_id from @tempCalls A
                inner join ccCallsIn B with(nolock) on A.cal_id=B.cal_id and A.callType=0
                inner join ccLogAgentesDia aglog with(nolock) on aglog.callID=B.cal_id and aglog.Tipo=A.callType and aglog.TipoStatusAge_id=4

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join ccCallsIn B with(nolock) on A.cal_id=B.cal_id 

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join @tempCalls B on A.cal_id=B.cal_id and B.callType=0
                
                delete from @relationCallIdUser
        END

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and callType=1 and IsVoicemail =0)
    BEGIN   
                insert into @relationCallIdUser
                select A.cal_id,aglog.User_id from @tempCalls A
                inner join ccoCallsOut B with(nolock) on A.cal_id=B.cal_id and A.callType=1
                inner join ccLogAgentesDia aglog with(nolock) on aglog.callID=B.cal_id and aglog.Tipo=A.callType and aglog.TipoStatusAge_id=4

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join ccoCallsOut B with(nolock) on A.cal_id=B.cal_id 

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join @tempCalls B on A.cal_id=B.cal_id and B.callType=1
        END

     -- Revisar si hay registros con IsVoicemail = 1
    IF EXISTS (SELECT 1 FROM @tempCalls WHERE IsVoicemail = 1)
    BEGIN            
                update A
                set A.duration=B.tDialing
                FROM @tempCalls A
                Inner JOIN ccoLogDials B with(nolock) ON A.cal_id=B.cal_id
        WHERE A.IsVoicemail = 1;
    END

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and IsVoicemail=0)
    BEGIN
                delete A from ccAVRSTransfer A
                inner join @tempCalls t on A.id=t.avrsId 
                where t.user_id=0 and t.IsVoicemail=0
        END
        
    -- Si no hay registros con IsVoicemail, simplemente devolver los resultados de la variable tipo tabla
    SELECT * FROM @tempCalls;
        
END
ELSE IF @action = 2
BEGIN
    Delete A
    from ccAVRSTransfer A
    inner join dbo.fn_RIASplitDelimited(@ids,'','') t on A.id=t.Value
    
END
END;
'
	EXEC(@sql)

	---------------------------------- END MACL -------------------------------------------------

    /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
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
