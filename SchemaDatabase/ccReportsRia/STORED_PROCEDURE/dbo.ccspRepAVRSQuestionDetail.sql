CREATE PROCEDURE [dbo].[ccspRepAVRSQuestionDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on


if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
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
(a.apellidopaterno+' '+a.apellidomaterno+' '+a.nombres) Agent, 
s.User_id as SupId,
s.Login as LoginSup,
(s.apellidopaterno+' '+s.apellidomaterno+' '+s.nombres) AS Supervisor,
t.id_formato formatId,
t.nombre as nameTemplate,
SUM (r.peso) as score,
f.tipo as medio
		

from RIA_RESULTADOSFORMA r
INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre
FROM dbo.RIA_FORMATOS
WHERE activo = 1 and tipo=1
GROUP BY id_formato,nombre) as t ON t.id_formato = f.id_formato
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to	
GROUP BY f.fecha_calif,a.User_id,
(a.apellidopaterno+' '+a.apellidomaterno+' '+a.nombres),a.Login,(s.apellidopaterno+' '+s.apellidomaterno+' '+s.nombres), s.Login, t.nombre,f.tipo,s.User_id,t.id_formato
)
insert into RepAVRSQuestionDetail
select Fecha,agentId, LoginAgent, Agent, SupId,LoginSup,Supervisor,formatId,nameTemplate,score,
(case Medio 
when 1 then 'systemTranslated_Recording' 
when 2 then 'systemTranslated_Chat'
when 3 then 'systemTranslated_Email'
when 3 then 'systemTranslated_Twitter'
end) as Medio,	
		
YEAR(Fecha) AS [year], 
MONTH(Fecha) AS [month], 
DAY(Fecha) AS [day],
DATEPART(HOUR,Fecha) AS [hour], 
DATEPART(MINUTE,Fecha) AS [minute]
from reportQaEvaluation


set nocount off
END