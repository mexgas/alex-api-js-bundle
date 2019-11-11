CREATE PROCEDURE [dbo].[ccspGenDetCall]
@tipo as integer
AS

SET NOCOUNT ON

declare @server varchar(200)
declare @sql  varchar(8000)
declare @from datetime
declare @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ ':00',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ ':00',121)

SET ARITHABORT ON

if @tipo = 0
begin

-- Borra tabla destino
set @sql = 'DELETE '+@server+'.dbo.ccocallsout WHERE cal_inicio >= '+ char(0x27) + convert(varchar(20),@from,120) + char(0x27) +' AND cal_inicio < ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
--print @sql
--exec (@sql)

set @sql = 'insert into ' + @server +'.dbo.ccocallsout (cal_id,callout_id, cal_telefono, cal_puerto,cam_id, user_id, cal_extension,cal_colgada,cal_key,statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,cal_tlinebusy,costo,provedor_id,tipollamada_id) '
set @sql = @sql + 'select cal_id,callout_id, cal_telefono, cal_puerto,cam_id, user_id, cal_extension,cal_colgada,cal_key,statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,cal_tlinebusy,costo,provedor_id,tipollamada_id from ccocallsout WHERE cal_id > (select isnull(max(cal_id),1) from ' + @server +'.dbo.ccocallsout) and cal_id<= (select min(cal_id) from ccocallsout with(index (IX_ccoCallsOut_2)) where cal_inicio > ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + ')'
--print @sql
exec(@sql)

-- Borra tabla destino
set @sql = 'DELETE '+@server+'.dbo.cccallsin WHERE cal_inicio >= '+ char(0x27) + convert(varchar(20),@from,120) + char(0x27) +' AND cal_inicio < ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
--print @sql
--exec (@sql)

set @sql = 'insert into ' + @server +'.dbo.cccallsin (cal_id,dni_id, cal_ani, cal_puerto,inbound_id, user_id, cal_extension,cal_colgada,cal_key,statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_twait,cal_txfer,cal_tcall,cal_tring,cal_xfer,cal_inicio,cal_opciones,cal_origin_id) '
set @sql = @sql + 'select cal_id,dni_id, cal_ani, cal_puerto,inbound_id, user_id, cal_extension,cal_colgada,cal_key,statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_twait,cal_txfer,cal_tcall,cal_tring,cal_xfer,cal_inicio,cal_opciones,cal_origin_id from cccallsin WHERE cal_id > (select isnull(max(cal_id),1) from ' + @server +'.dbo.cccallsin) and cal_id<= (select min(cal_id) from cccallsin with(index (IX_ccCallsIn)) where cal_inicio > ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + ')'
--print @sql
exec(@sql)

-- Borra tabla destino
set @sql = 'DELETE '+@server+'.dbo.ccLogAgentesNotReady WHERE fecha >= '+ char(0x27) + convert(varchar(20),@from,120) + char(0x27) +' AND fecha < ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
--print @sql
--exec (@sql)

set @sql = 'insert into ' + @server +'.dbo.ccLogAgentesNotReady (user_id,tiponotready_id,tStatus,fecha,separado) '
set @sql = @sql + 'select user_id,tiponotready_id,tStatus,fecha,separado from ccLogAgentesNotReady where fecha >= (select max(fecha) from ' + @server +'.dbo.ccLogAgentesNotReady) AND fecha < ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
--print @sql
exec(@sql)

-- Borra tabla destino
set @sql = 'DELETE '+@server+'.dbo.ccologdials WHERE fecha >= '+ char(0x27) + convert(varchar(20),@from,120) + char(0x27) +' AND fecha < ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
--print @sql
--exec (@sql)

set @sql = 'insert into ' + @server +'.dbo.ccologdials (logdial_id,callout_id,cam_id,tiporesdial_id,telefono,puerto,fecha,tdialing,tbusy,answerbit) '
set @sql = @sql + 'select logdial_id,callout_id,cam_id,tiporesdial_id,telefono,puerto,fecha,tdialing,tbusy,answerbit from ccologdials where logDial_ID > (select isnull(max(logDial_ID),0) from ' + @server +'.dbo.ccoLogDials)AND logDial_ID <= (select min(logDial_ID) from ccoLogDials with(index (IX_ccoLogDials)) where fecha > ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + ')'
--print @sql
exec(@sql)

-- Borra tabla destino
set @sql = 'DELETE '+@server+'.dbo.ccoCallsOutSource WHERE cal_fechadial >= '+ char(0x27) + convert(varchar(20),@from,120) + char(0x27) +' AND cal_fechadial < ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
--print @sql
--exec (@sql)

set @sql = 'insert into ' + @server +'.dbo.ccoCallsOutSource (callout_id,cal_key,cam_id,cal_fechaDial) '
set @sql = @sql + 'select callout_id,cal_key,cam_id,cal_fechaDial from ccoCallsOutSource where callout_id > (select max(callout_id) from ' + @server +'.dbo.ccocallsoutsource) AND cal_fechadial < ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
--print @sql
exec(@sql)

end

if @tipo = 1
begin

set @from = convert(smalldatetime,convert(varchar(11),getdate(),121)+ '06:00:00',121)
set @to = convert(smalldatetime,convert(varchar(11),getdate(),121)+ '23:00:00',121)


set @sql = 'Update rept set rept.calif_id = cc.calif_id, rept.cal_tdialog = cc.cal_tdialog from ' + @server +'.dbo.ccocallsout rept, ccocallsout cc where rept.cal_tdialog = 0 and rept.cal_inicio >= ' + char(0x27) +  convert(varchar(20),@from,120) + char(0x27) + ' and rept.cal_inicio < ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + ' and rept.user_id <> 0 and rept.calif_id = 0 and rept.cal_manual <> 1 and rept.user_id = cc.user_id and rept.cal_id = cc.cal_id'
--print @sql
exec(@sql)


set @sql = 'Update rept set rept.calif_id = cc.calif_id, rept.cal_tdialog = cc.cal_tdialog from ' + @server +'.dbo.cccallsin rept, cccallsin cc where rept.cal_tdialog = 0 and rept.cal_inicio >= ' + char(0x27) +  convert(varchar(20),@from,120) + char(0x27) + ' and rept.cal_inicio < ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + ' and rept.user_id <> 0 and rept.calif_id = 0 and rept.user_id = cc.user_id and rept.cal_id = cc.cal_id'
--print @sql
exec(@sql)

set @sql = 'update rept set rept.tstatus = cc.tstatus from ' + @server +'.dbo.cclogagentesNotReady rept, cclogagentesnotready cc where rept.tstatus = 0 and rept.fecha >= ' + char(0x27) +  convert(varchar(20),@from,120) + char(0x27) + ' and rept.fecha < ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + ' and rept.user_id = cc.user_id and rept.tiponotready_id = cc.tiponotready_id and rept.fecha = cc.fecha'
--print @sql
exec(@sql)

set @sql = 'Update rept set rept.tdialing = cc.tdialing from ' + @server +'.dbo.ccologdials rept, ccologdials cc where cc.logdial_id = rept.logdial_id and rept.tdialing = 0 and rept.fecha >= ' + char(0x27) +  convert(varchar(20),@from,120) + char(0x27) + ' and rept.fecha < ' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
--print @sql
exec(@sql)

end