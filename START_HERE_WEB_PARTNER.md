# 공웹 파트너 시작점

이 저장소는 Project Zomboid **B42.21 싱글플레이** 환경에서 사용하는 Partner 모드와 호환 패치의 인수인계본입니다.

## 먼저 볼 것

1. 현재 기획: [`docs/PARTNER_LEGEND_PLAN.md`](docs/PARTNER_LEGEND_PLAN.md)
2. 우리가 만든 모드: [`patches/`](patches/)
3. 실제 활성 모드 199개: [`docs/ACTIVE_MODS.md`](docs/ACTIVE_MODS.md)
4. 기존 패치 설명: [`docs/PATCH_CATALOG.md`](docs/PATCH_CATALOG.md)

## 이번 기능에 필요한 원본 모드

원본 파일은 이 저장소에 복제하지 않습니다. 아래 창작마당에서 직접 받습니다.

| 모드 | 확인 버전 | 용도 |
|---|---:|---|
| [Beyond Ten](https://steamcommunity.com/sharedfiles/filedetails/?id=3765241705) | 1.3.4 | 11~15레벨 |
| [Skill Journal](https://steamcommunity.com/sharedfiles/filedetails/?id=3776641628) | 1.2.2 | 사망 후 스킬·킬 기록 복구 |
| [Traits As Skills](https://steamcommunity.com/sharedfiles/filedetails/?id=3784847437) | B42.20+ | 특성 진행도 표시·조회 |
| [Traits As Skills - More Traits](https://steamcommunity.com/sharedfiles/filedetails/?id=3786253696) | B42.20+ | More Traits 연동 |

함께 읽을 Partner 모드는 다음 세 개입니다.

- `patches/PartnerMasteryExtension` — 16~20레벨과 보너스 설정
- `patches/PartnerBeyondTenSkillJournalBridge` — 11~20레벨 일기장 기록·복구
- `patches/PartnerLightweightBallistics` — 총기 피해·관통·음량 설정
- `patches/PartnerViewpointBallisticsBridge` — 쿼터뷰 PLB와 1·3인칭 VTB 자동 전환 시험판

현재 권장 순서는 `BeyondTen` → `PartnerMasteryExtension` → `PartnerBeyondTenSkillJournalBridge`입니다.

Viewpoint 본체·QOL·3D 모델팩은 본 세이브에서 사용 중이지만, `ViewpointTrueBallistics`와 탄도 브리지는 복제 세이브 전용입니다. 최신 상태와 남은 시험은 [`docs/VIEWPOINT_BALLISTICS_HANDOFF.md`](docs/VIEWPOINT_BALLISTICS_HANDOFF.md)를 먼저 확인하세요.

## 함께 일하는 방식

- 사용자: 기획과 인게임 체감 시험
- 공웹 파트너: 아이디어 정리와 독립 모드 구현
- 로컬 Codex 파트너: 코드 검수, 기존 모드와 병합, 설치, 로그·세이브 안전 확인

공웹 파트너는 새 기능을 **원본 모드 수정이 아닌 독립 모드**로 `patches/PartnerLegend`에 작성하면 됩니다. 원본 창작마당 코드·세이브·로그·개인 경로는 커밋하지 않습니다. 구현이 끝나면 변경 파일과 시험 방법을 함께 남겨 주세요.

현재 최우선 작업은 새 기능 추가보다 Viewpoint 탄도 브리지, Partner Legend, Mastery 전투 기능의 회귀 검증과 안정화입니다.
