CREATE PROCEDURE [dbo].[ccsp_GetCampsNvosCB]
@cam_id integer = 0,
@Tipo tinyint=0,
@user_id int=0
AS
set nocount on
declare @RecicleSIC tinyint,@sFin int,@sql varchar(8000)
select @RecicleSIC=IsNull(valor,0)FROM ccSettings WHERE setting_id=60
select @sFin=case when @RecicleSIC=0 and USER_NAME()<>'dbo' then 0 else 1 end

select @sql='declare @ultimo as datetime
if '+cast(isnull(@Tipo,0) as varchar(10))+'=0
  begin
    if '+cast(isnull(@cam_id,0) as varchar(10))+'=0 begin
      select Camps.cam_id as ID,cam_descripcion as ''Campaña'',
        IsNull(Jobs.New,0)as New,IsNull(Jobs.CB,0)as CB,IsNull(Jobs.Pro,0)as Pro,
        IsNull(Pends.pend,0)as Pen,'+case when @sFin=1 then 'IsNull(Jobs.Fin,0)as Fin,' else '' end+'
        case cam_procesando when 1 then ''Pro'' when 0 then '''' end as St,
        case cam_TipoJobs when 2 then ''New'' when 1 then ''CB'' when 0 then ''Amb'' end as Job     
      from ccCamps Camps(nolock)Left Join 
      (select cam_id,
        count(case cal_status when 0 then 1 else null end)as New,
        count(case cal_status when 1 then 1 else null end)as CB,
        count(case cal_status when 2 then 1 else null end)as Pro'
        +case when @sFin=1 then ',count(case cal_status when 3 then 1 else null end)as Fin' else '' end+'
      from ccoWorkingTable(nolock) group by cam_id)Jobs
      on Camps.cam_id=Jobs.cam_id Left Join
      (select cam_id,count(*)as Pend
          from ccocallsoutsource(nolock)where cal_status=0
          and cal_fechadial>dateadd(dd,-5,getdate())
          group by cam_id)Pends
      On Camps.cam_id=Pends.cam_id
      Order by cam_procesando desc,cam_descripcion
    end 
    else
    begin
      select wt.cam_id,cam_descripcion,
      count(case cal_status when 0 then 1 else null end)as Nuevos,
      count(case cal_status when 1 then 1 else null end)as CB
      from ccoworkingtable wt(nolock)inner join cccamps c(nolock)
      on wt.cam_id=c.cam_id and wt.cam_id='+cast(isnull(@cam_id,0) as varchar(10))+' group by wt.cam_id,cam_descripcion
      order by cam_descripcion
    end
  end

  if '+cast(isnull(@Tipo,0) as varchar(10))+'=1
  begin
    if('+cast(isnull(@cam_id,0) as varchar(10))+'>0)
      begin
      select Camps.cam_id as ID,cam_descripcion as ''Campaña'',
        IsNull(Jobs.New,0)as New,IsNull(Jobs.CB,0)as CB,IsNull(Jobs.Pro,0)as Pro,
        IsNull(Pends.pend,0)as Pen,'+case when @sFin=1 then 'IsNull(Jobs.Fin,0)as Fin,' else '' end+'
        case cam_procesando when 1 then ''Pro'' when 0 then '''' end as St,
        case cam_TipoJobs when 2 then ''New'' when 1 then ''CB''  when 0 then ''Amb'' end as Job
      from ccCamps Camps(nolock)Left Join 
      (select cam_id,
        count(case cal_status when 0 then 1 else null end)as New,
        count(case cal_status when 1 then 1 else null end)as CB,
        count(case cal_status when 2 then 1 else null end)as Pro'
        +case when @sFin=1 then ',count(case cal_status when 3 then 1 else null end)as Fin' else '' end+'
      from ccoWorkingTable(nolock) group by cam_id)Jobs
      on Camps.cam_id=Jobs.cam_id Left Join
      (select cam_id,count(*)as Pend
          from ccocallsoutsource(nolock)where cal_status=0
          and cal_fechadial>dateadd(dd,-5,getdate())
          group by cam_id)Pends
      On Camps.cam_id=Pends.cam_id
      Where Camps.cam_id='+cast(isnull(@cam_id,0) as varchar(10))+'
      Order by cam_procesando desc,cam_descripcion
    end
  end

  if '+cast(isnull(@Tipo,0) as varchar(10))+'=2
  begin
    if('+cast(isnull(@user_id,0) as varchar(10))+'>0)
      begin
      select distinct Camps.cam_id as ID,cam_descripcion as ''Campaña'',
        IsNull(Jobs.New,0)as New,IsNull(Jobs.CB,0)as CB,IsNull(Jobs.Pro,0)as Pro,
        isnull(Pends.Pend,0)Pen,'+case when @sFin=1 then 'IsNull(Jobs.Fin,0)as Fin,' else '' end+'
        case cam_procesando when 1 then ''Pro'' when 0 then '''' end as St,     
        case cam_TipoJobs when 2 then ''New'' when 1 then ''CB'' when 0 then ''Amb'' end as Job     
      from ccCamps Camps(nolock)Left Join 
      ccCampsNvosCB jobs(nolock)on Camps.cam_id=Jobs.id
      inner join ccSupervisorCam U(nolock)on Camps.cam_id=U.cam_id left Join
      (select cam_id,count(*)as Pend
          from ccocallsoutsource(nolock)where cal_status=0
          and cal_fechadial>dateadd(dd,-5,getdate())
          group by cam_id)Pends
      On Camps.cam_id=Pends.cam_id
      Where U.user_id='+cast(isnull(@user_id,0) as varchar(10))+' and tipo=1
      Order by Camps.cam_id desc,cam_descripcion
    end
  end

  if '+cast(isnull(@Tipo,0) as varchar(10))+'=3
  begin

    select @ultimo=isnull(cast(valor as datetime),dateadd(hh,-1,getdate())) from ccSettings where setting_id=21
    if datediff(mi,@ultimo,getdate())>=1 begin
      update ccsettings set valor=convert(varchar(25),getdate(),121)where setting_id=21
      delete ccCampsNvosCB
      insert ccCampsNvosCB(ID,Campaña,new,cb,pen,pro,'+case when @sFin=1 then 'fin,' else '' end+'st,job)
      select Camps.cam_id as ID,cam_descripcion as ''Campaña'',
        IsNull(Jobs.New,0)as New,IsNull(Jobs.CB,0)as CB,0 as pen,IsNull(Jobs.Pro,0)as Pro,'+case when @sFin=1 then 'IsNull(Jobs.Fin,0)as Fin,' else '' end+'cam_procesando as st,cam_TipoJobs as Job
        from ccCamps Camps(nolock)Left Join 
        ( select cam_id,
          count(case cal_status when 0 then 1 else null end)as New,
          count(case cal_status when 1 then 1 else null end)as CB,
          count(case cal_status when 2 then 1 else null end)as Pro'
          +case when @sFin=1 then ',count(case cal_status when 3 then 1 else null end)as Fin' else '' end+'
          from ccoWorkingTable(nolock)
          group by cam_id
        )Jobs on Camps.cam_id=Jobs.cam_id
    end
    select ID,Campaña,St as cam_procesando,Job as cam_tipoJobs,New,CB,Pro'+case when @sFin=1 then ',Fin' else '' end+'
    from ccCampsNvosCB (nolock)
    Order by ID
  end'

exec(@sql)
set nocount off