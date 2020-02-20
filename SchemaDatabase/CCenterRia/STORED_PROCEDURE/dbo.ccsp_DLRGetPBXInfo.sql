CREATE procedure [dbo].[ccsp_DLRGetPBXInfo]
				@pbx_id int
				AS
				set nocount on

				declare @port varchar(5), @remotes varchar(300)
				select @port = valor from ccsettings where setting_id=119
				select @remotes = valor from ccsettings where setting_id=143
				select
				case when charindex(':',pbxIp)>0 then substring(pbxIp, 0, charindex(':',pbxIp)) else pbxIp end pbxUri,
				case when charindex(':',pbxIp)>0 then substring(pbxIp, charindex(':',pbxIp)+1, 5) else @port end port
				from
				(select
				substring(value,0,charindex('|',value)) pbxId,
				substring(value,charindex('|',value)+1,len(value)) pbxIp
				from dbo.fn_RIASplitDelimited(@remotes, ',')
				where cast(substring(value,0,charindex('|',value)) as int)=@pbx_id) x

				set nocount off