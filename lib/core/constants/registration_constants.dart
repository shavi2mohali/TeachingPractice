class RegistrationConstants {
  static const List<String> roles = [
    'College',
    'School',
    'DEO',
    'DIET',
  ];

  static const List<String> districts = [
    'Amritsar',
    'Bathinda',
    'Jalandhar',
    'Ludhiana',
    'Mansa',
    'Patiala',
    'Sangrur',
    'SAS Nagar',
  ];

  static const String pendingApprovalMessage =
      'Your registration is pending approval from the admin side. '
      'You will be able to login once approved.';

  static const String loginPendingMessage = 'Approval pending from the admin side';

  static const String registrationPendingMessage =
      'Your registration is pending approval from the admin side. '
      'You will be able to login once approved.';

  const RegistrationConstants._();
}
