/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
		
Date: 2019/01/08
Description:

Database: CCenterRia
Required version: 121.11

Se agrega la tarea
CW-2031
CW-2576

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

set @version = 121--**********actualizar a 119 sin fix
set @versionfix = 24
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 22
	begin
		begin tran
		begin try
--Drop-Start
--Drop-End
--Create-Start


  set @process = 'CW-2152 Alter column Data'
  set @Sql= 'alter table DataCallIn alter column [Data] varchar(255)'
  EXEC(@Sql) 


  set @process = 'CW-2393 ETIQUETAS EN PORTUGUES Validate y Detalle ccSettings -- Version BD 119.122 -- '
      set @Sql= 'update ccSettings set detalle = ''Idioma en que apareceran tanto agente como admin RIA.  (0 español - 1 inglés - 2 portugués)'' where setting_id=27
update ccSettings set validate = ''^[0-2]$'' where setting_id=27
'
      EXEC(@Sql)       


  set @process = 'CW-2027 Plan de marcación update setting 195'
  set @Sql= 'update ccSettings set descripcion=''"Estructuras especiales de marcación (México)'',
detalle=''Valor:(0) Local 7 o 8, LD 12 y Celular 13, Valor: (1) Local 10, LD 12 y Celular 13,Valor: (2) Local 10, LD 10 y Celular 10 '',
description=''Special dialing structures (Mexico)'',validate=''^[0-2]$''
 where setting_id=195'
    EXEC(@Sql)

    set @process = 'CW-2027 Plan de marcación agregar a cstoTipoLlamada'
    set @Sql= 'if not exists(select * from cstoTipoLlamada where country_id=1 and tipoLlamada_id=12)
    insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,prefijo,longitud)
    values (1,12,''Local'',''%'',''10'')'
    EXEC(@Sql)

    set @process = 'CW-1501 Version 102.24 '
      set @Sql= 'if not exists (select * from sys.tables where name = N''targetRecord'')
      begin
          create table targetRecord(
        targetT varchar(250) primary key,en varchar(255),es varchar(255),pt varchar(255)
      );
      end'
    EXEC(@Sql)

    set @process = 'CW-1501 Version 102.24 '
      set @Sql= 'if not exists (select * from sys.tables where name = N''valueRecord'')
      begin
        create table valueRecord(
        valueT varchar(250) primary key,es varchar(255),en varchar(255),pt varchar(255)
        );
      end'
    EXEC(@Sql)
--Create-End
--Alter-Start

set @process = 'CW-1501 Version  120.24'
      set @Sql= 'ALTER procedure [dbo].[ccsp_RIA_ABCLog]
    @option tinyint,
    @areaName varchar(50)=null,
    @operationType tinyint = null,
    @login varchar(20) = null,
    @moduleId int=null,
    @value varchar(250)=null,
    @target varchar(250)=null,
    @operationDateIni smalldatetime = null,
    @operationDateFin smalldatetime = null,
    @top int = 0
    as
    set nocount on

    if @option=1 -- muestra todo
     begin
      select log_id, areaName, operationDate, operationType, login, module_id, value, target
      from ccRIALog with(nolock)
      return(0)
     end

    if @option=2 -- insert
     begin
      declare @areaNameValue as varchar(50)
      set @areaNameValue = @areaName

      if (left(@areaName,1) = ''!'')
       begin
        select @areaNameValue = areaName
        from dbo.ccRIACat_Areas AS AREAS WITH(NOLOCK)
        where AREAS.IDArea = right(@areaName,len(@areaName)-1)
       end

      INSERT INTO ccRIALog VALUES(@areaNameValue, GETDATE(), @operationType, @login, @moduleId, @value, @target)
      return(0)
     end

    declare @lang tinyint
    select @lang = valor from ccsettings where setting_id=27

    if @option=3 -- muestra información por filtros (System>Log) // Fechas
     begin
      set rowcount @top
      select L.log_id, L.areaName, L.operationDate, 
      case @lang when 0 then SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion)-1)
       else SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion)+1, len(o.descripcion)) END operationType, L.login, 
      case @lang when 0 then SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion)-1)
       else SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion)+1, len(m.descripcion)) END module_id,

       case  when t.targetT is null then L.target 
      else
           case @lang 
           when 0 then t.es
           when 2 then t.pt
          else t.en end
      end as target,
      case when v.valueT is null then L.value
      else
        case @lang 
        when 0 then v.es
        when 2 then v.pt
        else v.en end
       end  as value



      from CCRIALOG L join ccRIALog_Module M with(index(IX_ccRIALog_Module)) on L.module_id = M.module_id join ccRIALog_Operation O with(index(IX_ccRIALog_Operation)) on L.operationType = O.operationType
      left join targetRecord t on t.targetT=L.target
      left join valueRecord v on v.valueT = L.value
      where L.operationType = case isnull(@operationType, 0) when 0 then L.operationType else @operationType end
       and L.login = case isnull(@login, '''') when '''' then L.login else @login end
       and L.module_id = case isnull(@moduleId, 0) when 0 then L.module_id else @moduleId end
       and L.target = case isnull(@target, '''') when '''' then L.target else @target end
       and L.operationDate >= case when isnull(@operationDateIni, ''19000101'') <> ''19000101'' and 
        isnull(@operationDateFin, ''19000101'') <> ''19000101'' then dateadd(minute, -1, @operationDateIni) else L.operationDate end
       and L.operationDate <= case when isnull(@operationDateIni, ''19000101'') <> ''19000101'' and 
        isnull(@operationDateFin, ''19000101'') <> ''19000101'' then dateadd(minute, 1, @operationDateFin) else L.operationDate end
   
  
      order by L.operationDate desc
      return(0)
     end
    if @option=4 -- Catalogo de modulos
     begin
      select m.module_id, o.operationType, 
      case @lang when 0 then SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion)-1)
       else SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion)+1, len(m.descripcion)) END as mDescripcion, 
       case @lang when 0 then SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion)-1)
       else SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion)+1, len(o.descripcion)) END as oDescripcion
      from ccRIALog_Operation o with(index(IX_ccRIALog_Operation)) join ccRIALog_Cat_Relation r on o.operationType = r.operationType
       join ccRIALog_Module m with(index(IX_ccRIALog_Module)) on r.module_id = m.module_id
      UNION
      select 0, -1, case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END, ''-''
      UNION
      select 0, 0, case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END, case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END
      UNION
      select module_id, 0, case @lang when 0 then SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion)-1)
       else SUBSTRING(descripcion, CHARINDEX(''|'', descripcion)+1, len(descripcion)) END as descripcion, 
       case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END from ccRIALog_Module with(index(IX_ccRIALog_Module)) 
      UNION
      select module_id, -1, case @lang when 0 then SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion)-1)
       else SUBSTRING(descripcion, CHARINDEX(''|'', descripcion)+1, len(descripcion)) END as descripcion, ''-'' 
       from ccRIALog_Module with(index(IX_ccRIALog_Module))   
      order by mDescripcion, oDescripcion
      return(0)
     end

    if @option=5 -- Catalogo de operaciones
     begin
      select operationType, case @lang when 0 then SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion)-1)
       else SUBSTRING(descripcion, CHARINDEX(''|'', descripcion)+1, len(descripcion)) END as descripcion
      from ccRIALog_Operation with(index(IX_ccRIALog_Operation))
      union
      select 0, case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END 
      order by 2
      return(0)
     end

    set nocount off'
    EXEC(@Sql)
--Alter-End
--Select-Start
--Select-End
--Update-Start
    set @process = 'CW-2031 --se cambia el nombre de la etiqueta del menu y se cambia la encriptacion'
        set @Sql= 'update [dbo].[ccMenus] set menu_descrip = ''Historial de carga|Export Log'', release = ''b14dfaa33570212ebf08ddc649b950b52262aa5dcab6451991e6927bbd77d325'' where menu_id = 26 '
        EXEC(@Sql)
