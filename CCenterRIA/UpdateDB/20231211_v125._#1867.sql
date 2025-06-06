IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_ccLogAgentesDia_Update'
      AND object_id = OBJECT_ID('ccLogAgentesDia')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_Update
    ON ccLogAgentesDia (user_id, IdCampEsp, fecha);
END



go


ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent] --Corrección del ticket #1867
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady smallint,
@tStatus float,
@TipoCall  tinyint,
@Camp smallint,
@callout_id int=0,
@call_id int=0,
@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog float =0 ,
@currentStatus int =-2,--NUEVO PARAMETRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null,
@tMusicHold int =0,
@isTransferEngine bit = 0
AS

if @Fecha4 is null set @Fecha4 = getdate()

if @TipoCall > 0 set @TipoCall = @TipoCall - 1

 IF @User_id <= 0 OR (@tStatus = 0 AND @TipoStatusAge_id = 30)
        RETURN 0;

declare @cam_id int,@surveycamId int
declare @cal_telefono varchar(30)
declare @cal_key varchar(40)
declare @inbound_id int
declare @callBackSurveyClients bit
declare @cal_whoHung tinyint
DECLARE @cal_tXfer float,   @cal_tRing float
declare @cal_tDialog int
declare @cal_tNotas float
declare @cal_tNotaOri int
declare @tMinAVRS smallint
declare @calInicio datetime
declare @sumCall float
declare @cal_manual int 

set @cal_tNotas =0
set @cal_tNotaOri=0

if @TipoStatusAge_id=32 set @tStatus=CONVERT(DECIMAL(10,2), ROUND(@tStatus, 0, 1))

set @cal_manual =0
--4 Dialog,6 Notas, 27 Notas Fallida

 IF @TipoStatusAge_id IN (4, 6, 27) AND @call_id > 0 and @isLogout=1
BEGIN
   if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
   if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas

   
     if @TipoCall = 0 
     begin -- BEING IN @TipoCall = 0  ---
        SELECT @calInicio = cal_Xfer,
        @sumCall = cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas,
        @Camp = Inbound_id,
        @cal_tDialog = cal_tDialog,
        @cal_tNotaOri = cal_tNotas,
        @cal_key = cal_Key,
        @inbound_id = inbound_id,
        @cal_telefono = cal_ani,
        @cal_whoHung = cal_whoHung,
        @cal_tXfer = cal_tXfer,
        @cal_tRing = cal_tRing
        FROM ccCallsIN WITH (NOLOCK)
        WHERE cal_id = @call_id
        AND statusCall_id = 13

        IF @cal_tXfer = 0 AND @cal_tRing = 0
        BEGIN
            SELECT @cal_tXfer = CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE @cal_tXfer END,
                @cal_tRing = CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE @cal_tRing END
            FROM ccLogAgentesDia WITH (NOLOCK)
            WHERE User_id = @User_id
                AND callID = @call_id
                AND Tipo = @TipoCall
                AND TipoStatusAge_id IN (5, 9)
        END
        IF @cal_tDialog = 0 AND @tDialog > 0            
        BEGIN
            IF @Fecha4 < DATEADD(ms, (@sumCall + @tDialog + @cal_tNotas) * 1000, @calInicio)
            BEGIN
                SET @tStatus = CASE WHEN @tStatus > 0 THEN @tStatus - 1 ELSE @tStatus END

                IF @TipoStatusAge_id = 4
                    SET @tDialog = @tDialog - 1

                IF @TipoStatusAge_id = 6
                BEGIN
                    IF @cal_tNotas > 0
                        SET @cal_tNotas = @cal_tNotas - 1
                    ELSE
                        SET @tDialog = @tDialog - 1
                END
            END

            UPDATE ccCallsIN
            WITH (ROWLOCK)

            SET cal_tDialog = @tDialog,
                cal_tNotas = @cal_tNotas,
                cal_tMoh = @tMusicHold,
                cal_tXfer=@cal_tXfer,
                cal_tRing=@cal_tRing
            WHERE cal_id = @call_id
                AND statusCall_id = 13
        END
        ----------------------------
        IF @isTransferEngine = 1
        BEGIN 
            DECLARE @minimoDialogo TINYINT

            SELECT @minimoDialogo = valor
            FROM ccSettings
            WHERE setting_id = 13

            IF @cal_tDialog < @minimoDialogo
            BEGIN
                --el status 18 es para llamada cortada con transferencia en Reminder
                EXEC ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id, @nStatus = 18
            END
        END
        -----------------------------
     END -- END IN @TipoCall = 0  ---
     Else 
     begin -- BEING IN @TipoCall = 1  ---
        SELECT @calInicio = cal_inicio,
        @sumCall = cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas,
        @cam_id = cam_id,
        @cal_tDialog = cal_tDialog,
        @cal_tNotaOri = cal_tNotas,
        @cal_tXfer = cal_tXfer,
        @cal_tRing = cal_tRing
        FROM ccoCallsOut WITH (NOLOCK)
        WHERE cal_id = @call_id

        SET @Camp = @cam_id

        if @cal_tXfer=0 and @cal_tRing=0 begin
            SELECT @cal_tXfer = CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE @cal_tXfer END,
            @cal_tRing = CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE @cal_tRing END
            FROM ccLogAgentesDia WITH (NOLOCK)
            WHERE User_id = @User_id
            AND callID = @call_id
            AND Tipo = @TipoCall
            AND TipoStatusAge_id IN (5, 9)

        end

        if @cal_tDialog = 0 and @tDialog>0 begin
            IF @Fecha4 < DATEADD(ss, @sumCall + @tDialog + @cal_tNotas, @calInicio)
                BEGIN
                    SET @tStatus = CASE WHEN @tStatus > 0 THEN @tStatus - 1 ELSE @tStatus END

                    IF @TipoStatusAge_id = 4
                        SET @tDialog = @tDialog - 1
                    IF @TipoStatusAge_id = 6
                    BEGIN
                        IF @cal_tNotas > 0
                            SET @cal_tNotas = @cal_tNotas - 1
                        ELSE
                            SET @tDialog = @tDialog - 1
                    END
                END

                UPDATE ccoCallsOut
                WITH (ROWLOCK)
                SET cal_tDialog = @tDialog,
                    totalCall_Time = @tDialog,
                    cal_tNotas = @cal_tNotas,
                    cal_tMoh = @tMusicHold,
                    cal_tXfer = @cal_tXfer,
                    cal_tRing = @cal_tRing
                WHERE cal_id = @call_id
                    AND statusCall_id = 13

        end
        else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
            update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog  
            ,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
            where cal_id = @call_id
        else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
            update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas 
            ,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
            where cal_id = @call_id 
     END -- END OUT @TipoCall = 1  ---
    
    select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

    if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1 and @cal_manual<>1 begin
        insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
    end

    if @TipoStatusAge_id in(6,27) begin
    --Valida que el agente no pudo guardar el status antes de desloguear
    if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
        INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
    end
