CREATE PROCEDURE [dbo].[ccspRepOutDialDetail]   
		@action as tinyint,  
		@from as datetime = null,  
		@to as datetime = null  
		AS  
		if @from is null  
		select @from = convert(datetime,convert(varchar(11),getdate()))  
		select @to = getdate()  
		if @action = 1  begin  
		--Borrar lo que esta para no repetir  
		delete from RepOutDialDetail with(rowlock)  
		where date >= @from AND date < @to  
		declare @country smallint
		select @country=valor from ccSettings where setting_id=104

		--Inserta informaci?n de reporte  
		insert into RepOutDialDetail  
		SELECT fecha,isnull(isnull(dials.cal_key,cs.cal_key),'') cal_key, telefono, dials.tiporesdial_id, isnull(descripcion,'') as resultado, 
		dials.[cam_id],ISNULL(rtrim(ltrim(camps.cam_descripcion)), 'systemTranslated_NoCampaign') as campa, dials.tbusy as Msgtime,  
		datepart(yyyy,fecha), datepart(mm,fecha), datepart(dd,fecha), datepart(hh,fecha), datepart(mi,fecha), isnull(rl.name,'')  
		,case when answerbit = 1 then 'systemTranslated_Charged' else 'systemTranslated_NotCharged' end as billed, 
		isnull(cs.Dato1,'') as data1, isnull(cs.Dato2,'') as data2, isnull(cs.Dato3,'') as data3, isnull(cs.Dato4,'') as data4, isnull(cs.Dato5,'') as data5
		,case when dials.[file_moved] = 1 then 'systemTranslated_Remoto' else 'Local' end as file_Moved, dials.disconnectCause, COALESCE(dat.description, descripcion,'N/A') DCCustomer
		,dials.dialType,case when @country=1 then isnull((select case when dials.tipoLlamada_id in (1,2,5)   then 'systemTranslated_fijo'
			when dials.tipoLlamada_id in(3,4) then 'systemTranslated_cellPhone' else  'systemTranslated_Indefinite' end
			),'systemTranslated_Indefinite') else '' end as TipoTel
		FROM 
		(select dial.logDial_id,dial.callout_id,dial.cam_id,dial.tipoResDial_id,dial.Telefono,dial.Puerto,dial.fecha,dial.tDialing,  
			case when Left(dial.TipoDialingMode,1)='1' then 'Preview' else
					case when right(dial.TipoDialingMode,2)='00' then 'systemTranslated_Auto' 
					when right(dial.TipoDialingMode,2) in ('10','01') then 'systemTranslated_Manual' end end as dialType,
			dial.tBusy,dial.answerbit,dial.canceledNoAgents,dial.cal_id,dial.disconnectCause, co.cal_key, co.file_moved,dial.tipoLlamada_id 
			FROM ccoLogDials dial (nolock)
			left join ccocallsout co (nolock) on dial.cal_id=co.cal_id
			WHERE fecha >= @from AND fecha < @to) dials  
		LEFT JOIN ccoCallsOutSource cs (nolock) ON dials.callout_id = cs.callout_id  
		LEFT JOIN cctipoResultadoDial tr ON dials.tiporesdial_id=tr.tiporesdial_id  
		LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]  
		LEFT JOIN ccRIARegistryLists rl ON cs.list_id = rl.list_id 
		LEFT JOIN DC_Extra dat on(dat.id = case when isnumeric(substring(dials.disconnectCause,21,3))=0 then '' else substring(dials.disconnectCause,21,3) end )
		WHERE fecha >= @from AND fecha < @to  
		order by fecha  
		end