--Update-End
--Delete-Start
--Delete-End
--Insert-Start
   set @process = 'CW-1501 Version 120.24'
      set @Sql= 'if not exists (select * from targetRecord where targetT=''ALL'')
    begin
    insert into targetRecord values(''ALL'',''ALL'', ''TODO'',''TUDO'');  
  end'
  EXEC(@Sql)

  set @process = 'CW-1501 Version 120.24'
      set @Sql= 'if not exists (select * from targetRecord where targetT=''System'')
    begin
    insert into targetRecord values(''System'',''System'',''Sistema'',''Sistema''); 
  end'
  EXEC(@Sql)
  set @process = 'CW-1501 Version 120.24'
      set @Sql= 'if not exists (select * from targetRecord where targetT=''All Users'')
    begin
    insert into targetRecord values(''All Users'',''All users'',''Todos los usuarios'',''Todos os usuários'');  
  end'
  EXEC(@Sql)
  
  set @process = 'CW-1501 Version 120.24'
      set @Sql= 'if not exists (select * from targetRecord where targetT=''Database version'')
    begin
    insert into targetRecord values(''Database version'',''Database version'',''Versión de base de datos'',''Versão do banco de dados'');
  end'
  EXEC(@Sql)

  
  
  set @process = 'CW-1501 Version 120.24'
      set @Sql= 'if not exists (select * from valueRecord where valueT=''RESTRICT LOCAL CALLS (OFF)'')
  begin
    insert into valueRecord values(''RESTRICT LOCAL CALLS (OFF)'',  ''RESTRINGIR LLAMADAS LOCALES (DESACTIVADO)'',  ''RESTRICT LOCAL CALLS (DISABLED)'',  ''RESTRINGIR AS CHAMADAS LOCAIS (DESATIVADO)'');
  end'
  EXEC(@Sql)

  set @process = 'CW-1501 Version 120.24'
      set @Sql= 'if not exists (select * from valueRecord where valueT=''RESTRICT LD CALLS (OFF)'')
  begin
    insert into valueRecord values(''RESTRICT LD CALLS (OFF)'', ''RESTRINGIR LLAMADAS DE LD (DESACTIVADO)'',  ''RESTRICT LD CALLS (DISABLED)'', ''RESTRINGIR AS CHAMADAS INTERURBANAS (DESATIVADO)'');
  end'
  EXEC(@Sql)

  

  set @process = 'CW-1501 Version 120.24'
      set @Sql= 'if not exists (select * from valueRecord where valueT=''RESTRICT CEL CALLS (OFF)'')
  begin
    insert into valueRecord values(''RESTRICT CEL CALLS (OFF)'',  ''RESTRINGIR LLAMADAS A CELULAR (DESACTIVADO)'',  ''RESTRICT CELL PHONE CALLS (DISABLED)'', ''RESTRINGIR AS CHAMADAS AO CELULAR (DESATIVADO)'');
  end'

  EXEC(@Sql)


  set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''RESTRICT CEL CALLS (ON)'')
  begin
    insert into valueRecord values(''RESTRICT CEL CALLS (ON)'', ''RESTRINGIR LLAMADAS A CELULAR (ACTIVADO)'', ''RESTRICT CELL PHONE CALLS (ENABLED)'',  ''RESTRINGIR AS CHAMADAS AO CELULAR (ATIVADO)'');
  end'

  EXEC(@Sql)


  set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''RESTRICT LD CALLS (ON)'')
  begin
    insert into valueRecord values(''RESTRICT LD CALLS (ON)'',  ''RESTRINGIR LLAMADAS DE LD (ACTIVADO)'', ''RESTRICT LD CALLS (ENABLED)'',  ''RESTRINGIR AS CHAMADAS INTERURBANAS (ATIVADO)'');
  end'

  EXEC(@Sql)


  set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''RESTRICT LOCAL CALLS (ON)'')
  begin
    insert into valueRecord values(''RESTRICT LOCAL CALLS (ON)'', ''RESTRINGIR LLAMADAS LOCALES (ACTIVADO)'', ''RESTRICT LOCAL CALLS (ENABLED)'', ''RESTRINGIR AS CHAMADAS LOCAIS (ATIVADO)'');
  end'

  EXEC(@Sql)


  set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''XFERMASK (OFF)'')
  begin
    insert into valueRecord values(''XFERMASK (OFF)'',  ''RECIBIR TRANSFERENCIAS (DESACTIVADO)'', ''RECEIVE TRANSFERS (DISABLED)'', ''RECEBER TRANSFERÊNCIAS (DESATIVADO)'');
  end'

  EXEC(@Sql)


  set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''XFERMASK (ON)'')
  begin 
    insert into valueRecord values(''XFERMASK (ON)'', ''RECIBIR TRANSFERENCIAS (ACTIVADO)'',  ''RECEIVE TRANSFERS (ENABLED)'',  ''RECEBER TRANSFERÊNCIAS (ATIVADO)'');
  end'

  EXEC(@Sql)


  set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''AGT TRANSF. (OFF)'')
  begin
    insert into valueRecord values(''AGT TRANSF. (OFF)'', ''TRANSFERIR A AGENTES (DESACTIVADO)'', ''TRANSFER TO AGENTS (DISABLED)'',  ''TRANSFERIR AS CHAMADAS PARA OS AGENTES (DESATIVADO)'');
  end'

  EXEC(@Sql)


  set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''ACD TRANSF. (OFF)'')
  begin
    insert into valueRecord values(''ACD TRANSF. (OFF)'', ''TRANSFERIR A GRUPOS ACD (DESACTIVADO)'',  ''TRANSFER TO ACD GROUPS (DISABLED)'',  ''TRANSFERIR AS CHAMADAS PARA OS GRUPOS ACD (DESATIVADO)'');
  end'

  EXEC(@Sql)


  set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''EXT TRANSF. (OFF)'')
  begin
    insert into valueRecord values(''EXT TRANSF. (OFF)'', ''TRANSFERIR A NÚMEROS EXTERNOS (DESACTIVADO)'',  ''TRANSFER TO EXTERNAL NUMBERS (DISABLED)'',  ''TRANSFERIR AS CHAMADAS PARA NÚMEROS EXTERNOS (DESATIVADO)'');
  end'

  EXEC(@Sql)


  set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''MAN TRANSF. (OFF)'')
  begin
    insert into valueRecord values(''MAN TRANSF. (OFF)'', ''TRANSFERIR A NÚMEROS MANUALES (DESACTIVADO)'',  ''TRANSFER TO MANUAL NUMBERS (DISABLED)'',  ''TRANSFERIR AS CHAMADAS PARA NÚMEROS MANUAIS (DESATIVADO)'');
  end'

  EXEC(@Sql)


  set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''MAN TRANSF. (ON)'')
  begin
    insert into valueRecord values(''MAN TRANSF. (ON)'',  ''TRANSFERIR A NÚMEROS MANUALES (ACTIVADO)'', ''TRANSFER TO MANUAL NUMBERS (ENABLED)'', ''TRANSFERIR AS CHAMADAS PARA NÚMEROS MANUAIS (ATIVADO)'');
  end'

  EXEC(@Sql)




  set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''EXT TRANSF. (ON)'')
  begin
    insert into valueRecord values(''EXT TRANSF. (ON)'',  ''TRANSFERIR A NÚMEROS EXTERNOS (ACTIVADO)'', ''TRANSFER TO EXTERNAL NUMBERS (ENABLED)'', ''TRANSFERIR AS CHAMADAS PARA NÚMEROS EXTERNOS (ATIVADO)'');
  end'

  EXEC(@Sql)


  set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''ACD TRANSF. (ON)'')
  begin
    insert into valueRecord values(''ACD TRANSF. (ON)'',  ''TRANSFERIR A GRUPOS ACD (ACTIVADO)'', ''TRANSFER TO ACD GROUPS (ENABLED)'', ''TRANSFERIR AS CHAMADAS PARA OS GRUPOS ACD (ATIVADO)'');
  end'

  EXEC(@Sql)


    set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''AGT TRANSF. (ON)'')
  begin
    insert into valueRecord values(''AGT TRANSF. (ON)'',  ''TRANSFERIR A AGENTES (ACTIVADO)'',  ''TRANSFER TO AGENTS (ENABLED)'', ''TRANSFERIR AS CHAMADAS PARA OS AGENTES (ATIVADO)'');
  end'

  EXEC(@Sql)



    set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''Pause and resume recording(OFF)'')
  begin 
    insert into valueRecord values(''Pause and resume recording(OFF)'', ''PAUSAR Y CONTINUAR GRABACIÓN (DESACTIVADO)'', ''PAUSE AND RESUME RECORDING (DISABLED)'',''PAUSAR E RETOMAR A GRAVAÇÃO (DESATIVADO)'');
  end'

  EXEC(@Sql)



    set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''Pause and resume recording(ON)'')
  begin
    insert into valueRecord values(''Pause and resume recording(ON)'',  ''PAUSAR Y CONTINUAR GRABACIÓN (ACTIVADO)'',  ''PAUSE AND RESUME RECORDING (ENABLED)'', ''PAUSAR E RETOMAR A GRAVAÇÃO (ATIVADO)'');
  end'

  EXEC(@Sql)


  set @process = 'CW-2152 Alter FN fn_RIASplitDelimited'
  set @Sql= 'ALTER FUNCTION [dbo].[fn_RIASplitDelimited]
( 
  @List nvarchar(2000),
  @SplitOn nvarchar(1)
)
RETURNS @RtnValue table (
  Id int identity(1,1),
  Value nvarchar(255)
)
AS
BEGIN
  While (Charindex(@SplitOn,@List)>0)
  Begin 
    Insert Into @RtnValue (value)
    Select 
      Value = ltrim(rtrim(Substring(@List,1,Charindex(@SplitOn,@List)-1))) 
    Set @List = Substring(@List,Charindex(@SplitOn,@List)+len(@SplitOn),len(@List))
  End 
  
  Insert Into @RtnValue (Value)
    Select Value = ltrim(rtrim(@List))

    Return
END'
        EXEC(@Sql)  


  set @process = 'CW-2027 Plan de marcación ALTER function Completa'
    set @Sql= 'ALTER function [dbo].[Completa](@Cadena varchar(32), @pais varchar(2) = '''', @ld varchar(5) = '''')
RETURNS varchar(32)
AS
BEGIN
declare @resultado varchar(32)

