CREATE PROCEDURE [dbo].[trsp_AdmCheckExportProfile]
							@id_usuario int
							AS
							BEGIN
								SET NOCOUNT ON;
								select count(*) from RIA_PERFILES_EXPORTACION where id_usuario = @id_usuario and active = 1
							END