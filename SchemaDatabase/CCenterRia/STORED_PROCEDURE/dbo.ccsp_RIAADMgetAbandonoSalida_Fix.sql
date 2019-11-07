CREATE proc [dbo].[ccsp_RIAADMgetAbandonoSalida_Fix]
as
set nocount on
declare @fecha smalldatetime, @fecha2 smalldatetime
declare @i int



declare @tempChart table (
cam_id	int,
countAbnd int,
countAll int,
timestamp	smalldatetime
)

set @fecha = convert(varchar(10), getdate(), 112)+' '+convert(varchar(4), getdate(), 108)+'0'
set @i =0
while @i < 30
begin
	set @fecha2 = dateadd( mi, -10, @fecha)

	insert into @tempChart
	select ccCamps.cam_id, x.countAbnd,x.countAll, @fecha2 from ccCamps
	left join
	(
		select cam_id,count(case statuscall_id when 6 then 1 else null end ) as countAbnd,
		COUNT(*) as countAll		
		from ccoCallsOut
		with( index(IX_ccoCallsOut_2) )
		where cal_manual in (0,2 ) and cal_inicio >= @fecha2 and cal_inicio < @fecha		
		group by cam_id
	)x on x.cam_id = ccCamps.cam_id
	where ccCamps.idArea is not null

	set @fecha = @fecha2
	set @i = @i +1
end

truncate table ccAbandonoSalida_Chart

insert into ccAbandonoSalida_Chart
select cam_id,
CONVERT(decimal(10,2),
case when countAll=0 then 0 else countAbnd*100.00/countAll end
),[timestamp]
  from @tempChart order by cam_id 

truncate table ccAbandonoSalida  
  
 insert into ccAbandonoSalida
 select cam_id,
 CONVERT(decimal(10,2),
 SUM(countAbnd*100.0)/sum(countAll) 
 ) as AbndPctg 

 from @tempChart
 group by cam_id
 
set nocount off