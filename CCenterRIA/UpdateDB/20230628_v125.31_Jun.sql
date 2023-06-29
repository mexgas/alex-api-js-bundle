/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @versionfix = 31
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
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

	---------------------------------------BEGIN Jesus Gallardo---------------------------------------------------------
	/****************************************************************************
	 * Creacion de SP 
	 * 		ccspOutboundSmsMessage  -> Lo ocupa el servicio NuxibaOutboundSendSmsWorkerService
	 * 		ccsp_smsOUTResetJobs	-> Cuando se detiene una campaña este regresa a status 0 los mensajes no procesados
	 * 		ccsp_SmsInformation		-> El AdminMachine para poder mostrar la grafica
	 *		ccsp_smsCampSchedule	-> Obtner los horarios si hay un cambio en el Administrador
	 *		ccsp_OUTGetNewJobsSMS	-> Carga de registros si estan en horario disponible para el envio de mensajes
	 * 		ccsp_InsertDNCListSms	-> Coloca en la lista negra y elimina los nu
	 *		ccsp_GetHourLaw			-> Obtiene el horario de ley para que se ocupen en campañas de salida
	 * 		ccspLoadCampsOutbound -> Se crea para las consultas de carga de campañas en el outbound y quitar los query directos 
	 *	Alter SP 
	 * 		ccsp_OUTGetNewJobsSMS	-> Se refactoriza para que la cadena de salida sea la misma y solo se divida por los status y la fecha para marcar
	 * 		ccsp_OUTcheckTimeZone	-> Se agrega @isReturnSelect por que sql no permite que se envie a una tabla temporal y no fallen otros SP y se agrega la consulta del SP ccsp_GetHourLaw
	 * 		ccsp_InsertDNCListSms	-> Se quita las campañas de SMS y Whats para que solo procese las campañas de voz y se refactoriza la busqueda para que solo cambie las condiciones del where y update para los demas telefonos
	 *		ccsp_GalateaGetRecordsInfoBySMSCamp -> Se agrega si la campaña esta iniciada por que lo marcaba como apagada en el AdminMachine
	 * 		ccsp_GalateaGetCampsNvosCB -> Se agrega la separacion de campañas de SMS y Voz para que este procese los datos en la barra de progreso select * from #Tcamps2 where campType=7
	 * 		ccsp_RIADNCList			-> Se agrega la ejecuccion del SP ccsp_InsertDNCListSms IF @tipoMov = 1 para cuando se realice una carga de lista negras
	 *		ccsp_ManualCallApplyTimeZoneRules -> Se agrega para timezone no use el uso de la tabla temporal
	 * ****************************************************************************/
	SET @process = 'Core-Sms_K042019 Create Table smsccoLogDial'
	SET @sql = 'if not exists(select * from sys.tables where name=''smsccoLogDial'') begin
	create table smsccoLogDial(	
	logId bigint not null identity primary key,
	smsout_id int not null,
	cam_id int not null,	
	phone varchar(32) not null,
	smsDate datetime not null,
	registryClient varchar(60) not null,
	SystemApiId varchar(100) not null,
	statusSystemsId int not null,
	Bill float not null,
	ProviderId int not null
	)
end'
	EXEC(@sql)


	SET @process = 'Core-Sms_K042019 Create table ccSmsConversationsResult'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccSmsConversationsResult'') begin
CREATE TABLE ccSmsConversationsResult (
		camId SMALLINT NOT NULL,
		SentMsg INT NOT NULL,
		Delivered INT NOT NULL,
		NotDelivered INT NOT NULL,
		RecipientRejected INT NOT NULL,
		CarrierRejected INT NOT NULL,
		InsufficientBalance INT NOT NULL
);
end'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 create table ccHistoryBlacklistSms'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccHistoryBlacklistSms'') begin
CREATE TABLE [dbo].[ccHistoryBlacklistSms](
	[HistorySmsId] [bigint] IDENTITY(1,1) NOT NULL,
	[smsout_id] [int] NULL,
	[Phone] [varchar](32) NOT NULL,
	[Date] [datetime] NOT NULL DEFAULT (getdate()),
	[cam_id] [smallint] NULL,
	[idtipomov] [int] NOT NULL,
	[idtipolista] [int] NULL
)
end'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 Insert setting 247'
	SET @sql = 'if not exists(select * from ccsettings where setting_id=247) begin
	insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
	values(247,''http://192.168.1.47/SmsApi|20|10|UserSmsCore|Password'',''Configuracion para el envio de mensajes|Tiempo entre cada envio|Cantidad de registros'',
	1,''GRL'',''UrlEndpointApi|TimeSend|AccountRegistrybyCamp|UserName|Password'',
	''Configuration for sending messages | Time between each sending | Number of records'',0,''.*'')
end'
	EXEC(@sql)

	
	SET @process = 'Core-Sms_K042019'
	SET @sql = ''
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 DROP PROCEDURE ccspLoadCampsOutbound'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccspLoadCampsOutbound'')
		BEGIN
			DROP PROCEDURE ccspLoadCampsOutbound
		END'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 DROP PROCEDURE ccspOutboundSmsMessage'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccspOutboundSmsMessage'')
		BEGIN
			DROP PROCEDURE ccspOutboundSmsMessage
		END'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 DROP PROCEDURE ccsp_smsOUTResetJobs'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_smsOUTResetJobs'')
		BEGIN
			DROP PROCEDURE ccsp_smsOUTResetJobs
		END'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 DROP PROCEDURE ccsp_SmsInformation'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_SmsInformation'')
		BEGIN
			DROP PROCEDURE ccsp_SmsInformation
		END'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 DROP PROCEDURE ccsp_smsCampSchedule'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_smsCampSchedule'')
		BEGIN
			DROP PROCEDURE ccsp_smsCampSchedule
		END'
	EXEC(@sql)


SET @process = 'Core-Sms_K042019 DROP PROCEDURE ccsp_OUTGetNewJobsSMS'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_OUTGetNewJobsSMS'')
		BEGIN
			DROP PROCEDURE ccsp_OUTGetNewJobsSMS
		END'
EXEC(@sql)
	

	SET @process = 'Core-Sms_K042019 DROP PROCEDURE ccsp_InsertDNCListSms'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_InsertDNCListSms'')
		BEGIN
			DROP PROCEDURE ccsp_InsertDNCListSms
		END'
	EXEC(@sql)


	SET @process = 'Core-Sms_K042019 DROP PROCEDURE ccsp_GetHourLaw'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GetHourLaw'')
		BEGIN
			DROP PROCEDURE ccsp_GetHourLaw
		END'
	EXEC(@sql)
		

	SET @process = 'Core-Sms_K042019 CREATE PROCEDURE ccspOutboundSmsMessage'
	SET @sql = 'CREATE procedure [dbo].[ccspOutboundSmsMessage] 
