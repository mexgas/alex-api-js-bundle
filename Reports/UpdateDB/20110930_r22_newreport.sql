/*
Autor: Armando Rodriguez
Fecha: 2011/09/30
Descripcion: corrección del proceso que actualiza informacion
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '22'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''tdialog'',
''declare @sql varchar(8000), @server varchar(200)
set @server = valor from ccsettings where setting_id = 22
set @sql= ''''update rep set rep.cal_tdialog = cw.cal_tdialog, rep.cal_tnotas = cw.cal_tnotas  from cccallsin cw, '''' + @server + ''''.dbo.cccallsin rep 
where cw.cal_id = rep.cal_id and rep.cal_tdialog = 0 ''''
exec(@sql)

set @sql= ''''update rep set rep.cal_tdialog = cw.cal_tdialog, rep.cal_tnotas = cw.cal_tnotas  from ccocallsout cw, '''' + @server + ''''.dbo.ccocallsout rep 
where cw.cal_id = rep.cal_id and rep.cal_tdialog = 0 ''''
exec(@sql)'',''*N/A*'',1,0,60,''01/01/1900 00:30'',''01/01/1900 23:45'',''1111111'','''','''','''','''','''','''',0,'''','''',1,0)'
	EXEC(@Sql)

 	set @Sql='update Exp_Jobs set readquery = ''declare @sql varchar(1000), @server varchar(300)
select @server = valor from ccsettings where setting_id = 22

set @sql = ''''update rep set rep.statuscall_id = cw.statuscall_id from ccocallsout cw, '''' + @server + ''''.dbo.ccocallsout rep 
where cw.cal_id = rep.cal_id and rep.statuscall_id = 5 and cw.statuscall_id <> rep.statuscall_id ''''
exec(@sql)

set @sql = ''''update rep set rep.statuscall_id = cw.statuscall_id from cccallsin cw, '''' + @server + ''''.dbo.cccallsin rep 
where cw.cal_id = rep.cal_id and rep.statuscall_id = 5 and cw.statuscall_id <> rep.statuscall_id ''''
exec(@sql)'' where description = ''updatestatus5'''
	EXEC(@Sql)

 	set @Sql='update exp_jobs set readquery = replace(convert(varchar(max),readquery),''-2'',''-4'')  where 
description in (''ccspGenInCall'',''ccspGenInCallDNI'',''ccspGenOutCall'',''ccspGenAgentStatusNotReady'',''ccspGenInAbnd'',''ccspGenInAnsw'',''ccspGenInCalif'',''ccspGenOutCallCalif'',''ccspGenOutCallDials'',''ccspGenOutCstoResumen'',''ccspGenInCallWG'',''ccspGenInAbndWG'',''ccspGenInAnswWG'',''ccspGenInCalifWG'',''ccspGenOutCallWG'',''ccGenOutCallCalifWG'',''ccGenOutCallDialsWG'')'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE dbo.ccCallsReject(
	cal_id int NOT NULL,
	ani varchar(15) NOT NULL,
	dnis varchar(15) NOT NULL,
	puerto smallint NOT NULL,
	cal_inicio datetime NOT NULL,
	Inbound_id smallint NOT NULL)'
	EXEC(@Sql)

 	set @Sql='insert into Exp_Jobs (ReadQuery, [Description], WriteQuery, Active, IntervalType, Interval, StartTime, EndTime, [Days], 
	DServer, DDataBase, DLogin, DPass, Vars, CnxOrigen, validate, cvalidate, qupdate, useCCenInCNX, useCCRepInDes)

select ''declare @server varchar(200), @sql varchar(8000)
declare @from datetime, @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @calIni as varchar(15)
declare @calfin as varchar(15)
select @calIni = isnull(max(cal_id),1) from '''' + @server +''''.dbo.ccCallsReject 
select @calfin = min(cal_id) from ( select isnull(min(cal_id),0) cal_id from ccCallsReject 
where cal_inicio > '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '''' union all select max(cal_id) cal_id from ccCallsReject as a where cal_id <> 0''''

set @sql = nchar(13) + @sql + ''''select ReadQuery, [Description], WriteQuery, Active, IntervalType, Interval, StartTime, EndTime, [Days], DServer, DDataBase, DLogin, 
DPass, Vars, CnxOrigen, validate, cvalidate, qupdate, useCCenInCNX, useCCRepInDes from ccCallsReject WHERE cal_id > @calIni and cal_id<= @calfin''''

--print @sql
exec(@sql)
exec ccsp_LogInfo @sql, -19'', 
''ccCallsReject'', ''ccCallsReject'', ''1'', ''0'', ''15'', ''1900-01-01 00:01:00'', ''1900-01-01 23:59:00'', ''1111111'', '''', '''', '''', '''', '''', '''', ''0'', '''', '''', ''1'', ''1'''

	EXEC(@Sql)

 	set @Sql='create procedure ccsp_reportInRejectCall
@fFin smalldatetime = null,
@fIni smalldatetime = null,
@dni_numeroS varchar(max) = null
as
set nocount on
declare @SQL varchar(max), @Where varchar(max), @dni_numeroS_MAX varchar(max), @idioma tinyint
declare @campo1 varchar(50), @campo2 varchar(50), @campo3 varchar(50), @campo4 varchar(50), @campo5 varchar(50), @campo6 varchar(50)

select @idioma = valor from ccSettings where setting_id = 23

if @idioma=0
 begin
	select @campo1=''[Numero DNIS]'', @campo2=''[Descripcion DNIS]'', @campo3=''[Descripcion Especialidad]'', @campo4=''[Fecha]'', @campo5=''[Ani]'', @campo6=''[Puerto]''
 end

else
 begin
	select @campo1=''[DNIS Number]'', @campo2=''[DNIS Description]'', @campo3=''[ACD Description]'', @campo4=''[Date]'', @campo5=''[Ani]'', @campo6=''[Port]''
 end

set @dni_numeroS_MAX=''''

set @SQL= ''select CR.dnis '' + @campo1 + '', isnull(DN.dni_descripcion, '''''''') '' + @campo2 + '', isnull(NI.descripcion, '''''''') '' + @campo3 
+ '', convert(varchar(19), cal_inicio, 121) '' + @campo4 + '', CR.ani '' + @campo5 + '', CR.puerto '' + @campo6 
+ nchar(13) + ''from ccCallsReject CR join ccDNIS DN on CR.dnis = DN.dni_numero	left join ccInbound NI on CR.Inbound_id = NI.Inbound_id''

set @Where = nchar(13) + ''Where 1=1''

if @fIni is not null
	set @Where = @Where + '' and convert(varchar(25), cal_inicio, 121) >= '''''' + convert(varchar(25), @fIni, 121) + nchar(39)

if @fFin is not null
	set @Where = @Where + '' and convert(varchar(25), cal_inicio, 121) <= '''''' + convert(varchar(25), @fFin, 121) + nchar(39)

if len(isnull(@dni_numeroS, '''')) > 1
 begin
	select @dni_numeroS_MAX=@dni_numeroS_MAX+coalesce('',''+nchar(39)+value+nchar(39), '','')
	from CCenterRIA.dbo.fn_RIASplitDelimited(replace(@dni_numeroS, nchar(39), ''''), '','')

	set @dni_numeroS_MAX=right(@dni_numeroS_MAX,len(@dni_numeroS_MAX)-1)
	set @Where = @Where + nchar(13) + '' and CR.dnis in ('' + @dni_numeroS_MAX + '')'' 
 end

set @SQL = @SQL + @Where + '' order by cal_inicio desc''

exec(@SQL)
set nocount off'
	EXEC(@Sql)

 	set @Sql='create FUNCTION [dbo].[fn_RIASplitDelimited]
(	
	@List nvarchar(2000),
	@SplitOn nvarchar(1)
)
RETURNS @RtnValue table (
	Id int identity(1,1),
	Value nvarchar(100)
)
AS
BEGIN
	While (Charindex(@SplitOn,@List)>0)
	Begin 
		Insert Into @RtnValue (value)
		Select 
			Value = ltrim(rtrim(Substring(@List,1,Charindex(@SplitOn,@List)-1))) 
		Set @List = Substring(@List,Charindex(@SplitOn,@List)+len(@SplitOn),len(@List))
	End 
	
	Insert Into @RtnValue (Value)
    Select Value = ltrim(rtrim(@List))

    Return
END'
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


