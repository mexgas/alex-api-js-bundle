/*
Autor: Raymundo Gonzalez
Fecha: 2013/02/28
Descripcion:
	Se inserta registro en la tabla ccRIACat_AdminPermissions para configuracion de permiso de solo monitoreo para supervisores
	Se modifica el SP ccsp_RIAGetRelsSupsAgent para no mostrar a los supervisores de sólo monitoreo en la lista de chat del agente
	Se actualiza la tabla ccoLogDials agregando la columna disconnectCause para almacenar la causa de desconexion de la llamada
	Se modifica el SP ccsp_DLRSaveDialResult para guardar causa de desconexion de la llamada
	Se crea la tabla seriesBR para plan de marcacion de Brasil
	Se inserta registro en la tabla ccriacat_country para plan de marcacion de Brasil
	Se actualiza la tabla cstoProvedor agregando columna de carrier para plan de marcacion de Brasil
	Se actualiza la tabla ccsettings para plan de marcacion de Brasil
	Se inserta registro en la tabla ccSettings para plan de marcacion de Brasil en llamadas por cobrar
	Se insertan registros en la tabla ccHorarioVerano para plan de marcacion de Brasil
	Se insertan registros en la tabla cstoTipoLlamada para plan de marcacion de Brasil
	Se insertan registros en la tabla ccTimeZoneArea para plan de marcacion de Brasil
	Se insertan registros en la tabla cstoProvedor para plan de marcacion de Brasil
	Se insertan registros en la tabla seriesBR para plan de marcacion de Brasil	
	Se crea la funcion fnIsDayLight para plan de marcacion de Brasil
	Se modifica la funcion fnGetTimeZone para plan de marcacion de Brasil
	se modifica la funcion TelAni para plan de marcacion de Brasil
	Se modifica la funcion Completa para plan de marcacion de Brasil
	Se modifica la funcion Completa_ListaNegra para plan de marcacion de Brasil
	Se modifica la funcion Verifica para plan de marcacion de Brasil
	Se modifica el SP ccsp_INInsertaCallBack para plan de marcacion de Brasil
	Se modifica el SP ccsp_ManualCallApplyTimeZoneRules para plan de marcacion de Brasil
	Se modifica el SP ccsp_OUTGetNewJobs para plan de marcacion de Brasil
	Se modifica el SP ccsp_OUTGetNewProviderJobs para plan de marcacion de Brasil
	Se modifica el SP ccsp_OUTInsertaCallBack para plan de marcacion de Brasil
	Se modifica el SP ccspADM_AniListLD para plan de marcacion de Brasil
	Se modifica el SP ccsp_InsertDNCList para plan de marcacion de Brasil
	Se modifica el SP ccsp_Limpia para plan de marcacion de Brasil
	Se modifica el SP ccsp_RIAAgentGetDialMask para plan de marcacion de Brasil
	Se actualiza la tabla ccTimeZoneArea agregando la columna call_record para grabacion de llamadas
	Se actualiza la tabla ccTimeZoneArea para indicar los estados de USA para restringir grabacion de llamadas
	Se actualiza la tabla ccCamps agregando la columna call_record para grabacion de llamadas
	Se crea la funcion EnableCallRecord para revisar si se puede o no hacer grabacion de llamadas
	Se actualiza el SP ccsp_DLRGetDialInfo para devolver si se puede o no grabar llamadas
	Se actualiza el SP ccsp_DLRgetDialPrefix para devolver si se puede o no grabar llamadas
	Se actualiza el SP ccsp_RIAConfCamp  para devolver si se puede o no grabar llamadas
	Se modifica el SP configuraIdiomaCatalogosEnglish para agregar registros al catalogo de movimientos de lista negra
	Se inserta registro en la tabla ccsettings para callKey en llamadas manuales
	Se modifica el SP ccsp_RIACATMenu para controlar menu de AVRS
	
Version requerida: 90
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '91'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccRIACat_AdminPermissions - Insert'
		set @Sql='insert into ccRIACat_AdminPermissions
values (''Sólo Monitoreo|Only Monitoring'',1)'
			
	EXEC(@Sql)

		set @process = 'ccsp_RIAGetRelsSupsAgent - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAGetRelsSupsAgent]

AS

--Relaciones Sup-Agt de acuerdo a WorkGroups
select distinct a1.user_id as agt, a5.user_id as sup, a5.login 
from ccusers a1 
inner join ccriaworkgroupusers a2 on (a1.user_id=a2.user_id and tipouser_id=1)
inner join (select a3.user_id, a4.IDWG, a3.login  
			from ccusers a3 
			inner join ccriaworkgroupusers a4 on (a3.user_id = a4.user_id and (tipouser_id = 2 or tipouser_id = 6))
			) a5 
			on (a2.IDWG = a5.IDWG)
where a5.user_id not in (select User_id from ccRIAUsr_AdminPermissions where per_id = 4) -- Excluye sólo monitoreo
order by a1.user_id, a5.user_id'
	
	EXEC(@Sql)
	
		set @process = 'ccoLogDials - Alter Table'
		set @Sql = 'alter table ccoLogDials add disconnectCause varchar(250) not null default '''''
	
	EXEC(@Sql)
	
		set @process = 'ccsp_DLRSaveDialResult - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_DLRSaveDialResult]
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
@canceledNoAgents bit =0,
@disconnectCause varchar(250) = ''''
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
	INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause)
	select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''0000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause
END
ELSE
BEGIN
	INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause)
	select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''0000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause
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
	
		set @process = 'seriesBR - Create Table'
		set @Sql='CREATE TABLE [dbo].[seriesBR](
	[Regiones] [nvarchar](max) NOT NULL,
	[AreaCode] [varchar](2) NULL,
	[SerieInicio] [varchar](9) NULL,
	[SerieFin] [varchar](9) NULL,
	[TipoRed] [varchar](10) NULL,
	[Modalidad] [varchar](10) NULL
) ON [PRIMARY]'
	
	EXEC(@Sql)
	
		set @process = 'ccriacat_country - Insert'
		set @Sql = 'insert into ccriacat_country ([ctyname], [ctycode], [minphonelength], [maxphonelength]) values (''Brasil'', ''55'', 8, 11);'
			
	EXEC(@Sql)
	
		set @process = 'cstoProvedor - Alter Table'
		set @Sql = 'ALTER table cstoProvedor add codigoCarrierBR varchar(5)'
			
	EXEC(@Sql)
	
		set @process = 'cstoProvedor - Update'
		set @Sql = 'update cstoProvedor 
set codigoCarrierBR='''' 
where codigoCarrierBR is null'
			
	EXEC(@Sql)

		set @process = 'ccsettings - Update'
		set @Sql = 'update ccsettings 
set detalle = ''1:Mexico, 2:Argentina, 3:Colombia, 4:USA, 5:Chile, 6: Venezuela, 7: Reino Unido, 8: Arabia saudita, 9: Australia, 10:Brasil'' 
where setting_id = 104'
			
	EXEC(@Sql)
	
		set @process = 'ccsettings - Insert(1)'
		set @Sql = 'INSERT INTO [CCenterRia].[dbo].[ccSettings] ([setting_id],[valor],[descripcion],[Status],[Tipo],[detalle],[description],[bLoadSettings])
VALUES (126,''1'',''Permitir llamadas por cobrar Brasil'',1,''GRL'',''1:Activar 0:Desactivar'',''Collect calls Brazil'',1)'
					
	EXEC(@Sql)
	
		set @process = 'ccHorarioVerano - Insert'
		set @Sql = 'insert into ccHorarioVerano values (''2012/10/21 00:00'', ''2013/02/17 00:00'', 10)
insert into ccHorarioVerano values (''2013/10/20 00:00'', ''2014/02/16 00:00'', 10)
insert into ccHorarioVerano values (''2014/10/19 00:00'', ''2015/02/15 00:00'', 10)
insert into ccHorarioVerano values (''2015/10/18 00:00'', ''2016/02/21 00:00'', 10)
insert into ccHorarioVerano values (''2016/10/16 00:00'', ''2017/02/19 00:00'', 10)
insert into ccHorarioVerano values (''2017/10/15 00:00'', ''2018/02/18 00:00'', 10)
insert into ccHorarioVerano values (''2018/10/21 00:00'', ''2019/02/17 00:00'', 10)
insert into ccHorarioVerano values (''2019/10/20 00:00'', ''2020/02/16 00:00'', 10)
insert into ccHorarioVerano values (''2020/10/18 00:00'', ''2021/02/21 00:00'', 10)
insert into ccHorarioVerano values (''2021/10/17 00:00'', ''2022/02/20 00:00'', 10)'
					
	EXEC(@Sql)
	
		set @process = 'cstoTipoLlamada - Insert'
		set @Sql = 'insert into cstoTipoLlamada values (10, 1,  ''Local''						, 8,     ''%'')
insert into cstoTipoLlamada values (10, 2,  ''Movil ''						, 8,     ''%'')
insert into cstoTipoLlamada values (10, 3,  ''Movil 9 Digitos''      		, 9,    ''9%'')
insert into cstoTipoLlamada values (10, 4,  ''LD Nacional''					, 10, ''%'')
insert into cstoTipoLlamada values (10, 5,  ''LD Nacional Movil''			, 10, ''%'')
insert into cstoTipoLlamada values (10, 6,  ''LD Nacional Movil 9 Digitos''	, 11, ''%'')
insert into cstoTipoLlamada values (10, 7,  ''LD Internacional''				, 19,  ''00%'')'
					
	EXEC(@Sql)
	
		set @process = 'ccTimeZoneArea - Insert'
		set @Sql = 'insert into ccTimeZoneArea  values (10, ''11'', ''SE - São Paulo (Capital)''     ,  8,  4)
insert into ccTimeZoneArea  values (10, ''12'', ''SE - São José dos Campos''     ,  8,  4)
insert into ccTimeZoneArea  values (10, ''13'', ''SE - Santos''                  ,  8,  4)
insert into ccTimeZoneArea  values (10, ''14'', ''SE - Botucatu''                ,  8,  4)
insert into ccTimeZoneArea  values (10, ''15'', ''SE - Sorocaba''                ,  8,  4)
insert into ccTimeZoneArea  values (10, ''16'', ''SE - Serrana''                 ,  8,  4)
insert into ccTimeZoneArea  values (10, ''17'', ''SE - São José do Rio Preto''   ,  8,  4)
insert into ccTimeZoneArea  values (10, ''18'', ''SE - Presidente Prudente''     ,  8,  4)
insert into ccTimeZoneArea  values (10, ''19'', ''SE - Vinhedo''                 ,  8,  4)
insert into ccTimeZoneArea  values (10, ''21'', ''SE - Rio de Janeiro (Capital)'',  8,  4)
insert into ccTimeZoneArea  values (10, ''22'', ''SE - Nova Friburgo''           ,  8,  4)
insert into ccTimeZoneArea  values (10, ''24'', ''SE - Volta Redonda''           ,  8,  4)
insert into ccTimeZoneArea  values (10, ''27'', ''SE - Vitória''                 ,  8,  4)
insert into ccTimeZoneArea  values (10, ''28'', ''SE - Cachoeiro de Itapemirim'' ,  8,  4)
insert into ccTimeZoneArea  values (10, ''31'', ''SE - Viçosa''                  ,  8,  4)
insert into ccTimeZoneArea  values (10, ''32'', ''SE - Ubá''                     ,  8,  4)
insert into ccTimeZoneArea  values (10, ''33'', ''SE - Governador Valadares''    ,  8,  4)
insert into ccTimeZoneArea  values (10, ''34'', ''SE - Uberlândia''              ,  8,  4)
insert into ccTimeZoneArea  values (10, ''35'', ''SE - Varginha''                ,  8,  4)
insert into ccTimeZoneArea  values (10, ''37'', ''SE - Piumhi''                  ,  8,  4)
insert into ccTimeZoneArea  values (10, ''38'', ''SE - Montes Claros''           ,  8,  4)
insert into ccTimeZoneArea  values (10, ''41'', ''S - Curitiba''                 ,  8,  4)
insert into ccTimeZoneArea  values (10, ''42'', ''S - Ponta Grossa''             ,  8,  4)
insert into ccTimeZoneArea  values (10, ''43'', ''S - Ventania''                 ,  8,  4)
insert into ccTimeZoneArea  values (10, ''44'', ''S - Umuarama''                 ,  8,  4)
insert into ccTimeZoneArea  values (10, ''45'', ''S - Toledo''                   ,  8,  4)
insert into ccTimeZoneArea  values (10, ''46'', ''S - Pato Branco''              ,  8,  4)
insert into ccTimeZoneArea  values (10, ''47'', ''S - Navegantes''               ,  8,  4)
insert into ccTimeZoneArea  values (10, ''48'', ''S - Florianópolis''            ,  8,  4)
insert into ccTimeZoneArea  values (10, ''49'', ''S - Lages''                    ,  8,  4)
insert into ccTimeZoneArea  values (10, ''51'', ''S - Santa Cruz do Sul''        ,  8,  4)
insert into ccTimeZoneArea  values (10, ''53'', ''S - Rio Grande''               ,  8,  4)
insert into ccTimeZoneArea  values (10, ''54'', ''S - Passo Fundo''              ,  8,  4)
insert into ccTimeZoneArea  values (10, ''55'', ''S - Santa Maria''              ,  8,  4)
insert into ccTimeZoneArea  values (10, ''61'', ''CO - Brasília''                ,  8,  4)
insert into ccTimeZoneArea  values (10, ''62'', ''CO - Santa Isabel''            ,  8,  4)
insert into ccTimeZoneArea  values (10, ''63'', ''N - Palmas''                   ,  8,  4)
insert into ccTimeZoneArea  values (10, ''64'', ''CO - Rio Verde''               ,  8,  4)
insert into ccTimeZoneArea  values (10, ''65'', ''CO - Cuiabá''                  , 16,  8)
insert into ccTimeZoneArea  values (10, ''66'', ''CO - Rondonópolis''            , 16,  8)
insert into ccTimeZoneArea  values (10, ''67'', ''CO - Três Lagoas''             , 16,  8)
insert into ccTimeZoneArea  values (10, ''68'', ''N - Rio Branco''               , 16, 16)
insert into ccTimeZoneArea  values (10, ''69'', ''N - Porto Velho''              , 16, 16)
insert into ccTimeZoneArea  values (10, ''71'', ''NE - Salvador''                ,  8,  8)
insert into ccTimeZoneArea  values (10, ''73'', ''NE - Ilhéus''                  ,  8,  8)
insert into ccTimeZoneArea  values (10, ''74'', ''NE - Mundo Novo''              ,  8,  8)
insert into ccTimeZoneArea  values (10, ''75'', ''NE - Santa Quitéria''          ,  8,  8)
insert into ccTimeZoneArea  values (10, ''77'', ''NE - Vitória da Conquista''    ,  8,  8)
insert into ccTimeZoneArea  values (10, ''79'', ''NE - Aracaju''                 ,  8,  8)
insert into ccTimeZoneArea  values (10, ''81'', ''NE - Xexéu''                   ,  8,  8)
insert into ccTimeZoneArea  values (10, ''82'', ''NE - Maceió''                  ,  8,  8)
insert into ccTimeZoneArea  values (10, ''83'', ''NE - João Pessoa''             ,  8,  8)
insert into ccTimeZoneArea  values (10, ''84'', ''NE - Natal''                   ,  8,  8)
insert into ccTimeZoneArea  values (10, ''85'', ''NE - Fortaleza''               ,  8,  8)
insert into ccTimeZoneArea  values (10, ''86'', ''NE - Teresina''                ,  8,  8)
insert into ccTimeZoneArea  values (10, ''87'', ''NE - Petrolina''               ,  8,  8)
insert into ccTimeZoneArea  values (10, ''88'', ''NE - Juazeiro do Norte''       ,  8,  8)
insert into ccTimeZoneArea  values (10, ''89'', ''NE - Picos''                   ,  8,  8)
insert into ccTimeZoneArea  values (10, ''91'', ''N - Belém''                    ,  8,  8)
insert into ccTimeZoneArea  values (10, ''92'', ''N - Manaus''                   , 16, 16)
insert into ccTimeZoneArea  values (10, ''93'', ''N - Santarém''                 ,  8,  8)
insert into ccTimeZoneArea  values (10, ''94'', ''N - Marabá''                   ,  8,  8)
insert into ccTimeZoneArea  values (10, ''95'', ''N - Boa Vista''                , 16, 16)
insert into ccTimeZoneArea  values (10, ''96'', ''N - Macapá''                   ,  8,  8)
insert into ccTimeZoneArea  values (10, ''97'', ''N - Coari''                    , 16, 16)
insert into ccTimeZoneArea  values (10, ''98'', ''NE - São Luís''                ,  8,  8)
insert into ccTimeZoneArea  values (10, ''99'', ''NE - Imperatriz''              ,  8,  8)'
					
	EXEC(@Sql)
	
		set @process = 'cstoProvedor - Insert'
		set @Sql = 'insert into cstoProvedor ([descrip],[codigoCarrierBR]) values (''Embratel''		,''21'')
insert into cstoProvedor ([descrip],[codigoCarrierBR]) values (''Intelig''		,''23'')
insert into cstoProvedor ([descrip],[codigoCarrierBR]) values (''Telemar''		,''31'')
insert into cstoProvedor ([descrip],[codigoCarrierBR]) values (''Brasil Telecom''	,''14'')
insert into cstoProvedor ([descrip],[codigoCarrierBR]) values (''Telefónica''		,''15'')
insert into cstoProvedor ([descrip],[codigoCarrierBR]) values (''TIM''			,''41'')
insert into cstoProvedor ([descrip],[codigoCarrierBR]) values (''CTBC''			,''12'')
insert into cstoProvedor ([descrip],[codigoCarrierBR]) values (''GVT''			,''25'')
insert into cstoProvedor ([descrip],[codigoCarrierBR]) values (''Transit''		,''17'')'
					
	EXEC(@Sql)
	
		set @process = 'seriesBR - Insert'
		set @Sql = 'insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''20100000'', ''25519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''25490000'', ''25599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''25610000'', ''25699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''25710000'', ''26999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''27110000'', ''27199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''27210000'', ''27399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''27410000'', ''27499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''27510000'', ''27599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''27660000'', ''27799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''27810000'', ''27999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28010000'', ''28059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28070000'', ''28099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28110000'', ''28159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28170000'', ''28199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28210000'', ''28259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28270000'', ''28279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28290000'', ''28299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28310000'', ''28359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28370000'', ''28459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28470000'', ''28559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28570000'', ''28609999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28680000'', ''28689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28700000'', ''28859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''28870000'', ''29999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''30090000'', ''33739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''33750000'', ''35399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''35410000'', ''37539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''37550000'', ''39999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''40010000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''40070000'', ''40073999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''40090000'', ''40299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''40310000'', ''40799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''40810000'', ''40899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''40910000'', ''41199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''41210000'', ''41299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''41310000'', ''41399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''41410000'', ''41499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''41510000'', ''41599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''41610000'', ''41699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''41710000'', ''41799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''41810000'', ''41899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''41910000'', ''42299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''42310000'', ''42399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''42410000'', ''42499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''42510000'', ''42599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''42610000'', ''42699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''42710000'', ''42799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''42810000'', ''42895999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''42910000'', ''42919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''42950000'', ''42959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''43010000'', ''43099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''43110000'', ''43199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''43210000'', ''43399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''43410000'', ''43489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''43510000'', ''43689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''43710000'', ''43799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''43810000'', ''43949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''43960000'', ''44039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''44050000'', ''44099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''44110000'', ''44199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''44210000'', ''44399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''44410000'', ''44499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''44510000'', ''44599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''44610000'', ''44669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''44680000'', ''44699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''44720000'', ''44799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''44810000'', ''44899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''44910000'', ''45099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''45110000'', ''45169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''45180000'', ''45199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''45210000'', ''45299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''45310000'', ''45399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''45410000'', ''45499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''45510000'', ''45599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''45610000'', ''45699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''45710000'', ''45789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''45810000'', ''45899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''45910000'', ''45999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''46010000'', ''46099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''46110000'', ''46279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''46340000'', ''46349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''46360000'', ''46369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''46380000'', ''46499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''46510000'', ''46589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''46610000'', ''46699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''46740000'', ''46799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''46810000'', ''46899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''46910000'', ''46979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''46990000'', ''47089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''47110000'', ''47199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''47210000'', ''47299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''47310000'', ''47329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''47350000'', ''47369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''47380000'', ''47499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''47510000'', ''47559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''47570000'', ''47579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''47590000'', ''47649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''47670000'', ''47679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''47710000'', ''47759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''47770000'', ''47799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''47810000'', ''47999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''48010000'', ''48099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''48110000'', ''48139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''48150000'', ''48299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''48310000'', ''48389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''48410000'', ''48499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''48510000'', ''48559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''48650000'', ''48659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''48670000'', ''49329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''49370000'', ''49609999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''49620000'', ''49859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''49880000'', ''49999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''50100000'', ''50199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''50210000'', ''50229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''50290000'', ''50299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''50310000'', ''50369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''50410000'', ''50429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''50440000'', ''50469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''50490000'', ''50499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''50510000'', ''50569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''50580000'', ''50589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''50600000'', ''50639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''50650000'', ''50749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''50770000'', ''50999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''51020000'', ''51039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''51050000'', ''51059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''51100000'', ''51129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''51150000'', ''51159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''51710000'', ''51719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''51800000'', ''51899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''51910000'', ''51919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''52120000'', ''52139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''55010000'', ''55199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''55210000'', ''55299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''55310000'', ''55399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''55410000'', ''55499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''55530000'', ''55539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''55600000'', ''55689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''55710000'', ''55769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''55790000'', ''55799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''55810000'', ''55899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''55910000'', ''55999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56010000'', ''56019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56030000'', ''56039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56110000'', ''56169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56200000'', ''56279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56310000'', ''56359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56410000'', ''56469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56600000'', ''56639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56650000'', ''56799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56810000'', ''56839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56850000'', ''56879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56910000'', ''56919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56930000'', ''56969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''56980000'', ''56999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''58110000'', ''58129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''58140000'', ''58149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''58160000'', ''58199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''58210000'', ''58279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''58310000'', ''58359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''58370000'', ''58379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''58390000'', ''58399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''58410000'', ''58469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''58510000'', ''58559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''58700000'', ''58759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''58900000'', ''58999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''59040000'', ''59049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''59060000'', ''59099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''59200000'', ''59299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''59310000'', ''59349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''59380000'', ''59399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''59700000'', ''59799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''70000000'', ''70099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''77000000'', ''78999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''79010000'', ''79029999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''79040000'', ''79049999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''79060000'', ''79089999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''79100000'', ''79219999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''79230000'', ''79249999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''79280000'', ''79329999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''79340000'', ''79499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''941000000'', ''942089999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''945000000'', ''945599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''949000000'', ''949209999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''950200000'', ''950209999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''950230000'', ''950289999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''950300000'', ''950309999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''950370000'', ''950409999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''950430000'', ''950439999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''950470000'', ''950489999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''950500000'', ''950509999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''950570000'', ''950579999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''950590000'', ''950599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''950640000'', ''950649999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''950750000'', ''950769999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''951000000'', ''951019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''951040000'', ''951049999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''951060000'', ''951099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''951130000'', ''951149999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''951160000'', ''951709999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''951720000'', ''951799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''951900000'', ''951909999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''951920000'', ''952119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''952140000'', ''953249999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''953290000'', ''955009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''955200000'', ''955209999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''955300000'', ''955309999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''955400000'', ''955409999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''955500000'', ''955529999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''955540000'', ''955599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''955690000'', ''955709999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''955770000'', ''955789999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''955800000'', ''955809999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''955900000'', ''955909999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''956000000'', ''956009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''956020000'', ''956029999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''956040000'', ''956109999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''956170000'', ''956199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''956280000'', ''956309999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''956360000'', ''956409999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''956470000'', ''956599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''957000000'', ''958109999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''958130000'', ''958139999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''958150000'', ''958159999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''958200000'', ''958209999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''958280000'', ''958309999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''958360000'', ''958369999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''958380000'', ''958389999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''958400000'', ''958409999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''958470000'', ''958509999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''958560000'', ''958699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''958760000'', ''958899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''959000000'', ''959039999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''959050000'', ''959059999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''959100000'', ''959199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''959300000'', ''959309999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''959350000'', ''959379999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''959400000'', ''959699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''959800000'', ''959999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''960110000'', ''969999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''970110000'', ''976999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''979090000'', ''979099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''979220000'', ''979229999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''979500000'', ''979999999'',''Movil'', ''CPP'')

insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''980100000'', ''989999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São Paulo (Capital)''     ), ''11'', ''991000000'', ''999999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''20210000'', ''20229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''20250000'', ''20259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''21010000'', ''21039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''21220000'', ''21289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''21310000'', ''21319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''21340000'', ''21399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''21440000'', ''21449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''22000000'', ''29999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''30090000'', ''30096999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''30110000'', ''30199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''30210000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''30330000'', ''30369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31010000'', ''31099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31110000'', ''31129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31150000'', ''31179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31190000'', ''31199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31220000'', ''31239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31250000'', ''31289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31310000'', ''31339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31390000'', ''31399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31410000'', ''31419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31430000'', ''31479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31490000'', ''31499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31510000'', ''31539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31550000'', ''31579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31590000'', ''31599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31630000'', ''31634999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31840000'', ''31869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31960000'', ''31969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''32010000'', ''32139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''32210000'', ''32279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''32320000'', ''32359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''32510000'', ''32519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''33010000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''33170000'', ''33171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''33210000'', ''33229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''33330000'', ''33359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''33410000'', ''33469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''33510000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''33610000'', ''33689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''33730000'', ''33789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''33850000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''34110000'', ''34139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''34170000'', ''34173999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''34210000'', ''34229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''34240000'', ''34279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''34310000'', ''34369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''34540000'', ''34589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''35120000'', ''35129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''35190000'', ''35199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''35210000'', ''35229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''35250000'', ''35289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36010000'', ''36029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36040000'', ''36049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36070000'', ''36099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36210000'', ''36279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36290000'', ''36297999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36310000'', ''36359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36370000'', ''36379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36410000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36520000'', ''36599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36610000'', ''36649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36660000'', ''36669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36680000'', ''36699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36710000'', ''36831999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''36860000'', ''36879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''37000000'', ''37009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''37170000'', ''37171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''37970000'', ''37979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''38320000'', ''38369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''38390000'', ''38399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''38420000'', ''38439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''38450000'', ''38459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''38480000'', ''38499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''38610000'', ''38659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''38670000'', ''38679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''38760000'', ''38789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''38810000'', ''38899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''38910000'', ''38979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''38990000'', ''38999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39010000'', ''39139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39160000'', ''39179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39190000'', ''39199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39210000'', ''39299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39310000'', ''39399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39410000'', ''39499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39510000'', ''39599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39610000'', ''39629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39650000'', ''39699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39710000'', ''39729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39740000'', ''39759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39780000'', ''39799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39810000'', ''39813999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''39900000'', ''39909999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''40010000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''41010000'', ''41049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''41080000'', ''41101999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''45010000'', ''45019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''78110000'', ''78229999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''78500000'', ''78509999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''78980000'', ''78989999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''81000000'', ''82759999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''85990000'', ''85999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''87000000'', ''87129999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''88000000'', ''88999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''91000000'', ''92589999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''96000000'', ''96689999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José dos Campos''     ), ''12'', ''97000000'', ''97999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''21040000'', ''21059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''21270000'', ''21279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''21380000'', ''21389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''22020000'', ''22029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''27700000'', ''27709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''30090000'', ''30096999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''30110000'', ''30199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''30210000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''30320000'', ''30379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''30400000'', ''30449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''30480000'', ''30489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''30610000'', ''30629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''31130000'', ''31139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''31960000'', ''31969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32010000'', ''32039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32050000'', ''32059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32070000'', ''32099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32110000'', ''32139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32160000'', ''32169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32190000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32210000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32310000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32490000'', ''32499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32510000'', ''32529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32570000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32610000'', ''32619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32640000'', ''32649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32660000'', ''32669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32680000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32710000'', ''32739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32780000'', ''32799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32810000'', ''32819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32840000'', ''32869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32880000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32910000'', ''32919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32950000'', ''32969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''32980000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''33160000'', ''33179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''33190000'', ''33199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''33210000'', ''33299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''33330000'', ''33331999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''33410000'', ''33499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''33510000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''33610000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''33710000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''33810000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''33910000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34060000'', ''34069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34090000'', ''34098999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34110000'', ''34119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34160000'', ''34169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34180000'', ''34199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34210000'', ''34229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34240000'', ''34279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34290000'', ''34299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34450000'', ''34469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34480000'', ''34489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34510000'', ''34519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34530000'', ''34589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34610000'', ''34699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34710000'', ''34749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34760000'', ''34799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34810000'', ''34819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34910000'', ''34919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34930000'', ''34969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''34990000'', ''35001999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''35050000'', ''35079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''35130000'', ''35139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''35190000'', ''35199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''35210000'', ''35289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''35530000'', ''35539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''35610000'', ''35619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''35630000'', ''35699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''35760000'', ''35769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''35790000'', ''35799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''35910000'', ''35949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''35960000'', ''35969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''37000000'', ''37009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''37970000'', ''37979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''38000000'', ''38001999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''38210000'', ''38229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''38280000'', ''38299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''38410000'', ''38449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''38460000'', ''38499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''38510000'', ''38569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''38620000'', ''38623999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''38640000'', ''38649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''38710000'', ''38739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''38770000'', ''38799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''38890000'', ''38899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''38990000'', ''38999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''39900000'', ''39919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''40070000'', ''40073999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''40090000'', ''40109999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''41010000'', ''41079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''41090000'', ''41093999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''78020000'', ''78289999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''78500000'', ''78509999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''81000000'', ''82109999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''82140000'', ''82149999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''85990000'', ''85999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''88010000'', ''88799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''88840000'', ''88849999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''91000000'', ''92149999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''96000000'', ''96729999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Santos''                  ), ''13'', ''97000000'', ''97999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''20320000'', ''20349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''21040000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''23000000'', ''23009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''23230000'', ''23239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''23300000'', ''23309999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''24230000'', ''24239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''30090000'', ''30096999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''30110000'', ''30119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''30150000'', ''30169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''30180000'', ''30199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''30210000'', ''30229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''30250000'', ''30269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''30320000'', ''30339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''31000000'', ''31004999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''31020000'', ''31049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''31060000'', ''31069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''31080000'', ''31099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''31110000'', ''31139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''31170000'', ''31189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32010000'', ''32161999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32180000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32210000'', ''32243999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32260000'', ''32279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32310000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32410000'', ''32499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32510000'', ''32579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32610000'', ''32659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32670000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32710000'', ''32719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32730000'', ''32799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32810000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''32910000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33160000'', ''33199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33210000'', ''33229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33240000'', ''33269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33320000'', ''33329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33350000'', ''33359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33410000'', ''33469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33510000'', ''33579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33610000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33720000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33820000'', ''33829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33850000'', ''33879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33890000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''33990000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34010000'', ''34029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34040000'', ''34089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34110000'', ''34199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34210000'', ''34226999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34240000'', ''34289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34320000'', ''34349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34410000'', ''34417999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34510000'', ''34549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34560000'', ''34599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34710000'', ''34799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34810000'', ''34819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34840000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34910000'', ''34939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''34950000'', ''34968999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35110000'', ''35139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35190000'', ''35199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35220000'', ''35239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35290000'', ''35299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35320000'', ''35339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35350000'', ''35359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35410000'', ''35439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35460000'', ''35479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35490000'', ''35499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35520000'', ''35549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35560000'', ''35569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35580000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35700000'', ''35703999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35720000'', ''35741999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35770000'', ''35771999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35810000'', ''35899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35910000'', ''35921999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''35970000'', ''35979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36010000'', ''36049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36110000'', ''36111999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36190000'', ''36199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36210000'', ''36271999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36290000'', ''36299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36320000'', ''36331999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36360000'', ''36361999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36410000'', ''36429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36440000'', ''36449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36460000'', ''36469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36520000'', ''36549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36560000'', ''36569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36620000'', ''36649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36660000'', ''36689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36710000'', ''36711999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36740000'', ''36741999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36810000'', ''36811999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36910000'', ''36911999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''36990000'', ''37009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''37070000'', ''37079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''37110000'', ''37119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''37130000'', ''37149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''37170000'', ''37179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''37190000'', ''37199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''37210000'', ''37239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''37310000'', ''37339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''37370000'', ''37379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''37390000'', ''37399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''37610000'', ''37699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''38110000'', ''38159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''38190000'', ''38199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''38410000'', ''38499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''38770000'', ''38799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''38810000'', ''38899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''39170000'', ''39179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''41010000'', ''41069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''41080000'', ''41089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''78110000'', ''78119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''78340000'', ''78349999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''81000000'', ''82319999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''88000000'', ''88349999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''91010000'', ''91499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''91510000'', ''91599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''91610000'', ''91699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''91710000'', ''91799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''91810000'', ''91899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''91910000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Botucatu''                ), ''14'', ''96000000'', ''99119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''21010000'', ''21059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''21070000'', ''21089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''21810000'', ''21829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''22000000'', ''26999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''27700000'', ''27709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''30090000'', ''30096999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''30110000'', ''30199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''30210000'', ''30279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''30310000'', ''30379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''31000000'', ''31004999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''31150000'', ''31159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''31630000'', ''31634999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''31870000'', ''31879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32010000'', ''32089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32110000'', ''32139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32170000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32210000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32310000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32410000'', ''32499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32510000'', ''32539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32550000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32610000'', ''32649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32660000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32710000'', ''32799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32810000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32910000'', ''32949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''32970000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33010000'', ''33039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33050000'', ''33059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33070000'', ''33079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33150000'', ''33199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33210000'', ''33369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33390000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33610000'', ''33649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33660000'', ''33689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33720000'', ''33801999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33830000'', ''33891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33910000'', ''33929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33940000'', ''33949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''33960000'', ''33969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34110000'', ''34189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34250000'', ''34259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34310000'', ''34319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34420000'', ''34429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34440000'', ''34449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34510000'', ''34519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34540000'', ''34549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34570000'', ''34579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34590000'', ''34599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34610000'', ''34619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34660000'', ''34679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34710000'', ''34721999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34760000'', ''34789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34810000'', ''34819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34870000'', ''34879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''34910000'', ''34949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35110000'', ''35119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35130000'', ''35139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35190000'', ''35199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35210000'', ''35279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35290000'', ''35299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35310000'', ''35389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35410000'', ''35449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35460000'', ''35489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35510000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35610000'', ''35675999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35710000'', ''35739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35770000'', ''35789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35810000'', ''35819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''35840000'', ''35899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''36150000'', ''36159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''36240000'', ''36249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''36460000'', ''36469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''36530000'', ''36539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''36560000'', ''36569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''36650000'', ''36657999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''37000000'', ''37009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''40620000'', ''40639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''41010000'', ''41021999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''44000000'', ''44007201'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''78110000'', ''78149999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''78340000'', ''78379999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''81000000'', ''81839999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''81850000'', ''81869999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''88000000'', ''88349999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''91010000'', ''91099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''91110000'', ''91199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''91210000'', ''91299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''91310000'', ''91399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''91410000'', ''91499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''91510000'', ''91599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''91610000'', ''91699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''91710000'', ''91799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''91810000'', ''91899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''91910000'', ''91939999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''92010000'', ''92019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Sorocaba''                ), ''15'', ''96000000'', ''98649999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''20520000'', ''20529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''21010000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''21110000'', ''21119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''21320000'', ''21339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''21370000'', ''21389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''21410000'', ''21419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''23230000'', ''23239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''23300000'', ''23309999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''30090000'', ''30096999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''30110000'', ''30139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''30150000'', ''30159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''30170000'', ''30199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''30210000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''30320000'', ''30339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''30410000'', ''30439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''30750000'', ''30761999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''31110000'', ''31124999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''31140000'', ''31199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''31330000'', ''31359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''31420000'', ''31439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''31450000'', ''31469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''31630000'', ''31649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''31710000'', ''31739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''31760000'', ''31769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32010000'', ''32059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32080000'', ''32099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32110000'', ''32129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32140000'', ''32149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32180000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32210000'', ''32219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32260000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32310000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32410000'', ''32489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32510000'', ''32589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32620000'', ''32639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32650000'', ''32689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32720000'', ''32779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''32810000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''33110000'', ''33149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''33160000'', ''33199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''33210000'', ''33299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''33310000'', ''33399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''33410000'', ''33499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''33510000'', ''33589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''33610000'', ''33649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''33660000'', ''33689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''33710000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''33810000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''33910000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34010000'', ''34069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34080000'', ''34099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34110000'', ''34199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34210000'', ''34259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34320000'', ''34399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34410000'', ''34469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34510000'', ''34579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34610000'', ''34699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34710000'', ''34729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34740000'', ''34759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34810000'', ''34849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34860000'', ''34869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34880000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34910000'', ''34939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34950000'', ''34959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''34970000'', ''34979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''35010000'', ''35019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''35050000'', ''35099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''35110000'', ''35199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''35210000'', ''35289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''35350000'', ''35359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''35530000'', ''35539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''35670000'', ''35679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''36010000'', ''36059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''36070000'', ''36079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''36100000'', ''36129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''36150000'', ''36159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''36170000'', ''36189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''36200000'', ''36309999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''36320000'', ''36339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''36350000'', ''36399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''36590000'', ''36699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''36900000'', ''36909999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''36930000'', ''36933999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''37000000'', ''37081999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''37110000'', ''37139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''37170000'', ''37179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''37200000'', ''37299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''37490000'', ''37491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''37510000'', ''37529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''37580000'', ''37599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''37610000'', ''37619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''37630000'', ''37639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''37970000'', ''37979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38000000'', ''38001999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38100000'', ''38119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38180000'', ''38189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38200000'', ''38219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38230000'', ''38239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38260000'', ''38269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38290000'', ''38329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38350000'', ''38359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38380000'', ''38399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38470000'', ''38479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38510000'', ''38529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38580000'', ''38599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''38770000'', ''38789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39020000'', ''39029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39040000'', ''39059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39110000'', ''39119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39130000'', ''39149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39160000'', ''39179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39190000'', ''39199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39290000'', ''39299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39310000'', ''39319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39330000'', ''39349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39390000'', ''39399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39410000'', ''39479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39490000'', ''39499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39510000'', ''39549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39560000'', ''39589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39610000'', ''39699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39720000'', ''39779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39790000'', ''39799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39810000'', ''39849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39860000'', ''39879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39910000'', ''39919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39930000'', ''39939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39950000'', ''39969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''39980000'', ''39999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''40010000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''40420000'', ''40428999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''41010000'', ''41032999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''78110000'', ''78169999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''81000000'', ''82609999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''88010000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''88510000'', ''88689999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''91000000'', ''94169999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''96000000'', ''96249999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''97000000'', ''97999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''99610000'', ''99699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''99710000'', ''99739999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''99750000'', ''99759999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''99780000'', ''99799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''99860000'', ''99895999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Serrana''                 ), ''16'', ''99910000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''20210000'', ''20219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''20410000'', ''20449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''21010000'', ''21019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''21350000'', ''21399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''22440000'', ''22459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''23000000'', ''23009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''27300000'', ''27309999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''29320000'', ''29329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''30090000'', ''30096999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''30110000'', ''30179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''30210000'', ''30229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''30330000'', ''30339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''30430000'', ''30469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''30910000'', ''30919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''31010000'', ''31029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''31050000'', ''31053999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''31210000'', ''31229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32010000'', ''32039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32060000'', ''32066999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32090000'', ''32099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32110000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32210000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32310000'', ''32389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32420000'', ''32438999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32450000'', ''32459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32470000'', ''32499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32510000'', ''32519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32530000'', ''32549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32560000'', ''32589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32610000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32710000'', ''32729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32740000'', ''32859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32870000'', ''32875999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32910000'', ''32939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''32950000'', ''32959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33010000'', ''33091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33110000'', ''33141999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33170000'', ''33181999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33210000'', ''33359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33370000'', ''33371999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33410000'', ''33499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33510000'', ''33511999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33530000'', ''33561999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33580000'', ''33681999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33710000'', ''33711999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33730000'', ''33791999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33820000'', ''33821999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33840000'', ''33841999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33860000'', ''33871999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33890000'', ''33891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33910000'', ''33931999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33950000'', ''33961999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''33980000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34010000'', ''34011999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34040000'', ''34069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34090000'', ''34091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34110000'', ''34111999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34210000'', ''34239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34260000'', ''34269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34410000'', ''34429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34450000'', ''34469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34530000'', ''34539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34610000'', ''34639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34650000'', ''34699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34720000'', ''34729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34750000'', ''34759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34780000'', ''34789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''34810000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35110000'', ''35139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35190000'', ''35199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35210000'', ''35259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35290000'', ''35299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35310000'', ''35319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35410000'', ''35439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35450000'', ''35489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35510000'', ''35539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35560000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35610000'', ''35679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35710000'', ''35739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35760000'', ''35769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35790000'', ''35799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''35870000'', ''35879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''36210000'', ''36229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''36240000'', ''36249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''36310000'', ''36399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''36410000'', ''36439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''36480000'', ''36489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''36510000'', ''36519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''36590000'', ''36599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''36610000'', ''36649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''36670000'', ''36679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''36810000'', ''36819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''36910000'', ''36959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''36990000'', ''37009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38010000'', ''38029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38070000'', ''38099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38110000'', ''38199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38230000'', ''38239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38260000'', ''38279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38290000'', ''38299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38310000'', ''38399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38410000'', ''38499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38570000'', ''38575999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38740000'', ''38769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38790000'', ''38799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38860000'', ''38866999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38880000'', ''38899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38930000'', ''38939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38950000'', ''38979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''38990000'', ''38999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''41010000'', ''41011999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''77770000'', ''77779999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''78110000'', ''78129999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''78780000'', ''78789999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''81000000'', ''82139999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''88010000'', ''88329999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''91000000'', ''92709999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''96010000'', ''96099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''96110000'', ''96199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''96210000'', ''96299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''96310000'', ''96399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''96410000'', ''96709999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''97010000'', ''97099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''97110000'', ''97199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''97210000'', ''97299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''97310000'', ''97399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''97410000'', ''97499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''97510000'', ''97599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''97610000'', ''97699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''97710000'', ''97899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''97910000'', ''97949999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''99740000'', ''99799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - São José do Rio Preto''   ), ''17'', ''99960000'', ''99969999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''20350000'', ''20359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''21010000'', ''21059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''22420000'', ''22439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''23000000'', ''23009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''30090000'', ''30096999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''30150000'', ''30159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''30210000'', ''30229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''31170000'', ''31189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32010000'', ''32071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32090000'', ''32091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32110000'', ''32141999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32160000'', ''32181999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32210000'', ''32239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32250000'', ''32271999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32290000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32310000'', ''32311999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32330000'', ''32331999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32350000'', ''32351999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32370000'', ''32371999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32410000'', ''32411999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32430000'', ''32431999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32450000'', ''32451999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32470000'', ''32471999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32490000'', ''32491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32510000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32610000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32710000'', ''32799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32810000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32910000'', ''32911999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32930000'', ''32942999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32960000'', ''32961999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''32980000'', ''32981999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33110000'', ''33121999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33140000'', ''33141999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33160000'', ''33189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33210000'', ''33261999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33280000'', ''33299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33310000'', ''33311999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33330000'', ''33349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33410000'', ''33429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33440000'', ''33469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33490000'', ''33499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33510000'', ''33529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33540000'', ''33569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33590000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33610000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''33710000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''34010000'', ''34039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''34060000'', ''34079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''34210000'', ''34229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''34410000'', ''34419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''34620000'', ''34629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''34690000'', ''34699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''34790000'', ''34799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''35020000'', ''35029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''35170000'', ''35171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''35190000'', ''35199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''35210000'', ''35229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''35280000'', ''35299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''35310000'', ''35319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''35510000'', ''35526999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''35560000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''35710000'', ''35716999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''35790000'', ''35799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''35810000'', ''35839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''35860000'', ''35869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''36010000'', ''36099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''36210000'', ''36259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''36270000'', ''36279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''36310000'', ''36319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''36340000'', ''36349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''36360000'', ''36369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''36380000'', ''36399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''36410000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''36510000'', ''36599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''36910000'', ''36999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''37010000'', ''37099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''37210000'', ''37239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''37290000'', ''37299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''37410000'', ''37489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''37860000'', ''37869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''37880000'', ''37899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''38210000'', ''38239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''38390000'', ''38399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''38410000'', ''38429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''38510000'', ''38519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''38550000'', ''38579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''38590000'', ''38599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''38610000'', ''38629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''38660000'', ''38669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''38690000'', ''38699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''38710000'', ''38729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''38750000'', ''38769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''39010000'', ''39099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''39110000'', ''39119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''39130000'', ''39139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''39160000'', ''39199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''39280000'', ''39289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''39410000'', ''39429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''39590000'', ''39599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''39690000'', ''39699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''39790000'', ''39799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''39810000'', ''39818999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''39910000'', ''39999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''41010000'', ''41019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''41030000'', ''41041999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''81000000'', ''81979999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''88010000'', ''88269999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''91000000'', ''91939999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''91970000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Presidente Prudente''     ), ''18'', ''96000000'', ''98239999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''20210000'', ''20219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''20280000'', ''20289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''20550000'', ''20579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''21010000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''21110000'', ''21199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''21210000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''21260000'', ''21299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''21320000'', ''21349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''21360000'', ''21399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''21410000'', ''21419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''21430000'', ''21449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''21460000'', ''21479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''21510000'', ''21519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''22440000'', ''22449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''23000000'', ''23009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''23330000'', ''23339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''24230000'', ''24239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''25110000'', ''25199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''25320000'', ''25389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''27700000'', ''27709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''29320000'', ''29329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''30090000'', ''30199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''30210000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''30310000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''30410000'', ''30479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''30530000'', ''30569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''30900000'', ''30909999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31000000'', ''31029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31120000'', ''31171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31190000'', ''31199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31210000'', ''31249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31290000'', ''31299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31370000'', ''31379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31510000'', ''31519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31630000'', ''31634999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31810000'', ''31813999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31860000'', ''31879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31960000'', ''31969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''32000000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''32210000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''32310000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''32410000'', ''32499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''32510000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''32610000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''32710000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''32910000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''33160000'', ''33299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''33330000'', ''33399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''33410000'', ''33499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''33510000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''33610000'', ''33689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''33710000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''33810000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''33910000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''34010000'', ''34099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''34110000'', ''34199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''34210000'', ''34399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''34410000'', ''34499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''34510000'', ''34599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''34610000'', ''34699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''34710000'', ''34799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''34810000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''34910000'', ''35099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''35110000'', ''35199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''35210000'', ''35299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''35310000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''35610000'', ''35699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''35710000'', ''35799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''35810000'', ''35999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''36010000'', ''36099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''36110000'', ''36139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''36160000'', ''36199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''36210000'', ''36299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''36310000'', ''36399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''36410000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''36510000'', ''36599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''36610000'', ''36699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''36710000'', ''36799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''36810000'', ''36899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''36910000'', ''37239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''37250000'', ''37299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''37310000'', ''37399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''37410000'', ''37499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''37510000'', ''37599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''37610000'', ''37699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''37710000'', ''37799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''37810000'', ''37999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''38010000'', ''38099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''38110000'', ''38199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''38210000'', ''38229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''38240000'', ''38299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''38310000'', ''38399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''38410000'', ''38499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''38510000'', ''38599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''38610000'', ''38699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''38710000'', ''38799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''38810000'', ''38899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''38910000'', ''38999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39010000'', ''39099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39110000'', ''39139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39170000'', ''39171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39210000'', ''39299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39330000'', ''39399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39410000'', ''39459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39480000'', ''39489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39530000'', ''39539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39550000'', ''39591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39610000'', ''39689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39770000'', ''39779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39790000'', ''39799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39840000'', ''39849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39880000'', ''39885999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39900000'', ''39929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39960000'', ''39969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''39980000'', ''39989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''40010000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''40070000'', ''40073999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''41010000'', ''41099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''41110000'', ''41199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''41210000'', ''41224999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''41240000'', ''41241999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''41260000'', ''41269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''41290000'', ''41309999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''45010000'', ''45014999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''47000000'', ''47001999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''77000000'', ''77009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''78010000'', ''78339999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''78500000'', ''78519999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''81000000'', ''84389999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''85990000'', ''85999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''87000000'', ''87479999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''87650000'', ''87739999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''87790000'', ''87839999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''88000000'', ''89369999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vinhedo''                 ), ''19'', ''91000000'', ''99799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''20040000'', ''20089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''20100000'', ''20119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''20140000'', ''20149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''20160000'', ''20169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''20200000'', ''20209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''20230000'', ''20359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''20400000'', ''20409999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''20500000'', ''20509999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''20600000'', ''20609999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''20650000'', ''20656999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''21010000'', ''21179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''21210000'', ''21239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''21250000'', ''21299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''21310000'', ''21399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''21410000'', ''21499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''21510000'', ''21599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''21610000'', ''21699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''21720000'', ''21799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''21810000'', ''21879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''21890000'', ''21899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''21950000'', ''21979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''21990000'', ''21999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''22010000'', ''22999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''23010000'', ''23019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''23030000'', ''23039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''23230000'', ''23239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''23320000'', ''23349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''23540000'', ''23549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''23800000'', ''23809999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''23910000'', ''23919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''23940000'', ''23949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''23970000'', ''23979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''24010000'', ''24999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''25010000'', ''25999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''26010000'', ''26399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''26410000'', ''26839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''26850000'', ''26899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''26910000'', ''27259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27270000'', ''27309999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27340000'', ''27349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27360000'', ''27379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27390000'', ''27399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27410000'', ''27439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27450000'', ''27459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27470000'', ''27479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27510000'', ''27539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27550000'', ''27599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27610000'', ''27739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27750000'', ''27899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27910000'', ''27929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27960000'', ''27979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''27990000'', ''27999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''28680000'', ''28689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''28810000'', ''28829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''28860000'', ''28869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''29110000'', ''29199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''29210000'', ''29299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''29320000'', ''29329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''29510000'', ''29529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''29760000'', ''29769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''30020000'', ''30059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''30100000'', ''30599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''30610000'', ''30699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''30710000'', ''30799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''30810000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''34010000'', ''34199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''34210000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''34910000'', ''35799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''35810000'', ''35899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''35910000'', ''35999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''36010000'', ''36349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''36360000'', ''36789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''36800000'', ''36899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''36910000'', ''36945999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''36960000'', ''36969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''36980000'', ''37179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''37190000'', ''37279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''37310000'', ''37391999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''37410000'', ''37499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''37520000'', ''37579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''37590000'', ''37859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''37870000'', ''37879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''37890000'', ''37899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''37930000'', ''38001999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38030000'', ''38069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38080000'', ''38089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38120000'', ''38189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38200000'', ''38209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38220000'', ''38249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38260000'', ''38269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38300000'', ''38319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38330000'', ''38339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38350000'', ''38379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38390000'', ''38399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38410000'', ''38589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38600000'', ''38619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38650000'', ''38919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38950000'', ''38959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''38980000'', ''38999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''39010000'', ''39099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''39150000'', ''39169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''39230000'', ''39249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''39320000'', ''39399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''39420000'', ''39429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''39560000'', ''39589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''39700000'', ''39899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''39950000'', ''39959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''40010000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''40070000'', ''40073999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''40090000'', ''40109999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''40520000'', ''40529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''40620000'', ''40639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''41010000'', ''41099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''41110000'', ''41199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''41210000'', ''41299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''41310000'', ''41399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''41410000'', ''41492999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''44000000'', ''44007000'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''45010000'', ''45069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''47000000'', ''47009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''60990000'', ''60999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''62010000'', ''62019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''67000000'', ''67479999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''68000000'', ''68889999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''69000000'', ''69979999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''70100000'', ''70209999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''70990000'', ''89409999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Rio de Janeiro (Capital)''), ''21'', ''91000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''20050000'', ''20069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''20080000'', ''20109999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''20200000'', ''20209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''20220000'', ''20229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''20300000'', ''20319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''20400000'', ''20409999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''20500000'', ''20509999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''20600000'', ''20609999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''20700000'', ''20709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''20800000'', ''20809999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''20900000'', ''20909999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''21010000'', ''21039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''21050000'', ''21069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''21230000'', ''21239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''21330000'', ''21339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''21410000'', ''21449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''21610000'', ''21619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''22100000'', ''22109999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''22990000'', ''22999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''25190000'', ''25299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''25310000'', ''25319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''25330000'', ''25349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''25370000'', ''25379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''25400000'', ''25439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''25510000'', ''25569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''25590000'', ''25599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''25610000'', ''25619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''25640000'', ''25669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''25800000'', ''25809999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''26200000'', ''26259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''26270000'', ''26279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''26290000'', ''26309999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''26330000'', ''26349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''26400000'', ''26409999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''26430000'', ''26499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''26510000'', ''26559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''26570000'', ''26579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''26610000'', ''26629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''26640000'', ''26689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''26730000'', ''26749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''26840000'', ''26849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27200000'', ''27299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27310000'', ''27399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27410000'', ''27419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27470000'', ''27489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27510000'', ''27516999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27530000'', ''27539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27560000'', ''27749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27760000'', ''27815999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27830000'', ''27839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27850000'', ''27859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27890000'', ''27899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27910000'', ''27939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''27960000'', ''27975999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''30140000'', ''30199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''30210000'', ''30249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''30270000'', ''30279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''30510000'', ''30589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''30660000'', ''30679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''30810000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''30940000'', ''30949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''30970000'', ''30979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''31000000'', ''31004999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''31100000'', ''31499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''32010000'', ''32069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''32110000'', ''32139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''32210000'', ''32239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''32330000'', ''32349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''32610000'', ''32629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''33010000'', ''33019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''33060000'', ''33061999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''33080000'', ''33089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''33110000'', ''33129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''33210000'', ''33249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''33330000'', ''33339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''33430000'', ''33459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''33770000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''33990000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''35120000'', ''35129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''35180000'', ''35189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''35620000'', ''35629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''37000000'', ''37008999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''37170000'', ''37171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''37220000'', ''37239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''37370000'', ''37379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''38110000'', ''38119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''38200000'', ''38209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''38220000'', ''38249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''38260000'', ''38299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''38310000'', ''38339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''38350000'', ''38359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''38410000'', ''38449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''38470000'', ''38479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''38500000'', ''38559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''38610000'', ''38669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''41030000'', ''41051999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''78110000'', ''78189999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''78340000'', ''78369999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''81000000'', ''81799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''88510000'', ''88549999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''88570000'', ''88579999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''91010000'', ''91059999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''92010000'', ''92199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''92210000'', ''92299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''92310000'', ''92399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''92410000'', ''92499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''92510000'', ''92599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''92610000'', ''92699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''92710000'', ''92799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''92810000'', ''92939999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''96000000'', ''96419999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Nova Friburgo''           ), ''22'', ''97000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''20060000'', ''20069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''20100000'', ''20119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''20200000'', ''20219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''21020000'', ''21049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''21060000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''21320000'', ''21349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22200000'', ''22262999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22280000'', ''22289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22310000'', ''22339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22350000'', ''22379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22420000'', ''22499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22510000'', ''22529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22540000'', ''22559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22570000'', ''22599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22630000'', ''22639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22660000'', ''22669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22710000'', ''22729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22800000'', ''22809999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''22910000'', ''22929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24010000'', ''24019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24110000'', ''24119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24200000'', ''24209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24240000'', ''24249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24300000'', ''24319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24330000'', ''24339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24370000'', ''24389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24420000'', ''24459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24470000'', ''24479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24520000'', ''24539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24550000'', ''24559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24570000'', ''24589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24630000'', ''24639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24650000'', ''24659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24680000'', ''24683999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24710000'', ''24719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24830000'', ''24859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24870000'', ''24889999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''24910000'', ''24919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''30140000'', ''30171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''30210000'', ''30229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''30610000'', ''30659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''30710000'', ''30769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''30910000'', ''30939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''30950000'', ''30969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''31000000'', ''31009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''31100000'', ''31349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''32010000'', ''32069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''32080000'', ''32089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''32110000'', ''32159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''32210000'', ''32219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''33010000'', ''33029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''33060000'', ''33069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''33110000'', ''33119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''33200000'', ''33299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''33320000'', ''33741999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''33760000'', ''33779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''33790000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''33810000'', ''33819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''33830000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''33990000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''34010000'', ''34029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''34110000'', ''34119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''34210000'', ''34229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''35120000'', ''35129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''35170000'', ''35179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''37000000'', ''37004999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''37230000'', ''37249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''41020000'', ''41051999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''78110000'', ''78169999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''78340000'', ''78369999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''81000000'', ''81399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''81410000'', ''81599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''81610000'', ''81699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''81710000'', ''81749999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''81820000'', ''81829999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''88610000'', ''88659999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''92000000'', ''93149999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''93950000'', ''93959999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''98110000'', ''98199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''98210000'', ''98299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''98310000'', ''98399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''98410000'', ''98749999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''99010000'', ''99099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Volta Redonda''           ), ''24'', ''99110000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''20210000'', ''20219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''20270000'', ''20299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''21010000'', ''21049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''21210000'', ''21259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''21270000'', ''21279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''21330000'', ''21359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''21410000'', ''21449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''21510000'', ''21589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''22220000'', ''22229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''22330000'', ''22359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''22370000'', ''22379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''27270000'', ''27279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''30110000'', ''30119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''30130000'', ''30539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''30550000'', ''30589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''30600000'', ''30939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''31110000'', ''31249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''31320000'', ''31329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''31340000'', ''31399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''31450000'', ''31459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''31490000'', ''31549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''31610000'', ''31617999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''31710000'', ''31714999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''31770000'', ''31777999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''31800000'', ''31839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''31850000'', ''31869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''31940000'', ''31949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32000000'', ''32099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32110000'', ''32139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32150000'', ''32169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32180000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32210000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32320000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32410000'', ''32469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32480000'', ''32709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32720000'', ''32783999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32810000'', ''32829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32840000'', ''32849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32860000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32910000'', ''32923999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32950000'', ''32969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''32980000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33010000'', ''33059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33100000'', ''33419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33430000'', ''33519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33530000'', ''33579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33590000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33610000'', ''33645999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33660000'', ''33679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33690000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33710000'', ''33779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33790000'', ''33837999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33850000'', ''33869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33880000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33910000'', ''33919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''33950000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''34010000'', ''34079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''34110000'', ''34119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''34170000'', ''34179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''34210000'', ''34229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''34240000'', ''34259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''34340000'', ''34349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''34410000'', ''34419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''35110000'', ''35129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''35330000'', ''35359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''36360000'', ''36369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''37000000'', ''37009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''37110000'', ''37119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''37170000'', ''37173999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''37200000'', ''37334999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''37350000'', ''37366999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''37400000'', ''37409999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''37420000'', ''37464999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''37500000'', ''37739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''37760000'', ''37765999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''40070000'', ''40073999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''41010000'', ''41079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''44000000'', ''44007601'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''78110000'', ''78139999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''78780000'', ''78789999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''81000000'', ''81099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''81110000'', ''81299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''81310000'', ''81399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''81410000'', ''81499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''81510000'', ''81599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''81610000'', ''81949999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''88000000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''88610000'', ''88699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''88710000'', ''88799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''88810000'', ''88899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''88910000'', ''88999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''92010000'', ''92059999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''92220000'', ''92299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''92310000'', ''92399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''92410000'', ''92499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''92510000'', ''92599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''92610000'', ''92799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''92810000'', ''92899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''92910000'', ''92949999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''92960000'', ''92999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''93090000'', ''93099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''93110000'', ''93129999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''93160000'', ''93169999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''95000000'', ''95699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Vitória''                 ), ''27'', ''96000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''21220000'', ''21239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''21410000'', ''21419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''21430000'', ''21439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''22360000'', ''22369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''30150000'', ''30151999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''30360000'', ''30389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''31550000'', ''31555999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''32000000'', ''32005999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''32210000'', ''32219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''33010000'', ''33039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''33100000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''33210000'', ''33229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''33600000'', ''33619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''33830000'', ''33835999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''33850000'', ''33855999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''35110000'', ''35119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''35150000'', ''35153999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''35170000'', ''35269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''35280000'', ''35409999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''35420000'', ''35483999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''35500000'', ''35605999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''35620000'', ''35651999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''35690000'', ''35694999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''36360000'', ''36369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''37340000'', ''37345999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''81000000'', ''81039999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''81110000'', ''81229999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''88110000'', ''88119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''88140000'', ''88169999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''92100000'', ''92109999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''92220000'', ''92229999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''92510000'', ''92589999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''92710000'', ''92799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''92910000'', ''92919999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''92980000'', ''92989999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''98810000'', ''98869999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''99000000'', ''99269999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''99310000'', ''99329999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''99350000'', ''99359999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''99380000'', ''99399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''99410000'', ''99499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''99510000'', ''99599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''99610000'', ''99699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''99710000'', ''99799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''99810000'', ''99899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Cachoeiro de Itapemirim'' ), ''28'', ''99910000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''20140000'', ''20149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''20210000'', ''20229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''20250000'', ''20269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''21010000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''21110000'', ''21129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''21210000'', ''21239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''21250000'', ''21299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''21360000'', ''21369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''21380000'', ''21389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''21410000'', ''21469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''21910000'', ''21919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''22000000'', ''22009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''23230000'', ''23239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''23910000'', ''23919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''25100000'', ''25179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''25190000'', ''25289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''25310000'', ''25389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''25510000'', ''25529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''25550000'', ''25559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''25570000'', ''25579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''25590000'', ''25599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''25640000'', ''25699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''25710000'', ''25769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''25810000'', ''25819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''25850000'', ''25869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''25910000'', ''25929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''26260000'', ''26269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''27700000'', ''27709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''30110000'', ''30199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''30210000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''30410000'', ''30499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''30510000'', ''30599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''30610000'', ''30649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''30660000'', ''30699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''30710000'', ''30799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''30810000'', ''30891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''30910000'', ''30999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''31080000'', ''31096999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''31120000'', ''31199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''31220000'', ''31299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''31310000'', ''31325999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''31450000'', ''31459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''31630000'', ''31639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''31810000'', ''31829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''31940000'', ''31969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''32000000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''32410000'', ''32509999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''32520000'', ''32579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''32590000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''32610000'', ''32939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''32950000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''33110000'', ''33199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''33210000'', ''33399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''33410000'', ''33499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''33510000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''33610000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''33710000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''33810000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''34010000'', ''34041999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''34080000'', ''34099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''34110000'', ''34139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''34150000'', ''34199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''34210000'', ''34299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''34310000'', ''34399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''34410000'', ''34599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''34610000'', ''34699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''34710000'', ''34799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''34810000'', ''34999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''35010000'', ''35099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''35110000'', ''35199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''35210000'', ''35399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''35410000'', ''35478999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''35510000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''35610000'', ''35691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''35710000'', ''35869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''35880000'', ''35899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''35910000'', ''35999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''36010000'', ''36099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''36110000'', ''36129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''36140000'', ''36299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''36310000'', ''36399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''36410000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''36510000'', ''36659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''36670000'', ''36794999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''36810000'', ''36819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''36830000'', ''36899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''36910000'', ''37019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37110000'', ''37188999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37210000'', ''37283999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37310000'', ''37381999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37410000'', ''37424999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37460000'', ''37464999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37490000'', ''37498999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37510000'', ''37551999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37570000'', ''37572999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37610000'', ''37649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37660000'', ''37769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37790000'', ''37799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37850000'', ''37899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''37990000'', ''38016999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''38080000'', ''38094999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''38110000'', ''38119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''38170000'', ''38399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''38410000'', ''38499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''38510000'', ''38599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''38610000'', ''38692999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''38710000'', ''38737999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''38750000'', ''38799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''38810000'', ''38835999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''38850000'', ''38899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''38910000'', ''38999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''39110000'', ''39189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''39360000'', ''39399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''39560000'', ''39589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''39910000'', ''39999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''40010000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''40070000'', ''40073999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''40490000'', ''40496999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''40520000'', ''40529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''40620000'', ''40639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''41010000'', ''41099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''41110000'', ''41179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''41190000'', ''41199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''41210000'', ''41299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''41310000'', ''41399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''41410000'', ''41449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''41460000'', ''41461999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''41480000'', ''41499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''45010000'', ''45029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''62010000'', ''62019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''71000000'', ''71879999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''75000000'', ''75479999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''75530000'', ''75759999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''75770000'', ''75839999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''77000000'', ''77009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''78110000'', ''78189999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''78780000'', ''78789999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''80100000'', ''80489999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''81000000'', ''81059999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''82000000'', ''89999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Viçosa''                  ), ''31'', ''91000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''20100000'', ''20109999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''20200000'', ''20219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''20300000'', ''20309999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''20400000'', ''20419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''21040000'', ''21049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''21510000'', ''21559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''30150000'', ''30154999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''30210000'', ''30219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''30250000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''30310000'', ''30329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''30420000'', ''30429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''30510000'', ''30529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''30610000'', ''30619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''30810000'', ''30879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''31230000'', ''31239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''31320000'', ''31329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''32010000'', ''32039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''32110000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''32210000'', ''32269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''32280000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''32310000'', ''32379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''32390000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''32410000'', ''32419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''32490000'', ''32581999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''32610000'', ''32679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''32710000'', ''32784999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''32810000'', ''32881999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''32910000'', ''32961999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''33010000'', ''33039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''33110000'', ''33149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''33210000'', ''33239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''33300000'', ''33399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''33410000'', ''33481999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''33510000'', ''33514999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''33530000'', ''33571999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''33590000'', ''33593999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''33610000'', ''33671999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''33710000'', ''33779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''33790000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''33930000'', ''33938999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''34010000'', ''34029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''34210000'', ''34268999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''34290000'', ''34299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''34410000'', ''34422999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''34440000'', ''34479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''34490000'', ''34499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''34510000'', ''34532999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''34610000'', ''34669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''35110000'', ''35129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''35310000'', ''35399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''35410000'', ''35419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''35510000'', ''35519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''35530000'', ''35563999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''35590000'', ''35592999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''35710000'', ''35781999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''36900000'', ''36949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''36960000'', ''36965999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''37000000'', ''37005999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''37110000'', ''37115999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''37210000'', ''37299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''37410000'', ''37492999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''37510000'', ''37514999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''37530000'', ''37559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''37990000'', ''37998999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''39390000'', ''39399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''40010000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''41010000'', ''41049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''41060000'', ''41081999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''84000000'', ''85229999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''87010000'', ''87159999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''88000000'', ''88799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''88810000'', ''88999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''91000000'', ''91519999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''91530000'', ''91569999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''91590000'', ''91689999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''91720000'', ''91769999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''91930000'', ''91959999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''91970000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''98000000'', ''98199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Ubá''                     ), ''32'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''20520000'', ''20529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''30150000'', ''30151999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''30210000'', ''30259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''30380000'', ''30389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''30620000'', ''30629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''30810000'', ''30879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''30890000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''31020000'', ''31029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''31230000'', ''31239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''31330000'', ''31339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''31810000'', ''31819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32010000'', ''32059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32120000'', ''32139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32150000'', ''32155999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32210000'', ''32219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32250000'', ''32259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32310000'', ''32383999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32410000'', ''32474999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32510000'', ''32542999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32610000'', ''32639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32650000'', ''32685999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32710000'', ''32739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32750000'', ''32799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32840000'', ''32848999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''32910000'', ''32993999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''33110000'', ''33189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''33210000'', ''33299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''33310000'', ''33364999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''33390000'', ''33453999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''33510000'', ''33572999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''33730000'', ''33732999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''33770000'', ''33788999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''34010000'', ''34019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''34110000'', ''34164999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''34210000'', ''34281999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''34310000'', ''34362999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''35080000'', ''35089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''35110000'', ''35174999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''35210000'', ''35296999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''35310000'', ''35369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''35800000'', ''35831999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''36110000'', ''36118999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''36210000'', ''36282999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''37170000'', ''37171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''37210000'', ''37291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''37310000'', ''37395999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''37410000'', ''37416999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''37430000'', ''37472999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''37510000'', ''37518999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''37530000'', ''37558999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''37640000'', ''37652999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''37980000'', ''37999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''38250000'', ''38253999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''38450000'', ''38459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''41030000'', ''41039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''44000000'', ''44007605'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''84000000'', ''84659999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''87000000'', ''87169999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''87270000'', ''87289999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''87390000'', ''87409999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''87490000'', ''87519999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''88000000'', ''88999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''91000000'', ''91589999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''91610000'', ''91619999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''91630000'', ''91689999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''91910000'', ''91919999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''91930000'', ''91939999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''91970000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Governador Valadares''    ), ''33'', ''99010000'', ''99909999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''20610000'', ''20629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''21010000'', ''21049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''21060000'', ''21069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''21080000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''21510000'', ''21569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''30140000'', ''30169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''30210000'', ''30229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''30610000'', ''30639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''30710000'', ''30779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''30810000'', ''30889999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''31220000'', ''31259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''31310000'', ''31359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''31760000'', ''31764999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''32010000'', ''32029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''32100000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''32210000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''32410000'', ''32469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''32480000'', ''32499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''32510000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''32610000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''32710000'', ''32719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''32810000'', ''32819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''32830000'', ''32849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''32910000'', ''32939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''32990000'', ''32998999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''33010000'', ''33069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''33110000'', ''33199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''33210000'', ''33299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''33310000'', ''33349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''33360000'', ''33369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''33380000'', ''33389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''33420000'', ''33439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''33510000'', ''33569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''33590000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''34110000'', ''34159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''34210000'', ''34219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''34230000'', ''34299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''34310000'', ''34319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''34530000'', ''34571999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''34590000'', ''34599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''35010000'', ''35029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''35110000'', ''35159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''35170000'', ''35179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''35210000'', ''35229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''36110000'', ''36161999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''36310000'', ''36317999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''36330000'', ''36331999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''36370000'', ''36371999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''36540000'', ''36542999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''36610000'', ''36659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''36690000'', ''36699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''36710000'', ''36719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''36740000'', ''36742999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''36900000'', ''36917999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''37000000'', ''37009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''37170000'', ''37171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''37990000'', ''37996999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''38100000'', ''38269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''38310000'', ''38366999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''38390000'', ''38399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''38410000'', ''38495999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''38510000'', ''38532999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''38550000'', ''38561999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''38590000'', ''38599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''40010000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''41010000'', ''41099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''41110000'', ''41113999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''41140000'', ''41141999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''78110000'', ''78129999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''84000000'', ''84409999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''87000000'', ''87019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''87190000'', ''87199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''87210000'', ''87219999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''88000000'', ''88699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''88710000'', ''88799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''88810000'', ''88899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''88910000'', ''88999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''91000000'', ''92919999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''92930000'', ''92999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''96400000'', ''96449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''96500000'', ''96999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''97800000'', ''97829999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''97900000'', ''98299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''99010000'', ''99799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Uberlândia''              ), ''34'', ''99810000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''20640000'', ''20689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''21010000'', ''21039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''21050000'', ''21079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''21410000'', ''21439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''23000000'', ''23009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''30110000'', ''30139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''30150000'', ''30159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''30210000'', ''30239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''30640000'', ''30649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''30660000'', ''30689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''30850000'', ''30859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''31000000'', ''31009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''31230000'', ''31239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32110000'', ''32149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32190000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32210000'', ''32239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32250000'', ''32261999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32290000'', ''32295999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32310000'', ''32373999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32390000'', ''32396999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32410000'', ''32441999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32510000'', ''32514999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32610000'', ''32615999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32630000'', ''32679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32710000'', ''32719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32730000'', ''32742999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32810000'', ''32842999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32860000'', ''32862999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''32910000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33010000'', ''33059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33110000'', ''33129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33220000'', ''33271999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33290000'', ''33299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33310000'', ''33353999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33390000'', ''33399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33410000'', ''33465999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33490000'', ''33498999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33610000'', ''33619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33630000'', ''33661999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33710000'', ''33719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33730000'', ''33732999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''33750000'', ''33751999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''34110000'', ''34129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''34210000'', ''34279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''34290000'', ''34299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''34310000'', ''34382999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''34410000'', ''34465999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''34490000'', ''34499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''34510000'', ''34571999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''34610000'', ''34661999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''34710000'', ''34739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35210000'', ''35274999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35290000'', ''35299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35310000'', ''35379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35390000'', ''35399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35410000'', ''35415999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35430000'', ''35459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35490000'', ''35499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35510000'', ''35563999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35580000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35610000'', ''35642999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35710000'', ''35718999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35730000'', ''35736999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35910000'', ''35919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''35930000'', ''35932999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''36210000'', ''36261999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''36280000'', ''36299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''36410000'', ''36415999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''36430000'', ''36451999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''36510000'', ''36519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''36530000'', ''36561999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''36590000'', ''36591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''36620000'', ''36641999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''36900000'', ''36989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''37000000'', ''37019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''37120000'', ''37169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''37210000'', ''37239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''37290000'', ''37299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''37310000'', ''37393999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''37410000'', ''37434999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''37980000'', ''38009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''38210000'', ''38269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''38290000'', ''38299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''38310000'', ''38362999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''38410000'', ''38441999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''38510000'', ''38519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''38530000'', ''38582999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''38610000'', ''38619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''38630000'', ''38674999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''41010000'', ''41059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''84000000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''84310000'', ''84399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''84410000'', ''84499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''84510000'', ''84599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''84610000'', ''84699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''84710000'', ''84799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''87010000'', ''87099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''87110000'', ''87239999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''88000000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''88610000'', ''88699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''88710000'', ''88799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''88810000'', ''88879999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''88890000'', ''88899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''88910000'', ''88999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''91000000'', ''92399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''92410000'', ''92459999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''96700000'', ''96739999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''97000000'', ''97349999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Varginha''                ), ''35'', ''98000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''20710000'', ''20719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''21320000'', ''21339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''30150000'', ''30151999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''30710000'', ''30749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''30760000'', ''30779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''30850000'', ''30859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32010000'', ''32041999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32110000'', ''32169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32210000'', ''32229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32250000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32310000'', ''32381999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32410000'', ''32445999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32460000'', ''32471999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32490000'', ''32505999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32580000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32610000'', ''32626999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32710000'', ''32781999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32810000'', ''32818999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''32860000'', ''32889999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33010000'', ''33039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33110000'', ''33129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33210000'', ''33265999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33290000'', ''33296999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33310000'', ''33352999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33410000'', ''33418999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33430000'', ''33449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33510000'', ''33551999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33590000'', ''33597999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33610000'', ''33639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33660000'', ''33661999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33710000'', ''33719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33730000'', ''33732999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33810000'', ''33819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''33830000'', ''33842999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''34210000'', ''34219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''34230000'', ''34269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''34310000'', ''34316999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''34330000'', ''34352999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''34590000'', ''34599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''35110000'', ''35161999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''35200000'', ''35259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''35390000'', ''35398999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''35410000'', ''35416999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''35430000'', ''35461999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''35510000'', ''35516999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''35530000'', ''35531999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''35550000'', ''35551999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''35590000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''36900000'', ''36919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''37000000'', ''37001999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''37990000'', ''37996999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''39390000'', ''39399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''40010000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''41010000'', ''41019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''78110000'', ''78119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''84000000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''84210000'', ''84269999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''88510000'', ''88559999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''91000000'', ''91629999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''91640000'', ''91659999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''91680000'', ''91699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''91710000'', ''91719999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''91860000'', ''91869999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''91910000'', ''91949999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''91970000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''96600000'', ''96639999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''96710000'', ''96719999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''98010000'', ''98099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''98110000'', ''98469999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''98550000'', ''98639999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''99010000'', ''99099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''99110000'', ''99199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''99210000'', ''99299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''99310000'', ''99399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''99410000'', ''99499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''99510000'', ''99599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''99610000'', ''99899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Piumhi''                  ), ''37'', ''99910000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''21010000'', ''21049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''30150000'', ''30152999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''30810000'', ''30859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''31000000'', ''31029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''31230000'', ''31239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''32010000'', ''32029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''32120000'', ''32181999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''32210000'', ''32249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''32260000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''32310000'', ''32398999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''32510000'', ''32553999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''33010000'', ''33019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''33110000'', ''33129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''33210000'', ''33219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''33650000'', ''33651999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''34410000'', ''34419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''35040000'', ''35067999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''35150000'', ''35159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''35210000'', ''35219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''35230000'', ''35231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''35250000'', ''35279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''35310000'', ''35352999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''35410000'', ''35416999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''35430000'', ''35439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''35450000'', ''35471999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''35610000'', ''35646999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''35670000'', ''35675999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''36120000'', ''36172999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''36210000'', ''36294999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''36310000'', ''36365999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''36470000'', ''36472999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''36620000'', ''36633999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''36710000'', ''36798999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''36810000'', ''36811999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''36900000'', ''36909999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''37000000'', ''37003999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''37210000'', ''37299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''37310000'', ''37319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''37330000'', ''37331999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''37360000'', ''37369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''37410000'', ''37472999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''37490000'', ''37496999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''37510000'', ''37516999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''37530000'', ''37593999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''37980000'', ''37999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''38110000'', ''38141999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''38210000'', ''38272999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''38290000'', ''38294999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''38310000'', ''38346999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''38410000'', ''38461999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''41000000'', ''41019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''41030000'', ''41031999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''44000000'', ''44007614'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''84310000'', ''84379999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''88510000'', ''88569999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''88580000'', ''88589999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''91000000'', ''92329999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''92340000'', ''92429999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''97220000'', ''97499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''98000000'', ''98869999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''SE - Montes Claros''           ), ''38'', ''98890000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''20140000'', ''20149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''20270000'', ''20299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''20940000'', ''20949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''21010000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''21110000'', ''21129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''21170000'', ''21189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''21330000'', ''21339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''21410000'', ''21419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''21520000'', ''21529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''21690000'', ''21699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''22410000'', ''22419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''23910000'', ''23919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''26260000'', ''26269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''27700000'', ''27709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''30010000'', ''30011999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''30100000'', ''30799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''30810000'', ''30999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''31040000'', ''31099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''31110000'', ''31129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''31140000'', ''31349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''31360000'', ''31589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''31610000'', ''31789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''31800000'', ''31881999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''31950000'', ''31953999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''32000000'', ''32149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''32170000'', ''32369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''32380000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''32610000'', ''32799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''32810000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''32910000'', ''32929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''32940000'', ''32944999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''32960000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''33010000'', ''33679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''33690000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''33910000'', ''33939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''33950000'', ''33969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''33980000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34010000'', ''34099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34120000'', ''34121999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34140000'', ''34165999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34200000'', ''34279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34310000'', ''34349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34420000'', ''34439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34510000'', ''34539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34550000'', ''34589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34620000'', ''34629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34650000'', ''34659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34680000'', ''34689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34720000'', ''34739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34820000'', ''34829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''34910000'', ''34911999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35010000'', ''35069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35110000'', ''35139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35170000'', ''35179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35210000'', ''35289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35320000'', ''35399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35430000'', ''35449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35470000'', ''35479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35510000'', ''35579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35590000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35610000'', ''35699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35720000'', ''35739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35750000'', ''35799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35810000'', ''35969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''35980000'', ''35999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36010000'', ''36019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36030000'', ''36089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36110000'', ''36121999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36140000'', ''36149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36160000'', ''36199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36210000'', ''36299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36310000'', ''36399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36410000'', ''36439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36450000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36510000'', ''36599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36610000'', ''36699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36710000'', ''36799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36810000'', ''36881999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''36920000'', ''37007999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''37170000'', ''37171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''37210000'', ''37229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''37320000'', ''37379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''37510000'', ''37581999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''37770000'', ''37799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''38150000'', ''38156999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''38710000'', ''38791999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''38810000'', ''38819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''38830000'', ''38839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''38880000'', ''38889999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''39010000'', ''39095999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''39110000'', ''39125999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''39380000'', ''39399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''39410000'', ''39419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''39450000'', ''39459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''39710000'', ''39738999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''39750000'', ''39753999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''39780000'', ''39781999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''39950000'', ''39953999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''40010000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''40520000'', ''40529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''40620000'', ''40649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''41010000'', ''41099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''41110000'', ''41276999'',''Fijo'', ''Fijo'')

insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''45010000'', ''45014999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''47000000'', ''47009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''49110000'', ''49119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''62010000'', ''62019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''78110000'', ''78229999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''84000000'', ''85199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''85210000'', ''85279999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''85290000'', ''85389999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''87000000'', ''87799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''88000000'', ''88999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''91000000'', ''91099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''91110000'', ''91199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''91210000'', ''91299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''91310000'', ''91399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''91410000'', ''91499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''91510000'', ''91599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''91610000'', ''91699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''91710000'', ''91799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''91810000'', ''91899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''91910000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''92010000'', ''92099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''92110000'', ''92199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''92210000'', ''92299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''92310000'', ''92399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''92410000'', ''92499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''92510000'', ''92599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''92610000'', ''92909999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''96000000'', ''97869999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Curitiba''                 ), ''41'', ''98000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''21010000'', ''21049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''30010000'', ''30011999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''30250000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''30350000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''30410000'', ''30429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''30860000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''31020000'', ''31029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''31220000'', ''31229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''32010000'', ''32029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''32120000'', ''32121999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''32180000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''32310000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''32410000'', ''32591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''32610000'', ''32619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''32630000'', ''32642999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''32660000'', ''32799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''32910000'', ''32919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''33210000'', ''33279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''34120000'', ''34141999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''34160000'', ''34161999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''34210000'', ''34241999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''34340000'', ''34389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''34440000'', ''34479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''34570000'', ''34611999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''34630000'', ''34639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''34720000'', ''34729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''34740000'', ''34759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''34770000'', ''34779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''35110000'', ''35111999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''35160000'', ''35161999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''35190000'', ''35249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''35260000'', ''35262999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''35320000'', ''35339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''35420000'', ''35439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''35510000'', ''35549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''35600000'', ''35609999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''35620000'', ''35629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''35730000'', ''35739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''35810000'', ''35811999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''36130000'', ''36151999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''36170000'', ''36189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''36210000'', ''36399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''36410000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''36510000'', ''36599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''36610000'', ''36681999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''36750000'', ''36779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''36810000'', ''36831999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''36860000'', ''36861999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''36910000'', ''36911999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''37000000'', ''37003999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''39010000'', ''39127999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''39150000'', ''39162999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''40520000'', ''40529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''40620000'', ''40639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''41010000'', ''41066999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''78110000'', ''78119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''84310000'', ''84359999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''84390000'', ''84399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''88000000'', ''88909999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''91000000'', ''91099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''91110000'', ''91199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''91210000'', ''91299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''91310000'', ''91399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''91410000'', ''91499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''91510000'', ''91599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''91610000'', ''91669999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''98000000'', ''98309999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ponta Grossa''             ), ''42'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''21010000'', ''21059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''30010000'', ''30011999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''30110000'', ''30119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''30150000'', ''30182999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''30200000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''30310000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''30410000'', ''30489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''30510000'', ''30519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''30550000'', ''30569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''30610000'', ''30699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''31220000'', ''31224999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''31320000'', ''31339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''31450000'', ''31459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''31520000'', ''31529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''31540000'', ''31549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''31560000'', ''31564999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''31580000'', ''31594999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''31620000'', ''31624999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''31720000'', ''31729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''31740000'', ''31749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''31760000'', ''31769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''31780000'', ''31789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32010000'', ''32039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32110000'', ''32121999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32140000'', ''32141999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32180000'', ''32191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32210000'', ''32249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32280000'', ''32339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32350000'', ''32359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32380000'', ''32389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32400000'', ''32409999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32420000'', ''32429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32440000'', ''32449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32490000'', ''32629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32650000'', ''32689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32700000'', ''32782999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32910000'', ''32919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''32930000'', ''32949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33150000'', ''33199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33210000'', ''33299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33340000'', ''33344999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33360000'', ''33399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33410000'', ''33454999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33470000'', ''33489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33510000'', ''33589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33610000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33710000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33910000'', ''33915999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''33980000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34010000'', ''34049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34110000'', ''34131999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34150000'', ''34171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34200000'', ''34299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34310000'', ''34379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34390000'', ''34429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34440000'', ''34449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34460000'', ''34471999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34490000'', ''34491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34510000'', ''34563999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34580000'', ''34592999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34610000'', ''34691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34710000'', ''34793999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34810000'', ''34832999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''34850000'', ''34851999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''35110000'', ''35161999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''35180000'', ''35219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''35230000'', ''35299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''35310000'', ''35499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''35510000'', ''35699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''35710000'', ''35769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''35790000'', ''35799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''35810000'', ''35891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''35910000'', ''35991999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''36110000'', ''36191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''36210000'', ''36279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''36600000'', ''36629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''36750000'', ''36759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''36910000'', ''36911999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''36930000'', ''36931999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''37110000'', ''37139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''37170000'', ''37171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''38770000'', ''38789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''39010000'', ''39141999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''39460000'', ''39462999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''40330000'', ''40339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''40430000'', ''40431999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''40520000'', ''40539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''40620000'', ''40639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''40730000'', ''40739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''41010000'', ''41051999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''78110000'', ''78119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''81110000'', ''81119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''84310000'', ''84399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''84410000'', ''84499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''84510000'', ''84599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''84610000'', ''84639999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''84730000'', ''84799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''84810000'', ''84849999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''84920000'', ''84939999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''84980000'', ''84999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''88000000'', ''88609999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''91000000'', ''91699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''91710000'', ''91799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''91810000'', ''91899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''91910000'', ''91959999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''96000000'', ''96999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''98000000'', ''98179999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''99000000'', ''99399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Ventania''                 ), ''43'', ''99410000'', ''99989999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''21010000'', ''21039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''30010000'', ''30011999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''30100000'', ''30119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''30130000'', ''30519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''30530000'', ''30592999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''30610000'', ''30629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''30650000'', ''30659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''30670000'', ''30689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''31020000'', ''31029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''31120000'', ''31129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''31220000'', ''31239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''31250000'', ''31289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''31330000'', ''31349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''32010000'', ''32031999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''32090000'', ''32099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''32110000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''32310000'', ''32791999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''32810000'', ''32891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''32910000'', ''32919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''32930000'', ''32939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''32970000'', ''32993999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''33010000'', ''33069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''33090000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''33210000'', ''33251999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''33280000'', ''33289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''33300000'', ''33309999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''33320000'', ''33329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''33400000'', ''33409999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''33420000'', ''33489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''33510000'', ''33569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''33610000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''34010000'', ''34069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''34100000'', ''34192999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''34210000'', ''34299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''34310000'', ''34499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''34510000'', ''34681999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''34720000'', ''34729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''34740000'', ''34799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''34820000'', ''34829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''35090000'', ''35091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''35110000'', ''35191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''35210000'', ''35299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''35310000'', ''35592999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''35610000'', ''35699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''35710000'', ''35791999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''35810000'', ''35891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''35910000'', ''35999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''36010000'', ''36099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''36110000'', ''36199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''36210000'', ''36299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''36310000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''36510000'', ''36599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''36610000'', ''36699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''36710000'', ''36799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''36810000'', ''36899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''36910000'', ''37001999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''37170000'', ''37179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''39010000'', ''39093999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''39110000'', ''39131999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''40430000'', ''40431999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''40520000'', ''40529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''40620000'', ''40639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''41010000'', ''41023999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''78110000'', ''78119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''84310000'', ''84399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''84410000'', ''84499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''84510000'', ''84599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''84610000'', ''84629999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''84640000'', ''84649999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''88000000'', ''88689999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''91000000'', ''91099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''91110000'', ''91199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''91210000'', ''91299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''91310000'', ''91399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''91410000'', ''91499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''91510000'', ''91599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''91610000'', ''91699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''91710000'', ''91809999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''97000000'', ''97129999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Umuarama''                 ), ''44'', ''98000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''20310000'', ''20319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''21010000'', ''21059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''21410000'', ''21429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''30010000'', ''30011999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''30150000'', ''30151999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''30170000'', ''30172999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''30210000'', ''30229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''30250000'', ''30419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''30450000'', ''30459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''30530000'', ''30579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''30610000'', ''30619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''30900000'', ''30919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''30960000'', ''31019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''31120000'', ''31129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''32020000'', ''32092999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''32110000'', ''32209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''32220000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''32910000'', ''32919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33010000'', ''33069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33080000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33110000'', ''33135999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33210000'', ''33289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33320000'', ''33339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33360000'', ''33361999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33430000'', ''33471999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33520000'', ''33562999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33610000'', ''33679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33730000'', ''33739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33750000'', ''33806999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33850000'', ''33859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33920000'', ''33929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''33950000'', ''33959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''34110000'', ''34119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''34210000'', ''34229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''35200000'', ''35299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''35400000'', ''35439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''35450000'', ''35459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''35500000'', ''35509999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''35570000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''35610000'', ''35619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''35630000'', ''35661999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''35720000'', ''35789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''37000000'', ''37005999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''37230000'', ''37239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''39010000'', ''39051999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''39090000'', ''39091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''40520000'', ''40549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''40620000'', ''40639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''41000000'', ''41081999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''84310000'', ''84369999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''88000000'', ''88449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''91000000'', ''91099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''91110000'', ''91199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''91210000'', ''91299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''91310000'', ''91399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''91410000'', ''91499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''91510000'', ''91589999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''98000000'', ''98319999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Toledo''                   ), ''45'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''30210000'', ''30229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''30250000'', ''30279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''30550000'', ''30579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''31000000'', ''31004999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''32110000'', ''32131999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''32200000'', ''32209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''32230000'', ''32281999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''32320000'', ''32349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''32420000'', ''32469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''32520000'', ''32551999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''32570000'', ''32571999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''32620000'', ''32651999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''32670000'', ''32671999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''32720000'', ''32729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''32750000'', ''32759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''32910000'', ''32919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''33090000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''33160000'', ''33169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''33210000'', ''33219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''33230000'', ''33239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''33410000'', ''33419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''35150000'', ''35171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''35200000'', ''35292999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''35310000'', ''35509999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''35520000'', ''35679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''35710000'', ''35741999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''35780000'', ''35793999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''35810000'', ''35821999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''39010000'', ''39071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''40020000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''40540000'', ''40559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''41010000'', ''41027999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''44000000'', ''44007202'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''84110000'', ''84159999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''84190000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''84210000'', ''84229999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''88000000'', ''88369999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''91000000'', ''91419999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''99000000'', ''99419999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''99710000'', ''99769999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Pato Branco''              ), ''46'', ''99780000'', ''99789999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''20330000'', ''20339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''21010000'', ''21089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''21110000'', ''21119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''21220000'', ''21259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''21410000'', ''21419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''30010000'', ''30019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''30110000'', ''30199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''30210000'', ''30239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''30250000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''30310000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''30410000'', ''30509999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''30520000'', ''30596999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''30610000'', ''30649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''30800000'', ''30879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''30980000'', ''30989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''31000000'', ''31199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''31210000'', ''31399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''31410000'', ''31491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''31510000'', ''31699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''31710000'', ''31793999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''31810000'', ''31893999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''31910000'', ''31991999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32010000'', ''32129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32170000'', ''32178999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32210000'', ''32229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32250000'', ''32279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32310000'', ''32349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32360000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32410000'', ''32449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32460000'', ''32499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32510000'', ''32526999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32550000'', ''32559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32580000'', ''32583999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32610000'', ''32619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32630000'', ''32689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32700000'', ''32799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32810000'', ''32821999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''32850000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''33000000'', ''33019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''33030000'', ''33039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''33060000'', ''33109999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''33120000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''33150000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34010000'', ''34069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34080000'', ''34099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34110000'', ''34129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34160000'', ''34199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34210000'', ''34299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34310000'', ''34399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34410000'', ''34499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34510000'', ''34599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34610000'', ''34619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34630000'', ''34679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34710000'', ''34739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34810000'', ''34819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34880000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''34920000'', ''34922999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''35010000'', ''35029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''35170000'', ''35179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''35190000'', ''35269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''35310000'', ''35379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''35420000'', ''35479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''35560000'', ''35579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''35620000'', ''35659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''35910000'', ''35919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''36190000'', ''36199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''36210000'', ''36279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''36290000'', ''36293999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''36310000'', ''36359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''36410000'', ''36471999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''36520000'', ''36553999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''36740000'', ''36749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''36920000'', ''37089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''37170000'', ''37171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''38010000'', ''38049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''38090000'', ''38099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''39010000'', ''39096999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''40520000'', ''40559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''40620000'', ''40639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''41010000'', ''41091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''41110000'', ''41199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''41210000'', ''41254999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''78110000'', ''78139999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''84000000'', ''84599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''84610000'', ''84699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''84710000'', ''84899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''84910000'', ''84999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''88000000'', ''89229999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''91000000'', ''92979999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''96000000'', ''97249999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Navegantes''               ), ''47'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''20100000'', ''20109999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''20410000'', ''20419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''20900000'', ''20909999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''21060000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''21320000'', ''21359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''21510000'', ''21529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''23910000'', ''23919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''30010000'', ''30011999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''30110000'', ''30169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''30210000'', ''30259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''30270000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''30410000'', ''30599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''30610000'', ''30689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''30710000'', ''30729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''30800000'', ''30879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''30890000'', ''30969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''31810000'', ''31819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''31860000'', ''31869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''32010000'', ''32179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''32210000'', ''32269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''32280000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''32310000'', ''32499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''32510000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''32610000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''32710000'', ''32799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''32810000'', ''32889999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''32920000'', ''32929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''32940000'', ''32949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''32960000'', ''32969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''32980000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33210000'', ''33229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33240000'', ''33249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33300000'', ''33359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33370000'', ''33389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33410000'', ''33489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33530000'', ''33579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33630000'', ''33679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33690000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33710000'', ''33783999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33810000'', ''33829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''33890000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''34010000'', ''34039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''34110000'', ''34139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''34210000'', ''34229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''34300000'', ''34459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''34470000'', ''34479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''34610000'', ''34699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''34710000'', ''34719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''34760000'', ''34763999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''34780000'', ''34789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''34910000'', ''34913999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''35210000'', ''35291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''35310000'', ''35399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''35440000'', ''35469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''35480000'', ''35483999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''35830000'', ''35839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''35910000'', ''35915999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''36110000'', ''36119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''36210000'', ''36269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''36280000'', ''36299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''36310000'', ''36329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''36410000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''36510000'', ''36593999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''36640000'', ''36669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''36680000'', ''36689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''36910000'', ''36919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''37000000'', ''37009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''37170000'', ''37179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''37210000'', ''37229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''37330000'', ''37339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''38210000'', ''38219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''38670000'', ''38691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''38710000'', ''38799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''38810000'', ''38892999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''38910000'', ''38999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''39010000'', ''39031999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''39050000'', ''39101999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''39120000'', ''39179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''39190000'', ''39199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''39210000'', ''39291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''39310000'', ''39344999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''39360000'', ''39393999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''39410000'', ''39491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''39510000'', ''39589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''40520000'', ''40549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''41010000'', ''41099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''41110000'', ''41199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''41210000'', ''41281999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''78110000'', ''78139999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''84000000'', ''84909999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''84920000'', ''85069999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''88000000'', ''88719999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''91000000'', ''91099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''91110000'', ''91199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''91210000'', ''91299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''91310000'', ''91399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''91410000'', ''91499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''91510000'', ''91599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''91610000'', ''91699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''91710000'', ''91799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''91810000'', ''91949999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''96000000'', ''96999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''98000000'', ''98159999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Florianópolis''            ), ''48'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''20490000'', ''20499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''21010000'', ''21049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''21250000'', ''21259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''30150000'', ''30172999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''30210000'', ''30219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32010000'', ''32039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32110000'', ''32129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32170000'', ''32179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32210000'', ''32293999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32320000'', ''32339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32350000'', ''32389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32410000'', ''32493999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32510000'', ''32543999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32560000'', ''32583999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32750000'', ''32759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32770000'', ''32793999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32880000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''32920000'', ''32939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''33010000'', ''33079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''33160000'', ''33199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''33210000'', ''33399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''33410000'', ''33493999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''33510000'', ''33563999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''33580000'', ''33589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''33610000'', ''33673999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''33720000'', ''33722999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''33820000'', ''33823999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''33910000'', ''33912999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''34010000'', ''34039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''34120000'', ''34124999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''34210000'', ''34229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''34240000'', ''34259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''34310000'', ''34393999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''34410000'', ''34493999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''34510000'', ''34593999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''34620000'', ''34625999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''34720000'', ''34726999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''34820000'', ''34827999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''34910000'', ''34915999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''35210000'', ''35279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''35310000'', ''35396999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''35410000'', ''35493999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''35510000'', ''35589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''35610000'', ''35649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''35660000'', ''35679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''35720000'', ''35749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''35920000'', ''35929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''36210000'', ''36289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''36310000'', ''36343999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''36360000'', ''36373999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''36410000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''36520000'', ''36589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''36640000'', ''36689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''36740000'', ''36753999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''36770000'', ''36789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''36910000'', ''36919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37000000'', ''37009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37060000'', ''37071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37090000'', ''37092999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37110000'', ''37119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37130000'', ''37169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37180000'', ''37191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37210000'', ''37249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37260000'', ''37299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37310000'', ''37399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37410000'', ''37493999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37510000'', ''37599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37610000'', ''37699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37710000'', ''37794999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37810000'', ''37899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''37910000'', ''37991999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''38010000'', ''38099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''38110000'', ''38199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''38210000'', ''38299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''38310000'', ''38395999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''38410000'', ''38493999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''38510000'', ''38599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''38610000'', ''38619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''39010000'', ''39082999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''40020000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''41000000'', ''41019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''84310000'', ''84389999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''85010000'', ''85059999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''88000000'', ''89029999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''91000000'', ''91099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''91110000'', ''91199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''91210000'', ''91299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''91310000'', ''91399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''91410000'', ''91499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''91510000'', ''91599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''91610000'', ''91699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''91710000'', ''91799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''91810000'', ''91899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''91910000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''98000000'', ''98039999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''99000000'', ''99899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Lages''                    ), ''49'', ''99910000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''20140000'', ''20149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''20200000'', ''20229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''20900000'', ''20909999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''21010000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''21110000'', ''21129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''21170000'', ''21189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''21210000'', ''21219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''21230000'', ''21239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''21250000'', ''21299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''21310000'', ''21319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''21360000'', ''21369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''21390000'', ''21399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''21410000'', ''21419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''21610000'', ''21619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''23000000'', ''23009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''23910000'', ''23919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''26260000'', ''26269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''27270000'', ''27289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''27700000'', ''27709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''30110000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''30410000'', ''30499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''30510000'', ''30699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''30710000'', ''30799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''30810000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''30910000'', ''31199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''31210000'', ''31234999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''31250000'', ''31289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''31310000'', ''31379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''31410000'', ''31499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''31510000'', ''31599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''31610000'', ''31798999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''31810000'', ''31811999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''31870000'', ''31899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''31950000'', ''31955999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''31990000'', ''31999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''32010000'', ''32559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''32570000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''32610000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''32710000'', ''32829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''32840000'', ''32849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''32860000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''33110000'', ''33239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''33250000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''33710000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''33810000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''34010000'', ''34093999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''34110000'', ''34191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''34210000'', ''34239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''34250000'', ''34399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''34410000'', ''35099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''35110000'', ''35299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''35310000'', ''35399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''35410000'', ''35499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''35510000'', ''35697999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''35710000'', ''35999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''36010000'', ''36092999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''36110000'', ''36194999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''36210000'', ''36292999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''36310000'', ''36392999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''36410000'', ''36591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''36610000'', ''36899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''36920000'', ''37799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''37810000'', ''37895999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''37910000'', ''37999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''38010000'', ''38095999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''38110000'', ''38191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''38210000'', ''38291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''38310000'', ''38392999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''38410000'', ''38494999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''38510000'', ''38591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''38610000'', ''38691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''38710000'', ''38791999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''38810000'', ''38841999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''38870000'', ''38891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''38910000'', ''38931999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''38960000'', ''38999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''39010000'', ''39129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''39170000'', ''39269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''39300000'', ''39399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''39410000'', ''39491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''39510000'', ''39541999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''39560000'', ''39591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''39610000'', ''39689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''39710000'', ''39732999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''39810000'', ''39831999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''39910000'', ''39927999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''39940000'', ''39977999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''40610000'', ''40669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''40680000'', ''40689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''40760000'', ''40769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''41000000'', ''41099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''41110000'', ''41199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''41210000'', ''41294999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''41310000'', ''41332999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''41450000'', ''41459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''44000000'', ''44007605'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''62010000'', ''62019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''78110000'', ''78169999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''80100000'', ''80579999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''81000000'', ''83219999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''84000000'', ''86409999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''89000000'', ''89429999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Cruz do Sul''        ), ''51'', ''91000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''21230000'', ''21239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''21250000'', ''21269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''21280000'', ''21289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''30140000'', ''30199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''30250000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''30310000'', ''30329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''30350000'', ''30369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''30550000'', ''30559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''32010000'', ''32049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''32060000'', ''32069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''32080000'', ''32099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''32110000'', ''32119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''32210000'', ''32439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''32450000'', ''32495999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''32510000'', ''32529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''32540000'', ''32679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''32710000'', ''32799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''32810000'', ''32859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''32930000'', ''32939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''33010000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''33160000'', ''33189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''33210000'', ''33219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''33420000'', ''33459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''33530000'', ''33549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''34810000'', ''34859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''35030000'', ''35034999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''36110000'', ''36139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''36150000'', ''36151999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''37000000'', ''37009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''37170000'', ''37171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''38020000'', ''38091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''38110000'', ''38131999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''38740000'', ''38759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''38790000'', ''38799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''38810000'', ''38831999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''39050000'', ''39059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''39210000'', ''39216999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''39310000'', ''39321999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''39410000'', ''39411999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''39430000'', ''39437999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''40520000'', ''40529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''41010000'', ''41049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''44000000'', ''44007601'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''81000000'', ''81479999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''81490000'', ''81599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''84310000'', ''84399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''84410000'', ''84499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''84510000'', ''84599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''84610000'', ''84689999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''84730000'', ''84759999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''91000000'', ''91909999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''92410000'', ''92419999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''99010000'', ''99119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''99130000'', ''99139999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''99190000'', ''99399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''99410000'', ''99499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''99510000'', ''99599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''99610000'', ''99699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''99710000'', ''99839999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''99850000'', ''99899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Rio Grande''               ), ''53'', ''99910000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''21010000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''21410000'', ''21419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''21440000'', ''21449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''25210000'', ''25219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''26210000'', ''26219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''26280000'', ''26289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''29910000'', ''29929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''30110000'', ''30194999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''30210000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''30310000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''30410000'', ''30499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''30510000'', ''30599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''30610000'', ''30659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''30890000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''31000000'', ''31009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''31020000'', ''31029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''31170000'', ''31179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''32010000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''32310000'', ''32395999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''32410000'', ''32429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''32440000'', ''32451999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''32510000'', ''32518999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''32530000'', ''32533999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''32590000'', ''32619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''32660000'', ''32689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''32710000'', ''32735999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''32750000'', ''32762999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''32780000'', ''32988999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''33110000'', ''33491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''33510000'', ''33692999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''33710000'', ''33893999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''33910000'', ''33994999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34010000'', ''34041999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34110000'', ''34129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34160000'', ''34199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34210000'', ''34229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34240000'', ''34259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34330000'', ''34372999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34390000'', ''34391999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34410000'', ''34474999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34490000'', ''34499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34510000'', ''34593999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34610000'', ''34649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34660000'', ''34662999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34680000'', ''34689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34710000'', ''34723999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''34760000'', ''34782999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''35010000'', ''35061999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''35110000'', ''35129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''35190000'', ''35283999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''35310000'', ''35399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''35410000'', ''35414999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''35440000'', ''35463999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''35510000'', ''35549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''35610000'', ''35699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''35810000'', ''35819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''35830000'', ''35859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''36010000'', ''36091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''36110000'', ''36191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''36210000'', ''36229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''36250000'', ''36261999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''36320000'', ''36349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''37000000'', ''37079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''37110000'', ''37129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''37170000'', ''37199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''37330000'', ''37339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''38010000'', ''38021999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''38110000'', ''38191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''38210000'', ''38291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''38310000'', ''38341999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''38410000'', ''38492999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''38510000'', ''38542999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''38610000'', ''38681999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''38780000'', ''38783999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''38810000'', ''38811999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''38830000'', ''38871999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''39010000'', ''39091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''39110000'', ''39111999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''39910000'', ''39921999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''39940000'', ''39942999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''40520000'', ''40529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''40640000'', ''40649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''41000000'', ''41019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''78110000'', ''78119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''81000000'', ''81569999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''81610000'', ''81729999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''84310000'', ''84399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''84410000'', ''84499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''91000000'', ''92429999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''96000000'', ''97049999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Passo Fundo''              ), ''54'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''21010000'', ''21039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''21420000'', ''21429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''23000000'', ''23009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''30110000'', ''30129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''30140000'', ''30199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''30220000'', ''30239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''30250000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''30310000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''31000000'', ''31009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''31740000'', ''31742999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''31810000'', ''31819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''31880000'', ''31889999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''32010000'', ''32029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''32110000'', ''32149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''32160000'', ''32284999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''32310000'', ''32379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''32410000'', ''32449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''32490000'', ''32592999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''32610000'', ''32635999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''32650000'', ''32739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''32750000'', ''32824999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''32860000'', ''32869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''32890000'', ''32919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33010000'', ''33192999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33210000'', ''33229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33240000'', ''33249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33260000'', ''33294999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33310000'', ''33399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33410000'', ''33489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33510000'', ''33564999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33580000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33610000'', ''33679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33690000'', ''33695999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33720000'', ''33734999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33750000'', ''33774999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33790000'', ''33794999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33810000'', ''33814999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''33870000'', ''33874999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''34010000'', ''34059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''34110000'', ''34152999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''34190000'', ''34192999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''34210000'', ''34239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''34250000'', ''34269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''34300000'', ''34352999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35020000'', ''35021999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35050000'', ''35063999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35090000'', ''35094999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35110000'', ''35139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35210000'', ''35292999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35310000'', ''35394999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35410000'', ''35464999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35480000'', ''35484999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35510000'', ''35524999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35540000'', ''35544999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35560000'', ''35574999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35590000'', ''35594999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35630000'', ''35634999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35650000'', ''35654999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35670000'', ''35674999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''35950000'', ''35954999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''36010000'', ''36051999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''36110000'', ''36179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''36210000'', ''36221999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''36240000'', ''36249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''36260000'', ''36269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''36290000'', ''36291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''36430000'', ''36442999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''36490000'', ''36494999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''37000000'', ''37001999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''37300000'', ''37304999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''37370000'', ''37394999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''37410000'', ''37484999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''37510000'', ''37582999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''37720000'', ''37739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''37810000'', ''37821999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''37840000'', ''37854999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''37910000'', ''37924999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''37940000'', ''37944999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''37960000'', ''37984999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''38010000'', ''38091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''38110000'', ''38191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''38210000'', ''38291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''38310000'', ''38391999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''38410000'', ''38491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''38510000'', ''38591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''38610000'', ''38691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''38710000'', ''38799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''38810000'', ''38891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''38910000'', ''38991999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''39110000'', ''39132999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''39150000'', ''39187999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''39210000'', ''39217999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''39310000'', ''39331999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''39510000'', ''39511999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''39610000'', ''39611999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''39670000'', ''39691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''40520000'', ''40529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''41010000'', ''41031999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''44000000'', ''44007601'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''81000000'', ''81609999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''81620000'', ''81629999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''81660000'', ''81769999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''84310000'', ''84399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''84410000'', ''84499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''84510000'', ''84599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''91000000'', ''92139999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''96000000'', ''97429999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''S - Santa Maria''              ), ''55'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''20140000'', ''20149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''20170000'', ''20179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''20200000'', ''20799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''20800000'', ''20999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''21010000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''21410000'', ''21419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''21910000'', ''21969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''22000000'', ''22009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''22050000'', ''22059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''23120000'', ''23122999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''23230000'', ''23289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''24110000'', ''24119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''24150000'', ''24159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''26260000'', ''26269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''27300000'', ''27309999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''27700000'', ''27709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''28260000'', ''28279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''28290000'', ''28299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''30100000'', ''30139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''30210000'', ''30229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''30240000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''30410000'', ''30499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''30510000'', ''30849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''31000000'', ''31119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''31140000'', ''31149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''31200000'', ''31209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''31310000'', ''31312999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''31330000'', ''31339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''31630000'', ''31639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''31810000'', ''31819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''31960000'', ''31969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''32010000'', ''32099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''32110000'', ''32189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''32210000'', ''32269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''32320000'', ''32349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''32410000'', ''32489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''32510000'', ''32579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''32610000'', ''32649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''32720000'', ''32769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''32970000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''33010000'', ''33199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''33210000'', ''33239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''33250000'', ''33369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''33380000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''33610000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''33710000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''33910000'', ''33959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''33970000'', ''33979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''33990000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34010000'', ''34019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34030000'', ''34049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34080000'', ''34129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34140000'', ''34159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34210000'', ''34219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34240000'', ''34279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34290000'', ''34299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34320000'', ''34369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34410000'', ''34439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34450000'', ''34459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34470000'', ''34499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34510000'', ''34519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34530000'', ''34549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34560000'', ''34569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34580000'', ''34599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34610000'', ''34629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34640000'', ''34659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34670000'', ''34689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34710000'', ''34719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34750000'', ''34759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34780000'', ''34799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34810000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34910000'', ''34919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''34930000'', ''34939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35000000'', ''35094999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35210000'', ''35229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35250000'', ''35279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35320000'', ''35369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35400000'', ''35489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35500000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35610000'', ''35699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35770000'', ''35779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35810000'', ''35819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35850000'', ''35859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35910000'', ''35919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35950000'', ''35959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''35970000'', ''35979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36010000'', ''36091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36120000'', ''36299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36310000'', ''36349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36360000'', ''36379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36390000'', ''36399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36420000'', ''36429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36480000'', ''36481999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36610000'', ''36699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36730000'', ''36749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36770000'', ''36779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36790000'', ''36791999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36880000'', ''36899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''36970000'', ''36979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''37010000'', ''37099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''37120000'', ''37123999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''37150000'', ''37199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''37210000'', ''37231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''37970000'', ''37999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''38770000'', ''38799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''39010000'', ''39101999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''39610000'', ''39679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''39690000'', ''39691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''39810000'', ''39851999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''40010000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''40520000'', ''40529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''40620000'', ''40639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''41010000'', ''41079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''44000000'', ''44007601'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''45010000'', ''45015999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''62010000'', ''62019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''78110000'', ''78219999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''81000000'', ''83739999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''84000000'', ''85999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''86010000'', ''86099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''86110000'', ''86199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''86210000'', ''86299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''86310000'', ''86399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''86410000'', ''86499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''86510000'', ''86549999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''91000000'', ''94049999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''95000000'', ''95999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''96010000'', ''96099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''96110000'', ''96199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''96210000'', ''96299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''96310000'', ''96399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''96410000'', ''96499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''96510000'', ''96599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''96610000'', ''96699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''96710000'', ''96799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''96810000'', ''96899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''96910000'', ''96999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''98010000'', ''98099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''98110000'', ''98199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''98210000'', ''98299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''98310000'', ''98399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''98410000'', ''98499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''98510000'', ''98849999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''99010000'', ''99099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''99110000'', ''99199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''99210000'', ''99299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''99310000'', ''99399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''99410000'', ''99499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Brasília''                ), ''61'', ''99510000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''22050000'', ''22059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''27640000'', ''27659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''27700000'', ''27709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''30010000'', ''30019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''30100000'', ''30122999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''30140000'', ''30283999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''30310000'', ''30391999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''30410000'', ''30491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''30510000'', ''30591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''30610000'', ''30691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''30710000'', ''30791999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''30810000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''30910000'', ''31009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''31100000'', ''31119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''31150000'', ''31159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''31230000'', ''31239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''31420000'', ''31429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''31810000'', ''31819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''31960000'', ''31969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''32010000'', ''32659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''32670000'', ''32759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''32770000'', ''32789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''32800000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''33010000'', ''33679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''33690000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''33910000'', ''33991999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34020000'', ''34041999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34060000'', ''34085999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34120000'', ''34129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34160000'', ''34169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34210000'', ''34219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34250000'', ''34259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34270000'', ''34271999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34290000'', ''34299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34320000'', ''34349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34380000'', ''34399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34450000'', ''34499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34510000'', ''34519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34540000'', ''34597999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34610000'', ''34611999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34630000'', ''34679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34730000'', ''34739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34750000'', ''34751999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34810000'', ''34849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34860000'', ''34869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34880000'', ''34889999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''34940000'', ''34949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''35010000'', ''35399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''35410000'', ''35429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''35450000'', ''35469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''35480000'', ''35549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''35570000'', ''35589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''35610000'', ''35619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''35630000'', ''35659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''35670000'', ''35691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''35710000'', ''35799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''35810000'', ''35849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''35860000'', ''35899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''35910000'', ''35991999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''36010000'', ''36099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''36110000'', ''36129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''36210000'', ''36269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''36310000'', ''36399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''36420000'', ''36469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''36510000'', ''36589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''36610000'', ''36699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''36710000'', ''36799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''36830000'', ''36839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''37010000'', ''37089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''37170000'', ''37171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''37320000'', ''37379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''38000000'', ''38009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''38770000'', ''38789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39010000'', ''39081999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39120000'', ''39124999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39200000'', ''39269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39280000'', ''39289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39310000'', ''39339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39350000'', ''39399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39410000'', ''39496999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39510000'', ''39575999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39590000'', ''39597999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39730000'', ''39731999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39750000'', ''39861999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39880000'', ''39919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''39930000'', ''39999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''40010000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''40110000'', ''40189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''40510000'', ''40549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''41010000'', ''41099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''41410000'', ''41429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''44000000'', ''44007297'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''49110000'', ''49129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''78110000'', ''78159999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''81000000'', ''83329999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''84000000'', ''86119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''86180000'', ''86289999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''91000000'', ''94749999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''96000000'', ''96999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''98000000'', ''98539999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Santa Isabel''            ), ''62'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''21010000'', ''21049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''21110000'', ''21129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''30150000'', ''30159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''30250000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''30310000'', ''30391999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''30410000'', ''30435999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''30450000'', ''30459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''31000000'', ''31009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''32120000'', ''32212999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''32230000'', ''32263999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''32280000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''32320000'', ''32349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''32360000'', ''32365999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''32430000'', ''32449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''32600000'', ''32609999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''32620000'', ''32629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33010000'', ''33039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33090000'', ''33092999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33110000'', ''33179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33190000'', ''33193999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33210000'', ''33239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33350000'', ''33351999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33390000'', ''33399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33420000'', ''33421999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33440000'', ''33491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33510000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33610000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33710000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''33910000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''34020000'', ''34021999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''34060000'', ''34069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''34110000'', ''34169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''34200000'', ''34595999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''34610000'', ''34799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''34810000'', ''34891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''34910000'', ''34993999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''35010000'', ''35019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''35090000'', ''35099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''35120000'', ''35161999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''35190000'', ''35319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''35330000'', ''35365999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''35380000'', ''35581999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''35710000'', ''35729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''35760000'', ''35761999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''36020000'', ''36029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''36040000'', ''36073999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''36110000'', ''36129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''36150000'', ''36151999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''36210000'', ''36211999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''36240000'', ''36261999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''36530000'', ''36549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''36580000'', ''36599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''36850000'', ''36859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''36910000'', ''36929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''36950000'', ''36971999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''39010000'', ''39063999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''39150000'', ''39156999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''39290000'', ''39293999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''39370000'', ''39372999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''39510000'', ''39533999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''40520000'', ''40539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''41000000'', ''41013999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''44000000'', ''44007604'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''81000000'', ''81519999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''84000000'', ''84699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''84710000'', ''84799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''84810000'', ''84899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''84910000'', ''84999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''91000000'', ''91089999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''92000000'', ''92999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''99110000'', ''99119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''99280000'', ''99399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''99410000'', ''99499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''99510000'', ''99599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''99610000'', ''99899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Palmas''                   ), ''63'', ''99910000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''21010000'', ''21049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''21320000'', ''21339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''21410000'', ''21429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''30130000'', ''30177999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''30190000'', ''30191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''30210000'', ''30291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''30310000'', ''30311999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''30330000'', ''30391999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''30410000'', ''30431999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''30450000'', ''30461999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''30500000'', ''30559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''30710000'', ''30711999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''32110000'', ''32139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''32200000'', ''32219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''32930000'', ''32949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''33010000'', ''33019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''33090000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''33110000'', ''33119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''33210000'', ''33229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''33770000'', ''33779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34030000'', ''34061999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34080000'', ''34092999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34110000'', ''34141999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34160000'', ''34179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34190000'', ''34199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34220000'', ''34233999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34300000'', ''34383999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34400000'', ''34459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34470000'', ''34479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34500000'', ''34509999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34520000'', ''34569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34580000'', ''34582999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34610000'', ''34629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34650000'', ''34659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34690000'', ''34699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34710000'', ''34729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34740000'', ''34759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34780000'', ''34809999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34890000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34910000'', ''34929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''34950000'', ''34989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''35040000'', ''35049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''35090000'', ''35096999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''35120000'', ''35149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''35430000'', ''35439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''35470000'', ''35479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''35530000'', ''35539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''35550000'', ''35571999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''35590000'', ''35609999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''35620000'', ''35651999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''35670000'', ''35719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''36010000'', ''36159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''36170000'', ''36189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''36200000'', ''36692999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''36710000'', ''36729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''36740000'', ''36899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''36910000'', ''37009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39010000'', ''39091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39120000'', ''39121999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39210000'', ''39216999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39240000'', ''39263999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39290000'', ''39296999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39320000'', ''39328999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39350000'', ''39353999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39380000'', ''39386999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39420000'', ''39421999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39440000'', ''39443999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39540000'', ''39544999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39570000'', ''39591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39630000'', ''39634999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39650000'', ''39656999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39670000'', ''39678999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39710000'', ''39724999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''39770000'', ''39771999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''40020000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''44000000'', ''44007207'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''81000000'', ''81669999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''81680000'', ''81709999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''84310000'', ''84399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''84410000'', ''84499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''84510000'', ''84589999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''84790000'', ''84799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''92000000'', ''93239999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''96000000'', ''96189999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''96230000'', ''96279999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''96410000'', ''96489999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''96520000'', ''96559999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''96580000'', ''96589999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''96600000'', ''96679999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''96710000'', ''96719999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''96750000'', ''96769999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''96950000'', ''96959999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''96990000'', ''96999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''99000000'', ''99129999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''99150000'', ''99199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''99210000'', ''99299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''99310000'', ''99399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''99410000'', ''99929999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rio Verde''               ), ''64'', ''99940000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''20140000'', ''20149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''20650000'', ''20656999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''21010000'', ''21019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''21210000'', ''21239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''21280000'', ''21289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''21930000'', ''21939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''23910000'', ''23919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''30210000'', ''30239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''30250000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''30410000'', ''30439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''30460000'', ''30469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''30510000'', ''30599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''31010000'', ''31061999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32020000'', ''32071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32110000'', ''32131999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32210000'', ''32252999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32270000'', ''32281999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32330000'', ''32352999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32380000'', ''32381999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32410000'', ''32417999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32440000'', ''32443999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32470000'', ''32471999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32510000'', ''32529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32540000'', ''32541999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32570000'', ''32572999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32590000'', ''32594999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32610000'', ''32615999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32650000'', ''32669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32680000'', ''32681999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32730000'', ''32731999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32750000'', ''32771999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32820000'', ''32834999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32890000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''32910000'', ''32915999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33010000'', ''33052999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33070000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33110000'', ''33197999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33210000'', ''33279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33290000'', ''33294999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33310000'', ''33399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33410000'', ''33491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33510000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33610000'', ''33667999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33710000'', ''33719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33740000'', ''33741999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33760000'', ''33769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33820000'', ''33841999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33870000'', ''33889999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33910000'', ''33911999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33930000'', ''33931999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''33960000'', ''33979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''34490000'', ''34494999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''34570000'', ''34579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''34910000'', ''34921999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''35130000'', ''35138999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''35280000'', ''35296999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''35480000'', ''35499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''35890000'', ''35891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36100000'', ''36195999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36210000'', ''36299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36310000'', ''36329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36340000'', ''36349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36370000'', ''36379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36410000'', ''36469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36480000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36520000'', ''36543999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36610000'', ''36696999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36750000'', ''36756999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36810000'', ''36829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36840000'', ''36869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36880000'', ''36889999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36910000'', ''36927999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''36940000'', ''36959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''37010000'', ''37081999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''37170000'', ''37179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''39010000'', ''39086999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''39110000'', ''39119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''39220000'', ''39229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''39250000'', ''39289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''39410000'', ''39417999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''40520000'', ''40529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''40620000'', ''40639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''41010000'', ''41052999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''44000000'', ''44007629'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''62010000'', ''62019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''78780000'', ''78789999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''81000000'', ''81649999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''81670000'', ''81679999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''84310000'', ''84399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''84410000'', ''84499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''84510000'', ''84599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''84610000'', ''84699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''84710000'', ''84799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''92000000'', ''93319999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''96000000'', ''96659999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''96670000'', ''96999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''98000000'', ''98109999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Cuiabá''                  ), ''65'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''21010000'', ''21059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''21320000'', ''21339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''30150000'', ''30169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''30220000'', ''30279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''32110000'', ''32129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''33010000'', ''33029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''33210000'', ''33219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''33280000'', ''33286999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''33850000'', ''33865999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''33890000'', ''33891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''33970000'', ''33978999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''33990000'', ''33996999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34010000'', ''34024999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34050000'', ''34199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34210000'', ''34273999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34310000'', ''34399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34410000'', ''34492999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34510000'', ''34591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34610000'', ''34691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34710000'', ''34736999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34750000'', ''34799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34810000'', ''34815999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34860000'', ''34864999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34880000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''34930000'', ''35293999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''35310000'', ''35491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''35510000'', ''35692999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''35710000'', ''35792999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''35810000'', ''35891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''35910000'', ''35991999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''36010000'', ''36061999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''37010000'', ''37089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''39010000'', ''39079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''39090000'', ''39097999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''39110000'', ''39118999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''40020000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''41010000'', ''41012999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''44000000'', ''44007620'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''81000000'', ''81499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''84310000'', ''84399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''84410000'', ''84499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''84510000'', ''84539999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''84570000'', ''84599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''84610000'', ''84629999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''92000000'', ''92199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''92210000'', ''92299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''92310000'', ''92499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''92810000'', ''92839999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''92920000'', ''92929999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''96000000'', ''96659999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''96670000'', ''96999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''99000000'', ''99449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''99510000'', ''99599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''99610000'', ''99899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''99910000'', ''99919999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Rondonópolis''            ), ''66'', ''99940000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''20210000'', ''20219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''21030000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''30150000'', ''30192999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''30210000'', ''30239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''30250000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''30320000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''30410000'', ''30479999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''30560000'', ''30569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''31310000'', ''31313999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32010000'', ''32099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32110000'', ''32161999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32210000'', ''32229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32250000'', ''32281999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32300000'', ''32581999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32600000'', ''32694999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32720000'', ''32729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32740000'', ''32751999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32780000'', ''32782999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32810000'', ''32826999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32850000'', ''32874999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32890000'', ''32892999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32910000'', ''32926999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32950000'', ''32958999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''32970000'', ''32971999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33010000'', ''33069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33080000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33110000'', ''33189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33200000'', ''33274999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33290000'', ''33299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33310000'', ''33319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33410000'', ''33429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33440000'', ''33495999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33510000'', ''33529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33540000'', ''33589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33610000'', ''33689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33730000'', ''33739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33780000'', ''33789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33800000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33910000'', ''33919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33930000'', ''33939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''33970000'', ''33989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''34010000'', ''34031999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''34050000'', ''34061999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''34080000'', ''34291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''34310000'', ''34492999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''34510000'', ''34591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''34610000'', ''34619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''34630000'', ''34691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''34710000'', ''34714999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''34730000'', ''34921999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''34940000'', ''34961999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''34980000'', ''34991999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35030000'', ''35039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35090000'', ''35099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35110000'', ''35129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35210000'', ''35229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35240000'', ''35249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35320000'', ''35369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35410000'', ''35419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35460000'', ''35471999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35570000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35620000'', ''35628999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35650000'', ''35659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35680000'', ''35682999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35740000'', ''35749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35790000'', ''35792999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35910000'', ''35912999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''35960000'', ''35968999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''36650000'', ''36666999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''36680000'', ''36696999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''36710000'', ''36767999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''36810000'', ''36835999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''36860000'', ''36877999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''37110000'', ''37111999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''37170000'', ''37179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''39010000'', ''39097999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''39190000'', ''39199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''39210000'', ''39299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''39310000'', ''39321999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''39410000'', ''39419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''40010000'', ''40059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''40200000'', ''40208999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''40620000'', ''40639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''44000000'', ''44007626'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''49110000'', ''49119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''81000000'', ''81979999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''82000000'', ''82159999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''84310000'', ''84399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''84410000'', ''84499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''84510000'', ''84599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''84610000'', ''84699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''84710000'', ''84799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''84810000'', ''84849999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''84880000'', ''84889999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''88010000'', ''88019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''91000000'', ''93119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''96000000'', ''96999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''98000000'', ''98779999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''CO - Três Lagoas''             ), ''67'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''21010000'', ''21069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''21220000'', ''21239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''30150000'', ''30159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''30250000'', ''30269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''30280000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''30310000'', ''30319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''32110000'', ''32169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''32210000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''32310000'', ''32351999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''32370000'', ''32383999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''32420000'', ''32426999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''32440000'', ''32443999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''32480000'', ''32486999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''32610000'', ''32623999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''32670000'', ''32671999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''33010000'', ''33039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''33090000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''33110000'', ''33119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''33210000'', ''33229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''33250000'', ''33295999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''33420000'', ''33431999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''33450000'', ''33453999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''33490000'', ''33491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''33980000'', ''33989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''34620000'', ''34641999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''34690000'', ''34693999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''35420000'', ''35426999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''35440000'', ''35441999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''35460000'', ''35466999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''35480000'', ''35481999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''36110000'', ''36126999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''36150000'', ''36151999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''39010000'', ''39021999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''39040000'', ''39087999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''40520000'', ''40529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''41010000'', ''41019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''44000000'', ''44007605'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''81000000'', ''81039999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''81050000'', ''81159999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''81170000'', ''81249999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''84210000'', ''84289999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''92010000'', ''92099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''92110000'', ''92199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''92230000'', ''92249999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''92260000'', ''92269999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''92280000'', ''92299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''92310000'', ''92399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''92410000'', ''92499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''92810000'', ''92839999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''92920000'', ''92929999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''99000000'', ''99299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''99310000'', ''99399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''99410000'', ''99499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''99510000'', ''99599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''99610000'', ''99899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Rio Branco''               ), ''68'', ''99910000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''21410000'', ''21429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''21810000'', ''21839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''22220000'', ''22229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''30150000'', ''30159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''30250000'', ''30289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''30430000'', ''30439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''32010000'', ''32019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''32100000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''32210000'', ''32392999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''32410000'', ''32411999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''32510000'', ''32532999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''32590000'', ''32591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''32620000'', ''32621999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''33010000'', ''33029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''33090000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''33110000'', ''33119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''33160000'', ''33169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''33210000'', ''33229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''33250000'', ''33251999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''33330000'', ''33339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''33410000'', ''33493999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''33590000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''33620000'', ''33621999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''33980000'', ''33989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34110000'', ''34133999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34160000'', ''34169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34180000'', ''34184999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34210000'', ''34249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34270000'', ''34282999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34320000'', ''34322999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34340000'', ''34352999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34410000'', ''34499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34510000'', ''34529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34590000'', ''34594999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34610000'', ''34619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34630000'', ''34681999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34710000'', ''34719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34730000'', ''34751999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34810000'', ''34816999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34840000'', ''34861999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''34910000'', ''34921999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''35160000'', ''35169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''35210000'', ''35219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''35230000'', ''35369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''35390000'', ''35392999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''35410000'', ''35419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''35430000'', ''35449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''35460000'', ''35471999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''35560000'', ''35561999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''35590000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''35760000'', ''35761999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''35810000'', ''35831999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''36090000'', ''36099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''36210000'', ''36215999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''36230000'', ''36234999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''36410000'', ''36431999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''36450000'', ''36467999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''36510000'', ''36523999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''36540000'', ''36541999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''37330000'', ''37339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''39010000'', ''39096999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''39110000'', ''39197999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''39210000'', ''39212999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''40520000'', ''40529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''41000000'', ''41029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''44000000'', ''44007632'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''81000000'', ''81619999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''81630000'', ''81639999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''81700000'', ''81709999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''84110000'', ''84199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''84210000'', ''84299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''84310000'', ''84399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''84410000'', ''84499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''84510000'', ''84599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''84610000'', ''84699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''84710000'', ''84799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''84810000'', ''84899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''84910000'', ''84969999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''92000000'', ''93569999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''96000000'', ''96039999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Porto Velho''              ), ''69'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''20140000'', ''20149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''21010000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''21320000'', ''21379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''21410000'', ''21419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''22010000'', ''22039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''22230000'', ''22249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''26260000'', ''26269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''27700000'', ''27709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''30110000'', ''30199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''30210000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''30310000'', ''30419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''30450000'', ''30509999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''30820000'', ''30839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''31030000'', ''31039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''31110000'', ''31199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''31210000'', ''31219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''31690000'', ''31699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''31710000'', ''31799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''31810000'', ''31899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''31910000'', ''32001999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''32020000'', ''32089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''32110000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''32210000'', ''32219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''32290000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''32510000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''32610000'', ''32619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''32630000'', ''32649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''32660000'', ''32679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''32700000'', ''32739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''32750000'', ''32779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''32810000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''32910000'', ''32985999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''33010000'', ''33169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''33190000'', ''33489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''33500000'', ''33609999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''33620000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''34010000'', ''34099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''34110000'', ''34199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''34210000'', ''34229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''34310000'', ''34379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''34430000'', ''34449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''34500000'', ''34549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''34600000'', ''34685999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''34720000'', ''34749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''34800000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''34910000'', ''34999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''35010000'', ''35089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''35120000'', ''35129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''35210000'', ''35219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''35250000'', ''35259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''35270000'', ''35278999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''35310000'', ''35369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''35550000'', ''35559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''35610000'', ''35659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''35770000'', ''35779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''35940000'', ''35949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''35970000'', ''35979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36010000'', ''36029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36040000'', ''36079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36110000'', ''36129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36160000'', ''36179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36210000'', ''36299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36310000'', ''36386999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36410000'', ''36429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36440000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36510000'', ''36529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36550000'', ''36568999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36620000'', ''36652999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36670000'', ''36695999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36710000'', ''36724999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36740000'', ''36748999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36760000'', ''36784999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36810000'', ''36823999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''36840000'', ''36841999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''37170000'', ''37179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''37970000'', ''37979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''38770000'', ''38799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''40070000'', ''40073999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''41010000'', ''41099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''41110000'', ''41199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''41210000'', ''41266999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''62010000'', ''62019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''78110000'', ''78159999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''81000000'', ''84419999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''85000000'', ''85179999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''86000000'', ''88999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''91000000'', ''93419999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''93440000'', ''93899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''93990000'', ''93999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''94010000'', ''94029999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''96000000'', ''97439999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Salvador''                ), ''71'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''20110000'', ''20119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''21010000'', ''21059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''21320000'', ''21349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''21510000'', ''21529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''30110000'', ''30189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''30210000'', ''30229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''30310000'', ''30311999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''30410000'', ''30439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''30460000'', ''30489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''30510000'', ''30511999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''30810000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''31610000'', ''31668999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''31770000'', ''31789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''32010000'', ''32098999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''32110000'', ''32169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''32210000'', ''32266999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''32290000'', ''32319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''32340000'', ''32491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''32510000'', ''32513999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''32540000'', ''32596999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''32610000'', ''32797999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''32810000'', ''32998999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''33010000'', ''33019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''33160000'', ''33169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''34210000'', ''34229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''34240000'', ''34249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''35110000'', ''35129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''35210000'', ''35215999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''35250000'', ''35289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''35300000'', ''35495999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''35510000'', ''35541999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''35560000'', ''35562999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''35610000'', ''35616999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''35730000'', ''35731999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''35750000'', ''35758999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''35770000'', ''35771999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''35950000'', ''35951999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''35970000'', ''35979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36040000'', ''36069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36090000'', ''36109999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36120000'', ''36139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36160000'', ''36189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36210000'', ''36292999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36310000'', ''36349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36390000'', ''36401999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36450000'', ''36457999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36530000'', ''36531999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36550000'', ''36576999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36610000'', ''36627999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36650000'', ''36651999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36670000'', ''36691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36710000'', ''36805999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36820000'', ''36841999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36860000'', ''36899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36920000'', ''36922999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36940000'', ''36941999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''36960000'', ''36971999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''38770000'', ''38789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''41020000'', ''41032999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''44000000'', ''44007603'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''78110000'', ''78119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''81000000'', ''82339999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''88610000'', ''88699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''88710000'', ''88799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''88810000'', ''88899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''88910000'', ''88989999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''91000000'', ''91729999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''91780000'', ''91819999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''91910000'', ''91919999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''91930000'', ''91969999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''91980000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''98000000'', ''98429999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Ilhéus''                  ), ''73'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''21020000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''30170000'', ''30179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''30610000'', ''30699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''30850000'', ''30859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''31020000'', ''31029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''31610000'', ''31628999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''32110000'', ''32139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''32210000'', ''32229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''32290000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''32580000'', ''32596999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''32740000'', ''32745999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''32870000'', ''32872999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''33010000'', ''33019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''34940000'', ''34949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''34960000'', ''34969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''35230000'', ''35243999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''35260000'', ''35295999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''35310000'', ''35383999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''35410000'', ''35424999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''35440000'', ''35449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''35460000'', ''35498999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''35510000'', ''35539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''35590000'', ''35597999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''35770000'', ''35772999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''35970000'', ''35979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36020000'', ''36029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36040000'', ''36056999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36080000'', ''36087999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36100000'', ''36149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36170000'', ''36249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36260000'', ''36376999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36390000'', ''36491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36510000'', ''36597999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36610000'', ''36651999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36670000'', ''36697999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36710000'', ''36776999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36790000'', ''36791999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36810000'', ''36819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36830000'', ''36893999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36910000'', ''36959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36970000'', ''36976999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''36990000'', ''36997999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''41010000'', ''41038999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''44000000'', ''44007643'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''81000000'', ''81419999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''88610000'', ''88629999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''91000000'', ''91359999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''91370000'', ''91449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''91470000'', ''91499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''91880000'', ''91899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''91910000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''99220000'', ''99899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''99910000'', ''99919999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Mundo Novo''              ), ''74'', ''99940000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''21330000'', ''21349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''30140000'', ''30179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''30210000'', ''30339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''30520000'', ''30529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''30620000'', ''30629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''31610000'', ''31648999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''31790000'', ''31799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''31810000'', ''31839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''31850000'', ''31879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32010000'', ''32059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32070000'', ''32081999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32110000'', ''32191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32210000'', ''32219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32230000'', ''32276999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32290000'', ''32396999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32410000'', ''32493999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32510000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32610000'', ''32696999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32710000'', ''32793999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32810000'', ''32896999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32910000'', ''32947999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''32960000'', ''32988999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''33010000'', ''33049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''33160000'', ''33169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''33200000'', ''33282999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''33300000'', ''33325999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''33340000'', ''33412999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''33430000'', ''33455999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''33510000'', ''33539999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''33580000'', ''33582999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''33610000'', ''33669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''33810000'', ''33811999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''33870000'', ''33877999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34020000'', ''34047999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34110000'', ''34118999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34130000'', ''34146999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34180000'', ''34399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34410000'', ''34417999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34430000'', ''34437999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34450000'', ''34499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34510000'', ''34535999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34560000'', ''34566999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34580000'', ''34585999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34620000'', ''34628999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34690000'', ''34699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34710000'', ''34729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34740000'', ''34777999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34810000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34910000'', ''34919999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''34930000'', ''34979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''35010000'', ''35029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''35220000'', ''35225999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''35260000'', ''35279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''35350000'', ''35353999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''35420000'', ''35422999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''35440000'', ''35455999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''35770000'', ''35771999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''35930000'', ''35938999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''35970000'', ''36179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''36210000'', ''36298999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''36310000'', ''36329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''36340000'', ''36396999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''36410000'', ''36543999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''36560000'', ''36602999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''36620000'', ''36659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''36670000'', ''36699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''36730000'', ''36748999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''36760000'', ''36775999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''36800000'', ''36861999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''36880000'', ''36992999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''41010000'', ''41032999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''41080000'', ''41089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''44000000'', ''44007227'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''78110000'', ''78119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''81000000'', ''83409999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''88610000'', ''88699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''88710000'', ''88799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''88810000'', ''88849999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''91000000'', ''92659999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''92680000'', ''92689999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''98000000'', ''98979999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Santa Quitéria''          ), ''75'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''20210000'', ''20229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''21010000'', ''21039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''21410000'', ''21429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''30170000'', ''30181999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''30210000'', ''30219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''30810000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''31610000'', ''31638999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''32010000'', ''32029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''32160000'', ''32183999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''32210000'', ''32229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''32290000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''32610000'', ''32623999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''32640000'', ''32642999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''32740000'', ''32755999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''33110000'', ''33129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''33410000'', ''33411999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''33770000'', ''33779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''34010000'', ''34036999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''34050000'', ''34062999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''34080000'', ''34099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''34110000'', ''34172999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''34200000'', ''34279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''34290000'', ''34686999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''34700000'', ''34819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''34830000'', ''34897999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''34910000'', ''34994999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''35350000'', ''35353999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''35770000'', ''35772999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''35970000'', ''35979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36040000'', ''36047999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36100000'', ''36149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36160000'', ''36293999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36310000'', ''36333999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36370000'', ''36391999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36410000'', ''36501999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36520000'', ''36527999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36560000'', ''36585999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36610000'', ''36657999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36670000'', ''36686999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36710000'', ''36716999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36730000'', ''36742999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36770000'', ''36782999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36820000'', ''36842999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36860000'', ''36891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36910000'', ''36951999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''36980000'', ''36986999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''44000000'', ''44007627'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''81000000'', ''81649999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''88610000'', ''88699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''88710000'', ''88769999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''91000000'', ''91769999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''91780000'', ''91799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''91830000'', ''91839999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''91860000'', ''91879999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''91910000'', ''91919999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''91930000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''98000000'', ''98569999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Vitória da Conquista''    ), ''77'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''21040000'', ''21079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''30120000'', ''30125999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''30140000'', ''30179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''30210000'', ''30289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''30410000'', ''30469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''30850000'', ''30879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''31110000'', ''31149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''31790000'', ''31799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''31940000'', ''31949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32050000'', ''32059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32090000'', ''32099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32110000'', ''32192999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32210000'', ''32274999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32310000'', ''32349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32360000'', ''32369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32380000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32410000'', ''32419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32430000'', ''32499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32510000'', ''32579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32590000'', ''32663999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32680000'', ''32692999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32710000'', ''32819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32850000'', ''32858999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32870000'', ''32887999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''32970000'', ''32976999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''33120000'', ''33145999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''33160000'', ''33165999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''33180000'', ''33191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''33210000'', ''33239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''33250000'', ''33251999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''33370000'', ''33395999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''33410000'', ''33497999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''33510000'', ''33529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''33540000'', ''33548999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''33610000'', ''33671999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''33770000'', ''33771999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34010000'', ''34019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34110000'', ''34117999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34210000'', ''34229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34310000'', ''34329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34350000'', ''34373999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34410000'', ''34457999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34470000'', ''34478999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34490000'', ''34495999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34530000'', ''34537999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34550000'', ''34551999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34570000'', ''34571999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34590000'', ''34593999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34610000'', ''34611999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34650000'', ''34651999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''34830000'', ''34837999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''35170000'', ''35174999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''35220000'', ''35229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''35260000'', ''35267999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''35300000'', ''35309999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''35380000'', ''35397999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''35410000'', ''35498999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''36110000'', ''36117499'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''36130000'', ''36139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''36150000'', ''36161999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''36310000'', ''36329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''36350000'', ''36383999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''36410000'', ''36458999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''36480000'', ''36482999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''36510000'', ''36512999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''36530000'', ''36542999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''37110000'', ''37129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''37210000'', ''37219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''37260000'', ''37265999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''37280000'', ''37298999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''37310000'', ''37326999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''37360000'', ''37369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''37410000'', ''37422999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''37510000'', ''37519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''37610000'', ''37615999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''41010000'', ''41029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''81000000'', ''81809999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''88610000'', ''88699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''88710000'', ''88799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''91000000'', ''91009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''91020000'', ''91089999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''91100000'', ''91399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''91410000'', ''91499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''91510000'', ''91599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''91610000'', ''91659999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''91910000'', ''91939999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''91950000'', ''91959999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''91980000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''96000000'', ''96659999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Aracaju''                 ), ''79'', ''98000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''20140000'', ''20149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''21010000'', ''21059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''21190000'', ''21199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''21210000'', ''21239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''21250000'', ''21299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''21370000'', ''21389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''23230000'', ''23239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''26260000'', ''26269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''27270000'', ''27279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''27700000'', ''27709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''30100000'', ''30999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''31010000'', ''31025999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''31120000'', ''31149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''31160000'', ''31179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''31210000'', ''31239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''31250000'', ''31299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''31330000'', ''31349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''31810000'', ''31849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''31940000'', ''31949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''32010000'', ''32093999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''32110000'', ''32149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''32160000'', ''32179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''32200000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''32310000'', ''32339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''32360000'', ''32369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''32410000'', ''32449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''32490000'', ''32499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''32510000'', ''32579999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''32650000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''32710000'', ''32749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''33010000'', ''33079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''33110000'', ''33289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''33340000'', ''33349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''33380000'', ''33399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''33410000'', ''33459999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''33510000'', ''33569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''33610000'', ''33689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''33710000'', ''33739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''33750000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34010000'', ''34029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34110000'', ''34149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34160000'', ''34169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34180000'', ''34199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34210000'', ''34299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34310000'', ''34399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34410000'', ''34499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34510000'', ''34599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34610000'', ''34699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34710000'', ''34799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34810000'', ''34849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34860000'', ''34889999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34910000'', ''34959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''34970000'', ''34999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''35010000'', ''35019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''35100000'', ''35129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''35140000'', ''35199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''35210000'', ''35311999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''35330000'', ''35389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''35400000'', ''35489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''35510000'', ''35574999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''35590000'', ''35591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''35610000'', ''35639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''35760000'', ''35781999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''35810000'', ''35811999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36010000'', ''36072999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36100000'', ''36173999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36190000'', ''36194999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36210000'', ''36294999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36310000'', ''36315999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36330000'', ''36392999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36410000'', ''36491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36510000'', ''36591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36610000'', ''36629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36650000'', ''36651999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36670000'', ''36671999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36710000'', ''36715999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36730000'', ''36763999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36780000'', ''36799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36810000'', ''36891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''36910000'', ''37141999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''37170000'', ''37179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''37190000'', ''37199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''37210000'', ''37292999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''37310000'', ''37392999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''37410000'', ''37493999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''37510000'', ''37599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''37710000'', ''37719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''37970000'', ''37979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''38210000'', ''38219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''38230000'', ''38239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''38770000'', ''38799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''39030000'', ''39052999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''39110000'', ''39123999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''39140000'', ''39165999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''39230000'', ''39239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''39710000'', ''39749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''39760000'', ''39769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''39780000'', ''39789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''40070000'', ''40073999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''41000000'', ''41099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''41120000'', ''41199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''41210000'', ''41268999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''41310000'', ''41319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''41370000'', ''41379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''62010000'', ''62019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''73000000'', ''73189999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''78110000'', ''78159999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''81000000'', ''82639999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''83000000'', ''83609999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''84000000'', ''89999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''91000000'', ''95519999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''95550000'', ''95669999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Xexéu''                   ), ''81'', ''96000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''20210000'', ''20229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''21010000'', ''21039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''21210000'', ''21239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''21260000'', ''21269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''21320000'', ''21339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''30130000'', ''30138999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''30150000'', ''30159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''30210000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''30310000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''31120000'', ''31125999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''31310000'', ''31313999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''31770000'', ''31779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''31810000'', ''31839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''31850000'', ''31859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''31940000'', ''31949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''32010000'', ''32046999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''32110000'', ''32129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''32140000'', ''32189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''32210000'', ''32219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''32230000'', ''32239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''32310000'', ''32329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''32340000'', ''32359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''32410000'', ''32419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''32480000'', ''32492999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''32510000'', ''32892999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''32910000'', ''32995999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33020000'', ''33024999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33040000'', ''33055999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33080000'', ''33084999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33110000'', ''33189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33200000'', ''33229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33240000'', ''33289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33320000'', ''33329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33340000'', ''33349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33360000'', ''33389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33410000'', ''33449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33460000'', ''33469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33500000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33610000'', ''33621999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33640000'', ''33681999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33710000'', ''33789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33910000'', ''33911999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33930000'', ''33931999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''33990000'', ''33991999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''34200000'', ''34271999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''34290000'', ''34299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''34320000'', ''34369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''34810000'', ''34829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''34850000'', ''34859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''35170000'', ''35179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''35200000'', ''35399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''35410000'', ''35437999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''35460000'', ''35472999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''35510000'', ''35595999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''35970000'', ''35979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''36200000'', ''36291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''36310000'', ''36326999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''36340000'', ''36341999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''36400000'', ''36476999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''36660000'', ''36668999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''36860000'', ''36867999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''37210000'', ''37219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''41010000'', ''41099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''41110000'', ''41114999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''81000000'', ''81939999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''87010000'', ''87099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''87110000'', ''87199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''87210000'', ''87299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''87310000'', ''87399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''87410000'', ''87469999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''87480000'', ''87499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''87510000'', ''87599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''87610000'', ''87689999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''88000000'', ''88999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''91000000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''93000000'', ''94089999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''94440000'', ''94449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''96000000'', ''96999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''98000000'', ''98189999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''98200000'', ''98209999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Maceió''                  ), ''82'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''21060000'', ''21089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''21410000'', ''21429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30110000'', ''30119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30130000'', ''30139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30150000'', ''30159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30210000'', ''30239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30310000'', ''30359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30410000'', ''30499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30510000'', ''30569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30580000'', ''30589999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30630000'', ''30639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30650000'', ''30669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30770000'', ''30779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30850000'', ''30859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30880000'', ''30889999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''30990000'', ''30999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''31120000'', ''31129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''31230000'', ''31239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''31330000'', ''31334999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''31810000'', ''31829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''31850000'', ''31859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''31870000'', ''31879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''31910000'', ''31927999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''31940000'', ''31949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''32010000'', ''32039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''32080000'', ''32099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''32110000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''32310000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''32410000'', ''32591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''32610000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''32710000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''33010000'', ''33119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''33130000'', ''33171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''33210000'', ''33239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''33250000'', ''33263999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''33290000'', ''33293999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''33310000'', ''33399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''33410000'', ''33997999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''34090000'', ''34093999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''34150000'', ''34159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''34190000'', ''34191999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''34210000'', ''34291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''34310000'', ''34593999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''34610000'', ''34691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''34710000'', ''34855999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''34870000'', ''34941999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''34980000'', ''34991999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35020000'', ''35099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35110000'', ''35139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35150000'', ''35159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35170000'', ''35179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35210000'', ''35229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35250000'', ''35255999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35270000'', ''35276999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35310000'', ''35391999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35410000'', ''35456999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35470000'', ''35481999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35510000'', ''35561999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35580000'', ''35591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35610000'', ''35631999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35650000'', ''35679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''35750000'', ''35789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''36030000'', ''36079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''36120000'', ''36154999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''36170000'', ''36189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''36210000'', ''36291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''36320000'', ''36391999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''36410000'', ''36451999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''36510000'', ''36515999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''36610000'', ''36669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''36810000'', ''36864999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''40070000'', ''40071999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''40640000'', ''40649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''41000000'', ''41029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''41040000'', ''41089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''81000000'', ''81899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''86000000'', ''86479999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''86490000'', ''86819999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''86900000'', ''86909999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''87000000'', ''88999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''91000000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''93000000'', ''94209999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''94440000'', ''94449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''96000000'', ''96999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''98000000'', ''98419999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''98430000'', ''98579999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - João Pessoa''             ), ''83'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''20100000'', ''20119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''20140000'', ''20149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''20200000'', ''20209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''20800000'', ''20809999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''22220000'', ''22229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''22260000'', ''22269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''30120000'', ''30129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''30150000'', ''30157999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''30210000'', ''30219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''30250000'', ''30299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''30310000'', ''30349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''30610000'', ''30669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''30810000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''30910000'', ''30929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''31120000'', ''31129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''31310000'', ''31339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''31940000'', ''31949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''32010000'', ''32329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''32340000'', ''32494999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''32510000'', ''32693999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''32710000'', ''32798999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''32810000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''32910000'', ''32954999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''32970000'', ''32994999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''33010000'', ''33039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''33110000'', ''33129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''33140000'', ''33386999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''33410000'', ''33469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''33510000'', ''33519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''33530000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''33610000'', ''33689999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''33710000'', ''33799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''33810000'', ''33895999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''33910000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''34050000'', ''34059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''34110000'', ''34129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''34170000'', ''34179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''34210000'', ''34298999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''34310000'', ''34399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''34710000'', ''34734999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''34750000'', ''34796999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''34880000'', ''34884999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''35020000'', ''35059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''35170000'', ''35179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''35210000'', ''35238999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''35250000'', ''35262999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''35310000'', ''35363999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''35380000'', ''35384999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''35520000'', ''35533999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''35550000'', ''35555999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''36040000'', ''36069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''36080000'', ''36089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''36110000'', ''36119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''36130000'', ''36189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''36200000'', ''36224999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''36240000'', ''36259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''36310000'', ''36393999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''36410000'', ''36489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''36530000'', ''36549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''36610000'', ''36649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''36710000'', ''36749999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''36910000'', ''36979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''37370000'', ''37379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''40010000'', ''40069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''40080000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''41010000'', ''41042999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''41060000'', ''41061999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''41090000'', ''41091999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''44440000'', ''44449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''62010000'', ''62019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''81000000'', ''81819999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''86000000'', ''86119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''87000000'', ''87499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''87510000'', ''87599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''87610000'', ''87699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''87710000'', ''87799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''87810000'', ''88999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''91000000'', ''92269999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''94000000'', ''94999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''96000000'', ''96999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''98000000'', ''98229999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''98270000'', ''98449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Natal''                   ), ''84'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''20140000'', ''20149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''21010000'', ''21039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''25250000'', ''25259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''27270000'', ''27279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''27700000'', ''27709999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30110000'', ''30179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30210000'', ''30239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30250000'', ''30259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30310000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30410000'', ''30429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30440000'', ''30489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30510000'', ''30529999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30550000'', ''30559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30610000'', ''30679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30770000'', ''30779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30810000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30910000'', ''30959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''30990000'', ''31029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''31050000'', ''31059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''31110000'', ''31183999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''31330000'', ''31339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''31810000'', ''31819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''31940000'', ''31959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''32000000'', ''32025999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''32040000'', ''32216999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''32230000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''32410000'', ''32799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''32810000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33010000'', ''33089999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33100000'', ''33129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33150000'', ''33159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33170000'', ''33293999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33310000'', ''33329999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33340000'', ''33393999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33410000'', ''33489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33510000'', ''33535999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33550000'', ''33584999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33610000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33710000'', ''33792999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33810000'', ''33849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33870000'', ''33894999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''33910000'', ''33939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''34010000'', ''34069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''34110000'', ''34119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''34210000'', ''34219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''34330000'', ''34339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''34440000'', ''34449999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''34520000'', ''34599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''34610000'', ''34699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''34710000'', ''34799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''34810000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''34910000'', ''34999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''35010000'', ''35019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''35170000'', ''35179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''35210000'', ''35219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''35330000'', ''35339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''35350000'', ''35359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''36210000'', ''36219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''37710000'', ''37719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''38770000'', ''38799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''39210000'', ''39249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''40010000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''40110000'', ''40129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''40620000'', ''40629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''41010000'', ''41099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''41110000'', ''41198999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''45010000'', ''45019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''62010000'', ''62019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''78110000'', ''78149999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''81000000'', ''82179999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''84000000'', ''84409999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''85000000'', ''89999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''91000000'', ''92889999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''94010000'', ''94049999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''94440000'', ''94449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''96000000'', ''98059999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Fortaleza''               ), ''85'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''21060000'', ''21079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''30110000'', ''30128999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''30710000'', ''30719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''30810000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''31000000'', ''31009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''31020000'', ''31029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''31120000'', ''31129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''31220000'', ''31229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''31330000'', ''31339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''31810000'', ''31849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''31940000'', ''31949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''32020000'', ''32029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''32110000'', ''32691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''32710000'', ''32891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''32910000'', ''32991999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33010000'', ''33069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33150000'', ''33159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33170000'', ''33179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33210000'', ''33239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33260000'', ''33279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33310000'', ''33362999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33400000'', ''33409999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33430000'', ''33439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33450000'', ''33471999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33600000'', ''33601999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33620000'', ''33639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33660000'', ''33679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33690000'', ''33698999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33820000'', ''33838999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33850000'', ''33851999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33930000'', ''33939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''33980000'', ''33989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''34210000'', ''34219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''35170000'', ''35179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''41000000'', ''41073999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''44000000'', ''44007227'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''81000000'', ''81769999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''88610000'', ''88699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''88710000'', ''88799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''88810000'', ''88899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''88910000'', ''88979999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''94000000'', ''95769999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''98000000'', ''98359999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''98380000'', ''98409999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Teresina''                ), ''86'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''21010000'', ''21019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''30150000'', ''30153999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''30310000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''30960000'', ''30969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''31110000'', ''31119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''31330000'', ''31349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''32010000'', ''32049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''32080000'', ''32087999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''32110000'', ''32119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''32210000'', ''32219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''33210000'', ''33229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''34010000'', ''34019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''34110000'', ''34119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''34210000'', ''34219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''34850000'', ''34859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''37610000'', ''37659999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''37690000'', ''37691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''37710000'', ''37799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''37810000'', ''37891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''37910000'', ''37993999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''38010000'', ''38171999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''38210000'', ''38229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''38240000'', ''38899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''38910000'', ''38981999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''39210000'', ''39262999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''39290000'', ''39294999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''39310000'', ''39332999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''39350000'', ''39354999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''39370000'', ''39392999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''39420000'', ''39491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''39510000'', ''39533999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''39610000'', ''39693999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''39830000'', ''39839999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''39850000'', ''39895999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''39910000'', ''39912999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''41010000'', ''41029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''41040000'', ''41054999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''44000000'', ''44007601'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''81000000'', ''81449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''88610000'', ''88699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''88710000'', ''88789999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''91000000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''92430000'', ''92439999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''92530000'', ''92539999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''96000000'', ''96709999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''96760000'', ''96839999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''99000000'', ''99769999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''99880000'', ''99889999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Petrolina''               ), ''87'', ''99910000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''20210000'', ''20219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''21010000'', ''21019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''30850000'', ''30859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''31000000'', ''31005999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''31020000'', ''31029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''31110000'', ''31129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''31180000'', ''31188999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''32110000'', ''32129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''32210000'', ''32219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''33010000'', ''33059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''33160000'', ''33179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''33210000'', ''33229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''34000000'', ''34023999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''34040000'', ''34044999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''34060000'', ''34295999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''34310000'', ''34394999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''34410000'', ''34499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''34510000'', ''34513999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''34810000'', ''34829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''35010000'', ''35033999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''35100000'', ''35193999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''35210000'', ''35273999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''35290000'', ''35338999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''35350000'', ''35392999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''35410000'', ''35492999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''35510000'', ''35593999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''35610000'', ''35694999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''35710000'', ''35729999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''35740000'', ''35763999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''35780000'', ''35794999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''35810000'', ''35879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36010000'', ''36042999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36110000'', ''36119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36130000'', ''36177999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36190000'', ''36194999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36210000'', ''36219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36230000'', ''36619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36630000'', ''36655999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36670000'', ''36694999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36710000'', ''36759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36770000'', ''36779999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36830000'', ''36863999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36910000'', ''36929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''36950000'', ''36999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''37210000'', ''37219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''41000000'', ''41059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''44000000'', ''44007605'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''81000000'', ''81429999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''88610000'', ''88699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''88710000'', ''88799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''88810000'', ''88859999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''92000000'', ''93349999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''94000000'', ''94999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''96000000'', ''97559999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''97610000'', ''97929999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''97940000'', ''97949999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Juazeiro do Norte''       ), ''88'', ''99000000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''30150000'', ''30159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''33210000'', ''33219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''34150000'', ''34159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''34210000'', ''34298999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''34310000'', ''34599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''34610000'', ''34691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''34710000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''34910000'', ''34999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''35150000'', ''35159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''35210000'', ''35231700'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''35270000'', ''35299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''35310000'', ''35399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''35410000'', ''35929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''40020000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''41010000'', ''41012999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''44000000'', ''44007609'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''81000000'', ''81369999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''88210000'', ''88219999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''94000000'', ''94629999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''99000000'', ''99419999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''99710000'', ''99799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''99810000'', ''99889999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Picos''                   ), ''89'', ''99970000'', ''99979999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''20210000'', ''20219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''21010000'', ''21039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''21410000'', ''21419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''21510000'', ''21519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''30070000'', ''30079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''30110000'', ''30111999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''30150000'', ''30159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''30190000'', ''30195999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''30310000'', ''30339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''30350000'', ''30369999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''30380000'', ''30399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''30710000'', ''30759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''30810000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''31000000'', ''31079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''31100000'', ''31109999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''31120000'', ''31125999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''31140000'', ''31159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''31810000'', ''31849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''31940000'', ''31944999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''32010000'', ''32059999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''32070000'', ''32079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''32100000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''32210000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''32410000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''32610000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''32710000'', ''32899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''32910000'', ''32929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''32950000'', ''32959999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''32970000'', ''32999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''33110000'', ''33129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''33210000'', ''33239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''33250000'', ''33269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''33420000'', ''33499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''33510000'', ''33559999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''33660000'', ''33669999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''33970000'', ''33979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34110000'', ''34129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34230000'', ''34235999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34250000'', ''34259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34290000'', ''34291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34340000'', ''34344999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34410000'', ''34491999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34560000'', ''34569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34610000'', ''34629999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34640000'', ''34649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34660000'', ''34691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34810000'', ''34851999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34930000'', ''34941999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''34960000'', ''34976999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''35210000'', ''35219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''35270000'', ''35279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''35560000'', ''35569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''35640000'', ''35649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36010000'', ''36014999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36040000'', ''36082999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36140000'', ''36184999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36210000'', ''36234999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36250000'', ''36253999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36330000'', ''36343999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36360000'', ''36392999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36420000'', ''36422999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36460000'', ''36472999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36560000'', ''36563999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36580000'', ''36582999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36610000'', ''36621999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36650000'', ''36653999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36670000'', ''36672999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36890000'', ''36891999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36920000'', ''36921999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36940000'', ''36943999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''36970000'', ''36971999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37000000'', ''37009999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37110000'', ''37123999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37210000'', ''37299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37310000'', ''37347999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37380000'', ''37392999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37410000'', ''37412999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37440000'', ''37446999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37460000'', ''37461999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37480000'', ''37483039'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37510000'', ''37561999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37580000'', ''37596019'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37640000'', ''37651999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37670000'', ''37671999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37710000'', ''37771999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37810000'', ''37814999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37830000'', ''37842999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37880000'', ''37889019'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37910000'', ''37928019'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37950000'', ''37961999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''37980000'', ''37981999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''38010000'', ''38094999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''38110000'', ''38193999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''38210000'', ''38295999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''38310000'', ''38393999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''38410000'', ''38452999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''38470000'', ''38493999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''38510000'', ''38593999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''38610000'', ''38671999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''38690000'', ''38693999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''38710000'', ''38764999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''40010000'', ''40069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''40080000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''40420000'', ''40429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''41000000'', ''41092999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''44000000'', ''44007715'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''74000000'', ''74009999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''80100000'', ''85279999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''87010000'', ''87099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''87110000'', ''87199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''87210000'', ''87299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''87310000'', ''87399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''87410000'', ''87499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''87510000'', ''87549999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''87560000'', ''87599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''87610000'', ''87699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''87710000'', ''87719999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''88000000'', ''89349999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''91000000'', ''93859999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''96010000'', ''96099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''96110000'', ''96199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''96210000'', ''96299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''96310000'', ''96399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''96410000'', ''96429999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''99010000'', ''99089999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''99120000'', ''99199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''99210000'', ''99269999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''99330000'', ''99339999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''99400000'', ''99449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''99490000'', ''99499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''99600000'', ''99699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''99710000'', ''99719999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''99750000'', ''99754999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''99770000'', ''99899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Belém''                    ), ''91'', ''99910000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''20140000'', ''20149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''21010000'', ''21019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''21210000'', ''21219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''21230000'', ''21239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''21250000'', ''21279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''21290000'', ''21299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''30110000'', ''30126999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''30150000'', ''30159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''30710000'', ''30719999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''30810000'', ''30889999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''30900000'', ''30909999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''31010000'', ''31011999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''31120000'', ''31129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''31330000'', ''31339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''31820000'', ''31869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''31940000'', ''31943999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''32050000'', ''32056999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''32110000'', ''32169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''32210000'', ''32219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''32230000'', ''32239999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''32280000'', ''32289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''32310000'', ''32349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''32360000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''32450000'', ''32499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''32510000'', ''32512999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''32930000'', ''32984999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''33010000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''33110000'', ''33131999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''33160000'', ''33182999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''33210000'', ''33261999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''33280000'', ''33289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''33420000'', ''33499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''33510000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''33610000'', ''33692999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''33710000'', ''33781999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''33810000'', ''33821999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''33960000'', ''33969999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''35120000'', ''35141999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''35210000'', ''35251999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''35270000'', ''35291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''35310000'', ''35351999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''35370000'', ''35391999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''35420000'', ''35481999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''35710000'', ''35731999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''35750000'', ''35752999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''35810000'', ''35849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''36110000'', ''36189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''36210000'', ''36259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''36270000'', ''36279999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''36290000'', ''36299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''36310000'', ''36399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''36410000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''36510000'', ''36595999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''36630000'', ''36649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''36670000'', ''36679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''36710000'', ''36739999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''36750000'', ''36759999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''36810000'', ''36829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''38770000'', ''38789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''40400000'', ''40404999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''41010000'', ''41049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''44000000'', ''44007695'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''62010000'', ''62019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''62020000'', ''69999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''81000000'', ''82799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''82810000'', ''82819999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''82830000'', ''82849999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''84000000'', ''84519999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''88110000'', ''88199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''88210000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''88610000'', ''88699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''88710000'', ''88729999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''91000000'', ''95359999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''96010000'', ''96099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''96120000'', ''96199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''96210000'', ''96279999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''96310000'', ''96319999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''99010000'', ''99099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''99110000'', ''99139999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''99330000'', ''99339999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''99440000'', ''99449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''99510000'', ''99519999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''99610000'', ''99699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''99710000'', ''99789999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''99800000'', ''99899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''99910000'', ''99919999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Manaus''                   ), ''92'', ''99940000'', ''99999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''30140000'', ''30169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''30380000'', ''30389999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''30610000'', ''30679999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''31850000'', ''31859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''32210000'', ''32229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35020000'', ''35061999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35080000'', ''35081999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35120000'', ''35159999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35170000'', ''35189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35210000'', ''35247999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35260000'', ''35292999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35310000'', ''35341999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35360000'', ''35393999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35410000'', ''35445999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35470000'', ''35473999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35490000'', ''35499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35510000'', ''35534999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35570000'', ''35591999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35630000'', ''35664999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35690000'', ''35698999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35740000'', ''35745999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35760000'', ''35764999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35790000'', ''35793999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35820000'', ''35849999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35880000'', ''35893999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35920000'', ''35939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''35960000'', ''35984999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''36030000'', ''36039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''36450000'', ''36451999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''37350000'', ''37372999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''37930000'', ''37931999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''44000000'', ''44007698'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''81000000'', ''81319999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''81330000'', ''81349999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''84010000'', ''84099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''84110000'', ''84169999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''88110000'', ''88179999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''91000000'', ''92329999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''96510000'', ''96599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''99010000'', ''99049999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''99080000'', ''99089999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''99330000'', ''99339999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''99510000'', ''99529999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''99540000'', ''99549999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''99700000'', ''99703999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Santarém''                 ), ''93'', ''99730000'', ''99793999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''21010000'', ''21069999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''30120000'', ''30122999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''30140000'', ''30179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''32210000'', ''32229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''32910000'', ''32914999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33010000'', ''33075999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33090000'', ''33099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33120000'', ''33129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33140000'', ''33153999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33180000'', ''33194999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33210000'', ''33249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33260000'', ''33289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33310000'', ''33331999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33350000'', ''33359999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33370000'', ''33371999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33410000'', ''33421999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33440000'', ''33482999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33510000'', ''33585999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33620000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33790000'', ''33793999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33820000'', ''33832999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33850000'', ''33863999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''33910000'', ''33924999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''34210000'', ''34222999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''34240000'', ''34249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''34260000'', ''34282999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''34310000'', ''34354999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''34910000'', ''34914999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''37780000'', ''37791999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''37850000'', ''37879999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''38460000'', ''38465999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''44000000'', ''44007702'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''81000000'', ''81869999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''84000000'', ''84149999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''88110000'', ''88179999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''91000000'', ''92939999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''96610000'', ''96689999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''99010000'', ''99019999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''99030000'', ''99049999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''99080000'', ''99099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''99330000'', ''99349999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''99440000'', ''99449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''99530000'', ''99539999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''99550000'', ''99559999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''99690000'', ''99701999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''99720000'', ''99759999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''99770000'', ''99771999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Marabá''                   ), ''94'', ''99790000'', ''99796999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''21210000'', ''21219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''30150000'', ''30169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''30810000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''31120000'', ''31125999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''31310000'', ''31311999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''31810000'', ''31819999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''31940000'', ''31949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''32110000'', ''32139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''32150000'', ''32151999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''32240000'', ''32249999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''32350000'', ''32361999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''32380000'', ''32383999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''32620000'', ''32632999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''33980000'', ''33989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''35300000'', ''35341999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''35370000'', ''35373999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''35390000'', ''35391999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''35420000'', ''35432999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''35520000'', ''35532999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''35640000'', ''35641999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''35910000'', ''35932999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''36210000'', ''36218999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''36230000'', ''36289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''36910000'', ''36911999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''41010000'', ''41012999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''44000000'', ''44007610'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''81000000'', ''81279999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''81290000'', ''81299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''84000000'', ''84129999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''88010000'', ''88059999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''91110000'', ''91199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''91210000'', ''91299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''91310000'', ''91399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''91410000'', ''91499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''91510000'', ''91599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''91610000'', ''91749999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''99010000'', ''99059999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''99330000'', ''99339999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''99590000'', ''99599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''99610000'', ''99659999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''99670000'', ''99679999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''99700000'', ''99729999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''99740000'', ''99749999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''99760000'', ''99779999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Boa Vista''                ), ''95'', ''99810000'', ''99819999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''21010000'', ''21019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''30810000'', ''30869999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''31120000'', ''31129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''31150000'', ''31169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''31310000'', ''31312999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''31940000'', ''31949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''31980000'', ''31989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''32000000'', ''32019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''32030000'', ''32039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''32120000'', ''32179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''32210000'', ''32259999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''32270000'', ''32273999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''32290000'', ''32292999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''32320000'', ''32344999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''32410000'', ''32441999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''32510000'', ''32519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''32610000'', ''32612999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''32710000'', ''32721999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''32810000'', ''32841999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''33110000'', ''33141999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''33210000'', ''33281999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''33320000'', ''33323999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''33970000'', ''33979999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''34210000'', ''34271999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''35210000'', ''35231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''36210000'', ''36229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''41010000'', ''41041999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''44000000'', ''44007204'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''81000000'', ''81459999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''84000000'', ''84169999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''88010000'', ''88099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''88110000'', ''88149999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''91000000'', ''91799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''91810000'', ''91999999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''99010000'', ''99099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''99110000'', ''99189999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''99330000'', ''99339999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''99610000'', ''99689999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''99700000'', ''99769999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Macapá''                   ), ''96'', ''99810000'', ''99819999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''32930000'', ''32989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33030000'', ''33049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33210000'', ''33212999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33310000'', ''33312999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33340000'', ''33342999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33430000'', ''33439999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33450000'', ''33471999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33510000'', ''33533999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33560000'', ''33564999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33730000'', ''33734999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33790000'', ''33791999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33850000'', ''33859999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33890000'', ''33892999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''33910000'', ''33931999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34110000'', ''34131999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34150000'', ''34181999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34220000'', ''34231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34250000'', ''34291999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34310000'', ''34321999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34340000'', ''34351999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34410000'', ''34411999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34510000'', ''34519999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34530000'', ''34536999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34570000'', ''34581999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34610000'', ''34691999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34710000'', ''34715999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34730000'', ''34731999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34750000'', ''34771999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34810000'', ''34851999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34870000'', ''34871999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''34910000'', ''34914999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''35610000'', ''35619999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''44000000'', ''44007702'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''81000000'', ''81249999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''81260000'', ''81279999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''84000000'', ''84119999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''88010000'', ''88089999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''91450000'', ''91599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''91610000'', ''91699999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''91710000'', ''91799999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''91810000'', ''91899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''91910000'', ''91959999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''96110000'', ''96139999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''99010000'', ''99039999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''99330000'', ''99339999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''99530000'', ''99539999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''99570000'', ''99599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''N - Coari''                    ), ''97'', ''99780000'', ''99793999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''20160000'', ''20169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''21060000'', ''21099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''30150000'', ''30168999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''30810000'', ''30899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''31000000'', ''31014999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''31120000'', ''31129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''31310000'', ''31319999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''31330000'', ''31339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''31810000'', ''31829999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''31940000'', ''31949999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''31980000'', ''31999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''32010000'', ''32029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''32110000'', ''32199999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''32210000'', ''32299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''32310000'', ''32399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''32410000'', ''32499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''32510000'', ''32599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''32610000'', ''32699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''32710000'', ''32799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''32980000'', ''32989999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''33010000'', ''33049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''33110000'', ''33139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''33210000'', ''33289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''33340000'', ''33349999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''33370000'', ''33379999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''33440000'', ''33469999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''33490000'', ''33499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''33510000'', ''33599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''33610000'', ''33699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''33710000'', ''33789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''33810000'', ''33899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''33910000'', ''33999999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''34010000'', ''34049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''34060000'', ''34079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''34510000'', ''34569999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''34610000'', ''34699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''34710000'', ''34799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''34810000'', ''34899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''36440000'', ''36448999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''36510000'', ''36599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''36610000'', ''36612999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''36630000'', ''36649999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''36710000'', ''36799999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''36810000'', ''36899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''37170000'', ''37179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''38770000'', ''38789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''40090000'', ''40099999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''41000000'', ''41081999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''44000000'', ''44007680'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''81000000'', ''82969999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''84000000'', ''85089999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''86120000'', ''86129999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''87000000'', ''87589999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''87660000'', ''87899999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''87910000'', ''87919999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''88000000'', ''89349999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''91000000'', ''92169999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''96010000'', ''96099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''96110000'', ''96199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''96210000'', ''96219999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''99010000'', ''99099999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''99110000'', ''99139999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''99330000'', ''99349999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''99440000'', ''99449999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''99610000'', ''99769999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''99810000'', ''99859999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''99880000'', ''99889999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - São Luís''                ), ''98'', ''99910000'', ''99959999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''20170000'', ''20179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''21010000'', ''21029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''21220000'', ''21229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''21320000'', ''21339999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''21410000'', ''21429999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''23230000'', ''23231999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''30030000'', ''30049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''30150000'', ''30169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''30710000'', ''30769999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''30780000'', ''30789999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''31000000'', ''31004999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''31020000'', ''31039999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''31110000'', ''31119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''31130000'', ''31139999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''31160000'', ''31189999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''32120000'', ''32129999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''32160000'', ''32169999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''32210000'', ''32219999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''32620000'', ''32633054'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''33010000'', ''33019999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''33110000'', ''33119999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''33170000'', ''33179999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''33210000'', ''33229999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''33260000'', ''33269999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''33280000'', ''33289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''34040000'', ''34049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''34210000'', ''34289999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''34660000'', ''34661999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''34910000'', ''34939999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''35210000'', ''35299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''35310000'', ''35399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''35410000'', ''35489999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''35510000'', ''35599999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''35610000'', ''35699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''35710000'', ''35798999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''35810000'', ''35899999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''35910000'', ''35929999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''35940000'', ''35942999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''36010000'', ''36079999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''36110000'', ''36149999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''36210000'', ''36299999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''36310000'', ''36399999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''36410000'', ''36499999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''36540000'', ''36549999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''36610000'', ''36639999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''36650000'', ''36699999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''40010000'', ''40049999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''40200000'', ''40209999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''41000000'', ''41029999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''41410000'', ''41419999'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''44000000'', ''44007669'',''Fijo'', ''Fijo'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''81000000'', ''82199999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''82210000'', ''82219999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''82850000'', ''82859999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''84000000'', ''84389999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''88000000'', ''88299999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''88310000'', ''88399999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''88410000'', ''88499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''88510000'', ''88599999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''91000000'', ''92189999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''96310000'', ''96319999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''96410000'', ''96479999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''96490000'', ''96499999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''96510000'', ''96519999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''99010000'', ''99059999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''99330000'', ''99359999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''99510000'', ''99559999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''99700000'', ''99709999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''99770000'', ''99799499'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''99840000'', ''99879999'',''Movil'', ''CPP'')
insert into seriesBR values (rtrim (  ''NE - Imperatriz''              ), ''99'', ''99890000'', ''99899999'',''Movil'', ''CPP'')'
					
	EXEC(@Sql)
	
		set @process = 'fnIsDayLight - Create Function'
		set @Sql='CREATE FUNCTION [dbo].[fnIsDayLight](@country_id int, @date DATETIME)
RETURNS BIT
AS
BEGIN
	if exists (
		select * 
		from ccHorarioVerano
		where @date between inicio and fin
		and year(@date) = year(inicio) 
		and year(@date) = year(fin) 
		and country_id = @country_id)
	begin
		RETURN 1
	end

	if exists (
		select * 
		from ccHorarioVerano 
		where @date between inicio and fin
		and year(@date) > year(inicio) 
		and year(@date) = year(fin)
		and country_id = @country_id)
	begin
		RETURN 1
	end

	if exists (
		select * 
		from ccHorarioVerano 
		where @date between inicio and fin
		and year(@date) = year(inicio) 
		and year(@date) < year(fin)
		and country_id = @country_id)
	begin
		RETURN 1
	end
	
	RETURN 0
END'
	
	EXEC(@Sql)
	
		set @process = 'fnGetTimeZone - Alter Function'
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
			( len(@phone) = 7 and @lada = area and len(area) = 3 )
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
	
	if @country = 10 begin
		select @phone = dbo.Completa(@phone)
		-- 8 <= len(@phone) <= 19
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
			where id_country = @country and (
			((len(@phone) between  8 and  9)                                      and                   @lada = area) or
			((len(@phone) between 10 and 11)                                      and substring(@phone, 1, 2) = area) or
			((len(@phone) between 12 and 13) and substring(@phone, 1, 4) = ''9090'' and                   @lada = area) or
			((len(@phone)       = 13       )                                      and substring(@phone, 4, 2) = area) or
			((len(@phone) between 14 and 15) and substring(@phone, 1, 2) = ''90''   and substring(@phone, 5, 2) = area) or
			((len(@phone)       = 14       ) and substring(@phone, 1, 1) = ''0''    and substring(@phone, 4, 2) = area))
		end
	end

	return isNull(@timeZone,0)
 END'
	
	EXEC(@Sql)
	
		set @process = 'TelAni - Alter Function'
		set @Sql = 'ALTER function [dbo].[TelAni](@tel varchar(32), @lista smallint)
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

	return @ret
END'
			
	EXEC(@Sql)
	
		set @process = 'Completa - Alter Function'
		set @Sql = 'ALTER function [dbo].[Completa](@Cadena varchar(32))
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


if @pais = 10 --Brasil
begin
				
	select @resultado = case len(@resultado)
--llamada local fijo o celular	
	when 8 then @resultado 
    when 9 then @resultado 	
	when 10 then  -- Numero nacional
		case when left(@resultado, 2) = @ld 
			then right(@resultado,8) else @resultado end
	when 11 then	-- Este caso solomente es para numero celular
			case when left(@resultado, 2) = @ld
				 then right(@resultado,9) else @resultado end		
	when 12 then	-- llamadas por cobrar local
		case when (left(@resultado,4) = ''9090'') then right(@resultado,8) else ''E_NV_PC'' end
	when 13 then 
		case when left(@resultado,4) = ''9090'' then right(@resultado,9) -- llamadas por cobrar local celular	
			 when left(@resultado,1) = ''0'' then 				
			case when substring(@resultado,4,2)=@ld then right(@resultado,8) else right(@resultado,10) end -- llamadas de LDN
		else ''E_NV_Longitud'' end
	when 14 then
			case when left(@resultado,2) = ''90'' then -- llamadas por cobrar larga distancia
					case when substring(@resultado,5,2) = @ld then right(@resultado,8) else right(@resultado,11) end			     
				 when left(@resultado,1) = ''0''  then --llamada larga distancia a celular					
						case when substring(@resultado,4,2)= @ld then right(@resultado,9) else right(@resultado,11) end				
			else ''E_NV_Longitud'' end
	when 15 then 
		case when left(@resultado,2) = ''90'' then -- Llamadas por cobrar a celular LD
				case when substring(@resultado,5,2)=@ld then right(@resultado,9) else right(@resultado,11) end			
			else ''E_NV_Longitud'' end	

	else ''E_NV_Longitud'' end

end


-- Termina
return @resultado

end'
	
	EXEC(@Sql)
	
		set @process = 'Completa_ListaNegra - Alter Function'
		set @Sql = 'ALTER FUNCTION [dbo].[Completa_ListaNegra] (@Cadena varchar(30))
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


	-- Brasil
	if @pais = 10 and left(@resultado,1) <> ''E''
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
		
		set @process = 'Verifica - Alter Function'
		set @Sql = 'ALTER FUNCTION [dbo].[Verifica](@tel varchar(32))
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
			goto BuscaLada
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

	if @pais= 10
		begin -- Inicia Brasil
			select @tel = dbo.completa(@tel)
			select @lon = len(@tel)
			if left(@tel,1) <> ''E'' 
				begin
					if @lon in (8,9) begin --numero local
						if exists(
						select Regiones 
							from seriesBR where 
								convert(int,AreaCode) = convert(int,@cldLocal) and
								convert(int,@tel) between convert(int,SerieInicio) and convert(int,SerieFin)
						)
						begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end
					if @lon in (10,11) begin --numero nacional
						if exists(
						select Regiones 
							from seriesBR where 
								convert(int,AreaCode) = convert(int,left(@tel,2)) and
								convert(int,right(@tel, @lon-2)) between convert(int,SerieInicio) and convert(int,SerieFin)
						)
						begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end										
				end

			else begin
				return @tel
			end
		end -- Termina Brasil

	return @tel
 end'
			
	EXEC(@Sql)
	
		set @process = 'ccsp_INInsertaCallBack - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_INInsertaCallBack]
@cal_key varchar(20) =''b'',
@cam_id smallint,
@cal_telefono varchar(19),
@fechadial varchar(17),
@dato1 varchar(255),
@dato2 varchar(255),
@dato3 varchar(255),
@dato4 varchar(255),
@dato5 varchar(255),
@TelReprograma smallint = -1,
@user_id int=0
AS
set nocount on
declare @TelOriginal as varchar(15)
declare @FechaOriginal as datetime

if len(@cal_telefono)<=3
	return(0)

if isnull(@cal_key,'''') = ''''
 begin
      -- Generamos cal_key aleatorio para casos de reprogramacion inbound --
      Genera_cal_key:
      select @cal_key = right(newID(), 10)
      if exists (select cal_key from ccoCallsOutSource where cal_key=@cal_key)
            goto Genera_cal_key
 end

declare @bIsDaylight as bit
declare @idioma as int
declare @country_id as varchar(3)

select @country_id = valor from ccsettings where setting_id = 104

select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

declare @difference as int
select @difference = isNull(dbo.fnGetTimeDifference(dbo.fnGetTimeZone(@cal_telefono,@bIsDaylight)),0)
declare @Fecha smalldatetime, @callout_id int, @iZonaHoraria int,@iZonaHoraria_verano int, @cal_statusTemp tinyint
select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))

if exists(select cal_Key, cam_id from ccoCallsOutSource where cal_Key = @cal_key and cam_id =@cam_id)
 begin
	select @callout_id=callout_id,@cal_statusTemp =cal_status,@iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano, @TelOriginal = cal_telefono, @FechaOriginal = cal_fechadial from ccoCallsOutSource where cal_Key = @cal_key and cam_id = @cam_id
	update ccoCallsOutSource set cal_status = ''2'',cal_telefono=@cal_telefono where cal_key = @cal_key and cam_id = @cam_id

	if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
	else
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano)
		select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key,@iZonaHoraria,@iZonaHoraria_verano  

		insert ccoCallBacks values(@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
  end

else
 begin
	select @FechaOriginal = getdate()

	insert into ccoCallsOutSource (cal_key,cam_id,cal_telefono,cal_fechadial,Dato1,Dato2,Dato3,Dato4,Dato5,dial_tels,cal_status)
	values (@cal_key,@cam_id,@cal_telefono,@FechaOriginal,@dato1,@dato2,@dato3,@dato4,@dato5,cast(@TelReprograma as char(1))+ replace(''2345NNN'',cast(@TelReprograma as char(1)),''1''),''2'')

	select @TelOriginal = @cal_telefono

	select @callout_id = scope_identity()
	select @iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano from ccocallsoutsource where callout_id=@callout_id

	 if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
	 else
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano)
		select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key,@iZonaHoraria,@iZonaHoraria_verano

		insert ccoCallBacks values(@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
end

if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id)
	update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id
else
	insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@cam_id

return(0)
set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_ManualCallApplyTimeZoneRules - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_ManualCallApplyTimeZoneRules] @campid as int, @tel varchar(15) as

set nocount on

declare @bIsDaylight bit
declare @revHorario bit
declare @country_id int
declare @iZonas int
declare @Sql varchar(MAX)
declare @izonahoraria int
declare @izonahoraria_verano int

create table #TimeZone(
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
izonahoraria int,
izonahoraria_verano int
)

/*** Revisa zona horaria incluyendo de verano ***/
select @izonahoraria = dbo.fnGetTimeZone(@tel,0)
select @izonahoraria_verano = dbo.fnGetTimeZone(@tel,1)

