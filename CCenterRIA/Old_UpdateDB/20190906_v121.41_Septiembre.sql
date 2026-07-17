/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.38

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
SET @versionfix = 41
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 39
BEGIN
	BEGIN TRAN

	BEGIN TRY



	set @process = 'CW-3396 Aplicar listas negras relacionadas a la campaña'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaLoadCamps] @option    SMALLINT, 
	                                              @Sup       SMALLINT     = NULL, 
	                                              @TypeCamp  SMALLINT     = NULL, 
	                                              @CamId     SMALLINT     = NULL, 
	                                              @PinUpdate SMALLINT     = NULL, 
	                                              @Wg        SMALLINT     = NULL, 
	                                              @WgList    VARCHAR(256) = NULL
	AS
	     SET NOCOUNT ON;
	     DECLARE @AreaId SMALLINT;
	     SELECT @AreaId = IDArea
	     FROM ccUsers
	     WHERE User_id = @Sup;
	     IF @option = 1 -- Get Camps
	         BEGIN
	             IF @TypeCamp = 1 -- Campañas salida por Supervisor
	                 SELECT DISTINCT 
	                        rel.cam_id, 
	                        camps.cam_descripcion, 
	                        graph.graphic_id AS Frame,
	                        CASE
	                            WHEN(ISNULL(pin.Cam_Id, 0)) >= 1
	                            THEN 1
	                            ELSE 0
	                        END AS Pin, 
	                        camps.DNCScrub
	                 FROM ccSupervisorCam rel
	                      LEFT JOIN PinCampaings pin ON rel.user_id = pin.Sup_Id
	                                                    AND rel.cam_id = pin.Cam_Id
	                      LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
	                      LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
	                 WHERE rel.user_id = @Sup
	                       AND rel.tipo = 1
	                 ORDER BY camps.cam_descripcion ASC;
	             IF @TypeCamp = 2 -- Campañas entrada por Supervisor (ACDs)
	                 BEGIN
	                     SELECT CAST(inbound.Inbound_id AS INT) AS Cam_id, 
	                            inbound.descripcion AS Cam_descripcion, 
	                            graph.graphic_id AS Frame, 
	                            0
	                     FROM ccInbound inbound
	                          LEFT JOIN ccRIAinboundGraph graph ON inbound.Inbound_id = graph.Inbound_id
	                          LEFT JOIN ccSupervisorCam supCam ON inbound.Inbound_id = supCam.cam_id
	                     WHERE supCam.user_id = @Sup
	                           AND tipo = 0
	                     ORDER BY inbound.descripcion ASC;
	             END;
	     END;
	     IF @option = 2 -- update Pin campaing
	         BEGIN
	             IF @PinUpdate = 1
	                 BEGIN
	                     INSERT INTO PinCampaings
	                     (Cam_Id, 
	                      Sup_Id
	                     )
	                     VALUES
	                     (@CamId, 
	                      @Sup
	                     );
	             END;
	                 ELSE
	                 IF @PinUpdate = 0
	                     BEGIN
	                         DELETE FROM PinCampaings
	                         WHERE Cam_Id = @CamId
	                               AND Sup_Id = @Sup;
	                 END;
	     END;
	     IF @option = 3  --Get campaign info 
	         BEGIN
	             SELECT DISTINCT 
	                    rel.cam_id, 
	                    camps.cam_descripcion, 
	                    graph.graphic_id AS Frame,
	                    CASE
	                        WHEN(ISNULL(pin.Cam_Id, 0)) >= 1
	                        THEN 1
	                        ELSE 0
	                    END AS Pin, 
	                    camps.DNCScrub
	             FROM ccSupervisorCam rel
	                  LEFT JOIN PinCampaings pin ON rel.user_id = pin.Sup_Id
	                                                AND rel.cam_id = pin.Cam_Id
	                  LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
	                  LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
	             WHERE rel.user_id = @Sup
	                   AND rel.cam_id = @CamId
	                   AND rel.tipo = @TypeCamp;
	     END;
	     IF @option = 4 -- Get Campaigns by Supervisor, Wg and type
	         BEGIN
	             DECLARE @table TABLE
	             (camId    INT, 
	              campType TINYINT,
	              PRIMARY KEY(camId, campType)
	             );
	             INSERT INTO @table
	                    SELECT DISTINCT 
	                           IdCampEsp, 
	                           Tipo
	                    FROM ccRIACampEspWG wg
	                    WHERE wg.IDWG IN
	                    (
	                        SELECT IDWG
	                        FROM ccRIAWorkGroupUsers
	                        WHERE User_id = @Sup
	                              AND IDWG <> @WG
	                    );
	             SELECT CAST(B.IdCampEsp AS INT) AS Cam_id, 
	                    CAST(B.Tipo AS INT) AS Type
	             FROM @table A
	                  RIGHT JOIN
	             (
	                 SELECT wg.IdCampEsp, 
	                        wg.Tipo
	                 FROM ccRIACampEspWG wg
	                 WHERE wg.IDWG = @WG
	             ) B ON A.camId = B.IdCampEsp
	                    AND A.campType = B.Tipo
	             WHERE A.camId IS NULL
	             ORDER BY IdCampEsp;
	     END;
	     IF @option = 5 -- Get Campaigns by Supervisor, Wgs and type
	         BEGIN
	             SELECT COUNT(IdCampEsp)
	             FROM ccRIACampEspWG
	             WHERE IDWG IN
	             (
	                 SELECT Value
	                 FROM dbo.fn_RIASplitDelimited(@WgList, ''|'')
	             )
	             AND Tipo = 1
	             AND IdCampEsp = @CamId;
	     END;
	     IF @option = 6 -- Get Blacklist Ids by Campaign Id
	         BEGIN
	             DECLARE @BlackListIds VARCHAR(MAX);
	             SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
	             FROM Camplistanegra
	             WHERE cam_id = @CamId
	                   AND STATUS = 1;
	             SELECT isnull(@BlackListIds,''0'') AS BlackListIds;
	     END;'

	exec (@sql)
	
		set @process = 'CW-3371 Drop PROCEDURE ccsp_AvrsSyncronization'
		
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_AvrsSyncronization'')
			begin
				DROP PROCEDURE ccsp_AvrsSyncronization;
			end'

		exec (@sql)

		SET @process = 'CW-3371 Agregar campo DNIS a consulta de SP ccsp_AvrsSyncronization'
		SET @Sql = '
			CREATE PROCEDURE [dbo].[ccsp_AvrsSyncronization] 
			@action SMALLINT, 
			@maxRecordsToTransfer INT = 10, 
			@id INT = 0
			AS
			SET NOCOUNT ON

			IF @action = 1
			BEGIN
				DECLARE @countrId INT

				SET @countrId = 1

				SELECT @countrId = valor
				FROM ccSettings
				WHERE setting_id = 104
				

				SELECT TOP (@maxRecordsToTransfer) call.cal_id, user_id, call.Inbound_id, call.calif_id, cast(cal_extension AS INT) AS cal_extension, cal_inicio, cal_ANI AS phone, 
				cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration, cal_key, 0 AS cal_manual, cal_puerto, call.dni_id, fvalida, 
				cal_whohung, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id, 
				CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh, 
				dateadd(ss, cal_tDialog, cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, ccInbound.prefijo, 1 AS isCallRecord,isnull(dni.dni_numero,'''') as DNIS
				FROM ccCallsIn AS call
				INNER JOIN ccInbound ON ccInbound.Inbound_id = call.Inbound_id
				INNER JOIN ccAVRSTransfer avrs ON call.cal_id = avrs.cal_id AND avrs.tipo = 0
				LEFT JOIN ccDNIS dni on dni.dni_id=call.dni_id
				LEFT JOIN (
					SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
					FROM ccLogTransfers
					WHERE tipo = 1
					GROUP BY cal_id, tipo
					) trans ON call.cal_id = trans.cal_id
				
				UNION
				
				SELECT TOP (@maxRecordsToTransfer) call.cal_id AS CallId, user_id AS UserId, call.cam_id AS camAcdId, cast(call.calif_id AS SMALLINT) AS califId, cast(cal_extension AS INT) AS extension, 
				cal_inicio, cal_telefono, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration, cal_key, cal_manual, cal_puerto, 0 AS dni_id, fvalida, 
				cal_whohung, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id, 
				CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh, 
				dateadd(ss, cal_tDialog, cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, camps.prefijo, dbo.EnableCallRecord(camps.call_record, @countrId, cal_telefono) AS isCallRecord, '''' as DNIS
				FROM ccoCallsOut AS call
				INNER JOIN ccCamps camps ON camps.cam_id = call.cam_id
				INNER JOIN ccAVRSTransfer avrs ON call.cal_id = avrs.cal_id AND avrs.tipo = 1
				LEFT JOIN (
					SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
					FROM ccLogTransfers
					WHERE tipo = 2
					GROUP BY cal_id, tipo
					) trans ON call.cal_id = trans.cal_id
			END
			ELSE IF @action = 2
			BEGIN
				DELETE
				FROM ccAVRSTransfer
				WHERE id = @id
			END

		'
	exec (@sql)
	
	
	set @process = 'CW-3406 Alter PROCEDURE ccsp_RIAAgentGetDialMask'
		
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
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

				DECLARE @specialDialPlan TINYINT, @phoneType TINYINT
				SELECT @specialDialPlan = valor, @phoneType = 0
				FROM ccsettings WITH (NOLOCK)
				WHERE setting_id = 195

				if @specialDialPlan = 1 select @phoneType=dbo.fnGetCallType(@tel)

				--Restringe celulares
				if (@mask & 1)>0
				 begin
					if ((left(ltrim(rtrim(@tel)),3) = ''044'' Or left(ltrim(rtrim(@tel)),3) = ''045'') and len(ltrim(rtrim(@tel))) = 13) or (@specialDialPlan = 1 and (@phoneType=3 or @phoneType=4))
					 begin
						set @value = 4
					 end
				 end

				--Restringe larga distancia
				if(@value=0)
				 begin
					if ((@mask & 2) > 0)
					 begin
						if ((left(ltrim(rtrim(@tel)),2) = ''01'') and len(ltrim(rtrim(@tel))) = 12) or (@specialDialPlan = 1 and @phoneType=2)
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
						if (Len(@lada) + Len(ltrim(rtrim(@tel))) = 10 and @specialDialPlan = 0) or (@specialDialPlan = 1 and @phoneType=1)
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
						if ((left(ltrim(rtrim(@tel)),2) =''0'') and len(ltrim(rtrim(@tel))) = 11)
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

				end -- Termina Spain

			select @value Response'

		exec (@sql)

		set @process = 'CW-3423 Drop PROCEDURE ccsp_GalateaGetRecordsImportStatus'
		
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetRecordsImportStatus'')
			begin
				DROP PROCEDURE ccsp_GalateaGetRecordsImportStatus;
			end'

		exec (@sql)


		SET @process = 'CW-3423 Agregar SP de consulta de estado de carga'
		SET @Sql = '
					CREATE PROCEDURE [dbo].[ccsp_GalateaGetRecordsImportStatus]
		          -- @Type = 1:Detalle general de carga de registros | 2:Detalle específico de carga de registros | 3:Porcentaje de carga de registros
		          @action tinyint, 
		          @loadID int = NULL, 
		          @userID smallint = NULL

		          AS
		          SET nocount ON
		          if @action not IN (1,2,3)
		            raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)

		          if @action=1 -- Detalle general de carga de registros
		           BEGIN
		            if not exists(SELECT User_id FROM ccUsers WHERE TipoUser_id IN(2,6) AND Status>0 AND User_id=@userID)
		             BEGIN
		              raiserror(''ERROR. invalid user id'', 18, 1)
		              return(0)
		             END

		            SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded, regsNotLoaded, state, loadDate
		            FROM ccRIALoading riaLoad
		            JOIN ccSupervisorCam superCam ON riaLoad.cam_id = superCam.cam_id
					JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
		            WHERE superCam.user_id = @userID
		            AND superCam.tipo = 1
					ORDER BY riaLoad.loadDate DESC

		            return(0)
		           END

		          if @action=2 -- Detalle específico de carga de registros
		           BEGIN
		            if not exists(SELECT load_id FROM ccRIALoading)
		             BEGIN
		              raiserror(''ERROR. invalid template ID'', 18, 1)
		              return(0)
		             END

		              SELECT regsLoaded, alreadyLoaded, regsBlocked, regsNotLoaded,
		                     telsLoaded, telsBlocked, telsNotLoaded
		              FROM ccRIALoading
		              WHERE load_id  = @loadID
		           
		           END

		          if @action=3 -- Porcentaje de carga de registros
		           BEGIN
		            if not exists(SELECT load_id FROM ccRIALoading)
		             BEGIN
		              raiserror(''ERROR. invalid load ID'', 18, 1)
		              return(0)
		             END

		              SELECT state, pctg
		              FROM ccRIALoading
		              WHERE load_id  = @loadID

		           END
		          SET nocount off

		'
		exec (@sql)

	
		set @process = 'CW-3456 Drop PROCEDURE ccsp_GalateaLoadCamps'
		
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaLoadCamps'')
			begin
				DROP PROCEDURE ccsp_GalateaLoadCamps;
			end'

		exec (@sql)

		set @process = 'CW-3456 Campañas iniciadas en lista inicial'
		
		set @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaLoadCamps] @option    SMALLINT, 
                                              @Sup       SMALLINT     = NULL, 
                                              @TypeCamp  SMALLINT     = NULL, 
                                              @CamId     SMALLINT     = NULL, 
                                              @PinUpdate SMALLINT     = NULL, 
                                              @Wg        SMALLINT     = NULL, 
                                              @WgList    VARCHAR(256) = NULL
