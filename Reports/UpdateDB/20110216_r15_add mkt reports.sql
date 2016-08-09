/*
Autor: Armando Rodriguez
Fecha: 2011/02/14
Descripcion: se cambian los sp de reportes de costos y se agregan nuevos sp para los reportes de muñoz
Version requerida: 14
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '15'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='update exp_jobs  set endtime = dateadd(mi,10,starttime) where convert(varchar(8000),writequery) = ''*N/A*'''
	EXEC(@Sql)

 	set @Sql='CREATE PROCEDURE [dbo].[sp_mkt_intervalo_TiemposTotales]
@inb smallint,
@from datetime
AS

declare @to datetime
select @to=convert(varchar(10),dateadd(dd,1,@from),121)

BEGIN

SELECT
convert(varchar(10),fecha,121) [Dia],
c.rango1 [Rango1],
c.rango2 [Rango2],
isnull(sum(g.tnot)/1800,0)  [Prom. Posicion Personal],
isnull(sum(c.ncalls),0) [Llamadas Recibidas],
isnull(sum(c.nacd),0) [Llamadas Atendidas],
isnull(sum(c.nabnd),0) [Llamadas Aban.],
substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then avg(c.tacd) else 0 end),''''),120),15,5) [Tiempo Prom. ACD],
substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then avg(c.tacw) else 0 end),''''),120),15,5) [Tiempo Prom. ACW],
substring(convert(varchar,dateadd(ss,(case when sum(c.thold)>0 then avg(c.thold) else 0 end),''''),120),15,5)[Tiempo Prom. Reten],
isnull(sum(l.SalExt),0) [Llamadas Salida Ext],
substring(convert(varchar,dateadd(ss,(case when sum(l.SalExt)>0 then sum(l.tprosalext)/sum(l.SalExt) else 0 end),''''),120),15,5) [TProm Salida Ext],
substring(convert(varchar,dateadd(ss,isnull(avg(g.tdispon),0),''''),120),15,5) [Tiempo Prom. Dispon],
substring(convert(varchar,dateadd(ss,isnull(avg(c.tring),0),''''),120),15,5) [Tiempo Prom. Ring],
avg(c.tacd+c.tacw+c.tring+c.thold) [AHT]
FROM
	(SELECT 
	CONVERT(datetime, CONVERT(varchar(4),YEAR(i.cal_inicio))+''-''+CONVERT(varchar(2), MONTH(i.cal_inicio))+''-''+CONVERT(varchar(2), DAY(i.cal_inicio))  + '' '' + 	case when CONVERT(int, SUBSTRING(CONVERT(char(30), i.cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''30'' end ,121) as FECHA,
	case when CONVERT(int, SUBSTRING(CONVERT(char(30), i.cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''30'' end as RANGO1,
	case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), i.cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2),CONVERT(int, { fn HOUR(i.cal_inicio) })+1)+'':''+''00'' else CONVERT(varchar(2),CONVERT(int, { fn HOUR(i.cal_inicio) }))+'':''+''30'' end as RANGO2,
	count(i.cal_id) ncalls, 
	count(case when i.statusCall_id=13 then 1 else null end) nacd,
	sum(case when i.statuscall_id = 13 then i.cal_tmoh else 0 end) thold,
	sum(case when i.statuscall_id = 13 then i.cal_tring else 0 end) tring,
	sum(case when i.statusCall_id=13 then i.cal_tdialog else 0 end) tacd,
	sum(case when i.statusCall_id=13 then i.cal_tnotas else 0 end) tacw,
	count(case when (i.statuscall_id IN (5,6) AND (i.cal_que > 0) AND (i.cal_xfer=0)) then 1 else null end) nabnd,
	max(case when i.statuscall_id = 13 then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end) maxdem,
	sum(case when (i.statusCall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer=0)) then i.cal_tWait else 0 end) tcalque
	from cccallsin i (nolock)
	where i.inbound_id=@inb and i.cal_inicio between @from and @to
	GROUP BY 
	CONVERT(datetime,CONVERT(varchar(4),YEAR(cal_inicio))+''-''+CONVERT(varchar(2), MONTH(cal_inicio))+''-''+CONVERT(varchar(2), DAY(cal_inicio))  + '' '' +case when CONVERT(int, SUBSTRING(CONVERT(char(30), cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''30'' end,121),
	case when CONVERT(int, SUBSTRING(CONVERT(char(30), cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''30'' end,
	case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2),CONVERT(int, { fn HOUR(cal_inicio) })+1)+'':''+''00'' else CONVERT(varchar(2),CONVERT(int, { fn HOUR(cal_inicio) }))+'':''+''30'' end	) C
LEFT OUTER JOIN
	(select case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fechaFin), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fechaFin) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fechaFin) })+'':''+''30'' end as rango1,
			COUNT(CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else NULL end) as SalExt,
			SUM(CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else 0 end) as tprosalext
	from ccLogTransfers t (nolock)
		inner join ccCallsIn i (nolock) on (i.cal_id = t.cal_id and i.inbound_id=@inb and i.cal_inicio between @from and @to)
	where t.fechafin between @from and @to
	group by i.inbound_id,case when CONVERT(int, SUBSTRING(CONVERT(char(30),t.fechaFin), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fechaFin) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fechaFin) })+'':''+''30'' end) l
		on L.rango1 = c.rango1
LEFT OUTER JOIN
	(SELECT case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end rango1,
		sum(case t.TipoStatusAge_id when 3 then t.tStatus else 0 end) tdispon,		
		sum(case when t.TipoStatusAge_id not in (2,7,11) then t.tStatus else 0 end) tnot
	from  cclogagentesdia t with (index(ccLogAgentesDia_fecAsc),nolock) join (select distinct user_id from cccallsin (nolock) where inbound_id=@inb and cal_inicio between @from and @to) as x on t.user_id = x.user_id
	where t.fecha between @from and @to 
	group by case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end) g
	on g.rango1 = c.rango1	
group by c.fecha,c.rango1,c.rango2  order by c.fecha
END'
	EXEC(@Sql)

 	set @Sql='CREATE PROCEDURE [dbo].[sp_mkt_intervalo_TiemposAcumuladosTotales]
@inb smallint,
@from datetime
AS

declare @to datetime
select @to=convert(varchar(10),dateadd(dd,1,@from),121)
declare @tresDialog smallint
EXEC @tresDialog= ccspConfigTresDialog

BEGIN

	SELECT
	convert(varchar(10),fecha,121) [Dia],
	c.rango1 [Rango1],
	c.rango2 [Rango2],
	isnull(sum(g.tnot)/1800,0)  [Prom. Posicion Personal],
	isnull(sum(c.ncalls),0) [Llamadas Recibidas],
	isnull(sum(c.nacd),0) [Llamadas Atendidas],
	isnull(sum(c.nabnd),0) [Llamadas Aban.],
	substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then sum(c.tacd) else 0 end),''''),120),15,5) [Tiempo ACD],
	substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then sum(c.tacw) else 0 end),''''),120),15,5) [Tiempo ACW],
	substring(convert(varchar,dateadd(ss,(case when sum(c.thold)>0 then sum(c.thold) else 0 end),''''),120),15,5)[Tiempo Reten],
	isnull(sum(l.SalExt),0) [Llamadas Salida Ext],
	substring(convert(varchar,dateadd(ss,(case when sum(l.SalExt)>0 then sum(l.tprosalext) else 0 end),''''),120),15,5) [Tiempo Salida Ext],
	substring(convert(varchar,dateadd(ss,isnull(sum(g.tdispon),0),''''),120),15,5) [Tiempo Dispon],
	substring(convert(varchar,dateadd(ss,isnull(sum(c.tring),0),''''),120),15,5) [Tiempo Ring],
	avg(c.tacd+c.tacw+c.tring+c.thold) [AHT],
	(sum(ISNULL(abnd_tres,0)+ ISNULL(answ_tres,0)) * 100) /case when sum(den_ns + nabnd ) > 0 then sum(den_ns + nabnd ) else 1 end [% Nivel de Servicio 80/40],
	isnull(sum(nhold),0) [Llamadas Retenidas],
	isnull(sum(nring),0) [Llamadas en Ring]
	FROM
		(SELECT 
		CONVERT(datetime, CONVERT(varchar(4),YEAR(i.cal_inicio))+''-''+CONVERT(varchar(2), MONTH(i.cal_inicio))+''-''+CONVERT(varchar(2), DAY(i.cal_inicio))  + '' '' + 	case when CONVERT(int, SUBSTRING(CONVERT(char(30), i.cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''30'' end ,121) as FECHA,
		case when CONVERT(int, SUBSTRING(CONVERT(char(30), i.cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''30'' end as RANGO1,
		case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), i.cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2),CONVERT(int, { fn HOUR(i.cal_inicio) })+1)+'':''+''00'' else CONVERT(varchar(2),CONVERT(int, { fn HOUR(i.cal_inicio) }))+'':''+''30'' end as RANGO2,
		count(i.cal_id) ncalls, 
		count(case when i.statusCall_id=13 then 1 else null end) nacd,
		sum(case when i.statuscall_id = 13 then i.cal_tmoh else 0 end) thold,
		count(case when (i.statuscall_id = 13) and (i.cal_tmoh > 0) then 1 else null end) nhold,
		sum(case when i.statuscall_id = 13 then i.cal_tring else 0 end) tring,
		count(case when (i.cal_tring > 0) then 1 else null end) nring,
		sum(case when i.statusCall_id=13 then i.cal_tdialog else 0 end) tacd,
		sum(case when i.statusCall_id=13 then i.cal_tnotas else 0 end) tacw,
		count(case when (i.statuscall_id IN (5,6) AND (i.cal_que > 0) AND (i.cal_xfer=0)) then 1 else null end) nabnd,
		max(case when i.statuscall_id = 13 then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end) maxdem,
		sum(case when (i.statusCall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer=0)) then i.cal_tWait else 0 end) tcalque,
		COUNT(CASE WHEN((i.statuscall_id IN(5,6)AND i.cal_que>0 AND i.cal_xfer = 0)AND(cal_twait + cal_txfer + cal_tring<40))THEN 1 ELSE NULL END)AS abnd_tres,
		COUNT(CASE WHEN((i.statuscall_id=13 AND i.cal_tdialog>@tresDialog)AND(i.cal_twait + i.cal_txfer + i.cal_tring<40))THEN 1 ELSE NULL END)AS answ_tres,
		COUNT(CASE WHEN((i.statuscall_id=13)AND(i.cal_tdialog >@tresDialog)) or (i.statuscall_id=4) or (i.statuscall_id=7) or (i.statuscall_id=8) or ((i.statuscall_id=15)AND(cal_tring>3)) or (i.statuscall_id=16)  THEN 1 ELSE NULL END)AS den_ns
		from cccallsin i (nolock)
		where i.inbound_id=@inb and i.cal_inicio between @from and @to
		GROUP BY 
		CONVERT(datetime,CONVERT(varchar(4),YEAR(cal_inicio))+''-''+CONVERT(varchar(2), MONTH(cal_inicio))+''-''+CONVERT(varchar(2), DAY(cal_inicio))  + '' '' +case when CONVERT(int, SUBSTRING(CONVERT(char(30), cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''30'' end,121),
		case when CONVERT(int, SUBSTRING(CONVERT(char(30), cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''30'' end,
		case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2),CONVERT(int, { fn HOUR(cal_inicio) })+1)+'':''+''00'' else CONVERT(varchar(2),CONVERT(int, { fn HOUR(cal_inicio) }))+'':''+''30'' end	) C
	LEFT OUTER JOIN
		(select case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fechaFin), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fechaFin) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fechaFin) })+'':''+''30'' end as rango1,
				COUNT(CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else NULL end) as SalExt,
				SUM(CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else 0 end) as tprosalext
		from ccLogTransfers t (nolock)
			inner join ccCallsIn i (nolock) on (i.cal_id = t.cal_id and i.inbound_id=@inb and i.cal_inicio between @from and @to)
		where t.fechafin between @from and @to
		group by i.inbound_id,case when CONVERT(int, SUBSTRING(CONVERT(char(30),t.fechaFin), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fechaFin) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fechaFin) })+'':''+''30'' end) l
			on L.rango1 = c.rango1
	LEFT OUTER JOIN
		(SELECT case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end rango1,
			sum(case t.TipoStatusAge_id when 3 then t.tStatus else 0 end) tdispon,		
			sum(case when t.TipoStatusAge_id not in (2,7,11) then t.tStatus else 0 end) tnot
		from  cclogagentesdia t with (index(ccLogAgentesDia_fecAsc),nolock) join (select distinct user_id from cccallsin (nolock) where inbound_id=@inb and cal_inicio between @from and @to) as x on t.user_id = x.user_id
		where t.fecha between @from and @to 
		group by case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end) g
		on g.rango1 = c.rango1	
	group by c.fecha,c.rango1,c.rango2  order by c.fecha
END
'
	EXEC(@Sql)

 	set @Sql='CREATE PROCEDURE [dbo].[sp_mkt_diario_tiempostotales]
	    (@Inb INT,
		@from DATETIME,
		@to DATETIME)
AS
BEGIN	
	SELECT 
		login [OPA. ID],
		agt_name [NOMBRE DE OPERADORA],
		AVG(cal_tdialog) [Tiempo prom. de ACD],
		AVG(cal_tnotas) [Tiempo prom. de ACW],
		AVG(cal_tmoh) [Tiempo prom. de retenc],		
		AVG(cal_tring) [Tiempo prom. de Ring],		
		AVG(cal_tdialog+cal_tnotas+cal_tmoh+cal_tring) AHT
	FROM cccallsin i (NOLOCK) LEFT OUTER JOIN	
	(SELECT user_id,login,
		ISNULL(apellidopaterno,'''')+'' ''+ISNULL(apellidomaterno,'''')+'' ''+ISNULL(nombres,'''') agt_name
	FROM ccusers (NOLOCK)) u
	ON i.user_id=u.user_id
	WHERE i.user_id>0 and inbound_id=@inb and statuscall_id=13
		AND	cal_inicio between @from and @to
		GROUP BY agt_name,login
END
'
	EXEC(@Sql)

 	set @Sql='CREATE PROCEDURE [dbo].[sp_mkt_Abandono_Tiempos]
		(@inb AS INT ,
		@from AS DATETIME ,
		@to AS DATETIME) 
AS
BEGIN
	SELECT Fecha
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [5]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [10]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [15]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [20]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [25]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [30]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [40]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [50]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [60]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd > 0 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [>60]
	 FROM	(
			SELECT cal_id
					,CONVERT(VARCHAR(10),cal_inicio,121) AS Fecha
					,SUM(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = 0)) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd 
			 FROM	ccCallsIn
		     WHERE	Inbound_id = @inb AND cal_inicio >= @from AND cal_inicio < @to
			 GROUP BY cal_id,CONVERT(varchar(10),cal_inicio,121)
			) xCalls
	WHERE xCalls.tAbnd > 0
	GROUP BY FECHA
	ORDER BY FECHA ASC
END
'
	EXEC(@Sql)

 	set @Sql='CREATE PROCEDURE [dbo].[sp_mkt_Abandono_Porcentajes]
		(@inb AS INT ,
		@from AS datetime ,
		@to AS datetime) 
AS
BEGIN
	SELECT Fecha
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd >0 AND xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [5]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd >0 AND xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [10]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd >0 AND xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [15]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd >0 AND xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [20]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd >0 AND xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [25]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd >0 AND xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [30]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd >0 AND xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [40]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd >0 AND xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [50]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd >0 AND xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [60]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.tAbnd >0 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [>60]
	 FROM	(
			SELECT cal_id
					,CONVERT(VARCHAR(10),cal_inicio,121) AS Fecha
					,SUM(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = 0)) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd 
			 FROM	ccCallsIn with(index(IX_ccCallsIn),nolock)
			 WHERE	Inbound_id = @inb 
			 AND	cal_inicio >= @from AND cal_inicio < @to
			 GROUP BY cal_id,CONVERT(VARCHAR(10),cal_inicio,121)
			) xCalls
	GROUP BY FECHA
	ORDER BY FECHA ASC
END
'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[A_cwReportOutCtoUser]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4500)='''',
@CblDos as varchar(500) = ''''

AS

declare @cursor as varchar (max)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(4500)
DECLARE @idioma as bit
declare @iva varchar(5)
select @iva=valor from ccsettings where setting_id = 25
select @iva=convert(varchar(5),''1.'' + substring(@iva,(len(@iva)-2),3))

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(max)
DECLARE @nodiponibles as varchar(4000)
DECLARE @sumNoDip as varchar(5000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(max)
DECLARE @sSQLTot as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where tipoLlamada_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select  distinct nr.timegroup, nr.user_id'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
            set @nodiponibles = @nodiponibles+ ''+char(0x27)+'',['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call] as [Llamadas_''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min] as [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min_Facturados], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            --set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.mins,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.costo,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]''+char(0x27)+''

		Fetch Next From CCampos
		Into  @id, @desc
		End
	End

--print @sql
--print @nodiponibles
--print @sumNoDip


CLOSE CCampos 
DEALLOCATE CCampos 
''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.user_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.tipoLlamada_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.tipoLlamada_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT timegroup as Fecha, apellidoPaterno + ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'' ''+char(0x27)+''+ char(0x27)+''+char(0x27)+''+ isNull( apellidoMaterno, ''+char(0x27)+''+ char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'')+ ''+char(0x27)+'' + char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' +char(0x27)+''+char(0x27)+''+  nombres as Agente ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT '' + @sGroupDetail + '' as timegroup, user_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL = @sSQL + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL = @sSQL + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY timegroup, user_id ) a''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', user_id ) xDetail ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+''LEFT JOIN ccUsers ON (xDetail.[user_id]=ccUsers.[user_id]) ) ''+char(0x27)+''''

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT getdate() as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as user_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQLTot = @sSQLTot + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' GROUP BY timegroup, user_id ) a) order by Fecha, Agente''+char(0x27)+''


exec ( @sSQL + @sSQLTot)
--print (@sSQL)
--print (@sSQLTot)
''
if @idioma = 1
begin
--set @cursor = replace(@cursor, ''Sesion'', ''Session'')
set @cursor = replace(@cursor, ''Llamadas'', ''Calls'')
set @cursor = replace(@cursor, ''Min_Facturados'', ''Rated_Min'')
set @cursor = replace(@cursor, ''_CostoIVA'', ''_Tax'')
set @cursor = replace(@cursor, ''_Costo'', ''_Cost'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Agente'', ''Agent'')
end

--print(@cursor)
exec (@cursor)
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[A_cwReportOutCtoCamp]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4000)='''',
@CblDos as varchar(500) = ''''

AS

declare @cursor as varchar (max)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(4500)
DECLARE @idioma as bit
declare @iva varchar(5)
select @iva=valor from ccsettings where setting_id = 25
select @iva=convert(varchar(5),''1.'' + substring(@iva,(len(@iva)-2),3))

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(max)
DECLARE @nodiponibles as varchar(4000)
DECLARE @sumNoDip as varchar(5000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(max)
DECLARE @sSQLTot as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where tipoLlamada_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select  distinct nr.timegroup, nr.cam_id'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
            set @nodiponibles = @nodiponibles+ ''+char(0x27)+'',['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call] as [Llamadas_''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min] as [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min_Facturados], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            --set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
              set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.mins,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.costo,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]''+char(0x27)+''
		Fetch Next From CCampos
		Into  @id, @desc
		End
	End

--print @sql
--print @nodiponibles
--print @sumNoDip


CLOSE CCampos 
DEALLOCATE CCampos 
''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.cam_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.tipoLlamada_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.tipoLlamada_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT timegroup as Fecha, ccCamps.cam_descripcion AS Campana ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT '' + @sGroupDetail + '' as timegroup, cam_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL = @sSQL + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL = @sSQL + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY timegroup, cam_id ) a''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', cam_id ) xDetail ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' LEFT JOIN ccCamps ON (xDetail.cam_id=ccCamps.cam_id) ) ''+char(0x27)+''''

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT getdate() as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as  cam_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQLTot = @sSQLTot + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' GROUP BY timegroup, cam_id ) a) order by Fecha, Campana''+char(0x27)+''


exec ( @sSQL + @sSQLTot)
--print (@sSQL)
--print (@sSQLTot)
''

if @idioma = 1
begin
set @cursor = replace(@cursor, ''Llamadas'', ''Calls'')
set @cursor = replace(@cursor, ''Min_Facturados'', ''Rated_Min'')
set @cursor = replace(@cursor, ''_CostoIVA'', ''_Tax'')
set @cursor = replace(@cursor, ''_Costo'', ''_Cost'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Campana'', ''Campaign'')
end

exec (@cursor)
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[A_cwReportOutCtoProv]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4500)='''',
@CblDos as varchar(500) = ''''
as

declare @cursor as varchar (max)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(4500)
DECLARE @idioma as bit
declare @iva varchar(5)
select @iva=valor from ccsettings where setting_id = 25
select @iva=convert(varchar(5),''1.'' + substring(@iva,(len(@iva)-2),3))

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(max)
DECLARE @nodiponibles as varchar(4000)
DECLARE @sumNoDip as varchar(5000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(max)
DECLARE @sSQLTot as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where tipoLlamada_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select  distinct nr.timegroup, nr.provedor_id'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
            set @nodiponibles = @nodiponibles+ ''+char(0x27)+'',['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call] as [Llamadas_''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min] as [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min_Facturados], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            --set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
	    set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.mins,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.costo,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]''+char(0x27)+''
		Fetch Next From CCampos
		Into  @id, @desc
		End
	End

--print @sql
--print @nodiponibles
--print @sumNoDip


CLOSE CCampos 
DEALLOCATE CCampos 
''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.provedor_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.tipoLlamada_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.tipoLlamada_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT timegroup as Fecha, cstoProvedor.descrip AS Proveedor ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT '' + @sGroupDetail + '' as timegroup, provedor_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL = @sSQL + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL = @sSQL + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY timegroup, provedor_id ) a''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', provedor_id ) xDetail ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' LEFT JOIN cstoProvedor ON (xDetail.provedor_id=cstoProvedor.provedor_id) ) ''+char(0x27)+''''

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT getdate() as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as provedor_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQLTot = @sSQLTot + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' GROUP BY timegroup, provedor_id ) a) order by Fecha, Proveedor''+char(0x27)+''


exec ( @sSQL + @sSQLTot)
--print (@sSQL)
--print (@sSQLTot)
''

if @idioma = 1
begin
set @cursor = replace(@cursor, ''Llamadas'', ''Calls'')
set @cursor = replace(@cursor, ''Min_Facturados'', ''Rated_Min'')
set @cursor = replace(@cursor, ''_CostoIVA'', ''_Tax'')
set @cursor = replace(@cursor, ''_Costo'', ''_Cost'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Proveedor'', ''Supplier'')
end

exec (@cursor)
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInSpecWG]
@from AS smalldatetime,
@to AS smalldatetime
AS
set nocount on
-- Delete previous data in case of reprocess HLAS
DELETE ccGenInSpecWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInSpecWG (timegroup, idwg, pos_tot, pos_time, pos_efect)
SELECT timegroup, wgs.idwg
	, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max -- pos_tot
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
FROM ccGenAgent INNER JOIN 
	(select distinct wg.user_id, wg.idwg, ci.inbound_id from ccRIAWorkGroup_Calid wg, cccallsin ci with(index(IX_ccCallsIn),nolock) where wg.cal_id = ci.cal_id and wg.tipo = 1 and wg.timestamp >= @from AND wg.timestamp < @to)as wgs 
	ON (ccGenAgent.[user_id] = wgs.[user_id])
WHERE timegroup >= @from AND timegroup < @to  AND wgs.idwg > 0
GROUP BY timegroup, wgs.idwg
return(0)
set nocount off
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInCallWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

DELETE FROM ccGenInCallWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInCallWG (timegroup,idwg,ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer
	, nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
SELECT timegroup,idwg,ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
 FROM (SELECT xDetailTime.timegroup, xDetailTime.idwg
			, ISNULL(ntotal, 0) AS ntotal, ISNULL(initial, 0) AS ninitial, ISNULL(out_hour, 0) AS nout_hour, ISNULL(out_service, 0) AS nout_service
			, ISNULL(abnd, 0) AS nabnd, ISNULL(no_agent, 0) AS nno_agent, ISNULL(que, 0) AS nque, ISNULL(timeout, 0) AS ntimeout
			, ISNULL(overflow, 0) AS noverflow, ISNULL(xfer, 0) AS nxfer, ISNULL(xfer_que, 0) AS nxfer_que
			, ISNULL(abnd_xfer, 0) AS nabnd_xfer, ISNULL(abnd_ring, 0) AS nabnd_ring, ISNULL(no_answer, 0) AS nno_answer
			, ISNULL(abnd_dialog, 0) AS nabnd_dialog, ISNULL(answer, 0) AS nanswer, ISNULL(lost, 0) AS nlost, ISNULL(msg, 0) AS nmsg
			, ISNULL(abnd_tres, 0) AS nabnd_tres, ISNULL(answ_tres, 0) AS nansw_tres, ISNULL(tque_max, 0) AS tque_max
			, xDetailTime.tque, xDetailTime.txfer, xDetailTime.tring, xDetailTime.tdialog, xDetailTime.tnotes, ISNULL(tresp, 0) AS tresp,ISNULL(nMoh,0)AS nMoh
			,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM (SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup,wg.idwg
					, COUNT(ci.cal_id) AS ntotal
					, COUNT(CASE WHEN statuscall_id = 1 THEN 1 ELSE NULL END) AS initial
					, COUNT(CASE WHEN statuscall_id = 2 THEN 1 ELSE NULL END) AS out_hour 
					, COUNT(CASE WHEN statuscall_id = 3 THEN 1 ELSE NULL END) AS out_service
					, COUNT(CASE WHEN(statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = ''1900-01-01 00:00:00'')) THEN 1 ELSE NULL END) AS abnd 
					, COUNT(CASE WHEN(statuscall_id = 4) THEN 1 ELSE NULL END) AS no_agent
					, COUNT(CASE WHEN(cal_que > 0) THEN 1 ELSE NULL END) AS que 
					, COUNT(CASE WHEN(statuscall_id = 7) THEN 1 ELSE NULL END) AS timeout
					, COUNT(CASE WHEN(statuscall_id = 8) THEN 1 ELSE NULL END) AS overflow
					, COUNT(CASE WHEN((statuscall_id in (11,15,13,16)) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'')) THEN 1 ELSE NULL END) AS xfer
					, COUNT(CASE WHEN((cal_que > 0) and (statuscall_id in (11,15,13,16) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00''))) THEN cal_xfer ELSE NULL END) AS xfer_que
					, COUNT(CASE WHEN((statuscall_id = 11) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'')) THEN 1 ELSE NULL END) AS abnd_xfer
					, COUNT(CASE WHEN((statuscall_id = 15) AND (cal_tring <= @tresRing)) THEN 1 ELSE NULL END) AS abnd_ring
					, COUNT(CASE WHEN((statuscall_id = 15) AND (cal_tring > @tresRing)) THEN 1 ELSE NULL END) AS no_answer
					, COUNT(CASE WHEN((statuscall_id = 13) AND (cal_tdialog  <= @tresDialog)) THEN 1 ELSE NULL END) AS abnd_dialog
					, COUNT(CASE WHEN((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
					, COUNT(CASE WHEN(statuscall_id = 16) THEN 1 ELSE NULL END) AS lost
					, COUNT(CASE WHEN(statuscall_id IN (9, 10, 12, 14)) THEN 1 ELSE NULL END) AS msg
					, COUNT(CASE WHEN((statuscall_id IN (5,6) AND cal_que > 0 AND cal_xfer = ''1900-01-01 00:00:00'') AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS abnd_tres
					, COUNT(CASE WHEN((statuscall_id = 13 AND cal_tdialog > @tresDialog) AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS answ_tres
					, ISNULL(MAX(cal_twait), 0) AS tque_max,ISNULL(SUM(cal_twait), 0) AS tque
					, ISNULL(SUM(cal_txfer), 0) AS txfer,ISNULL(SUM(cal_tdialog), 0) AS tdialog
					, ISNULL(SUM(cal_tnotas), 0) AS tnotes,ISNULL(SUM(cal_tring), 0) AS tring
					, ISNULL(SUM(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN (cal_twait + cal_txfer + cal_tring) ELSE NULL END), 0) AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
					,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock), ccRIAWorkGroup_Calid wg
					WHERE wg. cal_id = ci.cal_id and wg.tipo = 1 and cal_inicio >= @fromExtended AND  cal_inicio < @to AND wg.idwg > 0
				 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), wg.idwg
			) xDetailCount
			LEFT JOIN
			(
				SELECT timegroup
					, idwg
					, ISNULL(SUM(cal_twait), 0) AS tque
					, ISNULL(SUM(cal_txfer), 0) AS txfer
					, ISNULL(SUM(cal_tring), 0) AS tring
					, ISNULL(SUM(cal_tdialog), 0) AS tdialog
					, ISNULL(SUM(cal_tnotas), 0) AS tnotes
				 FROM (	SELECT timegroup, idwg
						, CASE WHEN time_endque < timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss, timegroup_next, time_endque) END AS cal_twait
						, CASE WHEN (time_ring < timegroup_next) THEN cal_txfer WHEN ((time_ring >= timegroup_next) AND (time_endque < timegroup_next)) THEN cal_txfer - DATEDIFF(ss, timegroup_next, time_ring) ELSE 0 END  AS cal_txfer
						, CASE WHEN (time_dialog < timegroup_next) THEN cal_tring WHEN ((time_dialog >= timegroup_next) AND (time_ring < timegroup_next)) THEN cal_tring - DATEDIFF(ss, timegroup_next, time_dialog) ELSE 0 END  AS cal_tring
						, CASE WHEN (time_notes < timegroup_next) THEN cal_tdialog WHEN ((time_notes >= timegroup_next) AND (time_dialog < timegroup_next)) THEN cal_tdialog - DATEDIFF(ss, timegroup_next, time_notes) ELSE 0 END  AS cal_tdialog
						, CASE WHEN (time_end_call < timegroup_next) THEN cal_tnotas WHEN ((time_end_call >= timegroup_next) AND (time_notes < timegroup_next)) THEN cal_tnotas - DATEDIFF(ss, timegroup_next, time_end_call) ELSE 0 END  AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
								, DATEADD(hh, 1, CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121))  AS timegroup_next
								, DATEADD(ss, cal_twait, cal_inicio)  AS time_endque
								, DATEADD(ss, cal_twait + cal_txfer, cal_inicio)  AS time_ring
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring, cal_inicio)  AS time_dialog
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_inicio)  AS time_notes
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas, cal_inicio)  AS time_end_call
								, ci.*, wg.idwg
							FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock), ccRIAWorkGroup_Calid wg
							WHERE wg.cal_id = ci.cal_id and wg.tipo = 1 and cal_inicio >= @fromExtended AND  cal_inicio < @to  AND wg.idwg > 0
						) xDetail
					UNION
					SELECT timegroup_next, idwg
						, CASE WHEN time_endque >= timegroup_next THEN DATEDIFF(ss, timegroup_next, time_endque) ELSE 0 END AS cal_twait
						, CASE WHEN (time_ring < timegroup_next) THEN 0 WHEN ((time_ring >= timegroup_next) AND (time_endque < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_ring) ELSE cal_txfer END AS cal_txfer
						, CASE WHEN (time_dialog < timegroup_next) THEN 0 WHEN ((time_dialog >= timegroup_next) AND (time_ring < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_dialog) ELSE cal_tring END AS cal_tring
						, CASE WHEN (time_notes < timegroup_next) THEN 0 WHEN ((time_notes >= timegroup_next) AND (time_dialog < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_notes) ELSE cal_tdialog END AS cal_tdialog
						, CASE WHEN (time_end_call < timegroup_next) THEN 0 WHEN ((time_end_call >= timegroup_next) AND (time_notes < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_end_call) ELSE cal_tnotas END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
								, DATEADD(hh, 1, CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121))  AS timegroup_next
								, DATEADD(ss, cal_twait, cal_inicio)  AS time_endque
								, DATEADD(ss, cal_twait + cal_txfer, cal_inicio)  AS time_ring
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring, cal_inicio)  AS time_dialog
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_inicio)  AS time_notes
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas, cal_inicio)  AS time_end_call
								, ci.*, wg.idwg
							FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock), ccRIAWorkGroup_Calid wg
							WHERE wg.cal_id = ci.cal_id and wg.tipo = 1 and cal_inicio >= @fromExtended AND  cal_inicio < @to  AND wg.idwg > 0
						) xDetail
					) xTimeDetail
				 GROUP BY timegroup, idwg
			) xDetailTime
			ON (xDetailTime.timegroup = xDetailCount.timegroup AND xDetailTime.idwg = xDetailCount.idwg)
	) xComplete
 WHERE timegroup >= @from AND  timegroup < @to
	AND NOT (ntotal = 0 AND nout_hour = 0 AND nout_service = 0 AND nabnd = 0 AND nno_agent = 0 AND nque = 0
		 AND ntimeout = 0 AND noverflow = 0 AND nxfer = 0 AND nxfer_que = 0 AND nabnd_xfer = 0 AND nabnd_ring = 0
		 AND nno_answer = 0 AND nabnd_dialog = 0 AND nanswer = 0 AND nlost = 0 AND nmsg = 0 AND nabnd_tres = 0
		 AND nansw_tres = 0 AND tque_max = 0 AND tque = 0 AND txfer = 0 AND tring = 0 AND tdialog = 0 AND tnotes = 0 AND tresp = 0)
 ORDER BY timegroup, idwg
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInCalifWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenInCalifWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInCalifWG (timegroup, idwg, calif_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, wg.idwg, calif_id, COUNT(cal_inicio)
 FROM ccCallsIN ci with(index(IX_ccCallsIn),nolock), ccRIAworkgroup_calid wg
 WHERE cal_inicio >= @from AND  cal_inicio < @to
 AND statuscall_id = 13 and ci.cal_id = wg.cal_id and wg.tipo = 1
AND wg.idwg > 0
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), wg.idwg, calif_id
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInAnswWG]
@from AS smalldatetime,
@to AS smalldatetime
AS
DECLARE @tresDialog AS smallint

EXEC @tresDialog = ccspConfigTresDialog

DELETE ccGenInAnswWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInAnswWG (timegroup, idwg, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
	SELECT timegroup
		, idwg
		, COUNT(cal_inicio) AS amount
		, MAX(tAnsw) AS time_max
		, SUM(tAnsw) AS time_tot
		, COUNT(CASE WHEN tAnsw < 10  THEN 1 ELSE NULL END) as [<10]
		, COUNT(CASE WHEN tAnsw BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [<20]
		, COUNT(CASE WHEN tAnsw BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [<30]
		, COUNT(CASE WHEN tAnsw BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [<40]
		, COUNT(CASE WHEN tAnsw BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [<50]
		, COUNT(CASE WHEN tAnsw BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [<60]
		, COUNT(CASE WHEN tAnsw BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [<120]
		, COUNT(CASE WHEN tAnsw BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [<180]
		, COUNT(CASE WHEN tAnsw BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [<240]
		, COUNT(CASE WHEN tAnsw BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [<300]
		, COUNT(CASE WHEN tAnsw >= 300  THEN 1 ELSE NULL END) as [+300]
	 FROM	(
			SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
				, cal_inicio
				, wg.idwg
				, statuscall_id
				, (CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
				, (cal_twait + cal_txfer + cal_tring) AS tAnsw
			 FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock), ccRIAWorkGroup_Calid wg
				WHERE cal_inicio >= @from AND  cal_inicio < @to and wg.cal_id = ci.cal_id and wg.tipo = 1
				AND wg.idwg > 0
		) xCalls
	 WHERE (answer IS NOT NULL)
	 GROUP BY timegroup, idwg
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInAbndWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenInAbndWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInAbndWG (timegroup, idwg, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
	SELECT timegroup
		, idwg
		, COUNT(cal_inicio) AS amount
		, MAX(tAbnd) AS time_max
		, SUM(tAbnd) AS time_tot
		, COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [<10]
		, COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [<20]
		, COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [<30]
		, COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [<40]
		, COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [<50]
		, COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [<60]
		, COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [<120]
		, COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [<180]
		, COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [<240]
		, COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [<300]
		, COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [+300]
	 FROM	(
			SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
				, cal_inicio
				, wg.idwg
				, statuscall_id
				, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
				, (cal_twait + cal_txfer + cal_tring) AS tAbnd
			 FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock), ccRIAWorkGroup_Calid wg
				WHERE cal_inicio >= @from AND  cal_inicio < @to and wg.cal_id = ci.cal_id and wg.tipo = 1
				AND wg.idwg > 0
		) xCalls
	WHERE (abnd IS NOT NULL) 
	 GROUP BY timegroup, idwg
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCampWG]
@from AS smalldatetime,
@to AS smalldatetime
AS
set nocount on


declare @to2 as smalldatetime

declare @from2 as smalldatetime


SELECT @to2 = @to 

SELECT @from2 = @from

DELETE ccGenOutCampWG WHERE timegroup >= @from2 AND timegroup < @to2

INSERT INTO ccGenOutCampWG (timegroup, idwg, pos_tot, pos_time, pos_efect)
SELECT timegroup, idwg
	, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
FROM ccGenAgent INNER JOIN 
	(select distinct wg.user_id, wg.idwg, co.cam_id from ccRIAWorkGroup_Calid wg, ccocallsout co with(index(IX_ccoCallsOut_2),nolock) where wg.cal_id = co.cal_id and wg.tipo = 0 and co.cal_inicio >= @from2 AND co.cal_inicio < @to2)as wgs 
	ON (ccGenAgent.[user_id] = wgs.[user_id])
WHERE timegroup >= @from2 AND timegroup < @to2
GROUP BY timegroup, idwg

return(0)
set nocount off
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCallWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DECLARE @HourExtend AS smallint
SELECT @HourExtend=2
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog

DELETE FROM ccGenOutCallWG WHERE timegroup>=@from AND timegroup<@to

INSERT INTO ccGenOutCallWG (timegroup,idwg,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl)
SELECT timegroup,idwg,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
 FROM(		
		SELECT xDetailTime.timegroup,xDetailTime.idwg
			,ISNULL(ntotal,0)AS ntotal
			,ISNULL(no_agent,0)AS nno_agent,ISNULL(xfer,0)AS nxfer
			,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost
			,xDetailTime.txfer,xDetailTime.tring
			,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp
			,ISNULL(hung_up,0)AS nhangup,ISNULL(nMoh,0) as nMoh,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM(	 
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,wg.idwg
					,COUNT(co.cal_id)AS ntotal
					,COUNT(CASE WHEN(statuscall_id=6)THEN co.cal_id ELSE NULL END)AS hung_up --NO se usa,así que es igual a total para las llamadas sin agente asignada(->agente 0)
					,COUNT(CASE WHEN(statuscall_id=4)THEN co.cal_id ELSE NULL END)AS no_agent
					,COUNT(CASE WHEN(statuscall_id>=10)THEN co.cal_id ELSE NULL END)AS xfer
					,COUNT(CASE WHEN(statuscall_id=11)THEN co.cal_id ELSE NULL END)AS abnd_xfer
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN co.cal_id ELSE NULL END)AS abnd_ring
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN co.cal_id ELSE NULL END)AS no_answer
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN co.cal_id ELSE NULL END)AS abnd_dialog
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN co.cal_id ELSE NULL END)AS answer
					,COUNT(CASE WHEN(statuscall_id=16)THEN co.cal_id ELSE NULL END)AS lost
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
					,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccoCallsOut co with(index(IX_ccoCallsOut_2),nolock), ccRIAworkgroup_calid wg
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to and co.cal_id = wg.cal_id and wg.tipo = 0
					-- para contar bien las llamadas manuales
					and cal_manual in(0,2)
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),wg.idwg
			)xDetailCount
			LEFT JOIN
			(SELECT timegroup
					, idwg
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(cal_tring),0)AS tring
					,ISNULL(SUM(cal_tdialog),0)AS tdialog
					,ISNULL(SUM(cal_tnotas),0)AS tnotes
				 FROM(	SELECT timegroup,0 as idwg
						,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call								,*
							FROM ccoCallsOut co with(index(IX_ccoCallsOut_2),nolock)
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							and cal_manual in(0,2)
						)xDetail
					UNION
					SELECT timegroup_next, idwg
						,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 AS time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
								,co.* , wg.idwg
							FROM ccoCallsOut co with(index(IX_ccoCallsOut_2),nolock), ccRIAworkgroup_calid wg
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to and co.cal_id = wg.cal_id and wg.tipo = 0
							and cal_manual in(0,2)
						)xDetail
					)xTimeDetail
				 GROUP BY timegroup, idwg
			)xDetailTime
			ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.idwg=xDetailCount.idwg)
	)xComplete
 WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nno_agent=0
		 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		 AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
 ORDER BY timegroup,idwg
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCallDialsWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenOutCallDialsWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCallDialsWG (timegroup, idwg, [puerto], tiporesdial_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + '':00'', 121) AS timegroup
	, idwg, puerto, tiporesdial_id
	, COUNT(*)
 FROM ccologdials ld with(index(IX_ccoLogDials),nolock), ccRIAWorkGroup_logDial_id wg
 WHERE fecha >= @from AND  fecha < @to
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + '':00'', 121), idwg, [puerto], tiporesdial_id
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCallCalifWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenOutCallCalifWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCallCalifWG (timegroup, idwg, calif_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup, wg.idwg, calif_id, COUNT(*)
 FROM ccoCallsOut co with(index(IX_ccoCallsOut_2),nolock), ccRIAworkgroup_calid wg
 WHERE cal_inicio >= @from AND  cal_inicio < @to and co.cal_id = wg.cal_id and wg.tipo = 0
 AND statuscall_id = 13
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), wg.idwg, calif_id
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[A_cwRepNotReady]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(4000)='''',
@CblDos as varchar(1500) = ''''

AS
declare @cursor as varchar (Max)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(max)
DECLARE @idioma as bit

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(max)
DECLARE @sql2 as varchar(max)
DECLARE @nodiponibles as varchar(max)
DECLARE @sumNoDip as varchar(max)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)
DECLARE @totalC as varchar(250)
DECLARE @totalT as varchar(250)

DECLARE @sSQL as varchar(max)
DECLARE @sSQL2 as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select TipoNotReady_id, Descripcion from ccTipoNotReady
''
    end
    else
    begin
	set @cursor = @cursor +''select TipoNotReady_id, Descripcion from ccTipoNotReady where TipoNotReady_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select distinct nr.user_id, nr.timegroup,'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + '' dbo.fGetHHmmSS (Sesion) Sesion''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + '' sum(Sesion) Sesion ''+char(0x27) + ''
set @totalC = ''+char(0x27) + '', sum (0''+char(0x27) + ''
set @totalT = ''+char(0x27) + '', sum (0''+char(0x27) + ''
set @sql = @sql+ ''+char(0x27) + '' (select isnull(SUM(tlog),'' +char(0x27)+''+ char(0x27) + char(0x27) +'' +char(0x27)+'') from ccGenAgent where user_id = nr.user_id and timegroup =  nr.timegroup ) Sesion ''+char(0x27) + ''
set @sql2 =  ''+char(0x27) +char(0x27) + ''

Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
                set @totalC = @totalC + ''+char(0x27)+''+ sum([''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto])'' +char(0x27) + ''
                set @totalT = @totalT + ''+char(0x27)+''+ sum([''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo])'' +char(0x27) + ''
                set @nodiponibles = @nodiponibles+ ''+char(0x27)+'', ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto], dbo.fGetHHmmSS ([''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]) [''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
                set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
				if @id  < 35
				begin
					set @sql = @sql+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amountReal,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto]''+char(0x27)+''
					set @sql = @sql+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(time,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
			    end
			    else
			    begin
			    	set @sql2 = @sql2+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amountReal,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto]''+char(0x27)+''
					set @sql2 = @sql2+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(time,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
			    end
			
			Fetch Next From CCampos
			Into  @id, @desc
		End
	End

--print @sql
--print @nodiponibles
--print @sumNoDip


CLOSE CCampos 
DEALLOCATE CCampos 
''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''  timegroup,''
   set @sGroup = ''timegroup ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
--   set @sGroupDetail = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121), ''
 --  set @sGroup = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121) ''
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121), ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''

end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
   set @sGroupDetail = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121), ''
   set @sGroup = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121) ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' [user_id] in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and tiponotready_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' tiponotready_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + ''set @sSQL = ''+char(0x27)+''SELECT Login, timegroup as Fecha, apellidoPaterno + ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'' ''+char(0x27)+''+ char(0x27)+''+char(0x27)+''+ isNull( apellidoMaterno, ''+char(0x27)+''+ char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'')+ ''+char(0x27)+'' + char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' +char(0x27)+''+char(0x27)+''+  nombres as Agente, ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT ''+ @sGroup +'' as timegroup , [user_id], ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL2 = @sql2+  ''+char(0x27)+'' FROM ccGenAgentNotReady as nr WHERE timegroup >= ''+char(0x27)+'' + char(0x27) + '' +char(0x27)+ @fini +char(0x27)+ '' + char(0x27) + ''+char(0x27)+'' AND timegroup < ''+char(0x27)+'' + char(0x27) + '' +char(0x27)+ @ffin +char(0x27)+ '' + char(0x27) 
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL2 = @sSQL2 + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY  nr.timegroup, [user_id] ) as a WHERE timegroup >= ''+char(0x27)+'' + char(0x27)+ '' +char(0x27)+ @fini +char(0x27)+ ''+ char(0x27)+ ''+char(0x27)+'' AND timegroup < ''+char(0x27)+'' + char(0x27)+ '' +char(0x27)+ @ffin +char(0x27)+ '' + char(0x27) + ''+char(0x27)+''''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '' [user_id]  ) xDetail ''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' INNER JOIN ccUsers ON (xDetail.[user_id]=ccUsers.[user_id]) AND ccUsers.filter = 1 ORDER BY Fecha, Agente ''+char(0x27)+''

exec ( @sSQL + @sSQL2)
--print (@sSQL)
--print (@sSQL2)
''
if @idioma = 1
begin
set @cursor = replace(@cursor, ''Sesion'', ''Session'')
set @cursor = replace(@cursor, ''_Monto'', ''_Count'')
set @cursor = replace(@cursor, ''_Tiempo'', ''_Time'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Agente'', ''Agent'')
end

--print (@cursor)
exec (@cursor)
'
	EXEC(@Sql)

 	set @Sql=''
	EXEC(@Sql)

 	set @Sql=''
	EXEC(@Sql)


------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC]
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off


