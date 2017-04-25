/*
Autor: Armando Rodriguez
Fecha: 2010/04/09
Descripcion: Fix en funcion de porcentaje y calculo de costos
Version requerida: 1
*/
set nocount on
if (select valor from ccSettings where setting_id = 24) = '2.0'
	update ccsettings set valor = '0.0' where setting_id = 24

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '2'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 		set @Sql='ALTER   FUNCTION [dbo].[fPorcentaje] (@num1 integer,@num2 integer) 
RETURNS varchar(10)
AS  
BEGIN 
	declare @porcentaje integer
	declare @total as varchar(10)
	declare @decimal as varchar(10)

	set @porcentaje = @num1 * 100
	set @total = @porcentaje / @num2
	set @decimal = @porcentaje % @num2
	set @decimal = @decimal * 100
	set @decimal = @decimal / @num2
        set @total = @total + ''.'' + substring(convert(varchar(10),@decimal),1,2)

	RETURN (@total)
END'
	EXEC(@Sql)

 		set @Sql='ALTER PROCEDURE [dbo].[A_cwReportOutCtoUser]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4500)='''',
@CblDos as varchar(500) = ''''

AS

declare @cursor as varchar (8000)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(4500)
DECLARE @idioma as bit
declare @iva varchar(5)
select @iva=valor from ccsettings where setting_id = 25
select @iva=convert(varchar(5),''1.'' + substring(@iva,(len(@iva)-2),3))

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(4500)
DECLARE @nodiponibles as varchar(1200)
DECLARE @sumNoDip as varchar(1250)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(8000)
DECLARE @sSQLTot as varchar(8000)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where tipoLlamada_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select  distinct nr.timegroup, nr.user_id'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
            set @nodiponibles = @nodiponibles+ ''+char(0x27)+'',['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call] as [Llamadas_''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min] as [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min_Facturados], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            --set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.mins,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.costo,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]''+char(0x27)+''

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
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.user_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.tipoLlamada_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.tipoLlamada_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT timegroup as Fecha, apellidoPaterno + ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'' ''+char(0x27)+''+ char(0x27)+''+char(0x27)+''+ isNull( apellidoMaterno, ''+char(0x27)+''+ char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'')+ ''+char(0x27)+'' + char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' +char(0x27)+''+char(0x27)+''+  nombres as Agente ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT '' + @sGroupDetail + '' as timegroup, user_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL = @sSQL + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL = @sSQL + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY timegroup, user_id ) a''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', user_id ) xDetail ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+''LEFT JOIN ccUsers ON (xDetail.[user_id]=ccUsers.[user_id]) ) ''+char(0x27)+''''

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT getdate() as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as user_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQLTot = @sSQLTot + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' GROUP BY timegroup, user_id ) a) order by Fecha, Agente''+char(0x27)+''


exec ( @sSQL + @sSQLTot)
--print (@sSQL)
--print (@sSQLTot)
''
if @idioma = 1
begin
--set @cursor = replace(@cursor, ''Sesion'', ''Session'')
set @cursor = replace(@cursor, ''Llamadas'', ''Calls'')
set @cursor = replace(@cursor, ''Min_Facturados'', ''Rated_Min'')
set @cursor = replace(@cursor, ''_CostoIVA'', ''_Tax'')
set @cursor = replace(@cursor, ''_Costo'', ''_Cost'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Agente'', ''Agent'')
end

--print(@cursor)
exec (@cursor)'
	EXEC(@Sql)

 		set @Sql='ALTER PROCEDURE [dbo].[A_cwReportOutCtoProv]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(300)='''',
