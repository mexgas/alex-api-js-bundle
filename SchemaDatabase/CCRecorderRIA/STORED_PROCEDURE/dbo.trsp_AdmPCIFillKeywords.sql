-- =============================================
-- Author:		Javier R. R.
-- Create date: Enero 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmPCIFillKeywords]

@TypeCall int,
@CampACDID int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF @TypeCall = 1 

Begin

select Keyword from RIA_PCI_ACD_LIST where Inbound_id = @CampACDID

end
Else IF @TypeCall = 2

Begin

select Keyword from RIA_PCI_CAMP_LIST where cam_id = @CampACDID

End


END