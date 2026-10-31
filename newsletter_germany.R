setwd("C:/Users/Janin/Documents/dataprojects/R/newsletter")

library(tidyRSS)
library(tibble)
library(httr2)
library(rvest)
library(lubridate)
library(xml2)
library(usethis)
library(dplyr)
library(htmltools)

# Spiegel-Themen-Seite scrapen und aufbereiten -----------------------------------

## HTML der Spiegel-Themen-Seite laden:
spiegel_seite <- read_html(
  "https://www.spiegel.de/thema/daten-und-visualisierungen/"
)

## HTML-Container der Liste „Alle Beiträge“ auswählen
spiegel_liste <- spiegel_seite |>
  html_element('[data-area="article-teaser-list"]')

## Artikel innerhalb des Containers auswählen
spiegel_artikel <- spiegel_liste|>
  html_elements("article")

## Veröffentlichungsdatum der Artikel extrahieren
spiegel_datum <- spiegel_artikel |>
  html_element("footer span[data-auxiliary]") |>
  html_text2()

## Datumsangaben in Datums-Zeit-Werte umwandeln
spiegel_datum <- as.POSIXct(
  strptime(
    spiegel_datum,
    format = "%d. %B %Y, %H.%M Uhr",
    tz = "Europe/Berlin"
  )
)


################################################# Einschub 

## Stichtag für alle Artikel über alle Redaktion hinweg definieren
stichtag <- Sys.time() - 7 * 24 * 60 * 60

################################################# Ende


## Artikel und Datumsangaben der letzten sieben Tage filtern
spiegel_filter <- spiegel_datum >= stichtag

spiegel_aktuell <- spiegel_artikel[spiegel_filter]
spiegel_datum_aktuell <- spiegel_datum[spiegel_filter]

## Titel auslesen
spiegel_titel <- spiegel_aktuell |>
  html_attr("aria-label")

## Teaser auslesen
spiegel_teaser <- spiegel_aktuell |>
  html_element('[data-target-teaser-el="text"]') |>
  html_text2()

## URL auslesen
spiegel_url <- spiegel_aktuell |>
  html_element("h2 a") |>
  html_attr("href")

spiegel_artikel[[1]] |> 
  html_element("figure source")

## Bildinformationen aller Artikel auslesen
spiegel_bilder <- spiegel_aktuell |>
  html_element("figure source") |>
  html_attr("data-srcset")

spiegel_bilder <- sub(" .*", "", spiegel_bilder)

## Jeweils die erste Bild-URL auswählen
spiegel_bilder <- sub(" .*", "", spiegel_bilder)

## Artikelinformationen in einem Dataframe zusammenführen
spiegel_df <- data.frame(
  quelle = rep("SPIEGEL", length(spiegel_titel)),
  titel = spiegel_titel,
  teaser = spiegel_teaser,
  url = spiegel_url,
  bild_url = spiegel_bilder,
  datum = spiegel_datum_aktuell,
  standort = rep("Hamburg", length(spiegel_titel))
)

# ZEIT-Themen-Feed einlesen und aufbereiten -----------------------------------

## HTML der Zeit-Themen-Seite laden:
zeit_feed <- read_xml(
  "https://newsfeed.zeit.de/daten-und-visualisierung"
)

## Artikel aus zeit_feed extrahieren 
zeit_artikel <- zeit_feed |>
  xml2::xml_find_all("//item")

## Titel der Artikel extrahieren
zeit_titel <- zeit_artikel |>
  xml2::xml_find_first("title") |>
  xml2::xml_text()

## Veröffentlichungsdatum der Artikel extrahieren
zeit_datum <- zeit_artikel |>
  xml2::xml_find_first("pubDate") |>
  xml2::xml_text()

## Spracheinstellung vorübergehend ändern
alte_locale <- Sys.getlocale("LC_TIME")
Sys.setlocale("LC_TIME", "English_United States.utf8")

## Datumsangaben umwandeln
zeit_datum <- as.POSIXct(
  zeit_datum,
  format = "%a, %d %b %Y %H:%M:%S %z",
  tz = "UTC"
)

## Ursprüngliche Spracheinstellung wiederherstellen
Sys.setlocale("LC_TIME", alte_locale)

## Artikel der letzten sieben Tage filtern
zeit_filter <- zeit_datum >= stichtag

