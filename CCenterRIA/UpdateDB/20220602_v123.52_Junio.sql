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
          answerTimeoutClient = ISNULL(@muTimeOutClient, 30),
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
							UPDATE ccRIAMultimediaUsersPermissions SET AllowUnassign = @permissionValue
							WHERE AgentId IN (SELECT AgentId FROM @AgentIdsTemp)
						END
						IF @permissionName = ''AllowSpam''
						BEGIN 
							UPDATE ccRIAMultimediaUsersPermissions SET AllowSpam = @permissionValue
							WHERE AgentId IN (SELECT AgentId FROM @AgentIdsTemp)
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

        set @process = 'CW-6919 Drop procedure ccsp_MultimediaCommon'
        set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_MultimediaCommon'')
                    BEGIN 
                        DROP PROCEDURE ccsp_MultimediaCommon
                    END'
        EXEC(@sql)

        set @process = 'CW-6919 Create procedure ccsp_MultimediaCommon'
        set @sql = 'CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon]
                    @Option AS SMALLINT,
                    @inboundId AS SMALLINT = 0,
                    @conversationId AS INT = 0,
                    @ServiceType AS SMALLINT = 0,
                    @status as SMALLINT =0,
                    @messagesList as varchar(max) = ''''
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
                declare @pathFile as varchar(max)
                declare @filetype as varchar(5)

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
                    case when typeMessage = ''text'' or typeMessage = ''location'' then '' else @pathFile +char(92)+cast(conversationId/1000 as varchar(30))+char(92)+cast(conversationId as varchar(20))+char(92)+ typeMessage + char(92)+ messageId +''.''+
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
                    then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) else '' end as [Lat],
                    case when typeMessage = ''location''
                    then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '' end as [Long],
                    case when typeMessage = ''location''
                    then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2) else '' end as [Name],
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
        END'
		EXEC(@sql)

        set @process = 'CW-6688 Version Bd 123.52 update ccsp_MultimediaCommon'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_MultimediaCommon]
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
                        when typeMessage = ''file'' then (select substring(content, CHARINDEX('.',content)+1, len(content)))
                        else '' end
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

		------------------------------- End El Santi ----------------------------------

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


