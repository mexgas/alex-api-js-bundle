/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Carlos Chavez
Date: 2019/07/16
Description: CW-3154


Database: ccReportsRia
Required version: 67


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 69

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		

		SET @process = 'CW-3154 ALTER PROCEDURE dbo.ccspRepCallXfer'
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
			isnull((select description from survey where scriptId = abs(cast(clt.destino as int))),''systemTranslated_Indefinite'') 
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
		EXEC (@sql)



		SET @process = 'CW-3154 ALTER PROCEDURE dbo.ccspRepOutAnswAndXferCalls'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
                select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

declare @IVA INT
declare @country as tinyint


select @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25
select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104


if @country is null set @country = 1


if @action = 1
begin
                --Borrar lo que esta para no repetir
                delete from RepOutAnswAndXferCalls with(rowlock) where date >= @from AND date < @to

                insert into RepOutAnswAndXferCalls
                select COALESCE([Call].cal_inicio,ccld.fecha) as [date],
                isnull(ccld.cal_id,0) as [callid],
                isnull(ccld.cam_id,0) as [campaignId],
                ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign],
                isnull([Call].user_id,0) as [userId],
                ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') as [Agent],
                case when (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) end as [dialog],
                ccld.telefono as [telephone],
                isnull(Call.cal_manual,0) as [dialId],
                isnull((select [description] from dialType where dialId = Call.cal_manual),''systemTranslated_Auto'') as [dialType],
                ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
                dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType), COALESCE(Call.provedor_id,ccld.proBIDs) , case when (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) end) as [ncost],
                @IVA as iva,
                convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType), COALESCE(Call.provedor_id,ccld.proBIDs) , case when (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) end),0.00) * (1 + (@IVA / 100.00))) as total
                from (select *, [dbo].[GetProveedor](Telefono, Puerto,CallType) as proBIDs from (select *, tipoLlamada_id as CallType from ccologdials WITH(NOLOCK) where fecha >= @from and fecha < @to and answerbit = 1 ) as basequery ) ccld
                LEFT JOIN ccoCallsOut Call WITH(NOLOCK) on ccld.cal_id = Call.cal_id and ccld.answerbit = 1
                LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
                LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
                LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
                order by date

                insert into RepOutAnswAndXferCalls
                select dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) as [date],
                clt.cal_id as [callid],
                COALESCE(co.cam_id,ci.inbound_id,''0'')  as [campaignId],
                COALESCE(camps.cam_descripcion, ACD.descripcion, ''systemTranslated_NoCampaign'') as [campaign],
                isnull((case tipo when 1 then ci.User_id else co.User_id end),0) as [userId],
                isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccusers nolock where user_id = 
                (case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') as [Agent],
                case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else 60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end as [dialog],
                case when modo = 0 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino)  
                when modo = 3 then isnull((select tel from telefonosConferencia where tel = clt.destino),clt.destino) 
                when modo = 4 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino) 
                when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end as [telephone],
                3 as [dialId],
                (select [description] from dialType where dialId = 3) as [dialType],
                ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
                ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId, case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else 60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end), 0) as [ncost],
                @IVA as iva,
                convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId, case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else  60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end),0.00) * (1 + (@IVA / 100.00))) as [total]
                from (select *, tipoLlamada_id as  CallType from cclogtransfers WITH(NOLOCK) where modo not in (1,2) and (tAntesXfer > 0 or tDespuesXfer > 0) and dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) >= @from and dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) < @to) clt
                LEFT JOIN cccallsin ci WITH(NOLOCK) on ci.cal_id=clt.cal_id and tipo=1
                LEFT JOIN ccocallsout co WITH(NOLOCK) on co.cal_id=clt.cal_id and tipo=2 
                LEFT JOIN ccChannelTransfer channel on clt.pbxId=channel.pbxId and clt.channel between channel.startChannel and channel.endChannel
                LEFT JOIN cstoTarifa tarifa on tarifa.provedor_id=channel.proveedorId and tarifa.tipoLlamada_id = clt.CallType
                LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType and tl.Country_id = @country)
                LEFT JOIN ccCamps camps ON camps.[cam_id] = co.cam_id
                LEFT JOIN ccInbound ACD ON ACD.[Inbound_id] = ci.Inbound_id
                order by date 

