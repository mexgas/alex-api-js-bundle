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
	SET @process = '053000 Insert New Operations'
	SET @sql = 'IF NOT EXISTS (SELECT OperationId from c where OperationId in (63, 64, 65, 66, 67, 68)) 
				BEGIN
					INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
					VALUES(63, ''Añadir administrador a área'', ''Add administrator to area'', ''Adicionar administrador à área'')
					INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
					VALUES(64, ''Añadir agente a área'', ''Add agent to area'', ''Adicionar agente à área'')
					INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
					VALUES(65, ''Añadir campaña a área'', ''Add campaign to area'', ''Adicionar campanha à área'')

					INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
					VALUES(66, ''Remover administrador de área'', ''Remove administrator from area'', ''Remover administrador da área'')
					INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
					VALUES(67, ''Remover agente de área'', ''Remove agent from area'', ''Remover agente da área'')
					INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
					VALUES(68, ''Remover campaña de área'', ''Remove campaign from area'', ''Remover campanha da área'')
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