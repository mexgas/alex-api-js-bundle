/*
Date: 2016/03/04
Description:


 Drop PROCEDURE trsp_SaveAVRSExportParameters
 Create PROCEDURE trsp_SaveAVRSExportParameters

 Alter SP trsp_AdmRecSearchNodeWgCampACDCalif
 Alter SP trsp_GetRecordigsExportService

Database: CCRecorderRia
Required version: 32
*/

SET nocount ON
DECLARE @Version VARCHAR(10)
DECLARE @Version_Actual VARCHAR(10)
DECLARE @Process VARCHAR(MAX)
DECLARE @Sql NVARCHAR(MAX)
DECLARE @errorGenerated VARCHAR(max)


/* Version to release (use the version of your own databse)*/
set @version = 34

/* Actual version (use your own script to do it) */
select @Version_Actual=par_valor from trec_parametros where par_id = 30

if @Version_Actual=@Version-1 BEGIN
BEGIN TRAN
BEGIN TRY

  	set @process = 'ALTER SP trsp_InsertRecNode'
  	set @sql='ALTER procedure [dbo].[trsp_InsertRecNode]
@grabId int,
@type int
as
begin

declare @sql as nvarchar(max)
declare @callType as nvarchar(20)
declare @shoutLevel as nvarchar(20)
declare @date as datetime
declare @formatedDate as nvarchar(50)
declare @language as int
declare @start as int
declare @country as int
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

declare @manualId as int
--declare @score as nvarchar(20)

--Get languange

select @language= valor from ccSettings where setting_id = 27

--Get call type
--Get date
--Call manual
select @callType =tipo_llamada,@date=finicio,@manualId=cal_manual
	from ria_grabacion where grab_id = @grabId

--Get shout level

select @shoutlevel =sho.nombre_nivel from ria_grabacion rec
     inner join ria_tipo_gritos sho on rec.id_nivel_grito = sho.id_nivel_grito
	where rec.grab_id = @grabId



select @start=charindex(''|'',@shoutLevel)


--Languages 0 spanish 1 english
select @shoutlevel=case when @language =0 then substring(@shoutlevel,0,@start) else  substring(@shoutlevel,(@start+1),(LEN(@shoutlevel)-1)) end


--Set format date
select @formatedDate= convert(varchar(23), @date, 126)

select @manual = case when @manualId = 0 then ''N/A'' else ''Manual'' end


--Get rating
set @rating = (
	select  top 1 isnull (total_forma,0)
     from ria_formacalif
     where id_grabacion = @grabId order by fecha_calif desc)



----Get score
--set @score = (
--     select   top 1 isnull (total_forma,0)
--     from ria_formacalif
--     where id_grabacion = @grabId order by fecha_calif desc

--     --left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
--     --left join ccTipoCalif AS f ON a.calif_id = f.calif_id
--     )


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
	c25-----> Score Template
*/

