CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
                    @user_id varchar(255),
                    @Type int
                AS
                set nocount on

                Select distinct A.User_id as AgentId, Login as Username, Nombres + ' ' + isNull(apellidoPaterno,'') + ' ' +
                isNull(ApellidoMaterno, '') as FullName, cast(dialMask & 1 as int) as AllowCellPhoneCalls,
                cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
                cast( xfermask as int) as AllowTransferCalls, cast(CanChangeStatus as tinyint) CanChangeStatus,
                cast(XferAgents as tinyint) XferAgents,
                ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording
                from ccUsers A
                join ccRIAWorkGroupUsers B on A.user_id = B.user_id
                where tipoUser_id = 1 and IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
                return(0)

                set nocount off