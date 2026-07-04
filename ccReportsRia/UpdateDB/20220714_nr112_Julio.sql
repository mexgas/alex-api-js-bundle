SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 112

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'K002056 se cre RepWhatsAppByCampaignIn'
	set @sql = 'if not exists (select * from sys.tables where name = N''RepWhatsAppByCampaignIn'')
begin
    CREATE TABLE [dbo].[RepWhatsAppByCampaignIn](
	[date] [DATETIME] NOT NULL,
	[inboundid] [INT] NOT NULL,
	[campaign] [VARCHAR](50) NOT NULL,
	[associatedPhoneNumberWhatsApp] [VARCHAR](40) NOT NULL,	
	[numberSentMessagesWhatsApp] [VARCHAR](40) NOT NULL,
	[totalContactsWhatsApp] [INT] NOT NULL,
	[numberMsgReceivedWhats] [INT] NOT NULL,
	[contactCountry] [VARCHAR](50) NOT NULL,
	[totalConversationsWhatsApp] [INT] NOT NULL,
	[numberAssignedMessagesWhatsApp] [INT] NOT NULL,
	[maxWaitTimeWhatsApp] [INT] NULL,
	[avgWaitTimeWhatsApp] [INT] NOT NULL,
	[spamWhatsApp] [INT] NOT NULL,
	[serviceLevelWhats] [INT] NOT NULL,
	[contactFinishedConversationsWhatApp] [INT] NOT NULL,
	[agentFinishedConversationsWhatApp] [INT] NOT NULL,
	[systemFinishedConversationsWhatsApp] [INT] NOT NULL,
	[year] [SMALLINT] NOT NULL,
	[month] [SMALLINT] NOT NULL,
	[day] [SMALLINT] NOT NULL,
	[hour] [SMALLINT] NOT NULL,
	[minutes] [SMALLINT] NOT NULL)
end'
	EXEC(@sql)

	set @process = 'K002056 se cre RepWhatsAppDetailConversationIn'
	set @sql = 'if not exists (select * from sys.tables where name = N''RepWhatsAppDetailConversationIn'')
begin
    CREATE TABLE [dbo].[RepWhatsAppDetailConversationIn](
	[date] [DATETIME] NOT NULL,
	[inboundid] [INT] NOT NULL,
	[campaign] [VARCHAR](50) NOT NULL,
	[conversationid] [INT] NOT NULL,	
	[dispositionId] [SMALLINT] NOT NULL,
	[disposition] [VARCHAR](60) NOT NULL,
	[subDispositionId] [SMALLINT] NOT NULL,
    [subDisposition] [VARCHAR](60) NOT NULL,
	[associatedPhoneNumberWhatsApp] [VARCHAR](40) NOT NULL,
	[userId] [INT] NOT NULL,
	[agentName] [VARCHAR](50) NOT NULL,
	[contactPhoneNumberWhatsApp] [VARCHAR](40) NULL,
	[contactCountry] [VARCHAR](50) NOT NULL,
	[waitTimeWhatsApp] [INT] NOT NULL,
	[conversationTimeWhatsApp] [INT] NOT NULL,
	[billedAmountWhatsApp] [INT] NOT NULL,
	[year] [SMALLINT] NOT NULL,
	[month] [SMALLINT] NOT NULL,
	[day] [SMALLINT] NOT NULL,
	[hour] [SMALLINT] NOT NULL,
	[minutes] [SMALLINT] NOT NULL)
end'
	EXEC(@sql)

	set @process = 'K002056 se cre ccWhatsOringCountry'
	set @sql = 'if not exists( select * from sys.tables where name=''ccWhatsOringCountry'') begin
create table ccWhatsOringCountry(CodeCountry varchar(10) ,country varchar(255) not null,TagTranslate varchar(100) not null,length int not null
,primary key (CodeCountry,length desc)
)
end'
	EXEC(@sql)

	set @process = 'SPEC-72 RepAnsweredCallsByDialingRetries varchar(50) '
	set @sql = 'ALTER TABLE RepAnsweredCallsByDialingRetries ALTER COLUMN dialresult varchar(50);'
	EXEC(@sql)

	set @process = 'SPEC-72 RepOutManagementBase varchar(50) '
	set @sql = 'ALTER TABLE RepOutManagementBase ALTER COLUMN dialresult varchar(50);'
	EXEC(@sql)

	SET @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
	SET @Sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE [name] = N''MSmerge_tr_altertable'' AND type in (N''TR'') AND is_disabled = 0)
	BEGIN
	DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
	END'

	EXEC (@Sql)

	set @process = 'SPEC-72 Alter column descripcion from ccTipoResultadoDial'
    set @sql = '
		ALTER TABLE ccTipoResultadoDial ALTER COLUMN descripcion varchar(50);
	'
    EXEC(@sql)