@action int,
@camId int = null,
@SentMsg int=null,
@smsoutIds varchar(max)=null,
@SystemApiId varchar(100)=null,
@statusSystemsId int =null,
@InsufficientBalance int=null,
@date datetime =null
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
end'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 CREATE PROCEDURE ccsp_smsOUTResetJobs'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_smsOUTResetJobs] 
@camid AS INT= 0
AS
BEGIN

  CREATE TABLE #TempccoLogDials ( 
    smsout_id INT, PRIMARY KEY (smsout_id)
  );
  DECLARE @today DATETIME;

  SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);
  
  IF @camid = 0
  BEGIN
    INSERT INTO #TempccoLogDials
         SELECT smsout_id
         FROM smsccoLogDial AS ld WITH(NOLOCK)
         WHERE smsDate >= @today
         GROUP BY smsout_id;
  END;
     ELSE
    IF @camid > 0
    BEGIN
      INSERT INTO #TempccoLogDials
           SELECT smsout_id
           FROM smsccoLogDial AS ld WITH(NOLOCK)
           WHERE cam_id = @camid AND 
             smsDate >= @today
           GROUP BY smsout_id;
    END;

  -- CALLBACKS Se han marcado recientemente
  UPDATE smsWorkingTable WITH(ROWLOCK)
    SET sms_status = 1
  FROM smsWorkingTable wt
     INNER JOIN
     #TempccoLogDials ld
     ON wt.smsout_id = ld.smsout_id
  WHERE wt.sms_status = 2   

  IF @camid = 0
  BEGIN
    -- NUEVAS - Nunca se han marcado
    UPDATE smsWorkingTable --WITH(ROWLOCK)
      SET sms_status = 0
    WHERE sms_status = 2;
  END;
     ELSE
  BEGIN  
    -- NUEVAS - Nunca se han marcado
    UPDATE smsWorkingTable WITH(ROWLOCK)
      SET sms_status = 0
    WHERE sms_status = 2 AND 
        cam_id = @camid;
  END;

  DROP TABLE #TempccoLogDials;
END;'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 CREATE PROCEDURE ccsp_SmsInformation'
	SET @sql = 'CREATE   PROCEDURE [dbo].[ccsp_SmsInformation]
@Option SMALLINT = 1,
@camId SMALLINT = 0

AS
SET NOCOUNT ON


IF @Option = 1 -- Whats Conversations Results
	BEGIN
		SELECT ISNULL(SentMsg, 0) AS Sent,
				ISNULL(Delivered, 0) AS Delivered,
				ISNULL(NotDelivered, 0) AS NotDelivered,
				ISNULL(RecipientRejected, 0) AS RecipientRejected,
				ISNULL(CarrierRejected, 0) AS CarrierRejected,
				ISNULL(InsufficientBalance, 0) AS InsufficientBalance
		FROM ccSmsConversationsResult
		WHERE camId = @camId
	END
    
SET NOCOUNT OFF'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 CREATE PROCEDURE ccsp_smsCampSchedule'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_smsCampSchedule]
@camId as int
AS

declare @horaUniversal datetime
declare @hourStart int,@hourEnd int,@minStart int,@minEnd int
declare @timeMaxContestacion tinyint

set @timeMaxContestacion=30

select @timeMaxContestacion=cam_tNoContesta from cccamps where cam_id=@camId
declare @schLaw table (hourStart int not null,minStart int not null,hourEnd int not null,minEnd int not null)

insert into @schLaw
exec ccsp_GetHourLaw
SELECT @hourStart = hourStart, @minStart = minStart, @hourEnd = hourEnd, @minEnd = minEnd from @schLaw

SET DATEFIRST 1
set @horaUniversal = getutcdate()

;with camSch as(
select ROW_NUMBER() OVER(ORDER BY idate DESC) AS id
,DATEPART(hh,idate) HoraInicio, DATEPART(mi,idate) as MinInicio
,DATEPART(hh,fDate) horaFin, DATEPART(mi,fDate) as MinFin
,idate,fDate
from ccSmsSchedules where cam_id= @camId 
) 
, camSchLaw as(
select id,
case when HoraInicio>@hourStart then HoraInicio else @hourStart end HoraInicio,
 case when (horaInicio>@hourStart or (horaInicio=@hourStart and MinInicio>=@minStart) ) then MinInicio  else @minStart end MinInicio,
 case when horaFin<@hourEnd then horaFin else @hourEnd end HoraFin,
 case when ((horaFin < @hourEnd or (horaFin=@hourEnd and MinFin<=@minEnd) )) then MinFin  else @minEnd end MinFin
 ,convert(datetime, CONVERT(date, idate)) as idate,convert(datetime,convert(date,fDate)) as fDate
 ,@hourStart hourStart
from camSch
), timeZone as(
 select tz_id,
 dateadd(mi, tz_offset*60, @horaUniversal) as fecha
 from ccTimeZones
)

select distinct
 dateadd(mi,(HoraInicio*60)+MinInicio ,idate) [Start]
, dateadd(ss,-(2*@timeMaxContestacion), dateadd(mi,(horaFin*60)+MinFin ,idate)) [End]
from camSchLaw Sch
inner join timeZone t on 
t.fecha between dateadd(mi,(HoraInicio*60)+MinInicio ,idate)  and dateadd(mi,(horaFin*60)+MinFin ,idate)

'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 CREATE PROCEDURE ccsp_OUTGetNewJobsSMS'
	SET @sql = 'CREATE procedure [dbo].[ccsp_OUTGetNewJobsSMS]
@CAMPID INT,
@action INT=0, --0 select and update, 1 select registry
@topCount INT=50

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
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
SELECT @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

exec @iZonas= ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0

if exists(SELECT cam_id from ccSmsSchedules where cam_id=@campid)
begin
	if @iZonas = 0 begin
		SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
		return
	end
end


IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS

CREATE TABLE #NEW_JOBS (
	SmsOutId INT
	,CamId INT
	,Phone VARCHAR(30) collate SQL_Latin1_General_CP1_CI_AS
	,SmsStatus TINYINT
	,DateDial DATETIME
	,Tz1 INT
	,Tz2 INT
	,Tz3 INT
	,Tz4 INT
	,Tz5 INT
	,CallKey VARCHAR(40)
	,Message VARCHAR(255)
	)
set @sql=''''

DECLARE @new_calls_date VARCHAR(max) = '''';
		

SELECT @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

