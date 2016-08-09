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
update ccmenus set release=''af27c3de5996ed54fc284889ae4c64c5765fa9608a5a6d7ef128fcc0185b2c04007b2b4b868070061a84e9d349d61d7ac2617c56b3138cd334bd6cc617f7eb78'' where menu_id=8030 and type=2
'

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
@tDialog int =0 
AS
declare @Fecha4 datetime
set @Fecha4 = getdate()

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
	set @cal_tNotas =0

	if @TipoStatusAge_id in (4,6) and @call_id>0 begin
		if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo		
		if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas		
		

		if @TipoCall = 0 begin --IN			
			select @Camp=Inbound_id, @cal_tDialog=cal_tDialog, @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
						from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13						
	
			if @tDialog >0  and @isLogout=1  begin
				update ccCallsIN set cal_tDialog=@tDialog,@cal_tNotas=cal_tNotas where cal_id = @call_id and statusCall_id = 13
			end
		end
		else begin --OUT
			select  @cam_id = cam_id,@cal_tDialog=cal_tDialog from ccoCallsOut where cal_id = @call_id
			set @Camp=@cam_id
			
			if @tDialog >0  and @isLogout=1  begin
				update ccoCallsOut set cal_tDialog=@tDialog,@cal_tNotas=cal_tNotas  where cal_id = @call_id and statusCall_id = 13
			end
		end


		if @TipoStatusAge_id= 6  and @isLogout=1  begin
			INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo ) 
			VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall )
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

	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo )
	VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall )

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

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)






		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		--exec ccsp_getVersion 'BDF', @versionFix
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

		set @process = ''
    	set @sql=''
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