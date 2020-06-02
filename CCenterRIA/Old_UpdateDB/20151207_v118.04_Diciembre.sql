/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Perez
Date: 2015/12/15
Description:

-------drop index IX_ccoDialers y IX_ccoDialers_I-------- 
-------CREATE NONCLUSTERED INDEX [IX_ccoDialers]--------
-------CREATE NONCLUSTERED INDEX [IX_ccoDialers_I]-----------
-------alter table ccoDialers
-------ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
-------ALTER PROCEDURE [dbo].[ccsp_ADMDialer]
-------ALTER PROCEDURE [dbo].[ccsp_RIACATDialer]
-------ALTER PROCEDURE [dbo].[ccsp_AplicaListaNegra]
-------ALTER proc [dbo].[ccsp_ccRIACallBack_Queue]
-------ALTER PROCEDURE [dbo].[ccsp_ExtAppsDisposeCall]
-------ALTER procedure [dbo].[ccsp_Limpia]
-------ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
-------ALTER procedure [dbo].[ccsp_OUTInsertaCallBack]
-------ALTER procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]
-------Alter function [dbo].[Completa]
Alter function fnGetTimeZone
Alter function fGet_CampAcd_Area






Database: CCenterRia
Required version: 118.03

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
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 118 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 118--**********actualizar a 118 sin fix
set @versionfix = 4
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


--update  ccsettings
--set valor = '117.87.81.2'
--where setting_id = 77

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and @actualVersionFix = @versionfix -1
	begin
		begin tran
		begin try		

		set @process = 'drop index IX_ccoDialers y IX_ccoDialers_I-------- '
		set @sql='drop index IX_ccoDialers on ccoDialers
				drop index IX_ccoDialers_I on ccoDialers'
		EXEC(@sql)

		set @process = 'alter table ccoDialers------------'
		set @sql='alter table ccoDialers alter column Puerto int not null'
		EXEC(@sql)

			set @process = 'CREATE NONCLUSTERED INDEX [IX_ccoDialers]--------'
		set @sql='CREATE NONCLUSTERED INDEX [IX_ccoDialers] ON [dbo].[ccoDialers] 
			(
				[Puerto] ASC
			)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
			'
		EXEC(@sql)		

		set @process = 'CREATE NONCLUSTERED INDEX [IX_ccoDialers_I]-----------'
		set @sql='CREATE NONCLUSTERED INDEX [IX_ccoDialers_I] ON [dbo].[ccoDialers] 
