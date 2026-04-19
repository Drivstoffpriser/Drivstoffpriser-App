import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nb.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nb'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Drivstoffpriser'**
  String get appTitle;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navStations.
  ///
  /// In en, this message translates to:
  /// **'Stations'**
  String get navStations;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @searchStations.
  ///
  /// In en, this message translates to:
  /// **'Search stations...'**
  String get searchStations;

  /// No description provided for @noStationsFound.
  ///
  /// In en, this message translates to:
  /// **'No stations found for \"{query}\"'**
  String noStationsFound(String query);

  /// No description provided for @bestNearby.
  ///
  /// In en, this message translates to:
  /// **'Best Nearby'**
  String get bestNearby;

  /// No description provided for @sortCheapest.
  ///
  /// In en, this message translates to:
  /// **'Cheapest'**
  String get sortCheapest;

  /// No description provided for @sortNearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get sortNearest;

  /// No description provided for @sortLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get sortLatest;

  /// No description provided for @sortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort: {mode}'**
  String sortLabel(String mode);

  /// No description provided for @noPricesReported.
  ///
  /// In en, this message translates to:
  /// **'No prices reported yet'**
  String get noPricesReported;

  /// No description provided for @allOfNorway.
  ///
  /// In en, this message translates to:
  /// **'All of Norway'**
  String get allOfNorway;

  /// No description provided for @searchRadius.
  ///
  /// In en, this message translates to:
  /// **'Search Radius'**
  String get searchRadius;

  /// No description provided for @filterByBrand.
  ///
  /// In en, this message translates to:
  /// **'Filter by Brand'**
  String get filterByBrand;

  /// No description provided for @showFavoritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Show favorites only'**
  String get showFavoritesOnly;

  /// No description provided for @allowMapRotation.
  ///
  /// In en, this message translates to:
  /// **'Allow map rotation'**
  String get allowMapRotation;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @currentPrices.
  ///
  /// In en, this message translates to:
  /// **'CURRENT PRICES'**
  String get currentPrices;

  /// No description provided for @priceTrend.
  ///
  /// In en, this message translates to:
  /// **'PRICE TREND (30 DAYS)'**
  String get priceTrend;

  /// No description provided for @reportAPrice.
  ///
  /// In en, this message translates to:
  /// **'Report a Price'**
  String get reportAPrice;

  /// No description provided for @recentReports.
  ///
  /// In en, this message translates to:
  /// **'RECENT REPORTS'**
  String get recentReports;

  /// No description provided for @noReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet.'**
  String get noReportsYet;

  /// No description provided for @krSuffix.
  ///
  /// In en, this message translates to:
  /// **'kr'**
  String get krSuffix;

  /// No description provided for @krPerUnit.
  ///
  /// In en, this message translates to:
  /// **'kr/{unit}'**
  String krPerUnit(String unit);

  /// No description provided for @reportsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reports'**
  String reportsCount(int count);

  /// No description provided for @stationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} stations'**
  String stationsCount(int count);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @totalContributions.
  ///
  /// In en, this message translates to:
  /// **'Total Contributions'**
  String get totalContributions;

  /// No description provided for @priceReportsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'price reports'**
  String get priceReportsSubmitted;

  /// No description provided for @trustScore.
  ///
  /// In en, this message translates to:
  /// **'Trust Score'**
  String get trustScore;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to report prices and earn trust'**
  String get signUpSubtitle;

  /// No description provided for @mapPreferences.
  ///
  /// In en, this message translates to:
  /// **'MAP PREFERENCES'**
  String get mapPreferences;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageNorwegian.
  ///
  /// In en, this message translates to:
  /// **'Norsk'**
  String get languageNorwegian;

  /// No description provided for @refreshStations.
  ///
  /// In en, this message translates to:
  /// **'Refresh Stations'**
  String get refreshStations;

  /// No description provided for @updateNearbyStations.
  ///
  /// In en, this message translates to:
  /// **'Update nearby fuel stations'**
  String get updateNearbyStations;

  /// No description provided for @stationsRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Stations refreshed'**
  String get stationsRefreshed;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh stations. Please try again.'**
  String get refreshFailed;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get support;

  /// No description provided for @reportABug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportABug;

  /// No description provided for @foundIssue.
  ///
  /// In en, this message translates to:
  /// **'Found an issue? Let us know'**
  String get foundIssue;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Community-driven fuel price tracker for Norway. Report and find the cheapest fuel prices near you.'**
  String get aboutDescription;

  /// No description provided for @viewOnGithub.
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get viewOnGithub;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get privacyPolicySubtitle;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get account;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and data'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and profile data. Your submitted price reports will remain as anonymous community data.\n\nThis action cannot be undone.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountConfirmButton;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeleted;

  /// No description provided for @deleteAccountReauth.
  ///
  /// In en, this message translates to:
  /// **'For security, please sign out and sign back in before deleting your account'**
  String get deleteAccountReauth;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutSubtitle;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'reports'**
  String get reports;

  /// No description provided for @trust.
  ///
  /// In en, this message translates to:
  /// **'trust'**
  String get trust;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get enterYourName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterYourPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @needAccount.
  ///
  /// In en, this message translates to:
  /// **'Need an account? Create one'**
  String get needAccount;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try signing in instead.'**
  String get errorEmailInUse;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get errorInvalidEmail;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get errorWeakPassword;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get errorUserNotFound;

  /// No description provided for @errorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errorWrongPassword;

  /// No description provided for @errorCredentialInUse.
  ///
  /// In en, this message translates to:
  /// **'This credential is already associated with another account.'**
  String get errorCredentialInUse;

  /// No description provided for @errorAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed: {code}'**
  String errorAuthFailed(String code);

  /// No description provided for @reportPrice.
  ///
  /// In en, this message translates to:
  /// **'Report Price'**
  String get reportPrice;

  /// No description provided for @enterPricesInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter prices (fill in any you know)'**
  String get enterPricesInstruction;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @couldNotRecognizePrices.
  ///
  /// In en, this message translates to:
  /// **'Could not recognize any fuel prices'**
  String get couldNotRecognizePrices;

  /// No description provided for @filledPricesFromScan.
  ///
  /// In en, this message translates to:
  /// **'Filled {count} price(s) from scan'**
  String filledPricesFromScan(int count);

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable. Enable location services or scan a photo to report remotely.'**
  String get locationUnavailable;

  /// No description provided for @mustBeNearStation.
  ///
  /// In en, this message translates to:
  /// **'You must be within {distance}m of the station to report prices. You are {actual}m away.'**
  String mustBeNearStation(int distance, int actual);

  /// No description provided for @enterAtLeastOnePrice.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one fuel price.'**
  String get enterAtLeastOnePrice;

  /// No description provided for @needAccountToReport.
  ///
  /// In en, this message translates to:
  /// **'You need an account to report prices.'**
  String get needAccountToReport;

  /// No description provided for @allOnCooldown.
  ///
  /// In en, this message translates to:
  /// **'All selected fuel types are on cooldown. Try again later.'**
  String get allOnCooldown;

  /// No description provided for @confirmPriceSubmission.
  ///
  /// In en, this message translates to:
  /// **'Confirm Price Submission'**
  String get confirmPriceSubmission;

  /// No description provided for @confirmSubmissionBody.
  ///
  /// In en, this message translates to:
  /// **'Submitting prices for: {fuelTypes}.\n\nAfter submitting, you will not be able to update these for a while.'**
  String confirmSubmissionBody(String fuelTypes);

  /// No description provided for @doNotShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Do not show this again'**
  String get doNotShowAgain;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @pricesReported.
  ///
  /// In en, this message translates to:
  /// **'{count} price(s) reported'**
  String pricesReported(int count);

  /// No description provided for @skippedCooldown.
  ///
  /// In en, this message translates to:
  /// **'{count} skipped (cooldown)'**
  String skippedCooldown(int count);

  /// No description provided for @someSubmissionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Some submissions failed'**
  String get someSubmissionsFailed;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @scanPriceSign.
  ///
  /// In en, this message translates to:
  /// **'Scan price sign'**
  String get scanPriceSign;

  /// No description provided for @cropTip.
  ///
  /// In en, this message translates to:
  /// **'Crop Tip'**
  String get cropTip;

  /// No description provided for @cropTipBody.
  ///
  /// In en, this message translates to:
  /// **'After taking or selecting a photo, you will be asked to crop it. Try to include only the fuel price section of the sign for best results.'**
  String get cropTipBody;

  /// No description provided for @dontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show again'**
  String get dontShowAgain;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get chooseFromGallery;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get cameraPermissionRequired;

  /// No description provided for @failedToProcessImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to process image'**
  String get failedToProcessImage;

  /// No description provided for @verifyPrices.
  ///
  /// In en, this message translates to:
  /// **'Verify Prices'**
  String get verifyPrices;

  /// No description provided for @pleaseDoubleCheck.
  ///
  /// In en, this message translates to:
  /// **'Please double check the prices'**
  String get pleaseDoubleCheck;

  /// No description provided for @krPerL.
  ///
  /// In en, this message translates to:
  /// **'kr/L'**
  String get krPerL;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @selectPriceSign.
  ///
  /// In en, this message translates to:
  /// **'Select price sign'**
  String get selectPriceSign;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dragToSelect.
  ///
  /// In en, this message translates to:
  /// **'Drag to select the area with fuel prices'**
  String get dragToSelect;

  /// No description provided for @cropFailed.
  ///
  /// In en, this message translates to:
  /// **'Crop failed: {cause}'**
  String cropFailed(String cause);

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Range: 10-40 kr'**
  String get priceRange;

  /// No description provided for @enterAPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a price'**
  String get enterAPrice;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @priceMustBeBetween.
  ///
  /// In en, this message translates to:
  /// **'Price must be between 10 and 40 kr'**
  String get priceMustBeBetween;

  /// No description provided for @bugReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get bugReportTitle;

  /// No description provided for @bugReportIntro.
  ///
  /// In en, this message translates to:
  /// **'Found an issue? Let us know the details and we will look into it.'**
  String get bugReportIntro;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @briefSummary.
  ///
  /// In en, this message translates to:
  /// **'Brief summary of the issue'**
  String get briefSummary;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @whatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened? How can we reproduce it?'**
  String get whatHappened;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get pleaseEnterDescription;

  /// No description provided for @submitReportButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReportButton;

  /// No description provided for @technicalInfo.
  ///
  /// In en, this message translates to:
  /// **'Technical information about your device and app version will be included automatically.'**
  String get technicalInfo;

  /// No description provided for @bugReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Bug report submitted. Thank you!'**
  String get bugReportSubmitted;

  /// No description provided for @bugReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report: {error}'**
  String bugReportFailed(String error);

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetTitle;

  /// No description provided for @noInternetBody.
  ///
  /// In en, this message translates to:
  /// **'Drivstoffpriser requires an active Wi-Fi or mobile data connection to show fuel prices and station data.'**
  String get noInternetBody;

  /// No description provided for @stillNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Still no connection'**
  String get stillNoConnection;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @fuelPetrol95.
  ///
  /// In en, this message translates to:
  /// **'Petrol 95'**
  String get fuelPetrol95;

  /// No description provided for @fuelPetrol98.
  ///
  /// In en, this message translates to:
  /// **'Petrol 98'**
  String get fuelPetrol98;

  /// No description provided for @fuelDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelDiesel;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @anonymousBrowsingOnly.
  ///
  /// In en, this message translates to:
  /// **'Anonymous (browsing only)'**
  String get anonymousBrowsingOnly;

  /// No description provided for @googleEmailAccount.
  ///
  /// In en, this message translates to:
  /// **'Google + Email account'**
  String get googleEmailAccount;

  /// No description provided for @googleAccount.
  ///
  /// In en, this message translates to:
  /// **'Google account'**
  String get googleAccount;

  /// No description provided for @emailAccount.
  ///
  /// In en, this message translates to:
  /// **'Email account'**
  String get emailAccount;

  /// No description provided for @emailConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Email confirmed'**
  String get emailConfirmed;

  /// No description provided for @contributeData.
  ///
  /// In en, this message translates to:
  /// **'CONTRIBUTE DATA'**
  String get contributeData;

  /// No description provided for @station.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get station;

  /// No description provided for @fuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel Type'**
  String get fuelType;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @selectStation.
  ///
  /// In en, this message translates to:
  /// **'Select a Station'**
  String get selectStation;

  /// No description provided for @chooseStationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the station where you want to report a price'**
  String get chooseStationSubtitle;

  /// No description provided for @selectFuelGrade.
  ///
  /// In en, this message translates to:
  /// **'Select Fuel Grade'**
  String get selectFuelGrade;

  /// No description provided for @whatFuelType.
  ///
  /// In en, this message translates to:
  /// **'What type of fuel are you reporting?'**
  String get whatFuelType;

  /// No description provided for @enterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter Price'**
  String get enterPrice;

  /// No description provided for @currentAvg.
  ///
  /// In en, this message translates to:
  /// **'Current avg: {price} kr'**
  String currentAvg(String price);

  /// No description provided for @nok.
  ///
  /// In en, this message translates to:
  /// **'NOK'**
  String get nok;

  /// No description provided for @perL.
  ///
  /// In en, this message translates to:
  /// **'per L'**
  String get perL;

  /// No description provided for @verifyAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Verify & Submit'**
  String get verifyAndSubmit;

  /// No description provided for @createPriceAlert.
  ///
  /// In en, this message translates to:
  /// **'Create Price Alert'**
  String get createPriceAlert;

  /// No description provided for @targetPrice.
  ///
  /// In en, this message translates to:
  /// **'Target price ({symbol})'**
  String targetPrice(String symbol);

  /// No description provided for @egPrice.
  ///
  /// In en, this message translates to:
  /// **'e.g. 20.50'**
  String get egPrice;

  /// No description provided for @enterTargetPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a target price'**
  String get enterTargetPrice;

  /// No description provided for @priceBetween.
  ///
  /// In en, this message translates to:
  /// **'Price must be between 5 and 50 {symbol}'**
  String priceBetween(String symbol);

  /// No description provided for @anyStation.
  ///
  /// In en, this message translates to:
  /// **'Any station'**
  String get anyStation;

  /// No description provided for @maxDistance.
  ///
  /// In en, this message translates to:
  /// **'Max distance'**
  String get maxDistance;

  /// No description provided for @myAlerts.
  ///
  /// In en, this message translates to:
  /// **'My Alerts'**
  String get myAlerts;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @priceAlertCreated.
  ///
  /// In en, this message translates to:
  /// **'Price alert created'**
  String get priceAlertCreated;

  /// No description provided for @noAlertsYet.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet'**
  String get noAlertsYet;

  /// No description provided for @ageMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String ageMinutes(int minutes);

  /// No description provided for @ageHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}hr'**
  String ageHours(int hours);

  /// No description provided for @ageOver1Day.
  ///
  /// In en, this message translates to:
  /// **'>1d'**
  String get ageOver1Day;

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(String meters);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// No description provided for @addStationHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a missing station'**
  String get addStationHintTitle;

  /// No description provided for @addStationHintBody.
  ///
  /// In en, this message translates to:
  /// **'Tap and hold on the map at the location where you want to add a new station.'**
  String get addStationHintBody;

  /// No description provided for @addStation.
  ///
  /// In en, this message translates to:
  /// **'Add Station'**
  String get addStation;

  /// No description provided for @addStationTapMap.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to set the station location'**
  String get addStationTapMap;

  /// No description provided for @addStationName.
  ///
  /// In en, this message translates to:
  /// **'Station Name'**
  String get addStationName;

  /// No description provided for @addStationNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Shell Storo'**
  String get addStationNameHint;

  /// No description provided for @addStationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a station name'**
  String get addStationNameRequired;

  /// No description provided for @addStationBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get addStationBrand;

  /// No description provided for @addStationSelectBrand.
  ///
  /// In en, this message translates to:
  /// **'Please select a brand'**
  String get addStationSelectBrand;

  /// No description provided for @addStationNoChain.
  ///
  /// In en, this message translates to:
  /// **'Other / No chain'**
  String get addStationNoChain;

  /// No description provided for @addStationCustomBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand Name'**
  String get addStationCustomBrand;

  /// No description provided for @addStationCustomBrandHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Local Gas'**
  String get addStationCustomBrandHint;

  /// No description provided for @addStationBrandRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a brand name'**
  String get addStationBrandRequired;

  /// No description provided for @stationLogo.
  ///
  /// In en, this message translates to:
  /// **'Station Logo'**
  String get stationLogo;

  /// No description provided for @logoHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — will apply to all stations of this brand'**
  String get logoHint;

  /// No description provided for @uploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Logo'**
  String get uploadLogo;

  /// No description provided for @changeLogo.
  ///
  /// In en, this message translates to:
  /// **'Change Logo'**
  String get changeLogo;

  /// No description provided for @removeLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove Logo'**
  String get removeLogo;

  /// No description provided for @proposedLogo.
  ///
  /// In en, this message translates to:
  /// **'Proposed Logo'**
  String get proposedLogo;

  /// No description provided for @logoAppliesToBrand.
  ///
  /// In en, this message translates to:
  /// **'Will apply to all \"{brand}\" stations'**
  String logoAppliesToBrand(String brand);

  /// No description provided for @addStationAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addStationAddress;

  /// No description provided for @addStationAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Storgata 1'**
  String get addStationAddressHint;

  /// No description provided for @addStationAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an address'**
  String get addStationAddressRequired;

  /// No description provided for @addStationCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get addStationCity;

  /// No description provided for @addStationCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Oslo'**
  String get addStationCityHint;

  /// No description provided for @addStationCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a city'**
  String get addStationCityRequired;

  /// No description provided for @addStationSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Station'**
  String get addStationSubmitButton;

  /// No description provided for @addStationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Station submitted for review!'**
  String get addStationSubmitted;

  /// No description provided for @addStationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit station. Please try again.'**
  String get addStationFailed;

  /// No description provided for @stationsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'stations submitted'**
  String get stationsSubmitted;

  /// No description provided for @stationsSubmittedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} stations submitted'**
  String stationsSubmittedCount(int count);

  /// No description provided for @myStationSubmissions.
  ///
  /// In en, this message translates to:
  /// **'My Station Submissions'**
  String get myStationSubmissions;

  /// No description provided for @noSubmissionsYet.
  ///
  /// In en, this message translates to:
  /// **'No station submissions yet'**
  String get noSubmissionsYet;

  /// No description provided for @submissionStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get submissionStatusPending;

  /// No description provided for @submissionStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get submissionStatusApproved;

  /// No description provided for @submissionStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get submissionStatusRejected;

  /// No description provided for @adminFeedback.
  ///
  /// In en, this message translates to:
  /// **'Admin Feedback'**
  String get adminFeedback;

  /// No description provided for @adminFeedbackFor.
  ///
  /// In en, this message translates to:
  /// **'Feedback for {stationName}'**
  String adminFeedbackFor(String stationName);

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @editStation.
  ///
  /// In en, this message translates to:
  /// **'Edit Station'**
  String get editStation;

  /// No description provided for @addStationUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Station'**
  String get addStationUpdateButton;

  /// No description provided for @addStationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Station updated!'**
  String get addStationUpdated;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteSubmissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Submission?'**
  String get deleteSubmissionTitle;

  /// No description provided for @deleteSubmissionBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this station submission. This action cannot be undone.'**
  String get deleteSubmissionBody;

  /// No description provided for @adminSection.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get adminSection;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Station Approvals'**
  String get adminPanel;

  /// No description provided for @adminPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and approve new station submissions'**
  String get adminPanelSubtitle;

  /// No description provided for @noPendingSubmissions.
  ///
  /// In en, this message translates to:
  /// **'No pending submissions'**
  String get noPendingSubmissions;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectStationTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Station?'**
  String get rejectStationTitle;

  /// No description provided for @rejectStationBody.
  ///
  /// In en, this message translates to:
  /// **'This will reject the submission. You can optionally provide feedback to the user.'**
  String get rejectStationBody;

  /// No description provided for @adminFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Feedback for the user (optional)'**
  String get adminFeedbackHint;

  /// No description provided for @deleteReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Report?'**
  String get deleteReportTitle;

  /// No description provided for @deleteReportBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this price report.'**
  String get deleteReportBody;

  /// No description provided for @deleteReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete report: {error}'**
  String deleteReportFailed(String error);

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @approveStationTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve Station?'**
  String get approveStationTitle;

  /// No description provided for @approveStationBody.
  ///
  /// In en, this message translates to:
  /// **'This will add the station to the map. You can optionally send feedback to the user.'**
  String get approveStationBody;

  /// No description provided for @deleteStationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Station?'**
  String get deleteStationTitle;

  /// No description provided for @deleteStationBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this station from the map.'**
  String get deleteStationBody;

  /// No description provided for @deleteStationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete station'**
  String get deleteStationFailed;

  /// No description provided for @editStationInfo.
  ///
  /// In en, this message translates to:
  /// **'Suggest Edit'**
  String get editStationInfo;

  /// No description provided for @submitChanges.
  ///
  /// In en, this message translates to:
  /// **'Submit Changes'**
  String get submitChanges;

  /// No description provided for @noChangesToSubmit.
  ///
  /// In en, this message translates to:
  /// **'No changes to submit'**
  String get noChangesToSubmit;

  /// No description provided for @modifyRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Change request submitted for review!'**
  String get modifyRequestSubmitted;

  /// No description provided for @modifyRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit change request. Please try again.'**
  String get modifyRequestFailed;

  /// No description provided for @modifyRequests.
  ///
  /// In en, this message translates to:
  /// **'Station Edit Requests'**
  String get modifyRequests;

  /// No description provided for @modifyRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review proposed station changes'**
  String get modifyRequestsSubtitle;

  /// No description provided for @noPendingModifyRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending edit requests'**
  String get noPendingModifyRequests;

  /// No description provided for @approveModifyBody.
  ///
  /// In en, this message translates to:
  /// **'This will apply the proposed changes to the station.'**
  String get approveModifyBody;

  /// No description provided for @stationId.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String stationId(String id);

  /// No description provided for @manageAdmins.
  ///
  /// In en, this message translates to:
  /// **'Manage Admins'**
  String get manageAdmins;

  /// No description provided for @manageAdminsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Promote or demote users by Firebase UID'**
  String get manageAdminsSubtitle;

  /// No description provided for @manageAdminsIntro.
  ///
  /// In en, this message translates to:
  /// **'Paste a user\'s Firebase UID and promote them to admin or remove their admin access. Changes take effect next time the user signs in.'**
  String get manageAdminsIntro;

  /// No description provided for @firebaseUid.
  ///
  /// In en, this message translates to:
  /// **'Firebase UID'**
  String get firebaseUid;

  /// No description provided for @firebaseUidHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. HPcfQndrCHQfDg1w9UHo8mClQ8G3'**
  String get firebaseUidHint;

  /// No description provided for @pleaseEnterUid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a UID'**
  String get pleaseEnterUid;

  /// No description provided for @promote.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get promote;

  /// No description provided for @demote.
  ///
  /// In en, this message translates to:
  /// **'Demote'**
  String get demote;

  /// No description provided for @adminPromoted.
  ///
  /// In en, this message translates to:
  /// **'User promoted to admin.'**
  String get adminPromoted;

  /// No description provided for @adminDemoted.
  ///
  /// In en, this message translates to:
  /// **'Admin access removed.'**
  String get adminDemoted;

  /// No description provided for @adminUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update admin status: {error}'**
  String adminUpdateFailed(String error);

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Drivstoffpriser!'**
  String get onboardingTitle;

  /// No description provided for @onboardingRadiusTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by Radius & Brand'**
  String get onboardingRadiusTitle;

  /// No description provided for @onboardingRadiusBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the filter button to set a search radius and select which fuel brands to show on the map.'**
  String get onboardingRadiusBody;

  /// No description provided for @onboardingAddStationTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a Missing Station'**
  String get onboardingAddStationTitle;

  /// No description provided for @onboardingAddStationBody.
  ///
  /// In en, this message translates to:
  /// **'If a station is missing, tap and hold on the map to place it, then fill in the details and submit.'**
  String get onboardingAddStationBody;

  /// No description provided for @onboardingEditStationTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Station Info'**
  String get onboardingEditStationTitle;

  /// No description provided for @onboardingEditStationBody.
  ///
  /// In en, this message translates to:
  /// **'If something is wrong with a station, open it and tap the edit button to suggest changes.'**
  String get onboardingEditStationBody;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// No description provided for @tipsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn about app features'**
  String get tipsSubtitle;

  /// No description provided for @onboardingStepOf.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String onboardingStepOf(int current, int total);

  /// No description provided for @nearbyStationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Looks like you are close to {stationName}. Report a price?'**
  String nearbyStationPrompt(String stationName);

  /// No description provided for @emailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get emailNotVerified;

  /// No description provided for @emailNotVerifiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox for a verification link'**
  String get emailNotVerifiedSubtitle;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendVerificationEmail;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get verificationEmailSent;

  /// No description provided for @cameraZoomTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Zoom Tip'**
  String get cameraZoomTipTitle;

  /// No description provided for @cameraZoomTipBody.
  ///
  /// In en, this message translates to:
  /// **'Use pinch-to-zoom to zoom in closer to the price sign. You can also tap the zoom buttons below the viewfinder.'**
  String get cameraZoomTipBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nb'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nb':
      return AppLocalizationsNb();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
