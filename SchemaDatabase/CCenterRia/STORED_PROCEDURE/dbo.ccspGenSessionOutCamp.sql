CREATE PROCEDURE ccspGenSessionOutCamp
@from AS smalldatetime,
@to AS smalldatetime
AS
set nocount on
DECLARE @login_time datetime, @logout_time datetime
DECLARE @user_id smallint

-- Delete previous data in case of reprocess HLAS
DELETE ccGenSessionOutCamp WHERE login>=@from AND login<@to

DECLARE Session_Cursor CURSOR FOR
	SELECT [user_id], login, logout FROM ccGenSession WHERE login>@from and logout<@to

OPEN Session_Cursor
FETCH NEXT FROM Session_Cursor INTO @user_id, @login_time, @logout_time
WHILE @@fetch_status = 0 
 BEGIN

	INSERT INTO ccGenSessionOutCamp  (login, [user_id], cam_id, pos_tot, pos_time, pos_efect)
	SELECT @login_time, ccGenAgent.[user_id], ccCampsAgente.cam_id
		, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max
		, SUM(tlog - (tnot_av + tav + tprob + tother)) AS pos_time
		, COUNT(CASE WHEN (tlog - (tnot_av + tnot_av + tav + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
	FROM ccGenAgent INNER JOIN 
		(select distinct user_id, cam_id, prioridad, skill from ccCampsAgente) ccCampsAgente 
		ON (ccGenAgent.[user_id] = ccCampsAgente.[user_id])
	WHERE timegroup >= @login_time AND timegroup < @logout_time AND ccGenAgent.[user_id] = @user_id
	GROUP BY ccGenAgent.[user_id], ccCampsAgente.cam_id

 FETCH NEXT FROM Session_Cursor INTO @user_id, @login_time, @logout_time
 END
CLOSE Session_Cursor
DEALLOCATE Session_Cursor
set nocount off