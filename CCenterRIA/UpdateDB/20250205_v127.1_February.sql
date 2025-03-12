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
        SET @process = 'Facturacion - Columna TemplateId en ccoWhatsLogDials.TemplateId'
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

		SET @process = 'Facturacion - Registro de codeCountry 1'
        SET @sql = '
		if not exists (select 1 from ccWhatsOringCountry where CodeCountry = 1)
		begin
			insert into ccWhatsOringCountry values (1, ''USA'', ''systemTranslated_USA'', 1, ''US'')
		end'
        EXEC(@sql)

        -------------------------------------------  END Ricardo Nunez LRSV  ----------------------------------------
		------------------------------------------- Begin Hector Chavez   --------------------------------------
		 SET @process = 'KR170000 Generate ID menu'
   		 SET @sql = ' IF NOT EXISTS(SELECT * FROM ccMenus where menu_id = 2110)
             			BEGIN
              				INSERT INTO ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
                       		 VALUES (2110,''Tiempos de jornada|Shift Time'',2000,''B'',2,3,'''',''59e49d1a69b47480dbea6022fcbb02d186f63530500b9861f99ff8de26f86450'');
             			END
            		'
   		 EXEC(@sql);

		 SET @process = 'KR170000 Adding admin relationship report'
		 SET @sql= ' IF NOT EXISTS(SELECT * FROM ccMenuUser WHERE id_Menu=2110)
		 		 BEGIN
				 	INSERT INTO ccMenuUser (id_User, id_Menu,type) VALUES (1,2110,3)
				 END
		 	   '
		EXEC(@sql)
		------------------------------------------- End Hector Chavez   --------------------------------------
         SET @process = 'Facturacion - Columna TemplateId en ccoWhatsLogDials delete from ccMenuRol'
        SET @sql = 'delete from ccMenuRol where menu_id in(11000,11010,11020,11030,11040)
delete from ccMenuUser where id_Menu in(11000,11010,11020,11030,11040)
delete from ccMenus where menu_id in(11000,11010,11020,11030,11040)
'
        EXEC(@sql)


        --------------------------------------------------- START CW-8988 Hugo Longoria -------------------------------------------------------------

	SET @process = 'SPEC-99 setting para nueva telefonia'
	SET @sql= 'IF NOT EXISTS (select * from ccSettings where setting_id = 252)
	BEGIN
		insert ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values
		(252,''1|1-50|https://switch.nuxiba.com|engine||3|0|Freeswitch'',''Balancer Configuration'',1,''GRL'',''Balancer Configuration'',''Balancer Configuration'',0,''.*'')
	END'
	EXEC(@sql);

	SET @process = 'SPEC-99 tabla sip headers engine, antes en ini'
	SET @sql= 'IF NOT EXISTS (SELECT * 
					 FROM INFORMATION_SCHEMA.TABLES 
					 WHERE TABLE_SCHEMA = ''dbo'' 
					 AND  TABLE_NAME = ''ccSIPCustomHeaders'')
	BEGIN
		create table ccSIPCustomHeaders (header varchar(254) not null, value varchar(254) not null)
	END'
	EXEC(@sql);

	SET @process = 'SPEC-99 tabla ivr dnis, antes en xml ivr'
	SET @sql= 'IF NOT EXISTS (SELECT * 
					 FROM INFORMATION_SCHEMA.TABLES 
					 WHERE TABLE_SCHEMA = ''dbo'' 
					 AND  TABLE_NAME = ''ccIVRDnis'')
	BEGIN
		create table ccIVRDnis (ivr_id varchar(50) not null, ivr_name varchar(50), dni_number varchar(50) not null)
	END'
	EXEC(@sql);
	

	SET @process = 'Drop procedure ccsp_DLRInsertCall'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_DLRInsertCall'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_DLRInsertCall
		END'
    EXEC(@sql);

	SET @process = 'CREATE procedure ccsp_DLRInsertCall'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_DLRInsertCall]
		@callout_id int,
		@cam_id smallint,
		@cal_Key varchar(20),
		@cal_Telefono varchar(14),
		@Puerto smallint,
		@logDial_id int=0
		AS

		INSERT ccoCallsOUT ( callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id ) --Status 6=Pide Agente
		  VALUES ( @callout_id, @cam_id, @cal_Key, @cal_Telefono, @Puerto, getdate(), 6 )

		select cast(scope_identity() as int) as cal_id'
	EXEC(@sql);

	SET @process = 'Drop procedure ccsp_IVRInCalls'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_IVRInCalls'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_IVRInCalls
		END'
    EXEC(@sql);

	SET @process = 'CREATE procedure ccsp_IVRInCalls'
    SET @sql = 'CREATE procedure [dbo].[ccsp_IVRInCalls]
		@action tinyint = 0 ,
		@ani varchar(30) = null ,
		@idIvr int = 0 ,
		@option varchar(5)= null ,
		@saveType tinyInt = null,
		@dnis varchar(50) = null,
		@name varchar(50) = null,
		@questionId int = 0,
		@surveyId int = 0,
		@calId int = 0,
		@callout_id int = 0,
		@ttotalIVR int = 0,
		@callType tinyint = null,
		@callbackCamId int =0
		-- saveType 1 es menu 2 es dato
		-- accion 1 siempre @ani  -> @idIvr
		-- accion 2 siempre @idIvr @opcionDigitada -> nada
		AS
		IF @action = 1
		BEGIN
			IF @ani IS NOT NULL
			BEGIN
				INSERT INTO IVRCallsIn(cal_ani,date,dnis,callout_id) values(@ani,getDate(),isnull(@dnis,''''),@callout_id);
				UPDATE ccCallsIn SET cal_whoHung = 2 WHERE cal_id = @callout_id
                Select ''ID''=cast(scope_identity() as int)
			END
		END
		ELSE IF @action = 2
		BEGIN
			IF @option IS NOT NULL AND @idIvr IS NOT NULL
			BEGIN
				INSERT INTO IVROptions(IVR_id,selectedOption,date,saveType,name, questionId, surveyId, cal_id, callType) values (@idIvr,@option,getDate(),@saveType,@name,isnull(@questionId,0),isnull(@surveyId,0),isnull(@calId,0),isnull(@callType,0))
				select 0
			END
			ELSE select -1
		END
		ELSE IF @action = 3
		BEGIN
			UPDATE IVRCallsIn set tincall = @ttotalIVR where IVR_id = @idIvr and callout_id = @callout_id
			if @callout_id > 0
				exec ccsp_EngineLogTransfers 4, @callout_id, 0, 0, null
                UPDATE ccoCallsOut set cal_whoHung = 2 where cal_id = @callout_id
            if @callbackCamId >0  begin
				EXEC [ccsp_KolobUpdateCallback_AbandonIVR] @idIvr, @callbackCamId
	end
		END'
	EXEC(@sql);

	SET @process = 'Drop procedure spInsertCall'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''spInsertCall'')
		BEGIN
			DROP PROCEDURE dbo.spInsertCall
		END'
    EXEC(@sql);

	SET @process = 'CREATE procedure spInsertCall'
    SET @sql = 'CREATE PROCEDURE [dbo].[spInsertCall]
		@Pto smallint,
@DNIS varchar(14),
@ANI as varchar(14),
@inbound_id smallint=0,
@IVR_id int = 0, --Id del IVR
@CALLDATA as varchar(1275) = ''''
AS
DECLARE @dni_id as smallint
DECLARE @cal_id as int
DECLARE @datacall as varchar(100)

SELECT @ANI = LEFT(RTRIM(LTRIM(@ANI)), 13)
SELECT @DNIS = RTRIM(LTRIM(@DNIS))

-- Busca dni_id
SELECT @dni_id = ISNULL((SELECT dni_id FROM ccDNIS WHERE dni_numero = @DNIS AND dni_status = 1), 0)

-- Busca especialidad
IF @inbound_id = 0 AND @dni_id > 0
	SELECT @inbound_id = ED.Inbound_id FROM ccInboundDnis ED WHERE ED.dni_id = @dni_id

INSERT INTO ccCallsIN (cal_ANI, dni_id, cal_puerto, cal_Inicio, inbound_id, IVR_id)
VALUES (@ANI, @dni_id, @Pto, GETDATE(), @inbound_id, @IVR_id)

SELECT @cal_id = SCOPE_IDENTITY()

EXEC ccspSaveDispositionResult @action=1, @callid=@cal_id, @camId=@inbound_id, @callType=0, @statusCallId=1

IF @inbound_id > 0 
BEGIN
	INSERT INTO ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
	SELECT idwg, @cal_id, 0 as user_id, GETDATE(), 0 as tipo FROM ccRIACampEspWG wg   
	WHERE wg.tipo = 0 AND wg.IdCampEsp = @Inbound_id
END

IF @CALLDATA <> ''''  
BEGIN -- Transfer Reminder
	SET @CALLDATA = SUBSTRING(@CALLDATA, 0, LEN(@CALLDATA) - 2)
	INSERT INTO DataCallIn (CallId, Data, Description) 
	SELECT @cal_id, value, ''Dato '' + CAST(id AS VARCHAR(MAX)) FROM dbo.[fn_RIASplitDelimited](@CALLDATA, ''~'')
END

SELECT @cal_id AS IDCall'
	EXEC(@sql);

	SET @process = 'Drop procedure getPrefixByAcdId'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''getPrefixByAcdId'')
		BEGIN
			DROP PROCEDURE dbo.getPrefixByAcdId
		END'
    EXEC(@sql);

	SET @process = 'CREATE procedure getPrefixByAcdId'
    SET @sql = 'CREATE procedure [dbo].[getPrefixByAcdId] 
		@inboundId int, @phone varchar(50) = ''''
AS
DECLARE @prefijo varchar(40), @recordHold bit, @call_record tinyint
DECLARE @countryId tinyint 

SELECT @countryId = valor FROM ccsettings WITH(NOLOCK) WHERE setting_id = 104

SELECT @prefijo = ISNULL(prefijo, ''''), 
		@recordHold = CAST(ISNULL(recordHold, 0) AS bit),  
		@call_record = ISNULL(B.RecordCalls, 1)
FROM ccInbound A
LEFT JOIN ccInboundExtend B ON A.Inbound_id = B.Inbound_id
WHERE A.Inbound_id = @inboundId

SELECT @prefijo AS recordPrefix, 
		@recordHold AS recordHold, 
		dbo.EnableCallRecord(@call_record, @countryId, @phone) AS callRecord'
	EXEC(@sql);


	SET @process = 'Drop procedure ccsp_DLRgetDialPrefix'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_DLRgetDialPrefix'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_DLRgetDialPrefix
		END'
    EXEC(@sql);

	SET @process = 'CREATE procedure ccsp_DLRgetDialPrefix'
    SET @sql = 'CREATE procedure [dbo].[ccsp_DLRgetDialPrefix]
@cam_id smallint=0,
@iPortNumber smallint = 0,
@phone varchar(30) = '''',
@callout_id int = 0
as
declare @prefix as varchar(15), @sipheader varchar(500)
declare @ani as varchar(32)
declare @pais as tinyint 
declare @aniglobal varchar(32), @sipHdrFormat varchar(255)
declare @ivr_script smallint, @surveycamid int
declare @call_record tinyint, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint
declare @PrefixRec varchar(40)
declare @carrier varchar(255)
declare @recordHold bit, @recordIvr bit

select @pais = valor from ccsettings with(nolock) where setting_id = 104
select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

set @prefix =''''
-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

-- Prefijo por campa?a,
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

IF EXISTS (select 1 from ccCampsMsgs where Type = 20 and cam_id = @cam_id)
BEGIN
	select @MsgFiles = @MsgFiles + '',TTS/message.wav''
END
--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000) 
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

select @surveycamid = 0, @ivr_script = 0

select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta = cam_tNoContesta, @ani = case when @ani = '''' then ani else @ani end
,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
,@call_record = dbo.EnableCallRecord(call_record,@pais,@phone), @surveycamid = isnull(surveycamid,0), @recordHold=ISNULL(recordHold,0)
,@recordIvr=ISNULL(recordIvr,0), @PrefixRec = ISNULL(prefijo,'''')
from ccCamps nolock where cam_id = @cam_id

SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)

if @surveycamid > 0
	select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid


if @ani = '''' begin 
set @ani = @aniglobal 
end 

 set @carrier = ''''
 select @carrier = dbo.GetCarrierByTel(@phone)

select @prefix as sDialPrefix, @tNoContesta as tNoContesta,@ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
@call_record as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles, @ivr_script ivrScript, @sipheader data
,@PrefixRec PrefijoRec, @carrier Carrier, @recordHold recordHold, @recordIvr recordIvr
'
    EXEC(@sql);

---------------------------------------------------- END CW-8988 Hugo Longoria --------------------------------------------------------------

