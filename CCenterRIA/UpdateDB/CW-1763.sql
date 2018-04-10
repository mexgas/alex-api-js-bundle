/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Alan Minor
Date: 2018/04/02
Description:



Database: CCenterRia
Required version: 119.119.124

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

set @version = 119--**********actualizar a 119 sin fix
set @versionfix = 131
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version --and  @actualVersionFix >= 123
	begin
		begin tran
		begin try

	 
		set @process = 'CW-1763 Version 119.124 --Create Index ccRIAWorkGroupUsers.IX_ccRIAWorkGroupUsers_II'
    	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_ccRIAWorkGroupUsers_II'' and object_id = OBJECT_ID(N''ccRIAWorkGroupUsers''))
    begin
        Create index IX_ccRIAWorkGroupUsers_II on ccRIAWorkGroupUsers (User_id)
    end'
    	EXEC(@Sql)

    	set @process = 'CW-1763 Version 119.124 -- Alter ccsp_GetAgentIndividualCounters'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters]
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

set nocount on'
    	EXEC(@Sql)

    	set @process = 'CW-1763 Version 119.124 -- Alter ccsp_OUTCancelJobTimeZone'
    	set @Sql= 'ALTER procedure [dbo].[ccsp_OUTCancelJobTimeZone]
@callout_id int,
@status int,
@minutesCb int = 0
as
set nocount on
if @minutesCb = 0
	set @minutesCb = 5

update ccoWorkingTable with(rowlock) set cal_status=@status, cal_fechaDial= dateadd(mi, @minutesCb, cal_fechaDial) 
where callout_id=@callout_id

set nocount off'
    	EXEC(@Sql)

    	set @process = 'CW-1763 Version 119.124 -- '
    	set @Sql= 'ALTER proc [dbo].[ccsp_RIA_mnuReciclar]
@cam_id int,
@type tinyint, -- 0:recicla todo / 1:recicla no efectivos / 2:recicla los efectivos calificados / 
--				  3:recicla no efectivos y efectivos calificados (1 y 2) / 4:Recicla status "Finalizado"
@calif_id varchar(1500) = null,
@user_id as integer = null,
@list_id as integer = 0
as
set nocount on
declare @Valor int, @SQL varchar(4000)
select @Valor = valor from ccSettings with(nolock) where setting_id = 60

If @Valor = 1
 begin
	declare @ultimoReciclaje datetime, @siguienteReciclaje datetime, @difDateAdd datetime
	select @Valor = valor from ccSettings with(nolock) where setting_id = 59
	
	If @Valor = 0 
	 begin
		select -2, ''No hay un limite para volver a reciclar''
		return(0)
	 end

	select top 1 @ultimoReciclaje = max(fecha) from ccLogReciclaje where cam_id = @cam_id

	-- Se crea log, ccsp_ADMlogReciclaje para que esta informacion la traiga, por que no se esta metiendo
	select @user_id = isnull(@user_id, ''0''), @calif_id = isnull(@calif_id, ''0'')
	
	exec dbo.ccsp_ADMlogReciclaje @cam_id, @user_id, @type, @calif_id

	If @ultimoReciclaje is not null and getdate() < DateAdd(n, @Valor, @ultimoReciclaje)
	begin
		select -3, ''No se puede realizar un reciclaje hasta que pase el tiempo limite''
 		return(0)
	end

 end

if @type=0
 begin
	if @list_id = 0 begin
		create table #allReciycled(callout_id int not null primary key)

		insert into #allReciycled
		select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) where cam_id = @cam_id and cal_status = 1		

		update ccoCallBacks with(rowlock)
		set [status] = 3, schedulerStatus = 1
		from ccoCallBacks a with(index([IX_ccoCallBacks6])) join #allReciycled b on (a.callout_id = b.callout_id)
		where [status] = 0

		update ccoWorkingTable with(rowlock) 
		set cal_status = 0 
		from ccoWorkingTable a join #allReciycled b on (a.callout_id = b.callout_id)

		drop table #allReciycled
	end
	else begin
		create table #allListReciycled(callout_id int not null primary key)

		insert into #allListReciycled
		select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_10),nolock) where cam_id = @cam_id and cal_status = 1 and list_id = @list_id		

		update ccoCallBacks with(rowlock)
		set [status] = 3, schedulerStatus = 1
		from ccoCallBacks a with(index([IX_ccoCallBacks6])) join #allListReciycled b on (a.callout_id = b.callout_id)
		where [status] = 0

		update ccoWorkingTable with(rowlock) 
		set cal_status = 0 
		from ccoWorkingTable a join #allListReciycled b on (a.callout_id = b.callout_id)

		drop table #allListReciycled
	end

	return(0)
 end

