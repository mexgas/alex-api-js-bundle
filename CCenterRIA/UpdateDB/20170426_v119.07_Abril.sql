/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Armando Rodriguez
Date: 2017/04/26
Description:
	se modfiica el SP ccsp_RIACATQualifications para poder guardar y actualizar parametro finishPreview
	se modifica el SP ccsp_RIAsubCalif para obtener la columna finishPreview al cargar la lista de calificaciones
	se modifico el SP ccsptelefonosTransferencia para que no regresara ninguna columna con nulos si no con vacios
	Se modifica el SP ccsp_RIAUpdateEspecConfig para desvincular el dominio del chat del ACD CW-871
	Se modifica el SP ccsp_RIAManageAreas para desasociar cuentas de twitter,email y twitter CW-871
	Se modifica el SP ccsp_TwitterSave donde se buscan los registros los tweets por contestar CW-902
	Se modifica el SP ccspADMaddConversationTweet la parte donde recuperamos el campo close conversation del ACD CW-902

Database: CCenterRia
Required version: 119.06

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

set @version = 119--**********actualizar a 129 sin fix
set @versionfix = 7
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and (@actualVersionFix = @versionfix - 1 or @actualVersionFix = @versionfix)
	begin
		begin tran
		begin try

    set @process = 'Alter Column cctipocalifout.Description -- CW-876'
    set @Sql= 'ALTER TABLE cctipocalifout ALTER COLUMN  Description varchar(60)'
    EXEC(@Sql)

    set @process = 'Alter Column cctipocalifsubout.califSubDesc --CW-876'
    set @Sql= 'ALTER TABLE cctipocalifsubout ALTER COLUMN  califSubDesc varchar(60)'
    EXEC(@Sql)

		set @process = 'Alter cccamps -- Preview Dialer cccamps'
		set @Sql= 'if exists (SELECT * FROM sys.objects WHERE type_desc LIKE ''%CONSTRAINT'' AND OBJECT_NAME(OBJECT_ID)=''DF_ccCamps_progDial'' ) begin alter table cccamps drop DF_ccCamps_progDial
					alter table cccamps alter column progdial smallint not null
					alter table cccamps add constraint DF_ccCamps_progDial default((0)) for progDial end else begin alter table cccamps alter column progdial smallint not null
					alter table cccamps add constraint DF_ccCamps_progDial default((0)) for progDial end'
		EXEC(@Sql)

		set @process = 'Alter cctipocalifout  -- Preview Dialer cctipocalifout'
		set @Sql= 'if not exists (select * from sys.columns where name = N''finishPreview'' AND Object_ID = Object_ID(N''cctipocalifout'') ) alter table cctipocalifout add finishPreview bit'
		EXEC(@Sql)

		set @process = 'Alter ccologdials  -- Preview Dialer ccologdials'
		set @Sql= 'if not exists (Select  * from information_schema.columns WHERE TABLE_NAME=''ccologdials'' AND COLUMN_NAME=''TipoDialingMode'' and DATA_TYPE = ''varchar'' and CHARACTER_MAXIMUM_LENGTH = 8 ) alter table ccologdials alter column TipoDialingMode varchar(8)'
		EXEC(@Sql)

    set @process = 'Update ccsettings  -- disable default campaing'
    set @Sql= 'update ccsettings set valor = 0 where setting_id = 196'
    EXEC(@Sql)

    set @process = 'alter ccsp_OUTGetNewJobs -- '
    set @Sql= 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID int,
@test int=0,
@nAgentsLogin int=1,
@iZonas int = null
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @sql varchar(MAX), @Order_Asc_Desc char(4)
declare @camSurvey int
select @camSurvey = 0
DECLARE @iZonasTable TABLE (value int)

select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

if @iZonas is null begin

      INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
      select @iZonas=value from @iZonasTable
--Checamos si la campaña tiene horarios configurados
      if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
      begin
                  if @iZonas = 0 begin
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                  end
      end
      else begin
            if @camSurvey > 0
                  begin
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                  end
      end
end

set @sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
      cam_id int,
      cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
      cal_status tinyint,
      cal_fechaDial datetime,
      user_id int,
      tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint,
calkey varchar(max)
)''


-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
select @topCount=case when @nAgentsLogin<3 then 30
      when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
      when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
      when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
      when @nAgentsLogin>=16 then 240 else 20 end

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

declare @isVerano varchar(max)
set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin

            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,
            W.list_id, isNull(R.sequence,0) as sequence,
			cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
			left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
            WHERE W.cal_status=1 -- CallBacks
            and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
            and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)

            --select @sql
end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,
            W.list_id, isNull(R.sequence,0) as sequence,
			cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
			left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
            WHERE W.cal_status=0 -- Nuevas sin Tiempo
            and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''

end -- TOMA EN CUENTA LAS NUEVAS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @sql=@sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
      begin
            select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
            WHERE callout_id in(select callout_id from #NEW_JOBS)''
end

if @Test = 2
begin
      select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
      declare @nSQL nvarchar(4000)
      set @nSQL=cast(@sql as nvarchar(4000))
      exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
      return(@total)
end
else
begin
      select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5,
case when tz is null then '''''''' else cal_telefono end as tel,
case when tz2 is null then '''''''' else cal_telefono end as tel2,
case when tz3 is null then '''''''' else cal_telefono end as tel3,
case when tz4 is null then '''''''' else cal_telefono end as tel4,
case when tz5 is null then '''''''' else cal_telefono end as tel5,
NULL as dialOrder, list_id, sequence, calkey FROM #NEW_JOBS where len(cal_telefono)>0

---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
declare @regval int
SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
exec ccsp_RIAGetCampsNvosCB @cam_id=1,@Tipo=2,@user_id =0,@regval=@regval
''
end

set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
print (@sql)
exec(@sql)

return(0)
'

EXEC(@Sql)



    set @process = 'Alter SP  -- ccsp_RIACATQualifications --CW-876'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIACATQualifications]
@qualif_id varchar(max),
@Description varchar(60)=null,
@order varchar(3)=null,
@canReprogram varchar(1)=null,
@Type smallint,
@CamEspId smallint,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null,
@endConversation varchar(1)=null,
@finishPreview bit = 0
AS
set nocount on
declare @sql nvarchar(1000)

if @Type=0
begin
  if @CamEspId=0
    begin
      SELECT calif_id, description FROM ccTipoCalif WITH(NOLOCK) WHERE Calif_Status=1 and description=@qualif_id
      return(0)
  end
  SELECT calif_id, description FROM ccTipoCalifOUT  WHERE CalifOut_Status=1 and description=@qualif_id
  return(0)
end

if @Type=1 -- Load cctipoCalif
begin
  Select C.calif_id, C.Description, C.orden, cast(C.canReprogram as int) as canReprogram, 0 as contactOwner, cast(count(R.califRel_id)as tinyint) hasSub
  ,isnull(C.EndConversation,0) conversationEnd
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, cast(C.canReprogram as int)  ,C.EndConversation--, cast(C.contactOwner as int)
  order by 2
  return(0)
end

If @Type=2 -- Load cctipoCalifOUT
begin
  Select C.calif_id, C.Description, cast(C.canReprogram as int) as canReprogram, C.orden,
  cast(C.keepDial as int) as keepDial, cast(C.autocallback as int) autocallback,  cast(count(R.califRel_id)as tinyint) hasSub,cast(isnull(C.contactOwner,0) as int) as contacOwner,cast(C.finishPreview as int) finishPreview
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, cast(C.canReprogram as int), C.orden, cast(C.keepDial as int), cast(C.autocallback as int), cast(isnull(C.contactOwner,0) as int), cast(C.finishPreview as int)
  order by 2
  return(0)
end

If @Type=3 -- New cctipoCalif
begin
  If exists(select description from ccTipoCalif where Calif_Status=1 and description=@Description)
    begin
      select 2
      return(0)
    end
  If exists(select description from ccTipoCalif where Calif_Status=0 and description=@Description)
  begin
      update ccTipoCalif set orden=@order, CanReprogram=isnull(@canReprogram,0),EndConversation=isnull(@endConversation,0), Calif_Status=1--, contactOwner= isnull(@contactOwner,0)
      where description=@Description
      return(0)
  end
  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation)--, contactOwner
  select isnull(max(calif_id), 0) + 1,@Description, @order, isnull(@canReprogram,0), isnull(@endConversation,0) from ccTipoCalif --, isnull(@contactOwner,0)
  return(0)
 end

If @Type=4 -- Update cctipoCalif
  begin
    If exists(select description from ccTipoCalif where Calif_Status=1 and description=@Description)
      set @Description=null

    UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
    canReprogram=isnull(@canReprogram, canReprogram), EndConversation=isnull(@endConversation,EndConversation)--, contactOwner=isnull(@contactOwner,contactOwner)
    where calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))

    delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

    return(0)
  end

If @Type=5 -- elimina calif
  begin
    delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
    delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
    update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
    return(0)
  end

If @Type=6 -- New cctipoCalifOUT
 begin
 If exists(select description from ccTipoCalifOut where CalifOut_Status=1 and description=@Description)
  begin
  select 2
  return(0)
  end

 If exists(select description from ccTipoCalifOut where CalifOut_Status=0 and description=@Description)
 begin
  update ccTipoCalifOut set orden=@order, CanReprogram=isnull(@canReprogram,0),
  Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), finishPreview=isnull(@finishPreview,0)
  where description=@Description
  return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram,keepDial, autocallback, contactOwner, finishPreview)
 select isnull(max(calif_id), 0) + 1, @Description, @order , 0, @canReprogram, isnull(@keepDial,0), isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), isnull(@finishPreview,0) from ccTipoCalifOut
 return(0)
 end

If @Type=7 -- Update cctipoCalifOUT
 begin
 If exists(select Description from ccTipoCalifOUT where CalifOut_Status=1 and Description=@Description)
  set @Description=null

 UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
 canReprogram=isnull(@canReprogram, canReprogram), keepDial=isnull(@keepDial,keepDial), autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), finishPreview = isnull(@finishPreview,finishPreview)
 where calif_id=@qualif_id

 if @keepDial is not null
  begin
  update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
  end
 return(0)
 end

If @Type=8 -- elimina calif OUT
 begin
 delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
 delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
 update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
 update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
 return(0)
 end

If @Type=9
 begin
 select o.cam_id, cam_descripcion , c.calif_id, co.description as Calificacion, canReprogram, orden, cast(autoCallback as tinyint) autoCallback
 from ccCamps o left join ccCalifCamp c on o.cam_id=c.cam_id and c.tipo=1
 inner join ccTipoCalifOUT co on c.calif_id=co.calif_id
 where co.CalifOut_Status=1 and o.cam_id=@CamEspId
 order by 4
 return(0)
 end

If @Type=10
 begin
 select i.inbound_id as cam_id, descripcion, c.calif_id, ci.description as Calificacion, orden, cast(ci.canreprogram as integer) canreprogram, cast(isnull(ci.EndConversation,0) as integer) EndConversation
 from ccInbound i left join ccCalifCamp c on i.inbound_id=c.cam_id and c.tipo=0
 inner join ccTipoCalif ci on c.calif_id=ci.calif_id
 where ci.Calif_Status=1 and inbound_id=@CamEspId
 order by 4
 return(0)
 end
set nocount off
'
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_RIAsubCalif --CW-876'
		set @Sql= 'ALTER procedure [dbo].[ccsp_RIAsubCalif]
