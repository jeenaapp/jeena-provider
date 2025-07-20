import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _apiKey = 'OPENAI-API-KEY';

  static Future<String> generateServiceDescription(String serviceName, String category) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'أنت مساعد ذكي متخصص في كتابة أوصاف الخدمات باللغة العربية. اكتب وصفاً مختصراً وجذاباً للخدمة المطلوبة.',
            },
            {
              'role': 'user',
              'content': 'اكتب وصفاً مختصراً وجذاباً للخدمة التالية: $serviceName في فئة $category. الوصف يجب أن يكون باللغة العربية ولا يزيد عن 100 كلمة.',
            },
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Failed to generate service description: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating service description: $e');
    }
  }

  static Future<String> generateInvoiceDescription(String serviceName, String customerName, double amount) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'أنت مساعد ذكي متخصص في كتابة أوصاف الفواتير باللغة العربية. اكتب وصفاً مهنياً ومختصراً للفاتورة.',
            },
            {
              'role': 'user',
              'content': 'اكتب وصفاً مهنياً للفاتورة التالية: خدمة "$serviceName" للعميل "$customerName" بمبلغ $amount ريال سعودي. الوصف يجب أن يكون باللغة العربية ومختصراً.',
            },
          ],
          'max_tokens': 150,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Failed to generate invoice description: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating invoice description: $e');
    }
  }

  static Future<String> generateCustomerResponse(String customerMessage, String context) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'أنت مساعد ذكي متخصص في كتابة ردود احترافية على رسائل العملاء باللغة العربية. اكتب رداً مهذباً ومهنياً.',
            },
            {
              'role': 'user',
              'content': 'اكتب رداً مهذباً ومهنياً على رسالة العميل التالية: "$customerMessage". السياق: $context. الرد يجب أن يكون باللغة العربية ومختصراً.',
            },
          ],
          'max_tokens': 200,
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Failed to generate customer response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating customer response: $e');
    }
  }

  static Future<Map<String, dynamic>> generateBusinessInsights(List<Map<String, dynamic>> ordersData) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'أنت محلل أعمال ذكي متخصص في تحليل بيانات الطلبات وتقديم رؤى مفيدة للأعمال. قم بتحليل البيانات المقدمة وأعط رؤى مفيدة وتوصيات باللغة العربية. يجب أن يكون الرد بتنسيق JSON مع المفاتيح التالية: summary, trends, recommendations.',
            },
            {
              'role': 'user',
              'content': 'حلل بيانات الطلبات التالية وأعط رؤى وتوصيات مفيدة: ${jsonEncode(ordersData)}',
            },
          ],
          'max_tokens': 800,
          'temperature': 0.3,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final content = jsonResponse['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        throw Exception('Failed to generate business insights: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating business insights: $e');
    }
  }

  static Future<List<String>> generateServiceTags(String serviceName, String description) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'أنت مساعد ذكي متخصص في إنشاء علامات (tags) للخدمات باللغة العربية. قم بإنشاء قائمة من 5-8 علامات مناسبة للخدمة المقدمة. يجب أن تكون العلامات قصيرة ومفيدة للبحث.',
            },
            {
              'role': 'user',
              'content': 'أنشئ قائمة من العلامات (tags) للخدمة التالية: "$serviceName" - $description. اكتب العلامات مفصولة بفواصل.',
            },
          ],
          'max_tokens': 150,
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final content = jsonResponse['choices'][0]['message']['content'].toString().trim();
        return content.split(',').map((tag) => tag.trim()).toList();
      } else {
        throw Exception('Failed to generate service tags: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating service tags: $e');
    }
  }

  static Future<String> generateSupportResponse(String ticketTitle, String ticketDescription) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'أنت مساعد دعم فني ذكي متخصص في حل مشاكل المستخدمين في منصة جينا للخدمات. قدم حلولاً مفيدة ومفصلة باللغة العربية.',
            },
            {
              'role': 'user',
              'content': 'المستخدم يواجه المشكلة التالية: "$ticketTitle" - $ticketDescription. قدم حلاً مفصلاً وخطوات واضحة لحل المشكلة باللغة العربية.',
            },
          ],
          'max_tokens': 400,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Failed to generate support response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating support response: $e');
    }
  }
}