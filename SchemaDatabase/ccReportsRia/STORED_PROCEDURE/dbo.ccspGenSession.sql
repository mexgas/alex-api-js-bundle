CREATE PROCEDURE [dbo].[ccspGenSession] @from AS SMALLDATETIME, @to AS SMALLDATETIME
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
	) A
LEFT JOIN (
	SELECT ROW_NUMBER() OVER (
			PARTITION BY user_id ORDER BY FECHA, tipoMov
			) Fila, User_id, Extension, TipoMov, fecha
	FROM ccLogLogin a
	WHERE fecha >= @from
		AND fecha <= @to
	) S
	ON A.Fila = S.Fila - 1
		AND A.User_id = S.User_id
		AND A.TipoMov = 1
		AND S.TipoMov = 0
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
		) --logout,
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

--select *,datediff(ss,login,logout) as tlog from(
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