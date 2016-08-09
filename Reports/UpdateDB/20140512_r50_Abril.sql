/*
Autor: Jesus Gallardo
Fecha: 2014/05/12
Descripcion:
	Se modifica el SP A_cwRepNotReady desbordamiento de variables
	Se modifica el SP A_cwReportMnzCalif desbordamiento de variables 
	
Version requerida: 49
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '50'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @process = 'A_cwRepNotReady - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[A_cwRepNotReady]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(max)='''',
@CblDos as varchar(4000) = ''''

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
DECLARE @nodiponibles as varchar(max)
DECLARE @sumNoDip as varchar(max)
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

set @cursor = @cursor + ''set @sSQL = ''+char(0x27)+''SELECT Login, ''+case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else '' timegroup'' end +  '' as Fecha, apellidoPaterno + ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'' ''+char(0x27)+''+ char(0x27)+''+char(0x27)+''+ isNull( apellidoMaterno, ''+char(0x27)+''+ char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'')+ ''+char(0x27)+'' + char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' +char(0x27)+''+char(0x27)+''+  nombres as Agente, ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
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
 
 		set @process = 'A_cwReportMnzCalif - Alter Procedure'
 		set @Sql='ALTER PROCEDURE [dbo].[A_cwReportMnzCalif]
 @idusuario int,
 @fini varchar(19),
 @ffin varchar(19),
 @usrs varchar(max),
 @camp varchar(4000),
 @filtro2 varchar(200),
 @qry text = ''''
AS

declare @isRoot as smallint
declare @queryStr as varchar(4500)
declare @optionsStr as varchar(8000)
declare @optionsStr1 as varchar(max)
declare @where as varchar(300)
select @isRoot= count(*) from ccUsers where login like ''ROOT'' and user_id = @idusuario

set  @optionsStr1 = ''''

if @filtro2 = '''' begin
set @where = '' 9,4,29,18,25,11,53,13,2,27,17,3,12,7,5,26''
end
else begin
set @where =  @filtro2 
end



set @queryStr = 
''declare @outaclaracion  integer; ''+
''declare @outalcorriente  integer; ''+
''declare @outcontacto  integer; ''+
''declare @outcontestadora integer; ''+
''declare @outconvenio  integer; ''+
''declare @outevasivo  integer; ''+
''declare @outilocalizable integer; ''+
''declare @outliquidada  integer; ''+
''declare @outllamadacolgada integer; ''+
''declare @outllamadahueca integer; ''+
''declare @outninguna  integer; ''+
''declare @outnocontesta  integer; ''+
''declare @outnumeroequivocado integer; ''+
''declare @outpagoparcial  integer; ''+
''declare @outpromesa  integer; ''+
''declare @outrecado  integer; ''+
''declare @outrecadoefectivo integer; ''+''declare @otro integer; ''+char(10)

set @queryStr = @queryStr
+''select @outaclaracion = max(case when [description] like ''''ACLARACION'''' then calif_id else -1 end),'' 
+''@outalcorriente  = max(case when [description] like ''''AL CORRIENTE'''' then calif_id else -1 end), ''
+''@outcontacto  = max(case when [description] like ''''CONTACTO'''' then calif_id else -1 end), ''
+''@outcontestadora = max(case when [description] like ''''CONTESTADORA'''' then calif_id else -1 end), ''
+''@outconvenio  = max(case when [description] like ''''CONVENIO'''' then calif_id else -1 end), ''
+''@outevasivo  = max(case when [description] like ''''EVASIVO'''' then calif_id else -1 end), ''
+''@outilocalizable = max(case when [description] like ''''ILOCALIZABLE'''' then calif_id else -1 end), ''
+''@outliquidada  = max(case when [description] like ''''LIQUIDADA'''' then calif_id else -1 end), ''
+''@outllamadacolgada = max(case when [description] like ''''LLAMADA COLGADA'''' then calif_id else -1 end), ''
+''@outllamadahueca = max(case when [description] like ''''LLAMADA HUECA'''' then calif_id else -1 end), ''
+''@outninguna  = 0, ''
+''@outnocontesta  = max(case when [description] like ''''NO CONTESTA'''' then calif_id else -1 end), ''
+''@outnumeroequivocado = max(case when [description] like ''''NUMERO EQUIVOCADO'''' then calif_id else -1 end), ''
+''@outpagoparcial  = max(case when [description] like ''''PAGO PARCIAL'''' then calif_id else -1 end), ''
+''@outpromesa  = max(case when [description] like ''''PROMESA'''' then calif_id else -1 end), ''
+''@outrecado   = max(case when [description] like ''''RECADO'''' then calif_id else -1 end), ''
+''@outrecadoefectivo = max(case when [description] like ''''RECADO EFECTIVO'''' then calif_id else -1 end), ''
+''@otro = 0 ''
+''from ccTipoCalifOut; ''+char(10)

set @optionsStr = ''''
+''SELECT ''
+''usr.Login AS CCENTER, ''
+''usr.Nombres+'''' ''''+ISNULL(usr.ApellidoPaterno,'''''''')+'''' ''''+ISNULL(usr.ApellidoMaterno,'''''''') as ASESOR, ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outaclaracion        THEN goc.amount end),0) AS [ACLARACION], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outalcorriente    THEN goc.amount end),0) AS [AL CORRIENTE], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outcontacto     THEN goc.amount end),0) AS [CONTACTO], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outcontestadora    THEN goc.amount end),0) AS [CONTESTADORA], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outconvenio     THEN goc.amount end),0) AS [CONVENIO], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outevasivo     THEN goc.amount end),0) AS [EVASIVO], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outilocalizable    THEN goc.amount end),0) AS [ILOCALIZABLE], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outliquidada   THEN goc.amount end),0) AS [LIQUIDADA], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outllamadacolgada    THEN goc.amount end),0) AS [LLAMADA COLGADA], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outllamadahueca    THEN goc.amount end),0) AS [LLAMADA HUECA], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outninguna     THEN goc.amount end),0) AS [NINGUNA], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outnocontesta     THEN goc.amount end),0) AS [NO CONTESTAN], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outnumeroequivocado   THEN goc.amount end),0) AS [NUMERO EQUIVOCADO], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outpagoparcial    THEN goc.amount end),0) AS [PAGO PARCIAL], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outpromesa     THEN goc.amount end),0) AS [PROMESA], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outrecado     THEN goc.amount end),0) AS [RECADO], ''
+''ISNULL(SUM(CASE goc.calif_id WHEN @outrecadoefectivo  THEN goc.amount end),0) AS [RECADO EFECTIVO], ''
+''ISNULL(SUM(CASE WHEN goc.calif_id not in ( '' + @where + '' )  THEN goc.amount end),0) AS [Otro], ''
+''ISNULL(SUM(CASE WHEN goc.calif_id  > 1''
--+''  in( @outaclaracion, ''
---+''@outalcorriente, ''
--+''@outcontacto, ''
--+''@outcontestadora, ''
--+''@outconvenio, ''
--+''@outevasivo, ''
--+''@outilocalizable, ''
--+''@outliquidada, ''
--+''@outllamadacolgada, ''
--+''@outllamadahueca, ''
--+''@outninguna, ''
--+''@outnocontesta, ''
--+''@outnumeroequivocado, ''
--+''@outpagoparcial, ''
--+''@outpromesa, ''
--+''@outrecado, ''
--+''@outrecadoefectivo, ''
--+''@otro )''
+'' THEN goc.amount end),0) AS [TOTAL] ''
+''FROM ''
+''ccUsers as usr, ''
+''ccGenOutCallCalif as goc ''
+''WHERE
 ''

	if (len(@usrs) > 0)
	begin
	  set @optionsStr1 = @optionsStr1 + ''goc.[user_id] IN (''+@usrs+'' ) AND ''
	end
	else
	begin
	 if @isRoot < 1 
            begin
                set @optionsStr1 = @optionsStr1 + ''goc.user_id in ''
                +''( select distinct * from ( (select user_id from cccampsagente where cam_id in ( ''
                + @camp
                +''))) as blah  ''
                +'') AND ''
            end
        end
        set @optionsStr1 = @optionsStr1 + ''usr.Status = 1 AND usr.TipoUser_id = 1 AND goc.[user_id] = usr.[user_id] '' 
+'' AND goc.timegroup BETWEEN ''''''+ @fini +'''''' AND ''''''+  @ffin +'''''''' 
+''GROUP BY usr.ApellidoPaterno,usr.ApellidoMaterno, usr.Nombres,usr.login ''
+''ORDER BY usr.login ''

exec (@queryStr + @optionsStr + @optionsStr1)

--print (@queryStr + @optionsStr)
-- print (@optionsStr1)'
 		
	EXEC(@Sql)
			
------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
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