if @type in(1,3)
 begin
	
	update ccoCallBacks with(rowlock)
	set [status] = 3, schedulerStatus = 1
	where callout_id in (select distinct(callout_id)
						 from ccoWorkingTable with(index(IX_ccoWorkingTable_12),nolock)
						 where cam_id = @cam_id 
						 and cal_status = 1 
						 and tiporesdial_id <> 1
						 and callout_id in (select distinct(b.callout_id)
												from ccologdials a with (index (IX_ccoLogDials_4),nolock) 
												left join ccocallsout b with(index(IX_ccoCallsOut12),nolock)
												on a.callout_id = b.callout_id
												and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
												where calif_id = 0
												and calif_id is not null))
	and [status] = 0

	update ccoWorkingTable with(rowlock)
	set cal_status = 0, tiporesdial_id = 0 
	where cam_id = @cam_id 
	and cal_status = 1 
	and tiporesdial_id <> 1
	and callout_id in (select distinct(b.callout_id)
						   from ccologdials a with (index (IX_ccoLogDials_4),nolock) 
						   left join ccocallsout b with(index(IX_ccoCallsOut12),nolock)
						   on a.callout_id = b.callout_id
						   and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
						   where calif_id = 0
						   and calif_id is not null)
 end

if @type in(2,3)
 begin
	
	Set @SQL = ''update ccoCallBacks with(rowlock) set [status] = 3, schedulerStatus = 1'' +
	 ''where callout_id in ('' +
	 ''select distinct(callout_id) from ccoWorkingTable with(index(IX_ccoWorkingTable_14),nolock) '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 '' +
	 ''and calif_id in ('' + @calif_id + ''))'' +
	 ''and [status] = 0''

	exec(@SQL)

	Set @SQL = ''update ccoWorkingTable with(rowlock) set cal_status = 0, tiporesdial_id = 0, calif_id = 0 '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 ''
	 + -- and tiporesdial_id = 1 '' +
	 ''and calif_id in ('' + @calif_id + '')''

	exec(@SQL)
 end

if @type = 4
 begin	

	update ccoCallBacks with(rowlock) 
	set [status] = 3, schedulerStatus = 1
	where callout_id in (select distinct(callout_id)
						 from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) 
						 where cam_id = @cam_id and cal_status = 3)
	and [status] = 0

	update ccoWorkingTable with(rowlock) set cal_status = 0, tiporesdial_id = 0 
	where cam_id = @cam_id and cal_status = 3
 end

return(0)
set nocount off'
    	EXEC(@Sql)

    	set @process = 'CW-1763 Version 119.124 -- Alter SP ccsp_RIAAdmDelRegs '
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAAdmDelRegs]
	@tipoDel int, -- 1 Registros Nuevos / 2 Registros CallBack / 3 Registros sin meter a WT / 4 Registros CallBack - Excepto los programados por Agentes
	@cam_id int,
	@phone varchar(30) = '''',
	@calkey varchar(20) = '''',
	@exact bit = 1
	AS

	if @tipoDel = 1 --nuevos
	 begin
		delete ccoWorkingTable where cam_id = @cam_id and cal_status = 0
	 end

	if @tipoDel = 2 --callbacks
	 begin
		delete ccoWorkingTable where cam_id = @cam_id and cal_status = 1
	 end

	if @tipoDel = 3 -- 3 Registros sin meter a WT
	 begin
		update ccocallsoutsource --with(rowlock)
		set cal_Status = 5 
		where cam_id = @cam_id 
		and cal_status in(0, 7)
		
		Delete ccUploadTemporal where cam_id = @cam_id
	 end

	if @tipoDel = 4 --callbacks
	 begin
		delete ccoWorkingTable where cam_id = @cam_id and cal_status = 1 and user_id=0
	 end

	if @tipoDel = 5 --callbacks
	 begin
		delete ccoWorkingTable where cam_id = @cam_id and cal_status = 3
	 end

	if @tipoDel = 6 -- Delete a record from a specific campaign containing a specific phone number
	begin	
		delete ccoWorkingTable --with(rowlock) 
		where callout_id in (select callout_id 
								from ccocallsoutsource with(nolock)
								where cam_id = @cam_id 
								and (cal_telefono = @phone or 
										cal_telefono2 = @phone or 
										cal_telefono3 = @phone or 
										cal_telefono4 = @phone or 
										cal_telefono5 = @phone))

		update ccocallsoutsource --with(rowlock)
		set cal_Status = 5 
		where cam_id = @cam_id  and 
			(cal_telefono = @phone or 
			cal_telefono2 = @phone or 
			cal_telefono3 = @phone or 
			cal_telefono4 = @phone or 
			cal_telefono5 = @phone)
		
	end

	if @tipoDel = 7 -- Delete all the records from a specific campaign
	begin
		delete from ccoWorkingTable where cam_id = @cam_id

		update ccocallsoutsource set cal_Status = 5 where cam_id = @cam_id
	end

	if @tipoDel = 8 --delete records by specific callkey
	 begin
		if @exact = 1
			delete ccoWorkingTable with(rowlock) where cal_keyw = @calkey and cal_status <> 2
		else
			delete ccoWorkingTable with(rowlock) where cal_keyw like ''%'' + @calkey + ''%'' and cal_status <> 2
	 end'
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
