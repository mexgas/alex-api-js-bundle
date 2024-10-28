use CCenterRIA;

if not exists(select * from sys.tables where name='publicationTableCCenterRIA') begin
	create table publicationTableCCenterRIA (id int identity, publicationName varchar(100),status bit)
end

if not exists(select * from sys.tables where name='articleTableCCenterRIA') begin
	create table  articleTableCCenterRIA (id int identity, articleName varchar(100),publicationId int,status bit)
end

if not exists(select * from sys.tables where name='subcripcionTableCCReportsRIA') begin
	create table subcripcionTableCCReportsRIA (id int identity, publicationName varchar(100),status bit)	
end
if not exists(select * from sys.tables where name='subcripcionTableCCRecorderRIA') begin
	create table subcripcionTableCCRecorderRIA (id int identity, publicationName varchar(100),status bit)	
end


truncate table publicationTableCCenterRIA
truncate table articleTableCCenterRIA
truncate table subcripcionTableCCReportsRIA
truncate table subcripcionTableCCRecorderRIA

declare @idInt int=1

insert into publicationTableCCenterRIA(publicationName,status) values(N'LogDials',0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccoLogDials',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccoLogDialsData',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'LogAgentesDia',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccLogAgentesDia',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'Hold',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'RiaMarkHold',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'CallsOutSource',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccoCallsOutSource',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'CallsPreviewData',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccoCallsPreviewData',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'RegProcessPreviewRecord',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'RegProcessPreviewRecord',@idInt,0)
	
set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'CallsOut',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccoCallsOut',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccoCallsOutData',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'CallsIn',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccCallsIn',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'DataCallIn',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'OutIn',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cctipocalifsubout',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cctipocalifsub',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cctiposubcalifrel',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccCampsMovs',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'telefonosConferencia',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'telefonosTransferencia',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'messageStatus',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'Users',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccriacat_areas',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccinboundagentes',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccriaareaworkgroup',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccsupervisorcam',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccCampsAgente',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'Activity',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cclogagentesnotready',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccloglogin',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cccallsreject',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccLogtransfers',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccChannelTransfer',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'IVR',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ivrstructure',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ivrcallsin',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ivroptions',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'Survey',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'SurveyQuestion',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'SurveyAnswer',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'relationSurveyQuestion',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'relationQuestionAnswer',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'Catalogs',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cctipoResultadodial',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cctiponotready',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccodialers',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccdnis',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccstatusllamada',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cstoprovedor',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cstotipollamada',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cstotarifa',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccRIARegistryLists',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccCallCost_RIA',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccEstadosAni',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccTypeProcessPreview',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccHorarios',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccInboundHorarios',@idInt,0)



set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'LogAgentesDia_Dialog',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccLogAgentesDia_Dialog',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'Callbacks',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccoCallbacks',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccRIACallBack_Queue',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'Chats',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccriachats',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccriachatstatus',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'SpecialAVRS',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccinbound',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cctipocalif',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccUsers',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccUsers_Consulta',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cccamps',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccriacat_workgroup',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccriaworkgroupusers',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'cctipocalifout',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccBaseXDB',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'ccRIAWorkGroup_Calid',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccRIAWorkGroup_Calid',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'AVRSCampEsp',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccRIACampEspWG',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccCalifCamp',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccPosicion',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'AVRSGraphs',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccRIACampsGraph',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccRIAGraphics',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccRIAInboundGraph',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccRIACampEspWGConsulta',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccRIAWorkGroupUsersConsulta',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'AVRSSettings',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccSettings',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'MenuReportsRia',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccMenus',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccMenuUser',@idInt,0)
	
set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'ConversationMail',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'conversation',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'message',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'messageUnAssigned',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'ConversationWhatsApp',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccWhatsAppConversations',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccWhatsAppSpam',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccWAMessagesConversations',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccWhatsAppConversationsRelationship',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'contactMeanIn',@idInt,0)	

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'ConversationWhatsAppOut',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccWhatsAppConversationsOut',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccWAMessagesConversationsOut',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccWhatsAppConversationsRelationshipOut',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'contactMeanOut',@idInt,0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccWhatsAppGlobalIds',@idInt,0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccWhatsAppGlobalIdsRelationship',@idInt,0)	


set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'SMS',0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'smsccoLogDial',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'smsOutSource',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'smsoutSourceMessage',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'SmsRemesasMuñozDay',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccSmsSegments',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'AuxiliarReady',0)	
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'TipoReadyAuxiliar',@idInt,0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccLogAgentesAuxiliarReady',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCenterRIA(publicationName,status) values(N'SpecialDownload',0)
insert into articleTableCCenterRIA(articleName,publicationId,status) values(N'ccRecordingsDownload',@idInt,0)

print('----------------------------- subcripcionTableCCReportsRIA --------------')

insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'LogDials',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'LogAgentesDia',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'Hold',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'CallsOutSource',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'CallsPreviewData',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'RegProcessPreviewRecord',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'CallsOut',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'CallsIn',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'OutIn',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'Users',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'Activity',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'IVR',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'Catalogs',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'LogAgentesDia_Dialog',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'Callbacks',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'SpecialAVRS',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'ccRIAWorkGroup_Calid',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'MenuReportsRia',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'AVRSCampEsp',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'Chats',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'ConversationMail',0)

insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'AVRSGraphs',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'ConversationWhatsApp',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'ConversationWhatsAppOut',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'SMS',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'AuxiliarReady',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'SpecialDownload',0)
	-- insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'Conversationtweet',0)


print('----------------------------- subcripcionTableCCRecorderRIA --------------')

insert into  subcripcionTableCCRecorderRIA (publicationName,status) values(N'SpecialAVRS',0)
insert into  subcripcionTableCCRecorderRIA (publicationName,status) values(N'ccRIAWorkGroup_Calid',0)
insert into  subcripcionTableCCRecorderRIA (publicationName,status) values(N'AVRSCampEsp',0)
insert into  subcripcionTableCCRecorderRIA (publicationName,status) values(N'AVRSGraphs',0)
insert into  subcripcionTableCCRecorderRIA (publicationName,status) values(N'AVRSSettings',0)
insert into  subcripcionTableCCRecorderRIA (publicationName,status) values(N'OutIn',0)
insert into  subcripcionTableCCRecorderRIA (publicationName,status) values(N'Chats',0)
insert into  subcripcionTableCCRecorderRIA (publicationName,status) values(N'ConversationMail',0)
