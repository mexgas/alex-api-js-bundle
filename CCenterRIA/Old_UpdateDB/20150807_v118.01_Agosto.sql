/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2014/10/06
Description:

-------ALTER PROCEDURE [dbo].[ccsp_ExtAppsGetDialInfo]
------- alter table ccRIACat_Areas --------
-------  ALTER TABLE ccSettings--------
------- update cstoTipoLlamada----------
------- insert into ccRIACat_Country
------- update ccMenus
------- update ccsettings
------- update cstoTipoLlamada
------- delete ad update cstoTipoLlamada
------- ALTER function [dbo].[Completa]
------- ALTER FUNCTION [dbo].[Completa_ListaNegra]
------- ALTER FUNCTION [dbo].[fnGetTimeZone]
------- alter function [dbo].[fnGetTipoLlamada]
ALTER function [dbo].[TelAni]
ALTER FUNCTION [dbo].[Verifica]
ALTER PROCEDURE [dbo].[ccsp_ExtAppsGetDialInfo]
ALTER PROCEDURE [dbo].[ccsp_GetAgentECRelations]
ALTER procedure [dbo].[ccsp_Limpia]
ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
ALTER PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
ALTER PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
ALTER PROCEDURE [dbo].[ccsp_RIADialerAssignment]
ALTER PROCEDURE [dbo].[ccsp_RIAUpdateChatConfig]
ALTER PROCEDURE [dbo].[ccspADM_AniListLD]
ALTER PROCEDURE [dbo].[ccsp_RIAChatPredefinedMsg]
ALTER PROCEDURE [dbo].[ccsp_AgentLogINOUT]

ALTER PROCEDURE [dbo].[ccsp_RIAInsertChat]
ALTER PROCEDURE  [dbo].[ccsp_AdmGetSupervisorsForAgent]
------se agrega scrip de email





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

set @version = 118--**********actualizar a 118 sin fix
set @versionfix = 1
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


--update  ccsettings
--set valor = '117.87.81.2'
--where setting_id = 77

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version-1
	begin
		begin tran
		begin try

		set @process = 'update Plan de marcacion Arabia Saudita'
		set @sql='update seriesSA set [serie Inicio] = ''000'', [serie fin] = ''999'' where CLD in (''050'',''051'',''052'',''053'',''054'',''055'',''056'',''057'',''058'',''059'')'
		EXEC(@sql)

		set @process = 'insert into ccXionElementsRelease'
		set @sql='if not exists(select * from ccXionElementsRelease where menu_id=17 and element=''47d1d650e38623ac894993d6db5d4956'') begin
		insert into ccXionElementsRelease(menu_id,element) values(17,''47d1d650e38623ac894993d6db5d4956'')
		insert into ccXionElementsRelease(menu_id,element) values(17,''6cf851d43a1383a71247fddc91475306'')
			end'
		EXEC(@sql)

		set @process = 'insert into ccXionElementsRelease'
		set @sql='if not exists(select * from ccMenus where parent =8050) begin
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF) values(8050,''Calidad|Quality'',8050,''A'',8,3,'''')
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8060,''Formatos de calificacion|Scoring Templates'',8050,''B'',8,3,'''')		
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8080,''Encuestas de Satisfaccion|Customer Satisfaction Service'',8050,''B'',8,3,'''')			
end
if not exists(select * from ccMenus where parent=8060) begin
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8061,''Agente(Formatos de Calificación)|AgentScoringTemplates'',8060,''C'',8,3,'''')		
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8062,''Supervisor(Formatos de Calificación)|SupervisorScoringTemplates'',8060,''C'',8,3,'''')		
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8063,''Conceptos(Formatos de Calificación)|SectionsScoringTemplates'',8060,''C'',8,3,'''')		
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8064,''Preguntas(Formatos de Calificación)|QuestionsScoringTemplates'',8060,''C'',8,3,'''')		
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8071,''Calificaciones(Formatos de Calificación)|DispositionsScoringTemplates'',8060,''C'',8,3,'''')		
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8072,''Detalle(Formatos de Calificación)|DetailScoringTemplates'',8060,''C'',8,3,'''')		
end
if not exists(select * from ccMenus where parent=8080) begin
insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8081,''Agente(Encuestas de Satisfacción)|AgentCustomerSatisfactionService'',8080,''C'',8,3,'''')		
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8082,''Preguntas(Encuestas de Satisfacción)|QuestionsCustomerSatisfactionService'',8080,''C'',8,3,'''')		
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8083,''Calificaciones(Encuestas de Satisfacción)|DispositionsCustomerSatisfactionService'',8080,''C'',8,3,'''')		
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8084,''Detalle(Encuestas de Satisfacción)|DetailCustomerSatisfactionService'',8080,''C'',8,3,'''')
end'
		EXEC(@sql)

		set @process = 'update ccMenus-----------'
		set @sql='update ccMenus set menu_descrip = ''Plantillas de Multimedios|Multichannel Templates'',release=''fec74cbaf0b2d7132ee780dabe49895018e021439aaf0fa2d4d9f24ae3d2c6cacf39911a86fc8d63e1c236431d80d3470a8636aca7d924faa50353e8e7cd9612'' where menu_id = 79
		update ccmenus set  menu_descrip=''Guión de agentes|Scripting'', release=''60f9172cb2499c5bc34f64bb4a9a6cfc19488080042f8a086f7ccfd02fd6bc84'' where menu_id=72 and type=1'
		EXEC(@sql)


		set @process = 'update ccMenus-----------Xion License'
		set @sql='update ccmenus set release=''eb381bfd4e3225b43b06919869c9b2ce660c7f15bcf18244d858679257552462'' where menu_id=8050 and type=3
update ccmenus set release=''098b160e934cbb372399f774ac695b31540b07c0014f952339e6e293f97e24f7037ef4a7c460aec66c1dc42833824d84'' where menu_id=8060 and type=3
update ccmenus set release=''96bdd3fb8047d75a1e63b64bd4ce72dc64c83960a38a3382a253ab751052edd44f579a4a7929d0feafd1ebbd48d87e33b72499508a40a62fc78a25fc5018a8f6'' where menu_id=8080 and type=3
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

update ccMenus set release=''09cbbffafe26e97542fa49002c1ec5e68f2311d4e350aee98eac29f8fe77b538731750fedffaa62e936863a755d0df28'' where type=1 and menu_id=85
update ccMenus set release=''9f54271c454bdc582cee3c666e3f98e12009688903015cfbe334af813fc6c7cecd1268e1c3c95a6aab047205aa93c286'' where menu_id=76'
		EXEC(@sql)




		set @process = 'alter table ccRIACat_Areas --------'
		set @sql='if not exists (select * from sys.columns where name = N''maxChats'' and Object_ID = Object_ID(N''ccRIACat_Areas''))
		alter table ccRIACat_Areas add maxChats tinyint not null default(3)'
		EXEC(@sql)

		set @process = 'ALTER TABLE ccSettings--------'
		set @sql='if not exists (select * from sys.columns where name = N''validate'' and Object_ID = Object_ID(N''ccSettings''))
		ALTER TABLE ccSettings ADD validate varchar(255) default('''')'
		EXEC(@sql)


		set @process = 'update cstoTipoLlamada----------'
		set @sql='if not exists(select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where DATA_TYPE = ''varchar'' and CHARACTER_MAXIMUM_LENGTH = 15
					and COLUMN_NAME = ''longitud'' and TABLE_NAME = ''cstoTipoLlamada'')
					begin
						select * into cstoTipoLlamada_bkp from cstoTipoLlamada
						alter table cstoTipoLlamada drop column longitud
						alter table cstoTipoLlamada add longitud varchar(15)
						update cstoTipoLlamada set longitud=b.longitud from cstoTipoLlamada_bkp b join cstoTipoLlamada c on b.country_id=c.country_id and b.tipollamada_id=c.tipollamada_id
						drop table cstoTipoLlamada_bkp
					end'
		EXEC(@sql)



		
		
		
		

		set @process = 'update ccSettings------------'
		set @sql='update ccSettings set validate=''.*''
					update ccSettings set Tipo=''X'' where setting_id=87
					update ccSettings set validate=''^\d{1,2}$'' where setting_id=1
					update ccSettings set validate=''^\d{1,99}$'' where setting_id=17
					update ccSettings set validate=''^[0-1]$'' where setting_id=18
					update ccSettings set validate=''^[0-1]$'' where setting_id=26
					update ccSettings set validate=''^[0-1]$'' where setting_id=27
					update ccSettings set validate=''^\d{1,4}$'' where setting_id=28
					update ccSettings set validate=''^\d{1,4}$'' where setting_id=29
					update ccSettings set validate=''^\d{1,33}$'' where setting_id=30
					update ccSettings set validate=''^[0-1]$'' where setting_id=32
					update ccSettings set validate=''^[0-1]$'' where setting_id=33
					update ccSettings set validate=''^[0-1]$'' where setting_id=34
					update ccSettings set validate=''^\d{1,2}$'' where setting_id=35
					update ccSettings set validate=''^[0-1]$'' where setting_id=40
					update ccSettings set validate=''.{0,99}'' where setting_id=41
					update ccSettings set validate=''.{0,99}'' where setting_id=42
					update ccSettings set validate=''.{0,99}'' where setting_id=42
					update ccSettings set validate=''.{0,99}'' where setting_id=43
					update ccSettings set validate=''.{0,99}'' where setting_id=44
					update ccSettings set validate=''.{0,99}'' where setting_id=45
					update ccSettings set validate=''.{0,99}'' where setting_id=46
					update ccSettings set validate=''.{0,99}'' where setting_id=47
					update ccSettings set validate=''.{0,99}'' where setting_id=48
					update ccSettings set validate=''.{0,99}'' where setting_id=49
					update ccSettings set validate=''.{0,99}'' where setting_id=50
					update ccSettings set validate=''.{0,99}'' where setting_id=51
					update ccSettings set validate=''.{0,99}'' where setting_id=52
					update ccSettings set validate=''^[0-3]$'' where setting_id=53
					update ccSettings set validate=''.{0,99}'' where setting_id=54
					update ccSettings set validate=''.{0,99}'' where setting_id=55
					update ccSettings set validate=''.{0,99}'' where setting_id=58
					update ccSettings set validate=''^\d{1,3}$'' where setting_id=59
					update ccSettings set validate=''^[0-1]$'' where setting_id=60
					update ccSettings set validate=''^\d{1,2}$'' where setting_id=63
					update ccSettings set validate=''^\d{1,2}$'' where setting_id=64
					update ccSettings set validate=''^\d{1,2}$'' where setting_id=65
					update ccSettings set validate=''^((([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d),?)+$'' where setting_id=66
					update ccSettings set validate=''^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d)$'' where setting_id=67
					update ccSettings set validate=''^[0-1]$'' where setting_id=68
					update ccSettings set validate=''^[0-1]$'' where setting_id=70
					update ccSettings set validate=''^[0-3]$'' where setting_id=71
					update ccSettings set validate=''^[0-3]$'' where setting_id=72
					update ccSettings set validate=''^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d),.+,.+,.+,[0-1]$'' where setting_id=73
					update ccSettings set validate=''.{0,99}'' where setting_id=74
					update ccSettings set validate=''^[0-1]$'' where setting_id=75
					update ccSettings set validate=''^[0-1]$'' where setting_id=76
					update ccSettings set validate=''^[0-1]$'' where setting_id=78
					update ccSettings set validate=''^[0-1]$'' where setting_id=79
					update ccSettings set validate=''^[0-1]$'' where setting_id=80
					update ccSettings set validate=''^[0-1]$'' where setting_id=81
					update ccSettings set validate=''^[0-1]$'' where setting_id=82
					update ccSettings set validate=''^[0-1]$'' where setting_id=83
					update ccSettings set validate=''^\d{1,3}$'' where setting_id=84
					update ccSettings set validate=''^\d{1,3}$'' where setting_id=85
					update ccSettings set validate=''^[1-4]$'' where setting_id=87
					update ccSettings set validate=''^[0-1]$'' where setting_id=88
					update ccSettings set validate=''^[0-1]$'' where setting_id=89
					update ccSettings set validate=''^[0-1]$'' where setting_id=90
					update ccSettings set validate=''^[0-1]$'' where setting_id=91
					update ccSettings set validate=''^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d):\d+$'' where setting_id=92
					update ccSettings set validate=''^\d{1,3}$'' where setting_id=94
					update ccSettings set validate=''^[0-1]$'' where setting_id=95
					update ccSettings set validate=''^[0-1]$'' where setting_id=96
					update ccSettings set validate=''^[0-1]$'' where setting_id=97
					update ccSettings set validate=''^(\w+\.?)+\|[_a-z0-9-]+(.[_a-z0-9-]+)*@[a-z0-9-]+(.[a-z0-9-]+)*(.[a-z]{2,4})\|.*\|\d+\|[0-1]$'' where setting_id=98
					update ccSettings set validate=''^[0-2]$'' where setting_id=99
					update ccSettings set validate=''^\d{1,32}$'' where setting_id=101
					update ccSettings set validate=''^\d{1,2}$'' where setting_id=102
					update ccSettings set validate=''^[0-1]$'' where setting_id=103
					update ccSettings set validate=''^\d{1,2}$'' where setting_id=104
					update ccSettings set validate=''^[0-1]$'' where setting_id=105
					update ccSettings set validate=''^[0-1]$'' where setting_id=107
					update ccSettings set validate=''^[1-9]?$'' where setting_id=108
					update ccSettings set validate=''^\d{1,2}$'' where setting_id=109
					update ccSettings set validate=''^[0-1]$'' where setting_id=110
					update ccSettings set validate=''^[0-1]$'' where setting_id=111
					update ccSettings set validate=''^[0-1]$'' where setting_id=112
					update ccSettings set validate=''^[0-1]$'' where setting_id=114
					update ccSettings set validate=''^[0-1]$'' where setting_id=115
					update ccSettings set validate=''^[0-1]$'' where setting_id=117
					update ccSettings set validate=''^[0-1],.+,.+,.+$'' where setting_id=118
					update ccSettings set validate=''^\d{1,6}$'' where setting_id=119
					update ccSettings set validate=''^[0-1]$'' where setting_id=120
					update ccSettings set validate=''^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \?=.-]*)*\/?$'' where setting_id=121
					update ccSettings set validate=''^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \?=.-]*)*\/?$'' where setting_id=122
					update ccSettings set validate=''^[0-1]$'' where setting_id=123
					update ccSettings set validate=''^[0-1]$'' where setting_id=126
					update ccSettings set validate=''^[0-1]$'' where setting_id=127
					update ccSettings set validate=''^[0-1]$'' where setting_id=128
					update ccSettings set validate=''^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \?=.-]*)*\/?$'' where setting_id=129
					update ccSettings set validate=''^[0-3]$'' where setting_id=130
					update ccSettings set validate=''^[1-3]\|((-1)?|[0-3])\|[0-39]\|[0-5]\|\d{1,2}\|\d{1,2}\|[0-4]\|.*\|\d{1,3}$'' where setting_id=131
					update ccSettings set validate=''^[0-3]$'' where setting_id=133
					update ccSettings set validate=''^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d):\d+$'' where setting_id=133
					update ccSettings set validate=''^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d):\d+$'' where setting_id=134
					update ccSettings set validate=''^\[0-1]]$'' where setting_id=135
					update ccSettings set validate=''.{0,99}'' where setting_id=139
					update ccSettings set validate=''^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d)$'' where setting_id=140
					update ccSettings set validate=''^[0-1]$'' where setting_id=142
					update ccSettings set validate=''^((([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d),?)+$'' where setting_id=143
					update ccSettings set validate=''^(\d+\|((([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d),?))*$'' where setting_id=144
					update ccSettings set validate=''^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d)$'' where setting_id=146
					update ccSettings set validate=''^[0-1]$'' where setting_id=147
					update ccSettings set validate=''^\d+\|\d+(\|\d+\|\d+)?$'' where setting_id=149
					update ccSettings set validate=''^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \?=.-]*)*\/?$'' where setting_id=150

					update ccSettings set validate=''^[0-1]$'' where setting_id=152
					update ccSettings set validate=''^[0-1]$'' where setting_id=154

					update ccSettings set validate=''.{0,99}'' where setting_id=156
					update ccSettings set validate=''^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d)$'' where setting_id=157
					update ccSettings set validate=''^\d+\|\d+\|(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d)\|.+\|.+\|\d+\|(\*\.\w+;)+$'' where setting_id=160

					update ccSettings set validate=''^[0-1]$'' where setting_id=161
					update ccSettings set validate=''^[0-4]$'' where setting_id=162
					update ccSettings set validate=''^[0-1]$'' where setting_id=163
					update ccSettings set validate=''^[0-1]$'' where setting_id=164
					update ccSettings set validate=''^[0-1]$'' where setting_id=163

					update ccSettings set validate=''^[0-1]\|([0-1]?[0-9]|2[0-3]):[0-5][0-9]\|([0-1]?[0-9]|2[0-3]):[0-5][0-9]$'' where setting_id=166'
		EXEC(@sql)


		set @process = 'update cstoTipoLlamada---------'
		set @sql='update cstoTipoLlamada set longitud=''7|8'' where tipollamada_id=1 and country_id=1'
		EXEC(@sql)

		set @process = 'delete ad update cstoTipoLlamada ---------------'
		set @sql='if exists(select * from cstoTipoLlamada where country_id=9 and tipollamada_id=4)
					begin
						delete cstoTipoLlamada where country_id=9 and tipollamada_id=2
						update cstoTipoLlamada set tipollamada_id=2 where country_id=9 and tipollamada_id=3
						update cstoTipoLlamada set tipollamada_id=3 where country_id=9 and tipollamada_id=4
					end'
		EXEC(@sql)

		set @process = 'update cstoTipoLlamada---------'
		set @sql='update cstoTipoLlamada set prefijo=''2%|3%|4%|5%'' where country_id=10 and tipollamada_id=1
					update cstoTipoLlamada set prefijo=''6%|7%|8%|9%'' where country_id=10 and tipollamada_id=2
					update cstoTipoLlamada set prefijo=''02%|03%|04%|05%'' where country_id=10 and tipollamada_id=4
					update cstoTipoLlamada set prefijo=''06%|07%|08%|09%'' where country_id=10 and tipollamada_id=5'
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccsp_ExtAppsGetDialInfo] ----------'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_ExtAppsGetDialInfo]
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
		order by logDial_id
	end

End'
	EXEC(@sql)
	
	set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas] ---------'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
@option smallint,
@IDArea smallint,
@Descripcion varchar(40),
@maxMails smallint = 3,
@maxChats smallint = 3
AS

set nocount on

