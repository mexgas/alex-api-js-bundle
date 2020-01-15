CREATE VIEW CRMxView1 as select crmx_Date, crmxSource,crmx_calId,crmx_callKey,crmx_telephone,crmx_duration,crmx_userId,crmx_username,crmx_dispositionId ,crmx_disposition,crmx_subDispositionId,crmx_subDisposition,
isnull([textInput1],'') AS [textInput1],isnull([textInput2],'') AS [textInput2] from(
						select a.crmxRecordId, a.dateValue AS crmx_Date, a.serviceSource AS crmxSource,
						callData.value('(/callData/call/@id)[1]','varchar(50)') crmx_calId,
						callData.value('(/callData/call/@key)[1]','varchar(50)') crmx_callKey,
						callData.value('(/callData/call/@telephone)[1]','varchar(50)') crmx_telephone,
						callData.value('(/callData/call/@length)[1]','varchar(50)') crmx_duration,
						callData.value('(/callData/agent/@id)[1]','varchar(50)') crmx_userId,
						callData.value('(/callData/agent/@name)[1]','varchar(50)') crmx_username,
						callData.value('(/callData/disposition/@id)[1]','varchar(50)') crmx_dispositionId,
						callData.value('(/callData/disposition/@name)[1]','varchar(50)') crmx_disposition,
						callData.value('(/callData/subdisposition/@id)[1]','varchar(50)') crmx_subDispositionId,
						callData.value('(/callData/subdisposition/@name)[1]','varchar(50)') crmx_subDisposition, 
						B.dataValue, B.componentId
						from CRMxData1 as A 
						inner join CRMxRawData1 B WITH(NOLOCK) on A.crmxRecordId=B.crmxRecordId
						where A.callData is not null and 
						B.componentId  IN('textInput1','textInput2')

						

						) as SourceTable
						pivot(
						MAX(dataValue)
						FOR componentId IN([textInput1],[textInput2])
						)as PivoTable