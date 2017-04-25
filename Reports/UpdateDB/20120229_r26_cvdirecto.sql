/*
Autor: Armando Rodriguez
Fecha: 2011/02/29
Descripcion: se agrega sp y proceso para reporte de cvdirecto
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '26'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='insert into exp_jobs values (''quarter'',''exec ccenterria.dbo.ccspGenInCDNdelay'',''*N/A*'',1,0,15,''1900-01-01 00:01:00.0'',''1900-01-01 23:59:00.0'',''1111111'','''','''','''','''','''','''',0,'''','''',0,1 )
'
	EXEC(@Sql)

 	set @Sql='insert into exportReports values ( 129, 3, 15,''ccspGenInCDNdelay'',''0'',''1'','''',0)'
	EXEC(@Sql)

 	set @Sql='create PROCEDURE [dbo].[ccspGenInCDNdelay]
AS
DECLARE @from AS smalldatetime
DECLARE @to AS smalldatetime
DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint
DECLARE @tresDelayIn AS smallint

set @from = dateadd(mi,-15,convert(smalldatetime,convert(varchar(14),getdate(),121)+ case when substring(convert(varchar(20),getdate(),121),15,2) >= 0 and substring(convert(varchar(20),getdate(),121),15,2) < 15 then ''00'' when substring(convert(varchar(20),getdate(),121),15,2) >= 15 and substring(convert(varchar(20),getdate(),121),15,2) < 30 then ''15'' when substring(convert(varchar(20),getdate(),121),15,2) >= 30 and substring(convert(varchar(20),getdate(),121),15,2) < 45 then ''30'' when substring(convert(varchar(20),getdate(),121),15,2) >= 45 and substring(convert(varchar(20),getdate(),121),15,2) <= 59 then ''45'' end + '':00'',121))
set @to = dateadd(mi,-0,convert(smalldatetime,convert(varchar(14),getdate(),121)+ case when substring(convert(varchar(20),getdate(),121),15,2) >= 0 and substring(convert(varchar(20),getdate(),121),15,2) < 15 then ''00'' when substring(convert(varchar(20),getdate(),121),15,2) >= 15 and substring(convert(varchar(20),getdate(),121),15,2) < 30 then ''15'' when substring(convert(varchar(20),getdate(),121),15,2) >= 30 and substring(convert(varchar(20),getdate(),121),15,2) < 45 then ''30'' when substring(convert(varchar(20),getdate(),121),15,2) >= 45 and substring(convert(varchar(20),getdate(),121),15,2) <= 59 then ''45'' end + '':00'',121))

EXEC @tresRing = ccenterria.dbo.ccspConfigTresRing
EXEC @tresDialog = ccenterria.dbo.ccspConfigTresDialog
EXEC @tresDelayIn = ccenterria.dbo.ccspConfigtresDelayIn

DELETE FROM ccGenInCDN WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInCDN (timegroup, inbound_id, ntotal, nout_hour, nout_service, nabnd, nno_agent, ntimeout, noverflow, nabnd_xfer, nabnd_ring ,nno_answer, nabnd_dialog, nanswer, nlost)
select fechaCV as timegroup,inbound_id, count(cal_id) ntotal, COUNT(CASE WHEN statuscall_id = 2 THEN 1 ELSE NULL END) AS nout_hour
					, COUNT(CASE WHEN statuscall_id = 3 THEN 1 ELSE NULL END) AS nout_service
					, COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END) AS nabnd, COUNT(CASE WHEN (statuscall_id = 4) THEN 1 ELSE NULL END) AS nno_agent, COUNT(CASE WHEN (statuscall_id = 7) THEN 1 ELSE NULL END) AS ntimeout
					, COUNT(CASE WHEN (statuscall_id = 8) THEN 1 ELSE NULL END) AS noverflow 
					, COUNT(CASE WHEN ((statuscall_id = 11) OR (statuscall_id = 6 AND cal_xfer IS NOT NULL)) THEN 1 ELSE NULL END) AS abnd_xfer
					, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring <= @tresRing)) THEN 1 ELSE NULL END) AS nabnd_ring
					, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring > @tresRing)) THEN 1 ELSE NULL END) AS nno_answer
					, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  <= @tresDialog)) THEN 1 ELSE NULL END) AS nabnd_dialog
					, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS nanswer
					, COUNT(CASE WHEN (statuscall_id = 16) THEN 1 ELSE NULL END) AS nlost from (
select convert(smalldatetime,convert(varchar(14),cal_inicio,121)+ case when substring(convert(varchar(20),cal_inicio,121),15,2) >= 0 and substring(convert(varchar(20),cal_inicio,121),15,2) < 15 then ''00'' when substring(convert(varchar(20),cal_inicio,121),15,2) >= 15 and substring(convert(varchar(20),cal_inicio,121),15,2) < 30 then ''15'' when substring(convert(varchar(20),cal_inicio,121),15,2) >= 30 and substring(convert(varchar(20),cal_inicio,121),15,2) < 45 then ''30'' when substring(convert(varchar(20),cal_inicio,121),15,2) >= 45 and substring(convert(varchar(20),cal_inicio,121),15,2) <= 59 then ''45'' end + '':00'',121) fechaCV,cal_id,dni_id,cal_puerto,inbound_id,statuscall_id,calif_id,cal_tdialog,cal_tring, cal_que, cal_xfer from ccenterria.dbo.cccallsin where cal_inicio > @from and cal_inicio < @to ) a
group by fechaCV,inbound_id
'
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