insert into #TimeZone
values (@campid,@tel,@izonahoraria,@izonahoraria_verano)

/*** Valida el pais y la lada configurada ***/
SELECT @country_id = valor 
FROM ccSettings 
WHERE setting_id = 104

select @revHorario = valor 
from ccsettings 
where setting_id = 112

/*** Coloca el primer dia de la semana a Lunes ***/
SET DATEFIRST 1

/*** Se revisa si es horario de verano ***/
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

/*** Se revisa si la campaña tiene horarios configurados ***/
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
	begin
		declare @horaUniversal as datetime 
		select @horaUniversal = getutcdate()

		select @iZonas = sum(distinct tz_id)
		from (select tz_id,
			  datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora, 
			  datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
			  datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
			  from ccTimeZones )zonas 
			  inner join cchorarios on((hora > HoraInicio OR(hora = HoraInicio AND minuto >= MinInicio))
			  AND (hora < HoraFin OR(hora = HoraFin AND minuto <= MinFin))
			  AND (Lunes = dia or
				   Martes*2 = dia or
				   Miercoles*3 = dia or
				   Jueves*4 = dia or
				   Viernes*5 = dia or
				   Sabado*6 = dia or
				   domingo*7 = dia)
			 ) 
		inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id = ccCampsHorarios.horario_id 
		and ccCampsHorarios.cam_id = @campid

		if @iZonas is null 
			begin
				SELECT 0 as CanCall
				return
			end
	end 
