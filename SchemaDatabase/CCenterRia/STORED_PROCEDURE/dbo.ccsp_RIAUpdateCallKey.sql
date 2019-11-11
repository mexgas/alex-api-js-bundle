CREATE procedure [dbo].[ccsp_RIAUpdateCallKey]
@type Tinyint,
@callid int,
@callkey varchar(20)

AS

if @type = 1 --Inbound 
begin
	Update ccCallsIn set cal_key=@callkey where cal_id=@callid
end
	
if @type = 2 --Outbound 
begin
	Update ccoCallsOut set cal_key=@callkey where cal_id=@callid
end