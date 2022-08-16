/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/08/19
Description: Archivo Agosto 2022

Description

Database: CCenterRia
Required version: 124.11

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 2
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF (@actualVersion =@version and @actualVersionFix in(actualVersionFix,actualVersionFix-1)
BEGIN
	BEGIN TRAN

	BEGIN TRY	
	
	set @process = 'CW-7231 Alter SP ccsp_GalateaDnis change  @Tipo = 2'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaDnis]
@User varchar(10),
@Tipo tinyint,
@Dnis varchar(40) = null,
@Inbound_id smallint = null,
@dni_id as smallint = null,
@dnis_ids as varchar(MAX) = null,
@dni_description as varchar(40) = null,
@dni_isBlock as bit = null
as
set nocount on


if @Tipo = 1 -- carga dnis
 begin
	select dni_id, dni_numero as dni_number, dni_descripcion as dni_description, case when dni_id in(select dni_id from ccInboundDnis) then 1 else 0 end dni_isRelated
	from ccDnis where dni_Status=1 order by 2
	return(0)
 end

if @Tipo = 2 -- carga relaciones de dnis
 begin
	declare @UserId int=cast(@user as smallint)
	declare @isSuperUser bit=0

	if @UserId > 0 and exists (
		select * from ccUsers_Roles A
		inner join ccRoles R on A.Rol_id=R.Rol_id and R.Level=7
			where User_id = @UserId
		) begin
			set @isSuperUser =1
		end

	;with relationDnis as(
		select a1.Inbound_id, cast(0 as smallint) dni_id, a1.descripcion as description,'''' as dni_number,'''' as dni_description, cast(0 as tinyint) dni_isBlock
		from ccInbound a1
		inner join ccRIAInboundGraph a2 on (a1.Inbound_id = a2.Inbound_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		where a3.type_id = 1 and IDArea is not null 
		and a1.Inbound_id not in (select Inbound_id from ccInboundDnis)
		union
		select ci.inbound_id, cid.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
		from ccInboundDnis cid 
		inner join ccInbound ci on ci.inbound_id = cid.inbound_id 
		join ccDnis cd on cd.dni_id = cid.dni_id 
		where cd.dni_Status=1
	)

	select * from relationDnis a1
	where @isSuperUser=1 or a1.Inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@UserId, 2))
	order by 3,4

	return(0)
 end

if @Tipo = 3 -- Agrega Dnis
 begin
	if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis)
	 begin
		insert into ccDnis (dni_id, dni_numero, dni_tpoMaxEspera, tipodni_id, dni_Descripcion, dni_tipo)
		select isNull(max(dni_id), 0) + 1, @Dnis , 0, 1, @dni_description, 2 from ccDnis
		select top(1) dni_id from ccDNIS order by dni_id desc
		return(0)
	 end
	 
	select cast(-1 as smallint)
 end

if @Tipo = 4 -- Elimina Dnis
 begin
	delete from ccInboundDnis where inbound_id = @Inbound_Id and dni_id = @dni_id
	
	select ci.inbound_id, cd.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
	from ccInbound ci , ccDNIS cd
	where ci.Inbound_id=@Inbound_id and dni_id=@dni_id
 end

if @Tipo = 5 -- Agrega Relacion
 begin
	insert into ccInboundDnis (Inbound_id, dni_id)
	select @Inbound_Id,B.Value from  dbo.fn_RIASplitDelimited (@dnis_Ids, '','') B
	left join ccInboundDnis A on A.dni_id=B.Value 
	where  A.dni_id is null

	select cast(@Inbound_Id as smallint) inbound_id,cast(B.Value as smallint) dni_id, 
	ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock		
	,case when cid.Inbound_id is null then 0 else 1 end isAssigned
	from  dbo.fn_RIASplitDelimited (@dnis_Ids, '','') B
	left join ccInboundDnis cid on cid.dni_id=B.Value and cid.Inbound_id=@Inbound_Id
	left join ccInbound ci on ci.inbound_id = @Inbound_Id
	inner join ccDnis cd on cd.dni_id = B.Value
	order by 3,4
 end

if @Tipo = 6 -- Elimina Dnis sin pedir inbound_id
 begin
	if exists(select dni_id from ccInboundDnis where dni_id in (select value from dbo.fn_RIASplitDelimited (@dnis_Ids, '','')) and isnull(inbound_id, 0) <> 0)
		select -1

	else begin
		update ccDNIS set dni_Status=0 where dni_id in (select value from dbo.fn_RIASplitDelimited (@dnis_Ids, '',''))--= @dni_id -- delete from ccdnis where dni_id = @dni_id
		select 1
	end
 end

if @tipo = 7
 begin
	if @Dnis = (select dni_numero from ccDNIS where dni_id=@dni_id) begin
		update ccDnis set 
		dni_Descripcion=isnull(@dni_description,dni_Descripcion)
		where dni_id = @dni_id 
		
		select 1
		return(0)
	end

	if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis) begin
		update ccDnis set 
		dni_numero=case when @Dnis <> ''0'' then @Dnis else dni_numero end,
		dni_Descripcion=isnull(@dni_description,dni_Descripcion),
		dni_isBlock = isnull(@dni_isBlock,dni_isBlock)
		where dni_id = @dni_id 

		select 1
		--select dni_id,dni_numero as dni_number, dni_Descripcion as dni_Descriptiondni_id, dni_isBlock from ccDNIS where dni_id=@
		return(0)
	end
	
	select -1
 end

set nocount off'
    EXEC(@sql)

    set @process = ''
    set @sql = ''
    EXEC(@sql)

	 		/* End script release */
		/* Upgrade database version (use your own script to do it) */
	--	exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
