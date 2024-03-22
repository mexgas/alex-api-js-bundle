CREATE PROCEDURE [dbo].[ccSpCreateIndexReport]  
AS
BEGIN
    SET NOCOUNT ON;
    if not exists (select * from sys.indexes where name = N'MSmerge_index_ccoLogDials' and object_id = OBJECT_ID(N'ccoLogDials')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccoLogDials'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoLogDials] on [dbo].[ccoLogDials](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccLogAgentesDia' and object_id = OBJECT_ID(N'ccLogAgentesDia')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccLogAgentesDia'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccLogAgentesDia] on [dbo].[ccLogAgentesDia](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_RiaMarkHold' and object_id = OBJECT_ID(N'RiaMarkHold')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'RiaMarkHold'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RiaMarkHold] on [dbo].[RiaMarkHold](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccoCallsOutSource' and object_id = OBJECT_ID(N'ccoCallsOutSource')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccoCallsOutSource'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallsOutSource] on [dbo].[ccoCallsOutSource](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccoCallsPreviewData' and object_id = OBJECT_ID(N'ccoCallsPreviewData')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccoCallsPreviewData'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallsPreviewData] on [dbo].[ccoCallsPreviewData](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_RegProcessPreviewRecord' and object_id = OBJECT_ID(N'RegProcessPreviewRecord')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'RegProcessPreviewRecord'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RegProcessPreviewRecord] on [dbo].[RegProcessPreviewRecord](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccoCallsOut' and object_id = OBJECT_ID(N'ccoCallsOut')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccoCallsOut'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallsOut] on [dbo].[ccoCallsOut](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccCallsIn' and object_id = OBJECT_ID(N'ccCallsIn')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccCallsIn'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCallsIn] on [dbo].[ccCallsIn](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_DataCallIn' and object_id = OBJECT_ID(N'DataCallIn')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'DataCallIn'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_DataCallIn] on [dbo].[DataCallIn](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cctipocalifsubout' and object_id = OBJECT_ID(N'cctipocalifsubout')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cctipocalifsubout'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalifsubout] on [dbo].[cctipocalifsubout](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cctipocalifsub' and object_id = OBJECT_ID(N'cctipocalifsub')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cctipocalifsub'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalifsub] on [dbo].[cctipocalifsub](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cctiposubcalifrel' and object_id = OBJECT_ID(N'cctiposubcalifrel')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cctiposubcalifrel'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctiposubcalifrel] on [dbo].[cctiposubcalifrel](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccCampsMovs' and object_id = OBJECT_ID(N'ccCampsMovs')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccCampsMovs'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCampsMovs] on [dbo].[ccCampsMovs](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_telefonosConferencia' and object_id = OBJECT_ID(N'telefonosConferencia')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'telefonosConferencia'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_telefonosConferencia] on [dbo].[telefonosConferencia](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_telefonosTransferencia' and object_id = OBJECT_ID(N'telefonosTransferencia')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'telefonosTransferencia'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_telefonosTransferencia] on [dbo].[telefonosTransferencia](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_messageStatus' and object_id = OBJECT_ID(N'messageStatus')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'messageStatus'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageStatus] on [dbo].[messageStatus](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccriacat_areas' and object_id = OBJECT_ID(N'ccriacat_areas')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccriacat_areas'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriacat_areas] on [dbo].[ccriacat_areas](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccinboundagentes' and object_id = OBJECT_ID(N'ccinboundagentes')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccinboundagentes'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccinboundagentes] on [dbo].[ccinboundagentes](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccriaareaworkgroup' and object_id = OBJECT_ID(N'ccriaareaworkgroup')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccriaareaworkgroup'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriaareaworkgroup] on [dbo].[ccriaareaworkgroup](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccsupervisorcam' and object_id = OBJECT_ID(N'ccsupervisorcam')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccsupervisorcam'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccsupervisorcam] on [dbo].[ccsupervisorcam](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccCampsAgente' and object_id = OBJECT_ID(N'ccCampsAgente')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccCampsAgente'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCampsAgente] on [dbo].[ccCampsAgente](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cclogagentesnotready' and object_id = OBJECT_ID(N'cclogagentesnotready')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cclogagentesnotready'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cclogagentesnotready] on [dbo].[cclogagentesnotready](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccloglogin' and object_id = OBJECT_ID(N'ccloglogin')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccloglogin'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccloglogin] on [dbo].[ccloglogin](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cccallsreject' and object_id = OBJECT_ID(N'cccallsreject')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cccallsreject'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cccallsreject] on [dbo].[cccallsreject](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccLogtransfers' and object_id = OBJECT_ID(N'ccLogtransfers')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccLogtransfers'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccLogtransfers] on [dbo].[ccLogtransfers](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccChannelTransfer' and object_id = OBJECT_ID(N'ccChannelTransfer')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccChannelTransfer'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccChannelTransfer] on [dbo].[ccChannelTransfer](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ivrstructure' and object_id = OBJECT_ID(N'ivrstructure')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ivrstructure'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ivrstructure] on [dbo].[ivrstructure](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ivrcallsin' and object_id = OBJECT_ID(N'ivrcallsin')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ivrcallsin'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ivrcallsin] on [dbo].[ivrcallsin](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ivroptions' and object_id = OBJECT_ID(N'ivroptions')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ivroptions'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ivroptions] on [dbo].[ivroptions](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_Survey' and object_id = OBJECT_ID(N'Survey')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'Survey'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_Survey] on [dbo].[Survey](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_SurveyQuestion' and object_id = OBJECT_ID(N'SurveyQuestion')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'SurveyQuestion'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_SurveyQuestion] on [dbo].[SurveyQuestion](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_SurveyAnswer' and object_id = OBJECT_ID(N'SurveyAnswer')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'SurveyAnswer'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_SurveyAnswer] on [dbo].[SurveyAnswer](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_relationSurveyQuestion' and object_id = OBJECT_ID(N'relationSurveyQuestion')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'relationSurveyQuestion'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationSurveyQuestion] on [dbo].[relationSurveyQuestion](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_relationQuestionAnswer' and object_id = OBJECT_ID(N'relationQuestionAnswer')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'relationQuestionAnswer'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationQuestionAnswer] on [dbo].[relationQuestionAnswer](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cctipoResultadodial' and object_id = OBJECT_ID(N'cctipoResultadodial')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cctipoResultadodial'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipoResultadodial] on [dbo].[cctipoResultadodial](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cctiponotready' and object_id = OBJECT_ID(N'cctiponotready')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cctiponotready'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctiponotready] on [dbo].[cctiponotready](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccodialers' and object_id = OBJECT_ID(N'ccodialers')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccodialers'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccodialers] on [dbo].[ccodialers](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccdnis' and object_id = OBJECT_ID(N'ccdnis')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccdnis'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccdnis] on [dbo].[ccdnis](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccstatusllamada' and object_id = OBJECT_ID(N'ccstatusllamada')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccstatusllamada'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccstatusllamada] on [dbo].[ccstatusllamada](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cstoprovedor' and object_id = OBJECT_ID(N'cstoprovedor')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cstoprovedor'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cstoprovedor] on [dbo].[cstoprovedor](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cstotipollamada' and object_id = OBJECT_ID(N'cstotipollamada')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cstotipollamada'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cstotipollamada] on [dbo].[cstotipollamada](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cstotarifa' and object_id = OBJECT_ID(N'cstotarifa')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cstotarifa'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cstotarifa] on [dbo].[cstotarifa](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccRIARegistryLists' and object_id = OBJECT_ID(N'ccRIARegistryLists')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccRIARegistryLists'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIARegistryLists] on [dbo].[ccRIARegistryLists](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccCallCost_RIA' and object_id = OBJECT_ID(N'ccCallCost_RIA')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccCallCost_RIA'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCallCost_RIA] on [dbo].[ccCallCost_RIA](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccEstadosAni' and object_id = OBJECT_ID(N'ccEstadosAni')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccEstadosAni'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccEstadosAni] on [dbo].[ccEstadosAni](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccTypeProcessPreview' and object_id = OBJECT_ID(N'ccTypeProcessPreview')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccTypeProcessPreview'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccTypeProcessPreview] on [dbo].[ccTypeProcessPreview](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccLogAgentesDia_Dialog' and object_id = OBJECT_ID(N'ccLogAgentesDia_Dialog')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccLogAgentesDia_Dialog'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccLogAgentesDia_Dialog] on [dbo].[ccLogAgentesDia_Dialog](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccoCallbacks' and object_id = OBJECT_ID(N'ccoCallbacks')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccoCallbacks'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallbacks] on [dbo].[ccoCallbacks](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccRIACallBack_Queue' and object_id = OBJECT_ID(N'ccRIACallBack_Queue')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccRIACallBack_Queue'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACallBack_Queue] on [dbo].[ccRIACallBack_Queue](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccriachats' and object_id = OBJECT_ID(N'ccriachats')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccriachats'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriachats] on [dbo].[ccriachats](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccriachatstatus' and object_id = OBJECT_ID(N'ccriachatstatus')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccriachatstatus'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriachatstatus] on [dbo].[ccriachatstatus](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccinbound' and object_id = OBJECT_ID(N'ccinbound')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccinbound'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccinbound] on [dbo].[ccinbound](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cctipocalif' and object_id = OBJECT_ID(N'cctipocalif')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cctipocalif'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalif] on [dbo].[cctipocalif](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccUsers' and object_id = OBJECT_ID(N'ccUsers')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccUsers'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccUsers] on [dbo].[ccUsers](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccUsers_Consulta' and object_id = OBJECT_ID(N'ccUsers_Consulta')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccUsers_Consulta'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccUsers_Consulta] on [dbo].[ccUsers_Consulta](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cccamps' and object_id = OBJECT_ID(N'cccamps')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cccamps'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cccamps] on [dbo].[cccamps](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccriacat_workgroup' and object_id = OBJECT_ID(N'ccriacat_workgroup')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccriacat_workgroup'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriacat_workgroup] on [dbo].[ccriacat_workgroup](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccriaworkgroupusers' and object_id = OBJECT_ID(N'ccriaworkgroupusers')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccriaworkgroupusers'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriaworkgroupusers] on [dbo].[ccriaworkgroupusers](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_cctipocalifout' and object_id = OBJECT_ID(N'cctipocalifout')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'cctipocalifout'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalifout] on [dbo].[cctipocalifout](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccBaseXDB' and object_id = OBJECT_ID(N'ccBaseXDB')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccBaseXDB'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccBaseXDB] on [dbo].[ccBaseXDB](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccRIAWorkGroup_Calid' and object_id = OBJECT_ID(N'ccRIAWorkGroup_Calid')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccRIAWorkGroup_Calid'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAWorkGroup_Calid] on [dbo].[ccRIAWorkGroup_Calid](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccRIACampEspWG' and object_id = OBJECT_ID(N'ccRIACampEspWG')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccRIACampEspWG'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACampEspWG] on [dbo].[ccRIACampEspWG](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccCalifCamp' and object_id = OBJECT_ID(N'ccCalifCamp')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccCalifCamp'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCalifCamp] on [dbo].[ccCalifCamp](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccPosicion' and object_id = OBJECT_ID(N'ccPosicion')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccPosicion'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccPosicion] on [dbo].[ccPosicion](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccRIACampsGraph' and object_id = OBJECT_ID(N'ccRIACampsGraph')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccRIACampsGraph'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACampsGraph] on [dbo].[ccRIACampsGraph](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccRIAGraphics' and object_id = OBJECT_ID(N'ccRIAGraphics')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccRIAGraphics'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAGraphics] on [dbo].[ccRIAGraphics](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccRIAInboundGraph' and object_id = OBJECT_ID(N'ccRIAInboundGraph')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccRIAInboundGraph'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAInboundGraph] on [dbo].[ccRIAInboundGraph](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccRIACampEspWGConsulta' and object_id = OBJECT_ID(N'ccRIACampEspWGConsulta')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccRIACampEspWGConsulta'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACampEspWGConsulta] on [dbo].[ccRIACampEspWGConsulta](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccRIAWorkGroupUsersConsulta' and object_id = OBJECT_ID(N'ccRIAWorkGroupUsersConsulta')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccRIAWorkGroupUsersConsulta'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAWorkGroupUsersConsulta] on [dbo].[ccRIAWorkGroupUsersConsulta](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccSettings' and object_id = OBJECT_ID(N'ccSettings')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccSettings'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccSettings] on [dbo].[ccSettings](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccMenus' and object_id = OBJECT_ID(N'ccMenus')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccMenus'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccMenus] on [dbo].[ccMenus](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccMenuUser' and object_id = OBJECT_ID(N'ccMenuUser')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccMenuUser'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccMenuUser] on [dbo].[ccMenuUser](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_conversation' and object_id = OBJECT_ID(N'conversation')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'conversation'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_conversation] on [dbo].[conversation](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_message' and object_id = OBJECT_ID(N'message')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'message'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_message] on [dbo].[message](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_messageUnAssigned' and object_id = OBJECT_ID(N'messageUnAssigned')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'messageUnAssigned'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageUnAssigned] on [dbo].[messageUnAssigned](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_relationMessageDispositionTwit' and object_id = OBJECT_ID(N'relationMessageDispositionTwit')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'relationMessageDispositionTwit'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationMessageDispositionTwit] on [dbo].[relationMessageDispositionTwit](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_messageUnAssingedTwit' and object_id = OBJECT_ID(N'messageUnAssingedTwit')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'messageUnAssingedTwit'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageUnAssingedTwit] on [dbo].[messageUnAssingedTwit](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_messageOutTwitter' and object_id = OBJECT_ID(N'messageOutTwitter')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'messageOutTwitter'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageOutTwitter] on [dbo].[messageOutTwitter](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_conversationTwitter' and object_id = OBJECT_ID(N'conversationTwitter')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'conversationTwitter'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_conversationTwitter] on [dbo].[conversationTwitter](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_searchConversationTwitter' and object_id = OBJECT_ID(N'searchConversationTwitter')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'searchConversationTwitter'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_searchConversationTwitter] on [dbo].[searchConversationTwitter](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_messageInTwitter' and object_id = OBJECT_ID(N'messageInTwitter')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'messageInTwitter'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageInTwitter] on [dbo].[messageInTwitter](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccWhatsAppConversations' and object_id = OBJECT_ID(N'ccWhatsAppConversations')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccWhatsAppConversations'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWhatsAppConversations] on [dbo].[ccWhatsAppConversations](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccWhatsAppSpam' and object_id = OBJECT_ID(N'ccWhatsAppSpam')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccWhatsAppSpam'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWhatsAppSpam] on [dbo].[ccWhatsAppSpam](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccWAMessagesConversations' and object_id = OBJECT_ID(N'ccWAMessagesConversations')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccWAMessagesConversations'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWAMessagesConversations] on [dbo].[ccWAMessagesConversations](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_ccWhatsAppConversationsRelationship' and object_id = OBJECT_ID(N'ccWhatsAppConversationsRelationship')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'ccWhatsAppConversationsRelationship'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWhatsAppConversationsRelationship] on [dbo].[ccWhatsAppConversationsRelationship](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_contactMeanIn' and object_id = OBJECT_ID(N'contactMeanIn')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'contactMeanIn'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_contactMeanIn] on [dbo].[contactMeanIn](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_smsccoLogDial' and object_id = OBJECT_ID(N'smsccoLogDial')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'smsccoLogDial'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_smsccoLogDial] on [dbo].[smsccoLogDial](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_smsOutSource' and object_id = OBJECT_ID(N'smsOutSource')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'smsOutSource'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_smsOutSource] on [dbo].[smsOutSource](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N'MSmerge_index_smsoutSourceMessage' and object_id = OBJECT_ID(N'smsoutSourceMessage')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'smsoutSourceMessage'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_smsoutSourceMessage] on [dbo].[smsoutSourceMessage](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end


if not exists (select * from sys.indexes where name = N'MSmerge_index_RIA_GRABACION' and object_id = OBJECT_ID(N'RIA_GRABACION')) 
and exists (select * from sys.columns where name = N'rowguid' and Object_ID = Object_ID(N'RIA_GRABACION'))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RIA_GRABACION] on [dbo].[RIA_GRABACION](
    [rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
    
END

/****************************INDICES PARA REPORTES *******************************/

if not exists (select * from sys.indexes where name = N'IX_ccLogAgentesDia_4' and object_id = OBJECT_ID(N'ccLogAgentesDia'))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_4
ON [dbo].[ccLogAgentesDia] ([User_id],[fecha])
end

if not exists (select * from sys.indexes where name = N'IX_ccLogAgentesDia_6' and object_id = OBJECT_ID(N'ccLogAgentesDia'))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_6
ON [dbo].[ccLogAgentesDia] ([fecha])
INCLUDE ([User_id],[TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N'IX_ccLogAgentesNotReady_5' and object_id = OBJECT_ID(N'cclogagentesnotready'))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesNotReady_5
ON [dbo].[cclogagentesnotready] ([fecha])
INCLUDE ([User_id],[TipoNotReady_id],[tStatus])
end

    
if not exists (select * from sys.indexes where name = N'IX_ccLogLogin_6' and object_id = OBJECT_ID(N'ccloglogin'))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogLogin_6
ON [dbo].[ccloglogin] ([fecha])
INCLUDE ([User_id],[Extension],[TipoMov])
end

    
if not exists (select * from sys.indexes where name = N'IX_ccLogTransfers_3' and object_id = OBJECT_ID(N'ccLogtransfers'))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogTransfers_3
ON [dbo].[ccLogtransfers] ([fechaFin])
INCLUDE ([cal_id],[tipo],[modo],[destino],[tAntesXfer],[tDespuesXfer])
end

if not exists (select * from sys.indexes where name = N'IX_ccoCallsOut13' and object_id = OBJECT_ID(N'ccoCallsOut'))
begin
   CREATE NONCLUSTERED INDEX IX_ccoCallsOut13
ON [dbo].[ccoCallsOut] ([cal_Inicio])
INCLUDE ([cal_id],[cal_telefono],[cal_puerto],[cam_id],[User_id],[statusCall_id],[calif_id],[cal_tDialog],[cal_tNotas],[cal_tXfer],[cal_tRing],[cal_manual],[cal_tMoh],[cal_whoHung],[cal_twait])
end


if not exists (select * from sys.indexes where name = N'IX_ccoCallsOut_14' and object_id = OBJECT_ID(N'ccoCallsOut'))
begin
   CREATE NONCLUSTERED INDEX IX_ccoCallsOut_14
ON [dbo].[ccoCallsOut] ([cal_Inicio],[cal_manual])
INCLUDE ([cal_id],[callout_id],[cal_telefono],[cam_id],[User_id],[calif_id],[cal_tDialog],[cal_tNotas],[cal_tXfer],[cal_tRing],[califSub_id])
end 


    
if not exists (select * from sys.indexes where name = N'IX_RIA_GRABACION_10' and object_id = OBJECT_ID(N'RIA_GRABACION'))
begin
CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_10
ON [dbo].[RIA_GRABACION] ([tipo_llamada])
INCLUDE ([cal_id])
end

    
if not exists (select * from sys.indexes where name = N'IX_ccLogAgentesDia_Dialog' and object_id = OBJECT_ID(N'ccLogAgentesDia_Dialog'))
begin
CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_Dialog
ON [dbo].[ccLogAgentesDia_Dialog] ([fecha_Dialog])
INCLUDE ([User_id],[fecha_Calc_ms])
end


if not exists (select * from sys.indexes where name = N'IX_ccoCallsOutSource_1' and object_id = OBJECT_ID(N'ccoCallsOutSource'))
begin
CREATE NONCLUSTERED INDEX IX_ccoCallsOutSource_1
ON [dbo].[ccoCallsOutSource] ([cal_fechaDial],[Region])
end

if not exists (select * from sys.indexes where name = N'IX_ccoLogDials_6' and object_id = OBJECT_ID(N'ccoLogDials'))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_6
ON [dbo].[ccoLogDials] ([fecha])
INCLUDE ([cam_id],[tipoResDial_id],[Telefono],[cal_id],[disconnectCause],[answerbit],[tipoLlamada_id])
end

    
if not exists (select * from sys.indexes where name = N'IX_ccoLogDials_7' and object_id = OBJECT_ID(N'ccoLogDials'))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_7
ON [dbo].[ccoLogDials] ([cal_id])
INCLUDE ([tipoResDial_id])
end


if not exists (select * from sys.indexes where name = N'IX_ccoLogDials_8' and object_id = OBJECT_ID(N'ccoLogDials'))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_8
ON [dbo].[ccoLogDials] ([fecha],[cal_id])
INCLUDE ([tipoResDial_id])
end

if not exists (select * from sys.indexes where name = N'IX_ccCallsIn_7' and object_id = OBJECT_ID(N'ccCallsIn'))
begin
   CREATE NONCLUSTERED INDEX IX_ccCallsIn_7
ON [dbo].[ccCallsIn] ([Inbound_id],[cal_Inicio])
INCLUDE ([cal_id],[dni_id],[cal_ANI],[User_id],[statusCall_id],[calif_id],[cal_que],[cal_tDialog],[cal_tNotas],[cal_tWait],[cal_tXfer],[cal_tRing],[cal_Xfer],[cal_tMoh],[cal_whoHung],[califSub_id])

end

if not exists (select * from sys.indexes where name = N'IX_ccCallsIn_8' and object_id = OBJECT_ID(N'ccCallsIn'))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_8
ON [dbo].[ccCallsIn] ([IVR_id])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N'IX_ccCallsIn_9' and object_id = OBJECT_ID(N'ccCallsIn'))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_1
ON [dbo].[ccCallsIn] ([cal_Inicio])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N'IX_tmpSessionTimeGroup_1' and object_id = OBJECT_ID(N'tmpSessionTimeGroup'))
begin
CREATE NONCLUSTERED INDEX IX_tmpSessionTimeGroup_1
ON [dbo].[tmpSessionTimeGroup] ([user_id])
INCLUDE ([timegroup],[tlog])
end

   
if not exists (select * from sys.indexes where name = N'IX_tmpccLogAgentesDia_2' and object_id = OBJECT_ID(N'tmpccLogAgentesDia'))
begin
CREATE NONCLUSTERED INDEX IX_tmpccLogAgentesDia_2
ON [dbo].[tmpccLogAgentesDia] ([userId],[timeGroup])
INCLUDE ([TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N'IX_tmpTimesInboundData_1' and object_id = OBJECT_ID(N'tmpTimesInboundData'))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_1
ON [dbo].[tmpTimesInboundData] ([statusCall_id])
INCLUDE ([timegroup],[Inbound_id],[nabnd],[tque],[txfer],[tring])
end

    
if not exists (select * from sys.indexes where name = N'IX_tmpTimesInboundData_2' and object_id = OBJECT_ID(N'tmpTimesInboundData'))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_2
ON [dbo].[tmpTimesInboundData] ([cal_id])
INCLUDE ([Inbound_id],[User_id])
end


if not exists (select * from sys.indexes where name = N'IX_tmpTimesOutboundData_1' and object_id = OBJECT_ID(N'tmpTimesOutboundData'))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_1
ON [dbo].[tmpTimesOutboundData] ([timegroup],[cal_id])
INCLUDE ([User_id])
end
    
if not exists (select * from sys.indexes where name = N'IX_tmpTimesOutboundData_2' and object_id = OBJECT_ID(N'tmpTimesOutboundData'))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_2
ON [dbo].[tmpTimesOutboundData] ([cal_manual])
INCLUDE ([timegroup],[User_id],[nabnd_xfer],[nabnd_ring],[tdialog],[tnotes],[cal_id])
end


if not exists (select * from sys.indexes where name = N'IX_RepOutAnswAndXferCalls_1' and object_id = OBJECT_ID(N'RepOutAnswAndXferCalls'))
begin
   CREATE NONCLUSTERED INDEX IX_RepOutAnswAndXferCalls_1
ON [dbo].[RepOutAnswAndXferCalls] ([date])
end

if not exists (select * from sys.indexes where name = N'IX_RepMKTTiemposTotales_1' and object_id = OBJECT_ID(N'RepMKTTiemposTotales'))
begin
CREATE NONCLUSTERED INDEX IX_RepMKTTiemposTotales_1
ON [dbo].[RepMKTTiemposTotales] ([date])
end

if not exists (select * from sys.indexes where name = N'IX_RepOutDialDetail_3' and object_id = OBJECT_ID(N'RepOutDialDetail'))
begin
CREATE NONCLUSTERED INDEX IX_RepOutDialDetail_3
ON [dbo].[RepOutDialDetail] ([date])
INCLUDE ([callKey],[telephone],[dialResultId])
end

if not exists (select * from sys.indexes where name = N'IX_RepInSubDispositions_1' and object_id = OBJECT_ID(N'RepInSubDispositions'))
begin
CREATE NONCLUSTERED INDEX IX_RepInSubDispositions_1
ON [dbo].[RepInSubDispositions] ([date])
INCLUDE ([userId],[inboundId],[subDispositionId],[areaId])
end

if not exists (select * from sys.indexes where name = N'IX_RepInCallsDetail_2' and object_id = OBJECT_ID(N'RepInCallsDetail'))
begin
CREATE NONCLUSTERED INDEX IX_RepInCallsDetail_2
ON [dbo].[RepInCallsDetail] ([date])
INCLUDE ([callStatusId],[dispositionId],[userId],[queueTime])
end
    
if not exists (select * from sys.indexes where name = N'IX_RepAgentNotReadyDet_2' and object_id = OBJECT_ID(N'RepAgentNotReadyDet'))
begin
CREATE NONCLUSTERED INDEX IX_RepAgentNotReadyDet_2
ON [dbo].[RepAgentNotReadyDet] ([tiponotreadyId],[startDate])
INCLUDE ([userId],[status],[statusTime])
end

if not exists (select * from sys.indexes where name = N'IX_RepOutManagementBase_1' and object_id = OBJECT_ID(N'RepOutManagementBase'))
begin
CREATE NONCLUSTERED INDEX IX_RepOutManagementBase_1
ON [dbo].[RepOutManagementBase] ([date])
end
    
if not exists (select * from sys.indexes where name = N'IX_RepOutSubDispositions_1' and object_id = OBJECT_ID(N'RepOutSubDispositions'))
begin
CREATE NONCLUSTERED INDEX IX_RepOutSubDispositions_1
ON [dbo].[RepOutSubDispositions] ([date])
INCLUDE ([campaignId],[subDispositionId],[userId],[areaId])
end

    
if not exists (select * from sys.indexes where name = N'IX_RepAgentGI_1' and object_id = OBJECT_ID(N'RepAgentGI'))
begin
CREATE NONCLUSTERED INDEX IX_RepAgentGI_1
ON [dbo].[RepAgentGI] ([date])
INCLUDE ([userId],[user],[login],[tdialogin],[tnotesin],[tdialogout],[tnotesout],[tnotav],[tlog])
end