end --@TipoStatusAge_id IN (4, 6, 27) AND @call_id > 0 and @isLogout=1 --


IF (@TipoStatusAge_id = 4)
BEGIN -- 4 = Dialogo
    DECLARE @tStatus3 FLOAT, @Fecha3 DATETIME

    SELECT TOP 1 @tStatus3 = tstatus, @Fecha3 = fecha
    FROM ccLogAgentesDia WITH (NOLOCK)
    WHERE TipoStatusAge_id = 3 AND user_id = @User_id
    ORDER BY fecha DESC

    INSERT INTO ccLogAgentesDia_Dialog (
        User_id,
        Cam_id,
        fecha_Calc_ms,
        tStatus_Dispo,
        fecha_Dispo,
        tStatus_Dialog,
        fecha_Dialog
        )
    SELECT @User_id, cam_id,
        datediff(ms, dateadd(ms, - (@tStatus3 * 1000), @Fecha3), dateadd(ms, - (@tStatus3 * 1000
                    ), @Fecha4)),
        @tStatus3,
        @Fecha3,
        @tStatus,
        @Fecha4
    FROM cccampsagente
    WHERE user_id = @User_id

    ---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
    IF @call_id > 0
    BEGIN
        IF @TipoCall = 0
        BEGIN --IN
            SELECT @surveycamid = isnull(extend.SurveyCamId, 0),
                @callBackSurveyClients = i.callBackSurveyClient
            FROM ccinbound i
            LEFT JOIN ccInboundExtend extend
                ON i.inbound_id = extend.inbound_id
            WHERE i.inbound_id = @inbound_id

            IF @surveycamId > 0
                AND (
                    @callBackSurveyClients = 1
                    OR @cal_whoHung = 1
                    )
            BEGIN
                IF EXISTS (
                        SELECT cam_id
                        FROM cccamps
                        WHERE cam_id = @surveycamid
                            AND isnull(callsBySurvey, 0) > 0
                            AND isnull(ivrScript, 0) > 0
                        )
                BEGIN
                    IF (
                            SELECT surveyPctg
                            FROM ccCamps
                            WHERE cam_id = @surveycamid
                            ) >= rand() * 100
                    BEGIN
                        INSERT INTO ccoCallsOUTSource (
                            cal_Key,
                            cam_id,
                            cal_telefono,
                            cal_status,
                            cal_fechaDial
                            )
                        VALUES (
                            right((cast(@call_id AS VARCHAR) + '' + @cal_Key), 40),
                            @surveycamid,
                            @cal_telefono,
                            0,
                            dateadd(mi, 6, getdate())
                            )
                    END
                END
            END
        END --@TipoCall = 0
        ELSE
        BEGIN --OUT
            SELECT @surveycamId = isnull(surveycamid, 0),
                @callBackSurveyClients = callBackSurveyClient
            FROM cccamps
            WHERE cam_id = @cam_id

            SELECT @cal_key = cal_Key,
                @cam_id = cam_id,
                @cal_telefono = cal_telefono,
                @cal_whoHung = cal_whoHung
            FROM ccoCallsOUT WITH (
                    INDEX (IX_ccoCallsOut_11),
                    NOLOCK
                    )
            WHERE callout_id = @callout_id
                AND statusCall_id = 13
                AND cal_id = @call_id

            IF @surveycamId > 0
                AND (
                    @callBackSurveyClients = 1
                    OR @cal_whoHung = 1
                    )
            BEGIN
                IF (
                        SELECT surveyPctg
                        FROM ccCamps
                        WHERE cam_id = @surveycamId
                        ) >= rand() * 100
                BEGIN
                    INSERT INTO ccoCallsOUTSource (
                        cal_Key,
                        cam_id,
                        cal_telefono,
                        cal_status,
                        cal_fechaDial
                        )
                    VALUES (
                        right((cast(@call_id AS VARCHAR) + '' + @cal_Key), 40),
                        @surveycamid,
                        @cal_telefono,
                        0,
                        dateadd(mi, 6, getdate())
                        )
                END
            END
        END
    END --@callout_id>0
