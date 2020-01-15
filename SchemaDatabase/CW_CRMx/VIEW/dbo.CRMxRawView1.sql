CREATE VIEW CRMxRawView1 as select a.crmxRecordId as crmxRecordId ,  isnull(MAX([textInput1]),'') AS [textInput1],isnull(MAX([textInput2]),'') AS [textInput2]
						from (select crmxRecordId as RowID,dataValue,componentId from CRMxRawData1 WITH(NOLOCK)) as P
						pivot (max(dataValue) for componentId in ([textInput1],[textInput2]))  as PV_descriptionT, CRMxData1 a
						where a.crmxRecordId = RowID
						group by [RowID], a.serviceSource, a.crmxRecordId