SET @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
		SET @Sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE [name] = N''MSmerge_tr_altertable'' AND type in (N''TR'') AND is_disabled = 1)
	BEGIN 
		ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
	END'

		EXEC (@Sql)


	set @process = 'K002056 se crean registros de los diferentes paises'
	set @sql = 'if not exists(select * from ccWhatsOringCountry) begin
	insert into ccWhatsOringCountry values(''1264'',''Anguilla'',''systemTranslated_Anguilla'',4)
	insert into ccWhatsOringCountry values(''1268'',''Antigua'',''systemTranslated_Antigua'',4)
	insert into ccWhatsOringCountry values(''1242'',''Bahamas'',''systemTranslated_Bahamas'',4)
	insert into ccWhatsOringCountry values(''1246'',''Barbados'',''systemTranslated_Barbados'',4)
	insert into ccWhatsOringCountry values(''1411'',''Bermuda'',''systemTranslated_Bermuda'',4)
	insert into ccWhatsOringCountry values(''1284'',''British Virgin Islands'',''systemTranslated_BritishVirginIslands'',4)
	insert into ccWhatsOringCountry values(''1345'',''Cayman Islands'',''systemTranslated_CaymanIslands'',4)
	insert into ccWhatsOringCountry values(''1809'',''Dominican Republic'',''systemTranslated_DominicanRepublic'',4)
	insert into ccWhatsOringCountry values(''1829'',''Dominican Republic'',''systemTranslated_DominicanRepublic'',4)
	insert into ccWhatsOringCountry values(''1849'',''Dominican Republic'',''systemTranslated_DominicanRepublic'',4)
	insert into ccWhatsOringCountry values(''1473'',''Grenada'',''systemTranslated_Grenada'',4)
	insert into ccWhatsOringCountry values(''1671'',''Guam'',''systemTranslated_Guam'',4)
	insert into ccWhatsOringCountry values(''1876'',''Jamaica'',''systemTranslated_Jamaica'',4)
	insert into ccWhatsOringCountry values(''1664'',''Montserrat'',''systemTranslated_Montserrat'',4)
	insert into ccWhatsOringCountry values(''1787'',''Puerto Rico'',''systemTranslated_PuertoRico'',4)
	insert into ccWhatsOringCountry values(''1939'',''Puerto Rico'',''systemTranslated_PuertoRico'',4)
	insert into ccWhatsOringCountry values(''1869'',''St. Kitts/Nevis'',''systemTranslated_StKitts_Nevis'',4)
	insert into ccWhatsOringCountry values(''1758'',''St. Lucia'',''systemTranslated_St.Lucia'',4)
	insert into ccWhatsOringCountry values(''1868'',''Trinidad & Tobago'',''systemTranslated_TrinidadTobago'',4)
	insert into ccWhatsOringCountry values(''1649'',''Turks & Caicos'',''systemTranslated_TurksCaicos'',4)
	insert into ccWhatsOringCountry values(''1340'',''US Virgin Islands'',''systemTranslated_USVirginIslands'',4)
	insert into ccWhatsOringCountry values(''7'',''Russia'',''systemTranslated_Russia'',1)
	insert into ccWhatsOringCountry values(''20'',''Egypt'',''systemTranslated_Egypt'',2)
	insert into ccWhatsOringCountry values(''27'',''South Africa'',''systemTranslated_SouthAfrica'',2)
	insert into ccWhatsOringCountry values(''30'',''Greece'',''systemTranslated_Greece'',2)
	insert into ccWhatsOringCountry values(''31'',''Netherlands'',''systemTranslated_Netherlands'',2)
	insert into ccWhatsOringCountry values(''32'',''Belgium'',''systemTranslated_Belgium'',2)
	insert into ccWhatsOringCountry values(''33'',''France'',''systemTranslated_France'',2)
	insert into ccWhatsOringCountry values(''34'',''Spain'',''systemTranslated_Spain'',2)
	insert into ccWhatsOringCountry values(''36'',''Hungary'',''systemTranslated_Hungary'',2)
	insert into ccWhatsOringCountry values(''39'',''Italy'',''systemTranslated_Italy'',2)
	insert into ccWhatsOringCountry values(''40'',''Romania'',''systemTranslated_Romania'',2)
	insert into ccWhatsOringCountry values(''41'',''Switzerland'',''systemTranslated_Switzerland'',2)
	insert into ccWhatsOringCountry values(''43'',''Austria'',''systemTranslated_Austria'',2)
	insert into ccWhatsOringCountry values(''44'',''United Kingdom'',''systemTranslated_UnitedKingdom'',2)
	insert into ccWhatsOringCountry values(''45'',''Denmark'',''systemTranslated_Denmark'',2)
	insert into ccWhatsOringCountry values(''46'',''Sweden'',''systemTranslated_Sweden'',2)
	insert into ccWhatsOringCountry values(''47'',''Norway'',''systemTranslated_Norway'',2)
	insert into ccWhatsOringCountry values(''48'',''Poland'',''systemTranslated_Poland'',2)
	insert into ccWhatsOringCountry values(''49'',''Germany'',''systemTranslated_Germany'',2)
	insert into ccWhatsOringCountry values(''51'',''Peru'',''systemTranslated_Peru'',2)
	insert into ccWhatsOringCountry values(''52'',''Mexico'',''systemTranslated_Mexico'',2)
	insert into ccWhatsOringCountry values(''53'',''Cuba'',''systemTranslated_Cuba'',2)
	insert into ccWhatsOringCountry values(''54'',''Argentina'',''systemTranslated_Argentina'',2)
	insert into ccWhatsOringCountry values(''55'',''Brazil'',''systemTranslated_Brazil'',2)
	insert into ccWhatsOringCountry values(''56'',''Chile'',''systemTranslated_Chile'',2)
	insert into ccWhatsOringCountry values(''57'',''Colombia'',''systemTranslated_Colombia'',2)
	insert into ccWhatsOringCountry values(''58'',''Venezuela'',''systemTranslated_Venezuela'',2)
	insert into ccWhatsOringCountry values(''60'',''Malaysia'',''systemTranslated_Malaysia'',2)
	insert into ccWhatsOringCountry values(''61'',''Australia'',''systemTranslated_Australia'',2)
	insert into ccWhatsOringCountry values(''63'',''Philippines'',''systemTranslated_Philippines'',2)
	insert into ccWhatsOringCountry values(''64'',''New Zealand'',''systemTranslated_NewZealand'',2)
	insert into ccWhatsOringCountry values(''65'',''Singapore'',''systemTranslated_Singapore'',2)
	insert into ccWhatsOringCountry values(''66'',''Thailand'',''systemTranslated_Thailand'',2)
	insert into ccWhatsOringCountry values(''81'',''Japan'',''systemTranslated_Japan'',2)
	insert into ccWhatsOringCountry values(''82'',''Korea (South)'',''systemTranslated_KoreaSouth'',2)
	insert into ccWhatsOringCountry values(''84'',''Vietnam'',''systemTranslated_Vietnam'',2)
	insert into ccWhatsOringCountry values(''86'',''China'',''systemTranslated_China'',2)
	insert into ccWhatsOringCountry values(''90'',''Turkey'',''systemTranslated_Turkey'',2)
	insert into ccWhatsOringCountry values(''91'',''India'',''systemTranslated_India'',2)
	insert into ccWhatsOringCountry values(''92'',''Pakistan'',''systemTranslated_Pakistan'',2)
	insert into ccWhatsOringCountry values(''93'',''Afghanistan'',''systemTranslated_Afghanistan'',2)
	insert into ccWhatsOringCountry values(''94'',''Sri Lanka'',''systemTranslated_SriLanka'',2)
	insert into ccWhatsOringCountry values(''98'',''Iran'',''systemTranslated_Iran'',2)
	insert into ccWhatsOringCountry values(''212'',''Morocco'',''systemTranslated_Morocco'',3)
	insert into ccWhatsOringCountry values(''213'',''Algeria'',''systemTranslated_Algeria'',3)
	insert into ccWhatsOringCountry values(''216868'',''Tunisia'',''systemTranslated_Tunisia'',6)
	insert into ccWhatsOringCountry values(''218'',''Libya'',''systemTranslated_Libya'',3)
	insert into ccWhatsOringCountry values(''220'',''Gambia'',''systemTranslated_Gambia'',3)
	insert into ccWhatsOringCountry values(''221'',''Senegal'',''systemTranslated_Senegal'',3)
	insert into ccWhatsOringCountry values(''222'',''Mauritania'',''systemTranslated_Mauritania'',3)
	insert into ccWhatsOringCountry values(''224'',''Guinea'',''systemTranslated_Guinea'',3)
	insert into ccWhatsOringCountry values(''225'',''Ivory Coast'',''systemTranslated_IvoryCoast'',3)
	insert into ccWhatsOringCountry values(''226'',''Burkina Faso'',''systemTranslated_BurkinaFaso'',3)
	insert into ccWhatsOringCountry values(''227'',''Niger'',''systemTranslated_Niger'',3)
	insert into ccWhatsOringCountry values(''229'',''Benin'',''systemTranslated_Benin'',3)
	insert into ccWhatsOringCountry values(''231'',''Liberia'',''systemTranslated_Liberia'',3)
	insert into ccWhatsOringCountry values(''232'',''Sierra Leone'',''systemTranslated_SierraLeone'',3)
	insert into ccWhatsOringCountry values(''233'',''Ghana'',''systemTranslated_Ghana'',3)
	insert into ccWhatsOringCountry values(''234'',''Nigeria'',''systemTranslated_Nigeria'',3)
	insert into ccWhatsOringCountry values(''235'',''Chad'',''systemTranslated_Chad'',3)
	insert into ccWhatsOringCountry values(''236'',''Central African Republic'',''systemTranslated_CentralAfricanRepublic'',3)
	insert into ccWhatsOringCountry values(''237'',''Cameroon'',''systemTranslated_Cameroon'',3)
	insert into ccWhatsOringCountry values(''238'',''Cape Verde'',''systemTranslated_CapeVerdeIslands'',3)
	insert into ccWhatsOringCountry values(''242'',''Congo'',''systemTranslated_Congo'',3)
	insert into ccWhatsOringCountry values(''243'',''Congo, Dem. Rep. of'',''systemTranslated_CongoDemRepof'',3)
	insert into ccWhatsOringCountry values(''244'',''Angola'',''systemTranslated_Angola'',3)
	insert into ccWhatsOringCountry values(''246'',''Diego Garcia'',''systemTranslated_DiegoGarcia'',3)
	insert into ccWhatsOringCountry values(''247'',''Ascension'',''systemTranslated_Ascension'',3)
	insert into ccWhatsOringCountry values(''249758'',''Sudan'',''systemTranslated_Sudan'',6)
	insert into ccWhatsOringCountry values(''250'',''Rwandese Republic'',''systemTranslated_RwandeseRepublic'',3)
	insert into ccWhatsOringCountry values(''251'',''Ethiopia'',''systemTranslated_Ethiopia'',3)
	insert into ccWhatsOringCountry values(''253'',''Djibouti'',''systemTranslated_Djibouti'',3)
	insert into ccWhatsOringCountry values(''254'',''Kenya'',''systemTranslated_Kenya'',3)
	insert into ccWhatsOringCountry values(''255'',''Tanzania'',''systemTranslated_Tanzania'',3)
	insert into ccWhatsOringCountry values(''256649'',''Uganda'',''systemTranslated_Uganda'',6)
	insert into ccWhatsOringCountry values(''257'',''Burundi'',''systemTranslated_Burundi'',3)
	insert into ccWhatsOringCountry values(''258'',''Mozambique'',''systemTranslated_Mozambique'',3)
	insert into ccWhatsOringCountry values(''260'',''Zambia'',''systemTranslated_Zambia'',3)
	insert into ccWhatsOringCountry values(''261'',''Madagascar'',''systemTranslated_Madagascar'',3)
	insert into ccWhatsOringCountry values(''263'',''Zimbabwe'',''systemTranslated_Zimbabwe'',3)
	insert into ccWhatsOringCountry values(''265'',''Malawi'',''systemTranslated_Malawi'',3)
	insert into ccWhatsOringCountry values(''267'',''Botswana'',''systemTranslated_Botswana'',3)
	insert into ccWhatsOringCountry values(''268'',''Swaziland'',''systemTranslated_Swaziland'',3)
	insert into ccWhatsOringCountry values(''269'',''Comoros'',''systemTranslated_Comoros'',3)
	insert into ccWhatsOringCountry values(''291'',''Eritrea'',''systemTranslated_Eritrea'',3)
	insert into ccWhatsOringCountry values(''297'',''Aruba'',''systemTranslated_Aruba'',3)
	insert into ccWhatsOringCountry values(''299'',''Greenland'',''systemTranslated_Greenland'',3)
	insert into ccWhatsOringCountry values(''350'',''Gibraltar'',''systemTranslated_Gibraltar'',3)
	insert into ccWhatsOringCountry values(''351'',''Portugal'',''systemTranslated_Portugal'',3)
	insert into ccWhatsOringCountry values(''352'',''Luxembourg'',''systemTranslated_Luxembourg'',3)
	insert into ccWhatsOringCountry values(''353'',''Ireland'',''systemTranslated_Ireland'',3)
	insert into ccWhatsOringCountry values(''354'',''Iceland'',''systemTranslated_Iceland'',3)
	insert into ccWhatsOringCountry values(''355'',''Albania'',''systemTranslated_Albania'',3)
	insert into ccWhatsOringCountry values(''356'',''Malta'',''systemTranslated_Malta'',3)
	insert into ccWhatsOringCountry values(''357'',''Cyprus'',''systemTranslated_Cyprus'',3)
	insert into ccWhatsOringCountry values(''358'',''Finland'',''systemTranslated_Finland'',3)
	insert into ccWhatsOringCountry values(''359'',''Bulgaria'',''systemTranslated_Bulgaria'',3)
	insert into ccWhatsOringCountry values(''370'',''Lithuania'',''systemTranslated_Lithuania'',3)
	insert into ccWhatsOringCountry values(''371'',''Latvia'',''systemTranslated_Latvia'',3)
	insert into ccWhatsOringCountry values(''372'',''Estonia'',''systemTranslated_Estonia'',3)
	insert into ccWhatsOringCountry values(''373'',''Moldova'',''systemTranslated_Moldova'',3)
	insert into ccWhatsOringCountry values(''374'',''Armenia'',''systemTranslated_Armenia'',3)
	insert into ccWhatsOringCountry values(''375'',''Belarus'',''systemTranslated_Belarus'',3)
	insert into ccWhatsOringCountry values(''377'',''Monaco'',''systemTranslated_Monaco'',3)
	insert into ccWhatsOringCountry values(''378'',''San Marino'',''systemTranslated_SanMarino'',3)
	insert into ccWhatsOringCountry values(''379'',''Vatican City'',''systemTranslated_VaticanCity'',3)
	insert into ccWhatsOringCountry values(''380'',''Ukraine'',''systemTranslated_Ukrainea'',3)
	insert into ccWhatsOringCountry values(''381'',''Serbia/Montenegro'',''systemTranslated_Serbia_Montenegro'',3)
	insert into ccWhatsOringCountry values(''385'',''Croatia'',''systemTranslated_Croatia'',3)
	insert into ccWhatsOringCountry values(''386'',''Slovenia'',''systemTranslated_Slovenia'',3)
	insert into ccWhatsOringCountry values(''387'',''Bosnia/Herzegovina'',''systemTranslated_Bosnia_Herzegovina'',3)
	insert into ccWhatsOringCountry values(''389'',''Macedonia'',''systemTranslated_Macedonia'',3)
	insert into ccWhatsOringCountry values(''420'',''Czech Republic'',''systemTranslated_CzechRepublic'',3)
	insert into ccWhatsOringCountry values(''421'',''Slovak Republic'',''systemTranslated_SlovakRepublic'',3)
	insert into ccWhatsOringCountry values(''423'',''Liechtenstein'',''systemTranslated_Liechtenstein'',3)
	insert into ccWhatsOringCountry values(''500'',''Falkland Islands'',''systemTranslated_FalklandIslands'',3)
	insert into ccWhatsOringCountry values(''501'',''Belize'',''systemTranslated_Belize'',3)
	insert into ccWhatsOringCountry values(''502'',''Guatemala'',''systemTranslated_Guatemala'',3)
	insert into ccWhatsOringCountry values(''503'',''El Salvador'',''systemTranslated_ElSalvador'',3)
	insert into ccWhatsOringCountry values(''504'',''Honduras'',''systemTranslated_Honduras'',3)
	insert into ccWhatsOringCountry values(''505'',''Nicaragua'',''systemTranslated_Nicaragua'',3)
	insert into ccWhatsOringCountry values(''506'',''Costa Rica'',''systemTranslated_CostaRica'',3)
	insert into ccWhatsOringCountry values(''507'',''Panama'',''systemTranslated_Panama'',3)
	insert into ccWhatsOringCountry values(''509'',''Haiti'',''systemTranslated_Haiti'',3)
	insert into ccWhatsOringCountry values(''590'',''Guadeloupe'',''systemTranslated_Guadeloupe'',3)
	insert into ccWhatsOringCountry values(''591'',''Bolivia'',''systemTranslated_Bolivia'',3)
	insert into ccWhatsOringCountry values(''592'',''Guyana'',''systemTranslated_Guyana'',3)
	insert into ccWhatsOringCountry values(''593'',''Ecuador'',''systemTranslated_Ecuador'',3)
	insert into ccWhatsOringCountry values(''594'',''French Guiana'',''systemTranslated_FrenchGuiana'',3)
	insert into ccWhatsOringCountry values(''595'',''Paraguay'',''systemTranslated_Paraguay'',3)
	insert into ccWhatsOringCountry values(''596'',''Martinique'',''systemTranslated_Martinique'',3)
	insert into ccWhatsOringCountry values(''597'',''Suriname'',''systemTranslated_Suriname'',3)
	insert into ccWhatsOringCountry values(''598'',''Uruguay'',''systemTranslated_Uruguay'',3)
	insert into ccWhatsOringCountry values(''599'',''Netherlands Antilles'',''systemTranslated_NetherlandsAntilles'',3)
	insert into ccWhatsOringCountry values(''670'',''East Timor'',''systemTranslated_EastTimor'',3)
	insert into ccWhatsOringCountry values(''672'',''Australian External Territories'',''systemTranslated_AustralianExternalTerritories'',3)
	insert into ccWhatsOringCountry values(''673'',''Brunei Darussalam'',''systemTranslated_BruneiDarussalam'',3)
	insert into ccWhatsOringCountry values(''674'',''Nauru'',''systemTranslated_Nauru'',3)
	insert into ccWhatsOringCountry values(''675'',''Papua New Guinea'',''systemTranslated_PapuaNewGuinea'',3)
	insert into ccWhatsOringCountry values(''677'',''Solomon Islands'',''systemTranslated_SolomonIslands'',3)
	insert into ccWhatsOringCountry values(''679'',''Fiji Islands'',''systemTranslated_FijiIslands'',3)
	insert into ccWhatsOringCountry values(''680'',''Palau'',''systemTranslated_Palau'',3)
	insert into ccWhatsOringCountry values(''682'',''Cook Islands'',''systemTranslated_CookIslands'',3)
	insert into ccWhatsOringCountry values(''685'',''Western Samoa'',''systemTranslated_WesternSamoa'',3)
	insert into ccWhatsOringCountry values(''687'',''New Caledonia'',''systemTranslated_NewCaledonia'',3)
	insert into ccWhatsOringCountry values(''689'',''French Polynesia'',''systemTranslated_FrenchPolynesia'',3)
	insert into ccWhatsOringCountry values(''691'',''Micronesia'',''systemTranslated_Micronesia'',3)
	insert into ccWhatsOringCountry values(''692'',''Marshall Islands'',''systemTranslated_MarshallIslands'',3)
	insert into ccWhatsOringCountry values(''850'',''Korea (North)'',''systemTranslated_KoreaNorth'',3)
	insert into ccWhatsOringCountry values(''852'',''Hong Kong'',''systemTranslated_HongKong'',3)
	insert into ccWhatsOringCountry values(''853'',''Macao'',''systemTranslated_Macao'',3)
	insert into ccWhatsOringCountry values(''855'',''Cambodia'',''systemTranslated_Cambodia'',3)
	insert into ccWhatsOringCountry values(''856'',''Laos'',''systemTranslated_Laos'',3)
	insert into ccWhatsOringCountry values(''880'',''Bangladesh'',''systemTranslated_Bangladesh'',3)
	insert into ccWhatsOringCountry values(''886'',''Taiwan'',''systemTranslated_Taiwan'',3)
	insert into ccWhatsOringCountry values(''960'',''Maldives'',''systemTranslated_Maldives'',3)
	insert into ccWhatsOringCountry values(''961'',''Lebanon'',''systemTranslated_Lebanon'',3)
	insert into ccWhatsOringCountry values(''962'',''Jordan'',''systemTranslated_Jordan'',3)
	insert into ccWhatsOringCountry values(''963'',''Syria'',''systemTranslated_Syria'',3)
	insert into ccWhatsOringCountry values(''964'',''Iraq'',''systemTranslated_Iraq'',3)
	insert into ccWhatsOringCountry values(''965'',''Kuwait'',''systemTranslated_Kuwait'',3)
	insert into ccWhatsOringCountry values(''966'',''Saudi Arabia'',''systemTranslated_SaudiArabia'',3)
	insert into ccWhatsOringCountry values(''967'',''Yemen'',''systemTranslated_Yemen'',3)
	insert into ccWhatsOringCountry values(''968'',''Oman'',''systemTranslated_Oman'',3)
	insert into ccWhatsOringCountry values(''971'',''United Arab Emirates'',''systemTranslated_UnitedArabEmirates'',3)
	insert into ccWhatsOringCountry values(''972'',''Israel'',''systemTranslated_Israel'',3)
	insert into ccWhatsOringCountry values(''973'',''Bahrain'',''systemTranslated_Bahrain'',3)
	insert into ccWhatsOringCountry values(''974'',''Qatar'',''systemTranslated_Qatar'',3)
	insert into ccWhatsOringCountry values(''975'',''Bhutan'',''systemTranslated_Bhutan'',3)
	insert into ccWhatsOringCountry values(''976'',''Mongolia'',''systemTranslated_Mongolia'',3)
	insert into ccWhatsOringCountry values(''977'',''Nepal'',''systemTranslated_Nepal'',3)
	insert into ccWhatsOringCountry values(''992'',''Tajikistan'',''systemTranslated_Tajikistan'',3)
	insert into ccWhatsOringCountry values(''993'',''Turkmenistan'',''systemTranslated_Turkmenistan'',3)
	insert into ccWhatsOringCountry values(''994'',''Azerbaijan'',''systemTranslated_Azerbaijan'',3)
	insert into ccWhatsOringCountry values(''995'',''Georgia'',''systemTranslated_Georgia'',3)
	insert into ccWhatsOringCountry values(''998'',''Uzbekistan'',''systemTranslated_Uzbekistan'',3)
	insert into ccWhatsOringCountry values(''5399'',''Guantanamo Bay'',''systemTranslated_GuantanamoBay'',4)
