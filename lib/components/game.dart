import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:flutter/material.dart';

import 'background.dart';
import 'brick.dart';
import 'ground.dart';
import 'enemy.dart';
import 'player.dart';  

class MyPhysicsGame extends Forge2DGame {
  MyPhysicsGame()
      : super(
          gravity: Vector2(0, 10),
          camera: CameraComponent.withFixedResolution(width: 800, height: 600),
        );

  late final XmlSpriteSheet aliens;
  late final XmlSpriteSheet elements;
  late final XmlSpriteSheet tiles;

  int attemptCounter = 11;  // Inicializamos con 10 intentos.
  bool gameOver = false;
  TextComponent attemptText = TextComponent(
    text: 'Num. Intentos: 10',
    position: Vector2(10, -20),
    anchor: Anchor.topLeft,
    textRenderer: TextPaint(
      style: const TextStyle(color: Colors.black, fontSize: 3),
    ),
  );

  @override
  FutureOr<void> onLoad() async {
    final backgroundImage = await images.load('colored_desert.png');
    final spriteSheets = await Future.wait([
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_aliens.png',
        xmlPath: 'spritesheet_aliens.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_elements.png',
        xmlPath: 'spritesheet_elements.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_tiles.png',
        xmlPath: 'spritesheet_tiles.xml',
      ),
    ]);

    aliens = spriteSheets[0];
    elements = spriteSheets[1];
    tiles = spriteSheets[2];

    await world.add(Background(sprite: Sprite(backgroundImage)));
    await addGround();
    unawaited(addBricks().then((_) => addEnemies()));
    await addPlayer();
    await world.add(attemptText);

    return super.onLoad();
  }

  Future<void> addGround() {
    return world.addAll([
      for (var x = camera.visibleWorldRect.left;
          x < camera.visibleWorldRect.right + groundSize;
          x += groundSize)
        Ground(
          Vector2(x, (camera.visibleWorldRect.height - groundSize) / 2),
          tiles.getSprite('sand.png'),
        ),
    ]);
  }

  final _random = Random();

  Future<void> addBricks() async {
    for (var i = 0; i < 10; i++) {
      final type = BrickType.randomType;
      final size = BrickSize.randomSize;
      await world.add(
        Brick(
          type: type,
          size: size,
          damage: BrickDamage.some,
          position: Vector2(
              camera.visibleWorldRect.right / 3 +
                  (_random.nextDouble() * 5 - 2.5),
              0),
          sprites: brickFileNames(type, size).map(
            (key, filename) => MapEntry(
              key,
              elements.getSprite(filename),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> addPlayer() async {
    if (gameOver) return;

    attemptCounter--;  // Restamos 1 al contador de intentos.
    attemptText.text = 'Num. Intentos: $attemptCounter';

    if (attemptCounter <= 0) {
      gameOver = true;
      world.add(
        TextComponent(
          text: 'You Lose :(',
          anchor: Anchor.center,
          position: Vector2(0.5, 0.5),
          textRenderer: TextPaint(
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
      return;
    }

    await world.add(
      Player(
        Vector2(camera.visibleWorldRect.left * 2 / 3, 0),
        aliens.getSprite(PlayerColor.randomColor.fileName),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isMounted &&
        !gameOver &&
        world.children.whereType<Player>().isEmpty &&
        world.children.whereType<Enemy>().isNotEmpty) {
      addPlayer();
    }
    if (isMounted &&
        !gameOver &&
        enemiesFullyAdded &&
        world.children.whereType<Enemy>().isEmpty &&
        world.children.whereType<TextComponent>().where((t) => t.text == 'You win!').isEmpty) {
      world.addAll(
        [
          (position: Vector2(0.5, 0.5), color: Colors.white),
          (position: Vector2.zero(), color: Colors.orangeAccent),
        ].map(
          (e) => TextComponent(
            text: 'You win!',
            anchor: Anchor.center,
            position: e.position,
            textRenderer: TextPaint(
              style: TextStyle(color: e.color, fontSize: 16),
            ),
          ),
        ),
      );
    }
  }

  var enemiesFullyAdded = false;

  Future<void> addEnemies() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    for (var i = 0; i < 3; i++) {
      await world.add(
        Enemy(
          Vector2(
              camera.visibleWorldRect.right / 3 +
                  (_random.nextDouble() * 7 - 3.5),
              (_random.nextDouble() * 3)),
          aliens.getSprite(EnemyColor.randomColor.fileName),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    enemiesFullyAdded = true;
  }
}