@CblDos as varchar(150) = ''''
as

declare @cursor as varchar (8000)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(520)
DECLARE @idioma as bit
declare @iva varchar(5)
select @iva=valor from ccsettings where setting_id = 25
select @iva=convert(varchar(5),''1.'' + substring(@iva,(len(@iva)-2),3))

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(4500)
DECLARE @nodiponibles as varchar(1200)
DECLARE @sumNoDip as varchar(1250)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(8000)
DECLARE @sSQLTot as varchar(8000)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where tipoLlamada_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select  distinct nr.timegroup, nr.provedor_id'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
            set @nodiponibles = @nodiponibles+ ''+char(0x27)+'',['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call] as [Llamadas_''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min] as [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min_Facturados], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            --set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
	    set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.mins,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.costo,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]''+char(0x27)+''
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
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.provedor_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.tipoLlamada_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.tipoLlamada_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT timegroup as Fecha, cstoProvedor.descrip AS Proveedor ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT '' + @sGroupDetail + '' as timegroup, provedor_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL = @sSQL + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL = @sSQL + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY timegroup, provedor_id ) a''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', provedor_id ) xDetail ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' LEFT JOIN cstoProvedor ON (xDetail.provedor_id=cstoProvedor.provedor_id) ) ''+char(0x27)+''''

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT getdate() as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as provedor_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQLTot = @sSQLTot + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' GROUP BY timegroup, provedor_id ) a) order by Fecha, Proveedor''+char(0x27)+''


exec ( @sSQL + @sSQLTot)
--print (@sSQL)
--print (@sSQLTot)
''