if (@pais = '''' and @ld = '''')  begin
    select @pais = valor from ccSettings with(nolock) where setting_id = 104
    select @ld = valor from ccSettings with(nolock) where setting_id = 17
  end
select @resultado = dbo.limpia(@Cadena)

declare @lenPhone int,@lenLd int
set @lenPhone =len(@resultado)
set @lenLd =len(@ld)

if @pais = 1 begin --Empieza Mexico 
  
   declare @specialDialPlan tinyint 
   select @specialDialPlan=valor from ccsettings with(nolock) where setting_id = 195

   if @specialDialPlan=2 begin --Number 10 digits
    select @resultado = case
    when (@lenPhone =8 and @lenLd=2) or (@lenPhone =7 and @lenLd=3 ) then @ld + @resultado --Local    
    when @lenPhone=10 then @resultado -- LD
    when @lenPhone=12 then --LD
      case when left(@resultado, 2) = ''01'' then right(@resultado, 10) else ''E_NV_LD'' end
    when @lenPhone=13 then --Cell
      case when left(@resultado, 3) in (''044'', ''045'') then right(@resultado, 10) else ''E_NV_Cel'' end
    else ''E_NV_Longitud'' end
  end
  
  if @specialDialPlan=1  begin
    --Number local 10 digit
    --Number LD 12 digit
    --Number Cell 13 digit
    select @resultado = case
    when (@lenPhone =8 and @lenLd=2) or (@lenPhone =7 and @lenLd=3 ) then @ld + @resultado --Local    
    when @lenPhone=10 then --LD
      case when left(@resultado, @lenLd) = @ld then @resultado else ''01'' + @resultado end
    when @lenPhone=12 then
      case when left(@resultado, 2) = ''01'' then
        case when substring(@resultado, 3, @lenLd) = @ld then right(@resultado, 10) else @resultado end
      else ''E_NV_LD'' end
    when @lenPhone=13 then --Cell
      case when left(@resultado, 3) in (''044'', ''045'') then 
        case when substring(@resultado, 4, @lenLd) = @ld then ''044'' + right(@resultado, 10) else ''045'' + right(@resultado, 10) end
      end
    else ''E_NV_Longitud'' end
  end
  else begin
    --Number local 7 o 8 digit
    --Number LD 12 digit
    --Number Cell 13 digit
    select @resultado = case
    when (@lenPhone =8 and @lenLd=2) or (@lenPhone =7 and @lenLd=3 ) then @resultado --Local    
    when @lenPhone=10 then --LD
      case when left(@resultado, @lenLd) = @ld then right(@resultado, 10 - @lenLd) else ''01'' + @resultado end
    when @lenPhone=12 then
      case when left(@resultado, 2) = ''01'' then
        case when substring(@resultado, 3, @lenLd) = @ld then right(@resultado, 10 - @lenLd) else @resultado end
      else ''E_NV_LD'' end
    when @lenPhone=13 then --Cell
      case when left(@resultado, 3) in (''044'', ''045'') then 
        case when substring(@resultado, 4, @lenLd) = @ld then ''044'' + right(@resultado, 10) else ''045'' + right(@resultado, 10) end
      end
    else ''E_NV_Longitud'' end
  end 

  --Termina Mexico
  return @resultado
end

else if @pais = 2 begin -- Empieza Argentina
  select @resultado = case
    when (@lenPhone=7 and @lenLd=3) or (@lenPhone=6 and @lenLd=4) then
    @resultado
  -- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
  -- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
    when @lenPhone = 8 then
    case when @lenLd = 4 then
      case when left(@resultado,2) = ''15'' then @resultado end
    else
      case when @lenLd = 2 then @resultado end
    end
  -- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
    when @lenPhone=9 then
    case when left(@resultado, 2) = ''15'' then @resultado else ''E_NV_Cel'' end
  -- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
    -- Si es diferente se le agrega un 0 para llamadas de larga distancia
    when @lenPhone=10 then
    case when left(@resultado, @lenLd) = @ld
    then right(@resultado, 10 - @lenLd) else
      case when left(@resultado,2) = ''15'' then @resultado else ''0'' + @resultado end
    end
  -- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
  -- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
    when @lenPhone=11 then
    case when left(@resultado, 1) = ''0'' then
      case when substring(@resultado, 2, @lenLd) = @ld
      then right(@resultado, 10 - @lenLd) else @resultado end
    else ''E_NV_LD'' end
  -- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
  -- si no es local se le agrega el 0 y se marca el numero
    when @lenPhone=12 then
    case when left(@resultado, @lenLd) = @ld then
      case when substring(@resultado, @lenLd + 1, 2) = ''15'' then
        right(@resultado,12 - @lenLd) else ''E_NV_Cel'' end else ''0'' + @resultado end
  -- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
    when @lenPhone=13 then
    case when left(@resultado, 1) = ''0'' then
      case when substring(@resultado, 2, @lenLd) = @ld then substring(@resultado, @lenLd + 2, 12 - @lenLd) else @resultado end
    else ''E_NV_Cel'' end
  else ''E_NV_Longitud'' end

  --Termina Argentina
  return @resultado
  end

else if @pais = 3 begin --Empieza colombia
  select @resultado = case
  --Si son 7 digitos, se regresa igual
    when @lenPhone=7 then
    @resultado
  --Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
    when @lenPhone = 8  then
    case when left(@resultado,1) = @ld then right(@resultado,7) else @resultado end
  -- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
    when @lenPhone=10 then
    case when left(@resultado,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then ''0'' + @resultado
    else
      ''E_NV_Cel''
    end
  --Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
  --prefijo de celular
    when @lenPhone=11 then
    case when left(@resultado,1)=''0'' then
      case when substring(@resultado,2,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then @resultado else ''E_NV_Cel'' end
    else ''E_NV_Cel'' end
  else ''E_NV_Longitud'' end

  -- Termina Colombia
  return @resultado
  end

else if @pais = 4 begin --Empieza USA
  select @resultado = case @lenPhone
    when 3 then 
      case @resultado when ''911'' then @resultado else ''E_NV_Longitud'' end
    when 7 then @resultado
    when 10 then
      case when left(@resultado, @lenLd) = @ld
        then right(@resultado, 10 - @lenLd) else ''1'' + @resultado end
    when 11 then
      case when left(@resultado, 1) = ''1'' then
        case when substring(@resultado, 2, @lenLd) = @ld
          then right(@resultado, 10 - @lenLd) else @resultado end
    else ''E_NV_LD'' end
  else ''E_NV_Longitud'' end

  --Termina USA
  return @resultado
  end

else if @pais = 5 begin --5:Chile
  select @resultado = case @lenPhone
    when 6 then @resultado
    when 7 then @resultado
  -- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
    when 8 then

    case when @ld = left(@resultado,@lenLd) then right(@resultado,8-@lenLd) else
      case when left(@resultado,1) in (8,9) then ''09'' + @resultado else
        case when left(@resultado,1) = ''6'' then case when left(@resultado,2) in (61,63,64,65,67) then  @resultado else ''09'' + @resultado end
          else case when left(@resultado,1) = ''7'' then case when left(@resultado,2) in (71,72,73,75) then @resultado else ''09'' + @resultado end else @resultado end end
        end
    end
  -- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
  -- de telefonia voIp se le agrega el 0 al inicio
    when 9 then
    case when @ld = left(@resultado,2) then right(@resultado,7) else
      case when left(@resultado,2) in (41,32,65) then @resultado else
        case when left(@resultado,2) = ''44'' then ''0'' + @resultado else
          case when left(@resultado,1) = ''9'' and substring(@resultado,2,1) in (6,7,8,9) then ''0'' + @resultado else ''E_NV_Longitud'' end
          end
      end
    end
    when 10 then
    case when left(@resultado,2) = ''09'' then @resultado else ''E_NV_Cel'' end
  else ''E_NV_Longitud'' end

  -- Termina Chile
  return @resultado
  end

if @pais = 6 begin-- Venezuela
  select @resultado = case @lenPhone
    when 7 then @resultado
    when 10 then ''0'' + @resultado
    when 11 then
      case when left(@resultado,1) = ''0'' then @resultado else ''E_NV_Longitud'' end
    else
    ''E_NV_Longitud'' end
  return @resultado
end
--Termina Venezuela

else if @pais = 7 begin --7: Reino Unido
  select @resultado = case @lenPhone
    when 11 then
      case left(@resultado,1)
        when ''0'' then @resultado else ''E_NV_Longitud''
      end
    when 10 then
      case left(@resultado,1)
        when ''0'' then @resultado else ''0'' + @resultado
      end
    when 9 then
      case when left(@resultado,1) <> ''0'' then ''0'' + @resultado else ''E_NV_Longitud'' end
    when 8 then
      case when substring(@resultado, 1, 2) = ''08'' then @resultado else ''E_NV_Longitud'' end
    when 7 then
      case when left(@resultado,1) = ''8'' then ''0'' + @resultado else ''E_NV_Longitud'' end
    else
    ''E_NV_Longitud''
  end
  return @resultado
end
-- Termina UK

else if @pais = 8 begin -- arabia saudita
  select @resultado = case @lenPhone
  when 7 then @resultado
  when 8 then case substring(@resultado, 1, 1) when @ld then right(@resultado, 7) else ''0'' + @resultado end
  when 9 then case substring(@resultado, 1, 1) when ''5'' then ''0'' + @resultado
        when ''0'' then case substring(@resultado, 2, 1)
            when @ld then right(@resultado, 7) else @resultado end
        else ''E_NV_Longitud''
        end
  when 10 then case substring(@resultado, 2, 1) when ''5'' then @resultado else ''E_NV_Longitud'' end
  when 11 then case substring(@resultado, 2, 1)
          when ''8'' then case substring(@resultado, 3, 3)
                  when ''111'' then @resultado else ''E_NV_Longitud'' end
          else case when substring(@resultado, 3, 3) = ''510'' or substring(@resultado, 3, 3) = ''511'' then @resultado else ''E_NV_Longitud'' end
          end
  when 13 then @resultado
  else ''E_NV_Longitud'' end
  return @resultado
end -- arabia saudita

else if @pais = 9 begin--Australia

  select @resultado = case @lenPhone
  when 8 then
    /*case when exists (select AreaCode
              from SeriesAU
              where convert(int,LD) = convert(int,@ld)
              and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then*/
      case substring(@resultado, 1, 4) when ''5550'' then ''E_NV_LD'' else @ld +  @resultado end
    /*else case when exists (select AreaCode
              from SeriesAU
              where convert(int,LD) = convert(int,''04'')
              and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then
    ''04'' +  @resultado
    else ''E_NV_Cel'' end end*/
  when 9 then
    case when left(@resultado,1) <> ''0'' then
      case substring(@resultado, 2, 4) when ''5550'' then ''E_NV_LD'' else ''0'' + @resultado end
    else ''E_NV_LD'' end
  when 10 then
    case substring(@resultado, 3, 4) when ''5550'' then ''E_NV_LD'' else @resultado end
  else ''E_NV_Longitud'' end
  return @resultado
end


else if @pais = 10 begin--Brasil
  select @resultado = case @lenPhone
--llamada local fijo o celular
  when 8 then @resultado
  when 9 then @resultado
  when 10 then  -- Numero nacional
    case when left(@resultado, 2) = @ld
      then right(@resultado,8) else @resultado end
  when 11 then  -- Este caso solomente es para numero celular
      case when left(@resultado, 2) = @ld
          then right(@resultado,9) else @resultado end
  when 12 then  -- llamadas por cobrar local
    case when (left(@resultado,4) = ''9090'') then right(@resultado,8) else ''E_NV_PC'' end
  when 13 then
    case when left(@resultado,4) = ''9090'' then right(@resultado,9) -- llamadas por cobrar local celular
        when left(@resultado,1) = ''0'' then
      case when substring(@resultado,4,2)=@ld then right(@resultado,8) else right(@resultado,10) end -- llamadas de LDN
    else ''E_NV_Longitud'' end
  when 14 then
      case when left(@resultado,2) = ''90'' then -- llamadas por cobrar larga distancia
          case when substring(@resultado,5,2) = @ld then right(@resultado,8) else right(@resultado,11) end
          when left(@resultado,1) = ''0''  then --llamada larga distancia a celular
            case when substring(@resultado,4,2)= @ld then right(@resultado,9) else right(@resultado,11) end
      else ''E_NV_Longitud'' end
  when 15 then
    case when left(@resultado,2) = ''90'' then -- Llamadas por cobrar a celular LD
        case when substring(@resultado,5,2)=@ld then right(@resultado,9) else right(@resultado,11) end
      else ''E_NV_Longitud'' end

  else ''E_NV_Longitud'' end
  return @resultado
end

else if @pais = 11 begin--Guatemala
  if @lenPhone=8 and charindex(substring(@resultado,1,1),''2,3,4,5,6,7'') <= 0 begin    
    select @resultado = ''E_'' + @resultado
  end
  else
    select @resultado = ''E_NV_Longitud''
  return @resultado
end

else if @pais = 12 begin--Costa Rica
  if @lenPhone=8 and charindex(substring(@resultado,1,1),''2,3,4,5,6,7,8'') <= 0 begin    
    select @resultado = ''E_'' + @resultado
  end
  else if @lenPhone=10 and charindex(substring(@resultado,1,3),''800,900,905'') <= 0 begin    
    select @resultado = ''E_'' + @resultado
  end
  else if charindex(substring(@resultado,1,2),''00,08'') <= 0 begin   
    select @resultado = ''E_'' + @resultado
  end
  return @resultado
end

else if @pais = 13 begin--Salvador
  if @lenPhone=8 and charindex(substring(@resultado,1,1),''2,6,7'') <= 0 begin    
    select @resultado = ''E_'' + @resultado
  end
  else if charindex(substring(@resultado,1,2),''00'') <= 0 begin    
    select @resultado = ''E_'' + @resultado
  end
  return @resultado
end

else if @pais = 14 begin--Spain
  if @lenPhone=9 and charindex(substring(@resultado,1,1),''5,6,7,8,9'') <= 0 begin    
    select @resultado = ''E_'' + @resultado
  end   
  else if charindex(substring(@resultado,1,2),''00'') <= 0  begin   
    select @resultado = ''E_'' + @resultado
  end
  return @resultado
end

else if @pais = 15 begin--Peru
  select @resultado = case
    when (@lenPhone=7 and @lenLd=1) or (@lenPhone=6 and @lenLd=2) then @resultado
    when @lenPhone=8 then
    case when substring(@resultado, 1, @lenLd) = @ld
    then right(@resultado, 8 - @lenLd) else ''0'' + @resultado end
    when @lenPhone=9 then
    case when left(@resultado,1) = ''0'' and substring(@resultado, 2, @lenLd) = @ld
    then right(@resultado, 8 - @lenLd) else @resultado end
  else ''E_NV_Longitud'' end
  return @resultado
end --Termina Peru

else if @pais = 16 begin--Panama
  select @resultado = case
    when (@lenPhone=7) then
    case when substring(@resultado,1,1) in (''2'',''3'',''4'',''5'',''7'',''9'') then @resultado else ''E_'' + @resultado end
    when (@lenPhone=8) then
    case when substring(@resultado,1,1) = ''6'' then @resultado else ''E_'' + @resultado end
    else
      case when substring(@resultado,1,2) = ''00''then @resultado else ''E_'' + @resultado end
    end
  return @resultado
end

-- Termina
return @resultado

end'
    EXEC(@Sql)


    set @process = 'CW-2027 Plan de marcación alter function verifica2'
    set @Sql= 'ALTER FUNCTION [dbo].[Verifica2]
(@tel varchar(32),@pais tinyint = 0, @cldLocal varchar(7) = '''')
RETURNS varchar(32) AS
BEGIN
declare @ld varchar(7)
declare @lon tinyint
declare @result tinyint
declare @mod varchar(10)
declare @Cadena varchar(32)

if (@pais = 0 and @cldLocal = '''') begin
  select @pais = valor from ccSettings with(nolock) where setting_id = 104
  select @cldLocal = valor from ccSettings with(nolock) where setting_id = 17
end

select @tel = dbo.limpia(@tel)

if @pais = 1 begin --Empieza Mexico
  select @lon = len(@tel),@mod=''''
  if @lon in(7,8) begin
    set @tel = @cldLocal + @tel
    set @ld=@cldLocal   
  end 
  select @tel = right(@tel, 10)
  select @lon = len(@tel)
  

  if @lon = 10 begin
    
    if @ld is null begin
      if(exists(select top 1 cld from series nolock where cld=left(@tel,2)))
        select @ld = left(@tel,2)
      else if(exists(select top 1 cld from series nolock where cld=left(@tel,3)))
        select @ld = left(@tel,3)
      else
        return ''E_'' + @tel
    end

    select top 1 @mod = modalidad from series nolock where cld = @ld and serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

    if @mod not in (''FIJO'', ''MPP'',''CPP'')  begin
      return ''E_'' + @tel
    end


     declare @specialDialPlan tinyint 
   select @specialDialPlan=valor from ccsettings with(nolock) where setting_id = 195
    
  if @specialDialPlan=2 begin --Number 10 digits
    return @tel
  end
  
  if @specialDialPlan=1 begin
    --Number local 10 digit
    --Number LD 12 digit
    --Number Cell 13 digit
      select @tel = case
      when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then @tel else ''01'' + @tel end
      when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
      end
  end
  else begin
    --Number local 7 o 8 digit
    --Number LD 12 digit
    --Number Cell 13 digit
     select @tel = case
      when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''01'' + @tel end
      when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
      end
  end
     
  end 
  else if @lon>0 begin     
    set @tel = ''E_'' + @tel
  end
 return @tel
end --Termina Mexico

 -- Empieza Argentina
    if @pais = 2 begin
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel,1) = ''E'' begin return @tel end
     select @lon = len(@tel)
     if @lon in(6,7,8) and left(@tel,2) <> ''15'' begin
      set @tel = @cldLocal + @tel
     end

     if @lon in (8,9,10) and left(@tel,2) = ''15'' begin
      set @tel = @cldLocal + substring(@tel,3,@lon - 2)
     end

     --Buscamos el 15
     if @lon = 13 begin
      declare @index as int
      select @index = charindex(''15'',@tel)
      --El unico caso en el que la lada tiene un 15 es con lada 3715
      if @index < 2 begin
       select @tel = ''E_'' + @tel
       return @tel
      end
      else begin
       if substring(@tel,@index-2,4) = ''3715''
        begin
         select @ld = ''3715''
         set @tel = @ld + right(@tel,6)
        end
       else
        begin
         select @ld = substring(@tel,2,@index-2)
         set @tel = @ld + right(@tel,13 - (@index + 1))
        end
      end
     end

     select @tel = right(@tel, 10)

     if len(@tel) = 10 begin
      declare @serie as varchar(5)
      begin
       -- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
       declare @contLD as int
       declare @cont as int
       set @contLD=4
        BuscaLada:
        if isnull(@ld,'''') = '''' and @contLD >= 2
         begin
          select @ld = cld from seriesArg where cld=left(@tel,@contLD)
          if isnull(@ld,'''') = '''' begin
           set @contLD = @contLD - 1
           goto BuscaLada
          end
         end
        else begin
          if isnull(@ld,'''') = '''' begin
           select @tel = ''E_'' + @tel
          end
        end
      end

      -- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
      begin
      if len(@ld) = 2 begin
        set @cont = 5
        buscaSerie2:
        if isnull(@serie,'''') = '''' and @cont >= 4 begin
         select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,3,@cont)
         if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie2 end
        end
      end
      else begin
       if len(@ld) = 3 begin
        set @cont = 4
        buscaSerie3:
        if isnull(@serie,'''') = '''' and @cont >= 3 begin
         select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,4,@cont)
         if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie3 end
        end
       end
       else begin
        if len(@ld) = 4 begin
         set @cont = 3
         buscaSerie4:
         if isnull(@serie,'''') = '''' and @cont >= 2 begin
          select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,5,@cont)
          if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie4 end
         end
        end
       end
      end

      end

      select @mod = modalidad from seriesArg where cld = @ld and serie = @serie and right(@tel, 10 - len(@ld) - len(@serie)) between [NUMERACION INICIAL] and [NUMERACION FINAL]

      -- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie
      --select @ld,@serie,@mod,@contLD
      if isNull(@serie,'''') = '''' and @contLD>1 begin
      set @contLD = len(@ld) - 1
      set @ld = null
      goto BuscaLada
      end

      select @tel = case
       when @mod in (''BASICA'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''0'' + @tel end
       when @mod = ''CPP'' then case when @ld = @cldLocal then ''15'' + right(@tel,10-len(@ld)) else ''0'' + @ld + ''15'' + right(@tel,10-len(@ld)) end
       else ''E_'' + @tel
      end
     end else begin
      if len(@tel) > 0 begin
       select @tel = ''E_'' + @tel
      end
     end
     return @tel
    end  --Termina Argentina

    if @pais = 3 begin  --Empieza Colombia
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel,1) = ''E'' begin
      return @tel
     end

     if len(@tel) not in (7,8,10,11) begin
      return ''E_'' + @tel
     end

     if len(@tel) = 7 begin
      if exists(select serie from seriesCol where serie = left(@tel,4) and @cldLocal = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end

     if len(@tel) = 8 begin
      if exists(select serie from seriesCol where serie = substring(@tel,2,4) and left(@tel,1) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end

     if len(@tel) = 10 begin
      if exists(select serie from seriesCol where serie = substring(@tel,5,3) and (left(@tel,3) + ''-'' + substring(@tel,4,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end

     if len(@tel) = 11 begin
      if exists(select serie from seriesCol where serie = substring(@tel,6,3) and (substring(@tel,2,3) + ''-'' + substring(@tel,5,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end
    end  --Termina Colombia

    -- Empieza Chile
    if @pais = 5 begin
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel,1) = ''E'' begin
      return @tel
     end

     if len(@tel) = 6 and len(@cldLocal) = 2 begin
      if exists(select serie from seriesChi where cld = @cldLocal and left(@tel,3) = serie and right(@tel,3) between numeracioninicial and numeracionFinal) begin
       return @tel
      end
      else begin return ''E_'' + @tel end
     end

     if len(@tel) = 7 begin
      if @cldLocal in (2,41,44,32) begin
       if exists(select serie from serieschi where serie = left(@tel,4)) begin return @tel end
       else begin
        if left(@tel,3) = ''200'' and exists(select serie from serieschi where serie = left(@tel,3) ) begin return @tel end
       end
      end
     end

     if len(@tel) = 8 begin
      if left(@tel,1) = ''2'' begin
        if exists(select serie from serieschi where serie = substring(@tel,2,4)) begin return @tel end
        else begin
         if exists(select serie from serieschi where serie = substring(@tel,2,5)) begin return @tel end
         else begin return ''E_'' + @tel end
        end
      end
      else begin
       return @tel
      end
     end

     if len(@tel) = 10 begin
      if left(@tel,2) = ''09'' begin
       if exists(select serie from serieschi where cld=substring(@tel,3,1) and serie = substring(@tel,5,3)) begin
        return @tel
       end
       else begin
        return ''E_'' + @tel
       end
      end

     end
    end
    --Termina Chile

    if @pais = 6 begin --Empieza Venezuela
     select @lon = len(@tel)
     if @lon = 7  begin
      set @tel = @cldLocal + @tel
     end

     select @tel = right(@tel, 10)

     if len(@tel) = 10 begin
      select @ld = left(@tel,3)
      select @mod = tipo from seriesVen where left(@tel,3) = LD

      if @mod = ''CPP'' begin
       if exists( select * from seriesVen where LD = @ld ) begin
        if @ld = @cldLocal begin
         select @tel = right(@tel,7)
        end
        else begin
         select @tel = ''0'' + @tel
        end
       end
       else begin
        select @tel = ''E_'' + @tel
       end
      end
      else begin
       if @mod = ''FIJO'' begin
        if exists( select serie from seriesVen where serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [Inicio] and [Fin]) begin
         if @ld = @cldLocal begin
          select @tel = right(@tel,7)
         end
         else begin
          select @tel = ''0'' + @tel
         end
        end
        else begin
         select @tel = ''E_'' + @tel
        end
       end
       else begin
        select @tel = ''E_'' + @tel
       end
      end
     end
     else begin
      if len(@tel) > 0 begin
       select @tel = ''E_'' + @tel
      end
     end
     return @tel
    end --Termina Venezuela

    if @pais = 7 begin -- Empieza UK
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel, 1) = ''E'' begin -- regresa error por longitud
      return @tel
     end
     select @lon = len(@tel)

     --numeros no geograficos
     if (left(@tel, 2) in(''03'', ''07'', ''09'') and @lon <> 11) or (left(@tel, 3) in(''055'', ''056'', ''070'') and @lon <> 11) begin
      return ''E_'' + @tel --error por longitud con lada correcta
     end
     else begin
      if left(@tel, 7) in(''0845464'') or left(@tel, 5) = ''07624'' or left(@tel, 4) in(''0500'', ''0800'') or left(@tel, 3) in(''055'', ''056'', ''070'', ''76'') or left(@tel, 2) in(''03'', ''07'', ''08'', ''09'') begin
       return @tel; --longitud correcta y numero no geografico
      end
     end

     --numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
     if (left(@tel, 7) in(''0159575'', ''0159576'')) or
      (left(@tel, 5) in(''02820'',''02821'',''02825'',''02827'',''02828'',''02829'',''02830'',''02837'',''02838'',''02840'',''02841'',''02842'',''02843'',''02844'',''02866'',''02867'',''02868'',''02870'',''02871'',''02877'',''02879'',''02880'',''02881'',''02882'',''02885'',''02886'',''02887'',''02889'',''02890''
,''02891'',''02892'',''02893'',''02894'',''02895'',''02897'') and @lon = 11) or --claves 2xxx tienen formato 4-6
      (left(@tel, 4) in(''0113'', ''0114'',''0115'',''0116'',''0117'',''0118'',''0121'',''0131'',''0141'',''0151'',''0161'',''0238'',''0239'') and @lon = 11) or --3-digit area codes have 7-digit subscribers.
      (left(@tel, 3) in(''020'',''024'',''029'') and @lon = 11) begin --2-digit area codes have 8-digit subscribers.
      return @tel;
     end

     --numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
     if left(@tel, 2) = ''01'' begin
      select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,4) --mayor numero de ladas (va primero por ser mas probable)
      if @ld > 0 begin
       return @tel;
      end
      else begin
       select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,5) --ladas restantes
       if @ld > 0 begin
        return @tel;
       end
      end
     end --si no encontro ni error ni coincidencia entonces esta mal
     return ''E_'' + @tel
    end --Termina UK

    if @pais = 8 begin --Empieza Arabia Saudita
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     select @lon = len(@tel)
     if @lon = 7 begin
      set @tel = ''0'' + @cldLocal + @tel
     end
     select @lon = len(@tel)

     if @lon = 9 begin
      if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,2) = cld) begin
       if (substring(@tel,2,1) = @cldLocal)
       begin
        return right(@tel,7)
       end else begin
        return @tel
       end
      end
      else begin
       return ''E_'' + @tel
      end
     end
     if @lon = 10 begin
      if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,4,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,3) = cld) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end
     if @lon = 11 begin
      if exists(select regiones,* from seriesSA where right(@tel,6) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 6 and left(@tel,2) = cld) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end
    end --Termina Arabia Saudita

    if @pais = 9
     begin --Empieza Australia
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      select @lon = len(@tel)

      if left(@tel,1) <> ''E''
       begin
        if exists(select Regiones
            from SeriesAU
            where convert(int,LD) = convert(int,substring(@tel, 1, 2))
            and convert(int,AreaCode) = convert(int,substring(@tel, 3, 2))
            and convert(int,substring(@tel, 5, 6)) between convert(int,SerieInicio) and convert(int,SerieFin))
         begin
          return @tel
         end
        else
         begin
          return ''E_'' + @tel
         end
       end
      else
       begin
        return @tel
       end
     end --Termina Australia

    if @pais= 10
     begin -- Inicia Brasil
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      select @lon = len(@tel)
      if left(@tel,1) <> ''E''
       begin
        if @lon in (8,9) begin --numero local
         if exists(
         select Regiones
          from seriesBR where
           convert(int,AreaCode) = convert(int,@cldLocal) and
           convert(int,@tel) between convert(int,SerieInicio) and convert(int,SerieFin)
         )
         begin
          return @tel
         end
         else begin
          return ''E_'' + @tel
         end
        end
        if @lon in (10,11) begin --numero nacional
         if exists(
         select Regiones
          from seriesBR where
           convert(int,AreaCode) = convert(int,left(@tel,2)) and
           convert(int,right(@tel, @lon-2)) between convert(int,SerieInicio) and convert(int,SerieFin)
         )
         begin
          return @tel
         end
         else begin
          return ''E_'' + @tel
         end
        end
       end

      else begin
       return @tel
      end
     end -- Termina Brasil

    if @pais= 11
     begin -- Inicia Guatemala
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      if left(@tel,1) <> ''E''
       begin
        if exists(select zonaGeografica from seriesGT (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
         return @tel
        else
         return ''E_'' + @tel
       end
      else
       return @tel
     end -- Termina Guatemala

     if @pais= 12
     begin -- Inicia Costa Rica
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      if left(@tel,1) <> ''E''
       begin
        if len(@tel)=8
         if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
          return @tel
         else
          return ''E_'' + @tel
        else if len(@tel)=10 begin
         if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,3) and right(@tel, 7) between rangoInicio and rangoFinal)
          return @tel
         else
          return ''E_'' + @tel
        end
        else
         if charindex(substring(@tel,1,2),''00,08'') <= 0
          return ''E_'' + @tel
         else
          return @tel
       end
     end -- Termina Costa Rica

    if @pais= 13
     begin -- Inicia Salvador
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      if left(@tel,1) <> ''E''
       begin
        if len(@tel)=8
         if exists(select zonaGeografica from seriesSV (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
          return @tel
         else
          return ''E_'' + @tel
        else
         if charindex(substring(@tel,1,2),''00'') <= 0
          return ''E_'' + @tel
         else
          return @tel
       end
     end -- Termina Salvador

    if @pais= 14
     begin -- Inicia Spain
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      if left(@tel,1) <> ''E''
       begin
        if len(@tel)=9
         if exists(select provincia from seriesEsp (nolock) where indicativo = substring(@tel,1,1) and right(@tel, 8) between numInicial and numFinal)
          return @tel
         else
          return ''E_'' + @tel
        else
         if charindex(substring(@tel,1,2),''00'') <= 0
          return ''E_'' + @tel
         else
          return @tel
       end
     end -- Termina Espa?a

    if @pais= 15 begin --Inicia Peru
     select @tel = dbo.Completa(@tel, @pais, @cldLocal)
     select @lon = len(@tel)
     if @lon between 6 and 7 begin
      set @tel = @cldLocal + @tel
     end
     select @tel = right(@tel, 9)
     select @lon = len(@tel)
     if left(@tel,1) <> ''E'' begin
      if @lon = 9 begin
       if exists(select zonaGeografica from seriesPE (nolock) where
        left(@tel,1) = 9 or
        substring(@tel,2,1) = 1 and areaNumeracion = 1 and right(@tel, 7) between rangoInicio and rangoFinal or
        substring(@tel,2,1) <> 1 and left(@tel,2) = areaNumeracion and right(@tel, 7) between rangoInicio and rangoFinal
       )
        return @tel
       else
        return ''E_'' + @tel
      end
     end
    end --Termina Peru

  if @pais = 16 begin --Panama
    select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel,1) <> ''E''
     begin
      if len(@tel)=7 begin -- Local
       if(substring(@tel,1,1) != ''6'') begin
        if exists(select zonaGeografica from seriesPa (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
       return @tel
      else
       return ''E_'' + @tel
       end
       else
        return ''E_'' + @tel
      end
      if len(@tel)=8 begin --Celular
       if(substring(@tel,1,1) = ''6'') begin
        if exists(select zonaGeografica from seriesPa (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
         return @tel
      else
       return ''E_'' + @tel
       end
       else
        return ''E_'' + @tel
      end
      else begin
       if charindex(substring(@tel,1,2),''00'') <= 0
        return ''E_'' + @tel
       else
        return @tel
      end
     end
  end

    return @tel
   end'
    EXEC(@Sql)

  
  set @process = 'CW-2576 correccion de reporte de contestadas y transferidas'
  		set @sql='ALTER PROCEDURE [dbo].[ccsp_CstoCalculaCosto]
  @IDCall int = 0,
  @from AS smalldatetime = NULL,
  @to AS smalldatetime = NULL
  AS
  set nocount on
  declare @minutouno decimal(10,3), @minutoadicional decimal(10,3)
  declare @puerto smallint, @provedor_id smallint
  declare @longitud tinyint, @tipoLlamada_id tinyint
  declare @telefono varchar(20)
  
  if @IDCall = 0 -- Para calcular todo
   begin
      if @from is null and @to is null
       begin
          update ccoCallsOut
          --set costo =  t.MinutoUno + case when cco.cal_txfer + cco.cal_tring + cco.cal_tDialog > 0 then((ceiling(( cco.cal_txfer + cco.cal_tring + cco.cal_tDialog ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
          set costo =  t.MinutoUno + case when ISNULL(cco.totalCall_Time,0) > 0 then((ceiling(( ISNULL(cco.totalCall_Time,0) ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
           ,provedor_id = cd.provedor_id
           ,tipoLlamada_id = t.tipoLlamada_id
          from ccoCallsOut cco with(index(IX_ccoCallsOut_7), nolock), ccoDialers cd, cstoTarifa t
          where cco.cal_puerto = cd.puerto
           and cd.provedor_id = t.provedor_id 
           and t.tipoLlamada_id = dbo.fnGetTipoLlamada(dbo.Verifica(ltrim(rtrim(cal_telefono))))--dbo.fnGetTipoLlamada(cco.cal_telefono)
           and cco.cal_manual <> 1
           return(0)
       end
  
      -- calcula en el rango de fechas, solo los que no tienen costo
      update ccoCallsOut
      --set costo =  t.MinutoUno + case when cco.cal_txfer + cco.cal_tring + cco.cal_tDialog > 0 then((ceiling(( cco.cal_txfer + cco.cal_tring + cco.cal_tDialog ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
      set costo =  t.MinutoUno + case when ISNULL(cco.totalCall_Time,0) > 0 then((ceiling(( ISNULL(cco.totalCall_Time,0) ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
      ,provedor_id = cd.provedor_id
      ,tipoLlamada_id = t.tipoLlamada_id
      from ccoCallsOut cco with(index(IX_ccoCallsOut_8), nolock), ccoDialers cd, cstoTarifa t
      where cco.cal_puerto = cd.puerto
       and cd.provedor_id = t.provedor_id 
       and t.tipoLlamada_id = dbo.fnGetTipoLlamada(dbo.Verifica(cco.cal_telefono))
       and cco.cal_manual <> 1
       and cco.cal_inicio between @from and @to
       and cco.provedor_id is null
       return(0)
   end
  
  select @puerto = cal_puerto, @longitud = len(cal_telefono) , @telefono = cal_telefono 
  from ccoCallsOut with(index(PK_ccoCallsOut), nolock) where cal_id = @idCall
  
  if @puerto = 0
      return(0)
  
  select @minutouno = minutouno, @minutoadicional = minutoadicional, @provedor_id = d.provedor_id, @tipoLlamada_id = t.tipollamada_id 
  from cstoTarifa t
  inner join ccoDialers d on d.provedor_id = t.provedor_id
  where t.tipollamada_id = dbo.fnGetTipoLlamada(dbo.Verifica(@telefono))
  and d.puerto = @puerto
  
  update ccoCallsOut with(rowlock) 
  --set costo = @MinutoUno + case when cal_txfer + cal_tring + cal_tDialog > 0 then((ceiling(( cal_txfer + cal_tring + cal_tDialog ) / 60.0 )- 1) * @MinutoAdicional ) else 0 end
  set costo = @MinutoUno + case when ISNULL(totalCall_Time,0) > 0 then((ceiling(( ISNULL(totalCall_Time,0) ) / 60.0 )- 1) * @MinutoAdicional ) else 0 end
  ,provedor_id = case @provedor_id when 0 then provedor_id else @provedor_id end
  ,tipoLlamada_id = case @tipoLlamada_id when 0 then tipoLlamada_id else @tipoLlamada_id end
  where cal_id = @idCall
  
  set nocount off
  '
  		 
		EXEC(@sql)
  
  
--Insert-End
		set @process = 'CW-2609 ALTER ccsp_RIA_ABCCamps'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
			@option smallint,
			@UserId int = null,
			@Descripcion varchar(40) = null,
			@Cam_id varchar(1000),
			@Activa tinyint = null,
			@IDArea smallint = null,
			@frame tinyint = null, 
			@MirrorInbound_Id smallint = null,
			@Prefijo varchar(40) = null
			as
			set nocount on

			if @option = 0
			 begin
				 select cam_id,ISNULL(cam_descripcion,'''''''') as cam_descripcion,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
				 from ccCamps as CAMP with(nolock) 
				 left join ccRIACat_Areas as AREas with(nolock) on CAMP.IDArea = AREas.IDArea
				 return(0)
			 end

			if @option = 1 -- select Camp
			 begin
				 select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0) as Area_Id,
				 prefijo as Prefijo
				 from ccCamps a1 with(nolock) 
				  inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
				  inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
				 where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
				 return(0)
			 end

			if @option = 4 --Delete
			 begin
				 if exists (select inbound_id from ccInbound with(nolock) where cam_id = @Cam_id)
				  begin
					declare @error varchar(70)
					Select @error=case valor when 0 then ''No es posible eliminar la campaña, esta asociada a una especialidad'' 
					 else ''Campaign can not be deleted, it has an association with an ACD'' end
					from ccsettings with(nolock) where setting_id = 27
					raiserror (@error,18,1)		
					return(0)
				  end

				 delete ccCampsHorarios with(rowlock) where cam_id = @Cam_id
				 insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id) Values(@Cam_id, 5, 0, 0, @UserId)
				 Delete ccCalifCamp with(rowlock) where cam_id = @Cam_id and tipo = 1
				 Delete ccRIACampsGraph with(rowlock) where cam_id = @Cam_id
				 delete ccHistorialListaNegra with(rowlock) where cam_id = @Cam_id
				 delete ccRIARegistryLists with(rowlock) where cam_id = @Cam_id	
				 return(0)
			 end

			if @option = 2 --Insert
			 begin
				declare @new_cam_id smallint

				if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
				 begin
					select -1 --, ''Nombre en Uso''
					return(0)  
				 end

				-- ODC: la campaña siempre esta activa
				set @Activa = 1
				declare @pref int
				select  @pref = valor from ccSettings where setting_id = 201
				if (@pref = 0)
					set @Prefijo = ''''


				Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd,prefijo)
				select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
				case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end,@Prefijo

				if @@rowcount = 1
				select @new_cam_id = scope_identity()

				else
				 begin
					select -2 --, ''Error al crear campaña''
					return(0)
				 end

				if isnull(@MirrorInbound_Id, 0)<>0
				 begin
					if not exists(select inbound_id from ccInbound with(nolock) where inbound_id=@MirrorInbound_Id)
					 begin
						select -3 -- Error al asignar campaña a ACD, el ACD no existe o no pertenece a la misma area
						return(0)
					 end

					update ccinbound with(rowlock) set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
					update cccamps with(rowlock) set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
				 end

				insert into ccoDialerCamp (dialer_id, cam_id) 
				select dialer_id, @new_cam_id from ccoDialers with(nolock) where status = 1

				insert into ccCalifCamp (calif_id, cam_id, tipo) 
				select calif_id, @new_cam_id, 1 from ccTipoCalifOUT with(nolock) where CalifOut_Status = 1

				update ccCamps set keepDial=dbo.fn_keepDial_Camps(@new_cam_id)

				If not exists (select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
				 begin
					insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
				 end

				insert into ccRIACampsGraph (cam_id, graphic_id)
				select @new_cam_id, graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock)  where frame = @frame and type_id = 1

				--inserta la lista negra por default
				if (select valor from ccsettings with(nolock) where setting_id=152)=''1''
				begin
					declare @tempId as int
					DECLARE @dnclId TABLE 
					(
					  id int 
					);
					insert into @dnclId
					exec dbo.ccsp_RIACATBList null, null, 5
					select @tempId=id from @dnclId;
					exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
				end

				select @new_cam_id
				return(0)
			 end

			if @option = 3 -- Update
			 begin
				 if not exists(select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
				  insert into ccRIAGraphics (frame,type_id) values (@frame,1)

				 Update ccCamps with(rowlock) set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

				 update ccRIACampsGraph with(rowlock)
				  set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
				  where cam_id = @Cam_id

				 return(0)
			 end

			 if @option = 5 --Obtener relaciones de campañas - campañas
			   begin
				  if not exists (select cam_id from ccCamps with(nolock) where cam_id = @Cam_id) or
				 (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
					not exists (select cam_id from ccCamps with(nolock) where cam_id=@descripcion))
				 begin
					select -3 -- Campaña invalida
					return(0)
				 end
				
				if @descripcion=0
					set @descripcion = null

				update ccCamps with(rowlock) set surveyCamId = @descripcion where cam_id = @Cam_id
				if @@rowcount=0
					select -4 -- Error al actualizar
					
				else
				 begin
					delete cccalifcamp with(rowlock) where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

				 end

				return(0)
			   end

			if @option = 6
				begin
					select cam_id, isnull(surveycamid,0)
					from cccamps with(index(PK_ccCamps),nolock)
					where cam_id = @Cam_id
					return(0)
				end

			if @option = 7 -- Checa si la campaña no tiene grabaciones y se puede modificar el prefijo
				begin	
					select count(*) as Grabaciones from ccoCallsOut where cam_id = @Cam_id
					--select 0 as Grabaciones	
				end

			return(0)
			set nocount off'
		EXEC(@Sql)


    set @process = 'CW-2024 Alter SP --ccsp_AgentUpdateCallTimes validate manual call'
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
declare @cal_manual int

set @cal_manual= 0

if @TipoCall=1 --INBOUND
 begin
  Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
  cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
  cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
  Where cal_id= @IDCall

  --Actualizar tiempo total de llamada
  exec ccsp_EngineLogTransfers 2, @IDCall, @TipoCall, 2, null, @cal_tXfer, @cal_tDialog

  -- Elimina callback generado por abandono
  Declare @ANI_x varchar(19)
  select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

  DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
  DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
 end

if @TipoCall=2 --OUTBOUND
 begin
    Update ccoCallsOUT with(rowlock) Set cal_tXfer=case when @cal_tXfer > 0 then @cal_tXfer else cal_tXfer end, 
    cal_tDialog=case when @cal_tDialog > 0 then @cal_tDialog else cal_tDialog end, 
    @cal_tDialog=case when @cal_tDialog > 0 then @cal_tDialog else cal_tDialog end,
    cal_tNotas=case when @cal_tNotas > 0 then @cal_tNotas else cal_tNotas end, 
    cal_tMoh=case when @mtmoh > 0 then @mtmoh else cal_tMoh end,
    cal_tRing=case when @cal_tRing > 0 then @cal_tRing else cal_tRing end, 
    cal_manual=case when @isChatCall=1 then 3 else cal_manual end,
    cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end,
    totalCall_Time=case when totalCall_Time is null then @cal_tDialog else totalCall_Time end 
    Where cal_id=@IDCall

    -- calcula el costo de la llamada
    exec ccsp_CstoCalculaCosto @IDCall


  select @cal_manual=cal_manual from ccoCallsOUT with(nolock) Where cal_id=@IDCall

 end

select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

if @cal_tDialog >= @tMinAVRS and @cal_manual<>1
  and not exists(select * from ccAVRSTransfer where cal_id=@IDCall and tipo=@TipoCall - 1) 
  begin
        insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
    end

return(0) 

set nocount off'
        EXEC(@Sql)


        set @process = 'CW-2024 Alter SP --ccsp_EngineLogTransfers validate manual call'
        set @Sql= 'ALTER procedure [dbo].[ccsp_EngineLogTransfers]
@action as tinyint,
@cal_id as integer,
@tipo as tinyint,
@modo as tinyint,
@destino as varchar(50),
@tantes integer = 0,
@tdespues integer = 0,
@pbxId tinyint =0,
@channel int =0
as
-- tipo: 1 inbound, 2 outbound
-- modo: 0 externa ciega, 1 agente, 2 acd, 3 confer, 4 externa supervisada, 5 desborde

declare @totalCall_Time integer
declare @callout_id int

if @action = 1 begin
    if @modo = 4 begin
        insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel) 
        values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, getdate(), @pbxId,@channel )
        if @tdespues > 0 begin
                select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tdespues
                update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
        end
    end
    else begin
        if not exists (select * from ccLogTransfers where cal_id = @cal_id and tipo = @tipo)
            insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel) 
            values ( @cal_id, @tipo, @modo, @destino, 0, @tantes, getdate() ,@pbxId,@channel )

        if @tipo = 2 begin
            if @modo = 5 begin
                select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
                update ccLogTransfers set tDespuesXfer = @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2), tAntesXfer = @tdespues + (select tAntesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2) where cal_id = @cal_id and tipo = 2
            end
        
            if @modo in (0,1,2) begin
                select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
                update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
            end
        end

        else begin
            if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
                select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
                select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
                update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
            end
        end
    end
   --Valida que no existe y que el tiempo minimo de la grabacion se mayor al establecido para que lo tome el detector de gritos
  if not exists(select * from ccAVRSTransfer where cal_id=@cal_id and tipo= @tipo-1) begin
    declare @tMinAVRS smallint,@cal_tDialog int,@cal_manual int
    set @tMinAVRS=5
    set @cal_manual=0
    select @tMinAVRS=valor from ccSettings where setting_id=65
    if @tipo=2 begin
      select @cal_tDialog=cal_tDialog,@cal_manual=cal_manual from ccoCallsOut where cal_id=@cal_id
    end
    else begin
      select @cal_tDialog=cal_tDialog from ccCallsIn where cal_id=@cal_id
    end

    if @cal_tDialog >= @tMinAVRS and @cal_manual<>1 begin
      insert into ccAVRSTransfer (cal_id,tipo) values(@cal_id,@tipo-1)
    end
  end
