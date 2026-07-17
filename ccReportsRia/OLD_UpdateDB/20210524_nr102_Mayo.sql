SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 102

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'CW-5178 Create Table ccRIACampEspWGConsulta'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccRIACampEspWGConsulta'')begin

CREATE TABLE [dbo].[ccRIACampEspWGConsulta](
	[IDWG] [smallint] NOT NULL,
	[Tipo] [smallint] NOT NULL,
	[IdCampEsp] [smallint] NOT NULL	
)

end'
		EXEC(@sql)

		SET @process = 'CW-5178 DROP Create View'
		SET @sql = 'if exists (select * FROM sys.views where name = N''ccRIACampEspWGView'')
    begin
        DROP VIEW [dbo].[ccRIACampEspWGView]
    end'
		EXEC(@sql)

		SET @process = 'CW-5178 create View'
		SET @sql = 'CREATE VIEW [dbo].[ccRIACampEspWGView] AS
select A.IDWG,B.IdCampEsp,A.WGName, Tipo from ccriacat_workgroup A 
	inner join ccRIACampEspWG B on A.IDWG=B.IDWG 

union
select A.IDWG,B.IdCampEsp,A.WGName, Tipo from ccriacat_workgroup A 
	inner join ccRIACampEspWGConsulta B on A.IDWG=B.IDWG '
		EXEC(@sql)

		SET @process = 'CW-5178 ALTER SP '
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

create table #detailWorkGroup(
	IDWG int not null,
	idCampaing int not null,
	WGName varchar(45)
)

if @action = 1
begin

	insert into #detailWorkGroup
	SELECT IDWG, IdCampEsp, WGName from ccRIACampEspWGView where Tipo = 1
	 
	--Borrar lo que esta para no repetir
	delete from RepOutDispositions with(rowlock) 	where date >= @from AND date < @to

	--CTE
	;with callOut as(
	select CONVERT(smalldatetime, CONVERT(varchar(13), a.cal_inicio,121) + '':00'', 121) as date, 
		a.cam_id, a.calif_id, count(calif_id) DispAmount, user_id	
		from ccocallsout a 			
		where cal_inicio >= @from AND cal_inicio < @to and 
		a.statuscall_id = 13 and cal_manual in (0,2)	
		group by CONVERT(smalldatetime, CONVERT(varchar(13), a.cal_inicio,121) + '':00'', 121), a.cam_id, a.calif_id, user_id
		)

insert into  RepOutDispositions
	select A.date,a.cam_id, ISNULL(b.cam_descripcion,'''') as Campaign,
	a.calif_id, isnull(c.Description,''systemTranslated_Dispositionless'') as DispName, 
	isnull(c.Description,''systemTranslated_Dispositionless'')+''_Count'' as disposition_count,
    a.DispAmount as [count], A.user_id, ISNULL(d.login,'''') [login],
    isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''') as username, 
	isnull(b.IDArea,0) as IDArea, isnull(e.AreaName,'''') as areaName, 1 as wgId, ''systemTranslated_WorkGroup'' as wg,
	datepart(yyyy,date) as year, datepart(mm,date) as mounth, datepart(dd,date) as day,
	datepart(hh,date) as hour, datepart(mi,date) as min
	from callOut A
	left join cccamps b on a.cam_id = b.cam_id
	left join cctipocalifout c on A.calif_id = c.calif_id
	left join ccUserView d on a.User_id = d.User_id
	left join ccRIACat_Areas e on b.IDArea = e.IDArea

	update A set A.areaId = B.IDArea, A.area = C.AreaName
    from RepOutDispositions A
    inner join ccRIAAreaWorkGroup B on A.workgroupId = B.IDWG
    inner join ccRIACat_Areas C on C.IDArea = B.IDArea
    where [date] >= @from AND [date] < @to and areaId=0 
    
    update a set a.workgroupId = isnull(b.IDWG,0), a.wg = isnull(b.WGName, ''-'')
	from RepOutDispositions a
	left join #detailWorkGroup b	
    on a.campaignId = b.idCampaing
	where [date] >= @from AND [date] < @to

	drop table #detailWorkGroup

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

