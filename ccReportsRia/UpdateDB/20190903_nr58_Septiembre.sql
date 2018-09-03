/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Armando Rodriguez
Date: 2018/09/03
Description:
CW-2257 Nueva columna de disconectCause para geller

Database: ccReportsRia
Required version: 57


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =58
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try
	
		set @process = 'CW-2257 Geller agregar columna a rep. detalle de llamadas de causa de deaconexion del cliente'
		set @sql='if exists (select * from sys.tables where name = ''DC_Extra'') begin
				drop table DC_Extra
			end'
		EXEC(@sql)
		
		set @process = 'CW-2257 Geller agregar columna a rep. detalle de llamadas de causa de deaconexion del cliente'
				set @sql='CREATE TABLE DC_Extra
				(
					[id] [int] primary key,
					[description] varchar(100) default('')
				)'
		EXEC(@sql)
		
		set @process = 'CW-2257 Geller agregar columna a rep. detalle de llamadas de causa de deaconexion del cliente'
		set @sql='if not exists (select * from sys.columns where name = N''DCCustomer'' and Object_ID = Object_ID(N''RepOutDialDetail''))
				begin
					alter table RepOutDialDetail
						add DCCustomer varchar(250) null
				end'
		EXEC(@sql)
				
		set @process = 'CW-2257 Geller agregar columna a rep. detalle de llamadas de causa de deaconexion del cliente'
		set @sql='ALTER PROCEDURE [dbo].[ccspRepOutDialDetail]  
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

			--Inserta información de reporte  
			insert into RepOutDialDetail  
			SELECT fecha,isnull(isnull(dials.cal_key,cs.cal_key),'''') cal_key, telefono, dials.tiporesdial_id, isnull(descripcion,'''') as resultado,  
			dials.[cam_id],ISNULL(rtrim(ltrim(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') as campa, dials.tbusy as Msgtime,  
			datepart(yyyy,fecha), datepart(mm,fecha), datepart(dd,fecha), datepart(hh,fecha), datepart(mi,fecha), isnull(rl.name,'''')  
			,case when answerbit = 1 then ''systemTranslated_Charged'' else ''systemTranslated_NotCharged'' end as billed, 
			isnull(cs.Dato1,'''') as data1, isnull(cs.Dato2,'''') as data2, isnull(cs.Dato3,'''') as data3, isnull(cs.Dato4,'''') as data4, isnull(cs.Dato5,'''') as data5
			,case when dials.[file_moved] = 1 then ''systemTranslated_Remoto'' else ''Local'' end as file_Moved, dials.disconnectCause, isnull(dat.description,''N/A'') DCCustomer
			FROM 
			(select dial.logDial_id,dial.callout_id,dial.cam_id,dial.tipoResDial_id,dial.Telefono,dial.Puerto,dial.fecha,dial.tDialing,  
				dial.tBusy,dial.answerbit,dial.canceledNoAgents,dial.cal_id,dial.disconnectCause, co.cal_key, co.file_moved 
				FROM ccoLogDials dial (nolock)
				left join ccocallsout co (nolock) on dial.cal_id=co.cal_id
				WHERE fecha >= @from AND fecha < @to) dials  
			LEFT JOIN ccoCallsOutSource cs (nolock) ON dials.callout_id = cs.callout_id  
			LEFT JOIN cctipoResultadoDial tr ON dials.tiporesdial_id=tr.tiporesdial_id  
			LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]  
			LEFT JOIN ccRIARegistryLists rl ON cs.list_id = rl.list_id 
			LEFT JOIN DC_Extra dat on(dat.id = substring(dials.disconnectCause,21,3))
			WHERE fecha >= @from AND fecha < @to  
			order by fecha  
		 end
'
		EXEC(@sql)



		if @actualVersion  = @version - 1
	 	exec ccsp_getVersion 'BD', @version


	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off