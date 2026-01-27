USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_RIAUpdateCamConfigExtend]    Script Date: 1/27/2026 2:10:46 PM ******/
/*El script 'UPDATE ccCamps SET call_record = @recordCalls WHERE cam_id = @cam_id;', se colocó al final del sp, antes el END, 
ya que, es necesario que en ambos casos, tanto en el IF como en el ELSE, se actualice la columna call_record de la tabla cccamps
con el valor de la variable @recordsCalls, para que funcione correctamente lo de grabar o no grabar*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

    ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
        @cam_id SMALLINT,
        @zipCodeSchedule BIT = NULL,
        @userId SMALLINT = NULL,
        @idArea SMALLINT = NULL, 
        @isCreating SMALLINT = NULL,
        @simultaneousRecs SMALLINT = NULL,
        @module INT = -1,
        @recordCalls TINYINT = 1,
        @editableContactData BIT = 1,
        @assignConversationSameAgent BIT = 0,
        @RescheduledSurveyAI BIT = 0,
        @ImmediateSurveyAI BIT = 0,
        @ApplyRescheduledSurveyForCompletedCallsAI BIT = 0,
        @EnableCallRecordingAI BIT = 1
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @country INT = (SELECT valor FROM ccSettings WHERE setting_id = 104); 
        DECLARE @excludeIdentifier VARCHAR(255) = CASE WHEN @country = 4 THEN 'COMMON_INTERNATIONAL_RECORD_CALLS' ELSE 'COMMON_USA_RECORD_CALLS' END;

        IF EXISTS (SELECT * FROM ccCampsExtend WHERE cam_id = @cam_id) 
        BEGIN
            EXEC InsertLogAdminGalatea @action = 1, @tableName = 'ccCampsExtend', @columnNameId = 'cam_id', @valueId = @cam_id, @userId = @userId;

            IF OBJECT_ID(N'tempdb..#ccCampsTable') IS NOT NULL DROP TABLE #ccCampsTable;

            CREATE TABLE #ccCampsExtendTable 
            (
                columnInfo VARCHAR(255),
                dataInfo VARCHAR(255),
                identifierInfo VARCHAR(255)
            );

            DECLARE @Camptype INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @cam_id);
            DECLARE @operation SMALLINT = CASE 
                WHEN @isCreating = 1 THEN 
                    CASE 
                        WHEN @Camptype = 6 THEN 44
                        WHEN @Camptype = 5 THEN 46
                        WHEN @Camptype = 4 OR @Camptype = 9 THEN 48 -- TODO: Delete MediaType 4
                        WHEN @Camptype = 7 THEN 50
                        ELSE 42 
                    END
                ELSE 
                    CASE 
                        WHEN @Camptype = 6 THEN 55
                        WHEN @Camptype = 5 THEN 56
                        WHEN @Camptype = 4 OR @Camptype = 9 THEN 57 -- TODO: Delete MediaType 4
                        WHEN @Camptype = 7 THEN 58
                        ELSE 54 
                    END
                END;

            UPDATE ccCampsExtend
            SET
                zipCodeSchedule = ISNULL(@zipCodeSchedule, zipCodeSchedule),
                simultaneousRecs = ISNULL(@simultaneousRecs, simultaneousRecs),
                RecordCalls = ISNULL(@recordCalls, RecordCalls),
                EditableContactData = ISNULL(@editableContactData, EditableContactData),
                AssignConversationSameAgent = ISNULL(@assignConversationSameAgent, AssignConversationSameAgent),
                -- Outbound AI Campaign Special Settings
                RescheduledSurveyAI = ISNULL(@RescheduledSurveyAI, RescheduledSurveyAI),
                ImmediateSurveyAI = ISNULL(@ImmediateSurveyAI, ImmediateSurveyAI),
                ApplyRescheduledSurveyForCompletedCallsAI = ISNULL(@ApplyRescheduledSurveyForCompletedCallsAI, ApplyRescheduledSurveyForCompletedCallsAI),
                EnableCallRecordingAI = ISNULL(@EnableCallRecordingAI, EnableCallRecordingAI)
            WHERE cam_id = @cam_id;

            IF (@isCreating > 0 AND @module > -1) 
                EXEC InsertLogAdminGalatea @action = 2, @tableName = 'ccCampsExtend', @columnNameId = 'cam_id', @valueId = @cam_id, @userId = @userId, @tableTemp = '#ccCampsExtendTable';

            IF (@idArea IS NULL OR @idArea = -1) 
                SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id);

            IF (@isCreating = 1) 
                DELETE FROM #ccCampsExtendTable WHERE identifierInfo IN ('OUT_WHATS_ASSIGN_SAME_AGENT') AND dataInfo = 0;

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            SELECT 
                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                GETDATE(), 
                (SELECT [Login] FROM ccUsers WHERE User_id = @userId), 
                @operation, 
                @module, 
                CCCE.identifierInfo,
                CASE 
                    WHEN CCCE.identifierInfo IS NOT NULL AND CCCE.identifierInfo <> '' THEN
                        CASE 
                            WHEN CCCE.identifierInfo IN ('SETTINGS_CHANGED_AREAS_ZIP', 'COMMON_INTERNATIONAL_RECORD_CALLS', 'EDIT_CALL_DATASET') THEN
                                CASE WHEN CCCE.dataInfo = 1 THEN 'COMMON_ENABLED' ELSE 'COMMON_DISABLED' END
                            WHEN @isCreating = 1 THEN
                                CASE WHEN CCCE.identifierInfo IN ('OUT_WHATS_ASSIGN_SAME_AGENT') THEN
                                    CASE WHEN CCCE.dataInfo = 1 THEN 'COMMON_ENABLED' END
                                END
                            WHEN @isCreating = 2 THEN
                                CASE WHEN CCCE.identifierInfo IN ('OUT_WHATS_ASSIGN_SAME_AGENT') THEN
                                    CASE WHEN CCCE.dataInfo = 1 THEN 'COMMON_ENABLED' ELSE 'COMMON_DISABLED' END
                                END
                            WHEN CCCE.identifierInfo IN ('COMMON_USA_RECORD_CALLS') THEN
                                CASE 
                                    WHEN CCCE.dataInfo = 1 THEN 'COMMON_USA_RECORD_CALLS_MODE_ALL'
                                    WHEN CCCE.dataInfo = 2 THEN 'COMMON_USA_RECORD_CALLS_MODE_AUTH'
                                    WHEN CCCE.dataInfo = 4 THEN 'COMMON_USA_RECORD_CALLS_MODE_NOAUTH'
                                    ELSE 'COMMON_DISABLED' 
                                END
                            ELSE CCCE.dataInfo 
                        END
                    ELSE '' 
                END,
                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
            FROM #ccCampsExtendTable AS CCCE WHERE CCCE.identifierInfo != @excludeIdentifier;

            EXEC InsertLogAdminGalatea @action = 3, @tableName = 'ccCampsExtend', @columnNameId = 'cam_id', @valueId = @cam_id, @userId = @userId;

            IF OBJECT_ID(N'tempdb..#ccCampsExtendTable') IS NOT NULL DROP TABLE #ccCampsExtendTable;

        END
        ELSE 
        BEGIN
            INSERT INTO ccCampsExtend (
                cam_id, 
                zipCodeSchedule, 
                SimultaneousRecs, 
                RecordCalls, 
                AssignConversationSameAgent, 
                RescheduledSurveyAI, 
                ImmediateSurveyAI, 
                ApplyRescheduledSurveyForCompletedCallsAI, 
                EnableCallRecordingAI
            ) 
            VALUES (
                ISNULL(@cam_id, 0),                     
                ISNULL(@zipCodeSchedule, ''),           
                ISNULL(@simultaneousRecs, 0),           
                ISNULL(@recordCalls, 0),                
                ISNULL(@assignConversationSameAgent, 0),
                -- Outbound AI Campaign Special Settings
                ISNULL(@RescheduledSurveyAI, 0),        
                ISNULL(@ImmediateSurveyAI, 0),          
                ISNULL(@ApplyRescheduledSurveyForCompletedCallsAI, 0),
                ISNULL(@EnableCallRecordingAI, 1)
            );

            SET NOCOUNT OFF;
        END
        UPDATE ccCamps SET call_record = @recordCalls WHERE cam_id = @cam_id;
    END