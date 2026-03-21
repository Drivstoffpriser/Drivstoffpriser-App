// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TankVenn';

  @override
  String get navMap => 'Map';

  @override
  String get navStations => 'Stations';

  @override
  String get navProfile => 'Profile';

  @override
  String get searchStations => 'Search stations...';

  @override
  String noStationsFound(String query) {
    return 'No stations found for \"$query\"';
  }

  @override
  String get bestNearby => 'Best Nearby';

  @override
  String get sortCheapest => 'Cheapest';

  @override
  String get sortNearest => 'Nearest';

  @override
  String get sortLatest => 'Latest';

  @override
  String sortLabel(String mode) {
    return 'Sort: $mode';
  }

  @override
  String get noPricesReported => 'No prices reported yet';

  @override
  String get allOfNorway => 'All of Norway';

  @override
  String get searchRadius => 'Search Radius';

  @override
  String get filterByBrand => 'Filter by Brand';

  @override
  String get clearAll => 'Clear all';

  @override
  String get navigate => 'Navigate';

  @override
  String get currentPrices => 'CURRENT PRICES';

  @override
  String get priceTrend => 'PRICE TREND (30 DAYS)';

  @override
  String get reportAPrice => 'Report a Price';

  @override
  String get recentReports => 'RECENT REPORTS';

  @override
  String get noReportsYet => 'No reports yet.';

  @override
  String get krSuffix => 'kr';

  @override
  String krPerUnit(String unit) {
    return 'kr/$unit';
  }

  @override
  String reportsCount(int count) {
    return '$count reports';
  }

  @override
  String stationsCount(int count) {
    return '$count stations';
  }

  @override
  String get profile => 'Profile';

  @override
  String get totalContributions => 'Total Contributions';

  @override
  String get priceReportsSubmitted => 'price reports submitted';

  @override
  String get trustScore => 'Trust Score';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signUpSubtitle => 'Sign up to report prices and earn trust';

  @override
  String get mapPreferences => 'MAP PREFERENCES';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageNorwegian => 'Norsk';

  @override
  String get refreshStations => 'Refresh Stations';

  @override
  String get updateNearbyStations => 'Update nearby fuel stations';

  @override
  String get stationsRefreshed => 'Stations refreshed';

  @override
  String get support => 'SUPPORT';

  @override
  String get reportABug => 'Report a Bug';

  @override
  String get foundIssue => 'Found an issue? Let us know';

  @override
  String get about => 'About';

  @override
  String get aboutDescription =>
      'Community-driven fuel price tracker for Norway. Report and find the cheapest fuel prices near you.';

  @override
  String get viewOnGithub => 'View on GitHub';

  @override
  String get account => 'ACCOUNT';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and data';

  @override
  String get deleteAccountConfirmTitle => 'Delete Account?';

  @override
  String get deleteAccountConfirmBody =>
      'This will permanently delete your account and profile data. Your submitted price reports will remain as anonymous community data.\n\nThis action cannot be undone.';

  @override
  String get deleteAccountConfirmButton => 'Delete Account';

  @override
  String get accountDeleted => 'Account deleted successfully';

  @override
  String get deleteAccountReauth =>
      'For security, please sign out and sign back in before deleting your account';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutSubtitle => 'Sign out of your account';

  @override
  String get guestUser => 'Guest User';

  @override
  String get reports => 'reports';

  @override
  String get trust => 'trust';

  @override
  String get signIn => 'Sign In';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get or => 'OR';

  @override
  String get displayName => 'Display Name';

  @override
  String get enterYourName => 'Please enter your name';

  @override
  String get email => 'Email';

  @override
  String get enterYourEmail => 'Please enter your email';

  @override
  String get enterValidEmail => 'Please enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get enterYourPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get needAccount => 'Need an account? Create one';

  @override
  String get errorEmailInUse =>
      'This email is already registered. Try signing in instead.';

  @override
  String get errorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get errorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get errorUserNotFound => 'No account found with this email.';

  @override
  String get errorWrongPassword => 'Incorrect email or password.';

  @override
  String get errorCredentialInUse =>
      'This credential is already associated with another account.';

  @override
  String errorAuthFailed(String code) {
    return 'Authentication failed: $code';
  }

  @override
  String get reportPrice => 'Report Price';

  @override
  String get enterPricesInstruction => 'Enter prices (fill in any you know)';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get couldNotRecognizePrices => 'Could not recognize any fuel prices';

  @override
  String filledPricesFromScan(int count) {
    return 'Filled $count price(s) from scan';
  }

  @override
  String get locationUnavailable =>
      'Location unavailable. Enable location services or scan a photo to report remotely.';

  @override
  String mustBeNearStation(int distance, int actual) {
    return 'You must be within ${distance}m of the station to report prices. You are ${actual}m away.';
  }

  @override
  String get enterAtLeastOnePrice => 'Enter at least one fuel price.';

  @override
  String get needAccountToReport => 'You need an account to report prices.';

  @override
  String get allOnCooldown =>
      'All selected fuel types are on cooldown. Try again later.';

  @override
  String get confirmPriceSubmission => 'Confirm Price Submission';

  @override
  String confirmSubmissionBody(String fuelTypes) {
    return 'Submitting prices for: $fuelTypes.\n\nAfter submitting, you will not be able to update these for a while.';
  }

  @override
  String get doNotShowAgain => 'Do not show this again';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String pricesReported(int count) {
    return '$count price(s) reported';
  }

  @override
  String skippedCooldown(int count) {
    return '$count skipped (cooldown)';
  }

  @override
  String get someSubmissionsFailed => 'Some submissions failed';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get scanPriceSign => 'Scan price sign';

  @override
  String get cropTip => 'Crop Tip';

  @override
  String get cropTipBody =>
      'After taking or selecting a photo, you will be asked to crop it. Try to include only the fuel price section of the sign for best results.';

  @override
  String get dontShowAgain => 'Don\'t show again';

  @override
  String get gotIt => 'Got it';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get cameraPermissionRequired => 'Camera permission required';

  @override
  String get failedToProcessImage => 'Failed to process image';

  @override
  String get verifyPrices => 'Verify Prices';

  @override
  String get pleaseDoubleCheck => 'Please double check the prices';

  @override
  String get krPerL => 'kr/L';

  @override
  String get retake => 'Retake';

  @override
  String get confirm => 'Confirm';

  @override
  String get selectPriceSign => 'Select price sign';

  @override
  String get done => 'Done';

  @override
  String get dragToSelect => 'Drag to select the area with fuel prices';

  @override
  String cropFailed(String cause) {
    return 'Crop failed: $cause';
  }

  @override
  String get priceRange => 'Range: 5-50 kr';

  @override
  String get enterAPrice => 'Enter a price';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get priceMustBeBetween => 'Price must be between 5 and 50 kr';

  @override
  String get bugReportTitle => 'Report a Bug';

  @override
  String get bugReportIntro =>
      'Found an issue? Let us know the details and we will look into it.';

  @override
  String get title => 'Title';

  @override
  String get briefSummary => 'Brief summary of the issue';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get description => 'Description';

  @override
  String get whatHappened => 'What happened? How can we reproduce it?';

  @override
  String get pleaseEnterDescription => 'Please enter a description';

  @override
  String get submitReportButton => 'Submit Report';

  @override
  String get technicalInfo =>
      'Technical information about your device and app version will be included automatically.';

  @override
  String get bugReportSubmitted => 'Bug report submitted. Thank you!';

  @override
  String bugReportFailed(String error) {
    return 'Failed to submit report: $error';
  }

  @override
  String get noInternetTitle => 'No internet connection';

  @override
  String get noInternetBody =>
      'TankVenn requires an active Wi-Fi or mobile data connection to show fuel prices and station data.';

  @override
  String get stillNoConnection => 'Still no connection';

  @override
  String get tryAgain => 'Try again';

  @override
  String get retry => 'Retry';

  @override
  String get fuelPetrol95 => 'Petrol 95';

  @override
  String get fuelPetrol98 => 'Petrol 98';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get anonymousBrowsingOnly => 'Anonymous (browsing only)';

  @override
  String get googleEmailAccount => 'Google + Email account';

  @override
  String get googleAccount => 'Google account';

  @override
  String get emailAccount => 'Email account';

  @override
  String get contributeData => 'CONTRIBUTE DATA';

  @override
  String get station => 'Station';

  @override
  String get fuelType => 'Fuel Type';

  @override
  String get price => 'Price';

  @override
  String get selectStation => 'Select a Station';

  @override
  String get chooseStationSubtitle =>
      'Choose the station where you want to report a price';

  @override
  String get selectFuelGrade => 'Select Fuel Grade';

  @override
  String get whatFuelType => 'What type of fuel are you reporting?';

  @override
  String get enterPrice => 'Enter Price';

  @override
  String currentAvg(String price) {
    return 'Current avg: $price kr';
  }

  @override
  String get nok => 'NOK';

  @override
  String get perL => 'per L';

  @override
  String get verifyAndSubmit => 'Verify & Submit';

  @override
  String get createPriceAlert => 'Create Price Alert';

  @override
  String targetPrice(String symbol) {
    return 'Target price ($symbol)';
  }

  @override
  String get egPrice => 'e.g. 20.50';

  @override
  String get enterTargetPrice => 'Enter a target price';

  @override
  String priceBetween(String symbol) {
    return 'Price must be between 5 and 50 $symbol';
  }

  @override
  String get anyStation => 'Any station';

  @override
  String get maxDistance => 'Max distance';

  @override
  String get myAlerts => 'My Alerts';

  @override
  String get create => 'Create';

  @override
  String get priceAlertCreated => 'Price alert created';

  @override
  String get noAlertsYet => 'No alerts yet';

  @override
  String ageMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String ageHours(int hours) {
    return '${hours}hr';
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
}
