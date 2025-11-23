import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/story_model.dart';

// Widget para el cursor parpadeante
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({Key? key}) : super(key: key);

  @override
  _BlinkingCursorState createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(
        ' >', // El cursor
        style: GoogleFonts.vt323( // Usamos VT323 si está disponible, o courierPrime
          color: Colors.greenAccent,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class TerminalOverlay extends StatefulWidget {
  final Story story;
  final VoidCallback onFinished;

  const TerminalOverlay({
    Key? key,
    required this.story,
    required this.onFinished,
  }) : super(key: key);

  @override
  _TerminalOverlayState createState() => _TerminalOverlayState();
}

class _TerminalOverlayState extends State<TerminalOverlay> {
  int _currentLineIndex = 0;
  bool _isAnimating = true;

  void _nextDialogue() {
    if (!_isAnimating) {
      if (_currentLineIndex < widget.story.dialogues.length - 1) {
        setState(() {
          _currentLineIndex++;
          _isAnimating = true;
        });
      } else {
        widget.onFinished();
      }
    } else {
      // Si el usuario toca mientras se escribe, saltamos la animación (opcional)
      // Nota: AnimatedTextKit no tiene un método simple para "saltar al final" nativamente
      // sin reconstruir, pero detener la animación es un buen paso intermedio.
      setState(() {
        _isAnimating = false;
      });
    }
  }

  Color _getSpeakerColor(Speaker speaker) {
    switch (speaker) {
      case Speaker.sara:
        return Colors.cyanAccent;
      case Speaker.voidVirus:
        return Colors.redAccent;
      case Speaker.system:
        return Colors.greenAccent; // "default" eliminado
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLine = widget.story.dialogues[_currentLineIndex];
    final speakerColor = _getSpeakerColor(currentLine.speaker);

    return GestureDetector(
      onTap: _nextDialogue,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // CAMBIO AQUÍ: Usamos un Stack para asegurarnos de que el dialogo quede
        // en el centro, pero permitiendo que otros elementos (como el FAB del juego)
        // queden visualmente "detrás" o fuera del foco.
        body: Stack(
          children: [
            // Fondo oscuro para atenuar el juego detrás
            Container(color: Colors.black.withOpacity(0.5)),

            // La Caja de Diálogo Centrada
            Align(
              alignment: Alignment.center, // <--- ¡AQUÍ ESTÁ EL CAMBIO CLAVE!
              child: Container(
                // Aumenté el margen horizontal para que se vea más "centrado" y no toque los bordes
                margin: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                padding: const EdgeInsets.all(20.0),
                // Constraints para que no sea ni muy chica ni muy alta
                constraints: const BoxConstraints(minHeight: 150, maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.95), // Fondo más sólido para leer mejor
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: speakerColor.withOpacity(0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: speakerColor.withOpacity(0.2),
                      blurRadius: 20.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // Alinear verticalmente al centro
                  children: [
                    // --- AVATAR ---
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: speakerColor, width: 2),
                        borderRadius: BorderRadius.circular(8), // Un poco más cuadrado estilo chip
                        color: Colors.black,
                        boxShadow: [
                           BoxShadow(color: speakerColor.withOpacity(0.3), blurRadius: 10)
                        ]
                      ),
                      child: ClipRRect( // ClipRRect para asegurar que la imagen respete el borde
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          currentLine.avatarAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.broken_image,
                              color: speakerColor,
                              size: 40),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // --- TEXTO ---
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre del Speaker
                          Text(
                            currentLine.speaker.name.toUpperCase(),
                            style: GoogleFonts.vt323(
                              color: speakerColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(color: speakerColor, blurRadius: 10)
                              ]
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          // Contenedor flexible para el texto
                          Flexible(
                            child: Stack(
                              children: [
                                // El texto animado
                                _isAnimating
                                    ? AnimatedTextKit(
                                        key: ValueKey(_currentLineIndex),
                                        isRepeatingAnimation: false,
                                        onFinished: () => setState(() => _isAnimating = false),
                                        animatedTexts: [
                                          TypewriterAnimatedText(
                                            currentLine.text,
                                            textStyle: GoogleFonts.vt323(
                                              color: Colors.white,
                                              fontSize: 20,
                                              height: 1.3,
                                            ),
                                            speed: const Duration(milliseconds: 30),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        currentLine.text,
                                        style: GoogleFonts.vt323(
                                          color: Colors.white,
                                          fontSize: 20,
                                          height: 1.3,
                                        ),
                                      ),
                                
                                // El cursor parpadeante
                                if (!_isAnimating)
                                  const Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: _BlinkingCursor(),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
