CREATE PROCEDURE [dbo].[ccsp_WhatsAppUnsentMessages]
@Option TINYINT = 0, 
@Message_uuid VARCHAR(150) = '',
@ClientNumber VARCHAR(25) = '', 
@VonageNumber VARCHAR(25) = '', 
@Timestamp DATETIME = NULL,
@MessageType VARCHAR(50) = '', 
@Content VARCHAR(MAX) = '',
@MessagesList VARCHAR(max) = NULL,
@Status varchar(100)='',
@Currency varchar(50)='EUR',
@Price varchar(14)='0.0000',
@Client_ref int=0
AS
SET NOCOUNT ON

IF @Option IS NOT NULL
BEGIN 
    IF  @Option = 0  -- Save Unsent Message
    BEGIN
        IF @Message_uuid IS NOT NULL AND NOT EXISTS (SELECT * FROM ccWhatsAppUnsentMessages WHERE Message_uuid = @Message_uuid)
        BEGIN
            INSERT INTO ccWhatsAppUnsentMessages(Message_uuid, ClientNumber, VonageNumber, Timestamp, MessageType, Content)
            VALUES(@Message_uuid, @ClientNumber, @VonageNumber, @Timestamp, @MessageType, @Content)
            SELECT 1
        END
        ELSE BEGIN SELECT 0 END
    END
    else IF  @Option = 1  -- Get Unsent Messages
    BEGIN
        SELECT TOP 100 *FROM ccWhatsAppUnsentMessages order by ClientNumber,Timestamp
    END
    else  IF  @Option = 2  -- Delete Unsent Message
    BEGIN
        DELETE UnsentMessages FROM ccWhatsAppUnsentMessages UnsentMessages
        INNER JOIN  dbo.fn_RIASplitDelimited(@MessagesList, '|') MessagesList
        ON UnsentMessages.Message_uuid = MessagesList.Value
    END
    else IF  @Option = 3  -- 
    BEGIN
        if @Content is not null or @Content<>'' begin
            INSERT INTO ccWhatsAppUnsetMessagesMCSbyWebApi(Content)         VALUES(@Content)
        end
    END
    else IF  @Option = 4  -- 
    BEGIN
        select TOP 100 * from ccWhatsAppUnsetMessagesMCSbyWebApi
    END

    else IF  @Option = 5  -- 
    BEGIN
        DELETE UnsentMessages FROM ccWhatsAppUnsetMessagesMCSbyWebApi UnsentMessages
        INNER JOIN  dbo.fn_RIASplitDelimited(@MessagesList, '|') MessagesList
        ON UnsentMessages.Id = MessagesList.Value
    END
    else IF  @Option = 6  -- Save Unsent Message Status
    BEGIN       
        if NOT EXISTS (SELECT * FROM ccWhatsAppUnsetStatusMessages WHERE Message_uuid = @Message_uuid and Client_ref=@Client_ref) begin
            INSERT INTO ccWhatsAppUnsetStatusMessages(Message_uuid, ClientNumber, VonageNumber, Timestamp, MessageType,
            Status,Currency, Price, Client_ref, Content)
            VALUES(@Message_uuid, @ClientNumber, @VonageNumber, @Timestamp, @MessageType,@Status,@Currency,@Price, @Client_ref ,@Content)           
        end
        else begin
            update ccWhatsAppUnsetStatusMessages
            set Status=@Status,Currency=@Currency,Price=@Price,Timestamp=@Timestamp,Content=@Content
            where Message_uuid=@Message_uuid and Client_ref=@Client_ref
        end
    END
    else IF  @Option = 7  -- Save Unsent Message Status
    BEGIN       
        SELECT top 100 * FROM ccWhatsAppUnsetStatusMessages order by ClientNumber,Timestamp
    END
    else IF  @Option = 8  -- 
    BEGIN
        DELETE UnsentMessages FROM ccWhatsAppUnsetStatusMessages UnsentMessages
        INNER JOIN  dbo.fn_RIASplitDelimited(@MessagesList, '|') MessagesList
        ON UnsentMessages.Message_uuid = MessagesList.Value
    END
END

SET NOCOUNT OFF