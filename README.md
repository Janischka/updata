# UPDATA – Ein automatisierter Datenjournalismus-Newsletter

UPDATA ist ein kleines Projekt, das ich entwickelt habe, um meine Kenntnisse in R zu vertiefen und erste Erfahrungen mit Web-Scraping und der Anbindung einer KI-API zu sammeln.

Die Idee: Ein Newsletter, der aktuelle datenjournalistische Veröffentlichungen deutscher Nachrichtenmedien sammelt und übersichtlich zusammenstellt.

Dafür habe ich eine Pipeline in R aufgebaut, die Artikeldaten abruft, verarbeitet und mithilfe der OpenAI API kurze Newsletter-Texte erstellt. Am Ende entsteht eine HTML-Datei mit dem fertigen Newsletter.

Das Projekt ist ein **Prototyp**, kein veröffentlichungsfertiges journalistisches Produkt.

## Welche Medien werden berücksichtigt?

Aktuell umfasst UPDATA fünf deutsche Nachrichtenmedien:

* DER SPIEGEL
* DIE ZEIT
* Berliner Morgenpost
* Der Tagesspiegel
* Handelsblatt

Der Newsletter berücksichtigt Veröffentlichungen der vergangenen sieben Tage. Die Artikel werden nach den Standorten der Redaktionen gruppiert.

## Wie funktioniert UPDATA?

Die Erstellung des Newsletters besteht aus vier Schritten.

### 1. Artikel sammeln

Mit R rufe ich die Daten- und Visualisierungsseiten der ausgewählten Medien ab.

Bei vier Medien nutze ich dafür Web-Scraping. Die Artikel der ZEIT werden über einen RSS-Feed eingelesen.

Aus den Quellen lese ich unter anderem die Titel, Teaser, Veröffentlichungsdaten und Links der Artikel aus. Wenn verfügbar, werden auch Bild-URLs erfasst.

### 2. Daten aufbereiten

Die gesammelten Informationen werden in R als Tabellen zusammengeführt.

Anschließend werden Veröffentlichungen herausgefiltert, die älter als sieben Tage sind. Pro Redaktion wird ein Hauptartikel ausgewählt. Weitere Artikel werden später als kurze Meldungen dargestellt.

### 3. Texte mit KI erstellen

Für die Newsletter-Texte verwende ich die OpenAI API.

Das Sprachmodell erhält die gesammelten Artikelinformationen und erstellt daraus:

* Überschriften und Teaser für die Hauptartikel
* kurze Zusammenfassungen für weitere Artikel
* einen Einleitungssatz mit den Themen der Ausgabe

Dafür habe ich drei unterschiedliche Prompts angelegt, die im Ordner `prompts` liegen.

Die KI arbeitet mit den übergebenen Artikelinformationen. Sie überprüft nicht selbstständig, ob die Inhalte richtig sind.

### 4. Newsletter als HTML erstellen

Im letzten Schritt werden die Artikel und die generierten Texte in eine HTML-Vorlage eingefügt.

Das Layout habe ich mit HTML und CSS gestaltet. Der fertige Newsletter kann anschließend im Browser geöffnet werden.

## Verwendete Technologien

* **R:** Artikel sammeln, Daten aufbereiten und HTML erzeugen
* **rvest und xml2:** Informationen aus Webseiten und einem RSS-Feed auslesen
* **OpenAI API:** Newsletter-Texte generieren
* **HTML und CSS:** Newsletter gestalten
* **Git und GitHub:** Projektversionen verwalten und den Code dokumentieren

## Was ich dabei gelernt habe

UPDATA ist vor allem ein Lernprojekt.

Ich konnte dabei meine bisherigen R-Kenntnisse anwenden und mich mit einigen für mich neuen Aufgaben beschäftigen:

* Informationen automatisiert aus Webseiten und RSS-Feeds auslesen
* unterschiedliche Datenquellen in einer gemeinsamen Struktur zusammenführen
* Veröffentlichungen anhand ihres Datums filtern
* eine API aus R ansprechen
* Prompts für unterschiedliche Textformate entwickeln
* Daten und Texte automatisiert in eine HTML-Vorlage einsetzen

**Bei der Entwicklung habe ich ChatGPT als Programmierhilfe genutzt**, beispielsweise um Fehler zu finden, Funktionen zu verstehen und Lösungen für einzelne technische Probleme zu erarbeiten. Das Projekt ist also auch ein Versuch, mir neue Programmierkenntnisse mithilfe von KI anzueignen.

## Grenzen des Projekts

UPDATA ist bisher ein Prototyp mit einigen Einschränkungen.

**Datenerhebung:** Die Erfassung der Artikel hängt von den Webseiten und RSS-Feeds der Medien ab. Wenn sich eine Webseitenstruktur ändert, kann das Scraping nicht mehr funktionieren. Außerdem werden möglicherweise nicht alle relevanten Veröffentlichungen erfasst.

**KI-generierte Texte:** Die Texte werden auf Grundlage der gesammelten Artikelinformationen erstellt. Dabei können Fehler oder Ungenauigkeiten entstehen. Vor einer journalistischen Veröffentlichung müssten die Texte deshalb redaktionell geprüft werden.

**Bildrechte:** Der Newsletter bindet Bild-URLs aus den Originalveröffentlichungen ein. Vor einer öffentlichen Verbreitung muss geklärt werden, ob diese Bilder verwendet werden dürfen. Die Bilder sind derzeit nur für die interne Erprobung vorgesehen.

**Veröffentlichung:** Der Newsletter wird bislang als HTML-Datei erzeugt. Ein automatischer E-Mail-Versand ist nicht umgesetzt.

## Projektstatus

**Prototyp – Oktober 2026**

Die grundlegende Pipeline von der Artikelerfassung bis zur HTML-Ausgabe ist umgesetzt.

UPDATA ist noch nicht für einen regelmäßigen, unbeaufsichtigten Betrieb ausgelegt.
