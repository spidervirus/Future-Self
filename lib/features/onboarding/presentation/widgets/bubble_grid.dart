import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import 'package:country_picker/country_picker.dart';
import 'package:future_self/app/theme/cosmic_dream_theme.dart';
import 'package:future_self/features/onboarding/domain/entities/onboarding_question.dart';
import 'response_bubble.dart';

class BubbleGrid extends StatefulWidget {
  final OnboardingQuestion question;
  final String? selectedValue;
  final ValueChanged<String>? onBubbleSelected;
  final VoidCallback? onCustomInput;
  final bool isVisible;

  const BubbleGrid({
    super.key,
    required this.question,
    this.selectedValue,
    this.onBubbleSelected,
    this.onCustomInput,
    this.isVisible = true,
  });

  @override
  State<BubbleGrid> createState() => _BubbleGridState();
}

class _BubbleGridState extends State<BubbleGrid> {
  String? _customValue;
  bool _showCustomInput = false;

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResponseBubbles(),
            if (_shouldShowCustomInput()) ...[
              const SizedBox(height: 16),
              _buildCustomInputSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponseBubbles() {
    switch (widget.question.type) {
      case QuestionType.dropdown:
        return _buildDropdownBubbles();
      case QuestionType.text:
        return _buildTextInputBubbles();
      case QuestionType.date:
        return _buildDateBubbles();
      case QuestionType.image:
        return _buildImageBubbles();
      case QuestionType.country:
        return _buildCountryBubbles();
    }
  }

  Widget _buildDropdownBubbles() {
    if (widget.question.options == null || widget.question.options!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildAdaptiveGrid(
      children: AnimationConfiguration.toStaggeredList(
        duration: const Duration(milliseconds: 400),
        childAnimationBuilder: (widget) => SlideAnimation(
          horizontalOffset: 50.0,
          child: FadeInAnimation(child: widget),
        ),
        children: widget.question.options!.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;

          return ResponseBubble(
            text: option,
            isSelected: widget.selectedValue == option,
            isVisible: widget.isVisible,
            onTap: () => widget.onBubbleSelected?.call(option),
            animationDelay: index * 100,
            icon: _getIconForOption(option),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextInputBubbles() {
    final predefinedOptions = _getPredefinedOptionsForQuestion();

    return Column(
      children: [
        if (predefinedOptions.isNotEmpty)
          _buildAdaptiveGrid(
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 400),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: predefinedOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;

                return ResponseBubble(
                  text: option,
                  isSelected: widget.selectedValue == option,
                  isVisible: widget.isVisible,
                  onTap: () => widget.onBubbleSelected?.call(option),
                  animationDelay: index * 100,
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 16),
        _buildCustomInputBubble(),
      ],
    );
  }

  Widget _buildDateBubbles() {
    final hasSelectedDate = widget.selectedValue != null &&
        widget.selectedValue!.isNotEmpty &&
        widget.selectedValue != 'skipped';

    return Column(
      children: [
        // Display selected date prominently if one is chosen
        if (hasSelectedDate)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: CosmicDreamTheme.questionBubbleGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: CosmicDreamTheme.cosmicTeal.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: CosmicDreamTheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: CosmicDreamTheme.accent,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Birthday',
                  style: TextStyle(
                    color: CosmicDreamTheme.text.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatSelectedDate(),
                  style: const TextStyle(
                    color: CosmicDreamTheme.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        if (hasSelectedDate) const SizedBox(height: 16),

        // Date input options
        _buildAdaptiveGrid(
      children: [
        ResponseBubble(
              text: hasSelectedDate ? "Change Date" : "Select from Calendar",
          icon: Icons.calendar_today,
          isVisible: widget.isVisible,
          onTap: () => _showDatePicker(),
          customColor: CosmicDreamTheme.cosmicTeal,
        ),
          ResponseBubble(
              text: "Type Date",
              icon: Icons.edit,
              isVisible: widget.isVisible,
              onTap: () => setState(() => _showCustomInput = true),
              customColor: CosmicDreamTheme.accent,
            ),
          ],
        ),

        // Text input field for typing date
        if (_showCustomInput) ...[
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomInputBubble(
              hintText: "MM/DD/YYYY or type naturally (e.g., Jan 15, 1990)",
              initialValue:
                  hasSelectedDate ? _formatSelectedDateForInput() : '',
              onChanged: (value) => _handleDateInput(value),
            isVisible: widget.isVisible,
              animationDelay: 200,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _showCustomInput = false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: CosmicDreamTheme.text.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageBubbles() {
    return _buildAdaptiveGrid(
      children: [
        ResponseBubble(
          text: "Take Photo",
          icon: Icons.camera_alt,
          isVisible: widget.isVisible,
          onTap: () => _handleImageSelection('camera'),
          customColor: CosmicDreamTheme.nebulaPink,
        ),
        ResponseBubble(
          text: "Choose from Gallery",
          icon: Icons.photo_library,
          isVisible: widget.isVisible,
          onTap: () => _handleImageSelection('gallery'),
          customColor: CosmicDreamTheme.cosmicTeal,
        ),
        ResponseBubble(
          text: "Skip for now",
          icon: Icons.skip_next,
          isVisible: widget.isVisible,
          onTap: () => widget.onBubbleSelected?.call('skipped'),
          customColor: CosmicDreamTheme.surface,
        ),
      ],
    );
  }

  Widget _buildCountryBubbles() {
    final hasSelectedCountry = widget.selectedValue != null &&
        widget.selectedValue!.isNotEmpty &&
        widget.selectedValue != 'skipped';

    return Column(
      children: [
        // Display selected country prominently if one is chosen
        if (hasSelectedCountry)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: CosmicDreamTheme.questionBubbleGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: CosmicDreamTheme.cosmicTeal.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: CosmicDreamTheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: CosmicDreamTheme.accent,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected',
                  style: TextStyle(
                    color: CosmicDreamTheme.text.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.selectedValue!,
                  style: const TextStyle(
                    color: CosmicDreamTheme.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        if (hasSelectedCountry) const SizedBox(height: 16),

        // Country selection options
        _buildAdaptiveGrid(
          children: [
            ResponseBubble(
              text: hasSelectedCountry ? "Change Country" : "Select Country",
              icon: Icons.public,
              isVisible: widget.isVisible,
              onTap: () => _showCountryPicker(),
              customColor: CosmicDreamTheme.cosmicTeal,
            ),
            ResponseBubble(
              text: "Type Country",
              icon: Icons.edit,
              isVisible: widget.isVisible,
              onTap: () => setState(() => _showCustomInput = true),
              customColor: CosmicDreamTheme.accent,
            ),
          ],
        ),

        // Text input field for typing country
        if (_showCustomInput) ...[
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomInputBubble(
              hintText: "Type country name (e.g., United States, Canada)",
              initialValue: hasSelectedCountry ? widget.selectedValue! : '',
              onChanged: (value) => widget.onBubbleSelected?.call(value),
              isVisible: widget.isVisible,
              animationDelay: 200,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _showCustomInput = false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: CosmicDreamTheme.text.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomInputSection() {
    return Column(
      children: [
        if (!_showCustomInput)
          ResponseBubble(
            text: "✨ Create your own",
            icon: Icons.add_circle_outline,
            isVisible: widget.isVisible,
            onTap: () => setState(() => _showCustomInput = true),
            customColor: CosmicDreamTheme.accent,
            animationDelay: 300,
          ),
        if (_showCustomInput)
          CustomInputBubble(
            hintText: "Type your answer...",
            initialValue: _customValue,
            onChanged: (value) {
              _customValue = value;
              if (value.isNotEmpty) {
                widget.onBubbleSelected?.call(value);
              }
            },
            isVisible: widget.isVisible,
            animationDelay: 200,
          ),
      ],
    );
  }

  Widget _buildCustomInputBubble() {
    return CustomInputBubble(
      hintText: _getHintTextForQuestion(),
      initialValue: widget.selectedValue,
      onChanged: (value) => widget.onBubbleSelected?.call(value),
      isVisible: widget.isVisible,
      animationDelay: 200,
    );
  }

  Widget _buildAdaptiveGrid({required List<Widget> children}) {
    // Calculate the optimal number of columns based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount =
        _calculateCrossAxisCount(screenWidth, children.length);

    if (crossAxisCount == 1) {
      // Single column layout for narrow screens or long text
      return Column(
        children: children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: child,
              ),
            )
            .toList(),
      );
    }

    // Multi-column grid layout
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }

  int _calculateCrossAxisCount(double screenWidth, int itemCount) {
    if (screenWidth < 600) {
      // Mobile: prefer single column for readability
      return itemCount > 4 ? 2 : 1;
    } else if (screenWidth < 900) {
      // Tablet: 2-3 columns
      return itemCount > 6 ? 3 : 2;
    } else {
      // Desktop: up to 4 columns
      return itemCount > 8 ? 4 : 3;
    }
  }

  List<String> _getPredefinedOptionsForQuestion() {
    final key = widget.question.key;

    // Define common responses for different question types
    switch (key) {
      case 'name':
        return ['Alex', 'Jordan', 'Taylor', 'Morgan'];
      case 'culture':
        return ['USA', 'Canada', 'UK', 'Australia', 'Other'];
      case 'location':
        return ['At home', 'At work', 'Traveling', 'Coffee shop'];
      case 'mindState':
        return ['Hopeful', 'Curious', 'Overwhelmed', 'Excited'];
      case 'selfPerception':
        return ['In nature', 'With friends', 'Creating', 'Learning'];
      case 'selfLike':
        return ['My kindness', 'My creativity', 'My determination', 'My humor'];
      case 'desiredFeeling':
        return ['Joy', 'Peace', 'Confidence', 'Wonder', 'Love'];
      case 'futureSelfVision':
        return ['Wise', 'Creative', 'Adventurous', 'Peaceful'];
      case 'trustedVibes':
        return ['Authentic', 'Gentle', 'Honest', 'Encouraging'];
      default:
        return [];
    }
  }

  String _getHintTextForQuestion() {
    switch (widget.question.key) {
      case 'name':
        return 'What should I call you?';
      case 'mindState':
        return 'Share what\'s on your mind...';
      case 'pickMeUp':
        return 'What would lift your spirits?';
      case 'dreamDay':
        return 'Describe your perfect day...';
      default:
        return 'Share your thoughts...';
    }
  }

  IconData? _getIconForOption(String option) {
    // Map common options to icons
    final iconMap = {
      'Joy': Icons.sentiment_very_satisfied,
      'Peace': Icons.spa,
      'Confidence': Icons.fitness_center,
      'Wonder': Icons.auto_awesome,
      'Love': Icons.favorite,
      'Daily': Icons.today,
      'Weekly': Icons.date_range,
      'Long': Icons.article,
      'Short': Icons.short_text,
      'Wise': Icons.psychology,
      'Creative': Icons.palette,
      'Adventurous': Icons.explore,
      'Peaceful': Icons.self_improvement,
    };

    return iconMap[option];
  }

  bool _shouldShowCustomInput() {
    return widget.question.type == QuestionType.text &&
        widget.question.options == null;
  }

  String _formatSelectedDate() {
    if (widget.selectedValue == null || widget.selectedValue!.isEmpty)
      return '';

    try {
      // Try to parse as ISO date first
      final date = DateTime.parse(widget.selectedValue!);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      // If it's not a valid ISO date, try parsing common formats
      final value = widget.selectedValue!;

      // Check if it's already in a nice format
      if (RegExp(r'^[A-Za-z]+ \d{1,2}, \d{4}$').hasMatch(value)) {
        return value;
      }

      // Try to parse MM/DD/YYYY or MM-DD-YYYY
      try {
        DateTime? parsedDate;

        if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(value)) {
          final parts = value.split('/');
          parsedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        } else if (RegExp(r'^\d{1,2}-\d{1,2}-\d{4}$').hasMatch(value)) {
          final parts = value.split('-');
          parsedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }

        if (parsedDate != null) {
          return DateFormat('MMMM d, yyyy').format(parsedDate);
        }
      } catch (e) {
        // Continue to return original value
      }

      // Return the original value if we can't parse it
      return value;
    }
  }

  String _formatSelectedDateForInput() {
    if (widget.selectedValue == null || widget.selectedValue!.isEmpty)
      return '';
    try {
      final date = DateTime.parse(widget.selectedValue!);
      return DateFormat('MM/dd/yyyy').format(date);
    } catch (e) {
      return widget.selectedValue!;
    }
  }

  void _handleDateInput(String value) {
    if (value.isEmpty) return;

    // Try to parse the date in various formats
    DateTime? parsedDate;

    try {
      // Try MM/DD/YYYY format
      if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(value)) {
        final parts = value.split('/');
        parsedDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
      // Try MM-DD-YYYY format
      else if (RegExp(r'^\d{1,2}-\d{1,2}-\d{4}$').hasMatch(value)) {
        final parts = value.split('-');
        parsedDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
      // Try natural language parsing with DateFormat
      else {
        // Try various common formats
        final formats = [
          'MMMM d, yyyy', // January 15, 1990
          'MMM d, yyyy', // Jan 15, 1990
          'yyyy-MM-dd', // 1990-01-15
          'dd/MM/yyyy', // 15/01/1990
          'dd-MM-yyyy', // 15-01-1990
        ];

        for (final format in formats) {
          try {
            parsedDate = DateFormat(format).parse(value);
            break;
          } catch (e) {
            continue;
          }
        }
      }

      // Validate the date is reasonable (not in future, not too old)
      if (parsedDate != null) {
        final now = DateTime.now();
        if (parsedDate.isAfter(now)) {
          // Date is in the future
          return;
        }
        if (parsedDate.year < 1900) {
          // Date is too old
          return;
        }

        // Valid date - store as ISO string
        widget.onBubbleSelected?.call(parsedDate.toIso8601String());
      } else {
        // Store as text for now - user might still be typing
        widget.onBubbleSelected?.call(value);
      }
    } catch (e) {
      // Store as text for now - might be partial input
      widget.onBubbleSelected?.call(value);
    }
  }

  Future<void> _showDatePicker() async {
    DateTime? selectedDate;

    // Parse existing date if available
    if (widget.selectedValue != null && widget.selectedValue!.isNotEmpty) {
      try {
        selectedDate = DateTime.parse(widget.selectedValue!);
      } catch (e) {
        selectedDate = null;
      }
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              gradient: CosmicDreamTheme.questionBubbleGradient,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: CosmicDreamTheme.cosmicTeal.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: CosmicDreamTheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cake,
                        color: CosmicDreamTheme.accent,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'When is your birthday?',
                        style: TextStyle(
                          color: CosmicDreamTheme.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Date Picker
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: CosmicDreamTheme.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SfDateRangePicker(
                      onSelectionChanged:
                          (DateRangePickerSelectionChangedArgs args) {
                        selectedDate = args.value;
                      },
                      selectionMode: DateRangePickerSelectionMode.single,
                      initialSelectedDate: selectedDate,
                      initialDisplayDate: selectedDate ?? DateTime.now(),
                      minDate: DateTime(1900),
                      maxDate: DateTime.now(),
                      monthCellStyle: const DateRangePickerMonthCellStyle(
                        textStyle: TextStyle(
                          color: CosmicDreamTheme.text,
                          fontSize: 14,
                        ),
                        todayTextStyle: TextStyle(
                          color: CosmicDreamTheme.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selectionTextStyle: const TextStyle(
                        color: CosmicDreamTheme.text,
                        fontWeight: FontWeight.bold,
                      ),
                      rangeTextStyle: const TextStyle(
                        color: CosmicDreamTheme.text,
                      ),
                      headerStyle: const DateRangePickerHeaderStyle(
                        textAlign: TextAlign.center,
                        textStyle: TextStyle(
                          color: CosmicDreamTheme.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      monthViewSettings: const DateRangePickerMonthViewSettings(
                        viewHeaderStyle: DateRangePickerViewHeaderStyle(
                          textStyle: TextStyle(
                            color: CosmicDreamTheme.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      selectionColor: CosmicDreamTheme.accent,
                      todayHighlightColor: CosmicDreamTheme.cosmicTeal,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: CosmicDreamTheme.text.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: CosmicDreamTheme.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedDate != null) {
                              widget.onBubbleSelected
                                  ?.call(selectedDate!.toIso8601String());
                            }
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CosmicDreamTheme.accent,
                            foregroundColor: CosmicDreamTheme.text,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                ),
                            elevation: 0,
          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleImageSelection(String source) {
    // This would typically trigger image picker
    widget.onBubbleSelected?.call(source);
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        widget.onBubbleSelected?.call(country.name);
      },
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40.0),
          topRight: Radius.circular(40.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: CosmicDreamTheme.cosmicTeal.withOpacity(0.3),
            ),
          ),
        ),
        searchTextStyle: TextStyle(
          color: CosmicDreamTheme.text,
          fontSize: 18,
        ),
        textStyle: TextStyle(
          color: CosmicDreamTheme.text,
        ),
        backgroundColor: CosmicDreamTheme.surface,
        bottomSheetHeight: 500,
      ),
    );
  }
}
