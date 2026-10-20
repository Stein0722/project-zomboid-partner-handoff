Partner Beyond Ten - Skill Journal Bridge 1.0.1

목적
- Skill Journal 일기장에 Beyond Ten의 레벨 11~15 마스터리 XP를 함께 기록합니다.
- Workshop 원본 파일은 수정하거나 포함하지 않습니다.
- Beyond Ten과 Skill Journal이 공개한 함수만 연결합니다.

안전 규칙
- 일기장에 기록된 값보다 플레이어의 현재 마스터리 XP가 높으면 낮추지 않습니다.
- Skill Journal의 회복률을 마스터리 XP 차이에도 똑같이 적용합니다.
- "신체 스킬 제외"가 켜져 있으면 해당 마스터리 XP도 기록·복구하지 않습니다.
- Skill Journal의 "한 기록당 캐릭터 1회" 규칙을 그대로 사용합니다.
- 같은 일기장을 다시 읽어도 기록된 마스터리 XP를 넘겨서 더하지 않습니다.
- 바닐라 스킬 레벨이 10에 도달한 뒤에만 그 스킬의 마스터리 XP를 복구합니다.
- Skill Journal 복구와 Beyond Ten의 내부 9레벨 XP 저장고가 만날 때 10레벨 경계를 안전하게 이어 줍니다.

요구 모드
- Beyond Ten (BeyondTen) 1.3.4 / API 1
- Skill Journal (SkillJournal) 1.2.2
- Project Zomboid 42.21

시험 순서
1. 반드시 복제 세이브에서 BeyondTen, SkillJournal, PartnerBeyondTenSkillJournalBridge를 켭니다.
2. 스킬 하나를 레벨 10으로 만든 뒤 Beyond Ten 마스터리 XP를 얻습니다.
3. Skill Journal에 기록하고 게임을 완전히 종료했다가 다시 시작합니다.
4. 새 캐릭터가 같은 일기장을 읽어 레벨 10과 마스터리 XP가 복구되는지 봅니다.
5. 같은 일기장을 다시 읽어 XP가 더 늘지 않는지 확인합니다.
6. console.txt에서 PartnerBeyondTenSkillJournalBridge 오류가 없는지 확인합니다.

