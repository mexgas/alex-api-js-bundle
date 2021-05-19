CREATE PROCEDURE [dbo].[ccsp_IVRBeforeAskAge] @cal_id     INT, 
												  @Inbound_id SMALLINT, 
												  @cal_Key    VARCHAR(40), 
												  @callout_id INT
	AS
		 UPDATE ccCallsIn
		   SET 
			   Inbound_id = @Inbound_id, 
			   cal_key = @cal_Key, 
			   statusCall_id = 11, 
			   callout_id = @callout_id
		 WHERE cal_id = @cal_id