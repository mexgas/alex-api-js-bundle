/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2023/07/04
Description: K089000
Database: CCenterRia
Required version: 125.37
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 8
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end
IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END
IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY
 
        ----------------------------------------------------- BEGIN KR134000-SMS Masivo Muñoz, Ivan Martin  ----------------------------------------------------------------
    	SET @process = 'KR134000 Creación de tabla de status de referencia para email de mensajes sms. ';
    	SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N''ccSmsEmailResultStatus'')
                    BEGIN
                        CREATE TABLE ccSmsEmailResultStatus (
                            Id INT PRIMARY KEY IDENTITY(1,1),
                            Name VARCHAR(50) NOT NULL,
                            Description NVARCHAR(MAX) NOT NULL
                        );
                    END';
    	EXEC (@sql);

        SET @process = 'KR134000 Se insertan valores en la tabla';
        SET @sql = 'IF NOT EXISTS (SELECT * FROM ccSmsEmailResultStatus)
                    BEGIN
                        INSERT INTO ccSmsEmailResultStatus (Name, Description)
                        VALUES 
                            (''Success'', ''Message successfully sent''),
                            (''SendEmailError'', ''An error occurred while sending the message''),
                            (''AdminWithoutAssignedEmail'', ''Admin without assigned email''),
                            (''CenterwareWithoutOutboundEmail'', ''Centerware without outbound email'');
                    END;';
        EXEC (@sql);

        SET @process = 'KR134000 Creación de tabla para guardar mensajes';
        SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N''ccSmsResponseMessages'')
                    BEGIN
                        CREATE TABLE ccSmsResponseMessages (
                            Id INT PRIMARY KEY IDENTITY(1,1),
                            Destination VARCHAR(32) NOT NULL,
                            Source VARCHAR(32) NOT NULL,
                            Text NVARCHAR(MAX) NOT NULL,
                            Date DATETIME NOT NULL,
                            SystemApiId VARCHAR(100) NOT NULL, 
                            EmailAttempts INT NOT NULL DEFAULT 0,
                            EmailResultStatus SMALLINT NOT NULL DEFAULT 0,
                        );
                    END';
        EXEC (@sql);

        SET @process = 'KR134000 Se crea índice para SystemApiId';
        SET @sql = 'IF OBJECT_ID(N''IX_ccSmsResponseMessages_SystemApiId'', N''INDEX'') IS NULL
                    BEGIN
                        CREATE INDEX IX_ccSmsResponseMessages_SystemApiId ON ccSmsResponseMessages (SystemApiId);
                    END';
        EXEC (@sql);
		
        SET @process = 'KR134000 Creación de tabla para hacer BulkCopy al terminar procesamiento de correos y actualizar estados.';
        SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N''ProcessingSmsClientMessagesEmails'')
                    BEGIN
                        CREATE TABLE ProcessingSmsClientMessagesEmails (
                            Destination VARCHAR(32) NOT NULL,
                            Source VARCHAR(32) NOT NULL,
                            Text NVARCHAR(MAX) NOT NULL,
                            Date DATETIME NOT NULL,
                            SystemApiId VARCHAR(100) NOT NULL, 
                            UserEmail NVARCHAR(255), 
                            EmailAttempts INT NOT NULL DEFAULT 0,
                            EmailResultStatus SMALLINT NOT NULL DEFAULT 0,
                        );
                    END';
        EXEC (@sql);

        SET @process = 'KR134000 Drop procedure ccspSmsClientsResponse';
        SET @sql = 'IF EXISTS(SELECT * FROM sys.procedures WHERE name = N''ccspSmsClientsResponse'')
                    BEGIN
                      DROP PROCEDURE ccspSmsClientsResponse
                    END';
        EXEC (@sql);

        SET @process = 'KR134000 Se crea procedimiento almacenado ccspSmsClientsResponse';
        SET @sql = 'CREATE PROCEDURE [dbo].[ccspSmsClientsResponse] 
                    @Action SMALLINT, 
                    @Destination VARCHAR(32) = NULL, 
                    @Source VARCHAR(32) = NULL,
                    @Text VARCHAR(MAX) = NULL,
                    @Date DATETIME = NULL,
                    @SystemApiId VARCHAR(100) = NULL
                    AS

                    IF @Action IS NOT NULL BEGIN
                        IF @Action = 0 BEGIN        -- Insert new client message
                            INSERT INTO ccSmsResponseMessages (Destination, Source, Text, Date, SystemApiId) VALUES (@Destination, @Source, @Text, @Date, @SystemApiId)
                        END

                        IF @Action = 1 BEGIN        -- Get sender email information
                            SELECT valor FROM ccSettings WHERE setting_id = 98
                        END

                        IF @Action = 2 BEGIN        -- Get admin email information
                            SELECT LD.cam_id AS CampaignId, 
                                   U.notificationEmail AS AdminEmails
                            FROM ccSmsResponseMessages RM
                            INNER JOIN smsccoLogDial LD ON LD.SystemApiId = RM.SystemApiId
                            INNER JOIN ccSupervisorCam SC ON SC.cam_id = LD.cam_id 
                            INNER JOIN ccUsers U ON U.User_id = SC.user_id
                            WHERE RM.EmailResultStatus <> 1     -- Get all non successful email messages
                            GROUP BY LD.cam_id, U.notificationEmail;
                        END

                        IF @Action = 3 BEGIN        -- Get messages to send an email
                            SELECT  RM.Destination, 
                                    RM.Source, 
                                    RM.Text, 
                                    RM.Date, 
                                    RM.SystemApiId, 
                                    LD.cam_id AS CampaignId,
                                    RM.EmailResultStatus,
                                    RM.EmailAttempts
                            FROM ccSmsResponseMessages RM
                            INNER JOIN smsccoLogDial LD ON LD.SystemApiId = RM.SystemApiId
                            WHERE  RM.EmailResultStatus <> 1 
                        END

                        IF @Action = 4 BEGIN        -- Update email attempts and status BEGIN TRY
                            BEGIN TRY
                            BEGIN TRANSACTION;
                                UPDATE ccSmsResponseMessages
                                SET EmailAttempts = PM.EmailAttempts,
                                    EmailResultStatus = PM.EmailResultStatus
                                FROM ccSmsResponseMessages RM
                                INNER JOIN ProcessingSmsClientMessagesEmails PM ON RM.SystemApiId = PM.SystemApiId

                                COMMIT TRANSACTION;
                                RETURN @@ROWCOUNT;
                            END TRY
                            BEGIN CATCH
                                IF @@TRANCOUNT > 0
                                    ROLLBACK TRANSACTION;

                                RETURN -1;
                            END CATCH
                        END
                    END
                    ELSE BEGIN
                        RAISERROR(''Invalid action specified.'', 16, 1);
                        RETURN -1;
                    END';
        EXEC (@sql);

        SET @process = 'KR134000';
        SET @sql = '';
        EXEC (@sql);
        ----------------------------------------------------- END KR134000-SMS Masivo Muñoz, Ivan Martin  ----------------------------------------------------------------

 	
        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()
        RAISERROR (@errorGenerated, 11, 1)
        ROLLBACK TRAN
    END CATCH
END 
