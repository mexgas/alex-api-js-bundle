ALTER TABLE RepOutCallsDetail
      ADD MessageTime smallint null


ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @IVA INT
declare @country as tinyint


SELECT @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25
select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104


if @country is null set @country = 1

if @action = 1
    begin
        --Borrar lo que esta para no repetir
        delete from RepOutCallsDetail with(rowlock)
        where date >= @from AND date < @to

        INSERT INTO RepOutCallsDetail
        SELECT Call.cal_inicio as [date],
        Call.cal_key as [callKey],
        Call.cal_telefono AS [telephone],
        Call.cal_txfer + call.cal_tring AS [transfer],
        Call.cal_tdialog AS [dialog], 
        ISNULL(Call.cal_tMoh,0) as [nque],
        Call.cal_tnotas AS [wrapup],
        ISNULL( Tipo.[description], '') AS [CallDisposition],
        Call.cal_extension AS [extension],
        Usr.user_id as [userId],
        ISNULL(Usr.login,'systemTranslated_NoUserName') [login],
        ISNULL(Usr.ApellidoPaterno + ' ' + ISNULL(Usr.ApellidoMaterno, '') + ' ' + Usr.Nombres, '') AS [username],
        camps.cam_id as [campaignId],
        ISNULL(camps.cam_descripcion, 'systemTranslated_NoCampaign') as [campaign],
        (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg,0)) / 60.0 )* 60) AS [duration],
        ISNULL(Call.costo,0.00) as [ncost],
        @IVA as iva,
        convert(decimal(10,2),ISNULL(Call.costo,0.00) * (1 + (@IVA / 100.00))) as total,
        case when prov.descrip is not null then prov.descrip when cstoProvedor.descrip is not null then cstoProvedor.descrip else 'systemTranslated_NoCarrier' end as [ByCarrier],
        ISNULL(tl.descrip, 'systemTranslated_Indefinite') as [Calltypes],
        case when Call.cal_manual = 0 then 'systemTranslated_Auto' else 'systemTranslated_Manual' end as [dialType],
        case when cal_whoHung = 0 then 'systemTranslated_Client'
        when cal_whoHung = 1 then 'systemTranslated_Agent'
        else 'systemTranslated_AgentSurvey' end [whoHangUp],
        case when call.califsub_id = 0 then 'systemTranslated_NoSubDisposition' else isnull(sub.califSubDesc, '') end as [subDisposition],
        sta.descripcion as [dialResult],
        Call.cal_id as [calId]
        , datepart(yyyy,Call.cal_inicio) AS [year]
        , datepart(mm,Call.cal_inicio) as [month]
        , datepart(dd,Call.cal_inicio) as [day]
        , datepart(hh,Call.cal_inicio) as [hour]
        , datepart(mi,Call.cal_inicio) as [minutes]
        ,Call.cal_puerto
        , ISNULL(cs.Dato1,'') as [data1]
        , ISNULL(cs.Dato2,'') as [data2]
        , ISNULL(cs.Dato3,'') as [data3]
        , ISNULL(cs.Dato4,'') as [data4]
        , ISNULL(cs.Dato5,'') as [data5]
        , ISNULL(Call.cal_tMsg,0) as [MessageTime]
        FROM ccoCallsOut Call
        LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id=Tipo.calif_id
        INNER JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
        LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]
        LEFT JOIN ccStatusLlamada sta on call.statuscall_id = sta.statuscall_id
        LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]
        LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = @country)
        LEFT JOIN ccTipoCalifSubOut sub on call.califsub_id = sub.califsub_id
        LEFT JOIN ccoDialers di on di.dialer_id = Call.cal_puerto
        LEFT JOIN ccoCallsOutSource cs ON Call.callout_id = cs.callout_id
        LEFT JOIN cstoProvedor on di.provedor_id = cstoProvedor.provedor_id
        WHERE Call.cal_inicio >= @from
        AND Call.cal_inicio < @to
        and cal_manual in (0, 2)
        order by date

    end

go