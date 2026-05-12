USE [CCReportsRIA]
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepACDChats_date'AND object_id = OBJECT_ID('RepACDChats') ) BEGIN DROP INDEX IX_RepACDChats_date ON RepACDChats END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepAgentCallStatusesByInterval_date'AND object_id = OBJECT_ID('RepAgentCallStatusesByInterval') ) BEGIN DROP INDEX IX_RepAgentCallStatusesByInterval_date ON RepAgentCallStatusesByInterval END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepAgentGI_VersionOld_date'AND object_id = OBJECT_ID('RepAgentGI_VersionOld') ) BEGIN DROP INDEX IX_RepAgentGI_VersionOld_date ON RepAgentGI_VersionOld END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepAgentHSBCKPI_date'AND object_id = OBJECT_ID('RepAgentHSBCKPI') ) BEGIN DROP INDEX IX_RepAgentHSBCKPI_date ON RepAgentHSBCKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepAgentSummary_date'AND object_id = OBJECT_ID('RepAgentSummary') ) BEGIN DROP INDEX IX_RepAgentSummary_date ON RepAgentSummary END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepAnsweredCallsByDialingRetries_date'AND object_id = OBJECT_ID('RepAnsweredCallsByDialingRetries') ) BEGIN DROP INDEX IX_RepAnsweredCallsByDialingRetries_date ON RepAnsweredCallsByDialingRetries END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepAvgAnswerTimeChats_date'AND object_id = OBJECT_ID('RepAvgAnswerTimeChats') ) BEGIN DROP INDEX IX_RepAvgAnswerTimeChats_date ON RepAvgAnswerTimeChats END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepAVRSDisposition_date'AND object_id = OBJECT_ID('RepAVRSDisposition') ) BEGIN DROP INDEX IX_RepAVRSDisposition_date ON RepAVRSDisposition END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepCallTimeSummary_date'AND object_id = OBJECT_ID('RepCallTimeSummary') ) BEGIN DROP INDEX IX_RepCallTimeSummary_date ON RepCallTimeSummary END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepCallXfer_date'AND object_id = OBJECT_ID('RepCallXfer') ) BEGIN DROP INDEX IX_RepCallXfer_date ON RepCallXfer END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepChatsAndCallsGeneral_date'AND object_id = OBJECT_ID('RepChatsAndCallsGeneral') ) BEGIN DROP INDEX IX_RepChatsAndCallsGeneral_date ON RepChatsAndCallsGeneral END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepChatsDetail_date'AND object_id = OBJECT_ID('RepChatsDetail') ) BEGIN DROP INDEX IX_RepChatsDetail_date ON RepChatsDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepChatsEffectiveness_date'AND object_id = OBJECT_ID('RepChatsEffectiveness') ) BEGIN DROP INDEX IX_RepChatsEffectiveness_date ON RepChatsEffectiveness END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepChatsNotContacted_date'AND object_id = OBJECT_ID('RepChatsNotContacted') ) BEGIN DROP INDEX IX_RepChatsNotContacted_date ON RepChatsNotContacted END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepDetailAgent_date'AND object_id = OBJECT_ID('RepDetailAgent') ) BEGIN DROP INDEX IX_RepDetailAgent_date ON RepDetailAgent END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepDialingResultsDetail_date'AND object_id = OBJECT_ID('RepDialingResultsDetail') ) BEGIN DROP INDEX IX_RepDialingResultsDetail_date ON RepDialingResultsDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepEmailACD_date'AND object_id = OBJECT_ID('RepEmailACD') ) BEGIN DROP INDEX IX_RepEmailACD_date ON RepEmailACD END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepEmailAgente_date'AND object_id = OBJECT_ID('RepEmailAgente') ) BEGIN DROP INDEX IX_RepEmailAgente_date ON RepEmailAgente END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepEmailDetail_date'AND object_id = OBJECT_ID('RepEmailDetail') ) BEGIN DROP INDEX IX_RepEmailDetail_date ON RepEmailDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepEmailGeneral_date'AND object_id = OBJECT_ID('RepEmailGeneral') ) BEGIN DROP INDEX IX_RepEmailGeneral_date ON RepEmailGeneral END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInAbnd_date'AND object_id = OBJECT_ID('RepInAbnd') ) BEGIN DROP INDEX IX_RepInAbnd_date ON RepInAbnd END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInAnsw_date'AND object_id = OBJECT_ID('RepInAnsw') ) BEGIN DROP INDEX IX_RepInAnsw_date ON RepInAnsw END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInBill01900_date'AND object_id = OBJECT_ID('RepInBill01900') ) BEGIN DROP INDEX IX_RepInBill01900_date ON RepInBill01900 END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInboundKPI_date'AND object_id = OBJECT_ID('RepInboundKPI') ) BEGIN DROP INDEX IX_RepInboundKPI_date ON RepInboundKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInCalls_date'AND object_id = OBJECT_ID('RepInCalls') ) BEGIN DROP INDEX IX_RepInCalls_date ON RepInCalls END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInCallsDetail_date'AND object_id = OBJECT_ID('RepInCallsDetail') ) BEGIN DROP INDEX IX_RepInCallsDetail_date ON RepInCallsDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInChangeFlow_date'AND object_id = OBJECT_ID('RepInChangeFlow') ) BEGIN DROP INDEX IX_RepInChangeFlow_date ON RepInChangeFlow END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInDIDResume_date'AND object_id = OBJECT_ID('RepInDIDResume') ) BEGIN DROP INDEX IX_RepInDIDResume_date ON RepInDIDResume END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInDispositions_date'AND object_id = OBJECT_ID('RepInDispositions') ) BEGIN DROP INDEX IX_RepInDispositions_date ON RepInDispositions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInEffectiveness_date'AND object_id = OBJECT_ID('RepInEffectiveness') ) BEGIN DROP INDEX IX_RepInEffectiveness_date ON RepInEffectiveness END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInNotTransferred_date'AND object_id = OBJECT_ID('RepInNotTransferred') ) BEGIN DROP INDEX IX_RepInNotTransferred_date ON RepInNotTransferred END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInRejectedCalls_date'AND object_id = OBJECT_ID('RepInRejectedCalls') ) BEGIN DROP INDEX IX_RepInRejectedCalls_date ON RepInRejectedCalls END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInSubDispositions_date'AND object_id = OBJECT_ID('RepInSubDispositions') ) BEGIN DROP INDEX IX_RepInSubDispositions_date ON RepInSubDispositions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepInTrunkBusy_date'AND object_id = OBJECT_ID('RepInTrunkBusy') ) BEGIN DROP INDEX IX_RepInTrunkBusy_date ON RepInTrunkBusy END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepIVRByOptions_date'AND object_id = OBJECT_ID('RepIVRByOptions') ) BEGIN DROP INDEX IX_RepIVRByOptions_date ON RepIVRByOptions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepIVRDetail_date'AND object_id = OBJECT_ID('RepIVRDetail') ) BEGIN DROP INDEX IX_RepIVRDetail_date ON RepIVRDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepIVRFirstOption_date'AND object_id = OBJECT_ID('RepIVRFirstOption') ) BEGIN DROP INDEX IX_RepIVRFirstOption_date ON RepIVRFirstOption END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepIVRGeneral_date'AND object_id = OBJECT_ID('RepIVRGeneral') ) BEGIN DROP INDEX IX_RepIVRGeneral_date ON RepIVRGeneral END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutAnswCalls_date'AND object_id = OBJECT_ID('RepOutAnswCalls') ) BEGIN DROP INDEX IX_RepOutAnswCalls_date ON RepOutAnswCalls END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutboundKPI_date'AND object_id = OBJECT_ID('RepOutboundKPI') ) BEGIN DROP INDEX IX_RepOutboundKPI_date ON RepOutboundKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutCallBacks_date'AND object_id = OBJECT_ID('RepOutCallBacks') ) BEGIN DROP INDEX IX_RepOutCallBacks_date ON RepOutCallBacks END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutCalls_date'AND object_id = OBJECT_ID('RepOutCalls') ) BEGIN DROP INDEX IX_RepOutCalls_date ON RepOutCalls END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutCallsByTelephone_date'AND object_id = OBJECT_ID('RepOutCallsByTelephone') ) BEGIN DROP INDEX IX_RepOutCallsByTelephone_date ON RepOutCallsByTelephone END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutCallsDetail_date'AND object_id = OBJECT_ID('RepOutCallsDetail') ) BEGIN DROP INDEX IX_RepOutCallsDetail_date ON RepOutCallsDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutCallsOnChatDetail_date'AND object_id = OBJECT_ID('RepOutCallsOnChatDetail') ) BEGIN DROP INDEX IX_RepOutCallsOnChatDetail_date ON RepOutCallsOnChatDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutDialDetail_date'AND object_id = OBJECT_ID('RepOutDialDetail') ) BEGIN DROP INDEX IX_RepOutDialDetail_date ON RepOutDialDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutDials_date'AND object_id = OBJECT_ID('RepOutDials') ) BEGIN DROP INDEX IX_RepOutDials_date ON RepOutDials END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutDispositions_date'AND object_id = OBJECT_ID('RepOutDispositions') ) BEGIN DROP INDEX IX_RepOutDispositions_date ON RepOutDispositions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutKPI_date'AND object_id = OBJECT_ID('RepOutKPI') ) BEGIN DROP INDEX IX_RepOutKPI_date ON RepOutKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutSubDispositions_date'AND object_id = OBJECT_ID('RepOutSubDispositions') ) BEGIN DROP INDEX IX_RepOutSubDispositions_date ON RepOutSubDispositions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepOutTrunkBusy_date'AND object_id = OBJECT_ID('RepOutTrunkBusy') ) BEGIN DROP INDEX IX_RepOutTrunkBusy_date ON RepOutTrunkBusy END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepSpececialAbnd_date'AND object_id = OBJECT_ID('RepSpececialAbnd') ) BEGIN DROP INDEX IX_RepSpececialAbnd_date ON RepSpececialAbnd END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepSpececialAgent_date'AND object_id = OBJECT_ID('RepSpececialAgent') ) BEGIN DROP INDEX IX_RepSpececialAgent_date ON RepSpececialAgent END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepSpececialAgtPerformance_date'AND object_id = OBJECT_ID('RepSpececialAgtPerformance') ) BEGIN DROP INDEX IX_RepSpececialAgtPerformance_date ON RepSpececialAgtPerformance END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepSpececialCamMovs_date'AND object_id = OBJECT_ID('RepSpececialCamMovs') ) BEGIN DROP INDEX IX_RepSpececialCamMovs_date ON RepSpececialCamMovs END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepSpececialPromises_date'AND object_id = OBJECT_ID('RepSpececialPromises') ) BEGIN DROP INDEX IX_RepSpececialPromises_date ON RepSpececialPromises END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepSpecialCallKeyHistory_date'AND object_id = OBJECT_ID('RepSpecialCallKeyHistory') ) BEGIN DROP INDEX IX_RepSpecialCallKeyHistory_date ON RepSpecialCallKeyHistory END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepSpecialTimes_date'AND object_id = OBJECT_ID('RepSpecialTimes') ) BEGIN DROP INDEX IX_RepSpecialTimes_date ON RepSpecialTimes END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RepTrunkBusy_date'AND object_id = OBJECT_ID('RepTrunkBusy') ) BEGIN DROP INDEX IX_RepTrunkBusy_date ON RepTrunkBusy END


IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_RepOutDialDetail'
    AND object_id = OBJECT_ID('RepOutDialDetail')
)
BEGIN
    DROP INDEX IX_RepOutDialDetail ON RepOutDialDetail;
END



IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_RepOutDialDetail_date'
    AND object_id = OBJECT_ID('RepOutDialDetail')
)
BEGIN
    DROP INDEX IX_RepOutDialDetail_date ON RepOutDialDetail;
END
