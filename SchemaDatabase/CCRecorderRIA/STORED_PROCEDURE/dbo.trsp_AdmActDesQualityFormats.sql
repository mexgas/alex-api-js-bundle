-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: June 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmActDesQualityFormats]
	-- Add the parameters for the stored procedure here

@id_formato int,
@activate int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF @activate = 1 
BEGIN
Update CCRecorderRIA.dbo.RIA_FORMATOS set activo = 1 where id_formato = @id_formato
END
ELSE 
BEGIN
Update CCRecorderRIA.dbo.RIA_FORMATOS set activo = 0 where id_formato = @id_formato
END

END