/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

Database: CCenterRia
Required version: 123.27

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
SET @version = 123 --**********actualizar a 123 sin fix
SET @versionfix = 30
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= 30
BEGIN
	BEGIN TRAN

	BEGIN TRY

	-------------------------  Start CCC --------------------------------------------------
	 set @process = 'Se añade columna para permitir archivos adjuntos'
     set @sql = 'if not exists (select * from sys.columns where name = N''allowFileAttachments'' and Object_ID = Object_ID(N''contactMeanIn''))
				begin
					ALTER TABLE dbo.contactMeanIn ADD allowFileAttachments bit;
				end'
	 EXEC(@sql)

	 set @process = 'Se añade opción de archivos adjuntos para historial'
     set @sql = 'if not exists (select * from ccRIALog_Operation where operationType = 193)
				begin
					insert into  ccRIALog_Operation values (193,''Adjuntar archivos|Attach files'')
				end'
	 EXEC(@sql)


	 set @process = 'Cambio en SP [ccsp_GalateaGetInboundConfiguration]'
     set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
        @command int,
        @inboundId int
      AS
      BEGIN

      SET NOCOUNT ON;

      if @command=0
      begin
        select descripcion from ccInbound where Inbound_id = @inboundId
      end
      if @command=1 -- Voice campaign
      begin
        select 
        A.Inbound_id [InboundId],
        A.descripcion [Description],
        A.chat [MediaType],
        A.Status,
        isnull(gra.graphic_id,1) [Frame],
        A.tNotas,
        A.tMaxWaitCall,
        A.nMaxQue,
        A.tel_maxwait,
        A.tel_maxqueue,
        A.tel_outservice,
        A.tel_noct,
        A.ShowCalifWnd,
        A.editableCallKey [EditableCallKey],
        A.queuePosition [QueuePosition],
        A.tMaxQueueCallBack,
        A.stopRecording [StopRecording],
        A.dialPrefixOverflow [DialPrefixOverflow],
        isnull(A.callerIdDesc, '''') [CallerIdDesc],
        isnull(A.startStopRecording,0) [StartStopRecording],
        case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyAgent  else cast(0 as bit) end [CallBackSurveyAgent],
        case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyClient else cast(0 as bit) end [CallBackSurveyClient],
        case when A.cam_id > 0  and C.callsBySurvey>0 then cast(1 as bit) else cast(0 as bit) end [IsRelationSurvey],
        isnull(A.editableDtmf,0) [EditableDtmf],
        isnull(A.addDataCallBackReminder,0) [AddDataCallBackReminder]
        from ccInbound A
        left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
        left join ccCamps C on C.cam_id=A.cam_id
        where A.Inbound_id=@inboundId
      end
      if @command=2 -- WhatsApp campaign
      begin
        declare @numbers varchar(max)
        select @numbers=COALESCE(@numbers + '','', '''') + number from ccWhatsAppNumbers where inboundId = 0 and status = 1

        select i.Inbound_id [InboundId], i.descripcion [Description], i.chat [MediaType], i.Status, isnull(g.graphic_id,1) [Frame],
        ISNULL(c.conexionInfo,'''') [Number],
        ISNULL(@numbers,'''') [FreeNumbersStr],
        ISNULL(c.closeConversationTime, 0) [MaxAnswerTime],
        ISNULL(c.answerTimeoutClient, 30) [MUTimeOutClient],
		ISNULL(c.allowFileAttachments, 0) [AllowFileAttachments],
        i.tNotas [tNotas],
        i.ExitWrapUpDisposition,
        i.ShowCalifWnd
        from ccInbound i left join ccRIAInboundGraph g on i.Inbound_id = g.Inbound_id
        left join contactMeanIn c on i.Inbound_id = c.inboundId and i.chat = 5 and c.meanContactTypeId = 5
        where i.Inbound_id=@inboundId
      end
      if @command=3 -- Email campaign
      begin
        select 
        A.Inbound_id [InboundId],
        A.descripcion [Description],
        A.chat [MediaType],
        A.Status,
        isnull(gra.graphic_id,1) [Frame],
        A.tNotas,
        A.ShowCalifWnd,
        C.conexionInfo [ConnInfo],
        C.connUser  [ConnUserName],
        C.ConnPass [ConnPwd],
        C.isActive [IsActive],
        C.timeAlertMessage,
        C.closeConversationTime [CloseConversationTime],
        C.answerTimeOut [AnswerTimeOut],
        C.name [SenderName]
        from ccInbound A
        left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
        left join contactMeanIn C on A.Inbound_id = C.inboundId and C.meanContactTypeId=1
        where A.Inbound_id=@inboundId
      end
      RETURN(0)
        
      SET NOCOUNT OFF;    
      END
		'
	 EXEC(@sql)

	 set @process = 'Se cambia ccsp_UpdateACDWhatsappConfig'
     set @sql = 'ALTER PROCEDURE  [dbo].[ccsp_UpdateACDWhatsappConfig]
    @ConexionInfo varchar(400),
    @inbound_id int,
    @ConnUser varchar(60),
    @tNotas int,
    @closeConversationTime tinyint,
    @ShowCalifWnd bit,
    @ExitWrapUpDisposition bit,
    @MUTimeOutClient int,
	@allowFileAttachments bit
    AS
    set nocount on
    IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
    BEGIN
        UPDATE contactMeanIn SET conexionInfo = @conexionInfo, connUser = @connUser, closeConversationTime = @closeConversationTime,
                    ConnPass = ''N/A'', numMessages = 3, timeAlertMessage = 5, answerTimeOut = 10 , answerTimeoutClient = @MUTimeOutClient, allowFileAttachments = @allowFileAttachments        
        where inboundId = @inbound_id;
        UPDATE ccWhatsAppNumbers SET inboundId = @inbound_id WHERE number = @conexionInfo
    END;

    IF EXISTS (SELECT Inbound_id FROM ccInbound WHERE Inbound_id = @inbound_id) 
    BEGIN
        UPDATE ccInbound SET tNotas = @tNotas, ShowCalifWnd = @ShowCalifWnd, ExitWrapUpDisposition = @ExitWrapUpDisposition where Inbound_id = @inbound_id;
    END;
    SELECT @inbound_id;
    return(@inbound_id)

    set nocount off'
	 EXEC(@sql)

	 set @process = 'CW-6946, CW-6984  Se cambia ccsp_GalateaUpdateWhatsAppConfiguration'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateWhatsAppConfiguration]
        @inboundId        smallint,
        @frame          smallint  = null,
        @description      varchar(50) = null,
        @mediaType        tinyint   = null,
        @status         smallint  = null,
        @number         varchar(400)= null,
        @maxAnswerTime      tinyint   = null,
        @muTimeOutClient    int     = null,
        @tNotas         int     = null,
        @exitWrapUpDisposition  bit     = null,
        @showCalifWnd     bit     = null,
		@allowFileAttachments bit    = null
      AS
      BEGIN
        SET NOCOUNT ON;
        DECLARE @graph_id smallint

        UPDATE ccInbound SET
          descripcion = ISNULL(@description, descripcion),
          chat = ISNULL(@mediaType, chat),
          Status = ISNULL(@status, Status),
          tNotas = ISNULL(@tNotas, tNotas),
          ExitWrapUpDisposition = ISNULL(@exitWrapUpDisposition, ExitWrapUpDisposition)
        WHERE Inbound_id = @inboundId

        DECLARE @descUpdate varchar(50)
        DECLARE @statusCCInbound smallint
        select @descUpdate = ISNULL(@description, descripcion), @statusCCInbound = status from ccInbound where Inbound_id =@inboundId

        IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId=@inboundId) 
          BEGIN
              INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) 
          values (5, @descUpdate, @inboundId, @statusCCInbound);
          END

        IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inboundId) 
          BEGIN
		  
		  set @number = case when  @number is null or @number in('''',''0'') then '''' else @number end

          UPDATE contactMeanIn set name=@descUpdate, conexionInfo=ISNULL(@number, conexionInfo)
		  ,connUser=ISNULL(@number, connUser)
		  ,ConnPass=ISNULL(@number, ConnPass) 
          ,closeConversationTime = ISNULL(@maxAnswerTime, closeConversationTime),
          answerTimeoutClient = ISNULL(@muTimeOutClient, answerTimeoutClient),
		  allowFileAttachments = ISNULL(@allowFileAttachments, allowFileAttachments)
          where inboundId = @inboundId;

		  update ccWhatsAppNumbers set inboundId=0 where inboundId=@inboundId
		  if @number <> '''' begin
			update ccWhatsAppNumbers set inboundId=@inboundId where inboundId=0 and number=@number
		  end

          END

        IF @frame IS NOT NULL
        BEGIN
          SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
          UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId
        END

        IF @showCalifWnd = 1
          BEGIN
          IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
              BEGIN
            UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd)
                  WHERE inbound_id = @inboundId
            SELECT 1 [Result]
            RETURN(0)
              END

              SELECT -1 [Result]
              RETURN(0)
           END
           ELSE
         BEGIN
          UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;
         END

         SELECT 1 [Result]
         RETURN(0)

        SET NOCOUNT OFF;
      END'
	 EXEC(@sql)

	 	-- Ivan: Permisos de WhatsApp para agentes (Spam y Desasignar)

		set @process = 'CW-6322 Create table ccRIAUsersPermissions'
		set @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N''ccRIAUsersPermissions'')
					BEGIN
					    CREATE TABLE ccRIAUsersPermissions 
					    (   PermissionId TINYINT NOT NULL,
					        PermissionName VARCHAR(100) NOT NULL, 
					        PermissionTag VARCHAR(100) NOT NULL
					        PRIMARY KEY (PermissionId)
					    );
					END'
		EXEC(@sql)

		set @process = 'CW-6322 Agregar etiquetas a ccRIAUsersPermissions'
		set @sql = 'IF not EXISTS (SELECT * FROM ccRIAUsersPermissions WHERE PermissionName = N''AllowSpam'')
					BEGIN
						INSERT INTO ccRIAUsersPermissions (PermissionId, PermissionName, PermissionTag)
						VALUES (12, ''AllowSpam'',  ''Marcar conversación como spam|Mark conversation as spam|Marcar conversa como spam'')
						INSERT INTO ccRIAUsersPermissions (PermissionId, PermissionName, PermissionTag)
						VALUES (13, ''AllowUnassign'', ''Desasignar conversación|Unassign conversation|Cancelar atribuição da conversa'')
					END'
		EXEC(@sql)

		set @process = 'CW-6322 Modificar etiquetas a de ccRIALog_Operation'
		set @sql = 'IF EXISTS (SELECT * FROM sys.tables where name = N''ccRIALog_Operation'')
					BEGIN
						UPDATE ccRIALog_Operation set descripcion = ''Habilitar permiso|Enable permission'' where operationType = 33
						UPDATE ccRIALog_Operation set descripcion = ''Deshabilitar permiso|Disable permission'' where operationType = 35
					END'
		EXEC(@sql)

		set @process = 'CW-6322 Create table ccRIAUserPermissionsStatusTags'
		set @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N''ccRIAUserPermissionsStatusTags'')
					BEGIN
					    CREATE TABLE ccRIAUserPermissionsStatusTags 
					    (   Language TINYINT NOT NULL,
					        AllAgentsTag VARCHAR(20) NOT NULL
					        PRIMARY KEY (Language)
					    );
					END'
		EXEC(@sql)

		set @process = 'CW-6322 Agregar etiquetas a ccRIAUserPermissionsStatusTags'
		set @sql = 'if not exists (select * from ccRIAUserPermissionsStatusTags where AllAgentsTag = N''Todos los agentes'')
				    begin
				    	INSERT INTO ccRIAUserPermissionsStatusTags (Language, AllAgentsTag) VALUES
						(0, ''Todos los agentes'')
						INSERT INTO ccRIAUserPermissionsStatusTags (Language, AllAgentsTag) VALUES
						(1, ''All agents'')
						INSERT INTO ccRIAUserPermissionsStatusTags (Language, AllAgentsTag) VALUES
						(2, ''Todos os agentes'')
				    end'
		EXEC(@sql)

		set @process = 'CW-6322 Create table ccRIAMultimediaUsersPermissions'
		set @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N''ccRIAMultimediaUsersPermissions'')
					BEGIN
					    CREATE TABLE ccRIAMultimediaUsersPermissions 
					    (   AgentId SMALLINT NOT NULL,
					        AllowUnassign BIT NOT NULL,
					        AllowSpam BIT NOT NULL
					        PRIMARY KEY (AgentId),
					        FOREIGN KEY (AgentId) REFERENCES ccUsers(User_id)
					    );
					END'
		EXEC(@sql)

		set @process = 'CW-6322 Drop ccsp_GalateaCreateUser'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaCreateUser'')
					BEGIN
					    DROP PROCEDURE ccsp_GalateaCreateUser;
					END'
		EXEC(@sql)

		set @process = 'CW-6322 Se agrega implementacion en ccsp_GalateaCreateUser para agregar nuevo agente a la nueva tabla de ccRIAMultimediaUsersPermissions'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaCreateUser]
					@UserId int,
					@Login varchar(40),
					@Nombres varchar(45),
					@LastName varchar(45),
					@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
					@Password varchar(200),
					@Sexo bit,
					@canChangeStatus bit,
					@AreaId int,
					@UserType tinyint
					as

					Declare @ApellidoMaterno varchar(45)
					Declare @ApellidoPaterno varchar(45)

					--Obtiene el idioma de de Centerware
					Declare @lenguageXion varchar
					select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

					--se acondiciona los apellidos con el nombre opcional dependiendo del idioma
					  if @lenguageXion= ''0'' or @lenguageXion= ''2'' --para español y portugues
					    begin
					      set @ApellidoPaterno = @LastName
					      set @ApellidoMaterno = @NombreOpcionalExtra
					    end
					  else-- es idioma ingles
					    begin
					      set @ApellidoPaterno = @NombreOpcionalExtra 
					      set @ApellidoMaterno = @LastName
					    end

					-- validaciones 
					  if exists(select Login from ccUsers where Login=@Login)
					    begin
					    select -1 as ResponseCode--,''Login en Uso''
					    return(0)
					    end

					  if exists(select Login from ccUsers_Consulta where Login = @Login)
					  begin
					    select -4 as ResponseCode -- ''Login en Uso aunque el usuario ya se halla borrado de la base de datos'' -- quiza falta la validacion cuando el usuario ya se ha borrado pero mediante borrado logico
					    return(0)
					  end

					  if exists(select Nombres from ccUsers where Nombres=@Nombres
					  and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
					    begin
					    select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
					    return(0)
					    end


					--insert
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
					    select -3 as ResponseCode --Error_when_inserting_user
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

					  --Insert Agent into ccRIAMultimediaUsersPermissions
					  IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
					  BEGIN
					    IF NOT EXISTS (SELECT * FROM ccRIAMultimediaUsersPermissions WHERE AgentId = @UserId)
					    BEGIN 
					        INSERT INTO ccRIAMultimediaUsersPermissions(AgentId, AllowUnassign, AllowSpam)
					        VALUES (@UserId, 0, 0)
					    END
					  END

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

					  --Insert Agent into ccRIAMultimediaUsersPermissions
					  IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
					  BEGIN
					    IF NOT EXISTS (SELECT * FROM ccRIAMultimediaUsersPermissions WHERE AgentId = @UserId)
					    BEGIN 
					        INSERT INTO ccRIAMultimediaUsersPermissions(AgentId, AllowUnassign, AllowSpam)
					        VALUES (@UserId, 0, 0)
					    END 
					  END
					select 200 as ResponseCode -- indica que se agrego correctamente un nuevo usuario'
		EXEC(@sql)

		set @process = 'CW-6322 Drop ccsp_GalateaAdminSetPermissions'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSetPermissions'')
					BEGIN
					    DROP PROCEDURE ccsp_GalateaAdminSetPermissions;
					END'
		EXEC(@sql)

		set @process = 'CW-6322 Se agrega implementacion para Permisos de Spam y Desasignar de WhatsApp con registro en historial'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
			@adminId SMALLINT,
			@areaId SMALLINT,
		    @agentsIds VARCHAR(MAX),
			@allAgentsSelected BIT, 
		    @permissionName VARCHAR(255),
		    @permissionValue INT
		AS
		SET NOCOUNT ON

		DECLARE @changeBit INT

		SET @changeBit =
		CASE
		    WHEN @permissionName = ''AllowCellPhoneCalls'' or @permissionName = ''startStopRecording'' or @permissionName = ''XferManual'' or @permissionName = ''AllowTransferCalls'' or @permissionName = ''AgentPermissionDailing''or @permissionName = ''DailingMode'' or @permissionName=''AgentPermissionDailing''
		    THEN 1
		    WHEN @permissionName = ''AllowLongDistanceCalls'' or @permissionName = ''XferExt'' 
		    THEN 2
		    WHEN @permissionName = ''AllowLocalCalls'' or @permissionName = ''XferCamps''
		    THEN 4
		    WHEN @permissionName = ''XferAgents''
		    THEN 8
		    ELSE 0
		END
		print(@changeBit)
		IF @agentsIds IS NOT NULL
		BEGIN
			DECLARE @AgentIdsTemp TABLE (AgentId INT, Status BIT)
			INSERT INTO @AgentIdsTemp SELECT VALUE, 0 FROM dbo.fn_RIASplitDelimited(@agentsIds,'','')

			IF @permissionName = ''AllowUnassign'' 
			BEGIN 						
				UPDATE permissions SET permissions.AllowUnassign = @permissionValue FROM @AgentIdsTemp agentIds
				INNER JOIN ccRIAMultimediaUsersPermissions permissions ON agentIds.AgentId = permissions.AgentId

				INSERT INTO ccRIAMultimediaUsersPermissions(AgentId, AllowUnassign, AllowSpam)
				SELECT agentIds.AgentId , @permissionValue, 0 FROM @AgentIdsTemp agentIds
				LEFT JOIN ccRIAMultimediaUsersPermissions permissions ON agentIds.AgentId = permissions.AgentId
				WHERE permissions.AgentId IS NULL
			END
			IF @permissionName = ''AllowSpam''
			BEGIN 
				UPDATE permissions SET permissions.AllowSpam = @permissionValue FROM @AgentIdsTemp agentIds
				INNER JOIN ccRIAMultimediaUsersPermissions permissions ON agentIds.AgentId = permissions.AgentId

				INSERT INTO ccRIAMultimediaUsersPermissions(AgentId, AllowSpam, AllowUnassign)
				SELECT agentIds.AgentId , @permissionValue, 0 FROM @AgentIdsTemp agentIds
				LEFT JOIN ccRIAMultimediaUsersPermissions permissions ON agentIds.AgentId = permissions.AgentId
				WHERE permissions.AgentId IS NULL
			END

		    UPDATE
		        ccUsers
		    SET DialMask =
		        CASE
		        WHEN @permissionName = ''AllowCellPhoneCalls''
		        OR @permissionName = ''AllowLongDistanceCalls''
		        OR @permissionName = ''AllowLocalCalls''
		        THEN 
		            CASE
		            WHEN @permissionValue = 1
		            THEN
		                CASE
		                WHEN (DialMask & @changeBit) <> @changeBit
		                THEN DialMask ^ @changeBit
		                ELSE DialMask
		                END
		            WHEN @permissionValue = 0
		            THEN
		                CASE
		                WHEN (DialMask & @changeBit) = @changeBit
		                THEN DialMask ^ @changeBit
		                ELSE DialMask
		                END
		            END 
		        ELSE DialMask
		        END,
		                    
		        XferMask =
		        CASE
		        WHEN @permissionName = ''AllowTransferCalls''
		        THEN
		            CASE
		            WHEN @permissionValue = 1
		            THEN
		                CASE
		                WHEN (XferMask & @changeBit) <> @changeBit
		                THEN XferMask ^ @changeBit
		                ELSE XferMask
		                END
		            WHEN @permissionValue = 0
		            THEN
		                CASE
		                WHEN (XferMask & @changeBit) = @changeBit
		                THEN XferMask ^ @changeBit
		                ELSE XferMask
		                END
		            END
		        ELSE XferMask
		        END,

		        XferAgents =
		        CASE
		        WHEN @permissionName = ''XferAgents''
		        OR @permissionName = ''XferCamps'' 
		        OR @permissionName = ''XferExt'' 
		        OR @permissionName = ''XferManual'' 
		        THEN 
		            CASE
		            WHEN @permissionValue = 1
		            THEN
		                CASE
		                WHEN (XferAgents & @changeBit) <> @changeBit
		                THEN XferAgents ^ @changeBit
		                ELSE XferAgents
		                END
		            WHEN @permissionValue = 0
		            THEN
		                CASE
		                WHEN (XferAgents & @changeBit) = @changeBit
		                THEN XferAgents ^ @changeBit
		                ELSE XferAgents
		                END
		            END
		        ELSE XferAgents
		        END,

		        startStopRecording =
		        CASE
		        WHEN @permissionName = ''startStopRecording'' 
		        THEN 
		            CASE
		            WHEN @permissionValue = 1
		            THEN 1
		            WHEN @permissionValue = 0
		            THEN 0
		            END
		        ELSE startStopRecording
		        END,

		        DialingMode = 
		        CASE
		        WHEN @permissionName = ''DailingMode'' 
		        THEN 
		            CASE
		            WHEN @permissionValue = 1
		            THEN
		                CASE
		                WHEN (DialingMode & @changeBit) <> @changeBit
		                THEN DialingMode ^ @changeBit
		                ELSE DialingMode
		                END
		            WHEN @permissionValue = 0
		            THEN
		                CASE
		                WHEN (DialingMode & @changeBit) = @changeBit
		                THEN DialingMode ^ @changeBit
		                ELSE DialingMode
		                END
		            END 
		        ELSE DialingMode
		        END,
		        AllowChangeDialingMode = 
		        CASE
		        WHEN @permissionName = ''AgentPermissionDailing'' 
		        THEN 
		            CASE
		            WHEN @permissionValue = 1
		            THEN 1
		            WHEN @permissionValue = 0
		            THEN 0
		            END
		        ELSE AllowChangeDialingMode
		        END
		    WHERE User_id IN (SELECT AgentId FROM @AgentIdsTemp)

					
			DECLARE @Login VARCHAR(20) = (SELECT Login FROM ccUsers WHERE User_id = @adminId)
			DECLARE @AreaName VARCHAR(50) = (SELECT AreaName FROM ccRIACat_Areas WHERE IDArea = @areaId)
			DECLARE @OperationType TINYINT = (SELECT CASE WHEN @permissionValue = 1 THEN 33 ELSE 35 END)
			DECLARE @Language TINYINT = (SELECT valor FROM ccSettings WHERE setting_id = 27)
			DECLARE @Tag varchar(100) = (SELECT PermissionTag FROM ccRIAUsersPermissions WHERE PermissionName = @permissionName)		
			DECLARE @Value VARCHAR(250) = (SELECT permissions.Value 
											FROM  dbo.fn_RIASplitDelimited(@Tag,''|'') permissions
											WHERE permissions.Id = @Language + 1)

			DECLARE @AgentId INT = 0
			DECLARE @AgentName VARCHAR(20) = ''''

			IF @allAgentsSelected = 0
			BEGIN
				WHILE EXISTS(SELECT * FROM @AgentIdsTemp WHERE Status = 0)
				BEGIN 
					SELECT TOP 1 @AgentId = AgentId FROM @AgentIdsTemp WHERE Status = 0
					SET @AgentName = (SELECT Login FROM ccUsers WHERE User_id = @AgentId)
						
					EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
					@login = @Login, @moduleId = 4, @value = @Value , @target = @AgentName
							
					UPDATE @AgentIdsTemp SET Status = 1 WHERE AgentId = @AgentId
				END
			END
			ELSE
			BEGIN
				SET @AgentName = (SELECT AllAgentsTag FROM ccRIAUserPermissionsStatusTags WHERE Language = @Language)
						
				EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
				@login = @Login, @moduleId = 4, @value = @Value , @target = @AgentName
							
				UPDATE @AgentIdsTemp SET Status = 1
			END


		END

		SET NOCOUNT OFF'
		EXEC(@sql)

		set @process = 'CW-6322 Drop ccsp_GalateaAdminGetPermissions'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminGetPermissions'')
					BEGIN
					    DROP PROCEDURE ccsp_GalateaAdminGetPermissions;
					END'
		EXEC(@sql)

		set @process = 'CW-6322 Se agrega implementacion para Permisos de Spam y Desasignar de WhatsApp con registro en historial'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
		            	@user_id varchar(255),
		            	@Type int
		            AS
		            set nocount on

		            declare @isRoot int;

		            if exists (Select Rol_id from ccUsers A join ccUsers_Roles B on A.User_id = B.User_id where A.User_id = @user_id and rol_id = 7) set @isRoot = 1 else set @isRoot = 0;
		            print @isRoot

		            IF @isRoot = 1
		            BEGIN
		                Select 
		                User_id as AgentId, 
		                Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
		                cast(dialMask & 1 as int) as AllowCellPhoneCalls,
		                cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
		                cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
		                cast( xfermask as int) as AllowTransferCalls, 
		                cast(CanChangeStatus as tinyint) CanChangeStatus,
		                cast(XferAgents as tinyint) XferAgents,
		                ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
		                cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
		                ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
		                ISNULL(multimediaPermissions.AllowUnassign, 0) AS AllowUnassign,
		                ISNULL(multimediaPermissions.AllowSpam, 0 ) AS AllowSpam
		            from 
		                ccUsers users
		            left join ccRIAMultimediaUsersPermissions multimediaPermissions on
		                users.User_id = multimediaPermissions.AgentId
		            where 
		               tipoUser_id = 1
		            return(0)
		            END
		            ELSE
		            BEGIN
		                Select distinct 
		                A.User_id as AgentId, 
		                Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
		                cast(dialMask & 1 as int) as AllowCellPhoneCalls,
		                cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
		                cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
		                cast( xfermask as int) as AllowTransferCalls, 
		                cast(CanChangeStatus as tinyint) CanChangeStatus,
		                cast(XferAgents as tinyint) XferAgents,
		                ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
		                cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
		                ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
		                ISNULL(multimediaPermissions.AllowUnassign, 0) AS AllowUnassign,
		                ISNULL(multimediaPermissions.AllowSpam, 0 ) AS AllowSpam
		            from 
		                ccUsers A
		            join ccRIAWorkGroupUsers B on 
		                A.user_id = B.user_id
		            left join ccRIAMultimediaUsersPermissions multimediaPermissions on
		                A.User_id = multimediaPermissions.AgentId
		            where 
		                tipoUser_id = 1 and 
		                IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
		            return(0)
		            END
		            set nocount off'
		EXEC(@sql)

		-- Ivan (CW-6919) Obtener permiso de agente para mandar a Agent UI en nueva conversacion

        set @process = 'CW-6919,CW-6688 Alter procedure ccsp_MultimediaCommon'
