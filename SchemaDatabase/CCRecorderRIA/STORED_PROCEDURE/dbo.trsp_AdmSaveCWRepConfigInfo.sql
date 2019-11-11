CREATE PROCEDURE [dbo].[trsp_AdmSaveCWRepConfigInfo]
	-- Add the parameters for the stored procedure here

@id_repositorio as tinyint,
@Audio as nvarchar(250),
@AudioRep as nvarchar(250),
@AudioLocal as nvarchar(250),
@Video as nvarchar(250),
@VideoRep as nvarchar(250),
@VideoLocal as nvarchar(250),
@ImagenesRep as nvarchar(250)


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;



Update CCRecorderRIA.dbo.TREC_REPOSITORIOS set ruta_repositorio = @Audio, dirvirtual_audio=@AudioRep, ruta_local=@AudioLocal, 
ruta_rep_video = @Video, dirvirtual_video=@VideoRep, ruta_local_video=@VideoLocal, ruta_imagenes = @ImagenesRep where id_repositorio = @id_repositorio

END