@action tinyint = 0,
@tipo tinyint = null, -- 0:Outbound / 1:Inbound
@calif_id varchar(max) = nulesol,
@califSub_id varchar(max) = null,
@califSubDesc varchar(60) = null,
@canReprogramSub tinyint = null,
@orden varchar(3) = null,
@idTipoLista int = null,
@keepDial tinyint = null,
@autoCallback tinyint = null,
@contactOwner tinyint = null,
@endConversation tinyint = null
as
set nocount on
begin try
 declare @sxML as varchar(max), @xml as xml, @succesValue varchar(2), @succesType varchar(2)
 set @xml = cast(''<?xml version="1.0"?> <MainSubQualificationLoad/>'' as xml)
 set @xml.modify(''insert element action {""} as last into (/MainSubQualificationLoad)[1]'')
 set @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/MainSubQualificationLoad/action)[1]'')

 if @action = 0
  begin
  select @succesValue=0, @succesType=1 -- No se ingreso el action
  goto Success
  end

 if @action=1 -- Muestra info de Inbound
  begin
  set @xml.modify(''insert element qualifications {""} as last into (/MainSubQualificationLoad)[1]'')
  set @xml.modify(''insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]'')
  set @xml.modify(''insert element subQualifications {""} as last into (/MainSubQualificationLoad)[1]'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  calif_id as "qualification!1!qualif_id", Description as "qualification!1!qualification",
  CanReprogram as "qualification!1!canReprogram", orden as "qualification!1!sort", isnull(endConversation,0) as "qualification!1!endConversation",
  isnull(0,0) as "qualification!1!contactOwner"
  from cctipocalif where Calif_Status=1) as x order by tag, "qualification!1!sort",
  "qualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<qualifications/>'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification", isnull(O.canReprogram,0) "qualifRelation!1!canReprogram", isnull(O.EndConversation,0) "qualifRelation!1!endConversation"
  from cctipoSubCalifRel R join cctipocalifSub O on R.califSub_id = O.califSub_id
  where R.tipoSubRel=1 and R.calif_id in (select top 1 calif_id from cctipocalif where Calif_Status=1 order by orden, Description)) as x
  order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  califSub_id as "subQualification!1!qualif_id", califSubDesc as "subQualification!1!qualification",
  isnull(CanReprogram, 0) as "subQualification!1!canReprogram", isnull(orden, 0) as "subQualification!1!sort", isnull(EndConversation, 0) as "subQualification!1!endConversation"
  from cctipocalifSub where CalifSub_Status=1 ) as x order by tag, "subQualification!1!sort",
  "subQualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<subQualifications/>'')

  select @xml
  return(0)
  end

 if @action=2 -- Muestra Info de Outbound
  begin
  set @xml.modify(''insert element qualifications {""} as last into (/MainSubQualificationLoad)[1]'')
  set @xml.modify(''insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]'')
  set @xml.modify(''insert element subQualifications {""} as last into (/MainSubQualificationLoad)[1]'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  calif_id as "qualification!1!qualif_id", Description as "qualification!1!qualification",
  CanReprogram as "qualification!1!canReprogram", orden as "qualification!1!sort",
  autoCallback as "qualification!1!AutoCB", keepDial as "qualification!1!keepDial", contactOwner as "qualification!1!contactOwner", finishPreview as "qualification!1!preview"
  from cctipocalifOUT where CalifOut_Status=1) as x order by tag, "qualification!1!sort",
  "qualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<qualifications/>'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification", isnull(O.canReprogram,0) "qualifRelation!1!canReprogram"
  from cctipoSubCalifRel R join cctipocalifSubOUT O on R.califSub_id = O.califSub_id
  where R.tipoSubRel=0 and R.calif_id in (select top 1 calif_id from cctipocalifOUT where CalifOUT_Status=1 order by orden, Description)) as x
  order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  califSub_id as "subQualification!1!qualif_id", califSubDesc as "subQualification!1!qualification",
  isnull(CanReprogram,0) as "subQualification!1!canReprogram", isnull(orden,0) as "subQualification!1!sort",
  isnull(autoCallback,0) as "subQualification!1!AutoCB", isnull(keepDial,0) as "subQualification!1!keepDial", isnull(contactOwner,0) as "subQualification!1!contactOwner"
  from cctipocalifSubOUT where CalifSubOut_Status=1 ) as x order by tag, "subQualification!1!sort",
  "subQualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<subQualifications/>'')

  select @xml
  return(0)
  end

  if @tipo is null
  begin
  select @succesValue=0, @succesType=2 -- No se ingreso el tipo
  goto Success
  end

 if @action=3 -- Muestra relacion de Calificaciones con subCalificaciones
  begin
  set @xml.modify(''insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]'')

  if @tipo=0
   begin
   select @sxML = cast((select * from (select 1 as tag, null as parent,
   R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification",
   isnull(O.canReprogram,0) "qualifRelation!1!canReprogram", autoCallback "qualifRelation!1!autoCallback"
   from cctipoSubCalifRel R join cctipocalifSubOUT O on R.califSub_id = O.califSub_id
   where R.tipoSubRel=0 and R.calif_id in (select value from dbo.fn_RIASplitDelimited(@calif_id,'',''))) as x
   order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
   select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')
   select @xml
   return(0)
   end

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification",
  isnull(O.canReprogram,0) "qualifRelation!1!canReprogram"
  from cctipoSubCalifRel R join cctipocalifSub O on R.califSub_id = O.califSub_id
  where R.tipoSubRel=1 and R.calif_id in (select value from dbo.fn_RIASplitDelimited(@calif_id,'',''))) as x
  order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')
  select @xml
  return(0)
  end

 if @action=4 -- Alta de subcalificaciones
  begin
  if isnull(@califSubDesc, '''')=''''
   begin
   select @succesValue=0, @succesType=6 -- No se ingreso el nombre de la subcalificacion
   goto Success
   end

  if @tipo=0
   begin
   if exists(select califSub_id from cctipocalifSubOUT where califSubOut_Status=1 and califSubDesc=@califSubDesc)
    begin
    select @succesValue=0, @succesType=3 -- La subCalificacion ya existe
    goto Success
    end

   insert cctipocalifSubOUT (califSubDesc, canReprogram, orden, idTipoLista, califSubOut_Status, keepDial, autoCallback, contactOwner)
   select @califSubDesc, @canReprogramSub, @orden, @idTipoLista, 1, @keepDial, @autoCallback, isnull(@contactOwner,0)
   select @succesType=scope_identity(), @succesValue=1
   goto Success
   end

  if exists(select califSub_id from cctipocalifSub where califSub_Status=1 and califSubDesc=@califSubDesc)
   begin
   select @succesValue=0, @succesType=3 -- La subCalificacion ya existe
   goto Success
   end
  insert cctipocalifSub (califSubDesc,orden,canReprogram,califSub_Status,EndConversation)--,contactOwner
        select @califSubDesc, @orden, @canReprogramSub, 1,isnull(@endConversation, 0)--,isnull(@contactOwner,0)
  select @succesType=scope_identity(), @succesValue=1
  goto Success
  end

 if @action=5 -- baja de subcalificaciones
  begin
   delete cctipoSubCalifRel where tipoSubRel=@tipo and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, '',''))

  if @tipo=0
   begin
   update cctipocalifSubOUT set califSubOut_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, '',''))
   update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
   select @succesValue=1
   goto Success
   end

  update cctipocalifSub set califSub_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, '',''))
  select @succesValue=1
  goto Success
  end

 if @action=6 -- Actualizacion de subcalificaciones
  begin
   if @tipo=0
   begin
   if not exists(select califSub_id from cctipocalifSubOUT where califSub_id = cast(@califSub_id as smallint))
    begin
    select @succesValue=0, @succesType=4 -- La subCalificacion no existe
    goto Success
    end

   update cctipocalifSubOUT set califSubDesc=isnull(@califSubDesc, califSubDesc), canReprogram=isnull(@canReprogramSub, canReprogram),
    orden=isnull(@orden, orden), idTipoLista=isnull(@idTipoLista, idTipoLista), keepDial=isnull(@keepDial, keepDial),
    autoCallback=isnull(@autoCallback, autoCallback), contactOwner= isnull(@contactOwner,0) where califSub_id = cast(@califSub_id as smallint)
   update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
   select @succesValue=1
   goto Success
   end

  if not exists(select califSub_id from cctipocalifSub where califSub_id = cast(@califSub_id as smallint))
   begin
   select @succesValue=0, @succesType=4 -- La subCalificacion no existe
   goto Success
   end

  if @canReprogramSub=1
         begin
   declare @asignada bit, @can bit
   select @asignada=IB.inbound_id, @can=IB.cam_id from cctipoSubCalifRel CR join cctipoCalif TC on CR.calif_id = TC.calif_id and CR.tipoSubRel=1
      join ccCalifCamp CM on TC.calif_id = CM.calif_id and CM.tipo = 0 join ccInbound IB on CM.cam_id = IB.inbound_id where califSub_id = cast(@califSub_id as smallint)
            if @asignada is not null and @can is null
       begin
       select @succesValue=0, @succesType=5 -- No se puede reprogramar ya que no hay campaña asignada
       goto Success
       end
         end

  update cctipocalifSub set califSubDesc=isnull(@califSubDesc, califSubDesc), orden=isnull(@orden, orden),
   canReprogram=isnull(@canReprogramSub, canReprogram), EndConversation = isnull(@endConversation, 0) where califSub_id = cast(@califSub_id as smallint)

  exec ccsp_RIACATQualifications @Type = 4, @CamEspId = 0, @canReprogram = @canReprogramSub, @qualif_id = @califSub_id
  select @succesValue=1
  goto Success
  end

 if @action=7 -- Asignacion de Calfs / SubCalfs
  begin
  if @tipo=1 and (select cast(sum(isnull(cast(canReprogram as tinyint),0)) as bit) FROM cctipocalifSub where califSub_id in
  (select value from dbo.fn_RIASplitDelimited (@califSub_id, '','')))>0 and not exists (select IB.cam_id from cctipocalif CO
  join ccCalifCamp CF on  CF.calif_id = CO.calif_id and CF.tipo = 0 join ccInbound IB on IB.Inbound_id = CF.cam_id
  where IB.cam_id is not null and CO.calif_id in (select value from dbo.fn_RIASplitDelimited (@calif_id, '','')))
   begin
   select @succesValue=0, @succesType=5 -- No se puede reprogramar ya que no hay campaña asignada
   goto Success
   end

  insert cctipoSubCalifRel (calif_id, califSub_id, tipoSubRel)
  select C.value calif_id, S.value califSub_id, @tipo Tipo
  from dbo.fn_RIASplitDelimited (@califSub_id, '','') S
   cross join dbo.fn_RIASplitDelimited (@calif_id, '','') C
  where cast(C.value as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@tipo as varchar(10)) not in
   (select cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) from cctipoSubCalifRel)
  and C.value is not null and S.value is not null

if @tipo=0
    update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
    select @succesValue=1
    goto Success
end
 if @action=8 -- Desasignacion de Calfs / SubCalfs
    begin
    delete cctipoSubCalifRel
    where cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) in
    (select cast(C.value as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@tipo as varchar(10))
   from dbo.fn_RIASplitDelimited (@califSub_id, '','') S cross join dbo.fn_RIASplitDelimited (@calif_id, '','') C)
    if @tipo=0
      update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
      select @succesValue=1
      goto Success
  end

  return(0)
end try
begin catch
  select @succesValue=0, @succesType=0 -- error no controlado
  goto Success
