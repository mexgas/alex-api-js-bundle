CREATE PROCEDURE ccspGenSessionAgent
@from AS smalldatetime,
@to AS smalldatetime
AS
DECLARE @user_id smallint
DECLARE @login_time datetime
DECLARE @logout_time datetime
DECLARE @session int
DECLARE @tspec int

DECLARE @tcampa int

-- Delete previous data in case of reprocess HLAS

DELETE ccGenSessionAgent WHERE login >= @from AND login < @to


DECLARE Session_Cursor CURSOR FOR
	SELECT [user_id], login, logout, DATEDIFF(s, login, logout)
	 FROM ccGenSession
	 WHERE login >= @from and logout < @to

OPEN Session_Cursor
FETCH NEXT FROM Session_Cursor INTO @user_id, @login_time, @logout_time, @session
WHILE @@fetch_status = 0 
BEGIN
	SELECT @tspec = txfer + tdialog + tnotes + tring
	 FROM (
			SELECT ISNULL(SUM(ccGenSessionInCall.txfer), 0) AS txfer
				, ISNULL(SUM(ccGenSessionInCall.tdialog), 0) AS tdialog
				, ISNULL(SUM(ccGenSessionInCall.tnotes), 0) AS tnotes
				, ISNULL(SUM(ccGenSessionInCall.tring), 0) AS tring
			 FROM ccGenSessionInCall
			 WHERE login = @login_time AND [user_id] = @user_id
		) xDeta

	SELECT @tcampa = txfer + tdialog + tnotes + tring
	 FROM (
			SELECT ISNULL(SUM(ccGenSessionOutCall.txfer), 0) AS txfer
				, ISNULL(SUM(ccGenSessionOutCall.tdialog), 0) AS tdialog
				, ISNULL(SUM(ccGenSessionOutCall.tnotes), 0) AS tnotes
				, ISNULL(SUM(ccGenSessionOutCall.tring), 0) AS tring
			 FROM ccGenSessionOutCall
			 WHERE login = @login_time AND [user_id] = @user_id
		) xDetai



	INSERT INTO ccGenSessionAgent (login, [user_id], tlog, tnot_av, tav, tprob, tunknown, tother, nother)
		SELECT login, [user_id], tlog --tlog = @session
			, CASE WHEN tnot_av > tav AND tnot_av > tprob AND tnot_av > tother AND tnot_av > tunknown THEN tnot_av + (tlog - ttot) ELSE tnot_av END AS tnot_av
			, CASE WHEN tav >= tnot_av AND tav >= tprob AND tav >= tother AND tav >= tunknown THEN tav + (tlog - ttot) ELSE tav END AS tav
			, CASE WHEN tprob > tnot_av AND tprob > tav AND tprob > tother AND tprob > tunknown THEN tprob + (tlog - ttot) ELSE tprob END AS tprob
			, CASE WHEN tunknown > tnot_av AND tunknown > tav AND tunknown > tother AND tunknown > tprob THEN tunknown + (tlog - ttot) ELSE tunknown END AS tunknown
			, CASE WHEN tother > tnot_av AND tother > tav AND tother > tprob AND tother > tunknown THEN tother + (tlog - ttot) ELSE tother END AS tother
			, nother
		 FROM (
				SELECT xDetail.login, xDetail.[user_id], tlog, tnot_av, tav, tprob, tunknown, tother, nother
					, (tnot_av + tav + tprob + tother + tunknown + tspec +  tcampa) AS ttot
				 FROM (
						SELECT @login_time AS login
							, ccLogAgentesDia.[user_id]
							, @session AS tlog
							, @tspec AS tspec
							, @tcampa AS tcampa
							, ISNULL(SUM(CASE WHEN (tipostatusage_id = 1) THEN tStatus ELSE NULL END), 0) AS tunknown --
							, ISNULL(SUM(CASE WHEN (tipostatusage_id = 2) THEN tStatus ELSE NULL END), 0) AS tnot_av--
							, ISNULL(SUM(CASE WHEN (tipostatusage_id = 3) THEN tStatus ELSE NULL END), 0) AS tav--
							, ISNULL(SUM(CASE WHEN (tipostatusage_id = 11) THEN tStatus ELSE NULL END), 0) AS tprob--
							, ISNULL(SUM(CASE WHEN (tipostatusage_id = 7) THEN tStatus ELSE NULL END), 0) AS tother--
							, COUNT(CASE WHEN (tipostatusage_id = 7) THEN 1 ELSE NULL END) AS nother--
						 FROM ccLogAgentesDia
						 WHERE fecha >= @login_time AND  fecha < @logout_time AND ccLogAgentesDia.[user_id] = @user_id
						  GROUP BY ccLogAgentesDia.[user_id]
				 	) xDetail
			) xAllTimes


	FETCH NEXT FROM Session_Cursor INTO @user_id, @login_time, @logout_time, @session
END
CLOSE Session_Cursor
DEALLOCATE Session_Cursor