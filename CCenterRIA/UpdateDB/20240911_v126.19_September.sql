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

        ------------------------------------------------- Empieza Leonardo Ramírez ----------------------------------------------------------------------------------
---------------------------------------------------------------- K020135  -------------------------------------------------------------------------------------------
    set @process = ''

    set @sql = '
        IF NOT EXISTS (
        SELECT 1 FROM ccSettings2 WHERE setting_id = 269
        )
            BEGIN
                INSERT INTO ccSettings2 (
                    setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate
                ) VALUES (
                    269,
                    ''0'',
                    ''Encriptar conversaciones y adjuntos de WhatsApp'',
                    1,
                    ''GRL'',
                    ''Habilita la encripción para conversaciones y adjuntos de WhatsApp'',
                    ''Encrypt WhatsApp conversations and attachments'',
                    0,
                    ''^[0-1]$''
                );
        END;
    '

    EXEC(@sql)

------------------------------------------------- Termina Leonardo Ramírez ----------------------------------------------------------------------------------


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
