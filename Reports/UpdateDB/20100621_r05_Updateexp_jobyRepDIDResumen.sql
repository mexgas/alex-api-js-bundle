/*
Autor: Armando Rodriguez
Fecha: 2010/06/09
Descripcion: agrega job para poder borrar info generada de dia en los reportes y se agrega el sp que genera la informacion para el reporte Concentrado por did.
Version requerida: 4
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '5'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 		set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''Borra destino'',
''declare @to as smalldatetime
declare @from as smalldatetime
SELECT @to = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @from = DATEADD(d, -1, @to)

DELETE  from ccGenSession where login >= @from and login < @to
DELETE ccGenInCall WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenInCallDNI WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenOutCall WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenAgent WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenAgentNotReady WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenInSpec WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenInAbnd WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenInAnsw WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenInCalif WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenOutCamp WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenOutCallCalif WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenOutCallDials WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenOutCstoResumen WHERE timegroup >= @from AND timegroup < @to'',''*N/A*'',1,0,10,''01/01/1900 02:40'',''01/01/1900 02:45'',''1111111'','''','''','''','''','''','''',0,'''','''',0,0)
'
	EXEC(@Sql)

set @Sql='CREATE PROCEDURE [dbo].[ccsp_repDIDRes]
@DateG as varchar(20),
@end as varchar(20),
@start as varchar(20),
@cbjUno as varchar(500)=''''
AS

set nocount on
declare @RtnValue table (Id int identity(1,1), Value nvarchar(100))
declare @end_provccgen as smalldatetime
declare @end_prov as smalldatetime
declare @hoy as smalldatetime
declare @hora as smalldatetime
declare @sql as varchar(max)
declare @sGroupDetail as varchar(200)
declare @sGroupDetailCIn as varchar(200)
declare @server as varchar(200)
declare @cols as varchar(8000)
declare @colsUp as varchar(max)
declare @columna as varchar(20)
DECLARE @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23
select @hoy = convert(smalldatetime,convert(varchar(10),getdate(),120),120)
select @hora = dateadd(hh,-1,convert(smalldatetime,convert(varchar(14),getdate(),120)+''00:00'',120))
select @server = valor from ccSettings where setting_id = 22

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''timegroup''
   set @sGroupDetailCIn = ''convert(smalldatetime,convert(varchar(14),cal_inicio,120)+ ''''00:00'''',120)''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121)''
   set @sGroupDetailCIn = ''convert(smalldatetime,convert(varchar(10),cal_inicio,120),120)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''''-01'''', 121)''
    set @sGroupDetailCIn = ''convert(smalldatetime,convert(varchar(7),cal_inicio,120)+ ''''-01'''',120)''
end

if @end > @hoy
begin
	set @end_provccgen = @hoy
	if @start >= @hoy
	begin
		set @sql = ''''
	end
	else
	begin
		set @sql = '' (select '' + @sGroupDetail + '' as timegroup, dni_id, sum(nanswer) cantidad from dbo.ccGenInCallDNI where timegroup >= '' + char(0x27) + convert(varchar(20),@start,120) + char(0x27) + '' and timegroup < '' + char(0x27) + convert(varchar(20),@end_provccgen,120) + char(0x27) + '' group by '' + @sGroupDetail + '',dni_id)''
	end
	if @end > @hora
	begin
		set @end_prov = @hora
		if @start >= @hora
		begin
			set @sql = '' select '' + @sGroupDetailCIn + '' as timegroup, dni_id, count(dni_id) cantidad from '' + @server + ''cccallsin where cal_inicio >= '' + char(0x27) + convert(varchar(20),@start,120) + char(0x27) + '' and cal_inicio < '' + char(0x27) + convert(varchar(20),@end,120) + char(0x27) + '' and statuscall_id = 13 group by '' + @sGroupDetailCIn + '', dni_id''
		end
		else
		begin
			if @sql <> ''''
			begin
				set @sql = @sql + '' union all''
			end
			set @sql = @sql + '' (select '' + @sGroupDetailCIn + '' as timegroup, dni_id, count(dni_id) cantidad from  '' + @server + ''cccallsin where cal_inicio >= '' + char(0x27) + convert(varchar(20),dateadd(ss,1,@end_prov),120) + char(0x27) + '' and cal_inicio < '' + char(0x27) + convert(varchar(20),@end,120) + char(0x27) + '' and statuscall_id = 13 group by '' + @sGroupDetailCIn + '', dni_id)''
			set @sql = @sql + '' union all (select '' + @sGroupDetailCIn + '' as timegroup, dni_id, count(dni_id) cantidad from cccallsin where cal_inicio >= '' + char(0x27) + convert(varchar(20),dateadd(ss,1,@end_provccgen),120) + char(0x27) + '' and cal_inicio < '' + char(0x27) + convert(varchar(20),@end_prov,120) + char(0x27) + '' and statuscall_id = 13 group by '' + @sGroupDetailCIn + '', dni_id)''
		end
	end
	else
	begin
		set @end_prov = @end
		if @start >= @hoy and @start < @hora
		begin
			set @sql = '' select '' + @sGroupDetailCIn + '' as timegroup, dni_id, count(dni_id) cantidad from cccallsin where cal_inicio >= '' + char(0x27) + convert(varchar(20),@start,120) + char(0x27) + '' and cal_inicio < '' + char(0x27) + convert(varchar(20),@end_prov,120) + char(0x27) + '' and statuscall_id = 13 group by '' + @sGroupDetailCIn + '', dni_id''
		end
		else
		begin
			set @sql = @sql + '' union all (select '' + @sGroupDetailCIn + '' as timegroup, dni_id, count(dni_id) cantidad from cccallsin where cal_inicio >= '' + char(0x27) + convert(varchar(20),dateadd(ss,1,@end_provccgen),120) + char(0x27) + '' and cal_inicio < '' + char(0x27) + convert(varchar(20),@end_prov,120) + char(0x27) + '' and statuscall_id = 13 group by '' + @sGroupDetailCIn + '', dni_id)''
		end
	end
end
else
begin
	set @end_provccgen = @end
	set @sql = '' select '' + @sGroupDetail + '' as timegroup, dni_id, sum(nanswer) cantidad from dbo.ccGenInCallDNI where timegroup >= '' + char(0x27) + convert(varchar(20),@start,120) + char(0x27) + '' and timegroup < '' + char(0x27) + convert(varchar(20),@end_provccgen,120) + char(0x27) + '' group by '' + @sGroupDetail + '',dni_id''
end

if @cbjUno <> ''''
 begin
	While (Charindex('','',@cbjUno)>0)
	 Begin 
		Insert Into @RtnValue (value)
		Select Value = ltrim(rtrim(Substring(@cbjUno,1,Charindex('','',@cbjUno)-1))) 
		Set @cbjUno = Substring(@cbjUno,Charindex('','',@cbjUno)+len('',''),len(@cbjUno))
	 End 

	Insert Into @RtnValue (Value)
	Select Value = ltrim(rtrim(@cbjUno))
 end

else
 begin
	insert into @RtnValue select distinct dni_id from cccallsin where cal_inicio >=  dateadd(D,-20,getdate())
 end

--genera las columans de los dnis
DECLARE CCampos CURSOR FOR
     SELECT dni_numero from ccdnis where dni_id in (select value from @RtnValue) order by dni_numero
set @cols = ''''
set @colsUp = ''''
Open CCampos
Fetch Next From CCampos
Into @columna
if @@FETCH_STATUS = 0
	Begin
		While @@FETCH_STATUS = 0
		Begin   
			if @cols = ''''
			begin
				if @columna <> ''cont''
				begin
					set @cols = ''['' + @columna + '']''
					set @colsUp = ''isnull(['' + @columna + ''],0) '' + ''['' + @columna + '']''
				end
			end
			else
			begin
				if @columna <> ''cont''
				begin
					set @cols = @cols +'', ['' + @columna + '']''
					set @colsUp = @colsUp + '', isnull(['' + @columna + ''],0) '' + ''['' + @columna + '']''
				end
			end
			Fetch Next From CCampos
			Into   @columna
		End
	End
CLOSE CCampos 
DEALLOCATE CCampos 
print @colsUp
print @cols

set @sql = ''select timegroup as Fecha,'' + @colsUp + '' from(select timegroup,isnull(dni_numero,0) dni_numero, sum(cantidad) as cantidad from ('' + @sql + '') as a left join ccdnis ccd on (a.dni_id = ccd.dni_id) group by timegroup, dni_numero) dnis PIVOT(SUM(cantidad) FOR [dni_numero] IN ('' + @cols + '')) AS pvt''

if @idioma = 1
begin
	set @sql = replace(@sql, ''Fecha'', ''Date'') 
end

--print(@sql)
exec(@sql)
'
	EXEC(@Sql)


set @Sql='delete from ccsettings where setting_id = 25 and tipo = ''grl''
'
	EXEC(@Sql)

------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC]
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
