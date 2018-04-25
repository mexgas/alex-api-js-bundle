/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Mike Trejo
		Karen Rodríguez
Date: 2018/03/28
Description:
**********************************************************************************************
CW-1697 - Agrega reporte nuevo con vista en la tabla repAgentGI
CW-1043 - faltan relaciones en las tablas de survey
**********************************************************************************************
Database: ccReportsRia
Required version: 47


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =51
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try


	set @process = 'Elimina funcion [FNTruncateToDecimal]-- CW-1697'
    	set @Sql= 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''[FNTruncateToDecimal]'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
begin
drop function [FNTruncateToDecimal]
end'
		EXEC(@Sql)

		set @process = 'Elimina funcion [FNnoRoundGroupByReports]-- CW-1697'
    	set @Sql= 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''[FNnoRoundGroupByReports]'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
begin
drop function [FNnoRoundGroupByReports]
end'
		EXEC(@Sql)

	set @process = 'Elimina Vista RepViewAgentGISpecial-- CW-1697'
    	set @Sql= 'if exists (select * FROM sys.views where name = N''RepViewAgentGISpecial'')
begin
drop view RepViewAgentGISpecial
end'
		EXEC(@Sql)

		set @process = 'CW-1335 -- VERSION 49  DROP FUNCTION fnGetCstoTarifa IF IT EXISTS'
    set @Sql= 'IF object_id(N''dbo.fnGetCstoTarifa'', N''FN'') IS NOT NULL
	DROP FUNCTION dbo.fnGetCstoTarifa'
	EXEC(@Sql)

	set @process = 'Drop SP ccspRepOutAnswAndXferCalls -- CW-1331'
    set @Sql= 'if exists (select * from sys.procedures where name = N''ccspRepOutAnswAndXferCalls'')
    begin
        DROP PROCEDURE ccspRepOutAnswAndXferCalls;
    end'
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

	set @process = 'Crear funcion [FNTruncateToDecimal]-- CW-1697'
    	set @Sql= 'Create FUNCTION [dbo].[FNTruncateToDecimal] (@Valor float)
RETURNS  float
AS
begin
Declare @NumConverted as float;
set @NumConverted=(cast((cast(@Valor*100 as int)/100.00)/3600.00 as decimal(18,2)))
	return @NumConverted
END'
		EXEC(@Sql)


		set @process = 'Crear funcion [FNnoRoundGroupByReports]-- CW-1697'
    	set @Sql= 'create FUNCTION [dbo].[FNnoRoundGroupByReports] (@Valor float)
RETURNS  float
AS
begin
Declare @NumConverted as float;

set @NumConverted=(cast((cast(@Valor*100 as int)/100.00)/3600.00 as decimal(18,2)))
	return @NumConverted
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

	set @process = 'Crear vista de la tabla RepAgentGIl-- CW-1697'
    	set @Sql= 'CREATE VIEW RepViewAgentGISpecial AS
