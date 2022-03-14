CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
            @user_id varchar(255),
            @Type int
            AS
            set nocount on

            declare @isRoot int;

            if exists (Select Rol_id from ccUsers A join ccUsers_Roles B on A.User_id = B.User_id where A.User_id = @user_id and rol_id = 7) set @isRoot = 1 else set @isRoot = 0;
            print @isRoot

            IF @isRoot = 1
            BEGIN
            
            
                Select 
                User_id as AgentId, 
                Login as Username, Nombres + ' ' + isNull(apellidoPaterno,'') + ' ' + isNull(ApellidoMaterno, '') as FullName, 
                cast(dialMask & 1 as int) as AllowCellPhoneCalls,
                cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
                cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
                cast( xfermask as int) as AllowTransferCalls, 
                cast(CanChangeStatus as tinyint) CanChangeStatus,
                cast(XferAgents as tinyint) XferAgents,
                ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
                
                cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
                ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode
            from 
                ccUsers
            where 
                tipoUser_id = 1
            return(0)
            END
            ELSE
            BEGIN
                Select distinct 
                A.User_id as AgentId, 
                Login as Username, Nombres + ' ' + isNull(apellidoPaterno,'') + ' ' + isNull(ApellidoMaterno, '') as FullName, 
                cast(dialMask & 1 as int) as AllowCellPhoneCalls,
                cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
                cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
                cast( xfermask as int) as AllowTransferCalls, 
                cast(CanChangeStatus as tinyint) CanChangeStatus,
                cast(XferAgents as tinyint) XferAgents,
                ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
                cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
                ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode
            from 
                ccUsers A
            join ccRIAWorkGroupUsers B on 
                A.user_id = B.user_id
            where 
                tipoUser_id = 1 and 
                IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
            return(0)
            END
            set nocount off