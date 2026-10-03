import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:shadow_pvz/Util/Asset/SPAsset.dart';
import 'package:shadow_pvz/Util/EventBus/SPEventBus.dart';
import 'package:shadow_pvz/Util/Log/SPLogger.dart';

import '../../../View/Common/import/SPCommonView.dart';
import '../../../View/Game/Kylin/SPGameKylinRole.dart';

class SPGameKylinGaming extends PositionComponent
    with HasGameRef, KeyboardHandler, CollisionCallbacks {
  late SPCommonBackgroundLottieView _backgroundLottieView;
  late SPGameKylinRole _kylin;
  late SPPositionComponent _floor;
  late Timer _obstacleTimer;

  final double _baseMaxHeight = 200;
  final double _jumpSpeed = 0.6;
  final double _fallSpeed = 0.45;
  double _maxHeight = 200;
  double _currentHeight = 0;
  bool _isJumping = false;
  bool _isFalling = false;
  bool _isGameOver = false;
  final double _obstacleSpeed = 50; // Adjust obstacle speed as needed

  @override
  Future<void>? onLoad() async {
    // Load the background
    _backgroundLottieView = SPCommonBackgroundLottieView(
        lottiePath: SPAssetLottie.movingBackgroundOfKylin);
    add(_backgroundLottieView);

    // Create the floor
    _floor = SPPositionComponent(
      size: Vector2(gameRef.size.x, 50),
      position: Vector2(0, gameRef.size.y - 50),
      componentType: ComponentType.floor,
    );
    add(_floor);

    // Create the kylin
    _kylin = SPGameKylinRole(Vector2(100, gameRef.size.y - 90));
    _kylin.roleCollisionStart = (intersectionPoints, other, direction) {
      if (!_isGameOver) {
        if (other is SPPositionComponent &&
            other.componentType == ComponentType.obstacle) {
          SPLogger.d('kylin hit {$direction}');
          // SPLogger.d(intersectionPoints);
          // SPLogger.d(_kylin);
          // SPLogger.d(other);

          if (direction == CollisionDirection.down) {
            _isJumping = false;
            _isFalling = false;
            _kylin.updateState(KylinState.running);

            // Adjust max height based on obstacle
            final obstacleTop = other.position.y;
            final kylinBottom = _kylin.position.y + _kylin.size.y;
            final maxHeightIncrease = obstacleTop - kylinBottom;
            _maxHeight = _baseMaxHeight + maxHeightIncrease;
          } else {
            SPLogger.d('kylin hit SPPositionComponent error direction');
            _isGameOver = true;
            eventBus.fire(SPEvent(SPEventCode.kylinGameOver));
          }
        }
        else if (other is SPPositionComponent &&
            other.componentType == ComponentType.floor) {
          _isJumping = false;
          _isFalling = false;
          _kylin.updateState(KylinState.running);
        } if (other is ScreenHitbox) {
          SPLogger.d('kylin hit screenHitbox');
          _isGameOver = true;
          eventBus.fire(SPEvent(SPEventCode.kylinGameOver));
        }
      }
    };
    _kylin.roleCollisionEnd = (PositionComponent other) {
      if (!_isGameOver) {
        if (other is SPPositionComponent &&
            other.componentType == ComponentType.obstacle) {
          if (_kylin.position.x >= other.position.x + other.size.x) {
            SPLogger.d('kylin fall from obstacle');
            _isJumping = false;
            _isFalling = true;
          }
        }
      }
    };
    add(_kylin);
    add(ScreenHitbox()); // 添加 ScreenHitbox 组件

    // Start obstacle timer
    _obstacleTimer = Timer(5, repeat: true, onTick: _spawnObstacle);
    _obstacleTimer.start();
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!_isGameOver) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.keyZ &&
          !_isFalling) {
        _isJumping = true;
        _isFalling = false;
        _kylin.updateState(KylinState.jumping);
        return true;
      } else if (event is KeyUpEvent &&
          event.logicalKey == LogicalKeyboardKey.keyZ &&
          _isJumping) {
        _isJumping = false;
        _isFalling = true;
        return true;
      }
    }
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _obstacleTimer.update(dt);

    if (!_isGameOver) {
      if (_isJumping) {
        _currentHeight += _jumpSpeed;
        if (_currentHeight >= _maxHeight) {
          _isJumping = false;
          _isFalling = true;
        }
      } else if (_isFalling) {
        _kylin.updateState(KylinState.falling);
        _currentHeight -= _fallSpeed;
      }
      _kylin.updatePosition(Vector2(100, gameRef.size.y - 90 - _currentHeight));

      // Move and remove obstacles
      children.whereType<SPPositionComponent>().forEach((positionComponent) {
        if (positionComponent.componentType == ComponentType.obstacle) {
          positionComponent.position.x -= _obstacleSpeed * dt;
          if (positionComponent.position.x + positionComponent.size.x < 0) {
            positionComponent.removeFromParent();
          }
        }
      });
    }
  }

  void _spawnObstacle() {
    final random = Random();
    const obstacleWidth = 50.0;
    final obstacleHeight = random.nextDouble() * 100;
    final obstacleX = gameRef.size.x;
    final obstacleY = gameRef.size.y - 50 - obstacleHeight;

    final obstacle = SPPositionComponent(
      size: Vector2(obstacleWidth, obstacleHeight),
      position: Vector2(obstacleX, obstacleY),
      paint: Paint()..color = SPAssetColor.getRandomColor(),
      componentType: ComponentType.obstacle,
    );
    obstacle.add(RectangleHitbox());
    add(obstacle);
  }
}