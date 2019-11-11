-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: September 2012
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [dbo].[trsp_AdmGetMailSenderParams]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

Select isnull(MailType,'') as MailType, isnull([Server],'') as [Server], isnull(Port,'') as Port, isnull([User],'') as [User],
isnull(Pass,'') as Pass, isnull(MailFile,'') as MailFile, isnull(Domain,'') as Domain, isnull(SSL,'') as SSL, isnull(Authentication,'') as Authentication,
isnull([From],'') as [From], isnull (Display,'') as Display
from CCRecorderRIA.dbo.TREC_PARAMMAIL

END