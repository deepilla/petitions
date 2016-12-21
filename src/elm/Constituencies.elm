module Constituencies exposing
    ( Country (..)
    , Region (..)
    , Item
    , get
    )


import Dict exposing (Dict)


type Country
    = Eng
    | NI
    | Scot
    | Wales


type Region
    = EMid
    | East
    | London
    | NE
    | NW
    | SE
    | SW
    | WMid
    | Yorks


type alias Item =
    { country : Country
    , region : Maybe Region
    , electorate : Int
    }


-- Constituency data from Wikipedia:
-- https://en.wikipedia.org/wiki/List_of_United_Kingdom_Parliament_constituencies
-- TODO: This should be one long list of constituencies but we have
-- to break it up because Elm 0.18 can't handle lists over a certain
-- size. Hopefully this will get fixed and we can scrap the List.concat
-- stuff.
-- See https://groups.google.com/forum/#!topic/elm-discuss/5Ux-YuJjSjk
-- and https://github.com/elm-lang/elm-compiler/issues/1521 
items : Dict String Item
items =
    Dict.fromList
        (List.concat
            [
                [ ("E14000530", {country = Eng, region = Just SE, electorate = 72430}) -- Aldershot
                , ("E14000531", {country = Eng, region = Just WMid, electorate = 60215}) -- Aldridge-Brownhills
                , ("E14000532", {country = Eng, region = Just NW, electorate = 71511}) -- Altrincham and Sale West
                , ("E14000533", {country = Eng, region = Just EMid, electorate = 69510}) -- Amber Valley
                , ("E14000534", {country = Eng, region = Just SE, electorate = 77242}) -- Arundel and South Downs
                , ("E14000535", {country = Eng, region = Just EMid, electorate = 77091}) -- Ashfield
                , ("E14000536", {country = Eng, region = Just SE, electorate = 85177}) -- Ashford
                , ("E14000537", {country = Eng, region = Just NW, electorate = 68343}) -- Ashton-under-Lyne
                , ("E14000538", {country = Eng, region = Just SE, electorate = 80315}) -- Aylesbury
                , ("E14000539", {country = Eng, region = Just SE, electorate = 86420}) -- Banbury
                , ("E14000540", {country = Eng, region = Just London, electorate = 73977}) -- Barking
                , ("E14000541", {country = Eng, region = Just Yorks, electorate = 64534}) -- Barnsley Central
                , ("E14000542", {country = Eng, region = Just Yorks, electorate = 69135}) -- Barnsley East
                , ("E14000543", {country = Eng, region = Just NW, electorate = 68338}) -- Barrow and Furness
                , ("E14000544", {country = Eng, region = Just East, electorate = 66347}) -- Basildon and Billericay
                , ("E14000545", {country = Eng, region = Just SE, electorate = 79665}) -- Basingstoke
                , ("E14000546", {country = Eng, region = Just EMid, electorate = 76796}) -- Bassetlaw
                , ("E14000547", {country = Eng, region = Just SW, electorate = 63084}) -- Bath
                , ("E14000548", {country = Eng, region = Just Yorks, electorate = 78373}) -- Batley and Spen
                , ("E14000549", {country = Eng, region = Just London, electorate = 76111}) -- Battersea
                , ("E14000550", {country = Eng, region = Just SE, electorate = 74726}) -- Beaconsfield
                , ("E14000551", {country = Eng, region = Just London, electorate = 67439}) -- Beckenham
                , ("E14000552", {country = Eng, region = Just East, electorate = 69311}) -- Bedford
                , ("E14000553", {country = Eng, region = Just London, electorate = 83298}) -- Bermondsey and Old Southwark
                , ("E14000554", {country = Eng, region = Just NE, electorate = 56969}) -- Berwick-upon-Tweed
                , ("E14000555", {country = Eng, region = Just London, electorate = 82727}) -- Bethnal Green and Bow
                , ("E14000556", {country = Eng, region = Just Yorks, electorate = 80805}) -- Beverley and Holderness
                , ("E14000557", {country = Eng, region = Just SE, electorate = 78796}) -- Bexhill and Battle
                , ("E14000558", {country = Eng, region = Just London, electorate = 64828}) -- Bexleyheath and Crayford
                , ("E14000559", {country = Eng, region = Just NW, electorate = 62410}) -- Birkenhead
                , ("E14000560", {country = Eng, region = Just WMid, electorate = 65591}) -- Birmingham, Edgbaston
                , ("E14000561", {country = Eng, region = Just WMid, electorate = 65128}) -- Birmingham, Erdington
                , ("E14000562", {country = Eng, region = Just WMid, electorate = 76330}) -- Birmingham, Hall Green
                , ("E14000563", {country = Eng, region = Just WMid, electorate = 75302}) -- Birmingham, Hodge Hill
                , ("E14000564", {country = Eng, region = Just WMid, electorate = 68128}) -- Birmingham, Ladywood
                , ("E14000565", {country = Eng, region = Just WMid, electorate = 71428}) -- Birmingham, Northfield
                , ("E14000566", {country = Eng, region = Just WMid, electorate = 69943}) -- Birmingham, Perry Barr
                , ("E14000567", {country = Eng, region = Just WMid, electorate = 75092}) -- Birmingham, Selly Oak
                , ("E14000568", {country = Eng, region = Just WMid, electorate = 72146}) -- Birmingham, Yardley
                , ("E14000569", {country = Eng, region = Just NE, electorate = 66070}) -- Bishop Auckland
                , ("E14000570", {country = Eng, region = Just NW, electorate = 73260}) -- Blackburn
                , ("E14000571", {country = Eng, region = Just NW, electorate = 57411}) -- Blackley and Broughton
                , ("E14000572", {country = Eng, region = Just NW, electorate = 71913}) -- Blackpool North and Cleveleys
                , ("E14000573", {country = Eng, region = Just NW, electorate = 62468}) -- Blackpool South
                , ("E14000574", {country = Eng, region = Just NE, electorate = 67901}) -- Blaydon
                , ("E14000575", {country = Eng, region = Just NE, electorate = 61247}) -- Blyth Valley
                , ("E14000576", {country = Eng, region = Just SE, electorate = 72995}) -- Bognor Regis and Littlehampton
                , ("E14000577", {country = Eng, region = Just EMid, electorate = 71979}) -- Bolsover
                , ("E14000578", {country = Eng, region = Just NW, electorate = 67895}) -- Bolton North East
                , ("E14000579", {country = Eng, region = Just NW, electorate = 69687}) -- Bolton South East
                , ("E14000580", {country = Eng, region = Just NW, electorate = 72719}) -- Bolton West
                , ("E14000581", {country = Eng, region = Just NW, electorate = 70145}) -- Bootle
                , ("E14000582", {country = Eng, region = Just EMid, electorate = 67064}) -- Boston and Skegness
                , ("E14000583", {country = Eng, region = Just EMid, electorate = 79738}) -- Bosworth
                , ("E14000584", {country = Eng, region = Just SW, electorate = 72275}) -- Bournemouth East
                , ("E14000585", {country = Eng, region = Just SW, electorate = 72082}) -- Bournemouth West
                , ("E14000586", {country = Eng, region = Just SE, electorate = 81271}) -- Bracknell
                , ("E14000587", {country = Eng, region = Just Yorks, electorate = 66121}) -- Bradford East
                , ("E14000588", {country = Eng, region = Just Yorks, electorate = 63674}) -- Bradford South
                , ("E14000589", {country = Eng, region = Just Yorks, electorate = 63372}) -- Bradford West
                , ("E14000590", {country = Eng, region = Just East, electorate = 73557}) -- Braintree
                , ("E14000591", {country = Eng, region = Just London, electorate = 77038}) -- Brent Central
                , ("E14000592", {country = Eng, region = Just London, electorate = 82196}) -- Brent North
                , ("E14000593", {country = Eng, region = Just London, electorate = 84602}) -- Brentford and Isleworth
                , ("E14000594", {country = Eng, region = Just East, electorate = 71918}) -- Brentwood and Ongar
                , ("E14000595", {country = Eng, region = Just SW, electorate = 80491}) -- Bridgwater and West Somerset
                , ("E14000596", {country = Eng, region = Just Yorks, electorate = 68488}) -- Brigg and Goole
                , ("E14000597", {country = Eng, region = Just SE, electorate = 67858}) -- Brighton, Kemptown
                , ("E14000598", {country = Eng, region = Just SE, electorate = 76557}) -- Brighton, Pavilion
                , ("E14000599", {country = Eng, region = Just SW, electorate = 71193}) -- Bristol East
                , ("E14000600", {country = Eng, region = Just SW, electorate = 74743}) -- Bristol North West
                , ("E14000601", {country = Eng, region = Just SW, electorate = 81496}) -- Bristol South
                , ("E14000602", {country = Eng, region = Just SW, electorate = 91236}) -- Bristol West
                , ("E14000603", {country = Eng, region = Just East, electorate = 73552}) -- Broadland
                , ("E14000604", {country = Eng, region = Just London, electorate = 65477}) -- Bromley and Chislehurst
                , ("E14000605", {country = Eng, region = Just WMid, electorate = 73337}) -- Bromsgrove
                , ("E14000606", {country = Eng, region = Just East, electorate = 72944}) -- Broxbourne
                , ("E14000607", {country = Eng, region = Just EMid, electorate = 71764}) -- Broxtowe
                , ("E14000608", {country = Eng, region = Just SE, electorate = 77425}) -- Buckingham
                , ("E14000609", {country = Eng, region = Just NW, electorate = 64477}) -- Burnley
                , ("E14000610", {country = Eng, region = Just WMid, electorate = 75248}) -- Burton
                , ("E14000611", {country = Eng, region = Just NW, electorate = 67580}) -- Bury North
                , ("E14000612", {country = Eng, region = Just NW, electorate = 73883}) -- Bury South
                , ("E14000613", {country = Eng, region = Just East, electorate = 85982}) -- Bury St Edmunds
                , ("E14000614", {country = Eng, region = Just Yorks, electorate = 77754}) -- Calder Valley
                , ("E14000615", {country = Eng, region = Just London, electorate = 82746}) -- Camberwell and Peckham
                , ("E14000616", {country = Eng, region = Just SW, electorate = 66944}) -- Camborne and Redruth
                , ("E14000617", {country = Eng, region = Just East, electorate = 83384}) -- Cambridge
                , ("E14000618", {country = Eng, region = Just WMid, electorate = 74532}) -- Cannock Chase
                , ("E14000619", {country = Eng, region = Just SE, electorate = 81341}) -- Canterbury
                , ("E14000620", {country = Eng, region = Just NW, electorate = 65827}) -- Carlisle
                , ("E14000621", {country = Eng, region = Just London, electorate = 69981}) -- Carshalton and Wallington
                , ("E14000622", {country = Eng, region = Just East, electorate = 68170}) -- Castle Point
                , ("E14000623", {country = Eng, region = Just SW, electorate = 72737}) -- Central Devon
                , ("E14000624", {country = Eng, region = Just East, electorate = 76666}) -- Central Suffolk and North Ipswich
                , ("E14000625", {country = Eng, region = Just EMid, electorate = 77269}) -- Charnwood
                , ("E14000626", {country = Eng, region = Just SE, electorate = 66355}) -- Chatham and Aylesford
                , ("E14000627", {country = Eng, region = Just NW, electorate = 73239}) -- Cheadle
                , ("E14000628", {country = Eng, region = Just East, electorate = 78580}) -- Chelmsford
                , ("E14000629", {country = Eng, region = Just London, electorate = 63478}) -- Chelsea and Fulham
                , ("E14000630", {country = Eng, region = Just SW, electorate = 77287}) -- Cheltenham
                ]
            ,   [ ("E14000631", {country = Eng, region = Just SE, electorate = 72547}) -- Chesham and Amersham
                , ("E14000632", {country = Eng, region = Just EMid, electorate = 71625}) -- Chesterfield
                , ("E14000633", {country = Eng, region = Just SE, electorate = 83396}) -- Chichester
                , ("E14000634", {country = Eng, region = Just London, electorate = 66680}) -- Chingford and Woodford Green
                , ("E14000635", {country = Eng, region = Just SW, electorate = 74218}) -- Chippenham
                , ("E14000636", {country = Eng, region = Just London, electorate = 77807}) -- Chipping Barnet
                , ("E14000637", {country = Eng, region = Just NW, electorate = 74679}) -- Chorley
                , ("E14000638", {country = Eng, region = Just SW, electorate = 69303}) -- Christchurch
                , ("E14000639", {country = Eng, region = Just London, electorate = 60992}) -- Cities of London and Westminster
                , ("E14000640", {country = Eng, region = Just NW, electorate = 74485}) -- City of Chester
                , ("E14000641", {country = Eng, region = Just NE, electorate = 68725}) -- City of Durham
                , ("E14000642", {country = Eng, region = Just East, electorate = 68936}) -- Clacton
                , ("E14000643", {country = Eng, region = Just Yorks, electorate = 71008}) -- Cleethorpes
                , ("E14000644", {country = Eng, region = Just East, electorate = 74204}) -- Colchester
                , ("E14000645", {country = Eng, region = Just Yorks, electorate = 82516}) -- Colne Valley
                , ("E14000646", {country = Eng, region = Just NW, electorate = 72503}) -- Congleton
                , ("E14000647", {country = Eng, region = Just NW, electorate = 62087}) -- Copeland
                , ("E14000648", {country = Eng, region = Just EMid, electorate = 79775}) -- Corby
                , ("E14000649", {country = Eng, region = Just WMid, electorate = 75462}) -- Coventry North East
                , ("E14000650", {country = Eng, region = Just WMid, electorate = 73626}) -- Coventry North West
                , ("E14000651", {country = Eng, region = Just WMid, electorate = 70397}) -- Coventry South
                , ("E14000652", {country = Eng, region = Just SE, electorate = 73936}) -- Crawley
                , ("E14000653", {country = Eng, region = Just NW, electorate = 74169}) -- Crewe and Nantwich
                , ("E14000654", {country = Eng, region = Just London, electorate = 78171}) -- Croydon Central
                , ("E14000655", {country = Eng, region = Just London, electorate = 85941}) -- Croydon North
                , ("E14000656", {country = Eng, region = Just London, electorate = 82010}) -- Croydon South
                , ("E14000657", {country = Eng, region = Just London, electorate = 69128}) -- Dagenham and Rainham
                , ("E14000658", {country = Eng, region = Just NE, electorate = 65851}) -- Darlington
                , ("E14000659", {country = Eng, region = Just SE, electorate = 75209}) -- Dartford
                , ("E14000660", {country = Eng, region = Just EMid, electorate = 72873}) -- Daventry
                , ("E14000661", {country = Eng, region = Just NW, electorate = 66141}) -- Denton and Reddish
                , ("E14000662", {country = Eng, region = Just EMid, electorate = 69794}) -- Derby North
                , ("E14000663", {country = Eng, region = Just EMid, electorate = 70240}) -- Derby South
                , ("E14000664", {country = Eng, region = Just EMid, electorate = 63476}) -- Derbyshire Dales
                , ("E14000665", {country = Eng, region = Just SW, electorate = 69205}) -- Devizes
                , ("E14000666", {country = Eng, region = Just Yorks, electorate = 79770}) -- Dewsbury
                , ("E14000667", {country = Eng, region = Just Yorks, electorate = 71299}) -- Don Valley
                , ("E14000668", {country = Eng, region = Just Yorks, electorate = 71136}) -- Doncaster Central
                , ("E14000669", {country = Eng, region = Just Yorks, electorate = 70989}) -- Doncaster North
                , ("E14000670", {country = Eng, region = Just SE, electorate = 72930}) -- Dover
                , ("E14000671", {country = Eng, region = Just WMid, electorate = 60717}) -- Dudley North
                , ("E14000672", {country = Eng, region = Just WMid, electorate = 60363}) -- Dudley South
                , ("E14000673", {country = Eng, region = Just London, electorate = 76575}) -- Dulwich and West Norwood
                , ("E14000674", {country = Eng, region = Just London, electorate = 71422}) -- Ealing Central and Acton
                , ("E14000675", {country = Eng, region = Just London, electorate = 73881}) -- Ealing North
                , ("E14000676", {country = Eng, region = Just London, electorate = 65606}) -- Ealing, Southall
                , ("E14000677", {country = Eng, region = Just NE, electorate = 61659}) -- Easington
                , ("E14000678", {country = Eng, region = Just SW, electorate = 76519}) -- East Devon
                , ("E14000679", {country = Eng, region = Just London, electorate = 87382}) -- East Ham
                , ("E14000680", {country = Eng, region = Just SE, electorate = 71074}) -- East Hampshire
                , ("E14000681", {country = Eng, region = Just SE, electorate = 79654}) -- East Surrey
                , ("E14000682", {country = Eng, region = Just SE, electorate = 74775}) -- East Worthing and Shoreham
                , ("E14000683", {country = Eng, region = Just Yorks, electorate = 81023}) -- East Yorkshire
                , ("E14000684", {country = Eng, region = Just SE, electorate = 78262}) -- Eastbourne
                , ("E14000685", {country = Eng, region = Just SE, electorate = 79609}) -- Eastleigh
                , ("E14000686", {country = Eng, region = Just NW, electorate = 68569}) -- Eddisbury
                , ("E14000687", {country = Eng, region = Just London, electorate = 66016}) -- Edmonton
                , ("E14000688", {country = Eng, region = Just NW, electorate = 69223}) -- Ellesmere Port and Neston
                , ("E14000689", {country = Eng, region = Just Yorks, electorate = 79143}) -- Elmet and Rothwell
                , ("E14000690", {country = Eng, region = Just London, electorate = 63998}) -- Eltham
                , ("E14000691", {country = Eng, region = Just London, electorate = 68118}) -- Enfield North
                , ("E14000692", {country = Eng, region = Just London, electorate = 64937}) -- Enfield, Southgate
                , ("E14000693", {country = Eng, region = Just East, electorate = 73447}) -- Epping Forest
                , ("E14000694", {country = Eng, region = Just SE, electorate = 78633}) -- Epsom and Ewell
                , ("E14000695", {country = Eng, region = Just EMid, electorate = 71943}) -- Erewash
                , ("E14000696", {country = Eng, region = Just London, electorate = 70397}) -- Erith and Thamesmead
                , ("E14000697", {country = Eng, region = Just SE, electorate = 79894}) -- Esher and Walton
                , ("E14000698", {country = Eng, region = Just SW, electorate = 76968}) -- Exeter
                , ("E14000699", {country = Eng, region = Just SE, electorate = 77114}) -- Fareham
                , ("E14000700", {country = Eng, region = Just SE, electorate = 69523}) -- Faversham and Mid Kent
                , ("E14000701", {country = Eng, region = Just London, electorate = 82340}) -- Feltham and Heston
                , ("E14000702", {country = Eng, region = Just SW, electorate = 71310}) -- Filton and Bradley Stoke
                , ("E14000703", {country = Eng, region = Just London, electorate = 72530}) -- Finchley and Golders Green
                , ("E14000704", {country = Eng, region = Just SE, electorate = 83651}) -- Folkestone and Hythe
                , ("E14000705", {country = Eng, region = Just SW, electorate = 69865}) -- Forest of Dean
                , ("E14000706", {country = Eng, region = Just NW, electorate = 65679}) -- Fylde
                , ("E14000707", {country = Eng, region = Just EMid, electorate = 74686}) -- Gainsborough
                , ("E14000708", {country = Eng, region = Just NW, electorate = 73719}) -- Garston and Halewood
                , ("E14000709", {country = Eng, region = Just NE, electorate = 64524}) -- Gateshead
                , ("E14000710", {country = Eng, region = Just EMid, electorate = 70000}) -- Gedling
                , ("E14000711", {country = Eng, region = Just SE, electorate = 70984}) -- Gillingham and Rainham
                , ("E14000712", {country = Eng, region = Just SW, electorate = 82968}) -- Gloucester
                , ("E14000713", {country = Eng, region = Just SE, electorate = 73268}) -- Gosport
                , ("E14000714", {country = Eng, region = Just EMid, electorate = 81150}) -- Grantham and Stamford
                , ("E14000715", {country = Eng, region = Just SE, electorate = 72043}) -- Gravesham
                , ("E14000716", {country = Eng, region = Just Yorks, electorate = 59200}) -- Great Grimsby
                , ("E14000717", {country = Eng, region = Just East, electorate = 69793}) -- Great Yarmouth
                , ("E14000718", {country = Eng, region = Just London, electorate = 73315}) -- Greenwich and Woolwich
                , ("E14000719", {country = Eng, region = Just SE, electorate = 75733}) -- Guildford
                , ("E14000720", {country = Eng, region = Just London, electorate = 88153}) -- Hackney North and Stoke Newington
                , ("E14000721", {country = Eng, region = Just London, electorate = 84971}) -- Hackney South and Shoreditch
                , ("E14000722", {country = Eng, region = Just WMid, electorate = 66048}) -- Halesowen and Rowley Regis
                , ("E14000723", {country = Eng, region = Just Yorks, electorate = 70462}) -- Halifax
                , ("E14000724", {country = Eng, region = Just Yorks, electorate = 71195}) -- Haltemprice and Howden
                , ("E14000725", {country = Eng, region = Just NW, electorate = 72818}) -- Halton
                , ("E14000726", {country = Eng, region = Just London, electorate = 72254}) -- Hammersmith
                , ("E14000727", {country = Eng, region = Just London, electorate = 80195}) -- Hampstead and Kilburn
                , ("E14000728", {country = Eng, region = Just EMid, electorate = 77760}) -- Harborough
                , ("E14000729", {country = Eng, region = Just East, electorate = 67994}) -- Harlow
                , ("E14000730", {country = Eng, region = Just Yorks, electorate = 76408}) -- Harrogate and Knaresborough
                , ("E14000731", {country = Eng, region = Just London, electorate = 70981}) -- Harrow East
                ]
            ,   [ ("E14000732", {country = Eng, region = Just London, electorate = 69644}) -- Harrow West
                , ("E14000733", {country = Eng, region = Just NE, electorate = 69947}) -- Hartlepool
                , ("E14000734", {country = Eng, region = Just East, electorate = 69290}) -- Harwich and North Essex
                , ("E14000735", {country = Eng, region = Just SE, electorate = 75095}) -- Hastings and Rye
                , ("E14000736", {country = Eng, region = Just SE, electorate = 70573}) -- Havant
                , ("E14000737", {country = Eng, region = Just London, electorate = 74874}) -- Hayes and Harlington
                , ("E14000738", {country = Eng, region = Just NW, electorate = 63098}) -- Hazel Grove
                , ("E14000739", {country = Eng, region = Just East, electorate = 74616}) -- Hemel Hempstead
                , ("E14000740", {country = Eng, region = Just Yorks, electorate = 72714}) -- Hemsworth
                , ("E14000741", {country = Eng, region = Just London, electorate = 75285}) -- Hendon
                , ("E14000742", {country = Eng, region = Just SE, electorate = 77946}) -- Henley
                , ("E14000743", {country = Eng, region = Just WMid, electorate = 71485}) -- Hereford and South Herefordshire
                , ("E14000744", {country = Eng, region = Just East, electorate = 80610}) -- Hertford and Stortford
                , ("E14000745", {country = Eng, region = Just East, electorate = 73767}) -- Hertsmere
                , ("E14000746", {country = Eng, region = Just NE, electorate = 59708}) -- Hexham
                , ("E14000747", {country = Eng, region = Just NW, electorate = 79989}) -- Heywood and Middleton
                , ("E14000748", {country = Eng, region = Just EMid, electorate = 73336}) -- High Peak
                , ("E14000749", {country = Eng, region = Just East, electorate = 80333}) -- Hitchin and Harpenden
                , ("E14000750", {country = Eng, region = Just London, electorate = 86764}) -- Holborn and St Pancras
                , ("E14000751", {country = Eng, region = Just London, electorate = 79331}) -- Hornchurch and Upminster
                , ("E14000752", {country = Eng, region = Just London, electorate = 79247}) -- Hornsey and Wood Green
                , ("E14000753", {country = Eng, region = Just SE, electorate = 79085}) -- Horsham
                , ("E14000754", {country = Eng, region = Just NE, electorate = 68324}) -- Houghton and Sunderland South
                , ("E14000755", {country = Eng, region = Just SE, electorate = 73505}) -- Hove
                , ("E14000756", {country = Eng, region = Just Yorks, electorate = 65269}) -- Huddersfield
                , ("E14000757", {country = Eng, region = Just East, electorate = 82593}) -- Huntingdon
                , ("E14000758", {country = Eng, region = Just NW, electorate = 68341}) -- Hyndburn
                , ("E14000759", {country = Eng, region = Just London, electorate = 75294}) -- Ilford North
                , ("E14000760", {country = Eng, region = Just London, electorate = 91987}) -- Ilford South
                , ("E14000761", {country = Eng, region = Just East, electorate = 74499}) -- Ipswich
                , ("E14000762", {country = Eng, region = Just SE, electorate = 108804}) -- Isle of Wight
                , ("E14000763", {country = Eng, region = Just London, electorate = 73326}) -- Islington North
                , ("E14000764", {country = Eng, region = Just London, electorate = 68127}) -- Islington South and Finsbury
                , ("E14000765", {country = Eng, region = Just NE, electorate = 64002}) -- Jarrow
                , ("E14000766", {country = Eng, region = Just Yorks, electorate = 68865}) -- Keighley
                , ("E14000767", {country = Eng, region = Just WMid, electorate = 63957}) -- Kenilworth and Southam
                , ("E14000768", {country = Eng, region = Just London, electorate = 61133}) -- Kensington
                , ("E14000769", {country = Eng, region = Just EMid, electorate = 70155}) -- Kettering
                , ("E14000770", {country = Eng, region = Just London, electorate = 81238}) -- Kingston and Surbiton
                , ("E14000771", {country = Eng, region = Just Yorks, electorate = 65710}) -- Kingston upon Hull East
                , ("E14000772", {country = Eng, region = Just Yorks, electorate = 64148}) -- Kingston upon Hull North
                , ("E14000773", {country = Eng, region = Just Yorks, electorate = 59100}) -- Kingston upon Hull West and Hessle
                , ("E14000774", {country = Eng, region = Just SW, electorate = 68193}) -- Kingswood
                , ("E14000775", {country = Eng, region = Just NW, electorate = 79108}) -- Knowsley
                , ("E14000776", {country = Eng, region = Just NW, electorate = 61922}) -- Lancaster and Fleetwood
                , ("E14000777", {country = Eng, region = Just Yorks, electorate = 81799}) -- Leeds Central
                , ("E14000778", {country = Eng, region = Just Yorks, electorate = 64754}) -- Leeds East
                , ("E14000779", {country = Eng, region = Just Yorks, electorate = 69097}) -- Leeds North East
                , ("E14000780", {country = Eng, region = Just Yorks, electorate = 61974}) -- Leeds North West
                , ("E14000781", {country = Eng, region = Just Yorks, electorate = 64950}) -- Leeds West
                , ("E14000782", {country = Eng, region = Just EMid, electorate = 75430}) -- Leicester East
                , ("E14000783", {country = Eng, region = Just EMid, electorate = 73518}) -- Leicester South
                , ("E14000784", {country = Eng, region = Just EMid, electorate = 63204}) -- Leicester West
                , ("E14000785", {country = Eng, region = Just NW, electorate = 75905}) -- Leigh
                , ("E14000786", {country = Eng, region = Just SE, electorate = 69481}) -- Lewes
                , ("E14000787", {country = Eng, region = Just London, electorate = 72290}) -- Lewisham East
                , ("E14000788", {country = Eng, region = Just London, electorate = 73428}) -- Lewisham West and Penge
                , ("E14000789", {country = Eng, region = Just London, electorate = 66913}) -- Lewisham, Deptford
                , ("E14000790", {country = Eng, region = Just London, electorate = 64580}) -- Leyton and Wanstead
                , ("E14000791", {country = Eng, region = Just WMid, electorate = 74234}) -- Lichfield
                , ("E14000792", {country = Eng, region = Just EMid, electorate = 74121}) -- Lincoln
                , ("E14000793", {country = Eng, region = Just NW, electorate = 70829}) -- Liverpool, Riverside
                , ("E14000794", {country = Eng, region = Just NW, electorate = 61908}) -- Liverpool, Walton
                , ("E14000795", {country = Eng, region = Just NW, electorate = 61549}) -- Liverpool, Wavertree
                , ("E14000796", {country = Eng, region = Just NW, electorate = 63651}) -- Liverpool, West Derby
                , ("E14000797", {country = Eng, region = Just EMid, electorate = 75217}) -- Loughborough
                , ("E14000798", {country = Eng, region = Just EMid, electorate = 74870}) -- Louth and Horncastle
                , ("E14000799", {country = Eng, region = Just WMid, electorate = 66374}) -- Ludlow
                , ("E14000800", {country = Eng, region = Just East, electorate = 67329}) -- Luton North
                , ("E14000801", {country = Eng, region = Just East, electorate = 67741}) -- Luton South
                , ("E14000802", {country = Eng, region = Just NW, electorate = 71712}) -- Macclesfield
                , ("E14000803", {country = Eng, region = Just SE, electorate = 74187}) -- Maidenhead
                , ("E14000804", {country = Eng, region = Just SE, electorate = 73181}) -- Maidstone and The Weald
                , ("E14000805", {country = Eng, region = Just NW, electorate = 74320}) -- Makerfield
                , ("E14000806", {country = Eng, region = Just East, electorate = 69066}) -- Maldon
                , ("E14000807", {country = Eng, region = Just NW, electorate = 86078}) -- Manchester Central
                , ("E14000808", {country = Eng, region = Just NW, electorate = 72992}) -- Manchester, Gorton
                , ("E14000809", {country = Eng, region = Just NW, electorate = 74102}) -- Manchester, Withington
                , ("E14000810", {country = Eng, region = Just EMid, electorate = 77534}) -- Mansfield
                , ("E14000811", {country = Eng, region = Just SE, electorate = 72738}) -- Meon Valley
                , ("E14000812", {country = Eng, region = Just WMid, electorate = 81928}) -- Meriden
                , ("E14000813", {country = Eng, region = Just East, electorate = 78501}) -- Mid Bedfordshire
                , ("E14000814", {country = Eng, region = Just EMid, electorate = 67477}) -- Mid Derbyshire
                , ("E14000815", {country = Eng, region = Just SW, electorate = 64299}) -- Mid Dorset and North Poole
                , ("E14000816", {country = Eng, region = Just East, electorate = 77154}) -- Mid Norfolk
                , ("E14000817", {country = Eng, region = Just SE, electorate = 81034}) -- Mid Sussex
                , ("E14000818", {country = Eng, region = Just WMid, electorate = 73069}) -- Mid Worcestershire
                , ("E14000819", {country = Eng, region = Just NE, electorate = 61873}) -- Middlesbrough
                , ("E14000820", {country = Eng, region = Just NE, electorate = 71154}) -- Middlesbrough South and East Cleveland
                , ("E14000821", {country = Eng, region = Just SE, electorate = 86826}) -- Milton Keynes North
                , ("E14000822", {country = Eng, region = Just SE, electorate = 89656}) -- Milton Keynes South
                , ("E14000823", {country = Eng, region = Just London, electorate = 68474}) -- Mitcham and Morden
                , ("E14000824", {country = Eng, region = Just SE, electorate = 74038}) -- Mole Valley
                , ("E14000825", {country = Eng, region = Just NW, electorate = 66985}) -- Morecambe and Lunesdale
                , ("E14000826", {country = Eng, region = Just Yorks, electorate = 75820}) -- Morley and Outwood
                , ("E14000827", {country = Eng, region = Just SE, electorate = 72697}) -- New Forest East
                , ("E14000828", {country = Eng, region = Just SE, electorate = 68446}) -- New Forest West
                , ("E14000829", {country = Eng, region = Just EMid, electorate = 73747}) -- Newark
                , ("E14000830", {country = Eng, region = Just SE, electorate = 79512}) -- Newbury
                , ("E14000831", {country = Eng, region = Just NE, electorate = 64243}) -- Newcastle upon Tyne Central
                , ("E14000832", {country = Eng, region = Just NE, electorate = 67902}) -- Newcastle upon Tyne East
                ]
            ,   [ ("E14000833", {country = Eng, region = Just NE, electorate = 67619}) -- Newcastle upon Tyne North
                , ("E14000834", {country = Eng, region = Just WMid, electorate = 58147}) -- Newcastle-under-Lyme
                , ("E14000835", {country = Eng, region = Just SW, electorate = 69928}) -- Newton Abbot
                , ("E14000836", {country = Eng, region = Just Yorks, electorate = 82592}) -- Normanton, Pontefract and Castleford
                , ("E14000837", {country = Eng, region = Just SW, electorate = 67192}) -- North Cornwall
                , ("E14000838", {country = Eng, region = Just SW, electorate = 74737}) -- North Devon
                , ("E14000839", {country = Eng, region = Just SW, electorate = 73759}) -- North Dorset
                , ("E14000840", {country = Eng, region = Just NE, electorate = 65359}) -- North Durham
                , ("E14000841", {country = Eng, region = Just East, electorate = 83551}) -- North East Bedfordshire
                , ("E14000842", {country = Eng, region = Just East, electorate = 82990}) -- North East Cambridgeshire
                , ("E14000843", {country = Eng, region = Just EMid, electorate = 71445}) -- North East Derbyshire
                , ("E14000844", {country = Eng, region = Just SE, electorate = 76918}) -- North East Hampshire
                , ("E14000845", {country = Eng, region = Just East, electorate = 74000}) -- North East Hertfordshire
                , ("E14000846", {country = Eng, region = Just SW, electorate = 69380}) -- North East Somerset
                , ("E14000847", {country = Eng, region = Just WMid, electorate = 67926}) -- North Herefordshire
                , ("E14000848", {country = Eng, region = Just East, electorate = 68867}) -- North Norfolk
                , ("E14000849", {country = Eng, region = Just WMid, electorate = 78858}) -- North Shropshire
                , ("E14000850", {country = Eng, region = Just SW, electorate = 80161}) -- North Somerset
                , ("E14000851", {country = Eng, region = Just SW, electorate = 80983}) -- North Swindon
                , ("E14000852", {country = Eng, region = Just SE, electorate = 71478}) -- North Thanet
                , ("E14000853", {country = Eng, region = Just NE, electorate = 79300}) -- North Tyneside
                , ("E14000854", {country = Eng, region = Just WMid, electorate = 70152}) -- North Warwickshire
                , ("E14000855", {country = Eng, region = Just East, electorate = 90318}) -- North West Cambridgeshire
                , ("E14000856", {country = Eng, region = Just NE, electorate = 69816}) -- North West Durham
                , ("E14000857", {country = Eng, region = Just SE, electorate = 79223}) -- North West Hampshire
                , ("E14000858", {country = Eng, region = Just EMid, electorate = 72193}) -- North West Leicestershire
                , ("E14000859", {country = Eng, region = Just East, electorate = 74402}) -- North West Norfolk
                , ("E14000860", {country = Eng, region = Just SW, electorate = 67851}) -- North Wiltshire
                , ("E14000861", {country = Eng, region = Just EMid, electorate = 59144}) -- Northampton North
                , ("E14000862", {country = Eng, region = Just EMid, electorate = 61287}) -- Northampton South
                , ("E14000863", {country = Eng, region = Just East, electorate = 64515}) -- Norwich North
                , ("E14000864", {country = Eng, region = Just East, electorate = 74875}) -- Norwich South
                , ("E14000865", {country = Eng, region = Just EMid, electorate = 60464}) -- Nottingham East
                , ("E14000866", {country = Eng, region = Just EMid, electorate = 65918}) -- Nottingham North
                , ("E14000867", {country = Eng, region = Just EMid, electorate = 68987}) -- Nottingham South
                , ("E14000868", {country = Eng, region = Just WMid, electorate = 68037}) -- Nuneaton
                , ("E14000869", {country = Eng, region = Just London, electorate = 66035}) -- Old Bexley and Sidcup
                , ("E14000870", {country = Eng, region = Just NW, electorate = 71475}) -- Oldham East and Saddleworth
                , ("E14000871", {country = Eng, region = Just NW, electorate = 71652}) -- Oldham West and Royton
                , ("E14000872", {country = Eng, region = Just London, electorate = 68129}) -- Orpington
                , ("E14000873", {country = Eng, region = Just SE, electorate = 78978}) -- Oxford East
                , ("E14000874", {country = Eng, region = Just SE, electorate = 76174}) -- Oxford West and Abingdon
                , ("E14000875", {country = Eng, region = Just NW, electorate = 64573}) -- Pendle
                , ("E14000876", {country = Eng, region = Just Yorks, electorate = 70817}) -- Penistone and Stocksbridge
                , ("E14000877", {country = Eng, region = Just NW, electorate = 65209}) -- Penrith and The Border
                , ("E14000878", {country = Eng, region = Just East, electorate = 72530}) -- Peterborough
                , ("E14000879", {country = Eng, region = Just SW, electorate = 68246}) -- Plymouth, Moor View
                , ("E14000880", {country = Eng, region = Just SW, electorate = 73274}) -- Plymouth, Sutton and Devonport
                , ("E14000881", {country = Eng, region = Just SW, electorate = 72557}) -- Poole
                , ("E14000882", {country = Eng, region = Just London, electorate = 82081}) -- Poplar and Limehouse
                , ("E14000883", {country = Eng, region = Just SE, electorate = 73105}) -- Portsmouth North
                , ("E14000884", {country = Eng, region = Just SE, electorate = 71639}) -- Portsmouth South
                , ("E14000885", {country = Eng, region = Just NW, electorate = 59981}) -- Preston
                , ("E14000886", {country = Eng, region = Just Yorks, electorate = 70533}) -- Pudsey
                , ("E14000887", {country = Eng, region = Just London, electorate = 63923}) -- Putney
                , ("E14000888", {country = Eng, region = Just East, electorate = 77174}) -- Rayleigh and Wickford
                , ("E14000889", {country = Eng, region = Just SE, electorate = 73232}) -- Reading East
                , ("E14000890", {country = Eng, region = Just SE, electorate = 72567}) -- Reading West
                , ("E14000891", {country = Eng, region = Just NE, electorate = 64826}) -- Redcar
                , ("E14000892", {country = Eng, region = Just WMid, electorate = 65531}) -- Redditch
                , ("E14000893", {country = Eng, region = Just SE, electorate = 73429}) -- Reigate
                , ("E14000894", {country = Eng, region = Just NW, electorate = 77379}) -- Ribble Valley
                , ("E14000895", {country = Eng, region = Just Yorks, electorate = 79062}) -- Richmond (Yorks)
                , ("E14000896", {country = Eng, region = Just London, electorate = 77303}) -- Richmond Park
                , ("E14000897", {country = Eng, region = Just NW, electorate = 77248}) -- Rochdale
                , ("E14000898", {country = Eng, region = Just SE, electorate = 77119}) -- Rochester and Strood
                , ("E14000899", {country = Eng, region = Just East, electorate = 71935}) -- Rochford and Southend East
                , ("E14000900", {country = Eng, region = Just London, electorate = 72594}) -- Romford
                , ("E14000901", {country = Eng, region = Just SE, electorate = 66519}) -- Romsey and Southampton North
                , ("E14000902", {country = Eng, region = Just NW, electorate = 73779}) -- Rossendale and Darwen
                , ("E14000903", {country = Eng, region = Just Yorks, electorate = 74275}) -- Rother Valley
                , ("E14000904", {country = Eng, region = Just Yorks, electorate = 63698}) -- Rotherham
                , ("E14000905", {country = Eng, region = Just WMid, electorate = 71655}) -- Rugby
                , ("E14000906", {country = Eng, region = Just London, electorate = 73216}) -- Ruislip, Northwood and Pinner
                , ("E14000907", {country = Eng, region = Just SE, electorate = 73771}) -- Runnymede and Weybridge
                , ("E14000908", {country = Eng, region = Just EMid, electorate = 73278}) -- Rushcliffe
                , ("E14000909", {country = Eng, region = Just EMid, electorate = 79693}) -- Rutland and Melton
                , ("E14000910", {country = Eng, region = Just East, electorate = 80615}) -- Saffron Walden
                , ("E14000911", {country = Eng, region = Just NW, electorate = 69582}) -- Salford and Eccles
                , ("E14000912", {country = Eng, region = Just SW, electorate = 74291}) -- Salisbury
                , ("E14000913", {country = Eng, region = Just Yorks, electorate = 73511}) -- Scarborough and Whitby
                , ("E14000914", {country = Eng, region = Just Yorks, electorate = 64025}) -- Scunthorpe
                , ("E14000915", {country = Eng, region = Just NE, electorate = 62844}) -- Sedgefield
                , ("E14000916", {country = Eng, region = Just NW, electorate = 67744}) -- Sefton Central
                , ("E14000917", {country = Eng, region = Just Yorks, electorate = 76082}) -- Selby and Ainsty
                , ("E14000918", {country = Eng, region = Just SE, electorate = 71958}) -- Sevenoaks
                , ("E14000919", {country = Eng, region = Just Yorks, electorate = 70422}) -- Sheffield Central
                , ("E14000920", {country = Eng, region = Just Yorks, electorate = 67950}) -- Sheffield South East
                , ("E14000921", {country = Eng, region = Just Yorks, electorate = 72321}) -- Sheffield, Brightside and Hillsborough
                , ("E14000922", {country = Eng, region = Just Yorks, electorate = 70874}) -- Sheffield, Hallam
                , ("E14000923", {country = Eng, region = Just Yorks, electorate = 72351}) -- Sheffield, Heeley
                , ("E14000924", {country = Eng, region = Just EMid, electorate = 73349}) -- Sherwood
                , ("E14000925", {country = Eng, region = Just Yorks, electorate = 70464}) -- Shipley
                , ("E14000926", {country = Eng, region = Just WMid, electorate = 76400}) -- Shrewsbury and Atcham
                , ("E14000927", {country = Eng, region = Just SE, electorate = 76018}) -- Sittingbourne and Sheppey
                , ("E14000928", {country = Eng, region = Just Yorks, electorate = 76645}) -- Skipton and Ripon
                , ("E14000929", {country = Eng, region = Just EMid, electorate = 87972}) -- Sleaford and North Hykeham
                , ("E14000930", {country = Eng, region = Just SE, electorate = 86366}) -- Slough
                , ("E14000931", {country = Eng, region = Just WMid, electorate = 77956}) -- Solihull
                , ("E14000932", {country = Eng, region = Just SW, electorate = 83281}) -- Somerton and Frome
                , ("E14000933", {country = Eng, region = Just East, electorate = 71155}) -- South Basildon and East Thurrock
                ]
            ,   [ ("E14000934", {country = Eng, region = Just East, electorate = 84132}) -- South Cambridgeshire
                , ("E14000935", {country = Eng, region = Just EMid, electorate = 73923}) -- South Derbyshire
                , ("E14000936", {country = Eng, region = Just SW, electorate = 71534}) -- South Dorset
                , ("E14000937", {country = Eng, region = Just East, electorate = 84570}) -- South East Cambridgeshire
                , ("E14000938", {country = Eng, region = Just SW, electorate = 71071}) -- South East Cornwall
                , ("E14000939", {country = Eng, region = Just EMid, electorate = 76460}) -- South Holland and The Deepings
                , ("E14000940", {country = Eng, region = Just EMid, electorate = 76851}) -- South Leicestershire
                , ("E14000941", {country = Eng, region = Just East, electorate = 80721}) -- South Norfolk
                , ("E14000942", {country = Eng, region = Just EMid, electorate = 85781}) -- South Northamptonshire
                , ("E14000943", {country = Eng, region = Just NW, electorate = 76489}) -- South Ribble
                , ("E14000944", {country = Eng, region = Just NE, electorate = 62730}) -- South Shields
                , ("E14000945", {country = Eng, region = Just WMid, electorate = 72771}) -- South Staffordshire
                , ("E14000946", {country = Eng, region = Just East, electorate = 73836}) -- South Suffolk
                , ("E14000947", {country = Eng, region = Just SW, electorate = 73926}) -- South Swindon
                , ("E14000948", {country = Eng, region = Just SE, electorate = 70970}) -- South Thanet
                , ("E14000949", {country = Eng, region = Just East, electorate = 79285}) -- South West Bedfordshire
                , ("E14000950", {country = Eng, region = Just SW, electorate = 71035}) -- South West Devon
                , ("E14000951", {country = Eng, region = Just East, electorate = 79668}) -- South West Hertfordshire
                , ("E14000952", {country = Eng, region = Just East, electorate = 76970}) -- South West Norfolk
                , ("E14000953", {country = Eng, region = Just SE, electorate = 77548}) -- South West Surrey
                , ("E14000954", {country = Eng, region = Just SW, electorate = 73018}) -- South West Wiltshire
                , ("E14000955", {country = Eng, region = Just SE, electorate = 72281}) -- Southampton, Itchen
                , ("E14000956", {country = Eng, region = Just SE, electorate = 70270}) -- Southampton, Test
                , ("E14000957", {country = Eng, region = Just East, electorate = 66876}) -- Southend West
                , ("E14000958", {country = Eng, region = Just NW, electorate = 67326}) -- Southport
                , ("E14000959", {country = Eng, region = Just SE, electorate = 71592}) -- Spelthorne
                , ("E14000960", {country = Eng, region = Just East, electorate = 75825}) -- St Albans
                , ("E14000961", {country = Eng, region = Just SW, electorate = 76607}) -- St Austell and Newquay
                , ("E14000962", {country = Eng, region = Just NW, electorate = 75262}) -- St Helens North
                , ("E14000963", {country = Eng, region = Just NW, electorate = 77720}) -- St Helens South and Whiston
                , ("E14000964", {country = Eng, region = Just SW, electorate = 65570}) -- St Ives
                , ("E14000965", {country = Eng, region = Just WMid, electorate = 68705}) -- Stafford
                , ("E14000966", {country = Eng, region = Just WMid, electorate = 63104}) -- Staffordshire Moorlands
                , ("E14000967", {country = Eng, region = Just NW, electorate = 71357}) -- Stalybridge and Hyde
                , ("E14000968", {country = Eng, region = Just East, electorate = 70597}) -- Stevenage
                , ("E14000969", {country = Eng, region = Just NW, electorate = 63931}) -- Stockport
                , ("E14000970", {country = Eng, region = Just NE, electorate = 66126}) -- Stockton North
                , ("E14000971", {country = Eng, region = Just NE, electorate = 75111}) -- Stockton South
                , ("E14000972", {country = Eng, region = Just WMid, electorate = 60634}) -- Stoke-on-Trent Central
                , ("E14000973", {country = Eng, region = Just WMid, electorate = 71438}) -- Stoke-on-Trent North
                , ("E14000974", {country = Eng, region = Just WMid, electorate = 68091}) -- Stoke-on-Trent South
                , ("E14000975", {country = Eng, region = Just WMid, electorate = 67339}) -- Stone
                , ("E14000976", {country = Eng, region = Just WMid, electorate = 69077}) -- Stourbridge
                , ("E14000977", {country = Eng, region = Just WMid, electorate = 71304}) -- Stratford-on-Avon
                , ("E14000978", {country = Eng, region = Just London, electorate = 79137}) -- Streatham
                , ("E14000979", {country = Eng, region = Just NW, electorate = 69026}) -- Stretford and Urmston
                , ("E14000980", {country = Eng, region = Just SW, electorate = 80544}) -- Stroud
                , ("E14000981", {country = Eng, region = Just East, electorate = 77816}) -- Suffolk Coastal
                , ("E14000982", {country = Eng, region = Just NE, electorate = 72950}) -- Sunderland Central
                , ("E14000983", {country = Eng, region = Just SE, electorate = 79515}) -- Surrey Heath
                , ("E14000984", {country = Eng, region = Just London, electorate = 69228}) -- Sutton and Cheam
                , ("E14000985", {country = Eng, region = Just WMid, electorate = 74956}) -- Sutton Coldfield
                , ("E14000986", {country = Eng, region = Just WMid, electorate = 71913}) -- Tamworth
                , ("E14000987", {country = Eng, region = Just NW, electorate = 65004}) -- Tatton
                , ("E14000988", {country = Eng, region = Just SW, electorate = 83221}) -- Taunton Deane
                , ("E14000989", {country = Eng, region = Just WMid, electorate = 66166}) -- Telford
                , ("E14000990", {country = Eng, region = Just SW, electorate = 78910}) -- Tewkesbury
                , ("E14000991", {country = Eng, region = Just SW, electorate = 78290}) -- The Cotswolds
                , ("E14000992", {country = Eng, region = Just WMid, electorate = 65942}) -- The Wrekin
                , ("E14000993", {country = Eng, region = Just Yorks, electorate = 77451}) -- Thirsk and Malton
                , ("E14000994", {country = Eng, region = Just SW, electorate = 66066}) -- Thornbury and Yate
                , ("E14000995", {country = Eng, region = Just East, electorate = 77559}) -- Thurrock
                , ("E14000996", {country = Eng, region = Just SW, electorate = 76270}) -- Tiverton and Honiton
                , ("E14000997", {country = Eng, region = Just SE, electorate = 74877}) -- Tonbridge and Malling
                , ("E14000998", {country = Eng, region = Just London, electorate = 76782}) -- Tooting
                , ("E14000999", {country = Eng, region = Just SW, electorate = 76350}) -- Torbay
                , ("E14001000", {country = Eng, region = Just SW, electorate = 78621}) -- Torridge and West Devon
                , ("E14001001", {country = Eng, region = Just SW, electorate = 68630}) -- Totnes
                , ("E14001002", {country = Eng, region = Just London, electorate = 70803}) -- Tottenham
                , ("E14001003", {country = Eng, region = Just SW, electorate = 73601}) -- Truro and Falmouth
                , ("E14001004", {country = Eng, region = Just SE, electorate = 73429}) -- Tunbridge Wells
                , ("E14001005", {country = Eng, region = Just London, electorate = 80250}) -- Twickenham
                , ("E14001006", {country = Eng, region = Just NE, electorate = 77524}) -- Tynemouth
                , ("E14001007", {country = Eng, region = Just London, electorate = 70631}) -- Uxbridge and South Ruislip
                , ("E14001008", {country = Eng, region = Just London, electorate = 82231}) -- Vauxhall
                , ("E14001009", {country = Eng, region = Just Yorks, electorate = 70521}) -- Wakefield
                , ("E14001010", {country = Eng, region = Just NW, electorate = 65495}) -- Wallasey
                , ("E14001011", {country = Eng, region = Just WMid, electorate = 67080}) -- Walsall North
                , ("E14001012", {country = Eng, region = Just WMid, electorate = 67743}) -- Walsall South
                , ("E14001013", {country = Eng, region = Just London, electorate = 67015}) -- Walthamstow
                , ("E14001014", {country = Eng, region = Just NE, electorate = 60705}) -- Wansbeck
                , ("E14001015", {country = Eng, region = Just SE, electorate = 82931}) -- Wantage
                , ("E14001016", {country = Eng, region = Just WMid, electorate = 63738}) -- Warley
                , ("E14001017", {country = Eng, region = Just NW, electorate = 72104}) -- Warrington North
                , ("E14001018", {country = Eng, region = Just NW, electorate = 84767}) -- Warrington South
                , ("E14001019", {country = Eng, region = Just WMid, electorate = 71578}) -- Warwick and Leamington
                , ("E14001020", {country = Eng, region = Just NE, electorate = 68190}) -- Washington and Sunderland West
                , ("E14001021", {country = Eng, region = Just East, electorate = 83535}) -- Watford
                , ("E14001022", {country = Eng, region = Just East, electorate = 80166}) -- Waveney
                , ("E14001023", {country = Eng, region = Just SE, electorate = 80236}) -- Wealden
                , ("E14001024", {country = Eng, region = Just NW, electorate = 68407}) -- Weaver Vale
                , ("E14001025", {country = Eng, region = Just EMid, electorate = 74317}) -- Wellingborough
                , ("E14001026", {country = Eng, region = Just SW, electorate = 79405}) -- Wells
                , ("E14001027", {country = Eng, region = Just East, electorate = 73247}) -- Welwyn Hatfield
                , ("E14001028", {country = Eng, region = Just Yorks, electorate = 74283}) -- Wentworth and Dearne
                , ("E14001029", {country = Eng, region = Just WMid, electorate = 63637}) -- West Bromwich East
                , ("E14001030", {country = Eng, region = Just WMid, electorate = 65524}) -- West Bromwich West
                , ("E14001031", {country = Eng, region = Just SW, electorate = 78000}) -- West Dorset
                , ("E14001032", {country = Eng, region = Just London, electorate = 90640}) -- West Ham
                , ("E14001033", {country = Eng, region = Just NW, electorate = 70906}) -- West Lancashire
                ]
            ,   [ ("E14001034", {country = Eng, region = Just East, electorate = 76198}) -- West Suffolk
                , ("E14001035", {country = Eng, region = Just WMid, electorate = 73394}) -- West Worcestershire
                , ("E14001036", {country = Eng, region = Just London, electorate = 62346}) -- Westminster North
                , ("E14001037", {country = Eng, region = Just NW, electorate = 65857}) -- Westmorland and Lonsdale
                , ("E14001038", {country = Eng, region = Just SW, electorate = 80309}) -- Weston-Super-Mare
                , ("E14001039", {country = Eng, region = Just NW, electorate = 75990}) -- Wigan
                , ("E14001040", {country = Eng, region = Just London, electorate = 65853}) -- Wimbledon
                , ("E14001041", {country = Eng, region = Just SE, electorate = 74119}) -- Winchester
                , ("E14001042", {country = Eng, region = Just SE, electorate = 71538}) -- Windsor
                , ("E14001043", {country = Eng, region = Just NW, electorate = 56956}) -- Wirral South
                , ("E14001044", {country = Eng, region = Just NW, electorate = 55377}) -- Wirral West
                , ("E14001045", {country = Eng, region = Just East, electorate = 67090}) -- Witham
                , ("E14001046", {country = Eng, region = Just SE, electorate = 79767}) -- Witney
                , ("E14001047", {country = Eng, region = Just SE, electorate = 74269}) -- Woking
                , ("E14001048", {country = Eng, region = Just SE, electorate = 77881}) -- Wokingham
                , ("E14001049", {country = Eng, region = Just WMid, electorate = 61065}) -- Wolverhampton North East
                , ("E14001050", {country = Eng, region = Just WMid, electorate = 62556}) -- Wolverhampton South East
                , ("E14001051", {country = Eng, region = Just WMid, electorate = 60368}) -- Wolverhampton South West
                , ("E14001052", {country = Eng, region = Just WMid, electorate = 72461}) -- Worcester
                , ("E14001053", {country = Eng, region = Just NW, electorate = 58615}) -- Workington
                , ("E14001054", {country = Eng, region = Just NW, electorate = 72177}) -- Worsley and Eccles South
                , ("E14001055", {country = Eng, region = Just SE, electorate = 75617}) -- Worthing West
                , ("E14001056", {country = Eng, region = Just SE, electorate = 76371}) -- Wycombe
                , ("E14001057", {country = Eng, region = Just NW, electorate = 70637}) -- Wyre and Preston North
                , ("E14001058", {country = Eng, region = Just WMid, electorate = 77407}) -- Wyre Forest
                , ("E14001059", {country = Eng, region = Just NW, electorate = 75994}) -- Wythenshawe and Sale East
                , ("E14001060", {country = Eng, region = Just SW, electorate = 82447}) -- Yeovil
                , ("E14001061", {country = Eng, region = Just Yorks, electorate = 75351}) -- York Central
                , ("E14001062", {country = Eng, region = Just Yorks, electorate = 78561}) -- York Outer
                ]
            ,   [ ("N06000001", {country = NI, region = Nothing, electorate = 63157}) -- Belfast East
                , ("N06000002", {country = NI, region = Nothing, electorate = 68553}) -- Belfast North
                , ("N06000003", {country = NI, region = Nothing, electorate = 64927}) -- Belfast South
                , ("N06000004", {country = NI, region = Nothing, electorate = 62697}) -- Belfast West
                , ("N06000005", {country = NI, region = Nothing, electorate = 62811}) -- East Antrim
                , ("N06000006", {country = NI, region = Nothing, electorate = 66926}) -- East Londonderry
                , ("N06000007", {country = NI, region = Nothing, electorate = 70108}) -- Fermanagh and South Tyrone
                , ("N06000008", {country = NI, region = Nothing, electorate = 70036}) -- Foyle
                , ("N06000009", {country = NI, region = Nothing, electorate = 71152}) -- Lagan Valley
                , ("N06000010", {country = NI, region = Nothing, electorate = 67832}) -- Mid Ulster
                , ("N06000011", {country = NI, region = Nothing, electorate = 77633}) -- Newry and Armagh
                , ("N06000012", {country = NI, region = Nothing, electorate = 75876}) -- North Antrim
                , ("N06000013", {country = NI, region = Nothing, electorate = 64207}) -- North Down
                , ("N06000014", {country = NI, region = Nothing, electorate = 67425}) -- South Antrim
                , ("N06000015", {country = NI, region = Nothing, electorate = 75220}) -- South Down
                , ("N06000016", {country = NI, region = Nothing, electorate = 64289}) -- Strangford
                , ("N06000017", {country = NI, region = Nothing, electorate = 80060}) -- Upper Bann
                , ("N06000018", {country = NI, region = Nothing, electorate = 63856}) -- West Tyrone
                ]
            ,   [ ("S14000001", {country = Scot, region = Nothing, electorate = 67745}) -- Aberdeen North
                , ("S14000002", {country = Scot, region = Nothing, electorate = 68056}) -- Aberdeen South
                , ("S14000003", {country = Scot, region = Nothing, electorate = 66792}) -- Airdrie and Shotts
                , ("S14000004", {country = Scot, region = Nothing, electorate = 65792}) -- Angus
                , ("S14000005", {country = Scot, region = Nothing, electorate = 68875}) -- Argyll and Bute
                , ("S14000006", {country = Scot, region = Nothing, electorate = 72995}) -- Ayr, Carrick and Cumnock
                , ("S14000007", {country = Scot, region = Nothing, electorate = 68609}) -- Banff and Buchan
                , ("S14000008", {country = Scot, region = Nothing, electorate = 74214}) -- Berwickshire, Roxburgh and Selkirk
                , ("S14000009", {country = Scot, region = Nothing, electorate = 47558}) -- Caithness, Sutherland and Easter Ross
                , ("S14000010", {country = Scot, region = Nothing, electorate = 70021}) -- Central Ayrshire
                , ("S14000011", {country = Scot, region = Nothing, electorate = 73894}) -- Coatbridge, Chryston and Bellshill
                , ("S14000012", {country = Scot, region = Nothing, electorate = 67088}) -- Cumbernauld, Kilsyth and Kirkintilloch East
                , ("S14000013", {country = Scot, region = Nothing, electorate = 75249}) -- Dumfries and Galloway
                , ("S14000014", {country = Scot, region = Nothing, electorate = 68483}) -- Dumfriesshire, Clydesdale and Tweeddale
                , ("S14000015", {country = Scot, region = Nothing, electorate = 67822}) -- Dundee East
                , ("S14000016", {country = Scot, region = Nothing, electorate = 65927}) -- Dundee West
                , ("S14000017", {country = Scot, region = Nothing, electorate = 78037}) -- Dunfermline and West Fife
                , ("S14000018", {country = Scot, region = Nothing, electorate = 66966}) -- East Dunbartonshire
                , ("S14000019", {country = Scot, region = Nothing, electorate = 83205}) -- East Kilbride, Strathaven and Lesmahagow
                , ("S14000020", {country = Scot, region = Nothing, electorate = 79481}) -- East Lothian
                , ("S14000021", {country = Scot, region = Nothing, electorate = 69982}) -- East Renfrewshire
                , ("S14000022", {country = Scot, region = Nothing, electorate = 67141}) -- Edinburgh East
                , ("S14000023", {country = Scot, region = Nothing, electorate = 80910}) -- Edinburgh North and Leith
                , ("S14000024", {country = Scot, region = Nothing, electorate = 65801}) -- Edinburgh South
                , ("S14000025", {country = Scot, region = Nothing, electorate = 72149}) -- Edinburgh South West
                , ("S14000026", {country = Scot, region = Nothing, electorate = 71717}) -- Edinburgh West
                , ("S14000027", {country = Scot, region = Nothing, electorate = 21769}) -- Na h-Eileanan an Iar
                , ("S14000028", {country = Scot, region = Nothing, electorate = 83380}) -- Falkirk
                , ("S14000029", {country = Scot, region = Nothing, electorate = 70945}) -- Glasgow Central
                , ("S14000030", {country = Scot, region = Nothing, electorate = 70378}) -- Glasgow East
                , ("S14000031", {country = Scot, region = Nothing, electorate = 60169}) -- Glasgow North
                , ("S14000032", {country = Scot, region = Nothing, electorate = 66678}) -- Glasgow North East
                , ("S14000033", {country = Scot, region = Nothing, electorate = 68418}) -- Glasgow North West
                , ("S14000034", {country = Scot, region = Nothing, electorate = 74051}) -- Glasgow South
                , ("S14000035", {country = Scot, region = Nothing, electorate = 66209}) -- Glasgow South West
                , ("S14000036", {country = Scot, region = Nothing, electorate = 69781}) -- Glenrothes
                , ("S14000037", {country = Scot, region = Nothing, electorate = 79393}) -- Gordon
                , ("S14000038", {country = Scot, region = Nothing, electorate = 59350}) -- Inverclyde
                , ("S14000039", {country = Scot, region = Nothing, electorate = 77628}) -- Inverness, Nairn, Badenoch and Strathspey
                , ("S14000040", {country = Scot, region = Nothing, electorate = 75250}) -- Kilmarnock and Loudoun
                , ("S14000041", {country = Scot, region = Nothing, electorate = 75941}) -- Kirkcaldy and Cowdenbeath
                , ("S14000042", {country = Scot, region = Nothing, electorate = 79962}) -- Lanark and Hamilton East
                , ("S14000043", {country = Scot, region = Nothing, electorate = 86955}) -- Linlithgow and East Falkirk
                , ("S14000044", {country = Scot, region = Nothing, electorate = 82373}) -- Livingston
                , ("S14000045", {country = Scot, region = Nothing, electorate = 67875}) -- Midlothian
                , ("S14000046", {country = Scot, region = Nothing, electorate = 71685}) -- Moray
                , ("S14000047", {country = Scot, region = Nothing, electorate = 70283}) -- Motherwell and Wishaw
                , ("S14000048", {country = Scot, region = Nothing, electorate = 75791}) -- North Ayrshire and Arran
                , ("S14000049", {country = Scot, region = Nothing, electorate = 62003}) -- North East Fife
                , ("S14000050", {country = Scot, region = Nothing, electorate = 77370}) -- Ochil and South Perthshire
                , ("S14000051", {country = Scot, region = Nothing, electorate = 34552}) -- Orkney and Shetland
                , ("S14000052", {country = Scot, region = Nothing, electorate = 66206}) -- Paisley and Renfrewshire North
                , ("S14000053", {country = Scot, region = Nothing, electorate = 61281}) -- Paisley and Renfrewshire South
                , ("S14000054", {country = Scot, region = Nothing, electorate = 72459}) -- Perth and North Perthshire
                , ("S14000055", {country = Scot, region = Nothing, electorate = 54169}) -- Ross, Skye and Lochaber
                , ("S14000056", {country = Scot, region = Nothing, electorate = 82830}) -- Rutherglen and Hamilton West
                , ("S14000057", {country = Scot, region = Nothing, electorate = 67236}) -- Stirling
                , ("S14000058", {country = Scot, region = Nothing, electorate = 73445}) -- West Aberdeenshire and Kincardine
                , ("S14000059", {country = Scot, region = Nothing, electorate = 69208}) -- West Dunbartonshire
                ]
            ,   [ ("W07000041", {country = Wales, region = Nothing, electorate = 49939}) -- Ynys Môn
                , ("W07000042", {country = Wales, region = Nothing, electorate = 53639}) -- Delyn
                , ("W07000043", {country = Wales, region = Nothing, electorate = 62016}) -- Alyn and Deeside
                , ("W07000044", {country = Wales, region = Nothing, electorate = 50992}) -- Wrexham
                , ("W07000045", {country = Wales, region = Nothing, electorate = 59314}) -- Llanelli
                , ("W07000046", {country = Wales, region = Nothing, electorate = 61820}) -- Gower
                , ("W07000047", {country = Wales, region = Nothing, electorate = 58776}) -- Swansea West
                , ("W07000048", {country = Wales, region = Nothing, electorate = 58011}) -- Swansea East
                , ("W07000049", {country = Wales, region = Nothing, electorate = 49821}) -- Aberavon
                , ("W07000050", {country = Wales, region = Nothing, electorate = 57456}) -- Cardiff Central
                , ("W07000051", {country = Wales, region = Nothing, electorate = 67196}) -- Cardiff North
                , ("W07000052", {country = Wales, region = Nothing, electorate = 51811}) -- Rhondda
                , ("W07000053", {country = Wales, region = Nothing, electorate = 61896}) -- Torfaen
                , ("W07000054", {country = Wales, region = Nothing, electorate = 62248}) -- Monmouth
                , ("W07000055", {country = Wales, region = Nothing, electorate = 56015}) -- Newport East
                , ("W07000056", {country = Wales, region = Nothing, electorate = 62137}) -- Newport West
                , ("W07000057", {country = Wales, region = Nothing, electorate = 40492}) -- Arfon
                , ("W07000058", {country = Wales, region = Nothing, electorate = 45525}) -- Aberconwy
                , ("W07000059", {country = Wales, region = Nothing, electorate = 58644}) -- Clwyd West
                , ("W07000060", {country = Wales, region = Nothing, electorate = 56505}) -- Vale of Clwyd
                , ("W07000061", {country = Wales, region = Nothing, electorate = 44394}) -- Dwyfor Meirionnydd
                , ("W07000062", {country = Wales, region = Nothing, electorate = 54996}) -- Clwyd South
                , ("W07000063", {country = Wales, region = Nothing, electorate = 48690}) -- Montgomeryshire
                , ("W07000064", {country = Wales, region = Nothing, electorate = 54242}) -- Ceredigion
                , ("W07000065", {country = Wales, region = Nothing, electorate = 57291}) -- Preseli Pembrokeshire
                , ("W07000066", {country = Wales, region = Nothing, electorate = 57755}) -- Carmarthen West and South Pembrokeshire
                , ("W07000067", {country = Wales, region = Nothing, electorate = 55750}) -- Carmarthen East and Dinefwr
                , ("W07000068", {country = Wales, region = Nothing, electorate = 54441}) -- Brecon and Radnorshire
                , ("W07000069", {country = Wales, region = Nothing, electorate = 56097}) -- Neath
                , ("W07000070", {country = Wales, region = Nothing, electorate = 51422}) -- Cynon Valley
                , ("W07000071", {country = Wales, region = Nothing, electorate = 61716}) -- Merthyr Tydfil and Rhymney
                , ("W07000072", {country = Wales, region = Nothing, electorate = 51335}) -- Blaenau Gwent
                , ("W07000073", {country = Wales, region = Nothing, electorate = 59998}) -- Bridgend
                , ("W07000074", {country = Wales, region = Nothing, electorate = 55572}) -- Ogmore
                , ("W07000075", {country = Wales, region = Nothing, electorate = 58940}) -- Pontypridd
                , ("W07000076", {country = Wales, region = Nothing, electorate = 63603}) -- Caerphilly
                , ("W07000077", {country = Wales, region = Nothing, electorate = 55697}) -- Islwyn
                , ("W07000078", {country = Wales, region = Nothing, electorate = 72794}) -- Vale of Glamorgan
                , ("W07000079", {country = Wales, region = Nothing, electorate = 66762}) -- Cardiff West
                , ("W07000080", {country = Wales, region = Nothing, electorate = 76006}) -- Cardiff South and Penarth
                ]
            ]
        )


get : String -> Maybe Item
get constituencyCode =
    Dict.get constituencyCode items
