-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: October 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmGetExportSvrConfig]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

select par_valor from CCRecorderRIA.dbo.trec_parametros where par_id in (33,34,35,36,38,39,42,43,44,45,46,47,48,50,51,52,53)


END