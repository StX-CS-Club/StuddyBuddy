import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';

import '../../backend/data/account.dart';

class AccountTile extends StatelessWidget {
  const AccountTile({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: account.role == "teacher"
            ? StuddyBuddyTheme.forest
            : StuddyBuddyTheme.teal,
        child: Text(
          account.name?.isNotEmpty == true
              ? account.name![0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(
        account.name ?? 'Unknown',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: account.role != null
          ? Text(
              account.role!,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
    );
  }
}
