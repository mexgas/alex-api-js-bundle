CREATE PROCEDURE [dbo].[ccspRepOutDialDetail] 
@action AS TINYINT, 
@from AS   DATETIME = NULL, 
@to AS     DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
	SELECT @from =CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE())) - 15
if @to is null
	SELECT @to = GETDATE()

IF @action = 1
BEGIN  

DECLARE @country SMALLINT
SELECT @country = valor
FROM ccSettings
WHERE setting_id = 104

--Borrar lo que esta para no repetir          
DELETE FROM RepOutDialDetail WHERE date >= @from            AND date < @to
		        

;WITH dials
AS (
	SELECT dial.logDial_id
		,dial.callout_id
		,dial.cam_id
		,CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id
		,dial.Telefono
		,dial.Puerto
		,dial.fecha
		,dial.tDialing
		,CASE WHEN LEFT(dial.TipoDialingMode, 1) = '1' THEN 'systemTranslated_Assisted' 
			  WHEN RIGHT(dial.TipoDialingMode, 2) = '00' THEN 'systemTranslated_Auto' 
			  WHEN RIGHT(dial.TipoDialingMode, 2) IN ('10', '01') THEN 'systemTranslated_Manual' END AS dialType
		,dial.tBusy
		,dial.answerbit
		,dial.canceledNoAgents
		,dial.cal_id
		,dial.disconnectCause
		,co.cal_key
		,co.file_moved
		,dial.tipoLlamada_id
		,tco.[Description] AS CallDisposition
		,tsco.califSubDesc
		,CASE WHEN dial.disconnectCause <> '' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '' END codeSip
		,case when @country<>1 then '' WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN 'systemTranslated_fijo' 
			WHEN dial.tipoLlamada_id IN (3, 4) THEN 'systemTranslated_cellPhone' ELSE 'systemTranslated_Indefinite' END TipoTel		
	FROM ccoLogDials dial(NOLOCK)
	LEFT JOIN ccocallsout co(NOLOCK) ON dial.cal_id = co.cal_id
	LEFT JOIN cctipocalifout tco WITH (NOLOCK) ON tco.calif_id = co.calif_id
	LEFT JOIN cctipocalifsubout tsco WITH (NOLOCK) ON tsco.califSub_id = co.califSub_id
	WHERE fecha >= @from AND fecha < @to
	), codeSip as(
		select distinct cast(codeSip as int) as codeSip,disconnectCause from dials where codeSip<>'' and IsNumeric(codeSip)=1
	)
	, relationCodeSip as(
		select A.codeSip,A.disconnectCause,B.description from codeSip A
		inner join DC_Extra B on A.codeSip=B.id
	)


--Inserta informacon de reporte  
	INSERT INTO RepOutDialDetail
		SELECT fecha as [date]
		,case when dials.cal_key is null or  cs.cal_key is null then '' when dials.cal_key is not null then dials.cal_key else cs.cal_key end cal_key
		,telefono telephone
		,dials.tiporesdial_id as tiporesdialId
		,CASE WHEN dials.tipoResDial_id = 14 THEN 'systemTranslated_CancelledBySystem' ELSE ISNULL(descripcion, '') END AS dialResult
		,dials.[cam_id] campaignId
		,ISNULL(RTRIM(LTRIM(camps.cam_descripcion)), 'systemTranslated_NoCampaign') AS campaign
		,dials.tbusy AS timeMessage
		,DATEPART(yyyy, fecha) year	
		,DATEPART(mm, fecha) month	
		,DATEPART(dd, fecha) day	
		,DATEPART(hh, fecha) hour	
		,DATEPART(mi, fecha) minutes
		,ISNULL(rl.name, '') listName
		,CASE WHEN answerbit = 1 THEN 'systemTranslated_Charged' ELSE 'systemTranslated_NotCharged' END AS billed
		,ISNULL(cs.Dato1, '') AS data1
		,ISNULL(cs.Dato2, '') AS data2
		,ISNULL(cs.Dato3, '') AS data3
		,ISNULL(cs.Dato4, '') AS data4
		,ISNULL(cs.Dato5, '') AS data5
		,CASE WHEN dials.[file_moved] = 1 THEN 'systemTranslated_Remoto' ELSE 'Local' END AS fileMoved
		,dials.disconnectCause
		,COALESCE(dat.description, descripcion, 'N/A') DCCustomer
		,dials.dialType
		,TipoTel
		,ISNULL(CallDisposition, 'N/A') AS CallDisposition
		,ISNULL(califSubDesc, 'N/A') AS CallSubDisposition
	FROM dials
	LEFT JOIN ccoCallsOutSource cs(NOLOCK) ON dials.callout_id = cs.callout_id
	LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dials.tiporesdial_id = tr.tiporesdial_id
	LEFT JOIN ccCamps camps(NOLOCK) ON camps.[cam_id] = dials.[cam_id]
	LEFT JOIN ccRIARegistryLists rl(NOLOCK) ON cs.list_id = rl.list_id
	LEFT JOIN relationCodeSip dat ON dat.disconnectCause = dials.disconnectCause

END