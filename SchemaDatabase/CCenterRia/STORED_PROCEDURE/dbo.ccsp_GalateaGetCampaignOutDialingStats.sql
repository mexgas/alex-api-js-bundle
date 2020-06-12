CREATE PROCEDURE [dbo].[ccsp_GalateaGetCampaignOutDialingStats]
			@Tipo as tinyint=0,
			@cam_id as smallint = 0,
			@sup_id as smallint=0
			AS
			BEGIN

				DECLARE @table TABLE
					 (cam_id SMALLINT, 
					  Calls INT,
					  Answer INT,
					  Busy INT,
					  NoAnswer INT,
					  Fax INT,
					  NoService INT,
					  Other INT,
					  Canceled INT,
					  Machine INT,
					  NoTone INT,
					  Congestion INT,
					  Abandon INT
					  PRIMARY KEY(cam_id)
					 );
					 
			    INSERT INTO @table
			    	EXEC ccsp_OUTGetCallsInfo_AllCamps @Tipo, @cam_id, @sup_id

					select L.*, (L.Attended-L.Xfer) AS Assigned
					
					from
					(

						select A.*, C.Xfer,
						((A.Abandon *100.0)/ A.Answer) as AbandonRate,
						(A.Answer - A.Abandon - A.Canceled) as Attended
						
						from @table as A

						left join(
							select ccC.cam_id, ccC.aggressionFactor
							from ccCamps as ccC
						)B ON A.cam_id = B.cam_id

						left join(
							select Cco.cam_id, COUNT(CASE WHEN Cco.statusCall_id >= 10 THEN 1 END) AS  Xfer
							from ccoCallsOut  as cco
							right join (
								select distinct supCam.cam_id from ccSupervisorCam supCam where user_id=@sup_id
							) D ON Cco.cam_id = D.cam_id
							Where cal_Inicio >  convert(smalldatetime, convert(varchar(11), getdate() ), 101)
							group by Cco.cam_id
						)C ON A.cam_id = C.cam_id

					)L

			END