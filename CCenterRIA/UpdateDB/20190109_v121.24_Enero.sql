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
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 24

--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 22
BEGIN
	BEGIN TRAN

	BEGIN TRY
		--Drop-Start
		--Drop-End
		--Create-Start
		SET @process = 'CW-2152 Alter column Data'
		SET @Sql = 'alter table DataCallIn alter column [Data] varchar(255)'

		EXEC (@Sql)

		SET @process = 'CW-2220 Funcion Verifica CallBack alter ccinbound '
		SET @Sql = 'if not exists (select * from sys.columns where name = N''telFormato'' and Object_ID = Object_ID(N''ccinbound''))
      begin
      alter table ccinbound add telFormato tinyint null
      end'

		EXEC (@Sql)

		SET @process = 'CW-2018 CallBack Reminder alter column addDataCallBackReminder in ccInbound'
		SET @Sql = 'if not exists (select * from sys.columns where name = N''addDataCallBackReminder'' and Object_ID = Object_ID(N''ccInbound''))
    begin
        ALTER TABLE ccInbound ADD addDataCallBackReminder bit default(0)
    end'

		EXEC (@Sql)

		SET @process = 'CW-2018 CallBack Reminder table ccStatusLLamada ALTER COLUMN '
		SET @Sql = '
        ALTER TABLE ccStatusLLamada ALTER COLUMN descripcion varchar(50)  
      '

		EXEC (@Sql)

		SET @process = 'CW-2018 CallBack Reminder alter column ccStatusLlamada'
		SET @Sql = '
        ALTER TABLE ccStatusLLamada ALTER COLUMN descripcion varchar(50)
      '

		EXEC (@Sql)

		SET @process = 'CW-2393 ETIQUETAS EN PORTUGUES Validate y Detalle ccSettings -- Version BD 119.122 -- '
		SET @Sql = 'update ccSettings set detalle = ''Idioma en que apareceran tanto agente como admin RIA.  (0 español - 1 inglés - 2 portugués)'',validate = ''^[0-2]$'' where setting_id=27'

		EXEC (@Sql)

		SET @process = 'CW-2027 Plan de marcación update setting 195'
		SET @Sql = 'update ccSettings set descripcion=''"Estructuras especiales de marcación (México)'',
detalle=''Valor:(0) Local 7 o 8, LD 12 y Celular 13, Valor: (1) Local 10, LD 12 y Celular 13,Valor: (2) Local 10, LD 10 y Celular 10 '',
description=''Special dialing structures (Mexico)'',validate=''^[0-2]$''
 where setting_id=195'

		EXEC (@Sql)

		SET @process = 'CW-2027 Plan de marcación agregar a cstoTipoLlamada'
		SET @Sql = 'if not exists(select * from cstoTipoLlamada where country_id=1 and tipoLlamada_id=12)
    insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,prefijo,longitud)
    values (1,12,''Local'',''%'',''10'')'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 102.24 '
		SET @Sql = 'if not exists (select * from sys.tables where name = N''targetRecord'')
      begin
          create table targetRecord(
        targetT varchar(250) primary key,en varchar(255),es varchar(255),pt varchar(255)
      );
      end'

		EXEC (@Sql)

		SET @process = 'CW-2603 Reporte Clicks TCPA create tabla ClicksByAdmin '
		SET @Sql = 'if not exists (select * from sys.tables where name = N''ClicksByAdmin'')
      begin
        create table ClicksByAdmin  ( id int identity (1,1),  userId int, campId int, clicks int, date datetime );
      end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 102.24 '
		SET @Sql = 'if not exists (select * from sys.tables where name = N''valueRecord'')
      begin
        create table valueRecord(
        valueT varchar(250) primary key,es varchar(255),en varchar(255),pt varchar(255)
        );
      end'

		EXEC (@Sql)

		SET @process = 'CW-2605 -- Drop SP ccsp_Multimedia2'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_Multimedia2'')
    begin
        DROP PROCEDURE ccsp_Multimedia2;
    end'

		EXEC (@Sql)

		SET @process = 'CW-2605 -- Drop SP SaveClicksAdminByCamp'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''SaveClicksAdminByCamp'')
    begin
        DROP PROCEDURE SaveClicksAdminByCamp;
    end'

		EXEC (@Sql)

		SET @process = 'CW-2207 -- Drop function VerificaMex '
		SET @Sql = 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''VerificaMex'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    begin
        drop function VerificaMex
    end'

		EXEC (@Sql)

		SET @process = 'CW-2207 -- CREATE function VerificaMex '
		SET @Sql = 
			'CREATE FUNCTION [dbo].[VerificaMex] (@tel VARCHAR(32))
RETURNS VARCHAR(32)
AS
BEGIN
	DECLARE @ld VARCHAR(7)
	DECLARE @lon TINYINT
	DECLARE @result TINYINT
	DECLARE @mod VARCHAR(10)
	DECLARE @Cadena VARCHAR(32)
	DECLARE @cldLocal VARCHAR(10)

	SELECT @cldLocal = valor
	FROM ccSettings WITH (NOLOCK)
	WHERE setting_id = 17	

	SELECT @lon = len(@tel), @mod = ''''

	IF (@lon = 8 AND len(@cldLocal) = 2) OR (@lon = 7 AND len(@cldLocal) = 3)
	BEGIN
		SET @tel = @cldLocal + @tel
		SET @ld = @cldLocal
	END

	SELECT @tel = right(@tel, 10)

	SELECT @lon = len(@tel)

	IF @lon = 10
	BEGIN
		IF @ld IS NULL
		BEGIN
			IF (
					EXISTS (
						SELECT TOP 1 cld
						FROM series NOLOCK
						WHERE cld = left(@tel, 2)
						)
					)
				SELECT @ld = left(@tel, 2)
			ELSE IF (
					EXISTS (
						SELECT TOP 1 cld
						FROM series NOLOCK
						WHERE cld = left(@tel, 3)
						)
					)
				SELECT @ld = left(@tel, 3)
			ELSE
				RETURN ''E_'' + @tel
		END

		SELECT TOP 1 @mod = modalidad
		FROM series NOLOCK
		WHERE cld = @ld AND serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

		IF @mod NOT IN (''FIJO'', ''MPP'', ''CPP'')
		BEGIN
			RETURN ''E_'' + @tel
		END		
		SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @ld = @cldLocal THEN right(@tel, 10 - len(@ld)) ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN CASE WHEN @ld = @cldLocal THEN ''044'' + @tel ELSE ''045'' + @tel END END
		
	END
	ELSE IF @lon > 0
	BEGIN
		SET @tel = ''E_'' + @tel
	END

	RETURN @tel
END'

		EXEC (@Sql)

		SET @process = 'CW-2027 Plan de marcación update setting 195'
		SET @Sql = 
			'ALTER proc [dbo].[ccspOutDialerCsto]
as
set nocount on
declare @modePlian int 
declare @sql as varchar(max), @insert as varchar(max), @sql2 as varchar(max), @query as varchar(max), @country tinyint
set @modePlian=0
declare @RtnValue table (prov_Id int identity(1,1), costoloc decimal(15,3), costoLD decimal(15,3), costoCel decimal(15,3), costoCelLD decimal(15,3), costo01800 decimal(15,3), costoLDUsa decimal(15,3), costoLDInter decimal(15,3))
select @country = valor from ccsettings where setting_id = 104
set @query = ''declare @RtnValue table (provedor_id int ''
set @sql = ''select provedor_id ''
set @insert = ''''
if @country>1 begin
  select @sql = @sql + '', sum(case when tipollamada_id = '' + convert(varchar(3),tipollamada_id) + '' then isnull(minutoUno,100) else 0 end) [''+ descrip +'']'', @insert = @insert + '', [''+ descrip +'']'', @query = @query + '', ['' + descrip +''] decimal(15,3) '' 
  from cstotipollamada where country_id = @country
end
else begin
  select @sql = @sql + '', sum(case when tipollamada_id = '' + convert(varchar(3),tipollamada_id) + '' then isnull(minutoUno,100) else 0 end) [''+ descrip +'']'', @insert = @insert + '', [''+ descrip +'']'', @query = @query + '', ['' + descrip +''] decimal(15,3) '' 
  from cstotipollamada 
  where country_id=@country and ( tipoLlamada_id not in(1,12)  or  (@modePlian=0 and tipoLlamada_id=1) or (@modePlian<>0 and tipoLlamada_id=12) ) 

end
set @sql = '' Insert Into @RtnValue (provedor_id'' + @insert + '') '' + @sql + '' from cstotarifa group by provedor_id ''
set @query = @query + '')''
set @sql2 = '' select dialer_id, Puerto, Extension, Status, Descripcion, d.provedor_id'' + @insert + '' FROM ccoDialers d Left Join @RtnValue c on d.provedor_id = c.provedor_id ORDER BY Puerto''
--print (@query + @sql + @sql2)
exec (@query + @sql + @sql2)'

		EXEC (@Sql)

		SET @process = 'CW-2603 --CREATE SP SaveClicksAdminByCamp'
		SET @Sql = 'create procedure SaveClicksAdminByCamp
 
@User_Id int,
@Camps varchar(1000),
@Clicks varchar(1000)
as
insert into ClicksByAdmin 
select @User_Id,A.Value,B.Value,GETDATE() from dbo.fn_RIASplitDelimited(@Camps,'','') A
inner join dbo.fn_RIASplitDelimited(@clicks,'','') B on A.Id=B.Id
'

		EXEC (@Sql)

		SET @process = 'CW-2605 --CREATE SP ccsp_Multimedia2'
		SET @Sql = 
			'CREATE PROCEDURE [dbo].[ccsp_Multimedia2]
@action int,@inboundId int = null,@userId int =null,@senderId int= null
AS
BEGIN

SET NOCOUNT ON;

if @action = 1 begin --Lista  ACD
	select distinct A.inbound_id as Id,A.chat as Mode
	,C.maxMails MaxMails,cast(isnull(C.maxTweets,3) as tinyint) as MaxTweets,
	A.IDArea as AreaId
	from ccInbound A
	inner join ccRIACat_Areas C on A.IDArea=C.IDArea	
	where @inboundId is null or @inboundId=A.Inbound_id
	
end
else if @action = 2 begin --Lista Agentes  
	select A.User_id as [Id],C.idCampEsp AcdId,isnull(skill,8) Skill
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and (@userId is null or @userId=A.User_id)
		order by  A.User_id	
end
else if @action=3 begin --List Sender Mail
	select A.contactMeanOutId as Id,ISNULL(R.inboundId,0) as AcdId,A.isActive as IsActive from contactMeanOut A 
	left join relationContactMeanOutInbound R on A.contactMeanOutId=R.contactMeanOutId
	where @senderId is null or @senderId=A.contactMeanOutId
end
END'

		EXEC (@Sql)

		--Create-End
		--Alter-Start
		SET @process = 'CW-1501 Version  120.24'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCLog] @optiON TINYINT, @areaName VARCHAR(50) = NULL, @operationType TINYINT = NULL, @login VARCHAR(20) = NULL, @moduleId INT = NULL, @value VARCHAR(250) = NULL, @target VARCHAR(250) = NULL, @operationDateIni SMALLDATETIME = NULL, @operationDateFin SMALLDATETIME = NULL, @top INT = 0
AS
SET NOCOUNT ON

IF @option = 1 -- muestra todo
BEGIN
	SELECT log_id, areaName, operationDate, operationType, LOGIN, module_id, value, target
	FROM ccRIALog WITH (NOLOCK)

	RETURN (0)
END

IF @option = 2 -- insert
BEGIN
	DECLARE @areaNameValue AS VARCHAR(50)

	SET @areaNameValue = @areaName

	IF (left(@areaName, 1) = '' ! '')
	BEGIN
		SELECT @areaNameValue = areaName
		FROM dbo.ccRIACat_Areas AS AREAS WITH (NOLOCK)
		WHERE AREAS.IDArea = right(@areaName, len(@areaName) - 1)
	END

	INSERT INTO ccRIALog
	VALUES (@areaNameValue, GETDATE(), @operationType, @login, @moduleId, @value, @target)

	RETURN (0)
