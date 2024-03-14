/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 128

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 130 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	---------------------------------------BEGIN Carlos Chavez release/126.20240304.0.0---------------------------------------------------------

	---------------------------------------------Llamadas de entrada->Detalle de llamadas -------------------------------------------------------------------------

SET @process = 'K061008 Create table ReportsFilteredByHourRange'
SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N''ReportsFilteredByHourRange'')
BEGIN
	CREATE TABLE ReportsFilteredByHourRange
	(
		id INT PRIMARY KEY NOT NULL,
		reportName NVARCHAR(100) NOT NULL,
		groupDayWithHHmm bit NOT NULL
	)
END'
EXEC(@sql)


SET @process = 'K061001 DROP VIEW RepViewInCallsDetail'
SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(''dbo.RepViewInCallsDetail'') AND type = ''V'')
    BEGIN
        DROP VIEW dbo.RepViewInCallsDetail
    END'
EXEC(@sql)


SET @process = 'K061001 CREATE VIEW RepViewInCallsDetail'
SET @sql = '
CREATE VIEW [dbo].[RepViewInCallsDetail] AS
SELECT
	[date] as receptionDate,
	cal_final,
	inboundId as inboundCamp,
	ACDGroup as campaign,
	callStatusId,
	callStatus,
	dispositionId,
	disposition as disposition_InCallsDetail,
	subDispositionId,
	subDisposition as sub_Disposition,
	dnisId,
	dnis as didNumber,
	userId,
	[user],
	callKey as call_Key,
	ANI as aniNumber,
	queueTime as queue_Time,
	xferTime,
	ringingTime,
	dialogTime as dialog_Time,
	mohTime as hold_Time,
	twrapup,
	AverageHandleTime as handleTime,
	extension,
	agentName,
	whoHangUp as endedBy,
	recibeCallBy,
	year,
	month,
	day,
	hour,
	minutes,
	provedorId,
	provider as provider_InCallsDetail,
	trunk as trunk_InCallsDetail,
	fileMoved,
	Dato1,
	Dato2,
	Dato3,
	Dato4,
	Dato5,
	callid as call_Id,
	grabId,
	nameDNI,
	numDNI,
	collectCall,
	timeTotalInCallSec,
	timeTotalInCallMin,
	statusCallByIVR,
	IVR_ID,
	callHung
FROM
RepInCallsDetail NOLOCK'
EXEC(@sql)


SET @process = 'K061008 Insert into ReportsFilteredByHourRange report 3010'
SET @sql = 'IF NOT EXISTS (SELECT * FROM ReportsFilteredByHourRange WHERE id = 3010) 
BEGIN
	INSERT INTO ReportsFilteredByHourRange (id, reportName, groupDayWithHHmm) VALUES (3010, ''RepViewInCallsDetail'', 0)
END'
EXEC(@sql)


SET @process = 'K061001 Update ReportsTotals id 3010'
SET @sql = '
UPDATE 
	ReportsTotals 
SET 
	totalColumns = ''sum:queue_Time|sum:xferTime|sum:ringingTime|sum:dialog_Time|sum:hold_Time|sum:twrapup''
WHERE 
	id = 3010
'
EXEC(@sql)


SET @process = 'K061001 Update TranslatedReports id 3010'
SET @sql = '
	UPDATE
		TranslatedReports
	SET
		columns = ''endedBy|fileMoved|collectCall|recibeCallBy|statusCallByIVR''
	WHERE
		id = 3010
'
EXEC(@sql)


SET @process = 'K061001 Drop SupportReportCallInIVR '
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''SupportReportCallInIVR'')
	BEGIN
	    DROP PROCEDURE SupportReportCallInIVR;
	END'
EXEC(@sql)


