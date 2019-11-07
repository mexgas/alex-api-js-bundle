CREATE PROCEDURE [dbo].[ccspGenOutCstoResumen]
@from AS smalldatetime,
@to AS smalldatetime
AS
declare @country as tinyInt
select @country = valor from ccSettings where setting_id = 104

-- Delete previous data in case of reprocess HLAS
DELETE ccGenOutCstoResumen WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCstoResumen (timegroup, cam_id, [user_id], provedor_id, tipoLlamada_id, amount, mins, costo)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121) AS timegroup
	, cam_id, [user_id], provedor_id, tipoLlamada_id 
	, COUNT(*)
	, SUM( mins)
	, SUM( costo )
FROM
(
	SELECT cal_inicio, cam_id, [user_id], provedor_id, tipoLlamada_id, CEILING((cal_tXfer + cal_tRing + cal_tDialog +1 ) / 60.0 ) as mins, costo
	FROM ccoCallsOut
	WHERE cal_inicio >= @from AND  cal_inicio < @to and provedor_id is not null and cal_manual in (0,2)

	-- Tambien las llamdas que fueron fax
	UNION ALL

	SELECT cco.fecha as fecha, cco.cam_id, 0, p.provedor_id, l.tipoLlamada_id, 1, t.MinutoUno as costo
	FROM ccoLogDials cco, ccoDialers cd, cstoProvedor p, cstoTarifa t, cstoTipoLlamada l
	WHERE 
	l.country_id = @country
	and cco.answerbit = 1 and cco.tiporesdial_id <> 1
	and cco.fecha >=  @from AND cco.fecha < @to
	and cco.puerto = cd.puerto
	and cd.provedor_id = p.provedor_id	
	and p.provedor_id = t.provedor_id
	and l.longitud like '%'+cast( len(cco.telefono) as varchar(max))+'%'
	and cco.telefono like l.prefijo
	and t.tipoLlamada_id = l.tipoLlamada_id
)x
GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121), cam_id, [user_id], provedor_id, tipoLlamada_id