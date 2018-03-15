/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Alan Minor
Date: 2018/02/16
Description:
**********************************************************************************************
CW-1043 - faltan relaciones en las tablas de survey
**********************************************************************************************
Database: ccReportsRia
Required version: 46


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =49
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try

	set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
	begin
	DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
	end'
	EXEC(@sql)


	set @process = 'Crear tabla RepOutAnswAndXferCalls -- CW-1331'
    set @Sql= 'if not exists (select * from sys.tables where name = N''RepOutAnswAndXferCalls'')
    begin
        CREATE TABLE RepOutAnswAndXferCalls (
			[date] [datetime] NOT NULL,
			[callid] [int] NOT NULL,
			[campaignId] [int] NOT NULL,
			[campaign] [varchar](255) NOT NULL,
			[userId] [int] NOT NULL,
			[Agent] [varchar](255) NOT NULL, 
			[dialog] [int] NOT NULL,
			[telephone] [varchar](255) NOT NULL,
			[dialId] int NOT NULL,
			[dialType] [varchar](255) NOT NULL,
			[CallTypes] [varchar](255) NOT NULL,
			[ncost] decimal NOT NULL,
			[iva] int NOT NULL,
			[total] decimal NOT NULL
		) ON [PRIMARY]
    end'
	EXEC(@Sql)

	set @process = 'Crear tabla dialType -- CW-1331'
    set @Sql= 'if not exists (select * from sys.tables where name = N''RepOutAnswAndXferCalls'')
    begin
        CREATE TABLE dialType (
			[dialId] [int] NOT NULL PRIMARY KEY,
			[description] [varchar] (100) NOT NULL
		)
    end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla dialType -- CW-1331'
    set @Sql= 'if not exists (select * from dialType where dialId = 0)
	begin
		insert into dialtype values(0, ''systemTranslated_Auto'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla dialType -- CW-1331'
    set @Sql= 'if not exists (select * from dialType where dialId = 2)
	begin
		insert into dialtype values(2, ''systemTranslated_Manual'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla dialType -- CW-1331'
    set @Sql= 'if not exists (select * from dialType where dialId = 3)
	begin
		insert into dialtype values(3, ''systemTranslated_Xfer'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ccMenus -- CW-1331'
    set @Sql= 'if not exists (select * from ccmenus where menu_id=4250)
	begin
		insert into ccMenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,release) values(4250,''Llamadas Contestadas y Transferidas|Answered and Transfer Calls'', 4000, ''B'', 4, 3,''d858e34ff9e6e3eac25177b292cc1ecd4db3504470848abb0c98ce0e953332e3194a869b013e81f376c6f4ee2d3eed7e7230ec9d5d275d790015a477571b5987780bf1f6f57527fb1a643962bb991c05'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla Filters -- CW-1331'
    set @Sql= 'if not exists (select * from Filters where id=29)
	begin
		insert into Filters values(29, ''dialType'', 29, ''DialTypes'', ''DialType'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ReportsFiltersMenus -- CW-1331'
    set @Sql= 'if not exists (select * from ReportsFiltersMenus where idReport = 4250 and filterMenuName=''date'')
	begin
		insert ReportsFiltersMenus (idReport, filterMenuName) values (4250, N''date'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ReportsFiltersMenus -- CW-1331'
    set @Sql= 'if not exists (select * from ReportsFiltersMenus where idReport = 4250 and filterMenuName=''filterby'')
	begin
		insert ReportsFiltersMenus (idReport, filterMenuName) values (4250, N''filterby'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ReportsFilters -- CW-1331'
    set @Sql= 'if not exists (select * from ReportsFilters where id = 4250 and filterName = ''campaigns'')
	begin
		insert ReportsFilters values (''Answered and Transfer calls'', ''campaigns'', 4250)
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ReportsFilters -- CW-1331'
    set @Sql= 'if not exists (select * from ReportsFilters where id = 4250 and filterName = ''users'')
	begin
		insert ReportsFilters values (''Answered and Transfer calls'', ''users'', 4250)
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ReportsFilters -- CW-1331'
    set @Sql= 'if not exists (select * from ReportsFilters where id = 4250 and filterName = ''dialType'')
	begin
		insert ReportsFilters values (''Answered and Transfer calls'', ''dialType'', 4250)
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla TranslatedReports -- CW-1331'
    set @Sql= 'if not exists (select * from TranslatedReports where id=4250)
	begin
		insert into TranslatedReports values(4250, ''campaign|dialType|CallTypes|Agent|telephone'')
	end'
	EXEC(@Sql)

	set @process = 'Insertar datos en tabla ReportsTotals -- CW-1331'
    set @Sql= 'if not exists (select * from ReportsTotals where Id=4250)
	begin
		insert into ReportsTotals values(4250, ''sum:dialog|sum:ncost|sum:total'')
	end'
	EXEC(@Sql)


	set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
		begin
		ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
		end'
	EXEC(@sql)


	set @process = 'Modificacion al SP ccspRepCatalogos-- CW-1331'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepCatalogos]
@type as tinyint,
@action tinyint = 0 -- 0 Filter select; 1 Filters Range
,@userId int =0 ---- se agrega parametro para filtros

AS
declare @tablatemp table (id int,
						description varchar(100) null)
declare @tempwork table
(idwg int)

if @action = 0
begin


	-- CAMPAIGNS
if @type = 1
begin

		if @userId <> 0 begin

			insert into @tablatemp
			select distinct caesp.IdCampEsp,'''' as description  from ccUsers us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
			inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1
			where us.[User_id] = @userId

			SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn
				from ccCamps camp
				inner join @tablatemp A on camp.cam_id = A.id

		end
		else begin
			SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn
				from ccCamps camp

		end
end


	-- DIAL RESULTS
	if @type = 2
	begin
		Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
		from ccTipoResultadoDial
		order by descripcion
	end

	-- WORKGROUPS
	if @type = 3
	begin
		if @userId <> 0 begin

			insert into @tempwork
			select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

			select distinct catwor.IDWG as id,catwor.WGName as description,''workgroupId'' as dbColumn from ccRIAWorkGroupUsers wgu
			inner join ccRIACat_WorkGroup catwor on wgu.IDWG = catwor.IDWG
			left join @tempwork temp on wgu.IDWG = temp.idwg
			where catwor.StatusWorkGroup = 1
			return
		end
		else  begin
			select idwg as id, wgname as description, ''workgroupId'' as dbColumn
			from ccRIACat_WorkGroup
			group by idwg, wgname	select * from ccRIACat_WorkGroup
			order by wgname
		end
  end


	-- AREAS
	if @type = 4
	begin
	if @userId <> 0 begin

			insert into @tablatemp
			select distinct wgu.User_id,caesp.IDArea  from ccUsers us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
			left join ccUsers caesp on wgu.IDWG = caesp.User_id
			where us.[User_id] = @userId

			select distinct idArea as id, AreaName as description, ''areaId'' as dbColumn
			from ccRIACat_Areas area inner join @tablatemp tem on area.IDArea = tem.id
			return
	end
		else begin

			select idArea as id, AreaName as description, ''areaId'' as dbColumn
			from ccRIACat_Areas
			group by idArea, AreaName
			order by AreaName
		end
	end

	-- DISPOSITIONS OUT
	if @type = 5
	begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalifOut
		order by [description]
	end

	-- USE
	if @type = 6
	begin
	if @userId <> 0 begin

			insert into @tempwork
					select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

			select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUsers us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

			inner join @tempwork awg on wgu.IDWG = awg.idwg
			where us.TipoUser_id = 1 and [status] = 1

			return
		end

		else begin

			SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
			FROM ccUsers B WHERE [status] = 1 and TipoUser_id = 1
			ORDER BY description
		end
	end

	-- ACDS**************
	if @type = 7
	begin
		if @userId <> 0 begin
				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''' as description  from ccUsers us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
				inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
				where us.[User_id] = @userId


				SELECT inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
					from ccinbound B
					inner join @tablatemp A on B.inbound_id = A.id
					return
			end
			else begin
				select inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
					from ccinbound
			end
	end

	-- DIDS
	if @type = 8
	begin
		select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
		from ccdnis
	end

	--DISPOSITIONS IN
	if @type = 9
	begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalif
		order by [description]
	end

	--SUBDISPOSITIONS IN
	if @type = 10
	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM ccTipoCalifSub
		order by [description]
	end

	--PROVIDER
	if @type = 11
	begin
		SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
		FROM cstoProvedor
		order by [description]
	end

	-- UNAVAILABLES
	if @type = 12
	begin
		SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
		FROM cctiponotready
		order by descripcion
	end

	-- DIALERS
	if @type = 13
	begin
		SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
		FROM ccoDialers
		order by descripcion
	end

	-- CallTYpes
	if @type = 14
	begin
			SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
			FROM ccStatusLlamada
		order by descripcion
	end

	-- SUBDISPOSITIONS OUT
	if @type = 21
	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM cctipocalifsubout
		order by [description]
	end

	-- AVRS TEMPLATE-SECTION
	if @type = 15
	begin
		SELECT c.id_concepto as id, (t.nombre+''-''+c.con_descripcion) as description, ''sectionId'' as dbColumn
		FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,nombre,MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato,nombre) as t
		ON f.id_formato = t.id_formato AND f.version = t.version INNER JOIN RIA_CONCEPTOS c
		ON t.id_formato = c.id_formato AND t.version = c.version
		order by f.nombre
	end

	-- AVRS TEMPLATES
	if @type = 16
	begin
		SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
		FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato) as t
		ON f.id_formato = t.id_formato AND f.version = t.version
		order by f.nombre
	end

	-- AVRS SUPERVISOR
	if @type = 17
	begin
		SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
		FROM ccUsers
		WHERE [status] = 1
		and TipoUser_id = 2
		ORDER BY [login]
	end

	--Status Call
	if @type = 25
	begin
		select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
		from ccstatusllamada
		order by [descripcion]
	end

	--Survey
	if @type = 26
	begin
	select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
	from Survey
	order by [description]
	end

	--dialType
	if @type = 29
	begin
		select dialId as id, [description] as description, ''dialId'' as dbcolumn
		from dialType
		order by [description]
	end

	--dial
	if @type = 30
	begin
		select id as id, [description] as description, ''dialId'' as dbcolumn
		from Dials
		order by [description]
	end

end
-----------------------------------------------------------
if @action = 1
begin
	-- TRUNKS
	if @type = 13
	begin
		SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
	end

	-- AVRS DISPOSITION
	if @type = 18
	begin
		SELECT 0 as [min], 100 as [max],''Disposition'' as dbColumn
	end

	-- AVG DISPOSITION
	if @type = 19
	begin
		SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
	end

	-- SCORE
	if @type = 20
	begin
		SELECT 0 as [min], 100 as [max],''score'' as dbColumn
	end
end'
	EXEC(@sql)

	set @process = 'Drop SP ccspRepOutAnswAndXferCalls -- CW-1331'
    set @Sql= 'if exists (select * from sys.procedures where name = N''ccspRepOutAnswAndXferCalls'')
    begin
        DROP PROCEDURE ccspRepOutAnswAndXferCalls;
    end'
    EXEC(@Sql)

	set @process = 'Crear SP ccspRepOutAnswAndXferCalls -- CW-1331'
    set @Sql= 'USE [ccReportsRia]
GO
/****** Object:  StoredProcedure [dbo].[ccspRepOutAnswAndXferCalls]    Script Date: 15/03/2018 12:25:22 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

declare @IVA INT
declare @country as tinyint


select @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25
select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104


if @country is null set @country = 1


if @action = 1
begin
	--Borrar lo que esta para no repetir
	delete from RepOutAnswAndXferCalls with(rowlock) where date >= @from AND date < @to

	insert into RepOutAnswAndXferCalls
	select Call.cal_inicio as [date],
	Call.cal_id as [callid],
	camps.cam_id as [campaignId],
	ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign],
	Usr.user_id as [userId],
	ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') as [Agent],
	ISNULL(Call.totalCall_Time, 0) as [dialog],
	Call.cal_telefono as [telephone],
	Call.cal_manual as [dialId],
	(select [description] from dialType where dialId = Call.cal_manual) as [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
	dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, Call.totalCall_Time) as [ncost],
	@IVA as iva,
	convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, Call.totalCall_Time),0.00) * (1 + (@IVA / 100.00))) as total
	from ccoCallsOut Call
	LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]
	INNER JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = @country)
	INNER JOIN ccoLogDials ccld on ccld.cal_id = Call.cal_id and ccld.answerbit = 1
	where Call.cal_inicio >= @from
    and Call.cal_inicio < @to
	order by date

	insert into RepOutAnswAndXferCalls
	select dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) as [date],
	clt.cal_id as [callid],
	'''' as [campaignId],
	'''' as [campaign],
	(case tipo when 1 then ci.User_id else co.User_id end) as [userId],
	isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccusers nolock where user_id = 
	(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') as [Agent],
	ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) as [dialog],
	case when modo = 0 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino)  
	when modo = 3 then isnull((select tel from telefonosConferencia where tel = clt.destino),clt.destino) 
	when modo = 4 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino) 
	when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end as [telephone],
	3 as [dialId],
	(select [description] from dialType where dialId = 3) as [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
	ISNULL(dbo.fnGetCstoTarifa(dbo.fnGetTipoLlamada(clt.destino), channel.proveedorId, clt.tAntesXfer+clt.tDespuesXfer), 0) as [ncost],
	@IVA as iva,
	convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(dbo.fnGetTipoLlamada(clt.destino), channel.proveedorId, clt.tAntesXfer+clt.tDespuesXfer),0.00) * (1 + (@IVA / 100.00))) as [total]
	from cclogtransfers clt
	LEFT JOIN cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1
	LEFT JOIN ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
	LEFT JOIN ccChannelTransfer channel on clt.pbxId=channel.pbxId and clt.channel between channel.startChannel and channel.endChannel
	LEFT JOIN cstoTarifa tarifa on tarifa.provedor_id=channel.proveedorId and tarifa.tipoLlamada_id=dbo.fnGetTipoLlamada(clt.destino)
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = dbo.fnGetTipoLlamada(clt.destino) and tl.Country_id = @country)
	where clt.modo not in (1,2) 
	and (clt.tAntesXfer > 0 or clt.tDespuesXfer > 0)
	and dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) >= @from
    and dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) < @to
	order by date 

end'
    EXEC(@Sql)




		 if @actualVersion  = @version - 1
	 	exec ccsp_getVersion 'BD', @version


	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off