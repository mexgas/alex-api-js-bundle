SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 128

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	----------------------------------------------------------------------------------------------------------------------

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
	callHung,
	recibeCallBy,
	cal_final
FROM
RepInCallsDetail NOLOCK'
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
					WHEN B.statusTime > 0 THEN ''collectCallYes''
					ELSE ''collectCallNo''
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
				WHEN statusLlamada.descripcion IS NOT NULL THEN ''collectCallYes''
				ELSE ''collectCallNo''
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

update ReportsFilters set filterName = ''inboundCamps'' where id=3010
'
	EXEC (@sql)


SET @process = 'K061001 Alter procedure ccspRepCatalogos'
SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepCatalogos]
	@type as tinyint,
	@action tinyint = 0 -- 0 Filter select; 1 Filters Range
	,@userId int =0 ---- se agrega parametro para filtros

	AS
	declare @tablatemp table (id int, description varchar(100) null)
	declare @tempwork table (idwg int)

	if @action = 0
	begin


		-- CAMPAIGNS
	if @type = 1 begin

		if @userId <> 0 begin

			insert into @tablatemp
			select distinct caesp.IdCampEsp,'' '' as description  from ccUserView us
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
	if @type = 7 begin
		if @userId <> 0 begin

				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
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

	end
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



	
	----------------------------------------------------------------------------------------------------------------------

	
	
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
