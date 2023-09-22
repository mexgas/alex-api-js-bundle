SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 122

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY


-----------------------------------------------------BEGIN Carlos Chavez hotfix/125.20230719.0.4 -----------------------------------------------------------------

	set @process = 'DEV3-508 Drop procedure ccspRepIVRGeneral'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepIVRGeneral'')
	begin
        DROP PROCEDURE ccspRepIVRGeneral;
    end
	'
	EXEC(@sql)
	
	set @process = 'DEV3-508 Create procedure ccspRepIVRGeneral'
	set @sql = 'CREATE PROCEDURE [dbo].[ccspRepIVRGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if(@to = convert(datetime,convert(varchar(11),getdate(),121)+''03:00:00'',121)) AND @from = DATEADD(dd,-1,@to)
BEGIN
	select @from = convert(datetime,convert(varchar(11),@from))
END

if @action = 1
begin
	delete RepIVRGeneral with(rowlock)
	where date >= @from and date < @to

	insert into RepIVRGeneral
	select convert(varchar(10),date,121) as [date], 
	sum(case when calId = 0 then 1 else 0 end) as [noTransferred], 
	sum(case when calId > 0 then 1 else 0 end) as [transferred], 
	count(*) as [total]
	, datepart(yyyy,convert(varchar(10),date,121))
	, datepart(mm,convert(varchar(10),date,121))
	, datepart(dd,convert(varchar(10),date,121))
	, 0 [hour]
	, 0 [minutes]
	from (select A.Ivr_id, A.cal_ani, isnull(B.cal_id,0) as calId ,A.date 
			from IVRCallsIn as a 
			left join ccCallsIn as b on  A.IVR_id = B.IVR_id 
			where date >= @from and date < @to) as c
	where date >= @from and date < @to
	group by convert(varchar(10),date,121)
	order by convert(varchar(10),date,121)
end'
	EXEC(@sql)



---------------------------------------------------- END Carlos Chavez Hotfix/125.20230719.0.4 -------------------------------------------------------


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
