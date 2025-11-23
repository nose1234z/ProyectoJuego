import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'dart:math';
import 'package:iadenfender/components/base.dart';
import 'package:iadenfender/components/enemy.dart';
import 'package:iadenfender/components/player_unit.dart';
import 'package:iadenfender/components/upgrade_button.dart';
import 'package:iadenfender/components/gold_generator.dart';
import 'package:iadenfender/components/barricade.dart';
import 'package:iadenfender/components/boss.dart';
import 'package:iadenfender/components/projectile_preview_game.dart';
import 'package:iadenfender/services/data_manager.dart';
import 'package:iadenfender/services/payment_service.dart';
import 'package:iadenfender/services/music_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:iadenfender/data/story_data.dart';
import 'package:iadenfender/widgets/terminal_overlay.dart';

class Wave {
  final int numEnemies;
  final double spawnInterval;
  Wave({required this.numEnemies, required this.spawnInterval});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  await Supabase.initialize(
    url: 'https://xsfpmymssipfvjeaufqy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzZnBteW1zc2lwZnZqZWF1ZnF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyNzMwNDAsImV4cCI6MjA3Nzg0OTA0MH0._LtCi7QfQGFYSlchua4-rUFCNi7BbLYkzbdhtMvzBLw',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IA Defender',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: AuthHandler(),
    );
  }
}

class AuthHandler extends StatelessWidget {
  const AuthHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final session = snapshot.data?.session;
        if (session != null) {
          return MainMenuApp();
        }
        return const AuthScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController(); // Nickname
  bool _isLoading = false;
  bool _isLogin = true; // To toggle between Login and Sign Up

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      // 1. Sign up the user with metadata including username
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'username': _usernameController.text.trim()},
        emailRedirectTo: null, // Asegura que use la configuración por defecto
      );

      // The profile will be created automatically by a database trigger

      if (!mounted) return;

      // Verificar si necesita confirmación de email
      if (response.user != null &&
          response.user!.identities != null &&
          response.user!.identities!.isEmpty) {
        // Usuario ya existe
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este email ya está registrado. Intenta iniciar sesión.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Registro exitoso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Ya puedes iniciar sesión.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );

        // Cambiar a la pantalla de login después del registro
        setState(() {
          _isLogin = true;
        });
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Nickname'),
                ),
              ],
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _isLogin ? _signIn : _signUp,
                  child: Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse'),
                ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin
                      ? '¿No tienes cuenta? Regístrate'
                      : '¿Ya tienes cuenta? Inicia Sesión',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainMenuApp extends StatefulWidget {
  const MainMenuApp({super.key});

  @override
  State<MainMenuApp> createState() => _MainMenuAppState();
}

enum AppScreen { inicio, seleccion, tienda, personalizacion, juego }


class _MainMenuAppState extends State<MainMenuApp> with WidgetsBindingObserver {
  AppScreen screen = AppScreen.inicio;
  int selectedLevel = 1;
  late DataManager _dataManager;
  late Future<void> _dataManagerLoadingFuture;
  MyGame? _game;

  @override
  void initState() {
    super.initState();
    _dataManager = DataManager();
    _dataManagerLoadingFuture = _dataManager.load();
    // Reproducir música del menú
    MusicService().playMenu();
    // Escuchar cuando la app vuelve a tener foco
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MusicService().stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Cuando la app vuelve a estar activa (después de abrir el navegador)
    if (state == AppLifecycleState.resumed) {
      _reloadData();
    }
  }

  Future<void> _reloadData() async {
    setState(() {
      _dataManagerLoadingFuture = _dataManager.load();
    });
  }

