SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 107

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	SET @process = 'CW-5919 se modifica sp ccspRepAVRSQuestion'
	SET @sql = 'ALTER PROCEDURE  [dbo].[ccspRepAVRSQuestion]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()
if @action = 1 BEGIN


DELETE FROM dbo.RepAVRSQuestion with(rowlock)
where date >= @from AND date < @to
;with pregunta as(
SELECT id_pregunta,enunciado_pregunta FROM dbo.RIA_PREGUNTAS GROUP BY id_pregunta,enunciado_pregunta),
  dataResume as(
select
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
        when 1 then ''systemTranslated_Recording''
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

  INSERT INTO dbo.RepAVRSQuestion ([date],userId,[user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section, questionId, Question, avgDisposition,mediaId,media,cam_id,campaignAcd,Dispositions)
  select [date],userId, [user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section, questionId, Question, avg(score) score, mediaId, media,cam_id,campaignAcd, avg(score) score
  from dataResume
  group by  [date], userId,[user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section, questionId, Question,
  mediaId,media,cam_id,campaignAcd
 
END'
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
