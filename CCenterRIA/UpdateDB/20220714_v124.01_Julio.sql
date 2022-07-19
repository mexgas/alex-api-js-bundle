/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/05/23
Description: Archivo julio 2022, cambios preview

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

IF @actualVersion in(@version,@version-1) and @actualVersionFix >= 53
BEGIN
	BEGIN TRAN

	BEGIN TRY

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

------------------------------ Hugo,  Relaciones de campañas  ---------------------------------
    set @process = 'ALter SP ccsp_GalateaAdminCampaigns Relaciones de campañas'
   	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS      SMALLINT, 
                                               @CampType AS    SMALLINT = 0, 
                                               @WorkgroupId AS INT      = 0, 
                                               @Id AS          INT      = 0, 
                                               @AdminId AS     SMALLINT = 0, 
                                               @PinUpdate AS   SMALLINT = 0, 
                                               @LoadId AS      INT      = 0, 
                                               @Type AS        SMALLINT = 0,
											   @InboundType	   SMALLINT = 0,
											   @AreaId		   SMALLINT = 0
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
                                   CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
                                        CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType
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
                                   CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
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
                print ''xxxx Super''
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
                           CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
                           CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType
                    FROM ccCamps camps (NOLOCK)
                         INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
                         INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
                           --WHERE camps.cam_id = @Id
                           ORDER BY camps.cam_descripcion ASC;
            END;
            ELSE
                BEGIN
                    SELECT DISTINCT 
                           CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
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
									INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND cci.chat = @InboundType;
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
						FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND cci.chat = @InboundType
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
								INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND cci.chat = @InboundType AND isnull(cci.cam_id,-1) = -1
				END
			ELSE
				BEGIN
					SELECT DISTINCT 
					CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
					FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND cci.chat = @InboundType AND isnull(cam_id,-1) = -1
				END
		END
    IF @Option = 15
        BEGIN
            SELECT DISTINCT 
            CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
            FROM ccInbound NOLOCK where cam_id = @Id
        END
END; '
 EXEC(@sql)


------------------------------------ Hugo, Relaciones de campañas  ---------------------------------
    set @process = 'ALter SP ccsp_GalateaAdminDispositions Relaciones de campañas'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
@command int,
@calif_id smallint = null,
@califIdLst varchar(8000) = null,
@description varchar(60)=null,
@order tinyint=null,
@canReprogram bit = null,
@graphColor varchar(15) = null,
@endConversation bit=null,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null,
@finishPreview bit = 0,
@allNumbersToBlacklist bit = 0
AS
set nocount on
declare @inserted table (ID smallint)

if @command=1 -- Load Inbound Dispositions
begin
  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd, graphColor
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation, graphColor
  order by 2
  return(0)
end

If @command=2 -- Load Outbound Dispositions
begin
  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
  IsNull(C.finishPreview,0) as finishPreview, graphColor, allNumbersToBlacklist
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
  C.contactOwner, C.finishPreview, graphColor, allNumbersToBlacklist
  order by 2
  return(0)
end

If @command=3 -- New ccTipoCalif
begin
  If exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@description)
    begin
      select cast(-1 as smallint) [result]	-- Disposition already exists
      return(0)
    end

  If exists(select calif_id from ccTipoCalif where Calif_Status=0 and description=@description)
  begin
	select top 1 @calif_id = calif_id from ccTipoCalif where Calif_Status=0 and description=@description order by calif_id desc
    update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
	graphColor=isnull(@graphColor, ''1DB4E2''), Calif_Status=1
	output inserted.calif_id into @inserted
    where calif_id=@calif_id
	select ID [result] from @inserted 
    return(0)
  end

  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
  output inserted.calif_id into @inserted
  select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalif
  select ID [result] from @inserted
  return(0)
end

