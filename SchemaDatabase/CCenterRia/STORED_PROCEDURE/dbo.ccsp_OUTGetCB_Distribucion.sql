CREATE procedure ccsp_OUTGetCB_Distribucion
@CAMPID as int,
@Tipo int=0
as
set nocount on
declare @start datetime, @end datetime
select @end=CONVERT(datetime,CONVERT(varchar(11),GETDATE(),121)+'00:00',121), @start=DATEADD(d,-1,@end)

if @Tipo=0
 begin
	select count(case when(cal_fechaDial<@start) then 1 else null end) as Antes,
	 count(case when(cal_fechaDial between @start and @end) then 1 else null end) as Hoy,
	 count(case when(cal_fechaDial>@end) then 1 else null end) as Despues, count(callout_id) as Todos
	from ccoWorkingTable where cam_id = @CAMPID and cal_status=1
	return(0)
 end

--else if @Tipo=1
select datepart(hh, cal_fechaDial) as Hora, count(callout_id) as CB
from ccoWorkingTable
where cam_id=@CAMPID and cal_fechaDial>@start and cal_status=1
group by datepart(hh, cal_fechaDial)
order by Hora
return(0)
set nocount off