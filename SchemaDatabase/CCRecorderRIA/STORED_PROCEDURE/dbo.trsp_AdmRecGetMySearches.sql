-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmRecGetMySearches] 
	-- Add the parameters for the stored procedure here

@Sup_id int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select mysearch_id,mySearchName,workgroups_id,campaigns_id,acd_id,agents_id,inDuration,finDuration,pos_id,modulation, scoresIn_id, scoresOut_id, call_type from RIA_MIS_BUSQUEDAS where user_id = @Sup_id


END