CREATE procedure dbo.ccsp_IVRUpdateCallSetStatus
@cal_id int,
@nStatus tinyint
as
set nocount on

Update ccCallsIn SET cal_que=case @nStatus when 5 -- En Espera
then 1 else cal_que end, statusCall_id=@nStatus where cal_id=@cal_id

exec ccsp_RIAUpdateCallBack_Abandon @cal_id, @nStatus

return(0)
set nocount off