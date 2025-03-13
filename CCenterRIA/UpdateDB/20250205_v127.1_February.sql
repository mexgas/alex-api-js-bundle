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

	SET @process = 'Se borra didentificador para etiquetas al modificar areas'
	SET @sql = '	
		IF EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''T&SET_MAX_WHATS_IN'')
		BEGIN
			Delete ccGalateaIdentifiers where Description = ''T&SET_MAX_WHATS_IN''
		END'
	EXEC(@sql)

	SET @process = 'Se insertan identificadores para mostrar etiquetas en historial de actividad al editar areas'
	SET @sql = '	
		IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''T&SET_MAX_WHATS'')
		BEGIN
			insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
			values (''T&SET_MAX_WHATS'', ''Conversaciones de WhatsApp de entrada por agente'', ''Inbound WhatsApp conversations per agent'', ''Conversas de WhatsApp de entrada por agente'')
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
	
	------------------------------------------------Begin Omar Mejia -----------------------------------------------------------------
	
		SET @process = 'Actualizar tabla ZonasHorarias'
		SET @sql = '
Delete ccTimeZoneArea

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''CDMX'', 64, 32, NULL, N''CUAUHTEMOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''663'', N''BC'', 256, 128, NULL, N''TIJUANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''200'', N''SIN'', 128, 64, NULL, N''CONCORDIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''221'', N''PUE'', 64, 32, NULL, N''PUEBLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''HUEJOTZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''OCOYUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''PUEBLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''SAN ANDRES CHOLULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''SAN GRERIO ATZOMPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''SAN JUAN CUAUTLANCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''SAN MIGUEL XOXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''SAN PEDRO CHOLULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''SANTA ISABEL CHOLULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''SANTA MARIA CORONAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''TLALTENANGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''TLAX'', 64, 32, NULL, N''MAZATECOCHCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''TLAX'', 64, 32, NULL, N''PAPALOTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''TLAX'', 64, 32, NULL, N''SAN PABLO DEL MONTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''TLAX'', 64, 32, NULL, N''TENANCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''TLAX'', 64, 32, NULL, N''XICOTZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''223'', N''PUE'', 64, 32, NULL, N''ACAJETE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''223'', N''PUE'', 64, 32, NULL, N''NOPALUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''223'', N''PUE'', 64, 32, NULL, N''TEPATLAXCO DE HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''223'', N''PUE'', 64, 32, NULL, N''TEPEACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''223'', N''TLAX'', 64, 32, NULL, N''ZITLALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''ATOYATEMPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''CHIGMECATITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''CUAUTINCHAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''HUATLATLAHUACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''IXCAQUIXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''MOLCAXAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''SAN FRANCISCO MIXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''SAN JUAN ATZOMPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''SANTA CLARA HUITZILTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''SANTA INES AHUATEMPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''SANTO TOMAS HUEYOTLIPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''TECALI DE HERRERA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''TEPEXI DE RODRIGUEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''TLANEPANTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''TOCHTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''TZICATLACOYAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''ZACAPALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''225'', N''VER'', 64, 32, NULL, N''TLAPACOYAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''226'', N''VER'', 64, 32, NULL, N''ALTOTONGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''226'', N''VER'', 64, 32, NULL, N''ATZALAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''226'', N''VER'', 64, 32, NULL, N''JALACIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''227'', N''PUE'', 64, 32, NULL, N''DOMIN ARENAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''227'', N''PUE'', 64, 32, NULL, N''HUEJOTZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''227'', N''PUE'', 64, 32, NULL, N''SAN ANDRES CALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''227'', N''PUE'', 64, 32, NULL, N''SAN BUENAVENTURA NEALTICAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''227'', N''PUE'', 64, 32, NULL, N''SAN JERONIMO TECUANIPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''227'', N''PUE'', 64, 32, NULL, N''SAN NICOLAS DE LOS RANCHOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''ACAJETE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''BANDERILLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''COACOATZINTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''COATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''EMILIANO ZAPATA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''JILOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''RAFAEL LUCIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''TEOCELO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''TLALNELHUAYOCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''TONAYAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''XALAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''XALAPA ENRIQUEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''228'', N''VER'', 64, 32, NULL, N''XICO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''229'', N''VER'', 64, 32, NULL, N''ALVARADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''229'', N''VER'', 64, 32, NULL, N''BOCA DEL RIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''229'', N''VER'', 64, 32, NULL, N''MEDELLIN DE BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''229'', N''VER'', 64, 32, NULL, N''VERACRUZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''231'', N''PUE'', 64, 32, NULL, N''ATEMPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''231'', N''PUE'', 64, 32, NULL, N''CHIGNAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''231'', N''PUE'', 64, 32, NULL, N''HUEYAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''231'', N''PUE'', 64, 32, NULL, N''TETELES DE AVILA CAMACHO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''231'', N''PUE'', 64, 32, NULL, N''TEZIUTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''232'', N''PUE'', 64, 32, NULL, N''ACATENO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''232'', N''PUE'', 64, 32, NULL, N''HUEYTAMALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''232'', N''VER'', 64, 32, NULL, N''MARTINEZ DE LA TORRE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''232'', N''VER'', 64, 32, NULL, N''TECOLUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''232'', N''VER'', 64, 32, NULL, N''TLAPACOYAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''AYOTOXCO DE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''CAXHUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''CUETZALAN DEL PROGRESO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''HUEHUETLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''HUEYTLALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''IGNACIO ALLENDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''IXTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''JONOTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''NAUZONTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''OLINTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''TENAMPULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''TLATLAUQUITEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''TUZAMAPAN DE GALEANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''XOCHIAPULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''XOCHITLAN DE ROMERO RUBIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''XOCHITLAN DE VICENTE SUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''ZACAPOAXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''ZAPOTITLAN DE MENDEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''ZARAGOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''ZAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''ZOQUIAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''235'', N''VER'', 64, 32, NULL, N''MISANTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''235'', N''VER'', 64, 32, NULL, N''NAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''235'', N''VER'', 64, 32, NULL, N''TENOCHTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''235'', N''VER'', 64, 32, NULL, N''VEGA DE ALATORRE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''OAX'', 64, 32, NULL, N''HUAUTLA DE JIMENEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''OAX'', 64, 32, NULL, N''SAN ANTONIO NANAHUATIPAM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''OAX'', 64, 32, NULL, N''SAN JUAN BAUTISTA CUICATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''OAX'', 64, 32, NULL, N''SAN JUAN CHIQUIHUITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''OAX'', 64, 32, NULL, N''SAN JUAN DE LOS CUES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''OAX'', 64, 32, NULL, N''SAN MATEO YOLOXOCHITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''OAX'', 64, 32, NULL, N''SANTA MARIA TECOMAVACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''OAX'', 64, 32, NULL, N''SANTIA TEXCALCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''OAX'', 64, 32, NULL, N''TEOTITLAN DE FLORES MAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''PUE'', 64, 32, NULL, N''AJALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''PUE'', 64, 32, NULL, N''ALTEPEXI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''PUE'', 64, 32, NULL, N''COXCATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''PUE'', 64, 32, NULL, N''COYOMEAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''PUE'', 64, 32, NULL, N''SAN JOSE MIAHUATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''PUE'', 64, 32, NULL, N''TLACOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''PUE'', 64, 32, NULL, N''VICENTE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''PUE'', 64, 32, NULL, N''ZINACATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''PUE'', 64, 32, NULL, N''ZOQUITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''237'', N''PUE'', 64, 32, NULL, N''ATENAYUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''237'', N''PUE'', 64, 32, NULL, N''ATEXCAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''237'', N''PUE'', 64, 32, NULL, N''SAN GABRIEL CHILAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''237'', N''PUE'', 64, 32, NULL, N''TLACOTEPEC DE BENITO JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''237'', N''PUE'', 64, 32, NULL, N''XOCHITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''237'', N''PUE'', 64, 32, NULL, N''YEHUALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''237'', N''PUE'', 64, 32, NULL, N''ZAPOTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''238'', N''PUE'', 64, 32, NULL, N''NICOLAS BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''238'', N''PUE'', 64, 32, NULL, N''SANTIA MIAHUATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''238'', N''PUE'', 64, 32, NULL, N''TEHUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''238'', N''PUE'', 64, 32, NULL, N''TEPANCO DE LOPEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''APIZACO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''EMILIANO ZAPATA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''ESPANITA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''HUEYOTLIPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''LAZARO CARDENAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''MUNOZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''TERRENATE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''TETLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''TLAXCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''TZOMPANTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''XALOZTOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''XALTOCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''YAUHQUEMEHCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''243'', N''PUE'', 64, 32, NULL, N''AHUATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''243'', N''PUE'', 64, 32, NULL, N''ATZALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''243'', N''PUE'', 64, 32, NULL, N''CHIETLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''243'', N''PUE'', 64, 32, NULL, N''COATZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''243'', N''PUE'', 64, 32, NULL, N''HUEHUETLAN EL GRANDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''243'', N''PUE'', 64, 32, NULL, N''IZUCAR DE MATAMOROS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''243'', N''PUE'', 64, 32, NULL, N''SAN JUAN EPATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''243'', N''PUE'', 64, 32, NULL, N''TEOPANTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''243'', N''PUE'', 64, 32, NULL, N''TEPEXCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''243'', N''PUE'', 64, 32, NULL, N''TILAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''243'', N''PUE'', 64, 32, NULL, N''XOCHILTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''244'', N''PUE'', 64, 32, NULL, N''ACTEOPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''244'', N''PUE'', 64, 32, NULL, N''ATLIXCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''244'', N''PUE'', 64, 32, NULL, N''ATZITZIHUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''244'', N''PUE'', 64, 32, NULL, N''COHUECAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''244'', N''PUE'', 64, 32, NULL, N''HUAQUECHULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''244'', N''PUE'', 64, 32, NULL, N''TEPEOJUMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''244'', N''PUE'', 64, 32, NULL, N''TIANGUISMANALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''244'', N''PUE'', 64, 32, NULL, N''TLAPANALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''244'', N''PUE'', 64, 32, NULL, N''TOCHIMILCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''245'', N''PUE'', 64, 32, NULL, N''ATZITZINTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''245'', N''PUE'', 64, 32, NULL, N''CHALCHICOMULA DE SESMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''245'', N''PUE'', 64, 32, NULL, N''ESPERANZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''245'', N''PUE'', 64, 32, NULL, N''SAN JUAN ATENCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''245'', N''PUE'', 64, 32, NULL, N''SAN NICOLAS BUENOS AIRES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''245'', N''PUE'', 64, 32, NULL, N''TLACHICHUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''AMAXAC DE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''CHIAUTEMPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''LA MAGDALENA TLALTELULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''PANOTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''PAPALOTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''PAPALOTLA DE XICOHTENCATL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''SAN DAMIAN TEXOLOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''SAN FRANCISCO TETLANOHCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''SAN JOSE TEACALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''SANTA ANA NOPALUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''SANTA MARIA NATIVITAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''TEOLOCHOLCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''TETLATLAHUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''TLAXCALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''ZACATELCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''247'', N''TLAX'', 64, 32, NULL, N''HUAMANTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''247'', N''TLAX'', 64, 32, NULL, N''IXTENCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''248'', N''PUE'', 64, 32, NULL, N''CHIAUTZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''248'', N''PUE'', 64, 32, NULL, N''SAN FELIPE TEOTLALCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''248'', N''PUE'', 64, 32, NULL, N''SAN MARTIN TEXMELUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''248'', N''PUE'', 64, 32, NULL, N''SAN MATIAS TLALANCALECA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''248'', N''PUE'', 64, 32, NULL, N''SAN SALVADOR EL VERDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''248'', N''PUE'', 64, 32, NULL, N''TLAHUAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''248'', N''TLAX'', 64, 32, NULL, N''TEPETITLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''248'', N''TLAX'', 64, 32, NULL, N''VILLA MARIANO MATAMOROS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''249'', N''PUE'', 64, 32, NULL, N''ACATZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''249'', N''PUE'', 64, 32, NULL, N''ALJOJUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''249'', N''PUE'', 64, 32, NULL, N''CANADA MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''249'', N''PUE'', 64, 32, NULL, N''GENERAL FELIPE ANGELES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''249'', N''PUE'', 64, 32, NULL, N''LOS REYES DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''249'', N''PUE'', 64, 32, NULL, N''PALMAR DE BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''249'', N''PUE'', 64, 32, NULL, N''QUECHOLAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''249'', N''PUE'', 64, 32, NULL, N''SAN SALVADOR EL SECO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''249'', N''PUE'', 64, 32, NULL, N''SAN SALVADOR HUIXCOLOTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''249'', N''PUE'', 64, 32, NULL, N''SOLTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''249'', N''PUE'', 64, 32, NULL, N''TECAMACHALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''271'', N''VER'', 64, 32, NULL, N''AMATLAN DE LOS REYES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''271'', N''VER'', 64, 32, NULL, N''CORDOBA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''271'', N''VER'', 64, 32, NULL, N''FORTIN DE LAS FLORES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''271'', N''VER'', 64, 32, NULL, N''IXTACZOQUITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''271'', N''VER'', 64, 32, NULL, N''NARANJAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''ACULTZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''ACULZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''ATZACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''CAMERINO Z MENDOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''HUILOAPAN DE CUAUHTEMOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''IXHUATLANCILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''IXTACZOQUITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''MALTRATA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''MARIANO ESCOBEDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''ORIZABA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''RAFAEL DELGADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''RIO BLANCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''PUE'', 64, 32, NULL, N''CHICHIQUILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''ATOYAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''CALCAHUALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''CAMARON DE TEJEDA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''CHOCAMAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''COMAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''COSCOMATEPEC DE BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''HUATUSCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''HUATUSCO DE CUELLAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''IXHUATLAN DEL CAFE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''PASO DEL MACHO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''TEPATLAXCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''TLACOTEPEC DE MEJIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''TOMATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''TOTUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''ZENTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''274'', N''OAX'', 64, 32, NULL, N''ACATLAN DE PEREZ FIGUEROA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''274'', N''OAX'', 64, 32, NULL, N''NUEVO SOYALTEPEC TEMASCAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''274'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL SOYALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''274'', N''VER'', 64, 32, NULL, N''TIERRA BLANCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''AHUEHUETITLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''ALBINO ZERTUCHE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''AXUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''CAYUCA DE ANDRADE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''CHIAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''CHILA DE LA SAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''CHINANTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''COHETZALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''GUADALUPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''HUEHUETLAN EL CHICO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''IXACAMILPA DE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''JOLALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''PIAXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''SAN PABLO ANICANO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''TECOMATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''TEHUITZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''TULCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''276'', N''PUE'', 64, 32, NULL, N''CUYOACO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''276'', N''PUE'', 64, 32, NULL, N''IXTACAMAXTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''276'', N''PUE'', 64, 32, NULL, N''LIBRES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''276'', N''PUE'', 64, 32, NULL, N''OCOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''276'', N''PUE'', 64, 32, NULL, N''ORIENTAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''276'', N''PUE'', 64, 32, NULL, N''RAFAEL LARA GRAJALES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''276'', N''PUE'', 64, 32, NULL, N''SAN JOSE CHIAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''276'', N''TLAX'', 64, 32, NULL, N''ALTZAYANCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''276'', N''TLAX'', 64, 32, NULL, N''CUAPIAXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''276'', N''TLAX'', 64, 32, NULL, N''TEQUEXQUITLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''CARRILLO PUERTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''COTAXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''CUICHAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''CUITLAHUAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''OMEALCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''SOLEDAD ATZOMPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''TEHUIPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''TEQUILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''TEXHUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''TEZONAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''XOXOCOTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''YANGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''VER'', 64, 32, NULL, N''ZONLICA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''ACATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''ACTOPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''ALTO LUCERO DE GUTIERREZ BARRIOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''APAZAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''CHICONQUIACO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''COLIPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''COSAUTLAN DE CARVAJAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''EMILIANO ZAPATA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''JALCOMULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''JUCHIQUE DE FERRER'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''NAOLINCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''NAOLINCO DE VICTORIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''TENAMPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''TEPETLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''TLALTETELA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''YECUATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''281'', N''OAX'', 64, 32, NULL, N''LOMA BONITA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''282'', N''PUE'', 64, 32, NULL, N''CHILCHOTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''282'', N''PUE'', 64, 32, NULL, N''GUADALUPE VICTORIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''282'', N''PUE'', 64, 32, NULL, N''QUIMIXTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''282'', N''PUE'', 64, 32, NULL, N''SALTILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''282'', N''PUE'', 64, 32, NULL, N''TEPEYAHUALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''282'', N''VER'', 64, 32, NULL, N''AYAHUALULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''282'', N''VER'', 64, 32, NULL, N''IXHUACAN DE LOS REYES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''282'', N''VER'', 64, 32, NULL, N''LAS VIGAS DE RAMIREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''282'', N''VER'', 64, 32, NULL, N''PEROTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''282'', N''VER'', 64, 32, NULL, N''VILLA ALDAMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''ASUNCION CACALOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''AYOTZINTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SAN FELIPE USILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SAN JUAN BAUTISTA VALLE NACIONAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SAN JUAN COTZOCON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SAN JUAN LALANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL QUETZALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SANTA MARIA ALOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SANTA MARIA JACATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SANTA MARIA TLAHUITOLTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SANTIA CHOAPAM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SANTIA COMOTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SANTIA JOCOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SANTIA ZACATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''TAMAZULAPAM DEL ESPIRITU SANTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''TOTONTEPEC VILLA DE MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''VER'', 64, 32, NULL, N''ISLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''VER'', 64, 32, NULL, N''JUAN RODRIGUEZ CLARA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''VER'', 64, 32, NULL, N''PLAYA VICENTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''VER'', 64, 32, NULL, N''VILLA AZUETA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''284'', N''VER'', 64, 32, NULL, N''ANGEL R. CABADA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''284'', N''VER'', 64, 32, NULL, N''LERDO DE TEJADA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''284'', N''VER'', 64, 32, NULL, N''SALTABARRANCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''285'', N''VER'', 64, 32, NULL, N''IGNACIO DE LA LLAVE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''285'', N''VER'', 64, 32, NULL, N''JAMAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''285'', N''VER'', 64, 32, NULL, N''MANLIO FABIO ALTAMIRANO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''285'', N''VER'', 64, 32, NULL, N''MEDELLIN DE BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''285'', N''VER'', 64, 32, NULL, N''PASO DE OVEJAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''285'', N''VER'', 64, 32, NULL, N''SOLEDAD DE DOBLADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''285'', N''VER'', 64, 32, NULL, N''TLALIXCOYAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''287'', N''OAX'', 64, 32, NULL, N''SAN BARTOLOME AYAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''287'', N''OAX'', 64, 32, NULL, N''SAN FELIPE JALAPA DE DIAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''287'', N''OAX'', 64, 32, NULL, N''SAN JOSE CHILTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''287'', N''OAX'', 64, 32, NULL, N''SAN JUAN BAUTISTA TUXTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''287'', N''OAX'', 64, 32, NULL, N''SAN LUCAS OJITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''287'', N''OAX'', 64, 32, NULL, N''SAN PEDRO IXCATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''287'', N''VER'', 64, 32, NULL, N''OTATITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''288'', N''VER'', 64, 32, NULL, N''ACULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''288'', N''VER'', 64, 32, NULL, N''AMATITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''288'', N''VER'', 64, 32, NULL, N''CARLOS A CARRILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''288'', N''VER'', 64, 32, NULL, N''CHACALTIANGUIS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''288'', N''VER'', 64, 32, NULL, N''COSAMALOAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''288'', N''VER'', 64, 32, NULL, N''COSAMALOAPAN DE CARPIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''288'', N''VER'', 64, 32, NULL, N''IXMATLAHUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''288'', N''VER'', 64, 32, NULL, N''TLACOJALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''288'', N''VER'', 64, 32, NULL, N''TLACOTALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''288'', N''VER'', 64, 32, NULL, N''TRES VALLES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''288'', N''VER'', 64, 32, NULL, N''TUXTILLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''294'', N''VER'', 64, 32, NULL, N''ACAYUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''294'', N''VER'', 64, 32, NULL, N''CATEMACO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''294'', N''VER'', 64, 32, NULL, N''HUEYAPAN DE OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''294'', N''VER'', 64, 32, NULL, N''SAN ANDRES TUXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''294'', N''VER'', 64, 32, NULL, N''SANTIA TUXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''296'', N''VER'', 64, 32, NULL, N''ACTOPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''296'', N''VER'', 64, 32, NULL, N''ALTO LUCERO DE GUTIERREZ BARRIOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''296'', N''VER'', 64, 32, NULL, N''LA ANTIGUA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''296'', N''VER'', 64, 32, NULL, N''PUENTE NACIONAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''296'', N''VER'', 64, 32, NULL, N''URSULO GALVAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''297'', N''VER'', 64, 32, NULL, N''ALVARADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''311'', N''NAY'', 64, 32, 1, N''BAHIA DE BANDERAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''311'', N''NAY'', 128, 64, NULL, N''TEPIC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''311'', N''NAY'', 128, 64, NULL, N''XALISCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''312'', N''COL'', 64, 32, NULL, N''COLIMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''312'', N''COL'', 64, 32, NULL, N''COMALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''312'', N''COL'', 64, 32, NULL, N''COQUIMATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''312'', N''COL'', 64, 32, NULL, N''CUAUHTEMOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''312'', N''COL'', 64, 32, NULL, N''VILLA DE ALVAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''312'', N''JAL'', 64, 32, NULL, N''PIHUAMO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''312'', N''JAL'', 64, 32, NULL, N''TONILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''312'', N''JAL'', 64, 32, NULL, N''TUXPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''313'', N''COL'', 64, 32, NULL, N''ARMERIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''313'', N''COL'', 64, 32, NULL, N''IXTLAHUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''313'', N''COL'', 64, 32, NULL, N''TECOMAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''313'', N''MICH'', 64, 32, NULL, N''AQUILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''313'', N''MICH'', 64, 32, NULL, N''COAHUAYANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''314'', N''COL'', 64, 32, NULL, N''MANZANILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''314'', N''COL'', 64, 32, NULL, N''MINATITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''315'', N''JAL'', 64, 32, NULL, N''CIHUATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''315'', N''JAL'', 64, 32, NULL, N''LA HUERTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''316'', N''JAL'', 64, 32, NULL, N''AYUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''316'', N''JAL'', 64, 32, NULL, N''CUAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''316'', N''JAL'', 64, 32, NULL, N''UNION DE TULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''317'', N''JAL'', 64, 32, NULL, N''AUTLAN DE NAVARRO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''319'', N''NAY'', 128, 64, NULL, N''EL NAYAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''319'', N''NAY'', 128, 64, NULL, N''ROSAMORADA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''319'', N''NAY'', 128, 64, NULL, N''RUIZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''319'', N''NAY'', 128, 64, NULL, N''TUXPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''321'', N''JAL'', 64, 32, NULL, N''EL GRULLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''321'', N''JAL'', 64, 32, NULL, N''EL LIMON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''322'', N''JAL'', 64, 32, NULL, N''CABO CORRIENTES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''322'', N''JAL'', 64, 32, NULL, N''PUERTO VALLARTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''322'', N''JAL'', 64, 32, NULL, N''SAN SEBASTIAN DEL OESTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''322'', N''JAL'', 64, 32, NULL, N''TOMATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''322'', N''NAY'', 64, 32, 1, N''BAHIA DE BANDERAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''323'', N''NAY'', 128, 64, NULL, N''SAN BLAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''323'', N''NAY'', 128, 64, NULL, N''SANTIA IXCUINTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''324'', N''NAY'', 128, 64, NULL, N''AHUACATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''324'', N''NAY'', 128, 64, NULL, N''AMATLAN DE CAÑAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''324'', N''NAY'', 128, 64, NULL, N''IXTLAN DEL RIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''324'', N''NAY'', 128, 64, NULL, N''JALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''325'', N''NAY'', 128, 64, NULL, N''ACAPONETA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''325'', N''NAY'', 128, 64, NULL, N''HUAJICORI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''326'', N''JAL'', 64, 32, NULL, N''ATEMAJAC DE BRIZUELA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''326'', N''JAL'', 64, 32, NULL, N''ZACOALCO DE TORRES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''327'', N''NAY'', 64, 32, 1, N''BAHIA DE BANDERAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''327'', N''NAY'', 128, 64, NULL, N''COMPOSTELA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''327'', N''NAY'', 128, 64, NULL, N''SAN BLAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''327'', N''NAY'', 128, 64, NULL, N''SAN PEDRO LAGUNILLAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''327'', N''NAY'', 128, 64, NULL, N''SANTA MARIA DEL ORO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''328'', N''MICH'', 64, 32, NULL, N''CHURINTZIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''328'', N''MICH'', 64, 32, NULL, N''ECUANDUREO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''328'', N''MICH'', 64, 32, NULL, N''IXTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''328'', N''MICH'', 64, 32, NULL, N''PAJACUARAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''328'', N''MICH'', 64, 32, NULL, N''VISTA HERMOSA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''329'', N''NAY'', 64, 32, 1, N''BAHIA DE BANDERAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''33'', N''JAL'', 64, 32, NULL, N''EL SALTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''33'', N''JAL'', 64, 32, NULL, N''GUADALAJARA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''33'', N''JAL'', 64, 32, NULL, N''JUANACATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''33'', N''JAL'', 64, 32, NULL, N''SAN PEDRO TLAQUEPAQUE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''33'', N''JAL'', 64, 32, NULL, N''TALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''33'', N''JAL'', 64, 32, NULL, N''TLAJOMULCO DE ZUNIGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''33'', N''JAL'', 64, 32, NULL, N''TLAQUEPAQUE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''33'', N''JAL'', 64, 32, NULL, N''TONALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''33'', N''JAL'', 64, 32, NULL, N''ZAPOPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''341'', N''JAL'', 64, 32, NULL, N''CIUDAD GUZMAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''341'', N''JAL'', 64, 32, NULL, N''MEZ FARIAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''341'', N''JAL'', 64, 32, NULL, N''ZAPOTILTIC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''341'', N''JAL'', 64, 32, NULL, N''ZAPOTLAN EL GRANDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''342'', N''JAL'', 64, 32, NULL, N''SAYULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''343'', N''JAL'', 64, 32, NULL, N''EJUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''343'', N''JAL'', 64, 32, NULL, N''SAN GABRIEL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''343'', N''JAL'', 64, 32, NULL, N''TAPALPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''343'', N''JAL'', 64, 32, NULL, N''TOLIMAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''343'', N''JAL'', 64, 32, NULL, N''TONAYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''343'', N''JAL'', 64, 32, NULL, N''TUXCACUESCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''343'', N''JAL'', 64, 32, NULL, N''ZAPOTITLAN DE VADILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''344'', N''JAL'', 64, 32, NULL, N''MEXTICACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''344'', N''JAL'', 64, 32, NULL, N''YAHUALICA DE NZALEZ GALLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''345'', N''JAL'', 64, 32, NULL, N''AYOTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''345'', N''JAL'', 64, 32, NULL, N''DELLADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''346'', N''JAL'', 64, 32, NULL, N''TEOCALTICHE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''346'', N''ZAC'', 64, 32, NULL, N''APULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''346'', N''ZAC'', 64, 32, NULL, N''NOCHISTLAN DE MEJIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''347'', N''JAL'', 64, 32, NULL, N''SAN JULIAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''347'', N''JAL'', 64, 32, NULL, N''SAN MIGUEL EL ALTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''347'', N''JAL'', 64, 32, NULL, N''VALLE DE GUADALUPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''348'', N''JAL'', 64, 32, NULL, N''ARANDAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''348'', N''JAL'', 64, 32, NULL, N''JESUS MARIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''349'', N''JAL'', 64, 32, NULL, N''ATEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''349'', N''JAL'', 64, 32, NULL, N''JUCHITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''349'', N''JAL'', 64, 32, NULL, N''TECOLOTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''349'', N''JAL'', 64, 32, NULL, N''TENAMAXTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''351'', N''MICH'', 64, 32, NULL, N''JACONA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''351'', N''MICH'', 64, 32, NULL, N''ZAMORA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''352'', N''GTO'', 64, 32, NULL, N''PENJAMO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''352'', N''MICH'', 64, 32, NULL, N''CHURINTZIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''352'', N''MICH'', 64, 32, NULL, N''LA PIEDAD'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''353'', N''MICH'', 64, 32, NULL, N''JIQUILPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''353'', N''MICH'', 64, 32, NULL, N''PAJACUARAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''353'', N''MICH'', 64, 32, NULL, N''SAHUAYO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''353'', N''MICH'', 64, 32, NULL, N''SAHUAYO DE MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''353'', N''MICH'', 64, 32, NULL, N''VENUSTIANO CARRANZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''353'', N''MICH'', 64, 32, NULL, N''VILLAMAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''354'', N''JAL'', 64, 32, NULL, N''MANUEL M. DIEGUEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''354'', N''JAL'', 64, 32, NULL, N''SANTA MARIA DEL ORO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''354'', N''MICH'', 64, 32, NULL, N''LOS REYES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''354'', N''MICH'', 64, 32, NULL, N''PERIBAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''354'', N''MICH'', 64, 32, NULL, N''TINGUINDIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''354'', N''MICH'', 64, 32, NULL, N''TOCUMBO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''354'', N''MICH'', 64, 32, NULL, N''URUAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''355'', N''MICH'', 64, 32, NULL, N''CHILCHOTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''355'', N''MICH'', 64, 32, NULL, N''TANGANCICUARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''356'', N''MICH'', 64, 32, NULL, N''TANHUATO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''356'', N''MICH'', 64, 32, NULL, N''YURECUARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''357'', N''JAL'', 64, 32, NULL, N''CASIMIRO CASTILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''357'', N''JAL'', 64, 32, NULL, N''CUAUTITLAN DE GARCIA BARRAGAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''357'', N''JAL'', 64, 32, NULL, N''LA HUERTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''357'', N''JAL'', 64, 32, NULL, N''VILLA PURIFICACION'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''358'', N''JAL'', 64, 32, NULL, N''TAMAZULA DE RDIANO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''359'', N''MICH'', 64, 32, NULL, N''NUMARAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''359'', N''MICH'', 64, 32, NULL, N''PENJAMILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''359'', N''MICH'', 64, 32, NULL, N''ZINAPARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''371'', N''JAL'', 64, 32, NULL, N''TECALITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''371'', N''JAL'', 64, 32, NULL, N''TUXPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''372'', N''JAL'', 64, 32, NULL, N''AMACUECA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''372'', N''JAL'', 64, 32, NULL, N''ATOYAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''372'', N''JAL'', 64, 32, NULL, N''CONCEPCION DE BUENOS AIRES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''372'', N''JAL'', 64, 32, NULL, N''LA MANZANILLA DE LA PAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''372'', N''JAL'', 64, 32, NULL, N''TECHALUTA DE MONTENEGRO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''372'', N''JAL'', 64, 32, NULL, N''TEOCUITATLAN DE CORONA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''373'', N''JAL'', 64, 32, NULL, N''CUQUIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''373'', N''JAL'', 64, 32, NULL, N''IXTLAHUACAN DEL RIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''373'', N''JAL'', 64, 32, NULL, N''SAN CRISTOBAL DE LA BARRANCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''373'', N''JAL'', 64, 32, NULL, N''ZAPOTLANEJO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''374'', N''JAL'', 64, 32, NULL, N''AMATITAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''374'', N''JAL'', 64, 32, NULL, N''ARENAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''374'', N''JAL'', 64, 32, NULL, N''TEQUILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''375'', N''JAL'', 64, 32, NULL, N''AMECA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''376'', N''JAL'', 64, 32, NULL, N''CHAPALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''376'', N''JAL'', 64, 32, NULL, N''IXTLAHUACAN DE LOS MEMBRILLOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''376'', N''JAL'', 64, 32, NULL, N''PONCITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''376'', N''JAL'', 64, 32, NULL, N''TIZAPAN EL ALTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''376'', N''JAL'', 64, 32, NULL, N''TUXCUECA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''377'', N''JAL'', 64, 32, NULL, N''COCULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''377'', N''JAL'', 64, 32, NULL, N''VILLA CORONA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''378'', N''JAL'', 64, 32, NULL, N''ACATIC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''378'', N''JAL'', 64, 32, NULL, N''TEPATITLAN DE MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''381'', N''MICH'', 64, 32, NULL, N''COJUMATLAN DE REGULES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''381'', N''MICH'', 64, 32, NULL, N''MARCOS CASTELLANOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''382'', N''JAL'', 64, 32, NULL, N''MAZAMITLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''382'', N''JAL'', 64, 32, NULL, N''QUITUPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''382'', N''JAL'', 64, 32, NULL, N''VALLE DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''383'', N''MICH'', 64, 32, NULL, N''CHAVINDA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''383'', N''MICH'', 64, 32, NULL, N''TANGAMANDAPIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''383'', N''MICH'', 64, 32, NULL, N''VILLAMAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''384'', N''JAL'', 64, 32, NULL, N''TALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''384'', N''JAL'', 64, 32, NULL, N''TEUCHITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''384'', N''JAL'', 64, 32, NULL, N''VILLA CORONA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''385'', N''JAL'', 64, 32, NULL, N''CHIQUILISTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''385'', N''JAL'', 64, 32, NULL, N''COCULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''385'', N''JAL'', 64, 32, NULL, N''SAN MARTIN HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''385'', N''JAL'', 64, 32, NULL, N''TECOLOTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''386'', N''JAL'', 64, 32, NULL, N''AHUALULCO DE MERCADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''386'', N''JAL'', 64, 32, NULL, N''ANTONIO ESCOBEDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''386'', N''JAL'', 64, 32, NULL, N''ETZATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''386'', N''JAL'', 64, 32, NULL, N''HOSTOTIPAQUILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''386'', N''JAL'', 64, 32, NULL, N''MAGDALENA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''386'', N''JAL'', 64, 32, NULL, N''SAN JUANITO DE ESCOBEDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''386'', N''JAL'', 64, 32, NULL, N''SAN MARCOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''387'', N''JAL'', 64, 32, NULL, N''ACATLAN DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''387'', N''JAL'', 64, 32, NULL, N''JOCOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''387'', N''JAL'', 64, 32, NULL, N''VILLA CORONA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''388'', N''JAL'', 64, 32, NULL, N''ATENGUILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''388'', N''JAL'', 64, 32, NULL, N''GUACHINAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''388'', N''JAL'', 64, 32, NULL, N''MASCOTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''388'', N''JAL'', 64, 32, NULL, N''MIXTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''388'', N''JAL'', 64, 32, NULL, N''TALPA DE ALLENDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''389'', N''NAY'', 128, 64, NULL, N''TECUALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''391'', N''JAL'', 64, 32, NULL, N''ATOTONILCO EL ALTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''391'', N''JAL'', 64, 32, NULL, N''PONCITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''391'', N''JAL'', 64, 32, NULL, N''TEPATITLAN DE MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''391'', N''JAL'', 64, 32, NULL, N''TOTOTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''391'', N''JAL'', 64, 32, NULL, N''ZAPOTLAN DEL REY'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''392'', N''JAL'', 64, 32, NULL, N''JAMAY'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''392'', N''JAL'', 64, 32, NULL, N''JESUS MARIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''392'', N''JAL'', 64, 32, NULL, N''OCOTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''393'', N''JAL'', 64, 32, NULL, N''LA BARCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''393'', N''MICH'', 64, 32, NULL, N''BRISEÑAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''394'', N''MICH'', 64, 32, NULL, N''COTIJA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''395'', N''JAL'', 64, 32, NULL, N''SAN DIE DE ALEJANDRIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''395'', N''JAL'', 64, 32, NULL, N''SAN JUAN DE LOS LAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''395'', N''JAL'', 64, 32, NULL, N''UNION DE SAN ANTONIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''411'', N''GTO'', 64, 32, NULL, N''CORTAZAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''411'', N''GTO'', 64, 32, NULL, N''JARAL DEL PROGRESO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''411'', N''GTO'', 64, 32, NULL, N''VILLAGRAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''411'', N''GTO'', 64, 32, NULL, N''YURIRIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''412'', N''GTO'', 64, 32, NULL, N''COMONFORT'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''412'', N''GTO'', 64, 32, NULL, N''SANTA CRUZ DE JUVENTINO ROSAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''413'', N''GTO'', 64, 32, NULL, N''APASEO EL ALTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''413'', N''GTO'', 64, 32, NULL, N''APASEO EL GRANDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''414'', N''QRO'', 64, 32, NULL, N''TEQUISQUIAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''415'', N''GTO'', 64, 32, NULL, N''ALLENDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''415'', N''GTO'', 64, 32, NULL, N''SAN MIGUEL DE ALLENDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''417'', N''GTO'', 64, 32, NULL, N''ACAMBARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''418'', N''GTO'', 64, 32, NULL, N''DOLORES HIDALGO'')';
		EXEC(@sql);
