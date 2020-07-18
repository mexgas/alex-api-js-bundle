CREATE PROCEDURE [dbo].[ccsp_GalateaGetCampaignOutDialingStats]
@Tipo as tinyint=0,
@cam_id as smallint = 0,
@sup_id as smallint=0
AS
BEGIN
declare @dateStart datetime,@dateEnd datetime
select @dateStart = convert(smalldatetime, convert(varchar(11), getdate() ), 101)  
set @dateEnd=DATEADD(dd,1,@dateStart)

declare @relationCamSup table(cam_id int primary key)

insert into @relationCamSup
select distinct cam_id from ccSupervisorCam supCam where user_id=@sup_id

;

WITH ResultDial AS (
select logDials.cam_id, count(*) as Calls,
		    count(case tipoResDial_id when 1 then 1 else null end) as Answer,
		    count(case tipoResDial_id when 2 then 1 else null end) as Busy,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
		    count(case tipoResDial_id when 4 then 1 else null end) as Fax,
			count(case tipoResDial_id when 5 then 1 else null end) as NoTone,
			count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
			count(case tipoResDial_id when 11 then 1 else null end) as Machine,
			count(case tipoResDial_id when 12 then 1 else null end) as Congestion,
			count(case tipoResDial_id when 13 then 1 else null end) as Canceled		    
		    from ccoLogDials logDials with(nolock)
			inner join @relationCamSup  B ON logDials.cam_id = B.cam_id
where fecha between @dateStart and @dateEnd
--and logDials.cam_id in(1,3)
  group by logDials.cam_id
  
  )
 ,
  ResultAgent AS (
select A.cam_id, c.cam_descripcion Name,
count(case statuscall_id when 1 then 1 else null end) as Initial,
count(case statuscall_id when 2 then 1 else null end) as [OutofSchedule],
count(case statuscall_id when 3 then 1 else null end) as [OutofService],
count(case statuscall_id when 4 then 1 else null end) as [NoAgentsLoggedin],
count(case statuscall_id when 5 then 1 else null end) as [OnHold],
count(case statuscall_id when 6 then 1 else null end) as Abandoned,
count(case statuscall_id when 7 then 1 else null end) as [Timeoverflow],
count(case statuscall_id when 8 then 1 else null end) as [QueueSizeOverflow],
count(case statuscall_id when 9 then 1 else null end) as [WithMessage],
count(case statuscall_id when 10 then 1 else null end) as [Assigned Message],
count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned],
count(case statuscall_id when 13 then 1 else null end) as [Answered],
count(case statuscall_id when 14 then 1 else null end) as [Canceled Message]  
from ccoCallsOut A
inner join @relationCamSup  B ON A.cam_id = B.cam_id
inner join ccCamps c on a.cam_id = c.cam_id
where cal_Inicio  between @dateStart and @dateEnd
--and cam_id in(1,3)
group by A.cam_id, c.cam_descripcion
)

select  camps.cam_id, isnull(a.Calls, 0)Calls, isnull(a.Answer, 0)Answer, isnull(a.Busy, 0)Busy, isnull(a.NoAnswer, 0)NoAnswer, isnull(a.Fax, 0)Fax, isnull(a.NoService, 0)NoService, isnull(a.Other, 0)Other,
isnull(a.Canceled, 0)Canceled, isnull(a.Machine, 0)Machine, isnull(a.NoTone, 0) NoTone, isnull(a.Congestion, 0)Congestion,   isnull(B.Answered, 0)  Attended, isnull(B.Abandoned, 0) Abandon,isnull(B.Assigned, 0)Assigned,  
convert(decimal(5,2), isnull(( B.Abandoned*100.0)/nullif(A.Answer,0),0) )AbandonRate,camps.aggressionFactor
from ResultDial A
inner join ResultAgent B on A.cam_id=B.cam_id
inner JOIN @relationCamSup relation on relation.cam_id = A.cam_id
INNER join ccCamps camps on camps.cam_id=relation.cam_id
Order by camps.cam_descripcion
END