/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author: Jesus Gallardo
Date: 2014/10/06
Description:
	Se crear tabla SeriesCR para plan marcacion Costa Rica
	Se inserta series  tabla SeriesCR para plan marcacion Costa Rica
	Se inserta cstoTipoLlamada para plan marcacion Costa Rica
	Se inserta pais ccRIACat_Country para plan marcacion Costa Rica
	Se actualiza setting para opcion de pais para plan marcacion Costa Rica
	
	Se modifica la funcion Completa para plan marcacion Costa Rica
	Se modifica la funcion Completa_ListaNegra para plan marcacion Costa Rica
	Se modifica la funcion fnGetTipoLlamada para plan marcacion Costa Rica
	Se modifica la funcion fnGetTimeZone para plan marcacion Costa Rica
	Se modifica la funcion Verifica para plan marcacion Costa Rica
	Se modifica la funcion TelAni para plan marcacion Costa Rica

	Se modifica el SP ccsp_RIAccSettingsConfig para validar los paises validos plan marcacion Costa Rica
	Se modifica el SP ccsp_Limpia para plan marcacion Costa Rica
	Se modifica el SP ccsp_RIAAgentGetDialMask para plan marcacion Costa Rica
	Se modifica el SP ccspADM_AniListLD para plan marcacion Costa Rica
	

	Se agrega indice a ccoCallsOutSource
	Se agrega indice a ccoWorkingTable	
	Se agrega setting para grabacion en el engine vox o wav
	Se quita constrain para ccRIA_vmMessages para depurar tabla 
	Se agrega delete cascade ccRIA_vmMessages para ccCallsIn 
	
	Se Modifica el SP ccsp_RIAOUTInsertNewJOBS_WT_Camp
	Se Modifica el SP ccsp_DLRSaveDialResult para call_key en las integreaciones llamada manual
	Se Modifica el SP ccsp_RIA_ABCAgents para editar el nombre del usuario
	
	Se Borra el Job TrucateTransactionLog
	Se Borra el Job ShrinkLogCCReportsRia
	Se Borra el Job ShrinkLogCCenterRia
	Se Borra el Job Shrink-IndexOptimizationRIA
	Se Borra el Job Shrink-IndexOptimization
	Se Borra el Job CW Clear logs	
	Se Borra el job CWSpecialReadyToDial
	
	Se modifica parametro de la publicacion  generation_leveling_threshold y actuliza migration migration datStart y dateEnd	
	
	Se Modifica el Job CW Delete old records
	Se modifica el job DatabaseCentinella

