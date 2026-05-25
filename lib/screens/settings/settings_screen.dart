import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_strings.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/settings_data_notifier.dart';
import '../../providers/theme_provider.dart';
import '../../providers/app_lock_provider.dart';
import '../../providers/privacy_provider.dart';
import '../../services/security_service.dart';
import '../categories/categories_screen.dart';
import '../security/pin_setup_screen.dart';
import '../../widgets/skeleton.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _currencies = <Map<String, String>>[
    {'code': 'USD', 'symbol': r'$', 'label': 'US Dollar'},
    {'code': 'INR', 'symbol': '₹', 'label': 'Indian Rupee'},
    {'code': 'EUR', 'symbol': '€', 'label': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'label': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'label': 'Japanese Yen'},
    {'code': 'AED', 'symbol': 'د.إ', 'label': 'UAE Dirham'},
    {'code': 'SGD', 'symbol': 'S\$', 'label': 'Singapore Dollar'},
  ];

  bool _budgetAlerts = true;
  bool _dailyReminder = true;
  bool _loading = true; // For premium skeleton

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _plannedFeature(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is not available in this build.')),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/sign-in', (_) => false);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.genericError)),
        );
      }
    }
  }

  Future<void> _openPrivacy(BuildContext context) async {
    final u = Uri.parse(AppStrings.privacyPolicyUrl);
    try {
      if (await canLaunchUrl(u)) {
        await launchUrl(u, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open privacy policy.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.genericError)),
        );
      }
    }
  }

  void _pickCurrency(BuildContext context) {
    final search = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setS) {
            final q = search.text.toLowerCase();
            final list = _currencies
                .where(
                  (c) =>
                      q.isEmpty ||
                      c['label']!.toLowerCase().contains(q) ||
                      c['code']!.toLowerCase().contains(q),
                )
                .toList();
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: search,
                      decoration: const InputDecoration(hintText: 'Search currency'),
                      onChanged: (_) => setS(() {}),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final c = list[i];
                        return ListTile(
                          title: Text('${c['symbol']} ${c['code']}'),
                          subtitle: Text(c['label']!),
                          onTap: () async {
                            try {
                              await context.read<SettingsDataNotifier>().setCurrency(
                                    code: c['code']!,
                                    symbol: c['symbol']!,
                                  );
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (_) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text(AppStrings.genericError)),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickTheme(BuildContext context, ThemeNotifier themeNotifier) async {
    final chosen = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Appearance'),
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: themeNotifier.themeMode,
            onChanged: (v) => Navigator.pop(ctx, v),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: themeNotifier.themeMode,
            onChanged: (v) => Navigator.pop(ctx, v),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            value: ThemeMode.system,
            groupValue: themeNotifier.themeMode,
            onChanged: (v) => Navigator.pop(ctx, v),
          ),
        ],
      ),
    );
    if (chosen != null) {
      await themeNotifier.setThemeMode(chosen);
    }
  }

  Future<void> _toggleAppLock(bool value) async {
    final appLockProvider = context.read<AppLockProvider>();
    
    if (value) {
      // Enable app lock - for now, skip biometric and go straight to PIN
      try {
        if (mounted) {
          // Show PIN setup directly
          final pin = await Navigator.of(context).push<String>(
            MaterialPageRoute(builder: (_) => const PinSetupScreen()),
          );
          
          if (pin != null && pin.length == 4) {
            final pinSuccess = await appLockProvider.setupPINLock(pin);
            if (pinSuccess && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App lock enabled with PIN')),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to set up PIN. Please try again.')),
              );
            }
          } else if (mounted) {
            // User cancelled PIN setup
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('App lock setup cancelled')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to enable app lock: ${e.toString()}')),
          );
        }
      }
    } else {
      // Disable app lock - need authentication first
      try {
        bool canDisable = false;
        
        if (appLockProvider.lockMethod == LockMethod.biometric) {
          // Try biometric authentication first
          canDisable = await appLockProvider.authenticate();
          if (!canDisable && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric authentication failed')),
            );
          }
        }
        
        if (!canDisable && appLockProvider.lockMethod == LockMethod.pin) {
          // Need PIN verification to disable
          if (mounted) {
            final pin = await _showPinVerificationDialog();
            if (pin != null && pin.length == 4) {
              canDisable = await appLockProvider.verifyPIN(pin);
              if (!canDisable && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect PIN')),
                );
              }
            }
          }
        }
        
        // If authenticated, disable the app lock
        if (canDisable) {
          final success = await appLockProvider.forceDisableAppLock();
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('App lock disabled')),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to disable app lock')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to disable app lock: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<String?> _showPinVerificationDialog() async {
    String pin = '';
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter your PIN to disable app lock'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.surfaceContainerHigh,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Simple PIN input field
                  TextField(
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    onChanged: (value) {
                      setState(() {
                        pin = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Enter 4-digit PIN',
                      counterText: '',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: pin.length == 4 
                      ? () => Navigator.pop(context, pin)
                      : null,
                  child: const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _togglePrivacyMode(bool value) async {
    final privacyProvider = context.read<PrivacyProvider>();
    await privacyProvider.setPrivacyMode(value);
    
    // Force a refresh to ensure UI updates immediately
    if (mounted) {
      privacyProvider.forceRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeNotifier = context.watch<ThemeNotifier>();
    final settings = context.watch<SettingsDataNotifier>();
    final appLockProvider = context.watch<AppLockProvider>();
    final privacyProvider = context.watch<PrivacyProvider>();
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final name = email.isEmpty ? 'User' : email.split('@').first;

    return Scaffold(
      backgroundColor: cs.surface,
      body: _loading
        ? const SettingsScreenSkeleton()
        : ListView(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.04,
              MediaQuery.of(context).size.height * 0.10,
              MediaQuery.of(context).size.width * 0.04,
              120,
            ),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.person, size: 14, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Spndly',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Transactions',
                    onPressed: () => context.read<NavigationNotifier>().setIndex(2),
                    icon: Icon(Icons.search, color: cs.primary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: cs.surfaceContainerHigh,
                          child: Icon(Icons.person, color: cs.onSurface),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.surfaceContainerHighest, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleCase(name),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'PREMIUM MEMBER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Preferences'),
              _groupCard(context, [
                _rowChevron(
                  context,
                  icon: Icons.brightness_5_outlined,
                  iconBg: const Color(0xFFE1E3E4),
                  iconColor: const Color(0xFF526772),
                  title: 'Theme',
                  subtitle: switch (themeNotifier.themeMode) {
                    ThemeMode.light => 'Light mode',
                    ThemeMode.dark => 'Dark mode',
                    ThemeMode.system => 'System mode',
                  },
                  onTap: () => _pickTheme(context, themeNotifier),
                ),
                _divider(context),
                _rowChevron(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  iconBg: const Color(0xFFE1E3E4),
                  iconColor: const Color(0xFF526772),
                  title: 'Currency',
                  subtitle: 'Indian Rupee (${settings.currencySymbol})',
                  onTap: () => _pickCurrency(context),
                ),
                _divider(context),
                _rowChevron(
                  context,
                  icon: Icons.language,
                  iconBg: const Color(0xFFE1E3E4),
                  iconColor: const Color(0xFF526772),
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () => _plannedFeature(context, 'Language'),
                ),
              ]),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Security'),
              _groupCard(context, [
                _rowToggle(
                  context,
                  icon: Icons.lock_outline,
                  iconBg: const Color(0xFFFFDAD7),
                  iconColor: const Color(0xFFB3272A),
                  title: 'App lock',
                  subtitle: 'Biometrics or PIN',
                  value: appLockProvider.isAppLockEnabled,
                  onChanged: appLockProvider.isLoading ? null : _toggleAppLock,
                ),
                _divider(context),
                _rowToggle(
                  context,
                  icon: Icons.visibility_off_outlined,
                  iconBg: const Color(0xFFFFDAD7),
                  iconColor: const Color(0xFFB3272A),
                  title: 'Privacy mode',
                  subtitle: 'Hide balances on home',
                  value: privacyProvider.isPrivacyModeEnabled,
                  onChanged: privacyProvider.isLoading ? null : _togglePrivacyMode,
                ),
                _divider(context),
                _rowChevron(
                  context,
                  icon: Icons.backup_outlined,
                  iconBg: const Color(0xFFFFDAD7),
                  iconColor: const Color(0xFFB3272A),
                  title: 'Backup',
                  subtitle: 'Last synced: 2h ago',
                  trailing: Icon(Icons.sync, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => _plannedFeature(context, 'Backup'),
                ),
              ]),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Notifications'),
              _groupCard(context, [
                _rowToggle(
                  context,
                  icon: Icons.notifications_none_outlined,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF006A62),
                  title: 'Budget alerts',
                  subtitle: 'Notify when 80% limit reached',
                  value: _budgetAlerts,
                  onChanged: (v) => setState(() => _budgetAlerts = v),
                ),
                _divider(context),
                _rowToggle(
                  context,
                  icon: Icons.access_time,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF006A62),
                  title: 'Daily reminder',
                  subtitle: 'Evening summary at 20:00',
                  value: _dailyReminder,
                  onChanged: (v) => setState(() => _dailyReminder = v),
                ),
              ]),
              const SizedBox(height: 16),
              _sectionTitle(context, 'About'),
              _groupCard(context, [
                _rowChevron(
                  context,
                  icon: Icons.info_outline,
                  iconBg: const Color(0xFFE5E7EB),
                  iconColor: const Color(0xFF6B7280),
                  title: 'Version',
                  subtitle: 'v2.4.1 (stable build)',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'LATEST',
                      style: TextStyle(fontSize: 9, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w700),
                    ),
                  ),
                  onTap: () => _plannedFeature(context, 'Version info'),
                ),
                _divider(context),
                _rowChevron(
                  context,
                  icon: Icons.feedback_outlined,
                  iconBg: const Color(0xFFE5E7EB),
                  iconColor: const Color(0xFF6B7280),
                  title: 'Feedback',
                  subtitle: 'Report issues or suggest features',
                  trailing: Icon(Icons.open_in_new, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => _openPrivacy(context),
                ),
                _divider(context),
                _rowChevron(
                  context,
                  icon: Icons.category_outlined,
                  iconBg: const Color(0xFFE5E7EB),
                  iconColor: const Color(0xFF6B7280),
                  title: 'Categories',
                  subtitle: 'Manage category list',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () => _signOut(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.error.withValues(alpha: 0.6)),
                  foregroundColor: cs.error,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.logout, size: 16, color: cs.error),
                label: Text(
                  'Logout from Device',
                  style: TextStyle(fontWeight: FontWeight.w700, color: cs.error),
                ),
              ),
            ],
          ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: cs.primary,
        ),
      ),
    );
  }

  Widget _groupCard(BuildContext context, List<Widget> children) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _rowChevron(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _iconCircle(icon, iconBg, iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _rowToggle(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _iconCircle(icon, iconBg, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 24,
            child: Transform.scale(
              scale: 0.86,
              child: Switch(
                value: value,
                onChanged: onChanged,
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return cs.onPrimary;
                  }
                  return null;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return cs.primary;
                  }
                  return null;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconCircle(IconData icon, Color bg, Color fg) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: fg),
    );
  }

  Widget _divider(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(height: 1, color: cs.surfaceContainerHigh);
  }

  String _titleCase(String v) {
    if (v.isEmpty) return v;
    return v[0].toUpperCase() + v.substring(1);
  }
}
