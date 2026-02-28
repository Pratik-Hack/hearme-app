class ApiConstants {
  // Node.js backend
  static const String baseUrl = 'http://10.1.231.224:5000/api';

  // Python FastAPI chatbot server
  static const String chatbotBaseUrl = 'http://10.1.231.224:8000';

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

  // Rewards
  static const String rewardsRedeem = '/rewards/redeem';

  // Vitals Monitoring (Python chatbot server)
  static const String vitalsStart = '/vitals/start';
  static const String vitalsTick = '/vitals/tick';
  static const String vitalsDoctorAlerts = '/vitals/alerts/doctor';
  static const String vitalsPatientAlerts = '/vitals/alerts/patient';
  static const String vitalsSession = '/vitals/session';

  // Vitals Summaries (Node.js server)
  static const String vitalsSummary = '/vitals/summary';
  static const String vitalsSummaries = '/vitals/summaries';
}
