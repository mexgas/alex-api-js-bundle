/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.37

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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 38
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'fix/CW-7678 Alter SP ccsp_GetAgentIndividualCounters if @type = 5 se modifica para que tengamos los tiempos cada login'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters]
@type as int, @sup_id as int = 0 as
set nocount on

declare @fecha_ini datetime
select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

if @type = 1 --Session time
    begin
        SELECT User_id, case
            WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0
                THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))
            ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) +
                convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
            END as logintime
        FROM ccLogLogin a with(nolock,index(IX_ccLogLogin_4)), ccGenViewRelsSupsAgent b
        where fecha >= @fecha_ini
        and a.User_id = b.agt
        and b.sup = @sup_id
        GROUP BY User_id
    end

else if @type = 2 begin--Status agent
    
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

else if @type = 3 begin

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
            select calls.User_id, count(*) AS ''total_calls'',
            CASE
            WHEN statuscall_id = 15 THEN 5  --OutBound Asignada pero no contestada
            WHEN cal_manual = 2 THEN 3      --OutBound llamada manual
            ELSE 2                          --Llamada de OutBound
            END AS ''type_calls'',      
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

            select calls.User_id, count(*) AS ''total_calls'',
            CASE
            WHEN statuscall_id = 15 THEN 4  --InBound Asignada pero no contestada
            ELSE 1                          --Llamada de InBound
            END AS ''type_calls'',      
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

else if @type = 4
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
else if @type = 5
    begin          
	declare @users table(userId int primary key)


	if exists(select * from ccUsers_Roles where User_id=@sup_id and Rol_id=1 ) begin
		insert into @users
		select user_id from ccUsers where TipoUser_id=1
	end
	else begin
		
		insert into @users
		select distinct wgAgt.User_id as userId --,usr.login 
		from ccriaworkgroupusers wgAdmin
		inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
		inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
		where 
		wgAdmin.User_id=@sup_id 
	end

	SELECT cast(User_id AS INT) UserId
		,sum(CASE WHEN TipoStatusAge_id = 2 THEN tStatus ELSE 0 END) NotReady
		,sum(CASE WHEN TipoStatusAge_id = 3 THEN tStatus ELSE 0 END) Ready
		,sum(CASE WHEN TipoStatusAge_id = 4 THEN tStatus ELSE 0 END) Dialog
		,sum(CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE 0 END) XFer
		,sum(CASE WHEN TipoStatusAge_id = 6 THEN tStatus ELSE 0 END) Wrapup
		,sum(CASE WHEN TipoStatusAge_id = 7 THEN tStatus ELSE 0 END) Other
		,sum(CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE 0 END) Ringing
		,sum(CASE WHEN TipoStatusAge_id = 11 THEN tStatus ELSE 0 END) Problem
		FROM ccLogAgentesDia A with(nolock)
		inner join @users B on A.User_id=B.userId
		WHERE fecha >= @fecha_ini
			AND TipoStatusAge_id > 0
		GROUP BY User_id 

  
    end
set nocount on

';
		EXEC(@sql);

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
