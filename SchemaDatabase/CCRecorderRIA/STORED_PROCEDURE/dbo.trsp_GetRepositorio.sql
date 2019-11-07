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

SELECT @Cont=count(*)  FROM INFORMATION_SCHEMA.tables where table_name = 'trec_repositorios'
if @Cont > 0
begin
	select @Path=ruta_repositorio from trec_repositorios where id_repositorio = @id_rep
	if (@Path is not null)
	begin
		update trec_repositorios set InIniPort=@InIniPort, InFinPort=@InFinPort, OutIniPort=@OutIniPort, OutFinPort=@OutFinPort
			where id_repositorio = @id_rep
		select @Path as 'PathRepositorio'
		return
	end
end
select @Path=par_valor  from trec_parametros where par_id = 1
select @Path as 'PathRepositorio'
END