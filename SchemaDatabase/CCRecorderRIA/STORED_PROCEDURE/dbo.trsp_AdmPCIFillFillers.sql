-- =============================================
-- Author:		Javier R.R.
-- Create date: Enero 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmPCIFillFillers]

@TypeCall int,
@CampACDID int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

IF @TypeCall = 1

BEGIN

select Keyword from RIA_PCI_ACD_LIST where List_type = 3 and Inbound_Id = @CampACDID

END

ELSE IF @TypeCall = 2

BEGIN

select Keyword from RIA_PCI_CAMP_LIST where List_type = 3 and cam_id = @CampACDID

END


END