/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2016/08/09
Description:
	Alter SP -- ccsp_SaveStatusAgent cuando es logout y guarda el tiempo dialogo ccoCallOut y ccCallin
	Alter SP -- ccsp_AgentSetCallStatus cuando es llamada manual resetea el cal_inicio a la hora que contestea llamada manual efectiva
	Alter SP  -- ccsp_RIACATMenu para activar reportes viejos

Database: CCenterRia
Required version: 119.04

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 129 sin fix
set @versionfix = 5
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and @actualVersionFix = @versionfix-1
	begin
		begin tran
		begin try

		set @process = 'drop sp -- [dbo].[ccsp_isFinished]'
		set @Sql= 'if exists (select * from sys.procedures where name = ''ccsp_isFinished'') DROP PROCEDURE [dbo].[ccsp_isFinished]'
		EXEC(@Sql)

		set @process = 'drop sp -- [dbo].[ccsp_RIAConfEspec]'
		set @Sql= 'if exists (select * from sys.procedures where name = ''ccsp_RIAConfEspec'') DROP PROCEDURE [dbo].[ccsp_RIAConfEspec]'
		EXEC(@Sql)

		set @process = 'drop sp -- [dbo].[ccsp_SaveLogoutLastState]'
		set @Sql= 'if exists (select * from sys.procedures where name = ''ccsp_SaveLogoutLastState'') DROP PROCEDURE [dbo].[ccsp_SaveLogoutLastState]'
		EXEC(@Sql)

		set @process = 'create table ---------- optionIVR'
		set @Sql= ' if not exists (select * from sys.tables where name = N''optionIVR'')
  create table [optionIVR] ([dtmf] varchar(20),[tag] varchar(20),[camID] int ,[type] int)'
  EXEC(@Sql)

  		set @process = 'create INDEX ccRIAWorkGroupUsersConsulta.IX_ccRIAWorkGroupUsersConsulta'
		set @Sql= 'If not exists(SELECT * FROM sys.indexes WHERE name=''IX_ccRIAWorkGroupUsersConsulta'' AND object_id = OBJECT_ID(''ccRIAWorkGroupUsersConsulta''))
begin
	CREATE NONCLUSTERED INDEX [IX_ccRIAWorkGroupUsersConsulta] ON [dbo].[ccRIAWorkGroupUsersConsulta]([IDWG] ASC,[User_id] ASC)
	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80)
	ON [PRIMARY]
end'
		EXEC(@Sql)

		set @process = 'Add Column ---- ccinbound.editableDtmf'
		set @Sql= 'if not exists (select * from sys.columns where name = N''editableDtmf'' and Object_ID = Object_ID(N''ccinbound'')) alter table ccinbound add editableDtmf int'
		EXEC(@Sql)

		set @process = 'Add Column ---- ccCamps.funcEspDtmf'
		set @Sql= 'if not exists (select * from sys.columns where name = N''funcEspDtmf'' and Object_ID = Object_ID(N''ccCamps'')) alter table ccCamps add funcEspDtmf int '
		EXEC(@Sql)


		set @process = 'Alter Column --- optionivr.dtmf'
		set @Sql= 'if exists (select * from sys.columns where name = N''dtmf'' and Object_ID = Object_ID(N''optionivr'')) alter table optionivr alter column dtmf varchar(20)'
		EXEC(@Sql)

		set @process = 'Alter Column --- optionivr.tag'
		set @Sql= 'if exists (select * from sys.columns where name = N''tag'' and Object_ID = Object_ID(N''optionivr'')) alter table optionivr alter column tag varchar(20)'
		EXEC(@Sql)

				set @process = 'Adding currentStatus column to ccLogAgentesDia '
		set @Sql= 'if not exists (select * from sys.columns where name = N''currentStatus'' and Object_ID = Object_ID(N''ccLogAgentesDia'')) ALTER TABLE ccLogAgentesDia ADD currentStatus int'
		EXEC(@Sql)

		set @process = 'Adding callID column to ccLogAgentesDia '
		set @Sql= 'if not exists (select * from sys.columns where name = N''callID'' and Object_ID = Object_ID(N''ccLogAgentesDia'')) ALTER TABLE ccLogAgentesDia ADD callID int'
		EXEC(@Sql)

		set @process = 'INSERTAR EN LA TABLA DE ccMenus EL REPORTE DE SESSIONES POR INTERVALO'
		set @Sql= 'if not exists (select * from ccMenus where menu_id = 2060 and type=3)
