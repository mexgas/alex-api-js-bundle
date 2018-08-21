/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
		
Date: 2018/05/15
Description:

Database: CCRecorderRia
Required version: 

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 22
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 15
	begin
		begin tran
		begin try
	
	
    set @process = 'CW-2016 --Ver en Finder solo los grupos de trabajo alter trsp_InsertRecNode'
        set @Sql= '
ALTER procedure [dbo].[trsp_InsertRecNode]
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
 declare @sqlCRM nvarchar(2000)
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
    set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
    execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
  end

  if exists(select * from RIA_RecNodeHistory where grab_id=@grabId) begin
  update RIA_RecNodeHistory set node =@xml,[status]=2 where grab_id = @grabId
  end
  else if not exists(select * from ria_RecNode where grab_id=@grabId) begin
  insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),0)
  end
  else begin
  update ria_RecNode set node =@xml,[status]=2 where grab_id = @grabId
  end
  --select @xml
 end
end
  
   '
        EXEC(@Sql)

				
		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix 

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
