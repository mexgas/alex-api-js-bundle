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
SET @versionfix = 48
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

        ----------------------------------------------------- BEGIN IM-KR111001_Enmascaramiento_de_ani ----------------------------------------------------------------

        SET @process = 'KR111001 Drop procedure ccsp_ManualCallGetRotativeAni if exists'
        SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_ManualCallGetRotativeAni'')
                    BEGIN
                        DROP PROCEDURE ccsp_ManualCallGetRotativeAni;
                    END'
        EXEC(@sql);

        SET @process = 'KR111001 PROCEDURE to get ani deppending on the settings'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_ManualCallGetRotativeAni]
                    @phones VARCHAR(MAX),
                    @camId INT
                    AS
                    set nocount on

                    DECLARE @aniId INT;
                    DECLARE @rotativeAlgo INT;
                    DECLARE @Anis TABLE(id INT, pid VARCHAR(2), phone VARCHAR(32), ani VARCHAR(32));

                    SELECT @aniId = [id_anilist], @rotativeAlgo = [rotativeAlgo] FROM ccCamps WHERE cam_id = @camId;

                    INSERT @Anis
                    EXEC ccsp_DLRGetRotativeANI @callout_id=0, @phones=@phones, @aniList=@aniId,@algo=@rotativeAlgo;

                    IF(SELECT COUNT(*) FROM @Anis) > 0 BEGIN
                        SELECT TOP 1 ani FROM @Anis
                    END ELSE IF EXISTS (SELECT valor FROM ccSettings WHERE setting_id = 177) BEGIN
                        SELECT valor FROM ccSettings WHERE setting_id = 177
                    END ELSE BEGIN
                        SELECT ''''
                    END

                    set nocount off'
        EXEC(@sql);


      
        ----------------------------------------------------- END IM-KR111001_Enmascaramiento_de_ani----------------------------------------------------------------

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