set @sql = 'Alter PROCEDURE [dbo].[ccsp_MultimediaCommon]
@Option AS SMALLINT,
@inboundId AS SMALLINT = 0,
@conversationId AS INT = 0,
@ServiceType AS SMALLINT = 0,
@status as SMALLINT =0,
@messagesList as varchar(max) = '''',
@agentId AS SMALLINT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF(@Option = 1)
        BEGIN

             SELECT --inbound.chat AS ServiceType,
               CAST(inbound.Inbound_id AS INT) AS ACDId,
               inbound.descripcion AS ACDName,
               ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
               CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
               inbound.tNotas AS WrapUpTime

               FROM  ccInbound inbound
               INNER JOIN  contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId where inbound.Status != 0 
        END

    IF(@Option = 2)
        BEGIN
            DECLARE @OldAgentId INT = 0
            DECLARE @OldConversationId INT = 0

            SELECT  @OldAgentId = conv.agentId,
                    @OldConversationId = rel.conversationIdBefore
            FROM ccWhatsAppConversationsRelationship rel 
            RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
            WHERE rel.conversationIdAfter = @conversationId

            SELECT
                  cast(i.chat as int) AS ServiceType,
                  cast(c.conversationId as int) as ConversationID,
                  c.clientId as ClientId,
                  cm.conexionInfo as [To],
                  cast(i.Inbound_id as int) as ACDId,
                  i.descripcion as ACDName,
                  cast(g.graphic_id as int) as ACDGraphicId,
                  cast(cm.closeConversationTime as int) as [TimeOut],
                  cast(cm.answerTimeOut as int) as [TimeOutWarning],
                  i.ExitWrapUpDisposition as [ExitWrapUpDisposition],
                  i.tNotas as [WrapUpTime],
                  i.ShowCalifWnd,
                  cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient],
                  ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent),0) as [SecTimeOutLastMessageAgent],
                  permission.AllowUnassign,
                  permission.AllowSpam,
                  ISNULL(@OldAgentId, 0) AS OldAgentId,
                  ISNULL(@OldConversationId, 0) AS OldConversationId
            FROM  ccInbound i
                INNER JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId
                INNER JOIN ccWhatsAppConversations c ON (c.inboundId = i.Inbound_id and c.conversationId = @conversationId)
                INNER JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
                LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
                LEFT JOIN ccRIAMultimediaUsersPermissions permission ON permission.AgentId = c.agentId

            WHERE i.chat = @ServiceType and i.Inbound_id = @inboundId
        END
    IF(@Option = 3)
        BEGIN
             SELECT
               CAST(inbound.Inbound_id AS INT) AS ACDId,
               inbound.descripcion AS ACDName,
               ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
               CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
               inbound.tNotas AS WrapUpTime

               FROM  ccInbound inbound
               INNER JOIN  contactMeanIn configuration ON (inbound.Inbound_id = configuration.inboundId and inbound.Inbound_id = @inboundId)
        END
    IF(@Option = 4)
    Begin

        declare @pathFile as varchar(max)
        declare @filetype as varchar(5)
        DECLARE @mensajes TABLE(idMessage VARCHAR(100));

        insert into @mensajes
        select value from dbo.fn_RIASplitDelimited(@messagesList,'','')


        select @pathFile = valor from ccSettings where setting_id=230
        select
            messageId as MessageId,
            messageStatus as Status,
            originType as Origin,
            case when originType =''Client'' then 3
                 when originType =''Agent'' then 2
                 when originType =''Admin'' then 1
            else 0 end as OriginType,
            timeStampMessage as [Timestamp],
            case when typeMessage <> ''text''  then '''' else content end as Content,
            typeMessage as Type,
            case when typeMessage not in( ''text'' ,''location'') then content else '''' end as Caption,
            case when typeMessage = ''text'' or typeMessage = ''location'' then '''' else @pathFile +char(92)+cast(conversationId/1000 as varchar(30))+char(92)+cast(conversationId as varchar(20))+char(92)+ typeMessage + char(92)+ messageId +''.''+
            case
                when typeMessage = ''video'' then ''mp4''
                when typeMessage = ''image'' then ''jpg''
                when typeMessage = ''audio'' then ''mp3''
                when typeMessage = ''file'' then (select substring(content, CHARINDEX(''.'',content)+1, len(content)))
                else '''' end
            end as [Url],
            case when typeMessage = ''location''
            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) else '''' end as [Address],
            case when typeMessage = ''location''
            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) else '''' end as [Lat],
            case when typeMessage = ''location''
            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [Long],
            case when typeMessage = ''location''
            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2) else '''' end as [Name],
            case when typeMessage = ''location''
            then ''https://www.google.com/maps/search/'' + (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) + '','' +
                (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [LocationURL]
         from ccWAMessagesConversations where messageId in (select idMessage from @mensajes)
         order by Timestamp asc

    End
    
    IF(@Option = 5)
    BEGIN
        SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
         FROM contactMeanIn
        WHERE inboundId = @inboundId
    END
    IF(@Option = 6)
    BEGIN
        SELECT [Login] AS ''OriginName''
            FROM [CCenterRIA].[dbo].[ccUsers]
        WHERE [User_id] = @agentId
    END
END'
        EXEC(@sql)  

		----------------------- End CCC   ---------------------------------------------

		------------------------------ Start El Santi ---------------------------------

	set @process = 'CW-6688 Version Bd 123.52 update ccsp_AgentHistoricalChat'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentHistoricalChat]
	@option SMALLINT,
	@clientNum VARCHAR(15) = '''',
	@conversationId AS INT = 0,
	@inboundId AS SMALLINT = 0,
	@serviceType AS SMALLINT = 0
    AS
    BEGIN
        IF @option = 1 --whatsapp, get conversation ids
        BEGIN
            SELECT conversationId FROM [CCenterRIA].[dbo].[ccWhatsAppConversations] WHERE clientId = @clientNum GROUP BY conversationId
        END
		IF @option = 2 --whatsapp, get acdId by conversation id
        BEGIN
            SELECT CAST(inboundId AS INT) FROM [CCenterRIA].[dbo].[ccWhatsAppConversations] WHERE conversationId = @conversationId
        END
		IF @option = 3 --get data conversation
		BEGIN
			SELECT
                cast(i.chat as int) AS ServiceType,
                cast(c.conversationId as int) as ConversationID,
                c.clientId as ClientId,
                cm.conexionInfo as [To],
                cast(i.Inbound_id as int) as ACDId,
                i.descripcion as ACDName,
                cast(g.graphic_id as int) as ACDGraphicId,
                cast(cm.closeConversationTime as int) as [TimeOut],
                cast(cm.answerTimeOut as int) as [TimeOutWarning],
                i.ExitWrapUpDisposition as [ExitWrapUpDisposition],
                i.tNotas as [WrapUpTime],
                i.ShowCalifWnd,
                cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient],
                ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent),0) as [SecTimeOutLastMessageAgent]
            FROM  ccInbound i
                INNER JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId
                INNER JOIN ccWhatsAppConversations c ON (c.inboundId = i.Inbound_id and c.conversationId = @conversationId)
                INNER JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
                LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
            WHERE i.chat = @serviceType and i.Inbound_id = @inboundId
		END
		IF @option = 4 --get messages from conversation id
		BEGIN
			declare @filetype as varchar(5)

			select
				messageId as MessageId,
				messageStatus as Status,
				originType as Origin,
				case when originType =''Client'' then 3
						when originType =''Agent'' then 2
						when originType =''Admin'' then 1
				else 0 end as OriginType,
				timeStampMessage as [Timestamp],
				case when typeMessage <> ''text''  then '''' else content end as Content,
				typeMessage as Type,
				case when typeMessage not in( ''text'' ,''location'') then content else '''' end as Caption,
				case when typeMessage = ''text'' or typeMessage = ''location'' then '''' else char(92)+char(92)+''WhatsApp''+char(92)+char(92)+cast(conversationId/1000 as varchar(30))+char(92)+char(92)+cast(conversationId as varchar(20))+char(92)+char(92)+ typeMessage + char(92)+char(92)+ messageId +''.''+
				case
					when typeMessage = ''video'' then ''mp4''
					when typeMessage = ''image'' then ''jpg''
					when typeMessage = ''audio'' then ''mp3''
					when typeMessage = ''file'' then (select substring(content, CHARINDEX(''.'',content)+1, len(content)))
					else '''' end
				end as [Url],
				case when typeMessage = ''location''
				then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) else '''' end as [Address],
				case when typeMessage = ''location''
				then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) else '''' end as [Lat],
				case when typeMessage = ''location''
				then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [Long],
				case when typeMessage = ''location''
				then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2) else '''' end as [Name],
				case when typeMessage = ''location''
				then ''https://www.google.com/maps/search/'' + (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) + '','' +
					(select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [LocationURL]
				from ccWAMessagesConversations where conversationId = @conversationId
				order by Timestamp asc
		END
		IF @option = 5 --get if conversation is reassigned
		BEGIN
			SELECT CASE WHEN EXISTS (
			SELECT *
			FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationship]
			WHERE conversationIdAfter = @conversationId
			)
			THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT) END
		END
    END



