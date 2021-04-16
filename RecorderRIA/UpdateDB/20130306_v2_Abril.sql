/*

Fecha: 2013/04/19
Descripcion: 	

Version requerida: 1
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 2
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

set @Sql = '
CREATE PROCEDURE [dbo].[trsp_GetRepositorio]
@id_rep as tinyint,
@InIniPort as smallint,
@InFinPort as smallint,
@OutIniPort as smallint,
@OutFinPort as smallint
AS
BEGIN

declare @Cont as tinyint
declare @Path as varchar(120)

SELECT @Cont=count(*)  FROM INFORMATION_SCHEMA.tables where table_name = ''trec_repositorios''
if @Cont > 0
begin
	select @Path=ruta_repositorio from trec_repositorios where id_repositorio = @id_rep
	if (@Path is not null)
	begin
		update trec_repositorios set InIniPort=@InIniPort, InFinPort=@InFinPort, OutIniPort=@OutIniPort, OutFinPort=@OutFinPort
			where id_repositorio = @id_rep
		select @Path as ''PathRepositorio''
		return
	end
end
select @Path=par_valor  from trec_parametros where par_id = 1
select @Path as ''PathRepositorio''
END
'
EXEC(@Sql)


set @Sql = '
ALTER TABLE trec_parametros
ALTER COLUMN par_valor varchar(100)
'
EXEC(@Sql)


set @Sql = '

ALTER PROCEDURE [dbo].[trsp_GetFilesAnalisisGritos] 
@idRepositorios as varchar(32),
@sExtension as varchar(10) = ''.vox''
AS

declare @Integrado as int
declare @FInicio as datetime
declare @sSql1 as nvarchar(180)
declare @sSql2 as nvarchar (180)
declare @sSql3 as nvarchar(180) 
declare @sSql as nvarchar (512)
declare @dLenAnt as tinyint
declare @dLenNew as tinyint


set @FInicio = dateadd(hh, -1, getdate())
set @sSql = N''''
set @sSql3 = N''''
set @sExtension = (select par_valor from trec_parametros where par_id = 54)

select @integrado =count(*) from trec_parametros where par_id = 29
if (@integrado > 0)
	select @integrado = par_valor from trec_parametros where par_id = 29
set @sSql2 = '', isnull(tipo_llamada,0) from ria_grabacion NOLOCK where finicio < @fecInicio '' 
set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''
if (@integrado = 1)
	set @sSql1 = ''Select top 1000 grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
	--set @sSql1 = ''Select top 1000 grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+''.VOX''+char(0x27)
else
	set @sSql1 = ''Select top 1000 grab_id, grab_id, cast(grab_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
	--set @sSql1 = ''Select top 1000 grab_id, grab_id, cast(grab_id as varchar(20))+''+char(0x27)+''.VOX''+char(0x27)
if (@idRepositorios <> '''')
begin
	set @dLenAnt = len(@idRepositorios)
	set @idRepositorios = replace(@idRepositorios, ''NULL'', '''')
	if (len(@idRepositorios) = 0)   -- solo solicita NULL
		set @sSql3 = '' and id_repositorio is NULL ''
	else
	begin
		set @dLenNew = len(@idRepositorios) 
		if (@dLenNew = @dLenAnt)
			set @sSql3 = '' and id_repositorio in ('' + @idRepositorios +'')''
		else
		begin
			set @idRepositorios = right(@idRepositorios, @dLenNew-1)
			set @sSql3 = '' and (id_repositorio in ('' + @idRepositorios +'') or (id_repositorio is NULL)) ''
		end
	end
end
set @sSql = @sSql1 + @sSql2 + @sSql3 + N'' order by finicio asc''
--print (@sSql)
exec sp_executesql @sSql, N''@fecInicio datetime'', @fecInicio = @FInicio
'

EXEC(@Sql)


	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			--exec dbo.ccsp_getVersion 'BD', @Version

	-- Updating DB Version
	
update trec_parametros set par_valor = '2' where par_id = 30 

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC], ERROR_PROCEDURE()
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