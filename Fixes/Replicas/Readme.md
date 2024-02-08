
# Replicas es necesario eliminar las replicas 

Es necesario correr el script [QuitarReplicas.sql](./QuitarReplicas.sql) en las bases
- CCenterRIA
- CCRecorderRIA
- CCReportsRIA

Se debe validar que no tengamos un error al eliminar las réplicas es necesario revisar que no tengamos 
- Trigger
- columna rowguid
- índices de replicas

en caso de ser necesario correr el siguiente script [QuitaRelacionROWGUID.sql](./QuitaRelacionROWGUID.sql)

Después es necesario correr los jobs de replicas en el siguiente orden

|  Archivo  |  Base Datos | Descripción |
|---|---|---|
| 00_TablaReplicasCCenteRIA             | CCenterRIA  | Genera una tabla para las publicaciones y los artículos de cada uno |
| 00_TablaReplicasCCRecorderRIA         | CCRecorderRIA  | Genera una tabla para las publicaciones y los artículos de cada uno |
| 00_TablaReplicasCCReportsRIA         | CCReportsRIA  | Genera una tabla para las publicaciones y los artículos de cada uno |
| 02_CreateDistributorCCenterRIA        | CCenterRIA  | Crea la base del distribuidor para las réplicas |
| 03_CreateDistributorCCRecorderRIA     | CCRecorderRIA  | Crea la base del distribuidor para las réplicas |
| 04_CreatePublicationCCenterRIA        | CCenterRIA | Genera las publicaciones |
| 05_CreatePublicationCCRecorderRIA     | CCRecorderRIA  | Genera las publicaciones |
| 06_AddSubcriptorCCReportsRIAPublicatorCCenterRIA      | CCenterRIA  | Prepara las publicaciones para saber quién es el subscriptor local |
| 07_AddSubcriptorCCRecorderRIAPublicatorCCenterRIA     | CCenterRIA  | Prepara las publicaciones para saber quién es el subscriptor local |
| 08_AddSubcriptorCCReportsRIAPublicatorCCRecorderRIA   | CCRecorderRIA  | Prepara las publicaciones para saber quién es el subscriptor local |
| 09_AddLocalSubcriptorCCReportsRIAPublicatorCCenterRIA | CCReportsRIA  | Genera las subscripciones |
| 08_AddSubcriptorCCReportsRIAPublicatorCCRecorderRIA   | CCRecorderRIA  | Prepara las publicaciones para saber quién es el subscriptor local |
| 10_AddLocalSubcriptorCCRecorderRIAPublicatorCCenterRIA    | CCRecorderRIA  | Genera las subscripciones |
| 11_AddLocalSubcriptorCCReportsRIAPublicatorCCRecorderRIA  | CCReportsRIA  | Genera las subscripciones |
| 12_InitSnapshotCCRecorderRIAToCCReportsRIA                | CCRecorderRIA  | Inicia el snapShot de las publicaciones |
| 13_InitSnapshotCCenterRIAToCCReportsRIA                   | CCenterRIA  | Inicia el snapShot de las publicaciones |
| 14_InitSubcriptionCCReportsRIA                            | CCReportsRIA  | Inicia el snapShot de las subscripciones y prende los jobs de reportes |
| 15_InitSubcriptionCCRecorderRIA                           | CCRecorderRIA  | Inicia el snapShot de las subscripciones |
| 16_CleanReplicationCCenterRIA                           | CCenterRIA  | Depura los registros de las tablas de Msmerge* |

Los últimos dos scripts de agregaron ya que en el proceso normal al querer iniciar varias replicas al inicio este genera bloqueos y no terminaban de procesar la información

Otro cambio importante se quitó los índices, trigger y Constraints en las bases de suscripción esto para que no tengamos procesos que no son necesarios en las replicaciones de información ya que estos son solo de lectura 

Por ultimo es necesario correr el siguiente script Reportes_Cambios.sql este se debe correr dependiendo de la version instalada en el cliente