'
	EXEC(@sql)



		------------------------------- End El Santi ----------------------------------
		----------------------------------- GERARDO ----------------------------------



		 set @process = 'insert messageStatus 16 Agent Disconnected'
        set @sql = 'if not exists (select * from messageStatus where messageStatusId=16)
        begin
            SET IDENTITY_INSERT messageStatus ON

            insert into messageStatus (messageStatusId,name, description,isFinished) values (16, ''Disconnected'', ''Agent Disconnected'',1)			

			SET IDENTITY_INSERT messageStatus OFF
        end'

		   EXEC(@sql)

		set @process = 'K002079-81 K002079-81 insert messageStatus'
        set @sql = 'if not exists (select * from messageStatus where messageStatusId in(17,18))
        begin
			SET IDENTITY_INSERT messageStatus ON

            insert into messageStatus (messageStatusId,name, description,isFinished) values (17,''Close WhatsApp conversation'', ''Close WhatsApp conversation for window time'',1)
			insert into messageStatus (messageStatusId,name, description,isFinished) values (18,''Close conversation for error'', ''Close WhatsApp conversation for system error'',1)

			SET IDENTITY_INSERT messageStatus OFF

			DBCC CHECKIDENT (''messageStatus'', RESEED, 18)
        end'
        EXEC(@sql)

       
     


        
        set @process = 'K002068 SPAM CREATE TABLE ccWhatsAppSpam'
        set @sql = 'IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''ccWhatsAppSpam'')
        BEGIN
            CREATE TABLE [dbo].[ccWhatsAppSpam](
                [WhatsAppSpamId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
                [InboundId] [smallint] NOT NULL,
                [AgentId] [int],
                [ConversationId] [int],
                [Fecha] [datetime] DEFAULT GETDATE(),
                [NumberClient] [varchar](25) NOT NULL
            CONSTRAINT [pk_ccWhatsAppSpam_1] PRIMARY KEY CLUSTERED
            (
                [WhatsAppSpamId] ASC
            )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
            )ON [PRIMARY]

        END;'
        EXEC(@sql)


        set @process = 'K002079-81 Create procedure ccsp_WhatsAppInformation'
set @sql = 'ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformation]
@Option SMALLINT,
@InboundId SMALLINT = 0, 
@ConversationId INT = 0,
@AgentsAvailables INT = 0

AS
SET NOCOUNT ON

IF @InboundId IS NOT NULL BEGIN
    IF EXISTS (SELECT * FROM ccInbound WHERE Inbound_id = @InboundId AND chat = 5) BEGIN
        DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
        --DECLARE @Today SMALLDATETIME = ''2022-03-24''
        IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
            BEGIN
                IF EXISTS (SELECT * FROM ccWAAverageConversations 
                           WHERE InboundId = @InboundId 
                           AND (LastUpdate IS NULL
                           OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5) 
                           OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
                BEGIN 
                    -------------------------- ----------------------- Variable Declaration ---------------------------------------------------
        
                    DECLARE @AverageConversationTime INT = 0;
                    DECLARE @AverageDialogTime INT = 0;
                    DECLARE @AverageWaitingTime INT = 0;
                    DECLARE @MaximumWaitingTime INT = 0;
                    DECLARE @DefaultValue INT = (SELECT ISNULL(defaultServiceLevelParameter, 2) FROM contactMeanIn WHERE inboundId = @InboundId);
                    SET @DefaultValue = @DefaultValue * 60;
                    DECLARE @LessThanDefault INT = 0;
                    DECLARE @ReceivedConversations INT = 0;
                    DECLARE @ServiceLevel SMALLINT = 0;

                    --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

                    SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
                           @AverageDialogTime = ROUND(AVG(tChatting), 4),
                           @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
                           @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
                           @ReceivedConversations = COUNT(conversationDate),
                           @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
                    FROM ccWhatsAppConversations WHERE inboundId = @InboundId
                    AND requestDate >= @Today

                    SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END
    
                    ----------------------------------------------------- Update table --------------------------------------------------------
                    
                    IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId) 
                    BEGIN
                        UPDATE ccWAAverageConversations 
                        SET AverageConversationTime = @AverageConversationTime,
                            AverageDialogTime = @AverageDialogTime,
                            AverageWaitingTime = @AverageWaitingTime,
                            MaximumWaitingTime = @MaximumWaitingTime,
                            ServiceLevel = @ServiceLevel,
                            StatusUpdate = 0,
                            LastUpdate = GETDATE()
                        WHERE InboundId = @InboundId
                    END
                    ELSE
                    BEGIN
                        INSERT INTO ccWAAverageConversations (InboundId, AverageConversationTime, AverageDialogTime, 
                                                              AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
                        VALUES(@InboundId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                               @ServiceLevel, 0 , GETDATE()) 
                    END
                END
                --------------------------------- Results -----------------------------------

                SELECT ISNULL(AverageConversationTime, 0) AS AverageConversationTime,
                       ISNULL(AverageDialogTime, 0) AS AverageDialogTime, 
                       ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime, 
                       ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
                       ISNULL(ServiceLevel, 0) AS ServiceLevel
                FROM ccWAAverageConversations
                WHERE inboundId = @InboundId 
            END
        IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time, 
                       -- Average Queue/Waiting Time, and Service Level)
        BEGIN
            IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId) 
                BEGIN
                    UPDATE ccWAAverageConversations SET StatusUpdate = 1 
                    WHERE InboundId = @InboundId
                END
                ELSE
                BEGIN
                    INSERT INTO ccWAAverageConversations (InboundId, StatusUpdate)
                    VALUES(@InboundId, 1) 
                END
        END
        IF @Option = 3 -- Save time from accepted conversation by agent
        BEGIN
            IF @ConversationId IS NOT NULL
            BEGIN 
                UPDATE ccWhatsAppConversations SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
            END
        END
        IF @Option = 4 -- Get Disposition Information
        BEGIN
            SELECT disposition.Description AS DispositionName,
                   disposition.calif_id AS DispositionId,
                   COUNT(whatsConv.disposition) AS Total, 
                   disposition.GraphColor,
                   COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
            FROM ccWhatsAppConversations whatsConv  
            INNER JOIN cctipocalif disposition ON disposition.calif_id = whatsConv.disposition
            WHERE inboundId = @InboundId AND assignDate >= @Today
            GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor  
        END
        IF @Option = 5 -- Get Subdisposition Information
        BEGIN
            SELECT relation.calif_id AS DispositionId,
                   subDispositions.califSubDesc AS SubDispositionsName, 
                   COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
            FROM cctipoSubCalifRel relation
            INNER JOIN ccTipoCalifSub subDispositions ON subDispositions.califSub_id = relation.califSub_id
            INNER JOIN ccWhatsAppConversations whatsConv ON whatsConv.subDisposition = subDispositions.califSub_id
            WHERE whatsConv.inboundId = @InboundId AND 
                  whatsConv.assignDate >= @Today AND
                  relation.tipoSubRel = 1
            GROUP BY subDispositions.califSubDesc, relation.calif_id
        END
    END
