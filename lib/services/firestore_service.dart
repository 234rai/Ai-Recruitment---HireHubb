import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> testConnection() async {
    try {
      final snapshot = await _jobsCollection.limit(1).get();
      print('✅ Firestore connected. Jobs count: ${snapshot.docs.length}');
    } catch (e) {
      print('❌ Firestore error: $e');
    }
  }

  // Collection references
  static CollectionReference get _jobsCollection => _firestore.collection('jobs');

  static CollectionReference get _usersCollection => _firestore.collection('users');

  // Check if user has applied to job
  static Future<bool> hasAppliedToJob(String jobId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('applications')
          .doc(jobId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking application: $e');
      return false;
    }
  }

  // Get real-time job feed
  static Stream<List<Job>> getJobFeed() {
    return _jobsCollection
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Job.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get personalized job feed based on user skills
  static Stream<List<Job>> getPersonalizedJobFeed() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _usersCollection
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) {
        // If user doesn't exist, return regular job feed
        final snapshot = await _jobsCollection
            .orderBy('postedAt', descending: true)
            .get();
        return snapshot.docs.map((doc) {
          return Job.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      final userSkills = List<String>.from(userData?['skills'] ?? []);

      if (userSkills.isEmpty) {
        // If no skills, return regular job feed
        final snapshot = await _jobsCollection
            .orderBy('postedAt', descending: true)
            .get();
        return snapshot.docs.map((doc) {
          return Job.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      }

      // Get jobs that match user skills
      final querySnapshot = await _jobsCollection
          .where('skills', arrayContainsAny: userSkills)
          .orderBy('postedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Job.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Save job for later (Updated to use subcollection)
  static Future<void> saveJob(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Save to subcollection with timestamp
    await _usersCollection
        .doc(user.uid)
        .collection('savedJobs')
        .doc(jobId)
        .set({
      'savedAt': Timestamp.now(),
      'jobId': jobId,
    });
  }

  // Get saved jobs for the current user
  static Stream<List<Job>> getSavedJobs() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _usersCollection
        .doc(userId)
        .collection('savedJobs')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Job> jobs = [];

      for (var doc in snapshot.docs) {
        final jobId = doc.data()['jobId'] as String? ?? doc.id;
        try {
          final jobDoc = await _jobsCollection.doc(jobId).get();

          if (jobDoc.exists) {
            jobs.add(Job.fromMap(
              jobDoc.data() as Map<String, dynamic>,
              jobDoc.id,
            ));
          }
        } catch (e) {
          print('Error fetching job $jobId: $e');
        }
      }

      return jobs;
    });
  }

  // Remove job from saved
  static Future<void> unsaveJob(String jobId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _usersCollection
        .doc(userId)
        .collection('savedJobs')
        .doc(jobId)
        .delete();
  }

  // Check if job is saved
  static Future<bool> isJobSaved(String jobId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final doc = await _usersCollection
        .doc(userId)
        .collection('savedJobs')
        .doc(jobId)
        .get();

    return doc.exists;
  }

  // Apply for job
  static Future<void> applyForJob(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final application = {
      'jobId': jobId,
      'userId': user.uid,
      'appliedAt': Timestamp.now(),
      'status': 'pending',
      'userName': user.displayName,
      'userEmail': user.email,
    };

    // Store in applications collection
    await _firestore.collection('applications').add(application);

    // Also store in user's applications subcollection for quick access
    await _usersCollection
        .doc(user.uid)
        .collection('applications')
        .doc(jobId)
        .set({
      'appliedAt': Timestamp.now(),
      'status': 'pending',
    });
  }

  // Get user's applications
  static Stream<List<Map<String, dynamic>>> getUserApplications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _usersCollection
        .doc(userId)
        .collection('applications')
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> applications = [];

      for (var doc in snapshot.docs) {
        final appData = doc.data();
        final jobId = doc.id;

        try {
          final jobDoc = await _jobsCollection.doc(jobId).get();
          if (jobDoc.exists) {
            final job = Job.fromMap(
              jobDoc.data() as Map<String, dynamic>,
              jobDoc.id,
            );

            applications.add({
              'applicationId': doc.id,
              'job': job,
              'appliedAt': appData['appliedAt'],
              'status': appData['status'] ?? 'pending',
            });
          }
        } catch (e) {
          print('Error fetching application job: $e');
        }
      }

      return applications;
    });
  }

  // Get job by ID - FIXED: Use fromMap instead of fromFirestore
  static Future<Job> getJobById(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();
      if (doc.exists) {
        return Job.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      throw Exception('Job not found');
    } catch (e) {
      print('Error getting job: $e');
      throw e;
    }
  }

  // Add sample jobs to Firestore (run once)
  static Future<void> addSampleJobs() async {
    final sampleJobs = [
      {
        'company': 'Google',
        'logo': 'G',
        'logoColor': 0xFF4285F4,
        'position': 'Senior Product Manager',
        'type': 'Full-time',
        'location': 'Remote',
        'country': 'USA',
        'salary': '\$120k - \$180k',
        'postedTime': '2 hours ago',
        'isRemote': true,
        'isFeatured': true,
        'skills': ['Product Strategy', 'Agile', 'Leadership'],
        'description': 'We are looking for an experienced Product Manager to lead our core product team...',
        'requirements': [
          '5+ years of product management experience',
          'Strong analytical and problem-solving skills',
          'Experience with Agile methodologies',
          'Excellent communication and leadership abilities'
        ],
        'companyDescription': 'Google is a global technology company focused on search engine technology, cloud computing, and advertising.',
        'postedAt': Timestamp.now(),
        'searchKeywords': ['google', 'product manager', 'remote', 'senior', 'agile', 'leadership'],
      },
      {
        'company': 'Microsoft',
        'logo': 'M',
        'logoColor': 0xFF00A4EF,
        'position': 'Senior Software Engineer',
        'type': 'Full-time',
        'location': 'Hybrid',
        'country': 'UK',
        'salary': '\$100k - \$150k',
        'postedTime': '5 hours ago',
        'isRemote': false,
        'isFeatured': false,
        'skills': ['C#', '.NET', 'Azure'],
        'description': 'Join our engineering team to build scalable cloud services and applications...',
        'requirements': [
          '3+ years of software development experience',
          'Proficiency in C# and .NET framework',
          'Experience with cloud platforms (Azure preferred)',
          'Strong understanding of software architecture'
        ],
        'companyDescription': 'Microsoft is a leading technology company that develops, licenses, and supports software, services, and devices.',
        'postedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
        'searchKeywords': ['microsoft', 'software engineer', 'c#', '.net', 'azure', 'hybrid'],
      },
      {
        'company': 'Apple',
        'logo': 'A',
        'logoColor': 0xFF000000,
        'position': 'UX Designer',
        'type': 'Full-time',
        'location': 'Remote',
        'country': 'Remote',
        'salary': '\$90k - \$130k',
        'postedTime': '1 day ago',
        'isRemote': true,
        'isFeatured': false,
        'skills': ['Figma', 'UI/UX', 'Prototyping'],
        'description': 'Design beautiful and intuitive user experiences for our next-generation products...',
        'requirements': [
          '4+ years of UX design experience',
          'Proficiency in design tools (Figma, Sketch, etc.)',
          'Strong portfolio demonstrating design process',
          'Understanding of user-centered design principles'
        ],
        'companyDescription': 'Apple is a multinational technology company that designs, develops, and sells consumer electronics and software.',
        'postedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'searchKeywords': ['apple', 'ux designer', 'ui/ux', 'figma', 'remote', 'design'],
      },
      {
        'company': 'Amazon',
        'logo': 'A',
        'logoColor': 0xFFFF9900,
        'position': 'Frontend Developer',
        'type': 'Full-time',
        'location': 'Remote',
        'country': 'Canada',
        'salary': '\$85k - \$125k',
        'postedTime': '3 days ago',
        'isRemote': true,
        'isFeatured': true,
        'skills': ['React', 'TypeScript', 'CSS'],
        'description': 'Build responsive and performant web applications using modern frontend technologies...',
        'requirements': [
          '3+ years of frontend development experience',
          'Strong knowledge of React and TypeScript',
          'Experience with responsive design',
          'Familiarity with web performance optimization'
        ],
        'companyDescription': 'Amazon is a multinational technology company focusing on e-commerce, cloud computing, and artificial intelligence.',
        'postedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'searchKeywords': ['amazon', 'frontend', 'react', 'typescript', 'remote', 'developer'],
      },
      {
        'company': 'Meta',
        'logo': 'M',
        'logoColor': 0xFF0668E1,
        'position': 'Data Scientist',
        'type': 'Full-time',
        'location': 'Hybrid',
        'country': 'USA',
        'salary': '\$110k - \$160k',
        'postedTime': '1 week ago',
        'isRemote': false,
        'isFeatured': false,
        'skills': ['Python', 'Machine Learning', 'SQL'],
        'description': 'Apply data science and machine learning techniques to solve complex business problems...',
        'requirements': [
          'Masters or PhD in Data Science, Statistics, or related field',
          '3+ years of experience in data science',
          'Proficiency in Python and machine learning libraries',
          'Strong SQL and data analysis skills'
        ],
        'companyDescription': 'Meta builds technologies that help people connect, find communities, and grow businesses.',
        'postedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
        'searchKeywords': ['meta', 'data scientist', 'python', 'machine learning', 'sql', 'hybrid'],
      },
    ];

    for (final job in sampleJobs) {
      await _jobsCollection.add(job);
    }

    print('✅ Sample jobs added successfully!');
  }

  // Update user profile
  static Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _usersCollection.doc(user.uid).set(userData, SetOptions(merge: true));
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _usersCollection.doc(user.uid).get();
    return doc.data() as Map<String, dynamic>?;
  }
}