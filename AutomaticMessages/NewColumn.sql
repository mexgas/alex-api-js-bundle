if not exists (select * from sys.columns where name = N'msgName' and Object_ID = Object_ID(N'ccMsgFiles'))
    begin
        ALTER TABLE ccMsgFiles ADD msgName VARCHAR(40) NULL
    end