end'
	EXEC(@sql)

	set @process = 'K002056 verifica si existe la funcion'
	set @sql = 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''GetCountryWhatsApp'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
begin
    DROP FUNCTION GetCountryWhatsApp;
end'
	EXEC(@sql)

	set @process = 'K002056 crea el procedure GetCountryWhatsApp'
	set @sql = 'CREATE function [dbo].[GetCountryWhatsApp](@phone varchar(50))
RETURNS varchar(255) 
AS  
BEGIN
declare @resultado varchar(255)
set @resultado=@phone

select  top 1  @resultado=TagTranslate from ccWhatsOringCountry 
where left(@phone,length)=CodeCountry
order by length desc


return @resultado

end'
	EXEC(@sql)

	set @process = 'K002056 se agregan filtros'
	set @sql = 'if not exists(select * from ReportsFiltersMenus where idReport=12010) begin
	INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(12010,N''date'')
	INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(12010,N''filterby'')	
end

if not exists(select * from ReportsFilters where id=12010) begin
	insert into ReportsFilters values(''Answered Calls Detail'',''acds'',12010)
	insert into ReportsFilters values(''Answered Calls Detail'',''users'',12010)
end

if not exists(select * from TranslatedReports where id in(12010,12020)) begin
	insert into TranslatedReports values(12010,''contactCountry'')
	insert into TranslatedReports values(12020,''contactCountry'')
