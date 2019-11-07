CREATE PROCEDURE  [dbo].[trsp_AdmRecSearchNodeACD]
							@Workgroup int

							AS
							BEGIN
								SET NOCOUNT ON;

								select a.idCampEsp, b.descripcion, isnull(d.frame,1) from ccRIACampEspWGConsulta a
								inner join ccInbound b on b.Inbound_id = a.idCampEsp
								left join ccRIAInboundGraph c on  c.Inbound_id = a.idCampEsp
								left join ccRIAGraphics d on d.graphic_id = c.graphic_id
								where a.IDWG = @Workgroup and a.Tipo = 0

							END