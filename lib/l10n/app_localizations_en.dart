// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Drivstoffpriser';

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
  String get showFavoritesOnly => 'Show favorites only';

  @override
  String get allowMapRotation => 'Allow map rotation';

  @override
  String get clearAll => 'Clear all';

  @override
  String get favorites => 'Favorites';

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
  String get priceReportsSubmitted => 'price reports';

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
  String get refreshFailed => 'Failed to refresh stations. Please try again.';

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
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'How we handle your data';

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
  String get chooseFromGallery => 'Gallery';

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
  String get priceRange => 'Range: 10-40 kr';

  @override
  String get enterAPrice => 'Enter a price';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get priceMustBeBetween => 'Price must be between 10 and 40 kr';

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
      'Drivstoffpriser requires an active Wi-Fi or mobile data connection to show fuel prices and station data.';

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
  String get emailConfirmed => 'Email confirmed';

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

  @override
  String get addStationHintTitle => 'Add a missing station';

  @override
  String get addStationHintBody =>
      'Tap and hold on the map at the location where you want to add a new station.';

  @override
  String get addStation => 'Add Station';

  @override
  String get addStationTapMap => 'Tap the map to set the station location';

  @override
  String get addStationName => 'Station Name';

  @override
  String get addStationNameHint => 'e.g. Shell Storo';

  @override
  String get addStationNameRequired => 'Please enter a station name';

  @override
  String get addStationBrand => 'Brand';

  @override
  String get addStationSelectBrand => 'Please select a brand';

  @override
  String get addStationNoChain => 'Other / No chain';

  @override
  String get addStationCustomBrand => 'Brand Name';

  @override
  String get addStationCustomBrandHint => 'e.g. Local Gas';

  @override
  String get addStationBrandRequired => 'Please enter a brand name';

  @override
  String get stationLogo => 'Station Logo';

  @override
  String get logoHint => 'Optional — will apply to all stations of this brand';

  @override
  String get uploadLogo => 'Upload Logo';

  @override
  String get changeLogo => 'Change Logo';

  @override
  String get removeLogo => 'Remove Logo';

  @override
  String get proposedLogo => 'Proposed Logo';

  @override
  String logoAppliesToBrand(String brand) {
    return 'Will apply to all \"$brand\" stations';
  }

  @override
  String get addStationAddress => 'Address';

  @override
  String get addStationAddressHint => 'e.g. Storgata 1';

  @override
  String get addStationAddressRequired => 'Please enter an address';

  @override
  String get addStationCity => 'City';

  @override
  String get addStationCityHint => 'e.g. Oslo';

  @override
  String get addStationCityRequired => 'Please enter a city';

  @override
  String get addStationSubmitButton => 'Submit Station';

  @override
  String get addStationSubmitted => 'Station submitted for review!';

  @override
  String get addStationFailed => 'Failed to submit station. Please try again.';

  @override
  String get stationsSubmitted => 'stations submitted';

  @override
  String stationsSubmittedCount(int count) {
    return '$count stations submitted';
  }

  @override
  String get myStationSubmissions => 'My Station Submissions';

  @override
  String get noSubmissionsYet => 'No station submissions yet';

  @override
  String get submissionStatusPending => 'Pending';

  @override
  String get submissionStatusApproved => 'Approved';

  @override
  String get submissionStatusRejected => 'Rejected';

  @override
  String get adminFeedback => 'Admin Feedback';

  @override
  String adminFeedbackFor(String stationName) {
    return 'Feedback for $stationName';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String get editStation => 'Edit Station';

  @override
  String get addStationUpdateButton => 'Update Station';

  @override
  String get addStationUpdated => 'Station updated!';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get deleteSubmissionTitle => 'Delete Submission?';

  @override
  String get deleteSubmissionBody =>
      'This will permanently delete this station submission. This action cannot be undone.';

  @override
  String get adminSection => 'ADMIN';

  @override
  String get adminPanel => 'Station Approvals';

  @override
  String get adminPanelSubtitle => 'Review and approve new station submissions';

  @override
  String get noPendingSubmissions => 'No pending submissions';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get rejectStationTitle => 'Reject Station?';

  @override
  String get rejectStationBody =>
      'This will reject the submission. You can optionally provide feedback to the user.';

  @override
  String get adminFeedbackHint => 'Feedback for the user (optional)';

  @override
  String get deleteReportTitle => 'Delete Report?';

  @override
  String get deleteReportBody =>
      'This will permanently remove this price report.';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get approveStationTitle => 'Approve Station?';

  @override
  String get approveStationBody =>
      'This will add the station to the map. You can optionally send feedback to the user.';

  @override
  String get deleteStationTitle => 'Delete Station?';

  @override
  String get deleteStationBody =>
      'This will permanently remove this station from the map.';

  @override
  String get editStationInfo => 'Suggest Edit';

  @override
  String get submitChanges => 'Submit Changes';

  @override
  String get noChangesToSubmit => 'No changes to submit';

  @override
  String get modifyRequestSubmitted => 'Change request submitted for review!';

  @override
  String get modifyRequestFailed =>
      'Failed to submit change request. Please try again.';

  @override
  String get modifyRequests => 'Station Edit Requests';

  @override
  String get modifyRequestsSubtitle => 'Review proposed station changes';

  @override
  String get noPendingModifyRequests => 'No pending edit requests';

  @override
  String get approveModifyBody =>
      'This will apply the proposed changes to the station.';

  @override
  String stationId(String id) {
    return 'ID: $id';
  }

  @override
  String get onboardingTitle => 'Welcome to Drivstoffpriser!';

  @override
  String get onboardingRadiusTitle => 'Filter by Radius & Brand';

  @override
  String get onboardingRadiusBody =>
      'Tap the filter button to set a search radius and select which fuel brands to show on the map.';

  @override
  String get onboardingAddStationTitle => 'Add a Missing Station';

  @override
  String get onboardingAddStationBody =>
      'If a station is missing, tap and hold on the map to place it, then fill in the details and submit.';

  @override
  String get onboardingEditStationTitle => 'Edit Station Info';

  @override
  String get onboardingEditStationBody =>
      'If something is wrong with a station, open it and tap the edit button to suggest changes.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get tips => 'Tips';

  @override
  String get tipsSubtitle => 'Learn about app features';

  @override
  String onboardingStepOf(int current, int total) {
    return '$current of $total';
  }

  @override
  String nearbyStationPrompt(String stationName) {
    return 'Looks like you are close to $stationName. Report a price?';
  }

  @override
  String get emailNotVerified => 'Verify your email';

  @override
  String get emailNotVerifiedSubtitle =>
      'Check your inbox for a verification link';

  @override
  String get resendVerificationEmail => 'Resend email';

  @override
  String get verificationEmailSent => 'Verification email sent';
}
