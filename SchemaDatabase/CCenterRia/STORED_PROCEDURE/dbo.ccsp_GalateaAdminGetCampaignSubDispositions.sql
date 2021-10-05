CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetCampaignSubDispositions]
				@camp_id int,@type int, @agent_id int 
				AS
				BEGIN
				IF @type=0
					begin
						select c2.Description,
						case when c3.califSubDesc is not null 
							then c3.califSubDesc else 'No Subdisposition' end as SubCalifDescription,
						count(*) Total from ccCallsIn c1
						inner join ccTipoCalif c2 on c1.calif_id=c2.calif_id
						left join ccTipoCalifSub c3 on c1.califSub_id=c3.califSub_id
						where cal_inicio > convert(varchar(11), getdate(), 101)
						AND User_id=@agent_id AND statusCall_id=13
						AND Inbound_id=@camp_id AND c1.califSub_id!=-1
						group by c2.Description,c3.califSubDesc
					END
				IF @type=1
					BEGIN 
						select c2.Description,
						case when c3.califSubDesc is not null 
							then c3.califSubDesc else 'No Subdisposition' end as SubCalifDescription,
						count(*) Total from ccoCallsOut c1
						inner join ccTipoCalifOUT c2 on c1.calif_id=c2.calif_id
						left join ccTipoCalifSubOUT c3 on c1.califSub_id=c3.califSub_id
						where cal_inicio > convert(varchar(11), getdate(), 101)
						AND User_id=@agent_id AND statusCall_id=13
						AND cam_id=@camp_id AND c1.califSub_id!=-1
						group by c2.Description,c3.califSubDesc
					END
				END