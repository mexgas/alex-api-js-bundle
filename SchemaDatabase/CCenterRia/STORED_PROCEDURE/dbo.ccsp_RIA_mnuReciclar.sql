Create proc [dbo].[ccsp_RIA_mnuReciclar]
@cam_id int,
@type tinyint, -- 0:recicla todo / 1:recicla no efectivos / 2:recicla los efectivos calificados /
--                3:recicla no efectivos y efectivos calificados (1 y 2) / 4:Recicla status "Finalizado"
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
        select -2, 'No hay un limite para volver a reciclar'
        return(0)
     end

    select top 1 @ultimoReciclaje = max(fecha) from ccLogReciclaje where cam_id = @cam_id

    -- Se crea log, ccsp_ADMlogReciclaje para que esta informacion la traiga, por que no se esta metiendo
    select @user_id = isnull(@user_id, '0'), @calif_id = isnull(@calif_id, '0')

    exec dbo.ccsp_ADMlogReciclaje @cam_id, @user_id, @type, @calif_id

    If @ultimoReciclaje is not null and getdate() < DateAdd(n, @Valor, @ultimoReciclaje)
    begin
        select -3, 'No se puede realizar un reciclaje hasta que pase el tiempo limite'
        return(0)
    end

 end

if @type=0
 begin
    if @list_id = 0 begin
        create table #allReciycled(callout_id int not null primary key)

        insert into #allReciycled
        select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_8),nolock) where cam_id = @cam_id and cal_status = 1

        update ccoCallBacks
        set [status] = 3, schedulerStatus = 1
        from ccoCallBacks a with(index([IX_ccoCallBacks6])) join #allReciycled b on (a.callout_id = b.callout_id)
        where [status] = 0

        update ccoWorkingTable
        set cal_status = 0
        from ccoWorkingTable a join #allReciycled b on (a.callout_id = b.callout_id)

        drop table #allReciycled
    end
    else begin
        create table #allListReciycled(callout_id int not null primary key)

        insert into #allListReciycled
        select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_10),nolock) where cam_id = @cam_id and cal_status = 1 and list_id = @list_id

        update ccoCallBacks
        set [status] = 3, schedulerStatus = 1
        from ccoCallBacks a with(index([IX_ccoCallBacks6])) join #allListReciycled b on (a.callout_id = b.callout_id)
        where [status] = 0

        update ccoWorkingTable
        set cal_status = 0
        from ccoWorkingTable a join #allListReciycled b on (a.callout_id = b.callout_id)

        drop table #allListReciycled
    end
	select 1
    return(0)
 end

if @type in(1,3)
 begin

    update ccoCallBacks
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

    update ccoWorkingTable
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

    Set @SQL = 'update ccoCallBacks with(rowlock) set [status] = 3, schedulerStatus = 1' +
     'where callout_id in (' +
     'select distinct(callout_id) from ccoWorkingTable with(index(IX_ccoWorkingTable_14),nolock) ' +
     'where cam_id = ' + cast(@cam_id as varchar(10)) + ' and cal_status = 1 ' +
     'and calif_id in (' + @calif_id + '))' +
     'and [status] = 0'

    exec(@SQL)

    Set @SQL = 'update ccoWorkingTable set cal_status = 0, tiporesdial_id = 0, calif_id = 0 ' +
     'where cam_id = ' + cast(@cam_id as varchar(10)) + ' and cal_status = 1 '
     + -- and tiporesdial_id = 1 ' +
     'and calif_id in (' + @calif_id + ')'

    exec(@SQL)
 end

if @type = 4
 begin

    update ccoCallBacks
    set [status] = 3, schedulerStatus = 1
    where callout_id in (select distinct(callout_id)
                         from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock)
                         where cam_id = @cam_id and cal_status = 3)
    and [status] = 0

    update ccoWorkingTable
  set cal_status = 0, tiporesdial_id = 0
    where cam_id = @cam_id and cal_status = 3
 end

return(0)
set nocount off