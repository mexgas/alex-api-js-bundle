--drop table migration

IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE [name] = 'migration')
	BEGIN
		CREATE TABLE [dbo].[migration](
		[id] [int] NOT NULL,
		[description] [varchar](255) NOT NULL,		
		[status] [int] NOT NULL,
		[error] [nvarchar](max) NOT NULL,
		[dateStart] datetime NOT NULL,
		[dateEnd] datetime NOT NULL,
		[db_name] [sysname] NULL,
		) ON [PRIMARY]		
	END
	truncate table migration;

insert into migration
select
ROW_NUMBER() OVER(ORDER BY B.name desc)+99 AS id, B.name as [description],0 as status,'' as error,'1901-01-01' as dateStart,'1901-01-01' as dateEnd
,null db_name

from sysmergesubscriptions A
inner join sysmergepublications B on A.pubid=B.pubid
where A.db_name in('CCReportsRIA')
order by B.name,A.db_name


;with dbNamePublication as(

select A.description,s.db_name,S.status 
from migration A
inner join sysmergepublications B on A.description=B.name
inner join sysmergesubscriptions S on B.pubid=S.pubid 
where S.db_name in('CCenterRIA','CCRecorderRIA')
)
update M
set M.db_name=A.db_name
from dbNamePublication A
inner join migration M on A.description=M.description
