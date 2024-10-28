/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 128

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
SET @version = 140 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

----------------------------------------------------------- BEGIN Isaac Cortes  hotfix/125.20231211.0.17  -------------------------------------------------------------------------
    set @process = 'Actualizar settting 40'
    set @sql='
    IF (SELECT valor FROM ccsettings WHERE setting_id=44) <> ''200000|200000|2500000|10000|250000|2500000|44''
    BEGIN
        UPDATE ccSettings 
        SET valor=''200000|200000|2500000|10000|250000|2500000|44''
        WHERE setting_id=44
    END
    '
    EXEC(@sql)

    set @process = 'Eliminar SP ccspRepCallXfer'
    set @sql='
    IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepCallXfer'')
    BEGIN
        DROP PROCEDURE ccspRepCallXfer;
    END
    '
    EXEC(@sql)

    set @process = 'Crear SP ccspRepCallXfer y añadir modo 7 para press 8'
    set @sql='
    CREATE PROCEDURE [dbo].[ccspRepCallXfer]
    @action as tinyint,
    @from AS datetime = null,
    @to AS datetime = null
    AS

    SET NOCOUNT ON

    if @action = 1
    begin
        if @from is null
            select @from = convert(datetime,convert(varchar(11),getdate()))
        if @to is null	
            select @to = getdate()

        delete RepCallXfer with(rowlock)	where [date] between @from and @to
        insert RepCallXfer 
        select convert(varchar(10),fechafin,121) [date], 
        clt.cal_id callid, 
        case when tipo = 1 then ''systemTranslated_inbound'' else ''systemTranslated_outbound'' end CallTypes, 
        isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno 
                from ccUserView nolock 
                where user_id = (case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') Agent, 
        case when modo = 0 then ''systemTranslated_blindXfer'' 
            when modo = 1 then ''systemTranslated_Agent'' 
            when modo = 2 then 
                case when cast(dbo.Limpia(clt.destino) as int) >= 0 then ''systemTranslated_acd'' 
                    else ''systemTranslated_Survey'' end 
            when modo = 3 then ''systemTranslated_conference'' 
            when modo = 4 then ''systemTranslated_supXfer'' 
            when modo in(5,6) then ''systemTranslated_overflow'' 
            when modo in(7) then ''systemTranslated_press8'' 
            else ''systemTranslated_Default'' 
        end as xfertype, 
        ISNULL((case when modo = 0 then isnull((select top 1 nombre 
                                        from telefonosTransferencia 
                                        where tel = clt.destino),clt.destino) 
            when modo = 1 then isnull((select Computer 
                                        from ccposicion 
                                        where pos_id = abs(clt.destino)),''systemTranslated_Indefinite'') 
            when modo = 2 then 
                case when cast(dbo.Limpia(clt.destino) as bigint) >= 0 then
                        isnull((select descripcion from ccinbound 
                                where inbound_id = clt.destino),''systemTranslated_Indefinite'') 
                    else
                        isnull((select top 1 description 
                                from survey 
                                where active=1 
                                and scriptId = abs(cast(clt.destino as int))),''systemTranslated_Indefinite'') 
                end 
            when modo = 3 then isnull((select nombre 
                                        from telefonosConferencia 
                                        where tel = clt.destino),clt.destino) 
            when modo = 4 then isnull((select top 1 nombre 
                                        from telefonosTransferencia 
                                        where tel = clt.destino),clt.destino) 
            when modo in(5,6) then isnull((select Computer 
                                            from ccposicion 
                                            where pos_id = abs(clt.destino)),clt.destino) 
        end), ''systemTranslated_Indefinite'') destination, 
        tantesxfer timebeforexfer, 
        tdespuesxfer timeafterxfer, 
        dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate, 
        fechafin as endDate, 
        case when camp.cam_descripcion is not null then camp.cam_descripcion 
            when inbound.descripcion is not null then inbound.descripcion 
            else ''systemTranslated_Indefinite'' 
        end as Origin, 
        tantesxfer+tdespuesxfer as TotalTimeDuration, 
        isnull((select case clt.tipoLlamada_id 
                    when 1 then ''systemTranslated_fijo'' 
                    when 3 then ''systemTranslated_cellPhone'' 
                    else ''systemTranslated_interno'' 
                end),''systemTranslated_Indefinite'') as TipoTel, 
        (case tipo when 1 then ci.User_id else co.User_id end) User_ID, 
        isnull(callerAni, '''')  as callerni
        from cclogtransfers clt 
        left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
        left join cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1 
        left join cccamps camp on camp.cam_id =co.cam_id 
        left join ccinbound inbound on inbound.Inbound_id =ci.Inbound_id 
        WHERE fechafin >= @from and fechafin < @to
    end
    '
    EXEC(@sql)




----------------------------------------------------------- End Isaac Cortes hotfix/125.20231211.0.17 -------------------------------------------------------------------------


    -------------------------------------- Begin Jesus Gallardo hotfix/125.20231211.0.17 --------------------------------------
    set @process = 'alter SP ccspRepOutAnswAndXferCalls se modifica ani de ccoLogDials para reportes'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = NULL

AS

SET NOCOUNT ON

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME,CONVERT(VARCHAR(11),GETDATE()))
IF @to IS NULL
    SELECT @to = GETDATE()

DECLARE @IVA INT
DECLARE @country AS TINYINT
SELECT @IVA = CONVERT(INT,ISNULL(valor,0)) FROM ccsettings WHERE setting_id = 25
SELECT @country = CONVERT(TINYINT,ISNULL(valor,1)) FROM ccsettings WHERE setting_id = 104

IF @country IS NULL SET @country = 1

IF @action = 1
BEGIN
--Borrar lo que esta para no repetir
DELETE FROM RepOutAnswAndXferCalls WHERE DATE >= @from AND DATE < @TO

declare @descriptionXfer varchar(100)

SELECT @descriptionXfer=[description] FROM dialType WHERE dialId = 3

;with ccld as(
    SELECT *, [dbo].[GetProveedor](Telefono, Puerto,tipoLlamada_id) AS proBIDs,tipoLlamada_id as CallType  FROM ccologdials
    WHERE fecha between @from and @to and answerbit = 1
)

INSERT INTO RepOutAnswAndXferCalls
SELECT COALESCE([Call].cal_inicio,ccld.fecha) AS [date],
    ISNULL(ccld.cal_id,0) AS [callid],
    ISNULL(ccld.cam_id,0) AS [campaignId],
    ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
    ISNULL([Call].user_id,0) AS [userId],
    ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') AS [Agent],
    dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg) AS [dialog],
    ccld.telefono AS [telephone],
    ISNULL(Call.cal_manual,0) AS [dialId],
    ISNULL(dialType.[description],''systemTranslated_Auto'') AS [dialType],
    ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
    CASE 
        WHEN provedor_id IS NOT NULL THEN dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),COALESCE(Call.provedor_id,ccld.proBIDs),
            dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg), @country)
        ELSE  CONVERT(DECIMAL(10,2),(CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) / 60) * ccost.additional_min)))
    END AS [ncost],
    @IVA AS iva,
    CASE
        WHEN provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),
                COALESCE(Call.provedor_id,ccld.proBIDs), dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg), @country),0.00) * (1 + (@IVA / 100.00)))
        ELSE  CONVERT(DECIMAL(10,2),((CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) / 60) * ccost.additional_min)) * (1 + (@IVA / 100.00))))
    END AS total,
    COALESCE(ccld.Puerto, Call.cal_puerto, 0) as [trunk],
    case when (ccld.ani is not null and ccld.ani<>'''') then ccld.ani when dbo.TelAni(ccld.Telefono, camps.id_anilist) <> '''' then dbo.TelAni(ccld.Telefono, camps.id_anilist) else camps.ani end [ANI],
    COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) as dialTimeSec
FROM ccld
    LEFT JOIN ccoCallsOut Call WITH(NOLOCK) ON ccld.cal_id = Call.cal_id
            AND ccld.answerbit = 1
    LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
    LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
    LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
    LEFT JOIN ccCallCost_RIA ccost (NOLOCK) ON ccost.tipoLlamada_id = tl.tipoLlamada_id     AND ccost.country_id = tl.country_id
    left join dialType on dialType.dialId = Call.cal_manual


;with clt as (

SELECT *
, DATEADD(ss,-(tAntesXfer + tDespuesXfer),fechaFin) AS [date]
, tipoLlamada_id AS  CallType 
,case WHEN modo in(5,6) then abs(destino) else null end posicion
    FROM cclogtransfers WITH(NOLOCK) 
    WHERE modo not in (1,2) 
        AND (tAntesXfer > 0 or tDespuesXfer > 0) 
        AND fechaFin between @from and @to
)


INSERT INTO RepOutAnswAndXferCalls  
SELECT clt.[date],
    clt.cal_id AS [callid],
    COALESCE(co.cam_id,ci.inbound_id,''0'')  AS [campaignId],
    COALESCE(camps.cam_descripcion, ACD.descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
    ISNULL((CASE tipo 
                WHEN 1 THEN ci.User_id 
                ELSE co.User_id 
            END),0) AS [userId],
    ISNULL((SELECT nombres + '' '' + apellidopaterno + '' '' + apellidomaterno FROM ccusers NOLOCK WHERE user_id = 
                (CASE tipo 
                    WHEN 1 THEN ci.User_id 
                    ELSE co.User_id 
                END)),''systemTranslated_NoName'') as [Agent],
    dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) AS [dialog],
    CASE 
        WHEN modo = 0 THEN clt.destino
        WHEN modo = 3 THEN clt.destino 
        WHEN modo = 4 THEN clt.destino 
        WHEN modo in(5,6) THEN isnull((SELECT top 1 Computer FROM ccposicion WHERE pos_id = posicion),clt.destino) 
    END AS [telephone],
    3 AS [dialId],
    @descriptionXfer AS [dialType],
    ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
    CASE 
        WHEN tarifa.provedor_id IS NOT NULL THEN ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
            dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) ,@country), 0) 
        ELSE cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)
    END AS [ncost],
    @IVA AS iva,
    CASE 
        WHEN tarifa.provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
            dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0)
            ,@country),0.00) * (1 + (@IVA / 100.00))) 
        ELSE (cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)) * (1 + (@IVA / 100.00))
    END AS [total],
    IsNull(clt.channel, 0) as [trunk],
    case when (@country = 1 and modo = 4) then case when dbo.TelAni(clt.destino, camps.id_anilist) <> '''' then dbo.TelAni(clt.destino,camps.id_anilist) else camps.ani end else '''' end [ANI],
    ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) as dialTimeSec
FROM clt
    LEFT JOIN cccallsin ci WITH(NOLOCK) ON ci.cal_id=clt.cal_id AND tipo=1
    LEFT JOIN ccocallsout co WITH(NOLOCK) ON co.cal_id=clt.cal_id AND tipo=2 
    LEFT JOIN ccChannelTransfer channel ON clt.pbxId=channel.pbxId AND clt.channel BETWEEN channel.startChannel AND channel.endChannel
    LEFT JOIN cstoTarifa tarifa ON tarifa.provedor_id=channel.proveedorId AND tarifa.tipoLlamada_id = clt.CallType
    LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType AND tl.Country_id = @country)
    LEFT JOIN ccCallCost_RIA cCall ON cCall.country_id = tl.country_id AND cCall.tipoLlamada_id = tl.tipoLlamada_id
    LEFT JOIN ccCamps camps ON camps.[cam_id] = co.cam_id
    LEFT JOIN ccInbound ACD ON ACD.[Inbound_id] = ci.Inbound_id

end'
    EXEC(@sql)
  
-------------------------------------- End hotfix/125.20231211.0.17 --------------------------------------


-------------------------------------- Begin Carlos Muñoz --------------------------------------
set @process = 'K002151 Reporte historial de desasignaciones'
	set @sql = 'if not exists (select * from sys.tables where name = N''RepWhatsConversationsUnassigned'')
				BEGIN
					CREATE TABLE [dbo].[RepWhatsConversationsUnassigned](
                    [date] [datetime] NOT NULL,
                    [conversationid] [int] NOT NULL,
                    [globalid] [int] NULL,
                    [inboundid] [int] NULL,
                    [campaign] [varchar](50) NOT NULL,
                    [associatedPhoneNumberWhatsApp] [varchar](40) NOT NULL,
                    [contactPhoneNumberWhatsApp] [varchar](40) NULL,
                    [unassignedBy] [varchar](40) NULL,
                    [userId] [int] NOT NULL,
                    [agentName] [varchar](50) NOT NULL,
                    [year] [smallint] NOT NULL,
                    [month] [smallint] NOT NULL,
                    [day] [smallint] NOT NULL,
                    [hour] [smallint] NOT NULL,
                    [minutes] [smallint] NOT NULL
                ) ON [PRIMARY]
				END;'
	EXEC(@sql)

	set @process = 'DEV1-673 create index on RepWhatsConversationsUnassigned'
	set @sql = '
	if not exists (select * from sys.indexes where name = N''IX_RepWhatsConversationsUnassigned'' and object_id = OBJECT_ID(N''RepWhatsConversationsUnassigned''))
    begin
        CREATE INDEX IX_RepWhatsConversationsUnassigned ON RepWhatsConversationsUnassigned(date, inboundid, userId);
    end
	'
    EXEC(@sql)

    set @process = 'DEV1-673 Reportfilters, reportfiltersmenus and translation'
	-- REPORTS FILTERS
    set @sql = '
	if not exists (select * from ReportsFilters where id=12015 and filterName=''acds'')
	begin
		INSERT INTO ReportsFilters(reportName,filterName,id) VALUES(''Conversations unassigned'',''acds'',12015) 
	end
	'
	EXEC(@sql)

    set @sql = '
	if not exists (select * from ReportsFilters where id=12015 and filterName=''users'')
	begin
		INSERT INTO ReportsFilters(reportName,filterName,id) VALUES(''Conversations unassigned'',''users'',12015) 
	end
	'
	EXEC(@sql)

    -- REPORTS FILTERS MENUS
    set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=12015 and filterMenuName=''date'')
	begin
		INSERT INTO ReportsFiltersMenus VALUES(12015,N''date'',1,'''') 
	end
	'
	EXEC(@sql)

    set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=12015 and filterMenuName=''filterby'')
	begin
		INSERT INTO ReportsFiltersMenus VALUES(12015,N''filterby'',1,'''') 
	end
	'
	EXEC(@sql)

    set @sql = '
	if not exists (select * from TranslatedReports where id=12015)
	begin
		INSERT INTO TranslatedReports VALUES (12015, ''unassignedBy'')
	end
	'
	EXEC(@sql)

    set @process = 'DEV1-673  DROP PROCEDURE ccspRepWhatsConversationsUnassigned '
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccspRepWhatsConversationsUnassigned'')
    begin
        DROP PROCEDURE ccspRepWhatsConversationsUnassigned;
    end
	'
	EXEC(@sql)

        
    set @sql = '
        CREATE PROC ccspRepWhatsConversationsUnassigned
        @action AS tinyint,
        @from as datetime = null,
        @to as datetime = null
        AS
            IF @from is null
                SET @from = getdate()
                SET @from = DATEADD(dd, -1, @from)
            IF @to is null
                SET @to = getdate()

            IF @action = 1
            BEGIN
                DELETE FROM RepWhatsConversationsUnassigned WHERE date >= @from AND date < @to

                INSERT INTO RepWhatsConversationsUnassigned
                SELECT requestDate as date, 
                    wac.conversationId as conversationid,
                    ISNULL(globalRelation.GlobalId, 0) as globalid,
                    i.Inbound_id as inboundid,
                    i.descripcion as campaign, 
                    phoneACD as associatedPhoneNumberWhatsApp, 
                    clientId as contactPhoneNumberWhatsApp, 
                    CASE wac.conversationStatus
                            WHEN 4 THEN ''systemTranslated_Agent''
                            WHEN 17 THEN ''systemTranslated_systemTimeout''
                            WHEN 18 THEN ''systemTranslated_systemError''
                            END as unassignedBy, 
                    ISNULL(u.User_id, 0) as userId, 
                    ISNULL(u.Nombres, '''') as agentName ,
                    DATEPART(yyyy, wac.requestDate) [year],
                    datepart(mm, wac.requestDate) [month],
                    datepart(dd, wac.requestDate) [day],
                    datepart(hh, wac.requestDate) [hour],
                    datepart(mi, wac.requestDate) [minutes]
                FROM ccWhatsAppConversations wac LEFT JOIN ccInbound i on wac.inboundId = i.Inbound_id 
                LEFT JOIN ccUserView u ON u.User_id = wac.agentId
                LEFT JOIN ccWhatsAppGlobalIdsRelationship globalRelation ON globalRelation.ConversationId = wac.conversationId AND globalRelation.ConversationType = 0
                LEFT JOIN ccWhatsAppGlobalIds globalIds ON globalRelation.GlobalId = globalIds.GlobalId AND 
                        globalIds.FirstMessageConversationIdFromAgent = wac.conversationId AND
                        globalIds.FirstMessageConversationTypeFromAgent = 0
                WHERE wac.conversationStatus IN (4,17,18) AND wac.requestDate BETWEEN @from AND @to
        END
    '
    EXEC(@sql)

    set @process = 'K002152 Reporte SPAM de conversaciones WhatsApp de entrada'
	set @sql = 'if not exists (select * from sys.tables where name = N''RepWhatsConversationsMarkedAsSpam'')
				BEGIN
                    CREATE TABLE [dbo].[RepWhatsConversationsMarkedAsSpam](
                        [date] [datetime] NOT NULL,
                        [conversationid] [int] NOT NULL,
                        [globalid] [int] NULL,
                        [inboundid] [int] NULL,
                        [campaign] [varchar](50) NOT NULL,
                        [associatedPhoneNumberWhatsApp] [varchar](40) NOT NULL,
                        [contactPhoneNumberWhatsApp] [varchar](40) NULL,
                        [spamDate] [datetime] NOT NULL,
                        [userId] [int] NOT NULL,
                        [agentName] [varchar](50) NOT NULL,
                        [year] [smallint] NOT NULL,
                        [month] [smallint] NOT NULL,
                        [day] [smallint] NOT NULL,
                        [hour] [smallint] NOT NULL,
                        [minutes] [smallint] NOT NULL
                    ) ON [PRIMARY]
				END;'
	EXEC(@sql)

    set @process = 'DEV2-685 create index on RepWhatsConversationsMarkedAsSpam'
	set @sql = '
	if not exists (select * from sys.indexes where name = N''IX_RepWhatsConversationsMarkedAsSpam'' and object_id = OBJECT_ID(N''RepWhatsConversationsMarkedAsSpam''))
    begin
        CREATE INDEX IX_RepWhatsConversationsMarkedAsSpam ON RepWhatsConversationsMarkedAsSpam(date, inboundid, userId);
    end
	'
    EXEC(@sql)

    set @process = 'DEV2-685 Reportfilters, reportfiltersmenus and translation'
	-- REPORTS FILTERS
    set @sql = '
	if not exists (select * from ReportsFilters where id=12017 and filterName=''acds'')
	begin
		INSERT INTO ReportsFilters(reportName,filterName,id) VALUES(''Conversations As Spam IN'',''acds'',12017) 
	end
	'
	EXEC(@sql)

    set @sql = '
	if not exists (select * from ReportsFilters where id=12017 and filterName=''users'')
	begin
		INSERT INTO ReportsFilters(reportName,filterName,id) VALUES(''Conversations As Spam IN'',''users'',12017) 
	end
	'
	EXEC(@sql)

    -- REPORTS FILTERS MENUS
    set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=12017 and filterMenuName=''date'')
	begin
		INSERT INTO ReportsFiltersMenus VALUES(12017,N''date'',1,'''') 
	end
	'
	EXEC(@sql)

    set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=12017 and filterMenuName=''filterby'')
	begin
		INSERT INTO ReportsFiltersMenus VALUES(12017,N''filterby'',1,'''') 
	end
	'
	EXEC(@sql)

    set @process = 'DEV2-685 DROP PROCEDURE ccspRepWhatsConversationsMarkedAsSpam '
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccspRepWhatsConversationsMarkedAsSpam'')
    begin
        DROP PROCEDURE ccspRepWhatsConversationsMarkedAsSpam;
    end
	'
	EXEC(@sql)

    set @sql = '
    CREATE PROC ccspRepWhatsConversationsMarkedAsSpam
        @action AS tinyint,
        @from as datetime = null,
        @to as datetime = null
    AS
        IF @from is null
            SET @from = getdate()
            SET @from = DATEADD(dd, -1, @from)
        IF @to is null
            SET @to = getdate()

        IF @action = 1
        BEGIN
            DELETE FROM RepWhatsConversationsMarkedAsSpam  WHERE date >= @from AND date < @to

            INSERT INTO RepWhatsConversationsMarkedAsSpam
            SELECT wac.requestDate as date, 
                was.conversationId as conversationid,
                ISNULL(globalIds.GlobalId,0) as globalid,
                was.InboundId as inboundid,
                i.descripcion as campaign,
                wac.phoneACD as associatedPhoneNumberWhatsApp,
                wac.clientId as contactPhoneNumberWhatsApp,
                was.Fecha as spamDate,
                was.AgentId as userId,
                u.Nombres as agentName,
                DATEPART(yyyy, wac.requestDate) [year],
                datepart(mm, wac.requestDate) [month],
                datepart(dd, wac.requestDate) [day],
                datepart(hh, wac.requestDate) [hour],
                datepart(mi, wac.requestDate) [minutes]
            FROM ccWhatsAppSpam was 
                LEFT JOIN ccWhatsAppConversations wac ON was.ConversationId = wac.conversationId
                LEFT JOIN ccInbound i on was.inboundId = i.Inbound_id 
                LEFT JOIN ccUserView u ON u.User_id = was.agentId
                LEFT JOIN ccWhatsAppGlobalIdsRelationship globalRelation ON globalRelation.ConversationId = was.conversationId AND globalRelation.ConversationType = 0
                LEFT JOIN ccWhatsAppGlobalIds globalIds ON globalRelation.GlobalId = globalIds.GlobalId AND 
                    globalIds.FirstMessageConversationIdFromAgent = was.conversationId AND
                    globalIds.FirstMessageConversationTypeFromAgent = 0
            WHERE wac.agentId <> 0 AND wac.requestDate BETWEEN @from AND @to
        END
    '
    EXEC(@sql)

-------------------------------------- End Carlos Muñoz --------------------------------------
	
	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
