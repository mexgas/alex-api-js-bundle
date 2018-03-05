/*
Autor: Omar Mejia
Descripcion:


Version requerida: 44
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 47
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	
	set @process = 'Create stored procedure ccspAgent_GetRepositoryForCall CW-1296 Reproduccion de grabaciones'
 	set @sql ='
	CREATE PROCEDURE [dbo].[ccspAgent_GetRepositoryForCall]
@cal_id int,
@type varchar(10)
AS
set nocount on
declare @id_repository as tinyint
declare @sql nvarchar(max)
declare @isEncrypted bit

select @id_repository=id_repositorio from RIA_GRABACION  where cal_id=@cal_id and tipo_llamada=case when @type=''OUT'' then 2 else 1 end
select @isEncrypted=par_valor from TREC_PARAMETROS where par_id=15

--print @id_repository
select id_repositorio, dirvirtual_audio, ruta_local, dirvirtual_video, ruta_local_video, ruta_imagenes, ruta_repositorio, ruta_rep_video, Cred.domain, Cred.[user], Cred.[password]
into #tmpRepositorios
from TREC_REPOSITORIOS Rep
inner join TREC_REPO_NWCREDENTIALS  RepCred on Rep.id_repositorio =repCred.id_repository and Rep.id_repositorio= @id_repository
inner join RIA_NETWORKCREDENTIALS  Cred on RepCred.id_nwCredential=Cred.id
where Cred.type = 1 and status=1

set @sql=''select a.id_repositorio as id_repository,b.ruta_repositorio as repository,b.domain,
		case a.Tipo_llamada when 2 then ''''OUTBOUND\'''' else ''''INBOUND\'''' end + cast(floor(a.cal_id/10000) as nvarchar(max)) as subpath,
		case a.Tipo_llamada when 2 then ''''O_'''' else ''''I_'''' end + cast(a.cal_id as nvarchar(max)) + ''''.wav''''
		+ case ''+cast(@isEncrypted as nvarchar(max)) +'' when 1 then ''''.enc'''' else '''''''' end  fileAudio,
		 b.[user], b.[password],b.dirvirtual_audio,''+cast(@isEncrypted as nvarchar(max)) +'' as isEncrypted
		from RIA_GRABACION a
		inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio
		where a.cal_id=''+cast(@cal_id as nvarchar(max))+'' and a.tipo_llamada=case when ''''''+@type+''''''= ''''OUT'''' then 2 else 1 end
		union
		select a.id_repositorio as id_repository,b.ruta_repositorio as repository,b.domain,
		case a.Tipo_llamada when 2 then ''''OUTBOUND\'''' else ''''INBOUND\'''' end + cast(floor(a.cal_id/10000) as nvarchar(max)) as subpath,
		case a.Tipo_llamada when 2 then ''''O_'''' else ''''I_'''' end + cast(a.cal_id as nvarchar(max)) + ''''.wav''''
		+ case ''+cast(@isEncrypted as nvarchar(max)) +'' when 1 then ''''.enc'''' else '''''''' end  fileAudio,
		 b.[user], b.[password],b.dirvirtual_audio,''+cast(@isEncrypted as nvarchar(max)) +'' as isEncrypted
		from RIA_GRABACIONCONSULTA a
		inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio
		where a.cal_id=''+cast(@cal_id as nvarchar(max))+'' and a.tipo_llamada=case when ''''''+@type+'''''' = ''''OUT'''' then 2 else 1 end''
	exec (@sql)
	drop table #tmpRepositorios
	'
	
	EXEC(@sql)


------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
