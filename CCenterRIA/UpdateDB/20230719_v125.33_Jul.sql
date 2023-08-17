/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K053000

Database: CCenterRia
Required version: 125.31

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
SET @versionfix = 33
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

	---------------------------------------BEGIN Marco Garcia & Marco Chagolla K039000 Destinatario de grabaciones (envío de grabaciones en finder a correos dados de alta en el sistema)---------------------------------------------------------

SET @process = 'K039000 Destinatario de grabaciones (envío de grabaciones en finder a correos dados de alta en el sistema) update lenght  of email column in ccsp_RIA_AddressBook table'
SET @sql = 'IF exists
	(
	SELECT *
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE COLUMN_NAME = ''email'' AND TABLE_NAME = ''ccRIACat_AddressBook''
	)
	BEGIN
	  ALTER TABLE dbo.ccRIACat_AddressBook ALTER COLUMN  email VARCHAR(255)
	END'
	EXEC(@sql)



	SET @process = 'K039000 Destinatario de grabaciones (envío de grabaciones en finder a correos dados de alta en el sistema) delete store procedure ccsp_RIA_AddressBook'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIA_AddressBook'')
		BEGIN
			DROP PROCEDURE ccsp_RIA_AddressBook
		END'
EXEC(@sql)

SET @process = 'K039000 Destinatario de grabaciones (envío de grabaciones en finder a correos dados de alta en el sistema) create store procedure [ccsp_RIA_AddressBook]'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIA_AddressBook]
			@action smallint,
			@Email varchar(255) = '''',
			@Name varchar(100) = '''',
			@Organization varchar(100) = '''',
			@Department varchar(100) = '''',
			@Title varchar(100) = '''',
			@IDArea smallint = NULL,
			@IDAddr smallint = NULL,
			@IsKolob BIT = 0
			AS

			set nocount ON
            
			DECLARE @newAdressBookId SMALLINT; 

			if @action = 0 begin --Selected Address
				select addr_id,name,email,organization,department,job_title from ccRIACat_AddressBook nolock where area_id=@IDArea order by Name
				return(0)
			end
			else if @action=2 begin --Insert Address
				IF(@IsKolob = 1)
				BEGIN
					BEGIN TRY
						BEGIN TRANSACTION insertDirectory
							if exists(select addr_Id from ccRIACat_AddressBook where name = @Name)
							BEGIN
								SET @newAdressBookId = -1 -- Name in use
							END
							ELSE IF exists(select addr_Id from ccRIACat_AddressBook where email = @Email)
							BEGIN
								SET @newAdressBookId = -2 -- Email in use
							END
							ELSE
							BEGIN
								Insert into ccRIACat_AddressBook (email,name,organization,department,job_title,area_Id) values (@Email,@Name,@Organization,@Department,@Title,@IDArea)
								SET @newAdressBookId = SCOPE_IDENTITY(); 
							END
						COMMIT TRANSACTION insertDirectory
					END TRY
					BEGIN CATCH
						IF @@trancount > 0 ROLLBACK TRANSACTION insertDirectory
						SET @newAdressBookId = -500 --Internal Server  
					END CATCH

					SELECT @newAdressBookId
				END
				ELSE
				BEGIN
					Insert into ccRIACat_AddressBook (email,name,organization,department,job_title,area_Id) values (@Email,@Name,@Organization,@Department,@Title,@IDArea)
					SELECT 1, scope_identity()--, Address Inserted
				END
				return(0)
			end
			else if @action=3 begin--Update Address

				IF(@IsKolob = 1)
				BEGIN
					BEGIN TRY
						BEGIN TRANSACTION updateDirectory
							if exists(select addr_Id from ccRIACat_AddressBook where name = @Name AND addr_Id <> @IDAddr)
							BEGIN
								SET @newAdressBookId = -1 -- Name in use
							END
							ELSE IF exists(select addr_Id from ccRIACat_AddressBook where email = @Email AND addr_Id <> @IDAddr)
							BEGIN
								SET @newAdressBookId = -2 -- Email in use
							END
							ELSE
							BEGIN
								update ccRIACat_AddressBook set email=@Email,name=@Name,organization=@Organization,department=@Department,job_title=@Title where addr_id = @IDAddr
								SET @newAdressBookId = 1 --Address Book Updated successfully
							END
						COMMIT TRANSACTION updateDirectory
					END TRY
					BEGIN CATCH
						IF @@trancount > 0 ROLLBACK TRANSACTION updateDirectory
						SET @newAdressBookId = -500 --Internal Server  
					END CATCH

					SELECT @newAdressBookId
				END
				ELSE
				BEGIN
					update ccRIACat_AddressBook set email=@Email,name=@Name,organization=@Organization,department=@Department,job_title=@Title where addr_id = @IDAddr
				END
				return(0)
			end
			else if @action=4 begin --Delete Address
			IF(@IsKolob = 1)
				BEGIN
					delete ccRIACat_AddressBook where addr_id = @IDAddr
					SELECT @@ROWCOUNT AS result
				END
				ELSE BEGIN
					delete ccRIACat_AddressBook where addr_id = @IDAddr
				END
				return(0)
			end'
			EXEC(@sql)


		

	---------------------------------------END Marco Garcia & & Marco Chagolla K039000 Destinatario de grabaciones (envío de grabaciones en finder a correos dados de alta en el sistema)-----------------------------------------------------------

	/************************************************************************ Begin Union FIX 125.20230425.0.5 **************************************************************/
	SET @process = 'DEV1-335 Alter SP ccsp_DLRSaveDialResult Modificacion Se obtine el @cal_key si es null para no hacer doble update ccoLogDials'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRSaveDialResult] 
                @callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
                @tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
                @canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '''', @cal_key VARCHAR(40)= '''', @call_TS VARCHAR(15)='''',
                @ani varchar(32)=''''
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tNow AS DATETIME, @RecicleSIC TINYINT;
    DECLARE @logDial_id INT;
    DECLARE @tAnswerBitFinal AS DATETIME;
    DECLARE @tTotal SMALLINT;

    SELECT @RecicleSIC = ISNULL(valor, 0)
    FROM ccSettings
    WHERE setting_id = 60;

    SELECT @tTotal = @tDialing + @tAnswerBit;

    SELECT @tNow = GETDATE();

    SELECT @tAnswerBitFinal = DATEADD(ss, -@tAnswerBit, @tNow);


-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
IF @call_id > 0 AND @tipoResDial_id = 1 and @cal_key = ''''
    BEGIN
    SELECT @cal_key = cal_key
    FROM ccoCallsOutSource WITH(NOLOCK)
    WHERE @callout_id = callout_id;         
