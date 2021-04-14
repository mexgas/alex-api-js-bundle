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

set @process = 'CW-5024 Verificar si existe el trsp_AdmRecSearchRecs'
	set @sql = 'if exists (select * from sys.procedures where name = N''trsp_AdmRecSearchRecs'')
            begin
          DROP PROCEDURE trsp_AdmRecSearchRecs;
            end
			
			'
    EXEC(@sql)


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

set @process = 'CW-5024 Se altera el SP trsp_AdmRecSearchRecs para poder para poder realizar la exportacion masiva'
set @Sql = '
CREATE PROCEDURE [dbo].[trsp_AdmRecSearchRecs]
				@grabIds nvarchar(max)

				AS
				BEGIN

				SET NOCOUNT ON

					declare @sql nvarchar(max)
					declare @isEncrypted bit

					select @isEncrypted=par_valor from TREC_PARAMETROS where par_id=15


					select id_repositorio, ruta_repositorio
					into #tmpRepositorios
					from TREC_REPOSITORIOS
					where id_repositorio in (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential in
						(select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio


					set @sql="select a.grab_id as grabID,a.cal_id, a.Tipo_llamada, a.id_repositorio,b.ruta_repositorio as repository,
						case a.Tipo_llamada when 2 then ""OUTBOUND\"" else ""INBOUND\"" end + cast(floor(a.cal_id/10000) as nvarchar(max)) as subpath,
						case a.Tipo_llamada when 2 then ""O_"" else ""I_"" end + cast(a.cal_id as nvarchar(max)) + 
						case a.Tipo_llamada when 2 then 	
							case isnull(camp.prefijo,"""") when """" then """" else ""_"" + camp.prefijo end 	
							else
							case isnull(acds.prefijo,"""") when """" then """" else ""_"" + acds.prefijo end 				
						end + "".wav"" +
						case "+cast(@isEncrypted as nvarchar(max)) +" when 1 then "".enc"" else """" end  fileAudio,
						case a.tipo_llamada when 2 then camp.cam_descripcion else acds.descripcion end campacd
						from RIA_GRABACION a
						inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio
						left join cccamps camp on a.cam_id = camp.cam_id
						left join ccinbound acds on a.cam_id = acds.Inbound_id
						where a.grab_id in("+@grabIds+")
						union
						select a.grab_id as grabID,a.cal_id, a.Tipo_llamada, a.id_repositorio,b.ruta_repositorio as repository,
						case a.Tipo_llamada when 2 then ""OUTBOUND\"" else ""INBOUND\"" end + cast(floor(a.cal_id/10000) as nvarchar(max)) as subpath,
						case a.Tipo_llamada when 2 then ""O_"" else ""I_"" end + cast(a.cal_id as nvarchar(max)) +
						case a.Tipo_llamada when 2 then 	
							case isnull(camp.prefijo,"""") when """" then """" else ""_"" + camp.prefijo end 	
							else
							case isnull(acds.prefijo,"""") when """" then """" else ""_"" + acds.prefijo end 					
						end + "".wav"" +
						case "+cast(@isEncrypted as nvarchar(max)) +" when 1 then "".enc"" else """" end  fileAudior,
						case a.tipo_llamada when 2 then camp.cam_descripcion else acds.descripcion end campacd
						from RIA_GRABACIONCONSULTA a
						inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio
						left join cccamps camp on a.cam_id = camp.cam_id
						left join ccinbound acds on a.cam_id = acds.Inbound_id
						where a.grab_id in("+@grabIds+")"
					print @sql
					exec (@sql)

					drop table #tmpRepositorios

				END'
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