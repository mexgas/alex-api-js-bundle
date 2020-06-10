/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/05/06
Description:

Database: CCenterRia
Required version: 122.17

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
SET @version = 122 --**********actualizar a 122 sin fix
SET @versionfix = 18
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 17
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-4083 Mostrar número de llamadas atendidas y canceladas'
		set @sql='
			CREATE PROCEDURE [dbo].[ccsp_GalateaGetCampaignOutDialingStats]
			@Tipo as tinyint=0,
			@cam_id as smallint = 0,
			@sup_id as smallint=0
			AS
			BEGIN

				DECLARE @table TABLE
					 (cam_id SMALLINT, 
					  Calls INT,
					  Answer INT,
					  Busy INT,
					  NoAnswer INT,
					  Fax INT,
					  NoService INT,
					  Other INT,
					  Canceled INT,
					  Machine INT,
					  NoTone INT,
					  Congestion INT,
					  Abandon INT
					  PRIMARY KEY(cam_id)
					 );
					 
			    INSERT INTO @table
			    	EXEC ccsp_OUTGetCallsInfo_AllCamps @Tipo, @cam_id, @sup_id

					select L.*, (L.Attended-L.Xfer) AS Assigned
					
					from
					(

						select A.*, C.Xfer,
						((A.Abandon *100.0)/ A.Answer) as AbandonRate,
						(A.Answer - A.Abandon - A.Canceled) as Attended
						
						from @table as A

						left join(
							select ccC.cam_id, ccC.aggressionFactor
							from ccCamps as ccC
						)B ON A.cam_id = B.cam_id

						left join(
							select Cco.cam_id, COUNT(CASE WHEN Cco.statusCall_id >= 10 THEN 1 END) AS  Xfer
							from ccoCallsOut  as cco
							right join (
								select distinct supCam.cam_id from ccSupervisorCam supCam where user_id=48
							) D ON Cco.cam_id = D.cam_id
							Where cal_Inicio >  convert(smalldatetime, convert(varchar(11), getdate() ), 101)
							group by Cco.cam_id
						)C ON A.cam_id = C.cam_id

					)L

			END
		'
		EXEC(@sql)		

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		-- exec ccsp_getVersion 'BD', @version
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
