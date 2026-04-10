	USE [CCenterRIA]

	DECLARE @process VARCHAR(MAX), @sql VARCHAR(MAX);
GO
		ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
        @command int,
        @calif_id smallint = null,
        @califIdLst varchar(8000) = null,
        @description varchar(150)=null,
        @order tinyint=null,
        @canReprogram bit = null,
        @graphColor varchar(15) = null,
        @endConversation bit=null,
        @keepDial bit=null,
        @autoCB bit=null,
        @contactOwner bit=null,
        @finishPreview bit = 0,
        @allNumbersToBlacklist bit = 0,
        @FinishRecordPreview bit = 0,
        @Name_cal varchar(150) = null,
        @Description_cal varchar(100) = null,
        @ReturnCall smallint = null,
        @AplTransfer bit = 0,
        @TransferOpcion smallint = 0,
        @DestinyIVR bit = 0,
        @DestinyIVR_camp smallint = null,
        @DestinyIVR_number varchar(20) = null,
        @DestinyIVR_directory smallint = null,
        @AplExtDate bit = 0,
        @ExtDescription varchar(100) = null,
        @AplBlackList bit = 0,
        @Cali_StatusIA bit = 1,  
        @DirectoryNumberFlag bit = 1,
        @user_id INT = NULL,
        @type TINYINT = NULL,
        @acdId SMALLINT = NULL,
        @directoryId SMALLINT = NULL


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
          IsNull(C.finishPreview,0) as finishPreview, graphColor, allNumbersToBlacklist, ISNULL(C.FinishRecordPreview,0) as FinishRecordPreview
          from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
          where C.CalifOut_Status=1
          group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
          C.contactOwner, C.finishPreview, graphColor, allNumbersToBlacklist, C.FinishRecordPreview
          order by 2
          return(0)
        end

        If @command=3 -- New ccTipoCalif
        begin
          If exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@description)
            begin
              select cast(-1 as smallint) [result]  -- Disposition already exists
              return(0)
            end

          If exists(select calif_id from ccTipoCalif where Calif_Status=0 and description=@description)
          begin
            select top 1 @calif_id = calif_id from ccTipoCalif where Calif_Status=0 and description=@description order by calif_id desc
            update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
            graphColor=isnull(@graphColor, '1DB4E2'), Calif_Status=1
            output inserted.calif_id into @inserted
            where calif_id=@calif_id
            select ID [result] from @inserted 
            return(0)
          end

          insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
          output inserted.calif_id into @inserted
          select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, '1DB4E2') from ccTipoCalif
          select ID [result] from @inserted
          return(0)
        end

        If @command=4 -- New ccTipoCalifOUT
        begin
          If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
          begin
          select cast(-1 as smallint) [result]  -- Disposition already exists
          return(0)
          end

         If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
         begin
            select top 1 @calif_id = calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description order by calif_id desc
            update ccTipoCalifOut set autoTime=0, orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), idTipoLista=0,
            Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
            finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, '1DB4E2'), FinishRecordPreview = isnull(@FinishRecordPreview,0)
            output inserted.calif_id into @inserted
            where calif_id=@calif_id
            select ID [result] from @inserted 
            return(0)
         end

         insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor, allNumbersToBlacklist,FinishRecordPreview)
         output inserted.calif_id into @inserted
         select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
         isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, '1DB4E2'), ISNULL(@allNumbersToBlacklist,0), FinishRecordPreview = isnull(@FinishRecordPreview,0) from ccTipoCalifOut
         select ID [result] from @inserted 
         return(0)
        end
        If @command=5 -- Delete Inbound Dispositions
        begin
            delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
            delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
            update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
            return(0)
        end
       if @command=6 -- Delete Outbound Disposition
begin
    declare @cams table (cam_id int)

    insert into @cams
    select distinct cam_id
    from ccCalifCamp
    where tipo = 1
    and calif_id in (
        select value from dbo.fn_RIASplitDelimited(@califIdLst, ',')
    )

    -- deletes
    delete from ccCalifCamp 
    where tipo=1 
    and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))

    delete from cctipoSubCalifRel 
    where tipoSubRel=0 
    and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))

    update ccTipoCalifOUT 
    set CalifOut_Status=0 
    where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))

    update ccCamps 
    set keepDial = dbo.fn_keepDial_Camps(cam_id)
    where cam_id in (select cam_id from @cams)

    select 200 as ResponseCode, 'SUCCESS' as ResponseCodeDescription

