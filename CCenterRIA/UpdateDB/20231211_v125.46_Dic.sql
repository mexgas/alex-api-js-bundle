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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 46
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

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

	    -----------------------------------------------------BEGIN K042023-Indicador de creditos Ivan Martin ----------------------------------------------------------------

        SET @process = 'K042023 Se crea setting 258 para creditos globales de SMS'
        SET @sql = 'IF NOT EXISTS(SELECT * FROM ccSettings2 WHERE setting_id = 258)
                    BEGIN
                        INSERT INTO ccSettings2(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
                        VALUES(258, ''0'', ''Contador global de créditos para campañas SMS'', 1, ''ADM'', ''Contador global de créditos para campañas SMS'',
                                         ''SMS Campaigns credits global counter'',0,''.*'') 
                    END'
        EXEC(@sql);

        SET @process = 'K042023 Se agrega action 10 para apagar campañas cuando ya no hay creditos, se agrega en action 7 la actualizacion de creditos cuando el mensaje es enviado correctamente'
        SET @sql = 'ALTER procedure [dbo].[ccspOutboundSmsMessage] 
                        @action int,
                        @camId int = null,
                        @SentMsg int=null,
                        @smsoutIds varchar(max)=null,
                        @SystemApiId varchar(100)=null,
                        @statusSystemsId int =null,
                        @InsufficientBalance int=null,
                        @date datetime =null,
                        @IsCharged BIT = null
                        as
                        declare @sql varchar(max)
                        if @action=1 begin
                            select cast(cam_id as int) as CamId,cam_descripcion as [Name],cam_procesando as [Start] 
                            from ccCamps where CampType=7 and IDArea is not null and( @camId is null or cam_id=@camId)
                        end
                        else if @action=2 begin
                            select tz_offset from ccTimeZones ORDER BY tz_id
                        end
                        else if @action=3 begin
                            select cast(camId as int) CamId,SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected 
                            from ccSmsConversationsResult where ( @camId is null or camId=@camId)
                        end
                        else if @action=4 begin
                            truncate table ccSmsConversationsResult
                        end
                        else if @action=5 begin
                            if not exists(select * from ccSmsConversationsResult where camId=@camId) begin
                                insert into ccSmsConversationsResult values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance)
                            end
                            else begin
                                update ccSmsConversationsResult set SentMsg=SentMsg+@SentMsg 
                                ,InsufficientBalance=InsufficientBalance+@InsufficientBalance
                                where camId=@camId
                            end
                        end
                        else if @action=6 begin 
                            set @sql=''declare @listCamId table(camId int,status bit)

                        declare @camId int
                        insert into @listCamId
                        select distinct cam_id,0 from smsWorkingTable with(nolock) where smsout_id in(''+@smsoutIds+'')

                        while exists(select * from @listCamId where status=0)begin
                            select top 1 @camId=CamId from @listCamId where status=0
                            
                            exec ccsp_GalateaGetCampsNvosCB @cam_id=@camId,@Tipo=2,@regval=1
                            update @listCamId set status=1 where status=0 and @camId=CamId 
                        end
                        delete from smsWorkingTable where smsout_id in(''+@smsoutIds+'')
                            ''
                            exec (@sql)
                        end
                        else if @action=7 begin

                            IF @IsCharged = 1
                            BEGIN
                                DECLARE @CurrentCredit INT = (SELECT CAST(valor AS INT) FROM ccSettings2 WHERE setting_id = 258);
            
                                IF @CurrentCredit != 0
                                BEGIN
                                    SET @CurrentCredit = @CurrentCredit - 1;
                                    UPDATE ccSettings2 SET valor = @CurrentCredit WHERE setting_id = 258;
                                END
                            END

                            declare @statusSystemsIdOld int
                            declare @ccSmsConversationsResult table(camId int,statusSystemsId int,description varchar(255), value int)
                            select top(1) @camId =cam_id,@statusSystemsIdOld=statusSystemsId from smsccoLogDial with(nolock) where SystemApiId=@SystemApiId
                            update smsccoLogDial set statusSystemsId=@statusSystemsId where SystemApiId=@SystemApiId
                            
                            insert into @ccSmsConversationsResult
                            select camId, ROW_NUMBER() OVER(ORDER BY camId ASC)-1 AS statusSystemsId, description,value
                            from ccSmsConversationsResult
                            unpivot
                            (
                                value
                                for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,InsufficientBalance)
                            ) unpiv
                            where camId= @camId

                            update @ccSmsConversationsResult set value =case when value>0 then value-1 else 0 end where statusSystemsId=@statusSystemsIdOld
                            update @ccSmsConversationsResult set value =value+1 where statusSystemsId=@statusSystemsId
                            
                            ;with res as(
                            select * from 
                            (
                                select camId, description, value
                                from @ccSmsConversationsResult 
                            ) src
                            pivot
                            (
                            sum(value)
                            for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,InsufficientBalance)
                            ) piv
                            )

                            update B 
                            set B.SentMsg=A.SentMsg
                            ,B.Delivered=A.Delivered
                            ,B.NotDelivered=A.NotDelivered
                            ,B.RecipientRejected=A.RecipientRejected
                            ,B.CarrierRejected=A.CarrierRejected
                            ,B.InsufficientBalance=A.InsufficientBalance
                            from
                            res A
                            inner join ccSmsConversationsResult B on A.camId=B.camId
                        end
                        else if @action=8 begin
                            update smsccoLogDial set Bill=0.70 where smsDate>=@date and statusSystemsId not in(4,5)
                        end
                        else if @action=9 begin
                            CREATE TABLE #TempSmsOutIds (
                            smsout_id INT
                            );

                            INSERT INTO #TempSmsOutIds (smsout_id)
                            SELECT DISTINCT wt.smsout_id
                            FROM smsWorkingTable wt
                            JOIN smsOutSource os ON wt.smsout_id = os.smsout_id
                            LEFT JOIN smsccoLogDial cco ON wt.smsout_id = cco.smsout_id
                            WHERE wt.sms_status IN(1,2) 
                            AND cco.smsout_id IS NULL;

                            UPDATE wt
                            SET wt.sms_status = 0
                            FROM smsWorkingTable wt
                            JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

                            DROP TABLE #TempSmsOutIds;
                        end

                        else if @action=10 begin
                            IF(SELECT COUNT(*) FROM smsWorkingTable WHERE cam_id = @camId) = 0
                            BEGIN
                                UPDATE ccCamps SET cam_procesando = 0 WHERE cam_id = @camId
                                SELECT CAST(0 AS BIT) 
                            END
                            SELECT CAST(1 AS BIT) -- Has unsent messages 
                        end'
        EXEC(@sql);

        -----------------------------------------------------END K042023-Indicador de creditos Ivan Martin ----------------------------------------------------------------


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
