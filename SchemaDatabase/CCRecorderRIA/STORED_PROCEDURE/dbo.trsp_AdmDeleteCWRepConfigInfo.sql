-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: September 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmDeleteCWRepConfigInfo]
	-- Add the parameters for the stored procedure here

@RepositoryId smallint

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

Delete from CCRecorderRIA.dbo.TREC_REPOSITORIOS where id_repositorio = @RepositoryId


END