if @idioma = 1
begin
set @cursor = replace(@cursor, ''Llamadas'', ''Calls'')
set @cursor = replace(@cursor, ''Min_Facturados'', ''Rated_Min'')
set @cursor = replace(@cursor, ''_CostoIVA'', ''_Tax'')
set @cursor = replace(@cursor, ''_Costo'', ''_Cost'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Proveedor'', ''Supplier'')
end

exec (@cursor)'
	EXEC(@Sql)

 		set @Sql='ALTER PROCEDURE [dbo].[A_cwReportOutCtoCamp]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4000)='''',
@CblDos as varchar(500) = ''''

AS

declare @cursor as varchar (8000)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(4500)
DECLARE @idioma as bit
declare @iva varchar(5)
select @iva=valor from ccsettings where setting_id = 25
select @iva=convert(varchar(5),''1.'' + substring(@iva,(len(@iva)-2),3))

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(4500)
DECLARE @nodiponibles as varchar(1250)
DECLARE @sumNoDip as varchar(1650)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)
DECLARE @sSQL as varchar(8000)
DECLARE @sSQLTot as varchar(8000)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where tipoLlamada_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select  distinct nr.timegroup, nr.cam_id'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
            set @nodiponibles = @nodiponibles+ ''+char(0x27)+'',['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call] as [Llamadas_''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min] as [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min_Facturados], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            --set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
              set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.mins,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.costo,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]''+char(0x27)+''
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
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.cam_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.tipoLlamada_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.tipoLlamada_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT timegroup as Fecha, ccCamps.cam_descripcion AS Campana ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT '' + @sGroupDetail + '' as timegroup, cam_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL = @sSQL + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL = @sSQL + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY timegroup, cam_id ) a''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', cam_id ) xDetail ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' LEFT JOIN ccCamps ON (xDetail.cam_id=ccCamps.cam_id) ) ''+char(0x27)+''''

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT getdate() as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as  cam_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQLTot = @sSQLTot + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' GROUP BY timegroup, cam_id ) a) order by Fecha, Campana''+char(0x27)+''


exec ( @sSQL + @sSQLTot)
--print (@sSQL)
--print (@sSQLTot)
''

if @idioma = 1
begin
set @cursor = replace(@cursor, ''Llamadas'', ''Calls'')
set @cursor = replace(@cursor, ''Min_Facturados'', ''Rated_Min'')
set @cursor = replace(@cursor, ''_CostoIVA'', ''_Tax'')
set @cursor = replace(@cursor, ''_Costo'', ''_Cost'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Campana'', ''Campaign'')
end

exec (@cursor)'
	EXEC(@Sql)

 		set @Sql='ALTER PROCEDURE [dbo].[A_cwRepInbCalif]
@DateG as varchar(20),
@CamAgt as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(500)='''',
@CblDos as varchar(300) = ''''

AS

declare @cursor as varchar (8000)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(820)
DECLARE @idioma as bit

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(8000)
DECLARE @sql1 as varchar(8000)
DECLARE @nodiponibles as varchar(5000)
DECLARE @sumNoDip as varchar(8000)
DECLARE @sumNoDip2 as varchar(8000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(8000)
DECLARE @sSQL1 AS varchar(8000)
DECLARE @sSQL2 AS varchar(8000)
declare @contDet as integer
declare @contSum as integer

set @contDet = 0
set @contSum = 0

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select calif_id, Description from ccTipoCalif
''
    end
    else
    begin
	set @cursor = @cursor +''select calif_id, Description from ccTipoCalif where calif_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select distinct nr.timegroup, nr.inbound_id, nr.user_id'' + char(0x27)+ ''
set @sql1 = ''+char(0x27) + ''''+char(0x27) + ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip2 = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
		set @contDet = @contDet +1
		set @contSum = @contSum +1
                       	set @nodiponibles = @nodiponibles+ ''+char(0x27)+'', ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
		IF @contSum < 125
		begin
                        		set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum( ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
		end
		else
		begin
                        		set @sumNoDip2 = @sumNoDip2 + ''+char(0x27)+'', sum( ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
		end

		IF @contDet < 82
		begin
			set @sql = @sql+''+char(0x27)+'', sum(case when calif_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
		end
		else
		begin
			set @sql1 = @sql1+''+char(0x27)+'', sum(case when calif_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
		end
		Fetch Next From CCampos
		Into  @id, @desc
		End
	End

CLOSE CCampos 
DEALLOCATE CCampos 
''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.inbound_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.calif_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.calif_id IN ('' + @CblDos + '')''
end

if @CamAgt = ''Especialidad'' or @CamAgt = ''ACD group''
begin

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''SELECT timegroup as Fecha,ccInbound.descripcion AS Especialidad ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( SELECT '' + @sGroupDetail + '' as timegroup, inbound_id''+char(0x27)+'' 
set @sSQL1 = @sumNoDip2  + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL2 =  + ''+char(0x27)+'' FROM ccGenInCalif as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL2 = @sSQL2 + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY nr.timegroup, nr.inbound_id, nr.user_id ) a''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', inbound_id) xDetail ''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' LEFT JOIN ccInbound ON (xDetail.inbound_id=ccInbound.inbound_id) order by Fecha, Especialidad''+char(0x27)+''

exec (@sSQL + @sumNoDip + @sSQL1 + @sql + @sql1 + @sSQL2  )
''
end
if @CamAgt = ''Agente'' or @CamAgt = ''Agent''
begin

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''SELECT timegroup as Fecha, apellidoPaterno + ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'' ''+char(0x27)+''+ char(0x27)+''+char(0x27)+''+ isNull( apellidoMaterno, ''+char(0x27)+''+ char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'')+ ''+char(0x27)+'' + char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' +char(0x27)+''+char(0x27)+''+  nombres as Agente ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( SELECT '' + @sGroupDetail + '' as timegroup, [user_id]''+char(0x27)+'' 
set @sSQL1 =  @sumNoDip2 + ''+char(0x27)+'' from ( ''+char(0x27)+'' 
set @sSQL2 =  + ''+char(0x27)+'' FROM ccGenInCalif as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL2 = @sSQL2 + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY nr.timegroup, nr.inbound_id, nr.user_id ) a''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', [user_id]) xDetail ''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' LEFT JOIN ccUsers ON (xDetail.[user_id]=ccUsers.[user_id]) order by Fecha, Agente''+char(0x27)+''

exec (@sSQL + @sumNoDip + @sSQL1 + @sql + @sql1 + @sSQL2  )
''
end

if @idioma = 1
begin
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Agente'', ''Agent'')
set @cursor = replace(@cursor, ''Especialidad'', ''Specialty'')
end

exec (@cursor)'
	EXEC(@Sql)

 		set @Sql='ALTER TABLE dbo.Exp_Jobs ADD
	useCCenInCNX tinyint NOT NULL CONSTRAINT DF_Exp_Jobs_useCCenInCNX DEFAULT 0,
	useCCRepInDes tinyint NOT NULL CONSTRAINT DF_Exp_Jobs_useCCRepInDes DEFAULT 0'
	EXEC(@Sql)

 		set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate)
values(''ccspGenCatalogos'',
''declare @server varchar(50)
select @server = valor from ccSettings where setting_id = 22
exec ccspGenCatalogos @server'',
''*N/A*'',1,0,10,''01/01/1900 05:00'',''01/01/1900 05:15'',''1111111'','''','''','''','''','''',''cwserver|ccenter|ccuser|guess'',0,'''','''')'
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


