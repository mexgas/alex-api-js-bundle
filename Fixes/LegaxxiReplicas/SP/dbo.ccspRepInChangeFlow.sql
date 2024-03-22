ALTER PROCEDURE [dbo].[ccspRepInChangeFlow]
	@action as tinyint,
	@from AS datetime = NULL,
	@to AS datetime = NULL
AS

SET NOCOUNT ON
SET DATEFIRST 1

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	DELETE FROM RepInChangeFlow with(rowlock)
	WHERE [date]>=@from AND [date]<@to

	INSERT INTO RepInChangeFlow
	([date],inboundId,inbound,weekday_count,[count],[time],[year],[month],[day],[hour],[minutes])
	
	SELECT
		[date],
		inbound_id,
		'',
		'day' + cast (datepart(weekday,[date]) AS VARCHAR(1)) + '_Count',
		ISNULL(xfer,0) AS [count],
		left(CONVERT(varchar(20), [date], 114), 8),
		datepart(yyyy,[date]),
		datepart(mm,[date]),
		datepart(dd,[date]),
		datepart(hh,[date]),
		datepart(mi,[date])
	FROM(
		
		SELECT
			CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121) AS [date],
			inbound_id,
			COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE NULL END) AS xfer
		FROM ccCallsIn
			with (nolock)
			WHERE cal_inicio>=@from AND cal_inicio<@to AND INBOUND_ID > 0 AND [user_id] > 0
			GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121),inbound_id
	) xFers
	WHERE [date]>=@from AND [date]<@to
	AND ISNULL(xfer,0) > 0
	ORDER BY [date],inbound_id
	
	update r set
	r.Inbound = isnull(i.Descripcion,'')
	from RepInChangeFlow r, ccInbound i
	where [date] >= @from and [date] < @to
	and i.Inbound_id = r.InboundId 
	and i.inbound_id is not null
	
end