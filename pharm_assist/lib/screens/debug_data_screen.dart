// lib/screens/debug_data_screen.dart
import 'package:flutter/material.dart';
import '../core/services/enhanced_couchdb_service.dart';
import '../core/database/database_service.dart';
import '../models/daily_stats.dart';
import '../core/theme/app_theme.dart';
import '../utils/formatters.dart';

class DebugDataScreen extends StatefulWidget {
  @override
  _DebugDataScreenState createState() => _DebugDataScreenState();
}

class _DebugDataScreenState extends State<DebugDataScreen> {
  bool _isLoading = false;
  String _rawLog = '';
  bool _connected = false;
  List<String> _docIds = [];
  List<DailyStats> _remoteStats = [];
  List<DailyStats> _localStats = [];

  @override
  void initState() {
    super.initState();
    _runFullCheck();
  }

  Future<void> _runFullCheck() async {
    setState(() {
      _isLoading = true;
      _rawLog = 'Running debug check...\n\n';
    });

    final buffer = StringBuffer();
    final service = EnhancedCouchDBService.instance;

    try {
      // 1. Test connection
      buffer.writeln('Testing CouchDB connection...');
      _connected = await service.testConnection();
      buffer.writeln(_connected ? '✅ Connection OK' : '❌ Connection FAILED');

      if (!_connected) {
        throw Exception("No connection to CouchDB");
      }

      // 2. Remote document IDs
      buffer.writeln('\nFetching document IDs...');
      _docIds = await service.getDocumentIds(limit: 10);
      buffer.writeln('Found ${_docIds.length} documents');
      if (_docIds.isNotEmpty) buffer.writeln('Sample: ${_docIds.take(3).join(", ")}');

      // 3. Remote documents
      buffer.writeln('\nFetching remote documents...');
      _remoteStats = await service.getLatestStatsWithDocs(limit: 5);
      buffer.writeln('Parsed ${_remoteStats.length} DailyStats records');
      if (_remoteStats.isNotEmpty) {
        final s = _remoteStats.first;
        buffer.writeln('Sample remote: ${s.date}, Rev=${s.totalRevenue}, Sales=${s.totalSales}');
      }

      // 4. Local database
      buffer.writeln('\nChecking local database...');
      _localStats = await DatabaseService.instance.getAllStats();
      buffer.writeln('Local DB has ${_localStats.length} records');
      if (_localStats.isNotEmpty) {
        final s = _localStats.first;
        buffer.writeln('Sample local: ${s.date}, Rev=${s.totalRevenue}, Sales=${s.totalSales}');
      }

    } catch (e) {
      buffer.writeln('\n❌ Debug check failed: $e');
    }

    setState(() {
      _rawLog = buffer.toString();
      _isLoading = false;
    });
  }

  Widget _buildStatusTile(String title, bool ok) {
    return ListTile(
      leading: Icon(ok ? Icons.check_circle : Icons.error, color: ok ? Colors.green : Colors.red),
      title: Text(title),
    );
  }

  Widget _buildStatsList(String title, List<DailyStats> stats) {
    if (stats.isEmpty) {
      return Card(
        child: ListTile(title: Text('$title: No records found')),
      );
    }
    return Card(
      child: ExpansionTile(
        title: Text('$title (${stats.length})'),
        children: stats.take(5).map((s) {
          return ListTile(
            title: Text('${s.date} - Rev ${Formatters.formatCurrency(s.totalRevenue)}'),
            subtitle: Text('Sales=${s.totalSales}, Items=${s.itemsSold}'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDocIdList() {
    if (_docIds.isEmpty) {
      return Card(child: ListTile(title: Text("No CouchDB documents found")));
    }
    return Card(
      child: ExpansionTile(
        title: Text("Remote Document IDs (${_docIds.length})"),
        children: _docIds.take(10).map((id) => ListTile(title: Text(id))).toList(),
      ),
    );
  }

  Widget _buildRawLog() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SelectableText(
          _rawLog,
          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Debug Data"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _runFullCheck,
              child: ListView(
                padding: EdgeInsets.all(8),
                children: [
                  _buildStatusTile("CouchDB Connection", _connected),
                  _buildDocIdList(),
                  _buildStatsList("Remote Stats", _remoteStats),
                  _buildStatsList("Local Stats", _localStats),
                  SizedBox(height: 12),
                  Text("Raw Debug Log", style: Theme.of(context).textTheme.titleMedium),
                  _buildRawLog(),
                ],
              ),
            ),
    );
  }
}
