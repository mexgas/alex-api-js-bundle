-- =============================================
-- Author:		Javier R. R.
-- Create date: Enero 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmPCIGetACDList]
	-- Add the parameters for the stored procedure here
@Type int,
@Inbound_id int 

AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	 select a1.Keyword
	 from CCRecorderRIA.dbo.RIA_PCI_ACD_LIST a1
	 where a1.Inbound_id = @Inbound_id and  a1.List_type = @Type

END