INSERT INTO [dbo].[ccMenus]([menu_id],[menu_descrip],[parent],[Nivel],[ordengral],[type],[HelpSWF],[release])
VALUES(2060,''Sesiones por intervalo|Sessions by Interval'',2000 ,''B'',2,3,'''',''9032ee7929290765e01291a25dca0a7052d8521c779ad007529a9f3a460640798af7a60c5a2b63c4dd46b7aefa9aab77'')'
		EXEC(@Sql)

		set @process = 'Insert ccTipoStatusAgente'
		set @Sql= 'if not exists(select * from ccTipoStatusAgente where TipoStatusAge_id in(25,26)) begin
	insert into ccTipoStatusAgente (TipoStatusAge_id,descripcion) values(25,''Transferencia Fallida'')
	insert into ccTipoStatusAgente (TipoStatusAge_id,descripcion) values(26,''Ringing Fallida'')
end'
		EXEC(@Sql)

		set @process = 'Update ccmenus -- Reports Old Column Release'
		set @Sql= 'update ccmenus set release=''96d529790ccfca0b873be2921b21fc8e'' where menu_id=2000 and type=2
update ccmenus set release=''863c1b4be7789b285c2999b501311d7e'' where menu_id=2010 and type=2
update ccmenus set release=''26f540a73d36cea7632922a967892fbc'' where menu_id=2020 and type=2
update ccmenus set release=''21725d4ab1d73f91bea9d05c041d16e72ff678eb4582b2364cb5a262a0a0b6537c09e141b43ca8cb83b1af79ddaee9fa'' where menu_id=2030 and type=2
update ccmenus set release=''3cfc9a33dc5200222201e875d19251c976eae7d305214c2ed2e3128774bbaa6c'' where menu_id=2040 and type=2
update ccmenus set release=''0595f9a894803009e62c5a234aa2232d662b2c7d925be7c5955995853f4e1459'' where menu_id=2050 and type=2
update ccmenus set release=''8ef05a0599ad8a0ad4bcace93d3da032f50b53ac2086c961607a3085ad1a03cc31ea83ea698de717f5a8a71507a7dac5'' where menu_id=2060 and type=2
update ccmenus set release=''3efdb2f562082f73ee97f38d181a85b7acad7f063c3d7b522ee58b1551fef57c'' where menu_id=2070 and type=2
update ccmenus set release=''0f10d0f3975fea415f64116b08b3f0f4158b1a1c1255a581f66da60fdbb9f92231022e099f594c858ed05b8ad8b5ef79'' where menu_id=2080 and type=2
update ccmenus set release=''451fb584247906528fa2581818dea27868687fa25b5f2533257ae7ff51db6f58'' where menu_id=3000 and type=2
update ccmenus set release=''88671a67a73c950bc8e1af9f0e227c0f0f64ff6cac783bf28d06ea68775a3a27d990d4d2fd470e6a5e8eb40953729a49'' where menu_id=3010 and type=2
update ccmenus set release=''1621aa1eb065614348e1ef0ab4e8cfe61d2e482a8fe531d37f877a9aca9c54ef6cf639b69af876581c52e4fe2ce0e51d'' where menu_id=3020 and type=2
update ccmenus set release=''38e29518dc9e10cbe6c3c82acc2803f793a75d3ad08aef54bd153cb9f6b5e5c28e01b6ed0a348c54dc173fcdca8c3eed'' where menu_id=3030 and type=2
update ccmenus set release=''6d3714df6d975d1bf016b4e69cf7e3e2bbf1a6c032facf562f476c502f09aa1c'' where menu_id=3040 and type=2
update ccmenus set release=''76c88f6ae0d8fb18929149b4bb29d9aa9eefe37d883b01aced6c745dde316bb6d82dfe33ee8a1b3e223f1b0c5543e02e'' where menu_id=3050 and type=2
update ccmenus set release=''954686f810f48c79748db2363a49690933f1810031ae0fb22af8ecaebc6f48b6740178edc59d9057a7bbae250c2ab8c663239a0425081a583f62e6ca9117cc7b'' where menu_id=3060 and type=2
update ccmenus set release=''90b4263a8fc29731739fb4ead76a7a9a9a7e9b5dd04728a62f59293841b5e5e2'' where menu_id=3070 and type=2
update ccmenus set release=''26f540a73d36cea7632922a967892fbc'' where menu_id=3080 and type=2
update ccmenus set release=''7657fe7b3c16fd849a1b96da2b3a1ab4710ecf89f08f2468489b14137f017b1c'' where menu_id=3081 and type=2
update ccmenus set release=''58d4dc99cd15d638724baa23ced7904a92f69511abfd5adbbf02d9e37ae98603'' where menu_id=3082 and type=2
update ccmenus set release=''dfe863a9b40b5e3e799358a093aa026ab804aaa55991bce93b22625cc4e91f19'' where menu_id=3090 and type=2
update ccmenus set release=''e05ac39c9fb6448b7bcb456c8ae4b13134b42504c4692b8fcbabf774a1ec529669fe7ff7e6befca5cd22058226f98bb1eb172d6ce7638e9946fa52040be1135a173de3af7178b270b9dee838b00c37fd'' where menu_id=3100 and type=2
update ccmenus set release=''618eb9b6a71e84267143b7cedc82d1964ff1c1127f25547f8d2ffc613dbec777'' where menu_id=3110 and type=2
update ccmenus set release=''6253839f06a12a489609b104cac5b6aa4db076d1ad3a3f7a684f8bfa95a33f5e'' where menu_id=3120 and type=2
update ccmenus set release=''2496950a0257e0ca5abb81a1d48d0bfb0567ed607d5550088272a02a04a93cd3'' where menu_id=3130 and type=2
update ccmenus set release=''70b4a3d32ba74c0e7cf258a505a2a87f75ebc1d90789d54b9326ad55ca032624'' where menu_id=3140 and type=2
update ccmenus set release=''9a0bb5a8b5b598b4a2ebd4562fb8af7192c99f17ad6ddfcbcd31f72537138d8ae9712b5e09c4dff7325de4c6139fb7333612685c7cea151a5099b1fe060057aa'' where menu_id=3150 and type=2
update ccmenus set release=''76c88f6ae0d8fb18929149b4bb29d9aad066bf63d912dc864cca19a9f824dd5dd8768fdc7ea8c8efd251951704d25f0b69eae4e20a59695db8c29d0a8557485c234ecb44b68cbec22e7a90432f489c0d6c5ef29d3f2963a3c3220f4184bb7a43'' where menu_id=3160 and type=2
update ccmenus set release=''54d108e6439d9428e2b8fd3e9f91fdee03577c2655add923615496462aab1dd3318084eb79e5d7ecba4f65143d96d0d26b5287dd2ae4891cfeea1bc3606d723e9ae56f1c78864b39ec4fc829356c9dca'' where menu_id=3170 and type=2
update ccmenus set release=''c7f873bbb75c1ce5d906102169b7f56d79de2c5fe7227203c412f7b4de4fc181e3fb0b8cb4c5742fbbf208400e193657'' where menu_id=3180 and type=2
update ccmenus set release=''76c88f6ae0d8fb18929149b4bb29d9aa41761df4a111ee1a6c510f81ad55be1c40903a9b1941a4f98307fa2f631722b07cfe3df4480339edcf403194403d40eea4da3beb1169e8e268c78e444c49cdd8'' where menu_id=3190 and type=2
update ccmenus set release=''54d108e6439d9428e2b8fd3e9f91fdeed1b11ac78678f3722a4188412fb52e047c18c661a1894f5f9debd88c7a9bf81a88623363c4386926d5a0b31dd7ead535'' where menu_id=3200 and type=2
update ccmenus set release=''ee6c372bb76697296ddf9c822cf0f0413a909d990e67e9cd23d0b816182cde7d16cc33daa29c6ea3c2b28be8f4052971'' where menu_id=3210 and type=2
update ccmenus set release=''1daa38c5c8f28a1aa8d4d98293b41be12544c5b63f7ebc0b0adde3906df6ce7818a384b387507e79c91c2adfbd3e9581'' where menu_id=3220 and type=2
update ccmenus set release=''f0585156234b0e8d9141b6cf39130af21f6d2249c874af45fafba6ebe6843be7'' where menu_id=4000 and type=2
update ccmenus set release=''9abbbf7b91aab9c9f1cbe150444da7a931e35e3881dc842b11a71c8a4b785630c0a47cc99131b3f17650bf4396c22bb5'' where menu_id=4010 and type=2
update ccmenus set release=''88671a67a73c950bc8e1af9f0e227c0f3d1315d01f0907f4391b6d4584edb9f26497c2de39654acee45d58cc6ec0ee292edc74dd6bc3d2b3c138209fafc2db82'' where menu_id=4020 and type=2
update ccmenus set release=''1621aa1eb065614348e1ef0ab4e8cfe61d2e482a8fe531d37f877a9aca9c54ef6cf639b69af876581c52e4fe2ce0e51d'' where menu_id=4030 and type=2
update ccmenus set release=''e3d1c14ea7f6969dbeb3b7d31a883b10ea75e5893f001ba9b492a4bb9f73a98e65eb6cd55f9fbb60cad1e3ae5e957d6714f12a0588357af6dc50a9105440e9e7'' where menu_id=4040 and type=2
update ccmenus set release=''54d108e6439d9428e2b8fd3e9f91fdee001f6469b69e5f71681ee359260e39b22e0ce801af939ee2b630c0f95c4949a0'' where menu_id=4050 and type=2
update ccmenus set release=''766e1f5ad7ce194788f00d131c62cd14f74167aced2e47e65b532c3a0d6647df19d304f97bb13b8deae813f4dc2a2a77'' where menu_id=4060 and type=2
update ccmenus set release=''c57acbf5ca01e1fc9a94ce487f5b736331ba952a034f112379110f8f0d64c76c'' where menu_id=4070 and type=2
update ccmenus set release=''614fbe0bdc630291e3af7432e9d2f67874029eed65c789e8da646e5aa85feead'' where menu_id=4071 and type=2
update ccmenus set release=''72b3ee39e102898000f9f6c25f1febeb79953daf3e491b7c12c79e132a5b0fd8'' where menu_id=4072 and type=2
update ccmenus set release=''65c4e3450ca86ff8f15d7838f1500d89f505d18b6a82ccd3208409060d602341'' where menu_id=4073 and type=2
update ccmenus set release=''21d5d320c13bf1a21fdf8ea3f2ca1fd60e14a6aeeaf35c9b36d2dd476f82c7a89a762068eda2e25900d2b7a056212bed1abcba9cfce023e31d5dfb834f77ddb5'' where menu_id=4080 and type=2
update ccmenus set release=''755ae3e86705e3a4f94ce265ab8bffb567361e38b7070a25c82ab1764677b1521fa51c0b2acbb9b53cf08be422b3cb9cba6759f96336c6a4c0eb505c8d052109'' where menu_id=4090 and type=2
update ccmenus set release=''e3d1c14ea7f6969dbeb3b7d31a883b100ad101ff94fb4489328b1a8f994e054c0af17779a3ee664560dcee2696d1c5e9a0f6d49ea0604901376752572f5ecf7a99ab0475dbc9afa828f5b22342826bf4281c1c83f0a8273b7a2b173408fc21c4'' where menu_id=4100 and type=2
update ccmenus set release=''79edd1fe6e5b7d07e863765e1aea65bb1b07b8f8d096f08ba4a78a54aa5503235e15d6f7a9c9ae3de147e2180dc20956c0faeb5974e2c463f77dcce9f2ee17c3'' where menu_id=4110 and type=2
update ccmenus set release=''79edd1fe6e5b7d07e863765e1aea65bbe79131aaba618e8dc650f6377f1936b5a195cc63fb3dab58e85899fe009ee6d4ef8a0785812410cfc5d6feaf5a80edda65ae51dd9264c5a071f682a452d70b37'' where menu_id=4120 and type=2
update ccmenus set release=''fee6c9587ae675c9822e67af27a6517c52d4141cb017eb1c2ef391de6ab166af4a00a303132d9938f7c0854aef14547f6a20e934fa03188f4a15528e87da9300'' where menu_id=4130 and type=2
update ccmenus set release=''54d108e6439d9428e2b8fd3e9f91fdee03577c2655add923615496462aab1dd3318084eb79e5d7ecba4f65143d96d0d26b5287dd2ae4891cfeea1bc3606d723e9ae56f1c78864b39ec4fc829356c9dca'' where menu_id=4140 and type=2
update ccmenus set release=''79edd1fe6e5b7d07e863765e1aea65bba6cad002ae4bac70580b2b10225b3d577c935d54ab32bd87d6957a262a75bae8e80d556498fd63925f918c28a9fd7599'' where menu_id=4150 and type=2
update ccmenus set release=''fee6c9587ae675c9822e67af27a6517c000df78aa2fe349c0a53cd8c7ee4594d8c04be2c6acbc833ce6eb2956502b6bc'' where menu_id=4160 and type=2
update ccmenus set release=''54d108e6439d9428e2b8fd3e9f91fdeed1b11ac78678f3722a4188412fb52e047c18c661a1894f5f9debd88c7a9bf81a88623363c4386926d5a0b31dd7ead535'' where menu_id=4170 and type=2
update ccmenus set release=''413a290efc0a4bde33385ad101198bbbf60611d958a16e810287332dff0a4f925f9a037aadd848cc71aec9196a3a935d'' where menu_id=4180 and type=2
update ccmenus set release=''1daa38c5c8f28a1aa8d4d98293b41be12544c5b63f7ebc0b0adde3906df6ce7818a384b387507e79c91c2adfbd3e9581'' where menu_id=4190 and type=2
update ccmenus set release=''96a2eaa1909b9af1cc7e2b33784e45e6aad0715698e9d5c3316faaf4c04f0d9f'' where menu_id=4200 and type=2
update ccmenus set release=''f5ac718eba2bea2c7e42fc06a4133648617d0a0fd0007ee0f94f162a3059b1e5'' where menu_id=4210 and type=2
update ccmenus set release=''93a41caf4f2dd0c1f6e0bb1ad57526d0'' where menu_id=6000 and type=2
update ccmenus set release=''f7adec3242a59f86dc4f3a8072e5719494b8cdf81e2e17efb63b081df73a98fb'' where menu_id=6010 and type=2
update ccmenus set release=''00a21455609916b202052d466a352b5e055fa9c97a6702927ccbb25f648d1154'' where menu_id=6020 and type=2
update ccmenus set release=''71a48590ceb2883c82c98591972c86e9e44e423521bed45ada7a405afc9ded0c09e70d5eaefed48b04b1a1b311318bb9'' where menu_id=6030 and type=2
update ccmenus set release=''15c4927a18daca287dd9c826d6b1ee7e0f537b88dd19607d17a04d1ce2ed9779'' where menu_id=6040 and type=2
update ccmenus set release=''9069f719716240d7b738cd6f41a60f032805b33f9a7604926f36ee5899fa63e8'' where menu_id=8000 and type=2
update ccmenus set release=''af27c3de5996ed54fc284889ae4c64c5ac3d0385f57d6836f90f84effa76f96526d8e6cebca8f703fc83a37365452f59'' where menu_id=8010 and type=2
update ccmenus set release=''af27c3de5996ed54fc284889ae4c64c5bfd689ad924ed23e909750b5470193a28dd1176db39e7c7bee9583f01f19ba559bd688a3ac5c3ef90d4aaaa180ad5476'' where menu_id=8020 and type=2
update ccmenus set release=''af27c3de5996ed54fc284889ae4c64c5765fa9608a5a6d7ef128fcc0185b2c04007b2b4b868070061a84e9d349d61d7ac2617c56b3138cd334bd6cc617f7eb78'' where menu_id=8030 and type=2'

	set @process = 'Create SP -- [dbo].[ccsp_isFinished]'
	set @Sql= 'CREATE PROCEDURE [dbo].[ccsp_isFinished]
@tabla int,
@id int,
@result int output
AS
begin
	declare @time int
	if @tabla=0 begin
		set @time=(select cal_tDialog from ccoCallsOut where cal_id=@id)
	end
	else begin
		set @time=(select cal_tDialog from ccCallsIn where cal_id=@id)
	end

	if @time>0 begin
		set @result=0
	end
	else begin
		set @result=1
	end
end'
		EXEC(@Sql)

		set @process = 'Create SP -- [dbo].[ccsp_AgentLogINOUT]'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_AgentLogINOUT]
@UserID smallint,
@Extension varchar(7)=null,
@Computer varchar(20)=null,
@TipoMov tinyint,	-- 0= LogOut,  1=LogIN,	3=Consulta
@fecha datetime=null
AS
set nocount on
if @fecha is null set @fecha=getdate()

declare @hourlogin   varchar(8)
declare @sessionsecs int
declare @sessiontime varchar(8)
declare @fecha_ini datetime

IF  @TipoMov=1
 BEGIN
	Insert ccLogLogIn ( User_id, Extension, TipoMov,fecha ) Values( @UserID, @Extension, 1, @fecha)
	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID)	VALUES( @UserID, 0, 0, @fecha,0,0,1,0)

	Update c Set User_id=@UserID from ccPosicion c WITH (INDEX (IX_ccPosicion)) Where Computer =@Computer
	update c set user_id = 0 from ccPosicion c WITH (INDEX (IX_ccPosicion_2)) where Computer <> @Computer and user_id = @UserId
	update ccUsers set TipoStatusAge_id=3 where User_id=@UserID

	if exists(select valor from ccSettings where tipo=''AGT'' and Status=''1'' and setting_id=''53'' and valor=2)
	 begin
	 	if not exists (select axLic_Desc from axLicG729_Data where axLic_Status=1 and pos_id in (select pos_id from ccPosicion Where Computer =@Computer or user_id = @Userid))
		 begin
	 		raiserror(''Error. Without License'', 18, 1)
			return(0)
		 end

		update axLicG729_Data set axLic_Status=2 where axLic_Status=1 and pos_id in (select pos_id from ccPosicion Where Computer =@Computer or user_id = @Userid)
		select ''0'' CPLic
		return(0)
	 end

	return(0)
 END

IF @TipoMov=0
 BEGIN
	Insert ccLogLogIn ( User_id, Extension, TipoMov, fecha ) Values( @UserID, @Extension, 0, @fecha )
	Update c Set User_id= 0 from ccPosicion c WITH (INDEX (IX_ccPosicion_2)) Where Computer =@Computer or user_id = @Userid
	update ccUsers set TipoStatusAge_id=0 where User_id=@UserID

	if exists(select valor from ccSettings where tipo=''AGT'' and Status=''1'' and setting_id=''53'' and valor=2)
	 begin
		update axLicG729_Data set axLic_Status=0, pos_id=null, fecha_log=null where pos_id in (select pos_id from ccPosicion Where Computer =@Computer or user_id = @Userid)
	 end

	return(0)
 END

IF @TipoMov=3
 BEGIN
    select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

	select @hourlogin = convert(varchar(8), isnull(min(fecha), getdate()), 114)
	       from ccLogLogin where TipoMov=1 and user_id=@UserID and fecha >= @fecha_ini

    SELECT @sessionsecs = isnull (case
			WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0
			THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))
			ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) +
			         convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
			END, 0)
		FROM ccLogLogin where user_id=@UserID and fecha > dateadd(hh, -10, getdate())

    SELECT @sessiontime = RIGHT(''0'' + CONVERT(varchar(6),  @sessionsecs / 3600),       2) + '':'' +
                          RIGHT(''0'' + CONVERT(varchar(2), (@sessionsecs % 3600) / 60), 2) + '':'' +
                          RIGHT(''0'' + CONVERT(varchar(2),  @sessionsecs % 60),         2)

    select ''HourLogin'' = @hourlogin, ''SessionTime'' = @sessiontime, ''SessionSecs'' = @sessionsecs
	return(0)
 END'
		EXEC(@Sql)

		set @process = 'CREATE SP -- ccsp_SaveLogoutLastState'
		set @Sql= 'CREATE PROCEDURE [dbo].[ccsp_SaveLogoutLastState]
@UserID smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus int,
@TipoCall  tinyint,
@call_id int=0,
@tDialog int =0 ,
@Extension varchar(7)=null,
@Computer varchar(20)=null,
@fecha datetime=null
AS
set nocount on

if @fecha is null set @fecha=getdate()

exec ccsp_AgentLogINOUT @UserID=@UserID,@Extension=@Extension,@Computer=@Computer,@TipoMov=0,@fecha=@fecha
exec ccsp_SaveStatusAgent @User_id=@UserID,@TipoStatusAge_id=@TipoStatusAge_id,@TipoNotReady=@TipoNotReady,@tStatus=@tStatus,@TipoCall=@TipoCall,@Camp=0,@callout_id=0,@call_id=@call_id,@isLogout=1,@tDialog =@tDialog,@Fecha4=@fecha
'
		EXEC(@Sql)



set @process = 'Create SP -- [dbo].[ccsp_RIAConfEspec]'
		set @Sql= 'CREATE PROCEDURE [dbo].[ccsp_RIAConfEspec]
@User_id int
AS
set nocount on
/****
Conexion Info Email In
	protocol|server|ssl|port|cleanMail|revisionTime
Conexion Info Email Out
	serverOut|portOut|tls|sslOut
Conexion Info Twitter
	usuarioID|token|tokenSecret|time|daysTwitterRecord
***/
select  A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat mode, A.inactiveChatTime, A.maxChats, isnull(A.chatDomain,'''') chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
isnull(A.startStopRecording,0) startStopRecording
,isnull(B.name,'''') as nameMail,isnull(B.conexionInfo,'''') as conexionInfo,isnull(B.connUser,'''') as connUser,
isnull(B.ConnPass,'''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage,
isnull(B.IsActive,0) as Active, isnull(B.answerTimeOut,0) as answerTimeOut,
case when A.cam_id > 0   and C.callsBySurvey=3 then A.callBackSurveyAgent else 0 end callBackSurveyAgent,
case when A.cam_id > 0  and C.callsBySurvey=3 then A.callBackSurveyClient else 0 end callBackSurveyClient,
case when A.cam_id > 0  and C.callsBySurvey=3 then 1 else 0 end isRelationSurvey,
isnull(A.agts_notavailable,'''') as agts_notavailable,
isnull(nameTwitter,'''') nameTwitter,isnull(userTwitter,'''') userTwitter,isnull(numMessagesTwitter,3) numMessagesTwitter,
isnull(timeAlertMessageTwitter,10) timeAlertMessageTwitter,isnull(ActiveTwitter,0) ActiveTwitter,isnull(answerTimeOutTwitter,10) answerTimeOutTwitter,
--usuarioID|token|tokenSecret|time|daysTwitterRecord
isnull(conexionInfoTwitter,''usuarioID|token|tokenSecret|1|0'') conexionInfoTwitter
,isnull(closeConversationTimeTwitter,3) closeConversationTimeTwitter,isnull(closeConversationTime,3) closeConversationTimeEmail
,isnull(A.editableDtmf,0) as editableDtmf
from ccInbound A
left join ContactMeanIn B on A.inbound_id=B.inboundId and B.meanContactTypeId=1
left join ccCamps C on C.cam_id=A.cam_id
left join (
select D.inboundId,
D.name as nameTwitter,D.connUser as userTwitter,D.numMessages as numMessagesTwitter,
D.timeAlertMessage as timeAlertMessageTwitter,
D.IsActive as ActiveTwitter, D.answerTimeOut as answerTimeOutTwitter,D.conexionInfo as conexionInfoTwitter,
closeConversationTime as  closeConversationTimeTwitter
from ContactMeanIn D
where D.meanContactTypeId=2) D on A.Inbound_id=D.inboundId
where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 4))
return(0)
set nocount off'
		EXEC(@Sql)

		set @process = 'Alter SP -- ccsp_AgentSetCallStatus'
		set @sql='ALTER procedure [dbo].[ccsp_AgentSetCallStatus]
@callout_id int,
@cal_id int,
@TipoCall tinyint,	-- 1= IN,  2=Out
@TipoMov tinyint,	-- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
@cal_tXfer tinyint=0,
@cal_tring  smallint=0,
@user_id smallint=0,
@extension varchar(5)='''',
@isChatCall bit = 0
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
		if @TipoMov = 4 begin
			Update ccoCallsOUT with(rowlock) Set cal_Inicio=getdate(), statusCall_id=13, cal_manual=case when @isChatCall=1 then 3 else cal_manual end Where cal_id=@cal_id
		end
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

		--select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono
		--from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
		--where callout_id = @callout_id
		--and statusCall_id = 13
		--and cal_id = @cal_id

		--select @surveycamid = isnull(surveycamid,0) from cccamps where cam_id = @cam_id

		--if @surveycamid > 0
		--	begin
		--		if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100
		--		begin
		--			insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
		--			values(right((cast(@cal_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,1, dateadd(mi, 6, getdate()))
		--		end
		--	end

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

	DELETE ccoWorkingTable with(rowlock) WHERE callout_id in (select distinct(callout_id) from ccRIAUpdateCallBack_Abandon with(rowlock) where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x

	--select @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani
	--from ccCallsIN with(index(IX_ccCallsIn_6),nolock)
	--where cal_id = @cal_id
	--and statusCall_id = 13

	--select @surveycamid = isnull(cam_id,0) from ccinbound where inbound_id = @inbound_id

	--if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
	--begin
	--	if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100
	--	begin
	--		insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
	--		values(right((cast(@cal_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,1, dateadd(mi, 6, getdate()) )
	--	end
	--end

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
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_SaveStatusAgent'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus int,
@TipoCall  tinyint,
@Camp smallint,
--@isTransferSurvey bit=0, --0 Callback, 1 Realiza Transferencia inmediata
@callout_id int=0,
@call_id int=0,
@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog int =0 ,
@currentStatus int =-2,--NUEVO PARÁMETRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null
AS
if @Fecha4 is null set @Fecha4 = getdate()

if @TipoCall > 0 set @TipoCall = @TipoCall - 1

if (@User_id > 0 ) begin

	declare @cam_id int,@surveycamId int
	declare @cal_telefono varchar(30)
	declare @cal_key varchar(20)
	declare @inbound_id int
	declare @callBackSurveyClients bit
	declare @cal_whoHung tinyint
	declare @cal_tDialog int
	declare @cal_tNotas int
	declare @cal_tNotaOri int
	declare @tMinAVRS smallint
	set @cal_tNotas =0
	set @cal_tNotaOri=0
	--4 Dialog,6 Notas, 27 Notas Fallida
	if @TipoStatusAge_id in (4,6,27) and @call_id>0 begin
		if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
		if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


		if @TipoCall = 0 begin --IN
			select @Camp=Inbound_id, @cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas, @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
						from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13

			if @cal_tDialog = 0 and @tDialog >0  and @isLogout=1  begin
				update ccCallsIN with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas where cal_id = @call_id and statusCall_id = 13
			end
		end
		else begin --OUT
			select  @cam_id = cam_id,@cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas from ccoCallsOut where cal_id = @call_id
			set @Camp=@cam_id

			if @cal_tDialog = 0 and @tDialog>0 and @isLogout=1  begin
				update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas where cal_id = @call_id and statusCall_id = 13
			end
		end

		select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

		if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1
		begin
			insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
		end

		if @TipoStatusAge_id in(6,27)  and @isLogout=1  begin
			--Valida que el agente no pudo guardar el status antes de desloguear
			if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
				INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
		end


	end


	if (@TipoStatusAge_id=4) begin-- 4 = Dialogo
		declare @tStatus3 int, @Fecha3 datetime
		select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
		insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
		select @User_id, cam_id, datediff(ms, dateadd(ss, -@tStatus3, @Fecha3), dateadd(ss, -@tStatus, @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
		from cccampsagente where user_id = @User_id


		---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
		if @call_id>0 begin
			if @TipoCall = 0 begin --IN

					select @surveycamid = isnull(cam_id,0),@callBackSurveyClients = callBackSurveyClient  from ccinbound where inbound_id = @inbound_id

					if @surveycamId>0  and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
						if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
							begin
								if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100
								begin
									insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
									values(right((cast(@call_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()) )
								end
							end
					end
			end	--@TipoCall = 0
			else begin	--OUT



				select @surveycamId = isnull(surveycamid,0),@callBackSurveyClients= callBackSurveyClient from cccamps where cam_id = @cam_id
				select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono,@cal_whoHung=cal_whoHung
					from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
					where callout_id = @callout_id and statusCall_id = 13 and cal_id = @call_id

				if @surveycamId>0 and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
					if (select surveyPctg from ccCamps where cam_id = @surveycamId) >= rand() *100
					begin
						insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
						values(right((cast(@call_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()))
					end
				end
			end
		end--@isTransferSurvey = 0 and @callout_id>0


	 end


	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)	VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )


	if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
	begin
		INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )

		---Para Agente RIA: OAYC
		INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )
	end

	-- Actualiza para reporte de tiempos especiales (Boan)
	if @Camp > 0
		begin
			if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesDia with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end

			if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesNotReady with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
		end
end'
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_RIACATMenu'
		set @Sql= 'ALTER procedure [dbo].[ccsp_RIACATMenu]
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
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenusChat tinyint
Declare @MenuMail tinyint
Declare @MenuCRM tinyint

set @MenuMail=0
set @MenuCRM = 0

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155
select @MenuCRM = valor from ccsettings where setting_id = 168

---Mail MenuId (81)
if @Type=1
begin
	if @ReportRol = 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus)) where type = 1
		and (
		(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82,84,85))
		or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
		or (menu_id in (71,72) and @IVRScripting = 1)
		or (menu_id in (73,74,75,76) and @AVRS = 1)
		or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
		or (menu_id = 79 and @MenusChat > 0)
		or (menu_id in (81,82,84,85) and @MenuMail = 1)--Mail
		or (menu_id = 83 and @MenuCRM > 0)
		)
		order by ordengral asc
		return(0)

	end
	else if @ReportRol = 3 begin
		select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) and menu_id not in (select distinct Parent from ccMenus where menu_id >= 2000 and type = 3)
		and (menu_id not in (3131,3132,3133,3134,3135,3136,8061,8062,8063,8071,8072,8080,10000,10010,10020,10030,10040))
		or  (menu_id     in (3131,3132,3133,3134,3135,3136) and @MenusChat > 0 )
		or  (menu_id     in (8061,8062,8063,8071,8072,8080) and @AVRS > 0)
		or  (menu_id     in (9000,9010) and @MenuCRM > 0 )
		or  (menu_id     in (10000,10010,10020,10030,10040) and @MenuMail > 0 )
		order by ordengral asc
		return(0)
	end
	else begin
		select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)
	end

end

if @Type=2
begin
	delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu and type = @ReportRol
	return(0)
end

if @Type=3
begin
	insert into ccMenuUser(id_User,id_Menu,type) values (@id_User, @id_Menu,@ReportRol)
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



		set @process = 'Alter SP -- ccsp_MailInitialStatistics'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_MailInitialStatistics]
@inboundId int=0,
@Option AS SMALLINT=0,
@User_id AS SMALLINT=0
AS
BEGIN

SET NOCOUNT ON;
declare @from datetime,@to datetime
  set @from =convert(datetime, convert(varchar(10),getdate(),121))
  set @to =dateadd(dd,1,@from)

if(@Option=0)
begin
  select
  count(*) received,
  count(case when messageStatusId = 1 then 1 else null end) pending,
  count(case when messageStatusId in (2,3) then 1 else null end) assigned,
  count(case when messageStatusId = 4 then 1 else null end) unassigned,
  count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
  count(case when messageStatusId = 7 then 1 else null end) rejected,
  count(case when messageStatusId = 8 then 1 else null end) programFwd,
  count(case when messageStatusId = 9 then 1 else null end) forwarding,
  count(case when messageStatusId in (10,11) then 1 else null end) closed,
  count(case when messageStatusId = 3 then 1 else null end) active,
  isnull(AVG(B.twait + B.tretention + B.tresponse),0) avgtAtention,
  isnull(AVG(B.twait),0) avgtWait,
  isnull(MAX(B.twait),0) maxtWait
  from conversation A
  inner join message B on A.conversationId=b.conversationId
  where inboundId= @inboundId
  and (
    (
     messageStatusId in (1,4) or
    (tQueue is not null and convert(varchar(10), tQueue,121) = convert(varchar(10),getdate(),121)) or
    (tSend is not null and convert(varchar(10), tsend,121) = convert(varchar(10), getdate(),121))
    )
    or [date] between @from and @to
   )
end
if @Option = 1
BEGIN

  select
  count(*) received,
  count(case when messageStatusId = 1 then 1 else null end) pending,
  count(case when messageStatusId in (2,3) then 1 else null end) assigned,
  count(case when messageStatusId = 4 then 1 else null end) unassigned,
  count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
  count(case when messageStatusId = 7 then 1 else null end) rejected,
  count(case when messageStatusId = 8 then 1 else null end) programFwd,
  count(case when messageStatusId = 9 then 1 else null end) forwarding,
  count(case when messageStatusId in (10,11) then 1 else null end) closed,
  count(case when messageStatusId = 3 then 1 else null end) active ,
  isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
  isnull(AVG(msg.twait),0) avgtWait,
  isnull(MAX(msg.twait),0) maxtWait,
  InboundId inboundId
  from message msg (nolock) join conversation con (nolock) on con.conversationId=msg.conversationId
  where inboundId in (select inbound_id from ccInbound where inbound_id in (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0) and chat = 3)
  and (
    (
     messageStatusId in (1,4) or
    (tQueue is not null and convert(varchar(10), tQueue,121) = convert(varchar(10),getdate(),121)) or
    (tSend is not null and convert(varchar(10), tsend,121) = convert(varchar(10), getdate(),121))
    )
    or [date] between @from and @to
   )
  GROUP BY InboundId
  END
END
'
		EXEC(@Sql)

		set @process = 'Alter SP -- ccsp_TwitterInitialStatistics'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_TwitterInitialStatistics]
@inboundId int=0,
@Option AS SMALLINT=0,
@User_id AS SMALLINT=0
AS
BEGIN

  SET NOCOUNT ON;
  declare @from datetime,@to datetime
  set @from =convert(datetime, convert(varchar(10),getdate(),121))
  set @to =dateadd(dd,1,@from)


  if(@Option=0)
  begin
    select
    count(*) received,
    count(case when messageStatusId = 1 then 1 else null end) pending,
    count(case when messageStatusId in (2,3) then 1 else null end) assigned,
    count(case when messageStatusId = 4 then 1 else null end) unassigned,
    count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
    count(case when messageStatusId = 7 then 1 else null end) rejected,
    count(case when messageStatusId = 8 then 1 else null end) programFwd,
    count(case when messageStatusId = 9 then 1 else null end) forwarding,
    count(case when messageStatusId in (10,11) then 1 else null end) closed,
    count(case when messageStatusId = 3 then 1 else null end) active ,
    isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
    isnull(AVG(msg.twait),0) avgtWait,
    isnull(MAX(msg.twait),0) maxtWait
    from messageOutTwitter msg(nolock) join conversationTwitter con (nolock) on con.conversationTwitterId=msg.conversationTwitterId
    where inboundId=@inboundId
    and (
      (
       messageStatusId in (1,4) or
      (tQueue is not null and convert(varchar(10), tQueue,121) = convert(varchar(10),getdate(),121)) or
      (tSend is not null and convert(varchar(10), tsend,121) = convert(varchar(10), getdate(),121))
      )
      or [date] between @from and @to
    )
  end
  if @Option = 1
  BEGIN
    select
    count(*) received,
    count(case when messageStatusId = 1 then 1 else null end) pending,
    count(case when messageStatusId in (2,3) then 1 else null end) assigned,
    count(case when messageStatusId = 4 then 1 else null end) unassigned,
    count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
    count(case when messageStatusId = 7 then 1 else null end) rejected,
    count(case when messageStatusId = 8 then 1 else null end) programFwd,
    count(case when messageStatusId = 9 then 1 else null end) forwarding,
    count(case when messageStatusId in (10,11) then 1 else null end) closed,
    count(case when messageStatusId = 3 then 1 else null end) active ,
    isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
    isnull(AVG(msg.twait),0) avgtWait,
    isnull(MAX(msg.twait),0) maxtWait,
    InboundId inboundId
    from messageOutTwitter msg (nolock) join conversationTwitter con (nolock) on con.conversationTwitterId=msg.conversationTwitterId
    where inboundId in (select inbound_id from ccInbound where inbound_id in (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0) and chat = 4)

    and (
      (
       messageStatusId in (1,4) or
      (tQueue is not null and convert(varchar(10), tQueue,121) = convert(varchar(10),getdate(),121)) or
      (tSend is not null and convert(varchar(10), tsend,121) = convert(varchar(10), getdate(),121))
      )
       or [date] between @from and @to
    )
    GROUP BY InboundId
  END
END
'
		EXEC(@Sql)



		set @process = 'ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig]------------'
		set @Sql= 'ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig]
@inbound_id smallint,
@descripcion varchar(50) = null,
@Status tinyint = null,
@tNotas int = null,
@tMaxWaitCall int = null,
@nMaxQue int = null,
@tel_maxwait varchar(15) = null,
@tel_MaxQueue varchar(15) = null,
@tel_outservice varchar(15) = null,
@tel_noct varchar(15) = null,
@ShowCalifWnd bit = null,
@StartTimerOnHangUp bit = null,
@editableCallKey bit = null,
@queuePosition bit = null,
@tMaxQueueCallBack smallint = null,
@stopRecording bit = null,
@dialPrefixOverflow varchar(10) = null,
@OpriorityT smallint= null,
@callerIdDesc varchar(15) = null,
@chat tinyint = null,
@inactiveChatTime smallint = null,
@maxChats tinyint = null,
@chatDomain varchar(max) = null,
@chatQueue smallint = null,
@chatTime smallint = null,
@dRestrictPlay bit = null,
@callBackSurveyAgent bit = null,
@callBackSurveyClient bit = null,
@agts_notavailable varchar(15) = null,
@editableDtmf bit = null
as
set nocount on
UPDATE ccInbound SET
descripcion = isnull(@descripcion,descripcion),
Status = isnull(@status,status),
tNotas = isnull(@tNotas,tNotas),
tMaxWaitCall = isnull(@tMaxWaitCall,tMaxWaitCall),
nMaxQue = isnull(@nMaxQue,nMaxQue),
tel_maxwait = isnull(@tel_maxwait,tel_maxwait),
tel_MaxQueue = isnull(@tel_MaxQueue,tel_MaxQueue),
tel_outservice = isnull(@tel_outservice,tel_outservice),
tel_noct = isnull(@tel_noct,tel_noct),
bnocturno = case when isnull(@tel_noct,''0'')=''0'' or @tel_noct='''' then ''0'' else ''1'' end,
StartTimerOnHangUp = isnull(@StartTimerOnHangUp,StartTimerOnHangUp),
editableCallKey = isnull(@editableCallKey,editableCallKey),
queuePosition = isnull(@queuePosition,queuePosition),
tMaxQueueCallBack = isnull(@tMaxQueueCallBack,tMaxQueueCallBack),
stopRecording = isnull(@stopRecording, stopRecording),
dialPrefixOverflow = isnull(@dialPrefixOverflow, dialPrefixOverflow),
OpriorityT = isnull(@OpriorityT, OpriorityT),
callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
chat = isnull(@chat,chat),
inactiveChatTime = isnull(@inactiveChatTime,inactiveChatTime),
maxChats = isnull(@maxChats,maxChats),
chatQueueOverflow = isnull(@chatQueue,isnull(chatQueueOverflow,15)),
chatTimeOverflow = isnull(@chatTime,isnull(chatTimeOverflow,300)),
startStopRecording = isnull(@dRestrictPlay,startStopRecording),
callBackSurveyAgent = isnull(@callBackSurveyAgent,callBackSurveyAgent),
callBackSurveyClient = isnull(@callBackSurveyClient,callBackSurveyClient),
agts_notavailable = isnull(@agts_notavailable,agts_notavailable),
editableDtmf = isnull(@editableDtmf,editableDtmf)
where inbound_id = @inbound_id


if not exists( select inbound_id from ccinbound where inbound_id <> @inbound_id and chatDomain = @chatDomain ) begin
if isnull(@chatDomain,'''') <> '''' begin
	update ccinbound set chatDomain = @chatDomain where inbound_id = @inbound_id
end
end
else begin
raiserror(''Domain already in another ACD Group'',15,4)
end


if @ShowCalifWnd = 1
begin
If exists(select cam_id from ccCalifCamp where cam_id = @inbound_id and tipo = 0)
	begin
	UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd,ShowCalifWnd)
	where inbound_id = @inbound_id
	select 1
	return(0)
	end

select 0
return(0)
end

else
UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd,ShowCalifWnd)
where inbound_id = @inbound_id
return(0)
set nocount off'
		EXEC(@Sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]--------'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
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
     ,cast (startStopRecording as tinyint)startStopRecording, leaveRecMessage, manualCallOnChat
  ,callBackSurveyAgent,callBackSurveyClient,case when surveycamid is null or surveycamid = 0 then 0 else 1 end isRelationSurvey,isnull(a1.funcEspDtmf,0)
  from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
  inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
  where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
  order by cam_descripcion
 return(0)
 set nocount off'
		EXEC(@Sql)

	set @process = 'ccsp_RIAUpdateCamConfig----------'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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
@call_record tinyint=null,
@dRestrictPlay bit = null,
@leaveRecMessage bit = null,
@manualCallOnChat bit = null,
@callBackSurveyClient bit = null,
@callBackSurveyAgent bit = null,
@funcEspDtmf int =null
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
 call_record = isnull(@call_record,call_record),
 startStopRecording = isnull(@dRestrictPlay, startStopRecording),
 leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
 manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
 callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
 callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
 funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf )
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



set @process = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters]  --------'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters]
@type as int, @sup_id as int = 0 as
set nocount on

declare @fecha_ini datetime
select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

if @type = 1 --Session time
	begin
		SELECT User_id, case
			WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0
				THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))
			ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) +
				convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
			END as logintime
		FROM ccLogLogin a with(index(IX_ccLogLogin_4)), ccGenViewRelsSupsAgent b
		where fecha >= @fecha_ini
		and a.User_id = b.agt
		and b.sup = @sup_id
		GROUP BY User_id
	end

if @type = 2 begin--Status agent
	select User_id,TipoStatusAge_id,sum(segundos) as segundos from (
	SELECT User_id, TipoStatusAge_id, sum(tStatus) As segundos
	FROM ccLogAgentesDia a with(index(IX_ccLogAgentesDia_4)), ccGenViewRelsSupsAgent b
	WHERE fecha >= @fecha_ini AND a.User_id = b.agt
	and b.sup = @sup_id
	GROUP BY User_id, TipoStatusAge_id
	union all
	select A.User_id,
	case when A.TipoStatusAge_id= 1 then 3
	when A.currentStatus in (21,4,5,9) then 4
	else A.currentStatus end as TipoStatusAge_id,
	DATEDIFF(ss,A.fecha,getdate())  from ccLogAgentesDia A
	inner join
	(select max(fecha) fecha,USER_ID from ccLogAgentesDia D
	inner join ccGenViewRelsSupsAgent C on D.User_id=C.agt
	where C.sup=8 and fecha >= @fecha_ini and currentStatus not in (0,-2)  group by User_id) B
	on A.User_id=B.User_id and A.fecha=B.fecha
	)x
	group by User_id,TipoStatusAge_id
	ORDER BY User_id
end

if @type = 3 begin

		select calls.user_id, calls.total_calls, calls.type_calls, users.login, calls.nCalls, calls.tDialog, calls.tWrapup, calls.tHold
		from ccusers As users ,
		(
			SELECT User_id AS ''user_id'' , count(*) AS ''total_calls'',
			CASE
			  WHEN statuscall_id = 15 THEN 5  --OutBound Asignada pero no contestada
			  WHEN cal_manual = 2 THEN 3      --OutBound llamada manual
			  ELSE 2                          --Llamada de OutBound
			END AS ''type_calls'',
			count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
			sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end) tDialog,
			sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end) tWrapup,
			sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold
			FROM ccoCallsOut a WITH (NOLOCK index(IX_ccoCallsOut_10)) , ccGenViewRelsSupsAgent b
			WHERE a.User_id = b.agt
			and b.sup = @sup_id
			AND statuscall_id <> 11  --OutBound sin estado definitivo
			AND cal_inicio >= @fecha_ini
			GROUP BY User_id, statuscall_id, cal_manual

			UNION

			SELECT User_id AS ''user_id'' , count(*) AS ''total_calls'',
			CASE
			  WHEN statuscall_id = 15 THEN 4  --InBound Asignada pero no contestada
			  ELSE 1                          --Llamada de InBound
			END AS ''type_calls'',
			count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
			sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end) tDialog,
			sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end) tWrapup,
			sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold
			FROM ccCallsIn a WITH (NOLOCK index(IX_ccCallsIn_5)), ccGenViewRelsSupsAgent b
			WHERE a.User_id = b.agt
			and b.sup = @sup_id
			AND statuscall_id <> 11  --InBound sin estado definitivo
			AND cal_inicio >= @fecha_ini
			GROUP BY User_id, statuscall_id
		) AS calls
		where users.user_id = calls.user_id

	end

if @type = 4
	begin
		select a.user_id, a.login
		from ccusers a, ccGenViewRelsSupsAgent b
		where user_id = b.agt
		and b.sup = @sup_id
	end

set nocount on'
		EXEC(@Sql)


		set @process = 'Alter SP -- ccsp_RIAABCChat Escape "'
    	set @sql='ALTER Procedure [dbo].[ccsp_RIAABCChat]
@OperationType tinyint = 0, -- 0:Select | 1:Insert | 2:Select Excel | 3:DateRange | 4:Admins | 5:Agents
@TipoMsgChat tinyint = null,
@User_id_Adm varchar(8000) = null,
@User_id_Agt varchar(8000) = null,
@ChatMsg varchar(1500) = null,
@Fecha_Chat_ini datetime = null,
@Fecha_Chat_fin datetime = null,
@IDArea int = null
AS
set nocount on

if @OperationType not in (0,1,2,3,4,5)
	raiserror(''Invalid Operation Type'', 18, 1)

if @OperationType=0
 begin
	Declare @User_id_Adm2 smallint, @User_id_Agt2 smallint, @Fecha2 varchar(10), @Fecha3 varchar(10), @Fecha4 varchar(10)
	CREATE TABLE #CHAT (id int identity, xmlType tinyint, User_id_Adm smallint, User_id_Agt smallint, date varchar(10),
	 iniTime varchar(10), endTime varchar(10), TipoMsgChat tinyint, text varchar(1500), time varchar(10))

	Declare CursorChat Cursor For
	-- Realizamos la Select para extraer las tablas
	select distinct User_id_Adm, User_id_Agt, convert(varchar(25), Fecha_Chat, 103) date
	 , min(convert(varchar(8), Fecha_Chat, 108)) iniTime
	 , max(convert(varchar(8), Fecha_Chat, 108)) endTime
	from ccRIAChat_Log --with (nolock, index(PK_ccRIAChat_Log))
	where TipoMsgChat = case when isnull(@TipoMsgChat,0)=0 then TipoMsgChat else @TipoMsgChat end
	 and User_id_Adm in (select case when isnull(@User_id_Adm,''0'') in (''0'','''') then User_id_Adm else value end from dbo.fn_RIASplitDelimited (@User_id_Adm, '',''))
	 and User_id_Agt in (select case when isnull(@User_id_Agt,''0'') in (''0'','''') then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
	 and Fecha_Chat between isnull(@Fecha_Chat_ini, ''19000101 00:00'')
	 and isnull(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))
	group by User_id_Adm, User_id_Agt, convert(varchar(25), Fecha_Chat, 103)
	Order by date desc, iniTime desc

	Open CursorChat
	Fetch Next From CursorChat
	Into @User_id_Adm2, @User_id_Agt2, @Fecha2, @Fecha3, @Fecha4

	if @@FETCH_STATUS = 0
	 Begin

	-- Mientras hay resultados para procesar
		While @@FETCH_STATUS = 0
		 Begin
			insert into #CHAT select ''1'' xmlType, @User_id_Adm2 User_id_Adm, @User_id_Agt2 User_id_Agt,
			 @Fecha2 date, @Fecha3 iniTime, @Fecha4 endTime, 0 TipoMsgChat, '''' text, '''' time

			-- Iniciamos el proceso
			insert into #CHAT select ''0'' xmlType, @User_id_Adm2 User_id_Adm, @User_id_Agt2 User_id_Agt, @Fecha2 date, '''' iniTime,
			'''' endTime, TipoMsgChat, ChatMsg text, convert(varchar(25), Fecha_Chat, 108) time
			from ccRIAChat_Log where User_id_Adm = @User_id_Adm2 and User_id_Agt = @User_id_Agt2 and convert(varchar(25), Fecha_Chat, 103) = @Fecha2
			order by time desc

			-- Recuperamos la siguiente fila
			Fetch Next From CursorChat
				Into @User_id_Adm2, @User_id_Agt2, @Fecha2, @Fecha3, @Fecha4
		 End
	 End


	Close CursorChat
	Deallocate CursorChat
	select C.xmlType, U2.Nombres + isnull('' '' + U2.ApellidoPaterno, '''') + isnull('' '' + U2.ApellidoMaterno, '''') Nombre_Adm,
	 U1.Nombres + isnull('' '' + U1.ApellidoPaterno, '''') + isnull('' '' + U1.ApellidoMaterno, '''') Nombre_Agt,
	C.date, C.iniTime, C.endTime, C.TipoMsgChat, C.text, C.time
	from #CHAT C join ccUsers U1 on U1.user_id = C.User_id_Agt
	 join ccUsers U2 on U2.user_id = C.User_id_Adm
	order by C.id
	return(0)
 end

if @OperationType=1
 begin
	if  @TipoMsgChat is NULL or @User_id_Adm is NULL or @User_id_Agt is NULL or @ChatMsg is NULL
		raiserror(''Invalid Data 3'', 18, 3)

	insert ccRIAChat_Log (TipoMsgChat, User_id_Adm, User_id_Agt, ChatMsg)
	select @TipoMsgChat, @User_id_Adm, @User_id_Agt, @ChatMsg
	select SCOPE_IDENTITY() ChatID
	return(0)
 end

if @OperationType=2
 begin
	-- Realizamos la Select para extraer las tablas
	if isnull(@User_id_Adm,''0'')=''0'' and isnull(@User_id_Agt,''0'')=''0'' and isnull(@TipoMsgChat,0)=0 and (@Fecha_Chat_ini is null and @Fecha_Chat_fin is null)
		raiserror(''Invalid Data 2'', 18, 2)

	create table #ExcelChat (Fecha_Chat datetime, TipoMsgChat varchar(30), Nombre_Adm varchar(100), Nombre_Agt varchar(100), ChatMsg varchar(2000))

	insert into #ExcelChat
	select Fecha_Chat,
	case C.TipoMsgChat when 1 then ''Admin -> Agent'' when 2 then ''Admin <- Agent'' else ''Admin -> Global'' end TipoMsgChat,
	U2.Nombres + isnull('' '' + U2.ApellidoPaterno, '''') + isnull('' '' + U2.ApellidoMaterno, '''') Nombre_Adm,
	U1.Nombres + isnull('' '' + U1.ApellidoPaterno, '''') + isnull('' '' + U1.ApellidoMaterno, '''') Nombre_Agt,
	''"''+ REPLACE(C.ChatMsg,''"'',''""'') + ''"'' as ChatMsg
	from ccRIAChat_Log C join ccUsers U1 on U1.user_id = C.User_id_Agt
	 join ccUsers U2 on U2.user_id = C.User_id_Adm
	where TipoMsgChat = case when isnull(@TipoMsgChat,0)=0 then TipoMsgChat else @TipoMsgChat end
	 and User_id_Adm in (select case when isnull(@User_id_Adm,''0'')=''0'' then User_id_Adm else value end from dbo.fn_RIASplitDelimited (@User_id_Adm, '',''))
	 and User_id_Agt in (select case when isnull(@User_id_Agt,''0'')=''0'' then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
	 and Fecha_Chat between isnull(@Fecha_Chat_ini, ''19000101 00:00'')
	 and isnull(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))

	if (select valor from ccsettings where setting_id=27) = 0
	 begin
		select convert(varchar(10), Fecha_Chat, 103)+'' ''+convert(varchar(8), Fecha_Chat, 108) Fecha_Chat, TipoMsgChat, Nombre_Adm, Nombre_Agt, ChatMsg from #ExcelChat Order by 1 desc
	 end

	else
	 begin
		select convert(varchar(10), Fecha_Chat, 101)+'' ''+convert(varchar(8), Fecha_Chat, 108) timestamp, TipoMsgChat MsgChatType, Nombre_Adm Adm_Name, Nombre_Agt Agt_Name, ChatMsg ChatMsg from #ExcelChat Order by 1 desc
	 end

	return(0)
 end

if @OperationType=3
 begin
	set @Fecha_Chat_fin=getdate()
	select @Fecha_Chat_ini=dateadd(year,-1,@Fecha_Chat_fin)
	from ccRIAChat_Log
	select  convert(varchar(11),@Fecha_Chat_ini ,103) Fecha_Chat_MIN, convert(varchar(11),@Fecha_Chat_fin,103)Fecha_Chat_MAX
	return(0)
 end

if @OperationType=4
 begin
	if not exists(select IDArea from ccRIACat_Areas where IDArea = @IDArea) or not exists(select user_id from ccusers where TipoUser_id in(2,6) and IDArea=@IDArea)
		raiserror(''Invalid Area'', 18, 4)

	select User_id, Login, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') Nombre
	from ccusers where TipoUser_id in(2,6) and IDArea=@IDArea
	order by login, Nombre
	return(0)
 end

if @OperationType=5
 begin
	if not exists(select IDArea from ccRIACat_Areas where IDArea = @IDArea) or not exists(select user_id from ccusers where TipoUser_id in(1) and IDArea=@IDArea)
		raiserror(''Invalid Area'', 18, 4)

	select User_id, Login, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') Nombre, Sexo gender
	from ccusers where TipoUser_id in(1) and IDArea=@IDArea
	order by login, Nombre
	return(0)
 end

select 0
set nocount off'
		EXEC(@sql)


		set @process = 'Alter SP --ccsp_RIAGetCampsNvosCB update cam_procesando'
    	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0
as
set nocount on

declare @TipoJobs as int,@isExecOutbound bit


set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

  declare @id AS INTEGER

  CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
  CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)

  create table #temccocallsoutsource (cam_id int,Pend  int)

  create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

  if @cam_id = 0 begin
    if @user_id > 0 begin
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
      from ccCamps cam left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
      where user_id = @user_id and tipo = 1
    end
    else begin
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
      from ccCamps cam left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
    end

  end
  else begin
    if @Tipo = 2
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
      from ccCamps cam
      --left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
      where cam.cam_id = @cam_id
    else
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
        from ccCamps where cam_procesando=1
  end



  insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
  select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0 from(
  select A.* from #Tcamps A
  left join ccCampsNvosCB B on A.cam_id=B.id
  where datediff(ss,B.dateUpdate,getdate())>5 or B.dateUpdate is null)X

  group by cam_id


  --Se revisa que por lo menos una campaña se pueda actualizar para realizar el proceso en caso contrario se regresa el valro extablecido
  if (select count(*) from #Tcamps2)>0 begin

    insert into #temccocallsoutsource(cam_id,Pend)
    SELECT ccos.cam_id, count(ccos.cam_id) as Pend
    FROM ccocallsoutsource ccos --with(nolock index(IX_ccoCallsOutSource))
    left join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
    WHERE cal_status in(0, 7)
    GROUP BY ccos.cam_id

    insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
    SELECT A.cam_id,
    count(case cal_status when 0 then 1 else null end) as New,
    count(case cal_status when 1 then 1 else null end) as Cb,
    count(case cal_status when 2 then 1 else null end) as Pro,
    count(case cal_status when 3 then 1 else null end) as Fin
    FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
    inner join #Tcamps2 B on A.cam_id = B.cam_id
    GROUP BY A.cam_id

    --select * from #Tcamps2

    --Se va agregar al ccsp_OUTGetNewJobs cuando lo ejecute el SP Outbound para actualizar de manera seguida si solo es una campaña
    if @regval = 0 and @cam_id >0 and @Tipo =2 begin
      update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @cam_id
    end
    else begin
      While (select count(*) from #Tcamps2 where status = 0) > 0 Begin
        set rowcount 1
        select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
        set rowcount 0
        EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
        update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
      end
    end

    begin Tran updateccCampsNvosCB

      delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
      where CampNvosCB.id = tcamp.cam_id

      INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial,dateUpdate)
      SELECT cams.cam_id, cams.cam_descripcion,
      isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
      isNull(cs.Pend,0) as pend,
      isNull(wt.Pro,0) as pro,
      isNull(cams.procesando,0) cam_procesando,
      isNull(cams.cam_tipojobs,0) cam_tipojobs,
      isNull(wt.Fin,0) Fin,
      isNull(tc.cantidad,0) cantidad,
      getdate()
      FROM #Tcamps cams with(nolock)
      LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
      LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
      left join #Tcamps2 tc on (tc.cam_id = cams.cam_id)

    COMMIT TRAN updateccCampsNvosCB
  end

  if @isExecOutbound = 0 begin

    if @Tipo = 2
      -- devuelve resultado de la taba, solo las camps del usuario
      SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, res.st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial
      FROM #Tcamps tcam
      left join  ccCampsNvosCB res  on tcam.cam_id  = res.id
      LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
    else
      SELECT id, campaña, new, cb, pro, pen,st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial
      FROM ccCampsNvosCB res
      LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
      WHERE res.id = @cam_id
  end

  drop table #Tcamps
  drop table #Tcamps2
  drop table #temccocallsoutsource
  drop table #temWorkinTable

  return(0)

end

set nocount off'
		EXEC(@sql)


		set @process = 'Alter SP -- configuraIdiomaCatalogosEnglish'
    	set @sql='ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
AS
Print ''Iniciando proceso de configuracion en Ingles''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Week'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Night shift'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
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
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, ''Xfer Fail'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, ''Ringing Fail'')

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
insert into cstoTipoLlamada(country_id,tipoLlamada_id,descrip,longitud,prefijo) values (@country_id,1,''Standard call'', 8, ''%'')

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
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Wrong area'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Disconnected call'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong number'', 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Effective call'', 0, 0, 1)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Leave a message'', 0, 1, 2)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong number'', 0, 1, 3)

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
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''DNC list'')

Print ''Mensajes default chat''
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Welcome!'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Service currently unavailable'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Our schedule service has finished'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Please hold while one of our agents is available'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''There are not available agents'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Your request can not be processed'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Chat session has been inactive for too long'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Chat session has finished'')'
		EXEC(@sql)

		set @process = 'Alter SP configuraIdiomaCatalogosEspañol'
    	set @sql='ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEspañol]
AS
Print ''Iniciando proceso de configuracion en Español''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Semana'' collate SQL_Latin1_General_CP1_CI_AS), 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Nocturno'' collate SQL_Latin1_General_CP1_CI_AS), 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''No Clasificado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Break'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Tocador'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Con Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Aclaracion'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Junta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Comida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Sistemas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))

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
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, convert(text, N''Inicial'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, convert(text, N''Fuera de Horario'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, convert(text, N''Fuera de Servicio'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, convert(text, N''Sin Agentes Firmados'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, convert(text, N''En espera'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, convert(text, N''Colgada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, convert(text, N''Desborde por Tiempo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, convert(text, N''Desborde por Cantidad'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, convert(text, N''Con Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, convert(text, N''Asignada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, convert(text, N''Asignada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, convert(text, N''Atendida Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, convert(text, N''Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, convert(text, N''Cancelada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, convert(text, N''Asignada y No Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, convert(text, N''Asignada y Toma Linea'' collate SQL_Latin1_General_CP1_CI_AS))
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo resultados de marcacion''
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, convert(text, N''Contestan'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, convert(text, N''Ocupado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, convert(text, N''No Contesta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, convert(text, N''Fax/Modem'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, convert(text, N''NoDialTone'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, convert(text, N''NoService'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, convert(text, N''Buzon/Maquina'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, convert(text, N''Congestion'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de estado de los agentes''
Delete [dbo].[ccTipoStatusAgente]
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, convert(text, N''LogOut'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, convert(text, N''Desconocido'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, convert(text, N''No Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, convert(text, N''Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, convert(text, N''Dialogo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, convert(text, N''Transferencia'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, convert(text, N''Notas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, convert(text, N''Otra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, convert(text, N''Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, convert(text, N''Ringing'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, convert(text, N''Problema'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, convert(text, N''Espera llamada manual'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, convert(text, N''Transferencia Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, convert(text, N''Ringing Fallida'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, convert(text, N''Agente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, convert(text, N''AVRS Calidad'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccDias] OFF

Print ''Estableciendo los tipos de llamada''
truncate table cstoTarifa
delete cstoTipoLlamada
declare @country_id tinyint
select @country_id = valor from ccsettings where setting_id = 104

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,1,''Local'',8,''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,2,''LD nacional'',12,''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,3,''Cel'',13,''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,4,''Cel LD'',13,''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,5,''01800'',12,''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,6,''LD usa'',13,''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,7,''LD inter'',0,''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, convert(text, N''Lista Negra en Carga de Registros'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, convert(text, N''Eliminado por Aplicar Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, convert(text, N''Eliminado de Lista Negra por Remplazo '' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, convert(text, N''Borrado de Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, convert(text, N''Solicita información general'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, convert(text, N''Se cortó la llamada'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, convert(text, N''Número equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, convert(text, N''Gestión Efectiva'' collate SQL_Latin1_General_CP1_CI_AS), 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, convert(text, N''Se deja recado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, convert(text, N''Numero Equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telmex'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Maxcom'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Avantel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''AT&T'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telnor'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Axtel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telular'')

Print ''Mensajes default chat''
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default5'', ''!Bienvenido!'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default3'', ''El servicio no se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default2'', ''Nuestro horario de atención ha terminado'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default1'', ''Por favor espere mientras uno de nuestros agentes se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default7'', ''No hay agentes disponibles'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default10'', ''No podemos tomar su solicitud'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default12'', ''La sesión de chat ha estado inactiva mucho tiempo'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default13'', ''La sesión de chat ha concluido'')'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_CampHorario'
    	set @sql='Alter PROCEDURE [dbo].[ccsp_CampHorario]
@campId as int
AS

declare @horaUniversal datetime
declare @isShudulerLey bit, @valueShudulerLey varchar(max),@hourStart int,@hourEnd int,@minStart int,@minEnd int
declare @shourStart varchar(max),@shourEnd varchar(max),@timeMaxContestacion tinyint,@revHorario bit

set @timeMaxContestacion=30
select @timeMaxContestacion=(cam_tNoContesta*2) from cccamps where cam_id=@campId

select @revHorario=valor from ccsettings where setting_id = 112
select @valueShudulerLey = valor from ccsettings where setting_id=166
select @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)) as int),@valueShudulerLey=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
select @timeMaxContestacion=cam_tNoContesta from cccamps where cam_id=@campId

if @valueShudulerLey='''' begin
 set @valueShudulerLey=''0|07:00|22:00''
 update ccsettings set valor=@valueShudulerLey where setting_id=166
end
if @isShudulerLey = 1 begin
 select @shourStart=substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)),@shourEnd=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
 select @hourStart=substring(@shourStart, 0, charindex('':'',@shourStart)),@minStart=substring(@shourStart, charindex('':'',@shourStart) + 1, len(@shourStart))
 select @hourEnd=substring(@shourEnd, 0, charindex('':'',@shourEnd)),@minEnd=substring(@shourEnd, charindex('':'',@shourEnd) + 1, len(@shourEnd))
end
else begin
 select @hourStart=0,@minStart=0,@hourEnd=23,@minEnd=59
end

SET DATEFIRST 1
set @horaUniversal = getutcdate()

select h.horario_id,Descripcion,
 case when HoraInicio>@hourStart then HoraInicio else @hourStart end HoraInicio,
 case when (horaInicio>@hourStart or (horaInicio=@hourStart and MinInicio>=@minStart) ) then MinInicio  else @minStart end MinInicio,
 case when horaFin<@hourEnd then horaFin else @hourEnd end HoraFin,
 case when ((horaFin < @hourEnd or (horaFin=@hourEnd and MinFin<=@minEnd) )) then MinFin  else @minEnd end MinFin,
 Lunes,Martes,Miercoles,Jueves,Viernes,Sabado,Domingo
 into #tempCampLaw
 from cchorarios h
 inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on h.horario_id = ccCampsHorarios.horario_id and ccCampsHorarios.cam_id = @campId
 --where  horaInicio between @hourStart and @hourEnd or horaFin between @hourStart and @hourEnd


select distinct horario_id,HoraInicio,MinInicio,horaFin,MinFin into #tempCampLaw2 from
(
 select tz_id,
 dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
 datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora,
 datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
 datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
 from ccTimeZones
)zonas
inner join #tempCampLaw on
(
 (
  hora > HoraInicio OR  (hora = HoraInicio AND minuto >= MinInicio)
 )
 AND
 (
  hora < HoraFin  OR  (hora = HoraFin AND minuto <= (MinFin-@timeMaxContestacion) )
 )
 AND
 (
  Lunes  = dia or
  Martes *2 = dia or
  Miercoles*3 = dia or
  Jueves*4 = dia or
  Viernes*5 = dia or
  Sabado*6 = dia or
  domingo*7 = dia
 )

)

select distinct #tempCampLaw2.horario_id id,
(HoraInicio*3600)+(MinInicio*60) ini,
(HoraFin*3600)+(MinFin*60) fin,
(case when HoraInicio<10 then ''0''+convert(varchar(2),HoraInicio) else convert(varchar(2),HoraInicio) end) + '':'' + (case when MinInicio<10 then ''0''+convert(varchar(2),MinInicio) else convert(varchar(2),MinInicio) end ) as HoraInicio ,
(case when HoraFin<10 then ''0''+convert(varchar(2),HoraFin) else convert(varchar(2),HoraFin) end) + '':'' + (case when MinFin<10 then ''0''+convert(varchar(2),MinFin) else convert(varchar(2),MinFin) end ) as HoraFin
into #tempCamp from #tempCampLaw2

select id,min(ini) ini,max(fin) fin,min(HoraInicio) HoraInicio,max(HoraFin) HoraFin,@timeMaxContestacion timeMaxContestacion
 from(
select distinct min(a.id) id,(a.ini) ini,(case when a.fin>b.fin then a.fin else b.fin end) fin,min(a.HoraInicio) HoraInicio,
max(case when a.fin>b.fin then a.HoraFin else b.HoraFin end) HoraFin
 from #tempCamp a, #tempCamp b
where a.fin>b.ini and b.ini between a.ini and a.fin and a.id <> b.id
group by a.ini,(case when a.fin>b.fin then a.fin else b.fin end)
union
select a.* from #tempCamp a
where a.id not in(select distinct b.id from #tempCamp a, #tempCamp b where a.fin>b.ini and b.ini between a.ini and a.fin and a.id <> b.id)
)x
group by id
order by ini



drop table #tempCamp
drop table #tempCampLaw
drop table #tempCampLaw2'
		EXEC(@sql)

		set @process = 'Alter SP --  ccsp_NetworkSocialAdminAccount'
    	set @sql='ALTER PROCEDURE [dbo].[ccsp_NetworkSocialAdminAccount]
@action int,
@meanContactTypeId smallint = 2,
@contactMeanId int=0,
@name	varchar(30)=null,
@conexionInfo	varchar(255)=null,
@inboundId	int=0,
@connUser	varchar(60)=null,
@ConnPass	varchar(30)=null,
@numMessages	tinyint=null,
@timeAlertMessage	tinyint=null,
@isActive bit =null,
@UserId int =null,
@idArea smallint =null,
@maxMails tinyint =3,
@answerTimeOut tinyint=null,
@revisionTime varchar(10)=null,
@daysTwitterRecord varchar(10)=null,
@closeConversationTime varchar(10)=null
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

declare @isActiveMail bit
set @isActiveMail=0

if @action = 1 begin--insert account twitter account
	DECLARE @tableConexionInfo TABLE(  id int, value varchar(255))
	if exists(select * from ContactMeanIn where conexionInfo = @conexionInfo and meanContactTypeId=@meanContactTypeId and inboundId<>@inboundId) begin
		select 0, ''Error: acount already exists''
		return -1
	end
	if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
	if @name is null set @name=''''
		--if @conexionInfo is null set @conexionInfo=''''
		if @connUser is null set @connUser=''''
		if @connPass is null set @connPass=''''
		if @numMessages is null set @numMessages=3
		if @timeAlertMessage is null set @timeAlertMessage=5
		if @isActive is null set @isActive=0
		if @answerTimeOut is null set @answerTimeOut=0
		if @closeConversationTime is null set @closeConversationTime=3

		--Twitter deja los token
		--conexion Info usuarioID|token|tokenSecret|time|daysTwitterRecord
		if @meanContactTypeId= 2 begin

			if @conexionInfo is null begin
				set @conexionInfo=''usuarioID|token|tokenSecret''
				set @revisionTime=isnull(@revisionTime,''1'')
				set @daysTwitterRecord=isnull(@daysTwitterRecord,''0'')
			end
			else begin
			select @conexionInfo
				insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
				set @conexionInfo=null

				SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

				SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
				SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
				SELECT @closeConversationTime=  isnull(@closeConversationTime,isnull(max(value),''3'')) FROM @tableConexionInfo where id=6
			end
			set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
		end


		insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut,closeConversationTime)
				values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut,@closeConversationTime)
		select 1,''insert''
	end
	else begin
		select @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
				@numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
				@answerTimeOut= isnull(@answerTimeOut,answerTimeOut),@name=isnull(@name,name),@closeConversationTime=isnull(@closeConversationTime,closeConversationTime)
				from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId

		--Twitter deja los token
		if @meanContactTypeId= 2 begin
			--usuarioID|token|tokenSecret|time|daysTwitterRecord|closeConversation
			insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
			set @conexionInfo=null

			SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

			SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
			SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5

			set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
		end



		update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
			numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut,
			closeConversationTime=@closeConversationTime
			where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
		select 1,''update''
	end
end
else if @action = 2 begin
	if @inboundId=0
		select A.inboundId,A.conexionInfo,A.connUser,A.ConnPass,A.isActive,A.name from contactMeanIn A
		inner join ccInbound B on A.inboundId=B.Inbound_id
		and B.chat = case when A.meanContactTypeId=1 then 3 when A.meanContactTypeId=2 then 4 else -1 end
		where meanContactTypeId=@meanContactTypeId and isActive=1
	else
		select A.inboundId,A.conexionInfo,A.connUser,A.ConnPass,A.isActive,A.name from contactMeanIn A
		inner join ccInbound B on A.inboundId=B.Inbound_id
		and B.chat = case when A.meanContactTypeId=1 then 3 when A.meanContactTypeId=2 then 4 else -1 end

		where meanContactTypeId=@meanContactTypeId and isActive=1 and inboundId=@inboundId
end
else if @action = 3 begin
	select A.name,A.connUser,A.numMessages,A.timeAlertMessage,A.answerTimeOut ,B.tNotas,B.descripcion,C.graphic_id,D.frame
	from ContactMeanIn A
	inner join ccinbound B on A.inboundId=B.Inbound_id
	inner join ccRIAinboundGraph C on C.Inbound_id=B.Inbound_id
	inner join ccRIAGraphics D on D.graphic_id=C.graphic_id
	where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action=4 begin
	--Estos es para Twitter
	--usuarioID|token|tokenSecret|time|daysTwitterRecord
	select isnull(max(conexionInfo),''usuarioID|token|tokenSecret|1|0'') from contactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
END'
		EXEC(@sql)


		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix
		set  @actualVersionFix = @versionfix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
if @actualVersion = @version and @actualVersionFix = @versionfix begin
	begin tran
	begin try



		set @process = 'Alter table ccTimeZoneArea --- add locality'
    	set @sql='if not exists (select * from sys.columns where name = N''locality'' and Object_ID = Object_ID(N''ccTimeZoneArea''))
				begin
					alter table ccTimeZoneArea add locality varchar(255) null
				end'
		EXEC(@sql)

		set @process = 'Alter table ccTimeZoneArea --- drop PK_ccTimeZoneArea_1'
    	set @sql='if exists (select * from sys.indexes where name = N''PK_ccTimeZoneArea_1'' and object_id = OBJECT_ID(N''ccTimeZoneArea''))
				begin
					alter table ccTimeZoneArea drop PK_ccTimeZoneArea_1
				end'
		EXEC(@sql)

		set @process = 'Create Nonclustered index --- PK_ccTimeZoneArea_1'
    	set @sql='if not exists (select * from sys.indexes where name = N''PK_ccTimeZoneArea_1'' and object_id = OBJECT_ID(N''ccTimeZoneArea''))
				begin
					CREATE NONCLUSTERED INDEX [PK_ccTimeZoneArea_1] ON [dbo].[ccTimeZoneArea]
					(
						[id_country] ASC,
						[area] ASC,
						[location] ASC
					)
					INCLUDE ([tz_standard],[tz_daylight],[locality])
				end'
		EXEC(@sql)

		set @process = 'Insert ccSettings -- Conf Monitor Port'
    	set @sql='if not exists(select * from ccsettings where setting_id=186)
		insert into ccsettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values(186,''0'',''Enviar paquetes para monitoreo de puertos de salida'',1,''X'',''Al cargar el Outbound envio los estados del puertos al Admin'',''Send packets to monitor outbound ports'',0,''^[0-1]$'')'
		EXEC(@sql)

		set @process = 'Update ccTimeZoneArea -- QROO'
    	set @sql='if exists (select * from sys.tables where name = N''ccTimeZoneArea'')
				begin
					UPDATE ccTimeZoneArea SET tz_daylight = 32 WHERE location = ''QROO''
				end'
		EXEC(@sql)

		set @process = 'Delete ccTimeZoneArea --- id_country = 1, area = 329, tz_standard = 128'
    	set @sql='if exists (select * from sys.tables where name = N''ccTimeZoneArea'')
				begin
					delete from ccTimeZoneArea where id_country = 1 and area = 329 and tz_standard = 128
				end'
		EXEC(@sql)

		set @process = 'Insert ccTimeZoneArea --- locality BAHIA DE BANDERAS'
    	set @sql='if exists (select * from sys.tables where name = N''ccTimeZoneArea'')
				begin
					insert ccTimeZoneArea (id_country,area,location,tz_standard,tz_daylight,locality) values (1,311,''NAY'',64,32,''BAHIA DE BANDERAS'')
					insert ccTimeZoneArea (id_country,area,location,tz_standard,tz_daylight,locality) values (1,322,''NAY'',64,32,''BAHIA DE BANDERAS'')
					insert ccTimeZoneArea (id_country,area,location,tz_standard,tz_daylight,locality) values (1,327,''NAY'',64,32,''BAHIA DE BANDERAS'')
					insert ccTimeZoneArea (id_country,area,location,tz_standard,tz_daylight,locality) values (1,329,''NAY'',64,32,''BAHIA DE BANDERAS'')
				end'
		EXEC(@sql)

		set @process = 'Function fnGetTimeZone --- actualización de la función para el uso locality'
    	set @sql='ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN
	declare @lada as varchar(5)
	declare @timeZone as int
	declare @ld as varchar(5)
	declare @location as varchar(500)
	declare @locality as varchar(255)
	declare @country as tinyInt
	declare @pais varchar(2)

	select @lada = valor from ccsettings with(nolock) where setting_id = 17
	select @country = valor, @pais = valor from ccSettings with(nolock) where setting_id = 104
	
	select @ld = ''''
	select @location = ''''

		if @country = 1 begin
		
			select @phone=case when len(@phone) > 10 then RIGHT(@phone,10) when LEN(@phone)=10-LEN(@lada) then @lada+@phone else @phone  end

			if (len(@phone) = 10)
				begin
					if(exists(select top 1 cld from series nolock where cld=left(@phone,2)))
						select @ld = case when left(@phone,2) = @lada then 0 else left(@phone,2) end
					else if(exists(select top 1 cld from series nolock where cld=left(@phone,3)))
						select @ld = case when left(@phone,3) = @lada then 0 else left(@phone,3) end
				end
			else
				select @ld = 0

			if @ld <> 0
				begin
					select @location = estado, @locality = MUNICIPIO
					from series
					where cld = @ld
					and serie = substring(@phone, len(@ld) + 1, 6 - len(@ld))
					and right(@phone, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

					if not exists(select locality from ccTimeZoneArea (nolock) where area=@ld and locality=@locality)
						set @locality = null

					select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
					where id_country = @country and (
					( len(@phone) = 8 and @lada = area and len(area) = 2 )
					or
					( len(@phone) = 7 and @lada = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 2) = area and len(area) = 2 ))
					and location = @location and case when locality is null then 1 else 2 end=(case when @locality is null then 1 when locality=@locality then 2 else 0 end)
				end
			else
				begin
					select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
					where id_country = @country and (
					( len(@phone) = 8 and @lada = area and len(area) = 2 )
					or
					( len(@phone) = 7 and @lada = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 2) = area and len(area) = 2 ))
				end
		end

		if @country = 2 begin
			declare @telTemp varchar(15)
			set @telTemp = @phone
			select @phone = dbo.Completa(@phone, @pais, @lada)
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
		select @phone = dbo.Completa(@phone, @pais, @lada)
		-- len(@phone) = 10
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
			where id_country = @country and (
			(convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
			(convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
		end
	end

	if @country = 10 begin
		select @phone = dbo.Completa(@phone, @pais, @lada)
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

	if @country = 11 begin
		select @phone = dbo.Completa(@phone, @pais, @lada)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	if @country = 12 begin
		select @phone = dbo.Completa(@phone, @pais, @lada)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	if @country = 13 begin
		select @phone = dbo.Completa(@phone, @pais, @lada)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end
	
	if @country = 14 begin
		select @phone = dbo.Completa(@phone, @pais, @lada)
		if (substring(@phone, 1, 1) <> ''E'') begin
			if len(@phone) = 9 begin
				select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
				where id_country = @country and ((substring(@phone, 1, 2) = area) or (substring(@phone, 1, 3) = area))
			end
		end
	end
	
	if @country = 15 begin --Peru
		select @phone = dbo.Completa(@phone, @pais, @lada)
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
		where id_country = @country and (
		(len(@phone) = 6 and @lada = area and len(@lada) = 2) or --Local
		(len(@phone) = 7 and @lada = area and @lada = 1) or --Local Lima
		(len(@phone) = 9 and left(@phone, 1) <> ''9'' and ((substring(@phone, 2, 1) = ''1'' and area=''1'') or (substring(@phone, 2, 1) <> ''1'' and substring(@phone, 2, 2) = area)))) --LD
	end

	return isNull(@timeZone,0)
 END'
		EXEC(@sql)


		set @process = 'Alter SP ccsp_RIAConfEspec -- Add Frame'
    	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
@User_id int
AS
set nocount on
/****
Conexion Info Email In
	protocol|server|ssl|port|cleanMail|revisionTime
Conexion Info Email Out
	serverOut|portOut|tls|sslOut
Conexion Info Twitter
	usuarioID|token|tokenSecret|time|daysTwitterRecord
***/
select  A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat mode, A.inactiveChatTime, A.maxChats, isnull(A.chatDomain,'''') chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
isnull(A.startStopRecording,0) startStopRecording
,isnull(B.name,'''') as nameMail,isnull(B.conexionInfo,'''') as conexionInfo,isnull(B.connUser,'''') as connUser,
isnull(B.ConnPass,'''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage,
isnull(B.IsActive,0) as Active, isnull(B.answerTimeOut,0) as answerTimeOut,
case when A.cam_id > 0   and C.callsBySurvey=3 then A.callBackSurveyAgent else 0 end callBackSurveyAgent,
case when A.cam_id > 0  and C.callsBySurvey=3 then A.callBackSurveyClient else 0 end callBackSurveyClient,
case when A.cam_id > 0  and C.callsBySurvey=3 then 1 else 0 end isRelationSurvey,
isnull(A.agts_notavailable,'''') as agts_notavailable,
isnull(nameTwitter,'''') nameTwitter,isnull(userTwitter,'''') userTwitter,isnull(numMessagesTwitter,3) numMessagesTwitter,
isnull(timeAlertMessageTwitter,10) timeAlertMessageTwitter,isnull(ActiveTwitter,0) ActiveTwitter,isnull(answerTimeOutTwitter,10) answerTimeOutTwitter,
--usuarioID|token|tokenSecret|time|daysTwitterRecord
isnull(conexionInfoTwitter,''usuarioID|token|tokenSecret|1|0'') conexionInfoTwitter
,isnull(closeConversationTimeTwitter,3) closeConversationTimeTwitter,isnull(closeConversationTime,3) closeConversationTimeEmail
,isnull(A.editableDtmf,0) as editableDtmf
,isnull(gra.graphic_id,1) as frame
from ccInbound A
left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
left join ContactMeanIn B on A.inbound_id=B.inboundId and B.meanContactTypeId=1
left join ccCamps C on C.cam_id=A.cam_id
left join (
select D.inboundId,
D.name as nameTwitter,D.connUser as userTwitter,D.numMessages as numMessagesTwitter,
D.timeAlertMessage as timeAlertMessageTwitter,
D.IsActive as ActiveTwitter, D.answerTimeOut as answerTimeOutTwitter,D.conexionInfo as conexionInfoTwitter,
closeConversationTime as  closeConversationTimeTwitter
from ContactMeanIn D
where D.meanContactTypeId=2) D on A.Inbound_id=D.inboundId
where A.inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 4))
return(0)
set nocount off'
		EXEC(@sql)
		

		set @process = 'Alter SP ccsp_RIAccSettingsConfig -- Add country'
    	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
			@command tinyint,
			@setting_id smallint = null,
			@value varchar(200) = null
			AS
			set nocount on

			declare @idioma tinyint
			declare @activeChat tinyint

			select @idioma=valor from ccSettings where setting_id=27
			Select @activeChat=valor from ccSettings where setting_id=145

			if @command=0
			 begin
				SELECT case @idioma when 0 then descripcion else [description] end descripcion
				FROM ccSettings WITH(NOLOCK, index(PK_ccSettings)) WHERE setting_id=@setting_id
				order by descripcion
				return(0)
			 end

			if @command=1
			 begin
				Select setting_id, case @idioma when 0 then descripcion else [description] end descripcion, valor, tipo,validate
				from ccSettings WITH(NOLOCK, index(PK_ccSettings)) where tipo in (''AGT'',''ADM'',''GRL'',''REP'',''SV'')
				and (setting_id not in (139,140,141)
				or   setting_id     in (139,140,141) and @activeChat > 0)
				order by tipo, descripcion
				return(0)
			 end

			if @command=2
			 begin
				if @setting_id = 27 and @value not in(''0'',''1'') begin
					set @value = 0
				end
				else if @setting_id = 104 and @value not in(''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'',''10'',''11'',''12'',''13'',''14'',''15'') begin
					set @value = 1
				end
				update ccSettings set valor=@value where setting_id = @setting_id
				return(0)
			 end

			set nocount off';
		EXEC(@sql)
		
		set @process = 'Add Peru''s dialing plan -- Add country'
    	set @sql='update ccsettings set detalle=''1:Mexico, 2:Argentina, 3:Colombia, 4:USA, 5:Chile, 6: Venezuela, 7: Reino Unido, 8: Arabia saudita, 9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:España, 15:Peru'' where setting_id=104

			SET IDENTITY_INSERT ccRIACat_Country ON;
			delete ccRIACat_Country where CtyName=''España''
			insert ccRIACat_Country (CtyID,CtyName,CtyCode,minPhoneLength,maxPhoneLength) values (14,''España'',34,9,9)
			insert ccRIACat_Country (CtyID,CtyName,CtyCode,minPhoneLength,maxPhoneLength) values (15,''Peru'',51,7,9)
			SET IDENTITY_INSERT ccRIACat_Country OFF;

			if not exists(select * from cstoTipoLlamada where country_id=15 and tipoLlamada_id=1 and descrip=''Local'' and prefijo=''%'' and longitud=''6|7'')
				insert cstoTipoLlamada (country_id,tipoLlamada_id,descrip,prefijo,longitud) values (15,1,''Local'',''%'',''6|7'')
			if not exists(select * from cstoTipoLlamada where country_id=15 and tipoLlamada_id=2 and descrip=''LD nacional'' and prefijo=''0%'' and longitud=''9'')
				insert cstoTipoLlamada (country_id,tipoLlamada_id,descrip,prefijo,longitud) values (15,2,''LD nacional'',''0%'',''9'')
			if not exists(select * from cstoTipoLlamada where country_id=15 and tipoLlamada_id=3 and descrip=''Cel'' and prefijo=''9%'' and longitud=''9'')
				insert cstoTipoLlamada (country_id,tipoLlamada_id,descrip,prefijo,longitud) values (15,3,''Cel'',''9%'',''9'')
			if not exists(select * from cstoTipoLlamada where country_id=15 and tipoLlamada_id=4 and descrip=''LD inter'' and prefijo=''00%'' and longitud=''0'')
				insert cstoTipoLlamada (country_id,tipoLlamada_id,descrip,prefijo,longitud) values (15,4,''LD inter'',''00%'',''0'')
			
			if not exists (select * from sys.tables where name = N''seriesPE'')
			BEGIN
			create table seriesPE (zonaGeografica varchar(50), zonaNumeracion varchar(2), areaNumeracion varchar(2), rangoInicio varchar(8), rangoFinal varchar(8))
			insert seriesPE values (''Lima,Callao'',''1'',''1'',''0000000'',''9999999'')
			insert seriesPE values (''La Libertad'',''4'',''44'',''0000000'',''9999999'')
			insert seriesPE values (''Ancash'',''4'',''43'',''0000000'',''9999999'')
			insert seriesPE values (''San Martín'',''4'',''42'',''0000000'',''9999999'')
			insert seriesPE values (''Amazonas'',''4'',''41'',''0000000'',''9999999'')
			insert seriesPE values (''Ica'',''5'',''56'',''0000000'',''9999999'')
			insert seriesPE values (''Arequipa'',''5'',''54'',''0000000'',''9999999'')
			insert seriesPE values (''Moquegua'',''5'',''53'',''0000000'',''9999999'')
			insert seriesPE values (''Tacna'',''5'',''52'',''0000000'',''9999999'')
			insert seriesPE values (''Puno'',''5'',''51'',''0000000'',''9999999'')
			insert seriesPE values (''Huancavelica'',''6'',''67'',''0000000'',''9999999'')
			insert seriesPE values (''Ayacucho'',''6'',''66'',''0000000'',''9999999'')
			insert seriesPE values (''Loreto'',''6'',''65'',''0000000'',''9999999'')
			insert seriesPE values (''Junin'',''6'',''64'',''0000000'',''9999999'')
			insert seriesPE values (''Pasco'',''6'',''63'',''0000000'',''9999999'')
			insert seriesPE values (''Huanuco'',''6'',''62'',''0000000'',''9999999'')
			insert seriesPE values (''Ucayali'',''6'',''61'',''0000000'',''9999999'')
			insert seriesPE values (''Cajamarca'',''7'',''76'',''0000000'',''9999999'')
			insert seriesPE values (''Lambayeque'',''7'',''74'',''0000000'',''9999999'')
			insert seriesPE values (''Plura'',''7'',''73'',''0000000'',''9999999'')
			insert seriesPE values (''Tumbes'',''7'',''72'',''0000000'',''9999999'')
			insert seriesPE values (''Cuzco'',''8'',''84'',''0000000'',''9999999'')
			insert seriesPE values (''Apurimac'',''8'',''83'',''0000000'',''9999999'')
			insert seriesPE values (''Madre de Dios'',''8'',''82'',''0000000'',''9999999'')
			END';
		EXEC(@sql)
		
		set @process = 'ALTER function Completa -- Add country'
    	set @sql='ALTER function [dbo].[Completa](@Cadena varchar(32), @pais varchar(2) = '''', @ld varchar(5) = '''')
			RETURNS varchar(32)
			AS
			BEGIN
			declare @resultado varchar(32)

			if (@pais = '''' and @ld = '''')
				begin
					select @pais = valor from ccSettings with(nolock) where setting_id = 104
					select @ld = valor from ccSettings with(nolock) where setting_id = 17
				end
			select @resultado = dbo.limpia(@Cadena)

			--Completa 1:México 2:Argentina 3:Colombia 4:USA 5:Chile 6: venezuela 7: UK 8: arabia saudita 9: Australia 10:Brasil 11:Guatemala 12:Costa Rica 13:Salvador
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

			if @pais = 11 --Guatemala
			begin
				if len(@resultado)=8
					begin
						if charindex(substring(@resultado,1,1),''2,3,4,5,6,7'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					select @resultado = ''E_NV_Longitud''
			end

			if @pais = 12 --Costa Rica
			begin
				if len(@resultado)=8
					begin
						if charindex(substring(@resultado,1,1),''2,3,4,5,6,7,8'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else if len(@resultado)=10
					begin
						if charindex(substring(@resultado,1,3),''800,900,905'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					begin
						if charindex(substring(@resultado,1,2),''00,08'') <= 0
							select @resultado = ''E_'' + @resultado
					end
			end

			if @pais = 13 --Salvador
			begin
				if len(@resultado)=8
					begin
						if charindex(substring(@resultado,1,1),''2,6,7'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					begin
						if charindex(substring(@resultado,1,2),''00'') <= 0
							select @resultado = ''E_'' + @resultado
					end
			end

			if @pais = 14 --España
			begin
				if len(@resultado)=9
					begin
						if charindex(substring(@resultado,1,1),''5,6,7,8,9'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					begin
						if charindex(substring(@resultado,1,2),''00'') <= 0
							select @resultado = ''E_'' + @resultado
					end
			end

			if @pais = 15 --Peru
			begin
				select @resultado = case
				 when (len(@resultado)=7 and len(@ld)=1) or (len(@resultado)=6 and len(@ld)=2) then @resultado
				 when len(@resultado)=8 then
				  case when substring(@resultado, 1, len(@ld)) = @ld
				   then right(@resultado, 8 - len(@ld)) else ''0'' + @resultado end
				 when len(@resultado)=9 then
				   case when left(@resultado,1) = ''0'' and substring(@resultado, 2, len(@ld)) = @ld
					then right(@resultado, 8 - len(@ld)) else @resultado end
				else ''E_NV_Longitud'' end
			end --Termina Peru

			-- Termina
			return @resultado

			end';
		EXEC(@sql)
		
		set @process = 'ALTER function Completa_ListaNegra -- Add country'
    	set @sql='ALTER FUNCTION [dbo].[Completa_ListaNegra] (@Cadena varchar(30))
			RETURNS varchar(30) AS
			begin
			declare @resultado varchar(30), @ld varchar(6), @pais tinyint, @BLActivo tinyint

			select @ld=valor from ccSettings with(nolock) where setting_id=17
			select @pais = valor from ccsettings with(nolock) where setting_id = 104
			select @BLActivo = valor from ccsettings with(nolock) where setting_id = 114

			select @resultado=dbo.Completa(@Cadena, @pais, @ld)

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

				--Guatemala
				if @pais = 11 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end

				--Costa Rica
				if @pais = 12 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end

				--Salvador
				if @pais = 13 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end

				--Spain
				if @pais = 14 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end

				--Peru
				if @pais = 15 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end
			end
			else begin
			 select @resultado = dbo.Limpia(@cadena)
			end

			return @resultado
			end';
		EXEC(@sql)
		
		set @process = 'ALTER function TelAni -- Add country'
    	set @sql='ALTER function [dbo].[TelAni](@tel varchar(32), @lista smallint)
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

				if @pais = 14 begin --Empieza España
					if len(@tel) = 9  begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and
						((substring(@tel, 1, 1) = area) or
						(substring(@tel, 1, 2) = area) or
						(substring(@tel, 1, 3) = area))
					end
					else
						select @tel = ''''

					return @tel
				end --Termina España

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

				return @ret
			END';
		EXEC(@sql)
		
		set @process = 'ALTER function Verifica -- Add country'
    	set @sql='ALTER FUNCTION [dbo].[Verifica](@tel varchar(32))
			RETURNS varchar(32) AS
			 BEGIN
				declare @ld varchar(7)
				declare @lon tinyint
				declare @result tinyint
				declare @mod varchar(10)
				declare @Cadena varchar(32)
				declare @cldLocal varchar(7)
				declare @pais tinyint

				select @cldLocal = valor from ccsettings with(nolock) where setting_id = 17
				select @pais = valor from ccSettings with(nolock) where setting_id = 104
				select @tel = dbo.limpia(@tel)

				if @pais = 1 begin --Empieza Mexico
					select @lon = len(@tel)
					if @lon between 7 and 8 begin
						set @tel = @cldLocal + @tel
					end
					select @tel = right(@tel, 10)
					select @lon = len(@tel)

					if @lon = 10 begin

						if(exists(select top 1 cld from series nolock where cld=left(@tel,2)))
							select @ld = left(@tel,2)
						else if(exists(select top 1 cld from series nolock where cld=left(@tel,3)))
							select @ld = left(@tel,3)
						else
							return ''E_'' + @tel

						select @mod = modalidad from series nolock where cld = @ld and serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

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
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
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
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
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
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
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
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
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
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
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
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
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
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
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

				if @pais= 11
					begin -- Inicia Guatemala
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if exists(select zonaGeografica from seriesGT (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
									return @tel
								else
									return ''E_'' + @tel
							end
						else
							return @tel
					end -- Termina Guatemala

					if @pais= 12
					begin -- Inicia Costa Rica
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if len(@tel)=8
									if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
										return @tel
									else
										return ''E_'' + @tel
								else if len(@tel)=10 begin
									if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,3) and right(@tel, 7) between rangoInicio and rangoFinal)
										return @tel
									else
										return ''E_'' + @tel
								end
								else
									if charindex(substring(@tel,1,2),''00,08'') <= 0
										return ''E_'' + @tel
									else
										return @tel
							end
					end -- Termina Costa Rica

				if @pais= 13
					begin -- Inicia Salvador
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if len(@tel)=8
									if exists(select zonaGeografica from seriesSV (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
										return @tel
									else
										return ''E_'' + @tel
								else
									if charindex(substring(@tel,1,2),''00'') <= 0
										return ''E_'' + @tel
									else
										return @tel
							end
					end -- Termina Salvador

				if @pais= 14
					begin -- Inicia Spain
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if len(@tel)=9
									if exists(select provincia from seriesEsp (nolock) where indicativo = substring(@tel,1,1) and right(@tel, 8) between numInicial and numFinal)
										return @tel
									else
										return ''E_'' + @tel
								else
									if charindex(substring(@tel,1,2),''00'') <= 0
										return ''E_'' + @tel
									else
										return @tel
							end
					end -- Termina España

				if @pais= 15 begin --Inicia Peru
					select @tel = dbo.Completa(@tel, @pais, @cldLocal)
					select @lon = len(@tel)
					if @lon between 6 and 7 begin
						set @tel = @cldLocal + @tel
					end
					select @tel = right(@tel, 9)
					select @lon = len(@tel)
					if left(@tel,1) <> ''E'' begin
						if @lon = 9 begin
							if exists(select zonaGeografica from seriesPE (nolock) where 
								left(@tel,1) = 9 or
								substring(@tel,2,1) = 1 and areaNumeracion = 1 and right(@tel, 7) between rangoInicio and rangoFinal or
								substring(@tel,2,1) <> 1 and left(@tel,2) = areaNumeracion and right(@tel, 7) between rangoInicio and rangoFinal
							)
								return @tel
							else
								return ''E_'' + @tel
						end
					end	
				end --Termina Peru

				return @tel
			end';
		EXEC(@sql)

		set @process = 'Create SP -- [dbo].[crmxGetRecordData]'
		set @Sql= 'CREATE PROCEDURE [dbo].[crmxGetRecordData]
				@callID int,
				@callType tinyint
			AS
			BEGIN
				SET NOCOUNT ON;
				declare @xmlCallData xml

				if @callType = 2
				begin
					SET @xmlCallData =  
					(	select
							cal_id "call/@id",
							cal_key "call/@key",
							cal_telefono "call/@telephone",
							cal_tdialog "call/@length",
							co.user_id "agent/@id",
							isnull(nombres,'''')+'' ''+isnull(ApellidoPaterno,'''') "agent/@name",
							isnull(co.calif_id,0) "disposition/@id",
							isnull(tco.description,'''') "disposition/@name",
							isnull(co.califSub_id,0) "subdisposition/@id",
							isnull(tcso.califSubDesc,'''') "subdisposition/@name"
						from ccocallsout co (nolock)
							left join ccusers us (nolock) on us.user_id=co.user_id
							left join ccTipoCalifOUT tco on tco.calif_id=co.calif_id
							left join ccTipoCalifSubOUT tcso on tcso.califSub_id = co.califSub_id
						where cal_id=@callID
						for XML path (''callData'')
					)
				end
				else
				begin
					SET @xmlCallData =  
					(	select
							cal_id "call/@id",
							cal_key "call/@key",
							cal_ANI "call/@telephone",
							cal_tdialog "call/@length",
							co.user_id "agent/@id",
							isnull(nombres,'''')+'' ''+isnull(ApellidoPaterno,'''') "agent/@name",
							isnull(co.calif_id,0) "disposition/@id",
							isnull(tco.description,'''') "disposition/@name",
							isnull(co.califSub_id,0) "subdisposition/@id",
							isnull(tcso.califSubDesc,'''') "subdisposition/@name"
						from cccallsin co (nolock)
							left join ccusers us (nolock) on us.user_id=co.user_id
							left join ccTipoCalif tco on tco.calif_id=co.calif_id
							left join ccTipoCalifSub tcso on tcso.califSub_id = co.califSub_id
						where cal_id=@callID
						for XML path (''callData'')
					)
				end

				select @xmlCallData
			END'
		EXEC(@sql)



			set @process = 'Alter SP - Load Accountable'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_OUTGetCallsInfo_AllCamps]
@Tipo as tinyint=0
AS

declare @mToday as smalldatetime

select @mToday = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
if @Tipo = 0
begin
	SELECT cam_id, cam_descripcion,
		0 as pContesta,
		0 as pOcupado,
		0 as pNoContesta,
		0 as pFaxModem,
		0 as pNoService,
		0 as Marcaciones, 0 as Contestan,  0 as Ocupado, 0 as NoContesta, 0 as FaxModem, 0 as NoService
	FROM ccCamps
	order by cam_id
end

if @Tipo = 1
begin
	select cam_id, L.Campana,
		((L.Contestan*100)/ L.Marcaciones) as pContesta,
		((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
		((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
		((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
		((L.NoService*100)/ L.Marcaciones) as pNoService,
		L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
		,L.Otro,L.Cancelado,L.buzon,L.NoDialTone,L.congestion
	from (
	select cam_id, '''' as Campana,
		count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
		count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
		count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
		count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
		count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		count(*) as Marcaciones
		,count(case tipoResDial_id when 8 then 1 else null end) as Otro
		,count(case tipoResDial_id when 13 then 1 else null end) as Cancelado
		,count(case tipoResDial_id when 11 then 1 else null end) as buzon
		,count(case tipoResDial_id when 5 then 1 else null end) as NoDialTone
		,count(case tipoResDial_id when 12 then 1 else null end) as congestion

	from ccoLogDials
	Where fecha >  @mToday
	group by cam_id
	) L order by Campana

end

if @Tipo = 2
begin
	select cam_id, L.Campana,
		((L.Contestan*100)/ L.Marcaciones) as pContesta,
		((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
		((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
		((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
		((L.NoService*100)/ L.Marcaciones) as pNoService,
		L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
	from (
	select C.cam_id as cam_id, cam_descripcion as Campana,
		count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
		count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
		count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
		count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
		count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		count(*) as Marcaciones
	from ccoLogDials L join ccCamps C on L.cam_id=C.cam_id
	Where fecha >  @mToday
	group by C.cam_id, cam_descripcion
	) L order by Campana
end
'
	EXEC(@sql)

	set @process = ''
    set @sql='ALTER procedure [dbo].[ccsp_RIAMenuRoles]
@Type tinyint,
@User_id smallint = null,
@Role_id smallint = null,
@InsertMenu_id smallint = null,
@DeleteMenu_id smallint = null,

@firstSup smallint = null,
@reportRol tinyint = 1,
@AVRS tinyint = null,
@CM tinyint = 0,
@AE tinyint = 0
as
set nocount on

select @reportRol = case @reportRol when 0 then 1 else @reportRol end, @role_id = case @role_id when 0 then 1 else @role_id end

Declare @NRS tinyint
declare @MenusChat tinyint
declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenuMail tinyint
Declare @MenuCRM tinyint
Declare @monitorPortMenu tinyint

set @MenuMail = 0
set @MenuCRM = 0

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

---Checar si esta se aplica
select @AVRS = valor from ccSettings where setting_id = 124
select @IVRScripting = valor from ccsettings where setting_id = 125

select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
--Activa menus relacionados con campañas
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155
select @MenuCRM = valor from ccsettings where setting_id = 168
select @monitorPortMenu = case when valor=''1'' then 1 else 0 end from ccsettings where setting_id = 184

If @Type = 1 -- Carga todos los roles
	begin
		select Role_id, Description from ccRIACat_AdminRole where type = @reportRol order by priority
		return(0)
	end

If @Type = 2 -- Carga los menus de un supervisor
	begin
	Select a.id_User, a.id_Menu, b.menu_descrip, Nivel, ordengral
	from ccMenuUser a inner join ccMenus b with(index(IX_ccMenus)) on a.id_Menu = b.menu_id and a.type = b.type
	where id_User = @User_id and a.Type = @reportRol and ((a.id_Menu not in (41,42, 53)) or
	(a.id_Menu = 41 and @CM = 1) or (a.id_Menu = 42 and @AE > 0) or (a.id_Menu = 53 and @NRS = 1))
	order by ordengral asc
	return(0)
	end

If @Type = 3 -- Return the menus of a rol
	begin
	select a.Role_id, b.menu_id, b.menu_descrip, b.Nivel, b.ordengral
	from ccRIARoleMenu a inner join ccMenus b with(index(IX_ccMenus)) on b.menu_id = a.id_Menu and a.type = b.type
	where a.Role_id = @Role_id and
	a.type = @reportRol and
	((b.menu_id not in (41,42,53)) or (b.menu_id = 41 and @CM = 1) or (b.menu_id = 42 and @ae > 0) or (b.menu_id = 53 and @NRS = 1))
	order by a.Role_id, b.ordengral asc
	return(0)
	end

If @Type = 4 -- Insert
	begin
	if (@InsertMenu_id <> 0) or not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
	begin
		if @Role_id in (1, 10, 14) begin
			if @InsertMenu_id <> 0 and not exists(select * from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
				insert into ccMenuUser (id_User, id_Menu, type) values(@User_id, @InsertMenu_id, @reportRol)
			if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40)begin
				Insert into ccMenuUser (id_User, id_Menu, type)values(@User_id,40,@reportRol)
			end
			else If @reportRol = 2 and not exists(select id_User from ccMenuUser where id_User = @User_id and (id_Menu between 1000 and 1999)) begin
					Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, menu_id, @reportRol from ccMenus with(index(IX_ccMenus)) where menu_id between 1000 and 1999
				end
			else if @reportRol = 3 begin
				insert into ccMenuUser (id_User, id_Menu, type) select @User_id, id_Menu, @reportRol from ccRIARoleMenu  where Role_id = @Role_id
			end
		end
		else if ((@InsertMenu_id = 53 and @NRS = 1) or (@InsertMenu_id <> 53) )
		begin
			if @InsertMenu_id <> 40	delete ccMenuUser where id_User = @User_id and type = @reportRol
				insert into ccMenuUser (id_User, id_Menu, type)	select @User_id, id_Menu, @reportRol from ccRIARoleMenu where Role_id = @Role_id and type = @reportRol
			if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40 and type = @reportRol)
				insert into ccMenuUser (id_User, id_Menu, type) values(@User_id,40,@reportRol)
		end
	end
	--Asigna un rol por default o lo actuliza
	if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
	else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)

	--Solo es necesario en caso admin y reports
	if @reportRol in(1,2) begin
		--    inserta parent en caso de no haberlo hecho en rol personalizado
		insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent
		where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0

		select @User_id, parent, @reportRol from
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent
		where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0

	end
	return (0)
	end

If @Type = 5 -- delete
	begin
		delete ccMenuUser where id_User = @User_id and id_Menu = @DeleteMenu_id and type = @reportRol
		if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
		else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
		return(0)
	end

If @Type = 6 -- Get userMenus
	begin
	if @reportRol = 2 begin --Reports version vieja
		select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode,
		c.release
		from ccRIAUserRole a inner join ccMenuUser b on a.user_id = b.id_user
		inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
		where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol and
		((b.id_Menu not in (41,42,53)) or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1))
		and ( b.id_Menu not in(77,78) or (@RelationCampInbNotReady = 1 and b.id_Menu in(77,78)))
		and ( b.id_Menu not in(79) or (@MenusChat > 0 and b.id_Menu in(79)))
		and ( b.id_Menu not in(83) or (@MenuCRM > 0 and b.id_Menu in(83)))
		order by ordengral asc
		return(0)
	end
	else begin ---Sitio del administrador
		if not exists( select * from ccRIAUsr_AdminPermissions where User_id=@user_id and per_id=6)
		set @AVRS =0

		select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode,
		c.release
		from ccRIAUserRole a
		inner join ccMenuUser b on a.user_id = b.id_user
		inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
		where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol
		and (
			(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82,84,85,69))
			or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)
			or (menu_id in (71,72) and @IVRScripting = 1)
			or (menu_id in (73,74,75,76) and @AVRS = 1)
			or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
			or (menu_id = 79 and @MenusChat > 0)
			or (menu_id in (81,82,84,85) and @MenuMail = 1)--Mail
			or (menu_id = 83 and @MenuCRM > 0)
			and ( b.id_Menu not in(69) or (@monitorPortMenu > 0 and b.id_Menu in(69)))
			)
		order by ordengral asc
		return(0)
	end
	end

If @Type = 7 -- Get language
	begin
		select valor from ccSettings where setting_id = 27
		return(0)
	end

If @Type = 8 -- Insert the personalized menus of a supervisor
	begin
		insert into ccMenuUser (id_User, id_Menu, type)
		select @User_id, id_Menu, @reportRol from ccMenuUser where id_User = @firstSup and type = @reportRol

		If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		begin
			Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
			return(0)
		end

		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
		return(0)
	end

If @Type = 9 -- Delete all supervisor menus
	begin
		delete ccMenuUser where id_User = @User_id and type = @reportRol
		return(0)
	end

If @Type = 10 -- update all supervisor menus
	begin

		if @AVRS = 1
		begin
			update ccUsers set tipoUser_id = 6 where user_id = @User_id
			return(0)
		end
	end

If @Type = 11 -- Verify level A menus
	begin
	--   inserta parent en caso de no haberlo hecho en rol personalizado
		Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where m.menu_id in (1000,2000,3000,4000) and u.id_User = @User_id and u.type = @reportRol
		group by m.parent) parent where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

		return(0)
	end

If @Type = 12
	begin
		declare @lan as tinyint
		select @lan = valor from ccSettings where setting_id = 27
		select menu_descrip from ccMenus with(index(IX_ccMenus)) where menu_id = @Role_id
		return(0)
	end

	if @Type = 13 --Agrega Menus por default a Admin en ReportsRia Agentes,ACD y Campañas
	begin
	insert into ccMenuUser([id_user],[id_Menu],[type])
	select a.User_id, b.menu_id, b.type
		from ccUsers a cross join ccMenus b
		left join ccMenuUser d on d.id_User = a.User_id and d.id_Menu = b.menu_id
		where a.TipoUser_id = 2 and b.type = 3 and d.id_User IS null and
		b.menu_id >= 2000 and b.menu_id < 5000 and a.User_id = @User_id

	insert into ccRIAUserRole([User_id],[Role_id],[type])
		select a.[User_id], 14 as role_id, 3 as type from ccUsers a
			left join ccRIAUserRole d on d.User_id = a.User_id and d.type = 3
			where d.User_id IS null and a.TipoUser_id = 2 and a.User_id = @User_id

	return (0)

	end

return(0)
set nocount off'
	EXEC(@sql)

	set @process = ''
    set @sql='ALTER procedure [dbo].[ccsp_RIACATMenu]
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
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenusChat tinyint
Declare @MenuMail tinyint
Declare @MenuCRM tinyint
Declare @monitorPortMenu tinyint

set @MenuMail=0
set @MenuCRM = 0
set @monitorPortMenu =0

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155
select @MenuCRM = valor from ccsettings where setting_id = 168
select @monitorPortMenu = case when valor=''1'' then 1 else 0 end from ccsettings where setting_id = 184

---Mail MenuId (81)
if @Type=1
begin
	if @ReportRol = 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus)) where type = 1
		and (
		(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82,84,85,69))
		or (menu_id = 41 and @CM = 1)
		or (menu_id = 42 and @AE > 0)
		or (menu_id = 53 and @NRS = 1)
		or (menu_id in (71,72) and @IVRScripting = 1)
		or (menu_id in (73,74,75,76) and @AVRS = 1)
		or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
		or (menu_id = 79 and @MenusChat > 0)
		or (menu_id in (81,82,84,85) and @MenuMail = 1)--Mail
		or (menu_id = 83 and @MenuCRM > 0)
		or (menu_id = 69 and @monitorPortMenu > 0)--Monitoreo de puertos
		)
		order by ordengral asc
		return(0)

	end
	else if @ReportRol = 3 begin
		select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) and menu_id not in (select distinct Parent from ccMenus where menu_id >= 2000 and type = 3)
		and (menu_id not in (3131,3132,3133,3134,3135,3136,8061,8062,8063,8071,8072,8080,10000,10010,10020,10030,10040))
		or  (menu_id     in (3131,3132,3133,3134,3135,3136) and @MenusChat > 0 )
		or  (menu_id     in (8061,8062,8063,8071,8072,8080) and @AVRS > 0)
		or  (menu_id     in (9000,9010) and @MenuCRM > 0 )
		or  (menu_id     in (10000,10010,10020,10030,10040) and @MenuMail > 0 )
		order by ordengral asc
		return(0)
	end
	else begin
		select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)
	end

end

if @Type=2
begin
	delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu and type = @ReportRol
	return(0)
end

if @Type=3
begin
	insert into ccMenuUser(id_User,id_Menu,type) values (@id_User, @id_Menu,@ReportRol)
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
	EXEC(@sql)

	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch

end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ''', version to release: ''' + cast(@version as varchar(5))
	end

set nocount off