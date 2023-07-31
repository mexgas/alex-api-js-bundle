SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 120

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY


	set @process = 'update GroupByReports'
	set @Sql= 'update GroupByReports set columns = ''Template|Section|count(templateSectionId):Dispositions|avg(avgDisposition):avgDisposition'', groupByColumns = ''Template|Section'' where id = 8063'
	EXEC(@Sql)	

	
	set @process = 'Alter procedure ccspRepAVRSAgent'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSAgent]		
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if(DATEPART(hour, @from) = 3 and DATEPART(minute, @from) = 0)
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), @from))

if @action = 1
BEGIN

	---Before insert delete first  table dbo.RepAVRSAgent 
	DELETE FROM dbo.RepAVRSAgent with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSAgent
	--By Agent		
	select			-- Xion
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
			when 1 then case f.tipo_llamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end   
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
	INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
	left join cccamps AS e ON f.cam_id = e.cam_id
	left join ccinbound AS u ON f.cam_id = u.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	UNION
	select			-- Kolob
		DATEADD(dd, 0, DATEDIFF(dd, 0, RE.createAt)) AS fecha,
		g.age_id [User_id],
		a.Login,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		RE.totalPoints AS scores,
		RE.totalPoints AS scores,
		RE.totalPoints AS scores,
		u.User_id [User_id],
		RE.userAdmin [Login],
		RE.nameAdmin [Supervisor],
		RE.idFormat [id_formato],
		EF.nameFormat [nombre],
		RE.grab_id [id_grabacion],
		case g.tipo_grab_id		--Siempre es 1 -> trsp_AdmSaveScoresFormaCalif
			when 1 then case g.tipo_llamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end   
			when 2 then ''systemTranslated_Chat''
			when 3 then ''systemTranslated_Email''
			when 3 then ''systemTranslated_Twitter''
		end as Medio,		
		g.cam_id as CamId,
		g.tipo_llamada as TipoLlamada,
		(CASE WHEN g.tipo_llamada = 2 THEN c.cam_descripcion ELSE i.descripcion END) AS Cam,		 
		YEAR(RE.createAt) AS [year], 
		MONTH(RE.createAt) AS [month], 
		DAY(RE.createAt) AS [day], 
		DATEPART(hour, RE.createAt)  AS [hour], 
		DATEPART(minute, RE.createAt) AS [minute]
	from dbo.RECORDERRIA_RECORDINGEVALUATION RE
	inner join (
		select rg.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from RIA_GRABACION rg union
		select rgc.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from ria_grabacionconsulta rgc 
	)
	g on RE.grab_id = g.grab_id
	inner join RECORDERRIA_EVALUATIONFORMATS EF on RE.idFormat = EF.idFormat
	inner JOIN ccUserView a ON g.age_id = a.User_id and a.TipoUser_id = 1
	inner JOIN ccUserView u ON RE.userAdmin = u.Login and u.TipoUser_id > 1
	left join ccCamps AS c ON g.cam_id = c.cam_id
	left join ccInbound AS i ON g.cam_id = i.Inbound_id
	where RE.createAt >= @from and RE.createAt < @to
END

set nocount off'
	EXEC(@Sql)	
	
	
	set @process = 'Alter procedure ccspRepAVRSSupervisor'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSSupervisor]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()	

if(DATEPART(hour, @from) = 3 and DATEPART(minute, @from) = 0)
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), @from))

if @action = 1
BEGIN
---Before insert delete first  table dbo.RepAVRSSupervisor 
DELETE FROM dbo.RepAVRSSupervisor with(rowlock) 
where date >= @from AND date < @to