zeit_aktuell <- zeit_artikel[zeit_filter]
zeit_datum_aktuell <- zeit_datum[zeit_filter]

## URLs der Artikel extrahieren
zeit_url <- zeit_artikel |>
  xml2::xml_find_first("link") |>
  xml2::xml_text()

## Teaser der Artikel extrahieren
zeit_teaser <- zeit_artikel |>
  xml2::xml_find_first("description") |>
  xml2::xml_text()

## Bild-URLs der Artikel extrahieren
zeit_bild <- zeit_artikel |>
  xml2::xml_find_first("enclosure") |>
  xml2::xml_attr("url")

## Artikel in Dataframe zusammenführen
zeit_df <- data.frame(
  quelle = rep("Zeit", sum(zeit_filter)),
  titel = zeit_titel[zeit_filter],
  teaser = zeit_teaser[zeit_filter],
  url = zeit_url[zeit_filter],
  bild_url = zeit_bild[zeit_filter],
  datum = zeit_datum_aktuell,
  standort = rep("Berlin", sum(zeit_filter))
)

# Morgenpost-Themen-Seite scrapen und aufbereiten -------------------------

## HTML der Morgenpost-Interaktiv-Seite laden
morgenpost_seite <- read_html(
  "https://www.morgenpost.de/interaktiv/"
)

## Alle Artikel auswählen
morgenpost_artikel <- morgenpost_seite |>
  html_elements("article")

## Titel auslesen
morgenpost_titel <- morgenpost_artikel |>
  html_element("h2, h3") |>
  html_text2()

## Teaser auslesen
morgenpost_teaser <- morgenpost_artikel |>
  html_element("div.expressive-copy-base-stable") |>
  html_text2()

## Bild-URLs auslesen
morgenpost_bilder <- morgenpost_artikel |>
  html_element("picture img") |>
  html_attr("src")

## URLs auslesen
morgenpost_urls <- morgenpost_artikel |>
  html_element("a[href]") |>
  html_attr("href")

## Relative URLs vervollständigen
morgenpost_urls <- ifelse(
  is.na(morgenpost_urls),
  NA_character_,
  ifelse(
    grepl("^https?://", morgenpost_urls),
    morgenpost_urls,
    paste0("https://www.morgenpost.de", morgenpost_urls)
  )
)

## Artikel ohne URL ausschließen
morgenpost_gueltig <- !is.na(morgenpost_urls)

morgenpost_urls <- morgenpost_urls[morgenpost_gueltig]
morgenpost_titel <- morgenpost_titel[morgenpost_gueltig]
morgenpost_teaser <- morgenpost_teaser[morgenpost_gueltig]
morgenpost_bilder <- morgenpost_bilder[morgenpost_gueltig]

## Funktion zum Auslesen des Veröffentlichungsdatums
morgenpost_datum_lesen <- function(url) {
  tryCatch({
    
    seite <- read_html(url)
    
    datum <- seite |>
      html_element('meta[name="date"]') |>
      html_attr("content")
    
    as.POSIXct(
      datum,
      format = "%Y-%m-%dT%H:%M:%OSZ",
      tz = "UTC"
    )
    
  }, error = function(e) {
    message("Fehler bei: ", url)
    as.POSIXct(NA, tz = "UTC")
  })
}

## Veröffentlichungsdaten aller Artikel auslesen
morgenpost_datum <- lapply(
  morgenpost_urls,
  morgenpost_datum_lesen
)

## Liste in Datumsvektor umwandeln
morgenpost_datum <- do.call(c, morgenpost_datum)

## Nur Artikel der letzten sieben Tage auswählen
morgenpost_filter <- !is.na(morgenpost_datum) &
  morgenpost_datum >= stichtag

## Aktuelle Artikel herausfiltern
morgenpost_titel_aktuell <- morgenpost_titel[morgenpost_filter]
morgenpost_teaser_aktuell <- morgenpost_teaser[morgenpost_filter]
morgenpost_urls_aktuell <- morgenpost_urls[morgenpost_filter]
morgenpost_datum_aktuell <- morgenpost_datum[morgenpost_filter]
morgenpost_bilder_aktuell <- morgenpost_bilder[morgenpost_filter]

