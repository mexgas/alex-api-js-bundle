CREATE PROCEDURE  [dbo].[ccspRepAVRSQuestionChat]
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
	DELETE FROM dbo.RepAVRSQuestionChat with(rowlock)
	where date >= @from AND date < @to

;with formato as(
select id_formato,nombre, max(version) as version from dbo.RIA_FORMATOS WHERE activo = 1 and tipo=2 group by id_formato,nombre),
 dataResume as(

		select
		convert(date, f.fecha_calif) AS [date],
		a.User_id as userId,
		a.Login as [user],
		(a.apellidopaterno+' '+a.apellidomaterno+' '+a.nombres) AS agentName,
		t.id_formato as templateId,
		t.nombre as template,
		--c.id_concepto as sectionId,
		--c.con_descripcion as Section,
		p.id_pregunta as questionId,
		p.enunciado_pregunta as question,
		w.peso As Dispositions,
		w.peso AS avgDisposition,
		i.Inbound_id AS inboundId,
		i.descripcion AS inbound
		--chats.chatId as chatId
 from RIA_FORMACALIF_CHAT f
--inner join dbo.RIA_FORMATOS2 as t ON t.id_formato= f.id_formato
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
inner join formato t on f.id_formato = t.id_formato
inner join RIA_CONCEPTOS c on c.id_formato=t.id_formato and c.version=t.version
INNER JOIN RIA_PREGUNTAS p ON c.id_concepto = p.id_concepto
INNER JOIN dbo.ccriachats chats ON f.id_chat=chats.chatId
INNER JOIN ccinbound AS i ON chats.inboundId = i.Inbound_id
INNER JOIN RIA_RESULTADOSFORMA_CHAT w ON w.id_pregunta = p.id_pregunta
WHERE f.fecha_calif >=@from and f.fecha_calif < @to)

	INSERT INTO dbo.RepAVRSQuestionChat ([date], userId, [user],agentName, templateId, template,
		questionId, question, Dispositions,avgDisposition,	inboundId, inbound)
	select [date], userId, [user],agentName, templateId, template,
		questionId,	question,Dispositions,avgDisposition,	inboundId,inbound
	from dataResume
	group by [date], userId, [user], agentName,templateId, template,
		questionId,	question,Dispositions,avgDisposition,	inboundId,inbound
END