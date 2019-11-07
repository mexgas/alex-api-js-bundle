CREATE  PROCEDURE [dbo].[ccsp_IVRGetVoxFiles]
		@Inbound_ID as smallint,
		@Tipo tinyint
		AS
		/*
		SP para traer los Archivox Vox que va utilizan dentro del IVR x
		*/
		select orden, V.msgfile, queue,[length]
		from ccInboundMsgs VE join ccMsgfiles V
		on VE.Msg_id = V.Msg_id
		where Inbound_id = @Inbound_ID
		-- and tipomsg_id =@Tipo -- modificado para CW -V
		and type =@Tipo
		order by orden