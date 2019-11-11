-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmPCIGetPCIIntegrated]

@CallType int,
@CampACDID int

AS
BEGIN

	SET NOCOUNT ON;

IF @CallType = 1

BEGIN

SELECT  isnull(Xtime,0) as Xtime, isnull(OnOff,0) as OnOff, isnull (ActiveXtime,0) as ActiveXtime from RIA_PCI_ACD_SETTINGS where Inbound_id = @CampACDID

END

ELSE IF @CallType = 2

BEGIN

SELECT  isnull(Xtime,0) as Xtime, isnull(OnOff,0) as OnOff, isnull (ActiveXtime,0) as ActiveXtime from RIA_PCI_CAMP_SETTINGS where cam_id = @CampACDID

END

END