select * from RepAgentGI'
		EXEC(@Sql)

	set @process = 'Crear tabla RepOutAnswAndXferCalls -- CW-1331'
    set @Sql= 'if not exists (select * from sys.tables where name = N''RepOutAnswAndXferCalls'')
    begin
        CREATE TABLE RepOutAnswAndXferCalls (
			[date] [datetime] NOT NULL,
			[callid] [int] NOT NULL,
			[campaignId] [int] NOT NULL,
			[campaign] [varchar](255) NOT NULL,
			[userId] [int] NOT NULL,
			[Agent] [varchar](255) NOT NULL, 
			[dialog] [int] NOT NULL,
			[telephone] [varchar](255) NOT NULL,
			[dialId] int NOT NULL,
			[dialType] [varchar](255) NOT NULL,
			[CallTypes] [varchar](255) NOT NULL,
			[ncost] decimal NOT NULL,
			[iva] int NOT NULL,
			[total] decimal NOT NULL
		) ON [PRIMARY]
    end'
	EXEC(@Sql)

	set @process = 'Crear tabla dialType -- CW-1331'
    set @Sql= 'if not exists (select * from sys.tables where name = N''RepOutAnswAndXferCalls'')
    begin
        CREATE TABLE dialType (
			[dialId] [int] NOT NULL PRIMARY KEY,
			[description] [varchar] (100) NOT NULL
		)
    end'
	EXEC(@Sql)

	set @process = 'Crear SP ccspRepOutAnswAndXferCalls -- CW-1331'
    set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
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
	select Call.cal_inicio as [date],
	Call.cal_id as [callid],
	camps.cam_id as [campaignId],
	ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign],
	Usr.user_id as [userId],
	ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') as [Agent],
	ISNULL(Call.totalCall_Time, 0) as [dialog],
	Call.cal_telefono as [telephone],
	Call.cal_manual as [dialId],
	(select [description] from dialType where dialId = Call.cal_manual) as [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
	dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, Call.totalCall_Time) as [ncost],
	@IVA as iva,
	convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, Call.totalCall_Time),0.00) * (1 + (@IVA / 100.00))) as total
	from ccoCallsOut Call
	LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]
	INNER JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = @country)
	INNER JOIN ccoLogDials ccld on ccld.cal_id = Call.cal_id and ccld.answerbit = 1
	where Call.cal_inicio >= @from
    and Call.cal_inicio < @to
	order by date

	insert into RepOutAnswAndXferCalls
	select dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) as [date],
	clt.cal_id as [callid],
	'''' as [campaignId],
	'''' as [campaign],
	(case tipo when 1 then ci.User_id else co.User_id end) as [userId],
	isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccusers nolock where user_id = 
	(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') as [Agent],
	ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) as [dialog],
	case when modo = 0 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino)  
	when modo = 3 then isnull((select tel from telefonosConferencia where tel = clt.destino),clt.destino) 
	when modo = 4 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino) 
	when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end as [telephone],
	3 as [dialId],
	(select [description] from dialType where dialId = 3) as [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
	ISNULL(dbo.fnGetCstoTarifa(dbo.fnGetTipoLlamada(clt.destino), channel.proveedorId, clt.tAntesXfer+clt.tDespuesXfer), 0) as [ncost],
	@IVA as iva,
	convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(dbo.fnGetTipoLlamada(clt.destino), channel.proveedorId, clt.tAntesXfer+clt.tDespuesXfer),0.00) * (1 + (@IVA / 100.00))) as [total]
	from cclogtransfers clt
	LEFT JOIN cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1
	LEFT JOIN ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
	LEFT JOIN ccChannelTransfer channel on clt.pbxId=channel.pbxId and clt.channel between channel.startChannel and channel.endChannel
	LEFT JOIN cstoTarifa tarifa on tarifa.provedor_id=channel.proveedorId and tarifa.tipoLlamada_id=dbo.fnGetTipoLlamada(clt.destino)
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = dbo.fnGetTipoLlamada(clt.destino) and tl.Country_id = @country)
	where clt.modo not in (1,2) 
	and (clt.tAntesXfer > 0 or clt.tDespuesXfer > 0)
	and dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) >= @from
    and dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) < @to
	order by date 

end'
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
		WHERE channel.proveedorId is NOT NULL and trans.fechaFin between @from and @to and modo NOT IN (1,2)
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

	set @process = 'Modificacion al SP ccspRepCatalogos-- CW-1331'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepCatalogos]
@type as tinyint,
@action tinyint = 0 -- 0 Filter select; 1 Filters Range
,@userId int =0 ---- se agrega parametro para filtros

AS
declare @tablatemp table (id int,
						description varchar(100) null)
declare @tempwork table
(idwg int)

if @action = 0
begin


	-- CAMPAIGNS
