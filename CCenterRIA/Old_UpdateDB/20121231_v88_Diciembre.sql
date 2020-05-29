/*
Autor: Raymundo Gonzalez
Fecha: 2012/12/31
Descripcion: 	
	Se agrega campo en la tabla ccCamps llamado surveyPctg para porcentaje de encuestas
	Se agrega campo monitored y se actualiza a 1 en la atabla ccSupervisorCam para monitoreo de campañas y acds
	Se crea la tabla ccPosicionEspecialidad para reporte de Amatech
	Se crea la tabla ccPosicionCamps para reporte de Amatech
	Se crea trigger trigPosicionEspecialidad en la tabla ccLogLogin para reporte de Amatech
	Se crea la tabla seriesAU para el plan de marcacion de Australia
	Se crea el SP ccsp_RIA_ConfigMonitoredCampAndAcd para guardar filtros de campañas y acds monitoreadas
	Se inserta registro en la tabla ccRIACat_Country para el plan de marcacion de Australia
	Se insertan registros en la tabla ccTimeZones para el plan de marcacion de Australia
	Se insertan registros en la tabla ccHorarioVerano para el plan de marcacion de Australia
	Se insertan registros en la tabla cstoTipoLlamada para el plan de marcacion de Australia
	Se insertan registros en la tabla ccTimeZoneArea para el plan de marcacion de Australia
	Se insertan registros en la tabla seriesAU para el plan de marcacion de Australia
	Se modifica el SP ccsp_RIAConfCamp para porcentaje de encuestas
	Se modifica el SP ccsp_RIAUpdateCamConfig para porcentaje de encuestas
	Se modifica el SP ccsp_AgentSetCallStatus para porcentaje de encuestas
	Se modifica el SP ccsp_DLRSaveDialResult para porcentaje de encuestas
	Se modifica el SP ccsp_InsertDNCList para eliminar registros encontrados en Lista Negra
	Se modifica el SP ccsp_Limpia para el plan de marcacion de Australia
	Se modifica el SP ccsp_OUTInsertaCallBack para recibir parametro de FechaDial con tipo de dato smalldatetime
	Se modifica el SP ccsp_RIAAgentGetDialMask para restringir llamadas en el plan de marcacion de Australia
	Se modifica el SP ccsp_RIALoadACDGroups para devolver atributo de monitoreo de acds
	Se modifica el SP ccsp_RIALoadCamps para devolver atributo de monitoreo de campañas
	Se modifica el SP ccsp_RIAManageWG para control de campañas y acds monitoreadas
	Se modifica el SP ccsp_RIAOUTInsertNewJOBS_WT_Camp para porcentaje de encuestas
	Se modifica el SP ccspADM_AniListLD para configuracion de ANI Local del plan de marcacion de Australia
	Se modifica la funcion Completa para el plan de marcacion de Australia
	Se modifica la funcion Completa_ListaNegra para el plan de marcacion de Australia
	Se modifica la funcion TelAni para configuracion de ANI Local del plan de marcacion de Australia
	Se modifica la funcion Verifica para el plan de marcacion de Australia
	Se modifica la funcion fnGetTimeZone para el plan de marcacion de Australia

Version requerida: 87
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '88'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @Sql='alter table ccCamps add surveyPctg tinyint not null default 100'
	
	EXEC(@Sql)

		set @Sql='alter table ccSupervisorCam
add monitored int default 1'

	EXEC(@Sql)

		set @Sql='update ccSupervisorCam
set monitored = 1'

	EXEC(@Sql)

		set @Sql='CREATE TABLE [dbo].[ccPosicionEspecialidad](
      [Inbound_id] [smallint] NULL,
      [User_id] [smallint] NULL,
      [Tipo] [tinyint] NULL,
      [Fecha] [datetime] NULL
) ON [PRIMARY]'

	EXEC(@Sql)

		set @Sql='CREATE TABLE [dbo].[ccPosicionCamps](
      [cam_id] [smallint] NULL,
      [User_id] [smallint] NULL,
      [Tipo] [tinyint] NULL,
      [Fecha] [datetime] NULL
) ON [PRIMARY]'

	EXEC(@Sql)

		set @Sql='CREATE TRIGGER [dbo].[trigPosicionEspecialidad] ON [dbo].[ccLogLogin]
	FOR INSERT
	AS
	insert into ccPosicionEspecialidad(Inbound_id,User_id,Tipo,Fecha)
		select c.inbound_id,i.user_id,i.TipoMov,getdate()
		from inserted i
		inner join ccinboundagentes c (nolock)
		on	c.user_id = i.user_id
		
		
	insert into ccPosicionCamps(cam_id,User_id,Tipo,Fecha)
		select c.cam_id,i.user_id,i.TipoMov,getdate()
		from inserted i
		inner join cccampsagente c (nolock)
		on	c.user_id = i.user_id'

	EXEC(@Sql)

		set @Sql='CREATE TABLE [dbo].[seriesAU](
	[Regiones] [nvarchar](max) NOT NULL,
	[LD] [varchar](2) NULL,
	[AreaCode] [varchar](2) NULL,
	[SerieInicio] [varchar](6) NULL,
	[SerieFin] [varchar](6) NULL,
	[TipoRed] [varchar](10) NULL,
	[Modalidad] [varchar](10) NULL
) ON [PRIMARY]'

	EXEC(@Sql)

		set @Sql='CREATE procedure [dbo].[ccsp_RIA_ConfigMonitoredCampAndAcd]
@option smallint,
@user_id smallint,
@cam_id varchar(1000),
@inbound_id varchar(1000)
as
set nocount on

if @option = 1
	begin
		if @cam_id <> ''''
			begin
				update ccSupervisorCam
				set monitored = 1
				where user_id = @user_id
				and tipo = 1

				update ccSupervisorCam
				set monitored = 0
				where cam_id not in (select value from fn_RIASplitDelimited(@cam_id,'',''))
				and tipo = 1
				and user_id = @user_id
			end
		else
			begin
				update ccSupervisorCam
				set monitored = 0
				where user_id = @user_id
				and tipo = 1
			end

		if @inbound_id <> ''''
			begin
				update ccSupervisorCam
				set monitored = 1
				where user_id = @user_id
				and tipo = 0
				
				update ccSupervisorCam
				set monitored = 0
				where cam_id not in (select value from fn_RIASplitDelimited(@inbound_id,'',''))
				and tipo = 0
				and user_id = @user_id
			end
		else
			begin
				update ccSupervisorCam
				set monitored = 0
				where user_id = @user_id
				and tipo = 0
			end
	
	end

set nocount off'
			
	EXEC(@Sql)

		set @Sql='insert into ccRIACat_Country
values(''Australia'',61,10,10)'

	EXEC(@Sql)

		set @Sql='insert into ccTimeZones values (268435456, ''UTC+6.5'',  6.5)
insert into ccTimeZones values (536870912, ''UTC+9.5'',  9.5)
insert into ccTimeZones values (1073741824, ''UTC+10.5'', 10.5)'

	EXEC(@Sql)

		set @Sql='insert into ccHorarioVerano values (''2011/10/02 02:00'', ''2012/04/01 03:00'', 9)
insert into ccHorarioVerano values (''2012/10/07 02:00'', ''2013/04/07 03:00'', 9)
insert into ccHorarioVerano values (''2013/10/06 02:00'', ''2014/04/06 03:00'', 9)
insert into ccHorarioVerano values (''2014/10/05 02:00'', ''2015/04/05 03:00'', 9)
insert into ccHorarioVerano values (''2015/10/04 02:00'', ''2016/04/03 03:00'', 9)
insert into ccHorarioVerano values (''2016/10/02 02:00'', ''2017/04/02 03:00'', 9)
insert into ccHorarioVerano values (''2017/10/01 02:00'', ''2018/04/01 03:00'', 9)
insert into ccHorarioVerano values (''2018/10/07 02:00'', ''2019/04/07 03:00'', 9)
insert into ccHorarioVerano values (''2019/10/06 02:00'', ''2020/04/05 03:00'', 9) 
insert into ccHorarioVerano values (''2020/10/04 02:00'', ''2021/04/04 03:00'', 9)'

	EXEC(@Sql)

		set @Sql='insert into cstoTipoLlamada values (9,1,''Local''      ,10,''%''    )
insert into cstoTipoLlamada values (9,2,''LD nacional'',10,''%''    )
insert into cstoTipoLlamada values (9,3,''LD inter''   ,0 ,''0011%'')
insert into cstoTipoLlamada values (9,4,''Cel''        ,10,''04%''  )'

	EXEC(@Sql)

		set @Sql='insert into ccTimeZoneArea values (9, ''02''  , rtrim (ltrim (''NSW - New South Wales      '')), 4194304  , 8388608  )
insert into ccTimeZoneArea values (9, ''03''  , rtrim (ltrim (''V - Victoria               '')), 4194304  , 8388608  )
insert into ccTimeZoneArea values (9, ''07''  , rtrim (ltrim (''Q - Queensland             '')), 4194304  , 4194304  )
insert into ccTimeZoneArea values (9, ''0825'', rtrim (ltrim (''SA - Berri                 '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0826'', rtrim (ltrim (''SA - Ceduna                '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0851'', rtrim (ltrim (''X - Christmas Island       '')), 524288   , 524288   )
insert into ccTimeZoneArea values (9, ''0852'', rtrim (ltrim (''WA - Perth                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0853'', rtrim (ltrim (''WA - Perth                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0854'', rtrim (ltrim (''WA - Perth                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0855'', rtrim (ltrim (''WA - Bullsbrook East       '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0858'', rtrim (ltrim (''WA - Albany                '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0860'', rtrim (ltrim (''WA - Bruce Rock            '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0861'', rtrim (ltrim (''WA - Perth                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0862'', rtrim (ltrim (''WA - Perth                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0863'', rtrim (ltrim (''WA - Perth                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0864'', rtrim (ltrim (''WA - Perth                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0865'', rtrim (ltrim (''WA - Perth                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0866'', rtrim (ltrim (''WA - Moora                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0867'', rtrim (ltrim (''WA - Bridgetown            '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0868'', rtrim (ltrim (''WA - Albany                '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0869'', rtrim (ltrim (''WA - Carnamah              '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0870'', rtrim (ltrim (''SA - Adelaide              '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0871'', rtrim (ltrim (''SA - Adelaide              '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0872'', rtrim (ltrim (''SA - Adelaide              '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0873'', rtrim (ltrim (''SA - Adelaide              '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0874'', rtrim (ltrim (''SA - Adelaide              '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0875'', rtrim (ltrim (''SA - Berri                 '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0876'', rtrim (ltrim (''SA - Ceduna                '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0877'', rtrim (ltrim (''SA - Bordertown            '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0878'', rtrim (ltrim (''SA - Balaklava             '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0879'', rtrim (ltrim (''NT - Alice Springs         '')), 134217730, 134217730)
insert into ccTimeZoneArea values (9, ''0880'', rtrim (ltrim (''WA - Broken Hill           '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0881'', rtrim (ltrim (''SA - Adelaide              '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0882'', rtrim (ltrim (''SA - Adelaide              '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0883'', rtrim (ltrim (''SA - Adelaide              '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0884'', rtrim (ltrim (''SA - Adelaide              '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0885'', rtrim (ltrim (''SA - Berri                 '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0886'', rtrim (ltrim (''SA - Ceduna                '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0887'', rtrim (ltrim (''SA - Bordertown            '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0888'', rtrim (ltrim (''SA - Balaklava             '')), 134217730, 134217731)
insert into ccTimeZoneArea values (9, ''0889'', rtrim (ltrim (''NT - Alice Springs         '')), 134217730, 134217730)
insert into ccTimeZoneArea values (9, ''0890'', rtrim (ltrim (''WA - Bruce Rock            '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0891'', rtrim (ltrim (''X - Christmas Island       '')), 524288   , 524288   )
insert into ccTimeZoneArea values (9, ''0892'', rtrim (ltrim (''WA - Perth                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0893'', rtrim (ltrim (''WA - Perth                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0894'', rtrim (ltrim (''WA - Perth                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0895'', rtrim (ltrim (''WA - Bullsbrook East       '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0896'', rtrim (ltrim (''WA - Moora                 '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0897'', rtrim (ltrim (''WA - Bridgetown            '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0898'', rtrim (ltrim (''WA - Albany                '')), 1048576  , 1048576  )
insert into ccTimeZoneArea values (9, ''0899'', rtrim (ltrim (''WA - Carnamah              '')), 1048576  , 1048576  )'

	EXEC(@Sql)

		set @Sql='insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''33'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''37'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''38'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay, Narrandera, Temora, Wagga Wagga, West Wyalong,''                                                 , ''02'', ''39'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''000000'', ''138999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''140000'', ''212999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''214000'', ''215999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''217000'', ''217999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''219000'', ''220999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''225000'', ''359999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''361000'', ''368999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''370000'', ''379999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''381000'', ''388999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''391000'', ''398999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''401000'', ''428999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''431000'', ''438999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''440000'', ''448999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''451000'', ''458999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''461000'', ''467999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''480000'', ''489999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''525000'', ''525999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''40'', ''888000'', ''889999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''41'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''000000'', ''048999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''050000'', ''081999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''106000'', ''108999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''200000'', ''387999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''390000'', ''397999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''420000'', ''432999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''437000'', ''459999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''500000'', ''589999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''600000'', ''641999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''670000'', ''689999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''710000'', ''770999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''830000'', ''879999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''888000'', ''889999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''910000'', ''931999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Wollongong, Campbelltown''                                                                                               , ''02'', ''42'', ''940000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''000000'', ''118999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''121000'', ''125999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''200000'', ''261999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''280000'', ''353999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''360000'', ''382999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''390000'', ''461999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''464000'', ''465999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''480000'', ''779999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''790000'', ''800999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''808000'', ''829999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''840000'', ''859999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''880000'', ''910999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''920000'', ''949999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''960000'', ''979999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Gosford''                                                                                                                , ''02'', ''43'', ''990000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''000000'', ''085999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''087000'', ''098999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''101000'', ''108999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''111000'', ''118999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''121000'', ''128999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''210000'', ''271999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''280000'', ''299999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''410000'', ''489999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''540000'', ''579999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''640000'', ''659999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''710000'', ''819999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''881000'', ''881999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''884000'', ''884999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moruya, Nowra''                                                                                                          , ''02'', ''44'', ''999000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Windsor''                                                                                                                , ''02'', ''45'', ''000000'', ''043999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Windsor''                                                                                                                , ''02'', ''45'', ''047000'', ''047999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Windsor''                                                                                                                , ''02'', ''45'', ''049000'', ''058999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Windsor''                                                                                                                , ''02'', ''45'', ''061000'', ''068999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Windsor''                                                                                                                , ''02'', ''45'', ''071000'', ''072999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Windsor''                                                                                                                , ''02'', ''45'', ''450000'', ''460999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Windsor''                                                                                                                , ''02'', ''45'', ''550000'', ''579999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Windsor''                                                                                                                , ''02'', ''45'', ''600000'', ''841999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Windsor''                                                                                                                , ''02'', ''45'', ''870000'', ''894999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''000000'', ''048999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''050000'', ''072999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''080000'', ''102999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''200000'', ''238999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''240000'', ''369999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''400000'', ''411999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''450000'', ''499999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''510000'', ''600999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''611000'', ''611999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''660000'', ''661999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''667000'', ''667999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''770000'', ''789999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''800000'', ''819999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Campbelltown''                                                                                                           , ''02'', ''46'', ''830000'', ''849999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Penrith''                                                                                                                , ''02'', ''47'', ''000000'', ''059999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Penrith''                                                                                                                , ''02'', ''47'', ''061000'', ''088999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Penrith''                                                                                                                , ''02'', ''47'', ''091000'', ''096999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Penrith''                                                                                                                , ''02'', ''47'', ''200000'', ''422999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Penrith''                                                                                                                , ''02'', ''47'', ''430000'', ''439999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Penrith''                                                                                                                , ''02'', ''47'', ''441000'', ''444999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Penrith''                                                                                                                , ''02'', ''47'', ''470000'', ''480999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Penrith''                                                                                                                , ''02'', ''47'', ''489000'', ''605999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Penrith''                                                                                                                , ''02'', ''47'', ''608000'', ''619999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Penrith''                                                                                                                , ''02'', ''47'', ''730000'', ''782999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Penrith''                                                                                                                , ''02'', ''47'', ''800000'', ''837999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Penrith''                                                                                                                , ''02'', ''47'', ''840000'', ''899999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''000000'', ''513999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''515000'', ''516999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''518000'', ''519999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''526000'', ''527999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''529000'', ''531999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''537000'', ''537999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''540000'', ''548999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''550000'', ''638999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''641000'', ''648999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''651000'', ''658999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''661000'', ''668999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''671000'', ''678999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''680000'', ''748999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''751000'', ''758999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''761000'', ''768999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''770000'', ''798999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''801000'', ''808999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''830000'', ''899999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''901000'', ''901999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bowral, Crookwell, Goulburn, Marulan''                                                                                   , ''02'', ''48'', ''997000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Newcastle''                                                                                                              , ''02'', ''49'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''50'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''51'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''52'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''003500'', ''003699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''003900'', ''004699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''005000'', ''005399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''005500'', ''005899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''006000'', ''006399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''006500'', ''006799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''007000'', ''007699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''008000'', ''008399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''008500'', ''008699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''009000'', ''009399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''009500'', ''009699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''010000'', ''010399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''010500'', ''010699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''011000'', ''011399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''011500'', ''011699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''012000'', ''012399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''012500'', ''012699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''013000'', ''013699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''014000'', ''014399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''014500'', ''014699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''015000'', ''015399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''015500'', ''015699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''016000'', ''016599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''017000'', ''017399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''017500'', ''017699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''018000'', ''018399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''018500'', ''018699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''019000'', ''019699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''020000'', ''020399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''020500'', ''020699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''021000'', ''021699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''022000'', ''022399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''022500'', ''022699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''023000'', ''023399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''023500'', ''023699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''024000'', ''024399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''024500'', ''024699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''025000'', ''025399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''025500'', ''025699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''026000'', ''026399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''026500'', ''026699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''027000'', ''027399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''027500'', ''027699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''028000'', ''028399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''028500'', ''028699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''029000'', ''029399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''029500'', ''029699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''030000'', ''030699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''031000'', ''178999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''181000'', ''183999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''221000'', ''221999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''223000'', ''223999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''53'', ''530000'', ''577999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''54'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''000000'', ''045999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''047000'', ''050999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''053000'', ''539990'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''064000'', ''064999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''067000'', ''067999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''074000'', ''078999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''081000'', ''081999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''084000'', ''084999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''087000'', ''158999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''161000'', ''168999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''171000'', ''178999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''181000'', ''188999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''191000'', ''198999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''201000'', ''208999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''211000'', ''218999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''221000'', ''228999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''231000'', ''238999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''240000'', ''258999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''260000'', ''269999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''271000'', ''278999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''281000'', ''288999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''291000'', ''298999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''301000'', ''308999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''311000'', ''318999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''321000'', ''328999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''331000'', ''331999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''500000'', ''558999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''560000'', ''564999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''900000'', ''919999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''921000'', ''928999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''930000'', ''939999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''941000'', ''943999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''55'', ''945000'', ''945999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''000000'', ''058999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''060000'', ''070999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''073000'', ''073999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''075000'', ''075999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''077000'', ''083999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''087000'', ''090999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''095000'', ''208999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''211000'', ''218999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''221000'', ''229999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''231000'', ''238999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''241000'', ''248999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''251000'', ''258999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''261000'', ''268999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''271000'', ''278999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''281000'', ''288999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''291000'', ''298999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''301000'', ''301999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''321000'', ''321999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''323000'', ''325999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''981000'', ''981999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''56'', ''990000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''000000'', ''000099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''000200'', ''000699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''000800'', ''001099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''001200'', ''001899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''002000'', ''002399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''002500'', ''002899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''003000'', ''003399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''003500'', ''004399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''004500'', ''004899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''005000'', ''005399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''005500'', ''005899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''006000'', ''006399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''006500'', ''006899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''007000'', ''007399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''007500'', ''007699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''007800'', ''008099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''008200'', ''008699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''008800'', ''009499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''009600'', ''009799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''010000'', ''010499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''010600'', ''010799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''011000'', ''011499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''011600'', ''011799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''012000'', ''012799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''013000'', ''013499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''013600'', ''013799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''014000'', ''014799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''015000'', ''015699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''016000'', ''112499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''112600'', ''112799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''113000'', ''327999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''750000'', ''766999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''944000'', ''948999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''57'', ''951000'', ''951999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''58'', ''000000'', ''158999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''58'', ''160000'', ''166999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''58'', ''170000'', ''199999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''58'', ''201000'', ''203999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''58'', ''206000'', ''217999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''58'', ''220000'', ''233999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''58'', ''349000'', ''349999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''58'', ''520000'', ''522999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''58'', ''579000'', ''579999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''58'', ''585800'', ''585899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''58'', ''810000'', ''819999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''59'', ''000000'', ''239999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''59'', ''241000'', ''255999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''59'', ''257000'', ''257999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''59'', ''320000'', ''339999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''59'', ''423000'', ''423999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''59'', ''590000'', ''633999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''59'', ''700000'', ''709999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''59'', ''717000'', ''719999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''59'', ''761000'', ''761999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''59'', ''763000'', ''763999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''59'', ''999900'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''000000'', ''462999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''468000'', ''530999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''536000'', ''536999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''539000'', ''539999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''548000'', ''639999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''641000'', ''648999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''650000'', ''659999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''661000'', ''679999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''681000'', ''689999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''691000'', ''698999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''700000'', ''819999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''821000'', ''828999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''831000'', ''838999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''841000'', ''848999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''851000'', ''858999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albury, Corryong''                                                                                                       , ''02'', ''60'', ''861000'', ''868999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''000000'', ''408999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''411000'', ''449999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''451000'', ''458999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''460000'', ''479999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''481000'', ''488999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''491000'', ''492999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''494000'', ''498999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''501000'', ''504999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''510000'', ''519999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''525000'', ''532999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''537000'', ''538999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''540000'', ''588999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''591000'', ''598999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''600000'', ''789999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''791000'', ''792999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''800000'', ''820999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''840000'', ''859999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''883000'', ''889999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''61'', ''940000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Canberra''                                                                                                               , ''02'', ''62'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''000000'', ''019599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''020000'', ''029399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''029500'', ''029699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''030000'', ''039399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''039500'', ''039699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''040000'', ''049399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''049500'', ''049699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''050000'', ''069399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''069500'', ''069699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''070000'', ''079399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''079500'', ''079699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''080000'', ''089399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''089500'', ''089699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''090000'', ''099399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''099500'', ''099699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''100000'', ''119399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''119500'', ''119699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''120000'', ''129399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''129500'', ''129699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''130000'', ''139399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''139500'', ''139699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''140000'', ''149899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''150000'', ''159399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''159500'', ''159699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''160000'', ''169399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''169500'', ''169699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''170000'', ''179399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''179500'', ''179699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''180000'', ''189399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''189500'', ''189699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''190000'', ''199399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''199500'', ''199699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''200000'', ''200399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''200500'', ''200699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''201000'', ''219399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''219500'', ''219699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''220000'', ''229399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''229500'', ''229699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''230000'', ''810399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''810500'', ''810699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''811000'', ''939999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''941000'', ''988399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''988500'', ''988699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''989000'', ''989399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''989500'', ''989699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''990000'', ''990799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''991000'', ''991399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''991500'', ''991699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''992000'', ''992699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''993000'', ''993399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''993500'', ''993699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''994000'', ''994399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''994500'', ''994699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''995000'', ''995699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''996000'', ''996399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''996500'', ''996699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''997000'', ''997699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''998000'', ''998399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''998500'', ''998699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bathurst, Cowra, Lithgow, Mudgee, Orange, Rylstone, Young''                                                              , ''02'', ''63'', ''999000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''000000'', ''246999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''248000'', ''249999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''254000'', ''254999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''261000'', ''261999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''265000'', ''265999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''270000'', ''318999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''321000'', ''328999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''331000'', ''338999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''341000'', ''348999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''351000'', ''358999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''361000'', ''368999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''371000'', ''378999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''381000'', ''385999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''387000'', ''388999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''391000'', ''396999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''403000'', ''403999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''405000'', ''406999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''408000'', ''408999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''411000'', ''418999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''421000'', ''425999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''440000'', ''455999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''469000'', ''469999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''480000'', ''601999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''890000'', ''898999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bega, Cooma''                                                                                                            , ''02'', ''64'', ''900000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Kempsey, Lord Howe Island, Muswellbrook, Singleton, Taree, Wauchope''                                                    , ''02'', ''65'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Casino, Coffs Harbour, Grafton, Kyogle, Lismore, Murwillumbah''                                                          , ''02'', ''66'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''000000'', ''110599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''110800'', ''110899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''111000'', ''111699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''112000'', ''112699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''113000'', ''113699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''114000'', ''114699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''115000'', ''115399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''115500'', ''115699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''116000'', ''116699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''117000'', ''117699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''117800'', ''117899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''118000'', ''118099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''118200'', ''118699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''118800'', ''118899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''119000'', ''119399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''119500'', ''119699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''120000'', ''244699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''245000'', ''245699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''246000'', ''246699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''247000'', ''310399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''310500'', ''310699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''311000'', ''311399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''311500'', ''311699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''312000'', ''312699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''313000'', ''313099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''313200'', ''313699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''313800'', ''313899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''314000'', ''314099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''314200'', ''314899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''315000'', ''315399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''315500'', ''315699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''315800'', ''316099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''316200'', ''316699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''316800'', ''317399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''317500'', ''317699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''317800'', ''318399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''318500'', ''318699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''318800'', ''319099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''319200'', ''319699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''319800'', ''386099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''386200'', ''386699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''386800'', ''392699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''393000'', ''486699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''486800'', ''486899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''487000'', ''487699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''487800'', ''487899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''488000'', ''488699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''488800'', ''488899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''489000'', ''489699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''489800'', ''489899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''490000'', ''580699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''580800'', ''580899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''581000'', ''581699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''582000'', ''582699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''583000'', ''583699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''584000'', ''584699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''585000'', ''585699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''586000'', ''586699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''587000'', ''587699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''588000'', ''588499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''588600'', ''588799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''589000'', ''589499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''589600'', ''589799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''590000'', ''704499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''704600'', ''704799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''705000'', ''800499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''800600'', ''800799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''801000'', ''805499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''805600'', ''805799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''806000'', ''809899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''810000'', ''813799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''814000'', ''814499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''814600'', ''814799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''815000'', ''818499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''818600'', ''818799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''819000'', ''819499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''819600'', ''819899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''820000'', ''820499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''820600'', ''820799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''821000'', ''823499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''823600'', ''823799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''824000'', ''824499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''824600'', ''824799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''825000'', ''826499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''826600'', ''000899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''827000'', ''840499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''840600'', ''840799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''841000'', ''841499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''841600'', ''841799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''842000'', ''842399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''842500'', ''842699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''842800'', ''843399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''843500'', ''843899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''844000'', ''844099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''844200'', ''844699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''844800'', ''845399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''845500'', ''845899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''846000'', ''846399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''846500'', ''846899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''847000'', ''847799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''848000'', ''848399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''848500'', ''848899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''849000'', ''849399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''849500'', ''849899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''850000'', ''862399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''862500'', ''862699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''862800'', ''863399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''863500'', ''863699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''863800'', ''864399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''864500'', ''864899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''865000'', ''865399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''865500'', ''865899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''866000'', ''866099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''866200'', ''866699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''866800'', ''867399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''867500'', ''867699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''867800'', ''868399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''868500'', ''868899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''869000'', ''869499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''869600'', ''869799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''870000'', ''940499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''940600'', ''940799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''941000'', ''941499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''941600'', ''941799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''942000'', ''942499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''942600'', ''942799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''943000'', ''943799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''944000'', ''945499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''945600'', ''945799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''946000'', ''946499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''946600'', ''946799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''947000'', ''947499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''947600'', ''947799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''948000'', ''948499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''948600'', ''948799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''949000'', ''949099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''949200'', ''949699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''949800'', ''993399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''993500'', ''993699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Armidale, Barraba, Glen Innes, Gunnedah, Inverell, Moree , Narrabri, Tamworth''                                          , ''02'', ''67'', ''993800'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''000000'', ''080399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''080500'', ''080899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''081000'', ''081099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''081200'', ''081599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''081800'', ''081899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''082000'', ''082699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''082800'', ''082899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''083000'', ''083099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''083200'', ''083699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''083800'', ''083899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''084000'', ''084599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''084800'', ''084899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''085000'', ''085099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''085200'', ''085699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''085800'', ''085899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''086000'', ''086099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''086200'', ''086699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''086800'', ''086899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''087000'', ''087099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''087200'', ''087699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''087800'', ''087899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''088000'', ''088699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''088800'', ''088899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''089000'', ''089099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''089200'', ''089699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''089800'', ''089899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''090000'', ''210099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''210200'', ''210699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''210800'', ''210899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''211000'', ''211399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''211500'', ''211699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''211800'', ''211899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''212000'', ''212099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''212200'', ''212699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''212800'', ''212899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''213000'', ''213099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''213200'', ''213699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''213800'', ''213899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''214000'', ''214099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''214200'', ''214699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''214800'', ''214899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''215000'', ''215399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''215500'', ''215699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''215800'', ''215899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''216000'', ''216099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''216200'', ''216699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''216800'', ''216899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''217000'', ''217099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''217200'', ''217699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''217800'', ''217899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''218000'', ''218099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''218200'', ''218699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''218800'', ''218899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''219000'', ''219099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''219200'', ''219699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''219800'', ''219899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''220000'', ''303399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''303500'', ''303699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''303800'', ''303899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''304000'', ''312099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''312200'', ''312699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''312800'', ''312899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''313000'', ''313099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''313200'', ''313699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''313800'', ''313899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''314000'', ''314099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''314200'', ''314699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''314800'', ''314899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''315000'', ''315399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''315500'', ''315699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''315800'', ''315899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''316000'', ''316099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''316200'', ''316699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''316800'', ''316899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''317000'', ''317099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''317200'', ''317699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''317800'', ''317899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''318000'', ''318399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''318500'', ''318699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''318800'', ''318899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''319000'', ''319099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''319200'', ''319699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''319800'', ''319899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''320000'', ''340099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''340200'', ''340699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''340800'', ''340899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''341000'', ''341099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''341200'', ''341699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''341800'', ''341899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''342000'', ''342099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''342200'', ''342699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''342800'', ''342899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''343000'', ''343099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''343200'', ''343699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''343800'', ''343899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''344000'', ''344399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''344500'', ''344699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''345000'', ''345399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''345500'', ''345699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''346000'', ''346399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''346500'', ''346699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''347000'', ''348999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''350000'', ''360399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''360500'', ''360699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''361000'', ''368699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''369000'', ''369399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''369500'', ''369699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''370000'', ''370399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''370500'', ''370699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''371000'', ''371599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''372000'', ''372399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''372500'', ''372699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''373000'', ''374399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''374500'', ''374699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''375000'', ''375699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''376000'', ''376399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''376500'', ''376699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''377000'', ''377399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''377500'', ''377699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''378000'', ''378399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''378500'', ''378699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''379000'', ''379399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''379500'', ''379699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''380000'', ''394399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''394500'', ''394699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''395000'', ''395399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''395500'', ''395699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''396000'', ''396399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''396500'', ''396699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''397000'', ''432399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''432500'', ''432699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''433000'', ''433399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''433500'', ''433699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''433800'', ''433899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''434000'', ''456099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''456200'', ''456699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''456800'', ''456899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''457000'', ''457399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''457500'', ''457699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''458000'', ''458399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''458500'', ''458699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''459000'', ''490399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''490500'', ''490699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''491000'', ''493399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''493500'', ''493699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''494000'', ''554399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''554500'', ''554699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''554800'', ''554899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''555000'', ''555399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''555500'', ''555699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''556000'', ''556399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''556500'', ''556699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''557000'', ''557099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''557200'', ''557699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''557800'', ''557899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''558000'', ''558099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''558200'', ''558699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''558800'', ''558899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''559000'', ''559399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''559500'', ''559699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''560000'', ''564399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''564500'', ''564699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''565000'', ''565399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''565500'', ''565699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''566000'', ''566399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''566500'', ''566699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''567000'', ''567699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''567800'', ''567899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''568000'', ''568099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''568200'', ''568699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''568800'', ''568899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''569000'', ''569399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''569500'', ''569699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''569800'', ''569899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''570000'', ''577699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''578000'', ''578399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''578500'', ''578699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''579000'', ''579099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''579200'', ''579699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''579800'', ''579899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''580000'', ''580099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''580200'', ''580699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''580800'', ''580899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''581000'', ''581099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''581200'', ''581699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''581800'', ''581899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''582000'', ''582099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''582200'', ''582699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''582800'', ''582899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''583000'', ''583099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''583200'', ''583699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''583800'', ''583899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''584000'', ''584099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''584200'', ''584699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''584800'', ''584899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''585000'', ''585399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''585500'', ''585699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''585800'', ''585899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''586000'', ''586099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''586200'', ''586699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''586800'', ''586899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''587000'', ''587099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''587200'', ''587699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''587800'', ''587899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''588000'', ''588099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''588200'', ''588699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''588800'', ''588899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''589000'', ''589399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''589500'', ''589699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''590000'', ''650399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''650500'', ''650699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''651000'', ''651399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''651500'', ''651699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''652000'', ''654399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''654500'', ''654699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''655000'', ''655799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''656000'', ''656399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''656500'', ''656699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''657000'', ''657099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''657200'', ''657699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''657800'', ''657899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''658000'', ''658099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''658200'', ''658699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''658800'', ''658899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''659000'', ''659099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''659200'', ''659699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''659800'', ''659899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''660000'', ''665699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''665800'', ''665899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''666000'', ''666399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''666500'', ''666699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''666800'', ''666899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''667000'', ''667399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''667500'', ''667699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''668000'', ''668399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''668500'', ''668699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''668800'', ''668899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''669000'', ''669099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''669200'', ''669699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''669800'', ''669899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bourke, Condoblin, Coonamble, Dubbo, Forbes, Moree, Nyngan, Parkes, Wellington''                                         , ''02'', ''68'', ''670000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''000000'', ''198599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''198700'', ''198799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''199000'', ''199399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''199500'', ''199699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''200000'', ''340399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''340500'', ''340699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''341000'', ''341399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''341500'', ''341699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''342000'', ''350399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''350500'', ''350699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''351000'', ''351399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''351500'', ''351699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''352000'', ''352399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''352500'', ''352699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''353000'', ''353399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''353500'', ''353699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''354000'', ''354799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''355000'', ''355799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''356000'', ''356399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''356500'', ''356699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''357000'', ''357399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''357500'', ''357699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''358000'', ''358399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''358500'', ''358699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''359000'', ''359399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''359500'', ''359699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''360000'', ''456399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''456500'', ''456699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''457000'', ''457399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''457500'', ''457699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''458000'', ''458399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''458500'', ''458699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''459000'', ''459699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''460000'', ''460399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''460500'', ''460699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''461000'', ''463399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''463500'', ''463699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''464000'', ''496399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''496500'', ''496699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''497000'', ''497399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''497500'', ''497699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''498000'', ''498399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''498500'', ''498699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''499000'', ''499399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''499500'', ''499699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''500000'', ''520399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''520500'', ''520699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''521000'', ''521599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''522000'', ''522399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''522500'', ''522699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''523000'', ''523399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''523500'', ''523699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''524000'', ''524399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''524500'', ''524699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''525000'', ''525399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''525500'', ''525699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''526000'', ''526399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''526500'', ''526699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''527000'', ''527399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''527500'', ''527699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''528000'', ''528399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''528500'', ''528699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''529000'', ''529399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''529500'', ''529699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''530000'', ''570399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''570500'', ''570699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''571000'', ''571399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''571500'', ''571699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''572000'', ''572599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''573000'', ''573399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''573500'', ''573699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''574000'', ''574399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''574500'', ''574699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''575000'', ''575399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''575500'', ''575699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''576000'', ''576399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''576500'', ''576699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''577000'', ''577399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''577500'', ''577699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''578000'', ''578399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''578500'', ''578699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''579000'', ''579399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''579500'', ''579699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''580000'', ''604399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''604500'', ''604699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''605000'', ''733399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''733500'', ''733699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''734000'', ''734299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''734400'', ''734699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''734900'', ''735399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''735500'', ''735699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''736000'', ''736399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''736500'', ''736699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''737000'', ''742399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''742500'', ''742699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''743000'', ''744399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''744500'', ''744699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''745000'', ''745399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''745500'', ''745699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''746000'', ''746399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''746500'', ''746699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''747000'', ''747699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''748000'', ''748399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''748500'', ''748699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''749000'', ''749399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''749500'', ''749699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''750000'', ''750399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''750500'', ''750699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''751000'', ''751399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''751500'', ''751699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''752000'', ''760699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''761000'', ''761399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''761500'', ''761699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''762000'', ''765699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''766000'', ''766399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''766500'', ''766699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''767000'', ''767399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''767500'', ''767699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''768000'', ''768399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''768500'', ''768699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''769000'', ''769399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''769500'', ''769699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''770000'', ''784399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''784500'', ''784699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''785000'', ''785399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''785500'', ''785699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''786000'', ''786399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''786500'', ''786699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''787000'', ''787399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''787500'', ''787699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''788000'', ''788699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''789000'', ''789399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''789500'', ''789699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''790000'', ''804399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''804500'', ''804699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''805000'', ''805699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''806000'', ''806399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''806500'', ''806699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''807000'', ''820399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''820500'', ''820699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''821000'', ''833999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''835000'', ''835399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''835500'', ''835699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''836000'', ''836399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''836500'', ''836699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''837000'', ''837399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''837500'', ''837699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''838000'', ''838399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''838500'', ''838699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''839000'', ''839699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''840000'', ''892399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''892500'', ''892699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''893000'', ''893399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''893500'', ''893699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''894000'', ''894399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''894500'', ''894699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''895000'', ''904399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''904500'', ''904699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''905000'', ''910399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''910500'', ''910699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''911000'', ''955399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''955500'', ''955699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''956000'', ''956399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''956500'', ''956699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''957000'', ''957699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''958000'', ''958399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''958500'', ''958699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''959000'', ''959399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''959500'', ''959699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelong, Griffith, Hay,  Narrandera, Temora, Wagga Wagga, West Wyalong''                                                 , ''02'', ''69'', ''960000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''72'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''73'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''74'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''75'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''76'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''77'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''78'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''79'', ''002000'', ''021999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''80'', ''000000'', ''157999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''80'', ''160000'', ''399999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''80'', ''445000'', ''449999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''80'', ''600000'', ''749999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''80'', ''760000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''81'', ''000000'', ''029999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''81'', ''031000'', ''039999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''81'', ''041000'', ''042999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''81'', ''013000'', ''188999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''81'', ''019000'', ''239999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''81'', ''088000'', ''899999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''81'', ''097000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''82'', ''000000'', ''609999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''82'', ''611000'', ''611999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''82'', ''614000'', ''614999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''82'', ''620000'', ''690999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''82'', ''700000'', ''789999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''82'', ''800000'', ''829999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''82'', ''840000'', ''849999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''82'', ''860000'', ''869999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''82'', ''880000'', ''899999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''82'', ''920000'', ''939999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''82'', ''950000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''000000'', ''104999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''120000'', ''149999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''230000'', ''259999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''320000'', ''409999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''440000'', ''479999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''530000'', ''569999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''620000'', ''629999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''720000'', ''749999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''820000'', ''839999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''880000'', ''889999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''940000'', ''949999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''960000'', ''969999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''83'', ''990000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''84'', ''000000'', ''058999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''84'', ''060000'', ''168999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''84'', ''171000'', ''178999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''84'', ''220000'', ''269999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''84'', ''360000'', ''409999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''84'', ''430000'', ''489999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''84'', ''560000'', ''599999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''84'', ''670000'', ''679999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''84'', ''740000'', ''749999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''84'', ''840000'', ''849999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''84'', ''880000'', ''889999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''84'', ''950000'', ''959999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''000000'', ''188999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''190000'', ''199999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''201000'', ''206999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''210000'', ''259999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''350000'', ''369999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''390000'', ''399999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''430000'', ''459999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''480000'', ''489999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''550000'', ''590999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''650000'', ''815999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''820000'', ''889999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''940000'', ''969999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''85'', ''990000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''000000'', ''078999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''081000'', ''087999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''220000'', ''289999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''330000'', ''339999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''440000'', ''449999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''500000'', ''519999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''600000'', ''604999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''609000'', ''624999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''629000'', ''629999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''654000'', ''699999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''766000'', ''767999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''770000'', ''789999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''86'', ''880000'', ''889999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''87'', ''000000'', ''345999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''87'', ''350000'', ''399999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''87'', ''410000'', ''419999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''87'', ''450000'', ''470999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''87'', ''478000'', ''478999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''87'', ''480000'', ''489999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''87'', ''494000'', ''496999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''87'', ''520000'', ''679999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''87'', ''710000'', ''719999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''87'', ''740000'', ''789999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''87'', ''810000'', ''909999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''87'', ''950000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''88'', ''000000'', ''565999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''88'', ''570000'', ''909999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''88'', ''920000'', ''969999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''88'', ''980000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''89'', ''000000'', ''198999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''89'', ''200000'', ''240999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''89'', ''250000'', ''262999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''89'', ''340000'', ''379999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''89'', ''550000'', ''669999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''89'', ''680000'', ''749999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''89'', ''760000'', ''789999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''89'', ''800000'', ''809999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''89'', ''850000'', ''899999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''89'', ''980000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''90'', ''000000'', ''469999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''90'', ''780000'', ''902999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''90'', ''910000'', ''929999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''90'', ''980000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''91'', ''000000'', ''019999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''91'', ''110000'', ''209999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''91'', ''250000'', ''269999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''91'', ''300000'', ''309999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''91'', ''440000'', ''449999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''91'', ''460000'', ''469999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''91'', ''500000'', ''539999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''91'', ''810000'', ''819999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''91'', ''860000'', ''869999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''91'', ''880000'', ''889999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''91'', ''910000'', ''919999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''91'', ''990000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''92'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''93'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''94'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''95'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''96'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''97'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''98'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Sydney''                                                                                                                 , ''02'', ''99'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Colac- Geelong''                                                                                                         , ''03'', ''32'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Gisborne- Nhill''                                                                    , ''03'', ''33'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''34'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''000000'', ''010899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''011000'', ''011999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''012100'', ''012899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''013100'', ''013899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''014100'', ''014899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''015100'', ''015899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''016100'', ''016899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''017100'', ''017899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''018100'', ''018899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''019100'', ''019899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''020100'', ''020899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''021100'', ''021899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''022100'', ''022899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''023100'', ''023899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''024100'', ''024899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''025100'', ''025899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''026100'', ''026899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''027100'', ''027199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''40'', ''040400'', ''040799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''100000'', ''108899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''109100'', ''109199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''110600'', ''110799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''111000'', ''111199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''111300'', ''111399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''112000'', ''112099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''112500'', ''112599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''112700'', ''114899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''115100'', ''115899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''116100'', ''116899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''117100'', ''117899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''118100'', ''118899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''119100'', ''119899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''120100'', ''120899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''121100'', ''121899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''122100'', ''122899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''123100'', ''123899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''124100'', ''124899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''125100'', ''125899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''126100'', ''126899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''127100'', ''127899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''128100'', ''128799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''141100'', ''141199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''41'', ''141400'', ''141599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geelong- Colac''                                                                                                         , ''03'', ''42'', ''200000'', ''209999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geelong- Colac''                                                                                                         , ''03'', ''42'', ''210100'', ''210899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geelong- Colac''                                                                                                         , ''03'', ''42'', ''211100'', ''211899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geelong- Colac''                                                                                                         , ''03'', ''42'', ''212100'', ''212899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geelong- Colac''                                                                                                         , ''03'', ''42'', ''213100'', ''213899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geelong- Colac''                                                                                                         , ''03'', ''42'', ''214100'', ''214899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geelong- Colac''                                                                                                         , ''03'', ''42'', ''215000'', ''216899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geelong- Colac''                                                                                                         , ''03'', ''42'', ''217100'', ''217899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geelong- Colac''                                                                                                         , ''03'', ''42'', ''218100'', ''218899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geelong- Colac''                                                                                                         , ''03'', ''42'', ''242400'', ''243999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geelong- Colac''                                                                                                         , ''03'', ''42'', ''245000'', ''245999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton - Nhill''                                                                             , ''03'', ''43'', ''300000'', ''309899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton - Nhill''                                                                             , ''03'', ''43'', ''310100'', ''310199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton - Nhill''                                                                             , ''03'', ''43'', ''313200'', ''313499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton - Nhill''                                                                             , ''03'', ''43'', ''333000'', ''334299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton - Nhill''                                                                             , ''03'', ''43'', ''342900'', ''344399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton - Nhill''                                                                             , ''03'', ''43'', ''367700'', ''368299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton - Nhill''                                                                             , ''03'', ''43'', ''373000'', ''373099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''44'', ''400000'', ''410899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''44'', ''411200'', ''411299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''44'', ''416100'', ''416399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''44'', ''432200'', ''432299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''44'', ''433000'', ''435999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''44'', ''436100'', ''436199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''44'', ''444000'', ''444499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''44'', ''444550'', ''444559'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''44'', ''444600'', ''444699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''45'', ''500000'', ''505499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''47'', ''700100'', ''700599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''48'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''49'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''000000'', ''048699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''048800'', ''051899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''052000'', ''056399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''060000'', ''064899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''065000'', ''065899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''066000'', ''069999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''070100'', ''071999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''072600'', ''073199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''074600'', ''074999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''077100'', ''077299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''078100'', ''078299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''079100'', ''079299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''081200'', ''081399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''081500'', ''081699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''082300'', ''082499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''083200'', ''083899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''084100'', ''084299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''085300'', ''085499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''091000'', ''091499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''091700'', ''091799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''092100'', ''092399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''093100'', ''093299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''093600'', ''093799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''094000'', ''094299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''094500'', ''094699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''095100'', ''095299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''095600'', ''095799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Balranald- Hopetoun- Mildura- Ouyen- Swan Hill''                                                                         , ''03'', ''50'', ''099000'', ''099999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''100000'', ''162999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''163100'', ''163899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''164000'', ''165499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''165600'', ''166899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''167000'', ''167899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''168000'', ''168899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''169100'', ''169399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''169500'', ''169699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''171100'', ''171199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''172100'', ''184199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''185000'', ''185199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''186000'', ''186199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''187000'', ''188699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''188800'', ''189299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''190000'', ''190999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''191500'', ''191599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''191800'', ''191999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''192300'', ''192599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''193000'', ''194299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''194900'', ''194999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''195500'', ''195699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''196600'', ''196699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''197700'', ''197899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''198100'', ''198299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bairnsdale- Morwell- Sale''                                                                                              , ''03'', ''51'', ''198700'', ''199499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Colac- Geelong''                                                                                                         , ''03'', ''52'', ''200000'', ''299999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''300000'', ''316279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316300'', ''316339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316350'', ''316379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316400'', ''316439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316450'', ''316479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316500'', ''316539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316550'', ''316579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316600'', ''316639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316650'', ''316679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316700'', ''316779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316800'', ''316839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316850'', ''316879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316900'', ''316939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''316950'', ''316979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317000'', ''317039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317050'', ''317079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317100'', ''317139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317150'', ''317179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317200'', ''317239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317250'', ''317279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317300'', ''317339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317350'', ''317379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317400'', ''317439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317450'', ''317479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317500'', ''317539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317550'', ''317579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317600'', ''317679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317700'', ''317749'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317800'', ''317879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''317900'', ''317979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318000'', ''318089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318100'', ''318179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318200'', ''318239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318250'', ''318279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318300'', ''318379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318400'', ''318439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318450'', ''318479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318500'', ''318589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318600'', ''318679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318700'', ''318739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318750'', ''318779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318800'', ''318839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318850'', ''318879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318900'', ''318939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''318950'', ''318979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319000'', ''319039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319050'', ''319079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319100'', ''319139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319150'', ''319179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319200'', ''319239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319250'', ''319279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319300'', ''319339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319350'', ''319379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319400'', ''319439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319450'', ''319479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319500'', ''319539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319550'', ''319579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319600'', ''319639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319650'', ''319679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319700'', ''319779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319800'', ''319839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319850'', ''319879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319900'', ''319939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''319950'', ''319979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''320000'', ''322039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322050'', ''322079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322100'', ''322139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322150'', ''322179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322200'', ''322239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322250'', ''322279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322300'', ''322379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322400'', ''322639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322650'', ''322679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322700'', ''322779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322800'', ''322839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322850'', ''322879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322900'', ''322939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''322950'', ''322979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323000'', ''323069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323100'', ''323169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323200'', ''323269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323300'', ''323369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323400'', ''323439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323450'', ''323479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323500'', ''323539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323550'', ''323579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323600'', ''323639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323650'', ''323679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323700'', ''323779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323800'', ''323839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323850'', ''323879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323900'', ''323939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''323950'', ''323979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''324000'', ''324039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''324050'', ''324079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''324100'', ''324139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''324150'', ''324179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''324200'', ''379899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''380000'', ''382999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''383100'', ''384099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''384200'', ''384499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''384600'', ''384899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''385000'', ''387299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''387400'', ''387899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''388000'', ''389299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''389400'', ''390099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''390200'', ''392099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ararat- Ballarat- Horsham- Kyneton- Nhill''                                                                              , ''03'', ''53'', ''392200'', ''399999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''400000'', ''411039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''411080'', ''411089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''411100'', ''420089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''420100'', ''420189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''420200'', ''420289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''420300'', ''420389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''420400'', ''420479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''420500'', ''420579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''420600'', ''421479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''421500'', ''421879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''421900'', ''422479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''422500'', ''422579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''422600'', ''423079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''423100'', ''423169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''423200'', ''423679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''423700'', ''423879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''423900'', ''425079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''425100'', ''425179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''425200'', ''425679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''425700'', ''425779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''425900'', ''425979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''426000'', ''426079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''426100'', ''426579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''426600'', ''426679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''426700'', ''426779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''426800'', ''426879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''426900'', ''426979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''427000'', ''427679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''427700'', ''427769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''427800'', ''450079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''450100'', ''450179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''450200'', ''450279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''450300'', ''452379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''452400'', ''452479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''452500'', ''452579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''452600'', ''452679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''452700'', ''452779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''452800'', ''452879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''452900'', ''452979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''453000'', ''459379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''459400'', ''459579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''459600'', ''459679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''459700'', ''459879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''459900'', ''459979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''460000'', ''460049'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''460100'', ''460159'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''460200'', ''460269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''460300'', ''460669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''460700'', ''460769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''460800'', ''460869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''460900'', ''460979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''461000'', ''462079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''462100'', ''462379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''462400'', ''462479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''462500'', ''462569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''462600'', ''462679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''462700'', ''462779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''462800'', ''462879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''462900'', ''462969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''463000'', ''463079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''463100'', ''463379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''463400'', ''463479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''463500'', ''467599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''467700'', ''468999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''469100'', ''482899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''483000'', ''485999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''486100'', ''487999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''488100'', ''489599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''489700'', ''496079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''496100'', ''497079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''497100'', ''497499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''497600'', ''497899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''498000'', ''499599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bendigo- Charlton- Echuca- Kerang- Kyneton- Maryborough''                                                                , ''03'', ''54'', ''499700'', ''499999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''500000'', ''534939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''534950'', ''534979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535000'', ''535039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535050'', ''535079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535100'', ''535169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535200'', ''535269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535300'', ''535339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535350'', ''535369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535400'', ''535439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535450'', ''535469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535500'', ''535539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535550'', ''535569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535600'', ''535639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535650'', ''535669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535700'', ''535739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535750'', ''535769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535800'', ''535839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535850'', ''535869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535900'', ''535939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''535950'', ''535969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536000'', ''536069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536100'', ''536179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536200'', ''536239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536250'', ''536269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536300'', ''536339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536350'', ''536369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536400'', ''536439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536450'', ''536469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536500'', ''536539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536550'', ''536569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536600'', ''536639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536650'', ''536669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536700'', ''536739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536750'', ''536769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536800'', ''536839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536850'', ''536869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''536900'', ''536969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537000'', ''537039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537050'', ''537069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537100'', ''537139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537150'', ''537169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537200'', ''537239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537250'', ''537269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537300'', ''537339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537350'', ''537369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537400'', ''537439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537450'', ''537469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537500'', ''537539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537550'', ''537569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537600'', ''537639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537650'', ''537669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537700'', ''537739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537750'', ''537769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537800'', ''537839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537850'', ''537869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537900'', ''537959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''537990'', ''538039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538050'', ''538069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538100'', ''538139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538150'', ''538169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538200'', ''538239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538250'', ''538269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538300'', ''538339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538350'', ''538369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538400'', ''538439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538450'', ''538469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538500'', ''538539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538550'', ''538569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538600'', ''538639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538650'', ''538669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538700'', ''538739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538750'', ''538769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538800'', ''538839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538850'', ''538869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538900'', ''538939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''538950'', ''538969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539000'', ''539069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539100'', ''539139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539150'', ''539169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539200'', ''539269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539300'', ''539339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539350'', ''539369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539400'', ''539439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539450'', ''539469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539500'', ''539539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539550'', ''539559'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539600'', ''539639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539650'', ''539679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539700'', ''539779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539800'', ''539859'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539880'', ''539889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539900'', ''539939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''539950'', ''539979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''540000'', ''540199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''540300'', ''556899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''557000'', ''560399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''560500'', ''570299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''570400'', ''570699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''570800'', ''575999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''576100'', ''579499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''579600'', ''579899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''580000'', ''594199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''594300'', ''597399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''597500'', ''598999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''599100'', ''599399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Camperdown- Casterton- Edenhope- Hamilton- Portland- Warrnambool''                                                       , ''03'', ''55'', ''599500'', ''599899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''600000'', ''616299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''616400'', ''616499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''616700'', ''617299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''617700'', ''619899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''620100'', ''620899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''621000'', ''629999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''630100'', ''630899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''631100'', ''631899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''632100'', ''632899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''633000'', ''639899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''640100'', ''640799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''654000'', ''659999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''662000'', ''664999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''667000'', ''668999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''671000'', ''672999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''674000'', ''674999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''678000'', ''678999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Foster- Korumburra- Warragul''                                                                                           , ''03'', ''56'', ''680000'', ''689999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''700000'', ''723539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''723550'', ''723569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''723600'', ''724359'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''724380'', ''724439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''724450'', ''724469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''724500'', ''724589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''724600'', ''724639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''724650'', ''724669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''724700'', ''724769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''724800'', ''724839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''724850'', ''724869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''724900'', ''724969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''725100'', ''725599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''725700'', ''726269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''726300'', ''726339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''726350'', ''726369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''726400'', ''726469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''726500'', ''726639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''726650'', ''726669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''726700'', ''727539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''727550'', ''727569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''727600'', ''727769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''727800'', ''729039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''729050'', ''729069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''729100'', ''729169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''729200'', ''729269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''729300'', ''730169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''730200'', ''730269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''730300'', ''730369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''730400'', ''730469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''730500'', ''730569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''730600'', ''730669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''730700'', ''730769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''730800'', ''730869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''730900'', ''730969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''731000'', ''741769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''741800'', ''741869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''741900'', ''741959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''742000'', ''746069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''746100'', ''746169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''746200'', ''746269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''746300'', ''746369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''746400'', ''746459'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''746500'', ''746539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''746550'', ''746569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''746600'', ''746639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''746650'', ''746669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''746700'', ''746769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''746800'', ''746839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''746850'', ''746869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''746900'', ''746969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747000'', ''747039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747050'', ''747069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747100'', ''747139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747150'', ''747169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747200'', ''747239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747250'', ''747269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747300'', ''747339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747350'', ''747369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747400'', ''747439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747450'', ''747469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747500'', ''747549'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747600'', ''747639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747650'', ''747669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747700'', ''747739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747750'', ''747769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''747800'', ''747869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''748000'', ''749999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''750100'', ''750999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''751100'', ''752499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''752600'', ''753299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''753400'', ''755999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''756100'', ''756899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''757000'', ''757399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''757500'', ''757899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''758000'', ''763999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''764100'', ''764299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''764400'', ''764799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''765100'', ''765399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''766000'', ''766999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''767100'', ''767299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''768100'', ''768299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''768500'', ''768699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''768900'', ''769299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''770000'', ''770999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''771100'', ''771699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''772000'', ''772499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''773200'', ''773299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''773400'', ''775899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''776200'', ''776499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''776900'', ''777999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''778700'', ''778999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''779100'', ''779199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''780000'', ''781599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''782000'', ''782299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''783000'', ''783899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''784000'', ''784999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''785100'', ''785299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''786000'', ''787299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''787900'', ''788099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''788300'', ''788499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''789000'', ''789199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''789600'', ''790199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''790300'', ''790699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''790800'', ''790899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''791000'', ''793499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''793600'', ''795999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''796100'', ''796299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''796500'', ''797999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''798100'', ''798399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''798500'', ''798599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''798700'', ''798799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alexandra- Myrtleford- Seymour- Wangaratta''                                                                             , ''03'', ''57'', ''798900'', ''799999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''800000'', ''845799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''846300'', ''846399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''847300'', ''847399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''847700'', ''847799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''847900'', ''847999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''848400'', ''848499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''848600'', ''848899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''849000'', ''849899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''850100'', ''850899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''851000'', ''877899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''878100'', ''891899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''892100'', ''892899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''893100'', ''893899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''894100'', ''894899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''895100'', ''895899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''896100'', ''896899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''897100'', ''897899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deniliquin- Numurkah- Shepparton''                                                                                       , ''03'', ''58'', ''898000'', ''899999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''900000'', ''922899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''923100'', ''923899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''924100'', ''924899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''925100'', ''925899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''926100'', ''926699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''931000'', ''932899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''933000'', ''934999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''940000'', ''946199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''949000'', ''953299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''954000'', ''957999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''960000'', ''991999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''995000'', ''998999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Mornington- Warragul''                                                                                                   , ''03'', ''59'', ''999400'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''100000'', ''118899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''119000'', ''119999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''120100'', ''120899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''121100'', ''121899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''122100'', ''122899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''123100'', ''123899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''124100'', ''124899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''125100'', ''125899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''126100'', ''126899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''127100'', ''127899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''128100'', ''128899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''129100'', ''129899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''130100'', ''130899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''131100'', ''131899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''132100'', ''132899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''133100'', ''133899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''134100'', ''134799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''135000'', ''135099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''61'', ''165000'', ''168999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''200000'', ''283699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''283800'', ''285899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''286100'', ''288499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''288800'', ''289499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''289900'', ''291999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''292100'', ''292299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''293000'', ''293399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''293900'', ''293999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''294100'', ''295299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''295700'', ''296299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''297000'', ''297299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''297600'', ''298499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Geeveston- Hobart- Oatlands- Ouse''                                                                                      , ''03'', ''62'', ''298900'', ''299999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''63'', ''300000'', ''380899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''63'', ''381000'', ''387899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''63'', ''388100'', ''399999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''400000'', ''416999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''417100'', ''417899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''418100'', ''418899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''419100'', ''419899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''420000'', ''446999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''447100'', ''447899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''448100'', ''448899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''449100'', ''449899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''450100'', ''450899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''451100'', ''451899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''452000'', ''453999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''454100'', ''454299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''454400'', ''454799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''456000'', ''459299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''461000'', ''464299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''471000'', ''474299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''475000'', ''476799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''478900'', ''478999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''490000'', ''492999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''495100'', ''495199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''64'', ''496000'', ''499899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Burnie- Devonport- King Island- Queenstown- Smithton''                                                                   , ''03'', ''65'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''700000'', ''700999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''701100'', ''701899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''702100'', ''702899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''703100'', ''703899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''704100'', ''704899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''705100'', ''705899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''706100'', ''706899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''707100'', ''707899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''708100'', ''708899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''709100'', ''709899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''710100'', ''710899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''711100'', ''711899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''712100'', ''712899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''713100'', ''713899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''714100'', ''714899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''715100'', ''715699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''777000'', ''778399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Deloraine- Flinders Island- Launceston- Scottsdale- St Maryï¿œs''                                                        , ''03'', ''67'', ''778800'', ''778899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''70'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''71'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''77'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''78'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''79'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''80'', ''000000'', ''001899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''80'', ''002000'', ''005999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''80'', ''015300'', ''015899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''80'', ''060000'', ''060999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''80'', ''065500'', ''065599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''80'', ''080000'', ''080999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''80'', ''086000'', ''089999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''80'', ''099400'', ''099599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''81'', ''100000'', ''103899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''81'', ''118600'', ''119299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''81'', ''187000'', ''190999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''81'', ''199000'', ''199999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''82'', ''200000'', ''202599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''82'', ''202800'', ''202899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''82'', ''215700'', ''215999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''82'', ''256000'', ''256999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''82'', ''288000'', ''288999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''82'', ''290000'', ''290999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''83'', ''300000'', ''362899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''83'', ''363000'', ''371999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''83'', ''372100'', ''372499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''83'', ''375500'', ''375599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''83'', ''376300'', ''390999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''83'', ''395800'', ''395999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''83'', ''398000'', ''399999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''84'', ''400000'', ''400799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''84'', ''401000'', ''407499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''84'', ''412000'', ''420999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''84'', ''430000'', ''432999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''84'', ''436000'', ''436999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''84'', ''456000'', ''459999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''84'', ''461000'', ''461999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''84'', ''467000'', ''468999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''84'', ''470000'', ''470999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''84'', ''480000'', ''481999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''84'', ''486000'', ''486999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''84'', ''488600'', ''488999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''500000'', ''518799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''519000'', ''527999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''530000'', ''534999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''540000'', ''546999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''549000'', ''555999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''558000'', ''558999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''561000'', ''564999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''566600'', ''567999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''571000'', ''571999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''573000'', ''575999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''577700'', ''577799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''581000'', ''581999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''585000'', ''588999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''591000'', ''591999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''85'', ''598000'', ''599999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''86'', ''600000'', ''648999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''86'', ''649100'', ''651999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''86'', ''652100'', ''652299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''86'', ''653000'', ''658999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''86'', ''660000'', ''693999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''86'', ''695000'', ''699999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''87'', ''700000'', ''752399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''87'', ''752500'', ''752599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''87'', ''753000'', ''759999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''87'', ''761000'', ''763799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''87'', ''765000'', ''765999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''87'', ''767000'', ''772599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''87'', ''773000'', ''779999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''87'', ''780800'', ''782199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''87'', ''782300'', ''782699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''87'', ''785000'', ''799999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''800000'', ''820899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''821000'', ''822499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''822800'', ''822899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''823000'', ''826999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''831000'', ''833999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''838000'', ''839499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''840000'', ''851999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''855000'', ''855999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''862000'', ''862999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''866000'', ''866999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''870000'', ''870999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''872000'', ''873999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''877000'', ''878999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''888000'', ''888999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''892000'', ''892999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''88'', ''899600'', ''899999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''89'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''90'', ''000000'', ''007399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''90'', ''008000'', ''044999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''90'', ''049000'', ''049999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''90'', ''066000'', ''066999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''90'', ''076000'', ''081999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''90'', ''088000'', ''088999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''90'', ''090000'', ''099999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''91'', ''100000'', ''100999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''91'', ''101100'', ''101299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''91'', ''105800'', ''107999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''91'', ''111000'', ''111799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''91'', ''130000'', ''130999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''91'', ''173500'', ''173899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''91'', ''188000'', ''188999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''93'', ''300000'', ''399999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''94'', ''400000'', ''447999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''94'', ''449000'', ''452999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''94'', ''455000'', ''475099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''94'', ''478000'', ''490999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''94'', ''494000'', ''497999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''94'', ''499000'', ''499999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''95'', ''500000'', ''599999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''96'', ''600000'', ''699999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''97'', ''700000'', ''799999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Melbourne''                                                                                                              , ''03'', ''98'', ''800000'', ''899999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''20'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''21'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''30'', ''000000'', ''053899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''30'', ''054000'', ''060299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''30'', ''066000'', ''067999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''30'', ''070000'', ''072999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''30'', ''077600'', ''077999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''30'', ''086000'', ''086299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''30'', ''087000'', ''087999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''30'', ''088100'', ''092299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''30'', ''099200'', ''099999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''32'', ''200000'', ''209999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''32'', ''210000'', ''219999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''32'', ''220000'', ''229999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''32'', ''230000'', ''239999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''32'', ''240000'', ''249999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''32'', ''250000'', ''259999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''32'', ''260000'', ''269999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''32'', ''270000'', ''279999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''32'', ''280000'', ''289999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''32'', ''290000'', ''299999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''33'', ''300000'', ''309999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''33'', ''310000'', ''319999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''33'', ''320000'', ''329999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''33'', ''330000'', ''339999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''33'', ''340000'', ''349999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''33'', ''350000'', ''359999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''33'', ''360000'', ''369999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''33'', ''370000'', ''379999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''33'', ''380000'', ''389999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''33'', ''390000'', ''399999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''34'', ''400000'', ''477899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''34'', ''478100'', ''496899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''34'', ''497100'', ''497299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''34'', ''497700'', ''498099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''34'', ''498600'', ''498699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''34'', ''498800'', ''499999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''35'', ''500000'', ''506799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''35'', ''510000'', ''514999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''35'', ''535000'', ''535999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''35'', ''550000'', ''554999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''35'', ''555500'', ''555899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''37'', ''700000'', ''702999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''37'', ''703100'', ''703299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''37'', ''710000'', ''726399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''37'', ''727000'', ''728499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''37'', ''733000'', ''733399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''37'', ''735000'', ''737999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''38'', ''800000'', ''809999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''38'', ''810000'', ''819999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''38'', ''820000'', ''829999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''38'', ''830000'', ''839999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''38'', ''840000'', ''849999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''38'', ''850000'', ''859999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''38'', ''860000'', ''869999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''38'', ''870000'', ''879999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''38'', ''880000'', ''889999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''38'', ''890000'', ''899999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''39'', ''900000'', ''910999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''39'', ''911100'', ''911299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''39'', ''914000'', ''916199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''39'', ''917000'', ''917999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''39'', ''947500'', ''947599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Brisbane- Bribie Island- Esk''                                                                                           , ''07'', ''39'', ''999600'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''40'', ''000000'', ''079399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''40'', ''079500'', ''079599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''40'', ''079900'', ''082699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''40'', ''082900'', ''084799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''40'', ''084900'', ''085799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''40'', ''086100'', ''087799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''40'', ''088000'', ''088299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''40'', ''088400'', ''088999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''40'', ''089200'', ''099999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''100000'', ''166999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''167100'', ''167299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''167500'', ''167599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''167800'', ''170299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''170400'', ''170499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''170700'', ''170799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''171000'', ''171399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''171600'', ''171799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''172100'', ''172199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''172500'', ''172599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''172700'', ''173399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''173700'', ''178999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''179100'', ''179199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''179400'', ''181699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''181900'', ''183199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''41'', ''183600'', ''199999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''200000'', ''203299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''203700'', ''203799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''204100'', ''204299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''204800'', ''204999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''205200'', ''205299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''205400'', ''212999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''213100'', ''214999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''215100'', ''215899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''216100'', ''216999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''217100'', ''217899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''218100'', ''218899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''219100'', ''219899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''220100'', ''226999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''227100'', ''227899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''228100'', ''228899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''229100'', ''229899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''230100'', ''230899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''231100'', ''231899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''232100'', ''232999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''233100'', ''233899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''234100'', ''234899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''235100'', ''235899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''236100'', ''236899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''237100'', ''237899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''238100'', ''238399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''241000'', ''241999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''42'', ''242100'', ''242899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''300000'', ''303999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''304100'', ''304899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''305100'', ''305899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''306100'', ''306899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''307100'', ''307899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''308100'', ''308899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''309100'', ''309899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''310100'', ''310899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''311100'', ''311899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''312100'', ''312899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''313100'', ''313899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''314100'', ''314899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''315100'', ''315899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''316100'', ''316899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''317100'', ''317399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''317500'', ''317899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''318100'', ''318899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''319100'', ''319899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''320100'', ''320799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''325300'', ''325999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''326100'', ''326199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bundaberg- Gayndah- Kingaroy- Maryborough- Murgon''                                                                      , ''07'', ''43'', ''331000'', ''331699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''400000'', ''408999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''409100'', ''409999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''410100'', ''410399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''411000'', ''412999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''417100'', ''417199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''417500'', ''417599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''420000'', ''424899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''426100'', ''426199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''431000'', ''432499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''433000'', ''434999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''437300'', ''437399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''442000'', ''442899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''444400'', ''445199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''447700'', ''447999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''44'', ''448200'', ''448299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''500000'', ''514769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''514780'', ''514789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''514800'', ''514869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''514880'', ''514889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''514900'', ''514979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''515000'', ''515079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''515100'', ''515179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''515200'', ''515279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''515300'', ''515379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''515400'', ''515479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''515500'', ''515579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''515600'', ''515679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''515700'', ''515779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''515800'', ''515879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''515900'', ''515979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''516000'', ''516079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''516100'', ''516179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''516200'', ''516279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''516300'', ''516379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''516400'', ''516479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''516500'', ''516589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''516600'', ''516679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''516700'', ''516779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''516800'', ''516879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''516900'', ''516979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''517000'', ''517079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''517100'', ''517179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''517200'', ''517279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''517300'', ''517379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''517400'', ''517479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''517500'', ''517579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''517600'', ''517679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''517700'', ''517779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''517800'', ''517879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''517900'', ''517979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''518000'', ''518079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''518100'', ''518179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''518200'', ''518279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''518300'', ''518379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''518400'', ''518479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''518500'', ''518579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''518600'', ''518679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''518700'', ''518779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''518800'', ''518879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''518900'', ''518979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''519000'', ''519079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''519100'', ''519179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''519200'', ''519279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''519300'', ''519379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''519400'', ''519479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''519500'', ''519579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''519600'', ''519679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''519700'', ''519779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''519800'', ''519879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''519900'', ''519979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520000'', ''520079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520100'', ''520179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520200'', ''520279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520300'', ''520379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520400'', ''520479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520500'', ''520579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520600'', ''520639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520650'', ''520679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520700'', ''520739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520750'', ''520779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520800'', ''520839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520850'', ''520879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520900'', ''520939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''520950'', ''520979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521000'', ''521039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521050'', ''521079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521100'', ''521139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521150'', ''521179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521200'', ''521239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521250'', ''521279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521300'', ''521339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521350'', ''521379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521400'', ''521439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521450'', ''521479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521500'', ''521539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521550'', ''521579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521600'', ''521639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521650'', ''521679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521700'', ''521739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521750'', ''521779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521800'', ''521839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521850'', ''521879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''521900'', ''521979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''522000'', ''522079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''522100'', ''522179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''522200'', ''522279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''522300'', ''522379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''522400'', ''522479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''522500'', ''522579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''522600'', ''522679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''522700'', ''522779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''522800'', ''522879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''522900'', ''522979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''523000'', ''523079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''523100'', ''523179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''523200'', ''523279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''523300'', ''523379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''523400'', ''523479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''523500'', ''523579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''523600'', ''523669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''523700'', ''523779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''523800'', ''523879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''523900'', ''523979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''524000'', ''524069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''524100'', ''524179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''524200'', ''524279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''524300'', ''524379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''524400'', ''524479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''524500'', ''524579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''524600'', ''524679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''524700'', ''524779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''524800'', ''524869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''524880'', ''524889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''524900'', ''524969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''524980'', ''524989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525000'', ''525069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525080'', ''525089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525100'', ''525169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525180'', ''525189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525200'', ''525269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525280'', ''525289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525300'', ''525369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525380'', ''525389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525400'', ''525469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525480'', ''525489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525500'', ''525589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525600'', ''525669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525680'', ''525689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525700'', ''525769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525780'', ''525789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525800'', ''525869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525880'', ''525889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525900'', ''525969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''525980'', ''525989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526000'', ''526069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526080'', ''526089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526100'', ''526169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526180'', ''526189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526200'', ''526269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526280'', ''526289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526300'', ''526369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526380'', ''526389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526400'', ''526469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526480'', ''526489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526500'', ''526569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526580'', ''526589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526600'', ''526669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526680'', ''526689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526700'', ''526749'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526800'', ''526869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526880'', ''526889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526900'', ''526969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''526980'', ''526989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''527000'', ''527069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''527080'', ''527089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''527100'', ''527169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''527180'', ''527189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''527200'', ''527269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''527280'', ''527289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''527300'', ''527369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''527380'', ''527389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''527400'', ''527479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''527500'', ''569699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''569900'', ''569999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''570700'', ''570799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''570900'', ''570999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''571900'', ''571999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''572200'', ''572299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''572400'', ''572999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''573200'', ''573299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''577700'', ''577999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''578400'', ''578799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''579100'', ''579299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''592800'', ''592899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''594200'', ''594499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''596100'', ''596399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''45'', ''596700'', ''596999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''46'', ''600000'', ''683009'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''46'', ''683050'', ''683059'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''46'', ''683100'', ''699999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''700000'', ''738139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738150'', ''738179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738200'', ''738239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738250'', ''738279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738300'', ''738319'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738330'', ''738369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738400'', ''738439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738450'', ''738479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738500'', ''738519'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738530'', ''738569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738590'', ''738639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738650'', ''738679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738700'', ''738739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738750'', ''738779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738800'', ''738839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738850'', ''738879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738900'', ''738939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''738950'', ''738979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739000'', ''739039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739050'', ''739079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739100'', ''739139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739150'', ''739179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739200'', ''739219'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739230'', ''739269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739300'', ''739339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739350'', ''739379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739400'', ''739439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739450'', ''739479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739500'', ''739559'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739600'', ''739619'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739630'', ''739669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739700'', ''739739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739750'', ''739779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739800'', ''739869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''739900'', ''739979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''740000'', ''763379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''763400'', ''763579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''763600'', ''763679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''763700'', ''763759'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''763800'', ''763869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''763880'', ''763889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''763900'', ''763959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''763970'', ''763979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764000'', ''764269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764280'', ''764289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764300'', ''764369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764380'', ''764389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764400'', ''764469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764480'', ''764489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764500'', ''764559'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764570'', ''764579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764600'', ''764669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764680'', ''764689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764700'', ''764769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764780'', ''764789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764800'', ''764869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764880'', ''764889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764900'', ''764969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''764980'', ''764989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765000'', ''765069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765080'', ''765089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765100'', ''765169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765180'', ''765189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765200'', ''765269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765280'', ''765289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765300'', ''765369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765380'', ''765389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765400'', ''765459'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765470'', ''765479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765500'', ''765569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765580'', ''765589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765600'', ''765669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765680'', ''765689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765700'', ''765769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765780'', ''765789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765800'', ''765869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765880'', ''765889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765900'', ''765969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''765980'', ''765989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''766000'', ''767089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''767100'', ''767169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''767180'', ''767189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''767200'', ''767269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''767280'', ''767289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''767300'', ''767369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''767380'', ''767389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''767400'', ''767469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''767480'', ''767489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''767500'', ''767559'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''767600'', ''792069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''792080'', ''792089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''792100'', ''792169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''792180'', ''792189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''792200'', ''792269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''792280'', ''792289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''792300'', ''792339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''792350'', ''792379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''792440'', ''792939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''793000'', ''793199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''793300'', ''793399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''47'', ''794000'', ''799999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800000'', ''800009'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800020'', ''800089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800100'', ''800139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800150'', ''800189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800200'', ''800209'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800220'', ''800289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800300'', ''800389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800400'', ''800409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800420'', ''800509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800520'', ''800589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800600'', ''800609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800620'', ''800689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800700'', ''800789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800800'', ''800809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800820'', ''800889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800900'', ''800909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''800920'', ''800989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801000'', ''801009'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801020'', ''801089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801100'', ''801109'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801120'', ''801189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801200'', ''801239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801250'', ''801289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801300'', ''801309'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801320'', ''801389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801400'', ''801439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801450'', ''801489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801500'', ''801509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801520'', ''801589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801600'', ''801609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801620'', ''801689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801700'', ''801789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801800'', ''801809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801820'', ''801889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801900'', ''801939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''801950'', ''801989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802000'', ''802009'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802020'', ''802089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802100'', ''802189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802200'', ''802209'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802220'', ''802289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802300'', ''802359'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802400'', ''802409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802420'', ''802489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802500'', ''802509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802520'', ''802589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802600'', ''802609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802620'', ''802689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802700'', ''802789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802800'', ''802809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802820'', ''802889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802900'', ''802909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''802920'', ''802989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803000'', ''803009'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803020'', ''803089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803100'', ''803109'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803120'', ''803189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803200'', ''803239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803250'', ''803289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803300'', ''803389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803400'', ''803409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803420'', ''803489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803500'', ''803539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803550'', ''803569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803580'', ''803589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803600'', ''803689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803700'', ''803789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803800'', ''803809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803820'', ''803889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''803900'', ''803959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804000'', ''804089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804100'', ''804139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804150'', ''804189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804200'', ''804209'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804220'', ''804289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804300'', ''804309'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804320'', ''804389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804400'', ''804439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804450'', ''804489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804500'', ''804559'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804580'', ''804589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804600'', ''804609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804620'', ''804689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804700'', ''804709'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804720'', ''804789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804800'', ''804809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804820'', ''804889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804900'', ''804939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''804950'', ''804989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805000'', ''805039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805050'', ''805089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805100'', ''805109'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805120'', ''805189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805200'', ''805209'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805220'', ''805289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805300'', ''805339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805350'', ''805389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805400'', ''805409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805420'', ''805489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805500'', ''805509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805520'', ''805589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805600'', ''805659'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805680'', ''805689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805700'', ''805779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805800'', ''805839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805850'', ''805889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''805900'', ''805969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806000'', ''806089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806100'', ''806139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806150'', ''806189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806200'', ''806209'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806220'', ''806289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806300'', ''806389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806400'', ''806439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806450'', ''806489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806500'', ''806509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806520'', ''806589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806600'', ''806609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806620'', ''806689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806700'', ''806709'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806720'', ''806789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806800'', ''806809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806820'', ''806889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806900'', ''806909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''806920'', ''806989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807000'', ''807009'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807020'', ''807089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807100'', ''807109'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807120'', ''807189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807200'', ''807209'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807220'', ''807289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807300'', ''807339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807350'', ''807379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807400'', ''807439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807450'', ''807479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807500'', ''807539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807550'', ''807589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807600'', ''807659'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807690'', ''807739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807750'', ''807789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807800'', ''807839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807850'', ''807889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807900'', ''807909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''807920'', ''807989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''808000'', ''808039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''808050'', ''808089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''808100'', ''808109'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''808120'', ''808189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''808200'', ''808269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''808300'', ''837899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''838100'', ''838899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''839100'', ''839899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''840000'', ''842999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''843100'', ''843599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''844000'', ''844999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''846200'', ''846299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''846700'', ''846999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''847100'', ''847499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''862100'', ''862299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''884000'', ''885899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''886100'', ''886199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''898000'', ''898699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''48'', ''898900'', ''898999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''49'', ''900000'', ''913109'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''49'', ''913150'', ''913159'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''49'', ''913200'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''52'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''300000'', ''327199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''327400'', ''328099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''328200'', ''328299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''328400'', ''328699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''328800'', ''328899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''329000'', ''343999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''344100'', ''344999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''345100'', ''345999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''346100'', ''347899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''348100'', ''348899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''349100'', ''349899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''350100'', ''350899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''351000'', ''354899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''355100'', ''355899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''356100'', ''356899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''357100'', ''357899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''358100'', ''358899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''359100'', ''359699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''359800'', ''360899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''361000'', ''362999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''363100'', ''363599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''370100'', ''370899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''371000'', ''372699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''53'', ''390000'', ''390999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Caboolture- Esk- Gatton- Gympie- Nambour''                                                                               , ''07'', ''54'', ''400000'', ''499999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''55'', ''500000'', ''599999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''600000'', ''609999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''610100'', ''610899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''611100'', ''611799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''612100'', ''612599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''618100'', ''618399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''618600'', ''618999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''626000'', ''626999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''630000'', ''636999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''640000'', ''645399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''646000'', ''646699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''655000'', ''655899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''656000'', ''661899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''664900'', ''670299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''676400'', ''680999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''688500'', ''689199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''699800'', ''699999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''56'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Beaudesert''                                                                                                             , ''07'', ''57'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cairns''                                                                                                                 , ''07'', ''70'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''75'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Charleville- Dalby- Dirranbandi- Goondiwindi- Inglewood-Longreach-Miles-Roma-Stanthorpe-Toowoomba-Warwick''              , ''07'', ''76'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Cloncurry- Hughenden- Townsville''                                                                                       , ''07'', ''77'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Biloela- Emerald- Gladstone- Mackay- Rockhampton''                                                                       , ''07'', ''79'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''25'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Lincoln- Port Pirie- Cook- Gladstone- Peterborough- Woomera''                                 , ''08'', ''26'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''51'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''52'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''53'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''54'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''55'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''58'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''60'', ''000000'', ''001899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''60'', ''002100'', ''002299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''61'', ''100000'', ''109399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''61'', ''113000'', ''114999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''61'', ''140000'', ''146999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''61'', ''147100'', ''147199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''61'', ''150000'', ''150299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''61'', ''150600'', ''150699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''61'', ''160000'', ''162999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''61'', ''180000'', ''182099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''61'', ''188000'', ''189999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''61'', ''190000'', ''193899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''61'', ''194000'', ''197899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''61'', ''198000'', ''199999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''200000'', ''202899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''203000'', ''205599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''208000'', ''209999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''210000'', ''219899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''220000'', ''225399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''225500'', ''225599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''226000'', ''229999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''230000'', ''232999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''234600'', ''234699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''240000'', ''242499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''243000'', ''243999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''250000'', ''255599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''258000'', ''258999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''260000'', ''269999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''270000'', ''271399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''272000'', ''272999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''274000'', ''274999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''277000'', ''279999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''280000'', ''280299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''282000'', ''282999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''62'', ''290000'', ''299999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''304000'', ''305099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''310000'', ''318999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''321000'', ''324999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''330000'', ''333499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''336600'', ''336999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''350000'', ''350999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''355500'', ''355699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''360000'', ''361899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''362000'', ''369999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''377700'', ''377899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''380000'', ''382999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''383100'', ''383499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''388800'', ''389999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''63'', ''390000'', ''399999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''400000'', ''400099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''401000'', ''401599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''404000'', ''404999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''406000'', ''406999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''408000'', ''408999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''414000'', ''414999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''420000'', ''420999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''424000'', ''424999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''430000'', ''430999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''431800'', ''431899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''436000'', ''436999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''444000'', ''444999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''446600'', ''446799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''454000'', ''454999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''460000'', ''469999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''477000'', ''477999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''488000'', ''489299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''490000'', ''495899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''64'', ''496000'', ''499999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''65'', ''500000'', ''500999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''65'', ''540000'', ''540999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''65'', ''551000'', ''553999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''65'', ''555000'', ''555999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''65'', ''557000'', ''558999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''65'', ''580100'', ''580199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''65'', ''590000'', ''594399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''65'', ''595000'', ''595999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- 8York''                                                                       , ''08'', ''66'', ''600000'', ''600699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- 8York''                                                                       , ''08'', ''66'', ''661100'', ''661199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''67'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800000'', ''800009'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800020'', ''800089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800100'', ''800139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800150'', ''800189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800200'', ''800209'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800220'', ''800289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800300'', ''800309'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800320'', ''800389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800400'', ''800409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800420'', ''800509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800520'', ''800589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800600'', ''800639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800650'', ''800689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800700'', ''800709'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800720'', ''800789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800800'', ''800809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800820'', ''800889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800900'', ''800909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''800920'', ''800989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''801000'', ''801009'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''801020'', ''801089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''801100'', ''801109'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''801120'', ''801189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''801200'', ''801239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''801250'', ''801289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''801300'', ''801339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''801350'', ''801389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''801400'', ''818899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''819000'', ''819899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''68'', ''820100'', ''820199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills'', ''08'', ''69'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''70'', ''000000'', ''007999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''70'', ''008100'', ''008199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''70'', ''009000'', ''009999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''70'', ''070000'', ''073999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''70'', ''087000'', ''089999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''100000'', ''100199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''100500'', ''100899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''109000'', ''109999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''110100'', ''110199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''111000'', ''111399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''120000'', ''129999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''130000'', ''130399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''131000'', ''131999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''140000'', ''140199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''150100'', ''150199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''160000'', ''160399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''170000'', ''170599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''71'', ''180000'', ''189999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''72'', ''200000'', ''201999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''72'', ''202100'', ''202199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''72'', ''210000'', ''210999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''72'', ''220000'', ''229999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''72'', ''230000'', ''230999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''72'', ''233000'', ''233499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''72'', ''280000'', ''282899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''72'', ''283000'', ''285899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''72'', ''286100'', ''286399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''72'', ''287000'', ''289999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''73'', ''320000'', ''329999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''73'', ''333300'', ''333499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''73'', ''380000'', ''380399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''73'', ''380700'', ''380799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''73'', ''383000'', ''383999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''73'', ''389000'', ''389999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''74'', ''420000'', ''425999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''74'', ''444400'', ''444599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''74'', ''477700'', ''477899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''74'', ''480000'', ''480999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''74'', ''481500'', ''481899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''74'', ''485400'', ''485499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''75'', ''500000'', ''518899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''75'', ''519000'', ''521899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''75'', ''522100'', ''522899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''75'', ''523100'', ''523499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''75'', ''526700'', ''526799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''75'', ''531100'', ''531199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''75'', ''555600'', ''559999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''75'', ''599800'', ''599999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''76'', ''600000'', ''624899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''76'', ''625100'', ''625299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''76'', ''628300'', ''628499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''77'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''78'', ''000000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''900000'', ''903899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''904100'', ''904899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''905100'', ''905899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''906100'', ''906899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''907100'', ''907899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''908100'', ''908899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''909100'', ''909899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''910100'', ''910899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''911100'', ''911899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''912100'', ''912599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''969100'', ''969199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''978100'', ''978299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''988800'', ''988999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''79'', ''999400'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Broken Hill''                                                                                                            , ''08'', ''80'', ''000000'', ''009899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Broken Hill''                                                                                                            , ''08'', ''80'', ''010100'', ''010899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Broken Hill''                                                                                                            , ''08'', ''80'', ''011100'', ''011899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Broken Hill''                                                                                                            , ''08'', ''80'', ''012100'', ''012899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Broken Hill''                                                                                                            , ''08'', ''80'', ''013100'', ''013199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Broken Hill''                                                                                                            , ''08'', ''80'', ''080000'', ''084999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Broken Hill''                                                                                                            , ''08'', ''80'', ''087000'', ''089299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Broken Hill''                                                                                                            , ''08'', ''80'', ''090000'', ''090899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Broken Hill''                                                                                                            , ''08'', ''80'', ''091000'', ''092899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''100000'', ''100999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''104000'', ''104999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''110000'', ''116999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''118000'', ''118999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''120000'', ''129999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''130000'', ''133999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''135000'', ''135999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''139000'', ''139999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''150000'', ''150999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''152000'', ''152999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''154000'', ''154999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''155500'', ''155699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''159000'', ''159999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''161000'', ''162999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''164000'', ''165999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''166600'', ''166799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''168000'', ''169999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''172000'', ''172999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''177000'', ''179999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''180000'', ''189999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''190000'', ''190099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''193000'', ''193999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''81'', ''198000'', ''198999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''82'', ''200000'', ''209999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''82'', ''210000'', ''219999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''82'', ''220000'', ''229999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''82'', ''230000'', ''239999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''82'', ''240000'', ''246999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''82'', ''248000'', ''249999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''82'', ''250000'', ''259999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''82'', ''260000'', ''269999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''82'', ''270000'', ''279999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''82'', ''280000'', ''289999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''82'', ''290000'', ''299999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''83'', ''300000'', ''309999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''83'', ''310000'', ''317999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''83'', ''318200'', ''318299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''83'', ''320000'', ''329999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''83'', ''330000'', ''339999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''83'', ''340000'', ''349999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''83'', ''350000'', ''359999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''83'', ''360000'', ''369999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''83'', ''370000'', ''379999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''83'', ''380000'', ''389999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''83'', ''390000'', ''399999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''400000'', ''409999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''410000'', ''419999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''420000'', ''429999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''431000'', ''433999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''440000'', ''445999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''447000'', ''449999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''450000'', ''451999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''456000'', ''457199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''460000'', ''465999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''468000'', ''468999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''470000'', ''471999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''480000'', ''489999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Adelaide''                                                                                                               , ''08'', ''84'', ''490000'', ''490999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''500000'', ''501969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''501980'', ''501989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''502000'', ''502959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''502980'', ''502989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''503000'', ''503959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''503980'', ''503989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''504000'', ''506959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''506980'', ''506989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''507000'', ''507959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''507980'', ''507989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''508000'', ''508959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''508980'', ''508989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''509000'', ''509959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''509980'', ''509989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''510000'', ''510959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''510980'', ''510989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''511000'', ''511959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''511980'', ''511989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''512000'', ''512969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''512980'', ''514969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''514980'', ''515969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''515980'', ''516969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''516980'', ''517969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''517980'', ''517989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''518000'', ''518959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''518980'', ''519969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''519980'', ''519989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''520000'', ''520649'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''520680'', ''520769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''520780'', ''520789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''520800'', ''520869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''520880'', ''520889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''520900'', ''520959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''520980'', ''520989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''521000'', ''528769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''528780'', ''528859'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''528870'', ''528969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''528980'', ''530959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''530980'', ''535099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''535300'', ''543299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''544000'', ''544969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''544980'', ''545089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545100'', ''545169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545180'', ''545189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545200'', ''545269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545280'', ''545289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545300'', ''545369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545380'', ''545389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545400'', ''545469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545480'', ''545489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545500'', ''545569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545580'', ''545589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545600'', ''545669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545680'', ''545689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545700'', ''545769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545780'', ''545789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545800'', ''545869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545880'', ''545889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545900'', ''545959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''545980'', ''546989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''547000'', ''547989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''548000'', ''548959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''548980'', ''549069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549080'', ''549089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549100'', ''549169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549180'', ''549269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549280'', ''549289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549300'', ''549369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549380'', ''549389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549400'', ''549469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549480'', ''549489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549500'', ''549569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549580'', ''549589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549600'', ''549669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549680'', ''549689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549700'', ''549759'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549780'', ''549869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549880'', ''549889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549900'', ''549969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''549980'', ''549989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''550000'', ''550699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''550800'', ''566599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567000'', ''567069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567080'', ''567089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567100'', ''567169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567180'', ''567189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567200'', ''567269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567280'', ''567289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567300'', ''567369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567380'', ''567469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567480'', ''567489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567500'', ''567569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567580'', ''567589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567600'', ''567659'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567680'', ''567769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567780'', ''567789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567800'', ''567869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567880'', ''567889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567900'', ''567969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''567980'', ''567989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''568000'', ''571399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''572000'', ''573899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''574000'', ''574499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''575000'', ''576799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''577000'', ''579699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''580000'', ''581499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''581700'', ''585069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585080'', ''585089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585100'', ''585169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585180'', ''585189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585200'', ''585269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585280'', ''585289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585300'', ''585369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585380'', ''585389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585400'', ''585469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585480'', ''585489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585500'', ''585569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585580'', ''585589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585600'', ''585659'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585680'', ''585769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585780'', ''585789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585800'', ''585869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585880'', ''585889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585900'', ''585969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''585980'', ''585989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''586000'', ''588999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''589300'', ''589499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''589700'', ''589899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''590000'', ''599469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''599480'', ''599489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''599500'', ''599509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''599520'', ''599569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''599580'', ''599589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''599600'', ''599669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''599680'', ''599689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''599700'', ''599769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''599780'', ''599789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''599800'', ''599859'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''599880'', ''599969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Berri- Gawler- Kangaroo Island- Malalla- Murray Bridge- Nurioopta- Tailem Bend- Victor Harbour- Waikerie''               , ''08'', ''85'', ''599980'', ''599989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''600000'', ''600959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''600980'', ''620069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''620100'', ''620169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''620200'', ''620859'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''620890'', ''620969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''621000'', ''621669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''621680'', ''621689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''621700'', ''622069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''622080'', ''622089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''622100'', ''622769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''622780'', ''622789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''622800'', ''629069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''629080'', ''629089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''629100'', ''629169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''629180'', ''629189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''629200'', ''629869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''629880'', ''629889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''629900'', ''629959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''629980'', ''633669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''633680'', ''633689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''633700'', ''633769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''633780'', ''633789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''633800'', ''635669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''635680'', ''635689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''635700'', ''635769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''635780'', ''635789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''635800'', ''635969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''635980'', ''635989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''636000'', ''637069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''637080'', ''637089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''637100'', ''637569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''637600'', ''639569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''639580'', ''639589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''639600'', ''639669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''639680'', ''639689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''639700'', ''639869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''639880'', ''639889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''639900'', ''639969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''639980'', ''639989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''640000'', ''640569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''640580'', ''640589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''640600'', ''640669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''640680'', ''640689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''640700'', ''640769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''640780'', ''640789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''640800'', ''640869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''640880'', ''640889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''640900'', ''640969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''640980'', ''640989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''641000'', ''643169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''643180'', ''643189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''643200'', ''643269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''643300'', ''643369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''643400'', ''643469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''643500'', ''646079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''646100'', ''646159'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''646200'', ''646369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''646400'', ''646469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''646480'', ''646489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''646500'', ''646559'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''646600'', ''650069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''650080'', ''650089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''650100'', ''650169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''650180'', ''650189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''650200'', ''650269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''650280'', ''650289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''650300'', ''650769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''650780'', ''650789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''650800'', ''650869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''650880'', ''650889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''650900'', ''650969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''650980'', ''650989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''651000'', ''658269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''658280'', ''658289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''658300'', ''658369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''658380'', ''658389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''658400'', ''658469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''658480'', ''658489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''658500'', ''659269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''659280'', ''659289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''659300'', ''659369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''659380'', ''659389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''659400'', ''659469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''659480'', ''659489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''659500'', ''659669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''659680'', ''659689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''659700'', ''659769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''659780'', ''659789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''659800'', ''659869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''659880'', ''659889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''659900'', ''661669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''661680'', ''661689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''661700'', ''661769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''661780'', ''661789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''661800'', ''661869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''661880'', ''661889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''661900'', ''661969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''661980'', ''661989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''662200'', ''663669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''663680'', ''663689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''663700'', ''663769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''663780'', ''663789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''663800'', ''663869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''663880'', ''663889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''663900'', ''663969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''663980'', ''663989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''664000'', ''668099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''668300'', ''668899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669000'', ''669069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669080'', ''669089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669100'', ''669169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669180'', ''669189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669200'', ''669269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669280'', ''669289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669300'', ''669369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669400'', ''669469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669500'', ''669569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669600'', ''669679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669700'', ''669769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669800'', ''669869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''669900'', ''669969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''670000'', ''673999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''674300'', ''674499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''674900'', ''677069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677100'', ''677169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677200'', ''677269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677280'', ''677289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677300'', ''677369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677380'', ''677389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677400'', ''677469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677480'', ''677489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677500'', ''677569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677580'', ''677589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677600'', ''677669'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677680'', ''677689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677700'', ''677769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677780'', ''677789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677800'', ''677869'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677880'', ''677889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''677900'', ''677969'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''678000'', ''679199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''680000'', ''681399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''681700'', ''683799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''684000'', ''684999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''685200'', ''685699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''686000'', ''689599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''690000'', ''690069'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''690100'', ''690169'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''690200'', ''690269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''690300'', ''690369'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''690400'', ''690469'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''690480'', ''690489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''690500'', ''690569'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''690580'', ''690589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''691000'', ''691959'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Ceduna- Port Augusta- Port Pirie- Port Lincoln- Gladstone- Peterborough- Cook- Woomera''                                 , ''08'', ''86'', ''691980'', ''699999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''700000'', ''777899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''778100'', ''778899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''779100'', ''779899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''780100'', ''780899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''781100'', ''781899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''782100'', ''782899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''783100'', ''783899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''784100'', ''784899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''785100'', ''785899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''786100'', ''786899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''787100'', ''787899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''788100'', ''788899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''789100'', ''789899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bordertown- Mount Gambier- Naracoorte''                                                                                  , ''08'', ''87'', ''790000'', ''799999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''800000'', ''875999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''876100'', ''876899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''877100'', ''877899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''878100'', ''878899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''879100'', ''879899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''880100'', ''880899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''881100'', ''881899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''882100'', ''882899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''883100'', ''883899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''884100'', ''884899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''885100'', ''885899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''886100'', ''886899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''887100'', ''887899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''888100'', ''888599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Clare- Kadina- Port Lincoln- Burra- Balaklava- Maitland- Gawler- Yorketown''                                             , ''08'', ''88'', ''890000'', ''899999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''89'', ''900000'', ''996899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Alice Springs- Darwin''                                                                                                  , ''08'', ''89'', ''997000'', ''999999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''000000'', ''020699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''020800'', ''032639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''032650'', ''032679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''032700'', ''032739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''032750'', ''032779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''032800'', ''032839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''032850'', ''032879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''032900'', ''032939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''032950'', ''032979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033000'', ''033039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033050'', ''033079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033100'', ''033139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033150'', ''033179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033200'', ''033239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033250'', ''033279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033300'', ''033339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033350'', ''033379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033400'', ''033439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033450'', ''033479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033500'', ''033539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033550'', ''033579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033600'', ''033639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033650'', ''033679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033700'', ''033739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033750'', ''033779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033800'', ''033839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033850'', ''033879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033900'', ''033939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''033950'', ''033979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034000'', ''034039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034050'', ''034079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034100'', ''034139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034150'', ''034179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034200'', ''034239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034250'', ''034279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034300'', ''034339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034350'', ''034379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034400'', ''034439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034450'', ''034479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034500'', ''034539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034550'', ''034579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034600'', ''034639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034650'', ''034679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034700'', ''034779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034800'', ''034839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034850'', ''034879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034900'', ''034939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''034950'', ''034979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035000'', ''035059'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035100'', ''035139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035150'', ''035179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035200'', ''035239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035250'', ''035279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035300'', ''035339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035350'', ''035379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035400'', ''035439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035450'', ''035479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035500'', ''035539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035550'', ''035579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035600'', ''035639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035650'', ''035679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035700'', ''035739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035750'', ''035779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035800'', ''035839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035850'', ''035879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035900'', ''035939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''035950'', ''035979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036000'', ''036039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036050'', ''036079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036100'', ''036139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036150'', ''036179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036200'', ''036239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036250'', ''036279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036300'', ''036339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036350'', ''036379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036400'', ''036439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036450'', ''036479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036500'', ''036539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036550'', ''036579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036600'', ''036639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036650'', ''036679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036700'', ''036739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036750'', ''036779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036800'', ''036839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036850'', ''036879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036900'', ''036939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''036950'', ''036979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''037000'', ''038039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038050'', ''038079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038100'', ''038139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038150'', ''038179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038200'', ''038239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038250'', ''038279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038300'', ''038339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038350'', ''038379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038400'', ''038439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038450'', ''038479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038500'', ''038539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038550'', ''038579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038600'', ''038639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038650'', ''038679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038700'', ''038739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038750'', ''038779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038800'', ''038879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038900'', ''038939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''038950'', ''038979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''039000'', ''040499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''040600'', ''042139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042150'', ''042179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042200'', ''042239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042250'', ''042279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042300'', ''042339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042350'', ''042379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042400'', ''042439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042450'', ''042479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042500'', ''042539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042550'', ''042579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042600'', ''042639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042650'', ''042679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042700'', ''042739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042750'', ''042779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042800'', ''042839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''042850'', ''042879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''043100'', ''044799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''044900'', ''060899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''061000'', ''063599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''063700'', ''064399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''064500'', ''065999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''066300'', ''066799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''068100'', ''068199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''068800'', ''068999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''069900'', ''069999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''071000'', ''071799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''071900'', ''072399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''075000'', ''076999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''078000'', ''082999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''083100'', ''083299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''083900'', ''083999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''087700'', ''088799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''091000'', ''092299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bruce Rock- Great Victoria- Kalgoorlie- Merredin''                                                                       , ''08'', ''90'', ''092500'', ''099999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''100000'', ''126699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''126800'', ''126899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''127000'', ''127099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''127900'', ''127999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''128300'', ''128399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''128700'', ''128799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''129000'', ''129099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''129300'', ''130999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''131100'', ''132899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''133100'', ''133899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''134000'', ''134999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''135100'', ''135899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''136100'', ''136899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''137100'', ''137899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''138100'', ''138899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''139100'', ''139899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''140000'', ''142899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''143000'', ''145899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''146000'', ''147999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''148100'', ''148899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''149100'', ''149899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''151100'', ''151199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''153400'', ''153599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''154200'', ''154399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''154600'', ''154899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''156000'', ''171299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''172000'', ''180299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''181000'', ''181699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''181900'', ''189999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''190200'', ''190599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''190900'', ''198899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Christmas Island- Cocos (Keeling)- Islands- Derby- Great Sandy- Port Hedland''                                           , ''08'', ''91'', ''199900'', ''199999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''92'', ''200000'', ''209999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''92'', ''210000'', ''219999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''92'', ''220000'', ''229999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''92'', ''230000'', ''239999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''92'', ''240000'', ''249999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''92'', ''250000'', ''259999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''92'', ''260000'', ''269999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''92'', ''270000'', ''279999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''92'', ''280000'', ''289999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''92'', ''290000'', ''299999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''000000'', ''099999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''100000'', ''199999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''200000'', ''299999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''300000'', ''309999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''310000'', ''319999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''320000'', ''329999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''330000'', ''339999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''340000'', ''349999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''350000'', ''359999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''360000'', ''369999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''370000'', ''379999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''380000'', ''389999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''390000'', ''395399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''93'', ''395900'', ''399999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''94'', ''400000'', ''409999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''94'', ''410000'', ''419999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''94'', ''420000'', ''429999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''94'', ''430000'', ''439999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''94'', ''440000'', ''449999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''94'', ''450000'', ''459999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''94'', ''460000'', ''469999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''94'', ''470000'', ''479999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''94'', ''480000'', ''489999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Perth''                                                                                                                  , ''08'', ''94'', ''490000'', ''499999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''500000'', ''517399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''517500'', ''517899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''518000'', ''520899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''521000'', ''521899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''522000'', ''532899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''533000'', ''539899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''540100'', ''540899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''541100'', ''541899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''542100'', ''542899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''543100'', ''543899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''544100'', ''544699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''550000'', ''554199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''555500'', ''557299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''557400'', ''557699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''561000'', ''563099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''570000'', ''579699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''581000'', ''584699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''586000'', ''587999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''590000'', ''595099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bullsbrook East- Northam- Pinjarra''                                                                                     , ''08'', ''95'', ''599000'', ''599999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''600000'', ''628599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''628700'', ''631899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''632000'', ''636899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''637000'', ''641499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''641600'', ''642899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''643000'', ''644189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''644200'', ''644289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''644300'', ''644389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''644400'', ''644489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''644500'', ''644589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''644600'', ''644689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''644700'', ''644789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''644800'', ''644889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''644900'', ''644989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''645000'', ''647299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''648000'', ''648199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''649000'', ''649089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''649100'', ''649189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''649200'', ''649289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''649300'', ''649389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''649400'', ''649489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''649500'', ''649589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''649600'', ''649689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''649700'', ''649789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''649800'', ''649889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''649900'', ''649989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''650000'', ''653199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''653800'', ''656089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''656100'', ''656189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''656200'', ''656289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''656300'', ''656389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''656400'', ''656489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''656500'', ''656589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''656600'', ''656689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''656700'', ''656789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''656800'', ''656889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''656900'', ''656989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''657100'', ''661299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''662100'', ''662199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''663000'', ''663199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''664000'', ''664599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''665000'', ''665199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''666000'', ''666399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''667000'', ''667199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''668000'', ''668199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''670000'', ''670089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''670100'', ''670189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''670200'', ''670289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''670300'', ''670389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''670400'', ''670489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''670500'', ''670589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''670600'', ''670689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''670700'', ''670789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''670800'', ''670889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''670900'', ''670989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''671000'', ''671299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''672000'', ''672399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''673000'', ''673299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''674100'', ''674199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''674300'', ''674499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''674600'', ''674699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''675000'', ''675199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''676000'', ''676089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''676100'', ''676189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''676200'', ''676289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''676300'', ''676389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''676400'', ''676489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''676500'', ''676589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''676600'', ''676689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''676700'', ''676789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''676800'', ''676889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''676900'', ''676989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''677000'', ''677089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''677100'', ''677189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''677200'', ''677289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''677300'', ''677389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''677400'', ''677489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''677500'', ''677589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''677600'', ''677689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''677700'', ''677789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''677800'', ''677889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''677900'', ''677989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''678000'', ''678089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''678100'', ''678189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''678200'', ''678289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''678300'', ''678389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''678400'', ''678489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''678500'', ''678589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''678600'', ''681199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''681400'', ''681599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''682000'', ''682199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''682500'', ''682699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''683000'', ''683299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''684000'', ''685299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''686000'', ''687399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''689000'', ''689599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''690100'', ''690299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''690800'', ''690999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''691100'', ''691199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''692100'', ''692199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''693100'', ''693199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Moora- Northam- Wongan Hills- Wyalkatchem- York''                                                                        , ''08'', ''96'', ''694000'', ''699999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''700000'', ''742299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''742400'', ''742499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''742700'', ''742799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''742900'', ''742999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''743200'', ''743599'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''743800'', ''744099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''744200'', ''744399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''744600'', ''744799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''744900'', ''745999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''746100'', ''746899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''747100'', ''747899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''748100'', ''748899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''749100'', ''749899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''750000'', ''763899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''764000'', ''774899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''775000'', ''778899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''779100'', ''782999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''783100'', ''783899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''784100'', ''784899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''785100'', ''785899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''786100'', ''786899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''787100'', ''787899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''788100'', ''788899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''789100'', ''789299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''790000'', ''790899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Bridgetown- Bunbury- Busselton- Pinjarra''                                                                               , ''08'', ''97'', ''791000'', ''799999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''800000'', ''822279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''822300'', ''822309'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''822320'', ''822389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''822400'', ''822409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''822420'', ''822489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''822500'', ''822509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''822520'', ''822589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''822600'', ''822639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''822650'', ''822689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''822700'', ''823609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''823620'', ''823689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''823700'', ''823709'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''823720'', ''823789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''823800'', ''823809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''823820'', ''823889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''823900'', ''823909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''823920'', ''823989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824000'', ''824209'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824220'', ''824289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824300'', ''824309'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824320'', ''824389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824400'', ''824489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824500'', ''824509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824520'', ''824589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824600'', ''824609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824620'', ''824689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824700'', ''824709'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824720'', ''824789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824800'', ''824809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824820'', ''824889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824900'', ''824909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''824920'', ''824989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''825000'', ''825039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''825050'', ''825089'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''825100'', ''825209'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''825220'', ''825289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''825300'', ''829209'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829220'', ''829289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829300'', ''829309'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829320'', ''829389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829400'', ''829409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829420'', ''829489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829500'', ''829509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829520'', ''829589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829600'', ''829709'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829720'', ''829789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829800'', ''829809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829820'', ''829889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829900'', ''829939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''829950'', ''829989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''830000'', ''831899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''832000'', ''833309'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''833320'', ''833389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''833400'', ''833409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''833420'', ''833489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''833500'', ''833509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''833520'', ''833589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''833600'', ''834409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''834420'', ''834489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''834500'', ''834509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''834520'', ''834589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''834600'', ''834709'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''834720'', ''834789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''834800'', ''834809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''834820'', ''834889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''834900'', ''834939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''834950'', ''834989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''835000'', ''836309'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''836320'', ''836389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''836400'', ''836439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''836450'', ''836479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''836500'', ''836509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''836520'', ''836589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''836600'', ''836709'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''836720'', ''836789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''836800'', ''836839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''836850'', ''836889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''836900'', ''836909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''836920'', ''836989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837000'', ''837239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837250'', ''837269'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837280'', ''837289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837300'', ''837339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837350'', ''837389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837400'', ''837509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837520'', ''837589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837600'', ''837609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837620'', ''837689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837700'', ''837709'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837720'', ''837789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837800'', ''837809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837820'', ''837889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837900'', ''837909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''837920'', ''837989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''838000'', ''840499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''840600'', ''851609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''851620'', ''851689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''851700'', ''851809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''851820'', ''851889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''851900'', ''851909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''851920'', ''851989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''852400'', ''852899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''853000'', ''854409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''854420'', ''854489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''854500'', ''854509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''854520'', ''854589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''854600'', ''854609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''854620'', ''854689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''854700'', ''854709'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''854720'', ''854769'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''854780'', ''854789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''854800'', ''854839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''854850'', ''854889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''854900'', ''854939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''854950'', ''854989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855000'', ''855309'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855320'', ''855389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855400'', ''855409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855420'', ''855489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855500'', ''855509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855520'', ''855589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855600'', ''855609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855620'', ''855689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855700'', ''855739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855750'', ''855789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855800'', ''855809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855820'', ''855889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855900'', ''855909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''855920'', ''855989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''856000'', ''861439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''861450'', ''861489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''861500'', ''861539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''861550'', ''861589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''861600'', ''872899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''873000'', ''875899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''876000'', ''884399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''884500'', ''889199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''889300'', ''890309'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''890320'', ''890389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''890400'', ''890409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''890420'', ''890489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''890500'', ''890509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''890520'', ''890589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''890600'', ''890609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''890620'', ''890689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''890700'', ''890709'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''890720'', ''890789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''890800'', ''890889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''890900'', ''890909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''890920'', ''890989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891000'', ''891239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891250'', ''891289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891300'', ''891309'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891320'', ''891389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891400'', ''891439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891450'', ''891489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891500'', ''891589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891600'', ''891639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891650'', ''891689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891700'', ''891709'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891720'', ''891789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891800'', ''891809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891820'', ''891889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891900'', ''891909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''891920'', ''891989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''892000'', ''893109'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893120'', ''893189'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893200'', ''893239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893250'', ''893289'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893300'', ''893339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893350'', ''893389'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893400'', ''893409'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893420'', ''893489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893500'', ''893509'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893520'', ''893589'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893600'', ''893609'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893620'', ''893689'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893700'', ''893739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893750'', ''893789'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893800'', ''893809'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893820'', ''893889'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893900'', ''893909'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''893920'', ''893989'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Albany- Katanning- Kondinin- Narrogin- Wagin''                                                                           , ''08'', ''98'', ''894000'', ''899999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''900000'', ''900939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''900950'', ''900979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''900990'', ''922739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''922750'', ''922779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''922800'', ''922839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''922850'', ''922879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''922900'', ''922939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''922950'', ''922979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''923000'', ''928899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''929000'', ''930039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930050'', ''930079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930100'', ''930139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930150'', ''930179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930200'', ''930239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930250'', ''930279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930300'', ''930339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930350'', ''930379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930400'', ''930439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930450'', ''930479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930500'', ''930539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930550'', ''930579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930600'', ''930639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930650'', ''930679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930700'', ''930739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930750'', ''930779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930800'', ''930839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930850'', ''930879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930900'', ''930939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''930950'', ''930979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''931000'', ''932079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932100'', ''932139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932150'', ''932179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932200'', ''932239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932250'', ''932279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932300'', ''932339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932350'', ''932379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932400'', ''932439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932450'', ''932479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932500'', ''932539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932550'', ''932579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932600'', ''932659'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932700'', ''932739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932750'', ''932779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932800'', ''932839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932850'', ''932879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932900'', ''932939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''932950'', ''932979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''933000'', ''935899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''936000'', ''937899'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''938000'', ''939039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939050'', ''939079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939100'', ''939139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939150'', ''939179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939200'', ''939239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939250'', ''939279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939300'', ''939339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939350'', ''939379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939400'', ''939439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939450'', ''939479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939500'', ''939539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939550'', ''939579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939600'', ''939639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939650'', ''939679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939700'', ''939739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939750'', ''939779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939800'', ''939839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939850'', ''939879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939900'', ''939939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''939950'', ''939979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940000'', ''940039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940050'', ''940079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940100'', ''940139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940150'', ''940179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940200'', ''940239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940250'', ''940279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940300'', ''940339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940350'', ''940379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940400'', ''940439'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940450'', ''940479'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940500'', ''940539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940550'', ''940579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940600'', ''940639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940650'', ''940679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940700'', ''940739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940750'', ''940779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940800'', ''940839'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940850'', ''940879'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940900'', ''940939'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''940950'', ''940979'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''941000'', ''944039'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944050'', ''944079'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944100'', ''944139'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944150'', ''944179'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944200'', ''944239'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944250'', ''944279'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944300'', ''944339'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944350'', ''944379'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944400'', ''944489'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944500'', ''944539'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944550'', ''944579'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944600'', ''944639'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944650'', ''944679'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944700'', ''944739'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''944750'', ''944779'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''945000'', ''946999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''947800'', ''948699'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''949000'', ''951399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''951600'', ''953399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''954100'', ''954199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''954300'', ''954999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''955100'', ''955299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''955600'', ''956999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''957100'', ''957499'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''957800'', ''960199'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''960500'', ''965999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''971000'', ''973799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''980000'', ''980399'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''980600'', ''980799'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''981000'', ''981999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''983000'', ''983999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''992000'', ''992099'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''993000'', ''993299'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Carnamah- Carnarvon- Geraldton- Meekatharra- Morawa- Mullewa- Wongan Hills''                                             , ''08'', ''99'', ''994000'', ''995999'', ''Fijo'' , ''Fijo'')
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''00'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''01'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''02'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''03'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''04'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''05'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''06'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''07'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''08'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''09'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''10'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''11'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''12'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''13'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''14'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''15'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''16'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''17'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''18'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''19'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''20'', ''000000'', ''029999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''20'', ''100000'', ''109999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''20'', ''200000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''21'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''22'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''23'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''24'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''25'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''26'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''27'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''28'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''29'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''30'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''31'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''32'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''33'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''34'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''35'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''37'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''38'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''39'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''44'', ''400000'', ''499999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''47'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''48'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''49'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''50'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''51'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''52'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''53'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''55'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''56'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''57'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''58'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''59'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''66'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''67'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''68'', ''300000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''69'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''70'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''77'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''78'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''79'', ''000000'', ''199999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''81'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''82'', ''000000'', ''099999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''87'', ''000000'', ''099999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''88'', ''000000'', ''099999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''89'', ''840000'', ''849999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''90'', ''000000'', ''399999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''97'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''98'', ''000000'', ''999999'', ''Movil'', ''CPP'' )
insert into seriesAU values (''Australia''                                                                                                              , ''04'', ''99'', ''000000'', ''999999'', ''Movil'', ''CPP'' )'

	EXEC(@Sql)

		set @Sql='update ccsettings 
set detalle = ''1:Mexico, 2:Argentina, 3:Colombia, 4:USA, 5:Chile, 6: Venezuela, 7: Reino Unido, 8: Arabia saudita, 9: Australia'' 
where setting_id = 104'

	EXEC(@Sql)

		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
@User_id smallint 
AS 
set nocount on
	select a1.cam_id, cam_Descripcion
	 , cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
	 , cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
	 , cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
	 , detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
	 , cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
	 , stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, cam_maxqueue as queSize,
	 DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg 
	 from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id) 
	 where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
	 order by cam_descripcion
	return(0)
 set nocount off'
	
	EXEC(@Sql)
	
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
@cam_id smallint,
@cam_descripcion varchar(40) = null,
@cam_tnotas smallint = null,
@cam_ocupado tinyint = null,
@cam_NoInt_ocupado tinyint = null,
@cam_inter_ocupado smallint = null,
@cam_nocontesto tinyint = null,
@cam_NoInt_nocontesto tinyint = null,
@cam_inter_nocontesto smallint = null,
@cam_fax tinyint = null,
@cam_NoInt_fax tinyint = null,
@cam_inter_fax smallint = null,
@cam_ModoManual tinyint= null,
@ANI varchar(15) = null,
@cam_ShowCalifWnd bit = null,
@cam_StartTimerOnHangUp bit = null,
@editableCallKey bit = null, 
@cam_tNoContesta tinyint = null,
@cam_intensive_dialing tinyint = null, 
@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
@compliance TinyInt = null, 
@cam_inter_graba smallint = null,
@cam_NoInt_graba tinyint = null,
@progDial smallint = null,
@excCallBack Tinyint = null,
@dialOrder Tinyint = null,
@dialPrefix varchar(10) = null,
@dialPrefixMan varchar(10) = null,
@dialPrefixXfe varchar(10) = null,
@listenManualCall bit = null,
@stopRecording bit = null,
@abandonCallback bit = null,
@autoCB smallint = null,
@id_listAni int = null,
@tDialonWrapUp smallint = null,
@quesize smallint=null,
@DNCScrub int=null,
@callerIdDesc varchar(15)=null,
@timeZoneRule int=null,
@callsBySurvey int=null,
@ivrScript int=null,
@surveyPctg int=null
as
set nocount on
UPDATE ccCamps SET 
 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
 cam_fax = isnull(@cam_fax,cam_fax),
 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
 ANI = isnull(@ANI,ANI),
 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
 editableCallKey = isnull(@editableCallKey, editableCallKey),
 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial), 
 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine), 
 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
 compliance = isnull(@compliance, compliance),
 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
 progDial = isnull(@progDial, progDial),
 excCallBack = isnull(@excCallBack,excCallBack),
 dialOrder = isnull(@dialOrder, dialOrder),
 dialPrefix = isnull(@dialPrefix, dialPrefix),
 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
 listenManualCall = isnull(@listenManualCall, listenManualCall),
 stopRecording = isnull(@stopRecording, stopRecording),
 abandonCallback = isnull(@abandonCallback, abandonCallback),
 t_autoCB = isnull(@autoCB,t_autoCB),
 id_anilist = isnull(@id_listAni,id_anilist),
 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
 cam_maxqueue = isnull(@quesize,cam_maxqueue),
 DNCScrub = isnull(@DNCScrub,DNCScrub),
 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
 ivrScript = isnull(@ivrScript,ivrScript),
 surveyPctg = isnull(@surveyPctg,surveyPctg)
Where cam_id = @cam_id 

if @cam_ShowCalifWnd = 1
 begin
	If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
	 begin
		select 0
		return(0)
	 end
	 
	UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
	where cam_id = @cam_id
	select 1
	return(0)
  end

--else
UPDATE ccCamps SET 
cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
where cam_id = @cam_id
return(0)
set nocount off'
		
	EXEC(@Sql)
	
		set @Sql='ALTER procedure [dbo].[ccsp_AgentSetCallStatus]
@callout_id int,
@cal_id int,
@TipoCall tinyint,	-- 1= IN,  2=Out
@TipoMov tinyint,	-- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
@cal_tXfer tinyint=0,
@cal_tring  smallint=0,
@user_id smallint=0,
@extension varchar(5)=''''
AS
set nocount on

declare @RecicleSIC tinyint
SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id=60
Declare @ANI_x varchar(19)
declare @cal_inicio datetime
declare @callout_id_IN int
declare @cal_key varchar(20)
declare @cam_id int
declare @cal_telefono varchar(30)
declare @surveycamid int
declare @inbound_id int

if @TipoMov=4 or @TipoMov=14 -- DIALOG OnDialog
 begin
	if @TipoCall=2
	 begin
		if @TipoMov = 4
			Update ccoCallsOUT with(rowlock) Set statusCall_id=13 Where cal_id=@cal_id
		else if @TipoMov = 14
			Update ccoCallsOUT with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

		if @RecicleSIC=0
			DELETE ccoWorkingTable with(rowlock) WHERE callout_id=@callout_id

		update ccoCallBacks
		set [status] = 1, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 13

		-- calcula el costo de la llamada
		exec ccsp_CstoCalculaCosto @cal_id

		select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono
		from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
		where callout_id = @callout_id
		and statusCall_id = 13
		and cal_id = @cal_id

		select @surveycamid = isnull(surveycamid,0) from cccamps where cam_id = @cam_id

		if @surveycamid > 0
			begin
				if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100 
				begin
					insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial) 
					values(@cal_id + '','' + @cal_Key,@surveycamid,@cal_telefono,1, dateadd(mi, 6, getdate()))
				end
			end

		return(0)
	end

	if @TipoMov = 4
		Update ccCallsIN with(rowlock) Set statusCall_id=13 Where cal_id=@cal_id
	else if @TipoMov = 14
		Update ccCallsIN with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

	-- Elimina callback generado por abandono
	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x
	
	update ccoCallBacks with(rowlock)
	set [status] = 1, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	DELETE ccoWorkingTable with(rowlock) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon WHERE cal_ANI=@ANI_x

	select @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani
	from ccCallsIN with(index(IX_ccCallsIn_6),nolock)
	where cal_id = @cal_id
	and statusCall_id = 13

	select @surveycamid = isnull(cam_id,0) from ccinbound where inbound_id = @inbound_id

	if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
		begin
			if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100 
			begin
				insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial) 
				values(@cal_id + '','' + @cal_Key,@surveycamid,@cal_telefono,1, dateadd(mi, 6, getdate()) )
			end
		end

	return(0)
 end

if @TipoMov=7 --OTHER OFFHook_OnXfer
 begin
	if @cal_id<=0
		return(0)

	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 16

		exec ccsp_CstoCalculaCosto @cal_id
		return(0)
	 end

	Update ccCallsIN with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock) 
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

if  @TipoMov=9 --RING CallNoAnswered
 begin
	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 15

		exec ccsp_CstoCalculaCosto @cal_id
	 end
	
	Update ccCallsIN with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock) 
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

set nocount off'
			
	EXEC(@Sql)
	
		set @Sql='ALTER procedure [dbo].[ccsp_DLRSaveDialResult]
@callout_id int,
@cam_id smallint,
@tipoResDial_id tinyint,
@Telefono varchar(30),
@Puerto smallint,
@tDialing tinyint=0,
@tBusy smallint=0,
@call_id int = 0,
@answerbit bit = null,
@tAnswerBit smallint = 0,
@canceledNoAgents bit =0
AS
set nocount on
declare @tNow as datetime, @RecicleSIC tinyint
declare @logDial_id int
declare @tAnswerBitFinal as datetime

SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id = 60
select @tNow=getdate()

select @tAnswerBitFinal = dateadd(ss,-@tAnswerBit,@tNow)

if @call_id > 0 and @tipoResDial_id = 1
BEGIN
	INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents)
	select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''0000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents
END
ELSE
BEGIN
	INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, tAnswerBit, canceledNoAgents)
	select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''0000000'', @tAnswerBitFinal, @canceledNoAgents
END

select @logDial_id=scope_identity()

if (@RecicleSIC=1)
 begin
	UPDATE ccoWorkingTable SET tipoResDial_id = @tipoResDial_id where callout_id = @callout_id
 end

select @logDial_id

-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
if @call_id > 0 and @tipoResDial_id = 1
begin
	update ccoCallsOut set cal_manual = 2, cal_puerto = @Puerto	where cal_manual =1 and cal_id = @call_id and cal_puerto = 0
	exec ccsp_CstoCalculaCosto @call_id
end

-- inserta informacion para reportes de workgroup
insert ccRIAWorkGroup_logDial_id (IDWG, logDial_id, cam_id, timestamp)
select IDWG, @logDial_id, IdCampEsp, getdate() 
from ccRIACampEspWG where tipo = 1 and IdCampEsp = @cam_id

-- Guarda configuracion de TipoDialingMode
update ccoLogDials set TipoDialingMode = dbo.fn_getDialingMode(@call_id, 0, @logDial_id, @cam_id) where logDial_id=@logDial_id

set nocount off'
			
	EXEC(@Sql)
	
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer
AS

declare @ld varchar(4), @tel as varchar(30)

insert into cclistanegra values(@telephone, @ln_id)

CREATE TABLE [dbo].[#mycamps] (
	[campsid] [int] NULL )

insert #mycamps
select cam_id from Camplistanegra where idtipolista = @ln_id

CREATE TABLE [dbo].[#mytemp](
	[callout_id] [int] NULL, 
    [telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
    [idtipolista] [int] NULL)

CREATE  UNIQUE  INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) 

select @ld = valor from ccSettings where setting_id = 17
select @tel = dbo.completa(@telephone)

-----------------------------------------------------------------------------  telefono1
insert #mytemp
select callout_id,cal_telefono,cam_id,''3'',@ln_id as idtipolista 
from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono = @tel or cs.cal_telefono = right(@tel, 10)
and cal_fechadial > getdate()-30

if (select count(*) from #mytemp) > 0
begin
	-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
	delete ccoWOrkingTable 
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytemp t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono = wt.cal_telefono
	and rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
						 + cs.cal_telefono3 + ''         ''
						 + cs.cal_telefono4 + ''         ''
						 + cs.cal_telefono5 + ''         ''),13)) = ''''

	-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
	update ccoWOrkingTable 
	set cal_telefono = rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
										+ cs.cal_telefono3 + ''         ''
										+ cs.cal_telefono4 + ''         ''
										+ cs.cal_telefono5 + ''         ''),13))
	from ccoCallsOutSource cs 
	inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono= wt.cal_telefono

	---insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytemp

	-- Eliminamos el telefono1 de CS
	update ccoCallsOutSource 
	set cal_telefono = ''''
	from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30

	truncate table #mytemp
end

----------------------------------------------------------------------------------- -telefono 2

insert #mytemp
select callout_id,cal_telefono2,cam_id,''3'',@ln_id as idtipolista 
from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono2 = @tel or cs.cal_telefono2 = right(@tel, 10)
and cal_fechadial >  getdate()-30

if (select count(*) from #mytemp) > 0
begin
	-- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
	delete ccoWOrkingTable 
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytemp t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono2= wt.cal_telefono 
	and rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
						 + cs.cal_telefono4 + ''         ''
						 + cs.cal_telefono5 + ''         ''),13)) = ''''

	-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
	update ccoWOrkingTable 
	set cal_telefono = rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
										+ cs.cal_telefono4 + ''         ''
										+ cs.cal_telefono5 + ''         ''),13))
	from ccoCallsOutSource cs 
	inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono2= wt.cal_telefono

	---insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytemp

	-- Eliminamos el telefono2 de CS
	update ccoCallsOutSource 
	set cal_telefono2 = ''''
	from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30

	truncate table #mytemp
end

----------------------------------------------------------------------------------- -telefono 3

insert #mytemp
select callout_id,cal_telefono3,cam_id,''3'',@ln_id as idtipolista 
from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono3 = @tel or cs.cal_telefono3 = right(@tel, 10)
and cal_fechadial > getdate()-30

if (select count(*) from #mytemp) > 0
begin
	-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
	delete ccoWOrkingTable 
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytemp t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono3= wt.cal_telefono  
	and  rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
						  + cs.cal_telefono5 + ''         ''),13)) = ''''

	-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
	update ccoWOrkingTable 
	set cal_telefono = rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
										+ cs.cal_telefono5 + ''         ''),13))
	from ccoCallsOutSource cs 
	inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono3= wt.cal_telefono

	---insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytemp

	-- Eliminamos el telefono3 de CS
	update ccoCallsOutSource 
	set cal_telefono3 = ''''
	from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30

	truncate table #mytemp

	----------------------------------------------------------------------------------- -telefono 4

	insert #mytemp
	select callout_id,cal_telefono4,cam_id,''3'',@ln_id as idtipolista 
	from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cs.cal_telefono4 = @tel or cs.cal_telefono4 = right(@tel, 10)
	and cal_fechadial > getdate()-30

	-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
	delete ccoWOrkingTable 
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytemp t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono4= wt.cal_telefono 
	and rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13)) = ''''

	-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
	update ccoWOrkingTable 
	set cal_telefono = rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13))
	from ccoCallsOutSource cs 
	inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono4= wt.cal_telefono

	---insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytemp

	-- Eliminamos el telefono4 de CS
	update ccoCallsOutSource 
	set cal_telefono4 = ''''
	from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30

	truncate table #mytemp
end

----------------------------------------------------------------------------------- -telefono 5

insert #mytemp
select callout_id,cal_telefono5,cam_id,''3'',@ln_id as idtipolista 
from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono5 = @tel or cs.cal_telefono5 = right(@tel, 10)
and cal_fechadial > getdate()-30

if (select count(*) from #mytemp) > 0
begin
	-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
	delete ccoWOrkingTable 
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytemp t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono5= wt.cal_telefono

	---insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytemp

	-- Eliminamos el telefono5 de CS
	update ccoCallsOutSource 
	set cal_telefono5 = ''''
	from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30
end

drop table #mytemp
drop table [dbo].[#mycamps]'
			
	EXEC(@Sql)
	
		set @Sql='ALTER procedure [dbo].[ccsp_Limpia]
@tel varchar(30),
@Camp int = 0
as
set nocount on
declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint 
select @tel = dbo.limpia(@tel)
select @lon = len(@tel)
select @ld = valor from ccsettings where setting_id = 17
select @pais = valor from ccsettings where setting_id = 104
select @extLen = valor from ccsettings where setting_id = 108
declare @telTemp as varchar(15)

if @extLen=@lon and @lon>1
 begin
	select 0 as res, @tel as tel -- Extension
	return(0)
 end	
	
if @pais = 1 
 begin
	if @lon < 7 or @lon = 7 and len(@ld) = 2 or @lon = 8 and len(@ld) = 3 or @lon in (9, 11) or @lon > 13
	 begin
		select 1 as res, @tel as tel --Longitud invalida
		return(0)
	 end

	if @lon = 12 and left(@tel, 2) <> ''01'' or @lon = 13 and left(@tel, 3) <> ''044'' and left(@tel, 3) <> ''045'' and left(@tel, 3) <> ''001''
	 begin
		select 2 as res, @tel as tel--Digitos incorrectos
		return(0)
	 end

	if left(@tel, 3) = ''001'' 
	 begin
		select 0 as res, @tel as tel
		return(0)
	 end

	declare @mod varchar(5)
	select @tel = case when @lon in (7, 8) then @ld + @tel else right(@tel, 10) end
	select @mod = modalidad from series where cld + serie = left(@tel, 6) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

	if exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra))
	on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
	 begin
		select 4 as res, @tel as tel
		return(0)
	 end 

	if @mod = ''CPP'' 
	 begin
		select 0 as res, case left(@tel, len(@ld)) when @ld then ''044'' else ''045'' end + @tel as tel
		return(0)
	 end

	if @mod in (''FIJO'', ''MPP'') 
	 begin
		select 0 as res, case left(@tel, len(@ld)) when @ld then right(@tel, 10 - len(@ld)) else ''01'' + @tel end as tel
		return(0)
	 end

	--if @mod is null 
	select 3 as res, @tel as tel--No encontrado					
	return(0)
 end

if @pais = 2 
 begin	
	select @telTemp = @tel
	set @tel = dbo.completa(@tel)
	if left(@tel,1)=''E'' begin
		select 1 as res, @telTemp --Longitud Invalida
		return
	end

	select @tel = dbo.fnClearPhoneArg(@tel)

	if len(@tel) = 10 and left(@tel,1) <> ''E'' begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
	   begin				
			select  @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		end else begin
			select 4 as res, @tel
			return(0)
		end
	end else begin select 2 as res, @telTemp as tel end --Digitos incorrectos 
 end

if @pais = 3 
 begin
	select @telTemp = @tel
	if @lon < 7 or @lon = 9 or (@lon = 10 and  left(@telTemp,1) <> ''3'') or (@lon = 11 and  left(@telTemp,2) <> ''03'') begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	end
	select @tel = dbo.Completa_ListaNegra(@tel)

	if (len(@tel) = 8 or len(@tel) = 10) and left(@tel,1) <> ''E'' 
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin		 		
			select @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end 
		else 
		 begin
			select 4 as res, @tel
			return(0)
		 end		
	 end 
	else 
	 begin 
		select 2 as res, @telTemp as tel 
	 end --Digitos incorrectos 
 end

if @pais = 4
 begin
	exec ccsp_LimpiaUsa @tel, @Camp
	return(0)
 end

if @pais = 5 
 begin	
	select @telTemp = @tel
	if left(@tel,1)=''E'' 
	 begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	 end

	select @tel = dbo.Completa_ListaNegra(@tel)

	if len(@tel) in(8,9) and left(@tel,1) <> ''E'' 
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin		 		
			select  @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end 
		else 
		 begin
			select 4 as res, @tel
			return(0)
		 end		
	 end 
	else 
	 begin 
		select 2 as res, @telTemp as tel 
	 end --Digitos incorrectos 
 end

if @pais = 6
 begin
	select @telTemp = @tel
	if left(@tel,1)=''E'' 
	 begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	 end

	select @tel = dbo.Completa_ListaNegra(@tel)


	if len(@tel) = 10 and left(@tel,1) <> ''E'' 
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin		 		
			select @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end 
		else 
		 begin
			select 4 as res, @tel
			return(0)
		 end		
	 end 
	else 
	 begin 
		select 2 as res, @telTemp as tel 
	 end --Digitos incorrectos 
 end

if @pais = 7
 begin	
	select @telTemp = @tel
	if left(@tel,1)=''E'' 
	 begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	 end

	select @tel = dbo.Completa_ListaNegra(@tel)

	if (len(@tel) = 9 or len(@tel) = 10) and left(@tel,1) <> ''E'' 
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin		 		
			select @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end 
		else 
		 begin
			select 4 as res, @tel
			return(0)
		 end		
	 end 
	else 
	 begin 
		select 2 as res, @telTemp as tel 
	 end --Digitos incorrectos 
 end


if @pais = 8
 begin
	select @telTemp = @tel
	select @tel = dbo.Completa_ListaNegra(@tel)

	if left(@tel,1)=''E'' begin
		select 1 as res, @telTemp --Longitud Invalida
		return (0)
	end

	if (len(@tel) = 9 or len(@tel) = 10 or len(@tel) = 11 )
	begin
		if not exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra)) on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		begin
			select  @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		end
		else 
		begin
			select 4 as res, @tel
			return(0)
		end
	end
 end

if @pais = 9 --Australia
 begin
	select @telTemp = @tel
	select @tel = dbo.Completa_ListaNegra(@tel)

	if left(@tel,1)=''E'' 
		begin
			select 1 as res, @telTemp --Longitud Invalida
			return (0)
		end
	else
		begin
			if not exists(select a2.idtipolista 
						  from cclistanegra a1 
						  inner join camplistanegra a2 with(index(IX_Camplistanegra)) 
						  on (a1.idtipolista=a2.idtipolista) 
						  where cam_id=@Camp 
						  and telefono = @tel 
						  and status=1)
				begin
					select  @tel = dbo.verifica(@tel)
					if left(@tel,1) <> ''E''
						begin
							select 0 as res, @tel
							return(0)
						end
					else
						begin
							select 2 as res, @telTemp as tel 
							return(0)
						end
				end
			else 
				begin
					select 4 as res, @tel
					return(0)
				end
		end
 end

set nocount off'
			
	EXEC(@Sql)
	
		set @Sql='ALTER procedure [dbo].[ccsp_OUTInsertaCallBack]
@cal_id int,
@Telefono varchar(15),
@Camp smallint,
@FechaDial smalldatetime,
@callout_id int=0,
@TelReprograma smallint=-1,
@user_id int=0,
@cal_Key varchar(33)=''''
as
set nocount on
IF @TelReprograma<0
      return(0)
 
declare @Fecha smalldatetime, @sSQL nvarchar(max)
declare @iZonaHoraria int,@iZonaHoraria_verano int,@iZonaHoraria2 int, @iZonaHoraria_verano2 int,@iZonaHoraria3 int,@iZonaHoraria_verano3 int,@iZonaHoraria4 int,@iZonaHoraria_verano4 int,@iZonaHoraria5 int,@iZonaHoraria_verano5 int
declare @idZone int, @idZoneDaylight int
declare @bIsDaylight bit, @difference int
declare @TelOriginal varchar(15)
declare @FechaOriginal datetime
 
select @callout_id = callout_id, @TelOriginal = cal_telefono, @FechaOriginal = cal_Inicio
from ccocallsout
where Cal_id=@cal_id
 
IF @TelReprograma=0 --Otro telefono
BEGIN
      declare @tel2 varchar(20), @tel3 varchar(20), @tel4 varchar(20), @tel5 varchar(20)
      declare @phoneCompleted varchar(20)
      declare @emptyPhoneMsg varchar(50)
 
      select @idZone = dbo.fnGetTimeZone(@Telefono,0)
      select @idZoneDaylight = dbo.fnGetTimeZone(@Telefono,1)
      select @phoneCompleted = dbo.Completa(@Telefono)
      select @emptyPhoneMsg = case valor when 0 then ''El teléfono no puede ser nulo o vacío'' else ''Phone number can not be null or empty'' end from ccsettings where setting_id = 27
 
      if charIndex(''E_NV'',@phoneCompleted) > 0
            set @phoneCompleted = @Telefono
            if @phoneCompleted = ''''
            begin
                  raiserror(@emptyPhoneMsg, 18, 1)
            end
 
     select @tel2=cal_telefono2,@tel3=cal_telefono3,@tel4=cal_telefono4,@tel5=cal_Telefono5,@cal_Key=cal_key
     from ccoCallsoutSource where callout_id=@callout_id
     
      select @TelReprograma=case when isnull(@tel4,'''')='''' then 4 when isnull(@tel3,'''')='''' then 3     when isnull(@tel2,'''')='''' then 2 else 5 end
 
      select @sSQL=''update ccoCallsOutSource set cal_telefono''+cast(@TelReprograma as varchar(1))+''=''''''+@phoneCompleted+''''''''
      +'',cal_status=2,dial_Tels=''''''+cast(@TelReprograma as char(1))+replace(''2345NNN'',cast(@TelReprograma as char(1)),''1'')+''''''''
      +'', iZonaHoraria''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZone as varchar(10))+'', iZonaHoraria_Verano''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZoneDaylight as varchar(10))+'' where callout_id=''+cast(@callout_id as varchar(10))
      exec(@sSQL)
END
 
ELSE--@>0 telefono ya existente
BEGIN
      update ccoCallsOutSource set cal_status=2,
      dial_Tels=cast(@TelReprograma as char(1))+ replace(''2345NNN'',cast(@TelReprograma as char(1)),''1'')
      where callout_id=@callout_id
 
      select @sSQL= N''select @outA=cal_key, @outB=izonahoraria'' +replace( cast( @TelReprograma as varchar(1)), ''1'', '''' )+'', @outC=izonahoraria_verano''+replace( cast( @TelReprograma as varchar(1)), ''1'', '''' )+'', @outD= rtrim(left(ltrim(cal_telefono + ''''        ''''
            + cal_telefono2 + ''''         ''''
            + cal_telefono3 + ''''         ''''
            + cal_telefono4 + ''''         ''''
            + cal_telefono5 + ''''         ''''),13)) from ccoCallsOutSource where callout_id = '' +cast(@callout_id as varchar)
      exec sp_executesql @sSQL, N''@outA varchar(33) OUTPUT, @outB int OUTPUT, @outC int OUTPUT, @outD varchar(19) OUTPUT'', @outA=@cal_Key OUTPUT, @outB=@idZone OUTPUT, @outC=@idZoneDaylight OUTPUT, @outD=@Telefono OUTPUT
END
 
-- PARA LA FECHA
declare @country_id as int
select @country_id = valor from ccsettings where setting_id = 104
      select @bIsDaylight=case when getdate()between inicio and fin then 1 else 0 end from ccHorarioVerano where year(getdate())=year(inicio) and country_id = @country_id
 
select @difference = dbo.fnGetTimeDifference(case when @bIsDaylight = 0 then @idZone else @idZoneDaylight end)
select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))    
update ccoCallsOut set cal_fcallback=@FechaDial where cal_id=@cal_id
 
--PARA LAS ESTADISTICAS
if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha) and mes=month(@Fecha) and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@Camp)
      update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@Camp
else
      insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@Camp
 
select @iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end, @iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end,
 @iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end, @iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end,
@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end, @iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end,
@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end, @iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end,
@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end, @iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end
from ccocallsoutsource where callout_id=@callout_id
 
if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
      UPDATE ccoWorkingTable SET cal_telefono=@Telefono, cam_id=@Camp,cal_fechaDial=@Fecha,
      cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_Key,
      iZonaHoraria = @iZonaHoraria, iZonaHoraria_Verano = @iZonaHoraria_Verano,
      iZonaHoraria2 = @iZonaHoraria2, iZonaHoraria_Verano2 = @iZonaHoraria_Verano2,
      iZonaHoraria3 = @iZonaHoraria3, iZonaHoraria_Verano3 = @iZonaHoraria_Verano3,
      iZonaHoraria4 = @iZonaHoraria4, iZonaHoraria_Verano4 = @iZonaHoraria_Verano4,
      iZonaHoraria5 = @iZonaHoraria5, iZonaHoraria_Verano5 = @iZonaHoraria_Verano5
      WHERE callout_id=@callout_id
 
else
      INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,
      [user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano,iZonaHoraria2,iZonaHoraria_verano2,iZonaHoraria3,
      iZonaHoraria_verano3,iZonaHoraria4,iZonaHoraria_verano4,iZonaHoraria5,iZonaHoraria_verano5)
      select @callout_id,@Telefono,@Camp,@Fecha,1,3,1,
      @user_id,@cal_Key,@iZonaHoraria,@iZonaHoraria_Verano,@iZonaHoraria2,@iZonaHoraria_Verano2,@iZonaHoraria3,
      @iZonaHoraria_Verano3,@iZonaHoraria4,@iZonaHoraria_Verano4,@iZonaHoraria5,@iZonaHoraria_Verano5
 
      insert ccoCallBacks values(@callout_id,@user_id,@Camp,@cal_Key,@TelOriginal,@Telefono,@FechaOriginal,@Fecha,NULL,0,1)
 
set nocount off'
			
	EXEC(@Sql)
	
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
@user_id integer,
@tel varchar(15)
AS
declare @mask integer, @idioma integer, @value integer, @lada integer
declare @country as tinyint

set @value = 0
select @mask = isnull(dialmask,7) from ccusers where user_id=@user_id
select @country = valor from ccsettings where setting_id = 104

-- Restricciones por pais 1:Mexico 2:Argentina 3:Colombia 4:USA 5:Chile 6:Venezuela 7:uk 8:Arabia Saudita
if @country = 1 
 begin
	--Restringe celulares
	if (@mask & 1)>0
	 begin
		if ((left(ltrim(rtrim(@tel)),3) = ''044'' Or left(ltrim(rtrim(@tel)),3) = ''045''))
		 begin
			set @value = 4
		 end 
	 end	
	
	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if ((left(ltrim(rtrim(@tel)),2) = ''01'') and len(ltrim(rtrim(@tel))) = 12)
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
			 begin
				set @value = 6
			 end
		 end
	 end
 end
	
-- Argentina
if @country = 2 
 begin
	--Restringe celulares
	if ((@mask & 1) > 0)
	 begin			
		if (left(@tel,2)=''15'') or (len(@tel)>=13 and substring(@tel,1,1)=''0'' and 
			(substring(@tel,4,2)=''15'' or substring(@tel,5,2)=''15'' or substring(@tel,3,2)=''15''))
		 begin
			set @value = 4
		 end 
	 end
	
	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if ((left(ltrim(rtrim(@tel)),2) = ''0'') and len(ltrim(rtrim(@tel))) = 11)
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask&4)>0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
			 begin
				set @value=6
			 end
		 end
	 end
 end

if @country = 3 --Colombia
 begin
	--Restringe Celulares
	if ((@mask & 1) > 0)
	 begin
		if len(@tel) > 8
		 begin
			set @value = 4
		 end 
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if len(@tel) = 8 or left(@tel,1) = ''0''
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
			 begin
				set @value = 6
			 end
		 end
	 end
 end

if @country = 4 --USA
 begin
	--Restringe larga distancia usa
	if ((@mask & 2) > 0)
	 begin
		if len(ltrim(rtrim(@tel))) >= 11  and (left(ltrim(rtrim(@tel)),1) = ''1'')
		 begin
			set @value = 5
		 end
	 end

	--Restringe locales usa
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			--if Len(ltrim(rtrim(@tel))) = 7
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
			 begin
				set @value = 6
			end
		 end
	 end
 end

--Chile
if @country = 5 
 begin

		--Restringe Celulares
	if ((@mask & 1) > 0)
	 begin
		if len(@tel) >= 10 and left(@tel,2) = ''09''
		 begin
			set @value = 4
		 end 
	 end

		--Restringe Locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin				
			if Len(@tel) in (6,7)
			 begin
				set @value = 6
			 end
		 end
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if len(@tel) >= 8 and len(@tel) < 10
			 begin
				set @value = 5
			 end
		 end
	 end
 end

--Venezuela
if @country = 6
begin
		--Restringe Celulares
	if ((@mask & 1) > 0)
	 begin
		if len(@tel) >= 10 and left(@tel,2) = ''04''
		 begin
			set @value = 4
		 end 
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if len(@tel) >= 10 and left(@tel,1) = ''0''
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
			 begin
				set @value = 6
			 end
		 end
	 end

end

--United Kingdom
if @country = 7
begin
		--Restringe Celulares
	if ((@mask & 1) > 0)
	 begin
		if (len(@tel) >= 9) and left(@tel,2) = ''07''
		 begin
			set @value = 4
		 end 
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if len(@tel) >= 9 and left(@tel,1) = ''0''
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			if len(@tel) >= 9 and left(@tel,1) <> ''0''
			 begin
				set @value = 6
			 end
		 end
	 end

end

--arabia saudita
if @country = 8
begin
	
	--Restringe celulares
	if (@mask & 1)>0
	 begin
		if (left(ltrim(rtrim(@tel)),2) = ''05'' and len(ltrim(rtrim(@tel))) = 10 )
		 begin
			set @value = 4
		 end 
	 end	
	
	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if ( left(ltrim(rtrim(@tel)),2) <> ''05'' and len(ltrim(rtrim(@tel))) in (11, 9))
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
			 begin
				set @value = 6
			 end
		 end
	 end
end

--Australia
if @country = 9
begin
	
	--Restringe celulares
	if (@mask & 1)>0
	 begin
		if (left(ltrim(rtrim(@tel)),2) = ''04'' and len(ltrim(rtrim(@tel))) = 10)
		 begin
			set @value = 4
		 end 
	 end	
	
	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if ( left(ltrim(rtrim(@tel)),2) <> ''04'' and len(ltrim(rtrim(@tel))) = 10)
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if ((Len(ltrim(rtrim(@tel))) = 8) or 
			    (''0'' + left(ltrim(rtrim(@tel)),1) = @lada and Len(ltrim(rtrim(@tel))) = 9) or 
				(left(ltrim(rtrim(@tel)),2) = @lada and Len(ltrim(rtrim(@tel))) = 10))
			 begin
				set @value = 6
			 end
		 end
	 end
end

select @value'
			
	EXEC(@Sql)

		set @Sql='ALTER PROCedure [dbo].[ccsp_RIALoadACDGroups]
@option smallint,
@AreaId smallint,
@Sup smallint,
@inbound_id int = 0
AS
set nocount on
if @option = 1 -- Todas los ACDGroups
 begin
	select a1.inbound_id, descripcion, frame, isnull(IDArea,0)
	from ccinbound a1 join ccRIAinboundGraph a2 on (a1.inbound_id = a2.inbound_id)
	join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
	where a3.type_id = 1
	order by descripcion
	return(0)
 end

if @option = 2 -- ACDGroups de un Area
 begin
	select distinct a1.inbound_id, descripcion, frame, isnull(IDArea,0) 
	IDArea, dbo.fn_CampEspWG(a1.inbound_id, 2) relationsWG
	from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	where a3.type_id = 1 and isnull(IDArea, 0) = isnull(@AreaId, 0)
	order by descripcion
	return(0)
 end

if @option = 3 -- ACDGroups por Supervisor
 begin
	select distinct a1.inbound_id, descripcion, frame, isnull(IDArea,0) as IDArea, U.monitored
	from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccSupervisorCam U on a1.inbound_id = U.cam_id
	where U.user_id = @sup
    and tipo = 0
	and a3.type_id = 1 
	and a1.inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@Sup, 2)) 
	order by descripcion
	return(0)
 end

if @option = 4 -- Rels ACD-Agents
 begin
	select inbound_id, descripcion, User_id, Login, skill, prioridad, IDArea, min(rel_id) rel_id
	 from (select E.inbound_id, E.descripcion, A.User_id, A.Login, G.skill, G.prioridad, isnull(E.IDArea, 0) IDArea, G.rel_id
	 from ccinboundAgentes G join ccinbound E on G.inbound_id = E.inbound_id
	 join ccUsers A on A.User_id = G.User_id and A.TipoUser_Id = 1 and A.Status > 0
	 where E.inbound_id in (select cam_id from ccsupervisorcam where user_id = case isnull(@Sup,0) 
	  when 0 then user_id else @Sup end and tipo = 0)) as Relations
	 group by inbound_id, descripcion, User_id, Login, skill, prioridad, IDArea
	order by User_id, inbound_id, descripcion, prioridad
	return(0)
 end

if @option = 5 -- Todos los ACDGroups 
 begin
	option5:
	select a1.inbound_id, descripcion, frame, isnull(IDArea,0)
	from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	where a3.type_id = 1
	order by descripcion
	return(0)
 end

if @option = 7 -- Un solo ACDGroups
 begin
	select a1.inbound_id, descripcion, frame, isnull(IDArea,0)
	from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	where a3.type_id = 1 and status = 1 and a1.inbound_id = @inbound_id
	order by descripcion
	return(0)
 end

if @option = 8 -- ACDGroups de un Agente
 begin
	select distinct a1.inbound_id, a1.descripcion, a3.frame
	from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
	 join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	 join ccInboundAgentes a4 on a1.inbound_id = a4.inbound_id
	where a3.type_id=1 and a4.user_id = @Sup
	order by 2
	return(0)
 end

return(0)
set nocount off'

	EXEC(@Sql)

		set @Sql='ALTER PROCedure [dbo].[ccsp_RIALoadCamps]
@option smallint,
@AreaId smallint = null,
@Sup smallint = null
as
set nocount on
if @option = 1 -- Todas las campañas
begin
      select a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea,0), isnull(DNCscrub,0)
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      where a3.type_id = 1 and a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@Sup, 1))
      order by 5,2
      return(0)
end
 
if @option = 2 -- Campañas de un Area
begin
      select distinct a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea,0)
      IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      where a3.type_id = 1 and isnull(IDArea, 0) = isnull(@AreaId, 0)
      order by cam_descripcion
      return(0)
end
 
if @option = 3 -- Campañas por Supervisor
begin
      select distinct a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(a1.IDArea,0) IDArea
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      join ccSupervisorCam a4 on a1.cam_id = a4.cam_id
      where a3.type_id = 1 and a4.tipo = 1 and a4.user_id = @Sup
      order by 5, 2
      return(0)
end
 
if @option = 4 -- Rels Camps-Agents
begin
      select Login, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea, min(rel_id) rel_id
      from (select A.Login, A.User_id, Prioridad, Skill, C.cam_id, C.cam_descripcion, isnull(C.IDArea,0) IDArea, CA.rel_id
            from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id
            join ccRIACampsGraph a2 on C.cam_id = a2.cam_id
            join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
            join ccUsers A on A.User_id = CA.User_id and A.TipoUser_id = 1 and A.Status = 1
            where C.cam_id in(select cam_id from ccsupervisorcam where user_id = case isnull(@Sup,0)
             when 0 then user_id else @Sup end and tipo=1)) Relations
      group by Login, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea
      order by User_id, cam_descripcion, cam_id, Prioridad
      return(0)
end
 
if @option = 5 -- Campañas por Supervisor
      begin
            select distinct Camps.cam_id, Camps.cam_descripcion, a3.frame, Camps.cam_procesando, isnull(Camps.IDArea,0)IDArea,
            IsNull(CN.New, 0) as New, IsNull(CN.CB, 0) as CB, IsNull(CN.Pro, 0) as Pro,
            IsNull(CN.pen, 0) as Pen, cast(Camps.cam_procesando as int) as St, Camps.cam_TipoJobs as Job,
            isnull(CN.Fin, 0)Fin, isnull(CP.prioridad,''12345NNN'') prioridad, cast(camps.dialorder as tinyint) dialorder,
            cast(camps.progDial as tinyint) progDial, U.monitored
            from ccCamps Camps left join ccCampsPrioridadTel CP on CP.cam_id = Camps.cam_id
            left join ccCampsNvosCB CN on CN.id = Camps.cam_id
            join ccRIACampsGraph a2 on (Camps.cam_id = a2.cam_id)
            join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
            join ccSupervisorCam U on Camps.cam_id = U.cam_id
            where U.user_id = @sup
            and tipo = 1
            and a3.type_id = 1
            and Camps.cam_id in (select cam_id from ccSupervisorCam where tipo = 1 and user_id = @sup)
            order by 5, cam_procesando desc, cam_descripcion
            return(0)
      end
 
if @option = 7 -- Una sola
begin
      select distinct a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(IDArea,0) IDArea
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      where a3.type_id=1 and isnull(a1.cam_id,0)=isnull(@AreaId,0)
      order by 5,2
      return(0)
end
 
if @option = 8 -- Campañas de un Agente
begin
      select distinct a1.cam_id, a1.cam_descripcion, a3.frame
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      join ccCampsAgente a4 on a1.cam_id = a4.cam_id
      where a3.type_id=1 and a4.user_id = @Sup
      order by 2
      return(0)
end
 
return(0)
set nocount off'

	EXEC(@Sql)

		set @Sql='ALTER PROCedure [dbo].[ccsp_RIAManageWG]
@option smallint,
@IDWG smallint,
@Type smallint,
@UserId smallint,
@Descripcion varchar(25),
@IDArea as int
as
set nocount on

if @option = 3 -- Insert WokGroup
 begin
	Insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
	select @IDWG = scope_identity()
			
	Insert into ccRIAAreaWorkGroup(IDWG, IDArea) values(@IDWG, @IDArea)
	select @IDWG
	return(0)
 end

select @Type = TipoUser_id from ccUsers where User_id = @UserId

if @option = 1 -- Insert Agente-Supervisor in WorkGroup
 begin
	if @Type not in(1, 2, 6)
		return(0)

	if exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @UserId)
	 begin
		 select 1
		 return(0)
	 end

	If @Type = 1
	 begin
		
		If (select count(User_id) from ccRIAWorkGroupUsers where User_id = @UserId) > = (select valor from ccSettings where setting_id = 63)
		 begin
			select 3
			return(0)
		 end

		insert into ccRIAWorkGroupUsers(IDWG, User_id) values(@IDWG,@UserId)

		if @IDWG is null or @IDWG = 0
		 begin
			select 38
			return(0)
		 end
		 
		insert into cccampsAgente (user_id, cam_id, prioridad, skill, IDWG)
		select @UserId, idCampEsp, dbo.fn_Calcula_UsrPriority(@UserId,0), 1, @IDWG
		from ccRIACampEspWG where tipo = 1 and IDWG = @IDWG and 
		 idCampEsp not in (select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

		insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, IDWG)
		select @UserId, idCampEsp, 0, dbo.fn_Calcula_UsrPriority(@UserId,0), 1, @IDWG
		from ccRIACampEspWG where tipo = 0 and IDWG = @IDWG and 
		 idCampEsp not in (select inbound_id from ccInboundAgentes where user_id=@UserId and IDWG=@IDWG)
		return(0)
	 end	

	-- -Supervisor	@Type in (2,6)
	insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @UserId)

	insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
	select @UserId, idCampEsp, 0, @IDWG 
	from ccRIACampEspWG where tipo=0 and IDWG=@IDWG 
	 and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

	update ccSupervisorCam
	set monitored = 1
	where user_id = @UserId
	and cam_id in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)
	and tipo = 0
	and IDWG <> @IDWG
	and monitored = 0

	insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
	select @UserId, idCampEsp, 1, @IDWG
	from ccRIACampEspWG where tipo=1 and IDWG=@IDWG 
	 and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)

	update ccSupervisorCam
	set monitored = 1
	where user_id = @UserId
	and cam_id in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
	and tipo = 1
	and IDWG <> @IDWG
	and monitored = 0

	return(0)
 end

if @option = 2 -- Delete Agent-Supervisor from WorkGroup
 begin
	Delete ccRIAWorkGroupUsers where IDWG = @IDWG and User_id = @UserId

	if @Type = 1 -- Agente
	 begin
		delete from cccampsagente where user_id=@UserId and IDWG=@IDWG
		delete from ccInboundagentes where user_id=@UserId and IDWG=@IDWG
		select @Type
		return(0)
	 end
	 
	--else if @Type in(2, 6) -- Supervisor
 	delete ccSupervisorCam where user_id=@UserId and IDWG=@IDWG
	select @Type
	return(0)
end
return(0)
set nocount off'

	EXEC(@Sql)

		set @Sql='ALTER procedure [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp]
@camp_id as int,
@reciclar as int = 1
as
set nocount on

declare @prioridad varchar(8)

Delete ccUploadTemporal with(rowlock)
where cam_id = @camp_id

update ccoCallBacks with(rowlock)
set [status] = 6, schedulerStatus = 1
where callout_id in (select cs.callout_id
from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_11),nolock) 
inner join ccoWorkingTable wt with(index(IX_ccoWorkingTable),nolock)
on cs.cal_key = wt.cal_keyw and cs.cam_id = wt.cam_id 
where cs.cam_id = @camp_id
and wt.cal_status <= 2
and cs.cal_status in(0,7))

update ccoCallsOutSource
set cal_Status = 4 
from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_11),nolock)
inner join ccoWorkingTable wt with(index(IX_ccoWorkingTable),nolock)
on cs.cal_key = wt.cal_keyw and cs.cam_id = wt.cam_id 
where cs.cam_id = @camp_id
and wt.cal_status <= 2
and cs.cal_status in(0,7)

update ccoCallBacks with(rowlock)
set [status] = 6, schedulerStatus = 1
where callout_id in (select Cout.callout_id
from ccoCallsOutSource Cout with(index(IX_ccoCallsOutSource_11),nolock)
JOIN ccoworkingtable Wtab
ON Cout.callout_id = Wtab.callout_id 
WHERE Cout.cam_id = @camp_id 
and (COUT.cal_status < 2 or COUT.cal_status = 7))

update ccoCallsOutSource
set cal_Status = 4 
from ccoCallsOutSource Cout with(index(IX_ccoCallsOutSource_11),nolock)
JOIN ccoworkingtable Wtab
ON Cout.callout_id = Wtab.callout_id 
WHERE Cout.cam_id = @camp_id 
and (COUT.cal_status < 2 or COUT.cal_status = 7)

Insert ccoWorkingTable (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2,
	iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
SELECT callout_id, cam_id, 
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono,
case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key, 
case when len( cal_telefono ) > 0 then iZonaHoraria else null end, case when len( cal_telefono ) > 0 then iZonaHoraria_verano else null end, 
case when len( cal_telefono2 ) > 0 then iZonaHoraria2 else null end, case when len( cal_telefono2 ) > 0 then iZonaHoraria_verano2 else null end, 
case when len( cal_telefono3 ) > 0 then iZonaHoraria3 else null end, case when len( cal_telefono3 ) > 0 then iZonaHoraria_verano3 else null end, 
case when len( cal_telefono4 ) > 0 then iZonaHoraria4 else null end, case when len( cal_telefono4 ) > 0 then iZonaHoraria_verano4 else null end, 
case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end,
list_id
FROM ccoCallsOutSource with(index(IX_ccoCallsOutSource_11),nolock)
WHERE cam_id = @camp_id 
and (cal_status < 2 or cal_status = 7) -- Nuevos Jobs

Insert into ccoCallBacks
SELECT callout_id, user_id, cam_id, cal_key,
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono1,
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono2,cal_fechaDial,cal_fechaDial,NULL,0,1
FROM ccoCallsOutSource with(index(IX_ccoCallsOutSource_11),nolock)
WHERE cam_id = @camp_id 
and (cal_status < 2 or cal_status = 7) -- Nuevos Jobs

select @prioridad = isnull(Prioridad,''12345NNN'') from ccCampsPrioridadTel where cam_id = @camp_id

UPDATE ccoCallsOutSource with(rowlock)
SET cal_status = 2, dial_tels = @prioridad, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) 
and cam_id = @camp_id

set nocount off'

	EXEC(@Sql)

		set @Sql='ALTER PROCEDURE [dbo].[ccspADM_AniListLD]
@type as tinyint,
@idArea as smallint,
@descriptionList as varchar(40) = NULL,
@IdAniLista as smallint = NULL,
@cld as varchar(40)= NULL,
@AniTel as varchar(40)= NULL,
@edo as varchar(40) = NULL
AS
set nocount on
declare @pais tinyint, @listEdos varchar(4000), @idLista as integer, @sql as varchar(500)
select @pais = valor from ccsettings where setting_id = 104

select @listEdos = ''select distinct '' + case @type when 1 then
case @pais	when 1 then ''estado, cld as area '' 
			when 2 then ''estado, cld as area ''
			when 3 then ''municipio as estado, region +''''+ serie as area ''
			when 4 then ''location as estado, area ''
			when 5 then ''cld as estado, cld as area ''
			when 6 then ''region as estado, LD as area ''
			when 7 then ''region as estado, CLD as area ''
			when 8 then ''Regiones as estado, cld +''''-''''+ [serie inicio] as area ''
			when 9 then ''Regiones as estado, LD + AreaCode as area ''
			else '''' end
when 4 then
case @pais	when 1 then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani '' 
			when 2 then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 3 then ''municipio as estado, region +''''+ serie as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 4 then ''location as estado, area, @id_anilist as id_anilist, '''''''' as telani ''
			when 5 then ''cld as estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 6 then ''region as estado, LD as area, @id_anilist as id_anilist, '''''''' as telani '' 
			when 7 then ''region as estado, CLD as area, @id_anilist as id_anilist, '''''''' as telani''
			when 8 then ''Regiones as estado, cld +''''-''''+ [serie inicio] as area, @id_anilist as id_anilist, '''''''' as telani '' 
			when 9 then ''Regiones as estado, LD + AreaCode as area, @id_anilist as id_anilist, '''''''' as telani '' 
			else '''' end end + ''from '' +
case @pais	when 1 then ''series'' 
			when 2 then ''seriesarg where estado <> '''' order by 1'' 
			when 3 then ''seriescol'' 
			when 4 then ''ccTimeZoneArea where id_country = '' + convert(varchar(5),@pais) + '''' 
			when 5 then ''serieschi''
			when 6 then	''SeriesVen''
			when 7 then	''SeriesUK''
			when 8 then ''SeriesSA'' 
			when 9 then ''SeriesAU''
			else '''' end + ''''

if @type = 1 

begin
	exec(@listEdos + '' order by estado'')
	--print(@listEdos + '' order by estado'')
	return(0)
end

if @type = 2 
begin
	select @sql = ''select id_AniList, description from ccEdoAniList where idArea = '' + convert(varchar(5),@idArea) +  case when isnull(@IdAniLista,'''') <> '''' then '' and id_AniList = '' + convert(varchar(5),@IdAniLista) else '''' end
	exec(@sql) 
	return(0)
end

if @type = 3 
begin
	select @sql = ''select id_AniList, Estado, telAni, area from ccEstadosAni where id_AniList = '' + convert(varchar(5),@IdAniLista) + '' and estado like ''''%'' + @edo + ''%'''' and telani <> '''''''' and id_AniList in (select id_AniList from ccEdoAniList where idArea 
= '' +
	 convert(varchar(5),@idArea) + '') order by estado''
	exec(@sql)
	--print(@sql) 
	return(0)
end

if @type = 4 
begin  --insert new aniList
	if @descriptionList <> '''' begin
		if exists(select * from dbo.ccEdoAniList where [description] = @descriptionList )
		 begin
			--raiserror(''ERROR. invalid ID'', 18, 1)
			select 1 
			return(0)
		 end 
		insert into ccEdoAniList values(@descriptionList, @idArea)
		select @idLista = id_anilist from ccEdoAniList where [description] = @descriptionList
		set @listEdos = ''insert into ccEstadosAni (estado, area, id_anilist, telani) '' + @listEdos
		set @listEdos = replace(@listEdos, ''@id_anilist'', convert(varchar(6),@idLista))
		exec(@listEdos)
		--print(@listEdos)
	end
	return(0)
end

if @type = 5 
begin --update ccEstadosAni
	if not exists(select * from dbo.ccEstadosAni WHERE id_anilist = @IdAniLista and area = @cld )
	 begin
		--raiserror(''ERROR. invalid ID'', 18, 1) 
		select 1
		return(0)
	 end 

	update ccEstadosAni set telani= ISNULL(@AniTel, TELANI) WHERE id_anilist = @IdAniLista and area = @cld
	if @@rowcount>0
		select 0 id, [description]+''(Ld:''+cast(@cld as varchar(10))+'')'' [description] from ccEdoAniList WHERE id_anilist = @IdAniLista
	return(0)
end

if @type = 6 
begin --borra listas
	if not exists(select id_anilist from ccEdoAniList WHERE id_anilist = @IdAniLista and idarea = @idArea )
	 begin
		select 1
		return(0)
	 end 

	select @descriptionList=[description] from ccEdoAniList WHERE id_anilist = @IdAniLista and idarea = @idArea
	delete from ccEstadosAni where id_anilist = @IdAniLista
	delete from ccEdoAniList WHERE id_anilist = @IdAniLista 
	
	if @@rowcount>0
		select 0 id, @descriptionList descriptionList
	return(0)
end'

	EXEC(@Sql)

		set @Sql='ALTER function [dbo].[Completa](@Cadena varchar(32))
RETURNS varchar(32) 
AS  
BEGIN
declare @resultado varchar(32)
declare @ld varchar(5)
declare @pais varchar(2)

select @pais = valor from ccSettings where setting_id = 104
select @ld = valor from ccSettings where setting_id = 17
select @resultado = dbo.limpia(@Cadena)

--Completa 1:México 2:Argentina 3:Colombia 4:USA 5:Chile 6: venezuela 7: UK 8: arabia saudita 9: Australia
if @pais = 1 
 begin
	--Empieza Mexico
	select @resultado = case 
	 when (len(@resultado)=8 and len(@ld)=2) or (len(@resultado)=7 and len(@ld)=3) then @resultado
	 when len(@resultado)=10 then 
	   case when left(@resultado, len(@ld)) = @ld 
		then right(@resultado, 10 - len(@ld)) else ''01'' + @resultado end
	 when len(@resultado)=12 then 
	   case when left(@resultado, 2) = ''01'' then
		 case when substring(@resultado, 3, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	 when len(@resultado)=13 then
	   case when left(@resultado, 3) in (''044'', ''045'') then
		 case when substring(@resultado, 4, len(@ld)) = @ld then
		   ''044'' + right(@resultado, 10) else ''045'' + right(@resultado, 10) 
		 end
	   else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	--Termina Mexico
	return @resultado
 end

if @pais = 2 
 begin
	-- Empieza Argentina
	select @resultado = case 
	 when (len(@resultado)=7 and len(@ld)=3) or (len(@resultado)=6 and len(@ld)=4) then 
		@resultado
	-- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
	-- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
	 when len(@resultado) = 8 then
		case when len(@ld) = 4 then
			case when left(@resultado,2) = ''15'' then @resultado end
		else 
			case when len(@ld) = 2 then @resultado end
		end
	-- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
	 when len(@resultado)=9 then
		case when left(@resultado, 2) = ''15'' then @resultado else ''E_NV_Cel'' end
	-- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
	 -- Si es diferente se le agrega un 0 para llamadas de larga distancia
	 when len(@resultado)=10 then 
	   case when left(@resultado, len(@ld)) = @ld 
		then right(@resultado, 10 - len(@ld)) else 
			case when left(@resultado,2) = ''15'' then @resultado else ''0'' + @resultado end 
	   end
	-- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
	-- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
	 when len(@resultado)=11 then 
	   case when left(@resultado, 1) = ''0'' then
		 case when substring(@resultado, 2, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	-- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
	-- si no es local se le agrega el 0 y se marca el numero
	 when len(@resultado)=12 then
		case when left(@resultado, len(@ld)) = @ld then 
			case when substring(@resultado, len(@ld) + 1, 2) = ''15'' then 
				right(@resultado,12 - len(@ld)) else ''E_NV_Cel'' end else ''0'' + @resultado end
	-- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
	 when len(@resultado)=13 then
		case when left(@resultado, 1) = ''0'' then
			case when substring(@resultado, 2, len(@ld)) = @ld then substring(@resultado, len(@ld) + 2, 12 - len(@ld)) else @resultado end
		else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	--Termina Argentina	
	return @resultado	
 end

if @pais = 3 
 begin
	--Empieza colombia
	select @resultado = case 
	--Si son 7 digitos, se regresa igual
	 when len(@resultado)=7 then 
		@resultado
	--Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
	 when len(@resultado) = 8  then
		case when left(@resultado,1) = @ld then right(@resultado,7) else @resultado end		
	-- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
	 when len(@resultado)=10 then
		case when left(@resultado,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then ''0'' + @resultado 
		else
			''E_NV_Cel'' 
		end
	--Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
	--prefijo de celular
	 when len(@resultado)=11 then 
		case when left(@resultado,1)=''0'' then
			case when substring(@resultado,2,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then @resultado else ''E_NV_Cel'' end
		else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end	

	-- Termina Colombia
	return @resultado	
 end

if @pais = 4 
 begin
	--Empieza USA
	select @resultado = case len(@resultado)
	 when 3 then
		case @resultado when ''911'' then @resultado else ''E_NV_Longitud'' end
	 when 7 then @resultado
	 when 10 then 
	   case when left(@resultado, len(@ld)) = @ld 
		then right(@resultado, 10 - len(@ld)) else ''1'' + @resultado end
	 when 11 then 
	   case when left(@resultado, 1) = ''1'' then
		 case when substring(@resultado, 2, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	else ''E_NV_Longitud'' end

	--Termina USA
	return @resultado
 end

if @pais = 5 
 begin
	select @resultado = case len(@resultado) 
	 when 6 then @resultado 
	 when 7 then @resultado
	-- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
	 when 8 then

		case when @ld = left(@resultado,len(@ld)) then right(@resultado,8-len(@ld)) else				
			case when left(@resultado,1) in (8,9) then ''09'' + @resultado else
				case when left(@resultado,1) = ''6'' then case when left(@resultado,2) in (61,63,64,65,67) then  @resultado else ''09'' + @resultado end
				 else case when left(@resultado,1) = ''7'' then case when left(@resultado,2) in (71,72,73,75) then @resultado else ''09'' + @resultado end else @resultado end end	
			 end
		end
	-- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
	-- de telefonia voIp se le agrega el 0 al inicio
	 when 9 then
		case when @ld = left(@resultado,2) then right(@resultado,7) else
			case when left(@resultado,2) in (41,32,65) then @resultado else 
				case when left(@resultado,2) = ''44'' then ''0'' + @resultado else 
					case when left(@resultado,1) = ''9'' and substring(@resultado,2,1) in (6,7,8,9) then ''0'' + @resultado else ''E_NV_Longitud'' end
				 end
			end
		end
	 when 10 then
		case when left(@resultado,2) = ''09'' then @resultado else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	-- Termina Chile
	return @resultado
 end

-- Venezuela
if @pais = 6 begin
	select @resultado = case len(@resultado)
		when 7 then @resultado
		when 10 then ''0'' + @resultado
		when 11 then 
			case when left(@resultado,1) = ''0'' then @resultado else ''E_NV_Longitud'' end
		else 
	    ''E_NV_Longitud'' end
end
--Termina Venezuela

-- UK
if @pais = 7 begin
	select @resultado = case len(@resultado)
		when 11 then
			case left(@resultado,1)
				when ''0'' then @resultado else ''E_NV_Longitud''
			end
		when 10 then
			case left(@resultado,1)
				when ''0'' then @resultado else ''0'' + @resultado
			end
		when 9 then
			case when left(@resultado,1) <> ''0'' then ''0'' + @resultado else ''E_NV_Longitud'' end
		when 8 then
			case when substring(@resultado, 1, 2) = ''08'' then @resultado else ''E_NV_Longitud'' end
		when 7 then
			case when left(@resultado,1) = ''8'' then ''0'' + @resultado else ''E_NV_Longitud'' end
		else
		''E_NV_Longitud''
	end
end
-- Termina UK

if @pais = 8 begin -- arabia saudita
	select @resultado = case len(@resultado)
	when 7 then @resultado
	when 8 then case substring(@resultado, 1, 1) when @ld then right(@resultado, 7) else ''0'' + @resultado end
	when 9 then case substring(@resultado, 1, 1) when ''5'' then ''0'' + @resultado 
				when ''0'' then case substring(@resultado, 2, 1) 
						when @ld then right(@resultado, 7) else @resultado end 
				else ''E_NV_Longitud''
				end
	when 10 then case substring(@resultado, 2, 1) when ''5'' then @resultado else ''E_NV_Longitud'' end
	when 11 then case substring(@resultado, 2, 1) 
					when ''8'' then case substring(@resultado, 3, 3) 
									when ''111'' then @resultado else ''E_NV_Longitud'' end 
					else case when substring(@resultado, 3, 3) = ''510'' or substring(@resultado, 3, 3) = ''511'' then @resultado else ''E_NV_Longitud'' end
					end
	when 13 then @resultado
	else ''E_NV_Longitud'' end
end -- arabia saudita

if @pais = 9 --Australia
begin
	select @resultado = case len(@resultado)
	when 8 then 
		/*case when exists (select AreaCode 
						  from SeriesAU 
						  where convert(int,LD) = convert(int,@ld) 
						  and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then*/
			case substring(@resultado, 1, 4) when ''5550'' then ''E_NV_LD'' else @ld +  @resultado end
		/*else case when exists (select AreaCode 
						  from SeriesAU 
						  where convert(int,LD) = convert(int,''04'') 
						  and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then
		''04'' +  @resultado 
		else ''E_NV_Cel'' end end*/
	when 9 then 
		case when left(@resultado,1) <> ''0'' then 
			case substring(@resultado, 2, 4) when ''5550'' then ''E_NV_LD'' else ''0'' + @resultado end
		else ''E_NV_LD'' end
	when 10 then 
		case substring(@resultado, 3, 4) when ''5550'' then ''E_NV_LD'' else @resultado end 
	else ''E_NV_Longitud'' end
