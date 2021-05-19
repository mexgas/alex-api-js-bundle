CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCallKey] @type    TINYINT, 
												   @callid  INT, 
												   @callkey VARCHAR(40)
	AS
		 IF @type = 1 --Inbound 
			 BEGIN
				 UPDATE ccCallsIn
				   SET 
					   cal_key = @callkey
				 WHERE cal_id = @callid;
		 END;
		 IF @type = 2 --Outbound 
			 BEGIN
				 UPDATE ccoCallsOut
				   SET 
					   cal_key = @callkey
				 WHERE cal_id = @callid;
		 END;