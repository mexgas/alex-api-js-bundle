/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K053000

Database: CCenterRia
Required version: 125.31

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
SET @versionfix = 32
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

	---------------------------------------BEGIN Jesus Gallardo---------------------------------------------------------
	/****************************************************************************
	 * Creacion de SP 
	 * 		ccsp_UnassignedElementsInAreas  -> Se agrega nuevo SP para Componentes Sin Area	 
	 * ****************************************************************************/
	SET @process = '053000 Insert New Operations ID 72'
	SET @sql = 'IF NOT EXISTS (SELECT OperationId from ccGalateaOperations where OperationId = 72) 
				BEGIN
					INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
					VALUES(72, ''Añadir administrador a área'', ''Add administrator to area'', ''Adicionar administrador a área'')
				END'
	EXEC(@sql)

	SET @process = '053000 Insert New Operations ID 73'
	SET @sql = 'IF NOT EXISTS (SELECT OperationId from ccGalateaOperations where OperationId = 73) 
				BEGIN
					INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
					VALUES(73, ''Añadir agente a área'', ''Add agent to area'', ''Adicionar agente a área'')
				END'
	EXEC(@sql)

	SET @process = '053000 Insert New Operations ID 74'
	SET @sql = 'IF NOT EXISTS (SELECT OperationId from ccGalateaOperations where OperationId = 74) 
				BEGIN
					INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
					VALUES(74, ''Añadir campaña a área'', ''Add campaign to area'', ''Adicionar campaña a área'')
				END'
	EXEC(@sql)

	SET @process = '053000 Insert New Operations ID 75'
	SET @sql = 'IF NOT EXISTS (SELECT OperationId from ccGalateaOperations where OperationId = 75) 
				BEGIN
					INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
					VALUES(75, ''Remover administrador de área'', ''Remove administrator from area'', ''Remover administrador de área'')
				END'
	EXEC(@sql)

	SET @process = '053000 Insert New Operations ID 76'
	SET @sql = 'IF NOT EXISTS (SELECT OperationId from ccGalateaOperations where OperationId = 76) 
				BEGIN
					INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
					VALUES(76, ''Remover agente de área'', ''Remove agent from area'', ''Remover agente de área'')
				END'
	EXEC(@sql)

	SET @process = '053000 Insert New Operations ID 77'
	SET @sql = 'IF NOT EXISTS (SELECT OperationId from ccGalateaOperations where OperationId = 77) 
				BEGIN
					INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
					VALUES(77, ''Remover campaña de área'', ''Remove campaign from area'', ''Remover campaña de área'')
				END'
	EXEC(@sql)

	SET @process = 'DROP PROCEDURE ccsp_UnassignedElementsInAreas'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_UnassignedElementsInAreas'')
		BEGIN
			DROP PROCEDURE ccsp_UnassignedElementsInAreas
		END'
	EXEC(@sql)

	SET @process = '053000 Unassigned Elements in Areas'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_UnassignedElementsInAreas]   
					@Action INT,   
					@AreaId INT = 0,
					@Ids VARCHAR(MAX) = ''''
				AS    
				BEGIN
					DECLARE @IdsTemp TABLE (Id INT);
					DECLARE @Id VARCHAR(MAX);
					INSERT INTO @IdsTemp SELECT VALUE FROM dbo.fn_RIASplitDelimited(@Ids,'','')

					-- Return results 
					IF @Action IN (0, 3, 6)	-- User names 
					BEGIN 
						SELECT ISNULL(login,'''')  AS ElementNames
						FROM @IdsTemp ids
						INNER JOIN ccUsers users ON users.User_id = ids.Id
					END

					IF @Action IN (1, 4, 7)	-- Campaign names
					BEGIN 
						SELECT ISNULL(cam_descripcion,'''')  AS ElementNames
						FROM @IdsTemp ids
						INNER JOIN ccCamps campaign ON campaign.cam_id = ids.Id
					END

					IF @Action IN (2, 5, 8)	-- Acd names
					BEGIN 
						SELECT ISNULL(descripcion,'''') AS ElementNames
						FROM @IdsTemp ids
						INNER JOIN ccInbound acd ON acd.Inbound_id = ids.Id
					END
					-------------------------------------------------------
					IF @Action = 0 -- Assign Users to Unassigned area 
					BEGIN
						UPDATE ccUsers
						SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END,
							status = 1
						FROM @IdsTemp ids
						WHERE ccUsers.User_id = ids.Id
						AND NOT EXISTS (SELECT 1 FROM ccUsers WHERE IDArea = @AreaId AND User_id = ids.Id)
					END

					IF @Action = 1 -- Assign Users to Campaigns area 
					BEGIN
						UPDATE ccCamps
						SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END
						FROM @IdsTemp ids
						WHERE ccCamps.cam_id = ids.Id
						AND NOT EXISTS (SELECT 1 FROM ccCamps WHERE IDArea = @AreaId AND cam_id = ids.Id)
					END

					IF @Action = 2 -- Assign Users to Acds area 
					BEGIN		
						UPDATE ccInbound
						SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END,
							status = 1
						FROM @IdsTemp ids
						WHERE ccInbound.Inbound_id = ids.Id
						AND NOT EXISTS (SELECT 1 FROM ccInbound WHERE IDArea = @AreaId AND Inbound_Id = ids.Id)
					END

					IF @Action in (3, 4, 5, 6, 7, 8)
					BEGIN 
						SET @Id = ''0''
						WHILE EXISTS( SELECT Id FROM @IdsTemp ) 
						BEGIN
							SELECT TOP 1 @Id =Id FROM @IdsTemp 

							IF @Action = 3 -- Unassign Users from area 
							BEGIN
								EXEC ccsp_RIAManageAreas @option = 2, @DeleteUserId = @Id
							END

							IF @Action = 4 -- Unassign Campaigns from area 
							BEGIN
								EXEC ccsp_RIAManageAreas @option=4, @DeleteCamId = @Id
							END 

							IF @Action = 5 -- Unassign Acds from area 
							BEGIN
								EXEC ccsp_RIAManageAreas @option = 6, @DeleteACDGroupId = @Id
							END

							IF @Action = 6 -- Delete Users from area 
							BEGIN
								EXEC ccsp_RIA_ABCAgents @option=4, @UserId = @Id, @Login = '''', @Nombres='''',@ApellidoPaterno='''',@ApellidoMaterno='''',@Password='''',@Sexo=0,@canChangeStatus=0,@AreaId=0,@UserType=0,@IDWG=0
							END

							IF @Action = 7 -- Delete Campaigns from area 
							BEGIN
								EXEC ccsp_RIA_ABCCamps @option = 4, @UserId = 0, @Descripcion = '''', @Cam_id = @Id, @Activa = 0, @IDArea = 0, @frame = 0
							END

							IF @Action = 8 -- Delete Acds from area 
							BEGIN
								EXEC ccsp_RIA_ABCACDGroups @option = 4, @UserId = 0, @Descripcion = '''', @Inbound_id = @Id, @IDArea = 0, @frame = 0
							END

							DELETE FROM @IdsTemp WHERE Id = @Id
						END
					END
				END'
	EXEC(@sql)

	SET @process = '053000 Alter spGalateaRIALog'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaRIALog]
				@userId           SMALLINT,
				@OperationType    VARCHAR(MAX)= '''',
				@Value			  VARCHAR(MAX) = '''',
				@Module			  SMALLINT,
				@target			  VARCHAR(40) = ''''
				AS
				BEGIN
					SET NOCOUNT ON;

					IF OBJECT_ID(''tempdb..#OperationType'') IS NOT NULL DROP TABLE #OperationType
					create table #OperationType(
							id smallint IDENTITY(1,1),
							operationType varchar(MAX)
					)
					insert into #OperationType SELECT value FROM fn_RIASplitDelimited(@OperationType, '','')	

					IF OBJECT_ID(''tempdb..#Value'') IS NOT NULL DROP TABLE #Value
					create table #Value(
							id smallint IDENTITY(1,1),
							value varchar(MAX)
					)
					insert into #Value SELECT value FROM fn_RIASplitDelimited(@Value, ''^^'')
					
					IF OBJECT_ID(''tempdb..#Params'') IS NOT NULL DROP TABLE #Params
					select operationType,value 
					into #Params
					from #OperationType o
					LEFT JOIN #Value v with(nolock) on o.id = v.id


					IF OBJECT_ID(''tempdb..#PreLog'') IS NOT NULL DROP TABLE #PreLog
					create table #PreLog(
							areaName varchar(40),
							operatioDate DATETIME,
							login varchar(40),
							module_id smallint,
							target varchar(40)
					)
					insert into #PreLog
					select AreaName, GETDATE() as operatioDate,u.login,@Module module_id,@target as target
					from ccUsers U
					INNER JOIN ccRIACat_Areas A with(nolock) on u.IDArea = a.IDArea
					where U.User_id = @userId

					Insert into ccRIALog
					select areaName,operatioDate,operationType,login,module_id,value,target
					from #PreLog,#Params

					IF OBJECT_ID(''tempdb..#OperationType'') IS NOT NULL DROP TABLE #OperationType
					IF OBJECT_ID(''tempdb..#Value'') IS NOT NULL DROP TABLE #Value
					IF OBJECT_ID(''tempdb..#Params'') IS NOT NULL DROP TABLE #Params
					IF OBJECT_ID(''tempdb..#PreLog'') IS NOT NULL DROP TABLE #PreLog
					Select 1
					return
				END'
	EXEC(@sql)

	---------------------------------------END Jesus Gallardo-----------------------------------------------------------

	---------------------------------------BEGIN Uriel Cabrera---------------------------------------------------------
	/****************************************************************************
	 * Modificacion de SP 
	 * 		ccsp_RIALoadCamps  -> Se agrega el campType a los datos que se reciben en el admin machine en la opcion 2
	 * ****************************************************************************/

	SET @process = '053001 Alter ccsp_RIALoadCamps'
	SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_RIALoadCamps] @option SMALLINT, @AreaId SMALLINT = NULL, @Sup SMALLINT = NULL, @WGID SMALLINT = NULL
				AS
				SET NOCOUNT ON

				DECLARE @loginDays INT

				SET @loginDays = 0

				IF @option = 1 -- Todas las campa?as
				BEGIN
					SELECT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0), isnull(DNCscrub, 0)
					FROM ccCamps a1
					JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					WHERE a3.type_id = 1 AND a1.cam_id IN (
							SELECT cam_id
							FROM dbo.fGet_CampAcd_Area(@Sup, 1)
							)
					ORDER BY 5, 2

					RETURN (0)
				END

				IF @option = 2 -- Campa?as de un Area
				BEGIN
					SELECT DISTINCT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG, a1.CampType mode
					FROM ccCamps a1
					JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
					ORDER BY cam_descripcion

					RETURN (0)
				END

				IF @option = 3 -- Campa?as por Supervisor
				BEGIN
					SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(a1.IDArea, 0) IDArea
					FROM ccCamps a1
					JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccSupervisorCam a4 ON a1.cam_id = a4.cam_id
					WHERE a3.type_id = 1 AND a4.tipo = 1 AND a4.user_id = @Sup
					ORDER BY 5, 2

					RETURN (0)
				END

				IF @option = 4 -- Rels Camps-Agents
				BEGIN
					SELECT @loginDays = valor
					FROM ccSettings
					WHERE setting_id = 211 --Numero dias que cargara las relaciones

					SELECT LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea, min(rel_id) rel_id
					FROM (
						SELECT A.LOGIN, A.User_id, Prioridad, Skill, C.cam_id, C.cam_descripcion, isnull(C.IDArea, 0) IDArea, CA.rel_id
						FROM ccCamps C
						JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id
						JOIN ccRIACampsGraph a2 ON C.cam_id = a2.cam_id
						JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
						JOIN ccUsers A ON A.User_id = CA.User_id AND A.TipoUser_id = 1 AND A.STATUS = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)
						WHERE C.cam_id IN (
								SELECT cam_id
								FROM ccsupervisorcam
								WHERE user_id = CASE isnull(@Sup, 0) WHEN 0 THEN user_id ELSE @Sup END AND tipo = 1
								)
						) Relations
					GROUP BY LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea
					ORDER BY User_id, cam_descripcion, cam_id, Prioridad

					RETURN (0)
				END

				IF @option = 5 -- Campa?as por Supervisor
				BEGIN
					SELECT @AreaId = IDArea
					FROM ccUsers
					WHERE User_id = @sup

					SELECT DISTINCT Camps.cam_id, Camps.cam_descripcion, a3.frame, Camps.cam_procesando, isnull(Camps.IDArea, 0) IDArea, IsNull(CN.New, 0) AS New, IsNull(CN.CB, 0) AS CB, IsNull(CN.Pro, 0) AS Pro, IsNull(CN.pen, 0) AS Pen, cast(Camps.cam_procesando AS INT) AS St, Camps.cam_TipoJobs AS Job, isnull(CN.Fin, 0) Fin, isnull(CP.prioridad, ''12345NNN'') prioridad, cast(camps.dialorder AS TINYINT) dialorder, cast(camps.progDial AS TINYINT) progDial, U.monitored, Camps.aggressionFactor
					FROM ccCamps Camps
					LEFT JOIN ccCampsPrioridadTel CP ON CP.cam_id = Camps.cam_id
					LEFT JOIN ccCampsNvosCB CN ON CN.id = Camps.cam_id
					JOIN ccRIACampsGraph a2 ON (Camps.cam_id = a2.cam_id)
					JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
					JOIN ccSupervisorCam U ON Camps.cam_id = U.cam_id
					WHERE U.user_id = @sup AND tipo = 1 AND a3.type_id = 1 AND Camps.cam_id IN (
							SELECT cam_id
							FROM ccSupervisorCam
							WHERE tipo = 1 AND user_id = @sup
							) AND Camps.IDArea = @AreaId
					ORDER BY 5, cam_procesando DESC, cam_descripcion

					RETURN (0)
				END

				IF @option = 7 -- Una sola
				BEGIN
					SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(IDArea, 0) IDArea, isnull(DNCscrub, 0) DNCScrub
					FROM ccCamps a1
					JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					WHERE a3.type_id = 1 AND isnull(a1.cam_id, 0) = isnull(@AreaId, 0)
					ORDER BY 5, 2

					RETURN (0)
				END

				IF @option = 8 -- Campa?as de un Agente
				BEGIN
					SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame
					FROM ccCamps a1
					JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccCampsAgente a4 ON a1.cam_id = a4.cam_id
					WHERE a3.type_id = 1 AND a4.user_id = @Sup
					ORDER BY 2

					RETURN (0)
				END
				IF @option = 9 -- Campa?as de un Area
				BEGIN
					(SELECT DISTINCT a1.cam_id as CamID, cam_descripcion as CamDescription, frame as Frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) as RelationsWG,1 CamType, 
					ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 1 and IdCampEsp = a1.cam_id and IDWG = @WGID group by IdCampEsp),0) IsAssignedToCurrentWG,
					CAST(CASE WHEN a1.progDial = 3 THEN 6 WHEN a1.CampType = 5 THEN 5 WHEN a1.CampType=7 THEN 7 ELSE 0 END as [tinyint]) [MediaType]
					FROM ccCamps a1
					JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
					UNION
					SELECT DISTINCT b1.inbound_id, descripcion, frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(b1.inbound_id, 2) relationsWG, 0 CampType, 
					ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 0 and IdCampEsp = b1.inbound_id and IDWG = @WGID group by IdCampEsp),0) isAssignedToCurrentWG,
					b1.chat [MediaType]
					FROM ccinbound b1
					JOIN ccRIAinboundGraph b2 ON b1.inbound_id = b2.inbound_id
					INNER JOIN ccRIAGraphics b3 ON b2.graphic_id = b3.graphic_id
					LEFT JOIN (
						SELECT inbound_id, CASE WHEN (sum(skill) / count(user_id)) = max(skill) THEN 0 ELSE 1 END skillDif
						FROM ccSkills
						GROUP BY inbound_id
						) S ON S.Inbound_id = b1.inbound_id
					WHERE b3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
					) ORDER BY camtype desc,cam_descripcion

					RETURN (0)
				END

				RETURN (0)

				SET NOCOUNT OFF
	'
	EXEC(@sql)

	---------------------------------------END Uriel Cabrera---------------------------------------------------------
	
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