end

else if @action = 2 begin   
    if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
        select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
        update ccLogTransfers set tDespuesXfer = @tdespues + @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2) where cal_id = @cal_id and tipo = 2
        select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
        update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
    end
end

else if @action = 4 begin
    select @totalCall_Time = ISNULL((select sum(tincall) from IVRCallsIn where callout_id = @cal_id), 0) + ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0)
    update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
end'
        EXEC(@Sql)


                set @process = 'CW-2024 Alter SP --ccsp_SaveStatusAgent validate manual call'
        set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus float,
@TipoCall  tinyint,
@Camp smallint,
--@isTransferSurvey bit=0, --0 Callback, 1 Realiza Transferencia inmediata
@callout_id int=0,
@call_id int=0,
@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog int =0 ,
@currentStatus int =-2,--NUEVO PARÁMETRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null,
@tMusicHold int =0
AS
if @Fecha4 is null set @Fecha4 = getdate()

if @TipoCall > 0 set @TipoCall = @TipoCall - 1

if (@User_id > 0 ) begin

  declare @cam_id int,@surveycamId int
  declare @cal_telefono varchar(30)
  declare @cal_key varchar(20)
  declare @inbound_id int
  declare @callBackSurveyClients bit
  declare @cal_whoHung tinyint
  declare @cal_tDialog int
  declare @cal_tNotas int
  declare @cal_tNotaOri int
  declare @tMinAVRS smallint
  declare @calInicio datetime
  declare @sumCall int
  declare @cal_manual int

  set @cal_manual=0
  set @cal_tNotas =0
  set @cal_tNotaOri=0
  --4 Dialog,6 Notas, 27 Notas Fallida
  if @TipoStatusAge_id in (4,6,27) and @call_id>0 begin
    if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
    if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


    if @TipoCall = 0 begin --IN
      select @calInicio=cal_Xfer,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas, @Camp=Inbound_id, @cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas, @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
            from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13

      if @cal_tDialog = 0 and @tDialog >0  and @isLogout=1  begin
        if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
          set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
          if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
          if @TipoStatusAge_id=6  begin
            if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
            else  set @tDialog=@tDialog-1
          end
        end

        update ccCallsIN with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
      end
    end
    else begin --OUT
      select @calInicio=cal_inicio,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,
      @cam_id = cam_id,@cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas,@cal_manual=cal_manual from ccoCallsOut where cal_id = @call_id
      set @Camp=@cam_id

      if @cal_tDialog = 0 and @tDialog>0 and @isLogout=1  begin
        if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
          set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
          if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
          if @TipoStatusAge_id=6  begin
            if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
            else  set @tDialog=@tDialog-1
          end
        end

        update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog, cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
      end
      else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
        update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog  where cal_id = @call_id
      else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
        update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas where cal_id = @call_id
    end

    select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

    if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1 and @cal_manual<>1
    and  not exists(select * from ccAVRSTransfer where cal_id=@call_id and tipo= @TipoCall)     
    begin       
      insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
    end

    if @TipoStatusAge_id in(6,27)  and @isLogout=1  begin
      --Valida que el agente no pudo guardar el status antes de desloguear
      if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
        INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
    end


  end


  if (@TipoStatusAge_id=4) begin-- 4 = Dialogo
    declare @tStatus3 int, @Fecha3 datetime
    select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
    insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
    select @User_id, cam_id, datediff(ms, dateadd(ss, -@tStatus3, @Fecha3), dateadd(ss, -@tStatus, @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
    from cccampsagente where user_id = @User_id


    ---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
    if @call_id>0 begin
      if @TipoCall = 0 begin --IN

          select @surveycamid = isnull(cam_id,0),@callBackSurveyClients = callBackSurveyClient  from ccinbound where inbound_id = @inbound_id

          if @surveycamId>0  and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
            if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
              begin
                if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100
                begin
                  insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
                  values(right((cast(@call_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()) )
                end
              end
          end
      end --@TipoCall = 0
      else begin  --OUT



        select @surveycamId = isnull(surveycamid,0),@callBackSurveyClients= callBackSurveyClient from cccamps where cam_id = @cam_id
        select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono,@cal_whoHung=cal_whoHung
          from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
          where callout_id = @callout_id and statusCall_id = 13 and cal_id = @call_id

        if @surveycamId>0 and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
          if (select surveyPctg from ccCamps where cam_id = @surveycamId) >= rand() *100
          begin
            insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
            values(right((cast(@call_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()))
          end
        end
      end
    end--@isTransferSurvey = 0 and @callout_id>0


   end

  if @TipoStatusAge_id =6  and @isLogout=0
  begin
      --Valida que el ccserver no haya guardado antes el status antes al desloguear
      if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-10,@Fecha4) and @Fecha4 and tStatus = @tStatus+1)
        INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )
  end
  else
    INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )

  if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
  begin
    INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
      VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )

    ---Para Agente RIA: OAYC
    INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
      VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )
  end

  -- Actualiza para reporte de tiempos especiales (Boan)
  if @Camp > 0
    begin
      if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock)
            where IdCampEsp = 0 and user_id = @User_id)
        begin
          update ccLogAgentesDia with(rowlock)
          set IdCampEsp = @Camp, Tipo = @TipoCall
          where IdCampEsp = 0
          and user_id = @User_id
        end

      if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock)
            where IdCampEsp = 0 and user_id = @User_id)
        begin
          update ccLogAgentesNotReady with(rowlock)
          set IdCampEsp = @Camp, Tipo = @TipoCall
          where IdCampEsp = 0
          and user_id = @User_id
        end
    end
