use CCRecorderRIA

set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 104
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try

	-----------------------------------BEGIN Release Sprint 7 ---------------------------------------

    -----------------------------------BEGIN CAMBIOS OAOD---------------------------------------------
    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_GalateaRecordingEvaluation]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaRecordingEvaluation] 
    @option SMALLINT, @idRecordingEvaluation INT = 0, @user VARCHAR(50) = '''', @idFormat INT = 0, @userSupervisor VARCHAR(50) = '''', @grabId BIGINT = 0
    AS
    BEGIN
        IF @option = 1 --search recording evaluation owner
        BEGIN
            SELECT userAdmin
            FROM RECORDERRIA_RECORDINGEVALUATION
            WHERE deleted = 0
                AND idRecordingEvaluation = @idRecordingEvaluation
        END
        Else IF @option = 2 --get all answers
        BEGIN
            SELECT *
            FROM RECORDERRIA_ANSWERSOFQUESTIONSEVALUATION        
            WHERE idRecordingEvaluation IN (
                    SELECT idRecordingEvaluation
                    FROM RECORDERRIA_RECORDINGEVALUATION
                    WHERE grab_id = @idRecordingEvaluation
                        AND userAdmin = @user
                        AND userSupervisor = @userSupervisor
                        AND idFormat = @idFormat
                        AND deleted = 0
                    )
        END
        Else  IF @option = 3 --get all recording evaluations
        BEGIN
            SELECT 
                idRecordingEvaluation,
                grab_id,
                userAdmin,
                idFormat,
                totalPoints,
                generalQualification,
                nameAdmin,
                nameSupervisor,
                userSupervisor,
                createAt AS CreatedAt,
                deleted
            FROM RECORDERRIA_RECORDINGEVALUATION
            WHERE grab_id = @idRecordingEvaluation
                AND userAdmin = @user
                AND userSupervisor = @userSupervisor
                AND idFormat = @idFormat
                AND deleted = 0
        END
        Else  IF @option = 4 --get all supervisors
        BEGIN
            DECLARE @camId INT, @callType INT
            SELECT @camId = cam_id, @callType = tipo_llamada
            FROM (
                SELECT grab_id, cam_id, tipo_llamada
                FROM RIA_GRABACION
                WHERE grab_id = @grabId
                
                UNION
                
                SELECT grab_id, cam_id, tipo_llamada
                FROM RIA_GRABACIONCONSULTA
                WHERE grab_id = @grabId --1 Entrada/2 salida
                ) x
            IF @callType = 1
            BEGIN
                SELECT us.[User_id], us.[Login] AS ''Username''
                FROM [ccUsers] AS us
                INNER JOIN [ccInbound] AS ca ON us.IDArea = ca.IDArea
                    AND us.TipoUser_id = 2
                WHERE ca.Inbound_id = @camId
            END
            ELSE
            BEGIN
                SELECT us.[User_id], us.[Login] AS ''Username''
                FROM [ccUsers] AS us
                INNER JOIN cccamps AS ca ON us.IDArea = ca.IDArea
                    AND us.TipoUser_id = 2
                WHERE ca.cam_id = @camId
            END
        END
    END'
    EXEC(@sql)
    -----------------------------------END CAMBIOS OAOD---------------------------------------------

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)<
    ------------------------------------END Release Sprint 7 ----------------------------------------

    update trec_parametros set par_valor = @Version where par_id = 30
    set @Version_Actual=@Version_Actual+1

    select par_valor from trec_parametros where par_id = 30

    commit tran

    end try
    begin catch
        select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
        RAISERROR(@errorGenerated, 11, 1)
    rollback tran
    end catch
 end
 else begin
    select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
