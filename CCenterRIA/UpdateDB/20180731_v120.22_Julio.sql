/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
		
Date: 2018/05/15
Description:

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

		set @process = 'CW-893-DAVC_Administrator_Rights se agrega nuevo permiso'
		set @Sql= 'if (not exists(select * from ccRIACat_AdminPermissions where per_id = 10 ) )
		begin
			insert into ccRIACat_AdminPermissions(per_desc,bStatus,release) 
			values(''Ocultar base de datos|Hide database'',1,''beb771b4d7317a2fa20084db183694df92b9ec58cfc6aee81aeaa59a90a26648dad4a7681abba7e285a1b39d6b32aa15'')
		end'
		EXEC(@Sql)
			

		set @process = 'CW-1653 --Create new Table ccoLogBlackList'
        set @Sql= 'if not exists (select * from sys.tables where name = N''ccoLogBlackList'')
    begin
        create table ccoLogBlackList(
			id_BalckList int identity(1,1),
			callOut_Id int,
			telephone varchar(30),
			calKey varchar(20),
			camId int,
			DateDeleteWT datetime
		)
    end'
        EXEC(@Sql)

		set @process = 'CW-1653 --Crear indice en la tabla ccListaNegra'
        set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_ccListaNegra_I'' and object_id = OBJECT_ID(N''ccListaNegra''))
    begin
        CREATE INDEX IX_ccListaNegra_I ON ccListaNegra (idtipolista,Hashtel);
    end'
        EXEC(@Sql)

		set @process = 'CW-1653 --Crear indice en la tabla ccListaNegra'
        set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_ccListaNegra_II'' and object_id = OBJECT_ID(N''ccListaNegra''))
    begin
        CREATE INDEX IX_ccListaNegra_II ON ccListaNegra (idtipolista,Hashtel,HashKey);
    end'
        EXEC(@Sql)

        set @process = 'CW-1653 --Borrar SP ccsp_OUTDeleteJobBlackList para poder crearlo'
        set @Sql= 'if exists (select * from sys.procedures where name = N''ccsp_OUTDeleteJobBlackList'')
    begin
        DROP PROCEDURE ccsp_OUTDeleteJobBlackList;
    end'
        EXEC(@Sql)


		set @process = 'CW-1653 --Crear SP ccsp_OUTDeleteJobBlackList'
        set @Sql= 'CREATE procedure [dbo].[ccsp_OUTDeleteJobBlackList]
@callout_id int
as
set nocount on

if exists(select * from ccoWorkingTable where callout_id = @callout_id)	
	
	insert into ccoLogBlackList (callOut_Id,telephone,calKey,camId,DateDeleteWT)
	select callout_id,cal_telefono,cal_keyw,cam_id,getDate() from ccoWorkingTable where callout_id = @callout_id

	DELETE ccoWorkingTable WHERE callout_id = @callout_id

set nocount off'
        EXEC(@Sql)


		set @process = 'CW-1653 --Borrar SP ccsp_PhoneInBL para poder crearlo'
        set @Sql= 'if exists (select * from sys.procedures where name = N''ccsp_PhoneInBL'')
    begin
        DROP PROCEDURE ccsp_PhoneInBL;
    end'
        EXEC(@Sql)


		set @process = 'CW-1653 --Modificacion al SP ccsp_PhoneInBL'
        set @Sql= 'CREATE PROCEDURE [dbo].[ccsp_PhoneInBL]