end

-- Termina
return @resultado

end'

	EXEC(@Sql)

		set @Sql='ALTER FUNCTION [dbo].[Completa_ListaNegra] (@Cadena varchar(30))
RETURNS varchar(30) AS  
begin
declare @resultado varchar(30), @ld varchar(6), @pais tinyint, @BLActivo tinyint
select @resultado=dbo.Completa(@Cadena)

select @ld=valor from ccSettings where setting_id=17
select @pais = valor from ccsettings where setting_id = 104
select @BLActivo = valor from ccsettings where setting_id = 114

if @BLActivo = 1 begin
	if @pais in (1,4)
	 begin
		if left(@resultado, 1)=''E''
			return @resultado

		select @resultado = case
		 when len(@resultado)in(7,8) then @ld + @resultado
		 when @resultado=''911'' OR len(@resultado)=10 then @resultado
		 when len(@resultado) in (11,12,13) then right(@resultado,10)
		 else ''E_NV_Longitud''
		 end

		 return @resultado
	 end
		
	if @pais = 2 
	 begin
		select @resultado = dbo.fnClearPhoneArg(@cadena)
		return @resultado
	 end

	if @pais = 3 and left(@resultado,1) <> ''E'' 
	 begin
		select @resultado = case
			when len(@resultado) = 7 then @ld + @resultado
			when len(@resultado) in(8,10) then @resultado
			when len(@resultado) = 11 then right(@resultado,10) 
			else ''E_NV_Longitud'' end
		return @resultado
	 end

	if @pais = 5 and left(@resultado,1) <> ''E'' 
	 begin
		select @resultado = case
			when len(@resultado) in (6,7) then @ld + @resultado
			when len(@resultado) in (8,9) then @resultado
			when len(@resultado) = 10 then right(@resultado,9)
			else ''E_NV_Longitud'' end
		return @resultado
	 end

	if @pais = 6 and left(@resultado,1) <> ''E''
	begin
		select @resultado = case
			when len(@resultado) = 7 then @ld + @resultado
			when len(@resultado) = 10 then @resultado
			when len(@resultado) = 11 then right(@resultado,10)
			else ''E_NV_Longitud'' end
		return @resultado	
	end

	if @pais = 7 and left(@resultado,1) <> ''E''
	begin
		select @resultado = right(@resultado,10)
		return @resultado
	end

	if @pais = 8
	begin
		if left(@resultado,1) = ''E''
		begin
			return @resultado
		end
		select @resultado = case
			when len(@resultado) = 7 then ''0'' + @ld + @resultado
			when len(@resultado) = 9 and substring(@resultado,1,1) = ''0'' then @resultado
			when len(@resultado) = 10 and substring(@resultado,2,1) = ''5'' then @resultado
			when len(@resultado) = 11 and substring(@resultado,3,3) in (''111'',''510'',''511'') then @resultado
			else ''E_NV_Longitud'' end
		return @resultado	
	end

	if @pais = 9 and left(@resultado,1) <> ''E''
	begin
		return @resultado
	end

