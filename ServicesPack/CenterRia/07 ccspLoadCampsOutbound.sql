USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccspLoadCampsOutbound]    Script Date: 09/03/2026 08:58:46 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccspLoadCampsOutbound]
    @action int,  
    @nType INT=0,
    @agentId int=0,
    @campId int=0
AS
declare @sql nvarchar(max)

if @action= 0 begin
    set @sql='SELECT cc.cam_id
                ,cam_descripcion
                ,cam_activo
                ,cam_ModoManual
                ,cam_modpredictivo
                ,cam_callratio
                ,cam_procesando
                ,convert(VARCHAR(8), cast(cam_maxdlrxage AS FLOAT)) cam_maxdlrxage
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
                ,ISNULL(cc.CampType, 0) AS CampType
                ,ISNULL(cc.CamCanceled, 4) AS CamCanceled
                ,ISNULL(ex.SimultaneousRecs, 0) AS SimultaneousRecs
                ,ISNULL(cva.idAgent, 0) AS IdAgentVirtual
                                ,ISNULL(cva.nameAgent, '''') AS NameAgentVirtual
                ,ISNULL(cva.concurrentSessionsLimit, 0) AS NumberSessions
                FROM ccCamps cc (NOLOCK) 
                LEFT JOIN ccCampsExtend ex (NOLOCK) ON ex.cam_id = cc.cam_id
                LEFT JOIN ccVirtualAgent cva ON cva.idCampaign = cc.cam_id AND cva.campType = 1
                WHERE cc.CampType not in (5,7)'
    if @nType=2 
        set @sql=@sql+' AND cc.cam_bNew = 2 '
    else if @nType=3
        set @sql=@sql+' AND cc.cam_bNew in (1,2) '
    set @sql=@sql+' ORDER BY cc.cam_descripcion'
    --print(@sql)
    exec (@sql)
end
else if @action= 1 begin
    set @sql='SELECT distinct C.cam_id, C.cam_descripcion, Prioridad, A.Login, A.User_id, Skill
        from ccCamps C (nolock) join ccCampsAgente CA on C.cam_id = CA.cam_id AND CampType not in (5,7)
        join ccUsers A (nolock) on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1 '
    if @nType=2 
        set @sql=@sql+' and C.cam_bNew=2'
    else if @nType=3
        set @sql=@sql+' and C.cam_bNew in (1,2)'
    if @campId > 0
        set @sql=@sql+' where C.cam_id = ' + cast(@campId as varchar(5))
    set @sql=@sql+' order by C.cam_id, CA.Prioridad'
    --print(@sql)
    exec (@sql)
end
else if @action= 2 begin
    set @sql='select distinct A.Login, Prioridad, C.cam_id, Skill
            from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id AND CampType not in (5,7)
            join ccUsers A  on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1
            Where A.User_id = @agentId
            order by C.cam_id, CA.Prioridad'
    --print(@sql)
    exec sp_executesql @sql, N'@agentId int', @agentId
end
else if @action= 3 begin
    set @sql='SELECT dialer_id, C.cam_id FROM ccoDialerCamp R (nolock) join ccCamps C (nolock) on R.cam_id=C.cam_id AND CampType not in (5,7) '
    if @nType=2 
        set @sql=@sql+' and C.cam_bNew = 2 '
    else if @nType=3
        set @sql=@sql+' and C.cam_bNew in (1,2) '
    if @campId > 0
        set @sql=@sql+' where C.cam_id = ' + cast(@campId as varchar(5))
    set @sql=@sql+' ORDER BY cam_descripcion'
    --print(@sql)
    exec (@sql)
end
else if @action= 4 begin
    set @sql='
    declare @today datetime

    set @today=CONVERT(date,GETDATE(),121)

    SELECT A.Login, A.TipoLLamadas, A.user_id 
    FROM ccUsers A 
    INNER JOIN ccTipoUsers T on A.TipoUser_id=T.TipoUser_id   
    WHERE A.TipoUser_id =1 AND A.Status=1 AND A.User_id = CASE WHEN @agentId = 0 THEN A.User_id ELSE @agentId END
    ORDER BY Login'
    exec sp_executesql @sql, N'@agentId int', @agentId
end

