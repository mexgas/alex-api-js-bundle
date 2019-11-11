-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: March 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmRecSaveMySearchs]
	-- Add the parameters for the stored procedure here

@MySearchName nvarchar(MAX),
@Sup_id int,
@Workgroups_id nvarchar(MAX),
@Campaigns_id nvarchar(MAX),
@ACD_id nvarchar(MAX),
@Agents_id nvarchar(MAX),
@InDuration nvarchar(MAX),
@FinDuration nvarchar(MAX),
@Pos_id nvarchar(MAX),
@Modulation nvarchar(MAX),
@ScoresIn_id nvarchar(MAX),
@ScoresOut_id nvarchar(MAX),
@CallType int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here


Insert into RIA_MIS_BUSQUEDAS(user_id,mySearchName,workgroups_id, campaigns_id, acd_id, agents_id, scoresOut_id, scoresIn_id, inDuration, finDuration, pos_id, modulation, call_type)
values (@Sup_id,@MySearchName,@Workgroups_id, @Campaigns_id,@ACD_id, @Agents_id, @ScoresOut_id, @ScoresIn_id, @InDuration, @FinDuration, @Pos_id, @Modulation, @CallType)



END