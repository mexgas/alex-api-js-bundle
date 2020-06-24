select CONVERT(date,A.dateStart) dateStart, A.nameProcess,B.nameProcess,C.nameProcess, A.IndividualQuery,A.ParentQuery,A.DatabaseName
from Performance A 
left join (select nameProcess,IndividualQuery,ParentQuery,DatabaseName from Performance where nameProcess='E/S') B
on A.ParentQuery=B.ParentQuery
left join (select nameProcess,IndividualQuery,ParentQuery,DatabaseName from Performance where nameProcess='CPU') C
on A.ParentQuery=C.ParentQuery
where A.nameProcess='Block' and (B.nameProcess is not null or C.nameProcess is not null) order by dateStart desc