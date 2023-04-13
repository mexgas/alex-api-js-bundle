/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 14
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	---------------------------------------BEGIN MARCO CHAGOLLA ---------------------------------------------------------
	set @process = 'KR082000 add new columns and add registers for Activity Log'
	set @sql = '
		IF NOT EXISTS(SELECT 1 FROM sys.columns 
			WHERE Name = N''recycledByDisposition''
			AND Object_ID = Object_ID(N''ccoCallsOutSource''))
		BEGIN
			ALTER TABLE ccoCallsOutSource
			ADD recycledByDisposition bit
		END

		IF NOT EXISTS(SELECT 1 FROM sys.columns 
			WHERE Name = N''recycledByResult''
			AND Object_ID = Object_ID(N''ccoCallsOutSource''))
		BEGIN
			ALTER TABLE ccoCallsOutSource
			ADD recycledByResult VARCHAR(max)
		END

		IF NOT EXISTS(SELECT 1 FROM sys.columns 
			WHERE Name = N''recyclePhone''
			AND Object_ID = Object_ID(N''ccoCallsOutSource''))
		BEGIN
			ALTER TABLE ccoCallsOutSource
			ADD recyclePhone SMALLINT
		END

		IF NOT EXISTS(SELECT 1 FROM sys.columns 
			WHERE Name = N''recycleType''
			AND Object_ID = Object_ID(N''ccoCallsOutSource''))
		BEGIN
			ALTER TABLE ccoCallsOutSource
			ADD recycleType bit
		END

		IF NOT EXISTS(SELECT 1 FROM sys.columns 
			WHERE Name = N''canBeRecycled''
			AND Object_ID = Object_ID(N''ccoLogDials''))
		BEGIN
			ALTER TABLE ccoLogDials
			ADD canBeRecycled bit
		END

		IF NOT EXISTS(SELECT 1 FROM sys.columns 
			WHERE Name = N''canBeRecycled''
			AND Object_ID = Object_ID(N''ccoCallsOut''))
		BEGIN
			ALTER TABLE ccoCallsOut
			ADD canBeRecycled bit
		END

		IF NOT EXISTS(SELECT * FROM ccGalateaOperations where OperationId = 37)
		BEGIN
			INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt) 
			values(37, ''Reciclar registros por resultado de marcación'', ''Recycle records by dialing result'', ''Reciclar registros por resultado de discagem'')

			INSERT INTO ccGalateaModOpRelation values(2, 37)
		END

		IF NOT EXISTS(SELECT * FROM ccGalateaOperations where OperationId = 38)
		BEGIN
			INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt) 
			values(38, ''Reciclar registros por calificación'', ''Recycle records by disposition'', ''Reciclar registros por classificação'')
	
			INSERT INTO ccGalateaModOpRelation values(2, 38)
		END


		IF NOT EXISTS(SELECT * FROM ccGalateaOperations where OperationId = 39)
		BEGIN
			INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt) 
			values(39, ''Reciclar registros por subcalificación'', ''Recycle records by subdisposition'', ''Reciclar registros por subclassificação'')
	
			INSERT INTO ccGalateaModOpRelation values(2, 39)
		END

		if not exists (select * from ccPermissions where Permissions_Id = 10033)
		begin 
			insert into ccPermissions values (10033,''Reciclar registros'', ''RolesPermissionRecycleRecords'',0,0,0,''N/A'',1)
		end

		if not exists (select * from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = 10033)
		begin 
			insert into ccRoles_Permissions values(1,10033)
		end
		 '

	EXEC(@sql)

	set @process = 'KR082000 Drop SP ccsp_RecycleByDispositionOrResult'
	set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_RecycleByDispositionOrResult'')
            BEGIN
                DROP PROCEDURE [dbo].[ccsp_RecycleByDispositionOrResult]
            END'
    EXEC(@sql)

	set @process = 'KR082000 create SP ccsp_RecycleByDispositionOrResult'
	set @sql = '
		CREATE PROCEDURE ccsp_RecycleByDispositionOrResult
		@Action SMALLINT = 0,
		@cam_id SMALLINT = 0,
		@result_id SMALLINT = 0,
		@disposition_id SMALLINT = 0,
		@subDisposition_id SMALLINT = 0
		AS
		BEGIN
			DECLARE @date DATE = CONVERT(VARCHAR,GETDATE(),23);
			DECLARE @count INT = 0;

			IF(@Action = 1) BEGIN --Count registers to recycle by Result
				SELECT DISTINCT COUNT(*) OVER() AS TotalRecords
				FROM ccoLogDials ld
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = ld.callout_id and cs.cam_id = ld.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE ld.fecha > @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(ld.canBeRecycled, 1) = 1
				AND NOT EXISTS (select value FROM fn_RIASplitDelimited(ISNULL(cs.recycledByResult, ''0''), '','') where value = CONVERT(VARCHAR(2), @result_id))
				AND ld.tipoResDial_id = @result_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				GROUP BY ld.callout_id
				RETURN 0;
			END

			IF(@Action = 2) BEGIN --Count registers to recycle by Calif
				SELECT DISTINCT COUNT(co.callout_id) AS TotalRecords
				FROM ccoCallsOut co
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE co.cal_Inicio >= @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(co.canBeRecycled, 1) = 1
				AND ISNULL(recycledByCalif, 0) = 0
				AND co.calif_id = @disposition_id
				AND ISNULL(co.califSub_id, 0) <= 0
				AND cs.cam_id = @cam_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				GROUP BY co.callout_id
				RETURN 0;
			END

			IF(@Action = 3) BEGIN --Count registers to recycle by CalifSub
				SELECT DISTINCT COUNT(co.callout_id) AS TotalRecords
				FROM ccoCallsOut co
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE co.cal_Inicio >= @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(co.canBeRecycled, 1) = 1
				AND ISNULL(recycledByCalif, 0) = 0
				AND co.calif_id = @disposition_id
				AND co.califSub_id = @subDisposition_id
				AND cs.cam_id = @cam_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				GROUP BY co.callout_id
				RETURN 0;
			END

			IF(@Action = 4) BEGIN --Recycle registers to load by Result
				SELECT ld.callout_id, ld.Telefono, ld.fecha,
				ROW_NUMBER() OVER (PARTITION BY ld.callout_id ORDER BY ld.fecha ASC) AS RowFilter
				INTO #tmpCalloutIdResult
				FROM ccoLogDials ld
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = ld.callout_id and cs.cam_id = ld.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE ld.fecha > @date
				AND cs.cal_status not in (0,1,7)
				AND NOT EXISTS (select value FROM fn_RIASplitDelimited(ISNULL(cs.recycledByResult, ''0''), '','') where value = CONVERT(VARCHAR(2), @result_id))
				AND ISNULL(ld.canBeRecycled, 1) = 1
				AND ld.tipoResDial_id = @result_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				GROUP BY ld.callout_id, ld.Telefono, ld.fecha

				DELETE wt
				FROM ccoWorkingTable wt
				INNER JOIN #tmpCalloutIdResult tc on wt.callout_id = tc.callout_id
				WHERE wt.cal_status = 1

				UPDATE cs SET cs.cal_status = 0, cs.recycledByResult = ISNULL(cs.recycledByResult, '''') + '','' +CONVERT(VARCHAR(2), @result_id),
				cs.recyclePhone = CASE 
					WHEN tc.Telefono = cs.cal_telefono THEN 1
					WHEN tc.Telefono = cs.cal_telefono2 THEN 2
					WHEN tc.Telefono = cs.cal_telefono3 THEN 3
					WHEN tc.Telefono = cs.cal_telefono4 THEN 4
					ELSE 5 END, 
				cs.recycleType = 0
				FROM ccoCallsOutSource cs
				INNER JOIN #tmpCalloutIdResult tc on cs.callout_id = tc.callout_id
				WHERE tc.RowFilter = 1

				UPDATE ld SET ld.canBeRecycled = 0
				FROM ccoLogDials ld
				INNER JOIN #tmpCalloutIdResult tc on ld.callout_id = tc.callout_id
				WHERE ld.fecha >= @date
				AND ld.tipoResDial_id = @result_id

				SELECT @count = COUNT(*) from #tmpCalloutIdResult

				EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp @camp_id = @cam_id, @top = @count

				DROP TABLE #tmpCalloutIdResult

				SELECT cam_descripcion FROM ccCamps where cam_id = @cam_id

				RETURN 0;
			END

			IF(@Action = 5) BEGIN --Recycle registers to load by Calif
				SELECT co.callout_id INTO #tmpCalloutId
				FROM ccoCallsOut co
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE co.cal_Inicio >= @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(co.canBeRecycled, 1) = 1
				AND ISNULL(recycledByCalif, 0) = 0
				AND co.calif_id = @disposition_id
				AND ISNULL(co.califSub_id, 0) <= 0
				AND cs.cam_id = @cam_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				GROUP BY co.callout_id

				UPDATE cs SET cs.cal_status = 0, cs.recycledByCalif = 1, cs.recycleType = 1
				FROM ccoCallsOutSource cs
				INNER JOIN #tmpCalloutId tc on cs.callout_id = tc.callout_id

				UPDATE co SET co.canBeRecycled = 0
				FROM ccoCallsOut co
				INNER JOIN #tmpCalloutId tc on co.callout_id = tc.callout_id
				WHERE co.cal_Inicio >= @date

				DELETE wt
				FROM ccoWorkingTable wt
				INNER JOIN #tmpCalloutId tc on wt.callout_id = tc.callout_id
				WHERE wt.cal_status = 1

				SELECT @count = COUNT(*) from #tmpCalloutId

				EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp @camp_id = @cam_id, @top = @count

				DROP TABLE #tmpCalloutId

				SELECT cam_descripcion FROM ccCamps where cam_id = @cam_id

				RETURN 0;
			END

			IF(@Action = 6) BEGIN --Recycle registers by CalifSub
				SELECT co.callout_id INTO #tmpCalloutIdSub
				FROM ccoCallsOut co
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE co.cal_Inicio >= @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(co.canBeRecycled, 1) = 1
				AND ISNULL(recycledByCalif, 0) = 0
				AND co.calif_id = @disposition_id
				AND co.califSub_id = @subDisposition_id
				AND cs.cam_id = @cam_id
				AND(wt.callout_id IS NULL OR wt.cal_status = 1)
				GROUP BY co.callout_id

				DELETE wt
				FROM ccoWorkingTable wt
				INNER JOIN #tmpCalloutIdSub tc on wt.callout_id = tc.callout_id
				WHERE wt.cal_status = 1

				UPDATE cs SET cs.cal_status = 0, cs.recycledByCalif = 1, cs.recycleType = 1
				FROM ccoCallsOutSource cs
				INNER JOIN #tmpCalloutIdSub tc on cs.callout_id = tc.callout_id

				UPDATE co SET co.canBeRecycled = 0
				FROM ccoCallsOut co
				INNER JOIN #tmpCalloutIdSub tc on co.callout_id = tc.callout_id
				WHERE co.cal_Inicio >= @date

				SELECT @count = COUNT(*) from #tmpCalloutIdSub

				EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp @camp_id = @cam_id, @top = @count

				DROP TABLE #tmpCalloutIdSub

				SELECT cam_descripcion FROM ccCamps where cam_id = @cam_id

				RETURN 0;
			END
		END
		 '
	EXEC(@sql)

	set @process = 'KR082000 Drop SP ccsp_DLRGetDialInfo'
	set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_DLRGetDialInfo'')
            BEGIN
                DROP PROCEDURE [dbo].[ccsp_DLRGetDialInfo]
            END'
    EXEC(@sql)

	set @process = 'KR082000 CREATE SP ccsp_DLRGetDialInfo'
	set @sql = '
		CREATE PROCEDURE [dbo].[ccsp_DLRGetDialInfo]
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
			declare @recordHold bit

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
			@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0), @rotativeAlgo=isnull(rotativeAlgo,0), @recordHold=ISNULL(recordHold,0)
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
                , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 1) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE C.cal_telefono  END cal_telefono
				, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 2) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono2 END cal_telefono2
				, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 3) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono3 END cal_telefono3
				, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 4) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono4 END cal_telefono4
				, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 5) AND ISNULL(recycleType, 1) = 0) THEN '''' Else c.cal_telefono5 END cal_telefono5
				, isnull(@message_name, '''') as message_name
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
                dbo.GetCarrierByTel(cal_telefono5) carrier5,
				@recordHold as recordHold
                FROM ccoCallsOutSource C with(nolock)
                left join ccoCallPriorityOrder cpo on cpo.callout_id = c.callout_id
                left join ccCampsPrioridadTel cpt on cpt.cam_id = c.cam_id
                left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
                WHERE C.callout_id = @callout_id
                return
            end 
            set nocount off
	'
    EXEC(@sql)

	set @process = 'KR082000 Drop SP ccsp_RIAOUTInsertNewJOBS_WT_Camp'
	set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_RIAOUTInsertNewJOBS_WT_Camp'')
            BEGIN
                DROP PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp]
            END'
    EXEC(@sql)

	set @process = 'KR082000 CREATE SP ccsp_RIAOUTInsertNewJOBS_WT_Camp'
	set @sql = '
		CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000
		AS
		SET NOCOUNT ON

		CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT)

		DECLARE @prioridad VARCHAR(8)
		DECLARE @batchsizeIni AS INT
		DECLARE @batchsizeFin AS INT
		DECLARE @rango AS DECIMAL
		DECLARE @rowstoInsert AS INT

		SET @rowstoInsert = 0
		SET @batchsizeIni = 0
		SET @batchsizeFin = 0
		SET @rango = 0.00

		IF @top < 3000
		BEGIN
			SET @top = 3000
		END

		SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
		FROM ccCampsPrioridadTel WITH (NOLOCK)
		WHERE cam_id = @camp_id

		DELETE ccUploadTemporal
		WHERE cam_id = @camp_id

		CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
			WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

		CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

		CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

		INSERT INTO #calloutIdSource
		SELECT top(@top) cs.callout_id
		FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_15), NOLOCK)
		inner join ccoWorkingTable wt WITH (INDEX (IX_ccoWorkingTable_15), NOLOCK) 
		on cs.callout_id = wt.callout_id AND cs.cam_id = wt.cam_id 
		WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

		UNION

		SELECT top(@top) Cout.callout_id
		FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
		inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id 
		WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)

		INSERT INTO #calloutIdSource2
		SELECT top(@top) callout_id
		FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
		WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

		IF exists(SELECT * FROM #calloutIdSource) 
		BEGIN
			UPDATE ccoCallBacks
			SET [status] = 6, schedulerStatus = 1
			WHERE callout_id IN (
					SELECT callout_id
					FROM #calloutIdSource cis
					)

			UPDATE ccoCallsOutSource
			SET cal_Status = 4
			WHERE callout_id IN (
					SELECT callout_id
					FROM #calloutIdSource cis
					)
		END

		INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
		iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
			iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
		SELECT top(@top) callout_id, cam_id, 
		CASE WHEN ISNULL(recycleType, 1) = 0 THEN 
			CASE 
				WHEN recyclePhone = 1 THEN cal_telefono
				WHEN recyclePhone = 2 THEN cal_telefono2
				WHEN recyclePhone = 3 THEN cal_telefono3
				WHEN recyclePhone = 4 THEN cal_telefono4
				else cal_telefono5
			END
		ELSE rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         '' 
			+ cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13)) 
		END AS cal_telefono,
		CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key, 
		CASE WHEN len(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
		CASE WHEN len(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
		CASE WHEN len(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
		CASE WHEN len(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
		CASE WHEN len(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
		CASE WHEN len(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
		CASE WHEN len(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
		CASE WHEN len(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
		CASE WHEN len(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
		CASE WHEN len(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE 
					NULL END iZonaHoraria_verano5, list_id
		FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
		WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7)

		SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

		IF exists(SELECT * FROM #tempCallsOutSource)
		BEGIN
			SELECT @rango = isnull(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
			FROM #tempCallsOutSource WITH (NOLOCK)

			SET @batchsizeFin = @batchsizeFin + @rango

			WHILE 1 = 1
			BEGIN
				-- Nuevos Jobs
				INSERT INTO ccoWorkingTable
				WITH (TABLOCKX) (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
				SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
				FROM #tempCallsOutSource
				WHERE id > @batchsizeIni AND id <= @batchsizeFin

				IF @batchsizeFin > @rowstoInsert
					BREAK
				ELSE
				BEGIN
					SET @batchsizeIni = @batchsizeIni + @rango
					SET @batchsizeFin = @batchsizeFin + @rango
				END
			END

			UPDATE ccoCallsOutSource
			SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
			FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
			WHERE co.callout_id = cis3.callout_id
		END

		DROP TABLE #calloutIdSource

		DROP TABLE #calloutIdSource2

		DROP TABLE #tempCallsOutSource

		UPDATE ccCampsNvosCB
		SET dateUpdate = NULL
		WHERE id = @camp_id

		SET NOCOUNT OFF
	'
    EXEC(@sql)

	set @process = 'KR082000 Drop SP ccsp_RIAADMGetCalifDay'
	set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_RIAADMGetCalifDay'')
            BEGIN
                DROP PROCEDURE [dbo].[ccsp_RIAADMGetCalifDay]
            END'
    EXEC(@sql)

	set @process = 'KR082000 CREATE SP ccsp_RIAADMGetCalifDay'
	set @sql = '
		CREATE Procedure [dbo].[ccsp_RIAADMGetCalifDay]
		@type smallint = null,
		@inbound_id smallint = null,
		@calif_id smallint = null,
		@cam_id smallint = null
		AS
		set nocount on
		create table #CalifTemp (
		id int identity,
		tipo integer,
		Cam_id varchar(60),
		Calificacion varchar(60),
		subCalificacion varchar(60) null,
		calif_id smallint null,
		Total int,
		iTotal4Campaign int null)

		declare @typeACD smallint --= 0
		declare @today datetime
		declare @nIdioma varchar(22),@nIdiomaSub varchar(22)

		set @today = convert(datetime, convert (varchar(11), getdate(), 101))
		select @typeACD = chat from ccInbound  where Inbound_id = @inbound_id


		select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end,
		@nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
		from ccsettings where setting_id = 27 -- 0 esp

		---------------OUT ----------------------------
		if @type=0 begin
		    insert into #CalifTemp
		    select 0 as tipo,co.cam_id as cam_id,
		    case when co.statuscall_id = 13
			   then case when description is not null
			   then description else @nIdioma end
		    else case when sll.descripcion is not null then ''cw:'' + sll.descripcion
		    else ''cw:'' + @nIdioma
		    end end as Calificacion
		    ,0 as subCalificaion,
		    co.calif_id,count(*) cantidad,0 as iTotal4Campaign
		    from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
		    left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
		    left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
		    left join ccCamps ci on ci.cam_id = co.cam_id
		    where co.cal_inicio > @today
		    group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id

		    select tipo,Cam_id, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end as Calificacion,
		    case when count(subCalificacion)>0 then 1 else 0 end subCalificacion, calif_id,sum(Total) as Total
		    from #CalifTemp
		    group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end, Cam_id, iTotal4Campaign,calif_id

		end
		---------------IN ----------------------------
		else if @type = 1 begin

		    if @typeACD = 0 begin  --Calls
		    insert into #CalifTemp
		    select @typeACD as tipo,cci.inbound_id as cam_id, description as Calificacion
				  ,case when count(ci.califSub_id) >0 then 1 else 0 end as subCalificacion,ci.calif_id
				  ,count(*) as total,0 as iTotal4Campaign
				  from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
				  left join ccTipoCalif ca on ci.calif_id = ca.calif_id
				  left join ccInbound cci on cci.inbound_id = ci.inbound_id
				  left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
				  where ci.cal_inicio > @today and statuscall_id = 13	and cci.Inbound_id=@inbound_id
				  group by description, cci.inbound_id,ci.calif_id

		    if (select valor from ccSettings where setting_id = 78) = 0 begin
			   update #CalifTemp set iTotal4Campaign = 0
		    end
		    else begin
		    update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign
			   from (
				  select cam_id, sum(A.Total) iTotal4Campaign from #CalifTemp A group by cam_id) t
			   inner join #CalifTemp c on t.cam_id = c.cam_id
		    end
		    end
		    else if @typeACD = 1 begin--Chats
		    insert into #CalifTemp(tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
		    select @typeACD as tipo, inboundId as Cam_id, [description] as Calificacion,
				  case when sum(case when a.subDisposition = 0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
				  a.disposition as calif_id, count(disposition) as Total
				  from ccriachats a
				  left join ccTipoCalif b on a.disposition=b.calif_id
			   where a.chatDate > @today and
			   a.chatStatus=4 and a.inboundId=@inbound_id
		    group by inboundId, [description],disposition
		    end
		    else if @typeACD = 3 begin ---Mail
		    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
		    select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
		    case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
		    relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
		    from conversation conver
		    inner join message mess on mess.conversationId = conver.conversationId
		    left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
		    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
		    where mess.date > @today and
		    conver.inboundId=@inbound_id and mess.messageStatusId >= 5
		    group by conver.inboundId,relmesdis.dispositionId,disp.Description

		    end
		    else if @typeACD = 4 begin --calif twetter
		    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
		    select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
		    case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
		    relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
		    from conversationTwitter conver
		    inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
		    left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
		    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
		    where mess.date > @today and
		    conver.inboundId=@inbound_id and mess.messageStatusId >= 5
		    group by conver.inboundId,relmesdis.dispositionId,disp.Description

		    end
		    select camtemp.tipo,camtemp.cam_id,
		    case when tipcal.Description is not null then tipcal.Description else @nIdioma end as Calificacion,
		    camtemp.subcalificacion,camtemp.calif_id,camtemp.total
		    from #CalifTemp camtemp
		    left join ccTipoCalif tipcal on camtemp.calif_id =  tipcal.calif_id
		end
		-------------------SUBCALIFICACIONES IN-------------------
		else if @type = 2 begin
		    if @typeACD = 0 begin --Calls
		    select @typeACD as Type,cci.inbound_id as CampId,  [description] as Calification,
		    isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName, count(ctcs.califSubDesc) as Quantity
		    from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
		    left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		    left join ccInbound cci on cci.inbound_id = ci.inbound_id
		    left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
		    where ci.cal_inicio > @today
		    and ci.inbound_id = @inbound_id  and statuscall_id = 13  and ci.calif_id = @calif_id
		    group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id
		    end
		    else if @typeACD = 1 begin --Chat
		    select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
				  isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
				  from ccriachats a
				  left join ccTipoCalif b on a.disposition=b.calif_id
				  left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
				  where a.chatDate > @today and
				  a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id
				  group by inboundId, [description],ctcs.califSubDesc
		    end
		    else if @typeACD = 3 begin --Mail
		    select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
		    isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
		    from conversation conver
		    inner join message mess on mess.conversationId = conver.conversationId
		    left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
		    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
		    left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
		    where mess.date > @today and
		    mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
		    group by conver.inboundId,disp.Description,subDisp.califSubDesc


		    end
		    else if @typeACD = 4 begin --Twitter
		    select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
		    isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
		    from conversationTwitter conver
		    inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
		    left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
		    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
		    left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
		    where mess.date > @today and
		    mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
		    group by conver.inboundId,disp.Description,subDisp.califSubDesc
		    end

		end
		-------------------SUBCALIFICACIONES OUT-------------------
		else if @type = 4 begin
		    select 0 as Type,co.cam_id as CampId,
		    case when co.statuscall_id = 13
		    then case when description is not null
		    then description else @nIdioma end
		    else
		    case when sll.descripcion is not null
		    then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma
		    end
		    end as Calification,
		    isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(cso.califSub_id) Quantity,
		    ISNULL(cso.califSub_id, 0) as [id]
			from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
		    left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
		    left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id 
		    left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
		    left join ccCamps ci on ci.cam_id = co.cam_id
		    where co.cal_inicio > @today
		    and co.cam_id = @inbound_id
		    and co.calif_id = @calif_id
			--and cso.califSub_id > 0
		    group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc, cso.califSub_id
		end


		drop table #CalifTemp
		set nocount off
	'
    EXEC(@sql)

		---------------------------------------END MARCO CHAGOLLA ---------------------------------------------------------
	
		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
		EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
