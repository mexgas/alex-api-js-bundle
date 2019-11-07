CREATE PROCEDURE [dbo].[trsp_AdmPCIGetCamp]

@User_id int 

AS
BEGIN

	 
	 select a1.cam_id, a1.cam_Descripcion , a3.frame, isnull(a4.Xtime,0) as Xtime,  isnull(a4.ActiveXtime,0) as ActiveXtime, isnull(a4.onOff,0) as OnOff
	 from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
     left join RIA_PCI_CAMP_SETTINGS a4 on (a4.cam_id = a1.cam_id) 
	 --where a1.cam_id in (select cam_id from fGet_CampAcd_Area (@User_id, 1))
     where a1.cam_id in (select cam_id from fGet_CampAcd_Area (@User_id, 1))
	 order by cam_descripcion

END