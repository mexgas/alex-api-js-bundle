/*
Autor: Raymundo Gonzalez
Fecha: 2013/05/31
Descripcion: 
	Se crea el SP MLS_Report para reporte de Montepio
	Se modifica el SP ccspIVRInfo para fix en tabla pivote con columnas vacias
	Se modifica el SP ccspGenAgent para fix en calculo de tiempos del agente
	
Version requerida: 43
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '44'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @process = 'MLS_Report - Create Procedure'
		set @Sql='Create PROCEDURE [dbo].[MLS_Report]
@from as varchar(20),
@to as varchar(20),
@cam as varchar(4000)=''''
AS

declare @sql as varchar(max)
DECLARE @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @sql = ''SELECT ISNULL(rtrim(ltrim(camps.cam_descripcion)), ''''Sin campaña'''') as [Campaña], Fecha [Fecha], isnull(dials.cal_key,cs.cal_key) [Clave], cs.dato1 [Dato 1], cs.dato2 [Dato 2], cs.dato3 [Dato 3], cs.dato4 [Dato 4], cs.dato5 [Dato 5], telefono [Telefono], isNull( Tipo.[description],isnull(descripcion,''''Sin Calificacion'''')) AS [Calificacion], isNull(Tiposub.califSubDesc,''''Sin  SubCalificacion'''') as [Sub-Calificacion], isNull(us.Nombres + '''' '''' + us.ApellidoPaterno + '''' '''' + us.ApellidoMaterno,''''Sin Agente'''') as [Agente], dbo.fGetHHmmSS(dials.cal_tDialog) as [En Dialogo], isnull(descripcion,''''Sin Resultado de Marcacion'''') as [Resultado de Marcacion]  
	FROM (select dial.*, co.cal_key, isnull(co.calif_id,0) as calif, isnull(co.califsub_id,0) as subCalif, isnull(co.user_id,0) as user_id, isnull(co.cal_tDialog,0) as cal_tDialog 
		FROM ccoLogDials dial with(index(IX_ccoLogDials)) left join ccocallsout co with(index(IX_ccoCallsOut_7)) on (dial.callout_id = co.callout_id and dial.Telefono=co.cal_telefono and dial.cal_id = co.cal_id) 
		WHERE fecha >= convert(datetime,'''''' + @from + '''''') AND fecha < convert(datetime,'''''' + @to + '''''' ) ''
if @cam <> ''''
begin
	set @sql = @sql	+ '' and dial.Cam_id in ('' + @cam + '')''
end
set @sql = @sql	+ ''	) dials 
	LEFT JOIN ccoCallsOutSource cs ON dials.callout_id = cs.callout_id  
	LEFT JOIN cctipoResultadoDial tr ON dials.tiporesdial_id=tr.tiporesdial_id  
	LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]  
	LEFT JOIN ccTipoCalifOUT Tipo ON dials.calif=Tipo.calif_id
	LEFT JOIN ccTipoCalifSubOUT TipoSub ON dials.subCalif = TipoSub.califSub_id
	LEFT JOIN ccusers us On dials.user_id = us.user_id
	order by fecha''

if @idioma = 1
begin
set @sql = replace(@sql, ''[Campaña]'', ''[Campaign]'')
set @sql = replace(@sql, ''Sin campaña'', ''Without Campaign'')
set @sql = replace(@sql, ''[Fecha]'', ''[Date]'')
set @sql = replace(@sql, ''[Clave]'', ''[Cal Key]'')
set @sql = replace(@sql, ''[Dato 1]'', ''[Data 1]'')
set @sql = replace(@sql, ''[Dato 2]'', ''[Data 2]'')
set @sql = replace(@sql, ''[Dato 3]'', ''[Data 3]'')
set @sql = replace(@sql, ''[Dato 4]'', ''[Data 4]'')
set @sql = replace(@sql, ''[Dato 5]'', ''[Data 5]'')
set @sql = replace(@sql, ''[Telefono]'', ''[Telephone]'')
set @sql = replace(@sql, ''[Calificacion]'', ''[Disposition]'')
set @sql = replace(@sql, ''Sin Calificacion'', ''Without Disposition'')
set @sql = replace(@sql, ''[Sub-Calificacion]'', ''[Sub Disposition]'')
set @sql = replace(@sql, ''Sin  SubCalificacion'', ''Without  Sub Disposition'')
set @sql = replace(@sql, ''[Agente]'', ''[Agent]'')
set @sql = replace(@sql, ''Sin Agente'', ''Without Agent'')
set @sql = replace(@sql, ''[En Dialogo]'', ''[Dialog Time]'')
set @sql = replace(@sql, ''[Resultado de Marcacion]'', ''[Call Result]'')
set @sql = replace(@sql, ''Sin Resultado de Marcacion'', ''Without Call Result'')
end

begin try
	exec(@Sql)
	--print(@Sql)
end try

begin catch
	declare @error varchar(255)
	set @error=''Se presento un problema al generar el reporte, causa del mismo: "''+ERROR_MESSAGE()+''"''
	select @error
end catch'

	EXEC(@Sql)
		
		set @process = 'ccspIVRInfo - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspIVRInfo]
	@from as varchar(20),
	@to as varchar(20),
	@option as tinyint
	AS
	declare @pivot as varchar(max), @sql as varchar(max)

	if (@option = 1)
	begin
		exec ccspIVRInsert @from,@to
	end

	if (@option = 2)
	begin
		select ivrLLamadas.date as fecha, cal_ani as telefono
		, isNull(u.nombres + '' '' + u.apellidopaterno + '' '' + u.apellidomaterno,'''') as nombre
		, isnull(calif.description, ivrLLamadas.calif_id) as calificacion, cal_id as cal_id
		, isnull(
		(
			select selectedOption + '',''	from IVROptions
			where IVROptions.ivr_id = ivrLLamadas.ivr_id
			order by IVROptions.date for xml path('''')
		),'''') as opciones
		, dbo.fGetHHmmSS( isnull(datediff( ss, date, maxdate),0)) as tiempo
		from ivrLLamadas
		left join
		(
			select ivr_id, max(date) as maxDate from IVROptions
			group by ivr_id
		) optTime on ivrLLamadas.ivr_id = optTime.ivr_id
		left join ccusers u on (u.user_id = ivrLLamadas.user_id)
		left join cctipocalif calif on (calif.calif_id = ivrLLamadas.calif_id)
		where ivrLLamadas.date >= @from and ivrLLamadas.date < @to
		order by date
	end

	if (@option = 3)
	begin
		select convert(varchar(10),date,121) as fecha, sum(case when cal_id = 0 then 1 else 0 end) as [No transferidas], sum(case when cal_id > 0 then 1 else 0 end) as [Transferidas], count(*) Total
		from IVRLlamadas  where date >= @from and date < @to
		group by convert(varchar(10),date,121)
		order by 1
	end

	if (@option = 4)
	begin
		select @pivot = stuff((
		select ''],['' + selectedoption from
		(
			select distinct selectedoption from IVROptions 
			join (
				select ivr_id, min(date) as minDate from IVROptions
				where date >= @from and date < @to
				group by ivr_id
			) subivr
			on subivr.ivr_id = IVROptions.ivr_id and subivr.minDate=IVROptions.date
			group by selectedoption
		)A order by ''],['' + selectedoption for xml path('''')
		),1,2, '''') + '']''
		
		if @pivot is null
			select 0 as fecha where 1=0

		select @pivot = REPLACE(@pivot, ''[]'', ''[ ]'')
		set @sql = ''select fecha, ''+@pivot+'' from
		(
			select convert(varchar(10), date, 121) as fecha, selectedOption from IVROptions
			join
			(
				select ivr_id, min(date) as minDate from IVROptions
				where date >= '''''' + @from + '''''' and date < '''''' +@to + ''''''
				group by ivr_id
			) subivr
			on subivr.ivr_id = IVROptions.ivr_id and subivr.minDate=IVROptions.date
		)p pivot( count(selectedOption) for selectedOption in (''+@pivot+'') ) as pvt
		order by fecha''
		exec (@sql)
	end

	if (@option = 5)
	begin
		select [level] as Nivel, min(Description) as Descripcion, count(*) as Cantidad
		from ivrstructure,
		( 
			select ivr_id, isnull
			((
				select selectedOption + '','' from IVROptions	
				where IVROptions.ivr_id = ivrLLamadas.ivr_id 
				order by IVROptions.date for xml path('''')
			),''#'') as opciones 
			from ivrLLamadas
			where ivrLLamadas.date >= @from and ivrLLamadas.date < @to
		)x 
		where opciones like [level]+''%''
		group by [level]
		order by [level]
	end'
					
	EXEC(@Sql)
	
		set @process = 'ccspGenAgent - Alter Procedure'
		Set @Sql='ALTER PROCEDURE [dbo].[ccspGenAgent]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenAgent WHERE timegroup>=@from AND timegroup<@to

INSERT INTO ccGenAgent(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl)
SELECT timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl
 FROM(
		SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
			,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
		 FROM(
			SELECT 
				xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
				,ISNULL(SUM(ccGenViewInCall.txfer),0)+ ISNULL(SUM(ccGenViewOutCall.txfer),0)as txfer
				,ISNULL(SUM(ccGenViewInCall.tdialog),0)+ ISNULL(SUM(ccGenViewOutCall.tdialog),0)as tdialog
				,ISNULL(SUM(ccGenViewInCall.tnotes),0)+ ISNULL(SUM(ccGenViewOutCall.tnotes),0)as tnotes
				,ISNULL(SUM(ccGenViewInCall.tring),0)+ ISNULL(SUM(ccGenViewOutCall.tring),0)as tring
				,ISNULL(SUM(ccGenViewInCall.nMoh),0)+ ISNULL(SUM(ccGenViewOutCall.nMoh),0)as nMoh
				,ISNULL(SUM(ccGenViewInCall.nWHag),0)+ ISNULL(SUM(ccGenViewOutCall.nWHag),0)as nWHag
				,ISNULL(SUM(ccGenViewInCall.nWHcl),0)+ ISNULL(SUM(ccGenViewOutCall.nWHcl),0)as nWHcl
		
				,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
							 FROM ccGenSession
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t1
				,ISNULL((SELECT top 1 3600
							 FROM ccGenSession
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t2
				,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
							 FROM ccGenSession
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t3
				,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
							 FROM ccGenSession
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t4
			
			 FROM(
					SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
						,ccLogAgentesDia.[user_id]
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
						,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
					 FROM ccLogAgentesDia
					 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
					 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
				)xTimeDetail
					LEFT OUTER JOIN ccGenViewInCall ON(xTimeDetail.timegroup=ccGenViewInCall.timegroup AND xTimeDetail.[user_id]=ccGenViewInCall.[user_id])
					LEFT OUTER JOIN ccGenViewOutCall ON(xTimeDetail.timegroup=ccGenViewOutCall.timegroup AND xTimeDetail.[user_id]=ccGenViewOutCall.[user_id])
				GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		 	)xDetail
	)xAllTimes
 WHERE tlog>0
 ORDER BY timegroup,[user_id]'
 
 	EXEC(@Sql)
	
------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

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
