-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: Septiembre 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmInsertRepositoryID]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--Declare @count as smallint,
--@countPlus as smallint
    -- Insert statements for procedure here
--set @count = (select count(*) from CCRecorderRIA.dbo.TREC_REPOSITORIOS)
--set @countPlus = (@count + 1)

Insert CCRecorderRIA.dbo.TREC_REPOSITORIOS (ruta_repositorio) values (NULL)


END