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

    SET @process = 'DROP SP Limpia2'
    SET @sql = '
	if exists (select * from sys.procedures where name = N''Limpia2'')
	begin
		DROP PROCEDURE Limpia2;
	end'
    EXEC(@sql);

	set @process = 'Create sp Limpia2'
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

	---------------------------------------- BEGIN fix/125.20231211.0.12 -------------------------------------------------
    SET @process = 'Alter SP ccsp_RIAOUTInsertNewJOBS_WT_Camp se quita with index para mejorar el procesamiento tome el plan de ejecuccion'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000
AS
SET NOCOUNT ON

DECLARE @prioridad VARCHAR(8)
DECLARE @batchsizeIni AS INT
DECLARE @batchsizeFin AS INT
DECLARE @rango AS DECIMAL
DECLARE @rowstoInsert AS INT
DECLARE @campType AS INT
DECLARE @recordsQuantitySetting VARCHAR(8)
DECLARE @settingValueP1 VARCHAR(25)

SET @rowstoInsert = 0
SET @batchsizeIni = 0
SET @batchsizeFin = 0
SET @rango = 0.00

IF EXISTS(SELECT * FROM sys.views WHERE NAME = ''VIEW_SETTINGS'') BEGIN
    SELECT @recordsQuantitySetting = [valor] FROM VIEW_SETTINGS WHERE setting_id = 257;
    IF(@recordsQuantitySetting IS NOT NULL AND @recordsQuantitySetting <> '''') BEGIN
        SELECT @settingValueP1 = SUBSTRING(@recordsQuantitySetting, CHARINDEX(''|'', @recordsQuantitySetting)+1, LEN(@recordsQuantitySetting)),
                @top = (SUBSTRING(@settingValueP1, 1, CHARINDEX(''|'', @settingValueP1)-1));
    END ELSE SET @top = 3000
END ELSE SET @top = 3000

SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
FROM ccCampsPrioridadTel WITH (NOLOCK)
WHERE cam_id = @camp_id

SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @camp_id;

DELETE ccUploadTemporal
WHERE cam_id = @camp_id

IF(@campType = 7)
BEGIN
        CREATE TABLE #tempsmsOutSource (Id INT PRIMARY KEY identity, smsout_id INT, cam_id INT, sms_phoneNumber VARCHAR(19), sms_status TINYINT, sms_dateDial DATETIME, cal_keyw VARCHAR(40), iTimeZone INT, iTimeZone_summer INT, iTimeZone2 INT, iTimeZone_summer2 INT, iTimeZone3 INT, iTimeZone_summer3 INT, iTimeZone4 INT, iTimeZone_summer4 INT, iTimeZone5 INT, iTimeZone_summer5 INT, list_id INT)

        CREATE TABLE #smsoutIdSource (smsout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #smsoutIdSource2 (smsout_id INT NOT NULL PRIMARY KEY)

        INSERT INTO #smsoutIdSource
        SELECT top(@top) sos.smsout_id
        FROM dbo.smsOutSource AS sos  WITH (INDEX (IX_smsOutSource_2), NOLOCK)
        inner join dbo.smsWorkingTable AS swt WITH (INDEX (IX_smsWorkingTable_2), NOLOCK) 
        on sos.callkey = swt.cal_keyw AND sos.cam_id = swt.cam_id 
        WHERE sos.cam_id = @camp_id and sos.sms_status IN (0, 7) AND swt.sms_status <= 2

        UNION

        SELECT top(@top) swt2.smsout_id
        FROM dbo.smsOutSource AS sos2 WITH (INDEX (IX_smsOutSource_2), NOLOCK)
        inner join dbo.smsWorkingTable AS swt2 (NOLOCK)on sos2.smsout_id = swt2.smsout_id 
        WHERE sos2.cam_id = @camp_id AND (sos2.sms_status < 2 OR sos2.sms_status = 7)

        INSERT INTO #smsoutIdSource2
        SELECT top(@top) sos.smsout_id
        FROM dbo.smsOutSource AS sos WITH (INDEX (IX_smsOutSource_1), NOLOCK)
        WHERE sos.sms_status IN (0, 1, 7) AND cam_id = @camp_id

        INSERT #tempsmsOutSource(smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, cal_keyw, iTimeZone, 
        iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4,
            iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id)
        SELECT TOP(@top) smsout_id, cam_id, RTRIM(LEFT(LTRIM(sms_phoneNumber + ''        '' + sms_phoneNumber2 + ''         '' 
        + sms_phoneNumber3 + ''         '' + sms_phoneNumber4 + ''         '' + sms_phoneNumber5 + ''         ''), 13)) AS sms_phoneNumber,
            CASE sms_status WHEN 7 THEN 1 ELSE sms_status END sms_status, sms_dateDial, callkey, 
            CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone ELSE NULL END iTimeZone,
            CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone_summer ELSE NULL END iTimeZone_summer, 
            CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone2 ELSE NULL END iTimeZone2,
            CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone_summer2 ELSE NULL END iTimeZone_summer2, 
            CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone3 ELSE NULL END iTimeZone3, 
            CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone_summer3 ELSE NULL END iTimeZone_summer3,
            CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone4 ELSE NULL END iTimeZone4, 
            CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone_summer4 ELSE NULL END iTimeZone_summer4, 
            CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone5 ELSE NULL END iTimeZone5, 
            CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone_summer5 ELSE 
                    NULL END iTimeZone_summer5, list_id
        FROM dbo.smsOutSource  WITH (INDEX (IX_smsOutSource_1), NOLOCK)
        WHERE cam_id = @camp_id AND (sms_status < 2 OR sms_status = 7) 

        SELECT @rowstoInsert = COUNT(*) FROM #tempsmsOutSource AS tos;

            
        IF EXISTS(SELECT * FROM #tempsmsOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempsmsOutSource  WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                -- Nuevos Jobs
                INSERT INTO dbo.smsWorkingTable
                WITH (TABLOCKX) (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id)
                SELECT smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, 0, 0 ,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id
                FROM #tempsmsOutSource 
                WHERE id > @batchsizeIni AND id <= @batchsizeFin

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE dbo.smsOutSource
            SET sms_status = 2
            FROM dbo.smsOutSource AS sos WITH (NOLOCK), #smsoutIdSource2  cis3 WITH (NOLOCK)
            WHERE sos.smsout_id = cis3.smsout_id
        END

        DROP TABLE #smsoutIdSource

        DROP TABLE #smsoutIdSource2

        DROP TABLE #tempsmsOutSource
END
ELSE
BEGIN
        CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT)
            
        CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

        INSERT INTO #calloutIdSource
        SELECT top(@top) cs.callout_id
        FROM ccoCallsOutSource cs WITH ( NOLOCK)
        inner join ccoWorkingTable wt WITH ( NOLOCK) 
        on cs.callout_id = wt.callout_id AND cs.cam_id = wt.cam_id 
        WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

        UNION

        SELECT top(@top) Cout.callout_id
        FROM ccoCallsOutSource Cout WITH ( NOLOCK)
        inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id 
        WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)
    

        INSERT INTO #calloutIdSource2
        SELECT top(@top) callout_id
        FROM ccoCallsOutSource WITH (NOLOCK)
        WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

        IF exists(SELECT * FROM #calloutIdSource) 
        BEGIN
            UPDATE ccoCallBacks
            SET [status] = 6, schedulerStatus = 1
            WHERE callout_id IN (
                    SELECT callout_id
                    FROM #calloutIdSource cis
                    )

            UPDATE ccoCallsOutSource
            SET cal_Status = 4
            WHERE callout_id IN (
                    SELECT callout_id
                    FROM #calloutIdSource cis
                    )
        END

        INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
        iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
            iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
        SELECT TOP(@top) callout_id, cam_id, CASE WHEN ISNULL(recycleType, 1) = 0 THEN 
        CASE 
            WHEN recyclePhone = 1 THEN cal_telefono
            WHEN recyclePhone = 2 THEN cal_telefono2
            WHEN recyclePhone = 3 THEN cal_telefono3
            WHEN recyclePhone = 4 THEN cal_telefono4
            else cal_telefono5
        END
        ELSE rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         '' 
            + cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13)) 
        END AS cal_telefono,
            CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key, 
            CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
            CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
            CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
            CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
            CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
            CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
            CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
            CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
            CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
            CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE 
                    NULL END iZonaHoraria_verano5, list_id
        FROM ccoCallsOutSource WITH (NOLOCK)
        WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7)

        SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

        IF EXISTS(SELECT * FROM #tempCallsOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempCallsOutSource WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                -- Nuevos Jobs
                INSERT INTO ccoWorkingTable
                WITH (TABLOCKX) (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
                SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
                FROM #tempCallsOutSource
                WHERE id > @batchsizeIni AND id <= @batchsizeFin

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE ccoCallsOutSource
            SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
            FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
            WHERE co.callout_id = cis3.callout_id
        END

        DROP TABLE #calloutIdSource

        DROP TABLE #calloutIdSource2

        DROP TABLE #tempCallsOutSource
END

UPDATE ccCampsNvosCB
SET dateUpdate = NULL
WHERE id = @camp_id

SET NOCOUNT OFF
    '
    EXEC(@sql);


       set @process = 'Create table ccLogAgentesDiaLast'
    set @sql = 'if not exists (select * from sys.tables where name = N''ccLogAgentesDiaLast'')
    begin
        CREATE TABLE [dbo].[ccLogAgentesDiaLast]
(
      [User_id] SMALLINT NOT NULL
    , [TipoStatusAge_id] TINYINT NOT NULL
    , [tStatus] FLOAT NULL
    , [fecha] DATETIME NOT NULL
    , [IdCampEsp] SMALLINT NULL
    , [Tipo] SMALLINT NULL
    , [currentStatus] INT NULL
    , [callID] INT NULL
    , CONSTRAINT [PK__ccLogAge__206A9DF893323245] PRIMARY KEY ([User_id] ASC)
)

ALTER TABLE [dbo].[ccLogAgentesDiaLast] WITH CHECK ADD CONSTRAINT [FK_ccLogAgentesDiaLast_ccTipoStatusAgente] FOREIGN KEY([TipoStatusAge_id]) REFERENCES [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id])
ALTER TABLE [dbo].[ccLogAgentesDiaLast] CHECK CONSTRAINT [FK_ccLogAgentesDiaLast_ccTipoStatusAgente]
    end'
        EXEC(@sql);

        SET @process = 'TT8053 DROP VIEW ccLogAgentesDiaViewLast'
        SET @sql = 'IF EXISTS(SELECT * FROM sys.views WHERE name=''ccLogAgentesDiaViewLast'')
                    BEGIN
                    DROP VIEW ccLogAgentesDiaViewLast;
                    END;'
        EXEC(@sql);


        SET @process = 'TT8053 Create ccLogAgentesDiaViewLast for better access to last status by agent'
        SET @sql = 'CREATE VIEW ccLogAgentesDiaViewLast AS
SELECT User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus, callId
FROM ccLogAgentesDiaLast with(nolock)      ;
                    '
        EXEC(@sql);


        SET @process = 'Alter ccsp_SaveStatusAgent se agrega ccLogAgentesDiaLast'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus float,
@TipoCall  tinyint,
@Camp smallint,
@callout_id int=0,
@call_id int=0,
@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog float =0 ,
@currentStatus int =-2,--NUEVO PARAMETRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null,
@tMusicHold int =0,
@isTransferEngine bit = 0,
@TypeAuxiliar int = 0
AS

if @Fecha4 is null set @Fecha4 = getdate()

if @TipoCall > 0 set @TipoCall = @TipoCall - 1

 IF @User_id <= 0 OR (@tStatus = 0 AND @TipoStatusAge_id = 30)
        RETURN 0;

declare @cam_id int,@surveycamId int
declare @cal_telefono varchar(30)
declare @cal_key varchar(40)
declare @inbound_id int
declare @callBackSurveyClients bit
declare @cal_whoHung tinyint
DECLARE @cal_tXfer float,   @cal_tRing float
declare @cal_tDialog int
declare @cal_tNotas float
declare @cal_tNotaOri int
declare @tMinAVRS smallint
declare @calInicio datetime
declare @sumCall float
declare @cal_manual int 

set @cal_tNotas =0
set @cal_tNotaOri=0

if @TipoStatusAge_id=32 set @tStatus=CONVERT(DECIMAL(10,2), ROUND(@tStatus, 0, 1))

set @cal_manual =0
--4 Dialog,6 Notas, 27 Notas Fallida

 IF @TipoStatusAge_id IN (4, 6, 27) AND @call_id > 0 and @isLogout=1
BEGIN
   if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
   if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas

   
     if @TipoCall = 0 
     begin -- BEING IN @TipoCall = 0  ---
        SELECT @calInicio = cal_Xfer,
        @sumCall = cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas,
        @Camp = Inbound_id,
        @cal_tDialog = cal_tDialog,
        @cal_tNotaOri = cal_tNotas,
        @cal_key = cal_Key,
        @inbound_id = inbound_id,
        @cal_telefono = cal_ani,
        @cal_whoHung = cal_whoHung,
        @cal_tXfer = cal_tXfer,
        @cal_tRing = cal_tRing
        FROM ccCallsIN WITH (NOLOCK)
        WHERE cal_id = @call_id
        AND statusCall_id = 13

        IF @cal_tXfer = 0 AND @cal_tRing = 0
        BEGIN
            SELECT @cal_tXfer = CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE @cal_tXfer END,
                @cal_tRing = CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE @cal_tRing END
            FROM ccLogAgentesDia WITH (NOLOCK)
            WHERE User_id = @User_id
                AND callID = @call_id
                AND Tipo = @TipoCall
                AND TipoStatusAge_id IN (5, 9)
        END
        IF @cal_tDialog = 0 AND @tDialog > 0            
        BEGIN
            IF @Fecha4 < DATEADD(ms, (@sumCall + @tDialog + @cal_tNotas) * 1000, @calInicio)
            BEGIN
                SET @tStatus = CASE WHEN @tStatus > 0 THEN @tStatus - 1 ELSE @tStatus END

                IF @TipoStatusAge_id = 4
                    SET @tDialog = @tDialog - 1

                IF @TipoStatusAge_id = 6
                BEGIN
                    IF @cal_tNotas > 0
                        SET @cal_tNotas = @cal_tNotas - 1
                    ELSE
                        SET @tDialog = @tDialog - 1
                END
            END

            UPDATE ccCallsIN
            WITH (ROWLOCK)

            SET cal_tDialog = @tDialog,
                cal_tNotas = @cal_tNotas,
                cal_tMoh = @tMusicHold,
                cal_tXfer=@cal_tXfer,
                cal_tRing=@cal_tRing
            WHERE cal_id = @call_id
                AND statusCall_id = 13
        END
        ----------------------------
        IF @isTransferEngine = 1
        BEGIN 
            DECLARE @minimoDialogo TINYINT

            SELECT @minimoDialogo = valor
            FROM ccSettings
            WHERE setting_id = 13

            IF @cal_tDialog < @minimoDialogo
            BEGIN
                --el status 18 es para llamada cortada con transferencia en Reminder
                EXEC ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id, @nStatus = 18
            END
        END
        -----------------------------
     END -- END IN @TipoCall = 0  ---
     Else 
     begin -- BEING IN @TipoCall = 1  ---
        SELECT @calInicio = cal_inicio,
        @sumCall = cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas,
        @cam_id = cam_id,
        @cal_tDialog = cal_tDialog,
        @cal_tNotaOri = cal_tNotas,
        @cal_tXfer = cal_tXfer,
        @cal_tRing = cal_tRing
        FROM ccoCallsOut WITH (NOLOCK)
        WHERE cal_id = @call_id

        SET @Camp = @cam_id

        if @cal_tXfer=0 and @cal_tRing=0 begin
            SELECT @cal_tXfer = CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE @cal_tXfer END,
            @cal_tRing = CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE @cal_tRing END
            FROM ccLogAgentesDia WITH (NOLOCK)
            WHERE User_id = @User_id
            AND callID = @call_id
            AND Tipo = @TipoCall
            AND TipoStatusAge_id IN (5, 9)

        end

        if @cal_tDialog = 0 and @tDialog>0 begin
            IF @Fecha4 < DATEADD(ss, @sumCall + @tDialog + @cal_tNotas, @calInicio)
                BEGIN
                    SET @tStatus = CASE WHEN @tStatus > 0 THEN @tStatus - 1 ELSE @tStatus END

                    IF @TipoStatusAge_id = 4
                        SET @tDialog = @tDialog - 1
                    IF @TipoStatusAge_id = 6
                    BEGIN
                        IF @cal_tNotas > 0
                            SET @cal_tNotas = @cal_tNotas - 1
                        ELSE
                            SET @tDialog = @tDialog - 1
                    END
                END

                UPDATE ccoCallsOut
                WITH (ROWLOCK)
                SET cal_tDialog = @tDialog,
                    totalCall_Time = @tDialog,
                    cal_tNotas = @cal_tNotas,
                    cal_tMoh = @tMusicHold,
                    cal_tXfer = @cal_tXfer,
                    cal_tRing = @cal_tRing
                WHERE cal_id = @call_id
                    AND statusCall_id = 13

        end
        else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
            update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog  
            ,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
            where cal_id = @call_id
        else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
            update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas 
            ,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
            where cal_id = @call_id 
     END -- END OUT @TipoCall = 1  ---
    
    select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

    if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1 and @cal_manual<>1 begin
        insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
    end

    if @TipoStatusAge_id in(6,27) begin
    --Valida que el agente no pudo guardar el status antes de desloguear
    if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
        INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
    end
end --@TipoStatusAge_id IN (4, 6, 27) AND @call_id > 0 and @isLogout=1 --


IF (@TipoStatusAge_id = 4)
BEGIN -- 4 = Dialogo
    DECLARE @tStatus3 FLOAT, @Fecha3 DATETIME

    SELECT TOP 1 @tStatus3 = tstatus, @Fecha3 = fecha
    FROM ccLogAgentesDia WITH (NOLOCK)
    WHERE TipoStatusAge_id = 3 AND user_id = @User_id
    ORDER BY fecha DESC

    INSERT INTO ccLogAgentesDia_Dialog (
        User_id,
        Cam_id,
        fecha_Calc_ms,
        tStatus_Dispo,
        fecha_Dispo,
        tStatus_Dialog,
        fecha_Dialog
        )
    SELECT @User_id, cam_id,
        datediff(ms, dateadd(ms, - (@tStatus3 * 1000), @Fecha3), dateadd(ms, - (@tStatus3 * 1000
                    ), @Fecha4)),
        @tStatus3,
        @Fecha3,
        @tStatus,
        @Fecha4
    FROM cccampsagente
    WHERE user_id = @User_id

    ---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
    IF @call_id > 0
    BEGIN
        IF @TipoCall = 0
        BEGIN --IN
            SELECT @surveycamid = isnull(extend.SurveyCamId, 0),
                @callBackSurveyClients = i.callBackSurveyClient
            FROM ccinbound i
            LEFT JOIN ccInboundExtend extend
                ON i.inbound_id = extend.inbound_id
            WHERE i.inbound_id = @inbound_id

            IF @surveycamId > 0
                AND (
                    @callBackSurveyClients = 1
                    OR @cal_whoHung = 1
                    )
            BEGIN
                IF EXISTS (
                        SELECT cam_id
                        FROM cccamps
                        WHERE cam_id = @surveycamid
                            AND isnull(callsBySurvey, 0) > 0
                            AND isnull(ivrScript, 0) > 0
                        )
                BEGIN
                    IF (
                            SELECT surveyPctg
                            FROM ccCamps
                            WHERE cam_id = @surveycamid
                            ) >= rand() * 100
                    BEGIN
                        INSERT INTO ccoCallsOUTSource (
                            cal_Key,
                            cam_id,
                            cal_telefono,
                            cal_status,
                            cal_fechaDial
                            )
                        VALUES (
                            right((cast(@call_id AS VARCHAR) + '''' + @cal_Key), 40),
                            @surveycamid,
                            @cal_telefono,
                            0,
                            dateadd(mi, 6, getdate())
                            )
                    END
                END
            END
        END --@TipoCall = 0
        ELSE
        BEGIN --OUT
            SELECT @surveycamId = isnull(surveycamid, 0),
                @callBackSurveyClients = callBackSurveyClient
            FROM cccamps
            WHERE cam_id = @cam_id

            SELECT @cal_key = cal_Key,
                @cam_id = cam_id,
                @cal_telefono = cal_telefono,
                @cal_whoHung = cal_whoHung
            FROM ccoCallsOUT WITH (
                    INDEX (IX_ccoCallsOut_11),
                    NOLOCK
                    )
            WHERE callout_id = @callout_id
                AND statusCall_id = 13
                AND cal_id = @call_id

            IF @surveycamId > 0
                AND (
                    @callBackSurveyClients = 1
                    OR @cal_whoHung = 1
                    )
            BEGIN
                IF (
                        SELECT surveyPctg
                        FROM ccCamps
                        WHERE cam_id = @surveycamId
                        ) >= rand() * 100
                BEGIN
                    INSERT INTO ccoCallsOUTSource (
                        cal_Key,
                        cam_id,
                        cal_telefono,
                        cal_status,
                        cal_fechaDial
                        )
                    VALUES (
                        right((cast(@call_id AS VARCHAR) + '''' + @cal_Key), 40),
                        @surveycamid,
                        @cal_telefono,
                        0,
                        dateadd(mi, 6, getdate())
                        )
                END
            END
        END
    END --@callout_id>0
END --End -- 4 = Dialogo


IF @isLogout = 0 AND @TipoStatusAge_id = 6
BEGIN --- BEGIN Insert ccLogAgentesDia @isLogout = 0 AND @TipoStatusAge_id = 6 -----
    --Valida que el ccserver no haya guardado antes el status antes al desloguear
    IF NOT EXISTS (
            SELECT *
            FROM ccLogAgentesDia WITH (NOLOCK)
            WHERE User_id = @User_id
                AND TipoStatusAge_id = 4
                AND fecha BETWEEN dateadd(ss, - 10, @Fecha4) AND @Fecha4
                AND tStatus = @tStatus + 1
            )
    BEGIN
        INSERT ccLogAgentesDia (
            User_id,
            TipoStatusAge_id,
            tStatus,
            fecha,
            IdCampEsp,
            Tipo,
            currentStatus,
            callID
            )
        VALUES (
            @User_id,
            @TipoStatusAge_id,
            @tStatus,
            @Fecha4,
            @Camp,
            @TipoCall,
            @currentStatus,
            @call_id
            )

        IF NOT EXISTS (
                SELECT *
                FROM [ccLogAgentesDiaLast]
                WHERE User_id = @User_id
                )
        BEGIN
            INSERT [ccLogAgentesDiaLast] (
                User_id,
                TipoStatusAge_id,
                tStatus,
                fecha,
                IdCampEsp,
                Tipo,
                currentStatus,
                callID
                )
            VALUES (
                @User_id,
                @TipoStatusAge_id,
                @tStatus,
                @Fecha4,
                @Camp,
                @TipoCall,
                @currentStatus,
                @call_id
                )
        END
        ELSE
        BEGIN
            UPDATE [ccLogAgentesDiaLast]
            SET TipoStatusAge_id = @TipoStatusAge_id,
                tStatus = @tStatus,
                fecha = @Fecha4,
                IdCampEsp = @Camp,
                Tipo = @TipoCall,
                currentStatus = @currentStatus,
                callID = @call_id
            WHERE USER_ID = @User_id
        END
    END
END --- END Insert ccLogAgentesDia @isLogout = 0 AND @TipoStatusAge_id = 6 -----
ELSE 
BEGIN --- BEGIN ELSE DIFF -----
    INSERT ccLogAgentesDia (
        User_id,
        TipoStatusAge_id,
        tStatus,
        fecha,
        IdCampEsp,
        Tipo,
        currentStatus,
        callID
        )
    VALUES (
        @User_id,
        @TipoStatusAge_id,
        @tStatus,
        @Fecha4,
        @Camp,
        @TipoCall,
        @currentStatus,
        @call_id
        )

    IF NOT EXISTS (
            SELECT *
            FROM [ccLogAgentesDiaLast]
            WHERE User_id = @User_id
            )
    BEGIN
        INSERT [ccLogAgentesDiaLast] (
            User_id,
            TipoStatusAge_id,
            tStatus,
            fecha,
            IdCampEsp,
            Tipo,
            currentStatus,
            callID
            )
        VALUES (
            @User_id,
            @TipoStatusAge_id,
            @tStatus,
            @Fecha4,
            @Camp,
            @TipoCall,
            @currentStatus,
            @call_id
            )
    END
    ELSE
    BEGIN
        UPDATE [ccLogAgentesDiaLast]
        SET TipoStatusAge_id = @TipoStatusAge_id,
            tStatus = @tStatus,
            fecha = @Fecha4,
            IdCampEsp = @Camp,
            Tipo = @TipoCall,
            currentStatus = @currentStatus,
            callID = @call_id
        WHERE USER_ID = @User_id
    END
END --- END ELSE DIFF -----


IF (@TipoStatusAge_id = 2)
BEGIN  -- 2 = No Disponible
    INSERT ccLogAgentesNotReady (
        User_id,
        TipoNotReady_id,
        tStatus,
        fecha,
        IdCampEsp,
        Tipo
        )
    VALUES (
        @User_id,
        @TipoNotReady,
        @tStatus,
        @Fecha4,
        @Camp,
        @TipoCall
        )

    ---Para Agente RIA: OAYC
    INSERT ccRIALogAgentesNotReady (
        User_id,
        TipoNotReady_id,
        tStatus,
        fecha
        )
    VALUES (
        @User_id,
        @TipoNotReady,
        @tStatus,
        @Fecha4
        )
END

if @TipoStatusAge_id = 37 
begin
    EXEC ccsp_GalateaReadyAuxiliar @action = 2, @tipoReadyId = @TypeAuxiliar, @userId = @User_id, @timeStatus= @tStatus
end    

-- Actualiza para reporte de tiempos especiales (Boan)
IF @Camp > 0
BEGIN
    IF EXISTS (
            SELECT *
            FROM ccLogAgentesDia WITH (
                    INDEX (IX_ccLogAgentesDia_5),
                    NOLOCK
                    )
            WHERE IdCampEsp = 0
                AND user_id = @User_id
            )
    BEGIN
        UPDATE ccLogAgentesDia
        WITH (ROWLOCK)

        SET IdCampEsp = @Camp,
            Tipo = @TipoCall
        WHERE IdCampEsp = 0
            AND user_id = @User_id
    END

    IF EXISTS (
            SELECT *
            FROM ccLogAgentesNotReady WITH (
                    INDEX (IX_ccLogAgentesNotReady_4),
                    NOLOCK
                    )
            WHERE IdCampEsp = 0
                AND user_id = @User_id
            )
    BEGIN
        UPDATE ccLogAgentesNotReady
        WITH (ROWLOCK)

        SET IdCampEsp = @Camp,
            Tipo = @TipoCall
        WHERE IdCampEsp = 0
            AND user_id = @User_id
    END
END


IF (
        @TipoStatusAge_id = 34
        AND @call_id > 0
        ) -- Dialogo WhatsApp
BEGIN
    IF @TipoCall = 0
    BEGIN
        UPDATE ccWhatsAppConversations
        SET tChatting = (tChatting + @tStatus)
        WHERE conversationId = @call_id;

        SET @Camp = (
                SELECT inboundId
                FROM ccWhatsAppConversations
                WHERE conversationId = @call_id
                );

        EXEC ccsp_WhatsAppInformation @Option = 2,
            @InboundId = @Camp
    END
    ELSE
    BEGIN
        UPDATE ccWhatsAppConversationsOut
        SET tChatting = (tChatting + @tStatus)
        WHERE conversationId = @call_id;

        SET @Camp = (
                SELECT camId
                FROM ccWhatsAppConversationsOut
                WHERE conversationId = @call_id
                );

        EXEC ccsp_WhatsAppInformationOut @Option = 2,
            @camId = @Camp
    END
END
'
        EXEC(@sql);       


  SET @process = 'Alter SP ccsp_GalateaAreas se agrega if @option = 2 borrar la tabla #Areas'
        SET @sql = 'ALTER procedure [dbo].[ccsp_GalateaAreas] 
    @option int = 2,
    @IDArea smallint = 0,
    @Descripcion varchar(40) = NULL,
    @maxMails smallint = 3,
    @maxChats smallint = 3,
    @maxTweets smallint = 3,
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
            users int,
            admins int,
            camps int,
            acds int,
            maxTweets tinyint,
            toolsTransfer tinyint
        )
        insert into #Areas
        EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@defCampaing=@defCampaing, @isKolob=1
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
        END
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

                DECLARE @AreasTable TABLE 
                (
                    columnInfo VARCHAR(255),
                    dataInfo VARCHAR(255),
                    identifierInfo VARCHAR(255)
                )

                update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=case when @toolsTransfer = 3 then ToolsTransfer else @toolsTransfer end where IDArea=@IDArea

                INSERT INTO @AreasTable EXEC InsertLogAdminGalatea @action=2, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId;

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
                            ELSE AT.dataInfo END
                    ELSE '''' END, 
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                    ELSE '''' END
                FROM @AreasTable AS AT;

                EXEC InsertLogAdminGalatea @action=3, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

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
    end
SET NOCOUNT ON;'
        EXEC(@sql);

        ---------------------------------------- END fix/125.20231211.012 -------------------------------------------------



 	
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
