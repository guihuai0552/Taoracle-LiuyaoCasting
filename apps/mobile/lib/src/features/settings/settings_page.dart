import 'package:flutter/material.dart';

import '../../ui/liuyao_design.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 40),
        children: [
          Row(
            children: [
              const LiuyaoSealMark(character: '藏', label: '本机'),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '设置',
                      key: const Key('settings-title'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '显示偏好与本地档案说明',
                      style: TextStyle(color: LiuyaoColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SettingsSectionLabel('本地数据'),
          const SizedBox(height: 10),
          const LiuyaoPaperCard(
            key: Key('settings-local-data-card'),
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.phonelink_lock_outlined,
                  title: '档案保存在本机',
                  description: '占问、卦面、解读与反馈写入应用私有空间，退出后台后不会清除。',
                ),
                Divider(height: 25, color: LiuyaoColors.inkFaint),
                _SettingsRow(
                  icon: Icons.cloud_off_outlined,
                  title: '离线可用',
                  description: '基础排盘与档案浏览无需登录，也不会自动上传到云端。',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SettingsSectionLabel('数据边界'),
          const SizedBox(height: 10),
          const LiuyaoPaperCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.swap_horiz_rounded,
                  title: '支持跨设备迁移',
                  description: '在“档案”页打开迁移入口，可批量导出或导入全部卦面、解读与反馈。',
                ),
                Divider(height: 25, color: LiuyaoColors.inkFaint),
                _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  title: '卸载前请先导出',
                  description: '清除应用数据或卸载应用会同时移除本地档案，请先生成迁移包并妥善保存。',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '— 资料留于方寸之间 —',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LiuyaoColors.inkFaint,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 17, color: LiuyaoColors.cinnabar),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: LiuyaoColors.parchment,
            border: Border.all(color: LiuyaoColors.inkFaint),
            borderRadius: BorderRadius.circular(LiuyaoRadii.small),
          ),
          child: Icon(icon, size: 21, color: LiuyaoColors.cinnabar),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LiuyaoColors.inkMuted,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
