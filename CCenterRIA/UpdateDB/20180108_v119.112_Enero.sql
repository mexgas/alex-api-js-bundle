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
set @versionfix = 112
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix in (@versionfix-1,@versionfix)
  begin
    begin tran
    begin try


    set @process = 'CW-1340 -- ALTER SP ccsp_OUTGetCallsInfo_AllCamps'
      set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_OUTGetCallsInfo_AllCamps]
@Tipo as tinyint=0
AS

declare @mToday as smalldatetime

select @mToday = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
if @Tipo = 0
begin
  SELECT cam_id, cam_descripcion,
    0 as pContesta,
    0 as pOcupado,
    0 as pNoContesta,
    0 as pFaxModem,
    0 as pNoService,
    0 as Marcaciones, 0 as Contestan,  0 as Ocupado, 0 as NoContesta, 0 as FaxModem, 0 as NoService
  FROM ccCamps
  order by cam_id
end

if @Tipo = 1
begin
  select cam_id, L.Campana,
    ((L.Contestan*100)/ L.Marcaciones) as pContesta,
    ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
    ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
    ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
    ((L.NoService*100)/ L.Marcaciones) as pNoService,
    L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
    ,L.Otro,L.Cancelado,L.buzon,L.NoDialTone,L.congestion
  from (
  select cam_id, '''' as Campana,
    count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
    count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
    count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
    count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
    count(*) as Marcaciones
    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Otro
    ,count(case tipoResDial_id when 13 then 1 else null end) as Cancelado
    ,count(case tipoResDial_id when 11 then 1 else null end) as buzon
    ,count(case tipoResDial_id when 5 then 1 else null end) as NoDialTone
    ,count(case tipoResDial_id when 12 then 1 else null end) as congestion

  from ccoLogDials
  Where fecha >  @mToday
  group by cam_id
  ) L order by Campana

end

if @Tipo = 2
begin
  select cam_id, L.Campana,
    ((L.Contestan*100)/ L.Marcaciones) as pContesta,
    ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
    ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
    ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
    ((L.NoService*100)/ L.Marcaciones) as pNoService,
    L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
  from (
  select C.cam_id as cam_id, cam_descripcion as Campana,
    count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
    count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
    count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
    count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
    count(*) as Marcaciones
  from ccoLogDials L join ccCamps C on L.cam_id=C.cam_id
  Where fecha >  @mToday
  group by C.cam_id, cam_descripcion
  ) L order by Campana
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