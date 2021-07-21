USE [CCenterRia]
GO

/******************************************************************************************************
***** Object:  StoredProcedure [dbo].[ccGenConcentradoAgente]    Script Date: 07/16/2021 16:56:43 *****
******************************************************************************************************/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE DBO.ccGenConcentradoAgente
AS
BEGIN

SET NOCOUNT ON;

SET ANSI_WARNINGS OFF;

DECLARE @sql VARCHAR(MAX),@sqls VARCHAR(MAX),@caseND VARCHAR(MAX),@sql2 VARCHAR(8000),@fechai VARCHAR(10),@fechaf VARCHAR(10),@cols VARCHAR(8000)

DECLARE @centro VARCHAR(100),@ip VARCHAR(15)

DECLARE @sqlFinal NVARCHAR(MAX)

SELECT @centro='Marron',@ip='10.246.10.55'

SELECT @fechai=CONVERT(VARCHAR(10),DATEADD(dd,-1,GETDATE()),121),@fechaf=CONVERT(VARCHAR(10),GETDATE(),121)
--select @fechai='2021-05-22', @fechaf='2021-05-24'
DECLARE @notReady TABLE(
	Descripcion       VARCHAR(255)
)

INSERT INTO @notReady
VALUES('DEFAULT')

INSERT INTO @notReady
VALUES('TrabajoAdmvo')

INSERT INTO @notReady
VALUES('FALLA')

INSERT INTO @notReady
VALUES('CAPACITACION')

INSERT INTO @notReady
VALUES('Retroalimentacion')

INSERT INTO @notReady
VALUES('PAUSA GENERAL')

INSERT INTO @notReady
VALUES('PERSONAL')

INSERT INTO @notReady
VALUES('SINCONEXION')

SELECT @cols=COALESCE(@cols,'') + '[' + Descripcion + '],',@sqls=COALESCE(@sqls,'') + 'isnull([' + Descripcion + '],0) [' + Descripcion + '],',
@caseND=COALESCE(@caseND,'') + 'SUM(case when TipoNotReady_id = ' + CAST(TipoNotReady_id AS VARCHAR(3)) + ' then cast(tstatus as int) else 0 end) ['
+ Descripcion + '],'
FROM ccTipoNotReady
WHERE descripcion IN
 (
	SELECT *
	FROM @notReady
 )
ORDER BY Descripcion

SELECT @cols=SUBSTRING(@cols,1,DATALENGTH(@cols) - 1),@sqls=SUBSTRING(@sqls,1,DATALENGTH(@sqls) - 1)

SET @sql='
delete [10.246.10.17].MktReports.dbo.ccConcentradoAgente where fecha = @fechai and Server = @ip

