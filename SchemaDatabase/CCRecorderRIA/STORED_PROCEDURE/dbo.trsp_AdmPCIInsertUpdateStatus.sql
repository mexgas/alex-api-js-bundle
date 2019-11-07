-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: March 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmPCIInsertUpdateStatus]
	-- Add the parameters for the stored procedure here

@Type int,
@GrabID int,
@Status int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF @Type = 1 
BEGIN 
Insert RIA_PCI_STATUS (grab_id, pci_status) values( @GRABID, @STATUS)
END
ELSE IF @Type = 2
BEGIN
Update RIA_PCI_STATUS set pci_status = @Status where grab_id  = @GrabID
END

END