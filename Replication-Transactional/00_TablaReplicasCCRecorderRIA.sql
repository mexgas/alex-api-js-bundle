use CCRecorderRIA;

if not exists(select * from sys.tables where name='publicationTableCCRecorderRIA') begin
	create table publicationTableCCRecorderRIA (id int identity, publicationName varchar(100),status bit)
end

if not exists(select * from sys.tables where name='articleTableCCRecorderRIA') begin
	create table  articleTableCCRecorderRIA (id int identity, articleName varchar(100),publicationId int,status bit)
end

if not exists(select * from sys.tables where name='subcripcionTableCCReportsRIA') begin
	create table subcripcionTableCCReportsRIA (id int identity, publicationName varchar(100),status bit)	
end
if not exists(select * from sys.tables where name='publicationTableCCenterRIA') begin
	create table publicationTableCCenterRIA (id int identity, publicationName varchar(100),status bit)	
end

truncate table publicationTableCCRecorderRIA
truncate table articleTableCCRecorderRIA
truncate table subcripcionTableCCReportsRIA
truncate table publicationTableCCenterRIA

declare @idInt int=1

insert into publicationTableCCRecorderRIA(publicationName,status) values(N'AVRSTemplatesRate',0)
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RIA_FORMACALIF',@idInt,0)
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RIA_RESULTADOSFORMA',@idInt,0)
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RIA_FORMACALIF_CHAT',@idInt,0)
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RIA_RESULTADOSFORMA_CHAT',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCRecorderRIA(publicationName,status) values(N'AVRSTemplates',0)	
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RIA_FORMATOS',@idInt,0)
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RIA_CONCEPTOS',@idInt,0)
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RIA_PREGUNTAS',@idInt,0)
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RIA_RESPUESTAS',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCRecorderRIA(publicationName,status) values(N'AVRSRecordings',0)	
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RIA_GRABACION',@idInt,0)

set @idInt=@idInt+1
insert into publicationTableCCRecorderRIA(publicationName,status) values(N'RecordEvaluation',0)
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RECORDERRIA_RECORDINGEVALUATION',@idInt,0)
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RECORDERRIA_CONCEPTQUESTIONS',@idInt,0)
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RECORDERRIA_EVALUATIONFORMATS',@idInt,0)
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RECORDERRIA_FORMATCONCEPTS',@idInt,0)
insert into articleTableCCRecorderRIA(articleName,publicationId,status) values(N'RECORDERRIA_ANSWERSOFQUESTIONSEVALUATION',@idInt,0)

print('----------------------------- subcripcionTableCCReportsRIA --------------')

insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'AVRSRecordings',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'AVRSTemplates',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'AVRSTemplatesRate',0)
insert into subcripcionTableCCReportsRIA(publicationName,status) values(N'RecordEvaluation',0)


print('----------------------------- publicationTableCCenterRIA --------------')

insert into publicationTableCCenterRIA(publicationName,status) values('AVRSCampEsp',0)
insert into publicationTableCCenterRIA(publicationName,status) values('AVRSGraphs',0)
insert into publicationTableCCenterRIA(publicationName,status) values('AVRSSettings',0)
insert into publicationTableCCenterRIA(publicationName,status) values('SpecialAVRS',0)
insert into publicationTableCCenterRIA(publicationName,status) values('WorkGroup_Calid',0)
insert into publicationTableCCenterRIA(publicationName,status) values('Chats',0)
insert into publicationTableCCenterRIA(publicationName,status) values('OutIn',0)
insert into publicationTableCCenterRIA(publicationName,status) values('ConversationMail',0)