if @type = 1
begin

		if @userId <> 0 begin

			insert into @tablatemp
			select distinct caesp.IdCampEsp,'''' as description  from ccUsers us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
			inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1
			where us.[User_id] = @userId

			SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn
				from ccCamps camp
				inner join @tablatemp A on camp.cam_id = A.id

		end
		else begin
			SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn
				from ccCamps camp

		end
end


	-- DIAL RESULTS
	if @type = 2
	begin
		Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
		from ccTipoResultadoDial
		order by descripcion
	end

	-- WORKGROUPS
	if @type = 3
	begin
		if @userId <> 0 begin

			insert into @tempwork
			select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

			select distinct catwor.IDWG as id,catwor.WGName as description,''workgroupId'' as dbColumn from ccRIAWorkGroupUsers wgu
			inner join ccRIACat_WorkGroup catwor on wgu.IDWG = catwor.IDWG
			left join @tempwork temp on wgu.IDWG = temp.idwg
			where catwor.StatusWorkGroup = 1
			return
		end
		else  begin
			select idwg as id, wgname as description, ''workgroupId'' as dbColumn
			from ccRIACat_WorkGroup
			group by idwg, wgname	select * from ccRIACat_WorkGroup
			order by wgname
		end
  end


	-- AREAS
	if @type = 4
	begin
	if @userId <> 0 begin

			insert into @tablatemp
			select distinct wgu.User_id,caesp.IDArea  from ccUsers us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
			left join ccUsers caesp on wgu.IDWG = caesp.User_id
			where us.[User_id] = @userId

			select distinct idArea as id, AreaName as description, ''areaId'' as dbColumn
			from ccRIACat_Areas area inner join @tablatemp tem on area.IDArea = tem.id
			return
	end
		else begin

			select idArea as id, AreaName as description, ''areaId'' as dbColumn
			from ccRIACat_Areas
			group by idArea, AreaName
			order by AreaName
		end
	end

	-- DISPOSITIONS OUT
	if @type = 5
	begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalifOut
		order by [description]
	end

	-- USE
	if @type = 6
	begin
	if @userId <> 0 begin

			insert into @tempwork
					select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

			select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUsers us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

			inner join @tempwork awg on wgu.IDWG = awg.idwg
			where us.TipoUser_id = 1 and [status] = 1

			return
		end

		else begin

			SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
			FROM ccUsers B WHERE [status] = 1 and TipoUser_id = 1
			ORDER BY description
		end
	end

	-- ACDS**************
	if @type = 7
	begin
		if @userId <> 0 begin
				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''' as description  from ccUsers us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
				inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
				where us.[User_id] = @userId


				SELECT inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
					from ccinbound B
					inner join @tablatemp A on B.inbound_id = A.id
					return
			end
			else begin
				select inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
					from ccinbound
			end
	end

	-- DIDS
	if @type = 8
	begin
		select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
		from ccdnis
	end

	--DISPOSITIONS IN
	if @type = 9
	begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalif
		order by [description]
	end

	--SUBDISPOSITIONS IN
	if @type = 10
	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM ccTipoCalifSub
		order by [description]
	end

	--PROVIDER
	if @type = 11
	begin
		SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
		FROM cstoProvedor
		order by [description]
	end

	-- UNAVAILABLES
	if @type = 12
	begin
		SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
		FROM cctiponotready
		order by descripcion
	end

	-- DIALERS
	if @type = 13
	begin
		SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
		FROM ccoDialers
		order by descripcion
	end

	-- CallTYpes
	if @type = 14
	begin
			SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
			FROM ccStatusLlamada
		order by descripcion
	end

	-- SUBDISPOSITIONS OUT
	if @type = 21
	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM cctipocalifsubout
		order by [description]
	end

	-- AVRS TEMPLATE-SECTION
	if @type = 15
	begin
		SELECT c.id_concepto as id, (t.nombre+''-''+c.con_descripcion) as description, ''sectionId'' as dbColumn
		FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,nombre,MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato,nombre) as t
		ON f.id_formato = t.id_formato AND f.version = t.version INNER JOIN RIA_CONCEPTOS c
		ON t.id_formato = c.id_formato AND t.version = c.version
		order by f.nombre
	end

	-- AVRS TEMPLATES
	if @type = 16
	begin
		SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
		FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato) as t
		ON f.id_formato = t.id_formato AND f.version = t.version
		order by f.nombre
	end

	-- AVRS SUPERVISOR
	if @type = 17
	begin
		SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
		FROM ccUsers
		WHERE [status] = 1
		and TipoUser_id = 2
		ORDER BY [login]
	end

	--Status Call
	if @type = 25
	begin
		select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
		from ccstatusllamada
		order by [descripcion]
	end

	--Survey
	if @type = 26
	begin
	select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
	from Survey
	order by [description]
	end

	--dialType
	if @type = 29
	begin
		select dialId as id, [description] as description, ''dialId'' as dbcolumn
		from dialType
		order by [description]
	end

	--dial
	if @type = 30
	begin
		select id as id, [description] as description, ''dialId'' as dbcolumn
		from Dials
		order by [description]
	end