DECLARE @AVRSSupervisor TABLE( fecha			DATETIME NOT NULL
							 , userID			INT NOT NULL
							 , [user]			VARCHAR(50) NOT NULL  
							 , agent			VARCHAR(50) NOT NULL
							 , Dispositions     INT NOT NULL
							 , Dispositions2	INT NOT NULL
							 , avgDisposition   INT NOT NULL
							 , supervisorId     INT NOT NULL
							 , supervisorUser   VARCHAR(50) NOT NULL
							 , supervisor		VARCHAR(50) NOT NULL
							 , idFormato		INT NOT NULL
							 , Template			VARCHAR(50) NOT NULL
							 , idMedia			INT NOT NULL
							 , media			VARCHAR(50) NOT NULL
							 , cam_id			INT NOT NULL
							 , tipoLlamada		INT NOT NULL
							 , campaignAcd		VARCHAR(50) NOT NULL
							 , [year]			INT NOT NULL
							 , [month]			INT NOT NULL
							 , [day]			INT NOT NULL
							 , [hour]			INT NOT NULL
							 , [minute]			INT NOT NULL
);

INSERT INTO @AVRSSupervisor

	select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
		a.User_id AS userID,
		a.Login AS [user],
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		f.total_forma AS Dispositions, 
		f.total_forma AS Dispositions2, 
		f.total_forma AS avgDisposition,
		s.User_id AS supervisorId,
		s.Login AS supervisorUser,
		(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS supervisor,
		f.id_formato AS idFormato,
		k.nombre AS Template,		
		f.id_grabacion AS idMedia,
		case f.tipo 
			when 1 then case f.tipo_llamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end   
			when 2 then ''systemTranslated_Chat''
			when 3 then ''systemTranslated_Email''
			when 3 then ''systemTranslated_Twitter''
		end AS media,	
		f.cam_id AS cam_id,
		f.tipo_llamada AS tipoLlamada,	
		(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
			AS campaignAcd,		 
		YEAR(f.fecha_calif) AS [year], 
		MONTH(f.fecha_calif) AS [month], 
		DAY(f.fecha_calif) AS [day], 
		CAST(DATEPART(hour, f.fecha_calif) AS varchar(2)) AS [hour], 
		CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
	from dbo.RIA_FORMACALIF f
	INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
	INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
	INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1
								GROUP BY id_formato,nombre) AS t 
								ON t.id_formato= f.id_formato
	INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
	left join cccamps e ON f.cam_id = e.cam_id
	left join ccinbound u ON f.cam_id = u.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
UNION 
	select 
		DATEADD(dd, 0, DATEDIFF(dd, 0, re.createAt)) AS fecha,
		rg.age_id AS userID,
		cu.Login AS [user],
		(cu.apellidopaterno+'' ''+cu.apellidomaterno+'' ''+cu.nombres) AS agent,
		re.totalPoints AS Dispositions, 
		re.totalPoints AS Dispositions2, 
		re.totalPoints AS avgDisposition,
		cuu.User_id AS supervisorId,
		re.userAdmin AS supervisorUser,
		re.nameAdmin AS supervisor,
		re.idFormat AS idFormato,
		ref.nameFormat AS Template,
		re.grab_id AS idMedia,
		case rg.tipo_grab_id
			when 1 then case rg.tipo_llamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end   
			when 2 then ''systemTranslated_Chat''
			when 3 then ''systemTranslated_Email''
			when 3 then ''systemTranslated_Twitter''
		end as media,
		rg.cam_id AS cam_id,
		rg.tipo_llamada AS tipoLlamada,
		(CASE WHEN rg.tipo_llamada = 2 THEN cc.cam_descripcion ELSE ci.descripcion END) AS campaignAcd,
		YEAR(re.createAt) AS [year], 
		MONTH(re.createAt) AS [month], 
		DAY(re.createAt) AS [day], 
		CAST(DATEPART(hour, re.createAt) as varchar(2)) AS [hour], 
		CAST(DATEPART(minute, re.createAt) as varchar(2)) AS [minute]
	from RECORDERRIA_RECORDINGEVALUATION re
	left join (
		select r.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from RIA_GRABACION r union
		select rgc.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from ria_grabacionconsulta rgc 
	) rg ON re.grab_id = rg.grab_id
	INNER join ccUsers cu ON cu.User_id = rg.age_id
	INNER join ccUsers cuu ON cuu.Login = re.userAdmin
	INNER join RECORDERRIA_EVALUATIONFORMATS ref ON ref.idFormat = re.idFormat
	left join cccamps cc ON rg.cam_id = cc.cam_id
	left join ccinbound ci ON rg.cam_id = ci.Inbound_id
	WHERE re.createAt >= @from AND re.createAt < @to

	

INSERT INTO dbo.RepAVRSSupervisor
	select 
		fecha, 
		userID,		
		[user],
		agent,		
		Dispositions,
		Dispositions2,
		avgDisposition,  
		supervisorId,    
		supervisorUser,  
		supervisor,	
		idFormato,	
		Template,		
		idMedia,		
		media,		
		cam_id,		
		tipoLlamada,	
		campaignAcd,	
		[year],		
		[month],		
		[day],		
		[hour],		
		[minute]	
	from @AVRSSupervisor

END'
	EXEC(@Sql)	
	
	
	set @process = 'Alter procedure ccspRepAVRSSection'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSSection]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if(DATEPART(hour, @from) = 3 and DATEPART(minute, @from) = 0)
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), @from))

