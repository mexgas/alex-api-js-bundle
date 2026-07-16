SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 88

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	SET @process = 'CW-4282 Se modifica sp ccspRepInNotTransferred'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepInNotTransferred]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	--1 as wgId
	--Borrar lo que esta para no repetir
	delete from RepInNotTransferred with(rowlock)
	where date >= @from AND date < @to

	insert into RepInNotTransferred
	select a.cal_Inicio as [date], a.Inbound_id, 
	b.descripcion as acd, a.statusCall_id, isnull(d.descripcion,'''') as statusCall,isnull(d.descripcion,'''')  + ''_Count'' as statusCallCount,1 as [count],  b.IDArea, 
	isnull(Area.AreaName, '''') as area, c.IDWG as wgId, isnull(c.WGName,''systemTranslated_WorkGroup'') as wg
	,datepart(yyyy,cal_inicio) as [year]
	,datepart(mm,cal_inicio) as [mount]
	,datepart(dd,cal_inicio) as [day]
	,datepart(hh,cal_inicio) as [hour]
	,datepart(mi,cal_inicio) as [minutes]
	,a.cal_id as cal_id,isnull(a.cal_Ani,'''') as phone_in
	from cccallsin a 		
	inner join ccWgByAcdView b on a.Inbound_id=b.Inbound_id
	left join ccRIACat_WorkGroup c on c.IDWG=b.IDWG
	left join ccstatusllamada d	on a.statusCall_id = d.statusCall_id
	left join ccRIACat_Areas Area on Area.IDArea=b.IDArea
	where cal_inicio >= @from AND cal_inicio < @to and 
	a.statuscall_id in (1,2,3,4,6,7,8)
	and  b.IDArea is not null
end'
        EXEC(@sql)



		SET @process = 'CW-4282 Se modifica sp ccspRepInDispositions'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepInDispositions] 
@action AS TINYINT, 
@from AS DATETIME = NULL, 
@to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	--Borrar lo que esta para no repetir
	DELETE
	FROM RepInDispositions WITH (ROWLOCK)
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepInDispositions
	SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + '':00'', 121), Inbound_id, ACDGroup, dispositionId, DispName, disposition_count, count(dispositionId) DispAmount, User_id, LOGIN, username, IDArea, areaName, IDWG AS wgId, wg, datepart(yyyy, max(dateHour)) AS year, datepart(mm, max(dateHour)) AS mes, datepart(dd, max(dateHour)) AS dia, datepart(hh, max(dateHour)), 0
	FROM (
		SELECT a.cal_inicio AS dateHour, a.Inbound_id, isnull(b.descripcion, '''') as ACDGroup, a.calif_id AS dispositionId, DispName = isnull(description, ''systemTranslated_Dispositionless''), disposition_count = isnull(description, ''systemTranslated_Dispositionless'') + ''_Count'', a.User_id, LOGIN = isnull(LOGIN, ''''), username = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, ''''), b.IDArea, isnull(AreaName, '''') AS areaName, c.IDWG, isnull(c.WGName,''systemTranslated_WorkGroup'') AS wg
		FROM cccallsin a
		INNER JOIN ccWgByAcdView b ON a.Inbound_id=b.Inbound_id
		LEFT JOIN ccRIACat_WorkGroup c ON c.IDWG=b.IDWG
		--INNER JOIN ccRIACampEspWG c ON b.Inbound_id=c.IdCampEsp
		LEFT JOIN cctipocalif tc ON a.calif_id = tc.calif_id
		LEFT JOIN ccUserView d ON a.User_id = d.user_id
		LEFT JOIN ccRIACat_Areas e ON b.IdArea = e.IDArea
		WHERE cal_inicio >= @from AND cal_inicio < @to AND a.statuscall_id = 13 --Constestada
			AND b.IDArea IS NOT NULL
		
		UNION

		SELECT requestDate, a.inboundId, isnull(b.descripcion, '''') as ACDGroup, a.disposition, DispName = isnull(description, ''systemTranslated_Dispositionless''), disposition_count = isnull(description, ''systemTranslated_Dispositionless'') + ''_Count'', a.userId, LOGIN = isnull(LOGIN, ''''), username = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, ''''), b.IDArea, isnull(AreaName, '''') AS areaName, b.IDWG, isnull(c.WGName,''systemTranslated_WorkGroup'') AS wg
		FROM ccRIAChats a
		--LEFT JOIN ccInbound b ON b.Inbound_id = a.inboundId
		INNER JOIN ccWgByAcdView b ON a.inboundId=b.Inbound_id
		LEFT JOIN ccRIACat_WorkGroup c ON c.IDWG=b.IDWG
		--INNER JOIN ccRIACampEspWG c ON b.Inbound_id=c.IdCampEsp
		LEFT JOIN cctipocalif tc ON a.disposition = tc.calif_id
		LEFT JOIN ccUserView d ON a.userId = d.user_id
		LEFT JOIN ccRIACat_Areas e ON b.IdArea = e.IDArea
		WHERE requestDate >= @from AND requestDate < @to AND a.chatStatus = 3 --Assigned
			AND b.IDArea IS NOT NULL
		) AS x
	GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + '':00'', 121), Inbound_id, ACDGroup, dispositionId,  DispName, disposition_count, user_id, LOGIN, username, IDArea, areaName, IDWG, wg
END'
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

