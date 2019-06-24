/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.35

Se agrega la tarea
cw-2915
cw-3001
CW-3201
CW-3032

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
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 37
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 36
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'cw-3045 Alter SP ccsp_AvrsSyncronization'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization] @action SMALLINT, @maxRecordsToTransfer INT = 10, @id INT = 0
AS
SET NOCOUNT ON

IF @action = 1
BEGIN
	DECLARE @countrId INT

	SET @countrId = 1

	SELECT @countrId = valor
	FROM ccSettings
	WHERE setting_id = 104
	

	SELECT TOP (@maxRecordsToTransfer) call.cal_id, user_id, call.Inbound_id, call.calif_id, cast(cal_extension AS INT) AS cal_extension, cal_inicio, cal_ANI AS phone, 
	cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration, cal_key, 0 AS cal_manual, cal_puerto, dni_id, fvalida, 
	cal_whohung, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id, 
	CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh, 
	dateadd(ss, cal_tDialog, cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, ccInbound.prefijo, 1 AS isCallRecord
	FROM ccCallsIn AS call
	INNER JOIN ccInbound ON ccInbound.Inbound_id = call.Inbound_id
	INNER JOIN ccAVRSTransfer avrs ON call.cal_id = avrs.cal_id AND avrs.tipo = 0
	LEFT JOIN (
		SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
		FROM ccLogTransfers
		WHERE tipo = 1
		GROUP BY cal_id, tipo
		) trans ON call.cal_id = trans.cal_id
	
	UNION
	
	SELECT TOP (@maxRecordsToTransfer) call.cal_id AS CallId, user_id AS UserId, call.cam_id AS camAcdId, cast(call.calif_id AS SMALLINT) AS califId, cast(cal_extension AS INT) AS extension, 
	cal_inicio, cal_telefono, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration, cal_key, cal_manual, cal_puerto, 0 AS dni_id, fvalida, 
	cal_whohung, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id, 
	CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh, 
	dateadd(ss, cal_tDialog, cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, camps.prefijo, dbo.EnableCallRecord(camps.call_record, @countrId, cal_telefono) AS isCallRecord
	FROM ccoCallsOut AS call
	INNER JOIN ccCamps camps ON camps.cam_id = call.cam_id
	INNER JOIN ccAVRSTransfer avrs ON call.cal_id = avrs.cal_id AND avrs.tipo = 1
	LEFT JOIN (
		SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
		FROM ccLogTransfers
		WHERE tipo = 2
		GROUP BY cal_id, tipo
		) trans ON call.cal_id = trans.cal_id
END
ELSE IF @action = 2
BEGIN
	DELETE
	FROM ccAVRSTransfer
	WHERE id = @id
END
'
		EXEC (@Sql)

		SET @process = 'cw-3045 Alter SP overFlow description'
		SET @Sql = 'ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]
@type smallint = null,
@inbound_id smallint = null,
@calif_id smallint = null,
@cam_id smallint = null
AS
set nocount on
create table #CalifTemp (
id int identity,
tipo integer,
Cam_id varchar(60),
Calificacion varchar(60),
subCalificacion varchar(60) null,
calif_id smallint null,
Total int,
iTotal4Campaign int null)

declare @typeACD smallint --= 0
declare @today datetime
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)

set @today = convert(datetime, convert (varchar(11), getdate(), 101))
select @typeACD = chat from ccInbound  where Inbound_id = @inbound_id


select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end,
@nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
from ccsettings where setting_id = 27 -- 0 esp

---------------OUT ----------------------------
if @type=0 begin
    insert into #CalifTemp
    select 0 as tipo,co.cam_id as cam_id,
    case when co.statuscall_id = 13
	   then case when description is not null
	   then description else @nIdioma end
    else case when sll.descripcion is not null then ''cw:'' + sll.descripcion
    else ''cw:'' + @nIdioma
    end end as Calificacion
    ,0 as subCalificaion,
    co.calif_id,count(*) cantidad,0 as iTotal4Campaign
    from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
    left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
    left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
    left join ccCamps ci on ci.cam_id = co.cam_id
    where co.cal_inicio > @today
    group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id

    select tipo,Cam_id, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end as Calificacion,
    case when count(subCalificacion)>0 then 1 else 0 end subCalificacion, calif_id,sum(Total) as Total
    from #CalifTemp
    group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end, Cam_id, iTotal4Campaign,calif_id

