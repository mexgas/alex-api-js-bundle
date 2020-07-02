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

					--select L.*, (L.Attended-L.Xfer) AS Assigned
					select  L.cam_id, ISNULL(L.Calls, 0) Calls, ISNULL(L.Answer, 0)Answer, ISNULL(L.Busy, 0)Busy, ISNULL(L.NoAnswer, 0)NoAnswer, ISNULL(L.Fax, 0)Fax, ISNULL(L.NoService, 0)NoService,
										ISNULL(L.Other, 0)Other, ISNULL(L.Canceled, 0)Canceled, ISNULL(L.Machine, 0)Machine, ISNULL(L.NoTone, 0)NoTone, ISNULL(L.Congestion, 0)Congestion,
										ISNULL(L.Abandon, 0)Abandon, ISNULL(L.Xfer, 0)Xfer, ISNULL(L.AbandonRate, 0)AbandonRate, ISNULL(L.Attended, 0)Attended, ISNULL(L.aggressionFactor, 0)aggressionFactor, ISNULL((L.Attended-L.Xfer), 0) AS Assigned
					from
					(

						select A.*, C.Xfer,
						case when isnull(A.Answer, 0) = 0 then 0 else ((A.Abandon *100.0)/ A.Answer) end as AbandonRate,
						(A.Answer - A.Abandon - A.Canceled) as Attended,
                        B.AggressionFactor
						
						from @table as A

						left join(
							select ccC.cam_id, ccC.AggressionFactor
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