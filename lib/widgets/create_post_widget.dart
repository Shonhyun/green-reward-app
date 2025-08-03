import 'package:flutter/material.dart';
import '../services/forum_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class CreatePostWidget extends StatefulWidget {
  final VoidCallback? onPostCreated;
  final VoidCallback? onPostUpdated;
  final String? postId;
  final String? initialContent;
  final String? initialCategory;
  final String? initialImageBase64;

  const CreatePostWidget({
    super.key,
    this.onPostCreated,
    this.onPostUpdated,
    this.postId,
    this.initialContent,
    this.initialCategory,
    this.initialImageBase64,
  });

  @override
  State<CreatePostWidget> createState() => _CreatePostWidgetState();
}

class _CreatePostWidgetState extends State<CreatePostWidget> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  String _selectedCategory = 'General Discussion';
  bool _isLoading = false;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    if (widget.initialImageBase64 != null) {
      _imageBase64 = widget.initialImageBase64!;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Ensure image_picker is supported on the platform
      if (!kIsWeb && !(await _picker.supportsImageSource(ImageSource.gallery))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image picker not supported on this platform'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Limit resolution to reduce size
        maxHeight: 800,
        imageQuality: 85, // Compress image
      );
      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No image selected'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final bytes = kIsWeb
          ? await image.readAsBytes()
          : await File(image.path).readAsBytes();
      final base64String = base64Encode(bytes);

      // Validate size (1MB limit to stay within Firestore document size)
      if (base64String.length > 1 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image size exceeds 1MB limit'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _imageBase64 = base64String;
      });
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (widget.postId != null) {
        success = await ForumService.updatePost(
          postId: widget.postId!,
          content: _contentController.text.trim(),
          category: _selectedCategory,
          imageBase64: _imageBase64,
        );
        if (success) {
          _contentController.clear();
          setState(() {
            _imageBase64 = null;
          });
          widget.onPostUpdated?.call();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post updated successfully!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update post. You may not have permission.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        success = await ForumService.createPost(
          content: _contentController.text.trim(),
          category: _selectedCategory,
          imageBase64: _imageBase64,
        );
        if (success) {
          _contentController.clear();
          setState(() {
            _imageBase64 = null;
          });
          widget.onPostCreated?.call();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create post. Please ensure you are logged in.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error submitting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ForumService.getCategories();
    final isEditing = widget.postId != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Post' : 'Create New Post',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212529),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          items: categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isEditing ? 'Edit your post' : 'What would you like to share?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212529),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 8,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: isEditing ? 'Edit your thoughts, questions, or tips...' : 'Share your thoughts, questions, or tips...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter some content';
                        }
                        if (value.trim().length < 1) {
                          return 'Content must be at least 1 character long';
                        }
                        if (value.trim().length > 500) {
                          return 'Content must be 500 characters or less';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _imageBase64 != null
                              ? Image.memory(
                                  base64Decode(_imageBase64!),
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Text('Error loading image'),
                                )
                              : const Text('No image selected'),
                        ),
                        IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image, color: Color(0xFF4CAF50)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community Guidelines:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Be respectful and constructive\n• Share helpful tips and experiences\n• Ask questions to learn from others\n• Keep content relevant to environmental topics',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? 'Update Post' : 'Create Post',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}