CREATE procedure [dbo].[ccsp_DLRGetSIPCodeMap]
			AS
			set nocount on

			declare @country int
			select @country = valor from ccsettings where setting_id=104
			select hash,mappedCode from ccSIPCodeMap nolock where country=@country