end
        if @command=7 -- Update Inbound Disposition
        begin
            if(exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@Description and calif_id<>@calif_id))
            begin
                select cast(-1 as smallint) [result]    -- Disposition already exists
                return(0)
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
                select cast(-1 as smallint) [result]    -- Disposition already exists
                return(0)
            end

            UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
            canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial), 
            autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), 
            finishPreview = isnull(@finishPreview,finishPreview), allNumbersToBlacklist = isnull(@allNumbersToBlacklist, allNumbersToBlacklist),  FinishRecordPreview = isnull(@FinishRecordPreview,FinishRecordPreview)
            output inserted.calif_id into @inserted
            where calif_id=@calif_id

            if @keepDial is not null
            begin
                update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
            end

            select ID [result] from @inserted
            return(0) 
            end


        if @command=9 
        begin
            Select 
                C.calif_id, 
                C.Name_cal as Description, 
                C.Description_cal, 
                C.CanReprogram, 
                C.autoCallback as autocallback, 
                C.ReturnCall,
                C.AplTransfer, 
                C.TransferOpcion, 
                C.DestinyIVR, 
                C.DestinyIVR_camp, 
                C.DestinyIVR_number, 
                C.DestinyIVR_directory,
                C.AplExtDate, 
                C.ExtDescription, 
                C.AplBlackList,
                C.Cali_StatusIA as CaliStatusIA,
                C.Color as graphColor,
                C.DirectoryNumberFlag
            from cctipoCalif_IA C 
            where C.Cali_StatusIA = 1
            order by C.Name_cal
            return(0)
        end
    
       If @command = 10 -- New ccTipoCalif_IA
                begin
                    declare @newId smallint

                    if @DestinyIVR_number IS NOT NULL AND @DestinyIVR_number <> ''
                        set @DirectoryNumberFlag = 0
                    else if @DestinyIVR_directory IS NOT NULL AND @DestinyIVR_directory <> 0
                        set @DirectoryNumberFlag = 1

                    if exists (select 1 from cctipoCalif_IA where Cali_StatusIA = 1 and Name_cal = @Name_cal)
                    begin
                        select cast(-1 as smallint) as [result]  
                        return(0)
                    end

                    if exists (select 1 from cctipoCalif_IA where Cali_StatusIA = 0 and Name_cal = @Name_cal)
                    begin
                        select top 1 @calif_id = calif_id 
                        from cctipoCalif_IA 
                        where Cali_StatusIA = 0 and Name_cal = @Name_cal 
                        order by calif_id desc

                        update cctipoCalif_IA
                        set 
                            Name_cal              = @Name_cal,
                            Description_cal       = @Description_cal,
                            CanReprogram          = isnull(@canReprogram, 0),
                            autoCallback          = isnull(@autoCB, 0),
                            ReturnCall            = @ReturnCall,
                            Color                 = isnull(@graphColor, '1DB4E2'),
                            AplTransfer           = isnull(@AplTransfer, 0),
                            TransferOpcion        = isnull(@TransferOpcion, 0),
                            DestinyIVR            = isnull(@DestinyIVR, 0),
                            DestinyIVR_camp       = @DestinyIVR_camp,
                            DestinyIVR_number     = @DestinyIVR_number,
                            DestinyIVR_directory  = @DestinyIVR_directory,
                            AplExtDate            = isnull(@AplExtDate, 0),
                            ExtDescription        = @ExtDescription,
                            AplBlackList          = isnull(@AplBlackList, 0),
                            Cali_StatusIA         = 1,
                            DirectoryNumberFlag   = isnull(@DirectoryNumberFlag, 1)
                        output inserted.calif_id into @inserted
                        where calif_id = @calif_id

                        select ID [result] from @inserted
                        return(0)
                    end

                    select @calif_id = isnull(max(calif_id), 0) + 1 from cctipoCalif_IA

                    insert into cctipoCalif_IA (
                        calif_id,
                        Name_cal,
                        Description_cal,
                        CanReprogram,
                        autoCallback,
                        ReturnCall,
                        Color,
                        AplTransfer,
                        TransferOpcion,
                        DestinyIVR,
                        DestinyIVR_camp,
                        DestinyIVR_number,
                        DestinyIVR_directory,
                        AplExtDate,
                        ExtDescription,
                        AplBlackList,
                        Cali_StatusIA,
                        DirectoryNumberFlag
                    )
                    output inserted.calif_id into @inserted
                    values (
                        @calif_id,
                        @Name_cal,
                        @Description_cal,
                        isnull(@canReprogram, 0),
                        isnull(@autoCB, 0),
                        @ReturnCall,
                        isnull(@graphColor, '1DB4E2'),
                        isnull(@AplTransfer, 0),
                        isnull(@TransferOpcion, 0),
                        isnull(@DestinyIVR, 0),
                        @DestinyIVR_camp,
                        @DestinyIVR_number,
                        @DestinyIVR_directory,
                        isnull(@AplExtDate, 0),
                        @ExtDescription,
                        isnull(@AplBlackList, 0),
                        1,                                  
                        isnull(@DirectoryNumberFlag, 1)
                    )

                    select ID [result] from @inserted
                    return(0)
                end
    
            -- Comando 11: DELETE_IA_BOUND_DISPOSITION
            if @command=11 -- Delete IA Bound Disposition
            begin
                delete from ccCalifCamp where tipo=2 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
                delete from cctipoSubCalifRel where tipoSubRel=2 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
                update ccTipoCalif_IA set Cali_StatusIA=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
                -- Agregar aquí cualquier limpieza adicional específica para IA si es necesario
                return(0)
            end
    
            if @command=12 -- Update IA Bound Disposition
                begin
                    if(exists(select calif_id from ccTipoCalif_IA where Cali_StatusIA=1 and Name_cal=@Name_cal and calif_id<>@calif_id))
                    begin
                        select cast(-1 as smallint) [result]    -- Disposition already exists
                        return(0)
                    end

                    if @DestinyIVR_number IS NOT NULL AND @DestinyIVR_number <> ''
                        set @DirectoryNumberFlag = 0
                    else if @DestinyIVR_directory IS NOT NULL AND @DestinyIVR_directory <> 0
                        set @DirectoryNumberFlag = 1

                    UPDATE ccTipoCalif_IA set Name_cal=isnull(@Name_cal, Name_cal), Description_cal=isnull(@Description_cal, Description_cal),
                    CanReprogram=isnull(@canReprogram, CanReprogram), Color=isnull(@graphColor, Color), autoCallback=isnull(@autoCB, autoCallback),
                    ReturnCall=isnull(@ReturnCall, ReturnCall), AplTransfer=@AplTransfer, TransferOpcion=@TransferOpcion,
                    DestinyIVR=@DestinyIVR, DestinyIVR_camp=@DestinyIVR_camp,
                    DestinyIVR_number=@DestinyIVR_number, DestinyIVR_directory=@DestinyIVR_directory,
                    AplExtDate=@AplExtDate, ExtDescription=@ExtDescription, DirectoryNumberFlag=isnull(@DirectoryNumberFlag, DirectoryNumberFlag),
                    AplBlackList=@AplBlackList, Cali_StatusIA=isnull(@Cali_StatusIA, Cali_StatusIA)
                    output inserted.calif_id into @inserted
                    where calif_id=@calif_id

                    select ID [result] from @inserted
                    return(0)
                end

