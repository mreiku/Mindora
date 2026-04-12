import 'package:flutter/material.dart';

import '../backend/auth_service.dart';
import '../backend/badge_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.initialDisplayName,
    required this.initialUsername,
    required this.initialPronouns,
    required this.initialBio,
    required this.isActive,
    required this.initialDisplayedBadgeIds,
  });

  final String initialDisplayName;
  final String initialUsername;
  final String initialPronouns;
  final String initialBio;
  final bool isActive;
  final List<String> initialDisplayedBadgeIds;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final BadgeService _badgeService = BadgeService();
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late String _selectedPronouns;
  late bool _isActive;
  late Set<String> _selectedBadgeIds;
  bool _isSaving = false;
  String _feedback = "";

  static const List<String> _pronounOptions = [
    "",
    "She/Her",
    "He/Him",
    "They/Them",
    "Prefer not to say",
  ];

  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.initialDisplayName);
    _bioController = TextEditingController(text: widget.initialBio);
    _selectedPronouns = _pronounOptions.contains(widget.initialPronouns)
        ? widget.initialPronouns
        : "";
    _isActive = widget.isActive;
    _selectedBadgeIds = {...widget.initialDisplayedBadgeIds};
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _feedback = "";
    });

    final result = await _authService.updateProfileDetails(
      displayName: _displayNameController.text,
      pronouns: _selectedPronouns,
      bio: _bioController.text,
    );

    if (result == null) {
      final badgeResult =
          await _authService.updateDisplayedBadges(_selectedBadgeIds.toList());
      if (!mounted) {
        return;
      }

      if (badgeResult != null) {
        setState(() {
          _isSaving = false;
          _feedback = badgeResult;
        });
        return;
      }

      final activeResult = await _authService.updateActiveStatus(_isActive);
      if (!mounted) {
        return;
      }

      if (activeResult != null) {
        setState(() {
          _isSaving = false;
          _feedback = activeResult;
        });
        return;
      }

      Navigator.pop(context, true);
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _feedback = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandTop =
        isDark ? const Color(0xFF1F1716) : const Color(0xFFA33A37);
    final brandCard =
        isDark ? const Color(0xFF2D2322) : const Color(0xFFE17A74);
    final brandSurface =
        isDark ? const Color(0xFF171212) : const Color(0xFFFFEAD3);
    final brandAccent =
        isDark ? const Color(0xFFD06B64) : const Color(0xFFC84D4D);
    final brandText =
        isDark ? const Color(0xFFFFEAD3) : const Color(0xFFA33A37);
    final panelFill =
        isDark ? const Color(0xFF372927) : const Color(0xFFF08F8A);
    final messageFill =
        isDark ? Colors.white10 : const Color(0x66FFEAD3);

    return Scaffold(
      backgroundColor: brandTop,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
              decoration: BoxDecoration(
                color: brandTop,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(26),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          "PROFILE",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 34),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: brandSurface,
                                width: 4,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 60,
                              color: Color(0xFFE7DAD2),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _isActive
                                    ? const Color(0xFF95E678)
                                    : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: brandSurface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _displayNameController.text.trim().isEmpty
                            ? "name."
                            : _displayNameController.text.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Jomhuria',
                          fontSize: 48,
                          height: 0.9,
                        ),
                      ),
                      Text(
                        "@${widget.initialUsername}",
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: brandCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFC85C55),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Edit Profile",
                            style: TextStyle(
                              fontSize: 38,
                              fontFamily: 'Jomhuria',
                              color: Colors.white,
                              height: 0.9,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Update how your profile appears to classmates. Your pronouns, bio, and active status will show on your profile after saving.",
                            style: TextStyle(
                              color: Color(0xFFFFEAD3),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel("Display Name", isDark: isDark),
                          const SizedBox(height: 8),
                          _StyledTextField(
                            controller: _displayNameController,
                            hintText: "name...",
                            isDark: isDark,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel("Pronouns", isDark: isDark),
                          const SizedBox(height: 8),
                          _StyledDropdown(
                            value: _selectedPronouns,
                            items: _pronounOptions,
                            isDark: isDark,
                            onChanged: (value) {
                              setState(() {
                                _selectedPronouns = value ?? "";
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel("About Me", isDark: isDark),
                          const SizedBox(height: 8),
                          _StyledTextField(
                            controller: _bioController,
                            hintText:
                                "Tell your classmates a little about yourself...",
                            maxLines: 5,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel("Active Status", isDark: isDark),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: panelFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.white70,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isActive ? "You appear active" : "You appear inactive",
                                        style: TextStyle(
                                          color: brandText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isActive
                                            ? "Classmates can see that you are currently available."
                                            : "Your profile will show that you are not currently active.",
                                        style: TextStyle(
                                          color: brandText.withOpacity(0.8),
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Switch(
                                  value: _isActive,
                                  onChanged: (value) {
                                    setState(() {
                                      _isActive = value;
                                    });
                                  },
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: brandAccent,
                                  inactiveTrackColor: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel("Display Quest Awards", isDark: isDark),
                          const SizedBox(height: 8),
                          StreamBuilder(
                            stream: _badgeService.streamCurrentUserBadges(),
                            builder: (context, snapshot) {
                              final badgeDocs = snapshot.data?.docs ?? [];

                              return Container(
                                width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: panelFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.white12 : Colors.white70,
                                ),
                              ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Choose up to 5 earned badges to show on your profile.",
                                      style: TextStyle(
                                        color: brandText.withOpacity(0.85),
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (badgeDocs.isEmpty)
                                      Text(
                                        "No earned badges yet.",
                                        style: TextStyle(
                                          color: brandText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    if (badgeDocs.isNotEmpty)
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: badgeDocs.map((badgeDoc) {
                                          final badge = badgeDoc.data();
                                          final badgeId =
                                              (badge["badgeId"] ?? "").toString();
                                          final title =
                                              (badge["title"] ?? "Badge").toString();
                                          final isSelected =
                                              _selectedBadgeIds.contains(badgeId);

                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedBadgeIds.remove(badgeId);
                                                } else if (_selectedBadgeIds.length < 5) {
                                                  _selectedBadgeIds.add(badgeId);
                                                }
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration:
                                                  const Duration(milliseconds: 180),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? brandAccent
                                                    : (isDark
                                                        ? const Color(0xFF3A2C2A)
                                                        : const Color(0xFFFFEAD3)),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.workspace_premium_rounded,
                                                    size: 16,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : brandText,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    title,
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : brandText,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_feedback.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: messageFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.white70,
                          ),
                        ),
                        child: Text(
                          _feedback,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFFFFEAD3),
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Center(
                      child: SizedBox(
                        width: 190,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            _isSaving ? "Saving..." : "Save Profile",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    required this.isDark,
  });

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2322) : const Color(0xFFE17A74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF4D3A38) : const Color(0xFFC85C55),
          width: 2,
        ),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: isDark ? const Color(0xFFFFEAD3) : const Color(0xFFFFEAD3),
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.isDark,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor:
            isDark ? const Color(0xFF3A2C2A) : const Color(0xFFFFEAD3),
        hintStyle: TextStyle(
          color: (isDark
                  ? const Color(0xFFD7B9B4)
                  : const Color(0xFFA33A37))
              .withOpacity(0.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFFD06B64)
                : const Color(0xFFA33A37),
            width: 2,
          ),
        ),
      ),
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFFA33A37),
      ),
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor:
            isDark ? const Color(0xFF3A2C2A) : const Color(0xFFFFEAD3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFFD06B64)
                : const Color(0xFFA33A37),
            width: 2,
          ),
        ),
      ),
      dropdownColor:
          isDark ? const Color(0xFF2D2322) : const Color(0xFFFFEAD3),
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFFA33A37),
      ),
      items: items.map((item) {
        final label = item.isEmpty ? "select..." : item;
        return DropdownMenuItem<String>(
          value: item,
          child: Text(label),
        );
      }).toList(),
    );
  }
}
