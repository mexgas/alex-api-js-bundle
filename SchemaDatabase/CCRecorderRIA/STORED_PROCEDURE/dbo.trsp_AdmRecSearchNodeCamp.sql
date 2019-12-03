CREATE PROCEDURE [dbo].[trsp_AdmRecSearchNodeCamp]
							@Workgroup int,
							@Cam_id int = 0
							AS
							BEGIN
								SET NOCOUNT ON;
								if @Workgroup = 0
								begin
									select distinct a.idCampEsp, b.cam_descripcion,isnull(d.frame,1) frame from ccRIACampEspWGConsulta a
									inner join ccCamps b on b.cam_id = a.idCampEsp and a.Tipo=1
									left join ccRIACampsGraph c on  c.cam_id = a.idCampEsp
									left join ccRIAGraphics d on d.graphic_id = c.graphic_id and type_id=1
								end
								else
								if @Cam_id = 0
								begin
									select distinct a.idCampEsp, b.cam_descripcion,isnull(d.frame,1) frame from ccRIACampEspWGConsulta a
									inner join ccCamps b on b.cam_id = a.idCampEsp and a.Tipo=1
									left join ccRIACampsGraph c on  c.cam_id = a.idCampEsp
									left join ccRIAGraphics d on d.graphic_id = c.graphic_id and type_id=1
									where a.IDWG = @Workgroup and a.Tipo = 1
								end
								else
									select distinct a.idCampEsp, b.cam_descripcion,isnull(d.frame,1) frame from ccRIACampEspWGConsulta a
									inner join ccCamps b on b.cam_id = a.idCampEsp and a.Tipo=1
									left join ccRIACampsGraph c on  c.cam_id = a.idCampEsp
									left join ccRIAGraphics d on d.graphic_id = c.graphic_id and type_id=1
									where b.cam_id = @Cam_id
							END