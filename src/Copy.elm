module Copy exposing (copy)


copy =
    { title = "Kleihaven"
    , pageInDevelopment = "Pagina in ontwikkeling"
    , notFound =
        { title = "Pagina niet gevonden"
        , description = "De pagina die je zoekt bestaat niet."
        }
    , home =
        { title = "Studio 1931"
        , subtitle = "ontdekken, beleven en creëren op een bijzondere locatie"
        , intro = """
            Gevestigd in een voormalige basisschool aan de Waddenzee, biedt Studio 1931
            keramiekcursussen, een artist-in-residence programma en gastenverblijf in
            een inspirerende omgeving.
            """
        , coursesButton = "Direct naar de cursussen"
        }
    , kleihaven =
        { title = "Kleihaven"
        , subtitle = "het toevluchtsoord en de vertrekplek voor keramiek"
        , intro = """
            Wil je keramist worden? Jouw creativiteit een boost geven? 
            Experimenteren met klei? Welkom bij de Kleihaven! 
            Wij bieden keramiekcursussen van enkele dagen tot twee volle weken.
            """
        , coursesButton = "Bekijk alle cursussen"
        , blockOne =
            { title = "Ontdek, creëer en geniet!"
            , subtitle = "Bij Kleihaven ligt de wereld van keramiek in jouw handen"
            , cards =
                [ { imgSrc = "/assets/6x8/potje.jpg"
                  , text = """
                    Voor beginners en gevorderden – leer van beeldend kunstenaars en bevlogen docenten
                    """
                  }
                , { imgSrc = "/assets/6x8/mensen.jpg"
                  , text = """
                    Werk aan technische vaardigheden en ontdek jouw creatieve mogelijkheden
                    """
                  }
                , { imgSrc = "/assets/6x8/wieringen.jpg"
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
                { title = "Naar buiten!"
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
        }
    }
