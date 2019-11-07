CREATE PROCEDURE [dbo].[trsp_AdmGetRecExportProfile]
							@id_usuario int
							AS
							BEGIN
								SET NOCOUNT ON;
							select isnull(max(campos),'') from RIA_PERFILES_EXPORTACION where id_usuario = @id_usuario and active =1
							END