## Dataframe erstellen
morgenpost_df <- data.frame(
  quelle = rep("Morgenpost", length(morgenpost_titel_aktuell)),
  titel = morgenpost_titel_aktuell,
  teaser = morgenpost_teaser_aktuell,
  url = morgenpost_urls_aktuell,
  bild_url = morgenpost_bilder_aktuell,
  datum = morgenpost_datum_aktuell,
  standort = rep("Berlin", length(morgenpost_titel_aktuell))
)

# Tagesspiegel-Themenseite scrapen und aufbereiten ------------------------

## HTML der Tagesspiegel-Themen-Seite laden:
tagesspiegel_seite <- read_html(
  "https://www.tagesspiegel.de/interaktiv/"
)

## Alle Artikel auswählen
tagesspiegel_artikel <- tagesspiegel_seite |>
  html_elements("article")

## Titel auslesen
tagesspiegel_titel <- tagesspiegel_artikel |>
  html_element("h2, h3") |>
  html_text2()

## URL auslesen
tagesspiegel_urls <- tagesspiegel_artikel |>
  html_element("a[href]") |>
  html_attr("href")

## Relative URLs vervollständigen
tagesspiegel_urls <- ifelse(
  grepl("^https?://", tagesspiegel_urls),
  tagesspiegel_urls,
  paste0("https://www.tagesspiegel.de", tagesspiegel_urls)
)

## Doppelte URLs erkennen
tagesspiegel_eindeutig <- !duplicated(tagesspiegel_urls)

## Artikel, Titel und URLs gemeinsam filtern
tagesspiegel_artikel <- tagesspiegel_artikel[tagesspiegel_eindeutig]
tagesspiegel_titel <- tagesspiegel_titel[tagesspiegel_eindeutig]
tagesspiegel_urls <- tagesspiegel_urls[tagesspiegel_eindeutig]

## Teaser auslesen
tagesspiegel_teaser <- tagesspiegel_artikel |>
  html_element('p[data-kilkaya$="-teaser"]') |>
  html_text2()

## Funktion für Datums-Auslese
tagesspiegel_datum_lesen <- function(url) {
  tryCatch({
    
    seite <- read_html(url)
    
    ## 1. Veröffentlichungsdatum aus Meta-Tag
    datum <- seite |>
      html_element('meta[property="article:published_time"]') |>
      html_attr("content")
    
    ## 2. Falls nicht vorhanden: JSON-LD prüfen
    if (is.na(datum)) {
      
      json_text <- seite |>
        html_element('script[type="application/ld+json"]') |>
        html_text2()
      
      if (!is.na(json_text)) {
        json_daten <- jsonlite::fromJSON(json_text)
        datum <- json_daten$datePublished
      }
    }
    
    ## 3. Datum umwandeln
    if (is.null(datum) || length(datum) == 0 || is.na(datum)) {
      return(as.POSIXct(NA, tz = "UTC"))
    }
    
    as.POSIXct(
      datum,
      format = if (nchar(datum) == 10) "%Y-%m-%d"
      else "%Y-%m-%dT%H:%M:%OSZ",
      tz = "UTC"
    )
    
  }, error = function(e) {
    message("Fehler bei: ", url)
    as.POSIXct(NA, tz = "UTC")
  })
}

## Veröffentlichungsdaten aller Artikel auslesen
tagesspiegel_datum <- lapply(
  tagesspiegel_urls,
  tagesspiegel_datum_lesen
)

## Liste in Datums-Vektor umwandeln
tagesspiegel_datum <- do.call(c, tagesspiegel_datum)

## Nur Artikel der letzten sieben Tage
tagesspiegel_filter <- !is.na(tagesspiegel_datum) &
  tagesspiegel_datum >= stichtag &
  tagesspiegel_datum <= Sys.time()

## Aktuelle Artikel auswählen
tagesspiegel_titel_aktuell <- tagesspiegel_titel[tagesspiegel_filter]
tagesspiegel_teaser_aktuell <- tagesspiegel_teaser[tagesspiegel_filter]
tagesspiegel_urls_aktuell <- tagesspiegel_urls[tagesspiegel_filter]
tagesspiegel_datum_aktuell <- tagesspiegel_datum[tagesspiegel_filter]

## Bild-URLs auslesen
tagesspiegel_bilder <- tagesspiegel_artikel |>
  html_element("img") |>
  html_attr("src")