end
-----------------------------------------------------------
if @action = 1
begin
	-- TRUNKS
	if @type = 13
	begin
		SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
	end

	-- AVRS DISPOSITION
	if @type = 18
	begin
		SELECT 0 as [min], 100 as [max],''Disposition'' as dbColumn
	end

	-- AVG DISPOSITION
	if @type = 19
	begin
		SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
	end

	-- SCORE
	if @type = 20
	begin
		SELECT 0 as [min], 100 as [max],''score'' as dbColumn
	end
end'
	EXEC(@sql)

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

		set @process = 'inserta valores a ReportsFiltersmenus-- CW-1697'
    	set @Sql= 'if not exists (select * from ReportsFiltersmenus where idReport=2090)
		begin
insert ReportsFiltersmenus(idReport,filterMenuName) Values(2090,N''date'')
insert ReportsFiltersmenus(idReport,filterMenuName) Values(2090,N''filterby'')
insert ReportsFiltersmenus(idReport,filterMenuName) Values(2090,N''groupby'')
END'
		EXEC(@Sql)

		set @process = 'inserta valores a ReportsFilters-- CW-1697'
    	set @Sql= 'if not exists (select * from ReportsFilters where id=2090)
begin
insert into ReportsFilters values (''General Information Special'',''users'',2090)
END'
		EXEC(@Sql)

		set @process = 'Inserta valores a ReportsCharts-- CW-1697'
    	set @Sql= 'if not exists (select * from ReportsCharts where id=2090)