;with logs as (
SELECT CONVERT(VARCHAR(10),fecha,121) AS fecha,MIN(CASE WHEN TipoMov = 1 THEN fecha ELSE NULL END) AS login,MAX(CASE WHEN TipoMov = 0 THEN fecha
	ELSE NULL END) AS logout,user_id        
	FROM ccloglogin WITH (INDEX(IX_ccLogLogin_2),NOLOCK)
	WHERE fecha BETWEEN @fechai AND @fechaf
	GROUP BY CONVERT(VARCHAR(10),fecha,121),user_id
),
--
lo as
(SELECT USER_ID,SUM(CASE WHEN TipoStatusAge_id = 3 THEN tstatus ELSE 0 END) AS tready,SUM(CASE WHEN TipoStatusAge_id = 6 THEN tstatus ELSE 0 END)
	AS tnotas,SUM(CASE WHEN TipoStatusAge_id IN(5,21) THEN tstatus ELSE 0 END) AS totro,CONVERT(VARCHAR(10),fecha,121) AS fecha
	FROM ccLogAgentesDia WITH (INDEX(IX_ccLogAgentesDia),NOLOCK)
	WHERE fecha BETWEEN @fechai AND @fechaf
	GROUP BY USER_ID,CONVERT(VARCHAR(10),fecha,121)
),
--
lon as (
select ' + @caseND +
'
user_id,CONVERT(varchar(10),fecha,121) fecha from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_2),nolock) 
where fecha between @fechai and @fechaf
group by USER_ID,CONVERT(varchar(10),fecha,121)
)
---
,
	Login
	AS (SELECT uid,cam_id,MAX(login) AS login,logout
	    FROM
		(
		    SELECT Login.user_id AS uid,cam_id AS cam_id,fecha AS login,
			(
			    SELECT MIN(subLogin.fecha)
			    FROM ccPosicionCamps AS subLogin --indexDescoment with(index(ix_pc_tipo_fecha_user),nolock)
			    WHERE subLogin.tipo = 0 AND subLogin.fecha > Login.fecha AND subLogin.user_id = Login.user_id AND sublogin.cam_id = Login.cam_id
			) AS logout
		    FROM ccPosicionCamps AS Login --indexComment with(index(ix_pc_tipo_fecha),nolock)
		    WHERE tipo = 1 AND login.fecha >= DATEADD(dd,-2,@fechai)
		    GROUP BY Login.user_id,Login.cam_id,Login.fecha
		) AS LogDet
	    GROUP BY uid,cam_id,logout)
	--
	,
	Detail
	AS (SELECT ccPosicionCamps.user_id AS uid,ccPosicionCamps.cam_id AS cam_id,fecha AS login,Login.logout
	    FROM Login
	    RIGHT OUTER JOIN ccPosicionCamps --indexDescoment with(index(ix_pc_tipo_fecha_user),nolock)
	    ON ccPosicionCamps.user_id = Login.uid AND ccPosicionCamps.fecha = Login.login AND ccPosicionCamps.cam_id = Login.cam_id
	    WHERE tipo = 1 AND ccPosicionCamps.fecha >= DATEADD(dd,-2,@fechai)
	    )
	--
	,
	LoginDet
	AS (SELECT uid,cam_id,login,ISNULL(logout,
		(
		    SELECT MIN(fecha)
		    FROM ccPosicionCamps --indexDescoment with(index(ix_pc_tipo_fecha_user),nolock)
		    WHERE tipo = 1 AND fecha > Detail.login AND user_id = Detail.uid AND cam_id = Detail.cam_id
		)) AS logout
	    FROM Detail)
	---
	,
	CCLOG
	AS (SELECT uid,cam_id,login,MAX(logout) AS logout
	    FROM LoginDet
	    WHERE login >= @fechai AND login < @fechaf
	    GROUP BY uid,cam_id,login)
	----
	,
	LogDet
	AS (SELECT Login.user_id AS uid,Inbound_id,fecha AS login,
		(
		    SELECT MIN(subLogin.fecha)
		    FROM ccPosicionEspecialidad AS subLogin --indexComment with(index(ix_pe_tipo_fecha_user),nolock)
		    WHERE subLogin.tipo = 0 AND subLogin.fecha > Login.fecha AND subLogin.user_id = Login.user_id AND sublogin.Inbound_id = Login.
		    Inbound_id
		) AS logout
	    FROM ccPosicionEspecialidad AS Login --indexComment with(index(ix_pe_tipo_fecha),nolock)
	    WHERE tipo = 1 AND login.fecha >= DATEADD(dd,-2,@fechai)
	    GROUP BY Login.user_id,Login.Inbound_id,Login.fecha)
   ----
   ,co as 
   (
		SELECT 1 AS tipo,USER_ID,COUNT(*) AS ncallsout,0 AS ncalls,0 AS pcalls,AVG(cal_tdialog) AS pcallsout,0 AS tdialog,SUM(cal_tdialog) AS
		tdialogout,CONVERT(VARCHAR(10),cal_inicio,121) AS fecha,co.cam_id AS skill
		FROM ccocallsout AS co WITH (INDEX(IX_ccoCallsOut_2),NOLOCK)
		WHERE cal_inicio BETWEEN @fechai AND @fechaf
		GROUP BY USER_ID,CONVERT(VARCHAR(10),cal_inicio,121),co.cam_id
		UNION
		SELECT 0 AS tipo,USER_ID,0 AS ncallsout,COUNT(*) AS ncalls,AVG(cal_tdialog) AS pcalls,0 AS pcallsout,SUM(cal_tdialog) AS tdialog,0 AS
		tdialogout,CONVERT(VARCHAR(10),cal_inicio,121) AS fecha,ci.inbound_id AS skill
		FROM cccallsin AS ci WITH (INDEX(IX_ccCallsIn),NOLOCK)
		WHERE cal_inicio BETWEEN @fechai AND @fechaf
		GROUP BY USER_ID,CONVERT(VARCHAR(10),cal_inicio,121),ci.inbound_id
	 )
---
	,
	CCLOG2
	AS (SELECT uid,inbound_id,login,MAX(logout) AS logout
	    FROM
		(
		    SELECT uid,inbound_id,login,ISNULL(logout,
			(
			    SELECT MIN(fecha)
			    FROM ccPosicionEspecialidad --indexComment with(index(ix_pe_tipo_fecha_user),nolock)
			    WHERE tipo = 1 AND fecha > Detail.login AND user_id = Detail.uid AND inbound_id = Detail.inbound_id
			)) AS logout
		    FROM
			(
			    SELECT ccPosicionEspecialidad.user_id AS uid,ccPosicionEspecialidad.Inbound_id AS inbound_id,fecha AS login,Login.logout
			    FROM
				(
				    SELECT uid,Inbound_id,MAX(login) AS login,logout
				    FROM LogDet
				    GROUP BY uid,Inbound_id,logout
				) AS Login
			    RIGHT OUTER JOIN ccPosicionEspecialidad --indexComment with(index(ix_pe_tipo_fecha_user),nolock)
			    ON ccPosicionEspecialidad.user_id = Login.uid AND ccPosicionEspecialidad.fecha = Login.login AND ccPosicionEspecialidad.Inbound_id
			    = Login.Inbound_id
			    WHERE tipo = 1 AND ccPosicionEspecialidad.fecha >= DATEADD(dd,-2,@fechai)
			) AS Detail
		) AS LoginDet
	    WHERE login >= @fechai AND login < @fechaf
	    GROUP BY uid,inbound_id,login)
