/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2014/10/06
Description:

-------ALTER PROCEDURE ccsp_RIAConfEspec
-------
-------
-------
-------




Database: CCenterRia
Required version: 117

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
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 118 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 117--**********actualizar a 118 sin fix
set  @versionfix = 3
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


--update  ccsettings
--set valor = '117.87.81.2'
--where setting_id = 77

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and @actualVersionFix = @versionfix -1
	begin
		begin tran
		begin try


	set @process = 'ccspXionElementsRelease - Drop if exists'
		set @sql='if exists (select * from sys.procedures where name = N''ccspXionElementsRelease'') DROP PROCEDURE ccspXionElementsRelease'
		EXEC(@sql)

		set @process = 'ccXionElementsRelease - Create Table'
		set @sql='if not exists (select * from sys.tables where name = N''ccXionElementsRelease'')
CREATE TABLE [dbo].[ccXionElementsRelease](
		[menu_id] [smallint] NULL,
		[element] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]'
		EXEC(@sql)

		set @process = 'Alter table - ccmenus'
		set @sql='if not exists (select * from sys.columns where name = N''release'' and Object_ID = Object_ID(N''ccmenus''))
				ALTER TABLE ccmenus ADD release varchar(max) not null default('''')'
		EXEC(@sql)


		set @process = 'Alter table - ccRIACat_AdminPermissions'
		set @sql='if not exists (select * from sys.columns where name = N''release'' and Object_ID = Object_ID(N''ccRIACat_AdminPermissions''))
			ALTER TABLE ccRIACat_AdminPermissions ADD release varchar(max) not null default('''')'
		EXEC(@sql)

		set @process = 'insert ccmenus'
		set @sql='if not exists (Select * from ccmenus where menu_id=85)
begin
	insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (85,''Direcciones CC de Email|Email CC Addresses'',80,''B'',84,1,'''')
end'
		EXEC(@sql)


		set @process = 'insert  Data - ccXionElementsRelease'
		set @sql='insert into ccXionElementsRelease  (menu_id,element) values (47,''c5c99bc26cf1c6099c4b4abd5a8061af'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''443599c24049a0ac9414221d2104960b'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''3a50ba6e3d57b776ce119444d5adcf6f'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''26d222921dad67337c594ca14b2163df'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''34bf14149524e92efe36ffe426aa0777'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''34a833cfbff7a6e2be59156e0803fc2e'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''f4dcfb25ab04a5a1fe803a8715d9f2ca'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''8dc4e133c2f70a56d1b55193435a11f7'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''76d6698b927c07a3bbdbe4add5f6287e'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''927a71687326a29de8f2545004838ca9'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''759d64ca7d4d842a4fd7fb1c59e56d222db58ac47f2c9698c63165af5b934cb7'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''b915e5adf2d539f015154397adceed5f'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''b1c1a7c7dbb0400c726421f969a545d397a616678bc6ad416bddc3b2db9605b8'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''6de48517b73b2757e6f675c4719afd8b'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''40540039fa519c6795038f1b1b9aab3c'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''271cfc42bcc2bb2ef57e56ef4f8f73a0'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''355a324df37c0eda9648e8c432adb3dc'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''b3b4e8822ca515fe2bcd7a15b67c25180d62d85ba2aa7d1f03c11b6c527f9cc5'')
insert into ccXionElementsRelease  (menu_id,element) values (47,''5d5b7f996ff391362be4bab9dd907146'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''c5c99bc26cf1c6099c4b4abd5a8061af'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''cccf9221fba2fb4085331f4f969e0529'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''cc4b8ad535f9bd477a0b221cc23c365d775b9a06de01bcf8996d17c1b22b5452'')
insert into ccXionElementsRelease  (menu_id,element) values (15,''1cc38475ea12b9b2c2423a6aadc81e11509a9f67637dfae7fc43202b62b6690b'')
insert into ccXionElementsRelease  (menu_id,element) values (15,''bbf415c4c5a4c81d9817a091179e05e31d5af6834e72aea5e95c7386936119c1b8bdbd20597ba286a3368cd0d7ce426e'')
insert into ccXionElementsRelease  (menu_id,element) values (19,''3c2cec36eff94978e34558e31a0b4aea'')
insert into ccXionElementsRelease  (menu_id,element) values (19,''1550dffe32088c1edad4f497ec63c076'')
insert into ccXionElementsRelease  (menu_id,element) values (19,''51390675c5527a4e9b710a3635a2fcc9'')
insert into ccXionElementsRelease  (menu_id,element) values (17,''ad57f746b66a5658e06a3294f51dda30'')
insert into ccXionElementsRelease  (menu_id,element) values (17,''46a05ba5a10dae3df01a15ef3d4fe483'')
insert into ccXionElementsRelease  (menu_id,element) values (30,''e96635f31f5a988eac955534ab3f30218388617eb75c6d77cb0ec6dcb939c2ad4df976dc4c30c91da0f4412e7aa6ec20fd3dd7bd138e049cf9a5db9af805c1bf'')
insert into ccXionElementsRelease  (menu_id,element) values (3,''8da2d495023d2e3375545e2da9d16aa7'')
insert into ccXionElementsRelease  (menu_id,element) values (3,''418e4b8da152417bb30c060d920fb1de'')
insert into ccXionElementsRelease  (menu_id,element) values (700,''f0585156234b0e8d9141b6cf39130af21f6d2249c874af45fafba6ebe6843be7'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''443599c24049a0ac9414221d2104960b'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''77731a52e6d321fc59d038119c74313fb91d961896055f78386474b60dbf2ff8'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''6878e1bc6646da6001e5cfc7ef99c3615069b1d70cffcbcc66871510a977f63b'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''106addc5cb24044a5138fc776ed9ccc9e39a7e14385702beede3ffffe74e1c2a'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''693c30de40ce3ce5ffc17a6c6ca26d6b'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''15204689ab6486b617515079d8292d1e'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''9549a014c9bbc6fee21eb0c28aaeb978'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''e5aafc723a1ad32093a4ac0c787bcf35'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''51ecea70ec39abbc8a323a6b9a5bcebf'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''4252a8482f36fcbd8962976dd4a678bc'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''9f2ce8270ff9aeae32952b7249dbe587'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''76c8f64742cc50891e84e7f70b3facf2'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''18cdc22ba29475b55c2887c724a1c2ab'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''73274ad28ad63480498bb1f324abd0c5'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''8b3ad1e69659f23f16a807a89b9f971c'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''7ec6d50736eae73111b35fb5766cf6c1'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''eae1ede439219731ca4fd1d7474464c6'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''22fa48f710815a9ae17d9ca938a7d170'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''f3dcb0ebbebb98ad7ec32baf9e30e37b'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''2568a20ea56037080b14018ff65012d4'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''7ff3d4fb9c345fd2ea59c08bc3b39c3d'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''4a242805bf98f92a28f9610fbf51b6bf'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''8ff9b978c13e1c83678dbc54d1e26111'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''c61ff4cfda37a4e687064d0498edbd1b'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''355a324df37c0eda9648e8c432adb3dc'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''2ee4cc23be6f2791ce6fef64a39766a8'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''8a8a179855b58333ddb8efc13ea0fc0b'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''523d8f191ca17d1f7aa9d465d92e7899'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''be40193a21e01531a7b19d8261c63287'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''f7fc999a32df7862b10cc6c125260858'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''b915e5adf2d539f015154397adceed5f'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''b1c1a7c7dbb0400c726421f969a545d38cf972b038860b9537be31b78e697c85'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''1d29e485897745623284f35981359066'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''3c9e768d09f654c9a5d6c47f9cebe716'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''6de48517b73b2757e6f675c4719afd8b'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''5d6f878fa559a2a3583a9204c8931749f2cfb3975528fdc775c90363b3770a49'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''d739ef8d49034ecc60f2c5e108ced06e'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''40540039fa519c6795038f1b1b9aab3c'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''7512a273bbe6b17747209a8992bd8332'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''9cf2101b463404247618a1b242eb587c'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''271cfc42bcc2bb2ef57e56ef4f8f73a0'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''b3b4e8822ca515fe2bcd7a15b67c2518153cd2a5aaf1ac29e32437e30dc89104'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''b3b4e8822ca515fe2bcd7a15b67c2518a8be8599e1ac85040b19700d6927c74d'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''b3b4e8822ca515fe2bcd7a15b67c25180d62d85ba2aa7d1f03c11b6c527f9cc5'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''4cf8c4c863e62b3895a381321a206f45'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''5843f961dc0e4abc3c01281f9a535567'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''5d5b7f996ff391362be4bab9dd907146'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''08899ebd6ff921d76bcc9876f0ad320e'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''b163361ead0bb04b28998ce4f9e2d419'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''694251a9a57efd1374d0d8a2fa74bcdb'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''920c9432ce1cf542f570bc22fde016088b56512563d74170c8e1833219b5e976'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''759d64ca7d4d842a4fd7fb1c59e56d22e0f31e59d7a23d503f2d9abd373ebf8c'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''759d64ca7d4d842a4fd7fb1c59e56d225fa34bdf218635e327e91e6a4e073ca6'')
insert into ccXionElementsRelease  (menu_id,element) values (10,''759d64ca7d4d842a4fd7fb1c59e56d222db58ac47f2c9698c63165af5b934cb7'')
insert into ccXionElementsRelease  (menu_id,element) values (700,''d729923216cf8d0e3a0a12531e84cac6e80b1bc4f95705b2f4a675f4cfcbf57156d21d89e1453d1d58907707d34f0719'')
insert into ccXionElementsRelease  (menu_id,element) values (700,''f0585156234b0e8d9141b6cf39130af21f6d2249c874af45fafba6ebe6843be7'')
insert into ccXionElementsRelease  (menu_id,element) values (700,''ba26ca7e52e6127ca6aac522dd12329946804a50129d3be1e1df800fc386de78b838f6e47dd6ba0d4e326ddae0c7f6fb8f8933565880a6252a2e203a90c4e58d'')
insert into ccXionElementsRelease  (menu_id,element) values (700,''9ddb8ef70eaba7c85041fe7a36dd8b73fd7b72e3eceb508899574ec84e99abf75d280024390d3ea06a75da1584a5cb63dc9c6b575720b340155076f9af5a3293fa32cd76cce91e11a2f08e5757bfb6c4'')'
			EXEC(@sql)

	set @process = 'Update Data - ccRIACat_AdminPermissions'
	set @sql='update ccRIACat_AdminPermissions set per_desc=''Iniciar campaña|Start Campaign'', release = ''821b5a60b5cdf4238e4ebc5e3e9e52795b5a92ed4ee810c96185adc70bbcfaae3597345fae699d1a52eeee1911388028'' where per_id = 1
update ccRIACat_AdminPermissions set per_desc=''Modificar orden de marcación|Change Dialing Order'', release = ''046f01019cd082288c234d152c6955e00a2303e3cadd3a9b97ca9302b913eae32a08f60cc951348ba8a5a35815548a5780960baf2073a2fa6d14bdced98c976f'' where per_id = 2
update ccRIACat_AdminPermissions set per_desc=''Eliminar grupos ACD y Campañas|Delete ACD Groups and Campaign'', release = ''9c1d3a6c0263c493aacbefdb61f7ca2d477d28434eaef9accb60ac5c638145884370d2b40800fcf690770956a84693c21ddcb96687ddf9617c07ff7b0ca1474a'' where per_id = 3
update ccRIACat_AdminPermissions set per_desc=''Sólo Monitoreo|Only Monitoring'', release = ''a87156ad77142a8463b2ca8fad09edc438304ac593e269b93172707890008b42ce7702a06e06dcaba3a7fb8574a5bc60'' where per_id = 4
update ccRIACat_AdminPermissions set per_desc=''Reportes|Reports'', release = ''2dcd7c1b2be45b431321df0d4a1a500a881b2ff4aa5f688e9871b56ebb55b106'' where per_id = 5
update ccRIACat_AdminPermissions set per_desc=''ver AVRS|view AVRS'', release = ''0693453312b87ed8820809f79da6dc1f41c24be614f8038fabaa307feef280d8'' where per_id = 6
update ccRIACat_AdminPermissions set per_desc=''Cambiar calificación|Change disposition'', release = ''2615a98148da7446b27e650aa6a299c11af7beecdbc249cf9a18e19e7ff4a61c1ea1756c89ed965b1d07bcffddda18ca'' where per_id = 7
update ccRIACat_AdminPermissions set per_desc=''Habilitar Clicker|Enable Clicker'', release = ''f7e0b7ee6d5e65e50fd6fee9689785ca0fa0d7a9feff07c9101c24a6d251307081da33f9b8a31efbfc104078309ab1e4'' where per_id = 8'
			EXEC(@sql)

	set @process = 'Update Data - ccmenus type 1'
	set @sql='update ccmenus set release=''85992a0728f5b837f6ca7b289b5f2219d318673b591808fd2d44cc7f1bcc2e5fdb60303ead29d5bda62265d16e866a68'' where menu_id=2 and type=1
update ccmenus set release=''ec86f9280f3ddb0487f2194a2316df4bdf6be467aed6bab26216dca31fb10be7d16c8d2f284129ec60fff3ae7c13f1ad'' where menu_id=3 and type=1
update ccmenus set release=''8a54b89d53297e7871a0c4072a3de33ad28a3b8ae346ac256b59304fe1e28c27d9aa12d201f9e9a3d0bb65a9cc63292a664d0b000fe3311e0482e032edd0ea18'' where menu_id=4 and type=1
update ccmenus set release=''e2646c409e1f92d42eb87ec99cf63205a63e2368419e782295eb430d8e40d8f265930df94850d87a6d39fca7e6f366e9'' where menu_id=5 and type=1
update ccmenus set release=''c2c6db193b45ba8a6691c7c974c021cc210696c4d52c89c98e2500ea567869c00a3b1397dba712e49969aaa3be342e53'' where menu_id=7 and type=1
update ccmenus set release=''2ce5aaa93c9e021af981814fa26a38f799259c5e363d8886bec0687c4facbd4d4f387bb90fd8d936e2919fc40364010a'' where menu_id=8 and type=1
update ccmenus set release=''9e175f3ecac1fb5782650d8f8de8ebbd05b09e06b68e5abe5d2fde916db58e50'' where menu_id=9 and type=1
update ccmenus set release=''9f54271c454bdc582cee3c666e3f98e1f4aa951ca099249f9c5c036f68e7f5ef'' where menu_id=10 and type=1
update ccmenus set release=''04ad7a6c0a683dc3f297463c7dbb029682cd3ce6fff75a53056155811eda79dd'' where menu_id=11 and type=1
update ccmenus set release=''b13bc6b2835686c7e094bcd29f3adb216303782ac1b013f763d91b3a2d23f405b4d9da853f14c073080425b8f7672759'' where menu_id=12 and type=1
update ccmenus set release=''644f3f9a7013f33219aae30ca25565240c0234b9a50a88494c16bb33bf9d3303b9cccff75b50ddb09b2242c5b3dbaf78'' where menu_id=13 and type=1
update ccmenus set release=''0136b908696acb11b0399e25cff6f54e05417e431b705f8d444decd195da4b4acb6d1355287561cd3df2511b3e7ec948'' where menu_id=14 and type=1
update ccmenus set release=''54d108e6439d9428e2b8fd3e9f91fdee6c66ac7b75719eb89993b68eac86947b'' where menu_id=15 and type=1
update ccmenus set release=''451fb584247906528fa2581818dea27868687fa25b5f2533257ae7ff51db6f58'' where menu_id=16 and type=1
update ccmenus set release=''9f54271c454bdc582cee3c666e3f98e1f4aa951ca099249f9c5c036f68e7f5ef'' where menu_id=17 and type=1
update ccmenus set release=''04ad7a6c0a683dc3f297463c7dbb029682cd3ce6fff75a53056155811eda79dd'' where menu_id=18 and type=1
update ccmenus set release=''6ba081beaebb7c3054834a5c627dd3abd29b8a8bdc2cd7d86addc77c17ebcb01a34660a141b5ab914cf3dcbc413728a6'' where menu_id=19 and type=1
update ccmenus set release=''96aefc1db17d45991e4fac4e2bcbd1cb70161191576e4d0dab04a8f9c3d352e2'' where menu_id=20 and type=1
update ccmenus set release=''54d108e6439d9428e2b8fd3e9f91fdee6c66ac7b75719eb89993b68eac86947b'' where menu_id=21 and type=1
update ccmenus set release=''657939de6fb0d4ed3d69cc97c831307c00bf475d844cf6bda2d3cfaf07e9e104'' where menu_id=22 and type=1
update ccmenus set release=''a29cd8c1799f7851b0249dfd05768285'' where menu_id=23 and type=1
update ccmenus set release=''614c124db2384775a4a2011f900ffc30e3ede48abf7ba7b419fc25887c6efe75'' where menu_id=24 and type=1
update ccmenus set release=''b14dfaa33570212ebf08ddc649b950b5dde7d0290fe993b2b25cf5bdd8966cff'' where menu_id=26 and type=1
update ccmenus set release=''71c4049b32adff34554c0bd223085689503d18379f3bfd756d0aad5db8bd3524'' where menu_id=27 and type=1
update ccmenus set release=''9069f719716240d7b738cd6f41a60f032805b33f9a7604926f36ee5899fa63e8'' where menu_id=28 and type=1
update ccmenus set release=''5c56447be49b20be68afcc90e3c04e816a76a1803de48898ab149f77e3c411f93cf22f161ef5e79fd9615ca8abe8e544'' where menu_id=29 and type=1
update ccmenus set release=''5698b9e6ebf6ed35823013e0c9937b15918c4c76d786b1c6cd80bd5611467283e49ca208bf37b2fdc0fddfd559851a0fffe45446c12f0a742320ece3e669ccf9'' where menu_id=30 and type=1
update ccmenus set release=''01ecf72c0d94f3a93cc6754f9e44b9a6'' where menu_id=32 and type=1
update ccmenus set release=''d97175d74af3b9d9152f1c606b5763e2663a6cd01d5313cef307cf52e8036216b6504c68c08429ad30565ae8dcfd7abd'' where menu_id=35 and type=1
update ccmenus set release=''d2cbc14611cb43181d724b13d76fd12d35bdec94a4340724b1427088491a4292d04a5eacd6413482200045f26ccf718c'' where menu_id=36 and type=1
update ccmenus set release=''89d5ec707d341b1fb374ea97aa1247868017195c0153f5025b08974df82c54fd'' where menu_id=38 and type=1
update ccmenus set release=''793625d951fb18db179715d3163af415a5fed4fda8a9cab3d014f851c35f0e07'' where menu_id=40 and type=1
update ccmenus set release=''3019576729a6fef6b140465b6baf9ad8550bc41e0de9a2ec407a94fb88b530941cf8f5207c5cf633d0f13ea712f5b62d'' where menu_id=41 and type=1
update ccmenus set release=''9f54271c454bdc582cee3c666e3f98e1bf5aa306fd577f2af8b6c647b64aeef3666b2398e73dec6f43b4f60729ffbafa35a93cfc10f0cf2e30b1d10dc4cc1db4'' where menu_id=42 and type=1
update ccmenus set release=''b14dfaa33570212ebf08ddc649b950b5c5ca6292b23a79e8b39d3ad3b12d67ab4a962ce3d75eb93a84925aa5c67be951'' where menu_id=43 and type=1
update ccmenus set release=''7172795309f1fa16c6115d56b3c7d287073ff1bbb59eb064560ddb981d7fd730beaf9019762af7c4e1829f9482c1ce3d'' where menu_id=44 and type=1
update ccmenus set release=''527590c40bfd963f637edd5cc63a0c06edcdd114ec2633d45e1a526ff8325b93'' where menu_id=45 and type=1
update ccmenus set release=''de2919ca4d64fb1651f0b15aa8e0e28b6e74c1d7b377bbc2501de2e77cd0afba09a186b6d92169877bb090544a68d9f7'' where menu_id=46 and type=1
update ccmenus set release=''481636551cd0cd1335a23da6d06e3a1d'' where menu_id=47 and type=1
update ccmenus set release=''0136b908696acb11b0399e25cff6f54ec76f668f15be3da0422c589b94a1ab2e77da6f20b7a3c0cdbac484df09f78db35125f207db0d7ffc3d28a45f4fedcbe4'' where menu_id=48 and type=1
update ccmenus set release=''e7444bff31cf8690971a3765fd7be8856ac97e7b828c495c5b07f01ce535ab57c3c8d530156cc144b0d3507762c27b20776d04f44e7300d76452b12627b7e98f'' where menu_id=49 and type=1
update ccmenus set release=''8a54b89d53297e7871a0c4072a3de33a36f98b8e6efa1fcd54f21e3f16c41fe89f366c4101b513b5d80b7c02fdc2e94ee082c2fbc939e0262cd9586166731fd0'' where menu_id=50 and type=1
update ccmenus set release=''b14dfaa33570212ebf08ddc649b950b57265ec8090a8690301f81ad44d94ddcf'' where menu_id=51 and type=1
update ccmenus set release=''7202fae50d36c63c3e4cbb3bb409e489085477320ab8f171532bebb3ec1d11045b7dc8274da14f1aadb402438205ddca'' where menu_id=52 and type=1
update ccmenus set release=''ffcfecd78fa179024db85f3e3a359f8c9e9b9b5efdd743bc9006cf139b3fc7cdbaf644f68e31fcc4d9a916554bccbbda26ac9dd8ce595871ce8b98b96774f217eaff5c64bdb74612533e943497b803d5'' where menu_id=53 and type=1
update ccmenus set release=''c7439dca463672a2f50dc0d2f578859a13296b1734caeb86bf603b538b6630bba0263e050a3384aa0eae426f47507c7b'' where menu_id=54 and type=1
update ccmenus set release=''9b3d10c34e016fa606c8503329315c02ca3038b855baeac7761b4570cf3ebaa8116d2990a02e4deacea76985d864df2d'' where menu_id=55 and type=1
update ccmenus set release=''9f54271c454bdc582cee3c666e3f98e103c54f0483feb0bad0e947c1c2133354db6dea4a4afafbe122f15ca4d69960f3a73ef19a775ecae05c9a822db2500a89'' where menu_id=56 and type=1
update ccmenus set release=''ec7b3d37a7c244aa749664387d2ad4bf504fb7de7b4115e7803b2ac84e09a7cd7669b8938f063fa1bf2bd342773033fe3d1e4fcc22b040641cae0bf7ed319753'' where menu_id=57 and type=1
update ccmenus set release=''95f092f5890652ffac6e3fdb26b40cf6eb3437a8bb265520dde05f5747937ac90b542746d22ab6652513c5a2b024cf68'' where menu_id=58 and type=1
update ccmenus set release=''9f54271c454bdc582cee3c666e3f98e11776165c80cc437046384e056ab4ed37e5e77994ffbe645787c136367f589933'' where menu_id=59 and type=1
update ccmenus set release=''4a2b132fca6cadb0130c5562d71d093e'' where menu_id=60 and type=1
update ccmenus set release=''afc997e7761f14f12b57430761bfff3049f42426abab7d4b2dff735fded61be7'' where menu_id=61 and type=1
update ccmenus set release=''0136b908696acb11b0399e25cff6f54eece46ae72f4917c62756999e53b36771e51def5030da9b37a08d39bdc40bd4b7'' where menu_id=62 and type=1
update ccmenus set release=''1471b681995a8c35ec8397a536ec36bbfa3eb650dca35ca0afbdb7edba59c10d743fc320ca4e48c89efc48a1a2912a84'' where menu_id=63 and type=1
update ccmenus set release=''67f0e4ac0a6b9b86ea70c212ebc1fdf38e5d88c818d02affc9fe5662db0e42d1faf3c4942671970f64dcded61429bf5b1ebed460bf017d72ed86919b963bbaf6'' where menu_id=64 and type=1
update ccmenus set release=''13d2f0a6b06bbb6cb5b3c59a6cae341c04ac1da0222d1191e0ffe0815cff26f6777649885309b1813407e4d5c70340ed'' where menu_id=65 and type=1
update ccmenus set release=''9dce99cc0370199e66b7c5e0e371d343bf0a2e3af7036d84a693b9fbf923a3f77e7a1d4a9e365e8ce4dd2c4ac05bdacb'' where menu_id=69 and type=1
update ccmenus set release=''7202fae50d36c63c3e4cbb3bb409e489b8041a66c81b61b518f83368e18cfc3e493bcc2c903b51b75642f7fa7da1e4ea'' where menu_id=70 and type=1
update ccmenus set release=''93a41caf4f2dd0c1f6e0bb1ad57526d0'' where menu_id=71 and type=1
update ccmenus set release=''60f9172cb2499c5bc34f64bb4a9a6cfc19488080042f8a086f7ccfd02fd6bc84'' where menu_id=72 and type=1
update ccmenus set release=''e286fc4ffbbcb5084d6cc222d60567f6fbebfcfa11913cc4f580db7713dfad04'' where menu_id=73 and type=1
update ccmenus set release=''54c093e373302ff86aece5040cc4de2b25b4a9b98de8b775f93b91cd599398bbe6547ef63aa6ba086fd6207aeb68b3b0'' where menu_id=74 and type=1
update ccmenus set release=''79ed371512e649e77dd10fa99c7d904acaa304b371a9d374797d1dfce44500d75751dd7dde4cbd1a3b53c2071e60b806'' where menu_id=75 and type=1
update ccmenus set release=''614c124db2384775a4a2011f900ffc30e3ede48abf7ba7b419fc25887c6efe75'' where menu_id=76 and type=1
update ccmenus set release=''ed93be8757f2d065ba8e1da0137bc1e7eb912738d52ec64ebf960dc06697dd9f58b831d628813db6953c3e59337e20d7cfcd07d03b9623aed3d1b03c3e3baef4aef94616ad64ea4f3c6148dbcc90897a'' where menu_id=77 and type=1
update ccmenus set release=''56ac1ed791ca894d238dc1349280b5a1e2c5c7ccc83038a562725f7f72942c73f39b384757526e186e0bec1e991c7b9d70449b38ddbd01b27113b1ef75edd1014943b8f0370cddeee3a70c3185c484bf'' where menu_id=78 and type=1
update ccmenus set release=''fec74cbaf0b2d7132ee780dabe498950701d593b62b59207952a3858088748796613d769010ed9b960e240dd4220eef2'' where menu_id=79 and type=1
update ccmenus set release=''6776bac546a32695e551cc6053276fecf54e1307ffa6d723ad6534933ae7aa7450930cb3ef30aca7d165f84414990f42'' where menu_id=80 and type=1
update ccmenus set release=''bda45847247b99acea62e0014335612a3a5c9650e6e18e8338724238b8e6ccfa583d5100bf3b90e376a0601f12f118a67a1b67be454ec2af354aefc10868288b241fe9c4ea130334b320843d2e884aab82999b176ba5a77c732b33aea621b156'' where menu_id=82 and type=1
update ccmenus set release=''b2b37d592e84fed0ad51de3d43fc0a28'' where menu_id=83 and type=1
update ccmenus set release=''6b82b3ec881a02c800504125e9300790'' where menu_id=84 and type=1'
		EXEC(@sql)

	set @process = 'Update Data - ccmenus type 3'
	set @sql='update ccmenus set release=''96d529790ccfca0b873be2921b21fc8e'' where menu_id=2000
update ccmenus set release=''c706077b228a003efcba36c3d76f8ccd02311f94c169f3d90625bfe06452ddf345f779f5c8f73d4a8eef54ef85d6f66d'' where menu_id=2010 and type=3
update ccmenus set release=''3cfc9a33dc5200222201e875d19251c976eae7d305214c2ed2e3128774bbaa6c'' where menu_id=2020 and type=3
update ccmenus set release=''a9f0cd825f8c38e2204fe4850277c64910c10a400868c8ca015225ea49bfe9ad'' where menu_id=2030 and type=3
update ccmenus set release=''8ef05a0599ad8a0ad4bcace93d3da032f50b53ac2086c961607a3085ad1a03cc31ea83ea698de717f5a8a71507a7dac5'' where menu_id=2040 and type=3
update ccmenus set release=''0f10d0f3975fea415f64116b08b3f0f4158b1a1c1255a581f66da60fdbb9f92231022e099f594c858ed05b8ad8b5ef79'' where menu_id=2050 and type=3
update ccmenus set release=''92abc655568830781f4b86ee96a0d7154c0d824251a9f7ed7ac8e471aed27b7a'' where menu_id=3000 and type=3
update ccmenus set release=''88671a67a73c950bc8e1af9f0e227c0f0f64ff6cac783bf28d06ea68775a3a27d990d4d2fd470e6a5e8eb40953729a49'' where menu_id=3010 and type=3
update ccmenus set release=''21c9167ed1f5346df3fc24bba193f68ae416e2b354ac1d6b9a0d37f767bff137e9d50f8c83b49b621ce8c838d72691f6b96a3dfe005e14c988bca7dff7701e52d3db66aa10a4497cbaf146a90013984bc565435959b42df48ff9daf82e38622c'' where menu_id=3020 and type=3
update ccmenus set release=''897d365fe1309008528b223040d8fe68a655baad738599eec65bbd1b356120277764e76105b7eaa3086a4bd94ac203e07e5b08622dfd73cc34f59ab20d2edd0054bc598b21fd8b0237421b5021030032ae788e956254d9d045366c629b5ba945'' where menu_id=3030 and type=3
update ccmenus set release=''54d108e6439d9428e2b8fd3e9f91fdee51be0db6cdc332bb21353a33b0290c23502ba00ff62717982e9b50dd734050d12501c9effbe49383f5cfa2bced65191db6ea50452c9fd86b085b43b637647fcae12af54f0a8957d5ca562d741cd6ba56'' where menu_id=3040 and type=3
update ccmenus set release=''dfe863a9b40b5e3e799358a093aa026ab804aaa55991bce93b22625cc4e91f19'' where menu_id=3060 and type=3
update ccmenus set release=''618eb9b6a71e84267143b7cedc82d1964ff1c1127f25547f8d2ffc613dbec777'' where menu_id=3070 and type=3
update ccmenus set release=''7a173c9014c92a563fd31045490c1b7d5dab68d8178ba964630f4f45850f2401'' where menu_id=3080 and type=3
update ccmenus set release=''70b4a3d32ba74c0e7cf258a505a2a87f75ebc1d90789d54b9326ad55ca032624'' where menu_id=3100 and type=3
update ccmenus set release=''ee6c372bb76697296ddf9c822cf0f0413a909d990e67e9cd23d0b816182cde7d16cc33daa29c6ea3c2b28be8f4052971'' where menu_id=3110 and type=3
update ccmenus set release=''1daa38c5c8f28a1aa8d4d98293b41be12544c5b63f7ebc0b0adde3906df6ce7818a384b387507e79c91c2adfbd3e9581'' where menu_id=3120 and type=3
update ccmenus set release=''9dc688d26be7d959afc7af108c35ef8f'' where menu_id=3130 and type=3
update ccmenus set release=''0d736f3481c6d1c942da49622f98db9805e1e5c411e81d0d66b812113e21db17'' where menu_id=3131 and type=3
update ccmenus set release=''56512fc2d7e0fd5f73a9fef24d21dd082991c459a9c36412d6afbc193429757254a0ea17808d051fed2e1e954eb98921'' where menu_id=3132 and type=3
update ccmenus set release=''00a720a507936015857fbeee4942e742a519ab593a79a8b8e0462cb7428cd9c4'' where menu_id=3133 and type=3
update ccmenus set release=''f20593a343b0b62c599e778fade2f79607a5a9ba8ea0c6e26c9a0cbe96f52a292aa2b5dd5a94f53d94a02de4b5b83b48115e0f2641c48abea9ed12c783d3f987'' where menu_id=3134 and type=3
update ccmenus set release=''eca6fbbc13298872edb507549bcd07d81bab739c9ac50a154667ed4439e77f7558db251482bceb1e1610bbcc81d0cbfb'' where menu_id=3135 and type=3
update ccmenus set release=''9c0ebebe2827fef16c1a39c19a25b6abbd4b09dd91e3d384afe10f7f02c1ee7ef242e45b0e4ebfaf8f59e6fc854a6f213080a6ae646f12ddb568c564288e2221'' where menu_id=3136 and type=3
update ccmenus set release=''26f540a73d36cea7632922a967892fbc'' where menu_id=3140 and type=3
update ccmenus set release=''7657fe7b3c16fd849a1b96da2b3a1ab4710ecf89f08f2468489b14137f017b1c'' where menu_id=3141 and type=3
update ccmenus set release=''58d4dc99cd15d638724baa23ced7904a92f69511abfd5adbbf02d9e37ae98603'' where menu_id=3142 and type=3
update ccmenus set release=''3df6b7dc4342106773d35c9daa327d1275e906be15781b95b5cfb9a9bb7e1cd3'' where menu_id=4000 and type=3
update ccmenus set release=''94b6faad25978826165a3650f2ac52419cacff55c626eba9a6f167d6c3aa443814ee1ad7516802370122df67cea4af10'' where menu_id=4010 and type=3
update ccmenus set release=''6e47659dcaf4473cf1414f28c8c3e5963ba40799a1b493c45118651d66980d3828b2b1d7a4ac8717cf9dfb7f558fc6155b243d86ad38d20468aa7a96a31617a2'' where menu_id=4020 and type=3
update ccmenus set release=''7f9603c7b03b294b1e3bf597edce2c52a3a156b41984b36ce220d2d6f14a4e6cba260d0ee5cd64e8f7cbbe8723f222de003b4de0d4da1f61e64cf69f04dc0078145d9d7a567fe68c20747b39f2d45d7009b7be7c99e6b448de21e95d18654e2d'' where menu_id=4030 and type=3
update ccmenus set release=''86ce8cbbe658db12522d483d082a8c7db5ee2873b0449dc419dfbdaafbacc0727f341365a711302b884f3cf3fcb3a7e79783ce0e8ce937d7db9bca8d4ee1acaf2be1692f427983529b13ba586e6d63d1'' where menu_id=4040 and type=3
update ccmenus set release=''ded69caddd3292663d1c288191974f77c293acdf7c0eeb41a99acab089a41cb26aa6f528788f3d3ef2a622c8051e7413b343cccd73fbbdaa6aa603ab19890d13'' where menu_id=4050 and type=3
update ccmenus set release=''1bd5c741650fc4f3a194486d99c23fbdd86e6a629a076303376fcc28be7e64d1'' where menu_id=4060 and type=3
update ccmenus set release=''fc0c387ebf579858b90c4f8f53fcf825576d14c6f239bb8ac507c6cee889596dd6da97c7c41a55f086cd327f6352519aa0f24ae7ea6a838163164b52a76be8297d10c6bb433680fe30dd4e1484efbfe98f6cc5b55430e0f7768db234952d38cd'' where menu_id=4070 and type=3
update ccmenus set release=''086f81cc6471414063117c5fdfbbbea7abd8139d996435dd276bb3745b30fe0d07710b4c7caa520333dde9d66558468b'' where menu_id=4090 and type=3
update ccmenus set release=''f9bd3104348eebb06d7417f73071b96cfe83fcdf8b3183ce992d1515ff619de71b301605aafbd9b1877adb6258abe060'' where menu_id=4100 and type=3
update ccmenus set release=''23541c08d5c45c0bbdc418fd3c6d3c977267ab0f93ec550c64ae8f616403dc45'' where menu_id=4110 and type=3
update ccmenus set release=''6283c7b8c70a61261c23495ad0d60d0eb6eb57e4ba562cddfcdd69554c841eff563bdad7f660b97fa30e5302b08bc061c8d8605b311176d2fdddc4a30427a9ce'' where menu_id=4120 and type=3
update ccmenus set release=''7f9603c7b03b294b1e3bf597edce2c52f2a3d3635d138a40248da16a757c755d7f23dc5f5f75305799ef8851b1b19c5712a0b18fc666e243fcc29f749924323d'' where menu_id=4130 and type=3
update ccmenus set release=''dcb850d9556a21ad8aa2b04cb1c805201d844d742b968ce9571ca24476bcf8c17ab06c58fc2aa71d2f9e182d31a3de899fa680622471fa2e8706e2e4e07f6094f85f74751873240e266c953d334eae13'' where menu_id=4140 and type=3
update ccmenus set release=''93a41caf4f2dd0c1f6e0bb1ad57526d0'' where menu_id=6000 and type=3
update ccmenus set release=''f7adec3242a59f86dc4f3a8072e5719494b8cdf81e2e17efb63b081df73a98fb'' where menu_id=6010 and type=3
update ccmenus set release=''00a21455609916b202052d466a352b5e055fa9c97a6702927ccbb25f648d1154'' where menu_id=6020 and type=3
update ccmenus set release=''9ae737a9afce05eaf5cbbf25e2ba8b3f1a11feb6ade86e49a24cc15d9657765fd15f768844d5bf62c5c7bad13fc8462e'' where menu_id=6030 and type=3
update ccmenus set release=''15c4927a18daca287dd9c826d6b1ee7e0f537b88dd19607d17a04d1ce2ed9779'' where menu_id=6040 and type=3
update ccmenus set release=''ba0bc68dfaf1522a21afa079a09a3eecbf5645bf4993b53c628f82508e20d565'' where menu_id=7000 and type=3
update ccmenus set release=''738ebc86f3f41c09dfbc766e6916e79acfba1ff528ff3200df04344760549be11837c395be68986d9dee1d375ee34983'' where menu_id=7010 and type=3
update ccmenus set release=''6127bfcd82490ed646b4932d276f186f9ac429af9c4214ff5dbece19d98c750377ff5dab61c8e5874566c63be1141ea3'' where menu_id=7020 and type=3
update ccmenus set release=''5d571d4f307b7d64c401eac958f36de9d9d17d1c0743b6712c0ad6b4ec198d95d5c9f5fb8e7bc05c946de5094edfa52993e4fb7a719dd5698bce354427c39991'' where menu_id=7030 and type=3
update ccmenus set release=''64a52235cd512a5867e3bf128b595fda6dd523479e736d9a755677146402aca9c783aa35248a5b85956f5e26d8645544'' where menu_id=7040 and type=3
update ccmenus set release=''c914940aa9fd9c40a06f419be041c7ece815861d64e35df3ade5953c0c3c24a0a3e926adbeef5be0baad8d7c5eb1903e'' where menu_id=7050 and type=3
update ccmenus set release=''5e6c6d0cc8edcaf5acce272ed069253c8968da51ce51256954e0cd470b03f9f2ac3965e1be65537cc311bf8bb67a845c'' where menu_id=7060 and type=3
update ccmenus set release=''58595a92cd28d166cdc11a451aff268ca45da90edb35dbabca6f34225264c783'' where menu_id=7070 and type=3
update ccmenus set release=''7698d560a7941b44d0142bf76a8028412670e700436a70dd13928a68aab5b907d245bd4323a9f574bbced8ee8a41d1dc52cdd25476f3c5732d6a9a7f321b3c71'' where menu_id=7090 and type=3
update ccmenus set release=''7698d560a7941b44d0142bf76a802841fbcad4eda713dea692bba8a80b515b08803bcdf2e40745e5748ed346253479208c942c2af701a43c5b87c9cc7caf39fd'' where menu_id=7100 and type=3
update ccmenus set release=''7698d560a7941b44d0142bf76a802841e2b848149d7c40f78ec0939cacf7c32c234f8d06eda4c388b93c43f48c0b5ee12bc1abb915f7edf102dc7d15431cd541'' where menu_id=7110 and type=3
update ccmenus set release=''9069f719716240d7b738cd6f41a60f032805b33f9a7604926f36ee5899fa63e8'' where menu_id=8000 and type=3
update ccmenus set release=''0362defe0bc9aa21dbe5cdf084801c440fca0417e154644e0a273fe0ffdd9af5eefbad7bf6449f40b602ac53d3e74d8c'' where menu_id=8010 and type=3
update ccmenus set release=''1ef7d4766eabd1e58b5303a6f2bec7c891973e222c3dcafdb473746ffaef91aca50906345359875907408fb45abd6ea96ff4f151d0f922d6ccfa220e9e4792da'' where menu_id=8020 and type=3
update ccmenus set release=''0362defe0bc9aa21dbe5cdf084801c44a84362415fc694a1331ec564447b43e2ad1f77912821ad8766fd62bd2aeea59f9a411c1f5e97ea397847da93846809ef'' where menu_id=8030 and type=3
update ccmenus set release=''2da7610f9626dc12e7669ac08d4099bcd561d8a5e9e0c7a7264a4197b69de5b61e3cafea9d7d5a1a4b1083c4ce62514f'' where menu_id=8040 and type=3
update ccmenus set release=''eb381bfd4e3225b43b06919869c9b2ce660c7f15bcf18244d858679257552462'' where menu_id=8050 and type=3
update ccmenus set release=''098b160e934cbb372399f774ac695b31540b07c0014f952339e6e293f97e24f7037ef4a7c460aec66c1dc42833824d84'' where menu_id=8060 and type=3
update ccmenus set release=''4c642ea42197239d977bff10e4035aa9378655fe3712106e36b29030abf49d7d0be86734ca07a07f823fcaa4480f57d7168f625c940c1e5405a5674391620af5'' where menu_id=8061 and type=3
update ccmenus set release=''8b0111b1f10de1ea152007b418c596c856e3c588698f62f6709119ed044f7d27b88d57743cd6226cc6dd3bed3f9b50f681cfaa692139ee0190eb9708015f76b9463c3498f7075988f009900e85ad30da'' where menu_id=8062 and type=3
update ccmenus set release=''06f8c5bd67dc764b2d58954a5e159a725568801cc8bdd416a07041980d801c019d24990b0cfc41b1d65a16c50cb9ee932d04d2b9adae06476c316acd35ae7e04'' where menu_id=8063 and type=3
update ccmenus set release=''005a270289bb12e09e0a31738ac21f172edf271c421bfb55edc03eca24e56c0215943587b6de7475ca96b06c6ab1c2f98b7f9acaa5f2a394f1cc97b9f44505a4'' where menu_id=8064 and type=3
update ccmenus set release=''54d108e6439d9428e2b8fd3e9f91fdeef35a8a2cf1c81ac605f355c6c5ed088395115b82ed8c782e42034ee93bf0f95a8a2097109472d35847e3bebe7cbd90bde52ca6b741a9f3e9ea7e2b6b51517300'' where menu_id=8071 and type=3
update ccmenus set release=''119304beb0451b2a19536e41012819a7f75bb2a1ee3af087d714af6f1f001f1a90c4dff93d71654c5580714d6aa9b56f5fa5a8ef63f2c502cd89dd8a46ccee63'' where menu_id=8072 and type=3
update ccmenus set release=''96bdd3fb8047d75a1e63b64bd4ce72dc64c83960a38a3382a253ab751052edd44f579a4a7929d0feafd1ebbd48d87e33b72499508a40a62fc78a25fc5018a8f6'' where menu_id=8080 and type=3
update ccmenus set release=''481d0fc0c3158788180f9154ef1db2815a9a6ae40380130220db30317904d18f18f5efd9bf439ca1aa6f7b62830ca897aa58110be2452cb3dc8297230520e8dd492e783ebb326457d9cd195a5e15e845'' where menu_id=8081 and type=3
update ccmenus set release=''9203d567abe7573f85f9f5c55eec9e1735c2a70b838c90c05e86088e3da7163c98c180c59ae1055b3f81ab66d350134130e91c3b8697de14258accbfa92b061f9f802cfbd091662927dad032ab4cbf81'' where menu_id=8082 and type=3
update ccmenus set release=''153e6811eec81553748db0c3d4e2f22dcb71ee48e699af23268b31717ac2cebb5ce79d6f82713571404d9404d60c7947b50051fbebcdbbaceb8cff9d1ffc3bcb597e2c0dc067442e011eefdd82b199f19d191de23f96bcc48f255a28b78e878b'' where menu_id=8083 and type=3
update ccmenus set release=''02547c912615a1e4d6552bab57984ee3702a1fb1e963680cfa7044653de25db417da62f779d55da177e98335f1f4b77af879b89a8db6070fcbd689586dde4d7fdd62780a20e98e467f09486e1e59d0c9'' where menu_id=8084 and type=3
update ccmenus set release=''b2b37d592e84fed0ad51de3d43fc0a28'' where menu_id=9000 and type=3
update ccmenus set release=''7e1d6a08abb01a1b1e5c46c29b2958db888d78c14c873d56874902ff85e360be'' where menu_id=9010 and type=3'
	EXEC(@sql)

	set @process ='CREATE TABLE [dbo].[ccRIAMultimediaAddress]-------------'
	set @sql = 'if not exists (select * from sys.tables where name = N''ccRIAMultimediaAddress'')
begin
CREATE TABLE [dbo].[ccRIAMultimediaAddress]
(
	[address_id] [smallint] NOT NULL,
	[Description] [varchar](40) NOT NULL,
	[address] [varchar](254) NOT NULL,
	[Status] [bit] NOT NULL CONSTRAINT [DF_ccRIAMultimediaAddress_Status]  DEFAULT ((1)),

 CONSTRAINT [PK_ccRIAMultimediaAddress] PRIMARY KEY CLUSTERED
(
	[address_id] ASC
) ON [PRIMARY]
) ON [PRIMARY]
end'
	EXEC(@sql)

		set @process ='CREATE TABLE [dbo].[ccRIAMultimediaAddressRel] -------------'
	set @sql = 'if not exists (select * from sys.tables where name = N''ccRIAMultimediaAddressRel'')
begin
CREATE TABLE [dbo].[ccRIAMultimediaAddressRel](
	[address_id] [smallint] NOT NULL,
	[campAcd_id] [smallint] NOT NULL
) ON [PRIMARY]
end'
	EXEC(@sql)


	set @process ='----------------fn Verifica'
	set @sql = 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''Verifica'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
	begin
		drop FUNCTION Verifica
	end'
	EXEC(@sql)

	set @process ='---------------- drop trsp_AdmGetSatisfactionScoreFinder'
	set @sql = 'if exists (select * from sys.procedures where name = N''trsp_AdmGetSatisfactionScoreFinder'')
	begin
		drop procedure trsp_AdmGetSatisfactionScoreFinder
	end'
	EXEC(@sql)

	set @process ='---------------- drop [fnGetTimeZone]'
	set @sql = 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''fnGetTimeZone'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
	begin
		drop FUNCTION fnGetTimeZone
	end'
	EXEC(@sql)


	set @process ='---------------- CREATE FUNCTION [dbo].[fnGetTimeZone]'
	set @sql = 'CREATE FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN
	declare @lada as varchar(5)
	declare @timeZone as int
	declare @ld as varchar(5)
	declare @location as varchar(500)

	select @lada = valor from ccsettings where setting_id = 17
	select @ld = ''''
	select @location = ''''

	declare @country as tinyInt
	select @country = valor from ccSettings where setting_id = 104

		if @country = 1 begin

			if(exists(select top 1 cld from series nolock where cld=left(@phone,2)))
				select @ld = left(@phone,2)
			else if(exists(select top 1 cld from series nolock where cld=left(@phone,3)))
				select @ld = left(@phone,3)
			else
				return 0

			select @location = estado
			from series
			where cld = @ld
			and serie = substring(@phone, len(@ld) + 1, 6 - len(@ld))
			and right(@phone, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
			where id_country = @country and (
			( len(@phone) = 8 and @lada = area and len(area) = 2 )
			or
			( len(@phone) = 7 and @lada = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 2) = area and len(area) = 2 ))
			and location = @location
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

	if @country = 11 begin
		select @phone = dbo.Completa(@phone)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	if @country = 12 begin
		select @phone = dbo.Completa(@phone)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	if @country = 13 begin
		select @phone = dbo.Completa(@phone)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	return isNull(@timeZone,0)
 END'
	EXEC(@sql)


	set @process = 'Create SP -- ccspXionElementsRelease'
	set @sql='CREATE PROCEDURE  [dbo].[ccspXionElementsRelease]
@Type as tinyint,
@menu_id as smallint

AS
if @Type = 0
begin
	if (@menu_id=47)
		select menu_id,element from [dbo].[ccXionElementsRelease] where menu_id in(47,10)
	else
		select menu_id,element from [dbo].[ccXionElementsRelease] where menu_id=@menu_id
end'
		EXEC(@sql)

set @process = 'trsp_AdmGetSatisfactionScoreFinder - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''trsp_AdmGetSatisfactionScoreFinder'') DROP PROCEDURE trsp_AdmGetSatisfactionScoreFinder'
	EXEC(@Sql)

		set @process ='----------------CREATE  PROCEDURE trsp_AdmGetSatisfactionScoreFinder'
	set @sql = 'CREATE  PROCEDURE [dbo].[trsp_AdmGetSatisfactionScoreFinder]
			@id_chat as Int
			AS
			BEGIN
				SET NOCOUNT ON;
				select top 1 fmt.id_formato format_id,nombre format_name, Nombres+'' ''+ApellidoPaterno+'' ''+ApellidoMaterno quality_sup,total_forma score
				from RIA_FORMACALIF fmt join ccusers us on us.user_id=fmt.id_calificador
				join RIA_FORMATOS cfmt on cfmt.id_formato=fmt.id_formato
				where fmt.tipo=2 AND id_grabacion = @id_chat
			END'
	EXEC(@sql)

	set @process = 'ccsp_RIAMultimediaAddresses - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccsp_RIAMultimediaAddresses'') DROP PROCEDURE ccsp_RIAMultimediaAddresses'
	EXEC(@Sql)

	set @process = 'Create SP -- ccsp_RIAMultimediaAddresses'
	set @sql='CREATE procedure [dbo].[ccsp_RIAMultimediaAddresses]
@action smallint,
@Description as varchar(40) = null,
@address as varchar(254) = null,
@address_id as smallint = null,
@campAcd_id as smallint = null
as
set nocount on

if @action = 1 --Load initial info
begin
	select ci.inbound_id, descripcion, graphic_id from ccinbound ci (nolock) join ccRIAInboundGraph cg (nolock) on cg.Inbound_id = ci.Inbound_id where status=1 and chat=3
	select address_id,description,address from ccRIAMultimediaAddress nolock where status=1

	return(0)
end

if @action = 2 --Load addresses
begin
	select address_id,description,address from ccRIAMultimediaAddress nolock where status=1
	return(0)
end

if @action = 3 --Load relations
begin
	select sg.address_id,description,address from ccRIAMultimediaAddressRel re (nolock)
	join ccRIAMultimediaAddress sg (nolock) on sg.address_id = re.address_id where campAcd_id = @campAcd_id or @campAcd_id = 0
	return(0)
end

if @action = 4 --Add Address
begin
	If exists(select description from ccRIAMultimediaAddress where Status=1 and address=@address)
	 begin
		select 2
		return(0)
	 end

	If exists(select description from ccRIAMultimediaAddress where Status=0 and address=@address)
	begin
		update ccRIAMultimediaAddress set Status=1,address=@address where description=@Description
		return(0)
	end

	insert into ccRIAMultimediaAddress (address_id, description, address)
	select isnull(max(address_id), 0) + 1,@Description,@address from ccRIAMultimediaAddress
	return(0)
end

if @action = 5 --Update Address
begin
	If exists(select description from ccRIAMultimediaAddress where Status=1 and address=@address)
		set @Description=null

	UPDATE ccRIAMultimediaAddress set Description=isnull(@Description, Description), address=isnull(@address, address)
	where address_id = @address_id
	return(0)
end

if @action = 6 --Delete Address
begin
	delete ccRIAMultimediaAddressRel where address_id = @address_id
	update ccRIAMultimediaAddress set Status=0 where address_id = @address_id
	return(0)
end

if @action = 7 --Delete relation
begin
	delete ccRIAMultimediaAddressRel where address_id = @address_id and (campAcd_id = @campAcd_id /*or @campAcd_id = 0*/)
	return(0)
end

if @action = 8 --Add relation
begin
	if not exists(select * from ccRIAMultimediaAddressRel where address_id = @address_id and campAcd_id = @campAcd_id)
	begin
		insert ccRIAMultimediaAddressRel (address_id, campAcd_id) values (@address_id, @campAcd_id)
	end
	return(0)
end

set nocount off'
		EXEC(@sql)



    set @process ='-------ALTER PROCEDURE ccsp_RIAConfEspec'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
				@User_id int
				AS
				set nocount on

				declare @sql nvarchar(max)

				if not exists (SELECT * FROM sysobjects WHERE type = ''U'' AND name = ''ContactMeanIn'') begin
					set @sql=''select A.inbound_id, A.Descripcion, A.Status, A.tNotas,
				A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
				A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
				A.OpriorityT, A.callerIdDesc, A.chat, A.inactiveChatTime, A.maxChats, A.chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
				isnull(A.startStopRecording,0) as startStopRecording,'''''''' as nameMail,'''''''' as conexionInfo,'''''''' as connUser,'''''''' as connPass,3 as numMessages,10 as timeAlertMessage, 0 as Active, 0 as answerTimeOut
				from ccInbound A where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (''+convert(nvarchar(max),@User_id)+'', 2))''

				end
				else begin
					set @sql=''select A.inbound_id, A.Descripcion, A.Status, A.tNotas,
				A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
				A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
				A.OpriorityT, A.callerIdDesc, A.chat, A.inactiveChatTime, A.maxChats, A.chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
				isnull(A.startStopRecording,0) as startStopRecording,isnull(B.name,'''''''') as nameMail,isnull(B.conexionInfo,'''''''') as conexionInfo,isnull(B.connUser,'''''''') as connUser,
				isnull(B.ConnPass,'''''''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage,
				isnull(B.IsActive,0) as Active, isnull(B.answerTimeOut,0) as answerTimeOut
				from ccInbound A
				left join ContactMeanIn B on A.inbound_id=B.inboundId
				where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (''+convert(nvarchar(max),@User_id)+'', 2))''
					end

				exec (@sql)

				return(0)
				set nocount off'
	EXEC(@sql)




	set @process ='---------------- CREATE fn Verifica'
	set @sql = 'CREATE FUNCTION [dbo].[Verifica](@tel varchar(32))
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

	if @pais= 11
		begin -- Inicia Guatemala
			select @tel = dbo.completa(@tel)
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
			select @tel = dbo.completa(@tel)
			if left(@tel,1) <> ''E''
				begin
					if len(@tel)=8
						if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
							return @tel
						else
							return ''E_'' + @tel
				end
			else if len(@tel)=10
				begin
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
		end -- Termina Costa Rica

	if @pais= 13
		begin -- Inicia Salvador
			select @tel = dbo.completa(@tel)
			if left(@tel,1) <> ''E''
				begin
					if len(@tel)=8
						if exists(select zonaGeografica from seriesSV (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
							return @tel
						else
							return ''E_'' + @tel
				end
			else
				if charindex(substring(@tel,1,2),''00'') <= 0
					return ''E_'' + @tel
				else
					return @tel
		end -- Termina Salvador

	return @tel
 end'
	EXEC(@sql)



	set @process ='ALTER PROCEDURE [dbo].[ccsp_ExtAppsGetDialInfo]-----------'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_ExtAppsGetDialInfo]
			@action tinyint = 0,
			@logDial_id int = null
			As
			Begin

				If @action = 1 begin
					select count(*) from ccologdials with(nolock) where logDial_id >= @logDial_id
				end

				if @action = 2 begin
					select top 500 logDial_id, callout_id, isnull(a.cam_id,0) as camId, isnull(c.cam_descripcion,'''') as camDescription,
					isnull(b.descripcion,''Unknown'') as DialResult, Telefono, fecha, tDialing, tBusy, isnull(cal_id,0) as cal_id, cal_key
					from ccologdials a with(nolock)
					inner join ccTipoResultadoDial b
					on a.tiporesdial_id = b.tiporesdial_id
					inner join ccCamps c
					on a.cam_id = c.cam_id
					where logDial_id >= @logDial_id
				end

			End'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_RIACATMenu'
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
		select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
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



	set @process = 'Alter SP -- ccsp_RiaMenuByRole'
	set @sql='ALTER procedure [dbo].[ccsp_RiaMenuByRole]
@Type tinyint,
@role_id smallint = null,
@Menu_id smallint = null,
@CM tinyint = 0,
@AE tinyint = 0
as
set nocount on

select @AE = valor from ccsettings where setting_id = 71
Declare @NRS tinyint
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

If @Type = 1 -- Get language
begin
	select valor from ccSettings where setting_id = 27
	return(0)
end

If @Type = 2 -- Carga todos los roles
begin
	select Role_id, Description from ccRIACat_AdminRole where type = 1 order by priority
	return(0)
end

If @Type = 3 -- Carga roles
begin
select rm.role_id, m.menu_descrip, rm.id_menu,rm.type,m.release from dbo.ccRIARoleMenu rm, ccmenus m where rm.id_menu = m.menu_id and rm.role_id = @role_id and rm.type = 1 and
	((rm.id_Menu not in (41,42,53)) or (rm.id_Menu = 41 and @CM = 1) or (rm.id_Menu = 42 and @ae > 0) or (rm.id_Menu = 53 and @NRS = 1))
	return(0)
end

declare @language tinyint
select @language=valor from ccSettings where setting_id = 27

If @Type = 4 -- Inserta rol
begin
if not exists(select role_id from ccRIARoleMenu where role_id = @role_id and id_Menu = @Menu_id and type = 1)
begin
	Insert into ccRIARoleMenu (role_id, id_Menu, type) values(@role_id, @Menu_id, 1)
	select
		(select case @language when 0 then substring(Description, 1, charindex(''|'',Description)-1)
		else substring(Description, charindex(''|'',Description)+1, len(Description)) end
		from ccRIACat_AdminRole where role_id=@role_id) as sRole,

		(select case @language when 0 then substring(menu_descrip, 1, charindex(''|'',menu_descrip)-1)
		else substring(menu_descrip, charindex(''|'',menu_descrip)+1, len(menu_descrip)) end
		from ccMenus where menu_id=@Menu_id) as sMenu
	return(0)
end
end

If @Type = 5 -- Elimina rol
begin
delete from ccRIARoleMenu where role_id =@role_id  and id_Menu=@Menu_id and type= 1
select
	(select case @language when 0 then substring(Description, 1, charindex(''|'',Description)-1)
	else substring(Description, charindex(''|'',Description)+1, len(Description)) end
	from ccRIACat_AdminRole where role_id=@role_id) as sRole,

	(select case @language when 0 then substring(menu_descrip, 1, charindex(''|'',menu_descrip)-1)
	else substring(menu_descrip, charindex(''|'',menu_descrip)+1, len(menu_descrip)) end
	from ccMenus where menu_id=@Menu_id) as sMenu
return(0)
end'
	EXEC(@sql)

	set @process ='ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig]'
	set @sql = 'ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig]
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
				@dRestrictPlay bit = null
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
				startStopRecording = isnull(@dRestrictPlay,startStopRecording)
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
	EXEC(@sql)



	set @process = 'Alter SP -- ccsp_RIAMenuRoles'
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
			(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82,84,85))
			or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)
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



	set @process = 'Alter SP -- ccspRIA_AdminPermissions'
	set @sql='ALTER procedure [dbo].[ccspRIA_AdminPermissions]
