-- =============================================
-- Author:		UEspinosa
-- Create date: 26/11/20
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ccsp_GalateacampaingManager] 
--declare
@option           SMALLINT, 
@Activa           SMALLINT     = NULL, 
@Descripcion      VARCHAR(40) = '', 
@IDArea           SMALLINT, 
@MirrorInbound_Id SMALLINT    = NULL, 
@frame            SMALLINT, 
@Prefijo          VARCHAR(40) = '', 
@Type             SMALLINT, 
@userId           SMALLINT, 
@moduleId         SMALLINT    = 49
AS
    BEGIN
        IF(@option = 2)
            BEGIN
				IF EXISTS(select top 1 cam_id from ccCamps where cam_descripcion = @Descripcion)
				BEGIN
					Select -1
					return
				END
                IF OBJECT_ID('tempdb..#Campaing') IS NOT NULL DROP TABLE #Campaing
                CREATE TABLE #Campaing(IdCampaing INT)
                IF @type = 1
                    BEGIN
                        INSERT INTO #Campaing
                        EXEC ccsp_RIA_ABCCamps 
                             @option = @option, 
                             @Descripcion = @Descripcion, 
                             @Cam_id = '0', 
                             @Activa = 1, 
                             @IDArea = @IDArea, 
                             @frame = @frame, 
                             @Prefijo = @Prefijo
                END
                    ELSE
                    IF @type = 0
                        BEGIN
                            INSERT INTO #Campaing
                            EXEC ccsp_RIA_ABCACDGroups 
                                 @option = @option, 
                                 @descripcion = @Descripcion, 
                                 @inbound_id = '0', 
                                 @idarea = @IDArea, 
                                 @frame = @frame, 
                                 @Prefijo = @Prefijo,
								 @userid = @userId
                    END
                IF((SELECT TOP 1 IdCampaing FROM #Campaing ) > 0)
                    BEGIN
                        INSERT INTO ccRIALog
                        VALUES(
                        (SELECT AreaName FROM ccRIACat_Areas WHERE IDArea = @IDArea), 
                        GETDATE(),
                        CASE
                            WHEN @type = 1
                            THEN 25
                            ELSE 26
                        END, 
                        (SELECT Login FROM ccUsers WHERE User_Id = @userId), 
                        @moduleId, 
                        '', 
                        @Descripcion
                        )
                END
				SELECT TOP 1 IdCampaing FROM #Campaing
				IF OBJECT_ID('tempdb..#Campaing') IS NOT NULL DROP TABLE #Campaing
        END
    END