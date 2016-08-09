/*
Autor: Raymundo González
Fecha: 2012/11/16
Descripcion: 
	Se agrega indice IX_ccoCallsOut_7 para acelera consulta del reporte de detalle de marcacion
	Se crea la tabla ccPosicionEspecialidad para reporte de MCA
	Se crea la tabla ccPosicionCamps para reporte de MCA
	Se crea la tabla ccGenMktIntervaloSalida para reporte de MCA
	Se crea el trigger trigPosicionEspecialidad para reporte de MCA
	Se modifica el SP A_cwReportOutCtoProv para los costos por proveedor
	Se modifica el SP A_cwReportOutCtoUser para los costos por usuario
	Se modifica el SP A_cwReportOutCtoCamp para los costos por campaña

Version requerida: 35
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '36'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @Sql = 'IF  NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[ccoCallsOut]'') AND name = N''IX_ccoCallsOut_7'')
CREATE NONCLUSTERED INDEX [IX_ccoCallsOut_7] ON [dbo].[ccoCallsOut](
	[callout_id] ASC,
	[cal_telefono] ASC,
	[cal_inicio] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'

	EXEC(@Sql)

		set @Sql = 'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[ccPosicionEspecialidad]'') AND type in (N''U''))
CREATE TABLE [dbo].[ccPosicionEspecialidad](
	[Inbound_id] [smallint] NULL,
	[User_id] [smallint] NULL,
	[Tipo] [tinyint] NULL,
	[Fecha] [datetime] NULL)'

	EXEC(@Sql)

		set @Sql = 'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[ccPosicionCamps]'') AND type in (N''U''))
CREATE TABLE [dbo].[ccPosicionCamps](
	[cam_id] [smallint] NULL,
	[User_id] [smallint] NULL,
	[Tipo] [tinyint] NULL,
	[Fecha] [datetime] NULL)'

	EXEC(@Sql)

		set @Sql = 'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[ccGenMktIntervaloSalida]'') AND type in (N''U''))
CREATE TABLE ccGenMktIntervaloSalida(
		[dia] [varchar](10) NULL,
		[rango1] [varchar](5) NULL,
		[rango2] [varchar](5) NULL,
		[Staff] [smallint] NULL,
		[Recibidas] [smallint] NULL,
		[Contactos] [smallint] NULL,
		[Abandonadas] [smallint] NULL,
		[TMO] [varchar] (8) NULL,
		[TiempoTotalTT] [varchar] (8) NULL,
		[TiempoTotalHold] [varchar](8) NULL,
		[TiempoTotalACW] [varchar] (8) NULL,
		[TiempoTotalRing] [varchar](8) NULL,
		[TiempoTotalAvail] [varchar](8) NULL,
		[TiempoTotalAUX] [varchar](8) NULL,
		[TiempoPersonal] [varchar](8) NULL,
		[VelocidadResp] [varchar](8) NULL,
		[Reductor] [numeric] (18,2) NULL,
		[Abandono] [numeric] (18,2) NULL,
		[OcupacionCOPC] [numeric](18,2) NULL,
		[Cam_id] [Int] null	)'

	EXEC(@Sql)

		set @Sql = 'IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N''[dbo].[trigPosicionEspecialidad]''))
DROP TRIGGER [dbo].[trigPosicionEspecialidad]'

	EXEC(@Sql)

		set @Sql = 'CREATE TRIGGER [dbo].[trigPosicionEspecialidad] ON [dbo].[ccLogLogin]
	FOR INSERT
	AS
	insert into ccPosicionEspecialidad(Inbound_id,User_id,Tipo,Fecha)
		select c.inbound_id,i.user_id,i.TipoMov,getdate()
		from inserted i
		inner join ccinboundagentes c (nolock)
		on	c.user_id = i.user_id
		
		
	insert into ccPosicionCamps(cam_id,User_id,Tipo,Fecha)
		select c.cam_id,i.user_id,i.TipoMov,getdate()
		from inserted i
		inner join cccampsagente c (nolock)
		on	c.user_id = i.user_id'

	EXEC(@Sql)

		set @Sql='ALTER PROCEDURE [dbo].[A_cwReportOutCtoProv]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4500)='''',
@CblDos as varchar(500) = '''',
@Country_id as varchar(3) = ''1''
as

declare @cursor as varchar (max)

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
DECLARE @sql as varchar(max)
DECLARE @nodiponibles as varchar(4000)
DECLARE @sumNoDip as varchar(5000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(max)
DECLARE @sSQLTot as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where country_id = '' + @Country_id + ''
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where country_id = '' + @Country_id + '' and tipoLlamada_id in ('' + @CblDos + '' )
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

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT '' +case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else '' timegroup'' end +  '' as Fecha, cstoProvedor.descrip AS Proveedor ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
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

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT '' +case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else ''getdate()'' end +'' as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as provedor_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
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

		set @Sql = 'ALTER PROCEDURE [dbo].[A_cwReportOutCtoUser]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4500)='''',
@CblDos as varchar(500) = '''',
@Country_id as varchar(3) = ''1''
AS

declare @cursor as varchar (max)

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
DECLARE @sql as varchar(max)
DECLARE @nodiponibles as varchar(4000)
DECLARE @sumNoDip as varchar(5000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(max)
DECLARE @sSQLTot as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where country_id = '' + @Country_id + ''
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where country_id = '' + @Country_id + '' and tipoLlamada_id in ('' + @CblDos + '' )
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

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT '' +case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else '' timegroup'' end + '' as Fecha, apellidoPaterno + ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'' ''+char(0x27)+''+ char(0x27)+''+char(0x27)+''+ isNull( apellidoMaterno, ''+char(0x27)+''+ char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'')+ ''+char(0x27)+'' + char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' +char(0x27)+''+char(0x27)+''+  nombres as Agente ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
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

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT '' +case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else ''getdate()'' end +'' as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as user_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
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

		set @Sql = 'ALTER PROCEDURE [dbo].[A_cwReportOutCtoCamp]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4000)='''',
@CblDos as varchar(500) = '''',
@Country_id as varchar(3) = ''1''
AS

declare @cursor as varchar (max)

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
DECLARE @sql as varchar(max)
DECLARE @nodiponibles as varchar(4000)
DECLARE @sumNoDip as varchar(5000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(max)
DECLARE @sSQLTot as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where country_id = '' + @Country_id + ''
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where country_id = '' + @Country_id + '' and tipoLlamada_id in ('' + @CblDos + '' )
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

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT '' +case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else '' timegroup'' end +  '' as Fecha, ccCamps.cam_descripcion AS Campana ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
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

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT '' +case @DateG when ''Por Periodo'' then char(0x27)+''''''Periodo''''''+char(0x27) when ''Period'' then char(0x27)+''''''Period''''''+char(0x27) else ''getdate()'' end +'' as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as  cam_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
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
