/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2016/04/11
Description:

	Se agrega fix para ejeccuion por tiempo report master process
Database: ccReportsRiaPara
Required version: 36

----ALTER PROCEDURE [dbo].[ccspRepCatalogos]

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 37

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)


		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off