CREATE PROCEDURE dbo.ccsp_RIAADMReciclarCB
@cam_id int
AS
update ccoCallsOutSource set dato5 = isnull(dato5, '') where callout_id in (
select callout_id from ccoWorkingTable where cam_id = @cam_id and cal_status = 1)
update ccoWorkingTable set cal_status = 0 where cam_id = @cam_id and cal_status = 1