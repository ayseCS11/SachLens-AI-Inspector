import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../checks/link_check.dart';

class LinkScreen extends StatefulWidget {
  const LinkScreen({super.key});

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  final TextEditingController _controller = TextEditingController();
  LinkReport? _report;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _controller.text = text.trim();
    _check();
  }

  void _check() {
    FocusScope.of(context).unfocus();
    setState(() => _report = analyzeLink(_controller.text));
  }

  Color _colorFor(double severity) {
    if (severity >= 0.7) return Colors.red.shade700;
    if (severity >= 0.3) return Colors.amber.shade800;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;

    return Scaffold(
      appBar: AppBar(title: const Text('Link checker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Paste a link from a message or email. SachLens checks the link text on this phone. '
                'It never opens the link and sends nothing anywhere.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Link',
              hintText: 'example.com/page',
            ),
            onSubmitted: (_) => _check(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _check,
                  icon: const Icon(Icons.search),
                  label: const Text('Check link'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.paste),
                label: const Text('Paste'),
              ),
            ],
          ),
          if (r != null) ...[
            const SizedBox(height: 16),
            if (!r.valid)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'That does not look like a link. Try something like example.com/page.'),
                ),
              )
            else ...[
              Card(
                color: _colorFor(r.worst).withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.verdict,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _colorFor(r.worst),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Website name: ${r.host}'),
                    ],
                  ),
                ),
              ),
              ...r.findings.map(
                    (f) => ListTile(
                  leading: Icon(Icons.flag, color: _colorFor(f.severity)),
                  title: Text(f.title),
                  subtitle: Text(f.detail),
                ),
              ),
              if (r.findings.isEmpty)
                const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('No warning signs in the link text'),
                ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'This check only reads the link text. It cannot know whether the website itself is safe, '
                        'so never enter passwords or codes on a site you were pushed to open.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}