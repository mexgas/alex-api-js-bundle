/*
Autor: Armando Rodriguez
Fecha: 2011/02/01
Descripcion: Actualizacion de sp para corregir problema cuando no muestra todos los tipos de ND
Version requerida: 13
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '14'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='ALTER PROCEDURE [dbo].[A_cwRepNotReady]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4000)='''',
@CblDos as varchar(1500) = ''''

AS
declare @cursor as varchar (Max)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(max)
DECLARE @idioma as bit

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(max)
DECLARE @sql2 as varchar(max)
DECLARE @nodiponibles as varchar(8000)
DECLARE @sumNoDip as varchar(8000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)
DECLARE @totalC as varchar(250)
DECLARE @totalT as varchar(250)

DECLARE @sSQL as varchar(max)
DECLARE @sSQL2 as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select TipoNotReady_id, Descripcion from ccTipoNotReady
''
    end
    else
    begin
	set @cursor = @cursor +''select TipoNotReady_id, Descripcion from ccTipoNotReady where TipoNotReady_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select distinct nr.user_id, nr.timegroup,'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + '' dbo.fGetHHmmSS (Sesion) Sesion''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + '' sum(Sesion) Sesion ''+char(0x27) + ''
set @totalC = ''+char(0x27) + '', sum (0''+char(0x27) + ''
set @totalT = ''+char(0x27) + '', sum (0''+char(0x27) + ''
set @sql = @sql+ ''+char(0x27) + '' (select isnull(SUM(tlog),'' +char(0x27)+''+ char(0x27) + char(0x27) +'' +char(0x27)+'') from ccGenAgent where user_id = nr.user_id and timegroup =  nr.timegroup ) Sesion ''+char(0x27) + ''
set @sql2 =  ''+char(0x27) +char(0x27) + ''

Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
                set @totalC = @totalC + ''+char(0x27)+''+ sum([''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto])'' +char(0x27) + ''
                set @totalT = @totalT + ''+char(0x27)+''+ sum([''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo])'' +char(0x27) + ''
                set @nodiponibles = @nodiponibles+ ''+char(0x27)+'', ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto], dbo.fGetHHmmSS ([''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]) [''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
                set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
				if @id  < 35
				begin
					set @sql = @sql+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amountReal,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto]''+char(0x27)+''
					set @sql = @sql+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(time,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
			    end
			    else
			    begin
			    	set @sql2 = @sql2+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amountReal,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto]''+char(0x27)+''
					set @sql2 = @sql2+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(time,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
			    end
			
			Fetch Next From CCampos
			Into  @id, @desc
		End
	End

--print @sql
--print @nodiponibles
--print @sumNoDip


CLOSE CCampos 
DEALLOCATE CCampos 
''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''  timegroup,''
   set @sGroup = ''timegroup ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
--   set @sGroupDetail = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121), ''
 --  set @sGroup = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121) ''
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121), ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''

end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
   set @sGroupDetail = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121), ''
   set @sGroup = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121) ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' [user_id] in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and tiponotready_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' tiponotready_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + ''set @sSQL = ''+char(0x27)+''SELECT Login, timegroup as Fecha, apellidoPaterno + ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'' ''+char(0x27)+''+ char(0x27)+''+char(0x27)+''+ isNull( apellidoMaterno, ''+char(0x27)+''+ char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'')+ ''+char(0x27)+'' + char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' +char(0x27)+''+char(0x27)+''+  nombres as Agente, ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT ''+ @sGroup +'' as timegroup , [user_id], ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL2 = @sql2+  ''+char(0x27)+'' FROM ccGenAgentNotReady as nr WHERE timegroup >= ''+char(0x27)+'' + char(0x27) + '' +char(0x27)+ @fini +char(0x27)+ '' + char(0x27) + ''+char(0x27)+'' AND timegroup < ''+char(0x27)+'' + char(0x27) + '' +char(0x27)+ @ffin +char(0x27)+ '' + char(0x27) 
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL2 = @sSQL2 + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY  nr.timegroup, [user_id] ) as a WHERE timegroup >= ''+char(0x27)+'' + char(0x27)+ '' +char(0x27)+ @fini +char(0x27)+ ''+ char(0x27)+ ''+char(0x27)+'' AND timegroup < ''+char(0x27)+'' + char(0x27)+ '' +char(0x27)+ @ffin +char(0x27)+ '' + char(0x27) + ''+char(0x27)+''''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '' [user_id]  ) xDetail ''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' INNER JOIN ccUsers ON (xDetail.[user_id]=ccUsers.[user_id]) AND ccUsers.filter = 1 ORDER BY Fecha, Agente ''+char(0x27)+''

exec ( @sSQL + @sSQL2)
--print (@sSQL)
--print (@sSQL2)
''
if @idioma = 1
begin
set @cursor = replace(@cursor, ''Sesion'', ''Session'')
set @cursor = replace(@cursor, ''_Monto'', ''_Count'')
set @cursor = replace(@cursor, ''_Tiempo'', ''_Time'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Agente'', ''Agent'')
end

--print (@cursor)
exec (@cursor)
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


