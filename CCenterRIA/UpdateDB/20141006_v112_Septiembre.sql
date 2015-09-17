/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author: Jesus Gallardo
Date: 2014/10/06
Description:
	Se agrega tabla ccSkills
	Se agrega columna ccRIACat_Areas para numero maximo mails 
	Se agrega columna IVROptions para nombre de IVR
	
	Se actuliza ccsettings para descripcion ingles setting 163
	Se actuliza cstoTipoLlamada para plan de guatemala
	Se actuliza ccmenus menu columna efectividad de chats
	
	Se modifica Funcion fnGetTipoLlamada
	Se modifica SP ccsp_RIA_ABCAreas para numero maximo de mails y numero maximo de chats
	Se modifica SP ccsp_DLRGetDialInfo
	Se modifica SP ccsp_DLRgetDialPrefix
	Se modifica SP ccsp_IVRChecaInboundHorario
	Se modifica SP ccsp_IVRInCalls
	Se modifica SP ccsp_RIALoadACDGroups cargar los skill de los ACDS
	Se modifica SP ccsp_Limpia
	Se modifica SP xx_OUTInsertNewJOBS_WT_Camp

Database: CCenterRia
Required version: 111

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 112

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

			/* Start script release */
			set @process = 'Create Table - ccSkills'
			set @sql='if not exists (select * from sys.tables where name = N''ccSkills'')
				CREATE TABLE ccSkills(
					Inbound_id smallint,
					User_id smallint,
					Skill smallint,
					primary key(Inbound_id,User_id),
					foreign key (Inbound_id) REFERENCES ccInbound(Inbound_id),
					foreign key (User_id) REFERENCES ccUsers(User_id)
				)'	
			EXEC(@sql)

			set @process = 'Alter Table - ccRIACat_Areas'
			set @sql='if not exists (select * from sys.columns where name = N''maxMails'' and Object_ID = Object_ID(N''ccRIACat_Areas''))
				ALTER TABLE ccRIACat_Areas ADD maxMails tinyint default(3)'	
			EXEC(@sql)
	
			set @process = 'Alter Table - IVROptions'
			set @sql='if not exists (select * from sys.columns where name = N''name'' and Object_ID = Object_ID(N''IVROptions''))
				Alter table IVROptions add name varchar(50) default('''')'	
			EXEC(@sql)

			set @process = 'update ccRIACat_Areas - maxMails'
			set @sql='if exists (select * from sys.tables where name = N''ccRIACat_Areas'')
				update ccRIACat_Areas set maxMails =3'	
			EXEC(@sql)	
	
			set @process = 'update - cstoTipoLlamada'
			set @sql='if exists (select * from sys.tables where name = N''cstoTipoLlamada'')
				begin
					update cstoTipoLlamada set prefijo = ''2%|6%'' where country_id = 11 and tipoLlamada_id = 1
					update cstoTipoLlamada set prefijo = ''3%|4%|5%'' where country_id = 11 and tipoLlamada_id = 2
					update cstoTipoLlamada set prefijo = ''7%'' where country_id = 11 and tipoLlamada_id = 3
				end'	
			EXEC(@sql)
	
			set @process = 'update - ccsettings '
			set @sql='if exists (select * from sys.tables where name = N''ccsettings'')
				update ccsettings set description=''Validate manually - dialed call rate'' where setting_id=164'	
			EXEC(@sql)
	
			set @process = 'upadte - ccmenus '
			set @sql='if exists (select * from sys.tables where name = N''ccmenus'')
				update ccmenus set menu_descrip = ''Efectividad de Chats|Chats Effectiveness'' where type = 3 and menu_id = 3135'	
			EXEC(@sql)
	
			set @process = 'Alter Function - fnGetTipoLlamada'
			if exists (select * from sys.objects where object_id = OBJECT_ID(N'fnGetTipoLlamada') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
				set @sql='ALTER function [dbo].[fnGetTipoLlamada]( @tel varchar(20) )
					returns int
					as
					 begin
						declare @len integer, @tipo integer, @country varchar(5)
						select @country = valor from ccsettings where setting_id = 104
						set @len = len( @tel )
						set @tipo = 0

						if @country <> 11
							begin
								select @tipo= tipoLlamada_id from cstoTipoLlamada with(index(IX_cstoTipoLlamada)) 
								where country_id = @country and (@len = longitud or longitud =0 )and @tel like prefijo 
								order by len(prefijo) asc -- para agarrar el ultimo ( el mas especifico), si se devuelven varias lineas
							end
						else
							begin
								declare @tipoLlamada_id smallint
								declare @longitud tinyint
								declare @prefijo varchar(15)

								declare @prefijosGT table(
								tipoLlamada_id smallint not null,
								longitud tinyint not null,
								prefijo varchar(15) not null,
								[status] bit not null
								)

								insert into @prefijosGT
								select tipoLlamada_id, longitud, prefijo, 0
								from cstoTipoLlamada 
								where country_id = 11

								declare @table table(
									id int not null,
									prefijo nvarchar(100) not null
								)

								while (select count(*) from @prefijosGT where [status] = 0) > 0
								begin
									select top 1 @tipoLlamada_id = tipoLlamada_id, @longitud = longitud, @prefijo = prefijo
									from @prefijosGT 
									where [status] = 0

									insert into @table
									select * from fn_RIASplitDelimited(@prefijo,''|'')

									if @len = @longitud
										begin
											if (select count(*)	from @table	where @tel like prefijo) = 1
												set @tipo = @tipoLlamada_id
										end

									if @tipo <> 0
										update @prefijosGT
										set [status] = 1
									else
										begin
											update @prefijosGT
											set [status] = 1
											where tipoLlamada_id = @tipoLlamada_id

											delete @table
										end
								end
							end

						return @tipo
					 end'	
			else
				set @sql = ''

			EXEC(@sql)

			set @process = 'Alter SP - ccsp_RIA_ABCAreas'
			if exists (select * from sys.procedures where name = N'ccsp_RIA_ABCAreas')
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
						Select a.IDArea, AreaName, isnull(maxChats,0) as maxChats, isnull(maxMails,3) maxMails, 
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

					Insert into ccRIACat_Areas (AreaName,maxMails) values (@Descripcion,@maxMails)			
					select 1, scope_identity()--, Area Insertada
					return(0)
					end

					if @option=3 --Update Area
					begin
						if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
							Update ccRIACat_Areas set AreaName=@Descripcion,maxMails=@maxMails where IDArea=@IDArea
						else
						begin
							Update ccRIACat_Areas set maxMails=@maxMails where IDArea=@IDArea
						end
						Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
					return(0)
					end

					if @option=4 --Delete Area
					begin	
					if (exists(select IDArea from ccUsers where IDArea=@IDArea) 
						or exists(select IDArea from ccCamps where IDArea = @IDArea)
						or exists(select IDArea from ccInbound where IDArea=@IDArea)) 
						and (select valor from ccSettings where setting_id=95)<>1
						begin
						select -1
						return(0)
						end

					declare @DWorkGroups as varchar(500)

					insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select user_id,cam_id,prioridad,skill,rel_id,IDWG from ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea) 
					insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

					Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
					Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

					insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select user_id,cam_id,tipo,IDWG,monitored from ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

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
					end
					return(0)
					set nocount off'	
			else
				set @sql = ''
			EXEC(@sql)

			set @process = 'Alter SP - ccsp_DLRGetDialInfo'
			if exists (select * from sys.procedures where name = N'ccsp_DLRGetDialInfo')			
				set @sql='ALTER procedure [dbo].[ccsp_DLRGetDialInfo]
					@callout_id int,
					@cam_id smallint=0,
					@iPortNumber smallint = 0
					AS
					set nocount on
					declare @message_name as varchar(max), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)
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
					select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
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

					--Custom MOH Files
					DECLARE @MohFiles VARCHAR(8000) 
					SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
					FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

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
						, isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name
						, isnull(@MohFiles,'''') as mohFiles
						FROM ccoCallsOutSource C 
						WHERE C.callout_id = @callout_id
						return
					end 

					set nocount off'	
			else
				set @sql = ''
			EXEC(@sql)

			set @process = 'Alter SP - ccsp_DLRgetDialPrefix'
			if exists (select * from sys.procedures where name = N'ccsp_DLRgetDialPrefix')
				set @sql='ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
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

					--AnswerMachine Message Files
					DECLARE @MsgFiles VARCHAR(8000) 
					SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile 
					FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

					--Custom MOH Files
					DECLARE @MohFiles VARCHAR(8000) 
					SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
					FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

					select @prefix as sDialPrefix, cam_tNoContesta as tNoContesta,
					case when @ani = '''' then ani else @ani end as ani, detectAnswerMachine, detectVoiceMail,
					dbo.EnableCallRecord(@call_record_cam,@pais,@phone) as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles
					from ccCamps where cam_id = @cam_id'	
			else
				set @sql = ''
			EXEC(@sql)
	
			set @process = 'Alter SP - ccsp_IVRChecaInboundHorario'
			if exists (select * from sys.procedures where name = N'ccsp_IVRChecaInboundHorario')
				set @sql='ALTER PROCEDURE [dbo].[ccsp_IVRChecaInboundHorario]
					@inbound_id int
					AS
					set nocount on
					declare @fecha datetime
					declare @dia smallint
					declare @hora smallint
					declare @minuto smallint
					declare @Cuantos smallint
					declare @bnocturno smallint
					declare @tel_noct varchar(14)
					declare @tel_maxqueue varchar(14)
					declare @tel_maxwait varchar(14)
					declare @tel_outservice varchar(14)
					declare @tHoldCall int
					declare @OutOFService tinyint
					declare @Active tinyint
					declare @stopRecording bit
					declare @MohFiles varchar(8000)

						SET DATEFIRST 1

						select @fecha =  getdate()
						select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)
						if ( @dia=1 )	--LUNES
						begin
							select @Cuantos = count(*)
							from ccInbound I join ccInboundHorarios IH
							on I.Inbound_id = IH.Inbound_id
							join ccHorarios H on IH.horario_id = H.Horario_id
							Where I.Inbound_id = @inbound_id
							AND LUNES = 1
							AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						if @dia=2	--MARTES
						begin
							select @Cuantos = count(*)
							from ccInbound I join ccInboundHorarios IH
							on I.Inbound_id = IH.Inbound_id
							join ccHorarios H on IH.horario_id = H.Horario_id
							Where I.Inbound_id = @inbound_id
							AND MARTES = 1
							AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						if @dia=3	--MIERCOLES
						begin
							select @Cuantos = count(*)
							from ccInbound I join ccInboundHorarios IH
							on I.Inbound_id = IH.Inbound_id
							join ccHorarios H on IH.horario_id = H.Horario_id
							Where I.Inbound_id = @inbound_id
							AND MIERCOLES = 1
							AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						if @dia=4	--JUEVES
						begin
							select @Cuantos = count(*)
							from ccInbound I join ccInboundHorarios IH
							on I.Inbound_id = IH.Inbound_id
							join ccHorarios H on IH.horario_id = H.Horario_id
							Where I.Inbound_id = @inbound_id
							AND JUEVES = 1
							AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						if @dia=5	--VIERNES
						begin
							select @Cuantos = count(*)
							from ccInbound I join ccInboundHorarios IH
							on I.Inbound_id = IH.Inbound_id
							join ccHorarios H on IH.horario_id = H.Horario_id
							Where I.Inbound_id = @inbound_id
							AND VIERNES = 1
							AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						if @dia=6	--SABADO
						begin
							select @Cuantos = count(*)
							from ccInbound I join ccInboundHorarios IH
							on I.Inbound_id = IH.Inbound_id
							join ccHorarios H on IH.horario_id = H.Horario_id
							Where I.Inbound_id = @inbound_id
							AND SABADO = 1
							AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						if @dia=7	--DOMINGO
						begin
							select @Cuantos = count(*)
							from ccInbound I join ccInboundHorarios IH
							on I.Inbound_id = IH.Inbound_id
							join ccHorarios H on IH.horario_id = H.Horario_id
							Where I.Inbound_id = @inbound_id
							AND DOMINGO = 1
							AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						--- Para ver si esta Activa la Especialidad
						select @Active = count(*)
						from ccInbound
						where Inbound_id = @inbound_id
						and Status =1
						--- Para ver si esta en Operacion o No esta Campaña
						select @OutOFService = count(*)
						from ccInbound
						where Inbound_id = @inbound_id
						and standby = 0
						IF ( @OutOFService =1 AND @Active=1 and (select valor from ccsettings where setting_id = 4) = 1)
						BEGIN
					--			SI ESTA EN SERVICO
							select  @tHoldCall = tMaxWaitCall, @bnocturno =bnocturno, @stopRecording=stopRecording,
								@tel_noct=tel_noct, @tel_maxqueue=tel_maxqueue, @tel_maxwait=tel_maxwait, @tel_outservice=tel_outservice
								from ccInbound I
								Where I.Inbound_id = @inbound_id

							--Custom MOH Files
							SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
							FROM ccInboundMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE Inbound_id = @Inbound_ID and TYPE = 15 ORDER BY orden
						END
						ELSE
						BEGIN
							IF ( @OutOFService = 0 and (select valor from ccsettings where setting_id = 4) = 1)
							BEGIN -- ESPECIALIDAD NO ACTIVA
								select @Cuantos= -1, @tHoldCall =0, @bnocturno ='''', @tel_noct ='''', @tel_maxqueue='''', @tel_maxwait='''', @tel_outservice='''', @MohFiles=''''
								--from ccInbound
								--Where Inbound_id = @inbound_id
							END
							IF ( @Active = 0 )
							BEGIN -- ESPECIALIDAD FUERA DE SERVICIO TEMPORAL
								select @Cuantos= -2, @tHoldCall =0, @bnocturno ='''', @tel_noct ='''', @tel_maxqueue='''', @tel_maxwait='''', @tel_outservice=tel_outservice, @MohFiles=''''
								from ccInbound
								Where Inbound_id = @inbound_id
							END 
						END
						SET DATEFIRST 7

						select ''Cuantos''=@Cuantos, ''tHoldCall''=@tHoldCall, ''bNocturno''=1, ''tel_MaxWait''=@tel_maxwait, ''tel_MaxQueue''=@tel_maxqueue, ''tel_Noct''=@tel_noct, ''tel_outservice''=@tel_outservice, ''stopRecording''=@stopRecording, ''mohFiles''=isnull(@MohFiles,'''')
					set nocount off'	
			else
				set @sql = ''
			EXEC(@sql)
	
			set @process = 'Alter SP - ccsp_IVRInCalls'
			if exists (select * from sys.procedures where name = N'ccsp_IVRInCalls')
				set @sql='ALTER Procedure [dbo].[ccsp_IVRInCalls]
					@action tinyint = 0 ,
					@ani varchar(30) = null ,
					@idIvr int = 0 , 
					@option varchar(5)= null ,
					@saveType tinyInt = null,
					@dnis varchar(50) = null,
					@name varchar(50) = null
					-- saveType 1 es menu 2 es dato
					-- accion 1 siempre @ani  -> @idIvr
					-- accion 2 siempre @idIvr @opcionDigitada -> nada
					AS

					IF @action = 1 
						BEGIN
							IF @ani IS NOT NULL 
								BEGIN
									INSERT  INTO IVRCallsIn(cal_ani,date,dnis) values(@ani,getDate(),isnull(@dnis,''''));
									Select ''ID''=scope_identity()
								END
						END
					ELSE IF @action = 2 
						BEGIN
							IF @option IS NOT NULL AND @idIvr IS NOT NULL
								BEGIN
									INSERT INTO IVROptions(IVR_id,selectedOption,date,saveType,name) values (@idIvr,@option,getDate(),@saveType,@name)
									select 0
								END
						END'	
			else
				set @sql = ''
			EXEC(@sql)

			set @process = 'Alter SP - ccsp_RIALoadACDGroups'
			if exists (select * from sys.procedures where name = N'ccsp_RIALoadACDGroups')
				set @sql='ALTER PROCedure [dbo].[ccsp_RIALoadACDGroups]
					@option smallint,
					@AreaId smallint,
					@Sup smallint,
					@inbound_id int = 0,
					@tipoModalidad tinyint = 0 -- llamada 0, chat 1 y ambos 2
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

						select distinct a1.inbound_id, descripcion, frame, isnull(IDArea,0) IDArea, dbo.fn_CampEspWG(a1.inbound_id, 2) relationsWG,a1.chat mode, skillDif
							from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
							inner join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
							left join (select inbound_id,case when (sum(skill)/count(user_id)) = max(skill) then 0 else 1 end skillDif from ccSkills GROUP BY inbound_id)
								S on S.Inbound_id=a1.inbound_id
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

					if @option = 9 -- ACDGroups por Supervisor para mensajes llamadas o chat filtra las campaÃ±as
					begin
					select distinct a1.inbound_id, descripcion, frame, isnull(IDArea,0) as IDArea, U.monitored
					from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
					join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
					join ccSupervisorCam U on a1.inbound_id = U.cam_id
					where U.user_id = @sup
					and tipo = 0
					and a3.type_id = 1 
					and a1.inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@Sup, 2)) 
					and a1.chat IN (2,@tipoModalidad)
					order by descripcion
					return(0)
					end

					return(0)
					set nocount off'	
			else
				set @sql = ''
			EXEC(@sql)
	
			set @process = 'Alter SP - ccsp_Limpia'
			if exists (select * from sys.procedures where name = N'ccsp_Limpia')
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

					set nocount off'	
			else
				set @sql = ''
			EXEC(@sql)
	
			set @process = 'ALTER SP - xx_OUTInsertNewJOBS_WT_Camp'
			if exists (select * from sys.procedures where name = N'xx_OUTInsertNewJOBS_WT_Camp')
				set @sql='ALTER PROCEDURE [dbo].[xx_OUTInsertNewJOBS_WT_Camp]
					@camp_id as int
					AS
					set nocount on
					declare @prioridad varchar(8)

					Insert ccoWorkingTable ( callout_id, user_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano,
					 iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5  )
					SELECT callout_id, user_id, cam_id, 
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
					case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end
					FROM ccoCallsOutSource with( index(IX_ccoCallsOutSource_11), nolock)
					WHERE cam_id = @camp_id and (cal_status <2 or cal_status=7) -- Nuevos Jobs

					--la prioridad establecidad (si existe) 
					select @prioridad = NULL
					select @prioridad = Prioridad from ccCampsPrioridadTel (nolock) where cam_id = @camp_id

					UPDATE ccoCallsOutSource with(rowlock)
					SET cal_status = 3, dial_tels = isNull( @prioridad, ''12345NNN''), nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
					where cal_status in (0, 1, 7) and cam_id = @camp_id'	
			else
				set @sql = ''
			EXEC(@sql)
			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			exec ccsp_getVersion 'BD', @version

		commit tran
		end try

		begin catch	

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)
		
		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off

