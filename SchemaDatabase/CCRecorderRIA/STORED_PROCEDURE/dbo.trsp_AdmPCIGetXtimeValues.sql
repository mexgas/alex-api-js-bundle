-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: Febrero 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmPCIGetXtimeValues]
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

Select  isnull(Num_recordings,0) as  Num_recordings, isnull(Suma,0) as Suma from RIA_PCI_XTIME_ACD where Inbound_id = @CamACD_id

END
ELSE IF @Call_Type = 2
BEGIN

Select  isnull(Num_recordings,0) as  Num_recordings, isnull(Suma,0) as Suma from RIA_PCI_XTIME_CAMP where cam_id = @CamACD_id

END

END