end'
		EXEC (@sql)



		SET @process = 'CW-3154 ALTER PROCEDURE dbo.ccspRepOutCallBilling'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallBilling]
@action AS TINYINT,
@from AS DATETIME=null,
@to AS DATETIME=null

AS

DECLARE @country AS TINYINT
DECLARE @iva AS DECIMAL(3,2)
DECLARE @aux AS VARCHAR(3)

SELECT @country = CONVERT(TINYINT,isnull(valor,1)) FROM ccsettings WHERE setting_id = 104
SELECT @aux = isnull(valor,0) FROM ccsettings WHERE setting_id = 25
set @iva=CONVERT(DECIMAL(3,2),''1.''+@aux)

if @country is null 
set @country = 1
if @from is null
 select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

IF @action = 1
BEGIN
	DELETE FROM RepOutCallBilling WITH(rowlock) WHERE [date] >= @FROM AND [date] < @to

	CREATE TABLE #TempTransCallBilling(
		[date] datetime NOT NULL,
		camId INT NOT NULL,
		inboundId INT NOT NULL,
		userId INT NOT NULL,
		[proveedorId] INT NOT NULL,
		provedor VARCHAR(30) collate SQL_Latin1_General_CP1_CI_AS NOT NULL,
		[tipollamadaId] INT NOT NULL,	
		[tipoLlamada] VARCHAR(50) collate SQL_Latin1_General_CP1_CI_AS NOT NULL,
		[amount] INT NOT NULL,
		mins INT NOT NULL,
		costo DECIMAL(10,2) NOT NULL,
		costoIva DECIMAL(10,2) NOT NULL
	)

	INSERT INTO #TempTransCallBilling
	
	SELECT CONVERT(smalldatetime, CONVERT(varchar(13), [date], 121) + '':00'', 121) AS [date],
	[camp_id],[inbund_id],[user_id],[proveedorId],provedor,[tipollamadaId],[tipoLlamada],
	COUNT(*) AS amount,SUM(mins) AS mins,SUM([costo]) AS [costo],SUM( costo ) * @iva AS costoIva
	FROM (
		SELECT DATEADD(ss, -(tAntesXfer + tDespuesXfer),fechaFin) AS [date],cco.cam_id AS [camp_id], 
		0 AS [inbund_id],cco.[User_id] AS [user_id], channel.proveedorId AS [proveedorId],prov.descrip AS provedor,
		tipoLlam.tipoLlamada_id AS [tipollamadaId],tipoLlam.descrip AS [tipoLlamada],
		CEILING((tAntesXfer+tDespuesXfer +1 ) / 60.0 )AS [mins], dbo.fnGetCstoTarifa(trans.tipoLlamada_id, 
		channel.proveedorId, tAntesXfer+tDespuesXfer+1) AS [costo]
		FROM 
		ccLogTransfers  trans 
		INNER JOIN ccoCallsOut cco ON cco.cal_id=trans.cal_id AND tipo = 2
		INNER JOIN cstoTipoLlamada tipoLlam ON  tipoLlam.country_id = @country AND tipoLlam.tipoLlamada_id = trans.tipoLlamada_id
		LEFT JOIN ccChannelTransfer channel ON channel.pbxId=trans.pbxId AND trans.channel BETWEEN channel.startChannel AND channel.endChannel
		LEFT JOIN cstoProvedor prov ON prov.provedor_id=channel.proveedorId
		WHERE channel.proveedorId is NOT NULL and trans.fechaFin between @from and @to
		UNION ALL
		SELECT DATEADD(ss, -(tAntesXfer + tDespuesXfer),fechaFin) AS [date],
		0 AS [camp_id], cci.Inbound_id AS [inbund_id],cci.[User_id] AS [user_id],  
		channel.proveedorId AS [proveedorId],prov.descrip AS provedor,tipoLlam.tipoLlamada_id AS [tipollamadaId],
		tipoLlam.descrip AS [tipoLlamada],CEILING((tAntesXfer+tDespuesXfer +1 ) / 60.0 )AS [mins],   
		dbo.fnGetCstoTarifa(trans.tipoLlamada_id, 
		channel.proveedorId, tAntesXfer+tDespuesXfer+1) AS [costo]
		FROM	
		ccLogTransfers  trans 
		INNER JOIN ccCallsIn cci ON cci.cal_id=trans.cal_id AND tipo = 1
		INNER JOIN cstoTipoLlamada tipoLlam ON  tipoLlam.country_id = @country AND tipoLlam.tipoLlamada_id = trans.tipoLlamada_id
		LEFT JOIN ccChannelTransfer channel ON channel.pbxId=trans.pbxId AND trans.channel BETWEEN channel.startChannel AND channel.endChannel
		LEFT JOIN cstoProvedor prov ON prov.provedor_id=channel.proveedorId
		WHERE channel.proveedorId is NOT NULL and trans.fechaFin between @from and @to and modo NOT IN (1,2)
	)x
	WHERE [costo] > 0
	GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), [date], 121) + '':00'', 121),[camp_id],[inbund_id],[user_id],[proveedorId],provedor,[tipollamadaId],[tipoLlamada]
		

	SELECT CONVERT(smalldatetime, CONVERT(VARCHAR(13), cal_inicio, 121) + '':00'', 121) AS date
	, cam_id,inboundId, [user_id],
	provedor_id, tipoLlamada_id , 
	MIN(tipoLlamada) AS tipoLlamada
	, COUNT(*) AS amount
	, SUM( mins) AS mins
	, SUM( costo ) AS costo
	, SUM( costo ) * @iva AS costoIva
	INTO #TempOutCallBilling
	FROM
	(
		SELECT cal_inicio, cco.cam_id AS cam_id,0 AS inboundId, cco.user_id AS user_id, cco.provedor_id,
		cco.tipoLlamada_id, t.descrip AS tipoLlamada, CEILING((cal_tXfer + cal_tRing + totalCall_Time +1 ) / 60.0 ) AS mins, 
		dbo.fnGetCstoTarifa(cco.tipoLlamada_id, cco.provedor_id, cco.totalCall_Time) AS costo
		FROM ccoCallsOut cco
		INNER JOIN cstoTipoLlamada t with(index(IX_cstoTipoLlamada),nolock) ON cco.tipoLlamada_id = t.tipoLlamada_id AND country_id = @country
		WHERE cal_inicio >= @FROM AND  cal_inicio < @to AND cco.provedor_id is NOT NULL AND cal_manual in (0,2) 
		UNION ALL
		---- Tambien las llamdas que fueron fax
		SELECT cco.fecha AS fecha, cco.cam_id,0 AS inboundId,0 AS userId, p.provedor_id, l.tipoLlamada_id,l.descrip AS tipoLlamada,1 AS mins, t.MinutoUno AS costo
		FROM ccoLogDials  cco with(index(IX_ccoLogDials),nolock)
		INNER JOIN ccoDialers cd with(index(IX_ccoDialers),nolock)  ON cco.puerto = cd.puerto
		INNER JOIN cstoProvedor p ON cd.provedor_id = p.provedor_id
		INNER JOIN cstoTarifa t ON  p.provedor_id = t.provedor_id and cco.tipoLlamada_id = t.tipoLlamada_id
		INNER JOIN cstotipollamada l on cco.tipoLlamada_id = l.tipoLlamada_id and country_id = @country	
		WHERE cco.fecha >=  @FROM AND cco.fecha < @to  AND cco.answerbit = 1 AND cco.tiporesdial_id <> 1
	) costo
	GROUP BY CONVERT(smalldatetime, CONVERT(VARCHAR(13), cal_inicio, 121) + '':00'', 121), cam_id,inboundId, [user_id], provedor_id, tipoLlamada_id
		

	INSERT RepOutCallBilling
	SELECT [date], [cam_id],[campACDDescription],[user_id],[agentName],[username],[provedor_id],[provedor],[tipoLlamada_id],
	(CASE WHEN tipo = ''amount'' THEN ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''Calls_Count''
	WHEN tipo = ''mins'' THEN + ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''MinBilled_Count''
	WHEN tipo = ''costo'' THEN + ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''Cost_Count''
	WHEN tipo = ''costoIva'' THEN + ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''Tax_Count''
	ELSE tipo END ) AS tipoLLamada_Count
	,CONVERT(VARCHAR,[tipollamada_Count])  AS [count]
	,[tipoLLamada] AS tipoLlamadaDesp, CASE WHEN tipo = ''costo'' THEN CONVERT(int,CONVERT(DECIMAL(10,2),[tipollamada_Count]) ) ELSE 0 END
	,DATEPART(yyyy,[date]) AS [year],DATEPART(mm,[date]) AS [month],DATEPART(dd,[date]) AS [day],DATEPART(hh,[date]) AS [hour],
	DATEPART(mi,[date]) AS [min],inboundId AS [inboundId],[dialId],[dialType]
	FROM(
		SELECT [date], temp.cam_id AS cam_id,inboundId,''Camp - '' + camps.cam_descripcion AS campACDDescription,
		ISNULL(ccuse.[user_id] ,0) AS [user_id], CASE WHEN ccuse.[user_id] IS NULL THEN ''systemTranslated_NoName'' ELSE  ccuse.Nombres+'' ''+ ccuse.ApellidoPaterno+'' ''+ccuse.ApellidoMaterno END AS agentName,
		CASE WHEN ccuse.[Login] IS NULL THEN ''systemTranslated_NoUserName'' ELSE ccuse.[Login] END AS username,
		temp.provedor_id AS provedor_id, prov.descrip AS provedor,
		[tipoLlamada_id], [tipoLLamada],[tipoLLamada] AS tipoLlamadaDesp,
		CONVERT(VARCHAR,[amount]) AS [amount], CONVERT(VARCHAR,[mins]) AS [mins], CONVERT(VARCHAR,[costo]) AS [costo], CONVERT(VARCHAR,[costoIva]) AS [costoIva]
		,di.id AS [dialId],
		di.[description] AS [dialType]
		FROM #TempOutCallBilling temp
		INNER JOIN ccCamps camps ON camps.cam_id = temp.cam_id
		LEFT JOIN ccUserView ccuse ON ccuse.[User_id] = temp.[user_id]
		INNER JOIN cstoprovedor prov ON prov.provedor_id = temp.provedor_id
		INNER JOIN Dials di ON di.Id = 2
		UNION ALL
		SELECT [date] ,	camId ,	inboundId ,
		CASE WHEN camps.cam_descripcion IS NULL THEN ''ACD - '' + cci.descripcion ELSE ''Camp - ''+ camps.cam_descripcion END AS campACDDescription
		,ISNULL(ccuse.[user_id] ,0) AS [user_id], CASE WHEN ccuse.[user_id] IS NULL THEN ''systemTranslated_NoName''  ELSE  ccuse.Nombres+'' ''+ ccuse.ApellidoPaterno+'' ''+ccuse.ApellidoMaterno END AS agentName,
		CASE WHEN ccuse.[Login] IS NULL THEN ''systemTranslated_NoUserName'' ELSE ccuse.[Login] END AS username 
		,[proveedorId] ,provedor,[tipollamadaId],[tipoLlamada] ,[tipoLlamada] [tipoLlamadaDesp] 
		,CONVERT(VARCHAR,[amount]) AS [amount], CONVERT(VARCHAR,[mins]) AS [mins], CONVERT(VARCHAR,[costo]) AS [costo], CONVERT(VARCHAR,[costoIva]) AS [costoIva]
		,di.Id AS [dialId],
		di.[description] AS [dialType]
		FROM #TempTransCallBilling temp
		LEFT JOIN ccCamps camps ON camps.cam_id = temp.camId
		LEFT JOIN ccinbound cci ON cci.Inbound_id=temp.inboundId 
		LEFT JOIN ccUserView ccuse ON ccuse.[User_id] = temp.userId
		INNER JOIN Dials di ON di.Id = 1
	) p
	UNPIVOT
		([tipollamada_Count] for tipo IN
		([amount], [mins], [costo], [costoIva])
	)AS unpvt
	DROP TABLE #TempOutCallBilling
	DROP TABLE #TempTransCallBilling	
