/*
	Check if we have to keep the video file, according with IdCamp and IdCalif. KeepVideoFile ?
	return	
			respuesta:  0 - No keep file, we have to delete it
						1 - We have to keep video file
			repository directory
			
*/

CREATE PROCEDURE [dbo].[trsp_VerificaGrabacion] 
@IDGrab varchar(10),
@IDCamp int,
@IDCalif int,
@Time int,
@Tipo int,
@Puerto int
 AS

declare @Respuesta as varchar(15)
declare @Repositorio as varchar(512)

declare @tiempo as int

select @Respuesta = CASE WHEN @Time < vg.tiempo THEN '0'
							else '1' end
							, @tiempo = vg.tiempo
from TREC_VERIFICA_GRAB vg, TREC_VERIFICA_CALIF vf
where vg.id = vf.id and vg.tipo = @Tipo 
and vg.id_camp_esp = @IDCamp and vf.calif_id = @IDCalif

IF (@Respuesta IS NULL)
	set @Respuesta = '0'

if (@Respuesta = '0')
begin
	Select @Repositorio = ruta_rep_video from TREC_REPOSITORIOS
		WHERE id_repositorio = 1
	if (@Repositorio is null) 
	begin
		select @Repositorio = par_valor from trec_parametros where par_id = 14
		if (@Repositorio is null)
			set @Repositorio = ''
	end 
end
else 
	set @Repositorio = ''

select @IDGrab as cal_id, @Respuesta as respuesta, @Repositorio as repositorio


/*
declare @Respuesta as varchar(15)
declare @Repositorio as varchar(512)

select @Respuesta = CASE WHEN vg.tiempo = 0 THEN 'YES'
								WHEN vg.tiempo > @Time THEN 'NO'
								WHEN vg.tiempo <= @Time THEN 'YES'
								ELSE 'NO' END
from TREC_VERIFICA_GRAB vg, TREC_VERIFICA_CALIF vf
where vg.id = vf.id and vg.tipo = @Tipo 
and vg.id_camp_esp = @IDCamp and vf.calif_id = @IDCalif

--print(@Respuesta)

IF @Respuesta IS NULL
BEGIN
	select @Respuesta = CASE WHEN count(*) = 0 then 'YES' 
						else 'NO' END
	from TREC_VERIFICA_GRAB where id_camp_esp = @IDCamp
END

IF @Respuesta = 'NO'
BEGIN
	IF @Tipo = 1
	BEGIN
		Select @Repositorio = ruta_repositorio from TREC_REPOSITORIOS
		WHERE @Puerto between InIniPort and InFinPort
	END
	ELSE
	BEGIN
		Select @Repositorio = ruta_repositorio from TREC_REPOSITORIOS
		WHERE @Puerto between OutIniPort and OutFinPort
	END
END
ELSE
BEGIN
	Set @Repositorio = ''
END
select @IDGrab as cal_id, @Respuesta as respuesta, isnull(@Repositorio,'SIN REPOSITORIO') as repositorio
*/