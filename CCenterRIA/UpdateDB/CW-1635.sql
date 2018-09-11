/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

 
/*
Author: 
		
Date: 2018/08/21
Description:

Release  120.24_20180906

Database: CCenterRia
Required version: 120.14

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120
set @versionfix = 24


/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 22
	begin
		begin tran
		begin try

		set @process = 'CW-1635 version 120.24--- '
		set @Sql= 'ALTER procedure [dbo].[ccsp_RIAADMgetAbandonoSalida]
@User_id smallint = null,
@cam_id smallint = null
AS 
set nocount on
declare @fecha datetime, @ultimo datetime
declare @lastAband float

select @ultimo = valor from ccSettings where setting_id = 25
if datediff(ss, @ultimo, getdate()) > 300 
begin
	set @fecha = getdate()
	update ccsettings set valor = convert(varchar(19), @fecha, 121) where setting_id = 25

	-- calcula abandono para la grafica
	exec ccsp_RIAADMgetAbandonoSalida_Fix	
end

if @User_id is not null
begin
	select distinct h.cam_id, isnull(h.AbndPctg,0)
	from ccAbandonoSalida h inner join ccSupervisorCam i on h.cam_id = i.cam_id
	where i.user_id = @User_id

	return(0)
end

if @cam_id is not null
begin
	select top 1 @lastAband = AbndPctg from ccAbandonoSalida_Chart
	where cam_id = @cam_id order by timestamp desc

	select @cam_id as cam_id, x.cam_descripcion, isNull(@lastAband,0) as LastAbndPctg, x.ts as timestamp, x.AbndPctg from 
	(
		select top 20 C.cam_descripcion,
		convert(varchar(4), A.Timestamp, 108)+''0'' as ts, isnull(A.AbndPctg,0) as AbndPctg
		from ccAbandonoSalida_Chart A 
		join ccCamps C on A.cam_id = C.cam_id
		Where A.cam_id=@cam_id
		order by timestamp desc
	)x order by x.ts

	return(0)
end

set nocount off'
	EXEC(@Sql)

		set @process = 'CW-1635 version 120.24_'
		set @Sql= 'ALTER proc [dbo].[ccsp_RIAADMgetAbandonoSalida_Fix]
as
set nocount on
declare @fecha smalldatetime, @fecha2 smalldatetime
declare @i int



declare @tempChart table (
cam_id	int,
countAbnd int,
countAll int,
timestamp	smalldatetime
)

set @fecha = convert(varchar(10), getdate(), 112)+'' ''+convert(varchar(4), getdate(), 108)+''0''
set @i =0
while @i < 30
begin
	set @fecha2 = dateadd( mi, -10, @fecha)

	insert into @tempChart
	select ccCamps.cam_id, x.countAbnd,x.countAll, @fecha2 from ccCamps
	left join
	(
		select cam_id,count(case statuscall_id when 6 then 1 else null end ) as countAbnd,
		COUNT(*) as countAll		
		from ccoCallsOut
		with( index(IX_ccoCallsOut_2) )
		where cal_manual in (0,2 ) and cal_inicio >= @fecha2 and cal_inicio < @fecha
		and cam_id=3
		group by cam_id
	)x on x.cam_id = ccCamps.cam_id
	where ccCamps.idArea is not null

	set @fecha = @fecha2
	set @i = @i +1
end

truncate table ccAbandonoSalida_Chart

insert into ccAbandonoSalida_Chart
select cam_id,
CONVERT(decimal(10,2),
case when countAll=0 then 0 else countAbnd*100.00/countAll end
),[timestamp]
  from @tempChart order by cam_id 

truncate table ccAbandonoSalida  
  
 insert into ccAbandonoSalida
 select cam_id,
 CONVERT(decimal(10,2),
 SUM(countAbnd*100.0)/sum(countAll) 
 ) as AbndPctg 

 from @tempChart
 group by cam_id
 
set nocount off'
		EXEC(@Sql)


	

	


		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix 

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
