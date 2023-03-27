/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @versionfix = 9
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
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

	---------------------------------------Begin Rod Salazar  ---------------------------------------------------------

	SET @process = 'CW-7838 Validación y eliminación de sp ccspAgent_GetLastCalls'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccspAgent_GetLastCalls'')
				begin
					DROP PROCEDURE ccspAgent_GetLastCalls;
				end
	'
	EXEC(@sql)

	SET @process = 'CW-7838 Creación de sp ccspAgent_GetLastCalls'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
		AS
			 SET NOCOUNT ON;
			 DECLARE @lastCallAgt TABLE(id           INT NOT NULL
									  , tipo         VARCHAR(10) NOT NULL
									  , Hora         DATETIME NOT NULL --VARCHAR(19) NOT NULL, 
									  , Telefono     VARCHAR(55) NOT NULL
									  , EspCamp      VARCHAR(55) NOT NULL
									  , Calificacion VARCHAR(60)
									  , Duracion     VARCHAR(10) NOT NULL
									  , CallBack     DATETIME
									  , cal_key      VARCHAR(40)
									  , IDCampEsp    SMALLINT NOT NULL
									  , prefijo      VARCHAR(255) NULL
									  , GraphicID    INT
									  , CamManualMode INT
									  , SelectRotativeANI INT
									  , PRIMARY KEY(id)
			 );

			 DECLARE @pais TINYINT;
			 DECLARE @maxHours SMALLINT;
			 DECLARE @topRows INT;
			 DECLARE @setting VARCHAR(6);
			 DECLARE @hidePhone BIT;
			 DECLARE @dateStart DATETIME;

			 SET @hidePhone = 1;

			 SELECT @setting = valor FROM ccSettings WHERE setting_id = 255;

			 SET @maxHours = CAST(SUBSTRING(@setting, 1, (SELECT PATINDEX(''%|%'', @setting)) - 1) AS SMALLINT);
			 SET @topRows = CAST(SUBSTRING(@setting, (SELECT PATINDEX(''%|%'', @setting)) + 1, LEN(@setting)) AS INT);

			 IF @maxHours = 0
			 BEGIN
				 SELECT Id
					  , tipo
					  , (CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) AS Hora
					  , Telefono
					  , EspCamp
					  , Calificacion
					  , CallBack
					  , Duracion
					  , '''' AS CallBack
					  , cal_key
					  , IDCampEsp
					  , prefijo
					  , GraphicID
					  , SelectRotativeANI
					  , @hidePhone AS HidePhone FROM @lastCallAgt;

				 RETURN 0;
			 END;

			 SELECT @pais = valor FROM ccSettings WHERE setting_id = 104;

			 SELECT @hidePhone = CASE WHEN valor = ''0''
								 THEN 0 ELSE 1
								 END FROM ccSettings WHERE setting_id = 223;

			 IF @topRows = 0
			 BEGIN
				 SET @topRows = 10000;
			 END;

			 SET @dateStart = DATEADD(hh, -@maxHours, GETDATE());

			 WITH timeTransfer
				  AS (SELECT cal_id
						   , tipo
						   , SUM(tAntesXfer) AS tAntesXfer
						   , SUM(tDespuesXfer) AS tDespuesXfer FROM ccLogTransfers
					  WHERE fechaFin > @dateStart
					  GROUP BY cal_id
							 , tipo)

				  INSERT INTO @lastCallAgt
						 ---Insert OUT
						 SELECT TOP (@topRows) c.cal_id AS id
											 , ''OUT'' AS Tipo
											 , cal_inicio
											 , cal_telefono AS Telefono
											 , cam_descripcion AS EspCamp
											 , ISNULL(cal.Description, '''') AS Calificacion
											 , CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
																										THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
																										END, 0), 114) AS Duracion
											 , cal_fcallback AS CallBack
											 , cal_key
											 , c.cam_id AS IDCampEsp
											 , ISNULL(ccCamps.prefijo, '''') Prefijo
											 , graph.graphic_id GraphicID
											 , cam_ModoManual as CamManualMode 
											 , ISNULL(selectRotativeANI, 0) as SelectRotativeANI FROM ccoCallsOut c
																			   INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
																			   LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
																			   LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
																			   LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
																										   AND t.tipo = 2
						 WHERE user_id = @user_id
							   AND cal_inicio > @dateStart
						 UNION
						 --- IN
						 SELECT TOP (@topRows) c.cal_id AS id
											 , ''IN'' AS Tipo
											 , cal_inicio
											 , cal_ani AS Telefono
											 , descripcion AS EspCamp
											 , ISNULL(cal.Description, '''') AS Calificacion
											 , CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
																											 THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
																											 END, 0), 108) Duracion
											 , NULL AS CallBack
											 , cal_key
											 , c.inbound_id AS IDCampEsp
											 , ISNULL(ccInbound.prefijo, '''') Prefijo
											 , graph.graphic_id GraphicID
											 , '''' as CamManualMode 
											 , 0 as SelectRotativeANI FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
																			   JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
																			   INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
																			   LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
																			   LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
																										   AND t.tipo = 1
						 WHERE user_id = @user_id
							   AND cal_inicio > @dateStart;

			 SELECT Id
				  , tipo
				  , CASE WHEN @pais = 4
					THEN(CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) ELSE(CONVERT(VARCHAR(10), Hora, 103) + '' '' + CONVERT(VARCHAR(8), Hora, 14))
					END AS Hora
				  , Telefono
				  , EspCamp
				  , Calificacion
				  , ISNULL(CONVERT(VARCHAR(16), CallBack, 121), '''') AS CallBack
				  , Duracion
				  , CallBack
				  , cal_key
				  , IDCampEsp
				  , prefijo
				  , GraphicID
				  , @hidePhone AS HidePhone 
				  , CamManualMode 
				  , SelectRotativeANI FROM @lastCallAgt
			 ORDER BY hora DESC;
			 SET NOCOUNT OFF;
		'
	exec (@sql)
	---------------------------------------End Rod Salazar  ---------------------------------------------------------
	---------------------------------------Begin B Dunzz  ---------------------------------------------------------
	SET @process = 'KR051000 - Creación del menu 3230'
	SET @sql = '
		IF NOT EXISTS(select * from ccMenus where menu_id = 3230)
			insert into ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type) values (3230, ''Cola virtual|Virtual queue'', 3000, ''B'', 3, 2)
	'
	EXEC(@sql)
	---------------------------------------End B Dunzz  ---------------------------------------------------------
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
