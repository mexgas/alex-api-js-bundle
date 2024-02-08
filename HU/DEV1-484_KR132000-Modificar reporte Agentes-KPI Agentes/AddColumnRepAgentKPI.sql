if not exists (select * from sys.columns where name = N'callsAvgTimeCustom' and Object_ID = Object_ID(N'RepAgentKPI'))
begin
    ALTER TABLE RepAgentKPI ADD callsAvgTimeCustom [decimal](10, 0) NULL;
end