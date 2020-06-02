/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author:
Date: 2014/10/06
Description:

	--- ALTER TABLE ccTimeZoneArea
	--- insert ccmenus
	--- insert ccmenus
	--- insert into ccTimeZoneArea
	--- CREATE ccRIAMultimediaAddress
	--- CREATE ccRIAMultimediaAddressRel
	--- CREATE procedure ccsp_RIAMultimediaAddresses
	--- ALTER FUNCTION fnGetTimeZone
	--- ALTER  PROCEDURE ccsp_GetAgentIndividualCounters
	---




Database: CCenterRia
Required version: 117

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
set  @versionfix = 2

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL =valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and @actualVersionFix = @versionfix -1
	begin
		begin tran
		begin try

	set @process = 'Drop PRIMARY KEY -- ccTimeZoneArea '
	set @Sql = 'if exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''ccTimeZoneArea'')
	begin
		ALTER TABLE ccTimeZoneArea DROP CONSTRAINT PK_ccTimeZoneArea_1
	end'
	exec(@sql)

	set @process = 'ADD PRIMARY KEY  ccTimeZoneArea '
	set @Sql = 'if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''ccTimeZoneArea'')
	begin
		ALTER TABLE ccTimeZoneArea ADD CONSTRAINT PK_ccTimeZoneArea_1 PRIMARY KEY (id_country, area, location)
	end'
	exec(@sql)

	set @process = 'insert  ------- ccTimeZoneArea'
	set @Sql = 'insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''222'', ''TLAX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''223'', ''TLAX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''232'', ''PUE'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''236'', ''OAX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''248'', ''TLAX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''273'', ''PUE'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''274'', ''OAX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''276'', ''TLAX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''282'', ''PUE'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''283'', ''OAX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''287'', ''VER'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''312'', ''JAL'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''313'', ''MICH'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''322'', ''NAY'', 128, 64, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''346'', ''ZAC'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''352'', ''GTO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''354'', ''JAL'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''393'', ''MICH'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''419'', ''QRO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''421'', ''MICH'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''424'', ''JAL'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''427'', ''MEX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''437'', ''JAL'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''437'', ''NAY'', 128, 64, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''438'', ''GTO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''441'', ''HGO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''442'', ''GTO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''457'', ''JAL'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''458'', ''AGS'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''458'', ''SLP'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''482'', ''TAMPS'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''483'', ''HGO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''487'', ''QRO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''488'', ''NL'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''489'', ''VER'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''495'', ''JAL'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''496'', ''AGS'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''496'', ''JAL'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''496'', ''SLP'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''499'', ''JAL'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''55'', ''MEX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''591'', ''HGO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''629'', ''DGO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''649'', ''DGO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''653'', ''BC'', 256, 128, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''671'', ''COAH'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''711'', ''MICH'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''721'', ''GRO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''741'', ''OAX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''743'', ''MEX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''746'', ''HGO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''746'', ''PUE'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''748'', ''TLAX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''751'', ''MEX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''753'', ''GRO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''757'', ''OAX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''761'', ''MEX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''767'', ''GRO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''767'', ''MICH'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''774'', ''VER'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''776'', ''HGO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''789'', ''HGO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''833'', ''VER'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''842'', ''ZAC'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''867'', ''COAH'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''867'', ''NL'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''871'', ''DGO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''872'', ''DGO'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''873'', ''COAH'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''913'', ''CAMP'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''917'', ''CHIS'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''923'', ''TAB'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''924'', ''OAX'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''932'', ''CHIS'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''934'', ''CHIS'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''953'', ''PUE'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''983'', ''CAMP'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''994'', ''CHIS'', 64, 32, NULL)
insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
values (1, ''997'', ''QROO'', 32, 16, NULL)'
	EXEC(@sql)

	set @process = 'insert ccmenus  -------  '
	set @Sql = 'if not exists (Select * from ccmenus where menu_id=85)
