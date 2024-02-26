if not exists (select * from sys.columns where name = N'Message' and Object_ID = Object_ID(N'smsccoLogDial'))
begin
    alter Table smsccoLogDial add Message varchar(200) null
end

if not exists (select * from sys.columns c 
inner join sys.types t on c.system_type_id=t.system_type_id
where c.name = N'Bill' and c.Object_ID = Object_ID(N'smsccoLogDial')
and t.name='float'
)
begin
   alter Table smsccoLogDial alter Column Bill decimal(10,2) not null
end


CREATE NONCLUSTERED INDEX IX_smsccoLogDial_3
ON [dbo].[smsccoLogDial] ([SystemApiId])