else
	begin
		if @revHorario = 0
			begin
				select @iZonas = sum(distinct tz_id)from ccTimeZones
			end
		else
			begin
				select @iZonas = Null
			end
	end

set @Sql = ''CREATE TABLE #NEW_JOBS(
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS)

INSERT #NEW_JOBS
SELECT cam_id, '' + @tel + ''
FROM #TimeZone
WHERE cam_id = '' + cast(isnull(@CAMPID,''0'') as varchar(7)) + '' 
and (((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0))

if (SELECT count(*) FROM #NEW_JOBS where len(cal_telefono)>0) > 0 
	begin 
		select 1 as CanCall
	end
else
	begin
		select 0 as CanCall
	end

DROP table #NEW_JOBS''

exec(@Sql)

DROP table #TimeZone

set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_OUTGetNewJobs - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID as int,
@test as int=0,
@nAgentsLogin as int=1
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @Sql varchar(4000), @Order_Asc_Desc char(4)
declare @camSurvey int
select @camSurvey = 0

select @camSurvey = cam_id
from cccamps 
where cam_id = @CAMPID 
and isnull(callsBySurvey,0) > 0 
and isnull(ivrScript,0) > 0
 
-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')
 
SET DATEFIRST 1
--Checamos si es horario de verano
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
 
--Checamos si la campaña tiene horarios configurados
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
begin
       declare @horaUniversal as datetime
       set @horaUniversal=getutcdate()
 
       select @iZonas=sum(distinct tz_id)from
       (select tz_id,
             datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora,
             datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
             datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
             from ccTimeZones
       )zonas inner join cchorarios on
       ((hora>HoraInicio OR(hora=HoraInicio AND minuto>= MinInicio))
             AND (hora<HoraFin OR(hora=HoraFin AND minuto<= MinFin))
             AND (
                    Lunes=dia or
                    Martes*2=dia or
                    Miercoles*3=dia or
                    Jueves*4=dia or
                    Viernes*5=dia or
                    Sabado*6=dia or
                    domingo*7=dia
              )
       ) inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id=ccCampsHorarios.horario_id and ccCampsHorarios.cam_id=@campid
 
       if @iZonas is null begin
             SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
             return
       end
end
 
else
begin
	   if @camSurvey > 0
			begin
				SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
				return
			end

       if @revHorario=0
             select @iZonas=sum(distinct tz_id)from ccTimeZones -- No hay horarios, ponemos todas las zonas
       else
             select @iZonas=Null
end
 
set @Sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
cal_status tinyint,
cal_fechaDial datetime,
user_id int,
 tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint
)''
 
-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94
 
if isnull(@topCount,0)=0
select @topCount=case when @nAgentsLogin<3 then 30
  when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
  when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
  when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
  when @nAgentsLogin>=16 then 240 else 20 end
 
select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
	   select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )
 
	   select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
	   SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
	   W.list_id, isNull(R.sequence,0) as sequence
	   FROM ccoWorkingTable W left join ccRIARegistryLists R on W.list_id = R.list_id
	   WHERE cal_status=1 -- CallBacks
	   and cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
	   and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
	   and (
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	   )
	   and isnull(R.status,2) = 2
	   order by prioridad_cb desc, cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
 
