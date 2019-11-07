CREATE  PROCEDURE [dbo].[trsp_AdmAVRSReportCallInfo]
			@id_formato int,
			@version int,
			@call_id int,
			@tipo int,
			@medio int
			AS
			BEGIN
			declare @id_grabacion as int

			if @medio =2
				BEGIN
					set @id_grabacion = @call_id
					 
					SELECT    Age.Nombres + ' ' + Age.ApellidoPaterno AS Agente, Super.Nombres + ' ' + Super.ApellidoPaterno AS Supervisor, 
					  Calificador.Nombres+' '+Calificador.ApellidoPaterno AS Calificador,chat.domain AS Telfono ,
					  Tipo= 'inbound',chat.chatDate AS Fecha,chat.chatId AS [Id de llamada],'' AS [Id de Grabacion],
					  '' AS [Cal key],dbo.ft_getTime(chat.tChatting,'2') AS Duracion,	[Campaña/GrupO ACD]=
					  ( SELECT ccInbound.descripcion FROM ccriachats INNER JOIN ccInbound ON ccriachats.inboundId = ccInbound.Inbound_id
						WHERE (ccriachats.chatId = @id_grabacion)),
						RIA_FORMATOS.nombre AS [Formato de calificacion],RIA_FORMACALIF.fecha_calif[Fecha revision]
				FROM  RIA_FORMACALIF INNER JOIN
						ccUsers AS Age ON RIA_FORMACALIF.age_id = Age.User_id INNER JOIN
						ccUsers AS Super ON RIA_FORMACALIF.id_supervisor = Super.User_id INNER JOIN
						ccUsers AS Calificador ON RIA_FORMACALIF.id_calificador = Calificador.User_id INNER JOIN
						RIA_FORMATOS ON  RIA_FORMACALIF.id_formato =  RIA_FORMATOS.id_formato INNER JOIN
						ccriachats AS chat ON chat.chatId = RIA_FORMACALIF.id_grabacion
				WHERE RIA_FORMACALIF.id_formato=@id_formato and
						RIA_FORMACALIF.version=@version and
						RIA_FORMACALIF.id_grabacion=@id_grabacion and
						RIA_FORMATOS.version=@version
				END
			else
			BEGIN 
				
				IF EXISTS (select grab_id from ria_grabacion where cal_id=@call_id and tipo_llamada=@tipo)
					BEGIN
					
						set @id_grabacion = (select grab_id from ria_grabacion where cal_id=@call_id and tipo_llamada=@tipo)

						SELECT    Age.Nombres + ' ' + Age.ApellidoPaterno AS Agente, Super.Nombres + ' ' + Super.ApellidoPaterno AS Supervisor, 
						  Calificador.Nombres+' '+Calificador.ApellidoPaterno AS Calificador,RIA_GRABACION.ani AS Telfono ,Tipo=
																								CASE WHEN (SELECT tipo_llamada 
																											FROM RIA_GRABACION 
																											WHERE grab_id=@id_grabacion)=1 THEN 'inbound' 
																								ELSE 'outbound' 
																								END,
											  RIA_GRABACION.finicio AS Fecha,RIA_GRABACION.cal_id AS [Id de llamada],RIA_GRABACION.grab_id AS [Id de Grabacion],
											  RIA_GRABACION.cal_key AS [Cal key],dbo.ft_getTime(RIA_GRABACION.duracion,'2') AS Duracion,
											  [Campaña/GrupO ACD]=
												CASE WHEN (SELECT tipo_llamada 
														   FROM RIA_GRABACION 
														   WHERE grab_id=@id_grabacion)=1 THEN (SELECT ccInbound.descripcion
																					   FROM RIA_GRABACION INNER JOIN
																					   ccInbound ON RIA_GRABACION.cam_id = ccInbound.Inbound_id
																					   WHERE (RIA_GRABACION.grab_id = @id_grabacion)) 
					     						ELSE (SELECT     ccCamps.cam_descripcion
													  FROM       RIA_GRABACION INNER JOIN
													  ccCamps ON RIA_GRABACION.cam_id = ccCamps.cam_id
													  WHERE     (RIA_GRABACION.grab_id = @id_grabacion))
												END,
											  RIA_FORMATOS.nombre AS [Formato de calificacion],RIA_FORMACALIF.fecha_calif[Fecha revision]
										FROM  RIA_FORMACALIF INNER JOIN
											 ccUsers AS Age ON RIA_FORMACALIF.age_id = Age.User_id INNER JOIN
											  ccUsers AS Super ON RIA_FORMACALIF.id_supervisor = Super.User_id INNER JOIN
											  ccUsers AS Calificador ON RIA_FORMACALIF.id_calificador = Calificador.User_id INNER JOIN
											  RIA_GRABACION ON RIA_FORMACALIF.id_grabacion = RIA_GRABACION.grab_id INNER JOIN
											  RIA_FORMATOS ON  RIA_FORMACALIF.id_formato =  RIA_FORMATOS.id_formato
										WHERE RIA_FORMACALIF.id_formato=@id_formato and
											  RIA_FORMACALIF.version=@version and
											  RIA_FORMACALIF.id_grabacion=@id_grabacion and
											  RIA_FORMATOS.version=@version

					END
				ELSE
					BEGIN

						set @id_grabacion =(select grab_id from RIA_GRABACIONCONSULTA where cal_id=@call_id and tipo_llamada=@tipo)

						SELECT    Age.Nombres + ' ' + Age.ApellidoPaterno AS Agente, Super.Nombres + ' ' + Super.ApellidoPaterno AS Supervisor, 
						  Calificador.Nombres+' '+Calificador.ApellidoPaterno AS Calificador,RIA_GRABACIONCONSULTA.ani AS Telfono ,Tipo=
																								CASE WHEN (SELECT tipo_llamada 
																											FROM RIA_GRABACIONCONSULTA 
																											WHERE grab_id=@id_grabacion)=1 THEN 'inbound' 
																								ELSE 'outbound' 
																								END,
											  RIA_GRABACIONCONSULTA.finicio AS Fecha,RIA_GRABACIONCONSULTA.cal_id AS [Id de llamada],RIA_GRABACIONCONSULTA.grab_id AS [Id de Grabacion],
											  RIA_GRABACIONCONSULTA.cal_key AS [Cal key],dbo.ft_getTime(RIA_GRABACIONCONSULTA.duracion,'2') AS Duracion,
											  [Campaña/GrupO ACD]=
												CASE WHEN (SELECT tipo_llamada 
														   FROM RIA_GRABACIONCONSULTA 
														   WHERE grab_id=@id_grabacion)=1 THEN (SELECT ccInbound.descripcion
																					   FROM RIA_GRABACIONCONSULTA INNER JOIN
																					   ccInbound ON RIA_GRABACIONCONSULTA.cam_id = ccInbound.Inbound_id
																					   WHERE (RIA_GRABACIONCONSULTA.grab_id = @id_grabacion)) 
					     						ELSE (SELECT     ccCamps.cam_descripcion
													  FROM       RIA_GRABACIONCONSULTA INNER JOIN
													  ccCamps ON RIA_GRABACIONCONSULTA.cam_id = ccCamps.cam_id
													  WHERE     (RIA_GRABACIONCONSULTA.grab_id = @id_grabacion))
												END,
											  RIA_FORMATOS.nombre AS [Formato de calificacion],RIA_FORMACALIF.fecha_calif[Fecha revision]
										FROM  RIA_FORMACALIF INNER JOIN
											 ccUsers AS Age ON RIA_FORMACALIF.age_id = Age.User_id INNER JOIN
											  ccUsers AS Super ON RIA_FORMACALIF.id_supervisor = Super.User_id INNER JOIN
											  ccUsers AS Calificador ON RIA_FORMACALIF.id_calificador = Calificador.User_id INNER JOIN
											  RIA_GRABACIONCONSULTA ON RIA_FORMACALIF.id_grabacion = RIA_GRABACIONCONSULTA.grab_id INNER JOIN
											  RIA_FORMATOS ON  RIA_FORMACALIF.id_formato =  RIA_FORMATOS.id_formato
										WHERE RIA_FORMACALIF.id_formato=@id_formato and
											  RIA_FORMACALIF.version=@version and
											  RIA_FORMACALIF.id_grabacion=@id_grabacion and
											  RIA_FORMATOS.version=@version

					
					END
				END
			END