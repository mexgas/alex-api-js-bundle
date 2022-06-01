/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/05/23
Description: Archivo mayo 2022, cambios preview

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
SET @versionfix = 31
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

	set @process = 'CW-PREVIEW se agrega campo para permiso descarte en campañas preview'
    set @sql = 'IF not exists(SELECT top 1 1
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE COLUMN_NAME = ''previewDiscard'' AND TABLE_NAME = ''cccamps'')
		BEGIN
			alter table cccamps add previewDiscard bit null
		END'
	EXEC(@sql)

	set @process = 'CW-PREVIEW se agrega la operacion del permiso de descarte de campañas preview'
    set @sql = 'IF not exists(SELECT top 1 1 FROM ccRIALog_Operation WHERE operationType=191)
		BEGIN
			insert ccRIALog_Operation values (191,''PERMISO PARA DESCARTAR|PERMISSION TO DISCARD'')
		END'
	EXEC(@sql)

    set @process = 'CW-PREVIEW se agrega type para campaigns preview'
    set @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS      SMALLINT, 
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
                           CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
                           CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType
                    FROM ccCamps camps
                         INNER JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                         INNER JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
                           --WHERE camps.cam_id = @Id
                           ORDER BY camps.cam_descripcion ASC;
            END;
            ELSE
                BEGIN
                    SELECT DISTINCT 
                           CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
                    FROM ccInbound inb
                         INNER JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                         INNER JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                           ORDER BY inb.descripcion ASC;
            END;
            RETURN 0;
    END;
END;'
    EXEC(@sql)
    set @process = 'CW-PREVIEW se aumenta un bit a TipoDialingMode ccsp_DLRSaveDialResult'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRSaveDialResult] 
                    @callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
                    @tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
                    @canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '''', @cal_key VARCHAR(40)= '''', @call_TS VARCHAR(15)=
                    ''''
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @tNow AS DATETIME, @RecicleSIC TINYINT;
        DECLARE @logDial_id INT;
        DECLARE @tAnswerBitFinal AS DATETIME;
        DECLARE @tTotal SMALLINT;

        SELECT @RecicleSIC = ISNULL(valor, 0)
        FROM ccSettings
        WHERE setting_id = 60;

        SELECT @tTotal = @tDialing + @tAnswerBit;

        SELECT @tNow = GETDATE();

        SELECT @tAnswerBitFinal = DATEADD(ss, -@tAnswerBit, @tNow);

        IF @call_id > 0 AND 
           @tipoResDial_id = 1
        BEGIN
            INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
            TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id )
                   SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
                   ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.
                   fnGetTipoLlamada( @Telefono );
        END;
             ELSE
        BEGIN
            INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
            TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id )
                   SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
                   ''000000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(
                   @Telefono );
        END;

        SELECT @logDial_id = SCOPE_IDENTITY();

        IF @RecicleSIC = 1
        BEGIN
            UPDATE ccoWorkingTable WITH(ROWLOCK)
              SET tipoResDial_id = @tipoResDial_id
            WHERE callout_id = @callout_id;
        END;

        -- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
        IF @call_id > 0 AND 
           @tipoResDial_id = 1
        BEGIN
            UPDATE ccoCallsOut WITH(ROWLOCK)
              SET cal_puerto = @Puerto, cal_manual = CASE
                                                     WHEN cal_manual = 1 THEN 2
                                                          ELSE cal_manual
                                                     END
            WHERE cal_id = @call_id AND 
                  cal_puerto = 0;

            EXEC ccsp_CstoCalculaCosto @call_id;

            IF @cal_key = ''''
            BEGIN
                SELECT @cal_key = cal_key
                FROM ccoCallsOutSource WITH(NOLOCK)
                WHERE @callout_id = callout_id;

                UPDATE ccologdials WITH(ROWLOCK)
                  SET cal_key = @cal_key
                WHERE logDial_id = @logDial_id;
            END;
        END;


        --2020-06-04 para marcaciones manuales no efectivas guarda el cal_id
                        if @call_id > 0 and @tipoResDial_id != 1
                        begin
                            update ccologdials with(rowlock) set cal_id=@call_id where logDial_id=@logDial_id
                        end

        -- inserta informacion para reportes de workgroup
        INSERT INTO ccRIAWorkGroup_logDial_id( IDWG, logDial_id, cam_id, TIMESTAMP )
               SELECT IDWG, @logDial_id, IdCampEsp, GETDATE()
               FROM ccRIACampEspWG
               WHERE tipo = 1 AND 
                     IdCampEsp = @cam_id;

        -- Guarda configuracion de TipoDialingMode
        UPDATE ccoLogDials WITH(ROWLOCK)
          SET TipoDialingMode = dbo.fn_getDialingMode( @call_id, 0, @logDial_id, @cam_id )
        WHERE logDial_id = @logDial_id;
        SET NOCOUNT OFF;
    END;

        SELECT @logDial_id as LogDialId'
    EXEC(@sql)

    set @process = 'CW-PREVIEW se modifica funcion fn_getDialingMode para tipo de marcacion preview '
    set @sql = '
    ALTER function [dbo].[fn_getDialingMode](@call_id int, @TipoDialingMode tinyint, @logDial_id int, @cam_id int)
