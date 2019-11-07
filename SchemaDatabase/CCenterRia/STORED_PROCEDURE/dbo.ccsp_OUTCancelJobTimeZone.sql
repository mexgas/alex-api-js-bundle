CREATE procedure [dbo].[ccsp_OUTCancelJobTimeZone]
@callout_id int,
@status int,
@minutesCb int = 0
as
set nocount on
if @minutesCb = 0
    set @minutesCb = 5

update ccoWorkingTable with(rowlock) set cal_status=@status, cal_fechaDial= dateadd(mi, @minutesCb, cal_fechaDial) 
where callout_id=@callout_id

set nocount off