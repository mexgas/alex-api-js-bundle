/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Daniel Vega
		Erick Muñoz
		Victor González

		
Date: 2019/03/12
Description: 

Database: CCenterRia
Required version: 121.33

Se agrega la tarea
CW-2729-Validar_setting_para_no_tener_admin_y_agente_al_mismo_tiempo
CW-2742 Reproductor externo


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 35

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 34
BEGIN
	BEGIN TRAN
	BEGIN TRY

		SET @process = 'CW-2762 Create Table ccGalateaCustomErrorMessages'
		SET @Sql = '
			IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N''ccGalateaCustomErrorMessages'')
			BEGIN
			CREATE TABLE ccGalateaCustomErrorMessages(
				message_id varchar(50) NOT NULL PRIMARY KEY,
				message_description varchar(50) NOT NULL,
			)
			END'
		EXEC (@Sql)

				EXEC (@Sql)
		SET @process = 'CW-2758 Menus ccspGalateaMenusHandler'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccspGalateaMenusHandler'')
	    begin
	        DROP PROCEDURE ccspGalateaMenusHandler;
	    end'
		EXEC (@Sql)


			EXEC (@Sql)
		SET @process = 'CW-2758 Menus ccspGalateaMenusHandler'
		SET @Sql = 'CREATE PROCEDURE ccspGalateaMenusHandler
		@action tinyint,
		@userID int
		AS BEGIN
			IF @action = 1  -- Get GalateaMenus of an Admin
			BEGIN
				
				DECLARE @EnableCallMonitorMenus bit,
						@EnablePositionMenus bit

				SELECT @EnableCallMonitorMenus = valor FROM ccSettings WHERE setting_id = 68 
				SELECT @EnablePositionMenus = valor  FROM ccSettings WHERE setting_id = 71

				exec ccsp_RIAMenuRoles @Type=6,@User_id=@userID,@Role_id=0,@InsertMenu_id=0,@DeleteMenu_id=0,@reportRol=4,@CM=@EnableCallMonitorMenus,@AE=@EnablePositionMenus

				RETURN(0)
			END
		END'
		EXEC (@Sql)


		SET @process = 'CW-2775 ALTER SP ccsp_AgentGetEspecialidadesActivas'
		SET @Sql = '
		ALTER PROCEDURE [dbo].[ccsp_AgentGetEspecialidadesActivas]
		@userID INT,
		@current integer = 0
		as
		declare @fecha datetime
		declare @dia smallint
		declare @hora smallint
		declare @minuto smallint
		declare @value int

			SET DATEFIRST 1

			select @fecha =  getdate()
			select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)

			set @value = 0
			select @value = valor from ccSettings where setting_id = 191

			if @value = 0
				begin
				select -8  as inbound_id, ''Survey'' as name
					union
					select -1 as inbound_id, ''IVR'' as name
					union
					select inbound_id as inbound_id, descripcion as name from ccInbound where inbound_id in
					(
						select inbound_id from ccInboundHorarios where horario_id in
						(
							select horario_id  from ccHorarios
							where
							( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
							AND (
								Lunes  = @dia or
								Martes *2 = @dia or
								Miercoles*3 = @dia or
								Jueves*4 = @dia or
								Viernes*5 = @dia or
								Sabado*6 = @dia or
								domingo*7 = @dia
							)
						)
					)
					and inbound_id <> @current
					-- las activas
					and status <> 0
					-- las que tienen agentes firmados
					-- and inbound_id  in ( select distinct inbound_id from ccInboundAgentes where user_id in ( select user_id from ccPosicion where user_id > 0 ))
					order by 2
				end

			if @value = 1
				begin
					if (@current <> 0)
						begin
							select -1 as inbound_id, ''IVR'' as name
							union
							select inbound_id as inbound_id, descripcion as name from ccInbound where inbound_id in
							(
								select inbound_id from ccInboundHorarios where horario_id in
								(
									select horario_id  from ccHorarios
									where
									( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
									AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
									AND (
										Lunes  = @dia or
										Martes *2 = @dia or
										Miercoles*3 = @dia or
										Jueves*4 = @dia or
										Viernes*5 = @dia or
										Sabado*6 = @dia or
										domingo*7 = @dia
									)
								)
							)
							and inbound_id <> @current
							-- las activas
							and status <> 0
							and IDArea in (select cu.IDArea from ccUsers cu join ccInbound ci on cu.IDArea = ci.IDArea where inbound_id =  @current)
							order by 2
						end
					else
						begin
							select -1 as inbound_id, ''IVR'' as name
							union
							select inbound_id as inbound_id, descripcion as name from ccInbound where inbound_id in
							(
								select inbound_id from ccInboundHorarios where horario_id in
								(
									select horario_id  from ccHorarios
									where
									( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
									AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
									AND (
										Lunes  = @dia or
										Martes *2 = @dia or
										Miercoles*3 = @dia or
										Jueves*4 = @dia or
										Viernes*5 = @dia or
										Sabado*6 = @dia or
										domingo*7 = @dia
									)
								)
							)
							and inbound_id <> @current
							-- las activas
							and status <> 0
							and IDArea in (
							select IDArea from ccUsers where User_id = @userID
							)
							-- las que tienen agentes firmados
							-- and inbound_id  in ( select distinct inbound_id from ccInboundAgentes where user_id in ( select user_id from ccPosicion where user_id > 0 ))
							order by 2
						end
				end'
		EXEC (@Sql)

		SET @process = 'CW-2762 Set Setting for ccsp_GalateaGetCustomErrorMessages'
		SET @Sql = '
			IF NOT EXISTS(SELECT * FROM ccsettings WHERE setting_id=212)
			INSERT ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) 
			VALUES (212,0,''Mensajes de error personalizados para llamada manual'',1,''ADM'',''0:Desactivado,1:Habilitar'',''Custom messages for manual call errors. 0:Disabled,1:Enabled'',1,''^[0-1]$'')'
		EXEC (@Sql)


		SET @process = 'CW-2762 agrega operation module ccRIALog_Operation'
		SET @Sql = '
			IF NOT EXISTS(SELECT * FROM ccRIALog_Operation WHERE setting_id=212)
			INSERT ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) 
			VALUES (212,0,''Mensajes de error personalizados para llamada manual'',1,''ADM'',''0:Desactivado,1:Habilitar'',''Custom messages for manual call errors. 0:Disabled,1:Enabled'',1,''^[0-1]$'')'
		EXEC (@Sql)



		SET @process = 'CW-2762 agrega operation en ccRIALog_Operation'
		SET @Sql = '
			IF NOT EXISTS
			(
			    SELECT *
			    FROM ccRIALog_Operation
			    WHERE operationType = 177
			)
			    INSERT INTO ccRIALog_Operation
			    (operationType, 
			     descripcion
			    )
			    VALUES
			    (177, 
			     ''Re-Encrypt|Reencryptar''
			    );

			'
		EXEC (@Sql)

		SET @process = 'CW-2762 agrega operation module ccRIALog_Module'
		SET @Sql = '
			IF NOT EXISTS
			(
			    SELECT *
			    FROM ccRIALog_Module
			    WHERE module_id = 60
			)
			    INSERT INTO ccRIALog_Module
			    (module_id, 
			     descripcion
			    )
			    VALUES
			    (60, 
			     ''RE-ENCRYPTER OF RECORDINGS| REENCRIPTADOR DE GRABACIONES''
			    );
			'
		EXEC (@Sql)

		SET @process = 'CW-2762 Drop SP ccsp_GalateaGetCustomErrorMessages'
		SET @Sql = '
			IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaGetCustomErrorMessages'')
		    BEGIN
		        DROP PROCEDURE ccsp_GalateaGetCustomErrorMessages;
		    END'
		EXEC (@Sql)


		SET @process = 'CW-2762 Create ccsp_GalateaGetCustomErrorMessages'
		SET @Sql = '
			CREATE PROCEDURE [dbo].[ccsp_GalateaGetCustomErrorMessages]
			@callout_id int 
			AS
				DECLARE @disconnectCause AS VARCHAR(250)
				--VALIDA QUE EL SETTING PARA MENSAJES PERSONALIZADOS ESTÉ ACTIVO
				IF EXISTS(SELECT * FROM ccSettings WHERE setting_id = 212 and valor = 1)
				BEGIN
					--VALIDA QUE EL CALLOUT_ID EXISTA EN CCOLOGDIALS
					IF EXISTS (SELECT * FROM ccoLogDials WHERE callout_id = @callout_id) 
					BEGIN
						--SE OBTIENE EL TIPO DE USUARIO YA REGISTRADO
						SELECT @disconnectCause=disconnectCause
						FROM ccoLogDials
						WHERE callout_id = @callout_id

						WHILE PATINDEX(''%[^0-9]%'',@disconnectCause) <> 0
						BEGIN
						    --ELIMINA LAS LETRAS PARA DEJAR SOLO NÚMEROS
						    SET @disconnectCause = STUFF(@disconnectCause,PATINDEX(''%[^0-9]%'',@disconnectCause),1,'''')
						END

						--VALIDA QUE EXISTA UN MENSAJE DE ERROR PARA EL CÓDIGO
						IF EXISTS (SELECT message_description FROM ccGalateaCustomErrorMessages WHERE message_id = @disconnectCause)
						BEGIN
							--REGRESA MENSAJE ASOCIADO AL CÓDIGO DE ERROR
							SELECT message_description
							FROM ccGalateaCustomErrorMessages
							WHERE message_id = @disconnectCause
						END
						ELSE
						BEGIN
							--REGRESA MENSAJE POR DEFAULT SI NO SE ENCUENTRA UNO ASOCIADO AL CÓDIGO DE ERROR
							SELECT message_description
							FROM ccGalateaCustomErrorMessages
							WHERE message_id = ''DEFAULT''
						END
					END
					ELSE
					BEGIN
						--REGRESA MENSAJE POR DEFAULT SI NO SE ENCUENTRA EN CCOLOGDIALS EL CALLOUT_ID
						SELECT message_description
						FROM ccGalateaCustomErrorMessages
						WHERE message_id = ''DEFAULT''
					END
				END
				ELSE
				BEGIN
					--REGRESA UN MENSAJE PREDETERMINADO PARA INFORMAR QUE EL SETTING ESTÁ DESHABILITADO
					SELECT ''SETTING_DISABLED'' ''message_description''
				END'
		EXEC (@Sql)

		-- *********************** END  121.03-3_201900307 *********************** ---


				/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix
		
		
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