end
else begin
 select @resultado = dbo.Limpia(@cadena)
end 

return @resultado
end'

	EXEC(@Sql)

		set @Sql='ALTER function [dbo].[TelAni](@tel varchar(32), @lista smallint)
RETURNS varchar(32) 
AS  
BEGIN
--declare @edo varchar(250)
declare @cldLocal varchar(10), @pais tinyint, @lon tinyint, @ret as varchar(10)

select  @cldLocal = valor from ccsettings where setting_id = 17
select @pais = valor, @ret = '''' from ccSettings where setting_id = 104

	if @lista = 0 begin
		select @tel = ''''
	end

	if @pais = 1 begin --Empieza Mexico
		select @lon = len(@tel)
		if @lon >= 7 and @lon <=13 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
			(( len(@tel) = 8 and @cldlocal = area and len(area) = 2 ) 
				or
				( len(@tel) = 7 and @cldlocal = area and len(area) = 3 )
				or
				( len(@tel) >= 10 and left(right(@tel, 10), 3) = area and len(area) = 3 )
				or
				( len(@tel) >= 10 and left(right(@tel, 10), 2) = area and len(area) = 2 ))
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
							( @lon = 7 and left(@tel,4) = area and len(area) = 3 )
							or
							( @lon = 8 and left(@tel,4) = area and len(area) = 2 )
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
			--select @edo = location from ccTimeZoneAreaUsa where area = left(@tel,3) 
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

	return @ret
