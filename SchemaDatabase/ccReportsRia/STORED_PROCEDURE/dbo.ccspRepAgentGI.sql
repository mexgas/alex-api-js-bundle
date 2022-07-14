CREATE PROCEDURE [dbo].[ccspRepAgentGI] @action AS TINYINT
	,@from AS DATETIME
	,@to AS DATETIME
AS
SET ANSI_WARNINGS OFF;
SET NOCOUNT ON;

IF @from IS NULL
	SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

IF @to IS NULL
	SELECT @to = GETDATE();

IF @action = 1
BEGIN
	IF OBJECT_ID('tempdb..#timeDetailAgent') IS NOT NULL
		DROP TABLE #timeDetailAgent;

	CREATE TABLE #timeDetailAgent (
		[User_id] INT NULL
		,dateStartDetail DATETIME NULL
		,dateEndDetail DATETIME NULL
		,timegroup DATETIME NULL
		,timegroup_next DATETIME NULL
		,tunknown INT NULL
		,tnot_av INT NULL
		,tav INT NULL
		,tprob INT NULL
		,tother INT NULL
		,nother INT NULL
		,tmanualcall INT NULL
		,tunknown2 DECIMAL(10, 3)
		,tchatting INT NULL
		,tReconnectKolob INT NULL
		,tPreview INT NULL
		,tAssisted INT NULL
		,tDialogoWhatsApp INT NULL
		);

	INSERT INTO #timeDetailAgent
	SELECT A.userId
		,A.dateIni
		,A.dateEnd
		,A.timegroup
		,A.timeGroupNext
		,CASE WHEN A.tipostatusage_id = 1 THEN A.tStatus ELSE 0 END tunknown
		,CASE WHEN A.tipostatusage_id = 2 THEN A.tStatus ELSE 0 END tnot_av
		,CASE WHEN A.tipostatusage_id IN (3, 31) THEN A.tStatus ELSE 0 END tav
		,--3	Ready y 31	Ready PreviewPro
		CASE WHEN A.tipostatusage_id IN (11, 25, 26, 27) THEN A.tStatus ELSE 0 END tprob
		,--11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
		CASE WHEN A.tipostatusage_id = 7 THEN A.tStatus ELSE 0 END tother
		,CASE WHEN A.tipostatusage_id = 7 THEN 1 ELSE 0 END nother
		,CASE WHEN A.tipostatusage_id = 21 THEN A.tStatus ELSE 0 END tmanualcall
		,CASE WHEN ABS(ISNULL(1.0 * DATEDIFF(ms, A.dateEnd, S.dateIni) / 1000, 0)) > A.tStatus THEN 0 WHEN A.currentStatus IN (0, - 1, - 2) THEN 0 --Logout
			WHEN S.TipoStatusAge_id = 1 THEN 0 ELSE ISNULL(1.0 * DATEDIFF(ms, A.dateEnd, S.dateIni) / 1000, 0) END AS tunknown2
		,CASE WHEN A.tipostatusage_id IN (23, 24) THEN A.tStatus ELSE 0 END AS tchatting
		,CASE WHEN A.tipostatusage_id = 30 THEN A.tStatus ELSE 0 END AS tReconnectKolob
		,CASE WHEN A.tipostatusage_id = 32 THEN A.tStatus ELSE 0 END AS tPreview
		,CASE WHEN A.tipostatusage_id = 33 THEN A.tStatus ELSE 0 END AS tAssisted
		,CASE WHEN A.tipostatusage_id = 34 THEN A.tStatus ELSE 0 END AS tDialogoWhatsApp
	FROM tmpccLogAgentesDia A
	LEFT JOIN tmpccLogAgentesDia S ON A.Id = S.Id - 1
		AND A.userId = S.userId

	UPDATE #timeDetailAgent
	SET tunknown2 = 0
	WHERE ABS(tunknown2) > 2.7;

	DELETE	FROM RepAgentGI	WHERE DATE >= @from		AND DATE < @to

	;WITH inboundCount
	AS (
		SELECT timegroup
			,user_id AS userId
			,nxfer AS nxferin
			,nanswer AS nanswerin
			,nabnd_xfer AS nabndxferin
			,nabnd_ring AS nabndringin
			,nabnd_dialog AS nabnddlgin
			,(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferin
			,nno_answer AS nnoanswerin
			,nlost AS nlostin
			,nMoh AS nMohIn
			,nWHag AS nWHagIn
			,nWHcl AS nWHclIn
			,tdialog AS tdialogIn
			,tnotes AS tnotesIn
			,tring AS tringIn
			,txfer AS txferIn
			,cal_id AS callIdIn
			,phone_in AS phoneIn
			,dateStartDetail AS dateStartDetailIn
		FROM tmpTimesInboundData
		WHERE user_id > 0
		)
		,outboundCount
	AS (
		SELECT timegroup
			,user_id AS userId
			,nxfer AS nxferOut
			,nanswer AS nanswerOut
			,nabnd_xfer AS nabndxferOut
			,nabnd_ring AS nabndringOut
			,nabnd_dialog AS nabnddlgOut
			,(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferOut
			,nno_answer AS nnoanswerOut
			,nlost AS nlostOut
			,nMoh AS nMohOut
			,nWHag AS nWHagOut
			,nWHcl AS nWHclOut
			,tdialog AS tdialogOut
			,tnotes AS tnotesOut
			,tring AS tringOut
			,txfer AS txferOut
			,cal_id AS callIdOut
			,phone_out AS phoneOut
			,dateStartDetail AS dateStartDetailOut
		FROM tmpTimesOutboundData
		WHERE user_id > 0
			AND cal_manual IN (0, 2, 3)
		)
		,agentTime
	AS (
		SELECT user_Id
			,timegroup
			,sum(nother) nOther
			,sum(tunknown) tunknown
			,sum(tnot_av) tnotAv
			,sum(tav) tav
			,sum(tother) AS tother
			,sum(tprob) AS tprob
			,sum(tchatting) AS tchatting
		FROM #timeDetailAgent
		GROUP BY user_Id
			,timegroup
		), outboundCountGroup as(
		select timegroup ,userId
		,sum(tdialogOut) tdialogOut
		,sum(tnotesOut) tnotesOut
		,sum(tringOut) tringOut
		,sum(txferOut) txferOut
		from outboundCount
		group by timegroup ,userId
		), inboundCountGroup as(
		select timegroup ,userId
		,sum(tdialogIn) tdialogIn
		,sum(tnotesIn) tnotesIn
		,sum(tringIn) tringIn
		,sum(txferIn) txferIn
		from inboundCount
		group by timegroup ,userId
		)

	
	
	INSERT INTO RepAgentGI
	SELECT A.timegroup AS [date]
		,A.user_id AS userId
		,u.Nombres + ' ' + u.ApellidoPaterno + ' ' + u.ApellidoMaterno AS [user]
		,u.LOGIN
		,
		---------------- Count IN Call -----------------------
		ISNULL(inCount.nxferin, 0) nXferIn
		,ISNULL(inCount.nanswerin, 0) nAnswerIn
		,ISNULL(inCount.nabndxferin, 0) nAbndXferIn
		,ISNULL(inCount.nabndringin, 0) nAbndRingIn
		,ISNULL(inCOunt.nabnddlgin, 0) AS nAbnddlgIn
		,ISNULL(inCount.abndaxferin, 0) abndaXferIn
		,ISNULL(inCount.nnoanswerin, 0) AS nnoAnswerIn
		,ISNULL(inCount.nlostIn, 0) AS nlostIn
		,isnull(inCount.tdialogIn, 0) AS tdialogIn
		,isnull(inCount.tnotesIn, 0) tnotesIn
		,isnull(inCount.tringIn, 0) tringIn
		,isnull(inCount.txferIn, 0) txferIn
		,
		---------------- Count Out Call -----------------------      
		0 AS nXferOut
		,0 AS nAnswerOut
		,0 AS nAbndXferOut
		,0 AS nabndringOut
		,0 AS nAbnddlgOut
		,0 AS abndaXferOut
		,0 AS nnoAnswerOut
		,0 AS nlostOut
		,0 AS tdialogOut
		,0 tnotesOut
		,0 tringOut
		,0 txferOut
		
		---------------- Time Agent Common -----------------------      
		,0 nOther
		,0 tunknown
		,0 tnotAv
		,0 as tlog
		,0 tav
		,0 tOther
		,0 tprob
		,
		---------------- Count In/Out Call-----------------------      
		isnull(inCount.nMohIn, 0) AS nMohIn
		,0 AS nMohOut
		,isnull(inCount.nWHagIn, 0) AS nWHagIn
		,0 AS nWHagOut
		,isnull(inCount.nWHclIn, 0) AS nWHclIn
		,0 AS nWHclOut
		,datepart(yyyy, A.timegroup) AS [year]
		,datepart(mm, A.timegroup) AS [mount]
		,datepart(dd, A.timegroup) AS [day]
		,datepart(HH, A.timegroup) AS [hour]
		,datepart(mi, A.timegroup) AS [minutes]
		,
		---------------- Detail In Call-----------------------      
		isnull(inCount.phoneIn, '') AS phoneIn
		,isnull(inCount.dateStartDetailIn, '') AS dateStartDetailIn
		,isnull(inCount.callIdIn, 0) AS callIdIn
		,
		---------------- Detail out Call-----------------------      
		'' AS phoneOut
		,'1900-01-01' AS dateStartDetailOut
		,0 AS callIdOut
		---------------- Time Agent Common -----------------------      
		,0 tnotAvg
		,0 AS tundefined
		,0 tchatting
	FROM TmpSessionTimeGroup A
	LEFT JOIN ccUserView u ON A.[user_id] = u.[user_id]
	LEFT JOIN inboundCount inCount ON A.timegroup = inCount.timegroup AND A.User_Id = inCount.userId
	
	UNION ALL
	
	SELECT A.timegroup AS [date]
		,A.user_id AS userId
		,u.Nombres + ' ' + u.ApellidoPaterno + ' ' + u.ApellidoMaterno AS [user]
		,u.LOGIN
		,
		---------------- Count IN Call -----------------------
		0 nXferIn
		,0 nAnswerIn
		,0 nAbndXferIn
		,0 nAbndRingIn
		,0 AS nAbnddlgIn
		,0 abndaXferIn
		,0 AS nnoAnswerIn
		,0 AS nlostIn
		,0 tdialogIn
		,0 tnotesIn
		,0 tringIn
		,0 txferIn
		,
		---------------- Count Out Call -----------------------      
		isnull(outTime.nXferOut, 0) nXferOut
		,isnull(outTime.nAnswerOut, 0) nAnswerOut
		,isnull(outTime.nAbndXferOut, 0) nAbndXferOut
		,isnull(outTime.nAbndRingOut, 0) nAbndRingOut
		,isnull(outTime.nAbnddlgOut, 0) AS nAbnddlgOut
		,isnull(outTime.abndaXferOut, 0) abndaXferOut
		,isnull(outTime.nnoAnswerOut, 0) AS nnoAnswerOut
		,isnull(outTime.nlostOut, 0) AS nlostOut
		,ISNULL(outTime.tdialogOut, 0) tdialogOut
		,ISNULL(outTime.tnotesOut, 0) tnotesOut
		,ISNULL(outTime.tringOut, 0) tringOut
		,ISNULL(outTime.txferOut, 0) txferOut
		,
		---------------- Time Agent Common -----------------------      
		0 AS nOther
		,0 AS tunknown
		,0 AS tnotAv
		,0 AS tlog
		,0 AS tav
		,0 AS tOther
		,0 AS tprob
		,
		---------------- Count In/Out Call-----------------------      
		0 AS nMohIn
		,isnull(outTime.nMohOut, 0) AS nMohOut
		,0 AS nWHagIn
		,isnull(outTime.nWHagOut, 0) AS nWHagOut
		,0 AS nWHclIn
		,isnull(outTime.nWHclOut, 0) AS nWHclOut
		,datepart(yyyy, A.timegroup) AS [year]
		,datepart(mm, A.timegroup) AS [mount]
		,datepart(dd, A.timegroup) AS [day]
		,datepart(HH, A.timegroup) AS [hour]
		,datepart(mi, A.timegroup) AS [minutes]
		,
		---------------- Detail In Call-----------------------      
		'' AS phoneIn
		,'1900-01-01' AS dateStartDetailIn
		,0 AS callIdIn
		,
		---------------- Detail out Call-----------------------      
		isnull(outTime.phoneOut, '') AS phoneOut
		,isnull(outTime.dateStartDetailOut, '1900-01-01') AS dateStartDetailOut
		,isnull(outTime.callIdOut, 0) AS callIdOut
		---------------- Time Agent Common -----------------------      
		,0 tnotAvg
		,0 AS tundefined
		,0 tchatting
	FROM TmpSessionTimeGroup A
	LEFT JOIN ccUserView u ON A.[user_id] = u.[user_id]
	LEFT JOIN outboundCount outTime ON outTime.timegroup = A.timegroup AND outTime.userId = A.User_id


	---------------------SOLO TIEMPOS  ---------------------
	union All
	SELECT A.timegroup AS [date]
		,A.user_id AS userId
		,u.Nombres + ' ' + u.ApellidoPaterno + ' ' + u.ApellidoMaterno AS [user]
		,u.LOGIN
		,
		---------------- Count IN Call -----------------------
		0 nXferIn
		,0 nAnswerIn
		,0 nAbndXferIn
		,0 nAbndRingIn
		,0 AS nAbnddlgIn
		,0 abndaXferIn
		,0 AS nnoAnswerIn
		,0 AS nlostIn
		,0 AS tdialogIn
		,0 tnotesIn
		,0 tringIn
		,0 txferIn
		,
		---------------- Count Out Call -----------------------      
		0 AS nXferOut
		,0 AS nAnswerOut
		,0 AS nAbndXferOut
		,0 AS nabndringOut
		,0 AS nAbnddlgOut
		,0 AS abndaXferOut
		,0 AS nnoAnswerOut
		,0 AS nlostOut
		,0 AS tdialogOut
		,0 tnotesOut
		,0 tringOut
		,0 txferOut
		,
		---------------- Time Agent Common -----------------------      
		isnull(agentTime.nOther, 0) nOther
		,isnull(agentTime.tunknown, 0) tunknown
		,isnull(agentTime.tnotAv, 0) tnotAv
		,A.tlog as tlog
		,isnull(agentTime.tav, 0) tav
		,isnull(agentTime.tOther, 0) tOther
		,isnull(agentTime.tprob, 0) tprob
		,
		---------------- Count In/Out Call-----------------------      
		0 AS nMohIn
		,0 AS nMohOut
		,0 AS nWHagIn
		,0 AS nWHagOut
		,0 AS nWHclIn
		,0 AS nWHclOut
		,datepart(yyyy, A.timegroup) AS [year]
		,datepart(mm, A.timegroup) AS [mount]
		,datepart(dd, A.timegroup) AS [day]
		,datepart(HH, A.timegroup) AS [hour]
		,datepart(mi, A.timegroup) AS [minutes]
		,
		---------------- Detail In Call-----------------------      
		'' AS phoneIn
		,'1900-01-01' AS dateStartDetailIn
		,0 AS callIdIn
		,
		---------------- Detail out Call-----------------------      
		'' AS phoneOut
		,'1900-01-01' AS dateStartDetailOut
		,0 AS callIdOut
		---------------- Time Agent Common -----------------------      
		,isnull(agentTime.tnotAv, 0) tnotAvg
		,A.tlog - isnull(inCount.tdialogin, 0) - isnull(inCount.tnotesin, 0) - isnull(inCount.tringin, 0) - isnull(inCount.txferin, 0) 
		- isnull(outTime.tdialogOut, 0) - isnull(outTime.tnotesOut, 0) - isnull(outTime.tringOut, 0) - isnull(outTime.txferOut, 0) 
		- isnull(agentTime.tunknown, 0) - isnull(agentTime.tnotAv, 0) - isnull(agentTime.tav, 0) - isnull(agentTime.tOther, 0) 
		- isnull(agentTime.tprob, 0) - isnull(agentTime.tchatting, 0) 
		
		AS tundefined
		,isnull(agentTime.tchatting, 0) tchatting
	FROM TmpSessionTimeGroup A
	LEFT JOIN ccUserView u ON A.[user_id] = u.[user_id]
	LEFT JOIN inboundCountGroup inCount ON A.timegroup = inCount.timegroup AND A.User_Id = inCount.userId
	LEFT JOIN agentTime ON agentTime.User_id = A.user_id AND agentTime.timegroup = A.timegroup
	LEFT JOIN outboundCountGroup outTime ON outTime.timegroup = A.timegroup AND outTime.userId = A.User_id

	--ORDER BY userId		,[date]

	IF OBJECT_ID('tempdb..#timeDetailAgent') IS NOT NULL
		DROP TABLE #timeDetailAgent;
END;