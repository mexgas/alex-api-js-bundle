/*
Autor: Jesus Gallardo
Fecha: 2016/12/20
Descripcion:

Se modifica SP trsp_InsertRecNode
Se modifica SP ccsp_CleanNodeBaseX
Se modifica SP ccsp_BaseXmngr

Version requerida: 40
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 41
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in( @Version -1, @version) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	set @process = 'Add Atribute with RIA_Grabacion CDATE --CW-876'
	set @sql ='update R
set node.modify(''insert attribute CDATE {sql:column("finicio") } into (/R02)[1]''),[status]=case [status] when 1 then 2 when 3 then 2 else [status] end
from ria_recnode R
inner join (select grab_id,convert(varchar(max),finicio,126) as finicio from RIA_GRABACION) G on R.grab_id=G.grab_id
where node.exist(''(/R02[1])[empty(@CDATE)]'' )=1'
	EXEC(@sql)

	set @process = 'Add Atribute with RIA_GRABACIONCONSULTA CDATE --CW-876'
	set @sql ='update R
set node.modify(''insert attribute CDATE {sql:column("finicio") } into (/R02)[1]''),[status]=case [status] when 1 then 2 when 3 then 2 else [status] end
from ria_recnode R
inner join (select grab_id,convert(varchar(max),finicio,126) as finicio from RIA_GRABACIONCONSULTA) G on R.grab_id=G.grab_id
where node.exist(''(/R02[1])[empty(@CDATE)]'' )=1'
	EXEC(@sql)


	set @process = 'ALTER sp -- ccsp_BaseXmngr --CW-876'
 	set @sql ='ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int = 0,
@option int = 0,
@idService int = 0,
@name varchar(25) = NULL,
@top varchar(max) = NULL,
@id int =0,
@dateStart dateTime= null

AS
declare @sql nvarchar(max)
declare @status tinyint

set @sql = ''''
if @action in(1,6) begin--obtiene los nodos a insertar en BX
	if @option = 2 begin
		if @action = 1 set @status =0
		else if @action = 6 set @status = 2
		set @sql=''with node ( grab_id,xmlString,dateNode)
AS(
	select top('' + @top + '') grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
	,isnull(node.value(''''(/R02/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R02/@C06)[1]'''',''''datetime'''')) as dateNode
	from ria_RecNode A with(rowlock)
	where A.status ='''''' + cast(@status as nvarchar(max)) +''''''
	union
	select top('' + @top + '') grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
	,isnull(node.value(''''(/R02/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R02/@C06)[1]'''',''''datetime'''')) as dateNode
	from ria_RecNodeHistory A with(rowlock)
	where A.status ='''''' + cast(@status as nvarchar(max)) +'' ''''
)

select node.grab_id,node.xmlString,baseX.Xname from node
left join ccBaseXDB baseX on baseX.serviceId=2  and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
order by baseX.Xname''
		--print(@sql)
		exec(@sql)
	end
end
if @action in(2,7) begin--actualiza los nodos insertados en BX
	if @option = 2 begin
		if @action = 2 set @status=0
		else if @action = 7 set @status = 2

		update ria_RecNode with(rowlock) set [status] = @status + 1 , dateOut = getDate() where grab_id = @id and [status] = @status
		update RIA_RecNodeHistory with(rowlock) set [status] = @status + 1 , dateOut = getDate() where grab_id = @id and [status] = @status
	end
end
else if @action = 3 begin--trae el nombre de la base de datos en BX
	select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
	insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option, @dateStart, @name,0)
end
else if @action = 11 begin--trae el nombre de la base de datos en BX
	if @option =2 begin
		SELECT ISNULL(min(node.value(''(/R02/@CDATE)[1]'',''datetime'')),GETDATE()) as node FROM RIA_RecNode where status = 0
	end
	end
else if @action =12 begin
	declare @replicationName nvarchar(500)
		select @replicationName = name from msdb.dbo.sysjobs where name like ''%-CCRecorderRIA- 0'' and name like ''%SpecialAVRS%''
		exec msdb.dbo.sp_start_job @job_name = @replicationName
		while(
		SELECT count(*) FROM msdb.dbo.sysjobactivity ja
		LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
		INNER JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
		INNER JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
		WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions   ORDER BY agent_start_date DESC)
		AND start_execution_date is not null AND stop_execution_date is null and j.name=@replicationName
	) > 0
	begin
		WAITFOR DELAY ''00:00:01''
	end
end'
	EXEC(@sql)



set @process = 'ALTER sp -- ccsp_CleanNodeBaseX'
set @sql ='ALTER PROCEDURE [dbo].[ccsp_CleanNodeBaseX]
@option int
AS
BEGIN

declare @dateEnd datetime
declare @count int ,@setting int

declare @nodos table (fecha varchar(100))
--declare @dateStart datetime, @dateEnd datetime
declare @res int
set @res = -1

select  @setting  = valor from ccSettings where setting_id = 188
	select  @setting  = valor from ccSettings where setting_id = 188
	if @setting is null set @setting = 40000

	select @count = COUNT (grab_id) from RIA_RecNode with(nolock) where status in(1,3)
	if @count >=  @setting begin

	if exists (select * from RIA_RecNode where status = 2)begin
		select 0,null
		return 0
	end
	begin try
		begin tran elimina

			if @option = 2 begin

				--insert into RIA_RecNodeHistory
				select grab_id,node,dateIn,dateOut,status
				into #TempRIA_RecNodeHistory
				from RIA_RecNode where status in(1,3)

				insert into @nodos
				SELECT node.value(''(/R02/@CDATE)[1]'',''datetime'') as node FROM #TempRIA_RecNodeHistory where status in(1,3) order by node

				select @dateEnd = convert(datetime, MAX(fecha)) from @nodos

				--update ccBaseXDB set isfull = 1, dateStart=isnull(@dateStart,dateStart),dateEnd=isnull(@dateEnd,getdate()) where serviceId= @option and  isfull = 0 and dateEnd is null

				delete from RIA_RecNode where grab_id in(select grab_id from #TempRIA_RecNodeHistory )
				insert into RIA_RecNodeHistory select * from #TempRIA_RecNodeHistory
				drop table #TempRIA_RecNodeHistory
				set @res = 1
			end
		commit tran elimina
	end try
	begin catch
			rollback  transaction elimina
			set @res = 0
		end catch
	end
	select @res,@dateEnd
END
'
EXEC(@sql)





set @process = 'ALTER sp -- trsp_InsertRecNode'
set @sql ='
ALTER procedure [dbo].[trsp_InsertRecNode]
@grabId int,
@type int=0

as
begin

 declare @callType as nvarchar(20)
 declare @shoutLevel as nvarchar(20)
 declare @language as int
 declare @start as int

 declare @xml as xml
 declare @crmNode as xml
 declare @manual as nvarchar(10)
 declare @rating as nvarchar(20)
 declare @sqlCRM nvarchar(2000)
 declare @supervisor as nvarchar(50)
 declare @template as nvarchar(50)
 declare @callID as nvarchar(50)


 declare @table as nvarchar(20)
 set @table=''RIA''

 /*
  CDATE---> Date Generic
  C01-----> grab_id
  C02-----> Type of Recording (Inbound/Outbound)
  C03-----> Camp/ACD descripcion
  C04-----> ShoutLevel
  C05-----> Agent Login
  C06-----> Formated date
  C07-----> Position Computer
  C08-----> Duration
  C09-----> Ani
  C10-----> Dnis
  C11-----> Calkey
  C12-----> Manual
  C13-----> User ID
  C14-----> cal ID
  C15-----> Cam /ACD ID
  C16-----> Duration Recording as 00:00:00
  C17-----> Position Extension
  C18-----> rating(Scoring Template)
  C19-----> Reposiory ID
  C20-----> Disposition
  C21-----> Disposition ID
  C22-----> Has Video
  C23-----> Agent Full Name
  C24-----> Supervisor Name
  C25-----> Score Template
  C26-----> graphic_id
 */

 select @language= valor from ccSettings where setting_id = 27

 select @callType = rec.tipo_llamada
  ,@manual = case when rec.cal_manual = 0 then ''N/A'' else ''Manual'' end
  ,@shoutlevel =sho.nombre_nivel
  ,@rating= total_forma
  ,@callID=cal_id
 from ria_grabacion rec
 left join ria_tipo_gritos sho on rec.id_nivel_grito = sho.id_nivel_grito
 left join (select top 1 total_forma,id_grabacion from ria_formacalif where id_grabacion = @grabId order by fecha_calif desc)  formCalif on formCalif.id_grabacion=rec.grab_id
 where grab_id = @grabId


 --Languages 0 spanish 1 english
 select @shoutlevel=case when @language =0 then substring(@shoutlevel,0,@start) else  substring(@shoutlevel,(@start+1),(LEN(@shoutlevel)-1)) end


 select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
   RIA_FORMATOS as formatos
   inner join RIA_FORMACALIF formatosCalif on formatosCalif.id_formato=formatos.id_formato
   inner join RIA_GRABACION grabacion  on grabacion.grab_id= formatosCalif.id_grabacion
   inner join ccUsers supervisor on supervisor.User_id = formatosCalif.id_supervisor
   where grabacion.grab_id=@grabId and formatosCalif.tipo=1

 set @xml = (select * from (
  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
  isnull(e.description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
   ,grap.graphic_id as ''@C26''
   from
   ria_grabacion rec
   inner join ccinbound inb on rec.cam_id = inb.Inbound_id and @callType = 1
   inner join ccUsers usr on usr.User_id = rec.age_id
   inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
   left join ccTipoCalif AS e  ON rec.calif_id = e.calif_id
   inner join ccRIAInboundGraph grap on grap.Inbound_id=inb.Inbound_id
   where rec.grab_id = @grabId
  union
  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'',inb.cam_descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'',convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
  isnull(e.Description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
  ,grap.graphic_id as ''@C26''
   from
  ria_grabacion rec
  inner join cccamps inb on rec.cam_id = inb.cam_id and @callType = 2
  inner join ccUsers usr on usr.User_id = rec.age_id
  inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
  left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
  inner join ccRIACampsGraph grap on grap.cam_id=inb.cam_id
  where rec.grab_id = @grabId

  )x
  for xml path(''R02'')
 )

if @xml is not null begin
	select @crmNode = node from ccCRMNodes where [type]= @callType and cal_id=@callID
	if @crmNode is not null begin
		update ccCRMNodes set grab_id=@grabId where [type]=@callType and cal_id=@callID
		set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
		execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
	end

  if exists(select * from RIA_RecNodeHistory where grab_id=@grabId) begin
	update RIA_RecNodeHistory set node =@xml,[status]=2 where grab_id = @grabId
 --   insert into ria_RecNode (grab_id,node,dateIn,[status]) --values (@grabId,@xml, getdate(),0)
	--select grab_id,node,dateIn,2 from RIA_RecNodeHistory where grab_id = @grabId
	--delete from RIA_RecNodeHistory where grab_id = @grabId
  end
  else if not exists(select * from ria_RecNode where grab_id=@grabId) begin
	insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),0)
  end
  else begin
	update ria_RecNode set node =@xml,[status]=2 where grab_id = @grabId
	end
	select @xml
 end
end
'
EXEC(@sql)



------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
