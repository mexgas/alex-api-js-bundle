SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 105

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	SET @process = 'CW-5863 update SP ccspRepOutCallsDetail'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] 
					@action as tinyint,
					@from as datetime = NULL,
					@to as datetime = NULL
					AS

					IF @from IS NULL
						SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

					IF @to IS NULL
						SELECT @to = getdate()

					DECLARE @IVA INT
					DECLARE @country AS TINYINT

					SELECT @IVA = convert(INT, isnull(valor, 0))
					FROM ccsettings
					WHERE setting_id = 25

					SELECT @country = convert(TINYINT, isnull(valor, 1))
					FROM ccsettings
					WHERE setting_id = 104

					IF @country IS NULL
						SET @country = 1

					IF @action = 1
					BEGIN
						--Borrar lo que esta para no repetir
						DELETE
						FROM RepOutCallsDetail WITH (ROWLOCK)
						WHERE DATE >= @from AND DATE < @to

						INSERT INTO RepOutCallsDetail
						SELECT Call.cal_inicio AS [date],
							Call.cal_key AS [callKey],
							Call.cal_telefono AS [telephone],
							Call.cal_txfer + call.cal_tring AS [transfer],
							Call.cal_tdialog AS [dialog],
							ISNULL(Call.cal_tMoh, 0) AS [nque],
							Call.cal_tnotas AS [wrapup],
							ISNULL(Tipo.[description], '''') AS [CallDisposition],
							Call.cal_extension AS [extension],
							isnull(Usr.user_id, 0) AS [userId],
							ISNULL(convert(VARCHAR(255), Usr.LOGIN), ''systemTranslated_NoUserName'') [login],
							ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username],
							camps.cam_id AS [campaignId],
							ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
							(CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration],
							CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country)) AS [ncost],

							@IVA AS iva,
							CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country) * (1 + (@IVA / 100.00))) AS total,
							CASE 
								WHEN prov.descrip IS NOT NULL THEN prov.descrip
								ELSE ''systemTranslated_NoCarrier'' 
							END AS [ByCarrier],
							ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [Calltypes],
							CASE 
								WHEN LEFT(ld.TipoDialingMode, 1) = ''1'' THEN ''systemTranslated_Assisted'' ELSE
								CASE WHEN Call.cal_manual = 0 THEN ''systemTranslated_Auto'' 
								ELSE ''systemTranslated_Manual'' END
							END AS [dialType], 
							CASE 
								WHEN Call.cal_whoHung = 0 THEN ''systemTranslated_Client'' 
								WHEN Call.cal_whoHung = 1 THEN ''systemTranslated_Agent'' 
								ELSE ''systemTranslated_AgentSurvey'' 
							END [whoHangUp], 
							CASE 
								WHEN call.califsub_id = 0 THEN ''systemTranslated_NoSubDisposition'' 
								ELSE isnull(sub.califSubDesc, '''') 
							END AS [subDisposition],
							sta.descripcion AS [dialResult], 
							Call.cal_id as [calId],
							datepart(yyyy, Call.cal_inicio) AS [year],
							datepart(mm, Call.cal_inicio) AS [month],
							datepart(dd, Call.cal_inicio) AS [day],
							datepart(hh, Call.cal_inicio) AS [hour],
							datepart(mi, Call.cal_inicio) AS [minutes],
							Call.cal_puerto,
							ISNULL(cs.Dato1, '''') AS [data1],
							ISNULL(cs.Dato2, '''') AS [data2],
							ISNULL(cs.Dato3, '''') AS [data3],
							ISNULL(cs.Dato4, '''') AS [data4],
							ISNULL(cs.Dato5, '''') AS [data5],
							ISNULL(Call.cal_tMsg, 0) AS [MessageTime],
							ISNULL(rc.grab_id, 0) as grabId
						FROM ccoCallsOut Call (nolock)
							LEFT JOiN ccoLogDials ld (nolock) ON Call.cal_id=ld.cal_id
							LEFT JOIN ccTipoCalifOUT Tipo (nolock) ON Call.calif_id = Tipo.calif_id
							LEFT JOIN ccUserView Usr (nolock) ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
							LEFT JOIN ccCamps camps (nolock) ON camps.[cam_id] = Call.[cam_id]
							LEFT JOIN ccStatusLlamada sta (nolock) ON call.statuscall_id = sta.statuscall_id
							LEFT JOIN cstoProvedor prov (nolock) ON prov.[provedor_id] = Call.[provedor_id]
							LEFT JOIN cstoTipoLlamada tl (nolock) ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] AND tl.Country_id = @country)
							LEFT JOIN ccTipoCalifSubOut sub (nolock) ON call.califsub_id = sub.califsub_id
							LEFT JOIN ccoDialers di (nolock) ON di.dialer_id = Call.cal_puerto AND call.provedor_id = di.provedor_id
							LEFT JOIN ccoCallsOutSource cs (nolock) ON Call.callout_id = cs.callout_id
							LEFT JOIN ccCallCost_RIA cc (nolock) ON cc.country_id = tl.country_id AND cc.tipoLlamada_id = tl.tipoLlamada_id
							LEFT JOIN Ria_grabacion rc (nolock) on (rc.cal_id = Call.cal_id and rc.tipo_llamada = 2)
						WHERE Call.cal_inicio >= @from AND Call.cal_inicio < @to AND Call.cal_manual IN (0, 2)
						ORDER BY DATE
					END'
	EXEC (@sql)

	SET @process = 'CW-5863 update SP ccspRepOutDialDetail'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail] 
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
					ISNULL(ISNULL(dials.cal_key, cs.cal_key), '''') cal_key, 
					telefono, 
					dials.tiporesdial_id,
					CASE 
						WHEN dials.tipoResDial_id = 14
						THEN ''systemTranslated_CancelledBySystem''
						ELSE ISNULL(descripcion, '''')
					END AS resultado,
					dials.[cam_id], 
					ISNULL(RTRIM(LTRIM(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') AS campa, 
					dials.tbusy AS Msgtime, 
					DATEPART(yyyy, fecha), 
					DATEPART(mm, fecha), 
					DATEPART(dd, fecha), 
					DATEPART(hh, fecha), 
					DATEPART(mi, fecha), 
					ISNULL(rl.name, ''''),
					CASE
						WHEN answerbit = 1
						THEN ''systemTranslated_Charged''
						ELSE ''systemTranslated_NotCharged''
					END AS billed, 
					ISNULL(cs.Dato1, '''') AS data1, 
					ISNULL(cs.Dato2, '''') AS data2, 
					ISNULL(cs.Dato3, '''') AS data3, 
					ISNULL(cs.Dato4, '''') AS data4, 
					ISNULL(cs.Dato5, '''') AS data5,
					CASE
						WHEN dials.[file_moved] = 1
						THEN ''systemTranslated_Remoto''
						ELSE ''Local''
					END AS file_Moved, 
					dials.disconnectCause, 
					COALESCE(dat.description, descripcion, ''N/A'') DCCustomer, 
					dials.dialType,
					CASE
						WHEN @country = 1
						THEN ISNULL(
			(
				SELECT CASE
							WHEN dials.tipoLlamada_id IN(1, 2, 5)
							THEN ''systemTranslated_fijo''
							WHEN dials.tipoLlamada_id IN(3, 4)
							THEN ''systemTranslated_cellPhone''
							ELSE ''systemTranslated_Indefinite''
						END
			), ''systemTranslated_Indefinite'')
						ELSE ''''
					END AS TipoTel, 
					ISNULL(CallDisposition, ''N/A'') AS CallDisposition, 
					ISNULL(califSubDesc, ''N/A'') AS CallSubDisposition
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
							WHEN LEFT(dial.TipoDialingMode, 1) = ''1''
							THEN ''systemTranslated_Assisted''
							ELSE CASE
									WHEN RIGHT(dial.TipoDialingMode, 2) = ''00''
									THEN ''systemTranslated_Auto''
									WHEN RIGHT(dial.TipoDialingMode, 2) IN(''10'', ''01'')
									THEN ''systemTranslated_Manual''
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
													THEN ''''
													ELSE SUBSTRING(dials.disconnectCause, 21, 3)
												END)
			WHERE fecha >= @from
					AND fecha < @to
			ORDER BY fecha
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
