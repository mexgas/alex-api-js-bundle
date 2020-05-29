/*
Autor: Raymundo Gonzalez
Fecha: 2013/11/06
Descripcion:
	Se agrego el ccsettings_id numero 29 para AVRS Integracion 
	Se crean los indices en las tablas de reportes en el campo date para mejora de performance
	Se modifica el SP ccspRepACDChats para mejora de performance
	Se modifica el SP ccspRepAgentGI para mejora de performance
	Se modifica el SP ccspRepAgentKPI para mejora de performance
	Se modifica el SP ccspRepAgentNotReady para mejora de performance
	Se modifica el SP ccspRepAgentNotReadyDet para mejora de performance
	Se modifica el SP ccspRepAvgAnswerTimeChats para mejora de performance
	Se modifica el SP ccspRepAVRSAgent para mejora de performance
	Se modifica el SP ccspRepAVRSDisposition para mejora de performance
	Se modifica el SP ccspRepAVRSQuestionDetail para mejora de performance
	Se modifica el SP ccspRepAVRSRateDetail para mejora de performance
	Se modifica el SP ccspRepAVRSScores para mejora de performance
	Se modifica el SP ccspRepAVRSSection para mejora de performance
	Se modifica el SP ccspRepAVRSSupervisor para mejora de performance
	Se modifica el SP ccspRepChatsAndCallsGeneral para mejora de performance
	Se modifica el SP ccspRepChatsDetail para mejora de performance
	Se modifica el SP ccspRepChatsEffectiveness para mejora de performance
	Se modifica el SP ccspRepChatsNotContacted para mejora de performance
	Se modifica el SP ccspRepInBill01900 para mejora de performance
	Se modifica el SP ccspRepInCalls para mejora de performance
	Se modifica el SP ccspRepInCallsDetail para mejora de performance
	Se modifica el SP ccspRepInChangeFlow para mejora de performance
	Se modifica el SP ccspRepInDIDResume para mejora de performance
	Se modifica el SP ccspRepInDispositions para mejora de performance
	Se modifica el SP ccspRepInEffectiveness para mejora de performance
	Se modifica el SP ccspRepInNotTransferred para mejora de performance
	Se modifica el SP ccspRepInRejectedCalls para mejora de performance
	Se modifica el SP ccspRepInSubDispositions para mejora de performance
	Se modifica el SP ccspRepIVRByOptions para mejora de performance
	Se modifica el SP ccspRepIVRDetail para mejora de performance
	Se modifica el SP ccspRepIVRFirstOption para mejora de performance
	Se modifica el SP ccspRepIVRGeneral para mejora de performance
	Se modifica el SP ccspRepOutCallBacks para mejora de performance
	Se modifica el SP ccspRepOutCallBilling para mejora de performance
	Se modifica el SP ccspRepOutCalls para mejora de performance
	Se modifica el SP ccspRepOutCallsByTelephone para mejora de performance
	Se modifica el SP ccspRepOutCallsDetail para mejora de performance
	Se modifica el SP ccspRepOutDialDetail para mejora de performance
	Se modifica el SP ccspRepOutDials para mejora de performance
	Se modifica el SP ccspRepOutDispositions para mejora de performance
	Se modifica el SP ccspRepOutKPI para mejora de performance
	Se modifica el SP ccspRepOutSubDispositions para mejora de performance
	Se modifica el SP ccspRepSpecialTimes para mejora de performance
	Se modifica el SP ccspRepTrunkBusy para mejora de performance
	Se modifica el SP ReportsMasterProcess para Integracion con avrs
Version requerida: 7
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '8'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'ccSettings - Insert AVRS Integration 29'
	set @Sql='INSERT INTO ccSettings (setting_id ,valor ,descripcion ,Status ,Tipo )  VALUES (29 ,''0'' ,''AVRS Integration'' ,1 ,''X'')'
	
	EXEC(@Sql)

		set @process = 'Reports - Create Index'
		set @Sql = 'CREATE NONCLUSTERED INDEX [IX_RepACDChats] ON [dbo].[RepACDChats] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAgentGI] ON [dbo].[RepAgentGI] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAgentKPI] ON [dbo].[RepAgentKPI] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAgentNotReady] ON [dbo].[RepAgentNotReady] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAgentNotReadyDet] ON [dbo].[RepAgentNotReadyDet] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAgentSession] ON [dbo].[RepAgentSession] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAvgAnswerTimeChats] ON [dbo].[RepAvgAnswerTimeChats] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAVRSAgent] ON [dbo].[RepAVRSAgent] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAVRSDisposition] ON [dbo].[RepAVRSDisposition] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAVRSQuestionDetail] ON [dbo].[RepAVRSQuestionDetail] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAVRSRateDetail] ON [dbo].[RepAVRSRateDetail] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAVRSScores] ON [dbo].[RepAVRSScores] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAVRSSection] ON [dbo].[RepAVRSSection] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepAVRSSupervisor] ON [dbo].[RepAVRSSupervisor] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepChatsAndCallsGeneral] ON [dbo].[RepChatsAndCallsGeneral] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepChatsDetail] ON [dbo].[RepChatsDetail] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepChatsEffectiveness] ON [dbo].[RepChatsEffectiveness] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepChatsNotContacted] ON [dbo].[RepChatsNotContacted] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInBill01900] ON [dbo].[RepInBill01900] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInCalls] ON [dbo].[RepInCalls] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInCallsDetail] ON [dbo].[RepInCallsDetail] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInChangeFlow] ON [dbo].[RepInChangeFlow] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInDIDResume] ON [dbo].[RepInDIDResume] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInDispositions] ON [dbo].[RepInDispositions] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInEffectiveness] ON [dbo].[RepInEffectiveness] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInNotTransferred] ON [dbo].[RepInNotTransferred] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInRejectedCalls] ON [dbo].[RepInRejectedCalls] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInSubDispositions] ON [dbo].[RepInSubDispositions] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepInTrunkBusy] ON [dbo].[RepInTrunkBusy] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepIVRByOptions] ON [dbo].[RepIVRByOptions] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepIVRDetail] ON [dbo].[RepIVRDetail] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepIVRFirstOption] ON [dbo].[RepIVRFirstOption] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepIVRGeneral] ON [dbo].[RepIVRGeneral] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepOutCallBacks] ON [dbo].[RepOutCallBacks] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepOutCallBilling] ON [dbo].[RepOutCallBilling] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepOutCalls] ON [dbo].[RepOutCalls] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepOutCallsByTelephone] ON [dbo].[RepOutCallsByTelephone] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepOutCallsDetail] ON [dbo].[RepOutCallsDetail] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepOutDialDetail] ON [dbo].[RepOutDialDetail] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepOutDials] ON [dbo].[RepOutDials] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepOutDispositions] ON [dbo].[RepOutDispositions] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepOutKPI] ON [dbo].[RepOutKPI] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepOutSubDispositions] ON [dbo].[RepOutSubDispositions] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepOutTrunkBusy] ON [dbo].[RepOutTrunkBusy] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepSpecialTimes] ON [dbo].[RepSpecialTimes] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepTrunkBusy] ON [dbo].[RepTrunkBusy] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepACDChats - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepACDChats]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
	
		delete from RepACDChats with(rowlock)
		where date >= @from AND date < @to
		
		insert into RepACDChats
			select fecha,
			inboundId, b.descripcion, ChatDetail.domain, b.IDArea, c.AreaName,
			max([totalChats]),
			sum([waitingAbandoned]),
			sum([waitingConnected]),
			max(maxTQueue),
			max(avgTQueue),
			sum([onQueue]),
			sum([Connected]),
			sum([UnavailableAgents] + [OutOfService] + [OutOfSchedule] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]),
			0.00 as levelService,
			sum([byCostumer]) as finishedByCostumer,
			sum([byAgent]) as finishedByAgent,
			sum([bySystem]) as finishedBySystem,
			sum([byAdmin]) as finishedByAdmin,
			datepart(yyyy,CONVERT(varchar(20), fecha, 120)) as [year],
			datepart(mm,CONVERT(varchar(20), fecha, 120)) as [month],
			datepart(dd,CONVERT(varchar(20), fecha, 120)) as [day],
			datepart(hh,CONVERT(varchar(20), fecha, 120)) as [hour],
			datepart(mi,CONVERT(varchar(20), fecha, 120)) as [minutes]
			from(

				select inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as fecha,
				count(*) as [totalChats],
				domain,
				ISNULL(count(CASE WHEN (chatstatus = 9) and onQueue = 1 THEN 1 ELSE NULL END),0)AS [waitingAbandoned],
				ISNULL(count(CASE WHEN (chatstatus = 4) and onQueue = 1 THEN 1 ELSE NULL END),0)AS [waitingConnected],
				ISNULL(count(CASE WHEN (chatstatus = 4) THEN 1 ELSE NULL END),0)AS [Connected],
				ISNULL(count(CASE WHEN onQueue = 1 THEN 1 ELSE NULL END),0)AS [onQueue],
				ISNULL(count(CASE WHEN(chatstatus = 2)THEN 1 ELSE NULL END),0)AS [UnavailableAgents],
				ISNULL(count(CASE WHEN(chatstatus = 5)THEN 1 ELSE NULL END),0)AS [OutOfService],
				ISNULL(count(CASE WHEN(chatstatus = 6)THEN 1 ELSE NULL END),0)AS [OutOfSchedule],
				ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
				ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
				ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
				ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow],
				ISNULL(count(CASE WHEN(finishedBy = 0)THEN 1 ELSE NULL END),0) AS [byCostumer],
				ISNULL(count(CASE WHEN(finishedBy = 1)THEN 1 ELSE NULL END),0) AS [byAgent],
				ISNULL(count(CASE WHEN(finishedBy = 2)THEN 1 ELSE NULL END),0) AS [bySystem],
				ISNULL(count(CASE WHEN(finishedBy = 3)THEN 1 ELSE NULL END),0) AS [byAdmin],
				max(tqueue) as maxTQueue,
				avg(tqueue) as avgTQueue
				from ccRIAChats a
				where
				chatStatus in (2,5,4,7,9,10,11)
				group by inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121), domain
				
			) as ChatDetail
			left join ccInbound b on (b.inbound_id = ChatDetail.inboundId)
			left join ccRIACat_Areas c on (c.IDArea = b.IDArea)
			where fecha >= @from and fecha < @to
			group by inboundId, fecha, b.descripcion, ChatDetail.domain, b.IDArea, c.AreaName
			
			declare @DTChat as int
			select @DTChat = valor from ccsettings where setting_id = 134
			
			select inboundId, descripcion, date,
			isnull(convert(decimal(10,2),convert(float,[Connected]) / NULLIF(convert(float, Total) * 100.00,0)),0) as NS
			into #tmpns
			from
			(select inboundId, descripcion, Date,
			sum([Connected>DT]) as [Connected], 
			sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as NotConnected,
			sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as Total
			from (
			select inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as Date,
			ISNULL(count(CASE WHEN chatstatus = 4 and tChatting >= @DTChat THEN 1 ELSE NULL END),0)AS [Connected>DT],
			ISNULL(count(CASE WHEN chatstatus = 4 and tChatting < @DTChat THEN 1 ELSE NULL END),0)AS [Connected<DT],
			ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
			ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
			ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
			ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
			ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
			from ccRIAChats a
			left outer join ccInbound c on (inboundId = inbound_id)
			where chatStatus in (3,4,7,9,10,11)
			and chatDate is not null
			group by inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121)) as ChatDetail
			group by inboundId, descripcion, Date) as ChatSummary order by date, inboundid
			
			update RepACDChats set SL = b.NS 
			from RepACDChats a, #tmpns b where a.date = b.date and a.inboundId = b.inboundId
			drop table #tmpns
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAgentGI - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentGI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
 
SET ANSI_WARNINGS off

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()
 
DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint
 
EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn
 
if @action = 1
begin
 
      declare @starttime datetime
      declare @number int
      set @starttime = @from
      set @number = 0     
      create table #notReady(
            [Row] int identity,
            dateStartDetail datetime,
            dateEndDetail     datetime,
            timegroup   datetime,
            timegroup_next    datetime,
            User_id     int,
            timeNotReady int
      )
     
      create table #inboundData(
      row int identity,
      dateStartDetail datetime,
      dateEndDetail datetime,
      timegroup datetime,
      timegroup_next datetime,
      time_endque datetime,
      time_ring datetime,
      time_dialog datetime,
      time_notes datetime,
      time_end_call datetime,
      phone_in varchar(30),
      cal_id int,
      dni_id int,
      Inbound_id int,
      User_id int,
      ntotal int,
      ninitial int,
      nout_hour int,
      nout_service int,
      nabnd int,
      nno_agent int,
      nque int,
      ntimeout int,
      noverflow int,
      nxfer int,
      nxfer_que int,
      nabnd_xfer int,
      nabnd_ring int,
      nno_answer int,
      nabnd_dialog int,
      nanswer int,
      nlost int,
      nmsg int,
      nabnd_tres int,
      nansw_tres int,
      tque_max int,
      tque int,
      txfer int,
      tdialog int,
      tnotes int,
      tring int,
      tresp int,
      nMoh int,
      nWHag int,
      nWHcl int)
     
      create table #outboundData(
      row int identity,
      dateStartDetail datetime,
      dateEndDetail datetime,
      timegroup datetime,
      timegroup_next datetime,
      cam_id int,
      User_id int,
      ntotal int,
      nno_agent int,
      nxfer int,
      nabnd_xfer int,
      nabnd_ring int,
      nno_answer int,
      nabnd_dialog int,
      nanswer int,
      nlost int,
      tque int,
      txfer int,
      tring int,
      tdialog int,
      tnotes int,
      tresp int,
      nhangup int,
      nMoh int,
      nWHag int,
      nWHcl int,
      time_endque datetime,
      time_ring datetime,
      time_dialog datetime,
      time_notes datetime,
      time_end_call datetime,
      phone_out varchar(30),
      cal_id int,
      cal_puerto int)
     
      CREATE TABLE #times(
      [ID] INT primary key,
      [Start] DATETIME,
      [Stop] DATETIME
      )
 
      create nonclustered index ix_times on #times(
      [Start] DESC,
      [Stop] DESC
      )
      create nonclustered index ix_times2 on #times([Start] DESC)
 
      while @number <= (datediff(mi,@starttime,@to)/15)
      begin
            insert into #times
            SELECT [Hour] = @number,
            StartTime = DATEADD(mi, @number*15, @starttime),
            EndTime = DATEADD(mi, (@number+1)*15, @StartTime)
 
            set @number = @number +1
      end
 
	-- Session Time
	select [user_id], [login], logout, extension
	into #sessionTime
	from(select a.extension, a.user_id, a.fecha as ''login'',
	(select max(Fecha)
	from ccLogLogin b with(nolock)
	where b.user_id = a.user_id and
	b.tipomov = 0 and
	b.fecha >= a.fecha and
	b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
		  from ccLogLogin with(nolock)
		  where user_id = b.user_id and
		  tipomov = 1 and
		  fecha > a.fecha)) as ''logout''
	from ccLogLogin a
	where a.tipomov=1
	and fecha >= @from
	and fecha <= @to) as sessiontime
	order by user_id, login
 
	update s
		set s.logout = (select dateadd(ss,-1,isnull(min(login),getdate())) from #sessionTime where [login]>s.[login] and [user_id] = s.[user_id])
		from #sessionTime s    
		where logout is null

	SELECT TOP 0 * INTO #temp_RepAgentSession FROM #sessionTime

	INSERT INTO #temp_RepAgentSession
	select sessiontime.user_id, sublogin, sublogout, extension
	from(select a.extension, a.user_id, a.fecha as ''subLogout'',
	(select isnull(max(Fecha),getdate())
	from ccLogLogin b with(nolock)
	where b.user_id = a.user_id and
	b.tipomov = 1 and
	b.fecha <= a.fecha and
	b.fecha >= (select isnull(max(fecha),b.fecha)
		  from ccLogLogin with(nolock)
		  where user_id = b.user_id and
		  tipomov = 0 and
		  fecha < a.fecha)
	) as ''subLogin''
	from ccLogLogin a
	where a.tipomov=0
	and fecha >= @from
	and fecha <= @to
	) as sessiontime
	left join ccusers u on (sessiontime.user_id = u.user_id)
	where datediff(day,subLogin,subLogout) >= 1
	order by sessiontime.user_id, sublogin

	UPDATE a with (rowlock)
	SET a.logout = b.logout
	FROM #temp_RepAgentSession b
	INNER JOIN #sessionTime a
	on a.user_Id = b.user_Id
	and a.login = b.login
	and a.logout <> b.logout

	DROP TABLE #temp_RepAgentSession  
	         
	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	SELECT      cal_inicio as dateStartDetail,
		  dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
		  case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_inicio,121) + '':00:00.000''
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_inicio,121) + '':15:00.000''
				when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_inicio,121) + '':30:00.000''
				when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_inicio,121) + '':45:00.000'' end as timegroup,       
		  case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':15:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':30:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':45:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 45 and 59 then  convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas+60),0),cal_inicio) ,121) + '':00:00.000'' end as timegroup_next
		  ,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		  ,isnull(max(cal_Ani),0) as phone_in,cal_id,dni_id,Inbound_id,[User_id]            
		  ,COUNT(cal_id)AS ntotal
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END),0) AS ninitial
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END),0) AS nout_hour
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END),0) AS nout_service
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0) AS nno_agent
		  ,ISNULL(COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END),0) AS nque
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0) AS ntimeout
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0) AS noverflow
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nxfer
		  ,ISNULL(COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END),0) AS nxfer_que
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd_xfer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END),0) AS nabnd_ring
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),0) AS nno_answer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END),0) AS nabnd_dialog
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) AS nanswer
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0) AS nlost
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END),0) AS nmsg
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nabnd_tres
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nansw_tres
		  ,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		  ,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
		  ,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
		  ,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		  ,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl           
		  FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		  WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0               
		  group by cal_id,[User_id],Inbound_id,cal_inicio,dni_id
	   
	delete #inboundData WHERE timegroup>=@from AND timegroup<@to AND INBOUND_ID>0
	AND ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0                                                   
   
	select * into #inboundData2 from #inboundData where datediff(mi,timegroup,timegroup_next)>15

	delete #inboundData where datediff(mi,timegroup,timegroup_next) > 15
               
	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)     
	select
		  dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call                                
		  ,phone_in,cal_id,dni_id,Inbound_id,[User_id]
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ninitial else 0 end as ninitial
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_hour else 0 end as nout_hour       
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_service else 0 end as nout_service
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd else 0 end as nabnd
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent       
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nque else 0 end as nque
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntimeout else 0 end as ntimeout
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then noverflow else 0 end as noverflow
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer_que else 0 end as nxfer_que
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nmsg else 0 end as nmsg
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_tres else 0 end as nabnd_tres
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nansw_tres else 0 end as nansw_tres           
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then tque_max else 0 end as tque_max
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				  when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque         
		  ,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				  when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
				  when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				  when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer               ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
				  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
		  ,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
				  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				  when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		  ,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				  when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
				  when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				  when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring              
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp                                                                      
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl               
		  from #inboundData2 t
		  join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  datediff(ss,th.start,timegroup_next)>0
		  order by cal_id                         
   
	drop table #inboundData2                      
	         
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto)
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull(sum(cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		  ,case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_Inicio,121) + '':00:00.000''
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_Inicio,121) + '':15:00.000''
				when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_Inicio,121) + '':30:00.000''
				when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_Inicio,121) + '':45:00.000'' end as timegroup
		  ,case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':15:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':30:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':45:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 45 and 59 then  convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas + 60),0),cal_Inicio) ,121) + '':00:00.000'' end as timegroup_next 
				,cam_id, [User_id]
				,COUNT(cal_id) AS ntotal
				,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END),0) AS nno_agent
				,ISNULL(COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END),0) AS nxfer
				,ISNULL(COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END),0) AS nabnd_xfer
				,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END),0) AS nabnd_ring
				,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END),0) AS nno_answer
				,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END),0) AS nabnd_dialog
				,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) AS nanswer
				,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END),0) AS nlost
				,ISNULL(SUM(cal_twait),0) as tque
				,ISNULL(SUM(cal_txfer),0)AS txfer
				,isnull(SUM(cal_tring),0) as tring
				,isnull(SUM(cal_tdialog),0) as tdialog        
				,isnull(SUM(cal_tnotas),0) as tnotes
				,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
				,ISNULL(COUNT(CASE WHEN(statuscall_id=6)THEN cal_id ELSE NULL END),0) AS nhangup
				,ISNULL(SUM(CASE WHEN cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag
				,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl                       
				,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
				,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
				,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
				,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
				,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
				,isnull(max(cal_telefono),0) as phone_out,cal_id,cal_puerto                 
		  FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))         
		  WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
		  -- para contar bien las llamadas manuales
		  and cal_manual in(0,2)
		  group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto

	delete from #outboundData WHERE timegroup>=@from AND timegroup<@to
		  AND ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		  AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		  AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0       
               
	select * into #outboundData2 from #outboundData where datediff(mi,timegroup,timegroup_next)>15

	delete #outboundData where datediff(mi,timegroup,timegroup_next) > 15                              
                                      
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto)
	select
		  dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,cam_id,[User_id]
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				  when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque
		  ,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				  when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
				  when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				  when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer
		  ,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				  when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
				  when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				  when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring
		  ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
				  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
		  ,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
				  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				  when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nhangup else 0 end as nhangup
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
		  ,time_endque,time_ring,time_dialog,time_notes,time_end_call
		  ,phone_out,cal_id,cal_puerto            
		  from #outboundData2 t
		  inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  datediff(ss,th.start,timegroup_next)>0
                    
	drop table #outboundData2         
	   
	select DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
		  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end) AS timegroup
		  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end) as timegroup_next
				,[User_id]
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE 0 END),0) AS tunknown
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE 0 END),0) AS tnot_av
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE 0 END),0) AS tav
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE 0 END),0) AS tprob
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE 0 END),0) AS tother
				,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
				into #timeDetailAgent
		  from ccLogAgentesDia
		  WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
		  GROUP BY
		  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end)
		  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end), [User_id]
               
   
	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15

	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15         
   
	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother)
	select
		  min(dateStartDetail),min(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tunknown,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tunknown
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnot_av,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tnot_av
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav                         
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tprob,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tprob,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tprob
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
		  ,isnull(sum(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	group by th.start,th.stop,[User_id]
                                                  
	drop table #timeDetailAgent2

	select ROW_NUMBER() OVER(ORDER BY xTimeDetail.timegroup,xTimeDetail.[user_id] ) AS Row,
		  xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
		  ,ISNULL(calls.txfer,0) as txfer,ISNULL(tdialog,0) as tdialog,ISNULL(tnotes,0) as tnotes,ISNULL(tring,0) as tring
		  ,ISNULL(nMoh,0) as nMoh,ISNULL(nWHag,0) as nWHag,ISNULL(nWHcl,0) as nWHcl
		  ,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
					 FROM #sessionTime
					 WHERE [user_id]=xTimeDetail.[user_id]
						   AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
		  ),0)AS t1                               
		  ,ISNULL((SELECT top 1 900
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login<=xTimeDetail.timegroup AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t2                         
		  ,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t3
		  ,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(mi,15,xTimeDetail.timegroup))
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login>xTimeDetail.timegroup AND login<DATEADD(mi,15,xTimeDetail.timegroup)AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t4
		  into #agentInformation
		  from (select min(dateStartDetail) as dateStartDetail,min(dateEndDetail) as dateEndDetail,timegroup,timegroup_next,[User_id]
			 ,sum(tunknown) as tunknown,sum(tnot_av) as tnot_av,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother,sum(nother) as nother        
				from #timeDetailAgent
				group by timegroup,timegroup_next,user_id
				)xTimeDetail
	right join
	(select CASE WHEN #inboundData.timegroup IS NOT NULL THEN #inboundData.timegroup
					 WHEN #outboundData.timegroup IS NOT NULL THEN #outboundData.timegroup ELSE NULL END timegroup,
		  CASE WHEN #inboundData.[user_id] IS NOT NULL THEN #inboundData.[user_id]
				  WHEN #outboundData.[user_id] IS NOT NULL THEN #outboundData.[user_id] ELSE NULL END as [user_id]
		  ,ISNULL(SUM(#inboundData.txfer),0)+ ISNULL(SUM(#outboundData.txfer),0)as txfer
		  ,ISNULL(SUM(#inboundData.tdialog),0)+ ISNULL(SUM(#outboundData.tdialog),0)as tdialog
		  ,ISNULL(SUM(#inboundData.tnotes),0)+ ISNULL(SUM(#outboundData.tnotes),0)as tnotes
		  ,ISNULL(SUM(#inboundData.tring),0)+ ISNULL(SUM(#outboundData.tring),0)as tring
		  ,ISNULL(SUM(#inboundData.nMoh),0)+ ISNULL(SUM(#outboundData.nMoh),0)as nMoh
		  ,ISNULL(SUM(#inboundData.nWHag),0)+ ISNULL(SUM(#outboundData.nWHag),0)as nWHag
		  ,ISNULL(SUM(#inboundData.nWHcl),0)+ ISNULL(SUM(#outboundData.nWHcl),0)as nWHcl            
	from #inboundData
	FULL OUTER JOIN #outboundData ON(#inboundData.timegroup=#outboundData.timegroup AND #inboundData.[user_id]=#outboundData.[user_id])       
	group by
		  case when #inboundData.timegroup IS NOT NULL then #inboundData.timegroup
				 when #outboundData.timegroup IS NOT NULL then #outboundData.timegroup else NULL end
		  ,case when #inboundData.[user_id] IS NOT NULL then #inboundData.[user_id]
				  when #outboundData.[user_id] IS NOT NULL then #outboundData.[user_id] else NULL end
	) as calls on calls.timegroup = xTimeDetail.timegroup and xTimeDetail.[user_id]=calls.[user_id]
	where xTimeDetail.timegroup is not null
	         
	drop table #timeDetailAgent

	insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,timeNotReady)
	SELECT DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
			  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
					when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
					when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
					when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end) AS timegroup
			  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
					when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
					when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
					when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end) as timegroup_next
					,[User_id],SUM(tStatus) as [timeNotReady]                
			  FROM ccLogAgentesNotReady
			  WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to     
		GROUP BY
			  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
					when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
					when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
					when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end)
			  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
					when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
					when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
					when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end), [User_id]
	               
	select * into #notReady2 from #notReady where datediff(mi,timegroup,timegroup_next)>15

	delete #notReady where datediff(mi,timegroup,timegroup_next) > 15                
	   
	insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,timeNotReady)
	select min(dateStartDetail),min(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
			  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,timeNotReady,dateStartDetail))
					  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
					  when th.start > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,dateadd(ss,timeNotReady,dateStartDetail))
					  when th.start > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as timeNotReady             
		from #notReady2 t
		inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		where  datediff(ss,th.start,timegroup_next)>0
		  group by th.start,th.stop,[User_id]
	   
	drop table #notReady2
	               

	select
		ROW_NUMBER() OVER(ORDER BY  CASE WHEN #agentInformation.timegroup IS NOT NULL THEN #agentInformation.timegroup
					WHEN calls.timegroup IS NOT NULL  THEN calls.timegroup ELSE 0 END,CASE WHEN #agentInformation.user_id IS NOT NULL THEN #agentInformation.user_id
					WHEN calls.userId IS NOT NULL THEN calls.userId ELSE - 1 END) AS id
		,dbo.#agentInformation.row as rowAgentInformation
		,isnull(dbo.#notReady.Row,-1) as rowNotReady        
		,rowIn,rowOut,
		calLIdIn,phoneIn,dateStartDetailIn,callIdOut,phoneOut,dateStartDetailOut,                          
		CASE WHEN #agentInformation.timegroup IS NOT NULL THEN #agentInformation.timegroup
			  WHEN calls.timegroup IS NOT NULL  THEN calls.timegroup ELSE 0 END AS date
		,CASE WHEN #agentInformation.user_id IS NOT NULL THEN #agentInformation.user_id
				WHEN calls.userId IS NOT NULL THEN calls.userId ELSE - 1 END AS [userId]
		,u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + nombres as [user] , u.login as [login]
		,isnull(nxfer_in,0) as nxferin, isnull(nanswer_in,0) as nanswerin, isnull(nabnd_xfer_in,0) as nabndxferin
		,isnull(nabnd_ring_in,0) as nabndringin,isnull(nabnd_dlg_in,0) as nabnddlgin,isnull(abnd_a_xfer_in,0) as abndaxferin
		,isnull(nno_answer_in,0) as nnoanswerin,isnull(nlost_in,0) as nlostin,isnull(tdialog_in,0) as tdialogin
		,isnull(tnotes_in,0) as tnotesin,isnull(tring_in,0) as tringin,isnull(txfer_in,0) as txferin
		,isnull(nxfer_out,0) as nxferout,isnull(nanswer_out,0) as nanswerout,isnull(nabnd_xfer_out,0) as nabndxferout
		,isnull(nabnd_ring_out,0) as nabndringout,isnull(nabnd_dlg_out,0) as nabnddlgout,isnull(abnd_a_xfer_out,0) as abndaxferout
		,isnull(nno_answer_out,0) as nnoanswerout,isnull(nlost_out,0) as nlostout,isnull(tdialog_out,0) as tdialogout
		,isnull(tnotes_out,0) as tnotesout,isnull(tring_out,0) as tringout, isnull(txfer_out,0) as txferout
	   
		,ISNULL(dbo.#agentInformation.nother, 0) AS nother, ISNULL(dbo.#agentInformation.tunknown, 0) AS tunknown
		,ISNULL(dbo.#agentInformation.tnot_av, 0) AS tnotav
		,ISNULL(dbo.#agentInformation.t1, 0)+ISNULL(dbo.#agentInformation.t2, 0)+ISNULL(dbo.#agentInformation.t3, 0)+ISNULL(dbo.#agentInformation.t4, 0)  AS tlog
		,ISNULL(dbo.#notReady.timeNotReady, 0) AS treq
		,ISNULL(dbo.#agentInformation.tav, 0) AS tav, ISNULL(dbo.#agentInformation.tother, 0) AS tother
		,ISNULL(dbo.#agentInformation.tprob, 0) AS tprob
	   
		,isnull(nMoh_in,0) as nMohin,isnull(nMoh_out,0) as nMohout,isnull(nWHag_in,0) as nWHagin
		,isnull(nWHag_out,0) as nWHagout,isnull(nWHcl_in,0) as nWHcliin,isnull(nWHcl_out,0) as nWHcliout
		, CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(yy,#agentInformation.timegroup)
					WHEN calls.timegroup IS NOT NULL THEN datepart(yy,calls.timegroup) ELSE 0 END AS [year]
		  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(mm,#agentInformation.timegroup)
					WHEN calls.timegroup IS NOT NULL THEN datepart(mm,calls.timegroup) ELSE 0 END AS [month]
		  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(dd,#agentInformation.timegroup)
					WHEN calls.timegroup IS NOT NULL THEN datepart(dd,calls.timegroup) ELSE 0 END AS [day]
		  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(hh,#agentInformation.timegroup)
					WHEN calls.timegroup IS NOT NULL THEN datepart(hh,calls.timegroup) ELSE 0 END AS [hour]
		  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(mi,#agentInformation.timegroup)
					WHEN calls.timegroup IS NOT NULL THEN datepart(mi,calls.timegroup) ELSE 0 END AS [minutes]
	into #tempRepAgentGI
	FROM  dbo.#agentInformation
	LEFT OUTER JOIN dbo.ccusers u ON (#agentInformation.[user_id] = u.[user_id])
	LEFT OUTER JOIN dbo.#notReady ON #agentInformation.[user_id] = dbo.#notReady.[user_id] AND dbo.#notReady.timegroup = dbo.#agentInformation.timegroup
	right join
		(
	   
		select
			  CASE WHEN #inboundData.timegroup IS NOT NULL THEN #inboundData.timegroup
						 WHEN #outboundData.timegroup IS NOT NULL THEN #outboundData.timegroup ELSE NULL END timegroup,
			  CASE WHEN #inboundData.[user_id] IS NOT NULL THEN #inboundData.[user_id]
					  WHEN #outboundData.[user_id] IS NOT NULL THEN #outboundData.[user_id] ELSE NULL END as [userId]
			  ,ISNULL(dbo.#inboundData.row, -1) as rowIn,ISNULL(dbo.#outboundData.row, -1) as rowOut
			  ,ISNULL((dbo.#inboundData.nxfer), 0) AS nxfer_in, ISNULL((dbo.#inboundData.nanswer), 0) AS nanswer_in, ISNULL((dbo.#inboundData.nabnd_xfer), 0) AS nabnd_xfer_in
			  ,ISNULL((dbo.#inboundData.nabnd_ring), 0) AS nabnd_ring_in, ISNULL((dbo.#inboundData.nabnd_dialog), 0) AS nabnd_dlg_in
			  ,ISNULL((dbo.#inboundData.nabnd_xfer), 0) + ISNULL((dbo.#inboundData.nabnd_ring), 0) + ISNULL((dbo.#inboundData.nabnd_dialog), 0) AS abnd_a_xfer_in
			  ,ISNULL((dbo.#inboundData.nno_answer), 0) AS nno_answer_in, ISNULL((dbo.#inboundData.nlost), 0) AS nlost_in, ISNULL((dbo.#inboundData.tdialog), 0) AS tdialog_in
			  ,ISNULL((dbo.#inboundData.tnotes), 0) AS tnotes_in, ISNULL((dbo.#inboundData.tring), 0) AS tring_in, ISNULL((dbo.#inboundData.txfer), 0) AS txfer_in
			  ,ISNULL((dbo.#inboundData.nMoh), 0) AS nMoh_in, ISNULL((dbo.#inboundData.nWHag), 0) AS nWHag_in,ISNULL((dbo.#inboundData.nWHcl), 0) AS nWHcl_in               
			  ,ISNULL((dbo.#outboundData.nxfer), 0) AS nxfer_out, ISNULL((dbo.#outboundData.nanswer), 0) AS nanswer_out, ISNULL((dbo.#outboundData.nabnd_xfer), 0) AS nabnd_xfer_out
			  ,ISNULL((dbo.#outboundData.nabnd_ring), 0) AS nabnd_ring_out, ISNULL((dbo.#outboundData.nabnd_dialog), 0) AS nabnd_dlg_out
			  ,ISNULL((dbo.#outboundData.nabnd_xfer), 0) + ISNULL((dbo.#outboundData.nabnd_ring), 0) + ISNULL((dbo.#outboundData.nabnd_dialog), 0) AS abnd_a_xfer_out
			  ,ISNULL((dbo.#outboundData.nno_answer), 0) AS nno_answer_out, ISNULL((dbo.#outboundData.nlost), 0) AS nlost_out, ISNULL((dbo.#outboundData.tdialog), 0) AS tdialog_out
			  ,ISNULL((dbo.#outboundData.tnotes), 0) AS tnotes_out, ISNULL((dbo.#outboundData.tring), 0) AS tring_out, ISNULL((dbo.#outboundData.txfer), 0) AS txfer_out
			  ,ISNULL((dbo.#outboundData.nMoh), 0) AS nMoh_out, ISNULL((dbo.#outboundData.nWHag), 0) AS nWHag_out,ISNULL((dbo.#outboundData.nWHcl), 0) AS nWHcl_out
			  ,isnull((dbo.#inboundData.cal_id),'''') as callIdIn,isnull((dbo.#inboundData.phone_in),'''') as phoneIn,isnull((dbo.#inboundData.dateStartDetail),'''') as dateStartDetailIn
			  ,isnull((dbo.#outboundData.cal_id),'''') as callIdOut,isnull((dbo.#outboundData.phone_out),'''') as phoneOut,isnull((dbo.#outboundData.dateStartDetail),'''') as dateStartDetailOut
		from #inboundData
		FULL OUTER JOIN #outboundData ON(#inboundData.timegroup=#outboundData.timegroup AND #inboundData.[user_id]=#outboundData.[user_id])       
		)calls on calls.timegroup = #agentInformation.timegroup and #agentInformation.[user_id]=calls.[userid]    
		where #agentInformation.timegroup is not null
     
     
      SELECT 
      RANK() OVER(PARTITION BY rowAgentInformation ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      into #tempTime
      FROM #tempRepAgentGI
      where rowAgentInformation in
            (select rowAgentInformation from #tempRepAgentGI temp GROUP BY temp.rowAgentInformation HAVING Count(*) > 1 )
           
      update t
            set nother=0,tunknown=0,tnotav=0,tlog=0,tother=0,tprob=0,tav=0
            from #tempRepAgentGI t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1
     
      delete #tempTime
     
      insert into #tempTime
      SELECT 
      RANK() OVER(PARTITION BY rowNotReady ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      FROM #tempRepAgentGI
      where rowNotReady in
            (select rowNotReady from #tempRepAgentGI temp GROUP BY temp.rowNotReady HAVING Count(*) > 1 )   
                 
      update t
            set treq=0
            from #tempRepAgentGI t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1
     
      delete #tempTime
     
      insert into #tempTime
      SELECT 
      RANK() OVER(PARTITION BY rowIn ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      FROM #tempRepAgentGI
      where rowIn in
            (select rowIn from #tempRepAgentGI temp GROUP BY temp.rowIn HAVING Count(*) > 1 )     
                 
      update t
            set nxferin=0,nanswerin=0,nabndxferin=0,nabndringin=0,nabnddlgin=0,abndaxferin=0,nnoanswerin=0
                  ,nlostin=0,tdialogin=0,tnotesin=0,tringin=0,txferin=0,nMohin=0,nWHagin=0,nWHcliin=0
            from #tempRepAgentGI t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1
           
      delete #tempTime
     
      insert into #tempTime
      SELECT 
      RANK() OVER(PARTITION BY rowOut ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      FROM #tempRepAgentGI
      where rowOut in
            (select rowOut from #tempRepAgentGI temp GROUP BY temp.rowOut HAVING Count(*) > 1 )    
                 
      update t
            set nxferout=0,nanswerout=0,nabndxferout=0,nabndringout=0,nabnddlgout=0,abndaxferout=0,nnoanswerout=0,nlostout=0,tdialogout=0
                  ,tnotesout=0,tringout=0,txferout=0,nMohout=0,nWHagout=0,nWHcliout=0
            from #tempRepAgentGI t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1
     
      delete from RepAgentGI with(rowlock)
	  where date >= @from AND date < @to
           
      insert into RepAgentGI(date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,treq,tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut)
      select
            date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,treq,tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut           
      from #tempRepAgentGI           
       
      drop table #times
      drop table #sessionTime
      drop table #inboundData
      drop table #outboundData
      drop table #agentInformation
      drop table #notReady
      drop table #tempTime
      drop table #tempRepAgentGI        
     
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAgentKPI - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete RepAgentKPI with(rowlock)
	where date >= @from AND date < @to

	create table #ccCalls_Temp(
	cal_id int, 
	User_id smallint, 
	statusCall_id tinyint, 
	cal_tDialog smallint, 
	cal_Inicio datetime, 
	cal_whoHung smallint, 
	tipoTabla tinyint)

	CREATE NONCLUSTERED INDEX IX_ccCalls_Temp ON #ccCalls_Temp (cal_id ASC)

	insert into #ccCalls_Temp 
	select cal_id, User_id, statusCall_id, cal_tDialog, convert(varchar(8), cal_Inicio, 112)+'' 00:00'', cal_whoHung, 0 
	from ccoCallsOut
	where cal_inicio between @from and @to

	insert into #ccCalls_Temp 
	select cal_id, User_id, statusCall_id, cal_tDialog, convert(varchar(8), cal_Inicio, 112)+'' 00:00'', cal_whoHung, 1 
	from ccCallsIn
	where cal_inicio between @from and @to 

	insert into RepAgentKPI
	select convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121)) date, Fst.Login as login, Fst.user_id as [userId],
	Nombres + isnull('' ''+ApellidoPaterno, '''') + isnull('' ''+ApellidoMaterno, '''') as [user], Total as totalCalls, Cin as callsIn, 
	Cout as callsOut, C10 as [finishedCalls10], C20 as [finishedCalls20], C30 as [finishedCalls30], cal_whoHung as whoHung, 
	isnull(avg_fCalc, 0) as callsAvgTime,
	datepart(yyyy,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(mm,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(dd,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(hh,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(mi,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121)))
	from 
	(
	select User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno 
	from ccUsers
	) as Fst
	join
	(
	select user_id, cal_Inicio, sum(Total) Total, sum(Cin) Cin, sum(Cout) Cout, sum(C10) C10, sum(C20) C20, sum(C30) C30, sum(cal_whoHung) cal_whoHung
	from (select user_id, cal_Inicio, 1 Total, tipoTabla Cin, case tipoTabla when 0 then 1 else 0 end Cout,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<10 then 1 else 0 end C10,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<20 then 1 else 0 end C20,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<30 then 1 else 0 end C30,
		cal_whoHung from #ccCalls_Temp
	) as Conteos group by user_id, cal_Inicio
	) as Snd
	on Fst.User_id = Snd.User_id
	left join 
	(
	select User_id, cast((AVG(convert(bigint,fecha_Calc_ms)))/1000.0 as decimal(10,0)) avg_fCalc 
	from ccLogAgentesDia_Dialog where fecha_Dialog between @from and @to 
	group by User_id
	) as Trd
	on Snd.User_id = Trd.User_id

	drop table #ccCalls_Temp
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAgentNotReady - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentNotReady]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS OFF

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
begin
	delete from RepAgentNotReady with(rowlock)
	where date >= @from AND date < @to
	
	-- Session Time
	select [user_id], [login], logout, extension
	into #sessionTime
	from(select a.extension, a.user_id, a.fecha as ''login'',
	(select isnull(max(Fecha),getdate())
	 from ccLogLogin b with(nolock)
	 where b.user_id = a.user_id and
	 b.tipomov = 0 and
	 b.fecha >= a.fecha and
	 b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
		from ccLogLogin with(nolock)
		where user_id = b.user_id and
		tipomov = 1 and
		fecha > a.fecha)) as ''logout''
	from ccLogLogin a
	where a.tipomov=1
	and fecha >= @from
	and fecha <= @to) as sessiontime
	order by user_id, login

		-- Inbound Data
	SELECT timegroup,inbound_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
	,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
	,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
	into #inboundData
	FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
		,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
		,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
		,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
		,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
		,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
		,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
		,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
	FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,[user_id]
		,COUNT(cal_id)AS ntotal
		,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
		,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
		,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
		,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd 
		,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
		,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
		,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
		,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
		,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS xfer
		,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END)AS xfer_que
		,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
		,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
		,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
		,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
		,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
		,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
		,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
		,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
		,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
		,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
		,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
	FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
	WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
	GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,[user_id])xDetailCount
	right JOIN(SELECT timegroup,inbound_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
	FROM(SELECT timegroup,inbound_id,[user_id]
		,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
		,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
		,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
		,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
		,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
	FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
		,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
		,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
		,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
		,*
	FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
	WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
	UNION
	SELECT timegroup_next,inbound_id,[user_id]
		,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
		,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
		,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
		,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
		,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
	FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
		,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
		,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
		,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
		,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
	GROUP BY timegroup,inbound_id,[user_id])xDetailTime
	ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
	ORDER BY timegroup,inbound_id,[user_id]

	--Outbound Data
	SELECT timegroup,cam_id,[user_id],ntotal
	,nno_agent,nxfer
	,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost
	,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
	into #outboundData
	FROM(		
		SELECT xDetailTime.timegroup,xDetailTime.cam_id,xDetailTime.[user_id]
			,ISNULL(ntotal,0)AS ntotal
			,ISNULL(no_agent,0)AS nno_agent,ISNULL(xfer,0)AS nxfer
			,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost
			,xDetailTime.txfer,xDetailTime.tring
			,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp
			,ISNULL(hung_up,0)AS nhangup,ISNULL(nMoh,0) as nMoh,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM(	 
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,cam_id
					,[user_id]
					,COUNT(cal_id)AS ntotal
					,COUNT(CASE WHEN(statuscall_id=6)THEN cal_id ELSE NULL END)AS hung_up --Ne se usa,as que es igual a total para las llamadas sin agente asignada(->agente 0)
					,COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END)AS no_agent
					,COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END)AS xfer
					--,COUNT(CASE WHEN(statuscall_id in(11,15,13,16))THEN 1 ELSE NULL END)AS xfer
					,COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END)AS no_answer
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END)AS answer
					,COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END)AS lost
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
					,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
					-- para contar bien las llamadas manuales
					and cal_manual in(0,2)
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),cam_id,[user_id]
			)xDetailCount
			--RIGHT OUTER JOIN 
			LEFT JOIN
			(
				SELECT timegroup
					,cam_id
					,[user_id]
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(cal_tring),0)AS tring
					,ISNULL(SUM(cal_tdialog),0)AS tdialog
					,ISNULL(SUM(cal_tnotas),0)AS tnotes
				 FROM(	SELECT timegroup,cam_id,[user_id]
						,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					UNION
					SELECT timegroup_next,cam_id,[user_id]
						,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 AS time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					)xTimeDetail
				 GROUP BY timegroup,cam_id,[user_id]
			)xDetailTime
			ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.cam_id=xDetailCount.cam_id AND xDetailTime.[user_id]=xDetailCount.[user_id])
	)xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nno_agent=0
		 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		 AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
	ORDER BY timegroup,cam_id,[user_id]

	-- Agent Information
	SELECT timegroup,[user_id],tlog, 0 as treq, tnot_av
	,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
	,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
	,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
	,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
	,nother,nMoh,nWHag,nWHcl
	into #agentInformation
 FROM(
		SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
			,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
		 FROM(
			SELECT 
				xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
				,ISNULL(SUM(#inboundData.txfer),0)+ ISNULL(SUM(#outboundData.txfer),0)as txfer
				,ISNULL(SUM(#inboundData.tdialog),0)+ ISNULL(SUM(#outboundData.tdialog),0)as tdialog
				,ISNULL(SUM(#inboundData.tnotes),0)+ ISNULL(SUM(#outboundData.tnotes),0)as tnotes
				,ISNULL(SUM(#inboundData.tring),0)+ ISNULL(SUM(#outboundData.tring),0)as tring
				,ISNULL(SUM(#inboundData.nMoh),0)+ ISNULL(SUM(#outboundData.nMoh),0)as nMoh
				,ISNULL(SUM(#inboundData.nWHag),0)+ ISNULL(SUM(#outboundData.nWHag),0)as nWHag
				,ISNULL(SUM(#inboundData.nWHcl),0)+ ISNULL(SUM(#outboundData.nWHcl),0)as nWHcl
		
				,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t1
				,ISNULL((SELECT top 1 3600
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t2
				,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t3
				,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t4
			
			 FROM(
					SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
						,ccLogAgentesDia.[user_id]
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
						,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
					 FROM ccLogAgentesDia
					 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
					 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
				)xTimeDetail
					LEFT OUTER JOIN #inboundData ON(xTimeDetail.timegroup=#inboundData.timegroup AND xTimeDetail.[user_id]=#inboundData.[user_id])
					LEFT OUTER JOIN #outboundData ON(xTimeDetail.timegroup=#outboundData.timegroup AND xTimeDetail.[user_id]=#outboundData.[user_id])
				GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		 	)xDetail
	)xAllTimes
 WHERE tlog>0
 ORDER BY timegroup,[user_id]

	SELECT CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121) AS timegroup
		, [user_id], tiponotready_id
		, COUNT(tStatus) as [count], SUM(tStatus) as [time]
		--, sum( case when separado in (0,3) then 1 else null end ) as amountReal --amount Real
	 into #notReady
	 FROM ccLogAgentesNotReady
	 WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
	 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121), [user_id], tiponotready_id

	insert into RepAgentNotReady
	select a.timegroup as date, c.login, a.user_id as [userId], c.apellidopaterno + '' '' + c.apellidomaterno + '' '' + c.nombres as [user],
	a.tlog as sessionTime, d.tiponotready_id, d.descripcion,
	d.descripcion + ''_Count'' as descripcion_count, [count], d.descripcion + ''_Time'' as descripcion_time,
	[time],
	[time] as timeSeconds--, amountReal
	, datepart(yyyy,a.timegroup), datepart(mm,a.timegroup), datepart(dd,a.timegroup), datepart(hh,a.timegroup), datepart(mi,a.timegroup)
	from #agentInformation a, #notReady b, ccusers c, ccTipoNotReady d
	where a.timegroup = b.timegroup
	and a.user_id = b.user_id
	and b.user_id = c.user_id
	and b.tiponotready_id = d.tiponotready_id

	drop table #sessionTime
	drop table #inboundData
	drop table #outboundData
	drop table #agentInformation
	drop table #notReady

end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAgentNotReadyDet - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentNotReadyDet]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete from RepAgentNotReadyDet with(rowlock)
	where date >= @from AND date < @to
	
	INSERT INTO RepAgentNotReadyDet
	SELECT convert(datetime,convert(varchar(11),fechaInicio)) as [date], isNull(usr.Login,''systemTranslated_NoUserName'') as login, usr.user_id as userId, 
	isNull(usr.ApellidoPaterno,'''') + '' '' + isNull(usr.ApellidoMaterno, '''') + '' '' + IsNull(usr.Nombres, ''systemTranslated_NoName'') as [user],
	isnull(tn.tiponotready_id,0) as tiponotreadyId,  
	isNull(tn.Descripcion, ''systemTranslated_NoStatus'')as [status], 
	fechaInicio as startDate, 
	case when fechaFin is null then fecha when separado = 0 then fecha when separado = 3  or separado = 1 then fechaFin end as endDate,
	case when fechafin is null then
			tStatus
		 when separado = 0 then 
			tStatus
		 when separado = 3  or separado = 1 then
			datediff( s, fechaInicio, fechaFin) end as statusTime,
	case when fechafin is null then tStatus when separado = 0 then tStatus when separado = 3  or separado = 1 then datediff( s, fechaInicio, fechaFin) end as statusTimeSeconds,
	datepart(yyyy,fechaInicio), datepart(mm,fechaInicio), datepart(dd,fechaInicio), datepart(hh,fechaInicio), datepart(mi,fechaInicio)
	From (select distinct user_id, 
		tiponotready_id, 
		DATEADD(s, -tstatus, fecha) AS fechaInicio, 
		separado, 
		tStatus, 
		fecha, 
		( select min( sub.fecha) 
			from ccLogAgentesNotReady sub 
			where sub.separado = 1 
			and sub.fecha = nr.fecha 
			and nr.user_id = sub.user_id 
			and nr.tiponotready_id = sub.tiponotready_id ) as fechaFin 
		from ccLogAgentesNotReady nr 
		WHERE fecha >= @from 
		AND fecha < @to )xdet 
	left join ccUsers usr on usr.user_id = xdet.user_id  
	left join ccTipoNotReady tn on tn.tipoNotready_id = xdet.tiponotready_id 
	where usr.user_id is not null
	order by [user], [status], fechaInicio

end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAvgAnswerTimeChats - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAvgAnswerTimeChats]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete RepAvgAnswerTimeChats with(rowlock)
		where date >= @from and date < @to

		insert into RepAvgAnswerTimeChats
		select CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121) as [date], userId, [Login], inboundId, [inbound],
		[user], convert(decimal(10,2),(convert(decimal(10,2),sum([answerTime])) / convert(decimal(10,2),count(*)))) as [avgAnswerTime]
		, datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		, datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		, datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		, datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		, datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		from(
		select requestDate as [date], userId, [Login] as [login], 
		inboundId, c.descripcion as [inbound], nombres + '' '' + apellidopaterno + '' '' + apellidomaterno as [user],
		case when firstMessageTime is null then convert(int,isnull(firstMessageTime,0)) 
		else datediff(ss,chatdate,firstMessageTime) end as [answerTime]
		from ccriachats a
		left join ccusers b on (a.userId = b.user_id)
		left join ccinbound c on (a.inboundId = c.inbound_id)
		where b.user_id is not null
		and c.inbound_id is not null
		and a.chatstatus = 4) as answerTime
		group by CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121), userId, [Login], inboundId, [inbound], [user]

	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSAgent - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSAgent]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
BEGIN

	---Before insert delete first  table dbo.RepAVRSAgent 
	DELETE FROM dbo.RepAVRSAgent with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSAgent
	--By Agent
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agent,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.age_id = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)
	
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSDisposition - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSDisposition]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRSDisposition 
	DELETE FROM dbo.RepAVRSDisposition with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSDisposition 
	SELECT f.fecha_calif,t.id_formato,t.nombre,u.User_id,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agente,f.id_grabacion,f.total_forma,
		   YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif),CAST(DATEPART(hour, f.fecha_calif) as varchar(2)),CAST(DATEPART(minute, f.fecha_calif) as varchar(2))
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u 
		 ON f.age_id = u.User_id INNER JOIN( SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre ) AS t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	order by f.fecha_calif,t.nombre,u.login
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSQuestionDetail - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSQuestionDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
BEGIN		
	---Before insert delete first table dbo.RepAVRSQuestionDetail 
	DELETE FROM dbo.RepAVRSQuestionDetail with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSQuestionDetail
	SELECT f.fecha_calif, f.id_grabacion, u.user_id, u.login, (u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS [agent], (s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS [supervisor], t.id_formato, t.nombre, c.id_concepto, c.con_descripcion,
		   p.id_pregunta, p.enunciado_pregunta, r.etiquetas, r.peso AS [score], b.finicio, 
		   YEAR(f.fecha_calif) AS [year], MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
    	FROM RIA_FORMACALIF f INNER JOIN (SELECT id_formato, nombre, MAX(version) AS [version]
					  FROM RIA_FORMATOS
					  WHERE activo = 1
					  GROUP BY id_formato, nombre) AS t
	ON (f.id_formato = t.id_formato) AND (f.version = t.version) INNER JOIN ccUsers u
	ON f.age_id = u.user_id INNER JOIN ccUsers s
	ON f.id_supervisor =  s.user_id INNER JOIN RIA_CONCEPTOS c
	ON (t.id_formato = c.id_formato) AND (t.version = c.version) INNER JOIN RIA_PREGUNTAS p
	ON c.id_concepto = p.id_concepto INNER JOIN RIA_RESULTADOSFORMA r
	ON (f.id_forma = r.id_forma) AND (r.id_pregunta = p.id_pregunta) INNER JOIN RIA_GRABACION b
	ON f.id_grabacion = b.grab_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	UNION ALL
	SELECT f.fecha_calif, f.id_grabacion, u.user_id, u.login, (u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS [agent], (s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS [supervisor], t.id_formato, t.nombre, c.id_concepto, c.con_descripcion,
		   p.id_pregunta, p.enunciado_pregunta, r.etiquetas, r.peso AS [score], b.finicio, 
		   YEAR(f.fecha_calif) AS [year], MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
    	FROM RIA_FORMACALIF f INNER JOIN (SELECT id_formato, nombre, MAX(version) AS [version]
					  FROM RIA_FORMATOS
					  WHERE activo = 1
					  GROUP BY id_formato, nombre) AS t
	ON (f.id_formato = t.id_formato) AND (f.version = t.version) INNER JOIN ccUsers u
	ON f.age_id = u.user_id INNER JOIN ccUsers s
	ON f.id_supervisor =  s.user_id INNER JOIN RIA_CONCEPTOS c
	ON (t.id_formato = c.id_formato) AND (t.version = c.version) INNER JOIN RIA_PREGUNTAS p
	ON c.id_concepto = p.id_concepto INNER JOIN RIA_RESULTADOSFORMA r
	ON (f.id_forma = r.id_forma) AND (r.id_pregunta = p.id_pregunta) INNER JOIN RIA_GRABACIONCONSULTA b
	ON f.id_grabacion = b.grab_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	order by f.fecha_calif,c.id_concepto,c.con_descripcion,t.id_formato,t.nombre,u.Login,u.User_id,agent
	
set nocount off
END'
		
	EXEC(@Sql)

		set @process = 'ccspRepAVRSRateDetail - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSRateDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRRateDetail 
	DELETE FROM dbo.RepAVRSRateDetail with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSRateDetail
	SELECT f.fecha_calif,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agent,(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS supervisor,
		   g.grab_id,t.id_formato,t.nombre AS formato,f.total_forma,g.finicio,
		   YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif),CAST(DATEPART(hour, f.fecha_calif) as varchar(2)),CAST(DATEPART(minute, f.fecha_calif) as varchar(2))
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.age_id = u.User_id INNER JOIN( SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre ) AS t
		 ON f.id_formato = t.id_formato AND f.version = t.version INNER JOIN dbo.RIA_GRABACION g
		 ON f.id_grabacion = g.grab_id INNER JOIN dbo.ccUsers s
		 ON f.id_supervisor = s.User_Id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	UNION ALL
	SELECT f.fecha_calif,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agent,(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS supervisor,
		   g.grab_id,t.id_formato,t.nombre AS formato,f.total_forma,g.finicio,
		   YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif),CAST(DATEPART(hour, f.fecha_calif) as varchar(2)),CAST(DATEPART(minute, f.fecha_calif) as varchar(2))
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.age_id = u.User_id INNER JOIN( SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre ) AS t
		 ON f.id_formato = t.id_formato AND f.version = t.version INNER JOIN dbo.RIA_GRABACIONCONSULTA g
		 ON f.id_grabacion = g.grab_id INNER JOIN dbo.ccUsers s
		 ON f.id_supervisor = s.User_Id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	order by f.fecha_calif,u.login,t.nombre
END'
		
	EXEC(@Sql)

		set @process = 'ccspRepAVRSScores - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSScores]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()	

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRSDisposition 
	DELETE FROM dbo.RepAVRSScores with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSScores
	--By Agent
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agent,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.age_id = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)
	UNION ALL
	--By Supervisor
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) as fecha,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS supervisor,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		  YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.id_supervisor = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1
								GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSSection - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSSection]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRSSection 
	DELETE FROM dbo.RepAVRSSection with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSSection
	SELECT f.fecha_calif, u.user_id, u.login, (u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS [agent], t.id_formato, t.nombre, c.id_concepto, c.con_descripcion, SUM(r.peso) AS [score],
		   YEAR(f.fecha_calif) AS [year], MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
    	FROM RIA_FORMACALIF f INNER JOIN (SELECT id_formato, nombre, MAX(version) AS [version]
					  FROM RIA_FORMATOS
					  WHERE activo = 1
					  GROUP BY id_formato, nombre) AS t
	ON (f.id_formato = t.id_formato) AND (f.version = t.version) INNER JOIN ccUsers u
	ON f.age_id = u.user_id INNER JOIN RIA_CONCEPTOS c
	ON (t.id_formato = c.id_formato) AND (t.version = c.version) INNER JOIN RIA_PREGUNTAS p
	ON c.id_concepto = p.id_concepto INNER JOIN RIA_RESULTADOSFORMA r
	ON (f.id_forma = r.id_forma) AND (r.id_pregunta = p.id_pregunta)
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY f.fecha_calif,c.id_concepto,c.con_descripcion,t.id_formato,t.nombre,u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSSupervisor - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSSupervisor]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()	

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRSSupervisor 
	DELETE FROM dbo.RepAVRSSupervisor with(rowlock) 
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSSupervisor
	--By Supervisor
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) as fecha,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS supervisor,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		  YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.id_supervisor = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1
								GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepChatsAndCallsGeneral - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepChatsAndCallsGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
	begin
		CREATE TABLE [dbo].[#callsin](
			[timegroup] [smalldatetime] NOT NULL,
			[inbound_id] [smallint] NOT NULL,
			[dni_id] [smallint] NOT NULL,
			[user_id] [smallint] NOT NULL,
			[ntotal] [smallint] NOT NULL,
			[ninitial] [smallint] NOT NULL,
			[nout_hour] [smallint] NOT NULL,
			[nout_service] [smallint] NOT NULL,
			[nabnd] [smallint] NOT NULL,
			[nno_agent] [smallint] NOT NULL,
			[nque] [smallint] NOT NULL,
			[ntimeout] [smallint] NOT NULL,
			[noverflow] [smallint] NOT NULL,
			[nxfer] [smallint] NOT NULL,
			[nxfer_que] [smallint] NOT NULL,
			[nabnd_xfer] [smallint] NOT NULL,
			[nabnd_ring] [smallint] NOT NULL,
			[nno_answer] [smallint] NOT NULL,
			[nabnd_dialog] [smallint] NOT NULL,
			[nanswer] [smallint] NOT NULL,
			[nlost] [smallint] NOT NULL,
			[nmsg] [smallint] NOT NULL,
			[nabnd_tres] [smallint] NOT NULL,
			[nansw_tres] [smallint] NOT NULL,
			[tque_max] [smallint] NOT NULL,
			[tque] [int] NOT NULL,
			[txfer] [int] NOT NULL,
			[tdialog] [int] NOT NULL,
			[tnotes] [int] NOT NULL,
			[tring] [int] NOT NULL,
			[tresp] [int] NOT NULL,
			[nMoh] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCall_nMoh]  DEFAULT ((0)),
			[nWHag] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCall_nWHag]  DEFAULT ((0)),
			[nWHcl] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCall_nWHcl]  DEFAULT ((0)),
		) ON [PRIMARY]

		INSERT INTO #callsin(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
		,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
		,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
		SELECT timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
		,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
		,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
		FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
			,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
			,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
			,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
			,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
			,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
			,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id,[user_id]
			,COUNT(cal_id)AS ntotal
			,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
			,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
			,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
			,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd 
			,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
			,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
			,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
			,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
			,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS xfer
			,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END)AS xfer_que
			,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
			,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
			,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
			,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
			,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
			,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
			,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
			,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
			,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
			,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
			,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
			,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
			,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
		GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id,[user_id])xDetailCount
		right JOIN(SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
			,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
		FROM(SELECT timegroup,inbound_id,dni_id,[user_id]
			,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
			,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
			,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
			,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
			,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
		FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
			,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
			,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
			,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
			,*
		FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
		UNION
		SELECT timegroup_next,inbound_id,dni_id,[user_id]
			,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
			,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
			,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
			,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
			,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
		FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
			,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
			,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
			,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
			,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
		GROUP BY timegroup,inbound_id,dni_id,[user_id])xDetailTime
		ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id = xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
		WHERE timegroup>=@from AND timegroup<@to
		AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
		AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
		AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
		AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
		ORDER BY timegroup,inbound_id,dni_id,[user_id]

		SELECT CONVERT(varchar(20), timegroup, 120) as [date], ccInbound.inbound_id as inboundId, descripcion as inbound, 
		ntotal, nabnd_que, tque_max, nnoanswer, nanswer, SL, avgTQueue
		into #partialCalls
		FROM (SELECT xDetCall.tg as timegroup , xDetCall.inbound_id  as inbound_id,
			ISNULL(ntotal, 0) ntotal, ISNULL(nabnd_que, 0) nabnd_que , ISNULL(tque_max, 0) tque_max , 
			ISNULL(tque, 0) tque, ISNULL(nanswer, 0) nanswer , ISNULL(tque/ NULLIF(nque, 0), 0) avgTQueue, 
			convert(decimal(10,2),ISNULL(SL_P_1 * 100 / NULLIF(ntotal,0), 0)) SL, ninitial + [nout_hour] + nabnd_xfer + nabnd_ring + nabnd_dialog + nno_agent + ntimeout + noverflow + nno_answer + nlost as nnoanswer,
			SL_P_1, SL_P_2
			FROM (SELECT timegroup as tg, inbound_id, SUM(ntotal) ntotal , SUM(nabnd) nabnd_que , 
				MAX(tque_max) tque_max, NULLIF(SUM(nque), 0) nque,
				SUM(tque) tque, SUM(nanswer) nanswer, SUM(nanswer) AS SL_P_1 , 
				SUM(ninitial + [nout_hour] +  nabnd_xfer + nabnd_ring + nabnd_dialog + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, 
				SUM(nabnd) nabnd, SUM(nno_agent) nno_agent, SUM(ntimeout) ntimeout, SUM(noverflow) noverflow, 
				SUM(nno_answer) nno_answer, SUM(nlost) nlost, sum([nout_hour]) [nout_hour], sum(nabnd_xfer) nabnd_xfer,
				SUM(nabnd_ring) nabnd_ring, SUM(nabnd_dialog) nabnd_dialog, SUM(ninitial) ninitial
				FROM #callsin  
				WHERE timegroup >= @from 
				AND timegroup < @to
				GROUP BY  timegroup, inbound_id) xDetCall) xDetail  
		INNER JOIN ccInbound ON (xDetail.inbound_id = ccInbound.inbound_id) 
		where ccInbound.inbound_id is not null
		order by descripcion, CONVERT(varchar(20), timegroup, 120)

		select fecha as date,
		inboundId, b.descripcion,
		max([totalChats]) as [totalChats],
		sum([waitingAbandoned]) as [waitingAbandoned],
		max(maxTQueue) as maxTQueue,
		sum([UnavailableAgents] + [OutOfService] + [OutOfSchedule] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as [notConnected],
		sum([Connected]) as [Connected],
		convert(decimal(10,2),''0.00'') as SL,
		max(avgTQueue) as avgTQueue
		into #partialChats
		from(

			select inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as fecha,
			count(*) as [totalChats],
			domain,
			ISNULL(count(CASE WHEN (chatstatus = 9) and onQueue = 1 THEN 1 ELSE NULL END),0)AS [waitingAbandoned],
			ISNULL(count(CASE WHEN (chatstatus = 4) THEN 1 ELSE NULL END),0)AS [Connected],
			ISNULL(count(CASE WHEN(chatstatus = 2)THEN 1 ELSE NULL END),0)AS [UnavailableAgents],
			ISNULL(count(CASE WHEN(chatstatus = 5)THEN 1 ELSE NULL END),0)AS [OutOfService],
			ISNULL(count(CASE WHEN(chatstatus = 6)THEN 1 ELSE NULL END),0)AS [OutOfSchedule],
			ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
			ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
			ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
			ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow],
			max(tqueue) as maxTQueue,
			avg(tqueue) as avgTQueue
			from ccRIAChats a
			where
			chatStatus in (2,5,4,7,9,10,11)
			group by inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121), domain
			
		) as ChatDetail
		left join ccInbound b on (b.inbound_id = ChatDetail.inboundId)
		where fecha >= @from and fecha < @to
		group by inboundId, fecha, b.descripcion

		declare @DTChat as int
		select @DTChat = valor from ccsettings where setting_id = 134

		select inboundId, descripcion, date,
		isnull(convert(decimal(10,2),convert(float,[Connected]) / NULLIF(convert(float, Total) * 100.00,0)),0) as NS
		into #tmpns
		from
		(select inboundId, descripcion, Date,
		sum([Connected>DT]) as [Connected], 
		sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as NotConnected,
		sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as Total
		from (
		select inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as Date,
		ISNULL(count(CASE WHEN chatstatus = 4 and tChatting >= @DTChat THEN 1 ELSE NULL END),0)AS [Connected>DT],
		ISNULL(count(CASE WHEN chatstatus = 4 and tChatting < @DTChat THEN 1 ELSE NULL END),0)AS [Connected<DT],
		ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
		ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
		ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
		ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
		ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
		from ccRIAChats a
		left outer join ccInbound c on (inboundId = inbound_id)
		where chatStatus in (3,4,7,9,10,11)
		and chatDate is not null
		group by inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121)) as ChatDetail
		group by inboundId, descripcion, Date) as ChatSummary order by date, inboundid

		update #partialChats set SL = b.NS 
		from #partialChats a, #tmpns b where a.date = b.date and a.inboundId = b.inboundId

		delete RepChatsAndCallsGeneral with(rowlock)
		where date >= @from and date <= @to

		insert into RepChatsAndCallsGeneral
		select convert(datetime,isnull(a.date, b.date)) as date, isnull(a.inboundId,b.inboundId) as inboundId, 
		isnull(a.inbound,b.descripcion) as descripcion,
		isnull(ntotal,0) as ntotal, isnull(totalChats,0) as totalChats, isnull(nabnd_que,0) as nabnd_que, 
		isnull(waitingAbandoned,0) as waitingAbandoned, isnull(tque_max,0) as tque_max, 
		isnull(maxTQueue,0) as maxTQueue, isnull(nnoanswer,0) as nnoanswer, isnull(notConnected,0) as notConnected,
		isnull(nanswer,0) as nanswer, isnull(Connected,0) as Connected, isnull(a.SL,0) as SL1, isnull(b.SL,0) as SL2, 
		isnull(a.avgTQueue,0) as avgTQueue1, isnull(b.avgTQueue,0) as avgTQueue2,
		datepart(yyyy,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [year],
		datepart(mm,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [month],
		datepart(dd,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [day],
		datepart(hh,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [hour],
		datepart(mi,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [minutes]
		from #partialCalls a
		full join #partialChats b on (a.date = b.date and a.inboundId = b.inboundId)

		drop table #tmpns
		drop table #partialChats
		drop table #partialCalls
		drop table #callsin
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepChatsDetail - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepChatsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
		
		delete from RepChatsDetail with(rowlock)
		where date >= @from AND date < @to
	
		insert into RepChatsDetail
			select requestDate,
			inboundId, b.descripcion, chatstatus, c.description, disposition, isnull(d.description,''''),
			subDisposition, isnull(califSubDesc,''''), domain, userid, isnull(f.login,''''), clientName, tqueue,
			0 as txfer, tchatting, 
			isnull(nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''') as Nombre,
			datepart(yyyy,CONVERT(varchar(20), requestDate, 120)) as [year],
			datepart(mm,CONVERT(varchar(20), requestDate, 120)) as [month],
			datepart(dd,CONVERT(varchar(20), requestDate, 120)) as [day],
			datepart(hh,CONVERT(varchar(20), requestDate, 120)) as [hour],
			datepart(mi,CONVERT(varchar(20), requestDate, 120)) as [minutes]
			from ccRIAChats
			left join ccInbound b on (inboundId = inbound_id)
			left join ccRIAChatStatus c on (chatstatus = id)
			left join ccTipoCalif d on (calif_id = disposition)
			left join ccTipoCalifSub e on (califSub_id = subDisposition)
			left join ccusers f on (User_id = userid)
			where requestDate >= @from and requestDate < @to
			
			select isnull(datediff(ss,requestDate,chatdate) - tqueue,0) as xferTime, requestDate as date
			into #tmpxferTime
			from ccRIAChats where chatstatus = 4
			
			update RepChatsDetail set xferTime = b.xferTime
			from RepChatsDetail a, #tmpxferTime b where a.date = b.date 
			
			drop table #tmpxferTime 
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepChatsEffectiveness - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepChatsEffectiveness]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete from RepChatsEffectiveness with(rowlock)
	where date >= @from AND date < @to

	insert into RepChatsEffectiveness
	select 
		a.date, a.inboundId, d.descripcion as [inbound]
		,a.ntotalChat, isnull(b.nanswer,0) as nanswerChat, isnull(c.nabnd,0) as nabnd
		, convert(decimal(10,2),isnull(convert(decimal(10,0),b.nAnswerTime)/convert(decimal(10,0),nAnswer),0)) as [avgAnswerTime]	
		, convert(decimal(10,2),isnull(convert(decimal(10,0),b.tSumQueue)/convert(decimal(10,0),nAnswer),0)) as [avgQueueTime]	
		, convert(decimal(10,2),isnull(convert(decimal(10,0),c.tSumAbandon)/convert(decimal(10,0),c.nabnd),0)) as [avgAbandonTime]
		, datepart(yyyy,a.date) as [year], datepart(mm,a.date) as [mount]
		, datepart(dd,a.date) as [day], datepart(hh,a.date) as [hh], datepart(mi,a.date) as [minutes]
	FROM(
		(SELECT 
			CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ '':00'',121) as [date],
			a.inboundId , count(*) as ntotalChat
			FROM ccRIaChats a		
			where requestDate >= @from AND requestDate < @to
			group by CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ '':00'',121), a.inboundId	
		) as a	
		LEFT JOIN
		(SELECT 
			CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as date,
			inboundId , count(*) as nAnswer
			,sum(case when firstMessageTime is null then convert(int,isnull(firstMessageTime,0)) 
				else datediff(ss,chatdate,firstMessageTime) end ) as [nAnswerTime]
			,sum(tQueue) as tSumQueue
			FROM ccRIaChats
			where chatStatus = 4 AND requestDate >= @from AND requestDate < @to -- Contestados
			group by CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121), inboundId	
		)as b
		ON a.date =  b.date AND a.inboundId = b.inboundId
		LEFT JOIN 
		(SELECT 
			CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as date,
			inboundId , count(*) as nabnd, sum(tQueue) as tSumAbandon
			FROM ccRIaChats
			where chatStatus = 9 AND requestDate >= @from AND requestDate < @to -- abandonadas		
			group by CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121), inboundId	
		)as c
		ON a.date = c.date AND a.inboundId = c.inboundId	
		INNER JOIN ccinbound d on (a.inboundId = d.inbound_id)
	)
	
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepChatsNotContacted - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepChatsNotContacted]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete from RepChatsNotContacted with(rowlock)
	where date >= @from AND date < @to

	insert INTO RepChatsNotContacted
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ '':00'',121) as date,
		inboundId,MAX(b.descripcion) as Inbound, MAX(b.IDArea) as areaID, MAX(c.AreaName) as area,
		DATEPART(yyyy,MAX(requestDate)) as [year], DATEPART(mm,MAX(requestDate)) as [mounth], DATEPART(dd,MAX(requestDate)) as [day],
		DATEPART(hh,MAX(requestDate)) as [hour], 0 as minutes,
		a.chatStatus as chatStatus,MIN(d.description)+''_Count'' as descriptionCount, COUNT(a.chatStatus) as [count]
		FROM ccRIaChats a
		INNER JOIN ccInbound b ON a.inboundId = b.Inbound_id
		INNER JOIN ccRIACat_Areas c ON c.IDArea = b.IDArea 
		INNER JOIN ccRIAChatStatus d ON d.id = a.chatStatus
		where a.chatStatus IN(10,11,6,5,7) AND a.requestDate >= @from AND a.requestDate < @to
		group by CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ '':00'',121), a.inboundId, b.IDArea, a.chatStatus 
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInBill01900 - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInBill01900]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off 
set ANSI_WARNINGS off

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
	begin

		--Borrar lo que esta para no repetir
		delete from RepInBill01900 with(rowlock)
		where date >= @from AND date < @to

		INSERT INTO RepInBill01900(date,inboundId,inbound,ntotalin,nxfer,tque2,txfer,tdialog,tring,[nminutes],[ncost],[year],[month],[day],[hour],[minutes])
		SELECT timegroup,xComplete.inbound_id,ccInbound.descripcion,ntotal,nxfer,tque,txfer,tdialog,tring, ceiling((tque+txfer+tdialog+tring) / 60.00),
		convert(int,ceiling((tque+txfer+tdialog+tring) / 60.00) * 25)
		, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
		, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
		, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
		, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
		, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes] 
		FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
			,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
			,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
			,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
			,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
			,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
			,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id
			,COUNT(cal_id)AS ntotal
			,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
			,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
			,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
			,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd 
			,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
			,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
			,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
			,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
			,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS xfer
			,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END)AS xfer_que
			,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
			,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
			,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
			,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
			,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
			,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
			,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
			,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
			,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
			,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
			,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
			,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
			,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
		GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id)xDetailCount
		right JOIN(SELECT timegroup,inbound_id,dni_id,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
			,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
		FROM(SELECT timegroup,inbound_id,dni_id
			,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
			,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
			,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
			,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
			,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
		FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
			,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
			,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
			,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
			,*
		FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
		UNION
		SELECT timegroup_next,inbound_id,dni_id
			,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
			,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
			,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
			,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
			,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
		FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
			,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
			,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
			,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
			,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
		GROUP BY timegroup,inbound_id,dni_id)xDetailTime
		ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id = xDetailCount.dni_id))xComplete
		LEFT OUTER JOIN ccDnis on (xComplete.dni_id = ccdnis.dni_id)
		LEFT OUTER JOIN ccInbound ON (xComplete.inbound_id = ccInbound.inbound_id)
		WHERE timegroup>=@from AND timegroup<@to
		AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
		AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
		AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
		AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
		and ccdnis.dni_numero = ''01900''
		ORDER BY timegroup,inbound_id

	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInCalls - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off 
set ANSI_WARNINGS off

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
	begin
	
	declare @starttime datetime
      declare @number int
      set @starttime = @from
      set @number = 0           
     
      create table [#callsin](
      row int identity,
      dateStartDetail datetime,
      dateEndDetail datetime,
      timegroup datetime,
      timegroup_next datetime,
      time_endque datetime,
      time_ring datetime,
      time_dialog datetime,
      time_notes datetime,
      time_end_call datetime,
      phone_in varchar(30),
      cal_id int,
      dni_id int,
      Inbound_id int,
      User_id int,
      ntotal int,
      ninitial int,
      nout_hour int,
      nout_service int,
      nabnd int,
      nno_agent int,
      nque int,
      ntimeout int,
      noverflow int,
      nxfer int,
      nxfer_que int,
      nabnd_xfer int,
      nabnd_ring int,
      nno_answer int,
      nabnd_dialog int,
      nanswer int,
      nlost int,
      nmsg int,
      nabnd_tres int,
      nansw_tres int,
      tque_max int,
      tque int,
      txfer int,
      tdialog int,
      tnotes int,
      tring int,
      tresp int,
      nMoh int,
      nWHag int,
      nWHcl int)
      
	CREATE TABLE [dbo].[#ccGenInSpec](
		[timegroup] [smalldatetime] NOT NULL,
		[inbound_id] [smallint] NOT NULL,
		[pos_tot] [smallint] NOT NULL,
		[pos_time] [int] NOT NULL,
		[pos_efect] [smallint] NOT NULL
	) ON [PRIMARY]

	CREATE TABLE [dbo].[#ccGenSession](
		[user_id] [smallint] NOT NULL,
		[login] [datetime] NOT NULL,
		[logout] [datetime] NULL default(getdate()),
		[extension] [varchar](7) NOT NULL
	) ON [PRIMARY]

	CREATE TABLE [dbo].[#ccGenInCall](
		[timegroup] [smalldatetime] NOT NULL,
		[inbound_id] [smallint] NOT NULL,
		[dni_id] [smallint] NOT NULL,
		[user_id] [smallint] NOT NULL,
		[ntotal] [smallint] NOT NULL,
		[ninitial] [smallint] NOT NULL,
		[nout_hour] [smallint] NOT NULL,
		[nout_service] [smallint] NOT NULL,
		[nabnd] [smallint] NOT NULL,
		[nno_agent] [smallint] NOT NULL,
		[nque] [smallint] NOT NULL,
		[ntimeout] [smallint] NOT NULL,
		[noverflow] [smallint] NOT NULL,
		[nxfer] [smallint] NOT NULL,
		[nxfer_que] [smallint] NOT NULL,
		[nabnd_xfer] [smallint] NOT NULL,
		[nabnd_ring] [smallint] NOT NULL,
		[nno_answer] [smallint] NOT NULL,
		[nabnd_dialog] [smallint] NOT NULL,
		[nanswer] [smallint] NOT NULL,
		[nlost] [smallint] NOT NULL,
		[nmsg] [smallint] NOT NULL,
		[nabnd_tres] [smallint] NOT NULL,
		[nansw_tres] [smallint] NOT NULL,
		[tque_max] [smallint] NOT NULL,
		[tque] [int] NOT NULL,
		[txfer] [int] NOT NULL,
		[tdialog] [int] NOT NULL,
		[tnotes] [int] NOT NULL,
		[tring] [int] NOT NULL,
		[tresp] [int] NOT NULL,
		[nMoh] [smallint] NOT NULL DEFAULT ((0)),
		[nWHag] [smallint] NOT NULL DEFAULT ((0)),
		[nWHcl] [smallint] NOT NULL DEFAULT ((0))
	) ON [PRIMARY]
	
	
	CREATE TABLE #times(
      [ID] INT primary key,
      [Start] DATETIME,
      [Stop] DATETIME
      )
 
      create nonclustered index ix_times on #times(
      [Start] DESC,
      [Stop] DESC
      )
      create nonclustered index ix_times2 on #times([Start] DESC)
 
      while @number <= (datediff(mi,@starttime,@to)/15)
      begin
            insert into #times
            SELECT [Hour] = @number,
            StartTime = DATEADD(mi, @number*15, @starttime),
            EndTime = DATEADD(mi, (@number+1)*15, @StartTime)
 
            set @number = @number +1
      end
    
    insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	SELECT      cal_inicio as dateStartDetail,
		  dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
		  case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_inicio,121) + '':00:00.000''
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_inicio,121) + '':15:00.000''
				when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_inicio,121) + '':30:00.000''
				when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_inicio,121) + '':45:00.000'' end as timegroup,       
		  case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':15:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':30:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':45:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 45 and 59 then  convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas+60),0),cal_inicio) ,121) + '':00:00.000'' end as timegroup_next
		  ,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		  ,isnull(max(cal_Ani),0) as phone_in,cal_id,dni_id,Inbound_id,[User_id]            
		  ,COUNT(cal_id)AS ntotal
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END),0) AS ninitial
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END),0) AS nout_hour
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END),0) AS nout_service
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0) AS nno_agent
		  ,ISNULL(COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END),0) AS nque
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0) AS ntimeout
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0) AS noverflow
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nxfer
		  ,ISNULL(COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END),0) AS nxfer_que
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd_xfer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END),0) AS nabnd_ring
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),0) AS nno_answer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END),0) AS nabnd_dialog
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) AS nanswer
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0) AS nlost
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END),0) AS nmsg
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nabnd_tres
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nansw_tres
		  ,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		  ,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
		  ,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
		  ,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		  ,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl           
		  FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		  WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0               
		  group by cal_id,[User_id],Inbound_id,cal_inicio,dni_id
	   
	delete #callsin WHERE timegroup>=@from AND timegroup<@to AND INBOUND_ID>0
	AND ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0                                                   
   
	select * into #callsin2 from #callsin where datediff(mi,timegroup,timegroup_next)>15

	delete #callsin where datediff(mi,timegroup,timegroup_next) > 15
               
	insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)     
	select
		  dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call                                
		  ,phone_in,cal_id,dni_id,Inbound_id,[User_id]
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ninitial else 0 end as ninitial
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_hour else 0 end as nout_hour       
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_service else 0 end as nout_service
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd else 0 end as nabnd
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent       
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nque else 0 end as nque
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntimeout else 0 end as ntimeout
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then noverflow else 0 end as noverflow
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer_que else 0 end as nxfer_que
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nmsg else 0 end as nmsg
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_tres else 0 end as nabnd_tres
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nansw_tres else 0 end as nansw_tres           
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then tque_max else 0 end as tque_max
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				  when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque         
		  ,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				  when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
				  when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				  when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer               ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
				  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
		  ,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
				  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				  when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		  ,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				  when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
				  when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				  when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring              
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp                                                                      
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl               
		  from #callsin2 t
		  join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  datediff(ss,th.start,timegroup_next)>0
		  order by cal_id                         
   
	drop table #callsin2
      
	-- Session Time
	insert into #ccGenSession
	select [user_id], [login], logout,extension
	from(select a.extension, a.user_id, a.fecha as ''login'',
	(select max(Fecha)
	from ccLogLogin b with(nolock)
	where b.user_id = a.user_id and
	b.tipomov = 0 and
	b.fecha >= a.fecha and
	b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
		  from ccLogLogin with(nolock)
		  where user_id = b.user_id and
		  tipomov = 1 and
		  fecha > a.fecha)) as ''logout''
	from ccLogLogin a
	where a.tipomov=1
	and fecha >= @from
	and fecha <= @to) as sessiontime
	order by user_id, login
 
	update s
		set s.logout = (select dateadd(ss,-1,isnull(min(login),getdate())) from ccGenSession where [login]>s.[login] and [user_id] = s.[user_id])
		from #ccGenSession s    
		where logout is null		
	
	select DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
		  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end) AS timegroup
		  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end) as timegroup_next
				,[User_id]
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE 0 END),0) AS tunknown
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE 0 END),0) AS tnot_av
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE 0 END),0) AS tav
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE 0 END),0) AS tprob
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE 0 END),0) AS tother
				,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
				into #timeDetailAgent
		  from ccLogAgentesDia
		  WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
		  GROUP BY
		  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end)
		  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end), [User_id]
               
   
	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15

	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15         
   
	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother)
	select
		  min(dateStartDetail),min(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tunknown,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tunknown
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnot_av,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tnot_av
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav                         
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tprob,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tprob,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tprob
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
		  ,isnull(sum(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	group by th.start,th.stop,[User_id]
                                                  
	drop table #timeDetailAgent2

	select ROW_NUMBER() OVER(ORDER BY xTimeDetail.timegroup,xTimeDetail.[user_id] ) AS Row,
		  xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
		  ,ISNULL(calls.txfer,0) as txfer,ISNULL(tdialog,0) as tdialog,ISNULL(tnotes,0) as tnotes,ISNULL(tring,0) as tring
		  ,ISNULL(nMoh,0) as nMoh,ISNULL(nWHag,0) as nWHag,ISNULL(nWHcl,0) as nWHcl
		  ,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
					 FROM #ccGenSession
					 WHERE [user_id]=xTimeDetail.[user_id]
						   AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
		  ),0)AS t1                               
		  ,ISNULL((SELECT top 1 900
						   FROM #ccGenSession
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login<=xTimeDetail.timegroup AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t2                         
		  ,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
						   FROM #ccGenSession
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t3
		  ,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(mi,15,xTimeDetail.timegroup))
						   FROM #ccGenSession
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login>xTimeDetail.timegroup AND login<DATEADD(mi,15,xTimeDetail.timegroup)AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t4
		  into #agentInformation
		  from (select min(dateStartDetail) as dateStartDetail,min(dateEndDetail) as dateEndDetail,timegroup,timegroup_next,[User_id]
			 ,sum(tunknown) as tunknown,sum(tnot_av) as tnot_av,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother,sum(nother) as nother        
				from #timeDetailAgent
				group by timegroup,timegroup_next,user_id
				)xTimeDetail
	right join
	(select #callsin.timegroup as timegroup,
		  #callsin.[user_id] as [user_id]
		  ,ISNULL(SUM(#callsin.txfer),0) as txfer
		  ,ISNULL(SUM(#callsin.tdialog),0) as tdialog
		  ,ISNULL(SUM(#callsin.tnotes),0) as tnotes
		  ,ISNULL(SUM(#callsin.tring),0) as tring
		  ,ISNULL(SUM(#callsin.nMoh),0) as nMoh
		  ,ISNULL(SUM(#callsin.nWHag),0) as nWHag
		  ,ISNULL(SUM(#callsin.nWHcl),0) as nWHcl            
	from #callsin	
	group by
		  #callsin.timegroup, #callsin.[user_id]
	) as calls on calls.timegroup = xTimeDetail.timegroup and xTimeDetail.[user_id]=calls.[user_id]
	where xTimeDetail.timegroup is not null
	         
	drop table #timeDetailAgent

	INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
		SELECT timegroup, ccInboundAgentes.inbound_id
			, COUNT(DISTINCT #agentInformation.[user_id]) AS pos_max -- pos_tot
			, SUM((t1+t2+t3+t4) - (tnot_av + tprob + tother)) AS pos_time
			, COUNT(CASE WHEN ((t1+t2+t3+t4)- (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
		 FROM #agentInformation
			INNER JOIN ccInboundAgentes ON (#agentInformation.[user_id] = ccInboundAgentes.[user_id])
		 WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0
		 GROUP BY timegroup, ccInboundAgentes.inbound_id

	--Borrar lo que esta para no repetir
	delete from [RepInCalls] with(rowlock)
	where date >= @from AND date < @to
	
	insert into [RepInCalls]
	SELECT	timegroup as [date], ccInbound.inbound_id as inboundId, descripcion as inbound, 
		ccDnis.dni_id as dnisId, ccDnis.dni_descripcion as dnis, 0 as [workgroupId], '''' as [workgroup], 0 as [areaId], 
		'''' as [area], 
		ntotal, nxfer, 
		nabnd_que, nxfer_que, nno_xfer, tque_max , 
		tque, nque, nanswer, nno_answer, nlost, nabnd_xfer, nabnd_ring, nabnd_dialog, pos_tot, pos_time, SL_P_1, SL_P_2 , avg, SL,nMoh, 
		nWHag, nWHcl, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
		, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
		, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
		, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
		, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
		,cal_id,phone_in,dateStartDetail
		FROM (	
	SELECT cal_id,phone_in,isnull(dateStartDetail,'''') as dateStartDetail,
		ISNULL(xDetCall.tg, xDetSpec.tg ) as timegroup , ISNULL(xDetCall.inbound_id, xDetSpec.inbound_id) inbound_id, xDetCall.dni_id as dni_id, 
			ISNULL(ntotal, 0) ntotal, ISNULL(nxfer, 0) nxfer, ISNULL(nabnd_que, 0) nabnd_que , ISNULL(nxfer_que, 0) nxfer_que, 
			ISNULL(nno_xfer, 0) nno_xfer, ISNULL(tque_max, 0) tque_max , ISNULL(tque, 0) tque, ISNULL(nque, 0) nque, 
			ISNULL(nanswer, 0) nanswer , ISNULL(nno_answer, 0) nno_answer, ISNULL(nlost, 0) nlost, ISNULL(nabnd_xfer, 0) nabnd_xfer , 
			ISNULL(nabnd_ring, 0) nabnd_ring, ISNULL(nabnd_dialog, 0) nabnd_dialog, ISNULL(pos_tot, 0) pos_tot , ISNULL(pos_time, 0) pos_time, 
			ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2 , ISNULL(tque/ NULLIF(nque, 0), 0) avg, 
			ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0) SL, ISNULL(nMoh, 0) nMoh, ISNULL(nWHag,0) nWHag, ISNULL(nWHcl,0) nWHcl 
			FROM (SELECT cal_id,phone_in,dateStartDetail,timegroup as tg, inbound_id, dni_id, ntotal , nxfer, nabnd as nabnd_que, nxfer_que,
				(ninitial + nout_service + nout_hour + nno_agent + ntimeout + noverflow ) nno_xfer , tque_max, 
				tque, NULLIF(nque, 0) nque , nanswer, nno_answer , nlost, 
				(nabnd_xfer) nabnd_xfer , nabnd_ring, nabnd_dialog, nMoh, nWHag,
				nWHcl , (nansw_tres + nabnd_tres) AS SL_P_1 , 
				(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2 
				FROM #callsin  
				WHERE timegroup >= @from AND timegroup < @to) xDetCall
	FULL OUTER JOIN (SELECT  timegroup as tg, inbound_id, pos_tot, pos_time  
					FROM #ccGenInSpec  
					WHERE timegroup >= @from AND timegroup < @to) xDetSpec
		ON xDetCall.tg = xDetSpec.tg  AND xDetCall.inbound_id = xDetSpec.inbound_id ) xDetail 
	INNER JOIN ccInbound ON (xDetail.inbound_id = ccInbound.inbound_id) 
	LEFT OUTER JOIN ccDnis ON (xDetail.dni_id = ccDnis.dni_id)
	where ccInbound.inbound_id is not null and ccDnis.dni_id is not null
	order by descripcion, timegroup 
				
	update [RepInCalls] set
	[workgroupId] = b.idwg
	from [RepInCalls] a, ccInboundAgentes b
	where a.inboundId = b.inbound_id

	update [RepInCalls] set
	areaId = b.idarea
	from [RepInCalls] a, ccRIAAreaWorkGroup b
	where a.[workgroupId] = b.idwg

	update [RepInCalls]
	set workgroup = wgname, area = areaname
	from [RepInCalls] a, ccriacat_workgroup b, ccriacat_areas c
	where a.[workgroupId] = b.idwg
	and a.areaId = c.idarea

	
	drop table #times		
	drop table #callsin
	drop table #agentInformation		
	drop table #ccGenInSpec
	drop table #ccGenSession
	drop table #ccGenInCall		
	
	
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInCallsDetail - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInCallsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInCallsDetail with(rowlock)
	where date >= @from AND date < @to

	insert into RepInCallsDetail
	select cal_inicio, Inbound_id, '''', statusCall_id, '''', calif_id, '''', isnull(califSub_id,0), '''', dni_id, '''', user_id, '''',
	isnull(cal_key,''''), cal_ANI, cal_tWait, cal_tXfer, cal_tRing, cal_tDialog, cal_extension, '''',
	cal_whoHung, cal_tMoh, datepart(yyyy,cal_inicio), datepart(mm,cal_inicio), datepart(dd,cal_inicio)
	, datepart(hh,cal_inicio), datepart(mi,cal_inicio)
	,di.provedor_id,prov.descrip [Proveedor],a.cal_puerto
	from cccallsin a
	left join ccoDialers di on di.dialer_id = a.cal_puerto
	left join cstoProvedor prov on di.provedor_id = prov.provedor_id
	where cal_inicio >= @from AND cal_inicio < @to

	update a set acdGroup = isnull(descripcion,'''')
	from RepInCallsDetail a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set callStatus = isnull(descripcion,'''')
	from RepInCallsDetail a
	left join ccstatusllamada b 
	on a.callStatusId = b.statusCall_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,'''')
	from RepInCallsDetail a
	left join cctipocalif b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,'''')
	from RepInCallsDetail a
	left join cctipocalifsub b 
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInCallsDetail a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set dnis = isnull(dni_numero,'''')
	from RepInCallsDetail a
	left join ccdnis b 
	on a.dnisId = b.dni_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInCallsDetail a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInChangeFlow - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInChangeFlow]
	@action as tinyint,
	@from AS datetime = NULL,
	@to AS datetime = NULL
AS

SET NOCOUNT ON
SET DATEFIRST 1

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	DELETE FROM RepInChangeFlow with(rowlock)
	WHERE [date]>=@from AND [date]<@to

	INSERT INTO RepInChangeFlow
	([date],inboundId,inbound,weekday_count,[count],[time],[year],[month],[day],[hour],[minutes])
	
	SELECT
		[date],
		inbound_id,
		'''',
		''day'' + cast (datepart(weekday,[date]) AS VARCHAR(1)) + ''_Count'',
		ISNULL(xfer,0) AS [count],
		left(CONVERT(varchar(20), [date], 114), 8),
		datepart(yyyy,[date]),
		datepart(mm,[date]),
		datepart(dd,[date]),
		datepart(hh,[date]),
		datepart(mi,[date])
	FROM(
		
		SELECT
			CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) AS [date],
			inbound_id,
			COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END) AS xfer
		FROM ccCallsIn
			with (nolock, index(IX_ccCallsIn))
			WHERE cal_inicio>=@from AND cal_inicio<@to AND INBOUND_ID > 0 AND [user_id] > 0
			GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id
	) xFers
	WHERE [date]>=@from AND [date]<@to
	AND ISNULL(xfer,0) > 0
	ORDER BY [date],inbound_id
	
	update r set
	r.Inbound = isnull(i.Descripcion,'''')
	from RepInChangeFlow r, ccInbound i
	where [date] >= @from and [date] < @to
	and i.Inbound_id = r.InboundId 
	and i.inbound_id is not null
	
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInDIDResume - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInDIDResume]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off 
set ANSI_WARNINGS off

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

--Sets amount of hours of last day to include in calculations of agent times
DECLARE @HourExtend AS smallint
SELECT @HourExtend = 2

--@fromExtended used to include the times of calls that extend FROM previous day
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended = DATEADD(hh, -@HourExtend, @from)

DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint
DECLARE @tresDelayIn AS smallint

EXEC @tresRing = ccspConfigTresRing
EXEC @tresDialog = ccspConfigTresDialog
EXEC @tresDelayIn = ccspConfigtresDelayIn

if @action = 1
	begin

		CREATE TABLE [dbo].[#ccGenInCallDNI](
			[timegroup] [smalldatetime] NOT NULL,
			[dni_id] [smallint] NOT NULL,
			[user_id] [smallint] NOT NULL,
			[ntotal] [smallint] NOT NULL,
			[ninitial] [smallint] NOT NULL,
			[nout_hour] [smallint] NOT NULL,
			[nout_service] [smallint] NOT NULL,
			[nabnd] [smallint] NOT NULL,
			[nno_agent] [smallint] NOT NULL,
			[nque] [smallint] NOT NULL,
			[ntimeout] [smallint] NOT NULL,
			[noverflow] [smallint] NOT NULL,
			[nxfer] [smallint] NOT NULL,
			[nxfer_que] [smallint] NOT NULL,
			[nabnd_xfer] [smallint] NOT NULL,
			[nabnd_ring] [smallint] NOT NULL,
			[nno_answer] [smallint] NOT NULL,
			[nabnd_dialog] [smallint] NOT NULL,
			[nanswer] [smallint] NOT NULL,
			[nlost] [smallint] NOT NULL,
			[nmsg] [smallint] NOT NULL,
			[nabnd_tres] [smallint] NOT NULL,
			[nansw_tres] [smallint] NOT NULL,
			[tque_max] [smallint] NOT NULL,
			[tque] [int] NOT NULL,
			[txfer] [int] NOT NULL,
			[tdialog] [int] NOT NULL,
			[tnotes] [int] NOT NULL,
			[tring] [int] NOT NULL,
			[tresp] [int] NOT NULL,
		-- CONSTRAINT [PK_ccGenInCallDNI] PRIMARY KEY CLUSTERED 
		--(
		--	[timegroup] ASC,
		--	[dni_id] ASC,
		--	[user_id] ASC
		--)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
		) ON [PRIMARY]

		INSERT INTO #ccGenInCallDNI (timegroup, dni_id, [user_id]
			, ntotal, nout_hour, nout_service
			, nabnd, nno_agent, nque, ntimeout
			, noverflow, nxfer, nxfer_que
			, nabnd_xfer, nabnd_ring ,nno_answer
			, nabnd_dialog, nanswer, nlost, nmsg
			, nabnd_tres, nansw_tres, tque_max
			, tque, txfer, tring
			, tdialog, tnotes, tresp, ninitial)
		SELECT timegroup, dni_id, [user_id], ntotal, nout_hour, nout_service
			, nabnd, nno_agent, nque, ntimeout, noverflow, nxfer, nxfer_que
			, nabnd_xfer, nabnd_ring ,nno_answer, nabnd_dialog, nanswer, nlost, nmsg
			, nabnd_tres, nansw_tres, tque_max, tque, txfer, tring, tdialog, tnotes, tresp, ninitial
		FROM (		
			SELECT xDetailTime.timegroup, xDetailTime.dni_id, xDetailTime.[user_id]
				, ISNULL(ntotal, 0) AS ntotal, ISNULL(initial, 0) AS ninitial, ISNULL(out_hour, 0) AS nout_hour, ISNULL(out_service, 0) AS nout_service
				, ISNULL(abnd, 0) AS nabnd, ISNULL(no_agent, 0) AS nno_agent, ISNULL(que, 0) AS nque, ISNULL(timeout, 0) AS ntimeout
				, ISNULL(overflow, 0) AS noverflow, ISNULL(xfer, 0) AS nxfer, ISNULL(xfer_que, 0) AS nxfer_que
				, ISNULL(abnd_xfer, 0) AS nabnd_xfer, ISNULL(abnd_ring, 0) AS nabnd_ring, ISNULL(no_answer, 0) AS nno_answer
				, ISNULL(abnd_dialog, 0) AS nabnd_dialog, ISNULL(answer, 0) AS nanswer, ISNULL(lost, 0) AS nlost, ISNULL(msg, 0) AS nmsg
				, ISNULL(abnd_tres, 0) AS nabnd_tres, ISNULL(answ_tres, 0) AS nansw_tres, ISNULL(tque_max, 0) AS tque_max
				, xDetailTime.tque, xDetailTime.txfer, xDetailTime.tring
				, xDetailTime.tdialog, xDetailTime.tnotes, ISNULL(tresp, 0) AS tresp
			FROM (	
				SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
					, dni_id
					, [user_id]
					, COUNT(cal_id) AS ntotal
					, COUNT(CASE WHEN statuscall_id = 1 THEN 1 ELSE NULL END) AS initial
					, COUNT(CASE WHEN statuscall_id = 2 THEN 1 ELSE NULL END) AS out_hour 
					, COUNT(CASE WHEN statuscall_id = 3 THEN 1 ELSE NULL END) AS out_service
					, COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
					, COUNT(CASE WHEN (statuscall_id = 4) THEN 1 ELSE NULL END) AS no_agent
					, COUNT(CASE WHEN (cal_que > 0) THEN 1 ELSE NULL END) AS que 
					, COUNT(CASE WHEN (statuscall_id = 7) THEN 1 ELSE NULL END) AS timeout
					, COUNT(CASE WHEN (statuscall_id = 8) THEN 1 ELSE NULL END) AS overflow
					, COUNT(CASE WHEN( (statuscall_id in (11,15,13,16)) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'') ) THEN 1 ELSE NULL END) AS xfer
					, COUNT(CASE WHEN ( (cal_que > 0) and (statuscall_id in (11,15,13,16)  OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00''))  ) THEN cal_xfer ELSE NULL END) AS xfer_que
					, COUNT(CASE WHEN ((statuscall_id = 11) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'')) THEN 1 ELSE NULL END) AS abnd_xfer
					, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring <= @tresRing)) THEN 1 ELSE NULL END) AS abnd_ring
					, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring > @tresRing)) THEN 1 ELSE NULL END) AS no_answer
					, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  <= @tresDialog)) THEN 1 ELSE NULL END) AS abnd_dialog
					, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
					, COUNT(CASE WHEN (statuscall_id = 16) THEN 1 ELSE NULL END) AS lost
					, COUNT(CASE WHEN (statuscall_id IN (9, 10, 12, 14)) THEN 1 ELSE NULL END) AS msg
					, COUNT(CASE WHEN ( (statuscall_id IN (5,6) AND cal_que > 0 AND cal_xfer = ''1900-01-01 00:00:00'') AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS abnd_tres
					, COUNT(CASE WHEN ( (statuscall_id = 13 AND cal_tdialog > @tresDialog) AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS answ_tres
					, ISNULL(MAX(cal_twait), 0) AS tque_max
					, ISNULL(SUM(cal_twait), 0) AS tque
					, ISNULL(SUM(cal_txfer), 0) AS txfer
					, ISNULL(SUM(cal_tdialog), 0) AS tdialog
					, ISNULL(SUM(cal_tnotas), 0) AS tnotes
					, ISNULL(SUM(cal_tring), 0) AS tring
					, ISNULL(SUM(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN (cal_twait + cal_txfer + cal_tring) ELSE NULL END), 0) AS tresp
				FROM ccCallsIn
				WHERE cal_inicio >= @fromExtended AND  cal_inicio < @to AND dni_id > 0
				GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), dni_id, [user_id]
			) xDetailCount
			LEFT JOIN
			(
				SELECT timegroup
					, dni_id
					, [user_id]
					, ISNULL(SUM(cal_twait), 0) AS tque
					, ISNULL(SUM(cal_txfer), 0) AS txfer
					, ISNULL(SUM(cal_tring), 0) AS tring
					, ISNULL(SUM(cal_tdialog), 0) AS tdialog
					, ISNULL(SUM(cal_tnotas), 0) AS tnotes
				FROM ( SELECT timegroup, dni_id, [user_id]
						, CASE WHEN time_endque < timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss, timegroup_next, time_endque) END AS cal_twait
						, CASE WHEN (time_ring < timegroup_next) THEN cal_txfer WHEN ((time_ring >= timegroup_next) AND (time_endque < timegroup_next)) THEN cal_txfer - DATEDIFF(ss, timegroup_next, time_ring) ELSE 0 END  AS cal_txfer
						, CASE WHEN (time_dialog < timegroup_next) THEN cal_tring WHEN ((time_dialog >= timegroup_next) AND (time_ring < timegroup_next)) THEN cal_tring - DATEDIFF(ss, timegroup_next, time_dialog) ELSE 0 END  AS cal_tring
						, CASE WHEN (time_notes < timegroup_next) THEN cal_tdialog WHEN ((time_notes >= timegroup_next) AND (time_dialog < timegroup_next)) THEN cal_tdialog - DATEDIFF(ss, timegroup_next, time_notes) ELSE 0 END  AS cal_tdialog
						, CASE WHEN (time_end_call < timegroup_next) THEN cal_tnotas WHEN ((time_end_call >= timegroup_next) AND (time_notes < timegroup_next)) THEN cal_tnotas - DATEDIFF(ss, timegroup_next, time_end_call) ELSE 0 END  AS cal_tnotas
					FROM (
						SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
							, DATEADD(hh, 1, CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121))  AS timegroup_next
							, DATEADD(ss, cal_twait, cal_inicio)  AS time_endque
							, DATEADD(ss, cal_twait + cal_txfer, cal_inicio)  AS time_ring
							, DATEADD(ss, cal_twait + cal_txfer + cal_tring, cal_inicio)  AS time_dialog
							, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_inicio)  AS time_notes
							, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas, cal_inicio)  AS time_end_call
							, *
						FROM ccCallsIn
						WHERE cal_inicio >= @fromExtended AND  cal_inicio < @to  AND dni_id > 0
					) xDetail
					UNION
					SELECT timegroup_next, dni_id, [user_id]
						, CASE WHEN time_endque >= timegroup_next THEN DATEDIFF(ss, timegroup_next, time_endque) ELSE 0 END AS cal_twait
						, CASE WHEN (time_ring < timegroup_next) THEN 0 WHEN ((time_ring >= timegroup_next) AND (time_endque < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_ring) ELSE cal_txfer END AS cal_txfer
						, CASE WHEN (time_dialog < timegroup_next) THEN 0 WHEN ((time_dialog >= timegroup_next) AND (time_ring < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_dialog) ELSE cal_tring END AS cal_tring
						, CASE WHEN (time_notes < timegroup_next) THEN 0 WHEN ((time_notes >= timegroup_next) AND (time_dialog < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_notes) ELSE cal_tdialog END AS cal_tdialog
						, CASE WHEN (time_end_call < timegroup_next) THEN 0 WHEN ((time_end_call >= timegroup_next) AND (time_notes < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_end_call) ELSE cal_tnotas END AS cal_tnotas
					FROM	(
						SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
							, DATEADD(hh, 1, CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121))  AS timegroup_next
							, DATEADD(ss, cal_twait, cal_inicio)  AS time_endque
							, DATEADD(ss, cal_twait + cal_txfer, cal_inicio)  AS time_ring
							, DATEADD(ss, cal_twait + cal_txfer + cal_tring, cal_inicio)  AS time_dialog
							, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_inicio)  AS time_notes
							, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas, cal_inicio)  AS time_end_call
							, *
						FROM ccCallsIn
						WHERE cal_inicio >= @fromExtended AND  cal_inicio < @to  AND dni_id > 0
					) xDetail
				) xTimeDetail
				GROUP BY timegroup, dni_id, [user_id]
			) xDetailTime
			ON (xDetailTime.timegroup = xDetailCount.timegroup AND xDetailTime.dni_id = xDetailCount.dni_id AND xDetailTime.[user_id] = xDetailCount.[user_id])
		) xComplete
		WHERE timegroup >= @from AND  timegroup < @to
		AND NOT (ntotal = 0 AND nout_hour = 0 AND nout_service = 0 AND nabnd = 0 AND nno_agent = 0 AND nque = 0
			AND ntimeout = 0 AND noverflow = 0 AND nxfer = 0 AND nxfer_que = 0 AND nabnd_xfer = 0 AND nabnd_ring = 0
			AND nno_answer = 0 AND nabnd_dialog = 0 AND nanswer = 0 AND nlost = 0 AND nmsg = 0 AND nabnd_tres = 0
			AND nansw_tres = 0 AND tque_max = 0 AND tque = 0 AND txfer = 0 AND tring = 0 AND tdialog = 0 AND tnotes = 0 AND tresp = 0)
		ORDER BY timegroup, dni_id, [user_id]
		
		delete [RepInDIDResume] with(rowlock)
		where date >= @from AND date < @to 

		insert into [RepInDIDResume]
		select timegroup as date, a.dni_id as dnisId,  CASE WHEN ccd.dni_descripcion = '''' then  convert(varchar,min(ccd.dni_numero)) else ccd.dni_descripcion end as dnis, 
			   (CASE WHEN ccd.dni_descripcion = '''' then  convert(varchar,min(ccd.dni_numero)) else ccd.dni_descripcion end) + ''_Count'' as dnis_count, sum(nanswer) as [count]
		, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
		, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
		, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
		, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
		, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes] 
		from dbo.#ccGenInCallDNI a
		left join ccdnis ccd on (a.dni_id = ccd.dni_id)
		where timegroup >= @from
		and timegroup < @to		
		group by timegroup,a.dni_id,dni_descripcion
		having sum(nanswer) > 0

		drop table #ccGenInCallDNI

	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInDispositions - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInDispositions with(rowlock)
	where date >= @from AND date < @to
	
	insert into RepInDispositions 
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),
		Inbound_id,'''' as ACDGroup, dispositionId, '''' as DispName,'''',
		count(dispositionId) DispAmount,user_id, '''' as login,'''' as username,IDArea, '''' as areaName,1 as wgId ,''systemTranslated_WorkGroup'' as wg ,
		datepart(yyyy,max(dateHour)) as year, datepart(mm,max(dateHour)), datepart(dd,max(dateHour)),
		datepart(hh,max(dateHour)), 0
		FROM (
			SELECT 
				a.cal_inicio as dateHour, a.Inbound_id, a.calif_id as dispositionId, user_id, b.IDArea
				from cccallsin a 		
				left join ccInbound b
				on	b.Inbound_id = a.Inbound_id		
				where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13	--Constestada
				and b.IDArea is not null
			UNION 
			SELECT 		
				requestDate,a.inboundId, a.disposition, a.userId, b.IDArea
				FROM ccRIAChats a
				left join ccInbound b
				on	b.Inbound_id = a.inboundId
				where requestDate >= @from AND requestDate < @to and a.chatStatus = 3 --Assigned
				and b.IDArea is not null		
	) as x group by CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),Inbound_id, dispositionId, user_id, IDArea
	
	update a set acdGroup = isnull(descripcion,'''')
	from RepInDispositions a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,''systemTranslated_Dispositionless''), disposition_count = isnull(description,''systemTranslated_Dispositionless'') + ''_Count''
	from RepInDispositions a
	left join cctipocalif b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInEffectiveness - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInEffectiveness]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off 
set ANSI_WARNINGS off

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
begin
CREATE TABLE [dbo].[#ccGenInCall](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[dni_id] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL,
[ntotal] [smallint] NOT NULL,
[ninitial] [smallint] NOT NULL,
[nout_hour] [smallint] NOT NULL,
[nout_service] [smallint] NOT NULL,
[nabnd] [smallint] NOT NULL,
[nno_agent] [smallint] NOT NULL,
[nque] [smallint] NOT NULL,
[ntimeout] [smallint] NOT NULL,
[noverflow] [smallint] NOT NULL,
[nxfer] [smallint] NOT NULL,
[nxfer_que] [smallint] NOT NULL,
[nabnd_xfer] [smallint] NOT NULL,
[nabnd_ring] [smallint] NOT NULL,
[nno_answer] [smallint] NOT NULL,
[nabnd_dialog] [smallint] NOT NULL,
[nanswer] [smallint] NOT NULL,
[nlost] [smallint] NOT NULL,
[nmsg] [smallint] NOT NULL,
[nabnd_tres] [smallint] NOT NULL,
[nansw_tres] [smallint] NOT NULL,
[tque_max] [smallint] NOT NULL,
[tque] [int] NOT NULL,
[txfer] [int] NOT NULL,
[tdialog] [int] NOT NULL,
[tnotes] [int] NOT NULL,
[tring] [int] NOT NULL,
[tresp] [int] NOT NULL,
[nMoh] [smallint] NOT NULL DEFAULT ((0)),
[nWHag] [smallint] NOT NULL DEFAULT ((0)),
[nWHcl] [smallint] NOT NULL DEFAULT ((0))
) ON [PRIMARY]

CREATE TABLE [dbo].[#ccGenSession](
[user_id] [smallint] NOT NULL,
[login] [datetime] NOT NULL,
[logout] [datetime] NOT NULL,
[extension] [varchar](7) NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[#agents](
[timegroup] [smalldatetime] NOT NULL,
[user_id] [smallint] NOT NULL,
[tlog] [smallint] NOT NULL DEFAULT (0),
[treq] [smallint] NOT NULL DEFAULT (0),
[tnot_av] [int] NOT NULL,
[tav] [smallint] NOT NULL DEFAULT (0),
[tprob] [smallint] NOT NULL DEFAULT (0),
[tunknown] [smallint] NOT NULL DEFAULT (0),
[tother] [smallint] NOT NULL DEFAULT (0),
[nother] [smallint] NOT NULL DEFAULT (0),
[nMoh] [smallint] NOT NULL DEFAULT ((0)),
[nWHag] [smallint] NOT NULL DEFAULT ((0)),
[nWHcl] [smallint] NOT NULL DEFAULT ((0))
) ON [PRIMARY]		

CREATE TABLE [dbo].[#ccGenInSpec](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[pos_tot] [smallint] NOT NULL,
[pos_time] [int] NOT NULL,
[pos_efect] [smallint] NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[#ccGenInAbnd](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[amount] [smallint] NOT NULL,
[time_max] [smallint] NOT NULL,
[time_tot] [bigint] NOT NULL,
[<10] [smallint] NOT NULL,
[<20] [smallint] NOT NULL,
[<30] [smallint] NOT NULL,
[<40] [smallint] NOT NULL,
[<50] [smallint] NOT NULL,
[<60] [smallint] NOT NULL,
[<120] [smallint] NOT NULL,
[<180] [smallint] NOT NULL,
[<240] [smallint] NOT NULL,
[<300] [smallint] NOT NULL,
[+300] [smallint] NOT NULL
) ON [PRIMARY]

INSERT INTO #ccGenInCall(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
SELECT timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id,[user_id]
,COUNT(cal_id)AS ntotal
,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(isnull(cal_xfer,'''') = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd 
,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS xfer
,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END)AS xfer_que
,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id,[user_id])xDetailCount
right JOIN(SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
FROM(SELECT timegroup,inbound_id,dni_id,[user_id]
,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
,*
FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
UNION
SELECT timegroup_next,inbound_id,dni_id,[user_id]
,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
GROUP BY timegroup,inbound_id,dni_id,[user_id])xDetailTime
ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id=xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
WHERE timegroup>=@from AND timegroup<@to
AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
ORDER BY timegroup,inbound_id,dni_id,[user_id]

INSERT INTO #ccGenSession ([user_id], extension, login, logout)
SELECT uid, max(ext) ext, login, max(logout) logout
FROM 
(SELECT uid, ext, login, ISNULL(logout, (SELECT MIN(fecha) FROM ccLogLogin /*with (nolock, index(ccLogLogin_fecha))*/
WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout 
FROM
	(SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout
	FROM 
		(SELECT uid, ext, MAX(login) as login, logout
		FROM
			(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha) 
			FROM ccLogLogin subLogin /*with (nolock, index(ccLogLogin_fecha))*/ WHERE subLogin.tipomov = 0 
			AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout] 
			FROM ccLogLogin Login /*with (nolock, index(ccLogLogin_fecha))*/
			WHERE login.fecha >= dateadd(dd, -5, @from) and tipomov = 1
			GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail 
		WHERE logout IS NOT NULL GROUP BY uid, ext, logout) Login 
	RIGHT OUTER JOIN ccLogLogin  /*with (nolock, index(ccLogLogin_fecha))*/
	ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login AND ccLogLogin.extension = Login.ext)
	WHERE tipomov = 1
	and ccLogLogin.fecha >= dateadd( dd, -5, @from)) Det 
) LoginDetail 
WHERE logout IS NOT NULL
AND login >= @from and login < @to
GROUP BY uid, login

