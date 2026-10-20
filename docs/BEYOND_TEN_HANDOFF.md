# Beyond Ten + Skill Journal 인수인계

## 현재 결론

`PartnerBeyondTenSkillJournalBridge` v1.0.1은 복제 세이브에서 핵심 시험을 통과했습니다. 그러나 기준 원본 세이브의 활성 목록에는 아직 `BeyondTen`과 브리지가 없습니다.

## 확인한 버전

- Project Zomboid: 42.21.0
- Beyond Ten: 1.3.4, Workshop 3765241705
- Skill Journal: 1.2.2, Workshop 3776641628
- Traits As Skills: Workshop 3784847437
- Traits As Skills - More Traits: Workshop 3786253696

## 구조 확인

- Beyond Ten은 바닐라 레벨 1~10을 바꾸지 않습니다.
- 별도 마스터리 XP로 11~15를 계산합니다.
- 사망하면 Beyond Ten의 캐릭터 마스터리 저장값은 비워집니다.
- 현재 Skill Journal은 기본 1~10 경험치만 알고 Beyond Ten 값을 기록하지 않습니다.
- 브리지는 `BeyondTen.ExportXP()`와 `ImportXP()` 공개 API를 사용해 일기장 ModData에 별도로 저장합니다.
- Traits As Skills는 10 이상을 10으로 고정해서 보므로 11~15가 TAS 특성 효과를 추가로 키우지는 않습니다. 이 동작은 당분간 유지합니다.

## v1.0.1 안전 규칙

- 현재 마스터리 XP를 낮추지 않음
- 일기장에 적힌 값보다 더 많이 복구하지 않음
- Skill Journal 회복률 적용
- 신체 스킬 제외 설정 적용
- 같은 기록을 같은 캐릭터가 반복 청구하지 못함
- 바닐라 레벨 10에 도달한 스킬만 마스터리 XP 복구
- 9→10 경계에서 Beyond Ten 내부 저장고로 이어지는 상황 처리

## 실제 시험 결과

1. 복제 세이브에서 15레벨 UI 표시 확인
2. 긴둔기 10 이후 타격으로 마스터리 XP 증가 확인
3. 일기장에 마스터리 XP 기록 확인
4. 완전 재시작 후 값 유지 확인
5. 사망 후 같은 특성을 가진 새 캐릭터가 일기장을 읽어 복구
6. 기록자, 일기장, 복구 캐릭터의 긴둔기 마스터리 XP가 모두 약 `6.474`로 일치
7. Traits As Skills 화면 정상
8. 전투와 체감 프레임 정상
9. 브리지 관련 Lua 오류 없음

## 실패에서 배운 점

- v1.0.0은 B42 Kahlua에서 전역 `next`가 nil인 경로 때문에 실패했습니다.
- Skill Journal은 절대 XP가 아니라 노력량과 캐릭터 배율을 사용하므로, 기록자와 복구 캐릭터의 직업·특성이 다르면 기본 1~10 복구 결과가 달라질 수 있습니다.
- 시험에서는 기록자와 새 캐릭터 모두 `기량: 둔기` 특성을 맞춘 뒤 정확 복구를 확인했습니다.

## 원본 적용의 다음 순서

1. 게임 완전 종료
2. 원본 세이브 ZIP 백업과 목록 검증
3. 원본 `mods.txt`의 `SkillJournal` 뒤에 `BeyondTen`, `PartnerBeyondTenSkillJournalBridge` 추가
4. 첫 로드 뒤 15레벨 UI, 로그, 기존 TAS 상태 확인
5. 일기장 기록 전 추가 백업
6. 오류가 있으면 원본 세이브를 계속 플레이하지 말고 백업으로 복원

## 장기 확장

최대 20/25레벨이나 레벨별 효과 변경은 가능성이 있지만 Beyond Ten의 UI, XP 비용, 저장 상한, 보너스 누적을 함께 다뤄야 합니다. 원본의 명시적 재배포 라이선스를 확인하지 못했으므로 전체 포크보다 별도 `Partner Mastery Core`가 안전합니다.

