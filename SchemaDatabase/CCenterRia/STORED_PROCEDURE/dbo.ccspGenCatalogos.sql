CREATE PROCEDURE [dbo].[ccspGenCatalogos]
@server AS varchar(200)
AS
SET NOCOUNT ON
declare @sql  varchar(8000)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccUsers' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccCalifCamp' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccCamps' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccCampsAgente' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccInbound' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccStatusLlamada' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccSupervisorCam' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccTipoCalif' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccTipoCalifOUT' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccTipoNotReady' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccTipoStatusAgente' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccInboundAgentes' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccTipoResultadoDial' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table cstoProvedor' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccPosicion' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccDNIS' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table cstoTipoLlamada' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccodialers' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table cstoTarifa' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccriacat_workgroup' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccRIAWorkGroupUsers' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccRIACat_Areas' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccRIAAreaWorkGroup' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table telefonostransferencia' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table telefonosConferencia' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table ccCallsReject' + char(39)
--print @sql
exec(@sql)

set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table cctipocalifsub' + char(39)
--print @sql
exec(@sql)
set @sql = @server + '.dbo.sp_executesql N' + char(39) + 'truncate table cctipocalifsubout' + char(39)
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccCalifCamp (calif_id, cam_id, tipo) '
set @sql = @sql + 'select calif_id, cam_id, tipo from ccCalifCamp'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccUsers (User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,Password,TipoUser_id,Status,TipoLLamadas,Sexo,filter,CanChangeStatus,fCreate,DialMask,xFerMask,LastPasswordChange) '
set @sql = @sql + 'select User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,Password,TipoUser_id,Status,TipoLLamadas,Sexo,filter,CanChangeStatus,fCreate,DialMask,xFerMask,LastPasswordChange from ccUsers'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccUsers (User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,Password,TipoUser_id,Status,TipoLLamadas,Sexo,filter,CanChangeStatus,fCreate,DialMask,xFerMask,LastPasswordChange) '
set @sql = @sql + 'select User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,Password,TipoUser_id,Status,TipoLLamadas,Sexo,filter,CanChangeStatus,fCreate,DialMask,xFerMask,LastPasswordChange from ccUsers_Consulta'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccCamps (cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, cam_inter_'

set @sql = @sql + 'ocupado, cam_inter_nocontesto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql, cam_tnotas, cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_t'
set @sql = @sql + 'DialBeforeWU, cam_tDialBeforeReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, cam_fCreate, cam_MaxDlrXage, ani) '
set @sql = @sql + 'select cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, cam_inter_ocupado, cam_inter_noconte'
set @sql = @sql + 'sto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql, cam_tnotas, cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_tDialBeforeWU, cam_tDialBef'
set @sql = @sql + 'oreReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, cam_fCreate, cam_MaxDlrXage, ani from ccCamps'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccCamps (cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, cam_inter_'

set @sql = @sql + 'ocupado, cam_inter_nocontesto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql, cam_tnotas, cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_t'
set @sql = @sql + 'DialBeforeWU, cam_tDialBeforeReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, cam_fCreate, cam_MaxDlrXage, ani) '
set @sql = @sql + 'select cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, cam_inter_ocupado, cam_inter_noconte'
set @sql = @sql + 'sto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql, cam_tnotas, cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_tDialBeforeWU, cam_tDialBef'
set @sql = @sql + 'oreReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, cam_fCreate, cam_MaxDlrXage, ani from ccCamps_Consulta'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccCampsAgente (user_id, cam_id, prioridad, skill) '
set @sql = @sql + 'select distinct user_id, cam_id, prioridad, skill from ccCampsAgente'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccInbound (cli_id,Inbound_id,descripcion,Status,dnis,standby,tNotas,tMaxWaitCall,nMaxQue,Msg_id,tel_maxwait,tel_maxqueue,tel_outservice,tel_noct,bnocturno,ShowCalifWnd,StartTimerOnHangUp,voicePath)'
set @sql = @sql + 'select isnull(cli_id,0) cli_id,Inbound_id,descripcion,Status,dnis,standby,tNotas,tMaxWaitCall,nMaxQue,Msg_id,tel_maxwait,tel_maxqueue,tel_outservice,tel_noct,bnocturno,ShowCalifWnd,StartTimerOnHangUp,voicePath from ccInbound'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccInbound (cli_id,Inbound_id,descripcion,Status,dnis,standby,tNotas,tMaxWaitCall,nMaxQue,Msg_id,tel_maxwait,tel_maxqueue,tel_outservice,tel_noct,bnocturno,ShowCalifWnd,StartTimerOnHangUp,voicePath)'
set @sql = @sql + 'select isnull(cli_id,0) cli_id,Inbound_id,descripcion,Status,dnis,standby,tNotas,tMaxWaitCall,nMaxQue,Msg_id,tel_maxwait,tel_maxqueue,tel_outservice,tel_noct,bnocturno,ShowCalifWnd,StartTimerOnHangUp,voicePath from ccInbound_Consulta'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccStatusLlamada (statusCall_id,descripcion) '
set @sql = @sql + 'select statusCall_id,descripcion from ccStatusLlamada'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccSupervisorCam (user_id,cam_id,tipo) '
set @sql = @sql + 'select distinct user_id,cam_id,tipo from ccSupervisorCam'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccTipoCalif (calif_id,Description,orden) '
set @sql = @sql + 'select calif_id,Description,orden from ccTipoCalif'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccTipoCalifOUT (calif_id,Description,autoTime,CanReprogram,orden) '
set @sql = @sql + 'select calif_id,Description,autoTime,CanReprogram,orden from ccTipoCalifOUT'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccTipoNotReady (TipoNotReady_id,Descripcion) '
set @sql = @sql + 'select TipoNotReady_id,Descripcion from ccTipoNotReady'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccTipoStatusAgente (TipoStatusAge_id,descripcion) '
set @sql = @sql + 'select TipoStatusAge_id,descripcion from ccTipoStatusAgente'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccInboundAgentes (User_id,Inbound_id,cli_id,prioridad,skill) '
set @sql = @sql + 'select distinct User_id,Inbound_id,cli_id,prioridad,skill from ccInboundAgentes'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccTipoResultadoDial ( tipoResDial_id,descripcion) '
set @sql = @sql + 'select tipoResDial_id,descripcion from ccTipoResultadoDial'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.cstoProvedor ( provedor_id,descrip) '
set @sql = @sql + 'select provedor_id,descrip from cstoProvedor'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccPosicion (pos_id,Computer,ext_id,user_id,Status,tipoConexion,IP) '
set @sql = @sql + 'select pos_id,Computer,ext_id,user_id,Status,tipoConexion,IP from ccPosicion'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccDNIS (dni_id,dni_numero,dni_tipo,tipodni_id,dni_tpoMaxEspera,dni_Descripcion) '
set @sql = @sql + 'select dni_id,dni_numero,dni_tipo,tipodni_id,dni_tpoMaxEspera,dni_Descripcion from ccDNIS'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) '
set @sql = @sql + 'select country_id,tipoLlamada_id,descrip,longitud,prefijo from cstoTipoLlamada'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccoDialers (dialer_id, Descripcion, Puerto, Extension, Status, provedor_id) '
set @sql = @sql + 'select dialer_id, Descripcion, Puerto, Extension, Status, provedor_id from ccoDialers'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.cstoTarifa (provedor_id, tipoLlamada_id, minutoUno, minutoAdicional) '
set @sql = @sql + 'select provedor_id, tipoLlamada_id, minutoUno, minutoAdicional from cstoTarifa'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccriacat_workgroup (idwg,wgname) '
set @sql = @sql + 'select idwg,wgname from ccriacat_workgroup'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccRIAWorkGroupUsers (idwg, user_id) '
set @sql = @sql + 'select idwg,user_id from ccRIAWorkGroupUsers'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccRIACat_Areas (IDArea,AreaName) '
set @sql = @sql + 'select IDArea, AreaName from ccRIACat_Areas'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccRIAAreaWorkGroup (IDWG,IDArea) '
set @sql = @sql + 'select IDWG, IDArea from ccRIAAreaWorkGroup'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.telefonosConferencia (nombre,tel) '
set @sql = @sql + 'select nombre,tel from telefonosConferencia'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.telefonosTransferencia (nombre,tel) '
set @sql = @sql + 'select nombre,tel from telefonosConferencia'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.ccCallsReject (cal_id, ani, dnis, puerto, cal_inicio, Inbound_id) '
set @sql = @sql + 'select cal_id, ani, dnis, puerto, cal_inicio, Inbound_id from ccCallsReject'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.cctipocalifsub (califsub_id, califsubdesc, orden, canreprogram,califsub_status) '
set @sql = @sql + 'select califsub_id, califsubdesc, isnull(orden,0), isnull(canreprogram,0),califsub_status from cctipocalifsub'
--print @sql
exec(@sql)

set @sql = 'insert into ' + @server +'.dbo.cctipocalifsubout (califsub_id, califsubdesc,canreprogram,orden,idtipolista,califsubout_status,keepdial,autocallback) '
set @sql = @sql + 'select califsub_id, califsubdesc,isnull(canreprogram,0),isnull(orden,0),isnull(idtipolista,0),califsubout_status,isnull(keepdial,0),isnull(autocallback,0) from cctipocalifsubout'
--print @sql
exec(@sql)