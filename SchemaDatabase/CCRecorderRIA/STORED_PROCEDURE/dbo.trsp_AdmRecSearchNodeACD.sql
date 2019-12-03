CREATE PROCEDURE  [dbo].[trsp_AdmRecSearchNodeACD]
							@Workgroup int,
							@ACD_id int = 0
							AS
							BEGIN
								SET NOCOUNT ON;
								if @Workgroup = 0
								begin
									select distinct a.idCampEsp, b.descripcion, isnull(d.frame,1) from ccRIACampEspWGConsulta a
									inner join ccInbound b on b.Inbound_id = a.idCampEsp and a.Tipo=0
									left join ccRIAInboundGraph c on  c.Inbound_id = a.idCampEsp
									left join ccRIAGraphics d on d.graphic_id = c.graphic_id and type_id=1
								end
								else
								if @ACD_id = 0
								begin
									select distinct a.idCampEsp, b.descripcion, isnull(d.frame,1) from ccRIACampEspWGConsulta a
									inner join ccInbound b on b.Inbound_id = a.idCampEsp and a.Tipo=0
									left join ccRIAInboundGraph c on  c.Inbound_id = a.idCampEsp
									left join ccRIAGraphics d on d.graphic_id = c.graphic_id and type_id=1
									where a.IDWG = @Workgroup and a.Tipo = 0
								end
								else
									select distinct a.idCampEsp, b.descripcion, isnull(d.frame,1) from ccRIACampEspWGConsulta a
									inner join ccInbound b on b.Inbound_id = a.idCampEsp and a.Tipo=0
									left join ccRIAInboundGraph c on  c.Inbound_id = a.idCampEsp
									left join ccRIAGraphics d on d.graphic_id = c.graphic_id and type_id=1
									where b.Inbound_id=@ACD_id
							END