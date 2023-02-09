/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.33

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
SET @versionfix = 36
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

		SET @process = 'K049000 Update module ports'
		SET @sql = 'if exists (select * from ccRIALog_Module where module_id=24)
		begin
		  update ccRIALog_Module set descripcion=''Puertos de marcación|Dialing ports'' where module_id=24
		end';
		EXEC(@sql);

		SET @process = 'K049002 Update operation add ports'
		SET @sql = 'if exists (select * from ccRIALog_Operation where operationType=37)
		begin
		  update ccRIALog_Operation set descripcion=''Configurar puerto|Configure port'' where operationType=37
		end';
		EXEC(@sql);

		SET @process = 'K049004 Update operation delete ports'
		SET @sql = 'if exists (select * from ccRIALog_Operation where operationType=37)
		begin
		  update ccRIALog_Operation set descripcion=''Eliminar puerto|Delete port'' where operationType=38
		end';
		EXEC(@sql);

		SET @process = 'K049003 add operation update port'
		SET @sql = 'if not exists (select * from ccRIALog_Operation where operationType=199)
		begin
		  insert into ccRIALog_Operation (operationType, descripcion) values(199,''Editar puerto|Edit port'')
		end';
		EXEC(@sql);

		SET @process = 'Add operation assign port'
		SET @sql = 'if not exists (select * from ccRIALog_Operation where operationType=200)
		begin
		  insert into ccRIALog_Operation (operationType, descripcion) values(200,''Asignar puerto|Assign port'')
		end';
		EXEC(@sql);

		SET @process = 'add operation unassign port'
		SET @sql = 'if not exists (select * from ccRIALog_Operation where operationType=201)
		begin
		  insert into ccRIALog_Operation (operationType, descripcion) values(201,''Desasignar puerto|Unassign port'')
		end';
		EXEC(@sql);

		SET @process = 'K049003 Add identifier name port'
		SET @sql = 'if not exists (select * from valueRecord where valueT like ''%NAME PORT%'')
		begin
		  insert into valueRecord(valueT,es,en,pt) values(''NAME PORT'',''Nombre'',''Name'',''Nome'')
		end';
		EXEC(@sql);

		SET @process = 'K049003 Add identifier number port'
		SET @sql = 'if not exists (select * from valueRecord where valueT like ''%NUMBER PORT%'')
		begin
		  insert into valueRecord(valueT,es,en,pt) values(''NUMBER PORT'',''Número'',''Number'',''Número'')
		end';
		EXEC(@sql);

		SET @process = 'K049003 Add identifier provider'
		SET @sql = 'if not exists (select * from valueRecord where valueT like ''%PROVIDER%'')
		begin
		  insert into valueRecord(valueT,es,en,pt) values(''PROVIDER'',''Proveedor de telefonía'',''Phone carrier'',''Operadora de telefone'')
		end';
		EXEC(@sql);

		SET @process = 'K049003 Add identifier xfer type'
		SET @sql = 'if not exists (select * from valueRecord where valueT like ''%XFER TYPE%'')
		begin
		  insert into valueRecord(valueT,es,en,pt) values(''XFER TYPE'',''Tipo de transferencia'',''Transfer type'',''Tipo de transferência'')
		end';
		EXEC(@sql);

		SET @process = 'K049000 delete relation module-operation'
		SET @sql = 'if exists (select * from ccRIALog_Cat_Relation  where module_id=24)
		begin
		  delete ccRIALog_Cat_Relation where module_id=24 
		end';
		EXEC(@sql);

		SET @process = 'K049000 insert relation module-operation'
		SET @sql = '
		insert into ccRIALog_Cat_Relation (module_id,operationType) values(24,37)
		insert into ccRIALog_Cat_Relation (module_id,operationType) values(24,38)
		insert into ccRIALog_Cat_Relation (module_id,operationType) values(24,199)
		insert into ccRIALog_Cat_Relation (module_id,operationType) values(24,200)
		insert into ccRIALog_Cat_Relation (module_id,operationType) values(24,201)';
		EXEC(@sql);


		SET @process = 'K049000 delete procedure ccsp_GalateaChangeHistory'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaChangeHistory'')
			BEGIN
				DROP PROCEDURE ccsp_GalateaChangeHistory;
			END';
		EXEC(@sql);

		SET @process = 'K049000 create procedure ccsp_GalateaChangeHistory'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaChangeHistory]
	@option TINYINT,
	@loginLst VARCHAR(max) = NULL,
	@moduleWithOperation varchar(max) = NULL,
	@operationDateIni SMALLDATETIME = NULL,
	@operationDateFin SMALLDATETIME = NULL,
	@top INT = 0
	AS
	SET NOCOUNT ON

	DECLARE @lang TINYINT

	SELECT @lang = valor
	FROM ccsettings
	WHERE setting_id = 27

	IF @option = 1 -- Catalogo de modulos
	BEGIN
		WITH Catalog AS(
		SELECT cast(m.module_id as int) module_id, cast(o.operationType as int) operationType, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion) + 1, len(m.descripcion)) END AS mDescripcion, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion) + 1, len(o.descripcion)) END AS oDescripcion
		FROM ccRIALog_Operation o WITH (INDEX (IX_ccRIALog_Operation))
		JOIN ccRIALog_Cat_Relation r ON o.operationType = r.operationType
		JOIN ccRIALog_Module m WITH (INDEX (IX_ccRIALog_Module)) ON r.module_id = m.module_id

		UNION

		SELECT 0, - 1, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, '' - ''

		UNION

		SELECT 0, 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END

		UNION

		SELECT cast(module_id as int) module_id, 0, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
		FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))

		UNION

		SELECT cast(module_id as int) module_id, - 1 , CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, '' - ''
		FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module)))

		SELECT module_id,operationType,mDescripcion,oDescripcion FROM Catalog
		WHERE module_id not in(5,8,14,21,22,25,32,33,36,37,44,53,57,58,59,60,42)
		AND operationType not in(6,15,51,58,36,46,44,45,59,12,8,7,55,54,33)
		ORDER BY mDescripcion, oDescripcion

		RETURN (0)
	END

	IF @option = 2 -- Muestra informacion por filtros
	BEGIN

		declare @sql as nvarchar(max)
		DECLARE @table TABLE(id int,value varchar(max))
		declare @id int
		declare @moduleId varchar(max)
		declare @operationLst varchar(max)
		declare @query varchar(max) = '' and (''
		declare @value varchar(max)
		declare @first int = 1
		declare @pos int

		insert into @table select * from dbo.fn_RIASplitDelimited(cast(isnull(@moduleWithOperation,'''') as varchar(max)), '','')
		while exists(select * from @table)
		begin
			select top 1 @id = id, @value = value from @table
			set @pos = charindex('':'', @value)
			if(@pos <> 0)
			begin
				set @moduleId = substring(@value, 1, @pos-1)
				set @operationLst = replace(substring(@value, @pos+1, len(@value)), ''-'', '','')
				if(@first = 1)
				begin
					set @query = @query + ''l.module_id='' + @moduleId + '' and l.operationType in ('' + @operationLst + '')''
					set @first = 0
				end
				else
				begin
					set @query = @query + '' or l.module_id='' + @moduleId + '' and l.operationType in ('' + @operationLst + '')''
				end
			end

			delete @table where id = @id
		end
		set @query = @query + '')''


		SET ROWCOUNT @top

		set @sql =
		''DECLARE @tableLogin TABLE(id int,value varchar(255))
		insert into @tableLogin  select * from dbo.fn_RIASplitDelimited('''''' + cast(isnull(@loginLst,'''') as varchar(max)) + '''''','''','''')

		SELECT L.log_id, L.areaName, L.operationDate,
		CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''''|'''', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''''|'''', o.descripcion) + 1, len(o.descripcion)) END operationType,
		L.LOGIN,
		CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''''|'''', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''''|'''', m.descripcion) + 1, len(m.descripcion)) END module_id,
		CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target,
		CASE WHEN v.valueT IS NULL THEN L.value ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN (SELECT REPLACE(L.value,v.valueT,v.es)) WHEN 2 THEN (SELECT REPLACE(L.value,v.valueT,v.pt)) ELSE (SELECT REPLACE(L.value,v.valueT,v.en)) END END AS value
		FROM CCRIALOG L
		JOIN ccRIALog_Module M WITH (INDEX (IX_ccRIALog_Module)) ON L.module_id = M.module_id
		JOIN ccRIALog_Operation O WITH (INDEX (IX_ccRIALog_Operation)) ON L.operationType = O.operationType
		LEFT JOIN targetRecord t ON t.targetT = L.target
		LEFT JOIN valueRecord v ON v.valueT = L.value or v.valueT=SUBSTRING(L.value,0, CHARINDEX('''':'''', L.value))
		LEFT JOIN ccUsers CU ON CU.Login = L.login 
		WHERE 1=1 
		AND
		CU.TipoUser_id = 2''
		+
		case isnull(@loginLst, '''') when '''' then '''' else
		'' AND L.LOGIN in (select value from @tableLogin) ''
		END
		+
		case isnull(@moduleWithOperation, '''') when '''' then '''' else
		@query
		end
		+ case ISNULL(@operationDateIni, '''') when '''' then '''' else
		''AND L.operationDate >= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull('''''' + convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, -1, '''''' + convert(varchar(19), @operationDateIni, 121) + '''''') ELSE L.operationDate END ''
		+ '' AND L.operationDate <= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull(''''''+ convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, 1, '''''' + convert(varchar(19), @operationDateFin, 121) + '''''') ELSE L.operationDate END''
		end
		+
		'' ORDER BY L.operationDate DESC''
		execute sp_executesql @sql
		--print @sql
	END


	SET NOCOUNT OFF';
		EXEC(@sql);

		SET @process = 'K049000 delete procedure ccsp_GalateaDialer'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaDialer'')
			BEGIN
				DROP PROCEDURE ccsp_GalateaDialer;
			END';
		EXEC(@sql);

		SET @process = 'K049000 create procedure ccsp_GalateaDialer'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaDialer]
@Description varchar(40)='''',
@DialerId int = 0,
@PortNumber int = 0,
@Status varchar(1)='''',
@action smallint=0,
@Provider smallint=0,
@XferType smallint=0,
@PortEnd int = 0,
@CampId smallint = 0,
@dialer_ids varchar(2000)=''''

AS
set nocount on

if @action=1
 begin
	select provedor_id as ProviderId, descrip as ProviderName  from cstoProvedor
 end

if @action=2 --Insert
 begin
	create table #tempPortTable( portId int primary key)

	if @PortEnd>0 begin
		begin transaction
			while @PortNumber<=@portEnd begin
			insert into #tempPortTable values(@PortNumber)
			set @PortNumber=@PortNumber+1
			end
		commit transaction
	 end
	 else begin
		insert into #tempPortTable values(@PortNumber)
	  end
	
	if exists(select Puerto from ccoDialers where Puerto in (select portId from #tempPortTable)) ---Puerto=@Port and dialer_id <> @Dialer_id
	 begin
		drop table #tempPortTable
		select -1 as ResponseCode
		return(0)
	 end

	Insert ccoDialers (Descripcion, Puerto, Status, provedor_id, xfertype) 
	Select @Description+''_''+CAST(portId as varchar(5)), portId, @Status, @Provider, @XferType from #tempPortTable t
	

	select 200 as ResponseCode, dialer_id as DialerId, Descripcion as PortDescription, 
	p.descrip as ProviderDescription, Puerto, XferType
	from ccoDialers d
	inner join cstoProvedor p on p.provedor_id=d.provedor_id
	where Puerto in (select portId from #tempPortTable)

	drop table #tempPortTable
 end

if @action=3 --Update
 begin

	if exists(select Puerto from ccoDialers where Puerto=@PortNumber and dialer_id <> @DialerId)
	 begin
		select -1 as ResponseCode ---Port already exists
		return(0)
	 end

	Update ccoDialers set Descripcion=case @Description when '''' then Descripcion else @Description+''_''+cast(@PortNumber as varchar(5)) end,
	Puerto=case @PortNumber when '''' then Puerto else @PortNumber end, Status=case @Status when '''' then Status else @status end,
	provedor_id=case @Provider when '''' then provedor_id else @Provider end,
	xfertype = case @XferType when 0 then xfertype else @XferType end
	where Dialer_id=cast(@DialerId as int)
	
	select 200 as ResponseCode, dialer_id as DialerId, Descripcion as PortDescription, 
	p.descrip as ProviderDescription, Puerto, XferType
	from ccoDialers d
	inner join cstoProvedor p on p.provedor_id=d.provedor_id
	where dialer_id=@DialerId
 end

if @action=4 --Delete
 begin

	if exists(select Dialer_id from ccoDialerCamp where
		Dialer_id in (select Value from dbo.fn_RIASplitDelimited (@dialer_ids, '','')))
	 begin
		select -2 as ResponseCode --Existe alguna campaña que esta utilizando este dialer
		return(0)
	 end
	 
	declare @portsDelete table(DialerId int, Port int,PortDescription varchar(15), inUse tinyint)

	insert @portsDelete (DialerId,Port,PortDescription,inUse)
	select Value, Puerto,Descripcion,0 from dbo.fn_RIASplitDelimited (@dialer_ids, '','') 
	inner join ccoDialers on dialer_id=Value

	update pd set inUse=1
	from @portsDelete pd
	inner join ccoCallsOut co on co.cal_puerto=pd.Port
	where statusCall_id=13 and cal_Inicio is not null and cal_tDialog=0
	and DialerId in (select Value from dbo.fn_RIASplitDelimited (@dialer_ids, '',''))

	update pd set inUse=1
	from @portsDelete pd
	inner join ccCallsIn co on co.cal_puerto=pd.Port
	where statusCall_id=13 and cal_Inicio is not null and cal_tDialog=0
	and DialerId in (select Value from dbo.fn_RIASplitDelimited (@dialer_ids, '',''))

	delete from ccoDialers Where Dialer_id in (select DialerId from @portsDelete where inUse=0)
	--(select Value from dbo.fn_RIASplitDelimited (@dialer_ids, '',''))
	
	select 200 as ResponseCode, DialerId, PortDescription
	from @portsDelete
 end

if @action=5 --Ports Info
begin
	select dc.cam_id as CampId, c.cam_descripcion as CampName, graphic_id as Frame, c.IDArea, a.AreaName
	from ccoDialerCamp dc
	inner join ccCamps c on c.cam_id=dc.cam_id
	inner join ccRIACat_Areas a on a.IDArea=c.IDArea
	inner join ccRIACampsGraph cg on c.cam_id=cg.cam_id
	where dc.dialer_id=@DialerId

	return(0)
end

set nocount off';
		EXEC(@sql);


		SET @process = 'K049000 delete procedure ccsp_GalateaAdminPortsManagement'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAdminPortsManagement'')
			BEGIN
				DROP PROCEDURE ccsp_GalateaAdminPortsManagement;
			END';
		EXEC(@sql);


		SET @process = 'K049000 delete procedure ccsp_GalateaAdminPortsManagement'
		SET @sql = ' ALTER PROCEDURE [dbo].[ccsp_GalateaAdminPortsManagement]
@action SMALLINT,
@dialer_id INT = 0,
@cam_id SMALLINT = 0,
@list_dialier_id varchar(max) =''''
AS
SET NOCOUNT ON;
DECLARE @transtate BIT
IF @@TRANCOUNT = 0
BEGIN
	SET @transtate = 1
BEGIN TRANSACTION transtate
END
BEGIN TRY
	IF @action = 1 --return all ports
	BEGIN
		SELECT Dialers.dialer_id AS DialerId, Dialers.Descripcion AS PortDescription, Provedor.Descrip AS ProviderDescription, Dialers.Puerto, XferType
		FROM [CCenterRIA].[dbo].[ccoDialers] AS Dialers INNER JOIN [CCenterRIA].[dbo].[cstoProvedor] AS Provedor 
		ON Dialers.provedor_id = Provedor.provedor_id
	END;
	IF @action = 2 --return ports for camp
	BEGIN
		SELECT dialer_id AS DialerId, cam_id AS CampId FROM [CCenterRIA].[dbo].[ccoDialerCamp] ORDER BY cam_id
	END;
	IF @action = 3 --insert port
	BEGIN
		IF @list_dialier_id = ''''
		BEGIN
			IF NOT EXISTS (SELECT dialer_id, cam_id FROM [CCenterRIA].[dbo].[ccoDialerCamp]
				WHERE dialer_id=@dialer_id AND cam_id=@cam_id)
			BEGIN
				INSERT INTO [CCenterRIA].[dbo].[ccoDialerCamp](dialer_id, cam_id) VALUES (@dialer_id, @cam_id)
			END;
		END
		ELSE
		BEGIN
		   INSERT INTO [CCenterRIA].[dbo].[ccoDialerCamp](dialer_id, cam_id)
			Select dialer_id,@cam_id from ccoDialers where dialer_id not in (SELECT dialer_id FROM [CCenterRIA].[dbo].[ccoDialerCamp]
				WHERE dialer_id in (select Value FROM fn_RIASplitDelimited(@list_dialier_id, '','') where [value] > 0) AND cam_id=@cam_id) and
				 dialer_id in (select Value FROM fn_RIASplitDelimited(@list_dialier_id, '',''))
		END;
	END;
	IF @action = 4 --delete port
	BEGIN
		IF @list_dialier_id = ''''
			DELETE FROM [CCenterRIA].[dbo].[ccoDialerCamp] WITH(ROWLOCK) WHERE cam_id = @cam_id AND dialer_id = @dialer_id
		ELSE
		BEGIN
			DELETE FROM [CCenterRIA].[dbo].[ccoDialerCamp] WITH(ROWLOCK) WHERE cam_id = @cam_id AND dialer_id in (select Value FROM fn_RIASplitDelimited(@list_dialier_id, '','') where [value] > 0)
		END;
	END;

	IF @action = 5 --return ports for single camp
	BEGIN
		SELECT dialer_id AS DialerId, cam_id AS CampId FROM [CCenterRIA].[dbo].[ccoDialerCamp] WHERE cam_id = @cam_id ORDER BY cam_id
	END;

	IF @transtate = 1 AND XACT_STATE() = 1
	BEGIN
		COMMIT TRANSACTION transtate
	END;
END TRY
BEGIN CATCH
DECLARE @error INT, @message VARCHAR(4000), @xstate INT;
SELECT @error = ERROR_NUMBER(), @message = ERROR_MESSAGE(), @xstate = XACT_STATE();
IF @xstate = -1
	ROLLBACK;
IF @xstate = 1
	ROLLBACK
IF @xstate = 1
	ROLLBACK TRANSACTION ccsp_GalateaAdminPortsManagement;
RAISERROR (''ccsp_GalateaAdminPortsManagement: %d: %s'', 16, 1, @error, @message) ;
END CATCH;';
		EXEC(@sql);
		-------------------------------------- End CW-7781 Fix Update Campaigns Ivan --------------------------------------------------------------------------------

		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
		EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
