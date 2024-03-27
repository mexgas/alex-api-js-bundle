USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_RIAGetCampsNvosCB]    Script Date: 27/03/2024 10:54:38 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0, @tcpa int=0
as
set nocount on

declare @TipoJobs as int,@isExecOutbound bit


set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

	declare @id AS INTEGER

	CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
	CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime)

	create table #temccocallsoutsource (cam_id int,Pend  int)

	create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

	if @cam_id = 0 begin
	if @user_id > 0 begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
		from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
		where user_id = @user_id and tipo = 1
	end
	else begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
		from ccCamps cam (nolock) join ccSupervisorCam supcam with(nolock) on tipo=1 and cam.cam_id  =  supcam.cam_id
	end

	end
	else begin
	if @Tipo = 2
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
		from ccCamps cam with(nolock)
		join ccSupervisorCam supcam with(nolock) on tipo=1 and cam.cam_id  =  supcam.cam_id
		where cam.cam_id = @cam_id
	else
		if @user_id > 0 begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
		from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
		where user_id = @user_id and tipo = 1
		end
		else begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
		from ccCamps cam (nolock) join ccSupervisorCam supcam with(nolock) on tipo = 1 and cam.cam_id  =  supcam.cam_id
		where user_id = @user_id and cam_activo=1
		end
	end



	insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate)
	select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate) from(
	select A.*,dateUpdate from #Tcamps A
	left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
	where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null)X
	group by cam_id


	
	if (select count(*) from #Tcamps2)>0 begin

	insert into #temccocallsoutsource(cam_id,Pend)
	SELECT ccos.cam_id, count(ccos.cam_id) as Pend
	FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
	join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
	WHERE cal_status in(0, 7)
	GROUP BY ccos.cam_id

	insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
	SELECT A.cam_id,
	count(case cal_status when 0 then 1 else null end) as New,
	count(case cal_status when 1 then 1 else null end) as Cb,
	count(case cal_status when 2 then 1 else null end) as Pro,
	count(case cal_status when 3 then 1 else null end) as Fin
	FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
	join #Tcamps2 B on A.cam_id = B.cam_id
	GROUP BY A.cam_id	

	
	if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
		update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @cam_id
	end
	--else begin
	--	While exists(select * from #Tcamps2 where status = 0 and ( datediff(ss,dateUpdate,getdate())>60 or dateUpdate is null))  Begin
	--	set rowcount 1
	--	select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
	--	set rowcount 0
	--	EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
	--	update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
	--	end
	--end

	declare @TotalNew table(
			cam_id int primary key,
			OverallTotalNew int 
		)
		
		

		

	begin Tran updateccCampsNvosCB

		insert into @TotalNew
		select CampNvosCB.id,isnull(CampNvosCB.OverallTotalNew,CampNvosCB.new)  from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
		where CampNvosCB.id = tcamp.cam_id

		delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
		where CampNvosCB.id = tcamp.cam_id

		INSERT into ccCampsNvosCB 
		SELECT cams.cam_id, cams.cam_descripcion,
		isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
		isNull(cs.Pend,0) as pend,
		isNull(wt.Pro,0) as pro,
		isNull(cams.procesando,0) cam_procesando,
		isNull(cams.cam_tipojobs,0) cam_tipojobs,
		isNull(wt.Fin,0) Fin,
		isNull(cams.cantidad,0) cantidad,
		getdate(),
		isnull(T.OverallTotalNew,0)  as OverallTotalNew
		FROM #Tcamps2 cams with(nolock)
		LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
		LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
		LEFT JOIN @TotalNew  T on T.cam_id = cams.cam_id

	COMMIT TRAN updateccCampsNvosCB
	end

	if @isExecOutbound = 0 begin

	if @Tipo = 2 begin
		-- devuelve resultado de la taba, solo las camps del usuario
		SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, 
		isnull(prio.prioridad,'12345NNN') as Prioridad, NextDial,cc.aggressionFactor, OverallTotalNew
		FROM #Tcamps tcam
		left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
	end
	else 
		SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,'12345NNN')  as Prioridad, NextDial,
		cc.aggressionFactor, OverallTotalNew
		FROM ccCampsNvosCB res (nolock)
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
		WHERE res.id = @cam_id
	end

	drop table #Tcamps
	drop table #Tcamps2
	drop table #temccocallsoutsource
	drop table #temWorkinTable

	return(0)

end

set nocount off