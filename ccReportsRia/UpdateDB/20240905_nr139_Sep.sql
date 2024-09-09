/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 128

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
SET @version = 139 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
-------------------------------------------------------------------BEGIN ULISES -----------------------------------------------------------------------------
	set @process = 'DEV1-605 Cambios en el reporte efectividad ccspRepInEffectivenes insert ccSettings 45'
	set @sql = 'if not exists( select * from ccSettings where setting_id=45)
begin
	insert into ccSettings values(45,''0'',''reporte ccspRepInEffectiveness si el valor es 1 este debe solo contar los horarios de las campañas de entrada'',1,''RPT'')
end

'
	EXEC(@sql)

	SET @process = 'DEV1-605 Drop procedure ccspRepInEffectiveness '
	SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepInEffectiveness'')
	BEGIN
	    DROP PROCEDURE ccspRepInEffectiveness;
	END'
	EXEC(@sql)

	SET @process = 'Create procedure ccspRepInEffectiveness '
	SET @sql = 'USE [CCReportsRIA]
GO

/****** Object:  StoredProcedure [dbo].[ccspRepInEffectiveness]    Script Date: 06/09/2024 12:33:44 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ccspRepInEffectiveness] 
    @action TINYINT, 
    @from DATETIME = NULL, 
    @to DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET ANSI_NULLS OFF;
    SET ANSI_WARNINGS OFF;

	 SET DATEFIRST 1;

    -- Set default values for @from and @to if not provided
    IF @from IS NULL
        SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

    IF @to IS NULL
        SELECT @to = GETDATE();

    -- Begin action logic
    IF @action = 1
    BEGIN
		-- Check if the temporary tables exist before dropping them
	IF OBJECT_ID(''tempdb..#ccGenInCall'') IS NOT NULL
		DROP TABLE #ccGenInCall;

	IF OBJECT_ID(''tempdb..#ccGenInSpec'') IS NOT NULL
		DROP TABLE #ccGenInSpec;

	IF OBJECT_ID(''tempdb..#ccGenSession'') IS NOT NULL
		DROP TABLE #ccGenSession;

	IF OBJECT_ID(''tempdb..#agents'') IS NOT NULL
		DROP TABLE #agents;

	IF OBJECT_ID(''tempdb..#ccGenInAbnd'') IS NOT NULL
		DROP TABLE #ccGenInAbnd;

	IF OBJECT_ID(''tempdb..#AgentsperInbound'') IS NOT NULL
		DROP TABLE #AgentsperInbound;

        DECLARE @validateSch INT = 0;

        SELECT @validateSch = CASE WHEN valor = ''1'' THEN 1 ELSE 0 END 
        FROM ccSettings 
        WHERE setting_id = 45;

        -- Create temporary tables
		CREATE TABLE [dbo].[#ccGenSession] (
			[user_id] SMALLINT NOT NULL, 
			fechaInicio DATETIME NOT NULL, 
			[tlog] INT NOT NULL
		) ON [PRIMARY];

		CREATE TABLE #AgentsperInbound (
			NumberAgents INT, 
			fechaInicio DATETIME, 
			fechaFinal DATETIME, 
			Inbound_id INT
		);

		-- Create more temporary tables for further processing
		CREATE TABLE [dbo].[#ccGenInCall] (
			[timegroup] DATETIME NOT NULL, 
			[inbound_id] SMALLINT NOT NULL, 
			[dni_id] SMALLINT NOT NULL, 
			[user_id] SMALLINT NOT NULL, 
			[ntotal] SMALLINT NOT NULL, 
			[nabnd] SMALLINT NOT NULL, 
			[nno_agent] SMALLINT NOT NULL, 
			[nque] SMALLINT NOT NULL, 
			[ntimeout] SMALLINT NOT NULL, 
			[noverflow] SMALLINT NOT NULL, 
			[nno_answer] SMALLINT NOT NULL, 
			[nanswer] SMALLINT NOT NULL, 
			[nlost] SMALLINT NOT NULL, 
			[nabnd_tres] SMALLINT NOT NULL, 
			[nansw_tres] SMALLINT NOT NULL, 
			[tque_max] SMALLINT NOT NULL, 
			[tque] INT NOT NULL, 
			[txfer] INT NOT NULL, 
			[tdialog] INT NOT NULL, 
			[tnotes] INT NOT NULL, 
			[tring] INT NOT NULL, 
			[tresp] INT NOT NULL, 
			[nMoh] SMALLINT NOT NULL DEFAULT (0), 
			[nWHag] SMALLINT NOT NULL DEFAULT (0), 
			[nWHcl] SMALLINT NOT NULL DEFAULT (0)
		) ON [PRIMARY];

		CREATE TABLE [dbo].[#agents] (
			[timegroup] DATETIME NOT NULL, 
			[user_id] SMALLINT NOT NULL, 
			[tlog] INT NOT NULL DEFAULT (0), 
			[treq] INT NOT NULL DEFAULT (0), 
			[tnot_av] INT NOT NULL, 
			[tav] INT NOT NULL DEFAULT (0), 
			[tprob] INT NOT NULL DEFAULT (0), 
			[tunknown] INT NOT NULL DEFAULT (0), 
			[tother] INT NOT NULL DEFAULT (0), 
			[nother] INT NOT NULL DEFAULT (0), 
			[nMoh] INT NOT NULL DEFAULT (0), 
			[nWHag] INT NOT NULL DEFAULT (0), 
			[nWHcl] INT NOT NULL DEFAULT (0)
		) ON [PRIMARY];

		CREATE TABLE [dbo].[#ccGenInSpec] (
			[timegroup] DATETIME NOT NULL, 
			[inbound_id] SMALLINT NOT NULL, 
			[pos_tot] SMALLINT NOT NULL, 
			[pos_time] INT NOT NULL, 
			[pos_efect] SMALLINT NOT NULL
		) ON [PRIMARY];

		CREATE TABLE [dbo].[#ccGenInAbnd] (
			[timegroup] DATETIME NOT NULL, 
			[inbound_id] SMALLINT NOT NULL, 
			[amount] SMALLINT NOT NULL, 
			[time_max] SMALLINT NOT NULL, 
			[time_tot] BIGINT NOT NULL, 
			[<10] SMALLINT NOT NULL, 
			[<20] SMALLINT NOT NULL, 
			[<30] SMALLINT NOT NULL, 
			[<40] SMALLINT NOT NULL, 
			[<50] SMALLINT NOT NULL, 
			[<60] SMALLINT NOT NULL, 
			[<120] SMALLINT NOT NULL, 
			[<180] SMALLINT NOT NULL, 
			[<240] SMALLINT NOT NULL, 
			[<300] SMALLINT NOT NULL, 
			[+300] SMALLINT NOT NULL
		) ON [PRIMARY];

		
       -- Populate #ccGenSession
		INSERT INTO [#ccGenSession]
		SELECT 
			A.user_id, 
			CONVERT(DATETIME, CONVERT(VARCHAR(14), timegroup, 121) + ''00:00'', 121) AS fechaInicio, 
			SUM(tlog) AS tlog
		FROM TmpSessionTimeGroup A
		GROUP BY A.user_id, 
				 CONVERT(DATETIME, CONVERT(VARCHAR(14), timegroup, 121) + ''00:00'', 121);
		

		
		-- Populate #AgentsperInbound
		WITH RtnValue3 AS (
			SELECT DISTINCT 
				1 AS cont, 
				A.user_id, 
				B.Inbound_id, 
				A.fechaInicio, 
				DATEADD(HOUR, 1, A.fechaInicio) AS fechaFinal
			FROM [#ccGenSession] A
			INNER JOIN ccinboundagentes B
				ON A.user_id = B.User_id
		)
		INSERT INTO #AgentsperInbound
		SELECT 
			SUM(cont) AS NumberAgents, 
			fechaInicio, 
			fechaFinal, 
			Inbound_id
		FROM RtnValue3
		GROUP BY fechaInicio, fechaFinal, Inbound_id;

		
        

       -- Insert into #ccGenInCall
		INSERT INTO #ccGenInCall (
			timegroup, inbound_id, dni_id, [user_id], ntotal, nabnd, nno_agent, nque, ntimeout, noverflow, 
			nno_answer, nanswer, nlost, nabnd_tres, nansw_tres, tque_max, tque, txfer, tring, tdialog, 
			tnotes, tresp, nMoh, nWHag, nWHcl
		)
		SELECT 
			CONVERT(DATETIME, CONVERT(VARCHAR(14), dateStartDetail, 121) + ''00:00'', 121) AS timegroup, 
			Inbound_id, dni_id, User_id, 
			ISNULL(SUM(ntotal), 0) AS ntotal, 
			ISNULL(SUM(nabnd), 0) AS nabnd, 
			ISNULL(SUM(nno_agent), 0) AS nno_agent, 
			ISNULL(SUM(nque), 0) AS nque, 
			ISNULL(SUM(ntimeout), 0) AS ntimeout, 
			ISNULL(SUM(noverflow), 0) AS noverflow, 
			ISNULL(SUM(nno_answer), 0) AS nno_answer, 
			ISNULL(SUM(nanswer), 0) AS nanswer, 
			ISNULL(SUM(nlost), 0) AS nlost, 
			ISNULL(SUM(nabnd_tres), 0) AS nabnd_tres, 
			ISNULL(SUM(nansw_tres), 0) AS nansw_tres, 
			ISNULL(MAX(tque_max), 0) AS tque_max, 
			ISNULL(SUM(tque), 0) AS tque, 
			ISNULL(SUM(txfer), 0) AS txfer, 
			ISNULL(SUM(tring), 0) AS tring, 
			ISNULL(SUM(tdialog), 0) AS tdialog, 
			ISNULL(SUM(tnotes), 0) AS tnotes, 
			ISNULL(SUM(tresp), 0) AS tresp, 
			ISNULL(SUM(nMoh), 0) AS nMoh, 
			ISNULL(SUM(nWHag), 0) AS nWHag, 
			ISNULL(SUM(nWHcl), 0) AS nWHcl
		FROM tmpTimesInboundData
		GROUP BY CONVERT(DATETIME, CONVERT(VARCHAR(14), dateStartDetail, 121) + ''00:00'', 121), inbound_id, dni_id, [user_id];
		
		
		-- Time Agent processing
		WITH timeAgent AS (
			SELECT 
				CONVERT(DATETIME, CONVERT(VARCHAR(14), timegroup, 121) + ''00:00'', 121) AS timegroup, 
				userId, 
				ISNULL(SUM(CASE WHEN (tipostatusage_id = 2) THEN tStatus ELSE NULL END), 0) AS tnot_av, 
				ISNULL(SUM(CASE WHEN (tipostatusage_id = 3) THEN tStatus ELSE NULL END), 0) AS tav, 
				ISNULL(SUM(CASE WHEN (tipostatusage_id = 11) THEN tStatus ELSE NULL END), 0) AS tprob, 
				ISNULL(SUM(CASE WHEN (tipostatusage_id = 1) THEN tStatus ELSE NULL END), 0) AS tunknown, 
				ISNULL(SUM(CASE WHEN (tipostatusage_id = 7) THEN tStatus ELSE NULL END), 0) AS tother, 
				COUNT(CASE WHEN (tipostatusage_id = 7) THEN 1 ELSE NULL END) AS nother
			FROM tmpccLogAgentesDia
			GROUP BY CONVERT(DATETIME, CONVERT(VARCHAR(14), timegroup, 121) + ''00:00'', 121), userId
		)
		INSERT INTO #agents (timegroup, [user_id], tlog, tnot_av, tav, tprob, tunknown, tother, nother, nMoh, nWHag, nWHcl)
		SELECT 
			A.fechaInicio AS timegroup, 
			A.user_id, 
			A.tlog, 
			ISNULL(B.tnot_av, 0) AS tnot_av, 
			ISNULL(B.tav, 0) AS tav, 
			ISNULL(B.tprob, 0) AS tprob, 
			ISNULL(B.tunknown, 0) AS tunknown, 
			ISNULL(B.tother, 0) AS tother, 
			ISNULL(B.nother, 0) AS nother, 
			ISNULL(ci.nMoh, 0) AS nMoh, 
			ISNULL(ci.nWHag, 0) AS nWHag, 
			ISNULL(ci.nWHcl, 0) AS nWHcl
		FROM [#ccGenSession] A
		LEFT JOIN timeAgent B
			ON A.user_id = B.userId AND A.fechaInicio = B.timegroup
		LEFT JOIN #ccGenInCall ci
			ON A.user_id = ci.user_id AND A.fechaInicio = ci.timegroup;

		-- Insert into #ccGenInSpec
		INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
		SELECT 
			timegroup, 
			ccInboundAgentes.inbound_id, 
			COUNT(DISTINCT #agents.[user_id]) AS pos_max, 
			SUM(tlog - (tnot_av + tprob + tother)) AS pos_time, 
			COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
		FROM #agents
		INNER JOIN ccInboundAgentes
			ON #agents.[user_id] = ccInboundAgentes.[user_id]
		WHERE timegroup >= @from
		  AND timegroup < @to
		  AND INBOUND_ID > 0
		GROUP BY timegroup, ccInboundAgentes.inbound_id;


        -- Call Abandoned processing
		WITH callInAbnd AS (
			SELECT 
				CONVERT(DATETIME, CONVERT(VARCHAR(14), timegroup, 121) + ''00:00'', 121) AS timegroup, 
				inbound_id, 
				tque + txfer + tring AS tAbnd, 
				nabnd, 
				CASE WHEN statuscall_id IN (5, 6) AND nabnd > 0 THEN 1 ELSE 0 END AS nabnd2
			FROM tmpTimesInboundData
			WHERE statuscall_id IN (5, 6)
		)
		INSERT INTO #ccGenInAbnd
		SELECT 
			timegroup, 
			inbound_id, 
			SUM(nabnd2) AS amount, 
			MAX(tAbnd) AS time_max, 
			SUM(tAbnd) AS time_tot, 
			COUNT(CASE WHEN tAbnd < 10 THEN 1 ELSE NULL END) AS [<10], 
			COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19 THEN 1 ELSE NULL END) AS [<20], 
			COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29 THEN 1 ELSE NULL END) AS [<30], 
			COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39 THEN 1 ELSE NULL END) AS [<40], 
			COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49 THEN 1 ELSE NULL END) AS [<50], 
			COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59 THEN 1 ELSE NULL END) AS [<60], 
			COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119 THEN 1 ELSE NULL END) AS [<120], 
			COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179 THEN 1 ELSE NULL END) AS [<180], 
			COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239 THEN 1 ELSE NULL END) AS [<240], 
			COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299 THEN 1 ELSE NULL END) AS [<300], 
			COUNT(CASE WHEN tAbnd >= 300 THEN 1 ELSE NULL END) AS [+300]
		FROM callInAbnd
		GROUP BY timegroup, inbound_id;

		-- Remove old data from RepInEffectiveness
		DELETE FROM RepInEffectiveness
		WHERE DATE >= @from
		  AND DATE < @to;

		-- Final query to insert data into RepInEffectiveness
		WITH xDetCall AS (
			SELECT 
				timegroup, 
				inbound_id, 
				SUM(ntotal) AS ntotal, 
				SUM(nanswer) AS nanswer, 
				SUM(nabnd) AS nabnd, 
				SUM(tdialog + tnotes) AS tatention, 
				ISNULL(SUM(tque) / NULLIF(SUM(nque), 0), 0) AS tque_avg, 
				SUM(tque) AS tQue_tot, 
				SUM(nQue) AS nQue_tot, 
				SUM(nansw_tres + nabnd_tres) AS SL_P_1, 
				SUM(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, 
				SUM(tresp) AS tresp
			FROM #ccGenInCall
			WHERE timegroup >= @from
			  AND timegroup < @to
			GROUP BY timegroup, inbound_id
		), xDetSpec AS (
			SELECT 
				timegroup, 
				inbound_id, 
				SUM(pos_tot) AS pos_tot, 
				SUM(pos_tot) AS pos_avg, 
				SUM(pos_efect) AS pos_efect
			FROM #ccGenInSpec
			WHERE timegroup >= @from
			  AND timegroup < @to
			GROUP BY timegroup, inbound_id
		), xDetAbnd AS (
			SELECT 
				timegroup, 
				inbound_id, 
				SUM(time_tot) AS tabnd_tot
			FROM #ccGenInAbnd
			WHERE timegroup >= @from
			  AND timegroup < @to
			GROUP BY timegroup, inbound_id
		), xDetail AS (
			SELECT 
				ISNULL(xDetCall.timegroup, ISNULL(xDetSpec.timegroup, xDetAbnd.timegroup)) AS timegroup, 
				ISNULL(xDetCall.inbound_id, ISNULL(xDetSpec.inbound_id, xDetAbnd.inbound_id)) AS inbound_id, 
				ISNULL(ntotal, 0) AS ntotal, 
				ISNULL(nanswer, 0) AS nanswer, 
				ISNULL(nabnd, 0) AS nabnd, 
				ISNULL(tatention, 0) AS tatention, 
				ISNULL(tque_avg, 0) AS tque_avg, 
				ISNULL(tQue_tot, 0) AS tQue_tot, 
				ISNULL(nQue_tot, 0) AS nQue_tot, 
				ISNULL(tabnd_tot, 0) AS tabnd_tot, 
				ISNULL(SL_P_1, 0) AS SL_P_1, 
				ISNULL(SL_P_2, 0) AS SL_P_2, 
				ISNULL(tresp, 0) AS tresp, 
				ISNULL(pos_tot, 0) AS pos_tot
			FROM xDetCall
			LEFT JOIN xDetSpec
				ON xDetCall.timegroup = xDetSpec.timegroup
			   AND xDetCall.inbound_id = xDetSpec.inbound_id
			LEFT JOIN xDetAbnd
				ON xDetCall.timegroup = xDetAbnd.timegroup
			   AND xDetCall.inbound_id = xDetAbnd.inbound_id
		)
		, FilteredRecords AS (
			SELECT 				
				timegroup AS [DATE],
				x.inbound_id,
				ISNULL(ccinbound.descripcion, ''systemTranslated_NoACDGroup'') AS descripcion,
				ntotal,
				nanswer,
				nabnd,
				ISNULL(tatention / NULLIF(nanswer, 0), 0) AS tatencion,
				tque_avg,
				tQue_tot,
				nQue_tot,
				ISNULL(tabnd_tot / NULLIF(nabnd, 0), 0) AS avgAbandonTime,
				SL_P_1 AS SLP1,
				SL_P_2 AS SLP2,
				tresp,
				ISNULL(c.NumberAgents, 0) AS NumberAgents,
				ISNULL(SL_P_1 * 100 / NULLIF(SL_P_2, 0), 0) AS Porcentaje,
				DATEPART(yyyy, timegroup) AS [year],
				DATEPART(mm, timegroup) AS [month],
				DATEPART(dd, timegroup) AS [day],
				DATEPART(hh, timegroup) AS [hour],
				0 AS [minutes],
				CONVERT(DECIMAL(10, 2), (nabnd / NULLIF(CONVERT(DECIMAL(10, 2), ntotal), 0)) * 100) AS [avgAbandon],
				tabnd_tot AS tabndtot,
				h.Horario_id, h.HoraInicio, h.MinInicio, h.HoraFin, h.MinFin,
				ROW_NUMBER() OVER (PARTITION BY timegroup, x.inbound_id ORDER BY h.Horario_id DESC) AS rn
			FROM xDetail x
			LEFT JOIN ccInbound ON x.inbound_id = ccInbound.inbound_id
			LEFT JOIN #AgentsperInbound C ON x.inbound_id = C.Inbound_id AND x.timegroup = C.fechaInicio
			LEFT JOIN ccInboundHorarios ch ON ch.Inbound_id = x.inbound_id
			LEFT JOIN ccHorarios h ON h.horario_id = ch.Horario_id
			and (
				(DATEPART(WEEKDAY, x.timegroup) = 1 AND h.Lunes = 1 AND 
					(DATEPART(HOUR, x.timegroup) * 60 + DATEPART(MINUTE, x.timegroup) BETWEEN 
					h.HoraInicio * 60 + h.MinInicio AND h.HoraFin * 60 + h.MinFin))
				OR (DATEPART(WEEKDAY, x.timegroup) = 2 AND h.Martes = 1 AND 
					(DATEPART(HOUR, x.timegroup) * 60 + DATEPART(MINUTE, x.timegroup) BETWEEN 
					h.HoraInicio * 60 + h.MinInicio AND h.HoraFin * 60 + h.MinFin))
				OR (DATEPART(WEEKDAY, x.timegroup) = 3 AND h.Miercoles = 1 AND 
					(DATEPART(HOUR, x.timegroup) * 60 + DATEPART(MINUTE, x.timegroup) BETWEEN 
					h.HoraInicio * 60 + h.MinInicio AND h.HoraFin * 60 + h.MinFin))
				OR (DATEPART(WEEKDAY, x.timegroup) = 4 AND h.Jueves = 1 AND 
					(DATEPART(HOUR, x.timegroup) * 60 + DATEPART(MINUTE, x.timegroup) BETWEEN 
					h.HoraInicio * 60 + h.MinInicio AND h.HoraFin * 60 + h.MinFin))
				OR (DATEPART(WEEKDAY, x.timegroup) = 5 AND h.Viernes = 1 AND 
					(DATEPART(HOUR, x.timegroup) * 60 + DATEPART(MINUTE, x.timegroup) BETWEEN 
					h.HoraInicio * 60 + h.MinInicio AND h.HoraFin * 60 + h.MinFin))
				OR (DATEPART(WEEKDAY, x.timegroup) = 6 AND h.Sabado = 1 AND 
					(DATEPART(HOUR, x.timegroup) * 60 + DATEPART(MINUTE, x.timegroup) BETWEEN 
					h.HoraInicio * 60 + h.MinInicio AND h.HoraFin * 60 + h.MinFin))
				OR (DATEPART(WEEKDAY, x.timegroup) = 7 AND h.Domingo = 1 AND 
					(DATEPART(HOUR, x.timegroup) * 60 + DATEPART(MINUTE, x.timegroup) BETWEEN 
					h.HoraInicio * 60 + h.MinInicio AND h.HoraFin * 60 + h.MinFin))
			)
		)



        INSERT INTO RepInEffectiveness (
		date, inboundId, inbound, ntotalin, nanswer2, nabnd, tatencion, tqueavg, tQuetot, 
		nQuetot, avgAbandonTime, SLP1, SLP2, tresp, poscount, Porcentaje, 
		year, month, day, hour, minutes, avgAbandon, tabndtot
	)
	SELECT 	
		DATE, inbound_id, descripcion, ntotal, nanswer, nabnd, tatencion, tque_avg, tQue_tot, 
		nQue_tot, avgAbandonTime, SLP1, SLP2, tresp, NumberAgents, Porcentaje, 
		year, month, day, hour, minutes, avgAbandon, tabndtot
		
	FROM FilteredRecords 
	WHERE 
		ntotal > 0 
		AND (@validateSch = 0 OR horario_id IS NOT NULL)
		AND rn = 1
	ORDER BY inbound_id, date;


       
    -- Check if the temporary tables exist before dropping them
	IF OBJECT_ID(''tempdb..#ccGenInCall'') IS NOT NULL
		DROP TABLE #ccGenInCall;

	IF OBJECT_ID(''tempdb..#ccGenInSpec'') IS NOT NULL
		DROP TABLE #ccGenInSpec;

	IF OBJECT_ID(''tempdb..#ccGenSession'') IS NOT NULL
		DROP TABLE #ccGenSession;

	IF OBJECT_ID(''tempdb..#agents'') IS NOT NULL
		DROP TABLE #agents;

	IF OBJECT_ID(''tempdb..#ccGenInAbnd'') IS NOT NULL
		DROP TABLE #ccGenInAbnd;

	IF OBJECT_ID(''tempdb..#AgentsperInbound'') IS NOT NULL
		DROP TABLE #AgentsperInbound;
    END
END;
'
	EXEC(@sql)

	set @process = ''
	set @sql = ''
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
