-- =============================================
-- Author:		UEspinosa
-- Create date: 03/12/20
-- Description:	Eliminacion de registros de WorkingTable
-- =============================================
CREATE PROCEDURE ccsp_GalateaDeleteWorkingTable
	@DeleteCamId	  VARCHAR(MAX) = '158'
AS
BEGIN
	IF OBJECT_ID('tempdb..#CampsDelete') IS NOT NULL DROP TABLE #CampsDelete
		SELECT value As DeleteCamId into #CampsDelete FROM fn_RIASplitDelimited(@DeleteCamId, ',')

	delete TOP(3000) from ccoWorkingTable where cam_id in (select DeleteCamId from #CampsDelete)

	SELECT COUNT(callout_id) FROM ccoWorkingTable WHERE cam_id in (select DeleteCamId from #CampsDelete)
END