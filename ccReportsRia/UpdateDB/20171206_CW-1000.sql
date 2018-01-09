/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Victor Paramo 
Date: 2017/12/18
Description:
**********************************************************************************************
CW-1000 - The following changes are required to generate the Quality/Scoring Template/Dispositions Report.
**********************************************************************************************
Database: ccReportsRia
Required version: 44


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =45
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try


	set @process = 'CW-1000 -- DROP THE TABLE '
	set @Sql= '
if exists (select * from sys.tables where name = N''RepAVRSQuestionDetail'')
begin
DROP TABLE RepAVRSQuestionDetail 
end
'
	EXEC(@sql)

	set @process = 'CW-1000 -- CREATE TABLE '
	set @Sql= '
if not exists (select * from sys.tables where name = N''RepAVRSQuestionDetail'')
begin
CREATE TABLE RepAVRSQuestionDetail(
[date] [datetime] NOT NULL,
[userId] [int] NOT NULL,
[user] [varchar](50) NOT NULL,
[agentName] [varchar](50) NOT NULL,
[supervisorId][smallint] NOT NULL,
[supervisorUser] [varchar](50) NOT NULL,
[Supervisor] [varchar](50) NOT NULL,
[templateId][int] NOT NULL,
[Template] [varchar](50) NOT NULL,
[score] [int] NOT NULL,
[media] [varchar](50) NULL,
[year] [int] NULL,
[month] [int] NULL,
[day] [int] NULL,
[hour] [int] NULL,
[minutes] [int] NULL
) ON [PRIMARY]
end
'
	EXEC(@sql)

	set @process = 'CW-1000 -- update ReportsFiltersRange'
	set @Sql= '
if exists (select * from ReportsFiltersRange where id = 8071)
begin
update ReportsFiltersRange set filterName=''score'' where id=8071
end
'
	EXEC(@sql)
	
	set @process = 'CW-1000 -- update ReportsTotals'
	set @Sql= '
if exists (select * from ReportsTotals where id = 8071)
begin
update ReportsTotals set totalColumns=''special:score:ISNULL(SUM(score)/NULLIF(count(score)_ 0)_ 0)'' where id=8071
end
'
	EXEC(@sql)


	set @process = 'CW-1000 -- Delete from GroupByReports'
	set @Sql= '
if exists (select * from GroupByReports where id=8071)
begin
delete from GroupByReports where id=8071
end
'
	EXEC(@sql)

	set @process = 'CW-1000 -- Insert into TranslatedReports'
	set @Sql= '
if not exists (select * from TranslatedReports where id = 8071)
begin
insert into TranslatedReports (id, columns) values (8071,''media'') 
end
'
	EXEC(@sql)

	set @process = 'CW-1000 -- SP changed'
	set @Sql= '
ALTER PROCEDURE [dbo].[ccspRepAVRSQuestionDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on

declare @idioma as tinyint
select @idioma = valor from ccSettings where setting_id=23


if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
BEGIN		
---Before insert delete first table dbo.RepAVRSQuestionDetail 
DELETE FROM dbo.RepAVRSQuestionDetail with(rowlock)
where date >= @from AND date < @to;

WITH reportQaEvaluation (Fecha,agentId, LoginAgent, Agent,SupId,LoginSup,Supervisor,formatId,nameTemplate,score,Medio)
AS
(
select
f.fecha_calif Fecha,
a.User_id agentId,
a.Login as LoginAgent,  
(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) Agent, 
s.User_id as SupId,
s.Login as LoginSup,
(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
t.id_formato formatId,
t.nombre as nameTemplate,
SUM (r.peso) as score,
f.tipo as medio
		

from RIA_RESULTADOSFORMA r
INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
INNER JOIN dbo.ccUsers s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre
FROM dbo.RIA_FORMATOS
WHERE activo = 1 and tipo=1
GROUP BY id_formato,nombre) as t ON t.id_formato = f.id_formato
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to	
GROUP BY f.fecha_calif,a.User_id,
(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres),a.Login,(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres), s.Login, t.nombre,f.tipo,s.User_id,t.id_formato
)
insert into RepAVRSQuestionDetail
select Fecha,agentId, LoginAgent, Agent, SupId,LoginSup,Supervisor,formatId,nameTemplate,score,
(case Medio 
when ''1'' then ''systemTranslated_Recording'' 
when ''2'' then ''systemTranslated_Chat''
end) as Medio,	
		
YEAR(Fecha) AS [year], 
MONTH(Fecha) AS [month], 
DAY(Fecha) AS [day],
DATEPART(HOUR,Fecha) AS [hour], 
DATEPART(MINUTE,Fecha) AS [minute]
from reportQaEvaluation


set nocount off
END	
			
'
	EXEC(@sql)

	set @process = 'CW-1000 -- Execute Store Procedure'
	set @Sql= '
declare @dateStart datetime
select @dateStart =isnull(min(fecha_calif),getdate()) from RIA_FORMACALIF
exec ccspRepAVRSQuestionDetail 1,@dateStart
'
	EXEC(@sql)

	
	if @actualVersion  = @version - 1
		exec ccsp_getVersion 'BD', @version


	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off