## Relative Bild-URLs vervollständigen
tagesspiegel_bilder <- ifelse(
  is.na(tagesspiegel_bilder),
  NA_character_,
  ifelse(
    grepl("^https?://", tagesspiegel_bilder),
    tagesspiegel_bilder,
    paste0("https://www.tagesspiegel.de", tagesspiegel_bilder)
  )
)

## Bild-URLs der aktuellen Artikel auswählen
tagesspiegel_bilder_aktuell <- tagesspiegel_bilder[tagesspiegel_filter]

## Dataframe erstellen
tagesspiegel_df <- data.frame(
  quelle = rep("Tagesspiegel", length(tagesspiegel_titel_aktuell)),
  titel = tagesspiegel_titel_aktuell,
  teaser = tagesspiegel_teaser_aktuell,
  url = tagesspiegel_urls_aktuell,
  bild_url = tagesspiegel_bilder_aktuell,
  datum = tagesspiegel_datum_aktuell,
  standort = rep("Berlin", length(tagesspiegel_titel_aktuell))
)

# Handelsblatt-Themenseite scrapen und aufbereiten ---------------------

## HTML der Handelsblatt-Themen-Seite laden:
handesblatt_seite <- read_html(
  "https://www.handelsblatt.com/daten-und-visualisierungen/"
)

## Alle Linke einladen
handelsblatt_links <- handesblatt_seite |>
  html_elements("a.list-layout[href]")

## Titel extrahieren
handelsblatt_titel <- handelsblatt_links |>
  html_element("h3") |>
  html_text2()

## Teaser extrahieren
handelsblatt_teaser <- handelsblatt_links |>
  html_element(".teaser-body hmg-rich-text") |>
  html_text2()

## Artikel-URLs extrahieren und vervollständigen
handelsblatt_urls <- handelsblatt_links |>
  html_attr("href") |>
  xml2::url_absolute("https://www.handelsblatt.com")

## Bild-URLs im WebP-Format extrahieren
handelsblatt_bilder <- sapply(handelsblatt_links, function(artikel) {
  
  ## Alle WebP-Bildvarianten auslesen
  bilder <- artikel |>
    html_elements('picture source[type="image/webp"]') |>
    html_attr("srcset") |>
    paste(collapse = ", ") |>
    strsplit(", ") |>
    unlist()
  
  ## Querformat mit 1080 Pixel Breite auswählen
  bild <- grep("/1080/608/", bilder, value = TRUE)
  
  ## Falls kein passendes Bild vorhanden ist
  if (length(bild) == 0) return(NA_character_)
  
  ## Doppelte Treffer entfernen und Breitenangabe abschneiden
  bild <- unique(bild)[1]
  sub(" 1080w$", "", bild)
})

handelsblatt_daten <- sapply(handelsblatt_urls, function(url) {
  
  ## Pause zwischen den Anfragen
  Sys.sleep(3)
  
  ## Artikelseite abrufen
  tryCatch({
    
    seite <- read_html(url)
    
    datum <- seite |>
      html_element('meta[property="article:published_time"]') |>
      html_attr("content")
    
    if (length(datum) == 0) NA_character_ else datum
    
  }, error = function(e) NA_character_)
  
})

## Zeitzonenformat korrigieren
hb_daten_korrigiert <- sub(
  "([+-][0-9]{2}):([0-9]{2})$",
  "\\1\\2",
  unname(handelsblatt_daten)
)

## Datumsformat umwandeln
handelsblatt_datum <- as.POSIXct(
  hb_daten_korrigiert,
  format = "%Y-%m-%dT%H:%M:%S%z"
)

## Ergebnisse auf 7 Tage filtern 
handelsblatt_aktuell <- !is.na(handelsblatt_datum) &
  handelsblatt_datum >= stichtag &
  handelsblatt_datum <= Sys.time()

# Handelsblatt Dataframe erstellen
handelsblatt_df <- data.frame(
  quelle = rep("Handelsblatt", sum(handelsblatt_aktuell)),
  titel = handelsblatt_titel[handelsblatt_aktuell],
  teaser = handelsblatt_teaser[handelsblatt_aktuell],
  url = handelsblatt_urls[handelsblatt_aktuell],
  bild_url = handelsblatt_bilder[handelsblatt_aktuell],
  datum = handelsblatt_datum[handelsblatt_aktuell],
  standort = rep("Düsseldorf", sum(handelsblatt_aktuell))
)


