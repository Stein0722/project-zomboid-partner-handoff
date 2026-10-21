# 알려진 문제와 다음 단계

## 바로 이어서 할 일

1. 복제 세이브에 `BeyondTen` → `PartnerMasteryExtension` → `SkillJournal` → 브리지 1.1.0 순으로 적용
2. 15→16, 19→20, 완전 재시작, 일기장 사망 복구, 제거 후 15레벨 회귀를 인게임 확인
3. F9/로그로 새 Tick이나 전투 이벤트가 늘지 않았는지 확인
4. 통과 뒤에만 기준 원본 세이브 백업과 적용 여부 결정
5. Workshop 업데이트가 있었는지 중요 모드의 버전·해시 재검사

## 아직 완전히 확정하지 않은 부분

- Beyond Ten 제작자의 설명은 Build 42.20까지였고 현재 게임은 42.21입니다. 복제 시험은 통과했지만 업데이트마다 재검사가 필요합니다.
- `PartnerMasteryExtension` 0.1.0은 자동 계약·실제 Beyond Ten 1.3.4 소스 통합 시험만 통과했고 인게임 UI/재시작/사망 복구는 아직 확인 전입니다.
- 0.1.0은 싱글플레이 전용입니다. 호스트/전용 서버는 Beyond Ten 서버 저장소가 매 Tick 15레벨 한도로 다시 정리하므로 아직 지원하지 않습니다.
- Traits As Skills는 Beyond Ten 11~15를 직접 지원하지 않습니다. 현재는 충돌 없이 10까지만 보는 상태를 의도적으로 유지합니다.
- `PartnerSpatialRefugeCoop`의 지하실이 실내로 판정되는지는 지하실 업그레이드 후 실제 로그와 방 판정을 봐야 합니다.
- PZ Optimization의 권장 프리셋은 환경에 따라 UI/Lua 부하가 커질 수 있습니다. 프레임 문제는 F9에서 `ui draw`, `lua events`, `ItemContainer.contains`를 구분해 봅니다.
- 인벤토리에 수백 개 물품을 직접 들고 있으면 UI 정렬·태그 검사 비용이 커집니다. 무게 0.01배와 FPS 비용은 별개입니다.
- 대형 월드맵을 연 동안 프레임이 떨어지는 것은 확인됐지만 닫으면 회복했습니다.

## 재현 시 먼저 볼 로그 키워드

- `[PartnerBeyondTenSkillJournalBridge]`
- `[PartnerMasteryExtension]`
- `[PartnerLightweightBallistics]`
- `PartnerSpatialRefugeCoop`
- `PartnerDynamicWeightCompat`
- `PartnerLargeMapMetaBuffer`
- `Object tried to call nil`
- `BufferOverflowException`
- `ItemContainer.contains`

## 절대 하지 않을 것

- 실행 중인 게임의 모드 파일 교체
- 원본 세이브에서 바로 첫 시험
- 구 More Traits와 Definitive 동시 활성화
- 창작마당 원본 코드·FBX·번역을 허가 없이 GitHub에 재배포
- 백업 검증 없이 `map_meta.bin`, `players.db`, 월드 청크 삭제
