SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 77

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		

		SET @process = 'CW-3891 Alter SP ccspRepAVRSRateDetail'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSRateDetail]
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
	f.fecha_calif AS fecha,
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
		EXEC (@sql)



		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

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