---			
'
SET @sql2=
'insert into [10.246.10.17].MktReports.dbo.ccConcentradoAgente (finsercion,fecha,CentroACD,Server,NombredelAgente,IDconexion,HoraConexion,HoraDesconexion,Splitcampana,Skill,
TiempoconPersonal,LlamadasACD,TiempoPromLlamadas,TiempoACD,TiempoOtraHora,TiempoDisponible,LlamadasSalida,TiempoPromLLamadaSalida,TiempoLlamadaSalida,TiempoACW,' + @cols + ')
--
select convert(smalldatetime,getdate()),logs.fecha, @centro as CentroACD,@ip as Server,
nombres+'' ''+apellidopaterno+'' ''+ apellidomaterno NombredelAgente, 
us.login IDconexion, logs.login HoraConexion, logs.logout HoraDesconexion, 
isnull(split,''Sin campaa'') Splitcampana, 
isnull(log2.Skill,0) Skill, isnull(tlogueo,0) TiempoconPersonal, isnull(ncalls,0) LlamadasACD, isnull(pcalls,0) TiempoPromLlamadas, 
isnull(tdialog,0) TiempoACD,totro TiempoOtraHora,cast(tready as int) TiempoDisponible,
isnull(ncallsout,0) LlamadasSalida, isnull(pcallsout,0) TiempoPromLLamadaSalida, isnull(tdialogout,0) TiempoLlamadaSalida,tnotas TiempoACW,
' + @sqls +
'FROM logs
	JOIN ccUsers AS us(NOLOCK) ON us.User_id = logs.User_id
	LEFT JOIN lo ON lo.User_id = logs.User_id AND lo.fecha = logs.fecha
	LEFT JOIN lon ON lon.user_id = logs.user_id AND lon.fecha = logs.fecha
	LEFT JOIN
	 (
		SELECT fecha,tipo,skill,split,USER_ID,SUM(tlogueo) AS tlogueo
		FROM
		 (
			SELECT CONVERT(VARCHAR(10),cclog.login,121) AS fecha,1 AS tipo,CCLOG.cam_id AS skill,cam_descripcion AS split,CCLOG.uid AS user_id,
			CASE WHEN CONVERT(VARCHAR(10),CCLOG.login,121) = CONVERT(VARCHAR(10),GETDATE(),121) THEN DATEDIFF(ss,CCLOG.login,ISNULL(CCLOG.logout,
			GETDATE())) ELSE DATEDIFF(ss,CCLOG.login,CCLOG.logout) END AS tlogueo
			FROM CCLOG
			JOIN ccCamps AS ca(NOLOCK) ON ca.cam_id = CCLOG.cam_id
    UNION	
-----union ---	 
			SELECT CONVERT(VARCHAR(10),cclog.login,121) AS fecha,0 AS tipo,CCLOG.inbound_id AS skill,descripcion AS split,CCLOG.uid AS user_id,
			CASE WHEN CONVERT(VARCHAR(10),CCLOG.login,121) = CONVERT(VARCHAR(10),GETDATE(),121) THEN DATEDIFF(ss,CCLOG.login,ISNULL(CCLOG.logout,
			GETDATE())) ELSE DATEDIFF(ss,CCLOG.login,CCLOG.logout) END AS tlogueo
			FROM CCLOG2 AS CCLOG
			JOIN ccInbound AS ib(NOLOCK) ON ib.Inbound_id = CCLOG.inbound_id
		 ) AS log3
		GROUP BY fecha,tipo,skill,split,USER_ID
	 ) AS log2 ON log2.user_id = logs.user_id AND log2.fecha = logs.fecha
	LEFT JOIN co ON co.user_id = logs.user_id AND co.tipo = log2.tipo AND co.skill = log2.skill AND co.fecha = logs.fecha
	ORDER BY fecha,skill,NombredelAgente'

SET @sqlFinal=@sql + @sql2

PRINT @sql
PRINT @sql2

EXEC sp_executesql
   @sqlFinal
  ,N'@fechai datetime, @fechaf datetime,@centro VARCHAR(100),@ip VARCHAR(15)'
  ,@fechai
  ,@fechaf
  ,@centro
  ,@ip;

END