@Type tinyint,	-- 1:Catalogo/2:Supervisores/3:permisos_X_supervisor/4:actualiza_supervisor/5:actualiza_todo
@user_id smallint = null,
@per_id tinyint = null,
@value bit=1
as
set nocount on
if @Type = 1
	begin
	declare @Idioma bit
	select @Idioma = valor from ccsettings where setting_id = 27
	select per_id, case @Idioma when 0 then substring(per_desc, 1, charindex(''|'',per_desc)-1)
	else substring(per_desc, charindex(''|'',per_desc)+1, len(per_desc))
	end per_desc,release
	from ccRIACat_AdminPermissions where bStatus = 1
	return(0)
	end

if @Type = 2
	begin
	select User_id, Login, Nombres +
	replace(''''+isnull(ApellidoPaterno, '''') + ''''+isnull(ApellidoMaterno, ''''), '''', '''') Nombre
	from ccUsers where tipouser_id in (2,6)
	order by Login
	return(0)
	end

if @Type = 3
	begin
	if not exists(select user_id from ccUsers where TipoUser_id in(2,6) and user_id = @user_id)
		return(0)

	select c.per_id, cast(cast(isnull(u.user_id, 0) as bit) as tinyint) value
	from ccRIACat_AdminPermissions c
		left join ccRIAUsr_AdminPermissions u
		on c.per_id = u.per_id and u.user_id = @user_id
	where c.bStatus = 1
		order by c.per_id
	return(0)
	end

if @Type = 4
	begin
	if cast(@User_id as bit) <> 1 or cast(@per_id as bit) <> 1
	return(0)

	if @value=0
		delete ccRIAUsr_AdminPermissions where user_id = @user_id and per_id = @per_id

	else if not exists (select user_id from ccRIAUsr_AdminPermissions where user_id = @user_id and per_id = @per_id)
		insert ccRIAUsr_AdminPermissions select @user_id, @per_id
	return(0)
	end

if @Type = 5
	begin
	if not exists(select per_id from ccRIACat_AdminPermissions)
		return(0)

	if @value=0
		delete ccRIAUsr_AdminPermissions where per_id = @per_id

	else
		insert into ccRIAUsr_AdminPermissions select User_id , per_id
		from ccUsers cross join ccRIACat_AdminPermissions
		where tipouser_id in (2,6) and per_id in (@per_id)
		and cast(User_id as varchar(10)) + ''|'' + cast(per_id as varchar(10))
		not in (select cast(User_id as varchar(10)) + ''|'' + cast(per_id as varchar(10))
		from ccRIAUsr_AdminPermissions)
		order by 1,2
	return(0)
	end
set nocount off'
	EXEC(@sql)


			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			--UPDATE settings SET value=@version WHERE id= 77
			exec ccsp_getVersion 'BDF', @versionfix ----- **********se quito BDF

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
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