END;

IF @call_id > 0 AND @tipoResDial_id = 1
BEGIN
        INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
        TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani )
               SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
               ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.
               fnGetTipoLlamada( @Telefono ), @ani;
    END;
         ELSE
    BEGIN
        INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
        TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani )
               SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
               ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(
               @Telefono ), @ani;
    END;

    SELECT @logDial_id = SCOPE_IDENTITY();

    IF @RecicleSIC = 1
    BEGIN
        UPDATE ccoWorkingTable WITH(ROWLOCK)
          SET tipoResDial_id = @tipoResDial_id
        WHERE callout_id = @callout_id;
    END;

    -- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
IF @call_id > 0 AND @tipoResDial_id = 1
    BEGIN
        UPDATE ccoCallsOut WITH(ROWLOCK)
    SET cal_puerto = @Puerto, cal_manual = CASE WHEN cal_manual = 1 THEN 2 ELSE cal_manual END
    WHERE cal_id = @call_id AND cal_puerto = 0;

        EXEC ccsp_CstoCalculaCosto @call_id;
    END;

    -- inserta informacion para reportes de workgroup
    INSERT INTO ccRIAWorkGroup_logDial_id( IDWG, logDial_id, cam_id, TIMESTAMP )
           SELECT IDWG, @logDial_id, IdCampEsp, GETDATE()
           FROM ccRIACampEspWG