end catch
Success: -- <success value=''n'' type=''n''/>
set @xml.modify(''insert element success {""} as last into (/MainSubQualificationLoad)[1]'')
set @xml.modify(''insert attribute value {sql:variable("@succesValue")} as last into (/MainSubQualificationLoad/success)[1]'')
if isnull(@succesType, 0) <> 0
begin
  set @xml.modify(''insert attribute type {sql:variable("@succesType")} as last into (/MainSubQualificationLoad/success)[1]'')
end
select @xml
return(0)
set nocount off
'
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_AgentGetCalificaciones'
		set @Sql= 'ALTER procedure [dbo].[ccsp_AgentGetCalificaciones]
@InOut tinyint, --0 in, 1 out
@cam_id int --campaÏa
AS
set nocount on

IF @InOut = 0 BEGIN
if exists(
	select calif.calif_id from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
	left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
	left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
	where cam_id = @cam_id and tipo = @InOut)
  begin
	 declare @relationCamId int
	select @relationCamId =cam_id from ccInbound where Inbound_id=@cam_id
	if @relationCamId is null set @relationCamId=0


	select distinct 1 as tag, null as parent, calif.calif_id "selection!1!id", calif.Description "selection!1!string", calif.orden "selection!1!califorden",
		isnull(calif.EndConversation,0) "selection!1!endConversation",
		null "subSelection!2!id", null "subSelection!2!string", null "subSelection!2!orden",  null "subSelection!2!endConversation"
		from ccTipoCalif calif
	 inner join ccCalifCamp camp on camp.calif_id=calif.calif_id and camp.cam_id=@cam_id and  camp.tipo = @InOut
	 left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
	 left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
	 where calif.CanReprogram=0 or (
		calif.CanReprogram=1 and @relationCamId>0
	 )
	 union
	 select distinct 2 as tag, 1 as parent, calif.calif_id "selection!1!id", null "selection!1!string", calif.orden "selection!1!califorden", isnull(calif.EndConversation,0) "selection!1!endConversation",
		sb.califsub_id "subSelection!2!id", sb.califSubDesc "subSelection!2!string", cast(sb.orden as int) "subSelection!2!orden" ,isnull(sb.EndConversation,0) "subSelection!2!endConversation"
		from ccTipoCalif calif
		inner join ccCalifCamp camp on camp.calif_id=calif.calif_id and camp.cam_id=@cam_id and  camp.tipo = @InOut
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where sb.califsub_id is not null
		and (
			sb.CanReprogram=0 or
			(sb.CanReprogram=1 and @relationCamId>0)
		)
		order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden"
	  for xml explicit, type
  end
 return(0)
 END

IF @InOut = 1 BEGIN
 if exists(
	select calif.calif_id from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
	left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
	left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
	where cam_id = @cam_id and tipo = @InOut)
  begin
		select distinct 1 as tag, null as parent, calif.calif_id "selection!1!id", calif.Description "selection!1!string", calif.keepDial "selection!1!keepOnDial",
		calif.orden "selection!1!califorden", isnull(calif.finishPreview,0) "selection!1!finishPreview", null "subSelection!2!id", null "subSelection!2!string", null "subSelection!2!keepOnDial",
		null "subSelection!2!orden"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = @InOut
		union
		  select distinct 2 as tag, 1 as parent, calif.calif_id "selection!1!id", null "selection!1!string", null "selection!1!keepOnDial",
		  calif.orden "selection!1!califorden", isnull(calif.finishPreview,0) "selection!1!finishPreview", sb.califsub_id "subSelection!2!id", sb.califSubDesc "subSelection!2!string",
		  sb.keepDial "subSelection!2!keepOnDial",
		  cast(sb.orden as int) "subSelection!2!orden"
		  from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		  left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		  left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		  where cam_id = @cam_id and tipo = @InOut and sb.califsub_id is not null
		  order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden"
		  for xml explicit, type
  end
 return(0)
 END

IF @InOut = 10
 BEGIN
  select distinct S.califSub_id, S.califSubDesc, orden
  from cctipoSubCalifRel R join cctipoCalifSub S on R.califSub_id = S.califSub_id
 where R.tipoSubRel=1 and S.califSub_Status=1 and R.calif_id=@cam_id
 order by S.orden, S.califSubDesc
 return(0)
 END

IF @InOut = 11
 BEGIN
  select distinct S.califSub_id, S.califSubDesc, orden
  from cctipoSubCalifRel R join cctipoCalifSubOut S on R.califSub_id = S.califSub_id
 where R.tipoSubRel=0 and S.califSubOut_Status=1 and R.calif_id=@cam_id
 order by S.orden, S.califSubDesc
 return(0)
 END

set nocount off'
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_AGENTInsertCallOut'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_AGENTInsertCallOut]
@cam_id smallint,
@cal_Key varchar(20),
@cal_Telefono varchar(30),
@user_id int,
@cal_extension varchar(7),
@sData varchar(255) = '''', --HLAS para guardar notas de la llamada
@existCallOut as int = 0,
@callmode as smallint = 0
AS
set
nocount on
declare @fecha as datetime, @callout_id as int, @cal_id as int, @calloutMaxTime as int
select @fecha=getdate()

if @callmode = 1
begin
	INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
	 select @existCallOut, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 0, @cal_extension
	select @cal_id = scope_identity()

	insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
	select idwg, cal_id, 0 as user_id, getdate() timestamp, 1 as tipo from ccocallsout cc right join dbo.ccRIACampEspWG wg on (wg.idcampesp = cc.cam_id )
	where wg.tipo = 1 and cal_id = @cal_id

	select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
	select @existCallOut as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
	return(0)
end

if @existCallOut=0
 begin
	declare @LasCallKey varchar(20)
	set @LasCallKey = @cal_Key
	declare @settingCallKey as int
	select @settingCallKey = valor from ccSettings where setting_id = 194

	if(@settingCallKey = 1)
	begin
		if (@cal_Key='''' or @cal_Key is null)
		begin
			select top 1 @LasCallKey=cal_Key from ccoCallsOut where cam_id=@cam_id and cal_Inicio>=convert(datetime,getdate()) and cal_manual=0 order by cal_id desc
			set @cal_Key= @LasCallKey
		end
	end

	INSERT ccocallsoutsource (cal_key, cam_id, cal_telefono, cal_status, user_id, cal_fechaDial, dato1)
	select @cal_Key, @cam_id, substring(@cal_Telefono, 1, 19), 6, @user_id, @fecha, @sData
	select @callout_id = scope_identity()

	INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
	 select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension
	select @cal_id = scope_identity()

	insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
	select idwg, cal_id, 0 as user_id, getdate() timestamp, 1 as tipo from ccocallsout cc right join dbo.ccRIACampEspWG wg on (wg.idcampesp = cc.cam_id )
	where wg.tipo = 1 and cal_id = @cal_id
 end

else
 begin
	Update ccocallsoutsource set cam_id=@cam_id, cal_telefono=substring(@cal_Telefono, 1, 19), dato1=@sData
		where callout_id = @existCallOut
	Update ccocallsout set cam_id=@cam_id, cal_telefono=@cal_Telefono
		where callout_id = @existCallOut
	set @callout_id = @existCallOut
	select @cal_id=cal_id from ccocallsout where callout_id = @existCallOut

	insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
	select idwg, cal_id, 0 as user_id, getdate() timestamp, 1 as tipo from ccocallsout cc right join dbo.ccRIACampEspWG wg on (wg.idcampesp = cc.cam_id )
	where wg.tipo = 1 and cal_id = @cal_id
 end

select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
select @callout_id as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
return(0)
set nocount off'
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_AgentUpdateCallCALIF'
		set @Sql= 'ALTER procedure [dbo].[ccsp_AgentUpdateCallCALIF]
@IDCall int,
@calif_id smallint,
@TipoCall smallint,
@Origin int=0,
@cal_key varchar(20)=null,
@callOutId int=0,
@subId smallint=0

as
set nocount on
declare @RecicleSIC tinyint, @Reprogram tinyint, @DateNewDial smalldatetime, @idTipoLista int, @autoCB tinyint, @tel varchar(30), @camp int, @iddncList as int
declare @userid int
select @RecicleSIC=valor FROM ccSettings WHERE setting_id=60
select @RecicleSIC=IsNull(@RecicleSIC, 0)

if @TipoCall=1
 begin
	Update ccCallsIN Set calif_id=@calif_id, cal_origin_id=@Origin, cal_key=isnull(@cal_key, cal_key),
	califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall

	if exists(select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 0 and calif_id=@calif_id)
	 begin
		select @tel=dbo.Completa_ListaNegra(ci.cal_ANI), @iddncList = cbl.idTipoLista

		from ccCallsIN ci with (index (PK_ccCallsIn))
		 join cccalifblacklist as cbl on ci.calif_id=cbl.calif_id
		where ci.cal_id=@idCall and left(dbo.Completa_ListaNegra(ci.cal_ANI),1)<>''E'' and cbl.tipo=0

		if @tel is not null and @iddncList is not null begin
			--insert ccListaNegra
			insert into cclistanegra (telefono, idtipolista) values(@tel,@iddncList)

			insert ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			select dbo.Completa_ListaNegra(ci.cal_ANI), cbl.idTipoLista, ci.cal_id, getdate(), ci.dni_id, 9
			from ccCallsIN ci with (index (PK_ccCallsIn)) join cccalifblacklist cbl on ci.calif_id=cbl.calif_id
			where ci.cal_id=@idCall and left(dbo.Completa_ListaNegra(ci.cal_ANI),1)<>''E'' and cbl.tipo=0
		end
	 end

	return(0)
 end

if @TipoCall=2
 begin
 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @autoCB=autocallback from ccTipoCalifSubout where califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	if @autoCB is null
	 begin
		select @autoCB = autocallback from cctipocalifout where calif_id = @calif_id
	 end

	if @autoCB = 1
	begin
		select @callOutId=callout_id, @camp=cam_id,@userid=user_id from ccocallsout where Cal_id=@IDCall
		select @DateNewDial=dateadd(mi,t_autoCB,getdate()) from cccamps cam where cam.cam_id = @camp

		exec ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
	end

	Update ccoCallsOUT Set calif_id=@calif_id, califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall

	if exists(select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id)
	and not exists (select co.cal_telefono from ccoCallsOut co with (index (PK_ccoCallsOut))
	join ccListaNegra bl on dbo.Completa_ListaNegra(co.cal_telefono)=bl.telefono or co.cal_telefono=bl.telefono where co.cal_id=@idCall
	and bl.idtipolista in (select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id))
	 begin
		select @tel=dbo.Completa_ListaNegra(co.cal_telefono), @iddncList = cbl.idTipoLista
		from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
		where co.cal_id=@idCall and left(dbo.Completa_ListaNegra(co.cal_telefono),1)<>''E'' and cbl.tipo=1


		if @tel is not null and @iddncList is not null begin
			exec ccsp_InsertDNCList @tel, @iddncList

			insert ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			select dbo.Completa_ListaNegra(co.cal_telefono), cbl.idTipoLista, co.cam_id, getdate(), co.callout_id, 6
			from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
			where co.cal_id=@idCall and left(dbo.Completa_ListaNegra(co.cal_telefono),1)<>''E'' and cbl.tipo=1
		end
	 end

	if @RecicleSIC=1
	 begin
	 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
		select @Reprogram=CanReprogram from ccTipoCalifSubout where califSub_Id = @subId

		-- Si no tiene subcalificacion toma la de la calificacion
		if @Reprogram is null
		 begin
			select @Reprogram=CanReprogram from ccTipoCalifOUT where calif_id=@calif_id
		 end

		if @callOutId=0
			select @callOutId=callout_id from ccocallsout where Cal_id=@IDCall

		Update ccoWorkingTable Set calif_id=@calif_id,
		 cal_status=case @Reprogram when 0 then 3 else cal_status end
		Where callout_id=@callOutId

	 end
	declare @keepDial bit
	declare @finishPreview smallint
	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @keepDial=keepDial from ccTipoCalifSubout where califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	if @keepDial is null
	 begin
		select @keepDial=keepDial from ccTipoCalifout where calif_id = @calif_id
	 end

	select @finishPreview=isnull(finishPreview,0) from ccTipoCalifout where calif_id = @calif_id

	if @keepDial=1
	 begin
		update ccologdials set TipoDialingMode=dbo.fn_getDialingMode(@IDCall, 3, 0, @camp)
		where logDial_id in (select top 1 L.logDial_id from
			ccoLogDials L with(index(IX_ccoLogDials_2), nolock)
			 join ccoCallsOut O with(index(PK_ccoCallsOut), nolock)
			 on L.callout_id = O.callout_id where O.cal_id=@IDCall
			order by L.logDial_id desc)
	 end

	select @keepDial, @finishPreview
	return(0)
 end

