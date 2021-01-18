set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 76
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try
	
    SET @process = 'CW-4797 agrega dirvirtual_audio en la desencriptar'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccspGalatea_Finder]
@action int,
@grabIds varchar(max)=null,
@grabId int =null,
@userId int =0,	
@markTime int=null,
@markId int=null
AS
BEGIN

    SET NOCOUNT ON;
	declare @sql varchar(max)

	if @action=1 begin
		select id_repositorio as repositoryId,dirvirtual_audio as pathAudio,dirvirtual_video as pathVideo,ruta_repositorio as pathRepositoryAudio from TREC_REPOSITORIOS
	end
	else if @action=2 begin
		set @sql=''
		;
		with grab as (
		select grab_id,cal_id,tipo_llamada from RIA_GRABACION where grab_id in(''+@grabIds+'')
		union
		select grab_id,cal_id,tipo_llamada from RIA_GRABACIONCONSULTA where grab_id in(''+@grabIds+'')
		)

		select mark.id_marca as markId, grab.grab_id as grabId,b.login as userName, mark.user_id as [userId],mark.marca as mark,convert(bit,case when b.TipoUser_id =1 then 0 else 1 end ) as IsAdmin
		from RIA_MARCAS mark 
		inner join grab on grab.cal_id=mark.call_id and grab.tipo_llamada=mark.tipo_llamada
		inner join ccUsers b on b.user_id = mark.user_id
		order by grab.grab_id,mark.tipo_marca 
		''
		--print @sql
		exec (@sql)
	end
	else if @action =3 begin
		select cast(case when par_valor =''1'' then 1 else 0 end as bit) as isEncrypt from TREC_PARAMETROS where par_id=15
	end
	else if @action =4 begin
		set @sql=''declare @nameFolder table (callType int,nameFolder varchar(100),prefijo varchar(2))
	insert into @nameFolder values(1,''''INBOUND'''',''''I_'''')
	insert into @nameFolder values(2,''''OUTBOUND'''',''''O_'''')
	declare @ext varchar(30)

	select @ext = case when par_valor=''''1'''' then ''''.wav.enc'''' else ''''.wav'''' end from TREC_PARAMETROS where par_id=15
		;
		with grab as (
		select grab_id,cal_id,tipo_llamada,id_repositorio,Prefijo as subFijo from RIA_GRABACION where grab_id in(''+@grabIds+'')
		union
		select grab_id,cal_id,tipo_llamada,id_repositorio,Prefijo as subFijo from RIA_GRABACIONCONSULTA where grab_id in(''+@grabIds+'')
		)
		
		select grab.grab_id as grabId,grab.id_repositorio as repositoryId,rep.dirvirtual_audio as virtualAudio
		,rep.ruta_repositorio+''''\''''+f.nameFolder+''''\''''+ cast(cal_id/10000 as varchar(100))+''''\'''' as pathRep,
		f.prefijo+cast(cal_id as varchar(100))	+ case when subFijo<>'''''''' then ''''_''''+subFijo else '''''''' end + @ext as [fileAudio]
		from grab 
		inner join TREC_REPOSITORIOS rep on grab.id_repositorio=rep.id_repositorio
		inner join @nameFolder f on f.callType=grab.tipo_llamada  
		order by repositoryId
		''
		--print @sql
		exec (@sql)
	end
	else if @action =5 begin
		select top 1 id_repositorio as repositoryId,rep.ruta_repositorio as pathRep, Cred.domain, Cred.[user], Cred.[password],Rep.dirvirtual_audio as virtualAudio
		from TREC_REPOSITORIOS Rep
		inner join TREC_REPO_NWCREDENTIALS  RepCred on Rep.id_repositorio =repCred.id_repository
		inner join RIA_NETWORKCREDENTIALS  Cred on RepCred.id_nwCredential=Cred.id
		where Cred.type = 1 and status=1
	end
	else if @action=6 begin
		declare @cal_id int,@tipo_llamada int

		select @cal_id= cal_id,@tipo_llamada=tipo_llamada from RIA_GRABACION where grab_id=@grabId

		if @cal_id is null and @tipo_llamada is null begin
			select @cal_id= cal_id,@tipo_llamada=tipo_llamada from RIA_GRABACIONCONSULTA where grab_id=@grabId
		end			   
		insert RIA_MARCAS (grab_id,user_id,marca,tipo_marca,tipo_llamada,call_id) values (@grabId,@userId,CONVERT(varchar, DATEADD(ss, @markTime , 0), 8),2,@tipo_llamada,@cal_id )
		select cast( @@IDENTITY  as int) as markId
	end
	else if @action=7 begin
		delete from RIA_MARCAS  where id_marca=@markId
	end
	else if @action=8 begin	
		select par_valor as hexKey from TREC_PARAMETROS where par_id=75
	end
  
END
'
	EXEC (@sql)

	
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