DECLARE @isVerano varchar(max)

	set @isVerano = ''W.iTimeZone'' + case @bIsDaylight when 1 then ''_summer'' else '''' END

	select @sqlInsertGeneric=nchar(13)+ ''INSERT #NEW_JOBS
SELECT top(@topCount) W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
sos.callkey as CallKey
,msg.message as Message
FROM smsWorkingTable W 
left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
left join smsoutSourceMessage msg (nolock) on msg.smsout_id =W.smsout_id
WHERE STATUS_REPLACE_QUERY
and DATE_REPLACE_QUERY
and W.cam_id=@CAMPID
and (
   ( (''+@isVerano+''  & @iZonas)>0 or ''+@isVerano+''=0) 
or ( (''+@isVerano+''2 & @iZonas)>0 or ''+@isVerano+''2=0) 
or ( (''+@isVerano+''3 & @iZonas)>0 or ''+@isVerano+''3=0) 
or ( (''+@isVerano+''4 & @iZonas)>0 or ''+@isVerano+''4=0)
or ( (''+@isVerano+''5 & @iZonas)>0 or ''+@isVerano+''5=0)
)''

if @TipoJobs in(0,2)--** INCLUIR LOS NUEVAS
begin				
	select @sql=@sql+nchar(13)+''--INCLUIR LAS NUEVAS--''
	select @sql=@sql+REPLACE(
	REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.sms_dateDial < dateadd(mi, 5, getdate())'')
		,''STATUS_REPLACE_QUERY'',''W.sms_status=0'')
	select @sql=@sql+nchar(13)+'' order by W.sms_dateDial ''+ @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc
	print(@sql)
end -- TOMA EN CUENTA LAS NUEVAS

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
	select @sql=@sql+nchar(13)+''--INCLUIR LOS CALLBACKS--''
	select @sql=@sql+nchar(13)+REPLACE(
		REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.cal_fechaDial<dateadd(mi, 5, getdate())'')
	,''STATUS_REPLACE_QUERY'',''W.sms_status=1 -- CallBacks'')
	select @sql=@sql+nchar(13)+'' order by priority_cb desc, W.sms_dateDial ''  + @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
		
					
end -- TOMA EN CUENTA LOS CALLBACKS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
set @parameters=''@CAMPID int,@topCount int,@iZonas int''		

if @action=0
begin
	
	SELECT @sql=@sql+nchar(13)+ ''UPDATE smsWorkingTable with (rowlock) SET sms_status=2 --CALLBACK IN PROGRESS
	WHERE smsout_id in(SELECT SmsOutId from #NEW_JOBS)''	
end

		
	select @sql=@sql+nchar(13)+ ''SELECT SmsOutId, CamId, Phone, SmsStatus, DateDial,
Tz1,Tz2,Tz3,Tz4,Tz5,CallKey as RegistryClient,Message
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

	SET @process = 'Core-Sms_K042019 CREATE PROCEDURE ccsp_InsertDNCListSms'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_InsertDNCListSms]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL

AS
SET NOCOUNT ON;  


declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)
,@tel10 as varchar(30),@tel11 as varchar(30)

if not exists(select * from ccListaNegra with(nolock) where telefono=@telephone and idtipolista=@ln_id 
	and HashKey=@hashCalKey and calKey=@calKey) begin
	insert into cclistanegra(telefono,idtipolista,HashKey, calKey) values(@telephone, @ln_id,@hashCalKey, @calKey)
end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempSms'') IS NOT NULL drop table #myprincipaltempSms
IF OBJECT_ID(N''tempdb..#mytempSms'') IS NOT NULL drop table #mytempSms


CREATE TABLE [dbo].[#mycamps] ([campsid] [int] NULL	)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id And B.CampType=7



CREATE TABLE [dbo].[#myprincipaltempSms](
	[smsout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[sms_phoneNumber] [varchar] (15) NULL ,
	[sms_phoneNumber2] [varchar] (15) NULL ,
	[sms_phoneNumber3] [varchar] (15) NULL ,
	[sms_phoneNumber4] [varchar] (15) NULL ,
	[sms_phoneNumber5] [varchar] (15) NULL
	)

CREATE CLUSTERED INDEX [IX_myprincipaltempSms] ON [dbo].[#myprincipaltempSms]([smsout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms2] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms3] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms4] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms5] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms6] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber5]) 

CREATE TABLE [dbo].[#mytempSms](
	[smsout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempSms]([smsout_id]) 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @tel = dbo.completa(@telephone, @pais, @ld)

set @tel10=RIGHT(@tel,10)
set @tel11=RIGHT(@tel,11)

declare @fech datetime = getdate()-30
if @hashCalKey is not null and @hashCalKey > 0
begin
	insert into [#myprincipaltempSms] 
	SELECT a.smsout_id as smsout_id, a.cam_id,3,@ln_id as idtipolista , a.sms_phoneNumber , a.sms_phoneNumber2, a.sms_phoneNumber3, a.sms_phoneNumber4, a.sms_phoneNumber5 
	FROM [smsOutSource] as a
	inner join #mycamps as b with(nolock) on a.cam_id = b.campsid
	WHERE dbo.hashList(callkey) = @hashCalKey and  sms_dateDial > @fech  
end
else begin	
	insert into [#myprincipaltempSms]
	SELECT a.smsout_id as smsout_id, a.cam_id,3,@ln_id  as idtipolista ,  a.sms_phoneNumber , a.sms_phoneNumber2, a.sms_phoneNumber3, a.sms_phoneNumber4, a.sms_phoneNumber5 
	FROM [smsOutSource] as a
	inner join #mycamps as b with(nolock) on a.cam_id = b.campsid	
	WHERE 
	(@tel  IN (sms_phoneNumber , sms_phoneNumber2, sms_phoneNumber3, sms_phoneNumber4, sms_phoneNumber5) 
	or @tel10 IN (sms_phoneNumber , sms_phoneNumber2, sms_phoneNumber3, sms_phoneNumber4, sms_phoneNumber5) 
	or @tel11 IN (sms_phoneNumber , sms_phoneNumber2, sms_phoneNumber3, sms_phoneNumber4, sms_phoneNumber5)) 
	and  sms_dateDial > @fech
end

if EXISTS (select * from #myprincipaltempSms)
	begin
	
	declare @column nvarchar(max), @sql nvarchar(max)
	,@sqlDeleteWorking nvarchar(max)
	,@sqlUpdateWorking nvarchar(max)
	,@sqlCaseWorking nvarchar(max)
	,@params nvarchar(max)
	,@phoneEmpty varchar(1)
	,@sqlWithReplace nvarchar(max)

	set @phoneEmpty=''''
	set @column=''sms_phoneNumber''
	set @params=''@tel varchar(30),@tel10 varchar(30),@tel11 varchar(30),@phoneEmpty varchar(1),@fech datetime''
	set @sqlDeleteWorking=''and cs.sms_phoneNumber2=@phoneEmpty
	and cs.sms_phoneNumber3=@phoneEmpty
	and cs.sms_phoneNumber4=@phoneEmpty
	and cs.sms_phoneNumber5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.sms_phoneNumber2<>@phoneEmpty then cs.sms_phoneNumber2 
	when cs.sms_phoneNumber3<>@phoneEmpty then cs.sms_phoneNumber3 
	when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
	when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
	else @phoneEmpty end ''

	set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
	update wt 
	set sms_phoneNumber = CASE_UPDATE_WT
	from smsOutSource cs 
	inner join smsWorkingTable wt on cs.smsout_id = wt.smsout_id
	inner join #mytempSms t on cs.smsout_id = t.smsout_id
	where cs.sms_dateDial > @fech and cs.COLUMN_CHECK= wt.sms_phoneNumber''

	set @sql=''insert #mytempSms
select smsout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempSms] with(nolock)
where COLUMN_CHECK in(@tel,@tel10,@tel11)

