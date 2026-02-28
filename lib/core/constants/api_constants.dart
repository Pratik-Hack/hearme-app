class ApiConstants {
  // Node.js backend
  static const String baseUrl = 'https://hearme-server.onrender.com/api';

  // Python FastAPI chatbot server
  static const String chatbotBaseUrl = 'https://hearme-chatbot.onrender.com';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  // Users
  static const String profile = '/users/profile';

  // Doctors
  static const String doctorPatients = '/doctors/patients';

  // Patients
  static const String patientLink = '/patients/link';
  static const String patientRecords = '/patients/records';
  static const String patientDoctor = '/patients/doctor';
  static const String patientMedicalSummary = '/patients/medical-summary';

  // Mental Health
  static const String mentalHealthAnalyze = '/mental-health/analyze';
  static const String mentalHealthNotifications = '/mental-health/notifications';

  // Rewards (chatbot)
  static const String rewardsRedeem = '/rewards/redeem';

  // Rewards (Node.js backend)
  static const String rewardsStats = '/rewards/stats';
  static const String rewardsRedeemed = '/rewards/redeemed';
  static const String rewardsMindSpace = '/rewards/mindspace';
}