end

if not exists (select * from ReportsTotals where id=''12010'') begin
	INSERT INTO ReportsTotals VALUES (12010,''sum:tQueue|sum:tConversation'')
end

if not exists (select * from ReportsTotals where id=''12020'') begin
	INSERT INTO ReportsTotals VALUES (12020,''sum:numberSentMessagesWhatsApp|sum:totalContactsWhatsApp|sum:numberMsgReceivedWhats|sum:totalConversationsWhatsApp|sum:numberAssignedMessagesWhatsApp|sum:maxWaitTimeWhatsApp|sum:avgWaitTimeWhatsApp|sum:spamWhatsApp|sum:contactFinishedConversationsWhatApp|sum:agentFinishedConversationsWhatApp|sum:systemFinishedConversationsWhatsApp'')
end


if not exists(select * from ReportsFiltersMenus where idReport=12020) begin
	INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(12020,N''date'')
	INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(12020,N''filterby'')	
end

if not exists(select * from ReportsFilters where id=12020) begin
	insert into ReportsFilters values(''Answered Calls Detail'',''acds'',12020)
end

--creation of index

if not exists (select * from sys.indexes where name = N''RepWhatsAppDetailConversationIn_I'' and object_id = OBJECT_ID(N''RepWhatsAppDetailConversationIn''))
begin
    CREATE INDEX RepWhatsAppDetailConversationIn_I ON RepWhatsAppDetailConversationIn (date, inboundid, userId);
end

if not exists (select * from sys.indexes where name = N''RepWhatsAppByCampaignIn_I'' and object_id = OBJECT_ID(N''RepWhatsAppByCampaignIn''))
begin
    CREATE INDEX RepWhatsAppByCampaignIn_I ON RepWhatsAppByCampaignIn (date, inboundid);