end'
        EXEC(@Sql)



      set @process = 'CW-2027 Plan de marcación ALTER SP  ccsp_Limpia'
    set @Sql= 'ALTER procedure [dbo].[ccsp_Limpia]
@tel varchar(50),
@Camp int = 0,
@calKey varchar(20) = ''''
      
as
set nocount on
declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint, @specialDialPlan smallint, @validateTel smallint
/***
 4  as res lista Negra
 2 as res Digitos incorrectos Prefijo Marcacion 01,044,045,001
 3 as res Number notExists
 1 as res Longitud invalida
 0 as res Numero correcto
 
***/
select @tel = dbo.limpia(@tel)
select @lon = len(@tel)
select @pais = valor from ccSettings with(nolock) where setting_id = 104 
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @extLen = valor from ccsettings with(nolock) where setting_id = 108
select @specialDialPlan = valor from ccsettings with(nolock) where setting_id = 195
select @validateTel = valor from ccsettings with(nolock) where setting_id = 206

if @lon>1 begin
  if @validateTel = 1 begin --Setting 206 para no validar longitud ni listas negras
    select 0 as res, @tel as tel
    return(0) 
  end

  if @extLen=@lon begin -- Setting 108 validar el tamaño de longitud del telefono
    if (select dbo.ValidateBlackListPhone(@tel,@Camp,@calKey))=1 begin
      select 4 as res, @tel as tel --blackList
      return(0)
    end 
    select 0 as res, @tel as tel -- Extension
    return(0)
  end
end

declare @telTemp as varchar(15)
      
select @telTemp = @tel

if @pais = 1 begin ---Mexico
  if @lon = 3 and @tel = ''911'' begin
    select 4 as res, @tel as tel --Lista Negra
    return(0)
  end

  if @lon < 7 or @lon = 7 and len(@ld) = 2 or @lon = 8 and len(@ld) = 3 or @lon in (9, 11) or @lon > 13 begin
    select 1 as res, @tel as tel --Longitud invalida
    return(0)
  end

  if @lon = 12 and left(@tel, 2) <> ''01'' 
    or @lon = 13 and left(@tel, 3) <> ''044'' and left(@tel, 3) <> ''045'' and left(@tel, 3) <> ''001'' begin
    select 2 as res, @tel as tel--Digitos incorrectos
    return(0)
  end

  if left(@tel, 3) = ''001'' begin
    select 0 as res, @tel as tel
    return(0)
  end

  
  select @tel = case when @lon in (7, 8) then @ld + @tel else right(@tel, 10) end   

  if (select dbo.ValidateBlackListPhone(@tel,@Camp,@calKey))=1 begin
    select 4 as res, @tel as tel --blackList
    return(0)
  end
  
  declare @mod varchar(5),@isLocal bit
  set @mod=''''

  
  select @mod = modalidad from series where cld + serie = left(@tel, 6) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

  if @mod not in (''FIJO'', ''MPP'',''CPP'')  begin
      select 3 as res, @tel as tel--No encontrado
    return (0)
    end


  if @specialDialPlan =2 begin --Number 10 digits
    select 0 as res, @tel as tel
    return (0)    
  end
  
  set @isLocal= case when left(@tel, len(@ld))= @ld then 1 else 0 end

  if @specialDialPlan =1  begin
    select @tel = case
      when @mod in (''FIJO'', ''MPP'') then case when @isLocal = 1 then @tel else ''01'' + @tel end
      when @mod = ''CPP'' then case when @isLocal = 1 then ''044'' + @tel else ''045'' + @tel end
    end
  end 
  else begin
    select @tel = case
      when @mod in (''FIJO'', ''MPP'') then case when @isLocal = 1 then right(@tel, 10 - len(@ld)) else ''01'' + @tel end
      when @mod = ''CPP'' then case when @isLocal = 1 then ''044'' + @tel else ''045'' + @tel end
    end
  end 

  select 0 as res, @tel as tel
  return(0)
