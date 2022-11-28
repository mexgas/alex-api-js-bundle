/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/25
Description: Cambios para no duplicar el quinto dato al momento de traer la informacion para marcar

Database: CCenterRia
Required version: 123.27

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 21
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY
	set @process = 'Se elimina SP ccsp_DLRGetDialInfo si existe'
    set @sql = 'if exists (select * from sys.procedures where name =''ccsp_DLRGetDialInfo'')
    begin
        DROP PROCEDURE ccsp_DLRGetDialInfo
    end'
    EXEC(@sql)

	set @process = 'Se crea SP ccsp_DLRGetDialInfo,se hace modificacion para evitar que duplique el 5 dato en la concatenacion (rtrim(dato5))'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_DLRGetDialInfo]
            @callout_id int,
            @cam_id smallint=0,
            @iPortNumber smallint = 0
            AS
            set nocount on
            declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
            declare @prefix as varchar(15)
            declare @prefixCalKey as varchar(30)
            declare @tNoContesta as tinyint
            declare @ani as varchar(32)
            declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint, @rotativeAlgo tinyint
            declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
            declare @ivr_script smallint, @surveycamid int
            declare @call_record_cam as tinyint
            declare @pais as tinyint 
            declare @sipHdrFormat varchar(255)
            declare @PrefixRec varchar(40)

            set @prefix =''''
            set @tNoContesta = 25
            set @ani=''''
            set @iTipoDial = 0
            set @detectAnswerMachine = 0
            set @detectVoiceMail =1
            set @cam_tnotas = 30
            set @keepDial = 0

            select @pais = valor from ccsettings where setting_id = 104
            select @PrefixRec=ISNULL(prefijo,'''') from ccCamps nolock where cam_id = @cam_id

            -- Mensajes
            select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
            from dbo.fn_ccCamps_SelMessage(@cam_id)

            -- Prefijo por puerto
            select @prefix = prefix from cstoProvedor nolock where provedor_id = (select provedor_id from ccodialers nolock where puerto = @iPortNumber )
            -- Prefijo por campa?a
            if @prefix =''''
                select @prefix = dialPrefix from ccCamps nolock where cam_id = @cam_id
            -- Prefijo general, si es que esta habilitado
            if @prefix ='''' and ((select cast(valor as int) from ccsettings nolock where setting_id =102) & 1 = 1)
                select @prefix = valor from ccsettings nolock where setting_id =101

            select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

            -- Propiedades de campa?a
            select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
            @detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
            @call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0), @rotativeAlgo=isnull(rotativeAlgo,0)
            from ccCamps C (nolock) where C.cam_id=@cam_id

            if @surveycamid > 0
                select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

            --Custom MOH Files
            DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
            SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
            FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

            --Agrega prefijo Marcacion con directo
            declare @mainPrefix varchar(1), @phones varchar(max)
            set @prefixCalKey=''''
            select @mainPrefix = valor from ccSettings where setting_id=202
            SELECT @prefixCalKey=CASE WHEN @mainPrefix=''1'' THEN isnull(dialPrefix,'''') ELSE '''' END,
                @phones=cal_telefono+'';''+cal_telefono2+'';''+cal_telefono3+'';''+cal_telefono4+'';''+cal_telefono5
            FROM ccoCallsOutSource NOLOCK WHERE callout_id=@callout_id 

            if @iPortNumber >= 0 
            begin
                declare @Anis table(id int, pid varchar(2), phone varchar(32), ani varchar(32))

                insert @Anis
                exec ccsp_DLRGetRotativeANI @callout_id=@callout_id,@phones=@phones,@aniList=@lista_id,@algo=@rotativeAlgo

                SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
    
                SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)
                , ISNULL(cpt.Prioridad,''12345NNN'') dial_tels
                , C.cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, isnull(@message_name, '''') as message_name
                , @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
                , case when anis.p1 <> '''' then anis.p1 else @ani end ani
                , case when anis.p2 <> '''' then anis.p2 else @ani end ani2
                , case when anis.p3 <> '''' then anis.p3 else @ani end ani3
                , case when anis.p4 <> '''' then anis.p4 else @ani end ani4
                , case when anis.p5 <> '''' then anis.p5 else @ani end ani5
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
                ,@PrefixRec as Prefijo,
                dbo.GetCarrierByTel(C.cal_telefono) carrier1, 
                dbo.GetCarrierByTel(cal_telefono2) carrier2, 
                dbo.GetCarrierByTel(cal_telefono3) carrier3, 
                dbo.GetCarrierByTel(cal_telefono4) carrier4, 
                dbo.GetCarrierByTel(cal_telefono5) carrier5
                FROM ccoCallsOutSource C with(nolock)
                left join ccoCallPriorityOrder cpo on cpo.callout_id = c.callout_id
                left join ccCampsPrioridadTel cpt on cpt.cam_id = c.cam_id
                left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
                WHERE C.callout_id = @callout_id
                return
            end 

            set nocount off'
	EXEC(@sql)

END

SET NOCOUNT OFF'
EXEC(@sql)

	
	

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
