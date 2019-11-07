CREATE PROCEDURE [dbo].[ccsp_IVRBeforeAskAge]
@cal_id int,
@Inbound_id smallint,
@cal_Key varchar(20),
@callout_id int
AS
Update ccCallsIn SET Inbound_id= @Inbound_id, cal_key=@cal_Key, statusCall_id=11, callout_id=@callout_id
where cal_id=@cal_id