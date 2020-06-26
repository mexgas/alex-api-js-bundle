SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 84

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'CW-4141 DELETE SP ccspEspecial'
		SET @sql = '
		IF (OBJECT_ID(''ccspEspecial'') IS NOT NULL)
		DROP PROCEDURE ccspEspecial'
		EXEC(@sql)

		SET @process = 'CW-4141 CREATE SP ccspEspecial'
		SET @sql = '		
		CREATE PROCEDURE ccspEspecial
		AS
		BEGIN
		SET NOCOUNT ON;
		DECLARE @fechai DATETIME, @fechaf DATETIME;
		SET @fechaf = CONVERT(VARCHAR(10), GETDATE(), 121);
		SET @fechaf = DATEADD(dd, 1, @fechaf);
		SELECT @fechai = DATEADD(dd, -1, @fechaf);
		DECLARE @centro VARCHAR(100), @ip VARCHAR(15);
		SELECT @centro = ''Marron'', 
			   @ip = ''10.246.10.52'';
		DECLARE @sql NVARCHAR(MAX), @sqls NVARCHAR(MAX), @caseND VARCHAR(8000), @sql2 VARCHAR(8000), @cols VARCHAR(8000);
		DECLARE @colsAndType VARCHAR(8000);
		DECLARE @filterNotReady TABLE
		(nameNotReady VARCHAR(255), 
		 dataType     VARCHAR(255)
		);
		INSERT INTO @filterNotReady
		VALUES
		(''DEFAULT'', 
		 ''float''
		);
		INSERT INTO @filterNotReady
		VALUES
		(''TrabajoAdmvo'', 
		 ''float''
		);
		INSERT INTO @filterNotReady
		VALUES
		(''FALLA'', 
		 ''float''
		);
		INSERT INTO @filterNotReady
		VALUES
		(''CAPACITACION'', 
		 ''float''
		);
		INSERT INTO @filterNotReady
		VALUES
		(''Retroalimentacion'', 
		 ''float''
		);
		INSERT INTO @filterNotReady
		VALUES
		(''PAUSA GENERAL'', 
		 ''float''
		);
		INSERT INTO @filterNotReady
		VALUES
		(''PERSONAL'', 
		 ''float''
		);
		INSERT INTO @filterNotReady
		VALUES
		(''SINCONEXION'', 
		 ''float''
		);
		SELECT @cols = COALESCE(@cols, '''') + ''['' + Descripcion + ''],''
		FROM ccTipoNotReady
		WHERE descripcion IN
		(
			SELECT nameNotReady
			FROM @filterNotReady
		)
		ORDER BY Descripcion;
		SELECT @cols = SUBSTRING(@cols, 1, len(@cols) - 1);
		SELECT @sqls = COALESCE(@sqls, '''') + ''isnull(['' + Descripcion + ''],0) ['' + Descripcion + ''],''
		FROM ccTipoNotReady
		WHERE descripcion IN
		(
			SELECT nameNotReady
			FROM @filterNotReady
		)
		ORDER BY Descripcion;


		SELECT @sqls = SUBSTRING(@sqls, 1, len(@sqls)-1 );


		SELECT @caseND = COALESCE(@caseND, '''') + ''SUM(case when TipoNotReady_id = '' + CAST(TipoNotReady_id AS VARCHAR(3)) + '' then tstatus else 0 end) ['' + Descripcion + ''],''
		FROM ccTipoNotReady
		WHERE descripcion IN
		(
			SELECT nameNotReady
			FROM @filterNotReady
		)
		ORDER BY Descripcion;



		IF OBJECT_ID(''tempdb..#agent_ccLogAgentesNotReady'') IS NOT NULL
			DROP TABLE #agent_ccLogAgentesNotReady;
		IF OBJECT_ID(''tempdb..#ccLog3'') IS NOT NULL
			DROP TABLE #ccLog3;
		IF OBJECT_ID(''tempdb..#tiempo_cocallsout'') IS NOT NULL
			DROP TABLE #tiempo_cocallsout;
		IF OBJECT_ID(''tempdb..#tiempo_cccallsin'') IS NOT NULL
			DROP TABLE #tiempo_cccallsin;
		IF OBJECT_ID(''tempdb..#table_ccloglogin'') IS NOT NULL
			DROP TABLE #table_ccloglogin;
			IF OBJECT_ID(''tempdb..#timeAgent'') IS NOT NULL
			DROP TABLE #timeAgent;

		--******************************************
		--TablasTemporales
		--******************************************

		Create  table #table_ccloglogin 
		(fecha   DATE, 
		 login   DATETIME, 
		 logout  DATETIME, 
		 user_id INT
		);
		INSERT INTO #table_ccloglogin
			   SELECT CONVERT(VARCHAR(10), fecha, 121) fecha, 
					  MIN(CASE
							  WHEN TipoMov = 1
							  THEN fecha
							  ELSE NULL
						  END) login, 
					  MAX(CASE
							  WHEN TipoMov = 0
							  THEN fecha
							  ELSE NULL
						  END) logout, 
					  user_id
			   FROM ccloglogin WITH (INDEX(IX_ccLogLogin_2), NOLOCK)
			   WHERE fecha BETWEEN @fechai AND @fechaf
			   GROUP BY CONVERT(VARCHAR(10), fecha, 121), 
						user_id;
		----------------------------------------------------------------------------------------------
		CREATE TABLE #timeAgent 
		(USER_ID INT, 
		 tready  FLOAT, 
		 tnotas  FLOAT, 
		 totro   FLOAT, 
		 fecha   DATE
		);
		INSERT INTO #timeAgent
			   SELECT USER_ID, 
					  SUM(CASE
							  WHEN TipoStatusAge_id = 3
							  THEN tstatus
							  ELSE 0
						  END) tready, 
					  SUM(CASE
							  WHEN TipoStatusAge_id = 6
							  THEN tstatus
							  ELSE 0
						  END) tnotas, 
					  SUM(CASE
							  WHEN TipoStatusAge_id IN(5, 21)
							  THEN tstatus
							  ELSE 0
						  END) totro, 
					  CONVERT(VARCHAR(10), fecha, 121) fecha
			   FROM ccLogAgentesDia WITH (INDEX(IX_ccLogAgentesDia), NOLOCK) 
			   --where fecha between CHAR(0x27) + @fechai + CHAR(0x27) and  CHAR(0x27) + @fechaf +  CHAR(0x27) 
			   WHERE fecha BETWEEN @fechai AND @fechaf
			   GROUP BY USER_ID, 
						CONVERT(VARCHAR(10), fecha, 121);
		----------------------------------------------------------------------------------------------
		CREATE TABLE #agent_ccLogAgentesNotReady
		(user_id INT
		);
		SET @colsAndType = ''alter TABLE #agent_ccLogAgentesNotReady add
		'';
		SELECT @colsAndType = @colsAndType + ''['' + nameNotReady + ''] '' + dataType + '',''
		FROM @filterNotReady;
		SET @sql = @colsAndType + '' fecha date'';
		EXEC (@sql);
		SET @sql = ''insert into #agent_ccLogAgentesNotReady ('' + @cols + '',user_id,fecha)
		select 
		'' + @caseND + ''user_id,CONVERT(varchar(10),fecha,121) fecha 
			from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_2),nolock)
			where fecha between @fechai and @fechaf
			group by USER_ID,CONVERT(varchar(10),fecha,121)'';
		EXEC sp_executesql 
			 @sql, 
			 N''@fechai datetime, @fechaf datetime'', 
			 @fechai, 
			 @fechaf;
		--------------------------------------------------------------------------------------------------	
		DECLARE @table_LoginLogout TABLE
		(uid    INT, 
		 cam_id INT, 
		 login  DATETIME, 
		 logout DATETIME
		);
		INSERT INTO @table_LoginLogout
			   SELECT Login.[user_id] AS [uid], 
					  cam_id AS [cam_id], 
					  fecha AS [login], 
			   (
				   SELECT MIN(subLogin.fecha)
				   FROM ccPosicionCamps subLogin --with(index(ix_pc_tipo_fecha_user),nolock)
				   WHERE subLogin.tipo = 0
						 AND subLogin.fecha > Login.fecha
						 AND subLogin.[user_id] = Login.[user_id]
						 AND sublogin.[cam_id] = Login.[cam_id]
			   ) AS [logout]
			   FROM ccPosicionCamps Login --with(index(ix_pc_tipo_fecha),nolock)
			   WHERE tipo = 1
					 AND login.fecha >= DATEADD(dd, -2, @fechai)
			   GROUP BY Login.[user_id], 
						Login.cam_id, 
						Login.fecha;	
		------------------------------------------------------------------------------------------------
		DECLARE @table_LoginLogoutMax TABLE
		(uid    INT, 
		 cam_id INT, 
		 login  DATETIME, 
		 logout DATETIME
		);
		INSERT INTO @table_LoginLogoutMax
			   SELECT ccPosicionCamps.[user_id] AS [uid], 
					  ccPosicionCamps.cam_id AS cam_id, 
					  fecha AS [login], 
					  Login.logout
			   FROM
			   (
				   SELECT uid, 
						  cam_id, 
						  MAX(login) AS login, 
						  logout
				   FROM @table_LoginLogout LogDet
				   GROUP BY uid, 
							cam_id, 
							logout
			   ) Login
			   RIGHT OUTER JOIN ccPosicionCamps --with(index(ix_pc_tipo_fecha_user),nolock)
			   ON(ccPosicionCamps.[user_id] = Login.uid
				  AND ccPosicionCamps.fecha = Login.login
				  AND ccPosicionCamps.cam_id = Login.cam_id)
			   WHERE tipo = 1
					 AND ccPosicionCamps.fecha >= DATEADD(dd, -2, @fechai);
		------------------------------------------------------------------------------------------------
		DECLARE @table_LoginLogoutACD TABLE
		(uid        INT, 
		 inbound_id INT, 
		 login      DATETIME, 
		 logout     DATETIME
		);
		INSERT INTO @table_LoginLogoutACD
			   SELECT Login.[user_id] AS [uid], 
					  Inbound_id, 
					  fecha AS [login], 
			   (
				   SELECT MIN(subLogin.fecha)
				   FROM ccPosicionEspecialidad subLogin --with(index(ix_pe_tipo_fecha_user),nolock)
				   WHERE subLogin.tipo = 0
						 AND subLogin.fecha > Login.fecha
						 AND subLogin.[user_id] = Login.[user_id]
						 AND sublogin.Inbound_id = Login.Inbound_id
			   ) AS [logout]
			   FROM ccPosicionEspecialidad Login --with(index(ix_pe_tipo_fecha),nolock)
			   WHERE tipo = 1
					 AND login.fecha >= DATEADD(dd, -2, @fechai)
			   GROUP BY Login.[user_id], 
						Login.Inbound_id, 
						Login.fecha;
		----------------------------------------------------------------------------------------------
		CREATE TABLE #tiempo_cocallsout
		(tipo       INT, 
		 USER_ID    SMALLINT, 
		 ncallsout  INT, 
		 ncalls     INT, 
		 pcalls     INT, 
		 pcallsout  INT, 
		 tdialog    INT, 
		 tdialogout INT, 
		 fecha      VARCHAR(10), 
		 skill      INT
		);
		INSERT INTO #tiempo_cocallsout
			   SELECT 1 tipo, 
					  USER_ID, 
					  COUNT(*) ncallsout, 
					  0 ncalls, 
					  0 pcalls, 
					  AVG(cal_tdialog) pcallsout, 
					  0 tdialog, 
					  SUM(cal_tdialog) tdialogout, 
					  CONVERT(VARCHAR(10), cal_inicio, 121) fecha, 
					  co.cam_id skill
			   FROM ccocallsout co WITH (INDEX(IX_ccoCallsOut_2), NOLOCK)
			   WHERE cal_inicio BETWEEN @fechai AND @fechaf
			   GROUP BY USER_ID, 
						CONVERT(VARCHAR(10), cal_inicio, 121), 
						co.cam_id;
		----------------------------------------------------------------------------------------------
		CREATE TABLE #tiempo_cccallsin
		(tipo       INT, 
		 USER_ID    SMALLINT, 
		 ncallsout  INT, 
		 ncalls     INT, 
		 pcalls     INT, 
		 pcallsout  INT, 
		 tdialog    INT, 
		 tdialogout INT, 
		 fecha      VARCHAR(10), 
		 skill      INT
		);
		INSERT INTO #tiempo_cccallsin
			   SELECT 0 tipo, 
					  USER_ID, 
					  0 ncallsout, 
					  COUNT(*) ncalls, 
					  AVG(cal_tdialog) pcalls, 
					  0 pcallsout, 
					  SUM(cal_tdialog) tdialog, 
					  0 tdialogout, 
					  CONVERT(VARCHAR(10), cal_inicio, 121) fecha, 
					  ci.inbound_id skill
			   FROM cccallsin ci WITH (INDEX(IX_ccCallsIn), NOLOCK)
			   WHERE cal_inicio BETWEEN @fechai AND @fechaf
			   GROUP BY USER_ID, 
						CONVERT(VARCHAR(10), cal_inicio, 121), 
						ci.inbound_id;
		DECLARE @ccLogCamps TABLE
		(uid    INT, 
		 cam_id INT, 
		 login  DATETIME, 
		 logout DATETIME
		);
		INSERT INTO @ccLogCamps
			   SELECT uid, 
					  cam_id, 
					  login, 
					  MAX(logout) AS logout
			   FROM
			   (
				   SELECT uid, 
						  cam_id, 
						  login, 
						  ISNULL(logout,
				   (
					   SELECT MIN(fecha)
					   FROM ccPosicionCamps --with(index(ix_pc_tipo_fecha_user),nolock)
					   WHERE tipo = 1
							 AND fecha > Detail.login
							 AND [user_id] = Detail.uid
							 AND cam_id = Detail.cam_id
				   )) AS logout
				   FROM @table_LoginLogoutMax Detail
			   ) LoginDet
			   WHERE login >= @fechai
					 AND login < @fechaf
			   GROUP BY uid, 
						cam_id, 
						login;
		DECLARE @ccLogACD TABLE
		(uid        INT, 
		 inbound_id INT, 
		 login      DATETIME, 
		 logout     DATETIME
		);
		INSERT INTO @ccLogACD
			   SELECT uid, 
					  inbound_id, 
					  login, 
					  MAX(logout) AS logout
			   FROM
			   (
				   SELECT uid, 
						  inbound_id, 
						  login, 
						  ISNULL(logout,
				   (
					   SELECT MIN(fecha)
					   FROM ccPosicionEspecialidad --with(index(ix_pe_tipo_fecha_user),nolock)
					   WHERE tipo = 1
							 AND fecha > Detail.login
							 AND [user_id] = Detail.uid
							 AND inbound_id = Detail.inbound_id
				   )) AS logout
				   FROM
				   (
					   SELECT ccPosicionEspecialidad.[user_id] AS [uid], 
							  ccPosicionEspecialidad.Inbound_id AS inbound_id, 
							  fecha AS [login], 
							  Login.logout
					   FROM
					   (
						   SELECT uid, 
								  Inbound_id, 
								  MAX(login) AS login, 
								  logout
						   FROM @table_LoginLogoutACD LogDet
						   GROUP BY uid, 
									Inbound_id, 
									logout
					   ) Login
					   RIGHT OUTER JOIN ccPosicionEspecialidad --with(index(ix_pe_tipo_fecha_user),nolock)
					   ON(ccPosicionEspecialidad.[user_id] = Login.uid
						  AND ccPosicionEspecialidad.fecha = Login.login
						  AND ccPosicionEspecialidad.Inbound_id = Login.Inbound_id)
					   WHERE tipo = 1
							 AND ccPosicionEspecialidad.fecha >= DATEADD(dd, -2, @fechai)
				   ) Detail
			   ) LoginDet
			   WHERE login >= @fechai
					 AND login < @fechaf
			   GROUP BY uid, 
						inbound_id, 
						login;
		IF OBJECT_ID(''tempdb..#ccLog3'') IS NOT NULL
			DROP TABLE #agent_ccLogAgentesNotReady;
		CREATE TABLE #ccLog3
		(fecha   DATETIME, 
		 tipo    INT, 
		 skill   INT, 
		 split   VARCHAR(255), 
		 user_id INT, 
		 tlogueo INT
		);
		INSERT INTO #ccLog3
			   SELECT CONVERT(VARCHAR(10), cclog.login, 121) fecha, 
					  1 tipo, 
					  CCLOG.cam_id skill, 
					  cam_descripcion split, 
					  CCLOG.uid user_id,
					  CASE
						  WHEN CONVERT(VARCHAR(10), CCLOG.login, 121) = CONVERT(VARCHAR(10), GETDATE(), 121)
						  THEN DATEDIFF(ss, CCLOG.login, ISNULL(CCLOG.logout, GETDATE()))
						  ELSE DATEDIFF(ss, CCLOG.login, CCLOG.logout)
					  END tlogueo
			   FROM @ccLogCamps CCLOG
					JOIN ccCamps ca(NOLOCK) ON ca.cam_id = CCLOG.cam_id
			   UNION
			   SELECT CONVERT(VARCHAR(10), cclog.login, 121) fecha, 
					  0 tipo, 
					  CCLOG.inbound_id skill, 
					  descripcion split, 
					  CCLOG.uid user_id,
					  CASE
						  WHEN CONVERT(VARCHAR(10), CCLOG.login, 121) = CONVERT(VARCHAR(10), GETDATE(), 121)
						  THEN DATEDIFF(ss, CCLOG.login, ISNULL(CCLOG.logout, GETDATE()))
						  ELSE DATEDIFF(ss, CCLOG.login, CCLOG.logout)
					  END tlogueo
			   FROM @ccLogACD CCLOG
					JOIN ccInbound ib(NOLOCK) ON ib.Inbound_id = CCLOG.inbound_id;

		----****************************************************
		----Insert en la tabla RepMKTIntervaloTiempoPorCampana
		----****************************************************
		set @sqls = SUBSTRING(@sqls, 1, DATALENGTH(@sqls) - 1);

		SET @sql = ''
		DELETE RepMKTIntervaloCampana where Fecha=@fechai and Server=@ip
		INSERT INTO RepMKTIntervaloCampana (Hora,Fecha,CentroACD,[Server],NombredelAgente,
					IDConexion,HoraConexion,HoraDesconexion,SplitCampana,Skill,TiempoConPersonal,
					LlamadasACD,TiempoPromLlamadas,TiempoACD,TiempoOtraHora,TiempoDisponible,LlamadasSalida,
					TiempoPromLlamadaSalida,TiempoLlamadaSalida,TiempoACW,'' + @cols + '' )
		SELECT CONVERT(SMALLDATETIME, GETDATE()), 
			   logs.fecha, 
			   @centro CentroACD, 
			   @ip Server, 
			   nombres + '''' '''' + apellidopaterno + '''' '''' + apellidomaterno NombredelAgente, 
			   us.login IDconexion, 
			   logs.login HoraConexion, 
			   logs.logout HoraDesconexion, 
			   ISNULL(split, ''''Sin campaa'''') Splitcampana, 
			   ISNULL(log2.Skill, 0) Skill, 
			   ISNULL(tlogueo, 0) TiempoconPersonal, 
			   ISNULL(ncalls, 0) LlamadasACD, 
			   ISNULL(pcalls, 0) TiempoPromLlamadas, 
			   ISNULL(tdialog, 0) TiempoACD, 
			   totro TiempoOtraHora, 
			   tready TiempoDisponible, 
			   ISNULL(ncallsout, 0) LlamadasSalida, 
			   ISNULL(pcallsout, 0) TiempoPromLLamadaSalida, 
			   ISNULL(tdialogout, 0) TiempoLlamadaSalida, 
			   tnotas TiempoACW,
			   '' + @sqls + ''
		FROM #table_ccloglogin logs
			 JOIN ccUsers us(NOLOCK) ON us.User_id = logs.User_id
			 LEFT JOIN #timeAgent lo ON lo.User_id = logs.User_id
										AND lo.fecha = logs.fecha
			 LEFT JOIN #agent_ccLogAgentesNotReady lon ON lon.user_id = logs.user_id
														  AND lon.fecha = logs.fecha
			 LEFT JOIN
		(
			SELECT fecha, 
				   tipo, 
				   skill, 
				   split, 
				   USER_ID, 
				   SUM(tlogueo) tlogueo
			FROM #ccLog3 log3
			GROUP BY fecha, 
					 tipo, 
					 skill, 
					 split, 
					 USER_ID
		) log2 ON log2.user_id = logs.user_id
				  AND log2.fecha = logs.fecha
			 LEFT JOIN
		(
			SELECT *
			FROM #tiempo_cocallsout
			UNION
			SELECT *
			FROM #tiempo_cccallsin
		) co ON co.user_id = logs.user_id
				AND co.tipo = log2.tipo
				AND co.skill = log2.skill
				AND co.fecha = logs.fecha
		ORDER BY fecha, 
				 skill, 
				 NombredelAgente;
		'';
		PRINT @sql;
		EXEC sp_executesql      @sql,      N''@fechai datetime, @fechaf datetime,@centro VARCHAR(100),@ip VARCHAR(15)'',      @fechai,      @fechaf,      @centro,      @ip;




		END
		------select * from RepMKTIntervaloCampana


		IF OBJECT_ID(''tempdb..#agent_ccLogAgentesNotReady'') IS NOT NULL
			DROP TABLE #agent_ccLogAgentesNotReady;
		IF OBJECT_ID(''tempdb..#ccLog3'') IS NOT NULL
			DROP TABLE #ccLog3;
		IF OBJECT_ID(''tempdb..#tiempo_cocallsout'') IS NOT NULL
			DROP TABLE #tiempo_cocallsout;
		IF OBJECT_ID(''tempdb..#tiempo_cccallsin'') IS NOT NULL
			DROP TABLE #tiempo_cccallsin;
		IF OBJECT_ID(''tempdb..#table_ccloglogin'') IS NOT NULL
			DROP TABLE #table_ccloglogin;
			IF OBJECT_ID(''tempdb..#timeAgent'') IS NOT NULL
			DROP TABLE #timeAgent;'
		EXEC(@sql)

		
		IF @actualVersion = @version - 1
		--	EXEC ccsp_getVersion 'BD', @version

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
