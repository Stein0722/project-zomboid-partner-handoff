# Project Zomboid Partner 작업 인수인계

이 저장소는 Project Zomboid Build 42.21 환경에서 진행한 모드 구성, 호환 패치, 성능 문제 해결, 테스트 결과를 다음 작업자에게 넘기기 위한 기록입니다.

핵심 목표는 단순합니다.

1. 어떤 모드를 사용 중인지 알 수 있게 한다.
2. 각 `Partner` 패치가 무엇을 고쳤는지 설명한다.
3. 검증된 결과와 아직 조심해야 할 부분을 구분한다.
4. 원본 창작마당 모드와 세이브를 공개 저장소에 포함하지 않는다.

## 현재 기준

- 게임: Project Zomboid Build 42.21.0
- 기준 싱글 세이브의 활성 Mod ID: 199개
- 공웹 파트너 시작점: [START_HERE_WEB_PARTNER.md](START_HERE_WEB_PARTNER.md)
- 모드 목록 스냅샷: [docs/ACTIVE_MODS.md](docs/ACTIVE_MODS.md)
- Partner 패치 목록: [docs/PATCH_CATALOG.md](docs/PATCH_CATALOG.md)
- 작업 연혁: [docs/WORK_HISTORY.md](docs/WORK_HISTORY.md)
- 필수 순서와 호환 규칙: [docs/LOAD_ORDER_AND_COMPAT.md](docs/LOAD_ORDER_AND_COMPAT.md)
- Beyond Ten 최신 인계: [docs/BEYOND_TEN_HANDOFF.md](docs/BEYOND_TEN_HANDOFF.md)
- Viewpoint·탄도 브리지 최신 인계: [docs/VIEWPOINT_BALLISTICS_HANDOFF.md](docs/VIEWPOINT_BALLISTICS_HANDOFF.md)
- 남은 문제와 다음 단계: [docs/KNOWN_ISSUES_AND_NEXT_STEPS.md](docs/KNOWN_ISSUES_AND_NEXT_STEPS.md)

## 중요한 상태

- 원본 싱글 세이브는 전체 백업 뒤 `BeyondTen` → `PartnerMasteryExtension` → `PartnerBeyondTenSkillJournalBridge` 순서로 사용 중입니다. 15레벨 표시, 경험치 획득, 일기장 기록·복구, 재시작, Traits As Skills 병용, 전투와 프레임을 확인했습니다.
- `PartnerBeyondTenSkillJournalBridge` v1.1.0으로 같은 특성 조건의 새 캐릭터가 긴둔기 10레벨을 넘기는 복구를 확인했습니다. 특성의 XP 배율이 다르면 같은 노력량도 다른 절대 XP가 되는 점은 정상 동작입니다.
- `PartnerMasteryExtension`은 현재 v0.3.0-bridge-test입니다. 16~20 성장과 전투 보너스 코드에 Viewpoint 3D 탄도 중복 방지 가드가 들어간 시험 빌드입니다.
- `Viewpoint` 0.1.6.1, `ProjectViewpointQOL`, `PZVoxelStudioViewpoint`는 본 세이브에서 활성화했고 3인칭 휠 줌과 기본 전투를 확인했습니다.
- `ViewpointTrueBallistics`와 `PartnerViewpointBallisticsBridge`는 복제 세이브 전용입니다. 쿼터뷰에서는 PLB, 1·3인칭에서는 VTB가 탄도를 맡도록 전환하는 v0.1.0 시험판이며 아직 본 세이브에는 넣지 않았습니다.
- `PartnerLegend` v0.4.2, `PartnerLegendaryWeaponDrops` v1.3.0, `PartnerJournalExtension` v0.4.3의 현재 사용 파일과 UI·음원 자산을 `patches/`에 보존합니다.
- 오래된 More Traits와 More Traits Definitive는 동시에 사용하지 않습니다. 현재 기준 목록은 Definitive 계열입니다.
- Project RPG와 Sleep With Friends는 현재 기준 목록에서 제외되어 있습니다.

## `patches/` 공개 범위

이 저장소에는 우리가 작성한 독립 패치와 공개 API 연결 코드만 넣었습니다. 다음 두 항목은 설명 파일만 있습니다.

- `PartnerBritaArmorB42Compat`: 원본 스크립트와 유사한 파생 코드가 있어 공개 코드 제외
- `PartnerFantasyWorkshopCat71Fix`: 원본 FBX의 파일명 별칭이므로 모델 파일 제외

`PartnerSpatialRefugeCoop`과 `PartnerJournalExtension`은 우리가 작성한 코드·번역만 포함하며, 의존하는 창작마당 원본 모드의 코드와 자산은 포함하지 않습니다.

## 설치 전에

- 원본 창작마당 모드를 먼저 설치합니다.
- [로드 순서 문서](docs/LOAD_ORDER_AND_COMPAT.md)를 확인합니다.
- 현재 세이브 전체를 ZIP으로 백업합니다.
- 먼저 복제 세이브나 새 테스트 월드에서 확인합니다.
- 게임 실행 중에는 모드 파일을 교체하지 않습니다.

## 저장소 성격과 권리

이 저장소는 개인 작업 인수인계용입니다. 별도 라이선스를 부여하지 않았으며, 창작마당 원본 모드의 코드·모델·번역·자산에 대한 권리를 주장하지 않습니다. 원본 모드는 각 제작자의 창작마당 페이지에서 받아야 합니다.
