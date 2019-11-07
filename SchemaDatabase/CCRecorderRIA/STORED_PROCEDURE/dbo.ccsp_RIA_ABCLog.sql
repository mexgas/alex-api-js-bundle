CREATE PROCEDURE [dbo].[ccsp_RIA_ABCLog] @moduleId SMALLINT, @operationType SMALLINT, @login VARCHAR(20), @target VARCHAR(250), @value VARCHAR(250)
				AS
				SET NOCOUNT ON

				declare @cw_dbpath varchar(250)
				declare @sql varchar(max)
				select @cw_dbpath=par_valor from trec_parametros where par_id=49
				set @sql = 'exec '+@cw_dbpath+'ccsp_RIA_ABCLog @option=2'+
							',@operationType='+cast(@operationType as varchar(5))+
							',@moduleId='+cast(@moduleId as varchar(5))+
							',@login='+char(39)+@login+char(39)+
							',@value='+char(39)+@value+char(39)+
							',@target='+char(39)+@target+char(39)

				exec(@sql)

				SET NOCOUNT OFF