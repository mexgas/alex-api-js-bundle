-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: September 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmSaveAlertsConfig]
	-- Add the parameters for the stored procedure here

@firstWarning as nvarchar(50),
@urgentWarning as nvarchar(50),
@deleteWarning as nvarchar(50),
@totalTime as nvarchar(50)


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor = @firstWarning where par_id = 8
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor = @urgentWarning where par_id = 9
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor = @deleteWarning where par_id = 10
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor = @totalTime where par_id = 21


END