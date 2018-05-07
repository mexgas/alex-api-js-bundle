/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Mike Trejo
Date: 2018/04/04
Description:



Database: CCenterRia
Required version: 119.119.123

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 119 sin fix
set @versionfix = 141
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 134
	begin
		begin tran
		begin try

		set @process = 'CW-1809  Version 119.133 ADD column ccoCallsOutSource.dialPrefix'
		set @Sql= 'if not exists (select * from sys.columns where name = N''dialPrefix'' and Object_ID = Object_ID(N''ccoCallsOutSource''))
    begin
        ALTER TABLE ccoCallsOutSource ADD dialPrefix varchar(30) CONSTRAINT ccoCallsOutSourceDiailPrefix DEFAULT('''')
    end'
		EXEC(@sql)

		set @process = 'CW-1809  Version 119.133 Insert setting_id 202 Marcacion con directo '
		set @Sql= 'if not exists(select * from ccSettings where setting_id=202) begin
	insert into ccSettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) 
	values(202,''0'',''Marcacion con directo'',1,''X'',''Agrega un segundo prefijo de marcacion, primero pondra el global o campaña este prefijo es por numero el cual esta en ccoCallsOutSource'',
	''Add a second dialing prefix, first put the global or campaign this prefix is by number which is in ccoCallsOutSource'',0,''^[0-1]$'')
end'
		EXEC(@sql)
	
		set @process = 'CW-1809  Version 119.133 update dialPrefix is empty '
		set @Sql= 'update ccoCallsOutSource set dialPrefix='''' where dialPrefix is null'
		EXEC(@sql)

		set @process = 'CW-1809  Version 119.133 ALter SP ccsp_DLRGetDialInfo prefix for callout_id '
		set @Sql= 'ALTER procedure [dbo].[ccsp_DLRGetDialInfo]
@callout_id int,    
@cam_id smallint=0,    
@iPortNumber smallint = 0    
AS    
set nocount on    
declare @message_name as varchar(max), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
declare @prefix as varchar(15)
declare @prefixCalKey as varchar(30)
declare @tNoContesta as tinyint    
declare @ani as varchar(50)    
declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint    
declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint    
declare @ivr_script smallint, @surveycamid int    
declare @call_record_cam as tinyint    
declare @pais as tinyint     
declare @sipHdrFormat varchar(255)    
    
set @prefix =''''    
set @tNoContesta = 25    
set @ani=''''    
set @iTipoDial = 0    
set @detectAnswerMachine = 0    
set @detectVoiceMail =1    
set @cam_tnotas = 30    
set @keepDial = 0    
    
select @pais = valor from ccsettings where setting_id = 104    
    
-- Mensajes    
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm    
from dbo.fn_ccCamps_SelMessage(@cam_id)    
    
-- Prefijo por puerto    
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )    
-- Prefijo por campaña    
if @prefix =''''    
    select @prefix = dialPrefix from ccCamps where cam_id = @cam_id    
-- Prefijo general, si es que esta habilitado    
if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 1 = 1)    
    select @prefix = valor from ccsettings where setting_id =101    
    
select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0    
    
-- Propiedades de campaña    
select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,    
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,    
@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0)    
from ccCamps C (nolock) where C.cam_id=@cam_id    
    
if @surveycamid > 0    
    select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid    
    
--Custom MOH Files    
DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)    
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile     
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden    

--Agrega prefijo Marcacion con directo    
set @prefixCalKey=''''
if (select valor from ccSettings where setting_id=202)=''1'' begin
	select @prefixCalKey=isnull(dialPrefix,'''') from ccoCallsOutSource with(nolock) where callout_id=@callout_id 
end

if @iPortNumber >= 0     
begin    
 SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)    
    
    SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)    
    , dial_tels    
    , C.cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, isnull(@message_name, '''') as message_name    
    , @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
    , case when dbo.TelAni(c.cal_telefono,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono,@lista_id) else @ani end ani    
    , case when dbo.TelAni(c.cal_telefono2,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono2,@lista_id) else @ani end ani2    
    , case when dbo.TelAni(c.cal_telefono3,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono3,@lista_id) else @ani end ani3    
    , case when dbo.TelAni(c.cal_telefono4,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono4,@lista_id) else @ani end ani4    
    , case when dbo.TelAni(c.cal_telefono5,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono5,@lista_id) else @ani end ani5    
    , @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail    
    , @cam_tnotas cam_tnotas, @keepDial keepDial    
    , isnull(@messageDNCL_name, '''') as messageDNCL_name    
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record    
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2    
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3    
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4    
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5    
    , isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name    
    , isnull(@MohFiles,'''') as mohFiles    
    ,@ivr_script ivrScript    
 ,@sipheader data    
    FROM ccoCallsOutSource C with(nolock)    
    WHERE C.callout_id = @callout_id    
    return    
end     
    
set nocount off'
		EXEC(@sql)		

				/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
