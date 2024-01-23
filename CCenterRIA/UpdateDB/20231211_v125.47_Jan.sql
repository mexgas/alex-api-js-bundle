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
SET @versionfix = 47
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

	    -----------------------------------------------------BEGIN TT7955 Uriel Cabrera ----------------------------------------------------------------

        SET @process = 'TT7955 Se elimina si existe ccsp_GalateaGetAgentsRelations'
        SET @sql = 'if exists (select * from master.sys.databases where name = N''ccsp_GalateaGetAgentsRelations'')
				    begin
				        DROP PROCEDURE ccsp_GalateaGetAgentsRelations; 
				    end'
        EXEC(@sql);
		
		SET @process = 'TT7955 Se crea prcedimeinto para relaciones de campañas agente en GalateaAgent'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetAgentsRelations] @Option AS SMALLINT,
					@Type AS SMALLINT = 0
					AS
					BEGIN
						SET NOCOUNT ON;
						IF @Option = 1 BEGIN
							IF @Type = 2 BEGIN
								SELECT distinct C.cam_id, C.cam_descripcion, prioridad, A.Login, A.User_id, skill 
								FROM ccCamps C JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id 
								JOIN ccUsers A  ON A.User_id = CA.User_id AND A.TipoUser_id=1 AND A.Status = 1 AND cam_activo=1 and A.IDArea = C.IDArea and cam_bNew = 2
								ORDER BY C.cam_id, CA.prioridad
							END
							ELSE BEGIN
								SELECT distinct C.cam_id, C.cam_descripcion, prioridad, A.Login, A.User_id, skill 
								FROM ccCamps C JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id 
								JOIN ccUsers A  ON A.User_id = CA.User_id AND A.TipoUser_id=1 AND A.Status = 1 AND cam_activo=1 and A.IDArea = C.IDArea
								ORDER BY C.cam_id, CA.prioridad
							END
						END
						ELSE IF @Option = 2 BEGIN
							SELECT distinct I.Inbound_id, I.descripcion, prioridad, A.Login, A.User_id, skill
							FROM ccInboundAgentes G JOIN ccInbound I ON G.Inbound_id = I.Inbound_id
							JOIN ccUsers A  ON A.user_id = G.user_id AND A.Status = 1 AND I.IDArea = A.IDArea
							ORDER BY I.Inbound_id, Prioridad
						END
					END
					'
        EXEC(@sql);

        -----------------------------------------------------END TT7955 Uriel Cabrera ----------------------------------------------------------------

        	    ----------------------------------------------------- BEGIN Hotfix SMS Ivan Martin ----------------------------------------------------------------

        SET @process = 'Hotfix SMS - Create new table for messages without a status update'
        SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''UnchangedStatusSmsMessages'')
					BEGIN
					    CREATE TABLE UnchangedStatusSmsMessages (
					        SystemApiId VARCHAR(100) NOT NULL,
					        StatusSystemsId INT NOT NULL
					    );
					END;'
        EXEC(@sql);

        SET @process = 'Hotfix SMS - Create new table for messages without a status update'
        SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_smsccoLogDial_'' and object_id = OBJECT_ID(N''smsccoLogDial''))
				    begin
				        CREATE INDEX IX_smsccoLogDial_ 2 ON smsccoLogDial(smsDate,statusSystemsId);
				    end'
        EXEC(@sql);

        SET @process = 'Hotfix SMS - Addition of actions 13 and 14 to update sms status when they are not updated correctly'
        SET @sql = 'ALTER procedure [dbo].[ccspOutboundSmsMessage] 
                        @action int,
                        @camId int = null,
                        @SentMsg int=null,
                        @smsoutIds varchar(max)=null,
                        @SystemApiId varchar(100)=null,
                        @statusSystemsId int =null,
                        @InsufficientBalance int=null,
                        @date datetime =null,
                        @IsCharged BIT = null,
                        @smsOutId INT = NULL,
						@TotalMessages INT = NULL
                        as
                        declare @sql varchar(max)
                        if @action=1 begin
                            select distinct cast(c. cam_id as int) as CamId,cam_descripcion as [Name],cam_procesando as [Start] 
                            from ccCamps c with(nolock)
                            left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
                            where CampType=7 and c.IDArea is not null and( @camId is null or c.cam_id=@camId) and w.new >0
    
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
                            if not exists(select 1 from ccSmsConversationsResult where camId=@camId) begin
                                insert into ccSmsConversationsResult values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance,0)
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

                        while exists(select 1 from @listCamId where status=0)begin
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
                                UPDATE ccSettings2 WITH(TABLOCK) SET valor = valor - 1 WHERE setting_id = 258 AND valor > 0;
                            END

                            declare @statusSystemsIdOld int
                            declare @ccSmsConversationsResult table(camId int,statusSystemsId int,description varchar(255), value int)
                            select top(1) @camId =cam_id,@statusSystemsIdOld=statusSystemsId, @smsOutId=smsout_id from smsccoLogDial with(nolock) where SystemApiId=@SystemApiId
                            update smsccoLogDial set statusSystemsId=@statusSystemsId where SystemApiId=@SystemApiId
                            
							IF @camId IS NULL BEGIN
								INSERT INTO UnchangedStatusSmsMessages (SystemApiId, StatusSystemsId) VALUES (@SystemApiId, @statusSystemsId)
							END

                            insert into @ccSmsConversationsResult
                            select camId, ROW_NUMBER() OVER(ORDER BY camId ASC)-1 AS statusSystemsId, description,value
                            from ccSmsConversationsResult
                            unpivot
                            (
                                value
                                for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected, Exception, InsufficientBalance)
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
                            for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected, Exception, InsufficientBalance)
                            ) piv
                            )

                            update B 
                            set B.SentMsg=A.SentMsg
                            ,B.Delivered=A.Delivered
                            ,B.NotDelivered=A.NotDelivered
                            ,B.RecipientRejected=A.RecipientRejected
                            ,B.CarrierRejected=A.CarrierRejected
                            ,B.Exception=A.Exception
                            ,B.InsufficientBalance=A.InsufficientBalance
                            from
                            res A
                            inner join ccSmsConversationsResult B on A.camId=B.camId

                            exec ccspOutboundSmsMessage @action = 11, @smsOutId=@smsOutId
                        end
                        else if @action=8 begin
                            update smsccoLogDial set Bill=0.70 where smsDate>=@date and statusSystemsId not in(3,4,5,6)
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
                            AND wt.cam_id = @camId;

                            UPDATE wt
                            SET wt.sms_status = 0, sms_dateDial = DATEADD(mi,30,GETDATE())
                            FROM smsWorkingTable wt
                            JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

                            DROP TABLE #TempSmsOutIds;
                        end

                        else if @action=10 begin
                            IF NOT EXISTS(SELECT 1 FROM smsWorkingTable WHERE cam_id = @camId) BEGIN
                                UPDATE ccCamps SET cam_procesando = 0 WHERE cam_id = @camId
                                SELECT CAST(0 AS BIT) 
                            END
                            ELSE BEGIN
                                SELECT CAST(1 AS BIT) -- Has unsent messages 
                            END
                        end

                        else if @action=11 begin
                            UPDATE wt
                            SET sms_status = 0, sms_dateDial = DATEADD(mi,30,GETDATE())
                            FROM smsWorkingTable wt with (rowlock) WHERE smsout_id = @smsOutId;
                        end
                        else if @action=12 begin
                            if exists(select 1 from ccSmsSchedules with(nolock) where cam_id = @camId and getdate() between iDate and fDate)
                            begin
                                if exists(select 1 from smsWorkingTable with(nolock) where cam_id = @camId)
                                begin
                                    select cast(1 as bit)
                                    return
                                end
                            end
                            select cast(0 as bit)
                            update ccCamps set cam_procesando=0 where cam_id=@camId
                        end

						else if @action=13 begin
							SELECT cam_id AS CampaingId, U.statusSystemsId AS StatusSystemsId, COUNT(*) AS TotalMessages
							FROM smsccoLogDial S
							INNER JOIN UnchangedStatusSmsMessages U ON S.SystemApiId = U.SystemApiId
							GROUP BY S.cam_id, U.statusSystemsId
                        end

						else if @action=14 begin
							
							DECLARE @TemporalUnchangedStatusSmsMessages TABLE (SystemApiId VARCHAR(100), StatusSystemsId INT, StatusSystemsIdOld INT)
							INSERT INTO @TemporalUnchangedStatusSmsMessages
								SELECT U.SystemApiId, U.statusSystemsId, S.statusSystemsId
								FROM UnchangedStatusSmsMessages U  with(nolock) 
								INNER JOIN smsccoLogDial S ON S.SystemApiId = U.SystemApiId			

							------------------------Update smsccoLogDial---------------------------------------
							UPDATE S SET S.StatusSystemsId = U.StatusSystemsId
							FROM smsccoLogDial S
							INNER JOIN @TemporalUnchangedStatusSmsMessages U ON S.SystemApiId = U.SystemApiId;
						
							DECLARE @TemporalSmsConversationsResult TABLE(camId INT, statusSystemsId INT, description VARCHAR(255), value INT)
							INSERT INTO @TemporalSmsConversationsResult
							SELECT camId, ROW_NUMBER() OVER(ORDER BY camId ASC)-1 AS statusSystemsId, description, value
							FROM ccSmsConversationsResult
							UNPIVOT
							(
								value
								FOR description IN (SentMsg, Delivered, NotDelivered, RecipientRejected, CarrierRejected, Exception, InsufficientBalance)
							) AS unpiv
							WHERE camId = @camId;

							--------------------------Update ccSmsConversationsResult --------------------------
							SELECT StatusSystemsIdOld, COUNT(*) AS DecrementCount
							INTO #DecrementCounts
							FROM @TemporalUnchangedStatusSmsMessages
							GROUP BY StatusSystemsIdOld;

							SELECT StatusSystemsId, COUNT(*) AS IncrementCount
							INTO #IncrementCounts
							FROM @TemporalUnchangedStatusSmsMessages
							GROUP BY StatusSystemsId;

							UPDATE T SET T.value = CASE WHEN T.value > D.DecrementCount THEN T.value - D.DecrementCount ELSE 0 END
							FROM @TemporalSmsConversationsResult T
							INNER JOIN #DecrementCounts D ON T.statusSystemsId = D.StatusSystemsIdOld;

							UPDATE T SET T.value = T.value + I.IncrementCount
							FROM @TemporalSmsConversationsResult T
							INNER JOIN #IncrementCounts I ON T.statusSystemsId = I.StatusSystemsId;

							DROP TABLE #DecrementCounts;
							DROP TABLE #IncrementCounts;
							---Return the results to the original table
							;WITH res AS
							(
								SELECT * FROM 
								(
									SELECT camId, description, value
									FROM @TemporalSmsConversationsResult 
								) AS src
								PIVOT
								(
									SUM(value)
									FOR description IN (SentMsg, Delivered, NotDelivered, RecipientRejected, CarrierRejected, Exception, InsufficientBalance)
								) AS piv
							)

							UPDATE B 
							SET B.SentMsg = A.SentMsg,
								B.Delivered = A.Delivered,
								B.NotDelivered = A.NotDelivered,
								B.RecipientRejected = A.RecipientRejected,
								B.CarrierRejected = A.CarrierRejected,
								B.Exception = A.Exception,
								B.InsufficientBalance = A.InsufficientBalance
							FROM
								res AS A
							INNER JOIN ccSmsConversationsResult AS B ON A.camId = B.camId;
                            -- Delete updated messages
							DELETE FROM UnchangedStatusSmsMessages WHERE SystemApiId IN (SELECT SystemApiId FROM @TemporalUnchangedStatusSmsMessages);
                        END'
        EXEC(@sql);


        ----------------------------------------------------- END Hotfix SMS Ivan Martin ----------------------------------------------------------------



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
