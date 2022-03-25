CREATE procedure [dbo].[ccsp_DLRgetDialPrefix]
			@cam_id smallint=0,
			@iPortNumber smallint = 0,
			@phone varchar(30) = '',
			@callout_id int = 0
			as
			declare @prefix as varchar(15), @sipheader varchar(500)
			declare @ani as varchar(32)
			declare @call_record_cam as tinyint
			declare @pais as tinyint 
			declare @aniglobal varchar(32), @sipHdrFormat varchar(255)
			declare @ivr_script smallint, @surveycamid int
			declare @call_record bit, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint
			declare @PrefixRec varchar(40)
			declare @carrier varchar(255)

			select @pais = valor from ccsettings with(nolock) where setting_id = 104
			select @call_record_cam = call_record from ccCamps where cam_id = @cam_id
			select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

			set @prefix =''
			-- Prefijo por puerto
			select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

			-- Prefijo por campa?a,
			if @prefix =''
				select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

			-- Prefijo general
			if @prefix ='' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
				select @prefix = valor from ccsettings with(nolock) where setting_id =101

			-- Ani
			set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

			--AnswerMachine Message Files
			DECLARE @MsgFiles VARCHAR(8000) 
			SELECT @MsgFiles = COALESCE(@MsgFiles + ',', '') + V.msgfile 
			FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

			--Custom MOH Files
			DECLARE @MohFiles VARCHAR(8000) 
			SELECT @MohFiles = COALESCE(@MohFiles + ',', '') + V.msgfile 
			FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

			select @surveycamid = 0, @ivr_script = 0

			select @sipHdrFormat=isnull(sipHdrFormat,''),@tNoContesta = cam_tNoContesta, @ani = case when @ani = '' then ani else @ani end
			,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
			,@call_record = dbo.EnableCallRecord(@call_record_cam,@pais,@phone), @surveycamid = isnull(surveycamid,0)
			from ccCamps where cam_id = @cam_id

			SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)

			if @surveycamid > 0
				select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid
    

			if @ani = '' begin 
			set @ani = @aniglobal 
			end 

			 select @PrefixRec=ISNULL(prefijo,'') from ccCamps where cam_id = @cam_id

			 set @carrier = ''
			 select @carrier = dbo.GetCarrierByTel(@phone)

			select @prefix as sDialPrefix, @tNoContesta as tNoContesta,@ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
			@call_record as call_record, isnull(@MsgFiles,'') as messageFiles, isnull(@MohFiles,'') as mohFiles, @ivr_script ivrScript, @sipheader data
			,@PrefixRec PrefijoRec, @carrier Carrier