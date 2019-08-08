/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Carlos Chavez
Date: 2019/08/07
Description: CW-2611


Database: ccReportsRia
Required version: 70


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 71

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		
		
		SET @process = 'CW-2611 Create Table ccEstadosAni'

		SET @sql = 'CREATE TABLE [dbo].[ccEstadosAni](
	[id_AniList] [smallint] NOT NULL,
	[Estado] [varchar](350) NOT NULL,
	[telAni] [varchar](30) NOT NULL,
	[area] [varchar](20) NOT NULL
) ON [PRIMARY]'

		EXEC (@sql)
		
		
		set @process = 'CW-2611 CREATE Function [dbo].[TelAni]'
		set @sql = 'CREATE Function [dbo].[TelAni](@tel varchar(32), @lista smallint)
RETURNS varchar(32)
AS
BEGIN
declare @cldLocal varchar(10), @pais tinyint, @lon tinyint, @ret as varchar(10)

select  @cldLocal = valor from ccsettings where setting_id = 17
select @pais = valor, @ret = '''' from ccSettings where setting_id = 104

	if @lista = 0 begin
		select @tel = ''''
	end

	if @pais = 1 begin --Empieza Mexico
		select @lon = len(@tel)
		if @lon >= 10 begin
			select TOP 1 @tel = telani from ccEstadosAni WITH (NOLOCK) where id_anilist = @lista and (
				( left(right(@tel, 10), 3) = area and len(area) = 3 )
				or
				( left(right(@tel, 10), 2) = area and len(area) = 2 ))
			AND telani <> ''''
		end
		else begin
			select @tel = ''''
		end

		return @tel
	end --Termina Mexico

	if @pais = 2 begin  -- Empieza Argentina
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=13 begin
			select @tel = telAni from ccEstadosAni where id_anilist = @lista and
				(( @lon = 6 and left(@tel,4) = area and len(area) = 4 )
				or
				( @lon = 7 and left(@tel,3) = area and len(area) = 3 )
				or
				( @lon = 8 and left(@tel,2) = area and len(area) = 2 )
				or
				( @lon = 11 and substring(@tel, 2, 2) = area and len(area) = 2 )
				or
				( @lon = 11 and substring(@tel, 2, 3) = area and len(area) = 3 )
				or
				( @lon = 11 and substring(@tel, 2, 4) = area and len(area) = 4 )
				or
				( @lon = 13 and substring(@tel, 2, 2) = area and len(area) = 2 )
				or
				( @lon = 13 and substring(@tel, 2, 3) = area and len(area) = 3 )
				or
				( @lon = 13 and substring(@tel, 2, 4) = area and len(area) = 4 ))
		end
		else begin
			select @tel = ''''
		end
			return @tel
	end  --Termina Argentina

	if @pais = 3 begin  --Empieza Colombia
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=13 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
				(( len(@tel) = 7 and @cldlocal = area )
				or
				( len(@tel) = 8 and left(@tel,5) = area )
				or
				( len(@tel) in(10,11) and (left(@tel,1) = ''3'' or substring(@tel,2,1) = ''3'')))
		end
		else begin
			select @tel = ''''
		end
		return @tel
	end  --Termina Colombia

	if @pais = 4 begin --Empieza USA
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=15 begin
			if @lon = 7 begin
				set @tel = @cldLocal + @tel
			end
			set @tel = right(@tel, 10)
			select @tel = telani from ccEstadosAni where area = left(@tel,3) and id_anilist = @lista
		end
		else begin
			select @tel = ''''
		end
		return @tel
	end --Termina USA

	if @pais = 5 begin -- Empieza Chile
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=15 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
			(( len(@tel) = 6 and @cldlocal = area )
			or
			( len(@tel) = 7 and @cldlocal = area )
			or
			( len(@tel) = 8 and left(@tel,1) = area )
			or
			( len(@tel) = 8 and left(@tel,2) = area )
			or
			( len(@tel) = 9 and left(@tel,2) = area )
			or
			( len(@tel) = 10 and substring(@tel,3,1) = area and left(@tel,2) = ''09'' ))
		end
		else begin
			select @tel = ''''
		end
		return @tel
	end --Termina Chile

	if @pais = 6 begin -- Venezuela
		select @lon = len(@tel)
		if @lon >= 7 and @lon <=11 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
				(len(@tel) = 7 and left(@tel,3) = area or
				len(@tel) = 11 and substring(@tel,2,3) = area)
		end
		else begin
			select @tel = ''''
		end

		return @tel
	end --Termina Venezuela

	if @pais = 7 begin -- Empieza UK
		select @lon = len(@tel)
		if left(@tel,1) = ''0'' begin
			set  @tel = substring(@tel,2,(len(@tel)-1))
		end

		if @lon >= 9 and @lon <=11 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
			(( len(@tel) = 10 and substring(@tel,1,5) = area )
			or
			( len(@tel) = 10 and substring(@tel,1,4) = area )
			or
			( len(@tel) = 10 and substring(@tel,1,3) = area )
			or
			( len(@tel) = 10 and substring(@tel,1,2) = area )
			or
			( len(@tel) = 9 and substring(@tel,1,5) = area )
			or
			( len(@tel) = 9 and substring(@tel,1,4) = area ) )
		end
		else begin
			select @tel = ''''
		end
		return @tel
	end --Termina UK

	if @pais = 8 begin --Empieza Arabia Saudita
		select @lon = len(@tel)
		if @lon >= 7 and @lon <=13 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
				(len(@tel) = 7 and ''0''+@cldlocal + ''-''+ substring(@tel,1,1) + ''00'' = area or
				len(@tel) = 9 and substring(@tel,1,3) + ''00'' = replace(area,''-'','''') or
				len(@tel) = 10 and substring(@tel,1,4) + ''00'' = replace(area,''-'','''') or
				len(@tel) = 11 and substring(@tel,1,4)+ ''0'' = replace(area,''-'','''') or
				len(@tel) = 11 and substring(@tel,1,5) = replace(area,''-'',''''))
		end
		else begin
			select @tel = ''''
		end

		return @tel
	end --Termina Arabia Saudita

	if @pais = 9 --Empieza Australia
		begin
			select @lon = len(@tel)
			if @lon >= 8 and @lon <=10
				begin
					select @tel = telani from ccEstadosAni where id_anilist = @lista
					and (len(@tel) = 8 and @cldLocal + substring(@tel,1,2) = area or
							len(@tel) = 9 and ''0'' + substring(@tel,1,3) = area or
							len(@tel) = 10 and substring(@tel,1,4) = area)
				end
			else
				begin
					select @tel = ''''
				end

			return @tel
		end --Termina Australia

	if @pais = 10 begin -- Empieza Brasil
		select @lon = len(@tel)
		if @lon >= 8 and @lon <=15 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and (
				((@lon       = 8        )                                    and             @cldlocal = area) or
				((@lon       = 9        ) and substring(@tel, 1, 1) = ''9''    and             @cldlocal = area) or
				((@lon between 10 and 11)                                    and substring(@tel, 1, 2) = area) or
				((@lon between 12 and 13) and substring(@tel, 1, 4) = ''9090'' and             @cldlocal = area) or
				((@lon       = 13       )                                    and substring(@tel, 4, 2) = area) or
				((@lon between 14 and 15) and substring(@tel, 1, 2) = ''90''   and substring(@tel, 5, 2) = area) or
				((@lon       = 14       ) and substring(@tel, 1, 1) = ''0''    and substring(@tel, 4, 2) = area))
		end
		else begin
			select @tel = ''''
		end

		return @tel
	end -- Termina Brasil

	if @pais = 11 begin --Empieza Guatemala
		if len(@tel) = 8  begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
		end
		else begin
			select @tel = ''''
		end

		return @tel
	end --Termina Guatemala

	if @pais = 12 begin --Empieza Costa Rica
		if len(@tel) = 8  begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
		end
		else if len(@tel) = 10 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 3) = area
		end
		else begin
			if charindex(substring(@tel,1,2),''00,08'') <= 0
				select @tel = ''''
			else
				select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
		end

		return @tel
	end --Termina Costa Rica

	if @pais = 13 begin --Empieza Salvador
		if len(@tel) = 8  begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
		end
		else begin
			if charindex(substring(@tel,1,2),''00'') <= 0
				select @tel = ''''
			else
				select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
		end

		return @tel
	end --Termina Salvador

	if @pais = 14 begin --Empieza Espa?a
		if len(@tel) = 9  begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
			((substring(@tel, 1, 1) = area) or
			(substring(@tel, 1, 2) = area) or
			(substring(@tel, 1, 3) = area))
		end
		else
			select @tel = ''''

		return @tel
	end --Termina Espa?a

	if @pais = 15 begin -- Empieza Peru
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=9 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
			(( len(@tel) = 6 and @cldlocal = area )
			or
			( len(@tel) = 7 and @cldlocal = area )
			or
			( len(@tel) = 9 and left(@tel,1)=''0'' and substring(@tel,2,len(@cldlocal)) = area ))
		end
		else begin
			select @tel = ''''
		end
		return @tel
	end --Termina Peru

	if @pais = 16 begin --Empieza Panama
		if len(@tel) = 7  begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
		end
		else begin
			if charindex(substring(@tel,1,2),''00'') <= 0
				select @tel = ''''
			else
				select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
		end

		return @tel
	end --Termina Panama

	return @ret
END'

		exec (@sql)
		

		SET @process = 'CW-2611 Add Column RepOutDialDetail.trunk'

		SET @sql = 'if not exists (select * from sys.columns where name = N''trunk'' and Object_ID = Object_ID(N''RepOutAnswAndXferCalls''))
		begin
			ALTER TABLE RepOutAnswAndXferCalls ADD trunk smallint NULL 
		end'

		EXEC (@sql)



		SET @process = 'CW-2611 Add Column RepOutDialDetail.ANI'
		SET @sql = 'if not exists (select * from sys.columns where name = N''ANI'' and Object_ID = Object_ID(N''RepOutAnswAndXferCalls''))
		begin
			ALTER TABLE RepOutAnswAndXferCalls ADD ANI varchar(30) NULL 
		end'

		EXEC (@sql)


		SET @process = 'CW-2611 Alter Procedure ccspRepOutAnswAndXferCalls'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))

if @to is null
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
                select COALESCE([Call].cal_inicio,ccld.fecha) as [date],
                isnull(ccld.cal_id,0) as [callid],
                isnull(ccld.cam_id,0) as [campaignId],
                ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign],
                isnull([Call].user_id,0) as [userId],
                ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') as [Agent],
                case when (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) end as [dialog],
                ccld.telefono as [telephone],
                isnull(Call.cal_manual,0) as [dialId],
                isnull((select [description] from dialType where dialId = Call.cal_manual),''systemTranslated_Auto'') as [dialType],
                ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
                dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType), COALESCE(Call.provedor_id,ccld.proBIDs) , case when (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) end) as [ncost],
                @IVA as iva,
                convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType), COALESCE(Call.provedor_id,ccld.proBIDs) , case when (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) end),0.00) * (1 + (@IVA / 100.00))) as total,
				COALESCE(ccld.Puerto, Call.cal_puerto, 0) as [trunk],
				case when dbo.TelAni(ccld.Telefono, camps.id_anilist) <> '''' then dbo.TelAni(ccld.Telefono, camps.id_anilist) else camps.ani end [ANI]
                from (select *, [dbo].[GetProveedor](Telefono, Puerto,CallType) as proBIDs from (select *, tipoLlamada_id as CallType from ccologdials WITH(NOLOCK) where fecha >= @from and fecha < @to and answerbit = 1 ) as basequery ) ccld
                LEFT JOIN ccoCallsOut Call WITH(NOLOCK) on ccld.cal_id = Call.cal_id and ccld.answerbit = 1
                LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
                LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
                LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
                order by date

                insert into RepOutAnswAndXferCalls
                select dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) as [date],
                clt.cal_id as [callid],
                COALESCE(co.cam_id,ci.inbound_id,''0'')  as [campaignId],
                COALESCE(camps.cam_descripcion, ACD.descripcion, ''systemTranslated_NoCampaign'') as [campaign],
                isnull((case tipo when 1 then ci.User_id else co.User_id end),0) as [userId],
                isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccusers nolock where user_id = 
                (case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') as [Agent],
                case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else 60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end as [dialog],
                case when modo = 0 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino)  
                when modo = 3 then isnull((select tel from telefonosConferencia where tel = clt.destino),clt.destino) 
                when modo = 4 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino) 
                when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end as [telephone],
                3 as [dialId],
                (select [description] from dialType where dialId = 3) as [dialType],
                ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
                ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId, case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else 60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end), 0) as [ncost],
                @IVA as iva,
                convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId, case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else  60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end),0.00) * (1 + (@IVA / 100.00))) as [total],
				IsNull(clt.channel, 0) as [trunk],
				case when (@country = 1 and modo = 4) then case when dbo.TelAni(clt.destino, camps.id_anilist) <> '''' then dbo.TelAni(clt.destino, camps.id_anilist) else camps.ani end else '''' end [ANI]
                from (select *, tipoLlamada_id as  CallType from cclogtransfers WITH(NOLOCK) where modo not in (1,2) and (tAntesXfer > 0 or tDespuesXfer > 0) and dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) >= @from and dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) < @to) clt
                LEFT JOIN cccallsin ci WITH(NOLOCK) on ci.cal_id=clt.cal_id and tipo=1
                LEFT JOIN ccocallsout co WITH(NOLOCK) on co.cal_id=clt.cal_id and tipo=2 
                LEFT JOIN ccChannelTransfer channel on clt.pbxId=channel.pbxId and clt.channel between channel.startChannel and channel.endChannel
                LEFT JOIN cstoTarifa tarifa on tarifa.provedor_id=channel.proveedorId and tarifa.tipoLlamada_id = clt.CallType
                LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType and tl.Country_id = @country)
                LEFT JOIN ccCamps camps ON camps.[cam_id] = co.cam_id
                LEFT JOIN ccInbound ACD ON ACD.[Inbound_id] = ci.Inbound_id
                order by date 

end'

		EXEC (@sql)






		--IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