end

else if @pais = 2 begin --Argentina 
  set @tel = dbo.completa(@tel, @pais, @ld)
  
  if left(@tel,1)=''E'' begin
    select 1 as res, @telTemp as tel --Longitud Invalida
    return (0)
  end

  select @tel = dbo.fnClearPhoneArg(@tel)

  if (len(@tel) = 10 or len(@ld + @tel) = 10) and left(@tel,1) <> ''E'' begin
    if (select dbo.ValidateBlackListPhone(@tel,@Camp,@calKey))=1 begin
      select 4 as res, @tel as tel --blackList      
    end
    else begin
      select @tel=dbo.verifica2(@tel,@pais,@ld)
      if left(@tel,1)=''E'' begin
        select 3 as res, @telTemp --Not existsFound
      end
      select 0 as res, @tel  as tel     
    end   
  end 
  else begin 
    select 2 as res, @telTemp as tel --Digitos incorrectos      
  end
  return (0)
end 


else if @pais = 3 begin --Colombia  
  if @lon < 7 or @lon = 9 or (@lon = 10 and  left(@telTemp,1) <> ''3'') or (@lon = 11 and  left(@telTemp,2) <> ''03'') begin
    select 1 as res, @telTemp as tel --Longitud Invalida
    return(0)
  end
  select @tel = dbo.Completa_ListaNegra(@tel)

  if (len(@tel) in(8 ,10) ) and left(@tel,1) <> ''E'' begin
    if (select dbo.ValidateBlackListPhone(@tel,@Camp,@calKey))=1 begin
      select 4 as res, @tel as tel --blackList      
    end
    else begin
      select @tel=dbo.verifica2(@tel,@pais,@ld)
      if left(@tel,1)=''E'' begin
        select 3 as res, @telTemp --Not existsFound
      end
      select 0 as res, @tel  as tel     
    end   
  end
  else begin
    select 2 as res, @telTemp as tel --Digitos incorrectos
  end 
  return(0)
