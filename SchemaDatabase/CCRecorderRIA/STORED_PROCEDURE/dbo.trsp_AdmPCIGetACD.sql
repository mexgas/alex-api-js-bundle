CREATE PROCEDURE [dbo].[trsp_AdmPCIGetACD]

@User_id int 

AS
BEGIN

	SET NOCOUNT ON;

	 select a1.Inbound_id, a1.descripcion , a3.frame, isnull(a4.Xtime,0) as Xtime, isnull(a4.ActiveXtime,0) as ActiveXtime, isnull(a4.onOff,0) as OnOff

	 from ccInbound a1 inner join ccRIAInboundGraph a2 on (a1.Inbound_id = a2.Inbound_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
     left join RIA_PCI_ACD_SETTINGS a4 on (a4.Inbound_id = a1.Inbound_id)
	 where a1.Inbound_id in (select cam_id from fGet_CampAcd_Area (@User_id, 2))
	 order by descripcion

END