--------------------------------------------------- START CW-8987 Hugo Longoria -------------------------------------------------------------
	 SET @process = 'Se crea setting 273'
     SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 273)
		BEGIN
			insert ccsettings2 (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) 
			values (273,''0|5|3'',''Outbound Configuration'',1,''GRL'',''CheckProvider=>0:Any port,1:Cost-effective,2:Cost-effective-only|TimeTxCallsCampInfo|DefaultDialFactorIa'',''Outbound Configuration'',0,''.*'')
		END'
     EXEC(@sql);
	 
	 SET @process = 'KR106000 se agrega columna CancelAttempts en ccoworkingTable'
     SET @sql = 'IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''CancelAttempts'' AND Object_ID = Object_ID(N''dbo.ccoworkingTable''))
		BEGIN
			ALTER TABLE ccoworkingTable ADD CancelAttempts INT NULL;
		END'
     EXEC(@sql);

     SET @process = 'Drop procedure ccsp_OUT_JobsActions'
     SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_OUT_JobsActions'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_OUT_JobsActions
		END'
     EXEC(@sql);

	 SET @process = '--KR106000 se crea sp ccsp_OUT_JobsActions'
	 SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_OUT_JobsActions]
		@Type SMALLINT,
		@callout_id INT = 0,
		@cam_id int = 0
	
		AS
			
		IF (@type = 1) 
		BEGIN
			update ccoWorkingTable set CancelAttempts = isnull(CancelAttempts, 0) + 1 where callout_id = @callout_id		
		END;'
	 EXEC(@sql);

	 SET @process = 'Drop procedure ccsp_OutPhonesInBL'
     SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_OutPhonesInBL'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_OutPhonesInBL
		END'
     EXEC(@sql);

	 SET @process = 'Create procedure ccsp_OutPhonesInBL'
	 SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_OutPhonesInBL]
		@action as tinyint,
		@cam_id as smallint,
		@phones as varchar(max),
		@keys as varchar(max)
		AS
		if @action = 1 begin	
			SELECT phone
				FROM cclistanegra a1 (nolock)
				INNER JOIN camplistanegra a2 WITH (INDEX (IX_Camplistanegra)) ON a1.idtipolista = a2.idtipolista
				JOIN (select p.Value phone, dbo.hashPhone(p.Value) hashPhone,case when len(k.Value) > 0 then dbo.hashList(k.Value) else 0 end hashKey from dbo.fn_RIASplitDelimited(@phones,''|'') p left join  dbo.fn_RIASplitDelimited(@keys,''|'') k on p.Id=k.Id 
				) phones on a1.Hashtel = phones.hashPhone AND (a1.HashKey IS NULL OR a1.HashKey = phones.hashKey)
				WHERE a2.cam_id = @cam_id AND STATUS = 1
		end'
	 EXEC(@sql);

	 SET @process = 'DROP FUNCTION ValidateBlackListPhone'
     SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects 
                    WHERE Name = ''ValidateBlackListPhone'' 
                        AND Type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
        BEGIN
            DROP FUNCTION dbo.ValidateBlackListPhone
        END'
     EXEC(@sql)

	 SET @process = 'Create function ValidateBlackListPhone'
	 SET @sql = 'CREATE FUNCTION [dbo].[ValidateBlackListPhone] (@tel VARCHAR(32), @camId INT, @calKey VARCHAR(20))
		RETURNS BIT
		AS
		BEGIN
			DECLARE @isBlackPhone BIT
			--PARA LA VALIDACION DE LISTAS NEGRAS CON HASH
			DECLARE @hasTelefono BIGINT

			SELECT @hasTelefono = dbo.hashPhone(@tel)

			DECLARE @hasCalKey BIGINT

			IF @calKey IS NOT NULL OR @calKey <> ''''
				SELECT @hasCalKey = dbo.hashList(@calKey)

			SET @isBlackPhone = 0

			IF EXISTS (
					SELECT a2.idtipolista
					FROM cclistanegra a1 (nolock)
					INNER JOIN camplistanegra a2 WITH (INDEX (IX_Camplistanegra)) ON a1.idtipolista = a2.idtipolista
					WHERE a2.cam_id = @camId AND STATUS = 1 AND a1.Hashtel = @hasTelefono AND (a1.HashKey IS NULL OR a1.HashKey = @hasCalKey)
					)
				SET @isBlackPhone = 1

			RETURN @isBlackPhone
		END'
	 EXEC(@sql);

	 SET @process = 'Drop procedure ccspLoadCampsOutbound'
     SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccspLoadCampsOutbound'')
		BEGIN
			DROP PROCEDURE dbo.ccspLoadCampsOutbound
		END'
     EXEC(@sql);

	 SET @process = 'Create procedure ccspLoadCampsOutbound'
	 SET @sql = 'CREATE PROCEDURE [dbo].[ccspLoadCampsOutbound] 
			@action int,  
			@nType INT=0,
			@agentId int=0,
			@campId int=0
		AS
		declare @sql nvarchar(max)

		if @action= 0 begin
			set @sql=''SELECT cc.cam_id
				,cam_descripcion
				,cam_activo
				,cam_ModoManual
				,cam_modpredictivo
				,cam_callratio
				,cam_procesando
				,convert(VARCHAR(8), cast(cam_maxdlrxage AS FLOAT)) cam_maxdlrxage
				,cam_fDialOnWU
				,cam_fDialOnDLG
				,cam_tDialAfterWU
				,cam_tDialBeforeReady
				,cam_tDialAfterDLG
				,compliance
				,progDial
				,excCallBack
				,aggressionFactor
				,listenManualCall
				,tDialOnWrapUp
				,callsbySurvey
				,ivrscript
				,cam_tNoContesta
				,cam_inter_cancelled
				,isnull(CampType,0) as CampType
				,isnull(CamCanceled, 4) as CamCanceled
				,isnull(SimultaneousRecs, 0) as SimultaneousRecs
				FROM ccCamps cc (NOLOCK) left join ccCampsExtend ex (NOLOCK) on ex.cam_id=cc.cam_id WHERE CampType not in (5,7)''
			if @nType=2 
				set @sql=@sql+'' AND cam_bNew = 2 ''
			else if @nType=3
				set @sql=@sql+'' AND cam_bNew in (1,2) ''
			set @sql=@sql+'' ORDER BY cam_descripcion''
			--print(@sql)
			exec (@sql)
		end
		else if @action= 1 begin
			set @sql=''SELECT distinct C.cam_id, C.cam_descripcion, Prioridad, A.Login, A.User_id, Skill
				from ccCamps C (nolock) join ccCampsAgente CA on C.cam_id = CA.cam_id AND CampType not in (5,7)
				join ccUsers A (nolock) on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1 ''
		  if @nType=2 
				set @sql=@sql+'' and C.cam_bNew=2''
			else if @nType=3
				set @sql=@sql+'' and C.cam_bNew in (1,2)''
			if @campId > 0
				set @sql=@sql+'' where C.cam_id = '' + cast(@campId as varchar(5))
			set @sql=@sql+'' order by C.cam_id, CA.Prioridad''
			--print(@sql)
			exec (@sql)
		end
		else if @action= 2 begin
			set @sql=''select distinct A.Login, Prioridad, C.cam_id, Skill
				 from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id AND CampType not in (5,7)
				 join ccUsers A  on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1
				 Where A.User_id = @agentId
				 order by C.cam_id, CA.Prioridad''
			--print(@sql)
			exec sp_executesql @sql, N''@agentId int'', @agentId
		end
		else if @action= 3 begin
			set @sql=''SELECT dialer_id, C.cam_id FROM ccoDialerCamp R (nolock) join ccCamps C (nolock) on R.cam_id=C.cam_id AND CampType not in (5,7) ''
			if @nType=2 
				set @sql=@sql+'' and C.cam_bNew = 2 ''
			else if @nType=3
				set @sql=@sql+'' and C.cam_bNew in (1,2) ''
			if @campId > 0
				set @sql=@sql+'' where C.cam_id = '' + cast(@campId as varchar(5))
			set @sql=@sql+'' ORDER BY cam_descripcion''
			--print(@sql)
			exec (@sql)
		end
		else if @action= 4 begin
			set @sql=''SELECT Login, TipoLLamadas, user_id FROM ccUsers A JOIN ccTipoUsers T on A.TipoUser_id=T.TipoUser_id
						WHERE A.TipoUser_id =1 AND A.Status=1 AND User_id = CASE WHEN @agentId = 0 THEN User_id ELSE @agentId END
						ORDER BY Login''
			exec sp_executesql @sql, N''@agentId int'', @agentId
		end'
	 EXEC(@sql);

	 SET @process = 'KR110001 TABLE CodesInterDialing'
     SET @sql = '
                if not exists(select * from sys.tables where name=''CodesInterDialing'')
                begin
                    create table CodesInterDialing(id int not null identity(1,1), Description varchar (50), ES varchar(max), EN varchar(max), PT varchar(max), Code varchar(25))

                    set identity_insert CodesInterDialing on

                    insert into CodesInterDialing(id, Description, ES, EN, PT)
                    values(1, ''america-code-1'', ''Estados Unidos de América (+1)'', ''United States of America (+1)'', ''Estados Unidos da América (+1)'')
                    ,(2, ''america-code-2'', ''Islas Vírgenes de EE. UU. (+1-340)'', ''Virgin Islands (U.S.) (+1-340)'', ''Ilhas Virgens Americanas (+1-340)'')
                    ,(3, ''america-code-3'', ''Islas Marianas del Norte (+1-670)'', ''Northern Mariana Islands (+1-670)'', ''Ilhas Marianas do Norte (+1-670)'')
                    ,(4, ''america-code-4'', ''Guam (+1-671)'', ''Guam (+1-671)'', ''Guam (+1-671)'')
                    ,(5, ''america-code-5'', ''Samoa Oriental (+1-684)'', ''American Samoa (+1-684)'', ''Samoa Americana  (+1-684)'')
                    ,(6, ''america-code-6'', ''Puerto Rico (+1)'', ''Puerto Rico (+1)'', ''Porto Rico (+1)'')
                    ,(7, ''america-code-7'', ''Canadá (+1)'', ''Canada (+1)'', ''Canadá (+1)'')
                    ,(8, ''america-code-8'', ''Bahamas (+1-242)'', ''Bahamas (+1-242)'', ''Bahamas (+1-242)'')
                    ,(9, ''america-code-9'', ''Barbados (+1-246)'', ''Barbados (+1-246)'', ''Barbados (+1-246)'')
                    ,(10, ''america-code-10'', ''Anguila (+1-264)'', ''Anguilla (+1-264)'', ''Anguila (+1-264)'')
                    ,(11, ''america-code-11'', ''Antigua y Barbuda (+1-268)'', ''Antigua and Barbuda (+1-268)'', ''Antígua e Barbuda (+1-268)'')
                    ,(12, ''america-code-12'', ''Islas Vírgenes Británicas (+1-284)'', ''Virgin Islands (British) (+1-284)'', ''Ilhas Virgens Britânicas (+1-284)'')
                    ,(13, ''america-code-13'', ''Islas Caimán (+1-345)'', ''Cayman Islands (+1-345)'', ''Ilhas Cayman (+1-345)'')
                    ,(14, ''america-code-14'', ''Bermudas (+1-441)'', ''Bermuda (+1-441)'', ''Bermudas (+1-441)'')
                    ,(15, ''america-code-15'', ''Granada (+1-473)'', ''Grenada (+1-473)'', ''Granada (+1-473)'')
                    ,(16, ''america-code-16'', ''Islas Turcas y Caicos (+1-649)'', ''Turks & Caicos (+1-649)'', ''Ilhas Turcos e Caicos (+1-649)'')
                    ,(17, ''america-code-17'', ''Jamaica (+1-876)'', ''Jamaica (+1-876)'', ''Jamaica (+1-876)'')
                    ,(18, ''america-code-18'', ''Montserrat (+1-664)'', ''Montserrat (+1-664)'', ''Montserrat (+1-664)'')
                    ,(19, ''america-code-19'', ''San Martín (zona neerlandesa) (+721)'', ''Sint Maarten (+721)'', ''São Martinho (parte holandesa) (+721)'')
                    ,(20, ''america-code-20'', ''Santa Lucía (+1-758)'', ''St. Lucia (+1-758)'', ''Santa Lúcia (+1-758)'')
                    ,(21, ''america-code-21'', ''Dominica (+1-767)'', ''Dominica (+1-767)'', ''Dominica (+1-767)'')
                    ,(22, ''america-code-22'', ''San Vicente y las Granadinas(+1-784)'', ''St. Vincent and the Grenadines (+1-784)'', ''São Vincente e Granadinas (+1-784)'')
                    ,(23, ''america-code-23'', ''República Dominicana (+1)'', ''Dominican Republic (+1)'', ''República Dominicana (+1)'')
                    ,(24, ''america-code-24'', ''Trinidad y Tobago (+1-868)'', ''Trinidad & Tobago (+1-868)'', ''Trinidad e Tobago (+1-868)'')
                    ,(25, ''america-code-25'', ''San Cristóbal y Nieves (+1-869)'', ''St. Kitts/Nevis (+1-869)'', ''São Cristóvão e Névis (+1-869)'')
                    ,(26, ''america-code-26'', ''Islas Malvinas (+500)'', ''Falkland Islands (+500)'', ''Ilhas Malvinas (+500)'')
                    ,(27, ''america-code-27'', ''Georgia del Sur e Islas Sandwich del Sur (+500)'', ''South Georgia and the South Sandwich Islands (+500)'', ''Ilhas Geórgia do Sul e Sandwich do Sul (+500)'')
                    ,(28, ''america-code-28'', ''Belice (+501)'', ''Belize (+501)'', ''Belize (+501)'')
                    ,(29, ''america-code-29'', ''Guatemala (+502)'', ''Guatemala (+502)'', ''Guatemala (+502)'')
                    ,(30, ''america-code-30'', ''El Salvador (+503)'', ''El Salvador (+503)'', ''El Salvador (+503)'')
                    ,(31, ''america-code-31'', ''Honduras (+504)'', ''Honduras (+504)'', ''Honduras (+504)'')
                    ,(32, ''america-code-32'', ''Nicaragua (+505)'', ''Nicaragua (+505)'', ''Nicarágua (+505)'')
                    ,(33, ''america-code-33'', ''Costa Rica (+506)'', ''Costa Rica (+506)'', ''Costa Rica (+506)'')
                    ,(34, ''america-code-34'', ''Panamá (+507)'', ''Panama (+507)'', ''Panamá (+507)'')
                    ,(35, ''america-code-35'', ''San Pedro y Miquelón (+508)'', ''St. Pierre and Miquelon (+508)'', ''São Pedro e Miquelon (+508)'')
                    ,(36, ''america-code-36'', ''Haití (+509)'', ''Haiti (+509)'', ''Haiti (+509)'')
                    ,(37, ''america-code-37'', ''Perú (+51)'', ''Peru (+51)'', ''Peru (+51)'')
                    ,(38, ''america-code-38'', ''México (+52)'', ''Mexico (+52)'', ''México (+52)'')
                    ,(39, ''america-code-39'', ''Cuba (+53)'', ''Cuba (+53)'', ''Cuba (+53)'')
                    ,(40, ''america-code-40'', ''Argentina (+54)'', ''Argentina (+54)'', ''Argentina (+54)'')
                    ,(41, ''america-code-41'', ''Brasil (+55)'', ''Brazil (+55)'', ''Brasil (+55)'')
                    ,(42, ''america-code-42'', ''Chile (+56)'', ''Chile (+56)'', ''Chile (+56)'')
                    ,(43, ''america-code-43'', ''Colombia (+57)'', ''Colombia (+57)'', ''Colômbia (+57)'')
                    ,(44, ''america-code-44'', ''Venezuela (+58)'', ''Venezuela (+58)'', ''Venezuela (+58)'')
                    ,(45, ''america-code-45'', ''Guadalupe (+590)'', ''Guadeloupe (+590)'', ''Guadalupe (+590)'')
                    ,(46, ''america-code-46'', ''Bolivia (+591)'', ''Bolivia (+591)'', ''Bolívia (+591)'')
                    ,(47, ''america-code-47'', ''Guyana (+592)'', ''Guyana (+592)'', ''Guiana (+592)'')
                    ,(48, ''america-code-48'', ''Ecuador (+593)'', ''Ecuador (+593)'', ''Equador (+593)'')
                    ,(49, ''america-code-49'', ''Guyana Francesa (+594)'', ''French Guiana (+594)'', ''Guiana Francesa (+594)'')
                    ,(50, ''america-code-50'', ''Paraguay (+595)'', ''Paraguay (+595)'', ''Paraguai (+595)'')
                    ,(51, ''america-code-51'', ''Martinica (+596)'', ''Martinique (+596)'', ''Martinica (+596)'')
                    ,(52, ''america-code-52'', ''Surinam (+597)'', ''Suriname (+597)'', ''Suriname (+597)'')
                    ,(53, ''america-code-53'', ''Uruguay (+598)'', ''Uruguay (+598)'', ''Uruguai (+598)'')
                    ,(54, ''america-code-54'', ''Antillas Neerlandesas (+599)'', ''Netherlands Antilles (+599)'', ''Antilhas Holandesas (+599)'')
                    ,(55, ''america-code-55'', ''Bonaire, San Eustaquio y Saba (+599)'', ''Bonaire, Sint Eustatius and Saba (+599)'', ''Bonaire, Santo Eustáquio e Saba(+599)'')
                    ,(56, ''america-code-56'', ''Curazao (+599)'', ''Curaçao (+599)'', ''Curaçao (+599)'')
                    ,(57, ''europa-code-1'', ''Grecia (+30)'', ''Greece (+30)'', ''Grécia (+30)'')
                    ,(58, ''europa-code-2'', ''Países Bajos (+31)'', ''Netherlands (+31)'', ''Países Baixos (+31)'')
                    ,(59, ''europa-code-3'', ''Bélgica (+32)'', ''Belgium (+32)'', ''Bélgica (+32)'')
                    ,(60, ''europa-code-4'', ''Francia (+33)'', ''France (+33)'', ''França (+33)'')
                    ,(61, ''europa-code-5'', ''España (+34)'', ''Spain (+34)'', ''Espanha (+34)'')
                    ,(62, ''europa-code-6'', ''Gibraltar (+350)'', ''Gibraltar (+350)'', ''Gibraltar (+350)'')
                    ,(63, ''europa-code-7'', ''Portugal (+351)'', ''Portugal (+351)'', ''Portugal (+351)'')
                    ,(64, ''europa-code-8'', ''Luxemburgo (+352)'', ''Luxembourg (+352)'', ''Luxemburgo (+352)'')
                    ,(65, ''europa-code-9'', ''Irlanda (+353)'', ''Ireland (+353)'', ''Irlanda (+353)'')
                    ,(66, ''europa-code-10'', ''Islandia (+354)'', ''Iceland (+354)'', ''Islândia (+354)'')
                    ,(67, ''europa-code-11'', ''Albania (+355)'', ''Albania (+355)'', ''Albânia (+355)'')
                    ,(68, ''europa-code-12'', ''Malta (+356)'', ''Malta (+356)'', ''Malta (+356)'')
                    ,(69, ''europa-code-13'', ''Chipre (+357)'', ''Cyprus (+357)'', ''Chipre (+357)'')
                    ,(70, ''europa-code-14'', ''Finlandia (+358)'', ''Finland (+358)'', ''Finlândia (+358)'')
                    ,(71, ''europa-code-15'', ''Bulgaria (+359)'', ''Bulgaria (+359)'', ''Bulgária (+359)'')
                    ,(72, ''europa-code-16'', ''Hungría (+36)'', ''Hungary (+36)'', ''Hungria (+36)'')
                    ,(73, ''europa-code-17'', ''Lituania (+370)'', ''Lithuania (+370)'', ''Lituânia (+370)'')
                    ,(74, ''europa-code-18'', ''Letonia (+371)'', ''Latvia (+371)'', ''Letônia (+371)'')
                    ,(75, ''europa-code-19'', ''Estonia (+372)'', ''Estonia (+372)'', ''Estônia (+372)'')
                    ,(76, ''europa-code-20'', ''Moldavia (+373)'', ''Moldova (+373)'', ''Moldova (+373)'')
                    ,(77, ''europa-code-21'', ''Armenia (+374)'', ''Armenia (+374)'', ''Armênia (+374)'')
                    ,(78, ''europa-code-22'', ''Bielorrusia (+375)'', ''Belarus (+375)'', ''Bielo-Rússia (+375)'')
                    ,(79, ''europa-code-23'', ''Andorra (+376)'', ''Andorra (+376)'', ''Andorra (+376)'')
                    ,(80, ''europa-code-24'', ''Mónaco (+377)'', ''Monaco (+377)'', ''Mônaco (+377)'')
                    ,(81, ''europa-code-25'', ''San Marino (+378)'', ''San Marino (+378)'', ''São Marinho (+378)'')
                    ,(82, ''europa-code-26'', ''Ciudad del Vaticano (+379)'', ''Vatican City (+379)'', ''Cidade do Vaticano (+379)'')
                    ,(83, ''europa-code-27'', ''Ucrania (+380)'', ''Ukraine (+380)'', ''Ucrânia (+380)'')
                    ,(84, ''europa-code-28'', ''Serbia (+381)'', ''Serbia (+381)'', ''Sérvia (+381)'')
                    ,(85, ''europa-code-29'', ''Montenegro (+382)'', ''Montenegro (+382)'', ''Montenegro (+382)'')
                    ,(86, ''europa-code-30'', ''Kosovo (+383)'', ''Kosovo (+383)'', ''Kosovo (+383)'')
                    ,(87, ''europa-code-31'', ''Croacia (+385)'', ''Croatia (+385)'', ''Croácia (+385)'')
                    ,(88, ''europa-code-32'', ''Eslovenia (+386)'', ''Slovenia (+386)'', ''Eslovênia (+386)'')
                    ,(89, ''europa-code-33'', ''Bosnia y Herzegovina (+387)'', ''Bosnia/Herzegovina (+387)'', ''Bósnia e Herzegovina (+387)'')
                    ,(90, ''europa-code-34'', ''Macedonia (+389)'', ''Macedonia (+389)'', ''Macedônia (+389)'')
                    ,(91, ''europa-code-35'', ''Italia (+39)'', ''Italy (+39)'', ''Itália (+39)'')
                    ,(92, ''europa-code-36'', ''Rumania (+40)'', ''Romania (+40)'', ''Romênia (+40)'')
                    ,(93, ''europa-code-37'', ''Suiza (+41)'', ''Switzerland (+41)'', ''Suíça (+41)'')
                    ,(94, ''europa-code-38'', ''República Checa (+420)'', ''Czech Republic (+420)'', ''República Tcheca (+420)'')
                    ,(95, ''europa-code-39'', ''República Eslovaca (+421)'', ''Slovak Republic (+421)'', ''República Eslovaca (+421)'')
                    ,(96, ''europa-code-40'', ''Liechtenstein (+423)'', ''Liechtenstein (+423)'', ''Liechtenstein (+423)'')
                    ,(97, ''europa-code-41'', ''Austria (+43)'', ''Austria (+43)'', ''Áustria (+43)'')
                    ,(98, ''europa-code-42'', ''Reino Unido (+44)'', ''United Kingdom (+44)'', ''Reino Unido (+44)'')
                    ,(99, ''europa-code-43'', ''Guernesey (+44-1481)'', ''Guernsey (+44-1481)'', ''Guernsey (+44-1481)'')
                    ,(100, ''europa-code-44'', ''Bailía de Jersey (+44-1534)'', ''Jersey (+44-1534)'', ''Protetorado de Jersey (+44-1534)'')
                    ,(101, ''europa-code-45'', ''Isla de Man (+44-1624)'', ''Isle of Man (+44-1624)'', ''Ilha de Man (+44-1624)'')
                    ,(102, ''europa-code-46'', ''Dinamarca (+45)'', ''Denmark (+45)'', ''Dinamarca (+45)'')
                    ,(103, ''europa-code-47'', ''Suecia (+46)'', ''Sweden (+46)'', ''Suécia (+46)'')
                    ,(104, ''europa-code-48'', ''Noruega (+47)'', ''Norway (+47)'', ''Noruega (+47)'')
                    ,(105, ''europa-code-49'', ''Islas Svalbard y Jan Mayen(+47)'', ''Svalbard and Jan Mayen (+47)'', ''Ilhas de Svalbard e Jan Mayen(+47)'')
                    ,(106, ''europa-code-50'', ''Polonia (+48)'', ''Poland (+48)'', ''Polônia (+48)'')
                    ,(107, ''europa-code-51'', ''Alemania (+49)'', ''Germany (+49)'', ''Alemanha (+49)'')

                    set identity_insert CodesInterDialing off

                    update CodesInterDialing
                    set Code = SUBSTRING(ES, CHARINDEX(''+'', ES) + 1, CHARINDEX(''+'', REVERSE(ES)) - 2)


                    alter table ccoDialers add DialingType bit not null default 1, IdCode int not null default 0                        
                end'
     EXEC(@sql);

 ---------------------------------------------------- END CW-8987 Hugo Longoria --------------------------------------------------------------

 ---------------------------------------------------- Begin Ulises Espinosa ------------------------------------------------------------------
		
 		SET @process = 'Se ajusta las condiciones para mostrar las campañas de encuesta para asiciar a campañas'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaignsSurvey] 
			@Option AS      INT, 
			@CampType AS    INT = 0,
			@AdminId AS     INT = 0,
			@CampId AS		INT = 0,
			@SurveyCampId   INT = 0,
			@Module AS SMALLINT = 12,
			@HistoryAction AS SMALLINT = 1

			AS
			BEGIN
				DECLARE @idArea SMALLINT = NULL;
				DECLARE @operation INT = -1;
				DECLARE @mediaType INT = 0;

				IF(@Option IN (3, 4)) BEGIN
					IF(@Module <> 12) BEGIN
						IF(@CampType = 0)BEGIN
							SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id = @CampId);
							SET @operation = CASE WHEN @HistoryAction = 1 THEN 
																				CASE 
																						WHEN @mediaType = 1  THEN 63
																						WHEN @mediaType = 5  THEN 40
																						ELSE 60 END
																				ELSE 
																					CASE 
																						WHEN @mediaType = 1  THEN 64
																						WHEN @mediaType = 5  THEN 53
																						ELSE 52 END
																				END;
						END ELSE BEGIN
							SET @mediaType = (SELECT [CampType] FROM ccCamps WHERE cam_id = @CampId);
							SET @operation = CASE WHEN @HistoryAction = 1 THEN 
																				CASE 
																						WHEN @mediaType = 6  THEN 44
																						WHEN @mediaType = 5  THEN 46
																						WHEN @mediaType = 4  THEN 48
																						WHEN @mediaType = 7  THEN 50
																						ELSE 42 END
																				ELSE 
																					CASE 
																						WHEN @mediaType = 6  THEN 55
																						WHEN @mediaType = 5  THEN 56
																						WHEN @mediaType = 4  THEN 57
																						WHEN @mediaType = 7  THEN 58
																						ELSE 54 END
																				END;
						END
					END ELSE BEGIN
						SET @operation = CASE WHEN @Option = 3 THEN 93 ELSE 94 END;
					END
				END

				IF @Option = 1 -- Otption 1 - Get all campaigns
				BEGIN
				IF NOT EXISTS
						(
							SELECT *
							FROM ccUsers_Roles NOLOCK
							WHERE User_id = @AdminId
									AND Rol_id = 7
						)
						BEGIN
							IF @CampType = 1 BEGIN
								WITH wgId
									AS (SELECT IDWG
										FROM ccRIAWorkGroupUsers NOLOCK
										WHERE user_id = @AdminId)
									SELECT DISTINCT 
										CAST(IdCampEsp AS INT) AS CampId,
										cam_descripcion AS Description,
										CAST(isnull(IDArea, -1) AS INT) AS AreaID,
										CAST(CampType AS INT) AS Channel,
										CAST(surveyCamId AS INT) AS SurveyCamId,
										CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
										CAST(1 AS INT) As CampType
									FROM ccRIACampEspWG A
										INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 1
										INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id AND ccc.CampType IN (0,4,6) AND ccc.ivrScript = 0 AND ccc.callsBySurvey = 0
										LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
							END ELSE BEGIN
								WITH wgId
									AS (SELECT IDWG
										FROM ccRIAWorkGroupUsers NOLOCK
										WHERE user_id = @AdminId)
									SELECT DISTINCT 
										CAST(IdCampEsp AS INT) AS CampId,
										descripcion AS Description,
										CAST(isnull(IDArea, -1) AS INT) AS AreaID,
										CAST(chat AS INT) AS Channel,
										CAST(isnull(ccie.SurveyCamId, 0) AS INT) AS SurveyCamId,
										CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
										CAST(0 AS INT) As CampType
									FROM ccRIACampEspWG A
										INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 0
										INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND cci.chat IN (0)
										LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
										LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
									ORDER BY CampId ASC
							END
						END ELSE BEGIN
							IF @CampType = 1 BEGIN
									SELECT DISTINCT 
										CAST(ccc.cam_id AS INT) AS CampId,
										cam_descripcion AS Description,
										CAST(isnull(IDArea, -1) AS INT) AS AreaID,
										CAST(CampType AS INT) AS Channel,
										CAST(surveyCamId AS INT) AS SurveyCamId,
										CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
										CAST(1 AS INT) As CampType
									FROM ccCamps ccc (NOLOCK)
										LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
									WHERE ccc.CampType IN (0,4,6) AND ccc.ivrScript = 0 AND ccc.callsBySurvey = 0
							END ELSE BEGIN
									SELECT DISTINCT 
										CAST(cci.Inbound_id AS INT) AS CampId,
										descripcion AS Description,
										CAST(isnull(IDArea, -1) AS INT) AS AreaID,
										CAST(chat AS INT) AS Channel,
										CAST(isnull(ccie.SurveyCamId, 0) AS INT) AS SurveyCamId,
										CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
										CAST(0 AS INT) As CampType
									FROM ccInbound cci (NOLOCK)
										LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
										LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
									WHERE cci.chat = 0 
									ORDER BY CampId ASC
							END
						END
				END -- Option 1 - Get all campaigns
				IF @Option = 2 BEGIN -- Option 2 - Get all survey camps
					WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS CampId,
								cam_descripcion AS Description,
								CAST(isnull(IDArea, -1) AS INT) AS AreaID,
								CAST(8 AS INT) AS Channel,
								CAST(surveyCamId AS INT) AS SurveyCamId,
								CAST(ccRCG.graphic_id AS INT) As Frame,
								CAST(8 AS INT) As CampType
							FROM ccRIACampEspWG A
								INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 1
								INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id AND ccc.CampType IN (0,8) AND ccc.ivrScript <> 0 AND ccc.callsBySurvey <> 0
								LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
							ORDER BY CampId ASC
				END -- Option 2 - Get all survey camps
				IF(@Option = 3) BEGIN --Option 3 - Associate Survey Campaign to Campaign
					IF(@CampType = 0) BEGIN
						IF EXISTS(SELECT * FROM ccInbound WHERE Inbound_id = @CampId) BEGIN
							IF EXISTS(SELECT * FROM ccInboundExtend WHERE Inbound_id = @CampId) BEGIN
								UPDATE ccInboundExtend SET SurveyCamId = @SurveyCampId WHERE Inbound_id = @CampId;
							END ELSE BEGIN
								INSERT INTO ccInboundExtend (Inbound_id, SurveyCamId)
								VALUES(@CampId, @SurveyCampId);
							END

							IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @CampId)
								
							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
							SELECT
								(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
								getDate(), 
								(SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
								@operation,
								@Module,
								CASE WHEN @Module = 12 THEN '''' ELSE ''ASSOCIATED_CAMP_SURVEY'' END,
								(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [surveyCamId] FROM ccInboundExtend WHERE Inbound_id = @CampId)),
								(SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @CampId)

							SELECT 1 AS Status
						END ELSE BEGIN
							SELECT -1 AS Status
						END
					END 
					ELSE BEGIN
						IF EXISTS(SELECT * FROM ccCamps WHERE cam_id = @CampId) BEGIN
							UPDATE ccCamps SET SurveyCamId = @SurveyCampId WHERE cam_id = @CampId;

							IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @CampId)

							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
							SELECT
								(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
								getDate(), 
								(SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
								@operation,
								@Module,
								CASE WHEN @Module = 12 THEN '''' ELSE ''ASSOCIATED_CAMP_SURVEY'' END,
								(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [surveyCamId] FROM ccCamps WHERE cam_id = @CampId)),
								(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @CampId)
							SELECT 1 AS Status
						END ELSE BEGIN
							SELECT -1 AS Status
						END
					END
				END
				IF(@Option = 4) BEGIN --Option 4 - Disassociate Survey Campaign from Campaign
					IF(@CampType = 0) BEGIN
						IF EXISTS(SELECT * FROM ccInbound WHERE Inbound_id = @CampId) BEGIN
							IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @CampId)

							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
							SELECT
								(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
								getDate(), 
								(SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
								@operation,
								@Module,
								CASE WHEN @Module = 12 THEN '''' ELSE ''DISASSOCIATED_CAMP_SURVEY'' END,
								(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [surveyCamId] FROM ccInboundExtend WHERE Inbound_id = @CampId)),
								(SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @CampId)

							UPDATE ccInboundExtend SET SurveyCamId = 0 WHERE Inbound_id = @CampId;
							SELECT 1 AS Status
						END ELSE BEGIN
							SELECT -2 AS Status
						END			
					END 
					ELSE BEGIN
						IF EXISTS(SELECT * FROM ccCamps WHERE cam_id = @CampId) BEGIN
							IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @CampId)

							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
							SELECT
								(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
								getDate(), 
								(SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
								@operation,
								@Module,
								CASE WHEN @Module = 12 THEN '''' ELSE ''DISASSOCIATED_CAMP_SURVEY'' END,
								(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [surveyCamId] FROM ccCamps WHERE cam_id = @CampId)),
								(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @CampId)

							UPDATE ccCamps SET SurveyCamId = 0 WHERE cam_id = @CampId;
							SELECT 1 AS Status
						END ELSE BEGIN
							SELECT -2 AS Status
						END
					END
				END
			END;'
		EXEC(@sql)

		SET @process = 'Se modifican las campañas de encuesta para que tengan el campType 8'
        SET @sql = 'update ccCamps set CampType = 8 where ivrScript <> 0 and callsBySurvey <> 0'
		EXEC(@sql)
		
 ------------------------------------------------------ End Ulises Espinosa ------------------------------------------------------------------

	SET @process = 'DROP PROCEDURE GetReportMenus'
    SET @sql = '
	if exists (select * from sys.procedures where name = N''GetReportMenus'')
	begin
		DROP PROCEDURE GetReportMenus
	end'
    EXEC(@sql)

    SET @process = 'CREATE PROCEDURE [dbo].[GetReportMenus]'
    SET @sql = 'CREATE PROCEDURE [dbo].[GetReportMenus]
@userId int,
@activeChat tinyint,
@activeAVRS tinyint,
@activeCRM tinyint=0,
@activeEmail tinyint=0,
@activeTwitter tinyint=0
AS
BEGIN

select menu_id,
	substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip)) as menu_descrip,
	nullif(parent,menu_id) as parent,Nivel,ordengral,release
	into #tempCCMenus
	from ccMenus with(nolock)
	where type = 3 and menu_id >= 2000 and(
		(menu_id not in (
		3130,3131,3132,3133,3134,3135,3136,
		8050,8060,8061,8062,8063,8070,8071,8072,8080,
		9000,9010,
		10000,10010,10020,10030,10040,
		11000,11010,11020,11030,11040
		))
		or  (@activeChat = 1 and menu_id in (3130,3131,3132,3133,3134,3135,3136))
		or  (@activeAVRS = 1 and menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080) )
		or  (@activeCRM = 1 and menu_id in (9000,9010) )
		or  (@activeEmail = 1 and menu_id in (10000,10010,10020,10030,10040) )
		or (@activeTwitter = 1 and menu_id in (11000,11010,11020,11030,11040))
		)
		order by menu_id


;WITH ccMenusUserRec(Nivel, menu_descrip, menu_id, ordengral, parent,release)
AS
(
	select
		distinct b.Nivel as Nivel,
		b.menu_descrip as menu_descrip,
		b.menu_id as menu_id,
		b.ordengral as ordengral,
		b.parent as parent,b.release
		from #tempCCMenus as b
		inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId and b.menu_id<>b.parent and a.type = 3
	UNION ALL


--RECURSIViDAD
	select a.Nivel, a.menu_descrip, a.menu_id, a.ordengral, a.parent,a.release
		from #tempCCMenus a inner join ccMenusUserRec b on a.menu_id=b.parent
)

select distinct Nivel,menu_descrip,menu_id,ordengral,parent,release into #tempCCMenusUser from ccMenusUserRec order by ordengral,menu_id

select distinct A.Nivel, A.menu_descrip, A.menu_id, A.ordengral,5 filtersType,A.release,parent from #tempCCMenusUser A
where  menu_id not in
	(select distinct parent from  #tempCCMenus where Nivel=''C'' and parent not in (select distinct  A.parent from  #tempCCMenusUser A where A.Nivel=''C''))
order by ordengral,menu_id

drop table #tempCCMenus
drop table #tempCCMenusUser

END '
    EXEC(@sql)
	-------------------------------------------------BEGIN FRIDA---------------------------------------------------
	SET @process = 'CW-8815 delete sp ccsp_RIAGetAveTimeEspec'
        SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAGetAveTimeEspec'')
		begin
			DROP PROCEDURE ccsp_RIAGetAveTimeEspec;
		end'
		EXEC(@sql)

		SET @process = 'CW-8815 create sp ccsp_RIAGetAveTimeEspec'
        SET @sql = '
CREATE PROCEDURE ccsp_RIAGetAveTimeEspec
	@CveCamp INT,
	@IsKolob BIT = 0
	AS

	declare @fechaI as datetime, @fechaF as datetime
	declare @Dlgs as int
	declare @DlgsAveTime as int
	declare @Que as int
	declare @QueueAveTime as INT
    declare @QueueMaxTime as int
	declare @CallsLost as int
	declare @SL1 as int
	declare @SL2 as int
	declare @answ_tres as smallint
	declare @abnd_tres as smallint

	declare @nanswer as smallint
	declare @nno_answer as smallint
	declare @nlost as smallint
	declare @nabnd as smallint
	declare @ntimeout as smallint
	declare @noverflow as smallint
	declare @nno_agent as smallint
	declare @total as int
	declare @setting as tinyint

	declare @dia as varchar(11)

	declare @tresRing as smallint
	declare @tresDialog as smallint
	declare @tresDelayIn as smallint

	exec @tresRing = ccspConfigTresRing
	exec @tresDialog = ccspConfigTresDialog
	exec @tresDelayIn = ccspConfigtresDelayIn

	--select @dia = ''2003/01/22'' --, @CveCamp=5
	select @dia=CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))

	select @fechaI = convert(datetime, @dia, 101)
	select @fechaF = dateadd( d, 1, @fechaI )
	select @setting = valor from ccsettings where setting_id = 127


	declare @acdType tinyint 

	select @acdType= chat from ccInbound where Inbound_id = @CveCamp

	if @acdType= 0 begin --call
	SELECT 
	@Dlgs = count(case when statuscall_id = 13 then 1 else null end), 
	@DlgsAveTime = ISNULL(sum( case when statuscall_id = 13 then cal_tDialog + cal_tNotas else null end), 0),

	@Que = count(case when cal_que> 0 then 1 else null end), 
	@QueueAveTime = ISNULL(sum( case when cal_que > 0 then cal_tWait else null end), 0),

	@CallsLost= isnull(COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END), 0), -- ODC

	@abnd_tres = COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer IS NULL)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),
	@answ_tres =  case when @setting = 0 then COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END) else Count(case when (statuscall_id = 13 and (cal_twait + cal_txfer + cal_tring<@tresDelayIn)) then 1 else null end) end,

	@SL1 = case when @setting = 0 then @abnd_tres + @answ_tres else @answ_tres end,

	@nanswer = COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),
	@nno_answer = COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),
	@nlost = COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),
	@nabnd = COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer IS NULL))THEN 1 ELSE NULL END),
	@ntimeout = COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),
	@noverflow = COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),
	@nno_agent = COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),
	@total = count(*),

	@SL2 = case when @setting = 0 then @nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent else @total end
	FROM ccCallsIN
	WHERE cal_Inicio between @fechaI AND @fechaF
	AND Inbound_id = @CveCamp

	select 
		''Id''=@CveCamp, 
		''AverageServiceTime''=@DlgsAveTime/ (@Dlgs+1), 
		''AverageWaitingTime''=@QueueAveTime / (@Que +1),
		''ServiceLevel'' = case 
			when @SL2 > 0 
			then 100 * @SL1 / @SL2 
			else 0 end, 
		''ServiceLevel2'' = case 
			when @setting = 0 
			then 
				case 
					when (@nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent) > 0 
					then 100 * (@abnd_tres + @answ_tres) / (@nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent)
					else 0 end 
			else case 
				when @total > 0 
				then 100 * @answ_tres/@total 
				else 0 end end
			,@acdType as Type
	end

	else if @acdType= 1 begin

	declare @CC int,@CCAb int,@ccme int,@ccma int,@cAs int,@cs int,@cAb int,@cDt int,@cDe int
	select @CC=0,@ccme=0,@ccma=0,@cAs=0,@cs=0,@cAb=1,@cDt=0,@cDe=0,@DlgsAveTime=0

	select
	@CC = count(case when chatStatus=4 and tChatting>=@tresDialog then 1 else null end) ,
	@DlgsAveTime = isnull(sum(case when chatStatus=4 then tChatting+tWrapUp else null end),0) ,
	@ccme = count(case when chatStatus=4 and tChatting<=@tresDialog and tChatting <> 0 then 1 else null end),
	@ccma = count(case when chatStatus=4 and tChatting>@tresDialog and tChatting <> 0 then 1 else null end) ,
	@cAs= count(case when chatStatus=3 then 1 else null end) ,
	@cs = count(case when chatStatus=7 then 1 else null end) ,
	@cAb = count(case when chatStatus=9 and tQueue>=@tresDialog then 1 else null end) ,
	@cDt = count(case when chatStatus=11 then 1 else null end) ,
	@cDe = count(case when chatStatus=10 then 1 else null end),
	@Que = count(case when onQueue > 0 then 1 else null end), 
	@QueueAveTime = ISNULL(sum( case when onQueue > 0 then tQueue else null end), 0),
	@QueueMaxTime = ISNULL (MAX (CASE WHEN onQueue    = 1 THEN  tQueue ELSE NULL END), 0),
	@SL2 = @ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe
	from ccRIAChats 
	where requestDate between @fechaI AND @fechaF
	and inboundId=@CveCamp 
	group by inboundId 

	DECLARE @RESULT DECIMAL(18,2);

		IF(@IsKolob = 1)
		BEGIN
			select 
				@CveCamp as ID, 
				isnull(@DlgsAveTime/(@CC + 1),0) as AverageServiceTime, 
				isnull(@QueueAveTime / (@Que + 1),0) as AverageWaitingTime,
				ISNULL(CONVERT(BIGINT,@QueueMaxTime),0) AS MaximumWaitingTime,
				case when @SL2>0 then (@CC)*100/(@SL2) else 0 end as ServiceLevel,
				isnull((@CC)*100/nullif(@ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe,0),0) as ServiceLevel2,
				@acdType as acdType,
				ISNULL(@CC,0) as CC,
				ISNULL(@SL2,0) as SumSL
		END
		ELSE 
		BEGIN
			select 
			@CveCamp as ID, 
			isnull(@DlgsAveTime/(@CC + 1),0) as DlgsAveTime, 
			isnull(@QueueAveTime / (@Que + 1),0) as QueueAveTime,
			case when @SL2>0 then (@CC)*100/(@SL2) else 0 end as SL,
			isnull((@CC)*100/nullif(@ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe,0),0) as Sl2,
			@acdType as acdType,
			ISNULL(@CC,0) as CC,
			ISNULL(@SL2,0) as SumSL
		END
	END'
		EXEC(@sql)
	-----------------------------------------------------------------------------------------------------------
	---------------------------------------------  BEGIN David  ---------------------------------------------------
	SET @process = 'CW-9166 DROP PROCEDURE ccsp_WhatsAppConversationHistory'
    SET @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_WhatsAppConversationHistory'')
    begin
        DROP PROCEDURE ccsp_WhatsAppConversationHistory
    end'
    EXEC(@sql)

	SET @process = 'CW-9166 Se revisa si el mensaje´tiene tipo error al abrir conversación para que no se muetre en historial de agente'
    SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_WhatsAppConversationHistory]
    @Option smallint = null,
    @agentId smallint = null,
    @From datetime = null,
    @To datetime = null,
    @InboundIdsLst varchar(max) = null,
    @OutboundIdsLst varchar(max) = null,
    @ClientNumbersLst varchar(max) = null,   
    @MaxConversationHistory smallint = null,
    @ConversationIndex smallint = null,
    @ConversationId int = null,
    @ConversationIds  varchar(max) = null,
    @CamType bit = null,
    @CamId int = null,
    @ActualTime dateTime = null,
    @CamNumber varchar(max) = null,
    @ClientNumber varchar(max) = null,
    @AgentsIdsLst varchar(max) = null,
    @StatusLst varchar(max) = null

	AS
	BEGIN 
		DECLARE @MaxConversationHistoryTime INT = NULL;   
		DECLARE @MaxDaysPerWAConvo INT = NULL;            
		DECLARE @FinalMaxValue INT = NULL; 
		DECLARE @combinedCampsIn VARCHAR(MAX) = ''''
		DECLARE @combinedCampsOut VARCHAR(MAX) = ''''
		DECLARE @combinedInboundNames VARCHAR(MAX) = ''''
		DECLARE @combinedOutboundNames VARCHAR(MAX) = ''''

	IF @Option = 0 -- Obtiene filtros para agente 
	BEGIN   
		SELECT 
			@combinedCampsIn = ISNULL(STUFF((
				SELECT '','' + CAST(i.inbound_id AS VARCHAR)
				FROM ccInboundAgentes ia
				INNER JOIN ccInbound i ON ia.inbound_id = i.inbound_id
				WHERE ia.user_id = @agentId AND i.chat = 5
				FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), ''''),
        
			@combinedInboundNames = ISNULL(STUFF((
				SELECT '','' + i.descripcion
				FROM ccInboundAgentes ia
				INNER JOIN ccInbound i ON ia.inbound_id = i.inbound_id
				WHERE ia.user_id = @agentId AND i.chat = 5
				FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), '''');

		SELECT 
			@combinedCampsOut = ISNULL(STUFF((
				SELECT '','' + CAST(c.cam_id AS VARCHAR)
				FROM ccCampsAgente ca
				INNER JOIN ccCamps c ON ca.cam_id = c.cam_id
				WHERE ca.user_id = @agentId AND c.CampType = 5
				FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), ''''),
        
			@combinedOutboundNames = ISNULL(STUFF((
				SELECT '','' + c.cam_descripcion
				FROM ccCampsAgente ca
				INNER JOIN ccCamps c ON ca.cam_id = c.cam_id
				WHERE ca.user_id = @agentId AND c.CampType = 5
				FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), '''');

		IF @combinedCampsIn IS NOT NULL AND @combinedCampsIn <> ''''
		BEGIN
			IF OBJECT_ID(''tempdb..#TmpInboundIds'') IS NOT NULL DROP TABLE #TmpInboundIds;
			CREATE TABLE #TmpInboundIds (Id INT);
			INSERT INTO #TmpInboundIds (Id)
			SELECT CAST(value AS INT) 
			FROM dbo.fn_RIASplitDelimited(@combinedCampsIn, '','');
			SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
			FROM ccInbound i
			INNER JOIN #TmpInboundIds tmp ON tmp.Id = i.inbound_id;
			IF OBJECT_ID(''tempdb..#TmpInboundIds'') IS NOT NULL DROP TABLE #TmpInboundIds;
		END

		IF @combinedCampsOut IS NOT NULL AND @combinedCampsOut <> ''''
		BEGIN
			IF OBJECT_ID(''tempdb..#TmpOutboundIds'') IS NOT NULL DROP TABLE #TmpOutboundIds;
			CREATE TABLE #TmpOutboundIds (Id INT);
			INSERT INTO #TmpOutboundIds (Id)
			SELECT CAST(value AS INT) 
			FROM dbo.fn_RIASplitDelimited(@combinedCampsOut, '','');
			SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
			FROM contactMeanOut cmo 
			INNER JOIN #TmpOutboundIds tmp ON tmp.Id = cmo.camp_id;
			IF OBJECT_ID(''tempdb..#TmpOutboundIds'') IS NOT NULL DROP TABLE #TmpOutboundIds;
		END

		SET @FinalMaxValue = 
			CASE 
				WHEN @MaxConversationHistoryTime IS NULL THEN ISNULL(@MaxDaysPerWAConvo, 0)
				WHEN @MaxDaysPerWAConvo IS NULL THEN ISNULL(@MaxConversationHistoryTime, 0)
				ELSE CASE 
					WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
					ELSE @MaxDaysPerWAConvo
				END
			END;

		SELECT 
			ISNULL(@combinedCampsIn, '''') AS InboundIdsLst, 
			ISNULL(@combinedInboundNames, '''') AS InboundNamesLst, 
			ISNULL(@combinedCampsOut, '''') AS OutboundIdsLst, 
			ISNULL(@combinedOutboundNames, '''') AS OutboundNamesLst, 
			ISNULL(CAST(@FinalMaxValue AS SMALLINT), 0) AS MaxConversationHistory;
		END 
	END

	IF @Option = 1 -- Obtiene filtros de campañas para admin
	BEGIN
		DECLARE @campsIn VARCHAR(MAX) = ''''
		DECLARE @InboundNames VARCHAR(MAX) = ''''
		DECLARE @OutboundNames VARCHAR(MAX) = ''''
		DECLARE @campsOut VARCHAR(MAX) = ''''

		DECLARE @ClientIds VARCHAR(MAX) = ''''
		DECLARE @count INT
		DECLARE @id INT
		DECLARE @wg INT

		IF OBJECT_ID(''tempdb..#AgentsRelations'') IS NOT NULL 
			DROP TABLE #AgentsRelations;

		SELECT ROW_NUMBER() OVER(ORDER BY idWG ASC) AS Row,
				IDWG, @campsIn AS campsIn, @campsOut AS campsOut, 
				@InboundNames AS InboundNames, @OutboundNames AS OutboundNames
		INTO #AgentsRelations
		FROM ccRIAAreaWorkGroup wg
		WHERE EXISTS (
			SELECT 1 
			FROM ccRIAWorkGroupUsers wgu 
			WHERE wgu.IDWG = wg.IDWG 
				AND wgu.user_id = @agentId
		);

		SELECT @count = COUNT(idWG) FROM #AgentsRelations;
		SET @id = 1;

		WHILE @id <= @count
		BEGIN
			SELECT @wg = idwg FROM #AgentsRelations WHERE Row = @id;

			SET @campsIn = '''';
			SET @campsOut = '''';
			SET @InboundNames = '''';
			SET @OutboundNames = '''';

			SELECT @campsIn = ISNULL(@campsIn + CASE WHEN @campsIn = '''' THEN '''' ELSE '','' END + CONVERT(VARCHAR(12), inbound_id), @campsIn)
			FROM ccInbound i 
			INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = i.Inbound_id
			WHERE wg.IDWG = @wg AND wg.Tipo = 0 and i.chat = 5
			ORDER BY inbound_id;

			SELECT @campsOut = ISNULL(@campsOut + CASE WHEN @campsOut = '''' THEN '''' ELSE '','' END + CONVERT(VARCHAR(12), cam_id), @campsOut)
			FROM ccCamps c 
			INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = c.cam_id
			WHERE wg.IDWG = @wg AND wg.Tipo = 1 and c.CampType = 5
			ORDER BY cam_id;

			SELECT @InboundNames = ISNULL(@InboundNames + CASE WHEN @InboundNames = '''' THEN '''' ELSE '','' END + i.descripcion, @InboundNames)
			FROM ccInbound i
			WHERE i.Inbound_id IN (
				SELECT inbound_id FROM ccInbound 
				INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = i.Inbound_id
				WHERE wg.IDWG = @wg AND wg.Tipo = 0 and i.chat = 5
			)
			ORDER BY i.Inbound_id;

			SELECT @OutboundNames = ISNULL(@OutboundNames + CASE WHEN @OutboundNames = '''' THEN '''' ELSE '','' END + c.cam_descripcion, @OutboundNames)
			FROM ccCamps c
			WHERE c.cam_id IN (
				SELECT cam_id FROM ccCamps 
				INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = c.cam_id
				WHERE wg.IDWG = @wg AND wg.Tipo = 1 and c.CampType = 5
			)
			ORDER BY c.cam_id;

			IF @campsIn IS NOT NULL AND @campsIn <> ''''
				SET @combinedCampsIn = ISNULL(@combinedCampsIn + CASE WHEN @combinedCampsIn = '''' THEN '''' ELSE '','' END + @campsIn, @combinedCampsIn);

			IF @campsOut IS NOT NULL AND @campsOut <> ''''
				SET @combinedCampsOut = ISNULL(@combinedCampsOut + CASE WHEN @combinedCampsOut = '''' THEN '''' ELSE '','' END + @campsOut, @combinedCampsOut);

			IF @InboundNames IS NOT NULL AND @InboundNames <> ''''
				SET @combinedInboundNames = ISNULL(@combinedInboundNames + CASE WHEN @combinedInboundNames = '''' THEN '''' ELSE '','' END + @InboundNames, @combinedInboundNames);

			IF @OutboundNames IS NOT NULL AND @OutboundNames <> ''''
				SET @combinedOutboundNames = ISNULL(@combinedOutboundNames + CASE WHEN @combinedOutboundNames = '''' THEN '''' ELSE '','' END + @OutboundNames, @combinedOutboundNames);

			SET @id = @id + 1;
		END

		IF @combinedCampsIn IS NOT NULL AND @combinedCampsIn <> ''''
		BEGIN
			IF OBJECT_ID(''tempdb..#TmpInboundIds2'') IS NOT NULL DROP TABLE #TmpInboundIds2;

			CREATE TABLE #TmpInboundIds2 (Id INT);
			INSERT INTO #TmpInboundIds2 (Id)
			SELECT CAST(value AS INT) 
			FROM fn_RIASplitDelimited(@combinedCampsIn, '','');

			SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
			FROM ccInbound i
			INNER JOIN #TmpInboundIds2 tmp ON tmp.Id = i.Inbound_id;

			IF OBJECT_ID(''tempdb..#TmpInboundIds2'') IS NOT NULL DROP TABLE #TmpInboundIds2;
		END

		IF @combinedCampsOut IS NOT NULL AND @combinedCampsOut <> ''''
		BEGIN
			IF OBJECT_ID(''tempdb..#TmpOutboundIds2'') IS NOT NULL DROP TABLE #TmpOutboundIds2;

			CREATE TABLE #TmpOutboundIds2 (Id INT);
			INSERT INTO #TmpOutboundIds2 (Id)
			SELECT CAST(value AS INT) 
			FROM fn_RIASplitDelimited(@combinedCampsOut, '','');

			SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
			FROM contactMeanOut cmo 
			INNER JOIN #TmpOutboundIds2 tmp ON tmp.Id = cmo.camp_id;

			IF OBJECT_ID(''tempdb..#TmpOutboundIds2'') IS NOT NULL DROP TABLE #TmpOutboundIds2;
		END

		SET @FinalMaxValue = CASE 
			WHEN @MaxConversationHistoryTime IS NULL THEN @MaxDaysPerWAConvo
			WHEN @MaxDaysPerWAConvo IS NULL THEN @MaxConversationHistoryTime
			ELSE CASE 
				WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
				ELSE @MaxDaysPerWAConvo
			END
		END;

		SELECT 
			@combinedCampsIn AS InboundIdsLst, 
			@combinedInboundNames AS InboundNamesLst, 
			@combinedCampsOut AS OutboundIdsLst, 
			@combinedOutboundNames AS OutboundNamesLst, 
			ISNULL(CAST(@FinalMaxValue AS SMALLINT), 0) AS MaxConversationHistory;

		IF OBJECT_ID(''tempdb..#AgentsRelations'') IS NOT NULL 
			DROP TABLE #AgentsRelations;
		END

	IF @Option = 2 -- Obtiene agentes tomando en cuenta filtros de Inbound, Outbound, o Client Numbers
	BEGIN
		DECLARE @AgentIds VARCHAR(MAX) = '''';
		DECLARE @AgentLogins VARCHAR(MAX) = '''';
		DECLARE @AgentNames VARCHAR(MAX) = '''';
		DECLARE @AgentStatusList VARCHAR(MAX) = '''';
		DECLARE @CampType SMALLINT = 0;
		IF OBJECT_ID(''tempdb..#TmpCampAgentWg'') IS NOT NULL DROP TABLE #TmpCampAgentWg;
		CREATE TABLE #TmpCampAgentWg (Id INT);

		IF @InboundIdsLst IS NOT NULL AND @InboundIdsLst <> ''''
		BEGIN
			INSERT INTO #TmpCampAgentWg (Id)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
		END

		IF @OutboundIdsLst IS NOT NULL AND @OutboundIdsLst <> ''''
		BEGIN
			INSERT INTO #TmpCampAgentWg (Id)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
			SET @CampType = 1;
		END

		IF @ClientNumbersLst IS NOT NULL AND @ClientNumbersLst <> ''''
		BEGIN
			INSERT INTO #TmpCampAgentWg (Id)
			SELECT DISTINCT inboundId
			FROM ccWhatsAppConversations
			WHERE clientId IN (SELECT CAST(value AS BIGINT) FROM fn_RIASplitDelimited(@ClientNumbersLst, '',''));

			INSERT INTO #TmpCampAgentWg (Id)
			SELECT DISTINCT camId
			FROM ccWhatsAppConversationsOut
			WHERE clientId IN (SELECT CAST(value AS BIGINT) FROM fn_RIASplitDelimited(@ClientNumbersLst, '',''));
		END

		;WITH LatestStatus AS (
			SELECT 
				lad.User_id, 
				lad.currentStatus, 
				lad.fecha,
				ROW_NUMBER() OVER (PARTITION BY lad.User_id ORDER BY lad.fecha DESC) AS RowNum
			FROM ccLogAgentesDia lad
		)
		SELECT 
			@AgentIds = ISNULL(@AgentIds + CASE WHEN @AgentIds = '''' THEN '''' ELSE '','' END + CAST(u.User_id AS VARCHAR), ''''),
			@AgentLogins = ISNULL(@AgentLogins + CASE WHEN @AgentLogins = '''' THEN '''' ELSE '','' END + u.Login, ''''),
			@AgentNames = ISNULL(@AgentNames + CASE WHEN @AgentNames = '''' THEN '''' ELSE '','' END + u.Nombres + '' '' + u.ApellidoPaterno + '' '' + ISNULL(u.ApellidoMaterno, ''''), ''''),
			@AgentStatusList = ISNULL(@AgentStatusList + CASE WHEN @AgentStatusList = '''' THEN '''' ELSE '','' END + 
							   ISNULL(CASE WHEN ts.descripcion = ''Disponible'' THEN ''Ready'' ELSE ts.descripcion END, ''Unknown''), '''')
		FROM ccUsers u
		INNER JOIN ccRIAWorkGroupUsers wgu ON u.User_id = wgu.User_id
		INNER JOIN ccRIACampEspWG wg ON wg.IDWG = wgu.IDWG
		LEFT JOIN LatestStatus ls ON u.User_id = ls.User_id AND ls.RowNum = 1
		LEFT JOIN ccTipoStatusAgente ts ON ls.currentStatus = ts.TipoStatusAge_id
		WHERE wg.IdCampEsp IN (SELECT Id FROM #TmpCampAgentWg)
		  AND u.TipoUser_id = 1 
		  AND wg.Tipo = (CASE 
							WHEN ((@InboundIdsLst IS NULL OR @InboundIdsLst = '''') AND (@OutboundIdsLst IS NULL OR @OutboundIdsLst = '''') AND (ISNULL(@ClientNumbersLst, '''') <> ''''))
							THEN wg.Tipo
							ELSE @CampType
						END)
		GROUP BY u.User_id, u.Login, u.Nombres, u.ApellidoPaterno, u.ApellidoMaterno, ts.descripcion;

		SELECT @AgentIds AS AgentIdsList, @AgentLogins AS AgentLoginsList, @AgentNames AS AgentNamesList, @AgentStatusList AS AgentStatusList;

		IF OBJECT_ID(''tempdb..#TmpCampAgentWg'') IS NOT NULL DROP TABLE #TmpCampAgentWg;
	END
	DECLARE @PageSize INT = 10;
	DECLARE @TotalConversations INT = 0;
	DECLARE @Offset INT;

	IF @Option = 3 -- Obtiene paginado de conversaciones de acuerdo a filtros seleccionados para agente 
	BEGIN 
		DECLARE @ClientNumberTable TABLE (ClientNumber BIGINT);
		DECLARE @InboundIdTable TABLE (InboundId INT);
		DECLARE @OutboundIdTable TABLE (OutboundId INT);
    
		IF @ClientNumbersLst IS NOT NULL AND @ClientNumbersLst <> ''''
		BEGIN
			INSERT INTO @ClientNumberTable (ClientNumber)
			SELECT CAST(value AS BIGINT)
			FROM fn_RIASplitDelimited(@ClientNumbersLst, '','');
		END

		IF @InboundIdsLst IS NOT NULL AND @InboundIdsLst <> ''''
		BEGIN
			INSERT INTO @InboundIdTable (InboundId)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
		END

		IF @OutboundIdsLst IS NOT NULL AND @OutboundIdsLst <> ''''
		BEGIN
			INSERT INTO @OutboundIdTable (OutboundId)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
		END

		SELECT 
			@TotalConversations = COUNT(DISTINCT ConversationId)
		FROM (
			SELECT c.ConversationId 
			FROM ccWhatsAppConversations c
			LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
			WHERE c.AgentId = @agentId 
				AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
				AND c.requestDate BETWEEN @From AND @To
				AND m.content IS NOT NULL
				AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
				AND (@InboundIdsLst IS NULL OR c.InboundId IN (SELECT InboundId FROM @InboundIdTable))  
				AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)

			UNION ALL

		SELECT c.ConversationId 
		FROM ccWhatsAppConversationsOut c
		LEFT JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
		WHERE c.AgentId = @agentId 
			AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
			AND c.requestDate BETWEEN @From AND @To
			AND m.content IS NOT NULL
			AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
			AND (@OutboundIdsLst IS NULL OR c.camId IN (SELECT OutboundId FROM @OutboundIdTable))
			AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19) 
			AND NOT (
				c.conversationStatus = 18
				AND EXISTS (  
					SELECT 1 
					FROM ccWAMessagesConversationsOut mo 
					WHERE mo.conversationId = c.ConversationId 
					GROUP BY mo.conversationId 
					HAVING COUNT(*) = 1 AND MAX(mo.messageStatus) = ''error''
				)
			)
		) AS AllConversations;

		SET @Offset = (@ConversationIndex - 1); 

		DECLARE @RemainingConversations INT = @TotalConversations - @Offset;
		IF @RemainingConversations < @PageSize
			SET @PageSize = @RemainingConversations;

		IF @Offset >= @TotalConversations
		BEGIN
			SELECT TOP 0
				CAST(0 AS INT) AS ConversationId,
				CAST(0 AS INT) AS CamId,
				'''' AS CamNumber,
				CAST(0 AS SMALLINT) AS Frame,
				'''' AS ClientNumber,
				'''' AS MessageContent,
				'''' AS CamType,
				CAST(GETDATE() AS DATETIME) AS LastMessageDateTime,
				@TotalConversations AS ConversationsCount
			WHERE 1 = 0;
			RETURN;
		END

		;WITH LatestInboundMessages AS (
			SELECT 
				c.ConversationId,
				c.InboundId AS CampaignId,
				ci.descripcion AS CamName,
				c.phoneACD as CamNumber,
				g.graphic_id AS GraphicId,
				c.clientId AS ClientNumber,
				m.content AS MessageContent,
				m.typeMessage AS MessageType,
				m.TimeStampMessage AS LastMessageTimestamp,
				''Inbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn    
			FROM ccWhatsAppConversations c
			LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = c.InboundId
			LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
			LEFT JOIN ccinbound ci ON ci.inbound_id = c.inboundid
			WHERE c.AgentId = @agentId 
				AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
				AND c.requestDate BETWEEN @From AND @To
				AND m.content IS NOT NULL
				AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
				AND (@InboundIdsLst IS NULL OR c.InboundId IN (SELECT InboundId FROM @InboundIdTable))
				AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)
		),
    
		LatestOutboundMessages AS (
			SELECT 
				c.ConversationId,
				c.camId AS CampaignId,
				ca.cam_descripcion AS CamName,
				c.phoneCamp AS CamNumber,
				g.graphic_id AS GraphicId,
				c.clientId AS ClientNumber,
				m.content AS MessageContent,
				m.typeMessage AS MessageType,
				m.TimeStampMessage AS LastMessageTimestamp,
				''Outbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn  
			FROM ccWhatsAppConversationsOut c
			LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
			LEFT JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
			LEFT JOIN ccCamps ca ON ca.cam_Id = c.camid
			WHERE c.AgentId = @agentId 
				AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
				AND c.requestDate BETWEEN @From AND @To
				AND m.content IS NOT NULL
				AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
				AND (@OutboundIdsLst IS NULL OR c.camId IN (SELECT OutboundId FROM @OutboundIdTable))
				AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)
		),

		CombinedMessages AS (
			SELECT 
				ConversationId,
				CampaignId,
				CamNumber,
				CamName,
				GraphicId,
				ClientNumber,
				MessageContent,
				MessageType,
				LastMessageTimestamp,
				CampType
			FROM LatestInboundMessages
			WHERE rn = 1
        
			UNION ALL
        
			SELECT 
				ConversationId,
				CampaignId,
				CamNumber,
				CamName,
				GraphicId,
				ClientNumber,
				MessageContent,
				MessageType,
				LastMessageTimestamp,
				CampType
			FROM LatestOutboundMessages
			WHERE rn = 1
		)

		SELECT conversationId AS ConversationId,
			   CampaignId AS CamId,
			   CamNumber AS CamNumber,
			   CamName AS CamName,
			   CAST(GraphicId AS SMALLINT) AS Frame,
			   ClientNumber AS ClientNumber,
			   MessageContent AS MessageContent,
			   MessageType AS MessageType,
			   CampType AS CamType,
			   LastMessageTimestamp AS LastMessageDateTime,
			   @TotalConversations AS ConversationsCount
		FROM CombinedMessages
		ORDER BY LastMessageTimestamp DESC
		OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
	END;

	IF @Option = 4 -- Obtiene paginado de conversaciones de acuerdo a filtros seleccionados para administrador
	BEGIN
		-- Drop and recreate temporary tables
		IF OBJECT_ID(''tempdb..#ClientNumberTable'') IS NOT NULL DROP TABLE #ClientNumberTable;
		CREATE TABLE #ClientNumberTable (ClientNumber BIGINT);

		IF OBJECT_ID(''tempdb..#InboundIdTable'') IS NOT NULL DROP TABLE #InboundIdTable;
		CREATE TABLE #InboundIdTable (InboundId INT);

		IF OBJECT_ID(''tempdb..#OutboundIdTable'') IS NOT NULL DROP TABLE #OutboundIdTable;
		CREATE TABLE #OutboundIdTable (OutboundId INT);

		IF OBJECT_ID(''tempdb..#AgentIdTable'') IS NOT NULL DROP TABLE #AgentIdTable;
		CREATE TABLE #AgentIdTable (AgentId INT);

		IF OBJECT_ID(''tempdb..#StatusTable'') IS NOT NULL DROP TABLE #StatusTable;
		CREATE TABLE #StatusTable (StatusCategory VARCHAR(50));

		IF OBJECT_ID(''tempdb..#StatusIdTable'') IS NOT NULL DROP TABLE #StatusIdTable;
		CREATE TABLE #StatusIdTable (StatusId INT);

		DECLARE @IncludeQueued BIT = 0;

		-- Populate temporary tables based on input parameters
		IF ISNULL(@ClientNumbersLst, '''') <> ''''
		BEGIN
			INSERT INTO #ClientNumberTable (ClientNumber)
			SELECT CAST(value AS BIGINT)
			FROM fn_RIASplitDelimited(@ClientNumbersLst, '','');
		END

		IF ISNULL(@InboundIdsLst, '''') <> ''''
		BEGIN
			INSERT INTO #InboundIdTable (InboundId)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
		END

		IF ISNULL(@OutboundIdsLst, '''') <> ''''
		BEGIN
			INSERT INTO #OutboundIdTable (OutboundId)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
		END

		IF ISNULL(@AgentsIdsLst, '''') <> ''''
		BEGIN
			INSERT INTO #AgentIdTable (AgentId)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@AgentsIdsLst, '','');
		END

		IF ISNULL(@StatusLst, '''') <> ''''
		BEGIN
			INSERT INTO #StatusTable (StatusCategory)
			SELECT LTRIM(RTRIM(value))
			FROM fn_RIASplitDelimited(@StatusLst, '','');
		END

		-- Map status categories to internal Status IDs
		INSERT INTO #StatusIdTable (StatusId)
		SELECT StatusId
		FROM (
			SELECT CASE 
				WHEN StatusCategory = ''active'' THEN messageStatusId
				WHEN StatusCategory = ''pre-assigned'' THEN 21
				WHEN StatusCategory = ''finished'' THEN messageStatusId
				ELSE NULL
			END AS StatusId
			FROM messageStatus
			INNER JOIN #StatusTable ON
				(StatusCategory = ''active'' AND messageStatusId IN (1, 2, 3, 5, 7, 8, 9))
				OR (StatusCategory = ''pre-assigned'' AND messageStatusId = 21)
				OR (StatusCategory = ''finished'' AND messageStatusId IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19))
		) AS MappedStatus
		WHERE StatusId IS NOT NULL;

		IF EXISTS (SELECT 1 FROM #StatusTable WHERE StatusCategory = ''queued'')
		BEGIN
			SET @IncludeQueued = 1;
		END

		-- Calculate total conversations based on filters for Inbound, Outbound, or Client-only cases

		-- Case 1: Inbound Conversations
		IF @InboundIdsLst IS NOT NULL 
		BEGIN
			WITH ConversationsWithMessages AS (
				-- Retrieve all conversations with messages
				SELECT DISTINCT c.ConversationId
				FROM ccWhatsAppConversations c
				INNER JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
				WHERE c.InboundId IN (SELECT InboundId FROM #InboundIdTable)
					AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
					AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
					AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
					OR (@IncludeQueued = 1 AND c.onQueue = 1))
			),
			LinkedConversations AS (
				-- Include conversations linked to ones with messages
				SELECT DISTINCT r.conversationIdAfter AS ConversationId
				FROM ccWhatsAppConversationsRelationship r
				INNER JOIN ConversationsWithMessages cm ON r.conversationIdBefore = cm.ConversationId
			)
			SELECT 
				@TotalConversations = COUNT(DISTINCT c.ConversationId)
			FROM ccWhatsAppConversations c
			WHERE c.ConversationId IN (
				-- Combine conversations with messages and linked conversations
				SELECT ConversationId FROM ConversationsWithMessages
				UNION
				SELECT ConversationId FROM LinkedConversations
			)
			AND c.InboundId IN (SELECT InboundId FROM #InboundIdTable)
			AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
			AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
			AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
			OR (@IncludeQueued = 1 AND c.onQueue = 1));
		END

		-- Case 2: Outbound Conversations
		ELSE IF @OutboundIdsLst IS NOT NULL
		BEGIN
			SELECT  
				@TotalConversations = COUNT(DISTINCT c.ConversationId)
			FROM ccWhatsAppConversationsOut c
			INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
			WHERE c.camId IN (SELECT OutboundId FROM #OutboundIdTable)
				AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND c.onQueue = 1))
		END

		-- Case 3: ClientNumbers only (when both Inbound and Outbound IDs are NULL)
		ELSE IF @ClientNumbersLst IS NOT NULL AND @TotalConversations = 0
		BEGIN
			DECLARE @InboundConversations INT = 0;
			DECLARE @OutboundConversations INT = 0;

			-- Count inbound conversations
			SELECT  
				@InboundConversations = COUNT(DISTINCT whatsIn.ConversationId)
			FROM ccWhatsAppConversations whatsIn
			INNER JOIN ccWAMessagesConversations m ON m.conversationId = whatsIn.ConversationId
			WHERE whatsIn.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatsIn.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR whatsIn.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND whatsIn.onQueue = 1));

			-- Count outbound conversations
			SELECT  
				@OutboundConversations = COUNT(DISTINCT whatOut.ConversationId)
			FROM ccWhatsAppConversationsOut whatOut
			INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = whatOut.ConversationId
			WHERE whatOut.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatOut.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR whatOut.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND whatOut.onQueue = 1));

			-- Sum the inbound and outbound counts
			SET @TotalConversations = @InboundConversations + @OutboundConversations;
		END

		-- Paginate results based on @ConversationIndex
		SET @Offset = ISNULL(@ConversationIndex, 1) - 1;

		IF @ConversationIndex >= @TotalConversations
		BEGIN
			SET @Offset = @TotalConversations - @PageSize;
			IF @Offset < 0 SET @Offset = 0;
		END

		-- Collect unique conversation IDs from Inbound and Outbound messages
		;WITH ExistingConversations AS (
			SELECT ConversationId FROM ccWhatsAppConversations WHERE InboundId IN (SELECT InboundId FROM #InboundIdTable)
			UNION
			SELECT ConversationId FROM ccWhatsAppConversationsOut WHERE camId IN (SELECT OutboundId FROM #OutboundIdTable)
		),
		-- Retrieve paginated conversations for Inbound, Outbound, or Client-only case

		LatestInboundMessages AS (
			SELECT 
				c.ConversationId,
				c.InboundId AS CampaignId,
				COALESCE(g.graphic_id, 0) AS GraphicId,
				COALESCE(c.clientId, '''') AS ClientNumber,
				COALESCE(m.content, '''') AS MessageContent,
				COALESCE(m.typeMessage, '''') AS MessageType,
				COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
				COALESCE(u.Login, '''') AS AgentLogin,
				CASE 
					WHEN c.onQueue = 1 AND c.conversationStatus = 8 THEN ''queued''
					WHEN c.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
					WHEN c.conversationStatus = 21 THEN ''pre-assigned''
					ELSE ''finished''
				END AS ConversationStatus,
				''Inbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
			FROM ccWhatsAppConversations c
			LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
			LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = c.InboundId
			LEFT JOIN ccUsers u ON u.User_id = c.AgentId
			WHERE 
				c.InboundId IN (SELECT InboundId FROM #InboundIdTable)
				AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND c.onQueue = 1))
		),
    
		LatestOutboundMessages AS (
			SELECT 
				c.ConversationId,
				c.camId AS CampaignId,
				COALESCE(g.graphic_id, 0) AS GraphicId,
				COALESCE(c.clientId, '''') AS ClientNumber,
				COALESCE(m.content, '''') AS MessageContent,
				COALESCE(m.typeMessage, '''') AS MessageType,
				COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
				COALESCE(u.Login, '''') AS AgentLogin,
				CASE 
					WHEN c.onQueue = 1 AND c.conversationStatus = 8 THEN ''queued''
					WHEN c.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
					WHEN c.conversationStatus = 21 THEN ''pre-assigned''
					ELSE ''finished''
				END AS ConversationStatus,
				''Outbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
			FROM ccWhatsAppConversationsOut c
			INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
			LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
			LEFT JOIN ccUsers u ON u.User_id = c.AgentId
			WHERE 
				c.camId IN (SELECT OutboundId FROM #OutboundIdTable)
				AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND c.onQueue = 1))
		),
    
		ClientOnlyMessages AS (
			-- Exclude conversations that already exist in ExistingConversations
			SELECT 
				whatsIn.ConversationId,
				whatsIn.InboundId AS CampaignId,
				COALESCE(g.graphic_id, 0) AS GraphicId,
				COALESCE(whatsIn.clientId, '''') AS ClientNumber,
				COALESCE(m.content, '''') AS MessageContent,
				COALESCE(m.typeMessage, '''') AS MessageType,
				COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
				COALESCE(u.Login, '''') AS AgentLogin,
				CASE 
					WHEN whatsIn.onQueue = 1 AND whatsIn.conversationStatus = 8 THEN ''queued''
					WHEN whatsIn.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
					WHEN whatsIn.conversationStatus = 21 THEN ''pre-assigned''
					ELSE ''finished''
				END AS ConversationStatus,
				''Inbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY whatsIn.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
			FROM ccWhatsAppConversations whatsIn
			INNER JOIN ccWAMessagesConversations m ON m.conversationId = whatsIn.ConversationId
			LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = whatsIn.InboundId
			LEFT JOIN ccUsers u ON u.User_id = whatsIn.AgentId
			WHERE 
				whatsIn.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatsIn.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR whatsIn.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND whatsIn.onQueue = 1))
				AND whatsIn.ConversationId NOT IN (SELECT ConversationId FROM ExistingConversations)

			UNION ALL

			SELECT 
				whatOut.ConversationId,
				whatOut.camId AS CampaignId,
				COALESCE(g.graphic_id, 0) AS GraphicId,
				COALESCE(whatOut.clientId, '''') AS ClientNumber,
				COALESCE(m.content, '''') AS MessageContent,
				COALESCE(m.typeMessage, '''') AS MessageType,
				COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
				COALESCE(u.Login, '''') AS AgentLogin,
				CASE 
					WHEN whatOut.onQueue = 1 AND whatOut.conversationStatus = 8 THEN ''queued''
					WHEN whatOut.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
					WHEN whatOut.conversationStatus = 21 THEN ''pre-assigned''
					ELSE ''finished''
				END AS ConversationStatus,
				''Outbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY whatOut.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
			FROM ccWhatsAppConversationsOut whatOut
			INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = whatOut.ConversationId
			LEFT JOIN ccRIACampsGraph g ON g.cam_id = whatOut.camId
			LEFT JOIN ccUsers u ON u.User_id = whatOut.AgentId
			WHERE 
				whatOut.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatOut.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR whatOut.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND whatOut.onQueue = 1))
				AND whatOut.ConversationId NOT IN (SELECT ConversationId FROM ExistingConversations)
		)

		-- Final result
		SELECT 
			CAST(ConversationId AS INT) AS ConversationId,
			CAST(CampaignId AS SMALLINT) AS CamId,
			CAST(GraphicId AS SMALLINT) AS Frame,
			CAST(ClientNumber AS VARCHAR(50)) AS ClientNumber,
			CAST(MessageContent AS VARCHAR(MAX)) AS MessageContent,
			CAST(MessageType AS VARCHAR(MAX)) AS MessageType, 
			CAST(LastMessageTimestamp AS DATETIME) AS LastMessageDateTime,
			CAST(AgentLogin AS VARCHAR(50)) AS AgentLogin,
			CAST(ConversationStatus AS VARCHAR(50)) AS ConversationStatus,
			CAST(CampType AS VARCHAR(50)) AS CamType,
			CAST(@TotalConversations AS INT) AS ConversationsCount
		FROM (
			SELECT * FROM LatestInboundMessages WHERE rn = 1
			UNION ALL
			SELECT * FROM LatestOutboundMessages WHERE rn = 1
			UNION ALL
			SELECT * FROM ClientOnlyMessages WHERE rn = 1
		) AS CombinedMessages
		ORDER BY ConversationId DESC
		OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
	END;
	
	IF @Option = 5 -- Obtiene número máximo de días a buscar por historial cuando se filtra por campañas 
	BEGIN 											
		IF OBJECT_ID(''tempdb..#TmpInboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpInboundIdsCampFilter;

		CREATE TABLE #TmpInboundIdsCampFilter (Id INT);

		INSERT INTO #TmpInboundIdsCampFilter (Id)
		SELECT CAST(value AS INT) 
		FROM fn_RIASplitDelimited(@InboundIdsLst, '','');

		SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
		FROM ccInbound i
		INNER JOIN #TmpInboundIdsCampFilter tmp ON tmp.Id = i.Inbound_id;

		IF OBJECT_ID(''tempdb..#TmpInboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpInboundIdsCampFilter;

		IF OBJECT_ID(''tempdb..#TmpOutboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpOutboundIdsCampFilter;

		CREATE TABLE #TmpOutboundIdsCampFilter (Id INT);

		INSERT INTO #TmpOutboundIdsCampFilter (Id)
		SELECT CAST(value AS INT) 
		FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');

		SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
		FROM contactMeanOut cmo 
		INNER JOIN #TmpOutboundIdsCampFilter tmp ON tmp.Id = cmo.camp_id;

		IF OBJECT_ID(''tempdb..#TmpOutboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpOutboundIdsCampFilter;

		SET @FinalMaxValue = CASE 
			WHEN @MaxConversationHistoryTime IS NULL THEN @MaxDaysPerWAConvo
			WHEN @MaxDaysPerWAConvo IS NULL THEN @MaxConversationHistoryTime
			ELSE CASE 
				WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
				ELSE @MaxDaysPerWAConvo
			END
		END;

		 SELECT CAST(@FinalMaxValue AS SMALLINT) AS MaxConversationHistory;
	END;

	IF @Option = 6 -- Obtener cabecera de varias conversaciones
	BEGIN 
		CREATE TABLE #TmpConversationIds (Id INT);
		INSERT INTO #TmpConversationIds (Id)
		SELECT CAST(value AS INT) 
		FROM fn_RIASplitDelimited(@ConversationIds, '','');

		IF @CamType = 0
		BEGIN 
			SELECT 
				cwc.conversationId AS ConversationId, 
				(CASE WHEN cwc.disposition = 0 THEN ''N/A'' ELSE ctc.Description END) AS Disposition,
				(CASE WHEN cwc.SubDisposition = 0 THEN ''N/A'' ELSE ctcs.califSubDesc END) AS SubDisposition, 
				cwc.inboundId AS CamId, 
				ISNULL(cwc.conversationDate, ''1900-01-01'') AS ConversationDate,
				(CASE 
					WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1)
						OR cwc.conversationStatus IN (1, 2, 3, 5, 7, 8, 9, 21)
						OR cwc.tConversation IS NULL THEN 0
					ELSE cwc.tConversation
				END) AS TConversation,
				0 AS CampType,
				ci.descripcion AS CampName,
				cwc.clientId AS PhoneNumber,
				(CASE 
					WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1) 
						OR cwc.conversationStatus IN (10, 17) 
						OR cu.User_id IS NULL THEN CONVERT(SMALLINT, 0)
					ELSE cu.User_id
				END) AS AgentId,
				(CASE 
					WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1) 
						OR cwc.conversationStatus IN (10, 17) 
						OR cu.User_id IS NULL THEN ''''
					ELSE cu.Nombres
				END) AS AgentName,
				ISNULL(CAST(mwn.Cam_Id AS SMALLINT), 0) AS ReopenWithTemplateOutboundCamId,
				ccc.cam_descripcion AS ReopenWithTemplateOutboundCamName
			FROM ccWhatsAppConversations cwc
			INNER JOIN ccInbound ci ON ci.inbound_id = cwc.inboundId
			LEFT JOIN ccUsers cu ON cu.User_id = cwc.agentId
			INNER JOIN #TmpConversationIds tci ON tci.Id = cwc.conversationId
			LEFT JOIN ccTipoCalif ctc ON ctc.calif_id = cwc.disposition
			LEFT JOIN ccTipoCalifSub ctcs ON ctcs.califSub_id = cwc.subDisposition
			LEFT JOIN ccMetaWhatsAppNumbers mwn ON mwn.Number = cwc.phoneACD
			LEFT JOIN cccamps ccc ON ccc.cam_Id = mwn.Cam_Id 
		END
		ELSE
		BEGIN
			SELECT 
				cwo.conversationId AS ConversationId, 
				(CASE WHEN cwo.disposition = 0 THEN ''N/A'' ELSE ctco.Description END) AS Disposition, 
				(CASE WHEN cwo.SubDisposition = 0 THEN ''N/A'' ELSE ctcso.califSubDesc END) AS SubDisposition,
				cwo.camId AS CamId, 
				ISNULL(cwo.conversationDate, ''1900-01-01'') AS ConversationDate, 
				(CASE 
					WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1)
						OR cwo.conversationStatus IN (1, 2, 3, 5, 7, 8, 9, 21)
						OR cwo.tConversation IS NULL THEN 0
					ELSE cwo.tConversation
				END) AS TConversation,
				1 AS CampType,
				cc.cam_descripcion AS CampName,
				cwo.clientId AS PhoneNumber,
				(CASE 
					WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1) 
						OR cwo.conversationStatus IN (10, 17) 
						OR cu.User_id IS NULL THEN CONVERT(SMALLINT, 0)
					ELSE cu.User_id
				END) AS AgentId,
				(CASE 
					WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1) 
						OR cwo.conversationStatus IN (10, 17) 
						OR cu.User_id IS NULL THEN ''''
					ELSE cu.Nombres
				END) AS AgentName,
				ISNULL(CAST(ccc.Cam_Id AS SMALLINT), 0) AS ReopenWithTemplateOutboundCamId,
				ccc.cam_descripcion AS ReopenWithTemplateOutboundCamName
			FROM ccWhatsAppConversationsOut cwo
			INNER JOIN ccCamps cc ON cc.cam_id = cwo.camId 
			LEFT JOIN ccUsers cu ON cu.User_id = cwo.agentId
			INNER JOIN #TmpConversationIds tci ON tci.Id = cwo.conversationId
			LEFT JOIN ccTipoCalifOUT ctco ON ctco.calif_id = cwo.disposition
			LEFT JOIN ccTipoCalifSubOUT ctcso ON ctcso.califSub_id = cwo.subDisposition
			LEFT JOIN ccMetaWhatsAppNumbers mwn ON mwn.Number = cwo.phoneCamp
			LEFT JOIN ccCamps ccc on ccc.cam_id = mwn.Cam_Id 
		END
	END

		DECLARE @MaxWhatsAllowed INT;
		DECLARE @ConversationCount INT;

	IF @Option = 8 -- Obtiene valor si se reabrirá o no la conversación y si será se reabrirá tipo entrada o salida
	BEGIN 
		IF NOT EXISTS (SELECT 1 FROM ccRIAAgentsPermissions WHERE AgentId = @AgentId AND AllowReopenWAConversation = 1)
		BEGIN
			SELECT ''REOPEN_PERMISSION_DISABLED'' AS ReopenConversationResponse;
			RETURN(0);
		END;

		IF @CamType = 0
		BEGIN
			IF EXISTS (SELECT 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent)) 
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM ccmetawhatsAppNumbers WHERE Number = @CamNumber AND Inbound_Id = @CamId)
				BEGIN
					SELECT ''CAMPAIGN_NUMBER_CHANGED'' AS ReopenConversationResponse;
					RETURN(0);
				END

				SELECT @MaxWhatsAllowed = a.maxWhats FROM ccinbound i INNER JOIN ccriacat_Areas a ON i.IDArea = a.IDArea WHERE i.Inbound_Id = @CamId;
				SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversations WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(HOUR, -24, GETDATE());

				IF @ConversationCount >= @MaxWhatsAllowed
				BEGIN
					SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationResponse;
					RETURN(0);
				END
				SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
				RETURN(0);
			END
			ELSE 
			BEGIN
				SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
				RETURN(0);
			END
		END

		IF @CamType = 1
		BEGIN
			IF EXISTS (SELECT 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent)) 
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM ccmetawhatsAppNumbers WHERE Number = @CamNumber AND Cam_Id = @CamId)  
				BEGIN
					SELECT ''CAMPAIGN_NUMBER_CHANGED'' AS ReopenConversationResponse;
					RETURN(0);
				END

				SELECT @MaxWhatsAllowed = a.maxWhatsOut FROM cccamps c INNER JOIN ccriacat_Areas a ON c.IDArea = a.IDArea WHERE c.cam_id = @CamId;
				SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversationsOut WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(HOUR, -24, GETDATE());

				IF @ConversationCount >= @MaxWhatsAllowed
				BEGIN
					SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationResponse;
					RETURN(0);
				END
				SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
				RETURN(0);
			END
			ELSE 
			BEGIN
				SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
				RETURN(0);
			END
		END
	END

		DECLARE @ConvId int;

	IF @Option = 9 -- Verificación al reabrir conversación
	BEGIN 
		DECLARE @ConversationWithinWindowTime BIT = 0;
		DECLARE @ReopenConversationButtonResponse VARCHAR(50);
		DECLARE @AgentName varchar(50);
		DECLARE @TimeThreshold DATETIME;
		SET @TimeThreshold = DATEADD(hour, -23, GETDATE());


		IF EXISTS (SELECT 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent))
		BEGIN  
			SET @ReopenConversationButtonResponse = ''REOPEN_CONVERSATION'';
		END
		ELSE 
		BEGIN 
			SET @ReopenConversationButtonResponse = ''REOPEN_CONVERSATION_WITH_TEMPLATE'';
		END

		IF @CamType = 0
		BEGIN
			IF EXISTS (SELECT 1 FROM ccWhatsAppConversations WHERE InboundId = @CamId AND phoneACD = @CamNumber AND clientId = @ClientNumber AND conversationStatus = 2 AND (agentId = @agentId OR agentId <> @agentId))
			BEGIN
				SELECT TOP 1 @ConvId = ConversationId FROM ccWhatsAppConversations WHERE InboundId = @CamId  AND phoneACD = @CamNumber  AND clientId = @ClientNumber  AND conversationStatus = 2  AND (agentId = @agentId OR agentId <> @agentId);
				SELECT @AgentName = u.Nombres FROM ccWhatsAppConversations c
												INNER JOIN ccusers u ON c.agentId = u.User_id 
												WHERE c.ConversationId = @ConvId;
				SELECT ''ONGOING_CONVERSATION'' AS ReopenConversationButtonResponse,
									@AgentName AS AgentName;
				RETURN(0);
			END

			SELECT @MaxWhatsAllowed = a.maxWhats FROM ccinbound i INNER JOIN ccriacat_Areas a ON i.IDArea = a.IDArea WHERE i.Inbound_Id = @CamId;
			SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversations WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(hour, -24, GETDATE());

			IF @ConversationCount >= @MaxWhatsAllowed
			BEGIN
				SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationButtonResponse;
				RETURN(0);
			END

			IF @ReopenConversationButtonResponse = ''REOPEN_CONVERSATION_WITH_TEMPLATE''
			BEGIN
				IF EXISTS (SELECT 1 FROM ccoWhatsLogDials WITH (NOLOCK, INDEX(IX_TimeSpam_PhoneClient_PhoneWa)) WHERE TimeSpam >= @TimeThreshold AND PhoneWa = @CamNumber AND PhoneClient = @ClientNumber AND answered = 0)
				BEGIN
					SELECT ''CONVERSATION_SENT_IN_BULK_IN_COURSE'' AS ReopenConversationButtonResponse,
									   ''N/A'' AS AgentName;
					RETURN(0);
				END
			END

			SELECT @ReopenConversationButtonResponse AS ReopenConversationButtonResponse, ''N/A'' AS AgentName;
			RETURN(0);
		END

		IF @CamType = 1
		BEGIN
			IF EXISTS (SELECT 1 FROM ccWhatsAppConversationsOut WHERE camId = @CamId AND phoneCamp = @CamNumber AND clientId = @ClientNumber AND conversationStatus = 2 AND (agentId = @agentId OR agentId <> @agentId))
			BEGIN
				SELECT TOP 1 @ConvId = ConversationId FROM ccWhatsAppConversationsOut WHERE camId = @CamId  AND phoneCamp = @CamNumber  AND clientId = @ClientNumber  AND conversationStatus = 2  AND (agentId = @agentId OR agentId <> @agentId);
				SELECT @AgentName = u.Nombres FROM ccWhatsAppConversationsOut c
											  INNER JOIN ccusers u ON c.agentId = u.User_id 
											  WHERE c.ConversationId = @ConvId;
				SELECT ''ONGOING_CONVERSATION'' AS ReopenConversationButtonResponse,
								   @AgentName AS AgentName;
				RETURN(0);
			END

			IF EXISTS (SELECT 1 FROM ccoWhatsLogDials WITH (NOLOCK, INDEX(IX_TimeSpam_PhoneClient_PhoneWa)) WHERE TimeSpam >= @TimeThreshold AND PhoneWa = @CamNumber AND PhoneClient = @ClientNumber AND answered = 0)
			BEGIN
				SELECT ''CONVERSATION_SENT_IN_BULK_IN_COURSE'' AS ReopenConversationButtonResponse,
				''N/A'' AS AgentName;
				RETURN(0);
			END

			SELECT @MaxWhatsAllowed = a.maxWhatsOut FROM cccamps c INNER JOIN ccriacat_Areas a ON c.IDArea = a.IDArea WHERE c.cam_id = @CamId;
			SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversationsOut WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(hour, -24, GETDATE());

			IF @ConversationCount >= @MaxWhatsAllowed
			BEGIN
				SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationButtonResponse;
				RETURN(0);
			END

			SELECT @ReopenConversationButtonResponse AS ReopenConversationButtonResponse, ''N/A'' AS AgentName;
			RETURN(0);
		END
	END 

	IF @Option = 10 -- Creación de conversationId de entrada 
	BEGIN 
		EXEC ccsp_ConversationWASave @action=1, @phoneacd=@CamNumber, @clientid= @ClientNumber, @inboundid=@CamId, @agentId = @agentId, @IsReopenedConversation = 1, @conversationstatus=2

	END 

	IF @Option = 11 -- Creación de conversationId de salida
	BEGIN
		EXEC ccsp_ConversationOutWASave @action=1, @phoneCamp=@CamNumber, @clientid= @ClientNumber, @campId=@CamId, @agentId = @agentId, @conversationstatus=2
	END'
    EXEC(@sql)

	SET @process = 'CW-9242 DROP PROCEDURE ccsp_GalateaAreas'
    SET @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_GalateaAreas'')
    begin
        DROP PROCEDURE ccsp_GalateaAreas
    end'
    EXEC(@sql)

    SET @process = 'CW-9242 Se crea tabla temporal #CCAreasTable para insertar los registros que se insertarán en el log de actividad'
    SET @sql = '
		CREATE procedure [dbo].[ccsp_GalateaAreas] 
        @option int = 2,
        @IDArea smallint = 0,
        @Descripcion varchar(40) = NULL,
        @maxMails smallint = 3,
        @maxChats smallint = 3,
        @maxTweets smallint = 3,
        @maxWhats smallint = 3,
        @maxWhatsOut smallint = 3,
        @callWhileChat bit = 0,
        @callWhileEmail bit = 0,
        @callWhileTwitter bit = 0,
        @CallWhileWhatsAppIn bit = 0,
        @CallWhileWhatsAppOut bit = 0,
        @defCampaing smallint = 0,
        @movesfromArea bit = 0,
        @userId int = NULL,
        @groupAreas varchar (MAX) = NULL,
        @toolsTransfer tinyint = NULL 
    AS

    SET NOCOUNT ON;
    
        declare @opt int = @option -1
    
        DECLARE @userLogin as varchar(40);
        SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @userId);

        if @option = 1 --Superuser info
        begin
            create table #campsIds(
                id int,
                cadena varchar(max)
            )
            
            declare @sql varchar(max),@idPivots varchar(max),@idConcat varchar(max)
            
            set @idPivots =''''
            set @idConcat=''''
            
            select @idPivots=@idPivots+Id+'','',
                @idConcat=@idConcat+''case when ''+id+'' is not null then convert(varchar(max),''+ id+'') + '''','''' else '''''''' end + 
                ''
                from (
                select distinct ''[''+convert(varchar(max),cam_id)+'']'' as Id from ccCamps   
                )x
            
            set @idPivots =SUBSTRING(@idPivots,0,len(@idPivots))
            set @idConcat =SUBSTRING(@idConcat,0,len(@idConcat)-7)
            
            set @sql=''
                select IDArea,''+@idConcat+'' from 
                (   select IDArea, cam_id from ccCamps) as T
                PIVOT (
                max(cam_id) for cam_id in (''+@idPivots+'') ) as P''

            insert into #campsIds
            exec(@sql)
            
            select a.IDArea Id, 
                a.AreaName Name, 
                a.StatusArea Status, 
                a.maxMails Mails, 
                a.maxChats Chats, 
                a.maxTweets Tweets, 
                a.maxWhats Whats,
                a.maxWhatsOut WhatsOut,
                a.callWhileChat callChat,
                a.callWhileEmail callEmail,
                a.CallWhileWhatsAppIn callWhatsIn,
                a.CallWhileWhatsAppOut callWhatsOut,
                a.CreateDate as CreateDate,         
                ISNULL(b.cadena, 0) as CampaignIds  
            from ccRIACat_Areas a --Falta el datetime 
            left join #campsIds b on a.IDArea = b.id

            drop table #campsIds
        end
        if @option = 2 -- Select de las areas
        begin
            IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
            Create table #Areas(
                IDArea smallint,
                AreaName varchar(MAX),
                maxChats tinyint ,
                maxMails tinyint ,
                maxWhats tinyint ,
                maxWhatsOut tinyint ,
                callWhileChat bit, 
                callWhileEmail bit,
                CallWhileWhatsAppIn bit,
                CallWhileWhatsAppOut bit,
                users int,
                admins int,
                camps int,
                acds int,
                maxTweets tinyint,
                toolsTransfer tinyint
            )
            insert into #Areas
            EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@maxWhats=@maxWhats,@maxWhatsOut=@maxWhatsOut,@callWhileChat=@callWhileChat,@callWhileEmail=@callWhileEmail,@callWhileWhatsAppIn=@callWhileWhatsAppIn,@callWhileWhatsAppOut=@callWhileWhatsAppOut,@defCampaing=@defCampaing, @isKolob=1
            select a.*,rca.CreateDate,Isnull(rca.defCampaing,0) as defCampaing
            from #Areas a
            inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea

            IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
        end
        if @option = 3 -- Insert new area
        begin
        IF OBJECT_ID(''tempdb..#InsertAreas'') IS NOT NULL DROP TABLE #InsertAreas;
            Create table #InsertAreas(
                result int,
                idAreas decimal
            )
            insert into #InsertAreas
            EXEC ccsp_RIA_ABCAreas 
                @option = @opt,
                @IDArea=@IDArea,
                @Descripcion=@Descripcion,
                @maxMails=@maxMails,
                @maxChats=@maxChats,
                @maxTweets=@maxTweets,
                @maxWhats=@maxWhats,
                @maxWhatsOut=@maxWhatsOut,
                @callWhileChat=@callWhileChat,
                @callWhileEmail=@callWhileEmail,
                @callWhileWhatsAppIn=@callWhileWhatsAppIn,
                @callWhileWhatsAppOut=@callWhileWhatsAppOut,
                @defCampaing=@defCampaing,
                @toolsTransfer=@toolsTransfer
            if (select result from #InsertAreas) = 1
                begin

                    --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD AL CREAR UN AREA
                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@Descripcion, getDate(), @userLogin, 17, 3, '''', '''', @Descripcion);

                    if(@movesfromArea = 1) begin
                        Update ccUsers set IDArea = (select idAreas from #InsertAreas), status = 1 where User_id = @userId
                    end
                end
            Select * from #InsertAreas
        end
        if @option = 4 -- Delete Areas
        begin
            IF OBJECT_ID(''tempdb..#AreasDelete'') IS NOT NULL DROP TABLE #AreasDelete;
            SELECT value As IDArea into #AreasDelete FROM fn_RIASplitDelimited(@groupAreas, '','')
        
        
            if (exists(select IDArea from ccUsers where IDArea=(Select top 1 IDArea from #AreasDelete)) or exists(select IDArea from ccCamps where IDArea = (Select top 1 IDArea from #AreasDelete))
              or exists(select IDArea from ccInbound where IDArea=(Select top 1 IDArea from #AreasDelete))) and (select valor from ccSettings where setting_id=95)<>1
            BEGIN
                Select -1 as result
            END
            ELSE
            BEGIN
                declare @DWorkGroups as varchar(500)
                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
                select user_id,cam_id,prioridad,skill,rel_id,IDWG
                from ccCampsAgente
                where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
                select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
                from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))
                Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
                select user_id,cam_id,tipo,IDWG,monitored
                from ccSupervisorCam
                where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
                delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
                delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
                where cam_id in (select cam_id from ccCamps where IDArea in (Select IDArea from #AreasDelete)))

                Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))
                Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))

                Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
                Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
                Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))

                select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)
                Delete from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)

                if (select valor from ccSettings where setting_id=95)=1
                begin
                Update ccInbound set IDArea=NULL, status=0 where IDArea in (Select IDArea from #AreasDelete)
                Update ccCamps set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
                Update ccUsers set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
                end

                Update ccRIACat_Areas set StatusArea=0 where IDArea in (Select IDArea from #AreasDelete)

                --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA AREA ELIMINADA
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                SELECT AreaName, getDate(), @userLogin, 19, 3, '''', '''', AreaName
                FROM ccRIACat_Areas 
                WHERE IDArea in (Select IDArea from #AreasDelete);

                select 1 as result
            END --  exec ccsp_GalateaAreas @option=5,@IDArea=1,@Descripcion=NULL,@maxMails=NULL,@maxChats=NULL,@maxWhats=NULL,@maxWhatsOut=NULL,@callWhileChat=1,@callWhileEmail=1,@callWhileWhatsAppIn=0,@callWhileWhatsAppOut=0,@defCampaing=NULL,@movesfromArea=0,@userId=17,@toolsTransfer=3;
        end
        if @option = 5 -- update Areas       
        begin
            if exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion and IDArea <> @IDArea)
                begin
                    select -1 as result
                    return
                end
            else
                begin

                    --INICIO - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

                    DECLARE @PrevDescription AS VARCHAR(50);
                    DECLARE @SelectedArea AS VARCHAR(10) = CAST(@IDArea AS varchar(10));

                    SELECT @PrevDescription = AreaName
                    FROM ccRIACat_Areas 
                    WHERE IDArea = @IDArea;

                    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

						CREATE TABLE #CCAreasTable 
					(
						columnInfo VARCHAR(255),
						dataInfo VARCHAR(255),
						identifierInfo VARCHAR(255)
					);  

                    update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),maxWhats=isnull(@maxWhats,maxWhats),maxWhatsOut=isnull(@maxWhatsOut,maxWhatsOut),callWhileChat=isnull(@callWhileChat,callWhileChat),callWhileEmail=isnull(@callWhileEmail,callWhileEmail),callWhileWhatsAppIn=isnull(@callWhileWhatsAppIn,callWhileWhatsAppIn),callWhileWhatsAppOut=isnull(@callWhileWhatsAppOut,callWhileWhatsAppOut),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=case when @toolsTransfer = 3 then ToolsTransfer else @toolsTransfer end where IDArea=@IDArea

                   EXEC InsertLogAdminGalatea @action=2, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId, @tableTemp=''#CCAreasTable'';

                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                    SELECT 
                        CASE WHEN AT.identifierInfo IS NOT NULL THEN
                            CASE 
                                WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                        ELSE '''' END,
                        getDate(), 
                        @userLogin, 
                        18, 
                        3, 
                        AT.identifierInfo,
                        CASE WHEN AT.identifierInfo IS NOT NULL THEN
                            CASE 
                                WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @Descripcion
                                WHEN AT.identifierInfo = ''T&SET_CAMPAIGN'' THEN 
                                    CASE 
                                        WHEN @defCampaing IS NOT NULL AND @defCampaing <> 0 THEN
                                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @defCampaing)
                                        ELSE ''T&COMMON_NONE'' END
                                WHEN AT.identifierInfo = ''T&SET_TOOLSTRANSFER'' THEN
                                    CASE
                                        WHEN @toolsTransfer = 1 THEN ''COMMON_ENABLED''
                                        ELSE ''COMMON_DISABLED'' END
                                when at.identifierInfo = ''T&SET_CALL_WHILE_CHAT'' then 
                                    case 
                                        when @callWhileChat = 1 then ''COMMON_ENABLED''
                                        else ''COMMON_DISABLED'' end
                                when at.identifierInfo = ''T&SET_CALL_WHILE_EMAIL'' then 
                                    case 
                                        when @callWhileEmail = 1 then ''COMMON_ENABLED''
                                            else ''COMMON_DISABLED'' end
                when at.identifierInfo = ''T&SET_CALL_WHILE_WHATSAPP_IN'' then 
                        case 
                        when @CallWhileWhatsAppIn = 1 then ''COMMON_ENABLED''
                            else ''COMMON_DISABLED'' end
                when at.identifierInfo = ''T&SET_CALL_WHILE_WHATSAPP_OUT'' then 
                    case 
                    when @CallWhileWhatsAppOut= 1 then ''COMMON_ENABLED''
                        else ''COMMON_DISABLED'' end

                                ELSE AT.dataInfo END
                        ELSE '''' END, 
                        CASE WHEN AT.identifierInfo IS NOT NULL THEN
                            CASE 
                                WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                        ELSE '''' END
                    FROM #CCAreasTable AS AT;

                    EXEC InsertLogAdminGalatea @action=3, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

					IF OBJECT_ID(N''tempdb..#CCUsersTable'') IS NOT NULL DROP TABLE #CCUsersTable

                    --FIN - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

                end
            if @maxChats is not null
                begin
                    Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
                end
            if @movesfromArea = 1
            Begin
                Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @userId
            End
            select 1 as result
        END
        IF @option = 6 -- get configAreaMultimedia by userId
        BEGIN
            SELECT 
            crca.callWhileChat
            , crca.callWhileEmail
            , crca.CallWhileWhatsAppIn
            , crca.CallWhileWhatsAppOut
            FROM  
            dbo.ccRIAWorkGroupUsers AS crwgu INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg 
            ON crawg.IDWG = crwgu.IDWG INNER JOIN dbo.ccRIACat_Areas AS crca 
            ON crca.IDArea = crawg.IDArea WHERE crwgu.User_id = @userId 
            GROUP BY crca.IDArea, crca.callWhileChat, crca.callWhileEmail, crca.CallWhileWhatsAppIn, crca.CallWhileWhatsAppOut

            RETURN (0)
        END
        IF(@option = 7) -- get area campaign relation by areaId
        BEGIN
            SELECT crcew.IdCampEsp, crawg.IDArea FROM dbo.ccRIACampEspWG AS crcew 
                                    INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg
                                    ON crawg.IDWG = crcew.IDWG
                                    WHERE crcew.Tipo = 1 AND crawg.IDArea = @idArea
            RETURN (0)
        END
        
    SET NOCOUNT ON;'
    EXEC(@sql)


	SET @process = 'CW-9242 DROP PROCEDURE InsertLogAdminGalatea'
    SET @sql = '
    if exists (select * from sys.procedures where name = N''InsertLogAdminGalatea'')
    begin
        DROP PROCEDURE InsertLogAdminGalatea
    end'
    EXEC(@sql)

    SET @process = 'CW-9242 Se quita reinserción de registros innecesarios en tabla para evitar duplicidad de registros en historial de actividad'
    SET @sql = '
	CREATE PROCEDURE [dbo].[InsertLogAdminGalatea]
    @action INT,
    @tableName VARCHAR(255),
    @columnNameId VARCHAR(255),
    @valueId VARCHAR(255),
    @userId INT,
    @tableTemp VARCHAR(255) = NULL
	AS
	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX);
	DECLARE @tableNameTmp VARCHAR(255) = ''##'' + @tableName + ''_'' + CONVERT(VARCHAR(10), @userId);

	IF @action = 1
	BEGIN
		SET @sql = ''IF OBJECT_ID(N''''tempdb..'' + @tableNameTmp + '''''') IS NOT NULL DROP TABLE '' + @tableNameTmp + '';
					SELECT * INTO '' + @tableNameTmp + '' FROM '' + @tableName + '' WHERE '' + @columnNameId + '' = '' + @valueId;
		EXEC(@sql);
	END
	ELSE IF @action = 2
	BEGIN
		DECLARE @columns NVARCHAR(MAX) = '''';
		DECLARE @conditions NVARCHAR(MAX) = '''';
		DECLARE @caseStatements NVARCHAR(MAX) = '''';
		DECLARE @batchSize INT = 10;
		DECLARE @counter INT = 0;
		DECLARE @emtpy VARCHAR(2) = '''';

		DECLARE @BatchColumns TABLE (
			name NVARCHAR(128),
			batch_id INT
		);

		INSERT INTO @BatchColumns (name, batch_id)
		SELECT 
			name,
			(ROW_NUMBER() OVER (ORDER BY column_id) - 1) / @batchSize AS batch_id
		FROM sys.columns
		WHERE object_id = OBJECT_ID(@tableName)
		  AND name <> @columnNameId
		  AND name <> ''rowguid'';

		DECLARE @BatchIds TABLE (
			batch_id INT PRIMARY KEY
		);

		INSERT INTO @BatchIds
		SELECT DISTINCT batch_id FROM @BatchColumns;

		DECLARE @batch_id INT = 0;

		WHILE EXISTS (SELECT 1 FROM @BatchIds WHERE batch_id = @batch_id)
		BEGIN
			SET @caseStatements = '''';
			SET @conditions = '''';

			SELECT @caseStatements = @caseStatements + 
				''SELECT '''''' + name + '''''' AS columnInfo, CONVERT(VARCHAR(300), A.'' + QUOTENAME(name) + '') AS dataInfo '' +
				''FROM '' + @tableName + '' AS A '' +
				''FULL OUTER JOIN '' + @tableNameTmp + '' AS B ON A.'' + QUOTENAME(@columnNameId) + '' = B.'' + QUOTENAME(@columnNameId) + '' '' +
				''WHERE A.'' + QUOTENAME(name) + '' <> B.'' + QUOTENAME(name) + '' UNION ALL ''
			FROM @BatchColumns
			WHERE batch_id = @batch_id;

			SET @caseStatements = LEFT(@caseStatements, LEN(@caseStatements) - LEN('' UNION ALL ''));
        
			IF @caseStatements <> ''''
			BEGIN
				SET @sql = ''INSERT INTO '' + @tableTemp + '' (columnInfo, dataInfo)
							'' + @caseStatements;
				EXEC sp_executesql @sql;
			END

			SET @batch_id = @batch_id + 1;
		END

		SET @sql = ''
		IF OBJECT_ID(''''tempdb..#Temp2'''') IS NOT NULL DROP TABLE #Temp2;

		SELECT DISTINCT A.columnInfo, A.dataInfo, ISNULL(B.Identifiers, '''''' + @emtpy + '''''') AS identifierInfo
		INTO #Temp2
		FROM '' + @tableTemp + '' A
		LEFT JOIN relationTableColumnIdentifiers B
		  ON A.columnInfo = B.colunName
		 AND B.tableName = '''''' + @tableName + '''''';

		TRUNCATE TABLE '' + @tableTemp + '';

		INSERT INTO '' + @tableTemp + '' (columnInfo, dataInfo, identifierInfo)
		SELECT columnInfo, dataInfo, identifierInfo FROM #Temp2;

		DROP TABLE #Temp2;
		'';
		EXEC sp_executesql @sql, N''@emtpy VARCHAR(2)'', @emtpy = @emtpy;
	END
	ELSE IF @action = 3
	BEGIN
		SET @sql = ''IF OBJECT_ID(N''''tempdb..'' + @tableNameTmp + '''''') IS NOT NULL DROP TABLE '' + @tableNameTmp;
		EXEC(@sql);
	END'
    EXEC(@sql)
	-----------------------------------------------  END David  ---------------------------------------------------
	---------------------------------------------------------------------------------------------------------------

	-------------------------------------------  BEGIN Isaac  ----------------------------------------

	SET @process = 'TT14496-Outbound-Inicio lento DROP PROCEDURE ccsp_CampHorario'
		SET @sql = '
		IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N''ccsp_CampHorario'')
		BEGIN
			DROP PROCEDURE ccsp_CampHorario;
		END'
		EXEC(@sql)

		SET @process = 'TT14496-Outbound-Inicio lento CREATE PROCEDURE ccsp_CampHorario'
		SET @sql = '
CREATE PROCEDURE ccsp_CampHorario
@campId as int=null
AS
declare @horaUniversal datetime
declare @isShudulerLey bit, @valueShudulerLey varchar(max),@hourStart int,@hourEnd int,@minStart int,@minEnd int
declare @shourStart varchar(max),@shourEnd varchar(max),@revHorario bit
select @revHorario=valor from ccsettings where setting_id = 112
select @valueShudulerLey = valor from ccsettings where setting_id=166
select @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)) as int),@valueShudulerLey=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
if @valueShudulerLey='''' begin
 set @valueShudulerLey=''0|07:00|22:00''
 update ccsettings set valor=@valueShudulerLey where setting_id=166
end
if @isShudulerLey = 1 begin
 select @shourStart=substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)),@shourEnd=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
 select @hourStart=substring(@shourStart, 0, charindex('':'',@shourStart)),@minStart=substring(@shourStart, charindex('':'',@shourStart) + 1, len(@shourStart))
 select @hourEnd=substring(@shourEnd, 0, charindex('':'',@shourEnd)),@minEnd=substring(@shourEnd, charindex('':'',@shourEnd) + 1, len(@shourEnd))
end
else begin
 select @hourStart=0,@minStart=0,@hourEnd=23,@minEnd=59
end
SET DATEFIRST 1
set @horaUniversal = getutcdate()
select c.cam_id, h.horario_id,Descripcion, c.cam_tNoContesta,  -- Correccion del ticket TT14496
 case when HoraInicio>@hourStart then HoraInicio else @hourStart end HoraInicio,
 case when (horaInicio>@hourStart or (horaInicio=@hourStart and MinInicio>=@minStart) ) then MinInicio  else @minStart end MinInicio,
 case when horaFin<@hourEnd then horaFin else @hourEnd end HoraFin,
 case when ((horaFin < @hourEnd or (horaFin=@hourEnd and MinFin<=@minEnd) )) then MinFin  else @minEnd end MinFin,
 Lunes,Martes,Miercoles,Jueves,Viernes,Sabado,Domingo
 into #tempCampLaw
 from cchorarios h
 inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on h.horario_id = ccCampsHorarios.horario_id --and 
 inner join ccCamps c on c.cam_id=ccCampsHorarios.cam_id 
 where (@campId is null or @campId=0 ) or ccCampsHorarios.cam_id = @campId
select distinct cam_id, horario_id,HoraInicio,MinInicio,horaFin,MinFin into #tempCampLaw2 from
(
 select tz_id,
 dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
 datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora,
 datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
 datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
 from ccTimeZones
)zonas
inner join #tempCampLaw on
(
 (
  hora > HoraInicio OR  (hora = HoraInicio AND minuto >= MinInicio)
 )
 AND
 (
  hora < HoraFin  OR  (hora = HoraFin AND minuto <= (MinFin-cam_tNoContesta) )  -- Correccion del ticket TT14496
 )
 AND
 (
  Lunes  = dia or
  Martes *2 = dia or
  Miercoles*3 = dia or
  Jueves*4 = dia or
  Viernes*5 = dia or
  Sabado*6 = dia or
  domingo*7 = dia
 )
)
select distinct #tempCampLaw2.cam_id, #tempCampLaw2.horario_id id,
(HoraInicio*3600)+(MinInicio*60) ini,
(HoraFin*3600)+(MinFin*60) fin,
(case when HoraInicio<10 then ''0''+convert(varchar(2),HoraInicio) else convert(varchar(2),HoraInicio) end) + '':'' + (case when MinInicio<10 then ''0''+convert(varchar(2),MinInicio) else convert(varchar(2),MinInicio) end ) as HoraInicio ,
(case when HoraFin<10 then ''0''+convert(varchar(2),HoraFin) else convert(varchar(2),HoraFin) end) + '':'' + (case when MinFin<10 then ''0''+convert(varchar(2),MinFin) else convert(varchar(2),MinFin) end ) as HoraFin
into #tempCamp from #tempCampLaw2
;WITH tempCamp AS (
    SELECT DISTINCT #tempCampLaw2.cam_id, #tempCampLaw2.horario_id AS id,
        (HoraInicio * 3600) + (MinInicio * 60) AS ini,
        (HoraFin * 3600) + (MinFin * 60) AS fin,
        RIGHT(''0'' + CONVERT(VARCHAR(2), HoraInicio), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), MinInicio), 2) AS HoraInicio,
        RIGHT(''0'' + CONVERT(VARCHAR(2), HoraFin), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), MinFin), 2) AS HoraFin
    FROM #tempCampLaw2
),
OrderedIntervals AS (
    SELECT 
        cam_id,
        ini,
        fin,
        ROW_NUMBER() OVER (PARTITION BY cam_id ORDER BY ini) AS RowNum
    FROM tempCamp
),
MergedIntervals AS (
    SELECT 
        o1.cam_id,
        o1.ini,
        MAX(o2.fin) AS fin
    FROM OrderedIntervals o1
    LEFT JOIN OrderedIntervals o2
        ON o1.cam_id = o2.cam_id
        AND o2.ini <= o1.fin -- Verifica si los intervalos se solapan
    GROUP BY o1.cam_id, o1.ini
),
CleanedIntervals AS (
    SELECT 
        cam_id,
        ini,
        fin
    FROM (
        SELECT 
            cam_id,
            ini,
            fin,
            LAG(fin) OVER (PARTITION BY cam_id ORDER BY ini) AS PrevFin
        FROM MergedIntervals
    ) t
    WHERE PrevFin IS NULL OR ini > PrevFin -- Elimina duplicados y solapamientos residuales
)
SELECT 
    ci.cam_id,
    ci.ini,
    ci.fin,
    RIGHT(''0'' + CONVERT(VARCHAR(2), ci.ini / 3600), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), (ci.ini % 3600) / 60), 2) AS HoraInicio,
    RIGHT(''0'' + CONVERT(VARCHAR(2), ci.fin / 3600), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), (ci.fin % 3600) / 60), 2) AS HoraFin,
	c.cam_tNoContesta AS timeMaxContestacion  -- Correccion del ticket TT14496
FROM CleanedIntervals ci
INNER JOIN ccCamps c ON c.cam_id = ci.cam_id  -- Correccion del ticket TT14496
ORDER BY cam_id, ini;
drop table #tempCamp
drop table #tempCampLaw
drop table #tempCampLaw2
'
		EXEC(@sql)



        -------------------------------------------  END Isaac  ----------------------------------------

------------------------------------------------Begin Gaby -----------------------------------------------------------
	SET @process = 'TT14545 DROP PROCEDURE ccsp_DLRgetDialPrefix'
	SET @sql = '
	IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N''ccsp_DLRgetDialPrefix'')
	BEGIN
		DROP PROCEDURE ccsp_DLRgetDialPrefix;
	END'
	EXEC(@sql)


	SET @process = 'TT14545 - se modifica set de @ani en ccsp_DLRgetDialPrefix'
	SET @sql = '
	create procedure ccsp_DLRgetDialPrefix
					@cam_id smallint=0,
					@iPortNumber smallint = 0,
					@phone varchar(30) = '''',
					@callout_id int = 0
					as
					declare @prefix as varchar(15), @sipheader varchar(500)
					declare @ani as varchar(32)
					declare @pais as tinyint 
					declare @aniglobal varchar(32), @sipHdrFormat varchar(255)
					declare @ivr_script smallint, @surveycamid int
					declare @call_record tinyint, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint
					declare @PrefixRec varchar(40)
					declare @carrier varchar(255)
					declare @recordHold bit, @recordIvr bit
					declare @RotativeAlgo int ,@aniList smallint 

					select @pais = valor from ccsettings with(nolock) where setting_id = 104
					select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

					set @prefix =''''
					-- Prefijo por puerto
					select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

					-- Prefijo por campa?a,
					if @prefix =''''
						select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

					-- Prefijo general
					if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
						select @prefix = valor from ccsettings with(nolock) where setting_id =101

					-- Ani
					select @RotativeAlgo = RotativeAlgo from ccCamps where cam_id = @cam_id
					select @aniList = id_anilist from ccCamps where cam_id =@cam_id

					if @RotativeAlgo=0 and @aniList>0  begin
					set @ani = dbo.TelAni(@phone, @aniList )
					end
					else begin
						set @ani=''''
					end
					set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

					--AnswerMachine Message Files
					DECLARE @MsgFiles VARCHAR(8000) 
					SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile 
					FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

					IF EXISTS (select 1 from ccCampsMsgs where Type = 20 and cam_id = @cam_id)
					BEGIN
						select @MsgFiles = @MsgFiles + '',TTS/message.wav''
					END

					--Custom MOH Files
					DECLARE @MohFiles VARCHAR(8000) 
					SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
					FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

					select @surveycamid = 0, @ivr_script = 0

					select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta = cam_tNoContesta, @ani = case when @ani = '''' then ani else @ani end
					,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
					,@call_record = dbo.EnableCallRecord(call_record, @pais, @phone), @surveycamid = isnull(surveycamid,0), @recordHold=ISNULL(recordHold,0)
					,@recordIvr=ISNULL(recordIvr,0), @PrefixRec = ISNULL(prefijo,'''')
					from ccCamps NOLOCK where cam_id = @cam_id

					SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)

					if @surveycamid > 0
						select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid


					if @ani = '''' begin 
					set @ani = @aniglobal 
					end 

					 set @carrier = ''''
					 select @carrier = dbo.GetCarrierByTel(@phone)

					select @prefix as sDialPrefix, @tNoContesta as tNoContesta,@ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
					@call_record as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles, @ivr_script ivrScript, @sipheader data
					,@PrefixRec PrefijoRec, @carrier Carrier, @recordHold recordHold, @recordIvr recordIvr'
	EXEC(@sql)


------------------------------------------------End Gaby -----------------------------------------------------------------

------------------------------------------------Begin Luis Zamora -----------------------------------------------------------------
	SET @process = 'Luis Zamora TT14714 - Finder - No se pueden visualizar grabaciones si solo se esta en un tipo de campaña DROP PROCEDURE ccsp_BaseXmngr'
		SET @sql = '
		IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N''ccsp_BaseXmngr'')
		BEGIN
			DROP PROCEDURE ccsp_BaseXmngr;
		END'
		EXEC(@sql)

	SET @process = 'Luis Zamora TT14714 - Finder - No se pueden visualizar grabaciones si solo se esta en un tipo de campaña CREATE PROCEDURE ccsp_BaseXmngr'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_BaseXmngr]
	@action int,
	@option tinyint = 0,
	@ids varchar(max)=null,
	@name varchar(25) = NULL,
	@top int = 0,
	@dateIni datetime =null,
	@dateEnd datetime =null,
	@dateStart dateTime= null,
	@userId int = 0,
	@node varchar(10) = null,
	@grabIds varchar(4000) = null
	AS

	declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
	declare @parameterDefinition nvarchar(max)
	declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
	declare @status tinyint
	declare @filterWg varchar(max)
	declare @len int
	declare @tipo int
	declare @serviceId varchar(10)

	set @sql = ''''

	select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=@option 

	if @action in (1,6) begin --obtiene los nodos a insertar en BX
	    if @action = 1 set @status =0
	    else if @action = 6 set @status = 2

	    if @option <>2 begin

	    declare @auxTag nvarchar(10)
	                            
	    select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02''
	    else ''@CDATE''   end
	    set @parameterDefinition =N''@status int, @top int,@option int''
	    set @sql=''declare @basexName varchar(max)
	select @basexName=Xname from ccBaseXDB where serviceId=@option and isFull=0;
	    with node ( ''+@columnId+ '',xmlString,dateNode)
	    AS(
	        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
	        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
	        from ''+ @tableName + '' A with(rowlock)
	        where A.status =@status
	        union
	        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
	        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
	        from ''+ @tableNameHistory + '' A with(rowlock)
	        where A.status =@status  
	    )

	    select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
	    left join ccBaseXDB baseX on baseX.serviceId= @option and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
	    order by Xname''
	    --print(@sql)
	    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top,@option=@option
	    end
	end
	else if @action in (2,7) begin--actualiza los nodos insertados en BX
	    if @action = 2 set @status =0
	    else if @action = 7 set @status = 2

	    set @parameterDefinition =N''@status int''

	    set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
	    select @tableName,@columnId,@ids,@sql
	    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
	    set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
	    --print(@sql)
	    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status

	end
	else if @action = 3 --trae el nombre de la base de datos en BX
	begin
	    select Xname from ccBaseXDB where serviceId = @option and isFull=0
	end
	else if @action = 4 --inserta el nombre del xml en BX
	begin
	    insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
	end
	else if @action = 5 begin --obtener servicios disponibles    
	    select id, ref  from ccFinderServices where isActive=1
	end
	else if @action = 8 begin--trae la lista de las bases para la busqueda
	    select Xname from ccBaseXDB where serviceId = @option
	    and (

	    @dateIni between dateStart and dateEnd
	    or @dateEnd between dateStart and dateEnd
	    or dateStart between @dateIni and @dateEnd
	    )
	    union
	    select Xname from ccBaseXDB where serviceId = @option and isFull=0
	    and (
	        dateStart between @dateIni and @dateEnd
	        or @dateIni>=dateStart

	    )
	end
	else if @action = 9 begin--Cierra la base datos
	    update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()), dateStart=isnull(@dateStart,dateStart) where serviceId= @option and  isfull = 0 and dateEnd is null
	    and Xname=@name
	end

	else if @action = 10 begin
	    
	    set @tipo = CASE WHEN @node = ''R06'' THEN 1 ELSE 0 END
	    set @filterWg=''''
	    if @node is null or @node = ''R02''
	    begin
	        select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
	        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
	        where Wguser.User_id=@userId
	                        
	    end
	    else
	    begin
	    
	    set @serviceId = (select convert(varchar(10), id) from ccFinderServices where ref = @node)
	    select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+@serviceId+'') or '' from ccRIAWorkGroupUsers Wguser
	        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
	        where Wguser.User_id=@userId and WGCam.Tipo=@tipo
	    end


	    set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
	    select SUBSTRING(@filterWg,0, @len)
	    end


	else if @action = 11 begin--trae el nombre de la base de datos en BX

	    set @sql=''
	    declare @dateStart datetime
	    set @dateStart= convert(datetime,convert(varchar(10),getdate(),121))
	    SELECT isnull(min(dateIn),@dateStart) as node FROM ''+@tableName+'' where status = 0  ''
	    EXECUTE sp_executesql  @sql

	end

	else if @action = 13 begin
	    set @sql = ''''
	    select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=5 
	    select @tableName,@tableNameHistory,@columnId
	    set @sql=''
	    ;
	    with duplicateIds as(
	    select ''+@columnId+'',dateIn from ''+@tableName+'' where ''+@columnId+'' in(''+@grabIds+'')
	    union
	    select ''+@columnId+'',dateIn from ''+@tableNameHistory+'' where ''+@columnId+'' in(''+@grabIds+'')
	    )

	    select A.''+@columnId+'' as Id,min(B.Xname) Xname from duplicateIds A
	    inner join ccbasexDB B on B.serviceId=2 and( A.dateIn between B.dateStart and B.dateEnd or A.dateIn>= B.dateStart)
	    group by A.''+@columnId+'',A.dateIn
	    Having count(*)>1
	    order by Xname
	    ''
	    exec (@sql)

	end

	else if @action = 14 begin
	    declare @CidNameOut varchar(100),@CidNameIn varchar(100)
	    declare @filterCamId varchar(max), @filterInboundId varchar(max);
	    declare @campType int
	    declare @cidOut varchar(max)=''''
	    declare @cidin varchar(max)=''''

	    set @filterWg=''''
	    if @node is null begin
	        set @node=''R02''
	    end

	    set @CidNameOut=''$CID_OUT''
	    set @CidNameIn=''$CID_IN''

	    set @filterCamId=''''
	    
	    select @filterCamId=@filterCamId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
	    from ccRIAWorkGroupUsers Wguser
	    inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
	    inner join ccCamps c on c.cam_id=WGCam.IdCampEsp --and c.CampType not in(5,7)
	    where Wguser.User_id=@userId and WGCam.Tipo=1                               
	    

	    if @filterCamId<>'''' begin
	        set @filterWg=''let ''+@CidNameOut+'':=(''

	        set @filterCamId=SUBSTRING(@filterCamId,0,len(@filterCamId))
	        set @filterCamId=@filterCamId+'')''+char(10)    

	        set @filterWg=@filterWg+@filterCamId
	        set @cidOut=''(exists(index-of($CID_OUT, $r/@CID)) and $r/@CType = CTYPE_REMPLACE)''
	    end
	    else begin 
		 set @filterWg=''let ''+@CidNameOut+'':=(0)''
		 set @filterCamId=0
		end

	    SET @filterInboundId= ''''
	            
	    select @filterInboundId=@filterInboundId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
	    from ccRIAWorkGroupUsers Wguser
	        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
	        inner join ccInbound c on c.Inbound_id=WGCam.IdCampEsp
	        where Wguser.User_id=@userId and WGCam.Tipo=0
	    
	    if @filterInboundId<>'''' begin
	        set @filterInboundId=SUBSTRING(@filterInboundId,0,len(@filterInboundId))
	        set @filterInboundId=@filterInboundId+'')''+char(10)    

	        set @filterWg=@filterWg+''let ''+@CidNameIn+'':=(''+@filterInboundId
	        set @cidin=''(exists(index-of($CID_IN, $r/@CID)) and $r/@CType = CTYPE_REMPLACE)''
	    end
	    else begin
		  set @filterWg=@filterWg+''let ''+@CidNameIn+'':=(0)''
		  set @filterInboundId=0
		end
	    
	    select @filterWg as VarCamInOut,@cidOut as CidOut,@cidin as CidIn
	end
	else if @action = 15 begin --Saber si hacer busqueda en basex
	  select @tableName=tableName,@tableNameHistory=tableNameHistory from ccFinderServices where ref=@node
	  if @node=''R02'' begin
	    select 1
	    return(0)
	  end

	  set @sql=''if exists(select * from ''+@tableName+'') begin
	        select 1
	    end
	    else if exists(select * from ''+@tableNameHistory+'') begin
	        select 1
	    end
	    select 0''
	    exec (@sql)
	    
	end'
	EXEC(@sql)
------------------------------------------------End Luis Zamora -----------------------------------------------------------------


	SET @process = 'Jesus Gallardo K075001 - Eliminar el reporte "Detalle de llamadas en chat contestadas"'
	SET @sql = 'delete from ccMenuRol where menu_id=4140 and type=3
delete from ccMenuUser where id_Menu=4140 and type=3
delete from ccMenus where menu_id=4140 and type=3
'
	EXEC(@sql)

	SET @process = ''
	SET @sql = ''
	EXEC(@sql)

	SET @process = ''
	SET @sql = ''
	EXEC(@sql)
	
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
