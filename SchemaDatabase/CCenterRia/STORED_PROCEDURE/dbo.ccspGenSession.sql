CREATE PROCEDURE dbo.ccspGenSession
@from as smalldatetime,
@to as smalldatetime
AS
set nocount on
declare @to2 as smalldatetime
declare @from2 as smalldatetime
SELECT @to2=@to, @from2=@from

delete  from ccGenSession where login >= @from2 and login<@to2
INSERT INTO ccGenSession ([user_id], extension, login, logout)
SELECT uid, max(ext) ext, login, max(logout) logout
FROM 
	(SELECT uid, ext, login, ISNULL(logout, (SELECT MIN(fecha) FROM ccLogLogin with (nolock, index(IX_ccLogLogin_2))
	WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout 
	FROM
		(SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout
		FROM 
			(SELECT uid, ext, MAX(login) as login, logout
			FROM
				(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha) 
				FROM ccLogLogin subLogin with (nolock, index(IX_ccLogLogin_2)) WHERE subLogin.tipomov = 0 
				AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout] 
				FROM ccLogLogin Login with (nolock, index(IX_ccLogLogin_2))
				WHERE login.fecha >= dateadd(dd, -5, @from2) and tipomov = 1
				GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail 
			WHERE logout IS NOT NULL GROUP BY uid, ext, logout) Login 
		RIGHT OUTER JOIN ccLogLogin  with (nolock, index(IX_ccLogLogin_2))
		ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login AND ccLogLogin.extension = Login.ext)
		WHERE tipomov = 1
		and ccLogLogin.fecha >= dateadd( dd, -5, @from2)) Det 
	) LoginDetail 
WHERE logout IS NOT NULL
AND login >= @from2 and login < @to2
GROUP BY uid, login

return(0)
set nocount off