begin
	insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (85,''Direcciones CC de Email|Email CC Addresses'',80,''B'',84,1,'''')
end'
	EXEC(@sql)


	set @process = 'Insertar registro para Chats en la tabla ccChatsNode --'
	set @Sql= 'if not exists(select * from ccMenus where menu_id in (81,84) and type=1)  begin
		insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF)  values(81,''Asignar correos de salida|Assign outgoing mail'',16,''B'',40,1,'''')
		insert ccMenus (menu_id,menu_descrip,parent,nivel,ordengral,type,HelpSWF) values (84,''Firmas de Email|Email Signatures'',16,''B'',40,1,'''')
					end'
	EXEC(@Sql)

	set @process = 'ALTER FUNCTION fnGetTimeZone-------  '
	set @Sql = 'ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN
	declare @lada as varchar(5)
	declare @timeZone as int
	declare @ld as varchar(5)
	declare @location as varchar(500)

	select @lada = valor from ccsettings where setting_id = 17
	select @ld = ''''
	select @location = ''''

	declare @country as tinyInt
	select @country = valor from ccSettings where setting_id = 104

		if @country = 1 begin
			select @ld = case when left(@phone, 2) in (''55'', ''33'', ''81'') then left(@phone, 2) else left(@phone, 3) end

			select @location = estado
			from series
			where cld = @ld
			and serie = substring(@phone, len(@ld) + 1, 6 - len(@ld))
			and right(@phone, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
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

		if @country = 2 begin
			declare @telTemp varchar(15)
			set @telTemp = @phone
			select @phone = dbo.Completa(@phone)
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
		select @phone = dbo.Completa(@phone)
		-- len(@phone) = 10
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
			where id_country = @country and (
			(convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
			(convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
		end
	end

	if @country = 10 begin
		select @phone = dbo.Completa(@phone)
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
		select @phone = dbo.Completa(@phone)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	if @country = 12 begin
		select @phone = dbo.Completa(@phone)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	if @country = 13 begin
		select @phone = dbo.Completa(@phone)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	return isNull(@timeZone,0)
 END'
	EXEC(@sql)

	set @process = 'ALTER  PROCEDURE ccsp_GetAgentIndividualCounters -------'
	set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters] @type as int, @sup_id as int = 0 as
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

	set @process = 'ALTER procedure [dbo].[ccsp_RIACATMenu]  -------  '
	set @Sql = 'ALTER procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
Declare @AVRS tinyint
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenusChat tinyint
Declare @MenuMail tinyint
Declare @MenuCRM tinyint

set @MenuMail=0
set @MenuCRM = 0

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155
select @MenuCRM = valor from ccsettings where setting_id = 168

---Mail MenuId (81)
if @Type=1
begin
	if @ReportRol = 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
		and (
		(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82,84,85))
		or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
		or (menu_id in (71,72) and @IVRScripting = 1)
		or (menu_id in (73,74,75,76) and @AVRS = 1)
		or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
		or (menu_id = 79 and @MenusChat > 0)
		or (menu_id in (81,82,84,85) and @MenuMail = 1)--Mail
		or (menu_id = 83 and @MenuCRM > 0)
		)
		order by ordengral asc
		return(0)

	end
	else if @ReportRol = 3 begin
		select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) and menu_id not in (select distinct Parent from ccMenus where menu_id >= 2000 and type = 3)
		and (menu_id not in (3131,3132,3133,3134,3135,3136,8061,8062,8063,8071,8072,8080,10000,10010,10020,10030,10040))
		or  (menu_id     in (3131,3132,3133,3134,3135,3136) and @MenusChat > 0 )
		or  (menu_id     in (8061,8062,8063,8071,8072,8080) and @AVRS > 0)
		or  (menu_id     in (9000,9010) and @MenuCRM > 0 )
		or  (menu_id     in (10000,10010,10020,10030,10040) and @MenuMail > 0 )

		order by ordengral asc
		return(0)
	end
	else begin
		select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)
	end

end

if @Type=2
begin
  delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu and type = @ReportRol
  return(0)
end

if @Type=3
begin
  insert into ccMenuUser(id_User,id_Menu,type) values (@id_User, @id_Menu,@ReportRol)
  return(0)
end

if @Type=4
begin
  declare @lan varchar(3), @page varchar(200)
  select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
  select @lan = case valor when 0 then ''ES'' else ''EN'' end from ccSettings where setting_id = 27

  select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
  return(0)
end

set nocount off'
	EXEC(@sql)

	set @process = 'ALTER procedure [dbo].[ccsp_RIACATMenu]  -------  '
	set @Sql = 'ALTER procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
Declare @AVRS tinyint
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenusChat tinyint
Declare @MenuMail tinyint
Declare @MenuCRM tinyint

set @MenuMail=0
set @MenuCRM = 0

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155
select @MenuCRM = valor from ccsettings where setting_id = 168

---Mail MenuId (81)
if @Type=1
begin
	if @ReportRol = 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
		and (
		(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82,84,85))
		or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
		or (menu_id in (71,72) and @IVRScripting = 1)
		or (menu_id in (73,74,75,76) and @AVRS = 1)
		or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
		or (menu_id = 79 and @MenusChat > 0)
		or (menu_id in (81,82,84,85) and @MenuMail = 1)--Mail
		or (menu_id = 83 and @MenuCRM > 0)
		)
		order by ordengral asc
		return(0)

	end
	else if @ReportRol = 3 begin
		select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) and menu_id not in (select distinct Parent from ccMenus where menu_id >= 2000 and type = 3)
		and (menu_id not in (3131,3132,3133,3134,3135,3136,8061,8062,8063,8071,8072,8080,10000,10010,10020,10030,10040))
		or  (menu_id     in (3131,3132,3133,3134,3135,3136) and @MenusChat > 0 )
		or  (menu_id     in (8061,8062,8063,8071,8072,8080) and @AVRS > 0)
		or  (menu_id     in (9000,9010) and @MenuCRM > 0 )
		or  (menu_id     in (10000,10010,10020,10030,10040) and @MenuMail > 0 )
		order by ordengral asc
		return(0)
	end
	else begin
		select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)
	end

end

if @Type=2
begin
  delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu and type = @ReportRol
  return(0)
end

if @Type=3
begin
  insert into ccMenuUser(id_User,id_Menu,type) values (@id_User, @id_Menu,@ReportRol)
  return(0)
end

if @Type=4
begin
  declare @lan varchar(3), @page varchar(200)
  select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
  select @lan = case valor when 0 then ''ES'' else ''EN'' end from ccSettings where setting_id = 27

  select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
  return(0)
end

set nocount off'
	EXEC(@sql)

	set @process = 'ALTER procedure [dbo].[ccsp_RIAMenuRoles]  -------  '
	set @Sql = 'ALTER procedure [dbo].[ccsp_RIAMenuRoles]
@Type tinyint,
@User_id smallint = null,
@Role_id smallint = null,
@InsertMenu_id smallint = null,
@DeleteMenu_id smallint = null,

@firstSup smallint = null,
@reportRol tinyint = 1,
@AVRS tinyint = null,
@CM tinyint = 0,
@AE tinyint = 0
as
set nocount on

select @reportRol = case @reportRol when 0 then 1 else @reportRol end, @role_id = case @role_id when 0 then 1 else @role_id end

Declare @NRS tinyint
declare @MenusChat tinyint
declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenuMail tinyint
Declare @MenuCRM tinyint

set @MenuMail = 0
set @MenuCRM = 0

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

---Checar si esta se aplica
select @AVRS = valor from ccSettings where setting_id = 124
select @IVRScripting = valor from ccsettings where setting_id = 125

select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
--Activa menus relacionados con campañas
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155
select @MenuCRM = valor from ccsettings where setting_id = 168

If @Type = 1 -- Carga todos los roles
	begin
		select Role_id, Description from ccRIACat_AdminRole where type = @reportRol order by priority
		return(0)
	end

If @Type = 2 -- Carga los menus de un supervisor
	begin
	Select a.id_User, a.id_Menu, b.menu_descrip, Nivel, ordengral
	from ccMenuUser a inner join ccMenus b with(index(IX_ccMenus)) on a.id_Menu = b.menu_id and a.type = b.type
	where id_User = @User_id and a.Type = @reportRol and ((a.id_Menu not in (41,42, 53)) or
	(a.id_Menu = 41 and @CM = 1) or (a.id_Menu = 42 and @AE > 0) or (a.id_Menu = 53 and @NRS = 1))
	order by ordengral asc
	return(0)
	end

If @Type = 3 -- Return the menus of a rol
	begin
	select a.Role_id, b.menu_id, b.menu_descrip, b.Nivel, b.ordengral
	from ccRIARoleMenu a inner join ccMenus b with(index(IX_ccMenus)) on b.menu_id = a.id_Menu and a.type = b.type
	where a.Role_id = @Role_id and
	a.type = @reportRol and
	((b.menu_id not in (41,42,53)) or (b.menu_id = 41 and @CM = 1) or (b.menu_id = 42 and @ae > 0) or (b.menu_id = 53 and @NRS = 1))
	order by a.Role_id, b.ordengral asc
	return(0)
	end

If @Type = 4 -- Insert
	begin
	if (@InsertMenu_id <> 0) or not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
	begin
		if @Role_id in (1, 10, 14) begin
			if @InsertMenu_id <> 0 and not exists(select * from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
				insert into ccMenuUser (id_User, id_Menu, type) values(@User_id, @InsertMenu_id, @reportRol)
			if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40)begin
				Insert into ccMenuUser (id_User, id_Menu, type)values(@User_id,40,@reportRol)
			end
			else If @reportRol = 2 and not exists(select id_User from ccMenuUser where id_User = @User_id and (id_Menu between 1000 and 1999)) begin
					Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, menu_id, @reportRol from ccMenus with(index(IX_ccMenus)) where menu_id between 1000 and 1999
				end
			else if @reportRol = 3 begin
				insert into ccMenuUser (id_User, id_Menu, type) select @User_id, id_Menu, @reportRol from ccRIARoleMenu  where Role_id = @Role_id
			end
		end
		else if ((@InsertMenu_id = 53 and @NRS = 1) or (@InsertMenu_id <> 53) )
		begin
			if @InsertMenu_id <> 40	delete ccMenuUser where id_User = @User_id and type = @reportRol
				insert into ccMenuUser (id_User, id_Menu, type)	select @User_id, id_Menu, @reportRol from ccRIARoleMenu where Role_id = @Role_id and type = @reportRol
			if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40 and type = @reportRol)
				insert into ccMenuUser (id_User, id_Menu, type) values(@User_id,40,@reportRol)
		end
	end
	--Asigna un rol por default o lo actuliza
	if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
	else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)

	--Solo es necesario en caso admin y reports
	if @reportRol in(1,2) begin
		--    inserta parent en caso de no haberlo hecho en rol personalizado
		insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent
		where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0

		select @User_id, parent, @reportRol from
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent
		where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0

	end
	return (0)
	end

If @Type = 5 -- delete
	begin
		delete ccMenuUser where id_User = @User_id and id_Menu = @DeleteMenu_id and type = @reportRol
		if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
		else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
		return(0)
	end

If @Type = 6 -- Get userMenus
	begin
	if @reportRol = 2 begin --Reports version vieja
		select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
		from ccRIAUserRole a inner join ccMenuUser b on a.user_id = b.id_user
		inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
		where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol and
		((b.id_Menu not in (41,42,53)) or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1))
		and ( b.id_Menu not in(77,78) or (@RelationCampInbNotReady = 1 and b.id_Menu in(77,78)))
		and ( b.id_Menu not in(79) or (@MenusChat > 0 and b.id_Menu in(79)))
		and ( b.id_Menu not in(83) or (@MenuCRM > 0 and b.id_Menu in(83)))
		order by ordengral asc
		return(0)
	end
	else begin ---Sitio del administrador
		if not exists( select * from ccRIAUsr_AdminPermissions where User_id=@user_id and per_id=6)
		set @AVRS =0

		select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode

		from ccRIAUserRole a
		inner join ccMenuUser b on a.user_id = b.id_user
		inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
		where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol
		and (
			(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82,84,85))
			or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)
			or (menu_id in (71,72) and @IVRScripting = 1)
			or (menu_id in (73,74,75,76) and @AVRS = 1)
			or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
			or (menu_id = 79 and @MenusChat > 0)
			or (menu_id in (81,82,84,85) and @MenuMail = 1)--Mail
			or (menu_id = 83 and @MenuCRM > 0)
			)
		order by ordengral asc
		return(0)
	end
	end

If @Type = 7 -- Get language
	begin
		select valor from ccSettings where setting_id = 27
		return(0)
	end

If @Type = 8 -- Insert the personalized menus of a supervisor
	begin
		insert into ccMenuUser (id_User, id_Menu, type)
		select @User_id, id_Menu, @reportRol from ccMenuUser where id_User = @firstSup and type = @reportRol

		If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		begin
		    Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
		    return(0)
		end

		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
		return(0)
	end

If @Type = 9 -- Delete all supervisor menus
	begin
		delete ccMenuUser where id_User = @User_id and type = @reportRol
		return(0)
	end

If @Type = 10 -- update all supervisor menus
	begin

		if @AVRS = 1
		begin
			update ccUsers set tipoUser_id = 6 where user_id = @User_id
			return(0)
		end
	end

If @Type = 11 -- Verify level A menus
	begin
	--   inserta parent en caso de no haberlo hecho en rol personalizado
		Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where m.menu_id in (1000,2000,3000,4000) and u.id_User = @User_id and u.type = @reportRol
		group by m.parent) parent where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

		return(0)
	end

If @Type = 12
	begin
		declare @lan as tinyint
		select @lan = valor from ccSettings where setting_id = 27
		select menu_descrip from ccMenus with(index(IX_ccMenus)) where menu_id = @Role_id
		return(0)
	end

	if @Type = 13 --Agrega Menus por default a Admin en ReportsRia Agentes,ACD y Campañas
	begin
	insert into ccMenuUser([id_user],[id_Menu],[type])
	select a.User_id, b.menu_id, b.type
		from ccUsers a cross join ccMenus b
		left join ccMenuUser d on d.id_User = a.User_id and d.id_Menu = b.menu_id
		where a.TipoUser_id = 2 and b.type = 3 and d.id_User IS null and
		b.menu_id >= 2000 and b.menu_id < 5000 and a.User_id = @User_id

	insert into ccRIAUserRole([User_id],[Role_id],[type])
		select a.[User_id], 14 as role_id, 3 as type from ccUsers a
			left join ccRIAUserRole d on d.User_id = a.User_id and d.type = 3
			where d.User_id IS null and a.TipoUser_id = 2 and a.User_id = @User_id

	return (0)

	end

return(0)
set nocount off'
	EXEC(@sql)



	set @process = 'ALTER procedure [dbo].[ccsp_RIAConfEspec]  -------  '
	set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
@User_id int
AS
set nocount on

declare @sql nvarchar(max)

if not exists (SELECT * FROM sysobjects WHERE type = ''U'' AND name = ''ContactMeanIn'') begin
	set @sql=''select A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat, A.inactiveChatTime, A.maxChats, isnull(A.chatDomain,''''''''), A.chatQueueOverflow, A.chatTimeOverflow,
isnull(A.startStopRecording,0) startStopRecording,'''''''' as nameMail,'''''''' as conexionInfo,'''''''' as connUser,'''''''' as connPass,3 as numMessages,10 as timeAlertMessage, 0 as Active, 0 as answerTimeOut
from ccInbound A where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (''+convert(nvarchar(max),@User_id)+'', 2))''

end
else begin
	set @sql=''select A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat, A.inactiveChatTime, A.maxChats, isnull(A.chatDomain,''''''''), A.chatQueueOverflow, A.chatTimeOverflow,
isnull(A.startStopRecording,0) startStopRecording,isnull(B.name,'''''''') as nameMail,isnull(B.conexionInfo,'''''''') as conexionInfo,isnull(B.connUser,'''''''') as connUser,
isnull(B.ConnPass,'''''''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage, isnull(B.IsActive,0) as Active, 0 as answerTimeOut
from ccInbound A
left join ContactMeanIn B on A.inbound_id=B.inboundId
where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (''+convert(nvarchar(max),@User_id)+'', 2))''
	end

exec (@sql)

return(0)
set nocount off'
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