if @type =0 BEGIN---Process to Insert


	if @callType = 1 BEGIN--Inbound
		select  @callID = cal_id from ria_grabacion where grab_id = @grabId

	set @xml = (
		select top 1 rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',
		@formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
		rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
		CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2)
		+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
		isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
		CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
		usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'','''' as ''@C24'','''' as ''@C25'',usr.Login as ''@C26''
		from
		ria_grabacion rec
		inner join ccRIAWorkGroup_Calid wgc on rec.cal_id = wgc.cal_id
		inner join ccriacat_workgroup cwg on wgc.IDWG = cwg.IDWG
		inner join ccRIACampEspWGConsulta cewg on cwg.IDWG = cewg.IDWG
		inner join ccinbound inb on cewg.IdCampEsp = inb.Inbound_id
		inner join ccUsers usr on usr.User_id = rec.age_id
		inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
		inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
		left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
		left join ccTipoCalif AS f  ON rec.calif_id = f.calif_id
		where rec.grab_id = @grabId and	(cewg.Tipo = 0)	and (wgc.tipo = 0)	and (inb.chat = 0)	and (rec.cam_id=cewg.IdCampEsp )
		for xml path(''R02'')
	)

	--Get crm node
		if @xml is not null begin
		select @crmNode = node from ccCRMNodes where [type]=1 and cal_id=@callID
			if @crmNode is not null begin
				update ccCRMNodes set grab_id=@grabId where [type]=1 and cal_id=@callID
				set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
				execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
			end
		end


	END
	else BEGIN

	select  @callID = cal_id from ria_grabacion where grab_id = @grabId

	set @xml = (
		select top 1 rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'', inb.cam_descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',
		@formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
		rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
		CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2)
		+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
		isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
		CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
		usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'','''' as ''@C24'','''' as ''@C25'',usr.Login as ''@C26''
		from
		ria_grabacion rec
		inner join ccRIAWorkGroup_Calid wgc on rec.cal_id = wgc.cal_id
		inner join ccriacat_workgroup cwg on wgc.IDWG = cwg.IDWG
		inner join ccRIACampEspWGConsulta cewg on cwg.IDWG = cewg.IDWG
		inner join cccamps inb on cewg.IdCampEsp = inb.cam_id
		inner join ccUsers usr on usr.User_id = rec.age_id
		inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
		inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
		left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
		left join ccTipoCalif AS f  ON rec.calif_id = f.calif_id
		where (rec.grab_id = @grabId) and	(rec.tipo_llamada = 2)	and (cewg.Tipo = 1) 	and (wgc.tipo = 1)	and (rec.cam_id=cewg.IdCampEsp )
		for xml path(''R02'')
	)

	--Get crm node
		if @xml is not null begin
			select @crmNode = node from ccCRMNodes where [type]=2 and cal_id=@callID
			if @crmNode is not null begin
				update ccCRMNodes set grab_id=@grabId where [type]=2 and cal_id=@callID
				set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
				execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
			end
		end

	END

	if (@xml IS NOT NULL) insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),0)

END

if @type =1 BEGIN---Process to Update

	if exists(select grab_id from RIA_GRABACION where grab_id=@grabId) begin -- Node in RIA_GRABACION
		select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
		RIA_FORMATOS as formatos
		inner join RIA_FORMACALIF formatosCalif on formatosCalif.id_formato=formatos.id_formato
		inner join RIA_GRABACION grabacion  on grabacion.grab_id= formatosCalif.id_grabacion
		inner join ccUsers supervisor on supervisor.User_id = formatosCalif.id_supervisor
		where grabacion.grab_id=@grabId and formatosCalif.tipo=1


		if @callType = 1 BEGIN

			select  @callID = cal_id from ria_grabacion where grab_id = @grabId

		set @xml = (
			select top 1 rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',
			@formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
			rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
			CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2)
			+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
			isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
			CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
			usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', @supervisor as ''@C24'',@Template as ''@C25'',usr.Login as ''@C26''
			from
			ria_grabacion rec
			inner join ccRIAWorkGroup_Calid wgc on rec.cal_id = wgc.cal_id
			inner join ccriacat_workgroup cwg on wgc.IDWG = cwg.IDWG
			inner join ccRIACampEspWGConsulta cewg on cwg.IDWG = cewg.IDWG
			inner join ccinbound inb on cewg.IdCampEsp = inb.Inbound_id
			inner join ccUsers usr on usr.User_id = rec.age_id
			inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
			inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
			left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
			left join ccTipoCalif AS f  ON rec.calif_id = f.calif_id
			where (rec.grab_id = @grabId) and 	(rec.tipo_llamada = 1)	and (cewg.Tipo = 0)	and (wgc.tipo = 0)	and (inb.chat = 0)	and (rec.cam_id=cewg.IdCampEsp )
			for xml path(''R02'')
		)

			--Get crm node
			if @xml is not null begin
				select @crmNode = node from ccCRMNodes where [type]=1 and cal_id=@callID
				if @crmNode is not null	begin
					update ccCRMNodes set grab_id=@grabId where [type]=1 and cal_id=@callID
					set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
					execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
				end
			end
