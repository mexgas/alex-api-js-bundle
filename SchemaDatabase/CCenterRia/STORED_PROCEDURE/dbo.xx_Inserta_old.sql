CREATE PROCEDURE [dbo].[xx_Inserta_old] @cal_key       VARCHAR(40), 
											@cal_telefono  VARCHAR(19), 
											@cal_telefono2 VARCHAR(19), 
											@cal_telefono3 VARCHAR(19), 
											@cal_telefono4 VARCHAR(19), 
											@cal_telefono5 VARCHAR(19), 
											@dato1         VARCHAR(255), 
											@dato2         VARCHAR(255), 
											@dato3         VARCHAR(255), 
											@dato4         VARCHAR(255), 
											@dato5         VARCHAR(255), 
											@cam_id        INTEGER, 
											@FCallBack     SMALLDATETIME = '', 
											@cal_status    TINYINT       = 0, 
											@User_id       INTEGER       = 0
	AS
		 DECLARE @calloutid INT;
		 IF(@cal_status = 0)
			 SET @FCallBack = GETDATE();
		 INSERT INTO ccoCallsOutSource
		 (cal_key, 
		  cal_telefono, 
		  cal_telefono2, 
		  cal_telefono3, 
		  cal_telefono4, 
		  cal_telefono5, 
		  dato1, 
		  dato2, 
		  dato3, 
		  dato4, 
		  dato5, 
		  cam_id, 
		  cal_fechaDial, 
		  cal_status, 
		  user_id
		 )
		 VALUES
		 (@cal_key, 
		  @cal_telefono, 
		  @cal_telefono2, 
		  @cal_telefono3, 
		  @cal_telefono4, 
		  @cal_telefono5, 
		  @dato1, 
		  @dato2, 
		  @dato3, 
		  @dato4, 
		  @dato5, 
		  @cam_id, 
		  @FCallBack, 
		  @cal_status, 
		  @User_id
		 );
		 SELECT @calloutid = SCOPE_IDENTITY();
		 INSERT INTO xxClienteHistorial
		 (callout_id, 
		  fechaAct
		 )
		 VALUES
		 (@calloutid, 
		  GETDATE()
		 );
		 SELECT @calloutid;