end

else if @pais = 4 begin--USA 
  exec ccsp_LimpiaUsa @tel, @Camp,@calKey
  return(0)
end

else if @pais = 5 begin--Chile  
  select @tel = dbo.Completa_ListaNegra(@tel)
  if len(@tel) in(8,9) and left(@tel,1) <> ''E'' begin
    if (select dbo.ValidateBlackListPhone(@tel,@Camp,@calKey))=1 begin
      select 4 as res, @tel as tel --blackList      
    end
    else begin
      select @tel=dbo.verifica2(@tel,@pais,@ld)
      if left(@tel,1)=''E'' begin
        select 3 as res, @telTemp --Not existsFound
      end
      select 0 as res, @tel  as tel     
    end   
  end
  else begin
    select 2 as res, @telTemp as tel --Digitos incorrectos
  end 
  return(0)
end
else if @pais = 6 begin--Venezuela    
  select @tel = dbo.Completa_ListaNegra(@tel)

  if len(@tel) = 10 and left(@tel,1) <> ''E'' begin
    if (select dbo.ValidateBlackListPhone(@tel,@Camp,@calKey))=1 begin
      select 4 as res, @tel as tel --blackList      
    end
    else begin
      select @tel=dbo.verifica2(@tel,@pais,@ld)
      if left(@tel,1)=''E'' begin
        select 3 as res, @telTemp --Not existsFound
      end
      select 0 as res, @tel  as tel     
    end   
  end
  else begin
    select 2 as res, @telTemp as tel --Digitos incorrectos
  end 
  return(0)
