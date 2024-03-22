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
SET @versionfix = 0
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

        ----------------------------------------------------- BEGIN Frida Orta----------------------------------------------------------------


SET @process = 'DEV2-405 update tableLangueDbLoader'
SET @sql = '
		if  exists(select tag from tableLangueDbLoader where tag = ''type-camp-no-international-port'' and languageId=0)
		begin
			update tableLangueDbLoader set translate=''Puerto de marcación no encontrado'' where tag = ''type-camp-no-international-port'' and languageId=0
		end
		'
EXEC(@sql);

SET @process = 'DEV2-405 update tableLangueDbLoader'
SET @sql = '
	if  exists(select tag from tableLangueDbLoader where tag = ''type-camp-no-international-port'' and languageId=1)
		begin
			update tableLangueDbLoader set translate=''Dialing port not found'' where tag = ''type-camp-no-international-port'' and languageId=1
		end'
EXEC(@sql);

SET @process = 'DEV2-405 update tableLangueDbLoader'
SET @sql = '
	if  exists(select tag from tableLangueDbLoader where tag = ''type-camp-no-international-port'' and languageId=2)
		begin
			update  tableLangueDbLoader set translate= ''Porta de discagem não encontrada''  where tag = ''type-camp-no-international-port'' and languageId=2
		end'
EXEC(@sql);

SET @process = 'CW-831 Drop SP ccsp_GetDialingCodesByCamp'
SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GetDialingCodesByCamp'')
    begin
        DROP PROCEDURE ccsp_GetDialingCodesByCamp;
    end
	'
EXEC(@sql);

SET @process = 'CW-831 Create SP ccsp_GetDialingCodesByCamp'
SET @sql = '
Create procedure ccsp_GetDialingCodesByCamp
@cam_id int
as
if((select COUNT(*) from 
(
	select idCode from ccoDialers a
	inner join ccoDialerCamp b
	on b.dialer_id = a.dialer_id
	where a.IdCode=0 and b.cam_id=@cam_id and a.DialingType=0
)
result)>0)
begin
	select 0 as Code
end
else
begin
	select  replace(Code,''-'','''') from CodesInterDialing a 
	inner join ccoDialers b 
	inner join ccoDialerCamp c 
	on c.dialer_id = b.dialer_id 
	on b.IdCode = a.id 
	where c.cam_id = @cam_id and  b.DialingType=0 
end


	'
EXEC(@sql);
        ----------------------------------------------------- END Frida Orta----------------------------------------------------------------
 

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
