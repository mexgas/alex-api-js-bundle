SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 89

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'se actualiza reprote de llamadas contestadas y transferidas'
		SET @sql = 'ALTER FUNCTION [dbo].[tDialog](
		@totalCall_Time int,
		@tdialing tinyint, 
		@cal_tMsg int)
RETURNS INT 
AS
BEGIN
		DECLARE @totalDialog INT
		IF ((COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0), @tdialing) % 60) <> 0 )
		BEGIN
			SET @totalDialog=COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing) + (60 -(COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing) % 60)) 
			RETURN @totalDialog
		END
		ELSE
			SET @totalDialog = 60 + COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing)
			RETURN @totalDialog
END'
		EXEC(@sql)

		SET @process = 'se actualiza reprote de llamadas contestadas y transferidas2'
		SET @sql = '		ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
		@action as tinyint,
		@from as datetime = null,
		@to as datetime = NULL
		AS
		IF @from IS NULL
		SELECT @from = CONVERT(DATETIME,CONVERT(VARCHAR(11),GETDATE()))
		IF @to IS NULL
		SELECT @to = GETDATE()

		DECLARE @IVA INT
		DECLARE @country AS TINYINT
		SELECT @IVA = CONVERT(INT,ISNULL(valor,0)) FROM ccsettings WHERE setting_id = 25
		SELECT @country = CONVERT(TINYINT,ISNULL(valor,1)) FROM ccsettings WHERE setting_id = 104

		IF @country IS NULL SET @country = 1

		IF @action = 1
		BEGIN
		--Borrar lo que esta para no repetir
		DELETE FROM RepOutAnswAndXferCalls WITH(ROWLOCK) WHERE DATE >= @from AND DATE < @TO
		INSERT INTO RepOutAnswAndXferCalls

		SELECT COALESCE([Call].cal_inicio,ccld.fecha) AS [date],
			ISNULL(ccld.cal_id,0) AS [callid],
			ISNULL(ccld.cam_id,0) AS [campaignId],
			ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
			ISNULL([Call].user_id,0) AS [userId],
			ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') AS [Agent],
		    dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg) AS [dialog],
			ccld.telefono AS [telephone],
			ISNULL(Call.cal_manual,0) AS [dialId],
			ISNULL((SELECT [description] FROM dialType 
						WHERE dialId = Call.cal_manual),''systemTranslated_Auto'') AS [dialType],
			ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
			CASE 
				WHEN provedor_id IS NOT NULL THEN dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),COALESCE(Call.provedor_id,ccld.proBIDs),
					CASE 
						WHEN (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 
							THEN COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) 
						ELSE 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) 
					END,@country)
		ELSE  CONVERT(DECIMAL(10,2),(CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) / 60) * ccost.additional_min)))
			END AS [ncost],
			@IVA AS iva,
			CASE
				WHEN provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),COALESCE(Call.provedor_id,ccld.proBIDs),
					dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg)
					,@country),0.00) * (1 + (@IVA / 100.00)))
				ELSE  CONVERT(DECIMAL(10,2),((CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) / 60) * ccost.additional_min)) * (1 + (@IVA / 100.00))))
			END	AS total,
			COALESCE(ccld.Puerto, Call.cal_puerto, 0) as [trunk],
			case when dbo.TelAni(ccld.Telefono, camps.id_anilist) <> '''' then dbo.TelAni(ccld.Telefono, camps.id_anilist) else camps.ani end [ANI],
			COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) as dialTimeSec
		FROM (SELECT *, [dbo].[GetProveedor](Telefono, Puerto,CallType) AS proBIDs 
				FROM (SELECT *, tipoLlamada_id as CallType 
						FROM ccologdials WITH(NOLOCK)
							WHERE fecha >= @from and fecha < @to and answerbit = 1
						) as basequery 
				) ccld
			LEFT JOIN ccoCallsOut Call WITH(NOLOCK) ON ccld.cal_id = Call.cal_id
					AND ccld.answerbit = 1
			LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
			LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
			LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
			LEFT JOIN ccCallCost_RIA ccost (NOLOCK) ON ccost.tipoLlamada_id = tl.tipoLlamada_id
					AND ccost.country_id = tl.country_id
		ORDER BY DATE
		
		INSERT INTO RepOutAnswAndXferCalls
		
		SELECT DATEADD(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) AS [date],
			clt.cal_id AS [callid],
			COALESCE(co.cam_id,ci.inbound_id,''0'')  AS [campaignId],
			COALESCE(camps.cam_descripcion, ACD.descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
			ISNULL((CASE tipo 
						WHEN 1 THEN ci.User_id 
						ELSE co.User_id 
					END),0) AS [userId],
			ISNULL((SELECT nombres + '' '' + apellidopaterno + '' '' + apellidomaterno FROM ccusers NOLOCK WHERE user_id = 
						(CASE tipo 
							WHEN 1 THEN ci.User_id 
							ELSE co.User_id 
						END)),''systemTranslated_NoName'') as [Agent],
		    dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) AS [dialog],
			CASE 
				WHEN modo = 0 THEN ISNULL((SELECT TOP 1 tel FROM telefonosTransferencia WHERE tel = clt.destino),clt.destino)  
				WHEN modo = 3 THEN isnull((SELECT tel FROM telefonosConferencia WHERE tel = clt.destino),clt.destino) 
				WHEN modo = 4 THEN isnull((SELECT TOP 1 tel FROM telefonosTransferencia WHERE tel = clt.destino),clt.destino) 
				WHEN modo = 5 THEN isnull((SELECT Computer FROM ccposicion WHERE pos_id = abs(clt.destino)),clt.destino) 
			END AS [telephone],
			3 AS [dialId],
			(SELECT [description] FROM dialType WHERE dialId = 3) AS [dialType],
			ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
			CASE 
				WHEN tarifa.provedor_id IS NOT NULL THEN ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
					dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) ,@country), 0) 
				ELSE cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)
			END AS [ncost],
			@IVA AS iva,
			CASE 
				WHEN tarifa.provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
					dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0)
					,@country),0.00) * (1 + (@IVA / 100.00))) 
				ELSE (cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)) * (1 + (@IVA / 100.00))
			END AS [total],
			IsNull(clt.channel, 0) as [trunk],
			case when (@country = 1 and modo = 4) then case when dbo.TelAni(clt.destino, camps.id_anilist) <> '''' then dbo.TelAni(clt.destino,
			camps.id_anilist) else camps.ani end else '''' end [ANI],
			ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) as dialTimeSec
		FROM (SELECT *, tipoLlamada_id AS  CallType 
			FROM cclogtransfers WITH(NOLOCK) 
			WHERE modo not in (1,2) 
				AND (tAntesXfer > 0 or tDespuesXfer > 0) 
				AND dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) >= @from 
				AND dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) < @to) clt
			LEFT JOIN cccallsin ci WITH(NOLOCK) ON ci.cal_id=clt.cal_id AND tipo=1
			LEFT JOIN ccocallsout co WITH(NOLOCK) ON co.cal_id=clt.cal_id AND tipo=2 
			LEFT JOIN ccChannelTransfer channel ON clt.pbxId=channel.pbxId AND clt.channel BETWEEN channel.startChannel AND channel.endChannel
			LEFT JOIN cstoTarifa tarifa ON tarifa.provedor_id=channel.proveedorId AND tarifa.tipoLlamada_id = clt.CallType
			LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType AND tl.Country_id = @country)
			LEFT JOIN ccCallCost_RIA cCall ON cCall.country_id = tl.country_id AND cCall.tipoLlamada_id = tl.tipoLlamada_id
			LEFT JOIN ccCamps camps ON camps.[cam_id] = co.cam_id
			LEFT JOIN ccInbound ACD ON ACD.[Inbound_id] = ci.Inbound_id
		order by date
		end'
		EXEC(@sql)
		
		SET @process = 'CW-4381 Se modifica sp ccspRepCallXfer'
		        SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepCallXfer]
		@action as tinyint,
		@from AS datetime = null,
		@to AS datetime = null
		AS
		
		if @action = 1
		begin
			if @from is null
				select @from = convert(datetime,convert(varchar(11),getdate()))
			if @to is null	
				select @to = getdate()
		
			delete RepCallXfer with(rowlock)
			where [date] between @from and @to
						
			insert RepCallXfer 
			select convert(varchar(10),fechafin,121) [date],
			clt.cal_id callid, case when tipo = 1 then ''systemTranslated_inbound'' else ''systemTranslated_outbound'' end CallTypes, 
			isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccUserView nolock where user_id = 
			(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') Agent,
			case when modo = 0 then ''systemTranslated_blindXfer'' 
			when modo = 1 then ''systemTranslated_Agent'' 
			when modo = 2 then 
				case when cast(clt.destino as int) >= 0 then ''systemTranslated_acd'' else ''systemTranslated_Survey'' end
			when modo = 3 then ''systemTranslated_conference'' 
			when modo = 4 then ''systemTranslated_supXfer'' 
			when modo = 5 then ''systemTranslated_overflow'' end as xfertype,
			case when modo = 0 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
			when modo = 1 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),''systemTranslated_Indefinite'') 
			when modo = 2 then 
				case when cast(clt.destino as int) >= 0 then
					isnull((select descripcion from ccinbound where inbound_id = clt.destino),''systemTranslated_Indefinite'') 
				else
					isnull((select top 1 description from survey where active=1 and scriptId = abs(cast(clt.destino as int))),''systemTranslated_Indefinite'') 
				end
			when modo = 3 then isnull((select nombre from telefonosConferencia where tel = clt.destino),clt.destino) 
			when modo = 4 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
			when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end destination,
			tantesxfer timebeforexfer,
			tdespuesxfer timeafterxfer,
			dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate,
			fechafin as endDate,		
			case when camp.cam_descripcion is not null then  camp.cam_descripcion 
			when inbound.descripcion is not null then  inbound.descripcion				
			else ''systemTranslated_Indefinite'' end as Origin,
			tantesxfer+tdespuesxfer as TotalTimeDuration,				
			isnull((select case clt.tipoLlamada_id when 1 then ''systemTranslated_fijo''
				when 3 then ''systemTranslated_cellPhone'' else ''systemTranslated_interno'' end
				),''systemTranslated_Indefinite'') as TipoTel
			from cclogtransfers clt 
			left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
			left join cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1
			left join cccamps camp on camp.cam_id =co.cam_id
			left join ccinbound inbound on inbound.Inbound_id =ci.Inbound_id
			WHERE fechafin >= @from and fechafin < @to
		end'
        EXEC(@sql)
		
		
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