If @command=4 -- New ccTipoCalifOUT
begin
  If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
  begin
  select cast(-1 as smallint) [result]	-- Disposition already exists
  return(0)
  end

 If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
 begin
	select top 1 @calif_id = calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description order by calif_id desc
	update ccTipoCalifOut set autoTime=0, orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), idTipoLista=0,
	Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
	finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, ''1DB4E2'')
	output inserted.calif_id into @inserted
	where calif_id=@calif_id
	select ID [result] from @inserted 
	return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor, allNumbersToBlacklist)
 output inserted.calif_id into @inserted
 select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
 isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, ''1DB4E2''), ISNULL(@allNumbersToBlacklist,0) from ccTipoCalifOut
 select ID [result] from @inserted 
 return(0)
end
If @command=5 -- Delete Inbound Dispositions
begin
    delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    return(0)
end
if @command=6 -- Delete Outbound Disposition
begin
	delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
end
if @command=7 -- Update Inbound Disposition
begin
	if(exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@Description and calif_id<>@calif_id))
	begin
		select cast(-1 as smallint) [result]	-- Disposition already exists
		return(0)
	end

	if @canReprogram=1
	begin
		if not exists(select i.Inbound_id from ccCalifCamp cc inner join ccTipoCalif t on cc.calif_id=t.calif_id and tipo=0
		inner join ccInbound i on cc.cam_id=i.Inbound_id where cc.calif_id=@calif_id and i.cam_id is not null)
		begin
			select cast(-2 as smallint) [result]	-- Cant reprogram, there is not assigned campaign
			return(0)
		end
	end

    UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
    canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  
	EndConversation=isnull(@endConversation,EndConversation)
	output inserted.calif_id into @inserted
    where calif_id=@calif_id

    delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	select ID [result] from @inserted
    return(0)
end
if @command=8 -- Update Outbound Disposition
begin
	if(exists(select calif_id from ccTipoCalifOUT where CalifOut_Status=1 and Description=@description and calif_id<>@calif_id))
	begin
		select cast(-1 as smallint) [result]	-- Disposition already exists
		return(0)
	end

	UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
	canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial), 
	autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), 
	finishPreview = isnull(@finishPreview,finishPreview), allNumbersToBlacklist = isnull(@allNumbersToBlacklist, allNumbersToBlacklist)
	output inserted.calif_id into @inserted
	where calif_id=@calif_id

	if @keepDial is not null
	begin
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end

	select ID [result] from @inserted
	return(0) 
	end

set nocount off'
    EXEC(@sql)

