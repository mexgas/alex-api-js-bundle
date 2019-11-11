-- Create date: August 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AgtGetMarks]
	-- Add the parameters for the stored procedure here

@call_id int,
@tipo_llamada int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
select marca from ria_marcas where call_id = @call_id and tipo_llamada = @tipo_llamada order by id_marca;


END