CREATE PROCEDURE ccspGenSessionInCall
@from AS smalldatetime,
@to AS smalldatetime
AS
DECLARE @user_id smallint
DECLARE @login_time datetime
DECLARE @logout_time datetime

DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint
DECLARE @tresDelay AS smallint

EXEC @tresRing = ccspConfigTresRing
EXEC @tresDialog = ccspConfigTresDialog
EXEC @tresDelay = ccspConfigTresDelayIn

-- Delete previous data in case of reprocess HLAS

DELETE ccGenSessionInCall WHERE login >= @from AND login < @to

DECLARE Session_Cursor CURSOR FOR
	SELECT [user_id], login, logout
	 FROM ccGenSession
	 WHERE login > @from and logout < @to

OPEN Session_Cursor
FETCH NEXT FROM Session_Cursor INTO @user_id, @login_time, @logout_time
WHILE @@fetch_status = 0 
BEGIN
	INSERT INTO ccGenSessionInCall (login, [user_id], inbound_id
		, ntotal, nout_hour, nout_service
		, nabnd, no_agent, nque, ntimeout
		, noverflow, nxfer, nxfer_que
		, nabnd_xfer, nabnd_ring ,nno_answer
		, nabnd_dialog, nanswer, nlost, nmsg
		, nabnd_tres, nansw_tres, tque_max
		, tque, txfer, tring
		, tdialog, tnotes, tresp)
		SELECT @login_time AS timegroup
			, @user_id as [user_id]
			, inbound_id
			, COUNT(cal_id) AS ntotal
			, COUNT(CASE WHEN statuscall_id = 2 THEN 1 ELSE NULL END) AS out_hour 
			, COUNT(CASE WHEN statuscall_id = 3 THEN 1 ELSE NULL END) AS out_service
			, COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND cal_xfer IS NULL)  THEN 1 ELSE NULL END) AS abnd 
			, COUNT(CASE WHEN (statuscall_id = 4) THEN 1 ELSE NULL END) AS no_agent
			, COUNT(CASE WHEN (cal_que > 0) THEN 1 ELSE NULL END) AS que 
			, COUNT(CASE WHEN (statuscall_id = 7) THEN 1 ELSE NULL END) AS timeout
			, COUNT(CASE WHEN (statuscall_id = 8) THEN 1 ELSE NULL END) AS overflow
			--, COUNT(cal_xfer) AS xfer
			, COUNT(CASE WHEN( (statuscall_id in (11,15,13,16)) OR (statuscall_id = 6 AND cal_xfer IS NOT NULL) ) THEN 1 ELSE NULL END) AS xfer
			, COUNT(CASE WHEN (cal_que > 0) THEN cal_xfer ELSE NULL END) AS xfer_que
			, COUNT(CASE WHEN ((statuscall_id = 11) OR (statuscall_id = 6 AND cal_xfer IS NOT NULL)) THEN 1 ELSE NULL END) AS abnd_xfer
			, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring <= @tresRing)) THEN 1 ELSE NULL END) AS abnd_ring
			, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring > @tresRing)) THEN 1 ELSE NULL END) AS no_answer
			, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  <= @tresDialog)) THEN 1 ELSE NULL END) AS abnd_dialog
			, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
			, COUNT(CASE WHEN (statuscall_id = 16) THEN 1 ELSE NULL END) AS lost
			, COUNT(CASE WHEN (statuscall_id IN (9, 10, 12, 14)) THEN 1 ELSE NULL END) AS msg
			, COUNT(CASE WHEN (((statuscall_id IN (4, 5, 6, 11)) OR (statuscall_id = 15 AND cal_tring <= @tresRing) OR (statuscall_id = 13 AND cal_tdialog <= @tresDialog)) AND (cal_twait + cal_txfer + cal_tring > @tresDelay)) THEN 1 ELSE NULL END) AS abnd_tres
			, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog > @tresDialog) AND (cal_twait + cal_txfer + cal_tring > @tresDelay)) THEN 1 ELSE NULL END) AS answ_tres
			, ISNULL(MAX(cal_twait), 0) AS tque_max
			, ISNULL(SUM(cal_twait), 0) AS tque
			, ISNULL(SUM(cal_txfer), 0) AS txfer
			, ISNULL(SUM(cal_tring), 0) AS tring
			, ISNULL(SUM(cal_tdialog), 0) AS tdialog
			, ISNULL(SUM(cal_tnotas), 0) AS tnotes
			, ISNULL(SUM(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN (cal_twait + cal_txfer + cal_tring) ELSE NULL END), 0) AS tresp
		 FROM ccCallsIn
			--WHERE cal_inicio >= @login_time AND  cal_inicio < @logout_time AND [user_id] = @user_id and Inbound_id > 0
			WHERE cal_Xfer >= @login_time AND  cal_Xfer < @logout_time AND [user_id] = @user_id and Inbound_id > 0
				--AND NOT (cal_que = 0 AND [user_id] = 0)
		 GROUP BY inbound_id
	FETCH NEXT FROM Session_Cursor INTO @user_id, @login_time, @logout_time
END
CLOSE Session_Cursor
DEALLOCATE Session_Cursor