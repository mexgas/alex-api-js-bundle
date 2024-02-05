/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K089000

Database: CCenterRia
Required version: 125.37

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 0
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY

        ----------------------------------------------------- BEGIN KR110000 ----------------------------------------------------------------

        SET @process = 'KR110001 TABLE CodesInterDialing'
        SET @sql = '
                    if not exists(select * from sys.tables where name=''CodesInterDialing'')
                    begin
                        create table CodesInterDialing(id int not null identity(1,1), Description varchar (50), ES varchar(max), EN varchar(max), PT varchar(max), Code varchar(25))

                        set identity_insert CodesInterDialing on

                        insert into CodesInterDialing(id, Description, ES, EN, PT)
                        values(1, ''america-code-1'', ''Estados Unidos de América (+1)'', ''United States of America (+1)'', ''Estados Unidos da América (+1)'')
                        ,(2, ''america-code-2'', ''Islas Vírgenes de EE. UU. (+1-340)'', ''Virgin Islands (U.S.) (+1-340)'', ''Ilhas Virgens Americanas (+1-340)'')
                        ,(3, ''america-code-3'', ''Islas Marianas del Norte (+1-670)'', ''Northern Mariana Islands (+1-670)'', ''Ilhas Marianas do Norte (+1-670)'')
                        ,(4, ''america-code-4'', ''Guam (+1-671)'', ''Guam (+1-671)'', ''Guam (+1-671)'')
                        ,(5, ''america-code-5'', ''Samoa Oriental (+1-684)'', ''American Samoa (+1-684)'', ''Samoa Americana  (+1-684)'')
                        ,(6, ''america-code-6'', ''Puerto Rico (+1)'', ''Puerto Rico (+1)'', ''Porto Rico (+1)'')
                        ,(7, ''america-code-7'', ''Canadá (+1)'', ''Canada (+1)'', ''Canadá (+1)'')
                        ,(8, ''america-code-8'', ''Bahamas (+1-242)'', ''Bahamas (+1-242)'', ''Bahamas (+1-242)'')
                        ,(9, ''america-code-9'', ''Barbados (+1-246)'', ''Barbados (+1-246)'', ''Barbados (+1-246)'')
                        ,(10, ''america-code-10'', ''Anguila (+1-264)'', ''Anguilla (+1-264)'', ''Anguila (+1-264)'')
                        ,(11, ''america-code-11'', ''Antigua y Barbuda (+1-268)'', ''Antigua and Barbuda (+1-268)'', ''Antígua e Barbuda (+1-268)'')
                        ,(12, ''america-code-12'', ''Islas Vírgenes Británicas (+1-284)'', ''Virgin Islands (British) (+1-284)'', ''Ilhas Virgens Britânicas (+1-284)'')
                        ,(13, ''america-code-13'', ''Islas Caimán (+1-345)'', ''Cayman Islands (+1-345)'', ''Ilhas Cayman (+1-345)'')
                        ,(14, ''america-code-14'', ''Bermudas (+1-441)'', ''Bermuda (+1-441)'', ''Bermudas (+1-441)'')
                        ,(15, ''america-code-15'', ''Granada (+1-473)'', ''Grenada (+1-473)'', ''Granada (+1-473)'')
                        ,(16, ''america-code-16'', ''Islas Turcas y Caicos (+1-649)'', ''Turks & Caicos (+1-649)'', ''Ilhas Turcos e Caicos (+1-649)'')
                        ,(17, ''america-code-17'', ''Jamaica (+1-876)'', ''Jamaica (+1-876)'', ''Jamaica (+1-876)'')
                        ,(18, ''america-code-18'', ''Montserrat (+1-664)'', ''Montserrat (+1-664)'', ''Montserrat (+1-664)'')
                        ,(19, ''america-code-19'', ''San Martín (zona neerlandesa) (+721)'', ''Sint Maarten (+721)'', ''São Martinho (parte holandesa) (+721)'')
                        ,(20, ''america-code-20'', ''Santa Lucía (+1-758)'', ''St. Lucia (+1-758)'', ''Santa Lúcia (+1-758)'')
                        ,(21, ''america-code-21'', ''Dominica (+1-767)'', ''Dominica (+1-767)'', ''Dominica (+1-767)'')
                        ,(22, ''america-code-22'', ''San Vicente y las Granadinas(+1-784)'', ''St. Vincent and the Grenadines (+1-784)'', ''São Vincente e Granadinas (+1-784)'')
                        ,(23, ''america-code-23'', ''República Dominicana (+1)'', ''Dominican Republic (+1)'', ''República Dominicana (+1)'')
                        ,(24, ''america-code-24'', ''Trinidad y Tobago (+1-868)'', ''Trinidad & Tobago (+1-868)'', ''Trinidad e Tobago (+1-868)'')
                        ,(25, ''america-code-25'', ''San Cristóbal y Nieves (+1-869)'', ''St. Kitts/Nevis (+1-869)'', ''São Cristóvão e Névis (+1-869)'')
                        ,(26, ''america-code-26'', ''Islas Malvinas (+500)'', ''Falkland Islands (+500)'', ''Ilhas Malvinas (+500)'')
                        ,(27, ''america-code-27'', ''Georgia del Sur e Islas Sandwich del Sur (+500)'', ''South Georgia and the South Sandwich Islands (+500)'', ''Ilhas Geórgia do Sul e Sandwich do Sul (+500)'')
                        ,(28, ''america-code-28'', ''Belice (+501)'', ''Belize (+501)'', ''Belize (+501)'')
                        ,(29, ''america-code-29'', ''Guatemala (+502)'', ''Guatemala (+502)'', ''Guatemala (+502)'')
                        ,(30, ''america-code-30'', ''El Salvador (+503)'', ''El Salvador (+503)'', ''El Salvador (+503)'')
                        ,(31, ''america-code-31'', ''Honduras (+504)'', ''Honduras (+504)'', ''Honduras (+504)'')
                        ,(32, ''america-code-32'', ''Nicaragua (+505)'', ''Nicaragua (+505)'', ''Nicarágua (+505)'')
                        ,(33, ''america-code-33'', ''Costa Rica (+506)'', ''Costa Rica (+506)'', ''Costa Rica (+506)'')
                        ,(34, ''america-code-34'', ''Panamá (+507)'', ''Panama (+507)'', ''Panamá (+507)'')
                        ,(35, ''america-code-35'', ''San Pedro y Miquelón (+508)'', ''St. Pierre and Miquelon (+508)'', ''São Pedro e Miquelon (+508)'')
                        ,(36, ''america-code-36'', ''Haití (+509)'', ''Haiti (+509)'', ''Haiti (+509)'')
                        ,(37, ''america-code-37'', ''Perú (+51)'', ''Peru (+51)'', ''Peru (+51)'')
                        ,(38, ''america-code-38'', ''México (+52)'', ''Mexico (+52)'', ''México (+52)'')
                        ,(39, ''america-code-39'', ''Cuba (+53)'', ''Cuba (+53)'', ''Cuba (+53)'')
                        ,(40, ''america-code-40'', ''Argentina (+54)'', ''Argentina (+54)'', ''Argentina (+54)'')
                        ,(41, ''america-code-41'', ''Brasil (+55)'', ''Brazil (+55)'', ''Brasil (+55)'')
                        ,(42, ''america-code-42'', ''Chile (+56)'', ''Chile (+56)'', ''Chile (+56)'')
                        ,(43, ''america-code-43'', ''Colombia (+57)'', ''Colombia (+57)'', ''Colômbia (+57)'')
                        ,(44, ''america-code-44'', ''Venezuela (+58)'', ''Venezuela (+58)'', ''Venezuela (+58)'')
                        ,(45, ''america-code-45'', ''Guadalupe (+590)'', ''Guadeloupe (+590)'', ''Guadalupe (+590)'')
                        ,(46, ''america-code-46'', ''Bolivia (+591)'', ''Bolivia (+591)'', ''Bolívia (+591)'')
                        ,(47, ''america-code-47'', ''Guyana (+592)'', ''Guyana (+592)'', ''Guiana (+592)'')
                        ,(48, ''america-code-48'', ''Ecuador (+593)'', ''Ecuador (+593)'', ''Equador (+593)'')
                        ,(49, ''america-code-49'', ''Guyana Francesa (+594)'', ''French Guiana (+594)'', ''Guiana Francesa (+594)'')
                        ,(50, ''america-code-50'', ''Paraguay (+595)'', ''Paraguay (+595)'', ''Paraguai (+595)'')
                        ,(51, ''america-code-51'', ''Martinica (+596)'', ''Martinique (+596)'', ''Martinica (+596)'')
                        ,(52, ''america-code-52'', ''Surinam (+597)'', ''Suriname (+597)'', ''Suriname (+597)'')
                        ,(53, ''america-code-53'', ''Uruguay (+598)'', ''Uruguay (+598)'', ''Uruguai (+598)'')
                        ,(54, ''america-code-54'', ''Antillas Neerlandesas (+599)'', ''Netherlands Antilles (+599)'', ''Antilhas Holandesas (+599)'')
                        ,(55, ''america-code-55'', ''Bonaire, San Eustaquio y Saba (+599)'', ''Bonaire, Sint Eustatius and Saba (+599)'', ''Bonaire, Santo Eustáquio e Saba(+599)'')
                        ,(56, ''america-code-56'', ''Curazao (+599)'', ''Curaçao (+599)'', ''Curaçao (+599)'')
                        ,(57, ''europa-code-1'', ''Grecia (+30)'', ''Greece (+30)'', ''Grécia (+30)'')
                        ,(58, ''europa-code-2'', ''Países Bajos (+31)'', ''Netherlands (+31)'', ''Países Baixos (+31)'')
                        ,(59, ''europa-code-3'', ''Bélgica (+32)'', ''Belgium (+32)'', ''Bélgica (+32)'')
                        ,(60, ''europa-code-4'', ''Francia (+33)'', ''France (+33)'', ''França (+33)'')
                        ,(61, ''europa-code-5'', ''España (+34)'', ''Spain (+34)'', ''Espanha (+34)'')
                        ,(62, ''europa-code-6'', ''Gibraltar (+350)'', ''Gibraltar (+350)'', ''Gibraltar (+350)'')
                        ,(63, ''europa-code-7'', ''Portugal (+351)'', ''Portugal (+351)'', ''Portugal (+351)'')
                        ,(64, ''europa-code-8'', ''Luxemburgo (+352)'', ''Luxembourg (+352)'', ''Luxemburgo (+352)'')
                        ,(65, ''europa-code-9'', ''Irlanda (+353)'', ''Ireland (+353)'', ''Irlanda (+353)'')
                        ,(66, ''europa-code-10'', ''Islandia (+354)'', ''Iceland (+354)'', ''Islândia (+354)'')
                        ,(67, ''europa-code-11'', ''Albania (+355)'', ''Albania (+355)'', ''Albânia (+355)'')
                        ,(68, ''europa-code-12'', ''Malta (+356)'', ''Malta (+356)'', ''Malta (+356)'')
                        ,(69, ''europa-code-13'', ''Chipre (+357)'', ''Cyprus (+357)'', ''Chipre (+357)'')
                        ,(70, ''europa-code-14'', ''Finlandia (+358)'', ''Finland (+358)'', ''Finlândia (+358)'')
                        ,(71, ''europa-code-15'', ''Bulgaria (+359)'', ''Bulgaria (+359)'', ''Bulgária (+359)'')
                        ,(72, ''europa-code-16'', ''Hungría (+36)'', ''Hungary (+36)'', ''Hungria (+36)'')
                        ,(73, ''europa-code-17'', ''Lituania (+370)'', ''Lithuania (+370)'', ''Lituânia (+370)'')
                        ,(74, ''europa-code-18'', ''Letonia (+371)'', ''Latvia (+371)'', ''Letônia (+371)'')
                        ,(75, ''europa-code-19'', ''Estonia (+372)'', ''Estonia (+372)'', ''Estônia (+372)'')
                        ,(76, ''europa-code-20'', ''Moldavia (+373)'', ''Moldova (+373)'', ''Moldova (+373)'')
                        ,(77, ''europa-code-21'', ''Armenia (+374)'', ''Armenia (+374)'', ''Armênia (+374)'')
                        ,(78, ''europa-code-22'', ''Bielorrusia (+375)'', ''Belarus (+375)'', ''Bielo-Rússia (+375)'')
                        ,(79, ''europa-code-23'', ''Andorra (+376)'', ''Andorra (+376)'', ''Andorra (+376)'')
                        ,(80, ''europa-code-24'', ''Mónaco (+377)'', ''Monaco (+377)'', ''Mônaco (+377)'')
                        ,(81, ''europa-code-25'', ''San Marino (+378)'', ''San Marino (+378)'', ''São Marinho (+378)'')
                        ,(82, ''europa-code-26'', ''Ciudad del Vaticano (+379)'', ''Vatican City (+379)'', ''Cidade do Vaticano (+379)'')
                        ,(83, ''europa-code-27'', ''Ucrania (+380)'', ''Ukraine (+380)'', ''Ucrânia (+380)'')
                        ,(84, ''europa-code-28'', ''Serbia (+381)'', ''Serbia (+381)'', ''Sérvia (+381)'')
                        ,(85, ''europa-code-29'', ''Montenegro (+382)'', ''Montenegro (+382)'', ''Montenegro (+382)'')
                        ,(86, ''europa-code-30'', ''Kosovo (+383)'', ''Kosovo (+383)'', ''Kosovo (+383)'')
                        ,(87, ''europa-code-31'', ''Croacia (+385)'', ''Croatia (+385)'', ''Croácia (+385)'')
                        ,(88, ''europa-code-32'', ''Eslovenia (+386)'', ''Slovenia (+386)'', ''Eslovênia (+386)'')
                        ,(89, ''europa-code-33'', ''Bosnia y Herzegovina (+387)'', ''Bosnia/Herzegovina (+387)'', ''Bósnia e Herzegovina (+387)'')
                        ,(90, ''europa-code-34'', ''Macedonia (+389)'', ''Macedonia (+389)'', ''Macedônia (+389)'')
                        ,(91, ''europa-code-35'', ''Italia (+39)'', ''Italy (+39)'', ''Itália (+39)'')
                        ,(92, ''europa-code-36'', ''Rumania (+40)'', ''Romania (+40)'', ''Romênia (+40)'')
                        ,(93, ''europa-code-37'', ''Suiza (+41)'', ''Switzerland (+41)'', ''Suíça (+41)'')
                        ,(94, ''europa-code-38'', ''República Checa (+420)'', ''Czech Republic (+420)'', ''República Tcheca (+420)'')
                        ,(95, ''europa-code-39'', ''República Eslovaca (+421)'', ''Slovak Republic (+421)'', ''República Eslovaca (+421)'')
                        ,(96, ''europa-code-40'', ''Liechtenstein (+423)'', ''Liechtenstein (+423)'', ''Liechtenstein (+423)'')
                        ,(97, ''europa-code-41'', ''Austria (+43)'', ''Austria (+43)'', ''Áustria (+43)'')
                        ,(98, ''europa-code-42'', ''Reino Unido (+44)'', ''United Kingdom (+44)'', ''Reino Unido (+44)'')
                        ,(99, ''europa-code-43'', ''Guernesey (+44-1481)'', ''Guernsey (+44-1481)'', ''Guernsey (+44-1481)'')
                        ,(100, ''europa-code-44'', ''Bailía de Jersey (+44-1534)'', ''Jersey (+44-1534)'', ''Protetorado de Jersey (+44-1534)'')
                        ,(101, ''europa-code-45'', ''Isla de Man (+44-1624)'', ''Isle of Man (+44-1624)'', ''Ilha de Man (+44-1624)'')
                        ,(102, ''europa-code-46'', ''Dinamarca (+45)'', ''Denmark (+45)'', ''Dinamarca (+45)'')
                        ,(103, ''europa-code-47'', ''Suecia (+46)'', ''Sweden (+46)'', ''Suécia (+46)'')
                        ,(104, ''europa-code-48'', ''Noruega (+47)'', ''Norway (+47)'', ''Noruega (+47)'')
                        ,(105, ''europa-code-49'', ''Islas Svalbard y Jan Mayen(+47)'', ''Svalbard and Jan Mayen (+47)'', ''Ilhas de Svalbard e Jan Mayen(+47)'')
                        ,(106, ''europa-code-50'', ''Polonia (+48)'', ''Poland (+48)'', ''Polônia (+48)'')
                        ,(107, ''europa-code-51'', ''Alemania (+49)'', ''Germany (+49)'', ''Alemanha (+49)'')

                        set identity_insert CodesInterDialing off

                        update CodesInterDialing
                        set Code = SUBSTRING(ES, CHARINDEX(''+'', ES) + 1, CHARINDEX(''+'', REVERSE(ES)) - 2)


                        alter table ccoDialers add DialingType bit not null default 1, IdCode int not null default 0                        
                    end'
        EXEC(@sql);

        SET @process = 'KR110001 DROP SP GetInterDialing'
        SET @sql = '
                    if exists(select * from sys.procedures where name = ''GetInterDialing'')
                    begin
                        DROP PROCEDURE GetInterDialing
                    end'
        EXEC(@sql);        

        SET @process = 'KR110001 CREATE SP GetInterDialing'
        SET @sql = '
                    CREATE PROCEDURE [dbo].[GetInterDialing]

                    AS
                    BEGIN

                    declare @language tinyint
                    select @language = valor from ccSettings nolock where setting_id = 27

                    select 
                    id
                    , case
                        when @language = 0 then ES
                        when @language = 1 then EN
                        else PT end description
                    , Code 
                    from CodesInterDialing nolock

                    END'
        EXEC(@sql);

        SET @process = 'KR110001 ADD COLUMN DialingType'
        SET @sql = 'if not exists (select * from sys.columns where name = N''Exception'' and Object_ID = Object_ID(N''DialingType''))
                    begin
                        alter table ccoDialers add DialingType bit not null default 1, IdCode int not null default 0
                    end'
        EXEC(@sql);

        SET @process = 'KR110001 ADD ccGalateaModules'
        SET @sql = '
                    IF NOT EXISTS(SELECT 1 FROM ccGalateaModules WHERE ModuleId = 14)
                    BEGIN
                        insert into ccGalateaModules(ModuleId, MTagEs, MTagEn, MTagPt)
                        values(14, ''Puertos de marcación'', ''Dialing ports'', ''Portas de discagem'')
                    END'
        EXEC(@sql);      

        SET @process = 'KR110001 ADD ccGalateaOperations'
        SET @sql = '
                    IF NOT EXISTS(SELECT 1 FROM ccGalateaOperations WHERE OperationId = 95)
                    BEGIN
                        insert into ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
                        values(95, ''Editar puerto'', ''Edit port'', ''Editar porta'')
                    END'
        EXEC(@sql);       

        SET @process = 'KR110001 ALTER PROCEDURE ccsp_GalateaDialer'
        SET @sql = '
                    ALTER PROCEDURE [dbo].[ccsp_GalateaDialer]
                    @Description varchar(40)='''',
                    @DialerId int = 0,
                    @PortNumber int = 0,
                    @Status varchar(1)='''',
                    @action smallint=0,
                    @Provider smallint=0,
                    @XferType smallint=0,
                    @PortEnd int = 0,
                    @CampId smallint = 0,
                    @dialer_ids varchar(2000)='''',
                    @DialingType tinyint = 0,--1,
                    @idDialingCode int = 0--38

                    AS
                    set nocount on

                    if @action=1
                    begin
                        select provedor_id as ProviderId, descrip as ProviderName  from cstoProvedor
                    end

                    if @action=2 --Insert
                    begin
                        create table #tempPortTable( portId int primary key)

                        if @PortEnd>0 begin
                            begin transaction
                                while @PortNumber<=@portEnd begin
                                insert into #tempPortTable values(@PortNumber)
                                set @PortNumber=@PortNumber+1
                                end
                            commit transaction
                        end
                        else begin
                            insert into #tempPortTable values(@PortNumber)
                        end
                        
                        if exists(select Puerto from ccoDialers where Puerto in (select portId from #tempPortTable))
                        begin
                            drop table #tempPortTable
                            select -1 as ResponseCode
                            return(0)
                        end

                        Insert ccoDialers (Descripcion, Puerto, Status, provedor_id, xfertype, DialingType, IdCode) 
                        Select @Description+''_''+CAST(portId as varchar(5)), portId, @Status, @Provider, @XferType, case @DialingType when 2 then 0 else @DialingType end, @idDialingCode from #tempPortTable t
                        

                        select 200 as ResponseCode, dialer_id as DialerId, Descripcion as PortDescription, 
                        p.descrip as ProviderDescription, Puerto, XferType, DialingType
                        from ccoDialers d
                        inner join cstoProvedor p on p.provedor_id=d.provedor_id
                        where Puerto in (select portId from #tempPortTable)

                        drop table #tempPortTable
                    end

                    if @action=3 --Update
                    begin

                        if exists(select Puerto from ccoDialers where Puerto=@PortNumber and dialer_id <> @DialerId)
                        begin
                            select -1 as ResponseCode ---Port already exists
                            return(0)
                        end

                        Update ccoDialers set Descripcion=case @Description when '''' then Descripcion else @Description+''_''+cast(@PortNumber as varchar(5)) end,
                        Puerto=case @PortNumber when '''' then Puerto else @PortNumber end, Status=case @Status when '''' then Status else @status end,
                        provedor_id=case @Provider when '''' then provedor_id else @Provider end,
                        xfertype = case @XferType when 0 then xfertype else @XferType end,
                        DialingType = case when @DialingType = 0 then DialingType when @DialingType = 2 then 0 else @DialingType end,
                        IdCode = case @idDialingCode when 0 then IdCode else @idDialingCode end
                        where Dialer_id=cast(@DialerId as int)
                        
                        select 200 as ResponseCode, dialer_id as DialerId, Descripcion as PortDescription, 
                        p.descrip as ProviderDescription, Puerto, XferType, DialingType, case when DialingType = 1 then 0 else IdCode end as DialingCode
                        from ccoDialers d
                        inner join cstoProvedor p on p.provedor_id=d.provedor_id
                        where dialer_id=@DialerId
                    end

                    if @action=4 --Delete
                    begin

                        if exists(select Dialer_id from ccoDialerCamp where
                            Dialer_id in (select Value from dbo.fn_RIASplitDelimited (@dialer_ids, '','')))
                        begin
                            select -2 as ResponseCode --Existe alguna campaña que esta utilizando este dialer
                            return(0)
                        end
                        
                        declare @portsDelete table(DialerId int, Port int,PortDescription varchar(15))

                        insert @portsDelete (DialerId,Port,PortDescription)
                        select Value, Puerto,Descripcion from dbo.fn_RIASplitDelimited (@dialer_ids, '','') 
                        inner join ccoDialers on dialer_id=Value

                        delete from ccoDialers Where Dialer_id in (select DialerId from @portsDelete)
                        
                        select 200 as ResponseCode, DialerId, PortDescription
                        from @portsDelete
                    end

                    if @action=5 --Ports Info
                    begin
                        select dc.cam_id as CampId, c.cam_descripcion as CampName, graphic_id as Frame, c.IDArea, a.AreaName
                        from ccoDialerCamp dc
                        inner join ccCamps c on c.cam_id=dc.cam_id
                        inner join ccRIACat_Areas a on a.IDArea=c.IDArea
                        inner join ccRIACampsGraph cg on c.cam_id=cg.cam_id
                        where dc.dialer_id=@DialerId

                        return(0)
                    end

                    set nocount off'
        EXEC(@sql);   

        SET @process = 'KR110001 ALTER PROCEDURE ccsp_GalateaAdminPortsManagement'
        SET @sql = '
                    ALTER PROCEDURE [dbo].[ccsp_GalateaAdminPortsManagement]
                    @action SMALLINT,
                    @dialer_id INT = 0,
                    @cam_id SMALLINT = 0,
                    @list_dialier_id varchar(max) =''''
                    AS
                    SET NOCOUNT ON;
                    DECLARE @transtate BIT
                    IF @@TRANCOUNT = 0
                    BEGIN
                        SET @transtate = 1
                    BEGIN TRANSACTION transtate
                    END
                    BEGIN TRY
                        IF @action = 1 --return all ports
                        BEGIN
                            SELECT Dialers.dialer_id AS DialerId, Dialers.Descripcion AS PortDescription, Provedor.Descrip AS ProviderDescription, Dialers.Puerto, XferType, DialingType, case when DialingType = 1 then 0 else IdCode end AS DialingCode
                            FROM [CCenterRIA].[dbo].[ccoDialers] AS Dialers INNER JOIN [CCenterRIA].[dbo].[cstoProvedor] AS Provedor 
                            ON Dialers.provedor_id = Provedor.provedor_id
                        END;
                        IF @action = 2 --return ports for camp
                        BEGIN
                            SELECT dialer_id AS DialerId, cam_id AS CampId FROM [CCenterRIA].[dbo].[ccoDialerCamp] ORDER BY cam_id
                        END;
                        IF @action = 3 --insert port
                        BEGIN
                            IF @list_dialier_id = ''''
                            BEGIN
                                IF NOT EXISTS (SELECT dialer_id, cam_id FROM [CCenterRIA].[dbo].[ccoDialerCamp]
                                    WHERE dialer_id=@dialer_id AND cam_id=@cam_id)
                                BEGIN
                                    INSERT INTO [CCenterRIA].[dbo].[ccoDialerCamp](dialer_id, cam_id) VALUES (@dialer_id, @cam_id)
                                END;
                            END
                            ELSE
                            BEGIN
                            INSERT INTO [CCenterRIA].[dbo].[ccoDialerCamp](dialer_id, cam_id)
                                Select dialer_id,@cam_id from ccoDialers where dialer_id not in (SELECT dialer_id FROM [CCenterRIA].[dbo].[ccoDialerCamp]
                                    WHERE dialer_id in (select Value FROM fn_RIASplitDelimited(@list_dialier_id, '','') where [value] > 0) AND cam_id=@cam_id) and
                                    dialer_id in (select Value FROM fn_RIASplitDelimited(@list_dialier_id, '',''))
                            END;
                        END;
                        IF @action = 4 --delete port
                        BEGIN
                            IF @list_dialier_id = ''''
                                DELETE FROM [CCenterRIA].[dbo].[ccoDialerCamp] WITH(ROWLOCK) WHERE cam_id = @cam_id AND dialer_id = @dialer_id
                            ELSE
                            BEGIN
                                DELETE FROM [CCenterRIA].[dbo].[ccoDialerCamp] WITH(ROWLOCK) WHERE cam_id = @cam_id AND dialer_id in (select Value FROM fn_RIASplitDelimited(@list_dialier_id, '','') where [value] > 0)
                            END;
                        END;

                        IF @action = 5 --return ports for single camp
                        BEGIN
                            SELECT dialer_id AS DialerId, cam_id AS CampId FROM [CCenterRIA].[dbo].[ccoDialerCamp] WHERE cam_id = @cam_id ORDER BY cam_id
                        END;

                        IF @transtate = 1 AND XACT_STATE() = 1
                        BEGIN
                            COMMIT TRANSACTION transtate
                        END;
                    END TRY
                    BEGIN CATCH
                    DECLARE @error INT, @message VARCHAR(4000), @xstate INT;
                    SELECT @error = ERROR_NUMBER(), @message = ERROR_MESSAGE(), @xstate = XACT_STATE();
                    IF @xstate = -1
                        ROLLBACK;
                    IF @xstate = 1
                        ROLLBACK
                    IF @xstate = 1
                        ROLLBACK TRANSACTION ccsp_GalateaAdminPortsManagement;
                    RAISERROR (''ccsp_GalateaAdminPortsManagement: %d: %s'', 16, 1, @error, @message) ;
                    END CATCH;'
        EXEC(@sql);                       
      
        ----------------------------------------------------- END KR110000----------------------------------------------------------------

        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

        COMMIT TRAN
    END TRY

    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

        RAISERROR (@errorGenerated, 11, 1)

        ROLLBACK TRAN
    END CATCH
END 
