CREATE PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=null
WITH RECOMPILE
AS

declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)

insert into cclistanegra(telefono,idtipolista,HashKey) values(@telephone, @ln_id,@hashCalKey)

CREATE TABLE [dbo].[#mycamps] (
  [campsid] [int] NULL
  )

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select cam_id from Camplistanegra where idtipolista = @ln_id

CREATE TABLE [dbo].[#myprincipaltemp](
  [callout_id] [int] NULL, 
  [cam_id] [smallint] NULL ,
  [tipomov] [int] NULL,
  [idtipolista] [int] NULL,
  [cal_telefono] [varchar] (15) NULL ,
  [cal_telefono2] [varchar] (15) NULL ,
  [cal_telefono3] [varchar] (15) NULL ,
  [cal_telefono4] [varchar] (15) NULL ,
  [cal_telefono5] [varchar] (15) NULL
  )

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltemp]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltemp]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltemp]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltemp]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltemp]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltemp]([cal_telefono5]) 

CREATE TABLE [dbo].[#mytemp](
  [callout_id] [int] NULL, 
  [telefono] [varchar] (15) NULL ,
  [cam_id] [smallint] NULL ,
  [tipomov] [int] NULL,
  [idtipolista] [int] NULL
  )

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @tel = dbo.completa(@telephone, @pais, @ld)

--declare @Sql nvarchar(max)
--declare @fecha datetime = dateadd(dd,-30,getdate())
declare @fech datetime = getdate()-30
if @hashCalKey is not null or @hashCalKey > 0
begin

  insert into [#myprincipaltemp] 
  SELECT a.callout_id as callout_id, a.cam_id,'3',cast(@ln_id as nvarchar) as idtipolista , a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
  FROM [ccoCallsOutSource] as a, #mycamps as b with(nolock) WHERE a.cam_id = b.campsid 
  AND dbo.hashList(cal_Key) = @hashCalKey and  cal_fechadial > @fech
  
end
else begin
  insert into [#myprincipaltemp]
  SELECT a.callout_id as callout_id, a.cam_id,'3',cast(@ln_id as nvarchar) as idtipolista , a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
  FROM [ccoCallsOutSource] as a, #mycamps as b with(nolock) WHERE a.cam_id = b.campsid
  and (@tel  IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) 
  or right(@tel,10) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) 
  or right(@tel,11) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5])) 
  and  cal_fechadial > @fech
  
end

--EXEC(@Sql)

if EXISTS (select * from #myprincipaltemp)
  begin
    /******************/
    /*** Telefono 1 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono = @tel or cal_telefono = right(@tel, 10) or cal_telefono = right(@tel, 11))

    if EXISTS (select * from #mytemp)
    begin
      -- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable with(rowlock)
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and
      cs.cal_telefono = wt.cal_telefono
      and rtrim(left(ltrim(cs.cal_telefono2 + '         '
                 + cs.cal_telefono3 + '         '
                 + cs.cal_telefono4 + '         '
                 + cs.cal_telefono5 + '         '),13)) = ''

      -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
      update ccoWOrkingTable 
      set cal_telefono = rtrim(left(ltrim(cs.cal_telefono2 + '         '
                        + cs.cal_telefono3 + '         '
                        + cs.cal_telefono4 + '         '
                        + cs.cal_telefono5 + '         '),13))
      from ccoCallsOutSource cs 
      inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
      inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono1 de CS
      update ccoCallsOutSource 
      set cal_telefono = ''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech

      truncate table #mytemp
    end

    /******************/
    /*** Telefono 2 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono2,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono2 = @tel or cal_telefono2 = right(@tel, 10) or cal_telefono2 = right(@tel, 11))

    if EXISTS (select * from #mytemp)
    begin
      -- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable 
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono2= wt.cal_telefono 
      and rtrim(left(ltrim(cs.cal_telefono3 + '         '
                 + cs.cal_telefono4 + '         '
                 + cs.cal_telefono5 + '         '),13)) = ''

      -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
      update ccoWOrkingTable 
      set cal_telefono = rtrim(left(ltrim(cs.cal_telefono3 + '         '
                        + cs.cal_telefono4 + '         '
                        + cs.cal_telefono5 + '         '),13))
      from ccoCallsOutSource cs 
      inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
      inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono2= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono2 de CS
      update ccoCallsOutSource 
      set cal_telefono2 = ''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech

      truncate table #mytemp
    end

    /******************/
    /*** Telefono 3 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono3,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono3 = @tel or cal_telefono3 = right(@tel, 10) or cal_telefono3 = right(@tel, 11))

    if EXISTS (select * from #mytemp)
    begin
      -- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable 
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono3= wt.cal_telefono  
      and  rtrim(left(ltrim(cs.cal_telefono4 + '         '
                  + cs.cal_telefono5 + '         '),13)) = ''

      -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
      update ccoWOrkingTable 
      set cal_telefono = rtrim(left(ltrim(cs.cal_telefono4 + '         '
                        + cs.cal_telefono5 + '         '),13))
      from ccoCallsOutSource cs 
      inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
      inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono3= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono3 de CS
      update ccoCallsOutSource 
      set cal_telefono3 = ''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech

      truncate table #mytemp
    end

    /******************/
    /*** Telefono 4 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono4,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono4 = @tel or cal_telefono4 = right(@tel, 10) or cal_telefono4 = right(@tel, 11))

    if EXISTS (select * from #mytemp)
    begin
      -- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable 
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono4= wt.cal_telefono 
      and rtrim(left(ltrim(cs.cal_telefono5 + '         '),13)) = ''

      -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
      update ccoWOrkingTable 
      set cal_telefono = rtrim(left(ltrim(cs.cal_telefono5 + '         '),13))
      from ccoCallsOutSource cs 
      inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
      inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono4= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono4 de CS
      update ccoCallsOutSource 
      set cal_telefono4 = ''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech

      truncate table #mytemp
    end

    /******************/
    /*** Telefono 5 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono5,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono5 = @tel or cal_telefono5 = right(@tel, 10) or cal_telefono5 = right(@tel, 11))

    if EXISTS (select * from #mytemp)
    begin
      -- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable 
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono5= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono5 de CS
      update ccoCallsOutSource 
      set cal_telefono5 = ''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech
    end
  end

drop table [#myprincipaltemp]
drop table [#mytemp]
drop table [#mycamps]