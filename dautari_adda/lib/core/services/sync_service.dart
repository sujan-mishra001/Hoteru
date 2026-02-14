import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dautari_adda/core/api/api_service.dart';
import 'package:dautari_adda/features/pos/data/pos_models.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ApiService _apiService = ApiService();
  
  List<MenuCategory> _categories = [];
  List<PosTable> _tables = [];
  List<FloorInfo> _floors = [];
  Map<String, dynamic>? _activeSession;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  List<MenuCategory> get categories => _categories;
  List<PosTable> get tables => _tables;
  List<FloorInfo> get floors => _floors;
  Map<String, dynamic>? get activeSession => _activeSession;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  // Cache duration: 5 minutes for menu/tables if not forced
  bool get isCacheValid => _lastSyncTime != null && 
      DateTime.now().difference(_lastSyncTime!).inMinutes < 5;

  Future<void> syncPOSData({bool force = false}) async {
    if (!force && isCacheValid) return;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      print('SYNC_DEBUG: Starting full POS sync...');
      final startTime = DateTime.now();
      
      final response = await _apiService.get('/pos/sync');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // 1. Parse Menu
        final List categoriesJson = data['categories'] ?? [];
        final List groupsJson = data['groups'] ?? [];
        final List itemsJson = data['items'] ?? [];
        _categories = _buildMenu(categoriesJson, groupsJson, itemsJson);
        
        // 2. Parse Floors
        final List floorsJson = data['floors'] ?? [];
        _floors = floorsJson.map((f) => FloorInfo.fromJson(f)).toList();
        
        // 3. Parse Tables
        final List tablesJson = data['tables'] ?? [];
        _tables = tablesJson.map((t) => PosTable.fromJson(t)).toList();

        // 4. Parse Active Session
        _activeSession = data['active_session'];
        
        _lastSyncTime = DateTime.now();
        final duration = _lastSyncTime!.difference(startTime).inMilliseconds;
        print('SYNC_DEBUG: Sync completed in ${duration}ms');
      } else {
        print('SYNC_DEBUG: Sync failed with status ${response.statusCode}');
      }
    } catch (e) {
      print("SYNC_DEBUG: Sync Error: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> startSession(double openingCash) async {
    try {
      final response = await _apiService.post('/sessions', {
        'opening_cash': openingCash,
        'notes': 'Started from Mobile App',
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        await syncPOSData(force: true);
        return true;
      }
      return false;
    } catch (e) {
      print("SYNC_DEBUG: Start Session Error: $e");
      return false;
    }
  }

  Future<bool> endSession() async {
    if (_activeSession == null) return false;
    try {
      final response = await _apiService.put('/sessions/${_activeSession!['id']}', {
        'status': 'Closed',
      });
      if (response.statusCode == 200) {
        await syncPOSData(force: true);
        return true;
      }
      return false;
    } catch (e) {
      print("SYNC_DEBUG: End Session Error: $e");
      return false;
    }
  }

  List<MenuCategory> _buildMenu(List cats, List groups, List items) {
    return cats.map((cat) {
      final catId = cat['id'];
      final catType = cat['type'] ?? 'KOT';
      final catImage = cat['image'];
      
      final categoryGroups = groups.where((g) => g['category_id'] == catId).toList();
      final topLevelItems = items.where((i) => i['category_id'] == catId && i['group_id'] == null).toList();
      
      final subCategories = categoryGroups.map((group) {
        final groupId = group['id'];
        final groupItems = items.where((i) => i['group_id'] == groupId).toList();
        
        return MenuCategory(
          id: groupId,
          name: group['name'] ?? '',
          type: catType,
          image: group['image'],
          items: groupItems.map((i) => MenuItem.fromMap(Map<String, dynamic>.from(i))).toList(),
        );
      }).toList();

      return MenuCategory(
        id: catId,
        name: cat['name'] ?? '',
        type: catType,
        image: catImage,
        subCategories: subCategories,
        items: topLevelItems.map((i) => MenuItem.fromMap(Map<String, dynamic>.from(i))).toList(),
      );
    }).toList();
  }
}
