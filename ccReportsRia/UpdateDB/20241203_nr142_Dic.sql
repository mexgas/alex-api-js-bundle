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
SET @version = 142 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY


    set @process = 'Alter SP ccspRepMKTAgentes'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepMKTAgentes]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
 set nocount on
if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
        select @to = getdate()

if @action = 1 begin

    
delete from dbo.RepMKTAgentes where date >= @from AND date < @to


;with timeAgenteTransfer as(
select A.timegroup,A.user_id 
,case when A.statusCall_id=13 and A.ntotal>0 then 1 else 0 end nacd 
,case when A.statusCall_id=13 and A.ntotal>0 and A.tnotes>0 then 1 else 0 end nacw
,case when l.modo in (3,4) and l.tipo=1 then [dbo].[AccountInterval](l.dateIni,l.dateEnd,l.timegroup,l.timegroup_next,1) else 0 end cayuda
,case when l.modo in (0,3,4) and l.tipo=1 then [dbo].[AccountInterval](l.dateIni,l.dateEnd,l.timegroup,l.timegroup_next,1) else 0 end nxfersal
,case when A.statuscall_id = 13 and A.ntotal>0 then A.tque + A.txfer + A.tring else 0 end tresp
,case when A.statusCall_id=13 then A.tdialog else 0 end tacd
,case when A.statusCall_id=13 then A.tnotes else 0 end tacw
from tmpTimesInboundData A
left join TmpTimesccLogtransfers l on l.callId=A.cal_id and l.tipo=1 and A.timegroup=l.timegroup
), timeAgenteTransferGroup as(

select A.timegroup,A.user_id 
,sum(nacd) nacd
,sum(nacw) nacw
,sum(cayuda) cayuda
,sum(nxfersal) nxfersal
,sum(tresp) tresp
,sum(tacd) tacd
,sum(tacw) tacw
from timeAgenteTransfer A
group by A.User_id,A.timeGroup
), timeAgenteStatus as(

select timeGroup,userId as user_id
,sum(case when TipoStatusAge_id = 7 then tstatus else 0 end) t_otra
,sum(case when TipoStatusAge_id = 2 then tstatus else 0 end) t_aux
,sum(case when TipoStatusAge_id = 3 then tstatus else 0 end) t_disp
,sum(tstatus) t_pers
from tmpccLogAgentesDia
group by userId,timeGroup
), cte as(

select isnull(acd.timegroup,tready.timegroup) date,
isnull(acd.user_Id,tready.User_id) User_id,
isnull(acd.nacd,0) [CallsperACDGroupD],
isnull(acd.tacd,0) [tACD],
isnull(acd.tresp,0) [tAgent],
isnull(tready.t_otra,0) [oHour],
isnull(tready.t_aux,0) [tAux],
isnull(tready.t_disp,0) [readyTime],
isnull(tready.t_pers,0) [tPer],
isnull(acd.cayuda,0) [Ayuda],
isnull(acd.nxfersal,0) [nxfer],
isnull(acd.nacw,0) [nacw],
isnull(acd.tACW,0) [tACW],
isnull(datepart(yyyy,convert(varchar(24),acd.timegroup,121)),0) year,
isnull(datepart(mm, acd.timegroup),0) month,
isnull(datepart(dd, convert(varchar(24),acd.timegroup,121)),0) day,
isnull(datepart(hh, convert(varchar(24),acd.timegroup,121)),0) hour,
isnull(datepart(mi,convert(varchar(24),acd.timegroup,121)),0) minutes
from timeAgenteTransferGroup acd 
full join timeAgenteStatus tready on tready.user_id=acd.user_id and tready.timegroup=acd.timegroup
)

insert into RepMKTAgentes(date,userId,login,agentName,CallsperACDGroupD,tACD,tAgent,oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW,year,month,day,hour,minutes)
select convert(varchar(24),date, 121) date,a.user_id,u.Login,
isnull(u.apellidopaterno+u.apellidomaterno+u.nombres,'''') agt_name,
CallsperACDGroupD,tACD,[tAgent],oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW, [year], [month],[day],[hour],[minutes]
from cte a
inner join ccUserView as u on a.user_id=u.user_id
order by date,Login

end
'
    EXEC(@sql)

    set @process = 'Alter SP DROP INDEX IX_RepMKTAgentes_date ON dbo.RepMKTAgentes'
    set @sql='if exists (select * from sys.indexes where name = N''IX_RepMKTAgentes_date'' and object_id = OBJECT_ID(N''RepMKTAgentes''))
begin
   DROP INDEX IX_RepMKTAgentes_date ON dbo.RepMKTAgentes;
end'
    EXEC(@sql)

    set @process = 'Alter SP ALTER TABLE RepMKTAgentes ALTER COLUMN date DATETIME;'
    set @sql='IF Not EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = ''RepMKTAgentes'' -- Nombre de la tabla
    AND COLUMN_NAME = ''date'' -- Nombre de la columna
    AND DATA_TYPE = ''datetime'' -- Tipo de dato esperado
)
BEGIN
    ALTER TABLE RepMKTAgentes ALTER COLUMN date DATETIME;
END'
    EXEC(@sql)

    set @process = 'CREATE NONCLUSTERED INDEX [IX_RepMKTAgentes_date] ON [dbo].[RepMKTAgentes]'
    set @sql='if not exists (select * from sys.indexes where name = N''IX_RepMKTAgentes_date'' and object_id = OBJECT_ID(N''RepMKTAgentes''))
begin
    CREATE NONCLUSTERED INDEX [IX_RepMKTAgentes_date] ON [dbo].[RepMKTAgentes]
(
    [date] ASC
)
end'
    EXEC(@sql)

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
