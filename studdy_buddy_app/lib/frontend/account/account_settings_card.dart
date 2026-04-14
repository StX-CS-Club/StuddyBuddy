import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';
import 'package:studdy_buddy_app/frontend/welcome/welcome_page.dart';

class AccountSettingsCard extends StatefulWidget {
  const AccountSettingsCard({super.key});

  @override
  State<AccountSettingsCard> createState() => _AccountSettingsCardState();
}

class _AccountSettingsCardState extends State<AccountSettingsCard> {
  final _nameController = TextEditingController(text: SupabaseDB.account?.name);

  bool get _nameChanged => _nameController.text.trim().isNotEmpty;

  Future<void> _updateName() =>
      SupabaseDB.writeAccount(name: _nameController.text);

  Future<void> _logout() async {
    await SupabaseDB.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => WelcomePage()), (_) => false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    return Center(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: screen.width * 0.88,
          decoration: BoxDecoration(
            color: StuddyBuddyTheme.surfaceDim,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: StuddyBuddyTheme.surfaceBase,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Text(
                  'Account Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            onChanged: (_) => setState(() {}),
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              floatingLabelStyle:
                                  TextStyle(color: StuddyBuddyTheme.teal),
                              filled: true,
                              fillColor: StuddyBuddyTheme.surfaceBase,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: StuddyBuddyTheme.teal, width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _nameChanged ? 1.0 : 0.4,
                          child: ElevatedButton(
                            onPressed: _nameChanged ? _updateName : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: StuddyBuddyTheme.teal,
                              disabledBackgroundColor:
                                  StuddyBuddyTheme.teal.withValues(alpha: 0.4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Divider(),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _logout,
                        icon:
                            const Icon(Icons.logout, color: Color(0xFFB3261E)),
                        label: const Text(
                          'Log out',
                          style: TextStyle(color: Color(0xFFB3261E)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
