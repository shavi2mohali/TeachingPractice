import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/firebase/firestore_service.dart';
import '../../data/services/file_download_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';

class CorrectionRequestsPage extends StatefulWidget {
  const CorrectionRequestsPage({super.key});

  @override
  State<CorrectionRequestsPage> createState() => _CorrectionRequestsPageState();
}

class _CorrectionRequestsPageState extends State<CorrectionRequestsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> _processingIds = <String>{};
  late final _collegesStream = FirebaseFirestore.instance
      .collection('colleges')
      .snapshots();
  String? _selectedCollegeId;
  String? _shownCollegeId;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _requestsStream;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correction Requests'),
        actions: const [HomeLogoutActions()],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _collegesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load colleges: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final collegeNames = <String, String>{
            for (final doc in snapshot.data!.docs)
              doc.id:
                  doc.data()['name'] as String? ??
                  doc.data()['shortName'] as String? ??
                  doc.id,
          };
          final colleges = collegeNames.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));
          final selectedId = collegeNames.containsKey(_selectedCollegeId)
              ? _selectedCollegeId
              : null;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(selectedId),
                        initialValue: selectedId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select College',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final college in colleges)
                            DropdownMenuItem(
                              value: college.key,
                              child: Text(
                                college.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() {
                          _selectedCollegeId = value;
                          _shownCollegeId = null;
                          _requestsStream = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: selectedId == null
                          ? null
                          : () => setState(() {
                              _shownCollegeId = selectedId;
                              _requestsStream = FirebaseFirestore.instance
                                  .collection('correction_requests')
                                  .where('collegeId', isEqualTo: selectedId)
                                  .snapshots();
                            }),
                      child: const Text('Show'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    _requestsStream == null ||
                        !collegeNames.containsKey(_shownCollegeId)
                    ? const Center(
                        child: Text(
                          'Select a college to view correction requests',
                        ),
                      )
                    : _buildRequests(collegeNames),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequests(Map<String, String> collegeNames) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey(_shownCollegeId),
      stream: _requestsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load correction requests: ${snapshot.error}',
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Firestore filters by college; sort only that college's results here
        // to retain newest-first ordering without requiring a composite index.
        final requests = [...?snapshot.data?.docs]
          ..sort((a, b) {
            final first = a.data()['createdAt'];
            final second = b.data()['createdAt'];
            return (second is Timestamp ? second.millisecondsSinceEpoch : 0)
                .compareTo(
                  first is Timestamp ? first.millisecondsSinceEpoch : 0,
                );
          });

        if (requests.isEmpty) {
          return const Center(
            child: Text('No correction requests found for this college'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data();
            final requestId = data['requestId'] as String? ?? request.id;
            final isProcessing = _processingIds.contains(requestId);
            final status = (data['status'] as String? ?? 'pending').trim();
            final statusColor = switch (status) {
              'approved' => Colors.green,
              'rejected' => Colors.red,
              _ => Colors.orange,
            };
            final collegeId = data['collegeId'] as String? ?? '';
            final collegeName = collegeNames[collegeId] ?? collegeId;

            return Card(
              child: ExpansionTile(
                title: Text(
                  data['registrationId'] as String? ??
                      data['studentId'] as String? ??
                      '',
                ),
                subtitle: Text(
                  '${data['studentName'] as String? ?? ''}  |  $collegeName',
                ),
                trailing: Chip(
                  label: Text(status.toUpperCase()),
                  backgroundColor: statusColor.withOpacity(0.12),
                  labelStyle: TextStyle(color: statusColor),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _InfoRow(label: 'College Name', value: collegeName),
                  _InfoRow(
                    label: 'Name Correction in English',
                    value: data['nameCorrectionEnglish'] as String? ?? '',
                  ),
                  _InfoRow(
                    label: 'Name in Punjabi',
                    value: data['namePunjabi'] as String? ?? '',
                  ),
                  _InfoRow(
                    label: 'Father Name Correction in English',
                    value: data['fatherNameCorrectionEnglish'] as String? ?? '',
                  ),
                  _InfoRow(
                    label: 'Father Name in Punjabi',
                    value: data['fatherNamePunjabi'] as String? ?? '',
                  ),
                  _InfoRow(
                    label: 'Mother Name Correction in English',
                    value: data['motherNameCorrectionEnglish'] as String? ?? '',
                  ),
                  _InfoRow(
                    label: 'Mother Name in Punjabi',
                    value: data['motherNamePunjabi'] as String? ?? '',
                  ),
                  _InfoRow(
                    label: 'Requested On',
                    value: _formatDateTime(data['createdAt']),
                  ),
                  if (data['reviewedAt'] != null)
                    _InfoRow(
                      label: 'Reviewed On',
                      value: _formatDateTime(data['reviewedAt']),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _downloadCertificate(data),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('View PDF'),
                      ),
                      if (status == 'pending')
                        FilledButton(
                          onPressed: isProcessing
                              ? null
                              : () => _approveRequest(data),
                          child: isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Approve'),
                        ),
                      if (status == 'pending')
                        OutlinedButton(
                          onPressed: isProcessing
                              ? null
                              : () => _rejectRequest(data),
                          child: const Text('Reject'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: requests.length,
        );
      },
    );
  }

  Future<void> _downloadCertificate(Map<String, dynamic> data) async {
    final blob = data['certificatePdf'];
    if (blob is! Blob) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate PDF not found.')),
      );
      return;
    }

    await downloadBytes(
      bytes: blob.bytes,
      fileName: data['certificateFileName'] as String? ?? 'certificate.pdf',
      mimeType: data['certificateMimeType'] as String? ?? 'application/pdf',
    );
  }

  Future<void> _approveRequest(Map<String, dynamic> data) async {
    final requestId = data['requestId'] as String? ?? '';
    if (requestId.isEmpty) return;

    setState(() => _processingIds.add(requestId));

    try {
      final reviewerId =
          context.read<AuthProvider>().currentUser?.uid ?? 'admin';
      await _firestoreService.approveCorrectionRequest(
        requestId: requestId,
        studentId: data['studentId'] as String? ?? '',
        reviewedBy: reviewerId,
        nameCorrectionEnglish: data['nameCorrectionEnglish'] as String? ?? '',
        namePunjabi: data['namePunjabi'] as String? ?? '',
        fatherNameCorrectionEnglish:
            data['fatherNameCorrectionEnglish'] as String? ?? '',
        fatherNamePunjabi: data['fatherNamePunjabi'] as String? ?? '',
        motherNameCorrectionEnglish:
            data['motherNameCorrectionEnglish'] as String? ?? '',
        motherNamePunjabi: data['motherNamePunjabi'] as String? ?? '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correction request approved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to approve request: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(requestId));
      }
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> data) async {
    final remarks = await _showRejectRemarksDialog();
    if (remarks == null) {
      return;
    }

    final requestId = data['requestId'] as String? ?? '';
    if (requestId.isEmpty) return;

    setState(() => _processingIds.add(requestId));

    try {
      final reviewerId =
          context.read<AuthProvider>().currentUser?.uid ?? 'admin';
      await _firestoreService.rejectCorrectionRequest(
        requestId: requestId,
        studentId: data['studentId'] as String? ?? '',
        reviewedBy: reviewerId,
        remarks: remarks,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correction request rejected.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to reject request: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(requestId));
      }
    }
  }

  Future<String?> _showRejectRemarksDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject Correction Request'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Remarks',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final remarks = controller.text.trim();
                if (remarks.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(remarks);
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  String _formatDateTime(dynamic value) {
    if (value is! Timestamp) {
      return '';
    }

    final date = value.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = (date.hour % 12 == 0 ? 12 : date.hour % 12).toString().padLeft(
      2,
      '0',
    );
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year $hour:$minute $suffix';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