@action as tinyint,
@cam_id as smallint,
@telefono as varchar(20),
@cal_key as varchar(30) = null
AS
if @action = 1
begin
	declare @hashPhone int,@hashCallKey int 
	set @hashPhone= (cast(@telefono as bigint) % 127499997)
	
	if @cal_key is not null and @cal_key<>'''' set @hashCallKey= dbo.hashList(@cal_Key) 	

	if @hashCallKey is null begin
		if exists(SELECT telefono from cclistanegra nolock where Hashtel = @hashPhone and HashKey is null
		and idtipolista in (select ln.idtipolista from Camplistanegra (nolock) cl left join ccTiposListaNegra (nolock) ln 
			on ln.idtipolista=cl.idtipolista where cam_id = @cam_id))	
			select 1
		else
			select 0

	end 
	else begin
		if exists(SELECT telefono from cclistanegra nolock where Hashtel = @hashPhone and HashKey is null
		and idtipolista in (select ln.idtipolista from Camplistanegra (nolock) cl left join ccTiposListaNegra (nolock) ln 
			on ln.idtipolista=cl.idtipolista where cam_id = @cam_id))	
		begin
			select 1
		end		

		else if exists(SELECT telefono from cclistanegra nolock where Hashtel = @hashPhone and HashKey = @hashCallKey
			and idtipolista in (select ln.idtipolista from Camplistanegra (nolock) cl left join ccTiposListaNegra (nolock) ln 
				on ln.idtipolista=cl.idtipolista where cam_id = @cam_id))	
			select 1
		else
			select 0
	end
end'
        EXEC(@Sql)


		set @process = 'CW-1653 --Borrar SP xx_ChecaVersion para poder crearlo'
        set @Sql= 'if exists (select * from sys.procedures where name = N''xx_ChecaVersion'')
    begin
        DROP PROCEDURE xx_ChecaVersion;
    end'
        EXEC(@Sql)

		set @process = 'CW-1653 --Crear SP xx_ChecaVersion'
        set @Sql= 'CREATE procedure [dbo].[xx_ChecaVersion]
@major as integer,
@minor as integer
as

if @major=1 and @minor=15
	select 1 as ok
else
	select 0 as ok'
        EXEC(@Sql)


		set @process = 'CW-1653 --Añadir una columna a la tabla ccListaNegra'
        set @Sql= 'if not exists (select * from sys.columns where name = N''Hashtel'' and Object_ID = Object_ID(N''ccListaNegra''))
begin
	alter table ccListaNegra add Hashtel int
end'
        EXEC(@Sql)


		set @process = 'CW-1653 --Añadir una columna a la tabla ccListaNegra'
        set @Sql= 'if not exists (select * from sys.columns where name = N''HashKey'' and Object_ID = Object_ID(N''ccListaNegra''))
begin
	alter table ccListaNegra add HashKey int
end'
        EXEC(@Sql)


		set @process = 'CW-1653 --Borrar PK de la tabla ccListaNegra'
        set @Sql= 'if exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''ccListaNegra'')
    begin
        ALTER TABLE ccListaNegra DROP CONSTRAINT PK_ccListaNegra
    end'
        EXEC(@Sql)


		set @process = 'CW-1653 --Modificacion al SP ccsp_Limpia'
        set @Sql= 'ALTER procedure [dbo].[ccsp_Limpia]
@tel varchar(30),
@Camp int = 0,
@calKey varchar(20) = ''''
			
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



--PARA LA VALIDACION DE LISTAS NEGRAS CON HASH
declare @hasTelefono bigint
select @hasTelefono =(cast(@tel as bigint) % 127499997)			
declare @hasCalKey bigint
select @hasCalKey = dbo.hashList(@calKey)
			
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
	on (a1.idtipolista=a2.idtipolista) where a2.cam_id=@Camp and status=1 and
	a1.Hashtel = @hasTelefono and a1.HashKey is null)
		begin
		select 4 as res, @tel as tel
		return(0)
		end
								
	else if exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra))
	on (a1.idtipolista=a2.idtipolista) where a2.cam_id=@Camp and status=1 and
	a1.Hashtel = @hasTelefono and (@hasCalKey > 0  and a1.HashKey = @hasCalKey)  )
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
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and a1.Hashtel = @hasTelefono and (@hasCalKey = 0  OR a1.HashKey = @hasCalKey) and status=1)
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
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and
		a1.Hashtel = @hasTelefono and (@hasCalKey = 0  OR a1.HashKey = @hasCalKey)  and status=1)
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
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and 
		a1.Hashtel = @hasTelefono and (@hasCalKey = 0  OR a1.HashKey = @hasCalKey) 
			and status=1)
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
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and a1.Hashtel = @hasTelefono and (@hasCalKey = 0  OR a1.HashKey = @hasCalKey)  and status=1)
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
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and 
		a1.Hashtel = @hasTelefono and (@hasCalKey = 0  OR a1.HashKey = @hasCalKey) 
			and status=1)
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
		if not exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra)) on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and 
		a1.Hashtel = @hasTelefono and (@hasCalKey = 0  OR a1.HashKey = @hasCalKey) 
			and status=1)
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
							and a1.Hashtel = @hasTelefono and (@hasCalKey = 0  OR a1.HashKey = @hasCalKey) 
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
							and a1.Hashtel = @hasTelefono and (@hasCalKey = 0  OR a1.HashKey = @hasCalKey) 
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
							and a1.Hashtel = @hasTelefono and (@hasCalKey = 0  OR a1.HashKey = @hasCalKey) 
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
							and a1.Hashtel = @hasTelefono and (@hasCalKey = 0  OR a1.HashKey = @hasCalKey) 
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
							and a1.Hashtel = @hasTelefono and (@hasCalKey = 0  OR a1.HashKey = @hasCalKey) 
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


