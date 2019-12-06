USE [CCenterRia]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

USE [CCenterRia]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_GalateaGetRegistryListID]
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
	