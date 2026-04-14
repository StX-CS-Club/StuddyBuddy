import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/backend/data/classroom.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';
import 'package:studdy_buddy_app/extensions/build_context_extension.dart';
import 'package:studdy_buddy_app/frontend/assignment/create_assignment_card.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';

import '../../backend/data/account.dart';
import '../../backend/data/assignment.dart';
import '../../extensions/color_extension.dart';
import '../../widgets/avatar_stack.dart';
import '../account/account_tile.dart';

class ClassroomPage extends StatefulWidget {
  const ClassroomPage({super.key, required this.classroom});

  final Classroom classroom;

  @override
  State<ClassroomPage> createState() => _ClassroomPageState();
}

class _ClassroomPageState extends State<ClassroomPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  Color get _color => widget.classroom.colorId != null
      ? ColorExtension.fromHex(widget.classroom.colorId!)
      : StuddyBuddyTheme.teal;

  Color get _bgColor => Color.alphaBlend(
        _color.withValues(alpha: 0.08),
        StuddyBuddyTheme.surfaceDim,
      );

  bool get _isTeacher => SupabaseDB.account?.role == 'teacher';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _fadeListView({required List<Widget> children}) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.symmetric(vertical: 48),
          children: children,
        ),
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _bgColor,
                    _bgColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    _bgColor,
                    _bgColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: StuddyBuddyTheme.surfaceBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: StuddyBuddyTheme.teal,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AvatarStack(),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.account_circle_outlined,
                  color: StuddyBuddyTheme.teal),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Classroom title + tab bar
          Container(
            color: StuddyBuddyTheme.surfaceBase,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            widget.classroom.emoji ?? '📚',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.classroom.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: _color,
                  labelColor: _color,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Assignments'),
                    Tab(text: 'People'),
                  ],
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Assignments tab
                Column(
                  children: [
                    if (_isTeacher)
                      Container(
                        color: StuddyBuddyTheme.surfaceBase,
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        child: Row(
                          children: [
                            Text(
                              'Assignments',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontSize: 17),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.add, color: _color),
                              onPressed: () => context.pushPopup(CreateAssignmentCard(classroomId: widget.classroom.id, color: _color)),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: FutureBuilder<List<Assignment>>(
                        future: widget.classroom.readAssignments(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(color: _color),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Failed to load assignments',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          }

                          final List<Assignment> assignments =
                              snapshot.data ?? [];

                          if (assignments.isEmpty) {
                            return Center(
                              child: Text(
                                'No assignments yet',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          }

                          return _fadeListView(
                            children: assignments
                                .map((a) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                      child: Card(
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: _color,
                                            child: const Icon(
                                                Icons.assignment_outlined,
                                                color: Colors.white,
                                                size: 18),
                                          ),
                                          title: Text(a.title),
                                          trailing:
                                              const Icon(Icons.chevron_right),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // People tab
                Column(
                  children: [
                    if (_isTeacher)
                      Container(
                        color: StuddyBuddyTheme.surfaceBase,
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        child: Row(
                          children: [
                            Text(
                              'People',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontSize: 17),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.person_add_outlined,
                                  color: _color),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: FutureBuilder<(Account, Set<Account>)>(
                        future: Future.wait([
                          widget.classroom.readTeacher(),
                          widget.classroom.readStudents(),
                        ]).then((results) => (results[0] as Account, results[1] as Set<Account>)),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(color: _color),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Failed to load people',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          }

                          final Account teacher = snapshot.data!.$1;
                          final Set<Account> students = snapshot.data!.$2;

                          return _fadeListView(
                            children: [
                              AccountTile(account: teacher),
                              const Divider(),
                              ...students.map((s) => AccountTile(account: s)),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
