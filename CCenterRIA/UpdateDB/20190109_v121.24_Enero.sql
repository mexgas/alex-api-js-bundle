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