if EXISTS (select * from #mytempSms)
begin
	-- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
	delete wt with(rowlock)
	from smsWorkingTable wt 
	inner join smsOutSource cs on wt.smsout_id = cs.smsout_id
	inner join #mytempSms t on wt.smsout_id = t.smsout_id
	where cs.sms_dateDial > @fech and
	cs.COLUMN_CHECK = wt.sms_phoneNumber
	AND_DELETE_WT

	UPDATE_SMS_WT_QUERY

	--insertar el historial
	insert ccHistoryBlacklistSms (smsout_id,Phone,cam_id,idtipomov,idtipolista)
	select * from #mytempSms

	-- Eliminamos el telefono1 de CS
	update smsOutSource 
	set COLUMN_CHECK = @phoneEmpty
	from smsOutSource cs 
	inner join #mytempSms t on cs.smsout_id = t.smsout_id
	where cs.sms_dateDial > @fech		

	truncate table #mytempSms
end''
	/******************/
	/*** Telefono 1 ***/
	/******************/
	
	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	print(@sqlWithReplace)	
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech	

	/******************/
	/*** Telefono 2 ***/
	/******************/
	set @column=''sms_phoneNumber2''
	
	set @sqlDeleteWorking='' and cs.sms_phoneNumber3=@phoneEmpty
		and cs.sms_phoneNumber4=@phoneEmpty
		and cs.sms_phoneNumber5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.sms_phoneNumber3<>@phoneEmpty then cs.sms_phoneNumber3 
		when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
		when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech

	/******************/
	/*** Telefono 3 ***/
	/******************/
	set @column=''sms_phoneNumber3''
	
	set @sqlDeleteWorking='' and cs.sms_phoneNumber4=@phoneEmpty
		and cs.sms_phoneNumber5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
		when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech	

	/******************/
	/*** Telefono 4 ***/
	/******************/	
	
	set @column=''sms_phoneNumber4''
	
	set @sqlDeleteWorking='' and cs.sms_phoneNumber4=@phoneEmpty
		and cs.sms_phoneNumber5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
		when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech
		

	/******************/
	/*** Telefono 5 ***/
	/******************/

	set @column=''sms_phoneNumber5''	
	set @sqlDeleteWorking='' and cs.sms_phoneNumber5=@phoneEmpty''	
	set @sqlCaseWorking=''''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech
	
end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempSms'') IS NOT NULL drop table #myprincipaltempSms
IF OBJECT_ID(N''tempdb..#mytempSms'') IS NOT NULL drop table #mytempSms'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 CREATE PROCEDURE ccsp_InsertDNCList'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL
WITH RECOMPILE
AS


declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)
,@tel10 as varchar(30),@tel11 as varchar(30)

insert into cclistanegra(telefono,idtipolista,HashKey, calKey) values(@telephone, @ln_id,@hashCalKey, @calKey)

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall


CREATE TABLE [dbo].[#mycamps] (	[campsid] [int] NULL)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id and B.CampType not in(7,5)

CREATE TABLE [dbo].[#myprincipaltempCall](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltempCall]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltempCall]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltempCall]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltempCall]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltempCall]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltempCall]([cal_telefono5]) 

CREATE TABLE [dbo].[#mytempCall](
	[callout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempCall]([callout_id]) 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @tel = dbo.completa(@telephone, @pais, @ld)

set @tel10=RIGHT(@tel,10)
set @tel11=RIGHT(@tel,11)

declare @fech datetime = getdate()-30
if @hashCalKey is not null and @hashCalKey > 0
begin

	insert into [#myprincipaltempCall] 
	SELECT a.callout_id as callout_id, a.cam_id,3,@ln_id as idtipolista , a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
	FROM [ccoCallsOutSource] as a, #mycamps as b with(nolock) 
	WHERE a.cam_id = b.campsid 
	AND dbo.hashList(cal_Key) = @hashCalKey and  cal_fechadial > @fech  
end
else begin
	insert into [#myprincipaltempCall]
	SELECT a.callout_id as callout_id, a.cam_id,''3'',cast(@ln_id as nvarchar) as idtipolista , a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
	FROM [ccoCallsOutSource] as a, #mycamps as b with(nolock) 
	WHERE a.cam_id = b.campsid	
	and (@tel  IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) 
	or @tel10 IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) 
	or @tel11 IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5])) 
	and  cal_fechadial > @fech  
end


if EXISTS (select * from #myprincipaltempCall)
begin
	declare @column nvarchar(max), @sql nvarchar(max)
	,@sqlDeleteWorking nvarchar(max)
	,@sqlUpdateWorking nvarchar(max)
	,@sqlCaseWorking nvarchar(max)
	,@params nvarchar(max)
	,@phoneEmpty varchar(1)
	,@sqlWithReplace nvarchar(max)

	set @phoneEmpty=''''
	set @column=''cal_telefono''
	set @params=''@tel varchar(30),@tel10 varchar(30),@tel11 varchar(30),@phoneEmpty varchar(1),@fech datetime''
	set @sqlDeleteWorking=''and cs.cal_telefono2=@phoneEmpty
	and cs.cal_telefono3=@phoneEmpty
	and cs.cal_telefono4=@phoneEmpty
	and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono2<>@phoneEmpty then cs.cal_telefono2 
	when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
	when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
	when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
	else @phoneEmpty end ''

	set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
	update wt 
	set cal_telefono = CASE_UPDATE_WT
	from ccoCallsOutSource cs 
	inner join ccoWOrkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytempCall t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > @fech and cs.COLUMN_CHECK= wt.cal_telefono''

	set @sql=''insert #mytempCall
select callout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempCall] with(nolock)
where cal_telefono in(@tel,@tel10,@tel11)

if EXISTS (select * from #mytempCall)
begin		
	-- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
	delete wt with(rowlock)
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytempCall t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > @fech and
	cs.COLUMN_CHECK = wt.cal_telefono
	AND_DELETE_WT

	UPDATE_SMS_WT_QUERY

	--insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytempCall

	-- Eliminamos el telefono1 de CS
	update ccoCallsOutSource 
	set COLUMN_CHECK = @phoneEmpty
	from ccoCallsOutSource cs 
	inner join #mytempCall t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > @fech		

	truncate table #mytempCall
end''

	
	/******************/
	/*** Telefono 1 ***/
	/******************/
	
	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	print(@sqlWithReplace)	
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech	

	/******************/
	/*** Telefono 2 ***/
	/******************/
	set @column=''cal_telefono2''
	
	set @sqlDeleteWorking='' and cs.cal_telefono3=@phoneEmpty
		and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
		when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech

	/******************/
	/*** Telefono 3 ***/
	/******************/
	set @column=''cal_telefono3''
	
	set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech
	
	/******************/
	/*** Telefono 4 ***/
	/******************/	
	
	set @column=''cal_telefono4''
	
	set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech
	
	/******************/
	/*** Telefono 5 ***/
	/******************/

	set @column=''cal_telefono5''	
	set @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty''	
	set @sqlCaseWorking=''''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech

end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 CREATE PROCEDURE ccsp_GetHourLaw'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GetHourLaw]
AS
SET NOCOUNT ON

DECLARE @isShudulerLey BIT
DECLARE @valueShudulerLey VARCHAR(max), @hourStart INT, @hourEnd INT, @minStart INT, @minEnd INT
DECLARE @shourStart VARCHAR(max), @shourEnd VARCHAR(max)

SELECT @valueShudulerLey = valor
FROM ccsettings
WHERE setting_id = 166

SELECT @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex(''|'', @valueShudulerLey)) AS INT), @valueShudulerLey = substring(
		@valueShudulerLey, charindex(''|'', @valueShudulerLey) + 1, len(@valueShudulerLey))

IF @valueShudulerLey = ''''
BEGIN
	SET @valueShudulerLey = ''0|07:00|22:00''

	UPDATE ccsettings
	SET valor = @valueShudulerLey
	WHERE setting_id = 166
END

IF @isShudulerLey = 1
BEGIN
	SELECT @shourStart = substring(@valueShudulerLey, 0, charindex(''|'', @valueShudulerLey)), 
	@shourEnd = substring(@valueShudulerLey, charindex(''|'', 
				@valueShudulerLey) + 1, len(@valueShudulerLey))

	SELECT @hourStart = substring(@shourStart, 0, charindex('':'', @shourStart)), 
	@minStart = substring(@shourStart, charindex('':'', @shourStart) + 1, len(
				@shourStart))

	SELECT @hourEnd = substring(@shourEnd, 0, charindex('':'', @shourEnd)), 
	@minEnd = substring(@shourEnd, charindex('':'', @shourEnd) + 1, len(@shourEnd))
END
ELSE
BEGIN
	SELECT @hourStart = 0, @minStart = 0, @hourEnd = 23, @minEnd = 59
END

SELECT @hourStart as hourStart, @minStart as minStart, @hourEnd as hourEnd, @minEnd minEnd
'
	EXEC(@sql)		


	SET @process = 'Core-Sms_K042019'
	SET @sql = ''
	EXEC(@sql)


	SET @process = 'Core-Sms_K042019 CREATE ccspLoadCampsOutbound'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccspLoadCampsOutbound] @action int,  @nTipo INT=0,@agentId int=0
AS
declare @sql nvarchar(max)

if @action= 0 begin

	set @sql=''SELECT cam_id
,cam_descripcion
,cam_activo
,cam_ModoManual
,cam_modpredictivo
,cam_callratio
,cam_procesando
,convert(VARCHAR(8), cast(cam_maxdlrxage AS FLOAT))
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
	''
	set @sql=@sql+'' ,isnull(CampType,0) as CampType''
	
	
	set @sql=@sql+'' FROM ccCamps NOLOCK ''
	if @nTipo=2 
		set @sql=@sql+'' WHERE cam_bNew = 2 ''
	else if @nTipo=3
		set @sql=@sql+'' WHERE cam_bNew in (1,2) ''
	set @sql=@sql+'' ORDER BY cam_descripcion''
	--print(@sql)
	exec (@sql)
