SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 114

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-7612 ccspGenSession DROP'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspGenSession'')
	begin
        DROP PROCEDURE ccspGenSession;
    end
	'
	EXEC(@sql)

	set @process = 'CW-7612 ccspGenSession CREATE'
	set @sql = '
CREATE PROCEDURE [dbo].[ccspGenSession]
@from AS SMALLDATETIME,
@to AS SMALLDATETIME
AS
SET NOCOUNT ON

DECLARE @date DATETIME

CREATE TABLE #tempccGenSession ([fila] INT NOT NULL, [user_id] [smallint] NOT NULL, [login] [datetime] NOT NULL, [logout] [datetime] NULL, [extension] [varchar](7) NOT NULL, PRIMARY KEY (fila, user_id))
CREATE TABLE #temUserIdLogoutNull ([user_id] [smallint] NOT NULL)
CREATE TABLE #temIdMaxLogoutNull ([fila] INT NOT NULL, [user_id] [smallint] NOT NULL, PRIMARY KEY (fila, user_id))

INSERT INTO #tempccGenSession
	SELECT A.Fila, A.User_id, dateadd(ms, - DATEPART(ms, A.fecha), A.fecha) LOGIN, dateadd(ms, - DATEPART(ms, S.fecha), S.fecha) logout, A.Extension
	FROM (
		SELECT ROW_NUMBER() OVER (
				PARTITION BY user_id ORDER BY FECHA, tipoMov
				) Fila, User_id, Extension, TipoMov, fecha
		FROM ccLogLogin a
		WHERE fecha >= @from
			AND fecha <= @to
			----------
			AND TipoMov=1
		) A
	RIGHT JOIN 
	(
		SELECT ROW_NUMBER() OVER (
				PARTITION BY user_id ORDER BY FECHA, tipoMov
				) Fila, User_id, Extension, TipoMov, fecha
		FROM ccLogLogin a
		WHERE fecha >= @from
			AND fecha <= @to
			----------
			AND TipoMov=0
		) S
		ON	
			A.Fila = S.Fila
			AND A.User_id = S.User_id
		WHERE A.TipoMov = 1
	ORDER BY LOGIN

	UPDATE x
	SET x.fila = x.row
	FROM (
		SELECT fila, ROW_NUMBER() OVER (
				PARTITION BY user_id ORDER BY LOGIN
				) row
		FROM #tempccGenSession
		) x

	INSERT INTO #temUserIdLogoutNull
		SELECT user_id
		FROM #tempccGenSession
		WHERE logout IS NULL
		GROUP BY user_id

	INSERT INTO #temIdMaxLogoutNull
		SELECT A.fila, A.user_id
		FROM #tempccGenSession A
		INNER JOIN (
			SELECT max(fila) fila, user_id
			FROM #tempccGenSession
			WHERE user_id IN (
					SELECT user_id
					FROM #temUserIdLogoutNull
					)
			GROUP BY user_id
			) B
			ON A.fila = B.fila
				AND A.user_id = B.user_id
		WHERE A.logout IS NULL

	SET @date = GETDATE()

	UPDATE A
		SET A.logout = CASE WHEN @to < @date THEN @to ELSE @date END
		FROM #tempccGenSession A
		INNER JOIN #temIdMaxLogoutNull B
			ON A.user_id = B.user_id
				AND A.fila = B.fila

	UPDATE A
		SET A.logout = (
				SELECT CASE WHEN max(fecha) IS NOT NULL THEN max(fecha) WHEN DATEDIFF(ss, A.LOGIN, B.LOGIN) < 2 THEN DATEADD(ms, - 10, B.LOGIN) ELSE DATEADD(ms, 5, A.LOGIN) END
				FROM ccLogAgentesDia C
				WHERE A.user_Id = C.User_id
					AND fecha BETWEEN A.LOGIN
						AND B.LOGIN
				)
		FROM #tempccGenSession A
		LEFT JOIN #tempccGenSession B
			ON A.fila = B.fila - 1
				AND A.user_id = B.user_id
		WHERE A.logout IS NULL

	DELETE
	FROM #tempccGenSession
	WHERE LOGIN = logout

	DELETE A
	FROM #tempccGenSession A
	INNER JOIN (
		SELECT user_id, [login], logout
		FROM #tempccGenSession
		GROUP BY user_id, [login], logout
		HAVING count(*) > 1
		) B
		ON A.user_id = B.user_id
			AND A.LOGIN = B.LOGIN
			AND A.logout = B.logout

	UPDATE a
	WITH (ROWLOCK)

	SET a.logout = b.logout
	FROM #tempccGenSession b
	INNER JOIN #tempccGenSession a
		ON a.user_id = b.user_id
			AND a.LOGIN = b.LOGIN
			AND a.logout <> b.logout;

	WITH tmpccGenSession
	AS (
		SELECT user_id, dateadd(ss, - 1, [login]) AS [login], convert(VARCHAR(19), dateadd(ss, 1, [logout]), 121) AS [logout], extension
		, dbo.GetTimeGroup(dateadd(ss, - 1, [login]), 0) AS timeGroup, dbo.GetTimeGroup(dateadd(ss, 1, [logout]), 1) AS timeGroupNext
		FROM #tempccGenSession
		)
	SELECT A.*, datediff(ss, [login], [logout]) AS tlog
	FROM tmpccGenSession A

DROP TABLE #tempccGenSession
DROP TABLE #temUserIdLogoutNull
DROP TABLE #temIdMaxLogoutNull

SET NOCOUNT OFF
    '
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
