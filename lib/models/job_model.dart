import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String company;
  final String logo;
  final int logoColor;
  final String position;
  final String type;
  final String location;
  final String country;
  final String salary;
  final String postedTime;
  final bool isRemote;
  final bool isFeatured;
  final List<String> skills;
  final String description;
  final List<String> requirements;
  final String companyDescription;
  final Timestamp postedAt;
  final List<String> searchKeywords;

  Job({
    required this.id,
    required this.company,
    required this.logo,
    required this.logoColor,
    required this.position,
    required this.type,
    required this.location,
    required this.country,
    required this.salary,
    required this.postedTime,
    required this.isRemote,
    required this.isFeatured,
    required this.skills,
    required this.description,
    required this.requirements,
    required this.companyDescription,
    required this.postedAt,
    required this.searchKeywords,
  });

  factory Job.fromMap(Map<String, dynamic> data, String id) {
    return Job(
      id: id,
      company: data['company'] ?? 'Unknown Company',
      logo: data['logo'] ?? '?',
      logoColor: data['logoColor'] ?? 0xFFFF2D55,
      position: data['position'] ?? 'No Position',
      type: data['type'] ?? 'Full-time',
      location: data['location'] ?? 'Unknown Location',
      country: data['country'] ?? 'Unknown Country',
      salary: data['salary'] ?? 'Salary not specified',
      postedTime: data['postedTime'] ?? 'Recently',
      isRemote: data['isRemote'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      skills: List<String>.from(data['skills'] ?? []),
      description: data['description'] ?? 'No description available.',
      requirements: List<String>.from(data['requirements'] ?? []),
      companyDescription: data['companyDescription'] ?? 'No company description available.',
      postedAt: data['postedAt'] ?? Timestamp.now(),
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'company': company,
      'logo': logo,
      'logoColor': logoColor,
      'position': position,
      'type': type,
      'location': location,
      'country': country,
      'salary': salary,
      'postedTime': postedTime,
      'isRemote': isRemote,
      'isFeatured': isFeatured,
      'skills': skills,
      'description': description,
      'requirements': requirements,
      'companyDescription': companyDescription,
      'postedAt': postedAt,
      'searchKeywords': searchKeywords,
    };
  }
}