end -- TOMA EN CUENTA LOS CALLBACKS
 
if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
	   select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )
 
	   select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
	   SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
	   W.list_id, isNull(R.sequence,0) as sequence
	   FROM ccoWorkingTable W left join ccRIARegistryLists R on W.list_id = R.list_id
	   WHERE cal_status=0 -- Nuevas sin Tiempo
	   and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
	   and (
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	   )
	   and isnull(R.status,2) = 2
	   order by R.sequence, cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''
      
end -- TOMA EN CUENTA LAS NUEVAS
 
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @Sql=@Sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
 begin
	   select @Sql=@Sql+nchar(13)+ ''UPDATE ccoWorkingTable SET cal_status=2 --CALLBACK IN PROGRESS
	   WHERE callout_id in(select callout_id from #NEW_JOBS)''
end

if @Test = 2
begin
	select @Sql=@Sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
	declare @nSQL nvarchar(4000)
	set @nSQL=cast(@Sql as nvarchar(4000))
	exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
	return(@total)
end
else
begin
 
select @Sql=@Sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0''
end
 
select @Sql=@Sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print @Sql
exec(@Sql)
return(0)'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_OUTGetNewProviderJobs - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewProviderJobs]
@CAMPID as int, 
@test as int=0,
@nAgentsLogin as int=1
as
set nocount on
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @Sql varchar(MAX), @Order_Asc_Desc char(4)
declare @camSurvey int
select @camSurvey = 0

select @camSurvey = cam_id
from cccamps 
where cam_id = @CAMPID 
and isnull(callsBySurvey,0) > 0 
and isnull(ivrScript,0) > 0

-- VALIDAMOS EL PAIS Y LADA CONFIGURADA --
SELECT @country_id =valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano 
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

--Checamos si la campaña tiene horarios configurados
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
 begin
	declare @horaUniversal as datetime 
	set @horaUniversal=getutcdate()

	select @iZonas=sum(distinct tz_id)from 
	(select tz_id,
		datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora, 
		datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
		datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
		from ccTimeZones 
	)zonas inner join cchorarios on
	((hora>HoraInicio OR(hora=HoraInicio AND minuto>= MinInicio))
		AND (hora<HoraFin OR(hora=HoraFin AND minuto<= MinFin))
		AND (
			Lunes=dia or
			Martes*2=dia or
			Miercoles*3=dia or
			Jueves*4=dia or
			Viernes*5=dia or
			Sabado*6=dia or
			domingo*7=dia
		)
	) inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id=ccCampsHorarios.horario_id and ccCampsHorarios.cam_id=@campid

	if @iZonas is null begin
		SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
		return
	end
 end 

else
begin
	if @camSurvey > 0
		begin
			SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
			return	
		end

	if @revHorario=0
		select @iZonas=sum(distinct tz_id)from ccTimeZones -- No hay horarios, ponemos todas las zonas
	else
		select @iZonas=Null
end

set @Sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
 cam_id int,
 cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
 cal_status tinyint,
 cal_fechaDial datetime,
 user_id int, 
 tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
tel varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel2 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel3 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel4 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel5 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
dialOrder varchar(10),
list_id int,
sequence smallint
)''

