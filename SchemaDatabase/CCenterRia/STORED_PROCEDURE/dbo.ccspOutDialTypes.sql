CREATE PROCEDURE [dbo].[ccspOutDialTypes]	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	DECLARE @country varchar(100) ;
	SELECT @country = valor FROM dbo.ccSettings WHERE setting_id = 104 ;
	
	SELECT tipoLlamada_id,longitud,prefijo FROM dbo.cstoTipoLlamada where country_id = @country ;	
END