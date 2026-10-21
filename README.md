# Project Zomboid Partner 작업 인수인계

이 저장소는 Project Zomboid Build 42.21 환경에서 진행한 모드 구성, 호환 패치, 성능 문제 해결, 테스트 결과를 다음 작업자에게 넘기기 위한 기록입니다.

핵심 목표는 단순합니다.

1. 어떤 모드를 사용 중인지 알 수 있게 한다.
2. 각 `Partner` 패치가 무엇을 고쳤는지 설명한다.
3. 검증된 결과와 아직 조심해야 할 부분을 구분한다.
4. 원본 창작마당 모드와 세이브를 공개 저장소에 포함하지 않는다.

## 현재 기준

- 게임: Project Zomboid Build 42.21.0
- 기준 싱글 세이브의 활성 Mod ID: 191개
- 공웹 파트너 시작점: [START_HERE_WEB_PARTNER.md](START_HERE_WEB_PARTNER.md)
- 모드 목록 스냅샷: [docs/ACTIVE_MODS.md](docs/ACTIVE_MODS.md)
- Partner 패치 목록: [docs/PATCH_CATALOG.md](docs/PATCH_CATALOG.md)
- 작업 연혁: [docs/WORK_HISTORY.md](docs/WORK_HISTORY.md)
- 필수 순서와 호환 규칙: [docs/LOAD_ORDER_AND_COMPAT.md](docs/LOAD_ORDER_AND_COMPAT.md)
- Beyond Ten 최신 인계: [docs/BEYOND_TEN_HANDOFF.md](docs/BEYOND_TEN_HANDOFF.md)
- 남은 문제와 다음 단계: [docs/KNOWN_ISSUES_AND_NEXT_STEPS.md](docs/KNOWN_ISSUES_AND_NEXT_STEPS.md)

## 중요한 상태

- 원본 싱글 세이브는 전체 백업 뒤 `BeyondTen` → `PartnerMasteryExtension` → `PartnerBeyondTenSkillJournalBridge` 순서로 활성 목록에 추가했습니다. 첫 본세이브 실행 확인은 아직 남았습니다.
- 두 모드는 복제 세이브에서 15레벨 표시, 경험치 획득, 일기장 기록, 재시작 유지, 사망 후 새 캐릭터 복구, Traits As Skills 병용, 전투와 프레임을 확인했습니다.
- `PartnerBeyondTenSkillJournalBridge` v1.0.1은 복제 세이브 인게임 시험을 통과했습니다. 선택적 16~20 XP 보존을 더한 v1.1.0은 자동 계약 시험을 통과했지만 아직 인게임 시험 전입니다.
- `PartnerMasteryExtension` v0.2.1은 16~20레벨 XP·보라색 UI와 핵심 보너스 50% 연장을 추가하는 싱글플레이 베타입니다. 보라색 UI는 복제 세이브에서 확인했고 보너스 계산과 Build 42 JSON 번역 검증을 통과했습니다.
- 오래된 More Traits와 More Traits Definitive는 동시에 사용하지 않습니다. 현재 기준 목록은 Definitive 계열입니다.
- Project RPG, Sleep With Friends, Viewpoint 계열은 현재 기준 목록에서 제외되어 있습니다.

## `patches/` 공개 범위

이 저장소에는 우리가 작성한 독립 패치와 공개 API 연결 코드만 넣었습니다. 다음 두 항목은 설명 파일만 있습니다.

- `PartnerBritaArmorB42Compat`: 원본 스크립트와 유사한 파생 코드가 있어 공개 코드 제외
- `PartnerFantasyWorkshopCat71Fix`: 원본 FBX의 파일명 별칭이므로 모델 파일 제외

`PartnerSpatialRefugeCoop`은 인수인계에 필요한 Partner Lua와 스크립트만 포함하며, 원본 모드 번역·자산은 포함하지 않습니다. 따라서 GitHub 사본만으로 완전 설치되는 배포본이 아니라 코드 검토용입니다.

## 설치 전에

- 원본 창작마당 모드를 먼저 설치합니다.
- [로드 순서 문서](docs/LOAD_ORDER_AND_COMPAT.md)를 확인합니다.
- 현재 세이브 전체를 ZIP으로 백업합니다.
- 먼저 복제 세이브나 새 테스트 월드에서 확인합니다.
- 게임 실행 중에는 모드 파일을 교체하지 않습니다.

## 저장소 성격과 권리

이 저장소는 개인 작업 인수인계용입니다. 별도 라이선스를 부여하지 않았으며, 창작마당 원본 모드의 코드·모델·번역·자산에 대한 권리를 주장하지 않습니다. 원본 모드는 각 제작자의 창작마당 페이지에서 받아야 합니다.
