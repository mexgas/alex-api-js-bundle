/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 24
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

    set @process = 'CW-5828 ccsp_GalateaLoadUsersForManagement - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaLoadUsersForManagement'')
            begin
          DROP PROCEDURE ccsp_GalateaLoadUsersForManagement;
            end'
    EXEC(@sql)

    set @process = 'CW-5828 ccsp_GalateaLoadUsersForManagement '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
 @option SMALLINT,
 @AreaId SMALLINT,
 @UserType INT,
 @Username VARCHAR(200)=null,
 @userId INT =0
as

--Obtiene el idioma de de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

IF @option = 1 --Agentes/supervisores de un Area
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
  ORDER BY LOGIN, Nombres, ApellidoPaterno,Sexo, User_id

  RETURN (0)
END

IF @option = 2 -- obtiene Agente o supervisor en base a su nombre de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE Login=@Username

  RETURN (0)
END

IF @option = 3 -- obtiene Agente o supervisor en base a su ID de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE user_id=@userId

  RETURN (0)
END


IF @option = 4 -- supervisores en Area/Sistema
BEGIN
	DECLARE @Admins TABLE (UserId smallint, Username varchar(50), Names varchar(50), LastName varchar(50), OptionalExtraName varchar(50), AreaId smallint, primary key(UserId))
	INSERT INTO @Admins
	SELECT User_id as UserId,
	LOGIN as Username,
	Nombres as Names,
	CASE
	  WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
	  ELSE isnull(ApellidoPaterno, '''')
	END as LastName,

	CASE
	  WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
	  ELSE isnull(ApellidoMaterno, '''')
	END as OptionalExtraName,

	isnull(IDArea, 0) as AreaId
	FROM ccusers
	WHERE TipoUser_id = 2 AND STATUS = 1


	IF NOT EXISTS(SELECT * FROM ccUsers_Roles WHERE User_id=@userId and Rol_id=7) BEGIN
		SELECT UserId, Username, Names, LastName, OptionalExtraName
		FROM @Admins
		WHERE AreaId = (SELECT IDArea FROM ccUsers WHERE User_id=@userId)
		ORDER BY Username, Names, LastName, UserId
	END
	ELSE BEGIN
		SELECT UserId, Username, Names, LastName, OptionalExtraName
		FROM @Admins
		ORDER BY Username, Names, LastName, UserId
	END

  RETURN (0)
END'
    EXEC(@sql)

    set @process = 'CW-5828, CW-5841 Se quita el SP ccsp_GalateaChangeHistory si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaChangeHistory'')
            begin
          DROP PROCEDURE ccsp_GalateaChangeHistory;
            end'
    EXEC(@sql)

    set @process = 'CW-5828, CW-5841 Se crea SP ccsp_GalateaChangeHistory'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaChangeHistory]
	@option TINYINT,
	@loginLst VARCHAR(max) = NULL,
	@moduleWithOperation varchar(max) = NULL,
	@operationDateIni SMALLDATETIME = NULL,
	@operationDateFin SMALLDATETIME = NULL,
	@top INT = 0
	AS
	SET NOCOUNT ON

	DECLARE @lang TINYINT

	SELECT @lang = valor
	FROM ccsettings
	WHERE setting_id = 27

	IF @option = 1 -- Catalogo de modulos
	BEGIN
		WITH Catalog AS(
		SELECT cast(m.module_id as int) module_id, cast(o.operationType as int) operationType, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion) + 1, len(m.descripcion)) END AS mDescripcion, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion) + 1, len(o.descripcion)) END AS oDescripcion
		FROM ccRIALog_Operation o WITH (INDEX (IX_ccRIALog_Operation))
		JOIN ccRIALog_Cat_Relation r ON o.operationType = r.operationType
		JOIN ccRIALog_Module m WITH (INDEX (IX_ccRIALog_Module)) ON r.module_id = m.module_id

		UNION

		SELECT 0, - 1, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, '' - ''

		UNION

		SELECT 0, 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END

		UNION

		SELECT cast(module_id as int) module_id, 0, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
		FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))

		UNION

		SELECT cast(module_id as int) module_id, - 1 , CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, '' - ''
		FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module)))

		SELECT module_id,operationType,mDescripcion,oDescripcion FROM Catalog
		WHERE module_id not in(5,8,14,21,22,25,32,33,36,37,44,53,57,58,59,60,42)
		AND operationType not in(6,15,51,58,36,46,44,45,59,12,8,7,55,54,33)
		ORDER BY mDescripcion, oDescripcion

		RETURN (0)
	END

	IF @option = 2 -- Muestra informacion por filtros
	BEGIN

		declare @sql as nvarchar(max)
		DECLARE @table TABLE(id int,value varchar(max))
		declare @id int
		declare @moduleId varchar(max)
		declare @operationLst varchar(max)
		declare @query varchar(max) = '' and (''
		declare @value varchar(max)
		declare @first int = 1
		declare @pos int

		insert into @table select * from dbo.fn_RIASplitDelimited(cast(isnull(@moduleWithOperation,'''') as varchar(max)), '','')
		while exists(select * from @table)
		begin
			select top 1 @id = id, @value = value from @table
			set @pos = charindex('':'', @value)
			if(@pos <> 0)
			begin
				set @moduleId = substring(@value, 1, @pos-1)
				set @operationLst = replace(substring(@value, @pos+1, len(@value)), ''-'', '','')
				if(@first = 1)
				begin
					set @query = @query + ''l.module_id='' + @moduleId + '' and l.operationType in ('' + @operationLst + '')''
					set @first = 0
				end
				else
				begin
					set @query = @query + '' or l.module_id='' + @moduleId + '' and l.operationType in ('' + @operationLst + '')''
				end
			end

			delete @table where id = @id
		end
		set @query = @query + '')''


		SET ROWCOUNT @top

		set @sql =
		''DECLARE @tableLogin TABLE(id int,value varchar(255))
		insert into @tableLogin  select * from dbo.fn_RIASplitDelimited('''''' + cast(isnull(@loginLst,'''') as varchar(max)) + '''''','''','''')

		SELECT L.log_id, L.areaName, L.operationDate,
		CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''''|'''', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''''|'''', o.descripcion) + 1, len(o.descripcion)) END operationType,
		L.LOGIN,
		CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''''|'''', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''''|'''', m.descripcion) + 1, len(m.descripcion)) END module_id,
		CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target,
		CASE WHEN v.valueT IS NULL THEN L.value ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN v.es WHEN 2 THEN v.pt ELSE v.en END END AS value
		FROM CCRIALOG L
		JOIN ccRIALog_Module M WITH (INDEX (IX_ccRIALog_Module)) ON L.module_id = M.module_id
		JOIN ccRIALog_Operation O WITH (INDEX (IX_ccRIALog_Operation)) ON L.operationType = O.operationType
		LEFT JOIN targetRecord t ON t.targetT = L.target
		LEFT JOIN valueRecord v ON v.valueT = L.value
		WHERE 1=1 ''
		+
		case isnull(@loginLst, '''') when '''' then '''' else
		'' AND L.LOGIN in (select value from @tableLogin) ''
		END
		+
		case isnull(@moduleWithOperation, '''') when '''' then '''' else
		@query
		end
		+ case ISNULL(@operationDateIni, '''') when '''' then '''' else
		''AND L.operationDate >= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull('''''' + convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, -1, '''''' + convert(varchar(19), @operationDateIni, 121) + '''''') ELSE L.operationDate END ''
		+ '' AND L.operationDate <= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull(''''''+ convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, 1, '''''' + convert(varchar(19), @operationDateFin, 121) + '''''') ELSE L.operationDate END''
		end
		+
		'' ORDER BY L.operationDate DESC''
		execute sp_executesql @sql
		--print @sql
	END


	SET NOCOUNT OFF'
    EXEC(@sql)


set @process = 'CW-5837 Se quita el SP ccspGalatea_Finder si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccspGalatea_Finder'')
            begin
          DROP PROCEDURE ccspGalatea_Finder;
            end'
    EXEC(@sql)

    set @process = 'CW-5837 se crea SP ccspGalatea_Finder'
    set @sql = '
CREATE PROCEDURE [dbo].[ccspGalatea_Finder] @action       INT
                                         , @userId       INT    = 0
                                         , @conversationId BIGINT = 0
AS
     IF @action = 1
     BEGIN--trae el nombre de la base de datos en BX
         SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value]
              , CAST(WGCam.Tipo AS INT) + 1 AS callType
              , c.cam_descripcion AS label FROM ccRIAWorkGroupUsers Wguser
                                                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                                                INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
                                                                        AND WGCam.Tipo = 1
         WHERE Wguser.User_id = @userId
         UNION
         SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value]
              , CAST(WGCam.Tipo AS INT) + 1 AS callType
              , inb.descripcion AS label FROM ccRIAWorkGroupUsers Wguser
                                              INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                                              INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
                                                                          AND WGCam.Tipo = 0
         WHERE Wguser.User_id = @userId;
     END;
     ELSE
         IF @action = 2
         BEGIN
             WITH WgId
                  AS (SELECT IDWG FROM ccRIAWorkGroupUsers Wguser WHERE Wguser.User_id = @userId)
                  SELECT DISTINCT
                         CAST(Wguser.User_id AS INT) AS [Value]
                       , ccUsers.Login AS label FROM ccRIAWorkGroupUsers Wguser
                                                     INNER JOIN WgId ON Wguser.IDWG = WgId.IDWG
                                                     INNER JOIN ccUsers ON ccUsers.User_id = Wguser.User_id
                                                                           AND TipoUser_id = 1;
         END;
         ELSE
             IF @action = 3
             BEGIN--Informacion de la conversacion de whatsApp
                 SELECT A.ConversationID
                      , A.inboundId AS AcdId
					  , isnull(graph.graphic_id,1) as GraphicId
                      , A.phoneACD AS PhoneAcd
                      , A.clientId AS PhoneClient
                      , ISNULL(B.descripcion, ''N/A'') AS AcdName
                      , ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition
                      , ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition
                      , ISNULL(conversationDate, requestDate) DateStart
					  , ISNULL(A.agentId,0) AgentID
					  FROM ccWhatsAppConversations A
                                                                             LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
                                                                             LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                                                                             LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
																			 left join ccRIAInboundGraph graph on graph.Inbound_id=A.inboundId
                 WHERE A.conversationId = @conversationId;

             END;'
    EXEC(@sql)

	set @process = 'CW-5830 Se quita el SP ccsp_GalateaAdminGetCampaignsPerAgent si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminGetCampaignsPerAgent'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminGetCampaignsPerAgent;
            end'
    EXEC(@sql)

    set @process = 'CW-5830 se crea SP ccsp_GalateaAdminGetCampaignsPerAgent'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetCampaignsPerAgent]
				@agent_id INT
				AS
				BEGIN
				SELECT DISTINCT 0 CampType, a1.inbound_id AS CampId, a1.descripcion AS Description, a3.frame AS Frame
					FROM ccinbound a1
					JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccInboundAgentes a4 ON a1.inbound_id = a4.inbound_id
					WHERE a3.type_id = 1 AND a4.user_id = @agent_id

					union

				SELECT DISTINCT 1 CampType, a1.cam_id AS CampId, a1.cam_descripcion AS Description, a3.frame AS Frame
					FROM ccCamps a1
					JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccCampsAgente a4 ON a1.cam_id = a4.cam_id
					WHERE a3.type_id = 1 AND a4.user_id = @agent_id
				END'
    EXEC(@sql)

	set @process = 'CW-5830 Se quita el SP ccsp_GalateaAdminGetCampaignSubDispositions si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminGetCampaignSubDispositions'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminGetCampaignSubDispositions;
            end'
    EXEC(@sql)

    set @process = 'CW-5845 se crea SP ccsp_GalateaAdminGetCampaignSubDispositions'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetCampaignSubDispositions]
				@camp_id int,@type int, @agent_id int
				AS
				BEGIN
				IF @type=0
					begin
						select c2.Description,
						case when c3.califSubDesc is not null
							then c3.califSubDesc else ''No Subdisposition'' end as SubCalifDescription,
						count(*) Total from ccCallsIn c1
						inner join ccTipoCalif c2 on c1.calif_id=c2.calif_id
						left join ccTipoCalifSub c3 on c1.califSub_id=c3.califSub_id
						where cal_inicio > convert(varchar(11), getdate(), 101)
						AND User_id=@agent_id AND statusCall_id=13
						AND Inbound_id=@camp_id AND c1.califSub_id!=-1
						group by c2.Description,c3.califSubDesc
					END
				IF @type=1
					BEGIN
						select c2.Description,
						case when c3.califSubDesc is not null
							then c3.califSubDesc else ''No Subdisposition'' end as SubCalifDescription,
						count(*) Total from ccoCallsOut c1
						inner join ccTipoCalifOUT c2 on c1.calif_id=c2.calif_id
						left join ccTipoCalifSubOUT c3 on c1.califSub_id=c3.califSub_id
						where cal_inicio > convert(varchar(11), getdate(), 101)
						AND User_id=@agent_id AND statusCall_id=13
						AND cam_id=@camp_id AND c1.califSub_id!=-1
						group by c2.Description,c3.califSubDesc
					END
				END'
    EXEC(@sql)

    set @process = 'CW-5870 Se agrega columna messageStatus'
    set @sql = '
    IF not exists (SELECT * FROM sys.columns WHERE name = N''messageStatus'' AND Object_ID = Object_ID(N''ccWAMessagesConversations''))
    BEGIN
        ALTER TABLE ccWAMessagesConversations ADD messageStatus VARCHAR(15) NULL;
    END'
    EXEC(@sql)

    set @process = 'CW-5870 Drop procedure ccsp_ConversationWASave'
    set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_ConversationWASave'')
	            BEGIN
	          		DROP PROCEDURE ccsp_ConversationWASave;
	            END'
    EXEC(@sql)

    set @process = 'CW-5870 update procedure ccsp_ConversationWASave'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
                                              , @conversationId     INT         = 0
                                              , @inboundId          SMALLINT    = NULL
                                              , @phoneACD           VARCHAR(50) = NULL
                                              , @clientId           VARCHAR(25) = NULL
                                              , @conversationStatus SMALLINT    = 0
                                              , @tChatting          SMALLINT    = 0
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
											  , @messageIdUi        INT			= NULL
											  , @clientNum			VARCHAR(15) = NULL
											  , @vonageNum			VARCHAR(15) = NULL
											  , @typeMessage		VARCHAR(25) = ''''
											  , @content			VARCHAR(MAX)= NULL
											  , @timeStampMessage   DATETIME	= NULL
											  , @timeStampMessageUTC DATETIME	= NULL
											  , @originType         VARCHAR(15) = NULL
											  , @currency			VARCHAR(10) = ''-''
											  ,	@price				VARCHAR(10) = ''0.00''
											  , @messageStatus		VARCHAR(15) = ''N/A''
	AS
	BEGIN
	    DECLARE @isEndConversation BIT;
	    DECLARE @meanContactTypeId SMALLINT;

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
	            SELECT @conversationId = SCOPE_IDENTITY();
	            SELECT @conversationId AS ConversationId;
	            RETURN(0);
	        END;
	        ELSE
	        BEGIN
	            SELECT 0 AS ConversationId;
	            RETURN(0);
	        END;
	    END;

	    IF @action = 2
	    BEGIN --save conversation Times
	        UPDATE ccWhatsAppConversations
	               SET
	                   tChatting = DATEDIFF(ss, conversationDate, GETDATE())
	                 , conversationStatus = @conversationStatus
	                 , finishedBy = case when @conversationStatus = 10 then 2 else 1 end
	                 , tConversation = DATEDIFF(ss, requestDate, GETDATE())
					 ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else tQueue end
					 ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
	        WHERE conversationId = @conversationId;


			exec ccsp_CreateNodeMultimedia @conversationId=@conversationId, @type=5

	    END;

	    IF @action = 3
	    BEGIN --save conversation Status
	        UPDATE ccWhatsAppConversations
	               SET
	                   conversationDate = GETDATE()
	                 , conversationStatus = @conversationStatus
	        WHERE conversationId = @conversationId;
	    END;

		IF @action = 4 BEGIN --save messages from conversation
			IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId)
				AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
			BEGIN
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
	        UPDATE ccWhatsAppConversations
	               SET agentId = @agentId,
				   assignDate = getdate(),
				   conversationStatus = @conversationStatus
	        WHERE conversationId = @conversationId;

			UPDATE ccWhatsAppConversations
	               SET tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
	        WHERE conversationId = @conversationId;
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
	END;'
    EXEC(@sql)

	set @process = 'CW-5949 cambio de tipo de dato columna Content'
    set @sql = 'if(SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=''ccWAMessagesConversations'' and COLUMN_NAME = ''content'') <> ''nvarchar''
			begin
			ALTER TABLE ccWAMessagesConversations
			ALTER COLUMN content nvarchar(max);
			end'
    EXEC(@sql)


    set @process = 'CW-5949 ccsp_ConversationWASave - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ConversationWASave'')
            begin
          DROP PROCEDURE ccsp_ConversationWASave;
            end'
    EXEC(@sql)

    set @process = 'CW-5949 ccsp_ConversationWASave '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
                                              , @conversationId     INT         = 0
                                              , @inboundId          SMALLINT    = NULL
                                              , @phoneACD           VARCHAR(50) = NULL
                                              , @clientId           VARCHAR(25) = NULL
                                              , @conversationStatus SMALLINT    = 0
                                              , @tChatting          SMALLINT    = 0
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
											  , @messageIdUi        INT			= NULL
											  , @clientNum			VARCHAR(15) = NULL
											  , @vonageNum			VARCHAR(15) = NULL
											  , @typeMessage		VARCHAR(25) = ''''
											  , @content			NVARCHAR(MAX)= NULL
											  , @timeStampMessage   DATETIME	= NULL
											  , @timeStampMessageUTC DATETIME	= NULL
											  , @originType         VARCHAR(15) = NULL
											  , @currency			VARCHAR(10) = ''-''
											  ,	@price				VARCHAR(10) = ''0.00''
											  , @messageStatus		VARCHAR(15) = ''N/A''
	AS
	BEGIN
	    DECLARE @isEndConversation BIT;
	    DECLARE @meanContactTypeId SMALLINT;

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
	            SELECT @conversationId = SCOPE_IDENTITY();
	            SELECT @conversationId AS ConversationId;
	            RETURN(0);
	        END;
	        ELSE
	        BEGIN
	            SELECT 0 AS ConversationId;
	            RETURN(0);
	        END;
	    END;

	    IF @action = 2
	    BEGIN --save conversation Times
	        UPDATE ccWhatsAppConversations
	               SET
	                   tChatting = DATEDIFF(ss, conversationDate, GETDATE())
	                 , conversationStatus = @conversationStatus
	                 , finishedBy = case when @conversationStatus = 10 then 2 else 1 end
	                 , tConversation = DATEDIFF(ss, requestDate, GETDATE())
					 ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else tQueue end
					 ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
	        WHERE conversationId = @conversationId;


			exec ccsp_CreateNodeMultimedia @conversationId=@conversationId, @type=5

	    END;

	    IF @action = 3
	    BEGIN --save conversation Status
	        UPDATE ccWhatsAppConversations
	               SET
	                   conversationDate = GETDATE()
	                 , conversationStatus = @conversationStatus
	        WHERE conversationId = @conversationId;
	    END;

		IF @action = 4 BEGIN --save messages from conversation
			IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId)
				AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
			BEGIN
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
	        UPDATE ccWhatsAppConversations
	               SET agentId = @agentId,
				   assignDate = getdate(),
				   conversationStatus = @conversationStatus
	        WHERE conversationId = @conversationId;

			UPDATE ccWhatsAppConversations
	               SET tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
	        WHERE conversationId = @conversationId;
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
	END;'
    EXEC(@sql)


