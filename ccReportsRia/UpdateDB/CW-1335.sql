/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Karen Rodriguez
Date: 2018/03/01
Description:
**********************************************************************************************
CW-1043 - faltan relaciones en las tablas de survey
**********************************************************************************************
Database: ccReportsRia
Required version: 46


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =50
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try

	set @process = 'CW-1335 -- VERSION 49  DROP FUNCTION fnGetCstoTarifa IF IT EXISTS'
    set @Sql= 'IF object_id(N''dbo.fnGetCstoTarifa'', N''FN'') IS NOT NULL
	DROP FUNCTION dbo.fnGetCstoTarifa'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49  CREATE TABLE DIALS'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N''Dials'')
BEGIN
    CREATE TABLE Dials(
	id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[description] varchar(250),
) 
END'
	EXEC(@Sql)

	
	set @process = 'CW-1335 -- VERSION 49  CREATE FUNCTION fnGetCstoTarifa'
    set @Sql= 'CREATE FUNCTION [dbo].[fnGetCstoTarifa](@tipoLlamada_id TINYINT, @provedor_id SMALLINT, @callTime INT)
RETURNS DECIMAL(10,3)  
AS
BEGIN
	DECLARE @minutouno DECIMAL(10,3)  
	DECLARE @minutoadicional DECIMAL(10,3)
	DECLARE  @costo DECIMAL(10,3)
	SELECT @minutouno = minutouno, 
		@minutoadicional = minutoadicional
		FROM cstoTarifa 
		WHERE tipollamada_id =  @tipoLlamada_id and @provedor_id = provedor_id
	SELECT @costo = @MinutoUno + CASE WHEN ISNULL(@callTime,0) > 0 
		THEN((CEILING(( ISNULL(@callTime,0) ) / 60.0 )- 1) * @MinutoAdicional ) 
		ELSE 0 
		END
	RETURN ISNULL(@costo, 0)
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49  ADD INBOUND COLUMN INTO REPOUTCALLBILLING'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''inboundId'' AND Object_ID = Object_ID(N''RepOutCallBilling''))
BEGIN
	ALTER TABLE [RepOutCallBilling]
	ADD inboundId SMALLINT
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49  ADD DIALID COLUMN INTO REPOUTCALLBILLING'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''dialId'' AND Object_ID = Object_ID(N''RepOutCallBilling''))
BEGIN
	ALTER TABLE [RepOutCallBilling]
	ADD dialId INT
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49  ADD DIALTYPE COLUMN INTO REPOUTCALLBILLING'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''dialType'' AND Object_ID = Object_ID(N''RepOutCallBilling''))
BEGIN
	ALTER TABLE [RepOutCallBilling]
	ADD [dialType] VARCHAR(250)
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49 RENAME COLUMN TO CAMPACDDESCRIPTION'
    set @Sql= 'IF EXISTS (SELECT * FROM sys.columns WHERE name = N''campaign'' AND Object_ID = Object_ID(N''RepOutCallBilling''))
