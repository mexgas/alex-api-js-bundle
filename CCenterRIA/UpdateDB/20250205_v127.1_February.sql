/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio Chagolla
Date: 2024/09/30
Description: Release 126.20241218.0.0
Database: CCenterRia
Required version: 126.6
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
SET @version = 127 --**********actualizar a 124 sin fix
SET @versionfix = 1
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
        ------------------------------------------- BEGIN Ricardo Nunez LRSV ----------------------------------------
        SET @process = 'Facturacion - Columna TemplateId en ccoWhatsLogDials'
        SET @sql = 'IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccoWhatsLogDials'' AND COLUMN_NAME = ''TemplateId'')
					BEGIN
						ALTER TABLE ccoWhatsLogDials 
						ADD TemplateId bigint NULL; 
					END
'
        EXEC(@sql)
		
 
		SET @process = 'Facturacion - Columna CountryAbbreviation en ccWhatsOringCountry'
        SET @sql = '
		
		IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccWhatsOringCountry'' AND COLUMN_NAME = ''CountryAbbreviation'')
		BEGIN
			ALTER TABLE ccWhatsOringCountry
			ADD CountryAbbreviation VARCHAR(2) NULL;

			
		END'
        EXEC(@sql)

		SET @process = 'Facturacion - Se modifica campo de CountryAbbreviation'
		SET @sql = '		
		UPDATE ccWhatsOringCountry
			SET CountryAbbreviation = CASE
				WHEN country = ''USA'' THEN ''US''
				WHEN country = ''Bahamas'' THEN ''BS''
				WHEN country = ''Barbados'' THEN ''BB''
				WHEN country = ''Anguilla'' THEN ''AI''
				WHEN country = ''Antigua'' THEN ''AG''
				WHEN country = ''British Virgin Islands'' THEN ''VG''
				WHEN country = ''US Virgin Islands'' THEN ''VI''
				WHEN country = ''Cayman Islands'' THEN ''KY''
				WHEN country = ''Bermuda'' THEN ''BM''
				WHEN country = ''Grenada'' THEN ''GD''
				WHEN country = ''Turks & Caicos'' THEN ''TC''
				WHEN country = ''Montserrat'' THEN ''MS''
				WHEN country = ''Guam'' THEN ''GU''
				WHEN country = ''St. Lucia'' THEN ''LC''
				WHEN country = ''Puerto Rico'' THEN ''PR''
				WHEN country = ''Dominican Republic'' THEN ''DO''
				WHEN country = ''Trinidad & Tobago'' THEN ''TT''
				WHEN country = ''St. Kitts/Nevis'' THEN ''KN''
				WHEN country = ''Jamaica'' THEN ''JM''
				WHEN country = ''Egypt'' THEN ''EG''
				WHEN country = ''Morocco'' THEN ''MA''
				WHEN country = ''Algeria'' THEN ''DZ''
				WHEN country = ''Tunisia'' THEN ''TN''
				WHEN country = ''Libya'' THEN ''LY''
				WHEN country = ''Gambia'' THEN ''GM''
				WHEN country = ''Senegal'' THEN ''SN''
				WHEN country = ''Mauritania'' THEN ''MR''
				WHEN country = ''Guinea'' THEN ''GN''
				WHEN country = ''Ivory Coast'' THEN ''CI''
				WHEN country = ''Burkina Faso'' THEN ''BF''
				WHEN country = ''Niger'' THEN ''NE''
				WHEN country = ''Benin'' THEN ''BJ''
				WHEN country = ''Liberia'' THEN ''LR''
				WHEN country = ''Sierra Leone'' THEN ''SL''
				WHEN country = ''Ghana'' THEN ''GH''
				WHEN country = ''Nigeria'' THEN ''NG''
				WHEN country = ''Chad'' THEN ''TD''
				WHEN country = ''Central African Republic'' THEN ''CF''
				WHEN country = ''Cameroon'' THEN ''CM''
				WHEN country = ''Cape Verde'' THEN ''CV''
				WHEN country = ''Congo'' THEN ''CG''
				WHEN country = ''Congo, Dem. Rep. of'' THEN ''CD''
				WHEN country = ''Angola'' THEN ''AO''
				WHEN country = ''Sudan'' THEN ''SD''
				WHEN country = ''Rwandese Republic'' THEN ''RW''
				WHEN country = ''Ethiopia'' THEN ''ET''
				WHEN country = ''Djibouti'' THEN ''DJ''
				WHEN country = ''Kenya'' THEN ''KE''
				WHEN country = ''Tanzania'' THEN ''TZ''
				WHEN country = ''Uganda'' THEN ''UG''
				WHEN country = ''Burundi'' THEN ''BI''
				WHEN country = ''Mozambique'' THEN ''MZ''
				WHEN country = ''Zambia'' THEN ''ZM''
				WHEN country = ''Madagascar'' THEN ''MG''
				WHEN country = ''Zimbabwe'' THEN ''ZW''
				WHEN country = ''Malawi'' THEN ''MW''
				WHEN country = ''Botswana'' THEN ''BW''
				WHEN country = ''Swaziland'' THEN ''SZ''
				WHEN country = ''Comoros'' THEN ''KM''
				WHEN country = ''South Africa'' THEN ''ZA''
				WHEN country = ''Eritrea'' THEN ''ER''
				WHEN country = ''Aruba'' THEN ''AW''
				WHEN country = ''Greenland'' THEN ''GL''
				WHEN country = ''Greece'' THEN ''GR''
				WHEN country = ''Netherlands'' THEN ''NL''
				WHEN country = ''Belgium'' THEN ''BE''
				WHEN country = ''France'' THEN ''FR''
				WHEN country = ''Spain'' THEN ''ES''
				WHEN country = ''Gibraltar'' THEN ''GI''
				WHEN country = ''Portugal'' THEN ''PT''
				WHEN country = ''Luxembourg'' THEN ''LU''
				WHEN country = ''Ireland'' THEN ''IE''
				WHEN country = ''Iceland'' THEN ''IS''
				WHEN country = ''Albania'' THEN ''AL''
				WHEN country = ''Malta'' THEN ''MT''
				WHEN country = ''Cyprus'' THEN ''CY''
				WHEN country = ''Finland'' THEN ''FI''
				WHEN country = ''Bulgaria'' THEN ''BG''
				WHEN country = ''Hungary'' THEN ''HU''
				WHEN country = ''Lithuania'' THEN ''LT''
				WHEN country = ''Latvia'' THEN ''LV''
				WHEN country = ''Estonia'' THEN ''EE''
				WHEN country = ''Moldova'' THEN ''MD''
				WHEN country = ''Armenia'' THEN ''AM''
				WHEN country = ''Belarus'' THEN ''BY''
				WHEN country = ''Monaco'' THEN ''MC''
				WHEN country = ''San Marino'' THEN ''SM''
				WHEN country = ''Vatican City'' THEN ''VA''
				WHEN country = ''Ukraine'' THEN ''UA''
				WHEN country = ''Serbia/Montenegro'' THEN ''RS''
				WHEN country = ''Croatia'' THEN ''HR''
				WHEN country = ''Slovenia'' THEN ''SI''
				WHEN country = ''Bosnia/Herzegovina'' THEN ''BA''
				WHEN country = ''Macedonia'' THEN ''MK''
				WHEN country = ''Italy'' THEN ''IT''
				WHEN country = ''Romania'' THEN ''RO''
				WHEN country = ''Switzerland'' THEN ''CH''
				WHEN country = ''Czech Republic'' THEN ''CZ''
				WHEN country = ''Slovak Republic'' THEN ''SK''
				WHEN country = ''Liechtenstein'' THEN ''LI''
				WHEN country = ''Austria'' THEN ''AT''
				WHEN country = ''United Kingdom'' THEN ''GB''
				WHEN country = ''Denmark'' THEN ''DK''
				WHEN country = ''Sweden'' THEN ''SE''
				WHEN country = ''Norway'' THEN ''NO''
				WHEN country = ''Poland'' THEN ''PL''
				WHEN country = ''Germany'' THEN ''DE''
				WHEN country = ''Diego Garcia'' THEN ''US''
				WHEN country = ''Ascension'' THEN ''BS''
				WHEN country = ''Falkland Islands'' THEN ''FK''
				WHEN country = ''Belize'' THEN ''BZ''
				WHEN country = ''Guatemala'' THEN ''GT''
				WHEN country = ''El Salvador'' THEN ''SV''
				WHEN country = ''Honduras'' THEN ''HN''
				WHEN country = ''Nicaragua'' THEN ''NI''
				WHEN country = ''Costa Rica'' THEN ''CR''
				WHEN country = ''Panama'' THEN ''PA''
				WHEN country = ''Haiti'' THEN ''HT''
				WHEN country = ''Peru'' THEN ''PE''
				WHEN country = ''Mexico'' THEN ''MX''
				WHEN country = ''Cuba'' THEN ''CU''
				WHEN country = ''Guantanamo Bay'' THEN ''CU''
				WHEN country = ''Argentina'' THEN ''AR''
				WHEN country = ''Brazil'' THEN ''BR''
				WHEN country = ''Chile'' THEN ''CL''
				WHEN country = ''Colombia'' THEN ''CO''
				WHEN country = ''Venezuela'' THEN ''VE''
				WHEN country = ''Guadeloupe'' THEN ''GP''
				WHEN country = ''Bolivia'' THEN ''BO''
				WHEN country = ''Guyana'' THEN ''GY''
				WHEN country = ''Ecuador'' THEN ''EC''
				WHEN country = ''French Guiana'' THEN ''GF''
				WHEN country = ''Paraguay'' THEN ''PY''
				WHEN country = ''Martinique'' THEN ''MQ''
				WHEN country = ''Suriname'' THEN ''SR''
				WHEN country = ''Uruguay'' THEN ''UY''
				WHEN country = ''Netherlands Antilles'' THEN ''NL''
				WHEN country = ''Malaysia'' THEN ''MY''
				WHEN country = ''Australia'' THEN ''AU''
				WHEN country = ''Philippines'' THEN ''PH''
				WHEN country = ''New Zealand'' THEN ''NZ''
				WHEN country = ''Singapore'' THEN ''SG''
				WHEN country = ''Thailand'' THEN ''TH''
				WHEN country = ''East Timor'' THEN ''TL''
				WHEN country = ''Australian External Territories'' THEN ''NF''
				WHEN country = ''Brunei Darussalam'' THEN ''BN''
				WHEN country = ''Nauru'' THEN ''NR''
				WHEN country = ''Papua New Guinea'' THEN ''PG''
				WHEN country = ''Solomon Islands'' THEN ''SB''
				WHEN country = ''Fiji Islands'' THEN ''FJ''
				WHEN country = ''Palau'' THEN ''PW''
				WHEN country = ''Cook Islands'' THEN ''CK''
				WHEN country = ''Western Samoa'' THEN ''WS''
				WHEN country = ''New Caledonia'' THEN ''NC''
				WHEN country = ''French Polynesia'' THEN ''PF''
				WHEN country = ''Micronesia'' THEN ''FM''
				WHEN country = ''Marshall Islands'' THEN ''MH''
				WHEN country = ''Russia'' THEN ''RU''
				WHEN country = ''Japan'' THEN ''JP''
				WHEN country = ''Korea (South)'' THEN ''KR''
				WHEN country = ''Vietnam'' THEN ''VN''
				WHEN country = ''Korea (North)'' THEN ''KP''
				WHEN country = ''Hong Kong'' THEN ''HK''
				WHEN country = ''Macao'' THEN ''MO''
				WHEN country = ''Cambodia'' THEN ''KH''
				WHEN country = ''Laos'' THEN ''LA''
				WHEN country = ''China'' THEN ''CN''
				WHEN country = ''Bangladesh'' THEN ''BD''
				WHEN country = ''Taiwan'' THEN ''TW''
				WHEN country = ''Turkey'' THEN ''TR''
				WHEN country = ''India'' THEN ''IN''
				WHEN country = ''Pakistan'' THEN ''PK''
				WHEN country = ''Afghanistan'' THEN ''AF''
				WHEN country = ''Sri Lanka'' THEN ''LK''
				WHEN country = ''Maldives'' THEN ''MV''
				WHEN country = ''Lebanon'' THEN ''LB''
				WHEN country = ''Jordan'' THEN ''JO''
				WHEN country = ''Syria'' THEN ''SY''
				WHEN country = ''Iraq'' THEN ''IQ''
				WHEN country = ''Kuwait'' THEN ''KW''
				WHEN country = ''Saudi Arabia'' THEN ''SA''
				WHEN country = ''Yemen'' THEN ''YE''
				WHEN country = ''Oman'' THEN ''OM''
				WHEN country = ''United Arab Emirates'' THEN ''AE''
				WHEN country = ''Israel'' THEN ''IL''
				WHEN country = ''Bahrain'' THEN ''BH''
				WHEN country = ''Qatar'' THEN ''QA''
				WHEN country = ''Bhutan'' THEN ''BT''
				WHEN country = ''Mongolia'' THEN ''MN''
				WHEN country = ''Nepal'' THEN ''NP''
				WHEN country = ''Iran'' THEN ''IR''
				WHEN country = ''Tajikistan'' THEN ''TJ''
				WHEN country = ''Turkmenistan'' THEN ''TM''
				WHEN country = ''Azerbaijan'' THEN ''AZ''
				WHEN country = ''Georgia'' THEN ''GE''
				WHEN country = ''Uzbekistan'' THEN ''UZ''
			END
			where CountryAbbreviation is null
		'
		EXEC(@sql)
 
		
        

		SET @process = 'Facturacion - Validación de sp ccsp_WAOUTGetNewJobs'
        SET @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_WAOUTGetNewJobs'')
		begin
			DROP PROCEDURE ccsp_WAOUTGetNewJobs
		end'
        EXEC(@sql)

		SET @process = 'Facturacion - Cambios en ccsp_WAOUTGetNewJobs'
        SET @sql = '
			CREATE PROCEDURE [dbo].[ccsp_WAOUTGetNewJobs]
				@campId INT,
				@action INT=0, --0 select and update, 1 select registry
				@topCount INT=80

				as
				set nocount on
				DECLARE @iZonas INT = NULL
				DECLARE @bIsDaylight bit, @revHorario bit
				DECLARE @country_id INT, @TipoJobs INT

				DECLARE @sql nvarchar(MAX), @Order_Asc_Desc char(4)
				declare @sqlInsertGeneric nvarchar(MAX)
				declare @parameters nvarchar(MAX)
						
				-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
				SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
				SELECT @revHorario=valor from ccsettings where setting_id = 112
				-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
				SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@campId
				SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

				SET DATEFIRST 1
				--Checamos si es horario de verano
				SELECT @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

				exec @iZonas= ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0

				if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
				begin
					if @iZonas = 0 begin
						SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
						return
					end
				end


				IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS

				CREATE TABLE #NEW_JOBS (
					WAOutId INT
					,CamId INT
					,Phone VARCHAR(30) collate SQL_Latin1_General_CP1_CI_AS
					,Status TINYINT
					,DateDial DATETIME	
					,Tz1 INT
					,CallKey VARCHAR(40)	
					,Components NVARCHAR(4000)
					,TemplateId bigint
					)
				set @sql=''''

				DECLARE @new_calls_date VARCHAR(max) = '''';
						

				SELECT @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

				DECLARE @isVerano varchar(max)

					set @isVerano = ''W.TimeZone'' + case @bIsDaylight when 1 then ''_summer'' else '''' END

					

					select @sqlInsertGeneric=nchar(13)+ ''INSERT #NEW_JOBS
				SELECT top(@topCount) W.waout_id, W.CamId, W.phoneNumber, W.WaStatus,W.dateDial,''
				+@isVerano+'',
				w.callkey,
				wos.componentJson
				, wos.TemplateId
				FROM ccoWAWorkingTable W 
				inner join ccWhatsAppOutSource wos (nolock) on wos.waout_id=W.waout_id
				WHERE WaStatus in (0)
				and W.CamId=@campId
				and (
				( (''+@isVerano+''  & @iZonas)>0 or ''+@isVerano+''=0) 
				)
				order by W.dateDial ''+ @Order_Asc_Desc +'', waout_id ''+ @Order_Asc_Desc

				if @TipoJobs in(0,2)--** INCLUIR LOS NUEVAS
				begin				
					select @sql=@sql+nchar(13)+''--INCLUIR LAS NUEVAS--''
					select @sql=@sql+REPLACE(
					REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.dateDial < dateadd(mi, 5, getdate())'')--Todo cambiar
						,''STATUS_REPLACE_QUERY'',''W.WaStatus=0'')
					
					--print(@sql)
				end -- TOMA EN CUENTA LAS NUEVAS

				----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
				set @parameters=''@CAMPID int,@topCount int,@iZonas int''		

				if @action=0 begin	
					SELECT @sql=@sql+nchar(13)+ ''update ccoWAWorkingTable with (rowlock) SET WaStatus=2 where WAOut_id in(select WaOutId from #NEW_JOBS)''	
				end

						
				select @sql=@sql+nchar(13)+ ''SELECT WaOutId, CamId, Phone, Status, DateDial,
				Tz1,CallKey as RegistryClient,Components as MessageJson,TemplateId
				FROM #NEW_JOBS where len(Phone)>0
				''

				print (@sql)

				exec sp_executesql  @sql,@parameters,
				@CAMPID=@CAMPID
				,@topCount=@topCount
				,@iZonas=@iZonas

				IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS

				return(0)'
        EXEC(@sql)

        -------------------------------------------  END Ricardo Nunez LRSV  ----------------------------------------
	
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
