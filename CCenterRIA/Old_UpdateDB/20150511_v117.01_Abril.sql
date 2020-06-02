/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2014/10/06
Description:
	update ------ ccmenus
	DROP ------- IX_ccAgendaListaNegra ON ccAgendaListaNegra
	Alter ------- Drop Column idagenda
	CREATE ------- IX_ccAgendaListaNegra ON ccAgendaListaNegra
	Alter ---- ccAgendaListaNegra
	exec sp_rename ---- ccAgendaListaNegra
	update ccsettings -- Description version
	Alter Funcion --Completa
	Alter SP -- ccsp_getVersion  se modifica sp para agregar al setting 77 la version de fix
	Alter SP -- ccsp_RIABlackListCamp
	Alter SP -- ccsp_AplicaListaNegra

Database: CCenterRia
Required version: 116

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
set @version = 118  y  ccsp_getVersion 'BD' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 118 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion 'BDF' se tendra que tener cuidado con las versiones ya que */

set @version = 117
set  @versionfix = 1

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL =valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@version,'.') where id=4;

if @actualVersion = @version and @actualVersionFix = @versionfix -1
	begin
		begin tran
		begin try

	set @process = 'update ------- ccmenus  Description'
	set @sql = 'update ccmenus set menu_descrip=''Carga|Import'',ordengral=40 where type=1 and menu_id=23