END

DECLARE @lang TINYINT

SELECT @lang = valor
FROM ccsettings
WHERE setting_id = 27

IF @option = 3 -- muestra información por filtros (System>Log) // Fechas
BEGIN
	SET ROWCOUNT @top

	SELECT L.log_id, L.areaName, L.operationDate, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion) + 1, len(o.descripcion)) END operationType, L.LOGIN, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion) + 1, len(m.descripcion)) END module_id, CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE @lang WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target, CASE WHEN v.valueT IS NULL THEN L.value ELSE CASE @lang WHEN 0 THEN v.es WHEN 2 THEN v.pt ELSE v.en END END AS value
	FROM CCRIALOG L
	JOIN ccRIALog_Module M WITH (INDEX (IX_ccRIALog_Module)) ON L.module_id = M.module_id
	JOIN ccRIALog_Operation O WITH (INDEX (IX_ccRIALog_Operation)) ON L.operationType = O.operationType
	LEFT JOIN targetRecord t ON t.targetT = L.target
	LEFT JOIN valueRecord v ON v.valueT = L.value
	WHERE L.operationType = CASE isnull(@operationType, 0) WHEN 0 THEN L.operationType ELSE @operationType END AND L.LOGIN = CASE isnull(@login, '''') WHEN '''' THEN L.LOGIN ELSE @login END AND L.module_id = CASE isnull(@moduleId, 0) WHEN 0 THEN L.module_id ELSE @moduleId END AND L.target = CASE isnull(@target, '''') WHEN '''' THEN L.target ELSE @target END AND L.operationDate >= CASE WHEN isnull(@operationDateIni, '' 19000101 '') <> '' 19000101 '' AND isnull(@operationDateFin, '' 19000101 '') <> '' 19000101 '' THEN dateadd(minute, - 1, @operationDateIni) ELSE L.operationDate END AND L.operationDate <= CASE WHEN isnull(@operationDateIni, '' 19000101 '') <> '' 19000101 '' AND isnull(@operationDateFin, '' 19000101 '') <> '' 19000101 '' THEN dateadd(minute, 1, @operationDateFin) ELSE L.operationDate END
	ORDER BY L.operationDate DESC

	RETURN (0)
END

IF @option = 4 -- Catalogo de modulos
BEGIN
	SELECT m.module_id, o.operationType, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion) + 1, len(m.descripcion)) END AS mDescripcion, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion) + 1, len(o.descripcion)) END AS oDescripcion
	FROM ccRIALog_Operation o WITH (INDEX (IX_ccRIALog_Operation))
	JOIN ccRIALog_Cat_Relation r ON o.operationType = r.operationType
	JOIN ccRIALog_Module m WITH (INDEX (IX_ccRIALog_Module)) ON r.module_id = m.module_id
	
	UNION
	
	SELECT 0, - 1, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, '' - ''
	
	UNION
	
	SELECT 0, 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
	
	UNION
	
	SELECT module_id, 0, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
	FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))
	
	UNION
	
	SELECT module_id, - 1, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, '' - ''
	FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))
	ORDER BY mDescripcion, oDescripcion

	RETURN (0)
END

IF @option = 5 -- Catalogo de operaciones
BEGIN
	SELECT operationType, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion
	FROM ccRIALog_Operation WITH (INDEX (IX_ccRIALog_Operation))
	
	UNION
	
	SELECT 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
	ORDER BY 2

	RETURN (0)
END

