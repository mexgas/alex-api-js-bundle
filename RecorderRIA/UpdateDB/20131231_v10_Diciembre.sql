/*

Fecha: 2013/12/31
Descripcion: 

* Se realiza fix en store procedure trsp_AdmRecSearchNodeACD.sql
* Se altera store de analizagritos
* Se actualiza parametro 54 de trec_parametros para extension .WAV


Version requerida: 9

*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 10
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)

	---------------- inicio SCRIPT @Sql ----------------


-- Se realiza fix en store procedure trsp_AdmRecSearchNodeACD

set @process='trsp_AdmRecSearchNodeACD - Alter Store Procedure'
set @SQl='

ALTER PROCEDURE  [dbo].[trsp_AdmRecSearchNodeACD]

@Workgroup int

AS
BEGIN

	SET NOCOUNT ON;

select a.idCampEsp, b.descripcion, d.frame from ccRIACampEspWG a
inner join ccInbound b on b.Inbound_id = a.idCampEsp
inner join ccRIAInboundGraph c on  c.Inbound_id = a.idCampEsp
inner join ccRIAGraphics d on d.graphic_id = c.graphic_id
where a.IDWG = @Workgroup and a.Tipo = 0

END
'
Exec(@Sql)


-- Se altera procedure trsp_GetFilesAnalisisGritos

set @process='trsp_GetFilesAnalisisGritos - Alter Store Procedure'
set @SQl='

ALTER PROCEDURE [dbo].[trsp_GetFilesAnalisisGritos] 
@idRepositorios as varchar(32),
@sExtension as varchar(10) = ''.wav''
AS

declare @Integrado as int
declare @FInicio as datetime
declare @sSql1 as nvarchar(180)
declare @sSql2 as nvarchar (180)
declare @sSql3 as nvarchar(180) 
declare @sSql as nvarchar (512)
declare @dLenAnt as tinyint
declare @dLenNew as tinyint


set @FInicio = dateadd(hh, 0, getdate())
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
Exec(@Sql)


-- Se actualiza parametro 54 de trec_parametros para extension .WAV


set @process='par_id 54 - Alter value in table trec_parametros'
set @SQl='

update trec_parametros set par_valor= ''.wav'' where par_id = 54

'
Exec(@Sql)


-- Se actualiza la version de la base de datos

set @process ='Update DB Version'
set @Sql='
 update trec_parametros set par_valor = ''10'' where par_id = 30 
'
Exec(@Sql)

	------------------ fin SCRIPT @Sql ------------------


	commit tran

	end try	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
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