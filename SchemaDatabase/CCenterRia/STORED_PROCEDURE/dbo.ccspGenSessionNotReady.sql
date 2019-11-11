CREATE PROCEDURE ccspGenSessionNotReady
@from AS smalldatetime,
@to AS smalldatetime
AS
DECLARE @user_id smallint
DECLARE @login_time datetime
DECLARE @logout_time datetime
DECLARE @session int

-- Delete previous data in case of reprocess HLAS

DELETE ccGenSessionNotReady WHERE login >= @from AND login < @to


DECLARE Session_Cursor CURSOR FOR
	SELECT [user_id], login, logout, DATEDIFF(s, login, logout)
	 FROM ccGenSession
	 WHERE login > @from and logout < @to

OPEN Session_Cursor
FETCH NEXT FROM Session_Cursor INTO @user_id, @login_time, @logout_time, @session
WHILE @@fetch_status = 0 
BEGIN

	INSERT INTO ccGenSessionNotReady (login, [user_id], tiponotready_id, amount, [time])
		SELECT @login_time AS login, [user_id], tiponotready_id
			, COUNT(tStatus), SUM(tStatus)
		 FROM ccLogAgentesNotReady
		 WHERE DATEADD(ss, -tStatus, fecha) >= @login_time AND  DATEADD(ss, -tStatus, fecha) < @logout_time
			AND [user_id] = @user_id
		 GROUP BY [user_id], tiponotready_id

	FETCH NEXT FROM Session_Cursor INTO @user_id, @login_time, @logout_time, @session
END
CLOSE Session_Cursor
DEALLOCATE Session_Cursor