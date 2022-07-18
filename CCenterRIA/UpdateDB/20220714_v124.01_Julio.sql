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
SET @versionfix = 30
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

	
    set @process = 'Alter table ccsp_RegProcessPreviewRecord'
    set @sql = '
		ALTER PROCEDURE [dbo].[ccsp_RegProcessPreviewRecord](
        @process smallint,
        @callout_id int,
        @agent_id smallint,
        @camId int,
		@previewTime smallint,
		@callId int)
        AS
        DECLARE @result_callout_id INT
        if(exists(select top 1 1 from ccoWorkingTable nolock where callout_id = @callout_id)) begin
            set @result_callout_id =1
        end
        IF (@result_callout_id > 0 or @process in (4,7))
        BEGIN
            INSERT INTO RegProcessPreviewRecord(userId,process,callout_id,camId,reg_date,tPreview, callID) VALUES (@agent_id,@process,@callout_id,@camId,SYSDATETIME(),@previewTime,@callId)
		END
        IF (@process=1 AND @result_callout_id > 0)
        BEGIN
            DELETE ccoWorkingTable WHERE callout_id = @callout_id
        END
	'
    EXEC(@sql)

	set @process = 'Add columns CallId and tPreview to RegProcessPreviewRecord'
    set @sql = '
		if not exists (select * from sys.columns where name = N''tPreview'' and Object_ID = Object_ID(N''RegProcessPreviewRecord''))
		begin
			alter table RegProcessPreviewRecord add tPreview smallint not null default 0
		end

		if not exists (select * from sys.columns where name = N''callId'' and Object_ID = Object_ID(N''RegProcessPreviewRecord''))
		begin
			alter table RegProcessPreviewRecord add callId int not null default 0
		end
	'
    EXEC(@sql)

	set @process = 'Create table ccTypeProcessPreview'
    set @sql = '
		if not exists (select * from sys.tables where name = N''ccTypeProcessPreview'')
		begin
			create table ccTypeProcessPreview(
			typeProcess_id tinyint primary key not null,
			descripcion varchar (20) not null,
			translatedDesc varchar (50) not null)
		end
	'
    EXEC(@sql)

	set @process = 'Add data to ccTypeProcessPreview'
    set @sql = '
		if (select count(typeProcess_id) from ccTypeProcessPreview where typeProcess_id = 0) = 0
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (0, ''Discard'',''systemTranslated_Discard'')
			end
		 if (select count(typeProcess_id) from ccTypeProcessPreview where typeProcess_id = 1) = 0
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (1, ''Delete'',''systemTranslated_DeletePreview'')
			end
		 if (select count(typeProcess_id) from ccTypeProcessPreview where typeProcess_id=2) = 0
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (2, ''DiscardByTime'',''systemTranslated_DiscardByTime'')
			end
		 if (select count(typeProcess_id) from ccTypeProcessPreview where typeProcess_id = 3) = 0
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (3, ''DiscardByND'',''systemTranslated_DiscardByND'')
			end
		 if (select count(typeProcess_id) from ccTypeProcessPreview where typeProcess_id = 4) = 0
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (4, ''DiscardByXfer'',''systemTranslated_DiscardByXfer'')
			end
		 if (select count(typeProcess_id) from ccTypeProcessPreview where typeProcess_id = 7) = 0
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (7, ''WithDialResult'','''')
			end
	'    

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

