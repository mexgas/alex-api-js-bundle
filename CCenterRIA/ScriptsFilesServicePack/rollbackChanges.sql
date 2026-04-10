USE CCenterRIA
GO
/******************************** rollback file 01 ccCalifCampIA.sql **************************************************/
IF  exists(select * from sys.tables where name='ccCalifCampIA') begin
	DROP TABLE ccCalifCampIA
END

GO
/******************************** rollback file 02 InsertOperationsToGalateaActivity.sql **************************************************/
use CCenterRIA;
GO

IF EXISTS (
	SELECT 1
	FROM ccGalateaOperations
	WHERE OperationId = 175
)
BEGIN
	DELETE FROM dbo.ccGalateaOperations WHERE OperationId = 175
END
IF EXISTS (
	SELECT 1
	FROM ccGalateaOperations
	WHERE OperationId = 176
)
BEGIN
	DELETE FROM dbo.ccGalateaOperations WHERE OperationId = 176
END

IF EXISTS (
    SELECT 1
    FROM ccGalateaOperations
    WHERE OperationId = 177
)
BEGIN
    DELETE FROM dbo.ccGalateaOperations WHERE OperationId = 177
END

IF EXISTS (
	SELECT 1
	FROM ccGalateaOperations
	WHERE OperationId = 178
)
BEGIN
	DELETE FROM dbo.ccGalateaOperations WHERE OperationId = 178
END

IF EXISTS (
	SELECT 1
	FROM ccGalateaOperations
	WHERE OperationId = 179
)
BEGIN
	DELETE FROM dbo.ccGalateaOperations WHERE OperationId = 179
END

--Nombre
 IF EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_NAME' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'Name_cal')
BEGIN
	DELETE FROM dbo.relationTableColumnIdentifiers WHERE  Identifiers = 'AI_UPDATE_DISPOSITION_NAME' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'Name_cal'
END
IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_NAME')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_NAME'
END

--Descripción
 IF EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_DESCRIPTION' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'Description_cal')
BEGIN
	DELETE FROM dbo.relationTableColumnIdentifiers WHERE  Identifiers = 'AI_UPDATE_DISPOSITION_DESCRIPTION' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'Description_cal'
END
IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_DESCRIPTION')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_DESCRIPTION'
END

--Devolver llamada 
 IF EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_CALLBACK' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'CanReprogram')
BEGIN
	DELETE FROM dbo.relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_CALLBACK' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'CanReprogram'
END
IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_CALLBACK')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_CALLBACK'
END
--Color
 IF EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_COLOR' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'Color')
BEGIN
	DELETE FROM dbo.relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_COLOR' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'Color'
END
IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_COLOR')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_COLOR'
END
--Transferencia
IF EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_TRANSFER' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'AplTransfer')
BEGIN
	DELETE FROM dbo.relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_TRANSFER' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'AplTransfer'
END
IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER'
END
--Transferencia RadioButton
IF EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'TransferOpcion')
BEGIN
	DELETE FROM dbo.relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'TransferOpcion'
END
IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION'
END
--Extracción
IF EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_EXTRACTION' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'AplExtDate')
BEGIN
	DELETE FROM dbo.relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_EXTRACTION' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'AplExtDate'
END
IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_EXTRACTION')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_EXTRACTION'
END
--Descripción Extracción
IF EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_EXTRACTION_DESCRIPTION' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'ExtDescription')
BEGIN
	DELETE FROM dbo.relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_EXTRACTION_DESCRIPTION' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'ExtDescription'
END
IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_EXTRACTION_DESCRIPTION')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_EXTRACTION_DESCRIPTION'
END
--LN
IF EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_DNC' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'AplBlackList')
BEGIN
	DELETE FROM dbo.relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_DNC' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'AplBlackList'
END
IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_DNC')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_DNC'
END

IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION_1')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION_1'
END

IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION_2')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION_2'
END

IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION_3')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION_3'
END



IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_CALLBACK_OPTION_1')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_CALLBACK_OPTION_1'
END

IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_CALLBACK_OPTION_2')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_CALLBACK_OPTION_2'
END

IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_CALLBACK_OPTION_3')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_CALLBACK_OPTION_3'
END

IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_CAMPAIGN')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_CAMPAIGN'
END

IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_NUMBER')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_NUMBER'
END

IF EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_DIRECTORY')
BEGIN
	DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_DIRECTORY'
END

GO

/******************************** rollback file 03 ccsp_GalateaAdminDispositionRelations.sql **************************************************/
ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositionRelations]
@command int,
@type tinyint = null, --0=In, 1=Out
@cam_id smallint = null,
@califIdLst varchar(8000) = null,
@user_id smallint = null
AS
set nocount on
declare @sql as nvarchar(max)

If @command = 1
begin
	select 
		cast (0 as int) [type], 
		i.inbound_id as cam_id, 
		c.calif_id 
	from ccInbound i inner join ccCalifCamp c on i.inbound_id = c.cam_id and c.tipo = 0
	inner join ccTipoCalif t on c.calif_id = t.calif_id
	UNION
	select 
		cast (1 as int) [type], 
		o.cam_id, 
		c.calif_id 
	from ccCamps o inner join ccCalifCamp c on o.cam_id = c.cam_id and c.tipo = 1
	inner join ccTipoCalifOUT co on c.calif_id = co.calif_id
	order by [type], cam_id, calif_id
