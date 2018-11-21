/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
		
Date: 2018/11/21
Description:

Database: CCenterRia
Required version: 120.35

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
set @versionfix = 36
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 35
	begin
		begin tran
		begin try

		 set @process = 'CW-1653 --Borrar SP ccsp_OUTDeleteJobBlackList para poder crearlo'
        set @Sql= 'if exists (select * from sys.procedures where name = N''ccsp_OUTDeleteJobBlackList'')
    begin
        DROP PROCEDURE ccsp_OUTDeleteJobBlackList;
    end'
        EXEC(@Sql)

		set @process = 'CW-1653 --Borrar SP ccsp_PhoneInBL para poder crearlo'
        set @Sql= 'if exists (select * from sys.procedures where name = N''ccsp_PhoneInBL'')
    begin
        DROP PROCEDURE ccsp_PhoneInBL;
    end'
        EXEC(@Sql)

		set @process = 'CW-1653 --Borrar SP xx_ChecaVersion para poder crearlo'
        set @Sql= 'if exists (select * from sys.procedures where name = N''xx_ChecaVersion'')
    begin
        DROP PROCEDURE xx_ChecaVersion;
    end'
        EXEC(@Sql)

         set @process = 'CW-1653 --Setting 209 Search for do-not-call numbers in server memory'
        set @Sql= 'if not exists(select * from ccSettings where setting_id=209) begin
	--Portugues no esta es necesario agregar  --->Validar as listas negras para os números na memória do servidor
	insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) 
	values(209,''0'',''Realizar validación de lista negra a números en memoria del servidor'',1,''X'',''El marcado predictivo revisara todos los registros a marcar si el esta 1, 0 la revision la realizara solo el databaseLoader es necesario reiniciar para tome el cambio''
		,''Search for do-not-call numbers in server memory'',0,''^[0-1]$'')
end'
        EXEC(@Sql)
	
	set @process = 'CW-1653 --Borrar PK de la tabla ccListaNegra'
        set @Sql= 'if exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''ccListaNegra'')
    begin
        ALTER TABLE ccListaNegra DROP CONSTRAINT PK_ccListaNegra
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

        set @process = 'CW-1653 --function hashList'
		if not exists (select * from sys.objects where object_id = OBJECT_ID(N'hashList') and type in (N'FN', N'IF', N'TF', N'FS', N'FT')) begin
        set @Sql= 'CREATE FUNCTION [dbo].[hashList] (@calKey varchar(255)) 
RETURNS bigint AS
BEGIN
declare @codigo varchar(max)
declare @hash bigint

set @codigo=''''
set @hash=0
declare @i int,@len int
select @i=1,@len=len(@calKey)
while @i<=@len begin
	select @codigo=@codigo+convert(varchar(max), ASCII(SUBSTRING(@calKey,@i,1)))
	
	if @i%5=0 begin
		set @hash=@hash+cast(@codigo as bigint)
		set @codigo=''''
	end	
	set @i=@i+1
end
if @codigo<>''''
set @hash=@hash+cast(@codigo as bigint)
return @hash % 127499997
END'
       EXEC(@Sql)
	   end

	    set @process = 'CW-1653 --function ValidateBlackListPhone'
		if not exists (select * from sys.objects where object_id = OBJECT_ID(N'ValidateBlackListPhone') and type in (N'FN', N'IF', N'TF', N'FS', N'FT')) begin
        set @Sql= 'CREATE FUNCTION [dbo].[ValidateBlackListPhone](@tel varchar(32),@camId int,@calKey varchar(20))
RETURNS bit AS
BEGIN
	declare @isBlackPhone bit
	--PARA LA VALIDACION DE LISTAS NEGRAS CON HASH
	declare @hasTelefono bigint
	select @hasTelefono =(cast(@tel as bigint) % 127499997)			
	declare @hasCalKey bigint
	if @calKey is not null or @calKey <> ''''
		select @hasCalKey = dbo.hashList(@calKey)

	
	set @isBlackPhone=0
	if exists(	
		select a2.idtipolista from cclistanegra a1 
		inner join camplistanegra a2 with(index(IX_Camplistanegra)) on a1.idtipolista=a2.idtipolista
		where a2.cam_id=@camId and status=1 
		and	a1.Hashtel = @hasTelefono and ( a1.HashKey is null or  a1.HashKey = @hasCalKey)
	)
		set @isBlackPhone=1		
	
	return @isBlackPhone
