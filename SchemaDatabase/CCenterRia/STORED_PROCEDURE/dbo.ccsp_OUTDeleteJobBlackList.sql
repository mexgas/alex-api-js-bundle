CREATE procedure [dbo].[ccsp_OUTDeleteJobBlackList]
@callout_id int
as
set nocount on

if exists(select * from ccoWorkingTable where callout_id = @callout_id)	
	
	insert into ccoLogBlackList (callOut_Id,telephone,calKey,camId,DateDeleteWT)
	select callout_id,cal_telefono,cal_keyw,cam_id,getDate() from ccoWorkingTable where callout_id = @callout_id

	DELETE ccoWorkingTable WHERE callout_id = @callout_id

set nocount off