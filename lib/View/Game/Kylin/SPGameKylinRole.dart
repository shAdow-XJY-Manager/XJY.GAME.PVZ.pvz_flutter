import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_lottie/flame_lottie.dart';
import 'package:shadow_pvz/Util/Asset/SPAsset.dart';
import 'package:shadow_pvz/Util/Log/SPLogger.dart';

import '../../Common/SPCommonCollisionType.dart';

enum KylinState { running, jumping, falling }

typedef RoleCollisionStartCallback = void Function(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
    CollisionDirection direction,
    );

typedef RoleCollisionEndCallback = void Function(PositionComponent other);

class SPGameKylinRole extends PositionComponent with CollisionCallbacks {
  late LottieComponent _runAnimationComponent;
  late LottieComponent _jumpAnimationComponent;
  late LottieComponent _fallAnimationComponent;
  late RectangleHitbox _rectangleHitbox;

  RoleCollisionStartCallback? roleCollisionStart;
  RoleCollisionEndCallback? roleCollisionEnd;

  KylinState _currentState = KylinState.running;

  // In SPGameKylinRole

  SPGameKylinRole(Vector2 position) : super(position: position, size: Vector2(80, 40)); // Constructor with position parameter

  @override
  Future<void>? onLoad() async {
    // Load Lottie compositions
    final runComposition = await loadLottie(Lottie.asset(SPAssetLottie.jumpingOfKylin));
    final jumpComposition = await loadLottie(Lottie.asset(SPAssetLottie.jumpingOfKylin));
    final fallComposition = await loadLottie(Lottie.asset(SPAssetLottie.jumpingOfKylin));

    SPLogger.d(size);
    SPLogger.d(position);

    // Create animation components
    _runAnimationComponent = LottieComponent(
      runComposition,
      size: size,
      repeating: true,
      // anchor: Anchor.center,
    );
    _jumpAnimationComponent = LottieComponent(
      jumpComposition,
      size: size,
      repeating: true,
      // anchor: Anchor.center,
    );
    _fallAnimationComponent = LottieComponent(
      fallComposition,
      size: size,
      repeating: true,
      // anchor: Anchor.center,
    );

    _rectangleHitbox = RectangleHitbox();
    add(_rectangleHitbox);

    // Initially add the run animation component
    add(_runAnimationComponent);
  }

  void updateState(KylinState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _changeAnimation();
    }
  }

  void updatePosition(Vector2 newPosition) {
    position = newPosition;
  }

  void _changeAnimation() {
    // Remove the current animation component
    removeAll(children);
    add(_rectangleHitbox);
    // Add the new animation component based on the current state
    switch (_currentState) {
      case KylinState.running:
        add(_runAnimationComponent);
        break;
      case KylinState.jumping:
        add(_jumpAnimationComponent);
        break;
      case KylinState.falling:
        add(_fallAnimationComponent);
        break;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (roleCollisionStart != null) {
      // Calculate collision direction
      CollisionDirection direction = _getCollisionDirection(intersectionPoints, other);
      roleCollisionStart!(intersectionPoints, other, direction);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (roleCollisionEnd != null) {
      roleCollisionEnd!(other);
    }
  }

  CollisionDirection _getCollisionDirection(
      Set<Vector2> intersectionPoints, PositionComponent other) {

    if ((other.position.y - (position.y + size.y)).abs() <= 1) {
      return CollisionDirection.down; // Role is below the other component
    } else if ((position.y - (other.position.y + other.size.y)).abs() <= 1 ) {
      return CollisionDirection.up; // Role is above the other component
    } else if ((position.x - (other.position.x + other.size.x)).abs() <= 1) {
      return CollisionDirection.left; // Role is to the left of the other component
    } else {
      return CollisionDirection.right; // Role is to the right of the other component
    }
  }

}