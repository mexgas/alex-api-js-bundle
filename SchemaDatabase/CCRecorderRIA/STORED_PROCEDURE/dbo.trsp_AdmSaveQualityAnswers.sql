-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: June 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmSaveQualityAnswers]
	-- Add the parameters for the stored procedure here

@id_pregunta int,
@etiqueta varchar(120),
@peso int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

insert CCRecorderRIA.dbo.RIA_RESPUESTAS (id_pregunta, etiqueta,peso) values (@id_pregunta, @etiqueta, @peso)


END