returns nvarchar(9)
as
begin
    declare @valor nvarchar(9), @calif_id smallint, @califSub_id smallint, @cal_manual tinyint, @keepDial char(1)
    set @keepDial=''0''

    -- En el caso de que no cuente con cal_id, se debe contar con logDial_id, por lo cual se busca el registro
    if @call_id is null
     begin
        select top 1 @call_id=o.cal_id from ccoLogDials l with(nolock,index(PK_ccoLogDials)) join ccocallsout o with(nolock,index(IX_ccoCallsOut_2))
            on l.callout_id = o.callout_id and l.Puerto = o.cal_puerto
        where l.logDial_id = @logDial_id and l.fecha between convert(varchar(19), dateadd(minute, -5, o.cal_inicio), 121)
        and convert(varchar(19), dateadd(minute, 5, o.cal_inicio), 121)
        order by datediff(ss, l.fecha, o.cal_inicio) asc -- en caso de tener mas de uno, toma el que tenga menor diferencia en tiempo
     end

    if @cam_id is null
     begin
        select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual, @cam_id=cam_id
        from ccocallsout O with(nolock,index(PK_ccoCallsOut))
        where O.cal_id = @call_id
     end
    else
     begin
        select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual
        from ccocallsout O with(nolock,index(PK_ccoCallsOut))
        where O.cal_id = @call_id
     end

    select @valor=isnull((select case when progDial=3 then ''100'' when progDial=2 then ''010'' when progDial=1 then ''001'' else ''000'' end + cast(iTipoDial as char(1)) + cast(abandonCallback as char(1))
     + cast(excCallback as char(1)) from cccamps where cam_id=@cam_id), ''000000'')

    if ((select keepDial from ccTipoCalifOUT where calif_id = @calif_id)=1
    or (select keepDial from ccTipoCalifSubOUT where califSub_id = @califSub_id)=1)
        set @keepDial=''1''

    select @valor = @valor + @keepDial + case @cal_manual when 1 then ''10'' when 2 then ''01'' else ''00'' end
    
      select @valor=substring(@valor, 1, 3) +
      case @TipoDialingMode when 6 then ''1'' else substring(@valor, 4, 1) end + substring(@valor, 5, 2) +
      case @TipoDialingMode when 3 then ''1'' else substring(@valor, 7, 1) end + substring(@valor, 8, 2)
      
 return @valor
end'
    EXEC(@sql)

    set @process = 'CW-PREVIEW modifica columna TipoDialingMode'
    set @sql = '
        ALTER TABLE [dbo].[ccoLogDials] ALTER COLUMN [TipoDialingMode] [varchar](9) NULL;'
    EXEC(@sql)

    set @process = 'CW-PREVIEW se agrega login en [ccsp_AgentTransfLstArea]'
    set @sql = '
    ALTER PROCEDURE [dbo].[ccsp_AgentTransfLstArea]
@userID INT,
@current INTEGER = 0
AS
set nocount on

BEGIN
declare @value int

set @value = 0
select @value = case when valor=''1'' then 1 else 0 end from ccSettings (nolock) where setting_id = 191

    IF @value = 0
        begin
            select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name,login from ccusers cu (nolock) join
            (
                select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp (nolock)
                join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
            )
            x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
            Order by name asc
        end

    if @value = 1
        begin
            if (@current <> 0)
                begin
                    select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name,login from ccusers cu (nolock) join
                    (
                        select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp (nolock)
                        join ccmonitorext ce (nolock) on cp.ext_id = ce.ext_id where user_id > 0
                    )
                    x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
                    and IDArea in (select cu.IDArea from ccUsers cu join ccInbound ci (nolock) on cu.IDArea = ci.IDArea where inbound_id =  @current)
                    Order by name asc
                end
            else
                begin
                    select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name,login from ccusers cu (nolock) join
                    (
                        select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp (nolock)
                        join ccmonitorext ce (nolock) on cp.ext_id = ce.ext_id where user_id > 0
                    )
                    x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
                    and IDArea in (select IDArea from ccUsers (nolock) where User_id = @userID)
                    Order by name asc
                end
        end
END
       
       '
    EXEC(@sql)

    set @process = 'PREVIEW bug de horarios'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_CampHorario]
@campId as int
AS

declare @horaUniversal datetime
declare @isShudulerLey bit, @valueShudulerLey varchar(max),@hourStart int,@hourEnd int,@minStart int,@minEnd int
declare @shourStart varchar(max),@shourEnd varchar(max),@timeMaxContestacion tinyint,@revHorario bit

set @timeMaxContestacion=30

select @revHorario=valor from ccsettings where setting_id = 112
select @valueShudulerLey = valor from ccsettings where setting_id=166
select @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)) as int),@valueShudulerLey=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
select @timeMaxContestacion=cam_tNoContesta from cccamps where cam_id=@campId