SET @process = 'Actualizar tabla ZonasHorarias'
		SET @sql = '

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''418'', N''GTO'', 64, 32, NULL, N''DOLORES HIDALGO CUNA DE LA INDEPENDENCIA NACIONAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''418'', N''GTO'', 64, 32, NULL, N''SAN DIE DE LA UNION'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''419'', N''GTO'', 64, 32, NULL, N''DOCTOR MORA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''419'', N''GTO'', 64, 32, NULL, N''DR. MORA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''419'', N''GTO'', 64, 32, NULL, N''SAN JOSE ITURBIDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''419'', N''GTO'', 64, 32, NULL, N''SANTA CATARINA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''419'', N''GTO'', 64, 32, NULL, N''TIERRA BLANCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''419'', N''GTO'', 64, 32, NULL, N''VICTORIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''419'', N''GTO'', 64, 32, NULL, N''XICHU'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''419'', N''QRO'', 64, 32, NULL, N''COLON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''421'', N''GTO'', 64, 32, NULL, N''CORONEO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''421'', N''GTO'', 64, 32, NULL, N''JERECUARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''421'', N''GTO'', 64, 32, NULL, N''TARANDACUAO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''421'', N''MICH'', 64, 32, NULL, N''EPITACIO HUERTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''422'', N''MICH'', 64, 32, NULL, N''ARIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''422'', N''MICH'', 64, 32, NULL, N''GABRIEL ZAMORA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''422'', N''MICH'', 64, 32, NULL, N''NUEVO URECHO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''422'', N''MICH'', 64, 32, NULL, N''TARETAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''423'', N''MICH'', 64, 32, NULL, N''CHARAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''423'', N''MICH'', 64, 32, NULL, N''CHERAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''423'', N''MICH'', 64, 32, NULL, N''NAHUATZEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''423'', N''MICH'', 64, 32, NULL, N''PARACHO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''423'', N''MICH'', 64, 32, NULL, N''TINGAMBATO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''423'', N''MICH'', 64, 32, NULL, N''ZIRACUARETIRO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''424'', N''JAL'', 64, 32, NULL, N''JILOTLAN DE LOS DOLORES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''424'', N''MICH'', 64, 32, NULL, N''AGUILILLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''424'', N''MICH'', 64, 32, NULL, N''AQUILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''424'', N''MICH'', 64, 32, NULL, N''CHINICUILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''424'', N''MICH'', 64, 32, NULL, N''COALCOMAN DE VAZQUEZ PALLARES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''424'', N''MICH'', 64, 32, NULL, N''TEPALCATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''425'', N''MICH'', 64, 32, NULL, N''CHURUMUCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''425'', N''MICH'', 64, 32, NULL, N''LA HUACANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''425'', N''MICH'', 64, 32, NULL, N''MUGICA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''425'', N''MICH'', 64, 32, NULL, N''PARACUARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''425'', N''MICH'', 64, 32, NULL, N''TANCITARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''426'', N''MICH'', 64, 32, NULL, N''AGUILILLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''426'', N''MICH'', 64, 32, NULL, N''BUENAVISTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''427'', N''MEX'', 64, 32, NULL, N''POLOTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''427'', N''QRO'', 64, 32, NULL, N''SAN JUAN DEL RIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''428'', N''GTO'', 64, 32, NULL, N''OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''428'', N''GTO'', 64, 32, NULL, N''SAN FELIPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''429'', N''GTO'', 64, 32, NULL, N''ABASOLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''429'', N''GTO'', 64, 32, NULL, N''CUERAMARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''429'', N''GTO'', 64, 32, NULL, N''HUANIMARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''429'', N''GTO'', 64, 32, NULL, N''PUEBLO NUEVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''431'', N''JAL'', 64, 32, NULL, N''CA?ADAS DE OBREN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''431'', N''JAL'', 64, 32, NULL, N''JALOSTOTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''432'', N''GTO'', 64, 32, NULL, N''MANUEL DOBLADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''432'', N''GTO'', 64, 32, NULL, N''ROMITA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''433'', N''ZAC'', 64, 32, NULL, N''MIGUEL AUZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''433'', N''ZAC'', 64, 32, NULL, N''SOMBRERETE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''434'', N''MICH'', 64, 32, NULL, N''ACUITZIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''434'', N''MICH'', 64, 32, NULL, N''ERONGARICUARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''434'', N''MICH'', 64, 32, NULL, N''HUIRAMBA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''434'', N''MICH'', 64, 32, NULL, N''LAGUNILLAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''434'', N''MICH'', 64, 32, NULL, N''PATZCUARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''434'', N''MICH'', 64, 32, NULL, N''SALVADOR ESCALANTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''434'', N''MICH'', 64, 32, NULL, N''TZINTZUNTZAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''435'', N''MICH'', 64, 32, NULL, N''HUETAMO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''435'', N''MICH'', 64, 32, NULL, N''SAN LUCAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''436'', N''MICH'', 64, 32, NULL, N''ZACAPU'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''437'', N''JAL'', 64, 32, NULL, N''BOLAÑOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''437'', N''JAL'', 64, 32, NULL, N''CHIMALTITAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''437'', N''JAL'', 64, 32, NULL, N''SAN MARTIN DE BOLA?OS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''437'', N''JAL'', 64, 32, NULL, N''TOTATICHE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''437'', N''JAL'', 64, 32, NULL, N''VILLA GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''437'', N''NAY'', 128, 64, NULL, N''LA YESCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''437'', N''ZAC'', 64, 32, NULL, N''ATOLINGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''437'', N''ZAC'', 64, 32, NULL, N''MOMAX'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''437'', N''ZAC'', 64, 32, NULL, N''TEPECHITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''437'', N''ZAC'', 64, 32, NULL, N''TLALTENANGO DE SANCHEZ ROMAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''438'', N''GTO'', 64, 32, NULL, N''YURIRIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''438'', N''MICH'', 64, 32, NULL, N''JOSE SIXTO VERDUZCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''438'', N''MICH'', 64, 32, NULL, N''MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''438'', N''MICH'', 64, 32, NULL, N''PURUANDIRO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''441'', N''HGO'', 64, 32, NULL, N''JACALA DE LEDEZMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''441'', N''QRO'', 64, 32, NULL, N''ARROYO SECO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''441'', N''QRO'', 64, 32, NULL, N''CADEREYTA DE MONTES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''441'', N''QRO'', 64, 32, NULL, N''EZEQUIEL MONTES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''441'', N''QRO'', 64, 32, NULL, N''JALPAN DE SERRA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''441'', N''QRO'', 64, 32, NULL, N''LANDA DE MATAMOROS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''441'', N''QRO'', 64, 32, NULL, N''PEÑAMILLER'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''441'', N''QRO'', 64, 32, NULL, N''PINAL DE AMOLES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''441'', N''QRO'', 64, 32, NULL, N''SAN JOAQUIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''441'', N''QRO'', 64, 32, NULL, N''TOLIMAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''442'', N''GTO'', 64, 32, NULL, N''APASEO EL GRANDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''442'', N''GTO'', 64, 32, NULL, N''SAN LUIS DE LA PAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''442'', N''QRO'', 64, 32, NULL, N''CORREGIDORA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''442'', N''QRO'', 64, 32, NULL, N''EL MARQUES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''442'', N''QRO'', 64, 32, NULL, N''QUERETARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''443'', N''MICH'', 64, 32, NULL, N''CHUCANDIRO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''443'', N''MICH'', 64, 32, NULL, N''CONTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''443'', N''MICH'', 64, 32, NULL, N''MARAVATIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''443'', N''MICH'', 64, 32, NULL, N''MORELIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''443'', N''MICH'', 64, 32, NULL, N''TARIMBARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''444'', N''SLP'', 64, 32, NULL, N''AHUALULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''444'', N''SLP'', 64, 32, NULL, N''MEXQUITIC DE CARMONA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''444'', N''SLP'', 64, 32, NULL, N''SAN LUIS POTOSI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''444'', N''SLP'', 64, 32, NULL, N''SOLEDAD DE GRACIANO SANCHEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''444'', N''SLP'', 64, 32, NULL, N''ZARAGOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''445'', N''GTO'', 64, 32, NULL, N''MOROLEON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''445'', N''GTO'', 64, 32, NULL, N''URIANGATO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''445'', N''GTO'', 64, 32, NULL, N''YURIRIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''447'', N''MICH'', 64, 32, NULL, N''CONTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''447'', N''MICH'', 64, 32, NULL, N''MARAVATIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''448'', N''QRO'', 64, 32, NULL, N''AMEALCO DE BONFIL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''448'', N''QRO'', 64, 32, NULL, N''HUIMILPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''448'', N''QRO'', 64, 32, NULL, N''PEDRO ESCOBEDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''449'', N''AGS'', 64, 32, NULL, N''AGUASCALIENTES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''449'', N''AGS'', 64, 32, NULL, N''JESUS MARIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''451'', N''MICH'', 64, 32, NULL, N''CHARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''451'', N''MICH'', 64, 32, NULL, N''INDAPARAPEO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''451'', N''MICH'', 64, 32, NULL, N''QUERENDARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''451'', N''MICH'', 64, 32, NULL, N''ZINAPECUARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''452'', N''MICH'', 64, 32, NULL, N''NUEVO PARANGARICUTIRO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''452'', N''MICH'', 64, 32, NULL, N''TUMBISCATIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''452'', N''MICH'', 64, 32, NULL, N''URUAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''453'', N''MICH'', 64, 32, NULL, N''APATZINGAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''453'', N''MICH'', 64, 32, NULL, N''TANCITARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''454'', N''MICH'', 64, 32, NULL, N''ANGAMACUTIRO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''454'', N''MICH'', 64, 32, NULL, N''COENEO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''454'', N''MICH'', 64, 32, NULL, N''COPANDARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''454'', N''MICH'', 64, 32, NULL, N''HUANIQUEO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''454'', N''MICH'', 64, 32, NULL, N''JIMENEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''454'', N''MICH'', 64, 32, NULL, N''PANINDICUARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''454'', N''MICH'', 64, 32, NULL, N''QUIROGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''455'', N''MICH'', 64, 32, NULL, N''ALVARO OBREN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''455'', N''MICH'', 64, 32, NULL, N''CUITZEO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''455'', N''MICH'', 64, 32, NULL, N''HUANDACAREO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''455'', N''MICH'', 64, 32, NULL, N''SANTA ANA MAYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''456'', N''GTO'', 64, 32, NULL, N''VALLE DE SANTIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''457'', N''JAL'', 64, 32, NULL, N''HUEJUCAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''457'', N''JAL'', 64, 32, NULL, N''HUEJUQUILLA EL ALTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''457'', N''JAL'', 64, 32, NULL, N''MEZQUITIC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''457'', N''ZAC'', 64, 32, NULL, N''CHALCHIHUITES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''457'', N''ZAC'', 64, 32, NULL, N''JIMENEZ DEL TEUL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''457'', N''ZAC'', 64, 32, NULL, N''MONTE ESCOBEDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''457'', N''ZAC'', 64, 32, NULL, N''VALPARAISO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''458'', N''AGS'', 64, 32, NULL, N''COSIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''458'', N''SLP'', 64, 32, NULL, N''SANTO DOMIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''458'', N''SLP'', 64, 32, NULL, N''VILLA DE RAMOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''458'', N''ZAC'', 64, 32, NULL, N''CAÑITAS DE FELIPE PESCADOR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''458'', N''ZAC'', 64, 32, NULL, N''CUAUHTEMOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''458'', N''ZAC'', 64, 32, NULL, N''GENARO CODINA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''458'', N''ZAC'', 64, 32, NULL, N''GENERAL PANFILO NATERA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''458'', N''ZAC'', 64, 32, NULL, N''LUIS MOYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''458'', N''ZAC'', 64, 32, NULL, N''OJOCALIENTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''458'', N''ZAC'', 64, 32, NULL, N''VILLA DE COS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''459'', N''MICH'', 64, 32, NULL, N''CARACUARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''459'', N''MICH'', 64, 32, NULL, N''MADERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''459'', N''MICH'', 64, 32, NULL, N''NOCUPETARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''459'', N''MICH'', 64, 32, NULL, N''TACAMBARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''459'', N''MICH'', 64, 32, NULL, N''TIQUICHEO DE NICOLAS ROMERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''459'', N''MICH'', 64, 32, NULL, N''TURICATO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''459'', N''MICH'', 64, 32, NULL, N''TZITZIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''461'', N''GTO'', 64, 32, NULL, N''CELAYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''461'', N''GTO'', 64, 32, NULL, N''JERECUARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''462'', N''GTO'', 64, 32, NULL, N''IRAPUATO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''462'', N''GTO'', 64, 32, NULL, N''VALLE DE SANTIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''463'', N''ZAC'', 64, 32, NULL, N''HUANUSCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''463'', N''ZAC'', 64, 32, NULL, N''JALPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''463'', N''ZAC'', 64, 32, NULL, N''TABASCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''464'', N''GTO'', 64, 32, NULL, N''SALAMANCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''465'', N''AGS'', 64, 32, NULL, N''PABELLON DE ARTEAGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''465'', N''AGS'', 64, 32, NULL, N''RINCON DE ROMOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''465'', N''AGS'', 64, 32, NULL, N''SAN FRANCISCO DE LOS ROMO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''465'', N''AGS'', 64, 32, NULL, N''SAN JOSE DE GRACIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''465'', N''AGS'', 64, 32, NULL, N''TEPEZALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''466'', N''GTO'', 64, 32, NULL, N''SALVATIERRA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''466'', N''GTO'', 64, 32, NULL, N''SANTIA MARAVATIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''466'', N''GTO'', 64, 32, NULL, N''TARIMORO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''467'', N''ZAC'', 64, 32, NULL, N''APOZOL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''467'', N''ZAC'', 64, 32, NULL, N''BENITO JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''467'', N''ZAC'', 64, 32, NULL, N''JUCHIPILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''467'', N''ZAC'', 64, 32, NULL, N''MEZQUITAL DEL ORO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''467'', N''ZAC'', 64, 32, NULL, N''MOYAHUA DE ESTRADA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''467'', N''ZAC'', 64, 32, NULL, N''TEUL DE NZALEZ ORTEGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''467'', N''ZAC'', 64, 32, NULL, N''TRINIDAD GARCIA DE LA CADENA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''468'', N''GTO'', 64, 32, NULL, N''SAN LUIS DE LA PAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''469'', N''GTO'', 64, 32, NULL, N''PENJAMO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''471'', N''MICH'', 64, 32, NULL, N''PUREPERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''471'', N''MICH'', 64, 32, NULL, N''TLAZAZALCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''472'', N''GTO'', 64, 32, NULL, N''SILAO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''472'', N''GTO'', 64, 32, NULL, N''SILAO DE VICTORIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''473'', N''GTO'', 64, 32, NULL, N''GUANAJUATO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''474'', N''JAL'', 64, 32, NULL, N''LAS DE MORENO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''474'', N''JAL'', 64, 32, NULL, N''OJUELOS DE JALISCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''474'', N''JAL'', 64, 32, NULL, N''SAN MIGUEL EL ALTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''475'', N''JAL'', 64, 32, NULL, N''ENCARNACION DE DIAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''476'', N''GTO'', 64, 32, NULL, N''PURISIMA DEL RINCON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''476'', N''GTO'', 64, 32, NULL, N''SAN FRANCISCO DEL RINCON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''477'', N''GTO'', 64, 32, NULL, N''LEON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''478'', N''ZAC'', 64, 32, NULL, N''CALERA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''478'', N''ZAC'', 64, 32, NULL, N''GENERAL ENRIQUE ESTRADA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''478'', N''ZAC'', 64, 32, NULL, N''PANUCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''481'', N''SLP'', 64, 32, NULL, N''CIUDAD VALLES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''482'', N''SLP'', 64, 32, NULL, N''ALAQUINES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''482'', N''SLP'', 64, 32, NULL, N''AQUISMON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''482'', N''SLP'', 64, 32, NULL, N''CIUDAD DEL MAIZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''482'', N''SLP'', 64, 32, NULL, N''EL NARANJO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''482'', N''SLP'', 64, 32, NULL, N''HUEHUETLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''482'', N''SLP'', 64, 32, NULL, N''TAMASOPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''482'', N''SLP'', 64, 32, NULL, N''TANCANHUITZ DE SANTOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''482'', N''TAMPS'', 64, 32, NULL, N''NUEVO MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''483'', N''HGO'', 64, 32, NULL, N''CHAPULHUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''483'', N''HGO'', 64, 32, NULL, N''HUEJUTLA DE REYES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''483'', N''HGO'', 64, 32, NULL, N''PISAFLORES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''483'', N''HGO'', 64, 32, NULL, N''SAN FELIPE ORIZATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''483'', N''SLP'', 64, 32, NULL, N''MATLAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''483'', N''SLP'', 64, 32, NULL, N''SAN MARTIN CALCHICUAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''483'', N''SLP'', 64, 32, NULL, N''TAMAZUNCHALE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''483'', N''SLP'', 64, 32, NULL, N''TAMPACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''485'', N''SLP'', 64, 32, NULL, N''SANTA MARIA DEL RIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''485'', N''SLP'', 64, 32, NULL, N''STA MARIA DEL RIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''485'', N''SLP'', 64, 32, NULL, N''TIERRANUEVA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''485'', N''SLP'', 64, 32, NULL, N''VILLA DE ARRIAGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''485'', N''SLP'', 64, 32, NULL, N''VILLA DE REYES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''486'', N''SLP'', 64, 32, NULL, N''ARMADILLO DE LOS INFANTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''486'', N''SLP'', 64, 32, NULL, N''CERRITOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''486'', N''SLP'', 64, 32, NULL, N''CHARCAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''486'', N''SLP'', 64, 32, NULL, N''GUADALCAZAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''486'', N''SLP'', 64, 32, NULL, N''MOCTEZUMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''486'', N''SLP'', 64, 32, NULL, N''SAN NICOLAS TOLENTINO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''486'', N''SLP'', 64, 32, NULL, N''VENADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''486'', N''SLP'', 64, 32, NULL, N''VILLA DE ARISTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''486'', N''SLP'', 64, 32, NULL, N''VILLA DE GUADALUPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''486'', N''SLP'', 64, 32, NULL, N''VILLA HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''486'', N''SLP'', 64, 32, NULL, N''VILLA JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''487'', N''QRO'', 64, 32, NULL, N''ARROYO SECO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''487'', N''SLP'', 64, 32, NULL, N''CARDENAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''487'', N''SLP'', 64, 32, NULL, N''CIUDAD FERNANDEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''487'', N''SLP'', 64, 32, NULL, N''LAGUNILLAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''487'', N''SLP'', 64, 32, NULL, N''RAYON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''487'', N''SLP'', 64, 32, NULL, N''RIO VERDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''487'', N''SLP'', 64, 32, NULL, N''RIOVERDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''487'', N''SLP'', 64, 32, NULL, N''SAN CIRO DE ACOSTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''488'', N''NL'', 64, 32, NULL, N''DOCTOR ARROYO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''488'', N''NL'', 64, 32, NULL, N''MIER Y NORIEGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''488'', N''SLP'', 64, 32, NULL, N''CATORCE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''488'', N''SLP'', 64, 32, NULL, N''CEDRAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''488'', N''SLP'', 64, 32, NULL, N''MATEHUALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''488'', N''SLP'', 64, 32, NULL, N''VENEGAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''488'', N''SLP'', 64, 32, NULL, N''VILLA DE LA PAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''489'', N''SLP'', 64, 32, NULL, N''AXTLA DE TERRAZAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''489'', N''SLP'', 64, 32, NULL, N''COXCATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''489'', N''SLP'', 64, 32, NULL, N''SAN ANTONIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''489'', N''SLP'', 64, 32, NULL, N''SAN VICENTE TANCUAYALAB'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''489'', N''SLP'', 64, 32, NULL, N''TAMPAMOLON CORONA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''489'', N''SLP'', 64, 32, NULL, N''TAMUIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''489'', N''SLP'', 64, 32, NULL, N''TANLAJAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''489'', N''SLP'', 64, 32, NULL, N''TANQUIAN DE ESCOBEDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''489'', N''SLP'', 64, 32, NULL, N''XILITLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''489'', N''VER'', 64, 32, NULL, N''EL HI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''492'', N''ZAC'', 64, 32, NULL, N''GUADALUPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''492'', N''ZAC'', 64, 32, NULL, N''MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''492'', N''ZAC'', 64, 32, NULL, N''TRONCOSO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''492'', N''ZAC'', 64, 32, NULL, N''VETAGRANDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''492'', N''ZAC'', 64, 32, NULL, N''ZACATECAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''493'', N''ZAC'', 64, 32, NULL, N''FRESNILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''494'', N''ZAC'', 64, 32, NULL, N''JEREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''494'', N''ZAC'', 64, 32, NULL, N''JEREZ DE GARCIA SALINAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''494'', N''ZAC'', 64, 32, NULL, N''SUSTICACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''494'', N''ZAC'', 64, 32, NULL, N''TEPETON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''495'', N''AGS'', 64, 32, NULL, N''CALVILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''495'', N''JAL'', 64, 32, NULL, N''VILLA HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''496'', N''AGS'', 64, 32, NULL, N''ASIENTOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''496'', N''AGS'', 64, 32, NULL, N''EL LLANO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''496'', N''JAL'', 64, 32, NULL, N''OJUELOS DE JALISCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''496'', N''SLP'', 64, 32, NULL, N''SALINAS DE HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''496'', N''ZAC'', 64, 32, NULL, N''LORETO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''496'', N''ZAC'', 64, 32, NULL, N''NORIA DE ANGELES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''496'', N''ZAC'', 64, 32, NULL, N''PINOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''496'', N''ZAC'', 64, 32, NULL, N''VILLA NZALEZ ORTEGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''496'', N''ZAC'', 64, 32, NULL, N''VILLA HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''498'', N''ZAC'', 64, 32, NULL, N''FRANCISCO R MURGUIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''498'', N''ZAC'', 64, 32, NULL, N''JUAN ALDAMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''498'', N''ZAC'', 64, 32, NULL, N''RIO GRANDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''498'', N''ZAC'', 64, 32, NULL, N''SAIN ALTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''499'', N''JAL'', 64, 32, NULL, N''COLOTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''499'', N''JAL'', 64, 32, NULL, N''SANTA MARIA DE LOS ANGELES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''499'', N''ZAC'', 64, 32, NULL, N''VILLANUEVA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''ALVARO OBREN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''AZCAPOTZALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''BENITO JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''COYOACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''CUAJIMALPA DE MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''CUAUHTEMOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''GUSTAVO A. MADERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''IZTACALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''IZTAPALAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''LA MAGDALENA CONTRERAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''MIGUEL HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''MILPA ALTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''TLAHUAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''TLALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''VENUSTIANO CARRANZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''CDMX'', 64, 32, NULL, N''XOCHIMILCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''ACOLMAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''ATIZAPAN DE ZARAGOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''CHALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''CHICOLOAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''CHIMALHUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''COACALCO DE BERRIOZABAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''COCOTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''CUAUTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''CUAUTITLAN IZCALLI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''ECATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''ECATEPEC DE MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''HUIXQUILUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''ISIDRO FABELA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''IXTAPALUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''JALTENCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''JILOTZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''LA PAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''LERMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''MELCHOR OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''NAUCALPAN DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''NEXTLALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''NEZAHUALCOYOTL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''NICOLAS ROMERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''TECAMAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''TEMAMATLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''TEPOTZOTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''TLALNEPANTLA DE BAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''TULTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''TULTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''55'', N''MEX'', 64, 32, NULL, N''VALLE DE CHALCO SOLIDARIDAD'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''588'', N''MEX'', 64, 32, NULL, N''CHAPA DE MOTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''588'', N''MEX'', 64, 32, NULL, N''VILLA DEL CARBON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''591'', N''HGO'', 64, 32, NULL, N''ATOTONILCO DE TULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''591'', N''MEX'', 64, 32, NULL, N''TECAMAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''591'', N''MEX'', 64, 32, NULL, N''TEQUIXQUIAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''591'', N''MEX'', 64, 32, NULL, N''ZUMPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''592'', N''MEX'', 64, 32, NULL, N''AXAPUSCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''592'', N''MEX'', 64, 32, NULL, N''NOPALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''592'', N''MEX'', 64, 32, NULL, N''OTUMBA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''593'', N''MEX'', 64, 32, NULL, N''COYOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''593'', N''MEX'', 64, 32, NULL, N''HUEHUETOCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''593'', N''MEX'', 64, 32, NULL, N''TEOLOYUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''594'', N''MEX'', 64, 32, NULL, N''ACOLMAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''594'', N''MEX'', 64, 32, NULL, N''SAN MARTIN DE LAS PIRAMIDES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''594'', N''MEX'', 64, 32, NULL, N''TEOTIHUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''594'', N''MEX'', 64, 32, NULL, N''TEZOYUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''595'', N''MEX'', 64, 32, NULL, N''ATENCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''595'', N''MEX'', 64, 32, NULL, N''CHIAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''595'', N''MEX'', 64, 32, NULL, N''CHICONCUAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''595'', N''MEX'', 64, 32, NULL, N''PAPALOTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''595'', N''MEX'', 64, 32, NULL, N''TEPETLAOXTOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''595'', N''MEX'', 64, 32, NULL, N''TEXCOCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''596'', N''MEX'', 64, 32, NULL, N''TECAMAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''596'', N''MEX'', 64, 32, NULL, N''TEMASCALAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''597'', N''MEX'', 64, 32, NULL, N''AMECAMECA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''597'', N''MEX'', 64, 32, NULL, N''ATLAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''597'', N''MEX'', 64, 32, NULL, N''AYAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''597'', N''MEX'', 64, 32, NULL, N''ECATZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''597'', N''MEX'', 64, 32, NULL, N''JUCHITEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''597'', N''MEX'', 64, 32, NULL, N''OZUMBA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''597'', N''MEX'', 64, 32, NULL, N''TENAN DEL AIRE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''597'', N''MEX'', 64, 32, NULL, N''TEPETLIXPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''597'', N''MEX'', 64, 32, NULL, N''TLALMANALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''599'', N''MEX'', 64, 32, NULL, N''APAXCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''599'', N''MEX'', 64, 32, NULL, N''HUEYPOXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''599'', N''MEX'', 64, 32, NULL, N''TEQUIXQUIAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''612'', N''BCS'', 128, 64, NULL, N''LA PAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''613'', N''BCS'', 128, 64, NULL, N''COMONDU'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''613'', N''BCS'', 128, 64, NULL, N''LORETO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''614'', N''CHIH'', 128, 64, NULL, N''ALADAMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''614'', N''CHIH'', 128, 64, NULL, N''ALDAMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''614'', N''CHIH'', 128, 64, NULL, N''AQUILES SERDAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''614'', N''CHIH'', 128, 64, NULL, N''CHIHUAHUA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''614'', N''CHIH'', 128, 64, NULL, N''RIVA PALACIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''614'', N''CHIH'', 128, 64, NULL, N''SANTA ISABEL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''614'', N''CHIH'', 128, 64, NULL, N''SATEVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''615'', N''BCS'', 128, 64, NULL, N''MULEGE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''616'', N''BC'', 256, 128, NULL, N''ENSENADA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''618'', N''DGO'', 64, 32, NULL, N''DURAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''621'', N''CHIH'', 128, 64, NULL, N''JULIMES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''621'', N''CHIH'', 128, 64, NULL, N''SAUCILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''622'', N''SON'', 128, 128, NULL, N''EMPALME'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''622'', N''SON'', 128, 128, NULL, N''GUAYMAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''ACONCHI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''BANAMICHI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''BAVIACORA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''CARBO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''HUEPAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''LA COLORADA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''MAZATAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''RAYON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''SAN MIGUEL HORCASITAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''SAN PEDRO DE LA CUEVA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''URES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''VILLA PESQUEIRA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''YECORA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''624'', N''BCS'', 128, 64, NULL, N''LA PAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''624'', N''BCS'', 128, 64, NULL, N''LOS CABOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''625'', N''CHIH'', 128, 64, NULL, N''CUAUHTEMOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''625'', N''CHIH'', 128, 64, NULL, N''CUSIHUIRIACHI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''625'', N''CHIH'', 128, 64, NULL, N''DOCTOR BELISARIO DOMINGUEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''625'', N''CHIH'', 128, 64, NULL, N''GRAN MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''626'', N''CHIH'', 128, 64, NULL, N''COYAME'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''626'', N''CHIH'', 128, 64, NULL, N''COYAME DEL SOTOL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''626'', N''CHIH'', 128, 64, NULL, N''MANUEL BENAVIDES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''626'', N''CHIH'', 128, 64, NULL, N''OJINAGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''627'', N''CHIH'', 128, 64, NULL, N''HIDALGO DEL PARRAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''628'', N''CHIH'', 128, 64, NULL, N''ALLENDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''628'', N''CHIH'', 128, 64, NULL, N''MATAMOROS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''628'', N''CHIH'', 128, 64, NULL, N''SAN FRANCISCO DEL ORO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''628'', N''CHIH'', 128, 64, NULL, N''SANTA BARBARA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''629'', N''CHIH'', 128, 64, NULL, N''CORONADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''629'', N''CHIH'', 128, 64, NULL, N''JIMENEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''629'', N''CHIH'', 128, 64, NULL, N''LOPEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''629'', N''DGO'', 64, 32, NULL, N''HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''629'', N''DGO'', 64, 32, NULL, N''MAPIMI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''631'', N''SON'', 128, 128, NULL, N''NOGALES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''632'', N''SON'', 128, 128, NULL, N''IMURIS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''632'', N''SON'', 128, 128, NULL, N''MAGDALENA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''632'', N''SON'', 128, 128, NULL, N''MAGDALENA DE KINO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''633'', N''SON'', 128, 128, NULL, N''AGUA PRIETA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''633'', N''SON'', 128, 128, NULL, N''FRONTERAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''633'', N''SON'', 128, 128, NULL, N''NACO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''ARIVECHI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''ARIZPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''BACADEHUACHI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''BACANORA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''BACERAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''BAVISPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''CUMPAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''DIVISADEROS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''HUACHINERA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''HUASABAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''MOCTEZUMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''NACORI CHICO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''NACOZARI DE GARCIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''SAHUARIPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''SUAQUI GRANDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''TEPACHE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''634'', N''SON'', 128, 128, NULL, N''VILLA HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''635'', N''CHIH'', 128, 64, NULL, N''BOCOYNA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''635'', N''CHIH'', 128, 64, NULL, N''CARICHI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''635'', N''CHIH'', 128, 64, NULL, N''CHINIPAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''635'', N''CHIH'', 128, 64, NULL, N''GUAZAPARES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''635'', N''CHIH'', 128, 64, NULL, N''GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''635'', N''CHIH'', 128, 64, NULL, N''MORIS'')';
EXEC(@sql);
SET @process = 'SPEC-75 Actualiza tabla ZonasHorarias'
		SET @sql = '

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''635'', N''CHIH'', 128, 64, NULL, N''NONOAVA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''635'', N''CHIH'', 128, 64, NULL, N''OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''635'', N''CHIH'', 128, 64, NULL, N''SAN FRANCISCO DE BORJA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''635'', N''CHIH'', 128, 64, NULL, N''URIQUE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''635'', N''CHIH'', 128, 64, NULL, N''URUACHI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''636'', N''CHIH'', 128, 64, NULL, N''ASCENSION'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''636'', N''CHIH'', 128, 64, NULL, N''BUENAVENTURA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''636'', N''CHIH'', 128, 64, NULL, N''CASAS GRANDES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''636'', N''CHIH'', 128, 64, NULL, N''GALEANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''636'', N''CHIH'', 128, 64, NULL, N''IGNACIO ZARAGOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''636'', N''CHIH'', 128, 64, NULL, N''JANOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''636'', N''CHIH'', 128, 64, NULL, N''NUEVO CASAS GRANDES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''637'', N''SON'', 128, 128, NULL, N''ALTAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''637'', N''SON'', 128, 128, NULL, N''ATIL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''637'', N''SON'', 128, 128, NULL, N''CABORCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''637'', N''SON'', 128, 128, NULL, N''PITIQUITO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''637'', N''SON'', 128, 128, NULL, N''SARIC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''637'', N''SON'', 128, 128, NULL, N''TUBUTAMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''638'', N''SON'', 128, 128, NULL, N''PUERTO PEÑASCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''638'', N''SON'', 128, 128, NULL, N''PUERTO PEÑASCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''639'', N''CHIH'', 128, 64, NULL, N''DELICIAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''639'', N''CHIH'', 128, 64, NULL, N''MEOQUI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''639'', N''CHIH'', 128, 64, NULL, N''ROSALES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''639'', N''CHIH'', 128, 64, NULL, N''SAUCILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''641'', N''SON'', 128, 128, NULL, N''BENJAMIN HILL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''641'', N''SON'', 128, 128, NULL, N''OPODEPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''641'', N''SON'', 128, 128, NULL, N''SANTA ANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''641'', N''SON'', 128, 128, NULL, N''TRINCHERAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''642'', N''SON'', 128, 128, NULL, N''NAVOJOA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''643'', N''SON'', 128, 128, NULL, N''BACUM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''643'', N''SON'', 128, 128, NULL, N''BENITO JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''643'', N''SON'', 128, 128, NULL, N''CAJEME'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''643'', N''SON'', 128, 128, NULL, N''ETCHOJOA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''643'', N''SON'', 128, 128, NULL, N''GUAYMAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''643'', N''SON'', 128, 128, NULL, N''SAN IGNACIO RIO MUERTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''644'', N''SON'', 128, 128, NULL, N''BACUM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''644'', N''SON'', 128, 128, NULL, N''BENITO JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''644'', N''SON'', 128, 128, NULL, N''CAJEME'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''645'', N''SON'', 128, 128, NULL, N''BACOACHI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''645'', N''SON'', 128, 128, NULL, N''CANANEA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''645'', N''SON'', 128, 128, NULL, N''SANTA CRUZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''646'', N''BC'', 256, 128, NULL, N''ENSENADA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''646'', N''BC'', 256, 128, NULL, N''TECATE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''647'', N''SON'', 128, 128, NULL, N''ALAMOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''647'', N''SON'', 128, 128, NULL, N''ETCHOJOA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''647'', N''SON'', 128, 128, NULL, N''HUATABAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''647'', N''SON'', 128, 128, NULL, N''HUTABAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''647'', N''SON'', 128, 128, NULL, N''QUIRIE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''647'', N''SON'', 128, 128, NULL, N''ROSARIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''648'', N''CHIH'', 128, 64, NULL, N''CAMARGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''648'', N''CHIH'', 128, 64, NULL, N''LA CRUZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''648'', N''CHIH'', 128, 64, NULL, N''SAN FRANCISCO DE CONCHOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''649'', N''CHIH'', 128, 64, NULL, N''BALLEZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''649'', N''CHIH'', 128, 64, NULL, N''BATOPILAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''649'', N''CHIH'', 128, 64, NULL, N''EL TULE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''649'', N''CHIH'', 128, 64, NULL, N''GUACHOCHI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''649'', N''CHIH'', 128, 64, NULL, N''GUADALUPE Y CALVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''649'', N''CHIH'', 128, 64, NULL, N''VALLE DE ZARAGOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''649'', N''DGO'', 64, 32, NULL, N''EL ORO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''649'', N''DGO'', 64, 32, NULL, N''INDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''649'', N''DGO'', 64, 32, NULL, N''OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''649'', N''DGO'', 64, 32, NULL, N''SAN BERNARDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''651'', N''SON'', 128, 128, NULL, N''GENERAL PLUTARCO ELIAS CALLES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''651'', N''SON'', 128, 128, NULL, N''GRAL PLUTARCO ELIAS CALLES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''652'', N''CHIH'', 128, 64, NULL, N''MEZ FARIAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''652'', N''CHIH'', 128, 64, NULL, N''MADERA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''653'', N''BC'', 256, 128, NULL, N''MEXICALI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''653'', N''SON'', 128, 128, NULL, N''SAN LUIS RIO COLORADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''656'', N''CHIH'', 128, 64, NULL, N''AHUMADA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''656'', N''CHIH'', 128, 64, NULL, N''ASCENSION'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''656'', N''CHIH'', 128, 64, NULL, N''GUADALUPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''656'', N''CHIH'', 128, 64, NULL, N''JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''656'', N''CHIH'', 128, 64, NULL, N''PRAXEDIS G. GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''658'', N''BC'', 256, 128, NULL, N''MEXICALI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''659'', N''CHIH'', 128, 64, NULL, N''BACHINIVA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''659'', N''CHIH'', 128, 64, NULL, N''MATACHI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''659'', N''CHIH'', 128, 64, NULL, N''NAMIQUIPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''659'', N''CHIH'', 128, 64, NULL, N''TEMOSACHI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''661'', N''BC'', 256, 128, NULL, N''PLAYAS DE ROSARITO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''662'', N''SON'', 128, 128, NULL, N''HERMOSILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''664'', N''BC'', 256, 128, NULL, N''ENSENADA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''664'', N''BC'', 256, 128, NULL, N''TIJUANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''665'', N''BC'', 256, 128, NULL, N''TECATE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''667'', N''SIN'', 128, 64, NULL, N''CULIACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''668'', N''SIN'', 128, 64, NULL, N''AHOME'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''669'', N''SIN'', 128, 64, NULL, N''MAZATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''671'', N''COAH'', 64, 32, NULL, N''VIESCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''671'', N''DGO'', 64, 32, NULL, N''CUENCAME'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''671'', N''DGO'', 64, 32, NULL, N''GENERAL SIMON BOLIVAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''671'', N''DGO'', 64, 32, NULL, N''NAZAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''671'', N''DGO'', 64, 32, NULL, N''SAN JUAN DE GUADALUPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''671'', N''DGO'', 64, 32, NULL, N''SAN LUIS DEL CORDERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''671'', N''DGO'', 64, 32, NULL, N''SAN PEDRO DEL GALLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''671'', N''DGO'', 64, 32, NULL, N''SANTA CLARA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''672'', N''SIN'', 128, 64, NULL, N''NAVOLATO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''673'', N''SIN'', 128, 64, NULL, N''MOCORITO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''673'', N''SIN'', 128, 64, NULL, N''SALVADOR ALVARADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''674'', N''DGO'', 64, 32, NULL, N''CANELAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''674'', N''DGO'', 64, 32, NULL, N''GUANACEVI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''674'', N''DGO'', 64, 32, NULL, N''OTAEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''674'', N''DGO'', 64, 32, NULL, N''SAN DIMAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''674'', N''DGO'', 64, 32, NULL, N''SANTIA PAPASQUIARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''674'', N''DGO'', 64, 32, NULL, N''TAMAZULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''674'', N''DGO'', 64, 32, NULL, N''TEPEHUANES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''674'', N''DGO'', 64, 32, NULL, N''TOPIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''675'', N''DGO'', 64, 32, NULL, N''MEZQUITAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''675'', N''DGO'', 64, 32, NULL, N''NOMBRE DE DIOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''675'', N''DGO'', 64, 32, NULL, N''POANAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''675'', N''DGO'', 64, 32, NULL, N''PUEBLO NUEVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''675'', N''DGO'', 64, 32, NULL, N''SUCHIL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''675'', N''DGO'', 64, 32, NULL, N''VICENTE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''676'', N''DGO'', 64, 32, NULL, N''CUENCAME'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''676'', N''DGO'', 64, 32, NULL, N''GUADALUPE VICTORIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''676'', N''DGO'', 64, 32, NULL, N''PANUCO CORONADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''676'', N''DGO'', 64, 32, NULL, N''PENON BLANCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''677'', N''DGO'', 64, 32, NULL, N''CANATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''677'', N''DGO'', 64, 32, NULL, N''CONETO DE COMONFORT'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''677'', N''DGO'', 64, 32, NULL, N''NUEVO IDEAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''677'', N''DGO'', 64, 32, NULL, N''PANUCO CORONADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''677'', N''DGO'', 64, 32, NULL, N''PANUCO DE CORONADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''677'', N''DGO'', 64, 32, NULL, N''RODEO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''677'', N''DGO'', 64, 32, NULL, N''SAN JUAN DEL RIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''686'', N''BC'', 256, 128, NULL, N''MEXICALI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''686'', N''BC'', 256, 128, NULL, N''TECATE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''687'', N''SIN'', 128, 64, NULL, N''GUASAVE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''687'', N''SIN'', 128, 64, NULL, N''SINALOA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''694'', N''SIN'', 128, 64, NULL, N''CONCORDIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''694'', N''SIN'', 128, 64, NULL, N''ROSARIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''695'', N''SIN'', 128, 64, NULL, N''ESCUINAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''696'', N''SIN'', 128, 64, NULL, N''COSALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''696'', N''SIN'', 128, 64, NULL, N''ELOTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''696'', N''SIN'', 128, 64, NULL, N''SAN IGNACIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''697'', N''SIN'', 128, 64, NULL, N''ANSTURA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''697'', N''SIN'', 128, 64, NULL, N''BADIRAGUATO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''697'', N''SIN'', 128, 64, NULL, N''MOCORITO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''697'', N''SIN'', 128, 64, NULL, N''NAVOLATO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''698'', N''SIN'', 128, 64, NULL, N''CHOIX'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''698'', N''SIN'', 128, 64, NULL, N''EL FUERTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''711'', N''MEX'', 64, 32, NULL, N''EL ORO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''711'', N''MICH'', 64, 32, NULL, N''TLALPUJAHUA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''711'', N''MICH'', 64, 32, NULL, N''TLALPUJAHUA DE RAYON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''712'', N''MEX'', 64, 32, NULL, N''ACULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''712'', N''MEX'', 64, 32, NULL, N''ATLACOMULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''712'', N''MEX'', 64, 32, NULL, N''IXTLAHUACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''712'', N''MEX'', 64, 32, NULL, N''JIQUIPILCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''712'', N''MEX'', 64, 32, NULL, N''JOCOTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''712'', N''MEX'', 64, 32, NULL, N''MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''712'', N''MEX'', 64, 32, NULL, N''SAN FELIPE DEL PROGRESO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''712'', N''MEX'', 64, 32, NULL, N''TIMILPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''713'', N''MEX'', 64, 32, NULL, N''ATIZAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''713'', N''MEX'', 64, 32, NULL, N''CAPULHUAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''713'', N''MEX'', 64, 32, NULL, N''TEXCALYACAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''713'', N''MEX'', 64, 32, NULL, N''TIANGISTENCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''713'', N''MEX'', 64, 32, NULL, N''TIANGUISTENCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''713'', N''MEX'', 64, 32, NULL, N''XALATLACO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''714'', N''MEX'', 64, 32, NULL, N''JOQUICIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''714'', N''MEX'', 64, 32, NULL, N''MALINALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''714'', N''MEX'', 64, 32, NULL, N''OCUILAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''714'', N''MEX'', 64, 32, NULL, N''TENANCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''714'', N''MEX'', 64, 32, NULL, N''VILLA GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''714'', N''MEX'', 64, 32, NULL, N''ZUMPAHUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''715'', N''MICH'', 64, 32, NULL, N''ANGANGUEO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''715'', N''MICH'', 64, 32, NULL, N''JUANGAPEO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''715'', N''MICH'', 64, 32, NULL, N''OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''715'', N''MICH'', 64, 32, NULL, N''ZITACUARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''716'', N''MEX'', 64, 32, NULL, N''ALMOLOYA DE ALQUISIRAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''716'', N''MEX'', 64, 32, NULL, N''AMATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''716'', N''MEX'', 64, 32, NULL, N''SAN SIMON DE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''716'', N''MEX'', 64, 32, NULL, N''SULTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''716'', N''MEX'', 64, 32, NULL, N''TEMASCALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''716'', N''MEX'', 64, 32, NULL, N''TEXCALTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''716'', N''MEX'', 64, 32, NULL, N''TLATLAYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''717'', N''MEX'', 64, 32, NULL, N''RAYON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''717'', N''MEX'', 64, 32, NULL, N''SAN ANTONIO LA ISLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''717'', N''MEX'', 64, 32, NULL, N''TENAN DEL VALLE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''718'', N''MEX'', 64, 32, NULL, N''ACAMBAY'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''718'', N''MEX'', 64, 32, NULL, N''ACAMBAY DE RUIZ CASTAÑEDA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''718'', N''MEX'', 64, 32, NULL, N''ACULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''718'', N''MEX'', 64, 32, NULL, N''TEMASCALCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''719'', N''MEX'', 64, 32, NULL, N''OTZOLOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''719'', N''MEX'', 64, 32, NULL, N''TEMOAYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''719'', N''MEX'', 64, 32, NULL, N''XONACATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''721'', N''GRO'', 64, 32, NULL, N''PILCAYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''721'', N''GRO'', 64, 32, NULL, N''TETIPAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''721'', N''MEX'', 64, 32, NULL, N''IXTAPAN DE LA SAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''721'', N''MEX'', 64, 32, NULL, N''TONATICO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''721'', N''MEX'', 64, 32, NULL, N''ZACUALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''722'', N''MEX'', 64, 32, NULL, N''ALMOLOYA DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''722'', N''MEX'', 64, 32, NULL, N''CALIMAYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''722'', N''MEX'', 64, 32, NULL, N''CHAPULTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''722'', N''MEX'', 64, 32, NULL, N''METEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''722'', N''MEX'', 64, 32, NULL, N''MEXICALTZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''722'', N''MEX'', 64, 32, NULL, N''TOLUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''722'', N''MEX'', 64, 32, NULL, N''ZINACANTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''723'', N''MEX'', 64, 32, NULL, N''COATEPEC HARINAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''724'', N''MEX'', 64, 32, NULL, N''TEJUPILCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''725'', N''MEX'', 64, 32, NULL, N''ALMOLOYA DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''725'', N''MEX'', 64, 32, NULL, N''ZINACANTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''726'', N''MEX'', 64, 32, NULL, N''AMANALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''726'', N''MEX'', 64, 32, NULL, N''DONATO GUERRA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''726'', N''MEX'', 64, 32, NULL, N''IXTAPAN DEL ORO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''726'', N''MEX'', 64, 32, NULL, N''OTZOLOAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''726'', N''MEX'', 64, 32, NULL, N''SANTO TOMAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''726'', N''MEX'', 64, 32, NULL, N''VALLE DE BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''726'', N''MEX'', 64, 32, NULL, N''VILLA DE ALLENDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''726'', N''MEX'', 64, 32, NULL, N''VILLA VICTORIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''726'', N''MEX'', 64, 32, NULL, N''ZACAZONAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''727'', N''GRO'', 64, 32, NULL, N''ATENAN DEL RIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''727'', N''GRO'', 64, 32, NULL, N''BUENAVISTA DE CUELLAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''727'', N''GRO'', 64, 32, NULL, N''COPALILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''727'', N''GRO'', 64, 32, NULL, N''HUITZUCO DE LOS FIGUEROA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''728'', N''MEX'', 64, 32, NULL, N''LERMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''728'', N''MEX'', 64, 32, NULL, N''METEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''728'', N''MEX'', 64, 32, NULL, N''OCOYOACAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''728'', N''MEX'', 64, 32, NULL, N''SAN MATEO ATENCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''729'', N''MEX'', 64, 32, NULL, N''TOLUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''731'', N''MOR'', 64, 32, NULL, N''JANTETELCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''731'', N''MOR'', 64, 32, NULL, N''OCUITUCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''731'', N''MOR'', 64, 32, NULL, N''TEMOAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''731'', N''MOR'', 64, 32, NULL, N''TETELA DEL VOLCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''731'', N''MOR'', 64, 32, NULL, N''YECAPIXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''731'', N''MOR'', 64, 32, NULL, N''ZACUALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''732'', N''GRO'', 64, 32, NULL, N''AJUCHITLAN DEL PROGRESO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''732'', N''GRO'', 64, 32, NULL, N''ARCELIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''732'', N''GRO'', 64, 32, NULL, N''CUTZAMALA DE PINZON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''732'', N''GRO'', 64, 32, NULL, N''SAN MIGUEL TOTOLAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''732'', N''GRO'', 64, 32, NULL, N''TLALCHAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''732'', N''GRO'', 64, 32, NULL, N''TLAPEHUALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''733'', N''GRO'', 64, 32, NULL, N''EDUARDO NERI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''733'', N''GRO'', 64, 32, NULL, N''IGUALA DE LA INDEPENDENCIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''733'', N''GRO'', 64, 32, NULL, N''TEPECOACUILCO DE TRUJANO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''734'', N''MOR'', 64, 32, NULL, N''JOJUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''734'', N''MOR'', 64, 32, NULL, N''PUENTE DE IXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''734'', N''MOR'', 64, 32, NULL, N''TLALTIZAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''734'', N''MOR'', 64, 32, NULL, N''TLALTIZAPAN DE ZAPATA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''734'', N''MOR'', 64, 32, NULL, N''TLAQUILTENAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''734'', N''MOR'', 64, 32, NULL, N''ZACATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''735'', N''MOR'', 64, 32, NULL, N''ATLATLAHUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''735'', N''MOR'', 64, 32, NULL, N''AYALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''735'', N''MOR'', 64, 32, NULL, N''CUAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''735'', N''MOR'', 64, 32, NULL, N''JONACATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''735'', N''MOR'', 64, 32, NULL, N''TEPALCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''735'', N''MOR'', 64, 32, NULL, N''TLALNEPANTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''735'', N''MOR'', 64, 32, NULL, N''TLAYACAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''735'', N''MOR'', 64, 32, NULL, N''TOTOLAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''735'', N''MOR'', 64, 32, NULL, N''YAUTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''735'', N''MOR'', 64, 32, NULL, N''YECAPIXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''736'', N''GRO'', 64, 32, NULL, N''APAXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''736'', N''GRO'', 64, 32, NULL, N''COCULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''736'', N''GRO'', 64, 32, NULL, N''CUETAZALA DEL PROGRESO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''736'', N''GRO'', 64, 32, NULL, N''CUETZALA DEL PROGRESO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''736'', N''GRO'', 64, 32, NULL, N''GENERAL CANUTO A. NERI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''736'', N''GRO'', 64, 32, NULL, N''GENERAL HELIODORO CASTILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''736'', N''GRO'', 64, 32, NULL, N''IXCATEOPAN DE CUAUHTEMOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''736'', N''GRO'', 64, 32, NULL, N''PEDRO ASCENCIO ALQUISIRAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''736'', N''GRO'', 64, 32, NULL, N''TELOLOAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''737'', N''MOR'', 64, 32, NULL, N''MIACATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''738'', N''HGO'', 64, 32, NULL, N''ALFAJAYUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''738'', N''HGO'', 64, 32, NULL, N''CHILCUAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''738'', N''HGO'', 64, 32, NULL, N''FRANCISCO I. MADERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''738'', N''HGO'', 64, 32, NULL, N''MIXQUIAHUALA DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''738'', N''HGO'', 64, 32, NULL, N''PROGRESO DE OBREN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''738'', N''HGO'', 64, 32, NULL, N''SAN SALVADOR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''739'', N''MOR'', 64, 32, NULL, N''HUITZILAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''739'', N''MOR'', 64, 32, NULL, N''TEPOZTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''741'', N''GRO'', 64, 32, NULL, N''AZOYU'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''741'', N''GRO'', 64, 32, NULL, N''COPALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''741'', N''GRO'', 64, 32, NULL, N''CUAJINICUILAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''741'', N''GRO'', 64, 32, NULL, N''IGUALAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''741'', N''GRO'', 64, 32, NULL, N''OMETEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''741'', N''GRO'', 64, 32, NULL, N''SAN LUIS ACATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''741'', N''GRO'', 64, 32, NULL, N''TLACOACHISTLAHUACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''741'', N''GRO'', 64, 32, NULL, N''XOCHISTLAHUACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''741'', N''OAX'', 64, 32, NULL, N''SANTIA TAPEXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''741'', N''OAX'', 64, 32, NULL, N''SANTO DOMIN ARMENTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''742'', N''GRO'', 64, 32, NULL, N''ATOYAC DE ALVAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''742'', N''GRO'', 64, 32, NULL, N''PETATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''742'', N''GRO'', 64, 32, NULL, N''TECPAN DE GALEANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''743'', N''HGO'', 64, 32, NULL, N''SAN AGUSTIN TLAXIACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''743'', N''HGO'', 64, 32, NULL, N''TOLCAYUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''743'', N''HGO'', 64, 32, NULL, N''VILLA DE TEZONTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''743'', N''HGO'', 64, 32, NULL, N''ZAPOTLAN DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''743'', N''HGO'', 64, 32, NULL, N''ZEMPOALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''743'', N''MEX'', 64, 32, NULL, N''AXAPUSCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''743'', N''MEX'', 64, 32, NULL, N''TEMASCALAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''744'', N''GRO'', 64, 32, NULL, N''ACAPULCO DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''744'', N''GRO'', 64, 32, NULL, N''COYUCA DE BENITEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''745'', N''GRO'', 64, 32, NULL, N''AYUTLA DE LOS LIBRES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''745'', N''GRO'', 64, 32, NULL, N''CHILPANCIN DE LOS BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''745'', N''GRO'', 64, 32, NULL, N''CUAUTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''745'', N''GRO'', 64, 32, NULL, N''FLORENCIO VILLARREAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''745'', N''GRO'', 64, 32, NULL, N''JUAN R. ESCUDERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''745'', N''GRO'', 64, 32, NULL, N''SAN MARCOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''745'', N''GRO'', 64, 32, NULL, N''TECOANAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''746'', N''HGO'', 64, 32, NULL, N''HUAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''746'', N''HGO'', 64, 32, NULL, N''XOCHIATIPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''746'', N''PUE'', 64, 32, NULL, N''FRANCISCO Z. MENA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''746'', N''PUE'', 64, 32, NULL, N''PANTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''746'', N''PUE'', 64, 32, NULL, N''VENUSTIANO CARRANZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''746'', N''VER'', 64, 32, NULL, N''BENITO JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''746'', N''VER'', 64, 32, NULL, N''CASTILLO DE TEAYO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''746'', N''VER'', 64, 32, NULL, N''CHICONTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''746'', N''VER'', 64, 32, NULL, N''CHICONTEPEC DE TEJEDA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''746'', N''VER'', 64, 32, NULL, N''IXHUATLAN DE MADERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''746'', N''VER'', 64, 32, NULL, N''TIHUATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''747'', N''GRO'', 64, 32, NULL, N''CHILPANCIN DE LOS BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''747'', N''GRO'', 64, 32, NULL, N''EDUARDO NERI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''747'', N''GRO'', 64, 32, NULL, N''LEONARDO BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''748'', N''HGO'', 64, 32, NULL, N''ALMOLOYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''748'', N''HGO'', 64, 32, NULL, N''APAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''748'', N''HGO'', 64, 32, NULL, N''EMILIANO ZAPATA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''748'', N''TLAX'', 64, 32, NULL, N''BENITO JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''748'', N''TLAX'', 64, 32, NULL, N''NANACAMILPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''748'', N''TLAX'', 64, 32, NULL, N''NANACAMILPA DE MARIANO ARISTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''748'', N''TLAX'', 64, 32, NULL, N''SANCTORUM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''749'', N''TLAX'', 64, 32, NULL, N''CALPULALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''751'', N''MEX'', 64, 32, NULL, N''MALINALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''751'', N''MOR'', 64, 32, NULL, N''AMACUZAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''751'', N''MOR'', 64, 32, NULL, N''COATLAN DEL RIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''751'', N''MOR'', 64, 32, NULL, N''MAZATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''751'', N''MOR'', 64, 32, NULL, N''PUENTE DE IXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''751'', N''MOR'', 64, 32, NULL, N''TETECALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''753'', N''GRO'', 64, 32, NULL, N''LA UNION DE ISIDORO MONTES DE OCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''753'', N''MICH'', 64, 32, NULL, N''ARTEAGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''753'', N''MICH'', 64, 32, NULL, N''LAZARO CARDENAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''754'', N''GRO'', 64, 32, NULL, N''MARTIR DE CUILAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''754'', N''GRO'', 64, 32, NULL, N''MOCHITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''754'', N''GRO'', 64, 32, NULL, N''TIXTLA DE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''754'', N''GRO'', 64, 32, NULL, N''TLIXTLA DE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''755'', N''GRO'', 64, 32, NULL, N''JOSE AZUETA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''755'', N''GRO'', 64, 32, NULL, N''LA UNION DE ISIDORO MONTES DE OCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''755'', N''GRO'', 64, 32, NULL, N''ZIHUATANEJO DE AZUETA '')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''756'', N''GRO'', 64, 32, NULL, N''AHUACUOTZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''756'', N''GRO'', 64, 32, NULL, N''ATLIXTAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''756'', N''GRO'', 64, 32, NULL, N''CHILAPA DE ALVAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''756'', N''GRO'', 64, 32, NULL, N''OLINALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''756'', N''GRO'', 64, 32, NULL, N''QUECHULTENAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''756'', N''GRO'', 64, 32, NULL, N''ZITLALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''GRO'', 64, 32, NULL, N''ALCOZAUCA DE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''GRO'', 64, 32, NULL, N''ALPOYECA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''GRO'', 64, 32, NULL, N''ATLAMAJALCIN DEL MONTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''GRO'', 64, 32, NULL, N''COPANATOYAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''GRO'', 64, 32, NULL, N''CUALAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''GRO'', 64, 32, NULL, N''HUAMUXTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''GRO'', 64, 32, NULL, N''MALINALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''GRO'', 64, 32, NULL, N''TLACOAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''GRO'', 64, 32, NULL, N''TLALIXTAQUILLA DE MALDONADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''GRO'', 64, 32, NULL, N''TLAPA DE COMONFORT'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''GRO'', 64, 32, NULL, N''XALPATLAHUAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''GRO'', 64, 32, NULL, N''XOCHIHUEHUETLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''OAX'', 64, 32, NULL, N''SAN ANDRES TEPETLAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''OAX'', 64, 32, NULL, N''SAN MATEO NEJAPAM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''757'', N''OAX'', 64, 32, NULL, N''ZAPOTITLAN LAGUNAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''758'', N''GRO'', 64, 32, NULL, N''PETATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''759'', N''HGO'', 64, 32, NULL, N''CARDONAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''759'', N''HGO'', 64, 32, NULL, N''IXMIQUILPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''759'', N''HGO'', 64, 32, NULL, N''TASQUILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''759'', N''HGO'', 64, 32, NULL, N''ZIMAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''761'', N''HGO'', 64, 32, NULL, N''HUICHAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''761'', N''HGO'', 64, 32, NULL, N''NOPALA DE VILLAGRAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''761'', N''HGO'', 64, 32, NULL, N''TECOZAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''761'', N''MEX'', 64, 32, NULL, N''JILOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''761'', N''MEX'', 64, 32, NULL, N''SOYANIQUILPAN DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''762'', N''GRO'', 64, 32, NULL, N''TAXCO DE ALARCON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''763'', N''HGO'', 64, 32, NULL, N''CHAPANTON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''763'', N''HGO'', 64, 32, NULL, N''TEPETITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''763'', N''HGO'', 64, 32, NULL, N''TEZONTEPEC DE ALDAMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''763'', N''HGO'', 64, 32, NULL, N''TLAHUELILPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''AHUACATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''AMIXTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''HERMENEGILDO GALEANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''JALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''JOPALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''NUEVO NECAXA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''SAN FELIPE TEPATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''TEPAN DE RODRIGUEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''114'', N''Sheffield'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''115'', N''Nottingham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''116'', N''Leicester'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''117'', N''Bristol'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''118'', N''Reading'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1200'', N''Clitheroe'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1202'', N''Bournemouth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1204'', N''Bolton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1205'', N''Boston'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1206'', N''Colchester'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1207'', N''Consett'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1208'', N''Bodmin'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1209'', N''Redruth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''121'', N''Birmingham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1223'', N''Cambridge'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1224'', N''Aberdeen'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1225'', N''Bath'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1226'', N''Barnsley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1227'', N''Canterbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1228'', N''Carlisle'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1229'', N''Barrow-in-Furness'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1233'', N''Ashford (Kent)'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1234'', N''Bedford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1235'', N''Abingdon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1236'', N''Coatbridge'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1237'', N''Bideford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1239'', N''Cardigan'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1241'', N''Arbroath'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1242'', N''Cheltenham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1243'', N''Chichester'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1244'', N''Chester'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1245'', N''Chelmsford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1246'', N''Chesterfield'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1248'', N''Banr (Gwynedd)'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1249'', N''Chippenham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1250'', N''Blairwrie'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1252'', N''Aldershot'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1253'', N''Blackpool'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1254'', N''Blackburn'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1255'', N''Clacton-on-Sea'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1256'', N''Basingstoke'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1257'', N''Coppull'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1258'', N''Blandford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1259'', N''Alloa'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1260'', N''Congleton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1261'', N''Banff'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1262'', N''Bridlington'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1263'', N''Cromer'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1264'', N''Andover'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1267'', N''Carmarthen'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1268'', N''Basildon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1269'', N''Ammanford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1270'', N''Crewe'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1271'', N''Barnstable'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1273'', N''Brighton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1274'', N''Bradford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1275'', N''Clevedon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1276'', N''Camberley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1277'', N''Brentwood'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1278'', N''Bridgwater'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1279'', N''Bishops Stortford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1280'', N''Buckingham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1282'', N''Burnley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1283'', N''Burton-on-Trent'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1284'', N''Bury-St-Edmunds'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1285'', N''Cirencester'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1286'', N''Caernarvon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1287'', N''Guisborough'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1288'', N''Bude'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1289'', N''Berwick-on-Tweed'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1290'', N''Cumnock'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1291'', N''Chepstow'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1292'', N''Ayr'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1293'', N''Crawley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1294'', N''Ardrossan'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1295'', N''Banbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1296'', N''Aylesbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1297'', N''Axminster'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1298'', N''Buxton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1299'', N''Bewdley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1300'', N''Cerne Abbas'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1301'', N''Arrochar'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1302'', N''Doncaster'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1303'', N''Folkestone'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1304'', N''Dover'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1305'', N''Dorchester'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1306'', N''Dorking'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1307'', N''Forfar'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1308'', N''Bridport'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1309'', N''Forres'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''131'', N''Edinburgh'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1320'', N''Fort Augustus'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1322'', N''Dartford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1323'', N''Eastbourne'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1324'', N''Falkirk'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1325'', N''Darlington'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1326'', N''Falmouth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1327'', N''Daventry'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1328'', N''Fakenham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1329'', N''Fareham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1330'', N''Banchory'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1332'', N''Derby'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1333'', N''Peat Inn'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1334'', N''St Andrews'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1335'', N''Ashbourne'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1337'', N''Ladybank'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1339'', N''Aboyne'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1340'', N''Craigellachie'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1341'', N''Barmouth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1342'', N''East Grinstead'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1343'', N''Elgin'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1344'', N''Bracknell'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1346'', N''Fraserburgh'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1347'', N''Easingwold'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1348'', N''Fishguard'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1349'', N''Dingwall'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1350'', N''Dunkeld'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1352'', N''Mold'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1353'', N''Ely'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1354'', N''Chatteris'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1355'', N''East Kilbride'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1356'', N''Brechin'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1357'', N''Strathaven'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1358'', N''Ellon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1359'', N''Pakenham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1360'', N''Killearn'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1361'', N''Duns'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1362'', N''Dereham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1363'', N''Crediton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1364'', N''Ashburton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1366'', N''Downham Market'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1367'', N''Faringdon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1368'', N''Dunbar'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1369'', N''Dunoon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1371'', N''Great Dunmow'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1372'', N''Esher'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1373'', N''Frome'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1375'', N''Grays Thurrock'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1376'', N''Braintree'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1377'', N''Driffield'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1379'', N''Diss'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1380'', N''Devizes'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1381'', N''Fortrose'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1382'', N''Dundee'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1383'', N''Dunfermline'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1384'', N''Dudley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1386'', N''Evesham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1387'', N''Dumfries'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''13873'', N''Langholm'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1388'', N''Stanhope'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1389'', N''Dumbarton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1392'', N''Exeter'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1394'', N''Felixstowe'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1395'', N''Budleigh Salterton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1397'', N''Fort William'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1398'', N''Dulverton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1400'', N''Honington'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1403'', N''Horsham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1404'', N''Honiton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1405'', N''ole'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1406'', N''Holbeach'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1407'', N''Holyhead'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1408'', N''lspie'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1409'', N''Holsworthy'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''141'', N''Glasw'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1420'', N''Alton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1422'', N''Halifax'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1423'', N''Harrogate'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1424'', N''Hastings'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1425'', N''Ringwood'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1427'', N''Gainsborough'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1428'', N''Haslemere'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1429'', N''Hartlepool'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1430'', N''North Cave'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1431'', N''Helmsdale'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1432'', N''Hereford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1433'', N''Hathersage'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1434'', N''Bellingham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1435'', N''Heathfield'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1436'', N''Helensburgh'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1437'', N''Clynderwen'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1438'', N''Stevenage'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1439'', N''Helmsley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1440'', N''Haverhill'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1442'', N''Hemel Hempstead'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1443'', N''Pontypridd'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1444'', N''Haywards Heath'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1445'', N''Gairloch'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1446'', N''Barry'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1449'', N''Stowmarket'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1450'', N''Hawick'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1451'', N''Stow-on-the-Wold'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1452'', N''Gloucester'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1453'', N''Dursley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1454'', N''Chipping Sodbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1455'', N''Hinckley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1456'', N''Glenurquhart'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1457'', N''Glossop'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1458'', N''Glastonbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1460'', N''Chard'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1461'', N''Gretna'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1462'', N''Hitchin'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1463'', N''Inverness'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1464'', N''Insch'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1465'', N''Girvan'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1466'', N''Huntly'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1467'', N''Inverurie'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1469'', N''Killingholme'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1470'', N''Isle of Skye – Edinbane'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1471'', N''Isle of Skye – Broadford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1472'', N''Grimsby'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1473'', N''Ipswich'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1474'', N''Gravesend'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1475'', N''Greenock'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1476'', N''Grantham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1477'', N''Holmes Chapel'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1478'', N''Isle of Skye – Portree'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1479'', N''Grantown-on-Spey'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1480'', N''Huntingdon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1481'', N''Guernsey'', 1, 32768, NULL, NULL)
';
EXEC(@sql);
SET @process = 'SPEC-75 Actualiza tabla ZonasHorarias'
		SET @sql = '

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1482'', N''Hull'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1483'', N''Guildford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1484'', N''Huddersfield'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1485'', N''Hunstanton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1487'', N''Warboys'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1488'', N''Hungerford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1489'', N''Bishops Waltham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1490'', N''Corwen'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1491'', N''Henley-on-Thames'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1492'', N''Colwyn Bay'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1493'', N''Great Yarmouth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1494'', N''High Wycombe'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1495'', N''Pontypool'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1496'', N''Port Ellen'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1497'', N''Hay-on-Wye'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1499'', N''Inveraray'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1501'', N''Harthill'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1502'', N''Lowestoft'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1503'', N''Looe'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1505'', N''Johnstone'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1506'', N''Bathgate'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1507'', N''Spilsby'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1508'', N''Brooke'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1509'', N''Loughborough'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''151'', N''Liverpool'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1520'', N''Lochcarron'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1522'', N''Lincoln'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1524'', N''Lancaster'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''15242'', N''Hornby'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1525'', N''Leighton Buzzard'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1526'', N''Martin'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1527'', N''Redditch'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1528'', N''Laggan'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1529'', N''Sleaford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1530'', N''Coalville'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1531'', N''Ledbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1534'', N''Jersey'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1535'', N''Keighley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1536'', N''Kettering'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1538'', N''Ipstones'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1539'', N''Kendal'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''15394'', N''Hawkshead'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''15395'', N''Grange-Over-Sands'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''15396'', N''Sedbergh'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1540'', N''Kingussie'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1542'', N''Keith'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1543'', N''Cannock'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1544'', N''Kington'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1545'', N''Llanarth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1546'', N''Lochgilphead'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1547'', N''Knighton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1548'', N''Kingsbridge'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1549'', N''Lairg'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1550'', N''Llandovery'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1553'', N''Kings Lynn'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1554'', N''Llanelli'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1555'', N''Lanark'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1556'', N''Castle Douglas'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1557'', N''Kirkcudbright'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1558'', N''Llandeilo'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1559'', N''Llandyssul'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1560'', N''Moscow'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1561'', N''Laurencekirk'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1562'', N''Kidderminster'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1563'', N''Kilmarnock'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1564'', N''Lapworth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1565'', N''Knutsford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1566'', N''Launceston'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1567'', N''Killin'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1568'', N''Leominster'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1569'', N''Stonehaven'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1570'', N''Lampeter'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1571'', N''Lochinver'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1572'', N''Oakham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1573'', N''Kelso'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1575'', N''Kirriemuir'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1576'', N''Lockerbie'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1577'', N''Kinross'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1578'', N''Lauder'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1579'', N''Liskeard'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1580'', N''Cranbrook'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1581'', N''New Luce'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1582'', N''Luton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1583'', N''Carradale'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1584'', N''Ludlow'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1586'', N''Campbeltown'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1588'', N''Bishops Castle'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1590'', N''Lymington'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1591'', N''Llanwrtyd Wells'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1592'', N''Kirkcaldy'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1593'', N''Lybster'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1594'', N''Lydney'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1595'', N''Lerwick'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1597'', N''Llandrindod Wells'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1598'', N''Lynton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1599'', N''Kyle'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1600'', N''Monmouth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1603'', N''Norwich'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1604'', N''Northampton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1606'', N''Northwich'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1608'', N''Chipping Norton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1609'', N''Northallerton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''161'', N''Manchester'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1620'', N''North Berwick'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1621'', N''Maldon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1622'', N''Maidstone'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1623'', N''Mansfield'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1624'', N''Isle of Man'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1625'', N''Macclesfield'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1626'', N''Newton Abbot'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1628'', N''Maidenhead'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1629'', N''Matlock'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1630'', N''Market Drayton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1631'', N''Oban'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1633'', N''Newport'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1634'', N''Medway'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1635'', N''Newbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1636'', N''Newark'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1637'', N''Newquay'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1638'', N''Newmarket'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1639'', N''Neath'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1641'', N''Strathy'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1642'', N''Middlesbrough'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1643'', N''Minehead'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1644'', N''New Galloway'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1646'', N''Milford Haven'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1647'', N''Moretonhampstead'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1650'', N''Cemmaes Road'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1651'', N''Oldmeldrum'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1652'', N''Brigg'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1653'', N''Malton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1654'', N''Machynlleth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1655'', N''Maybole'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1656'', N''Bridgend'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1659'', N''Sanquhar'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1661'', N''Prudhoe'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1663'', N''New Mills'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1664'', N''Melton Mowbray'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1665'', N''Alnwick'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1666'', N''Malmesbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1667'', N''Nairn'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1668'', N''Bamburgh'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1669'', N''Rothbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1670'', N''Morpeth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1671'', N''Newton Stewart'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1672'', N''Marlborough'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1673'', N''Market Rasen'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1674'', N''Montrose'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1675'', N''Coleshill'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1676'', N''Meriden'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1677'', N''Bedale'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1678'', N''Bala'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1680'', N''Isle of Mull – Craignure'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1681'', N''Isle of Mull – Fionnphort'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1683'', N''Moffat'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1684'', N''Malvern'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1685'', N''Merthyr Tydfil'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1686'', N''Llanidloes'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1687'', N''Mallaig'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1688'', N''Isle of Mull – Tobermory'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1689'', N''Orpington'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1690'', N''Betws-y-Coed'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1691'', N''Oswestry'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1692'', N''North Walsham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1694'', N''Church Stretton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1695'', N''Skelmersdale'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1697'', N''Brampton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''16973'', N''Wigton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''16974'', N''Raughton Head'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1698'', N''Motherwell'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1700'', N''Rothesay'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1702'', N''Southend-on-Sea'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1704'', N''Southport'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1706'', N''Rochdale'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1707'', N''Welwyn Garden City'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1708'', N''Romford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1709'', N''Rotherham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1720'', N''Isles of Scilly'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1721'', N''Peebles'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1722'', N''Salisbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1723'', N''Scarborough'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1724'', N''Scunthorpe'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1725'', N''Rockbourne'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1726'', N''St Austell'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1727'', N''St Albans'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1728'', N''Saxmundham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1729'', N''Settle'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1730'', N''Petersfield'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1732'', N''Sevenoaks'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1733'', N''Peterborough'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1736'', N''Penzance'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1737'', N''Redhill'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1738'', N''Perth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1740'', N''Sedgefield'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1743'', N''Shrewsbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1744'', N''St Helens'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1745'', N''Rhyl'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1746'', N''Bridgnorth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1747'', N''Shaftesbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1748'', N''Richmond'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1749'', N''Shepton Mallet'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1750'', N''Selkirk'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1751'', N''Pickering'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1752'', N''Plymouth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1753'', N''Slough'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1754'', N''Skegness'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1756'', N''Skipton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1757'', N''Selby'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1758'', N''Pwllheli'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1759'', N''Pocklington'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1760'', N''Swaffham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1761'', N''Temple Cloud'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1763'', N''Royston'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1764'', N''Crieff'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1765'', N''Ripon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1766'', N''Porthmadog'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1767'', N''Sandy'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1768'', N''Penrith'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''17683'', N''Appleby'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''17684'', N''Pooley Bridge'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''17687'', N''Keswick'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1769'', N''South Molton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1770'', N''Isle of Arran'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1771'', N''Maud'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1772'', N''Preston'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1773'', N''Ripley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1775'', N''Spalding'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1776'', N''Stranraer'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1777'', N''Retford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1778'', N''Bourne'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1779'', N''Peterhead'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1780'', N''Stamford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1782'', N''Stoke-on-Trent'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1784'', N''Staines'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1785'', N''Stafford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1786'', N''Stirling'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1787'', N''Sudbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1788'', N''Rugby'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1789'', N''Stratford-upon-Avon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1790'', N''Spilsby'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1792'', N''Swansea'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1793'', N''Swindon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1794'', N''Romsey'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1795'', N''Sittingbourne'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1796'', N''Pitlochry'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1797'', N''Rye'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1798'', N''Pulborough'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1799'', N''Saffron Walden'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1803'', N''Torquay'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1805'', N''Torrington'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1806'', N''Shetland'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1807'', N''Ballindalloch'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1808'', N''Tomatin'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1809'', N''Tomdoun'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1821'', N''Kinrossie'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1822'', N''Tavistock'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1823'', N''Taunton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1824'', N''Ruthin'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1825'', N''Uckfield'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1827'', N''Tamworth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1828'', N''Coupar Angus'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1829'', N''Tarporley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1830'', N''Kirkwhelpington'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1832'', N''Clopton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1833'', N''Barnard Castle'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1834'', N''Narberth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1835'', N''St Boswells'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1837'', N''Okehampton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1838'', N''Dalmally'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1840'', N''Camelford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1841'', N''Newquay'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1842'', N''Thetford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1843'', N''Thanet'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1844'', N''Thame'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1845'', N''Thirsk'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1847'', N''Thurso'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1848'', N''Thornhill'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1851'', N''Stornoway'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1852'', N''Kilmelford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1854'', N''Ullapool'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1855'', N''Ballachulish'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1856'', N''Orkney'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1857'', N''Sanday'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1858'', N''Market Harborough'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1859'', N''Harris'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1862'', N''Tain'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1863'', N''Ardgay'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1864'', N''Abington'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1865'', N''Oxford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1866'', N''Kilchrenan'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1869'', N''Bicester'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1870'', N''Isle of Benbecula'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1871'', N''Castlebay'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1872'', N''Truro'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1873'', N''Abergavenny'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1874'', N''Brecon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1875'', N''Tranent'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1876'', N''Lochmaddy'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1877'', N''Callandar'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1878'', N''Lochboisdale'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1879'', N''Scarinish'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1880'', N''Tarbert'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1882'', N''Kinloch Rannoch'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1883'', N''Caterham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1884'', N''Tiverton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1885'', N''Pencombe'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1886'', N''Bromyard'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1887'', N''Aberfeldy'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1888'', N''Turriff'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1889'', N''Rugely'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1890'', N''Coldstream'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1892'', N''Tunbridge Wells'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1895'', N''Uxbridge'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1896'', N''Galashiels'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1899'', N''Biggar'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1900'', N''Workington'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1902'', N''Wolverhampton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1903'', N''Worthing'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1904'', N''York'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1905'', N''Worcester'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1908'', N''Milton Keynes'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1909'', N''Worksop'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''191'', N''Tyneside'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1920'', N''Ware'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1922'', N''Walsall'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1923'', N''Watford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1924'', N''Wakefield'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1925'', N''Warrington'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1926'', N''Warwick'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1928'', N''Runcorn'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1929'', N''Wareham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1931'', N''Shap'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1932'', N''Weybridge'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1933'', N''Wellingborough'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1934'', N''Weston-Super-Mare'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1935'', N''Yeovil'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1937'', N''Wetherby'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1938'', N''Welshpool'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1939'', N''Wem'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1942'', N''Wigan'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1943'', N''Guiseley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1944'', N''West Heslerton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1945'', N''Wisbech'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1946'', N''Whitehaven'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''19467'', N''sforth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1947'', N''Whitby'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1948'', N''Whitchurch'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1949'', N''Whatton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1950'', N''Sandwick'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1951'', N''Colonsay'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1952'', N''Telford'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1953'', N''Wymondham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1954'', N''Madingley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1955'', N''Wick'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1957'', N''Mid Yell'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1959'', N''Westerham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1962'', N''Winchester'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1963'', N''Wincanton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1964'', N''Hornsea'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1967'', N''Strontian'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1968'', N''Penicuik'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1969'', N''Leyburn'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1970'', N''Aberystwyth'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1971'', N''Scourie'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1972'', N''Glenborrodale'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1974'', N''Llanon'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1975'', N''Alford (Aberdeen)'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1977'', N''Pontefract'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1978'', N''Wrexham'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1980'', N''Amesbury'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1981'', N''Wormbridge'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1982'', N''Builth Wells'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1983'', N''Isle of Wight'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1984'', N''Watchet'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1985'', N''Warminster'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1986'', N''Bungay'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1987'', N''Ebbsfleet'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1988'', N''Wigtown'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1989'', N''Ross-on-Wye'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1992'', N''Lea Valley'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1993'', N''Witney'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1994'', N''St Clears'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1995'', N''Garstang'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''1997'', N''Strathpeffer'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''20'', N''London'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''23'', N''Southampton'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''24'', N''Coventry'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''28'', N''Ballycastle'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''29'', N''Cardiff'', 1, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (8, N''1'', N''Riyadh'', 32768, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (8, N''2'', N''Jeddah, Taif, Rabigh'', 32768, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (8, N''3'', N''Qatif, Dammam, Dhahran, Hafar Al-Batin'', 32768, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (8, N''4'', N''Al-Madinah, Tabuk, Al-Jawf'', 32768, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (8, N''5'', N''cellphone'', 32768, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (8, N''6'', N''Al-Qassim, Buraidah, Majma and Hail'', 32768, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (8, N''7'', N''Asir, Al-Baha, Jizan, Najran, Khamis Mushait'', 32768, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (8, N''8'', N''Atheeb  Telecom phone numbers'', 32768, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (8, N''9'', N''Saudi Arabia'', 32768, 32768, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''02'', N''NSW - New South Wales'', 4194304, 8388608, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''03'', N''V - Victoria'', 4194304, 8388608, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''07'', N''Q - Queensland'', 4194304, 4194304, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0825'', N''SA - Berri'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0826'', N''SA - Ceduna'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0851'', N''X - Christmas Island'', 524288, 524288, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0852'', N''WA - Perth'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0853'', N''WA - Perth'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0854'', N''WA - Perth'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0855'', N''WA - Bullsbrook East'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0858'', N''WA - Albany'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0860'', N''WA - Bruce Rock'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0861'', N''WA - Perth'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0862'', N''WA - Perth'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0863'', N''WA - Perth'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0864'', N''WA - Perth'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0865'', N''WA - Perth'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0866'', N''WA - Moora'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0867'', N''WA - Bridgetown'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0868'', N''WA - Albany'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0869'', N''WA - Carnamah'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0870'', N''SA - Adelaide'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0871'', N''SA - Adelaide'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0872'', N''SA - Adelaide'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0873'', N''SA - Adelaide'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0874'', N''SA - Adelaide'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0875'', N''SA - Berri'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0876'', N''SA - Ceduna'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0877'', N''SA - Bordertown'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0878'', N''SA - Balaklava'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0879'', N''NT - Alice Springs'', 134217730, 134217730, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0880'', N''WA - Broken Hill'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0881'', N''SA - Adelaide'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0882'', N''SA - Adelaide'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0883'', N''SA - Adelaide'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0884'', N''SA - Adelaide'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0885'', N''SA - Berri'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0886'', N''SA - Ceduna'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0887'', N''SA - Bordertown'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0888'', N''SA - Balaklava'', 134217730, 134217731, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0889'', N''NT - Alice Springs'', 134217730, 134217730, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0890'', N''WA - Bruce Rock'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0891'', N''X - Christmas Island'', 524288, 524288, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0892'', N''WA - Perth'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0893'', N''WA - Perth'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0894'', N''WA - Perth'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0895'', N''WA - Bullsbrook East'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0896'', N''WA - Moora'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0897'', N''WA - Bridgetown'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0898'', N''WA - Albany'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (9, N''0899'', N''WA - Carnamah'', 1048576, 1048576, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''11'', N''SE - São Paulo (Capital)'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''12'', N''SE - São José dos Campos'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''13'', N''SE - Santos'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''14'', N''SE - Botucatu'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''15'', N''SE - Sorocaba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''16'', N''SE - Serrana'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''17'', N''SE - São José do Rio Preto'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''18'', N''SE - Presidente Prudente'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''19'', N''SE - Vinhedo'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''21'', N''SE - Rio de Janeiro (Capital)'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''22'', N''SE - Nova Fribur'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''24'', N''SE - Volta Redonda'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''27'', N''SE - Vitória'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''28'', N''SE - Cachoeiro de Itapemirim'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''31'', N''SE - Viçosa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''32'', N''SE - Ubá'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''33'', N''SE - vernador Valadares'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''34'', N''SE - Uberlândia'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''35'', N''SE - Varginha'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''37'', N''SE - Piumhi'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''38'', N''SE - Montes Claros'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''41'', N''S - Curitiba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''42'', N''S - Ponta Grossa'', 8, 4, NULL, NULL)
';
EXEC(@sql);
SET @process = 'Actualizar tabla ZonasHorarias'
		SET @sql = '

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''43'', N''S - Ventania'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''44'', N''S - Umuarama'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''45'', N''S - Toledo'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''46'', N''S - Pato Branco'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''47'', N''S - Navegantes'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''48'', N''S - Florianópolis'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''49'', N''S - Lages'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''51'', N''S - Santa Cruz do Sul'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''53'', N''S - Rio Grande'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''54'', N''S - Passo Fundo'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''55'', N''S - Santa Maria'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''61'', N''CO - Brasília'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''62'', N''CO - Santa Isabel'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''63'', N''N - Palmas'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''64'', N''CO - Rio Verde'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''65'', N''CO - Cuiabá'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''66'', N''CO - Rondonópolis'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''67'', N''CO - Três Laas'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''68'', N''N - Rio Branco'', 16, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''69'', N''N - Porto Velho'', 16, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''71'', N''NE - Salvador'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''73'', N''NE - Ilhéus'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''74'', N''NE - Mundo Novo'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''75'', N''NE - Santa Quitéria'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''77'', N''NE - Vitória da Conquista'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''79'', N''NE - Aracaju'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''81'', N''NE - Xexéu'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''82'', N''NE - Maceió'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''83'', N''NE - João Pessoa'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''84'', N''NE - Natal'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''85'', N''NE - Fortaleza'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''86'', N''NE - Teresina'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''87'', N''NE - Petrolina'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''88'', N''NE - Juazeiro do Norte'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''89'', N''NE - Picos'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''91'', N''N - Belém'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''92'', N''N - Manaus'', 16, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''93'', N''N - Santarém'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''94'', N''N - Marabá'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''95'', N''N - Boa Vista'', 16, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''96'', N''N - Macapá'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''97'', N''N - Coari'', 16, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''98'', N''NE - São Luís'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (10, N''99'', N''NE - Imperatriz'', 8, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''CDMX'', 64, 32, NULL, N''BENITO JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''657'', N''CHIH'', 128, 64, NULL, N''JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''649'', N''CHIH'', 128, 64, NULL, N''ROSARIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''659'', N''CHIH'', 128, 64, NULL, N''TEMOSACHIC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''992'', N''CHIS'', 64, 32, NULL, N''NICOLAS RUIZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''OCOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''676'', N''DGO'', 64, 32, NULL, N''PANUCO DE CORONADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''374'', N''JAL'', 64, 32, NULL, N''EL ARENAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''729'', N''MEX'', 64, 32, NULL, N''METEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''786'', N''MICH'', 64, 32, NULL, N''JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''715'', N''MICH'', 64, 32, NULL, N''JUNGAPEO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''319'', N''NAY'', 128, 64, NULL, N''DEL NAYAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''EL CARMEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''OAX'', 64, 32, NULL, N''CHIQUIHUITLAN DE BENITO JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''CUILAPAM DE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''GUADALUPE DE RAMIREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''HEROICA CIUDAD DE EJUTLA DE CRESPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''HEROICA CIUDAD DE TLAXIACO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''HEROICA VILLA TEZOATLAN DE SEGURA Y LUNA, CUNA DE LA INDEPENDENCIA DE OAXACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''994'', N''OAX'', 64, 32, NULL, N''SAN FRANCISCO IXHUATAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN FRANCISCO TELIXTLAHUACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN JORGE NUCHITA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN JUAN MIXTEPEC - DTO. 08-'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN PEDRO TOTOLAPAM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA ANA YARENI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTA MARIA CAMOTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''OAX'', 64, 32, NULL, N''SANTIA CAMOTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''SANTO DOMIN CHIHUITAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''994'', N''OAX'', 64, 32, NULL, N''SANTO DOMIN ZANATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''VILLA DE CHILAPA DE DIAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''VILLA DE ETLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''VILLA DE TUTUTEPEC DE MELCHOR OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''VILLA TALEA DE CASTRO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''233'', N''PUE'', 64, 32, NULL, N''ATLEQUIZAYAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''227'', N''PUE'', 64, 32, NULL, N''CALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''CORONAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''CUAUTLANCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''CUAYUCA DE ANDRADE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''278'', N''PUE'', 64, 32, NULL, N''ELOXOCHITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''243'', N''PUE'', 64, 32, NULL, N''EPATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''776'', N''PUE'', 64, 32, NULL, N''HONEY'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''HUATLATLAUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''HUITZILTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''275'', N''PUE'', 64, 32, NULL, N''IXCAMILPA DE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''JUAN GALINDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''237'', N''PUE'', 64, 32, NULL, N''JUAN N. MENDEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''282'', N''PUE'', 64, 32, NULL, N''LAFRAGUA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''224'', N''PUE'', 64, 32, NULL, N''MIXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''227'', N''PUE'', 64, 32, NULL, N''NEALTICAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''236'', N''PUE'', 64, 32, NULL, N''SAN SEBASTIAN TLACOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''231'', N''PUE'', 64, 32, NULL, N''TETELES DE AVILA CASTILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''CDMX'', 64, 32, NULL, N''AZCAPOTZALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''479'', N''GTO'', 64, 32, NULL, N''LEON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''TLAX'', 64, 32, NULL, N''PAPALOTLA DE XICOHTENCATL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''446'', N''QRO'', 64, 32, NULL, N''QUERETARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''221'', N''PUE'', 64, 32, NULL, N''SAN ANDRES CHOLULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''226'', N''PUE'', 64, 32, NULL, N''XIUTETELCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''237'', N''PUE'', 64, 32, NULL, N''XOCHITLAN TODOS SANTOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''984'', N''QROO'', 32, 32, NULL, N''TULUM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''496'', N''SLP'', 64, 32, NULL, N''SALINAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''440'', N''SLP'', 64, 32, NULL, N''SAN LUIS POTOSI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''483'', N''SLP'', 64, 32, NULL, N''SAN MARTIN CHALCHICUAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''482'', N''SLP'', 64, 32, NULL, N''TANCANHUITZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''485'', N''SLP'', 64, 32, NULL, N''TIERRA NUEVA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''488'', N''SLP'', 64, 32, NULL, N''VANEGAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''623'', N''SON'', 128, 128, NULL, N''SAN MIGUEL DE HORCASITAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''ATLANGATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''276'', N''TLAX'', 64, 32, NULL, N''EL CARMEN TEQUEXQUITLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''248'', N''TLAX'', 64, 32, NULL, N''IXTACUIXTLA DE MARIANO MATAMOROS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''TLAX'', 64, 32, NULL, N''MAZATECOCHCO DE JOSE MARIA MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''MUNOZ DE DOMIN ARENAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''246'', N''TLAX'', 64, 32, NULL, N''NATIVITAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''748'', N''TLAX'', 64, 32, NULL, N''SANCTORUM DE LAZARO CARDENAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''248'', N''TLAX'', 64, 32, NULL, N''TEPETITLA DE LARDIZABAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''241'', N''TLAX'', 64, 32, NULL, N''TETLA DE LA SOLIDARIDAD'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''TLAX'', 64, 32, NULL, N''XICOHTZINCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''223'', N''TLAX'', 64, 32, NULL, N''ZILTLALTEPEC DE TRINIDAD SANCHEZ SANTOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''272'', N''VER'', 64, 32, NULL, N''CAMERINO Z. MENDOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''288'', N''VER'', 64, 32, NULL, N''CARLOS A. CARRILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''COSCOMATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''271'', N''VER'', 64, 32, NULL, N''FORTIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''922'', N''VER'', 64, 32, NULL, N''JALTIPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''283'', N''VER'', 64, 32, NULL, N''JOSE AZUETA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''273'', N''VER'', 64, 32, NULL, N''LA PERLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''229'', N''VER'', 64, 32, NULL, N''MEDELLIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''285'', N''VER'', 64, 32, NULL, N''MEDELLIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''768'', N''VER'', 64, 32, NULL, N''TANTIMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''279'', N''VER'', 64, 32, NULL, N''YECUATLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''990'', N''YUC'', 64, 32, NULL, N''MERIDA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''498'', N''ZAC'', 64, 32, NULL, N''GENERAL FRANCISCO R. MURGUIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''492'', N''ZAC'', 64, 32, NULL, N''TRANCOSO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''446'', N''QRO'', 64, 32, NULL, N''CORREGIDORA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''CDMX'', 64, 32, NULL, N''ALVARO OBREN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''222'', N''PUE'', 64, 32, NULL, N''AMOZOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''220'', N''PUE'', 64, 32, NULL, N''AMOZOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''221'', N''PUE'', 64, 32, NULL, N''AMOZOC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''MEX'', 64, 32, NULL, N''ATIZAPAN DE ZARAGOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''MEX'', 64, 32, NULL, N''CHALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''CDMX'', 64, 32, NULL, N''COYOACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''CDMX'', 64, 32, NULL, N''CUAJIMALPA DE MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''MEX'', 64, 32, NULL, N''CUAUTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''MEX'', 64, 32, NULL, N''CUAUTITLAN IZCALLI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''CDMX'', 64, 32, NULL, N''GUSTAVO A. MADERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''CDMX'', 64, 32, NULL, N''IZTAPALAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''MEX'', 64, 32, NULL, N''HUIXQUILUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''CDMX'', 64, 32, NULL, N''MIGUEL HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''MEX'', 64, 32, NULL, N''NEXTLALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''MEX'', 64, 32, NULL, N''NICOLAS ROMERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''220'', N''PUE'', 64, 32, NULL, N''PUEBLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''729'', N''MEX'', 64, 32, NULL, N''CALIMAYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''221'', N''PUE'', 64, 32, NULL, N''CUAUTLANCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''446'', N''QRO'', 64, 32, NULL, N''EL MARQUES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''724'', N''MEX'', 64, 32, NULL, N''LUVIANOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''729'', N''MEX'', 64, 32, NULL, N''MEXICALTZIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''922'', N''VER'', 64, 32, NULL, N''OTEAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''220'', N''PUE'', 64, 32, NULL, N''SAN ANDRES CHOLULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''221'', N''PUE'', 64, 32, NULL, N''SAN PEDRO CHOLULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''232'', N''VER'', 64, 32, NULL, N''SAN RAFAEL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''MEX'', 64, 32, NULL, N''TECAMAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''720'', N''MEX'', 64, 32, NULL, N''TOLUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''CDMX'', 64, 32, NULL, N''VENUSTIANO CARRANZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''778'', N''HGO'', 64, 32, NULL, N''TETEPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''MEX'', 64, 32, NULL, N''TLALNEPANTLA DE BAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''56'', N''MEX'', 64, 32, NULL, N''TULTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''729'', N''MEX'', 64, 32, NULL, N''ZINACANTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''TLACUILOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''TLAOLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''TLAXCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''XICOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''764'', N''PUE'', 64, 32, NULL, N''ZIHUATEUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''765'', N''VER'', 64, 32, NULL, N''ALAMO TEMAPACHE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''765'', N''VER'', 64, 32, NULL, N''TEMAPACHE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''766'', N''VER'', 64, 32, NULL, N''GUTIERREZ ZAMORA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''766'', N''VER'', 64, 32, NULL, N''TECOLUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''767'', N''GRO'', 64, 32, NULL, N''COYUCA DE CATALAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''767'', N''GRO'', 64, 32, NULL, N''PUNGARABATO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''767'', N''GRO'', 64, 32, NULL, N''ZIRANDARO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''767'', N''MEX'', 64, 32, NULL, N''TLATLAYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''767'', N''MICH'', 64, 32, NULL, N''SAN LUCAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''768'', N''VER'', 64, 32, NULL, N''AMATLAN TUXPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''768'', N''VER'', 64, 32, NULL, N''NARANJOS AMATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''768'', N''VER'', 64, 32, NULL, N''TAMALIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''768'', N''VER'', 64, 32, NULL, N''TAMIAHUA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''769'', N''MOR'', 64, 32, NULL, N''AXOCHIAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''769'', N''MOR'', 64, 32, NULL, N''TEPALCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''771'', N''HGO'', 64, 32, NULL, N''EPAZOYUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''771'', N''HGO'', 64, 32, NULL, N''HUASCA DE OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''771'', N''HGO'', 64, 32, NULL, N''MINERAL DE LA REFORMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''771'', N''HGO'', 64, 32, NULL, N''MINERAL DEL CHICO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''771'', N''HGO'', 64, 32, NULL, N''MINERAL DEL MONTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''771'', N''HGO'', 64, 32, NULL, N''OMITLAN DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''771'', N''HGO'', 64, 32, NULL, N''PACHUCA DE SOTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''771'', N''HGO'', 64, 32, NULL, N''SAN AGUSTIN TLAXIACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''772'', N''HGO'', 64, 32, NULL, N''ACTOPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''772'', N''HGO'', 64, 32, NULL, N''EL ARENAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''772'', N''HGO'', 64, 32, NULL, N''SANTIA DE ANAYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''773'', N''HGO'', 64, 32, NULL, N''TEPEJI DEL RIO DE OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''773'', N''HGO'', 64, 32, NULL, N''TEPETITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''773'', N''HGO'', 64, 32, NULL, N''TULA DE ALLENDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''ACATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''AGUA BLANCA DE ITURBIDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''ATOTONILCO EL GRANDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''CALNALI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''HUAZALIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''HUEHUETLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''JUAREZ HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''METEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''METZTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''MOLAN DE ESCAMILLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''SAN AGUSTIN METZQUITITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''SAN BARTOLO TUTOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''TEPEHUACAN DE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''TIANGUISTEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''TLANCHINOL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''XOCHICOATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''YAHUALICA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''HGO'', 64, 32, NULL, N''ZACUALTIPAN DE ANGELES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''774'', N''VER'', 64, 32, NULL, N''HUAYACOCOTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''775'', N''HGO'', 64, 32, NULL, N''ACATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''775'', N''HGO'', 64, 32, NULL, N''CHAPULHUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''775'', N''HGO'', 64, 32, NULL, N''CUAUTEPEC DE HINOJOSA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''775'', N''HGO'', 64, 32, NULL, N''SANTIA TULANTEPEC DE LU GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''775'', N''HGO'', 64, 32, NULL, N''SINGUILUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''775'', N''HGO'', 64, 32, NULL, N''TULANCIN DE BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''776'', N''HGO'', 64, 32, NULL, N''ACAXOCHITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''776'', N''HGO'', 64, 32, NULL, N''TENAN DE DORIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''776'', N''PUE'', 64, 32, NULL, N''AHUAZOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''776'', N''PUE'', 64, 32, NULL, N''CHICONCUAUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''776'', N''PUE'', 64, 32, NULL, N''CHILA HONEY'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''776'', N''PUE'', 64, 32, NULL, N''HUAUCHINAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''776'', N''PUE'', 64, 32, NULL, N''PAHUATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''777'', N''MOR'', 64, 32, NULL, N''CUERNAVACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''777'', N''MOR'', 64, 32, NULL, N''EMILIANO ZAPATA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''777'', N''MOR'', 64, 32, NULL, N''HUITZILAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''777'', N''MOR'', 64, 32, NULL, N''JIUTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''777'', N''MOR'', 64, 32, NULL, N''TEMIXCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''777'', N''MOR'', 64, 32, NULL, N''XOCHITEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''777'', N''MOR'', 64, 32, NULL, N''YAUTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''778'', N''HGO'', 64, 32, NULL, N''AJACUBA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''778'', N''HGO'', 64, 32, NULL, N''ATITALAQUIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''778'', N''HGO'', 64, 32, NULL, N''ATOTONILCO DE TULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''778'', N''HGO'', 64, 32, NULL, N''TLAXCOAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''779'', N''HGO'', 64, 32, NULL, N''TIZAYUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''781'', N''GRO'', 64, 32, NULL, N''BENITO JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''781'', N''GRO'', 64, 32, NULL, N''COYUCA DE BENITEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''782'', N''VER'', 64, 32, NULL, N''COATZINTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''782'', N''VER'', 64, 32, NULL, N''POZA RICA DE HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''782'', N''VER'', 64, 32, NULL, N''TIHUATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''783'', N''VER'', 64, 32, NULL, N''TUXPAM DE RODRIGUEZ CANO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''783'', N''VER'', 64, 32, NULL, N''TUXPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''784'', N''VER'', 64, 32, NULL, N''CAZONES DE HERRERA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''784'', N''VER'', 64, 32, NULL, N''CHUMATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''784'', N''VER'', 64, 32, NULL, N''COAHUITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''784'', N''VER'', 64, 32, NULL, N''COXQUIHUI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''784'', N''VER'', 64, 32, NULL, N''COYUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''784'', N''VER'', 64, 32, NULL, N''ESPINAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''784'', N''VER'', 64, 32, NULL, N''FILOMENO MATA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''784'', N''VER'', 64, 32, NULL, N''MECATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''784'', N''VER'', 64, 32, NULL, N''PAPANTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''784'', N''VER'', 64, 32, NULL, N''PAPANTLA DE OLARTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''784'', N''VER'', 64, 32, NULL, N''ZOZOCOLCO DE HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''785'', N''VER'', 64, 32, NULL, N''CERRO AZUL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''785'', N''VER'', 64, 32, NULL, N''CHONTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''785'', N''VER'', 64, 32, NULL, N''CITLALTEPETL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''785'', N''VER'', 64, 32, NULL, N''IXCATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''785'', N''VER'', 64, 32, NULL, N''TANCOCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''785'', N''VER'', 64, 32, NULL, N''TEPETZINTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''786'', N''MICH'', 64, 32, NULL, N''APORO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''786'', N''MICH'', 64, 32, NULL, N''BENITO JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''786'', N''MICH'', 64, 32, NULL, N''HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''786'', N''MICH'', 64, 32, NULL, N''IRIMBO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''786'', N''MICH'', 64, 32, NULL, N''SENGUIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''786'', N''MICH'', 64, 32, NULL, N''SUSUPUATO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''786'', N''MICH'', 64, 32, NULL, N''TUXPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''786'', N''MICH'', 64, 32, NULL, N''TUZANTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''789'', N''HGO'', 64, 32, NULL, N''ATLAPEXCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''789'', N''HGO'', 64, 32, NULL, N''HUEJUTLA DE REYES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''789'', N''HGO'', 64, 32, NULL, N''JALTOCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''789'', N''VER'', 64, 32, NULL, N''CHALMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''789'', N''VER'', 64, 32, NULL, N''CHICONAMEL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''789'', N''VER'', 64, 32, NULL, N''PLATON SANCHEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''789'', N''VER'', 64, 32, NULL, N''TANTOYUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''789'', N''VER'', 64, 32, NULL, N''TEMPOAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''789'', N''VER'', 64, 32, NULL, N''TEMPOAL DE SANCHEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''791'', N''HGO'', 64, 32, NULL, N''TEPEAPULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''797'', N''PUE'', 64, 32, NULL, N''AQUIXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''797'', N''PUE'', 64, 32, NULL, N''CHIGNAHUAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''797'', N''PUE'', 64, 32, NULL, N''TEPETZINTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''797'', N''PUE'', 64, 32, NULL, N''TETELA DE OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''797'', N''PUE'', 64, 32, NULL, N''ZACATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''797'', N''PUE'', 64, 32, NULL, N''ZONZOTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''APODACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''CARMEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''CIENEGA DE FLORES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''GARCIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''GENERAL ESCOBEDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''GUADALUPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''MONTERREY'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''SALINAS VICTORIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''SAN NICOLAS DE LOS GARZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''SAN PEDRO GARZA GARCIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''SANTA CATARINA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''81'', N''NL'', 64, 32, NULL, N''SANTIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''821'', N''NL'', 64, 32, NULL, N''HUALAHUISES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''821'', N''NL'', 64, 32, NULL, N''ITURBIDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''821'', N''NL'', 64, 32, NULL, N''LINARES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''823'', N''NL'', 64, 32, NULL, N''CHINA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''823'', N''NL'', 64, 32, NULL, N''DOCTOR COSS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''823'', N''NL'', 64, 32, NULL, N''GENERAL BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''823'', N''NL'', 64, 32, NULL, N''LOS HERRERAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''823'', N''NL'', 64, 32, NULL, N''LOS RAMONES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''824'', N''NL'', 64, 32, NULL, N''SABINAS HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''824'', N''NL'', 64, 32, NULL, N''VALLECILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''825'', N''NL'', 64, 32, NULL, N''CIENEGA DE FLORES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''825'', N''NL'', 64, 32, NULL, N''DOCTOR NZALEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''825'', N''NL'', 64, 32, NULL, N''GENERAL ZUAZUA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''825'', N''NL'', 64, 32, NULL, N''HIGUERAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''825'', N''NL'', 64, 32, NULL, N''MARIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''825'', N''NL'', 64, 32, NULL, N''PESQUERIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''826'', N''NL'', 64, 32, NULL, N''ALLENDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''826'', N''NL'', 64, 32, NULL, N''ARAMBERRI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''826'', N''NL'', 64, 32, NULL, N''CADEREYTA JIMENEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''826'', N''NL'', 64, 32, NULL, N''GALEANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''826'', N''NL'', 64, 32, NULL, N''GENERAL TERAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''826'', N''NL'', 64, 32, NULL, N''GENERAL ZARAGOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''826'', N''NL'', 64, 32, NULL, N''MONTEMORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''826'', N''NL'', 64, 32, NULL, N''RAYONES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''828'', N''NL'', 64, 32, NULL, N''CADEREYTA JIMENEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''829'', N''NL'', 64, 32, NULL, N''BUSTAMANTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''829'', N''NL'', 64, 32, NULL, N''HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''829'', N''NL'', 64, 32, NULL, N''MINA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''829'', N''NL'', 64, 32, NULL, N''SALINAS VICTORIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''829'', N''NL'', 64, 32, NULL, N''VILLALDAMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''831'', N''TAMPS'', 64, 32, NULL, N''ANTIGUO MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''831'', N''TAMPS'', 64, 32, NULL, N''EL MANTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''832'', N''TAMPS'', 64, 32, NULL, N''BUSTAMANTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''832'', N''TAMPS'', 64, 32, NULL, N''MEZ FARIAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''832'', N''TAMPS'', 64, 32, NULL, N''JAUMAVE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''832'', N''TAMPS'', 64, 32, NULL, N''LLERA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''832'', N''TAMPS'', 64, 32, NULL, N''MIQUIHUANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''832'', N''TAMPS'', 64, 32, NULL, N''OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''832'', N''TAMPS'', 64, 32, NULL, N''PALMILLAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''832'', N''TAMPS'', 64, 32, NULL, N''TULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''832'', N''TAMPS'', 64, 32, NULL, N''XICOTENCATL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''833'', N''TAMPS'', 64, 32, NULL, N''ALTAMIRA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''833'', N''TAMPS'', 64, 32, NULL, N''CIUDAD MADERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''833'', N''TAMPS'', 64, 32, NULL, N''TAMPICO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''833'', N''VER'', 64, 32, NULL, N''CHONTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''833'', N''VER'', 64, 32, NULL, N''PANUCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''833'', N''VER'', 64, 32, NULL, N''PUEBLO VIEJO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''833'', N''VER'', 64, 32, NULL, N''TAMPICO ALTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''834'', N''TAMPS'', 64, 32, NULL, N''VICTORIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''835'', N''TAMPS'', 64, 32, NULL, N''ABASOLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''835'', N''TAMPS'', 64, 32, NULL, N''CASAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''835'', N''TAMPS'', 64, 32, NULL, N''GÜEMEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''835'', N''TAMPS'', 64, 32, NULL, N''HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''835'', N''TAMPS'', 64, 32, NULL, N''JIMENEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''835'', N''TAMPS'', 64, 32, NULL, N''MAINERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''835'', N''TAMPS'', 64, 32, NULL, N''PADILLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''835'', N''TAMPS'', 64, 32, NULL, N''SAN CARLOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''835'', N''TAMPS'', 64, 32, NULL, N''SOTO LA MARINA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''835'', N''TAMPS'', 64, 32, NULL, N''VILLAGRAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''836'', N''TAMPS'', 64, 32, NULL, N''ALDAMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''836'', N''TAMPS'', 64, 32, NULL, N''ALTAMIRA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''836'', N''TAMPS'', 64, 32, NULL, N''NZALEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''841'', N''TAMPS'', 64, 32, NULL, N''BURS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''841'', N''TAMPS'', 64, 32, NULL, N''CRUILLAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''841'', N''TAMPS'', 64, 32, NULL, N''MENDEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''841'', N''TAMPS'', 64, 32, NULL, N''SAN FERNANDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''842'', N''COAH'', 64, 32, NULL, N''GENERAL CEPEDA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''842'', N''COAH'', 64, 32, NULL, N''PARRAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''842'', N''ZAC'', 64, 32, NULL, N''CONCEPCION DEL ORO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''842'', N''ZAC'', 64, 32, NULL, N''MAZAPIL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''844'', N''COAH'', 64, 32, NULL, N''ARTEAGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''844'', N''COAH'', 64, 32, NULL, N''RAMOS ARIZPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''844'', N''COAH'', 64, 32, NULL, N''SALTILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''845'', N''SLP'', 64, 32, NULL, N''EBANO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''845'', N''SLP'', 64, 32, NULL, N''TAMUIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''846'', N''VER'', 64, 32, NULL, N''OZULUAMA DE MASCARENAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''846'', N''VER'', 64, 32, NULL, N''PANUCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''861'', N''COAH'', 64, 32, NULL, N''JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''861'', N''COAH'', 64, 32, NULL, N''PROGRESO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''861'', N''COAH'', 64, 32, NULL, N''SABINAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''861'', N''COAH'', 64, 32, NULL, N''SAN JUAN DE SABINAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''862'', N''COAH'', 64, 32, NULL, N''ALLENDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''862'', N''COAH'', 64, 32, NULL, N''GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''862'', N''COAH'', 64, 32, NULL, N''MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''862'', N''COAH'', 64, 32, NULL, N''NAVA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''862'', N''COAH'', 64, 32, NULL, N''VILLA UNION'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''862'', N''COAH'', 64, 32, NULL, N''ZARAGOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''864'', N''COAH'', 64, 32, NULL, N''MUZQUIZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''866'', N''COAH'', 64, 32, NULL, N''ABASOLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''866'', N''COAH'', 64, 32, NULL, N''CASTANOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''866'', N''COAH'', 64, 32, NULL, N''ESCOBEDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''866'', N''COAH'', 64, 32, NULL, N''FRONTERA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''866'', N''COAH'', 64, 32, NULL, N''MONCLOVA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''867'', N''COAH'', 64, 32, NULL, N''HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''867'', N''NL'', 64, 32, NULL, N''ANAHUAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''867'', N''TAMPS'', 64, 32, NULL, N''NUEVO LAREDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''868'', N''TAMPS'', 64, 32, NULL, N''MATAMOROS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''868'', N''TAMPS'', 64, 32, NULL, N''REYNOSA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''869'', N''COAH'', 64, 32, NULL, N''CUATRO CIENEGAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''869'', N''COAH'', 64, 32, NULL, N''CUATROCIENEGAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''869'', N''COAH'', 64, 32, NULL, N''LAMADRID'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''869'', N''COAH'', 64, 32, NULL, N''NADADORES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''869'', N''COAH'', 64, 32, NULL, N''OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''869'', N''COAH'', 64, 32, NULL, N''SACRAMENTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''869'', N''COAH'', 64, 32, NULL, N''SAN BUENAVENTURA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''871'', N''COAH'', 64, 32, NULL, N''MATAMOROS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''871'', N''COAH'', 64, 32, NULL, N''TORREON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''871'', N''DGO'', 64, 32, NULL, N''MEZ PALACIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''871'', N''DGO'', 64, 32, NULL, N''LERDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''872'', N''COAH'', 64, 32, NULL, N''FRANCISCO I. MADERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''872'', N''COAH'', 64, 32, NULL, N''SAN PEDRO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''872'', N''COAH'', 64, 32, NULL, N''SIERRA MOJADA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''872'', N''DGO'', 64, 32, NULL, N''MAPIMI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''872'', N''DGO'', 64, 32, NULL, N''TLAHUALILO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''873'', N''COAH'', 64, 32, NULL, N''CANDELA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''873'', N''NL'', 64, 32, NULL, N''ANAHUAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''873'', N''NL'', 64, 32, NULL, N''LAMPAZOS DE NARANJO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''877'', N''COAH'', 64, 32, NULL, N''ACUNA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''877'', N''COAH'', 64, 32, NULL, N''JIMENEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''878'', N''COAH'', 64, 32, NULL, N''JIMENEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''878'', N''COAH'', 64, 32, NULL, N''PIEDRAS NEGRAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''891'', N''TAMPS'', 64, 32, NULL, N''CAMARGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''891'', N''TAMPS'', 64, 32, NULL, N''GUSTAVO DIAZ ORDAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''892'', N''NL'', 64, 32, NULL, N''AGUALEGUAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''892'', N''NL'', 64, 32, NULL, N''CERRALVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''892'', N''NL'', 64, 32, NULL, N''GENERAL TREVIÑO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''892'', N''NL'', 64, 32, NULL, N''LOS ALDAMAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''892'', N''NL'', 64, 32, NULL, N''MELCHOR OCAMPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''892'', N''NL'', 64, 32, NULL, N''PARAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''894'', N''TAMPS'', 64, 32, NULL, N''RIO BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''894'', N''TAMPS'', 64, 32, NULL, N''VALLE HERMOSO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''897'', N''TAMPS'', 64, 32, NULL, N''GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''897'', N''TAMPS'', 64, 32, NULL, N''MIER'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''897'', N''TAMPS'', 64, 32, NULL, N''MIGUEL ALEMAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''899'', N''TAMPS'', 64, 32, NULL, N''REYNOSA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''899'', N''TAMPS'', 64, 32, NULL, N''RIO BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''913'', N''CAMP'', 64, 32, NULL, N''PALIZADA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''913'', N''TAB'', 64, 32, NULL, N''CENTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''913'', N''TAB'', 64, 32, NULL, N''JONUTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''914'', N''TAB'', 64, 32, NULL, N''CUNDUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''914'', N''TAB'', 64, 32, NULL, N''JALPA DE MENDEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''914'', N''TAB'', 64, 32, NULL, N''NACAJUCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''916'', N''CHIS'', 64, 32, NULL, N''CATAZAJA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''916'', N''CHIS'', 64, 32, NULL, N''PALENQUE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''916'', N''CHIS'', 64, 32, NULL, N''SALTO DE AGUA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''917'', N''CHIS'', 64, 32, NULL, N''REFORMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''917'', N''TAB'', 64, 32, NULL, N''HUIMANGUILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''918'', N''CHIS'', 64, 32, NULL, N''ACACOYAGUA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''918'', N''CHIS'', 64, 32, NULL, N''ACAPETAHUA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''918'', N''CHIS'', 64, 32, NULL, N''ESCUINTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''918'', N''CHIS'', 64, 32, NULL, N''MAPASTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''918'', N''CHIS'', 64, 32, NULL, N''PIJIJIAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''918'', N''CHIS'', 64, 32, NULL, N''VILLA COMALTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''ALTAMIRANO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''BENEMERITO DE LAS AMERICAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''BOCHIL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''CHALCHIHUITAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''CHAPULTENAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''CHENALHO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''CHILON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''COAPILLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''EL BOSQUE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''HUITIUPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''IXHUATAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''JITOTOL'')
';
EXEC(@sql);
SET @process = 'Actualizar tabla ZonasHorarias'
		SET @sql = '

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''MARQUES DE COMILLAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''OCOSIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''OXCHUC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''PANTELHO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''PUEBLO NUEVO SOLISTAHUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''RAYON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''SABANILLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''SAN JUAN CANCUC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''SIMOJOVEL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''SOLOSUCHIAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''TAPILULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''TILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''TUMBALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''919'', N''CHIS'', 64, 32, NULL, N''YAJALON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''921'', N''VER'', 64, 32, NULL, N''COATZACOALCOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''921'', N''VER'', 64, 32, NULL, N''COSOLEACAQUE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''921'', N''VER'', 64, 32, NULL, N''IXHUATLAN DEL SURESTE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''921'', N''VER'', 64, 32, NULL, N''NANCHITAL DE LAZARO CARDENAS DEL RIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''922'', N''VER'', 64, 32, NULL, N''CHINAMECA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''922'', N''VER'', 64, 32, NULL, N''COSOLEACAQUE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''922'', N''VER'', 64, 32, NULL, N''JALTIPAN DE MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''922'', N''VER'', 64, 32, NULL, N''MINATITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''922'', N''VER'', 64, 32, NULL, N''UXPANAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''922'', N''VER'', 64, 32, NULL, N''ZARAGOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''923'', N''TAB'', 64, 32, NULL, N''CARDENAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''923'', N''TAB'', 64, 32, NULL, N''HUIMANGUILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''923'', N''VER'', 64, 32, NULL, N''AGUA DULCE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''923'', N''VER'', 64, 32, NULL, N''LAS CHOAPAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''923'', N''VER'', 64, 32, NULL, N''MOLOACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''OAX'', 64, 32, NULL, N''SAN JUAN COTZOCON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''ACAYUCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''HIDALGOTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''JESUS CARRANZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''MECAYAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''OLUTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''PAJAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''SAN JUAN EVANGELISTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''SAYULA DE ALEMAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''SOCONUSCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''SOTEAPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''TATAHUICAPAN DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''TEXISTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''924'', N''VER'', 64, 32, NULL, N''UXPANAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''932'', N''CHIS'', 64, 32, NULL, N''IXTACOMITAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''932'', N''CHIS'', 64, 32, NULL, N''JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''932'', N''CHIS'', 64, 32, NULL, N''OSTUACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''932'', N''CHIS'', 64, 32, NULL, N''PICHUCALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''932'', N''TAB'', 64, 32, NULL, N''JALAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''932'', N''TAB'', 64, 32, NULL, N''TACOTALPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''932'', N''TAB'', 64, 32, NULL, N''TEAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''933'', N''TAB'', 64, 32, NULL, N''COMALCALCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''933'', N''TAB'', 64, 32, NULL, N''PARAISO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''934'', N''CHIS'', 64, 32, NULL, N''LA LIBERTAD'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''934'', N''TAB'', 64, 32, NULL, N''BALANCAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''934'', N''TAB'', 64, 32, NULL, N''EMILIANO ZAPATA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''934'', N''TAB'', 64, 32, NULL, N''TENOSIQUE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''936'', N''TAB'', 64, 32, NULL, N''MACUSPANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''937'', N''TAB'', 64, 32, NULL, N''CARDENAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''938'', N''CAMP'', 64, 32, NULL, N''CARMEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''ABEJONES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''ASUNCION NOCHIXTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''AYOQUEZCO DE ALDAMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''CAPULALPAM DE MENDEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''CIENEGA DE ZIMATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''COATECAS ALTAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''CULLAPAM DE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''EJUTLA DE CRESPO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''IXTLAN DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''LA COMPANIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''LA PE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''MAGDALENA JALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''MAGDALENA TEITIPAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''MIAHUATLAN DE PORFIRIO DIAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''OAXACA DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''OCOTLAN DE MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN AGUSTIN AMATEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN AGUSTIN DE LAS JUNTAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN AGUSTIN ETLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN ANDRES HUAYAPAM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN ANDRES SINAXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN ANDRES ZABACHE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN ANTONIO HUITEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN BALTAZAR CHICHICAPAM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN BARTOLO COYOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN BARTOLOME QUIALANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN BARTOLOME ZOOCHO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN BERNARDO MIXTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN CRISTOBAL AMATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN CRISTOBAL LACHIRIOAG'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN DIONISIO OCOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN FELIPE TEJALAPAM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN FRANCISCO TELIXCAHUACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN ILDEFONSO VILLA ALTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN JERONIMO COATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN JERONIMO TLACOCHAHUAYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN JOSE DEL PROGRESO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN JUAN ATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN JUAN BAUTISTA GUELACHE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN JUAN CHILATECA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN JUAN DEL ESTADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN JUAN DEL RIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN JUAN QUIOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN LORENZO CACAOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN LUCAS QUIAVINI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN MARTIN TILCAJETE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN MATEO ETLATON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN MATEO SINDIHUI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL ALOAPAM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL AMATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL COATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL MIXTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL TALEA DE CASTRO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL TILQUIAPAM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN NICOLAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN PABLO HUITZO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN PABLO HUIXTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN PABLO MACUILTIANGUIS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN PABLO VILLA DE MITLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN PEDRO APOSTOL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN PEDRO CAJONOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN PEDRO IXTLAHUACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN PEDRO SOCHIAPAM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN PEDRO TOTOLAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN PEDRO Y SAN PABLO AYUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN PEDRO YOLOX'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN RAYMUNDO JALPAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN SEBASTIAN ABASOLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN SIMON ALMOLONGAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SAN VICENTE COATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA ANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA ANA TLAPACOYAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA ANA YANERI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA ANA ZEGACHE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA CATARINA CUIXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA CATARINA IXTEPEJI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA CATARINA MINAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA CRUZ AMILPAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA CRUZ MIXTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA CRUZ PAPALUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA CRUZ XITLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA CRUZ XOXOCOTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA GERTRUDIS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA INES YATZECHE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA LUCIA OCOTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA MARIA ATZOMPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA MARIA CHACHOAPAM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA MARIA DEL TULE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA MARIA GUELACE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTA MARIA ZOQUITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTIA COMALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTIA MATATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTIA SUCHILQUITON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTIA XIACUI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTO DOMIN TEOJOMULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTO DOMIN XAGACIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTO DOMIN YANHUITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTO TOMAS JALIEZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SANTO TOMAS MAZALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''SOLEDAD ETLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''TEOCOCUILCO DE MARCOS PEREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''TEOTITLAN DEL VALLE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''TLACOLULA DE MATAMOROS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''TLALIXTAC DE CABRERA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''TRINIDAD ZAACHILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''VILLA DE ZAACHILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''VILLA DIAZ ORDAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''VILLA ETLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''VILLA HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''VILLA SOLA DE VEGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''YAXE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''YOGANA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''951'', N''OAX'', 64, 32, NULL, N''ZIMATLAN DE ALVAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''ASUNCION CUYOTEPEJI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''CALIHUALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''CHALCATON DE HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''COICOYAN DE LAS FLORES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''CONCEPCION BUENAVISTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''FRESNILLO DE TRUJANO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''GUADALUPE RAMIREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''HEROICA CIUDAD DE HUAJUAPAN DE LEON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''HUAJAPAN DE LEON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''IXPANTEPEC NIEVES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''MARISCALA DE JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''MESONES HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''PUTLA VILLA DE GUERRERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN AGUSTIN ATENAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN ANDRES DINICUITI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN ANTONINO MONTE VERDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN FRANCISCO TLAPANCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN JUAN BAUTISTA COIXTLAHUACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN JUAN MIXTEPEC (DISTRITO 8)'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN LORENZO VICTORIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN MARCOS ARTEAGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN MARTIN PERAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL AHUEHUETITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL EL GRANDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL TLACOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN NICOLAS HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN PEDRO Y SAN PABLO TEPOSCOLULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN SEBASTIAN NICANANDUTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SAN SEBASTIAN TECOMAXTLAHUACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTA CATARINA TICUA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTA CRUZ TACACHE DE MINA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTA MARIA CHILAPA DE DIAZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTA MARIA COMATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTA MARIA YUCUHITI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTIA AYUQUILILLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTIA CACALOXTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTIA CHAZUMBA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTIA HUAJOLOTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTIA JUXTLAHUACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTIA TAMAZOLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTIA YOLOMECATL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTIA YOSONDUA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTO DOMIN TONALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SANTOS REYES TEPEJILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''SILACAYOAPAM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''TEOTON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''TEPELMEME VILLA DE MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''TEZOATLAN DE SEGURA Y LUNA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''TLACOTEPEC PLUMAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''TLAXIACO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''VILLA DE TAMAZULAPAM DEL PROGRESO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''VILLA TEJUPAM DE LA UNION'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''OAX'', 64, 32, NULL, N''ZAPOTITLAN PALMAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''PUE'', 64, 32, NULL, N''ACATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''PUE'', 64, 32, NULL, N''CHILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''PUE'', 64, 32, NULL, N''PETLALCIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''PUE'', 64, 32, NULL, N''SAN JERONIMO XAYACATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''953'', N''PUE'', 64, 32, NULL, N''XAYACATLAN DE BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''LA REFORMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''MARTIRES DE TACUBAYA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''PINOTEPA DE DON LUIS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN AGUSTIN CHAYUCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN ANDRES HUAXPALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN ANTONIO TEPETLAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN GABRIEL MIXTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN JOSE ESTANCIA GRANDE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN JUAN BAUTISTA LO DE SOTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN JUAN CACAHUATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN JUAN COLORADO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN JUAN QUIAHIJE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN LORENZO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL PANIXTLAHUACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL TLACAMAMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN PEDRO AMUZS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN PEDRO ATOYAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN PEDRO JICAYAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN PEDRO JUCHATEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN PEDRO MIXTEPEC - DTO. 22-'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN PEDRO MIXTEPEC DISTR. 22'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN PEDRO TUTUTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SAN SEBASTIAN IXCAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTA CATARINA JUQUILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTA CATARINA MECHOACAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTA CRUZ ITUNDUJIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTA MARIA CORTIJO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTA MARIA HUAZOLOTITLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTA MARIA IPALAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTA MARIA TEMAXCALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTA MARIA ZACATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTIA IXTAYUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTIA JAMILTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTIA PINOTEPA NACIONAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTIA TETEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTIA YAITEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''SANTOS REYES NOPALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''954'', N''OAX'', 64, 32, NULL, N''TATALTEPEC DE VALDES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''958'', N''OAX'', 64, 32, NULL, N''CANDELARIA LOXICHA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''958'', N''OAX'', 64, 32, NULL, N''PLUMA HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''958'', N''OAX'', 64, 32, NULL, N''SAN AGUSTIN LOXICHA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''958'', N''OAX'', 64, 32, NULL, N''SAN BALTAZAR LOXICHA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''958'', N''OAX'', 64, 32, NULL, N''SAN BARTOLOME LOXICHA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''958'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL DEL PUERTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''958'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL SUCHIXTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''958'', N''OAX'', 64, 32, NULL, N''SAN PEDRO POCHUTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''958'', N''OAX'', 64, 32, NULL, N''SANTA CATARINA LOXICHA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''958'', N''OAX'', 64, 32, NULL, N''SANTA MARIA HUATULCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''958'', N''OAX'', 64, 32, NULL, N''SANTA MARIA TONAMECA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''958'', N''OAX'', 64, 32, NULL, N''SANTO DOMIN DE MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''961'', N''CHIS'', 64, 32, NULL, N''ACALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''961'', N''CHIS'', 64, 32, NULL, N''BERRIOZABAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''961'', N''CHIS'', 64, 32, NULL, N''CHIAPA DE CORZO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''961'', N''CHIS'', 64, 32, NULL, N''CHICOASEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''961'', N''CHIS'', 64, 32, NULL, N''IXTAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''961'', N''CHIS'', 64, 32, NULL, N''OSUMACINTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''961'', N''CHIS'', 64, 32, NULL, N''SAN FERNANDO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''961'', N''CHIS'', 64, 32, NULL, N''SOYALO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''961'', N''CHIS'', 64, 32, NULL, N''SUCHIAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''961'', N''CHIS'', 64, 32, NULL, N''TUXTLA GUTIERREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''961'', N''CHIS'', 64, 32, NULL, N''ZINACANTAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''962'', N''CHIS'', 64, 32, NULL, N''CACAHOATAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''962'', N''CHIS'', 64, 32, NULL, N''FRONTERA HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''962'', N''CHIS'', 64, 32, NULL, N''MAZAPA DE MADERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''962'', N''CHIS'', 64, 32, NULL, N''METAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''962'', N''CHIS'', 64, 32, NULL, N''MOTOZINTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''962'', N''CHIS'', 64, 32, NULL, N''SUCHIATE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''962'', N''CHIS'', 64, 32, NULL, N''TAPACHULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''962'', N''CHIS'', 64, 32, NULL, N''TUXTLA CHICO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''962'', N''CHIS'', 64, 32, NULL, N''UNION JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''963'', N''CHIS'', 64, 32, NULL, N''AMATENAN DE LA FRONTERA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''963'', N''CHIS'', 64, 32, NULL, N''CHANAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''963'', N''CHIS'', 64, 32, NULL, N''CHICOMUSELO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''963'', N''CHIS'', 64, 32, NULL, N''COMITAN DE DOMINGUEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''963'', N''CHIS'', 64, 32, NULL, N''FRONTERA COMALAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''963'', N''CHIS'', 64, 32, NULL, N''LA INDEPENDENCIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''963'', N''CHIS'', 64, 32, NULL, N''LA TRINITARIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''963'', N''CHIS'', 64, 32, NULL, N''LAS MARGARITAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''963'', N''CHIS'', 64, 32, NULL, N''SILTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''963'', N''CHIS'', 64, 32, NULL, N''TZIMOL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''964'', N''CHIS'', 64, 32, NULL, N''HUEHUETAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''964'', N''CHIS'', 64, 32, NULL, N''HUIXTLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''964'', N''CHIS'', 64, 32, NULL, N''MAZATAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''964'', N''CHIS'', 64, 32, NULL, N''TUZANTAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''965'', N''CHIS'', 64, 32, NULL, N''VILLA CORZO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''965'', N''CHIS'', 64, 32, NULL, N''VILLAFLORES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''966'', N''CHIS'', 64, 32, NULL, N''ARRIAGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''966'', N''CHIS'', 64, 32, NULL, N''TONALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''967'', N''CHIS'', 64, 32, NULL, N''CHAMULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''967'', N''CHIS'', 64, 32, NULL, N''HUIXTAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''967'', N''CHIS'', 64, 32, NULL, N''LARRAINZAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''967'', N''CHIS'', 64, 32, NULL, N''SAN CRISTOBAL DE LAS CASAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''967'', N''CHIS'', 64, 32, NULL, N''SAN LUCAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''967'', N''CHIS'', 64, 32, NULL, N''TENEJAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''968'', N''CHIS'', 64, 32, NULL, N''CINTALAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''968'', N''CHIS'', 64, 32, NULL, N''COPAINALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''968'', N''CHIS'', 64, 32, NULL, N''JIQUIPILAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''968'', N''CHIS'', 64, 32, NULL, N''OCOZOCOAUTLA DE ESPINOSA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''968'', N''CHIS'', 64, 32, NULL, N''TECPATAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''969'', N''YUC'', 64, 32, NULL, N''PROGRESO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''ASUNCION IXTALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''CD. IXTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''CIUDAD IXTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''EL ESPINAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''HEROICA CIUDAD DE JUCHITAN DE ZARAGOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''JUCHITAN DE ZARAGOZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''SALINA CRUZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''SAN MATEO DEL MAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''SAN PEDRO COMITANCILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''SAN PEDRO HUILOTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''SANTA MARIA MIXTEQUILLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''SANTA MARIA XADANI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''SANTO DOMIN TEHUANTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''STO. DOMIN CHIHUITAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''971'', N''OAX'', 64, 32, NULL, N''UNION HIDALGO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''972'', N''OAX'', 64, 32, NULL, N''ASUNCION IXTALTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''972'', N''OAX'', 64, 32, NULL, N''EL BARRIO DE LA SOLEDAD'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''972'', N''OAX'', 64, 32, NULL, N''MATIAS ROMERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''972'', N''OAX'', 64, 32, NULL, N''MATIAS ROMERO AVENDAÑO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''972'', N''OAX'', 64, 32, NULL, N''MATIAS ROMERO AVENDAÑO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''972'', N''OAX'', 64, 32, NULL, N''SAN JUAN GUICHICOVI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''972'', N''OAX'', 64, 32, NULL, N''SAN JUAN MAZATLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''972'', N''OAX'', 64, 32, NULL, N''SANTO DOMIN PETAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''981'', N''CAMP'', 64, 32, NULL, N''CAMPECHE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''982'', N''CAMP'', 64, 32, NULL, N''CANDELARIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''982'', N''CAMP'', 64, 32, NULL, N''CARMEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''982'', N''CAMP'', 64, 32, NULL, N''CHAMPOTON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''982'', N''CAMP'', 64, 32, NULL, N''ESCARCEGA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''983'', N''CAMP'', 64, 32, NULL, N''CALAKMUL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''983'', N''QROO'', 32, 32, NULL, N''FELIPE CARRILLO PUERTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''983'', N''QROO'', 32, 32, NULL, N''OTHON P. BLANCO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''984'', N''QROO'', 32, 32, NULL, N''LAZARO CARDENAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''984'', N''QROO'', 32, 32, NULL, N''SOLIDARIDAD'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''CHEMAX'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''CHICHIMILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''CHIKINDZONOT'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''CUNCUNUL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''DZITAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''KAUA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''TEKOM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''TEMOZON'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''TINUM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''TIXCACALCUPUL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''UAYMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''VALLADOLID'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''985'', N''YUC'', 64, 32, NULL, N''YAXCABA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''986'', N''YUC'', 64, 32, NULL, N''CALOTMUL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''986'', N''YUC'', 64, 32, NULL, N''ESPITA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''986'', N''YUC'', 64, 32, NULL, N''PANABA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''986'', N''YUC'', 64, 32, NULL, N''RIO LAGARTOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''986'', N''YUC'', 64, 32, NULL, N''SAN FELIPE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''986'', N''YUC'', 64, 32, NULL, N''SUCILA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''986'', N''YUC'', 64, 32, NULL, N''TIZIMIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''987'', N''QROO'', 32, 32, NULL, N''COZUMEL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''ABALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''ACANCEH'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''CELESTUN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''CHOCHOLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''CUZAMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''HOCABA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''HOCTUN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''HOMUN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''HUHI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''HUNUCMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''IZAMAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''KANTUNIL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''KINCHIL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''SAMAHIL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''SEYE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''SOTUTA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''TAHMEK'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''TECOH'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''TETIZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''TIMUCUY'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''UCU'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''UMAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''988'', N''YUC'', 64, 32, NULL, N''XOCCHEL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''BACA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''BUCTZOTZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''CACALCHEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''CANSAHCAB'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''CENOTILLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''DZEMUL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''DZIDZANTUN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''DZILAM DE BRAVO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''DZILAM NZALEZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''DZONCAUICH'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''IXIL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''MOCOCHA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''MOTUL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''MUXUPIP'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''SINANCHE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''TEKAL DE VENEGAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''TEKANTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''TELCHAC PUEBLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''TELCHAC PUERTO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''TEMAX'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''TEPAKAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''TIXKOKOB'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''TUNKAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''991'', N''YUC'', 64, 32, NULL, N''YOBAIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''992'', N''CHIS'', 64, 32, NULL, N''AMATENAN DEL VALLE'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''992'', N''CHIS'', 64, 32, NULL, N''ANGEL ALBINO CORZO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''992'', N''CHIS'', 64, 32, NULL, N''CHIAPILLA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''992'', N''CHIS'', 64, 32, NULL, N''LA CONCORDIA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''992'', N''CHIS'', 64, 32, NULL, N''LAS ROSAS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''992'', N''CHIS'', 64, 32, NULL, N''SOCOLTENAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''992'', N''CHIS'', 64, 32, NULL, N''TEOPISCA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''992'', N''CHIS'', 64, 32, NULL, N''TOTOLAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''992'', N''CHIS'', 64, 32, NULL, N''VENUSTIANO CARRANZA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''993'', N''TAB'', 64, 32, NULL, N''CENTRO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''994'', N''CHIS'', 64, 32, NULL, N''TONALA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''994'', N''OAX'', 64, 32, NULL, N''CHAHUITES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''994'', N''OAX'', 64, 32, NULL, N''SAN DIONISIO DEL MAR'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''994'', N''OAX'', 64, 32, NULL, N''SAN FCO. IXHUATAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''994'', N''OAX'', 64, 32, NULL, N''SAN MIGUEL CHIMALAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''994'', N''OAX'', 64, 32, NULL, N''SAN PEDRO TAPANATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''994'', N''OAX'', 64, 32, NULL, N''SANTA MARIA CHIMALAPA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''994'', N''OAX'', 64, 32, NULL, N''SANTIA NILTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''994'', N''OAX'', 64, 32, NULL, N''SANTO DOMIN INGENIO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''994'', N''OAX'', 64, 32, NULL, N''STO. DOMIN ZANATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''995'', N''OAX'', 64, 32, NULL, N''MAGDALENA TEQUISISTLAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''995'', N''OAX'', 64, 32, NULL, N''NEJAPA DE MADERO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''995'', N''OAX'', 64, 32, NULL, N''SAN CARLOS YAUTEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''995'', N''OAX'', 64, 32, NULL, N''SAN JUAN JUQILA MIXES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''995'', N''OAX'', 64, 32, NULL, N''SAN PEDRO HUAMELULA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''995'', N''OAX'', 64, 32, NULL, N''SAN PEDRO QUIATONI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''995'', N''OAX'', 64, 32, NULL, N''SANTA ANA TAVELA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''995'', N''OAX'', 64, 32, NULL, N''SANTA MARIA ECATEPEC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''995'', N''OAX'', 64, 32, NULL, N''SANTA MARIA JALAPA DEL MARQUES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''995'', N''OAX'', 64, 32, NULL, N''SANTIA ASTATA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''996'', N''CAMP'', 64, 32, NULL, N''CALKINI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''996'', N''CAMP'', 64, 32, NULL, N''HECELCHAKAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''996'', N''CAMP'', 64, 32, NULL, N''HOPELCHEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''996'', N''CAMP'', 64, 32, NULL, N''TENABO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''QROO'', 32, 32, NULL, N''JOSE MARIA MORELOS'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''AKIL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''CHAPAB'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''CHUMAYEL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''DZAN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''HALACHO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''KOPOMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''MAMA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''MANI'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''MAXCANU'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''MUNA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''OPICHEN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''OXKUTZCAB'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''PETO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''SACALUM'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''SANTA ELENA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''TAHDZIU'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''TEABO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''TEKAX'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''TEKAX DE ALVARO OBREN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''TEKIT'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''TICUL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''TIXMEHUAC'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''997'', N''YUC'', 64, 32, NULL, N''TZUCACAB'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''998'', N''QROO'', 32, 32, NULL, N''BENITO JUAREZ'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''998'', N''QROO'', 32, 32, NULL, N''ISLA MUJERES'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''999'', N''YUC'', 64, 32, NULL, N''CHICXULUB PUEBLO'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''999'', N''YUC'', 64, 32, NULL, N''CONKAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''999'', N''YUC'', 64, 32, NULL, N''KANASIN'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''999'', N''YUC'', 64, 32, NULL, N''MERIDA'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (1, N''999'', N''YUC'', 64, 32, NULL, N''TIXPEHUAL'')

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''11'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''220'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2202'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''221'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2221'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2223'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2224'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2225'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2226'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2227'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2229'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''223'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2241'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2242'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2243'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2244'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2245'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2246'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2252'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2254'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2255'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2257'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2261'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2262'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2264'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2265'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2266'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2267'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2268'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2271'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2272'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2273'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2274'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2281'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2283'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2284'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2285'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2286'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2291'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2292'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2293'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2296'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2297'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2302'', N''La Pampa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2314'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2316'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2317'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2320'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2322'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2323'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2324'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2325'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2326'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2331'', N''La Pampa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2333'', N''La Pampa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2334'', N''La Pampa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2335'', N''La Pampa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2336'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2337'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2338'', N''La Pampa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2342'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2343'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2344'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2345'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2346'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2352'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2353'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2354'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2355'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2356'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2357'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2358'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2362'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''237'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2392'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2393'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2394'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2395'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2396'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2473'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2474'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2475'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2477'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2478'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''261'', N''Mendoza'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2622'', N''Mendoza'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2623'', N''Mendoza'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2624'', N''Mendoza'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2625'', N''Mendoza'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2626'', N''Mendoza'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2627'', N''Mendoza'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''264'', N''San Juan'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2646'', N''San Juan'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2647'', N''San Juan'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2648'', N''San Juan'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2651'', N''San Luis'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2652'', N''San Luis'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2655'', N''San Luis'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2656'', N''San Luis'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2657'', N''San Luis'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2658'', N''San Luis'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2901'', N''Tierra del Fue'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2902'', N''Santa Cruz'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2903'', N''Chubut'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''291'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2920'', N''Rio Negro'', 8, 4, NULL, NULL)
';
EXEC(@sql);
SET @process = 'Actualizar tabla ZonasHorarias'
		SET @sql = '

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2921'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2922'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2923'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2924'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2925'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2926'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2927'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2928'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2929'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2931'', N''Rio Negro'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2932'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2933'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2934'', N''Rio Negro'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2935'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2936'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2940'', N''Rio Negro'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2941'', N''Rio Negro'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2942'', N''Neuquen'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2944'', N''Rio Negro'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2945'', N''Chubut'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2946'', N''Rio Negro'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2948'', N''Neuquen'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2952'', N''La Pampa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2953'', N''La Pampa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2954'', N''La Pampa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2962'', N''Santa Cruz'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2963'', N''Santa Cruz'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2964'', N''Tierra del Fue'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2965'', N''Chubut'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2966'', N''Santa Cruz'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''297'', N''Chubut'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2972'', N''Neuquen'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2982'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''2983'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''299'', N''Neuquen'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3327'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3329'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3382'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3385'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3387'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3388'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3400'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3401'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3402'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3404'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3405'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3406'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3407'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3408'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3409'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''341'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''342'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''343'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3435'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3436'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3437'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3438'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3442'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3444'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3445'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3446'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3447'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''345'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3454'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3455'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3456'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3458'', N''Entre Rios'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3460'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3461'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3462'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3463'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3464'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3465'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3466'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3467'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3468'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3469'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3471'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3472'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3476'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3482'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3483'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3487'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3488'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3489'', N''Buenos Aires'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3491'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3492'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3493'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3496'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3497'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3498'', N''Santa Fe'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''351'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3521'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3522'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3524'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3525'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''353'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3532'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3533'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3534'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3541'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3542'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3543'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3544'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3546'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3547'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3548'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3549'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3562'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3563'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3564'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3571'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3572'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3573'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3574'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3575'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3576'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''358'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3582'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3583'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3584'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3585'', N''Cordoba'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3711'', N''Formosa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3715'', N''Formosa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3716'', N''Formosa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3717'', N''Formosa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3718'', N''Formosa'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3721'', N''Chaco'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3722'', N''Chaco'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3725'', N''Chaco'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3731'', N''Chaco'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3732'', N''Chaco'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3734'', N''Chaco'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3735'', N''Chaco'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3741'', N''Misiones'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3743'', N''Misiones'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3751'', N''Misiones'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3752'', N''Misiones'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3754'', N''Misiones'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3755'', N''Misiones'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3756'', N''Corrientes'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3757'', N''Misiones'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3758'', N''Misiones'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3772'', N''Corrientes'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3773'', N''Corrientes'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3774'', N''Corrientes'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3775'', N''Corrientes'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3777'', N''Corrientes'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3781'', N''Corrientes'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3782'', N''Corrientes'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3783'', N''Corrientes'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3786'', N''Corrientes'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''381'', N''Tucuman'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3821'', N''La Rioja'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3822'', N''La Rioja'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3825'', N''La Rioja'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3826'', N''La Rioja'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3827'', N''La Rioja'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3832'', N''Catamarca'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3833'', N''Catamarca'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3835'', N''Catamarca'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3837'', N''Catamarca'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3838'', N''Catamarca'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3841'', N''Santia del Estero'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3843'', N''Santia del Estero'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3844'', N''Santia del Estero'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3845'', N''Santia del Estero'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3846'', N''Santia del Estero'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''385'', N''Santia Del Estero'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3854'', N''Santia del Estero'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3855'', N''Santia del Estero'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3856'', N''Santia del Estero'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3857'', N''Santia del Estero'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3858'', N''Santia del Estero'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3861'', N''Santia del Estero'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3862'', N''Tucuman'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3863'', N''Tucuman'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3865'', N''Tucuman'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3867'', N''Tucuman'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3868'', N''Salta'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3869'', N''Tucuman'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''387'', N''Salta'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3875'', N''Salta'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3876'', N''Salta'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3877'', N''Salta'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3878'', N''Salta'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''388'', N''Jujuy'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3884'', N''Jujuy'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3885'', N''Jujuy'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3886'', N''Jujuy'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3887'', N''Jujuy'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3891'', N''Tucuman'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3892'', N''Tucuman'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (2, N''3894'', N''Tucuman'', 8, 4, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (3, N''1'', N''Bota'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (3, N''2'', N''Cali'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (3, N''4'', N''Medellin'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (3, N''5'', N''Cartagena'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (3, N''6'', N''Armenia'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (3, N''7'', N''Bucaramanga'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (3, N''8'', N''Tunja'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''201'', N''NJ'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''202'', N''DC'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''203'', N''CT'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''204'', N''Manitoba'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''205'', N''AL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''206'', N''WA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''207'', N''ME'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''208'', N''ID'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''209'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''210'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''212'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''213'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''214'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''215'', N''PA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''216'', N''OH'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''217'', N''IL'', 64, 32, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''218'', N''MN'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''219'', N''IN'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''224'', N''IL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''225'', N''LA'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''226'', N''Ontario'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''227'', N''MD'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''228'', N''MS'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''229'', N''GA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''231'', N''MI'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''234'', N''OH'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''239'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''240'', N''MD'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''242'', N''Bahamas'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''246'', N''Barbados'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''248'', N''MI'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''250'', N''British Columbia'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''251'', N''AL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''252'', N''NC'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''253'', N''WA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''254'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''256'', N''AL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''260'', N''IN'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''262'', N''WI'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''264'', N''Anguilla'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''267'', N''PA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''268'', N''Antigua/Barbuda'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''269'', N''MI'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''270'', N''KY'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''274'', N''WI'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''276'', N''VA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''281'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''283'', N''OH'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''284'', N''British Virgin Islands'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''289'', N''Ontario'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''301'', N''MD'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''302'', N''DE'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''303'', N''CO'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''304'', N''WV'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''305'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''306'', N''Saskatchewan'', 64, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''307'', N''WY'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''308'', N''NE'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''309'', N''IL'', 64, 32, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''310'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''312'', N''IL'', 64, 32, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''313'', N''MI'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''314'', N''MO'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''315'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''316'', N''KS'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''317'', N''IN'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''318'', N''LA'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''319'', N''IA'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''320'', N''MN'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''321'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''323'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''325'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''330'', N''OH'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''331'', N''IL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''334'', N''AL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''336'', N''NC'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''337'', N''LA'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''339'', N''MA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''340'', N''USVI'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''341'', N''CA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''345'', N''Cayman Islands'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''347'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''351'', N''MA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''352'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''360'', N''WA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''361'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''364'', N''KY'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''369'', N''CA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''380'', N''OH'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''385'', N''UT'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''386'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''401'', N''RI'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''402'', N''NE'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''403'', N''Alberta'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''404'', N''GA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''405'', N''OK'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''406'', N''MT'', 128, 64, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''407'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''408'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''409'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''410'', N''MD'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''412'', N''PA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''413'', N''MA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''414'', N''WI'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''415'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''416'', N''Ontario'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''417'', N''MO'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''418'', N''Quebec'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''419'', N''OH'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''423'', N''TN'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''424'', N''CA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''425'', N''WA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''430'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''432'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''434'', N''VA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''435'', N''UT'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''438'', N''Quebec'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''440'', N''OH'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''441'', N''Bermuda'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''442'', N''CA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''443'', N''MD'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''447'', N''IL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''450'', N''Quebec'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''458'', N''OR'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''464'', N''IL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''469'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''470'', N''GA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''473'', N''Grenada'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''475'', N''CT'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''478'', N''GA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''479'', N''AR'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''480'', N''AZ'', 128, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''484'', N''PA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''501'', N''AR'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''502'', N''KY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''503'', N''OR'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''504'', N''LA'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''505'', N''NM'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''506'', N''New Brunswick'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''507'', N''MN'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''508'', N''MA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''509'', N''WA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''510'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''512'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''513'', N''OH'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''514'', N''Quebec'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''515'', N''IA'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''516'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''517'', N''MI'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''518'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''519'', N''Ontario'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''520'', N''AZ'', 128, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''530'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''531'', N''NE'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''534'', N''WI'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''540'', N''VA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''541'', N''OR'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''551'', N''NJ'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''557'', N''MO'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''559'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''561'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''562'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''563'', N''IA'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''564'', N''WA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''567'', N''OH'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''570'', N''PA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''571'', N''VA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''573'', N''MO'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''574'', N''IN'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''575'', N''NM'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''580'', N''OK'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''585'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''586'', N''MI'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''587'', N''Alberta'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''601'', N''MS'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''602'', N''AZ'', 128, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''603'', N''NH'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''604'', N''British Columbia'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''605'', N''SD'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''606'', N''KY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''607'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''608'', N''WI'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''609'', N''NJ'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''610'', N''PA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''612'', N''MN'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''613'', N''Ontario'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''614'', N''OH'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''615'', N''TN'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''616'', N''MI'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''617'', N''MA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''618'', N''IL'', 64, 32, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''619'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''620'', N''KS'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''623'', N''AZ'', 128, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''626'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''627'', N''CA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''628'', N''CA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''630'', N''IL'', 64, 32, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''631'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''636'', N''MO'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''641'', N''IA'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''646'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''647'', N''Ontario'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''649'', N''Turks & Caicos Islands'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''650'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''651'', N''MN'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''657'', N''CA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''659'', N''AL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''660'', N''MO'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''661'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''662'', N''MS'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''664'', N''Montserrat'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''667'', N''MD'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''669'', N''CA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''670'', N''CNMI'', 4194304, 8388608, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''671'', N''GU'', 4194304, 8388608, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''678'', N''GA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''679'', N''MI'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''681'', N''WV'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''682'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''689'', N''FL'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''701'', N''ND'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''702'', N''NV'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''703'', N''VA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''704'', N''NC'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''705'', N''Ontario'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''706'', N''GA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''707'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''708'', N''IL'', 64, 32, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''709'', N''Newfoundland'', 33554432, 67108864, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''712'', N''IA'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''713'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''714'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''715'', N''WI'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''716'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''717'', N''PA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''718'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''719'', N''CO'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''720'', N''CO'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''724'', N''PA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''727'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''730'', N''IL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''731'', N''TN'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''732'', N''NJ'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''734'', N''MI'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''737'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''740'', N''OH'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''747'', N''CA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''754'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''757'', N''VA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''758'', N''St. Lucia'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''760'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''762'', N''GA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''763'', N''MN'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''764'', N''CA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''765'', N''IN'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''767'', N''Dominica'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''769'', N''MS'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''770'', N''GA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''772'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''773'', N''IL'', 64, 32, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''774'', N''MA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''775'', N''NV'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''778'', N''British Columbia'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''779'', N''IL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''780'', N''Alberta'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''781'', N''MA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''784'', N''St. Vincent & Grenadines'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''785'', N''KS'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''786'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''787'', N''Puerto Rico'', 16, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''801'', N''UT'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''802'', N''VT'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''803'', N''SC'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''804'', N''VA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''805'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''806'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''807'', N''Ontario'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''808'', N''HI'', 1024, 1024, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''809'', N''Dominican Republic'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''810'', N''MI'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''812'', N''IN'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''813'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''814'', N''PA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''815'', N''IL'', 64, 32, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''816'', N''MO'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''817'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''818'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''819'', N''Quebec'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''828'', N''NC'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''829'', N''Dominican Republic'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''830'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''831'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''832'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''843'', N''SC'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''845'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''847'', N''IL'', 64, 32, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''848'', N''NJ'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''849'', N''Dominican Republic'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''850'', N''FL'', 64, 32, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''856'', N''NJ'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''857'', N''MA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''858'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''859'', N''KY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''860'', N''CT'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''862'', N''NJ'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''863'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''864'', N''SC'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''865'', N''TN'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''867'', N''Yukon, NW Terr., Nunavut'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''868'', N''Trinidad & Toba'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''869'', N''St. Kitts & Nevis'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''870'', N''AR'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''872'', N''IL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''876'', N''Jamaica'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''878'', N''PA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''901'', N''TN'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''902'', N''Nova Scotia, Prince Edward Island'', 16, 8, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''903'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''904'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''905'', N''Ontario'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''906'', N''MI'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''907'', N''AK'', 512, 256, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''908'', N''NJ'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''909'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''910'', N''NC'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''912'', N''GA'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''913'', N''KS'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''914'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''915'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''916'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''917'', N''NY'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''918'', N''OK'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''919'', N''NC'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''920'', N''WI'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''925'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''928'', N''AZ'', 128, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''931'', N''TN'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''935'', N''CA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''936'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''937'', N''OH'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''938'', N''AL'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''939'', N''Puerto Rico'', 16, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''940'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''941'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''947'', N''MI'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''949'', N''CA'', 256, 128, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''951'', N''CA'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''952'', N''MN'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''954'', N''FL'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''956'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''959'', N''CT'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''970'', N''CO'', 128, 64, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''971'', N''OR'', 256, 128, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''972'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''973'', N''NJ'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''975'', N''MO'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''978'', N''MA'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''979'', N''TX'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''980'', N''NC'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''984'', N''NC'', 32, 16, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''985'', N''LA'', 64, 32, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (4, N''989'', N''MI'', 32, 16, 0, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''212'', N''Distrito Capital, Vargas, Miranda'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''234'', N''Miranda'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''235'', N''Guárico'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''237'', N''Islas Federales'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''238'', N''Guárico'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''239'', N''Miranda'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''240'', N''Apure, Barinas'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''241'', N''Carabobo'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''242'', N''Carabobo'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''243'', N''Aragua, Carabobo'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''244'', N''Aragua'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''245'', N''Caraboro'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''246'', N''Aragua y Guárico'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''247'', N''Apure, Barinas, Guárico'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''248'', N''Amazonas'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''249'', N''Carabobo'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''251'', N''Lara y Yaracuy'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''252'', N''Lara'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''253'', N''Lara y Yaracuy'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''254'', N''Yaracuy'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''255'', N''Portuguesa'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''256'', N''Portuguesa'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''257'', N''Portuguesa'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''258'', N''Cojedes y Barinas'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''259'', N''Falcón'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''261'', N''Zulia'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''262'', N''Zulia'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''263'', N''Zulia'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''264'', N''Zulia'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''265'', N''Zulia'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''266'', N''Zulia'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''267'', N''Zulia'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''268'', N''Falcón'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''269'', N''Falcón'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''271'', N''Trujillo, Zulia, Mérida'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''272'', N''Trujillo'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''273'', N''Barinas'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''274'', N''Mérida'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''275'', N''Zulia, Mércia y Táchira'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''276'', N''Táchira'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''277'', N''Táchira, Mérida'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''278'', N''Barinas, Apure'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''279'', N''Falcón'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''281'', N''Anzoátegui'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''282'', N''Anzoátegui'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''283'', N''Anzoátegui'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''284'', N''Bolívar'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''285'', N''Bolívar y Anzoátegui'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''286'', N''Bolívar , Monagas'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''287'', N''Delta, Amacuro, Monagas'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''288'', N''Bolívar'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''289'', N''Bolívar'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''291'', N''Monagas'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''292'', N''Anzoátegui, Monagas'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''293'', N''Sucre'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''294'', N''Sucre'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''295'', N''Nueva Esparta'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''296'', N''Amazonas'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''400'', N''No Geográfico'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''412'', N''Corporación Digitel'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''414'', N''TELCEL C.A (Movistar)'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''415'', N''Globalstar de Venezuela C.A'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''416'', N''Telecomunicaciones Movilnet C.A'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''424'', N''TELCEL C.A (Movistar)'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''426'', N''Telecomunicaciones Movilnet C.A'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''500'', N''No Geográfico'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''501'', N''No Geográfico'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (6, N''800'', N''No Geográfico'', 134217728, 33554432, NULL, NULL)

INSERT [dbo].[ccTimeZoneArea] ([id_country], [area], [location], [tz_standard], [tz_daylight], [call_record], [locality]) VALUES (7, N''113'', N''Leeds'', 1, 32768, NULL, NULL)

';
		EXEC(@sql);

SET @process = 'Actualizar Zonas para de acuerdo a Decreto de gobierno Mexico'
		SET @sql = '
update ccTimeZoneArea set tz_standard=64, tz_daylight=64 where location in (''CHIH'',''DGO'',''ZAC'',''JAL'',''COAH'',''NL'',''TAMPS'',
''SLP'',''GTO'',''AGS'',''QRO'',''HGO'',''VER'',''MICH'',''COL'',''MEX'',''CDMX'',''MOR'',''TLAX'',''PUE'',''GRO'',''OAX'',
''TAB'',''CHIS'',''CAMP'',''YUC'') and id_country=1 


update ccTimeZoneArea set tz_standard=128, tz_daylight=128 where location in (''SON'',''SIN'',''BCS'',''NAY'')  and id_country=1

update ccTimeZoneArea set tz_standard=64, tz_daylight=64 where locality=''BAHIA DE BANDERAS'' and location=''NAY'' and id_country=1


update ccTimeZoneArea set tz_standard=256, tz_daylight=128 where location in (''BC'')  and id_country=1

update ccTimeZoneArea set tz_standard=32, tz_daylight=32 where location like ''qroo%''  and id_country=1


--Para Fraccion III
Update  ccTimeZoneArea set tz_standard=64,tz_daylight=128 where locality in (''Janos'', ''Ascension'',''Juarez'', ''Praxedis G. Guerrero'' , ''Guadalupe'') and location =''CHIH''

--Para Fraccion II
update ccTimeZoneArea set tz_standard=64,tz_daylight=64 where area in (
select distinct CLD from series where MUNICIPIO in (''Coyame del Sotol'', ''Ojinaga'', ''Manuel Benavides'')) and id_country =1 and location =''CHIH''

--Para fraccion I
update ccTimeZoneArea set tz_standard=64, tz_daylight=32 where locality in(
select MUNICIPIO from Series where  (MUNICIPIO in (''Acuna'', ''Allende'', ''Guerrero'', ''Hidalgo'', ''Jimenez'', ''Morelos'', ''Nava'', ''Ocampo'', ''Piedras Negras'', ''Villa Union'', ''Zaragoza'') and ESTADO=''COAH'' ))
and id_country=1 and location in (''COAH'')

update ccTimeZoneArea set tz_standard=64, tz_daylight=32 where locality in(
select MUNICIPIO from Series where  (Municipio in (''Anahuac'') and ESTADO=''NL''))
and id_country=1 and location in (''NL'')

update ccTimeZoneArea set tz_standard=64, tz_daylight=32 where locality in(
select MUNICIPIO from Series where  (Municipio In (''Nuevo Laredo'', ''Guerrero'', ''Mier'', ''Miguel Aleman'', ''Camargo'', ''Gustavo Diaz Ordaz'', ''Reynosa'', ''Rio Bravo'', ''Valle Hermoso'', ''Matamoros'') and ESTADO= ''TAMPS''))
and id_country=1 and location in (''TAMPS'')

';
		EXEC(@sql);
		
		SET @process = 'Actualizar fechas para aplicar cambo de horario en zonas fronterizas'
		SET @sql = '
		delete from ccHorarioVerano where country_id=1 and inicio>=''2023-01-01''

--Aplica el Segundo domingo de marzo
insert into ccHorarioVerano
select dateadd(dd,8-datepart(dw,''2023-03-01 02:00:00''),''2023-03-01 02:00:00''), dateadd(dd,8-datepart(dw,''2023-11-01 02:00:00''),''2023-11-01 02:00:00''),1
insert into ccHorarioVerano
select dateadd(dd,8-datepart(dw,''2024-03-01 02:00:00''),''2024-03-01 02:00:00''), dateadd(dd,8-datepart(dw,''2024-11-01 02:00:00''),''2024-11-01 02:00:00''),1
insert into ccHorarioVerano
SELECT DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY, ''2025-03-01 02:00:00'') = 1 THEN 7 ELSE 8 - DATEPART(WEEKDAY, ''2025-03-01 02:00:00'') + 7  END, ''2025-03-01 02:00:00''), DATEADD(DAY, 8 - DATEPART(WEEKDAY, ''2025-11-01 02:00:00''), ''2025-11-01 02:00:00''), 1;
insert into ccHorarioVerano
SELECT DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY, ''2026-03-01 02:00:00'') = 1 THEN 7 ELSE 8 - DATEPART(WEEKDAY, ''2026-03-01 02:00:00'') + 7  END, ''2026-03-01 02:00:00''), DATEADD(DAY, 8 - DATEPART(WEEKDAY, ''2026-11-01 02:00:00''), ''2026-11-01 02:00:00''), 1;
insert into ccHorarioVerano
SELECT DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY, ''2027-03-01 02:00:00'') = 1 THEN 7 ELSE 8 - DATEPART(WEEKDAY, ''2027-03-01 02:00:00'') + 7  END, ''2027-03-01 02:00:00''), DATEADD(DAY, 8 - DATEPART(WEEKDAY, ''2027-11-01 02:00:00''), ''2027-11-01 02:00:00''), 1;
insert into ccHorarioVerano
SELECT DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY, ''2028-03-01 02:00:00'') = 1 THEN 7 ELSE 8 - DATEPART(WEEKDAY, ''2028-03-01 02:00:00'') + 7  END, ''2028-03-01 02:00:00''), DATEADD(DAY, 8 - DATEPART(WEEKDAY, ''2028-11-01 02:00:00''), ''2028-11-01 02:00:00''), 1;
insert into ccHorarioVerano
SELECT DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY, ''2029-03-01 02:00:00'') = 1 THEN 7 ELSE 8 - DATEPART(WEEKDAY, ''2029-03-01 02:00:00'') + 7  END, ''2029-03-01 02:00:00''), DATEADD(DAY, 8 - DATEPART(WEEKDAY, ''2029-11-01 02:00:00''), ''2029-11-01 02:00:00''), 1;
insert into ccHorarioVerano
SELECT DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY, ''2030-03-01 02:00:00'') = 1 THEN 7 ELSE 8 - DATEPART(WEEKDAY, ''2030-03-01 02:00:00'') + 7  END, ''2030-03-01 02:00:00''), DATEADD(DAY, 8 - DATEPART(WEEKDAY, ''2030-11-01 02:00:00''), ''2030-11-01 02:00:00''), 1;
insert into ccHorarioVerano
SELECT DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY, ''2031-03-01 02:00:00'') = 1 THEN 7 ELSE 8 - DATEPART(WEEKDAY, ''2031-03-01 02:00:00'') + 7  END, ''2031-03-01 02:00:00''), DATEADD(DAY, 8 - DATEPART(WEEKDAY, ''2031-11-01 02:00:00''), ''2031-11-01 02:00:00''), 1;
insert into ccHorarioVerano
SELECT DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY, ''2032-03-01 02:00:00'') = 1 THEN 7 ELSE 8 - DATEPART(WEEKDAY, ''2032-03-01 02:00:00'') + 7  END, ''2032-03-01 02:00:00''), DATEADD(DAY, 8 - DATEPART(WEEKDAY, ''2032-11-01 02:00:00''), ''2032-11-01 02:00:00''), 1;
insert into ccHorarioVerano
SELECT DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY, ''2033-03-01 02:00:00'') = 1 THEN 7 ELSE 8 - DATEPART(WEEKDAY, ''2033-03-01 02:00:00'') + 7  END, ''2033-03-01 02:00:00''), DATEADD(DAY, 8 - DATEPART(WEEKDAY, ''2033-11-01 02:00:00''), ''2033-11-01 02:00:00''), 1;
insert into ccHorarioVerano
SELECT DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY, ''2034-03-01 02:00:00'') = 1 THEN 7 ELSE 8 - DATEPART(WEEKDAY, ''2034-03-01 02:00:00'') + 7  END, ''2034-03-01 02:00:00''), DATEADD(DAY, 8 - DATEPART(WEEKDAY, ''2034-11-01 02:00:00''), ''2034-11-01 02:00:00''), 1;
insert into ccHorarioVerano
SELECT DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY, ''2035-03-01 02:00:00'') = 1 THEN 7 ELSE 8 - DATEPART(WEEKDAY, ''2035-03-01 02:00:00'') + 7  END, ''2035-03-01 02:00:00''), DATEADD(DAY, 8 - DATEPART(WEEKDAY, ''2035-11-01 02:00:00''), ''2035-11-01 02:00:00''), 1;
		';
		EXEC(@sql);
		
		SET @process = 'UPDATE fnGetTimeZone para tomar en cuenta el campo locality y no tener problema cuando hay diferentes municipios con la misma LADA'
		SET @sql = '
ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN
  declare @lada as varchar(5)
  declare @timeZone as int
  declare @ld as varchar(5)
  declare @location as varchar(500)
  declare @locality as varchar(255)
  declare @country as tinyInt
  declare @pais varchar(2)
  declare @serie varchar(10)
  declare @rank int
  declare @len int

  select @lada = valor from ccsettings with(nolock) where setting_id = 17
  select @country = valor, @pais = valor from ccSettings with(nolock) where setting_id = 104

  select @ld = ''''
  select @location = ''''
  set @timeZone=0
	
  if @phone='''' begin
    return 0;
  end

  set @len=len(@phone)

    if @country = 1 begin

		if @len<10 and @len + len(@lada)=10 begin
			set @phone=@lada+@phone
			set @len=len(@phone)
		end      

      if @len = 10
        begin         
			IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@phone, 3)
					and serie=SUBSTRING(@phone,4,3)
					)
				SELECT @ld = left(@phone, 3),@serie=SUBSTRING(@phone,4,3)
			ELSE IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@phone, 2)
					and serie=SUBSTRING(@phone,3,4)
					)
				SELECT @ld = left(@phone, 2),@serie=SUBSTRING(@phone,3,4)


        end    	

      if @ld <> ''''
        begin			
		    set @rank=right(@phone, 4)

          select top 1 @location = estado, @locality = MUNICIPIO from series 
		  where cld = @ld and serie = @serie and @rank between [NUMERACION INICIAL] and [NUMERACION FINAL]

          if @location is null or not exists(select  locality from ccTimeZoneArea (nolock) where id_country=@country and area=@ld and locality=@locality)
            set @locality = null					         
        end
	else begin
		set @ld=@lada
	end

		set @location = case when @location = ''DF'' then ''CDMX'' else @location end

		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
          where id_country = @country and 
          area = @ld 
		  and ( @location is null or (location = @location and locality=@locality))
		if(@timeZone is null or @timeZone = 0)
		begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
			  where id_country = @country and 
			  area = @ld 
			  and ( @location is null or location = @location)
		end
		
		if(@timeZone is null or @timeZone = 0)
		begin
			select top 1 @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end 
			from ccTimeZoneArea t
			where id_country = @country and area = @lada
		end
		
		return isNull(@timeZone,0)
    end

   else  if @country = 2 begin
      declare @telTemp varchar(15)
      set @telTemp = @phone
      select @phone = dbo.Completa(@phone, @pais, @lada)
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

  else if @country = 3 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 7 and @lada = area )
    or
    ( len(@phone) = 8 and left(@phone,1) = area )
    or
    ( len(@phone) in(10,11) and (left(@phone,1) = ''3'' or substring(@phone,2,1) = ''3'')))
  end

   else if @country = 4

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

   else if @country = 5 begin
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

  else if @country = 6 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 7 and @lada = area and len(area) = 3 )
    or
    ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
  end

  else if @country = 7 begin
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

   else if @country = 9 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    -- len(@phone) = 10
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
      where id_country = @country and (
      (convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
      (convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
    end
  end

 else  if @country = 10 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
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

  else if @country = 11 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  else if @country = 12 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  if @country = 13 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  else if @country = 14 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      if len(@phone) = 9 begin
        select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
        where id_country = @country and ((substring(@phone, 1, 2) = area) or (substring(@phone, 1, 3) = area))
      end
    end
  end

 else  if @country = 15 OR @country = 16  begin --Peru
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = 32
    end
  end

  if(@timeZone is null or @timeZone = 0)
	begin
		select top 1 @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end 
		from ccTimeZoneArea t
		where id_country = @country and area = @lada
	end 

  return isNull(@timeZone,0)
 END
		';
		EXEC(@sql);
	------------------------------------------------End Omar Mejia -----------------------------------------------------------------

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
