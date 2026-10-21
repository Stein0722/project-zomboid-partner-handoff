# 로드 순서와 호환 규칙

## Partner 패치 권장 순서

아래는 관련 모드끼리의 상대 순서입니다. 전체 188개 목록은 [ACTIVE_MODS.md](ACTIVE_MODS.md)를 봅니다.

1. `ZombieBuddy`
2. `PartnerCoopZombieBuddyBridge`는 기본 모드 목록에서 활성화하되 서버 세이브의 Mods 목록에는 넣지 않음
3. `PartnerDynamicWeightCompat`
4. `PartnerLargeMapMetaBuffer`
5. `FantasyWorkshopVS42_4.0` → `PartnerFantasyWorkshopCat71Fix`
6. `PartnerBritaArmorB42Compat` → `BritasArmorPackB42`
7. `myspatialrefuge` → `myspatialrefuge_shop` → `PartnerSpatialRefugeCoop`
8. `BritaCombinedB42` → `PartnerLightweightBallistics`
9. `VSGirlBodyExtension` → 의상 호환 패치 → `PartnerVSGirlRenderGuard`/`PartnerVSGirlAllFemaleBridge`
10. `P4Excalibar` → `Xixi's Weapon Pack` → `Bust_Masamune` → `PartnerLegendaryWeaponDrops`
11. `BeyondTen` → `PartnerMasteryExtension`; `SkillJournal`도 켠 뒤 두 모드보다 아래에 `PartnerBeyondTenSkillJournalBridge`

## 주요 Workshop ID

| Mod ID | Workshop ID |
|---|---:|
| ZombieBuddy | 3619862853 |
| More Traits Definitive | 3799050151 |
| Traits As Skills | 3784847437 |
| Traits As Skills - More Traits | 3786253696 |
| Skill Journal | 3776641628 |
| Beyond Ten | 3765241705 |
| My Spatial Refuge | 3632195933 |
| Shop Extension | 3711250417 |
| Brita Armor B42 | 3780298456 |
| Brita B42 Unified Port | 3777433827 |
| Fantasy Workshop | 3717576490 |
| VSGirl Body Extension | 3820897273 |
| Excalibar | 2868777243 |
| Xixi's Weapon Pack | 3442077203 |
| Final Fantasy Weapons | 3774344755 |
| Skill Book Expansion | 3557111695 |
| Read Book Bypassing Level Restrictions | 3319538177 |

## 같이 켜면 안 되는 조합

- 구 More Traits + More Traits Definitive
- `42_VSGirlBodyAll_female` + `PartnerVSGirlAllFemaleBridge`
- Project RPG를 검증 없이 현재 세이브에 재도입
- Viewpoint 계열 전체를 성능 기준 없이 한꺼번에 재도입

## 버전 한정 주의

- Brita Armor 호환패치는 확인 버전 1.4.9 기준입니다. 업데이트되면 원본 해시와 오류 재검사가 필요합니다.
- Partner 패치들은 Build 42.21 기준입니다.
- `PartnerMasteryExtension` 0.2.0은 Beyond Ten 1.3.4 / API 1과 싱글플레이만 지원합니다. 멀티 서버에서는 사용하지 않습니다.
- Workshop 업데이트 뒤에는 `mod.info`, 함수 이름, 로그를 다시 비교해야 합니다.
