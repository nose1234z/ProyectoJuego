// lib/models/story_model.dart

enum Speaker { 
  sara, 
  voidVirus, // <--- CAMBIO AQUÍ (Antes decía 'void')
  system 
}

class DialogueLine {
  final Speaker speaker;
  final String text;
  final String avatarAsset;

  DialogueLine({
    required this.speaker,
    required this.text,
    required this.avatarAsset,
  });
}

class Story {
  final int levelId;
  final List<DialogueLine> dialogues;

  Story({
    required this.levelId,
    required this.dialogues,
  });
}
