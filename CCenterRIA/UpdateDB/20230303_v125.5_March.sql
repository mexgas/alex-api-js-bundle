/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.33

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
SET @version = 125 --**********actualizar a 123 sin fix
SET @versionfix = 5
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validación para cuando pasamos a una nueva versión LTS
IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN

	BEGIN TRY
		
		------------------------------Begin Marco Garcia  ---------------------------------------------------------
		SET @process = 'CW-7814  Se muestra una etiqueta en inglés cuando el idioma del sistema esta en portugués en el detalle de registros no cargados delete store procedure ccsp_RIALogPhones'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIALogPhones'')
		BEGIN
			DROP PROCEDURE ccsp_RIALogPhones
		END'
	EXEC(@sql)

	SET @process = 'CW-7814  Se muestra una etiqueta en inglés cuando el idioma del sistema esta en portugués en el detalle de registros no cargados create store procedure ccsp_RIALogPhones'
	SET @sql = 'CREATE procedure [dbo].[ccsp_RIALogPhones]
		@load_id int,
		@Type smallint,
		@GenCSV bit = 1, -- 0:100 / 1:todos
		@isKolob bit = 0,
		@PageIndex      INT = 0,
		@PageSize       INT = 0,
		@option SMALLINT = NULL
		as
		set nocount ON

		declare @CaseType varchar(2000), @sql varchar(MAX), @nType char(5), @MovType SMALLINT, @language VARCHAR(300), @column VARCHAR(100), 
		@typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200), @typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
		@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200);

		SELECT @language = cs.valor FROM dbo.ccSettings AS cs WHERE cs.setting_id = 27;

		-- Labels
		IF(@language = 0)
		BEGIN
			SET @column = ''COLUMNA'';
			SET @typeDescriptionPhoneNotLoaded = ''Teléfono no cargado'';
			SET @typeDescriptionPhoneBlocked = ''Teléfono bloqueado'';
			SET @typeDescriptionPhoneUpdated = ''Teléfono actualizado'';
			SET @typeDescriptionPhoneBlackList = ''Teléfono en lista negra'';
			SET @typeBlockedRecords = ''Registro bloqueado'';
			SET @typeIncorrectRecords = ''Registro no cargado'';
			SET @descriptionBlockedRecords = ''Todos los teléfonos bloqueados'';
			SET @descriptionIncorrectRecords = ''Todos los teléfonos inválidos'';
		END
		ELSE IF(@language = 1)
		BEGIN
			SET @column = ''COLUMN'';
			SET @typeDescriptionPhoneNotLoaded = ''Not loaded number'';
			SET @typeDescriptionPhoneBlocked = ''Blocked number''
			SET @typeDescriptionPhoneUpdated = ''Updated number'';
			SET @typeDescriptionPhoneBlackList = ''Number in DNC list'';
			SET @typeBlockedRecords = ''Blocked record'';
			SET @typeIncorrectRecords = ''Not loaded record'';
			SET @descriptionBlockedRecords = ''All numbers are blocked'';
			SET @descriptionIncorrectRecords = ''All numbers are invalid'';
		END
		ELSE
		BEGIN
			SET @column = ''COLUNA'';
			SET @typeDescriptionPhoneNotLoaded = ''Telefone não carregado'';
			SET @typeDescriptionPhoneBlocked = ''Telefone bloqueado''
			SET @typeDescriptionPhoneUpdated = ''Telefone atualizado'';
			SET @typeDescriptionPhoneBlackList = ''Telefone em lista negra'';
			SET @typeBlockedRecords = ''Registro bloqueado'';
			SET @typeIncorrectRecords = ''Registro não carregado'';
			SET @descriptionBlockedRecords = ''Todos os telefones bloqueados'';
			SET @descriptionIncorrectRecords = ''Todos os telefones inválidos'';
		END

		select @CaseType = '''', @nType = right(''0000''+cast(@Type as varchar(5)), 5)

		if @nType like ''%____1%''
			select @CaseType = @CaseType + '' or isnull(telefono, '''''''') = '''''''' and crlp.tipoMov = 0 ''

		if @nType like ''%___1_%''
			select @CaseType = @CaseType + '' or isnull(telefono, '''''''') <> '''''''' and crlp.tipoMov = 0 ''

		if @nType like ''%__1__%''
			select @CaseType = @CaseType + '' or isnull(telefono, '''''''') = '''''''' and crlp.tipoMov = 1 ''

		if @nType like ''%_1___%''
			select @CaseType = @CaseType + '' or isnull(telefono, '''''''') <> '''''''' and crlp.tipoMov = 1 ''

		if @nType like ''%1____%''
			select @CaseType = @CaseType + '' or isnull(telefono, '''''''') = '''''''' and crlp.tipoMov = 2 ''

		if @CaseType = '''' and @nType <> 0
			return(0)
        
		IF(@option = 1)
		BEGIN	
			SET @sql = ''SELECT count(*) AS listSize FROM (select  
						ROW_NUMBER() OVER(ORDER BY crlp.load_id ASC) AS RowNum,
						crlp.load_id,
						crlp.cal_key, 
						dbo.Limpia(crlp.telefono) AS phone, 
						CASE 
							WHEN crlp.tipoMov = 0 THEN ''''Teléfono no cargado'''' 
							WHEN crlp.tipoMov = 1 OR crlp.tipoMov = 4 THEN ''''Teléfono bloqueado''''  
							WHEN crlp.tipoMov = 2 THEN ''''Teléfono actualizado'''' 
						ELSE 
							crlp2.descTipoMov   
						END AS Tipo, 
						ISNULL(
						CASE 
							WHEN (SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(crlp.motivo, '''':'''') ORDER BY Id) = ''''Tel1'''' THEN ISNULL(fhpl.header_phone, '''''''')  
							WHEN (SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(crlp.motivo, '''':'''') ORDER BY Id) = ''''Tel2'''' THEN ISNULL(fhpl.header_phone2, '''''''')   
							WHEN (SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(crlp.motivo, '''':'''') ORDER BY Id) = ''''Tel3'''' THEN ISNULL(fhpl.header_phone3, '''''''') 
							WHEN (SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(crlp.motivo, '''':'''') ORDER BY Id) = ''''Tel4'''' THEN ISNULL(fhpl.header_phone4, '''''''')   
							WHEN (SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(crlp.motivo, '''':'''') ORDER BY Id) = ''''Tel5'''' THEN ISNULL(fhpl.header_phone5, '''''''')   
						END, '''''''') AS ColumnFile,
						CASE  WHEN crlp.tipoMov = 2 THEN '''''''' ELSE crlp.motivo END AS motivo
						from ccRIALogPhones AS crlp 
						INNER JOIN dbo.ccRIACATLogPhones AS  crlp2 ON crlp.tipoMov = crlp2.tipoMov
						LEFT JOIN dbo.fileHeadersPhoneLoad AS fhpl ON fhpl.load_id = crlp.load_id
						where crlp.load_id = '' 
						+ cast(@load_id as varchar(10)) + 
						case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' END +'') tmp '' +
						case @GenCSV when 0 then ''WHERE tmp.RowNum > ''+ cast(@PageSize as varchar(10)) +'' * ( ''+cast(@PageIndex as varchar(10))+'' - 1)
						AND tmp.RowNum <= ''+ cast(@PageSize as varchar(10)) +'' * ''+cast(@PageIndex as varchar(10))+'''' else '''' end +''''
			EXEC(@sql);
			RETURN (0);
		END
		ELSE 
		BEGIN
				IF(@isKolob = 1)
				BEGIN
					SET @sql = ''SELECT * FROM (select  
						ROW_NUMBER() OVER(ORDER BY crlp.load_id ASC) AS RowNum,
						crlp.load_id,
						crlp.cal_key, 
						dbo.Limpia(crlp.telefono) AS phone,
						CASE
							WHEN (crlp.tipoMov = 1 OR crlp.tipoMov = 4)  THEN ''''''+@typeDescriptionPhoneBlocked+''''''  
							WHEN crlp.tipoMov = 2 THEN ''''''+@typeDescriptionPhoneUpdated+''''''
							WHEN crlp.motivo = ''''Todos incorrectos'''' THEN ''''''+ @typeIncorrectRecords +''''''
							WHEN crlp.motivo = ''''Todos Bloqueados'''' THEN ''''''+ @typeBlockedRecords +''''''
							WHEN crlp.tipoMov = 0 THEN ''''''+@typeDescriptionPhoneNotLoaded+''''''
						ELSE 
							crlp2.descTipoMov   
						END AS Tipo, 
						ISNULL(
						CASE 
							WHEN (SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(crlp.motivo, '''':'''') ORDER BY Id) = ''''Tel1'''' THEN
								CASE WHEN (SELECT COUNT(*) FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone, ''''''''),''''F''''))  = 2 
										AND (SELECT TOP (1) ISNUMERIC(Value) FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone, ''''''''),''''F'''') ORDER BY Id DESC) = 1 THEN ''''''+@column+''''''+CONVERT(varchar(10) ,(SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone, ''''''''),''''F'''') ORDER BY Id DESC)) 
									ELSE
									ISNULL(fhpl.header_phone, '''''''')
								END 
							WHEN (SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(crlp.motivo, '''':'''') ORDER BY Id) = ''''Tel2'''' THEN
								CASE WHEN (SELECT COUNT(*) FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone2, ''''''''),''''F''''))  = 2 
										AND (SELECT TOP (1) ISNUMERIC(Value) FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone2, ''''''''),''''F'''') ORDER BY Id DESC) = 1 THEN ''''''+@column+''''''+CONVERT(varchar(10) ,(SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone2, ''''''''),''''F'''') ORDER BY Id DESC))
									ELSE
									ISNULL(fhpl.header_phone2, '''''''')
								END 
							WHEN (SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(crlp.motivo, '''':'''') ORDER BY Id) = ''''Tel3'''' THEN 
								CASE WHEN (SELECT COUNT(*) FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone3, ''''''''),''''F''''))  = 2 
										AND (SELECT TOP (1) ISNUMERIC(Value) FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone3, ''''''''),''''F'''') ORDER BY Id DESC) = 1 THEN ''''''+@column+ ''''''+CONVERT(varchar(10) ,(SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone3, ''''''''),''''F'''') ORDER BY Id DESC))
									ELSE
									ISNULL(fhpl.header_phone3, '''''''')
								END 
							WHEN (SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(crlp.motivo, '''':'''') ORDER BY Id) = ''''Tel4'''' THEN
								CASE WHEN (SELECT COUNT(*) FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone4, ''''''''),''''F''''))  = 2 
										AND (SELECT TOP (1) ISNUMERIC(Value) FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone4, ''''''''),''''F'''') ORDER BY Id DESC) = 1 THEN ''''''+@column+ ''''''+CONVERT(varchar(10) ,(SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone4, ''''''''),''''F'''') ORDER BY Id DESC))
									ELSE
									ISNULL(fhpl.header_phone4, '''''''')
								END 
							WHEN (SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(crlp.motivo, '''':'''') ORDER BY Id) = ''''Tel5'''' THEN 
								CASE WHEN (SELECT COUNT(*) FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone5, ''''''''),''''F''''))  = 2 
										AND (SELECT TOP (1) ISNUMERIC(Value) FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone5, ''''''''),''''F'''') ORDER BY Id DESC) = 1 THEN ''''''+@column+ ''''''+CONVERT(varchar(10) ,(SELECT TOP (1) Value FROM dbo.fn_RIASplitDelimited(ISNULL(fhpl.header_phone5, ''''''''),''''F'''') ORDER BY Id DESC))
									ELSE 
									ISNULL(fhpl.header_phone5, '''''''')
								END 
						END, '''''''') AS ColumnFile,
						CASE  WHEN crlp.tipoMov = 2 THEN ''''N/A'''' 
							  WHEN (crlp.tipoMov = 1 OR crlp.tipoMov = 4) THEN ''''''+@typeDescriptionPhoneBlackList+''''''
							  WHEN crlp.motivo = ''''Todos incorrectos'''' THEN ''''''+ @descriptionIncorrectRecords +''''''
							  WHEN crlp.motivo = ''''Todos Bloqueados'''' THEN ''''''+ @descriptionBlockedRecords +''''''
						ELSE crlp.motivo END AS motivo
						from ccRIALogPhones AS crlp 
						INNER JOIN dbo.ccRIACATLogPhones AS  crlp2 ON crlp.tipoMov = crlp2.tipoMov
						LEFT JOIN dbo.fileHeadersPhoneLoad AS fhpl ON fhpl.load_id = crlp.load_id
						where crlp.load_id = '' 
						+ cast(@load_id as varchar(10)) + 
						case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' END +'') tmp '' +
						case @GenCSV when 0 then ''WHERE tmp.RowNum > ''+ cast(@PageSize as varchar(10)) +'' * ( ''+cast(@PageIndex as varchar(10))+'' - 1)
						AND tmp.RowNum <= ''+ cast(@PageSize as varchar(10)) +'' * ''+cast(@PageIndex as varchar(10))+'''' else '''' end +'' 
						ORDER BY tmp.cal_key''
				END
				ELSE
				BEGIN
						set @sql = ''select '' + case @GenCSV when 0 then ''top 100 '' else '''' end 
						+ ''load_id, cal_key, telefono, tipoMov, motivo 
						from ccRIALogPhones AS crlp where load_id = '' 
						+ cast(@load_id as varchar(10)) + 
						case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' END 
				END  
				--PRINT(@sql);

				EXEC(@sql);
			return(0)
		END
		set nocount OFF'
		EXEC(@sql)

		------------------------------End Marco Garcia  ---------------------------------------------------------

		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
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