end'
	EXEC(@sql)

		set @process = 'K002056 verifica si existe el procedure'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepWhatsAppDetailConversationIn'')
    begin
        DROP PROCEDURE ccspRepWhatsAppDetailConversationIn;
    end'
	EXEC(@sql)

	set @process = 'K002056 verifica si existe el procedure'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepWhatsAppByCampaignIn'')
    begin
        DROP PROCEDURE ccspRepWhatsAppByCampaignIn;
    end'
	EXEC(@sql)

	set @process = 'K002056 crea el procedure ccspRepWhatsAppByCampaignIn'
	set @sql = 'CREATE procedure [dbo].[ccspRepWhatsAppByCampaignIn]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepWhatsAppByCampaignIn with(rowlock)	where date >= @from AND date < @to ;
	
	WITH conv
	AS (
		SELECT convert(date, A.requestDate) AS [date]
		,A.inboundId AS inboundid
		,B.descripcion as campaign		 
		,A.phoneACD AS associatedPhoneNumberWhatsApp
		,dbo.GetCountryWhatsApp(A.clientId) contactCountry
		,count(DISTINCT clientId) totalContactsWhatsApp------
		,count(A.requestDate) AS totalConversationsWhatsApp
		,count(CASE 
					WHEN agentId > 0
						THEN 1
					ELSE NULL
					END) numberAssignedMessagesWhatsApp
		,ISNULL(MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),0) as maxWaitTimeWhatsApp
		,ISNULL(ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),0) as avgWaitTimeWhatsApp
		,count(CASE 
					WHEN conversationStatus = 13
						THEN 1
					ELSE NULL
					END) spamWhatsApp
		,0 as serviceLevelWhats
		,count(CASE 
					WHEN conversationStatus = 17
						THEN 1
					ELSE NULL
					END) contactFinishedConversationsWhatApp
		,count(CASE 
					WHEN conversationStatus = 11
						THEN 1
					ELSE NULL
					END) agentFinishedConversationsWhatApp
		,count(CASE 
					WHEN conversationStatus = 17
						THEN 1
					ELSE NULL
					END) systemFinishedConversationsWhatsApp
		,COUNT(conversationDate) receivedConversations
        ,COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= (ISNULL(C.defaultServiceLevelParameter, 2) * 60) THEN 1 ELSE NULL END) lessThanDefault
		FROM ccWhatsAppConversations A
		inner join ccinbound B on A.inboundId=B.Inbound_id
		LEFT JOIN contactMeanIn C on A.inboundId = c.inboundId 
		WHERE A.requestDate 
			BETWEEN @from
				AND @to
		GROUP BY convert(DATE, A.requestDate), A.inboundId, B.descripcion, A.phoneACD, dbo.GetCountryWhatsApp(A.clientId)
		), numSentMsg
	AS (
		SELECT convert(DATE, conv.requestDate) date, conv.inboundId, conv.phoneACD associatedPhoneNumberWhatsApp, count(CASE 
					WHEN Msg.originType IN (''Agent'', ''Admin'')
						THEN 1
					ELSE NULL
					END) numberMsgClientConversation, count(CASE 
					WHEN Msg.originType IN (''Client'')
						THEN 1
					ELSE NULL
					END) numberMsgReceivedWhats
		FROM ccWAMessagesConversations Msg
		INNER JOIN ccWhatsAppConversations conv ON Msg.conversationId = conv.conversationId	
		WHERE conv.conversationDate BETWEEN @from
				AND @to
		GROUP BY convert(DATE, conv.requestDate), conv.inboundId, conv.phoneACD
		)

	INSERT INTO RepWhatsAppByCampaignIn
		SELECT A.date, A.inboundid, A.campaign, A.associatedPhoneNumberWhatsApp, ISNULL(B.numberMsgClientConversation,0) numberSentMessagesWhatsApp, A.totalContactsWhatsApp, ISNULL(B.numberMsgReceivedWhats,0), A.contactCountry, A.totalConversationsWhatsApp, A.numberAssignedMessagesWhatsApp, A.maxWaitTimeWhatsApp, A.avgWaitTimeWhatsApp,
			   A.spamWhatsApp, CASE WHEN A.receivedConversations = 0 THEN 0 ELSE ROUND(((A.lessThanDefault*1.0) / A.receivedConversations) * 100, 2) END serviceLevelWhats, A.contactFinishedConversationsWhatApp, A.agentFinishedConversationsWhatApp, A.systemFinishedConversationsWhatsApp ,DATEPART(yyyy,A.[DATE]) [year]
			,datepart(mm,A.[DATE]) [month]
			,datepart(dd,A.[DATE]) [day]
			,0 [hour]
			,0 [minutes]
		FROM conv A
		LEFT JOIN numSentMsg B ON A.DATE = B.DATE
			AND A.inboundId = B.inboundId
			AND A.associatedPhoneNumberWhatsApp = B.associatedPhoneNumberWhatsApp
end'
	EXEC(@sql)

	set @process = 'K002056 crea el procedure ccspRepWhatsAppDetailConversationIn'
	set @sql = 'CREATE procedure [dbo].[ccspRepWhatsAppDetailConversationIn]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
	set @from=DATEADD(dd,-1,@from)
if @to is null
	select @to = getdate()