IF @command = 13  -- DELETE IA
BEGIN  
    BEGIN TRY  

        -- 0. Validación inicial
        IF @califIdLst IS NULL OR LTRIM(RTRIM(@califIdLst)) = ''
        BEGIN
            SELECT -10 AS ResponseCode,
                   'califIdLst is empty' AS ResponseCodeDescription,
                   '' AS CalifIdLst
            RETURN
        END

        DECLARE @Ids TABLE (calif_id INT)  
        DECLARE @Active TABLE (calif_id INT)  
        DECLARE @ToDelete TABLE (calif_id INT)  

        -- 1. Parseo de IDs
        INSERT INTO @Ids  
        SELECT TRY_CAST(value AS INT)  
        FROM dbo.fn_RIASplitDelimited(@califIdLst, ',')  
        WHERE TRY_CAST(value AS INT) IS NOT NULL

        IF NOT EXISTS (SELECT 1 FROM @Ids)
        BEGIN
            SELECT -11 AS ResponseCode,
                   'No valid IDs received' AS ResponseCodeDescription,
                   '' AS CalifIdLst
            RETURN
        END

        -- 2. Detectar activos (solo campañas ACTIVAS)
        INSERT INTO @Active  
        SELECT DISTINCT c.calif_id  
        FROM ccCalifCampIA c  
        INNER JOIN @Ids i ON i.calif_id = c.calif_id  
        WHERE 
        (
            c.tipo = 1 AND EXISTS (
                SELECT 1 
                FROM ccCamps o
                WHERE o.cam_id = c.cam_id 
                  AND o.cam_procesando = 1
            )
        )
        OR
        (
            c.tipo = 0 AND EXISTS (
                SELECT 1 
                FROM ccInbound ib
                WHERE ib.Inbound_id = c.cam_id 
                  AND ib.Status = 1
            )
        )

        -- 3. Determinar eliminables
        INSERT INTO @ToDelete  
        SELECT i.calif_id 
        FROM @Ids i
        LEFT JOIN @Active a ON i.calif_id = a.calif_id
        WHERE a.calif_id IS NULL

        -- 4. Si TODOS están activos → NO borrar nada
        IF NOT EXISTS (SELECT 1 FROM @ToDelete)
        BEGIN  
            SELECT 
                -27 AS ResponseCode,  
                'All dispositions are active in campaigns.' AS ResponseCodeDescription,
                '' AS CalifIdLst
            RETURN  
        END  

        -- 5. ELIMINACIÓN REAL
        UPDATE cctipoCalif_IA  
        SET Cali_StatusIA = 0  
        WHERE calif_id IN (SELECT calif_id FROM @ToDelete)  

        DELETE FROM ccCalifCampIA  
        WHERE calif_id IN (SELECT calif_id FROM @ToDelete)  

        -- 6. LOG
        IF EXISTS (SELECT 1 FROM @ToDelete)
        BEGIN
            INSERT INTO ccGalateaActivityLog  
(Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)  
SELECT   
    'Default',  
    GETDATE(),  
    ISNULL(u.Login, 'system'),  
    177,
    7,  
    CAST(c.calif_id AS VARCHAR),
    c.Name_cal,  
    'Deleted Disposition'
FROM cctipoCalif_IA c
LEFT JOIN ccUsers u ON u.User_id = @user_id
WHERE c.calif_id IN (SELECT calif_id FROM @ToDelete)
        END

        -- 7. RESPUESTA

        -- Parcial
        IF EXISTS (SELECT 1 FROM @Active)
        BEGIN  
            SELECT 
                -28 AS ResponseCode,  
                'Partial Success. Some dispositions are active.' AS ResponseCodeDescription,
                STRING_AGG(CAST(calif_id AS VARCHAR), ',') AS CalifIdLst
            FROM @ToDelete
            RETURN  
        END  

        -- Éxito total
        SELECT 
            200 AS ResponseCode,  
            'SUCCESS' AS ResponseCodeDescription,
            STRING_AGG(CAST(calif_id AS VARCHAR), ',') AS CalifIdLst
        FROM @ToDelete

    END TRY  
    BEGIN CATCH  
        SELECT 
            -1 AS ResponseCode,  
            ERROR_MESSAGE() AS ResponseCodeDescription,
            '' AS CalifIdLst
    END CATCH  
END

IF @command = 14 
BEGIN 
SELECT Name_cal AS [Name],
       Description_cal AS [Description],
       CanReprogram AS Reprogram,
       autoCallback AS Callback,
       Color AS Color,
       ISNULL(AplTransfer, 0) AS [Transfer],
       ISNULL(TransferOpcion, 0) AS TransferOption,
       ISNULL(DestinyIVR, 0) AS DestinyDropDown,
       DestinyIVR_camp AS DestinyCamp,
       ISNULL(DirectoryNumberFlag, 0) AS NumberDropDown,
       DestinyIVR_number AS DestinyNumber,
       DestinyIVR_directory AS DestinyDirectory,
       ISNULL(AplExtDate, 0) AS Extraction,
       ExtDescription AS ExtractionDescription,
       ISNULL(AplBlackList, 0) AS DNC
FROM cctipoCalif_IA 
WHERE calif_id = @calif_id
END
--select * from cctipoCalif_IA


IF @command = 15 
BEGIN 
    select descripcion from ccinbound where inbound_id = @acdId
END

IF @command = 16
BEGIN 
    SELECT tel FROM dbo.telefonosTransferencia where numtra_id = @directoryId 
END

SET NOCOUNT OFF 