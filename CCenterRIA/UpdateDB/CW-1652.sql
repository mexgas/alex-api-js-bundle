/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2018/04/19
Description:



Database: CCenterRia
Required version: 119.119.131

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
set @versionfix = 134
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 133
	begin
		begin tran
		begin try

		set @process = 'CW-1652 Version 119.133 -- Remove conflict Replication'
    	set @Sql= 'SELECT s.conflict_table, c.rowguid, c.origin_datasource
      INTO #temp_conflicts
      FROM dbo.MSmerge_conflicts_info c
      JOIN sysmergearticles s
      ON c.tablenick = s.nickname
 
--Setup local variables
DECLARE @conflict_table nvarchar(255)
DECLARE @row uniqueidentifier
DECLARE @origin_datasource nvarchar(255)
 
--Step through conflicts and purge by RowGuid
DECLARE conflict_cursor CURSOR FOR
   SELECT conflict_table, rowguid, origin_datasource
   FROM #temp_conflicts
OPEN conflict_cursor;
FETCH NEXT FROM conflict_cursor INTO @conflict_table, @row, @origin_datasource;
WHILE @@FETCH_STATUS = 0
BEGIN
 
      --Purge conflict as "resolved"
    EXEC sp_deletemergeconflictrow
      @conflict_table = @conflict_table,        -- conflict table name from sysmergearticles
      @rowguid = @row,                                      -- row identifier from msmerge_conflicts_info
      @origin_datasource = @origin_datasource   -- origin of the conflict from msmerge_conflicts_info
  
   --Retrieve next conflict to purge
   FETCH NEXT FROM conflict_cursor
   INTO @conflict_table, @row, @origin_datasource;
END
 
CLOSE conflict_cursor;
DEALLOCATE conflict_cursor;
DROP table #temp_conflicts'
    	EXEC(@Sql)    	
		
	
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
