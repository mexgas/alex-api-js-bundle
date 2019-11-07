-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: Febrero 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmPCIInsertAverageXtime]
	-- Add the parameters for the stored procedure here

@Call_Type int,
@CamACD_id int,
@NumRecs int,
@SumTotal int,
@Average int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF @Call_Type = 1
BEGIN

Update RIA_PCI_XTIME_ACD set Num_recordings =  @NumRecs, Suma = @SumTotal where Inbound_id = @CamACD_id

Update RIA_PCI_ACD_SETTINGS set Xtime = @Average where Inbound_id = @CamACD_id


END
ELSE IF @Call_Type = 2
BEGIN

Update RIA_PCI_XTIME_CAMP set Num_recordings =  @NumRecs, Suma = @SumTotal where cam_id = @CamACD_id

Update RIA_PCI_CAMP_SETTINGS set Xtime = @Average where cam_id = @CamACD_id

END

END