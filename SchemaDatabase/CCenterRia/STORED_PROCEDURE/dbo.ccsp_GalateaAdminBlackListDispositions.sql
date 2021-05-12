CREATE procedure ccsp_GalateaAdminBlackListDispositions-- guiandose del sp ccsp_RIAcalifblacklist de xion
@Option tinyint,
@BlackListIds_ToProcess varchar(1500) = '',
@CampType tinyint = 1, -- 1 Campaña SALIDA, 0 Campaña ENTRADA
@Qualif_id int = null

as
set nocount on
declare @sql nvarchar(max)

if @Option = 1 -- Muestra listas negras asignadas a calificaciones de Campañas
 begin
	select b.idtipolista as BlackListId, a.calif_id as DispositionId
	from cccalifblacklist a with(index(IX_cccalifblacklist)) join ccTiposListaNegra b on a.idtipolista = b.idtipolista
	where a.tipo = @CampType 
	group by a.calif_id, b.idtipolista
	return(0)
 end

else if @Option = 2 -- Inserta BlackList por calificacion 
begin
	if LEN(@BlackListIds_ToProcess)>0 
		begin
			insert into cccalifblacklist(calif_id,idTipoLista,tipo)
			select  @Qualif_id calif_id,B.Value idTipolista, @CampType tipo from dbo.fn_RIASplitDelimited (@BlackListIds_ToProcess, ',') B
			left join  cccalifblacklist A on A.idTipoLista=B.value and A.tipo=@CampType and A.calif_id=@Qualif_id
			where A.idTipoLista is null
		end
	return(0)
end
else if @Option = 3 -- Elimina BlackList por calificacion Campañas
begin
	if LEN(@BlackListIds_ToProcess)>0 
		begin
			set @sql= 'delete from cccalifblacklist where tipo =' + cast(@CampType  as varchar(10)) + ' and idTipoLista in('+@BlackListIds_ToProcess+') and calif_id=' + cast(@Qualif_id  as varchar(10))
			exec(@sql)
		end
	return(0)
 end