if @option=1 --Selected Area
 begin
	Select a.IDArea, AreaName, isnull(a.maxChats,0) as maxChats, isnull(maxMails,3) maxMails,
	isnull(users,0) users, isnull(admins,0) admins,
	isnull(camps,0) camps, isnull(acds,0) acds
	from ccRIACat_Areas a (nolock)
	left join (select IDArea , MAX(isnull(maxChats,0)) as maxChats from ccInbound GROUP BY IDArea) b on a.IDArea = b.IDArea
	left join (select IDArea,count(case when TipoUser_id = 1 then 1 else null end) users, count(case when TipoUser_id > 1 then 1 else null end) admins from ccusers (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) userswg on userswg.IDArea=a.IDArea
	left join (select IDArea,count(*) acds from ccinbound (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) acdswg on acdswg.IDArea=a.IDArea
	left join (select IDArea,count(*) camps from cccamps (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) campswg on campswg.IDArea=a.IDArea
	where StatusArea=1 and isnull(a.IDArea,0)=case isnull(@IDArea,0)
	when 0 then isnull(a.IDArea,0) else @IDArea end
	order by AreaName

	return(0)
 end

if @option=2 --Insert Area
 begin
	if exists(select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
	begin
		select -1--, Nombre en Uso
		return(0)
	   end

	Insert into ccRIACat_Areas (AreaName,maxMails,maxChats) values (@Descripcion,@maxMails,@maxChats)

	select 1, scope_identity()--, Area Insertada
	return(0)
 end

if @option=3 --Update Area
 begin
	if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
		Update ccRIACat_Areas set AreaName=@Descripcion,maxMails=@maxMails,maxChats=@maxChats where IDArea=@IDArea
		else
		Update ccRIACat_Areas set maxMails=@maxMails,maxChats=@maxChats where IDArea=@IDArea

	if (select max(maxChats) as maxChats from ccinbound where IDArea=@IDArea) <> @maxChats
		Update ccinbound set maxChats=@maxChats where IDArea=@IDArea

	return(0)
 end

if @option=4 --Delete Area
 begin
	if (exists(select IDArea from ccUsers where IDArea=@IDArea) or exists(select IDArea from ccCamps where IDArea = @IDArea)
		or exists(select IDArea from ccInbound where IDArea=@IDArea)) and (select valor from ccSettings where setting_id=95)<>1
	begin
		select -1
		return(0)
 end

	declare @DWorkGroups as varchar(500)

	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
	select user_id,cam_id,prioridad,skill,rel_id,IDWG
	from ccCampsAgente
	where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
	select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
	from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
	Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
	select user_id,cam_id,tipo,IDWG,monitored
	from ccSupervisorCam
	where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
	delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
	delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
	where cam_id in (select cam_id from ccCamps where IDArea=@IDArea))

	Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)
	Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)

	Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
	Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
	Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)

	select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea=@IDArea
	Delete from ccRIAAreaWorkGroup where IDArea=@IDArea

	if (select valor from ccSettings where setting_id=95)=1
begin
		Update ccInbound set IDArea=NULL, status=0 where IDArea=@IDArea
		Update ccCamps set IDArea=NULL where IDArea=@IDArea
		Update ccUsers set IDArea=NULL where IDArea=@IDArea
end

	Update ccRIACat_Areas set StatusArea=0 where IDArea=@IDArea

	select @DWorkGroups

	return(0)
end'
		EXEC(@sql)


	set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIADialerAssignment] --------------'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIADialerAssignment]
@User_Id smallint,
@cam_id smallint,
@dialer_id varchar(4000),
@Type2 tinyint,
@Type tinyint
AS
set nocount on
declare @SQL as nvarchar(4000), @nUser_id as nvarchar(10), @params as nvarchar(1000)

If @Type=0--get ports
		begin
	select a.dialer_id, a.puerto, a.Descripcion, b.descrip from ccoDialers a
	inner join cstoProvedor b on a.provedor_id=b.provedor_id
	order by a.dialer_id
	return(0)
end

If @Type=1--get cams
		begin
	SELECT a1.cam_id, cam_descripcion FROM ccCamps a1 inner join ccRIACampsGraph a2 on(a1.cam_id=a2.cam_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
	order by 2
	return(0)
		end

If @Type=2--get port/cam relation
		begin
	select c.cam_id, cd.dialer_id, d.descripcion,
	d.puerto, e.descrip from ccCamps c
	left join ccoDialerCamp cd on cd.cam_id=c.cam_id
	left join ccoDialers d on cd.dialer_id=d.dialer_id
	inner join cstoProvedor e on d.provedor_id=e.provedor_id
	where c.cam_id=@cam_id
	ORDER BY c.cam_id, cd.dialer_id
	return(0)
end

If @Type=3--delete port/dialer relation
begin
	If @Type2=1--Sistema
		begin
		set @nUser_id=@User_Id
		set @sql=''delete ccoDialerCamp where dialer_id in('' + @dialer_id + '')''
		execute sp_executesql @sql
		return(0)
		end

	If @Type2=2--Camp
		begin
		delete ccoDialerCamp where cam_id=@cam_id and dialer_id=@dialer_id
		return(0)
		end
end

If @Type=4--insert new relation
begin
	If @Type2=1--Sistema
		begin
		set @nUser_id=@User_Id
		set @sql=''insert ccoDialerCamp(cam_id, dialer_id)
		select a.cam_id, b.dialer_id from ccCamps a, ccoDialers b where
		b.dialer_id in('' + @dialer_id + '') and not exists(
		select c.cam_id, c.dialer_id from ccoDialerCamp c
		where b.dialer_id=c.dialer_id and a.cam_id=c.cam_id)''
		execute sp_executesql @sql
		return(0)
		end

	If @Type2=2--Camp
		begin
		set @params=''@Ncam_id int''
 		set @sql=''insert ccoDialerCamp(cam_id, dialer_id) select distinct @Ncam_id,
 		dialer_id from ccCamps, ccoDialers where dialer_id not in(select dialer_id
 		from ccoDialerCamp where dialer_id in('' + @dialer_id + '')and cam_id=@Ncam_id)
		and dialer_id in('' + @dialer_id + '')''
		execute sp_executesql @sql, @params, @Ncam_id=@cam_id
		return(0)
		end
end

If @Type=5--Get existance of dialers
 begin
	if exists (select c.cam_id, cd.dialer_id, d.descripcion,
			   d.puerto, e.descrip from ccCamps c
			   left join ccoDialerCamp cd on cd.cam_id=c.cam_id
			   left join ccoDialers d on cd.dialer_id=d.dialer_id
			   inner join cstoProvedor e on d.provedor_id=e.provedor_id
			   where c.cam_id = @cam_id)
		select 0
	else
		select 13
	return(0)
end'
		EXEC(@sql)


	set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateChatConfig] ----------------'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAUpdateChatConfig]
@action smallint = 0,
@idArea smallint = 0,
@maxChats smallint = 0
AS

if @action = 1 begin
	select @maxChats = maxChats from ccRIACat_Areas where IDArea = @idArea
	return @maxChats
end

if @action = 2 begin
	select @maxChats = maxChats from ccRIACat_Areas where IDArea = @idArea
	update ccInbound set maxChats = @maxChats where IDArea = @idArea
end'
		EXEC(@sql)


	set @process = 'ALTER PROCEDURE [dbo].[ccsp_AgentLogINOUT]-------------------'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_AgentLogINOUT]
@UserID smallint,
@Extension varchar(7)=null,
@Computer varchar(20)=null,
@TipoMov tinyint	-- 0= LogOut,  1=LogIN,	3=Consulta
AS
set nocount on

declare @hourlogin   varchar(8)
declare @sessionsecs int
declare @sessiontime varchar(8)
declare @fecha_ini datetime

IF  @TipoMov=1
 BEGIN
	Insert ccLogLogIn ( User_id, Extension, TipoMov ) Values( @UserID, @Extension, 1)
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
	Insert ccLogLogIn ( User_id, Extension, TipoMov ) Values( @UserID, @Extension, 0 )
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
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentECRelations]-----------'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_GetAgentECRelations]
@User_id smallint,@action int =0
AS
set nocount on

declare @idioma as bit, @tipo as varchar(6)

if @action=0 begin
	select distinct ''Tipo''=1, E.Inbound_id, E.descripcion, A.Login, A.user_id, prioridad, skill, E.cli_id
		from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id
		join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
	union
	select distinct ''Tipo''=2, C.cam_id, C.cam_descripcion, A.Login, A.user_id, prioridad, skill, C.cli_id
		from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id
		join ccUsers A  on A.user_id = CA.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
		order by ''Tipo''
end
else begin
	select distinct 1 tipo, E.Inbound_id, E.descripcion, A.Login, A.user_id, prioridad, skill, isnull(E.cli_id,0) cli_id
	,right(''0''+cast(1 as varchar(1)),1) + right(''00000''+cast(E.Inbound_id as varchar(5)),5)
	+ right(''00''+cast(prioridad as varchar(2)),2) + right(''00''+cast(skill as varchar(2)),2) sPertenencias
		from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id
		join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
		union
	select distinct 2 tipo, C.cam_id, C.cam_descripcion, A.Login, A.user_id, prioridad, skill, C.cli_id
	,right(''0''+cast(2 as varchar(1)),1) + right(''00000''+cast(C.cam_id as varchar(5)),5)
	+ right(''00''+cast(prioridad as varchar(2)),2) + right(''00''+cast(skill as varchar(2)),2) sPertenencias
		from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id
		join ccUsers A  on A.user_id = CA.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
		order by ''Tipo''