(
	[dialer_id] ASC,
	[provedor_id] ASC
)
INCLUDE ( [Puerto],
[Descripcion]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
'
		EXEC(@sql)
			

		set @process = 'insert into ccsettings -----------'
		set @sql='if not exists ( select * from ccsettings where setting_id = 177) begin 
			insert into ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
			values(177,'''',''ani global'',1,''ADM'',''se tomara ani global'',''ani was taken overall'',1,''^\d*$'')
			end'
		EXEC(@sql)


		set @process = 'insert ccsettings ----- Credential Replication'
		set @sql='if not exists(select * from ccSettings where setting_id=176)
		insert into ccSettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
values(176,'''',''hostname\UserWindow|passWindow|userSQL|passSQL|hostname'',1,''X'',''Credencial Windows y SQL para replicas'',''Credential Windows y SQL para replication'',1,''.*'')'
		EXEC(@sql)


		set @process = 'Alter function [dbo].[Completa]--------'
		set @sql='Alter function [dbo].[Completa](@Cadena varchar(32), @pais varchar(2) = '''', @ld varchar(5) = '''')
RETURNS varchar(32)
AS
BEGIN
declare @resultado varchar(32)

if (@pais = '''' and @ld = '''')
	begin
		select @pais = valor from ccSettings with(nolock) where setting_id = 104
		select @ld = valor from ccSettings with(nolock) where setting_id = 17
	end
select @resultado = dbo.limpia(@Cadena)

--Completa 1:México 2:Argentina 3:Colombia 4:USA 5:Chile 6: venezuela 7: UK 8: arabia saudita 9: Australia 10:Brasil 11:Guatemala 12:Costa Rica 13:Salvador
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
		then right(@resultado, 10 - len(@ld)) else ''1'' + @resultado end
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

if @pais = 12 --Costa Rica
begin
	if len(@resultado)=8
		begin
			if charindex(substring(@resultado,1,1),''2,3,4,5,6,7,8'') <= 0
				select @resultado = ''E_'' + @resultado
		end
	else if len(@resultado)=10
		begin
			if charindex(substring(@resultado,1,3),''800,900,905'') <= 0
				select @resultado = ''E_'' + @resultado
		end
	else
		begin
			if charindex(substring(@resultado,1,2),''00,08'') <= 0
				select @resultado = ''E_'' + @resultado
		end
end

if @pais = 13 --Salvador
begin
	if len(@resultado)=8
		begin
			if charindex(substring(@resultado,1,1),''2,6,7'') <= 0
				select @resultado = ''E_'' + @resultado
		end
	else
		begin
			if charindex(substring(@resultado,1,2),''00'') <= 0
				select @resultado = ''E_'' + @resultado
		end
end

if @pais = 14 --España
begin
	if len(@resultado)=9
		begin
			if charindex(substring(@resultado,1,1),''5,6,7,8,9'') <= 0
				select @resultado = ''E_'' + @resultado
		end
	else
		begin
			if charindex(substring(@resultado,1,2),''00'') <= 0
				select @resultado = ''E_'' + @resultado
		end
end

-- Termina
return @resultado

end'
		EXEC(@sql)

		set @process = 'ALTER FUNCTION [dbo].[Completa_ListaNegra]-------'
		set @sql='ALTER FUNCTION [dbo].[Completa_ListaNegra] (@Cadena varchar(30))
RETURNS varchar(30) AS
begin
declare @resultado varchar(30), @ld varchar(6), @pais tinyint, @BLActivo tinyint

select @ld=valor from ccSettings with(nolock) where setting_id=17
select @pais = valor from ccsettings with(nolock) where setting_id = 104
select @BLActivo = valor from ccsettings with(nolock) where setting_id = 114

select @resultado=dbo.Completa(@Cadena, @pais, @ld)

if @BLActivo = 1 begin
	if @pais in (1,4)
	 begin
		if left(@resultado, 1)=''E''
			return @resultado

		select @resultado = case
		 when len(@resultado)in(7,8) then @ld + @resultado
		 when @resultado=''911'' OR len(@resultado)=10 then @resultado
		 when len(@resultado) in (11,12,13) then right(@resultado,10)
		 else ''E_NV_Longitud''
		 end

		 return @resultado
	 end

	if @pais = 2
	 begin
		select @resultado = dbo.fnClearPhoneArg(@cadena)
		return @resultado
	 end

	if @pais = 3 and left(@resultado,1) <> ''E''
	 begin
		select @resultado = case
			when len(@resultado) = 7 then @ld + @resultado
			when len(@resultado) in(8,10) then @resultado
			when len(@resultado) = 11 then right(@resultado,10)
			else ''E_NV_Longitud'' end
		return @resultado
	 end

	if @pais = 5 and left(@resultado,1) <> ''E''
	 begin
		select @resultado = case
			when len(@resultado) in (6,7) then @ld + @resultado
			when len(@resultado) in (8,9) then @resultado
			when len(@resultado) = 10 then right(@resultado,9)
			else ''E_NV_Longitud'' end
		return @resultado
	 end

	if @pais = 6 and left(@resultado,1) <> ''E''
	begin
		select @resultado = case
			when len(@resultado) = 7 then @ld + @resultado
			when len(@resultado) = 10 then @resultado
			when len(@resultado) = 11 then right(@resultado,10)
			else ''E_NV_Longitud'' end
		return @resultado
	end

	if @pais = 7 and left(@resultado,1) <> ''E''
	begin
		select @resultado = right(@resultado,10)
		return @resultado
	end

	if @pais = 8
	begin
		if left(@resultado,1) = ''E''
		begin
			return @resultado
		end
		select @resultado = case
			when len(@resultado) = 7 then ''0'' + @ld + @resultado
			when len(@resultado) = 9 and substring(@resultado,1,1) = ''0'' then @resultado
			when len(@resultado) = 10 and substring(@resultado,2,1) = ''5'' then @resultado
			when len(@resultado) = 11 and substring(@resultado,3,3) in (''111'',''510'',''511'') then @resultado
			else ''E_NV_Longitud'' end
		return @resultado
	end

	if @pais = 9 and left(@resultado,1) <> ''E''
	begin
		return @resultado
	end


	-- Brasil
	if @pais = 10 and left(@resultado,1) <> ''E''
	begin
		return @resultado
	end

	--Guatemala
	if @pais = 11 and left(@resultado,1) <> ''E''
	begin
		return @resultado
	end

	--Costa Rica
	if @pais = 12 and left(@resultado,1) <> ''E''
	begin
		return @resultado
	end

	--Salvador
	if @pais = 13 and left(@resultado,1) <> ''E''
	begin
		return @resultado
	end

	--Spain
	if @pais = 14 and left(@resultado,1) <> ''E''
	begin
		return @resultado
	end
end
else begin
 select @resultado = dbo.Limpia(@cadena)
end

return @resultado
end'
		EXEC(@sql)

		set @process = 'ALTER function [dbo].[fnClearPhoneArg]----------'
		set @sql='ALTER function [dbo].[fnClearPhoneArg](@tel varchar(32))
RETURNS varchar(32) 
AS  
BEGIN

declare @pais varchar(2)
declare @ld varchar(5)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

declare @telTemp varchar(15)

set @telTemp = @tel
select @tel = dbo.Completa(@tel, @pais, @ld)
select @tel = dbo.Verifica(@tel)

if left(@tel,1) = ''E'' begin return @telTemp end

if len(@tel) in (6,7,8,9,10) begin
	if left(@tel,2) = ''15'' begin set @tel = @ld + right(@tel,len(@tel) - 2) end 
	else begin set @tel = @ld + @tel end
end

if len(@tel) = 11 begin set @tel = right(@tel,10) end

if len(@tel) = 13 begin
	declare @index as int
	select @index = charindex(''15'',@tel)		
	--El unico caso en el que la lada tiene un 15 es con lada 3715
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

if len(@tel) <> 10 begin
	set @tel = @telTemp
end

return @tel

end'
		EXEC(@sql)

		set @process = 'ALTER FUNCTION [dbo].[fnGetTimeZone]--------'
		set @sql='ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN
	declare @lada as varchar(5)
	declare @timeZone as int
	declare @ld as varchar(5)
	declare @location as varchar(500)
	declare @country as tinyInt
	declare @pais varchar(2)

	select @lada = valor from ccsettings with(nolock) where setting_id = 17
	select @country = valor, @pais = valor from ccSettings with(nolock) where setting_id = 104
	
	select @ld = ''''
	select @location = ''''

		if @country = 1 begin

			if (len(@phone) = 10)
				begin
					if(exists(select top 1 cld from series nolock where cld=left(@phone,2)))
						select @ld = case when left(@phone,2) = @lada then 0 else left(@phone,2) end
					else if(exists(select top 1 cld from series nolock where cld=left(@phone,3)))
						select @ld = case when left(@phone,3) = @lada then 0 else left(@phone,3) end
				end
			else
				select @ld = 0

			if @ld <> 0
				begin
					select @location = estado
					from series
					where cld = @ld
					and serie = substring(@phone, len(@ld) + 1, 6 - len(@ld))
					and right(@phone, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

					select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
					where id_country = @country and (
					( len(@phone) = 8 and @lada = area and len(area) = 2 )
					or
					( len(@phone) = 7 and @lada = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 2) = area and len(area) = 2 ))
					and location = @location
				end
			else
				begin
					select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
					where id_country = @country and (
					( len(@phone) = 8 and @lada = area and len(area) = 2 )
					or
					( len(@phone) = 7 and @lada = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 2) = area and len(area) = 2 ))
				end
		end

		if @country = 2 begin
			declare @telTemp varchar(15)
			set @telTemp = @phone
			select @phone = dbo.Completa(@phone, @pais, @lada)
			if left(@phone,1) = ''E'' begin set @phone = @telTemp end
			select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaArgDetail where
				( len(@phone) = 6 and @lada = area and len(area) = 4 )
				or
				( len(@phone) = 7 and @lada = area and len(area) = 3 )
				or
				( len(@phone) = 8 and @lada = area and len(area) = 2 )
				or
				( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
				or
				( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
				or
				( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
				or
				( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
				or
				( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
				or
				( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 )
				if @timeZone is null
					begin
						select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
						where id_country = @country and (
							( len(@phone) = 6 and @lada = area and len(area) = 4 )
							or
							( len(@phone) = 7 and @lada = area and len(area) = 3 )
							or
							( len(@phone) = 8 and @lada = area and len(area) = 2 )
							or
							( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
							or
							( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
							or
							( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
							or
							( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
							or
							( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
							or
							( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 ))
					end
		end

	if @country = 3 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 7 and @lada = area )
		or
		( len(@phone) = 8 and left(@phone,1) = area )
		or
		( len(@phone) in(10,11) and (left(@phone,1) = ''3'' or substring(@phone,2,1) = ''3'')))
	end

	if @country = 4

		begin
			select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaUsaDetail where
			( len(@phone) = 7 and @lada = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 and left(right(@phone, 7), 3) = prefix)
			if @timeZone is null
				begin
					select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
					where id_country = @country and (
					( len(@phone) = 7 and @lada = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
				end
		end

	if @country = 5 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 6 and @lada = area )
		or
		( len(@phone) = 7 and @lada = area )
		or
		( len(@phone) = 8 and left(@phone,1) = area )
		or
		( len(@phone) = 8 and left(@phone,2) = area )
		or
		( len(@phone) = 9 and left(@phone,2) = area )
		or
		( len(@phone) = 10 and substring(@phone,3,1) = area and left(@phone,2) = ''09'' ))
	end

	if @country = 6 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 7 and @lada = area and len(area) = 3 )
		or
		( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
	end

	if @country = 7 begin
		declare @phoneTemp as varchar(10)
		select @phoneTemp = right ( @phone, 10 )
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
		where id_country = @country and (
		(len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,4) = area ) or
		(len(@phoneTemp) = 9 and left(@phoneTemp,4) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,3) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,2) = area )
		)
	end

	if @country = 8 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
		where id_country = @country and (
		(len(@phone) = 7 and @lada = area) or
		(len(@phone) = 9 and substring(@phone, 2, 1) = area) or
		(len(@phone) = 10 and substring(@phone, 2, 1) = area) or
		(len(@phone) = 11 and substring(@phone, 2, 1) = area))
	end

	if @country = 9 begin
		select @phone = dbo.Completa(@phone, @pais, @lada)
		-- len(@phone) = 10
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
			where id_country = @country and (
			(convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
			(convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
		end
	end

	if @country = 10 begin
		select @phone = dbo.Completa(@phone, @pais, @lada)
		-- 8 <= len(@phone) <= 19
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
			where id_country = @country and (
			((len(@phone) between  8 and  9)                                      and                   @lada = area) or
			((len(@phone) between 10 and 11)                                      and substring(@phone, 1, 2) = area) or
			((len(@phone) between 12 and 13) and substring(@phone, 1, 4) = ''9090'' and                   @lada = area) or
			((len(@phone)       = 13       )                                      and substring(@phone, 4, 2) = area) or
			((len(@phone) between 14 and 15) and substring(@phone, 1, 2) = ''90''   and substring(@phone, 5, 2) = area) or
			((len(@phone)       = 14       ) and substring(@phone, 1, 1) = ''0''    and substring(@phone, 4, 2) = area))
		end
	end

	if @country = 11 begin
		select @phone = dbo.Completa(@phone, @pais, @lada)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	if @country = 12 begin
		select @phone = dbo.Completa(@phone, @pais, @lada)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	if @country = 13 begin
		select @phone = dbo.Completa(@phone, @pais, @lada)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end
	
	if @country = 14 begin
		select @phone = dbo.Completa(@phone, @pais, @lada)
		if (substring(@phone, 1, 1) <> ''E'') begin
			if len(@phone) = 9 begin
				select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
				where id_country = @country and ((substring(@phone, 1, 2) = area) or (substring(@phone, 1, 3) = area))
			end
		end
	end

	return isNull(@timeZone,0)
 END'
		EXEC(@sql)




		set @process = 'ALTER function  -- fGet_CampAcd_Area'
		set @sql='ALTER function [dbo].[fGet_CampAcd_Area] (@user int, @tipo int)
returns @camps table (cam_id int)
as
begin
if (select login from ccusers where user_id=@user) = ''root''
      set @user=0
--solo se corrigio para el usuario root
if @tipo = 3 and @user =0
	set @tipo = 1
if @tipo = 4 and @user =0
	set @tipo = 2

if @tipo = 1 begin
      insert @camps select distinct c.cam_id 
      from ccusers u join ccCamps c on u.IDArea = c.IDArea 
      where isnull(u.user_id, 0) = case when @user>0 then @user else isnull(u.user_id, 0) end
      end

else if @tipo = 2 begin
      insert @camps select distinct c.Inbound_id 
      from ccusers u join ccinbound c on u.IDArea = c.IDArea 
      where isnull(u.user_id, 0) = case when @user>0 then @user else isnull(u.user_id, 0) end
      end
if @tipo = 3 begin --Solo trae los seleccionados en el wg
      insert @camps select distinct wgCamAcd.IdCampEsp
      from ccusers u with(nolock)
	  inner join ccCamps c with(nolock) on u.IDArea = c.IDArea
	  inner join ccRIAWorkGroupUsers wg with(index(IX_ccRIAWorkGroupUsers_I),nolock) on wg.User_id=u.User_id
	  inner join ccRIACampEspWG wgCamAcd with(index(IX_ccRIACampEspWG_2),nolock) on wgCamAcd.IDWG=wg.IDWG and tipo=1
      where u.User_id=@user
      end

else if @tipo = 4 begin --Solo trae los seleccionados en el wg
      insert @camps select distinct wgCamAcd.IdCampEsp cam_id from ccUsers u with(nolock)   
	  inner join ccInbound c with(nolock) on c.IDArea= c.IDArea
      inner join ccRIAWorkGroupUsers wg with(index(IX_ccRIAWorkGroupUsers_I),nolock) on wg.User_id=u.User_id
      inner join ccRIACampEspWG wgCamAcd with(index(IX_ccRIACampEspWG_2),nolock) on wgCamAcd.IDWG=wg.IDWG and tipo=0      
      where u.User_id=@user 
      end
return
end'
		EXEC(@sql)
		

		set @process = 'ALTER FUNCTION [dbo].[Verifica]--------'
		set @sql='ALTER FUNCTION [dbo].[Verifica](@tel varchar(32))
RETURNS varchar(32) AS
 BEGIN
	declare @ld varchar(7)
	declare @lon tinyint
	declare @result tinyint
	declare @mod varchar(10)
	declare @Cadena varchar(32)
	declare @cldLocal varchar(7)
	declare @pais tinyint

	select @cldLocal = valor from ccsettings with(nolock) where setting_id = 17
	select @pais = valor from ccSettings with(nolock) where setting_id = 104
	select @tel = dbo.limpia(@tel)

	if @pais = 1 begin --Empieza Mexico
		select @lon = len(@tel)
		if @lon between 7 and 8 begin
			set @tel = @cldLocal + @tel
		end
		select @tel = right(@tel, 10)
		select @lon = len(@tel)

		if @lon = 10 begin

			if(exists(select top 1 cld from series nolock where cld=left(@tel,2)))
				select @ld = left(@tel,2)
			else if(exists(select top 1 cld from series nolock where cld=left(@tel,3)))
				select @ld = left(@tel,3)
			else
				return ''E_'' + @tel

			select @mod = modalidad from series nolock where cld = @ld and serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

			select @tel = case
				when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''01'' + @tel end
				when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
				else ''E_'' + @tel
			end
		end else begin
			if @lon > 0 begin
				select @tel = ''E_'' + @tel
			end
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
			(left(@tel, 5) in(''02820'',''02821'',''02825'',''02827'',''02828'',''02829'',''02830'',''02837'',''02838'',''02840'',''02841'',''02842'',''02843'',''02844'',''02866'',''02867'',''02868'',''02870'',''02871'',''02877'',''02879'',''02880'',''02881'',''02882'',''02885'',''02886'',''02887'',''02889'',''02890'',''02891'',''02892'',''02893'',''02894'',''02895'',''02897'') and @lon = 11) or --claves 2xxx tienen formato 4-6
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
		end -- Termina España

	return @tel
end'
		EXEC(@sql)




		set @process = 'ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]-------------------'
		set @sql='ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
@cam_id smallint=0,
@iPortNumber smallint = 0,
@phone varchar(30) = ''''
as
declare @prefix as varchar(15)
declare @ani as varchar(32)
declare @call_record_cam as tinyint
declare @pais as tinyint 
declare @aniglobal varchar(32)
declare @ivr_script smallint, @surveycamid int
declare @call_record bit, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint

select @pais = valor from ccsettings with(nolock) where setting_id = 104
select @call_record_cam = call_record from ccCamps where cam_id = @cam_id
select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

set @prefix =''''
-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

-- Prefijo por campaña,
if @prefix =''''
    select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

-- Prefijo general
if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
    select @prefix = valor from ccsettings with(nolock) where setting_id =101

-- Ani
set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

--AnswerMachine Message Files
DECLARE @MsgFiles VARCHAR(8000) 
SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000) 
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

select @surveycamid = 0, @ivr_script = 0




select @tNoContesta = cam_tNoContesta, @ani = case when @ani = '''' then ani else @ani end
,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
,@call_record = dbo.EnableCallRecord(@call_record_cam,@pais,@phone), @surveycamid = isnull(surveycamid,0)
from ccCamps where cam_id = @cam_id

if @surveycamid > 0
    select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid
    

if @ani = '''' begin 
set @ani = @aniglobal 
end 

select @prefix as sDialPrefix, @tNoContesta as tNoContesta,@ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
@call_record as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles, @ivr_script ivrScript'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_ADMDialer]------------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_ADMDialer]
@Descripcion varchar(15),
@dialer_id smallint,
@Port int = 0, -- se cambia tipo de dato
@Status smallint,
@Tipo tinyint, -- 1=ALTA, 2=Modificacion, 3=Eliminar
@provedor_id int=0--by odc
AS
set nocount on
declare @idioma as bit
Select @idioma=isnull(valor,0) from ccSettings where setting_id=27

if @Tipo=1
 begin
	if @provedor_id=0
		select top 1 @provedor_id=provedor_id from cstoProvedor

	if exists(select Descripcion from ccoDialers where Descripcion=@Descripcion or Puerto=@Port)
	 begin
		select 0, case @idioma when 1 then ''Name in Use'' else ''Nombre en Uso'' end
		return(0)
	 end
	
	Insert ccoDialers (Descripcion, Puerto, Status, provedor_id) Select @Descripcion, @Port, @Status, @provedor_id
	select -1, case @idioma when 1 then ''Dialer: '' + upper(@Descripcion) + '' Added Succesfuly''
	else ''Dialer: '' + upper(@Descripcion) + '' Dado de alta'' end
	return(0)
 end

if @Tipo=2
 begin
	if exists(select Descripcion from ccoDialers where Descripcion=@Descripcion and dialer_id<>@Dialer_id) or 
	exists(select Puerto from ccoDialers where Puerto=@Port and dialer_id<>@Dialer_id)
	 begin
		select 0, case @idioma when 1 then ''Name or port in Use'' else ''Nombre o puerto en Uso'' end
		return(0)
	 end

	Update ccoDialers set Descripcion= @Descripcion, Puerto=@Port, Status=@Status, provedor_id=@provedor_id Where Dialer_id=@dialer_id
	select -1, case @idioma when 1 then ''Dialer: '' + upper(@Descripcion) + '' Modified''
	else ''Dialer: '' + upper(@Descripcion) + '' Modificado'' end
	return(0)
 end

if @Tipo=3
 begin
	if exists(select Dialer_id from ccoDialerCamp where Dialer_id=@dialer_id)
	select 0, case @idioma when 1 then ''There is some campaign that is using this dialer''
	else ''Existe alguna campaña que esta utilizando este dialer'' end
	return(0)

	delete ccoDialers Where Dialer_id=@dialer_id		
	select -1, case @idioma when 1 then ''Dialer: '' + upper(@Descripcion) + '' Eliminado''
	else ''Dialer: '' + upper(@Descripcion) + '' Removed'' end
	return(0)
 end
set nocount off'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIACATDialer]------------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIACATDialer]
@Descripcion varchar(40)='''',
@dialer_id varchar(5)='''',
@Port int = 0, -- se cambia tipo de dato
@Status varchar(1)='''',
@Tipo varchar(2), 
@carrier_id varchar(5)='''',--by odc
@xfertype smallint=0
AS
set nocount on
declare @sql as nvarchar(1000)

if @Tipo=0 --All Dialers
 begin
	SELECT dialer_id, Descripcion FROM ccoDialers WITH(NOLOCK)
	return(0)
 end

if @Tipo=1 --Query
 begin
	SELECT Puerto, Descripcion, Status, dialer_id, p.descrip, xt.description FROM ccoDialers d 
	join cstoProvedor p on p.provedor_id=d.provedor_id
	join ccoxfertype xt on xt.xfertype_id=d.xfertype 
	ORDER BY dialer_id
	return(0)
 end

if @Tipo=2 --Insert
 begin
	if @carrier_id=0
	 begin
		select top 1 @carrier_id=provedor_id from cstoProvedor
	 end

	if exists(select Descripcion from ccoDialers where (Descripcion=@Descripcion or Puerto=@Port))
	 begin
		select 1
		return(0)
	 end

	Insert ccoDialers (Descripcion, Puerto, Status, provedor_id, xfertype) Select @Descripcion, @Port, @Status, @carrier_id, @xfertype
	return(0)
 end

if @Tipo=3 --Update
 begin
	if exists(select Descripcion from ccoDialers where Descripcion=@Descripcion and dialer_id <> @Dialer_id)
	 begin
		select 1--, ''Nombre o puerto en Uso''
		return(0)
	 end

	if exists(select Puerto from ccoDialers where Puerto=@Port and dialer_id <> @Dialer_id)
	 begin
		select 1--, ''Nombre o puerto en Uso''
		return(0)
	 end

	Update ccoDialers set Descripcion=case @Descripcion when '''' then Descripcion else @Descripcion end,
	 Puerto=case @Port when '''' then Puerto else @Port end, Status=case @status when '''' then Status else @status end,
	 provedor_id=case @carrier_id when '''' then provedor_id else @carrier_id end,
	 xfertype = case @xfertype when 0 then xfertype else @xfertype end
	where Dialer_id=cast(@dialer_id as int)
	return(0)
 end

if @Tipo=4 --Delete
 begin
	if exists(select Dialer_id from ccoDialerCamp where Dialer_id=@dialer_id)
	 begin
		select 1--, ''Existe alguna campaña que esta utilizando este dialer''
		return(0)
	 end

	delete ccoDialers Where Dialer_id=@dialer_id
	return(0)
 end

if @Tipo=5 --cat. de tipo xfer
begin
	SELECT xfertype_id, description FROM ccoxfertype WITH(NOLOCK)
	return(0)
end

set nocount off'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_AplicaListaNegra]-------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_AplicaListaNegra]
--@idcampana as varchar(10),
--@fechacal as datetime
AS

declare @pais varchar(2)
declare @ld varchar(4)
declare @idagenda  int
declare @campsid int
declare @fechacal datetime
declare @Listid int

SET NOCOUNT ON

CREATE TABLE [dbo].[#mycamps] ( [campsid] [int]  NOT NULL primary key) ON [PRIMARY]

select top 1 @idagenda = idagenda, @campsid = campsid, @fechacal=fecharegs from ccagendalistanegra with(index(IX_ccagendalistanegra_4),nolock)
	where status= 1 and fechaaplicar < getdate() order by fechaaplicar asc

IF @idagenda is not  null
BEGIN

select top 1 @Listid = idtipolista from ccagenda_tipolistanegra with(nolock) 
	where idagenda = @idagenda order by idtipolista asc

update ccagendalistanegra with(rowlock) set inicio=getdate() where idagenda=@idagenda


insert #mycamps
select  campsid  from ccagendalistanegra where idagenda=@idagenda and  status= 1 and fechaaplicar < getdate() order by fechaaplicar asc

CREATE TABLE [dbo].[#mytemp] (
	[callout_id] [int] NOT NULL,
    [telefono] [varchar] (15) NOT NULL ,
	[cam_id] [smallint] NOT NULL ,
	[tipomov] [int] NOT NULL,
    [idtipolista] [int] NOT NULL
) ON [PRIMARY]

create table #tempListNegra(telefono varchar(32) NOT NULL,	idtipolista int NOT NULL)
CREATE NONCLUSTERED INDEX IX_tempListNegra_1 ON [dbo].#tempListNegra (telefono ASC)

--CREATE  UNIQUE  INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) ON [PRIMARY] -- Nunca usa el callout id y siempre se trunca por telefono.

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

insert into #tempListNegra select dbo.Completa(telefono, @pais, @ld),idtipolista from ccListaNegra
-----------------------------------------------------------------------------  telefono1
IF @campsid=0
BEGIN
	
        IF @Listid = 0
        BEGIN
		

	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono =ln.telefono
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono = ln.telefono
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	---Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal
	
           END
           ELSE
           BEGIN
              insert #mytemp
	---Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln on cs.cal_telefono = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END



-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono= wt.cal_telefono and  rtrim(left(ltrim(            cs.cal_telefono2 + ''         ''
							 + cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable with(rowlock) set cal_telefono =
rtrim(left(ltrim(            cs.cal_telefono2 + ''         ''
							 + cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono1 de CS
update ccoCallsOutSource with(rowlock)
set cal_telefono = ''''
from ccoCallsOutSource cs 
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp


----------------------------------------------------------------------------------- -telefono 2
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono2 =ln.telefono
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
             insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono2 = ln.telefono
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
    
           END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono2 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln on cs.cal_telefono2 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END

-- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono2= wt.cal_telefono and rtrim(left(ltrim(            cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable with(rowlock) set cal_telefono =
rtrim(left(ltrim(            cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono2= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono2 de CS
update ccoCallsOutSource with(rowlock) set cal_telefono2 = ''''
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
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono3 en lista negra
	select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono3 =ln.telefono
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono3 en lista negra
	select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono3 = ln.telefono
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
           END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono3 en lista negra
	select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono3 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono3 en lista negra
	select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln on cs.cal_telefono3 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono3= wt.cal_telefono  and  rtrim(left(ltrim(            cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable with(rowlock) set cal_telefono =
rtrim(left(ltrim(             cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono3= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono3 de CS
update ccoCallsOutSource set cal_telefono3 = ''''
from ccoCallsOutSource cs 
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 4
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono4 en lista negra
	select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono4 =ln.telefono
	where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono4 en lista negra
	select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono4 = ln.telefono
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono4 en lista negra
	select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono4 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono4 en lista negra
	select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln on cs.cal_telefono4 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono4= wt.cal_telefono and  rtrim(left(ltrim(            cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono =
rtrim(left(ltrim(            cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono4= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono4 de CS
update ccoCallsOutSource set cal_telefono4 = ''''
from ccoCallsOutSource cs 
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 5
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono5 =ln.telefono
	where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono5 en lista negra
	select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono5 = ln.telefono
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono5 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono5 en lista negra
	select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln on cs.cal_telefono5 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
    
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono5= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono5 de CS
update ccoCallsOutSource set cal_telefono5 = ''''
from ccoCallsOutSource cs 
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

update ccagendalistanegra set termino=getdate() where idagenda=@idagenda
update ccagendalistanegra set status=''0'' where idagenda=@idagenda
drop table #mytemp
drop table #tempListNegra
END


drop table #mycamps'
		EXEC(@sql)

		set @process = 'ALTER proc [dbo].[ccsp_ccRIACallBack_Queue]-------'
		set @sql='ALTER proc [dbo].[ccsp_ccRIACallBack_Queue]
@Que_id int = null,
@cal_id int = null,
@CAL_ANI varchar(15) = null,
@callout_id int = null,
@inbound_id int = null
as
set nocount on

if (isnull(@Que_id, '''') = '''') and (isnull(@cal_id, '''') = '''' or isnull(@CAL_ANI, '''') = '''')
 begin
	select -1
	return(0)
 end

declare @ANI_CB varchar(13)
declare @pais varchar(2)
declare @ld varchar(5)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @ANI_CB=dbo.completa(@CAL_ANI, @pais, @ld)

if isnull(@Que_id, '''') <> ''''
 begin
	update ccRIACallBack_Queue set cal_id = isnull(@cal_id,cal_id),
	 CAL_ANI = isnull(@CAL_ANI,CAL_ANI), callout_id = isnull(@callout_id,callout_id),
	 inbound_id = isnull(@inbound_id,inbound_id), status_queue = 1
	where Que_id=@Que_id

	select 0 Que_id, @ANI_CB ANI_CB
	return(0)
 end

insert ccRIACallBack_Queue (cal_id, CAL_ANI, callout_id, inbound_id, status_queue, datestamp)
select @cal_id, @CAL_ANI, @callout_id, @inbound_id, 0, GETDATE()

select @Que_id = SCOPE_IDENTITY()
select @Que_id Que_id, @ANI_CB ANI_CB

set nocount off'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_ExtAppsDisposeCall]---------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_ExtAppsDisposeCall]
@action as tinyint = 0,
@type as tinyint = 0,
@cal_id as smallint = 0,
@disposition as smallint = 0,
@subDisposition as smallint = 0,
@date as varchar(50) = '''',
@cam_id as smallint = 0
AS
declare @phone as varchar(15)
declare @msg as int
declare @needsCallback as int
declare @pais varchar(2)
declare @ld varchar(5)

set @msg = 0 --No hizo nada

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

if @action = 1 begin  -- Califica y reprograma
	if @type = 1 begin	-- Inbound
		
		if @subDisposition = 0 begin --Si la subcalif tiene 0 buscamos en la calif padre
			select @needsCallback = canReprogram from ccTipoCalif where calif_id = @disposition			
		end else begin -- Si no buscamos en la tabla de las subcalifs
			select @needsCallback = canReprogram from ccTipoCalifSub where califSub_id = @subDisposition			
		end

		if @needsCallback = 1 begin	-- Verificamos si necesita repgoramacion y si la fecha no viene vacia
			if @date <> '''' begin
				declare @acd_id as smallint			
				declare @phoneT as varchar(15)

				select @phone = cal_ani, @acd_id = inbound_id from cccallsin with(nolock) where cal_id = @cal_id
				select @cam_id = isnull(cam_id,0) from ccinbound with(nolock) where inbound_id = @acd_id
				select @phoneT = dbo.Completa(@phone, @pais, @ld)

				if @cam_Id <> 0 begin -- Si hay campaña espejo reprogramamos
					select @phone = case when left(@phoneT,1) = ''E'' then @phone else @phoneT end
					-- Genera callback
					exec ccsp_InInsertaCallBack '''', @cam_id, @phone, @date, '''','''','''','''','''',1,0
					-- Actualiza calificacion
					update cccallsin set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
					set @msg =  2 -- Reprogramacion Inbound
				end else begin				
					set @msg =  5 -- No hay campaña espejo para el acd	
				end
			end else begin				
				set @msg = 6 -- Necesita repgoramacion pero no hay fecha
			end
		end else begin -- Si no necesita repgoramacion se actualiza la calificacion
			update cccallsin set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
			set @msg = 1 -- Actualizo calificacion 
		end
	end
	else begin -- Outbound

		if @subDisposition = 0 begin --Si la subcalif tiene 0 buscamos en la tabla calif padre
			select @needsCallback = canReprogram from ccTipoCalifOut where calif_id = @disposition
		end else begin -- Si no buscamos en la tabla de las subcalifs
			select @needsCallback = canReprogram from ccTipoCalifSubOut where califSub_id = @subDisposition
		end

		if @needsCallback = 1 begin	-- Verificamos si necesita repgoramacion y si la fecha no viene vacia
			if @date <> '''' begin 
				declare @callout_id int
				declare @cal_key as varchar(33)
				
				select @phone = cal_telefono, @cam_id = cam_id, @callout_id = callout_id, @cal_key = cal_key from ccocallsout with(nolock) where cal_id = @cal_id
				exec ccsp_OUTInsertaCallBack @cal_id, @phone, @cam_id, @date, @callout_id, 1, 0, @cal_key
				update ccocallsout set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
				set @msg =  4 -- Reprogramacion Outbound
			end else begin
				set @msg = 6 -- Necesita repgoramacion pero no hay fecha
			end
		end else begin -- Si no necesita repgoramacion se actualiza la calificacion
			update ccocallsout set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
			set @msg = 3 -- Actualizo calificacion 
		end

	end	
	select @msg
end

if @action = 2 begin
	if @type = 1 begin
		select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
		calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
		from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = 0 
		union
		select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
		calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description",cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
		from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = 0 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
		for xml explicit, type		
	end
	else begin
 		select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback", 
 		calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = 1 
		union
		select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
		calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description", cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = 1 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
		for xml explicit, type
	end
end

if @action = 3 begin
	if @type = 1 begin
		select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
		calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
		from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where tipo = 0 
		union
		select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
		calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description",cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
		from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where tipo = 0 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
		for xml explicit, type		
	end
	else begin
 		select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
 		calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where tipo = 1 
		union
		select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
		calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description", cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where tipo = 1 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
		for xml explicit, type
	end
end'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]---------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer
AS

declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)

insert into cclistanegra values(@telephone, @ln_id)

CREATE TABLE [dbo].[#mycamps] (
	[campsid] [int] NULL
	)

CREATE UNIQUE INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select cam_id from Camplistanegra where idtipolista = @ln_id

CREATE TABLE [dbo].[#myprincipaltemp](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE UNIQUE INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltemp]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltemp]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltemp]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltemp]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltemp]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltemp]([cal_telefono5]) 

CREATE TABLE [dbo].[#mytemp](
	[callout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
	)

CREATE UNIQUE INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @tel = dbo.completa(@telephone, @pais, @ld)

declare @Sql nvarchar(max)

set @Sql = ''insert into [#myprincipaltemp] '' +
''SELECT callout_id as callout_id, cam_id,''''3'''','' + cast(@ln_id as nvarchar) + '' as idtipolista , [cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5] '' +
''FROM [ccoCallsOutSource] a inner join #mycamps b on (a.cam_id = b.campsid) '' +
''WHERE ('''''' + @tel + '''''' IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) '' +
''or right('''''' + @tel + '''''',10) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) '' +
''or right('''''' + @tel + '''''',11) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5])) '' +
''and  cal_fechadial > dateadd(dd,-30,getdate())''

EXEC(@Sql)

if (select count(*) from #myprincipaltemp with(nolock)) > 0
	begin
		/******************/
		/*** Telefono 1 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where cal_telefono = @tel

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono = wt.cal_telefono
			and rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
								 + cs.cal_telefono3 + ''         ''
								 + cs.cal_telefono4 + ''         ''
								 + cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
												+ cs.cal_telefono3 + ''         ''
												+ cs.cal_telefono4 + ''         ''
												+ cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono1 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 2 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono2,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where cal_telefono2 = @tel

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono2= wt.cal_telefono 
			and rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
								 + cs.cal_telefono4 + ''         ''
								 + cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
												+ cs.cal_telefono4 + ''         ''
												+ cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono2= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono2 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono2 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 3 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono3,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where cal_telefono3 = @tel

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono3= wt.cal_telefono  
			and  rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
								  + cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
												+ cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono3= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono3 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono3 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 4 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono4,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where cal_telefono4 = @tel

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono4= wt.cal_telefono 
			and rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono4= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono4 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono4 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 5 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono5,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where cal_telefono5 = @tel

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono5= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono5 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono5 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
		end
	end

drop table [#myprincipaltemp]
drop table #mytemp
drop table [dbo].[#mycamps]'
		EXEC(@sql)

		set @process = 'ALTER procedure [dbo].[ccsp_Limpia]'
		set @sql='ALTER procedure [dbo].[ccsp_Limpia]
@tel varchar(30),
@Camp int = 0
as
set nocount on
declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint
select @tel = dbo.limpia(@tel)
select @lon = len(@tel)
select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @extLen = valor from ccsettings with(nolock) where setting_id = 108
declare @telTemp as varchar(15)

if @extLen=@lon and @lon>1
 begin
	select 0 as res, @tel as tel -- Extension
	return(0)
 end

if @pais = 1
 begin
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
end

'
		EXEC(@sql)

		set @process = 'ALTER procedure [dbo].[ccsp_OUTInsertaCallBack]--------'
		set @sql='ALTER procedure [dbo].[ccsp_OUTInsertaCallBack]
@cal_id int,
@Telefono varchar(15),
@Camp smallint,
@FechaDial smalldatetime,
@callout_id int=0,
@TelReprograma smallint=-1,
@user_id int=0,
@cal_Key varchar(33)='''',
@isAuto bit=0
as
set nocount on
IF @TelReprograma<0
      return(0)
 
declare @Fecha smalldatetime, @sSQL nvarchar(max)
declare @iZonaHoraria int,@iZonaHoraria_verano int,@iZonaHoraria2 int, @iZonaHoraria_verano2 int,@iZonaHoraria3 int,@iZonaHoraria_verano3 int,@iZonaHoraria4 int,@iZonaHoraria_verano4 int,@iZonaHoraria5 int,@iZonaHoraria_verano5 int
declare @idZone int, @idZoneDaylight int, @list_id int
declare @bIsDaylight bit, @difference int
declare @TelOriginal varchar(15)
declare @FechaOriginal datetime
declare @pais varchar(2)
declare @ld varchar(5)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

select @callout_id = callout_id, @TelOriginal = cal_telefono, @FechaOriginal = cal_Inicio
from ccocallsout
where Cal_id=@cal_id
 
IF @TelReprograma=0 --Otro telefono
BEGIN
      declare @tel2 varchar(20), @tel3 varchar(20), @tel4 varchar(20), @tel5 varchar(20)
      declare @phoneCompleted varchar(20)
      declare @emptyPhoneMsg varchar(50)
 
      select @idZone = dbo.fnGetTimeZone(@Telefono,0)
      select @idZoneDaylight = dbo.fnGetTimeZone(@Telefono,1)
      select @phoneCompleted = dbo.Completa(@Telefono, @pais, @ld)
      select @emptyPhoneMsg = case valor when 0 then ''El teléfono no puede ser nulo o vacío'' else ''Phone number can not be null or empty'' end from ccsettings where setting_id = 27
 
      if charIndex(''E_NV'',@phoneCompleted) > 0
            set @phoneCompleted = @Telefono
            if @phoneCompleted = ''''
            begin
                  raiserror(@emptyPhoneMsg, 18, 1)
            end
 
     select @tel2=cal_telefono2,@tel3=cal_telefono3,@tel4=cal_telefono4,@tel5=cal_Telefono5,@cal_Key=cal_key
     from ccoCallsoutSource where callout_id=@callout_id
     
      select @TelReprograma=case when isnull(@tel4,'''')='''' then 4 when isnull(@tel3,'''')='''' then 3     when isnull(@tel2,'''')='''' then 2 else 5 end
 
      select @sSQL=''update ccoCallsOutSource set cal_telefono''+cast(@TelReprograma as varchar(1))+''=''''''+@phoneCompleted+''''''''
      +'',cal_status=2,dial_Tels=''''''+cast(@TelReprograma as char(1))+replace(''2345NNN'',cast(@TelReprograma as char(1)),''1'')+''''''''
      +'', iZonaHoraria''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZone as varchar(10))+'', iZonaHoraria_Verano''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZoneDaylight as varchar(10))+'' where callout_id=''+cast(@callout_id as varchar(10))
      exec(@sSQL)
END
 
ELSE--@>0 telefono ya existente
BEGIN
      update ccoCallsOutSource set cal_status=2,
      dial_Tels=cast(@TelReprograma as char(1))+ replace(''2345NNN'',cast(@TelReprograma as char(1)),''1'')
      where callout_id=@callout_id
 
      select @sSQL= N''select @outA=cal_key, @outB=izonahoraria'' +replace( cast( @TelReprograma as varchar(1)), ''1'', '''' )+'', @outC=izonahoraria_verano''+replace( cast( @TelReprograma as varchar(1)), ''1'', '''' )+'', @outD= rtrim(left(ltrim(cal_telefono + ''''        ''''
            + cal_telefono2 + ''''         ''''
            + cal_telefono3 + ''''         ''''
            + cal_telefono4 + ''''         ''''
            + cal_telefono5 + ''''         ''''),13)) from ccoCallsOutSource where callout_id = '' +cast(@callout_id as varchar)
      exec sp_executesql @sSQL, N''@outA varchar(33) OUTPUT, @outB int OUTPUT, @outC int OUTPUT, @outD varchar(19) OUTPUT'', @outA=@cal_Key OUTPUT, @outB=@idZone OUTPUT, @outC=@idZoneDaylight OUTPUT, @outD=@Telefono OUTPUT
END
 
-- PARA LA FECHA
declare @country_id as int
select @country_id = valor from ccsettings where setting_id = 104
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
 
if @isAuto=0
	select @difference = dbo.fnGetTimeDifference(case when @bIsDaylight = 0 then @idZone else @idZoneDaylight end)
else
	set @difference = 0
select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))    
update ccoCallsOut set cal_fcallback=@FechaDial where cal_id=@cal_id
 
--PARA LAS ESTADISTICAS
if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha) and mes=month(@Fecha) and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@Camp)
      update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@Camp
else
      insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@Camp
 
select @iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end, @iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end,
 @iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end, @iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end,
@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end, @iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end,
@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end, @iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end,
@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end, @iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end,
@list_id=list_id
from ccocallsoutsource where callout_id=@callout_id
 
if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
      UPDATE ccoWorkingTable SET cal_telefono=@Telefono, cam_id=@Camp,cal_fechaDial=@Fecha,
      cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_Key,
      iZonaHoraria = @iZonaHoraria, iZonaHoraria_Verano = @iZonaHoraria_Verano,
      iZonaHoraria2 = @iZonaHoraria2, iZonaHoraria_Verano2 = @iZonaHoraria_Verano2,
      iZonaHoraria3 = @iZonaHoraria3, iZonaHoraria_Verano3 = @iZonaHoraria_Verano3,
      iZonaHoraria4 = @iZonaHoraria4, iZonaHoraria_Verano4 = @iZonaHoraria_Verano4,
      iZonaHoraria5 = @iZonaHoraria5, iZonaHoraria_Verano5 = @iZonaHoraria_Verano5
      WHERE callout_id=@callout_id
 
else
      INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,
      [user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano,iZonaHoraria2,iZonaHoraria_verano2,iZonaHoraria3,
      iZonaHoraria_verano3,iZonaHoraria4,iZonaHoraria_verano4,iZonaHoraria5,iZonaHoraria_verano5,list_id)
      select @callout_id,@Telefono,@Camp,@Fecha,1,3,1,
      @user_id,@cal_Key,@iZonaHoraria,@iZonaHoraria_Verano,@iZonaHoraria2,@iZonaHoraria_Verano2,@iZonaHoraria3,
      @iZonaHoraria_Verano3,@iZonaHoraria4,@iZonaHoraria_Verano4,@iZonaHoraria5,@iZonaHoraria_Verano5,@list_id
 
      insert into ccoCallBacks 
	  (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus) 
	  values
	  (@callout_id,@user_id,@Camp,@cal_Key,@TelOriginal,@Telefono,@FechaOriginal,@Fecha,NULL,0,1)
 
set nocount off'
		EXEC(@sql)

		set @process = 'ALTER procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]---------'
		set @sql='ALTER procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]
@cal_id int,
@nStatus tinyint
as
set nocount on

declare @ANI varchar(13), @cam_id int, @inbound_id int, @fechadial varchar(40), @callout_id int, 
 @statuscall_id_Array varchar(1000), @minCallBackAbandon smallint, @pais varchar(2), @ld varchar(5)

select @ANI=C.cal_ANI, @cam_id=I.cam_id, @inbound_id=I.inbound_id, 
@statuscall_id_Array=statuscall_id_Array, @minCallBackAbandon=minCallBackAbandon
from cccallsin C join ccInbound I on I.Inbound_id=C.Inbound_id where cal_id=@cal_id

select @fechadial=convert(varchar(16), dateadd(minute, @minCallBackAbandon, getdate()), 121)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

if @nStatus not in (select value from dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','')) or isnull(@cal_id,0)=0
 return(0)

if isnull(@cam_id, 0)=0
	return(0)

select @ANI = dbo.completa(@ANI, @pais, @ld)

if (select substring(@ANI,1,1))= ''E''
	return(0)

if exists (select cal_ANI from ccRIAUpdateCallBack_Abandon where cal_ANI=@ANI)
	return(0)

 begin try
	insert ccRIAUpdateCallBack_Abandon (cal_id, cal_ANI, cam_id, callout_id, inbound_id, minCallBackAbandon)
	select @cal_id, @ANI, @cam_id, @callout_id, @inbound_id, @fechadial

	select @ANI=dbo.completa(@ANI, @pais, @ld)
	exec ccsp_INInsertaCallBack @cal_id, @cam_id, @ANI, @fechadial, ''Callback by abandon'', @fechadial, '''', '''', '''', 1, 0, 1

	select top 1 @callout_id=callout_id from ccoWorkingTable WITH(INDEX(PK_ccoWorkingTable)) WHERE cal_telefono=@ANI
	select @fechadial=dateadd(minute, minCallBackAbandonXpire, @fechadial) from ccInbound where Inbound_id=@inbound_id
	update ccRIAUpdateCallBack_Abandon set callout_id=@callout_id, minCallBackAbandonXpire=@fechadial where cal_id=@cal_id
	return(0)
 end try

 begin catch
	return(0)
 end catch
set nocount off'
		EXEC(@sql)

		
		set @process = 'ALTER procedure [dbo].[ccsp_RiaMenuByRole]--------'
		set @sql='ALTER procedure [dbo].[ccsp_RiaMenuByRole]
@Type tinyint,
@role_id smallint = null,
@Menu_id smallint = null,
@CM tinyint = 0,
@AE tinyint = 0
as
set nocount on

select @AE = valor from ccsettings where setting_id = 71
Declare @NRS tinyint
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

If @Type = 1 -- Get language
begin
	select valor from ccSettings where setting_id = 27
	return(0)
end

If @Type = 2 -- Carga todos los roles
begin
	select Role_id, Description from ccRIACat_AdminRole where type = 1 and Role_id<>1 order by priority
	return(0)
end

If @Type = 3 -- Carga roles
begin
select rm.role_id, m.menu_descrip, rm.id_menu,rm.type,m.release from dbo.ccRIARoleMenu rm, ccmenus m where rm.id_menu = m.menu_id and rm.role_id = @role_id and rm.type = 1 and
	((rm.id_Menu not in (41,42,53)) or (rm.id_Menu = 41 and @CM = 1) or (rm.id_Menu = 42 and @ae > 0) or (rm.id_Menu = 53 and @NRS = 1))
	return(0)
end

declare @language tinyint
select @language=valor from ccSettings where setting_id = 27

If @Type = 4 -- Inserta rol
begin
if not exists(select role_id from ccRIARoleMenu where role_id = @role_id and id_Menu = @Menu_id and type = 1)
begin
	Insert into ccRIARoleMenu (role_id, id_Menu, type) values(@role_id, @Menu_id, 1)
	select
		(select case @language when 0 then substring(Description, 1, charindex(''|'',Description)-1)
		else substring(Description, charindex(''|'',Description)+1, len(Description)) end
		from ccRIACat_AdminRole where role_id=@role_id) as sRole,

		(select case @language when 0 then substring(menu_descrip, 1, charindex(''|'',menu_descrip)-1)
		else substring(menu_descrip, charindex(''|'',menu_descrip)+1, len(menu_descrip)) end
		from ccMenus where menu_id=@Menu_id) as sMenu
	return(0)
end
end

If @Type = 5 -- Elimina rol
begin
delete from ccRIARoleMenu where role_id =@role_id  and id_Menu=@Menu_id and type= 1
select
	(select case @language when 0 then substring(Description, 1, charindex(''|'',Description)-1)
	else substring(Description, charindex(''|'',Description)+1, len(Description)) end
	from ccRIACat_AdminRole where role_id=@role_id) as sRole,

	(select case @language when 0 then substring(menu_descrip, 1, charindex(''|'',menu_descrip)-1)
	else substring(menu_descrip, charindex(''|'',menu_descrip)+1, len(menu_descrip)) end
	from ccMenus where menu_id=@Menu_id) as sMenu
return(0)
end'
		EXEC(@sql)
		


		
		set @process = 'ALTER procedure --- [ccsp_CreateNodeMail]'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_CreateNodeMail]  
@conversationId int,  
@xml xml OUTPUT,  
@supervisor varchar(255)='''',  
@template varchar (255)='''',  
@ScoreTemplate int=0  
AS  
BEGIN  
  
--SET @conversationId=16  
declare @existAttached bit,@numInteracion smallint  
  
--SELECT @supervisor='''',@template='''',@ScoreTemplate=''''  
SELECT @existAttached = case when count(*)>0 then 1 else 0 end  
from attached where messageId in (select messageId from message where conversationId=@conversationId)  
select @numInteracion = count(*) from message where conversationId=@conversationId  
  
  
select @xml = convert(xml,''<R03  C01="''+convert(varchar(max),a.conversationId) +''" C02="''  
+rtrim(ltrim(convert(varchar(23), min(b.date), 126)))+''" C03="''+convert(varchar(max),max(c.descripcion))  
+''" C04="''+ convert(varchar,min(isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno,''''))) +''" C05="''  
+convert(varchar,max(isnull(cctipocalif.[Description],''''))) +''" C06="''+ convert(varchar,max(replace(replace(a.mailClient,''<'','' ''),''>'','' ''))) +''" C07="''  
+convert(varchar(max),sum(b.tRetention+b.tResponse+b.tWrapup)) +''" C08="''+ convert(varchar,min(replace(replace(a.info,''<'',''(''),''>'','')''))) +''" C09="''  
+convert(varchar(max),max(b.messageStatusid) ) +''" C10="''+  convert(varchar(max), isnull(@numInteracion,0))+''" C11="''  
+convert(varchar(max),@existAttached) +''" C12="''+ convert(varchar(max),isnull(@supervisor,'''') ) +''" C13="''+convert(varchar(max),isnull(@template,'''') )  +''" C14="''+convert(varchar(max),isnull(@ScoreTemplate,0))  
+''" C15="''+ convert(varchar,max(isnull(cctipocalifsub.califSubdesc,''''))) +''" C16="''+ convert(varchar,min(isnull(replace(replace(a.info,''<'',''(''),''>'','')''),'''')))  
+  ''"/>'')  
from conversation a  
inner join message b on a.conversationid=b.conversationid  
left outer join ccinbound c on c.inbound_id = a.inboundid  
left outer join ccusers d on d.user_id = b.userid  
left outer join relationmessageDisposition e on e.messageId=b.messageId  
left outer join cctipocalif on cctipocalif.calif_id = e.dispositionId  
left outer join cctipocalifsub on cctipocalifsub.califsub_id = e.subdispositionId and e.subdispositionId <> 0  
where a.conversationId=@conversationId  
group by a.conversationId,a.inboundid  
--print convert(nvarchar(1000),@xml)  
END'
		EXEC(@sql)

		
		set @process = 'ALTER procedure --- [ccsp_MailSave]'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_MailSave]  
@action int,    
@uid varchar(max)=null,    
@date datetime=null,    
@conversationId int=0,    
@inboundId smallint=null,    
@userId smallint=0,    
@messageStatusId int=null,    
@isInbox bit=1,    
@messageId int =null,    
@timeAtt int = 0,    
@pathFile varchar(255)= null,    
@mailClient varchar(60)= null,    
@mailACD varchar(60)= null,    
@isSender bit=0,    
@isUser bit = 0,    
@info varchar(255)=null,    
@dispositionId smallint=0,    
@subDispositionId smallint=0,    
@tWrapUp int =0,    
@tRetention int = 0,    
    
---Finder    
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0    
AS    
BEGIN    
    
    
declare @isEndConversation bit    
declare @meanContactTypeId smallint    
declare @xmlnode xml    
declare @existAttached bit, @numInteracion smallint    
    
set @meanContactTypeId = 1    
SET NOCOUNT ON;    
    
if @action = 1 begin --find uid ConversationMail    
  select count(*) from messageMail where [uid]=@uid    
  return (0)    
end    
else if @action = 2 BEGIN --new Conversation    
 if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin    
  insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)    
  select @conversationId=SCOPE_IDENTITY()    
  insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,0,@date,@messageStatusId)    
  select @messageId=SCOPE_IDENTITY()    
  insert into [messageMail](messageId,[uid]) values (@messageId,@uid)    
  select @conversationId as conversationId,@messageId as messageId,0 as lastUserId    
  return (0)    
 end    
 else begin    
  select 0 as conversationId,0 as messageId,0 as lastUserId    
  return (0)    
 end    
END    
else if @action = 3 BEGIN --new Messages    
 if @date is null set @date=getdate()
 if @mailACD is null
	select @mailACD=mailInbound from conversation where conversationId=@conversationId
 if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin        
	 update [conversation] set info=@info where conversationId=@conversationId    
	 insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,@userId,@date,@messageStatusId)    
	 select @messageId=SCOPE_IDENTITY()
 end
 else begin 
	select 0 as conversationId,0 as messageId,0 as lastUserId
	return (0)
 end
    
 if @uid is null --for outbound messages    
  select @uid = dbo.md5(cast(@conversationId as varchar(10)) + ''_'' + cast(@messageId as varchar(10)))    
    
 insert into [messageMail](messageId,[uid]) values (@messageId,@uid)    
    
 --Finder    
 select @existAttached =case when count(*)>0 then 1 else 0 end  from attached where messageId in (select messageId from message where conversationId=@conversationId)    
 select @numInteracion = count(*) from message where conversationId=@conversationId    
    
    
 exec ccsp_CreateNodeMail @conversationId, @xml = @xmlnode OUTPUT    
    
 if not exists(select * from ccEmailNode where emailId=@conversationId) begin    
  insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)    
 end    
 else begin    
  update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId    
 end    
    
    
    
 select @conversationId as conversationId,@messageId as messageId,0 as lastUserId    
    
END    
else if @action = 4 BEGIN --new attachment    
 insert into [attached](messageId,pathFile,isUser) values(@messageId,@pathFile,@isUser)    
 select SCOPE_IDENTITY() as attachedId    
END    
else if @action = 5 BEGIN --Correos por contestar    
--Status DOWNLOAD,Assigned,READ,UnaSSIGNED    
 select A.conversationId,B.userId,A.mailClient,A.mailInbound,A.info,B.messageStatusId,max(B.messageId) as messageId    
 from conversation A    
 inner join message B on A.conversationId = B.conversationId    
 where A.inboundId = @inboundId and B.messageStatusId in(1,2,3,4) and meanContactTypeId = @meanContactTypeId    
 GROUP BY A.conversationId,A.inboundId,A.info,A.mailClient,A.mailInbound,B.messageStatusId,B.userId    
END    
else if @action = 6 BEGIN --update Time Attention, Retencion    
 select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId    
 update [message] set tResponse=@timeAtt,tRetention=@tRetention,isSender=@isSender,messageStatusId=@messageStatusId,userId=@userId where messageId=@messageId    
    
 ----Status Send,Close conversation system and Close conversation agent    
 --select A.conversationId,B.userId,A.mailClient,A.mailInbound,A.info,B.messageStatusId,max(B.messageId) as messageId    
 -- from conversation A    
 -- inner join message B on A.conversationId = B.conversationId    
 -- where A.inboundId = @inboundId and B.messageStatusId in(5,7,8,9) and meanContactTypeId = @meanContactTypeId    
 -- GROUP BY A.conversationId,A.inboundId,A.info,A.mailClient,A.mailInbound,B.messageStatusId,B.userId    
END    
else if @action = 7 BEGIN --Cambia el status del mensaje    
 select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId    
 update [message] set messageStatusId=@messageStatusId where messageId=@messageId    
 if @messageStatusId=6    
  update [message] set tSend=getdate() where messageId=@messageId    
    
 if @messageStatusId=5    
  begin    
   exec ccsp_CreateNodeMail @conversationId, @xml = @xmlnode OUTPUT    
   if not exists(select * from ccEmailNode where emailId=@conversationId) begin    
    insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)    
   end    
   else begin    
    update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId    
   end    
  end    
END    
else if @action = 8 BEGIN --info del ultimo correo    
 select messageId,GP.inboundId,C.connUser mailInbound,mailClient,mediaType,messageStatusId,info,I.descripcion,IG.graphic_id,I.tNotas,isnull(C.answerTimeOut,10) tTimeOut,C.timeAlertMessage tAlert    
  from (    
  select max(B.messageId) messageId,A.inboundId,A.mailClient,    
   case A.meanContactTypeId when 1 then 3 else -1 end mediaType, B.messageStatusId, max(A.info) info    
   from conversation A inner join message B  on A.conversationId = B.conversationId    
   where A.conversationId=@conversationId    
   GROUP BY A.inboundId,A.mailClient, A.meanContactTypeId, B.messageStatusId, B.userId) GP    
  join contactMeanIn C on C.inboundId=GP.inboundId    
  join ccInbound I on I.Inbound_id=GP.inboundId    
  join ccRIAInboundGraph IG on IG.Inbound_id=GP.inboundId    
END    
else if @action = 9 BEGIN --carga adjuntos del ultimo mensaje  
 if isnull(@conversationId,0) = 0   
  select pathFile,isUser from attached where messageId=@messageId and isUser=@isUser    
 else  
  select pathFile,isUser from attached A  
  inner join message B on A.messageId=B.messageId and B.conversationId=@conversationId  
  where B.conversationId=@conversationId  
END    
else if @action = 10 BEGIN --Correos por enviar    
 select A.conversationId,max(B.messageId) as messageId,B.userId,A.inboundId,A.mailInbound    
  from conversation A    
  inner join message B on A.conversationId = B.conversationId    
  where B.messageStatusId in(5,7,8,9) and A.meanContactTypeId = 1 and isSender=1    
  GROUP BY A.conversationId,A.inboundId,A.info,A.mailClient,A.mailInbound,B.messageStatusId,B.userId    
END    
    
else if @action = 11 BEGIN --Califica el mensaje y pone el tiempo Notas    
 if @subDispositionId <> 0 begin    
  select @isEndConversation=isnull(EndConversation,0) from ccTipoCalifSub where califSub_id=@subDispositionId    
 end    
 else begin    
  select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@subDispositionId    
 end    
    
 if not exists(select * from relationMessageDisposition where messageId=@messageId) begin    
  insert into relationMessageDisposition(messageId,dispositionId,subDispositionId) values(@messageId,@dispositionId,@subDispositionId)    
 end    
 else begin    
  update relationMessageDisposition set dispositionId=@dispositionId,subDispositionId=@subDispositionId where messageId=@messageId    
 end    
 update message set tWrapUp=@tWrapUp where messageId=@messageId    
 if @isEndConversation = 1 begin    
  select @conversationId=conversationId from [message] where messageId=@messageId    
  update conversation set isFinished=@isEndConversation where conversationId=@conversationId    
 end    
END    
else if @action = 12 begin --Tiempo de cola    
 select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId    
 update [message] set tQueue=getdate(),userId=@userId where messageId=@messageId    
end    
else if @action = 13 BEGIN  -- desasignar    
 if @messageId = 0 begin    
    
  insert into [messageUnAssigned](messageId,userId,[time],isLogout)    
  select messageId,userId,datediff(ss,tQueue,getdate()) as [time],1 as isLogout from [message] where userId=@userId and messageStatusId in (2,3)    
    
  update [message] set tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0 where userId=@userId and messageStatusId in (2,3)    
 end    
 else begin    
  insert into [messageUnAssigned](messageId,userId,[time],isLogout)    
  select messageId,userId,datediff(ss,tQueue,getdate()) as [time],0 as isLogout from [message] where userId=@userId and messageId=@messageId and messageStatusId in (2,3)    
    
  update [message] set tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0 where userId=@userId and messageId=@messageId and messageStatusId in (2,3)    
 end    
end    
else if @action = 14 begin    
 select 1    
end    
else if @action = 15 begin    
 SELECT @existAttached = case when count(*)>0 then 1 else 0 end    
 from attached where messageId in (select messageId from message where conversationId=@conversationId)    
 select messageid,A.inboundid,a.conversationid,mailClient,date,@existAttached isAttached,C.descripcion,  
 B.tSend,D.Nombres+'' ''+D.ApellidoPaterno+'' ''+D.ApellidoMaterno,E.timeAlertMessage,E.answerTimeOut,C.tNotas,  
 E.connUser as MailInbound  
 from conversation A    
 inner join message B  on A.conversationId = B.conversationId    
 inner join ccinbound C on A.inboundid= C.inbound_id  
 left join ccUsers D on B.userId = D.User_id    
 inner join contactMeanIn E on E.inboundId=C.Inbound_id  
 where A.conversationId=@conversationId    
  
end    
else if @action = 16 begin    
 select A.inboundid,B.messageid,a.conversationid,c.pathFile    
 from conversation A    
 inner join message B  on A.conversationId = B.conversationId    
 inner join attached C on B.messageid= C.messageid    
 where A.conversationId=@conversationId    
end    
else if @action = 17 begin  
 exec ccsp_CreateNodeMail @conversationId=@conversationId, @xml = @xmlnode OUTPUT,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate   
 if not exists(select * from ccEmailNode where emailId=@conversationId) begin    
 select @conversationId  
  insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)    
 end    
 else begin    
  update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId    
 end    
    
end    
END'
		EXEC(@sql)
		
		set @process = 'ALTER procedure --- [ccsp_RIAConfEspec]'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
@User_id int
AS
set nocount on

select  A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat mode, A.inactiveChatTime, A.maxChats, isnull(A.chatDomain,'''') chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
isnull(A.startStopRecording,0) startStopRecording
,isnull(B.name,'''') as nameMail,isnull(B.conexionInfo,'''') as conexionInfo,isnull(B.connUser,'''') as connUser,
isnull(B.ConnPass,'''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage,
isnull(B.IsActive,0) as Active, isnull(B.answerTimeOut,0) as answerTimeOut,A.callBackSurveyAgent,A.callBackSurveyClient,
case when C.CallsBySurvey is null or C.CallsBySurvey = 0 then 0 else 1 end isRelationSurvey,
isnull(nameTwitter,'''') nameTwitter,isnull(userTwitter,'''') userTwitter,isnull(numMessagesTwitter,3) numMessagesTwitter,
isnull(timeAlertMessageTwitter,10) timeAlertMessageTwitter,isnull(ActiveTwitter,0) ActiveTwitter,isnull(answerTimeOutTwitter,10) answerTimeOutTwitter
from ccInbound A
left join ContactMeanIn B on A.inbound_id=B.inboundId and B.meanContactTypeId=1
left join ccCamps C on C.cam_id=A.cam_id
left join (
select D.inboundId,
D.name as nameTwitter,D.connUser as userTwitter,D.numMessages as numMessagesTwitter,
D.timeAlertMessage as timeAlertMessageTwitter,
D.IsActive as ActiveTwitter, D.answerTimeOut as answerTimeOutTwitter
from ContactMeanIn D
where D.meanContactTypeId=2) D on A.Inbound_id=D.inboundId
where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 4))
return(0)
set nocount off'
		EXEC(@sql)

set @process = 'update table---ccmenus'
		set @sql='update ccMenus set release = ''924581cafd9fbd8aa9e5f65402fecc43d786c100156e029dce2b4bc741a1338d666f9f62a3f3b3538e380e6c99a71472'' where menu_id = 81
					update ccMenus set release = ''07da2c53af948512c23a76f70997c0af889512d8640374ffdceee4eed417b20712b9a91ea924e323ec6aef0b9b58c440d78620c23d5b4111020d9cd38857d28c194d9efe962ce6296af48920dbedfc9b'' where menu_id = 82'
		EXEC(@sql)

			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			exec ccsp_getVersion 'BD', @version
			exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ''', version to release: ''' + cast(@version as varchar(5))
	end

set nocount off