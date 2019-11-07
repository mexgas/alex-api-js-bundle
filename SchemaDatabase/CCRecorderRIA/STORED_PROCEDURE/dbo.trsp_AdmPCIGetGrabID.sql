-- =============================================
-- Author:		Javier R. R.
-- Create date: Enero 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmPCIGetGrabID]
	-- Add the parameters for the stored procedure here

@GrabID int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here


select top 10 * from (select top 10 grab_id  from RIA_GRABACIONCONSULTA where
grab_id >= @GrabID UNION select top 10 grab_id from RIA_GRABACION where grab_id >= @GrabID )x order by 1


END