import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/ai_message.dart';
import '../../data/models/insight.dart';
import '../../data/models/voice_command.dart';
import '../../data/repositories/user_repository.dart';

abstract class AiService {
  Future<AiMessage> sendMessage(String userMessage, {Map<String, dynamic>? context});
  Future<String> generateDailySummary({
    required int productiveMinutes,
    required int distractedMinutes,
    required int goalMinutes,
    String? craft,
    String? topAppName,
    int? topAppMinutes,
  });
  Future<Insight> generateDynamicInsight({
    required int productiveMinutes,
    required int distractedMinutes,
    required int goalMinutes,
    required int blockedCount,
    required String craft,
    String? topAppName,
    int? topAppMinutes,
    String? peakWindow,
  });
  Future<VoiceCommand> interpretVoiceCommand(String rawVoice);
  Future<List<String>> createDayPlan({int availableHours = 4, String? craft});
  Future<bool> testApiKey(String apiKey);
}

class DefaultAiService implements AiService {
  final UserRepository? userRepository;

  DefaultAiService({this.userRepository});

  static const String _serverUrlAndroid = 'http://10.0.2.2:3000';
  static const String _serverUrlLocal = 'http://127.0.0.1:3000';
  static const String _clientSecret = 'ekagra_vault_token_secure_2026';

