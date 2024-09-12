/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2024/06/13
Description: K064000
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 19
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
    	
		------------------------------------------------- Empieza Ivan Martin ----------------------------------------------------------------------------------
		------------------------------------------------------- CW-8657  --------------------------------------------------------------------------
		-------------------------------------------------------- Tablas -----------------------------------------------------------------------------------------
		SET @process = ' Fix CW-8657: Del action 7 se quita la validacion del telefono y de creditos ya se crea un accion 16 con dichas validaciones. Esto para regresar el status de error en los tres flujos.'
		SET @sql = 'ALTER procedure [dbo].[ccspLoadRegistrySegments] 
                    @action int,
                    @camId int = null,
                    @typeTemplate int=2, --1 Segmentos, 2 Plantillas Archivos
                    @phone varchar(32)=null,
                    @templateId int=null,
                    @callKey varchar(60)=null,
                    @userId int=0,
                    @msg varchar(160)=null,
                    @smsout_id int=null,
                    @SystemApiId varchar(100)=null,
                    @statusSystemsId int=null,
                    @dateStart datetime=null,
                    @dateEnd datetime=null,
                    @segmentIds varchar(max)='''',
                    @columns varchar(max)=''*''
                    as

                    SET NOCOUNT ON;
                    SET ANSI_WARNINGS OFF;

                    DECLARE @sql VARCHAR(max)
                    declare @today date=convert(date,getdate(),121)
                    declare @monday datetime
                    declare @valueInt104 int, @value17 varchar(100), @value247 varchar(100), @valueInt258 int

                    IF @action IN (7,16) BEGIN
                        select 
                            @valueInt104 = case when setting_id = 104 then valor else @valueInt104 end,
                            @value17 = case when setting_id = 17 then valor else @value17 end,
                            @value247 = case when setting_id = 247 then valor else @value247 end,
                            @valueInt258 = case when setting_id = 258 then valor else @valueInt258 end
                        from VIEW_SETTINGS 
                        where setting_id in (104, 17, 247, 258)
                    END

                    if @action=1 begin --List Segments
                        select SegmentId,Name from ccSmsSegments where IsGlobal=1 or CampaignId=@camId
                    end
                    else if @action=2 begin  --ListColumnsTable
                        SELECT name
                        FROM sys.columns
                        WHERE object_id = OBJECT_ID(''SmsRemesasMuñoz'')
                        and name like ''TELEFONOS[0-9]%''
                    end
                    else if @action=3 begin --List Plantillas
                        select TemplateId,Description as Name,MessageTemplate from ccSmsTemplate where Type=@typeTemplate
                    end
                    else if @action=4 begin
                        Select iDate DateStart,fDate DateEnd from ccSmsSchedules where cam_id=@camId
                    end
                    else if @action=5 begin
                        select top 1 * from SmsRemesasMuñoz
                    end
                    else if @action=6 begin
                        SET @columns = ''''
                        SELECT @columns = @columns + ''isnull(max(len('' + COLUMN_NAME + '')),0)as '' + COLUMN_NAME + '',''
                        FROM INFORMATION_SCHEMA.COLUMNS
                        WHERE TABLE_NAME = ''SmsRemesasMuñoz''
                        AND DATA_TYPE IN (''varchar'', ''nvarchar'', ''char'', ''nchar'');

                        SET @columns = SUBSTRING(@columns, 0, len(@columns))
                        SET @sql = ''select '' + @columns + '' from SmsRemesasMuñoz''

                        --PRINT (@sql)
                        EXEC (@sql)

                    end
                    else if @action = 7 begin  -- Return api information after validation
                        select 1 as Result, @value247 as ApiBackBone, MessageTemplate
                        from ccSmsTemplate 
                        where TemplateId = @templateId
                    end
                    else if @action=8 begin --smsOutSource
                        insert into smsOutSource (callkey,cam_id,sms_phoneNumber,sms_status,sms_attemps,user_id,sms_dateDial,dial_tels)
                        values (@callKey,@camId,@phone,0,0,@userId,getdate(),''12345NNN'')
                        select @smsout_id=SCOPE_IDENTITY()

                        insert into smsoutSourceMessage(smsout_id,message)
                        values(@smsout_id,@msg)

                        select @smsout_id as smsoutId
                    end
                    else if @action=9 begin --smsccoLogDial
                        insert into smsccoLogDial (smsout_id,cam_id,phone,smsDate,registryClient,SystemApiId,statusSystemsId,Bill,ProviderId)
                        values (@smsout_id,@camId,@phone,getdate(),@callKey,@SystemApiId,@statusSystemsId,
                        case when @statusSystemsId=0 then 0.7 else 0 end,0
                        )	
                    end
                    else if @action=10 begin --ChangeSchedule
                        delete from ccSmsSchedules where cam_id=@camId
                        insert into ccSmsSchedules(cam_id,iDate,fDate) values(@camId,@dateStart,@dateEnd)
                    end
                    else if @action=11 begin --Carga los registros cargados
                        truncate table ccSmsValidateRegistryWeek;
                        SELECT @monday= DATEADD(DAY, -(DATEPART(WEEKDAY, @today) + @@DATEFIRST - 2) % 7, CAST(@today AS DATE))
                        ---------------Revisa la lista de registros es necesario moverlo a otro proceso para que lo tenga en la carga---------------------
                        insert into ccSmsValidateRegistryWeek(registryClient,total,totaltoDay,loadRegistry)
                        select registryClient,count(*) total,
                        count(case when smsDate>=@today  then 1 end) totaltoday,
                        0 loadRegistry
                        from smsccoLogDial with(nolock)
                        where smsDate>=@monday
                        group by registryClient

                    end
                    else if @action in(12,13) begin --Validar Carga

                        declare @segmentTable table(id int, status bit, segmentName VARCHAR(10))
                        declare @segmentNames varchar(max)
                        declare @conditionTable table(conditionId int,smsCondition varchar(max),DailyLimit int,WeeklyLimit int,status bit, SegmentName varchar(255))
                        --declare @SmsRemesasId table (credictId int)
                        create table #SmsRemesasId(creditId nvarchar(40), TDCT VARCHAR(max))
                        create table #SmsRemesasIdTemp(creditId nvarchar(40), TDCT VARCHAR(max))
                        create table #functionalState(creditId nvarchar(40), smsSent int)
                        declare @FlagB table(credictId int, TDCT VARCHAR(max))
                        ------------Se obtiene los dias de la semana que han pasado
                        DECLARE @lastMonday datetime, @WeekStart datetime;
                        DECLARE @DaysFromWeek int, @LastMondaymonth int, @ActualMonth int
                        DECLARE @actualDate datetime = getdate()
                        SET @lastMonday = DATEADD(DAY, -(DATEPART(WEEKDAY, @actualDate) + 5) % 7, @actualDate);
                        --select @lastMonday lastMonday, @actualDate actualDate

                        SET @LastMondaymonth = DATEPART(MONTH, @lastMonday);
                        SET @ActualMonth = DATEPART(MONTH, @actualDate);

                        IF(@ActualMonth = @LastMondaymonth)
                        BEGIN
                            SELECT @DaysFromWeek = DATEDIFF(DAY, @lastMonday, @actualDate);
                        END
                        ELSE BEGIN
                            SELECT @DaysFromWeek = DATEDIFF(DAY, DATEADD(DAY, 1 - DATEPART(DAY, @actualDate), @actualDate), @actualDate);
                        END
                        SET @WeekStart = CONVERT(datetime, CONVERT(date, @actualDate-@DaysFromWeek));
                        

                        --------------------------Comienza validacion--------------

                        insert into @segmentTable
                        select a.value,0 status, s.Name from dbo.fn_RIASplitDelimited(@segmentIds,'','') a
                        inner join ccSmsSegments s on s.segmentId = a.value

                        --Condicion para obtener solo los que coincidan con SegmentoMC
                        SELECT @segmentNames = COALESCE(@segmentNames + '', '', '''') + QUOTENAME(a.segmentName, '''''''')
                        FROM @segmentTable a

                        --Tabla con todos los id de la tabla remesa que hacen match con los segmentos
                        INSERT INTO #SmsRemesasIdTemp
                        SELECT a.credito, a.TDCT from SmsRemesasMuñozDay a 
                        INNER JOIN @segmentTable b on a.SegmentoMC = b.segmentName
                        --Reseteamos todos los resultados para los segmentos
                        UPDATE rmd SET rmd.RESULTADO = '''', rmd.RESULTADO_ID = 0
                        FROM SmsRemesasMuñozDay rmd 
                        INNER JOIN #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT

                        --Actualizamos resultado para FLAG B
                        UPDATE rmd SET rmd.RESULTADO = ''FLAG B'', rmd.RESULTADO_ID = 1, rmd.RESULTADO_ENVIO = 0
                        FROM SmsRemesasMuñozDay rmd
                        inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
                        inner join ccSmsSegmentFlagB sfb on rmd.Fila = sfb.Validation
                        WHERE rmd.RESULTADO_ID = 0 AND sfb.IsActive = 1

                        --Actualizamos resultado para Telefono fijo y telefono no existe
                        UPDATE rmd SET 
                        rmd.RESULTADO = CASE 
                            WHEN dbo.VerifySmsMCA(rmd.TELEFONOS1) = 3 THEN ''NO ES POSIBLE ENVIO, CELUAR NO SE ENCUENTRA EN IFT''
                            WHEN dbo.VerifySmsMCA(rmd.TELEFONOS1) = 5 THEN ''TELEFONO FIJO''
                            ELSE '''' END,
                        rmd.RESULTADO_ID = dbo.VerifySmsMCA(rmd.TELEFONOS1),
                        rmd.RESULTADO_ENVIO = 0
                        FROM SmsRemesasMuñozDay rmd
                        inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
                        WHERE rmd.RESULTADO_ID = 0

                        --Regla de Estado Funcional para segmento BMX_122
                        UPDATE rmd SET rmd.RESULTADO = ''NO SE ENVIA POR REGLA DE ESTADO FUNCIONAL'', rmd.RESULTADO_ID = 4, rmd.RESULTADO_ENVIO = 0
                        FROM SmsRemesasMuñozDay rmd
                        inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
                        WHERE rmd.RESULTADO_ID = 0 AND rmd.SegmentoMC = ''BMX_122''
                        AND ESTADO_FUNCIONAL <> ''F''

                        INSERT INTO #functionalState
                        select rid.creditId, count(rid.creditId) from smsccoLogDial ld
                        inner join #SmsRemesasIdTemp rid on rid.TDCT = ld.registryClient
                        where ld.smsDate >= @WeekStart
                        GROUP BY rid.creditId

                        UPDATE rmd SET rmd.RESULTADO = ''NO SE ENVIA POR REGLA DE ESTADO FUNCIONAL'', rmd.RESULTADO_ID = 4, rmd.RESULTADO_ENVIO = 0
                        FROM SmsRemesasMuñozDay rmd
                        inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
                        inner join #functionalState fs on rmd.id_credito = fs.creditId
                        WHERE rmd.RESULTADO_ID = 0 AND rmd.SegmentoMC = ''BMX_122''
                        AND fs.smsSent >= 3;


                        declare @subQuery nvarchar(max)
                        
                        SELECT @monday= DATEADD(DAY, -(DATEPART(WEEKDAY, @today) + @@DATEFIRST - 2) % 7, CAST(@today AS DATE))
                        
                        if not exists(select * from ccSmsValidateRegistryWeek)begin
                            exec ccspLoadRegistrySegments @action=11
                        end
                        

                        declare @conditionId int,@segmentId int,@SubConditionId int
                        declare @conditionWhere varchar(max)
                        declare @SubConditionWhere varchar(max),@LogicConector varchar(20)
                        declare @DailyLimit int,@WeeklyLimit int
                        declare @SegmentName varchar(255)

                        DECLARE @Params NVARCHAR(MAX)
                        SET @Params = N''@WeeklyLimit int,@DailyLimit int'';
                        
                    ---Lista de @segmentIds
                    while exists(select * from @segmentTable where status=0) begin
                        select top 1 @segmentId=id from @segmentTable where status=0		
                        set @conditionId=0
                        -------------------------------- Revisa las condiciones por segmentId --------------------------------
                        while exists(select * from ccSmsConditions where SegmentId=@segmentId and ConditionId>@conditionId) begin
                            
                            SELECT @SegmentName = [Name] from ccSmsSegments where SegmentId = @segmentId

                            select top 1
                            @DailyLimit=DailyLimit,	@WeeklyLimit=WeeklyLimit,@conditionId=ConditionId,
                            @conditionWhere= PrimaryField+LogicOperator
                            +case when isnull(ComparisonValue,'''') <>'''' then ComparisonValue else''(''+ ComparisonField end 					
                            +case when isnull(ComparisonValue,'''') <>'''' or  isnull(ArithmeticOperator,'''')='''' or isnull(Value,'''')=''''then '''' else isnull(ArithmeticOperator,'''')+isnull(Value,'''') end 
                            +case when isnull(ComparisonValue,'''') <>'''' then '''' else'')'' end 
                            from ccSmsConditions where SegmentId=@segmentId and ConditionId>@conditionId
                            
                            set @SubConditionId=0
                            while exists(select * from ccSmsSubconditions where ConditionId=@conditionId and SubconditionId>@SubConditionId) 
                            begin
                            
                                select top 1
                                @LogicConector=LogicConector,
                                @SubConditionId=SubconditionId,
                                @SubConditionWhere=
                                PrimaryField+LogicOperator
                                +case when isnull(ComparisonValue,'''') <>'''' then ComparisonValue else''(''+ ComparisonField end 					
                                +case when isnull(ComparisonValue,'''') <>'''' or  isnull(ArithmeticOperator,'''')='''' or isnull(Value,'''')='''' then '''' else isnull(ArithmeticOperator,'''')+isnull(Value,'''') end
                                +case when isnull(ComparisonValue,'''') <>'''' then '''' else'')'' end 
                                from ccSmsSubconditions where ConditionId=@conditionId and SubconditionId>@SubConditionId

                                set @conditionWhere=@conditionWhere+'' ''+ @LogicConector+'' '' +@SubConditionWhere

                                
                            end
                                
                            insert into @conditionTable values(@conditionId,@conditionWhere,@DailyLimit,@WeeklyLimit,0, @SegmentName)	
                        end 
                        -------------------------------- Termina las condiciones por segmentId --------------------------------
                        update @segmentTable set status=1 where id=@segmentId
                    end
                    while exists(select * from @conditionTable where status=0) begin		
                        select top 1 
                        @conditionId=conditionId, @DailyLimit=DailyLimit, @WeeklyLimit=WeeklyLimit,	@conditionWhere=smsCondition,
                        @SegmentName = SegmentName
                        from @conditionTable 
                        where status=0
                        
                        set @subQuery= ''select A.id_credito, A.TDCT from SmsRemesasMuñozDay A with(nolock)
                        left join ccSmsValidateRegistryWeek B on A.credito=B.registryClient and B.total<@WeeklyLimit and B.totaltoDay<@DailyLimit
                        where  SegmentoMC in ('''''' + @SegmentName + '''''') AND RESULTADO_ID = 0 AND '' + @conditionWhere	
                        print(@subQuery)
                        insert into #SmsRemesasId
                        EXEC sp_executesql @subQuery,@Params,@WeeklyLimit,@DailyLimit;
                        update @conditionTable set status=1 where @conditionId=conditionId
                    end

                    --Actualizamos los ids que no coindiden
                    UPDATE rmd SET rmd.RESULTADO = ''CUENTA CON T. Celular para envio de sms'' , rmd.RESULTADO_ID = 6
                    FROM SmsRemesasMuñozDay rmd
                    INNER JOIN #SmsRemesasId rid on rid.TDCT = rmd.TDCT
                    WHERE RESULTADO_ID = 0;

                    --Actualizamos todo lo que no cumple
                    UPDATE rmd SET rmd.RESULTADO = ''NO CUMPLE CON REGLA DE CORTE'' , rmd.RESULTADO_ID = 2, rmd.RESULTADO_ENVIO = 0
                    FROM SmsRemesasMuñozDay rmd
                    INNER JOIN #SmsRemesasIdTemp rid on rid.TDCT = rmd.TDCT
                    WHERE RESULTADO_ID = 0;
                        
                    if @action=12 begin
                        declare @countValidate int,@nonValid int
                        select @countValidate=count(1) from SmsRemesasMuñozDay A with(nolock)
                        inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID = 6

                        select @nonValid=count(1) from SmsRemesasMuñozDay A with(nolock)
                        inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID <> 6

                        INSERT INTO SmsSegmentsValidationResult(id_credito, credito, TELEFONOS1, TDCT, RESULTADO, RESULTADO_ID, validation_date)
                        SELECT A.id_credito, A.credito, TELEFONOS1, A.TDCT, A.RESULTADO, A.RESULTADO_ID, GETDATE() FROM SmsRemesasMuñozDay A
                        inner join #SmsRemesasIdTemp b on A.TDCT = b.TDCT

                        select @countValidate as ValidRecords,@nonValid as InvalidRecords
                    end
                    else begin
                        DECLARE @tableName VARCHAR(20) = ''TEMPO_''+convert(varchar(10),@camId)
                        DECLARE @columnsWithTypes VARCHAR(MAX)
                        DECLARE @newColumns VARCHAR(MAX)
                        DECLARE @createTable VARCHAR(MAX)
                        DECLARE @insertInto VARCHAR(MAX)

                        SELECT 
                            @columnsWithTypes = COALESCE(@columnsWithTypes + '', '', '''') + 
                            QUOTENAME(COLUMN_NAME) + '' '' + DATA_TYPE + 
                            CASE 
                                WHEN DATA_TYPE IN (''char'', ''varchar'', ''nchar'', ''nvarchar'', ''binary'', ''varbinary'') THEN ''('' + 
                                    CASE 
                                        WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN ''MAX'' 
                                        ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR)
                                    END + '')''
                                WHEN DATA_TYPE IN (''decimal'', ''numeric'') THEN ''('' + CAST(NUMERIC_PRECISION AS VARCHAR) + '','' + CAST(NUMERIC_SCALE AS VARCHAR) + '')''
                                ELSE ''''
                            END,
                            @newColumns = COALESCE(@newColumns + '', '', '''') + QUOTENAME(COLUMN_NAME)
                        FROM INFORMATION_SCHEMA.COLUMNS
                        WHERE TABLE_NAME = ''SmsRemesasMuñozDay'' AND COLUMN_NAME in (select value from dbo.fn_RIASplitDelimited(@columns,'',''))

                        SET @createTable = ''IF EXISTS (SELECT * FROM sys.tables WHERE name = N'''''' + @tableName +'''''')
                        BEGIN
                            DROP TABLE '' + @tableName + ''
                        END
                            CREATE TABLE '' + @tableName + '' (
                                Record_id INT IDENTITY(1,1) PRIMARY KEY, ActiveRecord BIT DEFAULT(0),PhoneStatus int, callout_id int, DataPhone varchar(100), cal_Key varchar(40), cal_telephone varchar(40) default(''''''''), 
                                '' + @columnsWithTypes + '');''
                        print(@createTable)
                        EXEC (@createTable)
                        
                        set @sql=''INSERT INTO '' + @tableName + '' (PhoneStatus, callout_id, DataPhone, cal_Key, cal_telephone,'' + @newColumns + '')
                        select 0 PhoneStatus,0 callout_id,convert(varchar(100),'''''''') as DataPhone, A.TDCT, TELEFONOS1, ''+@newColumns+''
                        from SmsRemesasMuñozDay A with(nolock) inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID = 6''
                        print(@sql)
                        exec(@sql)
                        set @sql = ''IF EXISTS (SELECT * FROM sys.tables WHERE name = N'''''' + @tableName +''_ids'''')
                        BEGIN
                            DROP TABLE '' + @tableName + ''_ids
                        END
                        Create table '' + @tableName + ''_ids (Record_id int)'';
                        exec(@sql)
                    end
                    drop table #SmsRemesasId
                    drop table #SmsRemesasIdTemp
                    drop table #functionalState
                    end
                    else if @action =14 begin 
                        select MessageTemplate from ccSmsTemplate where TemplateId=@templateId
                    end

                    else if @action =15 begin --Obtener resultados de validación por segmentos

                        DECLARE @counter int = 0
                        DECLARE @ActualDay DATETIME = GETDATE();
                        DECLARE @FirstDayMonth DATETIME = DATEADD(MONTH, DATEDIFF(MONTH, 0, @ActualDay),0)
                        DECLARE @DayCounter DATETIME;
                        DECLARE @WeekCount int = 0;

                        WHILE @counter < DAY(@ActualDay)
                        BEGIN
                            SET @DayCounter =  DATEADD(DAY, @counter, @FirstDayMonth)
                            IF DATEPART(WEEKDAY,@DayCounter) = 2
                                SET @WeekCount = @WeekCount + 1
                            print @DayCounter
                            set @counter = @counter + 1
                        END

                        IF DATEPART(WEEKDAY, @FirstDayMonth) <> 2 BEGIN
                            SET @WeekCount = @WeekCount + 1
                        END

                        declare @segments table(segmentName VARCHAR(10))

                        insert into @segments
                        select s.Name from dbo.fn_RIASplitDelimited(@segmentIds,'','') a
                        inner join ccSmsSegments s on s.segmentId = a.value

                        select	id_credito AS id_credit, credito AS credit, GETDATE() as snapshot_date, MESES_VENCIDOS as expired_month, SEG_CUENTA as seg_account,
                                FILA as seg_row, LOCACION as [location], DIA_CORTE as cut_day, SegmentoMC as segment_mc, @WeekCount as [week], DATEPART(WEEKDAY, @ActualDay) week_day,
                                TELEFONOS1 as phones1, RESULTADO as result, ISNULL(ESTADO_FUNCIONAL, '''') as functional_state, ISNULL(CORTE_REAL, '''')  as real_cut
                        from SmsRemesasMuñozDay rmd
                        inner join @segments s on rmd.SegmentoMC = s.segmentName;
                        
                    end

                    else if @action =16 begin --Validate phone and credits for sms test message
                        select @phone = dbo.Verifica2(@phone, @valueInt104, @value17, 1)
                        if LEFT(@phone, 1) = ''E'' begin
                            select -3 -- Not a Cellphone
                            return -1;
                        end
                        if @valueInt258 <= 0 begin
                            select -2 -- No Credits
                            return -1;
                        end
                        select 1 -- Validation OK
                    end'
		EXEC(@sql)

		------------------------------------------------- Termina Ivan Martin ----------------------------------------------------------------------------------

        ------------------------------------------------- Empieza Carlos Muñoz ----------------------------------------------------------------------------------
        SET @process = 'Nuevo procedimiento almacenado para el reinicio diario de la tabla de conteo de conversaciones del día'
        SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_InitConversationCount'')
			begin
				DROP PROCEDURE ccsp_InitConversationCount;
			end'
        
        EXEC(@sql)
        SET @sql = '
            CREATE PROC ccsp_InitConversationCount
                AS
                BEGIN
                    IF OBJECT_ID(''ccWAOperatingSummary'') IS NULL
                        BEGIN
                            CREATE TABLE ccWAOperatingSummary(
                                Inboundid INT,
                                Attended INT, 
                                onQueue INT, 
                                Assigned INT, 
                                Request INT, 
                                EndedBySystem INT, 
                                Available INT,
                                MarkedAsSpam INT,
                            )
                        END
                    ELSE 
                        BEGIN
                            TRUNCATE TABLE ccWAOperatingSummary
                        END

                    DECLARE @TodayDate AS DATE = GETDATE();

                    WITH ConversationStats AS (
                        SELECT 
                            inboundId,
                            ISNULL(COUNT(CASE WHEN conversationStatus = 2 THEN 1 END), 0) AS enCurso,
                            ISNULL(COUNT(CASE WHEN conversationStatus = 8 THEN 1 END), 0) AS enCola,
                            ISNULL(COUNT(CASE WHEN conversationStatus IN(4,10,17,18) and finishedBy = 2 THEN 1 END), 0) AS terminadasPorSistema,
                            ISNULL(COUNT(CASE WHEN conversationStatus = 11 AND finishedBy = 1 THEN 1 END), 0) AS terminadasPorAgente,
                            ISNULL(COUNT(CASE WHEN conversationStatus = 13 THEN 1 END), 0) AS Spam,
                            ISNULL(COUNT(CASE WHEN CAST(requestDate AS date) = @TodayDate or 
                                                CAST(assignDate AS date) = @TodayDate or
                                                DATEDIFF(HOUR, requestDate, @TodayDate) <= 24 AND conversationStatus = 8 THEN 1 END), 0) AS todayConversations
                        FROM
                            ccWhatsAppConversations
                        WHERE CAST(requestDate AS date) = @TodayDate OR CAST(assignDate AS date) = @TodayDate or DATEDIFF(HOUR, requestDate, @TodayDate) <= 24 AND conversationStatus = 8  --Solo obtiene las de hoy
                        GROUP BY 
                            inboundId
                    )

                    INSERT INTO ccWAOperatingSummary 
                    SELECT 
                        ccin.Inbound_id,
                        ISNULL(cs.terminadasPorAgente,0) AS Attended,
                        ISNULL(cs.enCola,0) onQueue,
                        ISNULL(cs.enCurso,0) AS Assigned,
                        ISNULL(cs.todayConversations, 0) AS Request,
                        ISNULL(cs.terminadasPorSistema,0) AS EndedBySystem,
                        0,
                        ISNULL(cs.Spam,0) AS markedAsSpam
                    FROM
                        ccInbound ccin
                    LEFT JOIN
                        ConversationStats cs
                    ON 
                        ccin.Inbound_id = cs.inboundId

                    WHERE ccin.chat = 5
                END'
        EXEC(@sql)

        SET @process = 'Nuevo procedimiento almacenado la consulta general de conversaciones del día por área del administrador'
        SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GetInboundConversations'')
			begin
				DROP PROCEDURE ccsp_GetInboundConversations;
			end'
        EXEC(@sql)

        SET @sql = '
        CREATE PROC ccsp_GetInboundConversations 
            @id_admin INT
            AS
            BEGIN
                DECLARE @id_userArea INT
                IF @id_admin != 1
                BEGIN
                    SELECT @id_userArea = IDArea FROM ccUsers WHERE User_id = @id_admin
                END

                SELECT 
                    ccIN.descripcion AS Descripcion, 
                    ccWA.Request AS TodayConversations, 
                    ccWA.Assigned AS InProgress, 
                    ccWA.OnQueue AS InQueue, 
                    ccWA.EndedBySystem AS FinishedBySystem, 
                    ccWA.Attended AS FinishedByAgent, 
                    ccWA.MarkedAsSpam AS MarkedAsSpam,
                    ccRCA.AreaName AS AreaName
                FROM ccInbound ccIN 
                    LEFT JOIN ccWAOperatingSummary ccWA ON ccIN.Inbound_id = ccWA.InboundId
                    LEFT JOIN ccRIACat_Areas ccRCA on  ccIN.IDArea = ccRCA.IDArea
                WHERE ccIN.IDArea = (CASE WHEN @id_admin = 1 THEN ccIN.IDArea
                                    ELSE @id_userArea END) and ccIN.chat = 5
            END
        '
        EXEC(@sql)

        SET @process = 'Modificación del procedimiento para manejar los conteos'
        SET @sql = '
        ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
		, @conversationId     INT         = 0
		, @inboundId          SMALLINT    = NULL
		, @phoneACD           VARCHAR(50) = NULL
		, @clientId           VARCHAR(25) = NULL
		, @conversationStatus SMALLINT    = 0
		, @tChatting          FLOAT    = 0
		, @tWrapUp            SMALLINT    = 0
		, @finishedBy         TINYINT     = 0
		, @onQueue            BIT         = NULL
		, @tQueue             SMALLINT    = 0
		, @tTimeout           INT         = 0
		, @disposition        SMALLINT    = 0
		, @subDisposition     SMALLINT    = 0
		, @agentId            INT         = 0
		--VAR MESSAGES
		, @messageId          VARCHAR(150) = NULL
		, @messageIdUi        INT         = NULL
		, @clientNum          VARCHAR(15) = NULL
		, @vonageNum          VARCHAR(15) = NULL
		, @typeMessage        VARCHAR(25) = ''''
		, @content            NVARCHAR(MAX)= NULL
		, @timeStampMessage   DATETIME    = NULL
		, @timeStampMessageUTC DATETIME   = NULL
		, @originType         VARCHAR(15) = NULL
		, @currency           VARCHAR(10) = ''-''
		, @price              VARCHAR(10) = ''0.00''
		, @messageStatus      VARCHAR(15) = ''N/A''
		, @listConversationsIds   VARCHAR(MAX) = NULL
		, @IsAgentLoggingOut  BIT = 0
		AS
		BEGIN
			DECLARE @isEndConversation BIT;
			DECLARE @meanContactTypeId SMALLINT;
			DECLARE @conversationIdNew INT;
			SET @meanContactTypeId = 1;
			SET NOCOUNT ON;

			IF @action = 1
			BEGIN 
				IF NOT EXISTS --new Conversation
				(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock)
														WHERE A.conversationId = @conversationId)
				BEGIN
					INSERT INTO [ccWhatsAppConversations]
					(inboundId
					, phoneACD
					, clientId
					, conversationStatus
					, tChatting
					, tWrapUp
					, finishedBy
					, onQueue
					, tQueue
					, tTimeout
					, disposition
					, subDisposition
					, agentId
					)
					VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

					IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId) 
						BEGIN
							SELECT @conversationId = SCOPE_IDENTITY();
							SELECT @conversationId AS ConversationId;
						END

					ELSE 
						BEGIN
							declare @conversationIdTemporal     INT;
							SELECT @conversationIdTemporal = SCOPE_IDENTITY();
							EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
							SELECT 0 AS ConversationId;
						END;

					--Save new request
					IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
						BEGIN
							INSERT INTO ccWAOperatingSummary (InboundId, Request) VALUES (@inboundId, 1);
						END
					ELSE
						BEGIN
							UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
						END
					RETURN(0);
				END

				ELSE -- Reasign conversation
				BEGIN
					DECLARE @conversationStatusTemp INT = @conversationStatus;
					IF @conversationStatus in(17,18) 
						BEGIN
							SET @conversationStatusTemp = 1
						END

					DECLARE @RequestDate DATETIME = NULL;
					SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversations WITH(NOLOCK) WHERE conversationId = @conversationId;

					INSERT INTO [ccWhatsAppConversations]
					(inboundId
					, phoneACD
					, clientId
					, conversationStatus
					, tChatting
					, tWrapUp
					, finishedBy
					, onQueue
					, tQueue
					, tTimeout
					, disposition
					, subDisposition
					, agentId
					, requestDate
					)
					VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
					SELECT @conversationIdNew = SCOPE_IDENTITY();

					INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore, conversationIdAfter) VALUES (@conversationId, @conversationIdNew);
					--Save new request by reassign
					UPDATE ccWAOperatingSummary SET Request = (Request + 1), Assigned = (Assigned - 1), EndedBySystem = EndedBySystem + 1
					WHERE InboundId = @inboundId

					EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus
	
					SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship with(nolock) where conversationIdBefore = @conversationId;
					RETURN(0);
				END;
		END; -- End Action 1

		ELSE IF @action = 2
		BEGIN --save conversation Times
			DECLARE @conversationIdTemp INT;
			DECLARE @TablaTemp TABLE (conversationId INT, status bit);

			IF @listConversationsIds IS NOT NULL begin
				INSERT INTO @TablaTemp
				SELECT value,0
				FROM fn_RIASplitDelimited(@listConversationsIds, '','')
				where value is not null and value<>''''
			end
			else begin
				INSERT INTO @TablaTemp values(@conversationId,0)
			end

			UPDATE ccWhatsAppConversations
			SET
			conversationStatus = @conversationStatus
			, finishedBy = case when @conversationStatus in(4,10,17,18) then 2
			when @conversationStatus in(11) then 1
			else 0 end
			, tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
			,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
			,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
			WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

				WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
			BEGIN
				select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
				exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

			IF @conversationStatus in(4,10,11,13,17,18) BEGIN -- Ending Cases
					DECLARE @conversationDateTemp INT;
					select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
					from ccWhatsAppConversations with(nolock) where conversationId = @conversationId;


					IF @conversationStatus = 13 BEGIN
						UPDATE ccWAOperatingSummary SET MarkedAsSpam = (MarkedAsSpam + 1) where Inboundid = @inboundId
						IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
							INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
						END
					END
					ELSE IF @conversationStatus in(4,10,17,18) 
					BEGIN --Save conversation Ended by system
						IF @conversationDateTemp > 0 
						BEGIN
							UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
						END
					END
					ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
						UPDATE ccWAOperatingSummary SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
					END
				END
				update @TablaTemp set status=1 where conversationId=@conversationIdTemp
			END

		END;

		ELSE IF @action = 3
		BEGIN --save conversation Status
		UPDATE ccWhatsAppConversations SET conversationStatus = @conversationStatus
			WHERE conversationId = @conversationId;
		END;

		ELSE IF @action = 4 BEGIN --save messages from conversation
		IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock) WHERE A.conversationId=@conversationId)
				AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
			BEGIN
				IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
					(SELECT messageIdUi
						FROM ccWAMessagesConversations
						WHERE originType IN (''Agent'', ''Admin'')
						AND conversationId = @conversationId)
					BEGIN
						UPDATE ccWhatsAppConversations
							SET FirstMessageAgent = @timeStampMessage
							WHERE conversationId = @conversationId;
					END

				INSERT INTO [ccWAMessagesConversations](
													messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
													(@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
				SELECT @messageId=SCOPE_IDENTITY()
				SELECT @messageId as MessageId
				RETURN (0)
			END
			ELSE BEGIN
				SELECT 0 AS MessageId
				RETURN (0)
			END
		END;

			IF @action = 5
			BEGIN --save onQueue
				UPDATE ccWhatsAppConversations
						SET onQueue = 1,
						conversationStatus = @conversationStatus
				WHERE conversationId = @conversationId;
		SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
				UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
			END;

		ELSE IF @action = 6
		BEGIN --save agent, assigdate and tqueue
			
			 --Assigned a queue conversation
			declare @agentIdTmp int
			DECLARE @inboundIdTmp int
			DECLARE @lastStatus int
			SELECT @agentIdTmp = A.agentId, @inboundIdTmp = A.inboundId, @lastStatus = A.conversationStatus FROM ccWhatsAppConversations A with(nolock) where A.conversationId = @conversationId

			IF (@agentIdTmp is null or @agentIdTmp=0)
			BEGIN
				UPDATE ccWhatsAppConversations
						SET agentId = @agentId,
						assignDate = getdate(),
						conversationStatus = @conversationStatus
						,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
				WHERE conversationId = @conversationId;

				SELECT @conversationId as conversationId
				SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
				declare @onQueueInt int
				UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE Inboundid = @inboundId -- It´s assigned
				IF @onQueue = 1 BEGIN
					UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1),@onQueueInt =OnQueue WHERE InboundId = @inboundId
					if @onQueueInt<=0 or exists(select * from ccWAOperatingSummary WHERE InboundId = @inboundId and OnQueue<0)begin

						select          
						@onQueueInt=count(case when onQueue =1 then 1 end)
						from ccWhatsAppConversations with(nolock)
						where inboundId= @inboundId
						and requestDate>=convert(date,getdate(),121)
						UPDATE ccWAOperatingSummary SET OnQueue = @onQueueInt WHERE InboundId = @inboundId

					end
				END
			END
		END;

		ELSE IF @action = 7
			BEGIN --update price message
				UPDATE ccWAMessagesConversations
						SET price = @price,
							currency = @currency
				WHERE messageId = @messageId;
			END;

		ELSE IF @action = 8
			BEGIN --update status message
				IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
					UPDATE ccWAMessagesConversations
							SET messageStatus = @messageStatus
					WHERE messageId = @messageId;
				END;
			END;

		ELSE IF @action = 9
			BEGIN --Save last message time by conversationID
				IF not exists(SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) BEGIN
					INSERT INTO ccLastMessageAgentByConversation (conversationId,timeStampLastMessageAgent) VALUES (@conversationId,getDate())
				END;
				ELSE
					BEGIN
						UPDATE ccLastMessageAgentByConversation
							SET timeStampLastMessageAgent = getDate()
						WHERE conversationId = @conversationId;
					END;
			END;

		ELSE IF @action = 10
			BEGIN --drop and insert register by conversationID
				DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
			END;

		ELSE IF @action = 11
			BEGIN --register desconnection agent by conversationID
				UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
			END;

		ELSE IF @action = 12
			BEGIN --Obtain conversationsWA post MCS reset

				declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
				UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

				declare @from as datetime;-- = ''01-07-2022'';
				select @from = convert(datetime,convert(varchar(11),getdate()))
				set @from=DATEADD(dd,-1,@from);
					select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
					,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
					from ccWhatsAppConversations A with(nolock)
					left join ccWAMessagesConversations B on A.conversationId = B.conversationId
					left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp
					where A.requestDate >= @from 
						and A.conversationStatus not in (4, 10, 11, 13, 17, 18, 19)
					order by agentId desc, requestDate,timeStampMessage, inboundId, clientId 
			END;
		ELSE IF @action = 13
			BEGIN ---Obtain agents ON STATUS READY
				WITH agents
				AS(
					SELECT c.User_id, c.fecha, c.currentStatus
					FROM ccLogAgentesDia c
					INNER JOIN 
					(
						SELECT User_id, MAX(fecha) max_time
						FROM ccLogAgentesDia with(nolock)
						where fecha>=CONVERT(date,getdate(),121)
						GROUP BY User_id
					) AS t
					ON c.fecha = t.max_time
					AND c.User_id=t.User_id AND currentStatus in (3,34)
				), usersByCampigns
				AS (
					select IdCampEsp, User_id from ccRIACampEspWG A
					Inner join ccRIAWorkGroupUsers B
					on A.IDWG = B.IDWG
					Inner join contactMeanIn C
					ON A.idCampEsp = C.inboundId
					where A.IDWG = 1 and A.Tipo = 0
					AND C.meanContactTypeId = 5
				)

				select DISTINCT A.User_Id from agents A
				left join usersByCampigns B on A.User_Id = B.User_Id
			END;

		ELSE IF @action = 14
			BEGIN --register desconnection MCS
				INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
			END;

		ELSE IF @action = 15
			BEGIN --update content message
				IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
					UPDATE ccWAMessagesConversations
							SET content = @content
					WHERE messageId = @messageId;
				END;
			END;

		ELSE IF @action = 16
			BEGIN --update agent status for reassigning error message
					UPDATE ccWhatsAppConversations
					SET IsAgentLoggingOut = @IsAgentLoggingOut
					WHERE conversationId = @conversationId;
			END;

		ELSE IF @action = 18 BEGIN
				DECLARE @dateNow DATETIME;
				SET @dateNow = DATEADD(HOUR, -23, GETDATE());

				UPDATE ccWhatsAppConversations
				SET finishedBy = 2, conversationStatus=17
				WHERE finishedBy = 0 AND requestDate <= @dateNow    
			END;
		END;'
        EXEC(@sql)

        SET @process = 'Ajuste de SP para evitar conteos no deseados de conversaciones'
        SET @sql = '
        ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformation]
        @Option SMALLINT,
        @InboundId SMALLINT = 0,
        @ConversationId INT = 0,
        @AgentsAvailables INT = 0,
        @IncreaseDecreaseAgent BIT = NULL

        AS
        SET NOCOUNT ON

        IF @Option = 0 BEGIN	-- Reset TABLES
            TRUNCATE TABLE ccWAAverageConversations;
            TRUNCATE TABLE ccLastMessageAgentByConversation;
        END


        IF @InboundId IS NULL or  
        NOT EXISTS (SELECT * FROM ccInbound with(nolock) WHERE Inbound_id = @InboundId AND chat = 5) 
        BEGIN
        RETURN (-1)
        END

            DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
            
        IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
        BEGIN
            IF EXISTS (SELECT * FROM ccWAAverageConversations with(nolock)
                        WHERE InboundId = @InboundId
                        AND (LastUpdate IS NULL
                        OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                        OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
            BEGIN
                -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

                DECLARE @AverageConversationTime INT = 0;
                DECLARE @AverageDialogTime INT = 0;
                DECLARE @AverageWaitingTime INT = 0;
                DECLARE @MaximumWaitingTime INT = 0;
                DECLARE @DefaultValue INT = (SELECT CASE 
                        WHEN defaultServiceLevelParameter IS NULL THEN 2 
                        WHEN defaultServiceLevelParameter = 0 THEN 2
                        ELSE defaultServiceLevelParameter END
                FROM contactMeanIn WHERE inboundId = @InboundId);
                SET @DefaultValue = @DefaultValue * 60;
                DECLARE @LessThanDefault INT = 0;
                DECLARE @ReceivedConversations INT = 0;
                DECLARE @ServiceLevel SMALLINT = 0;

                --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

                SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
                        @AverageDialogTime = ROUND(AVG(tChatting), 4),
                        @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
                        @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
                        @ReceivedConversations = COUNT(conversationDate),
                        @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
                FROM ccWhatsAppConversations WHERE inboundId = @InboundId
                AND requestDate >= @Today

                SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

                ----------------------------------------------------- Update table --------------------------------------------------------

                IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
                BEGIN
                    UPDATE ccWAAverageConversations
                    SET AverageConversationTime = @AverageConversationTime,
                        AverageDialogTime = @AverageDialogTime,
                        AverageWaitingTime = @AverageWaitingTime,
                        MaximumWaitingTime = @MaximumWaitingTime,
                        ServiceLevel = @ServiceLevel,
                        StatusUpdate = 0,
                        LastUpdate = GETDATE()
                    WHERE InboundId = @InboundId
                END
                ELSE
                BEGIN
                    INSERT INTO ccWAAverageConversations (InboundId, AverageConversationTime, AverageDialogTime,
                                                            AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
                    VALUES(@InboundId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                            @ServiceLevel, 0 , GETDATE())
                END
            END
            --------------------------------- Results -----------------------------------

            if exists (select * from ccWAOperatingSummary with(nolock) where Inboundid=@InboundId
            and (OnQueue<0 or Assigned<0)
            ) begin                                
                set @Today =convert(date,getdate(),121)

                ;with waOperationSummary as(
                        select 
                inboundId
                --,count(case when finishedBy=1 then 1 end) Attend
                ,count(case when onQueue=1 and finishedBy=0 then 1 end) onQueue
                ,count(case when finishedBy=0 and agentId>0 then 1 end) Assigned
                --,count(*) Request
                --,count(case when finishedBy=2 then 1 end) EndedBySystem
                from ccWhatsAppConversations with(nolock)
                where inboundId=@InboundId
                and requestDate>=@Today
                group by inboundId
                )
                update A 
                set A.OnQueue=B.onQueue, A.Assigned=B.Assigned
                from ccWAOperatingSummary A 
                inner join waOperationSummary B on A.Inboundid=B.inboundId
            end


            SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
                ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
                ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
                ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
                ISNULL(ServiceLevel, 0) AS ServiceLevel,
                ISNULL(Attended, 0) AS Attended,
                ISNULL(Assigned, 0) AS Assigned,
                ISNULL(OnQueue, 0) AS OnQueue,
                ISNULL(EndedBySystem, 0) AS EndedBySystem,
                ISNULL(Available, 0) AS Available,
                ISNULL(Request, 0) AS Request
            FROM ccWAAverageConversations conv
            RIGHT JOIN ccWAOperatingSummary summary ON conv.InboundId = summary.InboundId
            WHERE conv.inboundId = @InboundId OR summary.InboundId = @InboundId
        END
        ELSE IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
            -- Average Queue/Waiting Time, and Service Level)
            BEGIN
                IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
                BEGIN
                    UPDATE ccWAAverageConversations SET StatusUpdate = 1
                    WHERE InboundId = @InboundId
                END
                ELSE
                BEGIN
                    INSERT INTO ccWAAverageConversations (InboundId, StatusUpdate)
                    VALUES(@InboundId, 1)
                END
            END
        ELSE IF @Option = 3 -- Save time from accepted conversation by agent
            BEGIN
                IF @ConversationId IS NOT NULL
                BEGIN
                    UPDATE ccWhatsAppConversations SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
                    --Save Conversation Assigned
                    SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
                END
            END
        ELSE IF @Option = 4 -- Get Disposition Information
            BEGIN
                declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
                select @nIdioma = case valor 
                    when 0 then ''Sin calificación''
                    when 2 then ''Sem classificação'' 
                    else ''No disposition'' end
                from ccsettings where setting_id = 27 -- 0esp
                SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
                                ISNULL(disposition.calif_id, 0) AS DispositionId,
                                COUNT(whatsConv.disposition) AS Total,
                                ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
                                COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
                FROM ccWhatsAppConversations whatsConv with(nolock) 
                LEFT JOIN cctipocalif disposition ON disposition.calif_id = whatsConv.disposition
                WHERE inboundId = @InboundId AND assignDate >= @Today
                        and whatsConv.conversationStatus != 2
                GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
            END
        ELSE IF @Option = 5 -- Get Subdisposition Information
            BEGIN
                SELECT relation.calif_id AS DispositionId,
                        subDispositions.califSubDesc AS SubDispositionsName,
                        COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
                FROM cctipoSubCalifRel relation
                INNER JOIN ccTipoCalifSub subDispositions ON subDispositions.califSub_id = relation.califSub_id
                INNER JOIN ccWhatsAppConversations whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
                WHERE whatsConv.inboundId = @InboundId AND
                        whatsConv.assignDate >= @Today AND
                        relation.tipoSubRel = 1
                GROUP BY subDispositions.califSubDesc, relation.calif_id
            END
        ELSE IF @Option = 6 -- Agents Availables
            BEGIN
            IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @InboundId)
                BEGIN
                    INSERT INTO ccWAOperatingSummary (InboundId, Available) VALUES (@InboundId, @AgentsAvailables);
                END
            ELSE
            BEGIN
                UPDATE ccWAOperatingSummary SET Available = @AgentsAvailables WHERE InboundId = @InboundId
            END
        END
        RETURN(0)
        '
        EXEC(@sql)

        SET @process = 'Ajuste SP para la consulta general de agentes por área de administrador en campañas de entrada'
        SET @sql = '
        ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns]
				@Option AS      SMALLINT, 
				@CampType AS    SMALLINT = 0, 
				@WorkgroupId AS INT      = 0, 
				@Id AS          INT      = 0, 
				@AdminId AS     SMALLINT = 0, 
				@PinUpdate AS   SMALLINT = 0, 
				@LoadId AS      INT      = 0, 
				@Type AS        SMALLINT = 0,
				@InboundType    SMALLINT = 0,
				@AreaId         SMALLINT = 0,
				@multi_type     varchar(max) = null,
				@IsWhatsAppCampaign  bit = 0
				AS
				BEGIN
					SET NOCOUNT ON;
				IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
                
					IF @CampType = 1 BEGIN-- Campaigns Out
                
					IF @WorkgroupId IS NOT NULL BEGIN
						SELECT CAST(IdCampEsp AS INT) AS Id FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId AND Tipo = 1
						ORDER BY IdCampEsp ASC;
					END;
					ELSE BEGIN
						RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
					END;
				END;
					IF @CampType = 0 BEGIN-- Campaigns In (ACD)
						IF @WorkgroupId IS NOT NULL BEGIN
							SELECT CAST(IdCampEsp AS INT) AS Id FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId AND Tipo = 0
							ORDER BY IdCampEsp ASC;
						END;
						ELSE
						BEGIN
							RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
						END;
					END;
					RETURN 0;
				END;
				IF @Option = 2 BEGIN-- Get Campaign complete information per Campaign Type and Campaign Id      
					IF @CampType = 1 BEGIN-- Campaigns Out      
						IF @Id IS NOT NULL BEGIN
							SELECT DISTINCT 
							CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
							isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
							camps.cam_procesando IsStarted, 
							ISNULL(a.AreaName, '''') AS Area, 
							CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
							CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
							CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 ELSE isnull(camps.CampType,0) END as OutboundType,
							ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
							a.ToolsTransfer         
							FROM ccCamps camps
							LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
							LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
							LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
							WHERE camps.cam_id = @Id
							ORDER BY camps.cam_descripcion ASC;
						END;
						ELSE BEGIN
							RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
						END;
					END;
					ELSE IF @CampType = 0 -- Campaigns In (ACD)
						BEGIN
							IF @Id IS NOT NULL
								BEGIN
									SELECT DISTINCT 
									CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, 
									ISNULL(a.AreaName, '''') AS Area, 
											CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType,
											a.ToolsTransfer
									FROM ccInbound inb
											LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
											LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
									WHERE inb.Inbound_id = @Id
											ORDER BY inb.descripcion ASC;
							END;
							ELSE
								BEGIN
									RAISERROR(''ERROR. No existe campañas de entrada con el id especificado'', 18, 1);
							END;
					END;
					RETURN 0;
				END;
				ELSE IF @Option = 3  BEGIN -- Update OverallTotalNew By Campaign

					IF @Id IS NOT NULL BEGIN
						UPDATE ccCampsNvosCB SET  OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id;
					END;
					ELSE BEGIN
						RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
					END;
					RETURN 0;
				END;
				ELSE IF @Option = 4 -- Update Pin from Campaign per Admin
				BEGIN
					IF @Id IS NOT NULL
						AND @AdminId IS NOT NULL
					BEGIN
						IF @PinUpdate = 1
						BEGIN
							INSERT INTO PinedCampaigns (CampId, AdminId, Type)
							VALUES (@Id, @AdminId, @Type);
						END;

						IF @PinUpdate = 0
						BEGIN
							DELETE
							FROM PinedCampaigns
							WHERE CampId = @Id
								AND AdminId = @AdminId
								AND Type = @Type;
						END;
					END;
					ELSE
					BEGIN
						RAISERROR (''ERROR. La campañas o administrador no existen'', 18, 1
								);
					END;

					RETURN 0;
				END;

				ELSE IF @Option = 5 BEGIN  -- Get Pin from Campaign Ids per Admin       
					IF @AdminId IS NOT NULL BEGIN
						SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
						ORDER BY Id ASC;
					END;
					ELSE BEGIN
						RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
					END;
					RETURN 0;
				END;
				ELSE IF @Option = 6 -- Get Blacklist Ids by Campaign Id
				BEGIN
					IF @Id IS NOT NULL
					BEGIN
						DECLARE @BlackListIds VARCHAR(MAX);

						SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR
									(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
						FROM Camplistanegra
						WHERE cam_id = @Id
							AND STATUS = 1;

						SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
					END;
					ELSE
					BEGIN
						RAISERROR (''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
					END;

					RETURN 0;
				END;
            
				ELSE IF @Option = 7 -- Get RegistryListIds Ids by Campaign Id
				BEGIN
					IF (
							@Id IS NOT NULL
							AND EXISTS (
								SELECT *
								FROM cccamps
								WHERE cam_id = @Id
								)
							)
					BEGIN
						SELECT TOP 1 list_id
						FROM ccRIARegistryLists
						WHERE cam_id = @Id
							AND STATUS = 2
						ORDER BY list_id DESC;
					END;
					ELSE
					BEGIN
						--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
						RAISERROR (''ERROR. No existe una campaña con el id especificado'', 18, 1);
					END;

					RETURN 0;
				END;

				ELSE IF @Option = 8 -- Delete RegistryListIds Ids by LoadId
				BEGIN
					IF (
							@LoadId IS NOT NULL
							AND EXISTS (
								SELECT *
								FROM ccRIARegistryLists
								WHERE list_id = @loadID
									AND STATUS <> 0
								)
							)
					BEGIN
						UPDATE ccoCallsOutSource
						SET cal_status = ''5''
						WHERE list_id = @loadID;

						DELETE
						FROM ccoWorkingTable
						WHERE list_id = @LoadId;

						EXEC ccsp_RIARegistryLists @action = 6, @list_id = @LoadId;
					END;
					ELSE
					BEGIN
						--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
						RAISERROR (''ERROR. No existe una carga el id especificado'', 18, 1);
					END;

					RETURN 0;
				END;

				ELSE IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
				BEGIN
					DECLARE @table TABLE (camId INT, campType TINYINT, PRIMARY KEY (camId, campType)
						);

					INSERT INTO @table
					SELECT DISTINCT IdCampEsp, Tipo
					FROM ccRIACampEspWG wg
					WHERE wg.IDWG IN (
							SELECT IDWG
							FROM ccRIAWorkGroupUsers
							WHERE IDWG <> @WorkgroupId
								AND User_id = @AdminId
							);

					SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
					FROM @table A
					RIGHT JOIN (
						SELECT wg.IdCampEsp, wg.Tipo
						FROM ccRIACampEspWG wg
						WHERE wg.IDWG = @WorkgroupId
						) B ON A.camId = B.IdCampEsp
						AND A.campType = B.Tipo
					WHERE A.camId IS NULL
					ORDER BY IdCampEsp;

					RETURN 0;
				END;

				ELSE IF @option = 10 BEGIN -- Get Agents States with totals per campaign by admin id and campaign type **********************
					DECLARE @date DATETIME = CONVERT(DATE, DATEADD(hh, - 3, GETDATE()));
					DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY (id));
					DECLARE @AgentsList TABLE (id INT, PRIMARY KEY (id));
					DECLARE @tmpCamAgent TABLE (
						camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY (camId, userId
							)  
						);
					DECLARE @AgentStatus TABLE (CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT
						);
					DECLARE @CurrentStatus TABLE (userId INT, CurrentState INT, IdCampEsp INT, camType INT
						);
					DECLARE @campDataTotal TABLE (
						camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY (camId
							)
						);

					INSERT INTO @AdminWorkgroups
					SELECT DISTINCT IDWG
					FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
					WHERE WG.User_id = @AdminId 
						OR (
							R.User_id = @AdminId
							AND R.Rol_id = 7
							);

					INSERT INTO @AgentsList
					SELECT DISTINCT A.User_id
					FROM ccRIAWorkGroupUsers A
					INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
					INNER JOIN ccUsers C ON A.User_id = C.User_id
						AND C.TipoUser_id = 1
					ORDER BY A.User_id;

					IF @IsWhatsAppCampaign  = 1
					BEGIN
						INSERT INTO @tmpCamAgent --Obtiene las relaciones entre agentes y campañas
						SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
									AND @CampType = 0 THEN inbound.chat ELSE NULL END
						FROM ccRIACampEspWG campPerWg
						INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
						INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
						INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
						LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
							AND @CampType = 0
						LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
							AND @CampType = 1
						WHERE C.TipoUser_id = 1  
							AND (camps.CampType = 5 or inbound.chat = 5)
							AND campPerWg.Tipo = @CampType
							AND (
								@Id = 0
								OR campPerWg.IdCampEsp = @Id
								);
					END
					ELSE
					BEGIN
						INSERT INTO @tmpCamAgent
						SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
									AND @CampType = 0 THEN inbound.chat ELSE NULL END
						FROM ccRIACampEspWG campPerWg
						INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
						INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
						INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
						LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
							AND @CampType = 0
						LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
							AND @CampType = 1
						WHERE C.TipoUser_id = 1
							AND campPerWg.Tipo = @CampType
							AND (
								@Id = 0
								OR campPerWg.IdCampEsp = @Id
								);
					END;

					WITH lastState
					AS (
						SELECT A.user_id, MAX(A.fecha) AS fecha
						FROM ccLogAgentesDiaViewLast A
						INNER JOIN @AgentsList B ON A.User_id = B.id
						WHERE fecha >= @date
						GROUP BY user_id
						)
					INSERT INTO @CurrentStatus
					SELECT B.User_id, CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS 
						currentStatus, B.IdCampEsp, B.Tipo
					FROM lastState A
					INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
						AND A.fecha = B.fecha;

					IF @Id = 0
						AND @CampType = 0
					BEGIN
						DELETE
						FROM @tmpCamAgent
						WHERE multimediaType = 0
					END

					DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;

					IF @CampType = 1
					BEGIN
						SELECT @MultimediaType = meanContactTypeId
						FROM contactMeanOut
						WHERE camp_id = @Id
					END
					ELSE
					BEGIN
						SELECT @chatType = ci.chat
						FROM dbo.ccInbound AS ci
						WHERE ci.Inbound_id = @Id;

						SELECT @MultimediaType = meanContactTypeId
						FROM contactMeanIn
						WHERE inboundId = @Id
					END

					IF (@chatType = 1)
					BEGIN
						SET @MultimediaType = 1
					END

					DECLARE @StateIds VARCHAR(100) = (
							SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN 
											''23'' ELSE ''4,5,6,9'' END
							) -- Add more for multimediaTypes

					;with stateDialog as(
					SELECT cast(value as int) as CurrentState FROM dbo.fn_RIASplitDelimited(@StateIds,'','')
				)
					INSERT INTO @AgentStatus
					SELECT A.camId, A.userId, B.CurrentState,
					(CASE
						WHEN @chatType = 1 THEN
							CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) THEN 1 ELSE 0 END
						ELSE
							CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN 1 ELSE 0
						END
					END) AS isCampDialog, B.camType

					FROM @tmpCamAgent A
					INNER JOIN @CurrentStatus B ON A.userId = B.userId
					WHERE (
							@Id = 0
							OR A.camId = @Id
							)

					IF @CampType = 1
					BEGIN
							;

						WITH campDataTotal
						AS (
							SELECT camId, count(*) total
							FROM @tmpCamAgent A
							GROUP BY camId
							)
						INSERT INTO @campDataTotal
						SELECT A.camId, B.cam_descripcion AS campName, A.Total, C.AreaName AS Area
						FROM campDataTotal A
						INNER JOIN ccCamps B ON A.camId = B.cam_id
						INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
					END
					ELSE
					BEGIN
							;

						WITH campDataTotal
						AS (
							SELECT camId, count(*) total
							FROM @tmpCamAgent A
							GROUP BY camId
							)
						INSERT INTO @campDataTotal
						SELECT A.camId, B.descripcion AS campName, A.Total, C.AreaName AS Area
						FROM campDataTotal A
						INNER JOIN ccInbound B ON A.camId = B.Inbound_id
						INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
					END;

					WITH stateCamp
					AS (
						SELECT A.CampId, count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready, 
							count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34, 37
											) THEN 1 WHEN A.CurrentState IN (6, 4
											)
										AND (
											A.CampId != C.IdCampEsp
											OR A.campType != @CampType
											) THEN 1 ELSE NULL END) AS notReady,
											COUNT(CASE WHEN A.isCampDialog = 1 OR A.CurrentState = 34 THEN 1 ELSE NULL END) AS dialog, 
											COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected,
					COUNT(CASE WHEN A.CurrentState = 37 THEN 1 ELSE NULL END) AS auxiliaryReady
						FROM @AgentStatus A
						INNER JOIN @CurrentStatus C ON A.userId = C.userId
						GROUP BY A.CampId
						)
					SELECT A.camId, A.campName, A.Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady, 
							0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL 
								THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady - B.auxiliaryReady END 
						Disconnected, ISNULL(B.auxiliaryReady, 0) AS AuxiliaryReady,A.Area
					FROM @campDataTotal A
					LEFT JOIN stateCamp B ON A.camId = B.CampId
					ORDER BY A.campName

					RETURN 0;
				END; -- *****************************************************************************************
				ELSE IF @Option = 11 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
					IF NOT EXISTS (
							SELECT *
							FROM ccUsers_Roles WITH (NOLOCK)
							WHERE User_id = @AdminId
								AND Rol_id = 7
							)
					BEGIN
						--print ''xxxx SIn Super''
							;

						WITH wgId
						AS (
							SELECT IDWG
							FROM ccRIAWorkGroupUsers WITH (NOLOCK)
							WHERE user_id = @AdminId
							)
						SELECT DISTINCT CAST(IdCampEsp AS INT) AS Id
						INTO #tempIds
						FROM ccRIACampEspWG A WITH (NOLOCK)
						INNER JOIN wgId ON wgId.IDWG = A.IDWG
							AND A.Tipo = @CampType;
	
						IF(@CampType = 1)
						BEGIN
							SELECT Id FROM #tempIds ids
							INNER JOIN ccCamps c on c.cam_id = ids.Id
							WHERE (c.CampType = 5 AND @IsWhatsAppCampaign = 1) 
							OR (c.CampType <> 5 AND @IsWhatsAppCampaign = 0)
						END
						ELSE
						BEGIN
							SELECT Id FROM #tempIds ids
							INNER JOIN ccInbound c on c.Inbound_id = ids.Id
							WHERE (c.chat = 5 AND @IsWhatsAppCampaign = 1) 
							OR (c.chat <> 5 AND @IsWhatsAppCampaign = 0)
						END
						DROP TABLE #tempIds
					END;
					ELSE
					BEGIN
						--print ''xxxx Super''
						IF @CampType = 1
						BEGIN
							SELECT DISTINCT CAST(cam_id AS INT) AS Id
							FROM ccCamps WITH (NOLOCK)
							WHERE IDArea IS NOT NULL
							AND(CampType = 5 AND @IsWhatsAppCampaign = 1) 
							OR (CampType <> 5 AND @IsWhatsAppCampaign = 0)
						END
						ELSE
						BEGIN
							SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
							FROM ccInbound WITH (NOLOCK)
							WHERE IDArea IS NOT NULL
							AND (chat = 5 AND @IsWhatsAppCampaign = 1) 
							OR (chat <> 5 AND @IsWhatsAppCampaign = 0)
						END
					END;

					RETURN 0;
				END;

				ELSE IF @Option = 12 BEGIN-- Get All Campaigns complete information per Campaign Type and Campaign Id
					IF @CampType = 1 -- Campaigns Out
					BEGIN
									SELECT DISTINCT 
									CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
									isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
									camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
									CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, 
									CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 ELSE isnull(camps.CampType,0) END as OutboundType,
									ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
						FROM ccCamps camps(NOLOCK)
						INNER JOIN ccRIACampsGraph graph(NOLOCK) ON camps.cam_id = graph.cam_id
						INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = camps.IDArea
						LEFT JOIN ccCampsExtend extended(NOLOCK) ON camps.cam_id = extended.cam_id
						ORDER BY camps.cam_descripcion ASC;
					END;
					ELSE
					BEGIN
						SELECT DISTINCT CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, isnull
							(CAST(graph.graphic_id AS INT), 1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(
								inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea AS INT) AS 
							AreaId, inb.chat AS InboundType, 0 AS OutboundType
						FROM ccInbound inb(NOLOCK)
											INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
						INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = inb.IDArea
						ORDER BY inb.descripcion ASC;
					END;

					RETURN 0;
				END;

				ELSE IF @Option = 13
				BEGIN
					BEGIN
						IF NOT EXISTS (
								SELECT *
								FROM ccUsers_Roles NOLOCK
								WHERE User_id = @AdminId
									AND Rol_id = 7
								)
						BEGIN
							IF @CampType = 1
							BEGIN
								WITH wgId
								AS (
									SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
													WHERE user_id = @AdminId)
												SELECT DISTINCT 
													CAST(IdCampEsp AS INT) AS CampId,
													cam_descripcion AS Description,
													isnull(IDArea, -1) AS AreaID,
													CAST(-1 AS SMALLINT) AS CampaignType,
													CAST(-1 AS INT) AS RelatedCampId,
													CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
													CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
													CAST(1 AS INT) As CampType
								FROM ccRIACampEspWG A
								INNER JOIN wgId ON wgId.IDWG = A.IDWG
									AND A.Tipo = 1
													INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id
													LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
							END
							ELSE
							BEGIN
								WITH wgId
								AS (
									SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
													WHERE user_id = @AdminId)
												SELECT DISTINCT 
													CAST(IdCampEsp AS INT) AS CampId,
													descripcion AS Description,
													isnull(IDArea, -1) AS AreaID,
													CAST(chat AS SMALLINT) AS CampaignType,
													CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
													CAST(chat AS INT) AS Channel,
													CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
													CAST(0 AS INT) As CampType
								FROM ccRIACampEspWG A(NOLOCK)
								INNER JOIN wgId ON wgId.IDWG = A.IDWG
									AND A.Tipo = 0
								INNER JOIN ccInbound cci(NOLOCK) ON A.IdCampEsp = cci.Inbound_id
													LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
													LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
													AND ((@multi_type is null AND cci.chat = @InboundType)
														OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
							END
						END;
						ELSE
						BEGIN
							IF @CampType = 1
							BEGIN
										SELECT DISTINCT 
												CAST(ccc.cam_id AS INT) AS CampId,
												cam_descripcion AS Description,
												isnull(IDArea, -1) AS AreaID,
												CAST(-1 AS SMALLINT) AS CampaignType,
												-1 AS RelatedCampId,
												CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
												CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
												CAST(1 AS INT) As CampType
										FROM ccCamps AS ccc (NOLOCK) 
											LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
										where IDArea = @AreaId
							END
							ELSE
							BEGIN
										SELECT DISTINCT 
												CAST(cci.Inbound_id AS INT) AS CampId,
												descripcion AS Description,
												isnull(IDArea, -1) AS AreaID,
												CAST(chat AS SMALLINT) AS CampaignType,
												CAST(chat AS INT) AS Channel,
												CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
												CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
												CAST(0 AS INT) As CampType
								FROM ccInbound cci(NOLOCK)
											LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
											LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
										where IDArea = @AreaId
										AND ((@multi_type is null AND cci.chat = @InboundType)
											OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

							END
						END;

						RETURN 0;
					END;
				END;
				ELSE IF @Option = 14
				BEGIN
					IF NOT EXISTS (
							SELECT *
							FROM ccUsers_Roles NOLOCK
							WHERE User_id = @AdminId
								AND Rol_id = 7
							)
					BEGIN
						WITH wgId
						AS (
							SELECT IDWG
							FROM ccRIAWorkGroupUsers NOLOCK
												WHERE user_id = @AdminId)
											SELECT DISTINCT 
												CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
						FROM ccRIACampEspWG A(NOLOCK)
						INNER JOIN wgId ON wgId.IDWG = A.IDWG
							AND A.Tipo = 0
												INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND isnull(cci.cam_id,-1) = -1
												AND ((@multi_type is null AND cci.chat = @InboundType)
													OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

					END
					ELSE
					BEGIN
									SELECT DISTINCT 
									CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
									FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND isnull(cam_id,-1) = -1
									AND ((@multi_type is null AND cci.chat = @InboundType)
										OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

					END
				END

				ELSE IF @Option = 15
				BEGIN
							SELECT DISTINCT 
							CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
							FROM ccInbound NOLOCK where cam_id = @Id
				END
				ELSE IF  @Option=16
				begin
					DECLARE @from DATETIME = CAST(GETDATE() AS DATE);
					DECLARE @to DATETIME = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, @from));
					select @AreaId = IDArea from ccUsers where User_id = @Id
					declare @camps table (cam_id int)
					insert @camps	select cam_id  FROM  dbo.fGet_CampAcd_Area(@Id,5) group by cam_id
					if((select SUM(cam_id) from @camps) IS NULL)
						begin
							select '''' as CampName
							,0 as Conversations
							,0 as Assign
							,0 as OnQueu
							,0 AS FinishedBySystem
							,0 AS FinishedByAgent
							,'''' as AreaName
							,0 as IsAssignedCamps
						end
					else
						begin
							;with camDesc as(
							select 
							c.cam_id as cam_id
							,cam_descripcion as cam_desc
							,area.AreaName
							from ccCamps c with (nolock)
							inner join @camps id on c.cam_id = id.cam_id
							inner join ccRIACat_Areas area on area.IDArea = c.IDArea
							group by area.AreaName, c.cam_id, c.cam_descripcion
							)
							,
							currentConversationWa as (
							select conversationId, camId, assignDate, onQueue,finishedBy
							,case when conversationStatus = 2 then 1 else 0 end as assigned
							from ccWhatsAppConversationsOut with (nolock)
							where assignDate >= @from and assignDate <= @to
							)
							select 
							b.cam_desc as CampName
							,COALESCE(COUNT(ccw.conversationId), 0) AS Conversations
							,COALESCE(SUM(ccw.assigned), 0) AS Assign
							,COALESCE(count(ccw.onQueue),0) as OnQueu
							,SUM(CASE WHEN ccw.finishedBy = 1 THEN 1 ELSE 0 END) AS FinishedBySystem
							,SUM(CASE WHEN ccw.finishedBy = 2 THEN 1 ELSE 0 END) AS FinishedByAgent
							,b.AreaName as AreaName
							,1 as IsAssignedCamps
							from camDesc b
							left join currentConversationWa ccw on ccw.camId = b.cam_id
							group by b.cam_id, b.cam_desc, b.AreaName
						end
					end

				END;
        '
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
