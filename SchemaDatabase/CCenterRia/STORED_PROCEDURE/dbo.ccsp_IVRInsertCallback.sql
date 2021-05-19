CREATE PROCEDURE [dbo].[ccsp_IVRInsertCallback] @ani    VARCHAR(40), 
													@cam_id SMALLINT
	AS
		 DECLARE @tel VARCHAR(20);
		 DECLARE @ld VARCHAR(4);
		 DECLARE @lon TINYINT;

		 --declare @result tinyint
		 SELECT @tel = RTRIM(LTRIM(@ani));
		 SELECT @tel = dbo.verifica(@tel);
		 IF LEFT(@tel, 1) <> 'E'
			 BEGIN
				 INSERT INTO ccoCallsOutSource
				 (cal_key, 
				  cal_telefono, 
				  cam_id
				 )
				 VALUES
				 (@ani, 
				  @tel, 
				  @cam_id
				 );
				 EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp 
					  @cam_id, 
					  0;
		 END;