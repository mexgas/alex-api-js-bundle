create procedure ccsp_DLRBeforeXferAge
@cal_id int,
@calOut_id int,
@tConnTime datetime=null,
@tBridgeTime datetime=null
AS
set nocount on
if @cal_id=0
 return(0)

set @tConnTime=   convert(varchar(8), getdate(), 112) + ' ' + @tConnTime
set @tBridgeTime=   convert(varchar(8), getdate(), 112) + ' ' + @tBridgeTime

Update ccoCallsOut SET callout_id=@calOut_id, tConnTime=ISNULL(@tConnTime, tConnTime), tBridgeTime=ISNULL(@tBridgeTime, tBridgeTime)
where cal_id=@cal_id

return(0)
set nocount off