import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../services/firestore_service.dart';

class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});

  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  bool _showPersonalized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Feed'),
        actions: [
          Switch(
            value: _showPersonalized,
            onChanged: (value) {
              setState(() {
                _showPersonalized = value;
              });
            },
          ),
          const SizedBox(width: 8),
          Text(_showPersonalized ? 'Personalized' : 'All Jobs'),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<Job>>(
        stream: _showPersonalized
            ? FirestoreService.getPersonalizedJobFeed()
            : FirestoreService.getJobFeed(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No jobs available'),
            );
          }

          final jobs = snapshot.data!;

          return ListView.builder(
            itemCount: jobs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final job = jobs[index];
              return JobCard(job: job);
            },
          );
        },
      ),
    );
  }
}

class JobCard extends StatefulWidget {
  final Job job;

  const JobCard({super.key, required this.job});

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isSaved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  void _checkSavedStatus() async {
    final saved = await FirestoreService.isJobSaved(widget.job.id);
    if (mounted) {
      setState(() {
        _isSaved = saved;
      });
    }
  }

  void _toggleSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSaved) {
        await FirestoreService.unsaveJob(widget.job.id);
        if (mounted) {
          setState(() {
            _isSaved = false;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job removed from saved')),
          );
        }
      } else {
        await FirestoreService.saveJob(widget.job.id);
        if (mounted) {
          setState(() {
            _isSaved = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job saved!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Company Logo
                CircleAvatar(
                  backgroundColor: Color(widget.job.logoColor),
                  child: Text(
                    widget.job.logo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Company & Position
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.job.position,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.job.company,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Featured Badge
                if (widget.job.isFeatured)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FEATURED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Job Details
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.work_outline, widget.job.type),
                _buildInfoChip(Icons.location_on_outlined, widget.job.location),
                _buildInfoChip(Icons.public, widget.job.country),
                _buildInfoChip(Icons.attach_money, widget.job.salary),
                _buildInfoChip(Icons.access_time, widget.job.postedTime),
              ],
            ),
            const SizedBox(height: 12),
            // Skills
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.job.skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  labelStyle: const TextStyle(fontSize: 12),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _toggleSave,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      color: _isSaved ? const Color(0xFFFF2D55) : null,
                    ),
                    label: Text(_isSaved ? 'Saved' : 'Save'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isSaved
                            ? const Color(0xFFFF2D55)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirestoreService.applyForJob(widget.job.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Application submitted!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Apply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2D55),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}