WHERE tipo = 1 AND IdCampEsp = @cam_id;

    -- Guarda configuracion de TipoDialingMode
    UPDATE ccoLogDials WITH(ROWLOCK)
      SET TipoDialingMode = dbo.fn_getDialingMode( @call_id, 0, @logDial_id, @cam_id )
    WHERE logDial_id = @logDial_id;
    SET NOCOUNT OFF;
END;

    SELECT @logDial_id as LogDialId'
	EXEC(@sql)

	SET @process = 'DEV1-335 Alter SP ccsp_GetAgentECRelations se agrega parametro @camId para filtrar por la campaña'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentECRelations]
@User_id smallint,@action int =0,@camId int=0
AS
set nocount on

declare @idioma as bit, @tipo as varchar(6)

if @action=0 begin
	select distinct ''Tipo''=1, E.Inbound_id, E.descripcion, A.Login, A.user_id, prioridad, skill, E.cli_id
		from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id
		join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
	union
	select distinct ''Tipo''=2, C.cam_id, C.cam_descripcion, A.Login, A.user_id, prioridad, skill, C.cli_id
		from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id
		join ccUsers A  on A.user_id = CA.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
		order by ''Tipo''
end
else begin
	select distinct 1 tipo, E.Inbound_id, E.descripcion, A.Login, A.user_id, prioridad, skill, isnull(E.cli_id,0) cli_id
	,right(''0''+cast(1 as varchar(1)),1) + right(''00000''+cast(E.Inbound_id as varchar(5)),5)
	+ right(''00''+cast(prioridad as varchar(2)),2) + right(''00''+cast(skill as varchar(2)),2) sPertenencias
		from ccInboundAgentes G 
		inner join ccInbound E on G.inbound_id = E.inbound_id
		inner join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
		and (@camId =0 or E.Inbound_id=@camId)
		union
	select distinct 2 tipo, C.cam_id, C.cam_descripcion, A.Login, A.user_id, prioridad, skill, C.cli_id
	,right(''0''+cast(2 as varchar(1)),1) + right(''00000''+cast(C.cam_id as varchar(5)),5)
	+ right(''00''+cast(prioridad as varchar(2)),2) + right(''00''+cast(skill as varchar(2)),2) sPertenencias
		from ccCamps C 
		inner join ccCampsAgente CA on C.cam_id = CA.cam_id
		inner join ccUsers A  on A.user_id = CA.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
		and (@camId =0 or C.cam_id=@camId)
		order by ''Tipo''

end'
	EXEC(@sql)

	SET @process = 'DEV1-335 Alter SP ccsp_GetAllAgentsECRelations se agrega parametro @camId para filtrar por la campaña'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAllAgentsECRelations]
@User_id varchar(max),@camId int=0
AS
set nocount on

DECLARE @userTable TABLE (Id int,userId int)
DECLARE @userIn TABLE (userId int)

insert into @userTable select * from dbo.fn_RIASplitDelimited(@User_id,''|'')

insert into @userIn
select distinct A.user_id
	from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id
	inner join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1
	inner join @userTable B on A.User_id = B.userId
	Where A.status > 0


select distinct
	case when CA.user_id is null and uIn.userId is null then 0
	when CA.user_id is null and uIn.userId is not null then 1
	when CA.user_id is not null and uIn.userId is null then 2
	else 3 end tipo,
	isnull(C.cam_id,0) as cam_id, B.user_id, isnull(prioridad,0) prioridad, isnull(skill,0) skill, isnull(C.cli_id,0) cli_id
	from @userTable A
	inner join ccUsers B  on A.userId = B.user_id and B.TipoUser_id =1
	left join ccCampsAgente CA on A.userId = CA.user_id
	left join ccCamps C  on C.cam_id = CA.cam_id
	left join @userIn uIn on uIn.userId = B.user_id
	Where B.status > 0 
	and (@camId=0 or (C.cam_id is not null and C.cam_id=@camId) )
	order by B.user_id,cam_id
'
	EXEC(@sql)

	SET @process = 'DEV1-335 Alter SP ccsp_OUTResetJobs se agrega parametro @today para buscar solo desde la ultima vez que se inicio la campaña en lugar del inicio del dia'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTResetJobs] 
