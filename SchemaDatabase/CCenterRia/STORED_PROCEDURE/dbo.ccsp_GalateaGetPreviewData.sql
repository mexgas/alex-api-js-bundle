CREATE PROCEDURE [dbo].[ccsp_GalateaGetPreviewData]
		@callout_id int 

		AS
		set nocount on

		select'previewData'=
		 ISNULL(P.Headers,'')+'~'+
		 ISNULL(O.Dato1,'')+'~'+
		 ISNULL(O.Dato2,'')+'~'+
		 ISNULL(O.Dato3,'')+'~'+
		 ISNULL(O.Dato4,'')+'~'+
		 ISNULL(O.Dato5,'')+'~'+
		 ISNULL(P.Dato6,'')+'~'+
		 ISNULL(P.Dato7,'')+'~'+
		 ISNULL(P.Dato8,'')+'~'+
		 ISNULL(P.Dato9,'')+'~'+
		 ISNULL(P.Dato10,'')+'~'+
		 ISNULL(P.Dato11,'')+'~'+
		 ISNULL(P.Dato12,'')+'~'+
		 ISNULL(P.Dato13,'')+'~'+
		 ISNULL(P.Dato14,'')+'~'+
		 ISNULL(P.Dato15,'')
			   from ccoCallsOutSource O
		INNER JOIN ccoCallsPreviewData P on O.cal_Key=P.Cal_key and O.cam_id=P.cam_id
		Where callout_id=@callout_id;
		set nocount off