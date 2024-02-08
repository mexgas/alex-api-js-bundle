USE [CCReportsRIA]
Go

if not exists (select * from sys.columns where name = N'active' and Object_ID = Object_ID(N'PublicationLowLoad'))
begin
    ALTER TABLE PublicationLowLoad ADD active bit NULL;
end

--update PublicationLowLoad set active=0


--drop  table ReportHighUse
if not exists (select * from sys.tables where name = N'ReportHighUse') begin
CREATE TABLE [dbo].[ReportHighUse](
	[nameSp] [varchar](256) not NULl primary key
) 
end
else begin
	truncate table ReportHighUse
end

--insert into ReportHighUse values('ccspRepAgentSession')
--insert into ReportHighUse values('ccspRepAgentNotReadyDet')
--insert into ReportHighUse values('ccspRepAgentNotReady')
--insert into ReportHighUse values('ccspRepAgentGI')

insert into ReportHighUse values('ccspRepAgentSessionByInterval')


insert into ReportHighUse values('ccspRepAgentKPI')
insert into ReportHighUse values('ccspRepAgentSummary')
insert into ReportHighUse values('ccspRepAnsweredCallsByDialingRetries')


insert into ReportHighUse values('ccspRepInAbnd')
insert into ReportHighUse values('ccspRepInAnsw')
insert into ReportHighUse values('ccspRepInBill01900')
insert into ReportHighUse values('ccspRepInboundKPI')
insert into ReportHighUse values('ccspRepInCalls')
insert into ReportHighUse values('ccspRepInCallsDetail')
insert into ReportHighUse values('ccspRepInChangeFlow')
insert into ReportHighUse values('ccspRepInDIDResume')
insert into ReportHighUse values('ccspRepInDispositions')
insert into ReportHighUse values('ccspRepInEffectiveness')
insert into ReportHighUse values('ccspRepInNotTransferred')
insert into ReportHighUse values('ccspRepInRejectedCalls')
insert into ReportHighUse values('ccspRepInSubDispositions')




insert into ReportHighUse values('ccspRepOutAnswAndXferCalls')
insert into ReportHighUse values('ccspRepOutAnswCalls')
insert into ReportHighUse values('ccspRepOutboundKPI')
insert into ReportHighUse values('ccspRepOutCallBacks')
insert into ReportHighUse values('ccspRepOutCallBilling')
insert into ReportHighUse values('ccspRepOutCalls')
insert into ReportHighUse values('ccspRepOutCallsByTelephone')
insert into ReportHighUse values('ccspRepOutCallsDetail')
insert into ReportHighUse values('ccspRepOutCallsOnChatDetail')
insert into ReportHighUse values('ccspRepOutDialDetail')
insert into ReportHighUse values('ccspRepOutDials')
insert into ReportHighUse values('ccspRepOutDispositions')
insert into ReportHighUse values('ccspRepOutDispositionsContacOwner')
insert into ReportHighUse values('ccspRepOutKPI')
--insert into ReportHighUse values('ccspRepOutManagementBase')
insert into ReportHighUse values('ccspRepOutSubDispositions')


--select * from ReportHighUse
--drop table ReportLowUse
--if not exists (select * from sys.tables where name = N'ReportLowUse') begin
--CREATE TABLE [dbo].[ReportLowUse](
--	[reportName] [varchar](256) not NULl primary key
--) 
--end


--insert into ReportLowUse values('ccspRepTrunkBusy') --Ocupacion de puertos

--insert into ReportLowUse values('ccspRepTwitterACD') 
--insert into ReportLowUse values('ccspRepTwitterAgente')
--insert into ReportLowUse values('ccspRepTwitterDetail')
--insert into ReportLowUse values('ccspRepTwitterGeneral')

--insert into ReportLowUse values('ccspRepWhatsAppByCampaignIn')
--insert into ReportLowUse values('ccspRepWhatsAppDetailConversationIn')