AS
     SET NOCOUNT ON;
     DECLARE @AreaId SMALLINT;
     SELECT @AreaId = IDArea
     FROM ccUsers
     WHERE User_id = @Sup;
     IF @option = 1 -- Get Camps
         BEGIN
             IF @TypeCamp = 1 -- Campañas salida por Supervisor
                 SELECT DISTINCT 
                        rel.cam_id, 
                        camps.cam_descripcion, 
                        graph.graphic_id AS Frame,
                        CASE
                            WHEN(ISNULL(pin.Cam_Id, 0)) >= 1
                            THEN 1
                            ELSE 0
                        END AS Pin, 
                        camps.DNCScrub,
						cam_procesando IsStarted
                 FROM ccSupervisorCam rel
                      LEFT JOIN PinCampaings pin ON rel.user_id = pin.Sup_Id
                                                    AND rel.cam_id = pin.Cam_Id
                      LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
                      LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                 WHERE rel.user_id = @Sup
                       AND rel.tipo = 1
                 ORDER BY camps.cam_descripcion ASC;
             IF @TypeCamp = 2 -- Campañas entrada por Supervisor (ACDs)
                 BEGIN
                     SELECT CAST(inbound.Inbound_id AS INT) AS Cam_id, 
                            inbound.descripcion AS Cam_descripcion, 
                            graph.graphic_id AS Frame, 
                            0  Pin,
							0 DNCScrub,
							CAST(0 AS BIT) IsStarted
                     FROM ccInbound inbound
                          LEFT JOIN ccRIAinboundGraph graph ON inbound.Inbound_id = graph.Inbound_id
                          LEFT JOIN ccSupervisorCam supCam ON inbound.Inbound_id = supCam.cam_id
                     WHERE supCam.user_id = @Sup
                           AND tipo = 0
                     ORDER BY inbound.descripcion ASC;
             END;
     END;
     IF @option = 2 -- update Pin campaing
         BEGIN
             IF @PinUpdate = 1
                 BEGIN
                     INSERT INTO PinCampaings
                     (Cam_Id, 
                      Sup_Id
                     )
                     VALUES
                     (@CamId, 
                      @Sup
                     );
             END;
                 ELSE
                 IF @PinUpdate = 0
                     BEGIN
                         DELETE FROM PinCampaings
                         WHERE Cam_Id = @CamId
                               AND Sup_Id = @Sup;
                 END;
     END;
     IF @option = 3  --Get campaign info 
         BEGIN
             SELECT DISTINCT 
                    rel.cam_id, 
                    camps.cam_descripcion, 
                    graph.graphic_id AS Frame,
                    CASE
                        WHEN(ISNULL(pin.Cam_Id, 0)) >= 1
                        THEN 1
                        ELSE 0
                    END AS Pin, 
                    camps.DNCScrub,
					cam_procesando IsStarted
             FROM ccSupervisorCam rel
                  LEFT JOIN PinCampaings pin ON rel.user_id = pin.Sup_Id
                                                AND rel.cam_id = pin.Cam_Id
                  LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
                  LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
             WHERE rel.user_id = @Sup
                   AND rel.cam_id = @CamId AND rel.tipo = @TypeCamp;
     END;
     IF @option = 4 -- Get Campaigns by Supervisor, Wg and type
         BEGIN
             DECLARE @table TABLE
             (camId    INT, 
              campType TINYINT,
              PRIMARY KEY(camId, campType)
             );
             INSERT INTO @table
                    SELECT DISTINCT 
                           IdCampEsp, 
                           Tipo
                    FROM ccRIACampEspWG wg
                    WHERE wg.IDWG IN
                    (
                        SELECT IDWG
                        FROM ccRIAWorkGroupUsers
                        WHERE User_id = @Sup
                              AND IDWG <> @WG
                    );
             SELECT CAST(B.IdCampEsp AS INT) AS Cam_id, 
                    CAST(B.Tipo AS INT) AS Type
             FROM @table A
                  RIGHT JOIN
             (
                 SELECT wg.IdCampEsp, 
                        wg.Tipo
                 FROM ccRIACampEspWG wg
                 WHERE wg.IDWG = @WG
             ) B ON A.camId = B.IdCampEsp
                    AND A.campType = B.Tipo
             WHERE A.camId IS NULL
             ORDER BY IdCampEsp;
     END;
     IF @option = 5 -- Get Campaigns by Supervisor, Wgs and type
         BEGIN
             SELECT COUNT(IdCampEsp)
             FROM ccRIACampEspWG
             WHERE IDWG IN
             (
                 SELECT Value
                 FROM dbo.fn_RIASplitDelimited(@WgList, ''|'')
             )
             AND Tipo = 1
             AND IdCampEsp = @CamId;
     END; 
	 IF @option = 6 -- Get Blacklist Ids by Campaign Id
	         BEGIN
	             DECLARE @BlackListIds VARCHAR(MAX);
	             SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
	             FROM Camplistanegra
	             WHERE cam_id = @CamId
	                   AND STATUS = 1;
	             SELECT isnull(@BlackListIds,''0'') AS BlackListIds;
	     END;
'

		exec (@sql)
	
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
