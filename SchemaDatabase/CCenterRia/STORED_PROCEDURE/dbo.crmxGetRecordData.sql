CREATE PROCEDURE [dbo].[crmxGetRecordData]
				@callID int,
				@callType tinyint
			AS
			BEGIN
				SET NOCOUNT ON;
				declare @xmlCallData xml

				if @callType = 2
				begin
					SET @xmlCallData =
					(	select
							cal_id "call/@id",
							cal_key "call/@key",
							cal_telefono "call/@telephone",
							cal_tdialog "call/@length",
							co.user_id "agent/@id",
							isnull(nombres,'')+' '+isnull(ApellidoPaterno,'') "agent/@name",
							isnull(co.calif_id,0) "disposition/@id",
							isnull(tco.description,'') "disposition/@name",
							isnull(co.califSub_id,0) "subdisposition/@id",
							isnull(tcso.califSubDesc,'') "subdisposition/@name"
						from ccocallsout co (nolock)
							left join ccusers us (nolock) on us.user_id=co.user_id
							left join ccTipoCalifOUT tco on tco.calif_id=co.calif_id
							left join ccTipoCalifSubOUT tcso on tcso.califSub_id = co.califSub_id
						where cal_id=@callID
						for XML path ('callData')
					)
				end
				else
				begin
					SET @xmlCallData =
					(	select
							cal_id "call/@id",
							cal_key "call/@key",
							cal_ANI "call/@telephone",
							cal_tdialog "call/@length",
							co.user_id "agent/@id",
							isnull(nombres,'')+' '+isnull(ApellidoPaterno,'') "agent/@name",
							isnull(co.calif_id,0) "disposition/@id",
							isnull(tco.description,'') "disposition/@name",
							isnull(co.califSub_id,0) "subdisposition/@id",
							isnull(tcso.califSubDesc,'') "subdisposition/@name"
						from cccallsin co (nolock)
							left join ccusers us (nolock) on us.user_id=co.user_id
							left join ccTipoCalif tco on tco.calif_id=co.calif_id
							left join ccTipoCalifSub tcso on tcso.califSub_id = co.califSub_id
						where cal_id=@callID
						for XML path ('callData')
					)
				end

				select @xmlCallData
			END