END --End -- 4 = Dialogo


IF @isLogout = 0 AND @TipoStatusAge_id = 6
BEGIN --- BEGIN Insert ccLogAgentesDia @isLogout = 0 AND @TipoStatusAge_id = 6 -----
    --Valida que el ccserver no haya guardado antes el status antes al desloguear
    IF NOT EXISTS (
            SELECT *
            FROM ccLogAgentesDia WITH (NOLOCK)
            WHERE User_id = @User_id
                AND TipoStatusAge_id = 4
                AND fecha BETWEEN dateadd(ss, - 10, @Fecha4) AND @Fecha4
                AND tStatus = @tStatus + 1
            )
    BEGIN
        INSERT ccLogAgentesDia (
            User_id,
            TipoStatusAge_id,
            tStatus,
            fecha,
            IdCampEsp,
            Tipo,
            currentStatus,
            callID
            )
        VALUES (
            @User_id,
            @TipoStatusAge_id,
            @tStatus,
            @Fecha4,
            @Camp,
            @TipoCall,
            @currentStatus,
            @call_id
            )

        IF NOT EXISTS (
                SELECT *
                FROM [ccLogAgentesDiaLast] with(nolock)
                WHERE User_id = @User_id
                )
        BEGIN
            INSERT [ccLogAgentesDiaLast] (
                User_id,
                TipoStatusAge_id,
                tStatus,
                fecha,
                IdCampEsp,
                Tipo,
                currentStatus,
                callID
                )
            VALUES (
                @User_id,
                @TipoStatusAge_id,
                @tStatus,
                @Fecha4,
                @Camp,
                @TipoCall,
                @currentStatus,
                @call_id
                )
        END
        ELSE
        BEGIN
            -- Bloqueo anticipado para evitar deadlocks
            SELECT 1
            FROM ccLogAgentesDiaLast WITH (UPDLOCK, ROWLOCK)
            WHERE USER_ID = @User_id;

            -- Actualización segura
            UPDATE [ccLogAgentesDiaLast]
            SET TipoStatusAge_id = @TipoStatusAge_id,
                tStatus = @tStatus,
                fecha = @Fecha4,
                IdCampEsp = @Camp,
                Tipo = @TipoCall,
                currentStatus = @currentStatus,
                callID = @call_id
            WHERE USER_ID = @User_id;

        END
    END
