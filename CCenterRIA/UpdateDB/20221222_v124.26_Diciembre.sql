/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.25

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
SET @versionfix = 26
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


	SET @process = 'K001084-Gestionar administradores conectados'
	  	
		SET @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10030)
		begin
			insert into ccPermissions values (10030,''Gestionar administradores conectados'',''RolesPermissionOnlineAdmins'',0,0,0,''N/A'',1)
		end'
		EXEC(@sql)

		SET @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10030)
		begin
      		INSERT INTO ccRoles_Permissions VALUES(1,10030)
		end'
		EXEC(@sql)

		SET @process = 'K039001 Add translate to calueRecord'
		SET @sql = 'if not exists (select * from valueRecord where valueT=''MANUALMODE1'')
		begin
			insert into valueRecord (valueT, es, en, pt) values (''MANUALMODE1'',''Vía teclado e historial'',''Via keypad and log'',''Via teclado e histórico'')
		end
		if not exists (select * from valueRecord where valueT=''MANUALMODE2'')
				begin
					insert into valueRecord (valueT, es, en, pt) values (''MANUALMODE2'',''Vía historial de llamadas'',''Via calls log'',''Via histórico de chamadas'')
				end
		if not exists (select * from valueRecord where valueT=''MANUALMODE3'')
				begin
					insert into valueRecord (valueT, es, en, pt) values (''MANUALMODE3'',''Vía dato en teclado'',''Via data in keypad'',''Via dado no teclado'')
				end'
		EXEC(@sql)

		SET @process = 'K039002 delete sp ccsp_RIACampsManualCall'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIACampsManualCall'')
		begin
			DROP PROCEDURE ccsp_RIACampsManualCall;
		end'
		EXEC(@sql)

		SET @process = 'K039002 create sp ccsp_RIACampsManualCall'
		SET @sql = 'Create PROCEDURE ccsp_RIACampsManualCall
		@UserID int,
		@onChat int = 0
		AS
		set nocount on

		if (@onChat = 0)
		begin
			declare @mod smallint
			select @mod = defCampaing from ccRIACat_Areas A
			where A.IDArea = (select IDArea from ccUsers where User_id = @UserID) 

			select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [isDefault],  g.graphic_id, c.cam_ModoManual
			from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
			join ccRIACampsGraph g ON g.cam_id = c.cam_id
			where ca.user_id = @UserID and cam_modoManual in(1,3)
			order by cam_descripcion
		end
		else
			select distinct c.cam_id, c.cam_descripcion,  g.graphic_id,  c.cam_ModoManual
			from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
			join ccRIACampsGraph g ON g.cam_id = c.cam_id
			where ca.user_id = @UserID and manualCallOnChat = 1
			order by cam_descripcion
			SET NOCOUNT OFF;'
		EXEC(@sql)

		SET @process = 'K039002 delete sp ccspAgent_GetLastCalls '
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccspAgent_GetLastCalls'')
		begin
			DROP PROCEDURE ccspAgent_GetLastCalls;
		end'
		EXEC(@sql)

		SET @process = 'K039002 create sp ccspAgent_GetLastCalls '
		SET @sql = 'CREATE PROCEDURE ccspAgent_GetLastCalls @user_id INT
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
											 , cam_ModoManual as CamManualMode FROM ccoCallsOut c
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
											 , '''' as CamManualMode FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
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
				  , CamManualMode FROM @lastCallAgt
			 ORDER BY hora DESC;
			 SET NOCOUNT OFF;
		'
		EXEC(@sql)

	
	

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
