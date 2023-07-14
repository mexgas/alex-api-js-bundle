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

	SET @process = '053000 Alter ccsp_GalateaActivityLog'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaActivityLog]
@UserId           SMALLINT,
@Operations       VARCHAR(MAX)= '''',
@Identifiers	  VARCHAR(MAX) = '''',
@Values			  VARCHAR(MAX) = '''',
@Module			  SMALLINT,
@Target			  VARCHAR(40) = ''''
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID(''tempdb..#OperationType'') IS NOT NULL DROP TABLE #OperationType
	create table #OperationType(
			id smallint IDENTITY(1,1),
			operationId int
	)
	insert into #OperationType SELECT value FROM fn_RIASplitDelimited(@Operations, '','')	

	IF OBJECT_ID(''tempdb..#Identifiers'') IS NOT NULL DROP TABLE #Identifiers
	create table #Identifiers(
			id smallint IDENTITY(1,1),
			identifier varchar(MAX)
	)
	insert into #Identifiers SELECT value FROM fn_RIASplitDelimited(@Identifiers, ''^^'')

	IF OBJECT_ID(''tempdb..#Value'') IS NOT NULL DROP TABLE #Value
	create table #Value(
			id smallint IDENTITY(1,1),
			value varchar(MAX)
	)
	insert into #Value SELECT value FROM fn_RIASplitDelimited(@Values, ''^^'')
	
	IF OBJECT_ID(''tempdb..#Params'') IS NOT NULL DROP TABLE #Params
	select operationId,isnull(identifier,'''') identifier,isnull(value,'''') value
	into #Params
	from #OperationType o
	left join #Value v with(nolock) on o.id = v.id
	left join #Identifiers i with(nolock) on i.id = o.id


	IF OBJECT_ID(''tempdb..#PreLog'') IS NOT NULL DROP TABLE #PreLog
	create table #PreLog(
			areaName varchar(40),
			operationDate DATETIME,
			login varchar(40),
			module_id smallint,
			target varchar(40)
	)
	insert into #PreLog
	select AreaName, GETDATE() as operationDate,u.login,@Module module_id,@target as target
	from ccUsers U
	INNER JOIN ccRIACat_Areas A with(nolock) on u.IDArea = a.IDArea
	where U.User_id = @userId

	Insert into ccGalateaActivityLog (Area,ActivityDate,OperationId,Login,ModuleId,Identifier,Value,Target)
	select areaName,operationDate,operationId,login,module_id,identifier,value,target
	from #PreLog,#Params

	IF OBJECT_ID(''tempdb..#OperationType'') IS NOT NULL DROP TABLE #OperationType
	IF OBJECT_ID(''tempdb..#Identifiers'') IS NOT NULL DROP TABLE #Identifiers
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
	SELECT DISTINCT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG, ISNULL(a1.CampType, 0) mode
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

	SET @process = '053000 Alter SP ccsp_RIA_ABCAgents @option 4 delete from ccRIAAgentsPermissions  where AgentId = @UserId'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
    @option smallint,
    @UserId int,
    @Login varchar(40)='''',
    @Nombres varchar(25)=null,
    @ApellidoPaterno varchar(25)='''',
    @ApellidoMaterno varchar(25)='''',
    @Password varchar(33)='''',
    @Sexo bit=null,
    @canChangeStatus bit=null,
    @AreaId int=null,
    @UserType tinyint=1,
    @IDWG int=0,
    @DeleteUsers int=1,
    @inOut int=null,
    @IDCampEsp int=null,
    @multipleUsers varchar(1000)=null
    as
    set nocount on

    if @option=0--All Users
      begin
      select User_id,Login,ISnull(AREas.AreaName,'''')as AreaName

    from ccusers as users with(nolock)
        left join ccRIACat_Areas as areas with(nolock)
        on users.IDArea=areas.IDArea
      return(0)
      end

    if @option=1--selected User
      begin
      select User_id,Login,Nombres,isnull(apellidoPaterno,''''),
        isnull(ApellidoMaterno,''''),Sexo,canChangeStatus,isnull(IDArea,0),tipouser_id
      from ccusers where User_id=@UserId
      order by IDArea,Nombres,ApellidoPaterno,User_id
      return(0)
      end

    if @option=2--insert
      begin
      if exists(select Login from ccUsers where Login=@Login)
        begin
        select -1--,''Login en Uso''
        return(0)
        end

      if exists(select Login from ccUsers_Consulta where Login = @Login)
      begin
        select -4 -- ''Login habia estado en Uso''
        return(0)
      end

      if exists(select Nombres from ccUsers where Nombres=@Nombres
      and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
        begin
        select -2--,''Nombre en Uso''
        return(0)
        end

    IF( select isnull(max(user_id),0) from ccusers) > 32700
    BEGIN
      set @UserId = null
      SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
      FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
      LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
      INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
      FROM ccusers) AS w ON w.recID = d.recID

      if @UserId is null
      begin
        select -2--insert Error
        return(0)
      end

      set identity_insert ccusers on
      insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
        Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
      select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
        1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
      set identity_insert ccusers off

      delete ccMenuUser where id_User = @UserId
      delete ccRIAUserRole where user_id = @UserId

      exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

    END
    ELSE
    BEGIN
      insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
        Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
      select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
        1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

      if @@rowcount=1
        select @UserId=scope_identity()
      else
        begin
        select -2--insert Error
        return(0)
        end
    END
      insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
      insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
      insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
      --Menu para roles RepotsRia
      exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

      select @UserId,'' Usuario '' + @Login + '' Dado de Alta''
      return(0)
      end

    if @option=3--Update
      begin
      if @Login='''' and @Password <> ''''
        begin
        Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId
        return(0)
        end

      Update ccUsers
      set Login= case when @Login <> '''' then @Login else Login end,
      Nombres=@Nombres,
      ApellidoPaterno=@ApellidoPaterno,ApellidoMaterno=@ApellidoMaterno,
      Password=case when @Password <> '''' then @Password else Password end,
      Sexo=@Sexo,canChangeStatus=@canChangeStatus
      where User_id=@UserId
      return(0)
      end

    if @option=4--Delete
      begin
	  delete from ccRIAAgentsPermissions  where AgentId = @UserId
	  delete from ccUsers_Roles where User_id = @UserId
      delete from ccSkills where user_id =@UserId
      delete from ccMenu_ViewsUser where user_id =@UserId
      delete from dbo.ccRIAWorkGroupUsers where user_id =@UserId
      delete from ccUsers where user_id=@UserId
      return(0)
      end

    declare @Type tinyint, @users int,@sql varchar(8000), @NinOut nvarchar(10)

    if @option=5--insert Agente-Supervisor in WorkGroup
      begin
      select @Type=TipoUser_id from ccUsers where User_id=@UserId

      if @Type not in(1,2,6)
        return(0)

      if @Type=1 and((select count(User_id)from ccRIAWorkGroupUsers where User_id=@UserId)>=(select valor from ccSettings where setting_id=63))
        begin
        select 3
        return(0)
        end

      if exists(select @UserId from ccRIAWorkGroupUsers where User_id=@UserId and IDWG=@IDWG)
        begin
        select 1
        return(0)
        end

      insert into ccRIAWorkGroupUsers(IDWG,User_id)values(@IDWG,@UserId)

      if @Type=1
        begin

        if @IDWG is null or @IDWG = 0
          begin
          select 28
          return(0)
          end
        insert into cccampsAgente(user_id,cam_id,prioridad,skill,IDWG)

        select @UserId,idCampEsp,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
        from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
          and idCampEsp not in(select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

        insert into ccinboundAgentes(User_id,Inbound_id,cli_id,prioridad,skill,IDWG)
        select @UserId,idCampEsp,0,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
        from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
          and idCampEsp not in(select inbound_id from ccinboundAgentes where user_id=@UserId and IDWG=@IDWG)

        return(0)
        end

    --else @Type=2 or @Type=6--Supervisor
      insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
      select @UserId,idCampEsp,0,@IDWG
      from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
        and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

      insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
      select @UserId,idCampEsp,1,@IDWG
      from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
        and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
      return(0)
      end

    if @option=6--Delete Agent-Supervisor from WorkGroup
      begin
      if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)=0
        select @UserId = @multipleUsers

            else if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)>0
              select @UserId = cast(substring(@multipleUsers, 1,
              CHARINDEX('','', @multipleUsers)-1) as int)

        select @Type=case when @UserType <> 0 then @UserType else TipoUser_id end,
        @multipleUsers=isnull(@multipleUsers,cast(@Userid as varchar(10)))
      from ccUsers where User_id=@UserId

      Declare @sqlDelete nvarchar(4000)
      if @Type in(1,2,6)--1:Agente / 2,6:Supervisor
        begin
        set @sqlDelete=N''Delete from '' + case @Type when 1 then ''cccampsagente where '' else ''ccSupervisorCam where tipo=0 and '' end
        + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
        + '' Delete from '' + case @Type when 1 then ''ccinboundagentes where '' else ''ccSupervisorCam where tipo=1 and '' end
        + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
        exec(@sqlDelete)
        end

      if isnull(@UserId, 0) = 0 or isnull(@multipleUsers, ''0'') = ''0''
        begin
        select -9 -- Se ingreso mal el id del usuario
        --delete ccinboundagentes where idwg=@IDWG
        --delete cccampsagente where idwg=@IDWG
        --delete ccSupervisorCam where idwg=@IDWG
        end

      if @DeleteUsers=1
        Delete ccRIAWorkGroupUsers where IDWG=@IDWG and User_id=@UserId

      return(0)
      end

    if @option=7--Delete Agent from WorkGroup
      begin
      select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end
      set @sql=''delete '' + case @NinOut when ''1'' then ''ccCampsAgente'' else ''ccInboundAgentes'' end +
        '' where user_id in('' + isnull(@multipleUsers, ''0'') +'') and '' + case @NinOut when ''1'' then ''cam_id'' else ''inbound_id'' end +
        ''='' + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' + cast(@IDWG as varchar(10)) +
        '' delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
      exec(@sql)
      --update preview permission
      set @sql = ''update ccusers set 
          AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
          DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
          select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
          where progDial=3 and user_id in ('' + isnull(@multipleUsers, ''0'') +'') group by user_id)c on us.User_id=c.user_id
          where us.user_id in ('' + isnull(@multipleUsers, ''0'') +'')''
      exec(@sql)
    return(0)
      end

    if @option=8--Delete Supervisor from WorkGroup
      begin
      select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end

            set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and user_id in('' + isnull(@multipleUsers, ''0'') + '') and cam_id=''
              + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' +cast(@IDWG as varchar(10)) + ''
              delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
            exec(@sql)

      set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and cam_id='' + cast(@IDCampEsp as varchar(10)) + ''and '' +
        ''user_id in ('' + isnull(@multipleUsers, ''0'') + '') and IDWG='' + cast(@IDWG as varchar(10))
      exec(@sql)
      return(0)
      end

    if @option=9
      begin

      update ccusers set NotReadyRestricted=@canChangeStatus where [User_id]=@UserId

select Login from ccUsers where [User_id]=@UserId
return(0)
end
set nocount off'
	EXEC(@sql)

	SET @process = '053000 Alter SP ccsp_GalateaAdminCampaigns '
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
@Option AS      SMALLINT, 
@CampType AS    SMALLINT = 0, 
@WorkgroupId AS INT      = 0, 
@Id AS          INT      = 0, 
@AdminId AS     SMALLINT = 0, 
@PinUpdate AS   SMALLINT = 0, 
@LoadId AS      INT      = 0, 
@Type AS        SMALLINT = 0,
@InboundType    SMALLINT = 0,
@AreaId         SMALLINT = 0,
@multi_type     varchar(max) = null
AS
BEGIN
	SET NOCOUNT ON;
	IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type
		BEGIN
			IF @CampType = 1 -- Campaigns Out
				BEGIN
					IF @WorkgroupId IS NOT NULL
						BEGIN
							SELECT CAST(IdCampEsp AS INT) AS Id
							FROM ccRIACampEspWG
							WHERE IDWG = @WorkgroupId
									AND Tipo = 1
									ORDER BY IdCampEsp ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
					END;
			END;
			IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @WorkgroupId IS NOT NULL
						BEGIN
							SELECT CAST(IdCampEsp AS INT) AS Id
							FROM ccRIACampEspWG
							WHERE IDWG = @WorkgroupId
									AND Tipo = 0
									ORDER BY IdCampEsp ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
					END;
			END;
			RETURN 0;
	END;
	IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id
		BEGIN
			IF @CampType = 1 -- Campaigns Out
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
							CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
							isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
							camps.cam_procesando IsStarted, 
							ISNULL(a.AreaName, '''') AS Area, 
							CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
							CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
							ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
							FROM ccCamps camps
							LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
							LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
							LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
							WHERE camps.cam_id = @Id
							ORDER BY camps.cam_descripcion ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
					END;
			END;
			IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
							CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, 
							ISNULL(a.AreaName, '''') AS Area, 
							CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType
							FROM ccInbound inb
									LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
									LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
							WHERE inb.Inbound_id = @Id
									ORDER BY inb.descripcion ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe campañas de entrada con el id especificado'', 18, 1);
					END;
			END;
			RETURN 0;
	END;
	IF @Option = 3   -- Update OverallTotalNew By Campaign
		BEGIN
			IF @Id IS NOT NULL
				BEGIN
					UPDATE ccCampsNvosCB
						SET 
							OverallTotalNew = ccCampsNvosCB.new
					WHERE id = @Id;
			END;
			ELSE
				BEGIN
					RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 4   -- Update Pin from Campaign per Admin
		BEGIN
			IF @Id IS NOT NULL
				AND @AdminId IS NOT NULL
				BEGIN
					IF @PinUpdate = 1
						BEGIN
							INSERT INTO PinedCampaigns(CampId, AdminId, Type)
						VALUES(@Id, @AdminId, @Type);
					END;
					IF @PinUpdate = 0
						BEGIN
							DELETE FROM PinedCampaigns
							WHERE CampId = @Id
									AND AdminId = @AdminId
									AND Type = @Type;
					END;
			END;
			ELSE
				BEGIN
					RAISERROR(''ERROR. La campañas o administrador no existen'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 5   -- Get Pin from Campaign Ids per Admin
		BEGIN
			IF @AdminId IS NOT NULL
				BEGIN
					SELECT CampId AS Id
					FROM PinedCampaigns
					WHERE AdminId = @AdminId
							AND Type = @Type
							ORDER BY Id ASC;
			END;
			ELSE
				BEGIN
					RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 6   -- Get Blacklist Ids by Campaign Id
		BEGIN
			IF @Id IS NOT NULL
				BEGIN
					DECLARE @BlackListIds VARCHAR(MAX);
					SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
					FROM Camplistanegra
					WHERE cam_id = @Id
							AND STATUS = 1;
					SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
			END;
			ELSE
				BEGIN
					RAISERROR(''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
		BEGIN
			IF(@Id IS NOT NULL
				AND EXISTS
			(
				SELECT *
				FROM cccamps
				WHERE cam_id = @Id
			))
				BEGIN
					SELECT TOP 1 list_id
					FROM ccRIARegistryLists
					WHERE cam_id = @Id
							AND STATUS = 2
							ORDER BY list_id DESC;
			END;
			ELSE
				BEGIN
					--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
					RAISERROR(''ERROR. No existe una campaña con el id especificado'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
		BEGIN
			IF(@LoadId IS NOT NULL
				AND EXISTS
			(
				SELECT *
				FROM ccRIARegistryLists
				WHERE list_id = @loadID
						AND STATUS <> 0
			))
				BEGIN
					UPDATE ccoCallsOutSource
						SET 
							cal_status = ''5''
					WHERE list_id = @loadID;
					DELETE FROM ccoWorkingTable
					WHERE list_id = @LoadId;
					EXEC ccsp_RIARegistryLists 
							@action = 6, 
							@list_id = @LoadId;
			END;
			ELSE
				BEGIN
					--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
					RAISERROR(''ERROR. No existe una carga el id especificado'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
		BEGIN
			DECLARE @table TABLE
			(camId    INT, 
				campType TINYINT, 
				PRIMARY KEY(camId, campType)
			);
			INSERT INTO @table
					SELECT DISTINCT 
							IdCampEsp, Tipo
					FROM ccRIACampEspWG wg
					WHERE wg.IDWG IN
					(
						SELECT IDWG
						FROM ccRIAWorkGroupUsers
						WHERE IDWG <> @WorkgroupId
								AND User_id = @AdminId
					);
			SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
			FROM @table A
					RIGHT JOIN
			(
				SELECT wg.IdCampEsp, wg.Tipo
				FROM ccRIACampEspWG wg
				WHERE wg.IDWG = @WorkgroupId
			) B ON A.camId = B.IdCampEsp
					AND A.campType = B.Tipo
			WHERE A.camId IS NULL
					ORDER BY IdCampEsp;
			RETURN 0;
	END;
	IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type
	BEGIN
	DECLARE @date DATETIME= CONVERT(DATE, DATEADD(hh, -3, GETDATE()));
	DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY(id));
	DECLARE @AgentsList TABLE(id INT, PRIMARY KEY(id));
	DECLARE @tmpCamAgent TABLE(camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY(camId, userId));
	DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT );
	DECLARE @CurrentStatus TABLE(userId INT, CurrentState INT, IdCampEsp INT, camType INT);
	DECLARE @campDataTotal TABLE(camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY(camId));

	INSERT INTO @AdminWorkgroups SELECT DISTINCT IDWG
	FROM ccRIAWorkGroupUsers WG, 
		ccUsers_Roles R
	WHERE WG.User_id = @AdminId
	OR (R.User_id = @AdminId
	AND R.Rol_id = 7);
					        
	INSERT INTO @AgentsList SELECT DISTINCT A.User_id
	FROM ccRIAWorkGroupUsers A
	INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
	INNER JOIN ccUsers C ON A.User_id = C.User_id 
	AND C.TipoUser_id = 1
	ORDER BY A.User_id;

					INSERT INTO @tmpCamAgent SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id,
	CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
	FROM ccRIACampEspWG campPerWg
	INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
	INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
	INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
	left JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp and @CampType = 0
	left JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp and @CampType = 1
	where C.TipoUser_id = 1
	AND campPerWg.Tipo = @CampType
	AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
					  
	;WITH lastState AS (
	SELECT A.user_id, MAX(A.fecha) AS fecha
	FROM ccLogAgentesDia A
	INNER JOIN @AgentsList B ON A.User_id = B.id
	WHERE fecha >= @date
	GROUP BY user_id)

	INSERT INTO @CurrentStatus 
	SELECT B.User_id,
	CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS currentStatus,
	B.IdCampEsp,
	B.Tipo
	FROM lastState A
	INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
	AND A.fecha = B.fecha;

	IF @Id = 0 AND @CampType = 0 
	BEGIN
	DELETE FROM @tmpCamAgent WHERE multimediaType = 5
	END

	DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;
	IF @CampType = 1 BEGIN
	SELECT @MultimediaType = meanContactTypeId FROM contactMeanOut WHERE camp_id = @Id
	END
	ELSE BEGIN
		SELECT @chatType = ci.chat FROM dbo.ccInbound AS ci WHERE ci.Inbound_id = @Id;
		SELECT @MultimediaType = meanContactTypeId FROM contactMeanIn WHERE inboundId = @Id
	END 

	IF(@chatType = 1)
	BEGIN
		SET @MultimediaType = 1
	END
			
	DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN ''23'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes
			
	INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
	(CASE 
		WHEN @chatType = 1 THEN 
		CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'',''))  THEN @CampType 
		ELSE 
		CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN @CampType 
		ELSE null 
		END END END) AS isCampDialog, B.camType
	FROM @tmpCamAgent A
	INNER JOIN @CurrentStatus B ON A.userId = B.userId
	WHERE (@Id = 0 or A.camId = @Id)

	IF @CampType = 1
	BEGIN
	;with  campDataTotal as(
		select camId,count(*) total from @tmpCamAgent A group by camId
	)

	insert into @campDataTotal
	select 
		A.camId,
		B.cam_descripcion as campName 
		,A.Total
		,C.AreaName as Area
		from campDataTotal A
		INNER JOIN ccCamps B ON A.camId= B.cam_id 
		INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
	END
	ELSE
	BEGIN    
	;with  campDataTotal as(
		select camId,count(*) total from @tmpCamAgent A group by camId
	)

	insert into @campDataTotal
	select 
		A.camId,
		B.descripcion as campName 
		,A.Total
		,C.AreaName as Area
		from campDataTotal A
		INNER JOIN ccInbound B ON A.camId = B.Inbound_id 
		INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
	END

	;WITH stateCamp AS(
	SELECT A.CampId,
	count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
	count(CASE WHEN A.CurrentState NOT IN(-2, -1, 0, 3, 4, 5, 6, 9, 30, 34) THEN 1 
			WHEN A.CurrentState IN (6, 34, 4) AND (A.CampId != C.IdCampEsp OR A.campType != @CampType) THEN 1 ELSE NULL END) AS notReady,
	COUNT(isCampDialog) AS dialog, 
	COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected 
	FROM @AgentStatus A
	INNER JOIN @CurrentStatus C ON A.userId = C.userId
	GROUP BY A.CampId
	)

	SELECT 
	A.camId,
	A.campName,
	A.Total,
		ISNULL(B.ready, 0) AS Ready,
	ISNULL(B.notReady, 0 ) AS NotReady, 
	ISNULL(B.dialog, 0) AS Dialog,
	CASE WHEN B.disconnected IS NULL THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END Disconnected,
	A.Area
	FROM @campDataTotal A
	LEFT JOIN stateCamp B ON A.camId = B.CampId
	ORDER BY A.campName

		RETURN 0;
	END;
	IF @Option = 11  -- Get Campaigns Ids List Per Workgroup and Campaign Type
		BEGIN                
			IF Not EXISTS
			(
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
						AND Rol_id = 7
			)
				BEGIN
		print ''xxxx SIn Super''
					;WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS Id
							FROM ccRIACampEspWG A (NOLOCK)
								INNER JOIN wgId ON wgId.IDWG = A.IDWG
													AND A.Tipo = @CampType;
			END;
			ELSE
				BEGIN
		--print ''xxxx Super''
		IF @CampType = 1
		BEGIN
			SELECT DISTINCT 
				CAST(cam_id AS INT) AS Id
						FROM ccCamps (NOLOCK) where IDArea IS NOT NULL
		END
		ELSE
		BEGIN 
			SELECT DISTINCT 
				CAST(Inbound_id AS INT) AS Id
						FROM ccInbound (NOLOCK) where IDArea IS NOT NULL
		END
			END;
			RETURN 0;
	END;
	IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
		BEGIN
			IF @CampType = 1 -- Campaigns Out
				BEGIN
					SELECT DISTINCT 
					CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
					isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
					camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
					CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
					ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
					FROM ccCamps camps (NOLOCK)
					INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
					INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
					INNER JOIN ccCampsExtend extended (NOLOCK) ON camps.cam_id = extended.cam_id
					--WHERE camps.cam_id = @Id
					ORDER BY camps.cam_descripcion ASC;
			END;
			ELSE
				BEGIN
					SELECT DISTINCT 
											CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId, inb.chat AS InboundType, 0 as OutboundType
					FROM ccInbound inb (NOLOCK)
							INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
							INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = inb.IDArea
							ORDER BY inb.descripcion ASC;
			END;
			RETURN 0;
	END;
	IF @Option = 13
	BEGIN
		BEGIN                
			IF NOT EXISTS
			(
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
						AND Rol_id = 7
			)
				BEGIN
					IF @CampType = 1
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,CAST(-1 AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 1
									INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id;
						END
					ELSE
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A (NOLOCK)
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 0
									INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id 
									AND ((@multi_type is null AND cci.chat = @InboundType)
										OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
						END
			END;
			ELSE
				BEGIN
				IF @CampType = 1
					BEGIN
						SELECT DISTINCT 
								CAST(cam_id AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,-1 AS RelatedCampId
						FROM ccCamps NOLOCK where IDArea = @AreaId
					END
				ELSE
					BEGIN 
						SELECT DISTINCT 
								CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
						FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
						AND ((@multi_type is null AND cci.chat = @InboundType)
							OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

					END
			END;
			RETURN 0;
		END;
	END;

	IF @Option = 14
		BEGIN
			IF NOT EXISTS
			(
					SELECT *
					FROM ccUsers_Roles NOLOCK
					WHERE User_id = @AdminId
							AND Rol_id = 7
			)
				BEGIN
					WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
							FROM ccRIACampEspWG A (NOLOCK)
								INNER JOIN wgId ON wgId.IDWG = A.IDWG
													AND A.Tipo = 0
								INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND isnull(cci.cam_id,-1) = -1
								AND ((@multi_type is null AND cci.chat = @InboundType)
									OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

				END
			ELSE
				BEGIN
					SELECT DISTINCT 
					CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
					FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND isnull(cam_id,-1) = -1
					AND ((@multi_type is null AND cci.chat = @InboundType)
						OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

				END
		END
	IF @Option = 15
		BEGIN
			SELECT DISTINCT 
			CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
			FROM ccInbound NOLOCK where cam_id = @Id
		END
END;
'
	EXEC(@sql)

	---------------------------------------END Ivan Martin---------------------------------------------------------
	---------------------------------------Begin Jesus Gallardo---------------------------------------------------------
	SET @process = 'Alter SP ccsp_Multimedia2 Se agrega parametro @multimediaType'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_Multimedia2] @action INT, @inboundId INT = NULL, @userId INT = NULL
, @senderId INT = NULL,@camType bit=0
,@multimediaType int =null
AS
BEGIN
	SET NOCOUNT ON;

	IF @action = 1
	BEGIN --Lista Cam Or  ACD
		if @camType=0 begin		
			SELECT DISTINCT A.inbound_id AS Id, A.chat AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets,
			cast(isnull(C.maxWhats, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId
			FROM ccInbound A
			INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
			WHERE (@inboundId IS NULL OR @inboundId = A.Inbound_id)
			and (@multimediaType is null or @multimediaType =-1 or A.chat=@multimediaType)
		end
		else begin
			SELECT DISTINCT A.cam_id AS Id,convert(tinyint, case when A.CampType =5  then A.CampType else 1 end) AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets,
			cast(isnull(C.maxWhats, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId
			FROM ccCamps A
			INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
			WHERE (@inboundId IS NULL OR @inboundId = A.cam_id)
			and (@multimediaType is null or @multimediaType =-1 or A.CampType=@multimediaType)
		end
	END
	ELSE IF @action = 2
	BEGIN --Lista Agentes
		if @camType=0 begin
			SELECT DISTINCT A.User_id AS [Id], C.idCampEsp AcdId, isnull(skill, 8) Skill
			FROM ccRIAWorkGroupUsers A
			INNER JOIN ccusers B ON A.User_id = B.User_id
			INNER JOIN ccRIACampEspWG C ON C.IDWG = A.IDWG -- AND C.Tipo = 0
			INNER JOIN ccInbound D ON C.idCampEsp = D.inbound_id  and D.IDArea is not null
			LEFT JOIN ccskills S ON S.inbound_id = D.inbound_id AND S.user_id = B.user_id
			WHERE B.TipoUser_id = 1 AND (@userId IS NULL OR @userId = A.User_id)
			and (@multimediaType is null or @multimediaType =-1 or D.chat=@multimediaType)
			ORDER BY A.User_id
		end
		else begin
			SELECT DISTINCT A.User_id AS [Id], C.idCampEsp AcdId, isnull(skill, 8) Skill
			FROM ccRIAWorkGroupUsers A
			INNER JOIN ccusers B ON A.User_id = B.User_id
			INNER JOIN ccRIACampEspWG C ON C.IDWG = A.IDWG -- AND C.Tipo = 0
			INNER JOIN ccCamps D ON C.idCampEsp = D.cam_id  and D.IDArea is not null
			LEFT JOIN ccskills S ON S.inbound_id = D.cam_id AND S.user_id = B.user_id
			WHERE B.TipoUser_id = 1 AND (@userId IS NULL OR @userId = A.User_id)
			and (@multimediaType is null or @multimediaType =-1 or D.CampType=@multimediaType)
			ORDER BY A.User_id
		end
	END
	ELSE IF @action = 3
	BEGIN --List Sender Mail
		SELECT A.contactMeanOutId AS Id, ISNULL(R.inboundId, 0) AS AcdId, A.isActive AS IsActive
		FROM contactMeanOut A
		LEFT JOIN relationContactMeanOutInbound R ON A.contactMeanOutId = R.contactMeanOutId
		WHERE (@senderId IS NULL OR @senderId = A.contactMeanOutId) and A.meanContactTypeId = 1
	END
	ELSE IF @action = 4
	BEGIN --List ACD Whatsapp
		if @camType=0 begin
			SELECT cast(Inbound_id as int) AS Id
			FROM ccInbound
			WHERE chat=5
		end
		else begin
			SELECT cast(cam_id as int) AS Id
			FROM ccCamps
			WHERE CampType = 5
		end
	END
END'
	EXEC(@sql)

	SET @process = 'Alter SP ccsp_GetInfoDash Se modifica para que se valide que inserta la informacion y no tenga flujo repetido'
	SET @sql = 'ALTER procedure [dbo].[ccsp_GetInfoDash]
@CampId as smallint
as
set nocount on				
declare @upd_date as datetime
declare @cps  as int 
declare @today datetime

select @cps = [valor] from ccSettings  where setting_id=238
select
	@upd_date = date_update
from ccCampsInfo with(nolock) where cam_id = @CampId

set @today=convert(date,getdate(),121)

if @upd_date is null begin
	insert into ccCampsInfo(cam_id,contact_reg,dial_retries,date_update,calls_per_second)
	values(@CampId,0,0,getdate(),@cps)

	set @upd_date=@today
end

select @today,datediff(ss, @upd_date, getdate())

if (datediff(ss, @upd_date, getdate()) > 300) begin
	if not exists(select cam_id from ccocallsout with(nolock)
	where cam_id=@CampId and statuscall_id=13 and cal_inicio>= @today)
	begin
		update ccCampsInfo
			set contact_reg=0, dial_retries=0, date_update = getdate(), calls_per_second=@cps
		where cam_id = @CampId		
	end else
	begin

		declare @vop1 decimal(5,2)
		declare @vop2 decimal(5,2)
		declare @vop3 decimal(5,2)
		declare @vop4 decimal(5,2)

		select @vop1 = count(distinct(callout_id)) from ccocallsout with(nolock)
		where cam_id = @CampId and statuscall_id=13 and cal_inicio>= @today
		group by cam_id
		select @vop2 = count(distinct(callout_id)), @vop4 = count(distinct telefono) from ccoLogDials with(nolock) 
		where cam_id = @CampId and fecha >= @today
		group by cam_id
		select @vop3 = count(distinct telefono) from ccoLogDials with(nolock) 
		where cam_id = @CampId and fecha >= @today
		group by cam_id, Telefono having count(1) > 1
		
		select @vop1,@vop2,@vop3,@vop4
		update ccCampsInfo set
			 contact_reg=case when @vop2=0 then 0 else (@vop1/@vop2)*100 end
			, dial_retries=case when @vop4=0 then 0 else(@vop3/@vop4)*100 end
			, date_update=getdate()
	end
end

select
cam_id, contact_reg, dial_retries, date_update, calls_per_second
from ccCampsInfo
where cam_id = @CampId


set nocount off'
	EXEC(@sql)

	SET @process = '21 - ccsp_RIA_ABCCamps (Option 2, 3) - SP Edited, edited to add records to Activity Log, (Crear/Editar Campaña de Salida (Llamada/VP/WhatsApp/IA/SMS))'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
@option smallint,
@UserId int = null,
@Descripcion varchar(40) = null,
@Cam_id varchar(1000),
@Activa tinyint = null,
@IDArea smallint = null,
@frame tinyint = null, 
@MirrorInbound_Id smallint = null,
@Prefijo varchar(40) = null,
@MediaType int = null,
@isCreating int = null
as
set nocount on

if @option = 0
    begin
        select cam_id,ISNULL(cam_descripcion,'''''''') as cam_descripcion,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
        from ccCamps as CAMP with(nolock) 
        left join ccRIACat_Areas as AREas with(nolock) on CAMP.IDArea = AREas.IDArea
        return(0)
    end

if @option = 1 -- select Camp
    begin
        select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0) as Area_Id,
        prefijo as Prefijo
        from ccCamps a1 with(nolock) 
        inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
        inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
        where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
        return(0)
    end

if @option = 4 --Delete
    begin
        if exists (select inbound_id from ccInbound with(nolock) where cam_id = @Cam_id)
        begin
        declare @error varchar(70)
        Select @error=case valor when 0 then ''No es posible eliminar la campa?a, esta asociada a una especialidad''
            else ''Campaign can not be deleted, it has an association with an ACD'' end
        from ccsettings with(nolock) where setting_id = 27
        raiserror (@error,18,1)     
        return(0)
        end

        delete ccCampsHorarios with(rowlock) where cam_id = @Cam_id
        insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id) Values(@Cam_id, 5, 0, 0, @UserId)
        Delete ccCalifCamp with(rowlock) where cam_id = @Cam_id and tipo = 1
        Delete ccRIACampsGraph with(rowlock) where cam_id = @Cam_id
        delete ccHistorialListaNegra with(rowlock) where cam_id = @Cam_id
        delete ccRIARegistryLists with(rowlock) where cam_id = @Cam_id  
        return(0)
    end

if @option = 2 --Insert
    begin
    declare @new_cam_id smallint
    declare @isAssingPortbyCam bit

    DECLARE @CampTypeNormal INT = 0

    if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
        begin
        select -1 --, ''Nombre en Uso''
        return(0)  
        end

    -- ODC: la campa?a siempre esta activa
    set @Activa = 1
    declare @pref int
    select  @pref = valor from ccSettings where setting_id = 201
    if (@pref = 0)
        set @Prefijo = ''''


    Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd,prefijo, CampType)
    select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
    case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end, @Prefijo, @CampTypeNormal

    if @@rowcount = 1 BEGIN
    select @new_cam_id = scope_identity()

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @UserId), 
        CASE 
            WHEN @MediaType = 6 THEN 44
            WHEN @MediaType = 5 THEN 46
            WHEN @MediaType = 4 THEN 48
            WHEN @MediaType = 7 THEN 50
            ELSE 42 END, 
        3, 
        '''',
        '''', 
        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @new_cam_id);

    END else
        begin
        select -2 --, ''Error al crear campa?a''
        return(0)
        end

    if isnull(@MirrorInbound_Id, 0)<>0
        begin
        if not exists(select inbound_id from ccInbound with(nolock) where inbound_id=@MirrorInbound_Id)
            begin
            select -3 -- Error al asignar campa?a a ACD, el ACD no existe o no pertenece a la misma area
            return(0)
            end

        update ccinbound with(rowlock) set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
        update cccamps with(rowlock) set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
        end
    set @isAssingPortbyCam=1

    select @isAssingPortbyCam=valor from ccSettings where setting_id=232

    if @isAssingPortbyCam=1 begin
        insert into ccoDialerCamp (dialer_id, cam_id) 
        select dialer_id, @new_cam_id from ccoDialers with(nolock) where status = 1
    end

    insert into ccCalifCamp (calif_id, cam_id, tipo) 
    select calif_id, @new_cam_id, 1 from ccTipoCalifOUT with(nolock) where CalifOut_Status = 1

    update ccCamps set keepDial=dbo.fn_keepDial_Camps(@new_cam_id) where cam_id=@new_cam_id

    If not exists (select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
        begin
        insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
        end

    insert into ccRIACampsGraph (cam_id, graphic_id)
    select @new_cam_id, graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock)  where frame = @frame and type_id = 1

    --inserta la lista negra por default
    if (select valor from ccsettings with(nolock) where setting_id=152)=''1''
    begin
        declare @tempId as int = 0
        select @tempId = idtipolista from cctiposlistanegra where Tipolista = ''defaultList/General''
        exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
    end

    --select * from cctiposlistanegra

    select @new_cam_id
    return(0)
    end

if @option = 3 -- Update
    begin
        if not exists(select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
        insert into ccRIAGraphics (frame,type_id) values (@frame,1)

        Update ccCamps with(rowlock) set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

        DECLARE @PrevFrame SMALLINT = (SELECT [graphic_id] FROM ccRIACampsGraph WHERE cam_id = @Cam_id);

        update ccRIACampsGraph with(rowlock)
        set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
        where cam_id = @Cam_id

        IF(@isCreating IS NOT NULL AND @isCreating = 2 AND @PrevFrame <> (SELECT [graphic_id] FROM ccRIACampsGraph WHERE cam_id = @Cam_id)) BEGIN
            DECLARE @Media INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @Cam_id);

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            SELECT 
                (SELECT CRA.[AreaName] FROM ccRIACat_Areas AS CRA, ccCamps AS CCC WHERE CRA.IDArea = CCC.IDArea AND CCC.cam_id = @Cam_id),
                getDate(), 
                (SELECT [Login] FROM ccUsers WHERE User_id = @UserId), 
                CASE
                    WHEN @Media = 6 THEN 55
                    WHEN @Media = 5 THEN 56
                    WHEN @Media = 4 THEN 57
                    WHEN @Media = 7 THEN 58
                    ELSE 54 END, 
                3, 
                '''',
                ''OUT_CALL_EDIT_ICON'', 
                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @Cam_id);
        END

        return(0)
    end

    if @option = 5 --Obtener relaciones de campa?as - campa?as
    begin
        if not exists (select cam_id from ccCamps with(nolock) where cam_id = @Cam_id) or
        (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
        not exists (select cam_id from ccCamps with(nolock) where cam_id=@descripcion))
        begin
        select -3 -- Campa?a invalida
        return(0)
        end
                
    if @descripcion=0
        set @descripcion = null

    update ccCamps with(rowlock) set surveyCamId = @descripcion where cam_id = @Cam_id
    if @@rowcount=0
        select -4 -- Error al actualizar
                    
    else
        begin
        delete cccalifcamp with(rowlock) where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

        end

    return(0)
    end

if @option = 6
    begin
        select cam_id, isnull(surveycamid,0)
        from cccamps with(index(PK_ccCamps),nolock)
        where cam_id = @Cam_id
        return(0)
    end

if @option = 7 -- Checa si la campa?a no tiene grabaciones y se puede modificar el prefijo
    begin   
        select count(*) as Grabaciones from ccoCallsOut where cam_id = @Cam_id
        --select 0 as Grabaciones   
    end

if @option = 8 -- Checa si la campa?a tiene asignada una campa?a tipo encuesta
    begin   
        SELECT CAST(CASE WHEN  isnull(surveycamid,0) != 0 THEN 1 ELSE 0 END AS bit)
        from cccamps with(index(PK_ccCamps),nolock)
        where cam_id = @Cam_id
        return(0)
    end

return(0)
set nocount off
        '
        EXEC(@sql)
	---------------------------------------END Jesus Gallardo---------------------------------------------------------
	
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