end'
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAInsertChat]--------------'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAInsertChat]
@action int,
@inboundId smallint = 0,
@domain varchar(50) = '''',
@session varchar(50) = '''',
@tTimeout smallint = 0,
@chatId int = 0,
@status tinyInt = 0,
@userId smallint = 0,
@finished tinyInt = 0,
@chattingTime int = 0,
@startTime datetime = null,
@clientName varchar(50) = '''',
@firstMessage int = 0,
@firstMessageTime datetime = null,
@crmNode xml = null,
@supervisor varchar(100) =null,
@template varchar (100)= null,
@ScoreTemplate int = null
AS

declare @xml xml
declare @sql nvarchar(2000)

if @action = 1 begin -- Inserta nuevo chat request /*comentario: se recomienda hacer la busqueda del userid del CRM en esta action*/
       insert into ccRIAChats (domain,session,chatStatus,requestDate,inboundId,clientName)
       values(@domain,@session,@status,getDate(),0,@clientName)
       set @chatId = scope_identity()
       select @chatId
end

else if @action = 2 begin -- Save Initial Info
update ccRIAChats set inboundId = @inboundId, chatStatus = @status, userId = @userId, tTimeout = @tTimeout where chatId = @chatId
end

else if @action = 3 begin -- Update Status
update ccRIAChats set chatStatus = @status where chatId = @chatId
end

else if @action = 4 begin -- Save Final Status
if @firstMessage = 0
				begin
             update ccRIAChats set finishedBy = @finished where chatId = @chatId
				end
			else
				begin
             update ccRIAChats set finishedBy = @finished, firstMessageTime  = @firstMessageTime where chatId = @chatId
				end
		end

else if @action in (5,6) begin -- Save Chatting Time /*comentario: la insercion del nodo (registro final para el finder) se recomiendo en esta action, no olvidar validar status = 4, finishedby != null y validar los tiempos para garantizar el dato final */
       if @action = 5 begin
             update ccRIAChats set tChatting = @chattingTime, chatDate = @startTime where chatId = @chatId
       end



       select @xml = convert(xml,''<R01 C01="''+convert(varchar(max),chatId)+''" C02="''+convert(varchar(max),isnull(ccinbound.descripcion,''''))+''" C03="''+convert(varchar(max),domain)+''" C04="''+convert(varchar(max), Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno )+
       ''" C05="''+convert(varchar(max),tchatting)+''" C06="''+convert(varchar(max),isnull(cctipocalif.[Description],''''))+''" C07="''+convert(varchar(max),isnull(cctipocalifsub.califSubdesc,''''))+''" C08="''+convert(varchar(max),clientname)+''" C09="''+rtrim(ltrim(convert(varchar(23), chatDate, 126)))+
       ''" C10="''+convert(varchar(max),isnull(@supervisor,'''') ) + ''" C11="''+convert(varchar(max),isnull(@template,'''') )  + ''" C12="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +  ''"/>'')
       from ccRIAChats
       left outer join ccinbound on ccinbound.inbound_id = ccRIAChats.inboundid
       left outer join ccusers on ccusers.user_id = ccRIAChats.userid
       left outer join cctipocalif on cctipocalif.calif_id = ccRIAChats.disposition
       left outer join cctipocalifsub on cctipocalifsub.califsub_id = ccRIAChats.subdisposition and ccRIAChats.subdisposition <> 0
       where chatId = @chatId and chatStatus = 4 and requestDate is not null and chatDate is not null

       set @crmNode = null

       if @xml is not null
       begin
             select @crmNode = node from ccCRMNodes where chatId = @chatId
             if @crmNode is not null
             begin
                    set @sql = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R01)[1]'''') ''
                    execute sp_executesql @sql,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
             end

             if not exists(select * from ccChatsNode where chatId=@chatId) begin ---insert finder
                    insert into ccChatsNode (chatId,node, dateIn,[status]) values (@chatId,@xml, getdate(),0)
             end
             else begin ---update finder<
                    update ccChatsNode set [status] = 2, node =@xml  where chatId = @chatId
                    select @chatId
             end
       end
end'
	EXEC(@sql)

----------------------------------------------PLAN DE SPAIN----------------------------------------------
set @process = 'Create table -- seriesEsp'
	set @Sql='if not exists (select * from sys.tables where name = N''seriesEsp'')
	begin
		CREATE TABLE [dbo].[seriesEsp](
	[IdSeriesEsp] [int] NOT NULL,
	[Provincia] [varchar](50) NOT NULL,
	[Indicativo] [varchar](2) NOT NULL,
	[NumInicial] [varchar](8) NOT NULL,
	[NumFinal] [varchar](8) NOT NULL,
	[indicativoProvincia] [varchar](3) NOT NULL)
	end'	

	EXEC(@Sql)

	
	set @process = 'insert -- seriesEsp'
	set @Sql='if not exists(select * from seriesEsp) begin
	insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(373,''A Coruña-La Coruña'',''8'',''81000000'',''81999999'',''881'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(374,''Madrid'',''8'',''10000000'',''19999999'',''81'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(375,''Barcelona'',''8'',''30000000'',''39999999'',''83'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(376,''Bizkaia-Vizcaya'',''8'',''40000000'',''49999999'',''840'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(377,''Avila'',''8'',''20000000'',''20999999'',''820'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(378,''Segovia'',''8'',''21000000'',''21999999'',''821'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(379,''Santa Cruz de Tenerife'',''8'',''22000000'',''22999999'',''822'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(380,''Salamanca'',''8'',''23000000'',''23999999'',''823'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(381,''Badajoz'',''8'',''24000000'',''24999999'',''824'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(382,''Toledo'',''8'',''25000000'',''25999999'',''825'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(383,''Ciudad Real'',''8'',''26000000'',''26999999'',''826'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(384,''Cáceres'',''8'',''27000000'',''27999999'',''827'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(385,''Las palmas (Islas Canarias)'',''8'',''28000000'',''28999999'',''828'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(386,''La Rioja'',''8'',''41000000'',''41999999'',''841'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(387,''Cantabria'',''8'',''42000000'',''42999999'',''842'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(388,''Gipuzkoa-Guipúzcoa'',''8'',''43000000'',''43999999'',''843'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(389,''Álava-Araba'',''8'',''45000000'',''45999999'',''845'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(390,''Burgos'',''8'',''47000000'',''47999999'',''847'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(391,''Navarra-Nafarroa'',''8'',''48000000'',''48999999'',''848'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(392,''Guadalajara'',''8'',''49000000'',''49999999'',''849'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(393,''Almería'',''8'',''50000000'',''50999999'',''850'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(394,''Málaga'',''8'',''51000000'',''51999999'',''851'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(395,''Málaga'',''8'',''52000000'',''52999999'',''852'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(396,''Jaen'',''8'',''53000000'',''53999999'',''853'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(397,''Sevilla'',''8'',''54000000'',''54999999'',''854'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(398,''Sevilla'',''8'',''55000000'',''55999999'',''855'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(399,''Cádiz'',''8'',''56000000'',''56999999'',''856'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(400,''Ceuta'',''8'',''56000000'',''56999999'',''856'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(401,''Córdoba'',''8'',''57000000'',''57999999'',''857'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(402,''Granada'',''8'',''58000000'',''58999999'',''858'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(403,''Huelva'',''8'',''59000000'',''59999999'',''859'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(404,''Valencia-Valéncia'',''8'',''60000000'',''60999999'',''860'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(405,''Valencia-Valéncia'',''8'',''61000000'',''61999999'',''861'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(406,''Valencia-Valéncia'',''8'',''62000000'',''62999999'',''862'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(407,''Valencia-Valéncia'',''8'',''63000000'',''63999999'',''863'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(408,''Castellón-Castelló'',''8'',''64000000'',''64999999'',''864'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(409,''Alicante-Alacant'',''8'',''65000000'',''65999999'',''865'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(410,''Alicante-Alacant'',''8'',''66000000'',''66999999'',''866'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(411,''Albacete'',''8'',''67000000'',''67999999'',''867'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(412,''Murcia'',''8'',''68000000'',''68999999'',''868'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(413,''Cuenca'',''8'',''69000000'',''69999999'',''869'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(414,''Baleares-Balears'',''8'',''71000000'',''71999999'',''871'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(415,''Girona-Gerona'',''8'',''72000000'',''72999999'',''872'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(416,''Lleida-Lérida'',''8'',''73000000'',''73999999'',''873'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(417,''Huesca'',''8'',''74000000'',''74999999'',''874'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(418,''Soria'',''8'',''75000000'',''75999999'',''875'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(419,''Zaragoza'',''8'',''76000000'',''76999999'',''876'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(420,''Tarragona'',''8'',''77000000'',''77999999'',''877'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(421,''Teruel'',''8'',''78000000'',''78999999'',''878'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(422,''Palencia'',''8'',''79000000'',''79999999'',''879'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(423,''Zamora'',''8'',''80000000'',''80999999'',''880'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(424,''Lugo'',''8'',''82000000'',''82999999'',''882'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(425,''Valladolid'',''8'',''83000000'',''83999999'',''883'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(426,''Asturias'',''8'',''84000000'',''84999999'',''884'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(427,''Asturias'',''8'',''85000000'',''85999999'',''885'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(428,''Pontevedra'',''8'',''86000000'',''86999999'',''886'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(429,''Leon'',''8'',''87000000'',''87999999'',''887'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(430,''Ourense-Orense'',''8'',''88000000'',''88999999'',''888'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(431,''A Coruña-La Coruña'',''9'',''81000000'',''81999999'',''981'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(432,''Madrid'',''9'',''10000000'',''19999999'',''91'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(433,''Barcelona'',''9'',''30000000'',''39999999'',''93'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(434,''Bizkaia-Vizcaya'',''9'',''40000000'',''49999999'',''940'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(435,''Avila'',''9'',''20000000'',''20999999'',''920'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(436,''Segovia'',''9'',''21000000'',''21999999'',''921'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(437,''Santa Cruz de Tenerife'',''9'',''22000000'',''22999999'',''922'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(438,''Salamanca'',''9'',''23000000'',''23999999'',''923'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(439,''Badajoz'',''9'',''24000000'',''24999999'',''924'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(440,''Toledo'',''9'',''25000000'',''25999999'',''925'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(441,''Ciudad Real'',''9'',''26000000'',''26999999'',''926'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(442,''Cáceres'',''9'',''27000000'',''27999999'',''927'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(443,''Las palmas (Islas Canarias)'',''9'',''28000000'',''28999999'',''928'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(444,''La Rioja'',''9'',''41000000'',''41999999'',''941'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(445,''Cantabria'',''9'',''42000000'',''42999999'',''942'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(446,''Gipuzkoa-Guipúzcoa'',''9'',''43000000'',''43999999'',''943'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(447,''Álava-Araba'',''9'',''45000000'',''45999999'',''945'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(448,''Burgos'',''9'',''47000000'',''47999999'',''947'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(449,''Navarra-Nafarroa'',''9'',''48000000'',''48999999'',''948'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(450,''Guadalajara'',''9'',''49000000'',''49999999'',''949'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(451,''Almería'',''9'',''50000000'',''50999999'',''950'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(452,''Málaga'',''9'',''51000000'',''51999999'',''951'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(453,''Málaga'',''9'',''52000000'',''52999999'',''952'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(454,''Jaen'',''9'',''53000000'',''53999999'',''953'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(455,''Sevilla'',''9'',''54000000'',''54999999'',''954'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(456,''Sevilla'',''9'',''55000000'',''55999999'',''955'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(457,''Cádiz'',''9'',''56000000'',''56999999'',''956'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(458,''Ceuta'',''9'',''56000000'',''56999999'',''956'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(459,''Córdoba'',''9'',''57000000'',''57999999'',''957'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(460,''Granada'',''9'',''58000000'',''58999999'',''958'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(461,''Huelva'',''9'',''59000000'',''59999999'',''959'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(462,''Valencia-Valéncia'',''9'',''60000000'',''60999999'',''960'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(463,''Valencia-Valéncia'',''9'',''61000000'',''61999999'',''961'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(464,''Valencia-Valéncia'',''9'',''62000000'',''62999999'',''962'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(465,''Valencia-Valéncia'',''9'',''63000000'',''63999999'',''963'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(466,''Castellón-Castelló'',''9'',''64000000'',''64999999'',''964'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(467,''Alicante-Alacant'',''9'',''65000000'',''65999999'',''965'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(468,''Alicante-Alacant'',''9'',''66000000'',''66999999'',''966'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(469,''Albacete'',''9'',''67000000'',''67999999'',''967'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(470,''Murcia'',''9'',''68000000'',''68999999'',''968'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(471,''Cuenca'',''9'',''69000000'',''69999999'',''969'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(472,''Baleares-Balears'',''9'',''71000000'',''71999999'',''971'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(473,''Girona-Gerona'',''9'',''72000000'',''72999999'',''972'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(474,''Lleida-Lérida'',''9'',''73000000'',''73999999'',''973'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(475,''Huesca'',''9'',''74000000'',''74999999'',''974'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(476,''Soria'',''9'',''75000000'',''75999999'',''975'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(477,''Zaragoza'',''9'',''76000000'',''76999999'',''976'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(478,''Tarragona'',''9'',''77000000'',''77999999'',''977'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(479,''Teruel'',''9'',''78000000'',''78999999'',''978'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(480,''Palencia'',''9'',''79000000'',''79999999'',''979'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(481,''Zamora'',''9'',''80000000'',''80999999'',''980'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(482,''Lugo'',''9'',''82000000'',''82999999'',''982'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(483,''Valladolid'',''9'',''83000000'',''83999999'',''983'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(484,''Asturias'',''9'',''84000000'',''84999999'',''984'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(485,''Asturias'',''9'',''85000000'',''85999999'',''985'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(486,''Pontevedra'',''9'',''86000000'',''86999999'',''986'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(487,''Leon'',''9'',''87000000'',''87999999'',''987'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(488,''Ourense-Orense'',''9'',''88000000'',''88999999'',''988'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(489,''Móvil'',''6'',''00000000'',''99999999'',''6'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(490,''Móvil'',''7'',''00000000'',''99999999'',''7'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(491,''Tarifas especiales'',''9'',''00000000'',''00999999'',''900'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(492,''Llamadas masivas'',''9'',''05100000'',''05299999'',''905'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(493,''Llamadas masivas'',''9'',''05400000'',''05599999'',''905'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(494,''Llamadas masivas'',''9'',''05700000'',''05899999'',''905'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(495,''Tarificación sobre sistemas de datos'',''9'',''07000000'',''07999999'',''907'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(496,''Acceso conmutado a red'',''9'',''08200000'',''08499999'',''908'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(497,''Acceso conmutado a red'',''9'',''09200000'',''09499999'',''909'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(498,''Red privada virtual'',''5'',''00000000'',''09999999'',''50'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(499,''Voz en internet (vocal nómada)'',''5'',''10000000'',''19999999'',''51'')
insert into seriesEsp(IdSeriesEsp,Provincia,Indicativo,NumInicial,NumFinal,indicativoProvincia) values(500,''Máquina a máquina (M2M)'',''5'',''90000000'',''99999999'',''59'')
	end'	
		
	EXEC(@Sql)


	set @process = 'insert -- cstoTipoLlamada'
	set @Sql='if not exists(select * from cstoTipoLlamada where country_id=14) begin
	insert into cstoTipoLlamada(country_id,tipoLlamada_id,descrip,prefijo,longitud) values(14,1,''Local'',''8%|9%'',''9'')
	insert into cstoTipoLlamada(country_id,tipoLlamada_id,descrip,prefijo,longitud) values(14,2,''Celular'',''6%|7%'',''9'')
	insert into cstoTipoLlamada(country_id,tipoLlamada_id,descrip,prefijo,longitud) values(14,3,''LD internacional'',''00%'',''0'')
	insert into cstoTipoLlamada(country_id,tipoLlamada_id,descrip,prefijo,longitud) values(14,4,''Servicios web'',''5%'',''9'')
end'		
	EXEC(@Sql)	

	set @process = 'insert into ccRIACat_Country ------------'
	set @sql='if not exists(select * from ccRIACat_Country where CtyName =''España'')
		insert into ccRIACat_Country (CtyName, CtyCode, minPhoneLength, maxPhoneLength) values (''Spain'', ''34'', 9, 9)'
	EXEC(@sql)

	set @process = 'update ccsettings----------'
	set @sql='update ccsettings
		set detalle = ''1:Mexico, 2:Argentina, 3:Colombia, 4:USA, 5:Chile, 6: Venezuela, 7: Reino Unido, 8: Arabia saudita, 9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:Spain''
		where setting_id = 104'
	EXEC(@sql)

	set @process = 'ALTER function [dbo].[Completa] -------------'
		set @sql='ALTER function [dbo].[Completa](@Cadena varchar(32))
RETURNS varchar(32)
AS
BEGIN
declare @resultado varchar(32)
declare @ld varchar(5)
declare @pais varchar(2)

select @pais = valor from ccSettings where setting_id = 104
select @ld = valor from ccSettings where setting_id = 17
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

-- Termina
return @resultado

end'
	EXEC(@sql)

	set @process = 'ALTER FUNCTION [dbo].[Completa_ListaNegra]  ----------------'
	set @sql='ALTER FUNCTION [dbo].[Completa_ListaNegra] (@Cadena varchar(30))
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
		end
else begin
 select @resultado = dbo.Limpia(@cadena)
	end

return @resultado
end'
		EXEC(@sql)


		set @process = 'alter function [dbo].[fnGetTipoLlamada] ---------'
		set @sql='ALTER function [dbo].[fnGetTipoLlamada]( @tel varchar(20) )
					returns int
					as
					 begin
						declare @len integer, @tipo integer, @country varchar(5)
						declare @tipoLlamada_id smallint
	declare @prefijo varchar(15), @longitud varchar(15)

						declare @table table(
						id int not null,
						prefijo nvarchar(100) not null
						)

						select @country = valor from ccsettings where setting_id = 104
						set @len = len( @tel )
						set @tipo = 0

	declare @prefixTable table(
			tipoLlamada_id smallint not null,
	longitud varchar(15) not null,
			prefijo varchar(15) not null,
			[status] bit not null
			)

	insert into @prefixTable
			select tipoLlamada_id, longitud, prefijo, 0
	from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
	where country_id = @country 
	and (country_id <> 1 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11))) --no incluir tarifas por region (Mexico)
	order by len(prefijo) desc -- para tomar el mas especifico si se devuelven varios patrones

	while (select count(*) from @prefixTable where [status] = 0) > 0
			begin
				select top 1 @tipoLlamada_id = tipoLlamada_id, @longitud = longitud, @prefijo = prefijo
		from @prefixTable 
				where [status] = 0

				insert into @table
		select * from fn_RIASplitDelimited(@prefijo,''|'') order by len(value) desc

		if (select count(*) from fn_RIASplitDelimited(@longitud,''|'') where value=@len) = 1
					begin
						if (select count(*)	from @table	where @tel like prefijo) = 1
							set @tipo = @tipoLlamada_id
					end
		else if @longitud = ''0''
					begin
						if (select count(*)	from @table	where @tel like prefijo) = 1
							set @tipo = @tipoLlamada_id
					end

				if @tipo <> 0
			update @prefixTable
					set [status] = 1
				else
					begin
				update @prefixTable
						set [status] = 1
						where tipoLlamada_id = @tipoLlamada_id

						delete @table
					end
			end

	return @tipo
 end'
		EXEC(@sql)

	set @process = 'ALTER FUNCTION [dbo].[fnGetTimeZone] --------------'
	set @sql='ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
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
				select @ld = 0

			if @ld <> 0
				begin
					select @location = estado
					from series
					where cld = @ld
					and serie = substring(@phone, len(@ld) + 1, 6 - len(@ld))
					and right(@phone, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

					select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
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

	if @country = 14 begin
		select @phone = dbo.Completa(@phone)
		if (substring(@phone, 1, 1) <> ''E'') begin
			if len(@phone) = 9 begin
				select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
				where id_country = @country and ((substring(@phone, 1, 2) = area) or (substring(@phone, 1, 3) = area))
			end
		end
		end

	return isNull(@timeZone,0)
END'
		EXEC(@sql)


		set @process = 'ALTER FUNCTION [dbo].[Verifica]-----------'
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
			select @tel = dbo.completa(@tel)
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
			select @tel = dbo.completa(@tel)
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

	return @tel
end'
		EXEC(@sql)

	set @process = 'Alter SP -- ccsp_RIAccSettingsConfig'
	set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
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
	else if @setting_id = 104 and @value not in(''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'',''10'',''11'',''12'',''13'',''14'') begin
		set @value = 1
	end
	update ccSettings set valor=@value where setting_id = @setting_id
	return(0)
 end

set nocount off'
	EXEC(@Sql)	

	set @process = 'ALTER procedure [dbo].[ccsp_Limpia] ----------'
	set @sql='ALTER procedure [dbo].[ccsp_Limpia]
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
			if left(@tel,1)=''E'' begin
				select 3 as res, @telTemp -- No existe el telefono
			end
			else begin
				select 0 as res, @telTemp  -- Todo Bien
			end
			return(0)
		 end
		else
		 begin
			select 4 as res, @tel --lista negra
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

if @pais = 11 -- Guatemala
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

if @pais = 12 -- Costa Rica
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

if @pais = 13 -- Salvador
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

if @pais = 14 -- Spain
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
end'
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask] ---------------'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
@user_id integer,
@tel varchar(15)
AS
declare @mask integer, @idioma integer, @value integer, @lada integer
declare @country as tinyint

set @value = 0
select @mask = isnull(dialmask,7) from ccusers where user_id=@user_id
select @country = valor from ccsettings where setting_id = 104

-- Restricciones por pais 1:Mexico 2:Argentina 3:Colombia 4:USA 5:Chile 6:Venezuela 7:uk 8:Arabia Saudita, 9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador
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


--Guatemala
if @country = 11
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''3,4,5'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''2,6,7'') > 0
					set @value = 6
			end
		end

	end -- Termina Guatemala

--Costa Rica
if @country = 12
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''5,6,7,8'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''2,3,4'') > 0
					set @value = 6
			end
		end

	end -- Termina Costa Rica

--Salvador
if @country = 13
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''6,7'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''2'') > 0
					set @value = 6
	 end
 end

	end -- Termina Salvador

--Spain
if @country = 14
 begin
		--Restringe celulares
		if (@mask & 1)>0
	 begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''6,7'') > 0
				set @value = 4
	 end

		--Restringe locales
		if(@value=0)
	 begin
			if ((@mask & 4) > 0)
 begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''8,9'') > 0
					set @value = 6
			end
end

	end -- Termina Spain'
		EXEC(@sql)


	set @process = 'ALTER PROCEDURE [dbo].[ccspADM_AniListLD] --------'
	set @sql='ALTER PROCEDURE [dbo].[ccspADM_AniListLD]
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
			when 11 then ''zonaGeografica as estado, indicativoDestino as area ''
			when 12 then ''zonaGeografica as estado, indicativoDestino as area ''
			when 13 then ''zonaGeografica as estado, indicativoDestino as area ''
			when 14 then ''provincia as estado, indicativoProvincia as area ''
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
			when 11 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 12 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 13 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 14 then ''provincia as estado, indicativoProvincia as area, @id_anilist as id_anilist, '''''''' as telani ''
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
			when 11 then ''SeriesGT''
			when 12 then ''SeriesCR''
			when 13 then ''SeriesSV''
			when 14 then ''SeriesEsp''
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
		EXEC(@sql)


	set @process = 'ALTER function [dbo].[TelAni]--------------------'
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

	return @ret
END'
	EXEC(@sql)


----------------------------------------------TERMINA PLAN DE SPAIN----------------------------------------------

----------------------------------------------EMAIL----------------------------------------------
	set @process = 'insert menu --'
	set @Sql='if not exists(select * from ccMenus where menu_id in (81,84) and type=1)  begin
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF)  values(81,''Asignar correos de salida|Assign outgoing mail'',16,''B'',40,1,''924581cafd9fbd8aa9e5f65402fecc43d786c100156e029dce2b4bc741a1338d666f9f62a3f3b3538e380e6c99a71472'')
insert ccMenus (menu_id,menu_descrip,parent,nivel,ordengral,type,HelpSWF) values (84,''Firmas de Email|Email Signatures'',16,''B'',40,1,''8cccc72416a9c78390ff5ed75e5e5e388c955e756a866917522acbdeb47bbe148028ce0d26d4fac3b30c123a67438c3c'')
end'
		EXEC(@Sql)

	set @process='insert menus -- Mail Reports'
	set @sql = 'if not exists(select * from ccMenus where menu_id =10000 and type=3)  begin
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release) values(10000,''Email|Email'',10000,''A'',10,3,'''',''6b82b3ec881a02c800504125e9300790'')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release) values(10010,''Email por ACD|Email ACD'',10000,''B'',10,3,'''',''4a8acb1d10e7bcbee1eaefeb9c389e900e4b6513040a9fb773007d474088fe29'')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release) values(10020,''Email por Agente|Agent Email'',10000,''B'',10,3,'''',''4119466bca1752938d8fe6c4c80bc74efa1008ff28a24b75fb9a7aeeedf7c8c6'')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release) values(10030,''Detalle Email|Email Detail'',10000,''B'',10,3,'''',''308b2fa967d3b9f4adfe39b5504883e0057356f8de744acbafe4e106d1d5e2b7'')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release) values(10040,''General Email|Email General'',10000,''B'',10,3,'''',''6552ec30842b5124f941e57c06c04a244ee2c1f6f36d179e6ca4fa9369f3151b'')	
end'
	EXEC(@sql)

	set @process = 'insert into ccFinderServices --'
	set @Sql= 'if not exists(select * from ccFinderServices where name=''Mail'') insert into ccFinderServices values (''Mail'', ''R03'')'
	EXEC(@Sql)


	set @process = 'Alter Table -- Column serviceId'
	set @Sql='if not exists (select * from sys.columns where name = N''serviceId'' and Object_ID = Object_ID(N''ccRIAChatPredefinedMsg''))
begin
	alter table ccRIAChatPredefinedMsg add serviceId smallint null
end'
	EXEC(@Sql)

	set @process = 'Alter Table -- Column serviceId'
	set @Sql='if not exists (select * from sys.columns where name = N''serviceId'' and Object_ID = Object_ID(N''ccRIAChatInboundPredefinedMsg''))
begin
	alter table ccRIAChatInboundPredefinedMsg add serviceId smallint null
end'
	EXEC(@Sql)

	set @process = 'update ccRIAChatPredefinedMsg serviceId'
	set @Sql='update ccRIAChatPredefinedMsg set serviceId = 1
	update ccRIAChatInboundPredefinedMsg set serviceId = 1'
	EXEC(@Sql)


	set @process = 'CREATE TABLE [dbo].[RiaMarkHold]'
	set @Sql='if not exists (select * from sys.tables where name = N''RiaMarkHold'')
		CREATE TABLE [dbo].[RiaMarkHold](
		[marca] [int] NOT NULL,
		[tipo_marca] [int] NOT NULL,
		[tipo_llamada] [int] NOT NULL,
		[call_id] [int] NULL
		) ON [PRIMARY]'
	EXEC(@Sql)

	set @process = 'CREATE NONCLUSTERED INDEX [IX_RiaMarkHold_1] ON [dbo].[RiaMarkHold] ------'
	set @Sql='if not exists (select * from sys.indexes where name = N''IX_RiaMarkHold_1'' and object_id = OBJECT_ID(N''RiaMarkHold''))
	begin
			CREATE NONCLUSTERED INDEX [IX_RiaMarkHold_1] ON [dbo].[RiaMarkHold]
			(
				[tipo_llamada] ASC,
				[call_id] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	end'
	EXEC(@Sql)

	set @process = 'Crear la tabla ccEmailNode --'
	set @Sql= 'if not exists (select * from sys.tables where name = N''ccEmailNode'') begin
	CREATE TABLE [dbo].[ccEmailNode](
	[emailId] [int] NOT NULL,
	[node] [xml] NOT NULL,
	[dateIn] [datetime] NOT NULL,
	[dateOut] [datetime] NULL ,
	[status] [int] NOT NULL DEFAULT ((0)),
	PRIMARY KEY CLUSTERED
	(
	[emailId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

end'
		EXEC(@Sql)


	set @process = 'CREATE ccRIAMultimediaAddress-------  '
	set @Sql = 'if not exists (select * from sys.tables where name = N''ccRIAMultimediaAddress'')
begin
CREATE TABLE [dbo].[ccRIAMultimediaAddress](
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

	set @process = 'CREATE ccRIAMultimediaAddressRel-------  '
	set @Sql = 'if not exists (select * from sys.tables where name = N''ccRIAMultimediaAddressRel'')
begin
CREATE TABLE [dbo].[ccRIAMultimediaAddressRel](
	[address_id] [smallint] NOT NULL,
	[campAcd_id] [smallint] NOT NULL
) ON [PRIMARY]
end'
	EXEC(@sql)


	set @process = 'ccRIAMultimediaSignatureRel - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''ccRIAMultimediaSignatureRel'') begin
CREATE TABLE [dbo].[ccRIAMultimediaSignatureRel](
	[signature_id] [smallint] NOT NULL,
	[campAcd_id] [smallint] NOT NULL
) ON [PRIMARY]
end'
	EXEC(@Sql)

	set @process = 'ccRIAMultimediaSignatures - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''ccRIAMultimediaSignatures'') begin
CREATE TABLE [dbo].[ccRIAMultimediaSignatures](
	[signature_id] [smallint] NOT NULL,
	[Description] [varchar](40) NOT NULL,
	[htmlText] [varchar](max) NOT NULL,
	[Status] [bit] NOT NULL CONSTRAINT [DF_ccRIAMultimediaSignatures_Status]  DEFAULT ((1)),
 CONSTRAINT [PK_ccRIAMultimediaSignatures] PRIMARY KEY CLUSTERED
(
	[signature_id] ASC
) ON [PRIMARY]
) ON [PRIMARY]
end'
	EXEC(@Sql)

		set @process = 'meanContactType - Create Table'
		set @Sql='if not exists (select * from sys.tables where name = N''meanContactType'') begin
	create table meanContactType(
meanContactTypeId [smallint] identity NOT NULL,
name [varchar](30) NOT NULL UNIQUE,
isActive [bit] NOT NULL
)
end'
	EXEC(@Sql)

		set @process = 'contactMeanOut - Create Table'
		set @Sql='if not exists (select * from sys.tables where name = N''contactMeanOut'') begin
create table contactMeanOut(
	contactMeanOutId [smallint] identity NOT NULL,
	meanContactTypeId [smallint] NOT NULL,
	name [varchar](30) NOT NULL,
	conexionInfo [varchar](255) NOT NULL,
	connUser [varchar](60) unique NOT NULL,
	ConnPass [varchar](30)NOT NULL,
	isActive [bit] NOT NULL
)
end'
	EXEC(@Sql)


	set @process = 'relationContactMeanOutInbound - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''relationContactMeanOutInbound'') 	begin
create table [relationContactMeanOutInbound](
	contactMeanOutId [smallint] NOT NULL,
	inboundId [smallint] NOT NULL
)
end'
	EXEC(@Sql)

	set @process = 'contactMeanIn - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''contactMeanIn'') 	begin
create table contactMeanIn(
	meanContactTypeId [smallint] NOT NULL,
	name [varchar](30)  NULL,
	conexionInfo [varchar](400) NULL,
	inboundId [int] NOT NULL,
	connUser [varchar] (60) unique NULL,
	ConnPass [varchar] (300) NULL,
	numMessages [tinyint] NULL,
	timeAlertMessage [tinyint] NULL,
	answerTimeOut [tinyint] NULL,
	isActive [bit] NOT NULL DEFAULT(0)
)
end'
	EXEC(@Sql)

	set @process = 'blackListContact - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''blackListContact'')	begin
create table blackListContact(
	blackListId [int] identity NOT NULL,
	meanContactTypeId [smallint] NOT NULL,
	name [varchar](30) NOT NULL UNIQUE,
	isActive [bit] NOT NULL
)
end'
	EXEC(@Sql)

	set @process = 'blackListContactInbound - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''blackListContactInbound'') begin
create table blackListContactInbound(
	inboundId [smallint] identity NOT NULL,
	blackListId [int] NOT NULL
)
end'
	EXEC(@Sql)

	set @process = 'blackListContactClientMail - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''blackListContactClientMail'') 	begin
create table blackListContactClientMail(
	blackListId[int] NOT NULL,
	clientContactMailId [int] NOT NULL
)
end'
	EXEC(@Sql)

	set @process = 'conversation - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''conversation'') begin
create table [conversation](
	conversationId [int] identity NOT NULL,
	inboundId [smallint] NOT NULL,
	info [varchar](255) NULL,
	isInbox [bit] NOT NULL,
	isFinished [bit] NOT NULL,
	mailClient [varchar] (60) NOT NULL,
	mailInbound [varchar](60) NULL,
	meanContactTypeId [smallint] NOT NULL
)
end'

	EXEC(@Sql)

	set @process = 'message - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''message'') begin
create table [message](
	messageId [int] identity NOT NULL,
	conversationId [int] NOT NULL,
	messageStatusId [int] NOT NULL,
	userId [smallint] NOT NULL,
	[date] [datetime] NOT NULL,
	tQueue [datetime] NULL,
	tWait [int] NOT NULL DEFAULT(0),
	tRetention [int] NOT NULL DEFAULT(0),
	tResponse [int] NOT NULL DEFAULT(0),
	tWrapUp [tinyint] NOT NULL DEFAULT(0),
	tSend [datetime] NULL,
	isSender bit NOT NULL DEFAULT(0)
)
end'

	EXEC(@Sql)

	set @process = 'clientContactMail - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''clientContactMail'') 	begin
create table clientContactMail(
	clientContactMailId [int] identity NOT NULL,
	name [varchar](60) NOT NULL
)
end'
	EXEC(@Sql)


	set @process = 'messageStatus - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''messageStatus'') 	begin
create table messageStatus(
	messageStatusId [int] identity NOT NULL,
	name [varchar](30) NOT NULL,
	description [varchar](100) NOT NULL,
	isFinished [bit] NOT NULL
)
end'

	EXEC(@Sql)

	set @process = 'attached - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''attached'') begin
create table attached(
	attachedId [int] identity NOT NULL,
	messageId [int] NOT NULL,
	pathFile [varchar](255) NOT NULL,
	isUser [bit] NOT NULL
)
end'
	EXEC(@Sql)

		set @process = 'relationMessageDisposition - Create Table'
		set @Sql='if not exists (select * from sys.tables where name = N''relationMessageDisposition'') begin
	create table [relationMessageDisposition](
messageId [int] NOT NULL,
dispositionId [int] NOT NULL,
subDispositionId [int] NOT NULL
)
end'
	EXEC(@Sql)

	set @process = 'messageMail - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''messageMail'') begin
	create table messageMail(
[messageId] [int] NOT NULL,
[uid] [varchar](100) NOT NULL)
end'
	EXEC(@Sql)

	set @process = 'messageUnAssigned - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''messageUnAssigned'') 	begin
	Create table messageUnAssigned(
		[messageId] [int] NOT NULL,
		userId [int] NOT NULL,
		time [int] NOT NULL DEFAULT(0),
		isLogout [bit] NOT NULL DEFAULT(0)
	)
end'
	EXEC(@Sql)


	set @process = 'Primary Keys - Add'
	set @Sql='if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''meanContactType'')
ALTER TABLE meanContactType ADD PRIMARY KEY (meanContactTypeId)
if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''contactMeanOut'')
	ALTER TABLE contactMeanOut ADD PRIMARY KEY (contactMeanOutId)
if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''clientContactMail'')
	ALTER TABLE clientContactMail ADD PRIMARY KEY (clientContactMailId)
if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''messageStatus'')
	ALTER TABLE messageStatus ADD PRIMARY KEY (messageStatusId)
if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''conversation'')
	ALTER TABLE [conversation] ADD PRIMARY KEY (conversationId)
if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''message'')
	ALTER TABLE [message] ADD PRIMARY KEY (messageId)
if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''attached'')
	ALTER TABLE attached ADD PRIMARY KEY (attachedId)
if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''blackListContact'')
	ALTER TABLE blackListContact ADD PRIMARY KEY (blackListId)
if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''messageMail'')
	ALTER TABLE [messageMail] ADD PRIMARY KEY ([messageId],[uid])'
	EXEC(@Sql)

		set @process = 'Foreign Keys - Add'
		set @Sql='if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''contactMeanOut'' and  c1.[name]=''meanContactTypeId'')
		ALTER TABLE contactMeanOut ADD FOREIGN KEY (meanContactTypeId) REFERENCES meanContactType (meanContactTypeId)
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''contactMeanIn'' and  c1.[name]=''meanContactTypeId'')
	ALTER TABLE contactMeanIn ADD FOREIGN KEY (meanContactTypeId) REFERENCES meanContactType (meanContactTypeId)
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''conversation'' and  c1.[name]=''inboundId'')
	ALTER TABLE [conversation] ADD FOREIGN KEY (inboundId) REFERENCES ccinbound (Inbound_id)
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''conversation'' and  c1.[name]=''meanContactTypeId'')
	ALTER TABLE [conversation] ADD FOREIGN KEY (meanContactTypeId) REFERENCES meanContactType (meanContactTypeId)
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''message'' and  c1.[name]=''conversationId'')
	ALTER TABLE [message] ADD FOREIGN KEY (conversationId) REFERENCES [conversation] (conversationId)
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''message'' and  c1.[name]=''messageStatusId'')
	ALTER TABLE [message] ADD FOREIGN KEY (messageStatusId) REFERENCES messageStatus (messageStatusId)
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''attached'' and  c1.[name]=''messageId'')
	ALTER TABLE attached ADD FOREIGN KEY (messageId) REFERENCES [message] (messageId)
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''blackListContactClientMail'' and  c1.[name]=''blackListId'')
	ALTER TABLE blackListContactClientMail ADD FOREIGN KEY (blackListId) REFERENCES blackListContact (blackListId)
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''blackListContactClientMail'' and  c1.[name]=''clientContactMailId'')
	ALTER TABLE blackListContactClientMail ADD FOREIGN KEY (clientContactMailId) REFERENCES clientContactMail (clientContactMailId)
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''relationMessageDisposition'' and  c1.[name]=''messageId'')
	ALTER TABLE [relationMessageDisposition] ADD FOREIGN KEY ([messageId]) REFERENCES [message] (messageId)
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''relationContactMeanOutInbound'' and  c1.[name]=''contactMeanOutId'')
	ALTER TABLE [relationContactMeanOutInbound] ADD FOREIGN KEY (contactMeanOutId) REFERENCES contactMeanOut (contactMeanOutId)
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''relationContactMeanOutInbound'' and  c1.[name]=''inboundId'')
	ALTER TABLE [relationContactMeanOutInbound] ADD FOREIGN KEY (inboundId) REFERENCES ccInbound (Inbound_id)'
	EXEC(@Sql)

	set @process='Status Messages - Insert'
	set @Sql='if not exists (select * from messageStatus where name=''Download'') begin
	insert into messageStatus(name,description,isFinished) values(''Download'',''Download emails from server'',0)