if @action = 1
BEGIN
DELETE FROM dbo.RepAVRSSection with(rowlock)
where date >= @from AND date <= @to

declare @FormatoConcepto table(
	id int not null,
	idConcept int not null,
	idFormat  int not null
);

insert into @FormatoConcepto
	select ROW_NUMBER()  OVER(ORDER BY fc.idFormat asc), idConcept, idFormat from RECORDERRIA_FORMATCONCEPTS fc

;with formato as(
SELECT id_formato,nombre,MAX(version)AS version FROM dbo.RIA_FORMATOS WHERE activo = 1 and tipo=1 GROUP BY id_formato,nombre),
		dataResume as(
			(select convert(date, f.fecha_calif) as [date],
				f.age_id as userId,
				a.Login as [user],
				(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agentName,
				f.id_calificador as supervisorId,
				s.Login as supervisorUser,
				(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
				f.id_formato as templateId
				,t.nombre as Template
				,c.id_concepto as sectionId
				,c.con_descripcion as Section
				,w.id as templateSectionId
				,(t.nombre + '' '' + c.con_descripcion)+'' ''+convert(varchar(10),w.id)  as templateSection
				,r.peso AS score
				,f.id_grabacion as idMedia
				,case f.tipo
					when 1 then case f.tipo_llamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end   
					when 2 then ''systemTranslated_Chat''
					when 3 then ''systemTranslated_Email''
					when 4 then ''systemTranslated_Twitter''
				end as media,
				f.cam_id as cam_id,
				f.tipo_llamada as tipoLlamada,
				(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END) AS campaignAcd
				,f.id_forma
				from RIA_RESULTADOSFORMA r
			INNER JOIN RIA_FORMACALIF f ON f.id_forma = r.id_forma
			INNER JOIN formato t ON t.id_formato= f.id_formato
			INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
			INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
			inner join RIA_FORMATOCONCEPTO w ON w.sectionId = c.id_concepto and w.templateId = c.id_formato
			INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
			INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
			left join cccamps AS e ON f.cam_id = e.cam_id and  f.tipo_llamada=2
			left join ccinbound AS u ON f.cam_id = u.Inbound_id and  f.tipo_llamada=1
			WHERE f.fecha_calif >= @from AND f.fecha_calif <= @to
		)
		UNION ALL

			(select 
				convert(date, re.createAt) as [date],
				rg.age_id as userId,
				cu.Login as [user],
				(cu.apellidopaterno+'' ''+cu.apellidomaterno+'' ''+cu.nombres) as agentName,
				cuu.User_id as supervisorId,
				re.userAdmin as supervisorUser,
				re.nameAdmin as Supervisor,
				re.idFormat as templateId,
				ref.nameFormat as Template,
				rfc.idConcept as sectionId,
				rfc.nameFormatConcept as section,
				fcc.id as templateSection,
				(ref.nameFormat + '' '' + rfc.nameFormatConcept)+'' ''+convert(varchar(10), rfc.idConcept) as templateSection, 
				re.totalPoints as score,
				re.grab_id as idMedia,
				case rg.tipo_grab_id
					when 1 then case rg.tipo_llamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end   
					when 2 then ''systemTranslated_Chat''
					when 3 then ''systemTranslated_Email''
					when 3 then ''systemTranslated_Twitter''
				end as media,
				rg.cam_id as cam_id,
				rg.tipo_llamada as tipoLlamada,
				(CASE WHEN rg.tipo_llamada = 2 THEN cc.cam_descripcion ELSE ci.descripcion END) as campaignAcd,
				re.idFormat as id_forma
			from RECORDERRIA_RECORDINGEVALUATION re
			INNER join (
				select r.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from RIA_GRABACION r union
				select rgc.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from ria_grabacionconsulta rgc 
			) rg ON re.grab_id = rg.grab_id
			INNER join ccUsers cu ON cu.User_id = rg.age_id
			INNER join ccUsers cuu ON cuu.Login = re.userAdmin
			INNER join RECORDERRIA_EVALUATIONFORMATS ref ON ref.idFormat = re.idFormat
			INNER join RECORDERRIA_FORMATCONCEPTS rfc ON rfc.idFormat = re.idFormat
			INNER join @FormatoConcepto fcc on fcc.idConcept = rfc.idConcept and fcc.idFormat = re.idFormat 
			left join cccamps cc ON rg.cam_id = cc.cam_id
			left join ccinbound ci ON rg.cam_id = ci.Inbound_id
			WHERE re.createAt >= @from AND re.createAt <= @to
			)
		
		)

INSERT INTO dbo.RepAVRSSection([date],userId,[user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section,templateSectionId,templateSection,avgDisposition,idMedia,media,cam_id,tipoLlamada,campaignAcd,idForma,year,month,day,hour,minutes,Dispositions)
		select [date],userId, [user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section,templateSectionId,templateSection
		,avg(score) score, idMedia,media,cam_id,tipoLlamada,campaignAcd,id_forma,
		YEAR([date]) AS [year],
		MONTH([date]) AS [month],
		DAY([date]) AS [day],
				0 AS [hour],
				0 AS [minute]
		,avg(score) score
		from dataResume
		group by  [date], userId,[user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section,templateSectionId,templateSection,
		idMedia,media,cam_id,tipoLlamada,campaignAcd,id_forma
END'
	EXEC(@Sql)	
	
	
	set @process = 'Alter procedure ccspRepAVRSQuestion'
	set @Sql= 'ALTER PROCEDURE  [dbo].[ccspRepAVRSQuestion]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
if @from is null
  select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
  select @to = getdate()

if(DATEPART(hour, @from) = 3 and DATEPART(minute, @from) = 0)
  SELECT @from = convert(DATETIME, convert(VARCHAR(11), @from))

if @action = 1 BEGIN


DELETE FROM dbo.RepAVRSQuestion with(rowlock)
where date >= @from AND date < @to
;with 
  dataResume as(
(select
convert(date, f.fecha_calif) as [date]
    ,f.age_id as userId
    ,a.Login as [user]
    ,(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agentName
    ,f.id_calificador as supervisorId
    ,s.Login as supervisorUser
    ,(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor
    ,f.id_formato as templateId
    ,q.nombre as Template
    ,c.id_concepto as sectionId
    ,c.con_descripcion as Section
    ,p.id_pregunta AS questionId
    ,p.enunciado_pregunta AS Question
    ,r.peso AS score
    ,f.id_grabacion as mediaId
    ,case f.tipo
        when 1 then case f.tipo_llamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end
        when 2 then ''systemTranslated_Chat''
        when 3 then ''systemTranslated_Email''
        when 3 then ''systemTranslated_Twitter''
    end as media
    ,f.cam_id as cam_id
    ,(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END) AS campaignAcd

from RIA_RESULTADOSFORMA r
  INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
  INNER JOIN RIA_FORMATOS q ON q.id_formato = f.id_formato
  INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
  INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
  INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
  INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
  left JOIN cccamps AS e ON f.cam_id = e.cam_id and  f.tipo_llamada=2
  left JOIN ccinbound AS u ON f.cam_id = u.Inbound_id and  f.tipo_llamada=1
  WHERE f.fecha_calif >= @from AND f.fecha_calif <= @to
  )
  UNION
  (
  select 
    convert(date, re.createAt) as [date],
    rg.age_id as UserId,
    cu.Login AS [user],
    (cu.apellidopaterno+'' ''+cu.apellidomaterno+'' ''+cu.nombres) AS agentName,
    cuu.User_id AS supervisorId,
    re.userAdmin AS supervisorUser,
    re.nameAdmin AS Supervisor,
    re.idFormat AS templateId,
    ref.nameFormat AS Template,
    rfc.idConcept as sectionId,
    rfc.nameFormatConcept as Section,
    raqv.idQuestion as questionId,
    rcq.title as question,
    raqv.points as score,
    re.grab_id AS mediaId,
    case rg.tipo_grab_id
      when 1 then case rg.tipo_llamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end    
      when 2 then ''systemTranslated_Chat''
      when 3 then ''systemTranslated_Email''
      when 3 then ''systemTranslated_Twitter''
    end as media,
    rg.cam_id AS cam_id,
    (CASE WHEN rg.tipo_llamada = 2 THEN cc.cam_descripcion ELSE ci.descripcion END) AS campaignAcd

  from RECORDERRIA_RECORDINGEVALUATION re
  inner join (
    select r.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from RIA_GRABACION r union
    select rgc.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from ria_grabacionconsulta rgc 
  ) rg ON re.grab_id = rg.grab_id
  inner join ccUsers cu ON cu.User_id = rg.age_id
  inner join ccUsers cuu ON cuu.Login = re.userAdmin
  inner join RECORDERRIA_EVALUATIONFORMATS ref ON ref.idFormat = re.idFormat
  inner join RECORDERRIA_FORMATCONCEPTS rfc ON rfc.idFormat = re.idFormat
  inner join RECORDERRIA_ANSWERSOFQUESTIONSEVALUATION raqv ON raqv.idRecordingEvaluation = re.idRecordingEvaluation
  inner join RECORDERRIA_CONCEPTQUESTIONS rcq ON rcq.idQuestion = raqv.IdQuestion
  left join cccamps cc ON rg.cam_id = cc.cam_id
  left join ccinbound ci ON rg.cam_id = ci.Inbound_id
  WHERE re.createAt >= @from AND re.createAt <= @to
  )
  )
  INSERT INTO dbo.RepAVRSQuestion ([date],userId,[user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section, questionId, Question, avgDisposition,mediaId,media,cam_id,campaignAcd,Dispositions)
  select [date],userId, [user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section, questionId, Question, avg(score) score, mediaId, media,cam_id,campaignAcd, avg(score) score
  from dataResume
  group by  [date], userId,[user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section, questionId, Question,
  mediaId,media,cam_id,campaignAcd
 
END'
	EXEC(@Sql)	
	
	
	set @process = 'Alter procedure ccspRepAVRSQuestionDetail'
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

WITH reportQaEvaluation (Fecha,agentId, LoginAgent, Agent,SupId,LoginSup,Supervisor,formatId,nameTemplate,score,Medio, tipoLlamada)
AS
(
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
	f.tipo as medio,
	ISNULL(f.tipo_llamada, 0) as tipoLlamada
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
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres),a.Login,(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres), s.Login, t.nombre,f.tipo,s.User_id,t.id_formato, f.tipo_llamada
	)	
	UNION
	(
	select 
	RE.createAt [Fecha],
	g.age_id [agentId],
	a.Login [LoginAgent],
	(a.apellidopaterno + '' '' + a.apellidomaterno + '' '' + a.nombres) AS Agent,
	u.User_id [SupId],
	RE.userAdmin [LoginSup],
	RE.nameAdmin [Supervisor],
	RE.idFormat [formatId],
	f.nameFormat [nameTemplate],
	RE.totalPoints [score],
	g.tipo_grab_id [medio],
	ISNULL(g.tipo_llamada, 0) as tipoLlamada
	from dbo.RECORDERRIA_RECORDINGEVALUATION RE
	inner join (
		select rg.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from RIA_GRABACION rg union
		select rgc.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from ria_grabacionconsulta rgc 
	)
	g on RE.grab_id = g.grab_id
	INNER JOIN RECORDERRIA_EVALUATIONFORMATS f on RE.idFormat = f.idFormat
	INNER JOIN ccUserView a ON g.age_id = a.User_id and a.TipoUser_id = 1
	INNER JOIN ccUserView u ON RE.userAdmin = u.Login and u.TipoUser_id > 1
	where RE.createAt >= @from and RE.createAt < @to
	)
)


insert into RepAVRSQuestionDetail
select Fecha,agentId, LoginAgent, Agent, SupId,LoginSup,Supervisor,formatId,nameTemplate,score,
(case Medio 
when 1 then case tipoLlamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end   
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

END	

set nocount off'
	EXEC(@Sql)	
	
	
	set @process = 'Alter procedure ccspRepAVRSRateDetail'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSRateDetail]

@action as tinyint,
@from as datetime,
@to as datetime
AS
SET ANSI_WARNINGS ON;

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN
--Before insert delete first  table dbo.RepAVRRateDetail 
DELETE FROM dbo.RepAVRSRateDetail with(rowlock)
where date >= @from AND date < @to

INSERT INTO dbo.RepAVRSRateDetail

select
	f.fecha_calif AS fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
	s.User_id,
	s.Login,
	(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
	f.id_grabacion,
	case f.tipo 
		when 1 then case f.tipo_llamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end
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
	DATEPART(hour, f.fecha_calif) AS [hour], 
	DATEPART(minute, f.fecha_calif) AS [minute]		
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
LEFT JOIN cccamps AS e ON f.cam_id = e.cam_id
LEFT JOIN ccinbound AS u ON f.cam_id = u.Inbound_id
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to

union

select 
	re.createAt as fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
	s.User_id,
	s.Login,
	(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
	g.grab_id as id_grabacion,
	case g.tipo_grab_id		--Siempre es 1 -> trsp_AdmSaveScoresFormaCalif
		when 1 then case rg.tipo_llamada when 1 then ''systemTranslated_in_single'' else ''systemTranslated_out_single'' end
		when 2 then ''systemTranslated_Chat''
		when 3 then ''systemTranslated_Email''
		when 3 then ''systemTranslated_Twitter''
	end as Medio,
	re.idFormat AS templateId,
	ref.nameFormat AS Template,
	rfc.nameFormatConcept as Section,
	rcq.title as question,
	CASE 
		WHEN raqv.answerType123 IS NOT NULL THEN raqv.answerType123.value(''(/rootNode/Answer/@title)[1]'', ''varchar(max)'')
		WHEN raqv.answerType4 IS NOT NULL THEN CAST(raqv.answerType4 AS varchar(max))
		WHEN raqv.answerType5 IS NOT NULL THEN raqv.answerType5
	ELSE ''''
	END AS etiquetas,
	raqv.points AS Dispositions, 
	raqv.points AS Dispositions2, 
	raqv.points AS avgDisposition,
	rg.cam_id AS cam_id,
	rg.tipo_llamada AS tipoLlamada,
	(CASE WHEN rg.tipo_llamada = 2 THEN cc.cam_descripcion ELSE ci.descripcion END) AS campaignAcd,
	ref.idFormat AS formaId,
	YEAR(re.createAt) AS [year], 
	MONTH(re.createAt) AS [month], 
	DAY(re.createAt) AS [day], 
	DATEPART(hour, re.createAt) AS [hour], 
	DATEPART(minute, re.createAt) AS [minute]
from RECORDERRIA_RECORDINGEVALUATION re
inner join (
		select rg.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from RIA_GRABACION rg union
		select rgc.grab_id, age_id, tipo_grab_id, cam_id, tipo_llamada from ria_grabacionconsulta rgc 
	)
g on RE.grab_id = g.grab_id
INNER JOIN RIA_GRABACION rg ON re.grab_id = rg.grab_id
INNER JOIN ccUserView a ON g.age_id = a.User_id
INNER JOIN ccUserView s ON RE.userAdmin = s.Login
LEFT JOIN cccamps cc ON rg.cam_id = cc.cam_id
LEFT JOIN ccinbound ci ON rg.cam_id = ci.Inbound_id
INNER JOIN RECORDERRIA_EVALUATIONFORMATS ref ON ref.idFormat = re.idFormat
INNER JOIN RECORDERRIA_FORMATCONCEPTS rfc ON rfc.idFormat = re.idFormat
INNER JOIN RECORDERRIA_ANSWERSOFQUESTIONSEVALUATION raqv ON raqv.idRecordingEvaluation = re.idRecordingEvaluation
INNER JOIN RECORDERRIA_CONCEPTQUESTIONS rcq ON rcq.idQuestion = raqv.IdQuestion
WHERE re.createAt >= @from AND re.createAt < @to
end'
	EXEC(@Sql)	
	
	set @process = 'KR085000 ccspRepInCallsDetail DROP SP'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepInCallsDetail'')
	begin
        DROP PROCEDURE ccspRepInCallsDetail;
    end
	'

	EXEC(@sql)

	set @process = 'KR085000 ccspRepInCallsDetail CREATE SP'
	set @sql = '
		CREATE PROCEDURE [dbo].[ccspRepInCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
		AS

		SET NOCOUNT ON

		IF @from IS NULL
			SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

		IF @to IS NULL
			SELECT @to = getdate()

		IF @action = 1
		BEGIN
			DECLARE @tab TABLE (callId INT PRIMARY KEY, [Dato1] VARCHAR(255), [Dato2] VARCHAR(255), [Dato3] VARCHAR(255), [Dato4] VARCHAR(255), [Dato5] VARCHAR(255))

			INSERT INTO @tab
			SELECT callId, [Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5]
			FROM (
				SELECT A.CallId, [Data], [Description]
				FROM DataCallIn A
				INNER JOIN ccCallsIn B ON A.CallId = B.cal_id
				WHERE b.cal_Inicio >= @from AND b.cal_Inicio < @to
				) AS SourceTable
			pivot(max([Data]) FOR [Description] IN ([Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5])) AS pvt

			--Borrar lo que esta para no repetir
			DELETE
			FROM RepInCallsDetail
			WHERE DATE >= @from AND DATE < @to

			INSERT INTO RepInCallsDetail (DATE, callid, inboundId, ACDGroup, callStatusId, callStatus, dispositionId, disposition, subDispositionId, subDisposition, dnisId, dnis, userId, [user], callKey, ANI, queueTime, xferTime, ringingTime, dialogTime, extension, agentName, whoHangUp, mohTime, year, month, day, hour, minutes, provedorId, provider, trunk, fileMoved, twrapup, AverageHandleTime, Dato1, Dato2, Dato3, Dato4, Dato5, grabId, nameDNI, numDNI, collectCall, timeTotalInCallSec, timeTotalInCallMin)
			SELECT cal_inicio, 
			   a.cal_id, 
			   a.Inbound_id,
			   ISNULL(ccIn.descripcion, '''') AS Inbound, 
			   a.statusCall_id, 
			   ISNULL(statusLlamada.descripcion, '''') AS statusCall, 
			   a.calif_id, 
			   ISNULL(disposition.description, '''') AS calif, 
			   ISNULL(a.califSub_id, 0), 
			   ISNULL(subDisposition.califSubDesc, '''') AS califSub, 
			   a.dni_id, 
			   ISNULL(dnis.dni_numero, '''') AS dni, 
			   a.user_id, 
			   ISNULL(LOGIN, '''') AS [user], 
			   ISNULL(a.cal_key, '''') as cal_key, 
			   cal_ANI, 
			   cal_tWait, 
			   cal_tXfer, 
			   cal_tRing, 
			   cal_tDialog, 
			   a.cal_extension, 
			   ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''') AS agentName,
			   CASE
				   WHEN a.cal_whoHung = 0
				   THEN ''systemTranslated_Client''
				   WHEN a.cal_whoHung = 1
				   THEN ''systemTranslated_Agent''
				   ELSE ''systemTranslated_AgentSurvey''
			   END [whoHangUp], 
			   a.cal_tMoh, 
			   DATEPART(yyyy, cal_inicio) [year], 
			   DATEPART(mm, cal_inicio) [month], 
			   DATEPART(dd, cal_inicio) [day], 
			   DATEPART(hh, cal_inicio) [hour], 
			   DATEPART(mi, cal_inicio) [minute], 
			   di.provedor_id, 
			   prov.descrip [Proveedor], 
			   a.cal_puerto,
			   CASE
				   WHEN a.file_moved = 1
				   THEN ''systemTranslated_Remoto''
				   ELSE ''Local''
			   END AS file_Moved, 
			   cal_tNotas, 
			   AverageHandleTime = cal_tNotas + cal_tDialog, 
			   ISNULL(tab.Dato1, '''') AS Dato1, 
			   ISNULL(tab.Dato2, '''') AS Dato2, 
			   ISNULL(tab.Dato3, '''') AS Dato3, 
			   ISNULL(tab.Dato4, '''') AS Dato4, 
			   ISNULL(tab.Dato5, '''') AS Dato5, 
			   ISNULL(rc.grab_id, 0) AS grabId,
			   ISNULL(dni_Descripcion, '''') AS nameDNI,
			   ISNULL(dnis.dni_numero, '''') AS dni,
			   CASE
					 WHEN statusLlamada.descripcion IS NOT NULL THEN ''Si''
					 ELSE ''No''
			   END AS collectCall,
			   ( CAST(cal_tDialog AS INT) + CAST(cal_tXfer AS INT) + CAST(cal_tWait AS INT) + CAST(cal_tRing AS INT)) AS timeTotalInCallSec,
			   (FLOOR( ( CAST(cal_tDialog AS INT) + CAST(cal_tXfer AS INT) + CAST(cal_tWait AS INT) + CAST(cal_tRing AS INT) )/ 60) + 
					CASE 
						WHEN CEILING(( CAST(cal_tDialog AS INT) + CAST(cal_tXfer AS INT) + CAST(cal_tWait AS INT) + CAST(cal_tRing AS INT) ) % 60) != 0 THEN 1 
						ELSE 0 
					END) AS timeTotalInCallMin
		FROM cccallsin a
			 LEFT JOIN ccoDialers di ON di.dialer_id = a.cal_puerto
			 LEFT JOIN cstoProvedor prov ON di.provedor_id = prov.provedor_id
			 LEFT JOIN @tab tab ON tab.callId = a.cal_id
			 LEFT JOIN Ria_grabacion rc ON rc.cal_id = a.cal_id and rc.tipo_llamada=1
			 LEFT JOIN ccInbound ccIn ON a.Inbound_id = ccIn.Inbound_id
			 LEFT JOIN ccstatusllamada statusLlamada ON a.statusCall_id = statusLlamada.statusCall_id
			 LEFT JOIN cctipocalif disposition ON a.calif_id = disposition.calif_id
			 LEFT JOIN cctipocalifsub subDisposition ON a.califSub_id = subDisposition.califSub_id
			 LEFT JOIN ccdnis dnis ON a.dni_id = dnis.dni_id
			 LEFT JOIN ccUserView ccuser ON a.User_id = ccuser.user_id
		WHERE cal_inicio >= @from
			  AND cal_inicio < @to;

		END
	'


	EXEC(@sql)


	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
