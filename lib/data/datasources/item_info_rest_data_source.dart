// Archivo: lib/data/datasources/item_info_rest_data_source.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../models/item_info_model.dart';
import '../../core/utils/logger.dart'; // Importar logger

abstract class ItemInfoRestDataSource {
  Future<List<ItemInfoModel>> getAllItemsInfo();
}

class ItemInfoRestDataSourceImpl implements ItemInfoRestDataSource {
  final http.Client client;
  final String _className = "ItemInfoRestDataSourceImpl";

  ItemInfoRestDataSourceImpl({required this.client});

  @override
  Future<List<ItemInfoModel>> getAllItemsInfo() async {
    final methodName = "$_className.getAllItemsInfo";
    final url = ApiConstants.baseUrl + ApiConstants.itemInfoEndpoint;
    logD("[$methodName] Iniciando petición GET a: $url");

    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      logD("[$methodName] Respuesta recibida con statusCode: ${response.statusCode}");
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        logI("[$methodName] Petición exitosa. Decodificando y mapeando ${jsonList.length} items.");
        final result =
            jsonList.map((json) => ItemInfoModel.fromJson(json)).toList();
        logD("[$methodName] Mapeo completado. Retornando lista de modelos.");
        return result;
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        logW(
            "[$methodName] Error del cliente (4xx). StatusCode: ${response.statusCode}, Body: ${response.body}");
        // Podríamos intentar decodificar el cuerpo si la API devuelve errores JSON
        // String errorMessage = "Error del cliente: ${response.statusCode}";
        // try {
        //   final errorBody = json.decode(response.body);
        //   errorMessage = errorBody['message'] ?? errorMessage;
        // } catch (_) {
        //   // No hacer nada si el cuerpo no es JSON o no tiene 'message'
        // }
        // throw ServerException(errorMessage);
        throw ServerException("Error del cliente: ${response.statusCode}");
      } else {
        logE(
            "[$methodName] Error del servidor (5xx o inesperado). StatusCode: ${response.statusCode}, Body: ${response.body}");
        throw ServerException("Error del servidor: ${response.statusCode}");
      }
    } on TimeoutException catch (e, s) {
      logE("[$methodName] TimeoutException", error: e, stackTrace: s);
      throw NetworkException("Timeout de la petición. Verifica tu conexión.");
    } on http.ClientException catch (e,s) { // Captura errores de cliente HTTP como SocketException
      logE("[$methodName] ClientException (probablemente de red)", error: e, stackTrace: s);
      throw NetworkException("Error de conexión: ${e.message}");
    } on FormatException catch (e, s) {
      logE("[$methodName] FormatException (error de parseo JSON)", error: e, stackTrace: s);
      throw ParsingException("Error al procesar la respuesta del servidor.");
    } catch (e, s) {
      // Para cualquier otra excepción no anticipada.
      logE("[$methodName] Excepción no controlada", error: e, stackTrace: s);
      // Considera si ServerException es el mejor fallback o si una AppException más genérica sería mejor.
      // Por ahora, mantenemos ServerException si no es un error de red o parseo ya capturado.
      throw ServerException("Ocurrió un error inesperado: ${e.toString()}");
    }
  }
}