end

else if @pais = 7 begin--Reino Unido
  select @tel = dbo.Completa_ListaNegra(@tel)

  if (len(@tel) in( 9 ,10) ) and left(@tel,1) <> ''E'' begin
    if (select dbo.ValidateBlackListPhone(@tel,@Camp,@calKey))=1 begin
      select 4 as res, @tel as tel --blackList      
    end 
    else begin
      select @tel=dbo.verifica2(@tel,@pais,@ld)
      if left(@tel,1)=''E'' begin
        select 3 as res, @telTemp --Not existsFound
      end
      select 0 as res, @tel  as tel     
    end   
  end 
  else begin
    select 2 as res, @telTemp as tel --Digitos incorrectos
  end 
  return(0)
end

else if @pais = 8 begin--Arabia saudita   
  select @tel = dbo.Completa_ListaNegra(@tel)

  if (len(@tel) in( 9 ,10, 11 ))
  begin
    if (select dbo.ValidateBlackListPhone(@tel,@Camp,@calKey))=1 begin
      select 4 as res, @tel as tel --blackList      
    end
    else begin
      select @tel=dbo.verifica2(@tel,@pais,@ld)
      if left(@tel,1)=''E'' begin
        select 3 as res, @telTemp --Not existsFound
      end
      select 0 as res, @tel  as tel     
    end   
  end
  else begin
    select 2 as res, @telTemp as tel --Digitos incorrectos
  end 
  return(0)
end

else if @pais in(9,10,11,12,13,14,15,16) begin--9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:España, 15:Peru, 16: Panama 
  select @tel = dbo.Completa_ListaNegra(@tel)
  if left(@tel,1)=''E'' begin
    select 1 as res, @telTemp --Longitud Invalida   
  end
  else if (select dbo.ValidateBlackListPhone(@tel,@Camp,@calKey))=1 begin
      select 4 as res, @tel as tel --blackList      
  end
  else begin
    select @tel=dbo.verifica2(@tel,@pais,@ld)
    if left(@tel,1)=''E'' begin
      select 2 as res, @telTemp --Digitos Incorrectos ??? debe ser numero no existe
    end
    select 0 as res, @tel  as tel     
  end
  return(0) 
end
'
    EXEC(@Sql)


    set @process = 'CW-2152 Alter SP spInsertCall'
        set @Sql= 'ALTER PROCEDURE [dbo].[spInsertCall]
@Pto smallint,
@DNIS varchar(14),
@ANI as varchar(14),
@inbound_id smallint=0,
@IVR_id int = 0, --Id del IVR
@CALLDATA as varchar(1275) = ''''
AS
declare @dni_id as smallint
declare @cal_id as int
declare @datacall as varchar(100)

select @Ani = left(rtrim(ltrim(@ANI)), 13)
select @DNIS = rtrim(ltrim(@DNIS))

  --busca dni_id
  select @dni_id = isnull ( ( select dni_id From ccDNIS Where dni_numero =  @DNIS and dni_status = 1 ), 0)
  
  --busca especialidad
  IF @inbound_id =0 and @dni_id >0
    select @Inbound_id=ED.Inbound_id from ccInboundDnis ED where ED.dni_id = @dni_id
  
  INSERT ccCallsIN ( cal_ANI, dni_id, cal_puerto, cal_Inicio, inbound_id, IVR_id )
  VALUES ( @ANI, @dni_id, @Pto, getdate(), @inbound_id, @IVR_id )

  select @cal_id = scope_identity()

  IF @inbound_id > 0 
  BEGIN
    insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
    select idwg, @cal_id, 0 as user_id, getdate() timestamp, 0 as tipo from ccRIACampEspWG wg   
    where wg.tipo = 0 and wg.IdCampEsp = @Inbound_id

  END

  IF @CALLDATA <> ''''  BEGIN -- Transfer Reminder
    set @CALLDATA=SUBSTRING(@CALLDATA,0,len(@CALLDATA)-2)
    insert into DataCallIn (CallId, Data, Description) 
    select @cal_id,value,''Dato ''+cast(id as varchar(max)) from dbo.[fn_RIASplitDelimited](@CALLDATA,''~'')
  END

  Select @cal_id as IDCall, @dni_id as IDdnis'
        EXEC(@Sql)


  set @process = 'CW-2393 ETIQUETAS EN PORTUGUES Permitir el valor 2 que es portugués en base de datos ccsp_RIAccSettingsConfig -- Version BD 119.122 -- '
      set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
@command tinyint,
@setting_id smallint = null,
@value varchar(200) = null
AS
set nocount on
declare @idioma tinyint
declare @activeChat tinyint
select @idioma=valor from ccSettings where setting_id=27
Select @activeChat=valor from ccSettings where setting_id=145
if @command=0
  begin
  SELECT case @idioma when 0 then descripcion 
            when 1 then [description]
            else DescripcionPT end descripcion
  FROM ccSettings WITH(NOLOCK, index(PK_ccSettings)) WHERE setting_id=@setting_id
  order by descripcion
  return(0)
  end

if @command=1
  begin
  Select setting_id, case @idioma  
            when 0 then descripcion 
            when 1 then [description]
            else DescripcionPT end descripcion,valor, tipo,validate
  from ccSettings WITH(NOLOCK, index(PK_ccSettings)) where tipo in (''AGT'',''ADM'',''GRL'',''REP'',''SV'')
  and (setting_id not in (139,140,141)
  or   setting_id     in (139,140,141) and @activeChat > 0)
  order by tipo, descripcion
  return(0)
  end

if @command=2
  begin
  if @setting_id = 27 and @value not in(''0'',''1'',''2'') begin
    set @value = 0
  end
  else if @setting_id = 104 and @value not in(''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'',''10'',''11'',''12'',''13'',''14'',''15'',''16'') begin
    set @value = 1
  end
  update ccSettings set valor=@value where setting_id = @setting_id
  return(0)
  end
set nocount off'
      EXEC(@Sql)

      set @process = 'CW-2431 --ALTER SP ccsp_RIAConfEspec Add hasMessageMail'
        set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
@User_id int
AS
set nocount on
/****
Conexion Info Email In
  protocol|server|ssl|port|cleanMail|revisionTime
Conexion Info Email Out
  serverOut|portOut|tls|sslOut
Conexion Info Twitter
  usuarioID|token|tokenSecret|time|daysTwitterRecord
***/
select  A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat mode, A.inactiveChatTime, A.maxChats, isnull(A.chatDomain,'''') chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
isnull(A.startStopRecording,0) startStopRecording
,isnull(B.name,'''') as nameMail,isnull(B.conexionInfo,'''') as conexionInfo,isnull(B.connUser,'''') as connUser,
isnull(B.ConnPass,'''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage,
isnull(B.IsActive,0) as Active, isnull(B.answerTimeOut,0) as answerTimeOut,
case when A.cam_id > 0   and C.callsBySurvey=3 then A.callBackSurveyAgent else 0 end callBackSurveyAgent,
case when A.cam_id > 0  and C.callsBySurvey=3 then A.callBackSurveyClient else 0 end callBackSurveyClient,
case when A.cam_id > 0  and C.callsBySurvey=3 then 1 else 0 end isRelationSurvey,
isnull(A.agts_notavailable,'''') as agts_notavailable,
isnull(nameTwitter,'''') nameTwitter,isnull(userTwitter,'''') userTwitter,isnull(numMessagesTwitter,3) numMessagesTwitter,
isnull(timeAlertMessageTwitter,10) timeAlertMessageTwitter,isnull(ActiveTwitter,0) ActiveTwitter,isnull(answerTimeOutTwitter,10) answerTimeOutTwitter,
--usuarioID|token|tokenSecret|time|daysTwitterRecord
isnull(conexionInfoTwitter,''usuarioID|token|tokenSecret|1|0'') conexionInfoTwitter
,isnull(closeConversationTimeTwitter,3) closeConversationTimeTwitter,isnull(closeConversationTime,3) closeConversationTimeEmail
,isnull(A.editableDtmf,0) as editableDtmf
,isnull(gra.graphic_id,1) as frame
,isnull(A.prefijo,'''') as prefijo
,isnull(Conv.hasMessage,0) as hasMessageMail
from ccInbound A
left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
left join ContactMeanIn B on A.inbound_id=B.inboundId and B.meanContactTypeId=1
left join ccCamps C on C.cam_id=A.cam_id
left join(

select GP.inboundId,case when count(*)>0 then 1 else 0 end hasMessage 
 from (
  select A.inboundId, A.conversationId, max(B.messageId) messageId  from conversation A 
  inner join message B  on A.conversationId = B.conversationId  where A.isFinished=0
    GROUP BY A.inboundId,A.conversationId
  ) GP
inner join message M on GP.messageId=M.messageId and messageStatusId not in(6,10,11,12,13)
group by inboundId

)  Conv on Conv.inboundId=A.inbound_id


left join (
select D.inboundId,
D.name as nameTwitter,D.connUser as userTwitter,D.numMessages as numMessagesTwitter,
D.timeAlertMessage as timeAlertMessageTwitter,
D.IsActive as ActiveTwitter, D.answerTimeOut as answerTimeOutTwitter,D.conexionInfo as conexionInfoTwitter,
closeConversationTime as  closeConversationTimeTwitter
from ContactMeanIn D
where D.meanContactTypeId=2) D on A.Inbound_id=D.inboundId
where A.inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 4)
)


return(0)
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
