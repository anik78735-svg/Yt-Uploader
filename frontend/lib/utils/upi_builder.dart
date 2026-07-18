class UpiBuilder {
  static String buildDeepLink(
      {required String upiId,
      required String appOwner,
      required String username,
      required String userId,
      required double amount}) {
    final note = 'Buy_100_Diamonds_User_${username}_ID_$userId';
    return 'upi://pay?pa=$upiId&pn=$appOwner&am=$amount&cu=INR&tn=$note';
  }
}
