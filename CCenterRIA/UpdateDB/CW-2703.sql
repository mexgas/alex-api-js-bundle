/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.37

Se agrega la tarea
cw-2915
cw-3001
CW-3201
CW-3032
CW-3045
CW-3199

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
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 38
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 37
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-2703 Creacion de la tabla ccCallCost_Ria '
		set @sql = 'if not exists (select * from sys.tables where name = N''ccCallCost_RIA'')
			    begin
			        CREATE TABLE [dbo].[ccCallCost_RIA](
						[country_id] [smallint] NOT NULL,
						[tipoLlamada_id] [smallint] NULL,
						[cost_per_min] [float] NULL,
						[additional_min] [float] NULL
					) ON [PRIMARY]
			    end'

		exec (@sql)

		set @process = 'CW-2703 Creacion del indice de la tabla ccCallCost_Ria '
		set @sql = 'if not exists (select * from sys.indexes where name = N''PK_ccCallCost'' and object_id = OBJECT_ID(N''ccCallCost_RIA''))
				    begin
				        CREATE UNIQUE INDEX PK_ccCallCost ON ccCallCost_RIA (country_id,tipoLlamada_id)
				    end'

		exec (@sql)

		set @process = 'CW-2703 Llenado de la tabla ccCallCost_RIA'
		set @sql = 'if not exists (select * from ccCallCost_RIA)
begin
	insert into ccCallCost_RIA (country_id,tipoLlamada_id,cost_per_min,additional_min)
	select country_id,tipoLlamada_id,1,1 from cstoTipoLlamada
end'

		exec (@sql)
		
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
