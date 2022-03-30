set @process = 'CW-6446 Se agrega columna allowsConference'
set @sql = '
    if not exists (select * from sys.columns where name = N''allowsConference'' and Object_ID = Object_ID(N''telefonosTransferencia''))
    begin
        ALTER TABLE telefonosTransferencia ADD allowsConference BIT NOT NULL DEFAULT 1
    end'
EXEC(@sql)


set @process = 'CW-6446 Se modifica ccsptelefonosTransferencia para traer columna allowsConference'
set @sql = '
    ALTER PROCEDURE [dbo].[ccsptelefonosTransferencia]
    @userID INT
    as
    set nocount on

    BEGIN
    declare @value bit
    declare @IDArea int
    set @value = 0
    set @IDArea =1
    select @value = case when valor=''1'' then 1 else 0 end from ccSettings where setting_id = 191

    select @IDArea =IDArea from ccUsers where User_id =@userID
    if @value = 1
        begin
            select numtra_id id, nombre as  name, tel as number, isnull(IDArea,@IDArea) as id_area,  allowsConference 
            from telefonosTransferencia where idarea= @IDArea or IDArea is null order by nombre asc 
        end
        else
        begin
            select numtra_id id, isnull(cast(IDArea as varchar(20) )+'' - ''+  nombre , nombre ) as name, 
            tel as number, isnull(IDArea,@IDArea) as id_area,  allowsConference
            from telefonosTransferencia  order by nombre asc
        end
    END'
EXEC(@sql) 