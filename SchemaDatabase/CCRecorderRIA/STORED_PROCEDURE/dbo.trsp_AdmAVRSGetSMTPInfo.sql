-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: September 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmAVRSGetSMTPInfo]
	-- Add the parameters for the stored procedure here



AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

Select [Server], [Port], [User], [Pass], [SSL], [Authentication], [From], [Display] from CCRecorderRIA.dbo.TREC_PARAMMAIL where MailType = 1

END