end
If @command=2  --Asignar calificacion(es) a una campaña de entrada o salida
 begin 
	if @Type=0 
	begin	
		set @sql = 'declare @NotAssigned table(NotAssigned int); 
		declare @Assigned table(Assigned int);

		insert into @NotAssigned (NotAssigned)
		select calif_id from ccTipoCalif where CanReprogram=1 and calif_id in (' + @califIdLst + ')
		and exists(select inbound_id from ccInbound where cam_id is null and Inbound_id= ' + cast(@cam_id as varchar(10)) + ')

		insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.inbound_id, 0 
		from ccInbound e, cctipoCalif f 
		where f.Calif_Status=1 and f.calif_id in (' + @califIdLst + ') and f.calif_id not in (select NotAssigned from @NotAssigned)
		and Inbound_id = ' + cast(@cam_id as varchar(10)) + '
		and not exists(
			select a.calif_id,c.inbound_id,0 from cctipoCalif a
			join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 0
			join ccInbound c on c.inbound_id = b.cam_id
			where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id
			and c.Inbound_id = ' + cast(@cam_id as varchar(10)) + ')

		insert into @Assigned (Assigned)
		select calif_id from ccTipoCalif where calif_id in (' + @califIdLst + ') and calif_id not in (select NotAssigned from @NotAssigned)

		declare @NotAssignedStr varchar(8000), @AssignedStr varchar(8000)
		SELECT @AssignedStr = COALESCE(@AssignedStr + '','', '''') + cast(Assigned as varchar(10)) from @Assigned
		select @NotAssignedStr = coalesce(@NotAssignedStr + '','', '''') + cast(NotAssigned as varchar(10)) from @NotAssigned

		select @AssignedStr [Assigned], @NotAssignedStr [NotAssigned]'
		execute sp_executesql @sql
	end
	else
	begin
		set @sql = 'insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalifOUT f where 
		f.CalifOut_Status=1 and f.calif_id in (' + @califIdLst + ') and cam_id = ' + cast(@cam_id as varchar(10)) + '
		and not exists(
		select a.calif_id,c.cam_id, 1 from cctipoCalifOUT a
		join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 1
		join ccCamps c on c.cam_id = b.cam_id
		where f.calif_id = a.calif_id and e.cam_id = c.cam_id
		and b.cam_id = ' + cast(@cam_id as varchar(10)) + ')'
		execute sp_executesql @sql
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id	
		return(0)
	end
 end
 If @command=3 -- Desasignar calificacion de campaña de entrada o salida
 begin
	delete ccCalifCamp where cam_id=@cam_id and tipo=@type and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id
	return(0)
 end
 If @command=4 
 begin
	IF(@type = 0) 
	BEGIN
		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
		SELECT 
			(select AreaName from ccRIACat_Areas c inner join ccInbound i on c.IDArea = i.IDArea where Inbound_id = @cam_id),
			getDate(),
			(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
			68,
			7,
			'',
			Description,
			(select descripcion from ccInbound where Inbound_id = @cam_id)
			from ccTipoCalif 
			where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
	END
 end
 If @command=5
 begin
	IF(@type = 0) 
	BEGIN
		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
		SELECT 
			(select AreaName from ccRIACat_Areas c inner join ccInbound i on c.IDArea = i.IDArea where Inbound_id = @cam_id),
			getDate(),
			(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
			69,
			7,
			'',
			Description,
			(select descripcion from ccInbound where Inbound_id = @cam_id)
			from ccTipoCalif 
			where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
	END
 end

set nocount off
GO
/******************************** rollback file 04 ccsp_ManageQuantumDispositions.sql **************************************************/
ALTER PROCEDURE [dbo].[ccsp_ManageQuantumDispositions]
				@Action INT,
				@CampId INT = NULL,
				@AgentId INT = NULL,
				@CampType INT = NULL,
				@VoiceId INT = NULL
		AS
		BEGIN
			DECLARE @Inbound INT = 0, @Outbound INT = 1
			IF @Action = 1 --Get API Data
			BEGIN
				DECLARE @key VARCHAR(255)
				SELECT @key = valor FROM ccSettings2 WHERE setting_id = 284
				SELECT valor AS ApiUrl, @key AS [Key] FROM ccSettings2 WHERE setting_id = 290
			END
			IF @Action = 2 --Get Quantum Id Agent Data
			BEGIN
				SELECT quantumAgentId
				FROM ccVirtualAgent
				WHERE 
					(@AgentId IS NOT NULL AND idAgent = @AgentId)
					OR (@AgentId IS NULL AND campType = @CampType AND idCampaign = @CampId);
			END
			IF @Action = 3 --Get Quantum Dispositions by camp
			BEGIN
				IF @CampType = @Inbound
				BEGIN
					SELECT tc.calif_id AS [Id], tc.[Description] AS [Description], tc.CanReprogram as Callback
					FROM ccCalifCamp cc INNER JOIN ccTipoCalif tc
					ON cc.calif_id = tc.calif_id
					WHERE cc.tipo = 0
					AND cc.cam_id = @CampId
				END
				IF @CampType = @Outbound
				BEGIN
					SELECT tc.calif_id AS [Id], tc.[Description] AS [Description], tc.CanReprogram as Callback
					FROM ccCalifCamp cc INNER JOIN ccTipoCalifOut tc
					ON cc.calif_id = tc.calif_id
					WHERE cc.tipo = 1
					AND cc.cam_id = @CampId
				END
			END
			IF @Action = 4 -- Get Quantum Agent Voice Id
			BEGIN
				SELECT ISNULL(
					(SELECT QuantumVoiceId 
					 FROM ccVirtualAgentVoices 
					 WHERE ID = @VoiceId), 
					''
				) AS QuantumVoiceId;
			END

			IF @Action = 5 -- Get Transfer Status 
			BEGIN
				IF @CampType = 0
				BEGIN
					SELECT 
						 CASE 
						-- 1. If both transfer options are disabled (0), return FALSE (0).
						WHEN ISNULL(cie.TransferToHumanAgents, 0) = 0 
							 AND ISNULL(cie.TransferOnSuccessfulHandling, 0) = 0 THEN CAST(0 AS BIT)

						-- 2. LOGICAL VALIDATION:
						-- Ensure that all active configurations are valid and have no missing requirements.
						WHEN 
							(
								-- Validate 'TransferToHumanAgents' integrity
								CASE 
									WHEN cie.TransferToHumanAgents = 2 THEN 1 -- Valid: External transfer
									WHEN cie.TransferToHumanAgents = 1 AND ISNULL(ci2.idForNonComprehension, 0) <> 0 THEN 1 -- Valid: Campaign transfer with assigned ID
									WHEN cie.TransferToHumanAgents = 0 THEN 1 -- Valid: Option is disabled, skip validation
									ELSE 0 -- Invalid: Option enabled but missing target campaign ID
								END = 1
							)
							AND -- ALL enabled configurations must be valid simultaneously
							(
								-- Validate 'TransferOnSuccessfulHandling' integrity
								CASE 
									WHEN cie.TransferOnSuccessfulHandling = 2 THEN 1 -- Valid: External transfer
									WHEN cie.TransferOnSuccessfulHandling = 1 AND ISNULL(ci2.idForSuccessfulTransaction, 0) <> 0 THEN 1 -- Valid: Campaign transfer with assigned ID
									WHEN cie.TransferOnSuccessfulHandling = 0 THEN 1 -- Valid: Option is disabled, skip validation
									ELSE 0 -- Invalid: Option enabled but missing target campaign ID
								END = 1
							)
							THEN CAST(1 AS BIT)

						ELSE CAST(0 AS BIT)
					END
					FROM dbo.ccInboundExtend AS cie
					INNER JOIN dbo.ccInbound AS ci2
					ON ci2.Inbound_id = cie.Inbound_id
					WHERE cie.Inbound_id= @CampId;
				END
				ELSE
				BEGIN
					SELECT 
					CASE 
						WHEN EXISTS (SELECT 1 FROM dbo.ccInbound WHERE cam_id = @CampId) 
						THEN CAST(1 AS BIT) 
						ELSE CAST(0 AS BIT) 
					END AS ExisteCampana;
				END
			END

			IF @Action = 6 -- Agent Id By Campaign 
			BEGIN
				IF(@CampType = 0)
				BEGIN
				
					SELECT ISNULL(
						(SELECT TOP 1 idAgent 
						 FROM ccVirtualAgent 
						 WHERE idCampaign = @CampId 
						   AND mediaType = 11
						   AND campType = 0),
						0
					) AS idAgent;
				END
				ELSE
				BEGIN
					SELECT ISNULL(
							(SELECT TOP 1 idAgent 
							 FROM ccVirtualAgent 
							 WHERE idCampaign = @CampId 
							   AND mediaType = 10 AND campType = 1),
							0
						) AS idAgent;
				END
			END
		END
GO	


/******************************** rollback file 05 ccsp_GalateaAdminInbound.sql **************************************************/
ALTER PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                            @InboundId AS SMALLINT = 0,
											@User_id AS SMALLINT = 0,
											@OutboundID AS SMALLINT = 0,
											@multi_cam as varchar(max) = null,
											@Module AS SMALLINT = 13,
											@Type AS SMALLINT = 0,
											@HistoryAction AS SMALLINT = 1,
											@AreaId AS SMALLINT = 0,
											@NonComprehensionId AS SMALLINT = -1,
											@SuccessfulTransactionCampaignId AS SMALLINT = -1,
											@CallBackCampaignId AS SMALLINT = -1,
											@IsEditing AS BIT = 0
		AS
		BEGIN
			set nocount on;

			DECLARE @idArea SMALLINT = NULL;
			DECLARE @operation INT = -1;
			DECLARE @mediaType INT = 0;

			IF(@Option IN (5, 6)) BEGIN
				IF(@Module IS NOT NULL AND @Module <> 13) BEGIN
				
					IF(@Type = 0)BEGIN
						
						IF(@multi_cam is not null) BEGIN
							SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,',')))
						END ELSE BEGIN
							SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id = @InboundId)
						END

						SET @operation = CASE WHEN @HistoryAction = 1 THEN 
																			CASE 
																					WHEN @mediaType = 1  THEN 63
																					WHEN @mediaType = 5  THEN 40
																					ELSE 60 END
																	  ELSE 
																			CASE 
																					WHEN @mediaType = 1  THEN 64
																					WHEN @mediaType = 5  THEN 53
																					ELSE 52 END
																	  END;
					END ELSE BEGIN

						SET @mediaType = (SELECT [CampType] FROM ccCamps WHERE cam_id = @OutboundID)

						SET @operation = CASE WHEN @HistoryAction = 1 THEN 
																			CASE 
																					WHEN @mediaType = 6  THEN 44
																					WHEN @mediaType = 5  THEN 46
																					WHEN @mediaType = 9  THEN 48
																					WHEN @mediaType = 7  THEN 50
																					ELSE 42 END
																	   ELSE 
																			CASE 
																					WHEN @mediaType = 6  THEN 55
																					WHEN @mediaType = 5  THEN 56
																					WHEN @mediaType = 9  THEN 57
																					WHEN @mediaType = 7  THEN 58
																					ELSE 54 END
																	    END;
					END

				END ELSE BEGIN
					SET @operation = CASE WHEN @Option = 5 THEN 93 ELSE 94 END;
				END
			END

			if(@Option = 1) -- Por campaña 
			begin
			    select 
			        ISNULL(count (*), 0) as Calls,
			        ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
			        ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
			        ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
			        ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
			        ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
			        ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
			        ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
			        ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
			        ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
			        THEN 1 ELSE NULL END), 0) AS Other
			    from ccCallsIn a (nolock)
			    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId

			end

			if(@Option = 2) -- Todas las campañas 
			begin
			    select 
					inbound.Inbound_id as IDEspec,
					inbound.descripcion as Name,
			        ISNULL(count (*), 0) as Calls,
			        ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
			        ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
			        ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
			        ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
			        ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
			        ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
			        ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
			        ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
			        ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
			        THEN 1 ELSE NULL END), 0) AS Other
			    from ccCallsIn a (nolock)
				left join ccInbound inbound on a.inbound_id = inbound.Inbound_id
			    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) 
				group by inbound.Inbound_id, inbound.descripcion
			end

			if(@Option = 3) -- Obtiene los datos de las llamadas de todos los ACD, datos que se muestran en el tablero de información del administrador 
			begin
				SELECT 
					a.inbound_id, calls = ISNULL(COUNT(*), 0), -- calls
					Dialogs = ISNULL(COUNT (CASE WHEN statusCall_id = 13 THEN 1 ELSE NULL END), 0), -- Answered
					DlgsAveTime =CONVERT(int, ISNULL(SUM (CASE WHEN statusCall_id = 13 THEN cal_tDialog + cal_tNotas ELSE 0 END), 0)),
					QueueAveTime =ISNULL( avg( CASE WHEN cal_que > 0 THEN cal_tWait ELSE NULL END), 0) ,
					abandon = ISNULL(COUNT(CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0), -- Abandoned
					OverFlowQueue = ISNULL(COUNT (CASE WHEN statusCall_id =8 THEN 1 ELSE NULL END), 0),
					OverFlowTimeOut = ISNULL(COUNT (CASE WHEN statusCall_id =7 THEN 1 ELSE NULL END), 0), -- OverFlowQueue+OverFlowTimeOut = not answered
					outOfSchedule = ISNULL(COUNT (CASE WHEN statusCall_id =2 THEN 1 ELSE NULL END), 0), -- fuera de horario
					outOfService = ISNULL(COUNT (CASE WHEN statusCall_id =3 THEN 1 ELSE NULL END), 0), -- fuera de servicio
					noAgentsLoggedIn = ISNULL(COUNT (CASE WHEN statusCall_id =4 THEN 1 ELSE NULL END), 0), -- sin agentes firmados
					assigned = ISNULL(COUNT (CASE WHEN statusCall_id =11 THEN 1 ELSE NULL END), 0), -- asignada
					--assignedAndNotAnswered = ISNULL(COUNT (CASE WHEN statusCall_id =15 THEN 1 ELSE NULL END), 0), -- asignada y no contestada
					--assignedAndTookLine = ISNULL(COUNT (CASE WHEN statusCall_id =16 THEN 1 ELSE NULL END), 0), -- asignada y toma linea
					callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0)
					--onQueue = ISNULL(COUNT(CASE WHEN statusCall_id = 5 THEN 1 ELSE NULL END), 0)
					--initCalls = CAST(ISNULL(COUNT(CASE WHEN statusCall_id = 1 THEN 1 ELSE NULL END), 0) AS varchar(7))+'|'+
					--			ISNULL((SELECT STUFF((SELECT '|' + cast(ci.cal_id AS varchar(7))
					--			FROM ccCallsin ci (nolock) WHERE cal_inicio > dateadd(mi,-5,getdate()) AND ci.inbound_id=a.inbound_id
					--			FOR XML PATH('')) ,1,1,'')),'0')
				FROM ccCallsIn a (nolock)
				WHERE cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
						--and a.inbound_id in (select cam_id from ccSupervisorCam where user_id = @User_id and tipo = 0)
				GROUP BY a.inbound_id
			--	SET nocount off
			--	return(0)
			end

			if(@Option = 4) -- Carga los ACD del administrador mandado
			begin
				SELECT cam_id 
				FROM ccSupervisorCam  nolock
				WHERE user_id = @User_id and tipo = 0
				SET nocount off
				return(0)
			end

			IF(@Option = 5) -- Relate the inbound campaign with the outbound campaign
			BEGIN
				IF(@idArea IS NULL OR @idArea = -1) SET @idArea = 
					CASE WHEN @Type = 0 
						THEN 
							CASE WHEN @multi_cam IS NULL
								THEN (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @InboundID) 
								ELSE (SELECT [IDArea] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,',')))
								END
						ELSE (SELECT [IDArea] FROM ccCamps WHERE cam_id = @OutboundID)
						END

				IF(@multi_cam is not null)
				BEGIN
					UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id IN (
						SELECT value from dbo.fn_RIASplitDelimited(@multi_cam,','))

					IF (@multi_cam <> '' )
					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
					SELECT
						(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
						getDate(), 
						(SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
						@operation,
						@Module,
						CASE WHEN @Module = 13 THEN '' ELSE 'ASSOCIATED_CAMP_CALLBACK' END,
						CASE WHEN @Type = 0 THEN
												(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @OutboundID)
											ELSE 
												(SELECT [descripcion] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,',')))
											END,
						CASE WHEN @Type = 0 THEN
												(SELECT [descripcion] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,',')))
											ELSE 
												(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @OutboundID)
											END

					SELECT 1;
					RETURN 1;
				END
				IF((SELECT ISNULL(cam_id,0) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId and chat in (0,11)) != 0 )
					BEGIN
						SELECT -1;
						RETURN -1;
					END;
				ELSE
					BEGIN
						UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id = @InboundID;
							
						IF(@Type <> 1 AND @InboundID <> 0)
						INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
						SELECT
							(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
							getDate(), 
							(SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
							@operation,
							@Module,
							CASE WHEN @Module = 13 THEN '' ELSE 'ASSOCIATED_CAMP_CALLBACK' END,
							(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [cam_id] FROM ccInbound WHERE Inbound_id = @InboundID)),
							(SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @InboundID)

						SELECT 1;
						RETURN 1;
					END;
			END;        
			IF(@Option = 6) -- Delete the relation between inbound and outbound campaigns
			BEGIN

			IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @InboundID)
							
				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
				SELECT
					(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
					getDate(), 
					(SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
					@operation,
					@Module,
					CASE WHEN @Module = 13 THEN '' ELSE 'DISASSOCIATED_CAMP_CALLBACK' END,
					(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [cam_id] FROM ccInbound WHERE Inbound_id = @InboundID)),
					(SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @InboundID)

				UPDATE ccInbound SET cam_id = null WHERE Inbound_id = @InboundId;
				SELECT 1;
				RETURN 1;
			END;
			IF(@Option = 7) -- Check if the inbound Campaign is related
			BEGIN
				SELECT CAST(CASE WHEN cam_id IS NULL OR cam_id = 0 THEN -1 ELSE cam_id END AS INT) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId;
			END
			IF(@Option = 8) -- Delete the relation between inbound campaings which are related to outdbound campaign
			BEGIN
				UPDATE ccInbound SET cam_id = null WHERE cam_id = @OutboundID;
				SELECT 1;
				RETURN 1;
			END
			IF(@Option = 9)
			BEGIN
				
				SET @Module = 3 --Corresponds to "Area", reference in ccGalateaModules
				SET @operation = CASE @IsEditing WHEN 1 THEN 138 ELSE 137 END -- Corresponds to edition and creation, reference ccGalateaOperations

				DECLARE @CurrentNonComprehensionId SMALLINT, 
						@CurrentCallbackId SMALLINT, 
						@CurrentSuccessfullTransactionId SMALLINT,
						@UserName VARCHAR(40),
						@AreaName VARCHAR(50),
						@CampaignName VARCHAR(40)

				SELECT @AreaName = AreaName  FROM ccRIACat_Areas WHERE IDArea = @AreaId
				SELECT @UserName = Login FROM ccUsers WHERE User_id = @User_id

				SELECT 
					@CurrentNonComprehensionId = ISNULL( idForNonComprehension , -1 ),
					@CurrentCallbackId = ISNULL( cam_id, -1 ),
					@CurrentSuccessfullTransactionId = ISNULL( idForSuccessfulTransaction, -1),
					@CampaignName = descripcion
				FROM ccInbound WHERE Inbound_id = @InboundId

				IF @CurrentCallbackId <> @CallBackCampaignId AND @CallBackCampaignId <> -1
				BEGIN
					UPDATE ccInbound
					SET cam_id = @CallBackCampaignId
					WHERE Inbound_id = @InboundId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@AreaName, 
							GETDATE(), 
							@UserName, 
							@operation, 
							@Module, 
							'ASSOCIATED_CAMP_CALLBACK', 
							CASE @CallBackCampaignId WHEN 0 THEN 'COMMON_NONE_O' ELSE (SELECT cam_descripcion FROM ccCamps WHERE cam_id = @CallBackCampaignId) END,
							@CampaignName)
				END

				IF @CurrentNonComprehensionId <> @NonComprehensionId AND @NonComprehensionId <> -1
				BEGIN
					UPDATE ccInbound
					SET idForNonComprehension = @NonComprehensionId
					WHERE Inbound_id = @InboundId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@AreaName, 
							GETDATE(), 
							@UserName, 
							@operation, 
							@Module, 
							'ASSOCIATED_CAMP_XFER_IA', 
							CASE @NonComprehensionId WHEN 0 THEN 'COMMON_NONE_O' ELSE (SELECT descripcion FROM ccInbound WHERE Inbound_id = @NonComprehensionId) END,
							@CampaignName)
				END

				IF @CurrentSuccessfullTransactionId <> @SuccessfulTransactionCampaignId AND @SuccessfulTransactionCampaignId <> -1
				BEGIN
					UPDATE ccInbound
					SET idForSuccessfulTransaction = @SuccessfulTransactionCampaignId
					WHERE Inbound_id = @InboundId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@AreaName, 
							GETDATE(), 
							@UserName, 
							@operation, 
							@Module, 
							'ASSOCIATED_CAMP_SUCCESSFUL_TRANSACTION', 
							CASE @SuccessfulTransactionCampaignId WHEN 0 THEN 'COMMON_NONE_O' ELSE (SELECT descripcion FROM ccInbound WHERE Inbound_id = @SuccessfulTransactionCampaignId) END,
							@CampaignName)
				END

				SELECT 1
			END
		END
    
