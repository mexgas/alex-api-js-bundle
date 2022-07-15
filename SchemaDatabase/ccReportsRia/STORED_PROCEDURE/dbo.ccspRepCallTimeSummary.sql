CREATE PROCEDURE [dbo].[ccspRepCallTimeSummary]
@action AS TINYINT, 
@from AS DATETIME = NULL, 
@to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1

BEGIN
	
	IF OBJECT_ID('tempdb..#chats') IS NOT NULL drop table #chats;
	IF OBJECT_ID('tempdb..#chatsMayores') IS NOT NULL drop table #chatsMayores;
	

CREATE TABLE #chats([user_id] [smallint] NOT NULL
,chatStart datetime not null,chatEnd datetime not null, timeChat smallint not null
,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL,chat_id int not null,total int not null
)

CREATE TABLE #chatsMayores([user_id] [smallint] NOT NULL
,chatStart datetime not null,chatEnd datetime not null,timeChat smallint not null
,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL,chat_id int not null,total int not null
)

--------------------CHATS---------------------------------------
;with timeChats as( --CTE
select userId,isnull(chatDate,requestDate) as chatStart,dateadd(ss,tChatting,isnull(chatDate,requestDate)) as chatEnd,tChatting,chatId
from ccriachats where chatStatus=4 and userId>0 and requestDate between @from and @to
)

insert into #chats
select userId,chatStart,chatEnd,tChatting,
dbo.GetTimeGroup(chatStart,0),dbo.GetTimeGroup(chatEnd,1),chatId,1 as total
from timeChats

INSERT into #chatsMayores SELECT * from #chats where datediff(mi,timegroup,timegroup_next)>15
delete #chats where  datediff(mi,timegroup,timegroup_next)>15


insert into #chats
select [user_id],t.chatStart,t.chatEnd, 
	dbo.TimeInterval(th.start,th.stop,t.chatStart,t.chatEnd) as [tChatting]	 
	,convert(datetime,th.start,121) as timegroup, convert(datetime, th.stop,121) as timegroup_next
	,chat_id
	,case when th.start > t.chatStart and th.stop > t.chatEnd then 1 else 0 end as ntotal
from #chatsMayores t
inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0;

DELETE	FROM RepCallTimeSummary WITH (ROWLOCK)		WHERE DATE >= @from AND DATE < @to

-------------------------------CTE'S--------------------------

;
WITH logAgentDia
AS (
	SELECT userId, timegroup, isnull(sum(CASE WHEN TipoStatusAge_id = 2 THEN tStatus ELSE 0 END), 0) AS timeAux, isnull(sum(CASE WHEN TipoStatusAge_id = 3 THEN tStatus ELSE 0 END), 0) AS timeDisp
	FROM tmpccLogAgentesDia
	WHERE TipoStatusAge_id IN (2, 3)
	GROUP BY timegroup, userId
	), callTimeGroup
AS (
	SELECT user_id, timegroup, sum(tdialog) AS cal_tDialog, sum(ntotal) totalIn, avg(tdialog) avgtimein
	FROM tmpTimesInboundData A
	GROUP BY A.[User_id], A.timegroup
	), callTimeGroupOutbound
AS (
	SELECT user_id, timegroup, sum(tdialog) AS cal_tDialog, sum(ntotal) totalOut, avg(tdialog) avgtimeout
	FROM tmpTimesOutboundData A
	GROUP BY A.[User_id], A.timegroup
	), AbandTime
AS (
	SELECT A.user_id, A.timegroup, count(DISTINCT cal_id) AS totalAband
	FROM tmpTimesInboundData A
	WHERE statusCall_id IN (
			SELECT statusCall_id
			FROM ccstatusllamada
			WHERE inAbandonConfig = 1
			)
	GROUP BY A.[User_id], A.timegroup
	)
	,chatTime as( --CTE
select A.user_id,A.timegroup,sum(timeChat) as timeChat,sum(total) as totalChat,avg(total) avgtTotal,avg(timeChat) avgttimeChat from #chats A
group by A.[User_id],A.timegroup
)

--------------------QUERY---------------------------------------
INSERT INTO RepCallTimeSummary
SELECT A.timegroup AS [date], A.user_id AS userId, u.Nombres + ' ' + u.ApellidoPaterno 'user', u.LOGIN 'Agent', a.tlog 'sesionTime'
	, ISNULL(auxt.timeAux, 0) 'unavailableTime'
	, ISNULL(auxt.timeDisp, 0) 'TiempoDispo'
	, stuff( right(convert(VARCHAR(30), A.LOGIN, 109), 14), 9, 4, ' ') 'sessionStart'
	, stuff(right(convert(VARCHAR(30), A.logout, 109), 14), 9, 4, ' ') 'sessionEnd'
	, isnull(callIn.cal_tDialog, 0) + isnull(callOut.cal_tDialog , 0) 'generalDialog'
	, isnull((isnull(callIn.cal_tDialog, 0) + isnull(callOut.cal_tDialog, 0)) / (nullif(isnull(callIn.totalIn, 0) + isnull(callOut.totalOut, 0), 0)), 0) 'avgCallTime' 
	,isnull(callIn.cal_tDialog, 0) 'inboundDialog'
	, isnull(callIn.avgtimein, 0) AS 'avginboundDialog'
	, isnull(callOut.cal_tDialog, 0) 'outboundDialog'
	, isnull(callOut.avgtimeout, 0) 'avgoutboundDialog'	
	,isnull(chatTime.timeChat,0) as 'chatTime'
	,ISNULL(chatTime.avgttimeChat,0) as 'avgchatTime'
	,isnull(chatTime.totalChat,0) as 'attendedChat'
	, isnull(callOut.totalOut, 0) AS 'callsOut'
	, isnull(callIn.totalIn, 0) AS 'callsIn', isnull(abant.totalAband, 0) AS 'abandonedCalls'
	, isnull(callOut.totalOut, 0) + isnull(callIn.totalIn, 0) 'answerCalls'
	, datepart(yyyy, A.timegroup) AS [year]
	, datepart(mm, A.timegroup) AS [month]
	, datepart(dd, A.timegroup) AS [day]
	, datepart(hh, A.timegroup) AS [hour]
	, datepart(mi, A.timegroup) 
	AS [minutes]
FROM TmpSessionTimeGroup A
LEFT JOIN ccUserView u	ON A.user_id = u.User_id
LEFT JOIN logAgentDia auxt	ON A.user_id = auxt.userId		AND A.timegroup = auxt.timegroup 
LEFT JOIN callTimeGroup callIn	ON A.user_id = callIn.user_id		AND A.timegroup = callIn.timegroup
LEFT JOIN callTimeGroupOutbound callOut	ON A.user_id = callOut.user_id		AND A.timegroup = callOut.timegroup
LEFT JOIN AbandTime abant	ON A.timegroup = abant.timegroup
left join chatTime chatTime on A.user_id=chatTime.user_id and A.timegroup=chatTime.timegroup
ORDER BY [date], userId

IF OBJECT_ID('tempdb..#chats') IS NOT NULL drop table #chats;
IF OBJECT_ID('tempdb..#chatsMayores') IS NOT NULL drop table #chatsMayores;

	
END