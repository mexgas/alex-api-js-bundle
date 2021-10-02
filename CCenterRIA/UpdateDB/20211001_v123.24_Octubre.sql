/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 24
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

    set @process = 'CW-5828 ccsp_GalateaLoadUsersForManagement - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaLoadUsersForManagement'')
            begin
          DROP PROCEDURE ccsp_GalateaLoadUsersForManagement;
            end'
    EXEC(@sql)

    set @process = 'CW-5828 ccsp_GalateaLoadUsersForManagement '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
 @option SMALLINT,
 @AreaId SMALLINT,
 @UserType INT,
 @Username VARCHAR(200)=null,
 @userId INT =0
as

--Obtiene el idioma de de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

IF @option = 1 --Agentes/supervisores de un Area  
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
  ORDER BY LOGIN, Nombres, ApellidoPaterno,Sexo, User_id

  RETURN (0)
END

IF @option = 2 -- obtiene Agente o supervisor en base a su nombre de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE Login=@Username

  RETURN (0)
END

IF @option = 3 -- obtiene Agente o supervisor en base a su ID de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE user_id=@userId

  RETURN (0)
END


IF @option = 4 -- supervisores en Area/Sistema
BEGIN
	DECLARE @Admins TABLE (UserId smallint, Username varchar(50), Names varchar(50), LastName varchar(50), OptionalExtraName varchar(50), AreaId smallint, primary key(UserId))
	INSERT INTO @Admins
	SELECT User_id as UserId,
	LOGIN as Username,
	Nombres as Names,
	CASE 
	  WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
	  ELSE isnull(ApellidoPaterno, '''')
	END as LastName,

	CASE 
	  WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
	  ELSE isnull(ApellidoMaterno, '''')
	END as OptionalExtraName,

	isnull(IDArea, 0) as AreaId
	FROM ccusers
	WHERE TipoUser_id = 2 AND STATUS = 1


	IF NOT EXISTS(SELECT * FROM ccUsers_Roles WHERE User_id=@userId and Rol_id=7) BEGIN
		SELECT UserId, Username, Names, LastName, OptionalExtraName
		FROM @Admins
		WHERE AreaId = (SELECT IDArea FROM ccUsers WHERE User_id=@userId)
		ORDER BY Username, Names, LastName, UserId
	END
	ELSE BEGIN
		SELECT UserId, Username, Names, LastName, OptionalExtraName
		FROM @Admins
		ORDER BY Username, Names, LastName, UserId
	END

  RETURN (0)
END'
    EXEC(@sql)

    set @process = 'CW-5828, CW-5841 Se quita el SP ccsp_GalateaChangeHistory si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaChangeHistory'')
            begin
          DROP PROCEDURE ccsp_GalateaChangeHistory;
            end'
    EXEC(@sql)

    set @process = 'CW-5828, CW-5841 Se crea SP ccsp_GalateaChangeHistory'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaChangeHistory] 
	@option TINYINT, 
	@loginLst VARCHAR(max) = NULL, 
	@moduleWithOperation varchar(max) = NULL, 
	@operationDateIni SMALLDATETIME = NULL, 
	@operationDateFin SMALLDATETIME = NULL,
	@top INT = 0
	AS
	SET NOCOUNT ON

	DECLARE @lang TINYINT

	SELECT @lang = valor
	FROM ccsettings
	WHERE setting_id = 27

	IF @option = 1 -- Catalogo de modulos
	BEGIN
		WITH Catalog AS(
		SELECT cast(m.module_id as int) module_id, cast(o.operationType as int) operationType, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion) + 1, len(m.descripcion)) END AS mDescripcion, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion) + 1, len(o.descripcion)) END AS oDescripcion
		FROM ccRIALog_Operation o WITH (INDEX (IX_ccRIALog_Operation))
		JOIN ccRIALog_Cat_Relation r ON o.operationType = r.operationType
		JOIN ccRIALog_Module m WITH (INDEX (IX_ccRIALog_Module)) ON r.module_id = m.module_id
						
		UNION
						
		SELECT 0, - 1, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, '' - ''
						
		UNION
						
		SELECT 0, 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
						
		UNION
						
		SELECT cast(module_id as int) module_id, 0, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
		FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))
						
		UNION
						
		SELECT cast(module_id as int) module_id, - 1 , CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, '' - ''
		FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module)))

		SELECT module_id,operationType,mDescripcion,oDescripcion FROM Catalog 
		WHERE module_id not in(5,8,14,21,22,25,32,33,36,37,44,53,57,58,59,60,42)
		AND operationType not in(6,15,51,58,36,46,44,45,59,12,8,7,55,54,33)
		ORDER BY mDescripcion, oDescripcion

		RETURN (0)
	END

	IF @option = 2 -- Muestra informacion por filtros
	BEGIN

		declare @sql as nvarchar(max)
		DECLARE @table TABLE(id int,value varchar(max))
		declare @id int
		declare @moduleId varchar(max)
		declare @operationLst varchar(max)
		declare @query varchar(max) = '' and (''
		declare @value varchar(max)
		declare @first int = 1
		declare @pos int
	
		insert into @table select * from dbo.fn_RIASplitDelimited(cast(isnull(@moduleWithOperation,'''') as varchar(max)), '','')
		while exists(select * from @table)
		begin
			select top 1 @id = id, @value = value from @table
			set @pos = charindex('':'', @value)
			if(@pos <> 0)
			begin
				set @moduleId = substring(@value, 1, @pos-1)
				set @operationLst = replace(substring(@value, @pos+1, len(@value)), ''-'', '','')
				if(@first = 1)
				begin
					set @query = @query + ''l.module_id='' + @moduleId + '' and l.operationType in ('' + @operationLst + '')''
					set @first = 0
				end
				else
				begin
					set @query = @query + '' or l.module_id='' + @moduleId + '' and l.operationType in ('' + @operationLst + '')''
				end
			end

			delete @table where id = @id
		end
		set @query = @query + '')''
	

		SET ROWCOUNT @top

		set @sql =
		''DECLARE @tableLogin TABLE(id int,value varchar(255))
		insert into @tableLogin  select * from dbo.fn_RIASplitDelimited('''''' + cast(isnull(@loginLst,'''') as varchar(max)) + '''''','''','''')

		SELECT L.log_id, L.areaName, L.operationDate, 
		CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''''|'''', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''''|'''', o.descripcion) + 1, len(o.descripcion)) END operationType, 
		L.LOGIN, 
		CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''''|'''', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''''|'''', m.descripcion) + 1, len(m.descripcion)) END module_id, 
		CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target, 
		CASE WHEN v.valueT IS NULL THEN L.value ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN v.es WHEN 2 THEN v.pt ELSE v.en END END AS value
		FROM CCRIALOG L
		JOIN ccRIALog_Module M WITH (INDEX (IX_ccRIALog_Module)) ON L.module_id = M.module_id
		JOIN ccRIALog_Operation O WITH (INDEX (IX_ccRIALog_Operation)) ON L.operationType = O.operationType
		LEFT JOIN targetRecord t ON t.targetT = L.target
		LEFT JOIN valueRecord v ON v.valueT = L.value
		WHERE 1=1 ''
		+
		case isnull(@loginLst, '''') when '''' then '''' else 
		'' AND L.LOGIN in (select value from @tableLogin) ''
		END 
		+
		case isnull(@moduleWithOperation, '''') when '''' then '''' else
		@query
		end
		+ case ISNULL(@operationDateIni, '''') when '''' then '''' else
		''AND L.operationDate >= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull('''''' + convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, -1, '''''' + convert(varchar(19), @operationDateIni, 121) + '''''') ELSE L.operationDate END ''
		+ '' AND L.operationDate <= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull(''''''+ convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, 1, '''''' + convert(varchar(19), @operationDateFin, 121) + '''''') ELSE L.operationDate END''
		end
		+
		'' ORDER BY L.operationDate DESC''
		execute sp_executesql @sql
		--print @sql
	END


	SET NOCOUNT OFF'
    EXEC(@sql)




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