set nocount off'
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_DLRSaveDialResult'
		set @Sql= 'ALTER procedure [dbo].[ccsp_DLRSaveDialResult]
@callout_id int,
@cam_id smallint,
@tipoResDial_id tinyint,
@Telefono varchar(30),
@Puerto smallint,
@tDialing tinyint=0,
@tBusy smallint=0,
@call_id int = 0,
@answerbit bit = null,
@tAnswerBit smallint = 0,
@canceledNoAgents bit =0,
@disconnectCause varchar(250) = '''',
@cal_key varchar(20) = ''''
AS
set nocount on
declare @tNow as datetime, @RecicleSIC tinyint
declare @logDial_id int, @preview smallint
declare @tAnswerBitFinal as datetime

SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id = 60
select @tNow=getdate()

select @tAnswerBitFinal = dateadd(ss,-@tAnswerBit,@tNow)

if @call_id > 0 and @tipoResDial_id = 1
BEGIN
	INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key)
	select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''00000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key
END
ELSE
BEGIN
	INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key)
	select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''00000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key
END

select @logDial_id=scope_identity()

if (@RecicleSIC=1) begin
	UPDATE ccoWorkingTable with(rowlock) SET tipoResDial_id = @tipoResDial_id where callout_id = @callout_id
end

select @logDial_id

