CREATE PROCEDURE CW_trsp_Get_Ftp_Server_Values

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
					DROP TABLE #Values_Ftp