BEGIN
    EXEC sp_RENAME ''RepOutCallBilling.campaign'' , ''campACDDescription'', ''COLUMN''
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49  MODIFY SP ccspRepOutCallBilling'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepOutCallBilling]
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
	---creamos tabla temporal con longitud
	IF EXISTS(SELECT longitud FROM cstoTipoLlamada WHERE CHARINDEX(''|'',longitud)<>0 AND country_id =@country) 
	BEGIN
		DECLARE @longitud VARCHAR(10)
		DECLARE @tipollamada INT
		DECLARE @prefijo VARCHAR(50)
		DECLARE @descrip VARCHAR(50)
		SELECT @longitud = CONVERT(VARCHAR(10),longitud),@descrip=descrip,@prefijo=prefijo, @tipollamada= tipoLlamada_id FROM cstoTipoLlamada WHERE CHARINDEX(''|'',longitud)<>0 AND country_id =@country
	END

	CREATE TABLE #cstoTipoLlamadaTemp(
		tipoLlamada_id SMALLINT NOT NULL,
		descrip VARCHAR(50) collate SQL_Latin1_General_CP1_CI_AS NOT NULL ,
		prefijo VARCHAR(50) collate SQL_Latin1_General_CP1_CI_AS NOT NULL,
		longitud INT NOT NULL
	)

	CREATE INDEX IX_CstoTipoLlamadaTemp ON #cstoTipoLlamadaTemp (longitud,tipoLlamada_id)

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
		CEILING((tAntesXfer+tDespuesXfer +1 ) / 60.0 )AS [mins], dbo.fnGetCstoTarifa(dbo.fnGetTipoLlamada(trans.destino), 
		channel.proveedorId, tAntesXfer+tDespuesXfer+1) AS [costo]
		FROM 
		ccLogTransfers  trans 
		INNER JOIN ccoCallsOut cco ON cco.cal_id=trans.cal_id AND tipo = 2
		INNER JOIN cstoTipoLlamada tipoLlam ON  tipoLlam.country_id = @country AND tipoLlam.tipoLlamada_id = dbo.fnGetTipoLlamada(trans.destino)
		LEFT JOIN ccChannelTransfer channel ON channel.pbxId=trans.pbxId AND trans.channel BETWEEN channel.startChannel AND channel.endChannel
		LEFT JOIN cstoProvedor prov ON prov.provedor_id=channel.proveedorId
		WHERE channel.proveedorId is NOT NULL and trans.fechaFin between @from and @to
		UNION ALL
		SELECT DATEADD(ss, -(tAntesXfer + tDespuesXfer),fechaFin) AS [date],
		0 AS [camp_id], cci.Inbound_id AS [inbund_id],cci.[User_id] AS [user_id],  
		channel.proveedorId AS [proveedorId],prov.descrip AS provedor,tipoLlam.tipoLlamada_id AS [tipollamadaId],
		tipoLlam.descrip AS [tipoLlamada],CEILING((tAntesXfer+tDespuesXfer +1 ) / 60.0 )AS [mins],   
		dbo.fnGetCstoTarifa(dbo.fnGetTipoLlamada(trans.destino), 
		channel.proveedorId, tAntesXfer+tDespuesXfer+1) AS [costo]
		FROM	
		ccLogTransfers  trans 
		INNER JOIN ccCallsIn cci ON cci.cal_id=trans.cal_id AND tipo = 1
		INNER JOIN cstoTipoLlamada tipoLlam ON  tipoLlam.country_id = @country AND tipoLlam.tipoLlamada_id = dbo.fnGetTipoLlamada(trans.destino)
		LEFT JOIN ccChannelTransfer channel ON channel.pbxId=trans.pbxId AND trans.channel BETWEEN channel.startChannel AND channel.endChannel
		LEFT JOIN cstoProvedor prov ON prov.provedor_id=channel.proveedorId
		WHERE channel.proveedorId is NOT NULL and trans.fechaFin between @from and @to
	)x
	WHERE [costo] > 0
	GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), [date], 121) + '':00'', 121),[camp_id],[inbund_id],[user_id],[proveedorId],provedor,[tipollamadaId],[tipoLlamada]
		
	INSERT INTO #cstoTipoLlamadaTemp
	SELECT tipoLlamada_id,descrip,prefijo,longitud
	FROM (
		SELECT tipoLlamada_id,descrip,prefijo,longitud FROM cstoTipoLlamada
		WHERE CHARINDEX(''|'',longitud)=0 AND country_id = @country
		union all
		SELECT @tipollamada AS tipoLlamada_id,@descrip AS descrip,@prefijo AS prefijo, Value AS longitud
		FROM dbo.fn_RIASplitDelimited(@longitud,''|'') WHERE @tipollamada is NOT NULL
	)x

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
		INNER JOIN cstoTarifa t ON  p.provedor_id = t.provedor_id
		INNER JOIN #cstoTipoLlamadaTemp l ON  l.longitud = len(cco.telefono) AND t.tipoLlamada_id = l.tipoLlamada_id
		WHERE cco.fecha >=  @FROM AND cco.fecha < @to  AND cco.answerbit = 1 AND cco.tiporesdial_id <> 1
		AND cco.telefono like l.prefijo
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
		LEFT JOIN ccUsers ccuse ON ccuse.[User_id] = temp.[user_id]
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
		LEFT JOIN ccUsers ccuse ON ccuse.[User_id] = temp.userId
		INNER JOIN Dials di ON di.Id = 1
	) p
	UNPIVOT
		([tipollamada_Count] for tipo IN
		([amount], [mins], [costo], [costoIva])
	)AS unpvt
	DROP TABLE #TempOutCallBilling
	DROP TABLE #cstoTipoLlamadaTemp
	DROP TABLE #TempTransCallBilling	
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49 UPDATE INBOUNDID TO 0 WHERE INBOUNDID IS NULL'
    set @Sql= 'IF EXISTS (SELECT * FROM sys.columns WHERE name = N''inboundId'' and Object_ID = Object_ID(N''RepOutCallBilling''))
