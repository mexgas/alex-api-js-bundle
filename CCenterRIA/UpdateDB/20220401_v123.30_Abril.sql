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

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-Roles permiso gestionar chats'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10015)
    begin
        insert into ccPermissions values (10015, ''Gestionar chat con agentes'', ''RolesPermissionChatManagement'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar chats'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10015)
    begin
        insert into ccRoles_Permissions values(1,10015)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar llamada'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10016)
    begin
        insert into ccPermissions values (10016, ''Gestionar monitoreo de llamada'', ''RolesPermissionCallMonitoring'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar llamada'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10016)
    begin
        insert into ccRoles_Permissions values(1,10016)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso solo monitoreo'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10017)
    begin
        insert into ccPermissions values (10017, ''Solo monitoreo'', ''RolesPermissionMonitoring'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol solo monitoreo'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10017)
    begin
        insert into ccRoles_Permissions values(1,10017)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar formatos'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10018)
    begin
        insert into ccPermissions values (10018, ''Gestionar formatos de evaluacion'', ''RolesPermissionFormsManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar formatos'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10018)
    begin
        insert into ccRoles_Permissions values(1,10018)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar historial'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10019)
    begin
        insert into ccPermissions values (10019, ''Gestionar historial de actividad'', ''RolesPermissionActivityLogManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar historial'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10019)
    begin
        insert into ccRoles_Permissions values(1,10019)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar autoinicio'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10020)
    begin
        insert into ccPermissions values (10020, ''Gestionar inicio automatico'', ''RolesPermissionAutostartManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar autoinicio'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10020)
    begin
        insert into ccRoles_Permissions values(1,10020)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar calificaciones'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10021)
    begin
        insert into ccPermissions values (10021, ''Gestionar calificaciones'', ''RolesPermissionDispositionManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar calificaciones'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10021)
    begin
        insert into ccRoles_Permissions values(1,10021)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar marcacion'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10022)
    begin
        insert into ccPermissions values (10022, ''Gestionar factor de marcacion fijo'', ''RolesPermissionDialFactorManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar marcacion'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10022)
    begin
        insert into ccRoles_Permissions values(1,10022)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar ani local'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10023)
    begin
        insert into ccPermissions values (10023, ''Gestionar lista de ANI local'', ''RolesPermissionANIListManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rolgestionar ani local'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10023)
    begin
        insert into ccRoles_Permissions values(1,10023)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar dnis'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10024)
    begin
        insert into ccPermissions values (10024, ''Gestionar numeros DNIS'', ''RolesPermissionDnisNumManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar dnis'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10024)
    begin
        insert into ccRoles_Permissions values(1,10024)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar listas negras'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10025)
    begin
        insert into ccPermissions values (10025, ''Gestionar listas negras'', ''RolesPermissionBlacklistManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar listas negras'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10025)
    begin
        insert into ccRoles_Permissions values(1,10025)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso acceder a reporteador'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10026)
    begin
        insert into ccPermissions values (10026, ''Acceder a reporteador'', ''RolesPermissionReporter'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol acceder a reporteador'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10026)
    begin
        insert into ccRoles_Permissions values(1,10026)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso acceder a buscador'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10027)
    begin
        insert into ccPermissions values (10027, ''Acceder a buscador'', ''RolesPermissionFinder'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol acceder a buscador'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10027)
    begin
        insert into ccRoles_Permissions values(1,10027)
    end'
    EXEC(@sql)
	

    set @process = 'KR020000 Se borra job si existe de callbacks por campaĆ±a'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_OUTGetCB_Distribucion'')
    begin
        DROP PROCEDURE ccsp_OUTGetCB_Distribucion;
    end'
    EXEC(@sql)

    set @process = 'KR020000 Se actualiza job de callbacks por campaĆ±a'
    set @sql = '
        CREATE PROCEDURE [dbo].[ccsp_OUTGetCB_Distribucion]
        @CAMPID as int,
        @Tipo int=0
        as
        set nocount on
        declare @start datetime, @end datetime, @final datetime

        select @end=CONVERT(datetime,CONVERT(varchar(11),GETDATE(),121)+''00:00'',121)
        select @start=DATEADD(d,-1,@end)
        select @final=DATEADD(d,+1,@end)

        if @Tipo=0
        begin
            select count(case when(cal_fechaDial<@end) then 1 else null end) as Antes,
            count(case when(cal_fechaDial between @end and @final) then 1 else null end) as Hoy,
            count(case when(cal_fechaDial>@final) then 1 else null end) as Despues,
            count(callout_id) as Todos
            from ccoWorkingTable where cam_id = @CAMPID and cal_status=1
            return(0)
        end

        select datepart(hh, cal_fechaDial) as Hora, count(callout_id) as CB
            from ccoWorkingTable
            where cam_id=@CAMPID and cal_fechaDial BETWEEN @end AND @final and cal_status=1
            group by datepart(hh, cal_fechaDial)
            order by Hora
        return(0)'
    EXEC(@sql)

    set @process = 'CW-Settings permiso tiempo de consulta de callbacks por hora'
    set @sql = 'if not exists (select * from ccSettings where setting_id=231)
    begin
        insert into ccSettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values (231,5,
        ''Tiempo de consulta Callbacks por hora (mins)'',1,''ADM'',
        ''Tiempo (mins) para realizar la consulta de callbacks agrupados por hora en el Dashboard del Admin Kolob, default 5 min'',
        ''Time delay to refresh callbacks information (mins), default 5 min'',1,''.*'')
    end'
    EXEC(@sql)

    set @process = 'CW-6457 Insert new column defaultServiceLevelParameter into contactMeanIn'
    set @sql = '
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''defaultServiceLevelParameter'' AND Object_ID = Object_ID(N''contactMeanIn''))
    BEGIN
        ALTER TABLE contactMeanIn
        ADD defaultServiceLevelParameter SMALLINT DEFAULT 0;
    END'
    EXEC(@sql)

    set @process = 'CW-6457 Eliminar SP ccsp_WhatsAppInformation'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_WhatsAppInformation'')
    begin
        DROP PROCEDURE ccsp_WhatsAppInformation;
    end'
    EXEC(@sql)

    set @process = 'CW-6457 Enviar datos de campaĆ±a de whats a UI Dashboard'
    set @sql = '
    CREATE PROCEDURE [dbo].[ccsp_WhatsAppInformation]
    @Option SMALLINT,
    @InboundId SMALLINT = 0, 
    @ConversationId INT = 0

    AS
    SET NOCOUNT ON

    IF @InboundId IS NOT NULL 
    BEGIN
        IF EXISTS (SELECT * FROM ccInbound WHERE Inbound_id = @InboundId AND chat = 5) 
        BEGIN
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
        ELSE IF @Option = 0 -- Reset Averages Times 
            BEGIN
                TRUNCATE TABLE ccWAAverageConversations;
                TRUNCATE TABLE ccLastMessageAgentByConversation;
            END
    END
    RETURN(0)
    SET NOCOUNT OFF'
    EXEC(@sql)

    set @process = 'CW-6457 Fix Pin for WhatsApp Campaign'
    set @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminCampaigns'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminCampaigns;
    end'
    EXEC(@sql)

    set @process = 'CW-6457 Fix Pin for WhatsApp Campaign'
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
                                       CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, CAST(graph.graphic_id AS INT) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area
                                FROM ccCamps camps
                                     LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                                     LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
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
                                       CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, CAST(graph.graphic_id AS INT) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
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
            DECLARE @Wg TABLE (id INT, PRIMARY KEY(id));
            DECLARE @tmpAgent TABLE(id INT, PRIMARY KEY(id));
            DECLARE @tmpCamAgent TABLE(camId INT, userId INT, PRIMARY KEY(camId, userId));
            DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT);
            DECLARE @CurrentStatus TABLE(userId INT, CurrentState INT, IdCampEsp INT, camType INT);
            DECLARE @campDataTotal TABLE(camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY(camId));

            INSERT INTO @Wg SELECT DISTINCT IDWG
            FROM ccRIAWorkGroupUsers WG, 
                    ccUsers_Roles R
            WHERE WG.User_id = @AdminId
            OR (R.User_id = @AdminId
            AND R.Rol_id = 7);
                
            INSERT INTO @tmpAgent SELECT DISTINCT A.User_id
            FROM ccRIAWorkGroupUsers A
            INNER JOIN @Wg B ON A.IDWG = B.id
            INNER JOIN ccUsers C ON A.User_id = C.User_id   
            AND C.TipoUser_id = 1
            ORDER BY A.User_id;

            INSERT INTO @tmpCamAgent SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id
            FROM ccRIACampEspWG campPerWg
            INNER JOIN @Wg wg ON wg.Id = campPerWg.IDWG
            INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
            INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
            AND C.TipoUser_id = 1
            WHERE campPerWg.Tipo = @CampType
            AND (@Id=0 OR campPerWg.IdCampEsp=@Id);
       
            WITH lastState AS (
            SELECT A.user_id, MAX(A.fecha) AS fecha
            FROM ccLogAgentesDia A
            INNER JOIN @tmpAgent B ON A.User_id = B.id
            WHERE fecha >= @date
            GROUP BY user_id)

            INSERT INTO @CurrentStatus SELECT B.User_id,
            CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS currentStatus, B.IdCampEsp, B.Tipo
            FROM lastState A
            INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
            AND A.fecha = B.fecha;

            DECLARE @MultimediaType SMALLINT = (SELECT CASE WHEN @CampType = 1 THEN -1 ELSE meanContactTypeId END
                                                FROM contactMeanIn WHERE inboundId = 3)

            DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes

            INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
            (CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = 1
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
    End
else begin    
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
End 

    
    ;with   stateCamp as(

        SELECT A.CampId,
        count(case when A.CurrentState = 3 then 1 else null end) as ready,
        count(case when A.CurrentState NOT IN(-2, -1, 0, 3, 4, 5, 6, 9, 34) then 1 else null end) as notReady,
        COUNT(isCampDialog) AS dialog,
        count(case when a.CurrentState <= 0 then 1 else null end) as disconnected 
        FROM @AgentStatus A
        GROUP BY A.CampId
    )

                --select * from ccTipoStatusAgente

    select 
    A.camId,
    A.campName,A.Total
    ,isnull(B.ready,0) as Ready
    ,case when B.notReady is null then  A.Total else  A.Total-B.ready-B.dialog end as NotReady
    ,isnull(B.dialog,0) as Dialog
    ,isnull(B.disconnected, 0) as Disconnected
    ,A.Area
    
    from @campDataTotal A
    left join stateCamp B on A.camId=B.CampId
    order by A.campName
    


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


    set @process = 'CW-6446 Se agrega columna allowsConference'
    set @sql = '
        if not exists (select * from sys.columns where name = N''allowsConference'' and Object_ID = Object_ID(N''telefonosTransferencia''))
        begin
            ALTER TABLE telefonosTransferencia ADD allowsConference BIT NOT NULL DEFAULT 1
        end'
    EXEC(@sql)

    set @process = 'CW-6446 Se modifica ccsptelefonosTransferencia para traer columna allowsConference'
    set @sql = '
        ALTER PROCEDURE [dbo].[ccsptelefonosTransferencia]
        @userID INT
        as
        set nocount on

        BEGIN
        declare @value bit
        declare @IDArea int
        set @value = 0
        set @IDArea =1
        select @value = case when valor=''1'' then 1 else 0 end from ccSettings where setting_id = 191

        select @IDArea =IDArea from ccUsers where User_id =@userID
        if @value = 1
            begin
                select numtra_id id, nombre as  name, tel as number, isnull(IDArea,@IDArea) as id_area,  allowsConference 
                from telefonosTransferencia where idarea= @IDArea or IDArea is null order by nombre asc 
            end
            else
            begin
                select numtra_id id, isnull(cast(IDArea as varchar(20) )+'' - ''+  nombre , nombre ) as name, 
                tel as number, isnull(IDArea,@IDArea) as id_area,  allowsConference
                from telefonosTransferencia  order by nombre asc
            end
        END'
    EXEC(@sql) 

    set @process = 'K002055 Historial de conversaciones de WA se borra SP'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_AgentHistoricalChat'')
    begin
        DROP PROCEDURE ccsp_AgentHistoricalChat;
    end'
    EXEC(@sql)
    
    set @process = 'K002055 Historial de conversaciones de WA'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_AgentHistoricalChat]
	@option SMALLINT,
	@clientNum VARCHAR(15) = ''''
    AS
    BEGIN
        IF @option = 1 --whatsapp, get conversation ids
        BEGIN
            SELECT conversationId FROM [CCenterRIA].[dbo].[ccWhatsAppConversations] WHERE clientId = @clientNum GROUP BY conversationId
        END
    END'
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


