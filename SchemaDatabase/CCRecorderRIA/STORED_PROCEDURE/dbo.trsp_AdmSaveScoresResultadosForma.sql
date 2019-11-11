-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: August 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmSaveScoresResultadosForma]
	-- Add the parameters for the stored procedure here

@id_forma int,
@id_pregunta int,
@id_respuesta int,
@peso int,
@etiquetas nvarchar(MAX)

 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

Insert CCRecorderRIA.dbo.RIA_RESULTADOSFORMA (id_forma,id_pregunta,id_respuesta,peso,etiquetas)
values(@id_forma,@id_pregunta, @id_respuesta,@peso,@etiquetas)

END