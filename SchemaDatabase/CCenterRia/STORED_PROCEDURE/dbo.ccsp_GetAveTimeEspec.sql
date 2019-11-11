CREATE PROCEDURE ccsp_GetAveTimeEspec
@dia as varchar(11)=NULL,
@CveCamp int
AS

declare @fechaI as datetime, @fechaF as datetime
declare @Dlgs as int
--declare @DlgsWaitMinXsecs as int
--declare @DlgsWaitMoreYsecs as int
declare @DlgsAveTime as int
declare @Que as int
declare @QueueAveTime as int
declare @CallsLost as int
declare @SL1 as int
declare @SL2 as int

declare @tresRing as smallint
declare @tresDialog as smallint
declare @tresDelayIn as smallint

exec @tresRing = ccspConfigTresRing
exec @tresDialog = ccspConfigTresDialog
exec @tresDelayIn = ccspConfigtresDelayIn

--select @dia = '2003/01/22' --, @CveCamp=5
if (@dia is null )
	select @dia=convert(CHAR(11), GETDATE(), 21)

select @fechaI = convert(datetime, @dia, 101)
select @fechaF = dateadd( d, 1, @fechaI )


SELECT 
@Dlgs = count(case when statuscall_id = 13 then 1 else null end), 
@DlgsAveTime = ISNULL(sum( case when statuscall_id = 13 then cal_tDialog + cal_tNotas else null end), 0),
--@DlgsWaitMinXsecs = count(case when statuscall_id = 13 and cal_tWait < 20 then 1 else null end),  --DIALOGS tWait<20 SEGS
--@DlgsWaitMoreYsecs = count(case when statuscall_id = 13 and cal_tDialog > 120 then 1 else null end),  

@Que = count(case when cal_que> 0 then 1 else null end), 
@QueueAveTime = ISNULL(sum( case when cal_que > 0 then cal_tWait else null end), 0),

--@CallsLost = count(case when statuscall_id in (4,6,7,8,15,16) then 1 else null end),  --Hector
--@CallsLost = count(case when statuscall_id in (6) then 1 else null end),  --ASP
@CallsLost= isnull(COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END), 0), -- ODC
@SL1 = count( case 	when 	( statuscall_id in (5,6) and cal_que > 0 and cal_xfer is null and (cal_twait + cal_txfer + cal_tring) < @tresDelayIn ) OR
				( statuscall_id = 13 and cal_tDialog > @tresDialog and (cal_twait + cal_txfer + cal_tring) < @tresDelayIn )
			then 1 else null end),
@SL2 = count( case	when	( statuscall_id IN (5,6) AND cal_que > 0 AND cal_xfer IS NULL ) OR
				( statuscall_id = 13 AND cal_tdialog  > @tresDialog ) OR
				( statuscall_id = 4 ) OR
				( statuscall_id = 7 ) OR
				( statuscall_id = 8 ) OR
				( statuscall_id = 15 and cal_tRing > @tresRing ) OR
				( statuscall_id = 16 ) 
			then 1 else null end)
FROM ccCallsIN
WHERE cal_Inicio between @fechaI AND @fechaF
AND Inbound_id = @CveCamp

select 	'Dialogs'=@Dlgs, 'LostCalls'=@CallsLost, 'DlgsAveTime'=@DlgsAveTime/ (@Dlgs+1),  'QueueAveTime'=@QueueAveTime / (@Que +1),
	'SL' = case when @SL2 > 0 then 100.0 * @SL1 / @SL2 else 0 end

-- 'DlgsWaitMin20segs'=@DlgsWaitMinXsecs, ,
--	'DlgWaitMore120segs'=@DlgsWaitMoreYsecs,