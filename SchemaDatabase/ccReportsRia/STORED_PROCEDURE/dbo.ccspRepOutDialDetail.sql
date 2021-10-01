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
		        


		--Inserta informacon de reporte  
		INSERT INTO RepOutDialDetail
			SELECT fecha, 
					ISNULL(ISNULL(dials.cal_key, cs.cal_key), '') cal_key, 
					telefono, 
					dials.tiporesdial_id,
					CASE 
						WHEN dials.tipoResDial_id = 14
						THEN 'systemTranslated_CancelledBySystem'
						ELSE ISNULL(descripcion, '')
					END AS resultado,
					dials.[cam_id], 
					ISNULL(RTRIM(LTRIM(camps.cam_descripcion)), 'systemTranslated_NoCampaign') AS campa, 
					dials.tbusy AS Msgtime, 
					DATEPART(yyyy, fecha), 
					DATEPART(mm, fecha), 
					DATEPART(dd, fecha), 
					DATEPART(hh, fecha), 
					DATEPART(mi, fecha), 
					ISNULL(rl.name, ''),
					CASE
						WHEN answerbit = 1
						THEN 'systemTranslated_Charged'
						ELSE 'systemTranslated_NotCharged'
					END AS billed, 
					ISNULL(cs.Dato1, '') AS data1, 
					ISNULL(cs.Dato2, '') AS data2, 
					ISNULL(cs.Dato3, '') AS data3, 
					ISNULL(cs.Dato4, '') AS data4, 
					ISNULL(cs.Dato5, '') AS data5,
					CASE
						WHEN dials.[file_moved] = 1
						THEN 'systemTranslated_Remoto'
						ELSE 'Local'
					END AS file_Moved, 
					dials.disconnectCause, 
					COALESCE(dat.description, descripcion, 'N/A') DCCustomer, 
					dials.dialType,
					CASE
						WHEN @country = 1
						THEN ISNULL(
			(
				SELECT CASE
							WHEN dials.tipoLlamada_id IN(1, 2, 5)
							THEN 'systemTranslated_fijo'
							WHEN dials.tipoLlamada_id IN(3, 4)
							THEN 'systemTranslated_cellPhone'
							ELSE 'systemTranslated_Indefinite'
						END
			), 'systemTranslated_Indefinite')
						ELSE ''
					END AS TipoTel, 
					ISNULL(CallDisposition, 'N/A') AS CallDisposition, 
					ISNULL(califSubDesc, 'N/A') AS CallSubDisposition
			FROM
			(
				SELECT dial.logDial_id, 
						dial.callout_id, 
						dial.cam_id, 
						CASE
							WHEN dial.canceledNoAgents = 1
							THEN 14
							ELSE dial.tipoResDial_id
						END AS tipoResDial_id,
						dial.Telefono, 
						dial.Puerto, 
						dial.fecha, 
						dial.tDialing,
						CASE
							WHEN LEFT(dial.TipoDialingMode, 1) = '1'
							THEN 'systemTranslated_Assisted'
							ELSE CASE
									WHEN RIGHT(dial.TipoDialingMode, 2) = '00'
									THEN 'systemTranslated_Auto'
									WHEN RIGHT(dial.TipoDialingMode, 2) IN('10', '01')
									THEN 'systemTranslated_Manual'
								END
						END AS dialType,
						dial.tBusy, 
						dial.answerbit, 
						dial.canceledNoAgents, 
						dial.cal_id, 
						dial.disconnectCause, 
						co.cal_key, 
						co.file_moved, 
						dial.tipoLlamada_id, 
						tco.Description AS CallDisposition, 
						tsco.califSubDesc
				FROM ccoLogDials dial(NOLOCK)
						LEFT JOIN ccocallsout co(NOLOCK) ON dial.cal_id = co.cal_id
						LEFT JOIN cctipocalifout tco WITH(NOLOCK) ON tco.calif_id = co.calif_id
						LEFT JOIN cctipocalifsubout tsco WITH(NOLOCK) ON tsco.califSub_id = co.califSub_id
				WHERE fecha >= @from
						AND fecha < @to
			) dials
			LEFT JOIN ccoCallsOutSource cs(NOLOCK) ON dials.callout_id = cs.callout_id
			LEFT JOIN cctipoResultadoDial tr (nolock) ON dials.tiporesdial_id = tr.tiporesdial_id
			LEFT JOIN ccCamps camps (nolock) ON camps.[cam_id] = dials.[cam_id]
			LEFT JOIN ccRIARegistryLists rl (nolock) ON cs.list_id = rl.list_id
			LEFT JOIN DC_Extra dat (nolock) ON(dat.id = CASE
													WHEN ISNUMERIC(SUBSTRING(dials.disconnectCause, 21, 3)) = 0
													THEN ''
													ELSE SUBSTRING(dials.disconnectCause, 21, 3)
												END)
			WHERE fecha >= @from
					AND fecha < @to
			ORDER BY fecha
		END