end
else if @action= 1 begin
	set @sql=''SELECT distinct C.cam_id, C.cam_descripcion, Prioridad, A.Login, A.User_id, Skill
 from ccCamps C (nolock) join ccCampsAgente CA on C.cam_id = CA.cam_id
  join ccUsers A (nolock) on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1
  ''
  if @nTipo=2 
		set @sql=@sql+'' and C.cam_bNew=2''
	else if @nTipo=3
		set @sql=@sql+'' and C.cam_bNew in (1,2)''
	set @sql=@sql+'' order by C.cam_id, CA.Prioridad''
	--print(@sql)
	exec (@sql)
end
else if @action= 2 begin
	set @sql=''select distinct A.Login, Prioridad, C.cam_id, Skill
 from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id
 join ccUsers A  on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1
 Where A.User_id = @agentId
 order by C.cam_id, CA.Prioridad''
	print(@sql)
	exec sp_executesql @sql, N''@agentId int'', @agentId
end'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 Alter PROCEDURE ccsp_OUTcheckTimeZone'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTcheckTimeZone] @cam_id AS INT,@isReturnSelect bit=1
AS
SET NOCOUNT ON

DECLARE @horaUniversal DATETIME, @revHorario BIT, @isShudulerLey BIT, @dateNow DATETIME
DECLARE @hourStart INT, @hourEnd INT, @minStart INT, @minEnd INT
DECLARE @timeMaxContestacion INT, @campType INT;

SET @timeMaxContestacion = 60

SELECT @revHorario = valor
FROM ccsettings
WHERE setting_id = 112

SELECT @timeMaxContestacion = (cam_tNoContesta * 2)
FROM cccamps
WHERE cam_id = @cam_id

SET @timeMaxContestacion = CEILING(cast(@timeMaxContestacion AS DECIMAL(10, 2)) / cast(60 AS DECIMAL(10, 2)))

declare @schLaw table (hourStart int not null,minStart int not null,hourEnd int not null,minEnd int not null)

insert into @schLaw
exec ccsp_GetHourLaw
SELECT @hourStart = hourStart, @minStart = minStart, @hourEnd = hourEnd, @minEnd = minEnd from @schLaw

SELECT @campType = CampType
FROM ccCamps
WHERE cam_id = @cam_id;

SET DATEFIRST 1
SET @horaUniversal = getutcdate()
SET @dateNow = getdate()
declare @iZonas int
-- Si la campaña no tiene horarios asignados, marcar todas las zonas
IF @revHorario = 0
BEGIN
	IF NOT EXISTS (
			SELECT cam_id
			FROM ccCampsHorarios WITH (INDEX (IX_ccCampsHorarios))
			WHERE cam_id = @cam_id
			)
	BEGIN
		SELECT @iZonas=sum(DISTINCT tz_id)
		FROM (
			SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha, 
			datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora, 
			datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto, 
			datepart(dw, dateadd(mi, tz_offset * 60, @horaUniversal)) AS dia
			FROM ccTimeZones
			) zonas
		WHERE (
				hora > @hourStart OR ( hora = @hourStart AND minuto >= @minStart)
				)
			AND (
				hora < @hourEnd OR ( hora = @hourEnd AND minuto <= @minEnd)
				)

	if @isReturnSelect=1 begin
		select @iZonas as iZonas
	end
	return @iZonas
	END
END

IF @campType <> 7
BEGIN
	
	SELECT h.horario_id, Descripcion, CASE WHEN HoraInicio > @hourStart THEN HoraInicio ELSE @hourStart END HoraInicio
	, CASE WHEN (horaInicio > @hourStart OR (horaInicio = @hourStart	AND MinInicio >= @minStart) ) THEN MinInicio ELSE @minStart END MinInicio
	, CASE WHEN horaFin < @hourEnd THEN horaFin ELSE @hourEnd END HoraFin
	, CASE WHEN (
		(horaFin < @hourEnd OR (horaFin = @hourEnd AND MinFin <= @minEnd)
			)
		) THEN MinFin ELSE @minEnd END MinFin, Lunes, Martes, Miercoles, Jueves, Viernes, Sabado, Domingo
	INTO #tempCamp
	FROM cchorarios h
	INNER JOIN ccCampsHorarios WITH (INDEX (IX_ccCampsHorarios)) ON h.horario_id = ccCampsHorarios.horario_id
		AND ccCampsHorarios.cam_id = @cam_id

	SELECT @iZonas=isnull(sum(DISTINCT tz_id), 0)
	FROM (
		SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha, 
		datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora, 
		datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto, 
		datepart(dw, dateadd(mi, tz_offset * 60, @horaUniversal)) AS dia
		FROM ccTimeZones
		) zonas
	INNER JOIN #tempCamp ON (
			(
				hora > HoraInicio OR ( hora = HoraInicio AND minuto >= MinInicio)
				)
			AND (
				hora < HoraFin OR (hora = HoraFin AND minuto <= (MinFin - @timeMaxContestacion))
				)
			AND (
				Lunes = dia
				OR Martes * 2 = dia
				OR Miercoles * 3 = dia
				OR Jueves * 4 = dia
				OR Viernes * 5 = dia
				OR Sabado * 6 = dia
				OR domingo * 7 = dia
				)
			)

	DROP TABLE #tempCamp
	if @isReturnSelect=1 begin
		select @iZonas as iZonas
	end
	return @iZonas
END
ELSE
BEGIN
		;

	WITH sch
	AS (
		SELECT DATEPART(hh, idate) AS HoraInicio, DATEPART(mi, iDate) AS MinInicio, 
		DATEPART(hh, fdate) HoraFin, DATEPART(mi, fdate) MinFin
		FROM ccSmsSchedules
		WHERE cam_id = @cam_id
			AND @dateNow BETWEEN iDate AND fDate
		), daysch
	AS (
		SELECT CASE WHEN HoraInicio > @hourStart THEN HoraInicio ELSE @hourStart END HoraInicio
		, CASE WHEN (horaInicio > @hourStart OR (horaInicio = @hourStart AND MinInicio >= @minStart	)
						) THEN MinInicio ELSE @minStart END MinInicio
		, CASE WHEN horaFin < @hourEnd THEN horaFin ELSE @hourEnd END HoraFin
		, CASE WHEN ((	horaFin < @hourEnd OR (	horaFin = @hourEnd AND MinFin <= @minEnd))
						) THEN MinFin ELSE @minEnd END MinFin
		FROM sch
		), zonas
	AS (
		SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha
		, datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora
		, datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto
		FROM ccTimeZones
		)
	SELECT @iZonas=isnull(sum(DISTINCT B.tz_id), 0)
	FROM daysch A
	INNER JOIN zonas B ON (
			hora > HoraInicio OR ( hora = HoraInicio AND minuto >= MinInicio)
			)
		AND (
			hora < HoraFin OR (hora = HoraFin AND minuto <= (MinFin - @timeMaxContestacion))
			)

	if @isReturnSelect=1 begin
		select @iZonas as iZonas
	end
	return @iZonas
END
'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 CREATE PROCEDURE ccsp_GalateaGetRecordsInfoBySMSCamp'
	SET @sql = 'ALTER proc [dbo].[ccsp_GalateaGetRecordsInfoBySMSCamp]
@cam_id integer = 0, @user_id int = 0
as
;with countState as(
SELECT cam_id as id,
count(case sms_status when 0 then 1 else null end) as New
FROM smsWorkingTable SMS 
where SMS.cam_id=@cam_id group by cam_id
)

