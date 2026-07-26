import 'package:flutter/material.dart';

import 'agent_client.dart';

class AgentPage extends StatefulWidget {
  const AgentPage({this.caseId, super.key});

  final String? caseId;

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> {
  final AgentClient _client = AgentClient();
  final TextEditingController _controller = TextEditingController();
  final List<({bool isUser, String text})> _messages = [];
  bool _healthy = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    final healthy = await _client.isHealthy();
    if (mounted) setState(() => _healthy = healthy);
  }

  Future<void> _send() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _sending = true;
      _messages.add((isUser: true, text: prompt));
    });

    try {
      final answer = await _client.chat(prompt, caseId: widget.caseId);
      if (mounted) {
        setState(() {
          _healthy = true;
          _messages.add((isUser: false, text: answer));
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _healthy = false;
          _messages.add((isUser: false, text: '连接失败：$error'));
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _client.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.caseId == null ? '存档助手' : '卦例助手'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: Icon(
                  Icons.circle,
                  size: 10,
                  color: _healthy ? Colors.green : Colors.orange,
                ),
                label: Text(_healthy ? '已连接' : '本地服务未连接'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const _AgentIntro()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Align(
                          alignment: message.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 560),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: message.isUser
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SelectableText(message.text),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: '让助手整理占问背景或复盘记录…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: '发送',
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentIntro extends StatelessWidget {
  const _AgentIntro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 54,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text('Pi 驱动的存档助手', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            '先启动电脑上的 Agent 服务。助手可帮助整理背景、补齐记录字段和复盘案例。',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
