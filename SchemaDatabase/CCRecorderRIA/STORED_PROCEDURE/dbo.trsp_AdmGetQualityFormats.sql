-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: June 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmGetQualityFormats]
	-- Add the parameters for the stored procedure here

@id_formato as Int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

--select id_formato, nombre, peso, activo, version from CCRecorderRIA.dbo.RIA_FORMATOS order by id_formato


declare @version int


set @version = (select MAX(version) from CCRecorderRIA.dbo.RIA_FORMATOS where id_formato = @id_formato)
select id_formato, nombre, peso, activo, version from CCRecorderRIA.dbo.RIA_FORMATOS where version = @version and id_formato = @id_formato



END