-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
if @call_id > 0 and @tipoResDial_id = 1
begin
	select @preview = case when progdial=2 then 1 else 0 end from cccamps nolock where cam_id=@cam_id
	if @preview = 1
	begin
		update ccoCallsOut with(rowlock) set cal_puerto = @Puerto where cal_id = @call_id and cal_puerto = 0
	end
	else
	begin
		update ccoCallsOut with(rowlock) set cal_manual = 2, cal_puerto = @Puerto where cal_manual =1 and cal_id = @call_id and cal_puerto = 0
	end
	exec ccsp_CstoCalculaCosto @call_id

	if @cal_key ='''' begin
		select @cal_key=cal_key from ccoCallsOutSource with(nolock) where @callout_id=callout_id
		update ccologdials with(rowlock) set cal_key=@cal_key where logDial_id=@logDial_id
	end

end

-- inserta informacion para reportes de workgroup
insert ccRIAWorkGroup_logDial_id (IDWG, logDial_id, cam_id, timestamp)
select IDWG, @logDial_id, IdCampEsp, getdate()
from ccRIACampEspWG where tipo = 1 and IdCampEsp = @cam_id

-- Guarda configuracion de TipoDialingMode
update ccoLogDials with(rowlock) set TipoDialingMode = dbo.fn_getDialingMode(@call_id, 0, @logDial_id, @cam_id) where logDial_id=@logDial_id
set nocount off'
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_OUTGetNewJobs'
		set @Sql= 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID int,
@test int=0,
@nAgentsLogin int=1,
@iZonas int = null
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @sql varchar(MAX), @Order_Asc_Desc char(4)
declare @camSurvey int
select @camSurvey = 0
DECLARE @iZonasTable TABLE (value int)

select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

if @iZonas is null begin

      INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
      select @iZonas=value from @iZonasTable
--Checamos si la campaña tiene horarios configurados
      if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
      begin
                  if @iZonas = 0 begin
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                  end
      end
      else begin
            if @camSurvey > 0
                  begin
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                  end
      end
end

set @sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
      cam_id int,
      cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
      cal_status tinyint,
      cal_fechaDial datetime,
      user_id int,
      tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint,
calkey varchar(max)
)''


-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
select @topCount=case when @nAgentsLogin<3 then 30
      when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
      when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
      when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
      when @nAgentsLogin>=16 then 240 else 20 end

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

declare @isVerano varchar(max)
set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin

            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,
            W.list_id, isNull(R.sequence,0) as sequence,
			cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
			left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
            WHERE W.cal_status=1 -- CallBacks
            and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
            and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)

            --select @sql
end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,
            W.list_id, isNull(R.sequence,0) as sequence,
			cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
			left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
            WHERE W.cal_status=0 -- Nuevas sin Tiempo
            and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''

end -- TOMA EN CUENTA LAS NUEVAS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @sql=@sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
      begin
            select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
            WHERE callout_id in(select callout_id from #NEW_JOBS)''
end

if @Test = 2
begin
      select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
      declare @nSQL nvarchar(4000)
      set @nSQL=cast(@sql as nvarchar(4000))
      exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
      return(@total)
end
else
begin
      select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5,
case when tz is null then '''''''' else cal_telefono end as tel,
case when tz2 is null then '''''''' else cal_telefono end as tel2,
case when tz3 is null then '''''''' else cal_telefono end as tel3,
case when tz4 is null then '''''''' else cal_telefono end as tel4,
case when tz5 is null then '''''''' else cal_telefono end as tel5,
NULL as dialOrder, list_id, sequence, calkey FROM #NEW_JOBS where len(cal_telefono)>0

---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
declare @regval int
SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
exec ccsp_RIAGetCampsNvosCB @cam_id=1,@Tipo=2,@user_id =0,@regval=@regval
''
end

set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
print (@sql)
exec(@sql)

return(0)'
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_OUTGetNewProviderJobs'
		set @Sql= 'ALTER procedure [dbo].[ccsp_OUTGetNewProviderJobs]
@CAMPID as int,
@test as int=0,
@nAgentsLogin as int=1
as
set nocount on
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @sql varchar(MAX), @Order_Asc_Desc char(4)
declare @camSurvey int
DECLARE @iZonasTable TABLE (value int)

select @camSurvey = 0

select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

-- VALIDAMOS EL PAIS Y LADA CONFIGURADA --
SELECT @country_id =valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
if @iZonas is null begin

	INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
	select @iZonas=value from @iZonasTable
	--Checamos si la campaña tiene horarios configurados
	if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
		begin
		declare @horaUniversal as datetime
		set @horaUniversal=getutcdate()

		if @iZonas = 0 begin
			SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
			return
		end
		end

	else
	begin
		if @camSurvey > 0
			begin
				SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
				return
			end
	end
end

set @sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
	cam_id int,
	cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
	cal_status tinyint,
	cal_fechaDial datetime,
	user_id int,
	tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
tel varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel2 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel3 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel4 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel5 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
dialOrder varchar(10),
list_id int,
sequence smallint,
calkey varchar(max)
)''

-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
	select @topCount=case when @nAgentsLogin<3 then 30
	when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
	when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
	when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
	when @nAgentsLogin>=16 then 240 else 20 end

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

declare @isVerano varchar(max)
set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
	begin
	select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

	select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isnull(R.sequence,0) as sequence,
	couts.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
	FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
	on W.list_id = R.list_id
	left join ccocallsoutsource couts (nolock)
	on W.callout_id = couts.callout_id
	WHERE W.cal_status=1 -- CallBacks
	and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
	and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
	and (
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by W.prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
	end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
	begin
	select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

	select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isNull(R.sequence,0) as sequence,
	couts.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
	FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
	on W.list_id = R.list_id
	left join ccocallsoutsource couts (nolock)
	on W.callout_id = couts.callout_id
	WHERE W.cal_status=0 -- Nuevas sin Tiempo
	and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
	and (
		( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
		( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', W.callout_id''

	end -- TOMA EN CUENTA LAS NUEVAS

----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @sql=@sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
	begin
	select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
	WHERE callout_id in(select callout_id from #NEW_JOBS)''
	end

select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5, tel, tel2, tel3, tel4, tel5, dialOrder, list_id, sequence, calkey FROM #NEW_JOBS where len(cal_telefono)>0''

select @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print @sql
exec(@sql)
return(0)'
		EXEC(@Sql)

		set @process = 'Alter Function  -- fn_getDialingMode'
		set @Sql= 'ALTER function [dbo].[fn_getDialingMode](@call_id int, @TipoDialingMode tinyint, @logDial_id int, @cam_id int)
returns nvarchar(8)
as
begin
	declare @valor nvarchar(8), @calif_id smallint, @califSub_id smallint, @cal_manual tinyint, @keepDial char(1)
	set @keepDial=''0''

	-- En el caso de que no cuente con cal_id, se debe contar con logDial_id, por lo cual se busca el registro
	if @call_id is null
	 begin
		select top 1 @call_id=o.cal_id from ccoLogDials l with(nolock,index(PK_ccoLogDials)) join ccocallsout o with(nolock,index(IX_ccoCallsOut_2))
			on l.callout_id = o.callout_id and l.Puerto = o.cal_puerto
		where l.logDial_id = @logDial_id and l.fecha between convert(varchar(19), dateadd(minute, -5, o.cal_inicio), 121)
		and convert(varchar(19), dateadd(minute, 5, o.cal_inicio), 121)
		order by datediff(ss, l.fecha, o.cal_inicio) asc -- en caso de tener mas de uno, toma el que tenga menor diferencia en tiempo
	 end

	if @cam_id is null
	 begin
		select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual, @cam_id=cam_id
		from ccocallsout O with(nolock,index(PK_ccoCallsOut))
		where O.cal_id = @call_id
	 end
	else
	 begin
		select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual
		from ccocallsout O with(nolock,index(PK_ccoCallsOut))
		where O.cal_id = @call_id
	 end

	select @valor=isnull((select case when progDial=2 then ''10'' when progDial=1 then ''01'' else ''00'' end + cast(iTipoDial as char(1)) + cast(abandonCallback as char(1))
	 + cast(excCallback as char(1)) from cccamps where cam_id=@cam_id), ''00000'')

	if ((select keepDial from ccTipoCalifOUT where calif_id = @calif_id)=1
	or (select keepDial from ccTipoCalifSubOUT where califSub_id = @califSub_id)=1)
		set @keepDial=''1''

	select @valor = @valor + @keepDial + case @cal_manual when 1 then ''10'' when 2 then ''01'' else ''00'' end

	 select @valor=substring(@valor, 1, 2) +
	  case @TipoDialingMode when 6 then ''1'' else substring(@valor, 3, 1) end + substring(@valor, 4, 2) +
	  case @TipoDialingMode when 3 then ''1'' else substring(@valor, 6, 1) end + substring(@valor, 7, 2)

 return @valor
end'
		EXEC(@Sql)

		set @process = 'Alter Setting 195'
		set @Sql= 'if not exists(select setting_id from ccsettings where setting_id=195)
					begin
						insert ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values
							(195,0,''Teléfonos locales a 10 dígitos para marcación manual (México)'',1,''AGT'',''Teléfonos locales a 10 dígitos para marcación manual (México)'',''Phone length for manual call (Mexico)'',1,''^[01]$'')
					end'
		EXEC(@Sql)

		set @process = 'Alter Setting 196'
		set @Sql= 'if not exists(select setting_id from ccsettings where setting_id=196)
					begin
						insert ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values
							(196,0,''Campaña default para marcación manual'',1,''AGT'',''Campaña default para marcación manual'',''Default campaign for manual call'',1,''^\d*$'')
					end'
		EXEC(@Sql)

		set @process = 'Alter Function -- ccsp_Limpia'
		set @Sql= 'ALTER procedure [dbo].[ccsp_Limpia]
			@tel varchar(30),
			@Camp int = 0
			as
			set nocount on
			declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint, @manOpt smallint
			select @tel = dbo.limpia(@tel)
			select @lon = len(@tel)
			select @pais = valor from ccSettings with(nolock) where setting_id = 104
			select @ld = valor from ccSettings with(nolock) where setting_id = 17
			select @extLen = valor from ccsettings with(nolock) where setting_id = 108
			select @manOpt = valor from ccsettings with(nolock) where setting_id = 195
			declare @telTemp as varchar(15)

			if @extLen=@lon and @lon>1
			 begin
				select 0 as res, @tel as tel -- Extension
				return(0)
			 end

			if @pais = 1
			 begin
				if @lon = 3 and @tel = ''911''
				begin
					select 4 as res, @tel as tel
					return(0)
				end

				if @lon < 7 or @lon = 7 and len(@ld) = 2 or @lon = 8 and len(@ld) = 3 or @lon in (9, 11) or @lon > 13
				 begin
					select 1 as res, @tel as tel --Longitud invalida
					return(0)
				 end

				if @lon = 12 and left(@tel, 2) <> ''01'' or @lon = 13 and left(@tel, 3) <> ''044'' and left(@tel, 3) <> ''045'' and left(@tel, 3) <> ''001''
				 begin
					select 2 as res, @tel as tel--Digitos incorrectos
					return(0)
				 end

				if left(@tel, 3) = ''001''
				 begin
					select 0 as res, @tel as tel
					return(0)
				 end

				declare @mod varchar(5)
				select @tel = case when @lon in (7, 8) then @ld + @tel else right(@tel, 10) end
				select @mod = modalidad from series where cld + serie = left(@tel, 6) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

				if exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra))
				on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
				 begin
					select 4 as res, @tel as tel
					return(0)
				 end

				if @mod = ''CPP''
				 begin
					select 0 as res, case left(@tel, len(@ld)) when @ld then ''044'' else ''045'' end + @tel as tel
					return(0)
				 end

				if @mod in (''FIJO'', ''MPP'')
				 begin
					if @manOpt = 1 --10 digits
					begin
						set @lon = len(@tel)
						if @lon = 10 - len(@ld)
							set @tel = @ld + @tel

						if @lon = 12 and left(@tel, 2) = ''01''
							set @tel = right(@tel, 10)
						select 0 as res, @tel
					end
					else
						select 0 as res, case left(@tel, len(@ld)) when @ld then right(@tel, 10 - len(@ld)) else ''01'' + @tel end as tel
					return(0)
				 end

				--if @mod is null
				select 3 as res, @tel as tel--No encontrado
				return(0)
			 end

			if @pais = 2
			 begin
				select @telTemp = @tel
				set @tel = dbo.completa(@tel, @pais, @ld)
				if left(@tel,1)=''E'' begin
					select 1 as res, @telTemp --Longitud Invalida
					return
				end

				select @tel = dbo.fnClearPhoneArg(@tel)

				if (len(@tel) = 10 or len(@ld + @tel) = 10) and left(@tel,1) <> ''E'' begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and (telefono = @tel or telefono= @ld + @tel) and status=1)
				   begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					end else begin
						select 4 as res, @tel
						return(0)
					end
				end else begin select 2 as res, @telTemp as tel end --Digitos incorrectos
			 end

			if @pais = 3
			 begin
				select @telTemp = @tel
				if @lon < 7 or @lon = 9 or (@lon = 10 and  left(@telTemp,1) <> ''3'') or (@lon = 11 and  left(@telTemp,2) <> ''03'') begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				end
				select @tel = dbo.Completa_ListaNegra(@tel)

				if (len(@tel) = 8 or len(@tel) = 10) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 4
			 begin
				exec ccsp_LimpiaUsa @tel, @Camp
				return(0)
			 end

			if @pais = 5
			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)

				if len(@tel) in(8,9) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 6
			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)


				if len(@tel) = 10 and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 7

			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)

				if (len(@tel) = 9 or len(@tel) = 10) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin

						select @tel = dbo.verifica(@tel)
						if left(@tel,1)=''E'' begin
							select 3 as res, @telTemp -- No existe el telefono
						end
						else begin
							select 0 as res, @telTemp  -- Todo Bien
						end
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel --lista negra
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end


			if @pais = 8
			 begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)

				if left(@tel,1)=''E'' begin
					select 1 as res, @telTemp --Longitud Invalida
					return (0)
				end

				if (len(@tel) = 9 or len(@tel) = 10 or len(@tel) = 11 )
				begin
					if not exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra)) on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					end
					else
					begin
						select 4 as res, @tel
						return(0)
					end
				end
			 end

			if @pais = 9 --Australia
			 begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)

				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			 end

			if @pais = 10 -- Brasil
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				set @lon = len(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 11 -- Guatemala
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 12 -- Costa Rica
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 13 -- Salvador
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 14 -- Spain
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end'
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_RIACampsManualCall'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]
@UserID int,
@onChat int = 0
AS
set nocount on

if (@onChat = 0)
begin
	declare @mod smallint
	select @mod = valor from ccsettings where setting_id = 196

	select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [default]
	from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
	where (ca.user_id = @UserID and cam_modoManual = 1) or ca.cam_id=@mod
	order by cam_descripcion
end
else
	select distinct c.cam_id, c.cam_descripcion
	from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
	where ca.user_id = @UserID and manualCallOnChat = 1
	order by cam_descripcion

set nocount off'
		EXEC(@Sql)


		set @process = 'Alter SP  -- ccsptelefonosTransferencia'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsptelefonosTransferencia]
@userID INT
as
set nocount on

BEGIN
declare @value bit
declare @IDArea int
set @value = 0
set @IDArea =1
select @value = case when valor=''1'' then 1 else 0 end from ccSettings where setting_id = 191

select @IDArea =IDArea from ccUsers where User_id =@userID
if @value = 1
	begin
		select numtra_id id, nombre name, tel number, isnull(IDArea,@IDArea) from telefonosTransferencia where idarea= @IDArea or IDArea is null order by nombre
	end
	else
	begin
		select numtra_id id, isnull(cast(IDArea as varchar(20) )+'' - ''+  nombre , nombre ), tel number, isnull(IDArea,@IDArea) from telefonosTransferencia  order by nombre
	end
END'
		EXEC(@Sql)


		set @process = 'Alter SP  -- ccsp_RIACAT_PhoneConfig'
		set @Sql= 'ALTER proc [dbo].[ccsp_RIACAT_PhoneConfig]
@Type tinyint, -- 1:Show #conf | 2:Add #conf | 3:Upd #conf | 4:Del #conf | 5:Add #tran | 6:Upd #tran | 7:Del #tran | 8: Show #tran
@CT_id SmallInt=0,
@Nombre varchar(50)='''',
@Telefono varchar(50)='''',
@IDArea smallint = 0 --parametro IDarea
as
set nocount on

BEGIN
declare @value bit

select @value = case when valor =''1'' then 1 else 0 end from ccSettings where setting_id = 191

if @Type=1
 begin
	select numcon_id id, nombre name, tel number from telefonosConferencia order by nombre
	return(0)
 end

if @Type=2
 begin
	IF exists (select numcon_id from telefonosConferencia where nombre=@Nombre)
	 begin
		select -3 -- El nombre ya esta asignado
		return(0)
	 end

	IF exists (select numcon_id from telefonosConferencia where tel=@Telefono)
	 begin
		select -4 -- El telefono ya esta asignado
		return(0)
	 end

	insert into telefonosConferencia (nombre, tel) select @Nombre, @Telefono
	select SCOPE_IDENTITY() numcon_id
	return(0)
 end

if @Type=3
 begin
 	IF exists (select numcon_id from telefonosConferencia where nombre=@Nombre and numcon_id<>@CT_id)
	 begin
		select -5 -- El nombre ya esta asignado
		return(0)
	 end

 	IF exists (select numcon_id from telefonosConferencia where tel=@Telefono and numcon_id<>@CT_id)
	 begin
		select -6 -- El telefono ya esta asignado
		return(0)
	 end

	update telefonosConferencia set nombre=@Nombre, tel=@Telefono where numcon_id=@CT_id
	return(0)
 end

if @Type=4
 begin
	delete telefonosConferencia where numcon_id=@CT_id
	return(0)
 end

if @Type=5
 begin
	IF exists (select numtra_id from telefonosTransferencia where nombre=@Nombre and IDArea=@IDArea)
	 begin
		select -3 -- El nombre ya esta asignado
		return(0)
	 end

	 	IF exists (select numtra_id from telefonosTransferencia where tel=@Telefono and IDArea=@IDArea)
	 begin
		select -4 -- El telefono ya esta asignado
		return(0)
	 end

	insert into telefonosTransferencia (nombre, tel, IDArea) select @Nombre, @Telefono,@IDArea --se agrega IDArea
	select SCOPE_IDENTITY() numtra_id
	return(0)
 end

if @Type=6
 begin
 	IF exists (select numtra_id from telefonosTransferencia where nombre=@Nombre and numtra_id<>@CT_id and IDArea=@IDArea )
	 begin
		select -5 -- El nombre ya esta asignado
		return(0)
	 end

 	IF exists (select numtra_id from telefonosTransferencia where tel=@Telefono and numtra_id<>@CT_id and IDArea=@IDArea )
	 begin
		select -6 -- El telefono ya esta asignado
		return(0)
	 end

	update telefonosTransferencia set nombre=@Nombre, tel=@Telefono where numtra_id=@CT_id and IDArea=@IDArea
	return(0)
 end

if @Type=7
 begin
	delete telefonosTransferencia where numtra_id=@CT_id
	return(0)
 end

if @Type=8
 begin
	if @value = 1
	begin
		select numtra_id id, nombre name, tel number, isnull(IDArea,@IDArea) from telefonosTransferencia where idarea= @IDArea or IDArea is null order by nombre
	end
	else
	begin
		select numtra_id id, isnull(cast(IDArea as varchar(20) )+'' - ''+  nombre, nombre) name, tel number, isnull(IDArea,@IDArea) from telefonosTransferencia  order by nombre
	end
	return(0)
 end

return(0)
set nocount off
end'

		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_BaseXmngr --CW-876'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@id bigint = 0,
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

    print(@sql)
    exec(@sql)
  end
end
else if @action in (2,7) begin--actualiza los nodos insertados en BX
  if @action = 2 set @status =0
  else if @action = 7 set @status = 2
  if @option = 1
    update ccChatsNode with(rowlock) set [status] = @status + 1 , dateOut = getDate() where chatId = @id and [status] = @status
  else if @option = 3
    update ccEmailNode with(rowlock) set [status] = @status + 1 , dateOut = getDate() where emailId = @id and [status] = @status
  else if @option = 4
    update ccTwitterNode with(rowlock) set [status] = @status + 1 , dateOut = getDate() where conversationTwitterId = @id and [status] = @status
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

		set @process = 'Alter SP  -- ccsp_CleanNodeBaseX  CW-880'    
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_CleanNodeBaseX]
@option int
AS
BEGIN

declare @dateStart datetime ,@dateEnd datetime

declare @count int , @setting int
declare @nodos table (fecha varchar(100))
declare @res int
set @res = -1
	select  @setting  = valor from ccSettings where setting_id = 188
	if @setting is null set @setting = 40000

	if @option = 1  select @count = COUNT (chatId) from ccChatsNode with(nolock)
	else if @option = 3  select @count = COUNT (emailId) from ccEmailNode with(nolock)
	else if @option = 4  select @count = COUNT (conversationTwitterId) from ccTwitterNode with(nolock)

	if @count >=  @setting begin

	begin try
			begin tran elimina

			if @option = 1 begin

				insert into ccChatsNodeHistory
				select chatId,node,dateIn,dateOut,status from ccChatsNode where status in(1,3)

				insert into @nodos
				SELECT node.value(''(/R01/@CDATE)[1]'',''varchar(100)'') as node FROM ccChatsNode where status in(1,3) order by node


				if(select count(*) from @nodos where fecha is null) > 0
				begin
					delete @nodos
					insert into @nodos
					SELECT node.value(''(/R01/@C09)[1]'',''varchar(100)'') as node FROM ccChatsNode where status in(1,3) order by node
				end


				select @dateStart = convert(datetime,MIN(fecha)) ,@dateEnd = convert(datetime, MAX(fecha)) from @nodos

				update ccBaseXDB set isfull = 1, dateStart=@dateStart,dateEnd=@dateEnd where serviceId = @option and isfull = 0 and dateEnd is null

				delete from ccChatsNode where status in(1,3)
				set @res = 1

			end
			else if @option = 3  begin
				insert into ccEmailNodeHistory
				select emailId,node,dateIn,dateOut,status from ccEmailNode where status in(1,3)

				insert into @nodos
				SELECT node.value(''(/R03/@CDATE)[1]'',''varchar(100)'') as node FROM ccEmailNode where status in(1,3) order by node


				if(select count(*) from @nodos where fecha is null) > 0
				begin
					delete @nodos
					insert into @nodos
					SELECT node.value(''(/R03/@C02)[1]'',''varchar(100)'') as node FROM ccEmailNode where status in(1,3) order by node
				end


				select @dateStart = convert(datetime,MIN(fecha)) ,@dateEnd = convert(datetime, MAX(fecha)) from @nodos

				update ccBaseXDB set isfull = 1,dateStart=@dateStart,dateEnd=@dateEnd  where serviceId = @option and isfull = 0 and dateEnd is null

				delete from ccEmailNode where status in(1,3)
				set @res = 1
			end
			else if @option = 4  begin
				insert into ccTwitterNodeHistory
				select conversationTwitterId,node,dateIn,dateOut,status from ccTwitterNode where status in(1,3)

				insert into @nodos
				SELECT node.value(''(/R04/@CDATE)[1]'',''varchar(100)'') as node FROM ccTwitterNode where status in(1,3) order by node


				if(select count(*) from @nodos where fecha is null) > 0
				begin
					delete @nodos
					insert into @nodos
					SELECT node.value(''(/R04/@C02)[1]'',''varchar(100)'') as node FROM ccTwitterNode where status in(1,3) order by node
				end


				select @dateStart = convert(datetime,MIN(fecha)) ,@dateEnd = convert(datetime, MAX(fecha)) from @nodos

				update ccBaseXDB set isfull = 1, dateStart=@dateStart,dateEnd=@dateEnd  where serviceId = @option and isfull = 0 and dateEnd is null

				delete from ccTwitterNode where status in(1,3)
				set @res = 1
			end

			commit tran elimina
		end try
		begin catch
			rollback  transaction elimina
			set @res = 0
		end catch
	end
	select @res,@dateStart,@dateEnd
END'

		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_CreateNodeMultimedia'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_CreateNodeMultimedia]
@conversationId bigint,
@xml xml OUTPUT,
@supervisor varchar(255)='''',
@template varchar (255)='''',
@ScoreTemplate int=0,
@type int =1--1 EMAIL , 2 Twitter
AS
BEGIN
declare @info varchar(255)
declare @infoEscape varchar(max)
declare @charEscape varchar(255),@charReplace varchar(max)
set @charEscape=''"|''''''''|<|>|&''
set @charReplace=''&quot;|&apos;|&lt;|&gt;|&amp;''

--SET @conversationId=16
declare @existAttached bit,@numInteracion smallint
if @type=0 begin--CHAT

	select @xml = convert(xml,''<R01 CDATE="''+rtrim(ltrim(convert(varchar(23), isNull(chatDate,requestDate), 126))) +
	''" C01="''+convert(varchar(max),chatId) +
	''" C02="''+convert(varchar(max),isnull(ccinbound.descripcion,'''')) +
	''" C03="''+convert(varchar(max),domain) +
	''" C04="''+convert(varchar(max), Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno ) +
	''" C05="''+convert(varchar(max),tchatting) +
	''" C06="''+convert(varchar(max),isnull(cctipocalif.[Description],''N/A'')) +
	''" C07="''+convert(varchar(max),isnull(cctipocalifsub.califSubdesc,''N/A'')) +
	''" C08="''+convert(varchar(max),clientname) +
	''" C09="''+rtrim(ltrim(convert(varchar(23), chatDate, 126))) +
	''" C10="''+convert(varchar(max),isnull(@supervisor,'''') ) +
	''" C11="''+convert(varchar(max),isnull(@template,'''') )  +
	''" C12="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +
	''" C13="''+convert(varchar(max),isnull(ccusers.[Login],'''')) + ''"/>'')
	from ccRIAChats
	left outer join ccinbound on ccinbound.inbound_id = ccRIAChats.inboundid
	left outer join ccusers on ccusers.user_id = ccRIAChats.userid
	left outer join cctipocalif on cctipocalif.calif_id = ccRIAChats.disposition
	left outer join cctipocalifsub on cctipocalifsub.califsub_id = ccRIAChats.subdisposition and ccRIAChats.subdisposition <> 0
	where chatId = @conversationId and chatStatus = 4 and requestDate is not null and chatDate is not null

end
else if @type=1 begin--EMAIL
	SELECT @existAttached = case when count(*)>0 then 1 else 0 end
	from attached where messageId in (select messageId from message where conversationId=@conversationId)
	select @numInteracion = count(*) from message where conversationId=@conversationId
	--Replaza los caracteres por los comunes
	select @info=info from conversation where conversationId=@conversationId
	select @info=replace(@info,A.Value,B.Value) from dbo.fn_RIASplitDelimited(@charEscape,''|'') A
	inner join dbo.fn_RIASplitDelimited(@charReplace,''|'') B on A.Id=B.Id


	select @xml = convert(xml,''<R03 CDATE="''+ rtrim(ltrim(convert(varchar(23), min(b.date), 126))) +
	''" C01="''+ convert(varchar(max),a.conversationId) +
	''" C02="''+ rtrim(ltrim(convert(varchar(23), min(b.date), 126))) +
	''" C03="''+ convert(varchar(max),max(c.descripcion)) +
	''" C04="''+ convert(varchar,max(isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno,''''))) +
	''" C05="''+ convert(varchar,max(isnull(cctipocalif.[Description],''N/A''))) +
	''" C06="''+ convert(varchar,max(replace(replace(a.mailClient,''<'','' ''),''>'','' ''))) +
	''" C07="''+ convert(varchar(max),sum(b.tRetention+b.tResponse+b.tWrapup)) +
	''" C08="''+ convert(varchar(max),min(isnull(@info,''''))) +
	''" C09="''+ convert(varchar(max),max(b.messageStatusid) ) +''" C10="''+  convert(varchar(max), isnull(@numInteracion,0)) +
	''" C11="''+ convert(varchar(max),@existAttached) +''" C12="''+ convert(varchar(max),isnull(@supervisor,'''') ) +
	''" C13="''+ convert(varchar(max),isnull(@template,'''') )  +''" C14="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +
	''" C15="''+ convert(varchar,max(isnull(cctipocalifsub.califSubdesc,''N/A''))) +
	''" C16="''+ convert(varchar(max),isnull(max(d.[Login]),'''')) + ''"/>'')
	from conversation a
	inner join message b on a.conversationid=b.conversationid
	left outer join ccinbound c on c.inbound_id = a.inboundid
	left outer join ccusers d on d.user_id = b.userid
	left outer join relationmessageDisposition e on e.messageId=b.messageId
	left outer join cctipocalif on cctipocalif.calif_id = e.dispositionId
	left outer join cctipocalifsub on cctipocalifsub.califsub_id = e.subdispositionId and e.subdispositionId <> 0
	where a.conversationId=@conversationId
	group by a.conversationId,a.inboundid

end
else if @type=2 begin--Twitter
	select @numInteracion = sum(ninteration) from messageOutTwitter where conversationTwitterId=@conversationId

	select @xml = convert(xml,''<R04 CDATE="''+rtrim(ltrim(convert(varchar(23), min(b.date), 126))) +
	''" C01="''+convert(varchar(max),a.conversationTwitterId) +
	''" C02="''+rtrim(ltrim(convert(varchar(23), min(b.date), 126))) +
	''" C03="''+convert(varchar(max),max(c.descripcion)) +
	''" C04="''+ convert(varchar,max(isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno,''''))) +
	''" C05="''+convert(varchar,max(isnull(cctipocalif.[Description],''N/A''))) +
	''" C06="''+ max(a.screenNameClient) +
	''" C07="''+convert(varchar(max),sum(b.tRetention+b.tResponse+b.tWrapup)) +
	''" C08="''+ max(a.screenNameInbound) +
	''" C09="''+convert(varchar(max),max(b.messageStatusid) ) +
	''" C10="''+  convert(varchar(max), isnull(@numInteracion,0)) +
	''" C11="''+ convert(varchar(max),isnull(@supervisor,'''') ) +
	''" C12="''+convert(varchar(max),isnull(@template,''''))  +
	''" C13="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +
	''" C14="''+ convert(varchar,max(isnull(cctipocalifsub.califSubdesc,''N/A''))) +
	''" C15="''+convert(varchar(max),isnull(max(d.[Login]),'''')) + ''"/>'')
	from conversationTwitter a
	inner join messageOutTwitter b on a.conversationTwitterId=b.conversationTwitterId
	left outer join ccinbound c on c.inbound_id = a.inboundid
	left outer join ccusers d on d.user_id = b.userid
	left outer join relationmessageDisposition e on e.messageId=b.messageOutTwitterId
	left outer join cctipocalif on cctipocalif.calif_id = e.dispositionId
	left outer join cctipocalifsub on cctipocalifsub.califsub_id = e.subdispositionId and e.subdispositionId <> 0
	where a.conversationTwitterId=@conversationId
	group by a.conversationTwitterId,a.inboundid
end

--print convert(nvarchar(1000),@xml)
--select @xml
END'


		EXEC(@Sql)
		
		set @process = 'Alter SP  -- ccsp_RIAUpdateEspecConfig CW-871'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig]
@inbound_id smallint,
@descripcion varchar(50) = null,
@Status tinyint = null,
@tNotas int = null,
@tMaxWaitCall int = null,
@nMaxQue int = null,
@tel_maxwait varchar(15) = null,
@tel_MaxQueue varchar(15) = null,
@tel_outservice varchar(15) = null,
@tel_noct varchar(15) = null,
@ShowCalifWnd bit = null,
@StartTimerOnHangUp bit = null,
@editableCallKey bit = null,
@queuePosition bit = null,
@tMaxQueueCallBack smallint = null,
@stopRecording bit = null,
@dialPrefixOverflow varchar(10) = null,
@OpriorityT smallint= null,
@callerIdDesc varchar(15) = null,
@chat tinyint = null,
@inactiveChatTime smallint = null,
@maxChats tinyint = null,
@chatDomain varchar(max) = null,
@chatQueue smallint = null,
@chatTime smallint = null,
@dRestrictPlay bit = null,
@callBackSurveyAgent bit = null,
@callBackSurveyClient bit = null,
@agts_notavailable varchar(15) = null,
@editableDtmf bit = null
as
set nocount on
UPDATE ccInbound SET
descripcion = isnull(@descripcion,descripcion),
Status = isnull(@status,status),
tNotas = isnull(@tNotas,tNotas),
tMaxWaitCall = isnull(@tMaxWaitCall,tMaxWaitCall),
nMaxQue = isnull(@nMaxQue,nMaxQue),
tel_maxwait = isnull(@tel_maxwait,tel_maxwait),
tel_MaxQueue = isnull(@tel_MaxQueue,tel_MaxQueue),
tel_outservice = isnull(@tel_outservice,tel_outservice),
tel_noct = isnull(@tel_noct,tel_noct),
bnocturno = case when isnull(@tel_noct,''0'')=''0'' or @tel_noct='''' then ''0'' else ''1'' end,
StartTimerOnHangUp = isnull(@StartTimerOnHangUp,StartTimerOnHangUp),
editableCallKey = isnull(@editableCallKey,editableCallKey),
queuePosition = isnull(@queuePosition,queuePosition),
tMaxQueueCallBack = isnull(@tMaxQueueCallBack,tMaxQueueCallBack),
stopRecording = isnull(@stopRecording, stopRecording),
dialPrefixOverflow = isnull(@dialPrefixOverflow, dialPrefixOverflow),
OpriorityT = isnull(@OpriorityT, OpriorityT),
callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
chat = isnull(@chat,chat),
inactiveChatTime = isnull(@inactiveChatTime,inactiveChatTime),
maxChats = isnull(@maxChats,maxChats),
chatQueueOverflow = isnull(@chatQueue,isnull(chatQueueOverflow,15)),
chatTimeOverflow = isnull(@chatTime,isnull(chatTimeOverflow,300)),
startStopRecording = isnull(@dRestrictPlay,startStopRecording),
callBackSurveyAgent = isnull(@callBackSurveyAgent,callBackSurveyAgent),
callBackSurveyClient = isnull(@callBackSurveyClient,callBackSurveyClient),
agts_notavailable = isnull(@agts_notavailable,agts_notavailable),
editableDtmf = isnull(@editableDtmf,editableDtmf)
where inbound_id = @inbound_id


if not exists( select inbound_id from ccinbound where inbound_id <> @inbound_id and chatDomain = @chatDomain and chatDomain <> '''') begin
	if @chatDomain is not null begin
		update ccinbound set chatDomain = @chatDomain where inbound_id = @inbound_id
	end
end
else begin
	update ccinbound set chatDomain = '''' where inbound_id = @inbound_id
	raiserror(''Domain already in another ACD Group'',15,4)
end


if @ShowCalifWnd = 1
begin
If exists(select cam_id from ccCalifCamp where cam_id = @inbound_id and tipo = 0)
	begin
	UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd,ShowCalifWnd)
	where inbound_id = @inbound_id
	select 1
	return(0)
	end

select 0
return(0)
end

else
UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd,ShowCalifWnd)
where inbound_id = @inbound_id
return(0)
set nocount off'


		EXEC(@Sql)
		
		set @process = 'Alter SP  -- ccsp_RIAManageAreas CW-871'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAManageAreas]
@option tinyint,
@IDArea smallint = 0,
@InsertUserId smallint =null,
@DeleteUserId varchar(255)=null,
@InsertCamId smallint=null,
@DeleteCamId smallint=null,
@InsertACDGroupId smallint=null,
@DeleteACDGroupId smallint=null
as
set nocount on

if @option = 1 -- Insert User Area
	begin
	if not exists(select IDArea from ccUsers where IDArea = @IDArea AND User_id = @InsertUserId)
		begin
		Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @InsertUserId
		return(0)
		end	
					 
	select 1
	return(0)
	end

if @option = 3 -- Insert camp area
	begin
	if not exists(select IDArea from ccCamps where IDArea = @IDArea and cam_id = @InsertCamId)
		begin
		Update ccCamps set IDArea = case @IDArea when 0 then null else @IDArea end
		where cam_id = @InsertCamId
		return(0)
		end

	select 1
	return(0)
	end

if @option = 4 begin-- Delete camp area
	

	--Si existe una campaña relacionada con el grupo
	if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
		select -4
		return(0)	 
	end

	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId
				 
	delete from ccCampsAgente where cam_id = @DeleteCamId
	--delete from ccoDialerCamp where cam_id = @DeleteCamId
	delete from ccoWorkingTable where cam_id = @DeleteCamId

	insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1	

	delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
	delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	
	delete from ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @DeleteCamId)
	

	Update ccCamps set IDArea= null where cam_id=@DeleteCamId--, cam_activo = 0 
	return(0)
	end

if @option = 5 -- Insert ACDGroup area
	begin
	if not exists(select IDArea from ccInbound where IDArea = @IDArea and Inbound_Id = @InsertACDGroupId)
		begin
		Update ccInbound set IDArea = @IDArea, status = 1 where Inbound_id = @InsertACDGroupId
		return(0)
		end

	select 1
	return(0)
	end

if @option = 6 -- Delete ACDGroup area
	begin
		insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

	delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
	delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId

	insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId and A.tipo = 0

	delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
	delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
	delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

	Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId
	select 1
	return(0)
	end

if @option in (2, 9, 10, 11)
	begin
		declare @Type tinyint
	select @Type = TipoUser_id from ccUsers where User_id = @DeleteUserId
					
	if @option in (2, 10, 11) -- Delete User area
		begin
		if @Type = 1 -- Agente
			begin

			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
			insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

			delete from ccCampsAgente where user_id = @DeleteUserId
			delete from ccInboundAgentes where user_id = @DeleteUserId

			if @option = 11
				begin
					select IDWG, User_id into #WorkGroupUsers from ccRIAWorkGroupUsers where user_id = @DeleteUserId

					delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
									
					select * from #WorkGroupUsers
					drop table #WorkGroupUsers
									
					return(0)
				end
			end

		else if @Type in (2, 6) -- Supervisor
		begin
			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
			delete from ccSupervisorCam where user_id = @DeleteUserId
		end

		delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
						
		if @option=2
			begin
			update ccPosicion set user_id = 0 where user_id = @DeleteUserId
			update ccUsers set IDArea = null where user_id = @DeleteUserId	
			end
		return(0)
	end

	declare @UserWG varchar(100)
	-- @option = 9 -- Delete User area and get his workgroups

	select @UserWG = IDWG from ccRIAWorkGroupUsers where user_id = @DeleteUserId

	if @Type = 1 -- Agente
		begin
		insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
		insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

		delete from ccCampsAgente where user_id = @DeleteUserId
		delete from ccInboundAgentes where user_id = @DeleteUserId
		end

	if @Type in (2, 6) -- Supervisor
		begin
		insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId

		delete from ccSupervisorCam where user_id = @DeleteUserId
		delete from ccMenuUser where id_User = @DeleteUserId
		end

	delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
	update ccPosicion set user_id = 0 where user_id = @DeleteUserId
					
	if @option <> 11
		update ccUsers set IDArea = null where user_id = @DeleteUserId
					
	select @UserWG, @Type
	return(0)
	end

declare @AllWG varchar(400), @CurrentWG varchar(400), @AreaDescripcion varchar(40)

if @option = 7 begin-- Delete camp area
	
	if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
	
		---Borra las calificacion con reprogramacion
		delete ccCalifCamp from ccInbound A 
		inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
		inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
		where A.cam_id=@DeleteCamId
		---Borra las subcalificacion con reprogramacion
		delete rel from ccInbound A 
		inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
		inner join ccTipoCalif C on B.calif_id=C.calif_id 
		inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
		inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where A.cam_id=@DeleteCamId and sb.canReprogram=1
	
		update ccInbound set cam_id = null where cam_id=@DeleteCamId				
		 
	end

	select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId

	delete from ccCampsAgente where cam_id = @DeleteCamId
	delete from ccoWorkingTable where cam_id = @DeleteCamId or callout_id 
		in (select callout_id from ccoCallsOutSource where cam_id = @DeleteCamId)

	insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1

	delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
	delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	

	select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

	select @AreaDescripcion = area.AreaName
	from ccCamps as camp with(nolock)inner join ccRIACat_Areas as area 
		with(nolock) on camp.IDArea = area.IDArea
	where camp.cam_id = @DeleteCamId
	Update ccCamps set IDArea = null where cam_id = @DeleteCamId

	If @CurrentWG is null
		set @CurrentWG = 0

	If @AllWG is null
		set @AllWG = 0

	select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
	return(0)
	end

if @option = 8 --Delete ACDGroup area
	begin
	if (select cam_id from ccInbound where Inbound_id = @DeleteACDGroupId) is not null
	begin
		update ccInbound set cam_id = null where Inbound_id = @DeleteACDGroupId
	end

	select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

	insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

	delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
	delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId

	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId 

	delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
	delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
	delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

	select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

	select @AreaDescripcion = area.AreaName
	from ccInbound as ACD with(nolock) inner join ccRIACat_Areas as area 
		with(nolock) on ACD.IDArea = area.IDArea
	where ACD.Inbound_id = @DeleteACDGroupId
	Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId

	If @CurrentWG is null
		set @CurrentWG = 0

	If @AllWG is null
		set @AllWG = 0

	select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
	
	if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId=@DeleteACDGroupId)--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
	begin
		DECLARE @TwitterResult table(--Se declaro por que el SP ccsp_MailAdminAccount regresa una consulta.  
		result int,  
		operation varchar(30));
		insert @TwitterResult
		EXEC [dbo].[ccsp_MailAdminAccount] @action = 22,@meanContactTypeId = 2, @inboundId = @DeleteACDGroupId--se ejecutara el SP para desasociar la cuenta de mail
	end
	if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId=@DeleteACDGroupId)--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
	begin
		update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId = @DeleteACDGroupId and meanContactTypeId=1
	end
	update ccinbound set chatDomain = '''' where inbound_id = @DeleteACDGroupId--para desasociar el dominio del chat
	return(0)
	end

return(0)
set nocount off'
		
		EXEC(@Sql)
		
		set @process = 'Alter SP  -- ccsp_TwitterSave CW-902'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_TwitterSave]
 @action int,
 @conversationId int=0,
 @messageOutTwitterId bigint=null,
 @userId int=0,
 @isLogout bit=0,
 @messageId int =null,
 @messageStatusId int=null,
 @inboundId smallint=null,
 @twitId varchar(255)=null,
 @dispositionId smallint=0,
 @subDispositionId smallint=0,
 @timeAtt int = 0,
 @tWrapUp int =0,
 @tRetention int = 0,

 ---Finder
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0
AS
BEGIN

declare @meanContactTypeId smallint
declare @isEndConversation bit
declare @xmlnode xml

set @meanContactTypeId = 2 --Twitter


 if @action = 1 BEGIN  -- desasignar
	if @messageOutTwitterId = 0 begin
		insert into [messageUnAssingedTwit](messageOutTwitterId,userId,[time],isLogout)
		select messageOutTwitterId,userId,datediff(ss,tQueue,getdate()) as [time],1 from [messageOutTwitter]  where userId=@userId and messageStatusId in (2,3)

		update [messageOutTwitter] set twitId='''',tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0 where userId=@userId and messageStatusId in (2,3)
	end
	else begin
		insert into [messageUnAssingedTwit](messageOutTwitterId,userId,[time],isLogout)
		select messageOutTwitterId,userId,datediff(ss,tQueue,getdate()) as [time],0 as isLogout from [messageOutTwitter] where userId=@userId and messageOutTwitterId=@messageOutTwitterId and messageStatusId in (2,3)

		update [messageOutTwitter] set twitId='''',tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0 where userId=@userId and messageOutTwitterId=@messageOutTwitterId and messageStatusId in (2,3)
	end
END
else if @action = 2 begin --Coloca el valor del TwitId
	update [messageOutTwitter] set twitId=@twitId where messageOutTwitterId=@messageOutTwitterId
end
else if @action = 5 BEGIN --Twitter por contestar
	--Status DOWNLOAD,Assigned,READ,UnaSSIGNED
	select A.conversationTwitterId,B.userId,A.screenNameClient,A.screenNameInbound,B.messageStatusId,B.messageOutTwitterId as messageId
		from conversationTwitter A
		inner join [messageoutTwitter] B on A.conversationTwitterId = B.conversationTwitterId
		where A.inboundId = @inboundId and B.messageStatusId in(1,2,3,4) and meanContactTypeId = @meanContactTypeId
		and b.messageOutTwitterId=(select max(bb.messageOutTwitterId)--esta subconsulta permite conocer el maximo messageOutTwitterId de la conversacion de la consulta principal 
				from messageOutTwitter bb
				inner join conversationTwitter aa on aa.conversationTwitterId = bb.conversationTwitterId
				where bb.conversationTwitterId=aa.conversationTwitterId
				and bb.conversationTwitterId=b.conversationTwitterid 
				and aa.inboundId=@inboundId
				GROUP BY bb.conversationTwitterId)
		GROUP BY A.conversationTwitterId,A.inboundId,A.screenNameClient,A.screenNameInbound,B.messageStatusId,B.userId,b.messageOutTwitterId
END
else if @action = 6 BEGIN --update Time Attention, Retencion
	select @messageId=max(messageOutTwitterId) from messageOutTwitter with(nolock) where conversationTwitterId=@conversationId
	update messageOutTwitter set tResponse=@timeAtt,tRetention=@tRetention,isSender=1,messageStatusId=@messageStatusId where messageOutTwitterId=@messageId
END
else if @action = 7 BEGIN --Cambia el status del mensaje
	select @messageId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId

	--Status Read
	if @messageStatusId=3  update [messageOutTwitter] set tWait=DATEDIFF(ss,tQueue, getdate()) where messageOutTwitterId=@messageId
	--Status Send
	if @messageStatusId=6  begin
		select @isEndConversation=isFinished from conversationTwitter where conversationTwitterId=@conversationId

		if @isEndConversation = 1 set @messageStatusId=11--Close conversation by Agent
		update [messageOutTwitter] set tSend=getdate() where messageOutTwitterId=@messageId

	end
	update [messageOutTwitter] set messageStatusId=@messageStatusId where messageOutTwitterId=@messageId

	--Answered,Send,CLose Conversation system or agent
	if @messageStatusId in (5,6,10,11)  begin
		exec ccsp_CreateNodeMultimedia @type=2, @conversationId=@conversationId, @xml = @xmlnode OUTPUT
		if not exists(select * from [ccTwitterNode] where [conversationTwitterId]=@conversationId) begin
			insert into [ccTwitterNode]([conversationTwitterId],[node],dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
		end
		else begin
			update [ccTwitterNode] set node=@xmlnode,status=2 where [conversationTwitterId]=@conversationId
		end
	end

END
else if @action = 10 begin --Carga las conversaciones pendientes
	if @conversationId = 0 begin
		select A.conversationTwitterId,max(B.messageOutTwitterId) as messageId,B.userId,A.inboundId,max(C.twitId) as twitId
			from conversationTwitter A
			inner join messageOutTwitter B on A.conversationTwitterId = B.conversationTwitterId
			inner join messageInTwitter C on C.conversationTwitterId=B.conversationTwitterId
			where A.meanContactTypeId = @meanContactTypeId
			and B.messageStatusId in(5,7,8,9) and isSender=1 and A.inboundId=@inboundId
			GROUP BY A.conversationTwitterId,A.inboundId,B.userId
	end
	else begin
	select A.conversationTwitterId,max(B.messageOutTwitterId) as messageId,B.userId,A.inboundId,max(C.twitId) as twitId
			from conversationTwitter A
			inner join messageOutTwitter B on A.conversationTwitterId = B.conversationTwitterId
			inner join messageInTwitter C on C.conversationTwitterId=B.conversationTwitterId
			where A.meanContactTypeId = @meanContactTypeId
			and A.conversationTwitterId = @conversationId
			GROUP BY A.conversationTwitterId,A.inboundId,B.userId
	end
end
else if @action = 11 BEGIN --Califica el mensaje y pone el tiempo Notas
	if @subDispositionId <> 0 begin
		select @isEndConversation=isnull(EndConversation,0) from ccTipoCalifSub where califSub_id=@subDispositionId
	end
	else begin
		select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@dispositionId
	end
	if not exists(select * from relationMessageDispositionTwit where messageOutTwitterId=@messageId) begin
		insert into relationMessageDispositionTwit(messageOutTwitterId,dispositionId,subDispositionId) values(@messageId,@dispositionId,@subDispositionId)
	end
	else begin
		update relationMessageDispositionTwit set dispositionId=@dispositionId,subDispositionId=@subDispositionId where messageOutTwitterId=@messageId
	end
	update [messageOutTwitter] set tWrapUp=@tWrapUp where messageOutTwitterId=@messageId
	if @isEndConversation = 1 begin
		select @conversationId=conversationTwitterId from [messageOutTwitter]where messageOutTwitterId=@messageId
		update conversationTwitter set isFinished=@isEndConversation where conversationTwitterId=@conversationId
	end
END
else if @action = 12 BEGIN  --Tiempo de cola
	select @messageId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId
	update [messageOutTwitter] set tQueue=getdate(),userId=@userId where messageOutTwitterId=@messageId
END
else if @action = 13 BEGIN  --Limpia las conversaciones quedaron abiertas por cerrar la aplicacion
	update [messageoutTwitter] set @messageStatusId=1,twitId='''',tQueue=null,userId=0,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0  where messageStatusId in(2,3)
END
else if @action = 14 begin --Asignar una evluacion
	exec ccsp_CreateNodeMultimedia @type=2, @conversationId=@conversationId, @xml = @xmlnode OUTPUT,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate
	if not exists(select * from ccEmailNode where emailId=@conversationId) begin
		insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
	end
	else begin
		update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
	end
end

END'
		
		EXEC(@Sql)
		
		set @process = 'Alter SP  -- ccspADMaddConversationTweet CW-902'
		set @Sql='ALTER PROCEDURE [dbo].[ccspADMaddConversationTweet]
@action int,
@inboundId int = null,
@clientId varchar(255)= null,
@isFinished bit = 0,
@screenNameClient varchar(100) = null,
@screenNameInbound varchar(100) = null,
@meanContactTypeId smallint = null,
@twitId varchar(255) = null,
@conversationId bigint = null,
@date datetime=null,
@replayId varchar(255)=null,
@tipoTwitId tinyint=1,
@messageId bigint = null,
@dispositionId smallint=0,
@subDispositionId smallint=0,
@tWrapUp int =0

as
set nocount on

declare @ninteration int ,@messageOutTwitterId bigint
declare @userId int
declare @isEndConversation bit


if @action = 1 begin --Revisa que exista la conversacion
	select @conversationId =  isnull(max(conversationTwitterId),0) from conversationTwitter where isFinished = 0 and meanContactTypeId = 2 and ClientId = @clientId and inboundId=@inboundId
	if @conversationId = 0
		select 0,''New Conversation''
	else begin
		declare @closeConversation tinyint
		declare @tRsponse datetime
		select @tRsponse = isnull(max(tSend),getdate()) from messageOutTwitter where conversationTwitterId = @conversationId
		select @closeConversation = closeConversationTime from contactMeanIn where inboundId=@inboundId
		 if datediff(dd,getdate(),@tRsponse ) > @closeConversation
			select 0,''New Conversation Close System''
		else
			select @conversationId
	end
    return 0
end
else if @action = 2 begin --Nueva conversacion y mensaje entrada y salida
    --agregar tabla de messagetwit fecha de descarga
	if @replayId is null or @replayId=''''
		set @replayId= ''0''
    insert into conversationTwitter (inboundId,ClientId,isFinished,screenNameClient,screenNameInbound,meanContactTypeId,replayId)
    values(@inboundId,@clientId,@isFinished,@screenNameClient,@screenNameInbound,@meanContactTypeId,@replayId)
    set  @conversationId  = SCOPE_IDENTITY()
	insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
	set @messageId=SCOPE_IDENTITY()
	insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
	values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)
    select 0 as userId,@conversationId as conversationId, @messageId as messageId
    return 0
end
else if @action = 3 begin --Nuevo mensaje Entrada
	---Revisa que no se contesto el twitt
	select @messageOutTwitterId=max(A.messageOutTwitterId),@ninteration= count(B.messageInTwitterId)
	from messageOutTwitter A inner join messageInTwitter B on A.conversationTwitterId=B.conversationTwitterId
	where A.conversationTwitterId=@conversationId and A.messageStatusId not in (5,6,7,8,9,10,11)

	insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
	set @messageId=SCOPE_IDENTITY()

	if  @messageOutTwitterId is null begin
		insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
		values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)
		set @messageOutTwitterId=SCOPE_IDENTITY()
	end
	else begin
		update messageOutTwitter set messageInTwitterIdEnd=@messageId,[date]=@date,ninteration=@ninteration
		where messageOutTwitterId=@messageOutTwitterId
	end
	select @userId = userId  from messageOutTwitter with(nolock) where messageOutTwitterId=@messageOutTwitterId
	select @userId as userId,@conversationId as conversationId, @messageId as messageId
	return 0
end
else if @action = 4 begin --Obtiene el maximo messageOutTwitterId por conversacion
    select @messageOutTwitterId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId
	select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
	select @messageOutTwitterId as messageOutTwitterId,@replayId as replayId
	return 0
end
else if @action = 5 begin --Ultimo mensaje en por ACD
    select isnull(max(twitId),0),max(date) from messageInTwitter as A
	inner join conversationTwitter as B on A.conversationTwitterId=B.conversationTwitterId
	where B.inboundId=@inboundId
	return 0
end
else if @action = 6 begin --Obtiene conversación dependiendo del replayId
	select @conversationId=conversationTwitterId  from messageOutTwitter where twitId=@replayId
	if @conversationId is not null begin
		select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
	end
	else begin
		select 0 as conversationId,''0'' as replayId
	end
	select @conversationId as conversationId,@replayId as replayId
	return 0
end

set nocount off'
		
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
