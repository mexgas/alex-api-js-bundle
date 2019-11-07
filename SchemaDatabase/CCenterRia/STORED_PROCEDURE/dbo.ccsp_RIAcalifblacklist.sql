CREATE procedure [dbo].[ccsp_RIAcalifblacklist]
@Qualif_id int = null,
@BlackListIds_Insert varchar(1500) = '',
@BlackListIds_Delete varchar(1500) = '',
@Type tinyint = 0,
@tipoCampACD tinyint = 1 --1 Campaña, 2 ACD
as
set nocount on
declare @sql nvarchar(max)
if @Type = 0 -- Catalogo de Calificaciones
 begin
	if @tipoCampACD=1 --Campañas
		select calif_id, Description from cctipocalifout where CalifOut_Status = 1
	else --ACDs
		select calif_id, Description from cctipocalif where Calif_Status = 1
	return(0)
 end

else if @Type = 1 -- Muestra listas negras asignadas por calificacion Campañas
 begin
	select b.idtipolista, b.Tipolista
	from cccalifblacklist a with(index(IX_cccalifblacklist)) join ccTiposListaNegra b on a.idtipolista = b.idtipolista
	where a.tipo = @tipoCampACD and a.calif_id = @Qualif_id
	group by b.idtipolista, b.Tipolista
	return(0)
 end

else if @Type = 2 -- Inserta BlackList por calificacion / Elimina BlackList por calificacion Campañas
 begin
	if LEN(@BlackListIds_Insert)>0 begin
		insert into cccalifblacklist(calif_id,idTipoLista,tipo)
		select  @Qualif_id calif_id,B.Value idTipolista, @tipoCampACD tipo from dbo.fn_RIASplitDelimited (@BlackListIds_Insert, ',') B
		left join  cccalifblacklist A on A.idTipoLista=B.value and A.tipo=@tipoCampACD and A.calif_id=@Qualif_id
		where A.idTipoLista is null
	end
	else if LEN(@BlackListIds_Delete)>0 begin
		set @sql= 'delete from cccalifblacklist where tipo =' + cast(@tipoCampACD  as varchar(10)) + ' and idTipoLista in('+@BlackListIds_Delete+')'
		--print(@sql)
		exec(@sql)
	end
	return(0)
 end
set nocount off