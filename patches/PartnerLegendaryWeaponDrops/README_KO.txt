Partner Extreme-Rare Legendary Weapon Drops v1.2.1

목적
- Excalibar, Xixi's Weapon Pack, Final Fantasy Weapons의 완성 무기를 싸울아비 명검처럼 극히 드물게 발견하게 합니다.
- 창작마당 원본 파일은 수정하지 않습니다.

기본 확률
- 새로 생성되는 월드 보관함과 좀비 인벤토리에서 각 전설 무기를 독립 확률로 판정합니다.
- 현재 목록은 전설 무기 89종과 봉인 상자 3종입니다.
- 샌드박스 옵션에서 분모를 바꿀 수 있습니다. 숫자가 클수록 희귀합니다.

포함 목록
- Excalibar 완성 무기 5종 (낡은 부품/수정/책 제외)
- Xixi 무기 50종 (칼집/벨트 제외)
- Final Fantasy 무기 5종

중복 획득 방지
- 기본 설정에서는 Excalibar 고정 배치/좀비 부착 드랍을 차단합니다.
- 기본 설정에서는 Final Fantasy 자체 좀비 드랍/킬 보상을 차단합니다.
- 필요하면 샌드박스의 '원본 모드의 별도 획득 경로 차단'을 끌 수 있습니다.

세이브 호환
- 기존 세이브에 추가할 수 있습니다.
- 이미 내용물이 생성된 보관함은 바뀌지 않습니다. 아직 생성되지 않은 새 보관함부터 적용됩니다.
- 제거해도 기존 세이브 구조나 기존 아이템은 손상되지 않습니다.

필수 로드 순서
1. P4Excalibar
2. Xixi's Weapon Pack
3. Bust_Masamune
4. PartnerLegendaryWeaponDrops (마지막)

v1.2.1
- B42가 보관함 이벤트에 전달하는 절차용 ItemPickerContainer를 실제 인벤토리로 잘못 처리하던 오류를 막았습니다.
- 인벤토리 새로고침 중 getParent/AddItem 예외가 반복되지 않습니다.

