/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jose Velasco. Jesus Gallardo
Date: 2015/03/10
Description:

	------ ALTER PROCEDURE ccspRepAgentSession  a guardar


Database: ccReportsRia
Required version: 27

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)


/* Version to release (use the version of your own databse)*/
set @version = 28

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

	set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
	DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE'
	EXEC(@sql)

	set @process = 'Alter table - ccmenus'
	set @sql='if not exists (select * from sys.columns where name = N''release'' and Object_ID = Object_ID(N''ccmenus''))
			ALTER TABLE ccmenus ADD release varchar(max) not null default('''')'
	EXEC(@sql)

	set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
		ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE'
	EXEC(@sql)

	set @process ='CREATE TABLE [dbo].[ccloglogin]-------------'
	set @sql = 'if not exists (select * from sys.tables where name = N''ccloglogin'')
 			begin

				CREATE TABLE [dbo].[ccloglogin](
				[User_id] [smallint] NOT NULL,
				[Extension] [varchar](7) NOT NULL,
				[TipoMov] [tinyint] NOT NULL,
				[fecha] [datetime] NOT NULL
				) ON [PRIMARY]
			end'
	EXEC(@sql)


	set @process ='ALTER TABLE [dbo].[ccloglogin]----------------'
	set @sql = '
	if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccLogLogin_fecha'')
 begin
  ALTER TABLE [dbo].[ccloglogin] ADD  CONSTRAINT [DF_ccLogLogin_fecha]  DEFAULT (getdate()) FOR [fecha]
 end'
	EXEC(@sql)


	set @process ='INSERT INTO ccReportsRia.dbo.reportsfilters---------------'
	set @sql = 'IF (SELECT COUNT (*) FROM ccReportsRia.dbo.reportsfilters WHERE ID = 9010) = 0
	BEGIN
		INSERT INTO ccReportsRia.dbo.reportsfilters VALUES(''General'',''CRMxTemplates'',9010)
	END'
	EXEC(@sql)

	set @process ='Alter PROCEDURE [dbo].[GetReportMenus]------------------------'
	set @sql = 'Alter PROCEDURE [dbo].[GetReportMenus]
@userId int,
@activeChat tinyint,
@activeAVRS tinyint,
@activeCRM tinyint=0,
@activeEmail tinyint=0
AS
BEGIN

select menu_id,
	substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip)) as menu_descrip,
	nullif(parent,menu_id) as parent,Nivel,ordengral,release
	into #tempCCMenus from ccMenus with(nolock)
	where type = 3 and menu_id >= 2000 and(
		(menu_id not in (
		3130,3131,3132,3133,3134,3135,3136,
		8050,8060,8061,8062,8063,8070,8071,8072,8080,
		9000,9010,
		10000,10010,10020,10030,10040
		))
		or  (@activeChat = 1 and menu_id in (3130,3131,3132,3133,3134,3135,3136))
		or  (@activeAVRS = 1 and menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080) )
		or  (@activeCRM = 1 and menu_id in (9000,9010) )
		or  (@activeEmail = 1 and menu_id in (10000,10010,10020,10030,10040) )
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

select distinct Nivel,menu_descrip,menu_id,ordengral,parent,release into #tempCCMenusUser from ccMenusUserRec order by menu_id

select distinct A.Nivel, A.menu_descrip, A.menu_id, A.ordengral,5 filtersType,A.release from #tempCCMenusUser A
where  menu_id not in
	(select distinct parent from  #tempCCMenus where Nivel=''C'' and parent not in (select distinct  A.parent from  #tempCCMenusUser A where A.Nivel=''C''))
order by menu_id

drop table #tempCCMenus
drop table #tempCCMenusUser

END '
	EXEC(@sql)


	set @process = 'ALTER PROCEDURE [dbo].[ccspRepIVRDetail]---------'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepIVRDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin


	create table #IVRLlamadas(
	IVR_id int not null,
	cal_ani varchar(30) null,
	User_id smallint not null,
	calif_id smallint not null,
	cal_id int not null,
	date datetime not null,
	dnis varchar(50) not null
	)

	insert into #IVRLlamadas
	select A.Ivr_id,A.cal_ani,isnull(B.user_id,0) as [user_id],isnull(B.calif_id,0) as [calif_id]
	,isnull(B.cal_id,0) as [cal_id],A.date,A.dnis
	from IVRCallsIn as A
	left join ccCallsIn As B on  A.IVR_id = B.IVR_id
	where date >= @from and date < @to
	and A.dnis <> ''''


	delete from RepIVRDetail with(rowlock)
	where date >= @from AND date < @to

	insert into RepIVRDetail
		select #IVRLlamadas.date as fecha, cal_ani as telefono
			, isNull(u.nombres + '' '' + u.apellidopaterno + '' '' + u.apellidomaterno,'''') as nombre
			, isnull(calif.description, #IVRLlamadas.calif_id) as calificacion, cal_id as cal_id
			, isnull(
			(
				select selectedOption + '',''	from IVROptions
				where IVROptions.ivr_id = #IVRLlamadas.ivr_id
				order by IVROptions.date for xml path('''')
			),'''') as opciones
			, isnull(datediff( ss, date, maxdate),0) as tiempo,
			datepart(yyyy,[date]),
			datepart(mm,[date]),
			datepart(dd,[date]),
			datepart(hh,[date]),
			datepart(mi,[date]),
			dnis as DNIS
			from #IVRLlamadas
			left join
			(
				select ivr_id, max(date) as maxDate from IVROptions
				group by ivr_id
			) optTime on #IVRLlamadas.ivr_id = optTime.ivr_id
			left join ccusers u on (u.user_id = #IVRLlamadas.user_id)
			left join cctipocalif calif on (calif.calif_id = #IVRLlamadas.calif_id)
			where #IVRLlamadas.date >= @from and #IVRLlamadas.date < @to
			order by date

	drop table #IVRLlamadas
	end'
	EXEC(@Sql)

	set @process ='DROP TRIGGER [trigPosicionEspecialidad]------------'
	set @sql = 'IF EXISTS (select * from sys.triggers where name = ''trigPosicionEspecialidad'')
				DROP TRIGGER [trigPosicionEspecialidad]'

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