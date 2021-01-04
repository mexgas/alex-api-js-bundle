SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 95

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		

		SET @process = 'CW-4645 Alter SP ccspGetTranslatedReports'
		SET @sql = 'ALTER procedure [dbo].[ccspGetTranslatedReports] @id int as
declare @columns nvarchar(max)
select @columns =[columns] from [TranslatedReports] where id = @id
if @columns is null begin
	set @columns=''''
end

select @columns [columns]'
		EXEC(@sql)

		SET @process = 'CW-4645 Alter SP GetReportMenus'
		SET @sql = 'ALTER PROCEDURE [dbo].[GetReportMenus]
--@userId = 10,@activeChat = 1,
--@activeAVRS = 1,
--@activeEmail =1,
--@activeTwitter =1

@userId int,
@activeChat tinyint,
@activeAVRS tinyint,
@activeCRM tinyint=0,
@activeEmail tinyint=0,
@activeTwitter tinyint=0
AS
BEGIN

select menu_id,
	substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip)) as menu_descrip,
	nullif(parent,menu_id) as parent,Nivel,ordengral,release
	into #tempCCMenus
	from ccMenus with(nolock)
	where type = 3 and menu_id >= 2000 and(
		(menu_id not in (
		3130,3131,3132,3133,3134,3135,3136,
		8050,8060,8061,8062,8063,8070,8071,8072,8080,
		9000,9010,
		10000,10010,10020,10030,10040,
		11000,11010,11020,11030,11040
		))
		or  (@activeChat = 1 and menu_id in (3130,3131,3132,3133,3134,3135,3136))
		or  (@activeAVRS = 1 and menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080) )
		or  (@activeCRM = 1 and menu_id in (9000,9010) )
		or  (@activeEmail = 1 and menu_id in (10000,10010,10020,10030,10040) )
		or (@activeTwitter = 1 and menu_id in (11000,11010,11020,11030,11040))
		)
		order by menu_id


;WITH ccMenusUserRec(Nivel, menu_descrip, menu_id, ordengral, parent,release)
AS
(
	select
		distinct b.Nivel as Nivel,
		b.menu_descrip as menu_descrip,
		b.menu_id as menu_id,
		b.ordengral as ordengral,
		b.parent as parent,b.release
		from #tempCCMenus as b
		inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId and b.menu_id<>b.parent and a.type = 3
	UNION ALL


--RECURSIViDAD
	select a.Nivel, a.menu_descrip, a.menu_id, a.ordengral, a.parent,a.release
		from #tempCCMenus a inner join ccMenusUserRec b on a.menu_id=b.parent
)

select distinct Nivel,menu_descrip,menu_id,ordengral,parent,release into #tempCCMenusUser from ccMenusUserRec order by ordengral,menu_id

select distinct A.Nivel, A.menu_descrip, A.menu_id, A.ordengral,5 filtersType,A.release,parent from #tempCCMenusUser A
where  menu_id not in
	(select distinct parent from  #tempCCMenus where Nivel=''C'' and parent not in (select distinct  A.parent from  #tempCCMenusUser A where A.Nivel=''C''))
order by ordengral,menu_id

drop table #tempCCMenus
drop table #tempCCMenusUser

END '
		EXEC(@sql)

		
				
		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF

