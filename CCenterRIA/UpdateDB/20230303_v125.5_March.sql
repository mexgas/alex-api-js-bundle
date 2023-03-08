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

		------------------------------JCL------------------------------

	set @process = 'SPEC-74 Eliminar telefonos sin zona horaria para evitar infringir el reglamento de husos horarios'

    set @sql = '
		if not exists (select * from sys.tables where name = N''BlockedNumbers'')
		begin
			CREATE TABLE [dbo].[BlockedNumbers](
				[callout_id] [int] NOT NULL,
				[phoneNumber] [varchar](50) NOT NULL,
				[cam_id] [int] NOT NULL,
				[dateRemoved] [datetime] NOT NULL
			) ON [PRIMARY]
		end
	'
    EXEC(@sql)		

		SET @process = 'SPEC-74 Eliminar telefonos sin zona horaria para evitar infringir el reglamento de husos horarios'

	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RemoveNoTZNumbers'')

		BEGIN

			DROP PROCEDURE ccsp_RemoveNoTZNumbers

		END'

	EXEC(@sql)

	SET @process = 'SPEC-74 Eliminar telefonos sin zona horaria para evitar infringir el reglamento de husos horarios'

	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RemoveNoTZNumbers]
				AS
				BEGIN

				insert into BlockedNumbers
				select callout_id, cal_telefono, cam_id, getdate() from ccoWorkingTable where iZonaHoraria = 0

				delete from ccoWorkingTable where iZonaHoraria=0

				END'

		EXEC(@sql)

	 set @process = 'SPEC-74 Eliminar telefonos sin zona horaria para evitar infringir el reglamento de husos horarios'
     
	 set @sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewProviderJobs]
		@CAMPID as int,
		@test as int=0,
		@nAgentsLogin as int=1
		as
		set nocount on
		declare @topCount smallint, @bIsDaylight bit, @revHorario bit
		declare @country_id int, @TipoJobs int
		declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
		declare @sql varchar(MAX), @Order_Asc_Desc char(4)
		declare @camSurvey int
		DECLARE @iZonasTable TABLE (value int)

		select @camSurvey = 0

		select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

		-- VALIDAMOS EL PAIS Y LADA CONFIGURADA --
		SELECT @country_id =valor FROM ccSettings WHERE setting_id=104

		--elimina numeros sin zona horaria de USA
		if (@country_id = 4) 
		begin

			exec dbo.ccsp_RemoveNoTZNumbers

		end

		select @revHorario=valor from ccsettings where setting_id = 112
		-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
		SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
		SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

		SET DATEFIRST 1
		--Checamos si es horario de verano
		select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
		if @iZonas is null begin

			INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
			select @iZonas=value from @iZonasTable
			--Checamos si la campaña tiene horarios configurados
			if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
				begin
				declare @horaUniversal as datetime
				set @horaUniversal=getutcdate()

				if @iZonas = 0 begin
					SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
					return
				end
				end

			else
			begin
				if @camSurvey > 0
					begin
						SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
						return
					end
			end
		end

		set @sql=''CREATE TABLE #NEW_JOBS
		(callout_id int,
			cam_id int,
			cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
			cal_status tinyint,
			cal_fechaDial datetime,
			user_id int,
			tz int,
		tz2 int,
		tz3 int,
		tz4 int,
		tz5 int,
		tel varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
		tel2 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
		tel3 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
		tel4 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
		tel5 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
		tel_type smallint,
		tel2_type smallint,
		tel3_type smallint,
		tel4_type smallint,
		tel5_type smallint,
		dialOrder varchar(10),
		list_id int,
		sequence smallint,
		calkey varchar(max)
		)''

		-- 0=Ambas, 1=CallBacks, 2=Nuevas
		select @topCount=valor from ccSettings where setting_id=94

		if isnull(@topCount,0)=0
			select @topCount=case when @nAgentsLogin<3 then 30
			when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
			when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
			when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
			when @nAgentsLogin>=16 then 240 else 20 end

		select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

		declare @isVerano varchar(max)
		set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

		if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
			begin
			select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

			select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
			SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
			W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
			W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
			W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
			W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
			W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
			couts.cal_telefono as tel,
			couts.cal_telefono2 as tel2,
			couts.cal_telefono3 as tel3,
			couts.cal_telefono4 as tel4,
			couts.cal_telefono5 as tel5,''
			if @country_id = 1
			begin
				set @sql=@sql+''dbo.fnGetCallType(couts.cal_telefono) tel_type,
				dbo.fnGetCallType(couts.cal_telefono2) tel2_type,
				dbo.fnGetCallType(couts.cal_telefono3) tel3_type,
				dbo.fnGetCallType(couts.cal_telefono4) tel4_type,
				dbo.fnGetCallType(couts.cal_telefono5) tel5_type,
				''
			end
			else
			begin
				set @sql=@sql+''0 tel_type,0 tel2_type,0 tel3_type,0 tel4_type,0 tel5_type,''
			end
			set @sql=@sql+''
			cpt.Prioridad as dialOrder, W.list_id, isnull(R.sequence,0) as sequence,
			couts.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
			FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
			on W.list_id = R.list_id
			left join ccocallsoutsource couts (nolock)
			on W.callout_id = couts.callout_id
			inner join ccCampsPrioridadTel cpt (nolock)
			on cpt.cam_id = W.cam_id
			WHERE W.cal_status=1 -- CallBacks
			and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
			and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
			and (
				((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
			or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
				((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
			or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
				((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
			or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
				((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
			or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
				((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
			or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
			)
			and isnull(R.status,2) = 2
			order by W.prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
			end -- TOMA EN CUENTA LOS CALLBACKS

		if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
			begin
			select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

			select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
			SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
			W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
			W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
			W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
			W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
			W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
			couts.cal_telefono as tel,
			couts.cal_telefono2 as tel2,
			couts.cal_telefono3 as tel3,
			couts.cal_telefono4 as tel4,
			couts.cal_telefono5 as tel5,''
			if @country_id = 1
			begin
				set @sql=@sql+''dbo.fnGetCallType(couts.cal_telefono) tel_type,
				dbo.fnGetCallType(couts.cal_telefono2) tel2_type,
				dbo.fnGetCallType(couts.cal_telefono3) tel3_type,
				dbo.fnGetCallType(couts.cal_telefono4) tel4_type,
				dbo.fnGetCallType(couts.cal_telefono5) tel5_type,
				''
			end
			else
			begin
				set @sql=@sql+''0 tel_type,0 tel2_type,0 tel3_type,0 tel4_type,0 tel5_type,''
			end
			set @sql=@sql+''
			cpt.Prioridad as dialOrder, W.list_id, isNull(R.sequence,0) as sequence,
			couts.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
			FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
			on W.list_id = R.list_id
			left join ccocallsoutsource couts (nolock)
			on W.callout_id = couts.callout_id
			inner join ccCampsPrioridadTel cpt (nolock)
			on cpt.cam_id = W.cam_id
			WHERE W.cal_status=0 -- Nuevas
			and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
			and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
			and (
				( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
			or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
				( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
			or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
				((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
			or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
				((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
			or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
				((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
			or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
			)
			and isnull(R.status,2) = 2
			order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', W.callout_id''

			end -- TOMA EN CUENTA LAS NUEVAS

		----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
		select @sql=@sql+nchar(13)+ ''SET rowcount 0''
		if @Test=0
			begin
			select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
			WHERE callout_id in(select callout_id from #NEW_JOBS)''
			end

		select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
		user_id, tz, tz2, tz3, tz4, tz5, tel, tel2, tel3, tel4, tel5, dialOrder, list_id, sequence, calkey,
		tel_type, tel2_type, tel3_type, tel4_type, tel5_type
		FROM #NEW_JOBS where len(cal_telefono)>0''

		select @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
		--print @sql
		exec(@sql)
		return(0)'

	 EXEC(@sql)

		------------------------------JCL------------------------------		

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
