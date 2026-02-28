import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/api_service.dart';
import 'package:hearme/core/constants/api_constants.dart';

class MindSpaceHistoryScreen extends StatefulWidget {
  const MindSpaceHistoryScreen({super.key});

  @override
  State<MindSpaceHistoryScreen> createState() => _MindSpaceHistoryScreenState();
}

class _MindSpaceHistoryScreenState extends State<MindSpaceHistoryScreen> {
  List<dynamic> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final data = await ApiService.get(ApiConstants.historyMindspace);
      setState(() {
        _records = data['records'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteRecord(String id, int index) async {
    try {
      await ApiService.delete('${ApiConstants.historyMindspace}/$id');
      setState(() => _records.removeAt(index));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _confirmDelete(String id, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Delete this MindSpace record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteRecord(id, index);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return const Color(0xFF4ECDC4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MindSpace History',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(color: AppTheme.primaryOrange),
              )
            : RefreshIndicator(
                onRefresh: _loadRecords,
                color: AppTheme.primaryOrange,
                child: _records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.psychology_outlined,
                              size: 64,
                              color: isDark
                                  ? AppTheme.darkTextDim
                                  : AppTheme.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No MindSpace records yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? AppTheme.darkTextGray
                                    : AppTheme.textGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your voice check-ins will appear here',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.darkTextDim
                                    : AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppTheme.spacingMedium),
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          final record = _records[index];
                          final id =
                              record['_id'] ?? record['id'] ?? '';
                          final response =
                              record['response'] ?? '';
                          final urgency =
                              record['urgency'] ?? 'low';
                          final coins =
                              record['coinsEarned'] ?? 0;
                          final date = record['createdAt'] != null
                              ? DateTime.tryParse(record['createdAt'])
                              : null;
                          final dateStr = date != null
                              ? '${date.day}/${date.month}/${date.year}'
                              : '';
                          final urgencyColor = _getUrgencyColor(urgency);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () => _openDetail(record, isDark),
                              child: GlassCard(
                                padding: const EdgeInsets.all(
                                    AppTheme.spacingMedium),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7C4DFF)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.psychology_rounded,
                                            color: Color(0xFF7C4DFF),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                dateStr,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: isDark
                                                      ? AppTheme
                                                          .darkTextLight
                                                      : AppTheme.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: urgencyColor
                                                          .withValues(
                                                              alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(8),
                                                    ),
                                                    child: Text(
                                                      urgency,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            urgencyColor,
                                                      ),
                                                    ),
                                                  ),
                                                  if (coins > 0) ...[
                                                    const SizedBox(
                                                        width: 8),
                                                    Text(
                                                      '+$coins coins',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDark
                                                            ? AppTheme
                                                                .darkTextDim
                                                            : AppTheme
                                                                .textLight,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _confirmDelete(id, index),
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: isDark
                                                ? AppTheme.darkTextDim
                                                : AppTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      response,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: isDark
                                            ? AppTheme.darkTextGray
                                            : AppTheme.textGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(
                              delay:
                                  Duration(milliseconds: 50 * index));
                        },
                      ),
              ),
      ),
    );
  }

  void _openDetail(dynamic record, bool isDark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MindSpaceDetailScreen(
          response: record['response'] ?? '',
          transcript: record['transcript'] ?? '',
          urgency: record['urgency'] ?? 'low',
          coinsEarned: record['coinsEarned'] ?? 0,
          createdAt: record['createdAt'],
        ),
      ),
    );
  }
}

class _MindSpaceDetailScreen extends StatelessWidget {
  final String response;
  final String transcript;
  final String urgency;
  final int coinsEarned;
  final String? createdAt;

  const _MindSpaceDetailScreen({
    required this.response,
    required this.transcript,
    required this.urgency,
    required this.coinsEarned,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final date =
        createdAt != null ? DateTime.tryParse(createdAt!) : null;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MindSpace - $dateStr',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Response card
              GlassCard(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF7C4DFF),
                                Color(0xFF536DFE),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'MindBot Response',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.darkTextLight
                                : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      response,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark
                            ? AppTheme.darkTextGray
                            : AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),

              if (transcript.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingMedium),
                GlassCard(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Words',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextLight
                              : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        transcript,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppTheme.darkTextDim
                              : AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
