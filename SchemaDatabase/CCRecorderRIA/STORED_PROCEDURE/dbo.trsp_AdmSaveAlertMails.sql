-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: September 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmSaveAlertMails]
	-- Add the parameters for the stored procedure here

@mail as nvarchar(50),
@nivel_id as int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

Insert CCRecorderRIA.dbo.TREC_LISTA_MAIL (mail,nivel_id) values (@mail,@nivel_id)


END