end
---------------IN ----------------------------
else if @type = 1 begin

    if @typeACD = 0 begin  --Calls
    insert into #CalifTemp
    select @typeACD as tipo,cci.inbound_id as cam_id, description as Calificacion
		  ,case when count(ci.califSub_id) >0 then 1 else 0 end as subCalificacion,ci.calif_id
		  ,count(*) as total,0 as iTotal4Campaign
		  from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
		  left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		  left join ccInbound cci on cci.inbound_id = ci.inbound_id
		  left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
		  where ci.cal_inicio > @today and statuscall_id = 13	and cci.Inbound_id=@inbound_id
		  group by description, cci.inbound_id,ci.calif_id

    if (select valor from ccSettings where setting_id = 78) = 0 begin
	   update #CalifTemp set iTotal4Campaign = 0
    end
    else begin
    update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign
	   from (
		  select cam_id, sum(A.Total) iTotal4Campaign from #CalifTemp A group by cam_id) t
	   inner join #CalifTemp c on t.cam_id = c.cam_id
    end
    end
    else if @typeACD = 1 begin--Chats
    insert into #CalifTemp(tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
    select @typeACD as tipo, inboundId as Cam_id, [description] as Calificacion,
		  case when sum(case when a.subDisposition = 0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
		  a.disposition as calif_id, count(disposition) as Total
		  from ccriachats a
		  left join ccTipoCalif b on a.disposition=b.calif_id
	   where a.chatDate > @today and
	   a.chatStatus=4 and a.inboundId=@inbound_id
    group by inboundId, [description],disposition
    end
    else if @typeACD = 3 begin ---Mail
    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
    select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
    case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
    relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
    from conversation conver
    inner join message mess on mess.conversationId = conver.conversationId
    left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
    where mess.date > @today and
    conver.inboundId=@inbound_id and mess.messageStatusId >= 5
    group by conver.inboundId,relmesdis.dispositionId,disp.Description

    end
    else if @typeACD = 4 begin --calif twetter
    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
    select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
    case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
    relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
    from conversationTwitter conver
    inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
    left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
    where mess.date > @today and
    conver.inboundId=@inbound_id and mess.messageStatusId >= 5
    group by conver.inboundId,relmesdis.dispositionId,disp.Description

    end
    select camtemp.tipo,camtemp.cam_id,
    case when tipcal.Description is not null then tipcal.Description else @nIdioma end as Calificacion,
    camtemp.subcalificacion,camtemp.calif_id,camtemp.total
    from #CalifTemp camtemp
    left join ccTipoCalif tipcal on camtemp.calif_id =  tipcal.calif_id
end
-------------------SUBCALIFICACIONES IN-------------------
else if @type = 2 begin
    if @typeACD = 0 begin --Calls
    select @typeACD as tipo,cci.inbound_id as cam_id,  [description] as Calificacion,
    isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
    from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
    left join ccTipoCalif ca on ci.calif_id = ca.calif_id
    left join ccInbound cci on cci.inbound_id = ci.inbound_id
    left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
    where ci.cal_inicio > @today
    and ci.inbound_id = @inbound_id  and statuscall_id = 13  and ci.calif_id = @calif_id
    group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id
    end
    else if @typeACD = 1 begin --Chat
    select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
		  isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
		  from ccriachats a
		  left join ccTipoCalif b on a.disposition=b.calif_id
		  left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
		  where a.chatDate > @today and
		  a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id
		  group by inboundId, [description],ctcs.califSubDesc
    end
    else if @typeACD = 3 begin --Mail
    select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
    isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
    from conversation conver
    inner join message mess on mess.conversationId = conver.conversationId
    left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
    left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
    where mess.date > @today and
    mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
    group by conver.inboundId,disp.Description,subDisp.califSubDesc


    end
    else if @typeACD = 4 begin --Twitter
    select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
    isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
    from conversationTwitter conver
    inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
    left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
    left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
    where mess.date > @today and
    mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
    group by conver.inboundId,disp.Description,subDisp.califSubDesc
    end

end
-------------------SUBCALIFICACIONES OUT-------------------
else if @type = 4 begin
    select 0 as tipo,co.cam_id as cam_id,
    case when co.statuscall_id = 13
    then case when description is not null
    then description else @nIdioma end
    else
    case when sll.descripcion is not null
    then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma
    end
    end as Calificacion,
    isnull(cso.califSubDesc,@nIdiomaSub) ,count(cso.califSub_id) cantidad
    from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
    left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
    left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
    left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
    left join ccCamps ci on ci.cam_id = co.cam_id
    where co.cal_inicio > @today
    and co.cam_id = @inbound_id
    and co.calif_id = @calif_id
    group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
end


drop table #CalifTemp
set nocount off'
		EXEC (@Sql)



		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
