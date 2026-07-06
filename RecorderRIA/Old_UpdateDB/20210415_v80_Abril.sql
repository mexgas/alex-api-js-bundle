set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 80
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try
	
    set @process = 'CW-5024 Se altera el SP trsp_AdmRecSearchRecs para poder para poder realizar la exportacion masiva'
		set @Sql = '
ALTER PROCEDURE [dbo].[trsp_AdmRecSearchRecs]
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


	set @sql=''select a.grab_id as grabID,a.cal_id, a.Tipo_llamada, a.id_repositorio,b.ruta_repositorio as repository,
		case a.Tipo_llamada when 2 then ''''OUTBOUND\'''' else ''''INBOUND\'''' end + cast(floor(a.cal_id/10000) as nvarchar(max)) as subpath,
		case a.Tipo_llamada when 2 then ''''O_'''' else ''''I_'''' end + cast(a.cal_id as nvarchar(max)) + 
		case a.Tipo_llamada when 2 then 	
			case isnull(camp.prefijo,'''''''') when '''''''' then '''''''' else ''''_'''' + camp.prefijo end 	
			else
			case isnull(acds.prefijo,'''''''') when '''''''' then '''''''' else ''''_'''' + acds.prefijo end 				
		end + ''''.wav'''' +
		case ''+cast(@isEncrypted as nvarchar(max)) +'' when 1 then ''''.enc'''' else '''''''' end  fileAudio,
		case a.tipo_llamada when 2 then camp.cam_descripcion else acds.descripcion end campacd
		from RIA_GRABACION a
		inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio
		left join cccamps camp on a.cam_id = camp.cam_id
		left join ccinbound acds on a.cam_id = acds.Inbound_id
		where a.grab_id in(''+@grabIds+'')
		union
		select a.grab_id as grabID,a.cal_id, a.Tipo_llamada, a.id_repositorio,b.ruta_repositorio as repository,
		case a.Tipo_llamada when 2 then ''''OUTBOUND\'''' else ''''INBOUND\'''' end + cast(floor(a.cal_id/10000) as nvarchar(max)) as subpath,
		case a.Tipo_llamada when 2 then ''''O_'''' else ''''I_'''' end + cast(a.cal_id as nvarchar(max)) +
		case a.Tipo_llamada when 2 then 	
			case isnull(camp.prefijo,'''''''') when '''''''' then '''''''' else ''''_'''' + camp.prefijo end 	
			else
			case isnull(acds.prefijo,'''''''') when '''''''' then '''''''' else ''''_'''' + acds.prefijo end 					
		end + ''''.wav'''' +
		case ''+cast(@isEncrypted as nvarchar(max)) +'' when 1 then ''''.enc'''' else '''''''' end  fileAudior,
		case a.tipo_llamada when 2 then camp.cam_descripcion else acds.descripcion end campacd
		from RIA_GRABACIONCONSULTA a
		inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio
		left join cccamps camp on a.cam_id = camp.cam_id
		left join ccinbound acds on a.cam_id = acds.Inbound_id
		where a.grab_id in(''+@grabIds+'')''
	print @sql
	exec (@sql)

	drop table #tmpRepositorios

END
		'
		EXEC(@Sql)

			

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
