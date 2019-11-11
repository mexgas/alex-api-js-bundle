/****** Object:  Stored Procedure dbo.trsp_GenDuracion    Script Date: 07/10/2009 03:34:54 p.m. ******/




CREATE        PROCEDURE [dbo].[trsp_GenDuracion] 
@finicio as smalldatetime,
@ffin as smalldatetime
AS
DECLARE @query AS VARCHAR(1700)

DELETE FROM trec_gen_duracion WHERE timegroup BETWEEN @finicio AND @ffin


IF EXISTS(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='TREC_MONITOR' and COLUMN_NAME='isIPExt' ) 
BEGIN
	SET @query='insert into trec_gen_duracion ' +
	 'select ' +
	 'CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + '':00'', 121) as timegroup ' + 
	 ', ISNULL(age_id,0),  extension as val ' + 
	 ', sum(case when duracion < 10 then 1 else 0 end) as Menor10 ' + 
	 ', sum(case when duracion between 10 and 19 then 1 else 0 end) as Menor20 ' + 
	 ', sum(case when duracion between 20 and 29 then 1 else 0 end) as Menor30 ' + 
	 ', sum(case when duracion between 30 and 39 then 1 else 0 end) as Menor40 ' + 
	 ', sum(case when duracion between 40 and 49 then 1 else 0 end) as Menor50 ' + 
	 ', sum(case when duracion between 50 and 59 then 1 else 0 end) as Menor60 ' + 
	 'from trec_grabacion grab join trec_monitor mon on extension = mon_extension ' +
	 'where mon.isIPExt = 0 ' + 
	 'and finicio between ''' + CONVERT(VARCHAR(16),@finicio, 120) + ''' and ''' + CONVERT(VARCHAR(16),@ffin, 120) + ''' ' + 
	 'group by age_id,extension,CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + '':00'', 121) ' +
	 'union ' +
	 'select ' + 
	 'CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + '':00'', 121) as timegroup ' + 
	 ', ISNULL(age_id,0),  grab.pos_pc as val ' + 
	 ', sum(case when duracion < 10 then 1 else 0 end) as Menor10 ' + 
	 ', sum(case when duracion between 10 and 19 then 1 else 0 end) as Menor20 ' + 
	 ', sum(case when duracion between 20 and 29 then 1 else 0 end) as Menor30 ' + 
	 ', sum(case when duracion between 30 and 39 then 1 else 0 end) as Menor40 ' + 
	 ', sum(case when duracion between 40 and 49 then 1 else 0 end) as Menor50 ' + 
	 ', sum(case when duracion between 50 and 59 then 1 else 0 end) as Menor60 ' + 
	 'from trec_grabacion grab join trec_monitor mon on grab.pos_pc = mon.pos_pc ' +
	 'where mon.isIPExt = 1 ' +
	 'and finicio between ''' + CONVERT(VARCHAR(16),@finicio, 120) + ''' and ''' + CONVERT(VARCHAR(16),@ffin, 120) + ''' ' + 
	 'group by age_id,grab.pos_pc,CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + '':00'', 121) ' +
	 'order by 1 ' 

	
	exec(@query)
END
ELSE
BEGIN
	 select 
	 CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121) as timegroup 
	 , ISNULL(age_id,0),  extension as val 
	 , sum(case when duracion < 10 then 1 else 0 end) as Menor10 
	 , sum(case when duracion between 10 and 19 then 1 else 0 end) as Menor20 
	 , sum(case when duracion between 20 and 29 then 1 else 0 end) as Menor30 
	 , sum(case when duracion between 30 and 39 then 1 else 0 end) as Menor40 
	 , sum(case when duracion between 40 and 49 then 1 else 0 end) as Menor50 
	 , sum(case when duracion between 50 and 59 then 1 else 0 end) as Menor60 
	 from trec_grabacion grab join trec_monitor mon on extension = mon_extension
	 where mon_extension <> CAST(mon_ext_id AS VARCHAR(20))
	 and finicio between @finicio and @ffin
	 group by age_id,extension,CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121)
	 union
	 select 
	 CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121) as timegroup 
	 , ISNULL(age_id,0),  extension as val 
	 , sum(case when duracion < 10 then 1 else 0 end) as Menor10 
	 , sum(case when duracion between 10 and 19 then 1 else 0 end) as Menor20 
	 , sum(case when duracion between 20 and 29 then 1 else 0 end) as Menor30 
	 , sum(case when duracion between 30 and 39 then 1 else 0 end) as Menor40 
	 , sum(case when duracion between 40 and 49 then 1 else 0 end) as Menor50 
	 , sum(case when duracion between 50 and 59 then 1 else 0 end) as Menor60 
	 from trec_grabacion grab join trec_monitor mon on extension = mon_extension
	 where mon_extension = CAST(mon_ext_id AS VARCHAR(20)) or mon_extension = 'IP'
	 and finicio between @finicio and @ffin
	 group by age_id,extension,CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121)
	 order by 1
END