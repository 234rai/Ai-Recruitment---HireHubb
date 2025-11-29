// lib/screens/ai_resume_checker_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AIResumeCheckerScreen extends StatefulWidget {
  const AIResumeCheckerScreen({super.key});

  @override
  State<AIResumeCheckerScreen> createState() => _AIResumeCheckerScreenState();
}

class _AIResumeCheckerScreenState extends State<AIResumeCheckerScreen> {
  bool _isAnalyzing = false;
  String _selectedFileName = '';
  Map<String, dynamic>? _analysisResult;

  void _pickAndAnalyzeResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        PlatformFile file = result.files.single;

        setState(() {
          _selectedFileName = file.name;
          _isAnalyzing = true;
          _analysisResult = null;
        });

        // TODO: Replace with your custom machine learning model integration
        // This is where you'll call your ML model API
        await Future.delayed(const Duration(seconds: 2)); // Simulate API call

        // TODO: Replace with actual ML model response
        // setState(() {
        //   _isAnalyzing = false;
        //   _analysisResult = yourMlModelResponse;
        // });

        // For now, keeping the interface ready but no static data
        setState(() {
          _isAnalyzing = false;
          // _analysisResult remains null to show empty state
        });
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing resume: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetAnalysis() {
    setState(() {
      _selectedFileName = '';
      _analysisResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AI Resume Checker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView( // ADDED: Prevent overflow with scroll
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'AI-Powered Resume Analysis',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get instant feedback on your resume from our AI analyzer',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            if (_analysisResult == null && !_isAnalyzing) ..._buildUploadSection(isDarkMode),
            if (_isAnalyzing) ..._buildAnalysisProgress(isDarkMode),
            if (_analysisResult != null) ..._buildAnalysisResult(_analysisResult!, isDarkMode),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUploadSection(bool isDarkMode) {
    return [
      // Custom dashed border container
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.upload_file,
              size: 64,
              color: const Color(0xFFFF2D55),
            ),
            const SizedBox(height: 16),
            Text(
              'Upload Your Resume',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supported formats: PDF, DOC, DOCX\nMax file size: 10MB',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickAndAnalyzeResume,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2D55),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Choose File',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (_selectedFileName.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedFileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis, // ADDED: Prevent text overflow
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    ];
  }

  List<Widget> _buildAnalysisProgress(bool isDarkMode) {
    return [
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFFF2D55),
              strokeWidth: 8,
            ),
            const SizedBox(height: 20),
            Text(
              'Analyzing your resume...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Processing with AI model',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildAnalysisResult(Map<String, dynamic> result, bool isDarkMode) {
    return [
      // Overall Score
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF2D55).withOpacity(0.1),
              const Color(0xFFFF2D55).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              'Overall Score',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: result['score'] / 100,
                    color: const Color(0xFFFF2D55),
                    strokeWidth: 12,
                    backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                Text(
                  '${result['score']}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF2D55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // FIXED: Wrap metrics in Expanded and Flexible to prevent overflow
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric('ATS Score', result['atsScore'], isDarkMode),
                    _buildMetric('Skills Match', result['skillsMatch'], isDarkMode),
                    _buildMetric('Readability', result['readabilityScore'], isDarkMode),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Strengths
      if (result['strengths'] != null && result['strengths'].isNotEmpty)
        _buildSection('Strengths', result['strengths'], Icons.check_circle, const Color(0xFF10B981), isDarkMode),
      if (result['strengths'] != null && result['strengths'].isNotEmpty) const SizedBox(height: 24),

      // Improvements
      if (result['improvements'] != null && result['improvements'].isNotEmpty)
        _buildSection('Areas for Improvement', result['improvements'], Icons.lightbulb_outline, const Color(0xFFFFB800), isDarkMode),
      if (result['improvements'] != null && result['improvements'].isNotEmpty) const SizedBox(height: 32),

      // Empty state when no analysis data
      if ((result['strengths'] == null || result['strengths'].isEmpty) &&
          (result['improvements'] == null || result['improvements'].isEmpty))
        _buildEmptyAnalysisState(isDarkMode),

      // Action Buttons
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetAnalysis,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
              child: Text(
                'Analyze Another',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement resume optimization with your ML model
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Resume optimization feature coming soon!'),
                    backgroundColor: Color(0xFFFF2D55),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2D55),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Optimize Now',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildMetric(String title, int score, bool isDarkMode) {
    return Flexible( // ADDED: Flexible to prevent overflow
      child: Column(
        children: [
          Text(
            '$score%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF2D55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded( // ADDED: Expanded to prevent text overflow
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ADDED: Empty state for when ML model returns no data
  Widget _buildEmptyAnalysisState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: const Color(0xFFFF2D55),
          ),
          const SizedBox(height: 16),
          Text(
            'Analysis Complete',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your resume has been processed.\nConnect your ML model to see detailed analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}