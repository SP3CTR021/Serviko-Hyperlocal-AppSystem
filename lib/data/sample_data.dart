import '../models/user_model.dart';
import '../models/service_category_model.dart';
import '../models/worker_profile_model.dart';
import '../models/worker_service_model.dart';
import '../models/booking_model.dart';
import '../models/job_post_model.dart';
import '../models/bid_model.dart';
import '../models/message_model.dart';

/// SampleData provides template/seed data used by DatabaseSeeder.
///
/// Note: These sample objects are no longer automatically loaded into the app
/// at runtime to ensure a clean slate for real database testing.
class SampleData {
  // ---------------------------------------------------------------------------
  // SAMPLE ACCOUNTS (SEED TEMPLATES)
  // ---------------------------------------------------------------------------
  static UserModel demoCustomer = UserModel(
    id: 1,
    name: 'Ana Ramos',
    fullName: 'Ana Ramos',
    firstName: 'Ana',
    lastName: 'Ramos',
    email: 'customer@serviko.com',
    phoneNumber: '09171234567',
    role: 'customer',
    city: 'Quezon City',
    barangay: 'Batasan Hills',
    isVerified: true,
  );

  // Demo Worker Users
  static UserModel demoWorker1 = UserModel(
    id: 2,
    name: 'Juan Dela Cruz',
    fullName: 'Juan Dela Cruz',
    firstName: 'Juan',
    lastName: 'Dela Cruz',
    email: 'juan@serviko.com',
    phoneNumber: '09189876543',
    role: 'worker',
    skill: 'Master Plumber',
    city: 'Quezon City',
    barangay: 'Commonwealth',
    isVerified: true,
  );

  static UserModel demoWorker2 = UserModel(
    id: 3,
    name: 'Elena Santos',
    fullName: 'Elena Santos',
    firstName: 'Elena',
    lastName: 'Santos',
    email: 'elena@serviko.com',
    phoneNumber: '09223344556',
    role: 'worker',
    skill: 'Professional Cleaner',
    city: 'Pasig City',
    barangay: 'Kapitolyo',
    isVerified: true,
  );

  static UserModel demoWorker3 = UserModel(
    id: 4,
    name: 'Mark Reyes',
    fullName: 'Mark Reyes',
    firstName: 'Mark',
    lastName: 'Reyes',
    email: 'mark@serviko.com',
    phoneNumber: '09335566778',
    role: 'worker',
    skill: 'Licensed Electrician',
    city: 'Makati City',
    barangay: 'Poblacion',
    isVerified: true,
  );

  // Service Categories
  static List<ServiceCategoryModel> categories = [
    ServiceCategoryModel(
      categoryId: 1,
      categoryName: 'Plumbing',
      description: 'Pipe repairs, faucet installs, drain unclogging & maintenance',
      displayOrder: 1,
    ),
    ServiceCategoryModel(
      categoryId: 2,
      categoryName: 'Electrical',
      description: 'Wiring, circuit breaker repair, outlet installation & lighting',
      displayOrder: 2,
    ),
    ServiceCategoryModel(
      categoryId: 3,
      categoryName: 'Home Cleaning',
      description: 'Deep house cleaning, disinfection, condo turnover cleaning',
      displayOrder: 3,
    ),
    ServiceCategoryModel(
      categoryId: 4,
      categoryName: 'Appliance Repair',
      description: 'Aircon cleaning & repair, refrigerator, washing machine fix',
      displayOrder: 4,
    ),
    ServiceCategoryModel(
      categoryId: 5,
      categoryName: 'Carpentry & Handyman',
      description: 'Furniture assembly, door fixing, cabinetry & general repairs',
      displayOrder: 5,
    ),
    ServiceCategoryModel(
      categoryId: 6,
      categoryName: 'Painting',
      description: 'Interior and exterior wall painting, waterproof coating',
      displayOrder: 6,
    ),
  ];

  // Worker Services
  static List<WorkerServiceModel> workerServices1 = [
    WorkerServiceModel(
      workerServiceId: 1,
      workerProfileId: 1,
      categoryId: 1,
      customServiceName: 'Emergency Leak Fix & Pipe Replacement',
      price: 500,
      priceType: 'hour',
      description: 'Fast diagnosis and pipe fitting with complete tools.',
      categoryName: 'Plumbing',
    ),
    WorkerServiceModel(
      workerServiceId: 2,
      workerProfileId: 1,
      categoryId: 1,
      customServiceName: 'Toilet Bowl & Sink Installation',
      price: 1500,
      priceType: 'unit',
      description: 'Sanitary fixtures setup and leak testing.',
      categoryName: 'Plumbing',
    ),
  ];

  static List<WorkerServiceModel> workerServices2 = [
    WorkerServiceModel(
      workerServiceId: 3,
      workerProfileId: 2,
      categoryId: 3,
      customServiceName: 'Full Condo Deep Cleaning',
      price: 1200,
      priceType: 'session',
      description: 'Eco-friendly supplies included. Kitchen, bath & bedrooms.',
      categoryName: 'Home Cleaning',
    ),
    WorkerServiceModel(
      workerServiceId: 4,
      workerProfileId: 2,
      categoryId: 3,
      customServiceName: 'Post-Construction Cleaning',
      price: 2500,
      priceType: 'session',
      description: 'Debris removal and thorough dust cleanup.',
      categoryName: 'Home Cleaning',
    ),
  ];

  static List<WorkerServiceModel> workerServices3 = [
    WorkerServiceModel(
      workerServiceId: 5,
      workerProfileId: 3,
      categoryId: 2,
      customServiceName: 'Circuit Breaker & Short Circuit Diagnostics',
      price: 800,
      priceType: 'hour',
      description: 'Certified electrical safety inspection and repair.',
      categoryName: 'Electrical',
    ),
  ];

