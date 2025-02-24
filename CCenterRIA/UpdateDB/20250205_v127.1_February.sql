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
         SET @process = 'Facturacion - Columna TemplateId en ccoWhatsLogDials'
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
	--EXEC(@sql);

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

		  exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@inbound_id,@callType=0,@statusCallId=1

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
	EXEC(@sql);

	SET @process = 'Drop procedure getPrefixByAcdId'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''getPrefixByAcdId'')
		BEGIN
			DROP PROCEDURE dbo.getPrefixByAcdId
		END'
    EXEC(@sql);

	SET @process = 'CREATE procedure getPrefixByAcdId'
    SET @sql = 'CREATE procedure [dbo].[getPrefixByAcdId] 
		@inboundId int,@phone varchar(50) = ''''
		as
		declare @prefijo varchar(40),@recordHold tinyint,@call_record as tinyint
		declare @countryId as tinyint 

		select @countryId = valor from ccsettings with(nolock) where setting_id = 104

		select @prefijo= isnull(prefijo,''''),@recordHold= ISNULL(recordHold,0)  ,@call_record=ISNULL(B.RecordCalls,1)
		from ccInbound A
		left join ccInboundExtend B on A.Inbound_id=B.Inbound_id
		where A.Inbound_id = @inboundId

		select @prefijo recordPrefix,@recordHold recordHold ,dbo.EnableCallRecord(@call_record,@countryId,@phone) callRecord'
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
