import 'dart:async';

import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';
import 'package:studdy_buddy_app/extensions/build_context_extension.dart';
import 'package:studdy_buddy_app/frontend/account/account_settings_card.dart';
import 'package:studdy_buddy_app/frontend/classroom/classroom_card.dart';
import 'package:studdy_buddy_app/frontend/classroom/create_classroom_card.dart';
import 'package:studdy_buddy_app/frontend/classroom/join_classroom_card.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';
import 'package:studdy_buddy_app/util/stream_signal.dart';

import '../../widgets/avatar_stack.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static StreamController<StreamSignal> stream = StreamController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    stream = StreamController();

    return StreamBuilder(
        stream: stream.stream,
        builder: (_, __) => Scaffold(
              backgroundColor: StuddyBuddyTheme.surfaceDim,
              appBar: AppBar(
                backgroundColor: StuddyBuddyTheme.surfaceBase,
                titleSpacing: 16,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AvatarStack(),
                    const SizedBox(width: 10),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                        children: [
                          TextSpan(
                            text: 'Studdy',
                            style: TextStyle(color: StuddyBuddyTheme.teal),
                          ),
                          TextSpan(
                            text: 'Buddy',
                            style: TextStyle(color: StuddyBuddyTheme.forest),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.account_circle_outlined,
                          size: 24, color: StuddyBuddyTheme.teal),
                      onPressed: () => context.pushPopup(AccountSettingsCard()),
                    ),
                  ),
                ],
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    color: StuddyBuddyTheme.surfaceBase,
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Classrooms',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.add, color: StuddyBuddyTheme.teal),
                          onPressed: () => context.pushPopup(
                              (SupabaseDB.account?.role == 'teacher')
                                  ? CreateClassroomCard()
                                  : JoinClassroomCard()),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          itemCount: SupabaseDB.classrooms.length,
                          itemBuilder: (_, i) => ClassroomCard(
                              classroom: SupabaseDB.classrooms[i]),
                        ),
                        IgnorePointer(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      StuddyBuddyTheme.surfaceDim,
                                      StuddyBuddyTheme.surfaceDim
                                          .withValues(alpha: 0),
                                    ],
                                  ),
                                )),
                          ),
                        ),
                        IgnorePointer(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    StuddyBuddyTheme.surfaceDim,
                                    StuddyBuddyTheme.surfaceDim
                                        .withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ));
  }
}
