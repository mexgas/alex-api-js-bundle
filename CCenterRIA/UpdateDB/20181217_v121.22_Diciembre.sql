/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
		
Date: 2018/11/21
Description:

Database: CCenterRia
Required version: 120.35 

Se agrega la tarea
	CW-2467

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

set @version = 122--**********actualizar a 119 sin fix
set @versionfix = 22
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 11
	begin
		begin tran
		begin try

		 set @process = 'CW-2467 --Alter SP ccsp_RIAGetCampsNvosCB'
        set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0
as
set nocount on

declare @TipoJobs as int,@isExecOutbound bit


set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

  declare @id AS INTEGER

  CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
  CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)

  create table #temccocallsoutsource (cam_id int,Pend  int)

  create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

  if @cam_id = 0 begin
    if @user_id > 0 begin
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
      from ccCamps cam with(nolock) left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
      where user_id = @user_id and tipo = 1
    end
    else begin
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
      from ccCamps cam left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
    end

  end
  else begin
    if @Tipo = 2
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
      from ccCamps cam with(nolock)
      left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
      where cam.cam_id = @cam_id
    else
      if @user_id > 0 begin
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
        from ccCamps cam with(nolock) left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
        where user_id = @user_id and tipo = 1
       end
      else begin
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
          select cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
          from ccCamps where cam_activo=1
      end
  end



  insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
  select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0 from(
  select A.* from #Tcamps A
  left join ccCampsNvosCB B  on A.cam_id=B.id
  where datediff(ss,B.dateUpdate,getdate())>5 or B.dateUpdate is null)X

  group by cam_id


  --Se revisa que por lo menos una campaña se pueda actualizar para realizar el proceso en caso contrario se regresa el valro extablecido
  if (select count(*) from #Tcamps2)>0 begin

    insert into #temccocallsoutsource(cam_id,Pend)
    SELECT ccos.cam_id, count(ccos.cam_id) as Pend
    FROM ccocallsoutsource ccos with(nolock)
    left join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
    WHERE cal_status in(0, 7)
    GROUP BY ccos.cam_id

    insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
    SELECT A.cam_id,
    count(case cal_status when 0 then 1 else null end) as New,
    count(case cal_status when 1 then 1 else null end) as Cb,
    count(case cal_status when 2 then 1 else null end) as Pro,
    count(case cal_status when 3 then 1 else null end) as Fin
    FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
    inner join #Tcamps2 B on A.cam_id = B.cam_id
    GROUP BY A.cam_id

    --select * from #Tcamps2

    --Se va agregar al ccsp_OUTGetNewJobs cuando lo ejecute el SP Outbound para actualizar de manera seguida si solo es una campaña
    if @regval = 0 and @cam_id >0 and @Tipo =2 begin
      update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @cam_id
    end
    else begin
      While (select count(*) from #Tcamps2 where status = 0) > 0 Begin
        set rowcount 1
        select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
        set rowcount 0
        EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
        update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
      end
    end

    begin Tran updateccCampsNvosCB

      delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
      where CampNvosCB.id = tcamp.cam_id

      INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial,dateUpdate)
      SELECT cams.cam_id, cams.cam_descripcion,
      isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
      isNull(cs.Pend,0) as pend,
      isNull(wt.Pro,0) as pro,
      isNull(cams.procesando,0) cam_procesando,
      isNull(cams.cam_tipojobs,0) cam_tipojobs,
      isNull(wt.Fin,0) Fin,
      isNull(tc.cantidad,0) cantidad,
      getdate()
      FROM #Tcamps cams with(nolock)
      LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
      LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
      left join #Tcamps2 tc on (tc.cam_id = cams.cam_id)

    COMMIT TRAN updateccCampsNvosCB
  end

  if @isExecOutbound = 0 begin

    if @Tipo = 2
      -- devuelve resultado de la taba, solo las camps del usuario
      SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor
      FROM #Tcamps tcam
      left join  ccCampsNvosCB res  on tcam.cam_id  = res.id
      LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
	  inner join cccamps cc on res.id=cc.cam_id
    else
      SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,cc.aggressionFactor
      FROM ccCampsNvosCB res
      LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
	  inner join cccamps cc on res.id=cc.cam_id
      WHERE res.id = @cam_id
  end

  drop table #Tcamps
  drop table #Tcamps2
  drop table #temccocallsoutsource
  drop table #temWorkinTable

  return(0)

end

set nocount off'
        EXEC(@Sql)

        set @process = 'CW-2467 --Add SP ccSettings Send Acitvity Port'
        set @Sql= 'if not exists(Select * From ccSettings Where setting_id=184) begin
	insert into ccSettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
	values (184,''0'',''Envío los cambios de estado de los puertos'',1,''X'',''Envia los cambios de los puertos del outbound al Admin'',''Send port status changes'',0,''^[0-1]$'')
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