if @pais = 16 -- Panama
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
							and a1.Hashtel = @hasTelefono and (@hasCalKey = 0  OR a1.HashKey = @hasCalKey) 
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


		set @process = 'CW-1653 --Modificacion al SP ccsp_InsertDNCList'
        set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey int=null
AS

declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)

insert into cclistanegra(telefono,idtipolista,HashKey) values(@telephone, @ln_id,@hashCalKey)

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
        EXEC(@Sql)


		set @process = 'CW-1653 --Modificacion al SP ccsp_RIADNCList'
        set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIADNCList]
@phoneNumber as varchar(30),
@idDNCList as integer,
@tipoMov as tinyint,
@calKey as varchar(20)=null
AS

declare @hashCalKey int,@hashPhone bigint




if @calKey is not null begin
	select @hashCalKey =dbo.hashList(@calKey)
end 


if @tipoMov = 1 begin -- Inserta Lista Negra	
	exec ccsp_InsertDNCList @telephone= @phoneNumber, @ln_id = @idDNCList,@hashCalKey=@hashCalKey
	insert cchistoriallistanegra (telefono,idtipomov,idtipolista) values (@phoneNumber,7,@idDNCList)
end

if @tipoMov = 2 begin -- Borra Lista Negra	

	set @hashPhone= convert(bigint,@phoneNumber) % 127499997
	if @hashCalKey is null  begin
		delete from cclistanegra where Hashtel = @hashPhone and HashKey is null and idtipolista = @idDNCList
	end
	else begin
		delete from cclistanegra where Hashtel = @hashPhone and HashKey=@hashCalKey and idtipolista = @idDNCList
	end
	insert cchistoriallistanegra (telefono,idtipomov,idtipolista) values (@phoneNumber,5,@idDNCList)
end

if @tipoMov = 3 begin -- Reemplaza Lista Negra
	insert cchistoriallistanegra(telefono,idtipomov,idtipolista) select telefono,''4'',@idDNCList from cclistanegra where idtipolista= @idDNCList
	delete from cclistanegra where idtipolista = @idDNCList
end'
        EXEC(@Sql)


		set @process = 'CW-1653 --Modificacion al SP ccsp_RIAUploadBLst'
        set @Sql= 'ALTER procedure [dbo].[ccsp_RIAUploadBLst]
@command tinyint,
@telephone varchar(20) = 0,
@idtipolista int,
@calKey as varchar(20)=null
AS
set nocount on
declare @hashCalKey int,@hashPhone bigint


set @hashPhone= convert(bigint,@telephone) % 127499997

if @calKey is not null begin
	select @hashCalKey =dbo.hashList(@calKey)
end 

if @hashCalKey is null begin
	if @command in (1,4)--LookForNumber
	--and exists(SELECT idtipolista FROM cclistanegra where telefono= @telephone and idtipolista=@idtipolista)
	and exists(SELECT idtipolista FROM cclistanegra where Hashtel= @hashPhone and HashKey is null)
	 begin
		select 1
		return(0)
	 end
 end