@camid AS INT= 0,@today DATETIME=null
AS
BEGIN

  CREATE TABLE #TempccoLogDials ( 
    callout_id INT, PRIMARY KEY (callout_id)
  ); 

  if @today is null begin
	SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);
  end
  else begin
	SELECT @today =dateadd(hh,-1,@today)
  end

  
  IF @camid = 0
  BEGIN
    INSERT INTO #TempccoLogDials
         SELECT callout_id
         FROM ccoLogDials AS ld WITH(NOLOCK)
         WHERE fecha >= @today
         GROUP BY callout_id;
  END;
     ELSE
    IF @camid > 0
    BEGIN
      INSERT INTO #TempccoLogDials
           SELECT callout_id
           FROM ccoLogDials AS ld WITH(NOLOCK)
           WHERE cam_id = @camid AND 
             fecha >= @today			
           GROUP BY callout_id;
    END;

  -- CALLBACKS Se han marcado recientemente
  UPDATE ccoWorkingTable WITH(ROWLOCK)
    SET cal_status = 1
  FROM ccoWorkingTable wt
     INNER JOIN
     #TempccoLogDials ld
     ON wt.callout_id = ld.callout_id
  WHERE wt.cal_status = 2   

  IF @camid = 0
  BEGIN
    -- NUEVAS - Nunca se han marcado
    UPDATE ccoWorkingTable --WITH(ROWLOCK)
      SET cal_status = 0
    WHERE cal_status = 2;
  END;
     ELSE
  BEGIN  
    -- NUEVAS - Nunca se han marcado	
    UPDATE ccoWorkingTable WITH(ROWLOCK)
      SET cal_status = 0
    WHERE cal_status = 2 AND 
        cam_id = @camid;
  END;

  DROP TABLE #TempccoLogDials;
END;'
	EXEC(@sql)