if @valueShudulerLey='''' begin
 set @valueShudulerLey=''0|07:00|22:00''
 update ccsettings set valor=@valueShudulerLey where setting_id=166
end
if @isShudulerLey = 1 begin
 select @shourStart=substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)),@shourEnd=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
 select @hourStart=substring(@shourStart, 0, charindex('':'',@shourStart)),@minStart=substring(@shourStart, charindex('':'',@shourStart) + 1, len(@shourStart))
 select @hourEnd=substring(@shourEnd, 0, charindex('':'',@shourEnd)),@minEnd=substring(@shourEnd, charindex('':'',@shourEnd) + 1, len(@shourEnd))
end
else begin
 select @hourStart=0,@minStart=0,@hourEnd=23,@minEnd=59
end

SET DATEFIRST 1
set @horaUniversal = getutcdate()

select h.horario_id,Descripcion,
 case when HoraInicio>@hourStart then HoraInicio else @hourStart end HoraInicio,
 case when (horaInicio>@hourStart or (horaInicio=@hourStart and MinInicio>=@minStart) ) then MinInicio  else @minStart end MinInicio,
 case when horaFin<@hourEnd then horaFin else @hourEnd end HoraFin,
 case when ((horaFin < @hourEnd or (horaFin=@hourEnd and MinFin<=@minEnd) )) then MinFin  else @minEnd end MinFin,
 Lunes,Martes,Miercoles,Jueves,Viernes,Sabado,Domingo
 into #tempCampLaw
 from cchorarios h
 inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on h.horario_id = ccCampsHorarios.horario_id and ccCampsHorarios.cam_id = @campId
 --where  horaInicio between @hourStart and @hourEnd or horaFin between @hourStart and @hourEnd


select distinct horario_id,HoraInicio,MinInicio,horaFin,MinFin into #tempCampLaw2 from
(
 select tz_id,
 dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
 datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora,
 datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
 datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
 from ccTimeZones
)zonas
inner join #tempCampLaw on
(
 (
  hora > HoraInicio OR  (hora = HoraInicio AND minuto >= MinInicio)
 )
 AND
 (
  hora < HoraFin  OR  (hora = HoraFin AND minuto <= (MinFin-@timeMaxContestacion) )
 )
 AND
 (
  Lunes  = dia or
  Martes *2 = dia or
  Miercoles*3 = dia or
  Jueves*4 = dia or
  Viernes*5 = dia or
  Sabado*6 = dia or
  domingo*7 = dia
 )

)

select distinct #tempCampLaw2.horario_id id,
(HoraInicio*3600)+(MinInicio*60) ini,
(HoraFin*3600)+(MinFin*60) fin,
(case when HoraInicio<10 then ''0''+convert(varchar(2),HoraInicio) else convert(varchar(2),HoraInicio) end) + '':'' + (case when MinInicio<10 then ''0''+convert(varchar(2),MinInicio) else convert(varchar(2),MinInicio) end ) as HoraInicio ,
(case when HoraFin<10 then ''0''+convert(varchar(2),HoraFin) else convert(varchar(2),HoraFin) end) + '':'' + (case when MinFin<10 then ''0''+convert(varchar(2),MinFin) else convert(varchar(2),MinFin) end ) as HoraFin
into #tempCamp from #tempCampLaw2

select id,min(ini) ini,max(fin) fin,min(HoraInicio) HoraInicio,max(HoraFin) HoraFin,@timeMaxContestacion timeMaxContestacion
 from(
select distinct min(a.id) id,(a.ini) ini,(case when a.fin>b.fin then a.fin else b.fin end) fin,min(a.HoraInicio) HoraInicio,
max(case when a.fin>b.fin then a.HoraFin else b.HoraFin end) HoraFin
 from #tempCamp a, #tempCamp b
where a.fin>b.ini and b.ini between a.ini and a.fin and a.id <> b.id
group by a.ini,(case when a.fin>b.fin then a.fin else b.fin end)
union
select a.* from #tempCamp a
where a.id not in(select distinct b.id from #tempCamp a, #tempCamp b where a.fin>b.ini and b.ini between a.ini and a.fin and a.id <> b.id)
)x
group by id
order by ini



drop table #tempCamp
drop table #tempCampLaw
drop table #tempCampLaw2
'
    EXEC(@sql)
    set @process = 'PREVIEW se agrega permiso de descarte permiso en ccsp_GalateaGetOutboundConfiguration'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
@adminID int,
@campID int
AS
BEGIN

    declare @AllCampaigns table 
    (cam_id smallint, cam_Descripcion varchar(40), cam_tNotas smallint, cam_ocupado smallint,cam_noInt_ocupado smallint, cam_inter_ocupado smallint,
    cam_nocontesto smallint, cam_noInt_nocontesto smallint, cam_inter_nocontesto smallint, cam_fax smallint, cam_noInt_fax smallint, cam_inter_fax smallint,
    cam_modomanual smallint, ANI varchar(15), cam_ShowCalifWnd bit, cam_StartTimerOnHangUp bit, editableCallKey bit, cam_tNoContesta smallint, iTipoDial smallint,
    detectAnswerMachine smallint,detectVoiceMail smallint, compliance smallint, cam_inter_graba smallint, cam_noint_graba smallint, progDial smallint, excCallBack smallint, dialOrder smallint,
    dialPrefix varchar(10),dialPrefixMan varchar(10), dialPrefixXfe varchar(10),listenManualCall bit,  stopRecording bit,abandonCallback bit, frame smallint,
    t_autoCB smallint, id_anilist int, tDialonWrapUp smallint, viewMode tinyint, queSize smallint, DNCScrub int, callerIdDesc varchar (15), timeZoneRule int,
    callsBySurvey int, ivrScript int, surveyPctg int,call_record smallint,startStopRecording bit,  leaveRecMessage  bit, manualCallOnChat bit, 
    callBackSurveyAgent bit, callBackSurveyClient bit, isRelationSurvey bit, funcEspDtmf int,  sipHdrFormat varchar(255), cam_inter_cancelled smallint, 
    prefijo varchar(40),enbleprefix bit,exitAssisted bit,previewDiscard bit )
     
        INSERT INTO @AllCampaigns EXEC ccsp_RIAConfCamp @adminID, @campID

        SELECT dialPrefixMan DialPrefixMan, dialPrefixXfe DialPrefixXfe, listenManualCall  ListenManualCall, stopRecording StopRecording, abandonCallback AbandonCallBack,
        t_autoCB AutoCB,id_anilist IdIstANI,tDialonWrapUp TDialOnWrapup, queSize Quesize, DNCScrub, callerIdDesc CallerIdDesc, timeZoneRule TimeZoneRule,callsBySurvey CallsBySurvey,
        ivrScript IvrScript, surveyPctg SurveyPctg, call_record CallRecord,startStopRecording StartStopRecording, leaveRecMessage LeaveRecMessage,manualCallOnChat ManualCallOnChat,
        callBackSurveyClient CallBackSurveyClient, callBackSurveyAgent CallBackSurveyAgent, funcEspDtmf FuncEspDtmf,sipHdrFormat SipHdrsCfg, dialPrefix DialPrefix,
        prefijo Prefix, dialOrder DialOrder, progDial ProgDial, cam_Descripcion CamDescription, cam_tNotas CamTnotas, cam_ocupado CamBusy, cam_noInt_ocupado CamNoIntBusy,
        cam_inter_ocupado CamInterBusy,cam_nocontesto CamNoAnswer, cam_noInt_nocontesto CamNoIntNoAnswer,cam_inter_nocontesto CamInterNoAnswer, (cam_inter_cancelled/60) CamInterCancelled,
        cam_fax CamFax, cam_noInt_fax CamNoIntFax,cam_inter_fax CamInterFax, cam_modomanual CamModoManual,ANI ,cam_StartTimerOnHangUp CamStartTimerOnHangUp,
        editableCallKey EditableCallKey, cam_tNoContesta CamTNoAnswer, iTipoDial  CamIntensiveDialing, detectAnswerMachine DetectAnswerMachine, detectVoiceMail DetectVoiceMail, 
        compliance Compliance, cam_inter_graba CamInterRecord,cam_noint_graba CamNoIntRecord,excCallBack ExcCallBack, cam_ShowCalifWnd CamShowCalifWnd, frame Frame, exitAssisted ExitAssistedDialMode, previewDiscard PreviewDiscard
        from @AllCampaigns WHERE cam_id = @campID
END'
    EXEC(@sql)

    set @process = 'PREVIEW se agregan phones en ccsp_GalateaGetPreviewData, y tambien nolock'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetPreviewData]
        @callout_id int 

        AS
        set nocount on

        select''previewData''=
         ISNULL(P.Headers,'''')+''~''+
         ISNULL(O.Dato1,'''')+''~''+
         ISNULL(O.Dato2,'''')+''~''+
         ISNULL(O.Dato3,'''')+''~''+
         ISNULL(O.Dato4,'''')+''~''+
         ISNULL(O.Dato5,'''')+''~''+
         ISNULL(P.Dato6,'''')+''~''+
         ISNULL(P.Dato7,'''')+''~''+
         ISNULL(P.Dato8,'''')+''~''+
         ISNULL(P.Dato9,'''')+''~''+
         ISNULL(P.Dato10,'''')+''~''+
         ISNULL(P.Dato11,'''')+''~''+
         ISNULL(P.Dato12,'''')+''~''+
         ISNULL(P.Dato13,'''')+''~''+
         ISNULL(P.Dato14,'''')+''~''+
         ISNULL(P.Dato15,'''')+''~''+
         ISNULL(O.cal_telefono2,'''')+''~''+
         ISNULL(O.cal_telefono3,'''')+''~''+
         ISNULL(O.cal_telefono4,'''')+''~''+
         ISNULL(O.cal_telefono5,'''')+''~''
               from ccoCallsOutSource O (nolock)
        INNER JOIN ccoCallsPreviewData P (nolock) on O.cal_Key=P.Cal_key and O.cam_id=P.cam_id
        Where callout_id=@callout_id;
        set nocount off

'
    EXEC(@sql)

    set @process = 'PREVIEW se actualiza el modo de marcacion del agente cuando no tiene campañas preview'
    set @sql = 'ALTER PROCedure [dbo].[ccsp_GalateaManageWG]
@option smallint,
@IDWG smallint,
@Type smallint = 0,
@usersList varchar(max) ='''',
@ListCampsIn varchar(max) = '''',
@ListCampsOut varchar(max) ='''',
@idNewArea int = 0
as
set nocount on
declare @count int
declare @id int
declare @user int
declare @IDCampEsp varchar(max)
declare @Assigned  varchar(max)
declare @AssignedCampsIn  varchar(max)
declare @AssignedCampsOut  varchar(max)

set @id = 1
set @Assigned = ''''
set @AssignedCampsIn = ''''
set @AssignedCampsOut = ''''


IF OBJECT_ID(''tempdb..#UsersList'') IS NOT NULL DROP TABLE #UsersList;
IF OBJECT_ID(''tempdb..#CampsInOutList'') IS NOT NULL DROP TABLE #CampsInOutList;

select *  into #CampsInOutList from (
select ROW_NUMBER() OVER(ORDER BY [CampEsp] ASC) AS Row, [CampEsp], [Type] from (
    select 0 as [Type],
    [value] As [CampEsp]
    FROM fn_RIASplitDelimited(@ListCampsIn, '','') where [value] > 0
    union
    select 1 as [Type],
    [value] As [CampEsp]
    FROM fn_RIASplitDelimited(@ListCampsOut, '','') where [value] > 0
    ) as Camps ) as CampsInOut


select ROW_NUMBER() OVER(ORDER BY value ASC) AS Row,
    value As user_id
    into #UsersList
    FROM fn_RIASplitDelimited(@usersList, '','')

select @count = count(user_id) from #UsersList

if @option = 1 -- Insert Agente-Supervisor in WorkGroup
 begin

    while @id<=@count
    begin
        select @user = user_id from #UsersList where Row= @id
        select @Type = tipoUser_id from ccUsers where user_id = @user

        if @Type in(1, 2, 6)
        begin

            if not exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
            begin
            

                If @Type = 1
                 begin

                        If (select count(User_id) from ccRIAWorkGroupUsers where User_id = @user) < (select valor from ccSettings where setting_id = 63)
                         begin
                            insert into ccRIAWorkGroupUsers(IDWG, User_id) values(@IDWG,@user)
                            select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                            --insert skill media
                            exec ccsp_Skills @action= 5,@userId=@user

                            insert into cccampsAgente (user_id, cam_id, prioridad, skill, IDWG)
                            select @user, idCampEsp, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
                            from ccRIACampEspWG where tipo = 1 and IDWG = @IDWG and
                             idCampEsp not in (select cam_id from cccampsAgente where user_id=@user and IDWG=@IDWG)

                            insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, IDWG)
                            select @user, idCampEsp, 0, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
                            from ccRIACampEspWG where tipo = 0 and IDWG = @IDWG and
                            idCampEsp not in (select inbound_id from ccInboundAgentes where user_id=@user and IDWG=@IDWG)

                            if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
                                insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
                            end
                        end
                 end
                 else if @Type in(2, 6)
                 begin
                    -- -Supervisor  @Type in (2,6)
                    insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @user)
                    select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                    if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
                        insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
                    end

                    insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                    select @user, idCampEsp, 0, @IDWG
                    from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
                     and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)

                    update ccSupervisorCam
                    set monitored = 1
                    where user_id = @user
                    and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)
                    and tipo = 0
                    and IDWG <> @IDWG
                    and monitored = 0

                    insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                    select @user, idCampEsp, 1, @IDWG
                    from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
                     and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)

                    update ccSupervisorCam
                    set monitored = 1
                    where user_id = @user
                    and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)
                    and tipo = 1
                    and IDWG <> @IDWG
                    and monitored = 0
                end
                
            end
        end
        set @id = @id+1
    end
end




if @option = 2 -- Delete Agent-Supervisor from WorkGroup
 begin

    while @id<=@count
    begin
        select @user = user_id from #UsersList where Row= @id
        select @Type = tipoUser_id from ccUsers where user_id = @user
        
        if @Type = 1 --delete skill media
        exec ccsp_Skills @action= 4,@userId=@user,@idwg=@IDWG
        
        if exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
        begin
        
            Delete ccRIAWorkGroupUsers where IDWG = @IDWG and User_id = @user
        
            if @Type = 1 -- Agente
             begin
                select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG   from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
                insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG

                delete from cccampsagente where user_id=@user and IDWG=@IDWG
                delete from ccInboundagentes where user_id=@user and IDWG=@IDWG

                --update preview permission
                update ccusers set 
                AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
                DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
                select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
                where progDial=3 and user_id = @user group by user_id)c on us.User_id=c.user_id
                where us.user_id = @user
                --select @Type
             end
             else if @Type in(2, 6) -- Supervisor
             begin
                select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
                delete ccSupervisorCam where user_id=@user and IDWG=@IDWG
                --select @Type
            end
        end
        set @id = @id+1
    end
end
if @option in (1,2)
begin
    if LEN(@Assigned) > 0
        select SUBSTRING(@Assigned,0,Len(@Assigned))
    else
        select @Assigned

    return(0)
end

if @option = 3 -- Insert WorkGroup in Camp or ACDGroup  
  begin
    select @count = count(CampEsp) from #CampsInOutList

    while @id<=@count
    begin
         select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id
         

         if (select count(IdCampEsp) from ccRIACampEspWG where IdCampEsp=@IDCampEsp and Tipo=@Type) < (select valor from ccSettings where setting_id=180) -- limit
             begin

                if (select count(IDWG) from ccRIACampEspWG where IDWG=@IDWG) < (select valor from ccSettings where setting_id=64) -- limit
                    begin

                        if not exists (select IDWG from ccRIACampEspWG where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) -- No existe el grupo en el ACD o Especialidad
                        begin

                            insert into ccRIACampEspWG (IDWG, Tipo, IdCampEsp, priority) values (@IDWG, @Type, @IDCampEsp, 1)
                            if not exists(select * from ccRIACampEspWGConsulta where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) begin
                                insert into ccRIACampEspWGConsulta (IDWG, Tipo, IdCampEsp) values (@IDWG, @Type, @IDCampEsp)
                            end
                

                            exec ccsp_RIACalcula_WGPriority @IDWG, @IDCampEsp, @Type
                            if @Type in (0, 1) -- ACDGroup
                            begin

                                if @IDWG is not null or @IDWG = 0
                                begin
                                    if @Type=0 --ACDGroup
                                    begin
                                        select @AssignedCampsIn = @AssignedCampsIn+ cast(@IDCampEsp as varchar(5))+'',''
                                        insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
                                        SELECT distinct u.user_id, @IDCampEsp, 0 cli_id, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG 
                                        FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
                                            join ccusers s on u.user_id = s.user_id
                                        WHERE c.tipo=0 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and c.IDWG=@IDWG 
                                        and u.User_id not in (select User_id from ccInboundAgentes where Inbound_id=@IDCampEsp and IDWG=@IDWG)

                                        insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                                        select b.user_id, @IDCampEsp, 0, @IDWG
                                        from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
                                            join ccusers s on b.user_id = s.user_id
                                        where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=0
                                            and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=0 and IDWG=@IDWG)
             
                                        --return(0)
                                    end

                                    else if @Type = 1 -- Camp
                                    begin
                                        select @AssignedCampsOut = @AssignedCampsOut+ cast(@IDCampEsp as varchar(5))+'',''
                                        insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
                                        SELECT distinct u.user_id, @IDCampEsp, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG
                                        FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
                                        join ccusers s on u.user_id = s.user_id
                                        WHERE c.tipo=1 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and u.IDWG=@IDWG 
                                            and u.User_id not in (select User_id from ccCampsAgente where cam_id=@IDCampEsp and IDWG=@IDWG)
            
                                        insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                                        select b.user_id, @IDCampEsp, 1, @IDWG
                                        from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
                                            join ccusers s on b.user_id = s.user_id
                                        where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=1
                                            and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=1 and IDWG=@IDWG)
                                    end
                            end
                        end
                    end
                end
            end
        set @id = @id + 1
   end
end

if @option = 3
begin
    
if LEN(@AssignedCampsIn) > 0 or LEN(@AssignedCampsOut) > 0
        select SUBSTRING(@AssignedCampsIn,0,Len(@AssignedCampsIn)) as CampsInAssigned, SUBSTRING(@AssignedCampsOut,0,Len(@AssignedCampsOut)) as CampsOutAssigned 
    else
        select @AssignedCampsIn as CampsInAssigned, @AssignedCampsOut as CampsOutAssigned

    return(0)
end

if @option = 4  --Delete relatoion Camp with WG
begin
declare @multipleAgents varchar(1000)
declare @multipleAdmins varchar(2000)
declare @sql varchar(max)

select @count = count(CampEsp) from #CampsInOutList
 while @id<=@count
  begin

        select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id

        SELECT @multipleAgents = coalesce(@multipleAgents + '','', '''') + CAST(A.user_id AS VARCHAR(40))
        FROM ccRIAWorkGroupUsers A
        JOIN ccUsers B ON A.user_id = B.user_id
        WHERE IDWG = @IDWG AND TipoUser_id = 1

        SELECT @multipleAdmins = coalesce(@multipleAdmins + '','', '''') + CAST(A.user_id AS VARCHAR(40))
        FROM ccRIAWorkGroupUsers A
        JOIN ccUsers B ON A.user_id = B.user_id
        WHERE IDWG = @IDWG AND TipoUser_id = 2

        --Delete Agent from WorkGroup
           set @sql = ''ccsp_RIA_ABCAgents @option=7,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
                    @AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAgents+''''''''
           exec(@sql)

         --Delete Supervisor from WorkGroup

         set @sql = ''ccsp_RIA_ABCAgents @option=8,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
                    @AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAdmins+''''''''
           exec(@sql)

        --Delete WokGroup from ACD or Camp 

         set @sql = ''exec ccsp_RIA_ABCWorkGroups @option=7,@IDWG=''+cast(@IDWG as varchar(4))+'',@IDCampEsp=''''''+cast(@IDCampEsp as varchar(4))+'''''',@Type=''+cast(@Type as varchar(4))+''''
         exec(@sql)
        set @id = @id + 1
    
    end

    select 1
    return 0
end

if @option = 5  --Change Admin Administrator.
begin
declare @user_id int
select @user_id = value FROM fn_RIASplitDelimited(@usersList, '','')
select @Type = TipoUser_id from ccUsers where User_id = @user_id

        if @Type = 1 -- Agente
        begin

            if(select count(user_id) from ccCampsAgente where user_id = @user_id) >0 or 
            (select count(user_id) from ccInboundAgentes where user_id = @user_id) >0 or
            (select count(user_id) from ccRIAWorkGroupUsers where user_id = @user_id) > 0
            begin
                select -1
                return 0
            end
            else
                update ccUsers set IDArea = @idNewArea where user_id = @user_id
        end

        
    if @Type in (2, 6) -- Supervisor
    begin

        if(select count(user_id) from ccSupervisorCam where user_id = @user_id) > 0 or
        (select count(user_id) from ccRIAWorkGroupUsers where user_id = @user_id) > 0
        begin
            select -1
            return 0
        end
        else
            update ccUsers set IDArea = @idNewArea where user_id = @user_id
    end

    update ccPosicion set user_id = 0 where user_id = @user_id

    select 1

end

set nocount off


'
    EXEC(@sql)

    set @process = '[ccsp_GalateaDeleteCampaignAndACD] se agrega linea para delete ccInboundDnis'
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
            delete ccInboundDnis where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
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

    set @process = 'PREVIEW  se agrega top y nolock a [ccsp_RegProcessPreviewRecord]'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RegProcessPreviewRecord](
        @process smallint,
        @callout_id int,
        @agent_id smallint,
        @camId int)
        AS
        DECLARE @result_callout_id INT
        if(exists(select top 1 1 from ccoWorkingTable nolock where callout_id = @callout_id)) begin
            set @result_callout_id =1
        end
        IF (@result_callout_id > 0)
        BEGIN
            INSERT INTO RegProcessPreviewRecord(userId,process,callout_id,camId,reg_date) VALUES (@agent_id,@process,@callout_id,@camId,SYSDATETIME())
        END
        IF (@process = 1 AND @result_callout_id > 0)
        BEGIN
            DELETE ccoWorkingTable WHERE callout_id = @callout_id
        END'
    EXEC(@sql)

    set @process = 'PREVIEW se actualiza el permiso del agente cuando ya no tienes campañas preview '
    set @sql = '
          ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
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
            return(0)
            end
          set nocount off
          '
    EXEC(@sql)

    set @process = 'PREVIEW se agrega permisos para descarte en campañas preview'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
@User_id smallint,
@campID int =null
AS
set nocount on
declare @tableExistsRec table (camId int primary key,existRec bit)
declare @camByUser table (camId int primary key,isCheck bit)
declare @camId int,@id int;

IF Not EXISTS
    (
        SELECT *
        FROM ccUsers_Roles
        WHERE User_id = @User_id
                AND Rol_id = 7
    )begin
    insert into @camByUser 
    select *,0 from dbo.fGet_CampAcd_Area (@User_id, 1) B 
    where @campID is null or cam_id=@campID
end
else begin
    insert into @camByUser 
    select cam_id,0 from ccCamps 
    where (IDArea>0 or IDArea is null)
    and (@campID is null or cam_id=@campID)
end


while exists(select * from @camByUser where isCheck=0)
begin
    select top 1 @camId=camId  from @camByUser where isCheck=0 
    if exists(select cam_id from ccoCallsOut where cam_id=@camId) begin
        insert into @tableExistsRec values(@camId,1)
    end
    else begin
        insert into @tableExistsRec values(@camId,0)
    end

    update  @camByUser  set isCheck=1 where camId=@camId
end


            

select a1.cam_id, cam_Descripcion
, cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
, cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
, cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
, detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
, cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
, stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, 
cam_maxqueue as queSize,
DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
    ,cast (startStopRecording as tinyint)startStopRecording, leaveRecMessage, manualCallOnChat
,callBackSurveyAgent,callBackSurveyClient,case when surveycamid is null or surveycamid = 0 then 0 else 1 end isRelationSurvey,isnull(a1.funcEspDtmf,0)
,isnull(sipHdrFormat, '''') sipHdrFormat
,cam_inter_cancelled
,prefijo,   enbleprefix = case when existRec = 0 then 1 else 0 end,
isnull(exitAssisted, 0) exitAssisted, isnull(previewDiscard, 0) PreviewDiscard
from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
inner join @tableExistsRec a4 on a1.cam_id=a4.camId
--where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
order by cam_descripcion
return(0)
set nocount off'
    EXEC(@sql)

    set @process = 'PREVIEW se agrega permiso de descarte para update campañas'
    set @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
                @cam_id smallint,
                @cam_descripcion varchar(40) = null,
                @cam_tnotas smallint = null,
                @cam_ocupado tinyint = null,
                @cam_NoInt_ocupado tinyint = null,
                @cam_inter_ocupado smallint = null,
                @cam_nocontesto tinyint = null,
                @cam_NoInt_nocontesto tinyint = null,
                @cam_inter_nocontesto smallint = null,
                @cam_fax tinyint = null,
                @cam_NoInt_fax tinyint = null,
                @cam_inter_fax smallint = null,
                @cam_ModoManual tinyint= null,
                @ANI varchar(15) = null,
                @cam_ShowCalifWnd bit = null,
                @cam_StartTimerOnHangUp bit = null,
                @editableCallKey bit = null,
                @cam_tNoContesta tinyint = null,
                @cam_intensive_dialing tinyint = null,
                @detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
                @detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
                @compliance TinyInt = null,
                @cam_inter_graba smallint = null,
                @cam_NoInt_graba tinyint = null,
                @progDial smallint = null,
                @excCallBack Tinyint = null,
                @dialOrder Tinyint = null,
                @dialPrefix varchar(10) = null,
                @dialPrefixMan varchar(10) = null,
                @dialPrefixXfe varchar(10) = null,
                @listenManualCall bit = null,
                @stopRecording bit = null,
                @abandonCallback bit = null,
                @autoCB smallint = null,
                @id_listAni int = null,
                @tDialonWrapUp smallint = null,
                @quesize smallint=null,
                @DNCScrub int=null,
                @callerIdDesc varchar(15)=null,
                @timeZoneRule int=null,
                @callsBySurvey int=null,
                @ivrScript int=null,
                @surveyPctg int=null,
                @call_record tinyint=null,
                @dRestrictPlay bit = null,
                @leaveRecMessage bit = null,
                @manualCallOnChat bit = null,
                @callBackSurveyClient bit = null,
                @callBackSurveyAgent bit = null,
                @funcEspDtmf int =null,
                @sipHdrsCfg varchar(255) = null,
                @cam_inter_cancelled smallint = null,
                @prefijo varchar(max) = null,
                @exitAssisted bit = null,
                @previewDiscard bit = null
                as
                set nocount on
                UPDATE ccCamps SET
                 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
                 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
                 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
                 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
                 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
                 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
                 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
                 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
                 cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
                 cam_fax = isnull(@cam_fax,cam_fax),
                 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
                 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
                 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
                 ANI = isnull(@ANI,ANI),
                 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
                 editableCallKey = isnull(@editableCallKey, editableCallKey),
                 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
                 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
                 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
                 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
                 compliance = isnull(@compliance, compliance),
                 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
                 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
                 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
                 progDial = isnull(@progDial, progDial),
                 excCallBack = isnull(@excCallBack,excCallBack),
                 dialOrder = isnull(@dialOrder, dialOrder),
                 dialPrefix = isnull(@dialPrefix, dialPrefix),
                 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
                 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
                 listenManualCall = isnull(@listenManualCall, listenManualCall),
                 stopRecording = isnull(@stopRecording, stopRecording),
                 abandonCallback = isnull(@abandonCallback, abandonCallback),
                 t_autoCB = isnull(@autoCB,t_autoCB),
                 id_anilist = isnull(@id_listAni,id_anilist),
                 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
                 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
                 cam_maxqueue = isnull(@quesize,cam_maxqueue),
                 DNCScrub = isnull(@DNCScrub,DNCScrub),
                 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
                 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
                 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
                 ivrScript = isnull(@ivrScript,ivrScript),
                 surveyPctg = isnull(@surveyPctg,surveyPctg),
                 call_record = isnull(@call_record,call_record),
                 startStopRecording = isnull(@dRestrictPlay, startStopRecording),
                 leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
                 manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
                 callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
                 callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
                 funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
                 sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
                 prefijo = isnull(@prefijo, prefijo),
                 exitAssisted = isnull(@exitAssisted, exitAssisted),
                 previewDiscard = isnull(@previewDiscard, previewDiscard)
                Where cam_id = @cam_id

                if @cam_ShowCalifWnd = 1
                 begin
                 If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
                  begin
                  select 0
                  return(0)
                  end

                 UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
                 where cam_id = @cam_id
                 select 1
                 return(0)
                  end

                --else
                UPDATE ccCamps SET
                cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
                where cam_id = @cam_id
                select 2
                return(0)
                set nocount off'
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


