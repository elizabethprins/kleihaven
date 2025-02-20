module Copy exposing (copy, faqPage, privacyPage, termsPage)

import Html exposing (..)
import Markdown


copy =
    { title = "Kleihaven"
    , pageInDevelopment = "– Pagina in ontwikkeling –"
    , lorem = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit,
        sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris
        nisi ut aliquip ex ea commodo consequat.
        """
    , loremTwo = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit,
        sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris
        nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
        reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
        pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
        culpa qui officia deserunt mollit anim id est laborum.
        """
    , loremTitle = "Excepteur sint occaecat"
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


privacyPage : List (Html msg)
privacyPage =
    [ Markdown.toHtml [] """
# Privacy Policy

### Gegevensverwerking bij Studio1931

Bij Studio1931 hechten we veel waarde aan de bescherming van jouw persoonsgegevens. In deze privacyverklaring leggen we duidelijk uit hoe we met jouw gegevens omgaan. We doen er alles aan om jouw privacy te waarborgen en behandelen jouw gegevens zorgvuldig.

Dit betekent dat wij:

- Jouw persoonsgegevens alleen verwerken voor de doeleinden waarvoor je ze hebt verstrekt, zoals beschreven in deze privacyverklaring.
- De verwerking van jouw persoonsgegevens beperken tot de gegevens die minimaal nodig zijn voor de doeleinden waarvoor ze worden verzameld.
- In gevallen waar toestemming vereist is, vragen wij jouw uitdrukkelijke toestemming voor de verwerking van je persoonsgegevens.
- Passende technische en organisatorische maatregelen treffen om de beveiliging van jouw persoonsgegevens te waarborgen.
- Jouw gegevens niet delen met derden, tenzij dit noodzakelijk is voor de uitvoering van de doeleinden waarvoor ze zijn verstrekt.
- Je wijzen op jouw rechten met betrekking tot je persoonsgegevens en deze respecteren.

### Waarvoor verwerken wij jouw persoonsgegevens?

Bij Studio1931 verwerken we jouw persoonsgegevens voor de volgende doeleinden:

- Het registreren van je inschrijving voor cursussen en workshops;
- Het voeren van de administratieve en financiële administratie;
- Het versturen van e-mailupdates, nieuwsbrieven en belangrijke informatie over cursussen of workshops.

Voor de bovengenoemde doeleinden kunnen wij de volgende persoonsgegevens van je vragen:

- Voornaam en achternaam;
- Adres, postcode en woonplaats;
- E-mailadres;
- Telefoonnummer.

### Jouw rechten met betrekking tot je gegevens
Je hebt altijd recht op inzage in de persoonsgegevens die wij van jou hebben. Daarnaast kun je verzoeken om correctie, verwijdering of beperking van de verwerking van jouw gegevens. Ook kun je bezwaar maken tegen de verwerking van je persoonsgegevens, of een deel hiervan.

Wil je gebruik maken van één van deze rechten, neem dan contact op met Studio1931 via het e-mailadres [info@studio1931.nl](mailto:info@studio1931.nl). We kunnen je vragen om je identiteit te verifiëren voordat we op jouw verzoek reageren.

### Verstrekking van gegevens aan derden

In sommige gevallen kan het nodig zijn om je gegevens te verstrekken aan derden, bijvoorbeeld voor de uitvoering van de hierboven beschreven doeleinden. Dit kan zijn voor:

- Het onderhouden en beheren van onze website en digitale systemen;
- Het versturen van e-mailnieuwsbrieven (via bijvoorbeeld Mailchimp);
- Het organiseren van cursussen of workshops waarvoor externe partijen betrokken zijn (zoals gastdocenten).
"""
    ]


faqPage : List (Html msg)
faqPage =
    [ Markdown.toHtml [] """
# Veelgestelde vragen

## Cursussen

### Wat zijn de tijden van de cursus?
Cursussen starten om 10:00 en eindigen rond 16:00, tenzij anders aangegeven. In de meeste gevallen kun je tot 21:00 doorwerken. De specifieke tijden staan in de cursusinformatie.
### Wat is de lengte van een cursus?
De duur verschilt per cursus. Kijk bij de cursusinformatie voor de specifieke data en tijden.
### Voor wie zijn de cursussen geschikt?
Onze cursussen zijn voor iedereen die graag met keramiek aan de slag wil, van beginners tot gevorderden. We bieden ook specifieke beginnerscursussen aan. Cursussen vragen concentratie en inspanning, dus voor kinderen onder de 12 jaar zijn andere cursussen geschikter.
### Wat is inbegrepen bij de cursus?
De cursusprijs omvat klei, glazuur (indien van toepassing) en 10 kg biscuit stoken per persoon. We zorgen ook voor koffie, thee, limonade en iets lekkers. Verblijf is niet inbegrepen.
### Is er een mogelijkheid om privélessen te boeken?
Leuke vraag. In overleg is ontzettend veel mogelijk. Neem hiervoor even contact met ons op.
### Wat als ik geen ervaring heb met keramiek?
Je bent van harte welkom! We bieden speciale beginnerscursussen aan én we inventariseren bij alle cursussen hoeveel ervaring mensen hebben. Onze cursussen zijn dus voor alle niveaus toegankelijk.

## Inschrijving en Annulering

### Hoe meld ik me aan voor een cursus?
Via de pagina [Cursussen](/cursussen/) klik je een cursus aan, vervolgens klik je op inschrijven. Daarna kom je in een menu terecht waar gevraagd wordt naar jouw gegevens en kun je betalen. Na betaling is de inschrijving definitief.
### Wat gebeurt er als ik niet kan komen?
Wat jammer dat je niet kunt! Zie hiervoor ook onze [Algemene Voorwaarden](/algemene-voorwaarden/). We hanteren de volgende afspraken:
- **Meer dan 6 weken voor aanvang van de cursus:** Je ontvangt het volledige lesgeld terug, minus €35 administratiekosten.
- **Tussen 1 maand en 1 week voor aanvang van de cursus:** Je krijgt 50% van het cursusgeld terug.
- **Minder dan 1 week voor aanvang of na de start van de cursus/workshop:** Er wordt geen terugbetaling gedaan.
- **Vervangen door een ander:** In overleg kun je iemand anders regelen om jouw plaats in te nemen. In dat geval worden alleen administratiekosten van €35 in rekening gebracht. Een andere deelnemer kunnen we alleen bij aanvang van de cursus ontvangen, halverwege of later in de cursus gaat helaas niet.

### Kan ik een cursus cadeau doen?
Ja, dat kan zeker! Neem contact met ons op voor meer informatie.
### Is er een wachtlijst als een cursus vol is?
Ja, stuur een e-mail naar [hello@studio1931.nl](mailto:hello@studio1931.nl) en we nemen contact met je op zodra er een plek beschikbaar komt.
### Ik kan helaas niet, kan ik de cursus verplaatsen?
Dit is alleen mogelijk als er in hetzelfde kalenderjaar een vergelijkbare cursus is. En uiteraard op basis van beschikbaarheid.
### Wat gebeurt er als er te weinig deelnemers zijn voor een cursus?
De cursussen gaan door bij 6 deelnemers of meer. Zijn er minder deelnemers? Dan nemen we contact op met je.

## Materialen en Voorbereiding
### Welke materialen heb ik nodig?
Materialen en gereedschappen zijn allemaal aanwezig. Als je je eigen gereedschap meeneemt, label het dan met je naam. Een oud bankpasje en af te sluiten yoghurtpot kunnen handig zijn. Vergeet niet dat je kleding vies kan worden van de klei!
### Kan ik zelf klei of glazuur meenemen?
- Heb je zelf klei gewonnen? Leuk! Neem vooral mee, dan kunnen we kijken wat we er mee kunnen doen.
- Andere klei, als in zelf gekochte broden klei meenemen, dat raden we af. We werken met onze vaste merken en daarvan weten wij precies hoe het reageert - ook in combinatie met engobes en stoken.
- Glazuren meenemen is niet nodig, hier is van alles voorhanden. Meenemen is dan ook geen garantie voor gebruik. We willen graag zien welke materialen de oven in gaan en kunnen geen andere stookprogramma's / temperaturen doen tijdens de cursus. Bij de weekend/week cursussen komen we over het algemeen niet toe aan glazuurstook.
- Indien je engobes mee wilt nemen, houd dan rekening met de stooktemperatuur - 1220 graden.

### Mag ik foto's maken van mijn werk of van de cursus?
Je mag foto's maken van jouw werk, dat is geen enkel probleem. We vragen je wel rekening te houden met andere deelnemers en als je iets deelt op social media dat je Kleihaven vermeldt.
### Wat gebeurt er met mijn werk na de cursus?
Afhankelijk van de lengte van de cursus kun je na afloop het werk meenemen. Klei heeft tijd nodig om te drogen alvorens het gebakken kan worden. Bij langere cursussen kun je het werk meestal na afloop gelijk meenemen. Is het werk nog niet droog genoeg om gebakken te worden, dan bakken we het na afloop van de cursus en plannen we een ophaalmoment.

## Praktische informatie
### Zijn er voorzieningen voor mensen met een beperking?
Studio1931 is in een oud pand. We hebben geen voorzieningen zoals een invalidentoilet. Het draaien kan fysiek soms wat zwaarder zijn, handvormen daarentegen is voor vrijwel iedereen. Neem bij vragen over dit onderdeel vooral contact op, dan kijken we wat de mogelijkheden zijn.
### Waar kan ik parkeren?
Fietsen kunnen op ons terrein staan. Voor je auto is er gratis parkeergelegenheid bij het Vikingsschip, 150 meter verderop. We vragen je vriendelijk niet in de straat te parkeren.
### Waar kan ik verblijven?
We hebben een prachtig nieuw appartement beschikbaar, zie de [Over Ons](/over-ons/) pagina. Je kunt ook gebruik maken van een van de campings, B&B's en huisjes in de buurt. Zorg ervoor dat je op tijd boekt!
### Zijn lunch of diner inbegrepen?
Maaltijden zijn niet inbegrepen, tenzij anders aangegeven. Er is een koelkast en magnetron aanwezig. Op loopafstand is een supermarkt en er zijn diverse restaurants/eetgelegenheden.
### Bij mijn cursus staat dat er een lunch aangeboden wordt, houden jullie rekening met allergieën/diëten?
Bij sommige cursussen zit een lunch. Dit is aangegeven in de cursusinformatie. Indien er lunch aangeboden wordt, is dit een vegetarische lunch. Voor aanvang van de cursus ontvangt iedere deelnemer nog uitgebreidere informatie met betrekking tot de cursus. Het is dan ook mogelijk om diëten en allergieën aan te geven. Daarbij wel de opmerking dat kruisbestuiving niet te vermijden is.
### Wat heb ik nodig voor wadlopen?
Oude, dichte schoenen en droge kleding. Je zult tot ongeveer kniehoogte nat worden. Het is een leuke en niet te zware activiteit.
"""
    ]


termsPage : List (Html msg)
termsPage =
    [ Markdown.toHtml [] """
# Algemene Voorwaarden

## Algemene informatie
Studio1931 biedt onder de naam Kleihaven diverse keramiekcursussen aan. Waar 'Studio1931' genoemd wordt, kun je 'Kleihaven' lezen. De cursussen zijn divers van aard en voor verschillende niveaus. De cursussen vinden plaats in Studio1931, Den Oever, tenzij anders vermeld.

Studio1931 - Kleihaven streeft ernaar om zo zuiver mogelijk, zonder fouten, informatie op de website te plaatsen. Mocht er ergens op deze website een onjuistheid of onvolledigheid staan, dan kunnen wij daarvoor geen aansprakelijkheid aanvaarden.

### Inschrijving en betaling
- Inschrijvingen gaan via onze [onze cursuspagina](/cursussen/). Via deze pagina kun je je per cursus inschrijven. Voor het inschrijven zijn gegevens zoals naam, adres, telefoonnummer en email nodig.
- Actuele prijzen staan op de cursuspagina.
- De cursussen zijn inclusief materialen zoals het (in alle redelijkheid) gebruik van klei, gereedschap en glazuur, tenzij anders vermeld. Tot 10 kg stoken wij biscuit, tenzij anders vermeld.
- Indien een cursus vol is, kun je je via mail aanmelden voor de wachtlijst. Is er een plekje vrij, dan nemen we contact op.
- Betalingen gaan via iDeal of diverse creditcards.
- De betaling kun je pas starten na accorderen van de Algemene Voorwaarden (een vinkje onderaan het inschrijfformulier)
- De inschrijving is definitief na ontvangst betaling. Je ontvangt tevens een bevestiging per mail.
- Voor aanvang van de cursus ontvang je meer informatie over de cursus.

### Annuleringsvoorwaarden
- Meer dan 6 weken voor aanvang van de cursus: Je ontvangt het volledige lesgeld terug, minus €35 administratiekosten.
- Tussen 1 maand en 1 week voor aanvang van de cursus: Je krijgt 50% van het cursusgeld terug.
- Minder dan 1 week voor aanvang of na de start van de cursus/workshop: Er wordt geen terugbetaling gedaan.
- Vervangen door een ander: In overleg kun je iemand anders regelen om jouw plaats in te nemen. Een andere deelnemer kunnen we alleen ontvangen bij aanvang van de cursus, later kan helaas niet. In het geval van een door jouw aangemelde cursist worden alleen de administratiekosten van €35  in rekening gebracht.
- Bij plotselinge annulering door Studio1931, nemen wij zo spoedig mogelijk contact op en zullen wij kijken naar een passende oplossing. Indien er geen passende oplossing is, zoals een cursus op een ander moment, ontvang je het geld terug.
- In geen geval vindt er een vergoeding plaats voor kosten zoals verblijf en/of reis.
- De cursussen vinden alleen plaats mits er minimaal 6 deelnemers zijn. Bij onvoldoende deelnemers kan de cursus geannuleerd worden. Mocht een cursus niet plaatsvinden of uitgesteld worden dan ontvang je uiterlijk 7 dagen voor aanvang bericht voor of een nieuwe datum, of wordt het cursusgeld terugbetaald. In geen geval vindt er een vergoeding plaats voor kosten zoals verblijf en/of reis.
- Bij ziekte of verhindering van een docent doet Studio1931 haar uiterste best om een andere docent aan te trekken. Lukt dat niet, dan kan de cursus geannuleerd worden. In overleg kan dan, zonder extra kosten, gekeken worden naar nieuwe data. Indien de cursus geannuleerd wordt, wordt het bedrag teruggestort. In geen geval vindt er een vergoeding plaats voor kosten zoals verblijf en/of reis.

### Verantwoordelijkheid en aansprakelijkheid
- Studio1931 is niet aansprakelijk voor schade, verlies, diefstal of beschadiging van eigendommen, goederen, geld of schade aan personen, door welke oorzaak dan ook, die zich voordoen tijdens activiteiten die door of namens Studio1931 worden georganiseerd, zowel direct als indirect.
- De deelnemer is zelf aansprakelijk voor schade die hij of zij toebrengt aan eigendommen, goederen en gebouwen van Studio1931 of van derden, evenals schade aan personen, ook als er geen sprake is van opzet. De deelnemer is verplicht om in het bezit te zijn van een geldige aansprakelijkheidsverzekering (WA-verzekering) en wordt geacht deze te hebben afgesloten voor de duur van de activiteit.

### Intellectueel eigendom
- Tijdens de cursus mogen foto's worden gemaakt van eigen gemaakt werk en gedeeld worden op social media, op voorwaarde dat Studio1931 duidelijk wordt vermeld. Houd rekening met medecursisten wanneer het gaat om beeldmateriaal.
- Het is niet de bedoeling om lesmateriaal te verspreiden.
- Tenzij de deelnemer expliciet aangeeft geen toestemming te geven, behoudt Studio1931 het recht om beeldmateriaal te gebruiken voor PR-doeleinden.

### Klachten
- Heb je een klacht over een cursus? Neem dan contact op met Studio1931, en we doen ons best om het probleem op te lossen. Houd er rekening mee dat het indienen van een klacht de betalingsverplichting van de deelnemer niet vervangt.

### Privacy
- Alle informatie rondom privacy en het bewaren van persoonsgegevens, kun je vinden op onze [privacy pagina](/privacy/).
"""
    ]
