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
    set @process = 'CW-PREVIEW se aumenta un bit a TipoDialingMode '
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

    set @process = 'CW-PREVIEW se modifica funcion para tipo de marcacion preview '
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