# Alle df zusammenführen --------------------------------------------------

## zusammenbinden
newsletter_df <- rbind(
  zeit_df,
  tagesspiegel_df,
  spiegel_df,
  morgenpost_df,
  handelsblatt_df
)

## in jeder Quelle nach Datum sortieren 
newsletter_df <- newsletter_df[
  order(newsletter_df$quelle, -as.numeric(newsletter_df$datum)),
]

## Zwei df für Haupt- und weitere Artikel anlegen
ist_hauptartikel <- !duplicated(newsletter_df$quelle)

hauptartikel_df <- newsletter_df[ist_hauptartikel, ]
weitere_artikel_df <- newsletter_df[!ist_hauptartikel, ]

## Ergebnis zwischenspeichern
saveRDS(hauptartikel_df, "newsletter_hauptartikel_daten.rds")
saveRDS(weitere_artikel_df, "newsletter_weitere_artikel_daten.rds")

# Artikel für API-Anbindung aufbereiten -----------------------------------

# id anfügen
hauptartikel_df$id <- seq_len(nrow(hauptartikel_df))
weitere_artikel_df$id <- seq_len(nrow(weitere_artikel_df))

# Prompts für API-Anbingung einladen

featured_prompt <- paste(
  readLines("prompts/featured.txt", encoding = "UTF-8"),
  collapse = "\n"
)

bullet_prompt <- paste(
  readLines("prompts/bullets.txt", encoding = "UTF-8"),
  collapse = "\n"
)

themenzeile_prompt <- paste(
  readLines("prompts/themenzeile.txt", encoding = "UTF-8"),
  collapse = "\n"
)

# JSON-Schema für Hauptartikel
featured_schema <- list(
  type = "object",
  properties = list(
    artikel = list(
      type = "array",
      items = list(
        type = "object",
        properties = list(
          id = list(type = "integer"),
          ueberschrift = list(type = "string"),
          teaser = list(type = "string")
        ),
        required = c("id", "ueberschrift", "teaser"),
        additionalProperties = FALSE
      )
    )
  ),
  required = c("artikel"),
  additionalProperties = FALSE
)

# JSON-Schema für Bulletpoint

bullet_schema <- list(
  type = "object",
  properties = list(
    artikel = list(
      type = "array",
      items = list(
        type = "object",
        properties = list(
          id = list(type = "integer"),
          bullet = list(type = "string")
        ),
        required = c("id", "bullet"),
        additionalProperties = FALSE
      )
    )
  ),
  required = c("artikel"),
  additionalProperties = FALSE
)

# JSON-Schema für Themenzeile

themenzeile_schema <- list(
  type = "object",
  properties = list(
    themenzeile = list(type = "string")
  ),
  required = c("themenzeile"),
  additionalProperties = FALSE
)

# API-Anbindung -----------------------------------------------------------
# Allgemeine Funktion für API-Anfragen---------------------------------------

api_anfrage <- function(prompt, llm_input) {
  # Prompt und Artikelinformationen zusammenfügen
  eingabe <- paste(
    prompt,
    llm_input,
    sep = "\n\n"
  )
  
  # API-Anfrage senden
  antwort <- httr2::request(
    "https://api.openai.com/v1/responses"
  ) |>
    httr2::req_auth_bearer_token(
      Sys.getenv("OPENAI_API_KEY")
    ) |>
    httr2::req_body_json(
      list(
        model = "gpt-5.4",
        input = eingabe
      )
    ) |>
    httr2::req_perform()
  
  # Antwort auslesen
  ergebnis <- httr2::resp_body_json(antwort)
  
  # Text aus den Ausgabeelementen zusammensetzen
  texte <- character()
  
  for (element in ergebnis$output) {
    
    if (!is.null(element$content)) {
      
      for (inhalt in element$content) {
        
        if (
          identical(inhalt$type, "output_text") &&
          !is.null(inhalt$text)
        ) {
          texte <- c(texte, inhalt$text)
        }
        
      }
    }
  }
  
  # Prüfen, ob Text zurückgegeben wurde
  if (length(texte) == 0) {
    stop("Die API hat keinen auslesbaren Text zurückgegeben.")
  }
  
  return(trimws(paste(texte, collapse = "\n")))
}


