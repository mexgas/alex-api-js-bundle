CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
                    @user_id varchar(MAX),
                    @permissionName VARCHAR(255),
                    @permissionValue INT
                AS
                SET NOCOUNT ON

                DECLARE @changeBit INT

                SET @changeBit =
                CASE
                    WHEN @permissionName = 'AllowCellPhoneCalls' or @permissionName = 'startStopRecording' or @permissionName = 'XferManual' or @permissionName = 'AllowTransferCalls' or @permissionName = 'AgentPermissionDailing'
                    THEN 1
                    WHEN @permissionName = 'AllowLongDistanceCalls' or @permissionName = 'XferExt' or @permissionName = 'DailingMode'
                    THEN 2
                    WHEN @permissionName = 'AllowLocalCalls' or @permissionName = 'XferCamps'
                    THEN 4
                    WHEN @permissionName = 'XferAgents'
                    THEN 8
                    ELSE 0
                END

                IF @user_id IS NOT NULL
                BEGIN
                    
                    UPDATE
                        ccUsers
                    SET DialMask =
                        CASE
                        WHEN @permissionName = 'AllowCellPhoneCalls'
                        OR @permissionName = 'AllowLongDistanceCalls'
                        OR @permissionName = 'AllowLocalCalls'
                        THEN 
                            CASE
                            WHEN @permissionValue = 1
                            THEN
                                CASE
                                WHEN (DialMask & @changeBit) <> @changeBit
                                THEN DialMask ^ @changeBit
                                ELSE DialMask
                                END
                            WHEN @permissionValue = 0
                            THEN
                                CASE
                                WHEN (DialMask & @changeBit) = @changeBit
                                THEN DialMask ^ @changeBit
                                ELSE DialMask
                                END
                            END	
                        ELSE DialMask
                        END,
                        
                        XferMask =
                        CASE
                        WHEN @permissionName = 'AllowTransferCalls'
                        THEN
                            CASE
                            WHEN @permissionValue = 1
                            THEN
                                CASE
                                WHEN (XferMask & @changeBit) <> @changeBit
                                THEN XferMask ^ @changeBit
                                ELSE XferMask
                                END
                            WHEN @permissionValue = 0
                            THEN
                                CASE
                                WHEN (XferMask & @changeBit) = @changeBit
                                THEN XferMask ^ @changeBit
                                ELSE XferMask
                                END
                            END
                        ELSE XferMask
                        END,

                        XferAgents =
                        CASE
                        WHEN @permissionName = 'XferAgents'
                        OR @permissionName = 'XferCamps' 
                        OR @permissionName = 'XferExt' 
                        OR @permissionName = 'XferManual' 
                        THEN 
                            CASE
                            WHEN @permissionValue = 1
                            THEN
                                CASE
                                WHEN (XferAgents & @changeBit) <> @changeBit
                                THEN XferAgents ^ @changeBit
                                ELSE XferAgents
                                END
                            WHEN @permissionValue = 0
                            THEN
                                CASE
                                WHEN (XferAgents & @changeBit) = @changeBit
                                THEN XferAgents ^ @changeBit
                                ELSE XferAgents
                                END
                            END
                        ELSE XferAgents
                        END,

						startStopRecording =
						CASE
						WHEN @permissionName = 'startStopRecording' 
						THEN 
							CASE
							WHEN @permissionValue = 1
							THEN 1
							WHEN @permissionValue = 0
							THEN 0
							END
						ELSE startStopRecording
						END,

                        DialingMode = 
                        CASE
                        WHEN @permissionName = 'DailingMode' 
                        OR @permissionName = 'AgentPermissionDailing' 
                        THEN 
                            CASE
                            WHEN @permissionValue = 1
                            THEN
                                CASE
                                WHEN (DialingMode & @changeBit) <> @changeBit
                                THEN DialingMode ^ @changeBit
                                ELSE DialingMode
                                END
                            WHEN @permissionValue = 0
                            THEN
                                CASE
                                WHEN (DialingMode & @changeBit) = @changeBit
                                THEN DialingMode ^ @changeBit
                                ELSE DialingMode
                                END
                            END	
                        ELSE DialingMode
                        END
                    WHERE User_id IN (select value from dbo.fn_RIASplitDelimited(@user_id,','))
                END

                SET NOCOUNT OFF