GO
/******************************** rollback file 06 cctipoCalif_IA.sql **************************************************/
IF  exists(select * from sys.tables where name='cctipoCalif_IA') begin
	DROP TABLE cctipoCalif_IA
END

GO
/******************************** rollback file 07 ccsp_GalateaAdminDispositions.sql **************************************************/
ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
                @command int,
                @calif_id smallint = null,
                @califIdLst varchar(8000) = null,
                @description varchar(150)=null,
                @order tinyint=null,
                @canReprogram bit = null,
                @graphColor varchar(15) = null,
                @endConversation bit=null,
                @keepDial bit=null,
                @autoCB bit=null,
                @contactOwner bit=null,
                @finishPreview bit = 0,
                @allNumbersToBlacklist bit = 0,
    			@FinishRecordPreview bit = 0
                AS
                set nocount on
                declare @inserted table (ID smallint)

                if @command=1 -- Load Inbound Dispositions
                begin
                  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
                  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd, graphColor
                  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
                  where C.Calif_Status=1
                  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation, graphColor
                  order by 2
                  return(0)
                end

                If @command=2 -- Load Outbound Dispositions
                begin
                  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
                  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
                  IsNull(C.finishPreview,0) as finishPreview, graphColor, allNumbersToBlacklist, ISNULL(C.FinishRecordPreview,0) as FinishRecordPreview
                  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
                  where C.CalifOut_Status=1
                  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
                  C.contactOwner, C.finishPreview, graphColor, allNumbersToBlacklist, C.FinishRecordPreview
                  order by 2
                  return(0)
                end

                If @command=3 -- New ccTipoCalif
                begin
                  If exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@description)
                    begin
                      select cast(-1 as smallint) [result]  -- Disposition already exists
                      return(0)
                    end

                  If exists(select calif_id from ccTipoCalif where Calif_Status=0 and description=@description)
                  begin
                    select top 1 @calif_id = calif_id from ccTipoCalif where Calif_Status=0 and description=@description order by calif_id desc
                    update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
                    graphColor=isnull(@graphColor, '1DB4E2'), Calif_Status=1
                    output inserted.calif_id into @inserted
                    where calif_id=@calif_id
                    select ID [result] from @inserted 
                    return(0)
                  end

                  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
                  output inserted.calif_id into @inserted
                  select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, '1DB4E2') from ccTipoCalif
                  select ID [result] from @inserted
                  return(0)
                end

                If @command=4 -- New ccTipoCalifOUT
                begin
                  If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
                  begin
                  select cast(-1 as smallint) [result]  -- Disposition already exists
                  return(0)
                  end

                 If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
                 begin
                    select top 1 @calif_id = calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description order by calif_id desc
                    update ccTipoCalifOut set autoTime=0, orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), idTipoLista=0,
                    Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
                    finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, '1DB4E2'), FinishRecordPreview = isnull(@FinishRecordPreview,0)
                    output inserted.calif_id into @inserted
                    where calif_id=@calif_id
                    select ID [result] from @inserted 
                    return(0)
                 end

                 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor, allNumbersToBlacklist,FinishRecordPreview)
                 output inserted.calif_id into @inserted
                 select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
                 isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, '1DB4E2'), ISNULL(@allNumbersToBlacklist,0), FinishRecordPreview = isnull(@FinishRecordPreview,0) from ccTipoCalifOut
                 select ID [result] from @inserted 
                 return(0)
                end
                If @command=5 -- Delete Inbound Dispositions
                begin
                    delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
                    delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
                    update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
                    return(0)
                end
                if @command=6 -- Delete Outbound Disposition
                begin
                    delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
                    delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
                    update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
                    update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
                    return(0)
                end
                if @command=7 -- Update Inbound Disposition
                begin
                    if(exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@Description and calif_id<>@calif_id))
                    begin
                        select cast(-1 as smallint) [result]    -- Disposition already exists
                        return(0)
                    end

                    UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
                    canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  
                    EndConversation=isnull(@endConversation,EndConversation)
                    output inserted.calif_id into @inserted
                    where calif_id=@calif_id

                    delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
                    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

                    select ID [result] from @inserted
                    return(0)
                end
                if @command=8 -- Update Outbound Disposition
                begin
                    if(exists(select calif_id from ccTipoCalifOUT where CalifOut_Status=1 and Description=@description and calif_id<>@calif_id))
                    begin
                        select cast(-1 as smallint) [result]    -- Disposition already exists
                        return(0)
                    end

                    UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
                    canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial), 
                    autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), 
                    finishPreview = isnull(@finishPreview,finishPreview), allNumbersToBlacklist = isnull(@allNumbersToBlacklist, allNumbersToBlacklist),  FinishRecordPreview = isnull(@FinishRecordPreview,FinishRecordPreview)
                    output inserted.calif_id into @inserted
                    where calif_id=@calif_id

                    if @keepDial is not null
                    begin
                        update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
                    end

                    select ID [result] from @inserted
                    return(0) 
                    end

                set nocount OFF
