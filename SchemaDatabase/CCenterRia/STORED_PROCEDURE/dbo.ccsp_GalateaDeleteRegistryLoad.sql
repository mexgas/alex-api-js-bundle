CREATE PROCEDURE [dbo].[ccsp_GalateaDeleteRegistryLoad]
		@loadID INT
		AS

		IF (@loadID IS NOT NULL AND EXISTS(SELECT * FROM ccRIARegistryLists WHERE list_id = @loadID and status <> 0))
		BEGIN
			UPDATE ccoCallsOutSource SET cal_status = '5' WHERE list_id = @loadID
			DELETE FROM ccoWorkingTable WHERE list_id = @loadID 
			exec ccsp_RIARegistryLists @action=6, @list_id = @loadID 
		END
		ELSE
		BEGIN
			--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
			raiserror('ERROR. No existe una carga el id especificado', 18, 1)
		END