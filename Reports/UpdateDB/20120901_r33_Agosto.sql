/*
Autor: Raymundo González
Fecha: 2012/09/01
Descripcion: 
	Se insertan registros para uso del scheduler en la tabla exportReports
	Modificacion de las tablas cstoTipoLlamada y ccDNIS para nuevos planes de marcacion
	Creacion de la Tabla ccoCallBacks para almacenar los callbacks del nuevo reporte	
	Creacion de la Tabla IVRCallsIn para registro de opciones de IVR
	Creacion de la Funcion zeroCalendarPadding para agregar un 0 a la izquierda de los numeros de 1 digito en fechas de calendario
	Creacion de la Vista holdViewDataOutbound para los tiempos de espera en ccoCallsOut
	Creacion de la Vista holdViewDataInbound para los tiempos de espera en ccCallsIn
	Creacion del SP ccspGenCallBacksInfo para nuevo reporte de callbacks
	Creacion del SP ccspIVRInsert para generar informacion de reportes IVR
	Creacion del SP ccsp_GenHoldReport para generar nuevo reporte de tiempos de espera
	Modificacion del SP ccspGenOutCstoResumen para utilizar los cambios de la tabla cstoTipoLlamada en cuanto a sus relaciones
	Modificacion del SP ccspIVRInfo para manejo de IVR y validacion de elementos de IVR
	
Version requerida: 32
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '33'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @Sql='alter table cstoTipoLlamada
	add country_id tinyint NOT NULL CONSTRAINT DF_cstoTipoLlamada_country_id DEFAULT 0

alter table cstoTipoLlamada
drop CONSTRAINT PK_cstoTipoLlamada

ALTER TABLE dbo.cstoTipoLlamada ADD CONSTRAINT
	PK_cstoTipoLlamada PRIMARY KEY CLUSTERED 
	(
	tipoLlamada_id,
	country_id
	) WITH( PAD_INDEX = OFF, FILLFACTOR = 90, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

alter table ccDNIS
	alter column dni_numero varchar(50) NULL

insert into exportReports (jobid,jobtype,intervalMinutes,tableN,idN,dateN,cols,skipMinutes) 
values (13,1,10,''IVRCallsIn'',''IVR_id'',''date'',''IVR_id,cal_ani,date'',60)

insert into exportReports (jobid,jobtype,intervalMinutes,tableN,idN,dateN,cols,skipMinutes) 
values (14,2,10,''IVROptions'','''',''date'',''IVR_id,selectedOption,date,saveType'',60)

update exportReports 
set cols = ''califSub_id, califSubDesc, isnull(orden,0) as orden, isnull(canReprogram,0) as canReprogram, califSub_Status'' 
where jobid = 225'
	
	EXEC(@Sql)


 		set @Sql='CREATE TABLE [dbo].[ccoCallBacks](
	[callout_id] [int] NULL,
	[user_id] [int] NULL,
	[cam_id] [int] NULL,
	[cal_key] [varchar](20) NULL,
	[cal_telefono] [varchar](30) NULL,
	[cal_telCB] [varchar](30) NULL,
	[cal_fecha] [datetime] NULL,
	[cal_fusercallback] [datetime] NULL,
	[cal_fcallback] [datetime] NULL,
	[status] [tinyint] NULL,
	[schedulerStatus] [tinyint] NULL
) ON [PRIMARY]'

	EXEC(@Sql)

		set @Sql='CREATE TABLE [dbo].[IVRCallsIn](
	[IVR_id] [int] IDENTITY(1,1) NOT NULL,
	[cal_ani] [varchar](30) NULL,
	[date] [datetime] NOT NULL,
 CONSTRAINT [PK_IVR_ID_1] PRIMARY KEY CLUSTERED 
(
	[IVR_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]'
	
	EXEC(@Sql)

		set @Sql='CREATE FUNCTION zeroCalendarPadding
(
	@number nvarchar(2)	
)
RETURNS nvarchar(2)
AS
BEGIN
     
    DECLARE @result nvarchar(2)
    
	IF len(@number) = 1 
      BEGIN
         SET @result =  N''0''+@number
      END 
    ELSE 
      BEGIN
         SET @result = @number
      END

    RETURN @result
END'
	
	EXEC(@Sql)

		set @Sql='CREATE VIEW [dbo].[holdViewDataOutbound] AS
SELECT
0 as ''type'', 
a.cam_id as ''id'',
cam_descripcion as ''description'',
a.User_id as ''userId'',
login as ''login'' ,
cal_tmoh as ''mohTime'', 
cal_Inicio as ''date'', 
DATEPART(yyyy,cal_Inicio) as ''year'',
DATEPART(mm,cal_Inicio) as ''month'',
DATEPART(dd,cal_Inicio) as ''day'',
DATEPART(hh,cal_Inicio) as ''hour''
FROM [dbo].[ccoCallsOut] a WITH(NOLOCK),[dbo].[ccCamps] b WITH(NOLOCK),[dbo].[ccUsers] c WITH(NOLOCK)
WHERE a.cam_id = b.cam_id
AND a.User_id = c.User_id 
AND cal_tmoh > 0 '
	
	EXEC(@Sql)

		set @Sql='CREATE VIEW [dbo].[holdViewDataInbound] AS
SELECT
1 as ''type'',
a.Inbound_id as ''id'',
descripcion as ''description'',
a.User_id as ''userId'',
login as ''login'',
cal_tmoh as ''mohTime'', 
cal_Inicio as ''date'', 
DATEPART(yyyy,cal_Inicio) as ''year'',
DATEPART(mm,cal_Inicio) as ''month'',
DATEPART(dd,cal_Inicio) as ''day'',
DATEPART(hh,cal_Inicio) as ''hour''
FROM [dbo].[cccallsin] a WITH(NOLOCK),[dbo].[ccInbound] b WITH(NOLOCK),[dbo].[ccUsers] c WITH(NOLOCK)
WHERE a.Inbound_id = b.Inbound_id
AND a.User_id = c.User_id
AND cal_tmoh > 0 '
	
	EXEC(@Sql)

 		set @Sql='CREATE PROCEDURE [dbo].[ccspGenCallBacksInfo]
@from AS datetime,
@to AS datetime,
@users as varchar(max) = '''',
@campaigns as varchar(max) = ''''
AS

declare @idioma int

select @idioma = convert(int,valor)
from ccsettings
where setting_id = 23

select @to = dateadd(ss,-1,dateadd(dd,1,@to))

if @idioma = 0
	begin
		if @users = '''' and @campaigns = ''''
			begin
				select b.login as Usuario,c.cam_descripcion as Campaña,cal_key as Cal_Key,cal_telefono as Tel_Original,cal_telCB as Tel_Agendado,
					cal_fecha as Fecha_Original,cal_fusercallback as Fecha_Agendada,
					case a.status when 0 then ''Pendiente''
						when 1 then ''Contestado''
						when 2 then ''No Contestado''
						when 3 then ''Reciclado''
						when 4 then ''Expirado''
						when 5 then ''Registro Viejo''
						when 6 then ''Carga de Registro'' end as Estado, cal_fcallback as Fecha_Marcacion
				from ccocallbacks a, ccusers b, cccamps c
				where cal_fecha between @from and @to
				and a.user_id = b.user_id
				and a.cam_id = c.cam_id
			end
		else if @users <> '''' and @campaigns = ''''
			begin
				select b.login as Usuario,c.cam_descripcion as Campaña,cal_key as Cal_Key,cal_telefono as Tel_Original,cal_telCB as Tel_Agendado,
					cal_fecha as Fecha_Original,cal_fusercallback as Fecha_Agendada,
					case a.status when 0 then ''Pendiente''
						when 1 then ''Contestado''
						when 2 then ''No Contestado''
						when 3 then ''Reciclado''
						when 4 then ''Expirado''
						when 5 then ''Registro Viejo''
						when 6 then ''Carga de Registro'' end as Estado, cal_fcallback as Fecha_Marcacion
				from ccocallbacks a, ccusers b, cccamps c
				where cal_fecha between @from and @to
				and a.user_id = b.user_id
				and a.cam_id = c.cam_id
				and a.user_id in (select Value from fn_RIASplitDelimited(@users, '',''))
			end
		else if @users = '''' and @campaigns <> ''''
			begin
				select b.login as Usuario,c.cam_descripcion as Campaña,cal_key as Cal_Key,cal_telefono as Tel_Original,cal_telCB as Tel_Agendado,
					cal_fecha as Fecha_Original,cal_fusercallback as Fecha_Agendada,
					case a.status when 0 then ''Pendiente''
						when 1 then ''Contestado''
						when 2 then ''No Contestado''
						when 3 then ''Reciclado''
						when 4 then ''Expirado''
						when 5 then ''Registro Viejo''
						when 6 then ''Carga de Registro'' end as Estado, cal_fcallback as Fecha_Marcacion
				from ccocallbacks a, ccusers b, cccamps c
				where cal_fecha between @from and @to
				and a.user_id = b.user_id
				and a.cam_id = c.cam_id
				and a.cam_id in (select Value from fn_RIASplitDelimited(@campaigns, '',''))
			end
		else if @users <> '''' and @campaigns <> ''''
			begin
				select b.login as Usuario,c.cam_descripcion as Campaña,cal_key as Cal_Key,cal_telefono as Tel_Original,cal_telCB as Tel_Agendado,
					cal_fecha as Fecha_Original,cal_fusercallback as Fecha_Agendada,
					case a.status when 0 then ''Pendiente''
						when 1 then ''Contestado''
						when 2 then ''No Contestado''
						when 3 then ''Reciclado''
						when 4 then ''Expirado''
						when 5 then ''Registro Viejo''
						when 6 then ''Carga de Registro'' end as Estado, cal_fcallback as Fecha_Marcacion
				from ccocallbacks a, ccusers b, cccamps c
				where cal_fecha between @from and @to
				and a.user_id = b.user_id
				and a.cam_id = c.cam_id
				and a.user_id in (select Value from fn_RIASplitDelimited(@users, '',''))
				and a.cam_id in (select Value from fn_RIASplitDelimited(@campaigns, '',''))
			end
	end
else if @idioma = 1
	begin
		if @users = '''' and @campaigns = ''''
			begin
				select b.login as Login,c.cam_descripcion as Campaign,cal_key as Cal_Key,cal_telefono as Original_Phone,cal_telCB as CallBack_Phone,
					cal_fecha as Original_Date,cal_fusercallback as CallBack_Date,
					case a.status when 0 then ''Pending''
						when 1 then ''Answer''
						when 2 then ''No Answer''
						when 3 then ''Recicled''
						when 4 then ''Expired''
						when 5 then ''Old Record''
						when 6 then ''Load Record'' end as Status, cal_fcallback as Dial_Date
				from ccocallbacks a, ccusers b, cccamps c
				where cal_fecha between @from and @to
				and a.user_id = b.user_id
				and a.cam_id = c.cam_id
			end
		else if @users <> '''' and @campaigns = ''''
			begin
				select b.login as Login,c.cam_descripcion as Campaign,cal_key as Cal_Key,cal_telefono as Original_Phone,cal_telCB as CallBack_Phone,
					cal_fecha as Original_Date,cal_fusercallback as CallBack_Date,
					case a.status when 0 then ''Pending''
						when 1 then ''Answer''
						when 2 then ''No Answer''
						when 3 then ''Recicled''
						when 4 then ''Expired''
						when 5 then ''Old Record''
						when 6 then ''Load Record'' end as Status, cal_fcallback as Dial_Date
				from ccocallbacks a, ccusers b, cccamps c
				where cal_fecha between @from and @to
				and a.user_id = b.user_id
				and a.cam_id = c.cam_id
				and a.user_id in (select Value from fn_RIASplitDelimited(@users, '',''))
			end
		else if @users = '''' and @campaigns <> ''''
			begin
				select b.login as Login,c.cam_descripcion as Campaign,cal_key as Cal_Key,cal_telefono as Original_Phone,cal_telCB as CallBack_Phone,
					cal_fecha as Original_Date,cal_fusercallback as CallBack_Date,
					case a.status when 0 then ''Pending''
						when 1 then ''Answer''
						when 2 then ''No Answer''
						when 3 then ''Recicled''
						when 4 then ''Expired''
						when 5 then ''Old Record''
						when 6 then ''Load Record'' end as Status, cal_fcallback as Dial_Date
				from ccocallbacks a, ccusers b, cccamps c
				where cal_fecha between @from and @to
				and a.user_id = b.user_id
				and a.cam_id = c.cam_id
				and a.cam_id in (select Value from fn_RIASplitDelimited(@campaigns, '',''))
			end
		else if @users <> '''' and @campaigns <> ''''
			begin
				select b.login as Login,c.cam_descripcion as Campaign,cal_key as Cal_Key,cal_telefono as Original_Phone,cal_telCB as CallBack_Phone,
					cal_fecha as Original_Date,cal_fusercallback as CallBack_Date,
					case a.status when 0 then ''Pending''
						when 1 then ''Answer''
						when 2 then ''No Answer''
						when 3 then ''Recicled''
						when 4 then ''Expired''
						when 5 then ''Old Record''
						when 6 then ''Load Record'' end as Status, cal_fcallback as Dial_Date
				from ccocallbacks a, ccusers b, cccamps c
				where cal_fecha between @from and @to
				and a.user_id = b.user_id
				and a.cam_id = c.cam_id
				and a.user_id in (select Value from fn_RIASplitDelimited(@users, '',''))
				and a.cam_id in (select Value from fn_RIASplitDelimited(@campaigns, '',''))
			end
	end'

	EXEC(@Sql)

		set @Sql='CREATE PROCEDURE [dbo].[ccspIVRInsert]
@from as varchar(20),
@to as varchar(20)
as
		delete from IVRLlamadas where date >= @from and date < @to

		insert into IVRLlamadas (ivr_id,cal_ani,user_id,calif_id,cal_id,date)
		select A.Ivr_id,A.cal_ani,isnull(B.user_id,0),isnull(B.calif_id,0),isnull(B.cal_id,0),A.date from IVRCallsIn as A 
		left join ccCallsIn As B on  A.IVR_id = B.IVR_id 
		where date >= @from and date < @to'
	
	EXEC(@Sql)

		set @Sql='CREATE PROCEDURE ccsp_GenHoldReport
	@fechaInicio nvarchar(20),
    @fechaFin nvarchar(20),
    @agentsId nvarchar(2000)=N'''', 
    @campsId nvarchar(2000)=N'''',
    @acdsId nvarchar(2000)=N'''',
    @groupType nvarchar(1)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    DECLARE @agentsClause nvarchar(2100)
    DECLARE @campsClause nvarchar(2100)
    DECLARE @acdsClause nvarchar(2100)
    DECLARE @groupByClause nvarchar(300)
    DECLARE @selectClause nvarchar(1000)
    DECLARE @innerSelectClause nvarchar(1000)
    DECLARE @sql nvarchar(max)
    DECLARE @innerSql nvarchar(max)
	DECLARE @campsSelect nvarchar(max)
	DECLARE @inboundSelect nvarchar(max)
	DECLARE @applyUnion nvarchar(30)
    DECLARE @params nvarchar(max)
	DECLARE @checkCamps bit
	DECLARE @checkInbound bit     
	
	SET @checkCamps = 1
	SET @checkInbound = 1     
	SET @applyUnion = N''''
	SET @campsSelect = N''''
	SET @inboundSelect = N''''
    
    SET @params = N'' @fechaInicio nvarchar(20), ''+
                  N'' @fechaFin nvarchar(20), ''+
			      N'' @agentsId nvarchar(2000), ''+
				  N'' @campsId nvarchar(2000), ''+
				  N'' @acdsId nvarchar(2000)''
                      
    IF len(@agentsId) = 0
      BEGIN
         SET @agentsClause = N'''' 
      END
    ELSE 
      BEGIN
		SET @agentsClause = N'' AND userId IN (SELECT value FROM fn_RIASplitDelimited(@agentsId,'''','''')) '' 
      END

    IF len(@campsId) = 0
      BEGIN         
		SET @campsClause = N''''        
      END
    ELSE 
      BEGIN
		SET @campsClause = N'' AND id IN (SELECT value FROM fn_RIASplitDelimited(@campsId,'''','''')) ''         
      END

   IF len(@acdsId) = 0
      BEGIN
		SET @acdsClause = N''''         
      END
    ELSE 
      BEGIN        
		SET @acdsClause = N'' AND id IN (SELECT value FROM fn_RIASplitDelimited(@acdsId,'''','''')) ''
      END
	  
    IF @acdsClause = N'''' AND @campsClause <> N''''
	  BEGIN	    
		SET @checkInbound = 0
	  END
	 
	IF @campsClause = N'''' AND @acdsClause <> N''''
	  BEGIN
	    SET @checkCamps = 0 
	  END

    IF @groupType = N''P'' 
       BEGIN
          SET @groupByClause = N''userId,login,year,month'' --Group by period
          SET @selectClause = N''userId,login,CONVERT(varchar(4),year)+''''-''''+dbo.zeroCalendarPadding(CONVERT(varchar(2),month)) AS date,sum(mohTime) AS holdtime'' --Select period
       END
    ELSE IF @groupType = N''H'' 
       BEGIN
          SET @groupByClause = N''userId,login,year,month,day,hour'' --Group by hour
		  SET @selectClause = N''userId,login,CONVERT(varchar(4),year)+''''-''''+dbo.zeroCalendarPadding(CONVERT(varchar(2),month))+''''-''''+dbo.zeroCalendarPadding(CONVERT(varchar(2),day))+'''' ''''+dbo.zeroCalendarPadding(CONVERT(varchar(2),hour))+'''':00'''' AS date,sum(mohTime) AS holdtime'' --Selec hour
       END
    ELSE   
       BEGIN
		  SET @groupByClause = N''userId,login,year,month,day'' --Group by day
		  SET @selectClause = N''userId,login,CONVERT(varchar(4),year)+''''-''''+dbo.zeroCalendarPadding(CONVERT(varchar(2),month))+''''-''''+dbo.zeroCalendarPadding(CONVERT(varchar(2),day)) AS date,sum(mohTime) AS holdtime'' --Selec day
       END
    
   IF @campsId = N'''' AND @acdsId = N'''' 
       BEGIN
         SET @selectClause = N'' SELECT '' + @selectClause + N'' FROM '' --Add SELECT and FROM
         SET @innerSelectClause = N'' SELECT '' + @groupByClause  + N'',mohTime FROM '' --Use group by  columns and add mohTime
       END
   ELSE
       BEGIN                 
		 SET @groupByClause = N''type,id,description,'' + @groupByClause --also group by camp/acd id and description
         SET @selectClause = N'' SELECT type,id,description,''  + @selectClause + N'' FROM ''  --also select camp/acd id and description
       END 
   
   SET @groupByClause = N'' GROUP BY '' + @groupByClause + N'' ''
   	     

   IF @checkCamps = 1 AND @checkInbound = 1 
	     BEGIN
		    SET @applyUnion = N'' UNION ALL''
		 END
   
   IF @campsId = '''' AND @acdsId = '''' --Group result by agents
     BEGIN       	
	 	  	 	   
       SET @innerSql = N'' '' + @innerSelectClause + N'' [dbo].[holdViewDataOutbound] WHERE date BETWEEN @fechaInicio AND @fechaFin ''+ @agentsClause + @campsClause + N'' '' 			 
		+ '' UNION ALL''
		+ N'' '' + @innerSelectClause + N'' [dbo].[holdViewDataInbound] WHERE date BETWEEN @fechaInicio AND @fechaFin ''+ @agentsClause + @acdsClause + N'' ''
        
       SET @sql = @selectClause + N'' ( '' + @innerSql + N'' ) AS a '' + @groupByClause

     END
   ELSE --Group result by camps and acds
     BEGIN

	   IF @checkCamps = 1 
			BEGIN
				SET @campsSelect = N'' '' + @selectClause + N'' [dbo].[holdViewDataOutbound] WHERE date BETWEEN @fechaInicio AND @fechaFin ''+ @agentsClause + @campsClause + @groupByClause  + N'' '' 			
			END
  		 
	   IF @checkInbound = 1 
			BEGIN
				SET @inboundSelect = N'' '' + @selectClause + N'' [dbo].[holdViewDataInbound] WHERE date BETWEEN @fechaInicio AND @fechaFin ''+ @agentsClause + @acdsClause + @groupByClause  + N'' ''
			END	 
	 

	   SET @sql = @campsSelect
		+ @applyUnion
		+ @inboundSelect

     END
     
   EXEC sp_executesql @sql,@params,@fechaInicio,@fechaFin,@agentsId,@campsId,@acdsId    
END'
	
	EXEC(@Sql)

		set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCstoResumen]
@from AS smalldatetime,
@to AS smalldatetime
AS
declare @country as tinyInt
select @country = valor from ccSettings where setting_id = 104

-- Delete previous data in case of reprocess HLAS
DELETE ccGenOutCstoResumen WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCstoResumen (timegroup, cam_id, [user_id], provedor_id, tipoLlamada_id, amount, mins, costo)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, cam_id, [user_id], provedor_id, tipoLlamada_id 
	, COUNT(*)
	, SUM( mins)
	, SUM( costo )
FROM
(
	SELECT cal_inicio, cam_id, [user_id], provedor_id, tipoLlamada_id, CEILING((cal_tXfer + cal_tRing + cal_tDialog +1 ) / 60.0 ) as mins, costo
	FROM ccoCallsOut
	WHERE cal_inicio >= @from AND  cal_inicio < @to and provedor_id is not null and cal_manual in (0,2)

	-- Tambien las llamdas que fueron fax
	UNION ALL

	SELECT cco.fecha as fecha, cco.cam_id, 0, p.provedor_id, l.tipoLlamada_id, 1, t.MinutoUno as costo
	FROM ccoLogDials cco, ccoDialers cd, cstoProvedor p, cstoTarifa t, cstoTipoLlamada l
	WHERE 
	l.country_id = @country
	and cco.answerbit = 1 and cco.tiporesdial_id <> 1
	and cco.fecha >=  @from AND cco.fecha < @to
	and cco.puerto = cd.puerto
	and cd.provedor_id = p.provedor_id	
	and p.provedor_id = t.provedor_id
	and l.longitud = len(cco.telefono)
	and cco.telefono like l.prefijo
	and t.tipoLlamada_id = l.tipoLlamada_id
)x
GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), cam_id, [user_id], provedor_id, tipoLlamada_id'
	
	EXEC(@Sql)

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

------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC]
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
