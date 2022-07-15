CREATE PROCEDURE [dbo].[ccspRepMKTIntervalosTiemposAcuTotales] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

DECLARE @dateNow DATETIME
	,@maxLogout DATETIME

IF @action = 1
BEGIN
	

	IF OBJECT_ID('tempdb..#RepMKTIntervalosTiemposAcuTotalesTemp') IS NOT NULL
		DROP TABLE #RepMKTIntervalosTiemposAcuTotalesTemp

	IF OBJECT_ID('tempdb..#timeDetailAgentFinal') IS NOT NULL
		DROP TABLE #timeDetailAgentFinal	

	IF OBJECT_ID('tempdb..#sessionTimeGroup') IS NOT NULL
		DROP TABLE #sessionTimeGroup

	CREATE TABLE #sessionTimeGroup (
		[user_id] [smallint] NOT NULL
		,[timegroup] [datetime] NOT NULL
		,[tlog] [INT] NULL
		,[inb_id] [int] NOT NULL
		);

	;WITH relationWg
	AS (
		SELECT DISTINCT wgu.User_id
			,wg.IdCampEsp
		FROM ccriaworkgroupusers wgu
		INNER JOIN ccRIACampEspWG wg
			ON wg.IDWG = WGU.IDWG
		WHERE wg.Tipo = 0
		)


	INSERT INTO #sessionTimeGroup
	SELECT st.[user_id]
		,timegroup
		,tlog
		,wgu.IdCampEsp
	FROM TmpSessionTimeGroup st
	INNER JOIN relationWg wgu
		ON st.User_id = wgu.User_id

			---------------------oRows---------------------
			;

	WITH timeDetailAgent
	AS (
		SELECT userId
			,timeGroup
			,CASE WHEN A.tipostatusage_id = 1 THEN A.tStatus ELSE 0 END tunknown
			,CASE WHEN A.tipostatusage_id = 2 THEN A.tStatus ELSE 0 END tnot_av
			,CASE WHEN A.tipostatusage_id = 3 THEN A.tStatus ELSE 0 END tav
			,CASE WHEN A.tipostatusage_id IN (11, 25, 26, 27) THEN A.tStatus ELSE 0 END tprob
			,--11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
			CASE WHEN A.tipostatusage_id = 7 THEN A.tStatus ELSE 0 END tother
			,CASE WHEN A.TipoStatusAge_id = 8 THEN A.tStatus ELSE 0 END tcliente
			,CASE WHEN A.TipoStatusAge_id = 0 THEN A.tStatus ELSE 0 END tlogout
			,CASE WHEN A.tipostatusage_id = 21 THEN A.tStatus ELSE 0 END tmanualCall
		FROM tmpccLogAgentesDia A
		)

	SELECT B.inb_id as IdCampEsp
		,A.timeGroup
		,sum(tunknown) tunknown
		,sum(tnot_av) tnot_av
		,sum(tav) tav
		,sum(tother) tother
		,sum(tprob) tprob
		,sum(tmanualCall) tmanualCall
		,sum(tlogout) tlogout
		,sum(tcliente) tcliente
	INTO #timeDetailAgentFinal
	FROM timeDetailAgent A
	INNER JOIN #sessionTimeGroup B
		ON A.timeGroup = B.timegroup
			AND A.userId = B.user_id
	GROUP BY B.inb_id
		,A.timeGroup

	----------------------------------------------------------
	
	;with 
	 relationCallIdCamId as(
		select distinct cal_id as callId,Inbound_id InboundId,User_id as userId from tmpTimesInboundData
	),
	transferData as(
		select B.userId,B.InboundId
		,CASE WHEN t.modo = 2 then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as fent
		,CASE WHEN t.modo = 2 and t.tipo=1 then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as fsal
		,CASE WHEN t.modo in (0,3,4) then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as SalExt
		,CASE WHEN t.modo in (0,3,4) then [dbo].TimeInterval( timegroup,timegroup_next,dateIni,dateEnd) else 0 end as tprosalext	
		,dateIni as dateStart	
		,dateEnd
		,timegroup
		,timegroup_next
		from TmpTimesccLogtransfers T
		inner join relationCallIdCamId B on t.callId=B.callId	
		where tipo=1
	), transferDataGroup as(

	select userId, timegroup, InboundId 
	,sum(fent) fent,sum(fsal) fsal, sum(salExt) salExt,sum(tprosalext) as tprosalext
	,min(dateStart) as [dateTTransferStart]
	,max(dateEnd) as [dateTTransferEnd]
	from transferData
	group by timegroup, InboundId,userId
	), inboundGroup as(

	select 
	i.timegroup
	,i.inbound_Id as inboundId	
	,i.User_id as userId
	,sum(case when statusCall_id =13 and ntotal>0 then 1 else 0 end) as nacd
	,sum(case when statusCall_id <>13 and ntotal>0 then 1 else 0 end) as nabnd	
	,sum(case when statusCall_id=13 then tdialog else 0 end) as tacd
	,sum(case when statusCall_id=13 then tnotes else 0 end) as tacw
	,sum(case when statusCall_id=13 and ntotal>0 and tnotes>0 then 1 else 0 end) as nacw 
	,sum(ntotal) nCalls
	,sum(case when statusCall_id=13 then txfer else 0 end) as txfer
	,isnull(sum(t.SalExt),0) as SalExt
	,isnull(sum(t.tprosalext),0) as tprosalext	
	,sum(nMoh) as nhold 
	,sum(case when statusCall_id=13 and ntotal>0 and tque+txfer+tring<40 then 1 else 0 end) as nserv 
	,sum(tring) AS tring
	,sum(case when statusCall_id=13 and ntotal>0 and tring>0 then 1 else 0 end) nring
	,sum(cal_tmoh) AS thold	
	,count(DISTINCT i.User_id) as countUserDistinct
	,count(distinct case when statusCall_id =13 and ntotal>0 then  userId end ) countUserDistinctNacd
	from tmpTimesInboundData i
	left join transferDataGroup t on i.timegroup=t.timegroup and i.Inbound_id=t.InboundId and i.User_id=t.userId	
	group by i.timegroup,i.inbound_Id,i.User_id
	), groupLog as(
	select userId as User_id ,camId as IdCampEsp,TipoStatusAge_id
	,sum(tStatus) as tStatus
	,sum(1) nstatusfra
	,timegroup	
	from tmpccLogAgentesDia
	where TipoStatusAge_id=3
	group by userId,camId,TipoStatusAge_id,timegroup
	)
	-----------------------------------------------------------------------------------
	
	SELECT DISTINCT CASE WHEN c.timegroup IS NOT NULL THEN c.timegroup ELSE G.timegroup END AS [date]
		,isnull(c.inboundId, inb_id) AS inboundId
		,isnull(ci.descripcion, '') AS [descripcion]
		,isnull(c.ncalls, 0) AS ncalls --LlamadasRecibidas
		,isnull(c.nacd, 0) AS nacd --atendidas
		,isnull(c.nabnd, 0) AS nabnd --abandonadas
		,isnull(c.tacd, 0) AS tacd --TiempoACD
		,isnull(c.tacw, 0) AS tacw --TiempoACW
		,isnull(d.tlogout, 0) AS tlogout --TiempoLogout
		,isnull(c.nacw, 0) AS nacw --nACW
		,isnull(d.tunknown, 0) AS tunknown --TiempoDescon
		,isnull(d.tnot_av, 0) AS tnot_av --TiempoNoDispo
		,isnull(c.txfer, 0) AS txfer --TiempoXfer
		,isnull(d.tother, 0) AS tother --TiempoOtra
		,isnull(d.tcliente, 0) AS tcliente --TiempoCliente
		,isnull(d.tprob, 0) AS tprob --TiempoProblema
		,isnull(d.tmanualCall, 0) AS tmanualCall --TiempoManual
		,G.user_id userId
		,isnull(G.[tlog], 0) AS tlog
		,isnull(hi.tiempohold, 0) AS tiempoHold
		,isnull(c.SalExt, 0) AS SalExt
		,isnull(c.tprosalext, 0) tprosalext
		,isnull(c.nhold, 0) nhold
		,isnull(thold, 0) thold
		,isnull(c.nserv, 0) nserv
		,isnull(c.nring, 0) nring
		,isnull(c.tring, 0) tring
	INTO #RepMKTIntervalosTiemposAcuTotalesTemp
	FROM inboundGroup c
	FULL JOIN #sessionTimeGroup G ON G.timegroup = c.[timegroup] AND c.inboundId = G.inb_id AND G.user_id = c.userId
	LEFT JOIN tmpTimesHoldIn hi ON hi.inbound_id = C.inboundId AND hi.timegroup = C.timegroup
	LEFT JOIN ccinbound ci(NOLOCK) ON ci.Inbound_id = c.inboundId
	LEFT JOIN #timeDetailAgentFinal d(NOLOCK) ON d.IdCampEsp = ci.Inbound_id AND d.timegroup = C.timegroup
	LEFT JOIN groupLog lo ON c.timegroup = lo.timegroup AND c.inboundId = lo.IdCampEsp AND c.userId = lo.user_id

	DELETE
	FROM [RepMKTIntervalosTiemposAcuTotales]
	WHERE DATE >= @from
		AND DATE <= @to

	INSERT INTO [RepMKTIntervalosTiemposAcuTotales]
	SELECT [date] AS [date]
		,inboundId
		,inb.descripcion AS descripcion
		,round(CASE WHEN count(DISTINCT userId) > 1 THEN ((convert(FLOAT, (sum([tlog]) * 100)) / convert(FLOAT, count(DISTINCT userId) * 1800)) * count(DISTINCT userId)
							) / 100 ELSE 0 END, 1) AS [PromPosicionPersonal]
		,sum(ncalls) LlamadasRecibidas
		,sum(nacd) LlamadasAtendidas
		,sum(nabnd) LlamadasAban
		,sum(tacd) AS TiempoACD --tACD
		,sum(tacw) AS TiempoACW --tACW
		,sum(c.tlogout) AS TiempoLogout --tLogout
		,sum(c.tunknown) AS TiempoDescon --tDescon
		,sum(DISTINCT c.tnot_av) AS TiempoNoDispo --tnotav
		,sum(DISTINCT d.tav) AS TiempoDispo
		,sum(txfer) AS TiempoXfer --txfer
		,sum(c.tother) AS TiempoOtra --tother
		,sum(c.tcliente) AS TiempoCliente --tCliente
		,sum(tring) AS TiempoRing --tring
		,sum(c.tprob) AS TiempoProblema --tprob
		,sum(c.tmanualCall) AS TiempoManual --tManual
		,sum(tiempoHold) AS TiempoReten --[timeretention]
		,sum(SalExt) AS LlamadasSalidaExt
		,CASE WHEN sum(SalExt) > 0 THEN sum(tprosalext) ELSE 0 END AS [TiempoSalidaExt]
		,CASE WHEN sum(ncalls) > 0 THEN (sum(nserv) * 100) / sum(ncalls) ELSE 0 END [PorcNiveldeServicio4080]
		,(
			(CASE WHEN sum(nacd) > 0 THEN sum(tacd) / sum(nacd) ELSE 0 END) + (CASE WHEN sum(nacw) > 0 THEN sum(tacw) / sum(nacw) ELSE 0 END) + (CASE WHEN sum(nring) > 0 THEN sum(tring) / sum(nring) ELSE 0 END
				) + (CASE WHEN sum(nhold) > 0 THEN sum(thold) / sum(nhold) ELSE 0 END)
			) [AHT]
		,sum(nhold) AS LlamadasRetenidas
		,sum(nring) AS LlamadasenRing
		,DATEPART(YYYY, [date]) AS [year]
		,DATEPART(mm, [date]) AS [month]
		,DATEPART(dd, [date]) AS [day]
		,DATEPART(hh, [date]) AS [hour]
		,DATEPART(mi, [date]) AS [minutes]
		,sum(nserv) AS nserv
		,sum(nacw) AS nacw
	FROM #RepMKTIntervalosTiemposAcuTotalesTemp c
	LEFT JOIN ccinbound inb
		ON inb.Inbound_id = inboundId
	LEFT JOIN #timeDetailAgentFinal d(NOLOCK)
		ON d.IdCampEsp = c.inboundId
			AND d.timegroup = c.DATE
	GROUP BY [date]
		,inboundId
		,inb.descripcion
	HAVING sum(nacd) > 0
		OR sum(nabnd) > 0
		OR sum(tlog) > 0

	IF OBJECT_ID('tempdb..#sessionTimeGroup') IS NOT NULL
		DROP TABLE #sessionTimeGroup;	

	IF OBJECT_ID('tempdb..#RepMKTIntervalosTiemposAcuTotalesTemp') IS NOT NULL
		DROP TABLE #RepMKTIntervalosTiemposAcuTotalesTemp
			
	IF OBJECT_ID('tempdb..#timeDetailAgentFinal') IS NOT NULL
		DROP TABLE #timeDetailAgentFinal		
END