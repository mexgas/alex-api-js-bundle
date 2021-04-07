CREATE PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                                         @InboundId AS SMALLINT
            AS
            BEGIN
                set nocount on;

                if(@Option = 1)
                begin
                    select 
                        ISNULL(count (*), 0) as Calls,
                        ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
                        ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
                        ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
                        ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
                        ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
                        ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
                        ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
                        ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
                        ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
                        THEN 1 ELSE NULL END), 0) AS Other
                    from ccCallsIn a (nolock)
                    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId

                end
                
            END