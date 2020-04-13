/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/03/06
Description:

Database: CCenterRia
Required version: 122.14

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
SET @versionfix = 15
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 14
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'Se registra reporte Agent Summary en BD'
		set @sql='
		if not exists(select * from ccMenus where menu_id=2100) begin
			insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release) values
			(2100,''Resumen de agente|Agent summary'',2000, ''B'', 2, 3, '''', ''875116a11e987ae3b690eedb9cfea927a96b85c266832a3760107db8e5817f901fe9324fde95cb986465c3399ea18173'')
		end	
			'
		EXEC(@sql)


		 set @process = 'CW-3916 Obtener información de estados del agente por camp Drop if exists ccsp_GalateaAdminGetAgentCounters'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminGetAgentCounters'')
	    begin
	        DROP PROCEDURE ccsp_GalateaAdminGetAgentCounters;
	    end'
	    exec (@sql)

		 set @process = 'CW-3916 Obtener información de estados del agente por camp '
		set @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS     INT, 
                                                    @sup_id AS   INT = 0, 
                                                    @agent_id AS INT = 0, 
                                                    @WG AS       INT = 0,
													@campId AS INT = 0

AS
     SET NOCOUNT ON;
     IF @type = 1
         BEGIN
             WITH TableUserAgent(userId)
                  AS (SELECT DISTINCT 
                           wgAgt.User_id  AS Id --,usr.login 
                      FROM ccriaworkgroupusers wgAdmin
                           INNER JOIN ccriaworkgroupusers wgAgt ON wgAdmin.IDWG = wgAgt.IDWG
                           INNER JOIN ccUsers usr ON usr.User_id = wgAgt.User_id
                                                     AND usr.TipoUser_id = 1
                      WHERE wgAdmin.User_id = @sup_id)
                  SELECT CAST(a.User_id AS INT) Id, 
                         a.login AS Username, 
                         a.Nombres + '' '' + a.ApellidoPaterno + '' '' + a.ApellidoMaterno AS Name
                  FROM ccusers a(NOLOCK)--, ccGenViewRelsSupsAgent b
                       INNER JOIN TableUserAgent b ON a.User_id = b.userId
                  ORDER BY a.Login ASC;
     END;
     IF @type = 2
         BEGIN
             SELECT CAST(User_id AS INT) Id,
					Login Username, 
                    Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno Name
             FROM ccUsers
             WHERE User_id = @agent_id;
     END;
     IF @type = 3 --Agents by supervisor and WG
         BEGIN
             DECLARE @table2 TABLE
             (userId INT
              PRIMARY KEY NOT NULL
             );
             INSERT INTO @table2
                    SELECT DISTINCT 
                           wg.User_id
                    FROM ccRIAWorkGroupUsers wg
                         LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                    WHERE us.TipoUser_id = 1
                          AND wg.IDWG IN
                    (
                        SELECT IDWG
                        FROM ccRIAWorkGroupUsers
                        WHERE User_id = @sup_id
                              AND IDWG <> @WG
                    );
             SELECT CAST(B.User_id AS int) AS Id
             FROM @table2 A
                  RIGHT JOIN
             (
                 SELECT DISTINCT 
                        wg.User_id
                 FROM ccRIAWorkGroupUsers wg
                      LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                 WHERE wg.IDWG = @WG
                       AND us.TipoUser_id = 1
             ) B ON A.userId = B.User_id
             WHERE A.userId IS NULL;
     END;

	 IF @type = 4 --Agents IDs by WG
     BEGIN
		SELECT  CAST(wg.User_id AS INT) Id  
		FROM ccRIAWorkGroupUsers wg
		JOIN CCUsers u on u.user_id = wg.user_id AND u.TipoUser_id = 1
		where IDWG = @WG
     END;

	 IF @type = 5 --Agents IDs by Campaign
     BEGIN
		SELECT Distinct(CAST(U.User_id AS INT)) Id FROM ccRIACampEspWG camp
		JOIN ccRIAWorkGroupUsers wg ON camp.IDWG = wg.IDWG
		JOIN ccUsers U ON U.User_id = WG.User_id AND U.TipoUser_id = 1
		WHERE IdCampEsp = @campId AND TIPO = 1
     END;
     SET NOCOUNT ON;
'
	    exec (@sql)

		
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