END'

	EXEC(@Sql)

		set @Sql='ALTER FUNCTION [dbo].[Verifica](@tel varchar(32))
RETURNS varchar(32) AS  
 BEGIN
	declare @ld varchar(7)
	declare @lon tinyint
	declare @result tinyint
	declare @mod varchar(10)
	declare @Cadena varchar(32)
	declare @cldLocal varchar(7)
	declare @pais tinyint

	select  @cldLocal = valor from ccsettings where setting_id = 17
	select @tel = dbo.limpia(@tel)

	select @pais = valor from ccSettings where setting_id = 104

	if @pais = 1 begin --Empieza Mexico
		select @lon = len(@tel)
		if @lon between 7 and 8 begin
			set @tel = @cldLocal + @tel
		end
		select @tel = right(@tel, 10)
		select @lon = len(@tel)

		if @lon = 10 begin
			select @ld = case when left(@tel, 2) in (''55'', ''33'', ''81'') then left(@tel, 2) else left(@tel, 3) end
			
			select @mod = modalidad from series where cld = @ld and serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]
			
			select @tel = case 
				when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''01'' + @tel end
				when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
				else ''E_'' + @tel
			end
		end else begin
			if @lon > 0 begin
				select @tel = ''E_'' + @tel
			end	
		end
		return @tel
	end --Termina Mexico

	-- Empieza Argentina
	if @pais = 2 begin 
		select @tel = dbo.completa(@tel)
		if left(@tel,1) = ''E'' begin return @tel end
		select @lon = len(@tel)
		if @lon in(6,7,8) and left(@tel,2) <> ''15'' begin
			set @tel = @cldLocal + @tel
		end

		if @lon in (8,9,10) and left(@tel,2) = ''15'' begin
			set @tel = @cldLocal + substring(@tel,3,@lon - 2)
		end

		--Buscamos el 15
		if @lon = 13 begin
			declare @index as int
			select @index = charindex(''15'',@tel)		
			--El unico caso en el que la lada tiene un 15 es con lada 3715
			if @index < 2 begin
				select @tel = ''E_'' + @tel						
				return @tel
			end
			else begin
				if substring(@tel,@index-2,4) = ''3715''
					begin
						select @ld = ''3715''
						set @tel = @ld + right(@tel,6)
					end
				else
					begin						
						select @ld = substring(@tel,2,@index-2)				
						set @tel = @ld + right(@tel,13 - (@index + 1))
					end
			end
		end

		select @tel = right(@tel, 10)

		if len(@tel) = 10 begin
			declare @serie as varchar(5)	
			begin 
				-- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
				declare @contLD as int
				declare @cont as int
				set @contLD=4
					BuscaLada:
					if isnull(@ld,'''') = '''' and @contLD >= 2
						begin					
							select @ld = cld from seriesArg where cld=left(@tel,@contLD)
							if isnull(@ld,'''') = '''' begin						
								set @contLD = @contLD - 1
								goto BuscaLada
							end
						end
					else begin
							if isnull(@ld,'''') = '''' begin
								select @tel = ''E_'' + @tel						
							end 
					end
			end

			-- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
			begin
			if len(@ld) = 2 begin
					set @cont = 5
					buscaSerie2:
					if isnull(@serie,'''') = '''' and @cont >= 4 begin				
						select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,3,@cont)				
						if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie2 end
					end			
			end
			else begin
				if len(@ld) = 3 begin
					set @cont = 4
					buscaSerie3:
					if isnull(@serie,'''') = '''' and @cont >= 3 begin
						select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,4,@cont)
						if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie3 end
					end			
				end		
				else begin
					if len(@ld) = 4 begin
						set @cont = 3
						buscaSerie4:
						if isnull(@serie,'''') = '''' and @cont >= 2 begin
							select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,5,@cont)
							if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie4 end
						end			
					end					
				end
			end		
					
			end
			
			select @mod = modalidad from seriesArg where cld = @ld and serie = @serie and right(@tel, 10 - len(@ld) - len(@serie)) between [NUMERACION INICIAL] and [NUMERACION FINAL]		
			
			-- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie
			--select @ld,@serie,@mod,@contLD
			if isNull(@serie,'''') = '''' and @contLD>1 begin		
			set @contLD = len(@ld) - 1
			set @ld = null
			goto buscaLada
			end	

			select @tel = case 
				when @mod in (''BASICA'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''0'' + @tel end
				when @mod = ''CPP'' then case when @ld = @cldLocal then ''15'' + right(@tel,10-len(@ld)) else ''0'' + @ld + ''15'' + right(@tel,10-len(@ld)) end
				else ''E_'' + @tel
			end
		end else begin
			if len(@tel) > 0 begin
				select @tel = ''E_'' + @tel
			end	
		end
		return @tel
	end  --Termina Argentina

	if @pais = 3 begin  --Empieza Colombia
		select @tel = dbo.completa(@tel)
		if left(@tel,1) = ''E'' begin
			return @tel
		end

		if len(@tel) not in (7,8,10,11) begin
			return ''E_'' + @tel		
		end
				
		if len(@tel) = 7 begin		
			if exists(select serie from seriesCol where serie = left(@tel,4) and @cldLocal = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				return @tel	
			end		
			else begin
				return ''E_'' + @tel
			end
		end	

		if len(@tel) = 8 begin
			if exists(select serie from seriesCol where serie = substring(@tel,2,4) and left(@tel,1) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				return @tel	
			end		
			else begin
				return ''E_'' + @tel
			end		
		end

		if len(@tel) = 10 begin
			if exists(select serie from seriesCol where serie = substring(@tel,5,3) and (left(@tel,3) + ''-'' + substring(@tel,4,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				return @tel	
			end		
			else begin
				return ''E_'' + @tel
			end		
		end

		if len(@tel) = 11 begin
			if exists(select serie from seriesCol where serie = substring(@tel,6,3) and (substring(@tel,2,3) + ''-'' + substring(@tel,5,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				return @tel	
			end		
			else begin
				return ''E_'' + @tel
			end		
		end
	end  --Termina Colombia

	-- Empieza Chile
	if @pais = 5 begin
		select @tel = dbo.completa(@tel)
		if left(@tel,1) = ''E'' begin
			return @tel
		end

		if len(@tel) = 6 and len(@cldLocal) = 2 begin
			if exists(select serie from seriesChi where cld = @cldLocal and left(@tel,3) = serie and right(@tel,3) between numeracioninicial and numeracionFinal) begin
				return @tel
			end
			else begin return ''E_'' + @tel end
		end
		
		if len(@tel) = 7 begin
			if @cldLocal in (2,41,44,32) begin
				if exists(select serie from serieschi where serie = left(@tel,4)) begin return @tel end
				else begin
					if left(@tel,3) = ''200'' and exists(select serie from serieschi where serie = left(@tel,3) ) begin return @tel end
				end
			end
		end

		if len(@tel) = 8 begin
			if left(@tel,1) = ''2'' begin
					if exists(select serie from serieschi where serie = substring(@tel,2,4)) begin return @tel end
					else begin
						if exists(select serie from serieschi where serie = substring(@tel,2,5)) begin return @tel end					
						else begin return ''E_'' + @tel end			
					end
			end
			else begin
				return @tel
			end
		end

		if len(@tel) = 10 begin
			if left(@tel,2) = ''09'' begin
				if exists(select serie from serieschi where cld=substring(@tel,3,1) and serie = substring(@tel,5,3)) begin
					return @tel
				end
				else begin
					return ''E_'' + @tel
				end
			end

		end
	end
	--Termina Chile

	if @pais = 6 begin --Empieza Venezuela
		select @lon = len(@tel)
		if @lon = 7  begin
			set @tel = @cldLocal + @tel
		end

		select @tel = right(@tel, 10)

		if len(@tel) = 10 begin
			select @ld = left(@tel,3)
			select @mod = tipo from seriesVen where left(@tel,3) = LD	

			if @mod = ''CPP'' begin
				if exists( select * from seriesVen where LD = @ld ) begin
					if @ld = @cldLocal begin
						select @tel = right(@tel,7)
					end
					else begin
						select @tel = ''0'' + @tel
					end
				end
				else begin
					select @tel = ''E_'' + @tel
				end
			end
			else begin
				if @mod = ''FIJO'' begin
					if exists( select serie from seriesVen where serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [Inicio] and [Fin]) begin
						if @ld = @cldLocal begin
							select @tel = right(@tel,7)
						end
						else begin
							select @tel = ''0'' + @tel
						end
					end
					else begin
						select @tel = ''E_'' + @tel
					end
				end 
				else begin
					select @tel = ''E_'' + @tel
				end	
			end
		end 
		else begin
			if len(@tel) > 0 begin
				select @tel = ''E_'' + @tel
			end	
		end
		return @tel
	end --Termina Venezuela

	if @pais = 7 begin -- Empieza UK
		select @tel = dbo.completa(@tel)
		if left(@tel, 1) = ''E'' begin -- regresa error por longitud
			return @tel
		end
		select @lon = len(@tel)

		--numeros no geograficos
		if (left(@tel, 2) in(''03'', ''07'', ''09'') and @lon <> 11) or (left(@tel, 3) in(''055'', ''056'', ''070'') and @lon <> 11) begin
			return ''E_'' + @tel --error por longitud con lada correcta
		end
		else begin
			if left(@tel, 7) in(''0845464'') or left(@tel, 5) = ''07624'' or left(@tel, 4) in(''0500'', ''0800'') or left(@tel, 3) in(''055'', ''056'', ''070'', ''76'') or left(@tel, 2) in(''03'', ''07'', ''08'', ''09'') begin
				return @tel; --longitud correcta y numero no geografico
			end
		end

		--numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
		if (left(@tel, 7) in(''0159575'', ''0159576'')) or
			(left(@tel, 5) in(''02820'',''02821'',''02825'',''02827'',''02828'',''02829'',''02830'',''02837'',''02838'',''02840'',''02841'',''02842'',''02843'',''02844'',''02866'',''02867'',''02868'',''02870'',''02871'',''02877'',''02879'',''02880'',''02881'',''02882'',''02885'',''02886'',''02887'',''02889'',''02890'',''02891'',''02892'',''02893'',''02894'',''02895'',''02897'') and @lon = 11) or --claves 2xxx tienen formato 4-6
			(left(@tel, 4) in(''0113'', ''0114'',''0115'',''0116'',''0117'',''0118'',''0121'',''0131'',''0141'',''0151'',''0161'',''0238'',''0239'') and @lon = 11) or --3-digit area codes have 7-digit subscribers.
			(left(@tel, 3) in(''020'',''024'',''029'') and @lon = 11) begin --2-digit area codes have 8-digit subscribers.
			return @tel;
		end

		--numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
		if left(@tel, 2) = ''01'' begin
			select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,4) --mayor numero de ladas (va primero por ser mas probable)
			if @ld > 0 begin
				return @tel;
			end
			else begin
				select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,5) --ladas restantes
				if @ld > 0 begin
					return @tel;
				end
			end
		end --si no encontro ni error ni coincidencia entonces esta mal
		return ''E_'' + @tel
	end --Termina UK

	if @pais = 8 begin --Empieza Arabia Saudita
		select @tel = dbo.completa(@tel)
		select @lon = len(@tel)
		if @lon = 7 begin
			set @tel = ''0'' + @cldLocal + @tel
		end
		select @lon = len(@tel)

		if @lon = 9 begin
			if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,2) = cld) begin
				if (substring(@tel,2,1) = @cldLocal)
				begin
					return right(@tel,7)
				end else begin
					return @tel
				end	
			end		
			else begin
				return ''E_'' + @tel
			end
		end
		if @lon = 10 begin
			if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,4,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,3) = cld) begin
				return @tel	
			end		
			else begin
				return ''E_'' + @tel
			end
		end
		if @lon = 11 begin
			if exists(select regiones,* from seriesSA where right(@tel,6) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 6 and left(@tel,2) = cld) begin
				return @tel	
			end		
			else begin
				return ''E_'' + @tel
			end
		end  
	end --Termina Arabia Saudita

	if @pais = 9 
		begin --Empieza Australia
			select @tel = dbo.completa(@tel)
			select @lon = len(@tel)

			if left(@tel,1) <> ''E'' 
				begin
					if exists(select Regiones
							  from SeriesAU 
							  where convert(int,LD) = convert(int,substring(@tel, 1, 2))
							  and convert(int,AreaCode) = convert(int,substring(@tel, 3, 2))
							  and convert(int,substring(@tel, 5, 6)) between convert(int,SerieInicio) and convert(int,SerieFin)) 
						begin
							return @tel	
						end		
					else 
						begin
							return ''E_'' + @tel
						end
				end
			else 
				begin
					return @tel
				end
		end --Termina Australia

	return @tel
 end'

	EXEC(@Sql)

		set @Sql='ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN
	declare @lada as varchar(5)
	declare @timeZone as int

	select @lada = valor from ccsettings where setting_id = 17

	declare @country as tinyInt
	select @country = valor from ccSettings where setting_id = 104

		if @country = 1 begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
			where id_country = @country and (
			( len(@phone) = 8 and @lada = area and len(area) = 2 )
			or
			( len(@phone) = 7 and @lada = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 2) = area and len(area) = 2 ))
		end

		if @country = 2 begin
			declare @telTemp varchar(15)
			set @telTemp = @phone
			select @phone = dbo.Completa(@phone)
			if left(@phone,1) = ''E'' begin set @phone = @telTemp end
			select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaArgDetail where
						( len(@phone) = 6 and @lada = area and len(area) = 4 )
						or
						( len(@phone) = 7 and @lada = area and len(area) = 3 )
						or
						( len(@phone) = 8 and @lada = area and len(area) = 2 )
						or
						( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
						or
						( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
						or
						( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
						or
						( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
						or
						( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
						or
						( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 )
						if @timeZone is null
							begin
								select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
								where id_country = @country and (
									( len(@phone) = 6 and @lada = area and len(area) = 4 and right(@phone,4) = area )
									or
									( len(@phone) = 7 and @lada = area and len(area) = 3 and right(@phone,3) = area )
									or
									( len(@phone) = 8 and @lada = area and len(area) = 2 and right(@phone,2) = area )
									or
									( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
									or
									( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
									or
									( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
									or
									( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
									or
									( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
									or
									( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 ))
							end
		end

	if @country = 3 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 7 and @lada = area )
		or
		( len(@phone) = 8 and left(@phone,1) = area )
		or
		( len(@phone) in(10,11) and (left(@phone,1) = ''3'' or substring(@phone,2,1) = ''3'')))
	end

	if @country = 4

		begin
			select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaUsaDetail where
			( len(@phone) = 7 and @lada = area and len(area) = 3 and right(@phone,3) = prefix )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 and left(right(@phone, 7), 3) = prefix)
			if @timeZone is null
				begin
					select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
					where id_country = @country and (
					( len(@phone) = 7 and @lada = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
				end
		end

	if @country = 5 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 6 and @lada = area )
		or
		( len(@phone) = 7 and @lada = area )
		or
		( len(@phone) = 8 and left(@phone,1) = area )
		or
		( len(@phone) = 8 and left(@phone,2) = area )
		or
		( len(@phone) = 9 and left(@phone,2) = area )
		or
		( len(@phone) = 10 and substring(@phone,3,1) = area and left(@phone,2) = ''09'' ))
	end

	if @country = 6 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 7 and @lada = area and len(area) = 3 )
		or
		( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
	end

	if @country = 7 begin
		declare @phoneTemp as varchar(10)
		select @phoneTemp = right ( @phone, 10 )
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
		where id_country = @country and (
		(len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,4) = area ) or
		(len(@phoneTemp) = 9 and left(@phoneTemp,4) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,3) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,2) = area )
		)
	end

	if @country = 8 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
		where id_country = @country and (
		(len(@phone) = 7 and @lada = area) or
		(len(@phone) = 9 and substring(@phone, 2, 1) = area) or
		(len(@phone) = 10 and substring(@phone, 2, 1) = area) or
		(len(@phone) = 11 and substring(@phone, 2, 1) = area))
	end
	
	if @country = 9 begin
		select @phone = dbo.Completa(@phone)
		-- len(@phone) = 10
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
			where id_country = @country and (
			(convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
			(convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
		end
	end

	return isNull(@timeZone,0)
 END'

	EXEC(@Sql)

	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC], ERROR_PROCEDURE()
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
