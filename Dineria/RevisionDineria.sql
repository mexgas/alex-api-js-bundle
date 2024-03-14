
declare @date varchar(15) = '2024-03-13';

declare @campSms table (cam_id int,cam_descripcion varchar(40)
,cam_procesando int,cam_fCreate datetime
,status bit)

declare @campNvo table (id int,cam_descripcion varchar(40),new int,cb int,pro int,pen int,
st int,job int,Fin int,Prioridad varchar(10),NexDial int,aggresionFactor float,OverTotalNew int)

declare @tempSmsLogDial table (SystemApiId varchar(max), statusSystemsId int, cam_id int)

--select * from ccSettings where setting_id = 112
--exec ccsp_GetHourLaw @isSms = 1

insert into @campSms
select c.cam_id,c.cam_descripcion,cam_procesando,cam_fCreate,0 
from ccCamps c
where CampType=7  and
cam_fCreate>=@date
--cam_procesando=1

insert into @tempSmsLogDial 
select SystemApiId, statusSystemsId, s.cam_id
from smsccoLogDial s
inner join @campSms c on s.cam_id = c.cam_id

--select * from @tempSmsLogDial where cam_id = 3022

declare @tempConversationResults table (cam_id int, SentMsg int, Delivered int, NotDelivered int, RecipientRejected int, CarrierRejected int,
										InsufficientBalance int, Exception int)
insert into @tempConversationResults
select cam_id, 
count(case when statusSystemsId=1 then 1 end) SentMsg
,count(case when statusSystemsId=2 then 1 end) Delivered
,count(case when statusSystemsId=3 then 1 end) NotDelivered
,count(case when statusSystemsId=4 then 1 end) RecipientRejected
,count(case when statusSystemsId=4 then 1 end) CarrierRejected
,count(case when statusSystemsId=5 then 1 end) InsufficientBalance
,count(case when statusSystemsId=6 then 1 end) Exception
from @tempSmsLogDial
group by cam_id

--select * from @tempConversationResults
select c.cam_id,c.cam_descripcion,c.cam_procesando 
,B.new,B.pro,B.dateUpdate,B.OverallTotalNew
,c.cam_fCreate, t.SentMsg, t.Delivered, t.NotDelivered--, t.RecipientRejected, t.CarrierRejected, t.InsufficientBalance, t.Exception
from @campSms c
inner join ccCampsNvosCB B on c.cam_id=B.id
inner join @tempConversationResults t on t.cam_id = c.cam_id
--where CampType=7 --and cam_procesando=1
order by cam_id desc

--declare @i int,@count int

--select @count=count(*) from @campSms
--while exists(select * from @campSms where status=0) begin
--	select top 1 @i=cam_id from @campSms where status=0
--	insert into @campNvo
--	exec ccsp_GalateaGetCampsNvosCB @cam_id=@i,@Tipo=2
--	update @campSms set status=1 where cam_id=@i
--end

select * from @campNvo order by id desc

select * from ccSmsSchedules Sch
inner join @campSms s on sch.cam_id=s.cam_id
order by s.cam_id desc


--select distinct iTimeZone_summer from smsWorkingTable where cam_id=2964
--select * from smsWorkingTable with(nolock) where cam_id in (2983) --and sms_status=2
--select smsout_id,cam_id,sms_phoneNumber,sms_status,sms_dateDial,iTimeZone,iTimeZone_summer from smsOutSource with(nolock) where cam_id in (2963) --and sms_status=2
--select * from ccTimeZones where tz_id in(256,128,32,64)

--update smsWorkingTable set sms_status=0 where cam_id=2914 and sms_status=2
--exec ccsp_OUTGetNewJobsSMS @CAMPID=2964,@action=1,@topCount=100
--exec ccsp_OUTcheckTimeZone @cam_id=2964,@isReturnSelect=1

select *,
SentMsg+Delivered+NotDelivered+RecipientRejected+CarrierRejected+InsufficientBalance+Exception as Total 
from ccSmsConversationsResult s
--left join @campSms c on c.cam_id = s.camId
order by camId desc

--select 'smsccoLogDial',cam_id,
--count(case when statusSystemsId=1 then 1 end) SentMsg
--,count(case when statusSystemsId=2 then 1 end) Delivered
--,count(case when statusSystemsId=3 then 1 end) NotDelivered
--,count(case when statusSystemsId=4 then 1 end) RecipientRejected
--,count(case when statusSystemsId=4 then 1 end) CarrierRejected
--,count(case when statusSystemsId=5 then 1 end) InsufficientBalance
--,count(case when statusSystemsId=6 then 1 end) Exception
-- from smsccoLogDial with(nolock) where cam_id in(2940,2941,2942)
-- group by cam_id
	

--select * from smsccoLogDial with(nolock) where smsDate>='2024-02-27'

--declare @camId int = 2932;
--select count(*), statusSystemsId, count(case when Bill > 0 then 1 else 0 end) as Billed from smsccoLogDial where cam_id = @camId group by statusSystemsId
----update ccSmsConversationsResult set SentMsg = 0, Delivered = 19314, NotDelivered = 809  where camId = @camId
--select * from ccSmsConversationsResult where camId = @camId


select getdate(),GETUTCDATE(),DATEADD(hh,-5,GETUTCDATE()) [-5],DATEADD(hh,-8,GETUTCDATE()) [-8],DATEADD(hh,-7,GETUTCDATE()) [-7]
,504356991&256,504356991&128,504356991&64