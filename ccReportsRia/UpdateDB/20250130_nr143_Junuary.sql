/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 128

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
SET @version = 143 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

    set @process = 'Add Column 4060 inboundId|campaignId '
    set @sql='if not exists(select * from orColumnsByReport where idReport=4060) begin
    insert into orColumnsByReport values(4060,''inboundId|campaignId'')
end'
    EXEC(@sql)

    ---------------------------------------BEGIN Jesus Gallardo hotfix/125.20231211.0.22---------------------------------------------------------
    set @process = 'CW-9070 Rename Column RepEmailDetail.inboundId'
    set @sql='IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(''RepEmailDetail'')
      AND name = ''inbounid''
)
BEGIN
    EXEC sp_rename ''RepEmailDetail.inbounid'', ''inboundId'', ''COLUMN'';
END
'
    EXEC(@sql)

    set @process = 'ALTER SP ccspRepOutDials Correcion obtener WG'
    set @Sql='ALTER PROCEDURE [dbo].[ccspRepOutDials]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null 
    select @to = getdate()

if @action = 1 
begin
    declare @total decimal(10,2)
        
        

    select @total = count(*) from ccologdials as a WITH(NOLOCK, INDEX(IX_ccoLogDials_8))
    inner join ccTipoResultadoDial as b (NOLOCK) on (a.tipoResDial_id = b.tipoResDial_id)
    where fecha >= @from and fecha < @to        
    and cal_id is not null
        
    delete from RepOutDials where date >= @from AND date < @to
        
        
    ;with tmpRepOutDials as(
    select  DATEADD(HOUR, DATEDIFF(HOUR, 0, fecha), 0) as fecha ,cal_id
    ,a.tipoResDial_id, descripcion,cam_id
    from ccologdials as a WITH(NOLOCK, INDEX(IX_ccoLogDials_8))
    inner join ccTipoResultadoDial as b (NOLOCK) on (a.tipoResDial_id = b.tipoResDial_id)
    where fecha >= @from and fecha < @to        
    and a.cal_id is not null
    )

    
    insert into RepOutDials

    select fecha as [date]      
    ,a.cam_id as campaignId, c.cam_descripcion as campaign
    , isnull(min(d.idwg),1) as workgroupId, isnull(min(wgname),'''') as workgroup, isnull(min(c.idarea),1) as areaId, isnull(min(areaname),'''') as area
        
    ,a.tipoResDial_id, descripcion,
    descripcion + ''_Count'' as descripcion_count,
    count(*) as count,
    descripcion + ''_Avg'' as descripcion_avg,
    convert(decimal(10,2), (count(*)/@total)*100.00) as avg,
    datepart(yyyy,fecha) AS [year],
    datepart(mm,fecha) as [month],
    datepart(dd,fecha) as [day],
    datepart(hh,fecha) as [hour],
    0 as [minutes]
    from  tmpRepOutDials as a
    left join ccCamps as c (NOLOCK) on (a.cam_id = c.cam_id)
    left join ccRIACampEspWG as d (NOLOCK) on a.cam_id = d.IdCampEsp and d.tipo = 1 
    left join ccRIACat_WorkGroup as e (NOLOCK) on (d.idwg = e.idwg)
    left join ccRIAAreaWorkGroup as f (NOLOCK) on (e.idwg = f.idwg)
    left join ccRIACat_Areas as g (NOLOCK) on (c.idarea = g.idarea)     
    group by fecha ,        
    a.cam_id, c.cam_descripcion, a.tipoResDial_id, descripcion  
    
end'
    
    EXEC(@Sql)

     set @process = 'DEV1-459 alter SP ccspRepOutAnswCalls se quita with index '
    set @sql='ALTER PROCEDURE [dbo].[ccspRepOutAnswCalls]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()
                            
    delete RepOutAnswCalls with(rowlock)
    where [date] between @from and @to

    ;with   
    co as(
    select
    convert(date,cal_inicio,121) [date],
    co.cam_id campaignId, count(*) total, 
    COUNT(CASE WHEN(statusCall_id = 16)THEN co.cal_id ELSE NULL END) nasig_tl,
    COUNT(CASE WHEN(statuscall_id = 15)THEN co.cal_id ELSE NULL END) nasig_nc,
    COUNT(CASE WHEN(statuscall_id = 13)THEN co.cal_id ELSE NULL END) nAnswered,
    COUNT(CASE WHEN(statuscall_id = 11)THEN co.cal_id ELSE NULL END) nassigned,
    COUNT(CASE WHEN(statuscall_id in (6,4))THEN co.cal_id ELSE NULL END) nabdn_sis
    from ccocallsout co with(nolock,index(IX_ccoCallsOut13))    
    where cal_inicio between @from and @to 
    group by convert(date,cal_inicio,121),co.cam_id
    ) 
    ,wgCalId as(
    
        select campaignId,isnull(min(wg.IDWG),1) IDWG
        from co o 
        left join ccRIACampEspWG wg on o.campaignId =wg.IdCampEsp and wg.Tipo=1
        group by campaignId
    )
    

    insert RepOutAnswCalls
    select 
    [date], abnd.campaignId, ca.cam_descripcion campaign, 
    wg.IDWG workgroupId, e.WGName workgroup, isnull(f.IDArea,0) areaId, g.AreaName area, total,
    cast(((nasig_tl*100.0)/total) as decimal(5,2)) asig_tl,
    cast(((nasig_nc*100.0)/total) as decimal(5,2)) asig_nc,
    cast(((nAnswered*100.0)/total) as decimal(5,2)) Answered,
    cast(((nassigned*100.0)/total) as decimal(5,2)) assigned,
    cast(((nabdn_sis*100.0)/total) as decimal(5,2)) abdn_sis
    from co abnd    
    left join cccamps ca on ca.cam_id=abnd.campaignId 
    left join wgCalId wg on abnd.campaignId=wg.campaignId
    left join ccRIACat_WorkGroup as e on e.idwg = wg.idwg
    left join ccRIAAreaWorkGroup as f on f.idwg = e.idwg
    left join ccRIACat_Areas as g on g.idarea = f.idarea
                            
end'
    EXEC(@sql)

    set @process = ''
    set @sql=''
    EXEC(@sql)

---------------------------------------END Jesus Gallardo hotfix/125.20231211.0.22---------------------------------------------------------

---------------------------------------------------- BEGIN TT14523 Luis Zamora 127.20250130.0.5 --------------------------------------------------------------
 SET @process = 'Delete view RepViewSummary'
SET @sql = '
IF EXISTS (SELECT * FROM sys.views WHERE name = N''RepViewSummary'')
BEGIN
    DROP VIEW RepViewSummary;
END'
EXEC(@sql)
SET @process = 'TT14523 --Reportes-Error en reporte de resumen de agentes  VIEW RepViewSummary'
SET @sql = '
        CREATE VIEW [dbo].[RepViewSummary] AS -- Correccion del Ticket TT14523
        select 
        [date]
        ,[login]
        ,[user]
        ,sessionTime
        ,loginMktTime
        ,logoutMktTime
        ,0 callTengaged
        ,ndTime
        ,NCallsOut
        ,NCallsIn
        ,NCallsCorta
        ,NAtend
        ,NNoCalif
        ,Available
        ,0 avgCallTengaged
        ,twrapup
        ,userId
        ,0 TypeNotReady
        ,'''' descripcion
        ,''_Time'' descripcion_time
        ,0 [time]
        ,0 transferStatus
        ,0 ringingTime
        ,0 unknownStatus
        ,0 otherStatus
        ,0 failureStatus
        ,0 chatTengaged
        ,0 undefinedTime
        ,0 dialingStatus
        ,null TipoReadyAuxiliarId
        ,'''' auxiliarRedy_descripcion
        ,'''' descripcion_auxiliarRedyTime_time
        ,0 auxiliarRedyTime
        from RepAgentSummary_VersionAmatech
        union
        select date
        ,login
        ,[user]
        ,sessionTime
        ,loginMktTime
        ,logoutMktTime
        ,callTengaged
        ,ndTime
        ,NCallsOut
        ,NCallsIn
        ,NCallsCorta
        ,NAtend
        ,NNoCalif
        ,Available
        ,avgCallTengaged
        ,twrapup
        ,userId
        ,TypeNotReady
        ,descripcion
        ,descripcion_time
        ,time
        ,transferStatus
        ,ringingTime
        ,unknownStatus
        ,otherStatus
        ,failureStatus
        ,chatTengaged
        ,undefinedTime
        ,dialingStatus
        ,TipoReadyAuxiliarId
        ,auxiliarRedy_descripcion
        ,descripcion_auxiliarRedyTime_time
        ,auxiliarRedyTime
        from RepAgentSummary'
        EXEC(@sql)
 -----------------------------------------------------------------END Luis Zamora---------------------------------------------------------------------

    set @process = 'Alter SP '
    set @sql=''
    EXEC(@sql)

   
	
	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
