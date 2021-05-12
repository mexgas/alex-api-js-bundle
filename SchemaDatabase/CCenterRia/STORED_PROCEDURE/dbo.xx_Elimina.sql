CREATE PROCEDURE [dbo].[xx_Elimina] @cal_key VARCHAR(40), 
										@cam_id  INTEGER
	AS
		 DELETE ccoWorkingTable
		 WHERE cal_keyw = @cal_key
			   AND cam_id = @cam_id
			   AND cal_status IN(0, 1);