----------------------------------- Hugo, Relaciones de campañas  ---------------------------------
    set @process = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                                @InboundId AS SMALLINT = 0,
												@User_id AS SMALLINT = 0,
												@OutboundID AS SMALLINT = 0,
												@multi_cam as varchar(max) = null
	AS
	BEGIN
	    set nocount on;

	    if(@Option = 1) -- Por campaña 
	    begin
	        select 
	            ISNULL(count (*), 0) as Calls,
	            ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
	            ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
	            ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
	            ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
	            ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
	            ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
	            ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
	            ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
	            ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
	            THEN 1 ELSE NULL END), 0) AS Other
	        from ccCallsIn a (nolock)
	        where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId

	    end

		if(@Option = 2) -- Todas las campañas 
	    begin
	        select 
				inbound.Inbound_id as IDEspec,
				inbound.descripcion as Name,
	            ISNULL(count (*), 0) as Calls,
	            ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
	            ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
	            ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
	            ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
	            ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
	            ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
	            ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
	            ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
	            ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
	            THEN 1 ELSE NULL END), 0) AS Other
	        from ccCallsIn a (nolock)
			left join ccInbound inbound on a.inbound_id = inbound.Inbound_id
	        where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) 
			group by inbound.Inbound_id, inbound.descripcion
	    end

		if(@Option = 3) -- Obtiene los datos de las llamadas de todos los ACD, datos que se muestran en el tablero de información del administrador 
	    begin
			SELECT 
				a.inbound_id, calls = ISNULL(COUNT(*), 0), -- calls
				Dialogs = ISNULL(COUNT (CASE WHEN statusCall_id = 13 THEN 1 ELSE NULL END), 0), -- Answered
				DlgsAveTime = ISNULL(SUM (CASE WHEN statusCall_id = 13 THEN cal_tDialog + cal_tNotas ELSE 0 END), 0),
				QueueAveTime =ISNULL( avg( CASE WHEN cal_que > 0 THEN cal_tWait ELSE NULL END), 0) ,
				abandon = ISNULL(COUNT(CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0), -- Abandoned
				OverFlowQueue = ISNULL(COUNT (CASE WHEN statusCall_id =8 THEN 1 ELSE NULL END), 0),
				OverFlowTimeOut = ISNULL(COUNT (CASE WHEN statusCall_id =7 THEN 1 ELSE NULL END), 0), -- OverFlowQueue+OverFlowTimeOut = not answered
				outOfSchedule = ISNULL(COUNT (CASE WHEN statusCall_id =2 THEN 1 ELSE NULL END), 0), -- fuera de horario
				outOfService = ISNULL(COUNT (CASE WHEN statusCall_id =3 THEN 1 ELSE NULL END), 0), -- fuera de servicio
				noAgentsLoggedIn = ISNULL(COUNT (CASE WHEN statusCall_id =4 THEN 1 ELSE NULL END), 0), -- sin agentes firmados
				assigned = ISNULL(COUNT (CASE WHEN statusCall_id =11 THEN 1 ELSE NULL END), 0), -- asignada
				--assignedAndNotAnswered = ISNULL(COUNT (CASE WHEN statusCall_id =15 THEN 1 ELSE NULL END), 0), -- asignada y no contestada
				--assignedAndTookLine = ISNULL(COUNT (CASE WHEN statusCall_id =16 THEN 1 ELSE NULL END), 0), -- asignada y toma linea
				callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0)
				--onQueue = ISNULL(COUNT(CASE WHEN statusCall_id = 5 THEN 1 ELSE NULL END), 0)
				--initCalls = CAST(ISNULL(COUNT(CASE WHEN statusCall_id = 1 THEN 1 ELSE NULL END), 0) AS varchar(7))+''|''+
				--			ISNULL((SELECT STUFF((SELECT ''|'' + cast(ci.cal_id AS varchar(7))
				--			FROM ccCallsin ci (nolock) WHERE cal_inicio > dateadd(mi,-5,getdate()) AND ci.inbound_id=a.inbound_id
				--			FOR XML PATH('''')) ,1,1,'''')),''0'')
			FROM ccCallsIn a (nolock)
			WHERE cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
					--and a.inbound_id in (select cam_id from ccSupervisorCam where user_id = @User_id and tipo = 0)
			GROUP BY a.inbound_id
		--	SET nocount off
		--	return(0)
		end

		if(@Option = 4) -- Carga los ACD del administrador mandado
	    begin
			SELECT cam_id 
			FROM ccSupervisorCam  nolock
			WHERE user_id = @User_id and tipo = 0
			SET nocount off
			return(0)
		end

		IF(@Option = 5) -- Relate the inbound campaign with the outbound campaign
		BEGIN
			IF(@multi_cam is not null)
			BEGIN
				UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id IN (
					SELECT value from dbo.fn_RIASplitDelimited(@multi_cam,'',''))
				SELECT 1;
				RETURN 1;
			END
			IF((SELECT ISNULL(cam_id,-1) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId) != -1)
				BEGIN
					SELECT -1;
					RETURN -1;
				END;
			ELSE
				BEGIN
					UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id = @InboundID;
					SELECT 1;
					RETURN 1;
				END;
		END;        
		IF(@Option = 6) -- Delete the relation between inbound and outbound campaigns
		BEGIN
			UPDATE ccInbound SET cam_id = null WHERE Inbound_id = @InboundId;
			SELECT 1;
			RETURN 1;
		END;
		IF(@Option = 7) -- Check if the inbound Campaign is related
		BEGIN
			SELECT CAST(ISNULL(cam_id,-1) AS INT) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId;
		END
		IF(@Option = 8) -- Delete the relation between inbound campaings which are related to outdbound campaign
		BEGIN
			UPDATE ccInbound SET cam_id = null WHERE cam_id = @OutboundID;
			SELECT 1;
			RETURN 1;
		END
	END
    '
    EXEC(@sql)





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