END
else BEGIN
	select  @callID = cal_id from ria_grabacion where grab_id = @grabId

	set @xml = (
		select  top 1  rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'', inb.cam_descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',
		@formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
		rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
		CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2)
		+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
		isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
		CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
		usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',@supervisor as ''@C24'',@Template as ''@C25'',usr.Login as ''@C26''
		from
		ria_grabacion rec
		inner join ccRIAWorkGroup_Calid wgc on rec.cal_id = wgc.cal_id
		inner join ccriacat_workgroup cwg on wgc.IDWG = cwg.IDWG
		inner join ccRIACampEspWGConsulta cewg on cwg.IDWG = cewg.IDWG
		inner join cccamps inb on cewg.IdCampEsp = inb.cam_id
		inner join ccUsers usr on usr.User_id = rec.age_id
		inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
		inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
		left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
		left join ccTipoCalif AS f  ON rec.calif_id = f.calif_id
		where (rec.grab_id = @grabId) and (rec.tipo_llamada = 2) and (cewg.Tipo = 1) and (wgc.tipo = 1)	and (rec.cam_id=cewg.IdCampEsp )
		for xml path(''R02'')
	)

		--Get crm node
		if @xml is not null begin
			select @crmNode = node from ccCRMNodes where [type]=2 and cal_id=@callID
			if @crmNode is not null begin
				update ccCRMNodes set grab_id=@grabId where [type]=2 and cal_id=@callID
				set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
				execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
			end
		end

	END
end
else begin-- Node in RIA_GRABACIONCONSULTA

	select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)
	from RIA_FORMATOS as formatos
	inner join RIA_FORMACALIF formatosCalif on formatosCalif.id_formato=formatos.id_formato
	inner join RIA_GRABACIONCONSULTA grabacion on grabacion.grab_id= formatosCalif.id_grabacion
	inner join ccUsers supervisor on supervisor.User_id = formatosCalif.id_supervisor
	where grabacion.grab_id=@grabId and formatosCalif.tipo=1

if @callType = 1 BEGIN

	select  @callID = cal_id from ria_grabacionconsulta where grab_id = @grabId

set @xml = (
	select rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',
	@formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
	CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2)
	+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
	isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',@supervisor as ''@C24'',@Template as ''@C25'' ,usr.Login as ''@C26''
	from ria_grabacionconsulta rec
	inner join ccRIAWorkGroup_Calid wgc on rec.cal_id = wgc.cal_id
	inner join ccriacat_workgroup cwg on wgc.IDWG = cwg.IDWG
	inner join ccRIACampEspWGConsulta cewg on cwg.IDWG = cewg.IDWG
	inner join ccinbound inb on cewg.IdCampEsp = inb.Inbound_id
	inner join ccUsers usr on usr.User_id = rec.age_id
	inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
	inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
	left join ccTipoCalif AS f  ON rec.calif_id = f.calif_id
	where (rec.grab_id = @grabId) and (cewg.Tipo = 0)	and (wgc.tipo = 0)	and (inb.chat = 0)	and (rec.cam_id=cewg.IdCampEsp )
	for xml path(''R02'')
)

	--Get crm node
	if @xml is not null begin
		select @crmNode = node from ccCRMNodes where [type]=1 and cal_id=@callID
		if @crmNode is not null begin
			update ccCRMNodes set grab_id=@grabId where [type]=1 and cal_id=@callID
			set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
			execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
		end
	end
END
else BEGIN

	select  @callID = cal_id from ria_grabacionconsulta where grab_id = @grabId

