/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Alan Minor 
Date: 2017/21/12
Description:



Database: CCenterRia
Required version: 119.10.2

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

set @version = 119--**********actualizar a 119 sin fix
set @versionfix = 114
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and ( @actualVersionFix >= 112)
	begin
		begin tran
		begin try


		set @process = 'CW-1380 -- Alter SP ccsp_BaseXmngr'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@ids varchar(max)=null,
@name varchar(25) = NULL,
@top varchar(max) = NULL,
@dateIni datetime =null,
@dateEnd datetime =null,
@dateStart dateTime= null
AS
declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
set @sql = ''''
--nota: las acciones 3 y 4 hacerlas para casos dinamicos, (i.e.) si se va controlor por tamaño y asignar un xml nuevo, conusltar Daniel de CW :)

if @action in (1,6) begin --obtiene los nodos a insertar en BX
  if @action = 1 set @status =0
  else if @action = 6 set @status = 2

  if @option = 1 begin
    set @tableName=''ccChatsNode''
    set @columnId=''chatId''
    set @tableNameHistory = ''ccChatsNodeHistory''
  end
  else if @option = 3 begin
    set @tableName=''ccEmailNode''
    set @columnId=''emailId''
    set @tableNameHistory = ''ccEmailNodeHistory''
  end
  else if @option = 4 begin
    set @tableName=''ccTwitterNode''
    set @columnId=''conversationTwitterId''
    set @tableNameHistory = ''ccTwitterNodeHistory''
  end
  if @option in (1,3,4) begin

    declare @auxTag nvarchar(4)
    select @auxTag =case when @option = 1 then ''@C09''
               when @option in (3,4) then ''@C02''
            end

    set @sql=''declare @basexName varchar(max)

select @basexName=Xname from ccBaseXDB where serviceId=''+cast(@option as nvarchar(3))+'' and isFull=0;

    with node ( ''+@columnId+ '',xmlString,dateNode)
    AS(
      select top ('' + @top + '') ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
      ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
      from ''+ @tableName + '' A with(rowlock)
      where A.status ='''''' + cast(@status as nvarchar(3)) +''''''
      union
      select top ('' + @top + '') ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
      ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
      from ''+ @tableNameHistory + '' A with(rowlock)
      where A.status ='''''' + cast(@status as nvarchar(3)) +''''''   )

    select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
    left join ccBaseXDB baseX on baseX.serviceId= ''++ cast(@option as nvarchar(3)) + '' and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
    order by baseX.Xname''

    --print(@sql)
    exec(@sql)
  end
end
else if @action in (2,7) begin--actualiza los nodos insertados en BX
  if @action = 2 set @status =0
  else if @action = 7 set @status = 2

  set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = ''+cast(@status as varchar(max))+''+ 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'' and [status] = ''+cast(@status as varchar(max))
  exec(@sql)
  set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = ''+cast(@status as varchar(max))+''+ 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'' and [status] = ''+cast(@status as varchar(max))
  exec(@sql)

end
else if @action = 3 --trae el nombre de la base de datos en BX
begin
  select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
  insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
end
else if @action = 5 begin --obtener servicios disponibles
  select @chat= 0,@rec= 2,@email= 0,@twitter=0
  select @chat = case when valor > 1 then 1 else 0 end from ccSettings where setting_id = 145
  select @email = case when valor = 1 then 3 else 0 end from ccSettings where setting_id = 155
  select @twitter = case when valor = 1 then 4 else 0 end from ccSettings where setting_id = 173
  select id, ref  from ccFinderServices where id in (@chat, @rec, @email,@twitter)

end
else if @action = 8 begin--trae la lista de las bases para la busqueda
  select Xname from ccBaseXDB where serviceId = @option
   and (

    @dateIni between dateStart and dateEnd
    or @dateEnd between dateStart and dateEnd
    or dateStart between @dateIni and @dateEnd
  )
  union
  select Xname from ccBaseXDB where serviceId = @option and isFull=0
   and (
     dateStart between @dateIni and @dateEnd
     or @dateIni>=dateStart

  )
end
else if @action = 9 begin--Cierra la base datos
  update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()) where serviceId= @option and  isfull = 0 and dateEnd is null
end
else if @action = 11 begin--trae el nombre de la base de datos en BX

	if @option =1 begin
	SELECT isnull(ISNULL(min(node.value(''(/R01/@CDATE)[1]'',''datetime'')),min(node.value(''(/R01/@C09)[1]'',''datetime''))),GETDATE()) as node FROM ccChatsNode where status = 0
	end
	if @option =3 begin
	SELECT isnull(ISNULL(min(node.value(''(/R03/@CDATE)[1]'',''datetime'')),min(node.value(''(/R03/@C02)[1]'',''datetime''))),GETDATE()) as node FROM ccEmailNode where status = 0
	end
	if @option =4  begin
	SELECT isnull(ISNULL(min(node.value(''(/R04/@CDATE)[1]'',''datetime'')),min(node.value(''(/R04/@C02)[1]'',''datetime''))),GETDATE()) as node FROM ccTwitterNode where status = 0
	end

end'
    	EXEC(@Sql)

    	set @process = 'CW-971 -- ALTER SP ccspAgent_GetLastCalls'
      set @Sql= 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id int AS
set nocount on

select * from

(select top 10 cal_id as id, ''IN'' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_ani as Telefono, descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, 
convert(varchar(14), dateadd(second, cal_tDialog-cal_tMoh,0), 108) Duracion,
'''' as CallBack, cal_key, c.inbound_id as IDCampEsp
from ccCallsIn c with(nolock index(IX_ccCallsIn_4)) 
inner join ccInbound i on c.inbound_id = i.inbound_id
left join ccTipoCalif cal on c.calif_id = cal.calif_id
where user_id = @user_id
and cal_inicio > dateadd(hh, -3, getdate())
order by cal_id desc) a

