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

-------------------------------------- Begin hotfix/125.20231211.0.19 --------------------------------------
    set @process = 'Alter SP ccspRepAgentGI se agrega eliminar ambos DELETE  FROM RepAgentGI_VersionOld  WHERE DATE >= @from AND DATE < @to'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepAgentGI] 
@action AS TINYINT ,@from AS DATETIME ,@to AS DATETIME
AS
SET ANSI_WARNINGS OFF;
SET NOCOUNT ON;

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

IF @to IS NULL
    SELECT @to = GETDATE();

IF @action = 1
BEGIN
    
    DELETE  FROM RepAgentGI WHERE DATE >= @from AND DATE < @to
    DELETE  FROM RepAgentGI_VersionOld  WHERE DATE >= @from AND DATE < @to

    ;with timeDetailAgent as(   
    SELECT userId, timegroup        
        ,sum(CASE WHEN tipostatusage_id = 1 THEN tStatus ELSE 0 END) tunknown
        ,sum(CASE WHEN tipostatusage_id = 2 THEN tStatus ELSE 0 END) tNotReady
        ,sum(CASE WHEN tipostatusage_id IN (3, 31) THEN tStatus ELSE 0 END) tReady  --3 Ready y 31  Ready PreviewPro    
        ,sum(CASE WHEN tipostatusage_id IN (11, 25, 26, 27) THEN tStatus ELSE 0 END) tprob --11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida      
        ,sum(CASE WHEN tipostatusage_id = 7 THEN tStatus ELSE 0 END) tother
        ,sum(CASE WHEN tipostatusage_id = 7 THEN 1 ELSE 0 END) nother
        ,sum(CASE WHEN tipostatusage_id = 21 THEN tStatus ELSE 0 END) tmanualcall       
        ,sum(CASE WHEN tipostatusage_id IN (23, 24) THEN tStatus ELSE 0 END) AS tchatting
        ,sum(CASE WHEN tipostatusage_id = 30 THEN tStatus ELSE 0 END) AS tReconnectKolob
        ,sum(CASE WHEN tipostatusage_id = 32 THEN tStatus ELSE 0 END) AS tPreview
        ,sum(CASE WHEN tipostatusage_id = 33 THEN tStatus ELSE 0 END) AS tAssisted
        ,sum(CASE WHEN tipostatusage_id = 34 THEN tStatus ELSE 0 END) AS tDialogoWhatsApp
        ,sum(CASE WHEN A.TipoStatusAge_id = 37 THEN A.tStatus ELSE 0 END) AS tAuxiliarReady
        FROM tmpccLogAgentesDia A
        group by A.userId,A.timegroup
    )   
    ,inboundCount
    AS (
        SELECT timegroup
            ,user_id AS userId
            ,sum(nxfer) AS nxferin
            ,sum(nanswer) AS nanswerin
            ,sum(nabnd_xfer) AS nabndxferin
            ,sum(nabnd_ring) AS nabndringin
            ,sum(nabnd_dialog) AS nabnddlgin
            ,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferin
            ,sum(nno_answer) AS nnoanswerin
            ,sum(nlost) AS nlostin
            ,sum(nMoh) AS nMohIn
            ,sum(nWHag) AS nWHagIn
            ,sum(nWHcl) AS nWHclIn
            ,sum(tdialog) AS tdialogIn
            ,sum(tnotes) AS tnotesIn
            ,sum(tring) AS tringIn
            ,sum(txfer) AS txferIn          
        FROM tmpTimesInboundData
        WHERE user_id > 0
        group by timegroup,user_id
        )
        ,outboundCount
    AS (
        SELECT timegroup
            ,user_id AS userId
            ,sum(nxfer) AS nxferOut
            ,sum(nanswer) AS nanswerOut
            ,sum(nabnd_xfer) AS nabndxferOut
            ,sum(nabnd_ring) AS nabndringOut
            ,sum(nabnd_dialog) AS nabnddlgOut
            ,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferOut
            ,sum(nno_answer) AS nnoanswerOut
            ,sum(nlost) AS nlostOut
            ,sum(nMoh) AS nMohOut
            ,sum(nWHag) AS nWHagOut
            ,sum(nWHcl) AS nWHclOut
            ,sum(tdialog) AS tdialogOut
            ,sum(tnotes) AS tnotesOut
            ,sum(tring) AS tringOut
            ,sum(txfer) AS txferOut         
        FROM tmpTimesOutboundData
        WHERE user_id > 0
            AND cal_manual IN (0, 2, 3)
            group by timegroup,user_id
        )
    
    INSERT INTO RepAgentGI
    SELECT A.timegroup AS [date]
        ,A.user_id AS userId
        ,u.Nombres + '' '' + u.ApellidoPaterno + '' '' + u.ApellidoMaterno AS [user]
        ,u.LOGIN
        ,A.tlog
        ,isnull(atgStatus.tunknown,0) as tunknown
        ,isnull(atgStatus.tReady,0) as tReady
        ,isnull(atgStatus.tNotReady,0) as tNotReady
        ,isnull(atgStatus.tother,0) as tother
        ,isnull(atgStatus.tprob,0) as tprob
        ,isnull(atgStatus.tchatting,0) as tchatting
        ,isnull(A.tlog-( 
        isnull(atgStatus.tunknown+atgStatus.tReady+atgStatus.tNotReady+atgStatus.tother+atgStatus.tprob+atgStatus.tchatting+atgStatus.tmanualcall+ atgStatus.tAuxiliarReady,0)
        +isnull( txferin+tringin+tdialogin+tnotesIn,0)
        +isnull(txferout+tringout+tdialogout+tnotesout,0)
        
        ),0) as tundefined
        
        ---------------- Count IN Call -----------------------
        ,ISNULL(inCount.nxferin, 0) nXferIn
        ,ISNULL(inCount.nanswerin, 0) nAnswerIn
        ,ISNULL(inCount.nabndxferin, 0) nAbndXferIn
        ,ISNULL(inCount.nabndringin, 0) nAbndRingIn
        ,ISNULL(inCOunt.nabnddlgin, 0) AS nAbnddlgIn
        ,ISNULL(inCount.abndaxferin, 0) abndaXferIn
        ,ISNULL(inCount.nnoanswerin, 0) AS nnoAnswerIn
        ,ISNULL(inCount.nlostIn, 0) AS nlostIn
        ,isnull(inCount.tdialogIn, 0) AS tdialogIn
        ,isnull(inCount.tnotesIn, 0) tnotesIn
        ,isnull(inCount.tringIn, 0) tringIn
        ,isnull(inCount.txferIn, 0) txferIn

        ---------------- Count Out Call -----------------------      
        ,isnull(outTime.nXferOut, 0) nXferOut
        ,isnull(outTime.nAnswerOut, 0) nAnswerOut
        ,isnull(outTime.nAbndXferOut, 0) nAbndXferOut
        ,isnull(outTime.nAbndRingOut, 0) nAbndRingOut
        ,isnull(outTime.nAbnddlgOut, 0) AS nAbnddlgOut
        ,isnull(outTime.abndaXferOut, 0) abndaXferOut
        ,isnull(outTime.nnoAnswerOut, 0) AS nnoAnswerOut
        ,isnull(outTime.nlostOut, 0) AS nlostOut
        ,ISNULL(outTime.tdialogOut, 0) tdialogOut
        ,ISNULL(outTime.tnotesOut, 0) tnotesOut
        ,ISNULL(outTime.tringOut, 0) tringOut
        ,ISNULL(outTime.txferOut, 0) txferOut
        
        ---------------- Time Agent Common -----------------------      
        ,ISNULL(atgStatus.nother,0) nOther
        
        ---------------- Count In/Out Call-----------------------      
        ,isnull(inCount.nMohIn, 0) AS nMohIn
        ,isnull(outTime.nMohOut, 0) AS nMohOut
        ,isnull(inCount.nWHagIn, 0) AS nWHagIn
        ,isnull(outTime.nWHagOut, 0) AS nWHagOut 
        ,isnull(inCount.nWHclIn, 0) AS nWHclIn
        ,isnull(outTime.nWHclOut, 0) AS nWHclOut                

        ,datepart(yyyy, A.timegroup) AS [year]
        ,datepart(mm, A.timegroup) AS [mount]
        ,datepart(dd, A.timegroup) AS [day]
        ,datepart(HH, A.timegroup) AS [hour]
        ,datepart(mi, A.timegroup) AS [minutes]
        ,isnull(atgStatus.tmanualcall,0) as tmanualcall
        ,isnull(atgStatus.tAuxiliarReady,0) as tAuxiliarReady 
    FROM TmpSessionTimeGroup A
    LEFT JOIN ccUserView u ON A.[user_id] = u.[user_id]
    left join timeDetailAgent as atgStatus on atgStatus.userId=A.user_id and atgStatus.timegroup=A.timegroup
    LEFT JOIN inboundCount inCount ON A.timegroup = inCount.timegroup AND A.User_Id = inCount.userId
    left join outboundCount outTime ON outTime.timegroup = A.timegroup AND outTime.userId = A.User_id   
