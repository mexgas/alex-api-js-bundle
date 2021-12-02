/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 26
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	 set @process = 'Correcion para finder en xion'
     set @sql = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@ids varchar(max)=null,
@name varchar(25) = NULL,
@top int = 0,
@dateIni datetime =null,
@dateEnd datetime =null,
@dateStart dateTime= null,
@userId int = 0,
@node varchar(10) = null
AS

declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
set @sql = ''''

select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=@option 

if @action in (1,6) begin --obtiene los nodos a insertar en BX
    if @action = 1 set @status =0
    else if @action = 6 set @status = 2

    if @option <>2 begin

    declare @auxTag nvarchar(10)
    
    select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02''
    else ''@CDATE''   end
    set @parameterDefinition =N''@status int, @top int,@option int''
    set @sql=''declare @basexName varchar(max)
select @basexName=Xname from ccBaseXDB where serviceId=@option and isFull=0;
    with node ( ''+@columnId+ '',xmlString,dateNode)
    AS(
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableName + '' A with(rowlock)
        where A.status =@status
        union
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableNameHistory + '' A with(rowlock)
        where A.status =@status  
    )

    select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
    left join ccBaseXDB baseX on baseX.serviceId= @option and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
    order by baseX.Xname''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top,@option=@option
    end
end
else if @action in (2,7) begin--actualiza los nodos insertados en BX
    if @action = 2 set @status =0
    else if @action = 7 set @status = 2

    set @parameterDefinition =N''@status int''

    set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    select @tableName,@columnId,@ids,@sql
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
    set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status

end
else if @action = 3 --trae el nombre de la base de datos en BX
begin
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
    insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
end
else if @action = 5 begin --obtener servicios disponibles    
    select id, ref  from ccFinderServices where isActive=1
end
else if @action = 8 begin--trae la lista de las bases para la busqueda
    select Xname from ccBaseXDB where serviceId = @option
    and (

    @dateIni between dateStart and dateEnd
    or @dateEnd between dateStart and dateEnd
    or dateStart between @dateIni and @dateEnd
    )
    union
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
    and (
        dateStart between @dateIni and @dateEnd
        or @dateIni>=dateStart

    )
end
else if @action = 9 begin--Cierra la base datos
       update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()), dateStart=isnull(@dateStart,dateStart) where serviceId= @option and  isfull = 0 and dateEnd is null
       and Xname=@name
end

else if @action = 10 begin
   declare @filterWg varchar(max)
    declare @len int
    set @filterWg=''''
    if @node is null or @node = ''R02''
    begin
        select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId
 
    end
    else
    begin
    declare @serviceId varchar(10)
    set @serviceId = (select convert(varchar(10), id) from ccFinderServices where ref = @node)
    select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+@serviceId+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId and WGCam.Tipo=0
    end


    set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
    select SUBSTRING(@filterWg,0, @len)
    end


else if @action = 11 begin--trae el nombre de la base de datos en BX

    set @sql=''
    declare @dateStart datetime
    set @dateStart= convert(datetime,convert(varchar(10),getdate(),121))
    SELECT isnull(min(dateIn),@dateStart) as node FROM ''+@tableName+'' where status = 0  ''
    EXECUTE sp_executesql  @sql

end'
    EXEC(@sql)

    set @process = 'Resetea las llamadas en cola como abandonadas'
     set @sql = 'ALTER PROCEDURE [dbo].[ccsp_CCServerDOWN]
@Flag as varchar(1)
AS
-- 0 = Fuera de Servicio
-- 1= En Servicio
Update ccSettings Set valor=@Flag Where setting_id=4

update ccCallsIn set statusCall_id =6 where statusCall_id = 5 
and cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))'
    EXEC(@sql)

    set @process = ''
     set @sql = ''
    EXEC(@sql)

    set @process = ''
     set @sql = ''
    EXEC(@sql)
	
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
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


