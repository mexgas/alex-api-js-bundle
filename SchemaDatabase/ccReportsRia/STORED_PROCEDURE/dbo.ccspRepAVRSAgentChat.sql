CREATE PROCEDURE  [dbo].[ccspRepAVRSAgentChat]
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
	DELETE FROM dbo.RepAVRSAgentChat with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSAgentChat
	select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS lDate,
		a.User_id AS userId,
		a.Login AS lUser,
		(a.apellidopaterno+' '+a.apellidomaterno+' '+a.nombres) AS agentName, 
		f.total_forma AS Dispositions, 
		f.total_forma AS Disposition2, 
		f.total_forma AS avgDisposition,
		f.id_formato AS idFormato,
		k.nombre AS Template,		
		f.id_chat AS chatId,
		i.Inbound_id AS inboundId,
		i.descripcion AS inbound,	 
		YEAR(f.fecha_calif) AS [year], 
		MONTH(f.fecha_calif) AS [month], 
		DAY(f.fecha_calif) AS [day], 
		CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
		CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
	from dbo.RIA_FORMACALIF_CHAT f
		INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
		INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
									FROM dbo.RIA_FORMATOS
									WHERE activo = 1
									GROUP BY id_formato,nombre) as t 
									ON t.id_formato= f.id_formato
		INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
		INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
		INNER JOIN ccinbound AS i ON c.inboundId = i.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
					
END