-------------------------------------------BEGIN MACL CW-7990, CW-7991--------------------------------------------------
SET @process = 'CW-7990 - Se actualiza ccsp_RecycleByDispositionOrResult para que coincida el reciclaje de llamadas al reciclar por resultado de marcacion'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RecycleByDispositionOrResult]
		@Action SMALLINT = 0,
		@cam_id SMALLINT = 0,
		@result_id SMALLINT = 0,
		@disposition_id SMALLINT = 0,
		@subDisposition_id SMALLINT = 0
		AS
		BEGIN
			DECLARE @date DATE = CONVERT(VARCHAR,GETDATE(),23);
			DECLARE @count INT = 0;

			IF(@Action = 1) BEGIN --Count registers to recycle by Result
				SELECT DISTINCT COUNT(*) OVER() AS TotalRecords
				FROM ccoLogDials ld
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = ld.callout_id and cs.cam_id = ld.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE ld.fecha > @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(ld.canBeRecycled, 1) = 1
				AND NOT EXISTS (select value FROM fn_RIASplitDelimited(ISNULL(cs.recycledByResult, ''0''), '','') where value = CONVERT(VARCHAR(2), @result_id))
				AND ld.tipoResDial_id = @result_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				AND ld.cam_id = @cam_id
				GROUP BY ld.callout_id
				RETURN 0;
			END

			IF(@Action = 2) BEGIN --Count registers to recycle by Calif
				SELECT COUNT(DISTINCT co.callout_id) AS TotalRecords
				FROM ccoCallsOut co
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE co.cal_Inicio >= @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(co.canBeRecycled, 1) = 1
				AND ISNULL(recycledByDisposition, 0) = 0
				AND co.calif_id = @disposition_id
				AND ISNULL(co.califSub_id, 0) <= 0
				AND cs.cam_id = @cam_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				RETURN 0;
			END

			IF(@Action = 3) BEGIN --Count registers to recycle by CalifSub
				SELECT COUNT(DISTINCT co.callout_id) AS TotalRecords
				FROM ccoCallsOut co
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE co.cal_Inicio >= @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(co.canBeRecycled, 1) = 1
				AND ISNULL(recycledByDisposition, 0) = 0
				AND co.calif_id = @disposition_id
				AND co.califSub_id = @subDisposition_id
				AND cs.cam_id = @cam_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				RETURN 0;
			END

			IF(@Action = 4) BEGIN --Recycle registers to load by Result
				SELECT ld.callout_id, ld.Telefono, ld.fecha,
				ROW_NUMBER() OVER (PARTITION BY ld.callout_id ORDER BY ld.fecha ASC) AS RowFilter
				INTO #tmpCalloutIdResult
				FROM ccoLogDials ld
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = ld.callout_id and cs.cam_id = ld.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE ld.fecha > @date
				AND cs.cal_status not in (0,1,7)
				AND NOT EXISTS (select value FROM fn_RIASplitDelimited(ISNULL(cs.recycledByResult, ''0''), '','') where value = CONVERT(VARCHAR(2), @result_id))
				AND ISNULL(ld.canBeRecycled, 1) = 1
				AND ld.tipoResDial_id = @result_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				AND ld.cam_id = @cam_id
				GROUP BY ld.callout_id, ld.Telefono, ld.fecha

				DELETE wt
				FROM ccoWorkingTable wt
				INNER JOIN #tmpCalloutIdResult tc on wt.callout_id = tc.callout_id
				WHERE wt.cal_status = 1

				UPDATE cs SET cs.cal_status = 0, cs.recycledByResult = ISNULL(cs.recycledByResult, '''') + '','' +CONVERT(VARCHAR(2), @result_id),
				cs.recyclePhone = CASE 
					WHEN tc.Telefono = cs.cal_telefono THEN 1
					WHEN tc.Telefono = cs.cal_telefono2 THEN 2
					WHEN tc.Telefono = cs.cal_telefono3 THEN 3
					WHEN tc.Telefono = cs.cal_telefono4 THEN 4
					ELSE 5 END, 
				cs.recycleType = 0
				FROM ccoCallsOutSource cs
				INNER JOIN #tmpCalloutIdResult tc on cs.callout_id = tc.callout_id
				WHERE tc.RowFilter = 1

				UPDATE ld SET ld.canBeRecycled = 0
				FROM ccoLogDials ld
				INNER JOIN #tmpCalloutIdResult tc on ld.callout_id = tc.callout_id
				WHERE ld.fecha >= @date
				AND ld.tipoResDial_id = @result_id

				SELECT @count = COUNT(*) from #tmpCalloutIdResult

				EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp @camp_id = @cam_id, @top = @count

				DROP TABLE #tmpCalloutIdResult

				SELECT cam_descripcion FROM ccCamps where cam_id = @cam_id

				RETURN 0;
			END

			IF(@Action = 5) BEGIN --Recycle registers to load by Calif
				SELECT co.callout_id INTO #tmpCalloutId
				FROM ccoCallsOut co
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE co.cal_Inicio >= @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(co.canBeRecycled, 1) = 1
				AND ISNULL(recycledByDisposition, 0) = 0
				AND co.calif_id = @disposition_id
				AND ISNULL(co.califSub_id, 0) <= 0
				AND cs.cam_id = @cam_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				GROUP BY co.callout_id

				UPDATE cs SET cs.cal_status = 0, cs.recycledByDisposition = 1, cs.recycleType = 1
				FROM ccoCallsOutSource cs
				INNER JOIN #tmpCalloutId tc on cs.callout_id = tc.callout_id

				UPDATE co SET co.canBeRecycled = 0
				FROM ccoCallsOut co
				INNER JOIN #tmpCalloutId tc on co.callout_id = tc.callout_id
				WHERE co.cal_Inicio >= @date

				DELETE wt
				FROM ccoWorkingTable wt
				INNER JOIN #tmpCalloutId tc on wt.callout_id = tc.callout_id
				WHERE wt.cal_status = 1

				SELECT @count = COUNT(*) from #tmpCalloutId

				EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp @camp_id = @cam_id, @top = @count

				DROP TABLE #tmpCalloutId

				SELECT cam_descripcion FROM ccCamps where cam_id = @cam_id

				RETURN 0;
			END

			IF(@Action = 6) BEGIN --Recycle registers by CalifSub
				SELECT co.callout_id INTO #tmpCalloutIdSub
				FROM ccoCallsOut co
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE co.cal_Inicio >= @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(co.canBeRecycled, 1) = 1
				AND ISNULL(recycledByDisposition, 0) = 0
				AND co.calif_id = @disposition_id
				AND co.califSub_id = @subDisposition_id
				AND cs.cam_id = @cam_id
				AND(wt.callout_id IS NULL OR wt.cal_status = 1)
				GROUP BY co.callout_id

				DELETE wt
				FROM ccoWorkingTable wt
				INNER JOIN #tmpCalloutIdSub tc on wt.callout_id = tc.callout_id
				WHERE wt.cal_status = 1

				UPDATE cs SET cs.cal_status = 0, cs.recycledByDisposition = 1, cs.recycleType = 1
				FROM ccoCallsOutSource cs
				INNER JOIN #tmpCalloutIdSub tc on cs.callout_id = tc.callout_id

				UPDATE co SET co.canBeRecycled = 0
				FROM ccoCallsOut co
				INNER JOIN #tmpCalloutIdSub tc on co.callout_id = tc.callout_id
				WHERE co.cal_Inicio >= @date

				SELECT @count = COUNT(*) from #tmpCalloutIdSub

				EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp @camp_id = @cam_id, @top = @count

				DROP TABLE #tmpCalloutIdSub

				SELECT cam_descripcion FROM ccCamps where cam_id = @cam_id

				RETURN 0;
			END
		END'

EXEC (@sql)

SET @process = 'CW-7990 - Se actualiza ccsp_GalateaLoadUsersForManagement para obtener usuarios inactivos'
SET @sql ='ALTER PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
 @option SMALLINT,
 @AreaId SMALLINT,
 @UserType INT = null,
 @Username VARCHAR(200)=null,
 @userId INT = 0
as

--Obtiene el idioma de de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

IF @option = 1 --Agentes/supervisores de un Area
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
	AND DATEDIFF(dd, LastLoginAttempt, getdate()) < 60
  ORDER BY LOGIN, Nombres, ApellidoPaterno,Sexo, User_id

  RETURN (0)
END

IF @option = 2 -- obtiene Agente o supervisor en base a su nombre de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE Login=@Username

  RETURN (0)
END

IF @option = 3 -- obtiene Agente o supervisor en base a su ID de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE user_id=@userId

  RETURN (0)
END




IF @option = 4 -- supervisores en Area/Sistema
BEGIN
	DECLARE @Admins TABLE (UserId smallint, Username varchar(50), Names varchar(50), LastName varchar(50), OptionalExtraName varchar(50), AreaId smallint, primary key(UserId))
	INSERT INTO @Admins
	SELECT User_id as UserId,
	LOGIN as Username,
	Nombres as Names,
	CASE
	  WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
	  ELSE isnull(ApellidoPaterno, '''')
	END as LastName,

	CASE
	  WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
	  ELSE isnull(ApellidoMaterno, '''')
	END as OptionalExtraName,

	isnull(IDArea, 0) as AreaId
	FROM ccusers
	WHERE TipoUser_id = 2 AND STATUS = 1


	IF NOT EXISTS(SELECT * FROM ccUsers_Roles WHERE User_id=@userId and Rol_id=7) BEGIN
		SELECT UserId, Username, Names, LastName, OptionalExtraName
		FROM @Admins
		WHERE AreaId = (SELECT IDArea FROM ccUsers WHERE User_id=@userId)
		ORDER BY Username, Names, LastName, UserId
	END
	ELSE BEGIN
		SELECT UserId, Username, Names, LastName, OptionalExtraName
		FROM @Admins
		ORDER BY Username, Names, LastName, UserId
	END
	Return(0)
END

IF @option = 5 --Usuarios inactivos por mas de 60 días por área
	BEGIN
		SELECT [User_id] as UserId,
		LOGIN as Username
		FROM CCUSERS WHERE DATEDIFF(dd, LastLoginAttempt, getdate()) >= 60
		AND @AreaId = IDArea
		RETURN 0;
	END'

EXEC (@sql)

SET @process = 'CW-7990 - Se actualiza ccsp_RIA_ABCAreas para filtrar usuarios inactivos'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
@option smallint,
@IDArea smallint,
@Descripcion varchar(40),
@maxMails smallint = 3, 
@maxChats smallint = 3,
@maxTweets smallint = 3,
@defCampaing smallint = NULL, 
@isKolob bit = 0
AS

set nocount on



if @option = 1 begin --Selected Area
 Select a.IDArea, AreaName, isnull(a.maxChats,0) as maxChats, isnull(maxMails,3) maxMails,
 isnull(users,0) users, isnull(admins,0) admins,
 isnull(camps,0) camps, isnull(acds,0) acds  ,isnull(a.maxTweets,3) as maxTweets
 from ccRIACat_Areas a (nolock)
 left join (select IDArea , MAX(isnull(maxChats,0)) as maxChats from ccInbound GROUP BY IDArea) b on a.IDArea = b.IDArea
 left join (select IDArea,count(case when TipoUser_id = 1 AND (@isKolob = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= 60)  then 1 else null end) users, count(case when TipoUser_id > 1 AND (@isKolob = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= 60) then 1 else null end) admins from ccusers (nolock) where isnull(IDArea,0)=case isnull(0,0) when 0 then isnull(IDArea,0) else 0 end group by IDArea) userswg on userswg.IDArea=a.IDArea
 left join (select IDArea,count(*) acds from ccinbound (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) acdswg on acdswg.IDArea=a.IDArea
 left join (select IDArea,count(*) camps from cccamps (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) campswg on campswg.IDArea=a.IDArea
 where StatusArea=1 and isnull(a.IDArea,0)=case isnull(@IDArea,0)
 when 0 then isnull(a.IDArea,0) else @IDArea end
 order by AreaName
 return(0)
end
else if @option=2 begin --Insert Area
	 if exists(select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion) begin
	  select -1 as result,-1 as idAreas--, Nombre en Uso
	  return(0)
	 end
	Insert into ccRIACat_Areas (AreaName,maxMails,maxChats,maxTweets,defCampaing,CreateDate) values (@Descripcion,@maxMails,@maxChats,@maxTweets,@defCampaing,Getdate())
	select 1 as result, scope_identity() as idAreas--, Area Insertada
	return(0)
end
else if @option=3 begin--Update Area
	if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
		Update ccRIACat_Areas set AreaName=@Descripcion,maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,defCampaing=@defCampaing where IDArea=@IDArea
	else
		Update ccRIACat_Areas set maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,defCampaing=@defCampaing where IDArea=@IDArea

	if (select max(maxChats) as maxChats from ccinbound where IDArea=@IDArea) <> @maxChats
		Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
 return(0)
end

else if @option=4 begin --Delete Area
 if (exists(select IDArea from ccUsers where IDArea=@IDArea) or exists(select IDArea from ccCamps where IDArea = @IDArea)
  or exists(select IDArea from ccInbound where IDArea=@IDArea)) and (select valor from ccSettings where setting_id=95)<>1
 begin
  select -1
  return(0)
 end

	declare @DWorkGroups as varchar(500)

	 insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
	 select user_id,cam_id,prioridad,skill,rel_id,IDWG
	 from ccCampsAgente
	 where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
	 select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
	 from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
	 Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
	 select user_id,cam_id,tipo,IDWG,monitored
	 from ccSupervisorCam
	 where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
	 delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
	 delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
	 where cam_id in (select cam_id from ccCamps where IDArea=@IDArea))

	 Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)
	 Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)

	 Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
	 Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
	 Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)

	 select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea=@IDArea
	 Delete from ccRIAAreaWorkGroup where IDArea=@IDArea

	 if (select valor from ccSettings where setting_id=95)=1
	 begin
	  Update ccInbound set IDArea=NULL, status=0 where IDArea=@IDArea
	  Update ccCamps set IDArea=NULL where IDArea=@IDArea
	  Update ccUsers set IDArea=NULL where IDArea=@IDArea
	 end

	 Update ccRIACat_Areas set StatusArea=0 where IDArea=@IDArea

	 select @DWorkGroups

 return(0)
end
else if @option=5 begin -- Select Areas Campaings and show its default Campaing 
	select A.IDArea as IDArea, C.cam_id as campID, C.cam_descripcion as campName,
	case when A.defCampaing=C.cam_id then 1 else 0 end as isDefault
	from ccRIACat_Areas A (nolock)
	inner join ccCamps C on A.IDArea=C.IDArea
	order by IDArea asc, isDefault desc, campName
	return(0)
 end'

EXEC (@sql)

SET @process = 'CW-7990 - Se actualiza ccsp_GalateaAreas para filtrar usuarios inactivos'
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
    @groupAreas varchar (MAX) = NULL
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
            maxTweets tinyint
        )
        insert into #Areas
        EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@defCampaing=@defCampaing, @isKolob=1
        select a.*,rca.CreateDate,Isnull(rca.defCampaing,0) as defCampaing
        from #Areas a
        inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea
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
            @defCampaing=@defCampaing
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

                update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=isnull(@defCampaing, 0) where IDArea=@IDArea

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

EXEC (@sql)
------------------------------------------------------END MACL----------------------------------------------------
/************************************************************************ End FIX 125.20230425.0.5 **************************************************************/

------------------------------------------------------Begin Roberto Nava ----------------------------------------------------
SET @process = 'CW-8013 Se agregan los tiempos finales de las llamadas de entrada'
SET @sql = '
	IF NOT EXISTS
	(
		SELECT *
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''ccCallsIn''
		AND COLUMN_NAME = ''cal_final''
	)
	BEGIN
		ALTER TABLE ccCallsIn
		ADD cal_final DATETIME NULL
	END
'
EXEC(@sql)


SET @process = 'CW-8013 Se valida SP ccsp_IVRUpdateCallEndNew para la fecha final de las llamadas de entrada'
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_IVRUpdateCallEndNew'')
	BEGIN
	    DROP PROCEDURE ccsp_IVRUpdateCallEndNew;
	END
'

EXEC(@sql)

SET @process = 'CW-8013 Se modifica SP ccsp_IVRUpdateCallEndNew para la fecha final de las llamadas de entrada'
SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_IVRUpdateCallEndNew]
	@cal_id INT,
	@cal_tIVRCallDuration INT,
	@statuscal_id TINYINT, 
	@cal_opciones VARCHAR(10),
	@cal_colgada TINYINT,
	@User_id SMALLINT,
	@cal_extension VARCHAR(7),
	@tWait SMALLINT,
	@cbPhone VARCHAR(20)
	AS
	SET NOCOUNT ON

	UPDATE ccCallsIn 
	SET statusCall_id = 
		CASE 
			WHEN @statuscal_id IN (2, 3, 4, 7, 8) THEN @statuscal_id 
			ELSE 
				CASE 
					WHEN statusCall_id = 5 THEN 6 
					ELSE statuscall_id 
				END 
		END, 
		user_id = 
		CASE 
			WHEN user_id = 0 AND @User_id > 0 THEN @User_id 
			ELSE user_id 
		END, 
	cal_extension = 
		CASE 
			WHEN LEN(cal_extension) = 0 AND LEN(@cal_extension) > 0 THEN @cal_extension 
			ELSE cal_extension 
		END, 
	cal_tWait = @tWait, 
	cal_final = getdate() 
	WHERE cal_id=@cal_id

	EXEC ccsp_RIAUpdateCallBack_Abandon @cal_id, @statuscal_id, @cbPhone
	EXEC ccsp_EngineLogTransfers 2, @cal_id, 2, 2, null, @tWait, @cal_tIVRCallDuration

	SET NOCOUNT OFF 
'

EXEC(@sql)
-------------------------------------------- END Roberto Nava -------------------------------------------------------

		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
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