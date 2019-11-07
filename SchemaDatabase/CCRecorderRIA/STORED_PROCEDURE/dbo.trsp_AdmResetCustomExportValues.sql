-- =============================================
-- Author:		Javier Ruelas
-- Create date: October 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmResetCustomExportValues]
	-- Add the parameters for the stored procedure here


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

Update CCRecorderRIA.dbo.TREC_FORM_ARCHIVOSEXPORT set Orden = 0
Update CCRecorderRIA.dbo.TREC_FORM_CARPETASEXPORT set Orden = 0


END