insert into messageStatus(name,description,isFinished) values(''Assigned'',''Assign message to agent'',0)
insert into messageStatus(name,description,isFinished) values(''Read'',''Read the message agent'',0)
insert into messageStatus(name,description,isFinished) values(''Unassigned'',''Unassign message to agent'',0)
insert into messageStatus(name,description,isFinished) values(''Answered'',''Message answered by agent'',0)
insert into messageStatus(name,description,isFinished) values(''Send'',''Message sent to the client'',0)
insert into messageStatus(name,description,isFinished) values(''Rejected'',''Message rejected for server'',0)
insert into messageStatus(name,description,isFinished) values(''Programar Forwarding'',''Sending the message is rescheduled'',0)
insert into messageStatus(name,description,isFinished) values(''Forwarding'',''It forwards the message'',0)
insert into messageStatus(name,description,isFinished) values(''Close conversation system'',''conversation closed  for system'',0)
insert into messageStatus(name,description,isFinished) values(''Close conversation agent'',''Close conversation for agent'',0)
	end'
	EXEC(@Sql)

	set @process = 'meanContactType - Insert'
	set @Sql='if not exists (select * from meanContactType where name=''EMail'')
	insert into meanContactType(name,isActive) values(''EMail'',1)'
	EXEC(@Sql)

	set @process = 'Create index IX_conversation_inbound --  conversation'
	set @Sql='if not exists (select * from sys.indexes where name = N''IX_conversation_inbound'' and object_id = OBJECT_ID(N''conversation''))	begin
	CREATE NONCLUSTERED INDEX [IX_conversation_inbound] ON [dbo].[conversation]
(
	[inboundId] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end'
	EXEC(@Sql)

	set @process = 'ccsp_MailAdminAccount - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccsp_MailAdminAccount'') DROP PROCEDURE ccsp_MailAdminAccount'
	EXEC(@Sql)

	set @process = 'ccsp_MailSave - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccsp_MailSave'') DROP PROCEDURE ccsp_MailSave'
	EXEC(@Sql)

	set @process = 'ccsp_Multimedia - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccsp_Multimedia'') DROP PROCEDURE ccsp_Multimedia'
	EXEC(@Sql)
	

	set @process = 'ccsp_Skills - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccsp_Skills'') DROP PROCEDURE ccsp_Skills'
	EXEC(@Sql)

	set @process = 'ccsp_MailInitialStatistics - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccsp_MailInitialStatistics'') DROP PROCEDURE ccsp_MailInitialStatistics'
	EXEC(@Sql)

	set @process = 'ccspRepSpececialAbndPercentage -- Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''ccsp_RIAGetEnabledServices'') DROP PROCEDURE ccsp_RIAGetEnabledServices'
	EXEC(@sql)

	set @process = 'ccsp_RIAMultimediaSignature -- Drop  if exists'
	set @sql='if exists (select * from sys.procedures where name = N''ccsp_RIAMultimediaSignature'') DROP PROCEDURE ccsp_RIAMultimediaSignature'
	EXEC(@sql)

	set @process = 'ccsp_RIAMultimediaAddresses -- Drop  if exists'
	set @sql='if exists (select * from sys.procedures where name = N''ccsp_RIAMultimediaAddresses'') DROP PROCEDURE ccsp_RIAMultimediaAddresses'
	EXEC(@sql)

	set @process = 'ccsp_CreateNodeMail - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccsp_CreateNodeMail'') DROP PROCEDURE ccsp_CreateNodeMail'
	EXEC(@Sql)

	set @process = 'ccsp_RIAtmpChart - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccsp_RIAtmpChart'') DROP PROCEDURE ccsp_RIAtmpChart'
	EXEC(@Sql)

	set @process = '[ccsp_Callbacks] - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccsp_Callbacks'') DROP PROCEDURE ccsp_Callbacks'
	EXEC(@Sql)  


	set @process = ' - Drop if exists [ccsp_RIAMarkHold]'
	set @Sql='if exists (select * from sys.procedures where name = N''ccsp_RIAMarkHold'') DROP PROCEDURE ccsp_RIAMarkHold'
	EXEC(@Sql)	

	set @process = 'CREATE PROCEDURE [dbo].[ccsp_Callbacks] ------'
	set @Sql='CREATE PROCEDURE [dbo].[ccsp_Callbacks]
@cam_id as int
AS
select año,mes,dia,hora, callbacks from ccRIACallbacks where cam_id=@cam_id order by año,mes,dia,hora'
	EXEC(@Sql)
	
	set @process = 'ALTER procedure [dbo].[ccsp_RIALoadAgents] ------'
	set @Sql='ALTER procedure [dbo].[ccsp_RIALoadAgents]
@option smallint,
@AreaId smallint,
@Sup smallint,
@UserType smallint,
@IDWG smallint = null,
@IDCampACD varchar(max) = null
AS
set nocount on
declare @IDArea int
if @option in(1,7) --1:Todos los agentes/supervisores | 7:UN solo agente/supervisor
 begin
	SELECT User_id, Login, TipoLlamadas, Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea,0) IDArea, Sexo
	From ccUsers with(readpast)
	Where TipoUser_id&2 = case @UserType when 1 then 0 else 2 end And Status > 0 and user_id = case @option when 7 then isnull(@sup,user_id) else user_id end
	ORDER by IDArea, Nombres, ApellidoPaterno, User_id
	return(0)
 end

if @option=2 --Agentes/supervisores de un Area
 begin
	SELECT User_id, Login, TipoLlamadas, Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea,0) IDArea, Sexo
	from ccusers
	Where isnull(IDArea,0) = isnull(@AreaId,0) And TipoUser_id&2 = case @UserType when 1 then 0 else 2 end
	 And status = 1 -- case isnull(@AreaId,0) when 0 then 0 else 1 end
	 ORDER by Sexo, Nombres, ApellidoPaterno, User_id
	return(0)
 end

