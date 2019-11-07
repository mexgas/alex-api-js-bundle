CREATE PROCEDURE [dbo].[ccspRepIVRFirstOption]
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

	DELETE FROM RepIVRFirstOption with(rowlock)
	WHERE [date]>=@from AND [date]<@to

	INSERT INTO RepIVRFirstOption
	([date],[descriptionOption],[option_Count],[count],[year],[month],[day],[hour],[minutes])
	
	SELECT
		[date],
		selectedoption,
		'' + selectedoption + '_Count',
		COUNT(selectedOption),
		datepart(yyyy,[date]),
		datepart(mm,[date]),
		datepart(dd,[date]),
		datepart(hh,[date]),
		datepart(mi,[date])
	from
	(
		select convert(varchar(10), [date], 121) as [date], selectedOption from IVROptions
		join
		(
			select ivr_id, min([date]) as minDate from IVROptions
			where [date] >= @from and [date] < @to
			group by ivr_id
		) A
		on A.ivr_id = IVROptions.ivr_id and A.minDate=IVROptions.[date]
	) B
	GROUP BY [date], selectedOption
	ORDER BY [date], selectedOption
	
end