if @action = 1	begin

    delete from RepWhatsAppDetailConversationIn where date >= @from AND date < @to

	INSERT INTO RepWhatsAppDetailConversationIn
	(date,inboundid,campaign,conversationid,dispositionId,disposition,subDispositionId,subDisposition,associatedPhoneNumberWhatsApp,userId,agentName,
	contactPhoneNumberWhatsApp,contactCountry,waitTimeWhatsApp,conversationTimeWhatsApp,billedWhatsApp,year,month,day,hour,minutes)
	select A.requestDate as [date] ---A.conversationDate
     ,A.inboundId as inboundid
	 ,B.descripcion as campaign	
	 ,A.conversationId as conversationid
	 ,A.disposition as dispositionId
	 ,isnull(disposition.Description,'''') as disposition
	 ,A.subDisposition as subDispositionId
	 ,isnull(subDisposition.califSubDesc,'''') as subDisposition
	 ,A.phoneACD as associatedPhoneNumberWhatsApp
	 ,A.agentId as userId
	 ,isnull([user].Nombres+'' ''+ [user].ApellidoPaterno+'' ''+[user].ApellidoMaterno,'''') as agentName
	 ,A.clientId as contactPhoneNumberWhatsApp
	 ,dbo.GetCountryWhatsApp(A.clientId) contactCountry
	 ,A.tQueue as waitTimeWhatsApp
	 ,isnull(A.tConversation,A.tChatting) as conversationTimeWhatsApp	
	 ,case when A.FirstMessageAgent is not null then 1 else 0 end as billedAmountWhatsApp
	 ,DATEPART(yyyy,A.requestDate) [year]
	 ,datepart(mm,A.requestDate) [month]
	 ,datepart(dd,A.requestDate) [day]
	 ,datepart(hh,A.requestDate) [hour]
	 ,datepart(mi,A.requestDate) [minutes]
	 from ccWhatsAppConversations A
	inner join ccinbound B on A.inboundId=B.Inbound_id
	left join cctipocalif disposition on disposition.calif_id=A.disposition
	left join cctipocalifsub subDisposition on subDisposition.califSub_id=A.subDisposition
	left join ccUserView [user] on [user].User_id=A.agentId
	where A.requestDate between @from AND @to
end'
	EXEC(@sql)
-------------------------------Preview K004009 DetalleMarcación --------------------------------
	set @process = 'alter table RepOutDialDetail'
	set @sql = '
		if not exists (select * from sys.columns where name = N''data6'' and Object_ID = Object_ID(N''RepOutDialDetail''))
		begin
			alter table RepOutDialDetail add data6 varchar(255) null
		end
		if not exists (select * from sys.columns where name = N''data7'' and Object_ID = Object_ID(N''RepOutDialDetail''))
			begin
				alter table RepOutDialDetail add data7 varchar(255) null
			end
		if not exists (select * from sys.columns where name = N''data8'' and Object_ID = Object_ID(N''RepOutDialDetail''))
			begin
				alter table RepOutDialDetail add data8 varchar(255) null
			end
		if not exists (select * from sys.columns where name = N''data9'' and Object_ID = Object_ID(N''RepOutDialDetail''))
			begin
				alter table RepOutDialDetail add data9 varchar(255) null
			end
		if not exists (select * from sys.columns where name = N''data10'' and Object_ID = Object_ID(N''RepOutDialDetail''))
			begin
				alter table RepOutDialDetail add data10 varchar(255) null
			end
		if not exists (select * from sys.columns where name = N''data11'' and Object_ID = Object_ID(N''RepOutDialDetail''))
			begin
				alter table RepOutDialDetail add data11 varchar(255) null
			end
		if not exists (select * from sys.columns where name = N''data12'' and Object_ID = Object_ID(N''RepOutDialDetail''))
			begin
				alter table RepOutDialDetail add data12 varchar(255) null
			end
		if not exists (select * from sys.columns where name = N''data13'' and Object_ID = Object_ID(N''RepOutDialDetail''))
			begin
				alter table RepOutDialDetail add data13 varchar(255) null
			end
		if not exists (select * from sys.columns where name = N''data14'' and Object_ID = Object_ID(N''RepOutDialDetail''))
			begin
				alter table RepOutDialDetail add data14 varchar(255) null
			end
		if not exists (select * from sys.columns where name = N''data15'' and Object_ID = Object_ID(N''RepOutDialDetail''))
			begin
				alter table RepOutDialDetail add data15 varchar(255) null
			end
		if not exists (select * from sys.columns where name = N''preview_Time'' and Object_ID = Object_ID(N''RepOutDialDetail''))
			begin
				alter table RepOutDialDetail add preview_Time smallint null
			end
		if not exists (select * from sys.columns where name = N''login'' and Object_ID = Object_ID(N''RepOutDialDetail''))
			begin
				alter table RepOutDialDetail add login varchar(40) null
			end
	'
	EXEC(@sql)

	set @process = 'SPEC-66 ALTER SP ccspRepOutDialDetail'
	set @sql = '
		ALTER PROCEDURE [dbo].[ccspRepOutDialDetail] 
		@action AS TINYINT, 
		@from AS   DATETIME = NULL, 
		@to AS     DATETIME = NULL
		AS
		SET NOCOUNT ON

		IF @from IS NULL
			SELECT @from =CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE())) - 15
		if @to is null
			SELECT @to = GETDATE()

		IF @action = 1
		BEGIN  

		DECLARE @country SMALLINT
		SELECT @country = valor
		FROM ccSettings
		WHERE setting_id = 104

		--Borrar lo que esta para no repetir          
		DELETE FROM RepOutDialDetail WHERE date >= @from            AND date < @to
		        
			IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
			IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
			IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;

			SELECT	dial.logDial_id
				,dial.callout_id
				,dial.cam_id
				,CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id
				,ISNULL(tr.descripcion ,'''') as resultDialDesc
				,dial.Telefono
				,dial.Puerto
				,dial.fecha
				,dial.tDialing
				,CASE WHEN dial.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview'' 
					  WHEN LEFT(dial.TipoDialingMode, 1) = ''1'' THEN ''systemTranslated_Assisted'' 
					  WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto'' 
					  WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' END AS dialType			  
				,dial.tBusy
				,dial.answerbit
				,dial.canceledNoAgents
				,dial.cal_id
				,dial.disconnectCause
				,co.cal_key
				,co.file_moved
				,dial.tipoLlamada_id
				,tco.[Description] AS CallDisposition
				,tsco.califSubDesc
				,CASE WHEN dial.disconnectCause <> '''' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '''' END codeSip
				,case when @country<>1 then '''' WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
					WHEN dial.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' ELSE ''systemTranslated_Indefinite'' END TipoTel
				,ISNULL(regp.tPreview,'''') as tpreview
				,co.User_id as UserID
			INTO #dials
			FROM ccoLogDials dial(NOLOCK)
			LEFT JOIN ccocallsout co(NOLOCK) ON dial.cal_id = co.cal_id
			LEFT JOIN cctipocalifout tco WITH (NOLOCK) ON tco.calif_id = co.calif_id
			LEFT JOIN cctipocalifsubout tsco WITH (NOLOCK) ON tsco.califSub_id = co.califSub_id
			LEFT JOIN RegProcessPreviewRecord regp WITH (NOLOCK) ON regp.callout_id = co.callout_id and regp.callId = co.cal_id
			LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dial.tipoResDial_id = tr.tiporesdial_id
			WHERE fecha >= @from AND fecha < @to
			union
			(
			select 
					''''
					,reg.callout_id
					,ccoa.cam_id
					,reg.process
					,ISNULL(cctyp.translatedDesc,'''')
					,ccoa.cal_telefono
					,''''
					,reg.reg_date
					,''''
					,''systemTranslated_Preview'' 		  
					,''''
					,''''
					,''''
					,''''
					,''''
					,ccoa.cal_Key
					,''''
					,''''
					,''''
					,''''
					,''''
					,''''	
					,reg.tPreview
					,reg.userId 
			FROM RegProcessPreviewRecord reg(NOLOCK)
			left join ccoCallsOutSource ccoa (NOLOCK) ON reg.callout_id = ccoa.callout_id
			left join ccTypeProcessPreview cctyp (NOLOCK) ON  cctyp.typeProcess_id = reg.process
			WHERE reg.reg_date >= @from AND reg.reg_date < @to AND reg.process !=7
			)
	
				select distinct cast(codeSip as int) as codeSip,disconnectCause into #codeSip from #dials where codeSip<>'''' and IsNumeric(codeSip)=1
			
				select A.codeSip,A.disconnectCause,B.description into #relationCodeSip from #codeSip A
				inner join DC_Extra B on A.codeSip=B.id
	
		--Inserta informacon de reporte  
			INSERT INTO RepOutDialDetail
				SELECT fecha as [date]
				,case when dials.cal_key is null or  cs.cal_key is null then '''' when dials.cal_key is not null then dials.cal_key else cs.cal_key end cal_key
				,telefono telephone
				,dials.tiporesdial_id as tiporesdialId
				,CASE WHEN dials.tipoResDial_id = 14 THEN ''systemTranslated_CancelledBySystem'' ELSE ISNULL(dials.resultDialDesc, '''') END AS dialResult
				,dials.[cam_id] campaignId
				,ISNULL(RTRIM(LTRIM(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') AS campaign
				,dials.tbusy AS timeMessage
				,DATEPART(yyyy, fecha) year	
				,DATEPART(mm, fecha) month	
				,DATEPART(dd, fecha) day	
				,DATEPART(hh, fecha) hour	
				,DATEPART(mi, fecha) minutes
				,ISNULL(rl.name, '''') listName
				,CASE WHEN answerbit = 1 THEN ''systemTranslated_Charged'' ELSE ''systemTranslated_NotCharged'' END AS billed
				,ISNULL(cs.Dato1, '''') AS data1
				,ISNULL(cs.Dato2, '''') AS data2
				,ISNULL(cs.Dato3, '''') AS data3
				,ISNULL(cs.Dato4, '''') AS data4
				,ISNULL(cs.Dato5, '''') AS data5
				,CASE WHEN dials.[file_moved] = 1 THEN ''systemTranslated_Remoto'' ELSE ''Local'' END AS fileMoved
				,dials.disconnectCause
				,COALESCE(dat.description, descripcion, ''N/A'') DCCustomer
				,dials.dialType
				,TipoTel
				,ISNULL(CallDisposition, ''N/A'') AS CallDisposition
				,ISNULL(califSubDesc, ''N/A'') AS CallSubDisposition
				,ISNULL(csP.Dato6, '''') AS data6
				,ISNULL(csP.Dato7, '''') AS data7
				,ISNULL(csP.Dato8, '''') AS data8
				,ISNULL(csP.Dato9, '''') AS data9
				,ISNULL(csP.Dato10, '''') AS data10
				,ISNULL(csP.Dato11, '''') AS data11
				,ISNULL(csP.Dato12, '''') AS data12
				,ISNULL(csP.Dato13, '''') AS data13
				,ISNULL(csP.Dato14, '''') AS data14
				,ISNULL(csP.Dato15, '''') AS data15
				,dials.tpreview AS preview_Time
				,ISNULL(us.Login,'''')
			FROM #dials as dials
			LEFT JOIN ccoCallsOutSource cs(NOLOCK) ON dials.callout_id = cs.callout_id
			LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dials.tiporesdial_id = tr.tiporesdial_id
			LEFT JOIN ccCamps camps(NOLOCK) ON camps.[cam_id] = dials.[cam_id]
			LEFT JOIN ccRIARegistryLists rl(NOLOCK) ON cs.list_id = rl.list_id
			LEFT JOIN #relationCodeSip dat ON dat.disconnectCause = dials.disconnectCause
			LEFT JOIN ccoCallsPreviewData csP ON (dials.cal_Key = csP.cal_Key AND dials.cam_id = csP.cam_id)
			LEFT JOIN ccUsers us (NOLOCK) ON  us.User_id = dials.UserID

			IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
			IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
			IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;
		END
	'	
	EXEC(@sql)

	set @process = 'SPEC-66 ALTER SP ccspRepOutboundKPI'
	set @sql = '

ALTER PROCEDURE [dbo].[ccspRepOutboundKPI]
		@action as tinyint,
		@from as datetime = null,
		@to as datetime = null
		AS

		SET NOCOUNT ON

		if @from is null
			select @from = convert(datetime,convert(varchar(11),getdate()))
		if @to is null
			select @to = getdate()

		if @action = 1
		begin

			DELETE FROM RepOutboundKPI WITH (ROWLOCK) WHERE DATE >= @from AND DATE < @to

			IF OBJECT_ID(''tempdb..#UniqueRecords'') IS NOT NULL drop table #UniqueRecords
			IF OBJECT_ID(''tempdb..#Connects'') IS NOT NULL drop table #Connects;
			IF OBJECT_ID(''tempdb..#callOut'') IS NOT NULL drop table #callOut;
			IF OBJECT_ID(''tempdb..#Quejas'') IS NOT NULL drop table #Quejas;
			IF OBJECT_ID(''tempdb..#t'') IS NOT NULL drop table #t;
			IF OBJECT_ID(''tempdb..#te'') IS NOT NULL drop table #te;

			create table #UniqueRecords (date datetime, UniqueRecordsCalled int)
			create table #Connects(date datetime, Connects int)
			create table #CallsOut(date datetime, Abandono int, RPC int, PTP int, PK int)
			create table #Quejas(date datetime, Quejas int)
	

			select distinct convert(date,[date]) as date,callKey,telephone into #t from RepOutDialDetail where date between @from and @to
			insert into #UniqueRecords
				select distinct convert(date,[date]),count(*) from #t group by convert(date,[date]) order by convert(date,[date])
	
			select date into #te from RepOutCallsDetail where date between @from and @to and USERID >0 and dialog>0
			insert into #Connects
				select distinct convert(date,[date]) as date,count(*) from #te group by convert(date,[date]) 

			insert into #CallsOut
				select convert(date,date),
					sum(Abandono) as Abandono,
					sum(RPC) as RPC,
					sum(PTP) as PTP,
					sum(PK) as PK
				from(
					select [cal_Inicio] as date,
						case when statusCall_id in (6,7,8) then 1 else 0 end Abandono,
						case when calif_id in (5,6,7,8,9,22,23,24,25,26,29,30,31,32,33,34) then 1 else 0 end RPC,
						case when calif_id in (5,6,7,8,9) then 1 else 0 end as PTP,
						case when calif_id in (46,47,48,49) then 1 else 0 end as PK
					from ccoCallsOut
					where cal_Inicio between @from and @to
				) as temp
				group by convert(date,date)

			insert into #Quejas
				select convert(date,[date]), sum(cuenta) 
				from (
				(select convert(date,[date]) as date,count(1) as cuenta from RepInCallsDetail where date between @from and @to and callStatusId=13 and dispositionId in (5,6,7,8,9,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,29,30,31,32,33,34,48,49) group by convert(date,[date]))
				union all
				(select convert(date,[cal_Inicio]) as date,count(1) as cuenta from ccoCallsOut where cal_Inicio between @from and @to and calif_id in (31) group by convert(date,[cal_inicio]) )
				) as final
				group by convert(date,[date]);

			insert into RepOutboundKPI
			select convert(date,final.date) as date,
				ISNULL(UniqueRecordsCalled, 0) as UniqueRecordCalled,
				sum(DialsAttempted) as DialsAttemted,
				sum(dialsComplete) as DialsCompleteRing,
				sum(Answer) as Answer,
				ISNULL(Connects, 0) as Connects,
				ISNULL(Abandono, 0) as Abandono,
				ISNULL(RPC, 0) as RPC,
				ISNULL(PTP, 0) as PTP,
				ISNULL(PK, 0) as PK,
				ISNULL(Quejas, 0) as Quejas,
				datepart(yyyy,max(final.date)) as year,
				datepart(mm,max(final.date)) as month,
				datepart(dd,max(final.date)) as day,
				datepart(hh,max(final.date)) as hours,
				datepart(mi,max(final.date)) as minutes
			from (
				select date as date,
					1 as DialsAttempted,
					case when dialResultId in (1,2,3,8,11,13) then 1 else 0 end dialsComplete,
					case when dialResultId in (1) then 1 else 0 end Answer
				from RepOutDialDetail
				where date between @from and @to
			) as final
			left join #UniqueRecords a on convert(date,final.date) = convert(date, a.date)
			left join #CallsOut b on convert(date,final.date) = convert(date, b.date)
			left join #Quejas c on convert(date,final.date) = convert(date, c.date)
			left join #Connects d on convert(date,final.date) = convert(date, d.date)
			group by convert(date,final.date), UniqueRecordsCalled, Abandono, RPC, PTP, PK, Quejas, Connects
			order by convert(date,final.date)

			IF OBJECT_ID(''tempdb..#UniqueRecords'') IS NOT NULL drop table #UniqueRecords
			IF OBJECT_ID(''tempdb..#Connects'') IS NOT NULL drop table #Connects;
			IF OBJECT_ID(''tempdb..#callOut'') IS NOT NULL drop table #callOut;
			IF OBJECT_ID(''tempdb..#Quejas'') IS NOT NULL drop table #Quejas;
			IF OBJECT_ID(''tempdb..#t'') IS NOT NULL drop table #t;
			IF OBJECT_ID(''tempdb..#te'') IS NOT NULL drop table #te;
end
	'
	EXEC(@sql)

	set @process = 'SPEC-66 ALTER SP ccspRepMKTIntervalosSalidas'
	set @sql = '
	ALTER PROCEDURE [dbo].[ccspRepMKTIntervalosSalidas] 
@action as tinyint, @from as datetime = null, @to as datetime = null	
AS
SET NOCOUNT ON
if @from is null
	select @from = convert(datetime, convert(varchar(11), getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN
	
	DECLARE @tresRing AS SMALLINT
	EXEC @tresRing = ccspConfigTresRing;						
			
delete RepMKTIntervalosSalida with(rowlock) where date between @from and @to;

IF OBJECT_ID(''tempdb..#tPersonal'') IS NOT NULL drop table #tPersonal
IF OBJECT_ID(''tempdb..#tDisp'') IS NOT NULL drop table #tDisp;
IF OBJECT_ID(''tempdb..#callOut'') IS NOT NULL drop table #callOut;
IF OBJECT_ID(''tempdb..#OutboundCalls'') IS NOT NULL drop table #OutboundCalls;
IF OBJECT_ID(''tempdb..#OutboundCallGroup'') IS NOT NULL drop table #OutboundCallGroup;

select count(distinct user_id) as uid
	,sum(tlog) tlog
,DATEADD(mi, CASE WHEN DATEPART(mi, timegroup_next) in (15,45) THEN - 15 ELSE 0 END, timegroup_next) timegroup_next
into #tPersonal
from TmpSessionTimeGroup
group by DATEADD(mi, CASE WHEN DATEPART(mi, timegroup_next) in (15,45) THEN - 15 ELSE 0 END, timegroup_next)
	
select 
DATEADD(mi, 
case when DATEPART(mi,timeGroupNext)= 15 then -15 
	else 0 end
, timeGroupNext) as timeGroupNext
,sum(case when TipoStatusAge_id=2 then tStatus else 0 end) tnodispo
,sum(case when TipoStatusAge_id=2 then tStatus else 0 end) tdispo
into #tDisp
from tmpccLogAgentesDia
where TipoStatusAge_id in (2,3)
group by DATEADD(mi, 
case when DATEPART(mi,timeGroupNext)= 15 then -15 
	else 0 end
, timeGroupNext) 

	SELECT cal_id,dateStartDetail, dateEndDetail,timegroup_next
		, user_id, ntotal AS Recibidas, nanswer AS [Contestadas], nabnd_dialog AS [Abandonadas], nhangup AS SinAgentes, statusCall_id, tque, 
		txfer, tring, tdialog, tnotes, cal_tMoh
	INTO #callOut
	FROM tmpTimesOutboundData
	
	SELECT lo.cal_id
	,co.cal_id AS callId
	,co.dateStartDetail
	,co.dateEndDetail	
	,CASE WHEN co.statusCall_id = 13 THEN co.timegroup_next ELSE dbo.getTimegroup(DATEADD(ss, tDialing, fecha),1) END AS timegroup_next	
	,Recibidas
	,co.user_id AS userId
	,cam_id AS cam_id
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 2 THEN 1 ELSE 0 END Ocupado
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 3 THEN 1 ELSE 0 END NoContestan
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 4 THEN 1 ELSE 0 END Fax
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 11 THEN 1 ELSE 0 END Buzon
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 5 THEN 1 ELSE 0 END SinTono
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 10 THEN 1 ELSE 0 END NoService
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 8 THEN 1 ELSE 0 END Otro
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 12 THEN 1 ELSE 0 END Congestion
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 13 THEN 1 ELSE 0 END Cancelado
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 1 THEN 1 ELSE 0 END [Contactos] --contactos sistema
	,[Contestadas]
	,CASE WHEN statusCall_id IN (6, 10, 11, 12, 14, 15, 16)
			OR (
				canceledNoAgents <> 0 AND answerbit = 1
				)
			OR ([Abandonadas] > 0) THEN 1 ELSE 0 END AS [Abandonadas]
	,SinAgentes
	,CASE WHEN statuscall_id IN (15, 16) THEN 1 ELSE 0 END AS NoContestadas
	,CASE WHEN statuscall_id IN (11, 10, 12, 14) AND tring <= @tresRing THEN 1 ELSE 0 END AS CortadasRing
	,CASE WHEN statuscall_id IN (11, 10, 12, 14) AND tring > @tresRing THEN 1 ELSE 0 END AS CortadasDespRing
	,[Abandonadas] AS CortadasDlg
	,CASE WHEN statuscall_id = 13 THEN co.txfer + co.tring + co.tdialog + co.tnotes + co.cal_tMoh ELSE 0 END TMO
	,CASE WHEN statuscall_id = 13 THEN 1 ELSE NULL END countStatus13
	,co.tdialog
	,co.cal_tMoh AS TiempoTotalHold
	,co.tnotes
	,co.txfer + co.tring AS TiempoTotalRing
	,co.tque
	,co.txfer + co.tring + co.tdialog + co.tnotes  [Ocupacion]
	,co.statuscall_id
	,co.tring
	,tipoResDial_id
INTO #OutboundCalls
FROM ccologdials(NOLOCK) lo
LEFT JOIN #callOut co
	ON co.cal_id = lo.cal_id
WHERE fecha BETWEEN @from
		AND @to

SELECT 
dateadd(mi, case when datepart(mi,timegroup_next) in (15,45) then -15 else 0 end,timegroup_next) as timegroup_next
,count(distinct userId )as Staff
,sum(Recibidas) as Recibidas
,sum(Ocupado) as Ocupado
,sum(NoContestan) as NoContestan	
,sum(Fax) as Fax
,sum(Buzon) as Buzon
,sum(SinTono) as SinTono
,sum(NoService) as nout_service	
,sum(Otro) as Other	
,sum(Congestion) as Congestion
,sum(Cancelado) as Cancelado
,sum(Contactos) as contacted
,sum(Contestadas) as Answered
,sum(Abandonadas) as abandonedCalls
,sum(SinAgentes) as SinAgentes
,sum(NoContestadas) as NoContestadas
,sum(CortadasRing) as nabndxferout
,sum(CortadasDespRing) as nabndringout
,sum(CortadasDlg) nabnddlgout
,isnull(SUM([Ocupacion])/nullif(COUNT(case when statuscall_id=13 then 1 end),0),0)  as TMO
,isnull(SUM(tdialog)/nullif(COUNT(case when statuscall_id=13 then 1 end),0),0) as promDialogo
,sum(TiempoTotalHold) as holdTime
,sum(tnotes) as tnotesout
,sum(TiempoTotalRing) as tringout
,isnull(sum(tque)*1.0/nullif(COUNT(case when statuscall_id=13 then 1 end),0),0)  as avrAnswer
, case when count(case when statusCall_id=13 then 1 end ) = 0 or count(case when tipoResDial_id=1 then 1 end) = 0 then 0.00
else convert(decimal(10,2),sum(Abandonadas)*100.0/count(case when tipoResDial_id=1 then 1 end) ) end as AvgAbandon
,Cam_id
,sum([Ocupacion]) as sumTime
INTO #OutboundCallGroup
FROM #OutboundCalls co
group by dateadd(mi, case when datepart(mi,timegroup_next) in (15,45) then -15 else 0 end,timegroup_next),cam_id



insert into RepMKTIntervalosSalida
select convert(datetime, convert([date],oc.timegroup_next,121)) as [date]
,convert(varchar(5),oc.timegroup_next,108) rango1
,convert(varchar(5),dateadd(mi,30,oc.timegroup_next),108) rango2
,oc.Staff
,oc.Recibidas
,oc.Ocupado
,oc.NoContestan
,oc.Fax
,oc.Buzon
,oc.SinTono
,oc.nout_service
,oc.Other
,oc.Congestion
,oc.Cancelado
,oc.contacted
,oc.Answered
,oc.abandonedCalls
,oc.SinAgentes
,oc.NoContestadas
,oc.nabndxferout
,oc.nabndringout
,oc.nabnddlgout
,oc.TMO
,oc.promDialogo
,oc.holdTime
,oc.tnotesout
,oc.tringout
,isnull(d.tdispo,0) as readyTime
,isnull(d.tnodispo,0) as notReadyTime
,isnull(l.tlog,0) as Personal
,oc.avrAnswer
,isnull(case when l.tlog=0 then 0.00 else convert(decimal(10,2), (oc.tnotesout+d.tnodispo)*100.0/L.tlog) end,0.00) as Reductor
,oc.AvgAbandon
,case when l.tlog is null or l.tlog =0  then 0.00 else convert(decimal(10,2), oc.sumTime*100.0/L.tlog,0) end as OcupacionCOPC
,oc.Cam_id
from #OutboundCallGroup oc
left join #tPersonal L on oc.timegroup_next=L.timegroup_next
left join #tDisp d on oc.timegroup_next=d.timeGroupNext

IF OBJECT_ID(''tempdb..#tPersonal'') IS NOT NULL drop table #tPersonal
IF OBJECT_ID(''tempdb..#tDisp'') IS NOT NULL drop table #tDisp;
IF OBJECT_ID(''tempdb..#callOut'') IS NOT NULL drop table #callOut;
IF OBJECT_ID(''tempdb..#OutboundCalls'') IS NOT NULL drop table #OutboundCalls;
IF OBJECT_ID(''tempdb..#OutboundCallGroup'') IS NOT NULL drop table #OutboundCallGroup;
END


	'
	EXEC(@sql)

	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

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