Database: CCenterRia
Required version: 112

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 113

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

			/* Start script release */
			set @process = 'Create table - SeriesCR'
			set @sql=' if not exists (select * from sys.tables where name = N''SeriesCR'')
				create table SeriesCR(
					zonaGeografica varchar (50),
					indicativoDestino varchar(3),
					rangoInicio varchar(8),
					rangoFinal varchar(8))'	
			EXEC(@sql)

			set @process = 'CREATE INDEX IX_ccoCallsOutSource_15 - ccoCallsOutSource'
			set @sql='if not exists (select * from sys.indexes where name = N''IX_ccoCallsOutSource_15'' and object_id = OBJECT_ID(N''ccoCallsOutSource''))
				CREATE NONCLUSTERED INDEX [IX_ccoCallsOutSource_15] ON [dbo].[ccoCallsOutSource] (
					[cal_key] ASC,
					[cam_id] ASC,
					[cal_status] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'	
			EXEC(@sql)
	
			set @process = 'CREATE INDEX IX_ccoCallsOutSource_16 - ccoCallsOutSource'
			set @sql='if not exists (select * from sys.indexes where name = N''IX_ccoCallsOutSource_16'' and object_id = OBJECT_ID(N''ccoCallsOutSource''))
				CREATE NONCLUSTERED INDEX [IX_ccoCallsOutSource_16] ON [dbo].[ccoCallsOutSource] (
					[callout_id] ASC,
					[cam_id] ASC,
					[cal_status] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'	
			EXEC(@sql)
	
			set @process = 'CREATE INDEX IX_ccoWorkingTable_15 - ccoWorkingTable'
			set @sql='if not exists (select * from sys.indexes where name = N''IX_ccoWorkingTable_15'' and object_id = OBJECT_ID(N''ccoWorkingTable''))
				CREATE NONCLUSTERED INDEX [IX_ccoWorkingTable_15] ON [dbo].[ccoWorkingTable] (
					[cal_keyw] ASC,
					[cam_id] ASC,
					[cal_status] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'	
			EXEC(@sql)	
	
			set @process = 'CREATE INDEX IX_ccoCallsOutSource_17 - ccoCallsOutSource'
			set @sql='if not exists (select * from sys.indexes where name = N''IX_ccoCallsOutSource_17'' and object_id = OBJECT_ID(N''ccoCallsOutSource''))
				CREATE NONCLUSTERED INDEX [IX_ccoCallsOutSource_17]
				ON [dbo].[ccoCallsOutSource] ([cam_id],[cal_status])
				INCLUDE ([callout_id],[cal_Key],[cal_telefono],[cal_telefono2],[cal_telefono3],[cal_telefono4],[cal_telefono5],[cal_fechaDial],[iZonaHoraria],[iZonaHoraria_verano],[iZonaHoraria2],[iZonaHoraria_verano2],[iZonaHoraria3],[iZonaHoraria_verano3],[iZonaHoraria4],[iZonaHoraria_verano4],[iZonaHoraria5],[iZonaHoraria_verano5],[list_id])'		
			EXEC(@sql)
	
			set @process = 'CREATE INDEX IX_ccoCallsOutSource_18 - ccoCallsOutSource'
			set @sql='if not exists (select * from sys.indexes where name = N''IX_ccoCallsOutSource_18'' and object_id = OBJECT_ID(N''ccoCallsOutSource''))
				CREATE NONCLUSTERED INDEX [IX_ccoCallsOutSource_18]
				ON [dbo].[ccoCallsOutSource] ([cam_id],[cal_status])
				INCLUDE ([callout_id],[cal_Key],[cal_telefono],[cal_telefono2],[cal_telefono3],[cal_telefono4],[cal_telefono5],[user_id],[cal_fechaDial])'	
			EXEC(@sql)	
	
			set @process = 'Insert - setting'
			set @sql='if exists (select * from sys.tables where name = N''ccsettings'')
				insert into ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings) 
				values (165,''0'',''Formato de archivo de grabaciones'', 1,''X'',''0:vox 1:wav si el setting 124 esta habilitado siempre grabara en formato wav'',''Recordings file format'',0)'	
			EXEC(@sql)
	
			set @process = 'Drop CONSTRAINT FK_ccRIA_vmMessages_ccCallsIn - ccRIA_vmMessages'
			set @sql='IF EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N''[dbo].[FK_ccRIA_vmMessages_ccCallsIn]'') AND parent_object_id = OBJECT_ID(N''[dbo].[ccRIA_vmMessages]''))
				ALTER TABLE [dbo].[ccRIA_vmMessages] DROP CONSTRAINT [FK_ccRIA_vmMessages_ccCallsIn]'	
			EXEC(@sql)
	
			set @process = 'ALTER CONSTRAINT DELETE CASCADE - ccRIA_vmMessages'
			set @sql='IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N''[dbo].[FK_ccRIA_vmMessages_ccCallsIn]'') AND parent_object_id = OBJECT_ID(N''[dbo].[ccRIA_vmMessages]''))
				ALTER TABLE [dbo].[ccRIA_vmMessages]  WITH CHECK ADD  CONSTRAINT [FK_ccRIA_vmMessages_ccCallsIn] FOREIGN KEY([cal_id])
				REFERENCES [dbo].[ccCallsIn] ([cal_id]) ON DELETE CASCADE'	
			EXEC(@sql)
	
			set @process = 'ALTER TABLE CONSTRAINT - ccRIA_vmMessages'
			set @sql='IF EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N''[dbo].[FK_ccRIA_vmMessages_ccCallsIn]'') AND parent_object_id = OBJECT_ID(N''[dbo].[ccRIA_vmMessages]''))
				ALTER TABLE [dbo].[ccRIA_vmMessages] CHECK CONSTRAINT [FK_ccRIA_vmMessages_ccCallsIn]'	
			EXEC(@sql)

			set @process = 'Insert - SeriesCR'
			set @sql='if exists (select * from sys.tables where name = N''SeriesCR'')
				begin
					insert into SeriesCR (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Local'',2,''0000000'',''9999999'')
					insert into SeriesCR (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Local'',3,''0000000'',''9999999'')
					insert into SeriesCR (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Telefonia SIP'',4,''0000000'',''9999999'')
					insert into SeriesCR (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Telefonia Movil'',5,''0000000'',''9999999'')
					insert into SeriesCR (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Telefonia Movil'',6,''0000000'',''9999999'')
					insert into SeriesCR (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Telefonia Movil'',7,''0000000'',''9999999'')
					insert into SeriesCR (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Telefonia Movil'',8,''0000000'',''9999999'')
					insert into SeriesCR (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Cobro Revertido'',800,''0000000'',''9999999'')	
					insert into SeriesCR (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Tarifa Prima'',905,''0000000'',''9999999'')
					insert into SeriesCR (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Acesso Internet'',900,''0000000'',''9999999'')
				end'		
			EXEC(@sql)

			set @process = 'Insert -- cstoTipoLlamada'
			set @sql='if exists (select * from sys.tables where name = N''cstoTipoLlamada'')
				begin
					insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (12,1,''Local'',8,''2%|3%'')
					insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (12,2,''Telefonia SIP'',8,''4%'')
					insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (12,3,''Telefonia Movil'',8,''5%|6%|7%|8%'')
					insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (12,4,''LD Internacional'',0,''00%'')
					insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (12,5,''Cobro Revertido'',10,''800%'')
					insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (12,6,''Tarifa Prima'',10,''90%'')
					insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (12,7,''Acesso Internet'',10,''900%'')
					insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (12,8,''Especial'',0,''08%'')
				end'	
			EXEC(@sql)

			set @process = 'Insert - ccRIACat_Country'
			set @sql='if exists (select * from sys.tables where name = N''ccRIACat_Country'')
				insert into ccRIACat_Country  values (''Costa Rica'', 506, 8, 8)'	
			EXEC(@sql)

	
			set @process = 'Update - ccsettings pais'
			set @sql='if exists (select * from sys.tables where name = N''ccsettings'')
				update ccsettings 
				set detalle = ''1:Mexico, 2:Argentina, 3:Colombia, 4:USA, 5:Chile, 6: Venezuela, 7: Reino Unido, 8: Arabia saudita, 9: Australia, 10:Brasil, 11:Guatemala 12:Costa Rica'', bLoadSettings = ''1'' 
				where setting_id = 104'	
			EXEC(@sql)

			set @process = 'Alter function - Completa'
			if exists (select * from sys.objects where object_id = OBJECT_ID(N'Completa') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
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

					--Completa 1:México 2:Argentina 3:Colombia 4:USA 5:Chile 6: venezuela 7: UK 8: arabia saudita 9: Australia 10:Brasil 11:Guatemala
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

					-- Termina
					return @resultado

					end'	
			else
				set @sql = ''
			EXEC(@sql)

			set @process = 'Alter function - Completa_ListaNegra'
			if exists (select * from sys.objects where object_id = OBJECT_ID(N'Completa_ListaNegra') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
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

					end
					else begin
					 select @resultado = dbo.Limpia(@cadena)
					end 

					return @resultado
					end'	
			else
				set @sql = ''
			EXEC(@sql)

			set @process = 'Alter function - fnGetTipoLlamada'
			if exists (select * from sys.objects where object_id = OBJECT_ID(N'fnGetTipoLlamada') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
				set @sql='ALTER function [dbo].[fnGetTipoLlamada]( @tel varchar(20) )
					returns int
					as
					 begin
						declare @len integer, @tipo integer, @country varchar(5)
						declare @tipoLlamada_id smallint
						declare @longitud tinyint
						declare @prefijo varchar(15)

						declare @table table(
						id int not null,
						prefijo nvarchar(100) not null
						)

						select @country = valor from ccsettings where setting_id = 104
						set @len = len( @tel )
						set @tipo = 0

						if @country <> 11 and @country <> 12
							begin
								select @tipo= tipoLlamada_id from cstoTipoLlamada with(index(IX_cstoTipoLlamada)) 
								where country_id = @country and (@len = longitud or longitud =0 )and @tel like prefijo 
								order by len(prefijo) asc -- para agarrar el ultimo ( el mas especifico), si se devuelven varias lineas
							end
						else if @country = 11
							begin
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
						else if @country = 12
							begin
								declare @prefijosCR table(
								tipoLlamada_id smallint not null,
								longitud tinyint not null,
								prefijo varchar(15) not null,
								[status] bit not null
								)

								insert into @prefijosCR
								select tipoLlamada_id, longitud, prefijo, 0
								from cstoTipoLlamada 
								where country_id = 12

								while (select count(*) from @prefijosCR where [status] = 0) > 0
								begin
									select top 1 @tipoLlamada_id = tipoLlamada_id, @longitud = longitud, @prefijo = prefijo
									from @prefijosCR
									where [status] = 0

									insert into @table
									select * from fn_RIASplitDelimited(@prefijo,''|'')

									if @len = @longitud
										begin
											if (select count(*)	from @table	where @tel like prefijo) = 1
												set @tipo = @tipoLlamada_id
										end
									else if @longitud = 0
										begin
											if (select count(*)	from @table	where @tel like prefijo) = 1
												set @tipo = @tipoLlamada_id
										end

									if @tipo <> 0
										update @prefijosCR
										set [status] = 1
									else
										begin
											update @prefijosCR
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

			set @process = 'Alter function - fnGetTimeZone'
			if exists (select * from sys.objects where object_id = OBJECT_ID(N'fnGetTimeZone') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
				set @sql='ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
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

						return isNull(@timeZone,0)
					 END'	
			else
				set @sql = ''
			EXEC(@sql)

			set @process = 'Alter function - Verifica'
			if exists (select * from sys.objects where object_id = OBJECT_ID(N'Verifica') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
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

						return @tel
					 end'	
			else
				set @sql = ''
			EXEC(@sql)

			set @process = 'Alter Function - TelAni'
			if exists (select * from sys.objects where object_id = OBJECT_ID(N'TelAni') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
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

						return @ret
					END'	
			else
				set @sql = ''
			EXEC(@sql)

			set @process = 'Alter SP - ccsp_RIAccSettingsConfig'
			if exists (select * from sys.procedures where name = N'ccsp_RIAccSettingsConfig')
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
						Select setting_id, case @idioma when 0 then descripcion else [description] end descripcion, valor, tipo
						from ccSettings WITH(NOLOCK, index(PK_ccSettings)) where tipo in (''AGT'',''ADM'',''GRL'',''REP'') 
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
						else if @setting_id = 104 and @value not in(''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'',''10'',''11'',''12'') begin
							set @value = 1
						end
						update ccSettings set valor=@value where setting_id = @setting_id
						return(0)
					 end

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


					set nocount off'
			else
				set @sql = ''	
			EXEC(@sql)

			set @process = 'Alter SP - ccsp_RIAAgentGetDialMask'
			if exists (select * from sys.procedures where name = N'ccsp_RIAAgentGetDialMask')
				set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
					@user_id integer,
					@tel varchar(15)
					AS
					declare @mask integer, @idioma integer, @value integer, @lada integer
					declare @country as tinyint

					set @value = 0
					select @mask = isnull(dialmask,7) from ccusers where user_id=@user_id
					select @country = valor from ccsettings where setting_id = 104

					-- Restricciones por pais 1:Mexico 2:Argentina 3:Colombia 4:USA 5:Chile 6:Venezuela 7:uk 8:Arabia Saudita, 9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica
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

					select @value'	
			else
				set @sql = ''
			EXEC(@sql)
	
			set @process = 'Alter SP - ccspADM_AniListLD'
			if exists (select * from sys.procedures where name = N'ccspADM_AniListLD')
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
			else
				set @sql = ''
			EXEC(@sql)	

			set @process = 'ALTER procedure - ccsp_RIAOUTInsertNewJOBS_WT_Camp'
			if exists (select * from sys.procedures where name = N'ccsp_RIAOUTInsertNewJOBS_WT_Camp')
				set @sql='ALTER procedure [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp]
					@camp_id as int,
					@reciclar as int = 1
					as
					set nocount on

					declare @prioridad varchar(8)

					select @prioridad = isnull(Prioridad,''12345NNN'') from ccCampsPrioridadTel with(nolock) where cam_id = @camp_id

					Delete ccUploadTemporal with(rowlock)
					where cam_id = @camp_id

					create table #calloutIdSource(
						callout_id int not null primary key
					)

					create table #calloutIdSource2(
						callout_id int not null primary key
					)

					create table #calloutIdSource3(
						callout_id int not null primary key
					)

					insert into #calloutIdSource
					select cs.callout_id
					from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_15),nolock),
					ccoWorkingTable wt with(index(IX_ccoWorkingTable_15),nolock)
					where cs.cal_key = wt.cal_keyw
					and cs.cam_id = wt.cam_id
					and cs.cam_id = @camp_id
					and cs.cal_status in(0,7)
					and wt.cal_status <= 2

					insert into #calloutIdSource2
					select Cout.callout_id
					from ccoCallsOutSource Cout with(index(IX_ccoCallsOutSource_16),nolock), 
					ccoworkingtable Wtab (nolock)
					WHERE Cout.callout_id = Wtab.callout_id   
					and Cout.cam_id = @camp_id 
					and (COUT.cal_status < 2 or COUT.cal_status = 7)

					insert into #calloutIdSource3
					select callout_id
					from ccoCallsOutSource with(index(IX_ccoCallsOutSource_11),nolock)
					WHERE cal_status in (0, 1, 7) 
					and cam_id = @camp_id

					if (select count(*) from #calloutIdSource) > 0
					begin
						update ccoCallBacks 
						set [status] = 6, schedulerStatus = 1
						from ccoCallBacks cb with(index(IX_ccoCallBacks6),nolock), #calloutIdSource cis with(nolock)
						where cb.callout_id = cis.callout_id

						update ccoCallsOutSource
						set cal_Status = 4 
						from ccoCallsOutSource cs with(nolock), #calloutIdSource cis with(nolock)
						where cs.callout_id = cis.callout_id
					end

					if (select count(*) from #calloutIdSource2) > 0
					begin
						update ccoCallBacks
						set [status] = 6, schedulerStatus = 1
						from ccoCallBacks cb with(index(IX_ccoCallBacks6),nolock), #calloutIdSource2 csi2 with(nolock)
						where cb.callout_id = csi2.callout_id

						update ccoCallsOutSource
						set cal_Status = 4 
						from ccoCallsOutSource Cout with(nolock), #calloutIdSource2 csi2 with(nolock)
						WHERE Cout.callout_id = csi2.callout_id
					end

					begin transaction insertccoWorkingTable

					Insert ccoWorkingTable with(TABLOCKX)
					(callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2,
						iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
					SELECT callout_id, cam_id, 
					rtrim(left(ltrim(cal_telefono + ''        ''
							 + cal_telefono2 + ''         ''
							 + cal_telefono3 + ''         ''
							 + cal_telefono4 + ''         ''
							 + cal_telefono5 + ''         ''),13)) as cal_telefono,
					case cal_status when 7 then 1 else cal_status end cal_status, cal_fechaDial, cal_key, 
					case when len( cal_telefono ) > 0 then iZonaHoraria else null end iZonaHoraria, case when len( cal_telefono ) > 0 then iZonaHoraria_verano else null end iZonaHoraria_verano, 
					case when len( cal_telefono2 ) > 0 then iZonaHoraria2 else null end iZonaHoraria2, case when len( cal_telefono2 ) > 0 then iZonaHoraria_verano2 else null end iZonaHoraria_verano2, 
					case when len( cal_telefono3 ) > 0 then iZonaHoraria3 else null end iZonaHoraria3, case when len( cal_telefono3 ) > 0 then iZonaHoraria_verano3 else null end iZonaHoraria_verano3, 
					case when len( cal_telefono4 ) > 0 then iZonaHoraria4 else null end iZonaHoraria4, case when len( cal_telefono4 ) > 0 then iZonaHoraria_verano4 else null end iZonaHoraria_verano4, 
					case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end iZonaHoraria5, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end iZonaHoraria_verano5,
					list_id
					FROM ccoCallsOutSource with(index(IX_ccoCallsOutSource_17),nolock)
					WHERE cam_id = @camp_id 
					and (cal_status < 2 or cal_status = 7) -- Nuevos Jobs

					commit transaction insertccoWorkingTable

					begin transaction insertccoCallBacks

					Insert into ccoCallBacks with(TABLOCKX)
					(callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus) 
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
							 + cal_telefono5 + ''         ''),13)) as cal_telefono2,cal_fechaDial,cal_fechaDial cal_fusercallback,NULL cal_fcallback,0 status,1 schedulerStatus
					FROM ccoCallsOutSource with(index(IX_ccoCallsOutSource_18),nolock)
					WHERE cam_id = @camp_id 
					and (cal_status < 2 or cal_status = 7) -- Nuevos Jobs

					commit transaction insertccoCallBacks

					begin transaction updateccoCallsOutSource

					UPDATE ccoCallsOutSource
					SET cal_status = 2, dial_tels = @prioridad, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
					from ccoCallsOutSource co with(nolock), #calloutIdSource3 cis3 with(nolock)
					where co.callout_id = cis3.callout_id

					commit transaction updateccoCallsOutSource

					drop table #calloutIdSource
					drop table #calloutIdSource2
					drop table #calloutIdSource3

					set nocount off'	
			else
				set @sql = ''
			EXEC(@sql)
	
			set @process = 'Alter SP - ccsp_DLRSaveDialResult'
			if exists (select * from sys.procedures where name = N'ccsp_DLRSaveDialResult')
				set @sql='ALTER procedure [dbo].[ccsp_DLRSaveDialResult]
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
					@disconnectCause varchar(250) = '''',
					@cal_key varchar(20) = ''''
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
						INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key)
						select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''0000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key
					END
					ELSE
					BEGIN
						INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key)
						select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''0000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key
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

						if @cal_key ='''' begin
							select @cal_key=cal_key from ccoCallsOutSource with(nolock) where @callout_id=callout_id
							update ccologdials with(rowlock) set cal_key=@cal_key where logDial_id=@logDial_id
						end

					end

					-- inserta informacion para reportes de workgroup
					insert ccRIAWorkGroup_logDial_id (IDWG, logDial_id, cam_id, timestamp)
					select IDWG, @logDial_id, IdCampEsp, getdate() 
					from ccRIACampEspWG where tipo = 1 and IdCampEsp = @cam_id

					-- Guarda configuracion de TipoDialingMode
					update ccoLogDials set TipoDialingMode = dbo.fn_getDialingMode(@call_id, 0, @logDial_id, @cam_id) where logDial_id=@logDial_id
					set nocount off'	
			else
				set @sql = ''
			EXEC(@sql)
	
			set @process = 'Alter SP - ccsp_RIA_ABCAgents'
			if exists (select * from sys.procedures where name = N'ccsp_RIA_ABCAgents')
				set @sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
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
			else
				set @sql = ''
			EXEC(@sql)
	
			set @process = 'Change Publication - generation_leveling_threshold'
			set @sql='
			if exists (select * from sysobjects where name=''sysmergepublications'' and type=''U'')  
				begin
					declare @i int, @count int
					declare @sql nvarchar(max),@name sysname
					CREATE TABLE #publicaction (id int,name sysname)

					INSERT INTO #publicaction (id,name)
					select ROW_NUMBER() OVER(ORDER BY name) AS Row,name from sysmergepublications where generation_leveling_threshold>0 and publisher_db=''CCenterRia''

					select @i=1,@count=count(*) from #publicaction

					while @i<=@count begin 
						select @name=name from #publicaction where id=@i
						set @sql=''exec sp_changemergepublication @publication = ''''''+ @name + '''''', @property = ''''generation_leveling_threshold'''', @value = 0''
						set @i=@i+1

						update migration set dateStart=''19000101'',dateEnd=''19000101'' where description=@name
						update migrationAVRS set dateStart=''19000101'',dateEnd=''19000101'' where description=@name
						exec(@sql)
					end

					drop table #publicaction
				end'	
			EXEC(@sql)
		
			set @process = 'Delete Job - TrucateTransactionLog'
			set @sql='USE [msdb]	
				/****** Object:  Job [TrucateTransactionLog]    Script Date: 10/20/2014 22:38:46 ******/
				IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''TrucateTransactionLog'')
					EXEC msdb.dbo.sp_delete_job @job_name=N''TrucateTransactionLog'', @delete_unused_schedule=1'	
			EXEC(@sql)
	
			set @process = 'Delete Job - ShrinkLogCCReportsRia'
			set @sql='USE [msdb]	
				/****** Object:  Job [ShrinkLogCCReportsRia]    Script Date: 10/20/2014 22:44:25 ******/
				IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''ShrinkLogCCReportsRia'')
					EXEC msdb.dbo.sp_delete_job @job_name=N''ShrinkLogCCReportsRia'', @delete_unused_schedule=1'	
			EXEC(@sql)
			
			set @process = 'Delete Job - ShrinkLogCCenterRia'
			set @sql='USE [msdb]	
				/****** Object:  Job [ShrinkLogCCenterRia]    Script Date: 10/20/2014 22:45:51 ******/
				IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''ShrinkLogCCenterRia'')
					EXEC msdb.dbo.sp_delete_job @job_name=N''ShrinkLogCCenterRia'', @delete_unused_schedule=1'	
			EXEC(@sql)
	
			set @process = 'Delete Job - Shrink-IndexOptimizationRIA'
			set @sql='USE [msdb]	
				/****** Object:  Job [Shrink-IndexOptimizationRIA]    Script Date: 10/20/2014 22:52:05 ******/
				IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''Shrink-IndexOptimizationRIA'')
					EXEC msdb.dbo.sp_delete_job @job_name=N''Shrink-IndexOptimizationRIA'', @delete_unused_schedule=1'	
			EXEC(@sql)
	
			set @process = 'Delete Job - Shrink-IndexOptimization'
			set @sql='USE [msdb]	
				/****** Object:  Job [Shrink-IndexOptimization]    Script Date: 10/20/2014 22:56:14 ******/
				IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''Shrink-IndexOptimization'')
					EXEC msdb.dbo.sp_delete_job @job_name=N''Shrink-IndexOptimization'', @delete_unused_schedule=1'	
			EXEC(@sql)
	
			set @process = 'Delete Job - CW Clear logs'
			set @sql='USE [msdb]	
				/****** Object:  Job [CW Clear logs]    Script Date: 10/20/2014 23:25:39 ******/
				IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''CW Clear logs'')
					EXEC msdb.dbo.sp_delete_job @job_name=N''CW Clear logs'', @delete_unused_schedule=1'	
			EXEC(@sql)

			set @process = 'Delete job - CWSpecialReadyToDial'
			set @sql='USE [msdb]	
				/****** Object:  Job [CW Clear logs]    Script Date: 10/20/2014 23:25:39 ******/
				IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''CWSpecialReadyToDial'')
					EXEC msdb.dbo.sp_delete_job @job_name=N''CWSpecialReadyToDial'', @delete_unused_schedule=1'	
			EXEC(@sql)
	
			set @process = 'Alter Job - CW Delete old records'
			set @sql='USE [msdb]	

				/****** Object:  Job [CW Delete old records]    Script Date: 10/20/2014 23:22:28 ******/
				IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''CW Delete old records'')
					EXEC msdb.dbo.sp_delete_job @job_name=N''CW Delete old records'', @delete_unused_schedule=1	
				
				/****** Object:  Job [CW Delete old records]    Script Date: 10/20/2014 23:23:45 ******/
				BEGIN TRANSACTION
				DECLARE @ReturnCode INT
				SELECT @ReturnCode = 0
				/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 10/20/2014 23:23:45 ******/
				IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
				BEGIN
				EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

				END

				DECLARE @jobId BINARY(16)
				EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Delete old records'', 
						@enabled=1, 
						@notify_level_eventlog=2, 
						@notify_level_email=0, 
						@notify_level_netsend=0, 
						@notify_level_page=0, 
						@delete_level=0, 
						@description=N''No description available.'', 
						@category_name=N''[Uncategorized (Local)]'', 
						@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				/****** Object:  Step [Run sp]    Script Date: 10/20/2014 23:23:46 ******/
				EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'', 
						@step_id=1, 
						@cmdexec_success_code=0, 
						@on_success_action=1, 
						@on_success_step_id=0, 
						@on_fail_action=2, 
						@on_fail_step_id=0, 
						@retry_attempts=0, 
						@retry_interval=1, 
						@os_run_priority=0, @subsystem=N''TSQL'', 
						@command=N''DECLARE @meses int
				set @meses = 3

				truncate table cclogInfo
				truncate table ccBorrardasReciclaje
				truncate table ccUploadTemporal
				truncate table ccLogCampsAgentesDia 

				delete from cchistoriallistanegra where fecha < dateadd(mm, -@meses, getdate())
				delete from ccRIAlog where operationDate < dateadd(mm, -@meses, getdate())
				delete from ccRiaChat_log where fecha_chat < dateadd(mm, -@meses, getdate())

				delete xxclientehistorial where fechaAct < dateadd(mm, -@meses, getdate())
				delete ccRIAWorkGroup_logDial_id where timestamp < dateadd(dd, -15, getdate())
				delete ccRIAWorkGroup_Calid where timestamp < dateadd(dd, -15, getdate())
				delete ccRIALogAgentesNotReady where fecha < dateadd(dd, -15, getdate())
				delete ccRIAcallbacks where año < datepart(yy,getdate())
				delete ccRIAcallbacks where mes < datepart(mm,getdate())

				delete from ccLogAgentesDia where fecha < dateadd(mm, -@meses, getdate())
				delete from ccLogAgentesNotReady where fecha < dateadd(mm, -@meses, getdate())
				delete from ccLogLogin where fecha < dateadd(mm, -@meses, getdate())
				delete from ccoLogDials where fecha < dateadd(mm, -@meses, getdate())
				delete from ccoCallsOut where cal_inicio < dateadd(mm, -@meses, getdate())
				delete from ccoWorkingTable where cal_fechadial < dateadd(mm, -@meses, getdate())
				delete from ccoCallsOutSource where cal_fechadial < dateadd(mm, -@meses-1, getdate())

				delete from ccPosicionEspecialidad where Fecha < dateadd(dd, -15, getdate())
				delete from ccPosicionCamps where Fecha < dateadd(dd, -15, getdate())

				delete from ccocallbacks where cal_fecha < dateadd(dd, -15, getdate())
				delete from ccLogReciclaje where fecha < dateadd(dd, -15, getdate())

				delete from cccallsreject where cal_inicio < dateadd(mm, -@meses-1, getdate())
				delete from ccLogtransfers where fechaFin < dateadd(mm, -@meses-1, getdate())
				delete from ccCallsIn where cal_Inicio < dateadd(mm, -@meses-1, getdate())
				delete from ccriachats where chatDate < dateadd(mm, -@meses-1, getdate())
				delete from ivrcallsin where date < dateadd(mm, -@meses-1, getdate())
				delete from ivroptions where date < dateadd(mm, -@meses-1, getdate())
				delete from ccLogAgentesDia_Dialog where fecha_Dialog < dateadd(mm, -@meses-1, getdate())'', 
						@database_name=N''CCenterRia'', 
						@flags=4
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Tuesday, Thursday and Saturday at 3:00 am'', 
						@enabled=1, 
						@freq_type=8, 
						@freq_interval=84, 
						@freq_subday_type=1, 
						@freq_subday_interval=0, 
						@freq_relative_interval=0, 
						@freq_recurrence_factor=1, 
						@active_start_date=20041022, 
						@active_end_date=99991231, 
						@active_start_time=30000, 
						@active_end_time=235959
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				COMMIT TRANSACTION
				GOTO EndSave
				QuitWithRollback:
				    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
				EndSave:'				
			EXEC(@sql)				
	
			set @process = 'Alter job -- DatabaseCentinella'
			set @sql='USE [master]

				if exists (select * from sys.tables where name = ''indexMaintenance'')
					DROP TABLE [dbo].[indexMaintenance]    

				if exists (select * from sys.tables where name = ''logCentinella'')
					DROP TABLE [dbo].[logCentinella]    

				if exists (select * from sys.tables where name = ''userDatabases'')
					DROP TABLE [dbo].[userDatabases]

				USE [msdb]

				if exists (select * from msdb.dbo.sysjobs_view where name = N''DatabaseCentinella'')
				EXEC msdb.dbo.sp_delete_job @job_name=N''DatabaseCentinella'', @delete_unused_schedule=1

				USE [msdb]

				/****** Object:  Job [DatabaseCentinella]    Script Date: 15/10/2014 09:25:39 PM ******/
				BEGIN TRANSACTION
				DECLARE @ReturnCode INT
				SELECT @ReturnCode = 0
				/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 15/10/2014 09:25:39 PM ******/
				IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
				BEGIN
				EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

				END

				DECLARE @jobId BINARY(16)
				EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''DatabaseCentinella'', 
						@enabled=1, 
						@notify_level_eventlog=0, 
						@notify_level_email=0, 
						@notify_level_netsend=0, 
						@notify_level_page=0, 
						@delete_level=0, 
						@description=N''Autor: Raymundo Gonzalez
				Fecha: 2014/10/15
				Descripcion:
					Centinela para monitoreo de performance y mantenimiento de las BD de SQL
				'', 
						@category_name=N''[Uncategorized (Local)]'', 
						@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				/****** Object:  Step [DatabaseCentinellaTasks]    Script Date: 15/10/2014 09:25:40 PM ******/
				EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''DatabaseCentinellaTasks'', 
						@step_id=1, 
						@cmdexec_success_code=0, 
						@on_success_action=1, 
						@on_success_step_id=0, 
						@on_fail_action=2, 
						@on_fail_step_id=0, 
						@retry_attempts=0, 
						@retry_interval=0, 
						@os_run_priority=0, @subsystem=N''TSQL'', 
						@command=N''use [master]

				set nocount on

				declare @idDb int
				declare @dbName nvarchar(100)
				declare @dbLog nvarchar(100)
				declare @sql nvarchar(max)
				declare @idIndex int
				declare @tableName nvarchar(100)
				declare @indexName nvarchar(100)
				declare @process int
				declare @firstSunday datetime
				declare @idCmdSql int
				declare @cmdSql nvarchar(max)
				declare @maxTimeSeconds int
				declare @maxTimeSecondsSunday int
				declare @dateExecution datetime

				set @idDb = 0
				set @dbName = ''''''''
				set @dbLog = ''''''''
				set @sql = ''''''''
				set @idIndex = 0
				set @tableName = ''''''''
				set @indexName = ''''''''
				set @process = 1
				set @firstSunday = DATEADD(WEEKDAY,(8-(DATEPART(WEEKDAY,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))))%7,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))
				set @idCmdSql = 0
				set @cmdSql = ''''''''
				set @maxTimeSeconds = 7200
				set @maxTimeSecondsSunday = 14400
				set @dateExecution = getdate()

				if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
					begin
						if exists (select * from sys.tables where name = ''''userDatabases'''')
							drop table userDatabases

						if exists (select * from sys.tables where name = ''''indexMaintenance'''')
							drop table indexMaintenance

						if exists (select * from sys.tables where name = ''''logCentinella'''')
							drop table logCentinella
					end

				if not exists (select * from sys.tables where name = ''''userDatabases'''')
					begin
						create table dbo.userDatabases(
							[idDb] int not null identity primary key,
							[dbName] nvarchar(100) not null,
							[dbLog] nvarchar(100) not null,
							[status] bit not null
						)

						CREATE NONCLUSTERED INDEX [IX_userDatabases1] ON [dbo].[userDatabases]
						(
							[dbName] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

						CREATE NONCLUSTERED INDEX [IX_userDatabases2] ON [dbo].[userDatabases]
						(
							[status] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					end

				if not exists (select * from sys.tables where name = ''''indexMaintenance'''')
					begin
						create table dbo.indexMaintenance(
							[idIndex] int not null identity primary key,
							[dbName] nvarchar(100) not null,
							[tableName] nvarchar(100) not null,
							[indexName] nvarchar(100) not null,
							[indexType] nvarchar(100) not null,
							[indexFragmentation] nvarchar(100) not null,
							[status] bit not null
						)

						CREATE NONCLUSTERED INDEX [IX_indexMaintenance1] ON [dbo].[indexMaintenance]
						(
							[dbName] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

						CREATE NONCLUSTERED INDEX [IX_indexMaintenance2] ON [dbo].[indexMaintenance]
						(
							[tableName] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

						CREATE NONCLUSTERED INDEX [IX_indexMaintenance3] ON [dbo].[indexMaintenance]
						(
							[status] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					end

				if not exists (select * from sys.tables where name = ''''logCentinella'''')
					begin
						create table dbo.logCentinella(
							[idCmdSql] int not null identity primary key,
							[date] datetime not null,
							[cmdSql] nvarchar(max) not null,
							[status] int not null,
							[dateStart] datetime not null,
							[dateEnd] datetime not null,
							[executionTimeSeconds] int not null
						)

						CREATE NONCLUSTERED INDEX [IX_logCentinella1] ON [dbo].[logCentinella]
						(
							[date] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

						CREATE NONCLUSTERED INDEX [IX_logCentinella2] ON [dbo].[logCentinella]
						(
							[status] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					end

				insert into userDatabases
				select db_name(database_id), '''''''', 0
				from sys.master_files
				where state = 0 
				and has_dbaccess(db_name(database_id)) = 1
				and db_name(database_id) NOT IN (''''master'''', ''''tempdb'''', ''''model'''', ''''msdb'''', ''''resource'''', ''''distribution'''', ''''reportservice'''', ''''reportservicetempdb'''')
				and type = 0

				update userDatabases
				set [dbLog] = name
				from sys.master_files
				inner join userDatabases on (db_name(database_id) = [dbName] and type = 1)

				while (select count(*) from userDatabases where status = 0) > 0
					begin
						set rowcount 1
							select @idDb = idDb, @dbName = dbName from userDatabases where status = 0 order by idDb
						set rowcount 0

						select @sql = ''''use ['''' + @dbName + ''''] 

				insert into master.dbo.indexMaintenance
				SELECT '''''''''''' + @dbName + '''''''''''', OBJECT_NAME(ind.OBJECT_ID), ind.name, indexstats.index_type_desc, indexstats.avg_fragmentation_in_percent, 0
				FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats 
				INNER JOIN sys.indexes ind ON (ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id and ind.type > 0)
				inner join sysobjects obj on (obj.id = indexstats.object_id and xtype=''''''''U'''''''' and category = 0)
				WHERE indexstats.avg_fragmentation_in_percent > 30 
				ORDER BY OBJECT_NAME(ind.OBJECT_ID), ind.name''''

						exec(@sql)

						update userDatabases
						set status = 1
						where idDb = @idDb
					end

				while (select count(*) from indexMaintenance where status = 0) > 0
					begin
						set rowcount 1
							select @idIndex = idIndex, @dbName = dbName, @tableName = tableName, @indexName = indexName from indexMaintenance where status = 0 order by idIndex
						set rowcount 0

						select @sql = ''''use ['''' + @dbName + ''''] ''''

						if @process = 1
								select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REORGANIZE WITH ( LOB_COMPACTION = ON )'''' 
						else if @process = 2
								select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )'''' 
						else if @process = 3
								select @sql = @sql + ''''UPDATE STATISTICS [dbo].['''' + @tableName + ''''] WITH FULLSCAN'''' 

						insert into logCentinella
						select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

						if @process < 3
							update indexMaintenance set status = 1 where idIndex = @idIndex
						else
							update indexMaintenance set status = 1 where dbName = @dbName and tableName = @tableName

						if @process < 3
							begin
								if (select count(*) from indexMaintenance where status = 0) = 0
									begin
										update indexMaintenance 
										set status = 0

										set @process = @process + 1
									end
							end
					end

				if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
					begin
						update userDatabases
						set status = 0

						while (select count(*) from userDatabases where status = 0) > 0
							begin
								set rowcount 1
									select @idDb = idDb, @dbName = dbName, @dbLog = dbLog from userDatabases where status = 0 order by idDb
								set rowcount 0

								select @sql = ''''use ['''' + @dbName + ''''] DBCC CHECKDB WITH NO_INFOMSGS''''
								
								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0
								
								select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKDATABASE(N'''''''''''' + @dbName + '''''''''''', 10, TRUNCATEONLY)''''
								
								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

								select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKFILE('''''''''''' + @dbLog + '''''''''''',1)''''

								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

								select @sql = ''''use [master] 

				DECLARE @currentdate datetime
				declare @date varchar(200)
				declare @rutaBak as nvarchar(2000)

				set @currentdate = CURRENT_TIMESTAMP
				select @date = '''''''''''' + @dbName + ''''_Backup_Centinella_'''''''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''''''.bak''''''''

				create table #RutaBak(
				Value nvarchar(2000) not null,
				Data nvarchar(2000) not null)

				insert into #RutaBak
				EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

				select @rutaBak = Data
				from #RutaBak

				select @rutaBak= @rutaBak + ''''''''\'''''''' + @date

				drop table #RutaBak

				BACKUP DATABASE ['''' + @dbName + ''''] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10''''

								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

								update userDatabases
								set status = 1
								where idDb = @idDb
							end

						select @sql = ''''use [master] 

				DECLARE @currentdate datetime
				declare @date datetime
				declare @rutaBak as nvarchar(2000)

				set @currentdate = CURRENT_TIMESTAMP
				select @date = dateadd(ww,-3,getdate())

				create table #RutaBak(
				Value nvarchar(2000) not null,
				Data nvarchar(2000) not null)

				insert into #RutaBak
				EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

				select @rutaBak = Data
				from #RutaBak

				EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''''''bak'''''''',@date

				drop table #RutaBak''''

						insert into logCentinella
						select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

					end

				set @dateExecution = getdate()

				while (select count(*) from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate()))) > 0
					begin
						set rowcount 1
							select @idCmdSql = idCmdSql, @cmdSql = cmdSql from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate())) order by idCmdSql
						set rowcount 0
						
						update logCentinella
						set dateStart = getdate()
						where idCmdSql = @idCmdSql	

						exec(@cmdSql)

						WAITFOR DELAY ''''00:00:01''''

						while(SELECT count(*)
								FROM sys.dm_exec_requests a 
								INNER JOIN sys.dm_exec_connections b       
								ON a.session_id = b.session_id       
								INNER JOIN sys.dm_exec_sessions c        
								ON c.session_id = a.session_id       
								CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d       
								WHERE a.session_id > 50   
								AND a.session_id = @@SPID
								and d.text = @cmdSql) > 0
							begin
								WAITFOR DELAY ''''00:00:01''''
							end

						if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
							begin
								if((datediff(ss,@dateExecution,getdate())) > @maxTimeSecondsSunday)
									BREAK
							end
						else
							begin
								if((datediff(ss,@dateExecution,getdate())) > @maxTimeSeconds)
									BREAK
							end

						update logCentinella
						set status = 1, dateEnd = getdate(), executionTimeSeconds = datediff(ss,dateStart,getdate())
						where idCmdSql = @idCmdSql
					end

				delete userDatabases
				delete indexMaintenance'', 
						@database_name=N''master'', 
						@flags=0
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''DatabaseCentinellaSchedule'', 
						@enabled=1, 
						@freq_type=4, 
						@freq_interval=1, 
						@freq_subday_type=1, 
						@freq_subday_interval=0, 
						@freq_relative_interval=0, 
						@freq_recurrence_factor=0, 
						@active_start_date=20140724, 
						@active_end_date=99991231, 
						@active_start_time=10000, 
						@active_end_time=235959
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				COMMIT TRANSACTION
				GOTO EndSave
				QuitWithRollback:
				    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
				EndSave:'	
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