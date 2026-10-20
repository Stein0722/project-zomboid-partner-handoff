# 알려진 문제와 다음 단계

## 바로 이어서 할 일

1. 기준 원본 세이브에 Beyond Ten과 브리지 적용 여부 결정
2. 적용한다면 게임 완전 종료와 새 백업부터 수행
3. 더 큰 마스터리 XP에서 브리지의 `ImportXP` 차액 보충 경로를 별도 강한 시험으로 확인
4. Workshop 업데이트가 있었는지 중요 모드의 버전·해시 재검사

## 아직 완전히 확정하지 않은 부분

- Beyond Ten 제작자의 설명은 Build 42.20까지였고 현재 게임은 42.21입니다. 복제 시험은 통과했지만 업데이트마다 재검사가 필요합니다.
- Traits As Skills는 Beyond Ten 11~15를 직접 지원하지 않습니다. 현재는 충돌 없이 10까지만 보는 상태를 의도적으로 유지합니다.
- `PartnerSpatialRefugeCoop`의 지하실이 실내로 판정되는지는 지하실 업그레이드 후 실제 로그와 방 판정을 봐야 합니다.
- PZ Optimization의 권장 프리셋은 환경에 따라 UI/Lua 부하가 커질 수 있습니다. 프레임 문제는 F9에서 `ui draw`, `lua events`, `ItemContainer.contains`를 구분해 봅니다.
- 인벤토리에 수백 개 물품을 직접 들고 있으면 UI 정렬·태그 검사 비용이 커집니다. 무게 0.01배와 FPS 비용은 별개입니다.
- 대형 월드맵을 연 동안 프레임이 떨어지는 것은 확인됐지만 닫으면 회복했습니다.

## 재현 시 먼저 볼 로그 키워드

- `[PartnerBeyondTenSkillJournalBridge]`
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

