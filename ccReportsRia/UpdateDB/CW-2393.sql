/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Trejo
Date: 2018/03/20
Description:
**********************************************************************************************
CW-2393 - Etiquetas en Portugués
**********************************************************************************************
Database: ccReportsRia
Required version: 60


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =61
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try
		
		set @process = 'CW-2393 add translate media'
    	set @Sql= 'if not  exists(select * from TranslatedReports where id=8062)
	insert into TranslatedReports values(8062,''media'')

if not  exists(select * from TranslatedReports where id=8063)
	insert into TranslatedReports values(8063,''media'')

if not  exists(select * from TranslatedReports where id=8072)
	insert into TranslatedReports values(8072,''media'')

if not  exists(select * from TranslatedReports where id=8064)
	insert into TranslatedReports values(8064,''media'')'
		EXEC(@Sql)

		set @process = 'CW-2393 Alter SP ccspRepAVRSAgent'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSAgent]		
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN

	---Before insert delete first  table dbo.RepAVRSAgent 
	DELETE FROM dbo.RepAVRSAgent with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSAgent
	--By Agent		
	select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
		a.User_id,
		a.Login,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		f.total_forma AS scores, 
		f.total_forma AS scores, 
		f.total_forma AS scores,
		s.User_id,
		s.Login,
		(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
		f.id_formato,
		k.nombre,		
		f.id_grabacion,
		case f.tipo 
			when 1 then ''systemTranslated_Recording'' 
			when 2 then ''systemTranslated_Chat''
			when 3 then ''systemTranslated_Email''
			when 3 then ''systemTranslated_Twitter''
		end as Medio,		
		f.cam_id as CamId,
		f.tipo_llamada as TipoLlamada,	
		(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
			AS Cam,		 
		YEAR(f.fecha_calif) AS [year], 
		MONTH(f.fecha_calif) AS [month], 
		DAY(f.fecha_calif) AS [day], 
		CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
		CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
	from dbo.RIA_FORMACALIF f
	INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
	INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
	INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS 
								WHERE activo = 1 and tipo=1
								GROUP BY id_formato,nombre) as t 
								ON t.id_formato= f.id_formato
	INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
	left join cccamps AS e ON f.cam_id = e.cam_id
	left join ccinbound AS u ON f.cam_id = u.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
END'
		EXEC(@Sql)

		set @process = 'CW-2393 Alter SP ccspRepAVRSDetailChat'
    	set @Sql= 'ALTER PROCEDURE  [dbo].[ccspRepAVRSDetailChat]
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
	DELETE FROM dbo.RepAVRSDetailChat with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSDetailChat

		select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
		a.User_id,
		a.Login,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		t.id_formato,
		t.nombre,
		p.enunciado_pregunta,
		r.etiquetas,
		r.peso as avgDisposition,
		i.Inbound_id AS inboundId,
		i.descripcion AS inbound	
	from RIA_RESULTADOSFORMA_CHAT r
	INNER JOIN dbo.RIA_FORMACALIF_CHAT f ON f.id_forma = r.id_forma
	INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
	INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1 and tipo=2
								GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
	INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
	INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
	INNER JOIN ccinbound AS i ON c.inboundId = i.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
				
set nocount off
END'
		EXEC(@Sql)

		set @process = 'CW-2393 Alter SP ccspRepAVRSSupervisor'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSSupervisor]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()	

if @action = 1
BEGIN
---Before insert delete first  table dbo.RepAVRSSupervisor 
DELETE FROM dbo.RepAVRSSupervisor with(rowlock) 
where date >= @from AND date < @to