set @xml = (
	select rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'', inb.cam_descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',
	@formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
	CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2)
	+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
	isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',@supervisor as ''@C24'',@Template as ''@C25'',usr.Login as ''@C26''
	from
	ria_grabacionconsulta rec
	inner join ccRIAWorkGroup_Calid wgc on rec.cal_id = wgc.cal_id
	inner join ccriacat_workgroup cwg on wgc.IDWG = cwg.IDWG
	inner join ccRIACampEspWGConsulta cewg on cwg.IDWG = cewg.IDWG
	inner join cccamps inb on cewg.IdCampEsp = inb.cam_id
	inner join ccUsers usr on usr.User_id = rec.age_id
	inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
	inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
	left join ccTipoCalif AS f  ON rec.calif_id = f.calif_id
	where (rec.grab_id = @grabId) and (cewg.Tipo = 1) and (wgc.tipo = 1) and (rec.cam_id=cewg.IdCampEsp )
	for xml path(''R02'')
)

	--Get crm node
	if @xml is not null begin
		select @crmNode = node from ccCRMNodes where [type]=2 and cal_id=@callID
		if @crmNode is not null begin
			update ccCRMNodes set grab_id=@grabId where [type]=2 and cal_id=@callID
			set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
			execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
		end
	end
END

end


if (@xml IS NOT NULL) update ria_RecNode set node =@xml,[status]=2 where grab_id = @grabId

END


end'
  	EXEC(@sql)

  	set @process = 'ALTER SP trsp_AdmRecSearchRecs'
  	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchRecs]
@grabIds nvarchar(max)

AS
BEGIN


SET NOCOUNT ON

	declare @sql nvarchar(max)
	declare @isEncrypted bit

	select @isEncrypted=par_valor from TREC_PARAMETROS where par_id=15


	select id_repositorio, ruta_repositorio
	into #tmpRepositorios
	from TREC_REPOSITORIOS
	where id_repositorio = (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential =
		(select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio


	set @sql=''select a.grab_id as grabID,a.cal_id, a.Tipo_llamada, a.id_repositorio,b.ruta_repositorio as repository,
		case a.Tipo_llamada when 2 then ''''OUTBOUND\'''' else ''''INBOUND\'''' end + cast(floor(a.cal_id/10000) as nvarchar(max)) as subpath,
		case a.Tipo_llamada when 2 then ''''O_'''' else ''''I_'''' end + cast(a.cal_id as nvarchar(max)) + ''''.wav''''
		+ case ''+cast(@isEncrypted as nvarchar(max)) +'' when 1 then ''''.enc'''' else '''''''' end  fileAudio
		from RIA_GRABACION a
		inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio
		where a.grab_id in(''+@grabIds+'')
		union
		select a.grab_id as grabID,a.cal_id, a.Tipo_llamada, a.id_repositorio,b.ruta_repositorio as repository,
		case a.Tipo_llamada when 2 then ''''OUTBOUND\'''' else ''''INBOUND\'''' end + cast(floor(a.cal_id/10000) as nvarchar(max)) as subpath,
		case a.Tipo_llamada when 2 then ''''O_'''' else ''''I_'''' end + cast(a.cal_id as nvarchar(max)) + ''''.wav''''
		+ case ''+cast(@isEncrypted as nvarchar(max)) +'' when 1 then ''''.enc'''' else '''''''' end  fileAudior
		from RIA_GRABACIONCONSULTA a
		inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio
		where a.grab_id in(''+@grabIds+'')''

	exec (@sql)

	drop table #tmpRepositorios

END'
  	EXEC(@sql)

------------------ End Script @Sql ------------------

	UPDATE trec_parametros SET par_valor = @version WHERE par_id = 30

COMMIT tran
END try

BEGIN catch
	SELECT @errorGenerated = 'DB Script Version: ' + cast(@Version AS NVARCHAR) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)
	ROLLBACK tran
END catch
END

ELSE
 BEGIN
	SELECT 'Data base incorrect version ' + cast(@Version_Actual AS VARCHAR(5)) + ', please update to  ' + cast(@Version AS VARCHAR(5))
 END
SET nocount off
