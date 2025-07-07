import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:future_self/features/onboarding/domain/entities/onboarding_question.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:image_picker/image_picker.dart';

class QuestionPage extends StatelessWidget {
  final OnboardingQuestion question;

  const QuestionPage({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _buildInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    switch (question.type) {
      case QuestionType.date:
        return _buildDatePicker(context);
      case QuestionType.dropdown:
        return _buildDropdown(context);
      case QuestionType.image:
        return _buildImagePicker(context);
      case QuestionType.text:
      default:
        return _buildTextField(context);
    }
  }

  Widget _buildTextField(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: 'Your answer here...',
      ),
      onChanged: (value) {
        context.read<OnboardingBloc>().add(
              AnswerUpdated({question.key: value}),
            );
      },
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(
                  context), // Use the Cosmic Dream theme for the picker
              child: child!,
            );
          },
        );
        if (picked != null) {
          context.read<OnboardingBloc>().add(
                AnswerUpdated({question.key: picked}),
              );
        }
      },
      child: const Text('Select Date'),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(),
      items: question.options?.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          context.read<OnboardingBloc>().add(
                AnswerUpdated({question.key: value}),
              );
        }
      },
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final imagePath = state.onboardingData.photoPath;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  context.read<OnboardingBloc>().add(
                        AnswerUpdated({question.key: image.path}),
                      );
                }
              },
              label: const Text('Upload a Photo'),
            ),
          ],
        );
      },
    );
  }
}
