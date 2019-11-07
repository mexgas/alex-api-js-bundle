CREATE PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters]
@type as int, @sup_id as int = 0 as
set nocount on

declare @fecha_ini datetime
select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

if @type = 1 --Session time
    begin
        SELECT User_id, case
            WHEN sum(convert(int,DateDiff(second, '00:00', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0
                THEN sum(convert(int,DateDiff(second, '00:00', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))
            ELSE sum(convert(int,DateDiff(second, '00:00', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) +
                convert(int,DateDiff(second, '00:00', Convert(VARCHAR(30), getdate(), 14)))
            END as logintime
        FROM ccLogLogin a with(nolock,index(IX_ccLogLogin_4)), ccGenViewRelsSupsAgent b
        where fecha >= @fecha_ini
        and a.User_id = b.agt
        and b.sup = @sup_id
        GROUP BY User_id
    end

if @type = 2 begin--Status agent
    
    ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )

    select User_id,TipoStatusAge_id,sum(segundos) as segundos from (
    SELECT User_id, TipoStatusAge_id, tStatus As segundos
    FROM ccLogAgentesDia a with(nolock,index(IX_ccLogAgentesDia_4))
    inner join TableUserAgent b  on  a.User_id = b.userId   
    WHERE fecha >= @fecha_ini   
    union all   
    select A.User_id,
    case when A.TipoStatusAge_id in(0,1) then 3
    when A.currentStatus in (21,5,9) then 4
    else A.currentStatus end as TipoStatusAge_id,
    DATEDIFF(ss,A.fecha,getdate()) as seconds   
    from ccLogAgentesDia A with(nolock)
    inner join
    (select max(fecha) fecha,USER_ID from ccLogAgentesDia D with(nolock,index(IX_ccLogAgentesDia_4))
    inner join TableUserAgent C on D.User_id=C.userId
    where fecha >= @fecha_ini    
        group by User_id) B
    on A.User_id=B.User_id and A.fecha=B.fecha and A.currentStatus not in (0,-2)

    )x
    group by User_id,TipoStatusAge_id
    ORDER BY User_id

end

if @type = 3 begin

    ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )

    select calls.user_id, calls.total_calls, calls.type_calls, users.login, calls.nCalls, calls.tDialog, calls.tWrapup, calls.tHold 
    from ccusers As users ,
        (
            select calls.User_id, count(*) AS 'total_calls',
            CASE
            WHEN statuscall_id = 15 THEN 5  --OutBound Asignada pero no contestada
            WHEN cal_manual = 2 THEN 3      --OutBound llamada manual
            ELSE 2                          --Llamada de OutBound
            END AS 'type_calls',      
            count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end) tDialog,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end) tWrapup,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold
            from TableUserAgent as tAgent
            inner join ccoCallsOut calls WITH (NOLOCK index(IX_ccoCallsOut_10))   
            on tAgent.userId=calls.User_id
            WHERE statuscall_id <> 11  --OutBound sin estado definitivo
            AND cal_inicio >= @fecha_ini
            GROUP BY User_id, statuscall_id, cal_manual--,tAgent.login
        
            union

            select calls.User_id, count(*) AS 'total_calls',
            CASE
            WHEN statuscall_id = 15 THEN 4  --InBound Asignada pero no contestada
            ELSE 1                          --Llamada de InBound
            END AS 'type_calls',      
            count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end) tDialog,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end) tWrapup,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold

            from TableUserAgent as tAgent
            inner join ccCallsIn calls WITH (NOLOCK index(IX_ccCallsIn_5)) 
            on tAgent.userId=calls.User_id
            WHERE statuscall_id <> 11  --OutBound sin estado definitivo
            AND cal_inicio >= @fecha_ini
            GROUP BY User_id, statuscall_id--,tAgent.login
        ) AS calls
        where users.user_id = calls.user_id     

    end

if @type = 4
    begin
        
        ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )


        select a.user_id, a.login
        from ccusers a (nolock)--, ccGenViewRelsSupsAgent b
        inner join TableUserAgent b on a.User_id=b.userId       
    end

set nocount on