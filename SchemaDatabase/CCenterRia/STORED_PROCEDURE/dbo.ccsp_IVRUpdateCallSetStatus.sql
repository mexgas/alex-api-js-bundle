CREATE procedure [dbo].[ccsp_IVRUpdateCallSetStatus]
@cal_id int,
@nStatus tinyint,
@userId int=0
as
set nocount on

Update ccCallsIn SET cal_que=case @nStatus when 5 -- En Espera
then 1 else cal_que end, statusCall_id=case when statusCall_id<>13 then @nStatus else statusCall_id end
,User_id= case when @userId >0 and User_id=0  then @userId else User_id end

where cal_id=@cal_id

exec ccsp_RIAUpdateCallBack_Abandon @cal_id, @nStatus

return(0)
set nocount off