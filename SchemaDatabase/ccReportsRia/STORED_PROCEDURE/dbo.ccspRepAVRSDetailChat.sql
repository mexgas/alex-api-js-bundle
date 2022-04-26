CREATE PROCEDURE  [dbo].[ccspRepAVRSDetailChat]
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
	DELETE FROM dbo.RepAVRSDetailChat	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSDetailChat

		select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
		a.User_id,
		a.Login,
		(a.apellidopaterno+' '+a.apellidomaterno+' '+a.nombres) AS agent, 
		t.id_formato,
		t.nombre,
		p.enunciado_pregunta,
		r.etiquetas,
		r.peso as avgDisposition,
		i.Inbound_id AS inboundId,
		i.descripcion AS inbound,
		c.chatId
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
END