END'
		EXEC (@sql)


		SET @process = 'CW-3154 ALTER PROCEDURE dbo.ccspRepOutCallsDetail'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
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
	SELECT Call.cal_inicio AS [date], Call.cal_key AS [callKey], Call.cal_telefono AS [telephone], Call.cal_txfer + call.cal_tring AS [transfer], 
	Call.cal_tdialog AS [dialog], ISNULL(Call.cal_tMoh, 0) AS [nque], Call.cal_tnotas AS [wrapup], ISNULL(Tipo.[description], '''') AS [CallDisposition], 
	Call.cal_extension AS [extension], isnull(Usr.user_id, 0) AS [userId], ISNULL(convert(VARCHAR(255), Usr.LOGIN), ''systemTranslated_NoUserName'') [login], 
	ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username], camps.cam_id AS [campaignId], 
	ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign], (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration], 
	convert(decimal(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60))) AS [ncost],
	@IVA AS iva, 
	convert(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60)) * (1 + (@IVA / 100.00))) AS total,
	CASE WHEN prov.descrip IS NOT NULL THEN prov.descrip WHEN cstoProvedor.descrip IS NOT NULL THEN cstoProvedor.descrip ELSE 
				''systemTranslated_NoCarrier'' END AS [ByCarrier], ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [Calltypes], 
				CASE WHEN Call.cal_manual = 0 THEN ''systemTranslated_Auto'' ELSE ''systemTranslated_Manual'' END AS [dialType], 
				CASE WHEN cal_whoHung = 0 THEN ''systemTranslated_Client'' WHEN cal_whoHung = 1 THEN ''systemTranslated_Agent'' ELSE ''systemTranslated_AgentSurvey'' END [whoHangUp], 
				CASE WHEN call.califsub_id = 0 THEN ''systemTranslated_NoSubDisposition'' ELSE isnull(sub.califSubDesc, '''') END AS [subDisposition], sta.descripcion AS [dialResult], 
				Call.cal_id AS [calId], datepart(yyyy, Call.cal_inicio) AS [year], datepart(mm, Call.cal_inicio) AS [month], datepart(dd, Call.cal_inicio) AS [day], 
				datepart(hh, Call.cal_inicio) AS [hour], datepart(mi, Call.cal_inicio) AS [minutes], Call.cal_puerto, ISNULL(cs.Dato1, '''') AS [data1], ISNULL(cs.Dato2, '''') AS [data2], 
				ISNULL(cs.Dato3, '''') AS [data3], ISNULL(cs.Dato4, '''') AS [data4], ISNULL(cs.Dato5, '''') AS [data5], ISNULL(Call.cal_tMsg, 0) AS [MessageTime]
	FROM ccoCallsOut Call
	LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id = Tipo.calif_id
	LEFT JOIN ccUserView Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
	LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]
	LEFT JOIN ccStatusLlamada sta ON call.statuscall_id = sta.statuscall_id
	LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] AND tl.Country_id = @country)
	LEFT JOIN ccTipoCalifSubOut sub ON call.califsub_id = sub.califsub_id
	LEFT JOIN ccoDialers di ON di.dialer_id = Call.cal_puerto
	LEFT JOIN ccoCallsOutSource cs ON Call.callout_id = cs.callout_id
	LEFT JOIN cstoProvedor ON di.provedor_id = cstoProvedor.provedor_id
	WHERE Call.cal_inicio >= @from AND Call.cal_inicio < @to AND cal_manual IN (0, 2)
	ORDER BY DATE
END'
		EXEC (@sql)



		--IF @actualVersion = @version - 1
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
