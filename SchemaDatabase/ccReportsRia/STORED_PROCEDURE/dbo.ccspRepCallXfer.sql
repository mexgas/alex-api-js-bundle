CREATE PROCEDURE [dbo].[ccspRepCallXfer]
					@action as tinyint,
					@from AS datetime = null,
					@to AS datetime = null
					AS

					SET NOCOUNT ON
		
					if @action = 1
					begin
						if @from is null
							select @from = convert(datetime,convert(varchar(11),getdate()))
						if @to is null	
							select @to = getdate()
		
						delete RepCallXfer with(rowlock)	where [date] between @from and @to
						
						insert RepCallXfer 
						select convert(varchar(10),fechafin,121) [date],
						clt.cal_id callid, case when tipo = 1 then 'systemTranslated_inbound' else 'systemTranslated_outbound' end CallTypes, 
						isnull((select nombres + ' ' + apellidopaterno + ' ' + apellidomaterno from ccUserView nolock where user_id = 
						(case tipo when 1 then ci.User_id else co.User_id end)),'systemTranslated_NoName') Agent,	
						case when modo = 0 then 'systemTranslated_blindXfer' 
						when modo = 1 then 'systemTranslated_Agent' 
						when modo = 2 then 
							case when cast(clt.destino as int) >= 0 then 'systemTranslated_acd' else 'systemTranslated_Survey' end
						when modo = 3 then 'systemTranslated_conference' 
						when modo = 4 then 'systemTranslated_supXfer' 
						when modo in(5,6) then 'systemTranslated_overflow' end as xfertype,
						case when modo = 0 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
						when modo = 1 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),'systemTranslated_Indefinite') 
						when modo = 2 then 
							case when cast(clt.destino as bigint) >= 0 then
								isnull((select descripcion from ccinbound where inbound_id = clt.destino),'systemTranslated_Indefinite') 
							else
								isnull((select top 1 description from survey where active=1 and scriptId = abs(cast(clt.destino as int))),'systemTranslated_Indefinite') 
							end
						when modo = 3 then isnull((select nombre from telefonosConferencia where tel = clt.destino),clt.destino) 
						when modo = 4 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
						when modo in(5,6) then  isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end destination,
						tantesxfer timebeforexfer,
						tdespuesxfer timeafterxfer,
						dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate,
						fechafin as endDate,		
						case when camp.cam_descripcion is not null then  camp.cam_descripcion 
						when inbound.descripcion is not null then  inbound.descripcion				
						else 'systemTranslated_Indefinite' end as Origin,
						tantesxfer+tdespuesxfer as TotalTimeDuration,				
						isnull((select case clt.tipoLlamada_id when 1 then 'systemTranslated_fijo'
							when 3 then 'systemTranslated_cellPhone' else 'systemTranslated_interno' end
							),'systemTranslated_Indefinite') as TipoTel,
						(case tipo when 1 then ci.User_id else co.User_id end) User_ID
						from cclogtransfers clt 
						left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
						left join cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1
						left join cccamps camp on camp.cam_id =co.cam_id
						left join ccinbound inbound on inbound.Inbound_id =ci.Inbound_id
						WHERE fechafin >= @from and fechafin < @to
					end