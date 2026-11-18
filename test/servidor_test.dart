import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/servidor.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('la URL del Servidor se convierte en la base de la API', () {
    expect(
      apiDeServidor('https://nutrimezzo.tailnet.ts.net'),
      Uri.parse('https://nutrimezzo.tailnet.ts.net/api/'),
    );
    expect(
      apiDeServidor(' https://nutrimezzo.tailnet.ts.net/ '),
      Uri.parse('https://nutrimezzo.tailnet.ts.net/api/'),
    );
    expect(
      apiDeServidor('http://192.168.1.5:8080/nutri'),
      Uri.parse('http://192.168.1.5:8080/nutri/api/'),
    );
    expect(apiDeServidor(''), isNull);
    expect(apiDeServidor('   '), isNull);
  });

  test('el Servidor vacío o http(s) es válido; lo demás no', () {
    expect(validarServidor(''), isNull);
    expect(validarServidor('https://nutrimezzo.tailnet.ts.net'), isNull);
    expect(validarServidor('http://100.64.0.1:8080'), isNull);
    expect(validarServidor('nutrimezzo.tailnet.ts.net'), isNotNull);
    expect(validarServidor('ftp://nutrimezzo'), isNotNull);
    expect(validarServidor('https://'), isNotNull);
  });

  test('web es siempre alojado en su mismo origen', () async {
    SharedPreferences.setMockInitialValues({'servidor.url': ''});

    final modo = await resolverModo(
      web: true,
      origen: Uri.parse('https://nutrimezzo.tailnet.ts.net/algo?x=1'),
    );

    expect(
      modo,
      ModoAlojado(Uri.parse('https://nutrimezzo.tailnet.ts.net/api/')),
    );
  });

  test('Android sin Servidor es offline; con Servidor, alojado', () async {
    expect(await resolverModo(web: false), isA<ModoOffline>());

    await guardarServidor('https://nutrimezzo.tailnet.ts.net');
    expect(
      await resolverModo(web: false),
      ModoAlojado(Uri.parse('https://nutrimezzo.tailnet.ts.net/api/')),
    );

    await guardarServidor('');
    expect(await resolverModo(web: false), isA<ModoOffline>());
  });
}
