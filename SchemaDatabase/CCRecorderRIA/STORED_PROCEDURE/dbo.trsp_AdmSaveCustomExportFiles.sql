-- =============================================
-- Author:		Javier Ruelas
-- Create date: October 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmSaveCustomExportFiles]
	-- Add the parameters for the stored procedure here

@Orden smallint,
@ID smallint


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

Update CCRecorderRIA.dbo.TREC_FORM_ARCHIVOSEXPORT set Orden = @Orden where ID = @ID


END