import 'package:dio/dio.dart';
import '../models/ticket.dart';

class ApiService {
  final _dio = Dio(BaseOptions(baseUrl: 'https://event-ticketing-ruddy.vercel.app/api'));

  Future<List<Ticket>> getTickets() async {
    final response = await _dio.get('/tickets');
    return (response.data as List).map((t) => Ticket.fromJson(t)).toList();
  }

  Future<void> addTicket(String name) async {
    await _dio.post('/tickets', data: {'name': name});
  }

  Future<void> deleteTicket(String id) async {
    await _dio.delete('/tickets', queryParameters: {'id': id});
  }

  Future<void> scanTicket(String qrData) async {
    await _dio.post('/scan', data: {'qr_data': qrData});
  }
}