END --- END Insert ccLogAgentesDia @isLogout = 0 AND @TipoStatusAge_id = 6 -----
ELSE 
BEGIN --- BEGIN ELSE DIFF -----
    INSERT ccLogAgentesDia (
        User_id,
        TipoStatusAge_id,
        tStatus,
        fecha,
        IdCampEsp,
        Tipo,
        currentStatus,
        callID
        )
    VALUES (
        @User_id,
        @TipoStatusAge_id,
        @tStatus,
        @Fecha4,
        @Camp,
        @TipoCall,
        @currentStatus,
        @call_id
        )

    IF NOT EXISTS (
            SELECT *
            FROM [ccLogAgentesDiaLast] with(nolock)
            WHERE User_id = @User_id
            )
    BEGIN
        INSERT [ccLogAgentesDiaLast] (
            User_id,
            TipoStatusAge_id,
            tStatus,
            fecha,
            IdCampEsp,
            Tipo,
            currentStatus,
            callID
            )
        VALUES (
            @User_id,
            @TipoStatusAge_id,
            @tStatus,
            @Fecha4,
            @Camp,
            @TipoCall,
            @currentStatus,
            @call_id
            )
    END
    ELSE
    BEGIN
        -- Bloqueo anticipado para evitar deadlocks
        SELECT 1
        FROM ccLogAgentesDiaLast WITH (UPDLOCK, ROWLOCK)
        WHERE USER_ID = @User_id;

        -- Actualización segura
        UPDATE [ccLogAgentesDiaLast]
        SET TipoStatusAge_id = @TipoStatusAge_id,
            tStatus = @tStatus,
            fecha = @Fecha4,
            IdCampEsp = @Camp,
            Tipo = @TipoCall,
            currentStatus = @currentStatus,
            callID = @call_id
        WHERE USER_ID = @User_id;

    END
END --- END ELSE DIFF -----


IF (@TipoStatusAge_id = 2)
BEGIN  -- 2 = No Disponible
    INSERT ccLogAgentesNotReady (
        User_id,
        TipoNotReady_id,
        tStatus,
        fecha,
        IdCampEsp,
        Tipo
        )
    VALUES (
        @User_id,
        @TipoNotReady,
        @tStatus,
        @Fecha4,
        @Camp,
        @TipoCall
        )

    ---Para Agente RIA: OAYC
    INSERT ccRIALogAgentesNotReady (
        User_id,
        TipoNotReady_id,
        tStatus,
        fecha
        )
    VALUES (
        @User_id,
        @TipoNotReady,
        @tStatus,
        @Fecha4
        )
END


-- Actualiza para reporte de tiempos especiales (Boan)
IF @Camp > 0
BEGIN
    declare @today datetime=convert(date,getdate(),121)
    IF EXISTS (
            SELECT *
            FROM ccLogAgentesDia WITH (
                    INDEX (IX_ccLogAgentesDia_5),
                    NOLOCK
                    )
            WHERE IdCampEsp = 0
                AND user_id = @User_id
            )
    BEGIN
        -- Bloqueo anticipado para evitar deadlocks
        SELECT 1
        FROM ccLogAgentesDia WITH (UPDLOCK, ROWLOCK)
        WHERE fecha > @today
            AND IdCampEsp = 0
            AND user_id = @User_id;

        -- Actualización segura
        UPDATE ccLogAgentesDia
        SET IdCampEsp = @Camp,
            Tipo = @TipoCall
        WHERE fecha > @today
            AND IdCampEsp = 0
            AND user_id = @User_id;
    END

    IF EXISTS (
            SELECT *
            FROM ccLogAgentesNotReady WITH (
                    INDEX (IX_ccLogAgentesNotReady_4),
                    NOLOCK
                    )
            WHERE IdCampEsp = 0
                AND user_id = @User_id
            )
    BEGIN
        UPDATE ccLogAgentesNotReady
        WITH (ROWLOCK)

        SET IdCampEsp = @Camp,
            Tipo = @TipoCall
        WHERE fecha>@today and
        IdCampEsp = 0
            AND user_id = @User_id
    END
END


IF (
        @TipoStatusAge_id = 34
        AND @call_id > 0
        ) -- Dialogo WhatsApp
BEGIN
    IF @TipoCall = 0
    BEGIN
        UPDATE ccWhatsAppConversations
        SET tChatting = (tChatting + @tStatus)
        WHERE conversationId = @call_id;

        SET @Camp = (
                SELECT inboundId
                FROM ccWhatsAppConversations
                WHERE conversationId = @call_id
                );

        EXEC ccsp_WhatsAppInformation @Option = 2,
            @InboundId = @Camp
    END
    ELSE
    BEGIN
        UPDATE ccWhatsAppConversationsOut
        SET tChatting = (tChatting + @tStatus)
        WHERE conversationId = @call_id;

        SET @Camp = (
                SELECT camId
                FROM ccWhatsAppConversationsOut
                WHERE conversationId = @call_id
                );

        EXEC ccsp_WhatsAppInformationOut @Option = 2,
            @camId = @Camp
    END
END


