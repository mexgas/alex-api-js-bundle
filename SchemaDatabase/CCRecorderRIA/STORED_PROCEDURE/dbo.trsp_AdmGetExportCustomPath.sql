-- =============================================
-- Author:		
-- Create date: October 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmGetExportCustomPath]


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select id,orden from CCRecorderRIA.dbo.TREC_FORM_CARPETASEXPORT where orden > 0 order by orden

END