set @process = 'CW-5949 ccsp_MultimediaCommon - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_MultimediaCommon'')
            begin
          DROP PROCEDURE ccsp_MultimediaCommon;
            end'
    EXEC(@sql)

    set @process = 'CW-5949 ccsp_MultimediaCommon '
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
					   INNER JOIN  contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId
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
						i.ShowCalifWnd
					FROM  ccInbound i
						INNER JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId
						INNER JOIN ccWhatsAppConversations c ON (c.inboundId = i.Inbound_id and c.conversationId = @conversationId)
						INNER JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
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
					then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 5),'':'') where id=2) +
					      (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 5),'':'') where id=3) else '''' end as [LocationURL]
				 from ccWAMessagesConversations where conversationId = @conversationId and messageId in (select idMessage from @mensajes)

			End
		END'
    EXEC(@sql)

		set @process = 'CW-5723 AgentCheckCampsActive  - Se quita el SP si ya existe'
				set @sql = 'if exists (select * from sys.procedures where name = N''AgentCheckCampsActive '')
								begin
									DROP PROCEDURE AgentCheckCampsActive ;
								end'
				EXEC(@sql)

		set @process = 'CW-5723 AgentCheckCampsActive  - Se añade SP para validar que la campaña pertenezca a un área'
			set @sql = 'CREATE PROCEDURE [dbo].[AgentCheckCampsActive]
					@cam_id as smallint,
					@user_id as smallint,
					@forceManualCall as tinyint = 0
					AS

					declare @isValidCall as int
					declare @timeZoneRule as int
					declare @idArea as int

					select @isValidCall = count(*)from ccCampsAgente with(nolock) where cam_id = @cam_id and user_id = @user_id
					select @idArea = IDArea from ccCamps with(nolock) where cam_id = @cam_id
					select @timeZoneRule = 0
					if @idArea is not NULL
						begin
							select @isValidCall = cam_ModoManual, @timeZoneRule = timeZoneRule, @idArea = 1
							from ccCamps with(nolock) where cam_id = @cam_id
							end

							else if @idArea is null
							begin
							select  @isValidCall = cam_ModoManual, @timeZoneRule = timeZoneRule, @idArea = 0
							from ccCamps with(nolock) where cam_id = @cam_id
							end

						select @isValidCall as Validation, @timeZoneRule as TimeZoneRule, @idArea as Active'
			EXEC(@sql)


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
