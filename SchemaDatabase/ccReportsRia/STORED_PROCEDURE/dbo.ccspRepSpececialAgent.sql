CREATE PROCEDURE [dbo].[ccspRepSpececialAgent] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
IF @action = 1
BEGIN
	IF @from IS NULL
		SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

	IF @to IS NULL
		SELECT @to = getdate()

	DELETE RepSpececialAgent	WHERE [date] BETWEEN @from			AND @to

	;WITH outCall
	AS (
		SELECT convert([date], timegroup, 121) [date]
			,User_id AS userId
			,COUNT(CASE WHEN statuscall_id >= 10
						AND ntotal > 0 THEN 1 ELSE NULL END) AS ncalls
			,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) nabnd
			,sum(nanswer) AS nanswer
			,COUNT(CASE WHEN statuscall_id = 13
						AND ntotal > 0
						AND (
							calif_id IS NULL
							OR calif_id = 0
							) THEN 1 ELSE NULL END) AS nocalif
		FROM tmpTimesOutboundData
		GROUP BY convert([date], timegroup, 121)
			,User_id
		)
		,inCall
	AS (
		SELECT convert([date], timegroup, 121) [date]
			,User_id AS userId
			,COUNT(CASE WHEN statuscall_id >= 10
						AND ntotal > 0 THEN 1 ELSE NULL END) AS ncalls
			,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) nabnd
			,sum(nanswer) AS nanswer
			,COUNT(CASE WHEN statuscall_id = 13
						AND ntotal > 0
						AND (
							calif_id IS NULL
							OR calif_id = 0
							) THEN 1 ELSE NULL END) AS nocalif
		FROM tmpTimesInboundData
		GROUP BY convert([date], timegroup, 121)
			,User_id
		)
		,AgentGI
	AS (
		SELECT convert([date], [date], 121) [date]
			,userId
			,[user]
			,[login]
			,sum(tlog) [session]
			,sum(tnotav) ndTime
			,sum(tdialogin + tnotesin + tdialogout + tnotesout) dialogTime
		FROM RepAgentGI WITH (NOLOCK)
		WHERE [date] BETWEEN @from
				AND @to
		GROUP BY convert([date], [date], 121)
			,userId
			,[user]
			,[login]
		)
		,ses
	AS (
		SELECT convert([date], [date], 121) [date]
			,userId
			,min(logintime) loginTime
			,max(logouttime) logoutTime
		FROM RepAgentsession WITH (NOLOCK)
		WHERE [date] BETWEEN @from
				AND @to
		GROUP BY convert([date], [date], 121)
			,userId
		)
	INSERT RepSpececialAgent
	SELECT A.[date]
		,A.userId
		,A.[user]
		,A.[login]
		,A.[session]
		,ses.loginTime
		,ses.logoutTime
		,A.dialogTime
		,A.ndTime
		,ISNULL(cout.ncalls, 0) callsOut
		,ISNULL(cin.ncalls, 0) callsIn
		,isnull(cout.nabnd, 0) + isnull(cin.nabnd, 0) AS abandonedCalls
		,ISNULL(cout.nanswer, 0) + ISNULL(cin.nanswer, 0) nanswer2
		,ISNULL(cout.nocalif, 0) + ISNULL(cin.nocalif, 0) unrated
	FROM AgentGI A
	INNER JOIN ses ON ses.[date] = A.[date]
		AND ses.userId = A.userId
	LEFT JOIN outCall cout ON cout.[date] = A.[date]
		AND cout.userId = A.userId
	LEFT JOIN inCall cin ON cin.[date] = A.[date]
		AND cin.userId = A.userId
END