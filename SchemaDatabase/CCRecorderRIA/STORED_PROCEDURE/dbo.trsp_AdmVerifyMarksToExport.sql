CREATE PROCEDURE  [dbo].[trsp_AdmVerifyMarksToExport]
		-- Add the parameters for the stored procedure here

		@cal_id int,
		@tipo_llamada smallint

		AS
		BEGIN
			
			select count (*) from CCRECORDERRIA.dbo.RIA_MARCAS where 
			call_id = @cal_id and tipo_llamada = @tipo_llamada

		END