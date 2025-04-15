USE [CCReportsRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_HSBC_Outbound_Dials_Attempted]    Script Date: 12/02/2025 11:34:05 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ccsp_HSBC_Outbound_Dials_Attempted]
@fe_ini datetime =null,@fe_fin datetime =null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if @fe_ini is null 
	 set @fe_ini= convert(date,getdate())

	 if @fe_fin is null 
	 set @fe_fin= getdate()

	 delete from HSBC_Outbound_Dials_Attempted where fecha between @fe_ini and @fe_fin


	 declare @temp table
(logdial_id int, callout_id int, cam_id smallint, tipoResDial_id tinyint, telefono varchar(50), 
    puerto smallint, fecha datetime, tdialing smallint
);

insert @temp
select dial.logDial_id, 
                dial.callout_id, 
                dial.cam_id, 
                CASE
					WHEN dial.canceledNoAgents = 1
					THEN 14
					ELSE dial.tipoResDial_id
				END AS tipoResDial_id,
                dial.Telefono, 
                dial.Puerto, 
                dial.fecha, 
                dial.tDialing from ccoLogDials_backup dial
LEFT JOIN ccocallsout_backup B ON dial.cal_id=B.cal_id 
WHERE fecha BETWEEN @fe_ini AND @fe_fin
UNION 
SELECT 0 AS logDial_id, A.callout_id, A.cam_id,A.statusCall_id,A.cal_telefono,a.cal_puerto,A.cal_Inicio,0 AS tDialing
FROM ccocallsout_backup A
LEFT JOIN ccoLogDials_backup B ON A.cal_id=B.cal_id 
WHERE cal_Inicio BETWEEN @fe_ini AND @fe_fin
 AND a.cam_id IN (SELECT cam_id FROM cccamps WHERE IDArea = 5)
AND B.cal_id IS NULL


insert into HSBC_Outbound_Dials_Attempted
SELECT CONVERT(date,A.fecha) fecha
     ,A.cam_id
     ,B.Dato4
     ,COUNT(1) AS [cuenta] 
	 ,B.Dato5
	 FROM  @temp A
INNER JOIN ccoCallsOutSource_backup B on A.callout_id=B.callout_id
group by CONVERT(date,A.fecha) 
     ,A.cam_id
     ,B.Dato4
	 ,B.Dato5;

END
