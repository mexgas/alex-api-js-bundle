/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2025/03/25
Description: Fix muñoz

Database: CCReportsRIA
Required version: 144

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON --

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
SET @version = 146 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
--------------------------------------------------------BEGIN 127.20250905.0.0 Jesus Gallardo----------------------------------------------------------------------
    
        set @process = '#3306 DROP INDEX IX_RepOutAnswAndXferCalls_1'
set @sql='IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = ''IX_RepOutAnswAndXferCalls_1''
      AND object_id = OBJECT_ID(''dbo.RepOutAnswAndXferCalls'')
)
BEGIN
    DROP INDEX IX_RepOutAnswAndXferCalls_1
    ON dbo.RepOutAnswAndXferCalls;    
END
'
EXEC(@sql)


set @process = '#3306 CREATE NONCLUSTERED INDEX [IX_RepOutAnswAndXferCalls_2]'
set @sql='IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = ''IX_RepOutAnswAndXferCalls_2''
      AND object_id = OBJECT_ID(''dbo.RepOutAnswAndXferCalls'')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RepOutAnswAndXferCalls_2] 
    ON [dbo].[RepOutAnswAndXferCalls] ([date])
    INCLUDE ([dialog],[ncost],[total]);
       
END'
EXEC(@sql)

set @process = '#3306 DROP INDEX IX_RepOutCallBilling'
set @sql='IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = ''IX_RepOutCallBilling''
      AND object_id = OBJECT_ID(''dbo.RepOutCallBilling'')
)
BEGIN
    DROP INDEX IX_RepOutCallBilling
    ON dbo.RepOutCallBilling;

END'
EXEC(@sql)


set @process = '#3306 CREATE NONCLUSTERED INDEX [IX_RepOutCallBilling_1]'
set @sql='IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = ''IX_RepOutCallBilling_1''
      AND object_id = OBJECT_ID(''dbo.RepOutCallBilling'')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RepOutCallBilling_1]
ON [dbo].[RepOutCallBilling] ([date])
INCLUDE ([tipoLlamada_count])
    
   
END'
EXEC(@sql)

set @process = ''
set @sql=''
EXEC(@sql)

set @process = ''
set @sql=''
EXEC(@sql)

    	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
