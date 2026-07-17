SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 106

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	SET @process = 'CW-5586 update table RepChatsDetail'
	SET @sql = 'IF EXISTS (
				  SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
				  WHERE table_name = ''RepChatsDetail''
				  AND column_name = ''chatId'')
				SELECT ''Column exists in table'' AS [Status] ;
				ELSE
				ALTER TABLE RepChatsDetail ADD chatId int NOT NULL CONSTRAINT MyColumn DEFAULT 0;'
	EXEC (@sql)

	SET @process = 'update table RepChatsDetail'
	SET @sql = 'IF OBJECT_ID(''MyColumn'', ''C'') IS NOT NULL ALTER TABLE RepChatsDetail DROP CONSTRAINT MyColumn;'
	EXEC (@sql)

	SET @process = 'CW-5586 update SP ccspRepChatsDetail'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepChatsDetail]
				@action as tinyint,
				@from as datetime = null,
				@to as datetime = null
				AS

				if @from is null
					select @from = convert(datetime,convert(varchar(11),getdate()))
				if @to is null
					select @to = getdate()

				if @action = 1 
					begin
		
						delete from RepChatsDetail with(rowlock)
						where date >= @from AND date < @to
	
						insert into RepChatsDetail
							select requestDate,
							inboundId, b.descripcion, chatstatus, c.description, disposition, isnull(d.description,''''),
							subDisposition, isnull(califSubDesc,''''), domain, userid, isnull(f.login,''''), clientName, tqueue,
							0 as txfer, tchatting, 
							isnull(nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''') as Nombre,
							datepart(yyyy,CONVERT(varchar(20), requestDate, 120)) as [year],
							datepart(mm,CONVERT(varchar(20), requestDate, 120)) as [month],
							datepart(dd,CONVERT(varchar(20), requestDate, 120)) as [day],
							datepart(hh,CONVERT(varchar(20), requestDate, 120)) as [hour],
							datepart(mi,CONVERT(varchar(20), requestDate, 120)) as [minutes],
							chatId
							from ccRIAChats
							left join ccInbound b on (inboundId = inbound_id)
							left join ccRIAChatStatus c on (chatstatus = id)
							left join ccTipoCalif d on (calif_id = disposition)
							left join ccTipoCalifSub e on (califSub_id = subDisposition)
							left join ccUserView f on (User_id = userid)
							where requestDate >= @from and requestDate < @to
			
							select isnull(datediff(ss,requestDate,chatdate) - tqueue,0) as xferTime, requestDate as date
							into #tmpxferTime
							from ccRIAChats where chatstatus = 4
			
							update RepChatsDetail set xferTime = b.xferTime
							from RepChatsDetail a, #tmpxferTime b where a.date = b.date 
			
							drop table #tmpxferTime
					end'
	EXEC (@sql)

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
