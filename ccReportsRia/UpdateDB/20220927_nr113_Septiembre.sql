
SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 113

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'KR048001 y KR048002 new Setting abandon'
	set @sql = '
	if NOT EXISTS(Select setting_id from ccsettings where setting_id=43)
	begin
    insert into ccSettings(setting_id,valor,descripcion,Status,Tipo) values(43,''0'',''Abandon in Reports status 6'',1,''RPT'')
	end
	'
	EXEC(@sql)

	set @process = 'KR048001 y KR048002 ccspRepSpececialAbnd DROP'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepSpececialAbnd'')
	begin
        DROP PROCEDURE ccspRepSpececialAbnd;
    end
	'
	EXEC(@sql)

	set @process = 'KR048001 y KR048002 ccspRepSpececialAbnd CREATE'
	set @sql = '
CREATE PROCEDURE [dbo].[ccspRepSpececialAbnd]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

declare @setting smallint
select @setting= valor from ccSettings where setting_id=43
if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()

	delete RepSpececialAbnd with(rowlock)
	where [date] between @from and @to
	
	insert RepSpececialAbnd select [date], campaignId, inboundId, [Espec/Camp], total, abandonedCalls, 
	cast(((abandonedCalls*100.0)/total) as decimal(5,2)) abandonedCallsPctg from (
		select convert(varchar(10),cal_inicio,121) [date], 0 campaignId, ci.inbound_id inboundId, 
		''ACD - '' + descripcion [Espec/Camp], count(*) total, 
		COUNT(
		CASE WHEN @setting = 0 and (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00''))  THEN 1
			 WHEN @setting = 1 and (statuscall_id IN (6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00'')) THEN 1
		 ELSE NULL END) abandonedCalls
		from cccallsin ci with(index(IX_ccCallsIn),nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id 
		where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, ''ACD - '' + descripcion
		union all
		select convert(varchar(10),cal_inicio,121) [date], co.cam_id campaignId, 0 inboundId, 
		''Camp - '' + cam_descripcion [Espec/Camp], count(*) total, 
		COUNT(
			CASE WHEN @setting = 0 and (statuscall_id in(11,15,16))THEN cal_id 
				 WHEN @setting = 1 and (statuscall_id in(6))THEN cal_id ELSE NULL END) abandonedCalls
		from ccocallsout co with(index(IX_ccoCallsOut_2),nolock) left join cccamps ca on ca.cam_id=co.cam_id 
		where cal_inicio between @from and @to and cal_manual in (0,2) group by convert(varchar(10),cal_inicio,121), co.cam_id, ''Camp - '' + cam_descripcion
    ) abnd
end
    '
	EXEC(@sql)

set @process = 'KR048001 y KR048002 ccspRepSpececialAbndPercentage DROP'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepSpececialAbndPercentage'')
	begin
        DROP PROCEDURE ccspRepSpececialAbndPercentage;
    end
	'
	EXEC(@sql)

set @process = 'KR048001 y KR048002 ccspRepSpececialAbndPercentage CREATE'
	set @sql = '
CREATE PROCEDURE [dbo].[ccspRepSpececialAbndPercentage]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS
declare @setting smallint
set @setting=1
select @setting= valor from ccSettings where setting_id=43 

begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null
		select @to = getdate()

	delete RepSpececialAbndPercentage with(rowlock)
	where [date] between @from and @to

	insert RepSpececialAbndPercentage select [date], inboundId, [inbound]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [5]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [10]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [15]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [20]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [25]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [30]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [40]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [50]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [60]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [>60]
			from (
				select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
				,cal_id
				,SUM(CASE WHEN  @setting = 0 and (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) 
						  WHEN  @setting = 1 and (statuscall_id = 6) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
				,COUNT(
					CASE WHEN @setting = 0 and (statuscall_id <> 13) THEN 1 
					     WHEN @setting = 1 and (statuscall_id = 6) THEN 1 ELSE NULL END) AS nAbnd
				from cccallsin ci with(index(IX_ccCallsIn),nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id
				where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
			) xCalls
		GROUP BY [date], inboundId, [inbound]
end
'
EXEC(@sql)

set @process = 'KR048001 y KR048002 ccspRepSpececialAbndProfiles'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepSpececialAbndProfiles'')
	begin
        DROP PROCEDURE ccspRepSpececialAbndProfiles;
    end
	'
	EXEC(@sql)

set @process = 'KR048001 y KR048002 ccspRepSpececialAbndProfiles'
	set @sql = '
CREATE PROCEDURE [dbo].[ccspRepSpececialAbndProfiles]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS
declare @setting smallint
select @setting= valor from ccSettings where setting_id=43
if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null
		select @to = getdate()

	delete RepSpececialAbndProfiles with(rowlock)
	where [date] between @from and @to

	insert RepSpececialAbndProfiles select [date], inboundId, [inbound]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))) AS [5]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))) AS [10]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))) AS [15]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))) AS [20]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))) AS [25]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))) AS [30]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))) AS [40]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))) AS [50]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))) AS [60]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 THEN 1 ELSE NULL END),0))) AS [>60]
		, COUNT(*) total
			from (
				select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
				,cal_id
				,SUM(CASE WHEN  @setting = 0 and (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) 
						  WHEN  @setting = 1 and (statuscall_id = 6) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
				,COUNT(
					CASE WHEN @setting = 0 and (statuscall_id <> 13) THEN 1 
					     WHEN @setting = 1 and (statuscall_id = 6) THEN 1 ELSE NULL END) AS nAbnd
				from cccallsin ci with(index(IX_ccCallsIn),nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id
				where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
			) xCalls
		GROUP BY [date], inboundId, [inbound]
end
'
EXEC(@sql)

set @process = 'KR048001 y KR048002 ccspRepSpececialAbndTimes'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepSpececialAbndTimes'')
	begin
        DROP PROCEDURE ccspRepSpececialAbndTimes;
    end
	'
	EXEC(@sql)

set @process = 'KR048001 y KR048002 ccspRepSpececialAbndTimes'
	set @sql = '
CREATE PROCEDURE [dbo].[ccspRepSpececialAbndTimes]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

declare @setting smallint
select @setting= valor from ccSettings where setting_id=43

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null
		select @to = getdate()

	delete RepSpececialAbndTimes with(rowlock)
	where [date] between @from and @to

	insert RepSpececialAbndTimes select [date], inboundId, [inbound]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [5]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [10]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [15]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [20]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [25]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [30]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [40]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [50]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [60]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [>60]
			from (
				select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
				,cal_id
				,SUM(CASE WHEN  @setting = 0 and (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) 
						  WHEN  @setting = 1 and (statuscall_id = 6) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
				,COUNT(
					CASE WHEN @setting = 0 and (statuscall_id <> 13) THEN 1 
					     WHEN @setting = 1 and (statuscall_id = 6) THEN 1 ELSE NULL END) AS nAbnd
				from cccallsin ci with(index(IX_ccCallsIn),nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id
				where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
			) xCalls
		GROUP BY [date], inboundId, [inbound]
end
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
