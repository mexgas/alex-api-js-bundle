/*
Autor: Jose Velasco
Fecha: 2016/09/30
Descripcion:

	SP trsp_GetParametersMailByType se agrega
Version requerida: 35
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 37
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

---------------- inicio SCRIPT @Sql ----------------

	--Index

	--Tables

	--Functions

  	--SP

  	set @process = 'Alter SP trsp_InsertRecNode -- Add C26 grafico'
  	set @sql='ALTER procedure [dbo].[trsp_InsertRecNode]
@grabId int,
@type int=0

as
begin

	declare @callType as nvarchar(20)
	declare @shoutLevel as nvarchar(20)
	declare @language as int
	declare @start as int

	declare @xml as xml
	declare @crmNode as xml
	declare @manual as nvarchar(10)
	declare @rating as nvarchar(20)
	declare @sqlCRM nvarchar(2000)
	declare @supervisor as nvarchar(50)
	declare @template as nvarchar(50)
	declare @callID as nvarchar(50)


	declare @table as nvarchar(20)
	set @table=''RIA''

	/*
		C01-----> grab_id
		C02-----> Type of Recording (Inbound/Outbound)
		C03-----> Camp/ACD descripcion
		C04-----> ShoutLevel
		C05-----> Agent Login
		C06-----> Formated date
		C07-----> Position Computer
		C08-----> Duration
		C09-----> Ani
		C10-----> Dnis
		C11-----> Calkey
		C12-----> Manual
		C13-----> User ID
		C14-----> cal ID
		C15-----> Cam /ACD ID
		C16-----> Duration Recording as 00:00:00
		C17-----> Position Extension
		C18-----> rating(Scoring Template)
		C19-----> Reposiory ID
		C20-----> Disposition
		C21-----> Disposition ID
		C22-----> Has Video
		C23-----> Agent Full Name
		C24-----> Supervisor Name
		C25-----> Score Template
		C26-----> graphic_id

	*/

	select @language= valor from ccSettings where setting_id = 27

	select @callType = rec.tipo_llamada
		,@manual = case when rec.cal_manual = 0 then ''N/A'' else ''Manual'' end
		,@shoutlevel =sho.nombre_nivel
		,@rating= total_forma
		,@callID=cal_id
	from ria_grabacion rec
	left join ria_tipo_gritos sho on rec.id_nivel_grito = sho.id_nivel_grito
	left join (select top 1 total_forma,id_grabacion from ria_formacalif where id_grabacion = @grabId order by fecha_calif desc)  formCalif on formCalif.id_grabacion=rec.grab_id
	where grab_id = @grabId


	--Languages 0 spanish 1 english
	select @shoutlevel=case when @language =0 then substring(@shoutlevel,0,@start) else  substring(@shoutlevel,(@start+1),(LEN(@shoutlevel)-1)) end


	select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
			RIA_FORMATOS as formatos
			inner join RIA_FORMACALIF formatosCalif on formatosCalif.id_formato=formatos.id_formato
			inner join RIA_GRABACION grabacion  on grabacion.grab_id= formatosCalif.id_grabacion
			inner join ccUsers supervisor on supervisor.User_id = formatosCalif.id_supervisor
			where grabacion.grab_id=@grabId and formatosCalif.tipo=1

	set @xml = (select * from (
		select rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
		convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
		rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
		CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
		isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
		isnull(e.description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
		usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
			,grap.graphic_id as ''@C26''
			from
			ria_grabacion rec
			inner join ccinbound inb on rec.cam_id = inb.Inbound_id and @callType = 1
			inner join ccUsers usr on usr.User_id = rec.age_id
			inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
			left join ccTipoCalif AS e  ON rec.calif_id = e.calif_id
			inner join ccRIAInboundGraph grap on grap.Inbound_id=inb.Inbound_id
			where rec.grab_id = @grabId
		union
		select rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'',inb.cam_descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
		convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'',convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
		rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
		CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
		isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
		isnull(e.Description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
		usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
		,grap.graphic_id as ''@C26''
		 from
		ria_grabacion rec
		inner join cccamps inb on rec.cam_id = inb.cam_id and @callType = 2
		inner join ccUsers usr on usr.User_id = rec.age_id
		inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
		left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
		inner join ccRIACampsGraph grap on grap.cam_id=inb.cam_id
		where rec.grab_id = @grabId

		)x
		for xml path(''R02'')
	)

	if @xml is not null begin
	select @callType,@callID
		select @crmNode = node from ccCRMNodes where [type]= @callType and cal_id=@callID
		if @crmNode is not null begin
			update ccCRMNodes set grab_id=@grabId where [type]=@callType and cal_id=@callID
			set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
			execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
		end

		if not exists(select * from ria_RecNode where grab_id=@grabId) 	insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),0)
		else update ria_RecNode set node =@xml,[status]=2 where grab_id = @grabId
		select @xml
	end

end'
  	EXEC(@sql)

  	set @process = ''
  	set @sql=''
  	EXEC(@sql)

------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	--update trec_parametros set par_valor = @Version where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

	if @Version_Actual = @Version begin
	begin tran
		begin try

	commit tran

		end try
		begin catch
			select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)
		rollback tran
		end catch
	 end
else
 begin
	select 'Version incorrecta de base de datos, version actual: '
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off