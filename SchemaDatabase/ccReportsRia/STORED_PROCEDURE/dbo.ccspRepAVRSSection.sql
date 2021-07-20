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
---Before insert delete first  table dbo.RepAVRSSection 
DELETE FROM dbo.RepAVRSSection with(rowlock)
where date >= @from AND date < @to

INSERT INTO dbo.RepAVRSSection
				
select
	DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+' '+a.apellidomaterno+' '+a.nombres) AS agent, 
	s.User_id,
	s.Login,
	(s.apellidopaterno+' '+s.apellidomaterno+' '+s.nombres) AS Supervisor,
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
		when 1 then 'systemTranslated_Recording' 
		when 2 then 'systemTranslated_Chat'
		when 3 then 'systemTranslated_Email'
		when 3 then 'systemTranslated_Twitter'
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

END