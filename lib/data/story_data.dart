
import '../models/story_model.dart';

final Map<int, Story> gameStories = {
  1: Story(
    levelId: 1,
    dialogues: [
      DialogueLine(
        speaker: Speaker.system,
        text: '> INICIANDO SISTEMA DE DEFENSA... [OK]',
        avatarAsset: 'assets/images/base/AI.png',
      ),
      DialogueLine(
        speaker: Speaker.sara,
        text: '¡Admin, estás en línea! Tenemos un problema. Alguien insertó un drive infectado en el servidor local.',
        avatarAsset: 'assets/images/base/AI.png',
      ),
      DialogueLine(
        speaker: Speaker.sara,
        text: 'Son simples Spam-Bots. No son inteligentes, pero son muchos.',
        avatarAsset: 'assets/images/base/AI.png',
      ),
      DialogueLine(
        speaker: Speaker.sara,
        text: 'Coloca torres Firewall (Verdes) en el camino. ¡No dejes que saturen la memoria!',
        avatarAsset: 'assets/images/base/AI.png',
      ),
    ],
  ),
  2: Story(
    levelId: 2,
    dialogues: [
      DialogueLine(
        speaker: Speaker.voidVirus,
        text: '> ACCESO DENEGADO... JA. JA. JA.',
        avatarAsset: 'assets/images/boss/VOID.png',
      ),
      DialogueLine(
        speaker: Speaker.voidVirus,
        text: '¿Crees que puedes borrarme con un simple antivirus gratuito? Qué tierno.',
        avatarAsset: 'assets/images/boss/VOID.png',
      ),
      DialogueLine(
        speaker: Speaker.sara,
        text: '¡Cuidado! Ese fue V0ID, el virus origen. Está enviando unidades Troyanas (Moradas).',
        avatarAsset: 'assets/images/base/AI.png',
      ),
      DialogueLine(
        speaker: Speaker.sara,
        text: 'Tienen un blindaje pesado. Tus Firewalls apenas les harán cosquillas.',
        avatarAsset: 'assets/images/base/AI.png',
      ),
      DialogueLine(
        speaker: Speaker.sara,
        text: 'Necesitas usar el Rayo Cifrador (Azul) para perforar su defensa. ¡Rápido!',
        avatarAsset: 'assets/images/base/AI.png',
      ),
    ],
  ),
  3: Story(
    levelId: 3,
    dialogues: [
      DialogueLine(
        speaker: Speaker.system,
        text: '> ALERTA: TEMPERATURA DE CPU AL 85%.',
        avatarAsset: 'assets/images/base/AI.png',
      ),
      DialogueLine(
        speaker: Speaker.sara,
        text: 'V0ID está cambiando de táctica. Ya no ataca fuerte, ataca rápido.',
        avatarAsset: 'assets/images/base/AI.png',
      ),
      DialogueLine(
        speaker: Speaker.sara,
        text: 'Detecto firmas de Gusanos (Amarillos). Se mueven a velocidades de overclocking.',
        avatarAsset: 'assets/images/base/AI.png',
      ),
      DialogueLine(
        speaker: Speaker.sara,
        text: 'Si se te escapan, usa la Bomba Lógica (Naranja) para dañar a grupos enteros. ¡No pierdas de vista las esquinas!',
        avatarAsset: 'assets/images/base/AI.png',
      ),
    ],
  ),
  4: Story(
    levelId: 4,
    dialogues: [
      DialogueLine(
        speaker: Speaker.voidVirus,
        text: '> FORMAT C: /Q /X ... EJECUTANDO.',
        avatarAsset: 'assets/images/boss/VOID.png',
      ),
      DialogueLine(
        speaker: Speaker.voidVirus,
        text: 'Se acabó el juego, Admin. Voy a tomar control del Kernel. Tu sistema es MÍO.',
        avatarAsset: 'assets/images/boss/VOID.png',
      ),
      DialogueLine(
        speaker: Speaker.sara,
        text: '¡Está intentando un borrado total! Esta es la última línea de defensa.',
        avatarAsset: 'assets/images/base/AI.png',
      ),
      DialogueLine(
        speaker: Speaker.sara,
        text: 'Gasta todas tus gemas. Utiliza todos tus aliados si es necesario. ¡Pero no dejes que V0ID toque el Núcleo!',
        avatarAsset: 'assets/images/base/AI.png',
      ),
       DialogueLine(
        speaker: Speaker.system,
        text: '> PROTOCOLO DE EMERGENCIA ACTIVADO. BUENA SUERTE.',
        avatarAsset: 'assets/images/base/AI.png',
      ),
    ],
  ),
};
