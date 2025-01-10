module Copy exposing (copy)


copy =
    { title = "Kleihaven"
    , pageInDevelopment = "Pagina in ontwikkeling"
    , notFound =
        { title = "Pagina niet gevonden"
        , description = "De pagina die je zoekt bestaat niet."
        }
    , home =
        { title = "Studio1931"
        , subtitle = "ontdekken, beleven en creëren op een bijzondere locatie"
        , intro = """
            Gevestigd in een voormalige basisschool aan de Waddenzee, biedt Studio 1931
            keramiekcursussen, een artist-in-residence programma en gastenverblijf in
            een inspirerende omgeving.
            """
        , coursesButton = "Direct naar de cursussen"
        , block =
            { title = "Programma's en activiteiten"
            , description = """
                Studio1931 is een broedplaats met artistieke programma's en activiteiten. 
                Bij ons vind je alle ruimte om je ideeën tot leven te brengen.
                """
            }
        , blockKleihaven =
            { title = "Studio1931 presenteert: Kleihaven"
            , description1 = """
                Bij Kleihaven draait alles om leren en creëren.
                Onder de inspirerende leiding van bevlogen kunstenaars en docenten bieden we
                diverse keramiekcursussen, variërend van enkele dagen tot twee weken.
                Van draaitechnieken en handvormen tot glazuren en stooktechnieken – bij ons
                kun je zowel je technische vaardigheden als je creatieve ideeën verder ontwikkelen.
                """
            , description2 = """
                Onze cursussen zijn geschikt voor zowel enthousiaste amateurs als doorgewinterde
                professionals. En wil je het meeste uit je ervaring halen? Blijf dan logeren in ons
                gastenverblijf en dompel je volledig onder in de creatieve sfeer.
                """
            , description3 = """
                Een bijzondere leerervaring voor je handen en je hoofd! Kleihaven biedt voor iedereen
                iets unieks.
                """
            , readMore = "Lees meer"
            }
        , blockAIR =
            { title = "Artist in Residence programma's"
            , description1 = """
                Ben jij beeldend kunstenaar en toe aan een plek waar frisse zeewind nieuwe 
                energie aan je werk geeft? Of je nu ruimte zoekt om bestaande plannen uit 
                te werken, of inspiratie op te doen voor nieuwe projecten, Studio1931 biedt een ruime 
                werkplek en tijd om je te focussen. 
                """
            , description2 = """
                We bieden werkperiodes van 4 à 6 weken voor individuele kunstenaars of duo's.
                Ook hebben we onze TUSSEN ZOET EN ZOUT week: 
                een jaarlijks terugkerende projectweek waarin meerdere kunstenaars (samen)werken.
                """
            , description3 = """
                Laat je meevoeren door de rust, wind 
                en bijzondere omgeving - dé ingrediënten om jouw proces en werk te laten bruisen. 
                """
            , readMore = "Lees meer"
            }
        , blockOverOns =
            { title = "Over Studio1931"
            , description1 = """
                Studio1931 heeft als doel om makers, publiek, kunst en omgeving met elkaar te verbinden.
                """
            , description2 = """
                We zijn gevestigd in de oude basisschool van Den Oever, 
                op het voormalige Zuiderzee-eiland Wieringen.
                Het is een prachtige plek om zowel te wonen als te werken in 
                en tussen de kunsten.
                """
            , description3 = """
                Met werelderfgoed de Waddenzee in de achtertuin 
                en het IJsselmeer op loopafstand zit Studio1931 op een bijzondere 
                locatie waar de zeewind alle artistieke plannen en creatieve ideeën aanwakkert.
                """
            , readMore = "Lees meer"
            }
        }
    , kleihaven =
        { title = "Kleihaven"
        , subtitle = "het toevluchtsoord en de vertrekplek voor keramiek"
        , intro = """
            Wil je keramist worden? Of je vaardigheden juist verder ontwikkelen? Jouw creativiteit een boost geven? 
            Experimenteren met klei? Welkom bij de Kleihaven! 
            Wij bieden keramiekcursussen van enkele dagen tot twee volle weken.
            """
        , coursesButton = "Bekijk alle cursussen"
        , blockOne =
            { title = "Ontdek, creëer en geniet!"
            , subtitle = "Bij Kleihaven ligt de wereld van keramiek in jouw handen"
            , cards =
                [ { imgSrc = "6x8/potje"
                  , imgAlt = "Keramieken potje in een paar handen"
                  , text = """
                    Voor beginners en gevorderden – leer van beeldend kunstenaars en bevlogen docenten
                    """
                  }
                , { imgSrc = "6x8/mensen"
                  , imgAlt = "Groep cursisten aan het werk in de tuin keramiekwerkplaats"
                  , text = """
                    Werk aan technische vaardigheden en ontdek jouw creatieve mogelijkheden
                    """
                  }
                , { imgSrc = "6x8/wieringen"
                  , imgAlt = "Foto de Waddenzee vanaf voormalig eiland Wieringen"
                  , text = """
                    Beleef voormalig eiland Wieringen, omringd door de Waddenzee en het IJsselmeer
                    """
                  }
                ]
            , viewCoursesButton = "Bekijk onze cursussen"
            }
        , blockTwo =
            { title = "Over de Kleihaven"
            , intro = """
                Kleihaven is gevestigd in Studio 1931, de oude school van Den Oever. 
                Het is een plek om te wonen, werken en verblijven in en tussen de kunsten – dat delen we graag met jou!
                """
            , inside =
                { title = "Van binnen..."
                , text1 = """
                    Eén van de lokalen is ingericht als volledig uitgeruste keramiekwerkplaats. 
                    Hier staan acht splinternieuwe draaischijven, een grote kleiwals, strengenpers 
                    en andere materialen voor je klaar. 
                    """
                , text2 = """Er zijn ovens in verschillende maten, en we hebben
                    alles klaarstaan voor rakustook."""
                , text3 = "Kortom – stap binnen en begin!"
                }
            , outside =
                { title = "...naar buiten!"
                , text1 = """      
                    Ook buiten is het genieten. Het oorspronkelijke schoolplein is een bloeiende 
                    tuin geworden.
                    """
                , text2 = """      
                    Zodra het weer het toelaat, werken we graag in de buitenlucht. 
                    Denk aan grote tafels om samen aan te werken, of een rustig plekje met een kleibok 
                    tussen de rozen en de eeuwenoude lindenbomen.
                    """
                , text3 = "Klinkt goed, toch?"
                }
            }
        , mobileCoursesButton = "Boek nu een cursus!"
        }
    }
