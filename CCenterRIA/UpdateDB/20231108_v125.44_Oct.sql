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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 44
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

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

	-----------------------------------------------------BEGIN Gaby -----------------------------------------------------------------
	SET @process = 'CW-8148 drop sp ccsp_GalateaGetPreviewData'
	SET @sql = '
		if exists(select * from sys.procedures where name = ''ccsp_GalateaGetPreviewData'')
		begin
			DROP PROCEDURE ccsp_GalateaGetPreviewData
		end'
	EXEC(@sql);

	SET @process = 'CW-8148 create procedure ccsp_GalateaGetPreviewData'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaGetPreviewData]
        @option int = null,
		@callout_id int = null,
        @user_id smallint = null

        AS
        set nocount on

		if(@option = 1 or @option is null)
		begin
			declare @typePreview varchar = null

			select @typePreview= valor from ccSettings (nolock)
			where setting_id=248 and Status=1

			select ''previewData''=
			 case when U.AllowDeleteRecord=1 then ''true'' else ''false'' end +''~''+
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
			 ISNULL(O.cal_telefono5,'''')+''~''+
			 ISNULL(cast(O.cal_Key as varchar),'''')+''~''+
			 ISNULL(cast(O.cal_telefono as varchar),'''')+''~''+
			 @typePreview+''~'',
			 C.previewDiscard,
			 CE.EditableContactData as previewUpdate
				   from ccoCallsOutSource O (nolock)
			INNER JOIN ccoCallsPreviewData P (nolock) on O.cal_Key=P.Cal_key and O.cam_id=P.cam_id
			INNER JOIN ccCamps C (nolock) on P.cam_id = C.cam_id
			INNER JOIN ccCampsExtend CE (nolock) on C.cam_id= CE.cam_id
			JOIN ccUsers U (nolock) on U.TipoUser_id=1
			Where callout_id=@callout_id and U.User_id=@user_id
		end

		if(@option = 2)
		begin
			select COUNT(*) from ccoCallsOutSource nolock where callout_id = @callout_id
		end
        set nocount off'
	EXEC(@sql);

	-----------------------------------------------------END Gaby -----------------------------------------------------------------s
	/* End script release */
	/* Upgrade database version (first and the last number of setting 77) */
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