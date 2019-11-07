CREATE PROCEDURE [dbo].[trsp_GenPuntajesAgente]
@from AS smalldatetime,
@to AS smalldatetime
AS

-- Borra los resultados previos para el puntaje de los monitores

DELETE TREC_GENPUNTAJEAGENTE WHERE timegroup BETWEEN @from AND @to

-- Inserta los nuevos registros para el puntaje dado por los monitores y el número de grabaciones calificadas
INSERT INTO TREC_GENPUNTAJEAGENTE (timegroup, age_id, cant_calif, puntaje) 
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), fecha_calif, 121) + ':00', 121) AS timegroup
		, grab.age_id as age_id
		, count(distinct forms.id_forma) as cant_calif
		, sum(forms.total_forma) as puntaje
FROM 
TREC_FORMACALIF forms
JOIN
TREC_GRABACION grab
ON 
grab.grab_id = forms.id_grabacion
WHERE forms.fecha_calif BETWEEN @from and @to
GROUP BY
CONVERT(smalldatetime, CONVERT(varchar(13), fecha_calif, 121) + ':00', 121), grab.age_id