# Erstellt aus einer Dataframe-Zeile den Input für das Modell
artikel_input <- function(artikel) {
  
  paste0(
    "Originaltitel: ", artikel$titel,
    "\nOriginal-Teaser: ", artikel$teaser
  )
}

# Funktion für Hauptartikel -----------------------------------------------
erstelle_featured <- function(artikel) {
  # Artikelinformationen vorbereiten
  llm_input <- artikel_input(artikel)
  # API aufrufen
  text <- api_anfrage(
    featured_prompt,
    llm_input
  )
  # Überschrift und Teaser auslesen
  zeilen <- strsplit(text, "\n")[[1]]
  ueberschrift <- grep(
    "^UEBERSCHRIFT:",
    zeilen,
    value = TRUE
  )
  teaser <- grep(
    "^TEASER:",
    zeilen,
    value = TRUE
  )
  
  # Prüfen, ob beide Bestandteile vorhanden sind
  if (length(ueberschrift) != 1 || length(teaser) != 1) {
    stop(
      "Die Featured-Antwort hat nicht das erwartete Format:\n",
      text
    )
  }
  
  # Kennzeichnungen entfernen
  ueberschrift <- trimws(
    sub("^UEBERSCHRIFT:\\s*", "", ueberschrift)
  )
  teaser <- trimws(
    sub("^TEASER:\\s*", "", teaser)
  )
  
  # Leere Texte abfangen
  if (!nzchar(ueberschrift) || !nzchar(teaser)) {
    stop("Überschrift oder Teaser ist leer.")
  }
  
  # Ergebnis zurückgeben
  return(
    data.frame(
      ueberschrift = ueberschrift,
      teaser_ki = teaser,
      stringsAsFactors = FALSE
    )
  )
  
}
# Funktion für Bulletpoints -----------------------------------------------

erstelle_bullet <- function(artikel) {
  # Artikelinformationen vorbereiten
  llm_input <- artikel_input(artikel)
  # API aufrufen
  text <- api_anfrage(
    bullet_prompt,
    llm_input
  )
  # Kennzeichnung entfernen
  bullet <- trimws(
    sub("^BULLET:\\s*", "", text)
  )
  # Prüfen, ob ein Text vorhanden ist
  if (!nzchar(bullet)) {
    stop("Der Bulletpoint ist leer.")
  }
  return(bullet)
}

## Funktion für Themenzeile ------------------------------------------------
erstelle_themenzeile <- function(artikel_df) {
  
  # Alle Hauptartikel zusammenführen
  artikel_liste <- character(nrow(artikel_df))
  for (i in seq_len(nrow(artikel_df))) {
    artikel_liste[i] <- paste0(
      "Artikel ", i, ":\n",
      artikel_input(artikel_df[i, , drop = FALSE])
    )
  }
  
  llm_input <- paste(
    artikel_liste,
    collapse = "\n\n"
  )
  
  # API aufrufen
  themenzeile <- api_anfrage(
    themenzeile_prompt,
    llm_input
  )
  return(trimws(themenzeile))
}
# Newsletter-Texte generieren ---------------------------------------------

# 1. Hauptartikel: Überschriften und Teaser erstellen

featured_ergebnisse <- lapply(
  seq_len(nrow(hauptartikel_df)),
  function(i) {
    erstelle_featured(hauptartikel_df[i, , drop = FALSE])
  }
)

featured_ergebnisse <- do.call(
  rbind,
  featured_ergebnisse
)

# Generierte Texte zum Dataframe hinzufügen
hauptartikel_df$ueberschrift_ki <- featured_ergebnisse$ueberschrift
hauptartikel_df$teaser_ki <- featured_ergebnisse$teaser_ki


# 2. Weitere Artikel: Bulletpoints erstellen

weitere_artikel_df$bullet_ki <- vapply(
  seq_len(nrow(weitere_artikel_df)),
  function(i) {
    erstelle_bullet(weitere_artikel_df[i, , drop = FALSE])
  },
  character(1)
)


# 3. Themenzeile für die gesamte Ausgabe erstellen

themenzeile <- erstelle_themenzeile(hauptartikel_df)


# 4. Ergebnisse speichern -------------------------------------------------

saveRDS(
  list(
    hauptartikel = hauptartikel_df,
    weitere_artikel = weitere_artikel_df,
    themenzeile = themenzeile
  ),
  file = "newsletter_texte.rds"
)




