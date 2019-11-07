CREATE PROCEDURE ccspGenSessionOutCall
@from AS smalldatetime,
@to AS smalldatetime
AS
DECLARE @user_id smallint
DECLARE @login_time datetime
DECLARE @logout_time datetime

DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint

EXEC @tresRing = ccspConfigTresRing
EXEC @tresDialog = ccspConfigTresDialog

-- Delete previous data in case of reprocess HLAS

DELETE ccGenSessionOutCall WHERE login >= @from AND login < @to


DECLARE Session_Cursor CURSOR FOR
	SELECT [user_id], login, logout
	 FROM ccGenSession
	 WHERE login > @from and logout < @to

OPEN Session_Cursor
FETCH NEXT FROM Session_Cursor INTO @user_id, @login_time, @logout_time
WHILE @@fetch_status = 0 
BEGIN
	INSERT INTO ccGenSessionOutCall (login, [user_id], cam_id
		, ntotal, nno_agent, nxfer, nabnd_xfer, nabnd_ring ,nno_answer
		, nabnd_dialog, nanswer, nlost
		, txfer, tring, tdialog, tnotes, tresp)
		SELECT @login_time AS timegroup
			, @user_id as [user_id]
			, cam_id
			, COUNT(cal_id) AS ntotal
			, COUNT(CASE WHEN (statuscall_id = 4) THEN 1 ELSE NULL END) AS nno_agent
			, COUNT(CASE WHEN (statuscall_id >= 10) THEN 1 ELSE NULL END) AS nxfer
			, COUNT(CASE WHEN ((statuscall_id = 11)) THEN 1 ELSE NULL END) AS abnd_xfer
			, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring <= @tresRing)) THEN 1 ELSE NULL END) AS abnd_ring
			, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring > @tresRing)) THEN 1 ELSE NULL END) AS no_answer
			, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  <= @tresDialog)) THEN 1 ELSE NULL END) AS abnd_dialog
			, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
			, COUNT(CASE WHEN (statuscall_id = 16) THEN 1 ELSE NULL END) AS lost
			, ISNULL(SUM(cal_txfer), 0) AS txfer
			, ISNULL(SUM(cal_tring), 0) AS tring
			, ISNULL(SUM(cal_tdialog), 0) AS tdialog
			, ISNULL(SUM(cal_tnotas), 0) AS tnotes
			, ISNULL(SUM(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN (cal_txfer + cal_tring) ELSE NULL END), 0) AS tresp
		 FROM ccoCallsOut
			WHERE cal_inicio >= @login_time AND  cal_inicio < @logout_time AND [user_id] = @user_id
		 GROUP BY cam_id
	FETCH NEXT FROM Session_Cursor INTO @user_id, @login_time, @logout_time
END
CLOSE Session_Cursor
DEALLOCATE Session_Cursor