GO


ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] --Correción del ticket #1867
@Option AS      SMALLINT, 
@CampType AS    SMALLINT = 0, 
@WorkgroupId AS INT      = 0, 
@Id AS          INT      = 0, 
@AdminId AS     SMALLINT = 0, 
@PinUpdate AS   SMALLINT = 0, 
@LoadId AS      INT      = 0, 
@Type AS        SMALLINT = 0,
@InboundType    SMALLINT = 0,
@AreaId         SMALLINT = 0,
@multi_type     varchar(max) = null,
@groupList as varchar (MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type     
    IF @WorkgroupId IS NOT NULL BEGIN
        SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId
        ORDER BY IdCampEsp ASC;
    END;
    ELSE BEGIN
        RAISERROR('ERROR. No existe una lista de campañas con el id de grupo de trabajo especificado', 18, 1);
    END;
    RETURN 0;
END;
IF @Option = 2 BEGIN-- Get Campaign complete information per Campaign Type and Campaign Id      
    IF @CampType = 1 BEGIN-- Campaigns Out      
        IF @Id IS NOT NULL BEGIN
            SELECT DISTINCT 
            CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
            isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
            camps.cam_procesando IsStarted, 
            ISNULL(a.AreaName, '') AS Area, 
            CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
            CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
            CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 ELSE isnull(camps.CampType,0) END as OutboundType,
            ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
            a.ToolsTransfer         
            FROM ccCamps camps
            LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
            LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
            LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
            WHERE camps.cam_id = @Id
            ORDER BY camps.cam_descripcion ASC;
        END;
        ELSE BEGIN
            RAISERROR('ERROR. No existe campañas de salida con el id especificado', 18, 1);
        END;
    END;
    ELSE IF @CampType = 0 -- Campaigns In (ACD)
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    SELECT DISTINCT 
                    CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, 
                    ISNULL(a.AreaName, '') AS Area, 
                            CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType,
                            a.ToolsTransfer
                    FROM ccInbound inb
                            LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                            LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                    WHERE inb.Inbound_id = @Id
                            ORDER BY inb.descripcion ASC;
            END;
            ELSE
                BEGIN
                    RAISERROR('ERROR. No existe campañas de entrada con el id especificado', 18, 1);
            END;
    END;
    RETURN 0;
END;
ELSE IF @Option = 3  BEGIN -- Update OverallTotalNew By Campaign

    IF @Id IS NOT NULL BEGIN
        UPDATE ccCampsNvosCB SET  OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id;
    END;
    ELSE BEGIN
        RAISERROR('ERROR. No existe la campañas de entrada con el id especificado', 18, 1);
    END;
    RETURN 0;
END;
ELSE IF @Option = 4 -- Update Pin from Campaign per Admin
BEGIN
    IF @Id IS NOT NULL
        AND @AdminId IS NOT NULL
    BEGIN
        IF @PinUpdate = 1
        BEGIN
            INSERT INTO PinedCampaigns (CampId, AdminId, Type)
            VALUES (@Id, @AdminId, @Type);
        END;

        IF @PinUpdate = 0
        BEGIN
            DELETE
            FROM PinedCampaigns
            WHERE CampId = @Id
                AND AdminId = @AdminId
                AND Type = @Type;
        END;
    END;
    ELSE
    BEGIN
        RAISERROR ('ERROR. La campañas o administrador no existen', 18, 1
                );
    END;

    RETURN 0;
END;

ELSE IF @Option = 5 BEGIN  -- Get Pin from Campaign Ids per Admin       
    IF @AdminId IS NOT NULL BEGIN
        SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
        ORDER BY Id ASC;
    END;
    ELSE BEGIN
        RAISERROR('ERROR. El administrador con el id seleccionado no existe', 18, 1);
    END;
    RETURN 0;
END;
ELSE IF @Option = 6 -- Get Blacklist Ids by Campaign Id
BEGIN
    IF @Id IS NOT NULL
    BEGIN
        DECLARE @BlackListIds VARCHAR(MAX);

        SELECT @BlackListIds = COALESCE(@BlackListIds + '|' + CAST(idtipolista AS VARCHAR
                    (MAX)), CAST(idtipolista AS VARCHAR(MAX)))
        FROM Camplistanegra
        WHERE cam_id = @Id
            AND STATUS = 1;

        SELECT ISNULL(@BlackListIds, '0') AS BlackListIds;
    END;
    ELSE
    BEGIN
        RAISERROR ('ERROR. La campañas con el id seleccionado no existe', 18, 1);
    END;

    RETURN 0;
END;
            
ELSE IF @Option = 7 -- Get RegistryListIds Ids by Campaign Id
BEGIN
    IF (
            @Id IS NOT NULL
            AND EXISTS (
                SELECT *
                FROM cccamps
                WHERE cam_id = @Id
                )
            )
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
        RAISERROR ('ERROR. No existe una campaña con el id especificado', 18, 1);
    END;

    RETURN 0;
END;

ELSE IF @Option = 8 -- Delete RegistryListIds Ids by LoadId
BEGIN
    IF (
            @LoadId IS NOT NULL
            AND EXISTS (
                SELECT *
                FROM ccRIARegistryLists
                WHERE list_id = @loadID
                    AND STATUS <> 0
                )
            )
    BEGIN
        UPDATE ccoCallsOutSource
        SET cal_status = '5'
        WHERE list_id = @loadID;

        DELETE
        FROM ccoWorkingTable
        WHERE list_id = @LoadId;

        EXEC ccsp_RIARegistryLists @action = 6, @list_id = @LoadId;
    END;
    ELSE
    BEGIN
        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
        RAISERROR ('ERROR. No existe una carga el id especificado', 18, 1);
    END;

    RETURN 0;
END;

ELSE IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
BEGIN
    DECLARE @table TABLE (camId INT, campType TINYINT, PRIMARY KEY (camId, campType)
        );

    INSERT INTO @table
    SELECT DISTINCT IdCampEsp, Tipo
    FROM ccRIACampEspWG wg
    WHERE wg.IDWG IN (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers
            WHERE IDWG <> @WorkgroupId
                AND User_id = @AdminId
            );

    SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
    FROM @table A
    RIGHT JOIN (
        SELECT wg.IdCampEsp, wg.Tipo
        FROM ccRIACampEspWG wg
        WHERE wg.IDWG = @WorkgroupId
        ) B ON A.camId = B.IdCampEsp
        AND A.campType = B.Tipo
    WHERE A.camId IS NULL
    ORDER BY IdCampEsp;

    RETURN 0;
END;

ELSE IF @option = 10 BEGIN -- Get Agents States with totals per campaign by admin id and campaign type
    DECLARE @date DATETIME = CONVERT(DATE, DATEADD(hh, - 3, GETDATE()));
    DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY (id));
    DECLARE @AgentsList TABLE (id INT, PRIMARY KEY (id));
    DECLARE @tmpCamAgent TABLE (
        camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY (camId, userId
            )
        );
    DECLARE @AgentStatus TABLE (CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT
        );
    DECLARE @CurrentStatus TABLE (userId INT, CurrentState INT, IdCampEsp INT, camType INT
        );
    DECLARE @campDataTotal TABLE (
        camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY (camId
            )
        );

    INSERT INTO @AdminWorkgroups
    SELECT DISTINCT IDWG
    FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
    WHERE WG.User_id = @AdminId
        OR (
            R.User_id = @AdminId
            AND R.Rol_id = 7
            );

    INSERT INTO @AgentsList
    SELECT DISTINCT A.User_id
    FROM ccRIAWorkGroupUsers A
    INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
    INNER JOIN ccUsers C ON A.User_id = C.User_id
        AND C.TipoUser_id = 1
    ORDER BY A.User_id;

    INSERT INTO @tmpCamAgent
    SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
                AND @CampType = 0 THEN inbound.chat ELSE NULL END
    FROM ccRIACampEspWG campPerWg
    INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
    INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
    INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
    LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
        AND @CampType = 0
    LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
        AND @CampType = 1
    WHERE C.TipoUser_id = 1
        AND campPerWg.Tipo = @CampType
        AND (
            @Id = 0
            OR campPerWg.IdCampEsp = @Id
            );;

    INSERT INTO @CurrentStatus
    SELECT A.user_id, CASE WHEN A.currentStatus <= 0 THEN 0 ELSE A.currentStatus END AS 
        currentStatus,A.IdCampEsp, A.Tipo
        FROM ccLogAgentesDiaViewLast A
        INNER JOIN @AgentsList B ON A.User_id = B.id
        WHERE fecha >= @date

    IF @Id = 0
        AND @CampType = 0
    BEGIN
        DELETE
        FROM @tmpCamAgent
        WHERE multimediaType = 5
    END

    DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;

    IF @CampType = 1
    BEGIN
        SELECT @MultimediaType = meanContactTypeId
        FROM contactMeanOut
        WHERE camp_id = @Id
    END
    ELSE
    BEGIN
        SELECT @chatType = ci.chat
        FROM dbo.ccInbound AS ci
        WHERE ci.Inbound_id = @Id;

        SELECT @MultimediaType = meanContactTypeId
        FROM contactMeanIn
        WHERE inboundId = @Id
    END

    IF (@chatType = 1)
    BEGIN
        SET @MultimediaType = 1
    END

    DECLARE @StateIds VARCHAR(100) = (
            SELECT CASE WHEN @MultimediaType = 5 THEN '6,34' WHEN @MultimediaType = 1 THEN 
                            '23' ELSE '4,5,6,9' END
            ) -- Add more for multimediaTypes

    ;with stateDialog as(
    SELECT cast(value as int) as CurrentState FROM dbo.fn_RIASplitDelimited(@StateIds,',')
)
    INSERT INTO @AgentStatus
    SELECT A.camId, A.userId, B.CurrentState,
    (CASE
        WHEN @chatType = 1 THEN
            CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) THEN 1 ELSE 0 END
        ELSE
            CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN 1 ELSE 0
        END
    END) AS isCampDialog, B.camType

    FROM @tmpCamAgent A
    INNER JOIN @CurrentStatus B ON A.userId = B.userId
    WHERE (
            @Id = 0
            OR A.camId = @Id
            )

    IF @CampType = 1
    BEGIN
            ;

        WITH campDataTotal
        AS (
            SELECT camId, count(*) total
            FROM @tmpCamAgent A
            GROUP BY camId
            )
        INSERT INTO @campDataTotal
        SELECT A.camId, B.cam_descripcion AS campName, A.Total, C.AreaName AS Area
        FROM campDataTotal A
        INNER JOIN ccCamps B ON A.camId = B.cam_id
        INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END
    ELSE
    BEGIN
            ;

        WITH campDataTotal
        AS (
            SELECT camId, count(*) total
            FROM @tmpCamAgent A
            GROUP BY camId
            )
        INSERT INTO @campDataTotal
        SELECT A.camId, B.descripcion AS campName, A.Total, C.AreaName AS Area
        FROM campDataTotal A
        INNER JOIN ccInbound B ON A.camId = B.Inbound_id
        INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END;

    WITH stateCamp
    AS (
        SELECT A.CampId, count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready, 
            count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34
                            ) THEN 1 WHEN A.CurrentState IN (6, 34, 4
                            )
                        AND (
                            A.CampId != C.IdCampEsp
                            OR A.campType != @CampType
                            ) THEN 1 ELSE NULL END) AS notReady,
                            COUNT(CASE WHEN A.isCampDialog = 1 THEN 1 ELSE NULL END) AS dialog, 
                            COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected
        FROM @AgentStatus A
        INNER JOIN @CurrentStatus C ON A.userId = C.userId
        GROUP BY A.CampId
        )
    SELECT A.camId, A.campName, A.Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady, 
            0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL 
                THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END 
        Disconnected, A.Area
    FROM @campDataTotal A
    LEFT JOIN stateCamp B ON A.camId = B.CampId
    ORDER BY A.campName

    RETURN 0;