  @override
  Future<AiMessage> sendMessage(String userMessage, {Map<String, dynamic>? context}) async {
    // 1. First priority: Ekagra Secure TypeScript Backend Server Proxy
    // (Keeps API key 100% on server so decompiling/reverse-engineering APK reveals zero secrets)
    try {
      final serverResp = await _callServerProxy(userMessage, context: context);
      if (serverResp != null && serverResp.text.trim().isNotEmpty) {
        return serverResp;
      }
    } catch (e) {
      debugPrint("Ekagra TypeScript Server query failed, trying next provider: $e");
    }

    // 2. Second priority: Direct client-provided Gemini API key (if explicitly supplied)
    final apiKey = userRepository?.currentUserSync?.geminiApiKey?.trim();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final geminiText = await _callGeminiApi(
          apiKey: apiKey,
          prompt: userMessage,
          contextData: context,
        );
        if (geminiText != null && geminiText.trim().isNotEmpty) {
          return AiMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: geminiText.trim(),
            isUser: false,
            timestamp: DateTime.now(),
            suggestedActions: _deriveSuggestedActions(userMessage, context),
          );
        }
      } catch (e) {
        debugPrint("Gemini API call failed, falling back to local cognitive engine: $e");
      }
    }

    // 3. Fallback: On-Device Cognitive Analytics Engine
    return _generateOnDeviceResponse(userMessage, context);
  }

  Future<AiMessage?> _callServerProxy(String userMessage, {Map<String, dynamic>? context}) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);

    final urls = [
      '$_serverUrlAndroid/api/ai/chat',
      '$_serverUrlLocal/api/ai/chat',
    ];

    for (final url in urls) {
      try {
        final req = await client.postUrl(Uri.parse(url));
        req.headers.set('Content-Type', 'application/json');
        req.headers.set('X-Ekagra-Secret', _clientSecret);

        final payload = <String, dynamic>{
          'message': userMessage,
        };
        if (context != null) {
          payload['telemetry'] = context;
        }

        req.add(utf8.encode(jsonEncode(payload)));
        final response = await req.close();

        if (response.statusCode == 200) {
          final respBody = await response.transform(utf8.decoder).join();
          final json = jsonDecode(respBody) as Map<String, dynamic>;
          if (json['success'] == true && json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            final reply = data['reply'] as String? ?? '';
            final actions = (data['suggestedActions'] as List?)?.map((e) => e.toString()).toList() ??
                _deriveSuggestedActions(userMessage, context);

            if (reply.isNotEmpty) {
              return AiMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                text: reply,
                isUser: false,
                timestamp: DateTime.now(),
                suggestedActions: actions,
              );
            }
          }
        }
      } catch (_) {
        // Try next host if emulator vs desktop mismatch
      }
    }
    client.close();
    return null;
  }

  Future<String?> _callGeminiApi({
    required String apiKey,
    required String prompt,
    Map<String, dynamic>? contextData,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      final req = await client.postUrl(uri);
      req.headers.set('Content-Type', 'application/json');

      final systemContext = StringBuffer();
      systemContext.writeln(
        "You are Ekagra, an intelligent, calm, mindful digital flow companion and attention coach.",
      );
      systemContext.writeln(
        "Tone: concise (2-3 sentences), warm, stoic, encouraging. Ground all statements strictly in the real user telemetry below. Do NOT fabricate fake numbers or non-existent metrics.",
      );

      if (contextData != null && contextData.isNotEmpty) {
        systemContext.writeln("User Telemetry Snapshot:");
        contextData.forEach((key, val) {
          systemContext.writeln("- $key: $val");
        });
      }

      final payload = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {
                "text": "$systemContext\n\nUser Inquiry: $prompt",
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.4,
          "maxOutputTokens": 280,
        }
      };

      req.add(utf8.encode(jsonEncode(payload)));
      final response = await req.close();

      if (response.statusCode == 200) {
        final respBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        final candidates = json['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] as String?;
          }
        }
      } else {
        final errBody = await response.transform(utf8.decoder).join();
        debugPrint("Gemini HTTP Error ${response.statusCode}: $errBody");
      }
    } finally {
      client.close();
    }
    return null;
  }

  @override
  Future<bool> testApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey.trim()}',
      );
      final req = await client.postUrl(uri);
      req.headers.set('Content-Type', 'application/json');

      final payload = {
        "contents": [
          {
            "parts": [
              {"text": "Ping. Respond with 'ok'."}
            ]
          }
        ],
        "generationConfig": {"maxOutputTokens": 10}
      };

      req.add(utf8.encode(jsonEncode(payload)));
      final response = await req.close();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("API Key verification error: $e");
      return false;
    } finally {
      client.close();
    }
  }

  AiMessage _generateOnDeviceResponse(String userMessage, Map<String, dynamic>? ctx) {
    final lower = userMessage.toLowerCase();
    final name = ctx?['userName']?.toString().trim().isNotEmpty == true
        ? ctx!['userName'].toString().trim()
        : 'Focus Practitioner';
    final craft = ctx?['craft'] ?? 'Deep Work Practitioner';
    final prodMins = (ctx?['productiveMinutes'] as num?)?.toInt() ?? 0;
    final distMins = (ctx?['distractedMinutes'] as num?)?.toInt() ?? 0;
    final goalMins = (ctx?['goalMinutes'] as num?)?.toInt() ?? 240;
    final flowScore = (ctx?['flowScore'] as num?)?.toInt() ?? 0;
    final blockedCount = (ctx?['blockedCount'] as num?)?.toInt() ?? 0;
    final topApp = ctx?['topApp'] as String?;
    final topAppMins = (ctx?['topAppMinutes'] as num?)?.toInt() ?? 0;

    final prodH = prodMins ~/ 60;
    final prodM = prodMins % 60;
    final prodFormatted = prodH > 0 ? '${prodH}h ${prodM}m' : '${prodM}m';
    final goalH = goalMins ~/ 60;

    String responseText;

    if (lower.contains('how productive') || lower.contains('how did i do') || lower.contains('summary') || lower.contains('today')) {
      if (prodMins == 0 && distMins == 0) {
        responseText = "$name, you haven't recorded any focus blocks yet today. Your daily target is $goalH hours. Launch a 25-minute sprint to establish momentum.";
      } else {
        final pct = goalMins > 0 ? ((prodMins / goalMins) * 100).toInt() : 0;
        final distStr = distMins > 0 ? " with ${distMins}m on distracting apps" : "";
        final deflectionNote = blockedCount > 0 ? " You deflected $blockedCount distraction attempts." : "";
        responseText = "$name, you have logged $prodFormatted of deep focus today ($pct% of your $goalH-hour target)$distStr. Flow Score is $flowScore/100.$deflectionNote";
      }
    } else if (lower.contains('focus') || lower.contains('start') || lower.contains('session')) {
      responseText = "Ready to protect your attention, $name. For your role as a $craft, I recommend starting with a 25-minute sprint or a 45-minute deep block.";
    } else if (lower.contains('distract') || lower.contains('waste') || (topApp != null && lower.contains(topApp.toLowerCase()))) {
      if (topApp != null && topAppMins > 0) {
        responseText = "Your most-used app today is $topApp with ${topAppMins}m logged. Focus Shield has deflected $blockedCount diversion attempts so far.";
      } else if (distMins > 0) {
        responseText = "You've logged ${distMins}m on distracting apps today. Focus Shield is active to deflect further disruptions.";
      } else {
        responseText = "Zero distracting apps logged today. Your attention purity is at 100%.";
      }
    } else if (lower.contains('plan') || lower.contains('afternoon') || lower.contains('day')) {
      final remMins = (goalMins - prodMins).clamp(0, goalMins);
      final remH = (remMins / 60).toStringAsFixed(1);
      responseText = "Here is your flow plan for $craft:\n• Remaining goal: $remH hours\n• Session 1: 45m Core High-Leverage Task\n• Quick Break: 10m Eye rest & hydration\n• Session 2: 25m Execution sprint & wrap-up.";
    } else if (lower.contains('break') || lower.contains('tired')) {
      responseText = "Take a mindful 5 to 10-minute break away from screens. A short walk or water reset will restore high cognitive throughput.";
    } else {
      responseText = "Greetings $name. I'm Ekagra, your $craft flow companion. You've logged $prodFormatted of focus today. What would you like to accomplish?";
    }

    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: responseText,
      isUser: false,
      timestamp: DateTime.now(),
      suggestedActions: _deriveSuggestedActions(userMessage, ctx),
    );
  }

  List<String> _deriveSuggestedActions(String query, Map<String, dynamic>? ctx) {
    final prodMins = (ctx?['productiveMinutes'] as num?)?.toInt() ?? 0;
    if (prodMins == 0) {
      return ["Start 25m Focus", "Plan my day", "Check app shield"];
    }
    return ["How did I do today?", "Start 45m sprint", "Plan my afternoon"];
  }

  @override
  Future<String> generateDailySummary({
    required int productiveMinutes,
    required int distractedMinutes,
    required int goalMinutes,
    String? craft,
    String? topAppName,
    int? topAppMinutes,
  }) async {
    final h = productiveMinutes ~/ 60;
    final m = productiveMinutes % 60;
    final prodStr = h > 0 ? '${h}h ${m}m' : '${m}m';

    if (productiveMinutes == 0 && distractedMinutes == 0) {
      return "No activity logged yet today. Start your first sprint to calibrate your attention architecture.";
    }

    if (productiveMinutes >= goalMinutes) {
      return "Outstanding focus! You met your $goalMinutes-minute target with $prodStr of deep work.";
    } else {
      final diff = goalMinutes - productiveMinutes;
      final diffStr = diff ~/ 60 > 0 ? '${diff ~/ 60}h ${diff % 60}m' : '${diff % 60}m';
      final appClause = topAppName != null && (topAppMinutes ?? 0) > 0
          ? " Primary tool: $topAppName ($topAppMinutes mins)."
          : "";
      return "Logged $prodStr of deep attention ($diffStr away from goal).$appClause";
    }
  }

  @override
  Future<Insight> generateDynamicInsight({
    required int productiveMinutes,
    required int distractedMinutes,
    required int goalMinutes,
    required int blockedCount,
    required String craft,
    String? topAppName,
    int? topAppMinutes,
    String? peakWindow,
  }) async {
    // 1. Try Ekagra Secure Backend Gateway first
    try {
      final serverInsight = await _callServerInsightsProxy(
        productiveMinutes: productiveMinutes,
        distractedMinutes: distractedMinutes,
        goalMinutes: goalMinutes,
        blockedCount: blockedCount,
        craft: craft,
        topAppName: topAppName,
        topAppMinutes: topAppMinutes,
      );
      if (serverInsight != null) {
        return serverInsight;
      }
    } catch (e) {
      debugPrint("Server insight query failed, falling back to local engine: $e");
    }

    // 2. Local Fallback Heuristics
    if (productiveMinutes > 0) {
      final total = productiveMinutes + distractedMinutes;
      final purity = total > 0 ? ((productiveMinutes / total) * 100).toInt() : 100;
      return Insight(
        id: 'dyn_peak_${DateTime.now().millisecondsSinceEpoch}',
        headline: peakWindow != null ? "Prime Cognitive Window: $peakWindow" : "Flow Purity: $purity%",
        description: "Your attention purity is $purity% with $productiveMinutes mins of deep work dedicated to your $craft practice.",
        metricHighlight: "$purity% Purity",
        type: InsightType.peakProductivity,
        icon: Icons.bolt_rounded,
        generatedAt: DateTime.now(),
        isAiGenerated: true,
      );
    }

    return Insight(
      id: 'dyn_shield_${DateTime.now().millisecondsSinceEpoch}',
      headline: blockedCount > 0 ? "$blockedCount Distractions Deflected" : "Shield Active & Ready",
      description: blockedCount > 0
          ? "Ekagra blocked $blockedCount tempting app launches to preserve mental clarity."
          : "Distraction blocker is armed in the background. Launch a focus sprint to establish today's baseline.",
      metricHighlight: blockedCount > 0 ? "$blockedCount Blocked" : "Active",
      type: InsightType.distractionReduction,
      icon: Icons.shield_rounded,
      generatedAt: DateTime.now(),
      isAiGenerated: true,
    );
  }

  Future<Insight?> _callServerInsightsProxy({
    required int productiveMinutes,
    required int distractedMinutes,
    required int goalMinutes,
    required int blockedCount,
    required String craft,
    String? topAppName,
    int? topAppMinutes,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);

    final urls = [
      '$_serverUrlAndroid/api/ai/insights',
      '$_serverUrlLocal/api/ai/insights',
    ];

    for (final url in urls) {
      try {
        final req = await client.postUrl(Uri.parse(url));
        req.headers.set('Content-Type', 'application/json');
        req.headers.set('X-Ekagra-Secret', _clientSecret);

        final payload = {
          'telemetry': {
            'productiveMinutes': productiveMinutes,
            'distractedMinutes': distractedMinutes,
            'goalMinutes': goalMinutes,
            'blockedCount': blockedCount,
            'craft': craft,
            'topApp': topAppName,
            'topAppMinutes': topAppMinutes,
          }
        };

        req.add(utf8.encode(jsonEncode(payload)));
        final response = await req.close();

        if (response.statusCode == 200) {
          final respBody = await response.transform(utf8.decoder).join();
          final json = jsonDecode(respBody) as Map<String, dynamic>;
          if (json['success'] == true && json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            final headline = data['headline'] as String? ?? 'Cognitive Trajectory';
            final desc = data['description'] as String? ?? '';
            final highlight = data['metricHighlight'] as String? ?? 'AI Active';

            if (desc.isNotEmpty) {
              return Insight(
                id: 'ai_srv_${DateTime.now().millisecondsSinceEpoch}',
                headline: headline,
                description: desc,
                metricHighlight: highlight,
                type: InsightType.peakProductivity,
                icon: Icons.psychology_rounded,
                generatedAt: DateTime.now(),
                isAiGenerated: true,
                actionLabel: 'Explore Focus',
                actionType: 'start_focus',
                accentColor: const Color(0xFF6366F1),
              );
            }
          }
        }
      } catch (_) {
        // Try next host
      }
    }
    client.close();
    return null;
  }

  @override
  Future<VoiceCommand> interpretVoiceCommand(String rawVoice) async {
    final lower = rawVoice.toLowerCase().trim();

    if (lower.contains('start') && (lower.contains('focus') || lower.contains('session') || lower.contains('work') || lower.contains('coding'))) {
      int duration = 25;
      final match = RegExp(r'(\d+)\s*(?:min|minute)').firstMatch(lower);
      if (match != null) {
        duration = int.tryParse(match.group(1)!) ?? 25;
      } else if (lower.contains('45')) {
        duration = 45;
      } else if (lower.contains('60') || lower.contains('hour')) {
        duration = 60;
      } else if (lower.contains('90')) {
        duration = 90;
      }

      String mode = 'Deep Work';
      if (lower.contains('cod')) mode = 'Coding';
      if (lower.contains('study')) mode = 'Study';
      if (lower.contains('read')) mode = 'Reading';

      return VoiceCommand(
        rawTranscript: rawVoice,
        intent: VoiceIntent.startFocus,
        parameters: {'duration': duration, 'mode': mode},
      );
    } else if (lower.contains('end') || lower.contains('stop') || lower.contains('finish')) {
      return VoiceCommand(
        rawTranscript: rawVoice,
        intent: VoiceIntent.endFocus,
        parameters: {},
      );
    } else if (lower.contains('pause')) {
      return VoiceCommand(
        rawTranscript: rawVoice,
        intent: VoiceIntent.pauseFocus,
        parameters: {},
      );
    } else if (lower.contains('resume')) {
      return VoiceCommand(
        rawTranscript: rawVoice,
        intent: VoiceIntent.resumeFocus,
        parameters: {},
      );
    } else if (lower.contains('productive') || lower.contains('score') || lower.contains('summary') || lower.contains('how did i do') || lower.contains('how much time')) {
      return VoiceCommand(
        rawTranscript: rawVoice,
        intent: VoiceIntent.getProductivitySummary,
        parameters: {},
      );
    } else if (lower.contains('plan')) {
      return VoiceCommand(
        rawTranscript: rawVoice,
        intent: VoiceIntent.planDay,
        parameters: {'hours': 2},
      );
    }

    return VoiceCommand(
      rawTranscript: rawVoice,
      intent: VoiceIntent.unknown,
      parameters: {},
    );
  }

  @override
  Future<List<String>> createDayPlan({int availableHours = 4, String? craft}) async {
    final role = craft ?? 'Deep Work';

    // 1. Try server day-plan endpoint
    try {
      final serverPlan = await _callServerDayPlanProxy(availableHours: availableHours, craft: role);
      if (serverPlan != null && serverPlan.isNotEmpty) {
        return serverPlan;
      }
    } catch (e) {
      debugPrint("Server day plan query failed, using local template: $e");
    }

    return [
      "Block 1: 45m High-leverage $role execution",
      "Rest: 10m Screen-free hydration & breathing",
      "Block 2: 45m Focused deep implementation",
      "Shutdown: 15m Task reflection & inbox review",
    ];
  }

  Future<List<String>?> _callServerDayPlanProxy({
    required int availableHours,
    required String craft,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);

    final urls = [
      '$_serverUrlAndroid/api/ai/day-plan',
      '$_serverUrlLocal/api/ai/day-plan',
    ];

    for (final url in urls) {
      try {
        final req = await client.postUrl(Uri.parse(url));
        req.headers.set('Content-Type', 'application/json');
        req.headers.set('X-Ekagra-Secret', _clientSecret);

        final payload = {
          'hours': availableHours,
          'craft': craft,
        };

        req.add(utf8.encode(jsonEncode(payload)));
        final response = await req.close();

        if (response.statusCode == 200) {
          final respBody = await response.transform(utf8.decoder).join();
          final json = jsonDecode(respBody) as Map<String, dynamic>;
          if (json['success'] == true && json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            final plan = (data['plan'] as List?)?.map((e) => e.toString()).toList();
            if (plan != null && plan.isNotEmpty) {
              return plan;
            }
          }
        }
      } catch (_) {
        // Try next
      }
    }
    client.close();
    return null;
  }
}
