/*
Autor: Jesus Gallardo
Descripcion:


Version requerida: 50
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 52
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	set @process = 'CW-1770 Version 51  Alter SP trsp_InsertRecNode'
	set @Sql= 'ALTER procedure [dbo].[trsp_InsertRecNode]
@grabId int,
@type int=0
as
begin

  declare @shoutLevel as nvarchar(20)
 declare @language as int
 declare @start as int
 declare @callType int

 declare @xml as xml
 declare @crmNode as xml
 declare @manual as nvarchar(10)
 declare @rating as nvarchar(20)
 declare @sqlCRM nvarchar(max)
 declare @supervisor as nvarchar(50)
 declare @template as nvarchar(50)
 declare @callID as nvarchar(50)
 declare @isHistory bit
 declare @Prefijo varchar(50)
 set @Prefijo = ''''

 declare @table as nvarchar(20)
 set @table=''RIA''

 /*
  CDATE---> Date Generic
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
  C16-----> Duration Reco@rding as 00:00:00
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
  C27-----> Prefix recording
  CID-----> CamId
  CType---> Tipo de llamada
 */

 select @language= valor from ccSettings where setting_id = 27



 if exists (select *  from ria_grabacion where grab_id = @grabId   ) begin
		select @isHistory=0,@callType=rec.tipo_llamada
	  ,@Prefijo = rec.Prefijo
	  ,@manual = case when rec.cal_manual = 0 then ''N/A'' else ''Manual'' end
	  ,@shoutlevel =sho.nombre_nivel
	  ,@rating= isnull(total_forma  ,0)
	  ,@callID=cal_id
	 from ria_grabacion rec
	 left join ria_tipo_gritos sho on rec.id_nivel_grito = sho.id_nivel_grito
	 left join (select top 1 total_forma,id_grabacion from ria_formacalif where id_grabacion = @grabId order by fecha_calif desc)  formCalif on formCalif.id_grabacion=rec.grab_id
	 where grab_id = @grabId
 end
 else begin
	 select
	 @isHistory=1,
	 @callType=rec.tipo_llamada,  @manual = case when rec.cal_manual = 0 then ''N/A'' else ''Manual'' end
	  ,@shoutlevel =sho.nombre_nivel
	  ,@rating= isnull(total_forma  ,0)
	  ,@callID=cal_id
	 from RIA_GRABACIONCONSULTA rec
	 left join ria_tipo_gritos sho on rec.id_nivel_grito = sho.id_nivel_grito
	 left join (select top 1 total_forma,id_grabacion from ria_formacalif where id_grabacion = @grabId order by fecha_calif desc)  formCalif on formCalif.id_grabacion=rec.grab_id
	 where grab_id = @grabId
 end




 --Languages 0 spanish 1 english
 select @shoutlevel=case when @language =0 then substring(@shoutlevel,0,@start) else  substring(@shoutlevel,(@start+1),(LEN(@shoutlevel)-1)) end


 select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
   RIA_FORMATOS as formatos
   inner join RIA_FORMACALIF formatosCalif on formatosCalif.id_formato=formatos.id_formato
   inner join RIA_GRABACION grabacion  on grabacion.grab_id= formatosCalif.id_grabacion
   inner join ccUsers supervisor on supervisor.User_id = formatosCalif.id_supervisor
   where grabacion.grab_id=@grabId and formatosCalif.tipo=1

if @isHistory=0 begin

 set @xml = (
	 select * from (
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	   ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27'',rec.cam_id as ''@CID'',rec.tipo_llamada AS ''@CType''
	   	   from
	   ria_grabacion rec
	   inner join ccinbound inb on rec.cam_id = inb.Inbound_id and rec.tipo_llamada  = 1
	   inner join ccUsers usr on usr.User_id = rec.age_id
	   inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	   left join ccTipoCalif AS e  ON rec.calif_id = e.calif_id
	   inner join ccRIAInboundGraph grap on grap.Inbound_id=inb.Inbound_id
	   where rec.grab_id = @grabId
	  union
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'',inb.cam_descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'',convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.Description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	  ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27'',rec.cam_id as ''@CID'',rec.tipo_llamada AS ''@CType''
	   from
	  ria_grabacion rec
	  inner join cccamps inb on rec.cam_id = inb.cam_id and rec.tipo_llamada  = 2
	  inner join ccUsers usr on usr.User_id = rec.age_id
	  inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	  left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
	  inner join ccRIACampsGraph grap on grap.cam_id=inb.cam_id
	  where rec.grab_id = @grabId  )x
	  for xml path(''R02'')
	 )
 end
 else begin
	 set @xml = (
	 select * from (
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	   ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27'',rec.cam_id as ''@CID'',rec.tipo_llamada AS ''@CType''
	   from
	   RIA_GRABACIONCONSULTA rec
	   inner join ccinbound inb on rec.cam_id = inb.Inbound_id and rec.tipo_llamada  = 1
	   inner join ccUsers usr on usr.User_id = rec.age_id
	   inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	   left join ccTipoCalif AS e  ON rec.calif_id = e.calif_id
	   inner join ccRIAInboundGraph grap on grap.Inbound_id=inb.Inbound_id
	   where rec.grab_id = @grabId
	  union
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'',inb.cam_descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'',convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.Description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	  ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27'',rec.cam_id as ''@CID'',rec.tipo_llamada AS ''@CType''
	   from
	  RIA_GRABACIONCONSULTA rec
	  inner join cccamps inb on rec.cam_id = inb.cam_id and rec.tipo_llamada  = 2
	  inner join ccUsers usr on usr.User_id = rec.age_id
	  inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	  left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
	  inner join ccRIACampsGraph grap on grap.cam_id=inb.cam_id
	  where rec.grab_id = @grabId  )x
	  for xml path(''R02'')
	 )
 end

if @xml is not null begin
	select @crmNode = node from ccCRMNodes where [type]= @callType and cal_id=@callID
	if @crmNode is not null begin
		update ccCRMNodes set grab_id=@grabId where [type]=@callType and cal_id=@callID
		set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(max),@crmNode)+'' into(/R02)[1]'''') ''
		execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
	end
end

if exists(select * from RIA_RecNodeHistory where grab_id=@grabId) begin
	update RIA_RecNodeHistory set node =@xml,[status]=2 where grab_id = @grabId
end
else if not exists(select * from ria_RecNode where grab_id=@grabId) begin
	if @xml is not null
		insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),0)
	else
		insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),-1)
end
else if @xml is not null begin
	update ria_RecNode set node =@xml,[status]=2  where grab_id = @grabId	
end
	--select @xml
end'
    EXEC(@Sql)

    set @process = 'CW-1770 Version 51  drop index ria_recnode.IX_status'
	set @Sql= 'if exists (select * from sys.indexes where name = N''IX_status'' and object_id = OBJECT_ID(N''ria_recnode'')) begin
	drop index ria_recnode.IX_status
 end'
    EXEC(@Sql)

    set @process = 'CW-1770 Version 51 Alter column ria_RecNode.status'
	set @Sql= 'alter table ria_RecNode alter column status smallint'
    EXEC(@Sql)

    set @process = 'CW-1770 Version 51  CReate index ria_recnode.IX_status'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_status'' and object_id = OBJECT_ID(N''ria_recnode'')) begin
	create index IX_status on ria_RecNode(status)
 end
'
    EXEC(@Sql)
		
		
------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