INSERT INTO #agents(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl)
SELECT timegroup,[user_id],tlog,tnot_av
,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
,nother,nMoh,nWHag,nWHcl
FROM(
	SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
		,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
	 FROM(
		SELECT 
			xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
			,ISNULL(SUM(#ccGenInCall.txfer),0) as txfer
			,ISNULL(SUM(#ccGenInCall.tdialog),0) as tdialog
			,ISNULL(SUM(#ccGenInCall.tnotes),0) as tnotes
			,ISNULL(SUM(#ccGenInCall.tring),0) as tring
			,ISNULL(SUM(#ccGenInCall.nMoh),0) as nMoh
			,ISNULL(SUM(#ccGenInCall.nWHag),0) as nWHag
			,ISNULL(SUM(#ccGenInCall.nWHcl),0) as nWHcl

			,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t1
			,ISNULL((SELECT top 1 3600
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t2
			,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t3
			,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t4

		 FROM(
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
					,ccLogAgentesDia.[user_id]
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
					,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
				 FROM ccLogAgentesDia
				 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
			)xTimeDetail
				LEFT OUTER JOIN #ccGenInCall ON(xTimeDetail.timegroup=#ccGenInCall.timegroup AND xTimeDetail.[user_id]=#ccGenInCall.[user_id])
			GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		)xDetail
)xAllTimes
WHERE tlog>0
ORDER BY timegroup,[user_id]

INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
SELECT timegroup, ccInboundAgentes.inbound_id
	, COUNT(DISTINCT #agents.[user_id]) AS pos_max -- pos_tot
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
 FROM #agents
	INNER JOIN ccInboundAgentes ON (#agents.[user_id] = ccInboundAgentes.[user_id])
 WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0
 GROUP BY timegroup, ccInboundAgentes.inbound_id

insert into #ccGenInAbnd (timegroup, inbound_id, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
SELECT timegroup
, inbound_id
, COUNT(cal_inicio) AS amount
, MAX(tAbnd) AS time_max
, SUM(tAbnd) AS time_tot
, COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [<10]
, COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [<20]
, COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [<30]
, COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [<40]
, COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [<50]
, COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [<60]
, COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [<120]
, COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [<180]
, COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [<240]
, COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [<300]
, COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [+300]
FROM	(
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, cal_inicio
	, inbound_id
	, statuscall_id
	, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,'''') = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
	, (cal_twait + cal_txfer + cal_tring) AS tAbnd
 FROM ccCallsIn
	WHERE cal_inicio >= @from AND  cal_inicio < @to
	AND INBOUND_ID > 0
) xCalls
WHERE (abnd IS NOT NULL) 
GROUP BY timegroup, inbound_id

--Borrar lo que esta para no repetir
delete from RepInEffectiveness with(rowlock)
where date >= @from AND date < @to

insert into RepInEffectiveness
SELECT timegroup as date, xDetail.inbound_id, isnull(descripcion, ''systemTranslated_NoACDGroup'') descripcion , ntotal, nanswer, nabnd , isnull(tatention / nullif(nanswer,0),0), 
tque_avg as tqueavg, tQue_tot as tQuetot, nQue_tot as nQuetot, isnull(tabnd_tot / NULLIF(nabnd,0),0) as tabndtot, SL_P_1 as SLP1, SL_P_2 as SLP2, tresp, 
/*pos_tot as postot,*/ pos_count as poscount, ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0)  as Porcentaje
, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes] 
FROM ( 

SELECT ISNULL(xDetCall.timegroup, ISNULL(xDetSpec.timegroup, xDetAbnd.timegroup)) timegroup, ISNULL(xDetCall.inbound_id, 
ISNULL(xDetSpec.inbound_id, xDetAbnd.inbound_id)) inbound_id, ISNULL(ntotal, 0) ntotal, ISNULL(nanswer, 0) nanswer, ISNULL(nabnd, 0) nabnd, 
ISNULL(tatention, 0) tatention, ISNULL(tque_avg, 0) tque_avg, isnull(tQue_tot, 0) tQue_tot, isnull(nQue_tot, 0) nQue_tot, ISNULL(tabnd_tot, 0) tabnd_tot, 
ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2, ISNULL(tresp, 0) tresp, ISNULL(pos_tot, 0) pos_tot, ISNULL(pos_count, 0) pos_count 

FROM (

SELECT timegroup, inbound_id, SUM(ntotal) AS ntotal, SUM(nanswer) AS nanswer, SUM(nabnd) AS nabnd, SUM(tdialog + tnotes) tatention, 
ISNULL(sum(tque)/ NULLIF(sum(nque), 0), 0) AS tque_avg, sum(tque) as tQue_tot, sum(nQue) as nQue_tot, SUM(nansw_tres + nabnd_tres) AS SL_P_1, 
SUM(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, SUM(tresp) AS tresp  
FROM #ccGenInCall  
WHERE timegroup >= @from
AND timegroup < @to 
GROUP BY timegroup , inbound_id) xDetCall  
LEFT JOIN (
SELECT timegroup, inbound_id, SUM(pos_tot) AS pos_tot, SUM(pos_tot) AS pos_avg, SUM(pos_efect) AS pos_efect, COUNT(pos_tot) AS pos_count  
FROM #ccGenInSpec 
WHERE timegroup >= @from
AND timegroup < @to 
GROUP BY timegroup , inbound_id) xDetSpec 
ON (xDetCall.timegroup = xDetSpec.timegroup AND xDetCall.inbound_id = xDetSpec.inbound_id)  
LEFT JOIN (
SELECT timegroup, inbound_id, SUM(time_tot) AS tabnd_tot   
FROM #ccGenInAbnd  
WHERE timegroup >= @from 
AND timegroup < @to 
GROUP BY timegroup , inbound_id) xDetAbnd 
ON (xDetCall.timegroup = xDetAbnd.timegroup AND xDetCall.inbound_id = xDetAbnd.inbound_id) 
) xDetail  
LEFT JOIN ccInbound ON (xDetail.inbound_id=ccInbound.inbound_id)  
ORDER BY date

drop table #ccGenInCall
drop table #ccGenInSpec
drop table #ccGenSession
drop table #agents
drop table #ccGenInAbnd
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInNotTransferred - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInNotTransferred]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInNotTransferred with(rowlock)
	where date >= @from AND date < @to

	insert into RepInNotTransferred
	select a.cal_Inicio as [date], a.Inbound_id, 
	'''' as acd, statusCall_id, '''' as statusCall,'''' as statusCallCount,1 as [count],  b.IDArea, 
	'''' as area, 1 as wgId, ''systemTranslated_WorkGroup'' as wg
	,datepart(yyyy,cal_inicio) as [year]
	,datepart(mm,cal_inicio) as [mount]
	,datepart(dd,cal_inicio) as [day]
	,datepart(hh,cal_inicio) as [hour]
	,datepart(mi,cal_inicio) as [minutes]
	,0 as cal_id,isnull(a.cal_Ani,'''') as phone_in
	from cccallsin a 		
	left join ccInbound b
	on	b.Inbound_id = a.Inbound_id
	where cal_inicio >= @from AND cal_inicio < @to and statuscall_id in (2,3,4,6,7,8)
	and  b.IDArea is not null	

	update a set acdGroup = isnull(descripcion,'''')
	from RepInNotTransferred a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set callStatus = isnull(descripcion,''''), callStatus_Count = isnull(descripcion,'''') + ''_Count''
	from RepInNotTransferred a
	left join ccstatusllamada b 
	on a.callStatusId = b.statusCall_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInNotTransferred a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInRejectedCalls - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInRejectedCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInRejectedCalls with(rowlock)
	where date >= @from AND date < @to
	
	insert into RepInRejectedCalls
		select 			
		D.dni_id,		
		reject.dnis,
		D.dni_Descripcion,
		reject.InBound_id,
		inBound.descripcion,
		reject.cal_inicio,
		reject.ani,
		reject.puerto,
		datepart(yyyy,reject.cal_inicio), datepart(mm,reject.cal_inicio), datepart(dd,reject.cal_inicio), 
		datepart(hh,reject.cal_inicio), datepart(mi,reject.cal_inicio) 		
	from ccCallsReject reject
	INNER JOIN ccDNIS D ON D.dni_numero = reject.dnis and D.dni_Status=1
	INNER JOIN ccInbound inBound ON reject.Inbound_id = inBound.Inbound_id
	where cal_inicio >= @from AND cal_inicio < @to

end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInSubDispositions - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInSubDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInSubDispositions with(rowlock)
	where date >= @from AND date < @to

	insert into RepInSubDispositions 
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),
		Inbound_id,'''' as ACDGroup, subDispositionId, '''' as DispName, '''',
		count(dispositionId) DispAmount,user_id, '''' as login,'''' as username,IDArea, '''' as areaName,1 as wgId ,''systemTranslated_WorkGroup'' as wg ,
		datepart(yyyy,max(dateHour)) as year, datepart(mm,max(dateHour)), datepart(dd,max(dateHour)),
		datepart(hh,max(dateHour)), 0
	 FROM 
	(
		select 
		cal_inicio as dateHour, a.Inbound_id,isnull(a.califSub_id,0) as subDispositionId, calif_id as dispositionId, user_id, b.IDArea
		from cccallsin a 		
		left join ccInbound b
		on	b.Inbound_id = a.Inbound_id		
		where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13
		and b.IDArea is not null
		UNION 
		SELECT 		
			requestDate,a.inboundId, a.subDisposition, a.disposition, a.userId, b.IDArea
			FROM ccRIAChats a
			left join ccInbound b
			on	b.Inbound_id = a.inboundId
			where requestDate >= @from AND requestDate < @to and a.chatStatus = 3 --Assigned
			and b.IDArea is not null
	) as x group by CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),Inbound_id, subDispositionId, user_id, IDArea

	update a set acdGroup = isnull(descripcion,'''')
	from RepInSubDispositions a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,''systemTranslated_Dispositionless''), subDisposition_count = isnull(califSubDesc,''systemTranslated_Dispositionless'') + ''_Count''
	from RepInSubDispositions a
	left join cctipocalifsub b 
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInSubDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepIVRByOptions - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepIVRByOptions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete from RepIVRByOptions with(rowlock)
		where date >= @from AND date < @to
		
		insert into RepIVRByOptions
		select date, [level] as [levelOption], min([Description]) as [descriptionOption], count(*) as [quantityOption]
		, datepart(yyyy,date)
		, datepart(mm,date)
		, datepart(dd,date)
		, datepart(hh,date)
		, datepart(mi,date)
		from ivrstructure,
		( 
			select ivrLLamadas.date, ivr_id, isnull
			((
				select selectedOption + '','' 
				from IVROptions	
				where IVROptions.ivr_id = ivrLLamadas.ivr_id 
				order by IVROptions.date 
				for xml path('''')
			),''#'') as opciones 
			from (
				select A.Ivr_id, A.cal_ani, isnull(B.cal_id,0) as calId , convert(datetime,convert(varchar(11),A.date)) as [date]
				from IVRCallsIn as a 
				left join ccCallsIn as b on  A.IVR_id = B.IVR_id 
				where date >= @from and date < @to
			)ivrLLamadas
			where ivrLLamadas.date >= @from and ivrLLamadas.date < @to
		)x 
		where opciones like [level]+''%''
		group by date, [level]
		order by date, [level]

	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepIVRDetail - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepIVRDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin

	select A.Ivr_id,A.cal_ani,isnull(B.user_id,0) as [user_id],isnull(B.calif_id,0) as [calif_id]
	,isnull(B.cal_id,0) as [cal_id],A.date 
	into #IVRLlamadas
	from IVRCallsIn as A 
	left join ccCallsIn As B on  A.IVR_id = B.IVR_id 
	where date >= @from and date < @to
		
	delete from RepIVRDetail with(rowlock)
	where date >= @from AND date < @to
		
	insert into RepIVRDetail
		select #IVRLlamadas.date as fecha, cal_ani as telefono
			, isNull(u.nombres + '' '' + u.apellidopaterno + '' '' + u.apellidomaterno,'''') as nombre
			, isnull(calif.description, #IVRLlamadas.calif_id) as calificacion, cal_id as cal_id
			, isnull(
			(
				select selectedOption + '',''	from IVROptions
				where IVROptions.ivr_id = #IVRLlamadas.ivr_id
				order by IVROptions.date for xml path('''')
			),'''') as opciones
			, isnull(datediff( ss, date, maxdate),0) as tiempo,
			datepart(yyyy,[date]),
			datepart(mm,[date]),
			datepart(dd,[date]),
			datepart(hh,[date]),
			datepart(mi,[date])
			from #IVRLlamadas
			left join
			(
				select ivr_id, max(date) as maxDate from IVROptions
				group by ivr_id
			) optTime on #IVRLlamadas.ivr_id = optTime.ivr_id
			left join ccusers u on (u.user_id = #IVRLlamadas.user_id)
			left join cctipocalif calif on (calif.calif_id = #IVRLlamadas.calif_id)
			where #IVRLlamadas.date >= @from and #IVRLlamadas.date < @to
			order by date
	
	drop table #IVRLlamadas
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepIVRFirstOption - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepIVRFirstOption]
	@action as tinyint,
	@from AS datetime = NULL,
	@to AS datetime = NULL
AS

SET NOCOUNT ON
SET DATEFIRST 1

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	DELETE FROM RepIVRFirstOption with(rowlock)
	WHERE [date]>=@from AND [date]<@to

	INSERT INTO RepIVRFirstOption
	([date],[descriptionOption],[option_Count],[count],[year],[month],[day],[hour],[minutes])
	
	SELECT
		[date],
		selectedoption,
		'''' + selectedoption + ''_Count'',
		COUNT(selectedOption),
		datepart(yyyy,[date]),
		datepart(mm,[date]),
		datepart(dd,[date]),
		datepart(hh,[date]),
		datepart(mi,[date])
	from
	(
		select convert(varchar(10), [date], 121) as [date], selectedOption from IVROptions
		join
		(
			select ivr_id, min([date]) as minDate from IVROptions
			where [date] >= @from and [date] < @to
			group by ivr_id
		) A
		on A.ivr_id = IVROptions.ivr_id and A.minDate=IVROptions.[date]
	) B
	GROUP BY [date], selectedOption
	ORDER BY [date], selectedOption
	
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepIVRGeneral - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepIVRGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete RepIVRGeneral with(rowlock)
		where date >= @from and date < @to

		insert into RepIVRGeneral
		select convert(varchar(10),date,121) as [date], 
		sum(case when calId = 0 then 1 else 0 end) as [noTransferred], 
		sum(case when calId > 0 then 1 else 0 end) as [transferred], 
		count(*) as [total]
		, datepart(yyyy,convert(varchar(10),date,121))
		, datepart(mm,convert(varchar(10),date,121))
		, datepart(dd,convert(varchar(10),date,121))
		, datepart(hh,convert(varchar(10),date,121))
		, datepart(mi,convert(varchar(10),date,121))
		from (select A.Ivr_id, A.cal_ani, isnull(B.cal_id,0) as calId ,A.date 
				from IVRCallsIn as a 
				left join ccCallsIn as b on  A.IVR_id = B.IVR_id 
				where date >= @from and date < @to) as c
		where date >= @from and date < @to
		group by convert(varchar(10),date,121)
		order by convert(varchar(10),date,121)
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallBacks - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallBacks]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete RepOutCallBacks with(rowlock)
		where date >= @from and date < @to

		insert into RepOutCallBacks
		select cal_fecha as [date], b.user_id as [userId], b.login as [user], c.cam_id as [campaignId], c.cam_descripcion as [campaign],
		cal_key as [callKey], cal_telefono as [originalTel], cal_telCB as [scheduledTel], cal_fecha as [originalDate], 
		cal_fusercallback as [scheduledDate],
		case a.status when 0 then ''systemTranslated_Pending''
		when 1 then ''systemTranslated_Answer''
		when 2 then ''systemTranslated_NoAnswer''
		when 3 then ''systemTranslated_Recicled''
		when 4 then ''systemTranslated_Expired''
		when 5 then ''systemTranslated_OldRecord''
		when 6 then ''systemTranslated_LoadRecord'' end as [status], 
		case when cal_fcallback is null then ''''
			when convert(varchar(13),cal_fcallback) = ''jan 1 1900'' then ''''
			else convert(varchar(255),cal_fcallback) end as [dialDate]
		, datepart(yyyy,cal_fecha) as [year]
		, datepart(mm,cal_fecha) as [month]
		, datepart(dd,cal_fecha) as [day]
		, datepart(hh,cal_fecha) as [hour]
		, datepart(mi,cal_fecha) as [minutes]
		from ccocallbacks a, ccusers b, cccamps c
		where cal_fecha between @from and @to
		and a.user_id = b.user_id
		and a.cam_id = c.cam_id
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallBilling - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallBilling]
	@action as tinyint,
	@from as datetime = null,
	@to as datetime = null
AS

declare @country as tinyint
declare @iva as decimal(3,2)
declare @aux as varchar(3)

select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104
select @aux = isnull(valor,0) from ccsettings where setting_id = 25
set @iva=convert(decimal(3,2),''1.''+@aux)

if @country is null set @country = 1

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	
	delete from RepOutCallBilling with(rowlock)
	where date >= @from AND date < @to
	
		SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS date
			, cam_id, [user_id],
			provedor_id, tipoLlamada_id , min(tipoLlamada) as tipoLlamada
			, COUNT(*) as amount
			, SUM( mins) as mins
			, SUM( costo ) as costo
			, SUM( costo ) * @iva as costoIva
			into #TempOutCallBilling 
		FROM
		(
			SELECT cal_inicio, cco.cam_id as cam_id,
					cco.user_id as user_id,
					cco.provedor_id,
					cco.tipoLlamada_id, t.descrip as tipoLlamada, CEILING((cal_tXfer + cal_tRing + cal_tDialog +1 ) / 60.0 ) as mins, costo
				FROM ccoCallsOut cco 
					inner join cstoTipoLlamada t on cco.tipoLlamada_id = t.tipoLlamada_id			
				WHERE cal_inicio >= @from AND  cal_inicio < @to and cco.provedor_id is not null and cal_manual in (0,2) and country_id = @country
			
			-- Tambien las llamdas que fueron fax
			UNION ALL

			SELECT cco.fecha as fecha, cco.cam_id, 0, p.provedor_id, l.tipoLlamada_id, l.descrip as tipoLlamada,1, t.MinutoUno as costo
				FROM ccoLogDials cco, ccoDialers cd, cstoProvedor p, cstoTarifa t, cstoTipoLlamada l
				WHERE 
				l.country_id = @country
				and cco.answerbit = 1 and cco.tiporesdial_id <> 1
				and cco.fecha >=  @from AND cco.fecha < @to
				and cco.puerto = cd.puerto
				and cd.provedor_id = p.provedor_id	
				and p.provedor_id = t.provedor_id
				and l.longitud = len(cco.telefono)
				and cco.telefono like l.prefijo
				and t.tipoLlamada_id = l.tipoLlamada_id
		
		) costo
		GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), cam_id, [user_id], provedor_id, tipoLlamada_id	

	insert RepOutCallBilling
		select [date], [cam_id], [campaign], [user_id], [agentName], [username], [provedor_id],[provedor], [tipoLlamada_id], 
			(case when tipo = ''amount'' then ''systemTranslated_'' + replace([tipoLLamada],'' '','''') + ''Calls_Count''
				  when tipo = ''mins'' then + ''systemTranslated_'' + replace([tipoLLamada],'' '','''') + ''MinBilled_Count''
				  when tipo = ''costo'' then + ''systemTranslated_'' + replace([tipoLLamada],'' '','''') + ''Cost_Count''
				  when tipo = ''costoIva'' then + ''systemTranslated_'' + replace([tipoLLamada],'' '','''') + ''Tax_Count''
				  else tipo end ) as tipoLLamada_Count
			,convert(varchar,[tipollamada_Count])  as [count]
			, [tipoLLamada] as tipoLlamadaDesp, case when tipo = ''costo'' then convert(int,convert(decimal(10,2),[tipollamada_Count]) ) else 0 end 			
			, datepart(yyyy,[date]) as [year]
			, datepart(mm,[date]) as [month]
			, datepart(dd,[date]) as [day]
			, datepart(hh,[date]) as [hour]
			, datepart(mi,[date]) as [min]
		from 
		   (
				select [date], temp.cam_id as cam_id, camps.cam_descripcion as campaign, 
					temp.user_id as user_id, ccuse.Nombres+'' ''+ ccuse.ApellidoPaterno+'' ''+ccuse.ApellidoMaterno as agentName, ccuse.Login as username,
					temp.provedor_id as provedor_id, prov.descrip as provedor,
					[tipoLlamada_id], [tipoLLamada],[tipoLLamada] as tipoLlamadaDesp,convert(varchar,[amount]) as [amount], convert(varchar,[mins]) as [mins], convert(varchar,[costo]) as [costo], convert(varchar,[costoIva]) as [costoIva]
			   from #TempOutCallBilling temp
				inner join ccCamps camps on camps.cam_id = temp.cam_id
				inner join ccUsers ccuse on ccuse.User_id = temp.user_id
				inner join cstoprovedor prov on prov.provedor_id = temp.provedor_id
			) p
		UNPIVOT
		   ([tipollamada_Count] for tipo IN 
			  ([amount], [mins], [costo], [costoIva])
		)AS unpvt

	drop table #TempOutCallBilling
	
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCalls - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint
SELECT @HourExtend=2
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint
DECLARE @tresDelayIn AS smallint

if @action = 1
begin

	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog
	EXEC @tresDelayIn=ccspConfigtresDelayIn

	 declare @starttime datetime
     declare @number int
     set @starttime = @from
     set @number = 0   

      create table #inboundData(
      row int identity,
      dateStartDetail datetime,
      dateEndDetail datetime,
      timegroup datetime,
      timegroup_next datetime,
      time_endque datetime,
      time_ring datetime,
      time_dialog datetime,
      time_notes datetime,
      time_end_call datetime,
      phone_in varchar(30),
      cal_id int,
      dni_id int,
      Inbound_id int,
      User_id int,
      ntotal int,
      ninitial int,
      nout_hour int,
      nout_service int,
      nabnd int,
      nno_agent int,
      nque int,
      ntimeout int,
      noverflow int,
      nxfer int,
      nxfer_que int,
      nabnd_xfer int,
      nabnd_ring int,
      nno_answer int,
      nabnd_dialog int,
      nanswer int,
      nlost int,
      nmsg int,
      nabnd_tres int,
      nansw_tres int,
      tque_max int,
      tque int,
      txfer int,
      tdialog int,
      tnotes int,
      tring int,
      tresp int,
      nMoh int,
      nWHag int,
      nWHcl int)
     
      create table #outboundData(
      row int identity,
      dateStartDetail datetime,
      dateEndDetail datetime,
      timegroup datetime,
      timegroup_next datetime,
      cam_id int,      
      User_id int,
      ntotal int,
      nno_agent int,
      nxfer int,
      nabnd_xfer int,
      nabnd_ring int,
      nno_answer int,
      nabnd_dialog int,
      nanswer int,
      nlost int,
      tque int,
      txfer int,
      tring int,
      tdialog int,
      tnotes int,
      tresp int,
      nhangup int,
      nMoh int,
      nWHag int,
      nWHcl int,
      time_endque datetime,
      time_ring datetime,
      time_dialog datetime,
      time_notes datetime,
      time_end_call datetime,
      phone_out varchar(30),
      cal_id int,
      cal_puerto int,
      idwg int)
     
     CREATE TABLE #times(
      [ID] INT primary key,
      [Start] DATETIME,
      [Stop] DATETIME
      )
 
      create nonclustered index ix_times on #times(
      [Start] DESC,
      [Stop] DESC
      )
      create nonclustered index ix_times2 on #times([Start] DESC)
 
      while @number <= (datediff(mi,@starttime,@to)/15)
      begin
            insert into #times
            SELECT [Hour] = @number,
            StartTime = DATEADD(mi, @number*15, @starttime),
            EndTime = DATEADD(mi, (@number+1)*15, @StartTime)
 
            set @number = @number +1
      end

	-- Session Time	
	select [user_id], [login], logout, extension
	into #sessionTime
	from(select a.extension, a.user_id, a.fecha as ''login'',
	(select max(Fecha)
	from ccLogLogin b with(nolock)
	where b.user_id = a.user_id and
	b.tipomov = 0 and
	b.fecha >= a.fecha and
	b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
		  from ccLogLogin with(nolock)
		  where user_id = b.user_id and
		  tipomov = 1 and
		  fecha > a.fecha)) as ''logout''
	from ccLogLogin a
	where a.tipomov=1
	and fecha >= @from
	and fecha <= @to) as sessiontime
	order by user_id, login
 
	update s
		set s.logout = (select dateadd(ss,-1,isnull(min(login),getdate())) from #sessionTime where [login]>s.[login] and [user_id] = s.[user_id])
		from #sessionTime s    
		where logout is null

	SELECT TOP 0 * INTO #temp_RepAgentSession FROM #sessionTime

	INSERT INTO #temp_RepAgentSession
	select sessiontime.user_id, sublogin, sublogout, extension
	from(select a.extension, a.user_id, a.fecha as ''subLogout'',
	(select isnull(max(Fecha),getdate())
	from ccLogLogin b with(nolock)
	where b.user_id = a.user_id and
	b.tipomov = 1 and
	b.fecha <= a.fecha and
	b.fecha >= (select isnull(max(fecha),b.fecha)
		  from ccLogLogin with(nolock)
		  where user_id = b.user_id and
		  tipomov = 0 and
		  fecha < a.fecha)
	) as ''subLogin''
	from ccLogLogin a
	where a.tipomov=0
	and fecha >= @from
	and fecha <= @to
	) as sessiontime
	left join ccusers u on (sessiontime.user_id = u.user_id)
	where datediff(day,subLogin,subLogout) >= 1
	order by sessiontime.user_id, sublogin

	UPDATE a with (rowlock)
	SET a.logout = b.logout
	FROM #temp_RepAgentSession b
	INNER JOIN #sessionTime a
	on a.user_Id = b.user_Id
	and a.login = b.login
	and a.logout <> b.logout

	DROP TABLE #temp_RepAgentSession

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	SELECT      cal_inicio as dateStartDetail,
		  dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
		  case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_inicio,121) + '':00:00.000''
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_inicio,121) + '':15:00.000''
				when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_inicio,121) + '':30:00.000''
				when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_inicio,121) + '':45:00.000'' end as timegroup,       
		  case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':15:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':30:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':45:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 45 and 59 then  convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas+60),0),cal_inicio) ,121) + '':00:00.000'' end as timegroup_next
		  ,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		  ,isnull(max(cal_Ani),0) as phone_in,cal_id,dni_id,Inbound_id,[User_id]            
		  ,COUNT(cal_id)AS ntotal
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END),0) AS ninitial
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END),0) AS nout_hour
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END),0) AS nout_service
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0) AS nno_agent
		  ,ISNULL(COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END),0) AS nque
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0) AS ntimeout
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0) AS noverflow
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nxfer
		  ,ISNULL(COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END),0) AS nxfer_que
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd_xfer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END),0) AS nabnd_ring
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),0) AS nno_answer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END),0) AS nabnd_dialog
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) AS nanswer
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0) AS nlost
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END),0) AS nmsg
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nabnd_tres
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nansw_tres
		  ,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		  ,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
		  ,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
		  ,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		  ,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl           
		  FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		  WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0               
		  group by cal_id,[User_id],Inbound_id,cal_inicio,dni_id
	   
	delete #inboundData WHERE timegroup>=@from AND timegroup<@to AND INBOUND_ID>0
	AND ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0                                                   
   
	select * into #inboundData2 from #inboundData where datediff(mi,timegroup,timegroup_next)>15

	delete #inboundData where datediff(mi,timegroup,timegroup_next) > 15
               
	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)     
	select
		  dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call                                
		  ,phone_in,cal_id,dni_id,Inbound_id,[User_id]
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ninitial else 0 end as ninitial
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_hour else 0 end as nout_hour       
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_service else 0 end as nout_service
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd else 0 end as nabnd
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent       
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nque else 0 end as nque
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntimeout else 0 end as ntimeout
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then noverflow else 0 end as noverflow
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer_que else 0 end as nxfer_que
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nmsg else 0 end as nmsg
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_tres else 0 end as nabnd_tres
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nansw_tres else 0 end as nansw_tres           
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then tque_max else 0 end as tque_max
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				  when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque         
		  ,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				  when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
				  when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				  when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer               ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
				  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
		  ,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
				  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				  when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		  ,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				  when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
				  when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				  when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring              
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp                                                                      
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl               
		  from #inboundData2 t
		  join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  datediff(ss,th.start,timegroup_next)>0
		  order by cal_id                         
   
	drop table #inboundData2                      
		
	      
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,idwg)	
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull(sum(cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		  ,case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_Inicio,121) + '':00:00.000''
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_Inicio,121) + '':15:00.000''
				when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_Inicio,121) + '':30:00.000''
				when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_Inicio,121) + '':45:00.000'' end as timegroup
		  ,case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':15:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':30:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':45:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 45 and 59 then  convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas + 60),0),cal_Inicio) ,121) + '':00:00.000'' end as timegroup_next 
				,cam_id, [User_id]
				,COUNT(cal_id) AS ntotal
				,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END),0) AS nno_agent
				,ISNULL(COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END),0) AS nxfer
				,ISNULL(COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END),0) AS nabnd_xfer
				,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END),0) AS nabnd_ring
				,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END),0) AS nno_answer
				,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END),0) AS nabnd_dialog
				,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) AS nanswer
				,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END),0) AS nlost
				,ISNULL(SUM(cal_twait),0) as tque
				,ISNULL(SUM(cal_txfer),0)AS txfer
				,isnull(SUM(cal_tring),0) as tring
				,isnull(SUM(cal_tdialog),0) as tdialog        
				,isnull(SUM(cal_tnotas),0) as tnotes
				,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
				,ISNULL(COUNT(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0) AS nhangup
				,ISNULL(SUM(CASE WHEN cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag
				,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl                       
				,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
				,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
				,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
				,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
				,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
				,isnull(max(cal_telefono),0) as phone_out,cal_id,cal_puerto, 0 as idwg     
		  FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))         
		  WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
		  -- para contar bien las llamadas manuales
		  and cal_manual in(0,2)
		  group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto		  
		
	
	delete from #outboundData WHERE timegroup>=@from AND timegroup<@to
		  AND ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		  AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		  AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0  and nhangup=0     
    
    
    
    update A
    set idwg = B.idwg
    from #outboundData A
    inner join ccriaworkgroup_calid B on A.cal_id = B.cal_id        
        
                      
	select * into #outboundData2 from #outboundData where datediff(mi,timegroup,timegroup_next)>15

	delete #outboundData where datediff(mi,timegroup,timegroup_next) > 15         
                                      
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,idwg)
	select
		  dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,cam_id,[User_id]
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				  when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque
		  ,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				  when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
				  when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				  when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer
		  ,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				  when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
				  when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				  when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring
		  ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
				  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
		  ,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
				  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				  when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nhangup else 0 end as nhangup
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
		  ,time_endque,time_ring,time_dialog,time_notes,time_end_call
		  ,phone_out,cal_id,cal_puerto,idwg           
		  from #outboundData2 t
		  inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  datediff(ss,th.start,timegroup_next)>0
     
                    
	drop table #outboundData2 
		
	select DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
		  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end) AS timegroup
		  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end) as timegroup_next
				,[User_id]
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE 0 END),0) AS tunknown
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE 0 END),0) AS tnot_av
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE 0 END),0) AS tav
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE 0 END),0) AS tprob
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE 0 END),0) AS tother
				,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
				into #timeDetailAgent
		  from ccLogAgentesDia
		  WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
		  GROUP BY
		  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end)
		  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end), [User_id]
                  
	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15

	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15         
      
	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother)
	select
		  min(dateStartDetail),min(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tunknown,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tunknown
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnot_av,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tnot_av
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav                         
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tprob,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tprob,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tprob
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
		  ,isnull(sum(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	group by th.start,th.stop,[User_id]
                                                  
	drop table #timeDetailAgent2

	select ROW_NUMBER() OVER(ORDER BY xTimeDetail.timegroup,xTimeDetail.[user_id] ) AS Row,
		  xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
		  ,ISNULL(calls.txfer,0) as txfer,ISNULL(tdialog,0) as tdialog,ISNULL(tnotes,0) as tnotes,ISNULL(tring,0) as tring
		  ,ISNULL(nMoh,0) as nMoh,ISNULL(nWHag,0) as nWHag,ISNULL(nWHcl,0) as nWHcl
		  ,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
					 FROM #sessionTime
					 WHERE [user_id]=xTimeDetail.[user_id]
						   AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
		  ),0)AS t1                               
		  ,ISNULL((SELECT top 1 900
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login<=xTimeDetail.timegroup AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t2                         
		  ,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t3
		  ,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(mi,15,xTimeDetail.timegroup))
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login>xTimeDetail.timegroup AND login<DATEADD(mi,15,xTimeDetail.timegroup)AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t4
		  into #agentInformation
		  from (select min(dateStartDetail) as dateStartDetail,min(dateEndDetail) as dateEndDetail,timegroup,timegroup_next,[User_id]
			 ,sum(tunknown) as tunknown,sum(tnot_av) as tnot_av,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother,sum(nother) as nother        
				from #timeDetailAgent
				group by timegroup,timegroup_next,user_id
				)xTimeDetail
	right join
	(select CASE WHEN #inboundData.timegroup IS NOT NULL THEN #inboundData.timegroup
					 WHEN #outboundData.timegroup IS NOT NULL THEN #outboundData.timegroup ELSE NULL END timegroup,
		  CASE WHEN #inboundData.[user_id] IS NOT NULL THEN #inboundData.[user_id]
				  WHEN #outboundData.[user_id] IS NOT NULL THEN #outboundData.[user_id] ELSE NULL END as [user_id]
		  ,ISNULL(SUM(#inboundData.txfer),0)+ ISNULL(SUM(#outboundData.txfer),0)as txfer
		  ,ISNULL(SUM(#inboundData.tdialog),0)+ ISNULL(SUM(#outboundData.tdialog),0)as tdialog
		  ,ISNULL(SUM(#inboundData.tnotes),0)+ ISNULL(SUM(#outboundData.tnotes),0)as tnotes
		  ,ISNULL(SUM(#inboundData.tring),0)+ ISNULL(SUM(#outboundData.tring),0)as tring
		  ,ISNULL(SUM(#inboundData.nMoh),0)+ ISNULL(SUM(#outboundData.nMoh),0)as nMoh
		  ,ISNULL(SUM(#inboundData.nWHag),0)+ ISNULL(SUM(#outboundData.nWHag),0)as nWHag
		  ,ISNULL(SUM(#inboundData.nWHcl),0)+ ISNULL(SUM(#outboundData.nWHcl),0)as nWHcl            
	from #inboundData
	FULL OUTER JOIN #outboundData ON(#inboundData.timegroup=#outboundData.timegroup AND #inboundData.[user_id]=#outboundData.[user_id])       
	group by
		  case when #inboundData.timegroup IS NOT NULL then #inboundData.timegroup
				 when #outboundData.timegroup IS NOT NULL then #outboundData.timegroup else NULL end
		  ,case when #inboundData.[user_id] IS NOT NULL then #inboundData.[user_id]
				  when #outboundData.[user_id] IS NOT NULL then #outboundData.[user_id] else NULL end
	) as calls on calls.timegroup = xTimeDetail.timegroup and xTimeDetail.[user_id]=calls.[user_id]
	where xTimeDetail.timegroup is not null
	         
	drop table #timeDetailAgent


	 SELECT timegroup, ccCampsAgente.cam_id		
		, SUM((t1+t2+t3+t4) - (tnot_av + tprob + tother)) AS pos_time
		, COUNT(CASE WHEN ((t1+t2+t3+t4) - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE 0 END) AS tresPos
	 INTO #ccGenOutCamp
	 FROM #agentInformation
		INNER JOIN ccCampsAgente ON (#agentInformation.[user_id] = ccCampsAgente.[user_id])
	 WHERE timegroup >= @from AND timegroup < @to
	 GROUP BY timegroup, ccCampsAgente.cam_id
			
	 select ROW_NUMBER() OVER(Order by row) as id,
		  #outboundData.row, #outboundData.timegroup as [date],0 as areaId,'''' as area
		 ,idwg as workgroupid,'''' as workgroup
		 ,#outboundData.cam_id as campaignid,'''' as campaign
		 ,[User_id] as userId,'''' as [user]		 
		 ,ntotal, nxfer, nno_agent, nanswer, nno_answer, nlost, nabnd_xfer, nabnd_ring, nabnd_dialog
		 ,1 as pos_tot, pos_time, nhangup, (tdialog + tnotes) as  tatencion
		 ,datepart(yy,convert(datetime,#outboundData.timegroup)) as [year]
		 ,datepart(mm,convert(datetime,#outboundData.timegroup)) as [mounth]
		 ,datepart(dd,convert(datetime,#outboundData.timegroup)) as [day]
		 ,datepart(hh,convert(datetime,#outboundData.timegroup)) as [hour]
		 ,datepart(mi,convert(datetime,#outboundData.timegroup)) as [minutes]
		 ,cal_id,phone_out,dateStartDetail
		 into #tempRepOutCalls
		 from #outboundData
		 left join #ccGenOutCamp  ON (#outboundData.timegroup = #ccGenOutCamp.timegroup and #outboundData.cam_id=#ccGenOutCamp.cam_id)
	 
	 SELECT 
      RANK() OVER(PARTITION BY row ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      into #tempTime
      FROM #tempRepOutCalls
      where row in
            (select row from #tempRepOutCalls temp GROUP BY temp.row HAVING Count(*) > 1 )
      
       update t
            set ntotal=0,nxfer=0,nno_agent=0,nanswer=0,nno_answer=0,nlost=0,nabnd_xfer=0,nabnd_ring=0,nabnd_dialog=0,tatencion=0
            from #tempRepOutCalls t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1
    
    delete #tempTime
    
    insert into #tempTime([rank],rowNumber,id)
    SELECT 
      RANK() OVER(PARTITION BY cal_id ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id      
      FROM #tempRepOutCalls
      where cal_id in
            (select cal_id from #tempRepOutCalls temp GROUP BY temp.cal_id HAVING Count(*) > 1 )
      
       update t
            set pos_tot=0
            from #tempRepOutCalls t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1
        
    --Borrar lo que esta para no repetir
	delete from RepOutCalls with(rowlock)
	where date >= @from AND date < @to 
    
     insert into RepOutCalls
		select date,areaId,area,workgroupid,workgroup,campaignid,campaign,userId,user,ntotal,nxfer,nno_agent,nanswer,nno_answer,nlost,nabnd_xfer,nabnd_ring,nabnd_dialog
		,isnull(pos_tot,0),isnull(pos_time,0),nhangup,tatencion,year,mounth,day,hour,minutes,cal_id,phone_out,dateStartDetail
		from #tempRepOutCalls order by cal_id

     
	delete RepOutCalls
	where userId = 0
	and [date] >= @from and [date] < @to

	update RepOutCalls
	set areaId = idArea
	from RepOutCalls 
	left outer join ccriaareaworkgroup on (workgroupid = idwg)
	where idarea is not null 
	and [date] >= @from and [date] < @to

	delete RepOutCalls
	where areaId = 0
	and [date] >= @from and [date] < @to

	update RepOutCalls set
	area = (select areaname from ccriacat_areas where idarea = areaid)
	,workgroup = (select wgname from ccriacat_workgroup where idwg = workgroupid)
	,campaign = (select cam_descripcion from cccamps where cam_id = campaignid)
	,[user] = (select login from ccusers where user_id = userid)
	where [date] >= @from and [date] < @to					
		
	drop table #times
	drop table #sessionTime
	drop table #inboundData
	drop table #outboundData
	drop table #agentInformation
	drop table #ccGenOutCamp
	drop table #tempTime
	drop table #tempRepOutCalls	
	
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallsByTelephone - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsByTelephone]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete RepOutCallsByTelephone with(rowlock)
		where date >= @from and date < @to

		insert into RepOutCallsByTelephone
		select timegroup as [date], cal_telefono as [telephone], cal_key as [callKey], cam_id as [campaignId], cam_descripcion as [campaign], 
		count(cal_telefono) as quantity
		, datepart(yyyy,timegroup) as [year]
		, datepart(mm,timegroup) as [month]
		, datepart(dd,timegroup) as [day]
		, datepart(hh,timegroup) as [hour]
		, datepart(mi,timegroup) as [minutes]
		from(select cal_telefono, convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) as timegroup, cal_key, a.cam_id, b.cam_descripcion
			 from ccocallsout a
			 left join cccamps b on (a.cam_id = b.cam_id) 
			 where cal_inicio >= @from 
			 and cal_inicio < @to) c
		group by cal_telefono, timegroup, cal_key, cam_id, cam_descripcion
		order by cal_telefono, count(cal_telefono)
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallsDetail - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @IVA INT
SELECT @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25

if @action = 1
	begin		
		--Borrar lo que esta para no repetir
		delete from RepOutCallsDetail with(rowlock)
		where date >= @from AND date < @to

		INSERT INTO RepOutCallsDetail
		SELECT Call.cal_inicio as [date],
		cal_key as [callKey],
		Call.cal_telefono AS [telephone], 
		Call.cal_txfer + call.cal_tring AS [transfer], 
		Call.cal_tdialog AS [dialog], 
		ISNULL(Call.cal_tMoh,0) as [nque],
		Call.cal_tnotas AS [wrapup], 
		ISNULL( Tipo.[description], '''') AS [CallDisposition], 
		Call.cal_extension AS [extension],
		Usr.user_id as [userId],
		ISNULL(Usr.login,''systemTranslated_NoUserName'') [login], 
		ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username], 
		camps.cam_id as [campaignId],
		ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign], 
		(CEILING((cal_tXfer + cal_tRing + cal_tDialog +1) / 60.0 )* 60) AS [duration], 
		ISNULL(Call.costo,0.00) as [ncost], 
		@IVA as iva, 
		convert(decimal(10,2),ISNULL(Call.costo,0.00) * (1 + (@IVA / 100.00))) as total,
		case when prov.descrip is not null then prov.descrip when cstoProvedor.descrip is not null then cstoProvedor.descrip else ''systemTranslated_NoCarrier'' end as [ByCarrier],		
		ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [Calltypes], 
		case when Call.cal_manual = 0 then ''systemTranslated_Auto'' else ''systemTranslated_Manual'' end as [dialType], 
		case when cal_whoHung = 0 then ''systemTranslated_Client'' else ''systemTranslated_Agent'' end [whoHangUp], 
		case when call.califsub_id = 0 then ''systemTranslated_NoSubDisposition'' else isnull(sub.califSubDesc, '''') end as [subDisposition],
		sta.descripcion as [dialResult],
		Call.cal_id as [calId]
		, datepart(yyyy,Call.cal_inicio) AS [year]
		, datepart(mm,Call.cal_inicio) as [month]
		, datepart(dd,Call.cal_inicio) as [day]
		, datepart(hh,Call.cal_inicio) as [hour]
		, datepart(mi,Call.cal_inicio) as [minutes]
		,Call.cal_puerto
		FROM ccoCallsOut Call  
		LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id=Tipo.calif_id  
		INNER JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
		LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]  
		LEFT JOIN ccStatusLlamada sta on call.statuscall_id = sta.statuscall_id  
		LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]  
		LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = 1)  
		LEFT JOIN ccTipoCalifSubOut sub on call.califsub_id = sub.califsub_id 
		LEFT JOIN ccoDialers di on di.dialer_id = Call.cal_puerto
		LEFT JOIN cstoProvedor on di.provedor_id = cstoProvedor.provedor_id
		WHERE Call.cal_inicio >= @from
		AND Call.cal_inicio < @to
		and cal_manual in (0, 2) 
		order by date
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutDialDetail - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
		--Borrar lo que esta para no repetir
		delete from RepOutDialDetail with(rowlock)
		where date >= @from AND date < @to

		--Inserta información de reporte
		insert into RepOutDialDetail
		SELECT fecha,isnull(isnull(dials.cal_key,cs.cal_key),'''') cal_key, telefono, dials.tiporesdial_id, isnull(descripcion,'''') as resultado,
		dials.[cam_id],ISNULL(rtrim(ltrim(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') as campa, dials.tbusy as Msgtime, datepart(yyyy,fecha),
		datepart(mm,fecha), datepart(dd,fecha), datepart(hh,fecha), datepart(mi,fecha)
		FROM
			(select dial.logDial_id,dial.callout_id,dial.cam_id,dial.tipoResDial_id,dial.Telefono,dial.Puerto,dial.fecha,dial.tDialing,dial.tBusy,dial.answerbit,dial.canceledNoAgents,dial.cal_id,dial.disconnectCause, co.cal_key
			FROM ccoLogDials dial
			left join ccocallsout co on (dial.callout_id = co.callout_id and dial.Telefono=co.cal_telefono and 
			tiporesdial_id = 1 and convert(datetime,convert(varchar(19),co.cal_inicio,121),121) >= 
			convert(datetime,convert(varchar(19),dateadd(mi,-1,dial.fecha),121),121) and 
			convert(datetime,convert(varchar(19),co.cal_inicio,121),121) <= convert(datetime,convert(varchar(19),dateadd(mi,1,dial.fecha),121),121))
			WHERE fecha >= @from AND fecha < @to) dials     
		LEFT JOIN ccoCallsOutSource cs ON dials.callout_id = cs.callout_id LEFT JOIN cctipoResultadoDial tr
		ON dials.tiporesdial_id=tr.tiporesdial_id LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]    
		WHERE fecha >= @from AND fecha < @to
		order by fecha
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutDials - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDials]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
		declare @total decimal(10,2)
		
		select @total = count(*) from ccologdials as a 
		left join ccTipoResultadoDial as b on (a.tipoResDial_id = b.tipoResDial_id)
		where fecha >= @from and fecha < @to
		and descripcion is not null
		and cal_id is not null
		
		delete from RepOutDials with(rowlock)
		where date >= @from AND date < @to
		
		insert into RepOutDials
		select CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121) as [date],
		a.cam_id as campaignId, c.cam_descripcion as campaign, min(d.idwg) as workgroupId, min(wgname) as workgroup, min(f.idarea) as areaId, min(areaname) as area,
		a.tipoResDial_id, descripcion,
		descripcion + ''_Count'' as descripcion_count,
		count(*) as count,
		descripcion + ''_Avg'' as descripcion_avg,
		convert(decimal(10,2), (count(*)/@total)*100.00) as avg,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) AS [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [month],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [minutes]
		from ccologdials as a 
		left join ccTipoResultadoDial as b on (a.tipoResDial_id = b.tipoResDial_id)
		left join ccCamps as c on (a.cam_id = c.cam_id)
		left join ccRIAWorkGroup_Calid as d on (a.cal_id = d.cal_id)
		left join ccRIACat_WorkGroup as e on (d.idwg = e.idwg)
		left join ccRIAAreaWorkGroup as f on (e.idwg = f.idwg)
		left join ccRIACat_Areas as g on (f.idarea = g.idarea)
		where fecha >= @from and fecha < @to
		and descripcion is not null
		and a.cal_id is not null
		and d.tipo = 1
		and f.idarea is not null
		group by CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121), 
		a.cam_id, c.cam_descripcion, a.tipoResDial_id, descripcion  
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutDispositions - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepOutDispositions with(rowlock)
	where date >= @from AND date < @to

	insert into RepOutDispositions 
	select CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121) as dateHour, a.cam_id, '''' as Campaign, a.calif_id, '''' as DispName, '''', count(calif_id) DispAmount, user_id, '''' as login
	, '''' as username, b.IDArea, '''' as areaName, 1 as wgId, ''systemTranslated_WorkGroup'' as wg,
	datepart(yyyy,max(cal_inicio)) as year, datepart(mm,max(cal_inicio)), datepart(dd,max(cal_inicio)),
	datepart(hh,max(cal_inicio)), datepart(mi,max(cal_inicio))
	from ccocallsout a 		
	left join cccamps b
	on	b.cam_id = a.cam_id		
	where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13
	and b.idArea is not null
	group by CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121),a.cam_id, a.calif_id, user_id,b.IDArea

	update a set campaign = isnull(cam_descripcion,'''')
	from RepOutDispositions a
	left join cccamps b 
	on a.campaignId = b.cam_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,''systemTranslated_Dispositionless''), disposition_count = isnull(description,''systemTranslated_Dispositionless'') + ''_Count''
	from RepOutDispositions a
	left join cctipocalifout b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepOutDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepOutDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepOutDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to


end'
		
	EXEC(@Sql)

		set @process = 'ccspRepOutKPI - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete RepOutKPI with(rowlock)
	where date >= @from AND date < @to

	insert into RepOutKPI
	select dateHour, cam_id, '''' as campaign, totalCalls, avgXfer, avgCallTime, c10sec, c20sec, c30sec, cMax, AnsweredCalls, ISNULL((AnsweredCalls * 100.00)/NULLIF(totalCalls,0),0) as AnsweredPctg,
		ComplementCalls as RemainingCalls,  ISNULL((ComplementCalls * 100.00)/NULLIF(totalCalls,0),0) as RemainingPct, AbandonedCalls, ISNULL((AbandonedCalls * 100.00)/NULLIF(totalCalls,0),0) as AbandonedPctg, ISNULL((3600*1.00/NULLIF(totalCalls,0)),0) as AvgTimeBtwCalls, 
			[year], [month], [day],  [hour], [minutes] from (
			select CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) as dateHour,
			calls.cam_id, sum(isnull(total,0)) + sum(isnull(total2,0)) + sum(isnull(total3,0)) as totalCalls,avg(calls.cal_tXfer) as avgXfer, avg(calls.cal_tDialog) as avgCallTime,
			sum(isnull(c10,0)) as c10sec ,sum(isnull(c20,0)) as c20sec ,sum(isnull(c30,0)) as c30sec, sum(isnull(cMax,0)) as cMax,
			sum(isnull(total,0)) as AnsweredCalls, sum(isnull(total2,0)) as ComplementCalls, sum(isnull(total3,0)) as AbandonedCalls,
			datepart(yyyy,max(cal_inicio)) as [year], datepart(mm,max(cal_inicio)) as [month], datepart(dd,max(cal_inicio)) as [day],
			datepart(hh,max(cal_inicio)) as [hour], datepart(mi,max(cal_inicio)) as [minutes]
			from ccocallsout as calls with(nolock)
			left join (
					select count(cal_id) as total,cal_id,cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour,
					case when statusCall_id = 13 and cal_tDialog<=10 then 1 else 0 end C10,
					case when statusCall_id = 13 and cal_tDialog<=20 and cal_tDialog > 10 then 1 else 0 end C20,
					case when statusCall_id = 13 and cal_tDialog<=30 and cal_tDialog > 20 then 1 else 0 end C30,
					case when statusCall_id = 13 and cal_tDialog>30 then 1 else 0 end CMax
					 from ccocallsout with(nolock) where statusCall_id = 13 and cal_inicio >= @from and cal_inicio < @to group by statusCall_id,cal_tDialog,cal_id,cam_id,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 
			) as times 
			on (CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) = times.dateHour and calls.cal_id = times.cal_id ) 
			left join (
					select count(cal_id) as total2, cal_id,cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour
					 from ccocallsout with(nolock) where statusCall_id not in(13,5) and cal_inicio >= @from and cal_inicio < @to group by statusCall_id,cal_tDialog,cal_id,cam_id,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 
			) as times2 
			on (CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) = times2.dateHour and calls.cal_id = times2.cal_id )
			left join (
					select count(cal_id) as total3, cal_id,cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour
					 from ccocallsout with(nolock) where statusCall_id in(5) and cal_inicio >= @from and cal_inicio < @to group by statusCall_id,cal_tDialog,cal_id,cam_id,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 
			) as times3
			on (CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) = times2.dateHour and calls.cal_id = times2.cal_id )
			group by calls.cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 	
			) as tablon

			update a set campaign = isnull(b.cam_descripcion,'''')
			from RepOutKPI a
			left join ccCamps b
			on a.campaignId = b.cam_id
			where date >= @from AND date < @to
	
end'
		
	EXEC(@Sql)

		set @process = 'ccspRepOutSubDispositions - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutSubDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepOutSubDispositions with(rowlock)
	where date >= @from AND date < @to

	insert into RepOutSubDispositions 
	select CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121) as dateHour, a.cam_id, '''' as Campaign, isnull(a.califSub_id,0), '''' as DispName, '''', count(calif_id) DispAmount, user_id, '''' as login
	, '''' as username, b.IDArea, '''' as areaName, 1 as wgId, ''systemTranslated_WorkGroup'' as wg,
	datepart(yyyy,max(cal_inicio)) as year, datepart(mm,max(cal_inicio)), datepart(dd,max(cal_inicio)),
	datepart(hh,max(cal_inicio)), datepart(mi,max(cal_inicio))
	from ccocallsout a 		
	left join ccCamps b
	on	b.cam_Id = a.cam_id		
	where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13
	and b.IDArea is not null
	group by CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121),a.cam_id, a.califSub_id, user_id,b.IDArea

	update a set campaign = isnull(cam_descripcion,'''')
	from RepOutSubDispositions a
	left join ccCamps b 
	on a.campaignId = b.cam_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,''systemTranslated_Dispositionless''), subDisposition_count = isnull(califSubDesc,''systemTranslated_Dispositionless'') + ''_Count''
	from RepOutSubDispositions a
	left join cctipocalifsubout b 
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepOutSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepOutSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepOutSubDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepSpecialTimes - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepSpecialTimes]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		--Borrar lo que esta para no repetir
		delete from RepSpecialTimes with(rowlock)
		where date >= @from AND date < @to

		declare @NotReady varchar(max)
		select top 1 @NotReady = descripcion
		from ccTipoNotReady
		order by tiponotready_id

		select cam_id, inbound_id, [Espec/Camp], Periodo, 
		isnull([Tiempo Disponible],0) + isnull([Tiempo Dialogo],0) + isnull([Tiempo No Disponible],0) + isnull([Otro],0) as [Tiempo Sesion],
		isnull([Tiempo Disponible],0) as [Tiempo Disponible], 
		isnull([Tiempo Dialogo],0) as [Tiempo Dialogo], 
		isnull([Tiempo No Disponible],0) as [Tiempo No Disponible], 
		isnull([Otro],0) as [Otro]
		into #Report1
		from(
			select cam_id, 0 as inbound_id, ''Camp - '' + b.cam_descripcion as [Espec/Camp], 
				case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) 
					 else convert(varchar(13), fecha,121) + '':30:00'' end as Periodo,
				case when tipostatusage_id = 3 then ''Tiempo Disponible'' when tipostatusage_id = 4 then ''Tiempo Dialogo'' 
					when tipostatusage_id = 2 then ''Tiempo No Disponible'' else ''Otro'' end as tDescripcion,
				sum(tstatus) as tstatus
			from ccLogAgentesDia a
			left outer join cccamps b on (cam_id = idcampesp and tipo = 1)
			where (idCampEsp is not null)
			and (tipo is not null)
			and tipo = 1
			and fecha between @from and @to
			group by cam_id, cam_descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end,
				case when tipostatusage_id = 3 then ''Tiempo Disponible'' when tipostatusage_id = 4 then ''Tiempo Dialogo'' when tipostatusage_id = 2 then ''Tiempo No Disponible'' else ''Otro'' end 
			union
			select 0 as cam_id, inbound_id, ''ACD - '' + b.descripcion as [Espec/Camp], 
				case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) 
					else convert(varchar(13), fecha,121) + '':30:00'' end as Periodo, 
				case when tipostatusage_id = 3 then ''Tiempo Disponible'' when tipostatusage_id = 4 then ''Tiempo Dialogo'' 
					when tipostatusage_id = 2 then ''Tiempo No Disponible'' else ''Otro'' end as tDescripcion,
				sum(tstatus) as tstatus
			from ccLogAgentesDia a
			left outer join ccinbound b on (inbound_id = idcampesp and tipo = 0)
			where (idCampEsp is not null)
			and (tipo is not null)
			and tipo = 0
			and fecha between @from and @to
			group by inbound_id, descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end,
				case when tipostatusage_id = 3 then ''Tiempo Disponible'' when tipostatusage_id = 4 then ''Tiempo Dialogo'' when tipostatusage_id = 2 then ''Tiempo No Disponible'' else ''Otro'' end 
		) times
		pivot (max(tstatus) for [tdescripcion] in ([Tiempo Disponible], [Tiempo Dialogo], [Tiempo No Disponible], [Otro])) as pvtTimes
		where [Espec/Camp] is not null
		order by [Espec/Camp], Periodo

		select * into #notready from(
		select ''Camp - '' + cam_descripcion as [Espec/Camp],  
			case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) 
					else convert(varchar(13), fecha,121) + '':30:00'' end as Periodo,
			c.descripcion as [descriptionT], sum(tstatus) as T, c.descripcion as [descriptionN], count(*) as N
		from ccLogAgentesNotReady a
		left outer join cccamps b on (idcampesp = cam_id and tipo = 1)
		left outer join ccTipoNotReady c on (a.tiponotready_id = c.tiponotready_id)
		where (idCampEsp is not null)
		and (tipo is not null)
		and tipo = 1
		and fecha between @from and @to
		group by cam_descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end, c.descripcion
		union
		select ''ACD - '' + b.descripcion as [Espec/Camp], 
			case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) 
					else convert(varchar(13), fecha,121) + '':30:00'' end as Periodo,
			c.descripcion as [descriptionT], sum(tstatus) as T, c.descripcion as [descriptionN], count(*) as N
		from ccLogAgentesNotReady a
		left outer join ccinbound b on (idcampesp = inbound_id and tipo = 0)
		left outer join ccTipoNotReady c on (a.tiponotready_id = c.tiponotready_id)
		where (idCampEsp is not null)
		and (tipo is not null)
		and tipo = 0
		and fecha between @from and @to
		group by b.descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end, c.descripcion
		) as tmp
		where [Espec/Camp] is not null

		insert into RepSpecialTimes
		select a.Periodo as [date], a.cam_id as [campaignId], a.inbound_id as [inboundId], a.[Espec/Camp] as [campACDDescription], 
		[Tiempo Sesion] as [sessionTime], 
		[Tiempo Disponible]  as [readyTime], 
		[Tiempo Dialogo] as [dialogTime], 
		[Tiempo No Disponible] as [notReadyTime], 
		[Otro] as [other], 
		descriptionN as [descripcion],
		descriptionN + ''_Count'' as [descripcion_count], 
		[N] as [count],
		b.descriptionT + ''_Time'' as [descripcion_time], 
		[T] as [time],
		[T] as [timeSeconds]
		, datepart(yyyy,a.Periodo) as [year]
		, datepart(mm,a.Periodo) as [month]
		, datepart(dd,a.Periodo) as [day]
		, datepart(hh,a.Periodo) as [hour]
		, datepart(mi,a.Periodo) as [minutes]
		from #Report1 a
		left outer join #notready b on (a.[Espec/Camp] = b.[Espec/Camp] and a.Periodo = b.Periodo)
		where b.Periodo is not null
		union
		select a.Periodo, a.cam_id, a.inbound_id, a.[Espec/Camp], 
		[Tiempo Sesion] as [Tiempo Sesion], 
		[Tiempo Disponible] as [Tiempo Disponible], 
		[Tiempo Dialogo] as [Tiempo Dialogo], 
		[Tiempo No Disponible] as [Tiempo No Disponible], 
		[Otro] as [Otro], 
		@NotReady,
		@NotReady + ''_Count'', 0,
		@NotReady + ''_Time'', ''0'', 0
		, datepart(yyyy,a.Periodo) as [year]
		, datepart(mm,a.Periodo) as [month]
		, datepart(dd,a.Periodo) as [day]
		, datepart(hh,a.Periodo) as [hour]
		, datepart(mi,a.Periodo) as [minutes]
		from #Report1 a
		left outer join #notready b on (a.[Espec/Camp] = b.[Espec/Camp] and a.Periodo = b.Periodo)
		where b.Periodo is null
		order by a.[Espec/Camp], a.Periodo

		drop table #Report1
		drop table #notready
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepTrunkBusy - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepTrunkBusy]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
	
		create table #RtnValue(cal_id int,
		[user_id] int,
		fecha datetime,
		puerto int,
		cam_id int,
		tbusy int,
		contador int,
		tipo int,
		fechafin datetime,
		fechaInicio datetime,
		fechaFinal datetime)

		create nonclustered index ix_RtnValue on #RtnValue(
		[fecha] DESC,
		[fechafin] DESC
		)

		create nonclustered index ix_RtnValue2 on #RtnValue(
		[fechaInicio] DESC,
		[fechafinal] DESC
		)

		create table #RtnValue2(cal_id int,
		[user_id] int,
		fecha datetime,
		puerto int,
		cam_id int,
		tbusy int,
		contador int,
		tipo int,
		fechafin datetime,
		fechaInicio datetime,
		fechaFinal datetime)

		create nonclustered index ix_RtnValue on #RtnValue2(
		[fecha] DESC,
		[fechafin] DESC
		)

		insert into #RtnValue
			select dials.cal_id, calls.user_id, dials.fecha, dials.Puerto, dials.cam_id,
			sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)) as tBusy,1 as contador, 1 as tipo,
			dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha) as fechafin,
			case when datepart(mi,dials.fecha) between 0 and 14 then convert(varchar(13),dials.fecha,121) + '':00:00.000''
			when datepart(mi,dials.fecha) between 15 and 29 then convert(varchar(13),dials.fecha,121) + '':15:00.000''
			when datepart(mi,dials.fecha) between 30 and 44 then convert(varchar(13),dials.fecha,121) + '':30:00.000''
			when datepart(mi,dials.fecha) between 45 and 59 then convert(varchar(13),dials.fecha,121) + '':45:00.000'' end as fechaInicio,
			case when datepart(mi,dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha)) 
				between 0 and 14 then convert(varchar(13),dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha),121) + '':15:00.000''
			when datepart(mi,dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha)) 
				between 15 and 29 then convert(varchar(13),dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha),121) + '':30:00.000''
			when datepart(mi,dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha)) 
				between 30 and 44 then convert(varchar(13),dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha),121) + '':45:00.000''
			when datepart(mi,dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha)) 
				between 45 and 59 then convert(varchar(13),dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha),121) + '':00:00.000'' end as fechaFinal
			from ccologdials as dials left join ccocallsout as calls 
			on (dials.Puerto = calls.cal_puerto and dials.cal_id = calls.cal_id ) 
			where dials.fecha >= @from and dials.fecha < getdate()
			group by dials.cal_id, calls.user_id, dials.fecha, dials.Puerto, dials.cam_id 
		union all
			select incall.cal_id,incall.user_id,incall.cal_inicio as fecha,incall.cal_puerto as puerto, incall.inbound_id as cam_id, 
			sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)) as tBusy,1 as contador, 0 as tipo,
			dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio) as fechafin,
			case when datepart(mi,incall.cal_inicio) between 0 and 14 then convert(varchar(13),incall.cal_inicio,121) + '':00:00.000''
			when datepart(mi,incall.cal_inicio) between 15 and 29 then convert(varchar(13),incall.cal_inicio,121) + '':15:00.000''
			when datepart(mi,incall.cal_inicio) between 30 and 44 then convert(varchar(13),incall.cal_inicio,121) + '':30:00.000''
			when datepart(mi,incall.cal_inicio) between 45 and 59 then convert(varchar(13),incall.cal_inicio,121) + '':45:00.000'' end as fechaInicio,
			case when datepart(mi,dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio)) 
				between 0 and 14 then convert(varchar(13),dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio),121) + '':15:00.000''
			when datepart(mi,dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio)) 
				between 15 and 29 then convert(varchar(13),dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio),121) + '':30:00.000''
			when datepart(mi,dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio)) 
				between 30 and 44 then convert(varchar(13),dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio),121) + '':45:00.000''
			when datepart(mi,dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio)) 
				between 45 and 59 then dateadd(hh,1,(convert(varchar(13),dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio),121) + '':00:00.000'')) end
			from cccallsin as incall 
			where cal_inicio >= @from and cal_inicio < getdate()
			group by incall.cal_id, incall.user_id, incall.cal_inicio, incall.cal_puerto, incall.inbound_id  

		delete #RtnValue
		where tbusy = 0

		declare @starttime datetime
		declare @number int
		set @starttime = @from
		select @number = 0

		CREATE TABLE #times(
		[ID] INT primary key,
		[Start] DATETIME,
		[Stop] DATETIME
		)

		create nonclustered index ix_times on #times(
		[Start] DESC,
		[Stop] DESC
		)
		create nonclustered index ix_times2 on #times(
		[Start] DESC
		)

		while @number <= (datediff(mi,@starttime,getdate())/15)
		begin
			insert into #times
			SELECT [Hour] = @number,
			StartTime = DATEADD(mi, @number*15, @starttime),
			EndTime = DATEADD(mi, (@number+1)*15, @StartTime)

			set @number = @number +1
		end

		insert into #RtnValue2
		select *
		from #RtnValue
		where datediff(mi,fechainicio,fechafinal) > 15

		delete #RtnValue
		where datediff(mi,fechainicio,fechafinal) > 15

		insert into #RtnValue
		select cal_id, [user_id], th.start as fecha, t.Puerto, t.cam_id, 
			case when th.start < t.fecha then datediff(ss,fecha,th.stop) 
			when th.start > t.fecha and th.stop < t.fechafin then datediff(ss,th.start, th.stop) 
			else datediff(ss,th.start,fechafin) end as tBusy, 
		t.contador as llamadas, tipo, th.stop, th.start, th.stop
		from #RtnValue2 t
		join #times th on (t.fecha > th.Start and t.fecha < th.stop) OR th.Start between t.fecha and t.fechafin

		drop table #times
		drop table #RtnValue2

		select fecha as timegroup, puerto as port,cam_id,sum(tBusy) as tbusy,sum(contador) as llamadas,tipo
		into #ccGenOutPortStats
		from #RtnValue
		group by fecha, puerto, cam_id, tipo

		drop table #RtnValue
		
		delete from RepInTrunkBusy with(rowlock)
		where date >= @from AND date < @to

		insert into RepInTrunkBusy
			select timegroup, #ccGenOutPortStats.cam_id, [in].descripcion, port, tbusy, llamadas,
			datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year],
			datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month],
			datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day],
			datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour],
			datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
			from #ccGenOutPortStats
			inner join ccInbound [in] on ([in].inbound_id = #ccGenOutPortStats.cam_id and #ccGenOutPortStats.tipo = 0)
			where timegroup >= @from and timegroup < @to
			
		delete from RepOutTrunkBusy with(rowlock)
		where date >= @from AND date < @to

		insert into RepOutTrunkBusy
			select timegroup, #ccGenOutPortStats.cam_id, [out].cam_descripcion, port, tbusy, llamadas,
			datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year],
			datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month],
			datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day],
			datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour],
			datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
			from #ccGenOutPortStats
			inner join cccamps [out] on ([out].cam_id = #ccGenOutPortStats.cam_id and #ccGenOutPortStats.tipo = 1)
			where timegroup >= @from and timegroup < @to
		
		delete from RepTrunkBusy with(rowlock)
		where date >= @from AND date < @to

		insert into RepTrunkBusy
			select timegroup, port, tbusy, llamadas,
			datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year],
			datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month],
			datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day],
			datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour],
			datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
			from #ccGenOutPortStats
			where timegroup >= @from and timegroup < @to
				
		drop table #ccGenOutPortStats 
	end'
		
	EXEC(@Sql)
				
	
	set @process = 'alter - ReportsMasterProcess'
	set @Sql = '
	   ALTER procedure [dbo].[ReportsMasterProcess] as

declare @dateStart datetime
declare @delay int
declare @strDelay nvarchar(8)
declare @reportName nvarchar(100)
declare @numOfReports int

set nocount on

set @dateStart = getdate()
set @delay = 0
set @reportName = ''''
set @numOfReports = 0

create table #reports ([name] nvarchar(100), flag bit)

declare @avrsIntegration int
set @avrsIntegration = (select valor from ccSettings where setting_id = 29) 

insert into #reports
select [name], 0 as flag
from msdb.dbo.sysjobs
where ([name] like ''ccsp%'' and [name] not like ''ccspRepAVRS%'')
or ([name] like ''ccspRepAVRS%'' and @avrsIntegration = 1)
order by [name]

select @numOfReports = count(*)
from #reports with(nolock)

select @delay = cast(valor as int)
from ccsettings
where setting_id = 28

if (@delay < 1)
	set @delay = 1
else if (@delay > floor(cast(600 as decimal) / cast(@numOfReports as decimal)))
	set @delay = floor(cast(600 as decimal) / cast(@numOfReports as decimal))

set @strDelay = STUFF(STUFF(REPLICATE(''0'',6-LEN(@delay)) + convert(VARCHAR(6),@delay),3,0,'':''),6,0,'':'')

while(select count(*) from #reports with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @reportName = [name]
		from #reports with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @reportName

	update #reports with(rowlock)
	set flag = 1
	where [name] = @reportName

	waitfor delay @strDelay
end

drop table #reports
	'
	EXEC(@Sql)
	
	
------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