INSERT INTO dbo.RepAVRSSupervisor
--By Supervisor
select
	DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
	f.total_forma AS scores, 
	f.total_forma AS scores, 
	f.total_forma AS scores,
	s.User_id,
	s.Login,
	(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
	f.id_formato,
	k.nombre,		
	f.id_grabacion,
	case f.tipo 
		when 1 then ''systemTranslated_Recording'' 
		when 2 then ''systemTranslated_Chat''
		when 3 then ''systemTranslated_Email''
		when 3 then ''systemTranslated_Twitter''
	end as Medio,	
	f.cam_id as CamId,
	f.tipo_llamada as TipoLlamada,	
	(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
		AS Cam,		 
	YEAR(f.fecha_calif) AS [year], 
	MONTH(f.fecha_calif) AS [month], 
	DAY(f.fecha_calif) AS [day], 
	CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
	CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
from dbo.RIA_FORMACALIF f
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							FROM dbo.RIA_FORMATOS
							WHERE activo = 1
							GROUP BY id_formato,nombre) as t 
							ON t.id_formato= f.id_formato
INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
left join cccamps AS e ON f.cam_id = e.cam_id
left join ccinbound AS u ON f.cam_id = u.Inbound_id
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to

END'
		EXEC(@Sql)

		set @process = 'CW-2393 Alter SP ccspRepAVRSQuestion'
    	set @Sql= 'ALTER PROCEDURE  [dbo].[ccspRepAVRSQuestion]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on


if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1 BEGIN		
---Before insert delete first table dbo.RepAVRSQuestionDetail 
DELETE FROM dbo.RepAVRSQuestion with(rowlock)
where date >= @from AND date < @to

INSERT INTO dbo.RepAVRSQuestion

select
	DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
	s.User_id,
	s.Login,
	(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
	t.id_formato,
	t.nombre,
	c.id_concepto,
	c.con_descripcion,
	p.id_pregunta,
	p.enunciado_pregunta,
	r.peso as avgDisposition,
	r.peso as avgDisposition,
	r.peso as avgDisposition,
	f.id_grabacion,
	case f.tipo 
		when 1 then ''systemTranslated_Recording'' 
		when 2 then ''systemTranslated_Chat''
		when 3 then ''systemTranslated_Email''
		when 3 then ''systemTranslated_Twitter''
	end as Medio,		
	f.cam_id as CamId,
	(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
		AS Cam	
from RIA_RESULTADOSFORMA r
INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							FROM dbo.RIA_FORMATOS
							WHERE activo = 1 and tipo=1
							GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
left join cccamps AS e ON f.cam_id = e.cam_id
left join ccinbound AS u ON f.cam_id = u.Inbound_id
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
				
set nocount off
END'
		EXEC(@Sql)

		set @process = 'CW-2393 Alter SP ccspRepAVRSQuestionChat'
    	set @Sql= 'ALTER PROCEDURE  [dbo].[ccspRepAVRSQuestionChat]
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
	DELETE FROM dbo.RepAVRSQuestionChat with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSQuestionChat

		select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
		a.User_id,
		a.Login,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		t.id_formato,
		t.nombre,
		p.id_pregunta,
		p.enunciado_pregunta,
		r.peso as avgDisposition,
		r.peso as avgDisposition,
		r.peso as avgDisposition,
		i.Inbound_id AS inboundId,
		i.descripcion AS inbound	
	from RIA_RESULTADOSFORMA_CHAT r
	INNER JOIN dbo.RIA_FORMACALIF_CHAT f ON f.id_forma = r.id_forma
	INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
	INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1 and tipo=2
								GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
	INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
	INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
	INNER JOIN ccinbound AS i ON c.inboundId = i.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
					
set nocount off
END'
		EXEC(@Sql)

		set @process = 'CW-2393 Alter SP ccspRepAVRSQuestionDetail'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSQuestionDetail]
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
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
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
when 1 then ''systemTranslated_Recording'' 
when 2 then ''systemTranslated_Chat''
when 3 then ''systemTranslated_Email''
when 3 then ''systemTranslated_Twitter''
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
		EXEC(@Sql)

		set @process = 'CW-2393 Alter SP ccspRepAVRSRateDetail'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSRateDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN
---Before insert delete first  table dbo.RepAVRRateDetail 
DELETE FROM dbo.RepAVRSRateDetail with(rowlock)
where date >= @from AND date < @to

INSERT INTO dbo.RepAVRSRateDetail

select
	DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
	s.User_id,
	s.Login,
	(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
	f.id_grabacion,
	case f.tipo 
		when 1 then ''systemTranslated_Recording'' 
		when 2 then ''systemTranslated_Chat''
		when 3 then ''systemTranslated_Email''
		when 3 then ''systemTranslated_Twitter''
	end as Medio,	
	t.id_formato,
	t.nombre,
	c.con_descripcion,
	p.enunciado_pregunta,
	r.etiquetas,
	r.peso as avgDisposition,	
	r.peso as avgDisposition,	
	r.peso as avgDisposition,
	f.cam_id as CamId,
	f.tipo,
	(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
		AS Cam,
	r.id_forma,
	YEAR(f.fecha_calif) AS [year], 
	MONTH(f.fecha_calif) AS [month], 
	DAY(f.fecha_calif) AS [day], 
	CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
	CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]		
from RIA_RESULTADOSFORMA r
INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							FROM dbo.RIA_FORMATOS
							WHERE activo = 1 and tipo=1
							GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
left join cccamps AS e ON f.cam_id = e.cam_id
left join ccinbound AS u ON f.cam_id = u.Inbound_id
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to

END
			'
		EXEC(@Sql)

		set @process = 'CW-2393 Alter SP ccspRepAVRSSection'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSSection]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN
---Before insert delete first  table dbo.RepAVRSSection 
DELETE FROM dbo.RepAVRSSection with(rowlock)
where date >= @from AND date < @to

INSERT INTO dbo.RepAVRSSection
				
select
	DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
	s.User_id,
	s.Login,
	(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
	f.id_formato,
	t.nombre,
	c.id_concepto,
	c.con_descripcion,
	r.peso AS scores, 
	r.peso as avgDisposition,
	r.peso as avgDisposition,
	r.peso as avgDisposition,
	f.id_grabacion,
	case f.tipo 
		when 1 then ''systemTranslated_Recording'' 
		when 2 then ''systemTranslated_Chat''
		when 3 then ''systemTranslated_Email''
		when 3 then ''systemTranslated_Twitter''
	end as Medio,		
	f.cam_id as CamId,
	f.tipo_llamada as TipoLlamada,	
	(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
		AS Cam,
		f.id_forma,		 
	YEAR(f.fecha_calif) AS [year], 
	MONTH(f.fecha_calif) AS [month], 
	DAY(f.fecha_calif) AS [day], 
	CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
	CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]		
from RIA_RESULTADOSFORMA r
INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							FROM dbo.RIA_FORMATOS
							WHERE activo = 1 and tipo=1
							GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
left join cccamps AS e ON f.cam_id = e.cam_id
left join ccinbound AS u ON f.cam_id = u.Inbound_id
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to

END'
		EXEC(@Sql)

			

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