# Daten für das HTML zusammenführen -------------------------------------
hauptartikel_html <- hauptartikel_df |>
  mutate(
    artikel_typ = "featured",
    bullet_ki = NA_character_
  )

weitere_artikel_html <- weitere_artikel_df |>
  mutate(
    artikel_typ = "weitere",
    ueberschrift_ki = NA_character_,
    teaser_ki = NA_character_
  )

newsletter_inhalt <- bind_rows(
  hauptartikel_html,
  weitere_artikel_html
)

# HTML-Sonderzeichen maskieren

html_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  htmltools::htmlEscape(x)
}

# Metadaten berechnen

anzahl_projekte <- nrow(newsletter_inhalt)
anzahl_redaktionen <- n_distinct(newsletter_inhalt$quelle)
anzahl_standorte <- n_distinct(newsletter_inhalt$standort, na.rm = TRUE)

meta_zeile <- paste(
  anzahl_projekte, "Projekte ·",
  anzahl_redaktionen, "Redaktionen ·",
  anzahl_standorte, "Standorte"
)

# Newsletter-Kopf

ausgabe_nummer <- 1

newsletter_kopf <- paste0(
  "<div class='newsletter-header'>",
  "<h1>UPDATA</h1>",
  
  "<div class='logo-line'>
    <svg width='175' height='45' viewBox='0 0 175 45'>
      <path d='
        M0,35 L25,32 L50,18 L75,24
        L100,30 L125,14 L150,20 L175,2
        L175,45 L0,45 Z'
        fill='#d9dde3'/>
    </svg>
  </div>",
  
  "<h2>Datenjournalismus aus Deutschland</h2>",
  "<p><strong>", html_text(meta_zeile), "</strong></p>",
  "</div>",
  
  "<hr>",
  
  "<p>Willkommen zur ", ausgabe_nummer,
  ". Ausgabe von UPDATA – einem experimentellen KI-Newsletter.</p>",
  
  "<p>Jeden Montag erhältst du hier einen Überblick über aktuelle ",
  "Datenprojekte, Visualisierungen und Recherchen deutscher Redaktionen.</p>",
  
  "<p>", html_text(themenzeile), "</p>",
  "<p>Viel Spaß beim Lesen!</p>"
)

# Newsletter-Schluss

newsletter_schluss <- paste0(
  "<hr>",
  "<p>Das war UPDATA für diese Woche!</p>",
  "<p>Nächsten Montag gibt es wieder neue Datenprojekte, ",
  "Visualisierungen und Recherchen aus deutschen Redaktionen.</p>",
  "<p><em>Als experimenteller Newsletter sammelt, sortiert und ",
  "verarbeitet UPDATA die Inhalte dieser Ausgabe automatisiert ",
  "mithilfe künstlicher Intelligenz.</em></p>"
)

# Standorte festlegen

standort_reihenfolge <- c(
  "Berlin",
  "Hamburg",
  "Düsseldorf"
)

# Weitere Standorte automatisch ergänzen

weitere_standorte <- setdiff(
  unique(newsletter_inhalt$standort),
  standort_reihenfolge
)

weitere_standorte <- weitere_standorte[
  !is.na(weitere_standorte) &
    nzchar(weitere_standorte)
]

standort_reihenfolge <- c(
  standort_reihenfolge,
  weitere_standorte
)

# Quellenblock erstellen

erstelle_quellenblock <- function(daten, quelle_name, standort_name) {
  
  quellen_daten <- daten |>
    filter(
      quelle == quelle_name,
      standort == standort_name
    )
  
  featured <- quellen_daten |>
    filter(artikel_typ == "featured")
  
  bullets <- quellen_daten |>
    filter(artikel_typ == "weitere")
  
  if (nrow(featured) == 0) {
    return("")
  }
  
  featured <- featured[1, , drop = FALSE]
  
  # Weitere Artikel als Liste
  
  weitere_html <- ""
  
  if (nrow(bullets) > 0) {
    
    bullet_eintraege <- paste0(
      "<li><a href='",
      html_text(bullets$url),
      "'>",
      html_text(bullets$bullet_ki),
      "</a></li>"
    )
    
    weitere_html <- paste0(
      "<h4>Weitere Artikel</h4>",
      "<ul>",
      paste(bullet_eintraege, collapse = "\n"),
      "</ul>"
    )
  }
  
  # Bild des Hauptartikels
  
  bild_html <- ""
  
  if (
    !is.na(featured$bild_url[1]) &&
    nzchar(featured$bild_url[1])
  ) {
    
    bild_html <- paste0(
      "<img src='",
      html_text(featured$bild_url[1]),
      "' class='featured-image'>"
    )
  }
  
  # Vollständiger Quellenblock
  
  paste0(
    "<h3>", html_text(quelle_name), "</h3>",
    
    "<h4><a href='",
    html_text(featured$url[1]),
    "'>",
    html_text(featured$ueberschrift_ki[1]),
    "</a></h4>",
    
    "<p>",
    html_text(featured$teaser_ki[1]),
    "</p>",
    
    bild_html,
    weitere_html
  )
}

