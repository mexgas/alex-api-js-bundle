CREATE PROCEDURE [dbo].[ccspGalateaINInsertaCallBack] 
		@cal_key       VARCHAR(40)  = '', 
		@acd_id        SMALLINT, 
		@cal_telefono  VARCHAR(19), 
		@fechadial     VARCHAR(17), 
		@dato1         VARCHAR(255), 
		@dato2         VARCHAR(255), 
		@dato3         VARCHAR(255), 
		@dato4         VARCHAR(255), 
		@dato5         VARCHAR(255), 
		@TelReprograma SMALLINT     = -1, 
		@user_id       INT          = 0, 
		@isAuto        BIT          = 0
	AS
		BEGIN
			SET NOCOUNT ON;
			DECLARE @cam_id SMALLINT;
			SELECT @cam_id = ISNULL(cam_id, 0)
			FROM ccinbound
			WHERE Inbound_id = @acd_id;
			EXEC ccsp_INInsertaCallBack 
				 @cal_key, 
				 @cam_id, 
				 @cal_telefono, 
				 @fechadial, 
				 @dato1, 
				 @dato2, 
				 @dato3, 
				 @dato4, 
				 @dato5, 
				 @TelReprograma, 
				 @user_id, 
				 @isAuto;
			SET NOCOUNT OFF;
		END;