END;
ELSE IF @Option = 11 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
    IF NOT EXISTS (
            SELECT *
            FROM ccUsers_Roles WITH (NOLOCK)
            WHERE User_id = @AdminId
                AND Rol_id = 7
            )
    BEGIN
        --print 'xxxx SIn Super'
            ;

        WITH wgId
        AS (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers WITH (NOLOCK)
            WHERE user_id = @AdminId
            )
        SELECT DISTINCT CAST(IdCampEsp AS INT) AS Id
        FROM ccRIACampEspWG A WITH (NOLOCK)
        INNER JOIN wgId ON wgId.IDWG = A.IDWG
            AND A.Tipo = @CampType;
    END;
    ELSE
    BEGIN
        --print 'xxxx Super'
        IF @CampType = 1
        BEGIN
            SELECT DISTINCT CAST(cam_id AS INT) AS Id
            FROM ccCamps WITH (NOLOCK)
            WHERE IDArea IS NOT NULL
        END
        ELSE
        BEGIN
            SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
            FROM ccInbound WITH (NOLOCK)
            WHERE IDArea IS NOT NULL
        END
    END;

    RETURN 0;
END;

ELSE IF @Option = 12 BEGIN-- Get All Campaigns complete information per Campaign Type and Campaign Id
    IF @CampType = 1 -- Campaigns Out
    BEGIN
                    SELECT DISTINCT 
                    CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
                    isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
                    camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
                    CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, 
                    CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 ELSE isnull(camps.CampType,0) END as OutboundType,
                    ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
        FROM ccCamps camps(NOLOCK)
        INNER JOIN ccRIACampsGraph graph(NOLOCK) ON camps.cam_id = graph.cam_id
        INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = camps.IDArea
        LEFT JOIN ccCampsExtend extended(NOLOCK) ON camps.cam_id = extended.cam_id
        ORDER BY camps.cam_descripcion ASC;
    END;
    ELSE
    BEGIN
        SELECT DISTINCT CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, isnull
            (CAST(graph.graphic_id AS INT), 1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(
                inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea AS INT) AS 
            AreaId, inb.chat AS InboundType, 0 AS OutboundType
        FROM ccInbound inb(NOLOCK)
                            INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
        INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = inb.IDArea
        ORDER BY inb.descripcion ASC;
    END;

    RETURN 0;
END;

ELSE IF @Option = 13
BEGIN
    BEGIN
        IF NOT EXISTS (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                    AND Rol_id = 7
                )
        BEGIN
            IF @CampType = 1
            BEGIN
                WITH wgId
                AS (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS CampId,
                                    cam_descripcion AS Description,
                                    isnull(IDArea, -1) AS AreaID,
                                    CAST(-1 AS SMALLINT) AS CampaignType,
                                    CAST(-1 AS INT) AS RelatedCampId,
                                    CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
                                    CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
                                    CAST(1 AS INT) As CampType
                FROM ccRIACampEspWG A
                INNER JOIN wgId ON wgId.IDWG = A.IDWG
                    AND A.Tipo = 1
                                    INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id
                                    LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
            END
            ELSE
            BEGIN
                WITH wgId
                AS (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS CampId,
                                    descripcion AS Description,
                                    isnull(IDArea, -1) AS AreaID,
                                    CAST(chat AS SMALLINT) AS CampaignType,
                                    CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                    CAST(chat AS INT) AS Channel,
                                    CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                    CAST(0 AS INT) As CampType
                FROM ccRIACampEspWG A(NOLOCK)
                INNER JOIN wgId ON wgId.IDWG = A.IDWG
                    AND A.Tipo = 0
                INNER JOIN ccInbound cci(NOLOCK) ON A.IdCampEsp = cci.Inbound_id
                                    LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                                    LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                                    AND ((@multi_type is null AND cci.chat = @InboundType)
                                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,','))));
            END
        END;
        ELSE
        BEGIN
            IF @CampType = 1
            BEGIN
                        SELECT DISTINCT 
                                CAST(ccc.cam_id AS INT) AS CampId,
                                cam_descripcion AS Description,
                                isnull(IDArea, -1) AS AreaID,
                                CAST(-1 AS SMALLINT) AS CampaignType,
                                -1 AS RelatedCampId,
                                CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
                                CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
                                CAST(1 AS INT) As CampType
                        FROM ccCamps AS ccc (NOLOCK) 
                            LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
                        where IDArea = @AreaId
            END
            ELSE
            BEGIN
                        SELECT DISTINCT 
                                CAST(cci.Inbound_id AS INT) AS CampId,
                                descripcion AS Description,
                                isnull(IDArea, -1) AS AreaID,
                                CAST(chat AS SMALLINT) AS CampaignType,
                                CAST(chat AS INT) AS Channel,
                                CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                CAST(0 AS INT) As CampType
                FROM ccInbound cci(NOLOCK)
                            LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                            LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                        where IDArea = @AreaId
                        AND ((@multi_type is null AND cci.chat = @InboundType)
                            OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,','))))

            END
        END;

        RETURN 0;
    END;
