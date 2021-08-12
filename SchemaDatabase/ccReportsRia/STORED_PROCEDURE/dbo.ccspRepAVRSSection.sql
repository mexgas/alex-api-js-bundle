CREATE PROCEDURE [dbo].[ccspRepAVRSSection]
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
DELETE FROM dbo.RepAVRSSection with(rowlock)
where date >= @from AND date <= @to


;with formato as(
SELECT id_formato,nombre,MAX(version)AS version FROM dbo.RIA_FORMATOS WHERE activo = 1 and tipo=1 GROUP BY id_formato,nombre),
		dataResume as(
		select convert(date, f.fecha_calif) as [date],
			f.age_id as userId,
			a.Login as [user],
			(a.apellidopaterno+' '+a.apellidomaterno+' '+a.nombres) AS agentName,
			f.id_calificador as supervisorId,
			s.Login as supervisorUser,
			(s.apellidopaterno+' '+s.apellidomaterno+' '+s.nombres) AS Supervisor,
			f.id_formato as templateId
			,t.nombre as Template
			,c.id_concepto as sectionId
			,c.con_descripcion as Section
			,w.id as templateSectionId
			,(t.nombre + ' ' + c.con_descripcion)+' '+convert(varchar(10),w.id)  as templateSection
			,r.peso AS score
			,f.id_grabacion as idMedia
			,case f.tipo
				when 1 then 'systemTranslated_Recording'
				when 2 then 'systemTranslated_Chat'
				when 3 then 'systemTranslated_Email'
				when 4 then 'systemTranslated_Twitter'
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
END