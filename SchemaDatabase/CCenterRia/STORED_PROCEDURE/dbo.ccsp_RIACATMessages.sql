CREATE PROCEDURE [dbo].[ccsp_RIACATMessages]
		@command tinyint,
		@msg_id int=0,
		@msgFile varchar(40)='',
		@Description varchar(40)='',
		@length smallint=0
		AS
		set nocount on
		If @command=0
		 begin
			SELECT Descripcion FROM ccMsgFiles WHERE msg_id=@msg_id
			return(0)
		end

		If @command=1
		 begin
			SELECT msg_id, msgFile, Descripcion, 1 as FileExists from ccMsgFiles where msgFile not like '%TTS|%' order by msg_id
			return(0)
		 end

		if @command=2
		 begin
			if EXISTS(select msgFile from ccMsgFiles where msgFile=@msgFile)
			 begin
				select 1, 'Nombre en Uso'
				return(0)
			 end

			Insert ccMsgFiles (msgFile, descripcion) select @msgFile, @Description
			return(0)
		 end

		if @command=3
		 begin
			if exists(select msg_id from ccInboundMsgs where msg_id=@msg_id)
			 begin
				select 1 --'Este Mensaje tiene alguna Especialidad asignada'
				return(0)
			 end

			if exists(select msg_id from ccCampsMsgs where msg_id=@msg_id)
			 begin
				select 1 --'Este Mensaje tiene alguna campaña asignada'
				return(0)
			 end

			Delete ccMsgFiles Where msg_id=@msg_id
			return(0)
		 end

		if @command=4
		 begin
			Update ccMsgFiles set msgFile=@msgFile, descripcion=@Description Where msg_id=@msg_id
			return(0)
		 end

		 if @command=5
		 begin
			if EXISTS(select msgFile from ccMsgFiles where descripcion= @Description)
			 begin
				select 1, 'Nombre en Uso'
				return(0)
			 end

			Insert ccMsgFiles (msgFile, descripcion) select @msgFile, @Description
			return scope_identity()
		 end

		 if @command=6
		 begin
			Update ccMsgFiles set [length]=@length Where msg_id=@msg_id
			return(0)
		 end

		set nocount off