  void _showSettingsDialog(BuildContext context) {
    double currentVolume = 0.5; // Volumen inicial

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings, color: Colors.amber),
              SizedBox(width: 10),
              Text('Configuración'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Control de volumen de música
              const Text(
                'Volumen de Música',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.volume_down),
                  Expanded(
                    child: Slider(
                      value: currentVolume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: '${(currentVolume * 100).round()}%',
                      onChanged: (value) {
                        setDialogState(() {
                          currentVolume = value;
                        });
                        MusicService().setVolume(value);
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up),
                ],
              ),
              Text(
                '${(currentVolume * 100).round()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectileSkinCard({
    required String name,
    required String description,
    required String spritePath,
    required int cost,
    required bool isOwned,
    String? icon, // Opcional - si es null, usa la imagen del sprite
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade800, Colors.purple.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Mostrar imagen del sprite o emoji
                if (icon != null)
                  Text(icon, style: const TextStyle(fontSize: 40))
                else
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyan, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/$spritePath',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(description, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Ver Preview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showProjectilePreview(spritePath, name),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOwned
                          ? Colors.grey
                          : (_dataManager.gems >= cost
                                ? Colors.green.shade700
                                : Colors.red.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: isOwned
                        ? null
                        : (_dataManager.gems >= cost
                              ? () => _purchaseProjectileSkin(
                                  name,
                                  cost,
                                  spritePath,
                                )
                              : null),
                    child: Text(
                      isOwned
                          ? 'Comprado'
                          : (cost == 0 ? 'Gratis' : '$cost Gemas'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectilePreview(String spritePath, String skinName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          height: 350,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.cyan, width: 2),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade900,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, color: Colors.cyan),
                    const SizedBox(width: 10),
                    Text(
                      'Preview: $skinName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GameWidget(
                    game: ProjectilePreviewGame(
                      projectileSpritePath: spritePath,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchaseProjectileSkin(
    String name,
    int cost,
    String skinPath,
  ) async {
    if (_dataManager.gems < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes suficientes gemas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Comprar skin (ya deduce las gemas automáticamente vía RPC)
      await _dataManager.purchaseSkin(skinPath);

      setState(() {}); // Actualizar UI

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Skin "$name" comprada! Ve a Personalización para equiparla.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al comprar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildLevelButton(int level) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        onPressed: () => setState(() {
          selectedLevel = level;
          screen = AppScreen.juego;
        }),
        child: Text('Nivel $level'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dataManagerLoadingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error al cargar datos: ${snapshot.error}'),
            ),
          );
        }

        // Data is loaded, build the UI based on the current screen
        switch (screen) {
          case AppScreen.inicio:
            return _buildInicioScreen();
          case AppScreen.seleccion:
            return _buildSeleccionScreen();
          case AppScreen.tienda:
            return _buildTiendaScreen();
          case AppScreen.personalizacion:
            return _buildPersonalizacionScreen();
          case AppScreen.juego:
            return _buildJuegoScreen();
        }
      },
    );
  }

  Widget _buildInicioScreen() {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/escenario/inicio.png', fit: BoxFit.cover),
          // Contador de gemas en la parte superior
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.diamond, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${_dataManager.gems}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => setState(() => screen = AppScreen.seleccion),
                  child: const Text('JUGAR'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => setState(() => screen = AppScreen.tienda),
                  child: const Text('Tienda'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () =>
                      setState(() => screen = AppScreen.personalizacion),
                  child: const Text('Personalización'),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () async {
                    await supabase.auth.signOut();
                  },
                  child: const Text('Cerrar Sesión'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeleccionScreen() {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/escenario/nivel.jpeg', fit: BoxFit.cover),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Selecciona un nivel',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 40),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLevelButton(1),
                      _buildLevelButton(2),
                      _buildLevelButton(3),
                      _buildLevelButton(4),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => setState(() => screen = AppScreen.inicio),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizacionScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalización'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => screen = AppScreen.inicio);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade900, Colors.black],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Header
            const Text(
              'Equipa tus Skins',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Personaliza la apariencia de tu juego',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 30),

            // Sección: Skins de Torre
            _buildSkinCategoryCard(
              title: 'Torre',
              icon: Icons.castle,
              description: 'Cambia la apariencia de tu torre principal',
              skins: [
                {
                  'name': 'Torre Clásica',
                  'path': 'base/torre.png',
                  'owned': true,
                  'equipped':
                      _dataManager.equippedSkins['tower'] == 'base/torre.png',
                },
              ],
              onEquip: (skinPath) async {
                try {
                  await _dataManager.equipSkin('tower', skinPath);
                  setState(() {});
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Skin equipada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            // Sección: Skins de Aliado
            _buildSkinCategoryCard(
              title: 'Aliados',
              icon: Icons.person,
              description: 'Cambia la apariencia de tus unidades aliadas',
              skins: [
                {
                  'name': 'IA Defensor',
                  'path': 'base/AI.png',
                  'owned': true,
                  'equipped':
                      _dataManager.equippedSkins['ally'] == 'base/AI.png',
                },
              ],
              onEquip: (skinPath) async {
                try {
                  await _dataManager.equipSkin('ally', skinPath);
                  setState(() {});
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Skin equipada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            // Sección: Skins de Proyectil
            _buildSkinCategoryCard(
              title: 'Proyectiles',
              icon: Icons.flash_on,
              description: 'Cambia la apariencia de los proyectiles',
              skins: [
                {
                  'name': 'Proyectil Básico',
                  'path': 'projectiles/projectile1.png',
                  'owned': true,
                  'equipped':
                      _dataManager.equippedSkins['projectile'] ==
                      'projectiles/projectile1.png',
                },
                {
                  'name': 'Proyectil de Fuego',
                  'path': 'projectiles/projectile2.png',
                  'owned': _dataManager.ownedSkins.contains(
                    'projectiles/projectile2.png',
                  ),
                  'equipped':
                      _dataManager.equippedSkins['projectile'] ==
                      'projectiles/projectile2.png',
                },
              ],
              onEquip: (skinPath) async {
                try {
                  await _dataManager.equipSkin('projectile', skinPath);
                  setState(() {});
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Skin equipada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinCategoryCard({
    required String title,
    required IconData icon,
    required String description,
    required List<Map<String, dynamic>> skins,
    required Future<void> Function(String) onEquip,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade800, Colors.purple.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...skins.map(
              (skin) => _buildSkinItem(
                name: skin['name'],
                path: skin['path'],
                owned: skin['owned'],
                equipped: skin['equipped'],
                onEquip: () => onEquip(skin['path']),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinItem({
    required String name,
    required String path,
    required bool owned,
    required bool equipped,
    required VoidCallback onEquip,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: equipped
            ? Colors.cyan.withOpacity(0.2)
            : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: equipped ? Colors.cyan : Colors.white24,
          width: equipped ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Miniatura de la skin
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset('assets/images/$path', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (equipped)
                  const Text(
                    'Equipado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          if (owned && !equipped)
            ElevatedButton(
              onPressed: onEquip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text('Equipar'),
            )
          else if (!owned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.lock, size: 16, color: Colors.red),
                  SizedBox(width: 4),
                  Text('Bloqueado', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTiendaScreen() {
    // Reproducir música de tienda cuando se muestra esta pantalla
    MusicService().playShop();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tienda'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              MusicService().playMenu(); // Volver a música del menú
              setState(() => screen = AppScreen.inicio);
            },
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Text(
                  'Gemas: ${_dataManager.gems}',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.upgrade), text: 'Mejoras'),
              Tab(icon: Icon(Icons.brush), text: 'Skins'),
              Tab(icon: Icon(Icons.diamond), text: 'Comprar Gemas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Upgrades Tab
            ListView.builder(
              itemCount: _dataManager.shopItems.length,
              itemBuilder: (context, index) {
                final item = _dataManager.shopItems[index];
                final level = _dataManager.getUpgradeLevel(item['id']);
                final cost = _dataManager.getUpgradeCost(item['id']);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Text(
                      item['icon'],
                      style: const TextStyle(fontSize: 30),
                    ),
                    title: Text('${item['name']} (Nivel $level)'),
                    subtitle: Text(item['description']),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dataManager.gems >= cost
                            ? Colors.green
                            : Colors.grey,
                      ),
                      onPressed: () async {
                        if (_dataManager.gems >= cost) {
                          try {
                            await _dataManager.purchaseUpgrade(item['id']);
                            // Reload data to show new gem count and level
                            await _reloadData();
                          } catch (e) {
                            if (!mounted) return;
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Text('$cost Gemas'),
                    ),
                  ),
                );
              },
            ),
            // Skins Tab - Proyectiles
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Skin de Proyectil - Premium
                _buildProjectileSkinCard(
                  name: 'Proyectil de Fuego',
                  description: 'Proyectil con efecto de llamas.',
                  spritePath: 'projectiles/projectile2.png',
                  cost: 150,
                  isOwned: _dataManager.isSkinOwned(
                    'projectiles/projectile2.png',
                  ),
                  icon: null, // Usar imagen en lugar de emoji
                ),
              ],
            ),
            // Comprar Gemas Tab
            _buildComprarGemasTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildComprarGemasTab() {
    final packages = PaymentService.gemPackages;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.purple.shade900, Colors.black],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final package = packages[index];
          return Card(
            elevation: 8,
            margin: const EdgeInsets.symmetric(vertical: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade700, Colors.amber.shade300],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.diamond,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${package['gems']} Gemas',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (package['bonus'] != null &&
                                  package['bonus'] > 0)
                                Text(
                                  '+${package['bonus']} gemas gratis',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            final success = await PaymentService.processPayment(
                              packageId: package['id'],
                              title: package['name'],
                              gems: package['gems'] + (package['bonus'] ?? 0),
                              price: package['price'],
                            );

                            if (!mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Abriendo Mercado Pago en el navegador. Completa el pago y regresa a la app.',
                                  ),
                                  backgroundColor: Colors.blue,
                                  duration: Duration(seconds: 5),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        },
                        child: Text(
                          '\$${package['price']} MXN',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJuegoScreen() {
    // Reproducir música del nivel
    MusicService().playLevel(selectedLevel);

    // Crear la instancia del juego
    _game = MyGame(
      level: selectedLevel,
      dataManager: _dataManager,
      onGameWon: (int gemsAwarded) async {
        await _dataManager.addGems(gemsAwarded);
        setState(() {
          _game = null; // Limpiar instancia del juego
          _reloadData();
          screen = AppScreen.seleccion;
        });
        MusicService().playMenu();
      },
      onGameOver: () {
        setState(() {
          _game = null; // Limpiar instancia del juego
          screen = AppScreen.seleccion;
        });
        MusicService().playMenu();
      },
    );

    // Verificar si se debe mostrar la historia
    final story = gameStories[selectedLevel];
    final bool _showStory =
        story != null && !_dataManager.readStoryLevels.contains(selectedLevel);

    if (_showStory) {
      _game!.pauseEngine(); // Pausar el juego para mostrar la historia
    }

    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            child: GameWidget(game: _game!),
            onTapDown: (details) {
              if (_game != null && !_game!.paused) {
                _game!.handleTap(
                  Vector2(details.localPosition.dx, details.localPosition.dy),
                );
              }
            },
          ),
          // Overlay de la historia
          if (_showStory)
            TerminalOverlay(
              story: story,
              onFinished: () {
                _game!.resumeEngine();
                _dataManager.markStoryAsRead(selectedLevel);
                setState(() {}); // Para que el TerminalOverlay desaparezca
              },
            ),
          // Botón de configuración (solo si no se muestra la historia)
          if (!_showStory)
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () => _showSettingsDialog(context),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Volver al menú',
        onPressed: () {
          MusicService().playMenu();
          setState(() {
            _game = null; // Limpiar instancia del juego
            screen = AppScreen.inicio;
          });
        },
        child: const Icon(Icons.home),
      ),
    );
  }
}

class MyGame extends FlameGame with HasCollisionDetection {
  final int level;
  final DataManager dataManager;
  final Function(int) onGameWon;
  final VoidCallback onGameOver;

  MyGame({
    required this.level,
    required this.dataManager,
    required this.onGameWon,
    required this.onGameOver,
  });

  late Base playerBase;
  late double currentGold;
  double goldPerSecond = 0.5;
  GoldGenerator? goldGenerator;

  int damageLevel = 0,
      attackSpeedLevel = 0,
      healingLevel = 0,
      baseHealthLevel = 0,
      barricadeLevel = 0;

  int totalAllies = 0;
  static const int maxAllies = 4;
  late double baseUnitDamage;
  double baseUnitAttackSpeed = 1.0;
  double baseHealingAmount = 5.0;
  late double baseMaxHealth;
  double baseBarricadeHealth = 150.0;

  Barricade? currentBarricade;
  Boss? currentBoss;
  bool isBossPhase = false;
  double baseBossHealth = 500.0;

  double _spawnTimer = 0.0, _currentSpawnInterval = 1.0, _autoHealTimer = 0.0;
  static const _autoHealInterval = 15.0;

  late TextComponent goldText, waveText, gameStatusText, statsText;
  bool isGameOver = false, gameWon = false;

  int currentWaveNumber = 0;
  List<Wave> waves = [];
  int enemiesToSpawnInCurrentWave = 0,
      enemiesSpawnedInCurrentWave = 0,
      enemiesRemainingInCurrentWave = 0;

  late List<Sprite> enemySprites;
  late Sprite baseSprite, playerUnitSprite, bossSprite;
  final Random _random = Random();
  late Map<String, UpgradeButton> upgradeButtons;

  void onAllyRemoved() {
    if (totalAllies > 0) {
      totalAllies--;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // --- Apply Permanent Upgrades from DataManager ---
    baseUnitDamage = 10.0 + dataManager.permanentDamageBonus;
    baseMaxHealth = 100.0 + dataManager.permanentHealthBonus;
    currentGold = 35.0 + dataManager.permanentGoldBonus;

    upgradeButtons = {};

    String mapPath;
    switch (level) {
      case 1:
        mapPath = 'escenario/mapa1.png';
        waves = [
          Wave(numEnemies: 5, spawnInterval: 3.0),
          Wave(numEnemies: 8, spawnInterval: 2.5),
          Wave(numEnemies: 10, spawnInterval: 2.0),
        ];
        break;
      case 2:
        mapPath = 'escenario/mapa2.png';
        waves = [
          Wave(numEnemies: 5, spawnInterval: 3.0),
          Wave(numEnemies: 8, spawnInterval: 2.5),
          Wave(numEnemies: 10, spawnInterval: 2.0),
        ];
        break;
      case 3:
        mapPath = 'escenario/mapa3.png';
        waves = [
          Wave(numEnemies: 5, spawnInterval: 3.0),
          Wave(numEnemies: 8, spawnInterval: 2.5),
          Wave(numEnemies: 10, spawnInterval: 2.0),
        ];
        break;
      case 4:
        mapPath = 'escenario/mapa4.png';
        // Nivel 4: Solo boss para pruebas
        waves = [];
        break;
      default:
        mapPath = 'escenario/mapa1.png';
        waves = [Wave(numEnemies: 5, spawnInterval: 3.0)];
    }

    final bg = await loadSprite(mapPath);
    add(SpriteComponent(sprite: bg, size: size));

    enemySprites = await Future.wait([
      loadSprite('enemies/malware.png'),
      loadSprite('enemies/gusano.png'),
    ]);
    bossSprite = await loadSprite('boss/ADWARE.png');

    try {
      // Usar skins equipadas del DataManager
      final towerSkin =
          dataManager.getEquippedSkin('tower') ?? 'base/torre.png';
      final allySkin = dataManager.getEquippedSkin('ally') ?? 'base/AI.png';

      baseSprite = await loadSprite(towerSkin);
      playerUnitSprite = await loadSprite(allySkin);
    } catch (e) {
      baseSprite = enemySprites[0];
      playerUnitSprite = enemySprites[1];
    }

    playerBase = Base(
      sprite: baseSprite,
      position: Vector2(100, size.y - 300),
      size: Vector2(100, 200),
      health: baseMaxHealth,
      maxHealth: baseMaxHealth,
      onBaseDestroyed: _onGameOver,
    );
    add(playerBase);

    goldText = TextComponent(
      text: 'Gold: ${currentGold.toInt()}',
      position: Vector2(20, 20),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24.0,
          color: Colors.amber,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(goldText);

    waveText = TextComponent(
      text: 'Wave: 0',
      position: Vector2(size.x / 2, 20),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(waveText);

    gameStatusText = TextComponent(
      text: '',
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(gameStatusText);

    statsText = TextComponent(
      text: 'Aliados: 0\nDaño: 10.0\nVel. Ataque: 1.00x\nCuración: +5/15s',
      position: Vector2(20, size.y - 100),
      anchor: Anchor.bottomLeft,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 14.0, color: Colors.white),
      ),
    );
    add(statsText);

    goldGenerator = GoldGenerator(
      position: Vector2(size.x - 120, 20),
      size: Vector2(100, 50),
    );
    add(goldGenerator!);

    const buttonWidth = 100.0, buttonHeight = 70.0, spacing = 8.0;
    final totalButtonsWidth = (buttonWidth + spacing) * 6 - spacing;
    final startX = (size.x - totalButtonsWidth) / 2;
    final startY = size.y - buttonHeight - 20;

    upgradeButtons['allies'] = UpgradeButton(
      upgradeType: 'allies',
      upgradeCost: 30,
      onUpgrade: _buyAlly,
      position: Vector2(startX, startY),
      size: Vector2(buttonWidth, buttonHeight),
    );
    add(upgradeButtons['allies']!);
    upgradeButtons['barricade'] = UpgradeButton(
      upgradeType: 'barricade',
      upgradeCost: 50,
      onUpgrade: _upgradeBarricade,
      position: Vector2(startX + (buttonWidth + spacing) * 1, startY),
      size: Vector2(buttonWidth, buttonHeight),
    );
    add(upgradeButtons['barricade']!);
    upgradeButtons['damage'] = UpgradeButton(
      upgradeType: 'damage',
      upgradeCost: 25,
      onUpgrade: _upgradeDamage,
      position: Vector2(startX + (buttonWidth + spacing) * 2, startY),
      size: Vector2(buttonWidth, buttonHeight),
    );
    add(upgradeButtons['damage']!);
    upgradeButtons['attackSpeed'] = UpgradeButton(
      upgradeType: 'attackSpeed',
      upgradeCost: 40,
      onUpgrade: _upgradeAttackSpeed,
      position: Vector2(startX + (buttonWidth + spacing) * 3, startY),
      size: Vector2(buttonWidth, buttonHeight),
    );
    add(upgradeButtons['attackSpeed']!);
    upgradeButtons['healing'] = UpgradeButton(
      upgradeType: 'healing',
      upgradeCost: 50,
      onUpgrade: _upgradeHealing,
      position: Vector2(startX + (buttonWidth + spacing) * 4, startY),
      size: Vector2(buttonWidth, buttonHeight),
    );
    add(upgradeButtons['healing']!);
    upgradeButtons['baseHealth'] = UpgradeButton(
      upgradeType: 'baseHealth',
      upgradeCost: 60,
      onUpgrade: _upgradeBaseHealth,
      position: Vector2(startX + (buttonWidth + spacing) * 5, startY),
      size: Vector2(buttonWidth, buttonHeight),
    );
    add(upgradeButtons['baseHealth']!);

    // Si es nivel 4, iniciar boss inmediatamente
    if (level == 4) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!isGameOver && !gameWon) {
          _startBossPhase();
        }
      });
    } else {
      startNextWave();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver || gameWon) return;

    if (!isBossPhase) {
      _spawnTimer += dt;
      if (_spawnTimer >= _currentSpawnInterval) {
        _spawnTimer = 0.0;
        spawnEnemy();
      }
    }

    _autoHealTimer += dt;
    if (_autoHealTimer >= _autoHealInterval) {
      _autoHealTimer = 0.0;
      if (playerBase.health < playerBase.maxHealth) {
        playerBase.repair(baseHealingAmount * (1 + healingLevel * 0.3));
      }
    }

    if (!isBossPhase) {
      if (enemiesSpawnedInCurrentWave >= enemiesToSpawnInCurrentWave &&
          enemiesRemainingInCurrentWave <= 0) {
        if (currentWaveNumber < waves.length) {
          startNextWave();
        } else {
          _startBossPhase();
        }
      }
    } else {
      if ((currentBoss == null || currentBoss!.health <= 0) &&
          children.whereType<Enemy>().isEmpty) {
        _onGameWin();
      }
    }

    statsText.text = _getStatsText();
  }

  String _getStatsText() =>
      'Aliados: $totalAllies\n'
      'Daño: ${(baseUnitDamage * (1 + damageLevel * 0.2)).toStringAsFixed(1)}\n'
      'Vel. Ataque: ${(baseUnitAttackSpeed * (1 + attackSpeedLevel * 0.15)).toStringAsFixed(2)}x\n'
      'Curación: +${(baseHealingAmount * (1 + healingLevel * 0.3)).toStringAsFixed(0)}/15s';

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isBossPhase && !isGameOver && !gameWon) {
      const barWidth = 200.0;
      const barHeight = 20.0;
      final barX = (size.x / 2) - (barWidth / 2);
      final barY = 65.0;
      final killsRequired = enemiesToSpawnInCurrentWave;
      final killsDone = (killsRequired - enemiesRemainingInCurrentWave).clamp(
        0,
        killsRequired,
      );
      final progress = killsRequired > 0 ? killsDone / killsRequired : 0.0;
      canvas.drawRect(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        Paint()
          ..color = Colors.grey.withAlpha(128)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        Rect.fromLTWH(barX, barY, barWidth * progress, barHeight),
        Paint()
          ..color = Colors.cyan.withAlpha(204)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$enemiesRemainingInCurrentWave/$enemiesToSpawnInCurrentWave',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          barX + (barWidth / 2) - (textPainter.width / 2),
          barY + (barHeight / 2) - (textPainter.height / 2),
        ),
      );
    }
  }

  void startNextWave() {
    currentWaveNumber++;
    if (currentWaveNumber > waves.length) {
      _startBossPhase();
      return;
    }
    final wave = waves[currentWaveNumber - 1];
    enemiesToSpawnInCurrentWave = wave.numEnemies;
    enemiesSpawnedInCurrentWave = 0;
    enemiesRemainingInCurrentWave = wave.numEnemies;
    _currentSpawnInterval = wave.spawnInterval;
    _spawnTimer = 0.0;
    waveText.text = 'Wave: $currentWaveNumber/${waves.length}';
  }

  void spawnHordeEnemy() {
    final enemyHealth = 30.0 + (currentWaveNumber * currentWaveNumber * 8);
    final enemy = Enemy(
      sprite: enemySprites[_random.nextInt(enemySprites.length)],
      position: Vector2(
        size.x + 25 + _random.nextDouble() * 100,
        size.y * 0.4 + _random.nextDouble() * 150,
      ),
      size: Vector2(50, 50),
      health: enemyHealth,
      speed: 30 + _random.nextDouble() * 15,
      damage: 10,
      goldValue: (10 + (currentWaveNumber * currentWaveNumber * 2)).toDouble(),
    );
    add(enemy);
  }

  void _startBossPhase() {
    isBossPhase = true;
    waveText.text = 'BOSS PHASE';
    gameStatusText.text = 'Defeat the Boss!';
    final bossHealth = baseBossHealth * (1 + (baseHealthLevel * 0.25));
    currentBoss = Boss(
      sprite: bossSprite,
      position: Vector2(size.x - 300, size.y / 2 - 100),
      size: Vector2(200, 200),
      health: bossHealth,
    );
    add(currentBoss!);

    // Solo en nivel 4 NO spawneamos oleada (para probar colisiones)
    if (level != 4) {
      // Spawn una oleada de enemigos normales junto con el boss
      final hordeSize = 8 + (level * 2);
      for (int i = 0; i < hordeSize; i++) {
        Future.delayed(Duration(milliseconds: i * 500), () {
          if (!isGameOver && !gameWon) {
            spawnHordeEnemy();
          }
        });
      }
    }
  }

  void spawnEnemy() {
    if (enemiesSpawnedInCurrentWave < enemiesToSpawnInCurrentWave) {
      final enemyHealth = 30.0 + (currentWaveNumber * currentWaveNumber * 8);
      final enemy = Enemy(
        sprite: enemySprites[_random.nextInt(enemySprites.length)],
        position: Vector2(
          size.x + 25,
          size.y * 0.5 + _random.nextDouble() * 100 - 25,
        ),
        size: Vector2(50, 50),
        health: enemyHealth,
        speed: 30,
        damage: 10,
        goldValue: (10 + (currentWaveNumber * currentWaveNumber * 2))
            .toDouble(),
      );
      add(enemy);
      enemiesSpawnedInCurrentWave++;
    }
  }

  void addGold(double amount, {bool fromKill = false}) {
    currentGold += amount;
    goldText.text = 'Gold: ${currentGold.toInt()}';
    if (fromKill && !isGameOver && !gameWon && !isBossPhase) {
      if (enemiesRemainingInCurrentWave > 0) {
        enemiesRemainingInCurrentWave--;
      }
    }
  }

  void _buyAlly() {
    totalAllies++;
    goldPerSecond += 0.2;
    goldGenerator?.setGoldPerSecond(goldPerSecond);
    _spawnPlayerUnit();
  }

  void _upgradeBarricade() {
    barricadeLevel++;
    final newHealth = baseBarricadeHealth * (1 + barricadeLevel * 0.3);
    if (currentBarricade != null) {
      currentBarricade!.health = newHealth;
      currentBarricade!.healthBar.maxHealth = newHealth;
    } else {
      _spawnBarricade(newHealth);
    }
  }

  void _spawnBarricade(double health) {
    final wallWidth = 10.0;
    final wallHeight = 300.0;
    final wallX = 450.0;
    final wallY = size.y - 200.0;
    currentBarricade = Barricade(
      sprite: playerUnitSprite,
      position: Vector2(wallX - wallWidth / 2, wallY - wallHeight / 2),
      size: Vector2(wallWidth, wallHeight),
      health: health,
    );
    add(currentBarricade!);
  }

  void _upgradeDamage() {
    damageLevel++;
    for (final unit in children.whereType<PlayerUnit>()) {
      unit.attackDamage = baseUnitDamage * (1 + damageLevel * 0.2);
    }
  }

  void _upgradeAttackSpeed() {
    attackSpeedLevel++;
    for (final unit in children.whereType<PlayerUnit>()) {
      unit.attackSpeed = baseUnitAttackSpeed * (1 + attackSpeedLevel * 0.15);
    }
  }

  void _upgradeHealing() {
    healingLevel++;
  }

  void _upgradeBaseHealth() {
    baseHealthLevel++;
    final newMaxHealth = baseMaxHealth * (1 + baseHealthLevel * 0.25);
    playerBase.health =
        (playerBase.health / playerBase.maxHealth) * newMaxHealth;
    playerBase.maxHealth = newMaxHealth;
  }

  void _spawnPlayerUnit() {
    final leftColumnX = playerBase.position.x + playerBase.size.x + 50.0;
    final spacingX = 120.0;
    final rowSpacing = 45.0;
    final baseY = playerBase.position.y + playerBase.size.y + 10.0;
    final index = totalAllies - 1;
    final middleRowY = baseY - rowSpacing;
    final topRowY = baseY - rowSpacing * 2;
    final centerX = leftColumnX + spacingX / 2.0;
    List<Vector2> positions;
    switch (totalAllies) {
      case 1:
        positions = [Vector2(centerX, topRowY)];
        break;
      case 2:
        positions = [
          Vector2(leftColumnX, topRowY),
          Vector2(leftColumnX + spacingX, topRowY),
        ];
        break;
      case 3:
        positions = [
          Vector2(leftColumnX, topRowY),
          Vector2(leftColumnX + spacingX, topRowY),
          Vector2(centerX, middleRowY),
        ];
        break;
      case 4:
      default:
        positions = [
          Vector2(leftColumnX, topRowY),
          Vector2(leftColumnX + spacingX, topRowY),
          Vector2(leftColumnX, middleRowY),
          Vector2(leftColumnX + spacingX, middleRowY),
        ];
    }
    final pos =
        positions[index < positions.length ? index : positions.length - 1];
    add(
      PlayerUnit(
        sprite: playerUnitSprite,
        position: pos,
        size: Vector2(40, 40),
        health: 50,
        attackDamage: baseUnitDamage * (1 + damageLevel * 0.2),
        attackSpeed: baseUnitAttackSpeed * (1 + attackSpeedLevel * 0.15),
        range: 150,
      ),
    );
  }

  void _onGameOver() {
    isGameOver = true;
    gameStatusText.text = 'GAME OVER!';
    children.whereType<Enemy>().forEach((e) => e.removeFromParent());
    onGameOver();
  }

  void _onGameWin() {
    gameWon = true;
    gameStatusText.text = 'VICTORY!';
    final gemsAwarded = 10 + (level * 5);
    onGameWon(gemsAwarded);
  }

  void handleTap(Vector2 pos) {
    if (isGameOver || gameWon) return;
    for (final btn in upgradeButtons.values) {
      if (btn.containsPoint(pos)) {
        btn.onClick();
        break;
      }
    }
  }
}
