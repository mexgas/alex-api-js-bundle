-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: March 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmRecDeleteMySearchs]
	-- Add the parameters for the stored procedure here

@MySearchID int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Delete from RIA_MIS_BUSQUEDAS where mysearch_id  = @MySearchID



END