END;'
    EXEC(@sql)


    set @process = 'alter SP ccspRepAgentSummary DELETE RepAgentSummary WHERE DATE BETWEEN @from AND @to;'
    set @sql='CREATE PROCEDURE [dbo].[ccspRepAgentSummary] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()))

IF @to IS NULL
    SELECT @to = GETDATE()

if(@to = convert(datetime,convert(varchar(11),getdate(),121)+''03:00:00'',121)) AND @from = DATEADD(dd,-1,@to)
BEGIN   
    select @from = convert(datetime,convert(varchar(11),@from))
END

IF @action = 1
BEGIN

    IF OBJECT_ID(''tempdb..#AuxiliarReadyDetail'') IS NOT NULL
    DROP TABLE #AuxiliarReadyDetail

    CREATE TABLE #AuxiliarReadyDetail
    (
        timegroup DATE,
        userId INT,
        [user] VARCHAR(50),
        [sessionTime] INT,
        TipoReadyAuxiliarId INT,
        descripcion VARCHAR(50),
        descripcion_time VARCHAR(50),
        [time] DECIMAL(18, 3),
        timeSeconds DECIMAL(18, 3)
    )

    INSERT INTO #AuxiliarReadyDetail
    EXEC ccspGetAuxiliarReadyDetail @from = @from, @to = @to
        
    DELETE RepAgentSummary WHERE DATE BETWEEN @from AND @to;
    DELETE RepAgentSummary_VersionAmatech WHERE DATE BETWEEN @from  AND @to;
    ;
    WITH AgentSession
    AS (
        SELECT dbo.getdaygroup(loginTime) AS [date], userId, min([login]) AS [login], [user] AS [user], MIN(loginTime) AS dateLogin, MAX(logoutTime) AS logout, SUM(sessionTimeSeconds) AS sessionTime
        FROM RepAgentSession
        WHERE dbo.getdaygroup(loginTime) BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(logintime), userId, [user]
        ),
        -------------OUT -------------------
    dataCallsOut
    AS (
        SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
        FROM tmpTimesOutboundData
        where cal_manual in (0,2,3)
        GROUP BY cal_id, statusCall_id
        ), dataCallsOutByDay
    AS (
        SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogOut, SUM(tnotes) tNotesOut, sum(nabnd_xfer) nabnd_xfer
        , sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
        , SUM(txfer)  txferOut, SUM(tring)  tringOut
        FROM tmpTimesOutboundData
        where cal_manual in (0,2,3)
        GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
        ), tmpCallout
    AS (
        SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifOut
        , isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallOut
        , isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallOut
        , sum(tDialogOut) AS tDialogOut, sum(tNotesOut) AS tNotesOut, sum(nabnd_xfer) abnd_xfer, sum(nabnd_ring) abnd_ring
        , sum(nabnd_dialog) abnd_dialog, [date]
        , SUM(txferOut)  txferOut, SUM(tringOut)  tringOut
        FROM dataCallsOutByDay A
        INNER JOIN dataCallsOut B
            ON A.cal_id = B.cal_id
        GROUP BY [date], User_id
        ),
        ------------- IN -------------------
    dataCallsIn
    AS (
        SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
        FROM tmpTimesInboundData
        GROUP BY cal_id, statusCall_id
        ), dataCallsInByDay
    AS (
        SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogIn, SUM(tnotes) tNotesIn
        , sum(nabnd_xfer) nabnd_xfer, sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
        , SUM(txfer)  txferIn, SUM(tring)  tringIn
        FROM tmpTimesInboundData
        GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
        ), tmpCallIn
    AS (
        SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifIn
        , isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallIn
        , isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallIn
        , sum(tDialogIn) AS tDialogIn, sum(tNotesIn) AS tNotesIn, sum(nabnd_xfer) abnd_xfer
        , sum(nabnd_ring) abnd_ring, sum(nabnd_dialog) abnd_dialog, [date]
        , SUM(txferIn)  txferIn, SUM(tringIn)  tringIn
        FROM dataCallsInByDay A
        INNER JOIN dataCallsIn B
            ON A.cal_id = B.cal_id
        GROUP BY [date], User_id
        ), RepDetail
    AS (
        SELECT r.userId, SUM(r.timeSeconds) AS notReady, dbo.getdaygroup(r.DATE) AS daygroup
        FROM RepAgentNotReady r with(nolock)
        WHERE r.DATE BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(r.DATE), r.userId
        )
    ,notReadyDay as(
    SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(r.DATE) AS daygroup
        ,descripcion_time,descripcion,tiponotreadyId
        FROM RepAgentNotReady r with(nolock)
        WHERE r.DATE BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(r.DATE), r.userId,descripcion,descripcion_time,tiponotreadyId
    ),auxiliarReadyDay as(
        SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(timegroup) AS daygroup
        ,descripcion_time,descripcion,TipoReadyAuxiliarId
        FROM #AuxiliarReadyDetail r with(nolock)
        GROUP BY dbo.getdaygroup(timegroup), r.userId,descripcion,descripcion_time,TipoReadyAuxiliarId
    ), RepAgentGIGroup as(
        SELECT dbo.getdaygroup([date]) AS [date], userId, SUM(tav) AS tav
        , SUM(tunknown) AS tunknown
        , SUM(tother) AS tother
        , SUM(tprob) AS tprob
        , SUM(tChatting) AS tChatting       
        , SUM(tundefined) AS tundefined
        , SUM([tManual]) AS [tManual]
        FROM RepAgentGI
        WHERE [date] BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup([date]), userId
    )
    --select * from AgentSession
    
    INSERT INTO RepAgentSummary (date,login,[user],sessionTime,loginMktTime,logoutMktTime,callTengaged,ndTime,NCallsOut,NCallsIn,NCallsCorta,NAtend,NNoCalif
    ,Available,avgCallTengaged,twrapup,userId,TypeNotReady,descripcion,descripcion_time,time,transferStatus,ringingTime,unknownStatus,otherStatus,failureStatus
    ,chatTengaged,undefinedTime,dialingStatus,TipoReadyAuxiliarId,auxiliarRedy_descripcion,descripcion_auxiliarRedyTime_time,auxiliarRedyTime)
    SELECT A.[date], A.[login], A.[user], A.sessionTime, A.dateLogin AS loginMktTime
    , A.logout AS logoutMktTime
    , isnull(co.tDialogOut, 0) + isnull(ci.tDialogIn, 0) callTengaged
    , ISNULL(r.notready, 0) AS ndTime, isnull(co.AttendedCallOut, 0) AS NCallsOut, isnull(ci.AttendedCallIn, 0) AS NCallsIn
    , ISNULL(co.abnd_xfer, 0) + isnull(co.abnd_ring, 0) + isnull(co.abnd_ring, 0) + isnull(ci.abnd_xfer, 0) + isnull(ci.abnd_ring, 0) + isnull(ci.abnd_ring, 0) AS NCallsCorta
    , ISNULL(co.NotAttendedCallOut, 0) + ISNULL(ci.NotAttendedCallIn, 0) AS NAtend
    , ISNULL(ci.NoCalifIn, 0) + ISNULL(co.NoCalifOut, 0) AS NNoCalif    
    , ISNULL(AgtGI.tav, 0) AS Available
        ,ISNULL(    
        (   ISNULL(co.tDialogOut, 0) + ISNULL(co.tNotesOut, 0) + ISNULL(ci.tDialogIn, 0) + ISNULL(ci.tNotesIn, 0) )
            /
         nullif(isnull(co.AttendedCallOut,0) + isnull(ci.AttendedCallIn,0),0)
        , 0) AS avgCallTengaged
        
        ,ISNULL(co.tNotesOut, 0) + ISNULL(ci.tNotesIn, 0) AS twrapup, A.userId AS userId
        , notReady.TipoNotReadyId
        , notReady.descripcion
        , notReady.descripcion_time
        , notReady.timeSeconds
        , ISNULL(co.txferOut, 0) + ISNULL(ci.txferIn, 0) AS transferStatus
        , ISNULL(co.tringOut, 0) + ISNULL(ci.tringIn, 0) AS ringingTime
        , ISNULL(AgtGI.tunknown, 0) unknownStatus
        , ISNULL(AgtGI.tother, 0) otherStatus
        , ISNULL(AgtGI.tprob, 0) failureStatus
        , ISNULL(AgtGI.tChatting, 0) chatTengaged
        , ISNULL(AgtGI.tundefined, 0) undefinedTime
        , ISNULL(AgtGI.tManual, 0) dialingStatus
        , auxiliarReady.TipoReadyAuxiliarId
        , auxiliarReady.descripcion as auxiliarRedy_descripcion
        , auxiliarReady.descripcion_time as descripcion_auxiliarRedyTime_time
        , convert(int,auxiliarReady.timeSeconds) as auxiliarRedyTime
    FROM AgentSession A
    LEFT JOIN tmpCallout co ON A.DATE = co.DATE AND A.userId = co.userId
    LEFT JOIN tmpCallIn ci  ON A.DATE = ci.DATE AND A.userId = ci.userId
    LEFT JOIN RepDetail r   ON r.daygroup = A.DATE AND A.userId = r.userId
    inner join notReadyDay notReady on notReady.userId=A.userId and notReady.daygroup=A.date
    LEFT join #AuxiliarReadyDetail auxiliarReady on auxiliarReady.userId=A.userId and auxiliarReady.timegroup=A.date
    left join RepAgentGIGroup AgtGI on AgtGI.date=A.date and AgtGI.userId=A.userId
    order by A.[date],A.userId

END'
    EXEC(@sql)
   
    -------------------------------------- End hotfix/125.20231211.0.17 --------------------------------------


	
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
