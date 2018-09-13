/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

 
/*
Author: 
		
Date: 2018/09/13
Description:

Release  120.24_20180906

Database: CCenterRia
Required version: 120.14

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

set @version = 120
set @versionfix = 24


/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 22
	begin
		begin tran
		begin try
        	
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
		insert into valueRecord values(''RESTRICT LOCAL CALLS (OFF)'',	''RESTRINGIR LLAMADAS LOCALES (DESACTIVADO)'',	''RESTRICT LOCAL CALLS (DISABLED)'',	''RESTRINGIR AS CHAMADAS LOCAIS (DESATIVADO)'');
	end'
	EXEC(@Sql)

	set @process = 'CW-1501 Version 120.24'
    	set @Sql= 'if not exists (select * from valueRecord where valueT=''RESTRICT LD CALLS (OFF)'')
	begin
		insert into valueRecord values(''RESTRICT LD CALLS (OFF)'',	''RESTRINGIR LLAMADAS DE LD (DESACTIVADO)'',	''RESTRICT LD CALLS (DISABLED)'',	''RESTRINGIR AS CHAMADAS INTERURBANAS (DESATIVADO)'');
	end'
	EXEC(@Sql)

	

	set @process = 'CW-1501 Version 120.24'
    	set @Sql= 'if not exists (select * from valueRecord where valueT=''RESTRICT CEL CALLS (OFF)'')
	begin
		insert into valueRecord values(''RESTRICT CEL CALLS (OFF)'',	''RESTRINGIR LLAMADAS A CELULAR (DESACTIVADO)'',	''RESTRICT CELL PHONE CALLS (DISABLED)'',	''RESTRINGIR AS CHAMADAS AO CELULAR (DESATIVADO)'');
	end'

	EXEC(@Sql)


	set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''RESTRICT CEL CALLS (ON)'')
	begin
		insert into valueRecord values(''RESTRICT CEL CALLS (ON)'', ''RESTRINGIR LLAMADAS A CELULAR (ACTIVADO)'',	''RESTRICT CELL PHONE CALLS (ENABLED)'',	''RESTRINGIR AS CHAMADAS AO CELULAR (ATIVADO)'');
	end'

	EXEC(@Sql)


	set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''RESTRICT LD CALLS (ON)'')
	begin
		insert into valueRecord values(''RESTRICT LD CALLS (ON)'',	''RESTRINGIR LLAMADAS DE LD (ACTIVADO)'',	''RESTRICT LD CALLS (ENABLED)'',	''RESTRINGIR AS CHAMADAS INTERURBANAS (ATIVADO)'');
	end'

	EXEC(@Sql)


	set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''RESTRICT LOCAL CALLS (ON)'')
	begin
		insert into valueRecord values(''RESTRICT LOCAL CALLS (ON)'',	''RESTRINGIR LLAMADAS LOCALES (ACTIVADO)'',	''RESTRICT LOCAL CALLS (ENABLED)'',	''RESTRINGIR AS CHAMADAS LOCAIS (ATIVADO)'');
	end'

	EXEC(@Sql)


	set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''XFERMASK (OFF)'')
	begin
		insert into valueRecord values(''XFERMASK (OFF)'',	''RECIBIR TRANSFERENCIAS (DESACTIVADO)'',	''RECEIVE TRANSFERS (DISABLED)'',	''RECEBER TRANSFERÊNCIAS (DESATIVADO)'');
	end'

	EXEC(@Sql)


	set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''XFERMASK (ON)'')
	begin	
		insert into valueRecord values(''XFERMASK (ON)'',	''RECIBIR TRANSFERENCIAS (ACTIVADO)'',	''RECEIVE TRANSFERS (ENABLED)'',	''RECEBER TRANSFERÊNCIAS (ATIVADO)'');
	end'

	EXEC(@Sql)


	set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''AGT TRANSF. (OFF)'')
	begin
		insert into valueRecord values(''AGT TRANSF. (OFF)'',	''TRANSFERIR A AGENTES (DESACTIVADO)'',	''TRANSFER TO AGENTS (DISABLED)'',	''TRANSFERIR AS CHAMADAS PARA OS AGENTES (DESATIVADO)'');
	end'

	EXEC(@Sql)


	set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''ACD TRANSF. (OFF)'')
	begin
		insert into valueRecord values(''ACD TRANSF. (OFF)'',	''TRANSFERIR A GRUPOS ACD (DESACTIVADO)'',	''TRANSFER TO ACD GROUPS (DISABLED)'',	''TRANSFERIR AS CHAMADAS PARA OS GRUPOS ACD (DESATIVADO)'');
	end'

	EXEC(@Sql)


	set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''EXT TRANSF. (OFF)'')
	begin
		insert into valueRecord values(''EXT TRANSF. (OFF)'',	''TRANSFERIR A NÚMEROS EXTERNOS (DESACTIVADO)'',	''TRANSFER TO EXTERNAL NUMBERS (DISABLED)'',	''TRANSFERIR AS CHAMADAS PARA NÚMEROS EXTERNOS (DESATIVADO)'');
	end'

	EXEC(@Sql)


	set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''MAN TRANSF. (OFF)'')
	begin
		insert into valueRecord values(''MAN TRANSF. (OFF)'',	''TRANSFERIR A NÚMEROS MANUALES (DESACTIVADO)'',	''TRANSFER TO MANUAL NUMBERS (DISABLED)'',	''TRANSFERIR AS CHAMADAS PARA NÚMEROS MANUAIS (DESATIVADO)'');
	end'

	EXEC(@Sql)


	set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''MAN TRANSF. (ON)'')
	begin
		insert into valueRecord values(''MAN TRANSF. (ON)'',	''TRANSFERIR A NÚMEROS MANUALES (ACTIVADO)'',	''TRANSFER TO MANUAL NUMBERS (ENABLED)'',	''TRANSFERIR AS CHAMADAS PARA NÚMEROS MANUAIS (ATIVADO)'');
	end'

	EXEC(@Sql)




	set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''EXT TRANSF. (ON)'')
	begin
		insert into valueRecord values(''EXT TRANSF. (ON)'',	''TRANSFERIR A NÚMEROS EXTERNOS (ACTIVADO)'',	''TRANSFER TO EXTERNAL NUMBERS (ENABLED)'',	''TRANSFERIR AS CHAMADAS PARA NÚMEROS EXTERNOS (ATIVADO)'');
	end'

	EXEC(@Sql)


	set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''ACD TRANSF. (ON)'')
	begin
		insert into valueRecord values(''ACD TRANSF. (ON)'',	''TRANSFERIR A GRUPOS ACD (ACTIVADO)'',	''TRANSFER TO ACD GROUPS (ENABLED)'',	''TRANSFERIR AS CHAMADAS PARA OS GRUPOS ACD (ATIVADO)'');
	end'

	EXEC(@Sql)


		set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''AGT TRANSF. (ON)'')
	begin
		insert into valueRecord values(''AGT TRANSF. (ON)'',	''TRANSFERIR A AGENTES (ACTIVADO)'',	''TRANSFER TO AGENTS (ENABLED)'',	''TRANSFERIR AS CHAMADAS PARA OS AGENTES (ATIVADO)'');
	end'

	EXEC(@Sql)



		set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''Pause and resume recording(OFF)'')
	begin	
		insert into valueRecord values(''Pause and resume recording(OFF)'',	''PAUSAR Y CONTINUAR GRABACIÓN (DESACTIVADO)'',	''PAUSE AND RESUME RECORDING (DISABLED)'',''PAUSAR E RETOMAR A GRAVAÇÃO (DESATIVADO)'');
	end'

	EXEC(@Sql)



		set @process = 'CW-1501 Version 120.24'
    set @Sql= 'if not exists (select * from valueRecord where valueT=''Pause and resume recording(ON)'')
	begin
		insert into valueRecord values(''Pause and resume recording(ON)'',	''PAUSAR Y CONTINUAR GRABACIÓN (ACTIVADO)'',	''PAUSE AND RESUME RECORDING (ENABLED)'',	''PAUSAR E RETOMAR A GRAVAÇÃO (ATIVADO)'');
	end'

	EXEC(@Sql)



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