if @option=3 --Agentes por Supervisor
 begin
	select a3.user_id, a3.Login, a3.TipoLlamadas, a3.Nombres + isnull('' ''+ a3.ApellidoPaterno,'''') + isnull('' '' + a3.ApellidoMaterno, '''') name,
	 isnull(a3.IDArea,0) IDArea, a3.Sexo
	from ccsupervisorcam a1 join cccampsagente a2 on a1.cam_id=a2.cam_id join ccusers a3 on a2.user_id=a3.user_id
	where a1.tipo=''1'' and a1.user_id=@Sup and a3.TipoUser_id = 1 and a3.status>0
	union
	select a3.user_id, a3.Login, a3.TipoLlamadas, a3.Nombres + isnull('' ''+ a3.ApellidoPaterno,'''') + isnull('' '' + a3.ApellidoMaterno, '''') name,
	 isnull(a3.IDArea,0) IDArea, a3.Sexo
	from ccsupervisorcam a1 join ccInboundagentes a2 on a1.cam_id=a2.Inbound_id join ccusers a3 on a2.user_id=a3.user_id
	where a1.tipo=''0'' and a1.user_id=@Sup and a3.TipoUser_id = 1 and a3.status>0
	Order by 5,4,1
	return(0)
 end

If @option=4 --Load All Supervisors
 begin
	SELECT User_id, Login, Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name
	from ccUsers where TipoUser_id in(2,6) and Status>0
	return(0)
 end

if @option=5 --Agentes por Supervisor de sus WG
 begin
	select @IDArea = IDArea from ccUsers where User_id=@Sup
	select a1.user_id, a1.Login, a1.TipoLlamadas, min(a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''')) name
		,isnull(a1.IDArea,0) IDArea, Sexo,isnull(IP, ''0.0.0.0'') IP,max(case when isnull(a5.chat,0) < 3 then 0 else 1 end) hasMail
	 from ccUsers a1 
	 inner join ccRIAWorkGroupUsers a2 on a1.user_id=a2.user_id 
	 left join ccPosicion a3 on a1.user_id=a3.user_id
	 inner join ccRIACampEspWG a4 on a2.idwg = a4.idwg
	 left join  ccInbound a5 on a4.IdCampEsp=a5.Inbound_id and a5.IDArea=@IDArea
	 where a1.tipouser_id=1 and a2.IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id=@Sup)
	 group by a1.user_id,Login,TipoLlamadas,a1.IDArea,Sexo,IP
	return(0)
 end

if @option=6 --Agentes por Supervisor de sus WG
 begin
	select distinct a1.user_id, a1.Login, a1.TipoLlamadas, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	from ccusers a1 join ccRIAWorkGroupUsers a2 on a1.user_id=a2.user_id
	where tipouser_id in(2,6) and IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id=@Sup)
	return(0)
 end

If @option in(8,9) --8:Agentes de un WG | 9:Supervisores de un WG
 begin
	declare @wgUsers as varchar(500)
	select @wgUsers = coalesce(@wgUsers + '','', '''') + CAST(A.user_id as varchar(40))
	FROM ccRIAWorkGroupUsers A join ccUsers B on A.user_id = B.user_id where IDWG=@IDWG 
	 -- and TipoUser_id&2 = case @option when 8 then 0 else 2 end -- Si se quiere tomar en cuenta tipo 2 y 6 como admin en vez de solo tipo 2
	 and TipoUser_id = case @option when 8 then 1 else 2 end 
	select @wgUsers wgUsers
	return(0)
 end

if @option=10 --Todos los agentes/supervisores
 begin
	SELECT User_id, Login, Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea,0) IDArea, Sexo 
	From ccUsers with(readpast)
	Where TipoUser_id in(/*2,*/6) And Status > 0
	ORDER by login, IDArea, Nombres, ApellidoPaterno, User_id
	return(0)
 end

if @option=11 -- Agentes por ACD
 begin
	select distinct a1.user_id, a1.Login, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name, a1.Sexo, a2.prioridad
	from ccusers a1	join ccInboundAgentes a2 on a1.user_id=a2.user_id 
	where a1.tipouser_id=1 and a2.Inbound_id in (select value from dbo.fn_RIASplitDelimited(@IDCampACD,'',''))
	return(0)
 end

if @option=12 -- Agentes por Camp
 begin
	select distinct a1.user_id, a1.Login, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name, a1.Sexo, a2.prioridad
	from ccusers a1	join ccCampsAgente a2 on a1.user_id=a2.user_id 
	where a1.tipouser_id=1 and a2.cam_id in (select value from dbo.fn_RIASplitDelimited(@IDCampACD,'',''))
	return(0)
 end

if @option=13 -- Sups por ACD
 begin
	select distinct a1.user_id, a1.Login, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	from ccusers a1	join ccSupervisorCam a2 on a1.user_id = a2.user_id
	where a1.tipouser_id&2=2 and tipo = 0 and a2.cam_id in (select value from dbo.fn_RIASplitDelimited(@IDCampACD,'',''))
	return(0)
 end

if @option=14 -- Sups por Camp
 begin
	select distinct a1.user_id, a1.Login, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	from ccusers a1	join ccSupervisorCam a2 on a1.user_id = a2.user_id
	where a1.tipouser_id&2=2 and tipo = 1 and a2.cam_id in (select value from dbo.fn_RIASplitDelimited(@IDCampACD,'',''))
	return(0)
 end

declare @sxML as varchar(max), @xml as xml, @action as int
 	
if @option=15 -- Info Agentes
 begin
	set @action=@option-9
	set @xml = cast(''<?xml version="1.0"?> <AgentData/>'' as xml)
	
	select @sxML = cast((select * from (select 1 as tag, null as parent, 
	User_id "Agent!1!id", login "Agent!1!login", Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') "Agent!1!name", 
	Sexo "Agent!1!gender", isnull(IDArea,0) "Agent!1!areaID"
	From ccUsers with(readpast) Where TipoUser_id=1 And Status>0 and user_id=@sup 
	) as x order by tag, "Agent!1!areaID", "Agent!1!name", "Agent!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<AgentData/>'')

	set @xml.modify(''insert element Workgroups {""} as last into (/AgentData/Agent)[1]'')
	select @sxML = cast((select * from (select 1 as tag, null as parent, 
	W.IDWG "Workgroup!1!id", W.WGName "Workgroup!1!description"
	from ccRIACat_WorkGroup W join ccRIAWorkGroupUsers U on W.IDWG = U.IDWG 
	where user_id = @sup
	) as x order by tag, "Workgroup!1!description" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<Workgroups/>'')

	set @xml.modify(''insert element Campaigns {""} as last into (/AgentData/Agent)[1]'')
	select @sxML = cast((select * from (select distinct 1 as tag, null as parent, 
	a1.cam_id "Campaign!1!id", a1.cam_descripcion "Campaign!1!description", a3.frame "Campaign!1!frame", a1.cam_procesando "Campaign!1!processing"
	from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccCampsAgente a4 on a1.cam_id = a4.cam_id
	where a3.type_id = 1 and a4.user_id = @Sup 
	) as x order by tag, "Campaign!1!processing", "Campaign!1!description", "Campaign!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<Campaigns/>'')

	set @xml.modify(''insert element ACDs {""} as last into (/AgentData/Agent)[1]'')
	select @sxML = cast((select * from (select distinct 1 as tag, null as parent, 
	a1.inbound_id "ACD!1!id", descripcion "ACD!1!description", frame "ACD!1!frame"
	from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccInboundAgentes a4 on a1.Inbound_id = a4.Inbound_id
	where a3.type_id = 1 and a4.user_id = @Sup
	) as x order by tag, "ACD!1!description", "ACD!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<ACDs/>'')
	
	set @xml.modify(''insert element action {""} as last into (/AgentData)[1]'')
	set @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/AgentData/action)[1]'')
	select @xML
	return(0)
 end

if @option=16 -- Info Sups
 begin
 
 	set @action=@option-9
	set @xml = cast(''<?xml version="1.0"?> <SuperData/>'' as xml)
	
	select @sxML = cast((select * from (select 1 as tag, null as parent, 
	User_id "Super!1!id", login "Super!1!login", Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') "Super!1!name", 
	Sexo "Super!1!gender", isnull(IDArea,0) "Super!1!areaID"
	From ccUsers with(readpast) Where TipoUser_id&2=2 And Status>0 and user_id=@sup 
	) as x order by tag, "Super!1!areaID", "Super!1!name", "Super!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<SuperData/>'')

	set @xml.modify(''insert element Workgroups {""} as last into (/SuperData/Super)[1]'')
	select @sxML = cast((select * from (select 1 as tag, null as parent, 
	W.IDWG "Workgroup!1!id", W.WGName "Workgroup!1!description"
	from ccRIACat_WorkGroup W join ccRIAWorkGroupUsers U on W.IDWG = U.IDWG 
	where user_id = @sup
	) as x order by tag, "Workgroup!1!description" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<Workgroups/>'')

	set @xml.modify(''insert element Campaigns {""} as last into (/SuperData/Super)[1]'')
	select @sxML = cast((select * from (select distinct 1 as tag, null as parent, 
	a1.cam_id "Campaign!1!id", a1.cam_descripcion "Campaign!1!description", a3.frame "Campaign!1!frame", a1.cam_procesando "Campaign!1!processing"
	from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccSupervisorCam a4 on a1.cam_id = a4.cam_id
	where a3.type_id=1 and a4.user_id = @Sup and a4.tipo=1
	) as x order by tag, "Campaign!1!processing", "Campaign!1!description", "Campaign!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<Campaigns/>'')

	set @xml.modify(''insert element ACDs {""} as last into (/SuperData/Super)[1]'')
	select @sxML = cast((select * from (select distinct 1 as tag, null as parent, 
	a1.inbound_id "ACD!1!id", descripcion "ACD!1!description", frame "ACD!1!frame"
	from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccSupervisorCam a4 on a1.inbound_id = a4.cam_id
	where a3.type_id=1 and a4.user_id = @Sup and a4.tipo=0
	) as x order by tag, "ACD!1!description", "ACD!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<ACDs/>'')
	
	set @xml.modify(''insert element action {""} as last into (/SuperData)[1]'')
	set @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/SuperData/action)[1]'')
	select @xML
	return(0)
 end

if @option=17 -- Load all agents
begin
	select distinct user_id, Login, TipoLlamadas, 
		Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name,
		isnull(IDArea,0) IDArea, Sexo, ''0.0.0.0'' IP, 0 as flagMine
	into #allAgents 
	from ccusers 
	where tipouser_id = 1

	select distinct a1.user_id, a1.Login, a1.TipoLlamadas, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name,
	 isnull(a1.IDArea,0) IDArea, Sexo, isnull(IP, ''0.0.0.0'') IP
	into #myAgents
	from ccusers a1	join ccRIAWorkGroupUsers a2 on a1.user_id=a2.user_id left join ccPosicion a3 on a1.user_id=a3.user_id
	join ccRIACampEspWG a4 on a2.idwg = a4.idwg
	where a1.tipouser_id=1 and a2.IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id=@Sup)

	update #allAgents
	set flagMine = 1
	from #allAgents a, #myAgents b
	where a.user_id = b.user_id

	select *
	from #allAgents
	
	drop table #allAgents
	drop table #myAgents

	return(0)
end

if @option = 18 -- View Agents
begin
	select isnull(viewAgents,0) as viewAgents
	from ccusers 
	where tipouser_id = 2
	and user_id = @Sup
	return(0)
end

set nocount off'
	EXEC(@Sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents] ------'
	set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
@option smallint,
@UserId int,
@Login varchar(12)='''',
@Nombres varchar(25)=null,
@ApellidoPaterno varchar(25)='''',
@ApellidoMaterno varchar(25)='''',
@Password varchar(33)='''',
@Sexo bit=null,
@canChangeStatus bit=null,
@AreaId int=null,
@UserType tinyint=1,
@IDWG int=0,
@DeleteUsers int=1,
@inOut int=null,
@IDCampEsp int=null,
@multipleUsers varchar(1000)=null
as
set nocount on

if @option=0--All Users
	begin
	select User_id,Login,ISnull(AREas.AreaName,'''')as AreaName
						
from ccusers as users with(nolock)
		left join ccRIACat_Areas as areas with(nolock)
		on users.IDArea=areas.IDArea
	return(0)
	end

if @option=1--selected User
	begin
	select User_id,Login,Nombres,isnull(apellidoPaterno,''''),
		isnull(ApellidoMaterno,''''),Sexo,canChangeStatus,isnull(IDArea,0),tipouser_id
	from ccusers where User_id=@UserId 
	order by IDArea,Nombres,ApellidoPaterno,User_id
	return(0)
	end

if @option=2--insert
	begin
	if exists(select Login from ccUsers where Login=@Login)
		begin
		select -1--,''Login en Uso''
		return(0)
		end

	if exists(select Login from ccUsers_Consulta where Login = @Login)
	begin
		select -4 -- ''Login habia estado en Uso''
		return(0)
	end

	if exists(select Nombres from ccUsers where Nombres=@Nombres 
	and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
		begin
		select -2--,''Nombre en Uso''
		return(0)
		end

IF( select isnull(max(user_id),0) from ccusers) > 32700
BEGIN
	set @UserId = null
	SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID 
	FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
	LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
	INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
	FROM ccusers) AS w ON w.recID = d.recID

	if @UserId is null
	begin
		select -2--insert Error
		return(0)
	end
						
	set identity_insert ccusers on
	insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
		Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
	select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
		1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
	set identity_insert ccusers off
							
	delete ccMenuUser where id_User = @UserId
	delete ccRIAUserRole where user_id = @UserId
						
	exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId	
						
END
ELSE
BEGIN
	insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
		Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
	select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
		1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

	if @@rowcount=1
		select @UserId=scope_identity()
	else
		begin
		select -2--insert Error
		return(0)
		end
END
	insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
	insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
	insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
	--Menu para roles RepotsRia
	exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId
						
	select @UserId,''Usuario '' + @Login + '' Dado de Alta''
	return(0)
	end

if @option=3--Update
	begin
	if @Login='''' and @Password <> ''''
		begin
		Update ccUsers set Password=@Password where User_id=@UserId
		return(0)
		end
					     
	Update ccUsers 
	set Login= case when @Login <> '''' then @Login else Login end,
	Nombres=@Nombres,
	ApellidoPaterno=@ApellidoPaterno,ApellidoMaterno=@ApellidoMaterno,
	Password=case when @Password <> '''' then @Password else Password end,
	Sexo=@Sexo,canChangeStatus=@canChangeStatus where User_id=@UserId
	return(0)
	end

if @option=4--Delete
	begin
	delete from ccSkills
	delete from ccMenu_ViewsUser where user_id =@UserId
	delete from dbo.ccRIAWorkGroupUsers where user_id =@UserId
	delete from ccUsers where user_id=@UserId
	return(0)
	end

declare @Type tinyint, @users int,@sql varchar(8000), @NinOut nvarchar(10)

if @option=5--insert Agente-Supervisor in WorkGroup
	begin
	select @Type=TipoUser_id from ccUsers where User_id=@UserId

	if @Type not in(1,2,6)
		return(0)
					    
	if @Type=1 and((select count(User_id)from ccRIAWorkGroupUsers where User_id=@UserId)>=(select valor from ccSettings where setting_id=63))
		begin
		select 3
		return(0)
		end

	if exists(select @UserId from ccRIAWorkGroupUsers where User_id=@UserId and IDWG=@IDWG)
		begin
		select 1
		return(0)
		end     

	insert into ccRIAWorkGroupUsers(IDWG,User_id)values(@IDWG,@UserId)    
					    
	if @Type=1 
		begin
						 
		if @IDWG is null or @IDWG = 0
			begin
			select 28
			return(0)
			end
		insert into cccampsAgente(user_id,cam_id,prioridad,skill,IDWG)

		select @UserId,idCampEsp,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
		from ccRIACampEspWG where tipo=1 and IDWG=@IDWG 
			and idCampEsp not in(select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

		insert into ccinboundAgentes(User_id,Inbound_id,cli_id,prioridad,skill,IDWG)
		select @UserId,idCampEsp,0,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
		from ccRIACampEspWG where tipo=0 and IDWG=@IDWG 
			and idCampEsp not in(select inbound_id from ccinboundAgentes where user_id=@UserId and IDWG=@IDWG)

		return(0)
		end

--else @Type=2 or @Type=6--Supervisor
	insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
	select @UserId,idCampEsp,0,@IDWG
	from ccRIACampEspWG where tipo=0 and IDWG=@IDWG 
		and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

	insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
	select @UserId,idCampEsp,1,@IDWG
	from ccRIACampEspWG where tipo=1 and IDWG=@IDWG 
		and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
	return(0)
	end

if @option=6--Delete Agent-Supervisor from WorkGroup
	begin
	if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)=0
		select @UserId = @multipleUsers

	else if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)>0
		select @UserId = cast(substring(@multipleUsers, 1, 
		CHARINDEX('','', @multipleUsers)-1) as int)

		select @Type=case when @UserType <> 0 then @UserType else TipoUser_id end,
		@multipleUsers=isnull(@multipleUsers,cast(@Userid as varchar(10)))
	from ccUsers where User_id=@UserId

	Declare @sqlDelete nvarchar(4000)
	if @Type in(1,2,6)--1:Agente / 2,6:Supervisor
		begin
		set @sqlDelete=N''Delete from '' + case @Type when 1 then ''cccampsagente where '' else ''ccSupervisorCam where tipo=0 and '' end 
		+ ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))		
		+ '' Delete from '' + case @Type when 1 then ''ccinboundagentes where '' else ''ccSupervisorCam where tipo=1 and '' end 
		+ ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
		exec(@sqlDelete)
		end

	if isnull(@UserId, 0) = 0 or isnull(@multipleUsers, ''0'') = ''0''
		begin
		select -9 -- Se ingreso mal el id del usuario
		--delete ccinboundagentes where idwg=@IDWG
		--delete cccampsagente where idwg=@IDWG
		--delete ccSupervisorCam where idwg=@IDWG
		end

	if @DeleteUsers=1
		Delete ccRIAWorkGroupUsers where IDWG=@IDWG and User_id=@UserId

	return(0)
	end

if @option=7--Delete Agent from WorkGroup
	begin
	select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end
	set @sql=''delete '' + case @NinOut when ''1'' then ''ccCampsAgente'' else ''ccInboundAgentes'' end + 
		'' where user_id in('' + isnull(@multipleUsers, ''0'') +'') and '' + case @NinOut when ''1'' then ''cam_id'' else ''inbound_id'' end + 
		''='' + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' + cast(@IDWG as varchar(10)) +
		'' delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10)) 
	exec(@sql)
return(0)
	end

if @option=8--Delete Supervisor from WorkGroup
	begin
	select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end

	set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and user_id in('' + isnull(@multipleUsers, ''0'') + '') and cam_id='' 
		+ cast(@IDCampEsp as varchar(10)) + '' and IDWG='' +cast(@IDWG as varchar(10)) + ''
		delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
	exec(@sql)

	set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and cam_id='' + cast(@IDCampEsp as varchar(10)) + ''and '' + 
		''user_id in ('' + isnull(@multipleUsers, ''0'') + '') and IDWG='' + cast(@IDWG as varchar(10))
	exec(@sql)
	return(0)
	end

if @option=9
	begin
	update ccusers set NotReadyRestricted=@canChangeStatus where [User_id]=@UserId
	return(0)
	end
set nocount off'
	EXEC(@Sql)

	set @process = ' CREATE PROCEDURE [dbo].[ccsp_RIAMarkHold] ------'
	set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAMarkHold]
@call_id int,@callType int,@marca int,@status int
--@status 0|1 hold
--@marca Se pone en segundos
AS
set nocount on
	if not exists(select * from RiaMarkHold where tipo_llamada=@callType and tipo_marca= @status and marca = @marca and call_id=@call_id)
		INSERT INTO RiaMarkHold (marca, tipo_marca, tipo_llamada, call_id) VALUES (@marca,@status,@callType,@call_id)	
set nocount off'
	EXEC(@Sql)




	set @process = 'CREATE procedure [dbo].[ccsp_RIAtmpChart]'
	set @Sql='CREATE procedure [dbo].[ccsp_RIAtmpChart]
@inbound_id smallint = NULL,
@graphicType smallint = NULL
as
SET NOCOUNT ON

declare @DT as int
select @DT = valor from ccsettings where setting_id = 12
Declare @Times Table (
	StartDate datetime not null,
	EndDate datetime not null,
	[timestamp] varchar(5) not null)

Declare @Start DateTime
Declare @End Datetime
Declare @descripcion varchar(50)

declare @DTChat as int
select @DTChat = valor from ccsettings where setting_id = 141

if @graphicType = 1
begin
 declare @Fecha smalldatetime, @FechaW smalldatetime

 select @Fecha=convert(varchar(10), getdate(), 121)

 if exists(select cal_Inicio from cccallsin_tmpChart where cal_inicio < @Fecha)
  truncate table cccallsin_tmpChart

 delete cccallsin_tmpChart where inbound_id = @inbound_id and cal_inicio >= @Fecha
 select @FechaW=@Fecha

 while @FechaW <= convert(varchar(15), getdate(), 121)+''0:00''
  begin
  if exists(Select SL.inbound_id from (select NS.inbound_id, @fechaW cal_inicio, sum(NS.LCt) LCt,  sum(NS.LAt) LAt,  sum(NS.LS) LS,  sum(NS.LA) LA,  sum(NS.LDt) LDt,
	sum(NS.LDc) LDc, sum(NS.LC) LC, sum(NS.LNC) LNC, sum(NS.LP) LP, @DT DyTrh
	from (Select @inbound_id inbound_id, @fechaW cal_inicio,
	 ISNULL(count(CASE WHEN(statuscall_id in(13))and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LCt,
	 ISNULL(count(CASE WHEN(statuscall_id=6)and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LAt,
	 ISNULL(count(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0)AS LS,
	 ISNULL(count(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0)AS LA,
	 ISNULL(count(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0)AS LDt,
	 ISNULL(count(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0)AS LDc,
	 ISNULL(count(CASE WHEN(statuscall_id in(13))THEN 1 ELSE NULL END),0)AS LC,
	 ISNULL(count(CASE WHEN(statuscall_id=15)THEN 1 ELSE NULL END),0)AS LNC,
	 ISNULL(count(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0)AS LP
	from cccallsin where inbound_id=@inbound_id and cal_inicio between @Fecha and @FechaW and statuscall_id IN(4,6,7,8,11,13,15,16)
	group by convert(varchar(15), cal_inicio, 121)+''0:00'') as NS group by NS.inbound_id) as SL)
   begin
   insert into cccallsin_tmpChart (inbound_id, cal_Inicio, LCt, LAt, LS, LA, LDt, LDc, LC, LNC, LP, DT, NS)
   Select SL.* ,case when (LC+LA+LS+LDt+LDc+LNC+LP) = 0 then ''1'' else cast((cast((LCt+LAt) as float)/cast((LC+LA+LS+LDt+LDc+LNC+LP)
	as float))*100 as decimal(18,2))end ServN
   from (select NS.inbound_id, @fechaW cal_inicio, sum(NS.LCt) LCt,  sum(NS.LAt) LAt,  sum(NS.LS) LS,  sum(NS.LA) LA,  sum(NS.LDt) LDt,
	sum(NS.LDc) LDc, sum(NS.LC) LC, sum(NS.LNC) LNC, sum(NS.LP) LP, @DT DyTrh
	from (Select @inbound_id inbound_id, @fechaW cal_inicio,
	 ISNULL(count(CASE WHEN(statuscall_id in(13))and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LCt,
	 ISNULL(count(CASE WHEN(statuscall_id=6)and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LAt,
	 ISNULL(count(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0)AS LS,
	 ISNULL(count(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0)AS LA,
	 ISNULL(count(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0)AS LDt,
	 ISNULL(count(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0)AS LDc,
	 ISNULL(count(CASE WHEN(statuscall_id in(13))THEN 1 ELSE NULL END),0)AS LC,
	 ISNULL(count(CASE WHEN(statuscall_id=15)THEN 1 ELSE NULL END),0)AS LNC,
	 ISNULL(count(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0)AS LP
	from cccallsin where inbound_id=@inbound_id and cal_inicio between @Fecha and @FechaW and statuscall_id IN(4,6,7,8,11,13,15,16)
	group by convert(varchar(15), cal_inicio, 121)+''0:00'') as NS group by NS.inbound_id) as SL
   end

  else
   begin
   insert into cccallsin_tmpChart (inbound_id, cal_Inicio, LCt, LAt, LS, LA, LDt, LDc, LC, LNC, LP, DT, NS)
   Select @inbound_id, @FechaW, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
   end
  select @FechaW=dateadd(minute, 10, @FechaW)
  end

 if not exists(select d.descripcion from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart)) join (select c.inbound_id, i.descripcion, c.NS, convert(varchar(5), max(c.cal_inicio), 108) timestamp
  from cccallsin_tmpChart c join ccinbound i on c.inbound_id = i.inbound_id
  where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id
  group by c.inbound_id, i.descripcion, c.NS) D on c.inbound_id = d.inbound_id
  where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id)
  begin
  raiserror(''without ACD Group information  '', 18, 1)
  return(0)
  end

 select * from
 (select top 20 @inbound_id inbound_id, d.descripcion, d.NS LastNS, convert(varchar(5), c.cal_inicio, 108) timestamp, c.NS
 from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart)) join
 (select top 1 c.inbound_id, i.descripcion, c.NS, convert(varchar(5), max(c.cal_inicio), 108) timestamp
  from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart)) join ccinbound i on c.inbound_id = i.inbound_id
  where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id
  --and c.cal_inicio < convert(varchar(15), getdate(), 121)+''0:00''
  group by c.inbound_id, i.descripcion, c.NS order by timestamp desc) D on c.inbound_id = d.inbound_id
 where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id
  --and c.cal_inicio < convert(varchar(15), getdate(), 121)+''0:00''
 order by 4 desc) as chart order by 4
 return(0)
end

if @graphicType = 2
begin


 Set @End = getdate()
 Set @Start = convert(varchar(15),dateadd(minute, -200, @end),121) + ''0:00''

 While @Start < @End begin
  Insert @Times(StartDate, EndDate, [timestamp])
  values(@Start, DateAdd(minute, 10, @Start), convert(varchar(5), convert(datetime,@Start), 108))

  Set @Start = DateAdd(minute, 10, @Start)
 End

 select @descripcion = descripcion
 from ccinbound
 where inbound_id = @inbound_id

 create table #ChatSummary(
 inboundId smallint not null,
 descripcion varchar(50) not null,
 LastNS decimal(10,2) not null,
 [timestamp] varchar(5) not null,
 NS decimal(10,2) not null,
 )

 create table #ChatChart(
 inboundId smallint not null,
 descripcion varchar(50) not null,
 LastNS decimal(10,2) not null,
 [timestamp] varchar(5) not null,
 NS decimal(10,2) not null,
 )

 insert into #ChatSummary
 select inboundId, descripcion,
 0.00 as LastNS,
 convert(varchar(5), convert(datetime,Date), 108) [timestamp],
 convert(decimal(10,2),convert(float,[Connected]) / convert(float, Total) * 100.00) as NS
 from
 (select inboundId, descripcion, Date,
 sum([Connected>DT]) as [Connected],
 sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as NotConnected,
 sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as Total
 from (
 select inboundId, descripcion, convert(varchar(15), chatDate, 121)+''0:00'' as Date,
 ISNULL(count(CASE WHEN chatstatus = 4 and tChatting >= @DTChat THEN 1 ELSE NULL END),0)AS [Connected>DT],
 ISNULL(count(CASE WHEN chatstatus = 4 and tChatting < @DTChat THEN 1 ELSE NULL END),0)AS [Connected<DT],
 ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
 ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
 ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
 ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
 ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
 from ccRIAChats a
 right outer join @times b on (chatDate >= StartDate and chatDate < EndDate)
 left outer join ccInbound c on (inboundId = inbound_id)
 where inboundId = @inbound_id
 and chatStatus in (3,4,7,9,10,11)
 and chatDate is not null
 group by inboundId, descripcion, convert(varchar(15), chatDate, 121)+''0:00'') as ChatDetail
 group by inboundId, descripcion, Date) as ChatSummary


 insert into #ChatChart
 select case when (inboundId is null) then @inbound_id else inboundID end as inboundId,
 case when (descripcion is null) then @descripcion else descripcion end as descripcion,
 case when (LastNS is null) then 0.00 else LastNS end as LastNS,
 case when (a.[timestamp] is null) then b.[timestamp] else a.[timestamp] end as [timestamp],
 case when (NS is null) then 0.00 else NS end as NS
 from #ChatSummary a
 full outer join @times b on (a.[timestamp] = b.[timestamp])
 order by b.[timestamp]

 select a.inboundId, a.descripcion, b.NS as LastNS, a.[timestamp], a.NS
 from #ChatChart a, #ChatChart b
 where convert(varchar(5),dateadd(minute, -10, convert(datetime,a.[timestamp])), 108) = b.[timestamp]
 order by a.[timestamp]

 drop table #ChatSummary
 drop table #ChatChart
 return(0)
end

if @graphicType = 3
begin
	Set @End = getdate()
	Set @Start = convert(varchar(15),dateadd(minute, -200, @end),121) + ''0:00''

	While @Start < @End begin
	Insert @Times(StartDate, EndDate, [timestamp])
	values(@Start, DateAdd(minute, 10, @Start), convert(varchar(5), convert(datetime,@Start), 108))

	Set @Start = DateAdd(minute, 10, @Start)
	End

	select @descripcion = descripcion
	from ccinbound
	where inbound_id = @inbound_id

	create table #MailSummary(
	inboundId smallint not null,
	descripcion varchar(50) not null,
	LastNS decimal(10,2) not null,
	[timestamp] varchar(5) not null,
	NS decimal(10,2) not null,
	)

	create table #MailChart(
	inboundId smallint not null,
	descripcion varchar(50) not null,
	LastNS decimal(10,2) not null,
	[timestamp] varchar(5) not null,
	NS decimal(10,2) not null,
	)

	insert into #MailSummary
	select
	x.inboundId,x.descripcion,
	0.00 as LastNS,
	convert(varchar(5), convert(datetime,Date), 108) [timestamp],
	convert(decimal(10,2),convert(float,sent+forwarding+closed) / convert(float, received) * 100.00) as NS
	from
	(select
	inboundId,c.descripcion, convert(varchar(15), msg.date, 121)+''0:00'' as Date,
	count(*) received,
	count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
	count(case when messageStatusId = 9 then 1 else null end) forwarding,
	count(case when messageStatusId in (10,11) then 1 else null end) closed
	from message msg (nolock) join conversation con (nolock) on con.conversationId=msg.conversationId
	right outer join @times b on (msg.date >= StartDate and msg.date < EndDate)
	left outer join ccInbound c on (con.inboundId = c.inbound_id)
	where inboundId = @inbound_id
	group by inboundId,c.descripcion, convert(varchar(15), date, 121)+''0:00''
	)x

	select
	inboundId,c.descripcion, convert(varchar(15), msg.date, 121)+''0:00'' as Date,
	count(*) received,
	count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
	count(case when messageStatusId = 9 then 1 else null end) forwarding,
	count(case when messageStatusId in (10,11) then 1 else null end) closed
	from message msg (nolock) join conversation con (nolock) on con.conversationId=msg.conversationId
	right outer join @times b on (msg.date >= StartDate and msg.date < EndDate)
	left outer join ccInbound c on (con.inboundId = c.inbound_id)
	where inboundId = @inbound_id
	group by inboundId,c.descripcion, convert(varchar(15), date, 121)+''0:00''

	insert into #MailChart
	select case when (inboundId is null) then @inbound_id else inboundID end as inboundId,
	case when (descripcion is null) then @descripcion else descripcion end as descripcion,
	case when (LastNS is null) then 0.00 else LastNS end as LastNS,
	case when (a.[timestamp] is null) then b.[timestamp] else a.[timestamp] end as [timestamp],
	case when (NS is null) then 0.00 else NS end as NS
	from #MailSummary a
	full outer join @times b on (a.[timestamp] = b.[timestamp])
	order by b.[timestamp]

	select a.inboundId, a.descripcion, b.NS as LastNS, a.[timestamp], a.NS
	from #MailChart a, #MailChart b
	where convert(varchar(5),dateadd(minute, -10, convert(datetime,a.[timestamp])), 108) = b.[timestamp]
	order by a.[timestamp]

	drop table #MailSummary
	drop table #MailChart
	return(0)
end
'
	EXEC(@Sql)

		set @process = 'CREATE PROCEDURE [dbo].[ccsp_CreateNodeMail]---------'
	set @Sql='CREATE PROCEDURE [dbo].[ccsp_CreateNodeMail]
@conversationId int,
@xml xml OUTPUT,
@supervisor varchar(255)='''',
@template varchar (255)='''',
@ScoreTemplate int=0
AS
BEGIN

--SET @conversationId=16
declare @existAttached bit,@numInteracion smallint

--SELECT @supervisor='''',@template='''',@ScoreTemplate=''''
SELECT @existAttached = case when count(*)>0 then 1 else 0 end
from attached where messageId in (select messageId from message where conversationId=@conversationId)
select @numInteracion = count(*) from message where conversationId=@conversationId


select @xml = convert(xml,''<R03  C01="''+convert(varchar(max),a.conversationId) +''" C02="''
+rtrim(ltrim(convert(varchar(23), min(b.date), 126)))+''" C03="''+convert(varchar(max),max(c.descripcion))
+''" C04="''+ convert(varchar,min(isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno,''''))) +''" C05="''
+convert(varchar,max(isnull(cctipocalif.[Description],''''))) +''" C06="''+ convert(varchar,max(replace(replace(a.mailClient,''<'','' ''),''>'','' ''))) +''" C07="''
+convert(varchar(max),sum(b.tRetention+b.tResponse+b.tWrapup)) +''" C08="''+ convert(varchar,min(a.info)) +''" C09="''
+convert(varchar(max),max(b.messageStatusid) ) +''" C10="''+  convert(varchar(max), isnull(@numInteracion,0))+''" C11="''
+convert(varchar(max),@existAttached) +''" C12="''+ convert(varchar(max),isnull(@supervisor,'''') ) +''" C13="''+convert(varchar(max),isnull(@template,'''') )  +''" C14="''+convert(varchar(max),isnull(@ScoreTemplate,0))
+''" C15="''+ convert(varchar,max(isnull(cctipocalifsub.califSubdesc,''''))) +''" C16="''+ convert(varchar,min(isnull(a.info,'''')))
+  ''"/>'')
from conversation a
inner join message b on a.conversationid=b.conversationid
left outer join ccinbound c on c.inbound_id = a.inboundid
left outer join ccusers d on d.user_id = b.userid
left outer join relationmessageDisposition e on e.messageId=b.messageId
left outer join cctipocalif on cctipocalif.calif_id = e.dispositionId
left outer join cctipocalifsub on cctipocalifsub.califsub_id = e.subdispositionId and e.subdispositionId <> 0
where a.conversationId=@conversationId
group by a.conversationId,a.inboundid
--print convert(nvarchar(1000),@xml)
END'
	EXEC(@Sql)


	set @process = 'ccsp_MailAdminAccount - Create SP'
	set @Sql='CREATE PROCEDURE [dbo].[ccsp_MailAdminAccount]
@action int,
@meanContactTypeId smallint = 1,
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
@answerTimeOut tinyint=null
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

declare @isActiveMail bit
set @isActiveMail=0

if @action = 1 begin --checha si esta activo el servicio
	select @isActiveMail = valor from ccSettings where setting_id=152
	if @isActiveMail = 1 begin
		select @isActiveMail=(case when isActive = 1 and @isActiveMail = 1 then 1 else 0 end) from meanContactType where meanContactTypeId = 1
	end
	select @isActiveMail as isActiveMail
	return (0)
end
else if @action = 2 begin -- carga la relacion de especialidades y cuentas de email de entrada
	select A.inboundId,A.conexionInfo,A.connUser,A.connPass
		from ContactMeanIn A
			inner join ccInbound B on A.inboundId=B.Inbound_Id
		where meanContactTypeId = 1 and B.Status=1 and A.isActive=1
end
else if @action = 3 begin	--
	select name,conexionInfo,connUser,ConnPass,numMessages,timeAlertMessage,answerTimeOut from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 4 begin--insert or update relation mail whit ACD by in
	if @connUser='''' 	set @connUser=''nuxiba@nuxiba.com''
	if not exists(select * from ContactMeanIn where inboundId=@inboundId) begin
		if not exists(select * from ContactMeanIn where connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin
		if @name is null set @name=''''
		if @conexionInfo is null set @conexionInfo=''''
		if @connUser is null set @connUser=''''
		if @connPass is null set @connPass=''''
		if @numMessages is null set @numMessages=3
		if @timeAlertMessage is null set @timeAlertMessage=5
		if @isActive is null set @isActive=0
		if @answerTimeOut is null set @answerTimeOut=0

		insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut)
				values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut)
		select 1,''insert''
	end
		else select -1,''insert''
	end
	else begin
		if not exists(select * from ContactMeanIn where inboundId<>@inboundId and connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin
			select @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
				@numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
				@answerTimeOut= isnull(@answerTimeOut,answerTimeOut)
				from ContactMeanIn where inboundId = @inboundId
			update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
				numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut
				where inboundId = @inboundId
			select 1,''update''
		end
		else select -1,''update''
	end
	return (0)
end

else if @action = 5 begin--parameters check conection Mail In
	select conexionInfo,connUser,connPass from ContactMeanIn with(nolock) where inboundId = @inboundId
end
else if @action = 6 begin--parameters check conection Mail Out
	select conexionInfo,connUser,connPass
		from ContactMeanOut with(nolock) where contactMeanOutId  = @contactMeanId
end
else if @action = 7 begin--list mail out by ACD
	select A.contactMeanOutId,A.name, A.conexionInfo,A.connUser,A.connPass,A.isActive
		from ContactMeanOut A with(nolock)

end
else if @action = 8 begin--insert account mail out
	if not exists(select * from ContactMeanOut where connUser=@connUser) begin
		insert into ContactMeanOut (meanContactTypeId,name,conexionInfo,connUser,ConnPass,isActive)
			values (@meanContactTypeId,@name,@conexionInfo,@connUser,@connPass,@isActive)
		select 1
		return(0)
	end
	else select -1
end
else if @action = 9 begin--update account mail out
	if not exists(select * from ContactMeanOut where contactMeanOutId <> @contactMeanId  and connUser=@connUser) begin

		select  @meanContactTypeId=isnull(@meanContactTypeId,meanContactTypeId),@name=isnull(@name,name),
			@conexionInfo=isnull(@conexionInfo,conexionInfo),@connUser=isnull(@connUser,connUser),
			@connPass=isnull(@connPass,ConnPass),@isActive=isnull(@isActive,isActive)
			from ContactMeanOut where contactMeanOutId = @contactMeanId

		update ContactMeanOut set meanContactTypeId=@meanContactTypeId,name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,isActive=@isActive
		 where contactMeanOutId = @contactMeanId
		 select 1,''update ''
	end
	else select -1
end
else if @action = 10 begin	--insert relation mail out and ACD
	if not exists(select * from relationContactMeanOutInbound where contactMeanOutId=@contactMeanId) begin
		insert into relationContactMeanOutInbound(contactMeanOutId,inboundId) values (@contactMeanId,@inboundId)
	end
end
else if @action = 11 begin --delete relation mail out and ACD
	delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId and inboundId=@inboundId
end
else if @action = 12 begin --delete mail out
	delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId
	delete ContactMeanOut where contactMeanOutId=@contactMeanId
end
else if @action = 13 begin --delete mail out
	if not exists(select * from ContactMeanOut where contactMeanOutId=@contactMeanId) begin
		update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
		select 1
	end
	else select -1
end
else if @action = 14 begin
	select * from relationContactMeanOutInbound
end
else if @action = 15 begin
	select * from relationContactMeanOutInbound where inboundId=@inboundId
end
--else if @action = 16 begin
--	update ccRIACat_Areas set maxMails = @maxMails where IDArea=@idArea
--end
else if @action = 17 begin	--
	select A.conexionInfo,A.connUser,A.connPass from ContactMeanIn A where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
End
else if @action = 18 begin	--
	select A.contactMeanOutId,A.conexionInfo,A.connUser,A.connPass from contactMeanOut A where isActive=1

end
else if @action = 19 begin	--
	select contactMeanOutId,inboundId from relationContactMeanOutInbound where inboundId = @inboundId or @inboundId = 0 order by inboundId

end
else if @action = 20 begin --relation MailOut and ACD
	select B.inboundId,A.conexionInfo,A.connUser,A.connPass
	from ContactMeanOut A join relationContactMeanOutInbound B
	on B.contactMeanOutId=A.contactMeanOutId
	where B.inboundId = @inboundId or @inboundId = 0
end
else if @action = 21 begin --relation MailOut and ACD
	update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
end
END'

	EXEC(@Sql)

	set @process = 'ccsp_MailSave - Create SP'
	set @Sql='CREATE PROCEDURE [dbo].[ccsp_MailSave]
@action int,  
@uid varchar(max)=null,  
@date datetime=null,  
@conversationId int=0,  
@inboundId smallint=null,  
@userId smallint=0,  
@messageStatusId int=null,  
@isInbox bit=1,  
@messageId int =null,  
@timeAtt int = 0,  
@pathFile varchar(255)= null,  
@mailClient varchar(60)= null,  
@mailACD varchar(60)= null,  
@isSender bit=0,  
@isUser bit = 0,  
@info varchar(255)=null,  
@dispositionId smallint=0,  
@subDispositionId smallint=0,  
@tWrapUp int =0,  
@tRetention int = 0,  
  
---Finder  
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0  
AS  
BEGIN  
  
  
declare @isEndConversation bit  
declare @meanContactTypeId smallint  
declare @xmlnode xml  
declare @existAttached bit, @numInteracion smallint  
  
set @meanContactTypeId = 1  
SET NOCOUNT ON;  
  
if @action = 1 begin --find uid ConversationMail  
  select count(*) from messageMail where [uid]=@uid  
  return (0)  
end  
else if @action = 2 BEGIN --new Conversation  
 if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin  
  insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)  
  select @conversationId=SCOPE_IDENTITY()  
  insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,0,@date,@messageStatusId)  
  select @messageId=SCOPE_IDENTITY()  
  insert into [messageMail](messageId,[uid]) values (@messageId,@uid)  
  select @conversationId as conversationId,@messageId as messageId,0 as lastUserId  
  return (0)  
 end  
 else begin  
  select 0 as conversationId,0 as messageId,0 as lastUserId  
  return (0)  
 end  
END  
else if @action = 3 BEGIN --new Messages  
 if @date is null set @date=getdate()  
 update [conversation] set info=@info where conversationId=@conversationId  
 insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,@userId,@date,@messageStatusId)  
 select @messageId=SCOPE_IDENTITY()  
  
 if @uid is null --for outbound messages  
  select @uid = dbo.md5(cast(@conversationId as varchar(10)) + ''_'' + cast(@messageId as varchar(10)))  
  
 insert into [messageMail](messageId,[uid]) values (@messageId,@uid)  
  
 --Finder  
 select @existAttached =case when count(*)>0 then 1 else 0 end  from attached where messageId in (select messageId from message where conversationId=@conversationId)  
 select @numInteracion = count(*) from message where conversationId=@conversationId  
  
  
 exec ccsp_CreateNodeMail @conversationId, @xml = @xmlnode OUTPUT  
  
 if not exists(select * from ccEmailNode where emailId=@conversationId) begin  
  insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)  
 end  
 else begin  
  update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId  
 end  
  
  
  
 select @conversationId as conversationId,@messageId as messageId,0 as lastUserId  
  
END  
else if @action = 4 BEGIN --new attachment  
 insert into [attached](messageId,pathFile,isUser) values(@messageId,@pathFile,@isUser)  
 select SCOPE_IDENTITY() as attachedId  
END  
else if @action = 5 BEGIN --Correos por contestar  
--Status DOWNLOAD,Assigned,READ,UnaSSIGNED  
 select A.conversationId,B.userId,A.mailClient,A.mailInbound,A.info,B.messageStatusId,max(B.messageId) as messageId  
 from conversation A  
 inner join message B on A.conversationId = B.conversationId  
 where A.inboundId = @inboundId and B.messageStatusId in(1,2,3,4) and meanContactTypeId = @meanContactTypeId  
 GROUP BY A.conversationId,A.inboundId,A.info,A.mailClient,A.mailInbound,B.messageStatusId,B.userId  
END  
else if @action = 6 BEGIN --update Time Attention, Retencion  
 select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId  
 update [message] set tResponse=@timeAtt,tRetention=@tRetention,isSender=@isSender,messageStatusId=@messageStatusId,userId=@userId where messageId=@messageId  
  
 ----Status Send,Close conversation system and Close conversation agent  
 --select A.conversationId,B.userId,A.mailClient,A.mailInbound,A.info,B.messageStatusId,max(B.messageId) as messageId  
 -- from conversation A  
 -- inner join message B on A.conversationId = B.conversationId  
 -- where A.inboundId = @inboundId and B.messageStatusId in(5,7,8,9) and meanContactTypeId = @meanContactTypeId  
 -- GROUP BY A.conversationId,A.inboundId,A.info,A.mailClient,A.mailInbound,B.messageStatusId,B.userId  
END  
else if @action = 7 BEGIN --Cambia el status del mensaje  
 select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId  
 update [message] set messageStatusId=@messageStatusId where messageId=@messageId  
 if @messageStatusId=6  
  update [message] set tSend=getdate() where messageId=@messageId  
  
 if @messageStatusId=5  
  begin  
   exec ccsp_CreateNodeMail @conversationId, @xml = @xmlnode OUTPUT  
   if not exists(select * from ccEmailNode where emailId=@conversationId) begin  
    insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)  
   end  
   else begin  
    update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId  
   end  
  end  
END  
else if @action = 8 BEGIN --info del ultimo correo  
 select messageId,GP.inboundId,C.connUser mailInbound,mailClient,mediaType,messageStatusId,info,I.descripcion,IG.graphic_id,I.tNotas,isnull(C.answerTimeOut,10) tTimeOut,C.timeAlertMessage tAlert  
  from (  
  select max(B.messageId) messageId,A.inboundId,A.mailClient,  
   case A.meanContactTypeId when 1 then 3 else -1 end mediaType, B.messageStatusId, max(A.info) info  
   from conversation A inner join message B  on A.conversationId = B.conversationId  
   where A.conversationId=@conversationId  
   GROUP BY A.inboundId,A.mailClient, A.meanContactTypeId, B.messageStatusId, B.userId) GP  
  join contactMeanIn C on C.inboundId=GP.inboundId  
  join ccInbound I on I.Inbound_id=GP.inboundId  
  join ccRIAInboundGraph IG on IG.Inbound_id=GP.inboundId  
END  
else if @action = 9 BEGIN --carga adjuntos del ultimo mensaje
	if isnull(@conversationId,0) = 0 
		select pathFile,isUser from attached where messageId=@messageId and isUser=@isUser  
	else
		select pathFile,isUser from attached A
		inner join message B on A.messageId=B.messageId and B.conversationId=@conversationId
		where B.conversationId=@conversationId
END  
else if @action = 10 BEGIN --Correos por enviar  
 select A.conversationId,max(B.messageId) as messageId,B.userId,A.inboundId,A.mailInbound  
  from conversation A  
  inner join message B on A.conversationId = B.conversationId  
  where B.messageStatusId in(5,7,8,9) and A.meanContactTypeId = 1 and isSender=1  
  GROUP BY A.conversationId,A.inboundId,A.info,A.mailClient,A.mailInbound,B.messageStatusId,B.userId  
END  
  
else if @action = 11 BEGIN --Califica el mensaje y pone el tiempo Notas  
 if @subDispositionId <> 0 begin  
  select @isEndConversation=isnull(EndConversation,0) from ccTipoCalifSub where califSub_id=@subDispositionId  
 end  
 else begin  
  select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@subDispositionId  
 end  
  
 if not exists(select * from relationMessageDisposition where messageId=@messageId) begin  
  insert into relationMessageDisposition(messageId,dispositionId,subDispositionId) values(@messageId,@dispositionId,@subDispositionId)  
 end  
 else begin  
  update relationMessageDisposition set dispositionId=@dispositionId,subDispositionId=@subDispositionId where messageId=@messageId  
 end  
 update message set tWrapUp=@tWrapUp where messageId=@messageId  
 if @isEndConversation = 1 begin  
  select @conversationId=conversationId from [message] where messageId=@messageId  
  update conversation set isFinished=@isEndConversation where conversationId=@conversationId  
 end  
END  
else if @action = 12 begin --Tiempo de cola  
 select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId  
 update [message] set tQueue=getdate(),userId=@userId where messageId=@messageId  
end  
else if @action = 13 BEGIN  -- desasignar  
 if @messageId = 0 begin  
  
  insert into [messageUnAssigned](messageId,userId,[time],isLogout)  
  select messageId,userId,datediff(ss,tQueue,getdate()) as [time],1 as isLogout from [message] where userId=@userId and messageStatusId in (2,3)  
  
  update [message] set tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0 where userId=@userId and messageStatusId in (2,3)  
 end  
 else begin  
  insert into [messageUnAssigned](messageId,userId,[time],isLogout)  
  select messageId,userId,datediff(ss,tQueue,getdate()) as [time],0 as isLogout from [message] where userId=@userId and messageId=@messageId and messageStatusId in (2,3)  
  
  update [message] set tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0 where userId=@userId and messageId=@messageId and messageStatusId in (2,3)  
 end  
end  
else if @action = 14 begin  
 select 1  
end  
else if @action = 15 begin  
 SELECT @existAttached = case when count(*)>0 then 1 else 0 end  
 from attached where messageId in (select messageId from message where conversationId=@conversationId)  
 select messageid,A.inboundid,a.conversationid,mailClient,date,@existAttached isAttached,C.descripcion,
 B.tSend,D.Nombres+'' ''+D.ApellidoPaterno+'' ''+D.ApellidoMaterno,E.timeAlertMessage,E.answerTimeOut,C.tNotas,
 E.connUser as MailInbound
 from conversation A  
 inner join message B  on A.conversationId = B.conversationId  
 inner join ccinbound C on A.inboundid= C.inbound_id
 left join ccUsers D on B.userId = D.User_id  
 inner join contactMeanIn E on E.inboundId=C.Inbound_id
 where A.conversationId=@conversationId  

end  
else if @action = 16 begin  
 select A.inboundid,B.messageid,a.conversationid,c.pathFile  
 from conversation A  
 inner join message B  on A.conversationId = B.conversationId  
 inner join attached C on B.messageid= C.messageid  
 where A.conversationId=@conversationId  
end  
else if @action = 17 begin
	exec ccsp_CreateNodeMail @conversationId=@conversationId, @xml = @xmlnode OUTPUT,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate	
	if not exists(select * from ccEmailNode where emailId=@conversationId) begin  
	select @conversationId
		insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)  
	end  
	else begin  
		update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId  
	end  
  
end  
END'

	EXEC(@Sql)

	set @process = 'create SP -- ccsp_Skills'
	set @Sql='CREATE PROCEDURE [dbo].[ccsp_Skills]
	@action int ,@userId int=null,@inboundId tinyint=null,@skill int =8,@idwg smallint=null
AS

if @action = 1 begin --lista acd de un admin
	select distinct i.Inbound_id, i.descripcion, g.frame,i.chat mode from ccRIACampEspWG wg
		inner join ccInbound i  ON wg.IdCampEsp=i.Inbound_id
		inner join ccRIAInboundGraph ig ON ig.Inbound_id = i.Inbound_id
		inner join ccRIAGraphics g ON g.graphic_id=ig.graphic_id
		inner join ccRIAWorkGroupUsers wgUser on WgUser.IDWG=wg.IDWG
		where wg.Tipo=0 and wgUser.User_id=@userId
end
else if @action=2 begin
	select distinct A.user_id,A.Nombres+'' '' +A.ApellidoPaterno+ '' '' +A.ApellidoMaterno name,isnull(B.Skill,8) skill
		from ccRIACampEspWG D
		inner join ccRIAWorkGroupUsers C on D.IDWG=C.IDWG
		inner join ccusers A on C.User_id=A.User_id
		left join ccSkills B on B.User_id= A.User_id and D.IdCampEsp= B.Inbound_id
		where D.IdCampEsp=@inboundId and A.TipoUser_id=1
end
else if @action =3 begin
	if @userId = 0 begin
		update ccSkills set Skill=@skill where Inbound_id=@inboundId
		select 1,''update All''
	end
	else begin
		if not exists(select * from ccSkills where Inbound_id= @inboundId and User_id=@userId) begin
			insert into ccSkills (Inbound_id,User_id,Skill) values (@inboundId,@userId,@skill)
			select 1,''insert''
			end
		else begin
			update ccSkills set Skill=@skill where Inbound_id=@inboundId and User_id=@userId
			select 1,''update''
		end
	end
end
else if @action = 4 begin --delete wg
	delete s from ccSkills S
inner join (select A.inboundId from
		(select distinct isnull(C.Inbound_id,B.IdCampEsp) inboundId from ccRIAWorkGroupUsers A inner join ccRIACampEspWG B on A.IDWG = B.IDWG and B.Tipo=0 left join ccSkills C on C.Inbound_id = B.IdCampEsp where A.User_id=@UserId and B.IDWG= @idwg) A
			left join
		(select distinct isnull(C.Inbound_id,B.IdCampEsp) inboundId from ccRIAWorkGroupUsers A inner join ccRIACampEspWG B on A.IDWG = B.IDWG and B.Tipo=0 left join ccSkills C on C.Inbound_id = B.IdCampEsp where A.User_id=@UserId and B.IDWG<> @idwg) B
			on A.inboundId=B.inboundId 	where B.inboundId is null) I
	on I.inboundId = S.Inbound_id where S.User_id=@UserId
end

else if @action = 5 begin --insert wg
	insert into ccSkills(Inbound_id,User_id,Skill)
select A.inboundId,@UserId,8 as Skill from (
(select distinct isnull(C.Inbound_id,B.IdCampEsp) inboundId from ccRIAWorkGroupUsers A
	inner join ccRIACampEspWG B on A.IDWG = B.IDWG and B.Tipo=0 left join ccSkills C on C.Inbound_id = B.IdCampEsp where A.User_id=@UserId) A
	left join (select Inbound_id as inboundId from ccSkills C where C.User_id=@UserId) B on A.inboundId=B.Inboundid) where B.inboundId is null

end'

	EXEC(@Sql)

	set @process = 'Create SP -- ccsp_MailInitialStatistics'
	set @Sql='CREATE PROCEDURE [dbo].[ccsp_MailInitialStatistics]        
@inboundId int=0,
@Option AS SMALLINT=0,  
@User_id AS SMALLINT=0          
AS        
BEGIN        
        
SET NOCOUNT ON;        

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
	from message msg (nolock) join conversation con (nolock) on con.conversationId=msg.conversationId        
	where inboundId=@inboundId and [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121)        
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
	and [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121)
	GROUP BY InboundId
	END   
END'
	EXEC(@Sql)

	set @process = 'Alter SP -- ccsp_RIAManageWG'
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

		--insert skill media
		exec ccsp_Skills @action= 5,@userId=@UserId


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

		if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@UserId) begin
			insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@UserId)
		end
		return(0)
	 end

	-- -Supervisor	@Type in (2,6)
	insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @UserId)
	if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@UserId) begin
		insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@UserId)
	end

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

	if @Type = 1 --delete skill media
	exec ccsp_Skills @action= 4,@userId=@UserId,@idwg=@IDWG

	Delete ccRIAWorkGroupUsers where IDWG = @IDWG and User_id = @UserId

	if @Type = 1 -- Agente
	 begin
	 	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@UserId and A.IDWG=@IDWG
		insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@UserId and A.IDWG=@IDWG

	 	delete from cccampsagente where user_id=@UserId and IDWG=@IDWG
		delete from ccInboundagentes where user_id=@UserId and IDWG=@IDWG
		select @Type
		return(0)
	 end

	--else if @Type in(2, 6) -- Supervisor
	insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@UserId and A.IDWG=@IDWG
	delete ccSupervisorCam where user_id=@UserId and IDWG=@IDWG
	select @Type
	return(0)
end
return(0)
set nocount off'
	EXEC(@Sql)


	set @process = 'CREATE SP -- ccsp_RIAGetEnabledServices'
	set @Sql='CREATE procedure [dbo].[ccsp_RIAGetEnabledServices]
as
set nocount on

SELECT
--services
case setting_id
	when 145 then 1 --chat
	when 155 then 2 --email
end [serviceId],
1 [enabled]
FROM ccsettings nolock
where setting_id in (145,155) --filter: chat,email
and valor > 0 --enabled only

set nocount off'
	EXEC(@Sql)

	set @process = 'Create SP -- ccsp_RIAMultimediaSignature'
	set @Sql='create procedure [dbo].[ccsp_RIAMultimediaSignature]
@action smallint,
@Description as varchar(40) = null,
@htmlText as varchar(max) = null,
@signature_id as smallint = null,
@campAcd_id as smallint = null
as
set nocount on

if @action = 1 --Load initial info
begin
	select ci.inbound_id, descripcion, graphic_id from ccinbound ci (nolock) join ccRIAInboundGraph cg (nolock) on cg.Inbound_id = ci.Inbound_id where status=1 and chat=3
	select signature_id,description from ccRIAMultimediaSignatures nolock where status=1

	return(0)
end

if @action = 2 --Load Signatures
begin
	select signature_id,description,htmltext from ccRIAMultimediaSignatures nolock where status=1
	return(0)
end

if @action = 3 --Load relations
begin
	select sg.signature_id,description,htmltext from ccRIAMultimediaSignatureRel re (nolock)
	join ccRIAMultimediaSignatures sg (nolock) on sg.signature_id = re.signature_id where campAcd_id = @campAcd_id or @campAcd_id = 0
	return(0)
end

if @action = 4 --Add signature
begin
	If exists(select description from ccRIAMultimediaSignatures where Status=1 and description=@Description)
	 begin
		select 2
		return(0)
	 end

	If exists(select description from ccRIAMultimediaSignatures where Status=0 and description=@Description)
	begin
		update ccRIAMultimediaSignatures set Status=1,htmlText=@htmlText where description=@Description
		return(0)
	end

	insert into ccRIAMultimediaSignatures (signature_id, description, htmlText)
	select isnull(max(signature_id), 0) + 1,@Description,@htmlText from ccRIAMultimediaSignatures
	return(0)
end

if @action = 5 --Update signature
begin
	If exists(select description from ccRIAMultimediaSignatures where Status=1 and description=@Description)
		set @Description=null

	UPDATE ccRIAMultimediaSignatures set Description=isnull(@Description, Description), htmlText=isnull(@htmlText, htmlText)
	where signature_id = @signature_id
	return(0)
end

if @action = 6 --Delete signature
begin
	delete ccRIAMultimediaSignatureRel where signature_id = @signature_id
	update ccRIAMultimediaSignatures set Status=0 where signature_id = @signature_id
	return(0)
end

if @action = 7 --Delete relation
begin
	delete ccRIAMultimediaSignatureRel where signature_id = @signature_id and (campAcd_id = @campAcd_id /*or @campAcd_id = 0*/)
	return(0)
end

if @action = 8 --Add relation
begin
	if not exists(select * from ccRIAMultimediaSignatureRel where signature_id = @signature_id and campAcd_id = @campAcd_id)
	begin
		delete ccRIAMultimediaSignatureRel where campAcd_id = @campAcd_id --only one
		insert ccRIAMultimediaSignatureRel (signature_id, campAcd_id) values (@signature_id, @campAcd_id)
	end
	return(0)
end

set nocount off'
	EXEC(@Sql)

	set @process = 'Alter SP -- ccsp_RIAConfEspec'
	set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
@User_id int
AS
set nocount on

select A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat, A.inactiveChatTime, A.maxChats, A.chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
isnull(A.startStopRecording,0),isnull(B.name,'''') as nameMail,isnull(B.conexionInfo,'''') as conexionInfo,isnull(B.connUser,'''') as connUser,
isnull(B.ConnPass,'''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage,
isnull(B.IsActive,0) as Active, isnull(B.answerTimeOut,0) as answerTimeOut
from ccInbound A
left join ContactMeanIn B on A.inbound_id=B.inboundId
where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 2))

return(0)
set nocount off'
	EXEC(@Sql)


	set @process = 'Alter SP -- ccsp_RIACATChatPredefinedMsg'
	set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAChatPredefinedMsg]
@Type smallint,
@Type2 smallint,
@IDArea smallint=0,
@CamEspID smallint,
@User_id smallint,
@InsertMessage_id varchar(1000),
@DeleteMessage_id varchar(1000),
@serviceId smallint = 1 --Default Chat
AS
set nocount on

If @Type=1--get ACDGroups
 begin
	if @serviceId = 2 --1 chat, 2 Email
		begin
			set @serviceId = 3
		end
	SELECT a1.Inbound_id, descripcion, a2.graphic_id, a3.frame, a1.chat from ccInbound a1
	inner join ccRIAInboundGraph a2 on(a1.Inbound_id=a2.Inbound_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where a1.chat = @serviceId and isnull(a1.IDArea, -1) = case when @IDArea=0 then -1
	when (select login from ccusers where user_id = @User_id) = ''root'' then isnull(a1.IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

IF @Type=2--query
 begin
	select i.Inbound_id, descripcion , c.message_id, description, [message]
	from ccInbound i inner join ccRIAChatInboundPredefinedMsg c on i.Inbound_id=c.Inbound_id
	inner join ccRIAChatPredefinedMsg m on m.message_id=c.message_id and m.serviceId=c.serviceId
	where m.message_status=1 and c.serviceId=@serviceId and i.Inbound_id=@CamEspID
	order by 4
	return(0)
 end

If @Type=3--get Areas
 begin
	if exists(select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id)
	and (select login from ccUsers where user_id=@User_id)<>''root''
		select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	else
		select * from ccRIACAT_Areas where StatusArea=1 order by AreaName
	return(0)
 end

declare @sql nvarchar(1000), @nIDArea nvarchar(10)

if @Type=4--Insert Message
 begin
	If @Type2=2
	 begin
		If exists(select inbound_id from ccRIAChatInboundPredefinedMsg where inbound_id=@CamEspID and message_id=@InsertMessage_id and serviceId=@serviceId)
			select 2
		else
			if exists(select inbound_id from ccInbound where Inbound_id=@CamEspID)
			and exists(select message_id from ccRIAChatPredefinedMsg where message_status=1 and message_id=@InsertMessage_id and serviceId=@serviceId)
					insert ccRIAChatInboundPredefinedMsg(inbound_id, message_id, serviceId) select @CamEspID, @InsertMessage_id, @serviceId
		return(0)
	 end

	If @Type2=1
	begin
		set @nIDArea = 0
		select @nIDArea=IDArea from ccUsers where USER_ID=@User_id
		if @nIDArea>0
		begin
			set @sql=''insert ccRIAChatInboundPredefinedMsg (inbound_id,message_id,serviceId)
			select distinct a.inbound_id, b.message_id, b.serviceId from ccInbound a, ccRIAChatPredefinedMsg b where
			b.message_id in(''+@InsertMessage_id+'') and b.message_status=1 and b.serviceId=''+cast(@serviceId as nvarchar)+''
			and not exists(select c.inbound_id, e.message_id, e.serviceId from ccRIAChatInboundPredefinedMsg c
			join ccRIAChatPredefinedMsg e on e.message_id=c.message_id and e.serviceId=c.serviceId
			join ccInbound d on d.inbound_id=c.inbound_id and IDArea=''+@nIDArea+
			'' where c.inbound_id=a.inbound_id and b.message_id=e.message_id and b.serviceId=e.serviceId)
			and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea=''+@nIDArea+'' and ((chat>0 and ''+cast(@serviceId as nvarchar)+''=1) || (''+cast(@serviceId as nvarchar)+''<>1)))''
			declare @serviceType int
			if(@serviceId = 1)
				begin
					set @serviceType = 1
				end
			if(@serviceId = 2)
				begin
					set @serviceType = 3
				end
			set @sql=''insert ccRIAChatInboundPredefinedMsg (inbound_id,message_id,serviceId)
			select distinct a.inbound_id, b.message_id, '' + cast(@serviceId as nvarchar) + '' from ccInbound a, ccRIAChatPredefinedMsg b where
			b.message_id in(''+@InsertMessage_id+'') and b.message_status=1 
			and not exists(select c.inbound_id, e.message_id, e.serviceId from ccRIAChatInboundPredefinedMsg c
			join ccRIAChatPredefinedMsg e on e.message_id=c.message_id and e.serviceId=c.serviceId
			join ccInbound d on d.inbound_id=c.inbound_id and IDArea=''+@nIDArea+
			'' where c.inbound_id=a.inbound_id and b.message_id=e.message_id and b.serviceId=e.serviceId)
			and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea=''+@nIDArea+'' and chat = ''+ cast(@serviceType as nvarchar) +'')''
			execute sp_executesql @sql
		end
	end
		return(0)
 end

If @Type=5--Delete Messages
 begin
	If @Type2=2
	 begin
		delete ccRIAChatInboundPredefinedMsg where inbound_id=@CamEspID	and message_id=@DeleteMessage_id and serviceId=@serviceId
		return(0)
	 end

	If @Type2=1
	begin
		set @nIDArea = 0
		select @nIDArea=IDArea from ccUsers where USER_ID=@User_id
		if @nIDArea>0
		begin
			set @sql=''delete ccRIAChatInboundPredefinedMsg where inbound_id in(select inbound_id from
			ccInbound where IDArea=''+@nIDArea+'') and message_id in(''+@DeleteMessage_id+'') and serviceId ='' + cast(@serviceId as nvarchar)
			execute sp_executesql @sql
		end
		return(0)
	end
 end

 If @Type=6 --get Areas
 begin
	select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	return(0)
 end

return(0)
set nocount off'
	EXEC(@Sql)


	set @process = 'CREATE procedure ccsp_RIAMultimediaAddresses-------  '
	set @Sql = 'CREATE procedure [dbo].[ccsp_RIAMultimediaAddresses]
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
set nocount off '
	EXEC(@sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAChatPredefinedMsg]--------'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAChatPredefinedMsg]
@Type smallint,
@Type2 smallint,
@IDArea smallint=0,
@CamEspID smallint,
@User_id smallint,
@serviceId smallint,
@InsertMessage_id varchar(1000),
@DeleteMessage_id varchar(1000)

AS
set nocount on

If @Type=1--get ACDGroups
 begin
	SELECT a1.Inbound_id, descripcion, a2.graphic_id, a3.frame, a1.chat from ccInbound a1
	inner join ccRIAInboundGraph a2 on(a1.Inbound_id=a2.Inbound_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where a1.chat>0 and isnull(a1.IDArea, -1) = case when @IDArea=0 then -1
	when (select login from ccusers where user_id = @User_id) = ''root'' then isnull(a1.IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

IF @Type=2--query
 begin
	select i.Inbound_id, descripcion , c.message_id, description, [message]
	from ccInbound i inner join ccRIAChatInboundPredefinedMsg c on i.Inbound_id=c.Inbound_id
	inner join ccRIAChatPredefinedMsg m on m.message_id=c.message_id --and m.serviceId=c.serviceId
	where m.message_status=1 and c.serviceId=@serviceId and i.Inbound_id=@CamEspID
	order by 4
	return(0)
 end

If @Type=3--get Areas
 begin
	if exists(select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id)
	and (select login from ccUsers where user_id=@User_id)<>''root''
		select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	else
		select * from ccRIACAT_Areas where StatusArea=1 order by AreaName
	return(0)
 end

declare @sql nvarchar(1000), @nIDArea nvarchar(10)

if @Type=4--Insert Message
 begin
	If @Type2=2
	 begin
		If exists(select inbound_id from ccRIAChatInboundPredefinedMsg where inbound_id=@CamEspID and message_id=@InsertMessage_id and serviceId=@serviceId)
			select 2
		else
			if exists(select inbound_id from ccInbound where Inbound_id=@CamEspID)
			and exists(select message_id from ccRIAChatPredefinedMsg where message_status=1 and message_id=@InsertMessage_id) --and serviceId=@serviceId)
					insert ccRIAChatInboundPredefinedMsg(inbound_id, message_id, serviceId) select @CamEspID, @InsertMessage_id, @serviceId
		return(0)
	 end

	If @Type2<>1
		return(0)

		set @nIDArea = 0
		select @nIDArea=IDArea from ccUsers where USER_ID=@User_id
		if @nIDArea>0
		begin
			--set @sql=''insert ccRIAChatInboundPredefinedMsg (inbound_id,message_id,serviceId)
			--select distinct a.inbound_id, b.message_id, b.serviceId from ccInbound a, ccRIAChatPredefinedMsg b where
			--b.message_id in(''+@InsertMessage_id+'') and b.message_status=1 and b.serviceId=''+@serviceId+''
			--and not exists(select c.inbound_id, e.message_id, e.serviceId from ccRIAChatInboundPredefinedMsg c
			--join ccRIAChatPredefinedMsg e on e.message_id=c.message_id and e.serviceId=c.serviceId
			--join ccInbound d on d.inbound_id=c.inbound_id and IDArea=''+@nIDArea+
			--'' where c.inbound_id=a.inbound_id and b.message_id=e.message_id and b.serviceId=e.serviceId)
			--and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea=''+@nIDArea+'' and ((chat>0 and ''+@serviceId+''=1) || (''+@serviceId+''<>1)))''
			declare @serviceType int
			if(@serviceId = 1)
				begin
					set @serviceType = 1
				end
			if(@serviceId = 2)
				begin
					set @serviceType = 3
				end
			set @sql=''insert ccRIAChatInboundPredefinedMsg (inbound_id,message_id,serviceId)
			select distinct a.inbound_id, b.message_id, '' + cast(@serviceId as nvarchar) + '' from ccInbound a, ccRIAChatPredefinedMsg b where
			b.message_id in(''+@InsertMessage_id+'') and b.message_status=1
			and not exists(select c.inbound_id, e.message_id, e.serviceId from ccRIAChatInboundPredefinedMsg c
			join ccRIAChatPredefinedMsg e on e.message_id=c.message_id and e.serviceId=c.serviceId
			join ccInbound d on d.inbound_id=c.inbound_id and IDArea=''+@nIDArea+
			'' where c.inbound_id=a.inbound_id and b.message_id=e.message_id and b.serviceId=e.serviceId)
			and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea=''+@nIDArea+'' and chat = ''+ cast(@serviceType as nvarchar) +'')''
			execute sp_executesql @sql
		end
		return(0)
 end

If @Type=5--Delete Messages
 begin
	If @Type2=2
	 begin
		delete ccRIAChatInboundPredefinedMsg where inbound_id=@CamEspID	and message_id=@DeleteMessage_id
		return(0)
	 end

	If @Type2<>1
		return(0)

		set @nIDArea = 0
		select @nIDArea=IDArea from ccUsers where USER_ID=@User_id
		if @nIDArea>0
		begin
			set @sql=''delete ccRIAChatInboundPredefinedMsg where inbound_id in(select inbound_id from
			ccInbound where IDArea=''+@nIDArea+'') and message_id in(''+@DeleteMessage_id+'') and serviceId ='' + cast(@serviceId as nvarchar)
			--print @sql
			execute sp_executesql @sql
		end
		return(0)

 end

 If @Type=6 --get Areas
 begin
	select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	return(0)
 end'
		EXEC(@sql)

	set @process = 'ccsp_Multimedia - Create SP'
	set @Sql='CREATE PROCEDURE [dbo].[ccsp_Multimedia]
@action int,@inboundId tinyint=null,@userId int =0

AS
BEGIN

SET NOCOUNT ON;


if @action = 1 begin --Cuentas acd por tipo

	if @inboundId is null or @inboundId=0 begin
		select A.inbound_id,A.chat as mode,cast(A.status as bit) [status],cast(isnull(b.isActive,0) as bit) isActive,cast(isnull(B.numMessages,3) as int) numMessages,
			case A.chat when 0 then ''call'' when 1 then ''chat'' when 2 then ''call and chat'' when 3 then ''mail'' else ''multimedia'' end  as typeMedia from ccInbound A
			left join ContactMeanIn B on B.inboundId =  A.inbound_id
			where A.IDArea is not null or A.IDArea>0
	end
	else if @inboundId>0 begin
		select A.inbound_id,A.chat as mode,cast(A.status as bit) [status],cast(isnull(b.isActive,0) as bit) isActive,cast(isnull(B.numMessages,3) as int) numMessages,
			case A.chat when 0 then ''call'' when 1 then ''chat'' when 2 then ''call and chat'' when 3 then ''mail'' else ''multimedia'' end  as typeMedia from ccInbound A
			left join ContactMeanIn B on B.inboundId =  A.inbound_id
			where A.inbound_id = @inboundId

	end
end
else if @action = 2 begin --Relacion entre agenetes y acd
	if @inboundId is null or @inboundId=0 begin
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG
		inner join ccInbound D on C.idCampEsp = D.inbound_id and D.chat=3
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1
	end
	else begin
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and D.Inbound_id=@inboundId
	end
end
else if @action =3 begin
	if	@userId is null or @userId=0 begin
		select user_id,Login,isnull(maxmails,3) maxMails from ccusers us (nolock) 
			left join ccriacat_areas area (nolock) on area.idarea=us.idarea where TipoUser_id=1
	end
	else begin 
	select user_id,Login,isnull(maxmails,3) maxMails from ccusers us (nolock) 
			left join ccriacat_areas area (nolock) on area.idarea=us.idarea 
			where TipoUser_id=1 and  us.User_id=@userId
	end
end
END'
	EXEC(@Sql)

	set @process = 'ALTER PROCEDURE  [dbo].[ccsp_AdmGetSupervisorsForAgent]-------'
set @Sql='Alter PROCEDURE  [dbo].[ccsp_AdmGetSupervisorsForAgent]
@chat_id int,@action int =1

AS
BEGIN

	SET NOCOUNT ON;

	declare @age_id int
	declare @conversationId int

	if @action=1 begin --Chat
		select @age_id = userId from ccRIAChats where chatId=@chat_id
	end
	else if @action =3 begin--Mail
		
		select @conversationId=conversationId from message where messageId=@chat_id
		select @chat_id=max(messageId) from message where conversationId=@conversationId and userId>0 
		select @age_id=userId from message where messageId=@chat_id
	end

	select distinct a1.user_id as agt, a5.user_id as sup, a5.login, a5.Nombres, a5.ApellidoPaterno, a5.ApellidoMaterno from ccusers a1 
	inner join ccriaworkgroupusers a2 on (a1.user_id=a2.user_id and tipouser_id=1)
	inner join 
	(select a3.user_id, a4.IDWG, a3.login, a3.Nombres, a3.ApellidoPaterno,a3.ApellidoMaterno  from ccusers a3 
	inner join ccriaworkgroupusers a4 on (a3.user_id=a4.user_id and (tipouser_id=2 or tipouser_id=6))) a5 on (a2.IDWG=a5.IDWG)
	where a1.user_id = @age_id
	order by a1.user_id,a5.user_id	
END'
	EXEC(@Sql)


			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			exec ccsp_getVersion 'BD', @version
			exec ccsp_getVersion 'BDF', @versionFix

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
