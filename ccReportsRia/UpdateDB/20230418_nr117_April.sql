SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 117

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	----------------------------------------------------- Begin B. Dunzz -----------------------------------------------------------------
	set @process = 'KR051000  Verifica si la columna telephone existe en la tabla RepCallbackQueue'
	set @sql = '
	IF NOT EXISTS (
		SELECT *
		FROM 
			INFORMATION_SCHEMA.COLUMNS
		WHERE 
			COLUMN_NAME = ''telephone''
			AND TABLE_NAME = ''RepCallbackQueue''
	)
	BEGIN 
		ALTER TABLE RepCallbackQueue
		ADD telephone varchar(20);
	END
	'
	EXEC(@sql)

	
	set @process = 'KR051000 ccspRepCallbackQueue DROP SP'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepCallbackQueue'')
	begin
        DROP PROCEDURE ccspRepCallbackQueue;
    end
	'
	EXEC(@sql)


	set @process = 'KR051000 ccspRepCallbackQueue CREATE SP'
	set @sql = '
		CREATE PROCEDURE [dbo].[ccspRepCallbackQueue]
		@action as tinyint,
		@from as datetime = null,
		@to as datetime = null
		AS

		set nocount on
		set ansi_nulls off
		set ANSI_WARNINGS off

		if @from is null
			select @from = convert(datetime,convert(varchar(11),getdate()))
		if @to is null
			select @to = getdate()

		if @action = 1
		begin
			delete from RepCallbackQueue with(rowlock) where [date] >= @from and [date] < @to

			insert into RepCallbackQueue ([date], calid, CALANI, inboundCampaignId, inboundCampaign, retry, xferDate, duration, [year], [mounth], [day], [hour], [minutes], telephone)
			select 
			a.datestamp, 
			a.cal_id, 
			a.CAL_ANI, 
			a.inbound_id, 
			c.descripcion, 
			a.retry, 
			a.xferDate, 
			b.cal_tDialog, 
			datepart(yy,convert(datetime,a.datestamp)) as [year], 
			datepart(mm,convert(datetime,a.datestamp)) as [mounth],
			datepart(dd,convert(datetime,a.datestamp)) as [day],
			datepart(hh,convert(datetime,a.datestamp)) as [hour],
			datepart(mi,convert(datetime,a.datestamp)) as [minutes],
			b.cal_ANI
			from ccRIACallBack_Queue as a 
			left join ccCallsIn as b on a.cal_id = b.cal_id 
			left join ccInbound as c on a.inbound_id = c.Inbound_id
			where a.datestamp >= @from and a.datestamp < @to
		end
	'
	EXEC(@sql)

	----------------------------------------------------- END B. Dunzz -----------------------------------------------------------------


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
