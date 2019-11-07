-- =============================================
-- Author:		Javie Ruelas Rossier
-- Create date: Febrero 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmPCIInsertCamACDXtime]
	-- Add the parameters for the stored procedure here

@Call_Type int,
@CamACD_id int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


IF @Call_Type = 1

BEGIN

insert RIA_PCI_XTIME_ACD values (@CamACD_id,0,0)

END

ELSE IF @Call_Type = 2

BEGIN

insert RIA_PCI_XTIME_CAMP values (@CamACD_id,0,0)

END


END