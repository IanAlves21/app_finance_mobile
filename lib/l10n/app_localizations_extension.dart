import 'app_localizations.dart';

extension AppLocalizationsExtension on AppLocalizations {
  String getTransactionName(String originalName) {
    switch (originalName) {
      case "Freelance Payment":
        return freelancePayment;
      case "Grocery Store":
        return groceryStore;
      case "Restaurant Dinner":
        return restaurantDinner;
      case "Car Insurance":
        return carInsurance;
      case "Netflix Subscription":
        return netflixSubscription;
      case "Salary Deposit":
        return salaryDeposit;
      case "Starbucks Coffee":
        return starbucksCoffee;
      case "Shell Gas Station":
        return shellGasStation;
      case "SmartFit Gym":
        return smartFitGym;
      default:
        return originalName;
    }
  }
}
