CREATE PROCEDURE [dbo].[ccsp_AplicaListaNegra]
--@idcampana as varchar(10),
--@fechacal as datetime
AS

declare @pais varchar(2)
declare @ld varchar(4)
declare @idagenda  int
declare @campsid int
declare @fechacal datetime
declare @Listid int

SET NOCOUNT ON

CREATE TABLE [dbo].[#mycamps] ( [campsid] [int]  NOT NULL primary key) ON [PRIMARY]

select top 1 @idagenda = idagenda, @campsid = campsid, @fechacal=fecharegs from ccagendalistanegra with(index(IX_ccagendalistanegra_4),nolock)
	where status= 1 and fechaaplicar < getdate() order by fechaaplicar asc

IF @idagenda is not  null
BEGIN

select top 1 @Listid = idtipolista from ccagenda_tipolistanegra with(nolock) 
	where idagenda = @idagenda order by idtipolista asc

update ccagendalistanegra with(rowlock) set inicio=getdate() where idagenda=@idagenda


insert #mycamps
select  campsid  from ccagendalistanegra where idagenda=@idagenda and  status= 1 and fechaaplicar < getdate() order by fechaaplicar asc

CREATE TABLE [dbo].[#mytemp] (
	[callout_id] [int] NOT NULL,
    [telefono] [varchar] (15) NOT NULL ,
	[cam_id] [smallint] NOT NULL ,
	[tipomov] [int] NOT NULL,
    [idtipolista] [int] NOT NULL
) ON [PRIMARY]

create table #tempListNegra(telefono varchar(32) NOT NULL,	idtipolista int NOT NULL)
CREATE NONCLUSTERED INDEX IX_tempListNegra_1 ON [dbo].#tempListNegra (telefono ASC)

--CREATE  UNIQUE  INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) ON [PRIMARY] -- Nunca usa el callout id y siempre se trunca por telefono.

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

insert into #tempListNegra select dbo.Completa(telefono, @pais, @ld),idtipolista from ccListaNegra
-----------------------------------------------------------------------------  telefono1
IF @campsid=0
BEGIN
	
        IF @Listid = 0
        BEGIN
		

	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,'3',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono =ln.telefono
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono = ln.telefono
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	---Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal
	
           END
           ELSE
           BEGIN
              insert #mytemp
	---Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln on cs.cal_telefono = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END



-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono= wt.cal_telefono and  rtrim(left(ltrim(            cs.cal_telefono2 + '         '
							 + cs.cal_telefono3 + '         '
							 + cs.cal_telefono4 + '         '
							 + cs.cal_telefono5 + '         '),13)) = ''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable with(rowlock) set cal_telefono =
rtrim(left(ltrim(            cs.cal_telefono2 + '         '
							 + cs.cal_telefono3 + '         '
							 + cs.cal_telefono4 + '         '
							 + cs.cal_telefono5 + '         '),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono1 de CS
update ccoCallsOutSource with(rowlock)
set cal_telefono = ''
from ccoCallsOutSource cs 
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp


----------------------------------------------------------------------------------- -telefono 2
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,'3',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono2 =ln.telefono
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
             insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono2 = ln.telefono
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
    
           END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono2 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln on cs.cal_telefono2 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END

-- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono2= wt.cal_telefono and rtrim(left(ltrim(            cs.cal_telefono3 + '         '
							 + cs.cal_telefono4 + '         '
							 + cs.cal_telefono5 + '         '),13)) = ''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable with(rowlock) set cal_telefono =
rtrim(left(ltrim(            cs.cal_telefono3 + '         '
							 + cs.cal_telefono4 + '         '
							 + cs.cal_telefono5 + '         '),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono2= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono2 de CS
update ccoCallsOutSource with(rowlock) set cal_telefono2 = ''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 3
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono3 en lista negra
	select callout_id,cal_telefono3,cam_id,'3',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono3 =ln.telefono
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono3 en lista negra
	select callout_id,cal_telefono3,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono3 = ln.telefono
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
           END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono3 en lista negra
	select callout_id,cal_telefono3,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono3 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono3 en lista negra
	select callout_id,cal_telefono3,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln on cs.cal_telefono3 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono3= wt.cal_telefono  and  rtrim(left(ltrim(            cs.cal_telefono4 + '         '
							 + cs.cal_telefono5 + '         '),13)) = ''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable with(rowlock) set cal_telefono =
rtrim(left(ltrim(             cs.cal_telefono4 + '         '
							 + cs.cal_telefono5 + '         '),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono3= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono3 de CS
update ccoCallsOutSource set cal_telefono3 = ''
from ccoCallsOutSource cs 
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 4
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono4 en lista negra
	select callout_id,cal_telefono4,cam_id,'3',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono4 =ln.telefono
	where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono4 en lista negra
	select callout_id,cal_telefono4,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono4 = ln.telefono
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono4 en lista negra
	select callout_id,cal_telefono4,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono4 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono4 en lista negra
	select callout_id,cal_telefono4,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln on cs.cal_telefono4 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono4= wt.cal_telefono and  rtrim(left(ltrim(            cs.cal_telefono5 + '         '),13)) = ''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono =
rtrim(left(ltrim(            cs.cal_telefono5 + '         '),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono4= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono4 de CS
update ccoCallsOutSource set cal_telefono4 = ''
from ccoCallsOutSource cs 
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 5
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono5,cam_id,'3',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono5 =ln.telefono
	where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono5 en lista negra
	select callout_id,cal_telefono5,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono5 = ln.telefono
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono5,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono5 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono5 en lista negra
	select callout_id,cal_telefono5,cam_id,'3',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_12),nolock)
	inner join #tempListNegra ln on cs.cal_telefono5 = ln.telefono
	INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
	where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
    
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono5= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono5 de CS
update ccoCallsOutSource set cal_telefono5 = ''
from ccoCallsOutSource cs 
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

update ccagendalistanegra set termino=getdate() where idagenda=@idagenda
update ccagendalistanegra set status='0' where idagenda=@idagenda
drop table #mytemp
drop table #tempListNegra
END


drop table #mycamps