import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../widgets/aurora_button.dart';
import '../widgets/glass_card.dart';

class DriverDocumentsScreen extends StatefulWidget {
  const DriverDocumentsScreen({super.key});

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isVerificationEnabled = true;
  List<Map<String, dynamic>> _fields = [];
  Map<String, dynamic>? _existingSubmission;

  // Key: fieldId -> Base64 data URI or URL
  final Map<String, String> _uploadedDocuments = {};
  // Key: fieldId -> File Name
  final Map<String, String> _fileNames = {};

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    if (auth.currentUser == null) return;

    try {
      final settings = await SupabaseService().getDriverVerificationSettings();
      _isVerificationEnabled = settings['is_enabled'] as bool? ?? false;

      final rawFields = settings['fields'] as List? ?? [];
      _fields = rawFields.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final submission = await SupabaseService().getDriverVerification(auth.currentUser!.id);
      _existingSubmission = submission;

      if (submission != null) {
        if (submission['documents'] != null) {
          final docs = Map<String, dynamic>.from(submission['documents'] as Map);
          docs.forEach((k, v) => _uploadedDocuments[k] = v.toString());
        }
        if (submission['file_names'] != null) {
          final names = Map<String, dynamic>.from(submission['file_names'] as Map);
          names.forEach((k, v) => _fileNames[k] = v.toString());
        }
      }
    } catch (e) {
      debugPrint('Load driver documents error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(String fieldId, ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _uploadedDocuments[fieldId] = base64Str;
          _fileNames[fieldId] = picked.name;
        });
      }
    } catch (e) {
      _showErrorSnackBar('تعذر التقاط/اختيار الصورة: $e');
    }
  }

  Future<void> _pickFile(String fieldId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);

        if (bytes != null) {
          final isPdf = file.extension?.toLowerCase() == 'pdf';
          final mime = isPdf ? 'application/pdf' : 'image/jpeg';
          final base64Str = 'data:$mime;base64,${base64Encode(bytes)}';

          setState(() {
            _uploadedDocuments[fieldId] = base64Str;
            _fileNames[fieldId] = file.name;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('تعذر اختيار الملف: $e');
    }
  }

  void _showSourceBottomSheet(String fieldId, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إرفاق $title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AuroraTheme.primaryBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AuroraTheme.primaryBlue),
              ),
              title: const Text('التقاط صورة بالمستمسك عبر الكاميرا', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('تصوير مباشر عالي الدقة للوثيقة'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(fieldId, ImageSource.camera);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AuroraTheme.primaryCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.folder_open_rounded, color: AuroraTheme.primaryCyan),
              ),
              title: const Text('اختيار ملف أو صورة من الهاتف (PDF / صور)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('متصفح الملفات والاستوديو'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile(fieldId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitVerification() async {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser == null) return;

    // Validate required fields
    for (final f in _fields) {
      final isReq = f['is_required'] as bool? ?? false;
      final fId = f['id'] as String? ?? '';
      final title = f['title'] as String? ?? 'المستمسك';

      if (isReq && (!_uploadedDocuments.containsKey(fId) || _uploadedDocuments[fId]!.isEmpty)) {
        _showErrorSnackBar('يرجى إرفاق: $title (حقل إجباري)');
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService().submitDriverVerification(
        driverId: auth.currentUser!.id,
        driverName: auth.currentUser!.name,
        driverPhone: auth.currentUser!.phone ?? '07800000000',
        documents: _uploadedDocuments,
        fileNames: _fileNames,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال المستمسكات بنجاح! جاري مراجعتها وتدقيقها من قبل الإدارة.'),
            backgroundColor: AuroraTheme.accentEmerald,
          ),
        );
        _loadData();
      }
    } catch (e) {
      _showErrorSnackBar('خطأ أثناء إرسال المستمسكات: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AuroraTheme.accentRose),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final status = _existingSubmission?['status'] as String? ?? 'none';
    final rejectionReason = _existingSubmission?['rejection_reason'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.isArabic ? 'توثيق ومستمسكات الكابتن' : 'Driver Verification'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verification Status Card
                  _buildStatusCard(status, rejectionReason, isDark),
                  const SizedBox(height: 20),

                  if (!_isVerificationEnabled) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AuroraTheme.accentEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AuroraTheme.accentEmerald.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AuroraTheme.accentEmerald, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'التوثيق حالياً اختياري من قبل الإدارة، يمكنك استقبال الرحلات بحرية.',
                              style: TextStyle(color: AuroraTheme.accentEmerald, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Header Guidance
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AuroraTheme.primaryBlue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: AuroraTheme.primaryBlue, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الوثائق والمستمسكات الرسمية',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'يرجى إرفاق صور واضحة أو ملفات PDF للمستمسكات المطلوبة لتفعيل حسابك ككابتن معتمد.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Document Fields List
                  ..._fields.map((f) => _buildDocumentFieldCard(f, isDark)),

                  const SizedBox(height: 24),

                  // Submit Button
                  if (status != 'approved')
                    AuroraButton(
                      text: status == 'pending' ? 'تحديث وإعادة إرسال المستمسكات' : 'إرسال المستمسكات للمراجعة والتدقيق',
                      icon: Icons.send_rounded,
                      isLoading: _isSaving,
                      onPressed: _submitVerification,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AuroraTheme.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AuroraTheme.accentEmerald.withValues(alpha: 0.4)),
                      ),
                      child: const Center(
                        child: Text(
                          'حسابك موثق ونشط بالكامل ✅',
                          style: TextStyle(color: AuroraTheme.accentEmerald, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(String status, String rejectionReason, bool isDark) {
    Color cardColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    switch (status) {
      case 'approved':
        cardColor = AuroraTheme.accentEmerald;
        textColor = Colors.white;
        icon = Icons.verified_rounded;
        title = 'تم التوثيق والقبول بنجاح ✅';
        subtitle = 'تمت مراجعة مستمسكاتك والموافقة عليها من قبل الإدارة. حسابك نشط لاستقبال الرحلات.';
        break;
      case 'pending':
        cardColor = AuroraTheme.accentAmber;
        textColor = Colors.white;
        icon = Icons.hourglass_top_rounded;
        title = 'المستمسكات قيد المراجعة والتدقيق ⏳';
        subtitle = 'تم إرسال مستمسكاتك إلى الإدارة العامة بنجاح، جاري مراجعتها وسيتم تفعيل حسابك فوراً.';
        break;
      case 'rejected':
        cardColor = AuroraTheme.accentRose;
        textColor = Colors.white;
        icon = Icons.cancel_rounded;
        title = 'تم رفض التوثيق ❌';
        subtitle = rejectionReason.isNotEmpty
            ? 'سبب الرفض: $rejectionReason\nيرجى إعادة إرفاق المستمسكات المطلوبة وتحديثها.'
            : 'يرجى مراجعة المستمسكات المرفقة وإعادة إرسالها بشكل أوضح.';
        break;
      default:
        cardColor = const Color(0xFF0284C7);
        textColor = Colors.white;
        icon = Icons.badge_rounded;
        title = 'لم يتم تقديم المستمسكات بعد';
        subtitle = 'يرجى إرفاق الوثائق الرسمية المطلوبة أدناه ليتم اعتماد حسابك في كابتن ميسان.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentFieldCard(Map<String, dynamic> field, bool isDark) {
    final fieldId = field['id'] as String? ?? '';
    final title = field['title'] as String? ?? 'مستمسك';
    final isRequired = field['is_required'] as bool? ?? false;

    final isUploaded = _uploadedDocuments.containsKey(fieldId) && _uploadedDocuments[fieldId]!.isNotEmpty;
    final docData = _uploadedDocuments[fieldId] ?? '';
    final fileName = _fileNames[fieldId] ?? '';
    final isPdf = docData.startsWith('data:application/pdf') || fileName.toLowerCase().endsWith('.pdf');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? AuroraTheme.accentEmerald.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isUploaded ? Icons.check_circle_rounded : Icons.description_rounded,
                    color: isUploaded ? AuroraTheme.accentEmerald : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isRequired
                        ? AuroraTheme.accentRose.withValues(alpha: 0.12)
                        : AuroraTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isRequired ? 'إجباري' : 'اختياري',
                    style: TextStyle(
                      color: isRequired ? AuroraTheme.accentRose : AuroraTheme.primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isUploaded)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    if (isPdf)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AuroraTheme.accentRose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: AuroraTheme.accentRose, size: 24),
                      )
                    else if (docData.startsWith('data:image'))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(docData.split(',').last),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Icon(Icons.insert_drive_file_rounded, color: AuroraTheme.primaryBlue, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName.isNotEmpty ? fileName : 'ملف تم إرفاقه بنجاح',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'جاهز للإرسال • اضغط للتغيير',
                            style: TextStyle(color: AuroraTheme.accentEmerald, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AuroraTheme.primaryCyan, size: 20),
                      onPressed: () => _showSourceBottomSheet(fieldId, title),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AuroraTheme.accentRose, size: 20),
                      onPressed: () {
                        setState(() {
                          _uploadedDocuments.remove(fieldId);
                          _fileNames.remove(fieldId);
                        });
                      },
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: () => _showSourceBottomSheet(fieldId, title),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded, color: AuroraTheme.primaryCyan, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'إرفاق الوثيقة (كاميرا / ملف / PDF)',
                        style: TextStyle(
                          color: AuroraTheme.primaryCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
