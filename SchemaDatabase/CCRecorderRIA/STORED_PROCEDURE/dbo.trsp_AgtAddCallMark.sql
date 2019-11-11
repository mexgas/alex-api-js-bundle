-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AgtAddCallMark]
	-- Add the parameters for the stored procedure here
	@timeMark varchar(20),
    @callId   int,
    @callType   int,
    @userId   int
AS
BEGIN
	insert into RIA_MARCAS (call_id, tipo_llamada,user_id,marca,tipo_marca)values(@callId,@callType,@userId,@timeMark,1)
END