# Standortblock erstellen

erstelle_standortblock <- function(daten, standort_name) {
  
  quellen <- daten |>
    filter(standort == standort_name) |>
    distinct(quelle) |>
    pull(quelle)
  
  if (length(quellen) == 0) {
    return("")
  }
  
  quellenbloecke <- vapply(
    quellen,
    function(q) {
      erstelle_quellenblock(daten, q, standort_name)
    },
    character(1)
  )
  
  quellenbloecke <- quellenbloecke[nzchar(quellenbloecke)]
  
  if (length(quellenbloecke) == 0) {
    return("")
  }
  
  paste0(
    "<h2 class='standort'>",
    html_text(standort_name),
    "</h2>",
    paste(quellenbloecke, collapse = "\n")
  )
}

# Newsletter-Body erstellen

standortbloecke <- vapply(
  standort_reihenfolge,
  function(s) {
    erstelle_standortblock(newsletter_inhalt, s)
  },
  character(1)
)

newsletter_body <- paste(
  standortbloecke[nzchar(standortbloecke)],
  collapse = "\n\n"
)

# CSS

newsletter_css <- "
<style>

body {
  background-color: #f4f5f7;
  margin: 0;
  padding: 40px 20px;
  }

.newsletter-container {
  font-family: Georgia, serif;
  font-size: 15px;
  color: #000000;
  background-color: #ffffff;
  line-height: 1.6;
  max-width: 800px;
  margin: 0 auto;
  padding: 50px;
}

.featured-image {
  width: 100%;
  height: auto;
  display: block;
  margin-bottom: 12px;
  border-radius: 4px;
}

.newsletter-header {
  text-align: center;
  margin-bottom: 30px;
}

.logo-line {
  display: flex;
  justify-content: center;
  margin-top: -8px;
  margin-bottom: 2px;
}

h1, h2, h3, h4 {
  font-family: Georgia, serif;
}

h1 {
  font-size: 38px;
  font-weight: 600;
  margin-bottom: 10px;
}

h2 {
  font-size: 26px;
  font-weight: 600;
  margin-top: 45px;
  margin-bottom: 20px;
}

.standort {
  padding-bottom: 6px;
  border-bottom: 1px solid #000000;
}

h3 {
  font-size: 22px;
  font-weight: 600;
  margin-top: 35px;
  margin-bottom: 10px;
}

h4 {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 10px;
  line-height: 1.4;
}

p {
  margin-bottom: 15px;
}

ul {
  margin-bottom: 25px;
}

li {
  margin-bottom: 8px;
}

a {
  color: #000000;
  text-decoration: underline;
}

a:hover {
  text-decoration: underline;
}

hr {
  margin-top: 20px;
  margin-bottom: 40px;
}

</style>
"

# Vollständiges HTML erzeugen

newsletter_html <- paste0(
  "<!DOCTYPE html>",
  "<html lang='de'>",
  "<head>",
  "<meta charset='UTF-8'>",
  "<meta name='viewport' content='width=device-width, initial-scale=1.0'>",
  "<title>UPDATA – Ausgabe ", ausgabe_nummer, "</title>",
  newsletter_css,
  "</head>",
  "<body>",
  "<div class='newsletter-container'>",
  newsletter_kopf,
  newsletter_body,
  newsletter_schluss,
  "</div>",
  "</body>",
  "</html>"
)

# HTML speichern und im Browser öffnen

writeLines(
  newsletter_html,
  "newsletter_updata.html",
  useBytes = TRUE
)

browseURL(normalizePath("newsletter_updata.html"))