--insert into ReportLowUse values('ccspRepEmailACD')
--insert into ReportLowUse values('ccspRepEmailAgente')
--insert into ReportLowUse values('ccspRepEmailDetail')
--insert into ReportLowUse values('ccspRepEmailGeneral')



--insert into ReportLowUse values('ccspRepACDChats')
--insert into ReportLowUse values('ccspRepAVRSAgentChat')
--insert into ReportLowUse values('ccspRepAVRSDetailChat')


--insert into ReportLowUse values('ccspRepAgentCallStatusesByInterval')

--insert into ReportLowUse values('ccspRepAgentHSBCKPI')



--insert into ReportLowUse values('ccspRepAvgAnswerTimeChats')
--insert into ReportLowUse values('ccspRepAVRSAgent')

--insert into ReportLowUse values('ccspRepAVRSDisposition')
--insert into ReportLowUse values('ccspRepAVRSQuestion')
--insert into ReportLowUse values('ccspRepAVRSQuestionChat')
--insert into ReportLowUse values('ccspRepAVRSQuestionDetail')
--insert into ReportLowUse values('ccspRepAVRSRateChat')
--insert into ReportLowUse values('ccspRepAVRSRateDetail')
--insert into ReportLowUse values('ccspRepAVRSScores')
--insert into ReportLowUse values('ccspRepAVRSSection')
--insert into ReportLowUse values('ccspRepAVRSSupervisor')


--insert into ReportLowUse values('ccspRepCallbackQueue')
--insert into ReportLowUse values('ccspRepCallTimeSummary')
--insert into ReportLowUse values('ccspRepCallXfer')
--insert into ReportLowUse values('ccspRepChatsAndCallsGeneral')
--insert into ReportLowUse values('ccspRepChatsDetail')
--insert into ReportLowUse values('ccspRepChatsEffectiveness')
--insert into ReportLowUse values('ccspRepChatsNotContacted')
--insert into ReportLowUse values('ccspRepDetailAgent')
--insert into ReportLowUse values('ccspRepDialingResultsDetail')

--insert into ReportLowUse values('ccspRepMKTAgentes')
--insert into ReportLowUse values('ccspRepMKTDiarioTiemposTotales')
--insert into ReportLowUse values('ccspRepMKTIntervalos')
--insert into ReportLowUse values('ccspRepMKTIntervalosSalidas')
--insert into ReportLowUse values('ccspRepMKTIntervalosTiemposAcuTotales')
--insert into ReportLowUse values('ccspRepMKTTiemposTotales')


--insert into ReportLowUse values('ccspRepSpececialAbnd')
--insert into ReportLowUse values('ccspRepSpececialAbndPercentage')
--insert into ReportLowUse values('ccspRepSpececialAbndProfiles')
--insert into ReportLowUse values('ccspRepSpececialAbndTimes')
--insert into ReportLowUse values('ccspRepSpececialAgent')
--insert into ReportLowUse values('ccspRepSpececialAgtPerformance')
--insert into ReportLowUse values('ccspRepSpececialCamMovs')
--insert into ReportLowUse values('ccspRepSpececialPromises')
--insert into ReportLowUse values('ccspRepSpecialAbndCamp')
--insert into ReportLowUse values('ccspRepSpecialCallKeyHistory')
--insert into ReportLowUse values('ccspRepSpecialDialingResults')
--insert into ReportLowUse values('ccspRepSpecialTelephoneNumbersByRegistry')
--insert into ReportLowUse values('ccspRepSpecialTelephoneNumbersByState')
--insert into ReportLowUse values('ccspRepSpecialTimes')

--insert into ReportHighUse values('ccspRepIVRByOptions')
--insert into ReportHighUse values('ccspRepIVRDetail')
--insert into ReportHighUse values('ccspRepIVRFirstOption')
--insert into ReportHighUse values('ccspRepIVRGeneral')
--insert into ReportHighUse values('ccspRepIVRSurveys')