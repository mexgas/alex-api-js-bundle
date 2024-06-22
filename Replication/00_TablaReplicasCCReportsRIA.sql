use CCReportsRIA;

if not exists(select * from sys.tables where name='publicationTableCCenterRIA') begin
	create table publicationTableCCenterRIA (id int identity, publicationName varchar(100),status bit)	
end

if not exists(select * from sys.tables where name='publicationTableCCRecorderRIA') begin
	create table publicationTableCCRecorderRIA (id int identity, publicationName varchar(100),status bit)	
end

truncate table publicationTableCCenterRIA
truncate table publicationTableCCRecorderRIA

insert into publicationTableCCenterRIA(publicationName,status) values(N'LogDials',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'LogAgentesDia',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'Hold',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'CallsOutSource',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'CallsPreviewData',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'RegProcessPreviewRecord',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'CallsOut',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'CallsIn',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'OutIn',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'Users',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'Activity',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'IVR',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'Catalogs',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'LogAgentesDia_Dialog',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'Callbacks',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'Chats',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'SpecialAVRS',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'ccRIAWorkGroup_Calid',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'MenuReportsRia',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'AVRSCampEsp',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'ConversationMail',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'AVRSGraphs',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'ConversationWhatsApp',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'ConversationWhatsAppOut',0)
insert into publicationTableCCenterRIA(publicationName,status) values(N'SMS',0)


print('---------------------------publicationTableCCRecorderRIA---------------------------')

insert into publicationTableCCRecorderRIA(publicationName,status) values(N'AVRSTemplatesRate',0)
insert into publicationTableCCRecorderRIA(publicationName,status) values(N'AVRSTemplates',0)	
insert into publicationTableCCRecorderRIA(publicationName,status) values(N'AVRSRecordings',0)
insert into publicationTableCCRecorderRIA(publicationName,status) values(N'RecordingEvaluation',0)