Union

select * from
(select top 10 cal_id as id, ''OUT'' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_telefono as Telefono,cam_descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, 
convert(varchar(14), dateadd(second, cal_tDialog-cal_tMoh,0), 108) Duracion,
convert(varchar(16), cal_fcallback, 121) as CallBack, cal_key, c.cam_id as IDCampEsp
from ccoCallsOut c with(nolock index(IX_ccoCallsOut_9)) 
inner join ccCamps o on c.cam_id = o.cam_id
left join ccTipoCalifOut cal on c.calif_id = cal.calif_id
where user_id = @user_id
and cal_inicio > dateadd(hh, -3, getdate())
order by cal_id desc) b

order by hora desc

set nocount off '
      EXEC(@Sql)

    set @process = 'CW-1273 CW-1280 Alter SP ccsp_AgentUpdateCallTimes'
    set @Sql= 'ALTER procedure [dbo].[ccsp_AgentUpdateCallTimes]
@IDCall int,
@cal_tXfer smallint,
@cal_tDialog smallint,
@cal_tNotas smallint,
@TipoCall tinyint,
@cal_tRing smallint=0,
@mtmoh smallint = 0,
@isChatCall bit = 0,
@isErroManualCall bit =0
AS
set nocount on
if @IDCall<=0 
  return(0)

declare @tMinAVRS smallint

if @TipoCall=1 --INBOUND
 begin
  Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
  cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
  cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
  Where cal_id= @IDCall
    
 
  -- Elimina callback generado por abandono
  Declare @ANI_x varchar(19)
  select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

  DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
  DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
 end

if @TipoCall=2 --OUTBOUND
 begin   
  Update ccoCallsOUT with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
   cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end, 
   cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end, 
   cal_manual=case when @isChatCall=1 then 3 else cal_manual end 
   Where cal_id=@IDCall
  select * from ccoCallsOUT Where cal_id=@IDCall

  -- calcula el costo de la llamada
  exec ccsp_CstoCalculaCosto @IDCall
 end

select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

if @cal_tDialog >= @tMinAVRS
 begin
  insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
  return(0)
 end

set nocount off'
    EXEC(@Sql)


	/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
--		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end