END
IF @Option = 0 BEGIN-- Reset TABLES
    TRUNCATE TABLE ccWAAverageConversations;
    TRUNCATE TABLE ccLastMessageAgentByConversation;
END
RETURN(0)
SET NOCOUNT OFF'
        EXEC(@sql) 
        
        set @process = 'K002079-81 Create procedure ccsp_ConversationWASave'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
                                          , @conversationId     INT         = 0
                                          , @inboundId          SMALLINT    = NULL
                                          , @phoneACD           VARCHAR(50) = NULL
                                          , @clientId           VARCHAR(25) = NULL
                                          , @conversationStatus SMALLINT    = 0
                                          , @tChatting          FLOAT    = 0
                                          , @tWrapUp            SMALLINT    = 0
                                          , @finishedBy         TINYINT     = 0
                                          , @onQueue            BIT         = NULL
                                          , @tQueue             SMALLINT    = 0
                                          , @tTimeout           INT         = 0
                                          , @disposition        SMALLINT    = 0
                                          , @subDisposition     SMALLINT    = 0
                                          , @agentId            INT         = 0
                                          --VAR MESSAGES
                                          , @messageId          VARCHAR(50) = NULL
                                          , @messageIdUi        INT         = NULL
                                          , @clientNum          VARCHAR(15) = NULL
                                          , @vonageNum          VARCHAR(15) = NULL
                                          , @typeMessage        VARCHAR(25) = ''''
                                          , @content            NVARCHAR(MAX)= NULL
                                          , @timeStampMessage   DATETIME    = NULL
                                          , @timeStampMessageUTC DATETIME   = NULL
                                          , @originType         VARCHAR(15) = NULL
                                          , @currency           VARCHAR(10) = ''-''
                                          , @price              VARCHAR(10) = ''0.00''
                                          , @messageStatus      VARCHAR(15) = ''N/A''
                                          , @listConversationsIds   VARCHAR(MAX) = NULL 
AS
BEGIN
    DECLARE @isEndConversation BIT;
    DECLARE @meanContactTypeId SMALLINT;
    DECLARE @conversationIdNew INT;
    SET @meanContactTypeId = 1;
    SET NOCOUNT ON;

    IF @action = 1
    BEGIN --new Conversation
        IF NOT EXISTS
                      (SELECT A.conversationId conversationId FROM ccWhatsAppConversations A
                       WHERE A.conversationId = @conversationId
                      )
        BEGIN
            INSERT INTO [ccWhatsAppConversations]
            (inboundId
           , phoneACD
           , clientId
           , conversationStatus
           , tChatting
           , tWrapUp
           , finishedBy
           , onQueue
           , tQueue
           , tTimeout
           , disposition
           , subDisposition
           , agentId
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

            IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId) BEGIN
                SELECT @conversationId = SCOPE_IDENTITY();
                SELECT @conversationId AS ConversationId;
            END
            ELSE BEGIN
                
                declare @conversationIdTemporal     INT;
                SELECT @conversationIdTemporal = SCOPE_IDENTITY();
                EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
                SELECT 0 AS ConversationId;
            END;
            RETURN(0);
        END
        ELSE
        BEGIN
             INSERT INTO [ccWhatsAppConversations]
            (inboundId
           , phoneACD
           , clientId
           , conversationStatus
           , tChatting
           , tWrapUp
           , finishedBy
           , onQueue
           , tQueue
           , tTimeout
           , disposition
           , subDisposition
           , agentId
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
            SELECT @conversationIdNew = SCOPE_IDENTITY();
            
            INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
                                                             , conversationIdAfter)
                VALUES (@conversationId, @conversationIdNew);

            EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = 17

            SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship where conversationIdBefore = @conversationId;
            RETURN(0);
        END;
    END;

    IF @action = 2
    BEGIN --save conversation Times
        IF @listConversationsIds IS NOT NULL

        BEGIN --register desconnection by conversationID
            UPDATE ccWhatsAppConversations
                   SET
                       --tChatting = DATEDIFF(ss, conversationDate, GETDATE())
                      conversationStatus = @conversationStatus
                     , finishedBy = case when @conversationStatus = 10 then 2
                                         when @conversationStatus = 17 then 2
                                         when @conversationStatus = 18 then 2
                                         else 1 end
                     , tConversation = DATEDIFF(ss, requestDate, GETDATE())
                     ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else tQueue end
                     ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
            WHERE conversationId IN (SELECT value FROM fn_RIASplitDelimited(@listConversationsIds, '',''));
            
            DECLARE @counter INT;
            DECLARE @conversationIdTemp INT;
            DECLARE @TablaTemp TABLE(id INT, value varchar(7));
            insert into @TablaTemp SELECT * FROM fn_RIASplitDelimited(@listConversationsIds, '','');
            SET @counter = 1;

            WHILE (@counter <= (SELECT COUNT(*) FROM fn_RIASplitDelimited(@listConversationsIds, '','')))
            BEGIN  
               set @conversationIdTemp = (select value from @TablaTemp where id = @counter);
               IF @conversationStatus = 17 OR @conversationStatus = 18 BEGIN --Save conversation Ended by system
                    select @inboundId = inboundId from ccWhatsAppConversations where conversationId = @conversationIdTemp;
               END
               exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5
               SET @counter += 1;
            END
        END
        ELSE BEGIN
            UPDATE ccWhatsAppConversations
                   SET
                       --tChatting = DATEDIFF(ss, conversationDate, GETDATE())
                      conversationStatus = @conversationStatus
                     , finishedBy = case when @conversationStatus = 10 then 2
                                         when @conversationStatus = 17 then 2
                                         when @conversationStatus = 18 then 2
                                         else 1 end
                     , tConversation = DATEDIFF(ss, requestDate, GETDATE())
                     ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else tQueue end
                     ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
            WHERE conversationId = @conversationId;

            IF @conversationStatus = 13 BEGIN
                select @inboundId = inboundId, @agentId = agentId, @clientId = clientId from ccWhatsAppConversations where conversationId = @conversationId;
                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient)
                        VALUES (@inboundId, @agentId, @conversationId, @clientId);
                    END
            END
            exec ccsp_CreateNodeMultimedia @conversationId=@conversationId, @type=5
        END;

    END;

    IF @action = 3
    BEGIN --save conversation Status
        UPDATE ccWhatsAppConversations
               SET
                   --conversationDate = GETDATE(),
                   conversationStatus = @conversationStatus
        WHERE conversationId = @conversationId;
    END;

    IF @action = 4 BEGIN --save messages from conversation
        IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId)
            AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
        BEGIN
            IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS 
                (SELECT messageIdUi 
                  FROM ccWAMessagesConversations 
                 WHERE originType IN (''Agent'', ''Admin'') 
                   AND conversationId = @conversationId)
                BEGIN
                    UPDATE ccWhatsAppConversations 
                       SET FirstMessageAgent = @timeStampMessage 
                     WHERE conversationId = @conversationId;
                END
            
            INSERT INTO [ccWAMessagesConversations](
                                                messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
                                               (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
            SELECT @messageId=SCOPE_IDENTITY()
            SELECT @messageId as MessageId
            RETURN (0)
        END
        ELSE BEGIN
            SELECT 0 AS MessageId
            RETURN (0)
        END
    END;

    IF @action = 5
    BEGIN --save onQueue
        UPDATE ccWhatsAppConversations
               SET onQueue = 1
        WHERE conversationId = @conversationId;
    END;

    IF @action = 6
    BEGIN --save agent, assigdate and tqueue
        IF ((SELECT A.agentId AS idAgent FROM ccWhatsAppConversations A where A.conversationId = @conversationId) IS NULL 
            OR (SELECT A.agentId AS idAgent FROM ccWhatsAppConversations A where A.conversationId = @conversationId) = 0)
        BEGIN
            UPDATE ccWhatsAppConversations
                   SET agentId = @agentId,
                   assignDate = getdate(),
                   conversationStatus = @conversationStatus
            WHERE conversationId = @conversationId;

            UPDATE ccWhatsAppConversations
                   SET tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
            WHERE conversationId = @conversationId;
            SELECT conversationId FROM ccWhatsAppConversations WHERE conversationId = @conversationId;
        END
    END;

    IF @action = 7
    BEGIN --update price message
        UPDATE ccWAMessagesConversations
               SET price = @price,
                   currency = @currency
        WHERE messageId = @messageId;
    END;

    IF @action = 8
    BEGIN --update status message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversations
                   SET messageStatus = @messageStatus
            WHERE messageId = @messageId;
        END;
    END;

    IF @action = 9
    BEGIN --Save last message time by conversationID
        IF (SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) IS NULL BEGIN
            INSERT INTO ccLastMessageAgentByConversation (conversationId) VALUES (@conversationId)
        END;
        ELSE
            BEGIN
                UPDATE ccLastMessageAgentByConversation
                   SET timeStampLastMessageAgent = getDate()
                WHERE conversationId = @conversationId;
            END;
    END;

    IF @action = 10
    BEGIN --drop register by conversationID
        DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
    END;

    IF @action = 11
    BEGIN --register desconnection by conversationID
        UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
    END;
END;'
        EXEC(@sql) 

        		----------------------------------- GERARDO ----------------------------------
            ----------------------------------- IVAN ----------------------------------

        set @process = 'CW-6459 Drop ccsp_GalateaAdminCampaigns'
        set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminCampaigns'')
              BEGIN
                  DROP PROCEDURE ccsp_GalateaAdminCampaigns;
              END'
        EXEC(@sql)

        set @process = 'CW-6459 Se modifica ccsp_GalateaAdminCampaigns para obtener agentes en estado de dialogo de whats'
        set @sql = '
        CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS      SMALLINT, 
                                                   @CampType AS    SMALLINT = 0, 
                                                   @WorkgroupId AS INT      = 0, 
                                                   @Id AS          INT      = 0, 
                                                   @AdminId AS     SMALLINT = 0, 
                                                   @PinUpdate AS   SMALLINT = 0, 
                                                   @LoadId AS      INT      = 0, 
                                                   @Type AS        SMALLINT = 0
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
                                        RAISERROR(''ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado'', 18, 1);
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
                                        RAISERROR(''ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado'', 18, 1);
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
                                               CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, CAST(graph.graphic_id AS INT) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area
                                        FROM ccCamps camps
                                             LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                                             LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
                                        WHERE camps.cam_id = @Id
                                               ORDER BY camps.cam_descripcion ASC;
                                END;
                                ELSE
                                    BEGIN
                                        RAISERROR(''ERROR. No existe campa?as de salida con el id especificado'', 18, 1);
                                END;
                        END;
                        IF @CampType = 0 -- Campaigns In (ACD)
                            BEGIN
                                IF @Id IS NOT NULL
                                    BEGIN
                                        SELECT DISTINCT 
                                               CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, CAST(graph.graphic_id AS INT) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
                                        FROM ccInbound inb
                                             LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                                             LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                                        WHERE inb.Inbound_id = @Id
                                               ORDER BY inb.descripcion ASC;
                                END;
                                ELSE
                                    BEGIN
                                        RAISERROR(''ERROR. No existe campa?as de entrada con el id especificado'', 18, 1);
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
                                RAISERROR(''ERROR. No existe la campa?as de entrada con el id especificado'', 18, 1);
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
                                RAISERROR(''ERROR. La campa?as o administrador no existen'', 18, 1);
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
                                RAISERROR(''ERROR. La campa?as con el id seleccionado no existe'', 18, 1);
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
                                RAISERROR(''ERROR. No existe una campa?a con el id especificado'', 18, 1);
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
              DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT);
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
              INNER JOIN ccInbound inbound ON Inbound_id = campPerWg.IdCampEsp 
              AND C.TipoUser_id = 1
              WHERE campPerWg.Tipo = @CampType
              AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
              
              WITH lastState AS (
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

              DECLARE @MultimediaType SMALLINT = (SELECT CASE WHEN @CampType = 1 THEN -1 ELSE meanContactTypeId END
                                FROM contactMeanIn WHERE inboundId = @Id)

              DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes

              INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
              (CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType
               THEN @CampType ELSE null END) AS isCampDialog 
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
                       WHEN A.CurrentState IN (6, 34) AND A.CampId != C.IdCampEsp THEN 1 ELSE NULL END) AS notReady,
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
                            FROM ccUsers_Roles
                            WHERE User_id = @AdminId
                                  AND Rol_id = 7
                        )
                            BEGIN
                    print ''xxxx SIn Super''
                                ;WITH wgId
                                     AS (SELECT IDWG
                                         FROM ccRIAWorkGroupUsers
                                         WHERE user_id = @AdminId)
                                     SELECT DISTINCT 
                                            CAST(IdCampEsp AS INT) AS Id
                                     FROM ccRIACampEspWG A
                                          INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                             AND A.Tipo = @CampType;
                        END;
                        ELSE
                            BEGIN
                  print ''xxxx Super''
                  IF @CampType = 1
                    BEGIN
                      SELECT DISTINCT 
                           CAST(cam_id AS INT) AS Id
                      FROM ccCamps where IDArea IS NOT NULL
                    END
                  ELSE
                    BEGIN 
                      SELECT DISTINCT 
                           CAST(Inbound_id AS INT) AS Id
                      FROM ccInbound where IDArea IS NOT NULL
                    END
                        END;
                        RETURN 0;
                END;
                IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
                    BEGIN
                        IF @CampType = 1 -- Campaigns Out
                            BEGIN
                                SELECT DISTINCT 
                                       CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, CAST(graph.graphic_id AS INT) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area
                                FROM ccCamps camps
                                     INNER JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                                     INNER JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
                                       --WHERE camps.cam_id = @Id
                                       ORDER BY camps.cam_descripcion ASC;
                        END;
                        ELSE
                            BEGIN
                                SELECT DISTINCT 
                                       CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, CAST(graph.graphic_id AS INT) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
                                FROM ccInbound inb
                                     INNER JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                                     INNER JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                                       ORDER BY inb.descripcion ASC;
                        END;
                        RETURN 0;
                END;
            END;'
        EXEC(@sql)
            ----------------------------------- IVAN ----------------------------------


		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
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


