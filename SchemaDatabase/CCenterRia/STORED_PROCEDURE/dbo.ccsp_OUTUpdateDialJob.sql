CREATE PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
@callout_id     INT, 
@CallResultDial TINYINT, 
@isTCPA         BIT     = 0
AS
     SET NOCOUNT ON

/*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine	*/

     DECLARE @nOcupado TINYINT, @nNoContesta TINYINT, @nFax TINYINT, @nContestadora TINYINT
     DECLARE @nShortCall TINYINT, @nOtro TINYINT, @cam_NoInt_ocupado TINYINT, @cam_NoInt_graba TINYINT
     DECLARE @cam_ocupado SMALLINT, @cam_inter_ocupado SMALLINT, @cam_nocontesto SMALLINT
     DECLARE @cam_graba SMALLINT, @cam_inter_graba SMALLINT, @cam_inter_nocontesto SMALLINT
     DECLARE @cam_fax SMALLINT, @cam_inter_fax SMALLINT
     DECLARE @DateNextDial SMALLDATETIME, @DateNewDial SMALLDATETIME, @cam_id SMALLINT
     DECLARE @ExisteWT TINYINT, @cam_NoInt_fax TINYINT, @cam_NoInt_nocontesto TINYINT, @cal_status TINYINT
     DECLARE @sSQL NVARCHAR(MAX), @Telefono VARCHAR(15), @prioridadLlamada CHAR(8)
     SELECT @cam_id = cam_id, 
            @nOcupado = ISNULL(nOcupado, 0), 
            @nNoContesta = ISNULL(nNoContesta, 0), 
            @nFax = ISNULL(nFax, 0),  
            @nContestadora = ISNULL(nContestadora, 0), 
            @nShortCall = ISNULL(nShortCall, 0), 
            @nOtro = ISNULL(nOtro, 0), 
            @DateNextDial = cal_fechaDial
     FROM ccoWorkingTable
     WHERE callout_id = @callout_id
     SELECT @ExisteWT = CASE
                            WHEN @cam_id IS NOT NULL
                            THEN 1
                            ELSE 0
                        END
     SELECT @cal_status = CASE
                              WHEN @isTCPA = 1
                              THEN 0
                              ELSE 1
                          END--si esta en modo TCPA no gene|rar callbacks

     IF @CallResultDial = 20 -- CONTACTADO
         BEGIN
             EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta, 
                  @nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
             RETURN(0)
     END
     IF @CallResultDial = 1
         BEGIN-- CONTESTO 
             IF @isTCPA = 1
                 BEGIN
                     UPDATE ccoWorkingTable SET cal_status = @cal_status
                     WHERE callout_id = @callout_id
             END
             ELSE
                 BEGIN
                     IF (SELECT abandonCallback FROM ccCamps WHERE cam_id = @cam_id) = 1
                         BEGIN
                             EXEC ccsp_OUTCancelDialJOB @callout_id,1,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
                     END
                     ELSE
                         BEGIN
                             EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
                     END
             END
             RETURN(0)
     END
     ELSE
         IF @CallResultDial IN(2, 12)
             BEGIN -- OCUPADO 
                 SELECT @cam_ocupado = cam_ocupado,
						@cam_inter_ocupado = cam_inter_ocupado,
						@cam_NoInt_ocupado = cam_NoInt_ocupado,
						@nOcupado = @nOcupado + 1
                 FROM ccCamps
                 WHERE cam_id = @cam_id

                 IF @cam_ocupado = 1
                 -- Opcion Ocupado HABILITADA	 
                     BEGIN
                         IF @nOcupado > @cam_NoInt_ocupado OR @nShortCall > 4
                             BEGIN
                                 EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
                                 RETURN(0)
                         END
                         IF NOT EXISTS (SELECT priorityCall FROM ccoCallPriorityOrder WHERE callout_id = @callout_id)
                             BEGIN
                                 SELECT @prioridadLlamada = Prioridad
                                 FROM ccCampsPrioridadTel
                                 WHERE cam_id = @cam_id

                                 INSERT INTO ccoCallPriorityOrder 
                                 VALUES (@callout_id,@prioridadLlamada)
                         END
                         -- Change priority and obtain the next telephone
                         UPDATE ccoCallsOutSource SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1	ELSE nNoContesta END
                         WHERE callout_id = @callout_id
                         UPDATE ccoCallPriorityOrder SET priorityCall = CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)) 
								+ REPLACE('2345NNN', CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)), '1') WHERE callout_id = @callout_id
                         SELECT @sSQL = 'select @outA=rtrim(left(ltrim(cal_telefono' + CASE SUBSTRING(priorityCall, 1, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 1, 1) END 
							+ '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 2, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 2, 1) END 
							+ '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 3, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 3, 1) END 
							+ '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 4, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 4, 1) END 
							+ '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 5, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 5, 1) END 
							+ '+''         ''),13)) from ccoCallsOutSource nolock where callout_id=' 
							+ CAST(@callout_id AS VARCHAR(15))
                         FROM ccoCallPriorityOrder pll WITH(NOLOCK)
                         WHERE callout_id = @callout_id
                         EXEC sp_executesql @sSQL, N'@outA varchar(15) OUTPUT', @outA = @Telefono OUTPUT

                         SELECT @DateNewDial = DATEADD(mi, @cam_inter_ocupado, GETDATE())

                         -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
                         IF @DateNewDial > @DateNextDial
                             BEGIN	-- Nueva fecha de Call BACk
                                 UPDATE ccoWorkingTable SET nOcupado = @nOcupado, cal_fechaDial = @DateNewDial, cal_status = @cal_status
                                 WHERE callout_id = @callout_id
                                 RETURN(0)
                         END
                         -- Mantiene la fecha de Call BACK
                         UPDATE ccoWorkingTable SET nOcupado = @nOcupado, cal_status = @cal_status, cal_telefono = @Telefono
                         WHERE callout_id = @callout_id
                         RETURN(0)
                 END

                 -- ELSE: Opcion Ocupado DESHABILITADA
                 EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                 RETURN(0)
         END
             ELSE
             IF @CallResultDial IN(3, 5, 8)
                 BEGIN-- NO CONTESTA 
                     --select NO Contesta
                     SELECT @cam_nocontesto = cam_nocontesto, 
                            @cam_inter_nocontesto = cam_inter_nocontesto, 
                            @cam_NoInt_nocontesto = cam_NoInt_nocontesto, 
                            @nNoContesta = @nNoContesta + 1
                     FROM ccCamps
                     WHERE cam_id = @cam_id
                     IF @cam_nocontesto = 1
                         BEGIN-- Opcion NoContesta HABILITADA	 
                             IF @nNoContesta > @cam_NoInt_nocontesto
                                OR @nShortCall > 4
                                 BEGIN --select No Contesta Habilitada
                                     EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                                     RETURN(0)
                             END

                             IF NOT EXISTS (SELECT priorityCall FROM ccoCallPriorityOrder WHERE callout_id = @callout_id)
                                 BEGIN
                                     SELECT @prioridadLlamada = Prioridad
                                     FROM ccCampsPrioridadTel
                                     WHERE cam_id = @cam_id

                                     INSERT INTO ccoCallPriorityOrder
                                     VALUES (@callout_id, @prioridadLlamada)
                             END

                             -- Change priority and obtain the next telephone
                             UPDATE ccoCallsOutSource SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1 ELSE nNoContesta END
                             WHERE callout_id = @callout_id
                             UPDATE ccoCallPriorityOrder SET priorityCall = CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)) 
									+ replace('2345NNN', CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)), '1')
							 WHERE callout_id = @callout_id

                             SELECT @sSQL = 'select @outA=rtrim(left(ltrim(cal_telefono' + CASE SUBSTRING(priorityCall, 1, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 1, 1) END 
								+ '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 2, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 2, 1) END 
								+ '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 3, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 3, 1) END 
								+ '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 4, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 4, 1) END 
								+ '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 5, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 5, 1) END 
								+ '+''         ''),13)) from ccocallsoutsource nolock where callout_id=' 
								+ CAST(@callout_id AS VARCHAR(15))
                             FROM ccoCallPriorityOrder WITH(NOLOCK)
                             WHERE callout_id = @callout_id

                             EXEC sp_executesql @sSQL, N'@outA varchar(15) OUTPUT', @outA = @Telefono OUTPUT

                             SELECT @DateNewDial = DATEADD(mi, @cam_inter_nocontesto, GETDATE())

                             UPDATE ccoWorkingTable SET nNoContesta = @nNoContesta, cal_status = @cal_status, cal_telefono = @Telefono, 
									cal_fechaDial = CASE
                                                       WHEN @DateNewDial > @DateNextDial
                                                       THEN @DateNewDial
                                                       ELSE cal_fechaDial
                                                    END
                             WHERE callout_id = @callout_id
                             RETURN(0)
                     END

                     -- Opcion NoContesta DESHABILITADA
                     EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                     RETURN(0)
             END
             ELSE
                 IF @CallResultDial = 4
                     BEGIN-- Fax/Modem 
                         SELECT @cam_fax = cam_fax,
                                @cam_inter_fax = cam_inter_fax, 
                                @cam_NoInt_fax = cam_NoInt_fax, 
                                @nFax = @nFax + 1
                         FROM ccCamps
                         WHERE cam_id = @cam_id
                         IF @cam_fax = 1
                             BEGIN-- Opcion Fax/Modem HABILITADA	 
                                 IF @nFax > @cam_NoInt_fax
                                    OR @nShortCall > 4
                                     BEGIN
                                         EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                                         RETURN(0)
                                 END
                                 IF NOT EXISTS (SELECT priorityCall FROM ccoCallPriorityOrder WHERE callout_id = @callout_id)
                                     BEGIN
                                         SELECT @prioridadLlamada = Prioridad
                                         FROM ccCampsPrioridadTel
                                         WHERE cam_id = @cam_id

                                         INSERT INTO ccoCallPriorityOrder
                                         VALUES (@callout_id, @prioridadLlamada)
                                 END

                                 -- Change priority and obtain the next telephone
                                 UPDATE ccoCallsOutSource SET nFax = CASE WHEN nFax < 255 THEN ISNULL(nFax, 0) + 1 ELSE nFax END
                                 WHERE callout_id = @callout_id

                                 UPDATE ccoCallPriorityOrder SET priorityCall = CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1))  
								    + replace('2345NNN', CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)), '1') 
								 WHERE callout_id = @callout_id

                                 SELECT @sSQL = 'select @outA=rtrim(left(ltrim(cal_telefono' + CASE SUBSTRING(priorityCall, 1, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 1, 1) END 
								 + '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 2, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 2, 1) END 
								 + '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 3, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 3, 1) END 
								 + '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 4, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 4, 1) END 
								 + '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 5, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 5, 1) END 
								 + '+''         ''),13)) from ccocallsoutsource nolock where callout_id=' 
								 + CAST(@callout_id AS VARCHAR(15))
                                 FROM ccoCallPriorityOrder WITH(NOLOCK)
                                 WHERE callout_id = @callout_id
                                 
								 EXEC sp_executesql @sSQL, N'@outA varchar(15) OUTPUT', @outA = @Telefono OUTPUT

                                 SELECT @DateNewDial = DATEADD(mi, @cam_inter_fax, GETDATE())

                                 -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
                                 UPDATE ccoWorkingTable SET nFax = @nFax, cal_status = @cal_status, cal_telefono = @Telefono, 
                                       cal_fechaDial = CASE
                                                           WHEN @DateNewDial > @DateNextDial
                                                           THEN @DateNewDial
                                                           ELSE cal_fechaDial
                                                       END
                                 WHERE callout_id = @callout_id
                                 RETURN(0)
                         END

                         -- Opcion Fax/Modem DESHABILITADA
                         EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                         RETURN(0)
                 END
                     ELSE
                     IF @CallResultDial = 11
                         BEGIN-- Maquina Contestadora 
                             SELECT @cam_graba = cam_graba, 
                                    @cam_inter_graba = cam_inter_graba, 
                                    @cam_NoInt_graba = cam_NoInt_graba, 
                                    @nContestadora = @nContestadora + 1
                             FROM ccCamps
                             WHERE cam_id = @cam_id
                             IF @cam_graba = 1 -- Opcion Maquina Contestadora HABILITADA
                                 BEGIN
                                     IF @nContestadora > @cam_NoInt_graba OR @nShortCall > 4
                                         BEGIN
                                             EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                                             RETURN(0)
                                     END
                                     IF NOT EXISTS (SELECT priorityCall FROM ccoCallPriorityOrder WHERE callout_id = @callout_id)
                                         BEGIN
                                             SELECT @prioridadLlamada = Prioridad
                                             FROM ccCampsPrioridadTel
                                             WHERE cam_id = @cam_id
                                             INSERT INTO ccoCallPriorityOrder
                                             VALUES (@callout_id, @prioridadLlamada)
                                     END

                                     -- Change priority and obtain the next telephone
                                     UPDATE ccoCallsOutSource SET nContestadora = CASE WHEN nContestadora < 255 THEN ISNULL(nContestadora, 0) + 1 ELSE nContestadora END
                                     WHERE callout_id = @callout_id

                                     UPDATE ccoCallPriorityOrder SET priorityCall = CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)) 
										+ replace('2345NNN', CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)), '1')
                                     WHERE callout_id = @callout_id

                                     SELECT @sSQL = 'select @outA=rtrim(left(ltrim(cal_telefono' + CASE SUBSTRING(priorityCall, 1, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 1, 1) END 
										+ '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 2, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 2, 1) END 
										+ '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 3, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 3, 1) END 
										+ '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 4, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 4, 1) END 
										+ '+''         ''+' + 'cal_telefono' + CASE SUBSTRING(priorityCall, 5, 1) WHEN 1 THEN '' ELSE SUBSTRING(priorityCall, 5, 1) END 
										+ '+''         ''),13)) from ccocallsoutsource nolock where callout_id=' 
										+ CAST(@callout_id AS VARCHAR(15))
                                     FROM ccoCallPriorityOrder WITH(NOLOCK)
                                     WHERE callout_id = @callout_id

                                     EXEC sp_executesql @sSQL, N'@outA varchar(15) OUTPUT', @outA = @Telefono OUTPUT

                                     SELECT @DateNewDial = DATEADD(mi, @cam_inter_graba, GETDATE())

                                     -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
                                     UPDATE ccoWorkingTable SET nContestadora = @nContestadora, cal_status = @cal_status, cal_telefono = @Telefono, 
                                           cal_fechaDial = CASE
                                                               WHEN @DateNewDial > @DateNextDial
                                                               THEN @DateNewDial
                                                               ELSE cal_fechaDial
                                                           END
                                     WHERE callout_id = @callout_id
                                     RETURN(0)
                             END

                             -- Opcion Maquina Contestadora DESHABILITADA
                             EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                             RETURN(0)
                     END
                         ELSE
                         IF @CallResultDial IN(10, 90)
                             BEGIN--No Dial Tone, otros, NoService 
                                 EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                                 RETURN(0)
                         END
                             ELSE
                             IF @CallResultDial > 13 AND @CallResultDial <> 51
                                 BEGIN--Dial Result not register
                                     EXEC ccsp_OUTUpdateDialJob @callout_id = @callout_id, @CallResultDial = 8, @isTCPA = @isTCPA
                             END

     RETURN(0)
     SET NOCOUNT OFF