/**************************/
/***** GUIDE AND HELP *****/
/**************************/

/* IMPORTANT: Consider objects manipulation in the sequence exposed in order to get consistency in the script, uncommon objects are prior to common ones in case of exist except replication */

/***** Language Reference *****/
/*
DDL (Data Definition Language)
	* Create
	* Drop
	* Alter

DML (Data Manipulation Language)
	* Select
	* Update
	* Delete
	* Insert

Contraint Object Types
	* C = CHECK constraint
	* D = DEFAULT (constraint or stand-alone)
	* F = FOREIGN KEY constraint
	* PK = PRIMARY KEY constraint
	* R = Rule (old-style, stand-alone)
	* UQ = UNIQUE constraint

Function Object Types
	* FN Scalar function
	* IF Inline table-valued function
	* TF Table-valued-function
	* FS Assembly (CLR) scalar-function
	* FT Assembly (CLR) table-valued function
*/

/***** Most common objects *****/
/* 
TABLES
-- When table exists
if exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

-- When table does not exists
if not exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

COLUMNS
-- When column exists
if exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When column does not exists
if not exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

CONSTRAINTS
-- When constraint exists
if exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not exists
if not exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

INDEXES
-- When index exists
if exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When index does not exists
if not exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

TRIGGERS
-- When trigger exists
if exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When trigger does not exists
if not exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

FUNCTIONS
-- When function exists
if exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

-- When function does not exists
if not exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

STORED PROCEDURES
-- When stored procedure exists
if exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

-- When stored procedure does not exists
if not exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

VIEWS
-- When view exists
if exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

-- When view does not exists
if not exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

JOBS (In this case be careful about what to do)
-- if you want to create, modify or delete use the script below
if exists (select * from msdb.dbo.sysjobs_view where name = N'yourJobName')
	begin
		exec msdb.dbo.sp_delete_job @job_name = N'yourJobName', @delete_unused_schedule=1
	end

-- After that, you could run the script to create the Job despite of being new or being modified
*/

/***** Uncommon objects *****/
/*
DATABASES
-- When database exists
if exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

-- When database does not exists
if not exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

LOGINS
-- When login exists
if exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

-- When login does not exists
if not exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

SERVER ROLES
-- When server role exists
if exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

-- When server role does not exists
if not exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

SCHEMAS
-- When schema exists
if exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

-- When schema does not exists
if not exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

Replication
-- Replication scripts are generated apart so you have to check them and consider the validations implemented on those scripts
	* Publications
	* Subscriptions on publisher
	* Subscriptions
	* Snapshots
*/