SET NOCOUNT OFF
'

		EXEC (@Sql)

		--Alter-End
		--Select-Start
		--Select-End
		--Update-Start
		SET @process = 'CW-2031 --se cambia el nombre de la etiqueta del menu y se cambia la encriptacion'
		SET @Sql = 'update [dbo].[ccMenus] set menu_descrip = ''Historial de carga|Export Log'', release = ''b14dfaa33570212ebf08ddc649b950b52262aa5dcab6451991e6927bbd77d325'' where menu_id = 26 '

		EXEC (@Sql)

		--Update-End
		--Delete-Start
		--Delete-End
		--Insert-Start
		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from targetRecord where targetT=''ALL'')
    begin
    insert into targetRecord values(''ALL'',''ALL'', ''TODO'',''TUDO'');  
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from targetRecord where targetT=''System'')
    begin
    insert into targetRecord values(''System'',''System'',''Sistema'',''Sistema''); 
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from targetRecord where targetT=''All Users'')
    begin
    insert into targetRecord values(''All Users'',''All users'',''Todos los usuarios'',''Todos os usuários'');  
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from targetRecord where targetT=''Database version'')
    begin
    insert into targetRecord values(''Database version'',''Database version'',''Versión de base de datos'',''Versão do banco de dados'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''RESTRICT LOCAL CALLS (OFF)'')
  begin
    insert into valueRecord values(''RESTRICT LOCAL CALLS (OFF)'',  ''RESTRINGIR LLAMADAS LOCALES (DESACTIVADO)'',  ''RESTRICT LOCAL CALLS (DISABLED)'',  ''RESTRINGIR AS CHAMADAS LOCAIS (DESATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''RESTRICT LD CALLS (OFF)'')
  begin
    insert into valueRecord values(''RESTRICT LD CALLS (OFF)'', ''RESTRINGIR LLAMADAS DE LD (DESACTIVADO)'',  ''RESTRICT LD CALLS (DISABLED)'', ''RESTRINGIR AS CHAMADAS INTERURBANAS (DESATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''RESTRICT CEL CALLS (OFF)'')
  begin
    insert into valueRecord values(''RESTRICT CEL CALLS (OFF)'',  ''RESTRINGIR LLAMADAS A CELULAR (DESACTIVADO)'',  ''RESTRICT CELL PHONE CALLS (DISABLED)'', ''RESTRINGIR AS CHAMADAS AO CELULAR (DESATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''RESTRICT CEL CALLS (ON)'')
  begin
    insert into valueRecord values(''RESTRICT CEL CALLS (ON)'', ''RESTRINGIR LLAMADAS A CELULAR (ACTIVADO)'', ''RESTRICT CELL PHONE CALLS (ENABLED)'',  ''RESTRINGIR AS CHAMADAS AO CELULAR (ATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''RESTRICT LD CALLS (ON)'')
  begin
    insert into valueRecord values(''RESTRICT LD CALLS (ON)'',  ''RESTRINGIR LLAMADAS DE LD (ACTIVADO)'', ''RESTRICT LD CALLS (ENABLED)'',  ''RESTRINGIR AS CHAMADAS INTERURBANAS (ATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''RESTRICT LOCAL CALLS (ON)'')
  begin
    insert into valueRecord values(''RESTRICT LOCAL CALLS (ON)'', ''RESTRINGIR LLAMADAS LOCALES (ACTIVADO)'', ''RESTRICT LOCAL CALLS (ENABLED)'', ''RESTRINGIR AS CHAMADAS LOCAIS (ATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''XFERMASK (OFF)'')
  begin
    insert into valueRecord values(''XFERMASK (OFF)'',  ''RECIBIR TRANSFERENCIAS (DESACTIVADO)'', ''RECEIVE TRANSFERS (DISABLED)'', ''RECEBER TRANSFERÊNCIAS (DESATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''XFERMASK (ON)'')
  begin 
    insert into valueRecord values(''XFERMASK (ON)'', ''RECIBIR TRANSFERENCIAS (ACTIVADO)'',  ''RECEIVE TRANSFERS (ENABLED)'',  ''RECEBER TRANSFERÊNCIAS (ATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''AGT TRANSF. (OFF)'')
  begin
    insert into valueRecord values(''AGT TRANSF. (OFF)'', ''TRANSFERIR A AGENTES (DESACTIVADO)'', ''TRANSFER TO AGENTS (DISABLED)'',  ''TRANSFERIR AS CHAMADAS PARA OS AGENTES (DESATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''ACD TRANSF. (OFF)'')
  begin
    insert into valueRecord values(''ACD TRANSF. (OFF)'', ''TRANSFERIR A GRUPOS ACD (DESACTIVADO)'',  ''TRANSFER TO ACD GROUPS (DISABLED)'',  ''TRANSFERIR AS CHAMADAS PARA OS GRUPOS ACD (DESATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''EXT TRANSF. (OFF)'')
  begin
    insert into valueRecord values(''EXT TRANSF. (OFF)'', ''TRANSFERIR A NÚMEROS EXTERNOS (DESACTIVADO)'',  ''TRANSFER TO EXTERNAL NUMBERS (DISABLED)'',  ''TRANSFERIR AS CHAMADAS PARA NÚMEROS EXTERNOS (DESATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''MAN TRANSF. (OFF)'')
  begin
    insert into valueRecord values(''MAN TRANSF. (OFF)'', ''TRANSFERIR A NÚMEROS MANUALES (DESACTIVADO)'',  ''TRANSFER TO MANUAL NUMBERS (DISABLED)'',  ''TRANSFERIR AS CHAMADAS PARA NÚMEROS MANUAIS (DESATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''MAN TRANSF. (ON)'')
  begin
    insert into valueRecord values(''MAN TRANSF. (ON)'',  ''TRANSFERIR A NÚMEROS MANUALES (ACTIVADO)'', ''TRANSFER TO MANUAL NUMBERS (ENABLED)'', ''TRANSFERIR AS CHAMADAS PARA NÚMEROS MANUAIS (ATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''EXT TRANSF. (ON)'')
  begin
    insert into valueRecord values(''EXT TRANSF. (ON)'',  ''TRANSFERIR A NÚMEROS EXTERNOS (ACTIVADO)'', ''TRANSFER TO EXTERNAL NUMBERS (ENABLED)'', ''TRANSFERIR AS CHAMADAS PARA NÚMEROS EXTERNOS (ATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''ACD TRANSF. (ON)'')
  begin
    insert into valueRecord values(''ACD TRANSF. (ON)'',  ''TRANSFERIR A GRUPOS ACD (ACTIVADO)'', ''TRANSFER TO ACD GROUPS (ENABLED)'', ''TRANSFERIR AS CHAMADAS PARA OS GRUPOS ACD (ATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''AGT TRANSF. (ON)'')
  begin
    insert into valueRecord values(''AGT TRANSF. (ON)'',  ''TRANSFERIR A AGENTES (ACTIVADO)'',  ''TRANSFER TO AGENTS (ENABLED)'', ''TRANSFERIR AS CHAMADAS PARA OS AGENTES (ATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''Pause and resume recording(OFF)'')
  begin 
    insert into valueRecord values(''Pause and resume recording(OFF)'', ''PAUSAR Y CONTINUAR GRABACIÓN (DESACTIVADO)'', ''PAUSE AND RESUME RECORDING (DISABLED)'',''PAUSAR E RETOMAR A GRAVAÇÃO (DESATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-1501 Version 120.24'
		SET @Sql = 'if not exists (select * from valueRecord where valueT=''Pause and resume recording(ON)'')
  begin
    insert into valueRecord values(''Pause and resume recording(ON)'',  ''PAUSAR Y CONTINUAR GRABACIÓN (ACTIVADO)'',  ''PAUSE AND RESUME RECORDING (ENABLED)'', ''PAUSAR E RETOMAR A GRAVAÇÃO (ATIVADO)'');
  end'

		EXEC (@Sql)

		SET @process = 'CW-2018 CallBack Reminder insert ccStatusLLamada 18'
		SET @Sql = '
    if not exists ( select * from ccStatusLLamada where statusCall_id = 18)
    begin
    insert into ccStatusLLamada(statusCall_id,descripcion,inAbandonConfig) values(18,''Colgada en dialogo (Reminder)'',1)---esto es por lo configurado en el setting_id 13
    end
      '

		EXEC (@Sql)

		SET @process = 'CW-2152 Alter FN fn_RIASplitDelimited'
		SET @Sql = 'ALTER FUNCTION [dbo].[fn_RIASplitDelimited]
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

		EXEC (@Sql)

		SET @process = 'CW-2027 Plan de marcación ALTER function Completa'
		SET @Sql = 
			'ALTER function [dbo].[Completa](@Cadena varchar(32), @pais varchar(2) = '''', @ld varchar(5) = '''')
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

		EXEC (@Sql)

		SET @process = 'CW-2027 Plan de marcación alter function verifica2'
		SET @Sql = 
			'ALTER FUNCTION [dbo].[Verifica2] (@tel VARCHAR(32), @pais TINYINT = 0, @cldLocal VARCHAR(7) = '''')
RETURNS VARCHAR(32)
AS
BEGIN
	DECLARE @ld VARCHAR(7)
	DECLARE @lon TINYINT
	DECLARE @result TINYINT
	DECLARE @mod VARCHAR(10)
	DECLARE @Cadena VARCHAR(32)

	IF (@pais = 0 AND @cldLocal = '''')
	BEGIN
		SELECT @pais = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 104

		SELECT @cldLocal = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 17
	END

	SELECT @tel = dbo.limpia(@tel)

	IF @pais = 1
	BEGIN --Empieza Mexico
		SELECT @lon = len(@tel), @mod = ''''

		IF (@lon = 8 AND len(@cldLocal) = 2) OR (@lon = 7 AND len(@cldLocal) = 3)
		BEGIN
			SET @tel = @cldLocal + @tel
			SET @ld = @cldLocal
		END

		SELECT @tel = right(@tel, 10)

		SELECT @lon = len(@tel)

		IF @lon = 10
		BEGIN
			IF @ld IS NULL
			BEGIN
				IF (
						EXISTS (
							SELECT TOP 1 cld
							FROM series NOLOCK
							WHERE cld = left(@tel, 2)
							)
						)
					SELECT @ld = left(@tel, 2)
				ELSE IF (
						EXISTS (
							SELECT TOP 1 cld
							FROM series NOLOCK
							WHERE cld = left(@tel, 3)
							)
						)
					SELECT @ld = left(@tel, 3)
				ELSE
					RETURN ''E_'' + @tel
			END

			SELECT TOP 1 @mod = modalidad
			FROM series NOLOCK
			WHERE cld = @ld AND serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

			IF @mod NOT IN (''FIJO'', ''MPP'', ''CPP'')
			BEGIN
				RETURN ''E_'' + @tel
			END

			DECLARE @specialDialPlan TINYINT

			SELECT @specialDialPlan = valor
			FROM ccsettings WITH (NOLOCK)
			WHERE setting_id = 195

			IF @specialDialPlan = 2
			BEGIN --Number 10 digits
				RETURN @tel
			END

			IF @specialDialPlan = 1
			BEGIN
				--Number local 10 digit
				--Number LD 12 digit
				--Number Cell 13 digit
				SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @ld = @cldLocal THEN @tel ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN CASE WHEN @ld = @cldLocal THEN ''044'' + @tel ELSE ''045'' + @tel END END
			END
			ELSE
			BEGIN
				--Number local 7 o 8 digit
				--Number LD 12 digit
				--Number Cell 13 digit
				SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @ld = @cldLocal THEN right(@tel, 10 - len(@ld)) ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN CASE WHEN @ld = @cldLocal THEN ''044'' + @tel ELSE ''045'' + @tel END END
			END
		END
		ELSE IF @lon > 0
		BEGIN
			SET @tel = ''E_'' + @tel
		END

		RETURN @tel
	END --Termina Mexico
			--------------------------- Empieza Argentina ---------------------------
	ELSE IF @pais = 2
	BEGIN
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = ''E''
		BEGIN
			RETURN @tel
		END

		SELECT @lon = len(@tel)

		IF @lon IN (6, 7, 8) AND left(@tel, 2) <> ''15''
		BEGIN
			SET @tel = @cldLocal + @tel
		END

		IF @lon IN (8, 9, 10) AND left(@tel, 2) = ''15''
		BEGIN
			SET @tel = @cldLocal + substring(@tel, 3, @lon - 2)
		END

		--Buscamos el 15
		IF @lon = 13
		BEGIN
			DECLARE @index AS INT

			SELECT @index = charindex(''15'', @tel)

			--El unico caso en el que la lada tiene un 15 es con lada 3715
			IF @index < 2
			BEGIN
				SELECT @tel = ''E_'' + @tel

				RETURN @tel
			END
			ELSE
			BEGIN
				IF substring(@tel, @index - 2, 4) = ''3715''
				BEGIN
					SELECT @ld = ''3715''

					SET @tel = @ld + right(@tel, 6)
				END
				ELSE
				BEGIN
					SELECT @ld = substring(@tel, 2, @index - 2)

					SET @tel = @ld + right(@tel, 13 - (@index + 1))
				END
			END
		END

		SELECT @tel = right(@tel, 10)

		IF len(@tel) = 10
		BEGIN
			DECLARE @serie AS VARCHAR(5)

			BEGIN
				-- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
				DECLARE @contLD AS INT
				DECLARE @cont AS INT

				SET @contLD = 4

				BuscaLada:

				IF isnull(@ld, '''') = '''' AND @contLD >= 2
				BEGIN
					SELECT @ld = cld
					FROM seriesArg
					WHERE cld = left(@tel, @contLD)

					IF isnull(@ld, '''') = ''''
					BEGIN
						SET @contLD = @contLD - 1

						GOTO BuscaLada
					END
				END
				ELSE
				BEGIN
					IF isnull(@ld, '''') = ''''
					BEGIN
						SELECT @tel = ''E_'' + @tel
					END
				END
			END

			-- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
			BEGIN
				IF len(@ld) = 2
				BEGIN
					SET @cont = 5

					buscaSerie2:

					IF isnull(@serie, '''') = '''' AND @cont >= 4
					BEGIN
						SELECT @serie = serie
						FROM seriesArg
						WHERE cld = @ld AND serie = substring(@tel, 3, @cont)

						IF isnull(@serie, '''') = ''''
						BEGIN
							SET @cont = @cont - 1

							GOTO buscaSerie2
						END
					END
				END
				ELSE
				BEGIN
					IF len(@ld) = 3
					BEGIN
						SET @cont = 4

						buscaSerie3:

						IF isnull(@serie, '''') = '''' AND @cont >= 3
						BEGIN
							SELECT @serie = serie
							FROM seriesArg
							WHERE cld = @ld AND serie = substring(@tel, 4, @cont)

							IF isnull(@serie, '''') = ''''
							BEGIN
								SET @cont = @cont - 1

								GOTO buscaSerie3
							END
						END
					END
					ELSE
					BEGIN
						IF len(@ld) = 4
						BEGIN
							SET @cont = 3

							buscaSerie4:

							IF isnull(@serie, '''') = '''' AND @cont >= 2
							BEGIN
								SELECT @serie = serie
								FROM seriesArg
								WHERE cld = @ld AND serie = substring(@tel, 5, @cont)

								IF isnull(@serie, '''') = ''''
								BEGIN
									SET @cont = @cont - 1

									GOTO buscaSerie4
								END
							END
						END
					END
				END
			END

			SELECT @mod = modalidad
			FROM seriesArg
			WHERE cld = @ld AND serie = @serie AND right(@tel, 10 - len(@ld) - len(@serie)) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

			-- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie
			--select @ld,@serie,@mod,@contLD
			IF isNull(@serie, '''') = '''' AND @contLD > 1
			BEGIN
				SET @contLD = len(@ld) - 1
				SET @ld = NULL

				GOTO BuscaLada
			END

			SELECT @tel = CASE WHEN @mod IN (''BASICA'', ''MPP'') THEN CASE WHEN @ld = @cldLocal THEN right(@tel, 10 - len(@ld)) ELSE ''0'' + @tel END WHEN @mod = ''CPP'' THEN CASE WHEN @ld = @cldLocal THEN ''15'' + right(@tel, 10 - len(@ld)) ELSE ''0'' + @ld + ''15'' + right(@tel, 10 - len(@ld)) END ELSE ''E_'' + @tel END
		END
		ELSE
		BEGIN
			IF len(@tel) > 0
			BEGIN
				SELECT @tel = ''E_'' + @tel
			END
		END

		RETURN @tel
	END ------------------ Termina Argentina ------------------
	ELSE IF @pais = 3
	BEGIN --Empieza Colombia
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = ''E''
		BEGIN
			RETURN @tel
		END

		IF len(@tel) NOT IN (7, 8, 10, 11)
		BEGIN
			RETURN ''E_'' + @tel
		END

		IF len(@tel) = 7
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesCol
					WHERE serie = left(@tel, 4) AND @cldLocal = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END

		IF len(@tel) = 8
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesCol
					WHERE serie = substring(@tel, 2, 4) AND left(@tel, 1) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END

		IF len(@tel) = 10
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesCol
					WHERE serie = substring(@tel, 5, 3) AND (left(@tel, 3) + ''-'' + substring(@tel, 4, 1)) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END

		IF len(@tel) = 11
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesCol
					WHERE serie = substring(@tel, 6, 3) AND (substring(@tel, 2, 3) + ''-'' + substring(@tel, 5, 1)) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END
	END --Termina Colombia

	-- Empieza Chile
	IF @pais = 5
	BEGIN
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = ''E''
		BEGIN
			RETURN @tel
		END

		IF len(@tel) = 6 AND len(@cldLocal) = 2
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesChi
					WHERE cld = @cldLocal AND left(@tel, 3) = serie AND right(@tel, 3) BETWEEN numeracioninicial AND numeracionFinal
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END

		IF len(@tel) = 7
		BEGIN
			IF @cldLocal IN (2, 41, 44, 32)
			BEGIN
				IF EXISTS (
						SELECT serie
						FROM serieschi
						WHERE serie = left(@tel, 4)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					IF left(@tel, 3) = ''200'' AND EXISTS (
							SELECT serie
							FROM serieschi
							WHERE serie = left(@tel, 3)
							)
					BEGIN
						RETURN @tel
					END
				END
			END
		END

		IF len(@tel) = 8
		BEGIN
			IF left(@tel, 1) = ''2''
			BEGIN
				IF EXISTS (
						SELECT serie
						FROM serieschi
						WHERE serie = substring(@tel, 2, 4)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM serieschi
							WHERE serie = substring(@tel, 2, 5)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END
			END
			ELSE
			BEGIN
				RETURN @tel
			END
		END

		IF len(@tel) = 10
		BEGIN
			IF left(@tel, 2) = ''09''
			BEGIN
				IF EXISTS (
						SELECT serie
						FROM serieschi
						WHERE cld = substring(@tel, 3, 1) AND serie = substring(@tel, 5, 3)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					RETURN ''E_'' + @tel
				END
			END
		END
	END

	--Termina Chile
	IF @pais = 6
	BEGIN --Empieza Venezuela
		SELECT @lon = len(@tel)

		IF @lon = 7
		BEGIN
			SET @tel = @cldLocal + @tel
		END

		SELECT @tel = right(@tel, 10)

		IF len(@tel) = 10
		BEGIN
			SELECT @ld = left(@tel, 3)

			SELECT @mod = tipo
			FROM seriesVen
			WHERE left(@tel, 3) = LD

			IF @mod = ''CPP''
			BEGIN
				IF EXISTS (
						SELECT *
						FROM seriesVen
						WHERE LD = @ld
						)
				BEGIN
					IF @ld = @cldLocal
					BEGIN
						SELECT @tel = right(@tel, 7)
					END
					ELSE
					BEGIN
						SELECT @tel = ''0'' + @tel
					END
				END
				ELSE
				BEGIN
					SELECT @tel = ''E_'' + @tel
				END
			END
			ELSE
			BEGIN
				IF @mod = ''FIJO''
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesVen
							WHERE serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) AND right(@tel, 4) BETWEEN [Inicio] AND [Fin]
							)
					BEGIN
						IF @ld = @cldLocal
						BEGIN
							SELECT @tel = right(@tel, 7)
						END
						ELSE
						BEGIN
							SELECT @tel = ''0'' + @tel
						END
					END
					ELSE
					BEGIN
						SELECT @tel = ''E_'' + @tel
					END
				END
				ELSE
				BEGIN
					SELECT @tel = ''E_'' + @tel
				END
			END
		END
		ELSE
		BEGIN
			IF len(@tel) > 0
			BEGIN
				SELECT @tel = ''E_'' + @tel
			END
		END

		RETURN @tel
	END --Termina Venezuela

	IF @pais = 7
	BEGIN -- Empieza UK
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = ''E''
		BEGIN -- regresa error por longitud
			RETURN @tel
		END

		SELECT @lon = len(@tel)

		--numeros no geograficos
		IF (left(@tel, 2) IN (''03'', ''07'', ''09'') AND @lon <> 11) OR (left(@tel, 3) IN (''055'', ''056'', ''070'') AND @lon <> 11)
		BEGIN
			RETURN ''E_'' + @tel --error por longitud con lada correcta
		END
		ELSE
		BEGIN
			IF left(@tel, 7) IN (''0845464'') OR left(@tel, 5) = ''07624'' OR left(@tel, 4) IN (''0500'', ''0800'') OR left(@tel, 3) IN (''055'', ''056'', ''070'', ''76'') OR left(@tel, 2) IN (''03'', ''07'', ''08'', ''09'')
			BEGIN
				RETURN @tel;--longitud correcta y numero no geografico
			END
		END

		--numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
		IF (left(@tel, 7) IN (''0159575'', ''0159576'')) OR (left(@tel, 5) IN (''02820'', ''02821'', ''02825'', ''02827'', ''02828'', ''02829'', ''02830'', ''02837'', ''02838'', ''02840'', ''02841'', ''02842'', ''02843'', ''02844'', ''02866'', ''02867'', ''02868'', ''02870'', ''02871'', ''02877'', ''02879'', ''02880'', ''02881'', ''02882'', ''02885'', ''02886'', ''02887'', ''02889'', ''02890'', ''02891'', ''02892'', ''02893'', ''02894'', ''02895'', ''02897'') AND @lon = 11) OR --claves 2xxx tienen formato 4-6
			(left(@tel, 4) IN (''0113'', ''0114'', ''0115'', ''0116'', ''0117'', ''0118'', ''0121'', ''0131'', ''0141'', ''0151'', ''0161'', ''0238'', ''0239'') AND @lon = 11) OR --3-digit area codes have 7-digit subscribers.
			(left(@tel, 3) IN (''020'', ''024'', ''029'') AND @lon = 11)
		BEGIN --2-digit area codes have 8-digit subscribers.
			RETURN @tel;
		END

		--numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
		IF left(@tel, 2) = ''01''
		BEGIN
			SELECT @ld = count(cld)
			FROM seriesuk
			WHERE cld = substring(@tel, 2, 4) --mayor numero de ladas (va primero por ser mas probable)

			IF @ld > 0
			BEGIN
				RETURN @tel;
			END
			ELSE
			BEGIN
				SELECT @ld = count(cld)
				FROM seriesuk
				WHERE cld = substring(@tel, 2, 5) --ladas restantes

				IF @ld > 0
				BEGIN
					RETURN @tel;
				END
			END
		END --si no encontro ni error ni coincidencia entonces esta mal

		RETURN ''E_'' + @tel
	END --Termina UK

	IF @pais = 8
	BEGIN --Empieza Arabia Saudita
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		SELECT @lon = len(@tel)

		IF @lon = 7
		BEGIN
			SET @tel = ''0'' + @cldLocal + @tel
		END

		SELECT @lon = len(@tel)

		IF @lon = 9
		BEGIN
			IF EXISTS (
					SELECT regiones
					FROM seriesSA
					WHERE right(@tel, 4) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 3, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 4 AND left(@tel, 2) = cld
					)
			BEGIN
				IF (substring(@tel, 2, 1) = @cldLocal)
				BEGIN
					RETURN right(@tel, 7)
				END
				ELSE
				BEGIN
					RETURN @tel
				END
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END

		IF @lon = 10
		BEGIN
			IF EXISTS (
					SELECT regiones
					FROM seriesSA
					WHERE right(@tel, 4) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 4, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 4 AND left(@tel, 3) = cld
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END

		IF @lon = 11
		BEGIN
			IF EXISTS (
					SELECT regiones, *
					FROM seriesSA
					WHERE right(@tel, 6) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 3, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 6 AND left(@tel, 2) = cld
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END
	END --Termina Arabia Saudita

	IF @pais = 9
	BEGIN --Empieza Australia
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		SELECT @lon = len(@tel)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF EXISTS (
					SELECT Regiones
					FROM SeriesAU
					WHERE convert(INT, LD) = convert(INT, substring(@tel, 1, 2)) AND convert(INT, AreaCode) = convert(INT, substring(@tel, 3, 2)) AND convert(INT, substring(@tel, 5, 6)) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END
		ELSE
		BEGIN
			RETURN @tel
		END
	END --Termina Australia

	IF @pais = 10
	BEGIN -- Inicia Brasil
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		SELECT @lon = len(@tel)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF @lon IN (8, 9)
			BEGIN --numero local
				IF EXISTS (
						SELECT Regiones
						FROM seriesBR
						WHERE convert(INT, AreaCode) = convert(INT, @cldLocal) AND convert(INT, @tel) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					RETURN ''E_'' + @tel
				END
			END

			IF @lon IN (10, 11)
			BEGIN --numero nacional
				IF EXISTS (
						SELECT Regiones
						FROM seriesBR
						WHERE convert(INT, AreaCode) = convert(INT, left(@tel, 2)) AND convert(INT, right(@tel, @lon - 2)) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					RETURN ''E_'' + @tel
				END
			END
		END
		ELSE
		BEGIN
			RETURN @tel
		END
	END -- Termina Brasil

	IF @pais = 11
	BEGIN -- Inicia Guatemala
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF EXISTS (
					SELECT zonaGeografica
					FROM seriesGT(NOLOCK)
					WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
					)
				RETURN @tel
			ELSE
				RETURN ''E_'' + @tel
		END
		ELSE
			RETURN @tel
	END -- Termina Guatemala

	IF @pais = 12
	BEGIN -- Inicia Costa Rica
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF len(@tel) = 8
				IF EXISTS (
						SELECT zonaGeografica
						FROM seriesCR(NOLOCK)
						WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
						)
					RETURN @tel
				ELSE
					RETURN ''E_'' + @tel
			ELSE IF len(@tel) = 10
			BEGIN
				IF EXISTS (
						SELECT zonaGeografica
						FROM seriesCR(NOLOCK)
						WHERE indicativoDestino = substring(@tel, 1, 3) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
						)
					RETURN @tel
				ELSE
					RETURN ''E_'' + @tel
			END
			ELSE IF charindex(substring(@tel, 1, 2), ''00,08'') <= 0
				RETURN ''E_'' + @tel
			ELSE
				RETURN @tel
		END
	END -- Termina Costa Rica

	IF @pais = 13
	BEGIN -- Inicia Salvador
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF len(@tel) = 8
				IF EXISTS (
						SELECT zonaGeografica
						FROM seriesSV(NOLOCK)
						WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
						)
					RETURN @tel
				ELSE
					RETURN ''E_'' + @tel
			ELSE IF charindex(substring(@tel, 1, 2), ''00'') <= 0
				RETURN ''E_'' + @tel
			ELSE
				RETURN @tel
		END
	END -- Termina Salvador

	IF @pais = 14
	BEGIN -- Inicia Spain
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF len(@tel) = 9
				IF EXISTS (
						SELECT provincia
						FROM seriesEsp(NOLOCK)
						WHERE indicativo = substring(@tel, 1, 1) AND right(@tel, 8) BETWEEN numInicial AND numFinal
						)
					RETURN @tel
				ELSE
					RETURN ''E_'' + @tel
			ELSE IF charindex(substring(@tel, 1, 2), ''00'') <= 0
				RETURN ''E_'' + @tel
			ELSE
				RETURN @tel
		END
	END -- Termina Espa?a

	IF @pais = 15
	BEGIN --Inicia Peru
		SELECT @tel = dbo.Completa(@tel, @pais, @cldLocal)

		SELECT @lon = len(@tel)

		IF @lon BETWEEN 6 AND 7
		BEGIN
			SET @tel = @cldLocal + @tel
		END

		SELECT @tel = right(@tel, 9)

		SELECT @lon = len(@tel)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF @lon = 9
			BEGIN
				IF EXISTS (
						SELECT zonaGeografica
						FROM seriesPE(NOLOCK)
						WHERE left(@tel, 1) = 9 OR substring(@tel, 2, 1) = 1 AND areaNumeracion = 1 AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal OR substring(@tel, 2, 1) <> 1 AND left(@tel, 2) = areaNumeracion AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
						)
					RETURN @tel
				ELSE
					RETURN ''E_'' + @tel
			END
		END
	END --Termina Peru

	IF @pais = 16
	BEGIN --Panama
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF len(@tel) = 7
			BEGIN -- Local
				IF (substring(@tel, 1, 1) != ''6'')
				BEGIN
					IF EXISTS (
							SELECT zonaGeografica
							FROM seriesPa(NOLOCK)
							WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
							)
						RETURN @tel
					ELSE
						RETURN ''E_'' + @tel
				END
				ELSE
					RETURN ''E_'' + @tel
			END

			IF len(@tel) = 8
			BEGIN --Celular
				IF (substring(@tel, 1, 1) = ''6'')
				BEGIN
					IF EXISTS (
							SELECT zonaGeografica
							FROM seriesPa(NOLOCK)
							WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
							)
						RETURN @tel
					ELSE
						RETURN ''E_'' + @tel
				END
				ELSE
					RETURN ''E_'' + @tel
			END
			ELSE
			BEGIN
				IF charindex(substring(@tel, 1, 2), ''00'') <= 0
					RETURN ''E_'' + @tel
				ELSE
					RETURN @tel
			END
		END
	END

	RETURN @tel
END'

		EXEC (@Sql)

		SET @process = 'CW-2220 Funcion Verifica CallBack alter SP ccsp_RIAAbandon_Config'
		SET @Sql = 
			'
        ALTER procedure [dbo].[ccsp_RIAAbandon_Config]
@Type smallint, -- 1:Muestra ACD | 2:Muestra Tiempos y Status (ACD) | 3:Actualiza Configuracion
@User_id smallint,
@Inbound_id smallint=null,
@minCallBackAbandon varchar(10)=null,
@minCallBackAbandonXpire varchar(10)=null,
@statuscall_id_Array varchar(1000)=null,
@telFormato TinyInt= null

as
set nocount on
declare @IDarea smallint
select @IDarea=IDarea from ccUsers where user_id=@user_id

if isnull(@IDarea,'''')=''''
 begin
  select -1, ''invalid user area''
  return(0)
 end

if @Type=1
 begin
  select distinct I.inbound_id, I.descripcion, A.frame, C.cam_procesando
  from ccinbound I join ccRIAinboundGraph G on I.inbound_id = G.inbound_id
  join ccRIAGraphics A on G.graphic_id = A.graphic_id
  join ccCamps C on I.cam_id=C.cam_id
  where A.type_id = 1 and I.cam_id is not null and I.IDArea=@IDarea
  order by descripcion
  return(0)
 end

if not exists(select inbound_id from ccInbound where cam_id is not null and inbound_id=@inbound_id and IDArea=@IDArea)
 begin
  select -2, ''invalid inbound_id''
  return(0)
 end

if @Type=2
 begin
  select @statuscall_id_Array = statuscall_id_Array from ccInbound where inbound_Id=@inbound_Id
  select 0 [type], (minCallBackAbandon/60) setHrs, (minCallBackAbandon-((minCallBackAbandon/60)*60)) setMin, 
  (minCallBackAbandonXpire/60) expHrs, (minCallBackAbandonXpire-((minCallBackAbandonXpire/60)*60)) expMin, 
  null statusCall_id,null descripcion,null chk
  from ccInbound where inbound_id=@Inbound_id
  union
  select 1, null, null, null, null, SL.statusCall_id, SL.descripcion, cast(cast(isnull(F.value,0) as bit)as tinyint) chk
  from ccStatusLLamada SL left join dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','') 
  F on SL.statusCall_id = F.value where SL.inAbandonConfig=1 
  order by [type], descripcion
  return(0)
 end

if @Type=3
 begin
  update ccInbound set 
   minCallBackAbandon=case when @minCallBackAbandon is null then minCallBackAbandon else @minCallBackAbandon end,
   minCallBackAbandonXpire=case when @minCallBackAbandonXpire is null then minCallBackAbandonXpire else @minCallBackAbandonXpire end,
   statuscall_id_Array=case when @statuscall_id_Array is null then statuscall_id_Array else @statuscall_id_Array end,
   telFormato = case when @telFormato is null then telFormato else @telFormato end   
   where inbound_id=@Inbound_id
  return(0)
 end

set nocount off    
    '

		EXEC (@Sql)

		SET @process = 'CW-2220 Funcion Verifica CallBack alter SP ccsp_RIAUpdateCallBack_Abandon'
		SET @Sql = 
			'
    ALTER procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]
@cal_id int,
@nStatus tinyint
as
set nocount on
declare @ANI varchar(13), @cam_id int, @inbound_id int, @fechadial varchar(40), @callout_id int, 
 @statuscall_id_Array varchar(1000), @minCallBackAbandon smallint, @pais varchar(2), @ld varchar(5), @telFormat tinyint

declare @lenExt int

select @ANI=C.cal_ANI, @cam_id=I.cam_id, @inbound_id=I.inbound_id, 
@statuscall_id_Array=statuscall_id_Array, @minCallBackAbandon=minCallBackAbandon,@telFormat = I.telFormato
from cccallsin C join ccInbound I on I.Inbound_id=C.Inbound_id where cal_id=@cal_id

select @fechadial=convert(varchar(16), dateadd(minute, @minCallBackAbandon, getdate()), 121)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @lenExt = case when valor=''''then 0 else valor end from ccSettings with(nolock) where setting_id = 108
if @nStatus not in (select value from dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','')) or isnull(@cal_id,0)=0
 return(0)
 
if isnull(@cam_id, 0)=0
  return(0)

  
--set @ANI =dbo.Limpia(@ANI)
--if @lenExt<>len(@ANI)
--  select @ANI = dbo.completa(@ANI, @pais, @ld)

  if @telFormat = 0
  set @ANI =dbo.Limpia(@ANI)
  else if @telFormat = 1
  select @ANI = dbo.completa(@ANI, @pais, @ld)

if (select substring(@ANI,1,1))= ''E''
  return(0)

if exists (select cal_ANI from ccRIAUpdateCallBack_Abandon where cal_ANI=@ANI)
  return(0)

 begin try
  insert ccRIAUpdateCallBack_Abandon (cal_id, cal_ANI, cam_id, callout_id, inbound_id, minCallBackAbandon)
  select @cal_id, @ANI, @cam_id, @callout_id, @inbound_id, @fechadial
  declare @dato1 varchar (max),  @dato2 varchar (max), @dato3 varchar (max), @dato4 varchar (max), @dato5 varchar (max)
  set @dato1 = '''' set @dato2 = '''' set @dato3 = '''' set @dato4 = '''' set @dato5 = ''''
  
  declare @datosToAgent varchar(max)
  select @datosToAgent= addDataCallBackReminder from ccInbound where Inbound_id = @inbound_id
  
  if(@datosToAgent = 1)
  begin
    select @dato1 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 1''
    select @dato2 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 2''
    select @dato3 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 3''
    select @dato4 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 4''
    select @dato5 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 5''
  end 
  exec ccsp_INInsertaCallBack @cal_id, @cam_id, @ANI, @fechadial, @dato1,@dato2,@dato3,@dato4,@dato5, 1, 0, 1

  select top 1 @callout_id=callout_id from ccoWorkingTable WITH(INDEX(PK_ccoWorkingTable)) WHERE cal_telefono=@ANI
  select @fechadial=dateadd(minute, minCallBackAbandonXpire, @fechadial) from ccInbound where Inbound_id=@inbound_id
  update ccRIAUpdateCallBack_Abandon set callout_id=@callout_id, minCallBackAbandonXpire=@fechadial where cal_id=@cal_id
  return(0)
 end try

 begin catch
  return(0)
 end catch
set nocount off
      '

		EXEC (@Sql)

		SET @process = 'CW-2576 correccion de reporte de contestadas y transferidas- Alter Table'
		SET @Sql = 'if not exists(select * from sys.columns where [name] = N''tipoLlamada_id'' and Object_ID = Object_ID(N''ccLogTransfers''))
begin
	alter table ccLogTransfers
	add tipoLlamada_id smallint default(0)
end'
		EXEC (@Sql)

		SET @process = 'CW-2576 correccion de reporte de contestadas y transferidas- Alter Table ccologdials'
		SET @Sql = 'if not exists(select * from sys.columns where [name] = N''tipoLlamada_id'' and Object_ID = Object_ID(N''ccologdials''))
		begin
			alter table ccologdials
			add tipoLlamada_id smallint default(0)
		end'
		
		EXEC (@Sql)

		SET @process = 'CW-2576 correccion de reporte de contestadas y transferidas - fnGetTipoLlamada'
		SET @Sql = 
			'ALTER function [dbo].[fnGetTipoLlamada]( @tel
 varchar(32) )
returns int
as
 begin
	declare @len integer, @tipo integer, @country varchar(5)
	declare @tipoLlamada_id smallint
	declare @prefijo varchar(15), @longitud varchar(15)

	declare @table table(
	id int not null,
	prefijo nvarchar(100) not null
	)

	select @country = valor from ccsettings where setting_id = 104	

	if @country=1 begin
		select @tel=dbo.VerificaMex(@tel)
	end


	set @len = len( @tel )
	set @tipo = 0

	declare @prefixTable table(
	tipoLlamada_id smallint not null,
	longitud varchar(15) not null,
	prefijo varchar(15) not null,
	[status] bit not null
	)

	insert into @prefixTable
	select tipoLlamada_id, longitud, prefijo, 0
	from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
	where country_id = @country 
	and (country_id <> 1 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11))) --no incluir tarifas por region (Mexico)
	order by len(prefijo) desc -- para tomar el mas especifico si se devuelven varios patrones

	while (select count(*) from @prefixTable where [status] = 0) > 0
	begin
		select top 1 @tipoLlamada_id = tipoLlamada_id, @longitud = longitud, @prefijo = prefijo
		from @prefixTable 
		where [status] = 0

		insert into @table
		select * from fn_RIASplitDelimited(@prefijo,''|'') order by len(value) desc

		if (select count(*) from fn_RIASplitDelimited(@longitud,''|'') where value=@len) = 1
			begin
				if (select count(*)	from @table	where @tel like prefijo) = 1
					set @tipo = @tipoLlamada_id
			end
		else if @longitud = ''0''
			begin
				if (select count(*)	from @table	where @tel like prefijo) = 1
					set @tipo = @tipoLlamada_id
			end

		if @tipo <> 0
			update @prefixTable
			set [status] = 1
		else
			begin
				update @prefixTable
				set [status] = 1
				where tipoLlamada_id = @tipoLlamada_id

				delete @table
			end
	end

	if @tipo = 0 and len(@tel) = 12 and LEFT(@tel,5) = ''E_800'' begin
		set @tipo = 5
	end

	return @tipo
 end'

		EXEC (@Sql)

		SET @process = 'CW-2576 correccion de reporte de contestadas y transferidas- ccsp_EngineLogTransfers'
		SET @Sql = 
			'ALTER procedure [dbo].[ccsp_EngineLogTransfers]
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
         insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id) 
         values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, getdate(), @pbxId,@channel, dbo.fnGetTipoLlamada(@destino) )
         if @tdespues > 0 begin
                 select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tdespues
                 update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
         end
     end
     else begin
         if not exists (select * from ccLogTransfers where cal_id = @cal_id and tipo = @tipo)
             insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id) 
             values ( @cal_id, @tipo, @modo, @destino, 0, @tantes, getdate() ,@pbxId,@channel, dbo.fnGetTipoLlamada(@destino) )
 
         if @tipo = 2 begin
             if @modo = 5 begin
                 select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
                 update ccLogTransfers set tDespuesXfer = @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2), tAntesXfer = @tdespues + (select tAntesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2) 
                 	,tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) 
                 	where cal_id = @cal_id and tipo = 2
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
         update ccLogTransfers set tDespuesXfer = @tdespues + @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)
         ,tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) 
         	where cal_id = @cal_id and tipo = 2
         select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
         update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
     end
 end

 else if @action = 4 begin
     select @totalCall_Time = ISNULL((select sum(tincall) from IVRCallsIn where callout_id = @cal_id), 0) + ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0)
     update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
end
'

		EXEC (@Sql)

		SET @process = 'CW-2576 correccion de reporte de contestadas y transferidas'
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccsp_CstoCalculaCosto]
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
           and t.tipoLlamada_id = dbo.fnGetTipoLlamada(cal_telefono)
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
       and t.tipoLlamada_id = dbo.fnGetTipoLlamada(cco.cal_telefono)
       and cco.cal_manual <> 1
       and cco.cal_inicio between @from and @to
       and cco.provedor_id is null
       return(0)
   end
  
  select @puerto = cal_puerto, @longitud = len(cal_telefono) , @telefono = cal_telefono 
  from ccoCallsOut with(index(PK_ccoCallsOut), nolock) where cal_id = @idCall
  
  if @puerto = 0
      return(0)
  
  select @tipoLlamada_id = dbo.fnGetTipoLlamada(@telefono)

  select @minutouno = minutouno, @minutoadicional = minutoadicional, @provedor_id = d.provedor_id
  from cstoTarifa t
  inner join ccoDialers d on d.provedor_id = t.provedor_id
  where t.tipollamada_id = @tipoLlamada_id
  and d.puerto = @puerto
  
  update ccoCallsOut with(rowlock) 
  --set costo = @MinutoUno + case when cal_txfer + cal_tring + cal_tDialog > 0 then((ceiling(( cal_txfer + cal_tring + cal_tDialog ) / 60.0 )- 1) * @MinutoAdicional ) else 0 end
  set costo = @MinutoUno + case when ISNULL(totalCall_Time,0) > 0 then((ceiling(( ISNULL(totalCall_Time,0) ) / 60.0 )- 1) * @MinutoAdicional ) else 0 end
  ,provedor_id = case @provedor_id when 0 then provedor_id else @provedor_id end
  ,tipoLlamada_id = case @tipoLlamada_id when 0 then tipoLlamada_id else @tipoLlamada_id end
  where cal_id = @idCall
  
  set nocount off
  '

		EXEC (@sql)

		SET @process = 'CW-2576 correccion de reporte de contestadas y transferidas- Alter SP ccsp_DLRSaveDialResult'
		SET @Sql = 'ALTER procedure [dbo].[ccsp_DLRSaveDialResult]
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
@cal_key varchar(20) = '''',
@call_TS varchar(15) = ''''
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
	INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id)
	select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''00000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(@Telefono)
END
ELSE
BEGIN
	INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS)
	select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''00000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS
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
set nocount off
'
				
		EXEC (@Sql)

		--Insert-End
		SET @process = 'CW-2609 ALTER ccsp_RIA_ABCCamps'
		SET @Sql = 
'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
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

	update ccCamps set keepDial=dbo.fn_keepDial_Camps(@new_cam_id) where cam_id=@new_cam_id

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

		EXEC (@Sql)

		SET @process = 'CW-2018 CallBack Reminder alter  ccsp_AgentUpdateCallTimes'
		SET @Sql = 
			'ALTER procedure [dbo].[ccsp_AgentUpdateCallTimes]
@IDCall int,
@cal_tXfer smallint,
@cal_tDialog smallint,
@cal_tNotas smallint,
@TipoCall tinyint,
@cal_tRing smallint=0,
@mtmoh smallint = 0,
@isChatCall bit = 0,
@isErroManualCall bit =0,
@isTransferEngine bit =0
AS
set nocount on
if @IDCall<=0 
    return(0)

declare @tMinAVRS smallint
declare @cal_manual int
declare @minimoDialogo tinyint 
select @minimoDialogo = valor from ccSettings where setting_id = 13

set @cal_manual=0

if @TipoCall=1 begin--INBOUND
  if @cal_tDialog < @minimoDialogo and @isTransferEngine =1 begin
    --el status 18 es para llamada cortada con transferencia en Reminder
    exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @IDCall, @nStatus = 18
  end
  Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
  cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
  cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
  Where cal_id= @IDCall

  --Actualizar tiempo total de llamada
  exec ccsp_EngineLogTransfers 2, @IDCall, @TipoCall, 2, null, @cal_tXfer, @cal_tDialog

  -- Elimina callback generado por abandono
  
  if @isTransferEngine = 0  begin
  Declare @ANI_x varchar(19)
  select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

  DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
  DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
  end
end
else if @TipoCall=2 begin--OUTBOUND 
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

		EXEC (@Sql)

		SET @process = 'CW-2024 Alter SP --ccsp_EngineLogTransfers validate manual call'
		SET @Sql = 
			'ALTER procedure [dbo].[ccsp_EngineLogTransfers]
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

		EXEC (@Sql)

		SET @process = 'CW-2018 CallBack Reminder alter ccsp_RIAUpdateEspecConfig '
		SET @Sql = 
			'
      ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig]
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
@editableDtmf bit = null,
@prefijo VARCHAR(max) = null,
@addDataCallBackReminder bit = null
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
bnocturno = case when isnull(@tel_noct,0)=''0'' or @tel_noct='''' then ''0'' else ''1'' end,
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
editableDtmf = isnull(@editableDtmf,editableDtmf),
prefijo = isnull(@prefijo,prefijo),
addDataCallBackReminder = isnull(@addDataCallBackReminder,addDataCallBackReminder)
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
set nocount off
        
      '

		EXEC (@Sql)

		SET @process = 'CW-2018 CallBack Reminder alter ccsp_SaveStatusAgent'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
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
@tMusicHold int =0,
@isTransferEngine bit = 0
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

set @cal_tNotas =0
set @cal_tNotaOri=0
--4 Dialog,6 Notas, 27 Notas Fallida
if @TipoStatusAge_id in (4,6,27) and @call_id>0 begin
if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


set @cal_manual =0

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
@cam_id = cam_id,@cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas from ccoCallsOut where cal_id = @call_id
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

if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1 and @cal_manual<>1 begin
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
            values(right((cast(@call_id as varchar) + '''' + @cal_Key),20),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()) )
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
      values(right((cast(@call_id as varchar) + '''' + @cal_Key),20),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()))
    end
  end
end
end--@isTransferSurvey = 0 and @callout_id>0


end

if @TipoCall = 0 and @isLogout = 1  and @isTransferEngine = 1 begin --IN
declare @minimoDialogo tinyint 
select  @minimoDialogo = valor from ccSettings where setting_id = 13
if @cal_tDialog < @minimoDialogo
  begin
  --el status 18 es para llamada cortada con transferencia en Reminder
  exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id, @nStatus = 18
end

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
end
'

		EXEC (@Sql)

		SET @process = 'CW-2027 Plan de marcación ALTER SP  ccsp_Limpia'
		SET @Sql = 
			'ALTER procedure [dbo].[ccsp_Limpia]
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

		EXEC (@Sql)

		SET @process = 'CW-2152 Alter SP spInsertCall'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[spInsertCall]
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

		EXEC (@Sql)

		SET @process = 'CW-2393 ETIQUETAS EN PORTUGUES Permitir el valor 2 que es portugués en base de datos ccsp_RIAccSettingsConfig -- Version BD 119.122 -- '
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
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
            --when 2 then DescripcionPT 
            else [description] 	end descripcion
  FROM ccSettings WITH(NOLOCK, index(PK_ccSettings)) WHERE setting_id=@setting_id
  order by descripcion
  return(0)
  end

if @command=1
  begin
  Select setting_id, 
		case @idioma  when 0 then descripcion 
            --when 2 then DescripcionPT 
            else [description] end descripcion,
			valor, tipo,validate
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

		EXEC (@Sql)

		SET @process = 'CW-2018 CallBack Reminder alter ccsp_RIAConfEspec'
		SET @Sql = 
			'
        ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
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
,isnull(A.addDataCallBackReminder,0) as addDataCallBackReminder
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
where A.inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 4))
return(0)
set nocount off
'

		EXEC (@Sql)

		SET @process = 'CW-2532 --Alter SP ccsp_DLRGetDialInfo -- type data msg answer machine'
		SET @Sql = 
			'ALTER procedure [dbo].[ccsp_DLRGetDialInfo]
@callout_id int,    
@cam_id smallint=0,    
@iPortNumber smallint = 0    
AS    
set nocount on    
declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
declare @prefix as varchar(15)
declare @prefixCalKey as varchar(30)
declare @tNoContesta as tinyint    
declare @ani as varchar(50)    
declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint    
declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint    
declare @ivr_script smallint, @surveycamid int    
declare @call_record_cam as tinyint    
declare @pais as tinyint     
declare @sipHdrFormat varchar(255)    
    
set @prefix =''''    
set @tNoContesta = 25    
set @ani=''''    
set @iTipoDial = 0    
set @detectAnswerMachine = 0    
set @detectVoiceMail =1    
set @cam_tnotas = 30    
set @keepDial = 0    
    
select @pais = valor from ccsettings where setting_id = 104    
    
-- Mensajes    
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm    
from dbo.fn_ccCamps_SelMessage(@cam_id)    
    
-- Prefijo por puerto    
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )    
-- Prefijo por campa?a    
if @prefix =''''    
    select @prefix = dialPrefix from ccCamps where cam_id = @cam_id    
-- Prefijo general, si es que esta habilitado    
if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 1 = 1)    
    select @prefix = valor from ccsettings where setting_id =101    
    
select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0    
    
-- Propiedades de campa?a    
select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,    
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,    
@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0)    
from ccCamps C (nolock) where C.cam_id=@cam_id    
    
if @surveycamid > 0    
    select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid    
    
--Custom MOH Files    
DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)    
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile     
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden    

--Agrega prefijo Marcacion con directo    
set @prefixCalKey=''''
if (select valor from ccSettings where setting_id=202)=''1'' begin
  select @prefixCalKey=isnull(dialPrefix,'''') from ccoCallsOutSource with(nolock) where callout_id=@callout_id 
end

if @iPortNumber >= 0     
begin    
 SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)    
    
    SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)    
    , dial_tels    
    , C.cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, isnull(@message_name, '''') as message_name    
    , @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
    , case when dbo.TelAni(c.cal_telefono,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono,@lista_id) else @ani end ani    
    , case when dbo.TelAni(c.cal_telefono2,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono2,@lista_id) else @ani end ani2    
    , case when dbo.TelAni(c.cal_telefono3,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono3,@lista_id) else @ani end ani3    
    , case when dbo.TelAni(c.cal_telefono4,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono4,@lista_id) else @ani end ani4    
    , case when dbo.TelAni(c.cal_telefono5,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono5,@lista_id) else @ani end ani5    
    , @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail    
    , @cam_tnotas cam_tnotas, @keepDial keepDial    
    , isnull(@messageDNCL_name, '''') as messageDNCL_name    
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record    
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2    
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3    
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4    
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5    
    , isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name    
    , isnull(@MohFiles,'''') as mohFiles    
    ,@ivr_script ivrScript    
 ,@sipheader data     
    FROM ccoCallsOutSource C with(nolock)    
    WHERE C.callout_id = @callout_id    
    return    
end     
    
set nocount off'

		EXEC (@Sql)

		SET @process = 'CW-2605 --Alter SP ccsp_MailAdminAccount'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_MailAdminAccount]
@action int,
@meanContactTypeId smallint = 1,
@contactMeanId int=0,
@name   varchar(30)=null,
@conexionInfo   varchar(255)=null,
@inboundId  int=0,
@connUser   varchar(60)=null,
@ConnPass   varchar(30)=null,
@numMessages    tinyint=null,
@timeAlertMessage   tinyint=null,
@isActive bit =null,
@UserId int =null,
@idArea smallint =null,
@maxMails tinyint =3,
@answerTimeOut tinyint=null,
@revisionTime varchar(10)=null,
@daysTwitterRecord varchar(10)=null,
@closeConversationTime varchar(10)=null
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;
/****
Conexion Info Email In
    protocol|server|ssl|port|cleanMail|revisionTime
Conexion Info Email Out
    serverOut|portOut|tls|sslOut
Conexion Info Twitter
    usuarioID|token|tokenSecret|time|daysTwitterRecord
***/


declare @isActiveMail bit
set @isActiveMail=0

if @action = 1 begin --checha si esta activo el servicio
    select @isActiveMail = valor from ccSettings where setting_id=152
    if @isActiveMail = 1 begin
        select @isActiveMail=(case when isActive = 1 and @isActiveMail = 1 then 1 else 0 end) from meanContactType where meanContactTypeId = 1
    end
    select @isActiveMail as isActiveMail
    return (0)
end
else if @action = 2 begin -- carga la relacion de especialidades y cuentas de email de entrada
    select A.inboundId as IdIn,A.conexionInfo as ConexionInfo,A.connUser as [Username],A.connPass as [Password], A.isActive as IsActive
        from ContactMeanIn A
            inner join ccInbound B on A.inboundId=B.Inbound_Id
        where meanContactTypeId = @meanContactTypeId and B.Status=1 and A.isActive=1
end
else if @action = 3 begin   --
    select name,conexionInfo,connUser,ConnPass,numMessages,timeAlertMessage,answerTimeOut from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 4 begin--insert or update relation mail whit ACD by in
    ---Es necesario cambiar [ccsp_NetworkSocialAdminAccount] por que tambien se ocupa aqui
    DECLARE @tableConexionInfo TABLE(  id int, value varchar(255))
    if @connUser=''''   set @connUser=''nuxiba@nuxiba.com''
    if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
        if not exists(select * from ContactMeanIn where connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin
        if @name is null set @name=''''
        if @conexionInfo is null and @meanContactTypeId=1  set @conexionInfo=''''
        if @connUser is null set @connUser=''''
        if @connPass is null set @connPass=''''
        if @numMessages is null set @numMessages=3
        if @timeAlertMessage is null set @timeAlertMessage=5
        if @isActive is null set @isActive=0
        if @answerTimeOut is null set @answerTimeOut=0
        if @closeConversationTime is null set @closeConversationTime=3

        --Twitter deja los token
        --conexion Info usuarioID|token|tokenSecret|time|daysTwitterRecord
        if @meanContactTypeId= 2 begin

            if @conexionInfo is null begin
                set @conexionInfo=''usuarioID|token|tokenSecret''
                set @revisionTime=isnull(@revisionTime,''1'')
                set @daysTwitterRecord=isnull(@daysTwitterRecord,''0'')
            end
            else begin
            select @conexionInfo
                insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
                set @conexionInfo=null

                SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

                SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
                SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
            end
            set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
        end



        insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut,closeConversationTime)
                values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut,@closeConversationTime)
        select 1,''insert''
    end
        else select -1,''insert''
    end
    else begin
        if not exists(select * from ContactMeanIn where inboundId<>@inboundId and connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin

            select @name=isnull(@name,name), @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
                @numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
                @answerTimeOut= isnull(@answerTimeOut,answerTimeOut),@closeConversationTime=isnull(@closeConversationTime,closeConversationTime)
            from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId


            --Twitter deja los token
            if @meanContactTypeId= 2 begin
                --usuarioID|token|tokenSecret|time|daysTwitterRecord
                insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
                set @conexionInfo=null

                SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

                SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
                SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
                set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
            end


            update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
                numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut,
                closeConversationTime=@closeConversationTime
                where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
            select 1,''update''
        end
        else select -1,''update''
    end
    return (0)
end

else if @action = 5 begin--parameters check conection Mail In
    select conexionInfo,connUser,connPass from ContactMeanIn with(nolock) where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 6 begin--parameters check conection Mail Out
    select conexionInfo as ConexionInfo,connUser as UserName,connPass as Password, isActive as IsActive, contactMeanOutId as IdOut
        from ContactMeanOut with(nolock) where contactMeanOutId  = @contactMeanId
end
else if @action = 7 begin--list mail out by ACD
    select A.contactMeanOutId,A.name, A.conexionInfo,A.connUser,A.connPass,A.isActive
        from ContactMeanOut A with(nolock)

end
else if @action = 8 begin--insert account mail out
    if not exists(select * from ContactMeanOut where connUser=@connUser) begin
        insert into ContactMeanOut (meanContactTypeId,name,conexionInfo,connUser,ConnPass,isActive)
            values (@meanContactTypeId,@name,@conexionInfo,@connUser,@connPass,@isActive)
        select 1
        return(0)
    end
    else select -1
end
else if @action = 9 begin--update account mail out
    if not exists(select * from ContactMeanOut where contactMeanOutId <> @contactMeanId  and connUser=@connUser) begin

        select  @meanContactTypeId=isnull(@meanContactTypeId,meanContactTypeId),@name=isnull(@name,name),
            @conexionInfo=isnull(@conexionInfo,conexionInfo),@connUser=isnull(@connUser,connUser),
            @connPass=isnull(@connPass,ConnPass),@isActive=isnull(@isActive,isActive)
            from ContactMeanOut where contactMeanOutId = @contactMeanId

        update ContactMeanOut set meanContactTypeId=@meanContactTypeId,name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,isActive=@isActive
         where contactMeanOutId = @contactMeanId
         select 1,''update ''
    end
    else select -1
end
else if @action = 10 begin  --insert relation mail out and ACD
    if not exists(select * from relationContactMeanOutInbound where contactMeanOutId=@contactMeanId) begin
        insert into relationContactMeanOutInbound(contactMeanOutId,inboundId) values (@contactMeanId,@inboundId)
    end
end
else if @action = 11 begin --delete relation mail out and ACD
    delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId and inboundId=@inboundId
end
else if @action = 12 begin --delete mail out
    delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId
    delete ContactMeanOut where contactMeanOutId=@contactMeanId
end
else if @action = 13 begin --delete mail out
    if not exists(select * from ContactMeanOut where contactMeanOutId=@contactMeanId) begin
        update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
        select 1
    end
    else select -1
end
else if @action = 14 begin
    select * from relationContactMeanOutInbound
end
else if @action = 15 begin
    select * from relationContactMeanOutInbound where inboundId=@inboundId
end
--else if @action = 16 begin
--  update ccRIACat_Areas set maxMails = @maxMails where IDArea=@idArea
--end
else if @action = 17 begin  --
    select A.conexionInfo as ConexionInfo,A.connUser as UserName,A.connPass as Password,A.isActive as IsActive,inboundId as IdIn  from ContactMeanIn A where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
End
else if @action = 18 begin  --Carga cuentas de salida
    select A.contactMeanOutId as IdOut,A.conexionInfo as ConexionInfo ,A.connUser as UserName,A.connPass as [Password],isActive as IsActive from contactMeanOut A where isActive=1
end
else if @action = 19 begin   --relation MailOut and ACD
    select contactMeanOutId as Id,inboundId as AcdId from relationContactMeanOutInbound where inboundId = @inboundId or @inboundId = 0 order by inboundId
end
else if @action = 20 begin --relation MailOut and ACD
    select B.inboundId,A.conexionInfo,A.connUser,A.connPass
    from ContactMeanOut A
    inner join relationContactMeanOutInbound B on B.contactMeanOutId=A.contactMeanOutId
    where B.inboundId = @inboundId or @inboundId = 0
end
else if @action = 21 begin --relation MailOut and ACD
    update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
end
else if @action = 22 begin --Update type
    if @meanContactTypeId = 2 --Twitter
        set @conexionInfo=''usuarioID|token|tokenSecret|1|0''
    else
        set @conexionInfo=''''
    update ContactMeanIn set name = '''', conexionInfo = @conexionInfo, connUser = '''', isActive = 0 where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
    select 1,''unAssigned''
end
END'

		EXEC (@Sql)

		SET @process = 'CW-2605 --Alter SP ccsp_MailInitialStatistics'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_MailInitialStatistics]
@inboundId int=0,
@Option AS SMALLINT=0,
@User_id AS SMALLINT=0
AS
BEGIN

SET NOCOUNT ON;
declare @from datetime,@to datetime
  set @from =convert(datetime, convert(varchar(10),getdate(),121))
  set @to =dateadd(dd,1,@from)

  

if(@Option=0)
begin
  select
  count(*) received,
  count(case when messageStatusId = 1 then 1 else null end) pending,
  count(case when messageStatusId in (2,3) then 1 else null end) assigned,
  count(case when messageStatusId = 4 then 1 else null end) unassigned,
  count(case when messageStatusId in (5,6) then 1 else null end) sent,
  count(case when messageStatusId = 7 then 1 else null end) rejected,
  count(case when messageStatusId = 8 then 1 else null end) programFwd,
  count(case when messageStatusId = 9 then 1 else null end) forwarding,
  count(case when messageStatusId in (10,11) then 1 else null end) closed,
  count(case when messageStatusId = 3 then 1 else null end) active,
  isnull(AVG(B.twait + B.tretention + B.tresponse),0) avgtAtention,
  isnull(AVG(B.twait),0) avgtWait,
  isnull(MAX(B.twait),0) maxtWait
  from conversation A
  inner join message B on A.conversationId=b.conversationId
  where inboundId= @inboundId
  and (
    (
     messageStatusId in (1,4) or
    (tQueue is not null and convert(datetime, convert(varchar(10),tQueue,121)) = @from) or
    (tSend is not null and convert(datetime, convert(varchar(10),tsend,121)) = @from)
    )
    or [date] between @from and @to
   )
end
if @Option = 1
BEGIN

  select
  count(*) received,
  count(case when messageStatusId = 1 then 1 else null end) pending,
  count(case when messageStatusId in (2,3) then 1 else null end) assigned,
  count(case when messageStatusId = 4 then 1 else null end) unassigned,
  count(case when messageStatusId in (5,6) then 1 else null end) sent,
  count(case when messageStatusId = 7 then 1 else null end) rejected,
  count(case when messageStatusId = 8 then 1 else null end) programFwd,
  count(case when messageStatusId = 9 then 1 else null end) forwarding,
  count(case when messageStatusId in (10,11) then 1 else null end) closed,
  count(case when messageStatusId = 3 then 1 else null end) active ,
  isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
  isnull(AVG(msg.twait),0) avgtWait,
  isnull(MAX(msg.twait),0) maxtWait,
  InboundId inboundId
  from message msg (nolock) join conversation con (nolock) on con.conversationId=msg.conversationId
  where inboundId in (select inbound_id from ccInbound where inbound_id in (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0) and chat = 3)
  and (
    (
     messageStatusId in (1,4) or
    (tQueue is not null and convert(datetime, convert(varchar(10),tQueue,121)) = @from) or
    (tSend is not null and convert(datetime, convert(varchar(10),tsend,121)) = @from)
    )
    or [date] between @from and @to
   )
  GROUP BY InboundId
  END
END'

		EXEC (@Sql)

		SET @process = 'CW-2605 --Alter SP ccsp_MailSave'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_MailSave]
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
@mailClient varchar(255)= null,
@mailACD varchar(60)= null,
@isSender bit=0,
@isUser bit = 0,
@info varchar(255)=null,
@dispositionId smallint=0,
@subDispositionId smallint=0,
@tWrapUp int =0,
@tRetention int = 0,
@email varchar(255) = null,

---Finder
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0,
@top int=30
AS
BEGIN


declare @isEndConversation bit
declare @meanContactTypeId smallint
declare @xmlnode xml
declare @existAttached bit, @numInteracion smallint
declare @ids varchar(max)

set @meanContactTypeId = 1
SET NOCOUNT ON;

if @action = 1 begin --find uid ConversationMail
if not exists(select A.uid,C.mailInbound from messageMail A 
    inner join [message] B on A.messageId=B.messageId
    inner join [conversation] C on C.conversationId=B.conversationId
    where A.[uid]=@uid and C.mailInbound=@mailACD) 
    select 0
else select 1
  return (0)
end
else if @action = 2 BEGIN --new Conversation
    if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin
        insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)
        select @conversationId=SCOPE_IDENTITY()
        insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,0,@date,@messageStatusId)
        select @messageId=SCOPE_IDENTITY()
        insert into [messageMail](messageId,[uid]) values (@messageId,@uid)
        select @conversationId as ConversationId,@messageId as MessageId,0 as LastUserId
        return (0)
    end
    else begin
        select 0 as ConversationId,0 as MessageId,0 as LastUserId
        return (0)
    end
END
else if @action = 3 BEGIN --new Messages
    if @date is null set @date=getdate()
    if @mailACD is null select @mailACD=mailInbound from conversation where conversationId=@conversationId
    if not exists(select * from [conversation] where conversationId=@conversationId) begin --si el id conversacion no existe
        insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)
        select @conversationId=SCOPE_IDENTITY()
    end

    if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin     
        insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,@userId,@date,@messageStatusId)
        select @messageId=SCOPE_IDENTITY()
    end
    else begin
        select 0 as ConversationId,0 as MessageId,0 as LastUserId
        return (0)
    end

    if @uid is null --for outbound messages
        select @uid = dbo.md5(cast(@conversationId as varchar(10)) + ''_'' + cast(@messageId as varchar(10)))

    insert into [messageMail](messageId,[uid]) values (@messageId,@uid)

    --Finder
    select @existAttached =case when count(*)>0 then 1 else 0 end  from attached where messageId in (select messageId from message where conversationId=@conversationId)
    select @numInteracion = count(*) from message where conversationId=@conversationId
    --Actualiza un nodo del finder
    exec ccsp_CreateNodeMultimedia @type=1, @conversationId=@conversationId, @xml = @xmlnode OUTPUT
    if not exists(select * from ccEmailNode where emailId=@conversationId) begin
        insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
    end
    else begin
        update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
    end
    select @conversationId as ConversationId,@messageId as MessageId,0 as LastUserId

END
else if @action = 4 BEGIN --new attachment
    insert into [attached](messageId,pathFile,isUser) values(@messageId,@pathFile,@isUser)
    select SCOPE_IDENTITY() as attachedId
END
else if @action = 5 BEGIN --Correos por contestar Status DOWNLOAD,Assigned,READ,UnaSSIGNED   
	select top(@top) A.conversationId,B.userId,A.mailClient,A.mailInbound,A.info,B.messageStatusId,B.messageId from (
	select A.conversationId,max(A.mailClient) as mailClient ,max(A.mailInbound) as mailInbound,min(A.info) as info,
		max(B.messageId) as messageId from conversation  A 
	inner join message B on A.conversationId = B.conversationId
	where A.inboundId = @inboundId and A.isFinished=0 and meanContactTypeId = @meanContactTypeId
	group by A.conversationId
	) A 
	inner join message B on A.conversationId = B.conversationId and A.messageId = B.messageId
	where B.messageStatusId in(1,2,3,4)

END
else if @action = 6 BEGIN --update Time Attention, Retencion
    select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
    update [message] set tResponse=@timeAtt,tRetention=@tRetention,isSender=@isSender,messageStatusId=@messageStatusId,userId=@userId where messageId=@messageId
END
else if @action = 7 BEGIN --Cambia el status del mensaje
    select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
    --Status Read
    if @messageStatusId=3  update [message] set tWait=DATEDIFF(ss,isnull(tQueue,getdate()), getdate()) where messageId=@messageId

    --Status Send
    if @messageStatusId=6  begin
        select @isEndConversation=isFinished from conversation where conversationId=@conversationId
        if @isEndConversation = 1 set @messageStatusId=11--Close conversation by Agent
        update [message] set tSend=getdate() where messageId=@messageId
    end
    update [message] set messageStatusId=@messageStatusId where messageId=@messageId

    --Answered,Send,CLose Conversation system or agent
    if @messageStatusId in (5,6,10,11)  begin
        exec ccsp_CreateNodeMultimedia @type=1, @conversationId=@conversationId, @xml = @xmlnode OUTPUT
		if exists(select * from ccEmailNodeHistory where emailId=@conversationId) begin
            update ccEmailNodeHistory set node=@xmlnode,status=2 where emailId=@conversationId
        end
        if  exists(select * from ccEmailNode where emailId=@conversationId) begin
            update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
        end
        else begin
            insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
        end
    end

END
else if @action = 8 BEGIN --info del ultimo correo
    select messageId,GP.inboundId,C.connUser mailInbound,mailClient,mediaType,messageStatusId,info,I.descripcion,IG.graphic_id,I.tNotas,isnull(C.answerTimeOut,10) tTimeOut,C.timeAlertMessage tAlert
    from (
        select max(B.messageId) messageId,A.inboundId,A.mailClient, case A.meanContactTypeId when 1 then 3 else -1 end mediaType, B.messageStatusId, max(A.info) info
        from conversation A inner join message B  on A.conversationId = B.conversationId  where A.conversationId=@conversationId  GROUP BY A.inboundId,A.mailClient, A.meanContactTypeId, B.messageStatusId, B.userId) GP
    inner join contactMeanIn C on C.inboundId=GP.inboundId
    inner join ccInbound I on I.Inbound_id=GP.inboundId
    inner join ccRIAInboundGraph IG on IG.Inbound_id=GP.inboundId
END
else if @action = 9 BEGIN --carga adjuntos del ultimo mensaje
    if @conversationId is null or @conversationId=0 begin
        set @conversationId=0
        select @conversationId=conversationId from message where messageId=@messageId 
    end
    
    select pathFile as NameFile,isUser from attached A
    inner join message B on A.messageId=B.messageId and B.conversationId=@conversationId
    where B.conversationId=@conversationId
END
else if @action = 10 BEGIN --Correos por enviar
    select A.conversationId as ConversationId,B.messageId as MessageId,B.userId as AgentId,A.inboundId as AcdId,A.mailInbound as MailInbound
	 from (
	select A.inboundId,A.conversationId as ConversationId,max(B.messageId) as MessageId,A.mailInbound   from conversation A 
	inner join message B on A.conversationId = B.conversationId
	where A.meanContactTypeId = 1 --and (@inboundId is null or A.inboundId=3)
	GROUP BY A.conversationId,A.inboundId,A.mailInbound 
	) A
	inner join message B on A.MessageId = B.messageId
	where B.messageStatusId in(5,7,8,9) 
END

else if @action = 11 BEGIN --Califica el mensaje y pone el tiempo Notas
    if @subDispositionId <> 0 begin
        select @isEndConversation=isnull(EndConversation,0) from ccTipoCalifSub where califSub_id=@subDispositionId
    end
    else begin
        select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@dispositionId
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
 update [message] set @messageStatusId=1,tQueue=null,userId=0,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0  where messageStatusId in(2,3)
end
else if @action = 15 begin
    SELECT @existAttached = case when count(*)>0 then 1 else 0 end
    from attached where messageId in (select messageId from message where conversationId=@conversationId)

    select max(messageid) as messageid,max(A.inboundid) as inboundid,max(a.conversationid) as conversationid,
        max(mailClient) as mailClient, min([date]) as [date], @existAttached isAttached, max(C.descripcion) as descripcion,
        max(B.tSend) as tSend, max(D.Nombres+'' ''+D.ApellidoPaterno+'' ''+D.ApellidoMaterno) as nameAgent,
        max(E.timeAlertMessage) timeAlertMessage ,max( E.answerTimeOut) answerTimeOut, max(C.tNotas) as tNotas,
        max(A.mailInbound) as MailInbound, isnull(max(E.name), '''') as name
    from conversation A
    inner join message B  on A.conversationId = B.conversationId
    inner join ccinbound C on A.inboundid= C.inbound_id
    left join ccUsers D on B.userId = D.User_id
    inner join contactMeanIn E on E.inboundId=C.Inbound_id   and E.meanContactTypeId=@meanContactTypeId
    where A.conversationId=@conversationId

end
else if @action = 16 begin
    select A.inboundid,B.messageid,a.conversationid,c.pathFile
    from conversation A
    inner join message B  on A.conversationId = B.conversationId
    inner join attached C on B.messageid= C.messageid
    where A.conversationId=@conversationId
end
else if @action = 17 begin --Asignar una evluacion
    exec ccsp_CreateNodeMultimedia @type=1, @conversationId=@conversationId, @xml = @xmlnode OUTPUT,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate
    if not exists(select * from ccEmailNode where emailId=@conversationId) begin
        insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
    end
    else begin
        update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
    end
end
else if @action = 18 begin --cerrar conversacion por tiempo
    if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date)
    if @conversationId = 0
        select 0
    else begin
        declare @closeConversation tinyint
        declare @tRsponse datetime
        select @tRsponse = isnull(max(tSend), getdate()) from message where messageId = @conversationId
        select @closeConversation = closeConversationTime from contactMeanIn
         if datediff(dd,getdate(),@tRsponse ) > @closeConversation
            select 0
        else
            select @conversationId
        end
    return 0
end
else if @action = 19 begin
    select isnull(max(C.Uid),0) [maxUid] from conversation A
    inner join message B on A.conversationId=B.conversationId
    inner join messageMail C on C.messageId=B.MessageId
    where inboundId=@inboundId and mailInbound=@mailACD
end
else if @action = 20 begin
    if @messageId is null begin
        select @ids=COALESCE(@ids + '','', '''') + cast(messageId as varchar(max))  from message where conversationId=@conversationId
        select @inboundId=inboundId from conversation where conversationId=@conversationId
        select @ids as ids,@inboundId as inboundId
    end
    else begin
        select case when count(*)>0 then 1 else 0 end  from attached where messageId=@messageId
    end
end
else if @action = 21 begin
    declare @isFinished bit
    set @isFinished = 0

    select @isFinished=isFinished from conversation where conversationId=@conversationId
    select @isFinished
end

else if @action = 22 begin
   
   declare @correo varchar(255)
   select  @correo = mailClient from conversation where conversationId = @conversationId      
   
   insert into emailSpam (inboundId,agentId,conversationId,correo,fecha) values (@inboundId,@userId,@conversationId,@correo,getDate())   

   update Conversation set isFinished = 1 where mailClient = @correo
   update message set messageStatusId = 13 where messageId = @messageId

   select distinct conversationId as ConversationId,inboundId as AcdId from emailSpam where correo = @correo

end

else if @action = 23 begin      
   if exists (select  * from emailSpam where correo like ''%''+@email+''%'') begin
        select 1
   end
   else begin
        select 0 
   end
end

END'

		EXEC (@Sql)

		SET @process = 'CW-2602 Alter SP ccsp_RIAGetCampsNvosCB -- Boton Clicker desaparece '
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0, @tcpa int=0
as
set nocount on

declare @TipoJobs as int,@isExecOutbound bit


set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

	declare @id AS INTEGER

	CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
	CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime)

	create table #temccocallsoutsource (cam_id int,Pend  int)

	create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

	if @cam_id = 0 begin
	if @user_id > 0 begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
		from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
		where user_id = @user_id and tipo = 1
	end
	else begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
		from ccCamps cam (nolock) join ccSupervisorCam supcam with(nolock) on tipo=1 and cam.cam_id  =  supcam.cam_id
	end

	end
	else begin
	if @Tipo = 2
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
		from ccCamps cam with(nolock)
		join ccSupervisorCam supcam with(nolock) on tipo=1 and cam.cam_id  =  supcam.cam_id
		where cam.cam_id = @cam_id
	else
		if @user_id > 0 begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
		from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
		where user_id = @user_id and tipo = 1
		end
		else begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
		from ccCamps cam (nolock) join ccSupervisorCam supcam with(nolock) on tipo = 1 and cam.cam_id  =  supcam.cam_id
		where user_id = @user_id and cam_activo=1
		end
	end



	insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate)
	select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate) from(
	select A.*,dateUpdate from #Tcamps A
	left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
	where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null)X
	group by cam_id


	--Se revisa que por lo menos una campaña se pueda actualizar para realizar el proceso en caso contrario se regresa el valro extablecido
	if (select count(*) from #Tcamps2)>0 begin

	insert into #temccocallsoutsource(cam_id,Pend)
	SELECT ccos.cam_id, count(ccos.cam_id) as Pend
	FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
	join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
	WHERE cal_status in(0, 7)
	GROUP BY ccos.cam_id

	insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
	SELECT A.cam_id,
	count(case cal_status when 0 then 1 else null end) as New,
	count(case cal_status when 1 then 1 else null end) as Cb,
	count(case cal_status when 2 then 1 else null end) as Pro,
	count(case cal_status when 3 then 1 else null end) as Fin
	FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
	join #Tcamps2 B on A.cam_id = B.cam_id
	GROUP BY A.cam_id

	--select * from #Tcamps2

	--Se va agregar al ccsp_OUTGetNewJobs cuando lo ejecute el SP Outbound para actualizar de manera seguida si solo es una campaña
	if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
		update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @cam_id
	end
	else begin
		While exists(select * from #Tcamps2 where status = 0 and ( datediff(ss,dateUpdate,getdate())>60 or dateUpdate is null))  Begin
		set rowcount 1
		select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
		set rowcount 0
		EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
		update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
		end
	end

	begin Tran updateccCampsNvosCB

		delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps tcamp
		where CampNvosCB.id = tcamp.cam_id

		INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial,dateUpdate)
		SELECT cams.cam_id, cams.cam_descripcion,
		isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
		isNull(cs.Pend,0) as pend,
		isNull(wt.Pro,0) as pro,
		isNull(cams.procesando,0) cam_procesando,
		isNull(cams.cam_tipojobs,0) cam_tipojobs,
		isNull(wt.Fin,0) Fin,
		isNull(tc.cantidad,0) cantidad,
		getdate()
		FROM #Tcamps cams with(nolock)
		LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
		LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
		left join #Tcamps2 tc on (tc.cam_id = cams.cam_id)

	COMMIT TRAN updateccCampsNvosCB
	end

	if @isExecOutbound = 0 begin

	if @Tipo = 2
		-- devuelve resultado de la taba, solo las camps del usuario
		SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, res.st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor
		FROM #Tcamps tcam
		left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
	else
		SELECT id, campaña, new, cb, pro, pen,st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,cc.aggressionFactor
		FROM ccCampsNvosCB res (nolock)
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
		WHERE res.id = @cam_id
	end

	drop table #Tcamps
	drop table #Tcamps2
	drop table #temccocallsoutsource
	drop table #temWorkinTable

	return(0)

end

set nocount off'

		EXEC (@Sql)

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