select id,New,B.cam_procesando St 
from countState A 
inner join ccCamps B on A.id=B.cam_id'
	EXEC(@sql)


	SET @process = 'Core-Sms_K042019 CREATE PROCEDURE ccsp_GalateaGetCampsNvosCB'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0, @tcpa int=0
as
set nocount on

declare @TipoJobs as int, @isExecOutbound bit

set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

	declare @id AS INTEGER;

	CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,campType INT)
	CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime,campType INT)

	create table #tempoutsource (cam_id int,Pend  int)

	create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

	if @cam_id = 0 begin
		if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
			select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
			,isnull(cam.CampType,0) as CampType
			from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
			where user_id = @user_id and tipo = 1
		end
		else begin
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
			select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
			,isnull(cam.CampType,0) as CampType
			from ccCamps cam (nolock)
		end
	end
	else begin
		if @Tipo = 2
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
			select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
			,isnull(cam.CampType,0) as CampType
			from ccCamps cam with(nolock) 
			where cam.cam_id = @cam_id
		else
			if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
				select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
				,isnull(cam.CampType,0) as CampType
				from ccCamps cam with(nolock) 
				inner join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
				where user_id = @user_id and tipo = 1
			end
			else begin
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
				select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
				,isnull(cam.CampType,0) as CampType
				from ccCamps cam (nolock) 
				where cam_activo=1 
			end
	end
	
	;with ccCampsNvosCBTmp as(
	select A.*,dateUpdate from #Tcamps A
	left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
	where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null
	)
	insert into #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate,campType)
	select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate),max(campType) as campType 
	from ccCampsNvosCBTmp
	group by cam_id

	if exists(select * from #Tcamps2) BEGIN

		if exists(select * from #Tcamps2 where campType=7) BEGIN
			insert into #tempoutsource(cam_id,Pend)
			SELECT sos.cam_id, count(sos.cam_id) as Pend
			FROM dbo.smsOutSource AS sos  with(index(IX_smsOutSource_1),nolock)
			inner join #Tcamps2 tcam on sos.cam_id = tcam.cam_id
			WHERE tcam.campType=7 and sos.sms_status in(0, 7)
			GROUP BY sos.cam_id

			insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
			SELECT swt.cam_id,
			count(case swt.sms_status when 0 then 1 else null end) as New,
			count(case swt.sms_status when 1 then 1 else null end) as Cb,
			count(case swt.sms_status when 2 then 1 else null end) as Pro,
			count(case swt.sms_status when 3 then 1 else null end) as Fin
			FROM dbo.smsWorkingTable AS swt  with(index(IX_smsWorkingTable_1),nolock)
			inner join #Tcamps2 B on swt.cam_id = B.cam_id 
			where B.campType=7
			GROUP BY swt.cam_id	
		end
			insert into #tempoutsource(cam_id,Pend)
			SELECT ccos.cam_id, count(ccos.cam_id) as Pend
			FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
			join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
			WHERE tcam.campType<>7 and cal_status in(0, 7)
			GROUP BY ccos.cam_id

			insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
			SELECT A.cam_id,
			count(case cal_status when 0 then 1 else null end) as New,
			count(case cal_status when 1 then 1 else null end) as Cb,
			count(case cal_status when 2 then 1 else null end) as Pro,
			count(case cal_status when 3 then 1 else null end) as Fin
			FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
			inner join #Tcamps2 B on A.cam_id = B.cam_id
			WHERE B.campType<>7 
			GROUP BY A.cam_id	
		
		if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
			update #Tcamps2 set status =1,cantidad=0  where cam_id = @cam_id
		end
		else begin
			While exists(select * from #Tcamps2 where status = 0 and ( datediff(ss,dateUpdate,getdate())>60 or dateUpdate is null))  Begin
				set rowcount 1
				select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
				set rowcount 0
				EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
				update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
			end
		end

		declare @TotalNew table(
			cam_id int primary key,
			OverallTotalNew int 
			)
		

		begin Tran updateccCampsNvosCB

			insert into @TotalNew
			select CampNvosCB.id,isnull(CASE WHEN CampNvosCB.OverallTotalNew = 0 THEN NULL ELSE CampNvosCB.OverallTotalNew END,CampNvosCB.new)  from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
			where CampNvosCB.id = tcamp.cam_id

			delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
			where CampNvosCB.id = tcamp.cam_id

			INSERT into ccCampsNvosCB 
			SELECT cams.cam_id, cams.cam_descripcion,
			isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
			isNull(cs.Pend,0) as pend,
			isNull(wt.Pro,0) as pro,
			isNull(cams.procesando,0) cam_procesando,
			isNull(cams.cam_tipojobs,0) cam_tipojobs,
			isNull(wt.Fin,0) Fin,
			isNull(cams.cantidad,0) cantidad,
			getdate(),
			isnull(T.OverallTotalNew,0)  as OverallTotalNew
			FROM #Tcamps2 cams with(nolock)
			LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
			LEFT JOIN #tempoutsource cs on cams.cam_id = cs.cam_id
			LEFT JOIN @TotalNew  T on T.cam_id = cams.cam_id

		COMMIT TRAN updateccCampsNvosCB
	end

	if @isExecOutbound = 0 begin

	if @Tipo = 2 begin
		-- devuelve resultado de la taba, solo las camps del usuario
		SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, 
		isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor, OverallTotalNew
		FROM #Tcamps tcam
		left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
	end
	else 
		SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,
		cc.aggressionFactor, OverallTotalNew
		FROM ccCampsNvosCB res (nolock)
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
		WHERE res.id = @cam_id
	end

	drop table #Tcamps
	drop table #Tcamps2
	drop table #tempoutsource
	drop table #temWorkinTable

	return(0)

end

set nocount off'
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 CREATE PROCEDURE ccsp_OUTGetNewJobs'
	SET @sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID INT,
@test INT=0,
@nAgentsLogin INT=1,
@iZonas INT = NULL,
@isDashboardApi BIT = 0
as
set nocount on
DECLARE @total INT
DECLARE @topCount smallINT, @bIsDaylight bit, @revHorario bit
DECLARE @country_id INT, @TipoJobs INT

DECLARE @sql nvarchar(MAX), @Order_Asc_Desc char(4)
declare @sqlInsertGeneric nvarchar(MAX)
declare @parameters nvarchar(MAX)
DECLARE @camSurvey INT, @campType INT;
SELECT @camSurvey = 0

SELECT @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0;
SELECT @campType = CampType FROM ccCamps WHERE cam_id =  @CAMPID;
		
-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
SELECT @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
SELECT @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

if @iZonas is null begin
	exec @iZonas= ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0		
--Checamos si la campaña tiene horarios configurados
if exists(SELECT cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
begin
	if @iZonas = 0 begin
		SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
		return
	end
end
else begin
	if @camSurvey > 0
	begin
		SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
		return
	end
end
end

IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS
IF OBJECT_ID(N''tempdb..#AI_NEW_JOBS'') IS NOT NULL  DROP TABLE #AI_NEW_JOBS

CREATE TABLE #NEW_JOBS (
	callout_id INT
	,cam_id INT
	,cal_telefono VARCHAR(15) collate SQL_Latin1_General_CP1_CI_AS
	,cal_status TINYINT
	,cal_fechaDial DATETIME
	,user_id INT
	,tz INT
	,tz2 INT
	,tz3 INT
	,tz4 INT
	,tz5 INT
	,list_id INT
	,sequence SMALLINT
	,calkey VARCHAR(max)
	,nDescartes INT
	,name_agent VARCHAR(max)
	,status_for_ai TINYINT
	)
select * into #AI_NEW_JOBS from  #NEW_JOBS where 1=0


set @sql=''''

-------------------------- IA -------------------
DECLARE @IsCampAi BIT = 0;
DECLARE @new_calls_date VARCHAR(max) = '''';


SELECT @IsCampAi = CASE WHEN CampType = 4 THEN 1 ELSE 0 END FROM ccCamps where cam_id = @CAMPID 

DECLARE @select_table VARCHAR(50);
SET @select_table = (CASE WHEN @IsCampAi = 1 THEN ''#AI_NEW_JOBS'' ELSE ''#NEW_JOBS'' END);
		
-------------------------- IA -------------------

-- 0=Ambas, 1=CallBacks, 2=Nuevas
SELECT @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
SELECT @topCount=case when @nAgentsLogin<3 then 30
		when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
		when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
		when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
		when @nAgentsLogin>=16 then 240 else 20 end
		
SELECT @sql=@sql+nchar(13) + ''DECLARE @topCountNewToday INT=0,@topCountNewLastDay INT=0,@topCountCb INT=0,@totalNewToday INT=0
,@totalNewLastDay INT=0,@totalCallbacks INT=0,@stateIa INT=0
DECLARE @newCallsPercentage FLOAT=0.7,@lastDayNewCallsPercentage FLOAT= 0.15,@callbacksPercentage FLOAT=0.15;
SELECT @topCountNewToday = CEILING(@topCount* @newCallsPercentage),
@topCountNewLastDay = CEILING(@topCount* @lastDayNewCallsPercentage), 
@topCountCb = CEILING(@topCount* @callbacksPercentage),@stateIa=0
,@topCountNewToday=case when @IsCampAi=1 then @topCountNewToday else  @topCount/2 end''

SELECT @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

DECLARE @isVerano varchar(max)
set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' END

IF(@campType = 7)
BEGIN
	set @isVerano = ''W.iTimeZone'' + case @bIsDaylight when 1 then ''_summer'' else '''' END

	select @sqlInsertGeneric=nchar(13)+ ''INSERT ''+@select_table+'' 
SELECT top(@topCount) W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
sos.callkey+''''~''''+rtrim(data1)+''''~''''+rtrim(data2)+''''~''''+rtrim(data3)+''''~''''+rtrim(data4)+''''~''''+rtrim(data5) calkey, 0 AS nDescartes,
isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
,@stateIa status_for_ai
FROM smsWorkingTable W 
left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
WHERE STATUS_REPLACE_QUERY
and DATE_REPLACE_QUERY
and W.cam_id=@CAMPID
and (
   ( (''+@isVerano+''  & @iZonas)>0 or ''+@isVerano+''=0) 
or ( (''+@isVerano+''2 & @iZonas)>0 or ''+@isVerano+''2=0) 
or ( (''+@isVerano+''3 & @iZonas)>0 or ''+@isVerano+''3=0) 
or ( (''+@isVerano+''4 & @iZonas)>0 or ''+@isVerano+''4=0)
or ( (''+@isVerano+''5 & @iZonas)>0 or ''+@isVerano+''5=0)
)
and isnull(R.status,2) in(0,2)''

END
else begin
	select @sqlInsertGeneric=nchar(13)+ ''INSERT ''+@select_table+'' 
SELECT top(@topCountNewToday) W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
,W.nDescartes,isnull(us.nombres, '''''''')+'''' ''''+isnull(us.ApellidoPaterno, '''''''')+'''' ''''+isnull(us.ApellidoMaterno, '''''''') Name_agent
,@stateIa status_for_ai
FROM ccoWorkingTable W 
left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
WHERE STATUS_REPLACE_QUERY
AND DATE_REPLACE_QUERY
and W.cam_id=@CAMPID
and (
   ( (''+@isVerano+''  & @iZonas)>0 or ''+@isVerano+''=0) 
or ( (''+@isVerano+''2 & @iZonas)>0 or ''+@isVerano+''2=0) 
or ( (''+@isVerano+''3 & @iZonas)>0 or ''+@isVerano+''3=0) 
or ( (''+@isVerano+''4 & @iZonas)>0 or ''+@isVerano+''4=0)
or ( (''+@isVerano+''5 & @iZonas)>0 or ''+@isVerano+''5=0)
)
and isnull(R.status,2) = 2''
end

if @TipoJobs in(0,2)--** INCLUIR LOS NUEVAS
begin			
	IF(@campType = 7)
	BEGIN

		select @sql=@sql+nchar(13)+''--INCLUIR LAS NUEVAS--''
		select @sql=@sql+REPLACE(
		REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.sms_dateDial < dateadd(mi, 5, getdate())'')
			,''STATUS_REPLACE_QUERY'',''W.sms_status=0'')
		select @sql=@sql+nchar(13)+'' order by R.sequence, W.sms_dateDial ''+ @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc
						
	END
	ELSE 
	BEGIN			

		SET @new_calls_date = (CASE WHEN @IsCampAi = 1
			THEN '' W.cal_fechaDial BETWEEN CONVERT(DATE, getdate()) AND DATEADD(mi, 5, getdate()) '' 
			ELSE '' W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora '' END);					
	
		select @sql=@sql+nchar(13)+''--INCLUIR LAS NUEVAS--''
		select @sql=@sql+REPLACE(
			REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',@new_calls_date)
				,''STATUS_REPLACE_QUERY'',''W.cal_status=0'')
		select @sql=@sql+nchar(13)+'' order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
	END

end -- TOMA EN CUENTA LAS NUEVAS

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
	IF(@campType = 7)
	BEGIN				
		select @sql=@sql+nchar(13)+''--INCLUIR LOS CALLBACKS--''
		select @sql=@sql+nchar(13)+REPLACE(
			REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.cal_fechaDial<dateadd(mi, 5, getdate())'')
		,''STATUS_REPLACE_QUERY'',''W.sms_status=1 -- CallBacks'')
		select @sql=@sql+nchar(13)+'' order by priority_cb desc, W.sms_dateDial ''  + @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
	END
	ELSE
	BEGIN
		select @sql=@sql+nchar(13)+''--INCLUIR LOS CALLBACKS--''
		select @sql=@sql+nchar(13)+REPLACE(
			REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.cal_fechaDial<dateadd(mi, 5, getdate())'')
		,''STATUS_REPLACE_QUERY'',''W.cal_status=1'')
		select @sql=@sql+nchar(13)+'' order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
	END
					
end -- TOMA EN CUENTA LOS CALLBACKS

IF @IsCampAi = 1 -- NUEVOS REZAGADOS
BEGIN	
	select @sql=@sql+nchar(13)+''--NUEVOS REZAGADOS--''
	select @sql=@sql+REPLACE(
		REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.cal_fechaDial<convert(date,getdate())'')
		,''STATUS_REPLACE_QUERY'',''W.cal_status=0'')
	select @sql=@sql+nchar(13)+'' order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
END -- TOMA EN CUENTA LOS NUEVOS REZAGADOS


		
----------------------- CASO DE IA------------------------------------------------------
IF @IsCampAi = 1 
BEGIN

SELECT @sql=@sql+nchar(13) + ''select @totalNewToday = count(*) from #AI_NEW_JOBS where status_for_ai = 0
select @totalCallbacks = count(*) from #AI_NEW_JOBS where status_for_ai = 1
select @totalNewLastDay = count(*) from #AI_NEW_JOBS where status_for_ai = 2	
insert into #NEW_JOBS
select top(@topCountNewToday) callout_id,cam_id,cal_telefono,cal_status,cal_fechaDial,user_id,tz,tz2,tz3,tz4,tz5,list_id,sequence,calkey,nDescartes,name_agent
,status_for_ai
from #AI_NEW_JOBS where status_for_ai=0
if @totalNewToday< @topCountNewToday begin
	set @topCountNewLastDay=@topCountNewLastDay+(@topCountNewToday-@totalNewToday)
end
insert into #NEW_JOBS
select top(@topCountNewLastDay) callout_id,cam_id,cal_telefono,cal_status,cal_fechaDial,user_id,tz,tz2,tz3,tz4,tz5
,list_id,sequence,calkey,nDescartes,name_agent
,status_for_ai
from #AI_NEW_JOBS where status_for_ai=2	
if @totalNewToday+@totalNewLastDay < @topCountNewToday+@topCountCb begin
	set @topCountCb=@topCountCb+@topCountNewToday+@topCountCb-@totalNewToday-@totalNewLastDay
end
insert into #NEW_JOBS
select top(@topCountCb) callout_id,cam_id,cal_telefono,cal_status,cal_fechaDial,user_id,tz,tz2,tz3,tz4,tz5
,list_id,sequence,calkey,nDescartes,name_agent
,status_for_ai
from #AI_NEW_JOBS where status_for_ai=1''

END
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
set @parameters=''@CAMPID int,@topCount int,@IsCampAi BIT,@iZonas int,@campType int''		

if @Test=0
begin
	IF(@campType = 7) begin
		SELECT @sql=@sql+nchar(13)+ ''UPDATE smsWorkingTable with (rowlock) SET sms_status=2 --CALLBACK IN PROGRESS
	WHERE smsout_id in(SELECT callout_id from '' + @select_table +'')''
	end
	else begin
		SELECT @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
	WHERE callout_id in(SELECT callout_id from '' + @select_table +'')''
	end
	
end

if @Test = 2
begin
	SELECT @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM '' + @select_table +'' where len(cal_telefono)>0''
	DECLARE @nSQL nvarchar(max)
	set @nSQL=cast(@sql as nvarchar(max))
	set @parameters=@parameters+N'',@outA int OUTPUT''

	exec sp_executesql @nSQL, @parameters
	,@CAMPID=@CAMPID
	,@topCount=@topCount
	,@IsCampAi=@IsCampAi
	,@iZonas=@iZonas
	,@campType=@campType
	,@outA=@total OUTPUT

	IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS
	IF OBJECT_ID(N''tempdb..#AI_NEW_JOBS'') IS NOT NULL  DROP TABLE #AI_NEW_JOBS

	print (@sql)

		return(@total)
end
else
BEGIN
	IF(@isDashboardApi = 1)
	BEGIN
			
	-- TOMA EN CUENTA LOS REGISTROS PROCESANDOSE
	select @sql=@sql+nchar(13)+''--Procesando--''
	select @sql=@sql+REPLACE(
		REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora'')
		,''STATUS_REPLACE_QUERY'',''W.cal_status=2'')
	select @sql=@sql+nchar(13)+'' order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc

	END
		
	select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5,
case when tz is null then '''''''' else cal_telefono end as tel,
case when tz2 is null then '''''''' else cal_telefono end as tel2,
case when tz3 is null then '''''''' else cal_telefono end as tel3,
case when tz4 is null then '''''''' else cal_telefono end as tel4,
case when tz5 is null then '''''''' else cal_telefono end as tel5,
NULL as dialOrder, list_id, sequence, calkey,
0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type
FROM #NEW_JOBS where len(cal_telefono)>0

---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
if @campType<>7 and exists(SELECT * FROM #NEW_JOBS)
	exec ccsp_GetCampsNvosCB @cam_id=@CAMPID,@Tipo=0,@user_id=0
''
END

print (@sql)

exec sp_executesql  @sql,@parameters,
@CAMPID=@CAMPID
,@topCount=@topCount
,@IsCampAi=@IsCampAi
,@iZonas=@iZonas
,@campType=@campType

IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS
IF OBJECT_ID(N''tempdb..#AI_NEW_JOBS'') IS NOT NULL  DROP TABLE #AI_NEW_JOBS


return(0)'
	EXEC(@sql)
	

	SET @process = 'Core-Sms_K042019 ALTER PROCEDURE ccsp_RIADNCList'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIADNCList] @phoneNumber AS VARCHAR(30), @idDNCList AS INTEGER, @tipoMov AS TINYINT, @calKey AS VARCHAR(40) = NULL
AS
DECLARE @hashCalKey bigint, @hashPhone BIGINT

IF @calKey IS NOT NULL
BEGIN
	SELECT @hashCalKey = dbo.hashList(@calKey)
END

IF @tipoMov = 1
BEGIN -- Inserta Lista Negra	
	EXEC ccsp_InsertDNCList @telephone = @phoneNumber, @ln_id = @idDNCList, @hashCalKey = @hashCalKey, @calKey = @calKey
	exec ccsp_InsertDNCListSms @telephone = @phoneNumber, @ln_id = @idDNCList, @hashCalKey = @hashCalKey, @calKey = @calKey

	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@phoneNumber, 7, @idDNCList)
END

IF @tipoMov = 2
BEGIN -- Borra Lista Negra	
	SELECT @hashPhone = dbo.hashPhone(@phoneNumber)

	IF @hashCalKey IS NULL
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idDNCList
	END
	ELSE
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idDNCList
	END

	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@phoneNumber, 5, @idDNCList)
END

IF @tipoMov = 3
BEGIN -- Reemplaza Lista Negra
	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	SELECT telefono, ''4'', @idDNCList
	FROM cclistanegra
	WHERE idtipolista = @idDNCList

	DELETE
	FROM cclistanegra
	WHERE idtipolista = @idDNCList
END '
	EXEC(@sql)

	SET @process = 'Core-Sms_K042019 Alter SP ccsp_ManualCallApplyTimeZoneRules'
	SET @sql = 'ALTER procedure [dbo].[ccsp_ManualCallApplyTimeZoneRules]
@campid as int, @tel varchar(15) as

set nocount on

declare @bIsDaylight bit
declare @revHorario bit
declare @country_id int
declare @iZonas int
declare @sql varchar(MAX)
declare @izonahoraria int
declare @izonahoraria_verano int
DECLARE @iZonasTable TABLE (value int)

create table #TimeZone(
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
izonahoraria int,
izonahoraria_verano int
)

/*** Revisa zona horaria incluyendo de verano ***/
select @izonahoraria = dbo.fnGetTimeZone(@tel,0)
select @izonahoraria_verano = dbo.fnGetTimeZone(@tel,1)

insert into #TimeZone
values (@campid,@tel,@izonahoraria,@izonahoraria_verano)

/*** Valida el pais y la lada configurada ***/
SELECT @country_id = valor  FROM ccSettings  WHERE setting_id = 104

select @revHorario = valor  from ccsettings  where setting_id = 112

/*** Coloca el primer dia de la semana a Lunes ***/
SET DATEFIRST 1

/*** Se revisa si es horario de verano ***/
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

exec @iZonas=ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0
select @iZonas=value from @iZonasTable

/*** Se revisa si la campaña tiene horarios configurados ***/
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid) begin
	if @iZonas = 0
		begin
			SELECT 0 as CanCall,0 as CanCallLaw
			return
		end
end

set @izonahoraria = case @bIsDaylight when 1 then @izonahoraria_verano else @izonahoraria end

set @sql = ''CREATE TABLE #NEW_JOBS(
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS)

INSERT #NEW_JOBS
SELECT cam_id, '' + @tel + ''
FROM #TimeZone
WHERE cam_id = '' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
and (((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0))

if (SELECT count(*) FROM #NEW_JOBS where len(cal_telefono)>0) > 0
	begin
		select 1 as CanCall , 1 as CanCallLaw
	end
else
	begin
		select 0 as CanCall,0 as CanCallLaw
	end

DROP table #NEW_JOBS''

exec(@sql)

DROP table #TimeZone

set nocount off'
	EXEC(@sql)



	---------------------------------------END Jesus Gallardo-----------------------------------------------------------
	
		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
		--EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		--EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