  // Worker Profiles
  static List<WorkerProfileModel> workerProfiles = [
    WorkerProfileModel(
      workerProfileId: 1,
      userId: 2,
      initials: 'JD',
      avatarColor: '#00897B',
      bio: 'Master Plumber with 8+ years of residential and commercial plumbing experience. Fast response in QC area.',
      primarySkill: 'Plumbing & Pipe Repair',
      yearsOfExperience: 8,
      serviceRadiusKm: 15.0,
      basePrice: 500,
      priceType: 'hour',
      availabilityStatus: 'available',
      avgRating: 4.9,
      totalJobsCompleted: 142,
      completionRate: 99.0,
      isIdVerified: true,
      user: demoWorker1,
      services: workerServices1,
    ),
    WorkerProfileModel(
      workerProfileId: 2,
      userId: 3,
      initials: 'ES',
      avatarColor: '#E91E63',
      bio: 'Detailed and trustworthy cleaning specialist. High-grade equipment and kid/pet-friendly cleaning solutions.',
      primarySkill: 'Deep Cleaning & Disinfection',
      yearsOfExperience: 5,
      serviceRadiusKm: 10.0,
      basePrice: 1200,
      priceType: 'session',
      availabilityStatus: 'available',
      avgRating: 4.8,
      totalJobsCompleted: 98,
      completionRate: 98.0,
      isIdVerified: true,
      user: demoWorker2,
      services: workerServices2,
    ),
    WorkerProfileModel(
      workerProfileId: 3,
      userId: 4,
      initials: 'MR',
      avatarColor: '#1E88E5',
      bio: 'Licensed Master Electrician. Expert in home rewiring, lighting installs, panel upgrades, and safety testing.',
      primarySkill: 'Electrical Installation',
      yearsOfExperience: 10,
      serviceRadiusKm: 20.0,
      basePrice: 800,
      priceType: 'hour',
      availabilityStatus: 'available',
      avgRating: 5.0,
      totalJobsCompleted: 215,
      completionRate: 100.0,
      isIdVerified: true,
      user: demoWorker3,
      services: workerServices3,
    ),
  ];

  // Initial Bookings
  static List<BookingModel> bookings = [
    BookingModel(
      bookingId: 1,
      customerId: 1,
      workerId: 2,
      workerServiceId: 1,
      categoryId: 1,
      scheduledDate: DateTime.now().add(const Duration(days: 1)),
      scheduledTime: '10:00 AM',
      serviceAddress: 'Blk 4 Lot 12, Batasan Hills, Quezon City',
      jobDescription: 'Main bathroom faucet is leaking and water pressure is very low.',
      status: 'accepted',
      isUrgent: true,
      totalAmount: 500.00,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      customer: demoCustomer,
      worker: demoWorker1,
      serviceName: 'Emergency Leak Fix & Pipe Replacement',
      categoryName: 'Plumbing',
    ),
    BookingModel(
      bookingId: 2,
      customerId: 1,
      workerId: 3,
      workerServiceId: 3,
      categoryId: 3,
      scheduledDate: DateTime.now().add(const Duration(days: 3)),
      scheduledTime: '02:00 PM',
      serviceAddress: 'Blk 4 Lot 12, Batasan Hills, Quezon City',
      jobDescription: '2-Bedroom condo general deep cleaning before visitors arrive.',
      status: 'pending',
      isUrgent: false,
      totalAmount: 1200.00,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      customer: demoCustomer,
      worker: demoWorker2,
      serviceName: 'Full Condo Deep Cleaning',
      categoryName: 'Home Cleaning',
    ),
  ];

  // Initial Job Posts
  static List<JobPostModel> jobPosts = [
    JobPostModel(
      jobPostId: 1,
      customerId: 1,
      categoryId: 2,
      title: 'Fix tripping circuit breaker in kitchen',
      description: 'Every time we turn on the microwave and induction stove, the kitchen breaker trips. Need a licensed electrician to diagnose.',
      locationAddress: 'Batasan Hills, Quezon City',
      city: 'Quezon City',
      barangay: 'Batasan Hills',
      budgetMin: 800,
      budgetMax: 1500,
      preferredDate: DateTime.now().add(const Duration(days: 2)),
      urgency: 'urgent',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      customer: demoCustomer,
      categoryName: 'Electrical',
      bids: [
        BidModel(
          bidId: 1,
          jobPostId: 1,
          workerId: 4,
          proposedPrice: 1000,
          message: 'Hello Ana! I can inspect this tomorrow morning. I have full electrical diagnostic testing equipment.',
          estimatedDuration: '2 hours',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          worker: demoWorker3,
        ),
      ],
    ),
  ];

  // Initial Messages
  static List<MessageModel> messages = [
    MessageModel(
      messageId: 1,
      bookingId: 1,
      senderId: 1,
      receiverId: 2,
      content: 'Hi Juan! Just confirming if you will bring your own pipe wrench?',
      isRead: true,
      sentAt: DateTime.now().subtract(const Duration(hours: 2)),
      sender: demoCustomer,
      receiver: demoWorker1,
    ),
    MessageModel(
      messageId: 2,
      bookingId: 1,
      senderId: 2,
      receiverId: 1,
      content: 'Yes! Complete tools and standard replacement seals are ready. See you tomorrow at 10:00 AM.',
      isRead: true,
      sentAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      sender: demoWorker1,
      receiver: demoCustomer,
    ),
  ];
}
