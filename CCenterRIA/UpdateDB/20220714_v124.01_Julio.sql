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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 1
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF (@actualVersion =@version-1 and @actualVersionFix >= 53) or  (@actualVersion =@version and @actualVersionFix =@versionfix)
BEGIN
	BEGIN TRAN

	BEGIN TRY	

	-------------------------------BEGIN MENUS --------------------------------

	set @process = 'K002056 se agregan menus'
    set @sql = 'if not exists( select * from ccmenus where type=3 and menu_id=12000)
begin
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
	values(12000,''WhatsApp|WhatsApp'',12000,''A'',7,3,'''',''9f1901c17c425d0a50eb4ef481632d34b736aa1dae75e5134dd5c15d4dde150d'')

	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
	values(12010,''Detalle de conversaciones|Conversations Detail'',12000,''B'',7,3,'''',''accb20a46285ea9856ace61e5e3ffd452de1f55f20c7a005ce8e05a503060fb18beee994719b6abd36ad36efaffd0370'')

	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
	values(12020,''Conversaciones por campaña|Conversations by Campaign'',12000,''B'',7,3,'''',''2605c8244920fb599fb936a4bf94521a7284d5e414815e8ef15fa8f6b0040db16a54ce29b02250a22a8cb87c41c6f3b30e3860a31b59d733442bb174a555b7b2'')

end'
	EXEC(@sql)

    set @process = 'K002056 se actualiza el orden de los menus'
    set @sql = '
    update ccMenus set ordengral = 8 where type = 3 and parent = 6000
update ccMenus set ordengral = 9 where type = 3 and parent = 8000
update ccMenus set ordengral = 10 where type = 3 and parent in  (8050,8060,8080)
update ccMenus set ordengral = 11 where type = 3 and parent = 7000
update ccMenus set ordengral = 12 where type = 3 and parent = 9000'
    EXEC(@sql)

    set @process = 'K002056 Se altera ccsp_RIACATMenu'
    set @sql = 'ALTER procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
Declare @AVRS tinyint
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenusChat tinyint
Declare @MenuMail tinyint
Declare @MenuCRM tinyint
Declare @monitorPortMenu tinyint

set @MenuMail=0
set @MenuCRM = 0
set @monitorPortMenu =0

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155
select @MenuCRM = valor from ccsettings where setting_id = 168
select @monitorPortMenu = case when valor=''1'' then 1 else 0 end from ccsettings where setting_id = 186

---Mail MenuId (81)
if @Type=1
begin
	if @ReportRol = 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus)) where type = 1
		and (
		(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82,83,84,85,69))
		or (menu_id = 41 and @CM = 1)
		or (menu_id = 42 and @AE > 0)
		or (menu_id = 53 and @NRS = 1)
		or (menu_id in (71,72) and @IVRScripting = 1)
		or (menu_id in (73,74,75,76) and @AVRS = 1)
		or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
		or (menu_id = 79 and @MenusChat > 0)
		or (menu_id in (81,82,84,85) and @MenuMail = 1)--Mail
		or (menu_id = 83 and @MenuCRM > 0)
		or (menu_id = 69 and @monitorPortMenu > 0)--Monitoreo de puertos
		)
		order by ordengral asc
		return(0)

	end
	else if @ReportRol = 3 begin
		select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) and menu_id not in (select distinct Parent from ccMenus where menu_id >= 2000 and type = 3)
		and (menu_id not in (3131,3132,3133,3134,3135,3136,8061,8062,8063,8071,8072,8080,10000,10010,10020,10030,10040))
		or  (menu_id     in (3131,3132,3133,3134,3135,3136) and @MenusChat > 0 )
		or  (menu_id     in (8061,8062,8063,8071,8072,8080) and @AVRS > 0)
		or  (menu_id     in (9000,9010) and @MenuCRM > 0 )
		or  (menu_id     in (10000,10010,10020,10030,10040) and @MenuMail > 0 )
		order by ordengral asc,menu_id
		return(0)
	end
	else begin
		select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)
	end

end

if @Type=2
begin
	delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu and type = @ReportRol
	return(0)
end

if @Type=3
begin
	insert into ccMenuUser(id_User,id_Menu,type) values (@id_User, @id_Menu,@ReportRol)
	return(0)
end

if @Type=4
begin
	declare @lan varchar(3), @page varchar(200)
	select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
	select @lan = case valor when 0 then ''ES'' else ''EN'' end from ccSettings where setting_id = 27

	select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
	return(0)
end

set nocount off'
    EXEC(@sql)
	-------------------------------END MENUS --------------------------------

	 -------------------------  Start CCC --------------------------------------------------
	 set @process = 'K002124-Mensajes recibidos en conversación al existir una desconexión en el servicio MultimediaCommon'
     set @sql = 'ALTER PROCEDURE [dbo].[ccsp_Multimedia2] @action INT, @inboundId INT = NULL, @userId INT = NULL, @senderId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	IF @action = 1
	BEGIN --Lista  ACD
		SELECT DISTINCT A.inbound_id AS Id, A.chat AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets, 
		cast(isnull(C.maxWhats, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId
		FROM ccInbound A
		INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
		WHERE @inboundId IS NULL OR @inboundId = A.Inbound_id
	END
	ELSE IF @action = 2
	BEGIN --Lista Agentes  
		SELECT DISTINCT A.User_id AS [Id], C.idCampEsp AcdId, isnull(skill, 8) Skill
		FROM ccRIAWorkGroupUsers A
		INNER JOIN ccusers B ON A.User_id = B.User_id
		INNER JOIN ccRIACampEspWG C ON C.IDWG = A.IDWG AND C.Tipo = 0
		INNER JOIN ccInbound D ON C.idCampEsp = D.inbound_id
		LEFT JOIN ccskills S ON S.inbound_id = D.inbound_id AND S.user_id = B.user_id
		WHERE B.TipoUser_id = 1 AND (@userId IS NULL OR @userId = A.User_id)
		ORDER BY A.User_id
	END
	ELSE IF @action = 3
	BEGIN --List Sender Mail
		SELECT A.contactMeanOutId AS Id, ISNULL(R.inboundId, 0) AS AcdId, A.isActive AS IsActive
		FROM contactMeanOut A
		LEFT JOIN relationContactMeanOutInbound R ON A.contactMeanOutId = R.contactMeanOutId
		WHERE @senderId IS NULL OR @senderId = A.contactMeanOutId
	END
	ELSE IF @action = 4
	BEGIN --List ACD Whatsapp
		SELECT  inboundId AS Id
		FROM contactMeanIn
		WHERE meanContactTypeId = 5
	END
END'
	 EXEC(@sql)

	-------------------------  END CCC --------------------------------------------------

-------------------------------START CAPACITACION --------------------------------
set @process = 'Correcion ALter SP ccsp_GalateaAdminANIListLD Capacitacion'
        set @sql='ALTER PROCEDURE [dbo].[ccsp_GalateaAdminANIListLD]
@type as tinyint,
@idArea as smallint,
@descriptionList as varchar(40) = NULL,
@idAniList as smallint = NULL,
@cld as varchar(max)= NULL,
@aniTel as varchar(30)= NULL,
@edo as varchar(350) = NULL
AS
set nocount on
declare @pais tinyint, @listEdos varchar(4000), @idLista as integer, @sql as varchar(500)
select @pais = valor from ccsettings where setting_id = 104

select @listEdos = ''select distinct '' + case @type when 1 then
case @pais  when 1  then ''estado as [state] ''
            when 2  then ''estado as [state] ''
            when 3  then ''municipio as [state] ''
            when 4  then ''location as [state] ''
            when 5  then ''cld as [state] ''
            when 6  then ''region as [state] ''
            when 7  then ''region as [state] ''
            when 8  then ''Regiones as [state] ''
            when 9  then ''Regiones as [state] ''
            when 10 then ''Regiones as [state] ''
            when 11 then ''zonaGeografica as [state] ''
            when 12 then ''zonaGeografica as [state] ''
            when 13 then ''zonaGeografica as [state] ''
            when 14 then ''provincia as [state] ''
            else '''' end
when 4 then
case @pais  when 1  then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 2  then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 3  then ''municipio as estado, region +''''''''+ serie as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 4  then ''location as estado, area, @id_anilist as id_anilist, '''''''' as telani ''
            when 5  then ''cld as estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 6  then ''region as estado, LD as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 7  then ''region as estado, CLD as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 8  then ''Regiones as estado, cld +''''-''''+ [serie inicio] as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 9  then ''Regiones as estado, LD + AreaCode as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 10 then ''Regiones as estado, AreaCode as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 11 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 12 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 13 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 14 then ''provincia as estado, indicativoProvincia as area, @id_anilist as id_anilist, '''''''' as telani ''
            else '''' end 
end + ''from '' +
case @pais  when 1  then ''series''
            when 2  then ''seriesarg where estado <> ''''''''''
            when 3  then ''seriescol''
            when 4  then ''ccTimeZoneArea where id_country = '' + convert(varchar(5),@pais) + ''''
            when 5  then ''serieschi''
            when 6  then ''SeriesVen''
            when 7  then ''SeriesUK''
            when 8  then ''SeriesSA''
            when 9  then ''SeriesAU''
            when 10 then ''SeriesBR''
            when 11 then ''SeriesGT''
            when 12 then ''SeriesCR''
            when 13 then ''SeriesSV''
            when 14 then ''SeriesEsp''
            else '''' end + ''''

if @type=1
begin   --Get locations / states
    print (@listEdos + '' order by [state]'')
    exec(@listEdos + '' order by [state]'')
    return(0)
end

if @type=2
begin
    select @sql = ''select id_AniList, description from ccEdoAniList where idArea = '' + convert(varchar(5),@idArea) +  
    case when isnull(@idAniList,'''') <> '''' then '' and id_AniList = '' + convert(varchar(5),@idAniList) else '''' end
    exec(@sql)
    return(0)
end

if @type=3
begin   -- Get Outbound telAni with Area Codes
    select @sql = ''select id_AniList, Estado, telAni, area from ccEstadosAni where id_AniList = '' + convert(varchar(5),@idAniList) + 
    '' and estado like ''''%'' + @edo + ''%'''' and id_AniList in (select id_AniList from ccEdoAniList where idArea = '' +
     convert(varchar(5),@idArea) + '') order by estado''
    exec(@sql)
    --print(@sql)
    return(0)
end

if @type=4
begin  --Insert new aniList
    if @descriptionList <> '''' begin       
        select @idAniList=id_AniList from dbo.ccEdoAniList where [description]=@descriptionList     
        if @idAniList is not null and @idAniList>0
        begin
            select cast(2 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
            return(0)
        end
        insert into ccEdoAniList values(@descriptionList, @idArea)
        select @idLista = id_anilist from ccEdoAniList where [description] = @descriptionList
        set @listEdos = ''insert into ccEstadosAni (estado, area, id_anilist, telani) '' + @listEdos
        set @listEdos = replace(@listEdos, ''@id_anilist'', convert(varchar(6),@idLista))
        exec(@listEdos)
        print(@listEdos)
        select @idAniList=Scope_identity()
        select cast(1 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
        return(0)
    end
    set @idAniList=0
    select cast(0 as int) [result] ,cast(@idAniList as int) as id_AniList,@descriptionList as[description]
    return(0)
end

if @type=5
begin --Save ANI number

    select @descriptionList=[description] from dbo.ccEdoAniList where id_anilist = @idAniList

    update ccEstadosAni set telani= ISNULL(@aniTel, TELANI) WHERE id_anilist = @idAniList 
    and area in (select value from dbo.fn_RIASplitDelimited(@cld, '',''))

    select cast(1 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
    return(0)
end

if @type=6
begin --Delete ANI list
    if not exists(select id_anilist from ccEdoAniList WHERE id_anilist = @idAniList  )
     begin
        select cast(-1 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
        return(0)
     end

     select @descriptionList=[description] from dbo.ccEdoAniList where id_anilist = @idAniList and idarea = @idArea

    delete from ccEstadosAni where id_anilist = @idAniList
    delete from ccEdoAniList WHERE id_anilist = @idAniList

    select cast(1 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
    return(0)
end

if @type=7
begin --Update ANI list name
    if(exists(select [description] from ccEdoAniList where [description]=@descriptionList and id_AniList<>@idAniList))
    begin
        select cast(2 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
        return(0)
    end

    update ccEdoAniList set [description]=@descriptionList where id_AniList=@idAniList
    select cast(1 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
    return(0)
end
'
        EXEC(@sql)

-------------------------------END CAPACITACION --------------------------------
-------------------------------START RESUMEN OPERATIVO --------------------------------
	 set @process = 'K002107-ResumenOperativo se crea tabla'
     set @sql = 'if not exists (select * from sys.tables where name = N''ccWAOperatingSummary'')
begin
    CREATE TABLE [dbo].[ccWAOperatingSummary](
	[Inboundid] [INT] NOT NULL,
	[Attended] [INT] DEFAULT 0,
	[OnQueue] [INT] DEFAULT 0,	
	[Assigned] [INT] DEFAULT 0,
	[Request] [INT] DEFAULT 0,
	[EndedBySystem] [INT] DEFAULT 0,
	[Available] [INT] DEFAULT 0)
end'
	 EXEC(@sql)

     set @process = 'K002107-ResumenOperativo se altera el sp ccsp_WhatsAppInformation'
     set @sql = 'ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformation]
    @Option SMALLINT,
    @InboundId SMALLINT = 0, 
    @ConversationId INT = 0,
	@AgentsAvailables INT = 0,
	@IncreaseDecreaseAgent BIT = NULL

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

                    SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
                           ISNULL(AverageDialogTime, 0) AS AverageDialogTime, 
                           ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime, 
                           ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
                           ISNULL(ServiceLevel, 0) AS ServiceLevel,
						   ISNULL(Attended, 0) AS Attended,
						   ISNULL(Assigned, 0) AS Assigned,
						   ISNULL(OnQueue, 0) AS OnQueue,
						   ISNULL(EndedBySystem, 0) AS EndedBySystem,
						   ISNULL(Available, 0) AS Available,
						   ISNULL(Request, 0) AS Request
                    FROM ccWAAverageConversations conv
					RIGHT JOIN ccWAOperatingSummary summary ON conv.InboundId = summary.InboundId
                    WHERE conv.inboundId = @InboundId OR summary.InboundId = @InboundId
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
					--Save Conversation Assigned
					SELECT @inboundId = inboundId FROM ccWhatsAppConversations where conversationId=@conversationId;
					UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE InboundId = @inboundId
					--EXEC ccsp_WhatsAppOperatingSummary @Option = 2, @InboundId = @CampIdTemp;
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
			IF @Option = 6 -- Agents Availables
			BEGIN
				IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @InboundId)
					BEGIN 
						INSERT INTO ccWAOperatingSummary (InboundId, Available) VALUES (@InboundId, @AgentsAvailables);
					END
				ELSE
					BEGIN
						UPDATE ccWAOperatingSummary SET Available = @AgentsAvailables WHERE InboundId = @InboundId
					END
			END
			
        END
    END
	IF @Option = 0 BEGIN-- Reset TABLES
		TRUNCATE TABLE ccWAOperatingSummary;
		TRUNCATE TABLE ccWAAverageConversations;
		TRUNCATE TABLE ccLastMessageAgentByConversation;
	END
	ELSE IF @Option = 7 -- Reset attended and OnQueue from OperatingSummary 
	BEGIN
		UPDATE ccWAOperatingSummary SET Assigned = 0, OnQueue = 0
	END
    RETURN(0)
    SET NOCOUNT OFF'
     EXEC(@sql)

     set @process = 'K002107-ResumenOperativo se altera sp ccsp_ConversationWASave'
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
											  , @listConversationsIds	VARCHAR(MAX) = NULL 
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

				--Save new request
				IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
					BEGIN 
						INSERT INTO ccWAOperatingSummary (InboundId, Request) VALUES (@inboundId, 1);
					END
				ELSE
					BEGIN
						UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
					END


				
	            RETURN(0);
	        END
	        ELSE
	        BEGIN
				DECLARE @conversationStatusTemp INT = @conversationStatus;
				IF @conversationStatus in(17,18) BEGIN
					SET @conversationStatusTemp = 1
				END
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
	            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
	            SELECT @conversationIdNew = SCOPE_IDENTITY();
				
				INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
																 , conversationIdAfter)
					VALUES (@conversationId, @conversationIdNew);
				--Save new request by reassign
				UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId

            EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

            SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship where conversationIdBefore = @conversationId;
            RETURN(0);
        END;
    END;

    IF @action = 2
    BEGIN --save conversation Times
		DECLARE @conversationIdTemp INT;
		DECLARE @TablaTemp TABLE (conversationId INT, status bit);

		IF @listConversationsIds IS NOT NULL begin
			INSERT INTO @TablaTemp
			SELECT value,0
			FROM fn_RIASplitDelimited(@listConversationsIds, '','')
			where value is not null and value<>''''
		end
		else begin
			INSERT INTO @TablaTemp values(@conversationId,0)
		end
				
		UPDATE ccWhatsAppConversations
		SET                       
		conversationStatus = @conversationStatus
		, finishedBy = case when @conversationStatus = 10 then 2
			when @conversationStatus = 17 then 2
			when @conversationStatus = 18 then 2
			else 1 end
		, tConversation =  case when @conversationStatus = 17 then 0 else DATEDIFF(ss, requestDate, GETDATE()) end
		,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else tQueue end
		,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
		WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

		 WHILE exists(SELECT conversationId FROM @TablaTemp where status=0) 
		BEGIN  
			select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0    
			exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5
			
            IF @conversationStatus in(13,10,17,18,11) BEGIN
				DECLARE @conversationDateTemp INT;
                select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate != null then 1 else 0 end from ccWhatsAppConversations where conversationId = @conversationId;
        
    			IF @conversationStatus = 13 BEGIN    				
    				IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
    					INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
    				END
    			END
                ELSE IF @conversationStatus in(10,17,18) BEGIN --Save conversation Ended by system 
					IF @conversationDateTemp > 0 BEGIN       
						UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
					END
					ELSE BEGIN
						 UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1) WHERE InboundId = @inboundId 
					END                  
                END
                ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT                            
                    UPDATE ccWAOperatingSummary SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId                    
                END
            END
			update @TablaTemp set status=1 where conversationId=@conversationIdTemp
		END

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
			SELECT @inboundId = inboundId FROM ccWhatsAppConversations where conversationId=@conversationId;
			UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
	    END;

    IF @action = 6
    BEGIN --save agent, assigdate and tqueue
		declare @agentIdTmp int
		SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A where A.conversationId = @conversationId

        IF (@agentIdTmp is null or @agentIdTmp=0)
        BEGIN
            UPDATE ccWhatsAppConversations
                   SET agentId = @agentId,
                   assignDate = getdate(),
                   conversationStatus = @conversationStatus
				   ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
            WHERE conversationId = @conversationId;
            
            SELECT @conversationId as conversationId 
	    SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations where conversationId=@conversationId;

	    IF @onQueue = 1 BEGIN 
		UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1) WHERE InboundId = @inboundId
	    END 
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

     set @process = 'K002107-ResumenOperativo se altera ccsp_GalateaDeleteCampaignAndACD'
     set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaDeleteCampaignAndACD]
        --declare
        @userId           SMALLINT,
        @DeleteCamId      VARCHAR(MAX),
        @DeleteACDGroupId VARCHAR(MAX),
        @moduleId         SMALLINT = 49
    AS
    BEGIN

        IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
            SELECT value As DeleteCamId, c.IDArea AS IDAreaCamp, 1 AS CampTypeCamp
            INTO #CampsDelete 
            FROM fn_RIASplitDelimited(@DeleteCamId, '','') a
            inner join ccCamps c on  a.value = c.cam_id and c.IDArea IS NOT NULL
        IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
            SELECT value As DeleteACDId, c.IDArea AS IDAreaACD, 0 AS CampTypeACD
            INTO #ACDDelete 
            FROM fn_RIASplitDelimited(@DeleteACDGroupId, '','') a
            inner join ccInbound c on  a.value = c.Inbound_id and c.IDArea IS NOT NULL

        IF  not Exists (select * from #CampsDelete union select * from #ACDDelete )
        begin 
            select ''-1'' AS Result
            return 
        end

        IF datalength(@DeleteCamId) > 0
            BEGIN

            if exists(select cam_id from ccInbound where cam_id in (select DeleteCamId from #CampsDelete)) begin
                --Borra las calificacion con reprogramacion
                delete ccCalifCamp from ccInbound A 
                inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
                where A.cam_id in (select DeleteCamId from #CampsDelete)
                --Borra las subcalificacion con reprogramacion
                delete rel from ccInbound A 
                inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                inner join ccTipoCalif C on B.calif_id=C.calif_id 
                inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
                inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
                where A.cam_id in (select DeleteCamId from #CampsDelete) and sb.canReprogram=1
        
                update ccInbound set cam_id = null where cam_id in (select DeleteCamId from #CampsDelete)           
             
            end

            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) 
            select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete)

            delete from ccCampsAgente where cam_id in (select DeleteCamId from #CampsDelete)
            insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) 
            select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete) and A.tipo = 1
        
            delete from ccSupervisorCam where cam_id in (select DeleteCamId from #CampsDelete) and tipo = 1
            delete from ccRIACampEspWG where IdCampEsp in (select DeleteCamId from #CampsDelete) and tipo = 1

            IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
            SELECT ca.AreaName,
                   GETDATE() operationDate,
                   27 operationType,
                   (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                   @moduleId module_id,
                   c.cam_descripcion value,
                   ca.AreaName AS target
            INTO #CampLog
            FROM ccRIACat_Areas ca
            Inner join ccCamps c with(nolock) on ca.IDArea = c.IDArea
            WHERE c.cam_id in (select DeleteCamId from #CampsDelete)

            Update ccCamps set IDArea = null where cam_id in (select DeleteCamId from #CampsDelete)

        END
        IF datalength(@DeleteACDGroupId) > 0
            BEGIN

            if exists(select top 1 cam_id from ccInbound where Inbound_id in (select DeleteACDId from #ACDDelete))
                begin
                    update ccInbound set cam_id = null where Inbound_id in (select DeleteACDId from #ACDDelete)
            end

            IF OBJECT_ID(''tempdb..#AllWGACD'') IS NOT NULL DROP TABLE #AllWGACD
            SELECT DISTINCT(IDWG)
            INTO #AllWGACD
            FROM ccRIACampEspWG ce 
            WHERE IDCampEsp in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

            insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) 
            select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG 
            from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id 
            where B.User_id is null and A.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            delete ccInboundHorarios Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
            delete ccInboundMsgs Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) 
            select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 
            from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id 
            where B.User_id is null and A.cam_id in (SELECT DeleteACDId FROM #ACDDelete)

            delete ccSupervisorCam where cam_id in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0
            delete ccInboundAgentes where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
            delete ccRIACampEspWG where IdCampEsp  in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0


            IF OBJECT_ID(''tempdb..#ACDLog'') IS NOT NULL DROP TABLE #ACDLog
            SELECT ca.AreaName,
                    GETDATE() operationDate,
                    28 operationType,
                    (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                    @moduleId module_id,
                    i.descripcion value,
                    ca.AreaName AS target
            INTO #ACDLog
            FROM ccRIACat_Areas ca
            inner join ccInbound i with(nolock) on ca.IDArea = i.IDArea
            WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            Update ccInbound set IDArea = null, status = 0 where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
        
            if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                begin
                    update ContactMeanIn set name = '''', conexionInfo = ''usuarioID|token|tokenSecret|1|0'', connUser = '''', isActive = 0 
                    where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=2
            end
            if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                begin
                    update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=1
            end
            update ccinbound set chatDomain = '''' where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)--para desasociar el dominio del chat
            
            if exists (SELECT inboundId FROM contactMeanIn WHERE inboundId in (select DeleteACDId from #ACDDelete))
                begin
                    update contactMeanIn set isActive = 0 where inboundId in (select DeleteACDId from #ACDDelete)
            end

			if exists (SELECT inboundId FROM ccWhatsAppNumbers WHERE inboundId in (select DeleteACDId from #ACDDelete))
				begin
					update ccWhatsAppNumbers set inboundId = 0 where inboundId in (select DeleteACDId from #ACDDelete)
			end
        END

        IF datalength(@DeleteCamId) > 0
            Insert into ccRIALog Select * from #CampLog
        IF datalength(@DeleteACDGroupId) > 0
            Insert into ccRIALog Select * from #ACDLog
        
        SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result FROM #CampsDelete
        UNION
        SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result FROM #ACDDelete
        IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
        IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
    END'
     EXEC(@sql)
-------------------------------END RESUMEN OPERATIVO --------------------------------   
	 		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
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


