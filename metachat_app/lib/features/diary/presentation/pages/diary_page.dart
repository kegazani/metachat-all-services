import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import 'package:metachat_app/core/network/api_client.dart';
import 'package:metachat_app/shared/widgets/glass_app_bar.dart';
import 'package:metachat_app/shared/widgets/glass_button.dart';
import 'package:metachat_app/shared/widgets/glass_card.dart';
import 'package:metachat_app/shared/widgets/glass_text_field.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  List<Map<String, dynamic>> entries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    
    try {
      final box = Hive.box('app');
      final userId = box.get('userId')?.toString();
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          setState(() {
            entries = [];
            loading = false;
          });
        }
        return;
      }
      
      final api = GetIt.instance<ApiClient>();
      final response = await api.get('/diary/entries/user/$userId');
      
      if (response.data is List) {
        final list = List<Map<String, dynamic>>.from(
          (response.data as List).map((e) => Map<String, dynamic>.from(e)),
        );
        if (mounted) {
          setState(() {
            entries = list;
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            entries = [];
            loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> addEntry() async {
    if (!mounted) return;
    
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    String? savedTitle;
    String? savedContent;
    
    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (modalContext) {
          return StatefulBuilder(
            builder: (builderContext, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(builderContext).viewInsets.bottom + 16,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassTextField(
                        controller: titleController,
                        hint: 'Заголовок',
                      ),
                      const SizedBox(height: 12),
                      GlassTextField(
                        controller: contentController,
                        hint: 'Запись',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 16),
                      GlassButton(
                        label: 'Сохранить',
                        onPressed: () {
                          savedTitle = titleController.text;
                          savedContent = contentController.text;
                          Navigator.of(builderContext).pop(true);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
      
      savedTitle = savedTitle ?? titleController.text;
      savedContent = savedContent ?? contentController.text;
      
      titleController.dispose();
      contentController.dispose();
      
      if (result != true || 
          (savedTitle?.isEmpty ?? true) || 
          (savedContent?.isEmpty ?? true)) {
        return;
      }
      
      if (!mounted) return;
    } catch (e) {
      titleController.dispose();
      contentController.dispose();
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка при открытии формы'),
            ),
          );
        } catch (_) {}
      }
      return;
    }
    
    try {
      if (!mounted) return;
      
      final box = Hive.box('app');
      final userId = box.get('userId')?.toString();
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ошибка: пользователь не найден'),
              ),
            );
          } catch (_) {}
        }
        return;
      }
      
      final api = GetIt.instance<ApiClient>();
      final response = await api.post(
        '/diary/entries',
        body: {
          'user_id': userId,
          'title': savedTitle!,
          'content': savedContent!,
          'token_count': savedContent!.length,
        },
      );
      
      if (!mounted) return;
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        await load();
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Запись успешно сохранена'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (_) {}
        }
      } else {
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Не удалось сохранить запись: ${response.statusCode}'),
              ),
            );
          } catch (_) {}
        }
      }
    } catch (e) {
      if (mounted) {
        try {
          final errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Не удалось сохранить запись';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 4),
            ),
          );
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(
        title: 'Дневник',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final item = entries[index];
                  final title = item['title']?.toString() ?? 'Без заголовка';
                  final content =
                      item['content']?.toString() ?? 'Пустая запись';
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          content,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addEntry,
        backgroundColor: const Color(0xFF7DD3FC),
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
    );
  }
}


