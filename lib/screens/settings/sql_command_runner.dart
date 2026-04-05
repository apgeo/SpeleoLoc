import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/localization.dart';

class SQLCommandRunner extends StatefulWidget {
  const SQLCommandRunner({super.key});

  @override
  State<SQLCommandRunner> createState() => _SQLCommandRunnerState();
}

class _SQLCommandRunnerState extends State<SQLCommandRunner> {
  final TextEditingController _sqlController = TextEditingController();
  bool _isRunning = false;
  String _output = '';

  @override
  void dispose() {
    _sqlController.dispose();
    super.dispose();
  }

  Future<void> _runSql() async {
    final sql = _sqlController.text.trim();
    if (sql.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocServ.inst.t('sql_empty_command'))),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      _output = '';
    });

    try {
      final normalized = sql.toLowerCase();
      final isQuery = normalized.startsWith('select') ||
          normalized.startsWith('pragma') ||
          normalized.startsWith('with') ||
          normalized.startsWith('explain');

      if (isQuery) {
        final rows = await appDatabase.customSelect(sql).get();
        if (!mounted) return;

        if (rows.isEmpty) {
          setState(() {
            _output = LocServ.inst.t('sql_no_rows');
          });
          return;
        }

        final buffer = StringBuffer();
        for (final row in rows) {
          buffer.writeln(row.data.toString());
        }

        setState(() {
          _output = buffer.toString().trimRight();
        });
      } else {
        await appDatabase.customStatement(sql);
        if (!mounted) return;
        setState(() {
          _output = LocServ.inst.t('sql_success');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _output = '${LocServ.inst.t('error')}: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocServ.inst.t('sql_command_runner')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _sqlController,
              decoration: InputDecoration(
                labelText: LocServ.inst.t('sql_command'),
                hintText: LocServ.inst.t('sql_command_hint'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,
              minLines: 12,
              maxLines: 20,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runSql,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(LocServ.inst.t('run_sql')),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isRunning
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: SelectableText(
                          _output.isEmpty
                              ? LocServ.inst.t('sql_output_placeholder')
                              : _output,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