END;
ELSE IF @Option = 14
BEGIN
    IF NOT EXISTS (
            SELECT *
            FROM ccUsers_Roles NOLOCK
            WHERE User_id = @AdminId
                AND Rol_id = 7
            )
    BEGIN
        WITH wgId
        AS (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers NOLOCK
                                WHERE user_id = @AdminId)
                            SELECT DISTINCT 
                                CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
        FROM ccRIACampEspWG A(NOLOCK)
        INNER JOIN wgId ON wgId.IDWG = A.IDWG
            AND A.Tipo = 0
                                INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND isnull(cci.cam_id,-1) = -1
                                AND ((@multi_type is null AND cci.chat = @InboundType)
                                    OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,','))))

    END
    ELSE
    BEGIN
                    SELECT DISTINCT 
                    CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                    FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND isnull(cam_id,-1) = -1
                    AND ((@multi_type is null AND cci.chat = @InboundType)
                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,','))))

    END
END

ELSE IF @Option = 15
BEGIN
            SELECT DISTINCT 
            CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
            FROM ccInbound NOLOCK where cam_id = @Id
END
ELSE IF @Option = 16 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
    IF @groupList IS NOT NULL BEGIN
        IF OBJECT_ID('tempdb..#WGDelete') IS NOT NULL DROP TABLE #WGDelete;
        SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, ',')
        SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type, IDWG AS IdWg FROM ccRIACampEspWG WHERE IDWG in (select IDwg from #WGDelete)
        ORDER BY IdCampEsp ASC;
    END;
    ELSE BEGIN
        RAISERROR('ERROR. No existe una lista de campañas con los ids de grupo de trabajo especificados', 18, 1);
    END;
    RETURN 0;
END;

END;


