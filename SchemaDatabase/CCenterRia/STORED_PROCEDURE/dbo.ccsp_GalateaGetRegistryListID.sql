CREATE PROCEDURE [dbo].[ccsp_GalateaGetRegistryListID]
		@camID INT
		AS

		IF (@camID IS NOT NULL AND EXISTS(SELECT * FROM cccamps WHERE cam_id = @camID))
		BEGIN
			SELECT TOP 1 list_id FROM ccRIARegistryLists WHERE cam_id = @camID AND status = 2 ORDER BY list_id DESC
		END
		ELSE
		BEGIN
			--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
			raiserror('ERROR. No existe una campaña con el id especificado', 18, 1)
		END