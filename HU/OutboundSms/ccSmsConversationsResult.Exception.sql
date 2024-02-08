if not exists (select * from sys.columns where name = N'Exception' and Object_ID = Object_ID(N'ccSmsConversationsResult'))
begin
    alter table ccSmsConversationsResult add Exception int null
end
update ccSmsConversationsResult set Exception=0 where Exception is null