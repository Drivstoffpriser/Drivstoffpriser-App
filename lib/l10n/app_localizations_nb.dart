// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get appTitle => 'Drivstoffpriser';

  @override
  String get navMap => 'Kart';

  @override
  String get navStations => 'Stasjoner';

  @override
  String get navProfile => 'Profil';

  @override
  String get searchStations => 'Søk stasjoner...';

  @override
  String noStationsFound(String query) {
    return 'Ingen stasjoner funnet for «$query»';
  }

  @override
  String get bestNearby => 'Beste i nærheten';

  @override
  String get sortCheapest => 'Billigst';

  @override
  String get sortNearest => 'Nærmest';

  @override
  String get sortLatest => 'Nyligst';

  @override
  String sortLabel(String mode) {
    return 'Sorter: $mode';
  }

  @override
  String get noPricesReported => 'Ingen priser rapportert ennå';

  @override
  String get allOfNorway => 'Hele Norge';

  @override
  String get searchRadius => 'Søkeradius';

  @override
  String get filterByBrand => 'Filtrer etter merke';

  @override
  String get showFavoritesOnly => 'Vis kun favoritter';

  @override
  String get allowMapRotation => 'Tillat kartrotasjon';

  @override
  String get clearAll => 'Fjern alle';

  @override
  String get favorites => 'Favoritter';

  @override
  String get navigate => 'Naviger';

  @override
  String get currentPrices => 'GJELDENDE PRISER';

  @override
  String get priceTrend => 'PRISTREND (30 DAGER)';

  @override
  String get reportAPrice => 'Rapporter pris';

  @override
  String get recentReports => 'SISTE RAPPORTER';

  @override
  String get noReportsYet => 'Ingen rapporter ennå.';

  @override
  String get krSuffix => 'kr';

  @override
  String krPerUnit(String unit) {
    return 'kr/$unit';
  }

  @override
  String reportsCount(int count) {
    return '$count rapporter';
  }

  @override
  String stationsCount(int count) {
    return '$count stasjoner';
  }

  @override
  String get profile => 'Profil';

  @override
  String get totalContributions => 'Totale bidrag';

  @override
  String get priceReportsSubmitted => 'prisrapporter';

  @override
  String get trustScore => 'Tillitsscore';

  @override
  String get createAccount => 'Opprett konto';

  @override
  String get signUpSubtitle =>
      'Registrer deg for å rapportere priser og oppnå tillit';

  @override
  String get mapPreferences => 'KARTINNSTILLINGER';

  @override
  String get appearance => 'Utseende';

  @override
  String get themeDark => 'Mørk';

  @override
  String get themeLight => 'Lys';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'Språk';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageNorwegian => 'Norsk';

  @override
  String get refreshStations => 'Oppdater stasjoner';

  @override
  String get updateNearbyStations => 'Oppdater nærliggende stasjoner';

  @override
  String get stationsRefreshed => 'Stasjoner oppdatert';

  @override
  String get refreshFailed => 'Kunne ikke oppdatere stasjoner. Prøv igjen.';

  @override
  String get support => 'STØTTE';

  @override
  String get reportABug => 'Rapporter en feil';

  @override
  String get foundIssue => 'Fant du et problem? Gi oss beskjed';

  @override
  String get about => 'Om';

  @override
  String get aboutDescription =>
      'Fellesskapsdrevet drivstoffprissporer for Norge. Rapporter og finn de billigste drivstoffprisene i nærheten.';

  @override
  String get viewOnGithub => 'Se på GitHub';

  @override
  String get privacyPolicy => 'Personvernerklæring';

  @override
  String get privacyPolicySubtitle => 'Hvordan vi håndterer dataene dine';

  @override
  String get account => 'KONTO';

  @override
  String get deleteAccount => 'Slett konto';

  @override
  String get deleteAccountSubtitle => 'Slett kontoen og dataene dine permanent';

  @override
  String get deleteAccountConfirmTitle => 'Slette konto?';

  @override
  String get deleteAccountConfirmBody =>
      'Dette vil permanent slette kontoen din og profildata. Dine innsendte prisrapporter vil forbli som anonyme fellesskapsdata.\n\nDenne handlingen kan ikke angres.';

  @override
  String get deleteAccountConfirmButton => 'Slett konto';

  @override
  String get accountDeleted => 'Kontoen er slettet';

  @override
  String get deleteAccountReauth =>
      'Av sikkerhetsgrunner, logg ut og logg inn igjen før du sletter kontoen din';

  @override
  String get signOut => 'Logg ut';

  @override
  String get signOutSubtitle => 'Logg ut av kontoen din';

  @override
  String get guestUser => 'Gjest';

  @override
  String get reports => 'rapporter';

  @override
  String get trust => 'tillit';

  @override
  String get signIn => 'Logg inn';

  @override
  String get continueWithGoogle => 'Fortsett med Google';

  @override
  String get or => 'ELLER';

  @override
  String get displayName => 'Visningsnavn';

  @override
  String get enterYourName => 'Vennligst skriv inn navnet ditt';

  @override
  String get email => 'E-post';

  @override
  String get enterYourEmail => 'Vennligst skriv inn e-posten din';

  @override
  String get enterValidEmail => 'Vennligst skriv inn en gyldig e-postadresse';

  @override
  String get password => 'Passord';

  @override
  String get enterYourPassword => 'Vennligst skriv inn passordet ditt';

  @override
  String get passwordMinLength => 'Passordet må være minst 6 tegn';

  @override
  String get createAccountSubtitle => 'Spor priser og hjelp fellesskapet.';

  @override
  String get signInSubtitle => 'Velkommen tilbake.';

  @override
  String get alreadyHaveAccountPrefix => 'Har du allerede en konto? ';

  @override
  String get needAccountPrefix => 'Trenger du en konto? ';

  @override
  String get alreadyHaveAccount => 'Har du allerede en konto? Logg inn';

  @override
  String get needAccount => 'Trenger du en konto? Opprett en';

  @override
  String get forgotPassword => 'Glemt passord?';

  @override
  String get passwordResetSent =>
      'Hvis det finnes en konto for denne e-postadressen, vil du motta en e-post for tilbakestilling av passord.';

  @override
  String get errorEmailInUse =>
      'Denne e-posten er allerede registrert. Prøv å logge inn i stedet.';

  @override
  String get errorInvalidEmail =>
      'Vennligst skriv inn en gyldig e-postadresse.';

  @override
  String get errorWeakPassword => 'Passordet må være minst 6 tegn.';

  @override
  String get errorUserNotFound => 'Ingen konto funnet med denne e-posten.';

  @override
  String get errorWrongPassword => 'Feil e-post eller passord.';

  @override
  String get errorCredentialInUse =>
      'Denne legitimasjonen er allerede knyttet til en annen konto.';

  @override
  String get errorUserDisabled => 'Denne kontoen er deaktivert.';

  @override
  String get errorTooManyRequests =>
      'For mange forsøk. Vent litt og prøv igjen.';

  @override
  String get errorNetworkRequestFailed =>
      'Nettverksfeil. Sjekk tilkoblingen og prøv igjen.';

  @override
  String errorAuthFailed(String code) {
    return 'Autentisering mislyktes: $code';
  }

  @override
  String get reportPrice => 'Rapporter pris';

  @override
  String get enterPricesInstruction => 'Skriv inn priser (fyll inn det du vet)';

  @override
  String get submitReport => 'Send rapport';

  @override
  String get couldNotRecognizePrices =>
      'Kunne ikke gjenkjenne noen drivstoffpriser';

  @override
  String filledPricesFromScan(int count) {
    return 'Fylte inn $count pris(er) fra skanning';
  }

  @override
  String get locationUnavailable =>
      'Plassering utilgjengelig. Aktiver posisjonstjenester eller skann et bilde for å rapportere eksternt.';

  @override
  String mustBeNearStation(int distance, int actual) {
    return 'Du må være innenfor ${distance}m fra stasjonen for å rapportere priser. Du er ${actual}m unna.';
  }

  @override
  String get enterAtLeastOnePrice => 'Skriv inn minst én drivstoffpris.';

  @override
  String get needAccountToReport =>
      'Du trenger en konto for å rapportere priser.';

  @override
  String get allOnCooldown =>
      'Alle valgte drivstofftyper er på nedkjøling. Prøv igjen senere.';

  @override
  String get confirmPriceSubmission => 'Bekreft prisrapport';

  @override
  String confirmSubmissionBody(String fuelTypes) {
    return 'Sender inn priser for: $fuelTypes.\n\nEtter innsending kan du ikke oppdatere disse på en stund.';
  }

  @override
  String get doNotShowAgain => 'Ikke vis dette igjen';

  @override
  String get cancel => 'Avbryt';

  @override
  String get submit => 'Send inn';

  @override
  String pricesReported(int count) {
    return '$count pris(er) rapportert';
  }

  @override
  String skippedCooldown(int count) {
    return '$count hoppet over (nedkjøling)';
  }

  @override
  String get someSubmissionsFailed => 'Noen innsendinger mislyktes';

  @override
  String get analyzing => 'Analyserer...';

  @override
  String get scanPriceSign => 'Skann prisskilt';

  @override
  String get cropTip => 'Beskjæringstips';

  @override
  String get cropTipBody =>
      'Etter å ha tatt eller valgt et bilde, blir du bedt om å beskjære det. Prøv å bare inkludere drivstoffprisdelen av skiltet for best resultat.';

  @override
  String get dontShowAgain => 'Ikke vis igjen';

  @override
  String get gotIt => 'Forstått';

  @override
  String get takePhoto => 'Ta bilde';

  @override
  String get chooseFromGallery => 'Galleri';

  @override
  String get cameraPermissionRequired => 'Kameratillatelse kreves';

  @override
  String get failedToProcessImage => 'Kunne ikke behandle bildet';

  @override
  String get verifyPrices => 'Bekreft priser';

  @override
  String get pleaseDoubleCheck => 'Vennligst dobbeltsjekk prisene';

  @override
  String get krPerL => 'kr/L';

  @override
  String get retake => 'Ta nytt bilde';

  @override
  String get confirm => 'Bekreft';

  @override
  String get selectPriceSign => 'Velg prisskilt';

  @override
  String get done => 'Ferdig';

  @override
  String get dragToSelect => 'Dra for å velge området med drivstoffpriser';

  @override
  String cropFailed(String cause) {
    return 'Beskjæring mislyktes: $cause';
  }

  @override
  String get priceRange => 'Område: 10–40 kr';

  @override
  String get enterAPrice => 'Skriv inn en pris';

  @override
  String get invalidNumber => 'Ugyldig tall';

  @override
  String get priceMustBeBetween => 'Prisen må være mellom 10 og 40 kr';

  @override
  String get bugReportTitle => 'Rapporter en feil';

  @override
  String get bugReportIntro =>
      'Fant du et problem? Gi oss detaljene, så ser vi på det.';

  @override
  String get title => 'Tittel';

  @override
  String get briefSummary => 'Kort oppsummering av problemet';

  @override
  String get pleaseEnterTitle => 'Vennligst skriv inn en tittel';

  @override
  String get description => 'Beskrivelse';

  @override
  String get whatHappened => 'Hva skjedde? Hvordan kan vi gjenskape det?';

  @override
  String get pleaseEnterDescription => 'Vennligst skriv inn en beskrivelse';

  @override
  String get submitReportButton => 'Send rapport';

  @override
  String get technicalInfo =>
      'Teknisk informasjon om enheten din og appversjonen vil bli inkludert automatisk.';

  @override
  String get bugReportSubmitted => 'Feilrapport sendt. Takk!';

  @override
  String bugReportFailed(String error) {
    return 'Kunne ikke sende rapport: $error';
  }

  @override
  String get noInternetTitle => 'Ingen internettilkobling';

  @override
  String get noInternetBody =>
      'Drivstoffpriser krever en aktiv Wi-Fi- eller mobildatatilkobling for å vise drivstoffpriser og stasjonsdata.';

  @override
  String get stillNoConnection => 'Fortsatt ingen tilkobling';

  @override
  String get tryAgain => 'Prøv igjen';

  @override
  String get retry => 'Prøv igjen';

  @override
  String get fuelPetrol95 => 'Bensin 95';

  @override
  String get fuelPetrol98 => 'Bensin 98';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get anonymous => 'Anonym';

  @override
  String get anonymousBrowsingOnly => 'Anonym (kun visning)';

  @override
  String get googleEmailAccount => 'Google + E-postkonto';

  @override
  String get googleAccount => 'Google-konto';

  @override
  String get emailAccount => 'E-postkonto';

  @override
  String get emailConfirmed => 'E-post bekreftet';

  @override
  String get contributeData => 'BIDRA MED DATA';

  @override
  String get station => 'Stasjon';

  @override
  String get fuelType => 'Drivstofftype';

  @override
  String get price => 'Pris';

  @override
  String get selectStation => 'Velg en stasjon';

  @override
  String get chooseStationSubtitle =>
      'Velg stasjonen der du vil rapportere en pris';

  @override
  String get selectFuelGrade => 'Velg drivstofftype';

  @override
  String get whatFuelType => 'Hvilken type drivstoff rapporterer du?';

  @override
  String get enterPrice => 'Skriv inn pris';

  @override
  String currentAvg(String price) {
    return 'Nåv. snitt: $price kr';
  }

  @override
  String get nok => 'NOK';

  @override
  String get perL => 'per L';

  @override
  String get verifyAndSubmit => 'Bekreft og send';

  @override
  String get createPriceAlert => 'Opprett prisvarsel';

  @override
  String targetPrice(String symbol) {
    return 'Målpris ($symbol)';
  }

  @override
  String get egPrice => 'f.eks. 20,50';

  @override
  String get enterTargetPrice => 'Skriv inn en målpris';

  @override
  String priceBetween(String symbol) {
    return 'Prisen må være mellom 5 og 50 $symbol';
  }

  @override
  String get anyStation => 'Alle stasjoner';

  @override
  String get maxDistance => 'Maks avstand';

  @override
  String get myAlerts => 'Mine varsler';

  @override
  String get create => 'Opprett';

  @override
  String get priceAlertCreated => 'Prisvarsel opprettet';

  @override
  String get noAlertsYet => 'Ingen varsler ennå';

  @override
  String ageMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String ageHours(int hours) {
    return '${hours}t';
  }

  @override
  String get ageOver1Day => '>1d';

  @override
  String distanceMeters(String meters) {
    return '$meters m';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String get addStationHintTitle => 'Legg til en manglende stasjon';

  @override
  String get addStationHintBody =>
      'Trykk og hold på kartet der du ønsker å legge til en ny stasjon.';

  @override
  String get addStation => 'Legg til stasjon';

  @override
  String get addStationTapMap =>
      'Trykk på kartet for å angi stasjonens plassering';

  @override
  String get addStationName => 'Stasjonsnavn';

  @override
  String get addStationNameHint => 'f.eks. Shell Storo';

  @override
  String get addStationNameRequired => 'Vennligst skriv inn et stasjonsnavn';

  @override
  String get addStationBrand => 'Merke';

  @override
  String get addStationSelectBrand => 'Vennligst velg et merke';

  @override
  String get addStationNoChain => 'Annet / Ingen kjede';

  @override
  String get addStationCustomBrand => 'Merkenavn';

  @override
  String get addStationCustomBrandHint => 'f.eks. Lokal Bensin';

  @override
  String get addStationBrandRequired => 'Vennligst skriv inn et merkenavn';

  @override
  String get stationLogo => 'Stasjonslogo';

  @override
  String get logoHint =>
      'Valgfritt — gjelder for alle stasjoner med dette merket';

  @override
  String get uploadLogo => 'Last opp logo';

  @override
  String get changeLogo => 'Endre logo';

  @override
  String get removeLogo => 'Fjern logo';

  @override
  String get proposedLogo => 'Foreslått logo';

  @override
  String logoAppliesToBrand(String brand) {
    return 'Gjelder for alle «$brand»-stasjoner';
  }

  @override
  String get addStationAddress => 'Adresse';

  @override
  String get addStationAddressHint => 'f.eks. Storgata 1';

  @override
  String get addStationAddressRequired => 'Vennligst skriv inn en adresse';

  @override
  String get addStationCity => 'By';

  @override
  String get addStationCityHint => 'f.eks. Oslo';

  @override
  String get addStationCityRequired => 'Vennligst skriv inn en by';

  @override
  String get addStationSubmitButton => 'Send inn stasjon';

  @override
  String get addStationSubmitted => 'Stasjon sendt inn for gjennomgang!';

  @override
  String get addStationFailed => 'Kunne ikke sende inn stasjon. Prøv igjen.';

  @override
  String get stationsSubmitted => 'stasjoner sendt inn';

  @override
  String stationsSubmittedCount(int count) {
    return '$count stasjoner sendt inn';
  }

  @override
  String get myStationSubmissions => 'Mine stasjonsforslag';

  @override
  String get noSubmissionsYet => 'Ingen stasjonsforslag ennå';

  @override
  String get submissionStatusPending => 'Venter';

  @override
  String get submissionStatusApproved => 'Godkjent';

  @override
  String get submissionStatusRejected => 'Avvist';

  @override
  String get adminFeedback => 'Tilbakemelding fra admin';

  @override
  String adminFeedbackFor(String stationName) {
    return 'Tilbakemelding for $stationName';
  }

  @override
  String get dismiss => 'Lukk';

  @override
  String get editStation => 'Rediger stasjon';

  @override
  String get addStationUpdateButton => 'Oppdater stasjon';

  @override
  String get addStationUpdated => 'Stasjon oppdatert!';

  @override
  String get edit => 'Rediger';

  @override
  String get delete => 'Slett';

  @override
  String get deleteSubmissionTitle => 'Slette forslag?';

  @override
  String get deleteSubmissionBody =>
      'Dette vil permanent slette dette stasjonsforslaget. Denne handlingen kan ikke angres.';

  @override
  String get adminSection => 'ADMIN';

  @override
  String get adminPanel => 'Stasjonsgodkjenning';

  @override
  String get adminPanelSubtitle => 'Gjennomgå og godkjenn nye stasjonsforslag';

  @override
  String get noPendingSubmissions => 'Ingen ventende forslag';

  @override
  String get approve => 'Godkjenn';

  @override
  String get reject => 'Avvis';

  @override
  String get rejectStationTitle => 'Avvise stasjon?';

  @override
  String get rejectStationBody =>
      'Dette vil avvise forslaget. Du kan eventuelt gi tilbakemelding til brukeren.';

  @override
  String get adminFeedbackHint => 'Tilbakemelding til brukeren (valgfritt)';

  @override
  String get deleteReportTitle => 'Slette rapport?';

  @override
  String get deleteReportBody =>
      'Dette vil permanent fjerne denne prisrapporten.';

  @override
  String deleteReportFailed(String error) {
    return 'Kunne ikke slette rapport: $error';
  }

  @override
  String get coordinates => 'Koordinater';

  @override
  String get approveStationTitle => 'Godkjenn stasjon?';

  @override
  String get approveStationBody =>
      'Dette vil legge stasjonen til på kartet. Du kan eventuelt sende tilbakemelding til brukeren.';

  @override
  String get deleteStationTitle => 'Slette stasjon?';

  @override
  String get deleteStationBody =>
      'Dette vil permanent fjerne denne stasjonen fra kartet.';

  @override
  String get deleteStationFailed => 'Kunne ikke slette stasjonen';

  @override
  String get editStationInfo => 'Foreslå endring';

  @override
  String get submitChanges => 'Send inn endringer';

  @override
  String get noChangesToSubmit => 'Ingen endringer å sende inn';

  @override
  String get modifyRequestSubmitted =>
      'Endringsforslag sendt inn for gjennomgang!';

  @override
  String get modifyRequestFailed =>
      'Kunne ikke sende inn endringsforslag. Prøv igjen.';

  @override
  String get modifyRequests => 'Endringsforslag for stasjoner';

  @override
  String get modifyRequestsSubtitle => 'Gjennomgå foreslåtte stasjonsendringer';

  @override
  String get noPendingModifyRequests => 'Ingen ventende endringsforslag';

  @override
  String get approveModifyBody =>
      'Dette vil bruke de foreslåtte endringene på stasjonen.';

  @override
  String stationId(String id) {
    return 'ID: $id';
  }

  @override
  String get manageAdmins => 'Administrer administratorer';

  @override
  String get manageAdminsSubtitle =>
      'Forfremme eller degradere brukere etter e-post';

  @override
  String get manageAdminsIntro =>
      'Skriv inn en brukers e-post for å forfremme dem til administrator eller fjerne administratortilgangen. Endringer trer i kraft neste gang brukeren logger inn.';

  @override
  String get manageAdminsEmailHint => 'f.eks. bruker@eksempel.no';

  @override
  String get promote => 'Forfremme';

  @override
  String get demote => 'Degradere';

  @override
  String get adminPromoted => 'Brukeren ble forfremmet til administrator.';

  @override
  String get adminDemoted => 'Administratortilgang fjernet.';

  @override
  String adminUpdateFailed(String error) {
    return 'Kunne ikke oppdatere administratorstatus: $error';
  }

  @override
  String get onboardingTitle => 'Velkommen til Drivstoffpriser!';

  @override
  String get onboardingRadiusTitle => 'Filtrer etter radius og merke';

  @override
  String get onboardingRadiusBody =>
      'Trykk på filterknappen for å angi søkeradius og velge hvilke drivstoffmerker som vises på kartet.';

  @override
  String get onboardingAddStationTitle => 'Legg til en manglende stasjon';

  @override
  String get onboardingAddStationBody =>
      'Hvis en stasjon mangler, trykk og hold på kartet for å plassere den, fyll ut detaljene og send inn.';

  @override
  String get onboardingEditStationTitle => 'Rediger stasjonsinformasjon';

  @override
  String get onboardingEditStationBody =>
      'Hvis noe er feil med en stasjon, åpne den og trykk på redigeringsknappen for å foreslå endringer.';

  @override
  String get onboardingNext => 'Neste';

  @override
  String get tips => 'Tips';

  @override
  String get tipsSubtitle => 'Lær om appens funksjoner';

  @override
  String onboardingStepOf(int current, int total) {
    return '$current av $total';
  }

  @override
  String nearbyStationPrompt(String stationName) {
    return 'Du er i nærheten av $stationName. Rapportere pris?';
  }

  @override
  String get emailNotVerified => 'Bekreft e-posten din';

  @override
  String get emailNotVerifiedSubtitle =>
      'Sjekk innboksen din for en bekreftelseslenke';

  @override
  String get resendVerificationEmail => 'Send på nytt';

  @override
  String get verificationEmailSent => 'Bekreftelses-e-post sendt';

  @override
  String get cameraZoomTipTitle => 'Zoom-tips';

  @override
  String get cameraZoomTipBody =>
      'Bruk knip-for-å-zoome for å zoome nærmere prisskiltet. Du kan også trykke på zoom-knappene under søkeren.';
}
