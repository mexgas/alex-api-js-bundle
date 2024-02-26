declare @campSms table (cam_id int,cam_descripcion varchar(40)
,cam_procesando int,cam_fCreate datetime
,status bit)

declare @campNvo table (id int,cam_descripcion varchar(40),new int,cb int,pro int,pen int,
st int,job int,Fin int,Prioridad varchar(10),NexDial int,aggresionFactor float,OverTotalNew int)


insert into @campSms
select c.cam_id,c.cam_descripcion,cam_procesando,cam_fCreate,0 from ccCamps c
where CampType=7  and
cam_fCreate>='2024-02-23 '
 --cam_procesando=1


select c.cam_id,c.cam_descripcion,c.cam_procesando 
,B.new,B.pro,B.dateUpdate,B.OverallTotalNew
,c.cam_fCreate
from @campSms c
inner join ccCampsNvosCB B on c.cam_id=B.id
--where CampType=7 --and cam_procesando=1
order by cam_id desc

declare @i int,@count int

select @count=count(*) from @campSms
while exists(select * from @campSms where status=0) begin
	select top 1 @i=cam_id from @campSms where status=0
	insert into @campNvo
	exec ccsp_GalateaGetCampsNvosCB @cam_id=@i,@Tipo=2
	update @campSms set status=1 where cam_id=@i
end

select * from @campNvo order by id desc

select * from ccSmsSchedules Sch
inner join @campSms s on sch.cam_id=s.cam_id
order by iDate desc,s.cam_id desc


--select * from smsWorkingTable where cam_id=2887
--select * from ccTimeZones where tz_id in(256,128)

--select * from smsWorkingTable where cam_id = 2883
--exec ccsp_OUTGetNewJobsSMS @CAMPID=2883,@action=1,@topCount=10
--exec ccsp_OUTcheckTimeZone @cam_id=2883,@isReturnSelect=1
select getdate(),GETUTCDATE(),DATEADD(hh,-6,GETUTCDATE()),1809850360&256