update ccmenus set menu_descrip=''Catálogo|Management'',ordengral=41 where type=1 and menu_id=24'
	EXEC(@sql)

	set @process = 'DROP ------- IX_ccAgendaListaNegra ON ccAgendaListaNegra '
	set @sql = 'DROP INDEX IX_ccAgendaListaNegra ON ccAgendaListaNegra'
	EXEC(@sql)

	set @process = 'Alter ------- Drop Column idagenda '
	set @sql = 'Alter Table ccAgendaListaNegra Drop Column idagenda'
	EXEC(@sql)


	set @process = 'Alter ---- ccAgendaListaNegra'
	set @sql = 'Alter Table ccAgendaListaNegra Add idagendaNew Int Identity(1,1)'
	EXEC(@sql)


	set @process = 'exec sp_rename ---- ccAgendaListaNegra'
	set @sql = 'exec sp_rename ''ccAgendaListaNegra.idagendaNew'', ''idagenda'',''Column'' '
	EXEC(@sql)

	set @process = 'CREATE ------- IX_ccAgendaListaNegra ON ccAgendaListaNegra '
	set @sql = 'CREATE NONCLUSTERED INDEX IX_ccAgendaListaNegra ON dbo.ccAgendaListaNegra
 (
	 idagenda
 ) WITH( PAD_INDEX = OFF, FILLFACTOR = 100, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	EXEC(@sql)

	set @process = 'update ccsettings -- Description version'
	set @sql = 'update ccsettings set detalle=''Version de base de datos, administrador, agente y fix de Centerware - de separa por puntos de la siguiente manera DB.Admin.Agent.fix'' where setting_id=77'
	EXEC(@sql)

	set @process = 'Alter ------function Completa '
	set @sql = ' ALTER function [dbo].[Completa](@Cadena varchar(32))
RETURNS varchar(32)
AS
BEGIN
declare @resultado varchar(32)
declare @ld varchar(5)
declare @pais varchar(2)

select @pais = valor from ccSettings where setting_id = 104
select @ld = valor from ccSettings where setting_id = 17
select @resultado = dbo.limpia(@Cadena)

--Completa 1:México 2:Argentina 3:Colombia 4:USA 5:Chile 6: venezuela 7: UK 8: arabia saudita 9: Australia 10:Brasil 11:Guatemala
if @pais = 1
 begin
	--Empieza Mexico
	select @resultado = case
	 when (len(@resultado)=8 and len(@ld)=2) or (len(@resultado)=7 and len(@ld)=3) then @resultado
	 when len(@resultado)=10 then
	   case when left(@resultado, len(@ld)) = @ld
		then right(@resultado, 10 - len(@ld)) else ''01'' + @resultado end
	 when len(@resultado)=12 then
	   case when left(@resultado, 2) = ''01'' then
		 case when substring(@resultado, 3, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	 when len(@resultado)=13 then
	   case when left(@resultado, 3) in (''044'', ''045'') then
		 case when substring(@resultado, 4, len(@ld)) = @ld then
		   ''044'' + right(@resultado, 10) else ''045'' + right(@resultado, 10)
		 end
	   else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	--Termina Mexico
	return @resultado
 end

if @pais = 2
 begin
	-- Empieza Argentina
	select @resultado = case
	 when (len(@resultado)=7 and len(@ld)=3) or (len(@resultado)=6 and len(@ld)=4) then
		@resultado
	-- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
	-- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
	 when len(@resultado) = 8 then
		case when len(@ld) = 4 then
			case when left(@resultado,2) = ''15'' then @resultado end
		else
			case when len(@ld) = 2 then @resultado end
		end
	-- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
	 when len(@resultado)=9 then
		case when left(@resultado, 2) = ''15'' then @resultado else ''E_NV_Cel'' end
	-- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
	 -- Si es diferente se le agrega un 0 para llamadas de larga distancia
	 when len(@resultado)=10 then
	   case when left(@resultado, len(@ld)) = @ld
		then right(@resultado, 10 - len(@ld)) else
			case when left(@resultado,2) = ''15'' then @resultado else ''0'' + @resultado end
	   end
	-- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
	-- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
	 when len(@resultado)=11 then
	   case when left(@resultado, 1) = ''0'' then
		 case when substring(@resultado, 2, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	-- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
	-- si no es local se le agrega el 0 y se marca el numero
	 when len(@resultado)=12 then
		case when left(@resultado, len(@ld)) = @ld then
			case when substring(@resultado, len(@ld) + 1, 2) = ''15'' then
				right(@resultado,12 - len(@ld)) else ''E_NV_Cel'' end else ''0'' + @resultado end
	-- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
	 when len(@resultado)=13 then
		case when left(@resultado, 1) = ''0'' then
			case when substring(@resultado, 2, len(@ld)) = @ld then substring(@resultado, len(@ld) + 2, 12 - len(@ld)) else @resultado end
		else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	--Termina Argentina
	return @resultado
 end

if @pais = 3
 begin
	--Empieza colombia
	select @resultado = case
	--Si son 7 digitos, se regresa igual
	 when len(@resultado)=7 then
		@resultado
	--Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
	 when len(@resultado) = 8  then
		case when left(@resultado,1) = @ld then right(@resultado,7) else @resultado end
	-- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
	 when len(@resultado)=10 then
		case when left(@resultado,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then ''0'' + @resultado
		else
			''E_NV_Cel''
		end
	--Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
	--prefijo de celular
	 when len(@resultado)=11 then
		case when left(@resultado,1)=''0'' then
			case when substring(@resultado,2,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then @resultado else ''E_NV_Cel'' end
		else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	-- Termina Colombia
	return @resultado
 end

if @pais = 4
 begin
	--Empieza USA
	select @resultado = case len(@resultado)
	 when 3 then
		case @resultado when ''911'' then @resultado else ''E_NV_Longitud'' end
	 when 7 then @resultado
	 when 10 then
	   case when left(@resultado, len(@ld)) = @ld
		--then right(@resultado, 10 - len(@ld)) else ''1'' + @resultado end  En USA siempre se marcan 10 numeros ya sin el 1, el 1 provoca que no cuadre el numero telefonico con los de lista negra
		then right(@resultado, 10 - len(@ld)) else @resultado end
	 when 11 then
	   case when left(@resultado, 1) = ''1'' then
		 case when substring(@resultado, 2, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	else ''E_NV_Longitud'' end

	--Termina USA
	return @resultado
 end

if @pais = 5
 begin
	select @resultado = case len(@resultado)
	 when 6 then @resultado
	 when 7 then @resultado
	-- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
	 when 8 then

		case when @ld = left(@resultado,len(@ld)) then right(@resultado,8-len(@ld)) else
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

-- Venezuela
if @pais = 6 begin
	select @resultado = case len(@resultado)
		when 7 then @resultado
		when 10 then ''0'' + @resultado
		when 11 then
			case when left(@resultado,1) = ''0'' then @resultado else ''E_NV_Longitud'' end
		else
	    ''E_NV_Longitud'' end
end
--Termina Venezuela

-- UK
if @pais = 7 begin
	select @resultado = case len(@resultado)
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
end
-- Termina UK

if @pais = 8 begin -- arabia saudita
	select @resultado = case len(@resultado)
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
end -- arabia saudita

if @pais = 9 --Australia
begin
	select @resultado = case len(@resultado)
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
end


if @pais = 10 --Brasil
begin

	select @resultado = case len(@resultado)
--llamada local fijo o celular
	when 8 then @resultado
    when 9 then @resultado
	when 10 then  -- Numero nacional
		case when left(@resultado, 2) = @ld
			then right(@resultado,8) else @resultado end
	when 11 then	-- Este caso solomente es para numero celular
			case when left(@resultado, 2) = @ld
				 then right(@resultado,9) else @resultado end
	when 12 then	-- llamadas por cobrar local
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

end

if @pais = 11 --Guatemala
begin
	if len(@resultado)=8
		begin
			if charindex(substring(@resultado,1,1),''2,3,4,5,6,7'') <= 0
				select @resultado = ''E_'' + @resultado
		end
	else
		select @resultado = ''E_NV_Longitud''
end


-- Termina
return @resultado

end'
	EXEC(@sql)


	set @process = 'sp ccsp_getVersion'
	set @sql='ALTER procedure [dbo].[ccsp_getVersion]
@Module varchar(3) = null,
@Version int = 0 output
as
set nocount on
declare @Idioma bit
select @Idioma = cast(valor as bit) from ccSettings where setting_id = 27

if upper(isnull(@Module, '''')) not in (''BD'', ''ADM'', ''AGT'', ''ALL'', ''BDF'')
 begin
	select ''-2'' ID, case @Idioma when 0 then ''ERROR. Modulo no valido''
	else ''ERROR. Invalid Module'' end [Description]
	return(0)
 end

declare @nVersion varchar(30)
select @nVersion = cast(valor as varchar(15)) from ccSettings where setting_id = 77

BEGIN TRY
	declare @version_1 varchar(15), @version_2 varchar(9), @version_3 varchar(6), @version_4 varchar(2)
	declare @Prueba table
	 (id int,
	  value nvarchar(100)
	 )
	 insert into @Prueba
		 select * from  fn_RIASplitDelimited (@nVersion,''.'')

	 IF not exists (select value from @Prueba where id = 4) begin

		update ccsettings
		set valor = valor +''.00''
		where setting_Id = 77

		insert into @Prueba (value)
		values(''00'')
	 end

END TRY

BEGIN CATCH
	select ''-1'' ID, ERROR_MESSAGE() [Description]
	return(0)
END CATCH

if isnull(@Version, 0) = 0
 begin

	select @version_1 = value from @Prueba where id = 1
	select @version_2 = value from @Prueba where id = 2
	select @version_3 = value from @Prueba where id = 3
	select @version_4 = value from @Prueba where id = 4

	if upper(@Module) = ''ALL'' or upper(@Module) = ''BDF'' begin
		if  upper(@Module) = ''ALL''
			select @version_1 + ''.'' + @version_2 + ''.'' + @version_3+''.''+ @version_4
		else if  upper(@Module) = ''BDF''
			select @version_1 + ''.'' + @version_4

		return(0)
	end
	else
		select @version = cast(case upper(@Module) when ''BD'' then @version_1
		when ''ADM'' then @version_2 when ''AGT'' then @version_3 end as int)
		select @version Version
		return(@version)

 end

--return

if upper(@Module) = ''BD'' and (@Version <= cast(@version_1 as int) or (@Version - cast(@version_1 as int))>1)
 begin
	select ''-3'' ID, case @Idioma when 0
	then ''ERROR. Version no Valida para BD. Version Actual: '' + @version_1
	else ''ERROR. Invalid Version for BD. Current Version: '' + @version_1
	end [Description]
	return(0)
 end

if @Version <= cast(case upper(@Module) when ''BD'' then @version_1
when ''ADM'' then @version_2 else @version_3 end as int)
 begin
	select ''-3'' ID, case @Idioma when 0
	then ''ERROR. Version no Valida para '' + @Module + ''. Version Actual: '' +
	 case upper(@Module) when ''BD'' then @version_1 when ''ADM'' then @version_2 else @version_3 end
	else ''ERROR. Invalid Version for '' + @Module + ''. Current Version: '' +
	 case upper(@Module) when ''BD'' then @version_1 when ''ADM'' then @version_2 else @version_3 end
	end [Description]
	return(0)
 end



	select @version_1 = value from @Prueba where id = 1
	select  @version_2 =value from @Prueba where id = 2
	select @version_3 = value from @Prueba where id = 3
	select @version_4 = isnull(max(value),0) from @Prueba where id = 4


if upper(@Module) = ''BD'' set @version_1 = @Version
else if upper(@Module) = ''ADM'' set @version_2 = @Version
else if upper(@Module) = ''AGT'' set @version_3 = @Version
else set @version_4 = @Version

set @nVersion = @version_1 + ''.'' + @version_2 + ''.'' + @version_3 + ''.'' + @version_4
update ccSettings set valor = @nVersion where setting_id = 77


if @@rowcount = 1
	select ''0'' ID, ''Actualizado a version: '' + @nVersion [Description]

else
	select ''-4'' ID, case @Idioma when 0
	then ''ERROR generado al actualizar a version '' + @nVersion
	else ''ERROR introduced when upgrading to version '' + @nVersion
	end [Description]

return (0)
set nocount off'
	EXEC(@sql)


	set @process = 'ALTER ccsp_GetAgentIndividualCounters '
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters] @type as int, @sup_id as int = 0 as
set nocount on

declare @fecha_ini datetime
select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

if @type = 1 --Session time
	begin
		SELECT User_id, case
			WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0
				THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))
			ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) +
				convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
			END as logintime
		FROM ccLogLogin a with(index(IX_ccLogLogin_4)), ccGenViewRelsSupsAgent b
		where fecha >= @fecha_ini
		and a.User_id = b.agt
		and b.sup = @sup_id
		GROUP BY User_id
	end

if @type = 2 --Status agent
	begin
		SELECT User_id, TipoStatusAge_id, sum(tStatus) As segundos
		FROM ccLogAgentesDia a with(index(IX_ccLogAgentesDia_4)), ccGenViewRelsSupsAgent b
		WHERE fecha >= @fecha_ini
		AND a.User_id = b.agt
		and b.sup = @sup_id
		GROUP BY User_id, TipoStatusAge_id
		ORDER BY User_id
	end

if @type = 3
	begin

        select calls.user_id, calls.total_calls, calls.type_calls, users.login, calls.nCalls, calls.tDialog, calls.tWrapup, calls.tHold
		from ccusers As users ,
        (
			SELECT User_id AS ''user_id'' , count(*) AS ''total_calls'',
			CASE
			  WHEN statuscall_id = 15 THEN 5  --OutBound Asignada pero no contestada
			  WHEN cal_manual = 2 THEN 3      --OutBound llamada manual
			  ELSE 2                          --Llamada de OutBound
			END AS ''type_calls'',
			count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
			sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end) tDialog,
			sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end) tWrapup,
			sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold
			FROM ccoCallsOut a WITH (NOLOCK index(IX_ccoCallsOut_10)) , ccGenViewRelsSupsAgent b
			WHERE a.User_id = b.agt
			and b.sup = @sup_id
			AND statuscall_id <> 11  --OutBound sin estado definitivo
			AND cal_inicio >= @fecha_ini
			GROUP BY User_id, statuscall_id, cal_manual

			UNION

			SELECT User_id AS ''user_id'' , count(*) AS ''total_calls'',
			CASE
			  WHEN statuscall_id = 15 THEN 4  --InBound Asignada pero no contestada
			  ELSE 1                          --Llamada de InBound
			END AS ''type_calls'',
			count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
			sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end) tDialog,
			sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end) tWrapup,
			sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold
			FROM ccCallsIn a WITH (NOLOCK index(IX_ccCallsIn_5)), ccGenViewRelsSupsAgent b
			WHERE a.User_id = b.agt
			and b.sup = @sup_id
			AND statuscall_id <> 11  --InBound sin estado definitivo
			AND cal_inicio >= @fecha_ini
			GROUP BY User_id, statuscall_id
        ) AS calls
        where users.user_id = calls.user_id

	end

if @type = 4
	begin
        select a.user_id, a.login
        from ccusers a, ccGenViewRelsSupsAgent b
		where user_id = b.agt
		and b.sup = @sup_id
    end

set nocount on'
	EXEC(@sql)

	set @process = '--------- procedure ccsp_RIABlackListCamp'
	set @sql = 'ALTER PROCEDURE dbo.ccsp_RIABlackListCamp
@Type smallint,
@IDArea smallint = 0,
@CamID SmallInt = 0,
@InsertSchedule_id varchar(max) = ''0'',
@DeleteSchedule_id varchar(max) = ''0'',
@User_id int = null
as
set nocount on

if @Type = 1 -- Cat_BList
 begin
	Select idtipolista as ID, tipolista as TIPO from cctiposlistanegra where Status= 1 order by 2
	return(0)
 end

if @Type = 2 -- Cat_Camps
 begin
	Select c.cam_id as ID, c.cam_descripcion TIPO
	from ccCamps c join ccRIACat_Areas a on c.IDArea = a.IDArea
	where c.cam_id in (select cam_id from dbo.fGet_CampAcd_Area(@User_id, 1))
	order by 2
	return(0)
 end

if @Type = 3 -- Relacion Camps vs BList
 begin
	select cl.cam_id, ca.cam_descripcion, cl.idtipolista blist_id, tl.Tipolista list_description
	from Camplistanegra cl join ccCamps ca on cl.cam_id = ca.cam_id
	 join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
	where cl.status = 1 and cl.cam_id = @CamID
	order by 1, 3
	return(0)
 end

if @Type = 4 -- Inserta BList
 begin

	if @CamID = 0
	 begin
		update Camplistanegra set status = 1 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))

		insert into Camplistanegra (idtipolista, cam_id, status)
		select FN.value, C.cam_id, 1 from ccCamps C, dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','') FN where C.IDArea = @IDArea
		and C.cam_id not in (select CL.cam_id from Camplistanegra CL join dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','') FN
		on CL.idtipolista = FN.value where CL.status = 1)
		return(0)
	 end

 	update Camplistanegra set status = 1 where cam_id = @CamID
	and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))

	insert into Camplistanegra (idtipolista, cam_id, status)
	select value, @CamID, 1 from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')
		where value not in (select idtipolista from Camplistanegra where cam_id = @CamID and status = 1
		and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')))

	Insert Into ccAgendaListaNegra (campsid,fecharegs,fechaaplicar) values (@CamID,''20100101'',getDate()) -- El 2010 es para que quite registros viejos con base en el cal fecha dial de ccocallsoutsource, principalmente para quitar callbacks de numeros cargados hace mucho tiempo

	declare @idAgenda as int
	select @idAgenda = SCOPE_IDENTITY()

	insert into ccAgenda_TipoListaNegra(idAgenda,idtipolista)
	select @idAgenda, value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')

	return(0)
 end

if @Type = 5 -- Elimina BList
 begin
	if @CamID=0
	 begin
		update Camplistanegra set status = 0 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, '',''))
		return(0)
	 end

	update Camplistanegra set status = 0 where cam_id = @CamID	and idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, '',''))

	return(0)
 end

if @Type = 6 -- Regresa la lista de Areas
 begin
	if isnull(@User_id, 0) = 0 or (select login from ccusers
 where User_id = @User_id) = ''root''
	 begin
		select IDArea, AreaName from ccRIACAT_Areas order by AreaName
		return(0)
	 end

	select u.IDArea, a.AreaName
	from ccRIACAT_Areas a join ccusers u on u.IDArea = a.IDArea
	where u.User_id = @User_id
	order by AreaName
	return(0)
 end

if @Type = 7 -- trae las listas negras de la campaña
 begin
	select cl.cam_id, ca.cam_descripcion, cl.idtipolista blist_id, tl.Tipolista list_description
	from Camplistanegra cl join ccCamps ca on cl.cam_id = ca.cam_id
	 join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
	where cl.status = 1 and cl.cam_id = @CamID
	order by 1, 3
	return(0)
 end

return(0)
set nocount off

'
	EXEC(@sql)

	set @process = '-----PROCEDURE ccsp_AplicaListaNegra'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AplicaListaNegra]
--@idcampana as varchar(10),
--@fechacal as datetime
AS

declare @ld varchar(4)
declare @idagenda  int
declare @campsid int
declare @fechacal datetime
declare @Listid int

SET NOCOUNT ON

CREATE TABLE [dbo].[#mycamps] (
	[campsid] [int] NULL
) ON [PRIMARY]

select top 1 @idagenda = idagenda, @campsid = campsid, @fechacal=fecharegs   from ccagendalistanegra where status= 1 and fechaaplicar < getdate() order by fechaaplicar asc
IF @idagenda is not  null
BEGIN

select top 1 @Listid = idtipolista from ccagenda_tipolistanegra where idagenda = @idagenda order by idtipolista asc

update ccagendalistanegra set inicio=getdate() where idagenda=@idagenda

insert #mycamps
select  campsid  from ccagendalistanegra where idagenda=@idagenda and  status= 1 and fechaaplicar < getdate() order by fechaaplicar asc

CREATE TABLE [dbo].[#mytemp] (
	[callout_id] [int] NULL,
             [telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
             [idtipolista] [int] NULL
) ON [PRIMARY]

--CREATE  UNIQUE  INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) ON [PRIMARY] -- Nunca usa el callout id y siempre se trunca por telefono.

select @ld = valor from ccSettings where setting_id = 17

-----------------------------------------------------------------------------  telefono1

IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	---Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where  cal_fechadial >  @fechacal
           END
           ELSE
           BEGIN
              insert #mytemp
	---Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END

-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
delete ccoWOrkingTable
from ccoWOrkingTable wt inner join ccoCallsOutSource cs
on wt.callout_id = cs.callout_id
inner join #mytemp t
on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono= wt.cal_telefono and  rtrim(left(ltrim(            cs.cal_telefono2 + ''         ''
							 + cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono =
rtrim(left(ltrim(            cs.cal_telefono2 + ''         ''
							 + cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt
on cs.callout_id = wt.callout_id
inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono1 de CS
update ccoCallsOutSource set cal_telefono = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp


----------------------------------------------------------------------------------- -telefono 2
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono2 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
             insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono2 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono2 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono2 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END

-- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
delete ccoWOrkingTable
from ccoWOrkingTable wt inner join ccoCallsOutSource cs
on wt.callout_id = cs.callout_id
inner join #mytemp t
on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono2= wt.cal_telefono and rtrim(left(ltrim(            cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono =
rtrim(left(ltrim(            cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt
on cs.callout_id = wt.callout_id
inner join #mytemp t
on cs.callout_id = t.callout_id

where cs.cal_fechadial > @fechacal and cs.cal_telefono2= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono2 de CS
update ccoCallsOutSource set cal_telefono2 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 3
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono3 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono3 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono3 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono3 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable
from ccoWOrkingTable wt inner join ccoCallsOutSource cs
on wt.callout_id = cs.callout_id
inner join #mytemp t
on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono3= wt.cal_telefono  and  rtrim(left(ltrim(            cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono =
rtrim(left(ltrim(             cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt
on cs.callout_id = wt.callout_id
inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono3= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono3 de CS
update ccoCallsOutSource set cal_telefono3 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 4
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono4 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono4 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono4 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono4 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable
from ccoWOrkingTable wt inner join ccoCallsOutSource cs
on wt.callout_id = cs.callout_id
inner join #mytemp t
on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono4= wt.cal_telefono and  rtrim(left(ltrim(            cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono =
rtrim(left(ltrim(            cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt
on cs.callout_id = wt.callout_id
inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono4= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono4 de CS
update ccoCallsOutSource set cal_telefono4 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 5
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono5 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono5 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono5 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono5 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable
from ccoWOrkingTable wt inner join ccoCallsOutSource cs
on wt.callout_id = cs.callout_id
inner join #mytemp t
on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono5= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono5 de CS
update ccoCallsOutSource set cal_telefono5 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp
truncate table #mycamps

update ccagendalistanegra set termino=getdate() where idagenda=@idagenda
update ccagendalistanegra set status=''0'' where idagenda=@idagenda

END

'
	EXEC(@sql)


			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			--UPDATE settings SET value=@version WHERE id= 77
			exec ccsp_getVersion 'BDF', @versionfix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off