SET @process = 'K061001 Create SupportReportCallInIVR '
SET @sql = 'CREATE PROCEDURE [dbo].[SupportReportCallInIVR] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
	AS

	SET NOCOUNT ON

	IF @from IS NULL
		SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

	IF @to IS NULL
		SELECT @to = getdate()

	IF @action = 1
	BEGIN

		INSERT INTO RepInCallsDetail (DATE, callid, inboundId, ACDGroup, callStatusId, callStatus, dispositionId, disposition, subDispositionId, subDisposition, dnisId, dnis, userId, [user], callKey, ANI, queueTime, xferTime, ringingTime, dialogTime, extension, agentName, whoHangUp, mohTime, year, month, day, hour, minutes, provedorId, provider, trunk, fileMoved, twrapup, AverageHandleTime, Dato1, Dato2, Dato3, Dato4, Dato5, grabId, nameDNI, numDNI, collectCall, timeTotalInCallSec, timeTotalInCallMin, statusCallByIVR, IVR_ID, callHung, recibeCallBy, cal_final)
		SELECT b.date, 
			0,--a.cal_id,
			0,--a.Inbound_id,
			'''' AS Inbound, 
			0,--a.statusCall_id, 
			'''' AS statusCall, 
			0,--a.calif_id, 
			'''' AS calif, 
			0,--ISNULL(a.califSub_id, 0), 
			'''' AS califSub, 
			'''',--a.dni_id, 
			B.dnis AS dni, 
			0,--a.user_id, 
			'''' AS [user], 
			'''' as cal_key, 
			B.telephone,--a.cal_ANI, 
			0,--cal_tWait, 
			0,--cal_tXfer, 
			0,--cal_tRing, 
			B.statusTime,--cal_tDialog, 
			0,--a.cal_extension, 
			'''' AS agentName,
			''systemTranslated_ClientSystem'' [whoHangUp], 
			0,--a.cal_tMoh, 
			DATEPART(yyyy, B.date) [year], 
			DATEPART(mm, B.date) [month], 
			DATEPART(dd, B.date) [day], 
			DATEPART(hh, B.date) [hour], 
			DATEPART(mi, B.date) [minute], 
			0,--di.provedor_id, 
			'''',--prov.descrip [Proveedor], 
			0,
			'''' AS file_Moved, 
			0,--cal_tNotas, 
			AverageHandleTime = 0, --cal_tNotas + cal_tDialog, 
			'''' AS Dato1, 
			'''' AS Dato2, 
			'''' AS Dato3, 
			'''' AS Dato4, 
			'''' AS Dato5, 
			0 AS grabId,
			ISNULL(dnis.dni_Descripcion,'''') AS nameDNI,
			ISNULL(dnis.dni_numero,'''') AS dni,
			CASE
					WHEN B.statusTime > 0 THEN ''systemTranslated_collectCallYes''
					ELSE ''systemTranslated_collectCallNo''
			END AS collectCall,
			B.statusTime  AS timeTotalInCallSec,
			(FLOOR( ( B.statusTime )/ 60) + 
			CASE 
				WHEN CEILING( (B.statusTime ) % 60) != 0 THEN 1 
				ELSE 0 
			END) AS timeTotalInCallMin,
			CASE 
				WHEN B.callStatus IS NULL THEN ''systemTranslated_AbandonedInIVR''
				ELSE ''systemTranslated_AbandonedInIVR''
			END AS statusCallByIV,
			ISNULL(B.IVR_id,0) AS IVR,
			''systemTranslated_ClientSystem'' AS statusCallByIVR,
			''systemTranslated_SystemIVR'' AS [recibeCallBy],
			NULL AS cal_final
	FROM RepIVRDetail B
	LEFT JOIN ccdnis dnis on dnis.dni_numero=B.dnis
	WHERE B.date >= @from
			AND B.date < @to
			AND B.IVR_ID NOT IN(SELECT IVR_ID FROM RepInCallsDetail WHERE IVR_ID IS NOT NULL);

	END'
EXEC(@sql)


SET @process = 'K061001 Drop sp ccspRepInCallsDetail'
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepInCallsDetail'')
	BEGIN
	    DROP PROCEDURE ccspRepInCallsDetail;
	END'
EXEC(@sql)


SET @process = 'K061001 Create sp ccspRepInCallsDetail'
SET @sql = 'CREATE PROCEDURE [dbo].[ccspRepInCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS

SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN

	DECLARE @tab TABLE (callId INT PRIMARY KEY, [Dato1] VARCHAR(255), [Dato2] VARCHAR(255), [Dato3] VARCHAR(255), [Dato4] VARCHAR(255), [Dato5] VARCHAR(255))
	DECLARE @fechaSUM DATETIME
	INSERT INTO @tab
	SELECT callId, [Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5]
	FROM (
		SELECT A.CallId, [Data], [Description]
		FROM DataCallIn A
		INNER JOIN ccCallsIn B ON A.CallId = B.cal_id
		WHERE b.cal_Inicio >= @from AND b.cal_Inicio < @to
		) AS SourceTable
	pivot(max([Data]) FOR [Description] IN ([Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5])) AS pvt

	--Borrar lo que esta para no repetir
	DELETE
	FROM RepInCallsDetail
	WHERE [date] >= @from AND [date] < @to

			
	INSERT INTO RepInCallsDetail (DATE, 
callid, 
inboundId, 
ACDGroup, 
callStatusId, 
callStatus, 
dispositionId, 
disposition, 
subDispositionId, 
subDisposition, 
dnisId, 
dnis, 
userId, 
[user], 
callKey, 
ANI, 
queueTime, 
xferTime, 
ringingTime, 
dialogTime, 
extension, 
agentName, 
whoHangUp, 
mohTime, 
year, 
month, 
day, 
hour, 
minutes, 
provedorId, 
provider, 
trunk, 
fileMoved, 
twrapup, 
AverageHandleTime, 
Dato1, 
Dato2, 
Dato3, 
Dato4, 
Dato5, 
grabId, 
nameDNI, 
numDNI, 
collectCall, 
timeTotalInCallSec, 
timeTotalInCallMin, 
statusCallByIVR, 
IVR_ID, 
callHung, 
recibeCallBy, 
cal_final)
	SELECT 
		a.cal_inicio AS cal_ini, 
		a.cal_id,
		a.Inbound_id,
		ISNULL(ccIn.descripcion, '''') AS Inbound, 
		a.statusCall_id, 
		ISNULL(statusLlamada.descripcion, '''') AS statusCall, 
		a.calif_id, 
		ISNULL(disposition.description, '''') AS calif, 
		ISNULL(a.califSub_id, 0), 
		ISNULL(subDisposition.califSubDesc, '''') AS califSub, 
		a.dni_id, 
		ISNULL(dnis.dni_numero, '''') AS dni, 
		a.user_id, 
		ISNULL(LOGIN, '''') AS [user], 
		ISNULL(a.cal_key, '''') as cal_key, 
		a.cal_ANI, 
		cal_tWait, 
		cal_tXfer, 
		cal_tRing, 
		cal_tDialog, 
		a.cal_extension, 
		ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''') AS agentName,
		CASE
			WHEN a.cal_whoHung = 0
			THEN ''systemTranslated_Contact''
			WHEN a.cal_whoHung = 1
			THEN ''systemTranslated_Agent''
			ELSE ''systemTranslated_AgentSurvey''
		END [whoHangUp], 
		a.cal_tMoh, 
		DATEPART(yyyy, cal_inicio) [year], 
		DATEPART(mm, cal_inicio) [month], 
		DATEPART(dd, cal_inicio) [day], 
		DATEPART(hh, cal_inicio) [hour], 
		DATEPART(mi, cal_inicio) [minute], 
		di.provedor_id, 
		prov.descrip [Proveedor], 
		a.cal_puerto,
		CASE
			WHEN a.file_moved = 1 THEN ''systemTranslated_Remoto''
			WHEN a.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
			ELSE ''Local''
		END AS file_Moved, 
		cal_tNotas, 
		AverageHandleTime = cal_tNotas + cal_tDialog, 
		ISNULL(tab.Dato1, '''') AS Dato1, 
		ISNULL(tab.Dato2, '''') AS Dato2, 
		ISNULL(tab.Dato3, '''') AS Dato3, 
		ISNULL(tab.Dato4, '''') AS Dato4, 
		ISNULL(tab.Dato5, '''') AS Dato5, 
		ISNULL(rc.grab_id, 0) AS grabId,
		ISNULL(dni_Descripcion, '''') AS nameDNI,
		ISNULL(dnis.dni_numero, '''') AS dni,
		CASE
				WHEN statusLlamada.descripcion IS NOT NULL THEN ''systemTranslated_collectCallYes''
				ELSE ''systemTranslated_collectCallNo''
		END AS collectCall,
		CASE
			WHEN A.cal_final IS NULL THEN 0
			ELSE CAST( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) AS INT)
		END AS timeTotalInCallSec,
		CASE
			WHEN A.cal_final IS NULL THEN 0
			ELSE CAST( FLOOR( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) / 60 ) AS INT) 
		END + 
		CASE
			WHEN A.cal_final IS NULL THEN 0
			ELSE
				CASE
					WHEN CAST(CEILING( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) ) AS INT) % 60 != 0 THEN 1
					ELSE 0
				END
		END AS timeTotalInCallMin,
		CASE 
			WHEN a.IVR_id != 0 and ivrCIN.callStatus = ''systemTranslated_AbandonedInIVR'' THEN ''systemTranslated_AbandonedInIVR''
			WHEN a.statusCall_id = 13 THEN ''systemTranslated_Answered''
			WHEN a.statusCall_id != 13 THEN ''''
			ELSE ''''
		END AS statusCallByIVR,
		ISNULL(ivrCIN.IVR_ID, 0) AS IVR_ID,
		CASE
			WHEN ivrCIN.callStatus = ''systemTranslated_AbandonedInIVR'' THEN ''systemTranslated_ClientSystem''
			ELSE ''''
		END AS callHung,
		CASE
			WHEN ivrCIN.callid = a.cal_id THEN ''systemTranslated_SystemIVR''
			WHEN a.IVR_id = 0 THEN ''systemTranslated_CallInbound'' 
			ELSE ''''
		END AS [recibeCallBy], 
		ISNULL(a.cal_final, NULL) AS cal_final
FROM cccallsin A   
		LEFT JOIN ccoDialers di ON di.dialer_id = a.cal_puerto
		LEFT JOIN cstoProvedor prov ON di.provedor_id = prov.provedor_id
		LEFT JOIN @tab tab ON tab.callId = a.cal_id
		LEFT JOIN Ria_grabacion rc ON rc.cal_id = a.cal_id and rc.tipo_llamada=1
		LEFT JOIN ccInbound ccIn ON a.Inbound_id = ccIn.Inbound_id
		LEFT JOIN ccstatusllamada statusLlamada ON a.statusCall_id = statusLlamada.statusCall_id
		LEFT JOIN cctipocalif disposition ON a.calif_id = disposition.calif_id
		LEFT JOIN cctipocalifsub subDisposition ON a.califSub_id = subDisposition.califSub_id
		LEFT JOIN ccdnis dnis ON a.dni_id = dnis.dni_id
		LEFT JOIN ccUserView ccuser ON a.User_id = ccuser.user_id
		LEFT JOIN repIVRDetail ivrCIN ON a.IVR_id = ivrCIN.IVR_ID 
WHERE a.cal_inicio >= @from
		AND a.cal_inicio < @to


EXEC SupportReportCallInIVR 1, @from, @to

END'
EXEC(@sql)


	SET @process = 'K061001 Report Filters Catalog'
	SET @sql = '
if not exists (select * from Filters  where id = 33) begin
	insert into Filters (id, name, type, xmlParentNode, xmlChildNode) 
	values (33, ''inboundCamps'', ''33'', ''InboundCamps'', ''InboundCamp'')
end

update ReportsFilters set filterName = ''inboundCamps'' where id=3010 and filterName = ''acds''
'
EXEC (@sql)


	set @process = 'K063001-K063005 Reportes de abandono - Modificar filtros de campaña ->  Modificacion ccspRepCatalogos'
	set @sql='
	CREATE OR ALTER PROCEDURE [dbo].[ccspRepCatalogos]
	@type as tinyint,
	@action tinyint = 0 -- 0 Filter select; 1 Filters Range
	,@userId int =0 ---- se agrega parametro para filtros
	,@menuId INT = 0

	AS
	declare @tablatemp table (id int, description varchar(100) null)
	declare @tempwork table (idwg int)
	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @condition NVARCHAR(300) = '''';
	DECLARE @columnName NVARCHAR(100) = '''';
	DECLARE @consult NVARCHAR (2000) = '''';

	if @action = 0
	BEGIN
	IF OBJECT_ID(''TEMPDB..#filters'') IS NULL
	BEGIN
		CREATE TABLE #filters ([Type] VARCHAR(200))
	END

		-- CAMPAIGNS
	IF @type = 1 BEGIN

		INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId
		IF EXISTS (SELECT * FROM #filters)
		BEGIN
			SET @condition = '' WHERE camp.campType IN (SELECT * FROM #filters)''
			SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId;
		END
		ELSE BEGIN
			SET @columnName =	''campaignId'';
		END

		SET @consult = N'' SELECT cam_id as id, cam_descripcion as description, @columnName as dbColumn FROM ccCamps camp''

		IF @userId <> 0 BEGIN

			SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null)	
				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''' '''' as description  from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
				inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1
				where us.[User_id] = @userId ''
				+ @consult + '' inner join @tablatemp A on camp.cam_id = A.id'' + @condition;
		END
		ELSE BEGIN
			SET @SQL = @consult + @condition;
		END
		EXEC sp_executesql @SQL, N''@userId AS int = 0, @columnName AS NVARCHAR(100)'', @userId=@userId, @columnName=@columnName;
	END


		-- DIAL RESULTS
	if @type = 2 begin
		Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
		from ccTipoResultadoDial
		order by descripcion
	end

		-- WORKGROUPS
	if @type = 3 begin
		if @userId <> 0 begin
			select v.IDWG as id, c.WGName as description, ''workgroupId'' as dbColumn
			from ccWgByAcdView v
			inner join ccriacat_workgroup c on c.IDWG=v.IDWG
			where USER_ID= @userId
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
	if @type = 4 begin
	if @userId <> 0 begin

		insert into @tablatemp
		select distinct isnull(us.IDArea,0) as IDArea, wgu.User_id from ccUserView us
		inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
		where us.[User_id] = @userId

		select distinct idArea as id, isnull(AreaName,''S/AREA'') as description, ''areaId'' as dbColumn
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
	if @type = 5 begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalifOut
		order by [description]
	end

		-- USER
	if @type = 6 	begin
		if @userId <> 0 begin

				insert into @tempwork
						select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

				select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

				inner join @tempwork awg on wgu.IDWG = awg.idwg
				where us.TipoUser_id = 1 and [status] = 1

				return
			end

			else begin

				SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
				FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 1
				ORDER BY description
			end
	end

		-- ACDS**************
	IF @type = 7 BEGIN

		INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId
		IF EXISTS (SELECT * FROM #filters)
		BEGIN
			SET @condition = '' WHERE B.chat IN (SELECT * FROM #filters)''
			SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId;
		END
		ELSE BEGIN
			SET @columnName = ''inboundId'';
		END

		SET @consult = N'' SELECT inbound_id AS id, descripcion AS description, @columnName AS dbColumn
			FROM ccinbound B''

		IF @userId <> 0 BEGIN

			SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null)
				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''''''' as description  from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
				inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
				where us.[User_id] = @userId;''
				+ @consult + '' inner join @tablatemp A on B.inbound_id = A.id'' + @condition + '' return;'';		
		END
		ELSE BEGIN
			SET @SQL = @consult + @condition;
		END
		EXEC sp_executesql @SQL, N''@userId INT = 0, @columnName AS NVARCHAR(100)'',@userId=@userId, @columnName=@columnName;
	end

		-- DIDS
	if @type = 8 	begin
		select 0 as id, ''S/DNIS''  as description, ''dnisId'' as dbColumn
		union
		select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
		from ccdnis
	end

		--DISPOSITIONS IN
	if @type = 9 begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalif
		order by [description]
	end

		--SUBDISPOSITIONS IN
	if @type = 10	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM ccTipoCalifSub
		order by [description]
	end

		--PROVIDER
	if @type = 11 begin
		SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
		FROM cstoProvedor
		order by [description]
	end

		-- UNAVAILABLES
	if @type = 12 begin
		SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
		FROM cctiponotready
		order by descripcion
	end

		-- DIALERS
	if @type = 13 begin
		SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
		FROM ccoDialers
		order by descripcion
	end

		-- CallTYpes
	if @type = 14	begin
			SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
			FROM ccStatusLlamada
		order by descripcion
	end

		-- SUBDISPOSITIONS OUT
	if @type = 21	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM cctipocalifsubout
		order by [description]
	end

		--AVRS TEMPLATE-SECTION
	if @type = 15 	begin
		SELECT fc.id as id, (rf.nombre +'' ''+ rc.con_descripcion)+'' ''+convert(varchar(10),fc.id) as description, ''templateSectionId'' as dbColumn
		FROM RIA_FORMATOCONCEPTO fc
		INNER JOIN  (SELECT id_formato, nombre, MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato, nombre) as rf
		ON rf.id_formato = fc.templateId
		inner join RIA_CONCEPTOS rc ON rc.id_concepto = fc.sectionId
		order by fc.id
	END

	--exec dbo.ccspRepCatalogos @type=15,@action=0

		--AVRS TEMPLATES
	if @type = 16 	begin
		SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
		FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato) as t
		ON f.id_formato = t.id_formato AND f.version = t.version
		order by f.nombre
	end

		--AVRS TEMPLATES
	if @type = 31 	begin
		SELECT c.id_concepto as id, c.con_descripcion as description, ''sectionId'' as dbColumn
		FROM RIA_CONCEPTOS c INNER JOIN (SELECT id_concepto,MAX(version) as version
										FROM RIA_CONCEPTOS
										group by id_concepto) as t
		ON c.id_concepto = t.id_concepto AND c.version = t.version
		order by c.con_descripcion
	END

		--AVRS QUESTIONS
	if @type = 23 	begin
		SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
		FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
										FROM RIA_PREGUNTAS
										group by id_pregunta) as t
		ON p.id_pregunta = t.id_pregunta
		order by p.enunciado_pregunta
	END


	--AVRS QUESTIONS CHAT
	if @type = 24 	begin
		SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
		FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
										FROM RIA_PREGUNTAS
										group by id_pregunta) as t
		ON p.id_pregunta = t.id_pregunta
		order by p.enunciado_pregunta
	END

		-- AVRS SUPERVISOR
	if @type = 17 	begin
		SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
		FROM ccUserView
		WHERE [status] = 1
		and TipoUser_id = 2
		ORDER BY [login]
	end

		--Status Call
	if @type = 25 	begin
		select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
		from ccstatusllamada
		order by [descripcion]
	end

		--Survey
	if @type = 26 	begin
		select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
		from Survey
		order by [description]
	end

	--dialType
	if @type = 29 begin
		select dialId as id, [description] as description, ''dialId'' as dbcolumn
		from dialType
		order by [description]
	end

		--dial
	if @type = 30 	begin
		select id as id, [description] as description, ''dialId'' as dbcolumn
		from Dials
		order by [description]
	end

	if @type = 33 begin
		if @userId <> 0 begin
 			insert into @tablatemp
			select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
			inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
			inner join ccinbound i on caesp.IdCampEsp = i.Inbound_id and i.chat = 0
			where us.[User_id] = @userId

			SELECT inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
			from ccinbound B
			inner join @tablatemp A on B.inbound_id = A.id
			return
		end
		else begin
			select inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
			from ccinbound where chat = 0
		end
	end
	end --Action 0

	IF OBJECT_ID(''TEMPDB..#filters'') IS NOT NULL
	BEGIN
		DROP TABLE #filters;
	END

	-----------------------------------------------------------
	if @action = 1 begin
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
			SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
		end
	end'
	EXEC(@sql)

	
	---------------------------------------------Llamadas de Entrada->Tiempos->Abandonadas -------------------------------------------------------------------------

set @process = 'Alter table RepInAbnd alter column workgroup'
set @sql = '
if EXISTS(
	select column_name
	from information_schema.columns  
	where table_name = ''RepInAbnd'' AND column_name = ''workgroup''
	AND character_maximum_length = 255
)
BEGIN
	ALTER TABLE RepInAbnd ALTER COLUMN workgroup VARCHAR(1020) NOT NULL;
END'
EXEC(@sql)


set @process = 'Alter table RepInAbnd add workgroupIds'
set @sql = '
if not exists (select * from sys.columns where name = N''workgroupIds'' and Object_ID = Object_ID(N''RepInAbnd''))
BEGIN
	ALTER TABLE RepInAbnd add workgroupIds varchar(120) null
END'
EXEC(@sql)


set @process = 'Drop procedure ccspRepInAbnd'
set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepInAbnd'')
    BEGIN
        DROP PROCEDURE ccspRepInAbnd;
    END'
EXEC(@sql)


set @process = 'Create procedure ccspRepInAbnd'
set @sql = '
CREATE PROCEDURE [dbo].[ccspRepInAbnd]
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

	 delete [RepInAbnd] with(rowlock) where [date] between @from and @to
		
	;WITH WGS AS (
		SELECT i.Inbound_id,
		(select isnull(STUFF((select '','' + cast(wg.idwg as varchar(5)) from ccRIACampEspWG wg 
		where Tipo = 0 and wg.IdCampEsp = i.Inbound_id for xml path ('''')),1,1,''''), 0)) [workgroupIds],
		(select isnull(STUFF((select '','' + c.WGName from ccRIACampEspWG wg left join ccriacat_workgroup c on wg.IDWG = c.IDWG and Tipo = 0
		where wg.IdCampEsp = i.Inbound_id for xml path ('''')),1,1,''''), '''')) [workgroups]
		FROM ccinbound i 
		WHERE chat = 0
	),
	xCalls AS (
		SELECT [Start] timegroup
		, cal_inicio
		, inbound_id				
		, statuscall_id
		, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0)
			AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
		, (cal_twait + cal_txfer + cal_tring) AS tAbnd
		FROM ccCallsIn ci with(nolock) JOIN TmpTimesInterval th on cal_inicio between [Start] and [Stop]
		WHERE cal_inicio >= @from AND cal_inicio < @to
		AND INBOUND_ID > 0
	), 
	Rep AS (
		SELECT timegroup [date]		
			, xCalls.inbound_id
			, COUNT(cal_inicio) AS amount
			, MAX(tAbnd) AS time_max
			, SUM(tAbnd) AS time_tot
			, COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [LT10]
			, COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [LT20]
			, COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [LT30]
			, COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [LT40]
			, COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [LT50]
			, COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [LT60]
			, COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [LT120]
			, COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [LT180]
			, COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [LT240]
			, COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [LT300]
			, COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [GT300]
			, datepart(yyyy,timegroup) [year], datepart(mm,timegroup) [month], datepart(dd,timegroup) [day]
			, datepart(hh,timegroup) [hour], datepart(mi,timegroup) [minutes]
		 FROM xCalls
		 WHERE (abnd IS NOT NULL) 
		 GROUP BY timegroup, xCalls.inbound_id
	 )

	 insert into RepInAbnd
	 select [date]
	 ,isnull(Ib.IDArea,0) areaId
	 ,isnull(Area.AreaName,'''') area
	 ,0 as workgroupId
	 , case when len(isnull(WGS.workgroups,'''')) > 1020 then substring(isnull(WGS.workgroups,''''), 0, 1020-1) else isnull(WGS.workgroups,'''') end [workgroup]
	 ,Rep.Inbound_id,isnull(Ib.descripcion,'''') inbound, amount, time_max
	 ,time_tot, LT10, LT20, LT30, LT40, LT50, LT60, LT120, LT180, LT240, LT300, GT300, [year], [month], [day], [hour], [minutes]
	 , case when len(isnull(WGS.workgroupIds,''0'')) > 120 then substring(isnull(WGS.workgroupIds,''0''), 0, 120-1) else isnull(WGS.workgroupIds,''0'') end [workgroupIds]
	 from Rep 
	 left join ccInbound Ib ON Ib.inbound_id=Rep.inbound_id and Ib.chat=0
	 left join ccriacat_areas Area on Area.IDArea=Ib.IDArea
	 left join WGS on WGS.Inbound_id=Rep.Inbound_id
end'
EXEC(@sql)


set @process = 'DROP VIEW RepViewInAbnd'
set @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(''dbo.RepViewInAbnd'') AND type = ''V'')
    BEGIN
        DROP VIEW dbo.RepViewInAbnd
    END'
EXEC(@sql)


set @process = 'CREATE VIEW RepViewInAbnd'
set @sql = '
CREATE VIEW [dbo].[RepViewInAbnd] AS
SELECT
	[date],
	areaId,
	area,
	workgroupIds,
	workgroup [WgOrWgs],
	inboundId [inboundCamp],
	inbound [campaign],
	amount [abandonedCalls],
	timeMax [abandonedMaxWaitTime],
	timeTot [accumulatedAbandonTime],
	LT10 [LT10s],
	LT20 [LT20s],
	LT30 [LT30s],
	LT40 [LT40s],
	LT50 [LT50s],
	LT60 [LT60s],
	LT120 [LT120s],
	LT180 [LT180s],
	LT240 [LT240s],
	LT300 [LT300s],
	GT300 [GT300s],
	[year],
	[month],
	[day],
	[hour],
	[minutes]
FROM
RepInAbnd NOLOCK'
EXEC(@sql)


SET @process = 'Delete workgroups filter from ReportsFilters where id = 3141'
SET @sql = 'if exists(select 1 from ReportsFilters where reportName = ''Abandoned'' and id = 3141 and filterName = ''workgroups'')
begin
	delete ReportsFilters where reportName = ''Abandoned'' and id = 3141 and filterName = ''workgroups''
end'
EXEC(@sql)


SET @process = 'Insert into GroupByReports report 3141'
SET @sql = 'if not exists(select * from GroupByReports where id=3141)
begin
	insert into GroupByReports (id, columns, groupByColumns) values
	(3141,''areaId|max(area):area|workgroupIds|max(WgOrWgs):WgOrWgs|inboundCamp|max(campaign):campaign|sum(abandonedCalls):abandonedCalls|max(abandonedMaxWaitTime):abandonedMaxWaitTime|
	sum(accumulatedAbandonTime):accumulatedAbandonTime|sum(LT10s):LT10s|sum(LT20s):LT20s|sum(LT30s):LT30s|sum(LT40s):LT40s|sum(LT50s):LT50s|sum(LT60s):LT60s|sum(LT120s):LT120s|
	sum(LT180s):LT180s|sum(LT240s):LT240s|sum(LT300s):LT300s|sum(GT300s):GT300s'',''areaId|workgroupIds|inboundCamp'')
end'
EXEC(@sql)


SET @process = 'Update ReportsFilters where id = 3141'
SET @sql = 'update ReportsFilters set filterName = ''inboundCamps'' where id = 3141 and filterName = ''acds'' '
EXEC (@sql)


SET @process = 'Insert into ReportsFilteredByHourRange report 3141'
SET @sql = 'IF NOT EXISTS (SELECT * FROM ReportsFilteredByHourRange WHERE id = 3141) 
BEGIN
	INSERT INTO ReportsFilteredByHourRange (id, reportName, groupDayWithHHmm) VALUES (3141, ''RepViewInAbnd'', 1)
END'
EXEC(@sql)


	---------------------------------------------Llamadas de Entrada->Tiempos->Contestadas -------------------------------------------------------------------------	


set @process = 'Alter table RepInAnsw alter column workgroup'
set @sql = '
if EXISTS(
	select column_name
	from information_schema.columns  
	where table_name = ''RepInAnsw'' AND column_name = ''workgroup''
	AND character_maximum_length = 255
)
BEGIN
	ALTER TABLE RepInAnsw ALTER COLUMN workgroup VARCHAR(1020) NOT NULL;
END'
EXEC(@sql)


set @process = 'Alter table RepInAnsw add workgroupIds'
set @sql = '
if not exists (select name from sys.columns where name = N''workgroupIds'' and Object_ID = Object_ID(N''RepInAnsw''))
BEGIN
	ALTER TABLE RepInAnsw add workgroupIds VARCHAR(120) NULL
END'
EXEC(@sql)


set @process = 'Drop procedure ccspRepInAnsw'
set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepInAnsw'')
    BEGIN
        DROP PROCEDURE ccspRepInAnsw;
    END'
EXEC(@sql)


set @process = 'Create procedure ccspRepInAnsw'
set @sql = '
CREATE PROCEDURE [dbo].[ccspRepInAnsw]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

DECLARE @tresDialog AS smallint
EXEC @tresDialog = ccspConfigTresDialog

if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()

	delete [RepInAnsw] with(rowlock) where [date] between @from and @to
        
	;WITH WGS AS (
		SELECT i.Inbound_id,
		(select isnull(STUFF((select '','' + cast(wg.idwg as varchar(5)) from ccRIACampEspWG wg 
		where Tipo = 0 and wg.IdCampEsp = i.Inbound_id for xml path ('''')),1,1,''''), 0)) [workgroupIds],
		(select isnull(STUFF((select '','' + c.WGName from ccRIACampEspWG wg left join ccriacat_workgroup c on wg.IDWG = c.IDWG and Tipo = 0
		where wg.IdCampEsp = i.Inbound_id for xml path ('''')),1,1,''''), '''')) [workgroups]
		FROM ccinbound i 
		WHERE chat = 0

	),
	xCalls AS (
		SELECT start timegroup
        , cal_inicio
        , inbound_id                
        , statuscall_id
        , (CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
        , (cal_twait + cal_txfer + cal_tring) AS tAnsw
        FROM ccCallsIn ci with(nolock) JOIN TmpTimesInterval th on cal_inicio between [Start] and [Stop]
        WHERE cal_inicio >= @from AND  cal_inicio < @to
        AND INBOUND_ID > 0
	),
	Rep AS (
		SELECT timegroup [date]
        , xCalls.inbound_id
        , COUNT(cal_inicio) AS amount
        , MAX(tAnsw) AS time_max
        , SUM(tAnsw) AS time_tot
        , COUNT(CASE WHEN tAnsw < 10  THEN 1 ELSE NULL END) as [LT10]
        , COUNT(CASE WHEN tAnsw BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [LT20]
        , COUNT(CASE WHEN tAnsw BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [LT30]
        , COUNT(CASE WHEN tAnsw BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [LT40]
        , COUNT(CASE WHEN tAnsw BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [LT50]
        , COUNT(CASE WHEN tAnsw BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [LT60]
        , COUNT(CASE WHEN tAnsw BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [LT120]
        , COUNT(CASE WHEN tAnsw BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [LT180]
        , COUNT(CASE WHEN tAnsw BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [LT240]
        , COUNT(CASE WHEN tAnsw BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [LT300]
        , COUNT(CASE WHEN tAnsw >= 300  THEN 1 ELSE NULL END) as [GT300]
        , datepart(yyyy,timegroup) [year], datepart(mm,timegroup) [month], datepart(dd,timegroup) [day]
        , datepart(hh,timegroup) [hour], datepart(mi,timegroup) [minutes]
		FROM xCalls
		WHERE (answer IS NOT NULL)
		GROUP BY timegroup, xCalls.Inbound_id
	 )

	 insert into RepInAnsw
	 select [date]
	 ,isnull(Ib.IDArea,0) areaId
	 ,isnull(Area.AreaName,'''') area
	 ,0 as workgroupId
	 , case when len(isnull(WGS.workgroups,'''')) > 1020 then substring(isnull(WGS.workgroups,''''), 0, 1020-1) else isnull(WGS.workgroups,'''') end [workgroup]
	 ,Rep.Inbound_id,isnull(Ib.descripcion,'''') inbound, amount, time_max
	 ,time_tot, LT10, LT20, LT30, LT40, LT50, LT60, LT120, LT180, LT240, LT300, GT300, [year], [month], [day], [hour], [minutes]
	 , case when len(isnull(WGS.workgroupIds,''0'')) > 120 then substring(isnull(WGS.workgroupIds,''0''), 0, 120-1) else isnull(WGS.workgroupIds,''0'') end [workgroupIds]
	 from Rep 
	 left join ccInbound Ib ON Ib.inbound_id=Rep.inbound_id and Ib.chat=0
	 left join ccriacat_areas Area on Area.IDArea=Ib.IDArea
	 left join WGS on WGS.Inbound_id=Rep.Inbound_id
end'
EXEC(@sql)


set @process = 'DROP VIEW RepViewInAnsw'
set @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(''dbo.RepViewInAnsw'') AND type = ''V'')
    BEGIN
        DROP VIEW dbo.RepViewInAnsw
    END'
EXEC(@sql)


set @process = 'CREATE VIEW RepViewInAnsw'
set @sql = '
CREATE VIEW [dbo].[RepViewInAnsw] AS
SELECT
	[date],
	areaId,
	area,
	workgroupIds,
	workgroup [WgOrWgs],
	inboundId [inboundCamp],
	inbound [campaign],
	amount [LlamadasAtendidas],
	timeMax [maximumAnswerTime],
	timeTot [accumulatedAnswerTime],
	LT10 [LT10s],
	LT20 [LT20s],
	LT30 [LT30s],
	LT40 [LT40s],
	LT50 [LT50s],
	LT60 [LT60s],
	LT120 [LT120s],
	LT180 [LT180s],
	LT240 [LT240s],
	LT300 [LT300s],
	GT300 [GT300s],
	[year],
	[month],
	[day],
	[hour],
	[minutes]
FROM
RepInAnsw NOLOCK'
EXEC(@sql)


SET @process = 'Delete workgroups filter from ReportsFilters where id = 3142'
SET @sql = 'if exists(select 1 from ReportsFilters where reportName = ''Answered'' and id = 3142 and filterName = ''workgroups'')
begin
	delete ReportsFilters where reportName = ''Answered'' and id = 3142 and filterName = ''workgroups''
end'
EXEC(@sql)


SET @process = 'Insert into GroupByReports report 3142'
SET @sql = 'if not exists(select * from GroupByReports where id=3142)
begin
	insert into GroupByReports (id, columns, groupByColumns) values
	(3142,''areaId|max(area):area|workgroupIds|max(WgOrWgs):WgOrWgs|inboundCamp|max(campaign):campaign|sum(LlamadasAtendidas):LlamadasAtendidas|max(maximumAnswerTime):maximumAnswerTime|
	sum(accumulatedAnswerTime):accumulatedAnswerTime|sum(LT10s):LT10s|sum(LT20s):LT20s|sum(LT30s):LT30s|sum(LT40s):LT40s|sum(LT50s):LT50s|sum(LT60s):LT60s|sum(LT120s):LT120s|
	sum(LT180s):LT180s|sum(LT240s):LT240s|sum(LT300s):LT300s|sum(GT300s):GT300s'',''areaId|workgroupIds|inboundCamp'')
end'
EXEC(@sql)


SET @process = 'Update ReportsFilters where id = 3142'
SET @sql = 'update ReportsFilters set filterName = ''inboundCamps'' where id = 3142 and filterName = ''acds'' '
EXEC (@sql)


SET @process = 'Insert into ReportsFilteredByHourRange report 3142'
SET @sql = 'IF NOT EXISTS (SELECT * FROM ReportsFilteredByHourRange WHERE id = 3142) 
BEGIN
	INSERT INTO ReportsFilteredByHourRange (id, reportName, groupDayWithHHmm) VALUES (3142, ''RepViewInAnsw'', 1)
END'
EXEC(@sql)    

    ---------------------------------------End Carlos Chavez release/126.20240304.0.0---------------------------------------------------------
	
	---------------------------------------BEGIN Frida Orta release/126.20240304.0.0---------------------------------------------------------

	---------------------------------------------Llamadas de salida->Detalle de marcacion -------------------------------------------------------------------------

set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
    begin
    DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
    end'
EXEC(@sql)
 

set @process = 'Alter table ccStatusLlamada add descTranslated'
set @sql = 'if not exists (select * from sys.columns where name = N''descTranslated'' and Object_ID = Object_ID(N''ccStatusLlamada''))
BEGIN
	alter table ccStatusLlamada add descTranslated varchar(100) null
END'
EXEC(@sql)
 

set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
        begin
        ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
        end'
EXEC(@sql)


SET @process = 'Insert into ReportsFilteredByHourRange report 4010'
SET @sql = 'IF NOT EXISTS (SELECT id FROM ReportsFilteredByHourRange WHERE id = 4010) 
BEGIN
	INSERT INTO ReportsFilteredByHourRange (id, reportName, groupDayWithHHmm) VALUES (4010, ''RepOutDialDetail'', 0)
END'
EXEC(@sql)


SET @process = 'Drop procedure ccspRepOutDialDetail '
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepOutDialDetail'')
	BEGIN
	    DROP PROCEDURE ccspRepOutDialDetail;
	END'
EXEC(@sql)


SET @process = 'Create procedure ccspRepOutDialDetail'
SET @sql = 'CREATE PROCEDURE [dbo].[ccspRepOutDialDetail] 
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

	DELETE FROM RepOutDialDetail WHERE date >= @from AND date < @to
        
    IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
    IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
    IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;

    SELECT  dial.logDial_id
        ,dial.callout_id
        ,dial.cam_id
        ,CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id
        ,ISNULL(tr.descTranslate ,'''') as resultDialDesc
        ,dial.Telefono
        ,dial.Puerto
        ,dial.fecha
        ,dial.tDialing
        ,CASE WHEN dial.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview'' 
              WHEN dial.TipoDialingMode =  ''10000000'' THEN ''systemTranslated_Assisted'' 
			  WHEN RIGHT(dial.TipoDialingMode,5) IN (''01000'',''10000'') THEN ''systemTranslated_Callback''
              WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto'' 
              WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' END AS dialType            
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
        ,CASE WHEN dial.disconnectCause <> '''' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '''' END codeSip
        ,case when @country<>1 then '''' WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
            WHEN dial.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' ELSE ''systemTranslated_Indefinite'' END TipoTel
        ,ISNULL(regp.tPreview,'''') as tpreview
        ,co.User_id as UserID
    INTO #dials
    FROM ccoLogDials dial(NOLOCK)
    LEFT JOIN ccocallsout co(NOLOCK) ON dial.cal_id = co.cal_id
    LEFT JOIN cctipocalifout tco WITH (NOLOCK) ON tco.calif_id = co.calif_id
    LEFT JOIN cctipocalifsubout tsco WITH (NOLOCK) ON tsco.califSub_id = co.califSub_id
    LEFT JOIN RegProcessPreviewRecord regp WITH (NOLOCK) ON regp.callout_id = co.callout_id and regp.callId = co.cal_id
    LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dial.tipoResDial_id = tr.tiporesdial_id
    WHERE fecha >= @from AND fecha < @to
    union
    (
    select 
            ''''
            ,reg.callout_id
            ,ccoa.cam_id
            ,reg.process
            ,ISNULL(cctyp.translatedDesc,'''')
            ,ccoa.cal_telefono
            ,''''
            ,reg.reg_date
            ,''''
            ,''systemTranslated_Preview''         
            ,''''
            ,''''
            ,''''
            ,''''
            ,''''
            ,ccoa.cal_Key
            ,''''
            ,''''
            ,''''
            ,''''
            ,''''
            ,''''   
            ,reg.tPreview
            ,reg.userId 
    FROM RegProcessPreviewRecord reg(NOLOCK)
    left join ccoCallsOut ccoa (NOLOCK) ON reg.callout_id = ccoa.callout_id
    left join ccTypeProcessPreview cctyp (NOLOCK) ON  cctyp.typeProcess_id = reg.process
    WHERE reg.reg_date >= @from AND reg.reg_date < @to AND reg.process not in (5,7,13,14)
    )

	select distinct cast(codeSip as int) as codeSip,disconnectCause into #codeSip from #dials where codeSip<>'''' and IsNumeric(codeSip)=1

	select A.codeSip,A.disconnectCause,B.description into #relationCodeSip from #codeSip A
	inner join DC_Extra B on A.codeSip=B.id


    INSERT INTO RepOutDialDetail
        SELECT fecha as [date]
        ,case when dials.cal_key is null and cs.cal_key is null then '''' when dials.cal_key is not null then dials.cal_key else cs.cal_key end cal_key
        ,ISNULL(telefono,'''') telephone
        ,dials.tiporesdial_id as tiporesdialId
        ,CASE WHEN dials.tipoResDial_id = 14 THEN 
                CASE WHEN camps.campType = 6 THEN ''systemTranslated_CancelledByEngaged'' ELSE ''systemTranslated_CancelledBySystem'' END
            ELSE ISNULL(dials.resultDialDesc, '''') END AS dialResult
        ,ISNULL(dials.[cam_id],'''')campaignId
        ,ISNULL(RTRIM(LTRIM(camps.cam_descripcion)),''systemTranslated_NoCampaign'') AS campaign
        ,dials.tbusy AS timeMessage
        ,DATEPART(yyyy, fecha) year 
        ,DATEPART(mm, fecha) month  
        ,DATEPART(dd, fecha) day    
        ,DATEPART(hh, fecha) hour   
        ,DATEPART(mi, fecha) minutes
        ,ISNULL(rl.name, '''') listName
        ,CASE WHEN answerbit = 1 THEN ''systemTranslated_Charged'' ELSE ''systemTranslated_NotCharged'' END AS billed
        ,ISNULL(cs.Dato1, '''') AS data1
        ,ISNULL(cs.Dato2, '''') AS data2
        ,ISNULL(cs.Dato3, '''') AS data3
        ,ISNULL(cs.Dato4, '''') AS data4
		,ISNULL(cs.Dato5, '''') AS data5
        ,CASE WHEN dials.[file_moved] = 1 THEN ''systemTranslated_Remoto'' 
            WHEN dials.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
            ELSE ''systemTranslated_Local'' END AS fileMoved
		,dials.disconnectCause
        ,COALESCE(dat.description, descTranslate, ''N/A'') DCCustomer
        ,dials.dialType
        ,TipoTel
        ,ISNULL(CallDisposition, ''N/A'') AS CallDisposition
        ,ISNULL(califSubDesc, ''N/A'') AS CallSubDisposition
        ,ISNULL(csP.Dato6, '''') AS data6
        ,ISNULL(csP.Dato7, '''') AS data7
        ,ISNULL(csP.Dato8, '''') AS data8
        ,ISNULL(csP.Dato9, '''') AS data9
        ,ISNULL(csP.Dato10, '''') AS data10
        ,ISNULL(csP.Dato11, '''') AS data11
        ,ISNULL(csP.Dato12, '''') AS data12
        ,ISNULL(csP.Dato13, '''') AS data13
        ,ISNULL(csP.Dato14, '''') AS data14
        ,ISNULL(csP.Dato15, '''') AS data15
        ,dials.tpreview AS preview_Time
        ,ISNULL(us.Login,'''') 
    FROM #dials as dials
    LEFT JOIN ccoCallsOutSource cs(NOLOCK) ON dials.callout_id = cs.callout_id
    LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dials.tiporesdial_id = tr.tiporesdial_id
    LEFT JOIN ccCamps camps(NOLOCK) ON camps.[cam_id] = dials.[cam_id]
    LEFT JOIN ccRIARegistryLists rl(NOLOCK) ON cs.list_id = rl.list_id
    LEFT JOIN #relationCodeSip dat ON dat.disconnectCause = dials.disconnectCause
    LEFT JOIN ccoCallsPreviewData csP ON (dials.cal_Key = csP.cal_Key AND dials.cam_id = csP.cam_id)
    LEFT JOIN ccUsers us (NOLOCK) ON  us.User_id = dials.UserID

    IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
    IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
    IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;
END'
EXEC(@sql)


set @process = 'DROP VIEW RepOutDialDetailView'
set @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(''dbo.RepOutDialDetailView'') AND type = ''V'')
    BEGIN
        DROP VIEW dbo.RepOutDialDetailView
    END'
EXEC(@sql)


set @process = 'CREATE VIEW RepOutDialDetailView'
set @sql = 'CREATE VIEW RepOutDialDetailView as 
select
	[date]  ,
	[callKey]  ,
	[telephone],
	[dialResultId]  ,
	[dialResult]  ,
	[campaignId]  ,
	[campaign]  ,
	[timeMessage]  ,
	[year]  ,
	[month]  ,
	[day]  ,
	[hour]  ,
	[minutes]  ,
	[listName] ,
	[billed]  ,
	[data1]  ,
	[data2]  ,
	[data3]  ,
	[data4]  ,
	[data5]  ,
	[fileMoved],
	[DCCustomer]  ,
	[disconnectCause]  ,
	[dialType]  ,
	[TipoTel]  ,
	[CallDisposition]  ,
	[CallSubDisposition]  ,
	[data6]  ,
	[data7]  ,
	[data8]  ,
	[data9]  ,
	[data10]  ,
	[data11]  ,
	[data12]  ,
	[data13]  ,
	[data14]  ,
	[data15]  ,
	[preview_Time]  ,
	[login] as [user]
	from RepOutDialDetail NOLOCK'
EXEC(@sql)


SET @process = 'Update TranslatedReports id 4010'
SET @sql = '
	UPDATE
		TranslatedReports
	SET
		columns = ''campaign|billed|fileMoved|dialType|TipoTel|dialResult|DCCustomer''
	WHERE
		id = 4010
'
EXEC(@sql)


	---------------------------------------------Llamadas de salida->Detalle de llamadas contestadas -------------------------------------------------------------------------

set @process = 'Alter table RepOutCallsDetail alter column iva'
set @sql = '
if EXISTS(
	select column_name
	from information_schema.columns  
	where table_name = ''RepOutCallsDetail'' AND column_name = ''iva''
	AND DATA_TYPE = ''int''
)
BEGIN
	alter table RepOutCallsDetail alter column iva varchar(5)
END'
EXEC(@sql)


SET @process = 'Insert into ReportsFilteredByHourRange report 4020'
SET @sql = 'IF NOT EXISTS (SELECT id FROM ReportsFilteredByHourRange WHERE id = 4020) 
BEGIN
	INSERT INTO ReportsFilteredByHourRange (id, reportName, groupDayWithHHmm) VALUES (4020, ''RepOutCallsDetail'', 0)
END'
EXEC(@sql)


SET @process = 'Drop procedure ccspRepOutCallsDetail '
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepOutCallsDetail'')
	BEGIN
	    DROP PROCEDURE ccspRepOutCallsDetail;
	END'
EXEC(@sql)


SET @process = 'Create procedure ccspRepOutCallsDetail'
SET @sql = 'CREATE PROCEDURE [dbo].[ccspRepOutCallsDetail] 
@action as tinyint,
@from as datetime = NULL,
@to as datetime = NULL
AS

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

DECLARE @IVA INT, @IVAstring varchar(3)
DECLARE @country AS TINYINT

SELECT @IVA = convert(INT, isnull(valor, 0))
FROM ccsettings
WHERE setting_id = 25

SELECT @IVAstring =CONVERT(VARCHAR(5),@IVA) + ''%''

SELECT @country = convert(TINYINT, isnull(valor, 1))
FROM ccsettings
WHERE setting_id = 104

IF @country IS NULL
	SET @country = 1

IF @action = 1
BEGIN
	DELETE FROM RepOutCallsDetail WITH (ROWLOCK)
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
		ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''')[login],
		ISNULL(convert(VARCHAR(255), Usr.LOGIN), ''systemTranslated_NoUserName'')  AS [username],
		camps.cam_id AS [campaignId],
		ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
		(CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration],
		CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country)) AS [ncost],

		@IVAstring AS iva,
		CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country) * (1 + (@IVA / 100.00))) AS total,
		CASE 
			WHEN prov.descrip IS NOT NULL THEN prov.descrip
			ELSE ''systemTranslated_NoCarrier'' 
		END AS [ByCarrier],
		case 
			when @country<>1 then '''' 
			WHEN ld.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
			WHEN ld.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' 
			ELSE ''systemTranslated_Indefinite'' END [Calltypes],
		CASE 
		WHEN ld.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview'' 
		WHEN ld.TipoDialingMode =  ''10000000'' THEN ''systemTranslated_Assisted'' 
		WHEN ld.TipoDialingMode IN (''00001000'',''00010000'') THEN ''systemTranslated_Callback'' 
		WHEN RIGHT(ld.TipoDialingMode, 3) = ''100'' THEN ''systemTranslated_Auto'' 
		WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' 
		WHEN ld.TipoDialingMode = ''000000000'' THEN ''systemTranslated_Auto''
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
		sta.descTranslated AS [dialResult], 
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
EXEC(@sql)


set @process = 'DROP VIEW RepViewOutCallsDetail'
set @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(''dbo.RepViewOutCallsDetail'') AND type = ''V'')
    BEGIN
        DROP VIEW dbo.RepViewOutCallsDetail
    END'
EXEC(@sql)


set @process = 'CREATE VIEW RepViewOutCallsDetail'
set @sql = 'CREATE VIEW RepViewOutCallsDetail AS SELECT
date,
callKey,
telephone,
transfer,
dialog,
nque,
wrapup,
CallDisposition,
subDisposition,
extension,
userId,
login,
username,
campaignId,
campaign,
duration,
ncost,
iva,
total ,
ByCarrier,
Calltypes,
dialType,
whoHangUp,
dialResult,
calId,
year,
month,
day,
hour,
minutes,
trunk,
data1,
data2,
data3,
data4,
data5,
MessageTime,
grabId  
FROM RepOutCallsDetail nolock'
EXEC(@sql)


SET @process = 'Update TranslatedReports id 4020'
SET @sql = '
	UPDATE
		TranslatedReports
	SET
		columns = ''login|campaign|ByCarrier|Calltypes|dialType|whoHangUp|subDisposition|dialResult''
	WHERE
		id = 4020
'
EXEC(@sql)


	---------------------------------------------Llamadas de salida->Abandono por campana -------------------------------------------------------------------------

set @process = 'Alter table RepSpecialAbndCamp rename total column to dialedCalls'
set @sql = '
if exists (select name from sys.columns where name = N''total'' and Object_ID = Object_ID(N''RepSpecialAbndCamp''))
BEGIN
	exec sp_rename ''RepSpecialAbndCamp.total'',''dialedCalls'',''COLUMN''
END'
EXEC(@sql)


SET @process = 'Insert into ReportsFilteredByHourRange report 4150'
SET @sql = 'IF NOT EXISTS (SELECT id FROM ReportsFilteredByHourRange WHERE id = 4150) 
BEGIN
	INSERT INTO ReportsFilteredByHourRange (id, reportName, groupDayWithHHmm) VALUES (4150, ''RepSpecialAbndCamp'', 0)
END'
EXEC(@sql)


SET @process = 'Update ReportsTotals id 4150'
SET @sql = '
UPDATE 
	ReportsTotals 
SET 
	totalColumns = ''special:abandonedCallsPctg:convert(decimal(10_2)_ISNULL((sum(AbandonedCalls) * 100.00)/NULLIF(sum(dialedCalls)_0)_0))|sum:abandonedCalls|sum:total''
WHERE 
	id = 4150
'
EXEC(@sql)
	
	---------------------------------------End Frida Orta release/126.20240304.0.0---------------------------------------------------------
-----------------------------------------------------BEGIN Enrique Ruiz -----------------------------------------------------------------

	set @process = 'K063001-K063005 Reportes de abandono - Modificar filtros de campaña ->  Agregar tabla ReportsFiltersCategory'
	set @sql='IF NOT EXISTS(SELECT * FROM SYS.TABLES WHERE NAME=''ReportsFiltersCategory'')
	BEGIN
		CREATE TABLE ReportsFiltersCategory (
			ReportId SMALLINT NOT NULL,
			FilterName VARCHAR(100) NOT NULL,
			Category VARCHAR(200) NOT NULL,
			dbColumn VARCHAR(100) NOT NULL,
			Description VARCHAR(500)
		)
	END'
	EXEC(@sql)

	set @process = 'K063001-K063005 Add view RepViewSpececialAbnd to support the campaign index management'
	set @sql='IF NOT EXISTS(SELECT * FROM SYS.VIEWS WHERE NAME=''RepViewSpececialAbnd'')
	BEGIN
		EXEC(''CREATE VIEW [dbo].[RepViewSpececialAbnd] AS
		SELECT
		[date],
		CASE
			WHEN [campaignId] = 0 THEN [inboundId]
			ELSE [campaignId]
		END AS [inboundId],
		[inboundId] AS [inboundId2],
		[campaignId] AS [campaignId2],
		[campACDDescription],
		[total],
		[abandonedCalls],
		[abandonedCallsPctg]
		FROM [dbo].[RepSpececialAbnd]'')
	END'
	EXEC(@sql)

	set @process = 'K063001-K063005 Reportes de abandono - Modificar filtros de campaña ->  ReportsFiltersCategory Insert & K061006-K062010  ReportsFiltersCategory for RepOutCallsDetail'
	set @sql='TRUNCATE TABLE ReportsFiltersCategory
			INSERT INTO ReportsFiltersCategory (ReportId, FilterName, Category, dbColumn, Description) VALUES
				(7010, ''acds'', 0, ''inboundId2'', ''Inbound Voice''),
				(7010, ''campaigns'', 0, ''campaignId2'', ''Outbound Voice''),
				(7010, ''campaigns'', 4, ''campaignId2'', ''Outbound AI''),
				(7010, ''campaigns'', 6, ''campaignId2'', ''Outbound Preview''),
				(4020, ''campaigns'', 0, ''campaignId'', ''Outbound Voice''),
				(4020, ''campaigns'', 4, ''campaignId'', ''Outbound AI''),
				(4020, ''campaigns'', 6, ''campaignId'', ''Outbound Preview'')
			'
	EXEC(@sql)

	-----------------------------------------------------END Enrique Ruiz -----------------------------------------------------------------

	-----------------------------------------------------BEGIN Gaby--------------------------------------------------------------------------
	
	SET @process = 'Drop procedure ccspRepInEffectiveness '
	SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepInEffectiveness'')
	BEGIN
	    DROP PROCEDURE ccspRepInEffectiveness;
	END'
	EXEC(@sql)

	SET @process = 'Create procedure ccspRepInEffectiveness '
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepInEffectiveness] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
SET NOCOUNT ON
SET ANSI_NULLS OFF
SET ANSI_WARNINGS OFF

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()


IF @action = 1
BEGIN
	--Consulta de agentes conectados agrupados por hora e inboundid
	CREATE TABLE [dbo].[#ccGenSession] ([user_id] [smallint] NOT NULL, fechaInicio [datetime] NOT NULL, [tlog] INT NOT NULL) ON [PRIMARY]

	CREATE TABLE #AgentsperInbound (NumberAgents INT, fechaInicio DATETIME, fechaFinal DATETIME, Inbound_id INT)

	INSERT INTO [#ccGenSession]
	SELECT A.user_id, convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + ''00:00'', 121) AS fechaInicio, sum(tlog) tlog
	FROM TmpSessionTimeGroup A
	GROUP BY A.user_id, convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + ''00:00'', 121);

	WITH RtnValue3
	AS (
		SELECT DISTINCT 1 AS cont, A.user_id, B.Inbound_id, A.fechaInicio, DATEADD(hh, 1, A.fechaInicio) AS fechaFinal
		FROM [#ccGenSession] A
		INNER JOIN ccinboundagentes B
			ON A.user_id = B.User_id
		)
	INSERT INTO #AgentsperInbound
	SELECT sum(cont) AS NumberAgents, fechaInicio, fechaFinal, Inbound_id
	FROM RtnValue3
	GROUP BY fechaInicio, fechaFinal, Inbound_id

	--Fin consulta agentes conectados por inbound
	CREATE TABLE [dbo].[#ccGenInCall] (
		[timegroup] [smalldatetime] NOT NULL, [inbound_id] [smallint] NOT NULL, [dni_id] [smallint] NOT NULL, [user_id] [smallint] NOT NULL, [ntotal] [smallint] NOT NULL, [nabnd] [smallint] NOT NULL, [nno_agent] [smallint] NOT 
		NULL, [nque] [smallint] NOT NULL, [ntimeout] [smallint] NOT NULL, [noverflow] [smallint] NOT NULL, [nno_answer] [smallint] NOT NULL, [nanswer] [smallint] NOT NULL, [nlost] [smallint] NOT NULL, [nabnd_tres] [smallint] 
		NOT NULL, [nansw_tres] [smallint] NOT NULL, [tque_max] [smallint] NOT NULL, [tque] [int] NOT NULL, [txfer] [int] NOT NULL, [tdialog] [int] NOT NULL, [tnotes] [int] NOT NULL, [tring] [int] NOT NULL, [tresp] [int] NOT NULL, 
		[nMoh] [smallint] NOT NULL DEFAULT((0)), [nWHag] [smallint] NOT NULL DEFAULT((0)), [nWHcl] [smallint] NOT NULL DEFAULT((0))
		) ON [PRIMARY]

	CREATE TABLE [dbo].[#agents] (
		[timegroup] [smalldatetime] NOT NULL, [user_id] [smallint] NOT NULL, [tlog] [int] NOT NULL DEFAULT(0), [treq] [int] NOT NULL DEFAULT(0), [tnot_av] [int] NOT NULL, [tav] [int] NOT NULL DEFAULT(0), [tprob] [int] NOT NULL 
		DEFAULT(0), [tunknown] [int] NOT NULL DEFAULT(0), [tother] [int] NOT NULL DEFAULT(0), [nother] [int] NOT NULL DEFAULT(0), [nMoh] [int] NOT NULL DEFAULT((0)), [nWHag] [int] NOT NULL DEFAULT((0
				)), [nWHcl] [int] NOT NULL DEFAULT((0))
		) ON [PRIMARY]

	CREATE TABLE [dbo].[#ccGenInSpec] ([timegroup] [smalldatetime] NOT NULL, [inbound_id] [smallint] NOT NULL, [pos_tot] [smallint] NOT NULL, [pos_time] [int] NOT NULL, [pos_efect] [smallint] NOT NULL) ON [PRIMARY]

	CREATE TABLE [dbo].[#ccGenInAbnd] (
		[timegroup] [smalldatetime] NOT NULL, [inbound_id] [smallint] NOT NULL, [amount] [smallint] NOT NULL, [time_max] [smallint] NOT NULL, [time_tot] [bigint] NOT NULL, [<10] [smallint] NOT NULL, [<20] [smallint] NOT NULL, 
		[<30] [smallint] NOT NULL, [<40] [smallint] NOT NULL, [<50] [smallint] NOT NULL, [<60] [smallint] NOT NULL, [<120] [smallint] NOT NULL, [<180] [smallint] NOT NULL, [<240] [smallint] NOT NULL, [<300] [smallint] NOT NULL, 
		[+300] [smallint] NOT NULL
		) ON [PRIMARY]

	INSERT INTO #ccGenInCall (
		timegroup, inbound_id, dni_id, [user_id], ntotal, nabnd, nno_agent, nque, ntimeout, noverflow, nno_answer, nanswer, nlost, nabnd_tres, nansw_tres, tque_max, tque, txfer, tring, tdialog, tnotes, tresp, nMoh, nWHag, 
		nWHcl
		)
	SELECT convert(DATETIME, convert(VARCHAR(14), dateStartDetail, 121) + ''00:00'', 121) AS timegroup, Inbound_id, dni_id, User_id, isnull(sum(ntotal), 0) AS ntotal, isnull(sum(nabnd), 0) AS nabnd, isnull(sum(nno_agent), 0) AS 
		nno_agent, isnull(sum(nque), 0) AS nque, isnull(sum(ntimeout), 0) AS ntimeout, isnull(sum(noverflow), 0) AS noverflow, isnull(sum(nno_answer), 0) AS nno_answer, isnull(sum(nanswer), 0) AS nanswer, isnull(sum(nlost
			), 0) AS nlost, isnull(sum(nabnd_tres), 0) AS nabnd_tres, isnull(sum(nansw_tres), 0) AS nansw_tres, isnull(max(tque_max), 0) AS tque_max, isnull(sum(tque), 0) AS tque, isnull(sum(txfer), 0) AS txfer, isnull(sum(tring), 0) AS tring, 
			isnull(sum(tdialog), 0) AS tdialog, isnull(sum(tnotes), 0) AS tnotes, isnull(sum(tresp), 0) AS tresp, isnull(sum(nMoh), 0) AS nMoh, isnull(sum(nWHag), 0) AS nWHag, isnull(sum(nWHcl), 0) AS nWHcl
	FROM tmpTimesInboundData
	GROUP BY convert(DATETIME, convert(VARCHAR(14), dateStartDetail, 121) + ''00:00'', 121), inbound_id, dni_id, [user_id];

	WITH timeAgent
	AS (
		SELECT convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + ''00:00'', 121) timegroup, userId, ISNULL(SUM(CASE WHEN (tipostatusage_id = 2) THEN tStatus ELSE NULL END), 0) AS 
			tnot_av, ISNULL(SUM(CASE WHEN (tipostatusage_id = 3) THEN tStatus ELSE NULL END), 0) AS tav, ISNULL(SUM(CASE WHEN (tipostatusage_id = 11) THEN 
								tStatus ELSE NULL END), 0) AS tprob, ISNULL(SUM(CASE WHEN (tipostatusage_id = 1) THEN tStatus ELSE NULL END), 0) AS tunknown, ISNULL(SUM(CASE WHEN (tipostatusage_id = 7
								) THEN tStatus ELSE NULL END), 0) AS tother, COUNT(CASE WHEN (tipostatusage_id = 7) THEN 1 ELSE NULL END) AS nother
		FROM tmpccLogAgentesDia
		GROUP BY convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + ''00:00'', 121), userId
		)
	INSERT INTO #agents (timegroup, [user_id], tlog, tnot_av, tav, tprob, tunknown, tother, nother, nMoh, nWHag, nWHcl)
	SELECT A.fechaInicio AS timegroup, A.user_id, A.tlog, isnull(B.tnot_av, 0) AS tnot_av, isnull(B.tav, 0) AS tav, isnull(B.tprob, 0) AS tprob, isnull(B.tunknown, 0) AS tunknown, isnull(B.tother, 0) AS tother, isnull(B.nother
			, 0) AS nother, isnull(ci.nMoh, 0) AS nMoh, isnull(ci.nWHag, 0) AS nWHag, isnull(ci.nWHcl, 0) AS nWHcl
	FROM [#ccGenSession] A
	LEFT JOIN timeAgent B
		ON A.user_id = B.userId
			AND A.fechaInicio = B.timegroup
	LEFT JOIN #ccGenInCall ci
		ON A.user_id = ci.user_id
			AND A.fechaInicio = ci.timegroup

	INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
	SELECT timegroup, ccInboundAgentes.inbound_id, 
	COUNT(DISTINCT #agents.[user_id]) AS pos_max, 
	SUM(tlog - (tnot_av + tprob + tother)) AS pos_time, 
	COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
	FROM #agents
	INNER JOIN ccInboundAgentes
		ON (#agents.[user_id] = ccInboundAgentes.[user_id])
	WHERE timegroup >= @from
		AND timegroup < @to
		AND INBOUND_ID > 0
	GROUP BY timegroup, ccInboundAgentes.inbound_id		
		;

	WITH callInAbnd
	AS (
		SELECT convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + ''00:00'', 121) AS timegroup, inbound_id, tque + txfer + tring AS tAbnd, nabnd, CASE WHEN statuscall_id IN (5, 6)
					AND nabnd > 0 THEN 1 ELSE 0 END nabnd2
		FROM tmpTimesInboundData
		WHERE statuscall_id IN (5, 6)
		)
	INSERT INTO #ccGenInAbnd
	SELECT timegroup, inbound_id, sum(nabnd2) amount, max(tAbnd) time_max, sum(tAbnd) AS time_tot, COUNT(CASE WHEN tAbnd < 10 THEN 1 ELSE NULL END) AS [<10], COUNT(CASE WHEN tAbnd BETWEEN 10
						AND 19 THEN 1 ELSE NULL END) AS [<20], COUNT(CASE WHEN tAbnd BETWEEN 20
						AND 29 THEN 1 ELSE NULL END) AS [<30], COUNT(CASE WHEN tAbnd BETWEEN 30
						AND 39 THEN 1 ELSE NULL END) AS [<40], COUNT(CASE WHEN tAbnd BETWEEN 40
						AND 49 THEN 1 ELSE NULL END) AS [<50], COUNT(CASE WHEN tAbnd BETWEEN 50
						AND 59 THEN 1 ELSE NULL END) AS [<60], COUNT(CASE WHEN tAbnd BETWEEN 60
						AND 119 THEN 1 ELSE NULL END) AS [<120], COUNT(CASE WHEN tAbnd BETWEEN 120
						AND 179 THEN 1 ELSE NULL END) AS [<180], COUNT(CASE WHEN tAbnd BETWEEN 180
						AND 239 THEN 1 ELSE NULL END) AS [<240], COUNT(CASE WHEN tAbnd BETWEEN 240
						AND 299 THEN 1 ELSE NULL END) AS [<300], COUNT(CASE WHEN tAbnd >= 300 THEN 1 ELSE NULL END) AS [+300]
	FROM callInAbnd
	GROUP BY timegroup, inbound_id

	--Borrar lo que esta para no repetir  
	DELETE	FROM RepInEffectiveness 	WHERE DATE >= @from		AND DATE < @to
	
	;with xDetCall as(
	SELECT timegroup, inbound_id, SUM(ntotal) AS ntotal, SUM(nanswer) AS nanswer, SUM(nabnd) AS nabnd, SUM(tdialog + tnotes) tatention, ISNULL(sum(tque) / NULLIF(sum(nque), 0), 0) AS tque_avg, sum(tque) AS tQue_tot, sum(nQue) 
		AS nQue_tot, SUM(nansw_tres + nabnd_tres) AS SL_P_1, SUM(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, SUM(tresp) AS tresp
	FROM #ccGenInCall
	WHERE timegroup >= @from
		AND timegroup < @to
	GROUP BY timegroup, inbound_id
	),xDetSpec as(
	SELECT timegroup, inbound_id, SUM(pos_tot) AS pos_tot, SUM(pos_tot) AS pos_avg, SUM(pos_efect) AS pos_efect
			FROM #ccGenInSpec
			WHERE timegroup >= @from
				AND timegroup < @to
			GROUP BY timegroup, inbound_id
	),xDetAbnd as (
	SELECT timegroup, inbound_id, SUM(time_tot) AS tabnd_tot
			FROM #ccGenInAbnd
			WHERE timegroup >= @from
				AND timegroup < @to
			GROUP BY timegroup, inbound_id
	),xDetail as(
	SELECT ISNULL(xDetCall.timegroup, ISNULL(xDetSpec.timegroup, xDetAbnd.timegroup)) timegroup, ISNULL(xDetCall.inbound_id, ISNULL(xDetSpec.inbound_id, xDetAbnd.inbound_id)) inbound_id, ISNULL(ntotal, 0) 
			ntotal, ISNULL(nanswer, 0) nanswer, ISNULL(nabnd, 0) nabnd, ISNULL(tatention, 0) tatention, ISNULL(tque_avg, 0) tque_avg, isnull(tQue_tot, 0) tQue_tot, isnull(nQue_tot, 0) nQue_tot, ISNULL(tabnd_tot, 0) 
			tabnd_tot, ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2, ISNULL(tresp, 0) tresp, ISNULL(pos_tot, 0) pos_tot
		FROM  xDetCall
		LEFT JOIN xDetSpec
			ON 
					xDetCall.timegroup = xDetSpec.timegroup
					AND xDetCall.inbound_id = xDetSpec.inbound_id
					
		LEFT JOIN  xDetAbnd
			ON 
					xDetCall.timegroup = xDetAbnd.timegroup
					AND xDetCall.inbound_id = xDetAbnd.inbound_id
	)
	----------
	INSERT INTO RepInEffectiveness
	SELECT timegroup AS DATE, xDetail.inbound_id, isnull(descripcion, ''systemTranslated_NoACDGroup'') descripcion, ntotal, nanswer, nabnd, 
	isnull(tatention / nullif(nanswer, 0), 0) as tatencion, tque_avg AS tqueavg, tQue_tot AS tQuetot
		, nQue_tot AS nQuetot, isnull(tabnd_tot / NULLIF(nabnd, 0), 0) AS avgAbandonTime, SL_P_1 AS SLP1, SL_P_2 AS SLP2, tresp,
		isnull(c.NumberAgents,0) AS NumberAgents, ISNULL(SL_P_1 * 100 / NULLIF(SL_P_2, 0), 0) AS Porcentaje
		, datepart(yyyy, timegroup) AS [year]
		, datepart(mm, timegroup) AS [month]
		, datepart(dd, timegroup) AS [day]
		, datepart(hh, timegroup) AS [hour]
		, 0 AS [minutes]
		, convert(DECIMAL(10, 2), (nabnd / nullif(convert(DECIMAL(10, 2), ntotal), 0)) * 100) AS [avgAbandon]
		, tabnd_tot AS tabndtot
	FROM xDetail
	LEFT JOIN ccInbound ON xDetail.inbound_id = ccInbound.inbound_id
	left join #AgentsperInbound C on xDetail.inbound_id=C.Inbound_id and xDetail.timegroup=C.fechaInicio
	ORDER BY DATE

	
	DROP TABLE #ccGenInCall

	DROP TABLE #ccGenInSpec

	DROP TABLE #ccGenSession

	DROP TABLE #agents

	DROP TABLE #ccGenInAbnd

	DROP TABLE #AgentsperInbound
END'
	EXEC(@sql)

	SET @process = 'K061021 DROP VIEW RepViewIneffectiveness'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(''dbo.RepViewIneffectiveness'') AND type = ''V'')
    BEGIN
        DROP VIEW dbo.RepViewIneffectiveness
    END'
	EXEC(@sql)

	SET @process = 'K061021 CREATE VIEW RepViewInEffectiveness'
	SET @sql = '
	CREATE VIEW [RepViewInEffectiveness] AS SELECT 
	date,
	inboundId,
	inbound as campaign,
	ntotalin,
	nanswer2,
	nabnd,
	tatencion,
	tqueavg,
	tQuetot,
	nQuetot,
	avgAbandonTime,
	SLP1,
	SLP2,
	tresp,
	tabndtot,
	poscount,
	Porcentaje,
	year,
	month,
	day,
	hour,
	minutes,
	avgAbandon
	FROM RepInEffectiveness NOLOCK'
	EXEC(@sql)

	set @process = 'Alter table RepOutAnswAndXferCalls alter column iva'
	set @sql = '
	if EXISTS(
		select column_name
		from information_schema.columns  
		where table_name = ''RepOutAnswAndXferCalls'' AND column_name = ''iva''
		AND DATA_TYPE = ''int''
	)
	BEGIN
		alter table RepOutAnswAndXferCalls alter column iva varchar(5)
	END'
	EXEC(@sql)

	SET @process = 'Drop procedure ccspRepOutAnswAndXferCalls '
	SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepOutAnswAndXferCalls'')
	BEGIN
	    DROP PROCEDURE ccspRepOutAnswAndXferCalls;
	END'
	EXEC(@sql)

	SET @process = 'Create procedure ccspRepOutAnswAndXferCalls '
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = NULL

AS

SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = CONVERT(DATETIME,CONVERT(VARCHAR(11),GETDATE()))
IF @to IS NULL
	SELECT @to = GETDATE()

DECLARE @IVA VARCHAR(3)
DECLARE @country AS TINYINT
SELECT @IVA = ISNULL(valor,0) FROM ccsettings WHERE setting_id = 25
--SELECT @IVA = CONVERT(INT,ISNULL(valor,0)) FROM ccsettings WHERE setting_id = 25
SELECT @country = CONVERT(TINYINT,ISNULL(valor,1)) FROM ccsettings WHERE setting_id = 104

IF @country IS NULL SET @country = 1

IF @action = 1
BEGIN
--Borrar lo que esta para no repetir
DELETE FROM RepOutAnswAndXferCalls WHERE DATE >= @from AND DATE < @TO

declare @descriptionXfer varchar(100)

SELECT @descriptionXfer=[description] FROM dialType WHERE dialId = 3

;with ccld as(
	SELECT *, [dbo].[GetProveedor](Telefono, Puerto,tipoLlamada_id) AS proBIDs,tipoLlamada_id as CallType  FROM ccologdials
	WHERE fecha between @from and @to and answerbit = 1
)

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
	ISNULL(dialType.[description],''systemTranslated_Auto'') AS [dialType],
	case when CHARINDEX(''local'', tl.descrip COLLATE Latin1_General_CI_AS) > 0 or CHARINDEX(''fijo'', tl.descrip COLLATE Latin1_General_CI_AS) > 0 then ''systemTranslated_fijo''
	when CHARINDEX(''movil'', tl.descrip COLLATE Latin1_General_CI_AS) > 0 or CHARINDEX(''cel'', tl.descrip COLLATE Latin1_General_CI_AS) > 0 then ''systemTranslated_cellPhone''
	else ''systemTranslated_Indefinite'' end AS [CallTypes],
	CASE 
		WHEN provedor_id IS NOT NULL THEN dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),COALESCE(Call.provedor_id,ccld.proBIDs),
			dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg), @country)
		ELSE  CONVERT(DECIMAL(10,2),(CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) / 60) * ccost.additional_min)))
	END AS [ncost],
	@IVA+''%'' AS iva,
	CASE
		WHEN provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),
				COALESCE(Call.provedor_id,ccld.proBIDs), dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg), @country),0.00) * (1 + (@IVA / 100.00)))
		ELSE  CONVERT(DECIMAL(10,2),((CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) / 60) * ccost.additional_min)) * (1 + (@IVA / 100.00))))
	END	AS total,
	COALESCE(ccld.Puerto, Call.cal_puerto, 0) as [trunk],
	case when dbo.TelAni(ccld.Telefono, camps.id_anilist) <> '''' then dbo.TelAni(ccld.Telefono, camps.id_anilist) else camps.ani end [ANI],
	COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) as dialTimeSec
FROM ccld
	LEFT JOIN ccoCallsOut Call WITH(NOLOCK) ON ccld.cal_id = Call.cal_id
			AND ccld.answerbit = 1
	LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
	LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
	LEFT JOIN ccCallCost_RIA ccost (NOLOCK) ON ccost.tipoLlamada_id = tl.tipoLlamada_id		AND ccost.country_id = tl.country_id
	left join dialType on dialType.dialId = Call.cal_manual


;with clt as (

SELECT *
, DATEADD(ss,-(tAntesXfer + tDespuesXfer),fechaFin) AS [date]
, tipoLlamada_id AS  CallType 
,case WHEN modo in(5,6) then abs(destino) else null end posicion
	FROM cclogtransfers WITH(NOLOCK) 
	WHERE modo not in (1,2) 
		AND (tAntesXfer > 0 or tDespuesXfer > 0) 
		AND fechaFin between @from and @to
)


INSERT INTO RepOutAnswAndXferCalls	
SELECT clt.[date],
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
		WHEN modo = 0 THEN clt.destino
		WHEN modo = 3 THEN clt.destino 
		WHEN modo = 4 THEN clt.destino 
		WHEN modo in(5,6) THEN isnull((SELECT top 1 Computer FROM ccposicion WHERE pos_id = posicion),clt.destino) 
	END AS [telephone],
	3 AS [dialId],
	@descriptionXfer AS [dialType],
	case when CHARINDEX( ''local'', tl.descrip COLLATE Latin1_General_CI_AS) > 0 or CHARINDEX( ''fijo'', tl.descrip COLLATE Latin1_General_CI_AS) > 0 then ''systemTranslated_fijo''
	when CHARINDEX( ''movil'', tl.descrip COLLATE Latin1_General_CI_AS) > 0 or CHARINDEX( ''cel'', tl.descrip COLLATE Latin1_General_CI_AS) > 0 then ''systemTranslated_cellPhone''
	else ''systemTranslated_Indefinite'' end AS [CallTypes],
	CASE 
		WHEN tarifa.provedor_id IS NOT NULL THEN ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
			dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) ,@country), 0) 
		ELSE cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)
	END AS [ncost],
	@IVA+''%'' AS iva,
	CASE 
		WHEN tarifa.provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
			dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0)
			,@country),0.00) * (1 + (@IVA / 100.00))) 
		ELSE (cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)) * (1 + (@IVA / 100.00))
	END AS [total],
	IsNull(clt.channel, 0) as [trunk],
	case when (@country = 1 and modo = 4) then case when dbo.TelAni(clt.destino, camps.id_anilist) <> '''' then dbo.TelAni(clt.destino,camps.id_anilist) else camps.ani end else '''' end [ANI],
	ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) as dialTimeSec
FROM clt
	LEFT JOIN cccallsin ci WITH(NOLOCK) ON ci.cal_id=clt.cal_id AND tipo=1
	LEFT JOIN ccocallsout co WITH(NOLOCK) ON co.cal_id=clt.cal_id AND tipo=2 
	LEFT JOIN ccChannelTransfer channel ON clt.pbxId=channel.pbxId AND clt.channel BETWEEN channel.startChannel AND channel.endChannel
	LEFT JOIN cstoTarifa tarifa ON tarifa.provedor_id=channel.proveedorId AND tarifa.tipoLlamada_id = clt.CallType
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType AND tl.Country_id = @country)
	LEFT JOIN ccCallCost_RIA cCall ON cCall.country_id = tl.country_id AND cCall.tipoLlamada_id = tl.tipoLlamada_id
	LEFT JOIN ccCamps camps ON camps.[cam_id] = co.cam_id
	LEFT JOIN ccInbound ACD ON ACD.[Inbound_id] = ci.Inbound_id

end'
	EXEC(@sql)

	SET @process = 'K061004 Insert into ReportsFilteredByHourRange report 3060'
	SET @sql = 'IF NOT EXISTS (SELECT * FROM ReportsFilteredByHourRange WHERE id = 3060) 
	BEGIN
		INSERT INTO ReportsFilteredByHourRange (id, reportName, groupDayWithHHmm) VALUES (3060, ''RepViewIneffectiveness'', 0)
	END'
	EXEC(@sql)

	SET @process = 'K062019 Insert into ReportsFilteredByHourRange report 4250'
	SET @sql = 'IF NOT EXISTS (SELECT * FROM ReportsFilteredByHourRange WHERE id = 4250) 
	BEGIN
		INSERT INTO ReportsFilteredByHourRange (id, reportName, groupDayWithHHmm) VALUES (4250, ''RepOutAnswAndXferCalls'', 0)
	END'
	EXEC(@sql)

	set @process = 'K061009-K062016  ReportsFiltersCategory '
	set @sql='
			INSERT INTO ReportsFiltersCategory (ReportId, FilterName, Category, dbColumn, Description) VALUES
				(3060, ''acds'', 0, ''inboundId'', ''Inbound Voice''),
				(4250, ''campaigns'', 0, ''campaignId'', ''Outbound Voice''),
				(4250, ''campaigns'', 4, ''campaignId'', ''Outbound AI''),
				(4250, ''campaigns'', 6, ''campaignId'', ''Outbound Preview'')
			'
	EXEC(@sql)




	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

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
