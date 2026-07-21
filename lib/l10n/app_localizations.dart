import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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
    Locale('pt'),
  ];

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'GOOD MORNING'**
  String get goodMorning;

  /// No description provided for @sharedTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'SHARED TOTAL BALANCE'**
  String get sharedTotalBalance;

  /// No description provided for @vsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get vsLastMonth;

  /// No description provided for @monthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly Income'**
  String get monthlyIncome;

  /// No description provided for @monthlyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Monthly Expenses'**
  String get monthlyExpenses;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @sharedMonthlySpending.
  ///
  /// In en, this message translates to:
  /// **'Shared monthly spending analysis'**
  String get sharedMonthlySpending;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @spendingIn.
  ///
  /// In en, this message translates to:
  /// **'SPENDING IN'**
  String get spendingIn;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdown;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @foodDining.
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get foodDining;

  /// No description provided for @transportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get transportation;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @wallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get wallets;

  /// No description provided for @manageSharedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage shared accounts & cards'**
  String get manageSharedAccounts;

  /// No description provided for @cardHolder.
  ///
  /// In en, this message translates to:
  /// **'CARD HOLDER'**
  String get cardHolder;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'EXPIRES'**
  String get expires;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @payBills.
  ///
  /// In en, this message translates to:
  /// **'Pay Bills'**
  String get payBills;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @sharedMonthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Shared Monthly Limit'**
  String get sharedMonthlyLimit;

  /// No description provided for @sharedLimitUsed.
  ///
  /// In en, this message translates to:
  /// **'Shared Limit Used'**
  String get sharedLimitUsed;

  /// No description provided for @limitText.
  ///
  /// In en, this message translates to:
  /// **'You have spent 42% of your shared threshold limit.'**
  String get limitText;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @customizePreferences.
  ///
  /// In en, this message translates to:
  /// **'Customize shared app preferences'**
  String get customizePreferences;

  /// No description provided for @premiumPlan.
  ///
  /// In en, this message translates to:
  /// **'Joint Account • Premium Plan'**
  String get premiumPlan;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get accountSettings;

  /// No description provided for @editProfiles.
  ///
  /// In en, this message translates to:
  /// **'Edit Profiles'**
  String get editProfiles;

  /// No description provided for @managePersonalProfiles.
  ///
  /// In en, this message translates to:
  /// **'Manage personal profiles'**
  String get managePersonalProfiles;

  /// No description provided for @connectedBanks.
  ///
  /// In en, this message translates to:
  /// **'Connected Banks'**
  String get connectedBanks;

  /// No description provided for @banksLinked.
  ///
  /// In en, this message translates to:
  /// **'2 external bank accounts linked'**
  String get banksLinked;

  /// No description provided for @cardsSettings.
  ///
  /// In en, this message translates to:
  /// **'Cards Settings'**
  String get cardsSettings;

  /// No description provided for @cardsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Virtual cards and blockings'**
  String get cardsSubtitle;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @darkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeLabel;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @biometricSignIn.
  ///
  /// In en, this message translates to:
  /// **'Biometric Sign-In'**
  String get biometricSignIn;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @faqsSupport.
  ///
  /// In en, this message translates to:
  /// **'FAQs and technical support'**
  String get faqsSupport;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @dataSecurity.
  ///
  /// In en, this message translates to:
  /// **'Data security policies'**
  String get dataSecurity;

  /// No description provided for @addNewTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add New Transaction'**
  String get addNewTransaction;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Target Store, Uber, Salary'**
  String get descriptionHint;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (R\$)'**
  String get amountLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @saveTransaction.
  ///
  /// In en, this message translates to:
  /// **'Save Transaction'**
  String get saveTransaction;

  /// No description provided for @transactionSaved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved successfully!'**
  String get transactionSaved;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @dining.
  ///
  /// In en, this message translates to:
  /// **'Dining'**
  String get dining;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @homeNav.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNav;

  /// No description provided for @analyticsNav.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsNav;

  /// No description provided for @walletsNav.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get walletsNav;

  /// No description provided for @settingsNav.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsNav;

  /// No description provided for @freelancePayment.
  ///
  /// In en, this message translates to:
  /// **'Freelance Payment'**
  String get freelancePayment;

  /// No description provided for @groceryStore.
  ///
  /// In en, this message translates to:
  /// **'Grocery Store'**
  String get groceryStore;

  /// No description provided for @restaurantDinner.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Dinner'**
  String get restaurantDinner;

  /// No description provided for @carInsurance.
  ///
  /// In en, this message translates to:
  /// **'Car Insurance'**
  String get carInsurance;

  /// No description provided for @netflixSubscription.
  ///
  /// In en, this message translates to:
  /// **'Netflix Subscription'**
  String get netflixSubscription;

  /// No description provided for @salaryDeposit.
  ///
  /// In en, this message translates to:
  /// **'Salary Deposit'**
  String get salaryDeposit;

  /// No description provided for @starbucksCoffee.
  ///
  /// In en, this message translates to:
  /// **'Starbucks Coffee'**
  String get starbucksCoffee;

  /// No description provided for @shellGasStation.
  ///
  /// In en, this message translates to:
  /// **'Shell Gas Station'**
  String get shellGasStation;

  /// No description provided for @smartFitGym.
  ///
  /// In en, this message translates to:
  /// **'SmartFit Gym'**
  String get smartFitGym;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @paidByLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidByLabel;

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountLabel;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedStatus;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get sessionExpiredMessage;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @manageCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage custom expense and income categories'**
  String get manageCategoriesSubtitle;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY NAME'**
  String get categoryName;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Gym, Pet, Gifts'**
  String get categoryNameHint;

  /// No description provided for @categoryIconLabel.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY ICON'**
  String get categoryIconLabel;

  /// No description provided for @categoryColorLabel.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY COLOR'**
  String get categoryColorLabel;

  /// No description provided for @saveCategory.
  ///
  /// In en, this message translates to:
  /// **'Save Category'**
  String get saveCategory;

  /// No description provided for @noCategoriesCreated.
  ///
  /// In en, this message translates to:
  /// **'No categories created'**
  String get noCategoriesCreated;

  /// No description provided for @tapToAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Tap the \"+\" button to add'**
  String get tapToAddCategory;

  /// No description provided for @expensesTab.
  ///
  /// In en, this message translates to:
  /// **'EXPENSES'**
  String get expensesTab;

  /// No description provided for @incomesTab.
  ///
  /// In en, this message translates to:
  /// **'INCOMES'**
  String get incomesTab;

  /// No description provided for @customLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customLabel;

  /// No description provided for @systemLabel.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemLabel;

  /// No description provided for @coupleLabel.
  ///
  /// In en, this message translates to:
  /// **'Couple'**
  String get coupleLabel;

  /// No description provided for @categoryCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category created successfully!'**
  String get categoryCreatedSuccess;

  /// No description provided for @categoryNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category name'**
  String get categoryNameError;

  /// No description provided for @categoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories'**
  String get categoryLoadError;

  /// No description provided for @categoryCreateError.
  ///
  /// In en, this message translates to:
  /// **'Error creating category'**
  String get categoryCreateError;

  /// No description provided for @categoryUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category updated successfully!'**
  String get categoryUpdatedSuccess;

  /// No description provided for @categoryUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating category'**
  String get categoryUpdateError;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the category \"{name}\"?'**
  String deleteCategoryConfirm(Object name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @categoryDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category deleted successfully!'**
  String get categoryDeleteSuccess;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @deleteTransactionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction? This action cannot be undone.'**
  String get deleteTransactionConfirm;

  /// No description provided for @transactionDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted successfully!'**
  String get transactionDeleteSuccess;

  /// No description provided for @transactionDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting transaction.'**
  String get transactionDeleteError;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
