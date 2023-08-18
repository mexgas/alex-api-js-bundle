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