else begin
	if @command in (1,4)--LookForNumber	
	and exists(SELECT idtipolista FROM cclistanegra where Hashtel= @hashPhone and HashKey=@hashCalKey)
	 begin
		select 1
		return(0)
	 end

end

if @command=1--Insert Number
 begin
	exec ccsp_InsertDNCList @telephone, @idtipolista,@hashCalKey
   	insert into cchistoriallistanegra (telefono,idtipomov,idtipolista) values(@telephone,1,@idtipolista)
	return(0)
 end

if @command=2--Delete Number
 begin
	insert into cchistoriallistanegra (telefono,idtipomov,idtipolista) values(@telephone,5,@idtipolista)
	--Delete from cclistanegra where telefono=@telephone and idtipolista=@idtipolista
	if @hashCalKey is null begin
		Delete from cclistanegra where Hashtel= @hashPhone and HashKey is null
	end
	else begin
		Delete from cclistanegra where Hashtel= @hashPhone and HashKey=@hashCalKey
	end
	return(0)
 end

if @command=3--Reemplaza
 begin
	insert cchistoriallistanegra (telefono,idtipomov,idtipolista) select telefono,4,@idtipolista from cclistanegra where idtipolista=@idtipolista
	delete from cclistanegra where idtipolista=@idtipolista
	return(0)
 end

if @command=5--Delete by idtipolista
 begin
	update ccTiposListaNegra set Status = 0 where idtipolista = @idtipolista

	delete ccAgendaListaNegra where idagenda in 
	(select idagenda from ccAgenda_TipolistaNegra where idtipolista = @idtipolista)

	delete ccAgenda_TipolistaNegra where idtipolista = @idtipolista
	delete cccalifblacklist where idtipolista = @idtipolista
	delete Camplistanegra where idtipolista = @idtipolista

	declare @telefono varchar(10)
	while exists(select telefono from ccListaNegra where idtipolista = @idtipolista)
	 begin
		select top 1 @hashPhone = Hashtel,@telefono=telefono from ccListaNegra where idtipolista = @idtipolista
		insert into cchistoriallistanegra (telefono,idtipomov,idtipolista) values(@telefono,5,@idtipolista)
		Delete from cclistanegra where Hashtel=@hashPhone and idtipolista=@idtipolista
	 end
	return(0)
 end
set nocount off'
        EXEC(@Sql)


		set @process = 'CW-1653 --Creacion de Trigger trigZonaHoraria'
        set @Sql= 'if not exists (select * from sys.triggers where name = N''trigZonaHoraria'' and parent_id = OBJECT_ID(N''ccListaNegra''))
    begin
        CREATE TRIGGER [dbo].[trigHashPhone] ON [dbo].[ccListaNegra]
FOR INSERT
AS
SET NOCOUNT ON
begin	
	update A set A.Hashtel= convert(bigint,B.telefono) % 127499997	from ccListaNegra A
	inner join INSERTED B on  A.idtipolista=B.idtipolista and A.telefono=B.telefono 

end
    end'
        EXEC(@Sql)

        set @process = 'CW-2022 -- VERSION 120.14 Alter SP ccsp_RIAvoiceMail '
		set @Sql= 'ALTER procedure [dbo].[ccsp_RIAvoiceMail]
