CREATE PROCEDURE [dbo].[trsp_AdmRecSearchNodeCamp]
							@Workgroup int
							AS
							BEGIN
								SET NOCOUNT ON;
								select a.idCampEsp, b.cam_descripcion,isnull(d.frame,1) frame from ccRIACampEspWGConsulta a
								inner join ccCamps b on b.cam_id = a.idCampEsp
								left join ccRIACampsGraph c on  c.cam_id = a.idCampEsp
								left join ccRIAGraphics d on d.graphic_id = c.graphic_id
								where a.IDWG = @Workgroup and a.Tipo = 1
							END