/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2023/07/04
Description: K089000
Database: CCenterRia
Required version: 125.37
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 7
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end
IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END
IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY
 
	----------------------------------------------------- BEGIN Gaby  ----------------------------------------------------------------


	SET @process = 'CREATE TABLE CodesInterDialing2';
	SET @sql = '
	IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''CodesInterDialing2'') BEGIN
	    CREATE TABLE [dbo].[CodesInterDialing2](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](50) NULL,
	[ES] [varchar](max) NULL,
	[EN] [varchar](max) NULL,
	[PT] [varchar](max) NULL,
	[Code] [varchar](25) NULL,
	[CodeWithout] [varchar](25) NULL,
	[length] int NULL,
) 
	END';
	EXEC (@sql);
		
	SET @process = 'KR134006-7 se agregan operaciones, modulos e identificadores para el historial de actividad'
	SET @sql= 'IF NOT EXISTS (select * from ccSettings2 where setting_id = 273)
	BEGIN
		insert into ccSettings2(setting_id, valor,descripcion,Status,Tipo, detalle, description, bLoadSettings, validate)
		values (273,''+52'',''Codigo de área'',1,''GRL'',''Codigo del país desde donde se realizan las llamadas'',''Area code'',0,''.*'')
	END'

	set @process = 'Insert Permissions'
	set @sql = 'if exists (select * from CodesInterDialing)
	begin
		insert into CodesInterDialing2 ([Description],ES,EN,PT,Code,CodeWithout,[length])
		select [Description],ES,EN,PT,Code,replace(Code,''-'',''''),len(replace(Code,''-'','''')) length from CodesInterDialing
	end
	'
	EXEC(@sql)

    SET @process = 'DROP fn Limpia2'
    SET @sql = '
	if exists (select * from sys.objects where object_id = OBJECT_ID(N''Limpia2'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
	begin
		DROP FUNCTION Limpia2;
	end'
    EXEC(@sql);

	set @process = 'Create fn Limpia2'
	set @sql = 'CREATE FUNCTION [dbo].[Limpia2](@Phone varchar(32))
RETURNS varchar(32) AS  
BEGIN
DECLARE @limpiada NVARCHAR(MAX) = ''''

DECLARE @index INT = 1
DECLARE @longitud INT = LEN(@Phone)

WHILE @index <= @longitud
BEGIN
    DECLARE @caracter NVARCHAR(1) = SUBSTRING(@Phone, @index, 1)
    
    IF PATINDEX(''%[0-9]%'', @caracter) > 0 OR (@caracter = ''+'' AND @index = 1) -- Mantener solo números y el símbolo de más al inicio
    BEGIN
        SET @limpiada = @limpiada + @caracter
    END

    SET @index = @index + 1
END

declare @codeCountry varchar(10), @codeCountryLen int
set @codeCountry= (select valor from ccSettings2 where setting_id = 272)
set @codeCountry=REPLACE(@codeCountry,''+'','''')
set @codeCountryLen=len(@codeCountry)




IF LEFT(@limpiada,1)<>''+'' begin
	IF LEFT(@limpiada, len(@codeCountry)) = @codeCountry  begin
		return ''N_''+ substring(@limpiada,@codeCountryLen,len(@limpiada)-@codeCountryLen)
	end
	return ''N_''+@limpiada
end
set @limpiada=replace(@limpiada,''+'','''')

IF LEFT(@limpiada, len(@codeCountry)) = @codeCountry  begin
	return ''N_''+ substring(@limpiada,@codeCountryLen,len(@limpiada)-@codeCountryLen)
end
return ''I_''+@limpiada



end'
	EXEC(@sql)
	
	SET @process = 'DROP SP ccsp_GetDialingCodesByCamp'
    SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GetDialingCodesByCamp'')
	begin
		DROP PROCEDURE ccsp_GetDialingCodesByCamp;
	end'
    EXEC(@sql);

	SET @process = 'Create sp ccsp_GetDialingCodesByCamp'
	SET @sql= 'CREATE PROCEDURE [dbo].[ccsp_GetDialingCodesByCamp]
@cam_id int
as
begin
		
	;with tableTmp as (		
	select distinct isnull(id, 0) as id, isnull(CodeWithout, 0 ) as Code,0 length from ccoDialers a
	inner join ccoDialerCamp b on a.dialer_id = b.dialer_id
	left join CodesInterDialing2 c on a.IdCode = c.id
	where a.DialingType = 0 and b.cam_id = @cam_id 
	)
	
	select A.id
	,case when B.Numero is null then A.Code else A.Code+convert(varchar(10),B.Numero) end Code
	,case when B.Numero is null then len(A.Code) else len( A.Code+convert(varchar(10),B.Numero)) end length
	from tableTmp A
	left join AreaCode B on A.id=B.IdCode
	
	
end'

	EXEC(@sql);

	
	-------------------------------------------------- End Gaby -----------------------------------------------------------------------------------
 	
        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()
        RAISERROR (@errorGenerated, 11, 1)
        ROLLBACK TRAN
    END CATCH
END 
