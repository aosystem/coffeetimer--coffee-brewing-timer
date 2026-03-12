import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import "package:audioplayers/audioplayers.dart";
import 'package:in_app_review/in_app_review.dart';

import 'package:coffeetimer/l10n/app_localizations.dart';
import 'package:coffeetimer/model.dart';
import 'package:coffeetimer/ad_manager.dart';
import 'package:coffeetimer/ad_banner_widget.dart';
import 'package:coffeetimer/loading_screen.dart';
import 'package:coffeetimer/theme_color.dart';
import 'package:coffeetimer/ad_ump_status.dart';
import 'package:coffeetimer/const_value.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late AdManager _adManager;
  late UmpConsentController _adUmp;
  AdUmpState _adUmpState = AdUmpState.initial;
  int _themeNumber = 0;
  String _languageCode = '';
  late ThemeColor _themeColor;
  final _inAppReview = InAppReview.instance;
  bool _isReady = false;
  bool _isFirst = true;
  //
  bool _wakelockEnabled = true;
  bool _soundEnabled = true;
  double _soundVolume = 1.0;
  int _soundSelect = 0;
  bool _vibrateEnabled = true;
  double _percentDisplayOpacity = 1.0;
  double _timeDisplayOpacity = 1.0;
  int _schemeColor = 0;
  Color _accentColor = Colors.red;
  //
  late AudioPlayer _audioPlayer;
  //

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    _adManager = AdManager();
    _audioPlayer = AudioPlayer();
    _themeNumber = Model.themeNumber;
    _languageCode = Model.languageCode;
    //
    _adUmp = UmpConsentController();
    _refreshConsentInfo();
    //
    _wakelockEnabled = Model.wakelockEnabled;
    _soundEnabled = Model.soundEnabled;
    _soundVolume = Model.soundVolume;
    _soundSelect = Model.soundSelect;
    _vibrateEnabled = Model.vibrateEnabled;
    _percentDisplayOpacity = Model.percentDisplayOpacity;
    _timeDisplayOpacity = Model.timeDisplayOpacity;
    _schemeColor = Model.schemeColor;
    _accentColor = _getRainbowAccentColor(_schemeColor);
    //
    setState(() {
      _isReady = true;
    });
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }

  Future<void> _refreshConsentInfo() async {
    _adUmpState = await _adUmp.updateConsentInfo(current: _adUmpState);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onTapPrivacyOptions() async {
    final err = await _adUmp.showPrivacyOptions();
    await _refreshConsentInfo();
    if (err != null && mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.cmpErrorOpeningSettings} ${err.message}')),
      );
    }
  }

  Color _getRainbowAccentColor(int hue) {
    return HSVColor.fromAHSV(1.0, hue.toDouble(), 1.0, 1.0).toColor();
  }

  Future<void> _onApply() async {
    await Model.setWakelockEnabled(_wakelockEnabled);
    await Model.setSoundEnabled(_soundEnabled);
    await Model.setSoundVolume(_soundVolume);
    await Model.setSoundSelect(_soundSelect);
    await Model.setVibrateEnabled(_vibrateEnabled);
    await Model.setPercentDisplayOpacity(_percentDisplayOpacity);
    await Model.setTimeDisplayOpacity(_timeDisplayOpacity);
    await Model.setSchemeColor(_schemeColor);
    await Model.setThemeNumber(_themeNumber);
    await Model.setLanguageCode(_languageCode);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady == false) {
      return LoadingScreen();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: _themeNumber, context: context);
    }
    final AppLocalizations l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _themeColor.backColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child:IconButton(
              icon: const Icon(Icons.check),
              onPressed: _onApply,
            )
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children:[
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 100),
                  child: Column(children: [
                    _buildSound(l),
                    _buildVibrateEnabled(l),
                    _buildWakelockEnabled(l),
                    _buildProgressOpacity(l),
                    _buildSchemeColor(l),
                    _buildTheme(l),
                    _buildLanguage(l),
                    _buildReview(l),
                    _buildCmp(l),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  Widget _buildSound(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return SizedBox(
        width: double.infinity,
        child: Card(
            margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
            color: _themeColor.cardColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            child: Column(children: [
              SwitchListTile(
                title: Text(l.soundEnabled, style: t.bodyMedium),
                value: _soundEnabled,
                onChanged: (value) => setState(() => _soundEnabled = value),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.soundVolume,
                        style: t.bodyMedium,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  children: <Widget>[
                    Text(_soundVolume.toStringAsFixed(1)),
                    Expanded(
                      child: Slider(
                          value: _soundVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: _soundVolume.toStringAsFixed(1),
                          onChanged: (double value) {
                            setState(() {
                              _soundVolume = value;
                            });
                          }
                      ),
                    )
                  ],
                ),
              ),
              ListTile(
                title: Text(l.soundSelect, style: t.bodyMedium),
                trailing: DropdownButton<int>(
                  value: _soundSelect,
                  items: finishSounds.map((sound) {
                    return DropdownMenuItem<int>(
                      value: sound['key'],
                      child: Text(sound['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _soundSelect = value);
                      final selected = finishSounds.firstWhere((s) => s['key'] == value);
                      _audioPlayer.play(AssetSource('sound/${selected['file']}'));
                    }
                  },
                ),
              ),
            ])
        )
    );
  }

  Widget _buildVibrateEnabled(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        color: _themeColor.cardColor,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.vibrateEnabled,
                  style: t.bodyMedium,
                ),
              ),
              Switch(
                value: _vibrateEnabled,
                onChanged: (value) {
                  setState(() {
                    _vibrateEnabled = value;
                  });
                },
              ),
            ],
          ),
        )
    );
  }

  Widget _buildWakelockEnabled(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.wakelockEnabled,
                style: t.bodyMedium,
              ),
            ),
            Switch(
              value: _wakelockEnabled,
              onChanged: (value) {
                setState(() {
                  _wakelockEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOpacity(AppLocalizations l) {
    return Column(
        children: [
          Card(
              margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              color: _themeColor.cardColor,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                    child: Row(
                      children: [
                        Text(l.percentDisplayOpacity),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Row(
                      children: <Widget>[
                        Text(_percentDisplayOpacity.toStringAsFixed(2)),
                        Expanded(
                            child: Slider(
                                value: _percentDisplayOpacity,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                label: _percentDisplayOpacity.toStringAsFixed(2),
                                onChanged: (double value) {
                                  setState(() {
                                    _percentDisplayOpacity = value;
                                  });
                                }
                            )
                        ),
                      ],
                    ),
                  ),
                ],
              )
          ),
          Card(
              margin: const EdgeInsets.only(left: 0, top: 2, right: 0, bottom: 0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              color: _themeColor.cardColor,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                    child: Row(
                      children: [
                        Text(l.timeDisplayOpacity),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Row(
                      children: <Widget>[
                        Text(_timeDisplayOpacity.toStringAsFixed(2)),
                        Expanded(
                            child: Slider(
                                value: _timeDisplayOpacity,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                label: _timeDisplayOpacity.toStringAsFixed(2),
                                onChanged: (double value) {
                                  setState(() {
                                    _timeDisplayOpacity = value;
                                  });
                                }
                            )
                        ),
                      ],
                    ),
                  ),
                ],
              )
          ),
        ]
    );
  }

  Widget _buildSchemeColor(AppLocalizations l) {
    return Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
              child: Row(
                children: [
                  Text(l.colorScheme),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                children: <Widget>[
                  Text(_schemeColor.toStringAsFixed(0)),
                  Expanded(
                      child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _accentColor,
                            inactiveTrackColor: _accentColor.withValues(alpha: 0.3),
                            thumbColor: _accentColor,
                            overlayColor: _accentColor.withValues(alpha: 0.2),
                            valueIndicatorColor: _accentColor,
                          ),
                          child: Slider(
                              value: _schemeColor.toDouble(),
                              min: 0,
                              max: 360,
                              divisions: 360,
                              label: _schemeColor.toString(),
                              onChanged: (double value) {
                                setState(() {
                                  _schemeColor = value.toInt();
                                  _accentColor = _getRainbowAccentColor(_schemeColor);
                                });
                              }
                          )
                      )
                  ),
                ],
              ),
            ),
          ],
        )
    );
  }

  Widget _buildTheme(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.theme,
                style: t.bodyMedium,
              ),
            ),
            DropdownButton<int>(
              value: _themeNumber,
              items: [
                DropdownMenuItem(value: 0, child: Text(l.systemSetting)),
                DropdownMenuItem(value: 1, child: Text(l.lightTheme)),
                DropdownMenuItem(value: 2, child: Text(l.darkTheme)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _themeNumber = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguage(AppLocalizations l) {
    final Map<String,String> languageNames = {
      'af': 'af: Afrikaans',
      'ar': 'ar: العربية',
      'bg': 'bg: Български',
      'bn': 'bn: বাংলা',
      'bs': 'bs: Bosanski',
      'ca': 'ca: Català',
      'cs': 'cs: Čeština',
      'da': 'da: Dansk',
      'de': 'de: Deutsch',
      'el': 'el: Ελληνικά',
      'en': 'en: English',
      'es': 'es: Español',
      'et': 'et: Eesti',
      'fa': 'fa: فارسی',
      'fi': 'fi: Suomi',
      'fil': 'fil: Filipino',
      'fr': 'fr: Français',
      'gu': 'gu: ગુજરાતી',
      'he': 'he: עברית',
      'hi': 'hi: हिन्दी',
      'hr': 'hr: Hrvatski',
      'hu': 'hu: Magyar',
      'id': 'id: Bahasa Indonesia',
      'it': 'it: Italiano',
      'ja': 'ja: 日本語',
      'km': 'km: ខ្មែរ',
      'kn': 'kn: ಕನ್ನಡ',
      'ko': 'ko: 한국어',
      'lt': 'lt: Lietuvių',
      'lv': 'lv: Latviešu',
      'ml': 'ml: മലയാളം',
      'mr': 'mr: मराठी',
      'ms': 'ms: Bahasa Melayu',
      'my': 'my: မြန်မာ',
      'ne': 'ne: नेपाली',
      'nl': 'nl: Nederlands',
      'or': 'or: ଓଡ଼ିଆ',
      'pa': 'pa: ਪੰਜਾਬੀ',
      'pl': 'pl: Polski',
      'pt': 'pt: Português',
      'ro': 'ro: Română',
      'ru': 'ru: Русский',
      'si': 'si: සිංහල',
      'sk': 'sk: Slovenčina',
      'sr': 'sr: Српски',
      'sv': 'sv: Svenska',
      'sw': 'sw: Kiswahili',
      'ta': 'ta: தமிழ்',
      'te': 'te: తెలుగు',
      'th': 'th: ไทย',
      'tl': 'tl: Tagalog',
      'tr': 'tr: Türkçe',
      'uk': 'uk: Українська',
      'ur': 'ur: اردو',
      'uz': 'uz: Oʻzbekcha',
      'vi': 'vi: Tiếng Việt',
      'zh': 'zh: 中文',
      'zu': 'zu: isiZulu',
    };
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.language,
                style: t.bodyMedium,
              ),
            ),
            DropdownButton<String?>(
              value: _languageCode,
              items: [
                DropdownMenuItem(value: '', child: Text('Default')),
                ...languageNames.entries.map((entry) => DropdownMenuItem<String?>(
                  value: entry.key,
                  child: Text(entry.value),
                )),
              ],
              onChanged: (String? value) {
                setState(() {
                  _languageCode = value ?? '';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.reviewApp, style: t.bodyMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.open_in_new, size: 16),
                  label: Text(l.reviewStore, style: t.bodySmall),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 12),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await _inAppReview.openStoreListing(
                      appStoreId: 'YOUR_APP_STORE_ID',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCmp(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    final showButton = _adUmpState.privacyStatus == PrivacyOptionsRequirementStatus.required;
    String statusLabel = l.cmpCheckingRegion;
    IconData statusIcon = Icons.help_outline;
    switch (_adUmpState.privacyStatus) {
      case PrivacyOptionsRequirementStatus.required:
        statusLabel = l.cmpRegionRequiresSettings;
        statusIcon = Icons.privacy_tip_outlined;
        break;
      case PrivacyOptionsRequirementStatus.notRequired:
        statusLabel = l.cmpRegionNoSettingsRequired;
        statusIcon = Icons.check_circle_outline;
        break;
      case PrivacyOptionsRequirementStatus.unknown:
        statusLabel = l.cmpRegionCheckFailed;
        statusIcon = Icons.error_outline;
        break;
    }
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.cmpSettingsTitle,
              style: t.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l.cmpConsentDescription,
              style: t.bodySmall,
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Chip(
                    avatar: Icon(statusIcon, size: 18),
                    label: Text(statusLabel),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l.cmpConsentStatusLabel} ${_adUmpState.consentStatus.localized(context)}',
                    style: t.bodySmall,
                  ),
                  if (showButton) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _adUmpState.isChecking
                          ? null
                          : _onTapPrivacyOptions,
                      icon: const Icon(Icons.settings),
                      label: Text(
                        _adUmpState.isChecking
                            ? l.cmpConsentStatusChecking
                            : l.cmpOpenConsentSettings,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _adUmpState.isChecking
                          ? null
                          : _refreshConsentInfo,
                      icon: const Icon(Icons.refresh),
                      label: Text(l.cmpRefreshStatus),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final message = l.cmpResetStatusDone;
                        await ConsentInformation.instance.reset();
                        await _refreshConsentInfo();
                        if (!mounted) {
                          return;
                        }
                        messenger.showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      },
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: Text(l.cmpResetStatus),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