@type as tinyint,
@msgId int=null,
@bSent int=null,
@mailType int = 0 -- Other=0; ChatMailAdmin=1; ChatMailClient=2
as
set nocount on
if @type=1 -- getSettings
 begin
	declare @SMTP_setting varchar(255)
	declare @svr as varchar(50), @usr as varchar(50), @pwd as varchar(50), @ssl as bit, @typeSend as bit
	declare @smtpPort as integer

	select @SMTP_setting=valor from ccsettings where setting_id=98
	select @svr = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 1
	select @usr = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 2
	select @pwd = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 3	
	select @smtpPort = cast(value as integer) from  dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 4
	select @ssl = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 5
	select @typeSend = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 6
	if isnull(@smtpPort,0)=0 set @smtpPort=25
	if isnull(@ssl,0)=0 set @ssl=0
	if isnull(@typeSend,0)=0 set @typeSend=0
	
	select isNull(@svr,'''')  as svr, isNull(@usr,'''') as usr, isNull(@pwd,'''') as pwd, @smtpPort as smtpPt, @ssl as [ssl], @typeSend as [typeSend]
	return(0)
 end

else if @type=2 begin-- getMailBoxes 
	if isnull(@msgId,0)=0
	 begin
		raiserror(''Missing msgId'', 18, 1)
		return(0)
	 end

	declare @inbound_id int, @calid int, @acdName varchar(50)

	if @mailType = 0 begin
		select @calid=cal_id from ccRIA_vmMessages where vmID=@msgId
		select @inbound_id=inbound_id from ccCallsIn where cal_id=@calid
	end
	else begin
		select @calid=chatId from ccRIAChatMailbox where ID=@msgId
		select @inbound_id=inboundId from ccRIAChats where chatId=@calid
	end
	
	select @acdName = descripcion from ccInbound where Inbound_id = @inbound_id
	
	if @mailType = 2 begin
		select '''', @acdName as acdName
		return(0)
	end

	select mailbox, @acdName as acdName from ccRIA_vmMailBoxes M join ccRIA_vmACDMailBoxes A on M.vmID = A.vmID
	where A.inbound_id in (0,@inbound_id)
	return(0)
 end

else if @type=3 begin-- getNext
 
 declare @mailBySend table(
	idm int,
	nameFile varchar(256),
	[type] int,
	Inbound_id int,
	acdName varchar(100)
	)

	insert into @mailBySend
	select top 30  * from (
	select vmID, archivo, 1 as [type],C.Inbound_id,ISNULL(I.descripcion,'''') as acdName from ccRIA_vmMessages M
	inner join ccCallsIn C on M.cal_id=C.cal_id
	left join ccInbound I on C.Inbound_id=I.Inbound_id
	where vmStatus=0  
	union
	select M.ID, M.[file] as [file],2 as [type],C.inboundId,ISNULL(I.descripcion,'''') as acdName   from ccRIAChatMailbox M
	inner join ccRIAChats C on M.chatID=C.chatID
	left join ccInbound I on C.inboundId=I.Inbound_id
	where M.[status] = 0 
	)x
	where 
	Inbound_id in(

	select distinct A.inbound_id  from ccRIA_vmMailBoxes M 
	inner join ccRIA_vmACDMailBoxes A on M.vmID = A.vmID 
	)

	

	update A set vmintentos=vmintentos+1 from ccRIA_vmMessages A 
	inner join @mailBySend B on A.vmID=B.idm and B.type=1

	update A set tries=tries+1 from ccRIAChatMailbox A 
	inner join @mailBySend B on A.ID=B.idm and B.type=2
	
	select * from @mailBySend

	return(0)
 end

else if @type=4 begin-- setResult 
	if @bSent is null or isnull(@msgId,0)=0
	 begin
		raiserror(''Missing data'', 18, 1)
		return(0)
	 end

 	if @bSent=1  begin
		if @mailType = 0 begin
			update ccRIA_vmMessages set vmStatus=1 where vmID=@msgId			
		end
		else begin
			update ccRIAChatMailbox set [status] = 1 where ID = @msgId						
		end
		return(0)
	 end

	if @mailType = 0  begin
		update ccRIA_vmMessages set vmStatus=case when vmintentos<10 then vmStatus else 2 end where vmID=@msgId 
	end
	else begin
		update ccRIAChatMailbox set [status]=case when tries<10 then [status] else 2 end where ID=@msgId 
	end		
	return(0)	
	
	
	 end
	else if @type=5  begin-- reset vmintentos
		if @mailType = 0 begin
			update ccRIA_vmMessages set vmintentos=case when vmintentos>1 then vmintentos-1 else 0 end where vmID=@msgId		
		end
		else begin
			update ccRIAChatMailbox set tries=case when tries>1 then tries-1 else 0 end where [ID]=@msgId		
		end
	 end'
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
