set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 71
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try
	
	SET @process = 'CW-4212 drop CW_trsp_Get_Ftp_Server_Values'
		SET @sql = 'if exists (select * from sys.procedures where name = N''CW_trsp_Get_Ftp_Server_Values'')
    				begin
        				DROP PROCEDURE CW_trsp_Get_Ftp_Server_Values;
    				end'
    EXEC (@sql)


    SET @process = 'CW-4212 create SP CW_trsp_Get_Ftp_Server_Values'
		SET @sql = 'CREATE PROCEDURE CW_trsp_Get_Ftp_Server_Values

					AS

					CREATE TABLE #Values_Ftp (
						FtpProtocol int,
						FtpServer VARCHAR(50),
						FtpUser VARCHAR(100),
						FtpPassword VARCHAR(200),
						FtpPort int,
					);

					declare	@protocol int
					declare	@server VARCHAR(50)
					declare	@user VARCHAR(200)
					declare	@password VARCHAR(200)
					declare	@port int

					select @protocol= par_valor FROM TREC_PARAMETROS
								WHERE par_id=42

					select @server= par_valor FROM TREC_PARAMETROS
								WHERE par_id=43

					select @user= par_valor FROM TREC_PARAMETROS
								WHERE par_id=44

					select @password= par_valor FROM TREC_PARAMETROS
								WHERE par_id=45

					select @port= par_valor FROM TREC_PARAMETROS
								WHERE par_id=46

					insert into #Values_Ftp VALUES (@protocol,@server,@user,@password,@port)

					select * from #Values_Ftp 
					DROP TABLE #Values_Ftp'
	EXEC (@sql)

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