GO                
/******************************** rollback file 08 ccsp_GalateaGetCampaignsIAController.sql **************************************************/
IF EXISTS (SELECT * FROM sysobjects WHERE name='ccsp_GalateaGetCampaignsIAController')
BEGIN
	DROP PROCEDURE dbo.ccsp_GalateaGetCampaignsIAController
END
GO
/******************************** rollback file 09 ALTER TABLE dbo.ccVirtualAgent.sql **************************************************/
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN ReplyGreeting NVARCHAR(350);
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN ReplyFarewell NVARCHAR(350);
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN ReplySystemFailure NVARCHAR(350);
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN ReplyNoUnderstanding NVARCHAR(350);

ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN rules VARCHAR(1200);
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN instructions VARCHAR(8000);
/******************************** rollback file 10 ccsp_VirtualAgents.sql **************************************************/
GO
ALTER PROCEDURE [dbo].[ccsp_VirtualAgents]
        @action INT = 0,

        @idVirtualAgent INT = 0,
        --Creation
        @nameAgent NVARCHAR(255) = NULL,
        @responseTone TINYINT = 0,
        @languageAgent TINYINT = 0,
        @quantumRoleId INT = 0,
        @roleDescription NVARCHAR(30) = '',
        @responseLength TINYINT = 0,
        @numberOfAgents INT = 0,
        @quantumAgentId NVARCHAR(50) = '',
        @replyGreeting NVARCHAR(350) = '',
        @replyFarewell NVARCHAR(350) = '',
        @replySystemFailure NVARCHAR(350) = '',
        @replyNoUnderstanding NVARCHAR(350) = '',
        @statusAgent BIT = NULL,
        @campaignId INT = NULL,
        @mediaType INT = NULL, -- CALLS, WHATSAPP, SMS
        @campType INT = NULL, -- 0 IN - 1 OUT
        @voiceID INT= 0,
        @adminId INT = 0,
        @originalAgentId INT = 0,

        --Definition
        @objective VARCHAR(1200) = NULL,
        @rules VARCHAR(1200) = NULL,
        @instructions VARCHAR(8000) = NULL,
        @variables VARCHAR(500) = NULL,

        -- Masivo
        @virtualAgentIds VARCHAR(600) = NULL
        AS
        BEGIN
            DECLARE @idArea SMALLINT, @userName varchar(40)

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
                        END, 'N/A'
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
                            ELSE 'N/A'
                        END, 'N/A'
                    ) AS NumeroAsociado,
                    CONVERT(VARCHAR(10), va.createDateAgent, 120) AS FechaCreacion, -- Devuelve como 'YYYY-MM-DD'
                    ISNULL(
                        CASE 
                            WHEN va.latestUpdateDateAgent IS NULL OR va.latestUpdateDateAgent = '' THEN 'N/A'
                            ELSE CONVERT(VARCHAR(10), va.latestUpdateDateAgent, 120) -- Devuelve como 'YYYY-MM-DD'
                        END, 'N/A'
                    ) AS FechaUltimaModificacion, -- Devuelve 'YYYY-MM-DD' o 'N/A'
                    ISNULL(va.voice,1) as Voice,
                    va.scriptAgent as ScriptAgent,
                    CAST(CASE
                        WHEN va.instructions IS NULL OR va.instructions = '' THEN 0
                        ELSE 1
                        END AS bit) AS HasInstructions, 
                    ISNULL(va.ReplyGreeting, '') AS ReplyGreeting,
                    ISNULL(va.ReplyFarewell, '') AS ReplyFarewell,
                    ISNULL(va.ReplySystemFailure, '') AS ReplySystemFailure,
                    ISNULL(va.ReplyNoUnderstanding, '') AS ReplyNoUnderstanding,
                    ISNULL(va.quantumRoleId, 0) AS QuantumRolId,
                    ISNULL(va.responseLength, 0) AS ResponseLength,
                    ISNULL(va.responseTone, 0) AS ResponseTone,
                    ISNULL(va.roleName, '') AS RolName,
                    ISNULL(va.Language, 0) as Language,
                    ISNULL(CopiesCount, 0) As CopiesCount,
                    ISNULL(OriginalAgentId, 0) As OriginalAgentId
                FROM dbo.ccVirtualAgent va
                LEFT JOIN dbo.ccInbound ci ON ci.Inbound_id = va.idCampaign AND va.campType = 0
                LEFT JOIN dbo.ccCamps co ON co.cam_id = va.idCampaign AND va.campType = 1
                LEFT JOIN dbo.ccMetaWhatsAppNumbers wn ON wn.Inbound_Id = va.idCampaign AND va.campType = 0 AND mediaType != 0
                LEFT JOIN dbo.ccMetaWhatsAppNumbers wno ON wno.Cam_Id = va.idCampaign AND va.campType = 1 AND mediaType != 0
                LEFT JOIN dbo.ccRIAInboundGraph ig ON ig.Inbound_id = va.idCampaign AND va.campType = 0
                LEFT JOIN dbo.ccRIACampsGraph og ON og.cam_id = va.idCampaign AND va.campType = 1
                WHERE va.wasDeleted = 0
            END

            ELSE IF @action = 2
            BEGIN
                -- We validate the capacity defined in the setting 281 with the received value. 
                DECLARE @TotalOfConcurrentAgents INT, 
                        @UsedConcurrentAgents INT

                IF EXISTS(SELECT 1 FROM ccVirtualAgent WHERE nameAgent = @nameAgent and wasDeleted = 0)
                BEGIN
                    SELECT 'A virtual agent with the same name already exists' as Result, 1 as ErrorCode
                    RETURN
                END

                SELECT @TotalOfConcurrentAgents = CAST(valor AS int) FROM ccSettings2 WHERE setting_id = 281
                SELECT @UsedConcurrentAgents = ISNULL(SUM(concurrentSessionsLimit), 0) FROM ccVirtualAgent WHERE wasDeleted = 0

                IF((@UsedConcurrentAgents + @numberOfAgents) <= @TotalOfConcurrentAgents)
                BEGIN
                    -- Creación de un nuevo agente virtual
                    DECLARE @newModelId int;

                    INSERT INTO dbo.ccVirtualAgent (
                        nameAgent, 
                        statusAgent, 
                        createDateAgent, 
                        latestUpdateDateAgent,
                        concurrentSessionsLimit,
                        responseTone,
                        language,
                        quantumAgentId,
                        quantumRoleId,
                        roleName,
                        responseLength,
                        ReplyGreeting,
                        ReplyFarewell,
                        ReplySystemFailure,
                        ReplyNoUnderstanding,
                        voice
                    )
                    VALUES (
                        @nameAgent, 
                        0, 
                        GETDATE(),
                        GETDATE(),
                        @numberOfAgents,
                        @responseTone,
                        @languageAgent,
                        @quantumAgentId,
                        @quantumRoleId,
                        @roleDescription,
                        @responseLength,
                        @replyGreeting,
                        @replyFarewell,
                        @replySystemFailure,
                        @replyNoUnderstanding,
                        @voiceID
                    );

                    SET @newModelId = SCOPE_IDENTITY();

                    -- Activity History 
                
                    SELECT @idArea = IDArea, @userName = Login FROM ccUsers where User_id = @adminId

                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                        SELECT
                            (SELECT ISNULL(AreaName, '') FROM ccRIACat_Areas WHERE IDArea = @idArea),
                            getDate(), 
                            @userName, 
                            169,
                            24,
                            '',
                            '',
                            @nameAgent

                    IF @campaignId = 0
                    BEGIN
                        SELECT 'Agent created correctly' AS Result, 0 AS ErrorCode, @newModelId as IdAgent;
                        RETURN
                    END

                    -- Invoke campaign association and return association results
        
                    CREATE TABLE #associationResult (Result varchar(100), ErrorCode int, idAgent int, nameAgent varchar(255), idCampaign int, campaignName varchar(40))

                    INSERT INTO #associationResult(Result, ErrorCode,idAgent,nameAgent,idCampaign,campaignName)
                    EXEC dbo.ccsp_VirtualAgents
                            @action=4,@adminId=@adminId, @campType=@campType, @campaignId=@campaignId, @mediaType=@mediaType, @idVirtualAgent=@newModelId;

                    SELECT Result, ErrorCode, idAgent as IdAgent FROM #associationResult
                    RETURN
                END
                ELSE
                BEGIN
                    SELECT 'There are not contracted agents available' AS Result, 2 AS ErrorCode; 
                END
            END

            ELSE IF @action = 3 -- Elimination of virtual Agent
            BEGIN
                CREATE TABLE #deletedVirtualAgents(idAgent int, agentName varchar(255), quantumAgentId VARCHAR(50))

                UPDATE dbo.ccVirtualAgent
                SET
                    idCampaign = 0,
                    mediaType = 0,
                    concurrentSessionsLimit = 0,
                    campType = 0,
                    wasDeleted = 1
                OUTPUT deleted.idAgent, deleted.nameAgent, deleted.quantumAgentId INTO #deletedVirtualAgents
                WHERE idAgent IN(SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,',')) AND statusAgent = 0;

                SELECT * FROM #deletedVirtualAgents
            END

            ELSE IF @action = 4 -- Change of associated campaign. Brings the info for Activity history
            BEGIN
				BEGIN TRY
					DECLARE @PreviousAgentData AS TABLE(
						idAgent INT,
						nameAgent VARCHAR(255),
						idCampaign SMALLINT,
						camptype TINYINT
					);

					IF(@campaignId <> 0)
					BEGIN
						-- *** VALIDATIONS FOR CAMPAIGN ASSIGNATION ***
						-- Campaign was deleted
						DECLARE @campaignArea AS SMALLINT

						IF @campType = 0
						BEGIN
							SELECT @campaignArea =
								CASE
									WHEN EXISTS (SELECT 1 FROM ccInbound_Consulta WHERE Inbound_id = @campaignId)
										THEN 1
									ELSE 0
								END;
						END
						ELSE IF @campType = 1
						BEGIN
							SELECT @campaignArea =
								CASE
									WHEN EXISTS (SELECT 1 FROM ccCamps_Consulta WHERE cam_id = @campaignId)
										THEN 1
									ELSE 0
								END;
						END

						IF @campaignArea <> 0
						BEGIN
							SELECT 'Campaign was deleted' AS Result, 3 AS ErrorCode , 0 AS idAgent, '' as nameAgent, 0 AS idCampaign, '' AS nameCampaign
							RETURN
						END

							--- Campaign was assigned to another model
						IF EXISTS (SELECT 1 FROM ccVirtualAgent WHERE idAgent != @idVirtualAgent AND idCampaign = @campaignId AND mediaType = @mediaType AND campType = @campType)
						BEGIN
							SELECT 'Campaign has already been assigned' as Result, 4 AS ErrorCode , 0 AS idAgent, '' as nameAgent, 0 AS idCampaign, '' AS nameCampaign;
							RETURN
						END

						--- Campaign doesn't belong to the same wg than te user
						DECLARE @CampaignIsNotInUserWorkgroup  BIT = 0;

						IF NOT EXISTS (SELECT * FROM ccUsers_Roles NOLOCK WHERE User_id = @AdminId AND Rol_id = 7) -- It's not a superUser
						BEGIN
							SELECT @CampaignIsNotInUserWorkgroup =
								CASE WHEN NOT EXISTS (
									SELECT 1
									FROM dbo.ccRIAWorkGroupUsers AS userWG
										JOIN dbo.ccRIACampEspWG AS campaignWg ON campaignWg.IDWG = userWG.IDWG
									WHERE userWG.User_id    = @adminId
										AND campaignWg.Tipo       = @campType 
										AND campaignWg.IdCampEsp  = @campaignId
									)
									THEN 1 ELSE 0 END;

							IF @CampaignIsNotInUserWorkgroup = 1
							BEGIN
								SELECT 'Campaign doesn''t belong to admin workgroups' as Result, 5 AS ErrorCode , 0 AS idAgent, '' as nameAgent, 0 AS idCampaign, '' AS nameCampaign;
								RETURN
							END
						END
					END

					UPDATE ccVirtualAgent SET idCampaign = @campaignId,
												mediaType = @mediaType,
												camptype = @campType,
												latestUpdateDateAgent = GETDATE()
												OUTPUT deleted.idAgent, deleted.nameAgent, deleted.idCampaign, deleted.campType INTO @PreviousAgentData
												WHERE idAgent = @idVirtualAgent
					IF @campaignId <> 0
						BEGIN
							SELECT
								'Campaign changed' AS Result,
								0 AS ErrorCode,
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
								'Campaign retired' AS Result,
								0 AS ErrorCode,
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
				END TRY
				BEGIN CATCH
					SELECT 'Generic error to assign or unassign campaign to agent' as Result, 7 AS ErrorCode , 0 AS idAgent, '' as nameAgent, 0 AS idCampaign, '' AS nameCampaign;
					RETURN
				END CATCH
            END

            ELSE IF @action = 5 -- Status change
            BEGIN
                CREATE TABLE #updatedVirtualAgents(idAgent int, nameAgent varchar(255), newStatus BIT)

                UPDATE ccVirtualAgent SET statusAgent = @statusAgent
                OUTPUT inserted.idAgent, inserted.nameAgent, inserted.statusAgent as newStatus INTO #updatedVirtualAgents
                WHERE idAgent IN (SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,',')) and statusAgent != @statusAgent

                SELECT * FROM #updatedVirtualAgents
            END

            ELSE IF @action = 6 --Check if there's enabled related agent to camp 
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
                DECLARE @defaultVoiceId VARCHAR(MAX)
                SELECT @defaultVoiceId = QuantumVoiceId FROM ccVirtualAgentVoices WHERE IsDefault = 1

                SELECT 
                cva.idAgent
                , ISNULL(cva.quantumAgentId,'') AS QuantumAgentId
                , ISNULL(cva.location,'') AS Location
                , ISNULL('','')  AS ProjectId
                , CASE 
                    WHEN cva.voice IS NULL OR cva.voice = '' THEN @defaultVoiceId
                    ELSE ISNULL(cvav.QuantumVoiceId, @defaultVoiceId)
                    END AS Voice
                FROM dbo.ccVirtualAgent AS cva
                LEFT JOIN ccVirtualAgentVoices cvav ON cvav.ID = cva.voice
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
                select ID,Name,Gender, FileName, Language from ccVirtualAgentVoices
            END
            ELSE IF(@action = 12) -- get voice info by its Id
            BEGIN
                select QuantumVoiceId from ccVirtualAgentVoices where ID = @voiceID
            END
            ELSE IF (@action = 13) --Register model definition (Objectives, instructions, rules and variables)
            BEGIN
                DECLARE @modifiedModelName VARCHAR(255), @objectiveModified TINYINT = 0, @rulesModified TINYINT = 0, @instructionsModified TINYINT = 0;

                IF NOT EXISTS(SELECT 1 FROM ccVirtualAgent WHERE idAgent = @idVirtualAgent and wasDeleted = 0)
                BEGIN
                    SELECT 2 AS ErrorCode -- Agent deleted before saving changes
                    RETURN
                END

				SELECT 
				@objectiveModified = CASE WHEN ISNULL(cva.objective, '') = @objective THEN 0 ELSE 1 END,
				@rulesModified = CASE WHEN ISNULL(cva.rules,'') = @rules THEN 0 ELSE 1 END,
				@instructionsModified = CASE WHEN ISNULL(cva.instructions,'') = @instructions THEN 0 ELSE 1 END,
				@modifiedModelName = nameAgent
				FROM dbo.ccVirtualAgent AS cva WHERE cva.idAgent = @idVirtualAgent

                UPDATE ccVirtualAgent
                SET
                    objective   = @objective,
                    rules       = @rules,
                    instructions = @instructions,
                    scriptAgent = @variables,
                    latestUpdateDateAgent = GETDATE(),
                    statusAgent = CASE WHEN idCampaign <> 0 THEN 1 ELSE 0 END
                WHERE idAgent = @idVirtualAgent;

                IF @@ROWCOUNT = 1
                BEGIN
                    SELECT @idArea = IDArea, @userName = Login FROM ccUsers where User_id = @adminId

                    -- ACTIVITY HISTORY REGISTER
                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                        SELECT
                            (SELECT ISNULL(AreaName, '') FROM ccRIACat_Areas WHERE IDArea = @idArea),
                            getDate(), 
                            @userName, 
                            170,
                            24,
                            CASE 
							WHEN @objectiveModified = 1 AND @rulesModified = 1 AND @instructionsModified = 1 
								THEN 'VA_STRUCTURE_CONFIGURATION' 
							WHEN @objectiveModified = 1 AND @rulesModified = 1 
								THEN 'VA_STRUCTURE_CONFIGURATION_OBJECTIVE_RULE'
							WHEN @objectiveModified = 1 AND @instructionsModified = 1 
								THEN 'VA_STRUCTURE_CONFIGURATION_OBJECTIVE_SCRIPT'
							WHEN @rulesModified = 1 AND @instructionsModified = 1 
								THEN 'VA_STRUCTURE_CONFIGURATION_RULE_SCRIPT'
							WHEN @objectiveModified = 1 
								THEN 'VA_STRUCTURE_CONFIGURATION_OBJECTIVE'
							WHEN @rulesModified = 1 
								THEN 'VA_STRUCTURE_CONFIGURATION_RULE'
							WHEN @instructionsModified = 1 
								THEN 'VA_STRUCTURE_CONFIGURATION_SCRIPT'
							ELSE
							 ''
							END,
                            '',
                            @modifiedModelName;
                
                    SELECT 0 AS ErrorCode -- Success
                END
                ELSE
                BEGIN
                    SELECT 1 AS ErrorCode -- Agent with no changes or not found
                END

            END
            ELSE IF (@action = 14)
            BEGIN
                SELECT
                    idAgent As IdAgent,
                    nameAgent As Nombre,
                    statusAgent As Status,
                    ISNULL(concurrentSessionsLimit,0) As concurrentSessionsLimit,
                    ISNULL(CAST(idCampaign AS INT),0) As idCampaign,
                    ISNULL(CAST(mediaType AS INT),0) As SubType,
                    ISNULL(CAST(campType AS INT),0) As campType,
                    ISNULL(location,'') As location,
                    ISNULL(quantumAgentId,'') As QuantumAgentId,
                    ISNULL(scriptAgent,'') As scriptAgent,
                    ISNULL(voice,'') As voice,
                    ISNULL(ReplyGreeting,'') As ReplyGreeting,
                    ISNULL(ReplyFarewell,'')As ReplyFarewell,
                    ISNULL(ReplySystemFailure,'') As ReplySystemFailure,
                    ISNULL(ReplyNoUnderstanding,'') As ReplyNoUnderstanding,
                    ISNULL(language,0) As language,
                    ISNULL(responseTone,0) As responseTone,
                    ISNULL(roleName,'') As RolName,
                    ISNULL(responseLength,0) As responseLength,
                    ISNULL(quantumRoleId,0) As quantumRolId,
                    ISNULL(objective,'') As objective,
                    ISNULL(rules,'') As rules,
                    ISNULL(instructions,'') As instructions
                FROM 
                    ccVirtualAgent
                WHERE 
                    idAgent = @idVirtualAgent
            END
            ELSE IF (@action = 15) -- UPDATE Agent Virtual 
            BEGIN

                -- No deletion validation
                IF NOT EXISTS(SELECT 1 FROM ccVirtualAgent WHERE idAgent = @idVirtualAgent and wasDeleted = 0)
                BEGIN
                    SELECT 'The agent was deleted before saving changes.' AS Result, 7 AS ErrorCode
                    RETURN
                END
                -- 

                -- *** NUEVA LÓGICA: Manejo automático de voz al cambiar idioma ***
                DECLARE @currentVoice INT,
                        @currentLanguage INT,
                        @currentGender NVARCHAR(10),
                        @homonymousVoiceID INT = NULL;
        
                SELECT @currentVoice = ISNULL(voice, 0), 
                    @currentLanguage = ISNULL(language, 0)
                FROM ccVirtualAgent 
                WHERE idAgent = @idVirtualAgent;
        
                IF @languageAgent IS NOT NULL 
                AND @languageAgent <> @currentLanguage
                BEGIN
                    SELECT @currentGender = Gender 
                    FROM ccVirtualAgentVoices 
                    WHERE ID = @currentVoice;
            
                    IF @currentGender IS NOT NULL
                    BEGIN
                        SELECT TOP 1 @homonymousVoiceID = ID
                        FROM ccVirtualAgentVoices 
                        WHERE Language = @languageAgent 
                        AND Gender = @currentGender
                        ORDER BY IsDefault DESC, ID; -- Priorizar voz por defecto del idioma
                
                        IF @homonymousVoiceID IS NOT NULL AND (@voiceID IS NULL OR @voiceID = 0 OR @voiceID = @currentVoice)
                        BEGIN
                            SET @voiceID = @homonymousVoiceID; -- Actualizar a voz homónima
                        END
                    END
                END
        
                IF (@voiceID IS NULL OR @voiceID = 0) AND @homonymousVoiceID IS NULL
                BEGIN
                    SET @voiceID = @currentVoice;
                END

                DECLARE @AreaName  NVARCHAR(200),
                        @Login NVARCHAR(200),
                        @NameCampaing NVARCHAR(200), @nameAgentBeforeUpdate VARCHAR(255);

                EXEC InsertLogAdminGalatea @action = 1,
                                            @tableName = 'ccVirtualAgent',
                                            @columnNameId = 'idAgent',
                                            @valueId = @idVirtualAgent,
                                            @userId = @adminId
                CREATE TABLE #ccVirtualAgentTable (
                    columnInfo varchar(255),
                    dataInfo varchar(255),
                    identifierInfo varchar(255)
                )

				SELECT @nameAgentBeforeUpdate = v.nameAgent
                FROM dbo.ccVirtualAgent AS v
                WHERE v.idAgent = @idVirtualAgent;

                UPDATE ccVirtualAgent
                SET
                    nameAgent = CASE 
                                    WHEN @nameAgent IS NOT NULL 
                                            AND LTRIM(RTRIM(@nameAgent)) <> '' 
                                            AND @nameAgent <> nameAgent 
                                    THEN @nameAgent 
                                    ELSE nameAgent 
                                END,

                    latestUpdateDateAgent = GETDATE(),

                    responseTone = CASE 
                                        WHEN @responseTone IS NOT NULL 
                                            AND @responseTone > 0 
                                            AND (@responseTone <> responseTone OR responseTone IS NULL)
                                        THEN @responseTone 
                                        ELSE responseTone 
                                    END,

                    language = CASE 
                                        WHEN @languageAgent IS NOT NULL 
                                            AND (@languageAgent <> language OR language IS NULL)
                                        THEN @languageAgent 
                                        ELSE language 
                                    END,

                    concurrentSessionsLimit = CASE 
                                                    WHEN @numberOfAgents IS NOT NULL 
                                                        AND @numberOfAgents > 0 
                                                        AND (@numberOfAgents <> concurrentSessionsLimit OR concurrentSessionsLimit IS NULL)
                                                    THEN @numberOfAgents 
                                                    ELSE concurrentSessionsLimit 
                                                END,

                    responseLength = CASE 
                                            WHEN @responseLength IS NOT NULL 
                                                AND @responseLength > 0 
                                                AND (@responseLength <> responseLength OR responseLength IS NULL)
                                            THEN @responseLength 
                                            ELSE responseLength 
                                        END,

                    ReplyGreeting = CASE 
                                        WHEN @replyGreeting IS NOT NULL 
                                                AND LTRIM(RTRIM(@replyGreeting)) <> '' 
                                                AND (@replyGreeting <> ReplyGreeting OR ReplyGreeting IS NULL)
                                        THEN @replyGreeting 
                                        ELSE ReplyGreeting 
                                    END,

                    ReplyFarewell = CASE 
                                        WHEN @replyFarewell IS NOT NULL 
                                                AND LTRIM(RTRIM(@replyFarewell)) <> '' 
                                                AND (@replyFarewell <> ReplyFarewell OR ReplyFarewell IS NULL)
                                        THEN @replyFarewell 
                                        ELSE ReplyFarewell 
                                    END,

                    ReplySystemFailure = CASE 
                                                WHEN @replySystemFailure IS NOT NULL 
                                                    AND LTRIM(RTRIM(@replySystemFailure)) <> '' 
                                                    AND (@replySystemFailure <> ReplySystemFailure OR ReplySystemFailure IS NULL)
                                                THEN @replySystemFailure 
                                                ELSE ReplySystemFailure 
                                            END,

                    ReplyNoUnderstanding = CASE 
                                                WHEN @replyNoUnderstanding IS NOT NULL 
                                                    AND LTRIM(RTRIM(@replyNoUnderstanding)) <> '' 
                                                    AND (@replyNoUnderstanding <> ReplyNoUnderstanding OR ReplyNoUnderstanding IS NULL)
                                                THEN @replyNoUnderstanding 
                                                ELSE ReplyNoUnderstanding 
                                            END,

                    voice = CASE 
                                WHEN @voiceID IS NOT NULL 
                                        AND @voiceID > 0 
                                        AND (@voiceID <> voice OR voice IS NULL)
                                THEN @voiceID 
                                ELSE voice 
                            END
                WHERE idAgent = @idVirtualAgent;

                IF @campaignId IS NOT NULL
                BEGIN
                    EXEC dbo.ccsp_VirtualAgents
                            @action=4,@adminId=@adminId, @campType=@campType, @campaignId=@campaignId, @mediaType=@mediaType, @idVirtualAgent=@idVirtualAgent;
                    IF @campaignId <> 0
                    BEGIN
                        IF @mediaType = 11
                        BEGIN
                            SELECT
                                @NameCampaing = [descripcion]
                            FROM ccInbound
                            WHERE inbound_id = @campaignId
                        END
                        ELSE
                            SELECT
                                @NameCampaing = cam_descripcion
                            FROM ccCamps
                            WHERE cam_id = @campaignId
                    END
                END

                EXEC InsertLogAdminGalatea @action = 2,
                                            @tableName = 'ccVirtualAgent',
                                            @columnNameId = 'idAgent',
                                            @valueId = @idVirtualAgent,
                                            @userId = @adminId,
                                            @tableTemp = '#ccVirtualAgentTable'

                SELECT  @Login = U.[Login],
                        @AreaName = A.[AreaName]
                FROM ccUsers AS U
                LEFT JOIN ccRIACat_Areas AS A
                    ON A.IDArea = U.IDArea
                WHERE U.User_id = @adminId;

                SELECT @NameAgent = v.nameAgent
                FROM dbo.ccVirtualAgent AS v
                WHERE v.idAgent = @idVirtualAgent;

                ;WITH src AS (
                    SELECT 
                        CCVA.*,
                        ROW_NUMBER() OVER (
                            PARTITION BY CCVA.identifierInfo 
                            ORDER BY CCVA.columnInfo 
                        ) AS rn
                    FROM #ccVirtualAgentTable AS CCVA
                )
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                SELECT
                    @AreaName,
                    GETDATE(),
                    @Login,
                    171,
                    24,
                    S.identifierInfo,
                    CASE
                        WHEN S.identifierInfo IS NOT NULL AND S.identifierInfo <> '' THEN 
                            CASE
                                WHEN S.identifierInfo = 'VA_LANGUAGE' THEN
                                    CASE S.dataInfo
                                        WHEN 1 THEN 'VA_ENGLISH_EN'
                                        WHEN 2 THEN 'VA_PORTUGUESE_PT'
                                        ELSE 'VA_SPANISH_ES'
                                    END
                                WHEN S.identifierInfo = 'VA_TONE_OF_VOICE' THEN
                                    CASE S.dataInfo
                                        WHEN 1 THEN 'VA_FORTHRIGHT_AND_CONCISE'
                                        WHEN 2 THEN 'VA_SYMPATHETIC_AND_WARM'
                                        WHEN 3 THEN 'VA_PERSUASIVE_AND_ACTION_ORIENTED'
                                        WHEN 4 THEN 'VA_NEUTRAL_AND_OBJECTIVE'
                                        WHEN 5 THEN 'VA_RELAXED_AND_FRIENDLY'
                                        ELSE 'VA_NONE_TV'
                                    END
                                WHEN S.identifierInfo = 'VA_RESPONSE_LENGTH' THEN
                                    CASE S.dataInfo
                                        WHEN 1 THEN 'VA_SHORT_RESPONSE'
                                        WHEN 2 THEN 'VA_MEDIUM_RESPONSE'
                                        WHEN 3 THEN 'VA_LONG_RESPONSE'
                                        ELSE 'VA_NONE'
                                    END
                                WHEN S.identifierInfo = 'VA_VIRTUAL_AGENT_CAMPAIGN' THEN
                                    CASE S.dataInfo
                                        WHEN 0 THEN 'VA_NONE' 
                                        ELSE @NameCampaing
                                    END
                                WHEN S.identifierInfo = 'VA_VOICE_TYPE' THEN
                                    CASE S.dataInfo
                                        WHEN 1 THEN 'VA_VOICE_FEMALE'
                                        WHEN 3 THEN 'VA_VOICE_FEMALE'
                                        WHEN 5 THEN 'VA_VOICE_FEMALE'
                                        WHEN 2 THEN 'VA_VOICE_MALE'
                                        WHEN 4 THEN 'VA_VOICE_MALE'
                                        WHEN 6 THEN 'VA_VOICE_MALE'
                                        ELSE 'VA_VOICE_MALE'
                                    END
                                WHEN S.identifierInfo = 'VA_SCRIPTED_RESPONSES' THEN
                                    'VA_RESPONSES' 
                                ELSE S.dataInfo
                            END
                        ELSE ''
                    END,
					CASE
					WHEN S.identifierInfo = 'VA_NAME' THEN @nameAgentBeforeUpdate 
					ELSE 
					@NameAgent END
                FROM src AS S
                WHERE NULLIF(LTRIM(RTRIM(S.identifierInfo)), '') IS NOT NULL
                    AND NOT (S.identifierInfo = 'VA_SCRIPTED_RESPONSES' AND S.rn > 1)

            
                EXEC InsertLogAdminGalatea @action = 3,
                                            @tableName = 'ccVirtualAgent',
                                            @columnNameId = 'idAgent',
                                            @valueId = @idVirtualAgent,
                                            @userId = @adminId

                IF OBJECT_ID(N'tempdb..#ccVirtualAgentTable') IS NOT NULL
                DROP TABLE #ccVirtualAgentTable

                SELECT 'Agent successfully updated' AS Result, 0 AS ErrorCode, @idVirtualAgent as IdAgent;
            END

            ELSE IF (@action = 16) -- Duplicate virtual agent
            BEGIN
                SET NOCOUNT ON;

                DECLARE @newAgentId INT;

                IF EXISTS(SELECT 1 FROM ccVirtualAgent WHERE nameAgent = @nameAgent and wasDeleted = 0)
                BEGIN
                    SELECT 'A virtual agent with the same name already exists' as Result, 1 as ErrorCode
                    RETURN
                END
        
                -- Validación de capacidad (variables con nombres únicos)
                DECLARE @TotalOfConcurrentAgents_16 INT,
                        @UsedConcurrentAgents_16   INT;

                SELECT @TotalOfConcurrentAgents_16 = CAST(valor AS INT)
                FROM ccSettings2
                WHERE setting_id = 281;

                SELECT @UsedConcurrentAgents_16 = ISNULL(SUM(concurrentSessionsLimit), 0)
                FROM ccVirtualAgent
                WHERE wasDeleted = 0;

                IF ((@UsedConcurrentAgents_16 + ISNULL(@numberOfAgents,0)) > ISNULL(@TotalOfConcurrentAgents_16,0))
                BEGIN
                    SELECT 'There are not contracted agents available' AS Result, 2 AS ErrorCode;
                    RETURN;
                END

                -- Crear el duplicado copiando del original y sobrescribiendo con valores del frontend
                INSERT INTO ccVirtualAgent (
                    nameAgent,
                    statusAgent,
                    createDateAgent,
                    latestUpdateDateAgent,
                    responseTone,
                    language,
                    quantumRoleId,
                    roleName,
                    responseLength,
                    quantumAgentId,
                    concurrentSessionsLimit,
                    voice,
                    ReplyGreeting,
                    ReplyFarewell,
                    ReplySystemFailure,
                    ReplyNoUnderstanding,
                    objective,
                    rules,
                    instructions,
                    scriptAgent,
                    OriginalAgentId,
                    CopiesCount,
                    wasDeleted,
                    idCampaign,
                    mediaType,
                    campType
                )
                SELECT
                    @nameAgent,                    
                    0,                             
                    GETDATE(),
                    GETDATE(),
                    @responseTone,                
                    @languageAgent,                
                    @quantumRoleId,                 
                    @roleDescription,                      
                    @responseLength,               
                    @quantumAgentId,               
                    @numberOfAgents,               
                    @voiceID,                         
                    @ReplyGreeting,                 
                    @ReplyFarewell,                
                    @ReplySystemFailure,            
                    @ReplyNoUnderstanding,         
                    objective,                     
                    rules,                         
                    instructions,                 
                    scriptAgent,                   
                    @originalAgentId,                       
                    0,                             -- Sin copias propias todavía
                    0,                             -- No eliminado
                    0,                             -- Sin campaña
                    0,                             -- Sin mediaType
                    0                              -- Sin campType
                FROM ccVirtualAgent
                WHERE idAgent = @originalAgentId;

                SET @newAgentId = SCOPE_IDENTITY();

                IF (@newAgentId IS NULL)
                BEGIN
                    SELECT 'Source agent not found' AS Result, 2 AS ErrorCode, NULL AS IdAgent, @originalAgentId AS OriginalAgentId;
                    RETURN;
                END

                -- Actualizar contador del padre
                UPDATE ccVirtualAgent 
                SET CopiesCount = ISNULL(CopiesCount, 0) + 1,
                    latestUpdateDateAgent = GETDATE()
                WHERE idAgent = @originalAgentId;

                -- Registrar actividad
                SELECT @idArea = IDArea, @userName = Login 
                FROM ccUsers 
                WHERE User_id = @adminId;

                INSERT INTO ccGalateaActivityLog (
                    Area, 
                    ActivityDate, 
                    Login, 
                    OperationId, 
                    ModuleId, 
                    Identifier, 
                    Value, 
                    Target
                )
                SELECT
                    (SELECT ISNULL(AreaName, '') FROM ccRIACat_Areas WHERE IDArea = @idArea),
                    GETDATE(), 
                    @userName, 
                    174,
                    24,
                    '',
                    '',
                    @nameAgent;

                -- Retornar resultado
                SELECT 'Agent duplicated successfully' AS Result,
                        0 AS ErrorCode,
                        @newAgentId AS IdAgent,
                        @originalAgentId AS OriginalAgentId;
            END
        END	    
	