BEGIN
    UPDATE [RepOutCallBilling] 
	SET inboundId = 0
		WHERE inboundId = NULL
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- UPDATE DIALID TO 2 WHERE DIALID IS NULL'
    set @Sql= 'IF EXISTS (SELECT * FROM sys.columns WHERE name = N''dialId'' and Object_ID = Object_ID(N''RepOutCallBilling''))
BEGIN
    UPDATE [RepOutCallBilling] 
	SET dialId = 2
		WHERE dialId = NULL
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- UPDATE DIALTYPE TO systemTranslated_Out WHERE DIALTYPE IS NULL'
    set @Sql= 'IF EXISTS (SELECT * FROM sys.columns WHERE name = N''dialType'' and Object_ID = Object_ID(N''RepOutCallBilling''))
BEGIN
   UPDATE [RepOutCallBilling] 
	SET [dialType] = ''systemTranslated_Out''
		WHERE [dialType] = NULL
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49 RENAME RECORDS FROM CAMPACDDESCRIPTION'
    set @Sql= 'IF EXISTS (SELECT * FROM sys.columns WHERE name = N''campaign'' AND Object_ID = Object_ID(N''RepOutCallBilling''))
BEGIN
	UPDATE RepOutCallBilling 
	SET campACDDescription = ''Camp - '' + campACDDescription
		WHERE campACDDescription <> ''Camp - '' + campACDDescription AND campACDDescription <> ''ACD'' + campACDDescription
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49 RENAME PIVOT TO CAMPACDDESCRIPTION AND ADD DIALTYPE AND DIALID'
    set @Sql= 'IF EXISTS (SELECT * FROM sys.columns WHERE name = N''complementColumns'' and Object_ID = Object_ID(N''PivotReports''))
BEGIN
    UPDATE PivotReports 
	SET complementColumns=''date|inboundId|campaignId|campACDDescription|userId|agentName|username|providerId|provider|dialId|dialType'' 
		WHERE id=4060
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49  ADD DIALTYPE COLUMN TO TRANSLATE YOUR RECORDS'
    set @Sql= 'IF EXISTS (SELECT * FROM sys.columns WHERE name = N''columns'' and Object_ID = Object_ID(N''TranslatedReports''))
BEGIN
	UPDATE TranslatedReports 
	SET [columns] = ''agentName|username|dialType''
	WHERE id= 4060
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49  CHANGE X1 VALUE FOR campACDDescription'
    set @Sql= 'IF EXISTS (SELECT * FROM sys.columns WHERE name = N''x1'' and Object_ID = Object_ID(N''ReportsCharts''))
BEGIN
	UPDATE ReportsCharts
	SET x1 = ''campACDDescription''
	WHERE id=4060 AND chartType =1
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49  CHANGE SUBX1 VALUE FOR campACDDescription'
    set @Sql= 'IF EXISTS (SELECT * FROM sys.columns WHERE name = N''subx1'' and Object_ID = Object_ID(N''ReportsCharts''))
BEGIN
	UPDATE ReportsCharts
	SET subx1 = ''campACDDescription''
	WHERE id=4060 AND chartType =2
END'
	EXEC(@Sql)
	
	set @process = 'CW-1335 -- VERSION 49  INSERT VALUE XFER INTO DIALS'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM Dials WHERE description = ''systemTranslated_Xfer'')
BEGIN
    INSERT INTO Dials VALUES (''systemTranslated_Xfer'')
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49  INSERT VALUE OUT INTO DIALS'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM Dials WHERE description = ''systemTranslated_Out'')
BEGIN
    INSERT INTO Dials VALUES (''systemTranslated_Out'')
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49  INSERT DIALS FILTER INTO FILTERS'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM Filters WHERE id = 30 OR name = ''dial'')
BEGIN
    INSERT INTO Filters VALUES (30, ''dial'', 30, ''Dials'', ''Dial'')
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49  INSERT ACD FILTER INTO REPORTSFILTERS'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsFilters] WHERE [id] = 4060 AND [filterName] = ''acds'')
BEGIN
    INSERT [dbo].[ReportsFilters]([reportName],[filterName],[id])
    VALUES (''Call Billing'',''acds'', 4060)
END'
	EXEC(@Sql)

	set @process = 'CW-1335 -- VERSION 49  INSERT DIAL FILTER INTO REPORTSFILTERS'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsFilters] WHERE [id] = 4060 AND [filterName] = ''dial'')
BEGIN
    INSERT [dbo].[ReportsFilters]([reportName],[filterName],[id])
    VALUES (''Call Billing'', ''dial'', 4060)
END'
	EXEC(@Sql)

		if @actualVersion  = @version - 1
	 	exec ccsp_getVersion 'BD', @version


	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off