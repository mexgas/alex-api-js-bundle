-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: September 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmDeleteAlertMails]
	-- Add the parameters for the stored procedure here

@mail_id as int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

Delete from CCRecorderRIA.dbo.TREC_LISTA_MAIL where mail_id = @mail_id


END