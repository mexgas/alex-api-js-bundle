CREATE PROCEDURE [dbo].[ccsp_AgentSetCallStatus] 
	@callout_id INT, 
    @cal_id     INT, 
    @TipoCall   TINYINT, -- 1= IN,  2=Out
    @TipoMov    TINYINT, -- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
    @cal_tXfer  TINYINT    = 0, 
    @cal_tring  SMALLINT   = 0, 
    @user_id    SMALLINT   = 0, 
    @extension  VARCHAR(5) = '', 
    @isChatCall BIT        = 0
AS
     SET NOCOUNT ON
     DECLARE @RecicleSIC TINYINT

     SELECT @RecicleSIC = ISNULL(valor, 0)
     FROM ccSettings
     WHERE setting_id = 60

     DECLARE @ANI_x VARCHAR(19)
     DECLARE @cal_inicio DATETIME
     DECLARE @callout_id_IN INT
     DECLARE @cal_key VARCHAR(20)
     DECLARE @cam_id INT
     DECLARE @cal_telefono VARCHAR(30)
     DECLARE @surveycamid INT
     DECLARE @inbound_id INT
     IF @TipoMov = 4 OR @TipoMov = 14 -- DIALOG OnDialog
         BEGIN
             IF @TipoCall = 2
                 BEGIN
                     IF @TipoMov = 4
                         BEGIN
                             UPDATE ccoCallsOUT WITH(ROWLOCK)
                               SET cal_Inicio = GETDATE(), 
                                   statusCall_id = 13, 
                                   cal_manual = CASE
                                                    WHEN @isChatCall = 1
                                                    THEN 3
                                                    ELSE cal_manual
                                                END
                             WHERE cal_id = @cal_id
                     END
                         ELSE
                         IF @TipoMov = 14
                             UPDATE ccoCallsOUT WITH(ROWLOCK)
                               SET statusCall_id = 13, 
                                   cal_tRing = @cal_tring, 
                                   user_id = @user_id, 
                                   cal_extension = @extension
                             WHERE cal_id = @cal_id
                     IF @RecicleSIC = 0
                         BEGIN
                             DELETE ccoWorkingTable WITH(ROWLOCK)
                             WHERE callout_id = @callout_id

                             DELETE ccoCallPriorityOrder WITH(ROWLOCK)
                             WHERE callout_id = @callout_id
                     END
                     UPDATE ccoCallBacks
                       SET [status] = 1, 
                           schedulerStatus = 1, 
                           cal_fcallback = cal_inicio
                     FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
                     WHERE a.callout_id = b.callout_id
                           AND b.callout_id = @callout_id
                           AND b.cal_id = @cal_id
                           AND [status] = 0
                           AND statusCall_id = 13

                     -- calcula el costo de la llamada
                     EXEC ccsp_CstoCalculaCosto @cal_id

                     RETURN(0)
             END
             IF @TipoMov = 4
                 UPDATE ccCallsIN WITH(ROWLOCK)
                   SET statusCall_id = 13
                 WHERE cal_id = @cal_id

                 ELSE
                 IF @TipoMov = 14
                     UPDATE ccCallsIN WITH(ROWLOCK)
                       SET statusCall_id = 13, 
                           cal_tRing = @cal_tring, 
                           user_id = @user_id, 
                           cal_extension = @extension
                     WHERE cal_id = @cal_id

             -- Elimina callback generado por abandono
             SELECT @ANI_x = cal_ani, 
                    @cal_inicio = cal_inicio
             FROM cccallsin WITH (INDEX(PK_ccCallsIn))
             WHERE cal_id = @cal_id

             SELECT @callout_id_IN = callout_id
             FROM ccRIAUpdateCallBack_Abandon
             WHERE cal_ani = @ANI_x

             UPDATE ccoCallBacks WITH(ROWLOCK)
               SET [status] = 1, 
                   schedulerStatus = 1, 
                   cal_fcallback = @cal_inicio
             WHERE callout_id = @callout_id_IN
                   AND [status] = 0

             DELETE ccoWorkingTable WITH(ROWLOCK)
             WHERE callout_id IN
             (
                 SELECT DISTINCT
                        (callout_id)
                 FROM ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
                 WHERE cal_ani = @ANI_x
             )


             DELETE ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
             WHERE cal_ANI = @ANI_x

             RETURN(0)
     END
     IF @TipoMov = 7 --OTHER OFFHook_OnXfer
         BEGIN
             IF @cal_id <= 0
                 RETURN(0)
             IF @TipoCall = 2
                 BEGIN
                     UPDATE ccoCallsOUT WITH(ROWLOCK)
                       SET statusCall_id = 16
                     WHERE cal_id = @cal_id
                     -- calcula el costo de la llamada

                     UPDATE ccoCallBacks
                       SET [status] = 2, 
                           schedulerStatus = 1, 
                           cal_fcallback = cal_inicio
                     FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
                     WHERE a.callout_id = b.callout_id
                           AND b.callout_id = @callout_id
                           AND b.cal_id = @cal_id
                           AND [status] = 0
                           AND statusCall_id = 16

                     EXEC ccsp_CstoCalculaCosto 
                          @cal_id

                     RETURN(0)
             END
             UPDATE ccCallsIN WITH(ROWLOCK)
               SET statusCall_id = 16
             WHERE cal_id = @cal_id

             SELECT @ANI_x = cal_ani, 
                    @cal_inicio = cal_inicio
             FROM cccallsin WITH (INDEX(PK_ccCallsIn))
             WHERE cal_id = @cal_id

             SELECT @callout_id_IN
             FROM ccRIAUpdateCallBack_Abandon
             WHERE cal_ani = @ANI_x

             UPDATE ccoCallBacks WITH(ROWLOCK)
               SET [status] = 2, 
                   schedulerStatus = 1, 
                   cal_fcallback = @cal_inicio
             WHERE callout_id = @callout_id_IN
                   AND [status] = 0

             RETURN(0)
     END
     IF @TipoMov = 9 --RING CallNoAnswered
         BEGIN
             IF @TipoCall = 2
                 BEGIN
                     UPDATE ccoCallsOUT WITH(ROWLOCK)
                       SET statusCall_id = 15, 
                           cal_tXFer = @cal_txFer, 
                           cal_tRing = @cal_tring
                     WHERE cal_id = @cal_id

                     -- calcula el costo de la llamada

                     UPDATE ccoCallBacks
                       SET [status] = 2, 
                           schedulerStatus = 1, 
                           cal_fcallback = cal_inicio
                     FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
                     WHERE a.callout_id = b.callout_id
                           AND b.callout_id = @callout_id
                           AND b.cal_id = @cal_id
                           AND [status] = 0
                           AND statusCall_id = 15

                     EXEC ccsp_CstoCalculaCosto @cal_id
             END

             UPDATE ccCallsIN WITH(ROWLOCK)
               SET statusCall_id = 15, 
                   cal_tXFer = @cal_txFer, 
                   cal_tRing = @cal_tring
             WHERE cal_id = @cal_id

             SELECT @ANI_x = cal_ani, 
                    @cal_inicio = cal_inicio
             FROM cccallsin WITH (INDEX(PK_ccCallsIn))
             WHERE cal_id = @cal_id

             SELECT @callout_id_IN
             FROM ccRIAUpdateCallBack_Abandon
             WHERE cal_ani = @ANI_x

             UPDATE ccoCallBacks WITH(ROWLOCK)
               SET [status] = 2, 
                   schedulerStatus = 1, 
                   cal_fcallback = @cal_inicio
             WHERE callout_id = @callout_id_IN
                   AND [status] = 0

             RETURN(0)
     END
     SET NOCOUNT OFF