-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
 select @topCount=case when @nAgentsLogin<3 then 30
  when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
  when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
  when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
  when @nAgentsLogin>=16 then 240 else 20 end

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
 begin
	select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

	select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isnull(R.sequence,0) as sequence
	FROM ccoWorkingTable W left join ccRIARegistryLists R 
	on W.list_id = R.list_id 
	left join ccocallsoutsource couts    
	on W.callout_id = couts.callout_id 
	WHERE W.cal_status=1 -- CallBacks
	and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
	and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + '' 
	and (
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by W.prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
 end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
 begin
	select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

	select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id, 
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isNull(R.sequence,0) as sequence
	FROM ccoWorkingTable W left join ccRIARegistryLists R 
	on W.list_id = R.list_id 
	left join ccocallsoutsource couts    
	on W.callout_id = couts.callout_id 
	WHERE W.cal_status=0 -- Nuevas sin Tiempo
	and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + '' 
	and (
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', W.callout_id''
	
 end -- TOMA EN CUENTA LAS NUEVAS

----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @Sql=@Sql+nchar(13)+ ''SET rowcount 0''
if @Test=0 
 begin
	select @Sql=@Sql+nchar(13)+ ''UPDATE ccoWorkingTable SET cal_status=2 --CALLBACK IN PROGRESS
	WHERE callout_id in(select callout_id from #NEW_JOBS)''
 end

select @Sql=@Sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, 
user_id, tz, tz2, tz3, tz4, tz5, tel, tel2, tel3, tel4, tel5, dialOrder, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0''

select @Sql=@Sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print @Sql
exec(@Sql)
return(0)'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_OUTInsertaCallBack - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_OUTInsertaCallBack]
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
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
 
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
	
		set @process = 'ccspADM_AniListLD - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspADM_AniListLD]
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
case @pais	when 1  then ''estado, cld as area '' 
			when 2  then ''estado, cld as area ''
			when 3  then ''municipio as estado, region +''''+ serie as area ''
			when 4  then ''location as estado, area ''
			when 5  then ''cld as estado, cld as area ''
			when 6  then ''region as estado, LD as area ''
			when 7  then ''region as estado, CLD as area ''
			when 8  then ''Regiones as estado, cld +''''-''''+ [serie inicio] as area ''
			when 9  then ''Regiones as estado, LD + AreaCode as area ''
			when 10 then ''Regiones as estado, AreaCode as area ''
			else '''' end
when 4 then
case @pais	when 1  then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani '' 
			when 2  then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 3  then ''municipio as estado, region +''''+ serie as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 4  then ''location as estado, area, @id_anilist as id_anilist, '''''''' as telani ''
			when 5  then ''cld as estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 6  then ''region as estado, LD as area, @id_anilist as id_anilist, '''''''' as telani '' 
			when 7  then ''region as estado, CLD as area, @id_anilist as id_anilist, '''''''' as telani''
			when 8  then ''Regiones as estado, cld +''''-''''+ [serie inicio] as area, @id_anilist as id_anilist, '''''''' as telani '' 
			when 9  then ''Regiones as estado, LD + AreaCode as area, @id_anilist as id_anilist, '''''''' as telani '' 
			when 10 then ''Regiones as estado, AreaCode as area, @id_anilist as id_anilist, '''''''' as telani '' 
			else '''' end end + ''from '' +
case @pais	when 1  then ''series'' 
			when 2  then ''seriesarg where estado <> '''' order by 1'' 
			when 3  then ''seriescol'' 
			when 4  then ''ccTimeZoneArea where id_country = '' + convert(varchar(5),@pais) + '''' 
			when 5  then ''serieschi''
			when 6  then ''SeriesVen''
			when 7  then ''SeriesUK''
			when 8  then ''SeriesSA'' 
			when 9  then ''SeriesAU''
			when 10 then ''SeriesBR''
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
	
		set @process = 'ccsp_InsertDNCList - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
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
where cs.cal_telefono = @tel or cs.cal_telefono = right(@tel, 10) or cs.cal_telefono = right(@tel, 11)
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
where cs.cal_telefono2 = @tel or cs.cal_telefono2 = right(@tel, 10) or cs.cal_telefono2 = right(@tel, 11)
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
where cs.cal_telefono3 = @tel or cs.cal_telefono3 = right(@tel, 10) or cs.cal_telefono3 = right(@tel, 11)
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
end
	----------------------------------------------------------------------------------- -telefono 4

	insert #mytemp
	select callout_id,cal_telefono4,cam_id,''3'',@ln_id as idtipolista 
	from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cs.cal_telefono4 = @tel or cs.cal_telefono4 = right(@tel, 10) or cs.cal_telefono4 = right(@tel, 11)
	and cal_fechadial > getdate()-30

if (select count(*) from #mytemp) > 0
begin
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
where cs.cal_telefono5 = @tel or cs.cal_telefono5 = right(@tel, 10) or cs.cal_telefono5 = right(@tel, 11)
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
	
		set @process = 'ccsp_Limpia - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_Limpia]
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

if @pais = 10 -- Brasil
begin
	select @telTemp = @tel
	select @tel = dbo.Completa_ListaNegra(@tel)
	set @lon = len(@tel)	
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
							select 2 as res, @telTemp as tel --digitos incorrectos
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
	
		set @process = 'ccsp_RIAAgentGetDialMask - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
@user_id integer,
@tel varchar(15)
AS
declare @mask integer, @idioma integer, @value integer, @lada integer
declare @country as tinyint

set @value = 0
select @mask = isnull(dialmask,7) from ccusers where user_id=@user_id
select @country = valor from ccsettings where setting_id = 104

-- Restricciones por pais 1:Mexico 2:Argentina 3:Colombia 4:USA 5:Chile 6:Venezuela 7:uk 8:Arabia Saudita, 9: Australia, 10:Brasil
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

--Brasil
if @country = 10
	begin
		declare @lon int
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			set @lon=len(@tel)						
			if  
				(@lon in(7,8) and left(@tel,1) in (''6'',''7'',''8'',''9'') ) 
				or (@lon=9 and left(@tel,1) = ''9'' ) 
				or (@lon=10 and substring(@tel,3,1) in (''6'',''7'',''8'',''9'') ) 
				or (@lon=11 and substring(@tel,3,1) = ''9'')
				--or (@lon=12 and substring(@tel,5,1) in (''6'',''7'',''8'',''9'') ) 
				--or (@lon=13 and substring(@tel,5,1) = ''9'' ) 
				--or (@lon=13 and substring(@tel,5,1) = ''9'' ) 
				begin					
					set @value = 4
				end	
		end

		--Restringe larga distancia
		if(@value=0)
		begin
			if ((@mask & 2) > 0)
		    begin
				select @lada=valor from ccSettings WHERE setting_id=17
				set @tel=ltrim(rtrim(@tel))
				set @lon=len(@tel)										
				if  @lon>=10 and left(@tel,2) <> @lada
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
				set @tel=ltrim(rtrim(@tel))
				set @lon=len(@tel)					
				if @lon in (7,8,9) or (@lon in (10,11) and left(@tel,2)= @lada)
				begin							
					set @value = 6
				end
			end
		end

		--Restringe por cobrar
		if(@value=0)
		begin
			declare @llamadasPorCobrar varchar(4);			
			select @llamadasPorCobrar= valor from ccSettings where setting_id=126
			set @tel=ltrim(rtrim(@tel))
			set @lon=len(@tel)					
			if @lon >= 12 and  left(@tel,2) = ''90'' and @llamadasPorCobrar=''0''													
			begin							
				set @value = 10 -- pone para llamadas por cobrar
			end	 		
		end

	end -- Termina Brasil

select @value'
	
	EXEC(@Sql)
	
		set @process = 'ccTimeZoneArea - Alter Table'
		set @Sql = 'ALTER table ccTimeZoneArea add call_record bit default (1)'
							
	EXEC(@Sql)
	
		set @process = 'ccTimeZoneArea - Update'
		set @Sql = 'update ccTimeZoneArea 
set call_record = 0
where area in (
209,213,310,323,408,415,510,530,559,562,619,626,650,661,707,714,760,805,818,831,858,909,916,925,949
,239,305,321,352,386,407,561,727,754,772,786,813,850,863,904,941,954
,217,309,312,618,630,708,773,815,847
,240,301,410,443
,339,413,508,617,774,781,978
,231,248,269,313,517,586,616,734,810,906,989	
,406
,702,775
,603
,215,267,412,484,570,610,717,724,814,878
,206,253,360,425,509
) and id_country = 4'
								
	EXEC(@Sql)

		set @process = 'ccCamps - Alter Table'
		set @Sql = 'ALTER table ccCamps add call_record tinyint not null default (1)'
							
	EXEC(@Sql)

		set @process = 'EnableCallRecord - Create Function'
		set @Sql = 'CREATE function [dbo].[EnableCallRecord](@call_record_cam tinyint,@pais tinyint, @tel varchar(32))
RETURNS bit
AS  
BEGIN

declare @call_record as bit

	if @pais = 4 begin --Empieza USA		
		-- grabar
		if @call_record_cam = 1 
			return 1
		-- no grabar
		if @call_record_cam=3  
			return 0
		-- grabar zonas permitidas
		if len(@tel) = 10
			select @call_record = isnull(call_record,1)  from ccTimeZoneArea where id_country= @pais and area = left(@tel,3) 			
		return @call_record
	end --Termina USA

	return 1;
END'
							
	EXEC(@Sql)
	
		set @process = 'ccsp_DLRGetDialInfo - Alter Procedure'
		set @Sql = 'Alter procedure [dbo].[ccsp_DLRGetDialInfo]
@callout_id int,
@cam_id smallint=0,
@iPortNumber smallint = 0
AS
set nocount on
declare @message_name as varchar(max), @messageDNCL_name as varchar(max)
declare @prefix as varchar(15)
declare @tNoContesta as tinyint
declare @ani as varchar(32)
declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint
declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
declare @call_record_cam as tinyint
declare @pais as tinyint 

set @prefix =''''
set @tNoContesta = 25
set @ani=''''
set @iTipoDial = 0
set @detectAnswerMachine = 0
set @detectVoiceMail =1
set @cam_tnotas = 30
set @keepDial = 0

select @pais = valor from ccsettings where setting_id = 104

-- Mensajes
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc
from dbo.fn_ccCamps_SelMessage(@cam_id)

-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )
-- Prefijo por campaña
if @prefix =''''
	select @prefix = dialPrefix from ccCamps where cam_id = @cam_id
-- Prefijo general, si es que esta habilitado
if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 1 = 1)
	select @prefix = valor from ccsettings where setting_id =101

set @iPortNumber = 0

-- Propiedades de campaña
select @tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
@call_record_cam = isnull(call_record,1)
from ccCamps C where C.cam_id=@cam_id

if @iPortNumber >= 0 
begin
	SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)
	, dial_tels
	, C.cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, isnull(@message_name, '''') as message_name
	, @tNoContesta as tNoContesta, @prefix as sDialPrefix
	, case when dbo.TelAni(c.cal_telefono,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono,@lista_id) else @ani end ani
	, case when dbo.TelAni(c.cal_telefono2,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono2,@lista_id) else @ani end ani2
	, case when dbo.TelAni(c.cal_telefono3,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono3,@lista_id) else @ani end ani3
	, case when dbo.TelAni(c.cal_telefono4,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono4,@lista_id) else @ani end ani4
	, case when dbo.TelAni(c.cal_telefono5,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono5,@lista_id) else @ani end ani5
	, @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail
	, @cam_tnotas cam_tnotas, @keepDial keepDial
	, isnull(@messageDNCL_name, '''') as messageDNCL_name
	,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record
	,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2
	,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3
	,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4
	,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5

	FROM ccoCallsOutSource C 
	WHERE C.callout_id = @callout_id
	return
end 

set nocount off'
									
	EXEC(@Sql)
	
		set @process = 'ccsp_DLRgetDialPrefix - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
@cam_id smallint=0,
@iPortNumber smallint = 0,
@phone varchar(30) = ''''
as
declare @prefix as varchar(15)
declare @ani as varchar(32)

declare @call_record_cam as tinyint
declare @pais as tinyint 

select @pais = valor from ccsettings where setting_id = 104
select @call_record_cam = call_record from ccCamps where cam_id = @cam_id

set @prefix =''''
-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

-- Prefijo por campaña,
if @prefix =''''
	select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

-- Prefijo general
if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
	select @prefix = valor from ccsettings where setting_id =101

-- Ani
set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

select @prefix as sDialPrefix, cam_tNoContesta as tNoContesta,
case when @ani = '''' then ani else @ani end as ani, detectAnswerMachine, detectVoiceMail,
dbo.EnableCallRecord(@call_record_cam,@pais,@phone) as call_record
from ccCamps where cam_id = @cam_id'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAConfCamp - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
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
	 DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
	 from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id) 
	 where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
	 order by cam_descripcion
	return(0)
 set nocount off'
 
 	EXEC(@Sql)
	
		set @process = 'ccsp_RIAUpdateCamConfig - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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
@surveyPctg int=null,
@call_record tinyint=null
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
 surveyPctg = isnull(@surveyPctg,surveyPctg),
 call_record = isnull(@call_record,call_record)
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
	
		set @process = 'configuraIdiomaCatalogosEnglish - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
AS
Print ''Iniciando proceso de configuracion en Ingles''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Week'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Night'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Saturday'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sunday'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady] 
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Not Clasified'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Break'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Bathroom'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''With client'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Clarification'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Meeting'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Lunch'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Systems'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Other'')

--EXEC sp_generate_inserts ''ccRIANotReadyGraph''
DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
TRUNCATE TABLE [dbo].[ccStatusLLamada]
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Initial'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Out of Schedule'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Out of Service'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''No Agents Logged in'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''On Hold'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandoned'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Time overflow'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Queue size overflow'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''With Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, ''Assigned Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, ''Assigned'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, ''Attended Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, ''Answered'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, ''Canceled Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, ''Assigned and Not Answered'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, ''Assigned and took line'')
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''Monday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''Tuesday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''Wednesday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''Thursday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''Friday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''Saturday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''Sunday'')

Print ''Estableciendo resultados de marcacion''
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Answer'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Busy'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Not Answer'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax/Modem'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Other'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, ''NoService'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, ''VoiceMail/Machine'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, ''Circuit busy'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, ''Cancelled'')

Print ''Estableciendo los tipos de estado de los agentes''
DELETE [dbo].[ccTipoStatusAgente]
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Unknown'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Ready'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Talking'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transfer'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Other'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Client'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Ringing'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, ''Problem'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, ''Wait for manual call'')

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agent'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''AVRS Access'')

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [dbo].[ccDias] ON
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (1, ''Sunday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (2, ''Monday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (3, ''Tuesday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (4, ''Wednesday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (5, ''Thursday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (6, ''Friday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (7, ''Saturday'')
SET IDENTITY_INSERT [dbo].[ccDias] OFF

truncate table cstoTarifa

Print ''Estableciendo los tipos de llamada''
delete cstoTipoLlamada
declare @country_id tinyint
select @country_id = valor from ccsettings where setting_id = 104
insert into cstoTipoLlamada values (@country_id,1,''Standard call'', 8, ''%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] ON
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Added to black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Blocked on loading'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removed from campaign'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Replaced from black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Deleted from black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Added by Disposition'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Load black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Load customer black list'')
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Ask for general information'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Call hung'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong Number'', 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Effective call'', 0, 0, 1)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Leave a message'', 0, 1, 2)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong Number'', 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes an individual message to agent'' where TipoMsgChat=1
Update ccRIAChat_TipoMsg set MsgDetalle=''Agent writes a message to Administrator'' where TipoMsgChat=2
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes a global message'' where TipoMsgChat=3

Print ''Mensajes defualt''
DELETE [dbo].[ccMsgFiles]
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Welcome message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Transfer message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Out of service message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''After hours message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''In queue message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''No agents signed in message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''VoiceMail message'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Overflow message'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''DNC list'')'

	EXEC(@Sql)
	
		set @process = 'ccsettings - Insert(2)'
		set @Sql = 'IF NOT EXISTS (select * from ccsettings where setting_id = 128)
BEGIN
	insert into ccsettings 
	values(128,0,''Enviar Call Key en llamada manual para integración'',1,''AGT'',''Envia el call key en las llamadas manuales a traves de la integracion'',''Send the call key for manual calls through integration components'',1)
END'

	EXEC(@Sql)

		set @process = 'ccsp_RIACATMenu - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
Declare @AVRS tinyint
select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124

if @Type=1
begin
if @ReportRol <> 1
  begin
  Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
  where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
  return(0)
  end

if @AVRS = 1
  begin
  Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
  and ((menu_id not in (41,42,53)) or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1))
  order by ordengral asc
 return(0)
  end
else
  begin
  Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
  and ((menu_id not in (41,42,53,73,74,75,76)) or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1))
  order by ordengral asc
  return(0)
  end
end

if @Type=2
begin
  delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu
  return(0)
end

if @Type=3
begin
  insert into ccMenuUser values (@id_User, @id_Menu,1)
  return(0)
end

if @Type=4
begin
  declare @lan varchar(3), @page varchar(200)
  select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
  select @lan = case valor when 0 then ''ES'' else ''EN'' end from ccSettings where setting_id = 27
  
  select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
  return(0)
end

set nocount off'

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
