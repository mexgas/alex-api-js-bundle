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
SET @versionfix = 2
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

        ----------------------------------------------------- BEGIN Gaby ---------------------------------------------------------------


    SET @process = 'Whatsapp Masivo - Create new table for Url Meta'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ccMetaWhatsAppConfigurations'')
                BEGIN
                    CREATE TABLE ccMetaWhatsAppConfigurations(
						Id int,
						Url varchar(150) not null,
						codeCountry int
					)
                END;'
    EXEC(@sql);

    SET @process = 'Whatsapp Masivo - Create new table for WhatsApp numbers'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ccMetaWhatsAppNumbers'')
                BEGIN
                    CREATE TABLE ccMetaWhatsAppNumbers
					(
						MetaId int identity(1,1),
						Number varchar(30) PRIMARY KEY not null,
						Status int,
						Inbound_Id smallint FOREIGN KEY(Inbound_id) REFERENCES ccInbound(Inbound_id),
						Cam_Id smallint FOREIGN KEY(cam_id) REFERENCES ccCamps(cam_id),
						PhoneNumberId varchar(100),
						Token varchar(max)
					)
                END;'
    EXEC(@sql);

    SET @process = 'Whatsapp Masivo - Create new table for'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ccMetaWAOutboundTemplates'')
                BEGIN
                    CREATE TABLE ccMetaWAOutboundTemplates
					(
						Id int IDENTITY(1,1) not null,
						Category varchar(100),
						TemplateName varchar(50) primary key,
						AllowCategoryChange bit,
						LanguageCode varchar(30),
						Status int,
						header varchar(max),
						body varchar(max),
						footer varchar(max),
						button varchar(max),
						MetaId int
					)
                END;'
    EXEC(@sql);

    SET @process = 'Whatsapp Masivo - Create new table for messages without a status update'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ccWhatsAppOutSource'')
                BEGIN
                    CREATE TABLE ccWhatsAppOutSource(
						WAOut_Id bigint IDENTITY(1,1) NOT NULL,
						CallKey varchar(40) NOT NULL,
						camId int NOT NULL,
						PhoneNumber varchar(30),
						Status int NOT NULL,
						TimeZone int NOT NULL,
						TimeZone_Summer int NOT NULL,
						List_id int NOT NULL,
						User_id smallint NOT NULL,
						TemplateId int NOT NULL,
						componentJson varchar(max) NOT NULL
					)
                END;'
    EXEC(@sql);

    SET @process = 'Whatsapp Masivo - Create new table for messages without a status update'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ccoWAWorkingTable'')
                BEGIN
	                CREATE TABLE ccoWAWorkingTable(
						WAOut_id bigint IDENTITY(1,1) NOT NULL,
						PhoneNumber varchar(30) NOT NULL,
						Callkey varchar(60) NOT NULL,
						CamId int NOT NULL,
						WaStatus int NOT NULL,
						dateDial datetime NOT NULL,
						UserId int NOT NULL,
						TimeZone int NOT NULL,
						TimeZone_Summer int NOT NULL
					)
                END;'
    EXEC(@sql);

    SET @process = 'Whatsapp Masivo - Create new table for messages without a status update'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ccoWhatsLogDials'')
                BEGIN
                    CREATE TABLE ccoWhatsLogDials(
						MetaId varchar(1000) NOT NULL,
						WaOutId bigint NOT NULL,
						CamId smallint NOT NULL,
						RegistryClient varchar(40) NOT NULL,
						PhoneClient varchar(50) NOT NULL,
						PhoneWa varchar(50) NOT NULL,
						Type varchar(20),
						Contented varchar(1000),
						Bill decimal(10,4) NOT NULL,
						TimeSpam datetime NOT NULL,
						ConversationId bigint,
					 	ErrorCode int,
						ErrorMessage varchar(1000),
						Status varchar(100) NOT NULL
					)
                END;'
    EXEC(@sql);


	SET @process = 'WhatsApp Masivo - Drop SP ccspOutboundWhatsApp'
	SET @sql = '
	    if exists (select * from sys.procedures where name = N''ccspOutboundWhatsApp'')
	    begin
	        DROP PROCEDURE ccspOutboundWhatsApp;
	    end'
	EXEC(@sql);

	SET @process = 'WhatsApp Masivo - Create SP ccspOutboundWhatsApp'	
	SET @sql='
		create procedure ccspOutboundWhatsApp
		@action int,
		@camId int = null
		as
		if @action=1 begin
			declare @Url as varchar(50)
			set @Url = (select Url from ccMetaWhatsAppConfigurations)

			select distinct cast(c. cam_id as int) as CamId,cam_descripcion as [Name],cam_procesando as [Start],Number as PhoneNumber, 
			case cam_procesando when 0 then '''' else REPLACE(@Url, ''phoneId'', PhoneNumberId) end as Url, Token
			from ccCamps c with(nolock)
			left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
			left join  ccCampsHorarios s ON s.cam_id = c.cam_id
			left join ccMetaWhatsAppNumbers wn on wn.cam_id = c.cam_id
			WHERE CampType=5 AND c.IDArea IS NOT NULL AND(@camId IS NULL or @camId=0 OR c.cam_id = @camId)
	    end
	'
	EXEC(@sql)

	SET @process = 'WhatsApp Masivo - Drop SP ccsp_WAOUTGetNewJobs'
	SET @sql = '
	    if exists (select * from sys.procedures where name = N''ccsp_WAOUTGetNewJobs'')
	    begin
	        DROP PROCEDURE ccsp_WAOUTGetNewJobs;
	    end'
	EXEC(@sql);

	SET @process = 'WhatsApp Masivo - Create SP ccsp_WAOUTGetNewJobs'	
	SET @sql='
		CREATE PROCEDURE ccsp_WAOUTGetNewJobs
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
FROM ccoWAWorkingTable W 
inner join ccWhatsAppOutSource wos (nolock) on wos.waout_id=W.waout_id
WHERE WaStatus in (0)
and W.CamId=@campId
and (
   ( (''+@isVerano+''  & @iZonas)>0 or ''+@isVerano+''=0) 
)
order by W.dateDial ''+ @Order_Asc_Desc +'', waout_id ''+ @Order_Asc_Desc

----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
set @parameters=''@CAMPID int,@topCount int,@iZonas int''		

	
SELECT @sql=@sql+nchar(13)+ ''update ccoWAWorkingTable with (rowlock) SET WaStatus=1 where WAOut_id in(select WaOutId from #NEW_JOBS)''	


		
select @sql=@sql+nchar(13)+ ''SELECT WaOutId, CamId, Phone, Status, DateDial,
Tz1,CallKey as RegistryClient,Components as MessageJson
FROM #NEW_JOBS where len(Phone)>0
''

print (@sql)

exec sp_executesql  @sql,@parameters,
@CAMPID=@CAMPID
,@topCount=@topCount
,@iZonas=@iZonas

IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS

return(0)
	'
	EXEC(@sql)

	SET @process = 'WhatsApp Masivo - Drop SP ccsp_WAOUTResetJobs'
	SET @sql = '
	    if exists (select * from sys.procedures where name = N''ccsp_WAOUTResetJobs'')
	    begin
	        DROP PROCEDURE ccsp_WAOUTResetJobs;
	    end'
	EXEC(@sql);

	SET @process = 'WhatsApp Masivo - Create SP ccsp_WAOUTResetJobs'	
	SET @sql='
		ALTER PROCEDURE ccsp_WAOUTResetJobs
                    @camid AS INT= 0
                    AS
                    BEGIN

                      CREATE TABLE #TempccoLogDials ( 
                        waout_id INT, PRIMARY KEY (waout_id)
                      );
                      DECLARE @today DATETIME;

                      SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);
                      
                      IF @camid = 0
                      BEGIN
                        INSERT INTO #TempccoLogDials
                             SELECT WaOutId
                             FROM ccoWhatsLogDials AS ld WITH(NOLOCK)
                             WHERE TimeSpam >= @today
                             GROUP BY WaOutId;
                      END;
                         ELSE
                        IF @camid > 0
                        BEGIN
                          INSERT INTO #TempccoLogDials
                               SELECT WaOutId
                               FROM ccoWhatsLogDials AS ld WITH(NOLOCK)
                               WHERE CamId = @camid AND 
                                 TimeSpam >= @today
                               GROUP BY WaOutId;
                        END;

                      IF @camid = 0
                      BEGIN
                        -- NUEVAS - Nunca se han marcado
                        UPDATE ccoWAWorkingTable 
                          SET WaStatus = 0
                        WHERE WaStatus = 1;
                      END;
                         ELSE
                      BEGIN  
                        -- NUEVAS - Nunca se han marcado
                        UPDATE ccoWAWorkingTable WITH(ROWLOCK)
                          SET WaStatus = 0
                        WHERE WaStatus = 1 AND 
                            CamId = @camid;
                      END;

                      UPDATE c
                      SET c.cam_procesando = 0
                      FROM ccCamps c
                      WHERE c.cam_id = @camid
                      

                      DROP TABLE #TempccoLogDials;
                    END;
	'
	EXEC(@sql)

	SET @process = 'WhatsApp Masivo - Drop SP ccsp_GalateaGetOutboundConfiguration'
	SET @sql = '
	    if exists (select * from sys.procedures where name = N''ccsp_GalateaGetOutboundConfiguration'')
	    begin
	        DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
	    end'
	EXEC(@sql);

	SET @process = 'WhatsApp Masivo - Create SP '	
	SET @sql='
		
	'
	EXEC(@sql)



	SET @process = 'Whatsapp Masivo - Add setting for messages per second'
    SET @sql = '
        IF NOT EXISTS(SELECT 1 FROM ccGalateaModules WHERE ModuleId = 14)
        BEGIN
            insert into ccSettings2(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
			values (270, 80, ''Mensajes de WhatsApp por segundo (default: 80, max: 1000, min: 1)'', 1, ''GRL'', ''Mensajes de WhatsApp por segundo (default: 80, max: 1000, min: 1)'',''Mensajes de WhatsApp por segundo (default: 80, max: 1000, min: 1)'',0,''.*'')

        END'
    EXEC(@sql);    
    

        

--------------------------------------------------------------------- END Gaby --------------------------------------------------------------------------
	  
        

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