END'
       EXEC(@Sql)
	   end
		

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
		

		set @process = 'CW-1653 --Modificacion al SP ccsp_PhoneInBL'
        set @Sql= 'CREATE PROCEDURE [dbo].[ccsp_PhoneInBL]
@action as tinyint,
@cam_id as smallint,
@telefono as varchar(20),
@cal_key as varchar(30) = null
AS
if @action = 1 begin	
	if (select dbo.ValidateBlackListPhone(@telefono,@cam_id,@cal_key)) = 1 begin
		select 1 as IsBlackList
	end
	else begin
		select 0 as IsBlackList
	end
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
				

		set @process = 'CW-1653 --Creacion de Trigger trigZonaHoraria'
		if not exists (select * from sys.triggers where name = N'trigHashPhone' and parent_id = OBJECT_ID(N'ccListaNegra')) begin
        set @Sql= 'CREATE TRIGGER [dbo].[trigHashPhone] ON [dbo].[ccListaNegra]
FOR INSERT
AS
SET NOCOUNT ON
begin	
	update A set A.Hashtel= convert(bigint,B.telefono) % 127499997	from ccListaNegra A
	inner join INSERTED B on  A.idtipolista=B.idtipolista and A.telefono=B.telefono 

end'
      EXEC(@Sql)        
	  end


		set @process = 'CW-1653 --Modificacion al SP ccsp_Limpia'
        set @Sql= 'ALTER procedure [dbo].[ccsp_Limpia]
@tel varchar(50),
@Camp int = 0,
@calKey varchar(20) = ''''
			
as
set nocount on
declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint, @manOpt smallint, @validateTel smallint
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
select @manOpt = valor from ccsettings with(nolock) where setting_id = 195
select @validateTel = valor from ccsettings with(nolock) where setting_id = 206

if @lon>1 begin
	if @validateTel = 1 begin --Setting 206 para no validar longitud ni listas negras
		select 1 as res, @tel as tel
		return(0) 
	end

	if @extLen=@lon begin -- Setting 108 validar el tamaño de longitud del telefono
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
	
	if @manOpt =1 begin
		select 0 as res, @tel as tel
		return (0)
	end

	set @isLocal= case when left(@tel, len(@ld))= @ld then 1 else 0 end

	select @tel = case
      when @mod in (''FIJO'', ''MPP'') then case when @isLocal=1 then right(@tel, 10 - len(@ld)) else ''01'' + @tel end
      when @mod = ''CPP'' then case when @isLocal=1 then ''044'' + @tel else ''045'' + @tel end
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

		set @process = 'CW-1653 --Modificacion al SP ccsp_LimpiaUsa'
        set @Sql= 'ALTER procedure [dbo].[ccsp_LimpiaUsa]
@tel varchar(20),
@Camp int = 0,
@calKey varchar(20) = ''''
as
set nocount on
declare @lon tinyint

select @tel = dbo.limpia(@tel)
select @lon = len(@tel)

if @lon not in (7, 10, 11) and @tel <> ''911''
 begin
	select 1 as res, @tel as tel --Longitud invalida
	return(0)
 end

if @tel = ''911''
 begin
 	select 0 as res, @tel as tel -- ok
 	return(0)
 end

declare @ld varchar(4)
select @ld = valor from ccsettings where setting_id = 17