begin
insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
values (2090,''General Information Special'',1,''user'','''','''','''',''sum([tav])'',''Ready time per user'',1)
insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
values (2090,''General Information Special'',2,''year|month|day|hour'',''user'','''','''',''sum([tav])'',''Ready time per user by hour'',1)
END'
		EXEC(@Sql)

		set @process = 'Inserta valores a GroupByReports-- CW-1697'
    	set @Sql= 'if not exists (select * from GroupByReports where id=2090)
begin
insert into GroupByReports values(2090,''userId|max([user]):user|max([login]):login|[dbo].[FNnoRoundGroupByReports]((sum([tdialogout])+sum([tringout])+sum([txferout])+sum([tunknown])+sum([tother])+sum([tprob])+sum([tundefined]))):tTalkNum|[dbo].[FNnoRoundGroupByReports](sum([tnotesout])):tnotesoutNum|[dbo].[FNnoRoundGroupByReports](sum([tav])):tavNum|[dbo].[FNnoRoundGroupByReports](sum([tnotav])):tnotavNum|[dbo].[FNnoRoundGroupByReports]((sum([tdialogout])+sum([tringout])+sum([txferout])+sum([tunknown])+sum([tother])+sum([tprob])+sum([tundefined]))+(sum([tnotesout]))+(sum([tav]))+(sum([tnotav]))):TotalNum'',''userId'')
END'
		EXEC(@Sql)

		set @process = 'Inserta valores a ReportsTotals-- CW-1697'
    	set @Sql= 'if not exists (select * from ReportsTotals where id=2090)
begin
insert into ReportsTotals values (2090,''sum:nxferin|sum:nanswerin|sum:nabndxferin|sum:nabndringin|sum:nabnddlgin|sum:abndaxferin|sum:nnoanswerin|sum:nlostin|sum:tdialogin|sum:tnotesin|sum:tringin|sum:txferin|sum:nxferout|sum:nanswerout|sum:nabndxferout|sum:nabndringout|sum:nabnddlgout|sum:abndaxferout|sum:nnoanswerout|sum:nlostout|sum:tdialogout|sum:tnotesout|sum:tringout|sum:txferout|sum:nother|sum:tunknown|sum:tnotav|sum:tlog|sum:tav|sum:tother|sum:tprob|sum:nmohin|sum:nmohout|sum:nwhagin|sum:nwhagout|sum:nwhcliin|sum:nwhcliout|special:tnotavg:isnull(sum([tdialogin]+[tdialogout])/nullif(sum([nanswerin]+[nanswerout]),0),0)'')
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

	set @process = 'Insertar datos en tabla dialType -- CW-1331'
    set @Sql= 'if not exists (select * from dialType where dialId = 0)
	begin
		insert into dialtype values(0, ''systemTranslated_Auto'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla dialType -- CW-1331'
    set @Sql= 'if not exists (select * from dialType where dialId = 2)
	begin
		insert into dialtype values(2, ''systemTranslated_Manual'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla dialType -- CW-1331'
    set @Sql= 'if not exists (select * from dialType where dialId = 3)
	begin
		insert into dialtype values(3, ''systemTranslated_Xfer'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla Filters -- CW-1331'
    set @Sql= 'if not exists (select * from Filters where id=29)
	begin
		insert into Filters values(29, ''dialType'', 29, ''DialTypes'', ''DialType'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ReportsFiltersMenus -- CW-1331'
    set @Sql= 'if not exists (select * from ReportsFiltersMenus where idReport = 4250 and filterMenuName=''date'')
	begin
		insert ReportsFiltersMenus (idReport, filterMenuName) values (4250, N''date'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ReportsFiltersMenus -- CW-1331'
    set @Sql= 'if not exists (select * from ReportsFiltersMenus where idReport = 4250 and filterMenuName=''filterby'')
	begin
		insert ReportsFiltersMenus (idReport, filterMenuName) values (4250, N''filterby'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ReportsFilters -- CW-1331'
    set @Sql= 'if not exists (select * from ReportsFilters where id = 4250 and filterName = ''campaigns'')
	begin
		insert ReportsFilters values (''Answered and Transfer calls'', ''campaigns'', 4250)
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ReportsFilters -- CW-1331'
    set @Sql= 'if not exists (select * from ReportsFilters where id = 4250 and filterName = ''users'')
	begin
		insert ReportsFilters values (''Answered and Transfer calls'', ''users'', 4250)
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ReportsFilters -- CW-1331'
    set @Sql= 'if not exists (select * from ReportsFilters where id = 4250 and filterName = ''dialType'')
	begin
		insert ReportsFilters values (''Answered and Transfer calls'', ''dialType'', 4250)
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla TranslatedReports -- CW-1331'
    set @Sql= 'if not exists (select * from TranslatedReports where id=4250)
	begin
		insert into TranslatedReports values(4250, ''campaign|dialType|CallTypes|Agent|telephone'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ReportsTotals -- CW-1331'
    set @Sql= 'if not exists (select * from ReportsTotals where Id=4250)
	begin
		insert into ReportsTotals values(4250, ''sum:dialog|sum:ncost|sum:total'')
	end'
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