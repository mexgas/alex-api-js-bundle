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
SET @versionfix = 16
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

	SET @process = 'CW 7605 No se guarda un registro eliminado de previsualización'
		SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_RegProcessPreviewRecord](
        @process smallint,
        @callout_id int,
        @agent_id smallint,
        @camId int,
		@previewTime smallint,
		@callId int)
        AS
        DECLARE @result_callout_id INT
		DECLARE @result_maxtimespreview INT = 0
		DECLARE @insert_date DATETIME = SYSDATETIME()
		DECLARE @first_date DATETIME = DATEADD(hh, 00, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
		DECLARE @process_insert int =  @process

        if(exists(select top 1 1 from ccoWorkingTable nolock where callout_id = @callout_id)) begin
            set @result_callout_id =1
        end

        IF (@process=1 AND @result_callout_id > 0)
        BEGIN
            DELETE ccoWorkingTable WHERE callout_id = @callout_id
        END

		IF (@process NOT IN (1, 7))
		BEGIN
			if(
				(SELECT COUNT(process) FROM RegProcessPreviewRecord 
				WHERE reg_date BETWEEN @first_date AND @insert_date
				and (process != 1 AND process != 7) 
				and (callout_id=@callout_id)
				)
				>=
				(SELECT timesPreview FROM ccCamps WHERE cam_id = @camId)
				)
			begin
					set @result_maxtimespreview = 1
					set @process_insert = 8
					DELETE ccoWorkingTable WHERE callout_id = @callout_id
			end
		END

		IF (@result_callout_id > 0 or @process in (4,7))
        BEGIN
            INSERT INTO RegProcessPreviewRecord(userId,process,callout_id,camId,reg_date,tPreview, callID) VALUES (@agent_id,@process_insert,@callout_id,@camId,@insert_date,@previewTime,@callId)
		END

		select @result_maxtimespreview as ''value''
		';

		EXEC(@sql);



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