declare @len tinyint, @plans tinyint, @hl tinyint, @ht tinyint, @fl tinyint, @ft tinyint
declare @plan varchar(15), @tel10 varchar(10)
select @plan = valor from ccSettings where setting_id = 149
select @plans = COUNT(*) from dbo.fn_RIASplitDelimited(@plan,''|'')
if @plans = 4
begin
	select 
	 @hl = case when id = 1 then cast(value as tinyint) else @hl end,
	 @ht = case when id = 2 then cast(value as tinyint) else @ht end,
	 @fl = case when id = 3 then cast(value as tinyint) else @fl end,
	 @ft = case when id = 4 then cast(value as tinyint) else @ft end from dbo.fn_RIASplitDelimited(@plan,''|'')
	 print @hl
end
else if @plans = 2
begin
	select 
	 @hl = case when id = 1 then cast(value as tinyint) else @hl end,
	 @ft = case when id = 2 then cast(value as tinyint) else @ft end from dbo.fn_RIASplitDelimited(@plan,''|'')
	 select @ht = @hl, @fl = @ft
end
select @tel10 = RIGHT(@ld + @tel, 10)
if SUBSTRING(@tel10, 1, LEN(@ld)) = @ld
begin --HNPA
	set @len = @hl
	if @hl <> @ht and (select COUNT(*) from ccNPALocalPrefixes) > 0 and not exists(select * from ccNPALocalPrefixes where NPA+NXX = SUBSTRING(@tel10, 1, 6))
		set @len = @ht
end
else --FNPA
begin
	set @len = @ft
	if @fl <> @ft and (select COUNT(*) from ccNPALocalPrefixes) > 0 and exists(select * from ccNPALocalPrefixes where NPA+NXX = SUBSTRING(@tel10, 1, 6))
		set @len = @fl
end

select @tel = case @len when 7 then SUBSTRING(@tel10, 4, 7) when 10 then @tel10 when 11 then ''1'' + @tel10 end

-- lista negra
if (select dbo.ValidateBlackListPhone(@tel,@Camp,@calKey))=1 begin
	select 4 as res, @tel as tel --blackList
	return(0)
end	

select 0 as res, @tel as tel

set nocount off'
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
	and exists(
	SELECT idtipolista FROM cclistanegra where Hashtel= @hashPhone and HashKey is null and idtipolista=@idtipolista)
	 begin
		select 1
		return(0)
	 end
 end
else begin
	if @command in (1,4)--LookForNumber	
	and exists(SELECT idtipolista FROM cclistanegra where Hashtel= @hashPhone and HashKey=@hashCalKey and idtipolista=@idtipolista)
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


		set @process = 'CW-1653 --Modificacion al FN Completa_ListaNegra'
        set @Sql= 'ALTER FUNCTION [dbo].[Completa_ListaNegra] (@Cadena varchar(30))
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

	if @pais = 2 begin
		select @resultado = dbo.fnClearPhoneArg(@cadena)
		return @resultado
	end

	if @pais = 3 and left(@resultado,1) <> ''E'' begin
		select @resultado = case
			when len(@resultado) = 7 then @ld + @resultado
			when len(@resultado) in(8,10) then @resultado
			when len(@resultado) = 11 then right(@resultado,10)
			else ''E_NV_Longitud'' end
		return @resultado
	end

	if @pais = 5 and left(@resultado,1) <> ''E'' begin
		select @resultado = case
			when len(@resultado) in (6,7) then @ld + @resultado
			when len(@resultado) in (8,9) then @resultado
			when len(@resultado) = 10 then right(@resultado,9)
			else ''E_NV_Longitud'' end
		return @resultado
	end

	if @pais = 6 and left(@resultado,1) <> ''E'' begin
		select @resultado = case
			when len(@resultado) = 7 then @ld + @resultado
			when len(@resultado) = 10 then @resultado
			when len(@resultado) = 11 then right(@resultado,10)
			else ''E_NV_Longitud'' end
		return @resultado
	end

	if @pais = 7 and left(@resultado,1) <> ''E'' begin
		select @resultado = right(@resultado,10)
		return @resultado
	end

	if @pais = 8 begin
		if left(@resultado,1) = ''E'' begin
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

	if @pais in(9,10,11,12,13,14,15,16) and left(@resultado,1) <> ''E'' begin
		return @resultado
	end
	
end
else begin
	select @resultado = dbo.Limpia(@cadena)
end

return @resultado
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
