-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmPCIGetCampACDType]

@GrabID int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

select Tipo_llamada, cam_id, cal_id from (select Tipo_llamada,cam_id, cal_id from RIA_GRABACIONCONSULTA where
grab_id = @GrabID UNION select Tipo_llamada, cam_id, cal_id from RIA_GRABACION where grab_id = @GrabID )x order by 1



END