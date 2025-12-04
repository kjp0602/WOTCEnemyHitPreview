Features:
- Shows hit chance for each enemy when previewing movement tiles
- Hit chance is calculated from the preview tile position, not your current position
- Color matches the enemy icon color
- Works with all enemies visible from the target tile

How to use:
- Hold Alt key while hovering over a tile to see hit chances against all visible enemies from that position

Configuration (XComEnemyHitPreview.ini):
- bHideUnrevealedEnemies=true : Only show enemies currently visible to your squad (default)
- bHideUnrevealedEnemies=false : Show all enemies including unrevealed ones

Changelog:
v1.2
- Improved hit chance calculation accuracy
- Height bonus calculation fix (now uses X2TacticalGameRuleset configured values)
- Automatically compatible with vanilla/LWOTC and other mods
- Added weapon upgrade aim bonuses (scope, laser sight, etc.)

v1.1
- Added config option to hide/show unrevealed enemies
- Fixed: Now correctly filters based on squad visibility (scanning protocol, battle scanner, etc.)

v1.0
- Initial release

---

목표물 미리보기(Alt 키)에서 모든 보이는 적에게 명중률을 표시합니다.

기능:
- 이동 타일 미리보기 시 각 적에 대한 명중률 표시
- 명중률은 현재 위치가 아닌 미리보기 타일 위치 기준으로 계산
- 적 아이콘 색상과 동일한 색상 적용
- 해당 타일에서 보이는 모든 적에게 적용

사용법:
- 타일 위에서 Alt 키를 누르면 해당 위치에서 보이는 모든 적에 대한 명중률 확인 가능

설정 (XComEnemyHitPreview.ini):
- bHideUnrevealedEnemies=true : 분대에게 현재 보이는 적만 표시 (기본값)
- bHideUnrevealedEnemies=false : 발견되지 않은 적 포함 모든 적 표시

변경사항:
v1.2
- 명중률 계산 정확도 개선
- 높이 보너스 계산 수정 (X2TacticalGameRuleset 설정값 사용)
- 바닐라/LWOTC 등 모드별 설정값 자동 반영
- 무기 업그레이드 명중 보너스 추가 (스코프, 레이저 사이트 등)

v1.1
- 발견되지 않은 적 숨기기/표시 설정 옵션 추가
- 수정: 분대 가시성 기준으로 올바르게 필터링 (스캐닝 프로토콜, 배틀 스캐너 등 포함)

v1.0
- 최초 릴리즈